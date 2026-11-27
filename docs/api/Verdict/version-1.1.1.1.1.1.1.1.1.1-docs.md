# `LibKa0s-Verdict-1.0` — version 1.1.1.1.1.1.1.1.1.1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Verdict surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Verdict-1.0` |
| Files and minors | `Verdict.lua` minor **1** · `VerdictConstants.lua` minor **1** · `VerdictClassData.lua` minor **1** · `VerdictTierTokens.lua` minor **1** · `VerdictEvaluate.lua` minor **1** · `VerdictReads.lua` minor **1** · `VerdictCollect.lua` minor **1** · `VerdictFacts.lua` minor **1** · `VerdictScore.lua` minor **1** · `VerdictGear.lua` minor **1** (the nine secondaries paired on `Verdict.lua`'s minor) |
| Shipped in | unreleased (v1.119.0) |
| Status | **Current** |
| Supersedes | none (new major) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`); `LibKa0s-Compat-1.0`, `LibKa0s-Item-1.0` and `LibKa0s-Role-1.0` read at call time by the reads, each optional |
| Confirm in-game | `LibStub("LibKa0s-Verdict-1.0").MODULES` → `{ Verdict = 1, VerdictConstants = 1, VerdictClassData = 1, VerdictTierTokens = 1, VerdictEvaluate = 1, VerdictReads = 1, VerdictCollect = 1, VerdictFacts = 1, VerdictScore = 1, VerdictGear = 1 }` |

> **Work in progress on `feat/2026-11-27-itemsearch-split`.** This version is being built in steps
> (Ka0s Drop Watcher's plan `docs/superpowers/plans/2026-11-27-itemsearch-split.md`, tasks B1 to
> B4). At this point of the branch the shell and the pure kernel (task B1) and the instance with its
> reads, facts, scorer, collection verdict and gear snapshot (task B2) are in place. The settings
> section (B3) follows as a file of its own, so the version key grows a number again; this document
> moves to the final key and is completed before the release (B4).

## What changed at this version: the major is new

Ka0s Drop Watcher's verdict engine ("what is this item to me": an upgrade, a sidegrade, a downgrade,
something you cannot use or do not want) moves here, so Drop Watcher and Ka0s Item Search judge the
same item the same way. The code is Drop Watcher's, moved: `modules/Evaluate.lua` and
`modules/OffSpec.lua` (now `VerdictEvaluate.lua`), `modules/TierTokens.lua` and the tier token part
of `core/TextParse.lua` (`VerdictTierTokens.lua`), `core/ClassData.lua` and
`core/ClassDataForever.lua` (`VerdictClassData.lua`), the part of `core/Constants.lua` they read
(`VerdictConstants.lua`), and the instance's halves: the compat reads the engine makes
(`VerdictReads.lua`), `modules/Collectibles.lua` without the feed's re-read pass
(`VerdictCollect.lua`), `modules/ItemFacts.lua` and `core/ItemRead.lua` (`VerdictFacts.lua`),
`modules/Scoring.lua` (`VerdictScore.lua`) and `modules/Gear.lua` without `Qualities`, with the
verdict half of `modules/LootFeed.lua`'s judge (`VerdictGear.lua`); pinned on both sides by one golden table (`tests/fixtures/verdict_golden.lua`,
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
| `New(host)` | An instance bound to `host` (the instance API below). Raises unless `host` is a table whose `client` is `"retail"` or `"forever"` | **1** |
| `VerdictModeFor(client)` | `"scoreFirst"` for `"forever"`, `"ilvlFirst"` for anything else: the verdict mode an instance judges in when its host's config names none | **1** |
| `CLIENTS` | `{ retail = true, forever = true }`, the clients a host may name | **1** |
| `Evaluate(facts, candidate, opts)` | The verdict: `{ verdict, equip, ilvlDelta, trackDelta, scoreDelta, baselineSlot, baseline, reasons, band?, either?, averaged?, tokenSlot?, led?, offSpec? }`; never throws. The input shapes are `VerdictEvaluate.lua`'s header | **1** |
| `Equippability(facts, candidate, client)` | Step 1 alone: `"ok"`, `"cant"`, `"doesntWant"` or `"unknown"`, and a reason key for anything but ok | **1** |
| `ItemVerdict(delta, band)` | One item level's verdict with no score | **1** |
| `TrackDelta(drop, base)` | The upgrade track change, `{ tier, rank, sign }` or nil | **1** |
| `SubClassKey(classID, subClassID)` | The `"<classID>:<subClassID>"` key an undesired list is indexed by | **1** |
| `OffSpec` | `Enabled(client)`, `SPEC_REASONS`, `Who(classFile, specID, client)`, `WornGear(gear, who, client)`, `Of(eval)`, `EvalFor(eval)`, `Attach(out, facts, candidate, opts, run)` | **1** |
| `ClassData` | `STAT`, `Set`, `SpecRow`, `Build(data)`, `LISTS` (`retail`, `forever`), `ForClient(key)`; each list carries its data, `STAT` and its lookups (`Spec`, `OwnSpec`, `SpecKey`, `PrimaryStat`, `DualWieldFor`, `TitanGripFor`, `CanUseShield`, `CanUseOffhand`, `SpecIndex`, `ArmorFor`, `CanWearArmor`, `CanUseRelic`, `CanUseWeapon`). Drop Watcher's `Install` has no counterpart: no list is installed on a table every addon shares | **1** |
| `TierTokens` | `Listed`, `UseNamesClass`, `UseSlot`, `NameSlot`, `IsCurio`, `Users`, `SlotOf`, `Fold`, the text parsers `EscapePattern`, `WordMap`, `FirstWord`, `EndsWithWord`, `TokenUseSlot`, and `WORDS`, the locale keys every word-reading member reads the host's locale table by (its last argument; with none, each key is its own word, and so is a key the table lacks) | **1** |
| `C` | The constants: `ITEM_CLASS`, `MISC_SUBCLASS`, `ARMOR_SUBCLASS`, `WEAPON_SUBCLASS`, `QUALITY`, `TRACK_TIER`, `TRACK_TIER_BY_STRING_ID`, `TIER_SLOTS`, `TIER_TOKENS`, `FEATURE_CLIENTS` (`offSpec`, `transmog`) and `FeatureOn(name, client)`, `RECIPE_SUBCLASS`, `RECIPE_SKILL_LINE`, `CATEGORIES`, `BAG_IDS`, `SLOTS` and `SlotsFor(client)`, `SLOT` (the slots both clients share), `SLOT_KIND`, `SLOT_PLANS` and `SlotPlanFor(client)`, `UNIVERSAL_EQUIPLOC`, `ARMOR_TYPED_EQUIPLOC`. Read them, never write them | **1** |

| `Reads` | The default client reads, each under its Drop Watcher compat name (`VerdictReads.lua`'s header): `IsSecret`, `GlobalString`, `ReadTooltipLine`, `InventoryItemLevel`, `InventoryItemLink`, `BagSlotCount`, `BagItemLink`, `BagItemLevelQuality`, `IsItemBindToAccount`, `IsItemBindToAccountUntilEquip`, `ItemEquipLoc`, `CanRequestItemLoad`, `GetItemInfo`, `GetDetailedItemLevel`, `GetItemStats`, `GetItemSpecs`, `GetItemUniqueness`, `GetItemUpgradeInfo`, `PlayerHasTransmog`, `ItemClassRestriction`, `ItemPrimaryStats`, `UnitClass`, `UnitLevel`, `PlayerSpecID`, `PlayerTalentTree`, `PlayerRole` (Role's Resolve with no store), `MountFromItem`, `MountCollected`, `PetSpeciesFromItem`, `PetCollected`, `IsToy`, `ToyCollected`, `IsCosmeticItem`, `RecipeKnown`, `ProfessionSkillLines`, `TierTokenSlot`, `ItemOpens`, `ItemUseText`, `CanRequestSpellLoad`, `RequestSpellLoad`, `ItemIDFromLink`, `QualityFromLink`, `LoadItem`, and the Pawn seam `PawnIsReady`, `PawnItemData`, `PawnUpgradeInfo`, `PawnScaleForSpec(classID, specID, tree, role, client)`, `PawnVisibleScale(…, client)`, `PawnCustomScale`, `PawnClassScales`, `PawnItemValue`. No member raises; each answers its absent value | **1** |
| `Collect` | `CategoryOf(facts, probe)`, `IsCollectible(facts)`, `Verdict(facts, forced, client)` (nil for gear and a tier token; `client` names whose slot plans say an item of no category reads as gear, either client's when nil), `Read(facts, R)` (fills `category` and `collect` through the reads `R`, `lib.Reads` when nil), `REREAD_DELAY` | **1** |
| `ItemRead` | The link, pure: `ItemString`, `LinkDetail`, `BetterLink`, `IdentityKey`, `GEAR_CLASSES` | **1** |
| `Facts` | `TrackTier(stringID, name)` and the cache tunables `MAX_LOAD_TRIES`, `CACHE_CAP`, `EVICT_SHARE`, `SPELL_LOAD_WAIT` (read at call time) | **1** |
| `Score` | The pure halves: `PAWN_STATS`, `STAT_KEYS`, `SCORERS`, `ParseImport(text, warn)`, `ImportInto(map, spec, text, warn)`, `WeightsScore(stats, weights, warn)`, `HasWeights(map)`, `Resolve(configured, pawnReady, hasWeights)`, `WeightsFor(map, candidate, dropStats, client, warn)`, `WeightsScorer(map, client, warn)`; `warn(key, name)` is told of a stat it does not score | **1** |
| `Gear` | `THROTTLE` (0.5 s), `SCORE_RETRY` (1 s), `SCORE_TRIES` (5), `SlotsFor(client)`, `ScorePending(me)` | **1** |

## The instance

`Verdict:New(host)` answers an instance. Every instance keeps its own state (its facts cache, its
gear snapshot, its timers, its pending scores), and the methods are one table every instance shares
(`lib.__methods`), so an instance made before a newer copy of the major loads keeps its host and
answers through the newer methods.

| Host field | What it is |
|---|---|
| `client` | `"retail"` or `"forever"` (required): the class list, the slots and plans, the off-spec and transmog gates, the default verdict mode and the events |
| `config` | `function() -> vcfg`, read per judgment: `{ sidegradeBand, compareOwned, undesired, heirloomProtect, scorer, weights, verdictMode }`, Drop Watcher's `comparison.*` shape; `verdictMode` nil reads `VerdictModeFor(client)`. No config judges on the defaults |
| `L` | The host's locale table, read by `TierTokens.WORDS`' keys (nil: enUS) |
| `reads` | `{ [member] = fn }`: per-read overrides of `lib.Reads`, looked up at each access (`v.R`) |
| `debug` | `function(tag, msg)` for the instance's debug lines |
| `perf` | `{ on, Note(key, ms) }`: timed while `on` (`gear.rebuild`, `evaluate`) |
| `deferWhile` | `function() -> boolean`: while true a `BAG_UPDATE_DELAYED` is held for the next `PLAYER_REGEN_ENABLED` (Drop Watcher: combat) |
| `registerEvent`, `unregisterEvent` | `(event, handler)` and `(event)`: the instance's events, one handler per event, called `handler(event, ...)` |
| `onChange` | `function(kind, arg)`: `"gear"` (your snapshot moved), `"collection"` (a collection was learned), `"score"` (a pending score answered; `arg` the link), `"item"` (an item asked for loaded; `arg` the link). Never while stood down |

| Method | What it answers |
|---|---|
| `Client()`, `ClassData()`, `Config()` | The client, its class list, the host's config now with the verdict mode filled in |
| `Judge(link, forced)` | Your verdict and whether it is pending: `nil, true` while the item loads (asked for; `onChange("item", link)` on arrival), `me, true` while its score waits (retried every `SCORE_RETRY` s, `SCORE_TRIES` times; `onChange("score", link)` when it answers), `me, false` when settled, `nil, false` for a link with no item or a client that cannot load it |
| `JudgeFacts(facts, opts)` | `lib.Collect.Verdict` first, else `lib.Evaluate` for your candidate (with your undesired list and `heirloomProtect`) or for `opts.candidate` (another player's: no heirloom rule); `opts.forced` is the host's own-list answer |
| `Facts(link)`, `ReadFacts(link)`, `Request(link, cb)`, `FactsCounts()`, `RereadCollections()` | The cached facts, an uncached read, the load (`facts, status`: `ready`, `loading`, `invalid`, `unavailable`), the cache's counts, the collection re-read |
| `EffectiveItemLevel(where)`, `QualityOf(link)`, `ItemLevelAt(bag, slot)`, `QualityAt(bag, slot)` | Level and quality with their source |
| `Snapshot()`, `Signature()`, `Candidate()`, `OffSpecGear(specID)` | Your gear snapshot (lazy, quiet), its signature (false when none), your kernel candidate, another spec's gear (Retail) |
| `ReadGear(prev)`, `RefreshGear(cause, quiet, bagsOnly)`, `ScheduleGear(cause)`, `GearScheduled()`, `OnGearEvent(event)`, `OnGearDeferEnd()` | The snapshot's read, rebuild, throttle and event edges |
| `Scorer(cfg)`, `ScorerInUse(cfg)`, `ScoreFor(link, who, cfg)`, `PawnScale(candidate, link)`, `PawnScorer()` | The scorer for the kernel, the adapter in use, one item's score and how it was chosen (`cfg` nil: the host's) |
| `CollectionsChanged()` | Arm the coalesced collection re-read |
| `StandUp()`, `StandDown()`, `IsStoodDown()` | Register the client's events and rebuild (announced); drop the events, cancel every timer, drop every cache |
| `Changed(kind, ...)`, `Debug(tag, fmt, ...)`, `DebugOnce(key, tag, fmt, ...)`, `PerfStart()`, `PerfNote(key, t0)` | The host hooks, for the secondaries |

The events, by client: `PLAYER_EQUIPMENT_CHANGED`, `BAG_UPDATE_DELAYED`, `PLAYER_REGEN_ENABLED`,
`SPELL_TEXT_UPDATE`, `NEW_MOUNT_ADDED`, `NEW_PET_ADDED`, `NEW_TOY_ADDED`, `NEW_RECIPE_LEARNED` and
`SKILL_LINES_CHANGED` on both; `PLAYER_SPECIALIZATION_CHANGED` and `TRANSMOG_COLLECTION_UPDATED` on
Retail; `TRAIT_CONFIG_UPDATED`, `CHARACTER_POINTS_CHANGED` and `PLAYER_LEVEL_UP` on WoW Forever.

The member manifest is [`members-1.1.1.1.1.1.1.1.1.1.json`](./members-1.1.1.1.1.1.1.1.1.1.json).
