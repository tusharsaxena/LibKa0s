# Review findings — LibKa0s v1.119.0, `LibKa0s-Verdict-1.0` (branch `feat/2026-11-27-itemsearch-split`)

**Verdict: minor issues.** No Critical or High finding. Two Medium design findings are about the
major's future-release and host seams, and neither is reachable by a player today.

**Resolved scope:** `branch`: `git diff master...HEAD` (merge-base `4dbc1636`, HEAD `110e02be`, 6
commits, 52 files, +43240/-28). Reviewed: the eleven `LibKa0s/Verdict*.lua` files, the
`LibKa0s.xml` / `DebugLogDiagnostics.lua` / `.luacheckrc` / `tests/majors.lua` / `tests/run.lua`
wiring, the fourteen new `tests/*verdict*` files, and the Verdict and DebugLog API documents,
CHANGELOG, README and releasing notes. The frozen bundle `docs/automated-tests/20261127-234144/` was
read as evidence and not reviewed. The consumers' `core/VerdictSetup.lua` (DropWatcher, ItemSearch)
were read only to establish reachability. They are not in scope.

Profile: `profile=wow kind=library` (dev-copilot-profile). Standard cross-check: v2.121.0 (2026-11-25),
fetched over the network. The sibling `../WowAddonStandards` checkout is at `b83f039c`, which is
behind origin master `e23dcd5f`, so it was not used.

## Measurement run (2026-11-28, HEAD `110e02be`, from the worktree root)

| Suite | Result | Command |
|---|---|---|
| luacheck | **pass**: 0 warnings / 0 errors in 421 files | `~/.claude/dev-copilot/bin/ka0s-bounded luacheck .` |
| Headless suite, Retail | **pass**: 5544 passed, 0 failed, 3 skipped, 5547 total | `~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua` |
| Headless suite, WoW Forever | **pass**: 5544 / 0 / 3, 5547 total | `KA0S_KIT_CLIENT=forever ~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua` |
| Test-case inventory | **pass**: 6573 lines to scratch, **0 diff lines** against the committed `docs/test-cases.md` (CR-stripped) | `~/.claude/dev-copilot/bin/ka0s-bounded lua tests/run.lua --list > <scratch>` |
| Seed contract | **pass**: 22 passed | `timeout 300 python3 -m pytest -q tools/seeds -p no:cacheprovider` (the cache plugin is off so nothing is written into the repo) |
| Offline perf runner | **not applicable**: the repo has no `tests/perf.lua` | — |
| Complexity (sighted) | **runner skipped, measured by hand**. `bash tests/_kit/run-automated-tests.sh --suite complexity --no-bundle` exited 2 with `no .toc here and no .git` because this checkout is a git worktree, where `.git` is a file (F-011). The runner's own two steps were then run in scratch: the `lizard_sighted.lua shadow` build, then the fixed `lizard -l lua -L 1500 -x "./libs/*" -x "./tests/_kit/*" .` through `ka0s-bounded`. Result: **0 warnings**, 17834 functions, 125259 NLOC, avg CCN 2.2. The four highest Verdict functions sit at CCN 14: `methods.ScoreFor` (VerdictScore.lua:375), `uniquePlan` (VerdictEvaluate.lua:220), `CO.CategoryOf` (VerdictCollect.lua:110) and `kindVerdict` (VerdictCollect.lua:162). The by-hand path skips the runner's parity and blind-file checks, so `blindFiles` was **not measured** today; the bundle records 0 | see cell |
| `make test` | **not applicable**: no root `Makefile` | — |
| Vendor sync, kit | **pass**: `diff -rq tests/_kit testkit` is empty | as shown |
| Vendor sync, consumers | **pass**: `diff -rq <A>/libs/LibKa0s LibKa0s` for DropWatcher and ItemSearch (both on `feat/2026-11-27-itemsearch-split`) is empty outside the `media/icons` and `media/sounds` carve-outs | as shown |
| Cross-addon, roster | 19 addons derived from `WowAddonStandards/standards/ADDONS.md` (sibling checkout) | the `set --` derivation |
| Cross-addon, provenance tags | **split**: 14 at v1.113.0, 2 at v1.114.0, 1 at v1.117.0, 2 at v1.119.0. The re-vendor sweep is in progress, which is normal between releases | the `CLAUDE.md` provenance grep |
| Class 1, slash tokens | **clean**: 36 roots, no duplicates (TOC load-list scope) | the two-pass loop |
| Class 2, vendored minors | **5 distinct lines**. They follow the tag split above and are not caused by this branch. No addon outside DropWatcher and ItemSearch vendors Verdict | the minors loop |
| Class 3, payload bytes | the differences against `AbsorbTracker` follow the tag split and the icon carve-out. Not attributed to this branch | `diff -rq AbsorbTracker/libs/LibKa0s <A>/libs/LibKa0s` |
| Class 4, `## Interface:` | **clean**: one Retail value (120105) and one Forever value (16001) | the Interface loop |

