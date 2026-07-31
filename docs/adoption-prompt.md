# Adoption prompt — drop this into any Ka0s addon repo

Copy everything below the line into a fresh Claude Code session **in the addon's own repo**. It is
self-contained: it names what to read rather than restating rules that may have moved on.

Target addons (all except Absorb Tracker, which is consumer #1): `BankLedger`, `ConsumableMaster`,
`KickCD`, `LootHistory`, `PanelMaster`, `prettychat`, `WhatGroup`. Do **KickCD** first — it is the
reference implementation and the most structurally complex, so it is the most likely to expose a
descriptor assumption that only held for the first consumer. `WhoGotLoots` and
`BuffTextNotifications` are out of scope until they are on the standard at all.

---

## Task: adopt the LibKa0s performance harness (standard v2.12.0, `performance`)

This addon needs the performance measurement harness that the Ka0s WoW Addon Standard now requires.
It is **MUST for the wiring, SHOULD for coverage** — the wiring is uniform across the collection so
that *"run `/<slash> perf` and send me the JSON"* is true of any Ka0s addon; which hot paths get
buckets is yours to decide.

### Read these first, in this order. Do not work from memory or from this prompt's summaries.

1. **`standards/standards/performance.md`** in the standard —
   <https://github.com/tusharsaxena/WowAddonStandards> — fetched with `curl -fsSL`, not WebFetch
   (its summarizer mangles verbatim content). Also read `library-stack-§7`, `savedvariables-§4`,
   `testing-§7`/`§8`, `debug-logging-§12`, and anti-patterns **#43/#44/#45**.
2. **`LibKa0s/README.md`** — the `LibKa0s-Perf-1.0` descriptor contract, field by field, the
   `suspend`/`resume` host contract, and that module's public surface (the README also documents
   `LibKa0s-Core-1.0`, `LibKa0s-DebugLog-1.0`, `LibKa0s-Slash-1.0` and `LibKa0s-Options-1.0` — four
   other modules, none of which is this task). This is authoritative over anything below.
3. **`LibKa0s/docs/record-schema.md`** and **`LibKa0s/docs/releasing.md`**.
4. **The worked reference: `AbsorbTracker/core/PerfSetup.lua`** — consumer #1, in a sibling repo.
   Read it as a shape to follow, not text to copy: its buckets, its suspend body, and its show-decision
   integration are all specific to what that addon does.

The library repo is a sibling: `../LibKa0s` relative to this addon's repo root.

### Before you write anything: work out what this addon actually does

The wiring is mechanical; the coverage is a judgement call that needs the codebase. Establish, with
file:line evidence in your report:

- **The hot paths.** What runs per combat-log event, per frame, per repaint/render pass, per row, per
  bag slot? Those are candidate buckets. A path that runs twice a session is not a bucket — it will
  read `0.000` forever and add a row that says nothing.
- **The nesting.** Which of those run *inside* another? That relationship goes in the descriptor as
  `within`, and it is what stops a reader summing overlapping totals.
- **The show / act decision.** Where does this addon decide to display or do its thing? That is where
  a `suspended` check belongs — as an early step in the existing decision, not as a new one bolted on.
- **The event surface.** Which frames and events would have to be unregistered to make this addon
  genuinely inert, and what rebuilds them? Look for per-unit or per-slot registrations that depend on
  current settings — those must be rebuilt from **current** state on resume, not from a snapshot.
- **The log and chat seams.** The addon's debug console sink and its shared `NS.Print`. The harness
  routes through them; it owns no console of its own.
- **Whether this addon has almost no hot path.** That is a legitimate finding. Some addons are
  event-sparse, and the honest outcome is full wiring with two or three buckets — not invented ones.

### Then do the work

1. **Vendor the library.** Copy the **whole** `../LibKa0s/LibKa0s/` folder into `libs/LibKa0s/`
   (`cp -r ../LibKa0s/LibKa0s/. libs/LibKa0s/`) — never a file at a time: `Perf.lua` sits on
   `LibKa0s-Core-1.0` and refuses to register at all against a `Core.lua` older than the minor it
   names. Verify `diff -r ../LibKa0s/LibKa0s libs/LibKa0s` is **empty**. Copy from the library repo's
   own ship folder — **never** from a sibling addon's `libs/`, which may have drifted. Do not edit
   anything under `libs/`: if the library needs a change, that is a finding to report, not an edit to
   make here.
2. **TOC.** Add `libs\LibKa0s\LibKa0s.xml` to the `# Libraries` block **after** Ace3. Add
   `core\PerfSetup.lua` positioned **before** any file that will take `local Perf = NS.Perf` as a
   load-time upvalue, and **after** the file that publishes the host's printer — the descriptor's
   `log`, `print` and `showLog` all route through it. In AbsorbTracker that puts `PerfSetup.lua`
   immediately after `core/CoreSetup.lua`. Add `<Addon>PerfDB` to `## SavedVariables:` as the second
   global.
