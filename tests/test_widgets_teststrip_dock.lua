-- tests/test_widgets_teststrip_dock.lua — LibKa0s-Widgets-1.0: the mode strip's docking (minor 27,
-- the owner's 2026-11-15 window-chrome rulings, WowAddonStandards v2.110.0): `opts.dock` and
-- `lib.DockTestStrip`, directly under a window's title bar, or on a HUD display's top edge, flipped
-- under its bottom edge while the top would leave the screen.
--
-- Every case runs under the geometry factory tests/fixture_geom.lua installs, wrapped once more by
-- `recording` (tests/test_widgets_teststrip.lua's header gives the reason): the geometry frame
-- answers its catch-all for HookScript, the mouse and the strata, so a case could not ask whether
-- the strip re-placed itself on a show or turned its mouse off. Edges (GetTop, GetBottom) are set
-- per frame by `at`, in UI units at scale 1 unless a case says otherwise.

local T = _G.LK_TEST
local assertEqual = T.assertEqual
local assertTrue  = T.assertTrue
local assertFalse = T.assertFalse
local assertNil   = T.assertNil
local mocks       = T.mocks
local W = T.widgets

local Geom = dofile("tests/fixture_geom.lua")
local test = Geom.test

local function record(f)
  rawset(f, "EnableMouse", function(self, v) self.__mouse = v and true or false end)
  rawset(f, "IsMouseEnabled", function(self) return self.__mouse or false end)
  rawset(f, "SetFrameStrata", function(self, v) self.__strata = v end)
  rawset(f, "GetFrameStrata", function(self) return self.__strata or "MEDIUM" end)
  rawset(f, "SetFrameLevel", function(self, v) self.__level = v end)
  rawset(f, "GetFrameLevel", function(self) return self.__level or 1 end)
  rawset(f, "HookScript", function(self, name, hook)
    local prev = self.__scripts[name]
    self.__scripts[name] = function(...)
      if prev then prev(...) end
      return hook(...)
    end
  end)
  -- Show and Hide fire their scripts, as the client does on a change of visibility.
  rawset(f, "Show", function(self)
    local was = self.__shown
    self.__shown = true
    if not was then self:__fire("OnShow") end
  end)
  rawset(f, "Hide", function(self)
    local was = self.__shown
    self.__shown = false
    if was then self:__fire("OnHide") end
  end)
  return f
end

local EDGES = { "GetTop", "GetBottom", "GetEffectiveScale" }

--- Run `fn()` with every frame CreateFrame builds carrying the recorders above, and with any edges a
--- case gave the shared UIParent stand-in put back afterwards, so no other suite reads them.
local function recording(fn)
  local saved, ui, edges = mocks.CreateFrame, mocks.UIParent, {}
  for _, k in ipairs(EDGES) do edges[k] = rawget(ui, k) end
  mocks.CreateFrame = function(...) return record(saved(...)) end
  local ok, err = pcall(fn)
  mocks.CreateFrame = saved
  for _, k in ipairs(EDGES) do rawset(ui, k, edges[k]) end
  if not ok then error(err, 0) end
end

--- Give `f` a top and a bottom edge (UI units) and an effective scale.
local function at(f, top, bottom, scale)
  rawset(f, "GetTop", function() return top end)
  rawset(f, "GetBottom", function() return bottom end)
  rawset(f, "GetEffectiveScale", function() return scale or 1 end)
  return f
end

local function frame() return record(mocks.CreateFrame("Frame", nil, mocks.UIParent)) end

local function point(region, i)
  local p, rel, relPoint, x, y = region:GetPoint(i)
  return { point = p, rel = rel, relPoint = relPoint, x = x, y = y }
end

local function assertPoint(region, i, p, rel, relPoint, x, y, label)
  local got = point(region, i)
  assertEqual(got.point, p, label)
  assertTrue(got.rel == rel, (label or "") .. ": the relative frame")
  assertEqual(got.relPoint, relPoint, label)
  assertEqual(got.x, x, label)
  assertEqual(got.y, y, label)
end

-- ── under the title bar ──────────────────────────────────────────────────────────────────────

test("TestStrip dock: 'title' anchors the strip full width directly under the title bar", function()
  recording(function()
    local win, bar = frame(), frame()
    local s = W.TestStrip(win, { text = "TEST MODE", dock = "title", titleBar = bar })
    assertFalse(s:IsShown(), "still born hidden: showing it is the host's")
    assertEqual(s:GetNumPoints(), 2)
    assertPoint(s, 1, "TOPLEFT", bar, "BOTTOMLEFT", 0, 0, "left edge")
    assertPoint(s, 2, "TOPRIGHT", bar, "BOTTOMRIGHT", 0, 0, "right edge")
    assertFalse(s:IsFlipped())
  end)
end)

test("TestStrip dock: 'title' with an inset pulls both sides in", function()
  recording(function()
    local bar = frame()
    local s = W.TestStrip(frame(), { dock = "title", titleBar = bar, inset = 1 })
    assertPoint(s, 1, "TOPLEFT", bar, "BOTTOMLEFT", 1, 0)
    assertPoint(s, 2, "TOPRIGHT", bar, "BOTTOMRIGHT", -1, 0)
  end)
end)

test("TestStrip dock: BodyOffset is the strip's height while it shows and 0 while hidden", function()
  recording(function()
    local s = W.TestStrip(frame(), { dock = "title", titleBar = frame() })
    assertEqual(s:BodyOffset(), 0, "hidden")
    s:Show()
    assertEqual(s:BodyOffset(), W.TEST_STRIP.HEIGHT, "shown")
    s:SetHeight(30)   -- a host's two-line variant
    assertEqual(s:BodyOffset(), 30, "the strip's own height")
    s:Hide()
    assertEqual(s:BodyOffset(), 0, "hidden again")
  end)
end)

test("TestStrip dock: onOffset is told the offset on each show and hide", function()
  -- red under: drop wireStrip's tellOffset hooks
  recording(function()
    local told = {}
    local s = W.TestStrip(frame(), { dock = "title", titleBar = frame(),
      onOffset = function(offset, strip) told[#told + 1] = offset; assertTrue(strip ~= nil) end })
    s:Show(); s:Hide(); s:Show()
    assertEqual(table.concat(told, ","), "18,0,18")
  end)
end)

test("TestStrip dock: with the title bar hidden the strip sits on the window's top edge", function()
  recording(function()
    local win, bar = frame(), frame()
    local s = W.TestStrip(win, { dock = "title", titleBar = bar, window = win, inset = 1 })
    assertPoint(s, 1, "TOPLEFT", bar, "BOTTOMLEFT", 1, 0, "title bar shown")
    bar:Hide()
    assertPoint(s, 1, "TOPLEFT", win, "TOPLEFT", 1, -1, "title bar hidden: the window's top")
    assertPoint(s, 2, "TOPRIGHT", win, "TOPRIGHT", -1, -1)
    bar:Show()
    assertPoint(s, 1, "TOPLEFT", bar, "BOTTOMLEFT", 1, 0, "back under the title bar")
  end)
end)

test("TestStrip dock: a title-docked strip keeps its menu and its mouse rule", function()
  recording(function()
    local plain = W.TestStrip(frame(), { dock = "title", titleBar = frame() })
    assertFalse(plain:IsMouseEnabled(), "nothing to offer: no mouse, as before")
    local s = W.TestStrip(frame(), { dock = "title", titleBar = frame(), onEnd = function() end })
    assertTrue(s:IsMouseEnabled(), "a strip with an End takes the mouse")
  end)
end)

-- ── on a HUD's top edge ──────────────────────────────────────────────────────────────────────

test("TestStrip dock: 'hud' sits on the display's top edge, outside it, full width", function()
  recording(function()
    at(mocks.UIParent, 768, 0)
    local hud = at(frame(), 400, 300)
    local s = W.TestStrip(mocks.UIParent, { dock = "hud", target = hud })
    assertPoint(s, 1, "BOTTOMLEFT", hud, "TOPLEFT", 0, 0)
    assertPoint(s, 2, "BOTTOMRIGHT", hud, "TOPRIGHT", 0, 0)
    assertFalse(s:IsFlipped())
    assertEqual(s:BodyOffset(), 0, "a HUD has no body to move")
  end)
end)

test("TestStrip dock: 'hud' flips under the bottom edge when the top would leave the screen", function()
  -- red under: drop the flip in placeHud
  recording(function()
    at(mocks.UIParent, 768, 0)
    local hud = at(frame(), 760, 700)   -- 8 under the top: an 18-tall strip would leave it
    local s = W.TestStrip(mocks.UIParent, { dock = "hud", target = hud, gap = 2 })
    assertTrue(s:IsFlipped())
    assertPoint(s, 1, "TOPLEFT", hud, "BOTTOMLEFT", 0, -2)
    assertPoint(s, 2, "TOPRIGHT", hud, "BOTTOMRIGHT", 0, -2)
  end)
end)

test("TestStrip dock: a HUD strip that just fits stays on top, and Place re-reads after a move", function()
  recording(function()
    at(mocks.UIParent, 768, 0)
    local hud = at(frame(), 750, 700)   -- 750 + 18 = 768: exactly at the top, still on screen
    local s = W.TestStrip(mocks.UIParent, { dock = "hud", target = hud })
    assertFalse(s:IsFlipped(), "fits")
    at(hud, 755, 705)   -- the host moved it; a move fires no script
    assertFalse(s:IsFlipped(), "not re-read until Place")
    s:Place()
    assertTrue(s:IsFlipped(), "re-read on Place")
    at(hud, 500, 450)
    s:Show()
    assertFalse(s:IsFlipped(), "a show re-places it too")
  end)
end)

test("TestStrip dock: the flip reads screen pixels, the display's scale and the strip's", function()
  recording(function()
    at(mocks.UIParent, 768, 0, 1)
    local hud = at(frame(), 700, 650, 1.0)
    local s = W.TestStrip(mocks.UIParent, { dock = "hud", target = hud })
    assertFalse(s:IsFlipped(), "700 + 18 fits under 768 at scale 1")
    rawset(s, "GetEffectiveScale", function() return 4 end)   -- 18 units at 4x is 72 px
    s:Place()
    assertTrue(s:IsFlipped(), "700 + 72 leaves 768")
  end)
end)

test("TestStrip dock: a HUD strip with unreadable edges stays on top", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent, { dock = "hud", target = frame() })
    assertFalse(s:IsFlipped())
  end)
end)

test("TestStrip dock: a HUD strip takes no mouse and opens no menu, even given onEnd", function()
  -- red under: wire stripMenu for a 'hud' dock
  recording(function()
    local s = W.TestStrip(mocks.UIParent, { dock = "hud", target = frame(), onEnd = function() end })
    assertFalse(s:IsMouseEnabled())
    assertNil(s:GetScript("OnMouseUp"))
  end)
end)

test("TestStrip dock: docking a menu strip to a HUD later turns the mouse and menu off", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent, { onEnd = function() end })
    assertTrue(s:IsMouseEnabled())
    W.DockTestStrip(s, { dock = "hud", target = frame() })
    assertFalse(s:IsMouseEnabled())
    assertNil(s:GetScript("OnMouseUp"))
  end)
end)

