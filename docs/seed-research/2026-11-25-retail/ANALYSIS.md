# Analysis — LibKa0s seed validation, 2026-11-25 (retail)

The first run of the library's seed contract (`docs/validate-seeds.md`, LibKa0s#93), item `SF-LK-02` of
Ka0sAddonsCommonTasks `docs/2026-11-25-SEEDS_AND_FOREVERDB/`.

## What the branch says

Ketho/BlizzardInterfaceResources `live` is at `f3b334b33bd19fa6a0250f7922ecfa83db7fe356` (2026-10-22),
the sha `testkit/client_globals_live.lua` already records. The run's reader reproduces the checked-in
set exactly: 10556 names, 0 added, 0 removed, and every kit name reaches the head (`DIFF.md`). So there
is no `regen:live` candidate and nothing to apply. The live name set and its `tests/_kit/` copy are
unchanged.

## The payload's assumptions

The scan of `LibKa0s/*.lua` found 10 `Enum` reads, 30 `C_X.Y` names and 60 bare global calls that a
client or a kit file knows. Six are absent on `live`, and all six are rungs of a feature-detected
ladder, so each is ruled `keep` with its guard cited (`RULINGS.md`):

| Flag | Why it is absent on Retail | Guard |
| --- | --- | --- |
| `Enum.GameRule.PvPRuleset`, `Enum.GameRule.RPRuleset` | WoW Forever's ruleset rules | `on(rule)` answers false for a nil member, `Compat.lua:394` |
| `C_SpecializationInfo.GetSpecializationInfoForClassID` | Retail has the global | tried only when present, `Role.lua:189`; the global next, `Role.lua:192` |
| `C_Traits.GetGroupCurrencyInfo`, `C_Traits.GetGroupDisplayInfoByTreeID` | WoW Forever's talent groups | `talentSource` answers nil off Forever and without either member, `Role.lua:296-299` |
| `RegionalUniqueNamesEnabled` | WoW Forever's region-unique names | `regionalNames` answers false where it is absent, `Compat.lua:404` |

No flag is ruled `fix`: the payload makes no unguarded Retail assumption that `live` contradicts.

## Needs owner review

Nothing.

## What a later run should re-check

- Whether `live` has moved: `python3 tools/seeds/libseeds.py status --flavor retail`. A regeneration
  of live means a forever re-run too, since the forever file is stored against live.
- The cited lines, if `Compat.lua` or `Role.lua` move.
