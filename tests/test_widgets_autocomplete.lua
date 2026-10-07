-- tests/test_widgets_autocomplete.lua — LibKa0s-Widgets-1.0: `lib.Autocomplete`, the suggestion
-- list under a host's EditBox.
--
-- The box is a kit frame with its text, its focus and the pointer answered by the test (the kit
-- answers its own table for any getter it does not model, which the widget reads as "no"). Every
-- frame the widget builds goes through a recording CreateFrame, so a case can read the list's
-- anchors, its skin and each row's color. Textures and FontStrings are the frame itself in the
-- base kit (testkit/mock_base.lua's "Known divergence"), so a row's text is read from the row's
-- `__text`, and its selection from `__selected`.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse = T.test, T.assertEqual, T.assertTrue, T.assertFalse
local mocks = T.mocks
local W = T.widgets
local AC = W.AUTOCOMPLETE

local function flush()
  for _ = 1, 20 do
    if mocks.__fireTimers() == 0 then return end
  end
end

--- Run `fn(made)` with every CreateFrame recorded: each frame keeps its points, backdrop colors,
--- text colors and how often it was highlighted.
local function recording(fn)
  local saved, made = mocks.CreateFrame, {}
  mocks.CreateFrame = function(...)
    local f = saved(...)
    f.__points, f.__textColors = {}, {}
    rawset(f, "SetPoint", function(self, ...) self.__points[#self.__points + 1] = { ... } end)
    rawset(f, "SetBackdropColor", function(self, ...) self.__bg = { ... } end)
    rawset(f, "SetBackdropBorderColor", function(self, ...) self.__border = { ... } end)
    rawset(f, "SetTextColor", function(self, ...) self.__textColors[#self.__textColors + 1] = { ... } end)
    rawset(f, "SetFrameStrata", function(self, s) self.__strata = s end)
    made[#made + 1] = f
    return f
  end
  local ok, err = pcall(fn, made)
  mocks.CreateFrame = saved
  flush()
  if not ok then error(err, 0) end
end

--- A search box the test drives: `type(text)` is the player typing, `set(text)` the host's own
--- SetText, and focus is held until the test says otherwise.
local function newBox(hostScripts)
  local box = mocks.CreateFrame("EditBox")
  box.__text, box.__focus = "", true
  rawset(box, "GetText", function(self) return self.__text end)
  rawset(box, "HasFocus", function(self) return self.__focus end)
  rawset(box, "SetFocus", function(self) self.__focus = true; self.__refocused = (self.__refocused or 0) + 1 end)
  rawset(box, "ClearFocus", function(self)
    self.__focus = false
    self:__fire("OnEditFocusLost")
  end)
  rawset(box, "SetText", function(self, t) self.__text = t; self.__setText = (self.__setText or 0) + 1
    self:__fire("OnTextChanged", false) end)
  for name, fn in pairs(hostScripts or {}) do box:SetScript(name, fn) end
  function box:type(t) self.__text = t; self:__fire("OnTextChanged", true) end
  return box
end

local function items(n, prefix)
  local out = {}
  for i = 1, n do out[i] = { text = (prefix or "Item ") .. i, value = i } end
  return out
end

local function shownRows(h)
  local n = 0
  for _, r in ipairs(h.__rows) do if r:IsShown() then n = n + 1 end end
  return n
end

--- A handle over a fresh box with a counting provider answering `answer(text)`.
local function setup(answer, extra)
  local box = newBox(extra and extra.hostScripts)
  local calls, picked = {}, {}
  local opts = {
    provider = function(text) calls[#calls + 1] = text; return answer(text) end,
    onPick = function(item) picked[#picked + 1] = item end,
  }
  for k, v in pairs(extra or {}) do if k ~= "hostScripts" then opts[k] = v end end
  local h = W.Autocomplete(box, opts)
  return h, box, calls, picked
end

local function typed(box, text)
  box:type(text)
  flush()
end

-- ── construction ──

test("autocomplete: answers nil without a provider or without a box it can hook", function()
  assertTrue(W.Autocomplete(newBox(), {}) == nil, "no provider")
  assertTrue(W.Autocomplete(nil, { provider = function() end }) == nil, "no box")
  assertTrue(W.Autocomplete({}, { provider = function() end }) == nil, "a table that cannot HookScript")
end)

test("autocomplete: publishes its chrome, with the 0.15 s debounce floor and 8 rows by default", function()
  assertEqual(AC.MAX_ROWS, 8)
  assertTrue(AC.DEBOUNCE >= 0.15, "debounce is at least 0.15 s")
  assertEqual(AC.MIN_CHARS, 1)
  assertEqual(W.MODULES.WidgetsAutocomplete, W.__autocompleteMinor)
end)

-- ── the provider and the debounce ──

test("autocomplete: typing asks the provider only after the debounce, once for a burst", function()
  local h, box, calls = setup(function() return items(3) end)
  box:type("a")
  box:type("ab")
  assertEqual(#calls, 0, "nothing until the debounce runs")
  local last = mocks.__timers[#mocks.__timers]
  assertTrue(last.delay >= 0.15, "debounced by at least 0.15 s")
  flush()
  assertEqual(#calls, 1, "the earlier keystroke's update was dropped")
  assertEqual(calls[1], "ab")
  assertTrue(h:IsShown(), "the list is up")
  assertEqual(shownRows(h), 3)
end)

test("autocomplete: an opts.debounce under the floor is raised to it", function()
  local _, box = setup(function() return items(1) end, { debounce = 0.01 })
  box:type("a")
  assertTrue(mocks.__timers[#mocks.__timers].delay >= 0.15)
  flush()
end)

test("autocomplete: empty or blank text closes without asking the provider", function()
  local h, box, calls = setup(function() return items(2) end)
  typed(box, "x")
  assertTrue(h:IsShown())
  typed(box, "   ")
  assertFalse(h:IsShown(), "blank text closes")
  assertEqual(#calls, 1, "the provider is not asked about blank text")
  typed(box, "")
  assertFalse(h:IsShown())
  assertEqual(#calls, 1)
end)

test("autocomplete: an empty or nil provider answer hides the list and never raises", function()
  local answer = items(2)
  local h, box = setup(function() return answer end)
  typed(box, "a")
  assertTrue(h:IsShown())
  answer = {}
  typed(box, "ab")
  assertFalse(h:IsShown(), "empty answer hides")
  answer = nil
  typed(box, "abc")
  assertFalse(h:IsShown(), "nil answer hides")
  assertFalse(h.__list:IsShown())
end)

test("autocomplete: at most maxRows rows, 8 by default", function()
  local h, box = setup(function() return items(20) end)
  typed(box, "a")
  assertEqual(shownRows(h), 8)
  local h2, box2 = setup(function() return items(20) end, { maxRows = 3 })
  typed(box2, "a")
  assertEqual(shownRows(h2), 3)
  assertEqual(#h2.__items, 3, "keyboard and picks only reach the shown rows")
end)

test("autocomplete: Refresh asks the provider at once for the box's text", function()
  local h, box, calls = setup(function() return items(2) end)
  box.__text = "zz"
  h:Refresh()
  assertEqual(calls[1], "zz")
  assertTrue(h:IsShown())
end)

-- ── the frame ──

test("autocomplete: the list hangs from the box's bottom corners, the box's width, in its own strata", function()
  recording(function(made)
    local h, box = setup(function() return items(2) end)
    typed(box, "a")
    local list = h.__list
    assertTrue(list.__parent == box, "parented to the box, so it takes its scale and hides with it")
    assertEqual(list.__strata, AC.STRATA)
    local tl, tr = list.__points[1], list.__points[2]
    assertEqual(tl[1], "TOPLEFT"); assertTrue(tl[2] == box); assertEqual(tl[3], "BOTTOMLEFT")
    assertEqual(tr[1], "TOPRIGHT"); assertTrue(tr[2] == box); assertEqual(tr[3], "BOTTOMRIGHT")
    assertEqual(tl[5], AC.OVERLAP)
    assertTrue(#made >= 3, "a list and its rows")
  end)
end)

test("autocomplete: the list wears the box's own border and background", function()
  recording(function()
    local h, box = setup(function() return items(1) end)
    rawset(box, "GetBackdropBorderColor", function() return 0.24, 0.24, 0.27, 0.9 end)
    rawset(box, "GetBackdropColor", function() return 0.1, 0.1, 0.12, 0.5 end)
    typed(box, "a")
    assertEqual(table.concat(h.__list.__border, ","), "0.24,0.24,0.27,0.9")
    local bg = h.__list.__bg
    assertEqual(bg[1], 0.1)
    assertEqual(bg[4], AC.MIN_BG_ALPHA, "a see-through box still gets a legible list")
  end)
end)

test("autocomplete: a box with no backdrop colors gets the house flat skin", function()
  recording(function()
    local h, box = setup(function() return items(1) end)
    typed(box, "a")
    assertEqual(table.concat(h.__list.__border, ","), table.concat(AC.BORDER, ","))
  end)
end)

test("autocomplete: each row takes its item's color, in either shape, and plain text without one", function()
  recording(function()
    local h, box = setup(function()
      return { { text = "Epic", color = { 0.64, 0.21, 0.93 } }, { text = "Rare", color = { r = 0, g = 0.44, b = 0.87 } },
               { text = "Plain" } }
    end)
    typed(box, "a")
    local function last(row) return table.concat(row.__textColors[#row.__textColors], ",") end
    assertEqual(last(h.__rows[1]), "0.64,0.21,0.93")
    assertEqual(last(h.__rows[2]), "0,0.44,0.87")
    assertEqual(last(h.__rows[3]), table.concat(AC.TEXT, ","))
    assertEqual(h.__rows[1].__text, "Epic")
  end)
end)

test("autocomplete: rows are pooled, and a shorter list hides the leftovers", function()
  local n = 5
  local h, box = setup(function() return items(n) end)
  typed(box, "a")
  local first = h.__rows[1]
  assertEqual(#h.__rows, 5)
  n = 2
  typed(box, "ab")
  assertEqual(#h.__rows, 5, "no row is built twice")
  assertTrue(h.__rows[1] == first)
  assertEqual(shownRows(h), 2)
end)

-- ── the keyboard ──

test("autocomplete: Down and Up move the selection, Up from the first row goes back to the text", function()
  local h, box = setup(function() return items(3) end)
  typed(box, "a")
  box:__fire("OnArrowPressed", "DOWN")
  assertEqual(h.__sel, 1); assertTrue(h.__rows[1].__selected)
  box:__fire("OnArrowPressed", "DOWN")
  box:__fire("OnArrowPressed", "DOWN")
  box:__fire("OnArrowPressed", "DOWN")
  assertEqual(h.__sel, 3, "stops at the last row")
  assertFalse(h.__rows[1].__selected)
  box:__fire("OnArrowPressed", "UP")
  box:__fire("OnArrowPressed", "UP")
  assertEqual(h.__sel, 1)
  box:__fire("OnArrowPressed", "UP")
  assertTrue(h.__sel == nil)
  assertFalse(h.__rows[1].__selected)
end)

test("autocomplete: Enter picks the selected row, closes, and hands the host the item as provided", function()
  local h, box, _, picked = setup(function() return items(3) end)
  typed(box, "a")
  box:__fire("OnArrowPressed", "DOWN")
  box:__fire("OnArrowPressed", "DOWN")
  box:__fire("OnEnterPressed")
  assertEqual(#picked, 1)
  assertEqual(picked[1].value, 2)
  assertFalse(h:IsShown())
end)

test("autocomplete: Enter still picks when the host's own Enter clears focus first", function()
  local h, box, _, picked = setup(function() return items(3) end,
    { hostScripts = { OnEnterPressed = function(self) self:ClearFocus() end } })
  typed(box, "a")
  box:__fire("OnArrowPressed", "DOWN")
  box:__fire("OnEnterPressed")
  assertEqual(#picked, 1, "the focus-lost close waits for the Enter hook")
  assertEqual(picked[1].value, 1)
  flush()
  assertFalse(h:IsShown())
end)

test("autocomplete: Enter with nothing selected closes and picks nothing", function()
  local h, box, _, picked = setup(function() return items(3) end)
  typed(box, "a")
  box:__fire("OnEnterPressed")
  assertEqual(#picked, 0)
  assertFalse(h:IsShown())
end)

test("autocomplete: Tab picks the selected row, or the first", function()
  local h, box, _, picked = setup(function() return items(3) end)
  typed(box, "a")
  box:__fire("OnTabPressed")
  assertEqual(picked[1].value, 1)
  assertFalse(h:IsShown())
  typed(box, "ab")
  box:__fire("OnArrowPressed", "DOWN")
  box:__fire("OnArrowPressed", "DOWN")
  box:__fire("OnTabPressed")
  assertEqual(picked[2].value, 2)
end)

test("autocomplete: Esc closes and keeps the typed text", function()
  local h, box, _, picked = setup(function() return items(3) end,
    { hostScripts = { OnEscapePressed = function(self) self:ClearFocus() end } })
  typed(box, "abc")
  box:__fire("OnEscapePressed")
  assertFalse(h:IsShown())
  assertEqual(box.__text, "abc")
  assertTrue(box.__setText == nil, "the widget never writes the box's text")
  assertEqual(#picked, 0)
end)

test("autocomplete: a new keystroke drops the selection at once", function()
  local h, box, _, picked = setup(function() return items(3) end)
  typed(box, "a")
  box:__fire("OnArrowPressed", "DOWN")
  box:type("ab")
  assertTrue(h.__sel == nil)
  assertFalse(h.__rows[1].__selected)
  box:__fire("OnEnterPressed")
  assertEqual(#picked, 0, "Enter cannot take a row the new text may no longer match")
  flush()
end)

-- ── the mouse and the focus ──

test("autocomplete: a click on a row picks it and closes", function()
  local h, box, _, picked = setup(function() return items(3) end)
  typed(box, "a")
  h.__rows[3]:__fire("OnClick")
  assertEqual(picked[1].value, 3)
  assertFalse(h:IsShown())
end)

test("autocomplete: focus lost elsewhere closes on the next frame", function()
  local h, box = setup(function() return items(3) end)
  typed(box, "a")
  box:ClearFocus()
  assertTrue(h:IsShown(), "not on the spot")
  flush()
  assertFalse(h:IsShown())
end)

test("autocomplete: focus lost to a press on the list keeps it, gives the box the keys back, and the row's click picks", function()
  local h, box, _, picked = setup(function() return items(3) end)
  typed(box, "a")
  rawset(h.__list, "IsMouseOver", function() return true end)
  box:ClearFocus()
  flush()
  assertTrue(h:IsShown(), "a press on the list does not close it")
  assertEqual(box.__refocused, 1, "the box takes the keys back")
  h.__rows[2]:__fire("OnClick")
  assertEqual(picked[1].value, 2)
  assertFalse(h:IsShown())
end)

test("autocomplete: focus regained before the next frame keeps the list", function()
  local h, box = setup(function() return items(3) end)
  typed(box, "a")
  box:ClearFocus()
  box.__focus = true
  flush()
  assertTrue(h:IsShown())
end)

test("autocomplete: a debounce still waiting when focus goes shows nothing", function()
  local h, box, calls = setup(function() return items(3) end)
  box:type("a")
  box:ClearFocus()
  flush()
  assertEqual(#calls, 0)
  assertFalse(h:IsShown())
end)

test("autocomplete: focus gained with text in the box offers the list again", function()
  local h, box, calls = setup(function() return items(2) end)
  box.__text = "a"
  box:__fire("OnEditFocusGained")
  flush()
  assertEqual(#calls, 1)
  assertTrue(h:IsShown())
end)

test("autocomplete: the host's own SetText closes the list, and the box hiding closes it", function()
  local h, box = setup(function() return items(2) end)
  typed(box, "a")
  box:SetText("")
  assertFalse(h:IsShown())
  typed(box, "a")
  box:__fire("OnHide")
  assertFalse(h:IsShown())
end)

-- ── the handle ──

test("autocomplete: Close hides the list and drops a waiting update", function()
  local h, box, calls = setup(function() return items(2) end)
  typed(box, "a")
  h:Close()
  assertFalse(h:IsShown())
  box:type("ab")
  h:Close()
  flush()
  assertEqual(#calls, 1, "the update typed before Close never ran")
end)

test("autocomplete: SetEnabled(false) closes and ignores typing until enabled again", function()
  local h, box, calls = setup(function() return items(2) end)
  typed(box, "a")
  h:SetEnabled(false)
  assertFalse(h:IsShown())
  typed(box, "ab")
  assertEqual(#calls, 1)
  h:SetEnabled(true)
  typed(box, "abc")
  assertEqual(#calls, 2)
  assertTrue(h:IsShown())
end)

test("autocomplete: Release leaves the hooks inert, and a second Autocomplete on the box replaces the first", function()
  local h, box, calls = setup(function() return items(2) end)
  typed(box, "a")
  h:Release()
  assertFalse(h:IsShown())
  typed(box, "ab")
  assertEqual(#calls, 1, "a released handle never asks its provider again")
  local calls2 = 0
  local h2 = W.Autocomplete(box, { provider = function() calls2 = calls2 + 1; return items(1) end })
  local h3 = W.Autocomplete(box, { provider = function() return items(4) end })
  typed(box, "abc")
  assertEqual(calls2, 0, "the replaced handle is released")
  assertFalse(h2:IsShown())
  assertEqual(shownRows(h3), 4)
end)

-- ── re-hooking, maxRows and the backdrop (minor 2) ──

test("autocomplete: calling it again after a host SetScript dropped the hooks brings the list back", function()
  -- red under: minor 1, whose once-per-box guard never re-hooked, so the list never opened again.
  local _, box = setup(function() return items(2) end)
  local hostRan = 0
  box:SetScript("OnTextChanged", function() hostRan = hostRan + 1 end)
  local h2 = W.Autocomplete(box, { provider = function() return items(3) end })
  typed(box, "a")
  assertEqual(hostRan, 1, "the host's new handler runs")
  assertTrue(h2:IsShown(), "the re-installed hook opens the list")
  assertEqual(shownRows(h2), 3)
end)

test("autocomplete: calling it twice without a SetScript dispatches each script once", function()
  -- red under: a re-hook on every call with no generation guard (two hook sets, two dispatches).
  local _, box = setup(function() return items(2) end)
  local calls, picked = 0, 0
  local h2 = W.Autocomplete(box, {
    provider = function() calls = calls + 1; return items(3) end,
    onPick = function() picked = picked + 1 end,
  })
  typed(box, "a")
  assertEqual(calls, 1, "one keystroke asks the provider once")
  box:__fire("OnArrowPressed", "DOWN")
  assertEqual(h2.__sel, 1, "one Down moves one row")
  box:__fire("OnEnterPressed")
  assertEqual(picked, 1, "one Enter picks once")
  assertFalse(h2:IsShown())
end)

test("autocomplete: a fractional maxRows is floored, and the list is exactly that many rows tall", function()
  -- red under: minor 1, which drew 2 rows in a list 2.5 rows tall.
  recording(function()
    local h, box = setup(function() return items(8) end, { maxRows = 2.5 })
    local heights = {}
    typed(box, "a")
    rawset(h.__list, "SetHeight", function(_, v) heights[#heights + 1] = v end)
    typed(box, "ab")
    assertEqual(shownRows(h), 2)
    assertEqual(#h.__items, 2)
    assertEqual(heights[#heights], 2 * AC.ROW_H + 2 * AC.PAD)
  end)
end)

test("autocomplete: a maxRows that floors below 1 falls back to MAX_ROWS", function()
  -- red under: minor 1, which took 0.5 as the row count and drew no row at all.
  local h, box = setup(function() return items(20) end, { maxRows = 0.5 })
  typed(box, "a")
  assertEqual(shownRows(h), AC.MAX_ROWS)
end)

test("autocomplete: the backdrop is set once, and its colors follow a restyled box on every show", function()
  -- red under: minor 1, which called SetBackdrop on every render.
  local saved, backdrops = mocks.CreateFrame, 0
  recording(function()
    local inner = mocks.CreateFrame
    mocks.CreateFrame = function(...)
      local f = inner(...)
      rawset(f, "SetBackdrop", function() backdrops = backdrops + 1 end)
      return f
    end
    local h, box = setup(function() return items(2) end)
    typed(box, "a")
    typed(box, "ab")
    rawset(box, "GetBackdropColor", function() return 0.3, 0.2, 0.1, 1 end)
    rawset(box, "GetBackdropBorderColor", function() return 0.5, 0.5, 0.5, 1 end)
    typed(box, "abc")
    mocks.CreateFrame = saved
    assertEqual(backdrops, 1, "one SetBackdrop across three renders")
    assertEqual(table.concat(h.__list.__bg, ","), "0.3,0.2,0.1,1")
    assertEqual(table.concat(h.__list.__border, ","), "0.5,0.5,0.5,1")
  end)
end)
