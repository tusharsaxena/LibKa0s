# `LibKa0s-Verdict-1.0` — version 3.1.1.1.1.1.1.1.1.2.2

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Verdict surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Verdict-1.0` |
| Files and minors | `Verdict.lua` minor **3** · `VerdictConstants.lua` minor **1** · `VerdictClassData.lua` minor **1** · `VerdictTierTokens.lua` minor **1** · `VerdictEvaluate.lua` minor **1** · `VerdictReads.lua` minor **1** · `VerdictCollect.lua` minor **1** · `VerdictFacts.lua` minor **1** · `VerdictScore.lua` minor **1** · `VerdictGear.lua` minor **2** · `VerdictSettings.lua` minor **2** (the ten secondaries paired on `Verdict.lua`'s minor) |
| Shipped in | v1.120.0 (unreleased) |
| Status | **Current** |
| Supersedes | [version 2.1.1.1.1.1.1.1.1.2.2](./version-2.1.1.1.1.1.1.1.1.2.2-docs.md) (unreleased, superseded before v1.120.0) — `v.R` resolved each read by a bare `__index`, so no seam could wrap the instance's reads and a host whose simulator had to see them handed over a copy of every read |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`); `LibKa0s-Compat-1.0`, `LibKa0s-Item-1.0` and `LibKa0s-Role-1.0` read at call time by the reads, each optional |
| Confirm in-game | `LibStub("LibKa0s-Verdict-1.0").MODULES` → `{ Verdict = 3, VerdictConstants = 1, VerdictClassData = 1, VerdictTierTokens = 1, VerdictEvaluate = 1, VerdictReads = 1, VerdictCollect = 1, VerdictFacts = 1, VerdictScore = 1, VerdictGear = 2, VerdictSettings = 2 }` |

> **Consumers at the tag: none yet.** Built in Ka0s Drop Watcher's plan
> `docs/superpowers/plans/2026-11-27-itemsearch-split.md` (tasks B1 to B4, DropWatcher#19). Its two
> consumers adopt it in the same run, each through one `New(host)` instance: Ka0s Drop Watcher (task C1,
> its loot feed and group-side judging) and Ka0s Item Search (task C3, its tooltip block and window,
> `client = "forever"`). The promotion record below is the owner's ruling R4.

## What changed at this version: the read seam (LibKa0s#111)

An instance resolves each read as `host.reads[name]`, else `lib.Reads[name]`, at the call. Through
version 2.1.1.1.1.1.1.1.1.2.2 `v.R` did that with a bare `__index`, so its members existed only as
lookups. Ka0s Drop Watcher's simulator wraps its own Compat table in place (`LibKa0s-Sim-1.0`'s
seam), and a read the instance made through `lib.Reads` escaped it: no provider was asked and no
guard held. So its host handed over a `reads` table answering `NS.Compat[name]` for every name, and
50 of the 53 library reads were shadowed by addon copies nothing kept in step (LibKa0s#111, review
F-003 of the Item Search split run). On the owner's ruling of 2026-11-28 (seam-wrapping), `v.R` is a
table a seam can wrap, so a host overrides only the reads it names. The design is
`docs/superpowers/specs/2026-11-28-verdict-read-seam.md`.

| Member | Since | What changed |
|---|---|---|
| `v.R` | 1, changed at `Verdict` 3 | Built at `New` with a forwarder per read: a real function member for every function in `lib.Reads` and in a plain `host.reads` table, each calling `host.reads[name]`, else `lib.Reads[name]`, resolved **at each call** (so `host.reads` may still be replaced later, and a newer `lib.Reads` is read at once). Arguments, returns and nil holes pass through; a read that resolves to nothing answers nothing. A name neither carried at `New` (one a later minor adds) still resolves through the table's `__index`, outside any seam until the next reload. A member is never `rawequal` to the host's or the library's function |
| `host.reads` | 1, changed at `Verdict` 3 | Name only the reads the host must answer itself. Every other read is the library's, and a host's simulator covers them with `Sim:Cover(seam, v.R, opts)` (`LibKa0s-Sim-1.0` minor 6, [its document](../Sim/version-6.3.11.4-docs.md)): its providers answer them and its guards hold, with no host copy |

