# Adoption report — 2026-08-01 (run v2)

Run against LibKa0s at **v1.2.0** — Core 2, DebugLog 4, Slash 5, Options 5, OptionsWidgets 5,
OptionsScroll 2, Perf 5, PerfPanel 3, each read out of the ship folder rather than out of the
changelog. Method: `docs/adoption-report.md`.

This is the **second run of 2026-08-01**, convened after the v1.2.0 minor bumps to DebugLog, Slash,
Options and OptionsWidgets and after BankLedger landed as the fourth consumer. The earlier run of
the day is `docs/adoption/2026-08-01/`; it is referred to below as the v1 run. Nothing here is
inherited from it — every figure was re-established from evidence, including the figures that have
not moved.

## Verdict

**The question this run was called to answer comes back clean: nothing is behind.** Thirty-two of
thirty-two file-minor cells — eight files across four consumers — sit at the current ship minors,
so there is no cross-major skew anywhere, which is the single most serious thing this report can
find and the failure mode whole-folder vendoring exists to prevent. All sixteen vendor diffs are
empty on both readings, byte and content, so nothing has forked and there is no line-ending
divergence left to adjudicate. Every consumer's gate actually runs green: 462, 643, 554 and 684
cases, zero failures, and 0 warnings / 0 errors from `luacheck` in every repo including this one.
Every consumer carries `LICENSE` inside `libs/LibKa0s/` and a README provenance line naming v1.2.0,
and every one of those lines is true rather than merely present.

What the run found instead is that **the library's own record of v1.2.0 is incomplete in the two
places a stranger would look**. `git tag` in this repo lists v1.0.0, v1.1.0 and v1.1.1 and nothing
else; `git describe --tags` reads `v1.1.1-7-g8d1d879`. Four published addons name a release that
does not resolve to a ref, and the vendored bytes prove they really are carrying it. Alongside that,
`docs/adoption-prompt.md` — the document dropped into a fresh session to start an adoption — still
lists BankLedger as a remaining target in four places, including the step that tells a library
author which suites to re-run to prove a change was additive. `docs/releasing.md` was moved for
BankLedger in three commits; the prompt was not. The code is right and the map is wrong.

The third high finding is about shape rather than bookkeeping. **All four of v1.2.0's additions were
driven by BankLedger, and three of the four are called by BankLedger and nobody else** — the
DebugLog `applySkin`/`makeCloseButton` pair, the Slash `format` hook, and the numeric-enum dropdown
in `RenderField`. The report's own scoring rule treats a surface with one consumer as a finding
rather than a success, and this release produced four of them at once, inside a `-1.0` major where
an assumption baked in now can only be worked around, never renamed. The fourth addition, the
Blizzard canvas contract in `CreatePanel`, is the inverse problem: it is not opt-in, so all four
consumers silently gained a working footer Defaults control, and exactly one of them asserts it.

## Confidence

