# Adoption matrix — 2026-08-02

Evidence for every table here is in `05_EVIDENCE.md`, by section number.

## 1. Version fidelity — file minors, ship vs vendored

Ship folder (`LibKa0s/*.lua`), read from source, not from the changelog:

| File | Ship minor |
|---|---|
| `Core.lua` | 3 |
| `DebugLog.lua` | 7 |
| `Slash.lua` | 5 |
| `Options.lua` | 5 |
| `OptionsWidgets.lua` | 5 |
| `OptionsScroll.lua` | 2 |
| `Perf.lua` | 5 |
| `PerfPanel.lua` | 3 |

Every consumer, every file:

| Consumer | Core | DebugLog | Slash | Options | Widgets | Scroll | Perf | PerfPanel |
|---|---|---|---|---|---|---|---|---|
| AbsorbTracker | 3 | 7 | 5 | 5 | 5 | 2 | 5 | 3 |
| BankLedger | 3 | 7 | 5 | 5 | 5 | 2 | 5 | 3 |
| ConsumableMaster | 3 | 7 | 5 | 5 | 5 | 2 | 5 | 3 |
| KickCD | 3 | 7 | 5 | 5 | 5 | 2 | 5 | 3 |
| LootHistory | 3 | 7 | 5 | 5 | 5 | 2 | 5 | 3 |
| PanelMaster | 3 | 7 | 5 | 5 | 5 | 2 | 5 | 3 |
| prettychat | 3 | 7 | 5 | 5 | 5 | 2 | 5 | 3 |
| WhatGroup | 3 | 7 | 5 | 5 | 5 | 2 | 5 | 3 |

**64 / 64 cells current. Zero cross-major skew.**

Note that every consumer carries `Perf.lua` and `PerfPanel.lua` at the current minor including the
five that decline the Perf module. That is correct and is what whole-folder vendoring means: the
files ship, the major registers, and the host simply never calls `lib:New`. A host that declined
Perf by *not copying the files* would be the defect.

## 2. Byte fidelity

`diff -rq` and `diff -rq --strip-trailing-cr`, library and test kit, per consumer. Every cell is the
line count of the diff output:

| Consumer | lib byte | lib content | kit byte | kit content |
|---|---|---|---|---|
| AbsorbTracker | 0 | 0 | 0 | 0 |
| BankLedger | 0 | 0 | 0 | 0 |
| ConsumableMaster | 0 | 0 | 0 | 0 |
| KickCD | 0 | 0 | 0 | 0 |
| LootHistory | 0 | 0 | 0 | 0 |
| PanelMaster | 0 | 0 | 0 | 0 |
| prettychat | 0 | 0 | 0 | 0 |
| WhatGroup | 0 | 0 | 0 | 0 |

**32 / 32 diffs empty.** Byte and content agree everywhere, so there is no line-ending divergence to
adjudicate — the state the v1 run of 2026-08-01 had to disentangle does not exist today.

The library's own `testkit/` and `tests/_kit/` are also byte-identical, asserted by its own suite
(`kitsync` cases, `05_EVIDENCE.md` §7).

## 3. Module coverage — majors wired, and where the seam lives

From `LibStub("LibKa0s-<Major>-1.0", true)` lookup sites outside `libs/` and `tests/`:

| Consumer | Core | DebugLog | Slash | Options | Perf | Majors |
|---|---|---|---|---|---|---|
| AbsorbTracker | `core/CoreSetup.lua:25` | `core/DebugLogSetup.lua:14` | `settings/Slash.lua:24` **+ `settings/Schema.lua:182`** | `settings/OptionsSetup.lua:36` | `core/PerfSetup.lua:14` | **5** |
| BankLedger | `core/CoreSetup.lua:34` | `core/DebugLogSetup.lua:20` | `settings/Slash.lua:99` | `settings/OptionsSetup.lua:26` | — declined | 4 |
| ConsumableMaster | `core/CoreSetup.lua:33` | `modules/DebugLog.lua:55` | `core/SlashCommands.lua:1302` | `settings/Panel.lua:184` | `modules/PerfSetup.lua:29` | **5** |
| KickCD | `core/CoreSetup.lua:64` | `core/DebugLogSetup.lua:45` | `settings/Slash.lua:55` | `settings/OptionsSetup.lua:35` | `core/PerfSetup.lua:33` | **5** |
| LootHistory | `core/CoreSetup.lua:32` | `core/DebugLogSetup.lua:25` | `settings/Slash.lua:103` | `settings/OptionsSetup.lua:35` | — declined | 4 |
| PanelMaster | `core/CoreSetup.lua:32` | `core/DebugLogSetup.lua:79` | `settings/Slash.lua:252` | `settings/OptionsSetup.lua:26` | — declined | 4 |
| prettychat | `core/CoreSetup.lua:41` | `core/DebugLogSetup.lua:39` | `settings/Slash.lua:72` **+ `settings/Schema.lua:229`** | `settings/OptionsSetup.lua:17` | — declined | 4 |
| WhatGroup | `core/CoreSetup.lua:39` | `core/DebugLogSetup.lua:20` | `settings/Slash.lua:73` | `settings/OptionsSetup.lua:17` | — declined | 4 |

