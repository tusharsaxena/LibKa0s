# Deviations — 2026-08-01 (run v2)

Second run of the day. It was convened after the v1.2.0 minor bumps to DebugLog, Slash, Options and
OptionsWidgets, and after BankLedger landed as the fourth consumer, to answer one question: is every
consumer's vendored copy at the current ship minors, or is some host now behind? It answers clean.
Thirty-two of thirty-two file-minor cells are at ship, all sixteen vendor diffs are empty, and every
consumer's suite and lint pass is green. The earlier run of the day is `docs/adoption/2026-08-01/`;
nothing below is inherited from it, and every figure was re-established from evidence.

Seventeen deviations follow. **None is a runtime defect in any consumer.** The two highest-severity
findings are both about the library's own artefacts rather than about anyone's code: a release that
four shipped addons name and no ref resolves, and four new contracts that between them have one
consumer. They are ordered by what each costs if left alone.

Each is labelled on two independent axes, because they have different fixes and different urgency:
**Deliberate?** — was this a choice, or an accident. **Recorded?** — is the choice written down
where the next person looks. A thing that is *wrong* needs a code change; a thing that is merely
*undocumented* needs a sentence, and the two should never be filed together.

Section references are to `05_EVIDENCE.md` in this bundle unless a path is given; a few cite the
collector notes under `_raw/`.

---

## Continuity — the earlier run's eight deviations, one by one

Carried forward with their original numbering, because a persisting finding is more useful with its
history attached than rediscovered fresh.

| Earlier | Subject | State now | Where |
|---|---|---|---|
| §1 | Ship folder violates its own line-ending policy; `diff -r` inverts | **FIXED** | §3, §10.1 — all 60 tracked ship files CRLF, all 16 vendor diffs empty |
| §2 | `L`-trap regression guard covers 1 of 15 module-adoptions | **FIXED** | §7.2, §7.3 — every consumer now carries rendered assertions; residual gaps at §11 below |
| §3 | ConsumableMaster declines convergence #1, unrecorded | **FIXED** | §6.3 — converged, LEDGER LIBKA0S-12 plus a CHANGELOG breaking entry |
| §4 | `docs/adoption-prompt.md` misstates ConsumableMaster's landing page | **CHANGED SHAPE — and the correction was wrong** | §5 below |
| §5 | The vendored library ships with no licence or attribution | **FIXED** | §9.1 — `LICENSE` inside `libs/LibKa0s/` in all four |
| §6 | No adopter records which LibKa0s version it carries | **FIXED** | §9.1 — four README provenance lines, all naming v1.2.0, all true |
| §7 | `RenderGrid` has one consumer | **PARTLY FIXED** | §14 below — AbsorbTracker joined ConsumableMaster; KickCD declines in writing |
| §8 | Degradation-stub idiom differs; KickCD has no shared cause clause | **FIXED** | §11.4 — KickCD 10 sites, ledger LIBKA0S-05 |

Five closed outright, one partly, one fixed in substance but replaced by a larger instance of the
same class of error in the same file, and one — §4 — where the earlier bundle's correction made the
record less accurate than what it corrected. Nothing that was green has regressed.

---

## §1 — v1.2.0 has shipped into four addons but was never tagged

**Deliberate:** no — steps 1–5 and 7 of `docs/releasing.md` were all executed; only step 6's tag is
missing. **Recorded:** no. **Severity:** high.

### What

`git tag` in the LibKa0s repo lists only v1.0.0, v1.1.0 and v1.1.1; `git describe --tags` reads
`v1.1.1-7-g8d1d879`, i.e. HEAD is seven commits past the last tag — the seven being the DebugLog,
Slash, OptionsWidgets and Options minor bumps and their `docs/releasing.md` entries. `CHANGELOG.md:13`
heads a `## v1.2.0 — 2026-08-01` block, all eight ship-folder minors stand at their v1.2.0 values
(Core 2, DebugLog 4, Slash 5, Options 5, OptionsWidgets 5, OptionsScroll 2, Perf 5, PerfPanel 3),
and all four consumers' READMEs say "Bundles LibKa0s v1.2.0 (MIT)" at `AbsorbTracker/README.md:143`,
`KickCD/README.md:197`, `ConsumableMaster/README.md:274` and `BankLedger/README.md:11`.

The claim is stronger than its own evidence. `diff -r` — the byte-level form of the vendoring gate
at `docs/releasing.md:56` — is empty for all four addons, so each one really does carry the v1.2.0
payload rather than merely naming it. Four published addons name a release that does not exist as a
ref in this repo.

### Why nothing has caught it

Nothing checks it. Every other release obligation has a mechanical proof: the minors are
cross-checked against the CHANGELOG block by `tests/test_versioning.lua`, which passes all seven of
its cases; the vendored copies are cross-checked by `diff -r`; the provenance lines were moved by
hand and are correct. The tag is the one step with neither a test nor a diff behind it, and it is
the step that leaves no trace in the working tree when skipped.

### Why it matters, and what it costs

The provenance line is the single artefact that answers "which LibKa0s does this addon carry?"
without grepping eight constants out of vendored source, and its answer currently cannot be resolved
to a commit. Nobody can check out what those four addons claim to bundle. A bisect across the four
feature commits between v1.1.1 and HEAD has no endpoint to bisect to, and a consumer that later
needs to establish *which* v1.2.0 it took — there being no ref, several different trees could
legitimately have carried that name — has nothing to appeal to but the byte diff, which only answers
for as long as the ship folder stays still.

