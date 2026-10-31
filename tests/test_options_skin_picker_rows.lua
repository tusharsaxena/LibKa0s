-- tests/test_options_skin_picker_rows.lua -- the skin picker's font, texture, outline and scope rows
-- (OptionsSkinPicker.lua minor 4, LK-A3 of Ka0sAddonsCommonTasks
-- docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES, the owner's request to give every addon's picker the
-- Skin tab's elements).
--
-- What it pins: the rows, in order, in a window at most 10% wider; each row's list, value and tooltip
-- from the Skin tab's own helpers; a pick, a reset and a scope flip previewing with no write, Apply
-- saving them through spec.set, a dismissal putting them back, and a write from elsewhere surviving
-- that dismissal; a skin pick clearing the override and the rows showing it (D-10); Apply to all
-- carrying them the way the Skin tab's copy does; the combat refusals and locks; the skin list laying
-- over the rows at T8; the widgets being acquired for a showing and released at its close, so a
-- closed picker holds nothing; the skin reaching them whatever Ignore settings panel says; and the
-- font preload staying the skins' faces until a pull-out opens. The degraded paths close it. The
-- review of LK-A3 adds: an open pull-out closing before its list is rebuilt, the rows waking when
-- combat ends, the reset icon sitting on its bar, the section's heading, and a Skin-tab write made
-- while the picker is up storing nothing the picker only previewed.
--
-- These pin what the library asks of the client. Whether the rows fit, and how a pull-out sits over
-- the window, is the owner's to judge in game.

local K = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  K.test, K.assertEqual, K.assertTrue, K.assertFalse, K.assertNil

local Bench = dofile("tests/fixture_skin_picker.lua")
local Fixture = dofile("tests/fixture_media.lua")
local OWNER, OTHER = Bench.OWNER, Bench.OTHER
local FIRA = "Ka0s Fira Sans"
local WAKE = 1      -- an OnUpdate's elapsed long past the picker's throttle

--- A fresh client with the real picker types, an owner, an instance and its spec. `opts.noBase`
--- leaves the stock Dropdown out, `opts.noLsm` LibSharedMedia. Answers the bench table.
local function bench(opts)
  opts = opts or {}
  local m, Skin, lib, ace = Fixture.env(opts)
  dofile("tests/_kit/mock_layers.lua")(m)
  Bench.armGeometry(m)
  m.popups = {}
  m.StaticPopup_Show = function(which, a1) m.popups[#m.popups + 1] = { which = which, a1 = a1 } end
  local store = Bench.register(Skin, OWNER)
  local O = Bench.instance(lib, OWNER)
  return { m = m, Skin = Skin, lib = lib, ace = ace, store = store, O = O, spec = Bench.specFor(store, opts.spec) }
end

local function open(b)
  b.f = b.O.SkinPicker(b.spec)
  return b.f
end

--- Is window `f` among what the kit says will still wake up?
local function armed(b, f)
  for _, t in ipairs(b.m.__timers()) do
    if t == f then return true end
  end
  return false
end

local function calls(store) return store.calls or {} end

local function lastMedia(store)
  local list = calls(store)
  for i = #list, 1, -1 do
    if list[i][4] then return list[i][4] end
  end
end

local function lastIgnore(store)
  local list = calls(store)
  for i = #list, 1, -1 do
    if list[i][3] then return list[i][3] end
  end
end

--- The offset of a row's top below the window's: its anchor's y, negated.
local function topOf(w)
  local pts = rawget(w.frame, "__pts")
  if pts then return -pts[1][5] end
  return w.__topForTest
end

--- Record widget frames' anchors too (the fake's frames are made before armGeometry reaches them).
local function armWidgets(b)
  local create = b.ace.Create
  b.ace.Create = function(self, wtype, ...)
    local w = create(self, wtype, ...)
    rawset(w.frame, "__pts", {})
    rawset(w.frame, "SetPoint", function(fr, ...)
      local pts = rawget(fr, "__pts")
      pts[#pts + 1] = { ... }
    end)
    rawset(w.frame, "ClearAllPoints", function(fr) rawset(fr, "__pts", {}) end)
    return w
  end
end

local function pickSkin(f, key)
  f.dd:__fire("OnClick")
  for _, r in ipairs({ f.list:GetChildren() }) do
    if r.key == key then r:__fire("OnClick") end
  end
end

-- ── what it draws ────────────────────────────────────────────────────────────────────────────

test("skin picker rows: Font, Texture, Font outline and Scope, in order, in a window at most 10% wider", function()
  local b = bench()
  armWidgets(b)
  local f = open(b)
  local r = f.rows
  assertEqual(r.font.type, "Ka0sMedia_Font")
  assertEqual(r.texture.type, "Ka0sMedia_Statusbar")
  assertEqual(r.outline.type, "Dropdown")
  assertEqual(r.panel.type, "CheckBox")
  assertEqual(r.fonts.type, "CheckBox")
  assertEqual(r.font.labelText, "Font")
  assertEqual(r.texture.labelText, "Texture")
  assertEqual(r.outline.labelText, "Font outline")
  assertEqual(f.scopeLabel:GetText(), "Scope")
  assertTrue(f:GetWidth() <= 308, "at most 10% over the 280 it was")
  local a, c, d, e = topOf(r.font), topOf(r.texture), topOf(r.outline), topOf(r.panel)
  assertTrue(a < c and c < d and d < e, "top to bottom")
  assertEqual(topOf(r.panel), topOf(r.fonts), "the check boxes share one row")
  assertTrue(f:GetHeight() > e + 24, "the window holds the rows and the Apply buttons")
end)

test("skin picker rows: the rows wear the Skin tab's words, list and leading previewing row", function()
  local b = bench()
  local f = open(b)
  local own = b.Skin:ResolveSkin("ka0s")["font.body"]
  local dd = f.rows.font
  assertEqual(dd.pullout.items[1].userdata.value, "@skin")
  assertEqual(dd.list["@skin"], "Skin's default (" .. own .. ")")
  assertEqual(dd.__media.previews["@skin"], own)
  assertEqual(dd.value, "@skin")
  assertEqual(f.rows.texture.value, "@skin")
  assertEqual(f.rows.outline.value, "hud", "the default mode")
  assertEqual(f.rows.outline.list.all, "All text")
  assertFalse(f.rows.panel.value)
  assertFalse(f.rows.fonts.value)
end)

test("skin picker rows: a tab copy and the picker read one list (lib-level helpers)", function()
  local b = bench()
  for _, name in ipairs({ "__mediaList", "__fillMedia", "__appliedMedia", "__readIgnore", "__baseTokens" }) do
    assertEqual(type(b.lib[name]), "function", name)
  end
  local items, order = b.lib.__mediaList(b.lib.APPEARANCE_STRINGS, b.Skin, OWNER, "font")
  assertEqual(order[1], "@skin")
  assertEqual(items[FIRA], FIRA)
end)

-- ── the contract: a pick previews, Apply saves, closing restores ─────────────────────────────

test("skin picker rows: a font pick previews with no write, Apply saves it with every media half", function()
  -- red under: rows that wrote through spec.set on the pick, as the Skin tab's do.
  local b = bench()
  local f = open(b)
  f.rows.font:__fire("OnValueChanged", FIRA)
  assertEqual((b.Skin:GetOverride(OWNER)), FIRA, "the preview is live")
  assertEqual(#calls(b.store), 0, "no write on a pick")
  f.apply:__fire("OnClick")
  local media = lastMedia(b.store)
  assertEqual(media.font, FIRA)
  assertEqual(media.texture, false)
  assertNil(media.outline, "an outline never moved off the default stays unstored")
  assertEqual((b.Skin:GetOverride(OWNER)), FIRA, "and stays worn")
end)

test("skin picker rows: closing puts back font, texture, outline and scope, with no write", function()
  local b = bench()
  b.Skin:SetOverride(OWNER, FIRA, false)
  local f = open(b)
  f.rows.font:__fire("OnValueChanged", "Ka0s Prototype")
  f.rows.texture:__fire("OnValueChanged", "Smooth")
  f.rows.outline:__fire("OnValueChanged", "all")
  f.rows.fonts:__fire("OnValueChanged", true)
  f.rows.panel:__fire("OnValueChanged", true)
  assertEqual(b.Skin:GetOutline(OWNER), "all")
  assertEqual(select(2, b.Skin:GetIgnore(OWNER)), true)
  f.close:__fire("OnClick")
  local font, texture = b.Skin:GetOverride(OWNER)
  assertEqual(font, FIRA)
  assertNil(texture)
  assertEqual(b.Skin:GetOutline(OWNER), "hud")
  assertNil(b.Skin:__StoredOutline(OWNER), "a default outline stays a default, not a stored mode")
  local panel, fonts = b.Skin:GetIgnore(OWNER)
  assertFalse(panel)
  assertFalse(fonts)
  assertEqual(#calls(b.store), 0, "no write")
end)

test("skin picker rows: an outline taken back to the default in one showing saves nothing", function()
  local b = bench()
  local f = open(b)
  f.rows.outline:__fire("OnValueChanged", "all")
  f.rows.outline:__fire("OnValueChanged", "hud")
  assertNil(b.Skin:__StoredOutline(OWNER))
  f.apply:__fire("OnClick")
  assertNil(lastMedia(b.store))
end)

test("skin picker rows: Apply saves the outline and the scope through the owner's seam", function()
  local b = bench()
  local f = open(b)
  f.rows.outline:__fire("OnValueChanged", "off")
  f.rows.panel:__fire("OnValueChanged", true)
  assertEqual(#calls(b.store), 0)
  f.apply:__fire("OnClick")
  assertEqual(lastMedia(b.store).outline, "off")
  local ig = lastIgnore(b.store)
  assertTrue(ig.panel)
  assertFalse(ig.fonts)
  assertEqual(#b.m.popups, 0, "a scope change raises no reload (Skin:SetIgnore answers none)")
end)

test("skin picker rows: the gear saves them as Apply does", function()
  local b = bench({ spec = { onSettings = function() end } })
  local f = open(b)
  f.rows.font:__fire("OnValueChanged", FIRA)
  f.settings:__fire("OnClick")
  assertEqual(lastMedia(b.store).font, FIRA)
end)

test("skin picker rows: a write from elsewhere during a preview survives the close", function()
  -- red under: a restore that did not check the state the preview left.
  local b = bench()
  local f = open(b)
  f.rows.font:__fire("OnValueChanged", FIRA)
  b.Skin:SetOverride(OWNER, "Ka0s Prototype", nil)
  f.rows.outline:__fire("OnValueChanged", "all")
  b.Skin:SetOutline(OWNER, "off")
  f.rows.fonts:__fire("OnValueChanged", true)
  b.Skin:SetIgnore(OWNER, true, nil)
  f.close:__fire("OnClick")
  assertEqual((b.Skin:GetOverride(OWNER)), "Ka0s Prototype")
  assertEqual(b.Skin:GetOutline(OWNER), "off")
  assertEqual((b.Skin:GetIgnore(OWNER)), true)
end)

test("skin picker rows: another skin clears the font and texture override, and the rows show it (D-10)", function()
  local b = bench()
  b.Skin:SetOverride(OWNER, FIRA, "Smooth")
  local f = open(b)
  assertEqual(f.rows.font.value, FIRA)
  assertEqual(f.rows.texture.value, "Smooth")
  pickSkin(f, "obsidian")
  assertEqual(f.rows.font.value, "@skin")
  assertEqual(f.rows.texture.value, "@skin")
  local own = b.Skin:ResolveSkin("obsidian")["font.body"]
  assertEqual(f.rows.font.list["@skin"], "Skin's default (" .. own .. ")", "naming the new skin's face")
  pickSkin(f, "ka0s")
  assertEqual(f.rows.font.value, FIRA, "a pick back restores them")
end)

test("skin picker rows: a font chosen under a previewed skin goes when the skin moves again", function()
  -- red under: previewMedia acting only on overrides the window opened with.
  local b = bench()
  local f = open(b)
  pickSkin(f, "obsidian")
  f.rows.font:__fire("OnValueChanged", FIRA)
  pickSkin(f, "azeroth")
  assertNil((b.Skin:GetOverride(OWNER)), "D-10 holds for a preview's override too")
  pickSkin(f, "obsidian")
  f.rows.font:__fire("OnValueChanged", FIRA)
  f.close:__fire("OnClick")
  assertNil((b.Skin:GetOverride(OWNER)), "the opened look has none, and the close restores that")
  assertEqual(select(2, b.Skin:GetChoice(OWNER)), "ka0s")
end)

test("skin picker rows: a font picked over a cleared override, then Apply, writes the new one", function()
  local b = bench()
  b.Skin:SetOverride(OWNER, FIRA, "Smooth")
  local f = open(b)
  pickSkin(f, "obsidian")
  f.rows.texture:__fire("OnValueChanged", "Flat")
  f.apply:__fire("OnClick")
  local media = lastMedia(b.store)
  assertEqual(media.font, false)
  assertEqual(media.texture, "Flat")
  assertEqual(b.store.skin, "obsidian")
end)

-- ── the reset buttons ────────────────────────────────────────────────────────────────────────

test("skin picker rows: a reset button is disabled while its half is the skin's own, and says what it does", function()
  local b = bench()
  b.Skin:SetOverride(OWNER, FIRA, false)
  local f = open(b)
  assertTrue(f.reset.font:IsEnabled(), "a font override to reset")
  assertFalse(f.reset.texture:IsEnabled(), "no texture override")
  assertTrue(f.reset.font.__tip:find("Reset font", 1, true) ~= nil)
  assertTrue(f.reset.texture.__tip:find("Reset texture", 1, true) ~= nil)
  f.reset.font:__fire("OnClick")
  assertNil((b.Skin:GetOverride(OWNER)), "a preview of the reset")
  assertEqual(#calls(b.store), 0, "no write")
  assertEqual(f.rows.font.value, "@skin")
  assertFalse(f.reset.font:IsEnabled())
  f.close:__fire("OnClick")
  assertEqual((b.Skin:GetOverride(OWNER)), FIRA, "put back")
end)

test("skin picker rows: the reset icons draw the client's art, which no consumer's icon prune can take", function()
  -- red under: the Media icon "reset", pruned from eleven consumers: a blank button, and no error.
  local b = bench()
  local f = open(b)
  assertEqual(f.reset.font.icon:GetTexture(), "Interface\\Buttons\\UI-RefreshButton")
end)

test("skin picker rows: Ignore fonts disables the Font outline, as on the Skin tab", function()
  local b = bench()
  local f = open(b)
  f.rows.fonts:__fire("OnValueChanged", true)
  assertTrue(f.rows.outline.disabled)
  f.rows.fonts:__fire("OnValueChanged", false)
  assertFalse(f.rows.outline.disabled)
end)

-- ── Apply to all ─────────────────────────────────────────────────────────────────────────────

test("skin picker rows: Apply to all carries font, texture, outline and scope, as the Skin tab's copy does", function()
  -- red under: the skin half alone, the picker's copy before LK-A3.
  local b = bench()
  local other = Bench.register(b.Skin, OTHER)
  local f = open(b)
  pickSkin(f, "obsidian")
  f.rows.font:__fire("OnValueChanged", FIRA)
  f.rows.texture:__fire("OnValueChanged", "Flat")
  f.rows.outline:__fire("OnValueChanged", "off")
  f.rows.panel:__fire("OnValueChanged", true)
  f.applyAll:__fire("OnClick")
  assertEqual(select(2, b.Skin:GetChoice(OTHER)), "obsidian")
  local font, texture = b.Skin:GetOverride(OTHER)
  assertEqual(font, FIRA)
  assertEqual(texture, "Flat")
  assertEqual(b.Skin:GetOutline(OTHER), "off")
  assertEqual((b.Skin:GetIgnore(OTHER)), true)
  local w = other.writes[#other.writes]
  assertEqual(w[2], "obsidian")
  assertTrue(w[3].panel)
  assertEqual(w[4].font, FIRA)
  assertEqual(w[4].outline, "off")
  assertEqual(lastMedia(b.store).font, FIRA, "and this owner's own save")
end)

-- ── combat ───────────────────────────────────────────────────────────────────────────────────

test("skin picker rows: combat refuses a row and the row goes back to what is worn", function()
  local b = bench()
  local f = open(b)
  b.m.InCombatLockdown = function() return true end
  local dd = f.rows.font
  dd:SetValue(FIRA)              -- what the stock widget has done by the time it fires
  dd:__fire("OnValueChanged", FIRA)
  assertNil((b.Skin:GetOverride(OWNER)), "refused")
  assertEqual(dd.value, "@skin", "the row shows the truth again")
  f.rows.panel:SetValue(true)
  f.rows.panel:__fire("OnValueChanged", true)
  assertFalse((b.Skin:GetIgnore(OWNER)))
  assertFalse(f.rows.panel.value)
end)

test("skin picker rows: a window shown in combat draws its rows disabled", function()
  local b = bench()
  b.Skin:SetOverride(OWNER, FIRA, false)
  b.m.InCombatLockdown = function() return true end
  local f = open(b)
  assertTrue(f.rows.font.disabled)
  assertTrue(f.rows.texture.disabled)
  assertTrue(f.rows.outline.disabled)
  assertTrue(f.rows.panel.disabled)
  assertTrue(f.rows.fonts.disabled)
  assertFalse(f.reset.font:IsEnabled())
end)

-- ── layering ─────────────────────────────────────────────────────────────────────────────────

test("skin picker rows: the open skin list lays over the rows at T8, and the window keeps its height", function()
  -- red under: the list growing the window, which would push the rows down under it.
  local b = bench()
  local f = open(b)
  local h = f:GetHeight()
  f.dd:__fire("OnClick")
  assertTrue(f.list:IsShown())
  assertEqual(f:GetHeight(), h, "the rows stay where they are")
  assertEqual(b.m.__layers(f.list).strata, "FULLSCREEN_DIALOG", "frame-layering T8: a transient popup")
  assertEqual(b.m.__layers(f).strata, "DIALOG", "the window itself stays T6, under every pull-out")
end)

test("skin picker rows: using a row closes an open skin list", function()
  local b = bench()
  local f = open(b)
  f.dd:__fire("OnClick")
  f.rows.fonts:__fire("OnValueChanged", true)
  assertFalse(f.list:IsShown())
end)

-- ── a closed picker holds nothing ────────────────────────────────────────────────────────────

test("skin picker rows: the widgets are acquired for a showing and released at its close", function()
  -- red under: rows built once with the window, which a stand-down would find shown.
  local b = bench()
  local f = open(b)
  local rows = f.rows
  local held = { rows.font, rows.texture, rows.outline, rows.panel, rows.fonts }
  b.O.SkinPicker(b.spec)         -- a repeat call while up must not leak a second set
  f.close:__fire("OnClick")
  assertNil(f.rows, "nothing held")
  for _, w in ipairs(held) do assertFalse(w.frame:IsShown(), "released and hidden") end
  assertEqual(#b.ace.__pools.Ka0sMedia_Font, 1, "one font row back in the pool, not two")
  assertFalse(f.reset.font:IsShown() and f:IsShown())
  local again = open(b)
  assertTrue(again.rows.font ~= nil, "the next showing acquires again")
end)

-- ── an open pull-out ─────────────────────────────────────────────────────────────────────────

--- `dd`'s pull-out opened as its bar's click opens it: AceGUI marks the widget focused.
local function openPullout(b, dd)
  dd.pullout:Open()
  b.ace.FocusedWidget = dd
end

local function assertClosed(b, dd)
  assertFalse(dd.open == true, "the widget knows it closed")
  assertFalse(dd.pullout.frame:IsShown(), "no pull-out left on screen")
  assertNil(b.ace.FocusedWidget)
end

test("skin picker rows: a reset closes the open pull-out before its list is rebuilt", function()
  -- red under: raw buttons, which AceGUI's click-to-clear never reaches: SetList emptied the open
  -- pull-out and only Pullout:Open anchors and shows new items, so it stayed up as an empty box.
  local b = bench()
  b.Skin:SetOverride(OWNER, FIRA, "Smooth")
  local f = open(b)
  openPullout(b, f.rows.font)
  f.reset.font:__fire("OnClick")
  assertClosed(b, f.rows.font)
  openPullout(b, f.rows.texture)
  f.reset.texture:__fire("OnClick")
  assertClosed(b, f.rows.texture)
end)

test("skin picker rows: a skin pick, the skin dropdown and the window's body close an open pull-out", function()
  local b = bench()
  local f = open(b)
  openPullout(b, f.rows.font)
  f.dd:__fire("OnClick")
  assertClosed(b, f.rows.font)
  f.dd:__fire("OnClick")
  openPullout(b, f.rows.texture)
  for _, r in ipairs({ f.list:GetChildren() }) do
    if r.key == "obsidian" then r:__fire("OnClick") end
  end
  assertClosed(b, f.rows.texture)
  openPullout(b, f.rows.outline)
  f:__fire("OnMouseDown", "LeftButton")
  assertClosed(b, f.rows.outline)
end)

test("skin picker rows: the eye and a refused Apply close an open pull-out too", function()
  local b = bench({ spec = { onPreview = function() end } })
  local f = open(b)
  openPullout(b, f.rows.font)
  f.preview:__fire("OnClick")
  assertClosed(b, f.rows.font)
  b.m.InCombatLockdown = function() return true end
  openPullout(b, f.rows.font)
  f.apply:__fire("OnClick")
  assertClosed(b, f.rows.font)
end)

test("skin picker rows: a change of looks from elsewhere closes an open pull-out", function()
  local b = bench()
  local f = open(b)
  openPullout(b, f.rows.font)
  b.Skin:SetOutline(OWNER, "off")
  assertClosed(b, f.rows.font)
end)

test("skin picker rows: another addon's focused dropdown is not the picker's to close", function()
  local b = bench()
  local f = open(b)
  local cleared = false
  local theirs = { ClearFocus = function() cleared = true end }
  b.ace.FocusedWidget = theirs
  f:__fire("OnMouseDown", "LeftButton")
  assertFalse(cleared)
  assertEqual(b.ace.FocusedWidget, theirs)
  b.ace.FocusedWidget = nil
end)

-- ── the end of combat ────────────────────────────────────────────────────────────────────────

test("skin picker rows: a row disabled in combat wakes when combat ends", function()
  -- red under: syncControls read the lock only when something called refresh.
  local b = bench()
  b.Skin:SetOverride(OWNER, FIRA, false)
  local f = open(b)
  b.m.InCombatLockdown = function() return true end
  f.rows.panel:__fire("OnValueChanged", true)
  assertTrue(f.rows.font.disabled, "the refused row's refresh drew them locked")
  assertTrue(f.rows.fonts.disabled)
  assertFalse(f.reset.font:IsEnabled())
  assertTrue(f:GetScript("OnUpdate") ~= nil, "rows drawn locked: watching")
  b.m.InCombatLockdown = function() return false end
  b.lib.__combatLocked = true    -- the page lock's flag clears in another frame's handler, maybe after
  f:__fire("OnUpdate", WAKE)
  assertTrue(f.rows.font.disabled, "the page lock's flag still up: the rows wait for it")
  assertTrue(f:GetScript("OnUpdate") ~= nil, "and the watch goes on")
  b.lib.__combatLocked = false
  f:__fire("OnUpdate", WAKE)
  assertFalse(f.rows.font.disabled)
  assertFalse(f.rows.texture.disabled)
  assertFalse(f.rows.outline.disabled)
  assertFalse(f.rows.panel.disabled)
  assertFalse(f.rows.fonts.disabled)
  assertTrue(f.reset.font:IsEnabled())
  assertNil(f:GetScript("OnUpdate"), "the watch removed itself")
end)

test("skin picker rows: a window shown in combat wakes when combat ends", function()
  local b = bench()
  b.m.InCombatLockdown = function() return true end
  local f = open(b)
  assertTrue(f.rows.font.disabled)
  b.m.InCombatLockdown = function() return false end
  f:__fire("OnUpdate", WAKE)
  assertFalse(f.rows.font.disabled)
  assertNil(f:GetScript("OnUpdate"))
end)

test("skin picker rows: the watch is throttled and redraws once", function()
  local b = bench()
  b.m.InCombatLockdown = function() return true end
  local f = open(b)
  b.m.InCombatLockdown = function() return false end
  f:__fire("OnUpdate", WAKE / 100)
  assertTrue(f.rows.font.disabled, "a frame short of the throttle reads nothing")
  local redraws, set = 0, f.rows.outline.SetValue
  f.rows.outline.SetValue = function(...)
    redraws = redraws + 1
    return set(...)
  end
  f:__fire("OnUpdate", WAKE)
  assertEqual(redraws, 1)
  assertNil(f:GetScript("OnUpdate"))
  f:__fire("OnUpdate", WAKE)
  assertEqual(redraws, 1, "gone means gone")
  f.rows.outline.SetValue = set
end)

test("skin picker rows: rows never drawn locked run no watch and an open pull-out stays", function()
  local b = bench()
  local f = open(b)
  openPullout(b, f.rows.font)
  assertNil(f:GetScript("OnUpdate"))
  assertTrue(f.rows.font.open, "nothing was locked, so nothing moved under the open list")
  b.ace:ClearFocus()
end)

test("skin picker rows: closing a window drawn locked leaves it no watch", function()
  local b = bench()
  b.m.InCombatLockdown = function() return true end
  local f = open(b)
  assertTrue(armed(b, f), "the kit counts the watch, so the two below can fail")
  f.close:__fire("OnClick")
  assertNil(f:GetScript("OnUpdate"))
  assertFalse(armed(b, f), "the kit's live timers hold no frame of the picker")
  assertNil(f.rows)
end)

test("skin picker rows: standing down a window drawn locked leaves it no watch", function()
  local b = bench()
  b.m.InCombatLockdown = function() return true end
  local f = open(b)
  b.O.HideSkinPicker()
  assertFalse(f:IsShown())
  assertNil(f:GetScript("OnUpdate"))
  assertFalse(armed(b, f), "the kit's live timers hold no frame of the picker")
end)

test("skin picker rows: a shown picker registers no event at all, in or out of combat", function()
  -- red under: the window held PLAYER_REGEN_ENABLED for a showing, and a re-vendor turned seven
  -- addons' stand-down suites red: slash-commands-§7 wants a disabled addon's registrations exact.
  local b = bench()
  local before = #b.m.__registrations()
  local f = open(b)
  assertEqual(#b.m.__registrations(), before, "out of combat")
  assertNil(next(f.__frameEvents))
  f.close:__fire("OnClick")
  b.m.InCombatLockdown = function() return true end
  open(b)
  assertEqual(#b.m.__registrations(), before, "in combat")
  assertNil(next(f.__frameEvents))
end)

-- ── the geometry and the heading ─────────────────────────────────────────────────────────────

test("skin picker rows: a reset icon's foot is its bar's, AceGUI's labeled height", function()
  -- red under: 44, what OnAcquire sets and SetLabel overwrites with 40: the icon hung 4 below the bar.
  local b = bench()
  armWidgets(b)
  local f = open(b)
  for _, which in ipairs({ "font", "texture" }) do
    local pts = rawget(f.reset[which], "__pts")
    assertEqual(-pts[1][5] - topOf(f.rows[which]), 40, which)
  end
end)

test("skin picker rows: the media rows sit under the Skin tab's heading", function()
  local b = bench()
  armWidgets(b)
  local f = open(b)
  local pts = {}
  rawset(f.mediaLabel, "SetPoint", function(_, ...) pts[#pts + 1] = { ... } end)
  open(b)                        -- a font string records no anchor: spy, then a repeat show draws again
  assertEqual(f.mediaLabel:GetText(), "Font and texture")
  assertTrue(f.mediaLabel:IsShown())
  assertTrue(-pts[#pts][5] < topOf(f.rows.font), "above the Font row")
  f.close:__fire("OnClick")
  assertFalse(f.mediaLabel:IsShown())
end)

test("skin picker rows: no Skin:SetOverride draws no heading for rows it did not draw", function()
  local b = bench()
  b.Skin.SetOverride = nil
  local f = open(b)
  assertFalse(f.mediaLabel:IsShown())
end)

-- ── a Skin-tab write while the picker is up ──────────────────────────────────────────────────

--- The Skin tab of the bench's owner, drawn while the picker may be up, over the owner's store.
local function tabOf(b)
  local ctx = b.O.CreatePanel("PickerTab", "Picker tab", { pageKey = "general" })
  return b.O.AppearanceRows(ctx, b.spec)
end

test("skin picker rows: a tab write stores no font the picker only previewed", function()
  -- red under: the tab's write read the applied state, the preview with it, and the dismissal's guard
  -- could not see that it was stored: font X at the next /reload with no Apply ever pressed.
  local b = bench()
  local view = tabOf(b)
  local f = open(b)
  f.rows.font:__fire("OnValueChanged", FIRA)
  view.outline:__fire("OnValueChanged", "off")
  assertEqual(lastMedia(b.store).font, false, "the store keeps the font it had")
  assertEqual(lastMedia(b.store).outline, "off")
  assertNil((b.Skin:GetOverride(OWNER)), "and the applied state agrees")
  assertEqual(f.rows.font.value, "@skin", "the picker shows it")
  f.close:__fire("OnClick")
  assertNil((b.Skin:GetOverride(OWNER)))
  assertEqual(b.Skin:GetOutline(OWNER), "off", "the tab's write stays")
end)

test("skin picker rows: a tab write stores no outline the picker only previewed", function()
  local b = bench()
  local view = tabOf(b)
  local f = open(b)
  f.rows.outline:__fire("OnValueChanged", "off")
  view.media.texture:__fire("OnValueChanged", "Smooth")
  assertNil(lastMedia(b.store).outline, "never stored, and still not")
  assertEqual(lastMedia(b.store).texture, "Smooth")
  assertEqual(b.Skin:GetOutline(OWNER), "hud")
  f.close:__fire("OnClick")
  assertEqual(select(2, b.Skin:GetOverride(OWNER)), "Smooth")
end)

test("skin picker rows: a tab scope flip stores no half the picker only previewed", function()
  -- red under: the tab handing setScope the half it did not flip, read while the preview was live.
  local b = bench()
  local view = tabOf(b)
  local f = open(b)
  f.rows.panel:__fire("OnValueChanged", true)
  view.ignore.fonts:__fire("OnValueChanged", true)
  local ig = lastIgnore(b.store)
  assertFalse(ig.panel)
  assertTrue(ig.fonts)
  f.close:__fire("OnClick")
  local panel, fonts = b.Skin:GetIgnore(OWNER)
  assertFalse(panel)
  assertTrue(fonts)
end)

test("skin picker rows: a tab write stores no override a pending skin pick cleared", function()
  local b = bench()
  b.Skin:SetOverride(OWNER, FIRA, false)
  local view = tabOf(b)
  local f = open(b)
  pickSkin(f, "obsidian")
  assertNil((b.Skin:GetOverride(OWNER)))
  view.outline:__fire("OnValueChanged", "off")
  assertEqual(lastMedia(b.store).font, FIRA, "the store keeps it; the pick was never applied")
  assertEqual(b.store.skin, "ka0s")
  assertEqual((b.Skin:GetOverride(OWNER)), FIRA)
end)

test("skin picker rows: a tab write moves what the picker measures from", function()
  -- red under: stale opened* baselines: back to the opened mode cleared the record, and Apply wrote
  -- nothing while the store kept the tab's.
  local b = bench()
  local view = tabOf(b)
  local f = open(b)
  view.outline:__fire("OnValueChanged", "all")
  assertEqual(f.rows.outline.value, "all", "the picker follows the tab")
  f.rows.outline:__fire("OnValueChanged", "hud")
  f.apply:__fire("OnClick")
  assertEqual(lastMedia(b.store).outline, "hud", "Apply stores what the row shows")
end)

test("skin picker rows: a dismissal after a tab write puts back the tab's, not the opened", function()
  local b = bench()
  local view = tabOf(b)
  local f = open(b)
  view.media.font:__fire("OnValueChanged", FIRA)
  f.rows.font:__fire("OnValueChanged", "Ka0s Prototype")
  f.close:__fire("OnClick")
  assertEqual((b.Skin:GetOverride(OWNER)), FIRA)
end)

test("skin picker rows: the tab's copy carries no preview to the other owners", function()
  local b = bench()
  Bench.register(b.Skin, OTHER)
  local view = tabOf(b)
  local f = open(b)
  f.rows.font:__fire("OnValueChanged", FIRA)
  b.m.StaticPopup_Show = function(_, _, _, data) data() end
  view.copy:__fire("OnClick")
  assertNil((b.Skin:GetOverride(OTHER)))
end)

test("skin picker rows: Apply saves the scope applied now, not the one the row last previewed", function()
  -- red under: saveRows sending scopeLeft while the row, and the addon, read another pair.
  local b = bench()
  local f = open(b)
  f.rows.fonts:__fire("OnValueChanged", true)
  b.Skin:SetIgnore(OWNER, true, false)
  f.apply:__fire("OnClick")
  local ig = lastIgnore(b.store)
  assertTrue(ig.panel)
  assertFalse(ig.fonts)
end)

-- ── the skin ─────────────────────────────────────────────────────────────────────────────────

test("skin picker rows: the rows are painted, repaint on a skin pick, and wear the skin under Ignore settings panel", function()
  -- red under: Skin:PaintAce alone, which refuses while the settings panel is ignored; the picker is a
  -- window, not a settings page, and the tooltip of that very box says windows still wear the skin.
  local b = bench()
  b.Skin:SetIgnore(OWNER, true, nil)
  local f = open(b)
  local st = b.Skin.__ace[f.rows.outline]
  assertEqual(st and st.owner, OWNER, "painted though the settings panel is ignored")
  local painted = 0
  local real = b.Skin.__acePaint.Dropdown
  b.Skin.__acePaint.Dropdown = function(...)
    painted = painted + 1
    return real(...)
  end
  pickSkin(f, "obsidian")
  assertTrue(painted > 0, "a skin pick repaints them")
  b.Skin.__acePaint.Dropdown = real
  f.close:__fire("OnClick")
end)

test("skin picker rows: a released row goes back to the pool under the panel's ordinary rule", function()
  -- red under: a window mark that outlived the release and skinned a settings row the scope ignores.
  local b = bench()
  b.Skin:SetIgnore(OWNER, true, nil)
  local f = open(b)
  local w = f.rows.outline
  f.close:__fire("OnClick")
  assertFalse(b.Skin:PaintAce(OWNER, w), "an ignored panel's row stays stock")
end)

-- ── the fonts ────────────────────────────────────────────────────────────────────────────────

test("skin picker rows: show loads the skins' faces and the override's, and the pull-out loads every face", function()
  -- red under: Ka0sMedia_Font's acquire preload, which loads every LSM face for a player who only
  -- wanted to pick a skin (OptionsSkinPicker's A ROW'S NAME NEVER STAYS BLANK).
  local b = bench()
  local lsm = b.m.LibStub("LibSharedMedia-3.0", true)
  local preload = b.lib.__PreloadFonts
  local handed = 0
  b.lib.__PreloadFonts = function(table_)
    if table_ == lsm then handed = handed + 1 end
    return preload(table_)
  end
  b.Skin:SetOverride(OWNER, FIRA, false)
  local f = open(b)
  assertEqual(handed, 0, "LSM's whole font table is not walked at show")
  local paths = b.lib.__fontPreload.paths
  assertTrue(paths[Fixture.FACE[FIRA]], "the override's face, which the closed row wears")
  f.rows.font.pullout:Open()
  assertTrue(handed > 0, "the pull-out asks for every face")
end)

test("skin picker rows: a lazy acquire leaves the next picker's preload as it was", function()
  local b = bench()
  open(b)
  assertFalse(b.lib.__mediaLazy == true, "the flag is down after the rows are made")
end)

-- ── degraded ─────────────────────────────────────────────────────────────────────────────────

test("skin picker rows: with no write seam the picker offers nothing it could not save", function()
  local b = bench({ spec = { set = false } })
  b.spec.set = nil
  local f = open(b)
  assertNil(f.rows)
  assertFalse(f.reset.font:IsShown())
  assertTrue(f:IsShown())
end)

test("skin picker rows: without LibSharedMedia a media row offers the skin's own entry alone", function()
  local b = bench({ noLsm = true })
  local f = open(b)
  assertEqual(#f.rows.font.pullout.items, 1)
  assertEqual(f.rows.font.value, "@skin")
end)

test("skin picker rows: without the stock Dropdown the media rows are plain Dropdowns", function()
  local b = bench({ noBase = true })
  local f = open(b)
  assertEqual(f.rows.font.type, "Dropdown")
  assertEqual(f.rows.font.value, "@skin")
end)

test("skin picker rows: the EllesmereUI source keeps the rows, as the Skin tab does", function()
  local b = bench()
  b.store.source = "eui"
  local f = open(b)
  assertTrue(f.rows.font ~= nil)
  assertFalse(f.rows.font.disabled)
end)

test("skin picker rows: a Skin major without the seams draws the window as before", function()
  local b = bench()
  b.Skin.SetOverride, b.Skin.SetOutline, b.Skin.SetIgnore = nil, nil, nil
  local f = open(b)
  assertNil(f.rows)
  assertFalse(f.scopeLabel:IsShown())
end)
