# `LibKa0s-Verdict-1.0` — version 1.1.1.1.1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Verdict surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Verdict-1.0` |
| Files and minors | `Verdict.lua` minor **1** · `VerdictConstants.lua` minor **1** · `VerdictClassData.lua` minor **1** · `VerdictTierTokens.lua` minor **1** · `VerdictEvaluate.lua` minor **1** (the four secondaries paired on `Verdict.lua`'s minor) |
| Shipped in | unreleased (v1.119.0) |
| Status | **Current** |
| Supersedes | none (new major) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`) |
| Confirm in-game | `LibStub("LibKa0s-Verdict-1.0").MODULES` → `{ Verdict = 1, VerdictConstants = 1, VerdictClassData = 1, VerdictTierTokens = 1, VerdictEvaluate = 1 }` |

> **Work in progress on `feat/2026-11-27-itemsearch-split`.** This version is being built in steps
> (Ka0s Drop Watcher's plan `docs/superpowers/plans/2026-11-27-itemsearch-split.md`, tasks B1 to
> B4). At this point of the branch the shell and the pure kernel are in place (task B1). The reads,
> the facts, the gear snapshot, the scorer, the collection verdict and the instance API (B2) and the
> settings section (B3) follow, each as a file of its own, so the version key grows a number per
> file; this document moves to the final key and is completed before the release (B4).

## What changed at this version: the major is new

Ka0s Drop Watcher's verdict engine ("what is this item to me": an upgrade, a sidegrade, a downgrade,
something you cannot use or do not want) moves here, so Drop Watcher and Ka0s Item Search judge the
same item the same way. The code is Drop Watcher's, moved: `modules/Evaluate.lua` and
`modules/OffSpec.lua` (now `VerdictEvaluate.lua`), `modules/TierTokens.lua` and the tier token part
of `core/TextParse.lua` (`VerdictTierTokens.lua`), `core/ClassData.lua` and
`core/ClassDataForever.lua` (`VerdictClassData.lua`), and the part of `core/Constants.lua` they read
(`VerdictConstants.lua`), pinned on both sides by one golden table (`tests/fixtures/verdict_golden.lua`,
copied unchanged from Drop Watcher).

## Why this exists: the promotion record

`library-stack-§7` bar 1 asks for two consumers before a component is promoted into the library, as a
SHOULD; a promotion the owner rules a suite-wide component is conformant and takes no deviation row.
This one has both:

| | |
|---|---|
| Ruled by | Tushar Saxena (owner) |
| Date | 2026-11-27 |
| Where | Ruling R4 of Ka0s Drop Watcher's `docs/superpowers/specs/2026-11-27-itemsearch-split-design.md` (DropWatcher#19): the upgrade engine is promoted into LibKa0s, not copied; both addons use it |
| Consumers | Ka0s Drop Watcher (its loot feed, its group-side judging) and Ka0s Item Search (its tooltip block and window) |

## The client is the caller's

Drop Watcher picked its class list, its ranged slot plans and its off-spec gate once, at file load,
from the client it ran on. A major shared through LibStub cannot, so the client is named per call:
`opts.client` (`"retail"` or `"forever"`) picks the class list (`ClassData.ForClient`), the slot
plans (`C.SlotPlanFor`) and the off-spec gate (`OffSpec.Enabled`) of an evaluation. Left out, the
class list and the slot plans are Retail's and the off-spec pass does not run: the two defaults
differ on purpose (no client named is no off-spec). The verdict mode stays the caller's
(`opts.verdictMode`). Nothing in the major reads the client it runs on.

## The lib-level surface

| Member | What it is | Since |
|---|---|---|
| `New(host)` | An instance bound to `host`. Raises unless `host` is a table whose `client` is `"retail"` or `"forever"`. At this point of the branch an instance carries its host and client, and answers `Client()`; the instance API lands with task B2 | **1** |
| `CLIENTS` | `{ retail = true, forever = true }`, the clients a host may name | **1** |
| `Evaluate(facts, candidate, opts)` | The verdict: `{ verdict, equip, ilvlDelta, trackDelta, scoreDelta, baselineSlot, baseline, reasons, band?, either?, averaged?, tokenSlot?, led?, offSpec? }`; never throws. The input shapes are `VerdictEvaluate.lua`'s header | **1** |
| `Equippability(facts, candidate, client)` | Step 1 alone: `"ok"`, `"cant"`, `"doesntWant"` or `"unknown"`, and a reason key for anything but ok | **1** |
| `ItemVerdict(delta, band)` | One item level's verdict with no score | **1** |
| `TrackDelta(drop, base)` | The upgrade track change, `{ tier, rank, sign }` or nil | **1** |
| `SubClassKey(classID, subClassID)` | The `"<classID>:<subClassID>"` key an undesired list is indexed by | **1** |
| `OffSpec` | `Enabled(client)`, `SPEC_REASONS`, `Who(classFile, specID, client)`, `WornGear(gear, who, client)`, `Of(eval)`, `EvalFor(eval)`, `Attach(out, facts, candidate, opts, run)` | **1** |
| `ClassData` | `STAT`, `Set`, `SpecRow`, `Build(data)`, `LISTS` (`retail`, `forever`), `ForClient(key)`; each list carries its data, `STAT` and its lookups (`Spec`, `OwnSpec`, `SpecKey`, `PrimaryStat`, `DualWieldFor`, `TitanGripFor`, `CanUseShield`, `CanUseOffhand`, `SpecIndex`, `ArmorFor`, `CanWearArmor`, `CanUseRelic`, `CanUseWeapon`). Drop Watcher's `Install` has no counterpart: no list is installed on a table every addon shares | **1** |
| `TierTokens` | `Listed`, `UseNamesClass`, `UseSlot`, `NameSlot`, `IsCurio`, `Users`, `SlotOf`, `Fold`, the text parsers `EscapePattern`, `WordMap`, `FirstWord`, `EndsWithWord`, `TokenUseSlot`, and `WORDS`, the locale keys every word-reading member reads the host's locale table by (its last argument; with none, each key is its own word) | **1** |
| `C` | The constants: `ITEM_CLASS`, `MISC_SUBCLASS`, `ARMOR_SUBCLASS`, `WEAPON_SUBCLASS`, `QUALITY`, `TRACK_TIER`, `TIER_SLOTS`, `TIER_TOKENS`, `FEATURE_CLIENTS`, `SLOTS` and `SlotsFor(client)`, `SLOT` (the slots both clients share), `SLOT_KIND`, `SLOT_PLANS` and `SlotPlanFor(client)`, `UNIVERSAL_EQUIPLOC`, `ARMOR_TYPED_EQUIPLOC`. Read them, never write them | **1** |

The member manifest is [`members-1.1.1.1.1.json`](./members-1.1.1.1.1.json).