### Evidence

§10.2, §2.1, §9.1.

---

## §2 — `docs/adoption-prompt.md` still lists BankLedger as an unadopted target, in four places

**Deliberate:** no — a document that was not moved when the adoption landed. `docs/releasing.md`
*was* moved, in three separate commits (ff08aef, 410da0b, 3ea1c51), so this is a single-file omission
rather than a systemic one. **Recorded:** no. **Severity:** high.

### What

Four statements, all of which say BankLedger has not adopted:

1. **Line 6** — "Adopted: **AbsorbTracker** (consumer #1), **KickCD**, **ConsumableMaster** — all
   five modules each." The count is three where the filesystem says four.
2. **Line 8** — "Remaining targets: `BankLedger`, `LootHistory`, `PanelMaster`, `prettychat`,
   `WhatGroup`." BankLedger belongs in neither this list nor this count.
3. **Line 303** — the per-addon suggested-order table still carries a live, un-struck BankLedger row
   reading "Core (printer only) → DebugLog → Slash → Options → Perf". ConsumableMaster's row at line
   299 is the established convention for a completed adoption: struck through, marked **done**, with
   a paragraph on what actually happened. BankLedger's row has had neither treatment, and its
   "→ Perf" tail now contradicts a recorded wont-do.
4. **Line 538** — the additive-change proof quotes "AbsorbTracker 462, KickCD 643, ConsumableMaster
   554, each 0 failed" as the suites to re-run when the library changes. BankLedger's 684 is absent.
   The three quoted figures are themselves still accurate — all three were re-run live and all three
   `docs/test-cases.md` Totals rows agree — so this is a missing entry rather than a rotted one.

The filesystem is the authority and it says BankLedger is consumer #4: `ls -d ../*/libs/LibKa0s`
returns exactly four repos, BankLedger wires four majors (`core/CoreSetup.lua:34`,
`core/DebugLogSetup.lua:20`, `settings/Slash.lua:99`, `settings/OptionsSetup.lua:26`), its vendored
copy is at all eight current minors with both diffs empty, and it declines Perf on structural grounds
recorded at its `docs/pending/LEDGER.md` LIBKA0S-17. `docs/releasing.md` is correct on every one of
those points, including omitting BankLedger from the Perf row and stating the decline in prose at
line 177.

Two lesser staleness items sit in the same file. Lines 285–286 — "BankLedger and LootHistory —
architectural twins; treat them as one job done twice" — is now recon for one addon rather than two,
and its claim that the numeric dropdown "stays host-drawn" is superseded: that is a library surface
as of OptionsWidgets minor 5.

### Why nothing has caught it

`docs/releasing.md`'s Consumers table has a mechanical check behind it — a release sweep reads it
file by file, and a wrong row shows up as a repo that fails `diff -r`. The prompt has no such
consumer. It is read once per adoption, by a fresh session with no memory of the previous one, which
is exactly the reader least equipped to notice it is being lied to.

### Why it matters, and what it costs

The operational cost is line 538. Step 8 of "When the library itself has to change" tells the next
library author to re-run three consumers and call the change additive. BankLedger's 684 cases are
the *only* ones anywhere that exercise the four surfaces v1.2.0 added — the `applySkin` and
`makeCloseButton` hooks, the `format` hook, the numeric-enum dropdown and the canvas contract — so
the proof step omits the one suite that could fail. Following it as written proves additivity against
three hosts that cannot see the change.

The rest is wasted work and worse. `docs/adoption-report.md` tells a reader to use the prompt for
"what is not yet adopted", so a future audit would count three adopters against a filesystem holding
four. A session dropped into BankLedger with this prompt is told the job is greenfield, and its live
module-order row would send that session to adopt a Perf module the host has a written, structural
reason to decline. It also strands the most valuable thing the BankLedger adoption produced: the
twin-repo framing that was meant to make LootHistory cheap has lost its worked half.

### Evidence

§11.3, §1, §8.5.

---

## §3 — Every v1.2.0 addition has exactly one consumer, and it is the same one

**Deliberate:** partly. Each change was individually justified and individually recorded; that all
four landed against one host's shape in one release is the emergent property nobody weighed.
**Recorded:** no — no artefact states it. **Severity:** high.

### What

All four surfaces added this release were driven by BankLedger, and three of the four are called by
BankLedger and by nobody else:

| Surface | Sole consumer | Everyone else |
|---|---|---|
| DebugLog `applySkin` + `makeCloseButton` (minor 4) | `BankLedger/core/DebugLogSetup.lua:111`, `:116` | AbsorbTracker and KickCD accept Core's chrome; ConsumableMaster declines the sibling `skin` field in writing (`modules/DebugLog.lua:167`) |
| Slash `format` (minor 5) | `BankLedger/settings/Slash.lua:198` — the only `format =` in the four repos | no other host has a row type `lib.FormatValue` cannot render |
| Numeric-enum dropdown in `RenderField` (OptionsWidgets minor 5) | `BankLedger/settings/Schema.lua:76` and `:83` — the only two `number` + `values` rows in the collection | every other host's number rows carry `min`/`max`/`step` and no `values` |
| `CreatePanel`'s Blizzard canvas contract (Options minor 5) | — not opt-in; see §6 | all four benefit, one asserts |

The report method's own scoring rule says a surface with one consumer is a finding rather than a
success, because its contract has been tested against exactly one shape. This release produced four
of them at once.

