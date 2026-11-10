# `LibKa0s-Role-1.0` — version 1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Role surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Role-1.0` |
| Files and minors | `Role.lua` minor **1** |
| Shipped in | v1.95.0 |
| Status | **Current** |
| Supersedes | — (the first version of this major) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`, no member called); `LibKa0s-Compat-1.0` at call time, with no floor |
| Confirm in-game | `LibStub("LibKa0s-Role-1.0").MODULES` → `{ Role = 1 }` |

## What changed at this version: the major is new (`QFE-LK1`)

The owner's rulings R3 and R5 of 2026-11-10 (Ka0sAddonsCommonTasks
`docs/2026-11-10-QUICKCOMMS_FOREVER_EMOTES/inputs/owner-rulings.md`, design §3): the player's
specialization and the role it plays, read the same way on Retail and on WoW Forever, built as a
reusable library module rather than inside Ka0s Quick Comms, its first consumer. Five functions and
one read-only table. The one-consumer promotion is a row in `CLAUDE.md`'s *Documented deviations*.

## What this major is

**A reader of the client, with no state of its own.** On Retail every class has two to four
specializations and the spec API names the role of each, so the spec is the answer. On WoW Forever
every class has one specialization, so the spec API's role is class-wide and wrong for every hybrid.
There the talent tree tells them apart: Forever's talents are one `C_Traits` tree per class whose
**groups are the classic talent trees** (Arms, Fury, Protection), and the group with the most points
spent is the role being played. `Resolve` asks the questions in one fixed order and says which one
answered.

The module owns no SavedVariables. The host passes its per-character table (`store`), and the module
reads `store.override` and `store.last` from it and writes `store.last` to it. No frames, no events,
no addon framework.

## Lib-level surface

| Member | Kind | Since | Contract |
|---|---|---|---|
| `Spec()` | function | 1 | `specID, name` of the active specialization, each plain or nil (exactly two values). Read through Compat's `GetSpecialization` / `GetSpecializationInfo`; a secret, a zero id or no answer is nil, and without Compat both are nil. |
| `SpecsForClass(classFile)` | function | 1 | The class's specializations on this client, in the client's index order: a new array of `{ id, name, role }` (`role` nil where the client names none). `classFile` is the class token (`"WARRIOR"`); nil reads the player's class from `UnitClass("player")`. Empty for an unknown class, a secret, or a missing API. |
| `Groups()` | function | 1 | WoW Forever's talent groups for the active spec group: a new array of `{ index, id, name, spent }` in display order (`orderIndex`), `index` being the position in that order. Empty on any other client and wherever an API or an answer is missing. |
| `Resolve(store)` | function | 1 | `role, source, detail` (exactly three values). See *The resolution order*. |
| `SetOverride(store, role)` | function | 1 | Sets `store.override` to `"TANK"`, `"HEALER"` or `"DAMAGER"`, or clears it with nil. Any other role, or a `store` that is not a table, raises at the caller. |
| `TALENT_GROUP_ROLE` | table | 1 | The talent seed, `[classFile][groupIndex] = role`. Read it; a host never writes it. |

`MAJOR`, `MINOR` and `MODULES` are the usual bookkeeping and are not listed in the member manifest.

## The resolution order

`Resolve(store)` answers the first of these that has an answer:

| # | Source | What it reads | Client |
|---|---|---|---|
| 1 | `"override"` | `store.override`, when it is one of the three roles | both |
| 2 | `"assigned"` | `UnitGroupRolesAssigned("player")`, unless it is `NONE` (or secret, or absent) | both |
| 3 | `"talents"` | The group of `Groups()` with the most points, mapped through `TALENT_GROUP_ROLE[classFile][index]`. A tie for the most, zero points everywhere, an unseeded class or an unseeded index falls through. | Forever only (Compat's `IsForever`) |
| 4 | `"spec"` | The spec API's role, the fifth return of `GetSpecializationInfo` | both |
| 5 | `"saved"` | `store.last.role`, the last answer rungs 2 to 4 gave | both |

`role` is `"TANK"`, `"HEALER"`, `"DAMAGER"` or nil; `source` is one of the five above or nil.
`detail` names where the answer came from when there is a name to give: the talent group's name for
`"talents"` (`"Protection"`), the spec's name for `"spec"`, else nil. A host's tooltip reads it
("from your talents: Protection").

Every answer from rungs 2 to 4 is written to `store.last` as `{ role = role, specID = id }`, updating
the table already there rather than replacing it. An override and a `"saved"` answer write nothing, so clearing an override never brings the manual
pick back as `"saved"`. A `store` that
is not a table is accepted as no store: no override, no saved answer, no write.

The talent rung comes before the spec API on Forever because one spec per class makes the API's
role class-wide (call C1 of the design). On Retail the talent rung is never asked, so its `C_Traits`
calls are never made there.

## How `Groups()` reads the tree

As Forever's own talent frame reads it (`Blizzard_PlayerSpells/Camelot/ClassTalents/`, Forever
1.60.1):

1. The config: `C_SpecializationInfo.GetCombatConfigIDForSpecGroup(C_SpecializationInfo.GetActiveSpecGroup())`,
   else `C_ClassTalents.GetActiveConfigID()`.
2. The tree: the config's first tree, `C_Traits.GetConfigInfo(configID).treeIDs[1]`, else
   `C_ClassTalents.GetTraitTreeForSpec(specID)`.
3. The groups: `C_Traits.GetGroupDisplayInfoByTreeID(treeID)`, sorted by `orderIndex` (then by id).
4. The points: `C_Traits.GetGroupCurrencyInfo(configID, groupIDs)`, the first entry of each group's
   `currencyInfos`, its `spent`. A group with no entry reads 0.

No C function is called with a nil argument: a missing config or tree ends the read with an empty
table.

## The talent seed

**MATCHED, NOT CONFIRMED.** The group order is assumed to be the classic tree order; the owner's
probe (Ka0s Quick Comms `/qc probe`, which records `Groups()`) is what confirms it on the client.

| Class | Group 1 | Group 2 | Group 3 |
|---|---|---|---|
| `WARRIOR` | Arms: DAMAGER | Fury: DAMAGER | Protection: TANK |
| `PALADIN` | Holy: HEALER | Protection: TANK | Retribution: DAMAGER |
| `PRIEST` | Discipline: HEALER | Holy: HEALER | Shadow: DAMAGER |
| `SHAMAN` | Elemental: DAMAGER | Enhancement: DAMAGER | Restoration: HEALER |
| `DRUID` | Balance: DAMAGER | Feral: DAMAGER | Restoration: HEALER |
| `HUNTER`, `ROGUE`, `MAGE`, `WARLOCK` | DAMAGER | DAMAGER | DAMAGER |

A probe that shows another order is a change to this table, and a new minor.

## The rules every member obeys

- Globals are read bare and at call time, never through the global table (pinned by a case), so the
  headless kit can remove an API after load.
- Namespaced rung first (`C_SpecializationInfo`, `C_CreatureInfo`), the global second, nil last.
- A value that may be secret is dropped to nil after `IsSecret` (Compat's, or `issecretvalue` where
  Compat is absent) has said so; only plain numbers and strings are compared or used as keys.
- "Is this WoW Forever" is answered only by Compat's `IsForever` (clients-§3). Without Compat the
  talent rung is skipped and `Spec()` answers nil, because the spec ladder is Compat's.
- No pcall.

## What a headless harness answers

`tests/test_role.lua` installs the whole client each case needs, the project constants included,
so both kit profiles (`lua tests/run.lua` and `KA0S_KIT_CLIENT=forever lua tests/run.lua`) run
every branch of `Resolve`. A consumer's own suite does the same: install `C_SpecializationInfo`,
`UnitGroupRolesAssigned`, `UnitClass` and, for the Forever rung, `C_Traits` and the two config
readers, rather than trusting what the kit's base mock happens to carry.

## Degradation

A host resolves the major with `LibStub("LibKa0s-Role-1.0", true)` and needs a stand-in when it is
absent (a partial payload). The stand-in answers the all-absent values: `Spec()` → `nil, nil`;
`SpecsForClass()` and `Groups()` → `{}`; `Resolve(store)` → the override if set, else `nil, nil, nil`
(or the saved role, if the host wants to mirror rung 5); `SetOverride` writes the field.

## Adopting it

1. Re-vendor v1.95.0 or later, whole-folder.
2. Pick the store: a per-character table (for an AceDB host, `db.char.role`).
3. Read the role with `Role.Resolve(store)` wherever the host decides by it, and show `source` and
   `detail` where the player can see why.
4. Offer the override: Automatic (`SetOverride(store, nil)`) and the three roles.
5. Offer the class's specs from `SpecsForClass`, which needs no per-client seed.

## What is not here

- **Inspecting another unit.** Every read is the player's own. A group member's role is the group's
  assigned role, which `UnitGroupRolesAssigned(unit)` already answers.
- **Events.** The module does not watch talent or spec changes. A host re-reads on its own events
  (`PLAYER_SPECIALIZATION_CHANGED`, `TRAIT_CONFIG_UPDATED`, `GROUP_ROSTER_UPDATE`).
- **Any SavedVariables.** The store is the host's.
