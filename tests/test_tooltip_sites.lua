-- tests/test_tooltip_sites.lua — the library's own tooltips on LibKa0s-Tooltip-1.0's placers
-- (LibKa0s#92 part B, LK-92B of Ka0sAddonsCommonTasks docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS,
-- design section 3.6). WowAddonStandards standalone-windows, *Tooltip placement*: "a window the
-- library draws is the library's to move, in that same release". Each case drives one site on the
-- kit's fake screen (tests/_kit/mock_screen.lua) and asserts where its tooltip landed:
--
--   body    beside the window group: TOPLEFT on UIParent's BOTTOMLEFT at the group's right + 2,
--           level with the element's top (IconBrowser cell, dropdown entries, the reorder handle,
--           the sim panel's controls and rows, a chart's marks)
--   chrome  attached and centered ABOVE the element: BOTTOM on UIParent at the element's center, its
--           top + 2 (the icon browser's toolbar, the skin picker's toolbar, a HUD drag strip and its
--           marks, a header mark), below only when there is no room above (smoke round 1, SR-L1)
--   launch  the launcher rule, only for the addon's own minimap button
--
-- The placers' own geometry is tests/test_tooltip_place.lua's; these cases pin that each site goes
-- through one, and with which element and group.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local mocks = T.mocks
local installScreen = dofile("tests/_kit/mock_screen.lua")

-- Every raw field `geo` wrote, put back by `onScreen`: the menu and its rows are pooled, process-wide,
-- and a size left on them would reach the next suite's menu.
local undo = {}
local GEO = { "GetLeft", "GetBottom", "GetRight", "GetTop", "GetWidth", "GetHeight", "GetEffectiveScale", "GetParent" }

