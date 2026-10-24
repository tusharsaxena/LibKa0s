-- tests/test_options_keybinds.lua -- LibKa0s-Options-1.0's Keybindings tab (OptionsKeybinds.lua
-- minor 2, one key button per row from minor 4, options-ui-§20): O.KeybindingsTab, O.KeybindRows and
-- O.KEYBINDS_UNCHANGED.
--
-- What it pins: the tab entry and its place (last on a tabbed page); one row per binding in the
-- host's order, labeled by the client's GetBindingName; ONE key button showing the first key or
-- NOT_BOUND, "<key> +1" and a tooltip naming every key when the game's page set a second (minor 4);
-- the capture (Escape cancels, a modifier alone keeps listening, a second click cancels, mouse
-- buttons and the wheel bind, a key bound through the button keeps the second key, a right-click
-- clears the key shown and the second moves up, Clear clears every key, one capture across every
-- row); the outcome line (KEY_UNBOUND_ERROR naming the action that lost its key, else
-- KEY_BOUND); the set line; the combat refusals and the capture stopped at combat start; pooled
-- hygiene (options-ui-§19); the page's OnHide; a page drawn disabled; the degradation row; the intro.
--
-- Every case runs on tests/fixture_keybinds.lua's bench, which fails it on any touch of Blizzard's
-- settings window. The model under the rows (lib.__keybindSet and friends) is
-- tests/test_options_keybinds_model.lua's.

local T = _G.LK_TEST
local assertEqual, assertTrue, assertFalse, assertNil =
  T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local mocks = T.mocks
local lib = T.options
local Bench = dofile("tests/fixture_keybinds.lua")
local case = Bench.case
local S = lib.KEYBIND_STRINGS

local SET_HOW = "(Options -> Keybindings -> Character Specific Keybindings)"

-- ── the version and the members ──────────────────────────────────────────────────────────────

case("keybinds tab: OptionsKeybinds is at minor 4 and attaches the three members", function()
  assertEqual(lib.MODULES.OptionsKeybinds, 4)
  assertEqual(lib.__keybindsMinor, 4)
  local O = Bench.page(function() end)
  assertEqual(type(O.KeybindingsTab), "function")
  assertEqual(type(O.KeybindRows), "function")
  assertEqual(O.KEYBINDS_UNCHANGED, "Key bindings are not changed.")
  assertEqual(O.KEYBINDS_UNCHANGED, S.UNCHANGED)
end)

-- ── the tab entry ────────────────────────────────────────────────────────────────────────────

case("keybinds tab: KeybindingsTab's defaults", function()
  local O = Bench.page(function() end)
  local tab = O.KeybindingsTab({ bindings = Bench.BINDINGS })
  assertEqual(tab.key, "Keybindings")
  assertEqual(tab.label, "Keybindings")
  assertEqual(tab.tooltip, S.TAB_TIP)
  assertNil(tab.before, "no before: the library puts it last")
  assertEqual(type(tab.render), "function")
end)

case("keybinds tab: spec.key, spec.before and spec.strings override", function()
  local O = Bench.page(function() end)
  local tab = O.KeybindingsTab({ bindings = Bench.BINDINGS, key = "Keys", before = "Beta",
    strings = { TAB_LABEL = "Tastenbelegung", TAB_TIP = "Tip" } })
  assertEqual(tab.key, "Keys")
  assertEqual(tab.label, "Tastenbelegung")
  assertEqual(tab.tooltip, "Tip")
  assertEqual(tab.before, "Beta")
  assertEqual(S.TAB_LABEL, "Keybindings", "the library's words are not written through")
end)