**Total module-adoptions: 35.**

Cross-checked against `docs/releasing.md`'s Consumers table: **every lookup site above appears in
the table's third column, and the table names no file that does not appear above.** Both second
Slash lookups (AbsorbTracker's and prettychat's `settings/Schema.lua`) are recorded, which is the
specific failure the releasing checklist's step 9 sweep exists to catch. No disagreement to report —
the first run in this series where that is true without qualification.

Filesystem cross-check: `ls -d ../*/libs/LibKa0s` returns exactly these eight. No repo holds a
vendored library the table does not name, and the table names no repo that lacks one.
`WhoGotLoots` and `BuffTextNotifications` hold none, as expected.

## 4. Adoption depth — surfaces actually called, in production source

Excludes `libs/` and `tests/`, so these are surfaces the shipped addon reaches, not ones a suite
pokes.

| Consumer | Schema CLI | Landing/Help | Flow engine | Core |
|---|---|---|---|---|
| AbsorbTracker | List, Get, Set, Reset | LandingRows | RenderRows, RenderGrid, LSMValues | SafeToString, MakeCloseButton |
| BankLedger | List, Get, Set, Reset | LandingRows | RenderRows, SetRenderer | SafeToString, SKIN, MakeCloseButton, ApplySkin |
| ConsumableMaster | List, Get, Set, Reset | LandingRows | RenderGrid, RenderField, LSMValues, SetRenderer | SafeToString, SKIN |
| KickCD | List, Get, Set, Reset | LandingRows, HelpRows | RenderRows, RenderField, LSMValues | SafeToString, MakeCloseButton |
| LootHistory | List, Get, Set, Reset | LandingRows, HelpRows | RenderRows, SetRenderer | SafeToString, SKIN, MakeCloseButton, ApplySkin |
| PanelMaster | List, Get, Set, Reset | LandingRows, HelpRows | RenderRows, RenderField, LSMValues, SetRenderer | SafeToString, SKIN |
| prettychat | List, Get, Set, Reset | LandingRows | RenderRows, RenderField, SetRenderer | SafeToString |
| WhatGroup | List, Get, Set, Reset | LandingRows, HelpRows | RenderRows, RenderGrid, RenderField, LSMValues, SetRenderer | SafeToString, SKIN, MakeCloseButton, ApplySkin |

**All four schema-CLI verbs are adopted by all eight consumers.** That is a notable movement: the
prompt's own plan for prettychat was "adopt the dispatcher, help renderer and landing-row formatter
while keeping `list/get/set/reset` host-owned", and the finished adoption took all four. `CliList` /
`CliGet` / `CliSet` / `CliReset` are counted separately here precisely because hosts were expected to
take three of four; none did.

Depth is not scored by deletion volume. prettychat reaches the fewest distinct surfaces in the table
and is not a worse adopter for it — its per-string editor is a documented 40/60 three-row block the
flow engine cannot express, and declining a maker that does not fit is the faithful answer.

## 5. Descriptor surfaces — who passes what

The count that matters for a frozen `-1.0` major: how many independent host shapes each optional
surface has been tested against.

| Surface | Since | Consumers | Count |
|---|---|---|---|
| `applySkin` | DebugLog 4 | BankLedger, LootHistory | 2 |
| `makeCloseButton` | DebugLog 4 | — **none** | **0** |
| `skin` | DebugLog | — **none** | **0** |
| `format` | Slash 5 | BankLedger, LootHistory, prettychat | 3 |
| `colorDecode` / `colorEncode` | Slash 4 | AbsorbTracker, ConsumableMaster, KickCD | 3 |
| `sliderCommit` | OptionsWidgets 4 | ConsumableMaster | 1 |
| `parse` | Slash | BankLedger, KickCD, PanelMaster, prettychat, WhatGroup | 5 |
| `sep` | Core | prettychat | 1 |
| `pairWith` | OptionsWidgets | prettychat | 1 |
| numeric-enum dropdown | OptionsWidgets 5 | BankLedger, LootHistory | 2 |

