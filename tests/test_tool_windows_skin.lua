-- tests/test_tool_windows_skin.lua — the library's tool windows follow their skin owner (LK-09 of
-- Ka0sAddonsCommonTasks docs/2026-10-25-SKINNING): the debug console (DebugLog minor 22 and the
-- peeled DebugLogWindow.lua minor 1) with its copy window, the perf panel (PerfPanel minor 10) and
-- the sim panel with its buttons (SimPanel minor 7), over SkinDefs minor 4's tool-window tokens.
--
-- Each window takes its owner from its own descriptor: the console's `addonName`, the perf panel's
-- `addonName` (else `name`), the sim panel's `name`, the folder each one's close mark is already
-- built from. A name counts only once that addon called Skin:RegisterOwner, so the three promises
-- pinned here on the kit's paint recorder (tests/fixture_skin_paint.lua) are LK-06's:
--
--   * WITHOUT AN OWNER NOTHING MOVES: an unregistered name and a client with no Skin major build
--     each window with the same paint calls, call for call (the tracer).
--   * WITH ONE, the chrome and the state colors paint from that owner's skin and follow its
--     switches, and two owners side by side never reach each other's windows.
--   * KA0S DEFAULT IS TODAY'S LOOK: its new tokens are the constants the windows drew.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER, OTHER = "LootHistory", "BankLedger"
local TOOL_FILES = { "Widgets", "WidgetsCopyWindow", "DebugLog", "DebugLogDiagnostics", "DebugLogGates",
  "DebugLogWindow", "Lifecycle", "Perf", "PerfSampler", "PerfCommands", "PerfPanel", "Sim", "SimTimeline",
  "SimPanel" }

local function survey(m, obj) return m.__paint(obj) end
local function rgba(c) return F.rgba(c) end
local function tok(Skin, skin, name) return F.tok(Skin, skin, name) end
--- A token's color as "r,g,b,1": what a three-argument SetTextColor records.
local function tok3(Skin, skin, name)
  local c = Skin:ResolveSkin(skin)[name]
  return F.rgba({ c[1], c[2], c[3], 1 })
end

