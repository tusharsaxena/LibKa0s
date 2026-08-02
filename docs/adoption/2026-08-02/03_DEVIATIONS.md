# Deviations — 2026-08-02

One section per deviation: what it is, where it binds with file:line, whether it is deliberate,
whether it is recorded, and what it costs. Evidence in `05_EVIDENCE.md`.

**Nothing in this file is a code defect in a consumer.** No consumer is behind a minor, no `libs/`
folder has forked, no descriptor is mis-passed, no gate is red. Every deviation below is either a
question about the library's own contract surface or a stale claim in the library's own documents.
That is worth saying plainly, because the shape of this run is unlike the two before it.

---

## §1 — `makeCloseButton` has zero shipped consumers

**Severity: Medium. Deliberate on the hosts' side, recorded in both. The finding is upstream.**

`makeCloseButton` was added in DebugLog minor 4 alongside `applySkin`, both defaulting to minor 3's
behaviour, specifically so BankLedger and LootHistory could keep their 24×24 class-coloured close
button while still adopting the module. Today **no consumer passes it.**

Evidence (`05_EVIDENCE.md` §5): a search for the key across all eight consumers' production source
returns nothing. Both hosts that would carry it instead carry an explicit note where it used to be:

```
../BankLedger/core/DebugLogSetup.lua:111:  -- NO `makeCloseButton`. The console and the copy window are the LIBRARY's windows, so they wear
../BankLedger/core/DebugLogSetup.lua:116:  -- on a library-drawn window is the library's. `applySkin` above is the opposite case and stays.
../LootHistory/core/DebugLogSetup.lua:125:  -- NO `makeCloseButton`. The console and the copy window are the LIBRARY's windows, so they wear
```

LootHistory's ledger records the drop at `LIBKA0S-18` / `-19`. The cause was Core minor 3 making the
Ka0s edge the library's own default, at which point overriding the close button meant re-specifying
what the library already did. This is the system working: a host adopted an override, the library
absorbed the divergence, and the host dropped the override. Both hosts reached the same conclusion
and wrote down why.

**What it costs.** `makeCloseButton` is live code in a frozen `-1.0` major — `LibKa0s/DebugLog.lua`
lines 171, 257, 321, 462 — reachable, documented, and impossible to remove inside this major. Its
override path is exercised by the library's own suite in six cases (`tests/test_debuglog.lua:672`,
`686`, `699`, `721`, `736`, `742`), including the nil-return and stub-frame arms, so it is not
untested. What it lacks is a *host shape*. The report's rule that a one-consumer surface is a
finding rests on the contract having been tested against exactly one real need; a zero-consumer
surface has been tested against none, and its shape is now fixed by nothing but the library's own
assumptions about what a host would want.

This is not urgent and it is not a correctness problem. It is a question worth asking once, on the
record, while the answer can still inform a `-2.0` conversation: **is `makeCloseButton` still
earning its place in the contract, now that the reason it was added has been absorbed into Core's
default?** `applySkin`, its twin, is the opposite case — two consumers, both still passing it, both
for the reason it was added.

---

## §2 — The "Provisional surfaces" section is stale in three entries

**Severity: Medium. Not deliberate. This is the document a new adopter reads to learn what is
unsettled.**

`docs/adoption-prompt.md:755` opens *"Provisional surfaces — one consumer each, and treated as
unsettled"*. Three of its entries no longer say what is true, and — unusually — they are wrong in
both directions, so a reader is over-cautious in two places and under-cautious in one.

**a. `applySkin` / `makeCloseButton` (line 764).** Reads *"One implementation behind them."*
`applySkin` now has **two** (BankLedger, LootHistory) and `makeCloseButton` has **zero** (§1). The
paragraph's operative instruction — *"If you are the second host to touch one of these, treat a
misfit as a library gap on first contact"* — has already been discharged for `applySkin`: LootHistory
*was* the second host, and `docs/releasing.md` records that it asserted the derived title-bar offsets
rather than assuming them. The prompt still tells a ninth adopter it would be the second.

**b. The numeric-enum dropdown (line 779).** Listed as single-consumer. It now has **two**,
BankLedger and LootHistory, at `../BankLedger/settings/Schema.lua:76,83` and
`../LootHistory/settings/Schema.lua:61,70`.

The entry's substantive warning is *still accurate and still worth keeping*: the route is inferred
from a `values` list on a `type="number"` row (`LibKa0s/OptionsWidgets.lua:466`), not opted into, so
any existing number row that grows a `values` key silently reclassifies from slider to dropdown. The
sentence *"KickCD's 31 number rows all carry min/max/step today; the first one to gain a list flips"*
was verified this run and holds — KickCD has 31 number rows and none carries `values`. So does the
clause that the route has never been rendered alongside `sliderCommit`: ConsumableMaster is the one
`sliderCommit` host (`settings/Panel.lua:226`), has 22 number rows, and **zero** carry a `values`
list. Only the consumer count is wrong.