--- Give a frame the library built `left`, `bottom`, `width`, `height` in its own units at scale 1,
--- and `parent` as its GetParent when one is named. Undone when the case's screen is restored.
local function geo(f, left, bottom, width, height, parent)
  for _, k in ipairs(GEO) do undo[#undo + 1] = { f, k, rawget(f, k) } end
  rawset(f, "GetLeft", function() return left end)
  rawset(f, "GetBottom", function() return bottom end)
  rawset(f, "GetRight", function() return left + width end)
  rawset(f, "GetTop", function() return bottom + height end)
  rawset(f, "GetWidth", function() return width end)
  rawset(f, "GetHeight", function() return height end)
  rawset(f, "GetEffectiveScale", function() return 1 end)
  if parent then rawset(f, "GetParent", function() return parent end) end
  return f
end

local function undoGeo()
  for i = #undo, 1, -1 do
    local e = undo[i]
    rawset(e[1], e[2], e[3])
    undo[i] = nil
  end
end

local TIP_METHODS = { "SetOwner", "GetOwner", "IsOwned", "ClearAllPoints", "SetPoint", "SetAnchorType",
                      "GetWidth", "GetHeight", "GetEffectiveScale", "Show", "Hide", "IsShown",
                      "SetText", "AddLine" }

--- Record `m.GameTooltip`: its owner, every point, a 200 x 80 size. Answers the tooltip and a
--- restore; `tip.__point` is the last point, `tip.__anchor` the last owner anchor.
local function recordTip(m)
  local tip = m.GameTooltip
  local saved = {}
  for _, k in ipairs(TIP_METHODS) do saved[k] = rawget(tip, k) end
  tip.__point, tip.__owner, tip.__anchor, tip.__kinds, tip.__lines = nil, nil, nil, nil, nil
  rawset(tip, "SetOwner", function(self, owner, anchor) self.__owner, self.__anchor = owner, anchor end)
  rawset(tip, "GetOwner", function(self) return self.__owner end)
  rawset(tip, "IsOwned", function(self, f) return self.__owner == f end)
  rawset(tip, "ClearAllPoints", function(self) self.__point = nil end)
  rawset(tip, "SetPoint", function(self, point, rel, relPoint, x, y)
    self.__point = { point = point, rel = rel, relPoint = relPoint, x = x or 0, y = y or 0 }
  end)
  rawset(tip, "SetAnchorType", function(self, a) self.__kinds = a end)
  rawset(tip, "GetWidth", function() return 200 end)
  rawset(tip, "GetHeight", function() return 80 end)
  rawset(tip, "GetEffectiveScale", function() return 1 end)
  rawset(tip, "Show", function(self) self.__up = true end)
  rawset(tip, "Hide", function(self) self.__up = false end)
  rawset(tip, "IsShown", function(self) return self.__up == true end)
  rawset(tip, "SetText", function(self, text, r, g, b)
    self.__lines = { { text = text, r = r, g = g, b = b } }
  end)
  rawset(tip, "AddLine", function(self, text, r, g, b, wrap)
    self.__lines = self.__lines or {}
    self.__lines[#self.__lines + 1] = { text = text, r = r, g = g, b = b, wrap = wrap }
  end)
  return tip, function() for _, k in ipairs(TIP_METHODS) do rawset(tip, k, saved[k]) end end
end

--- Run `fn(scr, tip)` on `m` with a 1920 x 1080 screen and a recorded tooltip, restored after.
local function onScreen(m, fn)
  local scr = installScreen(m, { width = 1920, height = 1080, scale = 1 })
  local tip, restore = recordTip(m)
  local ok, err = pcall(fn, scr, tip)
  undoGeo()
  restore()
  scr.restore()
  if not ok then error(err, 0) end
end

--- The body rule's point beside a group whose right edge is `groupRight`, for an element topped at
--- `top`: TOPLEFT on UIParent's BOTTOMLEFT at (groupRight + 2, top).
local function assertBeside(m, tip, groupRight, top, what)
  local p = tip.__point
  assertTrue(p ~= nil, what .. ": placed")
  assertEqual(p.point, "TOPLEFT", what .. ": the body rule's right side")
  assertTrue(p.rel == m.UIParent, what .. ": an absolute point on UIParent")
  assertEqual(p.relPoint, "BOTTOMLEFT", what)
  assertEqual(p.x, groupRight + 2, what .. ": the group's right edge plus TIP_GAP")
  assertEqual(p.y, top, what .. ": level with the element's top")
end

--- The chrome rule's point over an element spanning `left`..`right` with top `top`: BOTTOM on
--- UIParent's BOTTOMLEFT at (center, top + 2).
local function assertAbove(m, tip, left, right, top, what)
  local p = tip.__point
  assertTrue(p ~= nil, what .. ": placed")
  assertEqual(p.point, "BOTTOM", what .. ": attached above")
  assertTrue(p.rel == m.UIParent, what .. ": an absolute point on UIParent")
  assertEqual(p.relPoint, "BOTTOMLEFT", what)
  assertEqual(p.x, (left + right) / 2, what .. ": centered on the element")
  assertEqual(p.y, top + 2, what .. ": TIP_GAP over it")
end

--- The hand fallback a site writes when the geometry cannot be read: the same side, by a relative
--- point, BOTTOM on the element's TOP, TIP_GAP up.
local function assertAboveRelative(tip, el, what)
  local p = tip.__point
  assertTrue(p ~= nil, what .. ": placed")
  assertEqual(p.point, "BOTTOM", what .. ": above")
  assertTrue(p.rel == el, what .. ": relative to the element")
  assertEqual(p.relPoint, "TOP", what)
  assertEqual(p.x, 0, what); assertEqual(p.y, 2, what .. ": TIP_GAP over it")
end

-- ── the icon browser ────────────────────────────────────────────────────────────────────────

local IBF = dofile("tests/fixture_icon_browser.lua")

test("tooltip sites: an icon browser cell opens beside the browser window", function()
  -- red under: SetOwner(cell, "ANCHOR_RIGHT"), the cell's own right edge inside the window
  local m, B = IBF.boot()
  IBF.spells(m, IBF.range(300000, 50))
  IBF.openOn(B, nil)
  B:SetTab("game")
  onScreen(m, function(_, tip)
    geo(B.frame, 600, 200, 500, 600)
    local cell = B.cells[1]
    geo(cell, 620, 700, 32, 32, B.frame)
    cell:__fire("OnEnter")
    assertTrue(tip.__owner == cell, "owned by the cell")
    assertEqual(tip.__anchor, "ANCHOR_NONE")
    assertBeside(m, tip, 1100, 732, "cell")
  end)
end)

test("tooltip sites: the icon browser's toolbar tips attach above their control", function()
  -- red under: AttachTooltip's ANCHOR_RIGHT on a control of the window's top chrome, or the tip
  -- attached below it, where the pointer hangs (SR-L1)
  local m, B = IBF.boot()
  IBF.openOn(B, nil)
  B:SetTab("game")
  onScreen(m, function(_, tip)
    local filter = B:Widgets().filter
    geo(filter.frame, 640, 700, 120, 24)
    filter.callbacks.OnEnter(filter)
    assertTrue(tip.__owner == filter.frame, "owned by the control")
    assertAbove(m, tip, 640, 760, 724, "toolbar")
    -- the body line as AttachTooltip drew it: wrapped, in the host's __tipColor
    local body = tip.__lines and tip.__lines[2]
    assertTrue(body ~= nil, "toolbar: a body line")
    assertEqual(body.wrap, true, "toolbar: the body line wraps")
    filter.callbacks.OnLeave(filter)
    -- helpers without __tipColor: the same, never white
    local saved = B.helpers.__tipColor
    B.helpers.__tipColor = nil
    local ok, err = pcall(function()
      filter.callbacks.OnEnter(filter)
      local line = tip.__lines and tip.__lines[2]
      assertTrue(line ~= nil and line.wrap == true, "toolbar (no __tipColor): the body line wraps")
      assertNil(line.r, "toolbar (no __tipColor): the body in the client's color")
      filter.callbacks.OnLeave(filter)
    end)
    B.helpers.__tipColor = saved
    if not ok then error(err, 0) end
    assertTrue(tip.__up == false, "leaving hides it")
  end)
end)

-- ── the dropdown's entries, the reorder handle ──────────────────────────────────────────────

local W = T.widgets

local function menuAnchor() return mocks.CreateFrame("Button", nil, mocks.UIParent) end

test("tooltip sites: a dropdown entry's string tip opens beside the menu", function()
  -- red under: SetOwner(row, "ANCHOR_RIGHT"), which lands on the row inside the menu
  onScreen(mocks, function(_, tip)
    local menu = W.ContextMenu(menuAnchor(), { { label = "A", tooltip = "Why" }, { label = "B" } })
    geo(menu, 300, 400, 180, 60)
    local row = menu.buttons[1]
    geo(row, 302, 440, 176, 16, menu)
    row:GetScript("OnEnter")(row)
    assertEqual(tip.__anchor, "ANCHOR_NONE")
    assertBeside(mocks, tip, 480, 456, "entry")
    W.CloseMenu()
  end)
end)

test("tooltip sites: a host's tooltip renderer draws, then the library places it beside the menu", function()
  -- red under: the renderer's own anchor kept, or a re-place of a tooltip the renderer never showed
  onScreen(mocks, function(_, tip)
    local drew = 0
    local menu = W.ContextMenu(menuAnchor(), {
      { label = "A", tooltip = function(frame) drew = drew + 1; tip:SetOwner(frame, "ANCHOR_NONE"); tip:Show() end },
      { label = "B", tooltip = function() drew = drew + 1 end },
    })
    geo(menu, 300, 400, 180, 60)
    local a, b = menu.buttons[1], menu.buttons[2]
    geo(a, 302, 440, 176, 16, menu)
    geo(b, 302, 420, 176, 16, menu)
    a:GetScript("OnEnter")(a)
    assertEqual(drew, 1)
    assertBeside(mocks, tip, 480, 456, "renderer")
    tip.__point, tip.__up, tip.__owner = nil, false, nil
    b:GetScript("OnEnter")(b)
    assertEqual(drew, 2)
    assertNil(tip.__point, "a renderer that showed nothing is not placed")
    W.CloseMenu()
  end)
end)

test("tooltip sites: the reorder handle's tip opens beside its window", function()
  -- red under: SetOwner(handle, "ANCHOR_RIGHT")
  onScreen(mocks, function(_, tip)
    local win = geo(mocks.CreateFrame("Frame", nil, mocks.UIParent), 200, 300, 400, 500)
    local list = W.ReorderList({ stride = 30, handleTooltip = "Drag to move" })
    local handle = list:AddRow(win, {})
    geo(handle, 210, 700, 16, 16, win)
    handle:__fire("OnEnter")
    assertTrue(tip.__owner == handle)
    assertEqual(tip.__anchor, "ANCHOR_NONE")
    assertBeside(mocks, tip, 600, 716, "handle")
  end)
end)

-- ── the sim panel ───────────────────────────────────────────────────────────────────────────

local SF = dofile("tests/fixture_sim_panel.lua")

test("tooltip sites: the sim panel's controls open their tips beside the panel", function()
  -- red under: tip:SetOwner(owner, "ANCHOR_RIGHT") in showTip
  local b = SF.bench()
  SF.recording(b.m, function()
    local f = SF.shown(b)
    onScreen(b.m, function(_, tip)
      geo(f, 1000, 300, 420, 360)
      local btn = SF.buttons(f)[2]
      geo(btn, 1010, 560, 200, 20, f)
      btn:__fire("OnEnter")
      assertTrue(tip.__owner == btn)
      assertEqual(tip.__anchor, "ANCHOR_NONE")
      assertBeside(b.m, tip, 1420, 580, "sim row")
    end)
  end)
end)

-- ── the drag handle ─────────────────────────────────────────────────────────────────────────

local DH = dofile("tests/fixture_draghandle.lua")

local function stripOf(spec)
  local h = W.DragHandle(mocks.UIParent, DH.baseSpec(spec))
  geo(h, 800, 600, 160, 18)
  return h
end

DH.test("tooltip sites: a HUD drag strip's tooltip attaches above the strip, owned by UIParent", function()
  -- red under: SetOwner(strip, "ANCHOR_TOP"), the client's anchor, or the tip attached below the
  -- strip, under the pointer (SR-L1)
  onScreen(mocks, function(_, tip)
    local h = stripOf({ tooltip = { title = "Buffs" } })
    h:__fire("OnEnter")
    assertTrue(tip.__owner == mocks.UIParent, "restricted-tree safe: UIParent owns it")
    assertEqual(tip.__anchor, "ANCHOR_NONE")
    assertAbove(mocks, tip, 800, 960, 618, "strip")
  end)
end)

DH.test("tooltip sites: tooltipOwner = \"cursor\" and tooltipAnchor are retired to the attached placer", function()
  -- red under: SetOwner(UIParent, "ANCHOR_CURSOR"), which #119 forbids
  onScreen(mocks, function(_, tip)
    local h = stripOf({ tooltip = { title = "Buffs" }, tooltipOwner = "cursor", tooltipAnchor = "ANCHOR_TOPRIGHT" })
    h:__fire("OnEnter")
    assertEqual(tip.__anchor, "ANCHOR_NONE")
    assertAbove(mocks, tip, 800, 960, 618, "cursor owner")
  end)
end)

DH.test("tooltip sites: a strip's mark places by its strip, not by the mark", function()
  onScreen(mocks, function(_, tip)
    local h = stripOf({ tooltip = { title = "Buffs" }, onRightClick = function() end })
    geo(h.help, 942, 600, 18, 18, h)
    h.help:__fire("OnEnter")
    assertAbove(mocks, tip, 800, 960, 618, "mark")
  end)
end)

DH.test("tooltip sites: a host placement that fails changes nothing: above the strip, never the cursor", function()
  -- red under: the minor 4 fallback, SetOwner(UIParent, "ANCHOR_CURSOR")
  onScreen(mocks, function(_, tip)
    local h = stripOf({ tooltip = { title = "Buffs" }, tooltipPlace = function() error("no rect") end })
    h:__fire("OnEnter")
    assertEqual(tip.__anchor, "ANCHOR_NONE")
    assertAbove(mocks, tip, 800, 960, 618, "a raise")
    local silent = stripOf({ tooltip = { title = "Buffs" }, tooltipPlace = function() return false end })
    silent:__fire("OnEnter")
    assertAbove(mocks, tip, 800, 960, 618, "a false answer")
  end)
end)

DH.test("tooltip sites: a host placement that answers true no longer moves the strip's tooltip", function()
  -- WidgetsDragHandleTip minor 2 (AF-LK-02): the strip's tooltip, and its marks', attach above the
  -- strip everywhere; a host's `tooltipPlace` is accepted and ignored. red under: minor 1, where the
  -- hook's point stood (Aura Master's tooltip beside its strip, the owner's image 11).
  onScreen(mocks, function(_, tip)
    local called = false
    local h = stripOf({ tooltip = { title = "Buffs" }, onRightClick = function() end, tooltipPlace = function(t)
      called = true
      t:ClearAllPoints(); t:SetPoint("LEFT", mocks.UIParent, "BOTTOMLEFT", 1, 2); return true
    end })
    h:__fire("OnEnter")
    assertTrue(not called, "the hook is not called")
    assertAbove(mocks, tip, 800, 960, 618, "beside-the-strip hook")
    geo(h.help, 942, 600, 14, 18, h)
    h.help:__fire("OnEnter")
    assertAbove(mocks, tip, 800, 960, 618, "a mark, with the same hook")
  end)
end)

-- ── the charts ──────────────────────────────────────────────────────────────────────────────

local CF = dofile("tests/fixture_charts.lua")

local function chartRow(m, C, host)
  local content = CF.content(m)
  local ctx = C:New(content, host or {})
  local pool = ctx:Pool("list")
  ctx:renderListPanel(pool, ctx:listPanel(nil, "T"), { { name = "A", right = "1", tip = { "Title", "line" } } }, 0, 300, 8)
  return ctx, pool.active[1], content
end

test("tooltip sites: a chart mark's default tooltip opens beside the chart's window group", function()
  -- red under: plainTip's SetOwner(owner, "ANCHOR_CURSOR_RIGHT")
  local m, C = CF.env({ full = true })
  onScreen(m, function(_, tip)
    local win = geo(m.CreateFrame("Frame", nil, m.UIParent), 100, 100, 700, 600)
    local ctx, row = chartRow(m, C, { group = win })
    assertTrue(ctx ~= nil)
    geo(row, 120, 500, 300, 18, win)
    row:GetScript("OnEnter")(row)
    assertTrue(tip.__owner == row)
    assertEqual(tip.__anchor, "ANCHOR_NONE")
    assertBeside(m, tip, 800, 518, "chart row")
  end)
end)

test("tooltip sites: a host's tip seam gets the legacy anchor and a fourth argument, the context", function()
  -- Additive: the host keeps arg 3 (its frozen -1.0 contract) and may place through ctx:PlaceTip.
  local m, C = CF.env({ full = true })
  onScreen(m, function(_, tip)
    local win = geo(m.CreateFrame("Frame", nil, m.UIParent), 100, 100, 700, 600)
    local got
    local ctx, row = chartRow(m, C, { group = function() return win end, tip = function(owner, _, anchor, c)
      got = { owner = owner, anchor = anchor, ctx = c }
      tip:SetOwner(owner, "ANCHOR_NONE"); tip:Show()
      got.side = c:PlaceTip(tip, owner)
    end })
    geo(row, 120, 500, 300, 18, win)
    row:GetScript("OnEnter")(row)
    assertTrue(got.ctx == ctx, "the context is the fourth argument")
    assertEqual(type(got.anchor), "string", "arg 3 is still an anchor string")
    assertEqual(got.side, "right")
    assertBeside(m, tip, 800, 518, "PlaceTip")
  end)
end)

-- ── the launcher ────────────────────────────────────────────────────────────────────────────

local LB = dofile("tests/fixture_launcher.lua")

test("tooltip sites: the launcher re-places its own minimap button's tooltip, and no one else's", function()
  -- red under: LibDBIcon's 0 px getAnchors kept, or a broker display's tooltip moved
  onScreen(mocks, function(scr)
    local rec = LB.fixture()
    local L = mocks.LibStub("LibKa0s-Launcher-1.0"):New(rec.d)
    assertTrue(L:Register())
    local ICON = LB.ICON
    local button = scr.frame{ left = 1800, bottom = 980, width = 31, height = 31 }
    local own = scr.tooltip{ width = 220, height = 120 }
    local savedTip, savedGet = rawget(ICON, "tooltip"), rawget(ICON, "GetMinimapButton")
    ICON.tooltip = own
    ICON.GetMinimapButton = function(_, name) if name == rec.name then return button end end
    local ok, err = pcall(function()
      own:SetOwner(button, "ANCHOR_NONE")
      L:Object().OnTooltipShow(own)
      assertEqual(own.__point.point, "TOPRIGHT", "upper right of the screen: below, right edges level")
      assertTrue(own.__point.rel == button)
      assertEqual(own.__point.relPoint, "BOTTOMRIGHT")
      assertEqual(own.__point.y, -2, "TIP_GAP off the button")

      local broker = scr.tooltip{ width = 220, height = 120 }
      broker:SetOwner(button, "ANCHOR_NONE")
      L:Object().OnTooltipShow(broker)
      assertNil(broker.__point, "a broker display's own tooltip keeps its anchor")

      local other = scr.frame{ left = 10, bottom = 10, width = 31, height = 31 }
      own.__point = nil
      own:SetOwner(other, "ANCHOR_NONE")
      L:Object().OnTooltipShow(own)
      assertNil(own.__point, "the library tooltip on another owner (the compartment) is not moved")
    end)
    ICON.tooltip, ICON.GetMinimapButton = savedTip, savedGet
    if not ok then error(err, 0) end
  end)
end)

-- ── the skin picker ─────────────────────────────────────────────────────────────────────────

local SP = dofile("tests/fixture_skin_picker.lua")

test("tooltip sites: the skin picker's toolbar controls attach their tips above", function()
  -- red under: SetOwner(self, "ANCHOR_TOP") on the gear, the eye and the dropdown (R9 C1), or the
  -- tips attached below them (SR-L1)
  local m, Skin, lib = SP.env()
  local store = SP.register(Skin, "PickerTipHost", "azeroth")
  local f = SP.instance(lib, "PickerTipHost").SkinPicker(SP.specFor(store, { page = "general" }))
  onScreen(m, function(_, tip)
    for _, key in ipairs({ "settings", "dd" }) do
      local btn = f[key]
      geo(btn, 700, 640, 24, 24)
      btn:__fire("OnEnter")
      assertTrue(tip.__owner == btn, key .. ": owned by the control")
      assertEqual(tip.__anchor, "ANCHOR_NONE", key)
      assertAbove(m, tip, 700, 724, 664, key)
    end
  end)
end)

-- ── the hand fallbacks (SR-L1) ──────────────────────────────────────────────────────────────

test("tooltip sites: unreadable geometry attaches every chrome tip above its element by hand", function()
  -- red under: the fallbacks' old point, TOP on the element's BOTTOM, 2 down (under the pointer)
  local m, Skin, lib = SP.env()
  local store = SP.register(Skin, "PickerTipFallback", "azeroth")
  local f = SP.instance(lib, "PickerTipFallback").SkinPicker(SP.specFor(store, { page = "general" }))
  onScreen(m, function(_, tip)
    f.settings:__fire("OnEnter")
    assertAboveRelative(tip, f.settings, "skin picker gear")
  end)
  onScreen(mocks, function(_, tip)
    local bar = mocks.CreateFrame("Frame", nil, mocks.CreateFrame("Frame", nil, mocks.UIParent))
    local hb = W.HeaderButtons(bar, {})
    hb.settings:__fire("OnEnter")
    assertAboveRelative(tip, hb.settings, "header mark")
  end)
end)

-- ── a strip whose rect reads secret (WidgetsDragHandleTip minor 3, SD-LK-99, LibKa0s#99) ────────
--
-- The owner's ruling R-3 (2026-11-20): a strip whose own rect reads secret places its tooltip above
-- the NEAREST ANCESTOR WHOSE RECT READS, by the same absolute point on UIParent, with the same
-- above/below rule; above the strip whenever the strip reads; secret all the way up is no tooltip and
-- no error. The secrets are the kit's (testkit/secrets.lua): a wrapper traps any arithmetic on it,
-- so a case that passes did none, and `issecretvalue` answers true for each.

local Kit = dofile("tests/_kit/framework.lua")

--- Run `fn()` with the client's `issecretvalue` answering the kit's secrets, restored after.
local function withSecretValue(fn)
  local saved = rawget(mocks, "issecretvalue")
  mocks.issecretvalue = function(v) return Kit.isSecret(v) end
  local ok, err = pcall(fn)
  mocks.issecretvalue = saved
  if not ok then error(err, 0) end
end

--- Make `f`'s every geometry read secret (its parent, when named, still reads), undone with `geo`'s.
local function secretGeo(f, parent)
  for _, k in ipairs(GEO) do undo[#undo + 1] = { f, k, rawget(f, k) } end
  for _, k in ipairs({ "GetLeft", "GetBottom", "GetRight", "GetTop", "GetWidth", "GetHeight" }) do
    rawset(f, k, function() return Kit.secret(500) end)
  end
  rawset(f, "GetEffectiveScale", function() return 1 end)
  if parent then rawset(f, "GetParent", function() return parent end) end
  return f
end

--- A frame under UIParent, as an ancestor of a strip.
local function holder(parent)
  return mocks.CreateFrame("Frame", nil, parent or mocks.UIParent)
end

DH.test("tooltip sites: a strip whose rect reads places above the strip, not its readable parent", function()
  -- red under: a walk that started at the parent
  withSecretValue(function()
    onScreen(mocks, function(_, tip)
      local parent = geo(holder(), 600, 400, 600, 300, mocks.UIParent)
      local h = W.DragHandle(parent, DH.baseSpec({ tooltip = { title = "Buffs" }, onRightClick = function() end }))
      geo(h, 800, 600, 160, 18, parent)
      h:__fire("OnEnter")
      assertAbove(mocks, tip, 800, 960, 618, "readable strip")
      assertTrue(tip:IsShown(), "shown")
    end)
  end)
end)

DH.test("tooltip sites: a strip whose rect reads secret places above its nearest readable ancestor", function()
  -- red under: WidgetsDragHandleTip minor 2, which fell back to a relative point on the strip (a
  -- point into the restricted tree, refused in the client: Aura Master's strip, LibKa0s#99)
  withSecretValue(function()
    onScreen(mocks, function(_, tip)
      local parent = geo(holder(), 700, 500, 400, 120, mocks.UIParent)
      local h = W.DragHandle(parent, DH.baseSpec({ tooltip = { title = "Buffs" }, onRightClick = function() end }))
      secretGeo(h, parent)
      h:__fire("OnEnter")
      assertAbove(mocks, tip, 700, 1100, 620, "secret strip, readable parent")
      assertTrue(tip:IsShown(), "shown")
      geo(h.help, 942, 600, 14, 18, h)
      h.help:__fire("OnEnter")
      assertAbove(mocks, tip, 700, 1100, 620, "a mark of the secret strip places by the same ancestor")
    end)
  end)
end)

DH.test("tooltip sites: the walk skips a secret parent for the nearest readable one further up", function()
  withSecretValue(function()
    onScreen(mocks, function(_, tip)
      local outer = geo(holder(), 100, 200, 300, 400, mocks.UIParent)
      local inner = secretGeo(holder(outer), outer)
      local h = W.DragHandle(inner, DH.baseSpec({ tooltip = { title = "Buffs" } }))
      secretGeo(h, inner)
      h:__fire("OnEnter")
      assertAbove(mocks, tip, 100, 400, 600, "the grandparent")
    end)
  end)
end)

DH.test("tooltip sites: a readable ancestor at the screen's top takes the tooltip below it", function()
  -- the strip's own rule (SR-L1): below only when there is no room above
  withSecretValue(function()
    onScreen(mocks, function(_, tip)
      local parent = geo(holder(), 700, 1000, 400, 70, mocks.UIParent)
      local h = W.DragHandle(parent, DH.baseSpec({ tooltip = { title = "Buffs" } }))
      secretGeo(h, parent)
      h:__fire("OnEnter")
      local p = tip.__point
      assertTrue(p ~= nil, "placed")
      assertEqual(p.point, "TOP", "below the ancestor")
      assertTrue(p.rel == mocks.UIParent, "an absolute point on UIParent")
      assertEqual(p.x, 900, "centered on the ancestor")
      assertEqual(p.y, 998, "TIP_GAP under its bottom")
    end)
  end)
end)

DH.test("tooltip sites: a strip secret all the way up shows no tooltip, raises nothing, anchors nothing", function()
  -- red under: minor 2's relative point on the strip, or a placement above UIParent (the screen)
  withSecretValue(function()
    onScreen(mocks, function(_, tip)
      local parent = secretGeo(holder(), mocks.UIParent)
      local h = W.DragHandle(parent, DH.baseSpec({ tooltip = { title = "Buffs" }, onRightClick = function() end }))
      secretGeo(h, parent)
      h:__fire("OnEnter")
      assertNil(tip.__point, "no point, so nothing anchored into the restricted tree")
      assertTrue(not tip:IsShown(), "no tooltip")
      geo(h.help, 942, 600, 14, 18, h)
      h.help:__fire("OnEnter")
      assertNil(tip.__point, "a mark: no point either")
      assertTrue(not tip:IsShown(), "a mark: no tooltip")
    end)
  end)
end)

DH.test("tooltip sites: a strip with unreadable geometry and no readable ancestor shows no tooltip", function()
  -- An unplaced strip under UIParent reads nil, as a secret one does. Through minor 2 it was attached
  -- by a relative point on the strip; from minor 3 nothing anchors into the strip.
  onScreen(mocks, function(_, tip)
    local h = W.DragHandle(mocks.UIParent, DH.baseSpec({ tooltip = { title = "Buffs" } }))
    h:__fire("OnEnter")
    assertNil(tip.__point, "no relative point on the strip")
    assertTrue(not tip:IsShown(), "no tooltip")
  end)
end)

DH.test("tooltip sites: WidgetsDragHandleTip is at minor 3 or later, the readable-ancestor walk", function()
  assertTrue(W.MODULES.WidgetsDragHandleTip >= 3)
  assertTrue(W.__dragTipMinor >= 3)
end)

test("tooltip sites: a body site with unreadable geometry falls back above its element", function()
  -- red under: the body sites' hand fallback, TOP on the element's BOTTOM
  onScreen(mocks, function(_, tip)
    local menu = W.ContextMenu(menuAnchor(), { { label = "A", tooltip = "Why" } })
    local row = menu.buttons[1]
    row:GetScript("OnEnter")(row)
    assertAboveRelative(tip, row, "dropdown entry")
    W.CloseMenu()
    local list = W.ReorderList({ stride = 30, handleTooltip = "Drag to move" })
    local handle = list:AddRow(mocks.CreateFrame("Frame", nil, mocks.UIParent), {})
    handle:__fire("OnEnter")
    assertAboveRelative(tip, handle, "reorder handle")
  end)
end)