test("TestStrip dock: a HUD strip takes the display's strata, one chrome band over its level", function()
  recording(function()
    local hud = frame()
    hud:SetFrameStrata("LOW"); hud:SetFrameLevel(10)
    local s = W.TestStrip(mocks.UIParent, { dock = "hud", target = hud })
    assertEqual(s.__strata, "LOW")
    assertEqual(s.__level, 15)
  end)
end)

test("TestStrip dock: a HUD strip stacks beyond a shown drag handle, and back when it hides", function()
  recording(function()
    at(mocks.UIParent, 768, 0)
    local hud = at(frame(), 400, 300)
    local handle = at(frame(), 420, 402)   -- 18 tall, 2 over the display
    handle:Hide()
    local s = W.TestStrip(mocks.UIParent, { dock = "hud", target = hud, clear = handle })
    assertPoint(s, 1, "BOTTOMLEFT", hud, "TOPLEFT", 0, 0, "the handle is hidden")
    handle:Show()
    assertPoint(s, 1, "BOTTOMLEFT", hud, "TOPLEFT", 0, 20, "beyond the handle's top")
    handle:Hide()
    assertPoint(s, 1, "BOTTOMLEFT", hud, "TOPLEFT", 0, 0, "back on the edge")
  end)
end)

test("TestStrip dock: the display's show and resize re-place its strip", function()
  recording(function()
    at(mocks.UIParent, 768, 0)
    local hud = at(frame(), 400, 300)
    local s = W.TestStrip(mocks.UIParent, { dock = "hud", target = hud })
    at(hud, 760, 600)
    hud:__fire("OnSizeChanged", 100, 160)
    assertTrue(s:IsFlipped(), "a resize re-reads the edges")
  end)
end)