Committed artifacts compared with today's run: the bundle `docs/automated-tests/20261127-234144/`
(`manifest.json` git `55a7c6dc`) records lint 0/0 in 421 files, tests 5544/0/3, complexity 0
warnings and 17834 functions. Today's fresh run matches every figure. `docs/test-cases.md` matches
the fresh `--list` output.

## Medium

### F-001 `[design]` Verdict's secondary files hold `lib.C` and `lib.ClassData` captured at load, while the files that own those tables replace them wholesale every time they run

- **Where:** `LibKa0s/VerdictConstants.lua:33-34` (`local C = {}` / `lib.C = C`) and
  `LibKa0s/VerdictClassData.lua:53-54` (`local CD = {}` / `lib.ClassData = CD`) build new tables.
  Seven files capture `lib.C` at load: `VerdictEvaluate.lua:68`, `VerdictGear.lua:66`,
  `VerdictFacts.lua:65`, `VerdictCollect.lua:59`, `VerdictTierTokens.lua:56`,
  `VerdictSettings.lua:78` and `VerdictClassData.lua:55`, each `local C = lib.C`.
  `VerdictEvaluate.lua:75` and `VerdictSettings.lua:262` capture `local STAT = lib.ClassData.STAT`.
  `VerdictEvaluate.lua:586-599` caches its kernels over the ClassData list that was live when the
  cache was first built (`k = buildKernel(lib.ClassData.ForClient(key), C.SlotPlanFor(key))`).
- **Problem:** the files are paired on the shell's minor, but each one re-runs only when its *own*
  minor rises. Take a release that bumps `VerdictConstants.lua` alone. If the older copy loads first
  (DropWatcher loads before ItemSearch alphabetically), the newer `lib.C` replaces the table. The
  older Evaluate, Gear, Facts, Collect, TierTokens and Settings are not re-run, because their minors
  have not moved, so they keep the old table. Any file that reads `lib.C` at call time sees the new
  one. Which constants a verdict uses then depends on addon load order.
- **Impact:** in a mixed-version session, one judgment can read two different constant sets: slot
  plans, quality ids and feature gates. Both repos' suites stay green, because each loads one copy.
- **Reachability:** nobody today, because every file is at minor 1 in one release. The first player
  to hit it is one running two Verdict consumers at different tags after the first release that bumps
  `VerdictConstants`, `VerdictClassData` or `VerdictTierTokens` alone, with the older copy loaded
  first.
- **Measured:** not measurable headlessly. No case loads two Verdict copies with a secondary-only
  bump. The nearest test, `tests/test_verdict_instances.lua:73-88`, bumps the **shell**, which makes
  every secondary re-run, so it cannot catch this.

### F-002 `[design]` `[api]` The library owns the instance's event set but publishes it only as prose, so both consumers hand-copy it

- **Where:** the events are registered in `lib.__events`, 14 keys:
  `VerdictFacts.lua:464,472`, `VerdictGear.lua:509-522` and the `collect:` loop at
  `VerdictCollect.lua:272-275`. They are listed only in the API document's prose, at
  `docs/api/Verdict/version-1.1.1.1.1.1.1.1.1.1.1-docs.md:123-126`. `StandUp`
  (`Verdict.lua:222-238`) hands one handler per event to `host.registerEvent` and offers no way to ask
  which events exist. Both consumers keep their own copy of the list: DropWatcher
  `core/VerdictSetup.lua:137-144` (`local EVENTS = {`) and ItemSearch `core/VerdictSetup.lua:81-85`.
  Each routes only the names it copied and logs `"... has no NS.FEATURE_EVENTS row; it is not heard"`
  for the rest.
