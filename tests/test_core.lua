-- tests/test_core.lua — the secret-safe seam, the prefixed chat printer, and the window chrome.

local T = _G.LK_TEST
local core = T.core
local test, assertEqual = T.test, T.assertEqual

local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

-- A stand-in for a WoW combat "secret" value. Crucially it models BOTH halves of the real
-- behaviour: the `..` operator SUCCEEDS on a secret (silently propagating secretness) while
-- `table.concat` RAISES on it. A table with a string-returning __concat concatenates fine via
-- `..`, yet `table.concat({mock})` still rejects it (table.concat ignores __concat and refuses a
-- non-string/number element) — so this catches a detector that (wrongly) probes with `..` and
-- passes one that probes with `table.concat`. (Earlier a __concat that *errored* was used, which
-- modelled the opposite of a real secret and gave false confidence.)
local secretMock = setmetatable({}, {
  __concat = function() return "secret-propagated" end,
})

-- ── the secret-safe seam ───────────────────────────────────────────────────────────────────

test("core: IsConcatSafe is false for a table.concat-hostile value, true for a plain one", function()
  T.assertTrue(core.IsConcatSafe(1234) == true, "numbers concat fine")
  T.assertTrue(core.IsConcatSafe("hi") == true, "strings concat fine")
  T.assertTrue(core.IsConcatSafe(secretMock) == false, "secret-like value must be flagged unsafe")
end)

test("core: SafeToString renders a secret as lib.SECRET and passes nil/booleans through", function()
  assertEqual(core.SafeToString(1234), "1234")
  assertEqual(core.SafeToString("hi"), "hi")
  assertEqual(core.SafeToString(nil), "nil")
  -- Booleans are checked before the concat probe on purpose: table.concat rejects a boolean
  -- element, but a boolean is never secret and must not be masked as <secret>.
  assertEqual(core.SafeToString(true), "true")
  assertEqual(core.SafeToString(false), "false")
  assertEqual(core.SafeToString(secretMock), core.SECRET)
  assertEqual(core.SECRET, "<secret>")
end)

-- ── the prefixed chat printer ──────────────────────────────────────────────────────────────

