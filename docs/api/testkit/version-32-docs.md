# `testkit` — version 32

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **32** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.63.0 |
| Status | **Current** |
| Supersedes | [version 31](version-31-docs.md) — generated files leave the band table |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `32` |

Everything revision 31 describes is unchanged here except what follows. No file is added. Two files
change: `README.md`, whose counts were one short, and `framework.lua`, whose `Kit.VERSION` is 32 and
which changes in nothing else. No public member is added, removed or renamed, no kit case is added,
removed or renamed, no mock changes, and the runner writes what revision 31 wrote.

## What changed

### The README counts the eleventh consumer

`README.md` said it was byte-identical in twelve places (`testkit/`, this repo's `tests/_kit/` and
"each of the ten consumers'"), that eleven repositories run the kit's gates, and that the one
repository with generated data is one of eleven. The collection has eleven consumers, so the file now
says thirteen places, eleven consumers and twelve repositories. Found by the 2026-09-29 `profile`
rollout's doc sync (SP-FIN-01) and folded into v1.63.0, with the owner's go-ahead, before the tag was
published.

The change is to prose only, and it is a revision because the kit's rule is that any released change
to any file in `testkit/` bumps `Kit.VERSION`: the files vendor as one folder, and byte-identity is
the sync gate, so a consumer holding the old README is holding a different kit.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

Nothing else. The suites list does not change and no kit case name changes, so a consumer's
`docs/test-cases.md` does not change. A consumer's own prose that names the revision it holds
(`kit revision 31`) moves to 32 in the same commit.
