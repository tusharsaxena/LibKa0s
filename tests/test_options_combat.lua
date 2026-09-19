-- tests/test_options_combat.lua — LibKa0s-Options-1.0's combat lock (Options minor 22,
-- OptionsWidgets minor 23, OptionsTabs minor 2): options-ui-§2 and §13 as of the Ka0s WoW Addon
-- Standard v2.60.0, and anti-pattern #88.
--
-- Its own suite, for the reason test_options_switched.lua is one: tests/test_options_widgets.lua is
-- over the layout-§1 cap (issue #33), and the lock is one feature that crosses three files.
--
-- What the lock replaced: through Options minor 21, a page shown in combat closed Blizzard's
-- settings window from its own OnShow. The AddOns sidebar reaches that OnShow from inside
-- Blizzard's own DisplayCategory -> DisplayLayout -> Show, so the close ran from addon code and
-- Blizzard's close-and-commit path ran tainted (SaveBindings blocked, then ToggleGameMenu
-- re-entering until C stack overflow). And a page left open in combat still accepted writes. Every
-- case here runs under a SettingsPanel recorder that fails the case if the library so much as reads
-- a field of the window while the player is in combat.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local mocks = T.mocks
local Fixture = dofile("tests/fixture_options.lua")

local lib = T.options

-- ── harness ──────────────────────────────────────────────────────────────────────────────────

local function inCombat()
  return (mocks.InCombatLockdown() or lib.__combatLocked == true) and true or false
end

