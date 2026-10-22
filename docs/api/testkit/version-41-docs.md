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

## What a consumer owes

Re-vendor `tests/_kit/` whole:

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
lua tests/run.lua --list > docs/test-cases.md
```

No suite, case name or documented member changes. A consumer's own prose that names the revision it
holds moves to 41 in the same commit.
