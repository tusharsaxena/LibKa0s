# `testkit` — version 10

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **10** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.8.2 |
| Status | Superseded |
| Supersedes | [version 9](version-9-docs.md) — the runner now writes the bundle to the terminator `.gitattributes` declares |
| Superseded by | [version 11](version-11-docs.md) — the vendored-payload gate recurses into subdirectories and leaves binaries alone |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `10` |

## What changed at this version

One change, in one file. `run-automated-tests.sh` normalizes the line endings of everything it wrote
before it exits, to whatever `.gitattributes` declares for each path.

| | | Since |
|---|---|---|
| Bundle line endings | Every file in `docs/automated-tests/<STAMP>/`, plus `RESULTS.md`, is left carrying the terminator `git check-attr text eol` reports for it. | **10** |
| Binary paths | A path whose `text` attribute is `unset` — which is what `binary` expands to — is skipped before a byte of it is read. | **10** |
| `unspecified` repos | A repo that declares no `eol` for a path is left byte-for-byte alone. | **10** |
| Second pass | A file already carrying the declared terminator is not rewritten — no byte and no mtime moves. | **10** |
| Trailing newline | A written file whose last line lacked one **gains** one. See *The one byte this is not honest about*. | **10** |

Nothing else in the kit moved. Every other file is byte-identical to version 9, and no Lua surface
changed — `framework.lua` moves only for `Kit.VERSION` itself.

### The defect

Every file the runner puts in a bundle is written with a plain shell redirect. A redirect is a kernel
write into the working tree; it never passes through git's clean/smudge filters, so the `eol=crlf`
that every client-bound repo in this collection declares had no effect on any of it. The bundle
landed **LF on disk in a repo that says CRLF** — on every run, in nine repos.

Nothing reported it. The blob is LF in the index either way, which is where LF belongs, so
`git status` is silent before the commit and after it, and `git add --renormalize` does not help:
it rewrites the *index*, and the index was never wrong. Only a `file` or byte-level line-endings
audit ever saw it, which is why it survived as long as it did.

### Why one pass at the end, and not a fix at each writer

`perf.json` is not written by the runner at all. The runner passes `--out` to the addon's own
`tests/perf.lua`, and that harness creates the file. Fixing the writers would mean reaching into
eight addons' perf harnesses — and would still miss whatever the next suite decides to drop into the
bundle directory. A pass over the finished directory covers every file however it got there.

### Why it asks for `text` and not just `eol`

The pass asks `git check-attr text eol` and **skips any path whose `text` is `unset`**. That is the
primary binary test, and it is not interchangeable with the NUL heuristic below it.

`binary` is a macro for `-text -diff`, and it says **nothing at all about `eol`**. So a path marked
`*.png binary` in a repo pinned `* text=auto eol=crlf` still answers `eol: crlf` — inherited from the
pin line — for a file git itself will never convert:

```
$ git check-attr text eol -- asset.png lint.txt
asset.png: text: unset
asset.png: eol: crlf
lint.txt: text: auto
lint.txt: eol: crlf
```

Acting on the `eol` answer alone rewrites the asset. The NUL heuristic catches the common binary and
is kept as a second line of defence, but it cannot be the first: a binary format that happens to be
NUL-free walks straight through it. `line-endings-§4` names the live example —
`realesrgan-x4plus-anime.param`, whose ncnn format is plain ASCII — and that is a model definition
sitting beside its own weights. `text: unset` is a declaration; a NUL scan is a guess.

This is the same correction `line-endings-§7` made to the audit's working-tree check and
`wow-addon/scripts/normalize-eol.sh` made to the `Write`/`Edit` hook. All three now read `text` first.

### Why it reads git rather than assuming CRLF

`git check-attr` is the only thing that knows what a given repo pins. It answers correctly for a path
that is untracked or does not exist yet, it already honours carve-outs such as `*.sh text eol=lf`,
and an `unspecified` answer gives an exact, free no-op for a repo that has declared nothing. The
alternative — an unconditional `unix2dos` or `sed -i 's/$/\r/'` sweep — needs a tool that may not be
installed and doubles CRs on the `RESULTS.md` append path, which already emits the header's own
terminator correctly and was the one write site here that was never broken.

Dependencies are `git`, `awk`, `tr`, `cmp`, `mv` and `rm` — all POSIX, and all already required by
the runner. No `unix2dos`/`dos2unix`.

### The one byte this is not honest about

The rewrite is line-oriented, so **a file whose last line had no trailing newline gains one**:
`x\ny` normalizes to `x\r\ny\r\n`. That is the single respect in which the pass is not
"byte-identical apart from the terminators", and it is stated here rather than left to be found.

Everything the runner itself writes ends with an explicit newline, so the exposure is exactly two
files: `test-cases.md` (from `lua tests/run.lua --list`) and `perf.json` (from `tests/perf.lua`), if
either ever omits its final newline. Both are text records where a supplied final newline is an
improvement — but it is a real byte change.

A file containing a NUL byte is skipped as well, on top of the `text: unset` test above. Nothing in
a bundle is binary today; both guards are there so that the day something is, this cannot corrupt it.

### What it does NOT cover

- **`--no-bundle`.** The pass runs only when a bundle is written, which is correct — `--no-bundle`
  writes nothing — but it also means that mode gives no signal about the repo's declared terminator.
- **`ANALYSIS.md`.** That file is written by the `/wow-addon:automated-tests` skill agent, after the
  runner has exited, into the same directory. It is outside this pass and will still be an LF
  straggler in a CRLF-pinned repo unless the playbook writes CRLF itself.
- **Dotfiles in the bundle.** The pass is driven by `"$OUT"/*`, which does not match them. Nothing in
  a bundle is a dotfile today.
- **Bundles already on disk.** This fixes runs from now on. Existing stragglers need the one-time
  repair `.gitattributes` documents in its own footer — `rm <path> && git checkout -- <path>`, then
  confirm with `file <path>`.

## Adopting it is one commit

1. `cp -r testkit/. <Addon>/tests/_kit/` from a LibKa0s checkout at the tag being adopted.
2. Move the *Bundles [LibKa0s](…) vX.Y.Z (MIT).* line in `<Addon>/CLAUDE.md` to that tag.
3. `lua tests/run.lua && luacheck .`

No case name moves at this revision, so a consumer's `docs/test-cases.md` does **not** need
regenerating for the kit's sake — unlike version 9, where it did.

The first bundle written after adoption is the fix demonstrating itself: check it with
`file docs/automated-tests/<STAMP>/*` and expect *"with CRLF line terminators"* in a CRLF-pinned
repo.

## `vendor_sync.lua` — the full `opts` surface at this revision

Unchanged from [version 9](version-9-docs.md#vendor_synclua--the-full-opts-surface-at-this-revision)
in every respect — `provenanceFile`, `provenancePattern`, the retained `readmePattern` alias, `root`,
`sibling`, `probe` and `pairs` — and not restated here.

## The legacy `gating` boolean is still emitted

Still emitted, beside `gates`, for the third revision running. Nothing in the collection reads either
field; this revision is a one-file bug fix and dropping a manifest field alongside it would put two
unrelated adoption costs on one re-vendor. Deferred, not cancelled.

## Compatibility

The kit surface is **additive-only** on the same terms as the library: a function or seam may be
added in a later revision, never removed or repurposed, so a suite written against version 1 keeps
working unmodified. No Lua surface changed at this revision at all.

The behaviour change is to **bytes on disk in the consumer's own repo**, not to any API. A consumer
whose repo declares `eol=lf`, or declares nothing, sees no change of any kind.

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
