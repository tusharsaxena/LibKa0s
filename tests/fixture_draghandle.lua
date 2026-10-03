-- tests/fixture_draghandle.lua — the bench the two DragHandle suites share:
-- tests/test_widgets_draghandle.lua (the strip, its marks, its width, its drag and its tooltip's
-- shape) and tests/test_widgets_draghandle_place.lua (minor 4's tooltip placement hook).
--
-- Moved out of tests/test_widgets_draghandle.lua when minor 4's cases took that suite into
-- `layout-§1`'s 1000–1500 band (901 -> 1123), and the cases went to a suite of their own rather than
-- staying there. One copy rather than two, for the reason tests/fixture_widgets.lua gives: a bench
-- that drifted between the suites would make one suite's case prove something the other's does
-- not. Why the bench models geometry at all is in tests/test_widgets_draghandle.lua's header.
--
-- Loaded as `dofile("tests/fixture_draghandle.lua")`, once per suite file, so each suite has its
-- own stand-in UIParent.

local T = _G.LK_TEST
local rawTest = T.test
local mocks   = T.mocks
local W       = T.widgets

--- A frame stub modeling the geometry, the scripts and the REGISTRATIONS this widget does work on.
--- The registrations are real rather than swallowed by the catch-all because "a host that passes no
--- right-click gets none" is a claim about RegisterForClicks having never been called, and against
--- the catch-all that claim is unfalsifiable.
local function geomFrame()
  local f = { __shown = true, __w = 0, __h = 0, __scripts = {}, __points = {}, __clicks = {}, __drags = {} }
  function f:SetSize(w, h) self.__w, self.__h = w, h; return self end
  function f:SetWidth(w) self.__w = w; return self end
  function f:SetHeight(h) self.__h = h; return self end
  function f:GetWidth() return self.__w end
  function f:GetHeight() return self.__h end
  function f:Show() self.__shown = true; return self end
  function f:Hide() self.__shown = false; return self end
  function f:SetShown(v) self.__shown = not not v; return self end
  function f:IsShown() return self.__shown end
  function f:SetScript(k, fn) self.__scripts[k] = fn; return self end
  function f:GetScript(k) return self.__scripts[k] end
  function f:__fire(k, ...) local fn = self.__scripts[k]; if fn then return fn(self, ...) end end
  function f:RegisterForClicks(...) self.__clicks = { ... }; return self end
  function f:RegisterForDrag(...) self.__drags = { ... }; return self end
  function f:SetPoint(point, rel, relPoint, x, y)
    self.__points[#self.__points + 1] =
      { point = point, relativeTo = rel, relativePoint = relPoint, x = x, y = y }
    return self
  end
  function f:ClearAllPoints() self.__points = {}; return self end
  function f:GetPoint(i)
    local pt = self.__points[i or 1]
    if not pt then return nil end
    return pt.point, pt.relativeTo, pt.relativePoint, pt.x, pt.y
  end
  function f:SetTexture(p) self.__texture = p; return self end
  function f:SetColorTexture(r, g, b, a) self.__colorTexture = { r, g, b, a }; return self end
  function f:SetText(t) self.__text = t; return self end
  function f:GetText() return self.__text end
  function f:SetTextColor(r, g, b) self.__textColor = { r, g, b }; return self end
  -- The mark's TINT and the label's BOUNDS, recorded rather than swallowed by the catch-all: both
  -- claims here are claims about the arguments a setter was handed, and against the catch-all
  -- (which answers every capitalized key with a function returning the frame) they are
  -- unfalsifiable.
  function f:SetVertexColor(r, g, b, a) self.__vertex = { r, g, b, a }; return self end
  function f:SetJustifyH(j) self.__justifyH = j; return self end
  function f:SetWordWrap(on) self.__wordWrap = on; return self end
  function f:SetMaxLines(n) self.__maxLines = n; return self end
  -- THE FACE a FontString was created with, recorded rather than answered from a font table: the
  -- claim under test is that the label is DRAWN in the same face it is MEASURED in, and that is a
  -- claim about the argument CreateFontString was handed.
  function f:GetStringWidth() return #(self.__text or "") * 6 end
  function f:CreateTexture() return geomFrame() end
  function f:CreateFontString(_, _, face) local fs = geomFrame(); fs.__face = face; return fs end
  -- StartMoving / StopMovingOrSizing, recorded: the whole point of `moveFrame` is that the drag
  -- reaches THAT frame and not the strip, and the catch-all would answer both with the frame.
  function f:StartMoving() self.__moving = true; return self end
  function f:StopMovingOrSizing() self.__moving = false; return self end
  setmetatable(f, { __index = function(_, k)
    if type(k) == "string" and k:match("^%u") then return function() return f end end
    return nil
  end })
  return f
end

local geomCreateFrame = function(frameType, name, parent)
  local f = geomFrame()
  f.__frameType, f.__name, f.__parent = frameType, name, parent
  return f
end
local geomUIParent = geomFrame()

--- Register a case whose body runs with the geometry factory installed, and with the measuring
--- seam restored afterwards -- a stub left on `lib.__DragHandleMeasurer` is a stub the next suite
--- inherits, and it is a lib-level member rather than a mock.
local realMeasurer = W.__DragHandleMeasurer
local function test(name, fn)
  return rawTest(name, function()
    local savedCF, savedUI = mocks.CreateFrame, mocks.UIParent
    mocks.CreateFrame, mocks.UIParent = geomCreateFrame, geomUIParent
    local ok, err = pcall(fn)
    mocks.CreateFrame, mocks.UIParent = savedCF, savedUI
    W.__DragHandleMeasurer = realMeasurer
    if not ok then error(err, 0) end
  end)
end

--- Measure at 6px per character, whatever face is asked for.
local function stubMeasurer()
  local fs = geomFrame()
  W.__DragHandleMeasurer = function() return fs end
  return fs
end

--- A minimal well-formed spec: the two required fields and nothing else.
local function baseSpec(over)
  local spec = { label = "Buffs", moveFrame = geomFrame() }
  for k, v in pairs(over or {}) do spec[k] = v end
  return spec
end

return {
  geomFrame    = geomFrame,
  geomUIParent = geomUIParent,
  test         = test,
  stubMeasurer = stubMeasurer,
  baseSpec     = baseSpec,
}
