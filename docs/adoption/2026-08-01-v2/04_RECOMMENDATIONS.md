# Recommendations — 2026-08-01 (run v2)

Second run of the day, taken after the v1.2.0 minor bumps to DebugLog, Slash, Options and
OptionsWidgets and after BankLedger's adoption landed as the fourth consumer. The earlier run is
`docs/adoption/2026-08-01/`, and its own recommendations file is the format this one follows.

Proposals only. This report changed nothing. Each carries the deviation it addresses, the commands
that would do it, what it touches, and how to tell it worked. Section references are to
`05_EVIDENCE.md` in this bundle; `02_MATRIX.md` carries the tables the proposals argue from.

Ordered by value per unit of risk.

---

## What the 2026-08-01 recommendations achieved

Re-verified here rather than taken on trust, because a proposal recorded as done and not actually
done is worse than one still open.

| Prior proposal | State | Evidence |
|---|---|---|
| §1a renormalise the ship folder | **done** — all 60 tracked files are CRLF in the working tree over LF blobs, and all sixteen consumer diffs are empty | §3.1, §10.1 |
| §1b publish the gate as the content/byte pair | **done** — `docs/releasing.md:55` and `:85`, `docs/adoption-prompt.md:565` and `:567` | §10.6 |
| §2 write the missing `L`-trap assertions | **done** — every consumer now guards every adopted major bar two named cases, and three of the four suites carry a source matcher with its own non-vacuity case | §7 |
| §3 settle ConsumableMaster's `reset` | **done, Option A** — converged, re-homed to `/cm resetall` with the dialog intact, recorded at `LIBKA0S-12` and in a new `CHANGELOG.md` | §6.3 |
| §4 correct the adoption prompt on convergence #2 | **done, and it made the record worse** — see §5 below | §6.3, §11.4 |
| §5 ship the licence inside the payload | **done** — `LibKa0s/LICENSE` is byte-identical to the root copy and reaches all four consumers by whole-folder copy | §9.1, §10.5 |
| §6 give each adopter a provenance line | **done** — all four READMEs name v1.2.0, and all four are true | §9.1 |
| §7 point a second consumer at `RenderGrid` | **done for AbsorbTracker**, declined in writing by KickCD (`LIBKA0S-04`, wont-do, with a three-part not-expressible verdict now carried upstream as a library gap) | §5.3, §11.1 |
| §8 decide whether the degradation clause is shared | **done** — KickCD went from zero sites to ten and records it at `LIBKA0S-05`; all four consumers now share the clause | §11.4 |

Eight of eight actioned in a day, which is why almost everything below is new. Two proposals here
are re-proposals and both say so: §5 re-opens convergence #2 for ConsumableMaster because the
earlier §3/§4 pair settled the wrong half of it, and §10 asks AbsorbTracker for the vendor-gate
documentation that ConsumableMaster added and it did not.

---

## §1 — Tag v1.2.0. Do this first, and do it today.

Addresses the run's one high-severity ship-side deviation: four published addons name a release
that does not exist as a ref in this repo. `git tag` lists v1.0.0, v1.1.0 and v1.1.1 only;
`git describe --tags` reads `v1.1.1-7-g8d1d879`, so HEAD is seven commits past the last tag, those
seven being the four minor bumps and their `docs/releasing.md` entries. Everything else about the
release is complete: `CHANGELOG.md:13` heads a `## v1.2.0 — 2026-08-01` block whose eight numbers
match the eight live constants, `tests/test_versioning.lua` passes all seven cases against them,
and step 7 has been executed in full — every consumer carries the payload byte-identically (§2.1,
§3.1, §10.2).

```
git -C /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s tag -a v1.2.0 -m "v1.2.0"
git -C /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s push origin v1.2.0
```

Tag `8d1d879` — HEAD at the time of this run — not a later commit, so the ref names the tree the
four consumers actually hold. Confirm with `git describe --tags` returning `v1.2.0` and
`git show v1.2.0:LibKa0s/Options.lua | grep MINOR` reading 5.