-- ── the seam itself ──────────────────────────────────────────────────────────────────────────

test("TestStrip dock: a spec naming no usable dock changes nothing and answers nil", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent)
    assertNil(W.DockTestStrip(s, { dock = "title" }), "no title bar")
    assertNil(W.DockTestStrip(s, { dock = "hud" }), "no target")
    assertNil(W.DockTestStrip(s, { dock = "side", titleBar = frame() }), "no such dock")
    assertNil(W.DockTestStrip(s), "no spec")
    assertNil(W.DockTestStrip(nil, { dock = "title", titleBar = frame() }), "no strip")
    assertEqual(s:GetNumPoints(), 0, "still unanchored")
    assertNil(rawget(s, "Place"), "and no dock methods")
  end)
end)

test("TestStrip dock: an undocked strip is minor 26's: unanchored, hidden, no methods", function()
  recording(function()
    local s = W.TestStrip(mocks.UIParent, { text = "x" })
    assertEqual(s:GetNumPoints(), 0)
    assertFalse(s:IsShown())
    assertNil(rawget(s, "Place"))
    assertNil(rawget(s, "BodyOffset"))
  end)
end)

test("TestStrip dock: docking again replaces the dock, and hooks each frame once", function()
  recording(function()
    local bar = frame()
    local told = 0
    local s = W.TestStrip(frame(), { dock = "title", titleBar = bar, onOffset = function() told = told + 1 end })
    assertTrue(W.DockTestStrip(s, { dock = "title", titleBar = bar, inset = 2,
      onOffset = function() told = told + 10 end }) == s)
    assertPoint(s, 1, "TOPLEFT", bar, "BOTTOMLEFT", 2, 0)
    s:Show()
    assertEqual(told, 10, "the new dock's onOffset, once")
  end)
end)

test("TestStrip dock: the dock never shows or hides the strip", function()
  recording(function()
    local bar, win = frame(), frame()
    local s = W.TestStrip(win, { dock = "title", titleBar = bar, window = win })
    bar:Hide(); bar:Show(); win:__fire("OnSizeChanged")
    assertFalse(s:IsShown())
  end)
end)
