-- LibKa0s-Options-1.0 -- the Keybindings tab's model: the settings-panel editor for the key
-- bindings a host declares in its own Bindings.xml (launcher-§6), two slots per action as in the
-- client's Options -> Keybindings page, saved by the game to whichever set is in force. This file
-- holds the headless half: lib.__keybindSet / lib.__keybindClear (write a key with the client's own
-- slot semantics, refuse in combat, save once), lib.__keyChord (a key press to the client's chord
-- string), lib.__keybindSetName and the words, lib.KEYBIND_STRINGS. The rows that draw it attach
-- through lib.__AttachKeybinds (options-ui-§20).
--
-- A twelfth file of the Options major (minor 1), guarded with the same multi-file idiom as
-- OptionsDrawer.lua; Options minor 30 attaches it. It loads after OptionsCombat.lua, because every
-- write asks the combat lock (lib.__IsCombatLocked, Options.lua) first.
--
-- WHY A LIBRARY SURFACE, THOUGH LAUNCHER-§6's RECORDED REJECTION (LibKa0s#58) STANDS. That ruling
-- keeps Bindings.xml and the BINDING_* globals in each addon, so one owner names each category and
-- action. It still holds: this file writes no BINDING_* global, never reads Bindings.xml and sets no
-- default key. What it shares is the editor -- one capture, one write path and one set of words for
-- every addon that offers its bindings on its own settings page, instead of a copy per addon.
--
-- SUPERSEDES QuickComms' 2026-10-21 retirement of its in-panel key box (QuickComms b902e35). The
-- working code it retired (db8f7a6: modules/Dial.lua, core/Compat.lua, modules/Library.lua) is
-- where the write-and-save path below was first run out of combat; it moves here, so a host gets
-- the box back through the library rather than through its own copy.
--
-- THE RULES IT KEEPS (KEYBINDINGS_RESEARCH 3.2 and 5.1 of Ka0sAddonsCommonTasks'
-- docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/):
--   * It never touches SettingsPanel, KeybindListener, Settings.*BindingSet*, HideUIPanel or
--     ToggleGameMenu. Blizzard's own save path (its panel's Commit and OnHide) stays Blizzard's; this
--     file saves its own write with SaveBindings(GetCurrentBindingSet()) and nothing else.
--   * No key is bound, cleared or saved in combat: SetBinding is #nocombat, and SaveBindings is
--     blocked from tainted code in combat. A refusal calls no binding API at all.
--   * No SetPropagateKeyboardInput (protected in combat); the capture enables the keyboard only
--     while it listens, out of combat.
--   * It never reuses KeyBindingFrameBindingTemplate (it writes KeybindListener and SettingsPanel)
--     or AceGUI's Keybinding widget (Escape clears instead of canceling, no META, mouse buttons stop
--     at 5, one slot, English-only words, a FULLSCREEN_DIALOG message frame).

local lib = LibStub and LibStub("LibKa0s-Options-1.0", true)
if not lib then return end

-- Minor 1: the binding model (lib.__keybindSet / lib.__keybindClear / lib.__keybindAvailable /
-- lib.__keybindSetName), the chord builder (lib.__keyChord), the words (lib.KEYBIND_STRINGS) and an
-- empty lib.__AttachKeybinds.
local KEYBINDS_MINOR = 1
-- Paired on the SHELL's minor as well as this file's own -- see OptionsScroll.lua for why.
if lib.__keybindsMinor and lib.__keybindsMinor >= KEYBINDS_MINOR
  and lib.__keybindsShellMinor == lib.MINOR then return end
lib.__keybindsMinor      = KEYBINDS_MINOR
lib.__keybindsShellMinor = lib.MINOR

lib.MODULES = lib.MODULES or {}
lib.MODULES.OptionsKeybinds = KEYBINDS_MINOR

-- ── the words ────────────────────────────────────────────────────────────────────────────────
--
-- A literal table, as OptionsIds.lua's ID_TEXT is: the library carries no locale, and a host that
-- has one passes `spec.strings` with any of these keys. ASCII throughout, with "->" for an arrow
-- (Options.lua's reason: the client's font may draw U+2192 as an empty box).
lib.KEYBIND_STRINGS = {
  TAB_LABEL     = "Keybindings",
  TAB_TIP       = "The same key bindings as Options -> Keybindings. A key set here shows there, " ..
                  "and the other way round.",
  INTRO         = "Key bindings are saved by the game, not in your profile. Defaults and Reset " ..
                  "all settings leave them alone.",
  UNCHANGED     = "Key bindings are not changed.",
  KEY1          = "Key 1",
  KEY2          = "Key 2",
  CLEAR         = "Clear",
  CLEAR_TIP     = "Remove both keys from this action.",
  SLOT_TIP      = "Click, then press a key or a mouse button to bind it. Esc cancels. " ..
                  "Right-click removes this key.",
  LISTENING     = "Press a key...",
  SET_ACCOUNT   = "Saved for: all characters",
  SET_CHARACTER = "Saved for: this character only",
  SET_HOW       = "(Options -> Keybindings -> Character Specific Keybindings)",
  COMBAT        = "Key bindings can be changed after combat.",
  FAILED        = "That key could not be bound.",
  CLEARED       = "Key removed.",
  UNAVAILABLE   = "Key bindings cannot be set here on this client. Use Options -> Keybindings.",
}