**Blast radius:** one ref in this repo. No file changes anywhere, so nothing to re-vendor and no
consumer touched.

**Why first:** it is the only proposal in this document that is a single command with no
judgement in it, and it is the only one whose absence makes a shipped artefact unresolvable. The
provenance line is the one thing that answers "which LibKa0s does this addon carry?" without
grepping eight constants; right now four addons answer with a string nobody can check out.

---

## §2 — Fix the provenance template, which still says v1.1.1

Addresses the medium ship-side deviation at `docs/releasing.md:62` and `docs/adoption-prompt.md:398`.
Both publish the line a re-vendor is meant to write into the consumer README, and both still name
v1.1.1 — five lines after `docs/releasing.md:7`'s own table cell says the current semver is v1.2.0
(§10.6). All four consumers already carry a correct v1.2.0 line, so a maintainer following the
written instruction today would downgrade a true line to a false one.

Change both occurrences to v1.2.0, and while in `docs/releasing.md` add a half-sentence to step 7
saying the version in the template is the one being released, not a literal. That is what stops the
same edit being needed at v1.3.0. Leave `docs/adoption-prompt.md:393` alone — "LICENSE ships inside
the payload as of v1.1.1" is a historical statement and is correct.

**Blast radius:** two lines in two documents in this repo.

**Verify:** `grep -rn 'Bundles \[LibKa0s\]' docs/` returns v1.2.0 twice and nothing else.

**Hazard:** both files are CRLF. `sed -i` with a `$` anchor silently matches nothing and reports
success — the prompt documents this at `:479-481`. Edit them with a real editor, or anchor on the
version string rather than end-of-line.

---

## §3 — Move `docs/adoption-prompt.md` to four consumers

Addresses the high cross-cutting finding that the prompt still lists BankLedger as unadopted. The
filesystem holds four `libs/LibKa0s/` directories, `docs/releasing.md` names those same four in
every applicable module row and correctly omits BankLedger from the Perf row, and BankLedger's own
ledger runs to `LIBKA0S-25` including a structural, recorded Perf decline (§1, §4.4, §11.3).
`docs/releasing.md` was moved in three commits when the adoption landed; the prompt was not.

Five edits, all in `docs/adoption-prompt.md`:

- **line 6** — add BankLedger to `Adopted:`, with its four-of-five qualifier rather than "all five
  modules each";
- **line 8** — remove BankLedger from `Remaining targets:`, leaving LootHistory, PanelMaster,
  prettychat and WhatGroup, which is what `docs/releasing.md:177` already says;
- **line 303** — strike the BankLedger module-order row through and mark it done, following the
  pattern ConsumableMaster's row at `:299` already sets. Its `→ Perf` tail contradicts a recorded
  wont-do and should not survive the strike;
- **lines ~277-286** — the "architectural twins; treat them as one job done twice" paragraph is now
  recon for one addon, not two. Rewrite it as *LootHistory is BankLedger's twin, and BankLedger is
  the worked half*, which is the most valuable thing that adoption produced for the next one. Its
  claim that the numeric dropdown stays host-drawn is superseded by OptionsWidgets minor 5;
- **line 538** — add `BankLedger 684` to the additive-change proof. The three quoted figures are
  themselves still accurate; this is a missing entry, not a rotted one (§8.5).

**Blast radius:** one document in this repo.

**Verify:** `grep -n 'BankLedger' docs/adoption-prompt.md` shows no line describing it in the future
tense, and the four suite totals in step 8 match the four `docs/test-cases.md` Totals rows.

**Why this ranks above the deeper findings:** the prompt is what gets dropped into a fresh session
in an addon repo. Left as is, the next agent is told to start an adoption that is finished, to take
a Perf module the host has a written reason to decline, and to prove additivity by running the
three consumers that do *not* exercise anything v1.2.0 added.

---

