-- tests/test_waypoint_arrow_menu.lua — LibKa0s-WaypointArrow-1.0 minor 2: the right-click menu (Skill
-- Master round 9, L4). The Widgets major is a stand-in recording each ContextMenu call; the chat box
-- and the world map are client fakes the cases set.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_waypoint_arrow.lua")

--- An arrow with a Widgets stand-in, a chat box and a world map: answers the arrow, the mocks and
--- the record (`menus`, `chat`, `maps`, plus the bench's own).
local function menuArrow(d, before)
  local rec = { menus = {}, chat = {}, maps = {} }
  local a, m, Arrow, bench = F.newArrow(d, function(mm)
    local W = mm.LibStub:NewLibrary("LibKa0s-Widgets-1.0", 1)
    function W.ContextMenu(anchor, rows, opts)
      rec.menus[#rec.menus + 1] = { anchor = anchor, rows = rows, opts = opts }
      return {}
    end
    mm.ChatFrame_OpenChat = function(text) rec.chat[#rec.chat + 1] = text end
    mm.C_Map.OpenWorldMap = function(id) rec.maps[#rec.maps + 1] = id end
    mm.C_Map.GetMapInfo = function(id) if id == 1429 then return { name = "Elwynn Forest" } end end
    mm.InCombatLockdown = function() return mm.__combat == true end
    if before then before(mm) end
  end)
  for k, v in pairs(bench) do rec[k] = v end
  return a, m, Arrow, rec
end

local TARGET = { mapID = 1429, x = 0.4521, y = 0.6309, label = "Master Smith" }

local function ids(rows)
  local out = {}
  for i, r in ipairs(rows) do out[i] = r.id or "?" end
  return table.concat(out, ",")
end

local function item(rows, id)
  for _, r in ipairs(rows) do if r.id == id then return r end end
end

local function rightClick(a) a:Frame():__fire("OnMouseUp", "RightButton") end

test("arrow menu: a right-click opens the menu at the pointer with the stock items, Clear first", function()
  local a, _, _, rec = menuArrow({ skin = "TestAddon" })
  a:SetTarget(TARGET)
  rightClick(a)
  local menu = rec.menus[1]
  assertTrue(menu ~= nil, "opened")
  assertEqual(menu.anchor, a:Frame())
  assertTrue(menu.opts.cursor, "at the pointer")
  assertEqual(menu.opts.owner, "TestAddon", "in the host's skin")
  assertEqual(ids(menu.rows), "clear,share,map,lock,reset")
  local labels = {}
  for i, r in ipairs(menu.rows) do labels[i] = r.label end
  assertEqual(table.concat(labels, "|"), "Clear waypoint|Share in chat|Show on map|Lock the arrow|Reset position")
  assertEqual(#rec.clicks, 0, "the right button no longer reaches onClick")
  a:Frame():__fire("OnMouseUp", "LeftButton")
  assertEqual(rec.clicks[1], "LeftButton", "the left button still does")
end)

test("arrow menu: d.menu = false, or no Widgets major, keeps the old right-click", function()
  local a, _, _, rec = menuArrow({ menu = false })
  a:SetTarget(TARGET)
  rightClick(a)
  assertEqual(#rec.menus, 0)
  assertEqual(rec.clicks[1], "RightButton")
  assertFalse(a:OpenMenu())
  local b, _, _, brec = F.newArrow()
  b:SetTarget(TARGET)
  b:Frame():__fire("OnMouseUp", "RightButton")
  assertEqual(brec.clicks[1], "RightButton", "no Widgets: onClick as before")
end)

test("arrow menu: Clear waypoint goes to the host's onClear with the target, else clears", function()
  local cleared = {}
  local a, _, _, rec = menuArrow({ onClear = function(t) cleared[#cleared + 1] = t or false end })
  a:SetTarget(TARGET)
  rightClick(a)
  item(rec.menus[1].rows, "clear").onClick()
  assertEqual(cleared[1].label, "Master Smith", "the host owns the waypoint")
  local b, _, _, brec = menuArrow()
  b:SetTarget(TARGET)
  rightClick(b)
  item(brec.menus[1].rows, "clear").onClick()
  assertFalse(b:IsShown(), "no onClear: the arrow clears itself")
  assertNil(b:Target())
end)

test("arrow menu: Share in chat opens the chat box with the /way line and never sends", function()
  local a, m, Arrow, rec = menuArrow()
  local sent = 0
  m.SendChatMessage = function() sent = sent + 1 end
  a:SetTarget(TARGET)
  rightClick(a)
  local share = item(rec.menus[1].rows, "share")
  assertFalse(share.disabled == true)
  share.onClick()
  assertEqual(rec.chat[1], "/way Elwynn Forest 45.2, 63.1 Master Smith")
  assertEqual(sent, 0, "nothing sent")
  assertEqual(Arrow.ShareText({ mapID = 7, x = 0.5, y = 0.25 }), "/way 50.0, 25.0", "no zone, no label")
  assertNil(Arrow.ShareText({ instance = 1, wx = 1, wy = 1 }), "a world target has no map point")
end)

test("arrow menu: Share in chat prefers ChatFrameUtil.OpenChat where the client has it", function()
  local a, m, _, rec = menuArrow()
  local util = {}
  m.ChatFrameUtil = { OpenChat = function(text) util[#util + 1] = text end }
  a:SetTarget(TARGET)
  rightClick(a)
  item(rec.menus[1].rows, "share").onClick()
  assertEqual(util[1], "/way Elwynn Forest 45.2, 63.1 Master Smith")
  assertEqual(#rec.chat, 0)
end)

test("arrow menu: Show on map opens the world map at the target's map, and not in combat", function()
  local a, m, _, rec = menuArrow()
  a:SetTarget(TARGET)
  rightClick(a)
  item(rec.menus[1].rows, "map").onClick()
  assertEqual(rec.maps[1], 1429)
  m.__combat = true
  rightClick(a)
  rightClick(a)
  local map = item(rec.menus[#rec.menus].rows, "map")
  assertTrue(map.disabled == true, "disabled in combat")
  assertEqual(map.tooltip, "Not available in combat.")
  map.onClick()
  assertEqual(#rec.maps, 1, "and refused if reached anyway")
end)

test("arrow menu: the sample's map items are disabled and its Clear still works", function()
  local a, _, _, rec = menuArrow()
  a:ShowSample()
  rightClick(a)
  local rows = rec.menus[1].rows
  assertTrue(item(rows, "share").disabled == true)
  assertTrue(item(rows, "map").disabled == true)
  assertEqual(item(rows, "share").tooltip, "This waypoint has no map point to share or show.")
  item(rows, "clear").onClick()
  assertFalse(a:IsShown(), "the sample's Clear hides it")
end)

test("arrow menu: Lock and Unlock toggle the lock through the host; Reset position resets", function()
  local store = {}
  local a, _, _, rec = menuArrow({ paths = { lock = "w.lock", x = "w.x", y = "w.y" },
    set = function(p, v) store[p] = v end })
  a:SetTarget(TARGET)
  a:Configure({ x = 50 })
  rightClick(a)
  item(rec.menus[1].rows, "lock").onClick()
  assertEqual(store["w.lock"], true)
  assertTrue(a:IsLocked())
  rightClick(a)
  rightClick(a)
  local unlock = item(rec.menus[#rec.menus].rows, "lock")
  assertEqual(unlock.label, "Unlock the arrow")
  unlock.onClick()
  assertEqual(store["w.lock"], false)
  item(rec.menus[#rec.menus].rows, "reset").onClick()
  assertEqual(store["w.x"], 0)
  assertEqual(store["w.y"], 200)
end)

test("arrow menu: the host's menuItems adds, reorders or replaces the items", function()
  local seen
  local a, _, _, rec = menuArrow({ menuItems = function(items, target, arrow)
    seen = { target = target, arrow = arrow }
    table.insert(items, 2, { id = "trainers", label = "Show trainers", onClick = function() end })
    return items
  end })
  a:SetTarget(TARGET)
  rightClick(a)
  assertEqual(ids(rec.menus[1].rows), "clear,trainers,share,map,lock,reset")
  assertEqual(seen.target.label, "Master Smith")
  assertEqual(seen.arrow, a)
  assertEqual(ids(a:MenuItems()), "clear,trainers,share,map,lock,reset", "MenuItems answers the same")
end)

test("arrow menu: d.strings words the items", function()
  local a = menuArrow({ strings = { MENU_CLEAR = "Effacer" } })
  a:SetTarget(TARGET)
  assertEqual(a:MenuItems()[1].label, "Effacer")
  assertEqual(a:MenuItems()[2].label, "Share in chat")
end)

test("arrow menu: OpenMenu opens it as a right-click does", function()
  local a, _, _, rec = menuArrow()
  a:SetTarget(TARGET)
  assertTrue(a:OpenMenu())
  assertEqual(#rec.menus, 1)
end)