- **Problem:** the event set is library state, but every host has to duplicate it by hand to
  register through `SafeRegisterEvents`, as events-frames-taint-§1 requires.
- **Impact:** an event added in a later Verdict minor reaches no host until each consumer edits its
  copy. A missed edit fails quietly, with one debug line.
- **Reachability:** nobody today. The two copies match the 14 keys at this tag. It bites the first
  Verdict minor that adds or renames an event, for every player of a consumer that was not updated.

## Low

### F-003 `[error-handling]` `StandUp` does not isolate the host's registration per event

- **Where:** `Verdict.lua:225-233`. `self.__registered = {}` is set before the loop, and the loop
  calls `host.registerEvent(event, ...)` bare.
- **Problem:** if a host's `registerEvent` raises, for example a raw AceEvent `RegisterEvent` on a
  name the client lacks, the loop stops. Because `__registered` is already non-nil, a second
  `StandUp` registers nothing, and the stand-up steps (the gear rebuild) never ran.
  events-frames-taint-§1 says a registration block MUST survive one bad name.
- **Impact:** the instance is half registered for the rest of the session.
- **Reachability:** no shipping consumer. DropWatcher and ItemSearch route `registerEvent` into a
  handler table and do the real registration through their own `SafeRegisterEvent` rows. Only a
  future host that registers raw would hit it.

### F-004 `[correctness]` "No config judges on the defaults" is false for `heirloomProtect`

- **Where:** `Verdict.lua:139-148`. `Config()` answers `{}` plus `verdictMode` when the host has no
  config (`local cfg = type(self.host.config) == "function" and self.host.config() or nil`).
  `VerdictGear.lua:446` reads `eval.heirloomProtect = cfg.heirloomProtect == true`, but
  `VerdictSettings.lua:112` sets the shipped default `heirloomProtect = true`. The doc claims the
  opposite at `docs/api/Verdict/...-docs.md:100` ("No config judges on the defaults").
- **Impact:** a host with no config, or a config table that lacks the key, judges without heirloom
  protection, so an heirloom slot reads "upgrade".
- **Reachability:** briefly, any DropWatcher player before `NS.LootFeed` loads, because its `config`
  answers `nil` until then (DropWatcher `core/VerdictSetup.lua:171`). After that, only a future host
  that passes no config.

### F-005 `[lifecycle]` A stood-down instance still starts item loads

- **Where:** `Verdict.lua:62-63` says "while stood down nothing arms". But
  `VerdictFacts.lua:419-434` (`methods:Request`) and `attempt` (`:402-410`) never check `self.down`,
  and `Snapshot()` (`VerdictGear.lua:357-361`) rebuilds lazily and requests every uncached link.
- **Impact:** a `Judge`, `Facts`, `Request` or `Snapshot` call while stood down still calls
  `RequestLoadItemDataByID` and arms `C_Timer.After` up to `MAX_LOAD_TRIES` times. No `onChange`
  fires, because `Changed` is gated.
- **Reachability:** only a host that calls the instance while stood down. Neither consumer does
  this on a documented path.

### F-006 `[perf]` `Request` adds a waiter on every call for a link that is still loading

- **Where:** `VerdictFacts.lua:432`, `if callback then job.waiters[#job.waiters + 1] = callback end`.
  `Judge` passes a fresh closure each time (`VerdictGear.lua:492`).
- **Impact:** N calls to `Judge` on one loading link fire `onChange("item", link)` N times when it
  arrives. A tooltip host that re-judges on every refresh would repaint N times.
- **Reachability:** no shipping consumer calls `v:Judge` (`git grep ':Judge('` finds no call in
  either consumer).

### F-007 `[tests]` "StandUp registers the client's events once" cannot fail on double registration

- **Where:** `tests/test_verdict_instances.lua:123-124` asserts `W.count("gear") == 1` after a
  second `StandUp`. The fixture's `registerEvent` is
  `function(event, handler) W.events[event] = handler end`
  (`tests/fixture_verdict_client.lua:283`), which overwrites the previous handler.
