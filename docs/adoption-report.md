# The adoption report

Run this when asked for an **adoption report** (or "check adoption", "how faithful are the
adopters", "adoption fidelity"). It answers one question across every addon that has adopted
LibKa0s: *is what they are running actually what this repo ships, and does it fit the way the
library says it should?*

Output goes to `docs/adoption/<YYYY-MM-DD>/` as a frozen five-file bundle. Frozen means it is never
edited after the fact — a later run makes a new dated folder, and the difference between two
folders is the record of what moved.

This report is **read-only**. It never edits a consumer, never re-vendors, and never edits `libs/`
anywhere. Everything it finds is a finding, not a fix. If a fix is obvious, it goes in
`04_RECOMMENDATIONS.md` as a proposal with the command that would do it.

## Who is in scope

The adopters are whoever `docs/releasing.md`'s **Consumers** table names — read it, do not assume
the list from a previous run. Cross-check it against the filesystem, because the table is
maintained by hand and the filesystem is not:

```
ls -d ../*/libs/LibKa0s 2>/dev/null
```

A repo with `libs/LibKa0s/` that the table does not name is a finding on its own (an adoption
nobody recorded). So is the reverse. `docs/adoption-prompt.md` carries the remaining-targets list;
use it to say what is *not* yet adopted, but treat the filesystem as authoritative for what is.

## What to establish, in this order

Each step names the evidence it must produce. A claim without its command is not a finding.

### 1. Version fidelity — what minor is each consumer actually running

The file minor is the mechanism; the semver tag is a courtesy. Extract the live minors from the
ship folder and from every consumer's vendored copy, and put them in one table:

```
grep -hoE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *= *("[^"]+", *)?[0-9]+' \
  LibKa0s/*.lua
grep -hoE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *= *("[^"]+", *)?[0-9]+' \
  ../<Addon>/libs/LibKa0s/*.lua
```

Any consumer behind on any of the eight files is **cross-major skew** and is the single most
serious thing this report can find — it is the failure mode whole-folder vendoring exists to
prevent, and it does not announce itself at runtime. Report the file, both minors, and what the
consumer therefore does not have.

### 2. Byte fidelity — and do not trust `diff -r` alone

`docs/releasing.md` documents the gate as a pair of diffs — it published a bare `diff -r` until the
2026-08-01 run, which is where the false alarm below came from. Run both, whatever the doc in front
of you says:

```
diff -rq LibKa0s ../<Addon>/libs/LibKa0s                      # byte
diff -rq --strip-trailing-cr LibKa0s ../<Addon>/libs/LibKa0s  # content
diff -rq testkit ../<Addon>/tests/_kit
diff -rq --strip-trailing-cr testkit ../<Addon>/tests/_kit
```

The two answers mean different things and conflating them has already produced a false alarm:

- **byte differs, content same** → a line-ending divergence. Nothing is wrong with the *code*.
  Establish which side is the anomaly before calling it drift, with
  `file -b <path>` on both and `git cat-file -p HEAD:<path> | file -b -` for what git stores.
  Under `* text=auto eol=crlf` with LF blobs, a working tree holding **either** LF or CRLF reads
  clean to `git status`, so neither repo's cleanliness proves anything.
- **content differs** → a real fork in `libs/`, which is the forbidden state. Name every hunk.

Report both, separately, and never let a line-ending finding be written up as a code drift.

### 3. Module coverage — who wired what

```
grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' ../<Addon> --include='*.lua' \
  | grep -v '/libs/' | grep -v '/tests/'
```

That gives the majors adopted and the file each one's seam lives in. Check the result against
`docs/releasing.md`'s per-module Consumers column and report any disagreement — the table is the
thing step 7 of a release reads, so a stale row means a consumer silently misses a re-vendor.

### 4. Adoption shape — depth, not just presence

A wired major is not an adopted one. For each consumer and each major, establish which of the
library's public surfaces it actually calls and which equivalent it still owns:

- Options: `RenderRows`, `RenderGrid`, the four makers, `LSMValues`, `SetRenderer`,
  `RefreshAllPanels` / `RefreshScalars`, the page registry.
- Slash: the dispatcher, `HelpRows`, `LandingRows`, and the schema CLI —
  `CliList` / `CliGet` / `CliSet` / `CliReset` **counted separately**, because hosts routinely take
  three of the four.
- Core: printer, `SafeToString`, `SKIN`, `MakeCloseButton` — the skin half is legitimately declined
  by some hosts and that is a decision, not a shortfall.
- DebugLog / Perf: whether the host's own file deleted or survives, and at what line count.

Then say which library surfaces have **only one consumer**. A surface with one consumer is a
surface whose contract has been tested against exactly one shape, and the next adopter is where it
breaks.

### 5. The convergences — adopted, declined, or not applicable

`docs/adoption-prompt.md` names two deliberate user-visible convergences: `reset` takes a **path**,
and the landing page renders through the one row formatter. For each consumer decide which of three
states it is in, and **distinguish the third from the second**:

- **adopted** — calls `CliReset` / `LandingRows`;
- **declined** — has the surface the convergence applies to, and kept its own;
- **not applicable** — has no such surface at all (an addon with no landing page cannot diverge
  from a landing-page convergence).

A declined convergence is only a finding if the decision is not written down. Check the host's
`docs/pending/LEDGER.md` and its release notes before calling it undocumented. A *not applicable*
that `docs/adoption-prompt.md` lists as changing is an error **in the prompt**, and correcting the
prompt is part of the report's value.

### 6. The `L` trap — both halves

Two separate checks, and passing the first does not imply the second.

```
grep -rnE '(^|[,{[:space:]])L[[:space:]]*=' ../<Addon> --include='*.lua' \
  | grep -v '/libs/' | grep -v '/tests/' | grep -v 'local L'
grep -rn 'A-Z0-9_' ../<Addon>/tests --include='*.lua' | grep -v '_kit'
```

The first finds every descriptor `L`. Read each one: a plain table of literals is correct, the
addon's own locale table is the shipped-broken case. The second finds the
`^[A-Z][A-Z0-9_]+$` regression guard. Report coverage as *guarded module-adoptions / total
module-adoptions* — the trap being currently avoided is worth much less than it being pinned,
because nothing stops the next edit from reintroducing it.

### 7. The green gate, actually run

In this repo and in every consumer. Paste real output; never summarise a run you did not do.

```
lua tests/run.lua
luacheck .
```

Where a consumer misses the documented 0 warnings / 0 errors, **attribute the warnings**: warnings
inside the five seam files are adoption defects, warnings elsewhere are pre-existing host hygiene
and must be reported as such rather than counted against the adoption.

Also re-check the count the adoption prompt quotes as its additive-change proof (AbsorbTracker's
suite total at the time of writing). If it has moved, say by how much and why — that number is what
makes "the change was additive" checkable rather than asserted.

### 8. Provenance — can a human tell what they are running

Cheap, usually skipped, and the reason a stale vendor survives:

- Does the consumer's README or release notes name LibKa0s or the version it carries?
- Does the vendored folder carry the licence the library ships under?

```
grep -c -i copyright LibKa0s/*.lua
ls ../<Addon>/libs/LibKa0s/
```

## Confidence, and how to score it

Give every consumer a confidence grade and **justify it from the evidence above, not from
impression**. The grade answers: *if this consumer had silently diverged, would anything in its own
repo have caught it?*

| Grade | Means |
|---|---|
| High | Minors current, content identical, all wired majors have seam tests, green gate clean, decisions recorded. |
| Medium | The above with a named, bounded gap — a missing regression guard, an undocumented declined convergence, a gate that does not currently pass for reasons outside the adoption. |
| Low | Version skew, a content fork in `libs/`, an unguarded seam, or a divergence nobody wrote down. |

Never grade on how much code was deleted. A host that correctly declines half the library is a
faithful adopter; a host that took everything and pinned none of it is not.

## The bundle

Write exactly these five, in `docs/adoption/<YYYY-MM-DD>/`:

| File | Holds |
|---|---|
| `01_SUMMARY.md` | The verdict, the confidence grade per consumer, and the findings ranked by severity. Readable alone. |
| `02_MATRIX.md` | The tables: minors per consumer vs ship, majors wired and where, surface-level adoption depth, convergence state. |
| `03_DEVIATIONS.md` | One section per deviation — what, where with file:line, whether it is deliberate, whether it is recorded, and what it costs. |
| `04_RECOMMENDATIONS.md` | Proposed fixes, each with its command and its blast radius. Proposals only; this report changes nothing. |
| `05_EVIDENCE.md` | The raw command output every claim above rests on, verbatim. |

Conventions that keep the bundle trustworthy:

- **Every claim carries its evidence.** A finding in `03` cites a block in `05`.
- **Separate "is wrong" from "is undocumented".** They have different fixes and different urgency.
- **Name what you did not check.** In-game behaviour, anything a headless suite cannot reach, and
  any consumer you could not run. An unchecked area silently omitted reads as a clean one.
- Dates are the run date. `docs/` in this repo is CRLF like everything else — see `.gitattributes`,
  and mind the `sed -i` hazard in `docs/adoption-prompt.md`.

Finally, print a chat summary: the verdict in a sentence, the confidence grades, the findings worth
acting on this week, and anything the report could not establish.
