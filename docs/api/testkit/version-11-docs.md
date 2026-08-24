# `testkit` — version 11

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **11** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.9.0 |
| Status | Superseded |
| Supersedes | [version 10](version-10-docs.md) — the vendored-payload gate now recurses, and leaves binaries alone |
| Superseded by | [version 12](version-12-docs.md) — the loader caches compiled chunks, and the runner can fan its suites out across processes |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `11` |

## What changed at this version

One file, `vendor_sync.lua`, and two changes to the same comparison. No Lua surface moved:
`register(T, opts)` takes what it always took and the case names are unchanged, so adopting this is a
copy and nothing else. `framework.lua` moves only for `Kit.VERSION` itself.

| | | Since |
|---|---|---|
| Recursive listing | Both sides of the comparison now list **files, recursively**, as paths relative to the payload root. `git ls-tree -r` on the tag side; `find -type f` (or `dir /b /s /a-d`) on the working-tree side. | **11** |
| Binary-safe compare | A path whose extension is a known binary type is compared **byte for byte**, with no line-ending normalization. Text is normalized exactly as before. | **11** |

### Why: the first payload with a subdirectory

`LibKa0s v1.9.0` ships `LibKa0s/media/` — 49 icon TGAs and a font. Every payload before it was flat,
and the gate was written to that shape: `git ls-tree --name-only` without `-r` lists **one level**, so
`media` came back as a name and the comparison then tried to read a directory as a file. The failure
was real but pointed at nothing wrong, and it would have hit every consumer the moment it
re-vendored.

Recursing is also what "byte-for-byte what the tag published" was always supposed to mean. A file
added three levels down is now compared like any other, and a file added on one side only still fails
on the set comparison that runs first.

### Why: the CR strip is corruption on a binary

The gate compares the working tree against the git blob, and strips CR from the working-tree side
because a text file is CRLF on disk in a repo pinned `* text=auto eol=crlf` and LF in the blob.

Applied to a TGA or a TTF that same strip is **data corruption**: any binary whose bytes happen to
contain the pair `0D 0A` would be reported as diverged from the very blob it round-trips to, and the
message would name a line-ending problem in a file that has no lines.

**None of the 49 TGAs in v1.9.0 contains that pair**, which is exactly why this is worth writing down
rather than leaving to be discovered — the gate would have passed today, and the next icon added
could have broken it for a reason nobody would look for here. Binary types are recognized by
extension, from a list that matches the `binary` pins in every repo's `.gitattributes`:

```
tga png jpg jpeg gif bmp ico blp ttf otf mp3 ogg wav zip
```

An extension not on that list is treated as text, which is the safe default: normalizing a text file
is correct, and the only cost of missing a binary is the false failure above — loud, not silent.

## Adopting it is one commit

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

**Required before vendoring LibKa0s v1.9.0 or newer**, because that release is the first whose
payload has a subdirectory. A consumer staying on v1.8.3 needs nothing: its gate compares against the
tag its own `CLAUDE.md` names, and that tag's payload is still flat.

## Vendoring

Whole-folder, from the library repo's root — the same cwd `docs/releasing.md` assumes:

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

**Never edit `tests/_kit/` in a consumer.** A kit problem is a finding to fix here and re-vendor; a
local patch is a fork nobody knows about, and the next re-vendor silently reverts it.

LibKa0s is a consumer on the same terms as every addon: it reaches its own kit through `tests/_kit/`
rather than into `testkit/` directly, so `diff -r testkit tests/_kit` is the same gate here as it is
downstream, and a kit change that would break a consumer breaks this repo first.

## Bumping the revision

1. Change the kit, with its test.
2. Bump `Kit.VERSION` at the top of `testkit/framework.lua`.
3. Write `docs/api/testkit/version-<N>-docs.md`; mark this one `Superseded` and fill in its
   `Superseded by`. `tests/test_kitsync.lua` fails if the document for the live version is missing.
4. Re-vendor into `tests/_kit/` here **and** into every consumer's `tests/_kit/`, then run each
   repo's suite.
5. Add the row to [`../README.md`](../README.md).
