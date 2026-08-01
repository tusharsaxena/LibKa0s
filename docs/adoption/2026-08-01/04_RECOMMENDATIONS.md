# Recommendations — 2026-08-01

Proposals only. This report changed nothing. Each carries the command that would do it and what it
touches, so the blast radius is a decision rather than a discovery.

Ordered by value per unit of risk.

---

## §1 — Fix the line-ending gate. Do this before the next release.

Addresses `03_DEVIATIONS.md` §1. Two halves, and **both** are needed — either alone leaves the
problem live.

### 1a. Renormalise the ship folder

The condition is repo-wide — 16 of 49 tracked text files, not just the four in `LibKa0s/` — so fix
it repo-wide:

```
git add --renormalize .
git status                                   # expect: no changes staged (blobs already LF)
for f in $(git ls-files '*.lua' '*.md' '*.xml' '*.toc'); do
    file -b "$f" | grep -q CRLF || echo "still LF: $f"; done   # expect: nothing
```

`--renormalize` rewrites the index through the current filters. Because the blobs are already LF,
the index should not move; what changes is that a subsequent checkout writes CRLF consistently. If
the working tree does not flip, force the affected paths back through the filter:

```
rm -f <the LF paths> && git checkout -- .
```

Verify against `.gitattributes` before and after, and re-run `lua tests/run.lua` — `test_kitsync.lua`
compares byte-for-byte and will fire if `testkit/` and `tests/_kit/` end up on different sides.

**Blast radius:** this repo's working tree only. No blob changes, therefore no diff for reviewers.

### 1b. Make the documented gate line-ending-proof

`docs/releasing.md` and `docs/adoption-prompt.md` both publish the gate as bare `diff -r`. Change
both to run the pair, because the two answers are different findings:

```
diff -r --strip-trailing-cr ../LibKa0s/LibKa0s libs/LibKa0s   # content — MUST be empty
diff -r ../LibKa0s/LibKa0s libs/LibKa0s                       # bytes — SHOULD be empty
```

with one line saying what a byte-only difference means and that the fix is renormalisation, never
an edit to `libs/`. That sentence is the actual deliverable here — §1a fixes today's instance,
§1b stops the next one being misdiagnosed.

**Blast radius:** two documents.

### 1c. Optional — make it mechanical

`tests/test_kitsync.lua` already proves the pattern works: it caught a drift three documents
asserted was not there. The same shape pointed at the consumer list in `docs/releasing.md` would
close the loop for `libs/` too. Not proposed as work now; noted because the machinery exists and
the manual gate has now failed once.

---

## §2 — Write the fourteen missing `L`-trap assertions

Addresses `03_DEVIATIONS.md` §2. One assertion per adopted module, in that module's own suite:

```lua
assertNil(rendered:match("^[A-Z][A-Z0-9_]+$"),
    "the label resolved to prose, not to its own key")
```

Copy the shape from `KickCD/tests/test_perfsetup.lua:375`, which is the one that exists. Two things
the prompt is emphatic about and that the existing pair get right:

- assert on **the string the library actually rendered**, reached through a real accessor;
- never guard with `if label then` — the case passes vacuously when the accessor does not exist,
  which is how the first attempt at this test proved nothing.

Then mutate to confirm each one can fail: hand the descriptor its addon's locale table, run, and
confirm red. An assertion that survives that mutation is not an assertion.

**Blast radius:** thirteen new cases across three consumers' test suites, plus the two that exist.
No production code. Each consumer's `docs/test-cases.md` and `[tests]` badge count move with it.

**Cost:** perhaps an hour per addon. This is the highest-value test work available in the
collection — it is the only failure mode here with a shipped-broken precedent.

---

## §3 — Settle and record ConsumableMaster's `reset`

Addresses `03_DEVIATIONS.md` §3. A decision first, then whichever implementation follows.

**Option A — converge, keep the guard.** `/cm reset <path>` delegates to `CliReset`; a new
`/cm resetall` takes over the confirm popup and the global wipe. Matches AbsorbTracker and KickCD
exactly, and is what the prompt anticipates ("re-anchor the popup to `resetall`"). Costs a
breaking-change note and a deprecation message for anyone with `/cm reset` in a macro.

**Option B — stay divergent, on purpose.** Keep `/cm reset` as the guarded global wipe and record
why in `docs/pending/LEDGER.md` as a LIBKA0S-08 entry, in the same voice as LIBKA0S-01 … -07.

Either is defensible. What is not defensible is the current state, where a reader cannot tell which
one was chosen. **Option A is the recommendation** — the collection-wide consistency argument is
the same one that carried LIBKA0S-01 over its own line-count objection, and it keeps the
destructive path behind a confirmation.

