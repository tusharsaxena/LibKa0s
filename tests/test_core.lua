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

-- ── the close button ───────────────────────────────────────────────────────────────────────
--
-- THE STUB FRAME CANNOT ANSWER GEOMETRY OR TEXTURE STATE -- `GetWidth` is 0 forever and every other
-- capitalized method no-ops -- so these cases spy on the CALLS instead of reading state back. That
-- is the kit's documented way round it, and it is the right shape here anyway: what matters is that
-- the button was handed the path Media answers with, not that a headless texture object remembers.

--- Run `fn` with CreateFrame handing back a BUTTON that records what is drawn on it.
---
--- The spy has to sit on CreateFrame rather than on the parent: the button is a new frame and the
--- texture is created on THAT, so a recorder installed on the parent never sees a call. Restored
--- afterwards, because the mocks table is shared by every case in this file.
local function recording(fn)
  local rec = {}
  local real = T.mocks.CreateFrame
  T.mocks.CreateFrame = function(...)
    local b = real(...)
    b.CreateTexture = function()
      local tex = T.mocks.__stubFrame()
      tex.SetTexture = function(_, path) rec.path = path end
      tex.SetVertexColor = function(_, r, g, bb) rec.color = { r, g, bb } end
      tex.SetSize = function(_, w, h) rec.art = { w, h } end
      return tex
    end
    b.CreateFontString = function()
      local fs = T.mocks.__stubFrame()
      fs.SetText = function(_, t) rec.text = t end
      fs.SetTextColor = function(_, r, g, bb) rec.color = { r, g, bb } end
      return fs
    end
    b.SetSize = function(_, w, h) rec.slot = { w, h } end
    return b
  end
  local ok, err = pcall(fn, rec)
  T.mocks.CreateFrame = real
  if not ok then error(err, 0) end
  return rec
end

test("core: MakeCloseButton draws the collection's own art when told who is asking", function()
  -- Minor 6. The name is required because a texture path is absolute from Interface\AddOns\ and
  -- this library is vendored -- there is no one path to it, and a copy cannot know which addon
  -- folder it was copied into.
  -- red under: the multiplication sign whatever the caller passes.
  recording(function(rec)
    local b = core.MakeCloseButton(T.mocks.__stubFrame(), function() end, "TestHost")
    T.assertTrue(b ~= nil, "no button was built")
    assertEqual(rec.path, "Interface\\AddOns\\TestHost\\libs\\LibKa0s\\media\\icons\\close")
    assertEqual(rec.text, nil, "a glyph was drawn as well as the icon")
    T.assertTrue(b.icon ~= nil and b.glyph == nil, "the button records which of the two it drew")
  end)
end)

test("core: no addon name is the multiplication sign, exactly as before", function()
  -- Not a legacy spelling to be migrated away from: it is what an un-updated caller gets, what a
  -- host without the Media module gets, and what an install missing the art gets. One code path,
  -- exercised by all three.
  recording(function(rec)
    local b = core.MakeCloseButton(T.mocks.__stubFrame(), function() end)
    assertEqual(rec.text, "\195\151")
    assertEqual(rec.path, nil, "an icon was drawn for a caller that never said who it was")
    T.assertTrue(b.glyph ~= nil and b.icon == nil)
  end)
end)

test("core: an addon name the art cannot answer for falls back to the glyph", function()
  -- Media answers nil for an empty name, and nil here is the same branch a missing library takes.
  recording(function(rec)
    core.MakeCloseButton(T.mocks.__stubFrame(), function() end, "")
    assertEqual(rec.text, "\195\151")
  end)
end)

test("core: the art is inset inside the click target, not filling it", function()
  -- The slot stays 18 -- every window in the collection lays its title bar out around that number,
  -- and DebugLog derives two more offsets from it -- while the glyph is drawn smaller, because art
  -- that reaches its own edges reads far heavier than the title beside it.
  recording(function(rec)
    core.MakeCloseButton(T.mocks.__stubFrame(), function() end, "TestHost")
    assertEqual(rec.slot[1], 18, "the click target moved")
    T.assertTrue(rec.art ~= nil, "the art was never sized")
    T.assertTrue(rec.art[1] < rec.slot[1] and rec.art[1] > 8,
      "the art is " .. tostring(rec.art[1]) .. " in an " .. tostring(rec.slot[1]) .. "px slot")
  end)
end)

test("core: the icon reddens under the pointer and goes back", function()
  recording(function(rec)
    local b = core.MakeCloseButton(T.mocks.__stubFrame(), function() end, "TestHost")
    b:GetScript("OnEnter")(b)
    assertEqual(table.concat(rec.color, ","), "1,0.3,0.3")
    b:GetScript("OnLeave")(b)
    assertEqual(table.concat(rec.color, ","), "0.7,0.7,0.72")
  end)
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
  -- The VALUES a debug console and a perf panel must agree on byte for byte are pinned by the next
  -- case; this one pins that ApplySkin actually makes the three backdrop calls with them.
end)


