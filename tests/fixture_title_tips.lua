-- tests/fixture_title_tips.lua — the one acceptance check every library window's title bar runs
-- (SR-L2 of Ka0sAddonsCommonTasks docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, smoke round 1, ruling 3):
-- every title-bar control shows a non-empty tooltip when the pointer enters it and hides it when the
-- pointer leaves. Each window's suite builds the window on its own bench and hands its controls here,
-- so no suite builds another's window (the leak gate counts benches).
--
-- The game tooltip is recorded, not faked whole: SetOwner, SetText and AddLine, Show and Hide,
-- IsOwned and IsShown, the two point calls, each rawset on the kit's GameTooltip and put back after.
-- LibKa0s-Tooltip-1.0's PlaceAttached answers true and counts, so where a tooltip lands is not this
-- check's business (tests/test_tooltip_sites.lua has that).
--
-- Loaded as `dofile("tests/fixture_title_tips.lua")`; answers { record, check }.

local T = _G.LK_TEST
local assertTrue = T.assertTrue
local mocks = T.mocks

local M = {}

local KEYS = { "SetOwner", "GetOwner", "IsOwned", "SetText", "AddLine", "AddDoubleLine", "Show", "Hide",
               "IsShown", "ClearAllPoints", "SetPoint" }

--- Run `fn(rec)` with the game tooltip recorded in `rec`: `owner`, `anchor`, `text` (the first
--- line), `color` (its r, g, b), `shown`, and `placed` (PlaceAttached's calls). Everything is put back after.
function M.record(fn, tip)
  -- `tip`: the suite's own environment's GameTooltip, where it built a fresh one (else the kit's).
  tip = tip or mocks.GameTooltip
  local saved = {}
  for _, k in ipairs(KEYS) do saved[k] = rawget(tip, k) end
  local rec = { shown = false, placed = 0 }
  rawset(tip, "SetOwner", function(_, owner, anchor)
    rec.owner, rec.anchor, rec.text, rec.color = owner, anchor, nil, nil
  end)
  rawset(tip, "GetOwner", function() return rec.owner end)
  rawset(tip, "IsOwned", function(_, f) return rec.owner == f end)
  rawset(tip, "SetText", function(_, text, r, g, b) rec.text, rec.color = text, { r, g, b } end)
  rawset(tip, "AddLine", function(_, text, r, g, b)
    if rec.text == nil then rec.text, rec.color = text, { r, g, b } end
  end)
  rawset(tip, "AddDoubleLine", function(_, text) if rec.text == nil then rec.text = text end end)
  rawset(tip, "Show", function() rec.shown = true end)
  rawset(tip, "Hide", function() rec.shown = false end)
  rawset(tip, "IsShown", function() return rec.shown end)
  rawset(tip, "ClearAllPoints", function() end)
  rawset(tip, "SetPoint", function() end)
  local Tip = T.tooltip
  local real = Tip and Tip.PlaceAttached
  if Tip then Tip.PlaceAttached = function() rec.placed = rec.placed + 1; return true end end
  local ok, err = pcall(fn, rec)
  if Tip then Tip.PlaceAttached = real end
  for _, k in ipairs(KEYS) do rawset(tip, k, saved[k]) end
  if not ok then error(err, 0) end
end

--- Assert that every control in `controls` ({ { name, frame }, ... }) shows a non-empty tooltip on
--- OnEnter and hides it on OnLeave. `label` names the window in each message. Answers what each
--- control said, by name, for a case that pins a string. `tip` as in M.record.
function M.check(controls, label, tip)
  local said = {}
  M.record(function(rec)
    assertTrue(#controls > 0, label .. ": the window lists its title-bar controls")
    for _, c in ipairs(controls) do
      local name, f = c[1], c[2]
      assertTrue(type(f) == "table" and type(f.__fire) == "function", label .. ": " .. name .. " is built")
      rec.text, rec.shown = nil, false
      f:__fire("OnEnter")
      assertTrue(type(rec.text) == "string" and rec.text ~= "",
        label .. ": " .. name .. " shows a tooltip on enter, got " .. tostring(rec.text))
      assertTrue(rec.shown, label .. ": " .. name .. "'s tooltip is shown")
      said[name] = rec.text
      f:__fire("OnLeave")
      assertTrue(not rec.shown, label .. ": " .. name .. " hides its tooltip on leave")
    end
  end, tip)
  return said
end

return M
