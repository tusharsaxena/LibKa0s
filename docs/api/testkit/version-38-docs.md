# `testkit` — version 38

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_lines.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **38** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.71.0 |
| Status | **Current** |
| Supersedes | [version 37](version-37-docs.md) — the `--list` Total counted declared skips |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `38` |

Everything revision 37 describes is unchanged here except what follows. No file is added. Three
files change: `framework.lua`, whose `Kit.VERSION` is 38 and whose `--list` renderer moves, with the
change below, to `inventory.lua`; `inventory.lua`, which now holds that renderer and returns it to
`Kit.run`; and `README.md`, whose file table says where the renderer lives and what the Totals
count. No public member is renamed or removed, no kit case name changes and no mock changes.

## What changed

### `--list` Totals count only the cases that run

Through revision 37 the `## Totals` table's suite rows and its `| **Total** |` row counted the whole
registry, declared skips included (a `Kit.test` registered with a skip reason: a recorded decline of
a kit gate, a `pending` suite, a case a repo opted out of), and the preamble called that number the
authoritative pass count the README badge must agree with. `testing-§5` says a skip **MUST NOT** be
folded into passed or total, and the run's own summary never did, so every consumer holding a
declared skip shipped an inventory Total one above its badge (AuraMaster 2050 against 2049/2049,
AbsorbTracker 877 against 876/876, KickCD 1303 against 1302/1302). From revision 38:

- **Each count row** (`the runner` and every `<suite>.lua`) counts the cases registered there that
  are **not** declared skips. A row whose count is 0 is omitted, as before, so a group whose only
  case is a skip has no count row.
- **`| Skipped | N |`** is printed immediately before Total when the registry holds N > 0 declared
  skips, and not at all when it holds none.
- **`| **Total** | **N** |`** is the number of registered non-skipped cases: the sum of the count
  rows, the Skipped row excluded, and the number a green run reports as passed.
- **The preamble** says so: Total counts the cases that run and is the authoritative pass count the
  README badge must equal, and a declared skip is listed by name in its group and counted on the
  `Skipped` row, never in Total.
- **The groups do not change.** A declared skip is still listed by name in its group, with its
  reason, and a `### <group> (n)` heading still counts every case it lists.

A skip decided **inside** a case body (`Kit.skip` at run time) is not visible to `--list`, which runs
nothing, so it is counted in Total exactly as before; only declared skips move.

**Why the renderer moved.** `framework.lua` was 994 lines at revision 37, and the change would have
taken it into `layout-§1`'s 1000–1500 band. The renderer reads nothing of the runner's but the
registry, so it moves to `inventory.lua` (the inventory seam) and `Kit.run` hands it the registry;
`framework.lua` is 916 lines. The rendered bytes are otherwise unchanged.

The four cases that pin this live in this repo's `tests/test_kit_inventory.lua`, driving a fixture
repository's `lua tests/run.lua --list`; they are **not** kit cases, so a consumer's suites list
does not change.

**What a consumer owes:** the whole-folder copy, and `docs/test-cases.md` regenerated **in the same
commit**. Every consumer with a declared skip (every one that wires `test_diagnostics_contract.lua`
and keeps the default, and every one that records a kit-gate decline) sees its count rows drop, a
Skipped row appear and Total fall to its badge.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
lua tests/run.lua --list > docs/test-cases.md
```

The suites list does not change and no kit case name changes, but `docs/test-cases.md` does, so it
is regenerated in the re-vendor commit. A consumer's own prose that names the revision it holds
(`kit revision 37`) moves to 38 in the same commit.
