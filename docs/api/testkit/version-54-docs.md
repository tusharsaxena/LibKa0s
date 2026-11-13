# `testkit` — version 54

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 53 lists |
| Version | **54** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.95.0 |
| Status | Superseded |
| Supersedes | [version 53](version-53-docs.md) — the same surface and behavior, with three scanner functions over CCN 15 |
| Superseded by | [version 55](version-55-docs.md) — `vendor_sync.lua` holds `media/sounds/` to the `LibKa0s sounds:` line |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `54` |

Everything revision 53 describes is unchanged here except what follows.

## What changed

### `client_globals.lua`: `strip`, `scan` and `judge` split into helpers (`QFE-LK2`)

The v1.95.0 release run's complexity suite measured `CG.strip` at CCN 19, `CG.scan` at 16 and
`CG.judge` at 19, and `docs/releasing.md` allows no function above 15 at a tag. Each is split into
file-local helpers, with no behavior change:

- **`CG.strip`** dispatches one piece at a time through `stripPiece`, which hands a comment to
  `stripComment`, a quoted string to `stripQuoted` and a long string to `stripLong`.
- **`CG.scan`** strips and declares every file in `prepare`, then reads each file in `scanFile`, with
  its guard cache from `guardOf` and each call recorded per client by `recordCall`. The `seen` keys
  are still shared across files, so the findings and their order are unchanged.
- **`CG.judge`** reads a malformed row through `badRow` and a taken hit through `takenBy`, which
  still marks every addon row that takes it and still reads `CG.BUILTIN` at call time.

No member of `CG` is added, renamed or removed, and no case name changes. Checked against revision
53 on 2152 source files (this repo's tracked `.lua` and the sibling addons' `libs/`): the same
stripped text, the same 898 findings in the same order, and the same `judge` answers.

## What a consumer owes

Re-vendor the kit with the library, per `docs/releasing.md`. Nothing else: no declaration, suite,
allowlist or call changes.