--- A fresh client: the paint recorder, Core, the Skin major (unless `noSkin`) and the tool windows'
--- majors. Named frames are kept in m.__named (the kit's CreateFrame sets no global).
local function env(noSkin)
  local files = {}
  for _, f in ipairs(noSkin and { "Core" } or F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(TOOL_FILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  m.__named = {}
  local create = m.CreateFrame
  m.CreateFrame = function(kind, name, ...)
    local f = create(kind, name, ...)
    if name then m.__named[name] = f end
    return f
  end
  return m, Skin
end

-- ── the three windows ────────────────────────────────────────────────────────────────────────

--- A console for `owner` (its addonName), shown; answers D and its frame.
local function console(m, owner, extra)
  local enabled = false
  local d = {
    name = "Host" .. tostring(owner), addonName = owner, title = "Host", font = "Interface\\Fonts\\ARIALN.TTF",
    isEnabled = function() return enabled end, setEnabled = function(v) enabled = v end,
    print = function() end,
  }
  for k, v in pairs(extra or {}) do d[k] = v end
  local D = m.LibStub("LibKa0s-DebugLog-1.0"):New(d)
  D:Show()
  return D, D._frameForTest
end

--- A perf panel for `owner` (its addonName), shown; answers P and its frame.
local function perf(m, owner)
  local lc = m.LibStub("LibKa0s-Lifecycle-1.0"):New{
    name = "Perf" .. tostring(owner), standDown = function() end, standUp = function() end,
  }
  local P = m.LibStub("LibKa0s-Perf-1.0"):New{
    name = "Perf" .. tostring(owner), addonName = owner, title = "Host", slash = "/host",
    sv = "ToolSkinPerfDB", lifecycle = lc, log = function() end, print = function() end,
  }
  P.ShowPanel()
  return P, P.__panel()
end

--- A sim for `name` (its owner), panel shown; answers the instance and the panel frame. `panel` is
--- the descriptor's panel table (default empty).
local function sim(m, name, panel)
  local Sim = m.LibStub("LibKa0s-Sim-1.0")
  local seam = Sim:NewSeam({ Probe = function() return "live" end }, { name = name })
  local s = Sim:New{
    name = name, seam = seam, slash = "/host sim",
    deliver = function() return 1 end,
    isStoodDown = function() return false end,
    scenarios = { names = { "one" }, defs = { one = { label = "One", timeline = function()
      return { { kind = "a", label = "Alpha" }, { kind = "b", label = "Beta" } }
    end } } },
    prepare = function(_, _, _, ready) ready() end,
    play = function() return "did" end,
    print = function() end,
    panel = panel or {},
  }
  assertTrue(s:ShowPanel(), "ShowPanel")
  return s, m.__named[name .. "SimPanel"]
end

--- The tracer's lines for whatever `build(m, owner)` paints, in a fresh client.
local function traceOf(noSkin, owner, build)
  local m = env(noSkin)
  local tr = F.tracer(m)
  tr.start()
  local ok, err = pcall(build, m, owner)
  tr.stop(); tr.restore()
  if not ok then error(err, 0) end
  return tr.text()
end

local function assertUnchanged(build, what)
  local named = traceOf(false, OTHER, build)
  local noSkin = traceOf(true, OTHER, build)
  assertTrue(named ~= "", what .. " paints something")
  assertEqual(named, noSkin, what .. ": an unregistered owner is a Skin-less client's paint, call for call")
end

-- ── without an owner ─────────────────────────────────────────────────────────────────────────

test("tool windows skin: without a registered owner each window is the previous minors' paint", function()
  assertUnchanged(function(m, owner)
    local D = console(m, owner)
    D:SetEnabled(true)
    D:Add("Tag", "a line")
    D:ShowCopy()
  end, "the console and its copy window")
  assertUnchanged(function(m, owner) perf(m, owner) end, "the perf panel")
  assertUnchanged(function(m, owner) sim(m, owner) end, "the sim panel")
end)

test("tool windows skin: an unregistered console logs Ka0s Default's colored line, as before", function()
  local m = env()
  local D, f = console(m, OTHER)
  local got
  rawset(f.log, "AddMessage", function(_, ...) got = { ... } end)
  D:Add("Tag", "msg")
  assertEqual(#got, 1, "one argument: the message frame's own color")
  assertTrue(got[1]:find("|cff6f8faf", 1, true) == 1, "the steel-blue stamp: " .. got[1])
  assertTrue(got[1]:find("|cffc9a66b[Tag]|r", 1, true) ~= nil, "the tan tag")
end)

-- ── the console ──────────────────────────────────────────────────────────────────────────────

test("tool windows skin: a registered owner's console paints from its skin", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "obsidian")
  local D, f = console(m, OWNER)
  assertEqual(rgba(survey(m, f).backdropColor), tok(Skin, "obsidian", "win.bg"), "the window")
  assertEqual(rgba(survey(m, f.title).textColor), tok(Skin, "obsidian", "title.text"), "the title")
  assertEqual(rgba(survey(m, f.debugToggle).textColor), tok3(Skin, "obsidian", "sem.off"), "the OFF toggle")
  D:SetEnabled(true)
  assertEqual(rgba(survey(m, f.debugToggle).textColor), tok3(Skin, "obsidian", "sem.on"), "the ON toggle")
  f.debugToggleBtn:__fire("OnEnter")
  assertEqual(rgba(survey(m, f.debugToggle).textColor), tok3(Skin, "obsidian", "text.accent"), "its hover")
  f.debugToggleBtn:__fire("OnLeave")
  local clearLabel = f.clearButton:GetRegions()
  assertEqual(rgba(survey(m, clearLabel).textColor), tok3(Skin, "obsidian", "text.muted"), "Clear at rest")
  f.clearButton:__fire("OnEnter")
  assertEqual(rgba(survey(m, clearLabel).textColor), tok3(Skin, "obsidian", "text.accent"), "Clear hot")
  local diag = f.diagnosticsButton:GetRegions()
  assertEqual(rgba(survey(m, diag).textColor), tok3(Skin, "obsidian", "text.link"), "the Diagnostics link")
  assertEqual(rgba(survey(m, f.lineCount).textColor), tok3(Skin, "obsidian", "log.count"), "the line count")
  assertEqual(rgba(survey(m, f.statusDivider).color), tok(Skin, "obsidian", "divider"), "the status rule")
  local track, thumb = f.scrollBar:GetRegions()
  assertEqual(rgba(survey(m, track).color), tok(Skin, "obsidian", "scroll.track"), "the track")
  assertEqual(rgba(survey(m, thumb).color), tok(Skin, "obsidian", "scroll.thumb"), "the thumb")
end)

test("tool windows skin: an owned console logs in its skin's colors and re-colors the log on a switch", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "azeroth")
  local D, f = console(m, OWNER)
  local lines = {}
  rawset(f.log, "AddMessage", function(_, text, r, g, b) lines[#lines + 1] = { text, r, g, b } end)
  rawset(f.log, "Clear", function() lines = {} end)
  D:Add("Tag", "first")
  local function hex(name)
    local c = Skin:ResolveSkin("azeroth")[name]
    return ("%02x%02x%02x"):format(math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5),
      math.floor(c[3] * 255 + 0.5))
  end
  local last = lines[#lines]
  assertTrue(last[1]:find("|cff" .. hex("log.ts"), 1, true) == 1, "the stamp in log.ts: " .. last[1])
  assertTrue(last[1]:find("|cff" .. hex("log.tag") .. "[Tag]|r first", 1, true) ~= nil, "the tag in log.tag")
  assertEqual(rgba({ last[2], last[3], last[4] }), tok3(Skin, "azeroth", "log.text"), "the message in log.text")
  assertTrue(D:LastLine():find("|c", 1, true) == nil, "the buffer stays plain")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(#lines, D:BufferSize(), "the switch rebuilt the visible log from the buffer")
  local rebuilt = lines[#lines]
  assertTrue(rebuilt[1]:find("|cff6f8faf", 1, true) == 1, "Ka0s Default's stamp: " .. rebuilt[1])
  assertTrue(rebuilt[1]:find("|cffc9a66b[Tag]|r first", 1, true) ~= nil, "and its tag")
  assertEqual(rgba({ rebuilt[2], rebuilt[3], rebuilt[4] }), "1,1,1,1", "white, the frame's own color")
end)

test("tool windows skin: a skin switch repaints the console, and Ka0s Default is today's paint", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "contrast")
  local D, f = console(m, OWNER)
  D:SetEnabled(true)
  Skin:SetChoice(OWNER, "ka0s", "ember")
  assertEqual(rgba(survey(m, f).backdropColor), tok(Skin, "ember", "win.bg"), "the window")
  assertEqual(rgba(survey(m, f.debugToggle).textColor), tok3(Skin, "ember", "sem.on"), "the toggle")
  assertEqual(rgba(survey(m, f.lineCount).textColor), tok3(Skin, "ember", "log.count"), "the count")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  local m2 = env()
  local D2, f2 = console(m2, OTHER)
  D2:SetEnabled(true)
  for _, key in ipairs({ "debugToggle", "lineCount", "title" }) do
    assertEqual(rgba(survey(m, f[key]).textColor), rgba(survey(m2, f2[key]).textColor), key .. " on Ka0s Default")
  end
  assertEqual(rgba(survey(m, f).backdropColor), rgba(survey(m2, f2).backdropColor), "the window on Ka0s Default")
  assertEqual(rgba(survey(m, f.statusDivider).color), rgba(survey(m2, f2.statusDivider).color), "the status rule")
end)

test("tool windows skin: an owned console's copy window wears the owner's skin", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "obsidian")
  local D = console(m, OWNER)
  D:ShowCopy()
  local cf = D._copyFrameForTest
  assertTrue(Skin.painted[cf] ~= nil, "the copy window is handed to the owner's facade")
  assertEqual(rgba(survey(m, cf).backdropColor), tok(Skin, "obsidian", "win.bgDense"), "its dense fill")
end)

test("tool windows skin: a host's own skin or applySkin keeps the console out of the owner's skin", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "obsidian")
  local _, f = console(m, OWNER, { skin = { bgFile = "x", bg = { 0.2, 0.3, 0.4, 1 } } })
  assertNil(Skin.painted[f], "a host skin table wins")
  assertEqual(rgba(survey(m, f.lineCount).textColor), "0.600,0.600,0.620,1", "the count stays the constant")
  local seen
  local _, g = console(m, OWNER, { name = "HostApply", applySkin = function(frame) seen = frame end })
  assertTrue(seen == g, "the host's applySkin ran")
  assertNil(Skin.painted[g], "and owns the whole skin job")
end)

test("tool windows skin: two owners' consoles stay isolated", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "obsidian")
  F.owner(Skin, OTHER, "azeroth")
  local _, a = console(m, OWNER)
  local _, b = console(m, OTHER)
  Skin:SetChoice(OWNER, "ka0s", "glass")
  assertEqual(rgba(survey(m, a.lineCount).textColor), tok3(Skin, "glass", "log.count"), "A follows its switch")
  assertEqual(rgba(survey(m, b.lineCount).textColor), tok3(Skin, "azeroth", "log.count"), "B keeps its skin")
  assertEqual(rgba(survey(m, b).backdropColor), tok(Skin, "azeroth", "win.bg"), "B's window too")
end)

-- ── the perf panel ───────────────────────────────────────────────────────────────────────────

test("tool windows skin: a registered owner's perf panel paints its window and step colors", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "azeroth")
  local P, f = perf(m, OWNER)
  assertEqual(rgba(survey(m, f).backdropColor), tok(Skin, "azeroth", "win.bg"), "the window")
  local start = f.buttons.start
  assertEqual(start.__state, "ready")
  assertEqual(rgba(survey(m, start.text).textColor), tok3(Skin, "azeroth", "sem.stepReady"), "a ready step")
  assertEqual(rgba(survey(m, f.buttons.finish.text).textColor), tok3(Skin, "azeroth", "sem.stepLocked"),
    "a locked step")
  assertEqual(rgba(survey(m, start.cmd).textColor), tok3(Skin, "azeroth", "text.faint"), "the command column")
  start:__fire("OnEnter")
  assertEqual(rgba(survey(m, start.text).textColor), tok3(Skin, "azeroth", "text.accent"), "its hover")
  start:__fire("OnLeave")
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertEqual(rgba(survey(m, f).backdropColor), tok(Skin, "obsidian", "win.bg"), "a switch repaints the window")
  assertEqual(rgba(survey(m, start.text).textColor), tok3(Skin, "obsidian", "sem.stepReady"), "and the rows")
  assertEqual(rgba(survey(m, start.cmd).textColor), tok3(Skin, "obsidian", "text.faint"), "and the commands")
  P.HidePanel()
end)

test("tool windows skin: an owned perf panel on Ka0s Default draws the constants", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "ka0s")
  local _, f = perf(m, OWNER)
  local m2 = env()
  local _, g = perf(m2, OTHER)
  for _, key in ipairs({ "start", "finish", "cancel" }) do
    assertEqual(rgba(survey(m, f.buttons[key].text).textColor), rgba(survey(m2, g.buttons[key].text).textColor), key)
    assertEqual(rgba(survey(m, f.buttons[key].dot).color), rgba(survey(m2, g.buttons[key].dot).color), key .. " dot")
    assertEqual(rgba(survey(m, f.buttons[key].cmd).textColor), rgba(survey(m2, g.buttons[key].cmd).textColor),
      key .. " command")
  end
end)