## §4 — Add `BankLedger 684` to the additive-change proof, and say why it is the load-bearing one

Listed separately from §3 because it is the one edit in that file with an operational consequence
rather than a cartographic one, and because it deserves a sentence rather than a number.

All four v1.2.0 additions were driven by BankLedger, and three of the four are called by BankLedger
alone (§11.2). Its 684 cases are the only assertions anywhere that exercise `applySkin`,
`makeCloseButton`, the Slash `format` hook, the numeric-enum dropdown or the `OnDefault` forwarder.
Step 8 of "When the library itself has to change" currently tells a future author to re-run
AbsorbTracker, KickCD and ConsumableMaster — the three suites that would stay green through a
regression in any of those five surfaces.

Add the fourth total, and add one line to the same step saying that a change to a surface with a
single consumer is proved additive by that consumer's suite and by nothing else. Step 7 of the same
section already warns that the consumer list grows; this makes the warning actionable.

**Blast radius:** one line and one sentence in `docs/adoption-prompt.md`.

---

## §5 — Settle ConsumableMaster's convergence #2, and reverse the correction that hid it

Addresses the run's medium consumer-side deviation, and it is the one place where this bundle
contradicts the earlier one. This is a decision before it is a fix.

The earlier run recorded ConsumableMaster as *not applicable* for convergence #2, reasoning from a
grep of `settings/` for `COMMANDS` that genuinely returns nothing, and its §4 proposal duly amended
`docs/adoption-prompt.md:438-446` to use ConsumableMaster as the worked example of "not applicable
is not declined". Both statements are individually true and the conclusion drawn from them is
false: the landing page reaches its command rows through `KCM.SlashCommands.GetCommandSummary()`, a
name grep never sees. `settings/Panel.lua:770` installs `Helpers.BuildAboutContent` as the renderer
for the panel `/cm config` opens, and `:718-729` formats each row with the host's own string. `od -c`
against `LibKa0s/Slash.lua:69` puts the divergence beyond argument: two spaces either side of the em
dash against one, the dash white-wrapped against bare, the description bare against wrapped. The
chat half is already `lib.FormatRow`, pinned byte-for-byte at `tests/test_slashsetup.lua:57`. So the
host carries exactly the two-divergent-formatters state the convergence exists to collapse, and
`git log -L 718,729:settings/Panel.lua` shows the formatter arriving in f844f78, before the
adoption — never revisited rather than weighed and kept (§6.3).

**Who decides:** the ConsumableMaster maintainer, and only them — the visible cost lands on a
shipped panel. Nothing here can be settled from the library repo.

**Where it gets recorded:** `ConsumableMaster/docs/pending/LEDGER.md`, as `LIBKA0S-13` (the row index
runs 01, 04, 05, 02, 06-12; 13 is the next free number and there is no LIBKA0S-03 to reuse), in the
voice `LIBKA0S-12` already sets.

**Option A — converge.** Replace the loop body at `settings/Panel.lua:718-729` with an iteration
over `Sl:LandingRows()`, one Label per row, exactly as KickCD does at `settings/Panel.lua:531` and
BankLedger at `settings/Panel.lua:356`. The user-visible cost is the same one BankLedger itemised at
`LIBKA0S-11`: spacing halves, the dash loses its colour span, descriptions turn white. Add a case
alongside `tests/test_slashsetup.lua:57` pinning the panel half against `lib.FormatRow` the way the
chat half already is, so the two cannot drift again.

**Option B — decline, in writing.** Keep the host formatter and record why, naming the three
rendered differences so a future consistency sweep reads a decision rather than an oversight.

**Option A is the recommendation.** It is what the other three did, the host is already one
`lib.FormatRow` call away, and a convergence honoured on the chat half and not the panel half is the
worst of both — it is the exact drift the convergence was written to prevent, inside a single addon.

**Blast radius:** Option A touches `settings/Panel.lua`, one test file, the ledger and a
`CHANGELOG.md` entry (the panel wording changes, which users see). Option B touches one ledger row.

