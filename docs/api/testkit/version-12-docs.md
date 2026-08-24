# `testkit` — version 12

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `vendor_sync.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **12** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.14.0 |
| Status | **Current** |
| Supersedes | [version 11](version-11-docs.md) — the loader caches compiled chunks, and the runner can fan its suites out across processes |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `12` |

## What changed at this version

Two files, and they are independent of each other. `loader.lua` stops re-reading source it has
already read. `framework.lua` gains a way to run the suites in more than one process. Neither
removes or renames anything: every existing call site compiles and behaves as it did, so adopting
this is a copy plus — for the parallel half only — a deliberate switch-on.

| | | Since |
|---|---|---|
| Chunk cache | `Loader.load` compiles each path **once per process** and re-calls the cached chunk for every later instance. Isolation is unchanged: the cache holds a function, not a result. | **12** |
| `Loader.uncache(path)` | Drops one path from that cache, or the whole cache when called with no argument. For a suite that rewrites a source file and re-loads it. | **12** |
| `--jobs N` / `-j N` / `--jobs auto` | Fan the declared suites across N worker processes and aggregate the result. `auto` asks the host for its CPU count. | **12** |
| `--shard I/N` | Run only contiguous slice I of N. Set by the driver on each child; not for hand use. | **12** |
| `Kit.run{ jobs = ... }` | The runner's own default worker count. `--jobs` on the command line overrides it. Defaults to `1`. | **12** |
| `Kit.runParallel(jobs)` | The driver itself, exposed so a runner can call it directly. Returns the exit code, or `nil, reason` when the platform cannot fan out. | **12** |
| Batched blob reads | `vendor_sync` reads every blob of a payload with **one** `git cat-file --batch` instead of one `git show` per file. An empty blob now compares as an empty string rather than as "missing". | **12** |

### Why: `loadfile` was 91% of the run

A suite that wants a fresh, isolated instance re-loads the entire source tree — the vendored
library, then every file the TOC names. That shape is correct, and this change does not touch it:
isolation comes from re-*running* the chunks under a new mock, never from unpicking what the last
instance did.

What it was also doing was re-*reading*. `loadfile` re-opens, re-reads and re-parses an unchanged
file on every instance, and a real suite builds hundreds of instances. Measured on Ka0s Multi
Meters: **1,246 cases drove 60,112 `loadfile` calls**, 28.5s of the run's 31.4s of CPU. Wall clock
was 2m10s, because the checkout sits on a WSL2 `/mnt` mount and every one of those reads crosses a
9p boundary at roughly 1.5ms.

Caching the compiled chunk took that same suite to **11.9s** — an 11x improvement, with no change to
any test.

The subtlety, and why it is sound in Lua 5.1: `setfenv` sets the environment a chunk sees *when it
next runs*, and a closure created during that run inherits the environment its parent held *at
creation time*. Calling one cached chunk under env A and then under env B therefore leaves A's
closures reading A and B's reading B — two instances never share a global namespace.
`tests/test_loader.lua` pins that directly rather than trusting the paragraph.

The cache is keyed by path and lives for the process. Stat'ing every file on every load to detect a
mid-run rewrite would buy back the syscall the cache exists to avoid, so a suite that rewrites
source must say so with `Loader.uncache(path)`.

### Why: what was left was subprocess latency, not work

With the reads gone, the same suite spent 2.4s of CPU inside an 11.9s wall clock. The other 9.5s was
**147 `io.popen` calls** — directory listings and `git` invocations, each costing tens of
milliseconds to spawn and nothing to compute. That is latency, and latency is what more processes
fix.

```sh
lua tests/run.lua              # serial, exactly as before
lua tests/run.lua -j auto      # one worker per CPU
lua tests/run.lua --jobs 4     # four workers
```

Each child is a plain re-invocation of the **same** `tests/run.lua` with `--shard I/N`. There is no
worker script and no second code path to keep in step — the property that already makes `--list`
trustworthy, applied again.

Three things the driver guarantees:

- **Output is byte-identical to a serial run.** Shards take *contiguous* slices of the declared
  suite list, and the driver relays shard 1's output, then shard 2's, in order. A gate whose output
  reshuffles on every run is a gate nobody diffs. Verified on this repo: 578 lines, identical.
- **A shard that dies goes red.** Each child ends with a machine-readable count line; a child that
  never printed one did not finish, so its cases are missing from the totals and the run fails with
  that named. This is `assertSuiteInventory`'s rule — a gate that goes quiet when it cannot look is
  worse than no gate — applied to the fan-out.
- **`--list` never shards**, and neither does a child: `--shard` forces `jobs = 1`, so a runner
  carrying `jobs = "auto"` cannot fork a process tree.

Where there is no POSIX shell to background from, the driver returns its reason and the run
**falls back to serial with a `NOTE`** rather than failing.

### Why: the vendored-payload gate was spawning one `git` per file

With the reads cached and the fan-out working, one case was still the longest thing in a consumer's
suite: the vendored-payload gate. `gitShow` ran `git show <tag>:<path>` **once per file**, and a
payload is not a few files — LibKa0s v1.9.0 ships 49 icons and a font, so Ka0s Multi Meters was
spawning about 66 `git` processes and spending **7.5 seconds** on them.

That also capped the fan-out, because a shard can only be as fast as its slowest case. Measured
across 12 shards, eleven finished in under 1.3s and the one holding this case took 7.86s — so the
whole parallel run took 7.86s no matter how the suites were split. No partitioning scheme fixes
that; only making the case itself faster does.

`git cat-file --batch` answers every blob from **one** process. It takes its request list on stdin,
which Lua 5.1's unidirectional `io.popen` cannot write to, so the list goes through a temp file and
is redirected in. Each reply is `<oid> <type> <size>`, a newline, exactly `<size>` bytes, then one
more newline — so the payload is sliced by **length, never by pattern**, and a blob carrying
newlines, NUL bytes or CRLF round-trips unharmed. That is what makes it safe for the TGAs and the
TTF, not only the Lua. A ref git cannot resolve answers `<ref> missing` and maps to no entry, which
every caller already treats as "could not answer" rather than as "matched".

The gate's behavior is otherwise unchanged, and was verified by breaking it on purpose: appending
`0D 0A 00` and a few bytes to one vendored TGA still fails the run, naming that exact file.

One difference, and it is a fix: `gitShow` mapped an empty result to `nil`, so a legitimately
**empty** vendored file read as "the tag does not carry this". A batched empty blob is an empty
string and compares equal to an empty local file.

## Parallelism is opt-in, per repo, on purpose

The chunk cache is automatic and invisible — nothing to switch on, nothing to verify.

`--jobs` is not, and `Kit.run`'s default stays `1`. Splitting the suites across processes also
splits the process-wide state they share: the `shared` instance the runner builds once, and the
SavedVariables globals. A suite that quietly depended on an earlier suite having run first passes
serially and fails sharded.

That dependency was always a bug — `testing-§12`'s point is that a test which cannot fail is worse
than no test, and a test that only passes because of what ran before it is a cousin of that. `--jobs`
is what makes it visible. So switch it on deliberately, per repo, and confirm the run is green
before making it the gate.

## Adopting it is one commit

A step-by-step prompt for doing this in an addon repo — including the measurement `testing-§14`
requires before and after — is [`../../fast-gate-adoption-prompt.md`](../../fast-gate-adoption-prompt.md).

```sh
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit             # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

The cache is live at that point and the suite should simply be faster. To take the parallel half as
well, run it sharded once and confirm it agrees:

```sh
lua tests/run.lua -j auto                      # same totals, same exit code
```

then pass `jobs = "auto"` in that repo's `Kit.run{ ... }` call and record the new figure.

End to end on Ka0s Multi Meters, 1,246 cases, WSL2 `/mnt` checkout, 16 cores:

| | Wall |
|---|---|
| Before | 2m 10.8s |
| Chunk cache | 11.6s |
| Batched blob reads | 8.2s |
| `-j 12` | **3.7s** |

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
