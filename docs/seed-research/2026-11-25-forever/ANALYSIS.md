# Analysis — LibKa0s seed validation, 2026-11-25 (forever)

The first run of the library's seed contract (`docs/validate-seeds.md`, LibKa0s#93), item `SF-LK-02` of
Ka0sAddonsCommonTasks `docs/2026-11-25-SEEDS_AND_FOREVERDB/`.

## What the branch says

Ketho/BlizzardInterfaceResources `forever` has moved from `d1ee569878094270c0ad8d8b00de0762158fd578`
(2026-10-21, the sha the kit recorded) to `e230342a476eb4ef484ba7b34adc0da6ecc6acc1` (2026-11-14). Before
reading the new head, the run's reader was checked against the old one: from Ketho's files at
`d1ee569` it reproduces the checked-in forever set exactly (10545 names), and from `f3b334b` the live
set (10556), so the diff below is the branch's and not the reader's.

At `e230342` the set is 10559 names: 17 added and 3 removed (`DIFF.md`).

- **Added (17):** among them `C_ActionBar.IsHighestSpellRank`, `C_TradeSkillUI.HasNoReagentCost`,
  `C_GameRules.SetForeverExperiencePresetPreLogin` and `...PostLogin`, and eleven global functions
  (honor columns, smart navigation, a paper-doll overlay). An added name can only clear a finding.
- **Removed (3):** `C_GameRules.SetForeverExperiencePreset` (replaced by the pre- and post-login pair),
  `ShouldShowBattlePetIcon` and `SmartNavigation_SetReturnFrameFocusButton`. No tracked Lua file in any
  sibling checkout of the collection names any of the three (a grep of `GIT/` excluding `tests/_kit/`,
  `testkit/` and `libs/`, 2026-11-25), so the regenerated set gives no consumer's missing-globals gate a
  new finding.

## Rulings and what was applied

- `regen:forever`: **accept**. The diff is understood, no removed name is called, and the owner's answer 3
  of `03_SPEC.md` says regenerate when Ketho has moved. `apply` regenerated
  `testkit/client_globals_forever.lua` and `tests/_kit/client_globals_forever.lua` through the unchanged
  `tools/client_globals_data.lua` (CRLF kept), and a second `apply` changed nothing. That is kit revision
  62 (`docs/api/testkit/version-62-docs.md`).
- `C_SpecializationInfo.GetSpecializationInfoForClassID`, absent on `forever` too: **keep**. It is the
  namespaced rung of `Role.lua`'s `specForClass`, tried only when present (`Role.lua:189`), then the
  global `GetSpecializationInfoForClassID` (`Role.lua:192`), which this branch lists.

Every other payload assumption (10 `Enum` reads, 29 more `C_X.Y` names, 60 bare calls) is present on
`forever`. Ketho's forever set can over-report (the kit's forever profile removes `GetSpecialization`,
which it lists), so present is evidence, not proof, and no guard is dropped on its account.

`candidates.json` was derived before `apply`, so it still proposes `regen:forever`; a re-derive now
proposes nothing, because the kit records this bundle's sha.

## Needs owner review

Nothing.

## What a later run should re-check

- Whether `forever` (or `live`, which the forever file is stored against) has moved.
- The three removed names, if a consumer ever adopts one of them: the gate will flag it on Forever.