`format` ∩ `colorDecode` = **∅**. The documented precedence of `format` over `colorDecode` has never
executed and no host is near the boundary. See `03_DEVIATIONS.md` §4.

> **Correction, applied the same day, before this bundle was committed.** The `skin` and `sep` rows
> first read *1 — BankLedger* and *2 — prettychat, WhatGroup*. Both were wrong, and wrong the same
> way: the sweep matched a bare key name and caught **local variables**, not descriptor fields —
> `../BankLedger/modules/SessionWindow.lua:456` (`local skin = (NS.Browser and NS.Browser.SKIN) …`,
> BankLedger's own skin table) and `../WhatGroup/modules/Frame.lua:84` (`local sep = f:CreateTexture(…)`,
> a divider texture). Reading the descriptors gives `skin` **zero** consumers — every host falls
> through to `core.SKIN` at `LibKa0s/DebugLog.lua:195` — and `sep` **one**, prettychat at
> `../prettychat/core/CoreSetup.lua:103`. This is the third instance in this run of the same
> failure mode, after the `-A6` window that falsely reported ConsumableMaster as having numeric-enum
> rows: **a grep for a key name is not a reading of the descriptor.** The raw sweep output in
> `05_EVIDENCE.md` §5 is left exactly as it printed, with the false positives annotated there.

The numeric-enum route is inferred from a `values` list on a `type="number"` row
(`LibKa0s/OptionsWidgets.lua:466`), not opted into — the host's own `widget = "Dropdown"` key is host
vocabulary the library never reads. Both consumers happen to spell both, which means neither has
tested the inference in isolation. ConsumableMaster, the one `sliderCommit` host, has 22 number rows
and **zero** carrying `values`, so the prompt's statement that the two have never been rendered
together still holds.

## 6. The `L` trap — coverage per module-adoption

Descriptor `L` values found outside `libs/` and `tests/`, all four read and classified:

| Consumer | Site | Value | Verdict |
|---|---|---|---|
| ConsumableMaster | `core/SlashCommands.lua:1320` | `SLASH_STRINGS`, a plain literal table at `:1269` | correct |
| KickCD | `settings/Slash.lua:335` | `NS.L and { … } or nil` | correct — the legitimate third form |
| PanelMaster | `settings/Slash.lua:328` | `{ RESET_ALL = "…" }` literal | correct |
| WhatGroup | `settings/Slash.lua:182` | `{ ERR_BOOL = "…" }` literal | correct |

The other four consumers pass no `L` at all, which is the common and recommended case. **No
descriptor anywhere is handed an addon-wide locale table.**

Guard coverage, counted as *guarded module-adoptions / total module-adoptions*:

| Consumer | Core | DebugLog | Slash | Options | Perf | Guarded |
|---|---|---|---|---|---|---|
| AbsorbTracker | tripwire `test_ltrap.lua:154` | rendered `test_debuglog.lua:147` | rendered `test_slash.lua:167` | tripwire `test_ltrap.lua:167` | rendered `test_perf.lua:418` | 5/5 |
| BankLedger | tripwire `test_libka0s.lua:208` | rendered `test_libka0s.lua:461` | rendered `test_libka0s.lua:734` | tripwire `test_libka0s.lua:222` | — | 4/4 |
| ConsumableMaster | tripwire `test_coresetup.lua:124` | rendered `test_debuglog.lua:274` | rendered `test_slashsetup.lua:117` | tripwire `test_settingsui.lua:56` | rendered `test_perfsetup.lua:60` | 5/5 |
| KickCD | tripwire `test_coresetup.lua:241` | rendered `test_debuglogsetup.lua:275` | rendered `test_slash.lua:338` | tripwire `test_options_panel.lua:423` | rendered `test_perfsetup.lua:375` | 5/5 |
| LootHistory | tripwire `test_libka0s.lua:168` | rendered `test_debuglog.lua:159` | rendered `test_slash.lua:225` | tripwire `test_libka0s.lua:188` | — | 4/4 |
| PanelMaster | tripwire `test_libka0s.lua:593` | rendered `test_libka0s.lua:184` | rendered `test_libka0s.lua:290` | tripwire `test_libka0s.lua:466` | — | 4/4 |
| prettychat | tripwire `test_libka0s.lua:119` | rendered `test_libka0s.lua:204` | rendered `test_libka0s.lua:449` | tripwire `test_libka0s.lua:303` | — | 4/4 |
| WhatGroup | tripwire `test_libka0s.lua:625` | rendered `test_libka0s.lua:176` | rendered `test_libka0s.lua:407` | tripwire `test_libka0s.lua:636` | — | 4/4 |

