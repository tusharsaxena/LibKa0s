std = "lua51"
max_line_length = false
codes = true
exclude_files = { "tests/", "docs/" }
read_globals = {
  "LibStub", "CreateFrame", "UIParent", "UISpecialFrames", "DEFAULT_CHAT_FRAME",
  "time", "date", "debugprofilestop", "UnitAffectingCombat", "InCombatLockdown",
  "C_AddOns", "GetAddOnMetadata",
  "C_Map",   -- the player's map id, read by LibKa0s-Env-1.0
  "C_Item", "C_Timer", "ITEM_QUALITY_COLORS",   -- read by LibKa0s-Item-1.0
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
  "GetSpecialization", "GetSpecializationInfo", "IsInInstance", "IsInRaid", "IsInGroup",
  "GetNumGroupMembers",
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
