# `testkit` — version 41

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `secrets.lua`, `latch.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_lines.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **41** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | unreleased — the first LibKa0s release after v1.74.0 |
| Status | **Current** |
| Supersedes | [version 40](version-40-docs.md) — `framework.lua` exported two self-test seams, `Kit.__deviationRows` and `Kit.__declineFor`, that no suite read |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `41` |

Everything revision 40 describes is unchanged here except what follows. No file is added. Revision
41 is one release's kit: the LibKa0s release after v1.74.0 ships it once, and every kit change in
that release is listed below rather than taking a revision of its own.

## What changed

### `Kit.__deviationRows` and `Kit.__declineFor` are no longer exported (LibKa0s#45)

`framework.lua` put `inventory.lua`'s `## Documented deviations` reader and decline matcher on the
kit table as `Kit.__deviationRows` and `Kit.__declineFor`, for the kit's own self-tests. No suite
read either one, here or in any roster consumer: `tests/test_kit_inventory.lua` pins the decline
reader through its fixtures, a real register under a temporary root read by
`Kit.assertSuiteInventory`, which is the path a consumer's run takes. Both lines are deleted, and
`inventory.lua` stops returning the two functions to `framework.lua`; they stay local to
`inventory.lua`, which still calls them.

Neither member was contract. Under the kit's own revision contract a kit member is contract only
when a kit version document lists it for consumers, and no revision's document listed either one.
So this removes nothing a consumer may depend on, and no consumer reads them.

What the kit table still carries for its self-tests from the inventory is unchanged:
`Kit.__loadSuites`, `Kit.__normDir`, `Kit.__resolveDir`, `Kit.__adviceDir` and `Kit.__kitGateRule`.

Two comments follow: `inventory.lua`'s return-table note names only what `framework.lua` still
takes (the path helpers, `renderInventory`, `kitGateRule`), and `run-automated-tests.sh` says the
register is read by `inventory.lua`'s `deviationRows`, not `framework.lua`'s.

No documented member is renamed or removed, and no kit case name changes.

### A lizard crash or bound is a complexity fail with zeroed figures, never a pass (LibKa0s#46)

Revision 40's complexity suite ran lizard with `2>&1` and read its footer with `tail -1`. When
lizard raised, the last line was the exception, so five of its words were written into
`manifest.json` as the NLOC, function and average figures (invalid JSON), the maximum CCN was a
partial maximum over the function rows lizard had already streamed, and parity over a run with
no per-file table named every file blind. lizard does not print nothing before a raise: it
streams its function rows as it measures, and what a raise loses is the per-file table and the
footer. A deprecation warning on stderr broke a clean run the same way, by landing after the
footer.

What `run-automated-tests.sh` does from revision 41:

- **stderr is kept out of the parse.** The command is `performance-§10`'s, byte for byte; only
  the redirection changes, to `2>lizard.err` beside the shadow. `complexity.txt` is still lizard's
  stdout, and when stderr is not empty it follows under a `--- lizard stderr ---` separator, so a
  traceback survives in the frozen bundle.
- **The footer is the line exactly two below `Total nloc`**, never the last line of the output.
- **A run is measured only when** lizard exited 0 or 1 (lizard 1.24.0 returns 1 on any run that
  warned, `lizard.py:1182-1184`), the footer has exactly eight numeric fields, **and** stderr holds
  no `Traceback` line (a late raise can follow a good footer, `lizard.py:1176-1177`).
- **Anything else is `fail`**, never a pass, with exactly one of two notes:
  `lizard raised: <last non-empty line of stderr>` when there is a traceback, otherwise
  `lizard exited <rc> with no valid footer (bound: KA0S_KIT_TIMEOUT_S / KA0S_KIT_PROC_MB)`, which
  the timeout's 124 and the memory kill's 137 share. Every complexity figure is 0, the maximum CCN
  included, and parity is skipped (`blindFiles` stays 0). Like a blind file, a crash makes the
  verdict amber: it blocks the tag and never fails the run or the commit.
- **Zero is what the manifest holds, `n/a` is what a reader sees.** `manifest.json` keeps numeric
  0 in every complexity field (each field is read as a number or written as 0, so the manifest is
  valid JSON whatever lizard printed); the console line and the `RESULTS.md` trend row render the
  CCN figures as `n/a`. The watch list is not regenerated from a run that measured nothing: like
  a skip, the section names the note and carries the last measured list, dispositions included.

Four cases in `tests/test_kit_runner.lua` pin this with a fake lizard first on `PATH`, so they
run on any host: a traceback, a warned run that exits 1 with a valid footer, stderr noise on a
clean exit, and a timeout's 124.

## What a consumer owes

Re-vendor `tests/_kit/` whole:

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
lua tests/run.lua --list > docs/test-cases.md
```

No suite, case name or documented member changes. A consumer's own prose that names the revision it
holds moves to 41 in the same commit.