| Consumer | Grade | Why |
|---|---|---|
| **AbsorbTracker** | High | Eight of eight minors at ship, arrived as four legible re-vendor commits with a clean tree. All four diffs empty. Five majors wired, four of them carrying a rendered or library-regression `L` assertion on top of a source check that reads all five seam files and matches on what the expression *evaluates to*. Gate 462/0 and 0/0 in 28 files, with the suite total, `docs/test-cases.md`, the README badge and the prompt's quoted figure all agreeing at 462 — which is the evidence that v1.2.0 was additive here. Both convergences adopted. The residual gaps are documentation-shaped and bounded: no ledger entry for the re-vendor, no vendor-drift gate in `docs/testing.md`, no tripwire on Core. None is a divergence or a fork. |
| **BankLedger** | High | Current on all eight files, and current in the strong sense — it is the host three of v1.2.0's four changes were made *for*, so a skew here would have removed features nothing else uses. All four diffs empty, and clean by construction rather than by luck: it now carries its own `.gitattributes` pinning `* text=auto eol=crlf` byte-identically to the library's. Four majors wired exactly where `docs/releasing.md` says, and the Perf decline matches the table too. Gate 684/0 and 0/0 in 24 files with all four seam files inside the checked set. Every decline is recorded — Core chrome, `ConsoleCheckbox`, `LIST_GROUP_ORDER`, Perf, three Options surfaces — and both convergences are adopted and recorded. |
| **KickCD** | High | Eight of eight at ship, each v1.2.0 bump its own commit, tree clean. All four diffs empty; the v1 run's LF drift on this consumer is gone. Five majors wired, each with a seam test, and the `L` guard covers 5 of 5 module-adoptions with a source matcher that carries its own three-spelling non-vacuity case — which matters here more than anywhere, because KickCD's one real descriptor `L` is the legitimate `and … or nil` form, one typo from the live trap. Gate 643/0 and 0/0 in 32 files, against 7 warnings at the v1 run. Both convergences adopted, with the destructive `resetall` keeping its confirmation on both entry points. Its one open item is a decline recorded in writing with a three-part technical verdict. |
| **ConsumableMaster** | Medium | Everything the High row asks for is present: minors current, all four diffs empty, five majors wired at the documented file:line, 5 of 5 module-adoptions guarded, gate 554/0 and 0/0 in 50 files, provenance line true. It falls to Medium on one named, bounded gap, which is the exact case the method's Medium row describes — **convergence #2 is declined and written down nowhere**. `settings/Panel.lua:770` installs the landing renderer and `:718-729` draws command rows through the host's own formatter, while the chat half is already pinned byte-for-byte against `lib.FormatRow`, so this host carries the two-divergent-formatters state the convergence exists to collapse. It is not Low: no skew, no fork, no unguarded seam, and the convergence that *was* a finding last run is now adopted and recorded twice over. |

No consumer is Low. **Nothing in this report is a runtime defect in any consumer.**

## Findings, ranked

### 1 — v1.2.0 has shipped into four addons but was never tagged

`git tag` returns v1.0.0, v1.1.0 and v1.1.1; `git describe --tags` is `v1.1.1-7-g8d1d879`, so HEAD
sits seven commits past the last tag — the four minor bumps and their `docs/releasing.md` entries.
Meanwhile `CHANGELOG.md:13` heads a `## v1.2.0 — 2026-08-01` block whose eight named minors match
the eight live constants file for file, and all four consumer READMEs say "Bundles LibKa0s v1.2.0
(MIT)" at `AbsorbTracker/README.md:143`, `KickCD/README.md:197`,
`ConsumableMaster/README.md:274` and `BankLedger/README.md:11`.

Steps 1–5 and 7 of `docs/releasing.md` were all executed; only step 6's tag is missing. The claim is
stronger than the READMEs alone would make it — `diff -r` between the ship folder and each
consumer's `libs/LibKa0s/` is byte-empty in all four cases, so each addon genuinely contains the
v1.2.0 payload rather than merely naming it. The cost is that the provenance line, the one artefact
that answers "which LibKa0s does this addon carry?" without grepping eight constants, currently
answers with a string nobody can check out. See `03_DEVIATIONS.md` §1.

**What to do:** `04_RECOMMENDATIONS.md` §1 — tag it today, before anything else in this bundle.

### 2 — `docs/adoption-prompt.md` still lists BankLedger as an unadopted target, in four places

Line 6 names three adopters, line 8 lists BankLedger first among remaining targets, line 303 carries
a live un-struck module-order row for it ending in "→ Perf" against a recorded structural Perf
decline, and line 538 quotes only AbsorbTracker 462 / KickCD 643 / ConsumableMaster 554 as the
suites to re-run to prove a library change additive. The filesystem says otherwise:
`ls -d ../*/libs/LibKa0s` returns four, BankLedger wires four majors, its vendored copy is at all
eight current minors, and its ledger runs LIBKA0S-01 through LIBKA0S-25. `docs/releasing.md` is
correct on every point, including the Perf omission and the prose note at line 177.

The three quoted totals are themselves still accurate, so this is a missing entry rather than a
rotted one — but the missing one is BankLedger's 684, the only suite that covers the four surfaces
this release added. Anyone following step 8 today re-runs three consumers and believes they proved
additivity. See `03_DEVIATIONS.md` §2.