The compounding part is that the three opt-in ones cannot interact in any currently-shipping
combination. BankLedger passes `format` but no `colorDecode`, so the documented precedence of
`format` over `colorDecode` has never executed. BankLedger has the numeric enum and no
`sliderCommit`; ConsumableMaster has `sliderCommit` and no enum rows, so number-row dispatch has
never been rendered with both present. And both BankLedger enum rows declare no `min`/`max`/`step`,
so the fallback path for a number row carrying *both* a `values` list and a range has never run.

The dispatch is also inferred rather than opted into: `type = "number"` plus a non-empty `values`
silently reclassifies the row from slider to dropdown. Nothing else in the collection is affected
today, which is precisely why nothing else could catch a regression in it — and why the first KickCD
row to grow a `values` key will flip widget with no code change and no test anywhere that would see
it.

### Why nothing has caught it

The prompt's rule of thumb is sound — one host's misfit is a setup-file concern, two is a library
gap — but in three of these four cases the second host was supplied by argument rather than by a
second host. LootHistory being next in line makes this worse rather than better: it is BankLedger's
architectural twin, so it will confirm the contracts rather than stress them.

### Why it matters, and what it costs

Every one of these contracts is frozen additive-only inside a `-1.0` major. An assumption baked in
now cannot be renamed or repurposed later, only worked around. The specific assumptions currently
resting on one implementation each are worth naming: that `applySkin` may be handed a fully-built
frame with `frame.title` and `frame.divider` already assigned and will tolerate both; that a host's
close-button factory returns something whose `GetWidth()` is positive at build time (the derived
`titleBarOffsets` have been exercised at exactly two widths, 24 and the library's own 18); and that
`format` is only ever wanted for types the library cannot render at all — where prettychat, the
second motivating case in the CHANGELOG, needs it for a type the library renders fine.

### Evidence

§11.2, §5.6, §5.7.

---

## §4 — ConsumableMaster declines convergence #2, and the decision is written down nowhere

**Deliberate:** unknown, and that is the problem. `git log -L 718,729:settings/Panel.lua` shows the
formatter arriving whole in f844f78 ("Migrate Settings UI to KickCD-style canvas framework") and
untouched since, so on the evidence it was never revisited during the LibKa0s work rather than
weighed and kept. No comment acknowledges the divergence, in a file that comments at length on every
other library decision it makes — `:238` on the registry, `:384-389` on `Section`, `:407-424` on the
makers, `:435-455` on `LSMValues`, `:509-517` on `Grid`. **Recorded:** no. **Severity:** medium.

### What

The convergence says a landing page renders its command rows through `lib.FormatRow` via
`Sl:LandingRows`, in the help colours. ConsumableMaster has such a page and renders them through its
own formatter instead. `settings/Panel.lua:770` installs `Helpers.BuildAboutContent` as the renderer
for `mainCtx` — the panel `/cm config` opens, described in the source at `:776-780` as "the About
splash with logo + tagline + slash help"; `:707-714` draws the "Slash Commands" heading, `:718-719`
pulls the rows via `KCM.SlashCommands.GetCommandSummary()`, and `:723-724` formats each one itself.

`od -c` on both sides settles it byte for byte. The host emits `|cffffff00/cm %s|r` + **two** spaces
+ `|cffffffff` em dash `|r` + **two** spaces + a bare `%s`; the library's `Slash.lua:69` emits
`|cFFFFFF00%s|r` + one space + a bare em dash + one space + `|cFFFFFFFF%s|r`. Double spacing, a
white-wrapped dash and an uncoloured description — verbatim the three differences
`docs/adoption-prompt.md:427-432` predicts. `Sl:LandingRows` is never called anywhere in the repo.

The chat half is already converged: `tests/test_slashsetup.lua:57-59` pins `HelpRows[1]`
byte-for-byte against `"  " .. lib.FormatRow(...)`. So this host carries exactly the
two-divergent-formatters state the convergence exists to collapse — one of them the library's, one
of them not.

### Recorded nowhere, checked properly

`grep -rn -i 'landing\|LandingRows\|FormatRow\|About page\|BuildAboutContent\|converg'` over
`docs/pending/LEDGER.md` returns only LIBKA0S-01 (the dispatcher, help and version) and LIBKA0S-12
(convergence #1). `CHANGELOG.md` carries only the `/cm reset` entry. `README.md` carries nothing.
The single "landing" hit anywhere in `docs/` is a smoke-test heading at `docs/smoke-tests.md:136`.
The ledger's LIBKA0S row index runs 01, 04, 05, 02, 06, 07, 08, 09, 10, 11, 12 — no row for this,
and no LIBKA0S-03 at all.

### Why nothing has caught it

Because the obvious grep misses it — see §5. The rows reach the panel through
`KCM.SlashCommands.GetCommandSummary()`, a name that a search for `COMMANDS` or `LandingRows` never
returns, so both the earlier run and the prompt concluded from a negative grep that there was
nothing there.

### Why it matters, and what it costs

Two costs, neither at runtime. First, the silence: an unrecorded decision is indistinguishable from
an oversight, and the next consistency sweep will "fix" it — collapsing the spacing and moving the
colour span on a shipped panel with no record that anyone chose otherwise. That is the precise
failure the earlier run documented for convergence #1 in this same addon, and that LIBKA0S-12 was
written to close; the same shape survived here unnoticed. Second, this host is the collection's
best-documented adopter, with eleven ledger rows and superseded states preserved, so a gap here reads
as "nothing to decide" rather than "not yet decided".

### Evidence

§6.3, §6.1.

---

## §5 — The earlier bundle's §4 correction is wrong, and `docs/adoption-prompt.md` has been amended to match it

**Deliberate:** no — an honest error, and a narrow one. **Recorded:** yes, twice, and that is what
makes it expensive: it is now load-bearing in both the frozen bundle and the live prompt.
**Severity:** medium.

### What

`docs/adoption/2026-08-01/03_DEVIATIONS.md:148-171` recorded that "ConsumableMaster has no landing
page carrying command rows … This is **not applicable**, not declined", reasoning from a grep of
`settings/` for `COMMANDS` that genuinely does return nothing, and from `LandingRows` never being
called, which is genuinely true. `docs/adoption-prompt.md:438-446` has since been amended to carry a
"not applicable is not declined" paragraph naming ConsumableMaster as its worked example.

Both statements are individually true and the conclusion drawn from them is false. The landing page
reaches its command rows through `KCM.SlashCommands.GetCommandSummary()` (§4), so the absence of the
literal proved the opposite of what it was read to prove. The prompt's *original* sentence at
`:432-433` — "BankLedger, LootHistory and PanelMaster all change here; so do KickCD,
ConsumableMaster, prettychat and WhatGroup" — was correct, and the finding that called it a
misstatement was itself the misstatement.

The distinction the amended paragraph draws is sound and worth keeping. Only its worked example is
wrong.

### Why it matters, and what it costs

The prompt is the first artefact every future adopter reads and is described as authoritative about
what is already known. As it stands it teaches the next adopter that a host reaching its landing rows
through a helper function counts as "not applicable" — which is exactly how this one got missed, and
is a reasoning error that will reproduce. It also means the frozen 2026-08-01 bundle contains a
correction that made the record less accurate than the thing it corrected, so a reader trusting the
newer document is worse off than one trusting the prompt.

Note that this and §4 are one fact seen from two repos: the consumer has an undocumented decline, and
the library's own artefacts assert it has nothing to document. Fixing either without the other leaves
the contradiction standing. The fix is cheap — replace the worked example; the paragraph's argument
survives intact — and whoever makes it should heed the `sed -i` CRLF hazard the prompt itself warns
about at `:479-481`.

### Evidence

§6.3, §11.4.

---

## §6 — The Options canvas contract has four beneficiaries and one guard

**Deliberate:** the change was. Its universality was the point. **Recorded:** in the CHANGELOG and
in BankLedger's LIBKA0S-24; the coverage gap is not recorded anywhere. **Severity:** medium.

### What

Options minor 5 stamps `OnCommit`, `OnRefresh` and `OnDefault` on every frame `CreatePanel` builds.
Unlike the other three v1.2.0 additions this is not opt-in, so all four consumers silently gained a
working Blizzard Settings-window footer Defaults control they never asked for — the CHANGELOG records
it as having been dead for every consumer until minor 5. All four park `defaultsOnClick`
(`AbsorbTracker/settings/{Border,Font,Bar,General}.lua`, `BankLedger/settings/Panel.lua:52`,
`ConsumableMaster/settings/Panel.lua:317`, `KickCD/settings/{Icons,Label,Castbar,General,Spells}.lua`),
so all four depend on the forwarder at `LibKa0s/Options.lua:226-231`.

Only BankLedger asserts any of it, at `tests/test_panel.lua:37-95`, and it had to use `rawget` to do
so — the frame mock synthesises a no-op function for any PascalCase key, which is how that host's own
earlier version of those cases managed to be vacuous. AbsorbTracker, ConsumableMaster and KickCD
contain zero references to `OnCommit`, `OnDefault` or `OnRefresh` anywhere, tests included.

### Why nothing has caught it

A surface nobody had to opt into is a surface nobody had to think about. Three hosts gained
behaviour without touching a file, so there was no moment at which writing a case would have
occurred to anyone.

### Why it matters, and what it costs

If a future minor turns the forwarder back into a plain assignment — `panel.OnDefault =
panel.defaultsOnClick`, which captures `nil` because hosts park the handler *after* `CreatePanel`
returns, and which is the exact mutation BankLedger's LIBKA0S-25 verified against — three of the four
suites stay green and three addons lose a footer control they never knew they had. The failure is
silent, in-game only, and would be attributed to Blizzard long before it was attributed to a library
minor.

### Evidence

§11.2 (item 4), §5.7.

---

## §7 — The provenance template still says v1.1.1, in both documents that carry it

**Deliberate:** no. **Recorded:** no. **Severity:** medium.

### What

`docs/releasing.md:62` gives the line to write into each consumer README as
"Bundles [LibKa0s](…) **v1.1.1** (MIT)." — five lines after `:7`'s own table cell states the current
repo semver as v1.2.0. `docs/adoption-prompt.md:398` carries the same stale template. All four
consumers already carry v1.2.0 in their README lines and in their bytes, so following the written
instruction today would downgrade four correct lines to wrong ones.

(`docs/adoption-prompt.md:393`'s "`LICENSE` ships inside the payload as of v1.1.1" is a historical
statement about when that started and is correct. `README.md:741-744`'s `MODULES` recital matches the
live constants.)

### Why it matters, and what it costs

Step 7 explicitly requires bumping the provenance version in the same commit as the copy, on the
grounds that the version and the bytes must move together or the line stops being true. The step's
own reference text is the thing that is wrong, so the failure mode is a maintainer doing exactly as
told and silently un-fixing a correct provenance line — and that line is the fastest answer a
re-vendor sweep has, the artefact §1 above shows is already carrying more weight than it can bear.

### Evidence

§10.6.

---

## §8 — Perf ships roughly 980 lines whose entire imperative API has no direct host caller

**Deliberate:** yes, by design — the module is meant to be driven through one verb. **Recorded:**
the design is; the coverage consequence is not. **Severity:** medium.

### What

Across all four consumers the only Perf members any host touches are `Perf.Note` (the hot-path sink),
`Perf.OnCommand` (the string-dispatched slash entry point) and the plain flags `on`, `run` and
`suspended`. A grep for `Perf\.(Measure|Context|Progress|Cancel|Start|Reset|Save|Resume|ShowPanel|
TogglePanel|HidePanel|IsPanelShown|Log|Announce|MarkReviewed|StatusLines|FormatReport|BuildRecord|
EncodeJSON)` returns nothing outside `libs/` and `tests/`. `lib.EncodeJSON`, `lib.DEFAULT_RING`,
`lib.SCHEMA`, `P.BUCKET_ORDER`, `P.LABELS`, `P.EXPERIMENTS`, `P.STEPS`, `P.PanelStateOf` and
`P.PanelIsActionable` have no consumer references of any kind, and the PerfPanel descriptor's `ring`
field is passed by nobody. `Perf.lua` is 982 lines and `PerfPanel.lua` 247.

### Why it matters, and what it costs

This is not a defect. It is worth writing down because three-of-four Perf adoption reads as broad
coverage and is not: the three adopting hosts are contract-testing one entry point, not an API. A
signature change anywhere in the capture, panel or report surface cannot break a host, and equally
cannot be caught by a host suite — everything reaches it through string dispatch. Anyone reasoning
about Perf's blast radius from the Consumers table will overestimate it in both directions.

### Evidence

§5.8.

---

## §9 — The Consumers table omits AbsorbTracker's second Slash wiring, which is on the surface Slash minor 5 changed

**Deliberate:** the code is — a clean fallback-guarded lookup. The omission from the table is not.
**Recorded:** no. **Severity:** low.

### What

`docs/releasing.md:152`'s `LibKa0s-Slash-1.0` row names only `settings/Slash.lua` for AbsorbTracker.
There is a second lookup at `AbsorbTracker/settings/Schema.lua:182` —
`local SlashLib = LibStub and LibStub("LibKa0s-Slash-1.0", true)` — stashed at file load and used by
`NS.FormatSchemaValue` at `:190` to call `SlashLib.FormatValue(row, v)`. That is exactly the function
Slash minor 5 extended with the optional `format` descriptor hook, and it is reached on the write
seam every panel widget and every `/at set` goes through.

### Why it matters, and what it costs

`docs/releasing.md` calls the per-module column "which hosts' descriptors a change to one module can
reach" and warns that a stale row means a consumer silently misses a re-vendor. The repo is not
missed here — AbsorbTracker is in the row — but the file most affected by a `FormatValue` change is
not the file the checklist points a reviewer at. The call is guarded (`if SlashLib then`), so a
missing library degrades rather than errors; the bounded damage is a silently wrong rendered value,
not a Lua error.

### Evidence

§4.1, §4.5.

---

## §10 — `docs/releasing.md` says only AbsorbTracker decorates the library instance; KickCD does too

**Deliberate:** no. **Recorded:** no. **Severity:** low.

### What

`docs/releasing.md`'s Consumers section says AbsorbTracker's `settings/UnitPanel.lua` "is the one
non-obvious entry: it decorates the library instance itself — `NS.Helpers` IS the `lib:New` return,
not a wrapper", and adds that "a change to the Options instance surface can therefore collide with a
host member, which no other module can do."

KickCD has exactly that shape. `settings/OptionsSetup.lua:224` assigns
`NS.Settings.Helpers = lib:New(descriptor)`, the file header at `:12-17` states the rule explicitly
("Never a fresh table that copies members across"), and `settings/Panel.lua`, `Panel_Widgets.lua` and
`Panel_Render.lua` decorate that same instance in place with roughly twenty host members —
`RenderUnitPanel`, `PartitionUnitRows`, `ResetAllPositions`, `RestoreUnitLinks`, `AnchorValues`,
`SchemaForPanel`, `SetAndRefresh`, `Resolve`, `FindSchema` among them.

### Why it matters, and what it costs

Whoever adds a member to the Options instance surface reads this paragraph and checks one host's
decorations when there are two, so the collision surface is doubled and the "no other module can do"
claim is stale. A collision in KickCD would land on a page renderer and would be silent: a host
member shadowed by a library one of the same name.

### Evidence

§4.2, §5.3.

---

## §11 — Three `L`-trap coverage gaps, and a prompt claim that no consumer honours

**Deliberate:** the individual absences mostly are, and two are reasoned in-file. The prompt's claim
is simply inaccurate. **Recorded:** AbsorbTracker's Core gap is recorded; BankLedger's Options gap
and ConsumableMaster's missing source guard are not. **Severity:** low, and entirely
forward-looking.

### What

The trap itself is avoided everywhere, and the earlier run's §2 is closed — every consumer now
carries `^[A-Z][A-Z0-9_]+$` assertions on rendered strings. Three residual gaps remain, all of the
same kind: the substitute the prompt prescribes for a major that *cannot* express the trap.

- **AbsorbTracker — Core.** The one adopted major with no rendered assertion and no tripwire; covered
  by the source check alone. Correct today, since `LibKa0s/Core.lua` ships no `STRINGS` table, and
  recorded rather than omitted at `tests/test_ltrap.lua:30-33`.
- **BankLedger — Options.** Rendered assertions for DebugLog and Slash, a tripwire for Core at
  `tests/test_libka0s.lua:208-218`, nothing for Options. The Core tripwire's shape does not transfer:
  it asserts `rawget(lib,'STRINGS') == nil`, and Options *does* ship `lib.STRINGS`
  (`libs/LibKa0s/Options.lua:71`), so an Options tripwire would have to assert the source names no
  `d.L` read. Nothing in the repo or its 25-row ledger says the substitute was considered.
  Separately, the source guard's `SEAM_FILES` list omits `settings/OptionsSetup.lua` — defensible,
  since Options reads no `d.L` and an `L` there would be inert.
- **ConsumableMaster — no source guard at all.** The rendered half is 5 of 5, but the prompt's points
  3 and 4 also ask for a matcher grepping the seam files for a descriptor handed the locale table,
  driven against all three spellings. No such case exists; `tests/test_slashsetup.lua:87-89` and
  `tests/test_debuglog.lua:264` discuss the hazard in comments and assert on rendered output only.

And the claim: `docs/adoption-prompt.md:112-113` states that "AbsorbTracker, KickCD and
ConsumableMaster all carry that substitute; copy one." A grep across all four consumers' `tests/`
for an Options tripwire returns exactly one hit, and it is an unrelated comment at
`AbsorbTracker/tests/test_helpers.lua:838`. For Core the claim holds only for KickCD and BankLedger;
for Options it holds for nobody. AbsorbTracker in fact ships something *stronger* than the prescribed
tripwire for Options — a real rendered assertion on `lib.STRINGS.DEFAULTS_LABEL` read back off the
built Defaults button, with an explicit non-vacuity coupling at `tests/test_helpers.lua:850-852` —
and nothing at all beyond the source check for Core. The prompt is wrong in both directions.

### Why it matters, and what it costs

Low today, and bounded by the fact that the surfaces genuinely cannot fire: `LibKa0s/Core.lua` has no
`STRINGS`, and `libs/LibKa0s/Options.lua` contains no `d.L` read. The cost is the one the prompt
itself names — the trap being currently avoided is worth much less than it being pinned, because
nothing stops the next library minor from reintroducing the surface, and Options is where raw
`SCREAMING_SNAKE` keys would be most visible to a user. This is the one failure in the whole exercise
with a shipped-broken precedent.

The larger cost is to the prompt. An adopter told to "copy one" from three named repos will find no
such case in any of them and will either invent one or skip it. This gap is collection-wide rather
than any single host's, and should not be scored against BankLedger or ConsumableMaster alone.

### Evidence

§7.1, §7.2, §7.3.

---

## §12 — Two consumer ledgers now misstate present fact

**Deliberate:** no, in both cases — documentation drift, where the work was completed after the row
was written and the row was never revisited. **Recorded:** the rows *are* the record, and the records
are wrong. **Severity:** low.

### What

**AbsorbTracker has no ledger entry for the v1.2.0 re-vendor, and LIBKA0S-01 is now stale history.**
`docs/pending/LEDGER.md` ends at LIBKA0S-05; there is no LIBKA0S-06. Worse, LIBKA0S-01 still asserts
in the present tense that the repo is re-vendored from "LibKa0s v1.1.0 … All eight minors unmoved
(Core 2, DebugLog 3, Slash 4, Options 4, OptionsWidgets 4, OptionsScroll 2, Perf 5, PerfPanel 3)".
Four of those eight numbers are now wrong, and a reader trusting the ledger over the source would
conclude this host is a release behind when it is current. The re-vendor itself was done carefully —
four separate, individually titled commits (ebaad1e, 87eda52, 6d32bd4, 39620b4) with a clean tree —
so only the ledger step was skipped.

**BankLedger's LIBKA0S-06 describes a deviation that no longer exists.** `docs/pending/LEDGER.md:54`
still carries status `deferred` and the sentence "this repo has **no `.gitattributes` at all** and
its working tree is pure LF", closing with "Adding the pin is a repo-wide working-tree change well
outside this adoption and is the user's call." Both halves are false. `git ls-files .gitattributes`
returns the file, `git log` shows commit 9325663 "chore(repo): pin CRLF line endings, per the Ka0s
WoW Addon Standard", the file pins `* text=auto eol=crlf` identically to the library's, and `file -b`
reports CRLF for `core/CoreSetup.lua`, `settings/Slash.lua`, `README.md` and `docs/test-cases.md`.
The item was **done**, not deferred. Every other superseded row in that ledger (LIBKA0S-19,
LIBKA0S-20) is correctly struck through with a "SUPERSEDED by" pointer and the superseded text
preserved; this one was missed.

### Why nothing has caught it

Nothing reads a ledger mechanically. Both repos' suites, lints and diffs are green and would be green
regardless of what the ledger says, which is the whole reason the ledger exists as a separate
artefact — and the whole reason it decays silently.

### Why it matters, and what it costs

Zero at runtime in both repos: AbsorbTracker's `README.md:143` is correct at v1.2.0, and BankLedger's
byte diff is clean and its working tree correctly pinned. The cost lands on the next reader. In
AbsorbTracker the artefact designed to answer "what was decided and when" now disagrees with the
source about which release is vendored, and the only accurate record is four commit subjects. In
BankLedger — the collection's best ledger, and the one `docs/adoption-prompt.md` holds up as making a
decision auditable rather than merely inspectable — a maintainer auditing open deferrals gets a wrong
count and may spend time pinning something already pinned. A row that misstates present fact costs
more than its size suggests, because it is the artefact whose only value is being trusted.

### Evidence

`_raw/consumer-AbsorbTracker.md` §5 and §1; `_raw/consumer-BankLedger.md` §2 and §5c; §3.5.

---

## §13 — Core's window chrome is shipped and used by nobody

**Deliberate:** yes, on every consumer's side, and three of the four wrote the decline down.
**Recorded:** the declines are (BankLedger LIBKA0S-05, ConsumableMaster `modules/DebugLog.lua:167`);
the resulting library-side question is not. **Severity:** low.

### What

`lib.SKIN`, `lib.ApplySkin`, `lib.MakeCloseButton` and `lib.SECRET` have no direct consumer anywhere
across the four addons. Every `SKIN` / `ApplySkin` / `MakeCloseButton` hit in the four repos belongs
either to BankLedger's own Browser module or to a comment explaining a decline. Core's
`MakeCloseButton` is reached only indirectly, through DebugLog's forwarder, by AbsorbTracker, KickCD
and ConsumableMaster via the console instance; BankLedger declines even that.

Per the method this scores as faithful adoption rather than shortfall — the skin half is explicitly
declinable. The net effect is still that four of Core's public members are dead in the field.

### Why it matters, and what it costs

Nothing today. It matters because DebugLog minor 4 added `applySkin` and `makeCloseButton` precisely
to let a host route around this chrome, so the chrome now has a documented escape hatch and no users,
and the next adopter with its own window style has no reason to take it either. That deserves an
explicit decision — is Core's skin half a supported surface, or a default nobody is expected to keep?
— rather than continuing to accrete declines against it.

### Evidence

§5.6, §5.1.

---

## §14 — Nine further public surfaces have one consumer; four have none

**Deliberate:** varies. Two are recorded declines; most are simply where the collection happened to
land. **Recorded:** individually in some cases, never as a pattern. **Severity:** low.

### What

Beyond the four v1.2.0 additions of §3: `O.PatchAlwaysShowScrollbar` (KickCD only, at
`settings/Panel.lua:384` and `settings/Spells.lua:903` — the sole public function of an entire
vendored file, `OptionsScroll.lua`, and the one call path hands it a container the host built itself
rather than the library's `EnsureScroll` result); `Sl:BuildListLines`, `Sl:CliResetAll`,
`Sl:CliVersion` and `O.__panels` (BankLedger only); `Sl:SetRowAnnotator` and direct `lib.FormatRow`
(AbsorbTracker only); `d.sliderCommit` (ConsumableMaster only).

Zero consumers: `lib.FormatKV`, `lib.MAX_BUFFER`, `Sl:HelpHeader`, `Sl:HelpRows` called by name,
`D:LastLine`, `O.__pages`, the `skin` descriptor field and the `ring` descriptor field. `HelpRows` is
the notable one — every host reaches it through `PrintHelp`, so the indented half of the row-formatter
pair has no caller anywhere outside the library, and the only textual hits in the collection are
inside KickCD's own degradation stub.

Two of the one-consumer entries carry their own history. **`lib.FormatRow` called directly** is
AbsorbTracker's, at `settings/Slash.lua:33` for seven host-owned `/at profile` sub-rows the library's
`COMMANDS` table cannot hold — a legitimate use, explained at `:29-31`. It makes AbsorbTracker the
only host that a change to `FormatRow`'s signature or colour codes can break without also breaking a
convergence, and the only host whose degraded stub reimplements the format string (`:384`, `:397`) —
a second copy of the one formatter the convergence exists to eliminate. **`RenderGrid`** is the
earlier run's §7, now partly closed: AbsorbTracker adopted it this cycle (ledger LIBKA0S-02, at
`settings/UnitPanel.lua:143`, retiring a verbatim hand-rolled copy of the flow engine), so it has
three consumers. KickCD declines it, deliberately and exhaustively, at ledger LIBKA0S-04 (`wont-do`)
with a three-part not-expressible verdict: it takes no `parent` and hard-binds `EnsureScroll`
(`OptionsWidgets.lua:550`) against `settings/Spells.lua:888-904`'s own ScrollFrame; it offers only
half or wide cell widths against an eight-column tuned pixel strip; and it fires
`AddSpacer(ROW_VSPACER)` unconditionally against two deliberately gapless lists. Two of those are now
carried upstream as known library gaps and tracked at KickCD issue #10.

### Why it matters, and what it costs

The shape is what is worth recording. The page-registry half of Options
(`RegisterOptionsPage` / `SetRenderer` / `RefreshScalars` / `__panels`) and the schema-CLI tail of
Slash (`BuildListLines` / `CliResetAll` / `CliVersion`) are each carried by two hosts at most, and
the two hosts differ per surface — so no single consumer's suite covers either half, and a change to
either has to be reasoned about rather than tested. The remaining unadopted targets split the same
way: PanelMaster and WhatGroup will exercise the registry, prettychat and WhatGroup the CLI tail.
`CliResetAll` in particular has one consumer that wraps it in its own `NS.Panel:Batch`, so the
unbatched path — every row through the write seam, one refresh each — has never been run by anyone.

### Evidence

§11.1, §5.6.

---

## §15 — AbsorbTracker's vendor-drift gate is still absent from `docs/testing.md`

**Deliberate:** no — an omission that has now survived two adoption reports. **Recorded:** partly.
`CLAUDE.md:34-46` states the *rule* ("`libs/LibKa0s/` is vendored … Never edit it here — change it
upstream and re-vendor", and the same for `tests/_kit/`). What is missing is the *check*.
**Severity:** low.

### What

`docs/adoption-prompt.md` step 9 requires the four diffs to be written into `docs/testing.md` "with
what each answer means", on the stated grounds that `docs/testing.md` documents the green gates and
none of them can see a stale vendored library. `grep -n 'diff -r' docs/testing.md` returns nothing;
the only diff documented there is the test-case-list sync at line 120. ConsumableMaster has since
added exactly this block (`docs/testing.md:26-40`, both readings and the correct fix), and BankLedger
carries it too, so AbsorbTracker is now the odd one out on a step its siblings have taken.

### Why it matters, and what it costs

Zero right now, because this run establishes the copies are byte-identical. It is a latent cost, and
the failure it guards against has already happened to this exact addon — `docs/releasing.md` records
that "a fix landed here, AbsorbTracker was not re-vendored, and both repos' test suites stayed green
the whole time". A maintainer reading `docs/testing.md` for "what do I run before I ship" gets a
complete-looking answer that cannot detect it.

### Evidence

`_raw/consumer-AbsorbTracker.md` §8.

---

## §16 — The documented `luacheck` gate covers less than it reads

**Deliberate:** yes — every `.luacheckrc` sets the exclusions on purpose. **Recorded:** partly. The
exclusions are visible in each `.luacheckrc`; no document that quotes the gate says what it does not
reach. **Severity:** low.

### What

`docs/releasing.md:17` and `docs/adoption-prompt.md:564` both quote the gate as a bare `luacheck .`
producing "0 warnings / 0 errors", which reads as repo-wide. It is not, in any repo. The library's
`.luacheckrc:4` carries `exclude_files = { "tests/", "docs/" }`, so its 0/0 covers eleven files — the
eight ship files plus three under `testkit/` — and the twenty-one files under `tests/`, including the
suites, the fixtures, `wow_mock.lua` and the vendored `tests/_kit/` copies, are never linted there.
Every consumer excludes `libs/`; BankLedger also excludes `tests/`.

Excluding vendored code is correct practice — it is not the host's code to lint — and the exclusions
are not the finding. The phrasing is.

### Why it matters, and what it costs

Small here, and nothing is currently hidden by it: all five repos report zero warnings. It matters
because the audit method asks warnings to be attributed to seam files versus pre-existing host
hygiene, and that attribution assumes the lint saw the files. Anywhere a figure is quoted as
repo-wide and is not, a future run will draw a conclusion the tool never supported.

### Evidence

§8, §10.3.

---

## §17 — No ship file carries a copyright header, and a naive grep says one does

**Deliberate:** likely. `LICENSE` was moved into the ship folder in 17d6137 so a whole-folder copy
carries the notice with no per-file step, and `CHANGELOG.md:166-167` (v1.1.1) records that per-file
headers were considered and declined because they would touch all eight files and bump all eight
minors for a change that alters no behaviour. **Recorded:** yes for the mechanism
(`docs/releasing.md:47-51`), yes for the decision (the CHANGELOG). **Severity:** low —
informational.

### What

`grep -c -i copyright LibKa0s/*.lua` returns 0 for seven of the eight ship files and **3** for
`DebugLog.lua`. Those three, at `:319`, `:324` and `:329`, are a `copyRight` local holding the Copy
button's x-offset — not a notice. The effective header count is zero of eight. `LibKa0s/LICENSE` is
present at 1084 bytes, is byte-identical to the repo root `LICENSE`, and reaches all four consumers'
`libs/LibKa0s/` by whole-folder copy, which the empty byte diffs prove.

### Why it is here at all

Nothing requires per-file headers and the MIT terms travel with the payload as a file, so this is not
a breach. It is recorded because the method asks for the count and because the obvious command
returns a false positive that a future run would otherwise inherit as "DebugLog has three" — the same
class of error as §5, where a grep result was read as evidence of something it did not establish.

### Evidence

§9.3, §10.5.

---

## What is not in this list

Named explicitly, because an unchecked area silently omitted reads as a clean one, and a deviation
list is where a reader is most likely to assume absence means health.

**No consumer failed to run.** All four suites and all four lint passes completed, so nothing in this
bundle's green-gate table is a gap dressed as a pass.

**Nothing here observes a running WoW client**, so no in-game deviation could have been found. The
footer Defaults control of §6, DebugLog's derived title-bar offsets, BankLedger's console wearing its
own chrome and the 24-wide close button's gap against Clear, BankLedger's two numeric rows drawing as
dropdowns, ConsumableMaster's About page rendering as its format string implies and `sliderCommit` at
60 Hz, KickCD's converged landing-row spacing, and the on-screen half of the `L` trap in every repo
are all invisible to a headless suite. Several of those are the *only* observable effect of a v1.2.0
change.

**No `docs/smoke-tests.md` was executed** in any repo, so the in-game steps the prompt's step 10
requires were not checked for presence or currency except in passing.

**No assertion anywhere was mutation-verified.** Four ledgers claim their cases were verified red
first; those claims were read, not reproduced, because reproducing them requires editing a repo and
this audit is read-only. A vacuous assertion would therefore not appear above — and BankLedger's own
LIBKA0S-25 is a worked example of exactly that having happened once.

**The degraded-install path was exercised only where a host's own suite does it.** No run renamed
`libs/LibKa0s` aside and reloaded.

**How the ship-side CRLF condition was fixed could not be established**, so §3 of the continuity
table above is a statement about current state and not about cause.