**Either way, correct the prompt.** `docs/adoption-prompt.md:438-446` must lose ConsumableMaster as
its worked example. The paragraph's argument is sound and worth keeping — not applicable really is
not declined — but its example is a host that *is* declined, and teaching the next adopter that a
helper-function indirection means "not applicable" is precisely how this one was missed. Either
substitute a genuine example or state the distinction without one. That edit is a library-repo
change and can happen immediately, independently of what ConsumableMaster decides.

---

## §6 — Correct the prompt's "Pinning it" claim, then decide whether the Options tripwire is required

Addresses two low consumer-side deviations that turn out to be one library-document error.

`docs/adoption-prompt.md:112-113` prescribes a library tripwire for the majors that cannot express
the `L` trap — assert `lib.STRINGS` is absent and the source names neither `STRINGS` nor a `d.L`
read — names both Core and Options as needing it, and states that AbsorbTracker, KickCD and
ConsumableMaster all carry it, so a new adopter should copy one. Checked across all four suites: the
claim holds for Core, and for Options it is false everywhere. AbsorbTracker carries neither — for
Options it ships something stronger, a rendered assertion on `lib.STRINGS.DEFAULTS_LABEL` read back
off the built Defaults button with an explicit non-vacuity coupling at `tests/test_helpers.lua:850-852`,
and for Core nothing beyond its source check. BankLedger carries the Core tripwire and no Options
equivalent. A cross-consumer grep for an Options tripwire returns one hit and it is an unrelated
comment (§7).

Two separable pieces of work:

**6a — fix the prompt.** Say that the substitute is required for Core, that AbsorbTracker's Options
coverage is a rendered assertion rather than a tripwire and is the better pattern where a real
string exists, and drop the "copy one" instruction for Options because there is nothing to copy.
One paragraph, this repo, no risk.

**6b — decide whether Options needs a tripwire at all.** `libs/LibKa0s/Options.lua` ships a `STRINGS`
table, so the Core tripwire's shape does not transfer; an Options tripwire would have to assert the
source names no `d.L` read, which passes today and goes red the day the module grows one. That is
worth having in the module that renders the settings panel, where a raw SCREAMING_SNAKE key is most
visible. It is also four repos' worth of test work for a trap that currently cannot fire.

**Who decides:** the library maintainer, because the answer is the same for all four consumers and
belongs in the prompt as a requirement or not at all. **Where it gets recorded:** the prompt's
"Pinning it" section, either as a fifth point or as an explicit note that Options is exempt while it
reads no descriptor `L`.

**Blast radius:** 6a one document here. 6b, if taken, one case in each of four consumers' suites,
each moving that repo's `docs/test-cases.md` Totals row and README badge.

**Verify 6b:** the case passes as written, then mutate — add a `d.L` read to a scratch copy of
`Options.lua` and confirm red. A tripwire that survives that mutation is not a tripwire.

---

## §7 — Name AbsorbTracker's second Slash wiring site in the Consumers table

Addresses the low ship-side deviation at `docs/releasing.md:152`. The `LibKa0s-Slash-1.0` row names
only `settings/Slash.lua` for AbsorbTracker. There is a second lookup at
`AbsorbTracker/settings/Schema.lua:182`, stashed at file load and used by `NS.FormatSchemaValue` to
call `SlashLib.FormatValue(row, v)` (§4.1, §4.5). That is the function Slash minor 5 extended with
the `format` hook, and it sits on the seam every panel widget and every `/at set` passes through.

Add `settings/Schema.lua` to that cell. `docs/releasing.md` calls the per-module column the thing
step 7 of a release reads, and the file most exposed to a `FormatValue` change is currently not a
file the checklist points a reviewer at. The call is guarded (`if SlashLib then`), so the failure
mode is a silently wrong rendered value rather than a Lua error — which is why it is low severity
and also why nothing would catch it.

