std = "lua51"
max_line_length = false
codes = true
exclude_files = { "tests/", "docs/" }
read_globals = {
  "LibStub", "CreateFrame", "UIParent", "UISpecialFrames", "DEFAULT_CHAT_FRAME",
  "time", "date", "debugprofilestop", "UnitAffectingCombat", "InCombatLockdown",
  "C_AddOns", "GetAddOnMetadata",
  -- Blizzard stopwatch, driven by the measurement windows. Called as Lua functions rather than
  -- via "/sw play": RunMacroText is protected and would fail in combat.
  "Stopwatch_Clear", "Stopwatch_Play", "Stopwatch_Pause", "StopwatchFrame",
  -- Capture context, so a saved record says who/where/what.
  "UnitName", "UnitLevel", "UnitClass", "GetRealmName", "GetZoneText", "GetSubZoneText",
  "GetSpecialization", "GetSpecializationInfo", "IsInInstance", "IsInRaid", "IsInGroup",
  "GetNumGroupMembers",
}
-- The host's SavedVariables global is named at runtime by the descriptor, so persistence writes
-- through _G[name]. That is the one sanctioned _G mutation in this library.
globals = { "_G" }