-- ── the sim panel ────────────────────────────────────────────────────────────────────────────

test("tool windows skin: a registered owner's sim panel paints its window, rows and buttons", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "obsidian")
  local s, f = sim(m, OWNER)
  assertEqual(rgba(survey(m, f).backdropColor), tok(Skin, "obsidian", "win.bg"), "the window")
  local rows = f.__rowButtons
  assertEqual(rows[1].__state, "ready", "Start is ready while idle")
  assertEqual(rgba(survey(m, rows[1].text).textColor), tok3(Skin, "obsidian", "sem.stepReady"), "the Start row")
  assertEqual(rgba(survey(m, rows[2].text).textColor), tok3(Skin, "obsidian", "sem.stepLocked"), "a locked step")
  assertEqual(rgba(survey(m, rows[1].cmd).textColor), tok3(Skin, "obsidian", "text.faint"), "the command")
  local start = f.picker.start
  assertEqual(rgba(survey(m, start).backdropColor), tok(Skin, "obsidian", "win.bg"), "the Start button")
  assertEqual(rgba(survey(m, start.label).textColor), tok3(Skin, "obsidian", "sem.stepReady"), "its label")
  start:__fire("OnEnter")
  assertEqual(rgba(survey(m, start.label).textColor), tok3(Skin, "obsidian", "text.accent"), "its hover")
  start:__fire("OnLeave")
  Skin:SetChoice(OWNER, "ka0s", "azeroth")
  assertEqual(rgba(survey(m, f).backdropColor), tok(Skin, "azeroth", "win.bg"), "a switch repaints the window")
  assertEqual(rgba(survey(m, rows[1].text).textColor), tok3(Skin, "azeroth", "sem.stepReady"), "the rows")
  assertEqual(rgba(survey(m, rows[1].cmd).textColor), tok3(Skin, "azeroth", "text.faint"), "the commands")
  assertEqual(rgba(survey(m, start).backdropColor), tok(Skin, "azeroth", "win.bg"), "the button")
  assertEqual(rgba(survey(m, start.label).textColor), tok3(Skin, "azeroth", "sem.stepReady"), "its label")
  s:HidePanel()
