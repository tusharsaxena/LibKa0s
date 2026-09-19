-- tests/test_options_idlist_remove.lua — LibKa0s-Options-1.0's O.IdList `removeStyle = "icon"`
-- (OptionsWidgets minor 21): a small X at the LEFT of every entry in place of the right-hand Remove
-- button or checkbox, and a list drawn exactly as before when the key is absent.
--
-- Its own suite rather than more cases in tests/test_options_widgets.lua, which is over layout-§1's
-- cap and tracked by issue #33 (CLAUDE.md, "Files over the 1500-line cap"): new cases on a seam of
-- their own go to a file of their own, as v1.32.0's bulk cases did.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertNil
local Fixture = dofile("tests/fixture_options.lua")
local mocks = T.mocks

local panelSeq = 0

--- One IdList on a throwaway page, its spells known to the kit's id records; every callback logged.
local function listBench(entries, spec)
  local O = Fixture.new()
  panelSeq = panelSeq + 1
  local ctx = O.CreatePanel("IdListRemoveBench" .. panelSeq, "Bench " .. panelSeq, {})
  mocks.clearIdRecords()
  mocks.addIdRecord("spell", 21562, "Power Word: Fortitude", 135987)
  mocks.addIdRecord("spell", 774, "Rejuvenation", 136081)
  local log = { removed = {}, rebuilt = 0 }
  ctx.rebuild = function() log.rebuilt = log.rebuilt + 1 end
  spec = spec or {}
  spec.kind = "spell"
  spec.entries = function() return entries end
  spec.onAdd = function() end
  spec.onRemove = function(id)
    local n = #log.removed
    log.removed[n + 1] = id
  end
  return O, ctx, O.IdList(ctx, spec), log
end

test("IdList removeStyle icon: an X leads every line, then the name; no Remove button and no checkbox", function()
  local _, _, lines = listBench({ { id = 21562 }, { id = 774, toggle = true, on = true } }, { removeStyle = "icon" })
  for i, line in ipairs(lines) do
    local x, label = line.children[1], line.children[2]
    -- red under: idLine drawing the X after the name, or not at all
    assertEqual(x.type, "Icon", "line " .. i .. ": the X is first")
    assertEqual(x.__removeAtlas, "transmog-icon-remove")
    assertEqual(x.imageSize[1], 16)
    assertEqual(label.type, "InteractiveLabel")
    -- red under: entryAction still drawn under the icon style
    assertEqual(#line.children, 2, "line " .. i .. ": nothing on the right")
  end
  assertEqual(lines[1].children[2].text, "Power Word: Fortitude |cff808080(21562)|r")
end)

test("IdList removeStyle icon: a click on the X calls onRemove and rebuilds the list", function()
  local _, _, lines, log = listBench({ { id = 21562 }, { id = 774 } }, { removeStyle = "icon" })
  lines[2].children[1]:__fire("OnClick")
  -- red under: the X not wired to onRemove
  assertEqual(log.removed[1], 774)
  assertEqual(log.rebuilt, 1, "the list's shape changed, so it is drawn again")
end)

test("IdList removeStyle icon: the X's tooltip is the remove string, a host's override honored", function()
  local _, _, lines = listBench({ { id = 21562 } }, { removeStyle = "icon", strings = { remove = "Forget" } })
  local x = lines[1].children[1]
  -- red under: the X drawn with no tooltip (a bare icon says nothing about what it does)
  assertTrue(x.callbacks.OnEnter ~= nil, "a tooltip is attached")
  local shown = {}
  local tip = mocks.GameTooltip
  local setText = tip.SetText
  tip.SetText = function(_, text)
    local n = #shown
    shown[n + 1] = text
  end
  x:__fire("OnEnter")
  tip.SetText = setText
  assertEqual(shown[1], "Forget")
end)

test("IdList without removeStyle draws exactly as before: the name, then Remove or a checkbox", function()
  local _, _, lines = listBench({ { id = 21562 }, { id = 774, toggle = true, on = true } })
  -- red under: the icon style leaking into a list that did not ask for it
  assertEqual(lines[1].children[1].type, "InteractiveLabel")
  assertEqual(lines[1].children[1].relativeWidth, 0.78)
  assertEqual(lines[1].children[2].type, "Button")
  assertEqual(lines[2].children[2].type, "CheckBox")
  assertNil(lines[1].children[3])
end)

test("IdList removeStyle icon: drawn disabled, the X is disabled", function()
  local _, _, lines = listBench({ { id = 21562 } }, { removeStyle = "icon", disabled = true })
  -- red under: entryRemoveIcon ignoring the page's disable (a disabled page would still remove ids)
  assertTrue(lines[1].children[1].disabled)
end)