**35 / 35 module-adoptions guarded.** Every Core adoption carries both halves of the Core tripwire
(the `lib.STRINGS`-absent assertion *and* the source check), and every Options adoption carries the
source half alone — correctly, since `Options.lua` ships a `STRINGS` table of its own and asserting
its absence would fail against a module behaving as designed. Several hosts assert
`type(rawget(opts, "STRINGS")) == "table"` positively, so the tripwire goes red if Options ever
loses it rather than passing vacuously.

## 7. The convergences

| Consumer | `reset` takes a path | Landing rows through one formatter | Recorded |
|---|---|---|---|
| AbsorbTracker | adopted | adopted | `LEDGER.md`, 11 `LIBKA0S-*` rows |
| BankLedger | adopted | adopted | 36 rows |
| ConsumableMaster | adopted | adopted | `LIBKA0S-12` (reset), `LIBKA0S-13` (landing) |
| KickCD | adopted | adopted | 6 rows |
| LootHistory | adopted | adopted | 29 rows |
| PanelMaster | adopted | adopted | 34 rows |
| prettychat | adopted | adopted | 18 rows |
| WhatGroup | adopted | adopted | 19 rows |

**Both convergences are adopted by all eight consumers, and every consumer has a
`docs/pending/LEDGER.md` carrying `LIBKA0S-*` rows that mention both.** Nothing is in the *declined*
or *not applicable* state anywhere, so there is no undocumented-decision finding in this run.

ConsumableMaster is the closed loop from the 2026-08-01 runs: the v1 run found its `reset`
divergence with zero occurrences of the word anywhere in its ledger, and the v2 run found its
landing page misread as *not applicable* because a grep for `COMMANDS` missed a helper indirection.
Both are now recorded as explicit `Option A: converge` decisions at `LIBKA0S-12` and `-13`.

## 8. The green gate, and provenance

| Repo | Cases | Failed | luacheck | Files linted |
|---|---|---|---|---|
| **LibKa0s** | 419 | 0 | 0 / 0 | 11 |
| AbsorbTracker | 469 | 0 | 0 / 0 | 28 |
| BankLedger | 687 | 0 | 0 / 0 | 24 |
| ConsumableMaster | 561 | 0 | 0 / 0 | 50 |
| KickCD | 648 | 0 | 0 / 0 | 32 |
| LootHistory | 534 | 0 | 0 / 0 | 23 |
| PanelMaster | 609 | 0 | 0 / 0 | 23 |
| prettychat | 255 | 0 | 0 / 0 | 17 |
| WhatGroup | 415 | 0 | 0 / 0 | 14 |

**4,197 cases, 0 failed, 0 warnings, 0 errors.** No warnings needed attributing to adoption versus
host hygiene, because there were none in any repo.

Provenance:

| Consumer | `libs/LibKa0s/LICENSE` | README line | Version named | True? |
|---|---|---|---|---|
| AbsorbTracker | yes | `Bundles [LibKa0s](…) v1.5.0` | v1.5.0 | yes |
| BankLedger | yes | `Bundles …` | v1.5.0 | yes |
| ConsumableMaster | yes | `Bundles …` | v1.5.0 | yes |
| KickCD | yes | `Bundles …` | v1.5.0 | yes |
| LootHistory | yes | `…it bundles …` (mid-sentence) | v1.5.0 | yes |
| PanelMaster | yes | `Bundles …` | v1.5.0 | yes |
| prettychat | yes | `Bundles …` | v1.5.0 | yes |
| WhatGroup | yes | `…bundles …` (mid-sentence) | v1.5.0 | yes |

Tag fidelity — the previous run's headline finding, re-established from scratch:

```
git describe --tags        → v1.5.0
git log --oneline -1       → 4a33bad
git log --oneline -1 v1.5.0 → 4a33bad
git diff --stat v1.5.0 -- LibKa0s testkit → (empty)
```

The tag exists, resolves, points at HEAD, and the payload at that tag is byte-for-byte what all
eight consumers vendor. Every provenance line above is checkable rather than merely present.