--- A stand-in for Blizzard's settings window that records every touch made during combat — a field
--- read, a method call, a write — and raises on a call, so the case fails whether or not the caller
--- sat inside a pcall. The same for the three globals that close or re-open it.
local function installRecorder(violations)
  local function note(what) violations[#violations + 1] = what end
  local proxy = setmetatable({}, {
    __index = function(_, k)
      if inCombat() then note("read SettingsPanel." .. tostring(k)) end
      return function()
        if inCombat() then
          note("call SettingsPanel:" .. tostring(k) .. "()")
          error("SettingsPanel:" .. tostring(k) .. "() called in combat", 2)
        end
      end
    end,
    __newindex = function(t, k, v)
      if inCombat() then note("write SettingsPanel." .. tostring(k)) end
      rawset(t, k, v)
    end,
  })
  local function guarded(name)
    return function()
      if inCombat() then
        note(name .. "()")
        error(name .. "() called in combat", 2)
      end
    end
  end
  mocks.SettingsPanel = proxy
  mocks.HideUIPanel = guarded("HideUIPanel")
  mocks.ToggleGameMenu = guarded("ToggleGameMenu")
  mocks.Settings.OpenToCategory = guarded("Settings.OpenToCategory")
end

local function fire(event)
  local f = lib.__combatFrame
  assertTrue(f ~= nil, "the library owns one combat event frame")
  f:__fire("OnEvent", event)
end

local function enterCombat()
  fire("PLAYER_REGEN_DISABLED")           -- the client fires it before lockdown begins
  mocks.InCombatLockdown = function() return true end
end

local function leaveCombat()
  mocks.InCombatLockdown = function() return false end
  fire("PLAYER_REGEN_ENABLED")            -- and this one after lockdown has ended
end

--- One case under the recorder, with the library's process-lived combat state put back however the
--- case ends, so no case can hand the next one a locked library.
local function combatCase(name, fn)
  test(name, function()
    local saved = {
      panel = mocks.SettingsPanel, hide = mocks.HideUIPanel, toggle = mocks.ToggleGameMenu,
      open = mocks.Settings.OpenToCategory, combat = mocks.InCombatLockdown,
    }
    local violations = {}
    installRecorder(violations)
    local ok, err = pcall(fn)
    mocks.InCombatLockdown = function() return false end
    lib.__combatLocked = false
    mocks.SettingsPanel, mocks.HideUIPanel, mocks.ToggleGameMenu = saved.panel, saved.hide, saved.toggle
    mocks.Settings.OpenToCategory, mocks.InCombatLockdown = saved.open, saved.combat
    if not ok then error(err, 0) end
    assertEqual(#violations, 0,
      "Blizzard's settings window was touched in combat: " .. table.concat(violations, "; "))
  end)
end

--- A frame-level model over the kit's CreateFrame. The kit's frames answer GetFrameLevel with the
--- frame itself (fidelity rule 2 keeps unasked geometry inert), so a case about what draws over
--- what builds its frames through this: a child is one level above its parent, SetFrameLevel sticks,
--- GetChildren lists the frames built under it, and the mouse/keyboard switches are recorded.
local function withLevels(fn)
  local saved = mocks.CreateFrame
  mocks.CreateFrame = function(frameType, name, parent, template)
    local f = saved(frameType, name, parent, template)
    local base = (type(parent) == "table" and rawget(parent, "__level")) or 0
    f.__level, f.__kids = base + 1, {}
    function f:GetFrameLevel() return self.__level end
    function f:SetFrameLevel(n) self.__level = n end
    function f:GetChildren() return unpack(self.__kids) end
    function f:EnableMouse(v) self.__mouse = v end
    function f:EnableMouseWheel(v) self.__wheel = v end
    function f:SetPropagateKeyboardInput(v) self.__propagates = v end
    if type(parent) == "table" and rawget(parent, "__kids") then
      parent.__kids[#parent.__kids + 1] = f
    end
    return f
  end
  local ok, err = pcall(fn)
  mocks.CreateFrame = saved
  if not ok then error(err, 0) end
end

local seq = 0

--- A host, one page on it drawn by `render`, and a counter of how often it drew.
local function host(pageKey, tabbed)
  local O, rec = Fixture.new()
  seq = seq + 1
  local ctx = O.CreatePanel("CombatPage" .. seq, "Combat " .. seq, { pageKey = pageKey,
    defaultsButton = true })
  rec.drawn = 0
  O.SetRenderer(ctx, function(c)
    rec.drawn = rec.drawn + 1
    O.ClearScroll(c)
    if tabbed then O.RenderTabbedSchema(c, pageKey) else O.RenderSchema(c, pageKey) end
  end)
  return O, rec, ctx
end

local function show(ctx)
  ctx.panel:Show()
  ctx.panel:__fire("OnShow")
end

local function widget(ctx, label)
  for _, w in ipairs(Fixture.flatten(ctx.scroll)) do
    if w.labelText == label then return w end
  end
end

local function tabButton(ctx, label)
  for _, b in ipairs(ctx.__tabKids or {}) do
    if b.__ka0sTabTipLabel == label then return b end
  end
end

local function coverShown(ctx)
  local cover = ctx.__combatCover
  return cover ~= nil and cover:IsShown() == true
end

-- ── the cover ────────────────────────────────────────────────────────────────────────────────

combatCase("combat: a page shown in combat is covered and not drawn, and the window is left alone",
  function()
  -- red under: Options minor 21, whose OnShow read SettingsPanel.Close and called it.
  local _, rec, ctx = host("general")
  enterCombat()
  show(ctx)
  assertEqual(rec.drawn, 0, "the body is not drawn under lockdown")
  assertTrue(coverShown(ctx), "the cover is up")
  assertEqual(ctx.__combatCover.__text, lib.STRINGS.COMBAT_LOCKED)
  assertEqual(lib.STRINGS.COMBAT_LOCKED, "Settings are locked during combat.")
  assertTrue(ctx._dirty == true, "an unrendered page is marked dirty for the end of combat")
  assertEqual(#rec.chat, 1, "one gray notice")
  assertTrue(rec.chat[1]:find("|cffaaaaaa", 1, true) == 1, "and it is gray: " .. rec.chat[1])

  ctx.panel:Hide(); show(ctx)
  assertEqual(#rec.chat, 1, "a second show in the same combat prints nothing more")
end)

combatCase("combat: the cover is built out of combat, hidden, and takes the mouse and the wheel",
  function()
  withLevels(function()
    local _, _, ctx = host("general")
    local cover = ctx.__combatCover
    assertTrue(cover ~= nil, "built at CreatePanel, before any combat")
    assertEqual(cover.__parent, ctx.panel, "parented to the page's own canvas")
    assertFalse(cover:IsShown(), "and hidden until combat")
    assertTrue(cover.__mouse == true, "it takes clicks")
    assertTrue(cover.__wheel == true, "and the mouse wheel")
    assertTrue(cover.__propagates == nil, "and never touches keyboard propagation")
    assertTrue(cover.__frameType == "Frame" and cover.__template == nil,
      "a plain frame: no secure template")
  end)
end)

combatCase("combat: REGEN_DISABLED covers an open tabbed page above its tab strip", function()
  -- options-ui-§2: the cover falls over the WHOLE page, header band and tab strip included.
  -- red under: a cover left at its parent's level + 1, which the tab buttons (body + 1 + 1, then
  -- raised one more by newTabButton) draw over.
  withLevels(function()
    local _, rec, ctx = host("tabbed", true)
    show(ctx)
    assertEqual(rec.drawn, 1)
    assertFalse(coverShown(ctx), "no cover out of combat")

    enterCombat()
    assertTrue(coverShown(ctx), "the open page is covered the moment combat starts")
    local cover = ctx.__combatCover:GetFrameLevel()
    local tabs = 0
    for _, b in ipairs(ctx.__tabKids) do
      tabs = tabs + 1
      assertTrue(cover > b:GetFrameLevel(),
        ("cover level %d is above the strip's %d"):format(cover, b:GetFrameLevel()))
    end
    assertTrue(tabs > 0, "the strip was drawn")
    assertTrue(cover > ctx.chrome:GetFrameLevel() and cover > ctx.body:GetFrameLevel(),
      "and above the chrome band and the body")
    assertEqual(#rec.chat, 0, "covering an open page prints nothing")
  end)
end)

-- ── refused writes ───────────────────────────────────────────────────────────────────────────

combatCase("combat: a widget write is refused and the widget put back", function()
  local _, rec, ctx = host("general")
  show(ctx)
  local cb = widget(ctx, "Lock Position")
  assertTrue(cb ~= nil)
  enterCombat()
  cb:SetValue(true)                               -- what the click did to the widget
  cb:__fire("OnValueChanged", true)
  assertEqual(rec.store.locked, false, "nothing reached the host's write seam")
  assertEqual(cb.value, false, "and the widget reads the stored value again")
  assertEqual(#rec.chat, 1, "one notice")
  widget(ctx, "Show tooltips"):__fire("OnValueChanged", false)
  assertEqual(rec.store.showTooltips, true)
  assertEqual(#rec.chat, 1, "still one notice in this combat")
end)

combatCase("combat: the notice comes back once per combat, not once per session", function()
  local _, rec, ctx = host("general")
  show(ctx)
  enterCombat()
  widget(ctx, "Lock Position"):__fire("OnValueChanged", true)
  leaveCombat()
  enterCombat()
  widget(ctx, "Lock Position"):__fire("OnValueChanged", true)
  assertEqual(#rec.chat, 2, "a new combat, a new notice")
end)

combatCase("combat: the page's Defaults — header button and footer control — are refused",
  function()
  local O, rec, ctx = host("general")
  local pressed = 0
  ctx.panel.defaultsOnClick = function()
    pressed = pressed + 1
    O.RestoreDefaults("general", ctx)
  end
  show(ctx)
  rec.store.locked = true
  enterCombat()
  ctx.panel.defaultsBtn:__fire("OnClick")
  ctx.panel.OnDefault()
  O.RestoreDefaults("general", ctx)
  assertEqual(pressed, 0, "neither control reached the host's handler")
  assertEqual(rec.store.locked, true, "and nothing was reset")
end)

combatCase("combat: a library button's click is refused", function()
  local O, _, ctx = host("general")
  show(ctx)
  local clicks = 0
  O.InlineButtonPair(ctx, { text = "Reset all settings", onClick = function() clicks = clicks + 1 end })
  local btn = widget(ctx, nil)
  for _, w in ipairs(Fixture.flatten(ctx.scroll)) do
    if w.type == "Button" and w.text == "Reset all settings" then btn = w end
  end
  enterCombat()
  btn:__fire("OnClick")
  assertEqual(clicks, 0)
  leaveCombat()
  btn:__fire("OnClick")
  assertEqual(clicks, 1, "and works again once combat ends")
end)

combatCase("combat: a session checkbox is refused and put back", function()
  local O, _, ctx = host("general")
  show(ctx)
  local on, sets = false, 0
  local cb = O.SessionCheckbox(ctx, nil, 0.5, {
    label = "Debug console", get = function() return on end,
    set = function(v) on = v; sets = sets + 1 end,
  })
  enterCombat()
  cb:SetValue(true)
  cb:__fire("OnValueChanged", true)
  assertEqual(sets, 0)
  assertEqual(cb.value, false, "the box reads the live state again")
end)

combatCase("combat: a color commit is refused and the swatch put back", function()
  local _, rec, ctx = host("bar")
  show(ctx)
  local cp = widget(ctx, "Bar Color")
  assertTrue(cp ~= nil)
  enterCombat()
  cp:__fire("OnValueConfirmed", 0.1, 0.2, 0.3, 1)
  assertEqual(rec.store.barColor.r, 1, "nothing reached the host")
  assertEqual(cp.color.r, 1, "and the swatch shows the stored color again")
end)

combatCase("combat: a page banner's selection is refused and the dropdown put back", function()
  local O, _, ctx = host("general")
  show(ctx)
  local picked = 0
  local dd = O.PageBanner(ctx, { label = "Unit", list = { a = "A", b = "B" }, value = "a",
    onSelect = function() picked = picked + 1 end })
  enterCombat()
  dd:SetValue("b")
  dd:__fire("OnValueChanged", "b")
  assertEqual(picked, 0)
  assertEqual(dd.value, "a")
end)

combatCase("combat: a tab click is refused and the page stays on its tab", function()
  -- options-ui-§13 as of v2.60.0: the lock covers the strip, and the LIBRARY refuses the switch.
  local _, rec, ctx = host("tabbed", true)
  show(ctx)
  local before = ctx.activeTab
  local beta = tabButton(ctx, "Beta")
  assertTrue(beta ~= nil and before ~= "Beta")
  enterCombat()
  beta:__fire("OnClick")
  assertEqual(ctx.activeTab, before, "the tab did not move")
  assertEqual(rec.drawn, 1, "and nothing re-rendered")
  assertEqual(#rec.chat, 1, "the refusal is noticed once")
end)

combatCase("combat: SelectTab refuses in combat", function()
  local O, rec, ctx = host("tabbed", true)
  show(ctx)
  local before = ctx.activeTab
  enterCombat()
  assertFalse(O.SelectTab("tabbed", "Beta"), "no tab was set")
  assertEqual(ctx.activeTab, before)
  assertEqual(rec.drawn, 1)
end)

combatCase("combat: a structural refresh in combat waits; the page renders when combat ends",
  function()
  local O, rec, ctx = host("general")
  show(ctx)
  enterCombat()
  O.RefreshAllPanels()
  O.RefreshPanel(ctx, true)
  assertEqual(rec.drawn, 1, "no re-render under lockdown")
  assertTrue(ctx._dirty == true, "the page is owed one")
  leaveCombat()
  assertEqual(rec.drawn, 2, "and gets exactly one when combat ends")
  assertFalse(coverShown(ctx), "with the cover lifted")
end)

-- ── the end of combat ────────────────────────────────────────────────────────────────────────

combatCase("combat: a page first shown in combat renders when combat ends, and is never re-opened",
  function()
  local _, rec, ctx = host("general")
  enterCombat()
  show(ctx)
  leaveCombat()
  assertEqual(rec.drawn, 1, "drawn from current state")
  assertFalse(coverShown(ctx))
  assertTrue(ctx.panel.defaultsBtn ~= nil, "its Defaults button is there")
end)

combatCase("combat: a clean open page runs its refreshers when combat ends, not its renderer",
  function()
  -- A slash `set` or a profile switch during combat changes values, not the page's shape.
  local _, rec, ctx = host("general")
  show(ctx)
  enterCombat()
  rec.store.locked = true                          -- a /<slash> set during the fight
  leaveCombat()
  assertEqual(rec.drawn, 1, "no rebuild")
  assertEqual(widget(ctx, "Lock Position").value, true, "the widget shows the new value")
end)

combatCase("combat: a hidden page is left for its next show", function()
  local _, rec, ctx = host("general")
  show(ctx)
  ctx.panel:Hide()
  enterCombat()
  leaveCombat()
  assertEqual(rec.drawn, 1, "a hidden page is not rendered at the end of combat")
  assertFalse(coverShown(ctx), "and its cover is down, so its next show is not covered")
end)

combatCase("combat: REGEN_DISABLED closes the library's own dropdown pullout on an open page",
  function()
  local O, _, ctx = host("general")
  show(ctx)
  local AceGUI = O.AceGUI
  local cleared = 0
  local frame = mocks.CreateFrame("Frame", nil, ctx.panel)
  rawset(frame, "GetParent", function() return ctx.panel end)
  AceGUI.FocusedWidget = { frame = frame, ClearFocus = function() end }
  AceGUI.ClearFocus = function(self) cleared = cleared + 1; self.FocusedWidget = nil end
  local ok, err = pcall(enterCombat)
  AceGUI.ClearFocus, AceGUI.FocusedWidget = nil, nil
  if not ok then error(err, 0) end
  assertEqual(cleared, 1, "the pullout on this page was closed")
end)

combatCase("combat: another addon's focused widget is left alone", function()
  local O, _, ctx = host("general")
  show(ctx)
  local AceGUI = O.AceGUI
  local cleared = 0
  local frame = mocks.CreateFrame("Frame", nil, mocks.UIParent)
  rawset(frame, "GetParent", function() return mocks.UIParent end)
  AceGUI.FocusedWidget = { frame = frame, ClearFocus = function() end }
  AceGUI.ClearFocus = function() cleared = cleared + 1 end
  local ok, err = pcall(enterCombat)
  AceGUI.ClearFocus, AceGUI.FocusedWidget = nil, nil
  if not ok then error(err, 0) end
  assertEqual(cleared, 0)
end)

-- ── out of combat ────────────────────────────────────────────────────────────────────────────

combatCase("combat: out of combat nothing changes", function()
  local O, rec, ctx = host("tabbed", true)
  show(ctx)
  assertEqual(rec.drawn, 1)
  assertFalse(coverShown(ctx))
  widget(ctx, "Alpha one"):__fire("OnValueChanged", true)
  assertEqual(rec.store.tabAlpha, true, "a write lands")
  tabButton(ctx, "Beta"):__fire("OnClick")
  assertEqual(ctx.activeTab, "Beta", "a tab click switches")
  assertTrue(O.SelectTab("tabbed", "Gamma"))
  assertEqual(#rec.chat, 0, "and nothing is printed")
end)

-- ── the event frame ──────────────────────────────────────────────────────────────────────────

combatCase("combat: one event frame for the library, dispatching through lib at call time",
  function()
  -- Every vendored copy in the session is handed the same `lib`. The frame is created once and
  -- kept across a LibStub upgrade, and its handler looks the dispatcher up on `lib` when the event
  -- arrives, so the newest copy's code is what runs.
  local f = lib.__combatFrame
  assertTrue(f:IsEventRegistered("PLAYER_REGEN_DISABLED"))
  assertTrue(f:IsEventRegistered("PLAYER_REGEN_ENABLED"))
  local saved, seen = lib.__OnCombatEvent, {}
  lib.__OnCombatEvent = function(event) seen[#seen + 1] = event end
  local ok, err = pcall(f.__fire, f, "OnEvent", "PLAYER_REGEN_DISABLED")
  lib.__OnCombatEvent = saved
  if not ok then error(err, 0) end
  assertEqual(seen[1], "PLAYER_REGEN_DISABLED")
  assertFalse(lib.__IsCombatLocked(), "the replaced dispatcher, not the old one, handled it")
end)

combatCase("combat: the lock predicate is the flag or the client's lockdown", function()
  assertFalse(lib.__IsCombatLocked())
  lib.__combatLocked = true
  assertTrue(lib.__IsCombatLocked(), "REGEN_DISABLED's flag")
  lib.__combatLocked = false
  mocks.InCombatLockdown = function() return true end
  assertTrue(lib.__IsCombatLocked(), "or InCombatLockdown(), for a page shown after a /reload in combat")
end)
