# `testkit` — version 29

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, **`prose_coverage.lua`**, **`prose_selftests.lua`**, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **29** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.62.0 |
| Status | **Current** |
| Supersedes | [version 28](version-28-docs.md) — the suite inventory in `inventory.lua` |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `29` |

Everything revision 28 describes is unchanged here except what follows. Two files are added,
`prose_coverage.lua` and `prose_selftests.lua`. Two files change: `test_prose.lua`, which no longer
holds the code that moved and loads both new files, and `framework.lua`, whose `Kit.VERSION` is 29.
No member is added, removed or renamed, no case is added, removed or renamed, no mock changes, and no
behavior changes.

## What changed

### The prose gate peels on its two seams

`test_prose.lua` was 1486 lines, fourteen under `layout-§1`'s cap and in the 1000–1500 band.
Issue [#39](https://github.com/tusharsaxena/LibKa0s/issues/39) had named the first seam, the
narrowing and coverage machinery, for the next kit revision that touched the file. That seam alone
would have left the file above 1000 lines, so the fixture-driven self-tests at the foot of the file,
its second seam, move as well. `test_prose.lua` goes from 1486 lines to 750, out of the band.

What moved, byte for byte apart from the comments that said where things were:

- **`prose_coverage.lua` (404 lines).** `validateOptions`, the four list names (`SOURCE_EXEMPT`,
  `SOURCE_SKIPDIRS`, `SOURCE_SKIPFILES`, `SOURCE_WAIVED`), `declaredEntries`, `resolveExempt`, a
  declared narrowing and its readers (`exemptNarrowings`, `dirCovers`, `waiverNarrowings`,
  `allNarrowings`), the TOC and `.pkgmeta` readers (`normalizePath`, `tocLoads`, `pkgmetaIgnores`,
  `ignoreCovers`), the one resolved coverage set (`coverageOf`) and what reads it (the disclosure's
  `coverageSummary`, and the two refusals `narrowingsLoadedByToc` and `narrowingsNotIgnored`). It is
  a chunk taking `fail`, `SCAN_BACK` and `KIT_DIRS` and returning a table of those functions and
  names.
- **`prose_selftests.lua` (426 lines).** The thirteen `prose self-test:` cases and their fixtures
  (the generated-folder tree, and the PrettyChat and WhatGroup `.toc` and `.pkgmeta` bodies). It is a
  chunk taking the kit, the table `prose_coverage.lua` returns and the four scan functions the cases
  drive (`filterPaths`, `collect`, `exclusionSets`, `validateWaived`).

Why they are seams: every function in the machinery is pure apart from `fail`, and reaches the rest
of the gate only through `SCAN_BACK` and `KIT_DIRS`, which it is handed. The self-tests touch neither
git nor the disk and read nothing but the functions they drive.

What stayed in `test_prose.lua`: the header, the published lists' load and the named exclusions,
`options()` and `declared()` (the only readers of the live `Kit.prose`), the waiver file's reader
and `validateWaived`, the path scan, the British-spelling matcher and every case except the
self-tests.

**The self-tests are still the `test_prose` suite's cases.** `prose_selftests.lua` is not named
`test_*`, so the suite inventory does not read it as a suite and a consumer's suites list does not
change. `test_prose.lua` loads it at the point the cases used to stand, so every case registers under
`test_prose`, with the same name, in the same order. Both new files are found from `test_prose.lua`'s
own folder, the way `prose_lists.lua` is, and a missing one raises at load.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

Nothing else. The suites list does not change, no case name changes, so `docs/test-cases.md` does
not change, and the run's totals are the same before and after. A copy that leaves out
`prose_coverage.lua` or `prose_selftests.lua` fails at load, when `test_prose.lua` reaches for it:
copy the whole folder, as the kit's README says.
