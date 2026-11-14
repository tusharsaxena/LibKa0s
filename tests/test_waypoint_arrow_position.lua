-- tests/test_waypoint_arrow_position.lua — LibKa0s-WaypointArrow-1.0 minor 2: the position settings
-- (Skill Master round 9, L3). `x` and `y` from the parent's CENTER, the arrow's own `lock`, a drag
-- written back through the host's `d.set`, Reset position, and the Position block's rows.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil

local F = dofile("tests/fixture_waypoint_arrow.lua")
local newArrow = F.newArrow

local PATHS = { x = "w.arrowX", y = "w.arrowY", lock = "w.arrowLock" }

local function pointAhead(a) a:SetProvider(function() return 100, 0 end, "Trainer") end

--- An arrow whose writes land in `store` through d.set, as a host's helper would.
local function hosted(d)
  local store, writes = {}, {}
  local desc = { paths = PATHS, set = function(path, v)
    store[path] = v
    writes[#writes + 1] = path .. "=" .. tostring(v)
  end }
  for k, v in pairs(d or {}) do desc[k] = v end
  local a, m, Arrow, rec = newArrow(desc)
  return a, store, writes, m, Arrow, rec
end

--- Give the frame and the parent centers (and scales) the client would answer after a drag.
local function centers(m, f, fx, fy, fScale, pScale)
  rawset(f, "GetCenter", function() return fx, fy end)
  rawset(f, "GetEffectiveScale", function() return fScale or 1 end)
  local parent = m.UIParent
  rawset(parent, "GetCenter", function() return 960, 540 end)
  rawset(parent, "GetEffectiveScale", function() return pScale or 1 end)
end

test("arrow position: x and y place the arrow from the parent's CENTER; the defaults are today's spot", function()
  local a, m, Arrow = newArrow()
  assertEqual(a:Get("x"), 0)
  assertEqual(a:Get("y"), 200)
  assertEqual(a:Get("lock"), false)
  assertEqual(Arrow.DEFAULTS.y, Arrow.DEFAULT_POINT.y, "the default spot is DEFAULT_POINT's")
  a:Configure({ x = -150, y = 75 })
  pointAhead(a)
  local p = { a:Frame():GetPoint() }
  assertEqual(p[1], "CENTER")
  assertEqual(p[2], m.UIParent)
  assertEqual(p[3], "CENTER")
  assertEqual(p[4], -150)
  assertEqual(p[5], 75)
  a:Configure({ y = 9999 })
  assertEqual(a:GetPosition().y, 200, "out of range reads as the default")
end)

test("arrow position: configured x and y win over d.point; SetPosition sets them aside", function()
  local a = newArrow({ point = { point = "TOPLEFT", relPoint = "TOPLEFT", x = 10, y = -20 } })
  pointAhead(a)
  assertEqual(a:GetPosition().point, "TOPLEFT", "no x or y configured: the saved point")
  a:Configure({ x = 5 })
  local p = a:GetPosition()
  assertEqual(p.point .. "," .. p.x .. "," .. p.y, "CENTER,5,200", "an x configured: the settings")
  a:SetPosition({ "LEFT", "LEFT", 3, 4 })
  assertEqual(a:GetPosition().point, "LEFT")
end)

test("arrow position: a drag ends CENTER on the parent's CENTER, written to the host's x and y", function()
  local a, store, writes, m, _, rec = hosted()
  pointAhead(a)
  local f = a:Frame()
  f:__fire("OnDragStart")
  centers(m, f, 1000, 700)
  f:__fire("OnDragStop")
  assertEqual(store["w.arrowX"], 40)
  assertEqual(store["w.arrowY"], 160)
  assertEqual(table.concat(writes, " "), "w.arrowX=40 w.arrowY=160")
  local p = { f:GetPoint() }
  assertEqual(p[1] .. p[3] .. p[4] .. "," .. p[5], "CENTERCENTER40,160", "re-anchored")
  assertEqual(a:Get("x"), 40, "the arrow holds it too")
  assertEqual(rec.moved[1].point, "CENTER", "onMoved still hears the point")
end)

test("arrow position: the offsets are in the frame's own units at another scale", function()
  local a, store, _, m = hosted()
  a:Configure({ scale = 2 })
  pointAhead(a)
  local f = a:Frame()
  f:__fire("OnDragStart")
  centers(m, f, 500, 300, 2, 1)   -- the frame at scale 2: its center in its own (halved) units
  f:__fire("OnDragStop")
  assertEqual(store["w.arrowX"], 20, "500 - 960 / 2")
  assertEqual(store["w.arrowY"], 30, "300 - 540 / 2")
end)

test("arrow position: Lock the arrow holds it still, and canDrag still applies", function()
  local a, store, writes = hosted()
  pointAhead(a)
  a:Configure({ lock = true })
  local f = a:Frame()
  f:__fire("OnDragStart")
  assertFalse(rawget(f, "__moving") == true, "locked")
  f:__fire("OnDragStop")
  assertEqual(#writes, 0)
  a:Configure({ lock = false })
  f:__fire("OnDragStart")
  assertTrue(rawget(f, "__moving"), "unlocked")
  local b = newArrow({ canDrag = function() return false end })
  pointAhead(b)
  b:Frame():__fire("OnDragStart")
  assertFalse(rawget(b:Frame(), "__moving") == true, "the host's canDrag")
  a:SetLocked(true)
  assertTrue(a:IsLocked())
  assertEqual(store["w.arrowLock"], true, "SetLocked writes through the host")
end)

test("arrow position: ResetPosition writes the default spot through the host, then onMoved(nil)", function()
  local a, store, _, _, _, rec = hosted()
  a:Configure({ x = 300, y = -40 })
  pointAhead(a)
  a:ResetPosition()
  assertEqual(store["w.arrowX"], 0)
  assertEqual(store["w.arrowY"], 200)
  local p = { a:Frame():GetPoint() }
  assertEqual(p[4] .. "," .. p[5], "0,200")
  assertEqual(rec.moved[#rec.moved], false, "onMoved(nil)")
end)

test("arrow position: a drag with no centers to read keeps minor 1's point and writes no offsets", function()
  local a, store, _, _, _, rec = hosted()
  pointAhead(a)
  local f = a:Frame()
  f:__fire("OnDragStart")
  f:SetPoint("BOTTOM", nil, "BOTTOM", 4, 5)
  f:__fire("OnDragStop")
  assertEqual(rec.moved[1].point, "BOTTOM")
  assertNil(store["w.arrowX"], "not a CENTER point: no x")
end)

-- ── the rows ─────────────────────────────────────────────────────────────────────────────────

local function byKey(rows)
  local out = {}
  for _, r in ipairs(rows) do out[r.key] = r end
  return out
end

test("arrow position: the rows are X offset, Y offset and Lock the arrow, on a Position subgroup", function()
  local _, Arrow = F.env()
  local rows, hooks = Arrow.SettingsRows({ paths = PATHS, page = "p", group = "g" })
  local keys = {}
  for i, r in ipairs(rows) do keys[i] = r.key end
  assertEqual(table.concat(keys, ","), "x,y,lock")
  local r = byKey(rows)
  assertEqual(r.x.label, "X offset")
  assertEqual(r.y.label, "Y offset")
  assertEqual(r.x.default, 0)
  assertEqual(r.y.default, 200)
  assertEqual(r.x.min, -2000)
  assertEqual(r.y.max, 2000)
  assertEqual(r.x.step, 1)
  assertTrue(r.x.startsLine == true and r.lock.startsLine == true)
  assertEqual(r.lock.default, false)
  assertEqual(r.x.subgroup, "Position")
  assertNil(next(hooks), "no Options instance: no Reset position button")
end)

test("arrow position: with an Options instance the block is O.PositionBlock's, its Reset button hooked", function()
  local O = dofile("tests/fixture_options.lua").new()
  local a = newArrow()
  local after = 0
  local rows, hooks = T.arrow.__methods.SettingsRows(a, { paths = PATHS, options = O, page = "p", group = "g",
    subgroup = "Arrow", onResetPosition = function() after = after + 1 end })
  local keys = {}
  for i, r in ipairs(rows) do keys[i] = r.key end
  assertEqual(table.concat(keys, ","), "x,y,lock")
  assertEqual(byKey(rows).x.tooltip:find("screen's center", 1, true) ~= nil, true, "the arrow's words")
  assertTrue(type(hooks.Arrow) == "function", "keyed by the block's subgroup")
  byKey(rows).x.onChange(12)
  assertEqual(a:Get("x"), 12, "a row's change configures the arrow")
end)
