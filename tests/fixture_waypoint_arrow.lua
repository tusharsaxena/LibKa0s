-- tests/fixture_waypoint_arrow.lua — the bench the LibKa0s-WaypointArrow-1.0 suites share.
--
-- Every case runs on a fresh environment with Core and the arrow loaded and the kit's paint recorder
-- installed (so the body, the overlay and the shadow are distinct, recording Textures). CreateFrame is
-- wrapped so each frame records its anchor, its scale and a drag, and answers GetPoint from the
-- record. The client's position reads are fakes the case drives: `m.__player = { instance, x, y }`
-- (world yards, x north and y west; nil for unknown), `m.__facing` (radians, nil for none),
-- `m.__maps[mapID] = { instance, x0, y0, scale }` (a map point (u, v) lies at world x0 + u * scale,
-- y0 + v * scale). `F.tick(m, arrow)` drives one measure past the throttle.

local Loader = (_G.LK_TEST and _G.LK_TEST.loader) or dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")
local installPaint = dofile("tests/_kit/mock_paint.lua")

local F = {}
F.MAJOR = "LibKa0s-WaypointArrow-1.0"
F.MEDIA = "Interface\\AddOns\\TestAddon\\libs\\LibKa0s\\media\\waypoint\\"

local function instrument(f)
  rawset(f, "SetMovable", function(self, v) rawset(self, "__movable", v) end)
  rawset(f, "EnableMouse", function(self, v) rawset(self, "__mouse", v) end)
  rawset(f, "SetFrameStrata", function(self, s) rawset(self, "__strata", s) end)
  rawset(f, "SetScale", function(self, s) rawset(self, "__scale", s) end)
  rawset(f, "GetScale", function(self) return rawget(self, "__scale") or 1 end)
  rawset(f, "SetSize", function(self, w, h) rawset(self, "__size", { w, h }) end)
  rawset(f, "GetSize", function(self)
    local s = rawget(self, "__size") or { 0, 0 }
    return s[1], s[2]
  end)
  rawset(f, "ClearAllPoints", function(self) rawset(self, "__point", nil) end)
  rawset(f, "SetPoint", function(self, ...) rawset(self, "__point", { ... }) end)
  rawset(f, "GetPoint", function(self)
    local p = rawget(self, "__point")
    if not p then return nil end
    return p[1], p[2], p[3], p[4], p[5]
  end)
  rawset(f, "SetHitRectInsets", function(self, ...) rawset(self, "__insets", { ... }) end)
  rawset(f, "StartMoving", function(self) rawset(self, "__moving", true) end)
  rawset(f, "StopMovingOrSizing", function(self) rawset(self, "__moving", false) end)
  return f
end

local function installWorld(m)
  m.__maps = {}
  m.CreateVector2D = function(x, y) return { x = x, y = y, GetXY = function(v) return v.x, v.y end } end
  m.GetPlayerFacing = function() return m.__facing end
  m.C_Map = {
    GetBestMapForUnit = function() return m.__player and 1 or nil end,
    GetPlayerMapPosition = function()
      local p = m.__player
      if not p then return nil end
      return m.CreateVector2D(p[2], p[3])
    end,
    GetWorldPosFromMapPos = function(mapID, v)
      if mapID == 1 then   -- the player's own map: the identity, on their instance
        local p = m.__player
        return p and p[1], m.CreateVector2D(v.x, v.y)
      end
      local map = m.__maps[mapID]
      if not map then return nil end
      return map[1], m.CreateVector2D(map[2] + v.x * map[4], map[3] + v.y * map[4])
    end,
  }
end

--- A fresh environment: Core and the arrow, every frame instrumented, the world faked.
--- `before(m)` runs before the files load.
function F.env(before)
  local m = buildMocks()
  installPaint(m)
  local create = m.CreateFrame
  m.__made = {}
  m.CreateFrame = function(...)
    local f = instrument(create(...))
    m.__made[#m.__made + 1] = f
    return f
  end
  m.__errors = {}
  m.geterrorhandler = function() return function(e) m.__errors[#m.__errors + 1] = e end end
  installWorld(m)
  if before then before(m) end
  Loader.load("LibKa0s/Core.lua", nil, m)
  Loader.load("LibKa0s/WaypointArrow.lua", nil, m)
  Loader.load("LibKa0s/WaypointArrowSettings.lua", nil, m)
  return m, m.LibStub(F.MAJOR, true)
end

--- An arrow on a fresh environment; `d` overrides the descriptor's fields. Answers the arrow, the
--- mocks, the major and the record of every callback.
function F.newArrow(d, before)
  local m, Arrow = F.env(before)
  local rec = { moved = {}, arrived = {}, clicks = {} }
  local desc = { addon = "TestAddon", name = "TestArrow",
    onMoved = function(p) rec.moved[#rec.moved + 1] = p or false end,
    onArrive = function(t) rec.arrived[#rec.arrived + 1] = t end,
    onClick = function(_, button) rec.clicks[#rec.clicks + 1] = button end }
  for k, v in pairs(d or {}) do desc[k] = v end
  return Arrow:New(desc), m, Arrow, rec
end

--- The arrow's regions by role: the frame, the art box, the shadow, body and overlay textures, and
--- the distance text.
function F.parts(arrow)
  local f = arrow:Frame()
  local box = f:GetChildren()
  local shadow, body, overlay
  for _, r in ipairs({ box:GetRegions() }) do
    local _, sub = r:GetDrawLayer()
    if sub == 0 then shadow = r elseif sub == 1 then body = r elseif sub == 2 then overlay = r end
  end
  local text
  for _, r in ipairs({ f:GetRegions() }) do
    if r.GetObjectType and r:GetObjectType() == "FontString" then text = r end
  end
  return f, box, shadow, body, overlay, text
end

--- One measure, past the throttle, through the frame's own OnUpdate.
function F.tick(_, arrow)
  local f = arrow:Frame()
  local fn = f:GetScript("OnUpdate")
  if fn then fn(f, 1) end
end

return F
