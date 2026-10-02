-- tests/test_widgets_draghandle_place.lua — LibKa0s-Widgets-1.0: `lib.DragHandle`'s tooltip
-- placement hook, `spec.tooltipPlace` and a descriptor's `place` (WidgetsDragHandle minor 4,
-- AuraMaster#22).
--
-- A suite of its own for `layout-§1`, the exit tests/test_widgets_draghandle.lua itself took at
-- v1.48.0: these cases took that suite from 901 to 1123 lines, into the 1000–1500 band. The bench is
-- the same one, in tests/fixture_draghandle.lua; the tooltip's shape and its two owners are pinned
-- in tests/test_widgets_draghandle.lua, and what is pinned here is the third route: owned by
-- UIParent at ANCHOR_NONE, shown, then placed by the host, with the cursor owner as the fallback.

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

test("draghandle: without tooltipPlace the call sequence is exactly minor 3's, for both owners", function()
  -- The additive promise, pinned as a SEQUENCE rather than as a last owner: one SetOwner, the
  -- lines, one Show, nothing after. red under: a minor 4 that always owned at ANCHOR_NONE, or that
  -- called Show twice, on a host that never asked for placement.
  local names = { [mocks.UIParent] = "UIParent" }
  local cursor = W.DragHandle(mocks.UIParent, baseSpec({ tooltip = placeDescriptor(), tooltipOwner = "cursor" }))
  assertEqual(table.concat(logLines(hoverLog(cursor), names), "\n"), table.concat({
    "SetOwner|UIParent|ANCHOR_CURSOR|nil|nil|nil",
    "SetText|Buffs|1|0.82|0|nil",
    "AddLine|Drag to move. Right-click for settings.|1|1|1|true",
    "AddLine| |nil|nil|nil|nil",
    "AddLine|Unlocked.|0.6|0.6|0.6|true",
    "Show|nil|nil|nil|nil|nil",
  }, "\n"))

  local own = W.DragHandle(mocks.UIParent, baseSpec({ tooltip = placeDescriptor() }))
  names[own] = "strip"
  local seq = logLines(hoverLog(own), names)
  assertEqual(seq[1], "SetOwner|strip|ANCHOR_TOP|nil|nil|nil")
  assertEqual(#seq, 6)
  assertEqual(seq[6], "Show|nil|nil|nil|nil|nil")
end)

test("draghandle: tooltipPlace owns by UIParent at ANCHOR_NONE, draws, shows, then places", function()
  -- AuraMaster's anchor refuses SetOwner on any frame under it, so the frame-owner path is closed
  -- to it and ANCHOR_CURSOR was its only option. The hook lets it own by UIParent and put the
  -- tooltip BESIDE the strip itself. Show comes BEFORE the call, so the host can read the
  -- tooltip's measured width when it decides which side the tooltip fits on.
  local calls = {}
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip = placeDescriptor(),
    tooltipOwner = "cursor",
    tooltipPlace = function(tip, frame)
      calls[#calls + 1] = { tip = tip, frame = frame }
      return true
    end,
  }))
  local names = { [mocks.UIParent] = "UIParent", [h] = "strip" }
  local log = hoverLog(h)
  assertEqual(table.concat(logLines(log, names), "\n"), table.concat({
    "SetOwner|UIParent|ANCHOR_NONE|nil|nil|nil",
    "SetText|Buffs|1|0.82|0|nil",
    "AddLine|Drag to move. Right-click for settings.|1|1|1|true",
    "AddLine| |nil|nil|nil|nil",
    "AddLine|Unlocked.|0.6|0.6|0.6|true",
    "Show|nil|nil|nil|nil|nil",
  }, "\n"), "a placement that answers true is final: no second owner, no second Show")
  assertEqual(#calls, 1, "called once per hover")
  assertEqual(calls[1].tip, mocks.GameTooltip, "handed the tooltip it owns")
  assertEqual(calls[1].frame, h, "and the frame hovered")
end)

test("draghandle: tooltipPlace runs after Show, so the tooltip is measured when it is placed", function()
  local order = {}
  local tip = mocks.GameTooltip
  local savedShow = rawget(tip, "Show")
  rawset(tip, "Show", function() order[#order + 1] = "Show" end)
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip = { title = "Buffs" },
    tooltipPlace = function() order[#order + 1] = "place"; return true end,
  }))
  local ok, err = pcall(function() h:__fire("OnEnter") end)
  rawset(tip, "Show", savedShow)
  assertTrue(ok, tostring(err))
  assertEqual(table.concat(order, ","), "Show,place")
end)

test("draghandle: the mark and the X hand tooltipPlace the frame hovered, not the strip", function()
  local seen = {}
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    onClose = function() end,
    tooltip = { title = "Buffs" },
    tooltipPlace = function(_, frame) seen[#seen + 1] = frame; return true end,
  }))
  hoverLog(h.help)
  hoverLog(h.close)
  assertEqual(seen[1], h.help)
  assertEqual(seen[2], h.close)