-- The client's own words win where it has them, so the tab reads like its Keybindings page. Read
-- at use, never cached: a locale's global strings are the client's, not this file's.
local CLIENT_FALLBACK = {
  NOT_BOUND         = "Not bound",
  KEY_BOUND         = "Key bound.",
  KEY_UNBOUND_ERROR = "%s is now unbound.",
}

--- The client's string `name` (NOT_BOUND, KEY_BOUND or KEY_UNBOUND_ERROR), else the fallback.
function lib.__keybindClientString(name)
  local v
  if name == "NOT_BOUND" then v = NOT_BOUND
  elseif name == "KEY_BOUND" then v = KEY_BOUND
  elseif name == "KEY_UNBOUND_ERROR" then v = KEY_UNBOUND_ERROR end
  if type(v) == "string" and v ~= "" then return v end
  return CLIENT_FALLBACK[name]
end

-- ── the chord builder ────────────────────────────────────────────────────────────────────────
--
-- BindingUtil.lua's logic, bundled for a client (or the headless harness) without its functions.
-- The client's GetConvertedKeyOrButton, IsKeyPressIgnoredForBinding and
-- CreateKeyChordStringUsingMetaKeyState are taken first, each on its own guard.

local IGNORED = {
  LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true,
  LMETA = true, RMETA = true, UNKNOWN = true, BUTTON1 = true, BUTTON2 = true,
}
local MOUSE = { LeftButton = "BUTTON1", RightButton = "BUTTON2", MiddleButton = "BUTTON3" }

local function convertKey(key)
  if type(GetConvertedKeyOrButton) == "function" then return GetConvertedKeyOrButton(key) end
  if MOUSE[key] then return MOUSE[key] end
  local n = tonumber(key:match("^Button(%d+)$"))
  if n and n >= 4 and n <= 31 then return "BUTTON" .. n end
  return key
end

local function isIgnored(key)
  if type(IsKeyPressIgnoredForBinding) == "function" then
    return IsKeyPressIgnoredForBinding(key) and true or false
  end
  return IGNORED[key] == true
end

local function isDown(fn)
  return type(fn) == "function" and fn() and true or false
end