**What to do:** `04_RECOMMENDATIONS.md` §3 (move the prompt to four consumers) and §4 (add
BankLedger 684 to the additive-change proof, and say why it is the load-bearing one).

### 3 — Every v1.2.0 addition has exactly one consumer, and it is the same one

`applySkin`/`makeCloseButton` (`BankLedger/core/DebugLogSetup.lua:111` and `:116`), the Slash
`format` hook (`settings/Slash.lua:198`) and the numeric-enum dropdown
(`settings/Schema.lua:76` and `:83` — the only `number`+`values` rows in the whole collection) are
each called by BankLedger and by nobody else. The library grew four contracts in one release against
one host's shape, and the prompt's own rule of thumb — one host's misfit is a setup-file concern,
two is a library gap — was satisfied by argument rather than by a second host.

The combinations compound the exposure. `format`'s documented precedence over `colorDecode` has
never executed, because BankLedger passes no `colorDecode`. Number-row dispatch has never been
rendered with both an enum and `sliderCommit`, because the one host with `sliderCommit`
(ConsumableMaster) has no enum rows. And the numeric dispatch is *inferred* from the presence of
`values` rather than opted into, so the first KickCD row to grow a `values` list flips from slider
to dropdown with no code change and nothing anywhere that would see it. LootHistory being next in
line makes this worse rather than better: it is BankLedger's architectural twin, so it will confirm
the contracts rather than stress them. See `03_DEVIATIONS.md` §3, and §14 for the nine older
surfaces in the same position.

**What to do:** `04_RECOMMENDATIONS.md` §12 — a decision rather than work, and the highest-leverage
one in the bundle.

### 4 — ConsumableMaster declines convergence #2, and the decision is written down nowhere

The landing page exists and renders command rows: `settings/Panel.lua:770` installs
`Helpers.BuildAboutContent` as the renderer for the panel `/cm config` opens, and `:718-729` draws
one Label per command through the host's own format string. `od -c` against
`LibKa0s/Slash.lua:69` confirms the divergence byte for byte — two spaces either side of the em
dash against one, the dash white-wrapped against bare, the description bare against white-wrapped —
which is verbatim the three differences `docs/adoption-prompt.md:427-432` describes. The chat half
is already converged and pinned at `tests/test_slashsetup.lua:57`, so this host carries exactly the
two-divergent-formatters state the convergence exists to eliminate.

`grep` over `docs/pending/LEDGER.md`, `CHANGELOG.md` and `README.md` for *landing*, *LandingRows*,
*FormatRow*, *BuildAboutContent* and *converg* returns only the two rows about the dispatcher and
about convergence #1. `git log -L 718,729:settings/Panel.lua` shows the formatter arriving whole in
`f844f78`, predating the adoption — so on the evidence it was never revisited rather than weighed
and kept. This is the *undocumented* half, not the *wrong* half: the divergence may well be right,
and an unrecorded decision is indistinguishable from an oversight to the next consistency sweep.
See `03_DEVIATIONS.md` §4.

**What to do:** `04_RECOMMENDATIONS.md` §5.

### 5 — The v1 bundle's §4 correction is wrong, and the prompt has been amended to match it

`docs/adoption/2026-08-01/03_DEVIATIONS.md` §4 concluded that ConsumableMaster has no landing page
carrying command rows, reasoning from a grep of `settings/` for `COMMANDS`, which genuinely returns
nothing. But this host reaches its command rows through `KCM.SlashCommands.GetCommandSummary()`, a
name that grep never sees, so the absence of the literal proved the opposite of what it was read to
prove. The prompt was then amended to carry a "not applicable is not declined" paragraph
(`docs/adoption-prompt.md:438-446`) with ConsumableMaster as its worked example.

The distinction the paragraph draws is sound and worth keeping; only its worked example is wrong,
and the original sentence it replaced was right. This finding and §4 above are the same fact seen
from two repos: the consumer has an undocumented decline, and the library's own artefacts assert it
has nothing to document. It is recorded here rather than quietly fixed because the frozen v1 bundle
now contains a correction that made the record less accurate than the thing it corrected, and a
reader trusting the newer document is worse off. See `03_DEVIATIONS.md` §5.