end)

test("tool windows skin: an owned sim panel on Ka0s Default draws the constants", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "ka0s")
  local _, f = sim(m, OWNER)
  local m2 = env()
  local _, g = sim(m2, OTHER)
  for i = 1, 3 do
    local a, b = f.__rowButtons[i], g.__rowButtons[i]
    assertEqual(rgba(survey(m, a.text).textColor), rgba(survey(m2, b.text).textColor), "row " .. i)
    assertEqual(rgba(survey(m, a.cmd).textColor), rgba(survey(m2, b.cmd).textColor), "row " .. i .. " command")
  end
  assertEqual(rgba(survey(m, f.picker.start).backdropColor), rgba(survey(m2, g.picker.start).backdropColor),
    "the Start button")
  assertEqual(rgba(survey(m, f.picker.start.label).textColor), rgba(survey(m2, g.picker.start.label).textColor),
    "its label")
end)

-- ── the sim panel's tooltip (SimPanel minor 8) ───────────────────────────────────────────────

-- LK-06d (ruling R-5, decision D-14): the row and button tooltips take the owner's tooltip tokens,
-- the key column `gtip.title` and every white line `gtip.value`. The panel is a window (D-01), so
-- Ignore settings panel leaves them skinned. The title line names no color and stays the client's.

local TIP_PANEL = { startTip = { { "Injects", "a bag" }, "Plain line." } }

