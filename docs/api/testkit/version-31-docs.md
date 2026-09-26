# `testkit` — version 31

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **31** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.62.0 |
| Status | **Current** |
| Supersedes | [version 30](version-30-docs.md) — `None.` under an empty watch-list table |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `31` |

Everything revision 30 describes is unchanged here except what follows. No file is added. Four
files change: `run-automated-tests.sh`, which writes the band table; `framework.lua`, which answers
the runner's question and whose `Kit.VERSION` is 31; `test_layout_cap.lua`, which now calls the
matching rule where `framework.lua` keeps it; and `README.md`, whose runner and cap-gate notes
describe both. No public member is added, removed or renamed, no kit case is added, removed or
renamed, and no mock changes.

## What changed

### The band table leaves out generated non-shipping data

`layout-§1` has two carve-outs from its 1500-line cap: vendored code (`libs/` and `tests/_kit/`)
and generated non-shipping data. `RESULTS.md`'s *Files by `layout-§1` band* table honored only the
first, so a committed generated file was listed in every run. Pretty Chat's 23,842-line
`GlobalStrings/GlobalStrings.lua` appeared as `> 1500 (over cap)` in each of its records, and the
`AUTOMATED_TESTS.md` playbook reads a generated table in that list as the runner counting what the
rule never bound. The 2026-09-26 automated-tests sweep filed it as `ATS-21`.

Which files are generated is a fact about the repository, not something a path shows, so the runner
does not guess by folder name or size. A repository already declares the set once, for the cap
gate, as `Kit.layoutCap.exempt` in its `tests/run.lua` (revision 25). From revision 31 the runner
reads the same declaration:

1. It collects the files of 1000 lines or more outside the vendored pair, as before.
2. When the repo has a `tests/run.lua` and a Lua interpreter is on the path, it runs
   `lua tests/run.lua --layout-cap-exempt PATH...` with those files as the arguments.
3. `Kit.run` sees the flag before it loads any suite. For each PATH that an entry of
   `Kit.layoutCap.exempt` covers, it prints `layout-cap-exempt`, a tab, and the PATH, then exits 0.
4. The runner removes each answered PATH from the table. It reads only lines that carry the marker
   and name one of its candidates, so nothing a runner prints while it sets up can drop a row.

An entry covers a path when it equals the path or names a folder that contains it (`Gen/` and
`Gen` both cover `Gen/Dump.lua`; neither covers `General.lua`). Globs are not expanded. This is
the rule `test_layout_cap.lua` has always applied, moved unchanged into `framework.lua` as
`Kit.__layoutCapCovers`, and the gate now calls it there, so the gate and the runner cannot match an
entry two different ways. The entry forms are the gate's too: an array of paths and folders, a map
of path to `true`, or both. A malformed entry is still the gate's to fail by name; the runner's
question treats it as covering nothing.

What the carve-out left out is said under the table rather than dropped silently:

```markdown
Left out as generated non-shipping data (`layout-§1`'s second carve-out, declared in
`Kit.layoutCap.exempt` in `tests/run.lua`, the set the cap gate reads): `GlobalStrings/GlobalStrings.lua`.
```

The line opens with no `|`, so the runner's reader of the previous watch list never carries it
forward as an entry. `manifest.json` keeps its fields; `bandFiles` and `overCapFiles`, and the watch
list's opening sentence that quotes them, stop counting the files left out, because both are derived
from the same rows as the table.

Nothing is left out, and the table is what revision 30 wrote, when the repo has no `tests/run.lua`,
no interpreter is found, or no exempt set is declared. That errs toward listing a file rather than
hiding one.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

Nothing else. The suites list does not change and no kit case name changes, so a consumer's
`docs/test-cases.md` does not change. A repo that already declares `Kit.layoutCap.exempt` (Pretty
Chat) sees its generated files leave the band table on the next run of `run-automated-tests.sh`;
every other repo's table is unchanged. The previous `RESULTS.md` needs no edit: the watch list is
regenerated whole on every run that measures complexity, and a disposition carried against a row
that is no longer listed is simply not carried.