3. **`core/PerfSetup.lua`** — the descriptor. Required: `name`, `sv`, `suspend`, `resume`. Supply
   `version`, `slash`, `title`, `buckets`, `log`, `print`, `showLog`, `decorate` as this addon's own
   seams allow. It **must degrade, not error**, when the library is absent: build a stub carrying
   every member the addon actually calls — grep `NS.Perf` across the repo when you are done and make
   the stub answer all of it, `OnCommand` included.
4. **Brackets.** At each chosen hot path, in this exact shape and nothing else:
   `local t0 = Perf.on and debugprofilestop()` … `if t0 then Perf.Note("<key>", debugprofilestop() - t0) end`,
   with `local Perf = NS.Perf` as a **load-time upvalue** at the top of the file. Nothing inside a
   bracket may allocate, format, or call anything while capture is off.
5. **Suspend / resume.** Unregister events, cancel queued work, and make the addon's show/act decision
   consult `NS.Perf.suspended` **at the source**. Do **not** imperatively hide frames — they come back
   on the next combat transition, target swap or settings change, and the suspended arm then measures
   the addon still working.
6. **The `perf` verb.** One row in the addon's existing `NS.COMMANDS` table, dispatching to
   `NS.Perf.OnCommand(rest)` and printing the lines it returns through the addon's shared printer.
   The library registers no slash command; that is deliberate.
7. **`.luacheckrc`.** `debugprofilestop` into `read_globals`, `<Addon>PerfDB` into `globals` with a
   comment.
8. **Tests.** An integration suite for what this addon owns — descriptor well-formed; **every declared
   bucket actually reached by a real bracket** (drive each bucket's genuine entry point, and if one
   cannot be reached, that is a bug in your bucket list, not a reason to weaken the assertion);
   suspend genuinely inert; resume restoring from current state; and the **library-absent path
   exercised by loading the addon with the library missing**, not by hand-stubbing `NS.Perf`. The
   headless harness will need a real `LibStub` with `NewLibrary` if its mock only serves a lookup
   table — check.
9. **`tests/perf.lua`** — the offline scenario runner, **outside** the green gate. Assert only
   deterministic quantities (API calls, bytes allocated per iteration, isolated by a full collect
   either side). **Never** assert wall-clock. Include a zero-overhead scenario running the hottest
   bracketed path with capture off, as the evidence that instrumentation is free when off.
10. **Docs.** `docs/performance.md` (this addon's own perf page: which paths are bracketed and why,
    how to run a capture, how to read the report, what it can and cannot resolve) and
    `docs/perf-runs/README.md` (naming convention, schema summary, pointer to the library's canonical
    contract). Update `docs/ARCHITECTURE.md`, `docs/file-index.md` / `module-map.md`, and
    `docs/testing.md` to match. Regenerate `docs/test-cases.md` and move the README `[tests]` badge
    **count** in the same change — the count only, never the version.

### Mistakes that have already cost a capture — do not repeat them

- **Hiding frames instead of refusing at the source.** The single most common way a suspended arm
  silently measures the addon still running.
- **Not resuming before saving.** The B arm leaves the addon inert and there is no manual resume verb,
  so an error in save or format strands the addon dead until `/reload`. Resume first.
- **A degradation stub that omits `OnCommand`.** The stub exists precisely for the install where the
  library is missing, and `/<slash> perf` is exactly what someone will type there. A stub that crashes
  on the one path it exists to protect is worse than no stub.
- **A bucket nobody reaches.** It prints as a real row with a real zero and quietly lies in every
  report.
- **Reading the frame-time delta as a result.** It is a difference of two noisy aggregates. A
  city-square capture produced −1.18 ms/frame — the *suspended* arm reading slower, which is
  physically impossible — while the addon's entire accounted cost was ~0.00026 ms/frame. Read the
  **bucket** figures; treat the delta as unresolved below the documented run-to-run spread.
- **Editing `libs/` to fix a library problem.** That creates a fork nobody knows about, and the next
  re-vendor silently reverts it.
- **Counting `tests/perf.lua`'s scenarios** in `docs/test-cases.md` or the `[tests]` badge. They are
  not test cases.

### Verify, then report

Run and paste the real output — do not summarise a run you did not do:

```
diff -r ../LibKa0s/LibKa0s libs/LibKa0s      # must be empty
lua tests/run.lua                            # all green
luacheck .                                   # 0 warnings / 0 errors
lua tests/perf.lua                           # clean; note the zero-overhead figures
```

Then confirm, explicitly:

- the bracket call sites are the only places the hot paths changed, and nothing else in them moved;
- `git grep -n "NS.Perf"` — every member touched exists in both the real instance and the stub;
- the TOC load order puts `PerfSetup.lua` before its consumers;
- the `[tests]` badge, `docs/test-cases.md` and the suite all agree.

Follow this repo's own `CLAUDE.md` on committing and version bumps — **do not** bump the addon version
for this work, and do not push. Report at the end: the buckets you chose and why, what you found about
this addon's hot paths, anything about its structure that the descriptor contract did not fit (that is
the most valuable thing you can tell me — the contract is still unfrozen), and anything you left
undone.

Finally: this is an **in-game measurement tool**, so the last mile is mine. Tell me exactly what to run
to verify it live — the commands, in order, and what the numbers should look like if it is wired
correctly.
