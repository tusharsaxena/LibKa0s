# `testkit` — version 9

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **9** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.8.1 |
| Status | Superseded |
| Supersedes | [version 8](version-8-docs.md) — moves `vendor_sync.lua`'s provenance line from `README.md` to `CLAUDE.md` and names the file through an opt |
| Superseded by | [version 10](version-10-docs.md) |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `9` |

## What changed at this version

One change, in one file. `vendor_sync.lua` reads the LibKa0s provenance line — *"Bundles
[LibKa0s](…) vX.Y.Z (MIT)."* — out of the consumer's **`CLAUDE.md`** instead of its **`README.md`**.

| | |
|---|---|
| `opts.provenanceFile` | New. Default `"CLAUDE.md"`. Which doc, relative to `root`, carries the line. |
| `opts.provenancePattern` | New name for `opts.readmePattern`, which named the file rather than the thing. The old name is still accepted. |
| Case name | `libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles` — was *"the README says"*. |
| Failure message | Names the configured file rather than the literal string `README.md`. |

Nothing else in the kit moved. Every other file is byte-identical to version 8.

### Why the line moved

The provenance line answers *"which LibKa0s does this build carry?"* That is a maintainer's question.
`README.md` is the addon's user-facing page, and across this collection it is being reduced to what a
player needs — the bundled-library inventory comes out of it entirely. A gate that reads its input
from a file whose purpose is to stop mentioning the input is a gate on a countdown.

`CLAUDE.md` is where the repo already keeps the facts a maintainer or an agent needs about the build,
so the line goes there and the gate follows it.

### There is no fallback, deliberately

A consumer that has not moved its line reads as carrying **no provenance line at all** and the case
**fails**, naming `CLAUDE.md`. A fallback to `README.md` would let a repo sit half-migrated
indefinitely, with two lines that can disagree and a gate that silently prefers one of them — which
is the same shape as the drift this file exists to catch.

### Adopting it is one commit

Unchanged from version 8, and for the same reason: the gate compares **file sets** and reads the
provenance line as its input, so the re-vendor and the line's move must land together.

1. `cp -r testkit/. <Addon>/tests/_kit/` from a LibKa0s checkout at the tag being adopted.
2. Move the *Bundles [LibKa0s](…) vX.Y.Z (MIT).* line into `<Addon>/CLAUDE.md`, naming that tag.
3. Regenerate `docs/test-cases.md` — the first case's name changed, so a repo that pins its inventory
   is red until it does.
4. `lua tests/run.lua && luacheck .`

Step 3 is the one that surprises people: this revision moves a **case name**, which is the only
version-8-to-9 change visible outside `tests/_kit/`.

---

## `vendor_sync.lua` — the full `opts` surface at this revision

```lua
-- tests/test_vendor_sync.lua, in full
local VendorSync = dofile("tests/_kit/vendor_sync.lua")
VendorSync.register(_G.AT_TEST, {})
```

| `opts` key | Default | What it is |
|---|---|---|
| `root` | `"."` | the consuming repo root, as the suite sees it |
| `sibling` | `<root>/../LibKa0s` | the library checkout tags are read out of |
| `probe` | `"HEAD:LibKa0s/Core.lua"` | the ref that answers "is the sibling there at all?" |
| `provenanceFile` | `"CLAUDE.md"` | which doc, relative to `root`, carries the provenance line |
| `provenancePattern` | `"[Bb]undles %[LibKa0s%]%b() (v[%d%.]+)"` | how that line is spelled |
| `readmePattern` | — | accepted as a name for `provenancePattern`; retained so a repo passing it does not break on the way past |
| `pairs` | `libs/LibKa0s` + `tests/_kit` | `{ case, tag, local_, label }` per compared payload |

No repo in the collection needs either pattern override: the lowercase/mid-sentence leniency is
already in the shipped pattern, because some repos write the line inside a sentence rather than as
one.

Everything else about the gate — what it compares, the single CR-stripping normalization, SKIP when
the sibling checkout is absent, and the two properties of the gate living inside the payload it
checks — is unchanged from [version 8](version-8-docs.md#what-it-compares-and-the-one-normalization)
and is not restated here.

## The legacy `gating` boolean is still emitted

Version 8's document scheduled `suites.<name>.gating` for removal at this revision. It is **still
emitted**, beside `gates`. This revision is a one-file change cut to move the provenance line, and
dropping a manifest field in the same release would put two unrelated adoption costs on one
re-vendor. Nothing in the collection reads either field; the removal is deferred, not cancelled.

## Compatibility

The kit surface is **additive-only** on the same terms as the library: a function or seam may be
added in a later revision, never removed or repurposed, so a suite written against version 1 keeps
working unmodified. `readmePattern` is retained under that rule.

The **provenance file** is the one thing this revision changes rather than adds, and it is not part
of the Lua surface — it is where the gate looks for its input. A consumer adopting version 9 without
moving its line gets a clear failure naming the file it should be in, which is the intended
migration signal.

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

## Moving to 10

[Version 10](version-10-docs.md) changes one file, `run-automated-tests.sh`, and changes no Lua
surface at all. Everything above about `vendor_sync.lua` — `provenanceFile`, `provenancePattern`, the
retained `readmePattern` alias, and the case name this revision moved — is true of version 10
unchanged.

What version 10 adds is a line-ending pass at the end of a bundling run. Up to and including this
revision the runner wrote every bundle file with a plain shell redirect, which bypasses git's
clean/smudge filters, so in a repo pinned `* text=auto eol=crlf` — which is every client-bound repo
in this collection, LibKa0s included — the bundle landed **LF on disk while `.gitattributes` said
CRLF**. `git status` never mentioned it, before the commit or after, and `git add --renormalize`
never fixed it, because the index was already correct. Version 10 reads the declared terminator per
path with `git check-attr eol` and rewrites only what disagrees.

**Adopting 10 is `cp -r testkit/. <Addon>/tests/_kit/` and the provenance line, nothing more.** No
case name moves, so unlike the 8 → 9 hop, `docs/test-cases.md` does not need regenerating for the
kit's sake. Bundles already on disk are not repaired by adopting — they need the one-time
`rm <path> && git checkout -- <path>` from `.gitattributes`' own footer, per repo.
