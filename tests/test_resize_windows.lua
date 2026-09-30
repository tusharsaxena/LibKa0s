-- tests/test_resize_windows.lua — the three windows that resize from Core.MakeResizable's grip:
-- the debug console (DebugLog minor 15), every Widgets.CopyWindow (Widgets minor 11) and the perf
-- panel (PerfPanel minor 6, width only).
--
-- What is pinned for each: the default size is today's, the grip exists and the bounds are set,
-- a resize reflows what does not follow its anchors, the size survives a hide and a show because
-- nothing reapplies the default, two windows resize independently, and with the helper absent
-- (a host carrying an older Core.lua) the window is exactly today's fixed one.
--
-- The mock does not size a frame when sizing starts (testkit/mock_resize.lua says why), so a case
-- states the size the client's sizing would have left (`__setGeom`) and fires OnSizeChanged, which
-- is what the client does on every step of a drag.

local T = _G.LK_TEST
local core, widgets, debuglog, mocks = T.core, T.widgets, T.debuglog, T.mocks
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Fixture = dofile("tests/fixture.lua")

-- Every frame built while `fn` runs, with each SetSize it was given recorded as `__sizes`, so a
-- case can read the size a window was BUILT at (the mock's SetSize records nothing on its own).
local function recordBuilds(fn)
  local built = {}
  local realCreate = mocks.CreateFrame
  mocks.CreateFrame = function(...)
    local f = realCreate(...)
    f.__sizes = {}
    rawset(f, "SetSize", function(self, w, h)
      table.insert(self.__sizes, { w, h })
    end)
    built[#built + 1] = f
    return f
  end
  local ok, err = pcall(fn)
  mocks.CreateFrame = realCreate
  if not ok then error(err, 0) end
  return built
end

local function byName(built, name)
  for _, f in ipairs(built) do
    if f.__name == name then return f end
  end
  return nil
end

-- Every frame built while `fn` runs, with each SetPoint and SetSize it was given recorded as
-- `__points` / `__sizes` (and still applied), so a case can read where a child was anchored.
local function recordPoints(fn)
  local realCreate = mocks.CreateFrame
  mocks.CreateFrame = function(...)
    local f = realCreate(...)
    f.__points, f.__sizes = {}, {}
    local setPoint, setSize = f.SetPoint, f.SetSize
    rawset(f, "SetPoint", function(self, ...)
      table.insert(self.__points, { ... })
      if type(setPoint) == "function" then return setPoint(self, ...) end
    end)
    rawset(f, "SetSize", function(self, w, h)
      table.insert(self.__sizes, { w, h })
      if type(setSize) == "function" then return setSize(self, w, h) end
    end)
    return f
  end
  local ok, err = pcall(fn)
  mocks.CreateFrame = realCreate
  if not ok then error(err, 0) end
end

-- A recorded point's point name and its x / y offsets: the last two arguments, which is where they
-- sit in both the ("BOTTOMRIGHT", x, y) and the ("BOTTOMRIGHT", rel, "BOTTOMRIGHT", x, y) shape.
local function offsets(pt)
  return pt[1], pt[#pt - 1], pt[#pt]
end

-- The grip's footprint measured in from the window's bottom-right corner: how far left and how far
-- up it reaches (its inset plus its size), read off what Core actually gave it.
local function gripReach(grip)
  local _, gx, gy = offsets(grip.__points[1])
  local size = grip.__sizes[1]
  return -gx + size[1], gy + size[2]
end

-- Run `fn` as a host carrying a Core older than minor 9 would: no MakeResizable on the table.
local function withoutHelper(fn)
  local real = core.MakeResizable
  core.MakeResizable = nil
  local ok, err = pcall(fn)
  core.MakeResizable = real
  if not ok then error(err, 0) end
end

local function newConsole(name)
  local enabled = false
  return debuglog:New{
    name = name or "ResizeHost", title = "Test Host", font = "Interface\\Fonts\\FRIZQT__.TTF",
    isEnabled = function() return enabled end, setEnabled = function(v) enabled = v end,
    print = function() end,
  }
end

-- Count the line counter's repaints. The mock answers CreateFontString with the frame itself, so the
-- counter IS the console frame and its SetText is the frame's.
local function countStatus(f)
  local rec = { n = 0 }
  rawset(f, "SetText", function(_, text) rec.n = rec.n + 1; rec.last = text end)
  return rec
end

-- ── the debug console ──────────────────────────────────────────────────────────────────────

test("resize console: the default size is still 700 x 344", function()
  -- red under: change CONSOLE_W / CONSOLE_H in LibKa0s/DebugLog.lua
  local built = recordBuilds(function() newConsole("ResizeDefault"):Show() end)
  local f = byName(built, "ResizeDefaultDebugWindow")
  assertEqual(#f.__sizes, 1, "sized once, at build")
  assertEqual(f.__sizes[1][1], 700); assertEqual(f.__sizes[1][2], 344)
end)

-- Run `fn` as an instance whose DebugLogDiagnostics.lua did not install the report, so the console
-- draws no Diagnostics link and the title bar is what it was at minor 15.
local function withoutDiagnostics(fn)
  local saved = debuglog.__installDiagnostics
  debuglog.__installDiagnostics = nil
  local ok, err = pcall(fn)
  debuglog.__installDiagnostics = saved
  if not ok then error(err, 0) end
end

test("resize console: it has a grip and bounds that keep the title bar's controls clear", function()
  -- red under: drop the core.MakeResizable call from EnsureFrame
  local D
  withoutDiagnostics(function() D = newConsole("ResizeBounds") end)
  D:Show()
  local f = D._frameForTest
  assertTrue(f:IsResizable(), "resizable")
  assertTrue(type(f.resizeGrip) == "table", "from a grip")
  local minW, minH, maxW, maxH = f:GetResizeBounds()
  -- No addonName, so the text controls: Copy's left edge is 78 + 40 = 118 from the right, wider than
  -- the 8 + 80 toggle on the left; the title "Test Host - Debug" is 19 bytes at 7px each.
  assertEqual(minW, 2 * (118 + 6) + 19 * 7, "every control plus the centered title fits")
  assertEqual(minH, 26 + 6 + 4 * (10 + 2) + 16 + 4, "the bars and four lines fit")
  assertTrue(maxW >= 700 and maxH >= 344, "the default is inside the bounds")
end)

local function newIconConsole(name)
  local enabled = false
  return debuglog:New{
    name = name, title = "Test Host", font = "Interface\\Fonts\\FRIZQT__.TTF",
    addonName = "TestHost",
    isEnabled = function() return enabled end, setEnabled = function(v) enabled = v end,
    print = function() end,
  }
end

test("resize console: the icon controls are narrower, and so is the minimum", function()
  local D
  withoutDiagnostics(function() D = newIconConsole("ResizeIcons") end)
  D:Show()
  local f = D._frameForTest
  local minW = f:GetResizeBounds()
  -- Icons: Copy's left edge is 54 + 18 = 72, narrower than the toggle's 88, so the toggle sets it.
  assertEqual(minW, 2 * (88 + 6) + 19 * 7)
end)

test("resize console: the Diagnostics link widens the left group, and the minimum grows", function()
  -- red under: leave the link out of consoleMinWidth's left group
  local D = newConsole("ResizeDiagLink")
  D:Show()
  local minW = D._frameForTest:GetResizeBounds()
  -- Headless, every width is 7px per byte: the wider toggle word "Debug: OFF" is 70, the 10px gap,
  -- "Diagnostics" 77, from x = 8. 165 is wider than the text controls' 118 on the right.
  assertEqual(minW, 2 * (8 + 70 + 10 + 77 + 6) + 19 * 7)
  local without
  withoutDiagnostics(function() without = newConsole("ResizeDiagNone") end)
  without:Show()
  assertTrue(minW > without._frameForTest:GetResizeBounds(), "wider than the console without it")
  -- The icon controls do not change it: the left group is the wider side either way.
  local icons = newIconConsole("ResizeDiagIcons")
  icons:Show()
  assertEqual(icons._frameForTest:GetResizeBounds(), minW)
end)

test("resize console: a resize resyncs the scrollbar and the line counter, and keeps the buffer", function()
  -- red under: drop the onResize from the console's MakeResizable options
  local D = newConsole("ResizeReflow")
  for i = 1, 5 do D:Add("T", "line " .. i) end
  local f = D._frameForTest
  local log, bar = f.log, f.scrollBar
  rawset(log, "GetMaxScrollRange", function() return 7 end)
  rawset(log, "GetScrollOffset", function() return 2 end)
  local range
  rawset(bar, "SetMinMaxValues", function(_, lo, hi) range = { lo, hi } end)
  local status = countStatus(f)
  f:__setGeom(900, 500)
  f:__fire("OnSizeChanged", 900, 500)
  assertEqual(range[2], 7, "the scrollbar took the message frame's new range")
  assertTrue(status.n >= 1, "the line counter was repainted")
  assertEqual(D:BufferSize(), 5, "the buffer is untouched")
end)

test("resize console: the line counter sits clear of the grip", function()
  -- red under: put the counter's BOTTOMRIGHT x offset in LibKa0s/DebugLog.lua back to -10
  local f
  recordPoints(function()
    local D = newConsole("ResizeCounter")
    D:Show()
    f = D._frameForTest
  end)
  local reachX, reachY = gripReach(f.resizeGrip)
  assertEqual(reachX, 17, "the grip is 16 px square at 1 px in")
  assertEqual(reachY, 17)
  -- The mock answers CreateFontString with the frame, so the counter's point lands on the console:
  -- it is the one bottom-right point below the status divider (which sits at STATUS_H, 16).
  local counter
  for _, pt in ipairs(f.__points) do
    local name, _, y = offsets(pt)
    if name == "BOTTOMRIGHT" and type(y) == "number" and y < 16 then counter = pt end
  end
  assertTrue(counter ~= nil, "the line counter is anchored bottom-right")
  local _, x, y = offsets(counter)
  assertTrue(y < reachY, "the counter shares the grip's rows, so only x can keep it clear")
  assertTrue(-x > reachX, "the counter's right edge is left of the grip: " .. tostring(x))
end)

test("resize console: the size survives a hide and a show", function()
  -- red under: SetSize(CONSOLE_W, CONSOLE_H) on every Show
  local D = newConsole("ResizeKeep")
  D:Show()
  local f = D._frameForTest
  f:__setGeom(900, 500)
  f:__fire("OnSizeChanged", 900, 500)
  local sets = 0
  rawset(f, "SetSize", function() sets = sets + 1 end)
  D:Hide(); D:Show(); D:Toggle(); D:Toggle()
  assertEqual(sets, 0, "nothing reapplied the default")
  assertEqual(f:GetWidth(), 900); assertEqual(f:GetHeight(), 500)
end)

test("resize console: two hosts' consoles resize independently", function()
  local A, B = newConsole("ResizeA"), newConsole("ResizeB")
  A:Show(); B:Show()
  local fa, fb = A._frameForTest, B._frameForTest
  assertTrue(fa.resizeGrip ~= fb.resizeGrip, "each has its own grip")
  local statusB = countStatus(fb)
  fa:__setGeom(1000, 600)
  fa:__fire("OnSizeChanged", 1000, 600)
  assertEqual(statusB.n, 0, "B did not relayout for A's resize")
  assertEqual(fb:GetWidth(), 0, "and B's size was not touched")
end)

test("resize console: with no MakeResizable in Core it is today's fixed window", function()
  -- red under: call core.MakeResizable unguarded
  withoutHelper(function()
    local D = newConsole("ResizeAbsent")
    D:Show()
    local f = D._frameForTest
    assertFalse(f:IsResizable(), "not resizable")
    assertNil(f.resizeGrip, "no grip")
    assertTrue(D:IsShown(), "and the console still works")
  end)
end)

-- ── copy windows ───────────────────────────────────────────────────────────────────────────

local function newCopy(name, w, h)
  return widgets.CopyWindow{ addonName = "TestHost", name = name, width = w, height = h }
end

test("resize copy: a copy window opens at its descriptor's size", function()
  local built = recordBuilds(function() newCopy("ResizeCopyDefault", 500, 300):Show("x") end)
  local f = byName(built, "ResizeCopyDefault")
  assertEqual(#f.__sizes, 1)
  assertEqual(f.__sizes[1][1], 500); assertEqual(f.__sizes[1][2], 300)
end)

test("resize copy: it has a grip and a minimum on both axes", function()
  -- red under: drop the coreLib.MakeResizable call from buildCopyFrame
  local win = newCopy("ResizeCopyBounds", 500, 300)
  win:Show("x")
  local f = win:GetFrame()
  assertTrue(f:IsResizable())
  assertTrue(type(f.resizeGrip) == "table")
  local minW, minH = f:GetResizeBounds()
  assertEqual(minW, 240); assertEqual(minH, 140)
end)

test("resize copy: the scroll bar's down button sits above the grip", function()
  -- red under: put the scroll frame's BOTTOMRIGHT y offset in LibKa0s/Widgets.lua back to 10
  local f
  recordPoints(function()
    local win = newCopy("ResizeCopyInset", 500, 300)
    win:Show("x")
    f = win:GetFrame()
  end)
  local _, reachY = gripReach(f.resizeGrip)
  local bottom
  for _, pt in ipairs(f.scroll.__points) do
    local name, _, y = offsets(pt)
    if name == "BOTTOMRIGHT" then bottom = y end
  end
  assertTrue(type(bottom) == "number", "the scroll frame is anchored bottom-right")
  -- UIPanelScrollFrameTemplate's scroll-down button hangs at the scroll frame's bottom edge, and it
  -- spans the frame's right gutter, which is the grip's column: only the height can clear it.
  assertTrue(bottom > reachY, "the down button starts above the grip: " .. tostring(bottom))
end)

test("resize copy: a window declared smaller than the minimum is its own minimum", function()
  local win = newCopy("ResizeCopySmall", 200, 120)
  win:Show("x")
  local minW, minH = win:GetFrame():GetResizeBounds()
  assertEqual(minW, 200); assertEqual(minH, 120)
end)

test("resize copy: the edit box width tracks a resize", function()
  -- red under: drop the onResize; the edit box is a scroll child and does not follow the anchors
  local win = newCopy("ResizeCopyReflow", 500, 300)
  win:Show("x")
  local f = win:GetFrame()
  local width
  rawset(f.edit, "SetWidth", function(_, w) width = w end)
  f:__setGeom(800, 400)
  f:__fire("OnSizeChanged", 800, 400)
  -- The declared window keeps 50px between its width and the edit box's (editWidth = width - 50).
  assertEqual(width, 750)
end)

test("resize copy: the size, and the edit box's width, survive a hide and a show", function()
  local win = newCopy("ResizeCopyKeep", 500, 300)
  win:Show("x")
  local f = win:GetFrame()
  f:__setGeom(800, 400)
  f:__fire("OnSizeChanged", 800, 400)
  local sets, width = 0, nil
  rawset(f, "SetSize", function() sets = sets + 1 end)
  rawset(f.edit, "SetWidth", function(_, w) width = w end)
  win:Hide()
  win:Show("y")
  assertEqual(sets, 0, "nothing reapplied the default")
  assertEqual(width, 750, "the edit box was sized for the window as it is, not as declared")
end)

test("resize copy: two named copy windows resize independently", function()
  local a, b = newCopy("ResizeCopyA", 500, 300), newCopy("ResizeCopyB", 500, 300)
  a:Show("x"); b:Show("y")
  local fa, fb = a:GetFrame(), b:GetFrame()
  local widthB
  rawset(fb.edit, "SetWidth", function(_, w) widthB = w end)
  fa:__setGeom(800, 400)
  fa:__fire("OnSizeChanged", 800, 400)
  assertNil(widthB, "B's edit box did not move")
  assertEqual(fb:GetWidth(), 0, "and B was not sized")
end)

test("resize copy: the debug console's copy window resizes too", function()
  local D = newConsole("ResizeConsoleCopy")
  D:Add("T", "a line")
  D:ShowCopy()
  assertTrue(D._copyFrameForTest:IsResizable())
  assertTrue(type(D._copyFrameForTest.resizeGrip) == "table")
end)

test("resize copy: with no MakeResizable in Core it is today's fixed window", function()
  withoutHelper(function()
    local win = newCopy("ResizeCopyAbsent", 500, 300)
    win:Show("x")
    local f = win:GetFrame()
    assertFalse(f:IsResizable())
    assertNil(f.resizeGrip)
    assertTrue(f:IsShown())
  end)
end)

-- ── the perf panel ─────────────────────────────────────────────────────────────────────────

-- ROW_W 360 + PAD 8 on each side, and TITLE_H 24 + PAD 8 twice + six rows of ROW_H 22 + GAP 4.
local PANEL_W, PANEL_H = 360 + 8 * 2, 24 + 8 * 2 + 6 * (22 + 4)

test("resize panel: the panel opens at today's computed size", function()
  local p = Fixture.new()
  local built = recordBuilds(function() p.ShowPanel() end)
  local f = byName(built, "TestHostPerfPanel")
  assertEqual(#f.__sizes, 1)
  assertEqual(f.__sizes[1][1], PANEL_W); assertEqual(f.__sizes[1][2], PANEL_H)
end)

test("resize panel: width only, with today's width the minimum", function()
  -- red under: drop `widthOnly = true` from the panel's MakeResizable options
  local p = Fixture.new()
  p.ShowPanel()
  local f = p.__panel()
  assertTrue(f:IsResizable())
  assertTrue(type(f.resizeGrip) == "table")
  local minW, minH, maxW, maxH = f:GetResizeBounds()
  assertEqual(minW, PANEL_W, "today's width is the minimum")
  assertTrue(maxW > minW, "and it can grow")
  assertEqual(minH, PANEL_H); assertEqual(maxH, PANEL_H, "the height cannot move")
end)

test("resize panel: a resize stretches every step row", function()
  -- red under: drop stretchRows from the panel's onResize
  local p = Fixture.new()
  p.ShowPanel()
  local f = p.__panel()
  local widths = {}
  for key, b in pairs(f.buttons) do
    rawset(b, "SetWidth", function(_, w) widths[key] = w end)
  end
  f:__setGeom(520, PANEL_H)
  f:__fire("OnSizeChanged", 520, PANEL_H)
  local n = 0
  for _, w in pairs(widths) do
    n = n + 1
    assertEqual(w, 520 - 8 * 2)
  end
  assertEqual(n, 6, "all six rows")
end)

test("resize panel: the width survives a hide and a show", function()
  local p = Fixture.new()
  p.ShowPanel()
  local f = p.__panel()
  f:__setGeom(520, PANEL_H)
  f:__fire("OnSizeChanged", 520, PANEL_H)
  local sets = 0
  rawset(f, "SetSize", function() sets = sets + 1 end)
  p.HidePanel(); p.ShowPanel(); p.TogglePanel(); p.TogglePanel()
  assertEqual(sets, 0)
  assertEqual(f:GetWidth(), 520)
end)

test("resize panel: with no MakeResizable in Core it is today's fixed panel", function()
  withoutHelper(function()
    local p = Fixture.new()
    p.ShowPanel()
    local f = p.__panel()
    assertFalse(f:IsResizable())
    assertNil(f.resizeGrip)
    assertTrue(p.IsPanelShown())
  end)
end)