-- ── the Ka0s window edge ───────────────────────────────────────────────────────────────────
--
-- One treatment, defined once, worn by every window this library draws and by every window a host
-- draws beside them: a flat 1px BLACK outer border with a 1px light-grey highlight synthesised
-- just inside it (the "double edge"), a gold title and a grey divider under the title bar.
--
-- It became the definition because two hosts had already converged on it independently and looked
-- right, while the three on this library's 12px UI-Tooltip-Border did not read as the same suite of
-- addons. See standalone-windows in the Ka0s WoW Addon Standard.

local function recorderFrame()
  local f = {
    children = {}, points = {},
    SetBackdrop = function(self, b) self.backdrop = b end,
    SetBackdropColor = function(self, r, g, b, a) self.bg = { r, g, b, a } end,
    SetBackdropBorderColor = function(self, r, g, b, a) self.border = { r, g, b, a } end,
    SetPoint = function(self, ...) self.points[#self.points + 1] = { ... } end,
  }
  return f
end

test("core: SKIN is the flat 1px Ka0s edge, not the 12px tooltip border", function()
  assertEqual(core.SKIN.bgFile, "Interface\\Buttons\\WHITE8x8")
  assertEqual(core.SKIN.edgeFile, "Interface\\Buttons\\WHITE8x8",
    "the edge is a flat white 1px texture, tinted black — not the tooltip border art")
  assertEqual(core.SKIN.edgeSize, 1)
  assertEqual(core.SKIN.insets.left, 1)
  assertEqual(core.SKIN.insets.right, 1)
  assertEqual(core.SKIN.insets.top, 1)
  assertEqual(core.SKIN.insets.bottom, 1)
  assertEqual(table.concat(core.SKIN.bg, ","), "0.06,0.06,0.08,0.92")
  assertEqual(table.concat(core.SKIN.border, ","), "0,0,0,1")
  -- The three that used to be unexpressible as fields, and were therefore per-host.
  assertEqual(table.concat(core.SKIN.innerBorder, ","), "0.24,0.24,0.27,0.85")
  assertEqual(table.concat(core.SKIN.divider, ","), "0.24,0.24,0.27,0.85")
  assertEqual(table.concat(core.SKIN.title, ","), "1,0.82,0")
end)

test("core: ApplySkin synthesises the inner highlight, exactly once", function()
  local created = 0
  -- The loader env resolves WoW globals from the mock set BEFORE _G, so a swap on _G would be
  -- shadowed and this case would report 0 created frames forever.
  local realCreateFrame = T.mocks.CreateFrame
  T.mocks.CreateFrame = function() created = created + 1; return recorderFrame() end

  local frame = recorderFrame()
  core.ApplySkin(frame)
  core.ApplySkin(frame)
  T.mocks.CreateFrame = realCreateFrame

  assertEqual(created, 1, "the inner border is built once and re-tinted thereafter")
  T.assertTrue(frame.innerBorder ~= nil, "and it is recorded on the frame")
  assertEqual(table.concat(frame.innerBorder.border, ","), "0.24,0.24,0.27,0.85")
  -- Inset by one pixel on both axes so it sits INSIDE the black edge rather than on it.
  assertEqual(#frame.innerBorder.points, 2)
end)


test("core: ApplySkin survives a frame whose metatable answers every key", function()
  -- NOT a hypothetical. A consumer's mock returns a function for ANY key, so `frame.innerBorder`
  -- reads as a truthy FUNCTION rather than nil, a `if not frame.innerBorder` guard never fires,
  -- and the tint then indexes a function and raises. Real WoW frames carry a metatable too, so the
  -- library must decide on the TYPE it got rather than on truthiness.
  local answersEverything = setmetatable({}, {
    __index = function() return function() end end,
  })
  local ok, err = pcall(core.ApplySkin, answersEverything)
  T.assertTrue(ok, "ApplySkin must not raise on such a frame: " .. tostring(err))
  T.assertTrue(type(rawget(answersEverything, "innerBorder")) == "table",
    "and it must have replaced the synthesised answer with a real inner-border frame")
end)
test("core: ApplySkin tints a title and a divider when the frame carries them", function()
  local frame = recorderFrame()
  local tinted, drawn
  frame.title = { SetTextColor = function(_, r, g, b) tinted = { r, g, b } end }
  frame.divider = { SetColorTexture = function(_, r, g, b, a) drawn = { r, g, b, a } end }
  core.ApplySkin(frame)
  assertEqual(table.concat(tinted, ","), "1,0.82,0", "the title is Blizzard gold")
  assertEqual(table.concat(drawn, ","), "0.24,0.24,0.27,0.85", "the divider is the grey line")
end)

test("core: ApplySkin lays the backdrop down before anything drawn on top of it", function()
  -- The three stages are separate functions, so their ORDER is now a call site rather than the
  -- reading order of one body — and nothing else asserts it. It is not cosmetic: SetBackdrop
  -- REPLACES the frame's backdrop wholesale, so a stage that ran before it has its work discarded,
  -- and the inner highlight is a child frame anchored inside the edge the backdrop defines. The
  -- symptom in game is a window that loses its double edge and its gold title, which no headless
  -- assertion on the final values would catch — every individual call still happened.
  local order = {}
  local frame = {
    SetBackdrop            = function(self, b) order[#order + 1] = "backdrop"; self.backdrop = b end,
    SetBackdropColor       = function() order[#order + 1] = "bg" end,
    SetBackdropBorderColor = function() order[#order + 1] = "border" end,
    points = {},
    SetPoint = function(self, ...) self.points[#self.points + 1] = { ... } end,
  }
  frame.title   = { SetTextColor    = function() order[#order + 1] = "title" end }
  frame.divider = { SetColorTexture = function() order[#order + 1] = "divider" end }

  local realCreateFrame = T.mocks.CreateFrame
  T.mocks.CreateFrame = function()
    order[#order + 1] = "innerBorder"
    return recorderFrame()
  end
  core.ApplySkin(frame)
  T.mocks.CreateFrame = realCreateFrame

  assertEqual(table.concat(order, " "),
    "backdrop bg border innerBorder title divider",
    "backdrop first, then the highlight inside it, then the accents on top")
end)

test("core: ApplySkin tolerates a frame with neither a title nor a divider", function()
  -- The copy window has a title and no divider; a perf panel has a title and no divider either.
  local frame = recorderFrame()
  local ok = pcall(core.ApplySkin, frame)
  T.assertTrue(ok, "ApplySkin must not require either")
end)

test("core: ApplySkin honours an explicit skin table", function()
  -- The optional second argument, so DebugLog's descriptor `skin` override reaches ONE
  -- implementation rather than a second copy of these calls.
  local frame = recorderFrame()
  core.ApplySkin(frame, { bgFile = "x", bg = { 1, 0, 0, 1 }, border = { 0, 1, 0, 1 } })
  assertEqual(table.concat(frame.bg, ","), "1,0,0,1")
  assertEqual(table.concat(frame.border, ","), "0,1,0,1")
  -- A skin with no innerBorder/title/divider keys leaves those calls unmade rather than raising.
  assertEqual(frame.innerBorder, nil)
end)

-- ── the stored-color reader ────────────────────────────────────────────────────────────────

-- Four numbers joined, so a case reads as the color it asserts rather than as four arguments.
local function rgba(...)
  local r, g, b, a = core.RGBA(...)
  return table.concat({ tostring(r), tostring(g), tostring(b), tostring(a) }, ",")
end

test("core: RGBA reads the keyed shape", function()
  assertEqual(rgba({ r = 1, g = 0.5, b = 0.25, a = 0.75 }, 0, 0, 0, 1), "1,0.5,0.25,0.75")
end)

test("core: RGBA reads the positional shape", function()
  -- What the Ka0s options color widget writes. The two shapes are both live in users'
  -- SavedVariables across the collection, so one reader has to answer for both.
  assertEqual(rgba({ 1, 0.5, 0.25, 0.75 }, 0, 0, 0, 1), "1,0.5,0.25,0.75")
end)

test("core: RGBA lets the keyed shape win every channel, never mixing the two", function()
  -- The rule that makes the two shapes safe to hold at once. A per-channel `v.r or v[1]` fallback
  -- would answer g = 0.5 here, silently assembling a color out of two different storage formats;
  -- the presence of ANY named channel decides the shape for all four.
  assertEqual(rgba({ r = 1, [2] = 0.5 }, 0, 0, 0, 1), "1,0,0,1")
end)

test("core: RGBA falls back per channel, so a three-element color keeps its default alpha", function()
  assertEqual(rgba({ 0.2, 0.4, 0.6 }, 0, 0, 0, 1), "0.2,0.4,0.6,1")
  assertEqual(rgba({ r = 0.2, g = 0.4, b = 0.6 }, 0, 0, 0, 0.3), "0.2,0.4,0.6,0.3")
end)

test("core: RGBA keeps a stored false rather than swallowing it", function()
  -- Tested with `== nil`, not `or`. `or` would hand back the default here and quietly discard
  -- whatever the host meant by storing false — the same class of bug as defaulting an empty string.
  assertEqual(rgba({ r = false, g = 0, b = 0, a = 0 }, 1, 1, 1, 1), "false,0,0,0")
end)

test("core: RGBA returns the defaults unchanged for a non-table", function()
  -- nil is the case that actually happens: a color the user has never set.
  assertEqual(rgba(nil, 0.1, 0.2, 0.3, 0.4), "0.1,0.2,0.3,0.4")
  assertEqual(rgba("#ffffff", 0.1, 0.2, 0.3, 0.4), "0.1,0.2,0.3,0.4")
  assertEqual(rgba(7, 0.1, 0.2, 0.3, 0.4), "0.1,0.2,0.3,0.4")
end)

test("core: RGBA does not default the defaults", function()
  -- Call sites disagree on what an absent channel means (0,0,0,1 for a chat echo, 1,1,1,1 for a
  -- swatch, a per-widget tint elsewhere), so inventing a house default would recolor one of them.
  assertEqual(rgba({}), "nil,nil,nil,nil")
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