**A host that adopts it** names its own reads alone (Drop Watcher: `PlayerRole`, read from its role
store), and, with a simulator, covers the instance's table once the instance exists and before its
providers register:

```lua
NS.VerdictEngine = V:New({ client = CLIENT, reads = { PlayerRole = NS.Compat.PlayerRole }, ... })
if Sim then Sim:Cover(NS.SimSeam, NS.VerdictEngine.R, { pure = { PlayerRole = true } }) end
```

`pure = { PlayerRole = true }` because that read is already a member of the seam-wrapped Compat
table: covering it again routes one call through the seam twice (a provider asked twice, never a
leak). A host's suite asserts `seam:Unwrapped()` empty after load, which now covers `v.R` too.

**What a version 2.1.1.1.1.1.1.1.1.2.2 caller sees.** Every read answers as before, and a host that
hands every read over still works. A suite that compared `v.R.X` with `lib.Reads.X` or the host's
function by identity compares answers instead.

## At version 2.1.1.1.1.1.1.1.1.2.2: the lazy stand-up (LibKa0s#108)

`StandUp()` reads your gear at once and announces it (`onChange("gear")`). Ka0s Drop Watcher's own
snapshot, before the engine moved here, was lazy and quiet: read when something first asked for your
gear, announcing nothing, since nobody had judged against an older one. To keep that at its
`OnEnable`, its host stood the instance up with its gear announce suppressed, marked the read
provisional and read again, quietly, on the first ask through its gear view (`NS.VerdictEnable`,
`NS.VerdictFresh` in its `core/VerdictSetup.lua`). `StandUp{ lazy = true }` is that lifecycle in the
library, so a host can drop the workaround.

| Member | Since | What changed |
|---|---|---|
| `v:StandUp(opts)` | 1, changed at `Verdict` 2 and `VerdictGear` 2 | `opts.lazy == true`: the events are registered as ever, and the gear snapshot is not read. The first `Judge`, `JudgeFacts`, `Snapshot`, `Signature`, `Candidate` or `OffSpecGear` reads it, quietly: no `onChange("gear")` for that read. A gear event before that ask rebuilds and announces as ever, and its snapshot is the real one, which the ask keeps. A snapshot the instance still holds (a lazy stand-up after an eager one, with no stand-down between) is kept; after a stand-down, which drops it, the next lazy stand-up defers again. With no argument, `{}`, `{ lazy = false }` or anything but a table, unchanged: read at once and announced |
| lifecycle steps (`lib.__lifecycle[key].up`) | 1, changed at `Verdict` 2 | Called `up(v, opts)`, `opts` the stand-up's `{ lazy = boolean }` (always a table); a step that takes one argument is unchanged |

**What a version 1.1.1.1.1.1.1.1.1.1.2 caller sees.** Nothing: `StandUp()` keeps its behavior and
every other member its signature. A host on the lazy path calls `StandUp{ lazy = true }` where it
stood up quietly, and drops its provisional re-read.

## At version 1.1.1.1.1.1.1.1.1.1.2: the weight slider's range (LibKa0s#107)

LibKa0s#107 (review F-010 of the Item Search split run, DropWatcher#19), on the owner's ruling of
2026-11-28: widen the slider. The Pawn import (`Score.ImportInto`) and the weights row's check take any
signed number, but each weight's slider on the Weights tab ran 0..5: an imported 27 showed at 5, and
a touch that let go there wrote 5 over the 27.

| Member | Since | What changed |
|---|---|---|
| `Settings.WEIGHT_MIN`, `Settings.WEIGHT_MAX` | 1, changed at `VerdictSettings` 2 | `-5` and `20` (were `0` and `5`); `WEIGHT_STEP` stays `0.05` |
| `Settings.WeightRange(v)` | `VerdictSettings` 2 | New: a weight slider's `min, max` for the stored weight `v`: `WEIGHT_MIN..WEIGHT_MAX`, an end stretched to the whole number at or past a finite `v` beyond it (`27` answers `-5, 27`; `27.3` answers `-5, 28`; `-8` answers `-8, 20`); a non-number, an infinity or NaN answers the plain range |
| `Settings.Section(ctx, O, spec, "weights")` | 1, changed at `VerdictSettings` 2 | Each weight's slider runs `WeightRange` of its stored weight, read when the page draws (the import and every other write that can move a weight redraw it), so a weight is shown at its own value and a touch that lets go there writes it back |

