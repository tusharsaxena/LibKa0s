-- tests/test_widgets_searchbox.lua — LibKa0s-Widgets-1.0: `lib.SearchBox` (minor 13), the flat
-- filter-bar search box in the dropdown's skin, with the gold focus line (#52).
--
-- Every case runs under the geometry factory tests/fixture_geom.lua installs (the reason is
-- tests/test_widgets.lua's header), wrapped once more here by `recording`: the geometry frame
-- answers its catch-all for the backdrop colors, the text insets, the focus calls and HookScript,
-- so a case could not ask what border the box wears or whether a host hook survived. The wrapper
-- rawsets a recorder for exactly those, and nothing else.

local T = _G.LK_TEST
local assertEqual = T.assertEqual
local assertTrue  = T.assertTrue
local assertFalse = T.assertFalse
local mocks       = T.mocks
local W = T.widgets

local Geom = dofile("tests/fixture_geom.lua")
local test = Geom.test

local FILL  = { 0.1, 0.1, 0.12, 0.9 }
local LINE  = { 0.24, 0.24, 0.27, 0.9 }
local FOCUS = { 1, 0.82, 0, 0.9 }
local HOST_ICON = "Interface\\AddOns\\Host\\media\\icons\\search"

local function flush()
  for _ = 1, 20 do
    if mocks.__fireTimers() == 0 then return end
  end
end

--- Run `fn()` with every frame CreateFrame builds carrying recorders for what this widget paints.
local function recording(fn)
  local saved = mocks.CreateFrame
  mocks.CreateFrame = function(...)
    local f = saved(...)
    rawset(f, "SetBackdropColor", function(self, ...) self.__bg = { ... } end)
    rawset(f, "SetBackdropBorderColor", function(self, ...) self.__border = { ... } end)
    rawset(f, "SetTextInsets", function(self, ...) self.__insets = { ... } end)
    rawset(f, "SetAutoFocus", function(self, v) self.__autoFocus = v end)
    rawset(f, "SetFontObject", function(self, v) self.__fontObject = v end)
    rawset(f, "ClearFocus", function(self) self.__cleared = (self.__cleared or 0) + 1 end)
    -- Chained as the client chains a hook: the script that was set runs first.
    rawset(f, "HookScript", function(self, name, hook)
      local prev = self.__scripts[name]
      self.__scripts[name] = function(...)
        if prev then prev(...) end
        return hook(...)
      end
    end)
    return f
  end
  local ok, err = pcall(fn)
  mocks.CreateFrame = saved
  flush()
  if not ok then error(err, 0) end
end

--- The player typing: the box's text becomes `t`, and the client fires OnTextChanged.
local function typeText(box, t)
  box.__text = t
  box:__fire("OnTextChanged", true)
end

local function sameColor(got, want)
  assertTrue(type(got) == "table", "a color was painted")
  for i = 1, 4 do assertEqual(got[i], want[i]) end
end

-- ── the skin ─────────────────────────────────────────────────────────────────────────────────

test("SearchBox: wears the dropdown's skin, fill, line and height 20", function()
  recording(function()
    local dd = W.Dropdown(mocks.UIParent, 110)
    local box = W.SearchBox(mocks.UIParent, 160)
    assertEqual(box.__frameType, "EditBox")
    sameColor(box.__bg, dd.__bg)
    sameColor(box.__border, dd.__border)
    assertEqual(box:GetHeight(), 20)
    assertEqual(dd:GetHeight(), 20)
    -- The autocomplete's published chrome is the same house skin; the three must agree.
    sameColor(box.__bg, W.AUTOCOMPLETE.BG)
    sameColor(box.__border, W.AUTOCOMPLETE.BORDER)
  end)
end)

test("SearchBox: the dropdown's look is unchanged after the SKIN hoist", function()
  recording(function()
    local dd = W.Dropdown(mocks.UIParent, 110)
    sameColor(dd.__bg, FILL)
    sameColor(dd.__border, LINE)
    assertEqual(dd:GetWidth(), 110)
    assertEqual(dd:GetHeight(), 20)
  end)
end)

test("SearchBox: small highlight face, no auto focus", function()
  recording(function()
    local box = W.SearchBox(mocks.UIParent, 160)
    assertEqual(box.__fontObject, "GameFontHighlightSmall")
    assertEqual(box.__autoFocus, false)
  end)
end)

test("SearchBox: a number width is set, a nil width sets none", function()
  recording(function()
    assertEqual(W.SearchBox(mocks.UIParent, 160):GetWidth(), 160)
    -- The host that anchors both edges (LootHistory, DropWatcher) passes nil.
    assertEqual(W.SearchBox(mocks.UIParent, nil):GetWidth(), 0)
  end)
end)

-- ── the hint ─────────────────────────────────────────────────────────────────────────────────

test("SearchBox: the hint shows when empty, hides on text, shows again on clear", function()
  recording(function()
    local box = W.SearchBox(mocks.UIParent, 160, { hint = "Search..." })
    assertEqual(box.hint.__template, "GameFontDisableSmall")
    assertEqual(box.hint:GetText(), "Search...")
    assertTrue(box.hint:IsShown())
    typeText(box, "lin")
    assertFalse(box.hint:IsShown())
    typeText(box, "")
    assertTrue(box.hint:IsShown())
  end)
end)

test("SearchBox: a nil GetText counts as empty", function()
  recording(function()
    local box = W.SearchBox(mocks.UIParent, 160, { hint = "Search..." })
    typeText(box, "x")
    assertFalse(box.hint:IsShown())
    typeText(box, nil)
    assertTrue(box.hint:IsShown())
  end)
end)

test("SearchBox: no hint opt gives an empty hint, still a FontString", function()
  recording(function()
    local box = W.SearchBox(mocks.UIParent, 160)
    assertEqual(box.hint:GetText(), "")
  end)
end)

-- ── keys and focus ───────────────────────────────────────────────────────────────────────────

test("SearchBox: Escape and Enter clear focus", function()
  recording(function()
    local box = W.SearchBox(mocks.UIParent, 160)
    box:__fire("OnEscapePressed")
    assertEqual(box.__cleared, 1)
    box:__fire("OnEnterPressed")
    assertEqual(box.__cleared, 2)
  end)
end)

test("SearchBox: focus gained paints the gold line, focus lost the gray one", function()
  recording(function()
    local box = W.SearchBox(mocks.UIParent, 160)
    box:__fire("OnEditFocusGained")
    sameColor(box.__border, FOCUS)
    box:__fire("OnEditFocusLost")
    sameColor(box.__border, LINE)
  end)
end)

-- ── onChange ─────────────────────────────────────────────────────────────────────────────────

test("SearchBox: onChange gets (text, box) exactly once per change", function()
  recording(function()
    local calls = {}
    local box
    box = W.SearchBox(mocks.UIParent, 160, {
      onChange = function(text, b) calls[#calls + 1] = { text, b } end,
    })
    typeText(box, "ore")
    assertEqual(#calls, 1)
    assertEqual(calls[1][1], "ore")
    assertTrue(calls[1][2] == box, "the box itself is passed")
    typeText(box, nil)
    assertEqual(#calls, 2)
    assertEqual(calls[2][1], "")
  end)
end)

-- ── the icon ─────────────────────────────────────────────────────────────────────────────────

test("SearchBox: an icon path draws an 11x11 mark at LEFT+5 and insets the text 21", function()
  recording(function()
    local box = W.SearchBox(mocks.UIParent, 160, { icon = HOST_ICON })
    assertTrue(box.icon ~= nil, "box.icon is built")
    assertEqual(box.icon.__texture, HOST_ICON)
    assertEqual(box.icon:GetWidth(), 11)
    assertEqual(box.icon:GetHeight(), 11)
    local point, _, _, x = box.icon:GetPoint(1)
    assertEqual(point, "LEFT")
    assertEqual(x, 5)
    local c = box.icon.__vertexColor
    assertEqual(c[1], 0.7); assertEqual(c[2], 0.7); assertEqual(c[3], 0.72)
    assertEqual(box.__insets[1], 21)
    assertEqual(box.__insets[2], 6)
    assertEqual(box.__insets[3], 0)
    assertEqual(box.__insets[4], 0)
    local _, _, _, hx = box.hint:GetPoint(1)
    assertEqual(hx, 21)
  end)
end)

test("SearchBox: no icon keeps box.icon nil and the text inset 6", function()
  recording(function()
    local box = W.SearchBox(mocks.UIParent, 160, { icon = true })
    assertEqual(box.icon, nil)
    assertEqual(box.__insets[1], 6)
    local _, _, _, hx = box.hint:GetPoint(1)
    assertEqual(hx, 6)
  end)
end)

test("SearchBox: a numeric fileID is an icon too", function()
  recording(function()
    local box = W.SearchBox(mocks.UIParent, 160, { icon = 134400 })
    assertEqual(box.icon.__texture, 134400)
    assertEqual(box.__insets[1], 21)
  end)
end)

-- ── composition ──────────────────────────────────────────────────────────────────────────────

test("SearchBox: host hooks on OnTextChanged and OnEditFocusGained survive and run", function()
  recording(function()
    local box = W.SearchBox(mocks.UIParent, 160, { hint = "Search..." })
    local typed, focused = 0, 0
    box:HookScript("OnTextChanged", function() typed = typed + 1 end)
    box:HookScript("OnEditFocusGained", function() focused = focused + 1 end)
    typeText(box, "a")
    assertEqual(typed, 1)
    assertFalse(box.hint:IsShown())
    box:__fire("OnEditFocusGained")
    assertEqual(focused, 1)
    sameColor(box.__border, FOCUS)
  end)
end)

test("SearchBox: W.Autocomplete composes on it, and the hint still toggles", function()
  recording(function()
    local asked = {}
    local box = W.SearchBox(mocks.UIParent, 160, { hint = "Search..." })
    local h = W.Autocomplete(box, {
      provider = function(text) asked[#asked + 1] = text; return {} end,
    })
    assertTrue(h ~= nil, "Autocomplete accepts the box")
    typeText(box, "lin")
    assertFalse(box.hint:IsShown())
    flush()
    assertEqual(asked[#asked], "lin")
    typeText(box, "")
    assertTrue(box.hint:IsShown())
    h:Release()
  end)
end)

test("SearchBox: the host rewrites the hint through box.hint:SetText", function()
  recording(function()
    local box = W.SearchBox(mocks.UIParent, 160, { hint = "Search..." })
    box.hint:SetText("Filter loot")
    assertEqual(box.hint:GetText(), "Filter loot")
    assertTrue(box.hint:IsShown())
  end)
end)