**Blast radius:** one table cell in this repo.

**Verify:** for each consumer and each major, `grep -rn 'LibStub("LibKa0s-<X>-1.0"' --include='*.lua'`
outside `libs/` and `tests/` returns exactly the files the table names. That sweep is what found this
one, and it is cheap enough to belong in the release checklist rather than in an audit.

---

## §8 — Give the canvas contract a second guard, or three

Addresses the medium cross-cutting finding that Options minor 5 has four beneficiaries and one
guard. `CreatePanel` now stamps `OnCommit`/`OnRefresh`/`OnDefault` on every panel it builds, so all
four consumers silently gained a working Blizzard footer Defaults control — all four park
`defaultsOnClick`, and the library forwards to it. Only BankLedger asserts any of it, at
`tests/test_panel.lua:32-95`, and it had to reach through `rawget` because the frame mock synthesises
a no-op for any PascalCase key; its own earlier version of those cases was vacuous for exactly that
reason. AbsorbTracker, ConsumableMaster and KickCD contain zero references to the three names
anywhere, tests included (§11.2).

The mutation that matters is concrete: turn the forwarder back into an assignment
(`panel.OnDefault = panel.defaultsOnClick`), which captures `nil` because hosts park the handler
after `CreatePanel` returns. BankLedger's `LIBKA0S-25` verified against precisely that. Under it,
three of four suites stay green and three addons lose a footer control they never knew they had, in
game, silently.

Two ways to close it, and they are not exclusive:

**8a — assert it in the library's own suite.** Cheapest by far, one repo, no consumer touched: build
a panel through `O.CreatePanel`, park a `defaultsOnClick` afterwards, invoke `panel.OnDefault()`
through `rawget`, and assert the parked handler ran. That pins the forwarder where it is written.

**8b — assert it in the three consumers that gained it.** Copy BankLedger's case shape, including
the `rawget`, into AbsorbTracker, ConsumableMaster and KickCD. This is the one that protects the
hosts rather than the library, because it is the host's `defaultsOnClick` that has to still be
reachable.

**Recommendation: 8a now, 8b when each consumer is next touched.** The library case is the one that
would actually go red on the regression, and it costs one file here.

**Blast radius:** 8a one new case in `tests/`, moving this repo's Totals row from 407. 8b one case in
each of three consumer suites, each moving that repo's Totals and badge.

---

## §9 — Two ledger corrections in consumer repos

Addresses two low consumer-side deviations. Neither can be done from this repo; both are small and
both undercut the artefact that makes these adoptions auditable rather than merely inspectable.

**9a — AbsorbTracker has no ledger row for the v1.2.0 re-vendor, and `LIBKA0S-01` is now false.**
The four re-vendor commits (ebaad1e, 87eda52, 6d32bd4, 39620b4) are well-formed and individually
titled by minor, so only the ledger step was skipped. Worse, `LIBKA0S-01` still asserts in the
present tense that all eight minors are Core 2, DebugLog 3, Slash 4, Options 4, OptionsWidgets 4,
OptionsScroll 2, Perf 5, PerfPanel 3 — four of those numbers are now wrong, and a reader trusting
the ledger over the source would conclude the host is a release behind when it is current (§2.2).
Add `LIBKA0S-06` recording the re-vendor, the four commits, and that the suite stayed at 462 across
them; and amend `LIBKA0S-01` to name v1.1.0 as history rather than present state, or strike it
through with a `SUPERSEDED by LIBKA0S-06` pointer.

**9b — BankLedger's `LIBKA0S-06` describes a deviation that no longer exists.** The row is still
marked deferred and still says the repo has no `.gitattributes` and a pure-LF working tree. Both
halves are false: `git ls-files .gitattributes` returns the file, commit 9325663 pinned
`* text=auto eol=crlf` identically to the library's, and `file -b` reports CRLF throughout (§3.5).
The item was done. Every other superseded row in that ledger is struck through with a pointer and
the original text preserved; this one was missed. Strike it the same way.

