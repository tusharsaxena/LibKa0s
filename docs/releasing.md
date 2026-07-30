# Releasing LibKa0s

Two version numbers, one of which is load-bearing at runtime.

| Number | Lives in | Who reads it | When it moves |
|---|---|---|---|
| Repo semver (`v1.2.0`) | git tag, `CHANGELOG.md` heading | humans | once per release |
| File minor (integer) | `MINOR` / `PANEL_MINOR` at the top of each file in `LibKa0s/` | **LibStub, at load time** | every released change to that file |

The semver tag is a courtesy. The **file minor is the mechanism**: LibStub keeps the highest minor it
is offered for a major and discards the rest, so of the copies vendored across every installed addon,
exactly one wins. A released change that does not bump its file's minor therefore does not ship — any
host already carrying the old copy keeps running it, and nothing errors to say so.

## Order of operations

1. **Make the change**, with its test. Green gate: `lua tests/run.lua` and `luacheck .` (0/0).
2. **Bump the minor of every file you changed.** `MINOR` in `Perf.lua`, `PANEL_MINOR` in
   `PerfPanel.lua`. A file you did not touch does not move. Bumping the whole lib in lockstep would
   discard the narrow-skew property that made one major per module worth having.
3. **Update `CHANGELOG.md`**: the release's version block names each file's new minor, and the entries
   say what changed. `tests/test_versioning.lua` fails if the block and `lib.MODULES` disagree, so
   this is enforced rather than remembered.
4. **Regenerate the case list**: `lua tests/run.lua --list` into `docs/test-cases.md`, keeping CRLF
   (see that file's own banner for the exact command).
5. **Green gate again**, then commit and tag the repo semver.
6. **Re-vendor every consumer** — see below. This is part of the release, not a follow-up.

## Re-vendoring consumers

Two payloads, with different destinations and different reasons for existing.

**The library** is the inner `LibKa0s/` folder and nothing else. `docs/`, `README.md`, `CHANGELOG.md`
and `LICENSE` stay here.

```
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r LibKa0s <Addon>/libs/LibKa0s        # must be empty
cd <Addon> && lua tests/run.lua && luacheck .
```

**The test kit** is `testkit/`, and it goes to `<Addon>/tests/_kit/` — never to `libs/`, because
`libs/` is the ship payload and the kit must never be zipped. Under `tests/` it is already covered
by the `- tests` entry every addon's `.pkgmeta` already carries, so adopting it needs no packaging
change.

```
cp -r testkit/. <Addon>/tests/_kit/
diff -r testkit <Addon>/tests/_kit          # must be empty
```

Rules, and the reason each exists:

- **Copy the WHOLE folder, always. Never one module.** With one major per module and independent
  minors, per-module re-vendoring is exactly how cross-major skew gets manufactured: an addon ends
  up carrying a new `Options.lua` over an old `Core.lua`, and the symptom is a nil-value error at
  panel-build time in whichever addon the user happens to open. There is no version negotiation
  between majors, and the paired-minor guard that protects a secondary file within a major does not
  generalise across them. Whole-folder copying is the mitigation.
- **The vendored copy MUST be byte-identical to the ship folder.** `diff -r` empty, every time. A
  hand-patched `libs/` copy is a fork nobody knows about.
- **A library change MUST be followed by a re-vendor commit in every consumer that depends on it**,
  and that commit SHOULD be its own, so the sync is legible in history rather than buried in a feature
  diff.
- **This is the step that gets forgotten.** It already happened once, during the extraction that
  created this library: a fix landed here, AbsorbTracker was not re-vendored, and both repos' test
  suites stayed green the whole time — the library's tests passed against the library, and the addon's
  tests passed against a stale copy that still worked. An `after-the-fact` `diff -r` was the only
  thing that caught it. Nothing about "the tests are green" will tell you the copies have diverged.

Vendoring a third-party library is a one-time copy that stays stable for months. Vendoring a library
you also author is an ongoing **sync**, and the drift window is a single afternoon.

## Consumers

- **AbsorbTracker** — `libs/LibKa0s/`, descriptor in `core/PerfSetup.lua`.

Add each addon here as it adopts the lib, so "every consumer" in step 6 is a list rather than a
memory. Planned: KickCD (deliberately second, as the most structurally complex), then LootHistory,
BankLedger, ConsumableMaster, WhatGroup.

## Before the first public release

Publication freezes the descriptor contract in the wild — after it, a field may be added but never
removed or repurposed, because you cannot know who has vendored what. Outstanding items to settle
first are tracked as issues on the repo.