end)

test("draghandle: a tooltipPlace that raises falls back to the cursor and redraws the same lines", function()
  -- AuraMaster's strip can read SECRET geometry under an attached anchor, so the host's arithmetic
  -- can raise. red under: an unguarded call (the hover raises and no tooltip shows), or a fallback
  -- that re-owned without redrawing (SetOwner clears the tooltip, so it would show empty).
  local evaluated = 0
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip = {
      title  = "Buffs",
      body   = { function() evaluated = evaluated + 1; return "Live line." end },
      footer = { "Unlocked." },
    },
    tooltipPlace = function() error("secret number") end,
  }))
  local names = { [mocks.UIParent] = "UIParent" }
  assertEqual(table.concat(logLines(hoverLog(h), names), "\n"), table.concat({
    "SetOwner|UIParent|ANCHOR_NONE|nil|nil|nil",
    "SetText|Buffs|1|0.82|0|nil",
    "AddLine|Live line.|1|1|1|true",
    "AddLine| |nil|nil|nil|nil",
    "AddLine|Unlocked.|0.6|0.6|0.6|true",
    "Show|nil|nil|nil|nil|nil",
    "SetOwner|UIParent|ANCHOR_CURSOR|nil|nil|nil",
    "SetText|Buffs|1|0.82|0|nil",
    "AddLine|Live line.|1|1|1|true",
    "AddLine| |nil|nil|nil|nil",
    "AddLine|Unlocked.|0.6|0.6|0.6|true",
    "Show|nil|nil|nil|nil|nil",
  }, "\n"))
  assertEqual(evaluated, 1, "the SAME lines: a function entry is evaluated once per hover, not per draw")
end)

test("draghandle: a tooltipPlace that answers anything but true falls back to the cursor", function()
  -- Only a literal true means "placed". nil is the commonest way a host's function says nothing at
  -- all, and a truthy non-true answer is not a promise the tooltip was anchored.
  for _, answer in ipairs({ false, 1, "yes", {} }) do
    local h = W.DragHandle(mocks.UIParent, baseSpec({
      tooltip = { title = "Buffs" },
      tooltipPlace = function() return answer end,
    }))
    local log = hoverLog(h)
    assertEqual(#log, 6, "own, title, Show, re-own, title, Show for " .. tostring(answer))
    assertEqual(log[4][1], "SetOwner")
    assertEqual(log[4][2], mocks.UIParent)
    assertEqual(log[4][3], "ANCHOR_CURSOR")
    assertEqual(log[5][2], "Buffs")
    assertEqual(log[6][1], "Show")
  end
  local silent = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip = { title = "Buffs" }, tooltipPlace = function() end,
  }))
  assertEqual(hoverLog(silent)[4][3], "ANCHOR_CURSOR", "and a nil answer falls back too")
end)

test("draghandle: a descriptor's own place wins over the spec's, as owner and anchor do", function()
  local used = {}
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip      = { title = "Strip" },
    helpTooltip  = { title = "Mark", place = function() used[#used + 1] = "mark's"; return true end },
    tooltipPlace = function() used[#used + 1] = "spec's"; return true end,
  }))
  hoverLog(h)
  hoverLog(h.help)
  assertEqual(table.concat(used, ","), "spec's,mark's")
end)

test("draghandle: a descriptor may place while the spec does not, and its neighbor is untouched", function()
  local h = W.DragHandle(mocks.UIParent, baseSpec({
    tooltip     = { title = "Strip" },
    helpTooltip = { title = "Mark", place = function() return true end },
  }))
  local strip = hoverLog(h)
  assertEqual(strip[1][2], h, "the strip keeps the frame owner")
  assertEqual(strip[1][3], "ANCHOR_TOP")
  local mark = hoverLog(h.help)
  assertEqual(mark[1][2], mocks.UIParent)
  assertEqual(mark[1][3], "ANCHOR_NONE")
  assertEqual(#mark, 3, "own, title, Show; the placement answered true")
end)

test("draghandle: a tooltipPlace that is not a function is ignored, not called", function()
  -- red under: a truthiness check, which would call a string and fall back on every hover -- a
  -- host that wrote `tooltipPlace = "right"` would lose its frame owner for a cursor owner.
  local h = W.DragHandle(mocks.UIParent, baseSpec({ tooltip = { title = "Buffs" }, tooltipPlace = "right" }))
  local log = hoverLog(h)
  assertEqual(#log, 3)
  assertEqual(log[1][2], h)
  assertEqual(log[1][3], "ANCHOR_TOP")
end)

test("draghandle: DragHandle is at minor 4, the placement hook's minor", function()
  assertEqual(W.MODULES.WidgetsDragHandle, 4)
  assertEqual(W.__dragMinor, 4)
end)
