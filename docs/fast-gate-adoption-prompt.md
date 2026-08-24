# Fast-gate adoption prompt — drop this into any Ka0s addon repo

Copy everything below the line into a fresh Claude Code session **in the addon's own repo**. It is
self-contained and names what to read rather than restating rules that may have moved on.

**Status:** LibKa0s **v1.14.0 is tagged**. Ka0s Multi Meters adopted it on 2026-08-25 and went from
**2m 10.8s to 7.26s** on 1,246 unchanged cases — and, following the rule below, deliberately did
**not** switch on `--jobs`.

**What each repo's jump includes** (the vendored-payload gate compares *both* payloads against the
tag your `CLAUDE.md` names, so the library moves with the kit — you cannot take kit 12 alone):

| Coming from | Shipped library delta | Risk |
|---|---|---|
| v1.10.2 | `Widgets.lua` **added** plus its `.xml` line — a new major, nothing existing changes | Purely additive |
| v1.12.0 | `Widgets.lua` to minor 5 — the menu-dismissal fix | Only if you consume `LibKa0s-Widgets-1.0` |

---

## Task: adopt the fast green gate (LibKa0s v1.14.0 / testkit revision 12)

This repo is a Ka0s WoW addon built to the **Ka0s WoW Addon Standard**
(<https://github.com/tusharsaxena/WowAddonStandards>). Read this repo's `CLAUDE.md` first, then
**`standards/standards/testing.md` §14** in the standards repo — that section is the rule you are
implementing, and it governs both what to change and what to measure.

Work the steps in order. Stop and ask if a step's premise does not hold; do not improvise around a
failing gate.

### Step 1 — Measure what it costs today, before changing anything

`testing-§14` requires the measurement before the fix, because the intuitive diagnosis is usually
wrong. On Multi Meters the instinct was "too many tests"; the tests were not the problem at all.

```sh
/usr/bin/time -f "%e s wall  %P cpu" lua tests/run.lua
```

Record the case count, the wall clock and the **CPU percentage**. A figure well under 100% means the
process is *waiting*, not working, and no amount of faster code fixes waiting. Keep this — it is the
"before" in your report and there is no second chance to take it.

### Step 2 — Re-vendor from the tag

Prefer **`/wow-addon:revendor-libka0s`** if it is available: it copies both payloads, rolls the
provenance line in the same commit, and reports the delta properly.

By hand, from this repo's root, with the LibKa0s checkout as a sibling at tag v1.14.0 or newer:

```sh
cp -r ../LibKa0s/LibKa0s/.  libs/LibKa0s/
cp -r ../LibKa0s/testkit/.  tests/_kit/
diff -r --strip-trailing-cr ../LibKa0s/LibKa0s libs/LibKa0s    # content — MUST be empty
diff -r --strip-trailing-cr ../LibKa0s/testkit tests/_kit      # content — MUST be empty
```

Then roll the **provenance line** in this repo's root `CLAUDE.md` to the tag you vendored —
`Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.14.0 (MIT).` The vendored-payload
gate reads the version from that line and nowhere else, so a copy updated without it compares
against the wrong tag and fails for a reason that looks like the wrong thing.

**Never edit anything under `tests/_kit/` or `libs/`.** A problem there is an upstream fix in
LibKa0s plus a re-vendor. A local patch is a fork nobody knows about, and the next re-vendor reverts
it silently.

### Step 3 — Verify, and measure again

```sh
lua tests/run.lua && luacheck .
```

Same pass count as step 1, `luacheck` 0/0. Then re-time it exactly as in step 1.

Three failures are worth recognizing on sight:

- **The payload gate fails naming `tests/_kit` or `libs/LibKa0s`.** The copy does not match the tag
  `CLAUDE.md` names — either the copy is incomplete or the provenance line was not rolled. Fix the
  copy or the line, never the test.
- **A load-list assertion trips on `Widgets.lua`.** Coming from v1.10.2 you are gaining a file.
  Runners derive the library list from `LibKa0s.xml`, so this usually just works; if this repo pins
  an expected-file list, add the new entry there. Do not stop deriving the list.
- **A suite fails that passed before.** Do not weaken it. The chunk cache does not change isolation
  — it caches a *function*, so every instance still calls it and still builds its own state — so a
  new failure here is a real finding. Report it.

### Step 4 — Decide on `--jobs`, deliberately

**If the suite is now under ~10 seconds, stop. Do not switch `--jobs` on.** That is the rule, not a
shortcut: Multi Meters landed at 7.26s and declined it, because the remaining win is small and the
complexity is not free. Record the figure and go to step 5.

If it is still slow, ask *why* before sharding. `testing-§14` puts parallelism last because fanning
out duplicated work is a fraction of what deleting the work is. Profile first:

```sh
for i in $(seq 1 8); do printf "shard %d: " $i; /usr/bin/time -f "%e s" lua tests/run.lua --shard $i/8; done
```

If one shard dominates, the fix is that **case**, not more processes — a shard can only be as fast
as its slowest case. That is exactly how the `git show`-per-file problem was found. Report what you
find rather than sharding around it.

Only when the load is genuinely spread, confirm the sharded run agrees:

```sh
lua tests/run.lua -j auto
```

It must report **the same totals and the same exit code**, and its case output must be byte-identical
to the serial run's. Verify that, do not assume it:

```sh
diff <(lua tests/run.lua 2>&1     | grep -v '^$\|passed,') \
     <(lua tests/run.lua -j auto 2>&1 | grep -v '^$\|passed,')
```

**If a suite passes serially and fails sharded, you have found a real bug — not a reason to stay
serial.** Sharding splits the process-wide state suites share (the `shared` instance, the
SavedVariables globals), so it *reveals* an inter-suite dependency rather than creating one. Fix the
suite so it stands alone.

Once it agrees, opt in via this repo's `Kit.run{ … }` call in `tests/run.lua`:

```lua
Kit.run{ dir = root .. "/tests/", suites = SUITES, jobs = "auto" }
```

Then re-run plain `lua tests/run.lua` and confirm it is still green.

### Step 5 — Record it

- Run `tests/_kit/run-automated-tests.sh` so the bundle and `RESULTS.md` carry today's numbers.
  **If the verdict is amber, establish whether each reason is pre-existing** — re-run that suite
  against `HEAD` before your copy and compare — and say so either way. Do not report an inherited
  amber as caused by this change, and do not quietly drop one that is.
- Update `docs/testing.md` if it quotes a gate command or a figure.
- If the pass count moved at all, regenerate the inventory and the README badge **in the same
  change**: `lua tests/run.lua --list > docs/test-cases.md`.

### Step 6 — Smoke-test what the library jump touched

Headless tests cannot see click routing. If this repo looks up `LibKa0s-Widgets-1.0` anywhere
outside `libs/` and `tests/` —

```sh
grep -rn 'LibKa0s-Widgets-1.0' --include='*.lua' . | grep -v '/libs/' | grep -v '/tests/'
```

— then v1.13.0's menu-dismissal change is live in this addon: the dropdown menu no longer sits
behind a full-screen click catcher that ate the click closing it and ignored right-clicks entirely.
Add a line to `docs/smoke-tests.md` and verify in the client that one press both dismisses the menu
**and** reaches whatever is under the cursor. If nothing prints, skip this step and say so.

### Step 7 — Report

State plainly:

- **Before / after**, wall clock and CPU%, with the case count (which should be unchanged).
- Whether `--jobs` was adopted and **why or why not** — "under 10s already" is a complete answer.
- Any suite that failed sharded, and what the dependency turned out to be.
- Whether the automated-test verdict changed, and for pre-existing problems, the evidence that they
  are pre-existing.
- Anything that had to change outside `tests/_kit/` and `libs/`.

Do not push, and do not bump this addon's version, without being asked.