**What to do:** `04_RECOMMENDATIONS.md` §5 — the same proposal; it reverses the correction and
settles the convergence together.

### 6 — The Options canvas contract has four beneficiaries and one guard

Options minor 5 stamps `OnCommit`/`OnRefresh`/`OnDefault` on every frame `CreatePanel` builds, so
all four consumers silently gained a working Blizzard footer Defaults control that the CHANGELOG
records as dead for every consumer until this release. All four park `defaultsOnClick` and therefore
depend on the forwarder. Only BankLedger asserts any of it, at `tests/test_panel.lua:32-95`, and it
had to reach for `rawget` to do so because the frame mock synthesises a no-op for any PascalCase
key — which is how its own earlier version of those cases was vacuous. AbsorbTracker, ConsumableMaster
and KickCD contain zero references to `OnCommit`, `OnDefault` or `OnRefresh` anywhere, tests
included.

If a future minor turns the forwarder back into a plain assignment — capturing `nil`, because hosts
park the handler *after* `CreatePanel` returns, the exact mutation BankLedger's LIBKA0S-25 verified
against — three of four suites stay green and three addons lose a control they never knew they
gained. The failure is silent and in-game only. See `03_DEVIATIONS.md` §6.

**What to do:** `04_RECOMMENDATIONS.md` §8.

### 7 — The provenance template still says v1.1.1, in both documents that carry it

`docs/releasing.md:62` gives the line to write into each consumer README as "Bundles LibKa0s v1.1.1
(MIT)", five lines after the same file's own table cell says the current semver is v1.2.0.
`docs/adoption-prompt.md:398` carries the same stale template. All four consumers already carry
v1.2.0, so a maintainer following the written instruction today would downgrade a correct line to a
wrong one — and step 7 requires the provenance bump in the same commit as the copy, so the step's
own reference text is the thing that is wrong. See `03_DEVIATIONS.md` §7.

**What to do:** `04_RECOMMENDATIONS.md` §2. Mind the `sed -i` CRLF hazard the prompt itself warns
about when editing either file.

### 8 — Perf ships roughly 980 lines whose entire imperative API has no direct host caller

Across all four consumers the only Perf members any host touches are `Perf.Note`, `Perf.OnCommand`
and the plain flags `on` / `run` / `suspended`. A grep for `Measure`, `Context`, `Progress`,
`Cancel`, `Start`, `Reset`, `Save`, `Resume`, `ShowPanel`, `FormatReport`, `EncodeJSON` and the rest
returns nothing outside `libs/` and `tests/`; `lib.SCHEMA`, `lib.DEFAULT_RING`, `P.BUCKET_ORDER`,
`P.LABELS`, `P.EXPERIMENTS` and `P.STEPS` have no consumer references of any kind, and the
PerfPanel descriptor's `ring` field is passed by nobody.

This is not a defect — the module is designed to be driven through one verb — but it means the
whole capture, panel and report surface is reachable only by string dispatch, so a signature change
there can never be caught by a host suite. It is recorded so that nobody reads three-of-four Perf
adoption as broad coverage. See `03_DEVIATIONS.md` §8.

**What to do:** nothing. `04_RECOMMENDATIONS.md` carries it under *Not recommended*, with the
reasoning.

### 9 — Two rows in `docs/releasing.md` point a reviewer at the wrong files

Both are *incomplete*, not wrong, and both sit on the column the method calls the thing step 7 of a
release reads. The `LibKa0s-Slash-1.0` row names only `settings/Slash.lua` for AbsorbTracker, but
`AbsorbTracker/settings/Schema.lua:182` does its own `LibStub("LibKa0s-Slash-1.0", true)` and calls
`lib.FormatValue` at `:190` — precisely the function Slash minor 5 extended with the `format` hook,
reached on the seam every panel widget and every `/at set` goes through. Separately, the Consumers
prose says AbsorbTracker's `settings/UnitPanel.lua` "is the one non-obvious entry: it decorates the
library instance itself", and adds that no other module can collide with a host member that way.
KickCD has exactly that shape at `settings/OptionsSetup.lua:224`, decorated with roughly twenty host
members across three files, so the collision risk is doubled and the claim is stale. See
`03_DEVIATIONS.md` §9 and §10.