--- Hover `fire` with GameTooltip's SetText, AddLine and AddDoubleLine recorded: one string per line,
--- "text=r,g,b,1" (a double line "left|right=left color|right color"; "nil" for no color).
local function simTip(m, frame)
  local tip, seen = m.GameTooltip, {}
  local names = { "SetOwner", "SetText", "AddLine", "AddDoubleLine", "Show" }
  local saved = {}
  for _, n in ipairs(names) do saved[n] = rawget(tip, n) end
  local function c(r, g, b) return r == nil and "nil" or F.rgba({ r, g, b }) end
  rawset(tip, "SetOwner", function() end)
  rawset(tip, "Show", function() end)
  rawset(tip, "SetText", function(_, t, r, g, b) seen[#seen + 1] = tostring(t) .. "=" .. c(r, g, b) end)
  rawset(tip, "AddLine", function(_, t, r, g, b) seen[#seen + 1] = tostring(t) .. "=" .. c(r, g, b) end)
  rawset(tip, "AddDoubleLine", function(_, l, rt, r, g, b, r2, g2, b2)
    seen[#seen + 1] = tostring(l) .. "|" .. tostring(rt) .. "=" .. c(r, g, b) .. "|" .. c(r2, g2, b2)
  end)
  local ok, err = pcall(frame.__fire, frame, "OnEnter")
  for _, n in ipairs(names) do rawset(tip, n, saved[n]) end
  assertTrue(ok, tostring(err))
  return seen
end

test("tool windows skin: an owner-less sim panel's tooltip keeps its literals", function()
  local m = env()
  local _, f = sim(m, OTHER, TIP_PANEL)
  local seen = simTip(m, f.__rowButtons[1])
  assertEqual(seen[2], "Injects|a bag=0.900,0.820,0.500,1|1,1,1,1", "the key column's own gold")
  assertEqual(seen[3], "Plain line.=1,1,1,1")
  local typed = simTip(m, f.picker.start)
  assertEqual(typed[2]:match("=(.*)$"), "1,1,1,1", "a button's command line")
end)

test("tool windows skin: an owned sim panel's tooltip takes gtip.title and gtip.value, Ignore panel or not",
  function()
  -- red under: the literals (every skin's tooltip the same), or a sim panel that stands down with
  -- the settings panel (it is a window).
  local m, Skin = env()
  F.owner(Skin, OWNER, "azeroth")
  Skin:ResolveSkin("azeroth")["gtip.value"] = { 0.2, 0.4, 0.6, 1 }
  local _, f = sim(m, OWNER, TIP_PANEL)
  local seen = simTip(m, f.__rowButtons[1])
  assertEqual(seen[1]:match("=(.*)$"), "nil", "the title names no color")
  assertEqual(seen[2], "Injects|a bag=" .. tok3(Skin, "azeroth", "gtip.title") .. "|0.200,0.400,0.600,1")
  assertEqual(seen[3], "Plain line.=0.200,0.400,0.600,1")
  assertEqual(simTip(m, f.picker.start)[2]:match("=(.*)$"), "0.200,0.400,0.600,1", "a button's command line")
  Skin:SetIgnore(OWNER, true, nil)
  assertEqual(simTip(m, f.__rowButtons[1])[3], "Plain line.=0.200,0.400,0.600,1", "a window keeps its skin")
  Skin:SetIgnore(OWNER, false, nil)
  Skin:SetChoice(OWNER, "ka0s", "ember")
  seen = simTip(m, f.__rowButtons[1])
  assertEqual(seen[2], "Injects|a bag=" .. tok3(Skin, "ember", "gtip.title") .. "|" .. tok3(Skin, "ember", "gtip.value"),
    "the next hover after a switch")
end)

test("tool windows skin: under Ka0s Default the sim key column is gtip.title's gold, the rest white", function()
  -- D-14's recorded shift: 0.9, 0.82, 0.5 becomes Ka0s Default's tooltip gold.
  local m, Skin = env()
  F.owner(Skin, OWNER)
  local _, f = sim(m, OWNER, TIP_PANEL)
  local seen = simTip(m, f.__rowButtons[1])
  assertEqual(seen[2], "Injects|a bag=1,0.820,0,1|1,1,1,1")
  assertEqual(seen[3], "Plain line.=1,1,1,1")
end)

-- ── the tokens ───────────────────────────────────────────────────────────────────────────────

local KA0S = {
  ["log.ts"] = { 0x6f / 255, 0x8f / 255, 0xaf / 255, 1 }, ["log.tag"] = { 0xc9 / 255, 0xa6 / 255, 0x6b / 255, 1 },
  ["log.text"] = { 1, 1, 1, 1 }, ["log.count"] = { 0.6, 0.6, 0.62, 1 }, ["text.faint"] = { 0.45, 0.45, 0.48, 1 },
  ["sem.stepReady"] = { 0.9, 0.9, 0.92, 1 }, ["sem.stepBusy"] = { 1, 0.82, 0, 1 },
  ["sem.stepLocked"] = { 0.4, 0.4, 0.42, 1 }, ["sem.stepCancel"] = { 0.8, 0.32, 0.32, 1 },
  ["sem.stepCancelHot"] = { 1, 0.45, 0.45, 1 },
}

test("tool windows skin: Ka0s Default's tool-window tokens are the constants the windows drew", function()
  local _, Skin = env()
  local k = Skin:ResolveSkin("ka0s")
  for name, want in pairs(KA0S) do assertEqual(rgba(k[name]), rgba(want), name) end
  assertEqual(rgba(k["sem.on"]), "0.300,0.850,0.300,1", "done and used are sem.on")
end)

-- WCAG 2 contrast on the skin's own window, alpha ignored.
local function channel(c)
  if c <= 0.03928 then return c / 12.92 end
  return ((c + 0.055) / 1.055) ^ 2.4
end
local function luminance(c) return 0.2126 * channel(c[1]) + 0.7152 * channel(c[2]) + 0.0722 * channel(c[3]) end
local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then la, lb = lb, la end
  return (la + 0.05) / (lb + 0.05)
end

test("tool windows skin: every skin's tool-window text reads on its own window", function()
  local _, Skin = env()
  local MIN = {
    ["log.text"] = 4.5, ["log.ts"] = 3, ["log.tag"] = 3, ["log.count"] = 3, ["text.faint"] = 2.5,
    ["sem.stepReady"] = 4.5, ["sem.stepBusy"] = 3, ["sem.stepLocked"] = 2, ["sem.stepCancel"] = 3,
    ["sem.stepCancelHot"] = 3,
  }
  for _, def in ipairs(Skin:Skins()) do
    local t = Skin:ResolveSkin(def.key)
    for name, want in pairs(MIN) do
      local ratio = contrast(t[name], t["win.bg"])
      assertTrue(ratio >= want, ("%s: %s contrast %.2f on win.bg, want >= %.1f"):format(def.key, name, ratio, want))
    end
  end
end)
