std = "lua51"
max_line_length = false
codes = true
exclude_files = { "tests/_kit/" }
read_globals = {
  "LibStub", "CreateFrame", "UIParent", "UISpecialFrames", "DEFAULT_CHAT_FRAME",
  "time", "date", "debugprofilestop", "UnitAffectingCombat", "InCombatLockdown",
  "C_AddOns", "GetAddOnMetadata",
  "C_Map",   -- the player's map id, read by LibKa0s-Env-1.0
  "C_Item", "C_Timer", "ITEM_QUALITY_COLORS",   -- read by LibKa0s-Item-1.0
  -- An id list's name lookups (LibKa0s-Options-1.0's ResolveId / IdInput / IdList, minor 16), each
  -- read at call time and guarded, so a client without one degrades to id-only input.
  "C_Spell", "C_CurrencyInfo",
  -- IdInput's suggestions (issue #31): the bags and the spellbook it lists, the quality tier it
  -- labels an item's rank with, and the dropdown's backdrop. All read at call time and guarded.
  "C_Container", "C_SpellBook", "C_TradeSkillUI", "Enum", "NUM_TOTAL_EQUIPPED_BAG_SLOTS",
  "NUM_BAG_SLOTS", "BackdropTemplateMixin",
  "GetBuildInfo",   -- the client interface version a perf record stamps
  -- The settings canvas (LibKa0s-Options-1.0). `Settings` is the public registration API;
  -- `SettingsPanel` is private and only ever reached inside a pcall, for expanding the left tree,
  -- or guarded, for the combat refusal. `HideUIPanel` is that refusal's older fallback.
  "Settings", "SettingsPanel", "HideUIPanel", "GameTooltip",
  -- The pointer, for LibKa0s-Widgets-1.0's ReorderList drag. GetCursorPosition answers SCALED
  -- coordinates, so callers divide by UIParent:GetEffectiveScale(); IsMouseButtonDown is polled
  -- to end a drag whose release was never delivered back to the handle.
  "GetCursorPosition", "IsMouseButtonDown",
  -- Blizzard stopwatch, driven by the measurement windows. Called as Lua functions rather than
  -- via "/sw play": RunMacroText is protected and would fail in combat.
  "Stopwatch_Clear", "Stopwatch_Play", "Stopwatch_Pause", "StopwatchFrame",
  -- Capture context, so a saved record says who/where/what.
  "UnitName", "UnitLevel", "UnitClass", "GetRealmName", "GetZoneText", "GetSubZoneText",
  -- The client's class palette, read by LibKa0s-Core-1.0's ClassColor. RAID_CLASS_COLORS rather
  -- than C_ClassColor because it is the table every other UI on the player's screen already reads.
  "RAID_CLASS_COLORS",
  -- The client's own "would RegisterEvent raise?", the front gate of Core's SafeRegisterEvent
  -- family. Read at call time and optional: a client without it takes the pcall rung.
  "C_EventUtils",
  -- `C_SpecializationInfo` is the namespaced rung P.Context prefers; the two bare names are the
  -- deprecated fallback it keeps for a client that has not moved yet.
  "C_SpecializationInfo",
  "GetSpecialization", "GetSpecializationInfo", "IsInInstance", "IsInRaid", "IsInGroup",
  "GetNumGroupMembers",
  -- LibKa0s-Compat-1.0's ladders: the deprecated spell globals below C_Spell, and 12.0's secret
  -- tests. Every one read bare, at call time, and guarded for absence.
  "GetSpellInfo", "GetSpellTexture", "GetSpellCooldown", "issecretvalue", "canaccessvalue",
  -- The client's context menu (11.0+), which LibKa0s-Launcher-1.0's right click opens (minor 4).
  -- Read at call time and guarded: a client without it degrades to opening the settings panel.
  "MenuUtil", "MenuResponse",
}
-- The host's SavedVariables global is named at runtime by the descriptor, so persistence writes
-- through _G[name]. That is the one sanctioned _G mutation in this library.
globals = { "_G" }
-- `lib:New(descriptor)` keeps the colon form because that is how every host calls it, but its body
-- deliberately reads `lib` rather than `self`: a LibStub minor upgrade mutates the shared library
-- table in place, and `self` is only whatever table the caller happened to be holding. The implicit
-- self is therefore unused on purpose, and not a warning worth carrying.
-- 432/self is the same fact seen from the inside. A module whose instance carries methods defines
-- them as `function D:Method()` inside the `lib:New` body, so each one's implicit `self` shadows
-- New's own unused implicit `self`. The shadowing is the point — the inner `self` is the instance,
-- which is what every one of those bodies means — and the outer one is exactly what the paragraph
-- above says never to read.
ignore = { "212/self", "212/event", "432/self" }

-- The test tree is linted. Only `tests/_kit/` is excluded, because it is a byte copy of
-- `testkit/`, which is linted here as source: linting both would report every finding twice, and
-- would let the copy drift green while the original went red.
--
-- The kit publishes its exposed table under a per-repo global -- `LK_TEST` here, written at
-- tests/run.lua:37 and read by every suite file. It is declared in this stanza rather than in the
-- top-level `read_globals` on purpose: a name declared at the top level is a name `LibKa0s/*.lua`
-- may then read unchallenged, and no shipped library file may ever reach for the harness.
-- `globals` rather than `read_globals` because tests/run.lua is the writer.
files["tests/"] = {
  globals = { "LK_TEST" },
}