local function bundledChord(key, mods)
  local parts = {}
  if mods.alt then parts[#parts + 1] = "ALT" end
  if mods.ctrl then parts[#parts + 1] = "CTRL" end
  if mods.shift then parts[#parts + 1] = "SHIFT" end
  if mods.meta then parts[#parts + 1] = "META" end
  parts[#parts + 1] = key
  return table.concat(parts, "-")
end

--- A key press as the client's binding string, or nil for a press that binds nothing: a modifier
--- alone, UNKNOWN, the left and right mouse buttons, and ESCAPE (the capture cancels on it before it
--- asks). Prefixes ALT- CTRL- SHIFT- META- in that order. `mods` ({ alt, ctrl, shift, meta })
--- overrides the modifier state for a suite, and takes the bundled route; without it the client's
--- own chord string is used where it exists. PRINTSCREEN is the capture's to handle.
--- @param key string the OnKeyDown key or the OnMouseDown button name
--- @param mods table|nil
--- @return string|nil
function lib.__keyChord(key, mods)
  if type(key) ~= "string" or key == "ESCAPE" then return nil end
  key = convertKey(key)
  if type(key) ~= "string" or key == "" or isIgnored(key) then return nil end
  if mods == nil and type(CreateKeyChordStringUsingMetaKeyState) == "function" then
    return CreateKeyChordStringUsingMetaKeyState(key)
  end
  mods = mods or { alt = isDown(IsAltKeyDown), ctrl = isDown(IsControlKeyDown),
                   shift = isDown(IsShiftKeyDown), meta = isDown(IsMetaKeyDown) }
  return bundledChord(key, mods)
end

-- ── the binding model ────────────────────────────────────────────────────────────────────────

--- True when the client has every binding function the model calls.
function lib.__keybindAvailable()
  return type(GetBindingKey) == "function" and type(GetBindingAction) == "function"
    and type(SetBinding) == "function" and type(SaveBindings) == "function"
    and type(GetCurrentBindingSet) == "function"
end

-- "combat" or "unavailable", or nil when a write may go ahead. Combat first, so a refusal in combat
-- never so much as reads the binding API.
local function refusal()
  if lib.__IsCombatLocked and lib.__IsCombatLocked() then return "combat" end
  if not lib.__keybindAvailable() then return "unavailable" end
  return nil
end

-- The command's keys in slot order, with no hole.
local function currentKeys(command)
  local k1, k2 = GetBindingKey(command)
  local list = {}
  if k1 ~= nil and k1 ~= "" then list[#list + 1] = k1 end
  if k2 ~= nil and k2 ~= "" then list[#list + 1] = k2 end
  return list
end

-- The new slot order (Blizzard's RebindKeysInOrder, Blizzard_Keybindings.lua): the old keys with
-- `key` in `slot`. A key the command already holds moves (the two swap); a new key replaces the
-- slot's old key; slot 2 on a keyless command becomes slot 1.
local function newOrder(old, slot, key)
  local rest, moved = {}, false
  for _, k in ipairs(old) do
    if k == key then moved = true else rest[#rest + 1] = k end
  end
  if moved or rest[slot] == nil then
    table.insert(rest, math.min(slot, #rest + 1), key)
  else
    rest[slot] = key
  end
  return rest
end

-- Put everything back after a falsy SetBinding: unbind what was bound, rebind the old keys in
-- order, and give `key` back to the action it was taken from.
local function restore(command, old, bound, key, displaced)
  for _, k in ipairs(bound) do SetBinding(k, nil) end
  for _, k in ipairs(old) do SetBinding(k, command) end
  if displaced then SetBinding(key, displaced) end
end

-- Steps 5 to 7: unbind the old keys, take `key` from `displaced`, rebind in order. Answers false at
-- the first falsy return, with what it had bound so far.
local function writeOrder(command, old, order, key, displaced, bound)
  for _, k in ipairs(old) do
    if not SetBinding(k, nil) then return false end
  end
  if displaced and not SetBinding(key, nil) then return false end
  for _, k in ipairs(order) do
    if not SetBinding(k, command) then return false end
    bound[#bound + 1] = k
  end
  return true
end

--- Bind `key` to `command` in `slot` (1 or 2), the client's way, and save it to the set in force.
--- @return boolean ok
--- @return string|nil displaced the action `key` was taken from
--- @return boolean|nil displacedUnbound true when that action is left with no key
--- @return string|nil reason "combat", "unavailable" or "failed" when not ok
function lib.__keybindSet(command, slot, key)
  local why = refusal()
  if why then return false, nil, nil, why end
  slot = (slot == 2) and 2 or 1
  local old = currentKeys(command)
  if old[slot] == key then return true end
  local prev = GetBindingAction(key)
  local displaced = (prev ~= nil and prev ~= "" and prev ~= command) and prev or nil
  local order, bound = newOrder(old, slot, key), {}
  if not writeOrder(command, old, order, key, displaced, bound) then
    restore(command, old, bound, key, displaced)
    return false, nil, nil, "failed"
  end
  local displacedUnbound = displaced ~= nil and GetBindingKey(displaced) == nil
  SaveBindings(GetCurrentBindingSet())
  return true, displaced, displacedUnbound
end

--- Remove `command`'s key in `slot` (1 or 2), or both when `slot` is nil, and save once.
--- Nothing to clear answers true and saves nothing.
--- @return boolean ok
--- @return string|nil reason "combat", "unavailable" or "failed" when not ok
function lib.__keybindClear(command, slot)
  local why = refusal()
  if why then return false, why end
  local old = currentKeys(command)
  local targets = {}
  if slot == 1 or slot == 2 then targets[1] = old[slot] else targets = old end
  if #targets == 0 then return true end
  for _, k in ipairs(targets) do
    if not SetBinding(k, nil) then
      for _, o in ipairs(old) do SetBinding(o, nil) end
      for _, o in ipairs(old) do SetBinding(o, command) end
      return false, "failed"
    end
  end
  SaveBindings(GetCurrentBindingSet())
  return true
end

--- "character" when the character-specific set is in force, else "account".
function lib.__keybindSetName()
  if type(GetCurrentBindingSet) ~= "function" then return "account" end
  local character = (Enum and Enum.BindingSet and Enum.BindingSet.Character)
    or CHARACTER_BINDINGS or 2
  return GetCurrentBindingSet() == character and "character" or "account"
end

-- ── the attach ───────────────────────────────────────────────────────────────────────────────

--- Called by lib:New (Options minor 30), guarded. The tab's instance members arrive with the next
--- minor of this file; minor 1 attaches nothing.
function lib.__AttachKeybinds(O, d) -- luacheck: no unused args
end