**Blast radius:** Option A touches `core/SlashCommands.lua`, `tests/test_slash.lua`,
`tests/test_slashsetup.lua`, the ledger and the addon's user-facing help. Option B touches one
ledger row.

---

## §4 — Correct the adoption prompt

Addresses `03_DEVIATIONS.md` §4. In `docs/adoption-prompt.md`, convergence #2: remove
ConsumableMaster from the list of addons that change, and add a clause distinguishing *declined*
from *not applicable* — an addon with no landing page has nothing to converge.

While in the file, two other things this report established that it should carry:

- the `Adopted:` line and the ordering commentary are current and correct — leave them;
- ConsumableMaster's entry in the "Suggested module order" table already records that Slash ran
  before Options and why. It does not record that `CliReset` was declined. Add it, so the next
  adopter reading CM as a worked reference is not surprised.

**Blast radius:** one document. Mind the CRLF hazard the file itself documents — `sed -i` with a
`$` anchor never matches, and reports success.

---

## §5 — Ship the licence with the library

Addresses `03_DEVIATIONS.md` §5. The clean fix puts it in the payload rather than asking eight
addons to remember:

```
cp LICENSE LibKa0s/LICENSE
```

`docs/releasing.md` currently says *"The library is the inner `LibKa0s/` folder and nothing else.
`docs/`, `README.md`, `CHANGELOG.md` and `LICENSE` stay here."* That sentence changes: `LICENSE`
becomes part of the ship folder, and `cp -r LibKa0s/. <Addon>/libs/LibKa0s/` then carries it to
every consumer with no per-addon step and no change to the `diff -r` gate's shape.

Consider also a two-line header on each of the nine files — major, and `MIT — see LICENSE` — so a
file read in isolation says what it is. Not required by the licence; useful when someone finds one
of these in a zip.

**Blast radius:** one new file in the ship folder, one paragraph in `docs/releasing.md`, and a
re-vendor into three consumers. If the header lines are taken too, all eight file minors bump — so
do it as part of a release rather than between two.

**Do not** hand-copy `LICENSE` into any `libs/LibKa0s/` directly. That makes the vendored folder
differ from the ship folder and breaks the gate for real.

---

## §6 — Give each adopter a record of what it carries

Addresses `03_DEVIATIONS.md` §6. Cheapest useful version, one line in each adopter's README:

> Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.1.0 (MIT).

Better version, if any of the three grows a `CHANGELOG.md`: a line per re-vendor naming the library
tag. That turns "which consumers are stale?" into a grep instead of a sweep — and the answer is
needed at exactly the moment `docs/releasing.md` says the step gets forgotten.

**Blast radius:** one line per README. Needs a discipline to keep it true; the re-vendor step in
`docs/releasing.md` should name it so it moves with the copy rather than after it.

---

## §7 — Point a second consumer at `RenderGrid`

Addresses `03_DEVIATIONS.md` §7. Not urgent, and explicitly **not** a rewrite for its own sake.

Before the next adoption starts, look at AbsorbTracker's and KickCD's caller-driven list loops
against `RenderGrid`'s contract and answer one question: does it express them? If yes, adopting one
of them retires a hand-rolled copy and — more valuably — contract-tests the newest surface in the
library against a second shape before five more addons arrive. If no, the reason is a library
finding worth more than the adoption would have been.

KickCD's `settings/Panel_Render.lua` is the place to look first; the prompt records it as part of
the ~450 lines with no library equivalent, and that assessment predates `RenderGrid`.

**Blast radius:** recon only, until the answer is known.

---

## §8 — Decide whether the degradation message is shared or per-addon

Addresses `03_DEVIATIONS.md` §8. A decision, not work.

Either KickCD adopts `NS.LIBKA0S_MISSING` — matching AbsorbTracker's PLAN-04 and
ConsumableMaster — so all three say the same thing to a user with a broken install; or PLAN-04's
scope is written down as per-addon and KickCD's wording stands. Both are fine. Five more adopters
are coming, and each will copy whichever pattern it reads first.

**Blast radius:** KickCD's five seam files, or one paragraph in `docs/adoption-prompt.md`.

---

## Not recommended

- **Chasing KickCD's seven `luacheck` warnings as part of adoption.** All seven are outside the
  seam files and predate it. Worth fixing as host hygiene, on its own, so the adoption's clean bill
  stays legible. Note that KickCD does not currently pass the prompt's stated 0/0 gate, and either
  the gate or the warnings should move.
- **Reducing ConsumableMaster's `Slash.lua` / `Panel.lua` line counts.** They are large because
  they hold the addon's own command tree and page builders, not because the adoption is shallow.
  LIBKA0S-01 already litigated the size objection and it was overruled deliberately.
- **Adopting `LandingRows` in ConsumableMaster.** There is no landing page. Building one to satisfy
  a convergence would be the tail wagging the dog.