**What to do:** `04_RECOMMENDATIONS.md` §7.

### 10 — Three residual `L`-trap gaps, and a prompt claim that no consumer honours

The trap is avoided everywhere and now guarded nearly everywhere — this was the v1 run's §2 and it
is substantially closed. What remains is bounded and worth naming rather than rounding off. Neither
BankLedger nor any other consumer carries a tripwire for `LibKa0s-Options-1.0`; ConsumableMaster has
the rendered half at 5 of 5 majors but no source-level matcher, so a future `and`→`or` typo in a
descriptor `L` has nothing standing between it and the live trap; and AbsorbTracker's Core adoption
is covered by its source check alone, which is correct today and recorded at
`tests/test_ltrap.lua:30-33` rather than omitted.

The substantive item is that `docs/adoption-prompt.md`'s "Pinning it" point 2 states that
AbsorbTracker, KickCD and ConsumableMaster all carry the prescribed library tripwire for **both**
Core and Options, and tells the next adopter to copy one. A grep across all four suites finds no
Options tripwire in any of them. The claim is true for Core and false for Options, and correcting
the prompt is explicitly part of this report's value. See `03_DEVIATIONS.md` §11.

**What to do:** `04_RECOMMENDATIONS.md` §6 — correct the prompt first, then decide whether the
Options tripwire is required at all.

### 11 — Two consumer ledgers now misstate present fact

AbsorbTracker's `docs/pending/LEDGER.md:50` (LIBKA0S-01) still asserts in the present tense that the
vendored copy is v1.1.0 with "all eight minors unmoved (Core 2, DebugLog 3, Slash 4, Options 4,
OptionsWidgets 4, OptionsScroll 2, Perf 5, PerfPanel 3)". Four of those numbers are now wrong, and
the v1.2.0 re-vendor has no ledger row at all — the ledger ends at LIBKA0S-05. BankLedger's
`docs/pending/LEDGER.md:54` (LIBKA0S-06) still reads *deferred* and states the repo has "no
`.gitattributes` at all" and a "pure LF" working tree; `git ls-files` returns the file, commit
`9325663` added it, and `file -b` reports CRLF throughout. The item was done, not deferred, and
every other superseded row in that ledger is correctly struck through with a pointer.

Nothing is misrepresented to a user in either case, and the source is correct in both. The cost
lands on the next auditor: the artefact designed to answer "what was decided and when" disagrees
with the source about which release is vendored in one repo, and reports an open item as open in the
other. See `03_DEVIATIONS.md` §12.

**What to do:** `04_RECOMMENDATIONS.md` §9. Neither can be executed from this repo; both are asks of
a consumer.

### 12 — The remaining low findings, in one place

Five items that are each worth a sentence and none worth a section. **AbsorbTracker's vendor-drift
gate is still absent from `docs/testing.md`** — the rule is stated at `CLAUDE.md:34-46` but the check
is not, and the failure it guards has already happened once to this exact addon
(`04_RECOMMENDATIONS.md` §10). **The documented `luacheck` gate covers less than it reads**: this
repo's 0/0 is over 11 files, not the repo, because `.luacheckrc` excludes `tests/` and `docs/`, and
every consumer's gate is written against the same bare `luacheck .` phrasing (§11). **Core's window
chrome — `SKIN`, `ApplySkin`, `MakeCloseButton`, `SECRET` — has no real consumer at all**, and
DebugLog minor 4 has just given it a documented escape hatch, so the next adopter with its own
window style has no reason to take it either (§12). **Nine further public surfaces have exactly one
consumer and four have none**, with the page-registry half of Options and the schema-CLI tail of
Slash each carried by at most two hosts, and different hosts per surface (§12). And **no ship file
carries a copyright header**, which is a deliberate v1.1.1 decision recorded in the CHANGELOG — noted
only because a naive `grep -c -i copyright` reports three hits in `DebugLog.lua` that are a
`copyRight` local holding a button offset, a false positive a future run would otherwise inherit.
See `03_DEVIATIONS.md` §13 through §17.

## What moved since the 2026-08-01 v1 run

Re-verified rather than inherited. The v1 run recorded eight deviations.

