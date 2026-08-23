-- tests/test_debuglog.lua — the two formatters, the buffer, the enable seam, and the console.

local T = _G.LK_TEST
local debuglog = T.debuglog
local test, assertEqual = T.test, T.assertEqual

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

-- A throwaway host. `rec` captures everything the instance sends outward — chat, the enable flag,
-- visibility changes — so a case asserts on the host contract rather than on internals.
local function newLog(overrides)
  local rec = { chat = {}, enabled = false, shows = 0, summary = "TestHost v1.2.3, schema v3" }
  local d = {
    name    = "TestHost",
    title   = "Test Host",
    font    = "Interface\\Fonts\\FRIZQT__.TTF",
    slash   = "/th",
    isEnabled  = function() return rec.enabled end,
    setEnabled = function(v) rec.enabled = v end,
    print       = function(line) rec.chat[#rec.chat + 1] = line end,
    initSummary = function() return rec.summary end,
    onVisibilityChanged = function() rec.shows = rec.shows + 1 end,
  }
  for k, v in pairs(overrides or {}) do d[k] = v end
  return debuglog:New(d), rec
end

-- ── the two formatters ─────────────────────────────────────────────────────────────────────
--
-- These three assertions are the only place the rendered text is pinned byte for byte. The buffer
-- holds the plain form only, so a buffer assertion can never see the coloured one — that its output
-- actually reaches the console is asserted separately, further down, with a recorder on the message
-- frame.

test("dbg: FormatPlain wraps the tag in brackets with single-space separators", function()
  assertEqual(debuglog.FormatPlain("15:04:43", "Absorb", "player=1234"),
    "15:04:43 | [Absorb] player=1234")
end)

test("dbg: FormatPlain tolerates a nil tag", function()
  assertEqual(debuglog.FormatPlain("15:04:43", nil, "hi"), "15:04:43 | [] hi")
end)

test("dbg: FormatColored colours the timestamp and tag; pipe and content default", function()
  -- The `||` in the format string is WoW's escape for ONE literal pipe inside a colour-coded
  -- string. A de-duplication that "fixes" it to a single pipe breaks the console's separator.
  assertEqual(debuglog.FormatColored("15:04:43", "Absorb", "player=1234"),
    "|cff6f8faf15:04:43|r || |cffc9a66b[Absorb]|r player=1234")
end)

test("dbg: both formatters are reachable on an instance as well as on the library", function()
  -- Hosts reach them as NS.DebugLog.FormatPlain, so the instance carries them too.
  local D = newLog()
  assertEqual(D.FormatPlain, debuglog.FormatPlain)
  assertEqual(D.FormatColored, debuglog.FormatColored)
end)

test("dbg: the window title is the host's, with the library's suffix appended", function()
  -- A font string cannot be read back through the frame API, so the composed string is recorded
  -- alongside the SetText. Composing it is the only thing the library adds to `d.title`.
  local D = newLog{ title = "Test Host" }
  D:Show()
  assertEqual(D._frameForTest.titleText, "Test Host \226\128\148 Debug")
end)

test("dbg: a host can override the title suffix", function()
  local D = newLog{ title = "Test Host", L = { TITLE_SUFFIX = " (log)" } }
  D:Show()
  assertEqual(D._frameForTest.titleText, "Test Host (log)")
end)

-- ── the buffer ─────────────────────────────────────────────────────────────────────────────

test("dbg: Add appends the plain form to the buffer and is never gated on the flag", function()
  local D, rec = newLog()
  rec.enabled = false
  D:Add("Perf", "a line")
  assertEqual(#D.buffer, 1)
  T.assertTrue(D.buffer[1]:find("[Perf] a line", 1, true) ~= nil, "the plain form lands verbatim")
  T.assertTrue(D.buffer[1]:find("|cff", 1, true) == nil, "and carries no colour codes")
end)

test("dbg: the cap is 500 and the message frame is held to the same number", function()
  -- Pinned as a literal because every other case reads the constant back out of the library and
  -- would pass at any value. The two must move together or the visible log and the copied buffer
  -- disagree about how much history there is.
  assertEqual(debuglog.MAX_BUFFER, 500)
  -- SetMaxLines is called during the window build, so the recorder has to be in place before the
  -- frame exists: wrap the factory rather than the frame.
  local seen = {}
  local realCreate = T.mocks.CreateFrame
  T.mocks.CreateFrame = function(...)
    local f = realCreate(...)
    rawset(f, "SetMaxLines", function(_, n) seen[#seen + 1] = n end)
    return f
  end
  local ok, err = pcall(function() newLog():Show() end)
  T.mocks.CreateFrame = realCreate
  T.assertTrue(ok, tostring(err))
  assertEqual(seen[1], debuglog.MAX_BUFFER, "the console keeps exactly as many lines as the buffer")
end)

test("dbg: the buffer is capped, dropping the oldest line", function()
  -- Never exercised downstream — no addon suite writes 501 lines — so the eviction path is
  -- covered here for the first time.
  local D = newLog()
  for i = 1, debuglog.MAX_BUFFER + 10 do D:Add("N", "line " .. i) end
  assertEqual(#D.buffer, debuglog.MAX_BUFFER)
  T.assertTrue(D.buffer[1]:find("line 11", 1, true) ~= nil, "the first ten were evicted, oldest first")
  T.assertTrue(D.buffer[#D.buffer]:find("line " .. (debuglog.MAX_BUFFER + 10), 1, true) ~= nil,
    "and the newest is still last")
end)

test("dbg: the buffer stays a dense array of plain strings", function()
  -- Seven downstream suites do #buffer, buffer[#buffer], :find on an element, and the four-arg
  -- table.concat(buffer, "\n", i, j). All of those need a dense 1..n array of strings.
  local D = newLog()
  D:Add("A", "one")
  D:Add("B", "two")
  D:Add("C", "three")
  for i = 1, #D.buffer do assertEqual(type(D.buffer[i]), "string") end
  local joined = table.concat(D.buffer, "\n", 2, 3)
  T.assertTrue(joined:find("two", 1, true) ~= nil and joined:find("three", 1, true) ~= nil,
    "the four-arg table.concat form still works")
end)

test("dbg: Clear wipes the buffer and works before the window was ever built", function()
  local D = newLog()
  D:Clear()                       -- no frame yet; must not raise
  D:Add("A", "one")
  D:Add("B", "two")
  D:Clear()
  assertEqual(#D.buffer, 0)
  assertEqual(D:BufferSize(), 0)
end)

test("dbg: BufferSize, LastLine and FindLine answer without reaching into .buffer", function()
  local D = newLog()
  assertEqual(D:BufferSize(), 0)
  T.assertNil(D:LastLine(), "an empty buffer has no last line")
  D:Add("Absorb", "player=1234")
  D:Add("Combat", "left")
  assertEqual(D:BufferSize(), 2)
  T.assertTrue(D:LastLine():find("[Combat] left", 1, true) ~= nil, "LastLine is the newest")
  T.assertTrue(D:FindLine("player=1234") ~= nil, "FindLine matches a substring")
  T.assertNil(D:FindLine("nothing here"), "and answers nil when nothing matches")
end)

-- ── the gated sink ─────────────────────────────────────────────────────────────────────────

test("dbg: the sink routes the first arg as the [tag] and every vararg through safeToString", function()
  local D, rec = newLog()
  rec.enabled = true
  local ok = pcall(D.Debug, "Absorb", "value=%s", secretMock)
  T.assertTrue(ok, "the sink must not raise on a secret arg")
  local last = D:LastLine()
  T.assertTrue(last:find("[Absorb]", 1, true) ~= nil, "the first arg is the console [tag]")
  T.assertTrue(last:find("value=<secret>", 1, true) ~= nil, "a secret arg renders as <secret>")
end)

test("dbg: the sink is a no-op, and does no work at all, when logging is off", function()
  local stringified = 0
  local D, rec = newLog{
    safeToString = function(v) stringified = stringified + 1; return tostring(v) end,
  }
  rec.enabled = false
  D.Debug("Absorb", "value=%s", 123)
  assertEqual(D:BufferSize(), 0, "nothing is appended")
  assertEqual(stringified, 0, "and nothing is stringified — the off path allocates nothing")
end)

test("dbg: the sink is dot-callable, because host call sites bind it bare", function()
  -- Sixteen call sites downstream read `NS.Debug(...)`. A method needing self breaks all of them.
  local D, rec = newLog()
  rec.enabled = true
  local sink = D.Debug
  sink("Bare", "called without an instance")
  T.assertTrue(D:LastLine():find("[Bare]", 1, true) ~= nil, "a bare reference still logs")
end)

test("dbg: the sink survives a format the stringified args cannot satisfy", function()
  -- The whole reason the sink is the library's rather than a string.format at the call site is
  -- that a combat-protected value must not raise on its way to the log (debug-logging-§4). Routing
  -- every vararg through safeToString covers a `%s` slot — but a secret is a NUMBER, and a host
  -- logging one through `%d` handed the pre-stringified sentinel to a numeric slot, which raises
  -- inside string.format exactly as the unguarded value would have. That put the raise back on
  -- precisely the path this sink exists to protect, and on a repeating ticker it takes the feature
  -- down until /reload.
  --
  -- The line still has to LAND, and it has to carry the sentinel: dropping it silently would be
  -- the other way to lose the diagnostic.
  local D, rec = newLog()
  rec.enabled = true
  local ok = pcall(function() D.Debug("Absorb", "total=%d", secretMock) end)
  T.assertTrue(ok, "the gated sink must not propagate a format error")
  local line = D:LastLine()
  T.assertTrue(line ~= nil, "and the line still lands")
  T.assertTrue(line:find("[Absorb]", 1, true) ~= nil, "under its tag")
  T.assertTrue(line:find("total=%d", 1, true) ~= nil,
    "with the format string itself, since it could not be filled")
  T.assertTrue(line:find("<secret>", 1, true) ~= nil, "and the un-renderable value as the sentinel")
end)

test("dbg: an ordinary format is NOT routed through the fallback", function()
  -- Guards the fix from over-reaching: the fallback is a repair path, and a working format must
  -- still render exactly as it always did rather than as a space-joined list.
  -- red under: replace the pcall'd format with the fallback unconditionally.
  local D, rec = newLog()
  rec.enabled = true
  D.Debug("Absorb", "value=%s at %s", "x", "y")
  T.assertTrue(D:LastLine():find("value=x at y", 1, true) ~= nil,
    "a satisfiable format is filled, not joined")
end)

-- ── the enable seam ────────────────────────────────────────────────────────────────────────

test("dbg: SetEnabled writes the flag through the host, not into the library", function()
  local D, rec = newLog()
  D:SetEnabled(true)
  assertEqual(rec.enabled, true)
  assertEqual(D:IsEnabled(), true)
  D:SetEnabled(false)
  assertEqual(rec.enabled, false)
  assertEqual(D:IsEnabled(), false)
end)

test("dbg: SetEnabled normalises a truthy value to a boolean", function()
  local D, rec = newLog()
  D:SetEnabled("yes")
  assertEqual(rec.enabled, true, "the host is handed a boolean, never the raw argument")
end)

test("dbg: enabling acks in green, brackets the session, then adds the [Init] summary", function()
  local D, rec = newLog()
  D:SetEnabled(true)
  assertEqual(#rec.chat, 1)
  T.assertTrue(rec.chat[1]:find("|cff40ff40ON|r", 1, true) ~= nil, "the state word is ON green")
  local n = D:BufferSize()
  local bracket, initLine = D.buffer[n - 1], D.buffer[n]
  T.assertTrue(bracket:find("[Debug] logging enabled", 1, true) ~= nil, "the bracket line lands first")
  T.assertTrue(initLine:find("[Init]", 1, true) ~= nil, "then the [Init] summary")
  T.assertTrue(initLine:find(rec.summary, 1, true) ~= nil, "whose content is the host's to supply")
end)

test("dbg: disabling acks in red and the bracket line still lands after the flag flips", function()
  -- The subtlety this exists for: the disable line is written through the UNGATED Add, not through
  -- the gated sink. Routed through the sink it would early-return — the flag is already false —
  -- and "logging disabled" would never reach the console or the buffer.
  local D, rec = newLog()
  D:SetEnabled(true)
  local before = D:BufferSize()
  D:SetEnabled(false)
  assertEqual(rec.enabled, false, "the flag is off by the time the line is written")
  T.assertTrue(D:BufferSize() > before, "and the line still landed")
  T.assertTrue(D:LastLine():find("[Debug] logging disabled", 1, true) ~= nil,
    "as the last line in the console")
  T.assertTrue(rec.chat[#rec.chat]:find("|cffff4040OFF|r", 1, true) ~= nil, "the state word is OFF red")
end)

test("dbg: disabling adds no [Init] summary", function()
  local D = newLog()
  D:SetEnabled(false)
  assertEqual(D:BufferSize(), 1, "the bracket line alone")
  T.assertTrue(D:LastLine():find("[Init]", 1, true) == nil, "no summary on the way out")
end)

test("dbg: a host with no initSummary gets the bracket line and nothing else", function()
  local D = newLog{ initSummary = false }
  D:SetEnabled(true)
  assertEqual(D:BufferSize(), 1, "the bracket line alone — the summary is optional")
  T.assertTrue(D:LastLine():find("[Debug] logging enabled", 1, true) ~= nil)
end)

test("dbg: the header toggle click flips the flag through SetEnabled", function()
  local D, rec = newLog()
  D:Show()
  local click = D._toggleClickForTest
  assertEqual(type(click), "function", "the toggle seam exists once the window is built")
  click()
  assertEqual(rec.enabled, true)
  click()
  assertEqual(rec.enabled, false)
end)

-- ── the console window ─────────────────────────────────────────────────────────────────────

test("dbg: Show builds and shows; Hide and IsShown never build", function()
  local D = newLog()
  assertEqual(D:IsShown(), false, "a never-opened console reads as hidden without building")
  D:Hide()                        -- must not build, must not raise
  assertEqual(D:IsShown(), false)
  -- The build seam is the probe: it is assigned only inside the builder, so its absence is proof
  -- that neither call constructed a window. Without this the "never build" half is untestable —
  -- the builder ends in Hide(), so IsShown() answers false either way.
  T.assertNil(D._frameForTest, "neither Hide nor IsShown built a window")
  D:Show()
  assertEqual(D:IsShown(), true)
  D:Hide()
  assertEqual(D:IsShown(), false)
end)

test("dbg: Toggle builds the window on its first call", function()
  local D = newLog()
  D:Toggle()
  assertEqual(D:IsShown(), true)
  D:Toggle()
  assertEqual(D:IsShown(), false)
end)

test("dbg: showing and hiding the console tells the host", function()
  -- The host repaints its settings panels off this, so the checkbox on an open options page
  -- follows a console opened from a slash command. Driven through the frame's own handlers rather
  -- than through Show()/Hide(), because the callback is hooked to OnShow/OnHide — Esc and the close
  -- button hide the window without going through either method.
  local D, rec = newLog()
  D:Show()
  local f = D._frameForTest
  f:__fire("OnShow")
  f:__fire("OnHide")
  assertEqual(rec.shows, 2, "fired on both OnShow and OnHide")
end)

test("dbg: two instances own separate buffers and separate frames", function()
  local A = newLog{ name = "HostA" }
  local B = newLog{ name = "HostB" }
  A:Add("A", "only mine")
  assertEqual(A:BufferSize(), 1)
  assertEqual(B:BufferSize(), 0, "a second host shares no buffer")
  A:Show()
  assertEqual(A:IsShown(), true)
  assertEqual(B:IsShown(), false, "nor a frame")
end)

test("dbg: the copy text is the whole buffer, in order, newline-joined", function()
  local D, rec = newLog()
  rec.enabled = true
  D.Debug("Absorb", "value=%s", secretMock)
  D:Add("Perf", "another line")
  local text = D:CopyText()
  local lines = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end
  assertEqual(#lines, 2, "one line per buffered entry")
  T.assertTrue(lines[1]:find("value=<secret>", 1, true) ~= nil, "oldest first, secret rendered")
  T.assertTrue(lines[2]:find("[Perf] another line", 1, true) ~= nil, "then the newer line")
  assertEqual(text, table.concat(D.buffer, "\n"))
  local ok = pcall(function() D:ShowCopy() end)
  T.assertTrue(ok, "and the window itself builds without raising")
end)

test("dbg: Add sends the COLOURED form to the console and the plain one to the buffer", function()
  -- Without this the coloured formatter's delivery is unpinned: swapping FormatColored for
  -- FormatPlain at the AddMessage call is invisible to every buffer assertion in the file.
  local D = newLog()
  D:Show()
  local got
  local log = D._frameForTest.log
  rawset(log, "AddMessage", function(_, line) got = line end)
  D:Add("Absorb", "player=1")
  rawset(log, "AddMessage", nil)
  T.assertTrue(got ~= nil and got:find("|cffc9a66b[Absorb]|r", 1, true) ~= nil,
    "the console gets the colour-coded line: " .. tostring(got))
  T.assertTrue(D:LastLine():find("|cff", 1, true) == nil, "the buffer gets the plain one")
end)

test("dbg: the window degrades to nothing when CreateFrame is unavailable", function()
  local Loader = dofile("tests/_kit/loader.lua")
  local buildMocks = dofile("tests/wow_mock.lua")
  local m = buildMocks()
  m.CreateFrame = nil
  Loader.load("LibKa0s/Core.lua", nil, m)
  Loader.load("LibKa0s/DebugLog.lua", nil, m)
  local isolated = m.LibStub("LibKa0s-DebugLog-1.0")
  local D = isolated:New{
    name = "Headless", title = "Headless", font = "f",
    isEnabled = function() return true end, setEnabled = function() end,
    print = function() end,
  }
  local ok = pcall(function() D:Add("A", "still buffered") end)
  T.assertTrue(ok, "logging keeps working with no UI to draw into")
  assertEqual(D:BufferSize(), 1, "the buffer is the part that must never depend on a frame")
  assertEqual(D:IsShown(), false)
end)

-- ── the checkbox data contract ─────────────────────────────────────────────────────────────
--
-- ConsoleCheckbox returns a plain { label, tooltip, get, set } table that the Options module
-- consumes. It is a data contract assembled by the host — neither library reaches for the other,
-- because that would be a real cycle.

test("dbg: ConsoleCheckbox get reflects window visibility, not the logging flag", function()
  local D, rec = newLog()
  local spec = D:ConsoleCheckbox()
  assertEqual(type(spec.label), "string")
  assertEqual(type(spec.tooltip), "string")
  rec.enabled = true
  assertEqual(spec.get(), false, "logging on, window closed")
  D:Show()
  assertEqual(spec.get(), true)
end)

test("dbg: ConsoleCheckbox set shows and hides without touching the logging flag", function()
  local D, rec = newLog()
  local spec = D:ConsoleCheckbox()
  rec.enabled = false
  spec.set(true)
  assertEqual(D:IsShown(), true)
  assertEqual(rec.enabled, false, "visibility and logging are separate")
  rec.enabled = true
  spec.set(false)
  assertEqual(D:IsShown(), false)
  assertEqual(rec.enabled, true)
end)

test("dbg: the ConsoleCheckbox tooltip names the host's own slash command", function()
  local D = newLog{ slash = "/kcd" }
  T.assertTrue(D:ConsoleCheckbox().tooltip:find("/kcd debug", 1, true) ~= nil,
    "the tooltip is templated on the descriptor, not on a hardcoded verb")
end)

test("dbg: a host with no slash command gets a tooltip that does not mention one", function()
  -- Not cosmetic: substituting an empty slash into the templated sentence yields "Same as  debug.",
  -- and this string ships frozen in -1.0.
  local tip = newLog{ slash = false }:ConsoleCheckbox().tooltip
  T.assertTrue(tip:find("debug", 1, true) == nil or tip:find("  ", 1, true) == nil,
    "no doubled space where the verb would have been: " .. tip)
  assertEqual(tip, debuglog.STRINGS.CHECKBOX_TOOLTIP_NO_SLASH)
end)

-- ── the descriptor ─────────────────────────────────────────────────────────────────────────

test("dbg: New requires a name, a title, a font and an isEnabled/setEnabled pair", function()
  local function missing(field)
    local d = {
      name = "X", title = "X", font = "f",
      isEnabled = function() return false end, setEnabled = function() end,
    }
    d[field] = nil
    return T.assertError(function() debuglog:New(d) end, field .. " must be required")
  end
  for _, field in ipairs({ "name", "title", "font", "isEnabled", "setEnabled" }) do
    T.assertTrue(missing(field):find(field, 1, true) ~= nil, "the error names " .. field)
  end
end)

test("dbg: a host that overrides a string gets its own wording", function()
  local D = newLog{ L = { DEBUG_ON = "Debug: AN" } }
  assertEqual(D:Text("DEBUG_ON"), "Debug: AN")
  assertEqual(D:Text("DEBUG_OFF"), debuglog.STRINGS.DEBUG_OFF, "and the rest still come from the lib")
end)

test("dbg: DebugLog re-exports Core's close button so a host has one factory, not two", function()
  -- Deliberately NOT an identity check: the re-export is a forwarder, so that a Core upgraded
  -- under an unchanged DebugLog is the one that answers (see the load-order cases below).
  -- What must hold is that there is still exactly ONE implementation, reached through Core.
  local real = T.core.MakeCloseButton
  local seen
  T.core.MakeCloseButton = function(parent, onClick) seen = { parent, onClick } return "stub" end
  local got = debuglog.MakeCloseButton("P", "F")
  T.core.MakeCloseButton = real
  assertEqual(got, "stub", "the console's factory is Core's, not a copy of its own")
  assertEqual(seen[1], "P", "parent forwarded")
  assertEqual(seen[2], "F", "onClick forwarded")
end)


-- ── the close-button factory across a Core upgrade ─────────────────────────────────────────
--
-- LibStub upgrades a major IN PLACE: the `core` TABLE a module stashed at load stays the same
-- object while the functions on it are replaced. A host carrying two vendored copies can therefore
-- end up with a newer Core.lua and an unchanged DebugLog.lua — and if DebugLog copied the function
-- VALUE at file-load time, its console keeps drawing the OLD Core's button while lib.MODULES.Core
-- truthfully reports the newer minor. These load real, minor-patched copies of Core in the order
-- the client would, and assert the button came from the Core that won.

local Loader     = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local CORE_SRC = Loader.readFile("LibKa0s/Core.lua")

-- Patch a copy's minor, stamp the library so the assertion can name which copy answered, and
-- replace the factory with one whose product carries the same stamp. Every substitution is
-- counted: a pattern that silently stopped matching would turn this into a test of nothing.
local function coreCopy(tag, minor)
  local function sub(src, pattern, replacement, what)
    local out, n = src:gsub(pattern, replacement, 1)
    assertEqual(n, 1, "patching " .. what .. " in the real Core source")
    return out
  end
  -- Matched on `%d+` rather than on today's literal minor, so a routine release bump does not
  -- break a test that has nothing to do with the change.
  local src = sub(CORE_SRC, 'local MAJOR, MINOR = "LibKa0s%-Core%-1%.0", %d+',
    'local MAJOR, MINOR = "LibKa0s-Core-1.0", ' .. minor, "the Core minor")
  src = sub(src, "lib%.MAJOR, lib%.MINOR = MAJOR, MINOR",
    'lib.MAJOR, lib.MINOR = MAJOR, MINOR lib.__coreTag = "' .. tag .. '"', "the Core tag")
  return src .. '\nlib.MakeCloseButton = function() return { __coreTag = "' .. tag .. '" } end\n'
end

local function loadSkewed()
  local env = buildMocks()
  Loader.loadSource(coreCopy("OLD", 1), "OLD/Core.lua", nil, env)
  Loader.load("LibKa0s/DebugLog.lua", nil, env)
  Loader.loadSource(coreCopy("NEW", 2), "NEW/Core.lua", nil, env)
  return env.LibStub("LibKa0s-Core-1.0"), env.LibStub("LibKa0s-DebugLog-1.0")
end

test("dbg: a newer Core loading after DebugLog supplies the console's close button", function()
  local core, dl = loadSkewed()
  assertEqual(core.__coreTag, "NEW", "the higher Core minor won the LibStub race")
  assertEqual(core.MODULES.Core, 2, "and Core's own MODULES registry reports the newer file")
  assertEqual(dl.MakeCloseButton().__coreTag, "NEW",
    "a snapshotted function value would still be drawing the OLD Core's button")
end)

test("dbg: an instance built after the upgrade draws the newer Core's button", function()
  local _, dl = loadSkewed()
  local D = dl:New({
    name = "SkewHost", title = "Skew Host", font = "Interface\\Fonts\\FRIZQT__.TTF",
    isEnabled = function() return false end, setEnabled = function() end,
  })
  assertEqual(D.MakeCloseButton().__coreTag, "NEW",
    "the per-instance re-export must inherit the forwarder, not a stale value")
end)

-- ── Add is public, ungated, and must not reach past the secret-safe seam ────────────────────

test("dbg: Add renders a secret message as the sentinel", function()
  local D = newLog()
  local ok = pcall(D.Add, D, "Absorb", secretMock)
  T.assertTrue(ok, "Add must not raise on a combat-protected value")
  T.assertTrue(D:LastLine():find(T.core.SECRET, 1, true) ~= nil,
    "Add is the path a host's perf output takes; it must guard like the gated sink does")
end)

-- ── the `L` trap ────────────────────────────────────────────────────────────
--
-- A host's locale table carries a metatable fallback that answers EVERY key with
-- the key itself — the Ka0s standard mandates one (anti-patterns #2). Resolving
-- an override with a plain index therefore accepts that synthesised value for
-- every key, this module's own STRINGS become unreachable, and the host renders
-- raw keys. It shipped: KickCD's perf panel read "STEP_START" / "Ka0s
-- KickCDPANEL_TITLE_SUFFIX" in game, and no headless case caught it.
--
-- rawget is the fix, and it is the RIGHT one rather than a heuristic: it asks
-- "did the host actually put a value here?", which is precisely the question.

local function fallbackLocale()
  return setmetatable({}, { __index = function(_, k) return k end })
end

test("an L whose metatable synthesises every key does NOT mask the module's own strings", function()
  -- red under: reverting D:Text to `strings[key]`
  local d = newLog({ L = fallbackLocale() })
  assertEqual(d:Text("DEBUG_ON"), debuglog.STRINGS.DEBUG_ON,
    "a synthesised override must fall through to the module's own string")
  assertEqual(d:Text("COPY_TITLE"), debuglog.STRINGS.COPY_TITLE)
end)

test("a REAL entry in an L that also has a fallback still overrides", function()
  -- The half rawget must not break: a host with a genuine translation sitting in
  -- a table that also has the fallback still gets its translation.
  local L = fallbackLocale()
  rawset(L, "DEBUG_ON", "Debogage: ACTIF")
  local d = newLog({ L = L })
  assertEqual(d:Text("DEBUG_ON"), "Debogage: ACTIF", "a real entry must still win")
  assertEqual(d:Text("DEBUG_OFF"), debuglog.STRINGS.DEBUG_OFF,
    "and its neighbours must still fall through")
end)

test("a plain L table overrides exactly as before", function()
  -- The existing-consumer path, unchanged.
  local d = newLog({ L = { DEBUG_ON = "ON!" } })
  assertEqual(d:Text("DEBUG_ON"), "ON!")
  assertEqual(d:Text("DEBUG_OFF"), debuglog.STRINGS.DEBUG_OFF)
end)

-- ── host window chrome ─────────────────────────────────────────────────────────────────────
--
-- Added at DebugLog minor 4, for the two hosts (BankLedger and LootHistory) whose windows wear a
-- flat 1px double border with a synthesised inner border, a gold title tint and a grey divider, and
-- close with a 24x24 class-coloured x shared across every window they draw. At the time Core.SKIN
-- was a 12px tooltip border and could not express any of it, so taking the library default was a
-- visual redesign of every window such a host owned.
--
-- As of Core minor 3 that treatment IS the library default (see test_core.lua's "the Ka0s window
-- edge"), so the two hooks no longer exist to rescue a host from the default — they exist for
-- chrome that differs in SHAPE rather than colour, and for a host that wants its console to track
-- its own re-skin seam. Both still DEFAULT to what the library draws, so no consumer changes by
-- passing nothing.


test("dbg: with no makeCloseButton, BOTH windows close with Core's x", function()
  -- The console and the copy window are the LIBRARY's windows, so they wear the library's close
  -- glyph. A host whose own main window closes with a different one must not push that difference
  -- onto them: two adopters did exactly that, and their diagnostic windows ended up with a 24x24
  -- class-coloured x where the other three had Core's thin 18x18 one.
  --
  -- Spying on core.MakeCloseButton rather than on the returned button is what makes this specific:
  -- lib.MakeCloseButton forwards through the core TABLE at CALL time, so a default that stopped
  -- being Core's would stop reaching this counter.
  local core = T.core
  local realMake = core.MakeCloseButton
  local made = 0
  core.MakeCloseButton = function(parent, onClick)
    made = made + 1
    return realMake(parent, onClick)
  end
  local D = newLog{}
  D:Show()
  D:ShowCopy()
  core.MakeCloseButton = realMake

  assertEqual(made, 2, "one per window — the console and the copy window, both from Core")
  D:Hide()
end)
test("dbg: the default chrome IS the Ka0s window edge, on both windows", function()
  -- The host-facing half of Core minor 3. A host that passes no applySkin must get the flat
  -- black edge, the grey inner highlight, the gold title and the grey divider — not the tooltip
  -- border it got through v1.2.0. Asserted on the frame the library actually built.
  local D = newLog{}
  D:Show()
  local frame = D._frameForTest
  T.assertTrue(frame ~= nil, "the console frame must exist")
  T.assertTrue(frame.divider ~= nil, "and carry the divider the skin tints")
  T.assertTrue(frame.innerBorder ~= nil,
    "the 1px inner highlight must be synthesised by the default skin, not only by a host hook")
end)

test("dbg: a host can supply its own skin function, for both windows", function()
  local skinned = {}
  local D = newLog{ applySkin = function(f) skinned[#skinned + 1] = f end }
  D:Show()
  assertEqual(#skinned, 1, "the console window is skinned by the host's function")
  D:ShowCopy()
  assertEqual(#skinned, 2, "and so is the copy window — one skin seam, not one per window")
end)

test("dbg: the host's skin function runs AFTER the Hide and the Esc wiring", function()
  -- The ordering the library already keeps for its own applySkin, and it is load-bearing: a
  -- frame-API surprise in a host's skin must not abort EnsureFrame and leave a visible window with
  -- no Esc handler that EnsureFrame will never rebuild, because `frame` is already assigned.
  local seenShown, seenEsc
  local D = newLog{ applySkin = function(f)
    seenShown = f:IsShown()
    seenEsc = false
    for _, name in ipairs(T.mocks.UISpecialFrames) do
      if name == "TestHostDebugWindow" then seenEsc = true end
    end
  end }
  D:Show()
  T.assertFalse(seenShown, "the frame is already hidden when the host's skin runs")
  T.assertTrue(seenEsc, "and already registered for Esc")
end)

test("dbg: a host that supplies no skin function still gets the library's own", function()
  -- The default path, unchanged from minor 3: no error, and the window still builds.
  local D = newLog()
  D:Show()
  T.assertTrue(D._frameForTest ~= nil)
end)

test("dbg: a host can supply its own close-button factory, for both windows", function()
  local made = {}
  local D = newLog{ makeCloseButton = function(parent, onClick)
    local b = T.mocks.__stubFrame()
    made[#made + 1] = { parent = parent, onClick = onClick }
    return b
  end }
  D:Show()
  assertEqual(#made, 1, "the console's x comes from the host's factory")
  T.assertEqual(type(made[1].onClick), "function", "and is handed a working onClick")
  D:ShowCopy()
  assertEqual(#made, 2, "the copy window's x comes from the same factory")
end)

test("dbg: the host's close button actually closes the window", function()
  local captured
  local D = newLog{ makeCloseButton = function(_, onClick)
    captured = onClick
    return T.mocks.__stubFrame()
  end }
  D:Show()
  T.assertTrue(D:IsShown())
  captured()
  T.assertFalse(D:IsShown(), "the onClick handed to a host factory must hide the console")
end)

test("dbg: a close-button factory returning nil is survivable, as Core's own is", function()
  -- Core.MakeCloseButton answers nil where CreateFrame is unavailable, so a host factory is allowed
  -- to as well — and the title bar must still build.
  local D = newLog{ makeCloseButton = function() return nil end }
  D:Show()
  T.assertTrue(D._frameForTest ~= nil, "the window still builds without an x")
end)

test("dbg: the title-bar offsets are derived from the close button's width", function()
  -- Copy | Clear | Close read right to left, each with a six-pixel gap. Minor 3 hard-coded -30 and
  -- -78, which are correct ONLY for an 18-wide button: a host supplying a 24-wide one would have
  -- Clear's right edge land exactly on that button's left edge and the gap would vanish.
  --
  -- Recorded on the frame for the same reason `titleText` is: an anchor cannot be read back through
  -- the frame API, so this is the only way a host's test can see what it got.
  local D = newLog()
  D:Show()
  local off = D._frameForTest.titleBarOffsets
  T.assertTrue(off ~= nil, "the computed offsets are recorded on the frame")
  assertEqual(off.close, -6)
  assertEqual(off.clear, -30, "unchanged from minor 3 for the default 18-wide button")
  assertEqual(off.copy, -78, "unchanged from minor 3 for the default 18-wide button")
end)

test("dbg: with addonName the title bar draws icons, and they are narrower than the words", function()
  -- Minor 9. The three controls become one size and one pitch; at minor 8 they were 18, 42 and 40
  -- wide and only lined up by arithmetic.
  -- red under: text buttons whatever the descriptor says.
  local D = newLog{ addonName = "TestHost" }
  D:Show()
  local f = D._frameForTest
  T.assertTrue(f.copyButton.icon ~= nil, "Copy did not draw an icon")
  T.assertTrue(f.clearButton.icon ~= nil, "Clear did not draw an icon")
  assertEqual(f.titleBarOffsets.clear, -30, "the close button is still 18 wide")
  assertEqual(f.titleBarOffsets.copy, -54, "-30 - 18 - 6, where a 42-wide word gave -78")
end)

test("dbg: an icon control keeps the label the word was carrying, as a tooltip", function()
  -- Dropping a word for a mark costs the one thing the word was doing. A clipboard and a bin are
  -- not universally legible, so the label moves rather than disappearing.
  local D = newLog{ addonName = "TestHost" }
  D:Show()
  assertEqual(D._frameForTest.copyButton.tooltipText, D:Text("COPY"))
  assertEqual(D._frameForTest.clearButton.tooltipText, D:Text("CLEAR"))
end)

test("dbg: no addonName is the minor-8 title bar, word for word", function()
  -- The text path is not a legacy spelling to migrate away from: it is what a host that has not
  -- been updated gets, what a host without the Media module gets, and what an install missing the
  -- art gets. Three cases, one code path.
  local D = newLog()
  D:Show()
  local f = D._frameForTest
  assertEqual(f.copyButton.icon, nil, "an icon was drawn for a host that never asked")
  assertEqual(f.titleBarOffsets.copy, -78, "the word-width offsets")
end)

test("dbg: an addonName the art does not answer for falls back to words", function()
  -- Media answers nil for an icon it does not ship, and nil here means "draw the word" -- the same
  -- branch a missing library takes.
  local D = newLog{ addonName = "" }
  D:Show()
  assertEqual(D._frameForTest.copyButton.icon, nil)
  assertEqual(D._frameForTest.titleBarOffsets.copy, -78)
end)

test("dbg: a wider host close button pushes Copy and Clear out of its way", function()
  local D = newLog{ makeCloseButton = function()
    local b = T.mocks.__stubFrame()
    function b:GetWidth() return 24 end
    return b
  end }
  D:Show()
  local off = D._frameForTest.titleBarOffsets
  assertEqual(off.close, -6)
  assertEqual(off.clear, -36, "-6 - 24 - 6")
  assertEqual(off.copy, -84, "-36 - 42 - 6")
end)

test("dbg: a close button with no measurable width falls back to the library's own", function()
  -- A headless stub answers 0 from GetWidth, and a real frame can too before its first layout
  -- pass. Neither may collapse the title bar onto itself.
  local D = newLog{ makeCloseButton = function() return T.mocks.__stubFrame() end }
  D:Show()
  assertEqual(D._frameForTest.titleBarOffsets.clear, -30)
end)

test("dbg: with no close button at all the offsets are still the minor-3 defaults", function()
  local D = newLog{ makeCloseButton = function() return nil end }
  D:Show()
  assertEqual(D._frameForTest.titleBarOffsets.clear, -30)
  assertEqual(D._frameForTest.titleBarOffsets.copy, -78)
end)