case("keybinds tab: RenderTabbedSchema puts it LAST, after every group tab, and its render draws rows",
function()
  local keysSeen
  local O, _, ctx = Bench.page(function(O, c)
    local _, keys = O.RenderTabbedSchema(c, "tabbed", nil, nil,
      { tabs = { O.KeybindingsTab({ bindings = Bench.BINDINGS }) } })
    keysSeen = keysSeen or keys
  end)
  assertEqual(table.concat(keysSeen, "|"), "Alpha|Beta|Gamma|Delta|Keybindings")
  local strip = {}
  for _, b in ipairs(ctx.__tabKids or {}) do
    if b.__ka0sTabTipLabel then strip[#strip + 1] = b end
  end
  local last = strip[#strip]
  assertEqual(last.__ka0sTabTipLabel, "Keybindings", "the strip's last button")
  last:__fire("OnClick")
  assertEqual(ctx.activeTab, "Keybindings")
  local labels = {}
  for _, w in ipairs(Bench.widgets(ctx)) do
    if w.type == "InteractiveLabel" then labels[#labels + 1] = w.text end
  end
  assertEqual(table.concat(labels, "|"), Bench.TOGGLE_NAME .. "|" .. Bench.SECOND)
  assertTrue(O ~= nil)
end)

-- ── the rows ─────────────────────────────────────────────────────────────────────────────────

case("keybinds tab: rows follow spec.bindings in order, labeled by GetBindingName", function()
  local _, _, _, rows = Bench.rowsPage()
  local r = rows()
  assertEqual(#r, 2)
  assertEqual(r[1].command, Bench.TOGGLE)
  assertEqual(r[2].command, Bench.SECOND)
  assertEqual(r[1].label.text, Bench.TOGGLE_NAME, "a BINDING_NAME_ global shows")
  assertEqual(r[2].label.text, Bench.SECOND, "none shows the command, as the client's page does")
  assertEqual(r[1].group.type, "SimpleGroup")
  assertEqual(r[1].group.layout, "Flow")
  assertTrue(r[1].group.fullWidth == true)
  local sum = r[1].label.relativeWidth + r[1].slots[1].relativeWidth + r[1].clear.relativeWidth
  assertTrue(sum < 1, "the widths leave the clip inset (options-ui-§8): " .. sum)
  assertEqual(r[1].label.relativeWidth, 0.40, "the label's width as before")
  assertEqual(r[1].slots[1].relativeWidth, 0.22, "the key button's as before")
  assertEqual(r[1].clear.relativeWidth, 0.12, "Clear's as before")
  assertEqual(r[1].clear.text, S.CLEAR)
  assertTrue(r[1].status == r[2].status, "one outcome line under the rows")
  assertEqual(r[1].status.text, "", "empty until an action")
end)

case("keybinds tab: a binding whose command is not a string is skipped and reported", function()
  local _, rec, _, rows = Bench.rowsPage({ bindings = {
    { command = 42 }, Bench.BINDINGS[1] } })
  assertEqual(#rows(), 1)
  assertEqual(rows()[1].command, Bench.TOGGLE)
  assertEqual(#rec.chat, 1)
  assertTrue(rec.chat[1]:find("settings row '42' failed to render", 1, true) ~= nil, rec.chat[1])
end)

case("keybinds tab: one key button per row, then Clear: no second slot widget (minor 4)", function()
  local _, _, _, rows = Bench.rowsPage()
  for _, row in ipairs(rows()) do
    assertEqual(#row.slots, 1, "one key widget")
    assertNil(row.slots[2], "no Key 2 slot")
    local kids = row.group.children
    assertEqual(#kids, 3, "the label, the key button and Clear")
    assertTrue(kids[1] == row.label and kids[2] == row.slots[1] and kids[3] == row.clear,
      "in that order")
    local buttons = 0
    for _, w in ipairs(kids) do if w.type == "Button" then buttons = buttons + 1 end end
    assertEqual(buttons, 2, "the key button and Clear")
  end
  assertNil(S.KEY1, "no 'Key 1' word")
  assertNil(S.KEY2, "no 'Key 2' word")
end)

case("keybinds tab: the button shows the first key, '<key> +1' with a second, NOT_BOUND with none, "
  .. "and a refresher repaints", function()
  mocks.bindKey("F5", Bench.TOGGLE)
  mocks.bindKey("SHIFT-F5", Bench.TOGGLE)
  local _, _, ctx, rows = Bench.rowsPage()
  local r = rows()
  assertEqual(r[1].slots[1].text, "F5 +1", "nothing is hidden: the second key is counted")
  assertEqual(r[2].slots[1].text, mocks.NOT_BOUND)
  mocks.SetBinding("SHIFT-F5", nil)
  for _, fn in ipairs(ctx.refreshers) do fn() end
  assertEqual(r[1].slots[1].text, "F5", "one key: no count")
  mocks.SetBinding("K", Bench.SECOND)
  assertEqual(r[2].slots[1].text, mocks.NOT_BOUND, "no repaint until asked: nothing is cached")
  for _, fn in ipairs(ctx.refreshers) do fn() end
  assertEqual(r[2].slots[1].text, "K", "a refresher re-reads GetBindingKey")
end)

-- ── the capture ──────────────────────────────────────────────────────────────────────────────

-- The key button's tooltip, read by firing its OnEnter with GameTooltip's SetText and AddLine spied.
local function keyTip(widget)
  local tip, seen = mocks.GameTooltip, {}
  local savedSet, savedAdd = rawget(tip, "SetText"), rawget(tip, "AddLine")
  rawset(tip, "SetText", function(_, text) seen[#seen + 1] = text end)
  rawset(tip, "AddLine", function(_, text) seen[#seen + 1] = text end)
  local ok, err = pcall(widget.callbacks.OnEnter, widget)
  rawset(tip, "SetText", savedSet)
  rawset(tip, "AddLine", savedAdd)
  assertTrue(ok, tostring(err))
  return table.concat(seen, "\n")
end

case("keybinds tab: with a second key the tooltip names every key and where the others were set",
function()
  mocks.bindKey("F5", Bench.TOGGLE)
  mocks.bindKey("SHIFT-F5", Bench.TOGGLE)
  local _, _, _, rows = Bench.rowsPage()
  local tip = keyTip(rows()[1].slots[1])
  assertTrue(tip:find(S.SLOT_TIP, 1, true) ~= nil, tip)
  assertTrue(tip:find(S.KEYS_ALL:format("F5, SHIFT-F5"), 1, true) ~= nil, "every key: " .. tip)
  assertTrue(tip:find(S.KEYS_OTHER, 1, true) ~= nil, "where the others were set: " .. tip)
  assertTrue(S.KEYS_OTHER:find("Options -> Keybindings", 1, true) ~= nil, S.KEYS_OTHER)
  local one = keyTip(rows()[2].slots[1])
  assertTrue(one:find(S.SLOT_TIP, 1, true) ~= nil, one)
  assertTrue(one:find(S.KEYS_OTHER, 1, true) == nil, "no second key, no game-page line: " .. one)
  mocks.bindKey("K", Bench.SECOND)
  assertTrue(keyTip(rows()[2].slots[1]):find(S.KEYS_OTHER, 1, true) == nil, "one key neither")
  mocks.bindKey("L", Bench.SECOND)
  assertTrue(keyTip(rows()[2].slots[1]):find(S.KEYS_ALL:format("K, L"), 1, true) ~= nil,
    "read at hover, never cached")
end)

case("keybinds tab: a key bound through the button goes to slot 1 and keeps the second key", function()
  mocks.bindKey("F5", Bench.TOGGLE)
  mocks.bindKey("F6", Bench.TOGGLE)
  local _, _, _, rows = Bench.rowsPage()
  local r = rows()[1]
  Bench.click(r.slots[1])
  Bench.key("K")
  assertEqual(Bench.keys(Bench.TOGGLE), "K,F6", "slot 1 replaced, the game page's key kept")
  assertEqual(r.slots[1].text, "K +1")
  assertEqual(r.status.text, mocks.KEY_BOUND)
end)

case("keybinds tab: the button then SHIFT-K binds SHIFT-K to slot 1 and saves once", function()
  local _, _, _, rows = Bench.rowsPage()
  local r = rows()[1]
  Bench.click(r.slots[1])
  assertEqual(r.slots[1].text, S.LISTENING)
  local f = Bench.listener()
  assertTrue(f.__keyboard == true and f.__mouse == true and f.__wheel == true,
    "the listener takes the keyboard, the mouse and the wheel while it listens")
  assertTrue(f:IsShown())
  assertTrue(f.__kbParent == r.slots[1].frame, "over the slot it listens for")
  assertTrue(f.__kbAll ~= nil, "covering it")
  assertNil(f.__propagates, "never SetPropagateKeyboardInput")
  mocks.setModifiers({ shift = true })
  Bench.key("K")
  mocks.setModifiers({})
  assertEqual(Bench.keys(Bench.TOGGLE), "SHIFT-K")
  assertEqual(#mocks.__savedBindingSets, 1, "saved once")
  assertEqual(mocks.__savedBindingSets[1], 1, "to the set in force")
  assertEqual(r.slots[1].text, "SHIFT-K")
  assertEqual(r.status.text, mocks.KEY_BOUND)
  assertFalse(f:IsShown())
  assertTrue(f.__keyboard == false, "keyboard off once written")
end)

case("keybinds tab: Escape cancels with no SetBinding", function()
  mocks.bindKey("F5", Bench.TOGGLE)
  local _, _, _, rows = Bench.rowsPage()
  local r = rows()[1]
  Bench.click(r.slots[1])
  Bench.key("ESCAPE")
  assertEqual(#mocks.__bindingWrites, 0)
  assertEqual(Bench.keys(Bench.TOGGLE), "F5")
  assertEqual(r.slots[1].text, "F5", "the slot shows its key again")
  assertNil(lib.__keybindCapture)
  assertTrue(Bench.listener().__keyboard == false)
end)

case("keybinds tab: a modifier alone keeps listening; PRINTSCREEN screenshots and keeps listening",
function()
  local shots = 0
  mocks.Screenshot = function() shots = shots + 1 end
  local _, _, _, rows = Bench.rowsPage()
  local r = rows()[1]
  Bench.click(r.slots[1])
  Bench.key("LSHIFT")
  assertTrue(lib.__keybindCapture ~= nil, "still listening")
  assertEqual(r.slots[1].text, S.LISTENING)
  Bench.key("PRINTSCREEN")
  assertEqual(shots, 1)
  assertTrue(lib.__keybindCapture ~= nil, "still listening")
  assertEqual(#mocks.__bindingWrites, 0)
  Bench.key("J")
  assertEqual(Bench.keys(Bench.TOGGLE), "J")
end)

case("keybinds tab: a second left click cancels, and so does a right click on the listener", function()
  local _, _, _, rows = Bench.rowsPage()
  local r = rows()[1]
  Bench.click(r.slots[1])
  Bench.mouse("LeftButton")
  assertNil(lib.__keybindCapture)
  assertEqual(r.slots[1].text, mocks.NOT_BOUND)
  Bench.click(r.slots[1])
  Bench.mouse("RightButton")
  assertNil(lib.__keybindCapture)
  assertEqual(#mocks.__bindingWrites, 0)
end)

case("keybinds tab: Button4 and the wheel bind", function()
  local _, _, _, rows = Bench.rowsPage()
  local r = rows()[1]
  Bench.click(r.slots[1])
  Bench.mouse("Button4")
  assertEqual(Bench.keys(Bench.TOGGLE), "BUTTON4")
  Bench.click(r.slots[1])
  Bench.wheel(1)
  assertEqual(Bench.keys(Bench.TOGGLE), "MOUSEWHEELUP", "slot 1 again: the key replaces BUTTON4")
  Bench.click(rows()[2].slots[1])
  Bench.wheel(-1)
  assertEqual(Bench.keys(Bench.SECOND), "MOUSEWHEELDOWN")
end)

case("keybinds tab: a right click clears the key shown and the second moves up; Clear clears both",
function()
  mocks.bindKey("F5", Bench.TOGGLE)
  mocks.bindKey("F6", Bench.TOGGLE)
  local _, _, _, rows = Bench.rowsPage()
  local r = rows()[1]
  assertEqual(r.slots[1].text, "F5 +1")
  Bench.click(r.slots[1], "RightButton")
  assertEqual(Bench.keys(Bench.TOGGLE), "F6")
  assertEqual(r.status.text, S.CLEARED)
  assertEqual(r.slots[1].text, "F6", "the remaining key moves up and shows, as the client's slots do")
  mocks.bindKey("F7", Bench.TOGGLE)
  r.view.repaint()
  assertEqual(r.slots[1].text, "F6 +1")
  Bench.click(r.clear)
  assertEqual(Bench.keys(Bench.TOGGLE), "")
  assertEqual(r.slots[1].text, mocks.NOT_BOUND)
  assertEqual(r.status.text, S.CLEARED)
end)

case("keybinds tab: starting row 2 stops row 1; one listening slot", function()
  local _, _, _, rows = Bench.rowsPage()
  local r1, r2 = rows()[1], rows()[2]
  Bench.click(r1.slots[1])
  Bench.click(r2.slots[1])
  assertEqual(r1.slots[1].text, mocks.NOT_BOUND, "row 1 shows its key again")
  assertEqual(r2.slots[1].text, S.LISTENING)
  assertTrue(Bench.listener().__kbParent == r2.slots[1].frame)
  Bench.key("Q")
  assertEqual(Bench.keys(Bench.SECOND), "Q")
  assertEqual(Bench.keys(Bench.TOGGLE), "")
end)

-- ── the outcome line ─────────────────────────────────────────────────────────────────────────

case("keybinds tab: a taken key names the action left with no key; otherwise KEY_BOUND", function()
  mocks.BINDING_NAME_LKTEST_OTHER = "Open the other thing"
  mocks.bindKey("M", "LKTEST_OTHER")
  local _, _, _, rows = Bench.rowsPage()
  local r = rows()[1]
  Bench.click(r.slots[1])
  Bench.key("M")
  assertEqual(r.status.text, mocks.KEY_UNBOUND_ERROR:format("Open the other thing"))
  assertEqual(Bench.keys("LKTEST_OTHER"), "")

  mocks.bindKey("N", "LKTEST_OTHER")
  mocks.bindKey("O", "LKTEST_OTHER")
  Bench.click(r.slots[1])
  Bench.key("N")
  assertEqual(r.status.text, mocks.KEY_BOUND, "the loser keeps a key: no unbound line")
  assertEqual(Bench.keys("LKTEST_OTHER"), "O")
end)

-- ── the set line ─────────────────────────────────────────────────────────────────────────────

case("keybinds tab: the set line follows the set in force", function()
  local _, _, ctx = Bench.rowsPage()
  assertEqual(Bench.setLine(ctx), "Saved for: all characters " .. SET_HOW)
  mocks.LoadBindings(2)
  for _, fn in ipairs(ctx.refreshers) do fn() end
  assertEqual(Bench.setLine(ctx), "Saved for: this character only " .. SET_HOW)
end)

-- ── combat ───────────────────────────────────────────────────────────────────────────────────

case("keybinds tab: a capture started in combat is refused with the gray notice, once", function()
  local _, rec, _, rows = Bench.rowsPage()
  local r = rows()[1]
  mocks.InCombatLockdown = function() return true end
  Bench.click(r.slots[1])
  assertNil(lib.__keybindCapture)
  assertEqual(r.status.text, S.COMBAT)
  assertTrue(Bench.listener().__keyboard ~= true, "the keyboard is never taken in combat")
  assertEqual(#rec.chat, 1, "one gray notice")
  assertTrue(rec.chat[1]:find("|cffaaaaaa", 1, true) == 1, rec.chat[1])
  Bench.click(r.slots[1])
  assertEqual(#rec.chat, 1, "and only one")
end)

case("keybinds tab: PLAYER_REGEN_DISABLED stops a capture in progress, writing nothing", function()
  local _, _, _, rows = Bench.rowsPage()
  local r = rows()[1]
  Bench.click(r.slots[1])
  assertTrue(lib.__keybindCapture ~= nil)
  Bench.enterCombat()
  assertNil(lib.__keybindCapture, "stopped at combat start")
  local f = Bench.listener()
  assertTrue(f.__keyboard == false and f.__mouse == false and f.__wheel == false)
  assertFalse(f:IsShown())
  assertEqual(r.status.text, S.COMBAT)
  Bench.key("K")
  assertEqual(#mocks.__bindingWrites, 0)
  assertEqual(#mocks.__bindingRefusals, 0, "not even a refused SetBinding")
  Bench.leaveCombat()
end)

case("keybinds tab: a right click and Clear in combat call no binding API", function()
  mocks.bindKey("F5", Bench.TOGGLE)
  local _, _, _, rows = Bench.rowsPage()
  local r = rows()[1]
  local calls = 0
  for _, name in ipairs({ "GetBindingKey", "GetBindingAction", "SetBinding", "SaveBindings" }) do
    local fn = mocks[name]
    mocks[name] = function(...) calls = calls + 1; return fn(...) end
  end
  mocks.InCombatLockdown = function() return true end
  Bench.click(r.slots[1], "RightButton")
  assertEqual(r.status.text, S.COMBAT)
  r.status:SetText("")
  Bench.click(r.clear)
  assertEqual(r.status.text, S.COMBAT)
  assertEqual(calls, 0, "a refusal reads and writes nothing")
  mocks.InCombatLockdown = function() return false end
  assertEqual(Bench.keys(Bench.TOGGLE), "F5")
end)

-- ── pooling, OnHide, disabled ────────────────────────────────────────────────────────────────

case("keybinds tab: released slots leave with nothing of ours, and the listener goes home", function()
  local O, _, ctx, rows = Bench.rowsPage()
  local r = rows()
  for _, row in ipairs(r) do
    for _, slot in ipairs(row.slots) do
      assertEqual(slot.frame.__clicks, "LeftButtonUp,RightButtonUp", "a slot takes both buttons")
    end
  end
  Bench.click(r[1].slots[1])
  O.ClearScroll(ctx)
  -- The kit's ScrollFrame forgets its children rather than releasing them; AceGUI releases each.
  local aceGUI = mocks.__libs["AceGUI-3.0"]
  for _, row in ipairs(r) do
    for _, w in ipairs({ row.slots[1], row.clear }) do aceGUI:Release(w) end
  end
  for _, row in ipairs(r) do
    for _, w in ipairs({ row.slots[1], row.clear }) do
      assertTrue(w.frame.__clicks == nil or w.frame.__clicks == "LeftButtonUp",
        "restored to LeftButtonUp: " .. tostring(w.frame.__clicks))
      assertNil(w.callbacks.OnClick, "no OnClick left on a pooled Button")
      assertNil(w.frame.__scripts.OnClick, "and no frame script of ours")
    end
  end
  assertNil(lib.__keybindCapture, "a released slot stops its capture")
  local f = Bench.listener()
  assertFalse(f:IsShown())
  assertTrue(f.__kbParent == mocks.UIParent, "parented back to UIParent")
  assertTrue(f.__keyboard == false)
  assertNil(f.__kbAll, "its points cleared")
end)

case("keybinds tab: the page's OnHide stops a capture", function()
  local _, _, ctx, rows = Bench.rowsPage()
  Bench.click(rows()[1].slots[1])
  ctx.panel:Hide()
  ctx.panel:__fire("OnHide")
  assertNil(lib.__keybindCapture)
  assertTrue(Bench.listener().__keyboard == false)
  assertEqual(#mocks.__bindingWrites, 0)
end)

case("keybinds tab: a page drawn disabled draws disabled slots and Clear", function()
  local _, _, _, rows = Bench.rowsPage()
  assertFalse(rows()[1].slots[1].disabled == true, "enabled by default")
  local rows2
  Bench.page(function(O, c)
    c.__renderDisabled = true
    rows2 = O.KeybindRows(c, { bindings = Bench.BINDINGS })
    c.__renderDisabled = nil
  end)
  for _, row in ipairs(rows2) do
    assertTrue(row.slots[1].disabled == true and row.clear.disabled == true)
  end
end)

-- ── degradation and the intro ────────────────────────────────────────────────────────────────

case("keybinds tab: without SetBinding one UNAVAILABLE row and nil", function()
  mocks.SetBinding = nil
  local _, _, ctx, rows = Bench.rowsPage()
  assertNil(rows())
  local top = Bench.top(ctx)
  assertEqual(#top, 1, "exactly one row")
  assertEqual(top[1].text, S.UNAVAILABLE)
  assertEqual(S.UNAVAILABLE, "Key bindings cannot be set here on this client. Use Options -> Keybindings.")
end)

case("keybinds tab: with no AceGUI scroll it draws nothing and answers nil", function()
  local got = "unset"
  Bench.page(function(O, c)
    local saved = O.EnsureScroll
    O.EnsureScroll = function() return nil end
    got = O.KeybindRows(c, { bindings = Bench.BINDINGS })
    O.EnsureScroll = saved
  end)
  assertNil(got)
end)

case("keybinds tab: the fixed intro always draws, and spec.intro adds one line under it", function()
  local intro = "Key bindings are saved by the game, not in your profile. Defaults and Reset all settings leave them alone."
  local _, _, ctx = Bench.rowsPage()
  local top = Bench.top(ctx)
  assertEqual(top[1].text, intro, "XC-02's sentence, first")
  assertEqual(top[2].type, "SimpleGroup", "then the row gap")

  local _, _, ctx2 = Bench.rowsPage({ bindings = Bench.BINDINGS, intro = "A dial's key follows its place." })
  local top2 = Bench.top(ctx2)
  assertEqual(top2[1].text, intro, "the host line never replaces it")
  assertEqual(top2[2].text, "A dial's key follows its place.")
  assertEqual(top2[3].type, "SimpleGroup")

  local _, _, ctx3 = Bench.rowsPage({ bindings = Bench.BINDINGS, strings = { INTRO = "Translated." } })
  assertEqual(Bench.top(ctx3)[1].text, "Translated.", "spec.strings translates it")
end)

-- ── the kit helper ───────────────────────────────────────────────────────────────────────────

case("keybinds tab: T.keybindThroughTab binds through a row and answers the outcome line", function()
  local _, _, _, rows = Bench.rowsPage()
  local status = T.keybindThroughTab(rows()[1], 1, "K", { ctrl = true })
  assertEqual(Bench.keys(Bench.TOGGLE), "CTRL-K")
  assertEqual(status, mocks.KEY_BOUND)
  assertFalse(mocks.IsControlKeyDown(), "the modifiers are put back")
end)

case("keybinds tab: T.keybindThroughTab slot 2 sets the game page's key through the model", function()
  local _, _, _, rows = Bench.rowsPage()
  local r = rows()[1]
  T.keybindThroughTab(r, 1, "K")
  local status = T.keybindThroughTab(r, 2, "J", { shift = true })
  assertEqual(Bench.keys(Bench.TOGGLE), "K,SHIFT-J", "slot 2 written, slot 1 kept")
  assertEqual(status, mocks.KEY_BOUND)
  assertEqual(r.slots[1].text, "K +1", "the row repainted, as the sync would")
  assertFalse(mocks.IsShiftKeyDown(), "the modifiers are put back")
end)