- **Problem:** a `StandUp` that registered every event a second time would still pass. The
  assertion only shows that the snapshot signature did not move. The case has no `-- red under:`
  comment (testing-§12).
- **Reachability:** the test inventory only. The shipped guard (`Verdict.lua:225`) is correct.

### F-008 `[docs]` The Verdict document's lib-level table is cut in two by a blank line

- **Where:** `docs/api/Verdict/version-1.1.1.1.1.1.1.1.1.1.1-docs.md:81` is blank, between the `C`
  row (`:80`) and the `Reads` row (`:82`).
- **Impact:** in rendered Markdown the rows from `Reads` through `Settings` (`:82-88`) have no
  header, so they show as raw pipe text instead of table rows.
- **Reachability:** a reader of the document. No runtime effect.

### F-009 `[ux]` The Pawn import's chat line falls back to the bare global `print`

- **Where:** `VerdictSettings.lua:479`,
  `local say = type(spec.print) == "function" and spec.print or print`.
- **Impact:** without `spec.print`, the import line reaches chat with no addon prefix
  (slash-commands-§4).
- **Reachability:** none today. Both consumers pass `print = function(line) NS.Print(line) end`.

### F-010 `[ux]` The weight slider's range is narrower than what the import and the check accept

- **Where:** `VerdictSettings.lua:274` (`St.WEIGHT_MIN, St.WEIGHT_MAX, St.WEIGHT_STEP = 0, 5, 0.05`).
  The import accepts any signed number (`VerdictScore.lua:81`, `(%-?[%d%.]+)`), and so does
  `validWeights` (`VerdictSettings.lua:140`).
- **Impact:** an imported weight above 5 or below 0 shows pinned to the slider's end. Touching the
  slider then rewrites the imported value.
- **Reachability:** any player who imports a Pawn scale with such a weight, on either consumer's
  Comparison page. How common such scales are is **unverified**.

### F-011 `[tooling]` The automated-tests runner refuses a git worktree

- **Where:** `testkit/run-automated-tests.sh:89`, `if [ ! -d .git ]; then`. In a worktree `.git` is
  a file. This line is not in the branch diff; it is authored kit code that ships to every consumer
  as `tests/_kit/`.
- **Impact:** the release-gate runner cannot run from the worktree this branch is developed in. This
  review had to repeat the runner's two steps by hand, and lost its parity and blind-file checks.
- **Reachability:** any developer who runs the runner from a `git worktree`. No player effect.

### F-012 `[perf]` Per-judgment allocations on the judge path (**unverified**)

- **Where:** `Verdict.lua:142-148` (`Config()` copies the host config on every judgment),
  `VerdictGear.lua:373-380` (`Candidate()` builds a fresh table and an `offSpecGear` closure,
  `:378`), and `VerdictScore.lua:314-335` (`PawnScorer()` builds a new memo, `:315`, on every
  `Scorer` call, so the memo lives for one judgment).
- **Impact:** several tables and closures per judged item. This matters only if a host judges many
  items per frame, for example a search window repainting rows.
- **Reachability:** every judgment on both consumers. The cost is **unverified**: the repo has no
  `tests/perf.lua`, and no capture brackets `evaluate` on a consumer at this tag.

## Non-findings worth recording

- `tests/fixtures/verdict_golden.lua` is byte-identical (CR-stripped) to DropWatcher's
  `tests/fixtures/verdict_golden.lua`, so the "pinned on both sides" claim holds.
- The census figures in the docs check out. `git ls-files 'LibKa0s/*.lua' | wc -l` gives **98**,
  matching `docs/releasing.md` (scope: the shipped payload's tracked `.lua`).
  `grep -c 'major = "LibKa0s-' tests/majors.lua` gives **27**, matching the README.
- The `55a7c6dc` complexity split of `tests/test_verdict_golden.lua`'s `seed` into
  `seedPlayer` / `seedItems` / `seedClient` removes decisions and changes no behavior. The 16
  read-half cases pin it.
- No `[upstream]` finding: nothing this branch touches lives in a vendored path.
