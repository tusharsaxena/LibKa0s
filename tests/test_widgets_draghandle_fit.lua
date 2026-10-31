-- tests/test_widgets_draghandle_fit.lua — LibKa0s-Widgets-1.0: what a strip's fit is measured at
-- (WidgetsDragHandle minor 10, LibKa0s#68): the measuring host takes the strip's effective scale,
-- the measured text is written fresh each time, and a fitted strip repeats the host's last fit when
-- it shows, so a fit made before a face loaded does not last until the next skin switch.
--
-- The bench is tests/fixture_draghandle.lua's. The strip fitting its title in every skin is
-- arithmetic: Measure() spends the measured label, FIT_SLACK and both reserves, and the label's bound
-- is what is left. So these cases pin what the measure reads, not the widths per face.

local T = _G.LK_TEST
local assertEqual = T.assertEqual
local assertTrue  = T.assertTrue
local mocks       = T.mocks

local W = T.widgets

local Bench    = dofile("tests/fixture_draghandle.lua")
local test     = Bench.test
local baseSpec = Bench.baseSpec
local geomFrame = Bench.geomFrame

--- A measurer on a host of the case's own, measuring 6px a character, doubled once `load` says so.
local function measurer()
  local fs, host, state = geomFrame(), geomFrame(), { factor = 1, writes = {} }
  function fs:SetText(t)
    self.__text = t
    state.writes[#state.writes + 1] = t
    return self
  end
  function fs:GetStringWidth() return #(self.__text or "") * 6 * state.factor end
  function host:SetScale(s) self.__scale = s; return self end
  W.__DragHandleMeasurer = function() return fs, host end
  return state, host
end

--- A handle at effective scale `eff`, under a UIParent at `base`.
local function strip(eff, base, over)
  function mocks.UIParent:GetEffectiveScale() return base end
  local handle = W.DragHandle(geomFrame(), baseSpec(over))
  function handle:GetEffectiveScale() return eff end
  return handle
end

test("DragHandle minor 10: MODULES and the file minor say 10 or later", function()
  assertTrue(W.__dragMinor >= 10)
  assertEqual(W.MODULES.WidgetsDragHandle, W.__dragMinor)
end)

test("DragHandle scale: the measuring host sits at the strip's scale over UIParent's", function()
  local _, host = measurer()
  strip(1.5, 0.75):Measure()
  assertEqual(host.__scale, 2)
end)

test("DragHandle scale: an unreadable scale measures at UIParent's, not at the last strip's", function()
  local _, host = measurer()
  strip(1.5, 0.75):Measure()
  assertEqual(host.__scale, 2)
  local guarded = strip(1.5, 0.75, { number = function(_, fallback) return fallback end })
  guarded:Measure()
  assertEqual(host.__scale, 1, "the host's guard refused the read")
end)

test("DragHandle scale: a measurer with no host, the test seam's shape, still measures", function()
  Bench.stubMeasurer()
  local width = strip(1.5, 0.75):Measure()
  assertEqual(width, 5 * 6 + W.DRAG_HANDLE.FIT_SLACK + W.DRAG_HANDLE.RESERVE * 2)
end)

test("DragHandle measure: the text is cleared first, so a same-string measure is a new one", function()
  local state = measurer()
  strip(1, 1):Measure()
  assertEqual(state.writes[1], "")
  assertEqual(state.writes[2], "Buffs")
end)

test("DragHandle show: a fit made in a face that had not loaded is corrected on show", function()
  local state = measurer()
  local handle = strip(1, 1)
  handle:ApplyWidth(0)
  local early = handle:GetWidth()
  state.factor = 2
  handle:__fire("OnShow")
  assertEqual(handle:GetWidth(), early + 5 * 6, "the title's width doubled")
end)

test("DragHandle show: the fit keeps the host's floor", function()
  measurer()
  local handle = strip(1, 1)
  handle:ApplyWidth(300)
  handle:__fire("OnShow")
  assertEqual(handle:GetWidth(), 300)
end)

test("DragHandle show: a strip the host never fitted, or sized itself, is not sized", function()
  measurer()
  local handle = strip(1, 1)
  handle:__fire("OnShow")
  assertEqual(handle:GetWidth(), 0, "never fitted")
  handle:ApplyWidth(0)
  handle:SetWidth(77)
  handle:__fire("OnShow")
  assertEqual(handle:GetWidth(), 77, "the host's own width stands")
end)

test("DragHandle show: an onRefit host sizes its own strip", function()
  measurer()
  local calls = 0
  local handle = strip(1, 1, { onRefit = function() calls = calls + 1 end })
  handle:ApplyWidth(0)
  local width = handle:GetWidth()
  handle:SetLabel("A much longer title")
  handle:__fire("OnShow")
  assertEqual(handle:GetWidth(), width)
  assertEqual(calls, 0)
end)

test("DragHandle show: nothing is sized in combat", function()
  local state = measurer()
  local handle = strip(1, 1)
  handle:ApplyWidth(0)
  local width = handle:GetWidth()
  state.factor = 2
  local saved = mocks.InCombatLockdown
  mocks.InCombatLockdown = function() return true end
  local ok, err = pcall(handle.__fire, handle, "OnShow")
  mocks.InCombatLockdown = saved
  assertTrue(ok, err)
  assertEqual(handle:GetWidth(), width)
end)