Worth noting for whoever corrects it: both consumers spell `widget = "Dropdown"` on those rows *as
well as* `values`. The library never reads `widget` — it is host vocabulary — so neither consumer has
actually tested the inference in isolation. The inference hazard is real and remains untested by any
host.

**c. The `format` hook (line 771).** The entry is now mostly current — it was updated to record
prettychat as the second host and the first to use `format` on a row the library can already render.
It has three consumers (BankLedger, LootHistory, prettychat) and no longer belongs under a heading
reading "one consumer each". Its remaining live claim is the precedence question, which is §4.

**What it costs.** Every adopter is told to read this section before planning around a surface. It
currently overstates the risk on `applySkin` and the numeric enum — inviting a ninth adopter to
treat settled contracts as unsettled — while saying nothing about the one surface that has lost all
its consumers. Since no adoption targets remain, the audience for this document is now a *re-vendor*
or a `-2.0` planner rather than a new adopter, which changes what it needs to be accurate about.

---

## §3 — The additive-change proof names four consumer suites where there are eight

**Severity: Medium. Not deliberate. This one has a mechanism behind it.**

`docs/adoption-prompt.md:610-613`, inside step 8 of "When the library itself has to change":

```
   above is not a formality. Check "Provisional surfaces" before deciding a three-suite run was
   proves your "additive" change was additive. At the time of writing: **AbsorbTracker 467**,
   **KickCD 646**, **ConsumableMaster 559**, **BankLedger 685**, each 0 failed.
```

Two problems, and the second is the serious one.

**a. All four totals are stale, each by +2.** Measured this run: AbsorbTracker **469**, KickCD
**648**, ConsumableMaster **561**, BankLedger **687**. The uniform +2 is consistent with the
`test_vendor_sync.lua` pair every consumer gained. The prompt anticipates exactly this drift at line
625 — *"they go stale every time an addon adds a test of its own… and a stale figure here reads as a
regression that is not one"* — and instructs the reader to take the current number from the addon's
own `docs/test-cases.md` first. So the guidance is right and only the figures are old; a careful
reader is protected.

**b. The list is half the fleet.** This is not protected by that guidance. Step 7 immediately above
says *"Re-vendor into EVERY consumer, not just this addon. The consumer list is in
`../LibKa0s/docs/releasing.md`. It starts at AbsorbTracker and grows by one every time an addon
completes this migration — so check it, do not assume it is still just the one."* Step 8 then hands
the reader a hardcoded list of four, and the surrounding prose reinforces it: *"Run all four, and
know which one is load-bearing"*, and at line 619 *"before deciding a three-suite run was enough"*.

A library author who follows step 8 literally re-runs AbsorbTracker, KickCD, ConsumableMaster and
BankLedger, and never runs LootHistory, PanelMaster, prettychat or WhatGroup. Those four hosts
between them are the **only** consumers of `applySkin`, the `format` hook, `sep`, `pairWith`, the
instance-member wrapping of `SetRenderer` / `EnsureDefaultsButton` / `RenderField` / `EnsureScroll`,
and four of the five `parse` adapters. A change that broke any of those would pass a four-suite run
green.

The step's own stated purpose is *"the step that proves your 'additive' change was additive"*, and
the paragraph at 615-620 makes the argument precisely: *"A surface with a single consumer is proved
additive by that consumer's suite and by nothing else — the other three stay green through a
regression in it, because they never call it."* That reasoning is correct and it now indicts the
list it is attached to.

**What it costs.** This is the one stale figure in this report with a plausible path to a real
defect. Everything else here is a document disagreeing with reality; this is a document that would
let a non-additive change ship green.

DebugLog minor 7 — cut during the WhatGroup adoption, after this list was last touched — was in fact
re-vendored to all seven other consumers correctly, and all eight suites are green today, so nothing
has been missed. The risk is prospective, not realised.

---

## §4 — The `format` × `colorDecode` precedence is unexercised, and the host sets are disjoint

**Severity: Low. Deliberate and recorded; the new information is why it will not resolve on its
own.**

`docs/adoption-prompt.md:771` records that the Slash `format` hook is documented to take precedence
over `colorDecode` and that *"that precedence has never executed"*. Still true. What this run adds is
the reason it is unlikely to change:

| Passes `format` | Passes `colorDecode` / `colorEncode` |
|---|---|
| BankLedger, LootHistory, prettychat | AbsorbTracker, ConsumableMaster, KickCD |

The two sets are **disjoint**, they partition six of the eight consumers, and the remaining two
(PanelMaster, WhatGroup) pass neither. Nor is any host near the boundary: prettychat passes no colour
codecs because it has *no colour rows at all*, and the three codec hosts render no set-valued or
escape-doubling rows that would want `format`.

