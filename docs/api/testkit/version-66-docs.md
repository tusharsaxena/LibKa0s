# `testkit` — version 66

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files [version 61](version-61-docs.md) lists |
| Version | **66** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.119.0 |
| Status | **Current** |
| Supersedes | [version 65](version-65-docs.md) — the automated-test runner refused a library checked out as a `git worktree`, whose `.git` is a file, and named a library by its checkout's folder |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `66` |

Everything revision 65 describes is unchanged here except what follows. No file is added or removed,
and no kit case is added, removed or renamed. `framework.lua`'s `Kit.VERSION` is 66. The item is
F-011 of this repo's review `docs/reviews/2026-11-28/`, fixed in `IS-F1` of Ka0s Drop Watcher's plan
`docs/superpowers/plans/2026-11-27-itemsearch-split.md`.

## What changed

### `run-automated-tests.sh`: a library in a `git worktree` runs, named by its repository

A repo with no `.toc` (a library) is identified by git. Revision 65 tested `[ ! -d .git ]`, which is
false in a `git worktree` checkout, where `.git` is a file naming the repository's git dir, so the
runner stopped with `no .toc here and no .git` and a release gate could only be taken from a fresh
clone. Revision 66 asks git instead (`git rev-parse --git-dir`), and names the library by the folder
that holds the repository's common git dir (`git rev-parse --git-common-dir`), so a worktree's bundle
carries the repository's name, not the worktree folder's. An ordinary clone answers as before, and a
repo whose common git dir is not a `.git` folder keeps the working folder's name. An addon (a repo
with a `.toc`) is read exactly as at revision 65.

## What a consumer owes

The whole-folder copy of `tests/_kit/`, as at every revision. A suite that pins `KIT_VERSION` at 65
re-pins it at 66. Nothing else: no mock, fixture or gate moved.