**Fixed — five outright.** The `diff -r` gate no longer lies: all 60 tracked files in this repo are
CRLF in the working tree over LF blobs, and all sixteen consumer diffs are empty on both readings, so
ConsumableMaster's correct checkout now passes the gate that used to fail it. `L`-trap guard coverage
went from 1 of 15 module-adoptions to every consumer carrying rendered assertions, with three of the
four suites also carrying a source matcher that has its own non-vacuity case. ConsumableMaster's
unrecorded `reset` decline is converged, re-homed to `/cm resetall` with the confirmation dialog
intact, and recorded at LIBKA0S-12 plus a new `CHANGELOG.md` breaking entry. `LICENSE` now ships
inside `libs/LibKa0s/` in all four consumers, arrived by whole-folder copy, and all four READMEs name
the version they carry. KickCD's degradation clause went from zero shared sites to ten.

**Partly fixed — one.** `RenderGrid` gained a second consumer: `AbsorbTracker/settings/UnitPanel.lua:143`
joined ConsumableMaster, retiring a hand-rolled copy of the flow engine. KickCD declines it in
writing at LIBKA0S-04 with a three-part not-expressible verdict, two parts of which are now carried
upstream as library gaps.

**Persisting, in changed form — one.** The v1 run's §4 (the prompt wrong about ConsumableMaster's
landing page) was corrected, and the correction was itself wrong; the prompt has since acquired a
larger instance of the same class of error about BankLedger. That is findings 2, 4 and 5 above.

**New — everything else.** The untagged v1.2.0, the four one-consumer additions, the canvas
contract's single guard, the stale provenance template, the two stale ledger rows, and the
`docs/releasing.md` row omissions are all consequences of the day's own work: a release that shipped
and a consumer that landed, with the surrounding documents not yet moved to match. **Nothing that
was green at the v1 run has regressed.** In particular, the four suite totals the earlier run
recorded have either held or grown for reasons traceable to the hosts' own new cases, and no
consumer's total moved across the four re-vendor commits — which is what makes "v1.2.0 was additive"
checkable rather than asserted.

## What this report did not check

- **Anything in-game.** Eight of the deviations recorded here are only observable in a running
  client: the footer Defaults control all four consumers gained, DebugLog's derived title-bar
  offsets, BankLedger's console wearing its own chrome, the 24-wide close button's clearance against
  Clear, the two numeric rows drawing as dropdowns, the converged landing-row spacing, colour
  rendering, and the on-screen half of the `L` trap. Nothing in this bundle is evidence about live
  behaviour.
- **Any consumer's `docs/smoke-tests.md`.** All four were confirmed to exist; none was executed, and
  their steps were not read against the v1.2.0 surfaces. The degraded-install walk, the
  SCREAMING_SNAKE page sweep and the both-entry-points check on destructive verbs are exactly the
  checks a headless suite cannot reach.
- **Mutation verification of any assertion, in any repo.** Three consumers' ledgers claim their
  cases were verified red first. Those claims were read, not reproduced — mutating an assertion
  requires editing a repo, which this audit forbids. Where a case was suspected vacuous it was read
  for what it drives, which is weaker.
- **Lint over excluded trees.** `.luacheckrc` excludes `tests/` and `docs/` here and `libs/` and
  `tests/` in the consumers, so every 0 warnings / 0 errors in this bundle should be read as scoped
  to host source. No lint result exists for any suite, fixture or `wow_mock.lua`.
- **How the line-ending fix was made.** `git status` is clean and no commit in the last 25 is named
  as a renormalisation, so §3 and §10.1 establish the current state, not its cause.
- **Whether `origin/master` holds the same seven post-v1.1.1 commits.** `git status` reports
  up-to-date from local refs only; no fetch was run.
- **The four remaining unadopted targets** — LootHistory, PanelMaster, prettychat and WhatGroup —
  beyond confirming that none of them has a `libs/LibKa0s` directory. The recon in
  `docs/adoption-prompt.md` was not re-verified and its line numbers may have moved.

**No consumer failed to run.** All four suites and all four lint passes completed, so nothing in the
green-gate table is a gap dressed as a pass.
