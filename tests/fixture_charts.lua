-- tests/fixture_charts.lua — the frame recorder the Charts suites share (tests/test_charts.lua,
-- tests/test_charts_draw.lua and tests/test_charts_host.lua), and their environment.
--
-- The kit's frame answers `CreateTexture` and `CreateFontString` with the frame itself (its
-- header's known divergence), and any capitalized method with the frame, so a bar's label, its value
-- and its track would be one table, and `GetStringWidth` could not be compared. These frames hand
-- out DISTINCT regions. A method nothing here names records its last arguments in `__set`, so a case
-- reads what the renderer told a region, and regions and frames answer the getters a case or the
-- skin engine needs.

local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local F = {}

local KNOWN = {}

function KNOWN:GetObjectType() return self.__kind end
function KNOWN:ClearAllPoints() self.__points = {} end
function KNOWN:SetPoint(...) self.__points[#self.__points + 1] = { ... } end
function KNOWN:SetSize(w, h) self.__w, self.__h = w, h end
function KNOWN:SetWidth(w) self.__w = w end
function KNOWN:SetHeight(h) self.__h = h end
function KNOWN:Show() self.__shown = true end
function KNOWN:Hide() self.__shown = false end
function KNOWN:IsShown() return self.__shown end
function KNOWN:SetText(s) self.__text = s end
function KNOWN:GetText() return self.__text end
function KNOWN:SetTextColor(...) self.__color = { ... } end
function KNOWN:SetColorTexture(...) self.__color = { ... } end
function KNOWN:SetVertexColor(...) self.__vertex = { ... } end
function KNOWN:SetTexture(path) self.__texture = path end
function KNOWN:SetScript(name, fn) self.__scripts[name] = fn end
function KNOWN:GetScript(name) return self.__scripts[name] end
function KNOWN:GetStringWidth() return self.__stringWidth or #tostring(self.__text or "") * 6 end
function KNOWN:GetFont() return "Fonts\\X.ttf", self.__fontSize or 24, "" end
function KNOWN:SetFont(_, size) self.__fontSize = size end
function KNOWN:SetFontObject(obj)
  self.__fontObject = obj
  self.__fontSize = nil
end
function KNOWN:GetFontObject() return self.__fontObject end
function KNOWN:GetFrameLevel() return 1 end

local region

function KNOWN:CreateTexture()
  return region("Texture", self)
end
function KNOWN:CreateFontString(_, _, template)
  local fs = region("FontString", self)
  fs.__fontObject = template
  return fs
end

region = function(kind, parent)
  local o = { __kind = kind, __parent = parent, __points = {}, __scripts = {}, __set = {},
              __shown = true }
  return setmetatable(o, { __index = function(t, k)
    if KNOWN[k] then return KNOWN[k] end
    if type(k) == "string" and k:match("^%u") then
      local fn = function(self, ...) self.__set[k] = { ... } end
      rawset(t, k, fn)
      return fn
    end
    return nil
  end })
end

--- A fresh environment with the Charts major. opts.full loads the whole payload (for the skin cases,
--- which need the real engine); opts.noPool leaves LibKa0s-Pool-1.0 out; opts.noCharts stops short
--- of the major. CreateFrame counts every frame it builds in `m.__frames`.
function F.env(opts)
  opts = opts or {}
  local m = buildMocks()
  if opts.full then
    Loader.loadAll(Loader.xmlFiles("LibKa0s/LibKa0s.xml"), nil, m)
  else
    Loader.load("LibKa0s/Core.lua", nil, m)
    if not opts.noPool then Loader.load("LibKa0s/Pool.lua", nil, m) end
    Loader.load("LibKa0s/Charts.lua", nil, m)
    Loader.load("LibKa0s/ChartsRender.lua", nil, m)
  end
  m.__frames = {}
  m.CreateFrame = function(kind, _, parent, template)
    local f = region(kind or "Frame", parent)
    f.__template = template
    m.__frames[#m.__frames + 1] = f
    return f
  end
  m.GameTooltip = region("GameTooltip")
  m.GameTooltip.__lines = {}
  m.GameTooltip.SetOwner = function(self, owner, anchor) self.__owner, self.__anchor = owner, anchor end
  m.GameTooltip.AddLine = function(self, s) self.__lines[#self.__lines + 1] = s end
  return m, m.LibStub("LibKa0s-Charts-1.0", true)
end

--- A frame to draw into.
function F.content(m) return m.CreateFrame("Frame") end

--- An array of what `pool` holds active.
function F.active(pool) return pool.active end

--- A point's x and y out of `obj`'s last SetPoint: `{ point, ..., x, y }`.
function F.xy(obj)
  local p = obj.__points[#obj.__points]
  return p[#p - 1], p[#p]
end

return F