**Blast radius:** one file in each of two consumer repos. No code, no tests, no version bump.

**Verify:** in each repo, the ledger's account of which release is vendored matches
`grep -n 'MINOR' libs/LibKa0s/*.lua`, and no deferred row describes a state the working tree
contradicts.

---

## §10 — AbsorbTracker still has no vendor-drift gate in `docs/testing.md`

Addresses a low consumer-side deviation that has now survived two adoption reports, so this is a
re-proposal and says so. `docs/adoption-prompt.md` step 9 requires the four diffs to be written into
each consumer's `docs/testing.md` with what each answer means, on the grounds that the file
documents the green gates and none of them can see a stale vendored library. ConsumableMaster did
this after the last run — `docs/testing.md:26-40` carries all four diffs with both readings and the
correct fix — and BankLedger carries it too. AbsorbTracker does not: `grep -n 'diff -r'
docs/testing.md` returns nothing, and the only diff documented there is the test-case-list sync.
`CLAUDE.md:34-46` states the rule ("never edit `libs/` here — change it upstream and re-vendor")
without the check (§8.1).

The cost is zero today, because this run establishes the copies are byte-identical. It is latent,
and the failure it guards against has already happened to this exact addon — `docs/releasing.md`
records a fix landing upstream, AbsorbTracker not being re-vendored, and both suites staying green
throughout. Copy ConsumableMaster's block verbatim; it is already written and already correct.

**Blast radius:** one documentation section in one consumer repo.

**Verify:** `grep -n 'strip-trailing-cr' docs/testing.md` returns two lines in each of the four
consumers.

---

## §11 — Say what the quoted `luacheck` gate actually covers

Addresses a low ship-side deviation. `docs/releasing.md:17` and `docs/adoption-prompt.md:564` both
quote the gate as bare `luacheck .` producing "0 warnings / 0 errors", which reads as repo-wide and
is not. Here it is eleven files — the eight ship files plus three under `testkit/` — because
`.luacheckrc:4` excludes `tests/` and `docs/`, leaving the whole suite, the fixtures, `wow_mock.lua`
and the vendored `tests/_kit/` copies unlinted. Every consumer's `.luacheckrc` excludes `libs/` and
most exclude `tests/` as well, so all five figures in this run's gate table are scoped (§8, §10.3).

Excluding vendored code is correct — it is not the host's code to lint. The fix is one clause in
each of the two documents saying the figure is scoped by `exclude_files` and that the seam files
must be inside the checked set for the result to mean anything. That last part is the substance: the
audit method asks warnings to be attributed to seam files against host hygiene, and the attribution
assumes the lint saw the files. BankLedger's slice checked it explicitly and found all four seam
files inside the set; nobody is currently told to.

**Blast radius:** two sentences in two documents here.

---

## §12 — Decide what to do about four surfaces with one consumer each

Addresses the run's high cross-cutting finding. A decision, not work, and the highest-leverage one
in this document even though it ranks last on risk-adjusted urgency.

Every surface v1.2.0 added was driven by BankLedger, and three of the four are called by BankLedger
and nobody else: the DebugLog `applySkin`/`makeCloseButton` pair, the Slash `format` hook, and the
numeric-enum dropdown. The fourth, the canvas contract, is not opt-in and is covered by §8. Because
`-1.0` is frozen additive-only, an assumption baked into any of these now cannot be renamed or
repurposed later, only worked around. Three specifics from the sweep (§11.1, §11.2):

- `format`'s documented precedence over `colorDecode` has **never executed**, because BankLedger
  passes no colour codecs. The second motivating case, prettychat's `|` doubling, is a different
  kind of use — `format` on rows the library *can* already render — and has not been tried.
- The numeric-enum route is inferred from the presence of `values` rather than opted into, so any
  existing number row that grows a `values` key silently reclassifies from slider to dropdown.
  KickCD's number rows all carry min/max/step; the first one to gain a list flips with no code change
  and no test anywhere that would see it.
