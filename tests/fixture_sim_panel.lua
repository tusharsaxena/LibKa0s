-- tests/fixture_sim_panel.lua — the frame recorder the two Sim panel suites share
-- (tests/test_sim_panel.lua and tests/test_sim_panel_render.lua), and their environment.
--
-- The kit's frame answers `CreateTexture` and `CreateFontString` with the frame itself (its
-- header's known divergence), so a row's label, its dot and its command would be one table and a
-- color painted on one would read back from all three. `recording` swaps CreateFrame for one whose
-- frames hand out DISTINCT regions that record their color, text, texture, size, points and shown
-- state, and whose own SetSize / SetWidth / SetHeight / SetPoint / GetPoint are recorded too. The
-- resize surface (`SetResizeBounds` / `GetResizeBounds`) is the kit's own, from
-- testkit/mock_resize.lua.

local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local F = {}

F.MAJOR = "LibKa0s-Sim-1.0"
F.HOST_CHECK = "Interface\\AddOns\\Host\\media\\icons\\confirm"

--- A fresh environment: Core, Widgets (unless opts.noWidgets), Sim, SimTimeline and SimPanel.
--- opts.coreMinor overrides Core's MINOR before SimPanel.lua loads (the attach floor's cases).
function F.env(opts)
  opts = opts or {}
  local m = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, m)
  if not opts.noWidgets then Loader.load("LibKa0s/Widgets.lua", nil, m) end
  Loader.load("LibKa0s/Sim.lua", nil, m)
  Loader.load("LibKa0s/SimTimeline.lua", nil, m)
  local core = m.LibStub("LibKa0s-Core-1.0")
  local saved = core.MINOR
  if opts.coreMinor then core.MINOR = opts.coreMinor end
  Loader.load("LibKa0s/SimPanel.lua", nil, m)
  core.MINOR = saved
  return m, m.LibStub(F.MAJOR)
end

local function recordPoints(f)
  f.__pts = {}
  rawset(f, "SetPoint", function(self, p, rel, relPoint, x, y)
    -- The short form, SetPoint(point, x, y), carries the offsets in the second and third places.
    if type(rel) == "number" then rel, relPoint, x, y = nil, nil, rel, relPoint end
    self.__pts[#self.__pts + 1] = { point = p, rel = rel, relPoint = relPoint, x = x, y = y }
    return self
  end)
  rawset(f, "ClearAllPoints", function(self) self.__pts = {}; return self end)
  rawset(f, "GetPoint", function(self, i)
    local pt = self.__pts[i or 1]
    if not pt then return nil end
    return pt.point, pt.rel, pt.relPoint, pt.x, pt.y
  end)
end

local function recordSize(f)
  rawset(f, "SetSize", function(self, w, h) self:__setGeom(w, h); return self end)
  rawset(f, "SetWidth", function(self, w) self:__setGeom(w, self.__geomH or 0); return self end)
  rawset(f, "SetHeight", function(self, h) self:__setGeom(self.__geomW or 0, h); return self end)
end

--- One distinct region (texture or font string), recording what the panel paints on it.
local function region(parent, kind, layer, template)
  local r = { __shown = true, __kind = kind, __layer = layer, __template = template, __parent = parent }
  function r:Show() self.__shown = true; return self end
  function r:Hide() self.__shown = false; return self end
  function r:SetShown(v) self.__shown = not not v; return self end
  function r:IsShown() return self.__shown end
  function r:SetSize(w, h) self.__w, self.__h = w, h; return self end
  function r:SetPoint(p, rel, relPoint, x, y)
    self.__pts = self.__pts or {}
    self.__pts[#self.__pts + 1] = { point = p, rel = rel, relPoint = relPoint, x = x, y = y }
    return self
  end
  function r:SetText(t) self.__text = t; return self end
  function r:GetText() return self.__text end
  function r:SetTextColor(cr, cg, cb, ca) self.__textColor = { cr, cg, cb, ca }; return self end
  function r:SetColorTexture(cr, cg, cb, ca) self.__colorTexture = { cr, cg, cb, ca }; return self end
  function r:SetVertexColor(cr, cg, cb, ca) self.__vertexColor = { cr, cg, cb, ca }; return self end
  function r:SetTexture(p) self.__texture = p; return self end
  function r:GetTexture() return self.__texture end
  function r:SetJustifyH(v) self.__justifyH = v; return self end
  function r:SetAllPoints() return self end
  function r:SetFont() return self end
  return r
end

local function record(f)
  recordPoints(f)
  recordSize(f)
  rawset(f, "SetMotionScriptsWhileDisabled", function(self, v) self.__motionWhileDisabled = v; return self end)
  rawset(f, "CreateTexture", function(self, _, layer) return region(self, "Texture", layer) end)
  rawset(f, "CreateFontString", function(self, _, layer, template)
    return region(self, "FontString", layer, template)
  end)
  return f
end

F.record = record

--- Run `fn()` with every frame `m.CreateFrame` builds carrying the recorders above. A named frame
--- is also kept in `m.__named[name]` (the kit's CreateFrame sets no global).
function F.recording(m, fn)
  local saved = m.CreateFrame
  m.__named = m.__named or {}
  m.CreateFrame = function(frameType, name, ...)
    local f = record(saved(frameType, name, ...))
    if name then m.__named[name] = f end
    return f
  end
  local ok, err = pcall(fn)
  m.CreateFrame = saved
  if not ok then error(err, 0) end
end

--- Hover `b` as the client does: a disabled Button runs no OnEnter or OnLeave unless
--- SetMotionScriptsWhileDisabled(true) was called on it. The kit's frame fires them regardless,
--- which is how disabled rows that drew no tooltip in game passed here. `script` defaults to OnEnter.
function F.hover(b, script)
  if not b:IsEnabled() and b.__motionWhileDisabled ~= true then return end
  return b:__fire(script or "OnEnter")
end

--- `got` is a color table whose first three components equal `want`'s.
function F.sameColor(T, got, want, msg)
  T.assertTrue(got ~= nil, msg .. ": no color painted")
  for i = 1, 3 do T.assertEqual(got[i], want[i], msg .. " [" .. i .. "]") end
end

return F
