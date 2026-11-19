-- tests/test_widgets_draghandle_place.lua — LibKa0s-Widgets-1.0: `lib.DragHandle`'s tooltip
-- placement hook, `spec.tooltipPlace` and a descriptor's `place` (WidgetsDragHandle minor 4,
-- AuraMaster#22), RETIRED at WidgetsDragHandleTip minor 2 (AF-LK-02 of Ka0sAddonsCommonTasks
-- docs/2026-11-19-ADOPTION_FEEDBACK: the owner's image 11 showed Aura Master's strip tooltip beside
-- the strip, and the ruling is "above the strip everywhere"). Both keys are still accepted, so an
-- un-updated host does not error, and neither is called: what is pinned here is that a hook, of
-- any shape and any answer, changes no call the hover makes. Where the tooltip lands is pinned in
-- tests/test_tooltip_sites.lua.
--
-- A suite of its own for `layout-§1`, the exit tests/test_widgets_draghandle.lua itself took at
-- v1.48.0: these cases took that suite from 901 to 1123 lines, into the 1000–1500 band. The bench is
-- the same one, in tests/fixture_draghandle.lua; the tooltip's shape and its two owners are pinned
-- in tests/test_widgets_draghandle.lua, and what is pinned here is the third route: owned by
-- UIParent at ANCHOR_NONE, shown, then placed by the host. From minor 14 (LK-92B, LibKa0s#92) every
-- tooltip takes that owner and the fallback is the library's attached placement above the strip, never
-- the cursor; where it lands is pinned in tests/test_tooltip_sites.lua, and this suite pins the calls.

local T = _G.LK_TEST
local assertEqual = T.assertEqual
local assertTrue  = T.assertTrue
local mocks       = T.mocks

local W = T.widgets

local Bench    = dofile("tests/fixture_draghandle.lua")
local test     = Bench.test
local baseSpec = Bench.baseSpec


--- Hover `frame` with every GameTooltip call recorded IN ORDER, as one log: the claims below are
--- about sequence (own, draw, Show, then place; and on a refusal, re-own, redraw, Show again), and
--- tests/test_widgets_draghandle.lua's `hover` keeps the last owner only.
local function hoverLog(frame)
  local tip = mocks.GameTooltip
  local log = {}
  local saved = {}
  local function record(key, fn)
    saved[key] = rawget(tip, key)
    rawset(tip, key, fn)
  end
  record("SetOwner", function(_, owner, anchor) log[#log + 1] = { "SetOwner", owner, anchor } end)
  record("SetText", function(_, text, r, g, b) log[#log + 1] = { "SetText", text, r, g, b } end)
  record("AddLine", function(_, text, r, g, b, wrap) log[#log + 1] = { "AddLine", text, r, g, b, wrap } end)
  record("Show", function() log[#log + 1] = { "Show" } end)
  local ok, err = pcall(function() frame:__fire("OnEnter") end)
  for _, key in ipairs({ "SetOwner", "SetText", "AddLine", "Show" }) do rawset(tip, key, saved[key]) end
  assertTrue(ok, tostring(err))
  return log
end

--- One log entry as a comparable string, owners named rather than printed as table addresses.
local function logLine(e, names)
  local parts = {}
  for i = 1, 6 do
    local v = e[i]
    if type(v) == "table" then v = names[v] or "<frame>" end
    parts[#parts + 1] = tostring(v)
  end
  return table.concat(parts, "|")
end

local function logLines(log, names)
  local out = {}
  for i, e in ipairs(log) do out[i] = logLine(e, names) end
  return out
end

local function placeDescriptor()
  return {
    title  = "Buffs",
    body   = { "Drag to move. Right-click for settings." },
    footer = { "Unlocked." },
  }
end

test("draghandle: without tooltipPlace the calls are own by UIParent, draw, one Show, whatever the owner field", function()
  -- Pinned as a SEQUENCE rather than as a last owner: one SetOwner, the lines, one Show, nothing
  -- after (the placement that follows is points, not owner calls). Minor 14 retired the cursor and
  -- frame owners. red under: ANCHOR_CURSOR (#119), or Show called twice.
  local names = { [mocks.UIParent] = "UIParent" }
  local want = table.concat({
    "SetOwner|UIParent|ANCHOR_NONE|nil|nil|nil",
    "SetText|Buffs|1|0.82|0|nil",
    "AddLine|Drag to move. Right-click for settings.|1|1|1|true",
    "AddLine| |nil|nil|nil|nil",
    "AddLine|Unlocked.|0.6|0.6|0.6|true",
    "Show|nil|nil|nil|nil|nil",
  }, "\n")
  local cursor = W.DragHandle(mocks.UIParent, baseSpec({ tooltip = placeDescriptor(), tooltipOwner = "cursor" }))
  assertEqual(table.concat(logLines(hoverLog(cursor), names), "\n"), want)
  local own = W.DragHandle(mocks.UIParent, baseSpec({ tooltip = placeDescriptor() }))
  names[own] = "strip"
  assertEqual(table.concat(logLines(hoverLog(own), names), "\n"), want, "the frame owner is retired too")
end)

test("draghandle: tooltipPlace is accepted and never called, so the hover is the hook-less one", function()
  -- red under: WidgetsDragHandleTip minor 1, which called the hook after Show and kept its point on
  -- a literal true (Aura Master's tooltip beside the strip, the owner's image 11).
  local calls = 0
  local names = { [mocks.UIParent] = "UIParent" }
  local plain = W.DragHandle(mocks.UIParent, baseSpec({ tooltip = placeDescriptor() }))
  local want = table.concat(logLines(hoverLog(plain), names), "\n")
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    onClose = function() end,
    tooltip = placeDescriptor(),
    tooltipPlace = function() calls = calls + 1; return true end,
  }))
  assertEqual(table.concat(logLines(hoverLog(h), names), "\n"), want, "the strip's hover, call for call")
  hoverLog(h.help)
  hoverLog(h.close)
  assertEqual(calls, 0, "never called, on the strip or on either mark")
end)

test("draghandle: a retired hook of any shape or answer changes nothing and raises nothing", function()
  -- Kept accepted for compatibility: a host not yet updated passes one of these and must not error.
  local function raises() error("secret number") end
  local function answersFalse() return false end
  local function answersNil() return nil end
  local function answersOne() return 1 end
  local hooks = { raises, answersFalse, answersNil, answersOne, "right", {} }
  for _, hook in ipairs(hooks) do
    local h = W.DragHandle(mocks.UIParent, baseSpec({ tooltip = { title = "Buffs" }, tooltipPlace = hook }))
    local log = hoverLog(h)
    assertEqual(#log, 3, "own, title, Show for " .. type(hook))
    assertEqual(log[1][2], mocks.UIParent)
    assertEqual(log[1][3], "ANCHOR_NONE")
    assertEqual(log[3][1], "Show")
  end
end)

test("draghandle: a descriptor's own place is retired with the spec's", function()
  local used = 0
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip     = { title = "Strip", place = function() used = used + 1; return true end },
    helpTooltip = { title = "Mark", place = function() used = used + 1; return true end },
  }))
  assertEqual(#hoverLog(h), 3)
  assertEqual(#hoverLog(h.help), 3)
  assertEqual(used, 0, "neither descriptor's place is called")
end)

test("draghandle: WidgetsDragHandleTip is at minor 2 or later, the placement hook's retirement", function()
  assertTrue(W.MODULES.WidgetsDragHandleTip >= 2)
  assertTrue(W.__dragTipMinor >= 2)
end)