- `applySkin` has one implementation behind it, and its contract — you are handed a fully built
  frame with `frame.title` and `frame.divider` already assigned — tolerates a missing divider only
  because BankLedger's helper happens to.

LootHistory is next and is BankLedger's architectural twin, so it will confirm these contracts rather
than stress them. **Who decides:** the library maintainer. **Where it gets recorded:** the prompt's
"Known library gaps" section, which already carries the `RenderGrid` entry in the right voice.

The proposal is not to build a second consumer for its own sake. It is to write down, before
LootHistory starts, which of these three are considered provisional — and specifically to state
whether `format` beats `colorDecode` or whether that ordering is undefined until a host exercises
both. One paragraph now is worth more than a deprecation later, because inside a frozen major there
is no deprecation available.

---

## Not recommended

- **Re-running the renormalisation.** It is done and holding: 60 of 60 tracked files CRLF in the
  working tree over LF blobs, sixteen of sixteen consumer diffs empty. There is nothing left to fix,
  and a second `git add --renormalize .` would only risk moving blobs that are already right (§10.1).
  Note that this run could not establish *how* it was fixed — no commit in the last 25 is named as a
  renormalisation — so this is a statement about state, not about cause.
- **Per-file copyright headers on the eight ship files.** The real count is zero, not three; the
  three `grep -c -i copyright` hits in `DebugLog.lua` are a `copyRight` local holding the Copy
  button's x-offset (§9.3). Headers were considered and declined at v1.1.1 because they would touch
  all eight files and bump all eight minors for no behaviour change, and `LICENSE` now travels inside
  the payload, which was the actual problem. Recorded here only so the next run does not inherit the
  false positive.
- **Writing an `L`-trap case for AbsorbTracker's Core adoption beyond its source check.**
  `LibKa0s/Core.lua` genuinely ships no `STRINGS` table, so a rendered case would be a case that
  cannot fail. AbsorbTracker records that reasoning at `tests/test_ltrap.lua:30-33` rather than
  omitting it silently, which is the correct handling. The tripwire question is §6's, and it is a
  library-wide decision rather than this host's gap.
- **Chasing KickCD's `RenderGrid` decline.** It is recorded at `LIBKA0S-04` as wont-do with a
  three-part not-expressible verdict naming file and line, two parts of which are now carried
  upstream as library gaps and tracked at KickCD issue #10. The surface gained its second consumer
  through AbsorbTracker instead. Nothing further is owed here.
- **Treating three-of-four Perf adoption as broad coverage.** It is not a defect and no work is
  proposed, but the sweep found that the entire imperative Perf API — `Measure`, `Context`, `Start`,
  `Save`, `ShowPanel`, `FormatReport`, `EncodeJSON` and the rest — has zero direct host callers
  across all four consumers; hosts touch only `Perf.Note`, `Perf.OnCommand` and the plain flags
  (§5.8). Nearly a thousand lines are reachable only through string dispatch, so no host suite can
  catch a signature change there. Worth knowing before anyone counts Perf as well covered.

---

## What none of this reaches

Every proposal above is a text change, a ref, or a test. None of them is verified in game, and eight
of the deviations this bundle records are only observable there: the footer Defaults control all
four consumers gained, DebugLog's derived title-bar offsets, BankLedger's console wearing its own
chrome, the 24-wide close button's clearance against Clear, the two numeric rows drawing as
dropdowns, the converged landing-row spacing wherever it lands, colour rendering, and the on-screen
half of the `L` trap. No consumer's `docs/smoke-tests.md` was executed by this run, and none of the
proposals here changes that — if any of §5, §6b or §8b is taken, the corresponding smoke step should
be walked before it is called done. Nothing in §9 or §10 can be executed from this repo at all; they
are asks of two consumer repos, and this report has no standing to make them beyond writing them
down.