Nothing is clamped: the import and the check still take any signed number. **What a version
1.1.1.1.1.1.1.1.1.1.1 caller saw.** Every member keeps its signature; a host that read
`WEIGHT_MIN` / `WEIGHT_MAX` for its own slider now reads `-5` and `20`.

## At version 1.1.1.1.1.1.1.1.1.1.1: the major is new

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
verdict half of `modules/LootFeed.lua`'s judge (`VerdictGear.lua`), and the Comparison page's six
rows, defaults and two editors (`settings/SchemaRows.lua`, `defaults/Profile.lua`, `settings/Editors.lua`,
`settings/PageEditors.lua`: `VerdictSettings.lua`, owner ruling R10); pinned on both sides by one golden table (`tests/fixtures/verdict_golden.lua`,
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

## Loading: a file that runs re-runs every file after it

Each secondary's own minor gates it, paired on the shell's, and the files after it in
`LibKa0s.xml` capture what it builds at their load (`local C = lib.C`, the kernels built over
`lib.ClassData`). So when a secondary runs, every secondary after it runs again on what it built,
even at a minor already loaded: each file has an `ORDER` (its place in the load order, spaced by
ten), records the generation it ran at in `lib.__ranAt[ORDER]` through `lib.__Ran(ORDER)`, and runs
again while `lib.__Stale(ORDER)` (a file before it ran after it did). A second copy at the same
minors runs nothing. Without the rule, a release that bumps `VerdictConstants.lua` alone, loaded
after an older copy, left the older kernel judging on the constants it captured, and which set a
verdict read hung on addon load order. A later minor keeps it: a new file takes an `ORDER` between
its neighbors', and never reuses one.

## The lib-level surface

| Member | What it is | Since |
|---|---|---|
| `New(host)` | An instance bound to `host` (the instance API below). Raises unless `host` is a table whose `client` is `"retail"` or `"forever"` | **1** |
| `VerdictModeFor(client)` | `"scoreFirst"` for `"forever"`, `"ilvlFirst"` for anything else: the verdict mode an instance judges in when its host's config names none | **1** |
| `CLIENTS` | `{ retail = true, forever = true }`, the clients a host may name | **1** |
| `EventsFor(client)` | The events an instance of `client` listens to, sorted, a fresh array: the set `StandUp` hands to `host.registerEvent`, for a host that registers it ahead of the instance (events-frames-taint-§1's `SafeRegisterEvents` rows) instead of copying the list below | **1** |
| `Evaluate(facts, candidate, opts)` | The verdict: `{ verdict, equip, ilvlDelta, trackDelta, scoreDelta, baselineSlot, baseline, reasons, band?, either?, averaged?, tokenSlot?, led?, offSpec? }`; never throws. The input shapes are `VerdictEvaluate.lua`'s header | **1** |
| `Equippability(facts, candidate, client)` | Step 1 alone: `"ok"`, `"cant"`, `"doesntWant"` or `"unknown"`, and a reason key for anything but ok | **1** |
| `ItemVerdict(delta, band)` | One item level's verdict with no score | **1** |
| `TrackDelta(drop, base)` | The upgrade track change, `{ tier, rank, sign }` or nil | **1** |
| `SubClassKey(classID, subClassID)` | The `"<classID>:<subClassID>"` key an undesired list is indexed by | **1** |
| `OffSpec` | `Enabled(client)`, `SPEC_REASONS`, `Who(classFile, specID, client)`, `WornGear(gear, who, client)`, `Of(eval)`, `EvalFor(eval)`, `Attach(out, facts, candidate, opts, run)` | **1** |
| `ClassData` | `STAT`, `Set`, `SpecRow`, `Build(data)`, `LISTS` (`retail`, `forever`), `ForClient(key)`; each list carries its data, `STAT` and its lookups (`Spec`, `OwnSpec`, `SpecKey`, `PrimaryStat`, `DualWieldFor`, `TitanGripFor`, `CanUseShield`, `CanUseOffhand`, `SpecIndex`, `ArmorFor`, `CanWearArmor`, `CanUseRelic`, `CanUseWeapon`). Drop Watcher's `Install` has no counterpart: no list is installed on a table every addon shares | **1** |
| `TierTokens` | `Listed`, `UseNamesClass`, `UseSlot`, `NameSlot`, `IsCurio`, `Users`, `SlotOf`, `Fold`, the text parsers `EscapePattern`, `WordMap`, `FirstWord`, `EndsWithWord`, `TokenUseSlot`, and `WORDS`, the locale keys every word-reading member reads the host's locale table by (its last argument; with none, each key is its own word, and so is a key the table lacks) | **1** |
| `C` | The constants: `ITEM_CLASS`, `MISC_SUBCLASS`, `ARMOR_SUBCLASS`, `WEAPON_SUBCLASS`, `QUALITY`, `TRACK_TIER`, `TRACK_TIER_BY_STRING_ID`, `TIER_SLOTS`, `TIER_TOKENS`, `FEATURE_CLIENTS` (`offSpec`, `transmog`) and `FeatureOn(name, client)`, `RECIPE_SUBCLASS`, `RECIPE_SKILL_LINE`, `CATEGORIES`, `BAG_IDS`, `SLOTS` and `SlotsFor(client)`, `SLOT` (the slots both clients share), `SLOT_KIND`, `SLOT_PLANS` and `SlotPlanFor(client)`, `UNIVERSAL_EQUIPLOC`, `ARMOR_TYPED_EQUIPLOC`. Read them, never write them | **1** |
| `Reads` | The default client reads, each under its Drop Watcher compat name (`VerdictReads.lua`'s header): `IsSecret`, `GlobalString`, `ReadTooltipLine`, `InventoryItemLevel`, `InventoryItemLink`, `BagSlotCount`, `BagItemLink`, `BagItemLevelQuality`, `IsItemBindToAccount`, `IsItemBindToAccountUntilEquip`, `ItemEquipLoc`, `CanRequestItemLoad`, `GetItemInfo`, `GetDetailedItemLevel`, `GetItemStats`, `GetItemSpecs`, `GetItemUniqueness`, `GetItemUpgradeInfo`, `PlayerHasTransmog`, `ItemClassRestriction`, `ItemPrimaryStats`, `UnitClass`, `UnitLevel`, `PlayerSpecID`, `PlayerTalentTree`, `SpecName`, `TalentTreeNames`, `PlayerRole` (Role's Resolve with no store), `MountFromItem`, `MountCollected`, `PetSpeciesFromItem`, `PetCollected`, `IsToy`, `ToyCollected`, `IsCosmeticItem`, `RecipeKnown`, `ProfessionSkillLines`, `TierTokenSlot`, `ItemOpens`, `ItemUseText`, `CanRequestSpellLoad`, `RequestSpellLoad`, `ItemIDFromLink`, `QualityFromLink`, `LoadItem`, and the Pawn seam `PawnIsReady`, `PawnItemData`, `PawnUpgradeInfo`, `PawnScaleForSpec(classID, specID, tree, role, client)`, `PawnVisibleScale(…, client)`, `PawnCustomScale`, `PawnClassScales`, `PawnItemValue`. No member raises; each answers its absent value | **1** |
| `Collect` | `CategoryOf(facts, probe)`, `IsCollectible(facts)`, `Verdict(facts, forced, client)` (nil for gear and a tier token; `client` names whose slot plans say an item of no category reads as gear, either client's when nil), `Read(facts, R)` (fills `category` and `collect` through the reads `R`, `lib.Reads` when nil), `REREAD_DELAY` | **1** |
| `ItemRead` | The link, pure: `ItemString`, `LinkDetail`, `BetterLink`, `IdentityKey`, `GEAR_CLASSES` | **1** |
| `Facts` | `TrackTier(stringID, name)` and the cache tunables `MAX_LOAD_TRIES`, `CACHE_CAP`, `EVICT_SHARE`, `SPELL_LOAD_WAIT` (read at call time) | **1** |
| `Score` | The pure halves: `PAWN_STATS`, `STAT_KEYS`, `SCORERS`, `ParseImport(text, warn)`, `ImportInto(map, spec, text, warn)`, `WeightsScore(stats, weights, warn)`, `HasWeights(map)`, `Resolve(configured, pawnReady, hasWeights)`, `WeightsFor(map, candidate, dropStats, client, warn)`, `WeightsScorer(map, client, warn)`; `warn(key, name)` is told of a stat it does not score | **1** |
| `Gear` | `THROTTLE` (0.5 s), `SCORE_RETRY` (1 s), `SCORE_TRIES` (5), `SlotsFor(client)`, `ScorePending(me)` | **1** |
| `Settings` | The Comparison section a host drops into its panel (owner ruling R10; `VerdictSettings.lua`'s header): `DEFAULTS` (Drop Watcher's six: `scorer = "auto"`, `weights = {}`, `sidegradeBand = 0`, `compareOwned = false`, `heirloomProtect = true`, `undesired = {}`) and `Defaults()` (a fresh copy), `KEYS`, `SCORERS`, `Checks`, `WORDS`; `Rows(spec)` (the six as schema rows at `spec.root`, `comparison` by default, the two maps `skipRender`); `Section(ctx, O, spec, tab)` (drawn on the host's Options instance `O`: `tab` `"scoring"`, `"weights"` or `"undesired"`, all three when nil; every write `spec.set(path, value)`, a map always a fresh table); `Tabs(O, spec)` (the two editor tabs for `RenderTabbedSchema`, keyed `Weights` and `Unwanted types`); the editors' pure halves `SpecNamer(specName, treeNames, L)`, `ClassSpecs(classFile, nameOf, client)`, `PickSpec(list, remembered, own)`, `StatsFor(specKey, client)`, `StatLabel(key, globals, L)`, `Weight`, `WithWeight`, `ImportText(result, specLabel, L)`, `UndesiredChoices(classFile, client, L)`, `IsUndesired`, `WithUndesired`, `WEIGHT_MIN` / `WEIGHT_MAX` / `WEIGHT_STEP` (-5, 20, 0.05) and `WeightRange(v)` (a slider's ends, stretched to a stored weight beyond them). The spec: `{ root, L, client, get(path), set(path, value), page, print, reads }`; `print(line)` is the host's prefixed printer for the import's line, and with none the import says nothing | **2** |

## The instance

`Verdict:New(host)` answers an instance. Every instance keeps its own state (its facts cache, its
gear snapshot, its timers, its pending scores), and the methods are one table every instance shares
(`lib.__methods`), so an instance made before a newer copy of the major loads keeps its host and
answers through the newer methods.

| Host field | What it is |
|---|---|
| `client` | `"retail"` or `"forever"` (required): the class list, the slots and plans, the off-spec and transmog gates, the default verdict mode and the events |
| `config` | `function() -> vcfg`, read per judgment: `{ sidegradeBand, compareOwned, undesired, heirloomProtect, scorer, weights, verdictMode }`, Drop Watcher's `comparison.*` shape; `verdictMode` nil reads `VerdictModeFor(client)`. A key the host leaves out, or every key with no config, reads `Settings.DEFAULTS`' value (a map as a fresh copy), so no config judges on the defaults, heirloom protection on |
| `L` | The host's locale table, read by `TierTokens.WORDS`' keys (nil: enUS) |
| `reads` | `{ [member] = fn }`: per-read overrides of `lib.Reads`, resolved at each call through `v.R`'s forwarders (`Verdict` 3); name only the reads the host answers itself |
| `debug` | `function(tag, msg)` for the instance's debug lines |
| `perf` | `{ on, Note(key, ms) }`: timed while `on` (`gear.rebuild`, `evaluate`) |
| `deferWhile` | `function() -> boolean`: while true a `BAG_UPDATE_DELAYED` is held for the next `PLAYER_REGEN_ENABLED` (Drop Watcher: combat) |
| `registerEvent`, `unregisterEvent` | `(event, handler)` and `(event)`: the instance's events, one handler per event, called `handler(event, ...)` |
| `onChange` | `function(kind, arg)`: `"gear"` (your snapshot moved), `"collection"` (a collection was learned), `"score"` (a pending score answered; `arg` the link), `"item"` (an item asked for loaded; `arg` the link). Never while stood down |

| Method | What it answers |
|---|---|
| `Client()`, `ClassData()`, `Config()` | The client, its class list, the host's config now with a missing key's default and the verdict mode filled in |
| `Judge(link, forced)` | Your verdict and whether it is pending: `nil, true` while the item loads (asked for; `onChange("item", link)` on arrival), `me, true` while its score waits (retried every `SCORE_RETRY` s, `SCORE_TRIES` times; `onChange("score", link)` when it answers), `me, false` when settled, `nil, false` for a link with no item, a client that cannot load it or an instance stood down. A link judged again while it loads is announced once |
| `JudgeFacts(facts, opts)` | `lib.Collect.Verdict` first, else `lib.Evaluate` for your candidate (with your undesired list and `heirloomProtect`) or for `opts.candidate` (another player's: no heirloom rule); `opts.forced` is the host's own-list answer |
| `Facts(link)`, `ReadFacts(link)`, `Request(link, cb)`, `FactsCounts()`, `RereadCollections()` | The cached facts, an uncached read, the load (`facts, status`: `ready`, `loading`, `invalid`, `unavailable`, the last also while stood down, when nothing is asked for; a callback handed again for a link still loading is kept once), the cache's counts, the collection re-read |
| `EffectiveItemLevel(where)`, `QualityOf(link)`, `ItemLevelAt(bag, slot)`, `QualityAt(bag, slot)` | Level and quality with their source |
| `Snapshot()`, `Signature()`, `Candidate()`, `OffSpecGear(specID)` | Your gear snapshot (read on the first ask when none is held, quietly), its signature (false when none), your kernel candidate, another spec's gear (Retail) |
| `ReadGear(prev)`, `RefreshGear(cause, quiet, bagsOnly)`, `ScheduleGear(cause)`, `GearScheduled()`, `OnGearEvent(event)`, `OnGearDeferEnd()` | The snapshot's read, rebuild, throttle and event edges |
| `Scorer(cfg)`, `ScorerInUse(cfg)`, `ScoreFor(link, who, cfg)`, `PawnScale(candidate, link)`, `PawnScorer()` | The scorer for the kernel, the adapter in use, one item's score and how it was chosen (`cfg` nil: the host's) |
| `CollectionsChanged()` | Arm the coalesced collection re-read |
| `Events()` | `EventsFor` of the instance's client |
| `StandUp(opts)`, `StandDown()`, `IsStoodDown()` | Register the client's events and rebuild (announced), each registration protected on its own, so one the host refuses costs that event alone, with a debug line; with `opts.lazy` (`Verdict` 2, `VerdictGear` 2) register them and read nothing, the first `Judge` or gear ask reading your gear quietly (no `onChange("gear")` for that read); drop the events, cancel every timer, drop every cache |
| `Changed(kind, ...)`, `Debug(tag, fmt, ...)`, `DebugOnce(key, tag, fmt, ...)`, `PerfStart()`, `PerfNote(key, t0)` | The host hooks, for the secondaries |

The events, by client (`EventsFor(client)` answers the same set): `PLAYER_EQUIPMENT_CHANGED`, `BAG_UPDATE_DELAYED`, `PLAYER_REGEN_ENABLED`,
`SPELL_TEXT_UPDATE`, `NEW_MOUNT_ADDED`, `NEW_PET_ADDED`, `NEW_TOY_ADDED`, `NEW_RECIPE_LEARNED` and
`SKILL_LINES_CHANGED` on both; `PLAYER_SPECIALIZATION_CHANGED` and `TRANSMOG_COLLECTION_UPDATED` on
Retail; `TRAIT_CONFIG_UPDATED`, `CHARACTER_POINTS_CHANGED` and `PLAYER_LEVEL_UP` on WoW Forever.

The member manifest is [`members-3.1.1.1.1.1.1.1.1.2.2.json`](./members-3.1.1.1.1.1.1.1.1.2.2.json).
