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