The prompt's own guidance — *"the first host to pass both should assert it rather than assume it, and
if the assertion is awkward to write, that is the signal the ordering wants revisiting while it still
can be"* — assumes a first host will eventually arrive. With no adoption targets remaining, there is
no ninth consumer coming to supply one.

**What it costs.** A documented ordering in a frozen major that no shipped code executes.

**Correction, applied the same day, before this bundle was committed.** This paragraph originally
read "…that no shipped code executes **and no test in any repo pins**". The second half was false
when it was written. `tests/test_slash.lua:663` — *"slash: the format hook takes precedence over the
colour codec, and gets the raw stored value"* — has pinned the ordering at the **list echo** since
Slash minor 5 shipped (`git log -S` puts it in `1aab478`, the commit that introduced the hook), and
it was already inventoried at `docs/test-cases.md:158`. The audit asserted an absence without
grepping for the thing it claimed was absent.

What survives the correction is the host-side half, which is the substantive finding: **no shipped
addon executes this ordering**, because the `format` and `colorDecode` host sets are disjoint and no
ninth consumer is coming. And the coverage gap was real but narrower than stated — the ordering was
pinned at one of four echoes. The remediation run added `tests/test_slash.lua:683`, covering the
`get`, `set` and `reset` echoes and asserting that `colorEncode` still runs on the write side (the
documented precedence is over `colorDecode` **alone**, so a host that owns rendering has said
nothing about how its colour is stored). 419 → 420 cases, green.

---

## §5 — Three surfaces still have exactly one consumer

**Severity: Low. Not defects; recorded here because the report's scoring rule says to.**

| Surface | Sole consumer | Site |
|---|---|---|
| `sliderCommit` (OptionsWidgets 4) | ConsumableMaster | `settings/Panel.lua:226` |
| `pairWith` (OptionsWidgets) | prettychat | `settings/Panel.lua:77` |
| `sep` (Core) | prettychat | `core/CoreSetup.lua:103` |

**Corrected the same day, before this bundle was committed.** This table first listed `skin` as
BankLedger's, and `02_MATRIX.md` §5 put `sep` at two consumers. Both were artefacts of matching a
bare key name against local variables rather than reading the descriptors: `skin` has **zero**
consumers (every host falls through to `core.SKIN` at `LibKa0s/DebugLog.lua:195`), which puts it
alongside `makeCloseButton` in §1 rather than here, and `sep` has **one**. The `pairWith` site was
also corrected from `settings/OptionsSetup.lua` to `settings/Panel.lua:77`. See the correction note
in `02_MATRIX.md` §5.

Each has been tested against exactly one host shape, inside a major where an assumption baked in now
can be worked around but never renamed. None is currently misbehaving.

`sliderCommit` is the most considered of the three: ConsumableMaster's `settings/Panel.lua:419`
carries a comment explaining that the surface *"exists at all, so the Macro Bar page keeps its live
drag"*, which is the kind of recorded rationale that makes a single-consumer surface auditable rather
than merely lonely.

Note that this list is shorter than the equivalent list in the 2026-08-01 v2 run, which found four
single-consumer surfaces produced by one release. Two of those four (`applySkin`, the numeric enum)
have since gained a second consumer, and one (`makeCloseButton`) has lost its only one. That is the
population working as intended in two cases out of three.

---

## §6 — Two provenance lines are phrased mid-sentence

**Severity: Low. Deliberate, recorded, and already accounted for by the gate.**

`docs/releasing.md:96` templates the provenance line as a standalone sentence:

```
Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.5.0 (MIT).
```

LootHistory and WhatGroup both phrase it mid-sentence instead (*"…it bundles [LibKa0s](…) v1.5.0"*).
Both are true, both name the right version, and both are found by the `[Bb]undles` pattern the vendor
gate now ships with — a change made precisely because an earlier sweep anchored on a capital
`Bundles`, returned nothing for LootHistory, and wrongly reported it as having no provenance line at
all. That correction is recorded at `docs/adoption-prompt.md:364`.

**What it costs.** Nothing operationally. It is logged so that a future consistency sweep reading the
template as normative does not "fix" two correct lines, and so the `[Bb]` in the gate pattern keeps
its documented reason for existing.

---

## §7 — Stale version literal in two templates

**Severity: Cosmetic. Explicitly flagged as a template in both places.**

`docs/adoption-prompt.md:458` and `docs/releasing.md:96` both spell the provenance template at
**v1.4.0** while the ship version is v1.5.0. Both immediately say the version is *"whatever is being
released, not a literal to copy"*, and `docs/releasing.md:98` goes further: *"this template moves with
it rather than being corrected after the fact"* — which is an explicit statement that it did not
move. No consumer copied the stale literal; all eight name v1.5.0 correctly.

Logged only because `docs/releasing.md:99` states the template is supposed to move with each release
and it did not, so the rule and the artefact disagree about their own convention.