test("core: Print joins with a space, prefixes verbatim, and routes through the injected sink", function()
  local out = {}
  local p = core:New{
    prefix = "|cFF00FFFF[AT]|r",
    sink = function(line) out[#out + 1] = line end,
  }
  p.Print("alpha", 42, nil, true, secretMock)
  assertEqual(#out, 1)
  assertEqual(out[1], "|cFF00FFFF[AT]|r alpha 42 nil true <secret>")
end)

test("core: sep separates the prefix from the body and may be empty", function()
  -- prettychat's tag carries its own trailing space, so it passes sep = "".
  local out = {}
  local p = core:New{
    prefix = "[pc] ",
    sep = "",
    sink = function(line) out[#out + 1] = line end,
  }
  p.Print("one", "two")
  assertEqual(out[1], "[pc] one two")
end)

test("core: a function prefix is re-read on every call", function()
  -- The WhatGroup load-order case: NS.PREFIX is not yet set when the setup file runs, so a
  -- prefix captured once at :New() time would freeze to nil for the life of the session.
  local tag = nil
  local out = {}
  local p = core:New{
    prefix = function() return tag end,
    sink = function(line) out[#out + 1] = line end,
  }
  tag = "[first]"
  p.Print("x")
  tag = "[second]"
  p.Print("x")
  assertEqual(out[1], "[first] x")
  assertEqual(out[2], "[second] x")
end)

test("core: a prefix that has not resolved yet prints the body alone", function()
  -- The other half of the load-order window: a line reading "nil something happened" is worse
  -- than an untagged one.
  local out = {}
  local p = core:New{
    prefix = function() return nil end,
    sink = function(line) out[#out + 1] = line end,
  }
  p.Print("still working")
  assertEqual(out[1], "still working")
end)

test("core: Format applies the format string with pre-stringified args", function()
  -- ConsumableMaster's KCM.Say form. The args are run through SafeToString before :format sees
  -- them, so a secret reaching a %s slot renders rather than raising.
  local out = {}
  local p = core:New{
    prefix = "[T]",
    sink = function(line) out[#out + 1] = line end,
  }
  p.Format("value=%s after %s tries", secretMock, 3)
  assertEqual(out[1], "[T] value=<secret> after 3 tries")
end)

test("core: the default sink is DEFAULT_CHAT_FRAME:AddMessage", function()
  local chat = T.mocks.DEFAULT_CHAT_FRAME
  local got
  rawset(chat, "AddMessage", function(_, line) got = line end)
  local p = core:New{ prefix = "[T]" }
  p.Print("routed")
  rawset(chat, "AddMessage", nil)
  assertEqual(got, "[T] routed")
end)

test("core: :New refuses a descriptor with no prefix", function()
  local err = T.assertError(function() core:New{ sink = function() end } end,
    "a printer with no prefix is a silent mis-tag, not a degradation")
  T.assertTrue(err:find("prefix", 1, true) ~= nil, "the error names the missing field")
end)

-- ── the window chrome seam ─────────────────────────────────────────────────────────────────

test("core: ApplySkin no-ops on a frame without SetBackdrop", function()
  -- A bare table, not a mock frame: the mock synthesises every PascalCase method, so
  -- `frame.SetBackdrop` is always truthy there and the guard could never be exercised.
  local bare = {}
  local ok = pcall(core.ApplySkin, bare)
  T.assertTrue(ok, "ApplySkin must not raise on a frame with no backdrop support")
  T.assertNil(bare.backdrop, "nothing is written to a frame that cannot take a backdrop")
end)

test("core: ApplySkin applies the skin table and both colours", function()
  local calls = {}
  local frame = {
    SetBackdrop = function(_, b) calls.backdrop = b end,
    SetBackdropColor = function(_, r, g, b, a) calls.bg = { r, g, b, a } end,
    SetBackdropBorderColor = function(_, r, g, b, a) calls.border = { r, g, b, a } end,
  }
  core.ApplySkin(frame)
  assertEqual(calls.backdrop, core.SKIN)
  assertEqual(table.concat(calls.bg, ","), table.concat(core.SKIN.bg, ","))
  assertEqual(table.concat(calls.border, ","), table.concat(core.SKIN.border, ","))
  -- The values a debug console and a perf panel must agree on, byte for byte, or a host's two
  -- windows stop reading as one addon.
  assertEqual(core.SKIN.bgFile, "Interface\\Buttons\\WHITE8x8")
  assertEqual(core.SKIN.edgeFile, "Interface\\Tooltips\\UI-Tooltip-Border")
  assertEqual(core.SKIN.edgeSize, 12)
  assertEqual(table.concat(core.SKIN.bg, ","), "0.06,0.06,0.07,0.95")
  assertEqual(table.concat(core.SKIN.border, ","), "0,0,0,1")
end)

test("core: MakeCloseButton returns a button wired to onClick", function()
  local fired = 0
  local b = core.MakeCloseButton(T.mocks.UIParent, function() fired = fired + 1 end)
  T.assertTrue(b ~= nil, "a close button is built when CreateFrame is available")
  b:__fire("OnClick")
  assertEqual(fired, 1)
end)

test("core: MakeCloseButton returns nil when CreateFrame is unavailable", function()
  -- A fresh env rather than the shared one: nilling CreateFrame on T.mocks would leak into every
  -- later case in the run.
  local m = buildMocks()
  m.CreateFrame = nil
  Loader.load("LibKa0s/Core.lua", nil, m)
  local isolated = m.LibStub("LibKa0s-Core-1.0")
  T.assertNil(isolated.MakeCloseButton(nil, function() end),
    "a close button is worth degrading over, not erroring over")
end)

-- ── Perf's regression ──────────────────────────────────────────────────────────────────────

test("core: Perf refuses to register when Core is missing or below NEEDS_CORE", function()
  -- Absent, not degraded. A probe that registered and then nil-errored on its first Core call would
  -- surface as a Lua error mid-run in whichever addon the user happened to be using; refusing to
  -- register instead lets the host's own setup stub say "perf is not installed" and mean it.
  local bare = buildMocks()
  Loader.load("LibKa0s/Perf.lua", nil, bare)
  T.assertNil(bare.LibStub("LibKa0s-Perf-1.0", true), "no Core, no probe")

  local old = buildMocks()
  Loader.loadSource(
    'local c = LibStub:NewLibrary("LibKa0s-Core-1.0", 1) c.MAJOR, c.MINOR = "LibKa0s-Core-1.0", 0',
    "core-below-minimum", nil, old)
  Loader.load("LibKa0s/Perf.lua", nil, old)
  T.assertNil(old.LibStub("LibKa0s-Perf-1.0", true), "a Core below the declared minimum is refused")
end)

test("core: Perf's own stringifier renders a secret as <secret>", function()
  -- The live bug this milestone exists to close. Perf's private safeToString branched on type(),
  -- and a real secret IS a string or a number — so it returned the secret untouched, and the line
  -- raised further downstream at the host's `table.concat(buffer, "\n")` when the user pressed
  -- Copy, killing the button for the rest of the session.
  local Fixture = dofile("tests/fixture.lua")
  local P, rec = Fixture.new()
  P.Log("absorb=%s", secretMock)
  assertEqual(rec.log[#rec.log], "absorb=<secret>")
end)
