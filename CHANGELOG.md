# Changelog

Two version numbers, and they are not the same thing. The repo carries a semver tag for humans. Each
**file** separately carries a LibStub **MINOR** integer that increments on every released change to
that file — that is what LibStub compares when it picks a winner between vendored copies, and a
released change that forgets its bump silently does not reach any host that already has the old copy.

Every release therefore opens with a version block naming each file's live minor.
`tests/test_versioning.lua` enforces that the block and every major's `lib.MODULES` agree, so the two
cannot drift. Release order is in
[docs/releasing.md](docs/releasing.md).

## v1.60.0 — 2026-09-26

Versions in this release: **DebugLog minor 14** and **DebugLogDiagnostics minor 1**
(`LibKa0s-DebugLog-1.0` 14.1) and **Slash minor 16** (`LibKa0s-Slash-1.0` 16), and the test kit at
**revision 27**. Every other file is unchanged from v1.59.0: `Core` 8, `Env` 1, `Compat` 1,
`Lifecycle` 2, `Bus` 2, `Schema` 2, `Pool` 3, `Item` 2, `Media` 4, `Widgets` 10 and
`WidgetsDragHandle` 3 (key 10.3), `Launcher` 4, `Options` key 24.31.4.7.4, `Perf` 13 and `PerfPanel`
5 (key 13.5). No `NEEDS_*` floor rises and no major is added; `DebugLogDiagnostics.lua` is a second
file of the DebugLog major, so the library is **fifteen majors across twenty-two files**. Built to the
Ka0s WoW Addon Standard **v2.68.0**, whose `debug-logging-§14` makes the diagnostics dump below a
MUST for every addon. Stacked on the unmerged v1.59.0 (`53c141a`), for the 2026-09-25 diagnostics
rollout.

### DebugLog minor 14: the copy-timing switch and the published buffer slack

- **`lib.TIME_COPY`**, `false` at load and never saved. Turned on by hand
  (`/run LibStub("LibKa0s-DebugLog-1.0").TIME_COPY = true`), every `ShowCopy()` prints one line
  through the console's chat printer on the next frame: `copy timing: %d lines, %d bytes, concat
  %.1fms, open+highlight %.1fms, next frame %.1fms`, read from `debugprofilestop` around
  `CopyText()`, around `CopyWindow`'s `Show`, and from there to a `C_Timer.After(0)` callback. It is
  the measuring aid for the buffer-size decision this release carries. The line goes through the
  descriptor's `print`, never through `Add`, so it does not grow the buffer it measures. With no
  `debugprofilestop` or no `C_Timer.After`, the window opens untimed and nothing prints; with the
  switch off, `ShowCopy()` reads no clock, as at minor 13. The text is `lib.STRINGS.COPY_TIMING`.
- **`lib.BUFFER_SLACK`**, the compaction slack, published. It was a private local at minor 13, at
  64. `Add` reads it from the library at call time, as it reads `MAX_BUFFER`, so a suite reads both
  back rather than writing `64` beside a constant it reads. It is **128** at this release (below).
- **The buffer is 3000 lines**: `lib.MAX_BUFFER` **1500 → 3000** and `lib.BUFFER_SLACK` **64 → 128**,
  which keeps a compaction near 23 moves per appended line. The message frame's `SetMaxLines` and
  the copy window move with it, as they read the same constant. Why: the diagnostics report is
  written into this buffer after the trace, and at 1500 a report at its 1200-line cap would leave as
  little as 300 lines of trace. Why 3000 and not 5000: the owner measured the copy window in the live
  client on 2026-09-26 with a throwaway copy bench (median of three runs of the Copy open plus the
  next frame, the empty-buffer baseline subtracted). At 120-column lines 3000 cost **246 ms**
  against the 250 ms limit and 5000 cost **378 ms**; at 200 columns, 346 ms and 419 ms against 1 s.
  By hand the copy box at 5000 kept every line but was sluggish. So 3000, which passes only just
  and is a ceiling rather than a starting point. `tests/test_debuglog.lua` pins the cap as the
  literal 3000 and reads both constants back for its boundary (`cap - 1` to `cap + 100`) and
  compaction cases.
- The cases are in a new suite, `tests/test_debuglog_copytiming.lua`, because
  `tests/test_debuglog.lua` was 988 lines: the default and the string as literals, the untimed path
  reading no clock, one exact line from a scripted clock, the line never reaching the buffer, the
  timed path handing the window the same text, the kept-line count past the cap, both headless
  guards, the slack pinned (at 128 since the buffer moved), and `Add` honoring a changed slack.
  Documented in [the version 14.1 document](docs/api/DebugLog/version-14.1-docs.md) (key 14.1
  with the diagnostics file below); version 13 is Superseded. The member manifest,
  `docs/api/DebugLog/members-14.1.json`, gains `BUFFER_SLACK` and `TIME_COPY`, both lib-level.
  The buffer's move is in the same document, under *the buffer is 3000 lines*.

### DebugLogDiagnostics minor 1: the diagnostics report

- **A new secondary file of `LibKa0s-DebugLog-1.0`, `DebugLogDiagnostics.lua`**, for the standard's
  diagnostics dump (v2.68.0, `debug-logging-§14`). Paired on the shell's minor
  (`__diagMinor` / `__diagShellMinor`, as `WidgetsDragHandle.lua` pairs); loaded after
  `DebugLog.lua` in `LibKa0s.xml`; `lib:New` installs its methods on each instance through
  `lib.__installDiagnostics`. The version key becomes **14.1**.
- **`D:RunDiagnostics(spec?)`** writes one report into the console and returns its line count: the
  begin marker `[Diag] ==== <brandName> diagnostics begin ====`; the identity header (the host's
  `initSummary()`, `GetBuildInfo`, the locale, the debug flag, `InCombatLockdown()` and
  `UnitAffectingCombat("player")` each pcall'd, and every running LibKa0s file minor); the host's
  sections, each under its own pcall so a raise costs one line; a `truncated` line when a cap bit;
  and the end marker, which counts every line. It appends through an internal ungated append with
  one repaint at the end, never calls `Clear`, never touches the flag, shows a hidden console, and
  prints one chat line, `lib.STRINGS.DIAG_WRITTEN`. **`D:BuildDiagnostics(spec?)`** is the same
  report as data and writes nothing. **`D:DebugVerb(rest)`** routes `diagnostics`, `on` and `off`
  and answers `false` for anything else, so the host keeps its own fallback.
- **The cap**: `lib.DIAG_MAX_LINES` (**1200**), clamped to `lib.MAX_BUFFER - 100`, with two lines kept
  for the truncated line and the end marker; `lib.DIAG_MAX_PER_LIST` (**40**) for `out:list`.
- **The writer a section is handed**, `out`: `add`, `joined`, `list`, `section`, `str`, `plain`,
  `escape`, `readable` and `nonDefaults`. Every value goes through the console's `safeToString`,
  every format is pcall'd with the gated sink's fallback join, and color, texture, atlas and
  hyperlink escapes are stripped; `escape` doubles `|` for a value whose escapes are the evidence.
- **Two descriptor fields**: `brandName` (the markers; falls back to `title`) and `diagnostics` (a
  function returning the sections, called at run time).
- `DebugLog.lua` 14 (still unreleased) gains the `DIAG_WRITTEN` string, the install call at the end
  of `New`, and an `append` split out of `Add` so the report can repaint once.
- **Consumers' library-absent DebugLog stubs gain three members** for their parity cases:
  `RunDiagnostics` (the collection's placeholder line, nothing written, returns 0),
  `BuildDiagnostics` and `DebugVerb`.
- The cases are in a new suite, `tests/test_debuglog_diagnostics.lua`. Documented in
  [the version 14.1 document](docs/api/DebugLog/version-14.1-docs.md).

### Test kit revision 27: the shared diagnostics contract

- **`testkit/test_diagnostics_contract.lua`**, the kit's fourth own suite: the dispatcher half of
  `debug-logging-§14`, run against the consumer's own dispatcher through `Kit.diagnostics` (`brand`,
  `dispatch`, `console`, `setDebug`, `setDisabled`, optional `retired` and `reset`). Seven cases:
  both forms write one report; the debug word in any case; both markers carry the brand and the end
  marker counts the lines; the report appends; it lands with logging off and leaves it off; both
  forms run while disabled; `diag`, `dx` and the retired names run nothing. With `Kit.diagnostics`
  unset it registers one declared skip naming the rule, so a consumer's re-vendor stays green
  before the addon has its report. `framework.lua`'s `KIT_GATE_RULE` gains the suite's row.
- This repo wires it against a fixture host, `tests/fixture_diagnostics.lua` (a DebugLog console
  and a Slash dispatcher gated on an enabled flag). Documented in
  [the revision 27 document](docs/api/testkit/version-27-docs.md); revision 26 is Superseded.

### Slash minor 16: `diagnostics` is live while disabled

- **`lib.LIVE_VERBS` gains `diagnostics`**, after `perf`: the standard's thirteen reserved verbs,
  for v2.68.0's diagnostics dump (`debug-logging-§14`, `slash-commands-§2`, `§7`). A disabled host
  that ships the verb and passes no `liveVerbs`, or builds its array from `lib.LIVE_VERBS`, runs it
  where minor 15 answered the refusal line. A host with a literal array adds the verb itself. No
  member, descriptor field or `NEEDS_*` floor moves; `members-16.json` differs from
  `members-15.json` in the minor alone.
- `tests/test_slash.lua` re-pins the default set and adds one case: a disabled host that ships
  `diagnostics` runs it with no refusal line. Documented in
  [the version 16 document](docs/api/Slash/version-16-docs.md); version 15 is Superseded.

### What a consumer owes on re-vendoring v1.60.0

Copy both payloads whole (`cp -r LibKa0s/. <Addon>/libs/LibKa0s/`, `cp -r testkit/. <Addon>/tests/_kit/`)
and move the `CLAUDE.md` provenance line to v1.60.0 in the same commit, as always. The kit moves
this time, 26 → 27, so both copies are owed. Then, in the same commit so the suite stays green:

- **The load list.** A runner that derives its library files from `libs/LibKa0s/LibKa0s.xml`, as
  the collection's do, loads `DebugLogDiagnostics.lua` after `DebugLog.lua` with no change; a list
  typed by hand gains it there.
- **Surface-parity churn.** A DebugLog degradation stub pinned with `Kit.assertSurfaceParity` goes
  red until it gains the three instance members: `RunDiagnostics` prints the collection's
  library-absent line (`"%s is unavailable: the LibKa0s library did not load."`, naming
  `/<slash> diagnostics`), writes nothing and returns 0; `BuildDiagnostics` and `DebugVerb` are
  carried beside it for the parity case. No other major's surface moves.
- **The kit's new suite.** `tests/run.lua`'s suites list gains
  `{ name = "test_diagnostics_contract", dir = "tests/_kit/" }`; the inventory fails the run until it
  is there. With `Kit.diagnostics` unset it is one declared skip, so the re-vendor is green before
  the addon has its report. Regenerate `docs/test-cases.md`.
- **The buffer.** A host suite that writes a literal 1500 (or 1500 plus a margin) to push the
  console past its cap, or asserts the cap or the slack as a literal, re-pins, preferably on
  `lib.MAX_BUFFER` and `lib.BUFFER_SLACK`. A doc or comment that states the console holds 1500 lines
  moves to 3000.
- **The live verb.** A host whose `liveVerbs` is Slash's default, or built from `lib.LIVE_VERBS`,
  gets `diagnostics` live while disabled with no change. A host with a literal live-verb array, or a
  degraded fallback list, adds `diagnostics` itself, and a host test that pins the live set as a
  literal re-pins.
- **Owed by `debug-logging-§14`, and not by the re-vendor**: the report itself, both slash forms,
  `brandName` and the `diagnostics` descriptor field, the host's sections, `Kit.diagnostics`, and the
  README's `## Reporting a bug`. Until those land the addon is on v1.60.0 and still owes the dump.

## v1.59.0 — 2026-09-25

Versions in this release: **WidgetsDragHandle minor 3** (`LibKa0s-Widgets-1.0` 10.3). Every other
file is unchanged from v1.58.0: `Core` 8, `Env` 1, `Compat` 1, `Lifecycle` 2, `Bus` 2, `Schema` 2,
`Pool` 3, `Item` 2, `Media` 4, `Widgets` 10, `DebugLog` 13, `Slash` 15, `Launcher` 4, `Options` key
24.31.4.7.4, `Perf` 13 and `PerfPanel` 5 (key 13.5), and the test kit stays at **revision 26**. No
`NEEDS_*` floor rises and no major is added. Built to the Ka0s WoW Addon Standard **v2.67.0**,
unchanged.

### WidgetsDragHandle minor 3: an opt-in close mark beside the help mark

- **`spec.onClose`** builds a close mark, an X, immediately left of the help mark, and calls the
  function on the X's left click. Asked for by AuraMaster (feedback batch 8, `CX-1`), whose X
  disables the container it sits on; what the X does is always the host's.
- **The X is the help mark's twin**: the same `HELP_HIT` (18px) frame around the same `HELP` (8px)
  art at `CENTER`, anchored `RIGHT` to the help mark's `LEFT` at `-CLOSE_GAP`, the same resting tint
  `0.7, 0.7, 0.72` and full white under the cursor. It takes the strip's drag scripts, so a drag that
  starts on it moves the frame and closes nothing, and it passes a right click to `onRightClick`
  where the host wired one; with none it registers `LeftButtonUp` alone.
- **`spec.closeIcon`** is its art, a resolved path (a host's `Icon("close")`), falling back to
  `Interface\Buttons\UI-StopButton`; **`spec.closeTooltip`** is its own descriptor, falling back to
  `tooltip`.
- **The label stays centered.** The reserve grows by `HELP_HIT + CLOSE_GAP` on **both** sides, 29 to
  47, so a strip with an X is 36px wider and keeps `HELP_CLEAR` (12px) in front of the X's ink.
  `lib.DRAG_HANDLE.CLOSE_GAP = 0` is new, and so is **`handle:Reserve()`**, which answers this
  strip's reserve; `handle.close` (and `handle.close.icon`) is readable, `nil` without `onClose`.
- **A spec with no `onClose` is exactly minor 2**: two frames, a reserve of 29, the same label
  bounds, `Measure()` and click registrations. `tests/test_widgets_draghandle.lua` pins every one of
  those numbers as a literal, beside a minor check and nine new cases for the X (build, fallback
  art, symmetric reserve, left and right click, drag pass-through, hover and tooltip, a strip with
  no help mark).
  Documented in [the version 10.3 document](docs/api/Widgets/version-10.3-docs.md); version 10.2 is
  Superseded. No lib-level member moves, so `docs/api/Widgets/members-10.3.json` lists the same
  surface as `members-10.2.json`.

### What a consumer owes on re-vendoring v1.59.0

Copy both payloads whole and move the `CLAUDE.md` provenance line to v1.59.0 in the same commit, as
always; the kit bytes are those of v1.56.0. **Nothing else, unless the host wants an X**: a
`DragHandle` host that passes no `onClose` (ConsumableMaster, KickCD, AbsorbTracker today) draws the
same pixels and needs no change. A host that adopts it passes `onClose`, `closeIcon` and
`closeTooltip`, and any host test that hard-codes the strip's width or `RESERVE * 2` re-pins against
`handle:Reserve()`. No degradation stub moves: the member manifest is unchanged. This release is
re-vendored into AuraMaster only (batch 8, `D3`); the other hosts take it on their next re-vendor.

Release gate (`docs/automated-tests/20260925-170346/`): lint pass, 0/0 in 93 files;
tests pass, 1677 tests, 0 failed; complexity pass, 0 over CCN 15. Perf
SKIPPED, not measured — no `tests/perf.lua` — so the gate covered three suites, not four.

## v1.58.0 — 2026-09-24

Versions in this release: **Launcher minor 4** (`LibKa0s-Launcher-1.0` 4). Every other file is
unchanged from v1.57.0: `Core` 8, `Env` 1, `Compat` 1, `Lifecycle` 2, `Bus` 2, `Schema` 2, `Pool` 3,
`Item` 2, `Media` 4, `Widgets` 10 and `WidgetsDragHandle` 2 (key 10.2), `DebugLog` 13, `Slash` 15,
`Options` key 24.31.4.7.4, `Perf` 13 and `PerfPanel` 5 (key 13.5), and the test kit stays at
**revision 26**. No `NEEDS_*` floor rises and no major is added. Built to the Ka0s WoW Addon Standard
**v2.67.0**, whose `launcher-§2` makes the click behavior below a MUST drawn by this module.

### Launcher minor 4: left-click opens settings, right-click opens the options menu

- **Left-click calls `openSettings`, on every host, in either state** (M6, the owner's ruling of
  2026-09-24; `launcher-§2` as of the standard's v2.67.0). The three left-click rungs are retired,
  and so is minor 2's disabled left-click refusal: the panel is setup, and where a disabled addon is
  re-enabled.
- **Right-click opens the client's context menu** (`MenuUtil.CreateContextMenu`, 11.0+), anchored to
  the clicked frame and titled with the label, with one checkbox per toggle the descriptor supplies,
  in the one order: *Enabled* (`isEnabled` + `setEnabled(bool)`), *Locked* (`isLocked` +
  `toggleLock`), *Test mode* (`isTestMode` + `toggleTestMode`), *Show window* (`isWindowShown` +
  `toggleWindow`). An entry needs both halves. Each state is read when the menu opens; a click
  calls the host's handler once and closes the menu.
- **While `isEnabled()` is false**, *Enabled* stays live and the other entries are grayed
  (`SetEnabled(false)`) and read `<entry> (enable the addon first)`; a grayed entry clicked anyway
  calls no handler.
- **Every client call is nil-guarded.** With no `MenuUtil`, no `CreateContextMenu`, or no supplied
  entry at all, right-click opens the settings panel instead. A raising handler or menu API prints
  one line naming the addon and never escapes into the client's dispatch.
- **Retired, and ignored if passed** (no error): `onClick`, `leftClickLabel`, `disabledLine` and
  `slash`. `isEnabled` no longer requires `disabledLine`.
- **The tooltip's hints are fixed**: `Left-click: Open settings`, `Right-click: Options menu`. The
  rest of minor 3's tooltip is unchanged.
- **`lib.STRINGS`**: `TOOLTIP_OPTIONS_MENU` and seven `MENU_*` keys added; `TOOLTIP_LEFT_DEFAULT`,
  `TOOLTIP_DISABLED_HINT` and `TOOLTIP_DISABLED_BARE` removed with the rungs. No member is added, so
  `docs/api/Launcher/members-4.json` lists the same surface as `members-3.json`.
- `tests/test_launcher.lua` against a new headless menu stand-in, `tests/mock_menu.lua`
  (repo-local, not in the kit): fifteen new cases, fourteen for the clicks and the menu, among them the sixteen-cell matrix of pairs
  present or absent, half pairs, order, read-at-open, grayed while disabled, one call per toggle,
  the missing-API fallback and the retired fields. The minor-2 and minor-3 cases that pinned the
  rungs, the refusal and the rung hints are replaced, since this release retires those contracts.
  `.luacheckrc` declares `MenuUtil` and `MenuResponse`. Documented in
  [the version 4 document](docs/api/Launcher/version-4-docs.md).

### What a consumer owes on re-vendoring v1.58.0

Copy both payloads whole and move the `CLAUDE.md` provenance line to v1.58.0 in the same commit, as
always; the kit bytes are those of v1.56.0. Then, in `core/LauncherSetup.lua` (the M6 re-vendors):

- **Arrives without being asked for**: left-click opens the settings panel on every host, so a rung
  (a)/(b) host's `onClick` stops running; the hints read `Open settings` / `Options menu`; and the
  disabled refusal is gone. Until the host passes a pair, right-click still opens the panel.
- **Owed by `launcher-§2`**: pass `setEnabled` beside `isEnabled`, and `toggleLock`,
  `toggleTestMode`, `isWindowShown` + `toggleWindow` for each state the addon really has, each wired
  to the **same** handler its slash verb and settings row use; record the entries in the addon's
  docs. Delete `onClick`, `leftClickLabel`, `disabledLine` and `slash` from the descriptor.
- **Tests**: a host test that pinned the left click's action, the disabled refusal or minor 3's
  hints re-pins. A test of the menu needs a `MenuUtil` fake in the host's own harness; the kit does
  not ship one.
- No degradation stub moves: the member manifest is unchanged.

Release gate (`docs/automated-tests/20260924-234934/`): lint pass, 0/0 in 93 files;
tests pass, 1666 tests, 0 failed; complexity pass, 0 over CCN 15. Perf
SKIPPED, not measured — no `tests/perf.lua` — so the gate covered three suites, not four.

## v1.57.0 — 2026-09-24

Versions in this release: **Launcher minor 3** (`LibKa0s-Launcher-1.0` 3). Every other file is
unchanged from v1.56.0: `Core` 8, `Env` 1, `Compat` 1, `Lifecycle` 2, `Bus` 2, `Schema` 2, `Pool` 3,
`Item` 2, `Media` 4, `Widgets` 10 and `WidgetsDragHandle` 2 (key 10.2), `DebugLog` 13, `Slash` 15,
`Options` key 24.31.4.7.4, `Perf` 13 and `PerfPanel` 5 (key 13.5), and the test kit stays at
**revision 26**. No `NEEDS_*` floor rises and no major is added. Built to the Ka0s WoW Addon Standard
**v2.66.0**, whose `launcher-§1` makes the tooltip below a MUST drawn by this module.

### Launcher minor 3: the library always draws the status tooltip

- **The LDB object's `OnTooltipShow` is the library's, on every host** (M5, the owner's ruling from
  the 2026-09-24 smoke pass; `launcher-§1`/`§2` as of the standard's v2.66.0). It draws one fixed
  shape in all eleven addons, and it draws it **while the addon is disabled** too: the label and,
  where passed, `v<version>`; `Enabled: Yes|No` (always, green or red); `Locked: Yes|No` and
  `Test mode: On|Off` only where the descriptor passes `isLocked` / `isTestMode`; the host's own
  lines; `Left-click: <leftClickLabel>` on rungs (a)/(b), `Left-click: disabled — /<slash> enable`
  on those rungs while disabled, `Left-click: Open settings` on rung (c) in either state; and
  `Right-click: Open settings`.
- **Five new optional descriptor fields**: `version`, `isLocked`, `isTestMode`, `leftClickLabel`
  (a string, or a function asked on every show) and `slash`. The disabled hint needs nothing new: the
  command is read out of `disabledLine()`, which every host already passes as its Slash dispatcher's
  `DisabledLine()`; `slash` is for a line worded otherwise.
- **`onTooltipShow` now appends.** It is called once per show, between the status block and the
  click hints, and no longer handed to the LDB object as the whole tooltip. A host hook that drew a
  title, a version, a status line or a click hint draws a second copy of it (anti-pattern #89).
- **Every state is read on every show**, never cached, and every accessor and the host hook is
  `pcall`'d: a raise costs its own value and goes to the debug seam, never to chat.
- **Fourteen `TOOLTIP_*` keys in `lib.STRINGS`**, overridable through `d.L` with the same `rawget`
  guard as the four reports. No member is added, so `docs/api/Launcher/members-3.json` lists the same
  surface as `members-2.json`.
- `tests/test_launcher.lua`: fifteen new cases, one of them a 36-cell matrix (enabled or disabled,
  rung (a)/(b) or (c), lock absent/Yes/No, test mode absent/On/Off). The minor-2 case that asserted
  the pass-through (`OnTooltipShow is passed through, and only when it is a function`) is replaced:
  that contract is the one this release retires. Documented in
  [the version 3 document](docs/api/Launcher/version-3-docs.md).

### What a consumer owes on re-vendoring v1.57.0

Copy both payloads whole and move the `CLAUDE.md` provenance line to v1.57.0 in the same commit, as
always; the kit bytes are those of v1.56.0. Then, in `core/LauncherSetup.lua` (the M5 re-vendors):

- **Arrives without being asked for**: the button shows the library's tooltip on hover, enabled or
  disabled, whether or not the host passes `onTooltipShow`. A host test that called the object's
  `OnTooltipShow` and expected only the host's lines now sees the library's around them.
- **Owed by `launcher-§1`**: pass `version`; `leftClickLabel` on rung (a)/(b); `isLocked` and
  `isTestMode` where the addon has that state, reading the accessor its Master-controls row reads;
  and cut any existing `onTooltipShow` down to the addon's own lines, deleting every title, version,
  status line and click hint it drew.
- No degradation stub moves: the member manifest is unchanged.

Release gate (`docs/automated-tests/20260924-225548/`): lint pass, 0/0 in 92 files;
tests pass, 1662 tests, 0 failed; complexity pass, 0 over CCN 15. Perf
SKIPPED, not measured — no `tests/perf.lua` — so the gate covered three suites, not four.

## v1.56.0 — 2026-09-24

Versions in this release: **Core minor 8** (`LibKa0s-Core-1.0` 8), **Item minor 2**
(`LibKa0s-Item-1.0` 2), **Media minor 4** (`LibKa0s-Media-1.0` 4), **Bus minor 2**
(`LibKa0s-Bus-1.0` 2), **Lifecycle minor 2** (`LibKa0s-Lifecycle-1.0` 2), **Launcher minor 2**
(`LibKa0s-Launcher-1.0` 2), **Slash minor 15** (`LibKa0s-Slash-1.0` 15), **DebugLog minor 13**
(`LibKa0s-DebugLog-1.0` 13), **Perf minor 13** (`LibKa0s-Perf-1.0` 13; `PerfPanel` stays 5, key
13.5), **Widgets minor 10** (`LibKa0s-Widgets-1.0` 10; `WidgetsDragHandle` stays 2, key 10.2),
**Schema minor 2** (`LibKa0s-Schema-1.0` 2), **Options minor 24**, **OptionsWidgets minor 31**,
**OptionsTabs minor 4** and **OptionsScroll minor 4** (`LibKa0s-Options-1.0` key 24.31.4.7.4;
`OptionsCompose` stays 7), **test kit revision 26**. Unchanged from v1.55.0: `Env` 1, `Compat` 1,
`Pool` 3, `WidgetsDragHandle` 2 and `PerfPanel` 5.

A minor release: every change is additive, no `NEEDS_*` floor rises and no major changes, so a
consumer that re-vendors keeps every module it had. The cost of re-vendoring comes from the test
kit, not the library, and the section below lists it.

### What a consumer owes on re-vendoring v1.56.0

Copy both payloads whole (`cp -r LibKa0s/. <Addon>/libs/LibKa0s/`, `cp -r testkit/. <Addon>/tests/_kit/`)
and move the `CLAUDE.md` provenance line to v1.56.0 in the same commit, as always. Beyond that:

- **Surface-parity churn.** A degradation stub pinned with `Kit.assertSurfaceParity` goes red until it
  gains the new members. `LibKa0s-Core-1.0` adds `SafeRegisterEvent`, `SafeRegisterUnitEvent` and
  `SafeRegisterEvents`: every Core stub gains the three with one-rung bodies (pcall the
  registration, answer its result). A Schema **instance** stub gains `SetMany` (AbsorbTracker,
  BankLedger, LootHistory, PanelMaster and PrettyChat on the 2026-09-24 reading). A Slash stub is
  asked to pin its `DisabledLine` bytes with the new `Kit.assertLibraryConstant`. No other major's
  lib-level surface moves.
- **Behavioral kit flips.** Each can redden a suite that passed on revision 25, and the owner's
  standing ruling is that such a red is fixed in the addon, never by weakening an assertion:
  - `CreateFrame` starts frames **shown**, so a stand-down suite's `F_on` baseline now sees the
    addon's container frames;
  - the **AceDB fake raises** on a bad `CopyProfile` / `DeleteProfile` name and strips defaults on
    `SetProfile`, as AceDB-3.0 does;
  - `EventRegistry` callbacks are **recorded** in `M.__registrations()` as kind `callback`, and raw
    frame `RegisterEvent` / `RegisterUnitEvent` raise on a name in `M.__badEvents`;
  - `test_eol.lua` counts every **lone CR**, named as `path:line`;
  - the prose gate reads the three **store-root** files (`docs/automated-tests/README.md`,
    `docs/automated-tests/RESULTS.md`, `docs/perf-analysis/README.md`) and lists `synchronis`;
  - kit **case names carry `§`** (`line-endings-§5`, `layout-§1`, two `localization-§5`), so every
    consumer regenerates `docs/test-cases.md`;
  - the runner records a `performance-§12` register row as perf skip reason (2), fails a run whose
    register it cannot read, and heads an empty watch-list table instead of printing `None.`.
- **Opt-ins, owed only where a plan item adopts them**: Schema's `SetMany`, `row.normalize` and
  `writeThrough`; Launcher's `isEnabled` / `disabledLine`; `RenderTabbedSchema`'s `opts.tabs`,
  `disabledFor` / `disabledNotice` and `chrome`; `PageBanner`'s `action`; Core's
  `SafeRegisterEvent` family in place of a hand-rolled pcall.
- **Arrives without being asked for**: `CreateOptionsPanel` called in combat parks and replays at
  `PLAYER_REGEN_ENABLED` (a host that rolled its own park deletes it), `OpenOptionsPanel` answers a
  boolean, `Slash`'s `CliSet` / `CliReset` print the write seam's refusal, and the launcher's
  missing-library notice prints once without the `[LibKa0s] ` prefix.

The collection dry-run of this payload, per addon, is in the release bundle's `ANALYSIS.md`.

### Repository: the suite, the live documents and the artwork tools are held to US English

- **Swept** (audit finding `LibKa0s-A-07`): every `tests/*.lua`, the live document of every major
  under `docs/api/` and that folder's README, `docs/releasing.md`, `README.md`, `DEPENDENCIES.md`,
  `CLAUDE.md` and `tools/artwork/*.py` now carry no spelling from `localization-§5`'s British list.
  Superseded API documents and released entries in this file are records and were left as written.
  Case names changed with their prose (*colour*, *honours*, *synthesises* and the like), so
  `docs/test-cases.md` was regenerated; `icon_cleaner.py`'s recolor stage is now `recolor_white`.
- **Gated**: `tests/test_prose.lua` gains a case that reads that set, picking each major's live
  document by its highest version key and checking that it names no successor. Its exemptions are
  the identifiers the register already ratifies (the `minimise` icon key; AceTimer's `.cancelled`
  field and C_Timer's `IsCancelled`, whose register row now also covers `tests/test_mock_ace.lua`)
  and the quoted words in kit revision 26's document, which records the list entry it added. The
  gate file itself is read too: only its two list tables are skipped, and the words its comments
  quote in order to forbid them are named one by one, so its own prose is held to the rule (the
  sweep's one miss, *licences*, was in it). No payload byte and no minor moves.

### OptionsTabs minor 4: `RenderTabbedSchema` moves here and takes host tabs, a disabled notice and a chrome hook; `PageBanner` takes an action

- **`O.RenderTabbedSchema` moves from `OptionsWidgets.lua` to `OptionsTabs.lua`** (review finding
  `AuraMaster-R-04`, a first peel toward the `OptionsWidgets.lua` census row). The shell now calls
  `lib.__AttachTabs(O, d)` so the chrome half can read `d.rowsForPage`. `OptionsWidgets.lua` keeps an
  untabbed stand-in under the same name that the chrome half's attach replaces, so a partial copy
  without `OptionsTabs.lua` still draws every row with its headings. The four-argument call every
  host makes is unchanged, and every existing case in `tests/test_options_widgets.lua` passes as it
  did.
- **A fifth, optional `opts` argument**, for the page AuraMaster forked whole and four more hosts
  (AbsorbTracker, KickCD, ConsumableMaster, MultiMeters) hand-build the strip of: `tabs` (host tabs
  drawn by `render(ctx, rows)`; one keyed by a schema group takes that group's place and is handed
  its rows, any other is placed `before` a named tab or last), `cfg`, `disabledFor(cfg)` plus
  `disabledNotice` (a string or a function of `cfg`; when the predicate answers true the notice is
  drawn **above** the rows and the rows are drawn disabled, not replaced), and `chrome(ctx)`, called
  once per render after the strip and before the rows. A second return value lists every drawn
  tab's key in strip order.
- **`O.PageBanner` takes `action = { text, tooltip, onClick }`**: a `Button` in the band's right half,
  level with the dropdown's control, for `options-ui-§14`'s picker+create band. It is refused in
  combat, pcall'd, and Released like the banner's dropdown (after its replacement exists, so a create
  act that re-renders from its own click is never handed its own button). Returned as a second value.
- No minor moves beyond this release's (OptionsWidgets 31 and OptionsTabs 4 are already unreleased),
  no member is added, and the member manifest is unchanged. `OptionsTabs.lua` is 1489 lines and
  `OptionsWidgets.lua` 3852. `tests/test_options_tabs.lua`: thirteen new cases. Red before: a host
  tab placed `before` a group and rendered by its callback; a host tab replacing its group and
  handed its rows; a page of host tabs alone drawing its strip; the notice above rows drawn
  disabled; a host tab under the disable, restored after a raise; `chrome` once per render after
  the strip; the banner's action button, its release, its re-render from its own click and its
  combat refusal. Green from the start, as guards on the move: a false or raising `disabledFor`,
  the stand-in taking `opts` with `OptionsTabs.lua` absent, and no `RenderTabbedSchema` over a copy
  without the flow engine. Documented in
  [the version 24.31.4.7.4 document](docs/api/Options/version-24.31.4.7.4-docs.md).

### OptionsTabs minor 4: the page chrome stops leaking a widget per render

- **Fix: a banner or header page no longer grows by a widget and a texture per render** (review
  finding `LibKa0s-R-02`). Through minor 3 every full render of such a page left its old chrome
  behind for good: `O.PageBanner` created a fresh AceGUI `Dropdown`, `O.PageHeader` a fresh `Frame`,
  and the divider under either a fresh texture, and the release only hid and unparented them.
  AceGUI recycles a widget only when it is Released, and the client never destroys a frame or a
  region, so every subject switch on a banner or header page (AuraMaster, ConsumableMaster, KickCD,
  MultiMeters, AbsorbTracker) added to the session's frame count.
- **The banner's `Dropdown` is Released to AceGUI** when the band is next drawn, by either member.
  It is hidden at once and Released only after the replacement exists (after `PageBanner`'s own
  `Create`, after a `PageHeader` builder has run), because the replacing render usually runs inside
  the old dropdown's own `OnValueChanged` and a widget Released on the way in would be handed
  straight back to it. The library holds it under a private ctx key: `ctx.__bannerWidget` stays the
  host's, which AbsorbTracker, AuraMaster, KickCD and MultiMeters each write themselves.
- **`PageHeader` hands back the same `Frame` on every render of one page**, from a per-page pool of
  one (`LibKa0s-Pool-1.0`, which the file already floors on). What a builder draws into it is still
  the host's to release; both hosts in the collection build AceGUI widgets there and Release them.
- **The divider is one texture per page**, hidden on release and shown again on the next render.
  `SetParent(nil)` is no longer called on it, since a Region is not promised to honor it.
- No member or spec field moves; every consumer gets the fix by re-vendoring. `releaseChrome` now
  releases each piece through its owner, and `__chromeKids` stays as the ledger of what the render
  drew. `tests/test_options_tabs.lua`: five new cases -- two banner renders leave one `Dropdown` out
  (red before: two); a header page after a banner page gives the banner's `Dropdown` back (red
  before); a banner re-rendered from inside its own `onSelect` releases the old picker only after
  the new one exists; `PageHeader` hands back the same frame (red before: a new one each render);
  the divider texture is made once per page and never unparented (red before: three textures). The
  existing "at most ONE chrome block" case now asserts the reused frame, where it asserted the first
  frame was hidden. The Options key moves 24.31.3.7.4 -> 24.31.4.7.4 and the unreleased document is
  renamed to match: [the version 24.31.4.7.4 document](docs/api/Options/version-24.31.4.7.4-docs.md).
  The counts come from the kit's new AceGUI survey, below.

### OptionsWidgets minor 31: the drag throttles keep their own armed flag

- **Fix: a host whose `scheduleTimer` answers nil gets the 50 ms drag throttle** (review finding
  `KICKCD-R-19`). The slider's live commit (`commitOn` / `sliderCommit = "change"`) and the color
  picker's drag throttle each stored `scheduleTimer`'s return value and read it as "a timer is
  armed", so a `C_Timer.After` wrapper -- which answers nil, and which KickCD, LootHistory and
  MultiMeters all pass -- armed a new timer and closure on every drag frame and committed about once
  a frame. Each throttle now keeps a library-local boolean, set before it calls `scheduleTimer` and
  cleared inside the callback, and the return value is unused. A host whose timer answers a handle
  sees no difference. No member or field moves; the three hosts get the fix by re-vendoring.
- `LibKa0s/Options.lua`'s descriptor comment says `scheduleTimer`'s return value is unused and that
  it backs the slider's live commit too. Options stays at minor 24, already bumped in this release.
- `tests/test_options_throttle.lua`, a new suite (`tests/test_options_widgets.lua` is a census row
  over the 1500-line cap): four cases -- ten slider drag frames in one window with a nil-returning
  `scheduleTimer` arm one timer and commit once (red before: ten timers); the same for the color
  picker (red before: ten timers); the window re-arms once it fires (red before); a handle-returning
  host is unchanged. The Options key moves 24.30.3.7.4 -> 24.31.3.7.4 and the unreleased document
  is renamed to match: [the version 24.31.3.7.4 document](docs/api/Options/version-24.31.4.7.4-docs.md)
  (24.31.4.7.4 since OptionsTabs minor 4).

### Options minor 24: `CreateOptionsPanel` parks in combat; `OpenOptionsPanel` answers a boolean

- **Behavioral: `CreateOptionsPanel` under `InCombatLockdown()` registers nothing and replays itself
  when combat ends** (audit finding `ConsumableMaster-A-04`). The call is parked with the library;
  at `PLAYER_REGEN_ENABLED` the library replays it once, registering the category and building every
  queued page, whatever the host's stand-down state -- which also covers `ConsumableMaster-R-03`'s
  category lost to a stand-down mid-combat. A second call while parked is a no-op. A login or
  `/reload` taken in combat now shows the addon's category when the fight ends rather than at once;
  out of combat nothing changes. A host suite that pins "registering during combat still registers"
  (WhatGroup's `tests/test_panel.lua`) must fire the end of combat first.
- **Permitted by the standard.** `options-ui-§5` and `options-ui-§9` (standard v2.65.0) sanction
  this park: the library **MAY** park a registration requested under `InCombatLockdown()` and
  **MUST** replay it exactly once at `PLAYER_REGEN_ENABLED`, whatever the host's stand-down state,
  and a host **MUST NOT** add its own park on top. A parked registration waits on the client, never
  on the user, so it is not the deferral `options-ui-§9` forbids. The provisional `options-ui-§9`
  row this change first opened in `CLAUDE.md`'s `## Documented deviations` is retired.
- **The park listens on its own private frame**, `lib.__parkFrame`, separate from the page lock's
  `lib.__combatFrame`: created on the first park, kept across an upgrade, and registered for
  `PLAYER_REGEN_ENABLED` only while something is parked. Its dispatcher (`lib.__OnParkEvent`) is
  looked up at call time, so the newest copy drains what an older one parked. No instance member is
  added (no `ReplayPending`), so no degradation stub moves and the member manifest is unchanged.
- **`OpenOptionsPanel` now answers**: `true` when it opened the category, `false` when refused in
  combat (the `COMBAT_REFUSED` line still prints), `nil` when there is no category to open. It
  returned nothing through minor 23. It still never defers an **open**.
- `tests/test_options_combat.lua`: five cases -- in combat nothing registers and the park listens on
  its own frame (red before: the category registered at once); the end of combat registers once,
  builds the queued pages and lets go of the event; a second call while parked is a no-op; an
  event other than `PLAYER_REGEN_ENABLED` leaves the park armed; the three return values of
  `OpenOptionsPanel`. Documented in
  [the version 24.31.4.7.4 document](docs/api/Options/version-24.31.4.7.4-docs.md).

### Options minor 24, OptionsScroll minor 4: the font preload moves out of the shell

- **Structural, behavior-neutral: the font preload (Options minor 17) now lives in
  `OptionsScroll.lua`**, moved unchanged from `Options.lua` -- `preloadState`, `preloadFrame`,
  `preloadPath`, `subscribeLate` and `lib.__PreloadFonts`, with the library-level
  `lib.__fontPreload` state they share. `Options.lua` drops from 1476 lines to 1376, back under
  `layout-§1`'s 1500-line cap with room for the Options items later in this release.
  `lib.__PatchLSM30Border` stays in the shell.
- **A partial copy missing `OptionsScroll.lua` shows its pages with no preload and no error.** Both
  callers -- the instance's show trigger in `lib:New` and the late-registration callback -- already
  looked `lib.__PreloadFonts` up on `lib` at call time and did nothing when it was not a function,
  so no call site changed. The member, its contract and its state are unchanged; the member
  manifest differs from 23.30.3.7.3's in the version key alone.
- `tests/test_options.lua`: one case -- with `lib.__PreloadFonts` nil a panel's show survives and
  renders, and loading `OptionsScroll.lua` installs the preload (red before the move: the shell
  defined it). `tests/test_options_fontpreload.lua` passes unchanged, eleven cases before and after.
  Documented in [the version 24.31.4.7.4 document](docs/api/Options/version-24.31.4.7.4-docs.md);
  version 23.30.3.7.3 is Superseded.

### Schema minor 2: `SetMany`, `row.normalize`, `writeThrough`, and the instance id reaching `get` and `ApplyDefault`

- **New: `SetMany(entries, opts)`, the all-or-nothing batch.** `entries = { { path, value }, ... }`,
  `opts = { instanceId, act, scope }`. Every entry is resolved, validated and normalized before any
  is stored; one refusal answers `false, err, why, index` with nothing stored and nothing called.
  A batch that passes stores every entry in order, then runs every row's `onChange`, then calls the
  new optional descriptor field `announceBatch(writes, resolvedId)` **once** (or `announce` once per
  write without it). With `opts.act` the batch is one bulk bracket, so one
  `[Set] <act> <scope>: N rows` line. Owner-scope consumers: ConsumableMaster#39
  (`SetManyAndRefresh`), MultiMeters#52 (`SetByPaths`), KickCD#22 (copy styling).
- **New: `row.normalize(value, resolvedId)`**, after `validate` accepts and before the missing-root
  refusal and the store. It answers the value to store, or `nil, why`, which refuses with
  `INVALID`. The normalized value is what is stored, logged and handed to `onChange` and
  `announce`. AuraMaster#21 and ConsumableMaster#39 carry this semantic in front of their seams
  today, which clears `library-stack-§7` bar 2; the header's "deliberately does not do" paragraph
  no longer excludes it or the batch.
- **Behavioral: the instance id reaches a row's `get` and `ApplyDefault`'s write** (review finding
  `LibKa0s-R-14`). `Get(path, instanceId)` calls `row.get(instanceId)` where minor 1 called
  `row.get()`, and `ApplyDefault(row, instanceId)` forwards the id to `Set`. A closure `get` that
  ignores its argument is unaffected.
- **New: `descriptor.writeThrough`, the declared row-less paths** (audit findings
  `AbsorbTracker-A-02` and `AbsorbTracker-A-03`; owner-scope PartyFrameEnhanced#14, WhatGroup#22).
  An array of path strings, read once at `:New`. A write to a listed path **with no indexed row**
  is no longer refused with `NOT_FOUND`: `Set` (and a `SetMany` entry) resolves the root, stores
  the value raw and copied in, with no `validate`, `normalize` or `onChange`, logs or tallies it as
  any write, and calls `announce` with a synthetic row `{ path = path, writeThrough = true }`,
  built once per path so a write allocates nothing. A listed path that has a row takes the row; a
  row-less path not in the list is still refused. This is `options-ui-§1`'s route (a): a host verb
  writing a composed Master-controls row (`enabled`, `locked`, test mode) on a load where the
  composer is absent (library-absent, or Schema present and Options not) lands its write while the
  composers stay hollow and no host copy of them exists (anti-pattern #73). The version 2
  document's *degradation stub* now prescribes the same list for the stub, stored the same way,
  with every other row-less path refused. Opt-in: a host that passes no list sees no change. A
  written-through value runs no `onChange`, so a host that needs the reaction dispatches it from
  `announce` on `row.writeThrough`. Adoption notes for AbsorbTracker (`{ "enabled", "locked" }`,
  deleting `composeBlock` and the host copies, pinning full count, degraded count and the named
  composer gap), PartyFrameEnhanced#14 (`{ "enabled", "locked" }`) and WhatGroup#22 (route (b),
  no list).
- `Set` and `SetMany` share one `prepareWrite`, so a batch refuses on exactly the rules a single
  write does; `Set`'s answer counts are unchanged (`false, err, why` for a value refusal,
  `false, err` for a missing root).
- **Consumer impact: every Schema degradation stub pinned with the two-table
  `T.assertSurfaceParity` goes red on the re-vendor until it gains `SetMany`** — AbsorbTracker,
  BankLedger, LootHistory, PanelMaster and PrettyChat on the 2026-09-24 reading. Adding it before
  the re-vendor is harmless against minor 1. The lib-level surface is unchanged.
- `tests/test_schema_batch.lua` (new; `tests/test_schema.lua` was 1233 lines): a batch with one
  invalid entry stores nothing and names its index, an unknown path refuses the batch whole, a
  valid batch stores all, runs every `onChange` and calls `announceBatch` once, `act` gives exactly
  one bracket line counting the rows moved, `normalize`'s value is stored and `nil, why` refuses,
  `Get` hands the id to `row.get`, and `ApplyDefault(row, id)` reaches `Set` with the id.
  `tests/test_schema.lua`'s `referenceStub` gains `SetMany`, `normalize` and the id forwarding, is
  pinned against a live instance with the two-table parity, and a case holds its batch to the live
  one's store. Six `writeThrough` cases in `tests/test_schema_batch.lua` (a listed row-less path is
  stored, logged and announced with one synthetic row per path; an unlisted one is refused; a listed
  path with a row takes its `validate`; the store is a copy and a missing root refuses; a bracket
  tallies it and `SetMany` takes it; a malformed list keeps only its non-empty strings), and the
  `referenceStub` gains the list, with a case holding its store and announce order to the live
  seam's on the same writes. Documented in [the version 2 document](docs/api/Schema/version-2-docs.md), with
  per-host mappings for KickCD, ConsumableMaster, MultiMeters and AuraMaster; version 1 is
  Superseded.

### Widgets minor 10: a `ReorderList` drag no longer borrows the host's frames

- **Behavioral: the drag's poll runs on the library's ghost frame, not on the host's row frame**
  (review finding `LibKa0s-R-12`). Through minor 9 `beginDrag` called
  `row.frame:SetScript("OnUpdate", ...)` on the frame the host handed to `AddRow`, and the drop and
  `Cancel` cleared it with nil, wiping any `OnUpdate` the host had set there. The ghost is a frame
  this library owns and is shown for exactly as long as a drag is in flight; its `OnUpdate` reads the
  dragged row at fire time, the way the handles do. A host row frame's scripts are never touched.
- **Behavioral: the insertion line comes from a library free list, per drag.** Through minor 9 it
  was built once and cached on the container as `__ka0sDropLine`, and both shipped consumers hand
  over an AceGUI-pooled container, so the line rode back into AceGUI's pool painted in the first
  list's `lineColor`. It is now taken when a drag starts, parented to the container `Finish` named,
  repainted in the dragging list's color, and given back (hidden, unanchored, reparented off the
  container) at the drop and on `Cancel`, through the same reclaim the handles and row boxes use.
  This restores the file's own pooled-frame invariant (the handle-pool block in `Widgets.lua`).
- **`Finish(container)` now only names the container** and returns nothing; at minor 9 it built the
  line and returned it. No shipped consumer reads the return. `controller.line` is set only while a
  drag is in flight.
- **A host suite that drives a drag by firing the row frame's `OnUpdate` must fire the ghost's**
  (`LibStub("LibKa0s-Widgets-1.0").__DragGhost`). On the 2026-09-24 grep one does:
  MultiMeters' `tests/test_columnblocks.lua` (`drag`, `block:_run("OnUpdate", 0.1)`), which will go
  red on the re-vendor until it fires the ghost. No consumer reads `__ka0sDropLine` or `Finish`'s
  return.
- `tests/test_widgets_reorder.lua` (new; `tests/test_widgets.lua` is at 1493 lines): a host
  `OnUpdate` on a row frame survives a drag start and end, a row frame with none is never given one,
  two lists with different `lineColor` draw their own color on one pooled container, and the line
  goes back on `Cancel` and at the drop and is reused by the next drag. `tests/test_widgets.lua`'s
  drag cases poll the ghost. Documented in
  [the version 10.2 document](docs/api/Widgets/version-10.2-docs.md); version 9.2 is Superseded.

### Perf minor 13: the sampler's state fields stay raw, and the open depth resets at window edges

- **Performance: `armed`, `recording` and `label` hold `false`, never nil** (review finding
  `LibKa0s-R-11`). Through minor 12 they were initialized and reset to nil, which removes the raw
  key, so the sampler's every-frame reads of `recording` and `armed` fell through to the instance's
  `__index` closure (it exists only for `suspended`). All three now start `false` and every nil write
  (`openWindow`, `closeWindow`, `Start`, `Stop`, `Cancel`) writes `false`; `Start(label)` stores
  `label or false`. The stale "no metatable" comment on `P.on` is rewritten.
- **Behavioral: a leaked `Open` no longer parents a bracket in a later window** (review finding
  `LibKa0s-R-16`). A host error between `Open` and `Close` left the slot open until the next
  `Start`, so every nested `Close` for the rest of the run named the leaked key as its observed
  parent. `openWindow` and `closeWindow` now reset the open depth to zero; the free list is kept.
- No member or descriptor field is added. A host suite asserting `p.recording == nil` after a window
  closes reads `false` now and must assert falsiness; this repo's `tests/test_perf_run.lua` had three.
  No consumer asserts nil on the 2026-09-24 grep; AbsorbTracker's perf suites write nil by hand
  between cases, which still works.
- `tests/test_perf_core.lua`: "a leaked Open in window A does not parent a bracket in window B".
  `tests/test_perf_isolation.lua`: the three fields stay raw keys across a window, a cancel and a
  label-less `Start`; the 0 KB bracket pins stay green. Documented in
  [the version 13.5 document](docs/api/Perf/version-13.5-docs.md); version 12.5 is Superseded.

### DebugLog minor 13: the buffer trim is batched

- **Performance: one compaction per 65 lines at the cap instead of a 1500-slot shift per line**
  (review finding `LibKa0s-R-10`). Through minor 12 every `Add` past `MAX_BUFFER` ran
  `table.remove(buffer, 1)`. The raw array may now run 64 lines past the cap, and the line that would
  take it to 1565 moves the newest 1500 down in one pass. `table.remove` is no longer called.
- **`buffer` stays a plain ordered array**, because host suites index it; only its length past the
  cap moves. Between compactions `#buffer` may read up to **1564**, while every public reader —
  `BufferSize()`, `LastLine()`, `FindLine()`, `CopyText()` and the status line — answers the newest
  1500. `FindLine` no longer answers a line in the slack. `MAX_BUFFER` stays 1500.
- No member or descriptor field is added. A host suite that writes more than 1500 lines and asserts
  `#D.buffer` or `D.buffer[1]` moves to `BufferSize()` / `CopyText()`; PrettyChat's
  `tests/test_debuglog.lua` has one such case.
- Characterization cases at 1499, 1500, 1501 and 1600 lines and "the 1501st line drops the first",
  green before and after; a `table.remove` spy over 1564 adds (64 calls at minor 12, at most one
  now); the peak raw length and the compaction's order; the status line past the cap. Documented in
  [the version 13 document](docs/api/DebugLog/version-13-docs.md); version 12 is Superseded.

### Slash minor 15: `CliSet` and `CliReset` print the write seam's refusal

- **Behavioral: a `set` answering `false, reason[, why]` is printed as a refusal**, where minor 14
  discarded the answer and echoed the unchanged value (review finding `LibKa0s-R-03`).
  `LibKa0s-Schema-1.0`'s `S.Set` answers exactly that when a row's `validate` rejects a value, so a
  host passing it straight through — BankLedger — showed the player `path = <old value>` and no
  reason. `CliSet` now prints `INVALID` for the path, then the reason and `why` on lines indented two
  spaces, and no echo; a reason that is the `INVALID` line itself is not printed twice. `nil` and
  `true` still mean success.
- **`CliReset` prints the new `lib.STRINGS.NO_DEFAULT`** (`"%s has no default to restore"`) when
  `applyDefault` answers exactly `false`, as `S.ApplyDefault` does for a row with no default.
- No member or descriptor field is added. A host whose `set` wrapper prints its own refusal
  (AuraMaster) should return the seam's answer and drop its prints, or the player reads it twice.
- Seven cases in a new `tests/test_slash_refusal.lua` (`tests/test_slash.lua` is in the 1000–1500
  band). Documented in [the version 15 document](docs/api/Slash/version-15-docs.md); version 14 is
  Superseded.

### Launcher minor 2: a disabled gate for the left click, and notices printed once, untagged

- **Additive: an optional `isEnabled` / `disabledLine` pair on the descriptor.** Where `onClick` is
  present and `isEnabled()` answers false, a left click prints `disabledLine()` and does not call
  `onClick`. That is `launcher-§2`'s disabled rung (a)/(b), which BankLedger, AuraMaster and
  AbsorbTracker each hand-wrote inside `onClick` in three spellings (review finding
  `LibKa0s-R-06`). Right-click and rung (c) are never gated; both open the settings panel, where the
  addon is re-enabled. `New` raises on an `isEnabled` with no `disabledLine`. A host that passes
  neither behaves exactly as at minor 1.
- **Behavioral: `NO_BROKER`, `NO_ICON` and `NO_MINIMAP` print once per instance**, where minor 1
  printed them on every failing `Register` — twice for a host that registers at `OnInitialize` and
  again at login. The debug seam still hears every call.
- **The four `lib.STRINGS` values drop their `[LibKa0s] ` prefix** (review finding `LibKa0s-R-09`):
  every line goes out through the host's printer, which adds the host's own tag, so the library's
  was a second tag. The keys are unchanged, so a `d.L` override still works. A consumer test that
  asserts the prefix has to drop it.
- `tests/test_launcher.lua` gains five cases: the refused left click, right-click and rung (c)
  ungated, the half-filled pair refused at `New`, one `NO_ICON` (and one `NO_BROKER`) across two
  `Register` calls, and no tag in `lib.STRINGS`. Documented in
  [the version 2 document](docs/api/Launcher/version-2-docs.md); version 1 is Superseded. Adopting
  the gate is a per-host follow-up: pass the two fields and delete the hand-written check.

### Lifecycle minor 2: the nested-edge (re-entrancy) behavior is documented and pinned

- **Documentation only; the bytes move, so the minor does.** `New`'s docstring now states that a
  `standDown` or `standUp` callback MUST NOT take or release a hold on its own latch, and what
  happens if one does: the edge calls the callback synchronously, so the nested edge runs to
  completion inside the outer one — a `standDown` that releases a hold fires `standUp` before it
  returns. The latch stays consistent (the edge is recorded before each callback), but the host's
  teardown and rebuild interleave (review finding `LibKa0s-R-17`). No shipped callback touches its
  latch. The code is unchanged.
- `tests/test_lifecycle.lua` gains one characterization case pinning the nested order and that
  `IsDown()` ends false. No member moves, so the manifest differs from minor 1's only in the minor.
  Documented in [the version 2 document](docs/api/Lifecycle/version-2-docs.md), with a
  *Re-entrancy* section; version 1 is Superseded. Every consumer gets the new bytes by
  re-vendoring; none needs a code change.

### Bus minor 2: the tracking wrappers are re-stamped after a newer AceEvent re-embed

- **Behavioral, and additive on the answers.** AceEvent-3.0's upgrade loop re-embeds every table in
  `AceEvent.embeds`, so a newer AceEvent minor loading after a Ka0s host had created its bus targets
  wrote the six raw members back over the bus's wrappers for the rest of the session. From then on a
  registration went straight to CallbackHandler and was never recorded: `StandDown` left it live on a
  target with an empty record, and `StandUp` never brought it back on one with a recorded entry
  (review finding `LibKa0s-R-05`). `StandDown` and `StandUp` now re-stamp every target the bus
  created before anything else, adopting whatever member they find in a wrapper's place as the new
  raw member, so a newer AceEvent's member is the one forwarded to. They answer the number of
  targets re-stamped as a trailing value (`n, restamped` and `replayed, rejected, restamped`) for the
  host's debug seam.
- **The residual window is documented, not closed.** A registration made between a re-embed and the
  next edge is still untracked until that edge. The edges are the only moments the record is read,
  so no Ace3 fork and no metatable proxy.
- The bus keeps every target it created in a **weak-keyed** set so an edge can re-stamp a target
  whose record is empty. It releases a target in Lua 5.1 only because the per-target record no
  longer names its target: the wrappers look their target up in the set instead of holding it.
- No member is added, so the manifest differs from minor 1's only in the minor. Documented in
  [the version 2 document](docs/api/Bus/version-2-docs.md); version 1 is Superseded.
  `tests/test_bus.lua` gains three cases. Every consumer gets it by re-vendoring; none needs a code
  change, unless it forwards either call in the last position of an argument list, where the extra
  value now arrives too. No consumer vendors an AceEvent-3.0 above minor 4 today, so this is latent.

### Media minor 4: `RegisterLSM` flags the face western + ruRU and counts what LSM holds

- **Behavioral, and nothing else moves.** `RegisterLSM` registered JetBrains Mono with no langmask,
  and LibSharedMedia refuses a maskless font on every non-western client, so on ruRU, koKR, zhCN and
  zhTW the face never reached a font dropdown while the returned count still said `1` (review
  finding `LibKa0s-R-04`). The face is now registered with
  `LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU` when LSM publishes those bits (a plain `Register`
  otherwise): it has Latin and Cyrillic glyphs, so ruRU keeps it, and it has no Hangul or Han, so
  CJK clients are excluded on purpose. Both counts now answer what LSM holds afterwards
  (`LSM:IsValid(type, name)`), not how many `Register` calls were made; a key another copy
  registered first still counts, because LSM has it. An LSM with no `IsValid` method, which the
  real LSM-3.0 always has but consumers' test fakes (MultiMeters, Aura Master) do not, is not asked:
  every `Register` call counts there, as at minor 3, so those harnesses keep loading unmodified.
- The doc comment claimed an identical `(mediatype, key, path)` triple made a second registration
  free. Every consumer offers a different path; the first registration wins, and it is harmless
  because every one of those paths names identical bytes. The comment now says so.
- No member is added, so the manifest differs from minor 3's only in the minor. Documented in
  [the version 4 document](docs/api/Media/version-4-docs.md); version 3 is Superseded.
  `tests/test_media.lua` gains five cases, and the existing registration case's fake gains
  `IsValid`. Every consumer gets it by re-vendoring; none needs a code change.

### Item minor 2: `QualityFromLink` reads the 11.1.5+ `|cnIQ<n>` link color

- **Behavioral, and nothing else moves.** Since patch 11.1.5 the client colors an item link by
  quality number, `|cnIQ<n>:`, not by an eight-digit hex. `QualityFromLink` matched only the hex
  shape, so it answered `nil` for every live link, and a consumer that falls back to the link for an
  uncached drop recorded that drop with no quality (review finding `LibKa0s-R-01`). A `|cnIQ<n>`
  rung now runs ahead of the hex one, anchored on the digits with no trailing `:` required, and
  answers `n` (`|cnIQ0` answers `0`). The hex rung stays for links stored before the patch.
- **The hex rung's quality map is kept only when non-empty** (review finding `LibKa0s-R-13`). It
  was assigned before `ITEM_QUALITY_COLORS` was read, so a first call that landed before the client
  populated that table pinned an empty map for the session. It is now built into a local and
  committed only when at least one entry landed, so the next call retries.
- `LoadItem`'s fixed 0.4 s timer is **deliberately unchanged**: it was byte-identical in both addons
  it came from, and both treat the callback as "try again". No member is added, so the manifest
  differs from minor 1's only in the minor. Documented in
  [the version 2 document](docs/api/Item/version-2-docs.md); version 1 is Superseded.
  `tests/test_item.lua` gains two cases, and its two `|cff` cases stay as the legacy rung's. Every
  consumer gets it by re-vendoring; none needs a code change.

### Core minor 8: `printer.Format` survives a secret in a numeric slot

- **Behavioral, and nothing else moves.** `Format(fmt, ...)` stringifies every argument through
  `SafeToString` before `format()` sees it, so a secret in a `%s` slot has always rendered as
  `<secret>`. In a **numeric** slot the sentinel is a string, and `string.format` raised
  `number expected, got string` on it: `Format("%d rows", secret)` took the raise to exactly the
  chat line the stringifying was meant to protect (review finding `LibKa0s-R-08`). The call is now
  `pcall`ed, and on failure the line still lands as the format verbatim and the stringified
  arguments, space-joined (`%d rows <secret>`), the fallback `LibKa0s-DebugLog-1.0`'s `D.Debug`
  already uses. A satisfiable format is untouched: `Format("%d rows", 3)` still prints `3 rows`.
- No floor moves and this change adds no member. Documented in
  [the version 8 document](docs/api/Core/version-8-docs.md); version 7 is Superseded.
  `tests/test_core.lua` gains one case. Every consumer gets it by re-vendoring; none needs a code
  change.

### Core minor 8: `SafeRegisterEvent`, `SafeRegisterUnitEvent`, `SafeRegisterEvents`

- **Three new lib-level members, the collection's one pcalled event registration helper**
  (`events-frames-taint-§1`, review finding `AuraMaster-R-05`). The client raises on an event name
  it does not know, and a block of bare `RegisterEvent` calls loses every line after the one that
  raised. `SafeRegisterEvent(target, event, handler, rejected)` rejects the name without a call when
  `C_EventUtils.IsEventValid` exists and answers `false`, otherwise asks a private probe frame (a
  raw frame asks the client on every call; AceEvent asks only for an event's first registrant, so the
  target's own answer is `true` for every later one), and then runs
  `pcall(target.RegisterEvent, target, event, handler)`, so an AceEvent-embedded object, a Frame and
  a Bus target all work, and a Bus target still records the registration for its replay.
  `SafeRegisterUnitEvent(frame, event, rejected, unit1, unit2)` does the same through
  `RegisterUnitEvent`; `SafeRegisterEvents(target, events, handler, rejected)` walks an array and
  answers how many registered. Each answers `true`/`false` (or the count).
- **No registration state, no printing.** `rejected` is an optional array the caller owns, appended once
  per refused name and never twice, so a disable/enable cycle leaves it unchanged. The host surfaces
  it (`[Init]`, a debug verb).
- Still minor 8: v1.56.0 has not shipped, and one unreleased minor carries both changes. The member
  manifest gains the three names; `.luacheckrc` gains `C_EventUtils` as a read global.
  `tests/test_core.lua` gains nine cases, the per-rung ones run on the front gate and on the probe
  frame. A consumer with a Core degradation stub adds the three members with one-rung bodies (pcall,
  no front gate, no probe), shown under *Degradation* in the version 8 document, so
  `Kit.assertSurfaceParity` stays green.

### Test kit revision 26: two files peeled out, no behavior change

- **`testkit/asserts.lua` (new).** `framework.lua`'s assertion family (`Kit.fail`,
  `Kit.assertEqual`, `assertTrue`, `assertFalse`, `assertNil`, `assertNear`, `assertError`) and its
  surface-parity gate (`Kit.setSurfaceSource`, `Kit.publicMembers`, `Kit.assertSurfaceParity`, and
  the private `callable` / `resolveSurface` helpers behind them) moved, unchanged, into a file of
  their own. `framework.lua` loads it once, where the block stood and before `Kit.expose`, from the
  folder its own chunk name names (falling back to `tests/_kit/`), so every member is on the kit
  table exactly when it was. `framework.lua` drops from 1583 lines to 1381, back under
  `layout-§1`'s cap, which retires its row in the over-cap census in `CLAUDE.md`. That row had
  claimed a "Ratified deviation row" that the deviation register never held (the 2026-09-23 audit's
  `LK-34`), and peeling the file resolves the claim without adding one.
- **`testkit/prose_lists.lua` (new).** The prose gate's published lists — `BRITISH`, `ALLOWED`, the
  two published counts and the `SKIPPED_DIRS` folder exclusions — moved out of
  `testkit/test_prose.lua`, which loads them from its own folder the same way. The gate drops from
  1499 lines to 1464, and the list growth still to come lands in a file of data rather than in it.
  This repo's own `tests/test_prose.lua` exempts the new file for the reason it exempts the gate:
  it quotes every forbidden spelling in order to forbid it.
- `Kit.VERSION` 25 → 26, with [its document](docs/api/testkit/version-26-docs.md). A consumer that
  re-vendors takes two new files in `tests/_kit/`; its suite totals do not move.
  `tests/test_kitsync.lua` gains one case asserting both files exist in `testkit/` and
  `tests/_kit/`.

### Test kit revision 26: `Kit.assertErrorMatches`

- **`Kit.assertErrorMatches(fn, needle, msg)` (new, in `testkit/asserts.lua`).** Asserts that `fn`
  raises **and** that the raised text contains `needle` as plain text; it fails naming the needle
  when nothing was raised, and naming both the needle and the raised text when something else was.
  It returns the error, and `Kit.expose` copies it. `Kit.assertError` only ever proved that
  *something* raised, and `testing-§12` does not accept that as proof (review finding
  `LibKa0s-R-07`). Documented in [the revision 26 document](docs/api/testkit/version-26-docs.md).
- **The 23 statement-position `assertError` calls now assert on the raised text**, in
  `tests/test_launcher.lua` (the four descriptor refusals, whose expected field names had been
  passed only as failure messages), `tests/test_kit_inventory.lua` (five decline cases, which
  would have passed on any unrelated raise), `tests/test_mock_ace.lua` (nine),
  `tests/test_loader.lua`, `tests/test_options_compose.lua` and `tests/test_schema.lua`. The new
  `tests/test_kit_asserts.lua` adds three cases for the member itself. A consumer that re-vendors
  takes the new member; its own suite totals do not move.

### Test kit revision 26: `Kit.assertLibraryConstant`, and the Slash degradation stub

- **`Kit.assertLibraryConstant(value, majorName, memberPath, msg)` (new, in
  `testkit/asserts.lua`).** Asserts that a degradation stub's copy of a library constant is
  byte-equal to the live library's `memberPath` (a member or a dotted path) on `majorName`, and
  fails naming both strings when they differ, or naming the major or member that did not resolve.
  The live half is looked up through the registered surface source; a member the source's answer
  lacks is read off the exposed LibStub instead, which `Kit.expose` now records as the fallback
  whenever the exposed table carries one, so a runner that maps `LibKa0s-Slash-1.0` to the Slash
  instance (AbsorbTracker, WhatGroup) can still pin the lib-level `DISABLED_LINE_FORMAT`. What
  `Kit.expose` registers as the surface source is unchanged (review finding
  `PartyFrameEnhanced-R-11`; WhatGroup#22). `tests/test_kit_asserts.lua` gains four cases.
  Documented in [the revision 26 document](docs/api/testkit/version-26-docs.md).
- **The Slash version 15 document gains *The degradation stub*** — the shape `slash-commands-§1`
  now bounds a library-absent Slash stub to: minimal `OnSlash` dispatch; `DisabledLine` built from
  `DISABLED_LINE_FORMAT`'s bytes copied verbatim, the one library string a stub may carry, pinned
  with the new assertion; help rows printed `cmd  desc` with no `FormatRow` copy; and a
  composed-row verb that either writes through the Schema seam's `writeThrough` list or prints
  `%s is unavailable: the LibKa0s library did not load.`, never raising. Documentation only:
  `Slash.lua` does not change, and its minor stays 15. Every consumer's stub is asked to pin its
  line on its next re-vendor.

### Test kit revision 26: the AceDB fake raises where AceDB-3.0 raises

- **Behavioral.** `CopyProfile(name, silent)` raises on the active profile, and on a missing source
  unless `silent`; `DeleteProfile(name, silent)` raises on the active profile, and on a missing one
  unless `silent`. The four messages are AceDB-3.0's own, byte for byte (`AceDB-3.0.lua:531-537`
  and `:581-587`), at level 2. Through revision 25 all four returned silently, so a consumer's copy
  or delete command passed its suite on a name that raises a raw Lua error in the client (review
  findings `AbsorbTracker-R-06` and `PartyFrameEnhanced-R-09`). A consumer suite that goes red on
  re-vendoring is exposing that defect, not a kit regression.
- `CopyProfile` resets before it copies, as AceDB does, so a key the source lacks reads its default,
  and a silent copy of a missing profile is a reset. `SetProfile` strips the outgoing profile of
  every value equal to its default (`:460-463`), modeling `removeDefaults`' scalar and plain-table
  arms but not its `"*"`/`"**"` wildcards. `OnProfileChanged` and `OnProfileCopied` fire as before.
- `tests/test_mock_record.lua` gains eight cases. Documented in
  [the revision 26 document](docs/api/testkit/version-26-docs.md).

### Test kit revision 26: `EventRegistry`, `C_EventUtils` and frame registration

- **`testkit/mock_events.lua` (new).** A recording `EventRegistry` (`RegisterCallback`,
  `UnregisterCallback`, `TriggerEvent`; one callback per event and owner, invoked as
  `func(owner, ...)`, CallbackRegistry's own argument refusals, and a loud raise on the unmodeled
  closure form). Every live callback appears in `M.__registrations()` as
  `{ kind = "callback", event, owner }`, with no `target`, after every other kind. Through revision
  25 no callback reached the survey, so a stand-down suite could not see an `EditMode.Exit`
  callback left registered on disable (review finding `PartyFrameEnhanced-R-10`).
- **Behavioral.** A raw `frame:RegisterEvent` or `frame:RegisterUnitEvent` on a name in
  `M.__badEvents` raises `Attempt to register unknown event "<NAME>"` at level 2 and records
  nothing, as the AceEvent path has since revision 17; through revision 25 the frame recorded the
  name. `M.__badEvents` is read at call time.
- `M.C_EventUtils.IsEventValid(name)` answers `false` for a name in `M.__badEvents` and `true`
  otherwise; a suite sets `M.C_EventUtils = nil` to model an older client.
- `mock_base.lua` loads the file from its own folder through the loader that finds
  `mock_record.lua`, now taking the file name, and grows two lines to 1448. The new
  `tests/test_mock_events.lua` holds fourteen cases. Documented in
  [the revision 26 document](docs/api/testkit/version-26-docs.md).

### Test kit revision 26: a new frame starts shown

- **Behavioral.** The frame stub in `testkit/mock_base.lua` starts every frame **shown**
  (`__shown = true`), as `CreateFrame` returns one in the client; through revision 25 it started
  hidden, so `M.__shownFrames()` never listed a frame production built and never hid (audit finding
  `PartyFrameEnhanced-A-02`). `M.GameTooltip`, `M.SettingsPanel` and `M.StopwatchFrame` are hidden
  at build, because the client's own windows start closed. Fidelity rule 5's note says so, and
  `mock_base.lua` is 1452 lines.
- **Consumer note.** A stand-down suite's `F_on` baseline now sees the addon's container frames. A
  red on re-vendoring is either a frame the addon leaves shown, a real defect, or a setup that owes
  the case the `Hide()` production performs; it is never fixed by weakening an assertion.
- `tests/test_mock_base.lua` gains "a new frame is shown until hidden, as in the client". This
  repo's one case that relied on the old default, `tests/test_options_idsuggest.lua`'s "a box that
  left before the pause shows nothing", now hides the box's frame before firing `OnHide`, as the
  client does when the panel goes away. Documented in
  [the revision 26 document](docs/api/testkit/version-26-docs.md).

### Test kit revision 26: `test_eol.lua` catches a lone CR

- **Gate widened.** `testkit/test_eol.lua`'s first case now also counts every **lone CR** (a byte 13
  no byte 10 follows) in each file it already scans, and fails naming each as `path:line`. Through
  revision 25 it counted LFs and the CRs before them, so `a\r\r\n` read as one clean CRLF, and
  git's `text=auto` stores a file with a lone CR as binary, so nothing else saw it either (audit
  finding `AuraMaster-A-18`). The check is not keyed on the index's `-text`, which would redden real
  binaries that detection caught unmarked; the NUL guard still skips those.
- **Consumer note.** A dry run over every addon found AuraMaster's `tests/page_helpers.lua:80` and
  KickCD's frozen `docs/reviews/2026-09-23/` bundle (852 lone CRs across five files) red. Both are
  addon fixes owed before re-vendoring revision 26.
- `tests/test_kit_eol.lua` gains four "eol lone CR" cases. Documented in
  [the revision 26 document](docs/api/testkit/version-26-docs.md).

### Test kit revision 26: the prose gate reads the store roots and lists `synchronis`

- **Gate widened.** `testkit/prose_lists.lua` gains `SCAN_BACK`, naming
  `docs/automated-tests/README.md`, `docs/automated-tests/RESULTS.md` and
  `docs/perf-analysis/README.md` file by file; `testkit/test_prose.lua` reads them although their
  folders are skipped, because they are rewritten in place rather than frozen (audit findings
  `ConsumableMaster-A-05` and `KICKCD-A-06`). A consumer `skipDirs` entry that only restates a kit
  folder does not undo it, and is disclosed as suppressing nothing; a wider one, or `skipFiles`,
  does, and is disclosed.
- `SKIPPED_DIRS` gains `docs/superpowers/` and `docs/investigations/`, the two frozen stores
  `documentation-§3` lists that the gate read (`PanelMaster-A-09`).
- `BRITISH` gains `synchronis` and `ALLOWED` gains *synchronism*, *synchronisms* and *synchronistic*,
  to the standard's v2.65.0 lists: 92 and 33.
- This repo's own `tests/test_prose.lua` carries the same lists and reads its two
  `docs/automated-tests/` store-root files. Its one new hit, a comment in `LibKa0s/OptionsTabs.lua`,
  is respelled; `TABS_MINOR` moves with `LK-27`'s change to that file in this release.
- **Consumer note.** A dry run found ConsumableMaster (`docs/perf-analysis/README.md:25-26`,
  `docs/settings-panel.md:80`), KickCD (`docs/perf-analysis/README.md:35-36`,
  `docs/settings-panel.md:168`, `settings/Panel_Render.lua:61`) and MultiMeters
  (`tests/test_options_panel.lua:1091`) red; each is an addon fix owed before re-vendoring revision
  26. AuraMaster's disclosure case name changes, so its `docs/test-cases.md` regenerates.
- The new `tests/test_kit_prose.lua` holds twelve cases. Documented in
  [the revision 26 document](docs/api/testkit/version-26-docs.md).

### Test kit revision 26: kit citations carry the section sign

- **Case names change.** Every section citation in a kit string literal, case name and comment is
  spelled `<file>-§N` (`documentation-§6`), 79 lines across `testkit/framework.lua`,
  `prose_lists.lua`, `test_eol.lua`, `test_layout_cap.lua` and `test_prose.lua`. Four case names
  move (`line-endings-§5`, `layout-§1`, and two `localization-§5`), so every consumer regenerates
  `docs/test-cases.md` with its re-vendor; its totals do not move. `KIT_GATE_RULE` maps to
  `localization-§5`, `line-endings-§7` and `layout-§1`; `normRule` is unchanged and still matches a
  register cell written without the sign. Audit findings `AbsorbTracker-A-17` and
  `WHATGROUP-A-13`.
- This repo's `tests/test_prose.lua` ASCII gate now reads `LibKa0s/` only. The kit prints to a
  terminal and `tests/_kit/` never ships, so the gate had no player to protect there, and it was
  what forced the sign-less spelling. The gate's long-bracket exemption, which existed only for the
  kit's `.gitattributes` transcripts, is removed.
- Two red-first cases: "the ASCII gate scans LibKa0s/ and not testkit/" in `tests/test_prose.lua`,
  and "no kit string literal cites a section without the section sign" in
  `tests/test_kit_inventory.lua`. Documented in
  [the revision 26 document](docs/api/testkit/version-26-docs.md).

### Test kit revision 26: the runner records the `performance-§12` exemption and heads empty tables

- **Perf skip reason (2).** When a repo ships no `tests/perf.lua`, `run-automated-tests.sh` now reads
  its `## Documented deviations` register (`docs/ARCHITECTURE.md`, then the root `CLAUDE.md`) before
  it falls back to reason (1). A row whose Rule cell is exactly `performance-§12`, after `normRule`'s
  reduction, records `performance-§12 no-combat-path exemption (ratified; <file> -> Documented
  deviations)` as the manifest's `skipReason`, and `RESULTS.md`'s Perf section states the second
  sanctioned reason and points at `docs/performance.md`. A disclaiming row such as `performance-§12
  (the exemption is not claimed)` does not match. Reason (1)'s text is unchanged. Through revision
  25 the runner knew reason (1) only, so BankLedger, LootHistory and PrettyChat had their ratified
  exemption denied in every record (audit findings `BankLedger-A-04`, `LootHistory-A-12`,
  `PRETTYCHAT-A-15`). Each records reason (2) on its first run after re-vendoring.
- **An unreadable register exits 2**, before any suite runs and before the bundle directory exists:
  a register table with no `Rule` header, no `|---|` separator, or a row with no cell after its
  Rule. A row with more cells than the header is accepted, because a `|` in a code span splits a
  cell and several registers in the collection carry one.
- **`KA0S_PERF_EXEMPT=1`** records reason (2) only in a repo with no register at all. A present
  register outranks it.
- **Empty watch-list tables keep their header.** `fn_table` and `band_table` print the header row
  and separator unconditionally, and the `None.` they printed for an empty set is gone
  (`automated-tests-§4`; audit finding `LibKa0s-A-09`).
- The new `tests/test_kit_runner.lua` holds seven cases that run the script over fixture repos. The
  complexity case skips where `lizard` is not on PATH. Documented in
  [the revision 26 document](docs/api/testkit/version-26-docs.md).

### Test kit revision 26: an AceGUI Create/Release survey

- **`M.__aceguiLive(type)` (new, in `testkit/mock_record.lua`).** How many widgets of that type the
  AceGUI fake has handed out and not taken back; with no type, a table of every type with at least
  one out. The fake never reuses a widget, so a render that Creates on every pass and never
  Releases passed every other assertion in the kit, which is how the page banner's per-render
  `Dropdown` went unseen (review finding `LibKa0s-R-02`). `mock_base.lua` feeds it with two lines,
  one in `Create` and one in `Release` (1454 lines with them). A Release of a widget `Create` never
  handed out is ignored rather than counted below zero. `tests/test_mock_record.lua` gains two cases.
  Documented in [the revision 26 document](docs/api/testkit/version-26-docs.md); a consumer's suite
  totals do not move on re-vendoring.

Release gate (`docs/automated-tests/20260924-040553/`): lint pass, 0/0 in 92 files;
tests pass, 1648 tests, 0 failed; complexity pass, 0 over CCN 15. Perf
SKIPPED, not measured — no `tests/perf.lua` — so the gate covered three suites, not four.

## v1.55.0 — 2026-09-23

Versions in this release: **test kit revision 25**, and three new majors — **Compat minor 1**
(`LibKa0s-Compat-1.0`), **Bus minor 1** (`LibKa0s-Bus-1.0`) and **Schema minor 1**
(`LibKa0s-Schema-1.0`). **No existing `.lua` file in the library changes** — every existing major's
version key and every existing file's LibStub minor are exactly v1.54.2's. The payload is not
unchanged, though, and this release is not kit-only: it gains three files, `LibKa0s/Compat.lua`,
`LibKa0s/Bus.lua` and `LibKa0s/Schema.lua`, and `LibKa0s/LibKa0s.xml` is the one existing payload
file whose bytes move, by the three `<Script>` rows that load them. The kit gains one file,
`testkit/test_layout_cap.lua`, and changes five. So a consumer that re-vendors takes new bytes in
`tests/_kit/`, the three new files and the three new XML rows in `libs/LibKa0s/`, and identical
bytes everywhere else in the payload. The repository also gains `tests/test_compat.lua`,
`tests/test_bus.lua`, `tests/test_schema.lua`, `tests/test_kit_inventory.lua`, and a
`docs/api/Compat/`, `docs/api/Bus/` and `docs/api/Schema/` folder each holding a version-1 document
and member manifest. None of those is vendored.

**Five rules in the Ka0s WoW Addon Standard v2.63.0 name this revision, and this release is what
they were waiting for.** `layout-§1`, `line-endings-§7`, `testing-§9`, `localization-§5` and
`automated-tests-§4` each carry a commencement clause reading *from LibKa0s test-kit revision 25
(LibKa0s v1.55.0)*. They were written that way because the standard's own audit found a defect
class it had been producing for a year: a **MUST no repository can satisfy by any act of its own**.
Each of those five rules is enforced by a gate, the gate lives in this kit, and a repo's only move
is the re-vendor. A consumer's obligations under those five clauses therefore commence when it
re-vendors this tag — not when the standard was committed — and a repo whose kit predates revision
25 owes the re-vendor, never a hand-written suite of its own.

### Three new majors: Compat, Bus and Schema

The Ka0s WoW Addon Standard's harvest of 2026-09-22 ratified three extractions into this library —
findings C2-F01 (Compat), C2-F02 (the bus), C2-F03 (the schema runtime) and C3-F08 (the secret
seam, narrowed to `IsSecret` / `CanAccess` / `IsSafeKey` and folded into Compat) in that bundle's
`02_FINDINGS.md`. Each lands the way a new major always has: a new file in `LibKa0s/`, a new
`LibKa0s.xml` row, a new row in `tests/majors.lua`, a suite, an API document and a generated
member manifest. **All three are additive.** None changes a byte of an existing `.lua` file, the
only existing payload file touched is `LibKa0s.xml`, which gains their three rows, and each
floors on Core minor 1 and returns before `NewLibrary` without it, calling no Core member — the
load-payload check `library-stack-§7` asks for, so a partial payload leaves every module absent
rather than a working half.

- **New major `LibKa0s-Compat-1.0` (`Compat.lua`, Compat minor 1): nine stateless members.** The
  secret seam — `IsSecret`, `CanAccess`, `IsSafeKey` — and six version-variant readers:
  `GetSpellInfo`, `GetSpellName`, `GetSpellTexture`, `GetSpellCooldown`, `GetSpecialization`,
  `GetSpecializationInfo`, each a ladder from the namespaced API down to the deprecated global,
  read at call time and guarded for absence. It is deliberately narrow: a member is here only when
  two or more addons had a production caller for it and every copy agreed on the right answer, and
  what was considered and left out is recorded in the document. The copies it replaces had
  drifted — two read the deprecated `GetSpellInfo` global's rank as the icon, one compared a
  possibly-secret spell name with `""`, one read a legacy `isEnabled` of `0` as enabled — and each
  is resolved in writing in [its document](docs/api/Compat/version-1-docs.md). One statement there
  rests on the source copies rather than on a measurement, and the document says so: that
  `isEnabled` on the modern cooldown table is a plain value. It wants an in-game check on a 12.x
  client. `tests/test_compat.lua`, 49 cases.
- **New major `LibKa0s-Bus-1.0` (`Bus.lua`, Bus minor 1).** `New` builds the stand-down record for
  an addon's tracked bus receivers — `NewTarget`, `StandDown`, `StandUp` — so a stood-down addon
  takes every event and message registration down and a stood-up one puts back exactly what is
  wanted now, CallbackHandler's optional `arg` included. `Catalog` validates the addon's
  `Ka0s_<Addon>_<Event>` message names once at load and hands back a strict copy that raises on a
  mistyped key (`architecture-§4`). Four repos wrote the record by hand; this is the widest of them
  without the two defects the copies carried, a key list that gained a duplicate on every
  re-register and a replay that dropped `arg`. It owns no hold set — the host calls it from inside
  its own Lifecycle callbacks, at the point in its sequence it chooses — and AceEvent-3.0 is
  resolved at call time, never required. [Its document](docs/api/Bus/version-1-docs.md) records
  what it does not free: every AceEvent-embedded target lives for the session in `AceEvent.embeds`
  whatever the bus does, so retiring a record releases the bus's reference, not the memory.
  `tests/test_bus.lua`, 27 cases.
- **New major `LibKa0s-Schema-1.0` (`Schema.lua`, Schema minor 1): the settings schema runtime.**
  The host keeps its rows; this supplies the path primitives (`SplitPath` / `Read` / `Write` /
  `SameValue`, and the `STRINGS` table of default refusal wording), the row registry, the single
  write seam `Set` (`architecture-§5`), the bulk bracket (`debug-logging-§10`), the profile reset's
  count and `Validate`. Nine hosts carried that machinery and the copies disagreed on which of two
  duplicate rows wins, whether a table value is copied into the store, what the bulk line counts
  and whether a raising `onChange` is swallowed; each is one answer now, recorded in
  [its document](docs/api/Schema/version-1-docs.md) with the reading taken. Adopting it changes
  some hosts' behavior on purpose, and that document's adoption notes list every such change.
  A host's library-absent stub is write-completing and log-silent, so host verbs and Reset All
  keep writing on a degraded load; `tests/test_schema.lua` carries the reference stub.
  `tests/test_schema.lua`, 62 cases.

**A consumer whose harness re-types its lib load list owes three rows on re-vendor.** A harness that
derives the list from `LibKa0s.xml` picks the new files up with no edit. Two re-type it —
LootHistory's `tests/test_libka0s.lua` (`LIB_FILES`) and WhatGroup's `tests/loader.lua`
(`LIBKA0S`) — and each adds `libs/LibKa0s/Compat.lua` after `Env.lua`, then `libs/LibKa0s/Bus.lua`
and `libs/LibKa0s/Schema.lua` after `Lifecycle.lua`, the XML's own order. Adoption of any of the
three majors is per host and separate from the re-vendor; `docs/releasing.md`'s consumer table
carries each as pending. A consumer whose runner registers a table-map surface source adds the
major's row to it when it adopts, or the by-name parity call cannot resolve the live half
([Compat's gate](docs/api/Compat/version-1-docs.md#how-a-host-wires-it)).

### The declaration is the pair (basename, directory)

`Kit.assertSuiteInventory` keyed a declaration by **basename** through revision 24. A bare
`"test_prose"` in a runner's suite list wired that repo's own `tests/test_prose.lua` and was
accepted as covering `tests/_kit/test_prose.lua` too, which was loading nothing. **Six of the twelve
repos carrying the kit were in exactly that state** — BankLedger, ConsumableMaster, LibKa0s,
LootHistory, PrettyChat and WhatGroup, each declaring a bare `test_prose` beside a local file of
that name, and **not one of the six carrying a register row for it**. That is worse than an absent
gate: an absent gate leaves a visible gap, while a shadowed one leaves the repo's own record — the
suite list, `docs/test-cases.md`, the pass count — asserting the rule is covered.

The key is now the pair, and the inventory reports three shapes instead of one. A **collision** —
the basename declared bare against the repo's own directory while the kit ships one too — is a
failure naming **both** paths and saying which one is running. An unreferenced kit suite with no
local twin is the same **hole**, and the same failure. And either of those, with a
`## Documented deviations` row behind it, is a **decline**: reported once, as a skip carrying the
row's own reason, so it lands in `docs/test-cases.md` and in the run's output rather than nowhere.
The carve-out reaches the collision as well as the general form, because every repo
`localization-§5`'s permission was written for *is* a collision, and a carve-out that reached only
the general form would leave that permission unexercisable by exactly those repos.

**A decline row has to say which copy it is declining**, and this library is the proof. Its register
carries two `localization-§5` rows about third-party API identifiers, so matching on the rule cell
alone would have switched the prose gate off without ever mentioning it — and both of those rows go
on to mention `tests/test_prose.lua` in passing, so matching the bare basename would have done the
same. So a decline needs the Rule cell to name the rule **and** the row to name `tests/_kit/<suite>`.
That is narrower than the standard's wording, deliberately: the alternative hands six repositories a
waiver none of them wrote.

**The kit was green and wrong at the same time, and that is the part worth keeping.** Written
without path normalization, the pair key compared directory strings raw. Two runners in the
collection — KickCD and MultiMeters — compose their `dir` out of a root resolved from `arg[0]`, so
`./tests/_kit/` arrives from one side while the suites list beside it spells the literal
`tests/_kit/` that `testing-§9` prescribes. Raw inequality read those as two directories and
reported a **collision** against two repositories that had done exactly what the rule asks, with a
remedy telling them to delete a vendored file — and it failed from `Kit.run`, so the whole suite
aborted, no case ran, and `--list` aborted with it, leaving the repo unable to regenerate its own
`docs/test-cases.md`.

This library's own suite passed throughout, because it spells its `dir` one way on both sides.
The defect was caught by running the revision against the other eleven trees before it shipped,
which is a check a kit's own suite structurally cannot make: every gate in here is enforced
somewhere else, and green at home says nothing about that. Every directory that becomes a key or a
comparand now folds to one spelling at the point it enters the gate — `./` stripped, `//` and `/./`
collapsed, exactly one trailing slash — lexically, leaving `..` and backslashes alone, because
resolving file identity would need a subprocess per comparison and would follow symlinks the
runner's own `dir` does not.

**Then the same defect came back wearing the other hat, and a second consumer drive found it.**
Folding the spellings ONE hand produces is not the same as folding the spellings TWO hands produce.
KickCD and MultiMeters each take a root from `arg[0]` with a `"."` fallback, hand `Kit.run`
`root .. "/tests/"`, and then declare one kit suite as `root .. "/tests/_kit/"` and the next as a
bare `"tests/_kit/"` — both correct, both in the same list. From the repo root the fallback makes
the root `"."` and normalization folds the two together, which is why the first fix looked
sufficient. Invoked BY PATH from any other working directory — a wrapper script, an editor's
runner, a CI step — the root is absolute, the relative entry keys against a different string from
the very directory it names, and the inventory reported one correctly wired suite as BOTH "declared
but not on disk" AND "arrived with the kit but is not declared", aborting before a case ran. So
neither side is keyed until it has been read against the other (`resolveDir`): a relative entry
under an absolute runner takes the runner's own root, and an absolute entry under a relative runner
is cut back at the runner's own directory — the one anchor the two share, at its LAST occurrence so
a checkout that itself lives under a `tests/` cuts in the right place. An absolute entry that never
passes through that directory is left alone rather than given an invented relationship.

**And the remedy was printing something nobody could paste.** Every hint here hands over a
`{ name = ..., dir = ... }` for a suites list, and each interpolated the directory the gate had
RESOLVED: under a runner rooted at `arg[0]`, invoked from elsewhere, that read
`dir = "/home/someone/GIT/KickCD/tests/_kit/"`. An engineer who follows a remedy literally — which
is what a remedy is for — would have hard-coded one machine's checkout into a file every other
checkout runs. `adviceDir` now separates the two: the resolved path is still printed as a
diagnostic, saying where the file is, while the advice is the repo-relative directory plus the
instruction to build it from the same root expression the runner already passes to `Kit.run`. The
declined-gate case NAME had the same defect and it reached further: it interpolated the resolved
path, so `docs/test-cases.md` — a generated file that is committed — said one thing when the runner
ran from the repo root and another when a wrapper invoked it by path. That name is now the
root-relative `tests/_kit/<suite>.lua`. **The dedupe key stays the resolved path**, and trying to
move it too was the mistake that proved it: the key has to tell two REPOSITORIES apart inside one
process, and `tests/_kit/test_prose` is the same string in all of them.

Eleven cases pin all of this, in a suite of thirty — the five normalization cases, including one
that starts a child interpreter from a fixture root to reproduce the literal shape, and six more for
the two-sided resolution and the remedy text, four of which drive KickCD's own mixed list.

### `test_layout_cap.lua` — the cap gate, in the kit

`layout-§1` caps every authored `.lua` file a repo tracks at 1500 lines and requires each breach's
disposition to be written where a reader and a gate can both find it. Until now the enforcement was
five hand-written suites and seven addons with nothing. The five measure **232, 221, 209, 380 and
206 lines and no two are byte-identical** (md5 `5a08ecf7`, `94822c5e`, `8a6f4efb`, `14b885da`,
`dada183d`), and they had drifted where it costs: one looks for a heading named ``Files by the
`layout-§1` band`` where the other four look for `Files over the 1500-line cap`, so one rule was
keyed to two names, and that same copy gates the 1000–1500 band the release watch list already
generates.

The kit's copy reads `git ls-files`, drops vendored code (`libs/` and `tests/_kit/`), counts lines
on the bytes on disk, and asserts the three things `layout-§1` names and their converses: nothing
over the cap is missing from the census, no census row outlives its breach, and every over-cap row
carries one of the three terminal states — except a row marked `exempt`, which is graded against the
exempt set the gate is handed. It **fails rather than skips when it cannot look**, and a repo that
tracks no authored `.lua` skips with the reason said out loud.

The two facts a gate cannot infer arrive on the kit table as `Kit.layoutCap`: the engineer-context
hub, and the generated-data exempt set. Whether an exemption is *legitimate* rests on three
repository facts no path betrays — generated rather than authored, loaded by nothing, excluded from
the payload — and that judgment stays with the auditor. What the gate asserts is only that the
census and the exempt set **agree about which paths were exempted**.

### `test_prose.lua` — the generated-data carve-out, as an input

`localization-§5`'s third exclusion is a generated dump of the client's own strings. It now reaches
the prose gate the way the cap gate's exempt set reaches that one, on the kit table before
`Kit.run`:

```lua
Kit.prose = { exempt = { "GlobalStrings/" } }   -- generated, loaded by nothing, not packaged
```

Same shape, same semantics, same bargain: an array, a map or both; a tracked path or a folder,
compared as `entry .. "/"` so a sibling whose name merely starts with it is not swept in; no globs;
a stale entry is stale rather than silent and is not a failure; a malformed one is. The carve-out
drops the path **before it is opened** rather than filtering its hits — the one folder in the
collection it applies to is 3.6 MB across 27 files, one of them 23,842 lines, that the gate would
otherwise read to say nothing.

It is an input rather than an inference because it rests on three facts about the repository that no
path betrays: a script writes the file and a person does not edit it, nothing loads it, and
`.pkgmeta` keeps it out of the packaged zip. **A generated file that ships is not exempt** — the
third condition fails, and its spellings reach a screen.

**Two of the three are now GATED, and the first draft gated none of them.** A path betrays nothing,
but the repository root this gate already runs in answers two of the three out loud, and that is the
difference between a carve-out and the whole-file waiver `localization-§5` forbids. Measured on a
repository in this collection: with
`Kit.prose = { exempt = { "core/WhatGroup.lua", "docs/data-flow.md", "tests/" } }` WhatGroup's prose
gate went green while silencing five real hits, two of them inside the packaged payload, and the run
printed not one word about it — `core\WhatGroup.lua` is line 48 of that addon's TOC. So:

- **A path the TOC loads is refused.** Every tracked `.toc` is parsed, its backslashes read as the
  separators they are, its `##` directives and comments dropped, and each file line resolved against
  its own TOC's folder so a vendored library's TOC names its own files. A declared narrowing
  covering any of them reddens the run.
- **A path `.pkgmeta` does not ignore is refused.** The root `.pkgmeta`'s `ignore:` block alone is
  read — a column-zero sibling key closes it, indented comments and blank lines do not — and an
  entry no ignore line covers reddens the run. Coverage is exact, by folder, and by the packager's
  `*`, matched on the whole path and on the basename.
- **Both refusals reach both channels.** A repository narrows this gate in two places —
  `Kit.prose.exempt` in the runner, and `skipDirs` / `skipFiles` in `tests/prose_waivers.lua` — and
  they are merged into the same exclusion sets and take files out of the same scan. The first draft
  gated the carve-out alone and left the older, wider channel beside it checked against nothing,
  while the refusal's own failure text pointed a refused consumer straight at it. Every entry in
  all three lists is now a **declared narrowing** and both refusals run over the lot, in the same
  words. Each list is refused on **its own** matching rule, because a refusal has to cover exactly
  what that list suppresses: the carve-out matches a path or a folder, `skipDirs` is the plain
  prefix the scan compares, `skipFiles` is one exact path. `localization-§5`'s own published
  exclusions are neither refused nor disclosed — they are the baseline, and `libs/` is on every TOC
  in the collection on purpose.
- **Both refusals read ONE resolved coverage set, because they had come to disagree about what
  they were refusing.** `narrowingsNotIgnored` asked `.pkgmeta` about the narrowing **entry as
  written**; `narrowingsLoadedByToc` asked about the paths the narrowing actually suppresses. For
  `Kit.prose.exempt` and `skipFiles` the two questions coincide. For `skipDirs` they do not: its
  coverage is an unanchored plain prefix while the ignore check anchors on `entry .. "/"`, so
  coverage spills past the boundary the refusal checks. Measured in a throwaway Aura Master with
  its real `.pkgmeta`, which ignores `tools`: `skipDirs = { "docs/spell-research/", "tools" }` hid
  the **shipped root file** `tools-notes.md` carrying `colour` and `cancelled`, and the run was
  **15 passed / 0 failed with both refusals green**. Every entry is now resolved through its own
  rule against the tracked authored set **once**, and the refusals, the disclosure and the counts
  read that one resolution. The packaging refusal asks about the entry as written **and** about
  every path it covers — the first arm keeps a stale entry honest, the second closes what it left
  open — and names the shipped file it found, not only the entry.
- **A narrowing that covers no tracked path is refused for its SPELLING**, in its own message, and
  only where the entry arm already refused it. Sending it to `.pkgmeta` contradicted the same run's
  disclosure, which says truthfully that the entry suppressed nothing. It stays red — git writes
  forward slashes, no leading `./`, no trailing `/`, and is case-sensitive — while a stale entry
  `.pkgmeta` does cover stays stale rather than silent, and not a failure.
- **The narrowing now says what it suppressed, in one line covering both channels, and names the
  files.** A third case passes with every declared path, the list each one came from, the file
  count **and the suppressed paths grouped under the entry that suppressed each** — `suppressed 3
  of 148 tracked authored file(s), by: docs/spell-research/ [skipDirs in tests/prose_waivers.lua]
  (3): docs/spell-research/2026-09-20/ANALYSIS.md, ...`. The count on its own was what made a
  `.pkgmeta`-blessed entry over a shipped file read as ratified rather than as suspicious: nothing
  tied the number to a file. The list is **bounded and says so** — past twelve paths every entry
  falls back to its count and three examples, `and 25 more (list bounded)` — because Pretty Chat's
  carve-out alone suppresses 28 files and a truncated list read as a complete one is worse than a
  count. Its body re-measures the live lists and compares them against the reading taken at load,
  so a suite or a waiver file that changes between the two is caught rather than obeyed. The three
  cases register wherever a repository declared a narrowing of **either** kind; keyed on the
  carve-out alone, the one repository in this collection that narrows the gate only through the
  waiver file registered none of them. **A narrowing that arrives after load finds none of them
  armed, so the gate refuses it itself**: a repository that declared nothing at load and then had a
  later suite write `Kit.prose.exempt` hid a shipped file behind a green gate, with no refusal and
  no disclosure registered to notice. The gate now fails with *a narrowing was declared after this
  suite loaded*.
- **`waived` is validated for shape, which it never was.** It is the third key in the same table:
  a `waived` that was not a table died inside the scan with a raw Lua error instead of the gate's
  own message, and either array form — `waived = { "core/Foo.lua" }`, or a file's words written as
  an array — waived **nothing** and said nothing, because the scan looks both up by key. That is
  the silence just removed from `skipFiles`, left standing one key over. Keys must be strings,
  values tables, words string keys. `waived` stays **outside** the two refusals deliberately: it is
  per file **and** per word, so it cannot hide a spelling it did not name, which is why both
  refusals point at it as the way out. Only its shape is policed.

**Where a repository has no `.toc`, the TOC condition degrades out loud rather than disappearing** —
it `skip`s with the reason printed, because a repo that packages no addon has no TOC for LOADED BY
NOTHING to be read off. Same for `.pkgmeta` where nothing is packaged. **But a `.toc` with no
`.pkgmeta` is refused**, because the packager then ships the working tree whole. The gate reads each
TOC's own lines and follows nothing further: an `.xml` line pulls in a tree of `.lua` the TOC never
names, and a `dofile` inside a loaded file pulls in more.

**The third condition stays the auditor's, and the reason is stated rather than assumed**: nothing
in the repository root records whether a script or a person wrote the lines. GENERATED RATHER THAN
AUTHORED is not gated, here or in `layout-§1`'s cap gate, and a repository that names a hand-written
file in either exempt set has fooled the gate and will be caught by a reader.

Without it this gate fails the one repository that had already done everything the rule asked.
Pretty Chat's own hand-written copy named that folder in its skip list and was green; retiring that
copy for the shipped one, which `testing-§9` requires, takes it red on **34 lines, all 34 of them
under that folder** — 17 in the dump itself and 17 across nine of its chunk files, so a carve-out
naming only the large file would leave exactly half the red standing. With the folder named, it
passes. A repository must not lose a gate it had by adopting the shipped one.

This is not a whole-file waiver by the back door, and the old docstring was holding that door open:
its `skipDirs` example was literally `GlobalStrings/`. `skipDirs` and `skipFiles` extend
`localization-§5`'s own **named exclusion** list and nothing wider; generated data goes in the
runner, beside `Kit.layoutCap.exempt` naming the same folder for the same three reasons, so one fact
about the repository is recorded once. What the two channels now share is the two refusals and the
one disclosure, because what a reader *means* by an entry does not change what it *does* to the
scan. One consequence, stated rather than left to be discovered in a red run: a **British locale
file cannot be excluded by `skipFiles`**, because a locale file is TOC-loaded and shipped, so both
refusals reject it — `locales/enGB.lua` is excluded by name in the kit's copy of `localization-§5`'s
published list, which is where a differently-named one belongs too.

An authored file somebody would rather not fix still belongs in `tests/prose_waivers.lua`'s
`waived` table, per file **and** per word, with the reason beside it. `waived` is the one list the
two refusals do not police, because a waiver that has to name the word cannot hide a spelling it did
not name — which is why it, and not `skipFiles`, is what a refusal now points at.

**This is a documented deviation until the standard says otherwise.** `localization-§5` publishes
four exclusions, each MUST-named in the gate rather than inferred from a pattern, and lists a
generated dump of the client's own strings among the *waivable* shapes rather than the exempt ones.
A per-word waiver over 27 files is a whole-file waiver with extra typing, and `layout-§1` took
exactly this amendment one revision earlier — but until §5 takes it too, `Kit.prose.exempt` is
flagged here rather than treated as settled by the code that implements it.

### `test_eol.lua` — a second case, over the `.gitattributes` body

`line-endings-§5` publishes two canonical bodies and `§7` now asks that a repo be **diffed** against
the right one rather than read against it. It is a second case in the suite that already owns the
question rather than a second suite, because two gates over one rule is two lists to keep whole.
The case checks the file is present and tracked, that the pin is the one `§2` gives this repo kind,
that `§3`'s carve-outs and `§4`'s binary marks are there, and that the body matches line for line
through its final line and terminator — then grades any `§5` appendix below it against `§5`'s own
five rules. The repo kind is decided by `§2`'s mechanical discriminator, never by a roster: the
directory a checkout sits under is the one fact a gate cannot read.

Both bodies are **84 and 85 lines**, counted off `§5`'s fenced blocks rather than copied from prose.
The standard carried 81/82 until v2.63.0, and a body short by three lines would have reported three
phantom differences against a correct file, in every repository, forever.

**This repository failed its own new case, and the fix is in this release.** `LibKa0s/.gitattributes`
was 82 lines against a required 84: it carried the pre-v2.61.0 six-line shell-scripts comment where
`§5` now has the eight-line shebang comment, the widening that brought `*.py` under the same rule.
Twelve of the collection's fourteen `.gitattributes` are missing `*.py text eol=lf` entirely; only
Aura Master and this repo carry it, and this repo was carrying it under the wrong comment.

### The automated-test runner names the commit every row measured

`automated-tests-§4` requires each `RESULTS.md` row to carry the commit the run measured and whether
the tree was clean at it. Two generated cells arrive: `Commit`, the short sha, and `Tree`, `clean`
or `**dirty**` — both read from git, neither typed, `unknown` where there is no git to ask. The
watch list's `Disposition` remains the one authored cell in the file.

The table widens **once**. The revision-24 header is recognized and spliced; a header the runner
does not recognize is still left alone with a warning. Every row written before the runner emitted
these cells is carried forward with both cells `unknown` — not `clean`, and not reconstructed from
git archaeology, because a row that names a commit it never measured is worse than a row that admits
it does not know. **189 existing rows widen this way across the collection**: 73 here,
ConsumableMaster 13, Panel Master 12, WhatGroup 12, AbsorbTracker / BankLedger / KickCD /
LootHistory / Pretty Chat 11 each, MultiMeters 9, PartyFrameEnhanced 9, Aura Master 6. All twelve
carry the byte-identical revision-24 header, so one predecessor is enough.

The console also prints one `record:` line per run, saying whether the newest bundle was measured at
HEAD, how many commits behind it is, that it is not an ancestor of HEAD, or that it predates this
revision. It reports and stops there — it never touches the verdict or the exit code, because
`automated-tests-§3` forbids failing a run on a result of that kind. The manifest half needed
nothing: revision 24 already emitted `"git": { "sha", "branch", "dirty" }` on 73 of 73 bundles here.

Why the columns exist at all is in the record: of this repository's **73** bundles, **29** record a
dirty tree, and **28 of those 29 are release bundles** — `20260903-161751` stamps
`"release": "1.25.0"` at sha `895cdf4` on a tree that cannot be checked out. Every one of them reads,
to a trend line, exactly like a reproducible run.

### What this repository owed itself, and paid

The library consumes its own kit through `tests/_kit/` on exactly the terms every addon does, so
every obligation above landed here first.

- **The hand-written cap gate is deleted.** `tests/test_layout_cap.lua` (206 lines) is gone and
  `{ name = "test_layout_cap", dir = "tests/_kit/" }` is wired in its place, with
  `Kit.layoutCap = { hub = "CLAUDE.md" }` beside `Kit.run`. Keeping both would have been the
  collision the new inventory reports, and the bare form would have wired the local file over the
  kit's.
- **The census moved one level.** `Files over the 1500-line cap` was a sibling `##` of
  `## Documented deviations` in the root `CLAUDE.md`; `layout-§1` fixes the parent in both hosts, so
  it is now a `###` nested under the register. Re-measured today at revision 25, the census is
  **three** files: `tests/test_options_widgets.lua` at 4086 and `LibKa0s/OptionsWidgets.lua` at
  3922, both carrying open issues that name the seam, and a new row for **`testkit/framework.lua` at
  1571**. That third row is this revision's own doing: `resolveDir` and `adviceDir` took the file
  from 1227 at v1.53.0 past the cap, and a comment-free implementation of the two fixes still lands
  around 1512, so the breach is the change and not its prose. It is ratified rather than filed as an
  issue, on the argument that deferring the fix to a peel would leave two repositories unable to run
  their tests at all, while peeling in the same change would move 584 lines of the suite inventory
  into a new vendored file in the same revision that changes how it behaves — the one thing a
  whole-folder vendored payload should not do to eleven consumers at once. The seam is named in the
  row (the `suite loading` band, `fileExists` through `Kit.assertSuiteInventory`, out to a
  `testkit/inventory.lua`) and the trigger is the next revision that touches the inventory.
  `testkit/framework.lua` therefore leaves the 1000–1500 band note it had just been added to. The
  note first said that left eight files, which was wrong: the same revision took
  `testkit/test_prose.lua` from 335 lines to 1499, one under the cap, and the Schema major's
  `tests/test_schema.lua` arrived at 1101. The band is **ten** files at v1.55.0, re-measured with
  `git ls-files '*.lua' | grep -v '^tests/_kit/' | xargs wc -l | sort -rn`.
- **The prose gate is declined, on the record.** This repo is one of the six, and the row is now in
  the register keyed `localization-§5` naming `tests/_kit/test_prose.lua`. The reason is measured
  rather than asserted: the kit's copy reports **1121 lines across 147 files** here, and **twelve
  of them are in the shipped payload outside the gate's own source — all twelve already ratified
  by the two rows above it**. The other 1109 are records this repo must not rewrite or does not
  write at all: 560 in `docs/api/`'s frozen per-version documents, 150 under `tests/`, 118 under `docs/adoption/`, 107
  under `docs/superpowers/`, 63 in `CHANGELOG.md`'s entries, 46 in the generated
  `docs/test-cases.md`, 21 in `docs/adoption-prompt.md`, and 23 in `testkit/test_prose.lua` itself, which quotes every forbidden
  spelling in order to forbid it and gained six more with this revision's fixture. Against that,
  this repo's own copy carries two cases the kit's has no equivalent for — no non-ASCII byte
  reaches a player, and no retired `§N.M` section reference survives — over the one payload eleven
  consumers receive by copy and cannot fix for themselves. The row carries the trigger that ends it.
- **The ASCII gate learned about long-bracket strings.** `tests/test_prose.lua` justified not
  modeling them on the premise that the shipped payload had exactly one; revision 25 falsified it,
  because `testkit/test_eol.lua` now carries `§5`'s two canonical bodies verbatim, section signs and
  all. The exemption is the ASCII gate alone — a transcript of somebody else's document is the one
  string this repo is forbidden to re-spell — and the British-spelling and `§N.M` gates go on
  reading those lines.

### Adoption

Both payloads, whole-folder as always. The library copy brings the three new majors' files and their
`LibKa0s.xml` rows; adopting any of the three majors is a separate, per-host change (see *Three new
majors*, above).

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
cp -r testkit/. <Addon>/tests/_kit/
git -C <Addon> update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

Then, in the consuming `tests/run.lua`: add `{ name = "test_layout_cap", dir = "tests/_kit/" }`,
delete any local `tests/test_layout_cap.lua` and the bare string that wired it, set `Kit.layoutCap`
if the hub is not `docs/ARCHITECTURE.md` or the repo has generated data, and resolve the prose
gate — the kit-directory entry with the local file deleted, or the register row that declines it.
A local prose copy being retired that named a generated folder in its own skip list moves that
folder to `Kit.prose = { exempt = { ... } }` in the same change.
Nothing is owed for `test_eol`'s second case or for the runner's two cells. Collection-wide, the cap
gate lands green today in MultiMeters as-is and in Pretty Chat with one `exempt` entry;
ConsumableMaster owes its census's move under its register, Panel Master owes the rename off its
band heading, and the seven addons with no census owe the heading itself, with "Nothing is over the
cap today" where nothing breaches.

Every consumer whose `docs/test-cases.md` carries a declined kit gate regenerates that file in the
same change: the decline's case name moved from the resolved path to the root-relative
`tests/_kit/<suite>.lua`. No consumer runner needs editing for the path fix — the mixed spellings in
KickCD's and MultiMeters' lists are correct as written and are now read as correct.

### Three rounds of consumer-tree driving, and why the count is in the record

**This kit was green in its own repository and wrong in consumer trees twice before it shipped.**
Writing that down is the point of this heading, because the pattern is structural rather than
careless. LibKa0s is an unrepresentative consumer of its own kit: it declines the prose gate, it
spells its suite directories one way on both sides, and it has no `.toc` and no `libs/`. A case that
passes here therefore proves very little about the eleven trees the folder is copied into.

- **Round one.** The pair key compared two spellings of one directory as raw strings. Green here;
  fatal in two repositories that had done exactly what `testing-§9` asks.
- **Round two.** Two fixes, both invisible at home. The suite-list spellings folded together under
  this repo's own single-spelling runner and only came apart when a suite was invoked by path from
  another working directory. And the prose gate's own self-test read the LIVE carve-out instead of a
  fixture, which is permanently green here — this repository sets no `Kit.prose` — and permanently
  red in the one repository the carve-out exists for.
- **Round three, this one.** Every assertion added in this revision is driven off a fixture the case
  builds, never off the live runner's state, and the result was driven in throwaway copies of four
  real consumers before it was called done: **PrettyChat** (the legitimate carve-out) at 417 passed
  / 1 failed / 2 skipped of 420, with all twelve prose cases green and the disclosure reading
  `suppressed 28 of 95 tracked authored file(s), by: GlobalStrings/`; **WhatGroup** (the abuse case)
  with both new refusals red and naming `core/WhatGroup.lua (loads core/WhatGroup.lua, line 48 of
  WhatGroup.toc)`; and **KickCD** (1027 cases) and **MultiMeters** (1926 cases), each driven BY PATH
  from a foreign working directory, where the inventory previously aborted before a single case ran.

The lesson is written into the kit's own headers rather than left here: a gate whose self-test reads
the live runner's state is a gate that tests the repository it is standing in, not the gate.

The green gate here: **1484 passed, 0 failed, 1 skipped, 1485 total**, `luacheck` **0 warnings /
0 errors in 81 files**, and `lizard` **0 functions above CCN 15**. The kit revision alone measured
1318 passed of 1319 in 74 files; the three new majors add 147 cases (49 Compat, 27 Bus, 71 Schema)
and six files. The release run first found four functions above CCN 15, all new in this release
(Schema's `Set` and `Validate`, the kit's `collectKitHoles` and `repoKind`). Each was split with
its behavior pinned first: 9 of the Schema cases, 7 more inventory cases and the new
`tests/test_kit_eol.lua` (12) are those pins. Differential runs of the old code against the new
found no difference. The one skip is the prose
decline, which is the point of it — and it is also why the prose gate's seven self-tests and its
three carve-out cases run in the consumers that wire the kit's copy and in none of this repository's
1485: a suite this library declines is a suite it cannot exercise.

## v1.54.2 — 2026-09-22

Versions in this release: **test kit revision 24**, unchanged. `test_prose.lua` stops scanning
`tests/prose_waivers.lua`.

The waiver file is the fourth exclusion too, and for the same reason the gate itself is: it exists
to NAME forbidden spellings, and every reason written beside a waiver is prose about one. A gate
that scans it reddens on the file whose whole job is to record what it must not correct, and the
only way out would be to write those reasons without naming the word — which is the one place
naming it is the point. Panel Master hit it on the first adoption: its waiver for a third-party art
pack's texture path could not explain itself without spelling the path.

## v1.54.1 — 2026-09-22

Versions in this release: **test kit revision 24**, unchanged from v1.54.0. One byte comes out of
`testkit/README.md`, and it is a byte that made the whole kit un-vendorable.

**A single bare CR turned the file binary in git's eyes.** v1.54.0's README edit was generated by a
script that wrapped its new section as `NL + text` and then ran `.replace("\n", NL)` over the
result — which rewrote the `\n` of that leading `\r\n` as well, leaving `\r\r\n` at byte 7973.
Git's `text=auto` refuses to normalize a file containing a bare CR (`convert.c`: *"if we have any
bare CR characters, we're not going to touch it"*), so it classified the README as **binary** and
stored the working tree's CRLF verbatim in the blob. Every other kit file's blob is LF.

**Nothing in this repository could see it.** `test_eol.lua` holds the WORKING TREE to the
terminator `.gitattributes` declares, and the working tree was correctly CRLF; the index is the one
side it does not read. `git status` was clean in both directions, exactly as the eol gate's own
header warns. It surfaced only in the consumers, where `tests/test_vendor_sync.lua` strips CR from
the vendored copy and compares against the blob — 11 repositories failed that case on the v1.54.0
re-vendor, each reporting the kit README as edited in place when nobody had touched it.

The byte is gone, `git ls-files --eol` reports `i/lf w/crlf` for both copies, and the blob is LF.
**Re-vendor from this tag, not v1.54.0.**

## v1.54.0 — 2026-09-22

Versions in this release: **test kit revision 24**. **No library file changes at all** — every
major's version key is exactly v1.53.0's, `LibKa0s-Options-1.0` included, so a consumer that
re-vendors takes new bytes in `tests/_kit/` and identical bytes in `libs/LibKa0s/`.

**The kit ships the US-English gate** (`test_prose.lua`), beside `test_eol.lua` and on the same
contract: it takes the kit as its chunk argument, because the exposed table's global name belongs to
the consumer and a vendored suite cannot know which one it is standing in.

It is here because the rule had one definition and eleven implementations. `localization-5` has
published the `BRITISH` and `ALLOWED` lists for months and required a gate to carry them **whole**;
by the time this shipped, **seven** repositories had written that gate by hand under **three**
different filenames — `test_prose.lua`, `test_spelling.lua`, and folded into `test_docs.lua` — so
nothing could tell at a glance which repositories had a gate at all, and **four more had none**,
their drift found only by a sweep somebody happened to run. Eleven hand-written copies are eleven
chances to carry a subset, and a subset is a gate whose green means nothing.

**Adoption is one line and it is not automatic.** `Kit.assertSuiteInventory` scans `tests/_kit/`, so
a re-vendor that lands the file in a repo which has not declared it goes **red** naming the entry to
add — the same bargain `test_eol.lua` struck. Note that the check compares **names**: a repo already
declaring a `test_prose` of its own satisfies it and keeps running that one, which is the
"wire one or the other, never both" outcome reached by coincidence.

**Waivers, and the standard's new clause.** Some British spellings in a Ka0s tree are not the
repository's English to correct — AceTimer's cancellation flag, whose name the kit's own live-timer
survey reads off a handle; a Blizzard status string matched verbatim off its event; a generated dump
of the client's own strings. Five repositories had each invented a mechanism for this, which is the
signal the rule was owed. `localization-5` v2.62.0 now carries it as a MAY under three MUSTs, and
the kit reads waivers from an optional `tests/prose_waivers.lua`; a file that exists but does not
return a table is a **failure**, not an empty one, because the alternative silently widens the gate.

The shipped payload does not waive — it declines to quote. The kit gate and the kit README describe
the forbidden spellings rather than spelling them, because those bytes reach every consumer and no
consumer can fix them. The one exemption in this repo's own gate is the kit gate's copy of the
`BRITISH` list, which `localization-5` names as the fourth of its four exclusions.

Release gate (`docs/automated-tests/20260922-202214/`): lint 0/0 in 73 files, 1277 tests 0 failed,
complexity 0 over CCN 15. Perf SKIPPED, not measured — no `tests/perf.lua` — so the gate covered
three suites, not four.

## v1.53.0 — 2026-09-22

Versions in this release: **OptionsWidgets minor 30** (`LibKa0s-Options-1.0` 23.30.3.7.3). Every
other file is unchanged from v1.52.0 and the kit stays at revision 23. The member manifest is
identical to minor 29's apart from the minor and the version key: **no new member, no new field,
and nothing for a host to adopt.**

**`O.IdInput`'s Add button is the height of the box it sits beside.** The owner reported it sitting
*"slightly higher"*. It was not higher. The two were already centered on each other and always had
been: AceGUI's labeled `EditBox` publishes `self.alignoffset = 30` and Flow anchors the next widget
by `frameoffset - lastframeoffset`, which puts their middles on one line. Measured off the
screenshot — box 20px tall centered at y 43, button 24px centered at y 42 — they were **one pixel
apart and four pixels different in height**.

So it was the height. `InputBoxTemplate` draws its border art **20** tall and AceGUI's `Button` is a
flat `SetHeight(24)`, so a centered 24 against a 20 overhangs 2px at each end — and the overhangs do
not read alike, because the top one sits against the row's gold caption and the bottom against empty
dark. That asymmetry is what reads as *higher*. The button is now set to 20, which is Blizzard's own
number for that art rather than a tuned one; the centering stays AceGUI's.

Every consumer of `O.IdInput` gets this by re-vendoring — Aura Master, ConsumableMaster and KickCD
all draw one.

## v1.52.0 — 2026-09-22

Versions in this release: **OptionsWidgets minor 29** (`LibKa0s-Options-1.0` 23.29.3.7.3). Every
other file is unchanged from v1.51.0 and the kit stays at revision 23. The member manifest is
identical to minor 28's apart from the minor and the version key.

**A REGRESSION FIX, and it was this library's.** v1.51.0 reserved `0.05` of an id-list row for a
help mark whose frame is ABSOLUTE, making the two-column floor `2 × 18 ÷ 0.05` = **720px of
content** — past what a settings canvas hands a page. So `columns`' fit correctly dropped **every
list that adopted `help` to one column**, and a host that took the option silently lost its second
column. The suite could not see it: the bench draws into 1000px, which pays for 720.

The reserve is now **0.09**, derived as the smallest hundredth at which the mark's own floor stops
binding before the label floor the row already pays. Adopting `help` still lifts an icon-style
two-column list's floor from **520px to 561px** — the label floor rising as the name gives up its
share, unavoidable, and under the 584px the library already calls comfortable. **A helped
default-style list at two columns wants ~665px and will fall back to one column on a normal canvas;
a host that wants help and two columns should draw the X.**

**The glyph is the library's own** `media/icons/info.tga` at **14px of art in a 24px frame**, where
v1.51.0 used the client's `InformationIcon` at 8px — which reads as half-drawn beside the two 16px
textures an entry already carries. Reaching it crosses a major boundary, so the **Options descriptor
takes an optional `addonName`**, resolved at call time through `LibStub("LibKa0s-Media-1.0", true)`
— the same shape `Core.MakeCloseButton` and DebugLog use. Nothing is copied across the seam, so
Options stays vendorable without Media, and **without it the mark falls back to the client's glyph
at the new size**. `spec.helpIcon` still wins.

**A severity the host declares**, as a `level` field on the table carrying the help lines —
`entry.help = { level = "blocked", "…" }`. `"blocked"` tints the mark red, `"info"` leaves it the
resting gold, and an entry with nothing to say keeps the dimmed mark and no tooltip. The library
reads the lines as opaque strings and cannot know which means what. An unknown level reads as
`"info"`. It rides the lines rather than a second field beside them, so a host builds an entry's
lines and its severity in one place and neither can go stale against the other. **Backward
compatible**: an entry passing a plain string or list, as v1.51.0 documented, draws exactly as it
did — the table carries no `level`, which reads as `"info"`.

Verified against lint, tests and complexity. This library ships no `tests/perf.lua`, so the perf
suite was skipped rather than measured — the release gate covered three suites, not four.

## v1.51.0 — 2026-09-22

Versions in this release: **OptionsWidgets minor 28** (`LibKa0s-Options-1.0` 23.28.3.7.3). Every
other file is unchanged from v1.50.0 and the kit stays at revision 23.

Three new optional spec fields on `O.IdList`, and one behaviour change that needs no adoption. The
member manifest is identical to minor 27's apart from the minor and the version key.

- **`entry.help` — a "?" between the delete control and the name.** A string, or a list of them,
  shown as a tooltip titled with the entry's own name. The alternative already here is `note`, a
  full-width second line — and a second line cannot share a Flow row, so a noted entry takes a row
  of its own and punches a hole in a multi-column grid. A host with something to say about MANY
  entries had to choose between saying it and keeping its columns.
  **Asked once per LIST, not per entry**: a list where nothing carries `help` draws no marks,
  claims no width, and is byte-identical to minor 27. A list that uses it gives EVERY entry a mark,
  because a column that appears and disappears down the list is not a column — an entry with
  nothing to say wears a dimmed one and registers no hover, so it cannot answer with a blank
  tooltip. `spec.helpIcon` picks the art.
- **Every row lights under the cursor now**, not only above one column — **automatic, nothing to
  adopt**. The old rule reasoned a one-column tooltip already hangs off the name; but the lit name
  is also the feedback saying which row the cursor is on, and it left a NOTED entry, drawn at one
  column inside a two-column list, as the only unlit row on the page.
- **`kind.suggestTag(id)` — a host's word on a suggestion row**, after the gray id. `rank` beside
  it is the library's own answer about an id and a host cannot supply one; this is the other half.
  The case it was written for: an id can be a spell's CAST rather than the aura it applies, which
  matches nothing, and the host knew before the player picked the row and could only say so after.
  A tag turns a correction into a choice.

The mark's geometry is the drag handle's — 8px of art in an 18px frame, the same gold and the same
brighten — restated in `OptionsWidgets.lua` rather than read across, because `lib.DRAG_HANDLE` is
the Widgets major's and this is the Options major's. The column floor covers its frame, which is
absolute like the X's.

Verified against lint, tests and complexity. This library ships no `tests/perf.lua`, so the perf
suite was skipped rather than measured — the release gate covered three suites, not four.

## v1.50.0 — 2026-09-21

Versions in this release: **OptionsWidgets minor 27** (`LibKa0s-Options-1.0` 23.27.3.7.3). Every
other file is unchanged from v1.49.1 and the kit stays at revision 23.

Four `O.IdList` follow-ups from the v1.47.0 reviews (issue #34). **Nothing here is a surface
change**: `docs/api/Options/members-23.27.3.7.3.json` is identical to minor 26's apart from the
minor and the version key, and no host has anything to adopt.

- **The X lights the whole of its hit area, not just the art inside it.** In `removeStyle = "icon"`
  the delete control's frame is 26px around 16px of art, but AceGUI's Icon anchors its highlight to
  the IMAGE while the FRAME is what takes the click — so the 5px ring the list deliberately buys was
  live and unlit, on a control that deletes the row. A click on what read as the gap between the X
  and the entry's own icon removed an entry with nothing having lit up first. The highlight now
  tracks the frame, and goes back onto the image when AceGUI pools the widget.
- **`columns` is now a maximum, not a promise.** The X's frame is absolute, so the icon style spends
  52px of every row before a relative width is multiplied out; below roughly 520px of content
  AceGUI's Flow broke the trailing gutter onto a row of its own, leaving icons stacked over wrapped
  names with nothing reporting it. The draw measures the content width and drops a column at a time
  until the count is payable — a narrower list is a correct list, a broken grid is not. **A width
  that cannot be measured changes nothing**, so a list whose canvas answers no geometry draws the
  count it was given, exactly as before. Measured once, at draw time: a canvas dragged narrower
  afterwards is not re-fitted, because nothing re-runs the page builder on a resize.
- **An entry label's markers no longer ride into the AceGUI pool.** `__wordWrap` and `__highlight`
  are keys this library invents, and `AceGUI:Release` nils only a fixed list of its own fields, so
  both survived to be read by the next consumer of that pooled label. They are cleared on release
  now, from the single `OnRelease` that also hands the FontString back — single because
  `SetCallback` stores one handler per event name, so a second registration replaces the first
  rather than chaining with it.
- **Two comments stopped quoting a pixel figure the file itself calls unknowable.** The fraction
  minor 23 gave the delete control was "about 41" px only at some content width, and the paragraph
  under `ID_COLUMNS_MAX` says that width is not knowable here and is measured nowhere in this repo.

The fifth finding — the multi-column tooltip anchoring off the list's right edge whatever column the
cursor is in — is closed as **no change**, with the reasoning recorded at `entryTooltip`: anchoring
under the hovered label buys the sibling column and pays for it with every row below the cursor, and
the debug window already shipped that and took it back.

Verified against lint, tests and complexity. This library ships no `tests/perf.lua`, so the perf
suite was skipped rather than measured — the release gate covered three suites, not four.

## v1.49.1 — 2026-09-21

Versions in this release: **OptionsWidgets minor 26** (`LibKa0s-Options-1.0` 23.26.3.7.3). Every
other file is unchanged from v1.49.0 and the kit stays at revision 23.

**A host kind that names a base gets that base's suggestions back.** `O.IdList` builds an entry's
tooltip from the kind and nothing else, so a host that wants its own entry tooltip has to pass its
own kind table; it says `base = "spell"` so resolution, the drawn name and the words still come from
the library's spell kind. Through minor 25 the suggestion table was keyed by the library's kind
TABLE, a host table is a different table, and so the add box under such a list suggested nothing as
the player typed — the spellbook was no longer a source, and only what the host passed as
`candidates` could be offered. A tooltip cost a capability, which is not a trade a library should
impose. A based kind now reads its base's row.

- **What comes with the base**: its client source — the bags for `base = "item"`, the Spell and
  FutureSpell slots of the spellbook for `base = "spell"` — listed after the host's own
  `candidates()` exactly as the base lists them, and read by the shared-name check, so a name two
  spellbook spells share is refused as `"ambiguous"` through a based kind as it is through the base.
  The base's rank label already came with it; it is now read through the same single lookup as the
  source, so the two cannot disagree about which row a kind wears.
- **How a host opts out: by not declaring a `base`.** A host kind with no base still matches nothing
  in that table and behaves exactly as it did, which is the protection the old keying wanted — such
  a kind's ids need not be the client's at all, and a list of currency or encounter ids must never be
  offered the spellbook. There is no third setting: declaring a base opts in, leaving it out opts out.
- **What still does not come with the base: `byName`.** A typed name reaches the host's `resolve` and
  its `candidates()`, never `C_Spell.GetSpellInfo(name)` or `C_Item.GetItemInfoInstant(name)`. What a
  host kind RESOLVES is as much its own as it ever was; only what it is OFFERED changed.
- Resolution is unchanged for every kind, and a list whose kind declares no base renders and resolves
  byte-for-byte what minor 25 rendered and resolved.

## v1.49.0 — 2026-09-21

Versions in this release: **OptionsWidgets minor 25** (`LibKa0s-Options-1.0` 23.25.3.7.3). Every
other file is unchanged from v1.48.1 and the kit stays at revision 23.

**An `O.IdList` entry can say a few words on its own row now.** An entry may carry
`suffix = "<string>"`, drawn INSIDE its label after the gray `(id)` and in that same gray:

```
(X) [icon] Renewing Mist (119611) (also in 1)
```

The field exists because `entry.note` (W17) is the wrong shape for a short aside. A note is a
SECOND full-width `Label` under the name, and under `columns` a noted entry gives up its place in a
shared row and takes a full-width one — so a three-word remark costs a line and half a row. A
suffix is bytes appended to the `FontString` the name and the id already share: it adds no widget,
so two suffixed entries still pair up at the same `0.37` each. `note` is unchanged and is still the
answer for a sentence; reach for `suffix` for a count, a tag, a pointer.

- **The full story belongs in the entry's tooltip**, which the host already owns. A suffix says
  *that* there is more, not what.
- **The truncation order is the cost, and it is documented rather than discovered.** At more than
  one column word wrap is off (W24) and the client cuts the tail, so an entry that already overruns
  loses its suffix first, then its id, then its own name. That is the right order — the suffix is
  the least of the three — but a host has to be able to size a suffix against the room, so the API
  document carries the pixel budget per style and column count and the rule of thumb that turns it
  into characters: about 44 for the whole label at two columns at the `584px` content the column cap
  is chosen against.
- **Concatenated, never formatted**, which is the guarantee `note` already gives. The suffix is
  never a `string.format` argument and never a `gsub` replacement, so a `%`, a `%%` or a `%(` is
  drawn as the byte the host wrote; a `|c` is not stripped either, so a host that colors its own
  suffix gets that color.
- **Anything that is not a non-empty string draws nothing.** A list whose entries carry no `suffix`
  renders byte-for-byte what minor 24 rendered.

## v1.48.1 — 2026-09-21

Versions in this release: **WidgetsDragHandle minor 2** (`LibKa0s-Widgets-1.0` 9.2). Every other
file is unchanged from v1.48.0 and the kit stays at revision 23.

**A help mark only brightens where a click does something.** `dhBuildHelp` tinted the mark to full
white on `OnEnter` unconditionally, while `dhSetClick` registers no click at all for a host that
passes no `onRightClick`. On ConsumableMaster — the one host that passes none — the mark lit up
under the cursor and then did nothing, which is a control advertising itself and then declining.
The over-tint is now chosen from `spec.onRightClick`: a host with a click still gets the full-white
response, and a host without one gets a mark that stays at its resting gray and reads as the label
it is.

Found by the adoption review, after v1.48.0 was tagged and both hosts had already vendored it —
which is why this is a patch rather than an amendment to that tag.

## v1.48.0 — 2026-09-21

Versions in this release: **WidgetsDragHandle minor 1**, a new file (`LibKa0s-Widgets-1.0` 9.1).
`Widgets.lua` stays at minor 9, every other file is unchanged from v1.47.0, and the kit stays at
revision 23.

**The unlocked drag handle is a widget now.** `lib.DragHandle(parent, spec)` builds the labeled
strip a player drags a movable frame by — a dark fill, a 1px gold edge, a centered gold
`GameFontNormalSmall` label and a help mark in its far end. AuraMaster drew one per container and
ConsumableMaster drew one over its macro bar, and the two were the same widget twice: the same 18px
strip, the same 2px gap, the same 24px of padding, the same help `Button` at `RIGHT, -4` over the
same Blizzard fallback texture, and the same `label + PAD + HELP * 2` width. That is the argument
the dropdown was lifted under and the argument `lib.ROW_BOX` was published under one layer down.

- **The help mark's art is 8px rather than 14, and it matches the chevron in INK rather than in
  BOX.** The precedent is the dropdown's chevron, `arrow:SetSize(12, 12)` at the same `RIGHT, -4`
  inset (`LibKa0s/Widgets.lua:331-333`) — but a box is not a weight. The chevron's art inks 44 of
  its 64 rows, so a 12px box of it draws 8.25px of mark; this mark's art inks all 64 and the
  Blizzard fallback is a filled disc, so a 12px box of it draws 12. Against the small label face's
  cap height (FRIZQT\_\_ at 10px, a cap of roughly 7px) that is about 1.7x the text it annotates,
  where the chevron is about 1.1x. 8 is the chevron's ink, and it is a floor: below it the "?"
  loses the gap between its hook and its dot. A draft computed the size from the label's font height
  and was described as growing with a larger face — untrue, since the cap equalled the default, and
  it rested on an unevidenced, locale-dependent claim about `GameFontNormalSmall`. Nothing reads a
  font.
- **The mark wears the chevron's own tint and brightens under the cursor.** Both copies drew it at
  full white, the brightest element on a strip whose label is gold `1, 0.82, 0` on a dark fill. The
  chevron carries `arrow:SetVertexColor(0.7, 0.7, 0.72)` (`LibKa0s/Widgets.lua:335`), set by the
  widget so that shared white art wears the widget's gray rather than its own; the mark takes the
  same tint from the same place, at alpha 1 — vertex color multiplies white art, where alpha would
  fade the mark toward the fill behind it. Unlike the chevron the mark is its own `Button`, so it
  goes full white on `OnEnter` and back on `OnLeave`.
- **The label is bounded, not only centered.** `LEFT` and `RIGHT` at `RESERVE` with word wrap off
  and one line, so a label longer than the strip truncates inside its own half instead of running
  under the mark and past the gold edge. Both copies anchored the label by a lone `CENTER` point,
  which has no width of its own and grows both ways: a host floor narrower than the text, a
  `SetLabel` with no `ApplyWidth` after it, or a client that cannot build a measurer all get there.
- **`HELP_GUTTER` is exact rather than floored.** The art is placed by `SetPoint("CENTER")`, which
  halves `HELP_HIT - HELP` whatever its parity, so a floored term in `RESERVE` would advertise a
  clearance the layout does not draw as soon as those two differ by an odd amount.
- **The mark's frame is 18px — the strip's full height — so the art shrank and the click target did
  not.** It is the only right-click affordance on AuraMaster's strip and it opens a settings page;
  12×12 was not a target to leave it with. `HELP_HIT` is the `Button`, `HELP` is the texture centered
  inside it, `HELP_GUTTER` is the 3px between them. Same shape `O.IdList`'s remove icon took at
  v1.47.0 — 16px of atlas inside a 26px frame.
- **The clearance between the label and the mark is 12px, where both copies spent 8.** That gap was
  the complaint, and shrinking the art alone did not move it: both copies reserved
  `PAD / 2 + HELP - HELP_INSET`, and with `HELP` on both sides of that expression 14 → 12 left the 8
  exactly where it was. `HELP_CLEAR` names it so it can be changed alone.
- **The reserve is spent twice in the width, so this is a layout change too.** `Measure()` is
  `labelWidth + RESERVE * 2` — once on the right for the inset, the frame and the clearance, once on
  the left as the matching gap that keeps the label optically centered. At 29 per side against the
  copies' 26, a strip's natural width grows by **6px**: invisible wherever the strip is floored by
  something wider, visible on a narrow one, which is where the crowding was.
  `handle:ApplyWidth(minWidth)` owns the arithmetic so a host can never restate it.
- **`lib.DRAG_HANDLE` publishes `HEIGHT`, `GAP`, `HELP`, `HELP_HIT`, `HELP_INSET` and `HELP_CLEAR`,
  with `HELP_GUTTER` and `RESERVE` computed from them**, on `lib.ROW_BOX`'s precedent: a host that
  copies the numbers back into its own constants file is the drift this removes. There is no `PAD`:
  the copies' `24` silently carried the clearance, the inset and half the mark, and splitting it is
  what made the clearance changeable on its own.
- **Every tooltip line may be a function, and it is called on every hover.** A `nil` return drops
  the line, and the blank spacer before the gray footer band is emitted from what survived the hover
  rather than from the descriptor. That is what lets ConsumableMaster's last line read off the live
  lock state and AuraMaster's "Attached — …" line appear only while the container is attached.
- **A line may also carry its own color, `{ entry, r, g, b }`, and one line needed it.** AuraMaster
  draws its conditional "Attached — …" line gold, in the body, with no blank line above it. Bands
  that were each one color would have recolored it white or pushed it into the gray footer behind a
  spacer. **Adoption changes no pixel of that tooltip.**
- **The strip and the help mark may carry different tooltips.** `spec.tooltip` is shown by both,
  which is AuraMaster's case and stays one field; `spec.helpTooltip` is a second descriptor the mark
  shows instead. ConsumableMaster titles its strip "Consumable Master" with a one-line body and its
  mark "Macro bar" with three body lines, a gray footer and a different anchor — a shape with one
  descriptor for both frames would have merged the two on adoption, silently, in the host this
  widget exists for.
- **`tooltipOwner` is a correctness knob and the spec requires it to be.** AuraMaster's anchor
  inherits `DisableUntrustedLayoutScriptsTemplate` and the restriction reaches every frame under it,
  so the client refuses `GameTooltip:SetOwner` on the strip or the mark; that host owns by `UIParent`
  at the cursor and ConsumableMaster owns by the frame hovered — `ANCHOR_TOP` off the strip,
  `ANCHOR_TOPRIGHT` off the mark. A widget that picked one would leave the other with no tooltip at
  all, and only in-game. "The frame hovered" is now literal: the strip owns by the strip, the mark by
  the mark, and `owner` / `anchor` may be set per descriptor as well as per spec.
- **The strip's drag scripts reach the mark**, so a left-drag that starts on the "?" moves the frame
  instead of landing in a dead zone. AuraMaster's copy did that; ConsumableMaster's did not.
- **A host that passes no `onRightClick` gets no click registration at all**, on either frame — an
  empty handler on a registered button swallows the click.
- **A plain `Button` with a fill and four 1px edge strips, never a `BackdropTemplate`.** Under an
  anchor attached to another frame the strip's size can read secret and `SetBackdrop` does
  arithmetic on it every set and every resize. ConsumableMaster's handle loses its backdrop on
  adoption: the pixels are the same, the hazard is not. `spec.name` keeps its global frame name.
- **The label is measured on a hidden, unanchored FontString of the widget's own**
  (`lib.__DragHandleMeasurer`), and every read goes through the host's `spec.number` guard.
  AuraMaster's label hangs off an anchor that inherits secret geometry, and reading its own width
  raised "attempt to perform arithmetic on a secret number value" out of combat.
- **`spec.labelFont` sets the face the label is drawn in and the face it is measured in, together.**
  A draft split them across a hardcoded face and a separate `measureFont`, so a host that set one
  measured a width the strip never drew — and a label measured narrower than it renders runs into
  the mark.
- **The constructor returns a hidden handle, and that is the file's one visibility call.** A strip is
  born with no width and no anchor point, so a handle that came back visible would flash a
  zero-width box at its parent's center until the host's first pass. Nothing shows it again.

**It ships as a second file in the Widgets major, not as more of `Widgets.lua` and not as a major of
its own.** Written into `Widgets.lua` the surface took that file to 1540 lines, over `layout-§1`'s
cap; `LibKa0s/WidgetsDragHandle.lua` is guarded with the same paired-minor idiom the Options family
uses (`lib.__dragMinor` against `lib.__dragShellMinor == lib.MINOR`). A major of its own would have
cost a `core/…Setup.lua` seam in all eleven consumers, nine of which will never draw a handle.
**A consumer's re-vendor therefore gains a file**: a copy that took only the files it already had
would leave `LibKa0s.xml` naming a file that is not on disk. Its thirty-four cases are in
`tests/test_widgets_draghandle.lua`, a suite of its own because `tests/test_widgets.lua` was seven
lines from the same cap.

## v1.47.0 — 2026-09-20

Versions in this release: **OptionsWidgets minor 24** (`LibKa0s-Options-1.0` 23.24.3.7.3). Every
other file is unchanged from v1.46.1, and the kit stays at revision 23.

**`O.IdList` draws in columns.** A new optional spec field, `columns`, packs that many entries into
each Flow row, filled row-major — `1 2` / `3 4` / `5 6` — into the same full-width row the
two-column flow engine has always packed a pair of widgets into. Default `1`, which is what every
list drew before and what every list that does not ask still draws, to the width.

- **The widths are divided, not redesigned.** Every relative width an entry claims is divided by the
  column count, so at two columns the name is `0.37`, the action `0.10` and the gutter after them
  `0.02`, the icon style's name is `0.43`, and each entry is `0.49` of the row — the pair sums to
  the same `0.98` one entry held alone, which is the clip inset `options-ui-§8` asks for. The X, the
  icon, the name and the gray id are laid out by the same code at every count, so they line up
  across columns too.
- **A gutter separates each entry from the next.** AceGUI's Flow butts its children edge to edge, so
  a gap has to be a widget; without one the default style reads `[name][Remove][name][Remove]` with
  the first Remove flush against the name it does not belong to. It is drawn at the end of every
  entry at more than one column and not at all at one, and it comes out of the entry's own share
  rather than out of the line, so each entry is still exactly `0.98 / cols`.
- **The icon style's X now takes an absolute frame WIDER than its art — 26px around 16px of atlas —
  at every column count.** Absolute, because a relative width is multiplied by the row at layout
  time and an AceGUI `Icon` anchors its texture TOP-centered rather than clipping it: a frame
  narrower than the art spills the art over its neighbor. Wider than the art, because the entry's
  own spell icon is 16px too, and a frame the size of its art left two adjacent 16x16 textures — one
  of which deletes the row — and a 16px click target where minor 23's fraction gave about 41px. At
  26 the `Icon`'s own geometry centers the art with 5px of padding on all four sides, so **the hit
  area is 26x26** and does not move with the column count. The name's reserve, `ID_REMOVE_REL`,
  moves from `0.06` to `0.08` so it still covers that frame at two columns. A single-column
  icon-style list therefore draws its X in a wider frame and its name at `0.90` rather than `0.92`,
  which is the visible part of this.
- **A tooltip in a multi-column list hangs off the ROW, not the entry label.** `GameTooltip` is still
  anchored `ANCHOR_RIGHT`; at one column the label's right edge is the list's right edge and the
  tooltip lands outside the list, but at two a column-one label's right edge is the middle of the
  list and the same anchor drops the tooltip over column two — over the entries the reader is on
  their way to. The row spans the full width at every count, so the rule is the same one applied to
  the widget that still reaches the edge. Single-column lists are anchored exactly as before.
- **An odd count leaves the last row half filled**, the trailing entry in the left column at a
  column's width, because nothing here is asked to fill a row.
- **A noted entry takes a full-width row of its own** at the one-column widths, and anything
  half-packed is flushed ahead of it. `entry.note` is a second line under the name, and a Flow row
  cannot hold that in one column and a neighbor beside it.
- **The per-entry guard still costs one entry.** It now also rolls the shared row back to the
  children it held before the failing entry started, so half an entry is never drawn beside a whole
  one; with nothing else in the row the row is dropped, as it was when an entry had the line to
  itself. The entries after a failure keep packing into the free column.
  A row abandoned by a failing FIRST entry is `Release`d rather than dropped: it was never added to
  the scroll, so nothing else would ever have handed it back to AceGUI's pool.
- **Out of range reads as usable**: floored and clamped into `1..2`, and a non-number reads as `1`.
  Two is arithmetic, measured against a width that is a conservative choice, and the constant's
  comment says which part is which. Two floors bind it. AceGUI's: a `Label` given an image moves the
  image on top, centered, with the name wrapped underneath, whenever the frame leaves it under 200px
  beside that image, so an entry's name needs `16 + 200 = 216px` of label. This library's: the X's
  frame is absolute, so the names must leave `26 * cols` behind. Both are measured against the
  **content** width, which is derivable here — `L.CONTENT_LEFT` and `L.CONTENT_RIGHT` (`12` and
  `28`, `LibKa0s/Options.lua:187-188`) off the panel and then `OptionsScroll.lua`'s `GUTTER` of `20`
  off that, so content is the panel less 60. Two columns want ~584px of content, ~644px of panel;
  three want ~876px and ~936px. The **panel's** width is not knowable at file scope and nothing in
  this repo measures it, so the cap is stated as a conservative choice rather than dressed in a
  measurement. The cap is flat rather than style-aware because `removeStyle` is the host's choice
  about a delete control, not a fact about the page's width.
- **At more than one column an entry name does not wrap.** Word wrap is turned off on the name's
  `FontString`, so every entry is exactly one line tall. It is not cosmetic: AceGUI's Flow centers a
  row's widgets on each other by `alignoffset`, so one name wrapping to two lines in column one
  pushes the name *and* the delete control in column two down with it — a broken grid rather than an
  uneven row, and "Holy Word: Chastise (200200)" is the kind of entry that reaches it. A name too
  long for its column is truncated by the client, and truncation cuts the **tail**: the tail is the
  gray `(id)` suffix, so a truncated entry shows part of the name and **no id**. Hover still names
  the spell or item. The `FontString` is put back on release, because AceGUI pools the widget across
  every addon in the session. **A single-column list wraps exactly as minor 23 did**, byte for
  byte; a host that would rather wrap than lose the id asks for one column.
- **At more than one column the hovered entry is lit.** The tooltip hangs off the whole row there,
  which can open it a long way from the name the cursor is on; `InteractiveLabel` ships a
  `HIGHLIGHT`-layer texture and draws nothing in it until a caller names one, so it now wears the
  same art the id suggestion lines use. Nothing to restore on release — its `OnAcquire` clears it.
  A single-column list lights nothing, as before.

`lines`, the table `O.IdList` returns, still has one element per entry drawn, in entry order. Where
entries share a row the same row object is returned once per entry in it, so `lines[i]` is still the
row carrying the i-th drawn entry. Cases: `tests/test_options_widgets.lua` (sixteen more).

## v1.46.1 — 2026-09-19

Versions in this release: **Options minor 23** and **OptionsTabs minor 3** (`LibKa0s-Options-1.0`
23.23.3.7.3). Every other file is unchanged from v1.46.0, and the kit stays at revision 23.

**The combat lock stops standing up with a stood-down addon.** v1.46.0 broke the stand-down suites
(`slash-commands-§7`) of seven consumers, for three reasons, all fixed here:

- **A permanent registration.** `lib.__combatFrame` registered `PLAYER_REGEN_DISABLED` / `_ENABLED`
  at load, for the life of the process, so every host — a stood-down one with no settings page open
  included — owned two live registrations and a second REGEN dispatcher beside its own. Now the frame
  registers both events only while one of the library's pages is on screen: a page's show registers
  (`lib.__pageShown`), a page's hide lets go when it was the last (`lib.__pageHidden`, from a new
  `OnHide` hook `CreatePanel` installs), and the dispatcher re-syncs first — pruning pages no longer
  on screen — and does nothing at all when none is left. A page shown mid-combat is locked off
  `InCombatLockdown()` alone, and its registration is what hears the end of that combat. Letting go
  also drops `lib.__combatLocked`, which nothing would clear once unregistered. A newer copy lets go
  of the registration an older v1.46.0 copy made at load.
- **Covers under hidden pages.** `PLAYER_REGEN_DISABLED` put the cover up over EVERY registered page,
  hidden ones included, so a baseline combat event left frames "on screen" under pages nobody had
  open. Now only a page on screen is covered; a hidden page is covered by its own next show, and a
  page that hides takes its cover down with it.
- **Unheld regions.** The cover's dim and line were locals, so a harness that tracks textures and
  font strings as frames saw two garbage objects per page. The cover now holds both.

A page on screen is still watched, on purpose: a stood-down addon's settings window stays usable, and
its lock with it. A consumer's stand-down suite that runs after other suites left a settings page
shown closes that page first. Cases: `tests/test_options_combat.lua` (six more).

## v1.46.0 — 2026-09-19

Versions in this release: **Options minor 22**, **OptionsWidgets minor 23** and
**OptionsTabs minor 2** (`LibKa0s-Options-1.0` 22.23.2.7.3). Every other major is unchanged from
v1.45.0, and the kit stays at revision 23.

**A settings page shown in combat is locked, and the library no longer closes Blizzard's settings
window.** The Ka0s WoW Addon Standard v2.60.0 (options-ui-§2, options-ui-§13, anti-pattern #88).
Through Options minor 21, `O.SetRenderer`'s `OnShow` called `SettingsPanel:Close()` (or
`HideUIPanel(SettingsPanel)`) when a page was shown in combat. The AddOns sidebar reaches that
`OnShow` from inside Blizzard's own `DisplayCategory → DisplayLayout → Show`, so the close ran from
addon code and Blizzard's close-and-commit path ran tainted: `SaveBindings()` blocked
(`ADDON_ACTION_BLOCKED`), then `ToggleGameMenu` re-entering the half-shown panel until `C stack
overflow`, leaving the window broken (Aura Master's smoke test). And a page left open in combat
still took writes, which applied as if nothing had refused them. Now:

- **Nothing touches the settings window in combat** — no `SettingsPanel` method or field,
  `HideUIPanel`, `ToggleGameMenu` or `Settings.OpenToCategory`. `O.OpenOptionsPanel`'s gate and its
  gray refusal are unchanged.
- **A cover per page.** `O.CreatePanel` builds, out of combat, a plain non-secure frame over the whole
  canvas — header band, chrome and tab strip included — that takes the mouse and the wheel and says
  *Settings are locked during combat.* in gray (`lib.STRINGS.COMBAT_LOCKED`). It goes up on a page
  shown in combat (nothing is rendered and no font is preloaded; an unrendered page is marked owed a
  render) and on every open page at `PLAYER_REGEN_DISABLED`, at a frame level above the deepest frame
  the page draws. It never touches keyboard propagation, and no Blizzard frame is hooked.
- **Every write through the options surface is refused while locked**: widget writes, color commits,
  session toggles, library-drawn buttons (*Reset all settings* among them), id-list adds, removes and
  toggles, the page's Defaults (header button, footer control and `O.RestoreDefaults`), structural
  re-renders (`RefreshAllPanels`, `RefreshPanel`, a switched section), tab clicks, a page banner's
  selection and `O.SelectTab`. A refused control is put back. The host hears one gray chat line per
  combat (`lib.STRINGS.COMBAT_LOCKED_NOTICE`). `O.RestoreAllDefaults` is not refused in itself: a
  host's slash reset verb calls it, and the lock covers the settings window only.
- **`PLAYER_REGEN_ENABLED` lifts the covers**; a page on screen that is owed a render renders, a
  clean one runs its refreshers, so a value a slash verb or a profile switch changed shows up. A
  hidden page is drawn on its next show. Nothing is re-opened (options-ui-§2's no defer-and-replay).
- **One event frame for the process** (`lib.__combatFrame`), kept across a LibStub upgrade and
  dispatching through `lib.__OnCombatEvent` at call time; each instance registers a weak-keyed hook.

No member, descriptor field or row field is added — the new state is `__`-prefixed — so no
degradation stub moves. A host MUST NOT keep a combat guard of its own on a settings page or a tab
strip beside this one (options-ui-§2, §13). Cases: `tests/test_options_combat.lua`, run under a
`SettingsPanel` recorder that fails any case touching the window in combat; the old
closes-the-window case in `tests/test_options.lua` is inverted.

## v1.45.0 — 2026-09-19

Versions in this release: **OptionsWidgets minor 22** (`LibKa0s-Options-1.0` 21.22.1.7.3). Every
other major is unchanged from v1.44.0, and the kit stays at revision 23.

**Switched sections: a row can be shown only while a dropdown says so.** A new optional row field,
`shownWhen = { path = <selector path>, equals = <value> | { <value>, … } }`, makes the flow engine
draw the row only while the selector holds that value — a subsection whose rows are all dropped draws
no heading and takes no space — and re-render the page once, on the next frame, when the selector
changes (its own dropdown, a `/<slash> set`, a Defaults press). It is a tab strip whose selector is a
stored setting: the three placement subsections under an *Attach to* or *Anchor mode* dropdown, of
which only the chosen one applies. The rows stay in the schema, so the CLI and the resets still reach
them. Opt-in: a row list without the field renders exactly as at v1.44.0. Aura Master (Layout →
Anchor) and Party Frame Enhanced (Size & Position) are the first adopters. Cases:
`tests/test_options_switched.lua` (its own suite: `tests/test_options_widgets.lua` is over the
layout-§1 cap, issue #33).

## v1.44.0 — 2026-09-19

Versions in this release: **OptionsWidgets minor 21** (`LibKa0s-Options-1.0` 21.21.1.7.3). Every
other major is unchanged from v1.43.0, and the kit stays at revision 23.

**`O.IdList` can draw its remove control as an X on the left.** A new optional spec field,
`removeStyle = "icon"`, draws a small X (the client's `transmog-icon-remove` atlas, 16px) at the LEFT
of every entry, before its icon and name, in place of the right-hand *Remove* button or toggle
checkbox. A click calls `onRemove` and redraws the list; the tooltip is the `remove` string, so a
host's `strings.remove` names it. Opt-in: a list that does not pass the field is drawn exactly as at
v1.43.0, so no consumer's look changes until it adopts. Aura Master's spell lists are the first
adopter. Cases: `tests/test_options_idlist_remove.lua` (its own suite: `tests/test_options_widgets.lua`
is over the layout-§1 cap, issue #33).

## v1.43.0 — 2026-09-17

Versions in this release: **kit revision 23**. Every LibStub major is unchanged from v1.42.0 — no
file under `LibKa0s/` changes, so every consumer's `libs/LibKa0s/` copy is byte-identical to the one
it already carries.

**A headless run can no longer take the machine with it, and the kit stops holding every instance a
suite builds.** Two incidents on 2026-09-16/17, neither visible as a test failure:

- **A runner that started itself.** An uncommitted probe in one consumer's `tests/`, registered in its
  runner, made the `lua tests/run.lua --list` child a suite starts start another, forever — a chain of
  ~700 MB processes that OOM-killed the WSL2 VM. A per-process cap would not have stopped it.
- **A harness that kept everything.** `testkit/mock_base.lua` found a target's build through a
  process-wide weak-keyed table whose value reached its own key through AceEvent's `embeds`. Lua 5.1
  has no ephemerons, so no build and no instance embedded in one was ever collected. Multi Meters'
  suite peaked at 1.75 GB; with the build moved onto the `__events` table's metatable it peaks at
  41 MB (Kick CD 771 → 80 MB, ConsumableMaster 442 → 24 MB, WhatGroup 328 → 18 MB).

What revision 23 adds, all of it adopted by re-vendoring with no change to a consumer's runner:

- **A load-time guard in `framework.lua`**: the process re-launches itself once under a re-launch
  depth limit (4), a process-tree `systemd-run --user --scope` memory and task cap where systemd
  exists, a per-process `ulimit -v` (2048 MB) and a wall-clock `timeout` (900 s). Every limit is a
  `KA0S_KIT_*` environment variable.
- **Runner gates**: a live-heap budget per case (1024 MB), a cumulative leak gate (256 MB), a CPU
  ceiling per case and per suite-file load (120 s) that a swallowing `pcall` cannot outrun, a refusal
  to load a suite naming a host path, and a memory-capped `--jobs`. Budgets are `Kit.run` options.
- **`run-automated-tests.sh`** runs `luacheck`, the headless suite, `tests/perf.lua` and `lizard`
  under the same memory and time bounds.

`docs/api/testkit/version-23-docs.md` is the contract; `tests/test_kit_limits.lua` pins the guard
across real child processes and every gate; `tests/test_mock_base.lua` pins the leak. The Ka0s WoW
Addon Standard v2.59.0 makes all of it `testing-§15`.

**For a consumer:** re-vendor both payloads from this tag and move the provenance line. A repo whose
docs cite `tests/_kit/framework.lua` by line number re-points those citations, since the guard moves
every line below it.

## v1.42.0 — 2026-09-17

Versions in this release: **Slash minor 14**. Every other major is unchanged from v1.41.0, and the
kit stays at revision 22.

**A reserved verb the host never registered is no longer refused while disabled.** It answers
`unknown command '<verb>'` and the help index, which is exactly what it already answered while the
addon was running. No member is added, removed, renamed or resignatured, no descriptor field is
added and `lib.LIVE_VERBS` does not move, so `docs/api/Slash/members-14.json` differs from
`members-13.json` in nothing but the file it is named for. One branch of the dispatcher is deleted
and nothing else in the file changes.

**Why.** Minor 13 answered such a verb with the stand-down refusal line while disabled and with
`unknown command` while enabled. The usual case is `perf`: a verb is reserved always but
**registered when wired**, so an addon holding a performance no-combat-path exemption ships no
`perf` entry at all and `perf` is simply not one of that addon's commands. The asymmetry made the
disabled state look as though it had swallowed a command the addon never had — **five of the eleven
consuming addons reported exactly that for `/<slash> perf` within a day of adopting minor 13**.
Nothing was refused, so nothing says it was.

The rule the gate now applies has no exception inside it: **it refuses a verb the host SHIPS, and
nothing else.** A word with no `commands` entry behind it — a misspelling, or a reserved verb this
addon never wired — takes `slash-commands-§3`'s unknown-verb path in both states. Minor 13 had
already moved the gate after the COMMANDS lookup so a typo stopped being answered with "the addon is
disabled"; this removes the one case it carved back out.

`tests/test_slash.lua`'s *a reserved verb the host never shipped is not refused, in either state*
pins it, and the verb it drives is load-bearing: only a verb that is in `lib.LIVE_VERBS` **and**
absent from the host's `commands` reaches the deleted branch, so a made-up word passes against the
bug and proves nothing.

**For a consumer:** re-vendor, and change nothing in its own code. The one thing to look at is
`tests/test_disabled.lua` — a host that pinned the refusal line for a reserved verb it does not ship
(the exempt addons pinning it for `perf`) inverts that one expectation to the unknown-command line.
A host that only pinned its own feature verbs has nothing to change; those are still refused, and
they are now the whole of what the disabled gate refuses.

## v1.41.0 — 2026-09-16

Versions in this release: **Slash minor 13**. Every other major is unchanged from v1.40.0, and the
kit stays at revision 22.

**The disabled slash surface is restored, and it is the only thing that moves.** `lib.LIVE_VERBS`
goes from `{ "enable", "help", "disable" }` to the Ka0s WoW Addon Standard's twelve reserved verbs —
`help`, `config`, `version`, `enable`, `disable`, `debug`, `perf`, `get`, `set`, `list`, `reset`,
`resetall` — and the bare `/<slash>` opens the settings panel while disabled instead of being
refused. No member is added, removed, renamed or resignatured and no descriptor field is added, so
`docs/api/Slash/members-13.json` differs from `members-12.json` in nothing at all but the file it is
named for.

**Why, and it is one sentence of testing rather than one of reasoning.** v1.40.0's Slash minor 12
implemented the standard's v2.56.0, which narrowed a disabled addon's slash surface to `enable` and
`help`. **The standard reversed that at v2.57.0** the same day, because `/<slash>` on a disabled
addon answered with a refusal instead of opening the settings panel — the one surface from which a
player switches the addon back on by hand. A rule that hides the off switch has mistaken which half
of the pair it protects, and v2.56.0's own *What the refusals cost* passage had already conceded that
taking the schema CLI away was the largest thing it gave up. `slash-commands-§2` is restored verbatim
from v2.55.0.

**What the gate is left refusing is exactly the host's own FEATURE verbs** — the ones that draw,
show, hide, track, record, test, clear or export the thing the addon exists to do, `lock` and
`unlock` among them. They answer on one tagged line naming `/<slash> enable` and do nothing else.
That is `slash-commands-§2`'s SHOULD, it survived the reversal unchanged, and it is now the only
refusal in the disabled state. `DISABLED_LINE_FORMAT`, `DisabledLine()` and the `liveVerbs`
descriptor field all stay: the refusal still prints exactly that line, and a host may still name its
own live set — narrowing it to the verbs it ships, or widening it if it declines the SHOULD.

**Nothing here weakens the stand-down, which was always the substance.** `slash-commands-§7`'s
*What MUST stand down*, `LibKa0s-Lifecycle-1.0`'s one-latch-two-holds rule and the conformance suite
are untouched. A disabled addon registers nothing, runs no timer, draws nothing and writes nothing
from a game event — and it answers every reserved verb you type at it. The dispatcher and the
settings registration are setup rather than features, so keeping them live costs nothing the
stand-down was trying to reclaim. Only step 7 of every addon's `tests/test_disabled.lua` inverts,
and it now pins whichever way the addon answered the SHOULD so the choice cannot drift silently.

**For a consumer:** re-vendor. A host that passes no `isEnabled` is unaffected, exactly as at minor
12. A host that passed a `liveVerbs` array to reproduce the narrowing should delete it, or it keeps
refusing `config` and the schema CLI on its own account.

## v1.40.0 — 2026-09-16

Versions in this release: **Lifecycle minor 1** (a new major), **Perf minor 12**, **Slash minor 12**
and **kit revision 22**. Every other major is unchanged from v1.39.0. **v1.40.0 is the tag the Ka0s
WoW Addon Standard's `slash-commands-§7` and `library-stack-§7` cite**, and no version was named
in the standard in advance, because a number invented ahead of the release is a citation that does
not resolve. With this tag, every addon's adoption of the stand-down seam is **overdue** rather than
blocked.

**`LibKa0s-Lifecycle-1.0` is a new major: the stand-down latch.** One addon, many reasons to be
inert, one way down and one way back up. `Lifecycle:New(descriptor)` takes a `standDown` and a
`standUp`, and the instance owns a HOLD SET: `:Hold(key)` calls `standDown` only when the set goes
from empty to non-empty, `:Release(key)` calls `standUp` only when it goes back to empty, and
`:Set(key, held)` is the shape a settings `onChange` actually has. There is deliberately **no
`:StandUp()` member** — a bare stand-up is the bug the latch exists to prevent, so the only route out
is releasing the hold that put the addon down.

**Why a latch and not a boolean, which is the whole of it.** Two independent reasons to be inert
means four states, and the interesting one is the state a boolean cannot represent: the addon is
perf-suspended AND the player has disabled it, the run finishes, and `resume` runs. With a boolean,
resume writes `false` and the addon comes back to life under a player who switched it off. With a
hold set, releasing `perf` leaves `disabled` taken and nothing is rebuilt. **Releasing one hold must
not resurrect an addon the other is still holding down.**

`disabled` and `perf` are exported as `lib.HOLD_DISABLED` and `lib.HOLD_PERF` rather than left as
literals, because two majors and every host in the collection have to spell them the same way or the
latch holds a key nothing releases. The key space is otherwise the host's. The latch persists
nothing: `disabled` survives a reload by being re-taken at load from the stored path, and `perf` is
session-only. It floors on `LibKa0s-Core-1.0` and returns before `NewLibrary` when Core is missing,
**even though it calls no Core member**, so a host holding a partial payload gets every module absent
rather than a mixed set (`library-stack-§7`).

**`LibKa0s-Perf-1.0` minor 12 — the suspend arm moves onto the latch, and the floor rises. THIS IS A
RE-VENDOR TRIGGER.** `Perf.lua` now returns before `NewLibrary` unless `LibKa0s-Lifecycle-1.0` is
present at minor 1 or newer, so a vendored copy that arrives beside a payload with no `Lifecycle.lua`
in it loses its perf probe outright rather than finding out mid-run. Re-vendoring is whole-folder, so
this is loud in the one case it can happen and silent otherwise.

`descriptor.lifecycle` is **required**; `suspend` and `resume` are no longer required and are no
longer called. A host passes the same two functions to the latch as `standDown` and `standUp`, where
the *disabled* arm reaches them too. Keeping them required would have forced every host to carry two
live copies of its own teardown, and two copies is exactly how the perf arm and the disable arm drift
apart. `P.Suspend()` takes the `perf` hold and `P.Resume()` releases it and nothing else — whether
the addon comes back is the latch's decision, and it says no while `disabled` is still taken.
`P.suspended` keeps its name and its meaning and is now a VIEW of the latch rather than a second
boolean; assigning to it raises, because a raw write would create a shadowing field that wins forever
after and hand the module two answers to "is this addon inert". `perf finish` still releases before
`Save` and `FormatReport`, and its line now says which of the two actually happened.

**`LibKa0s-Slash-1.0` minor 12 — the disabled gate.** Three descriptor fields (`isEnabled`,
`brandName`, `liveVerbs`), two exports (`lib.DISABLED_LINE_FORMAT`, `lib.LIVE_VERBS`) and one
instance member (`cli:DisabledLine()`). **Absent `isEnabled`, the gate is off and the dispatcher
behaves exactly as at minor 11**, so an un-adopted host is unaffected and there is no half-adopted
state to reason about.

Gated, exactly three verbs answer: `enable`, because refusing it would leave a player with no typed
route back; `help`, in full, because the player has to be able to SEE `enable` in the list — with the
refusal line immediately after the header, unindented, so twelve rows do not read as twelve working
commands; and `disable`, which is not a feature verb but an alias onto a schema write, so writing
false over false is an idempotent no-op whose honest answer is the `<enablePath> = false` echo.
Refusing `disable` would answer `/at disable` with a line telling the player to type `/at enable`,
which reads as the addon having misunderstood the request. Everything else — a known verb outside the
set, the bare `/<slash>` and an unknown verb — prints the one line and does nothing else: never
`unknown command '<verb>'` and never the index, because both answer "I did not understand you" and
the addon understood perfectly well. It is off.

The wording lives in exactly one place. It is one sentence, so re-spelling it per addon costs nothing
— which is precisely why eleven addons would each end up with their own, and a player who uses four
of them would read four different answers to the same question. `brandName` is the plain-text
`Ka0s <Name>` the LDB object already takes as its `label`, and the reuse is load-bearing:
`launcher-§1` already forbids escape sequences there, which is what makes it safe to drop into a
colored line. The `L` override deliberately does not reach this wording.

**Kit revision 22 — the recording fidelity a stand-down conformance suite needs.** `mock_record.lua`
is a new kit file carrying five surveys (`__registrations()`, `__timers()`, `__shownFrames()`,
`__svWrites()`, `__printed()`), the two drivers (`__fire` to the live set only,
`__fireUnconditional` at a target whose registration is gone), and an `AceBucket-3.0` fake. The frame
stub records raw `frame:RegisterEvent` for the first time — through revision 21 the metatable
answered it and remembered nothing, so an addon whose events sit on a plain `CreateFrame` had a
registration set no suite could see. Entries are REMOVED on unregister, which is the half that makes
the assertion falsifiable in the useful direction: a registry that only grew would report a perfectly
torn-down addon as still watching everything.

The same revision fixes two RESULTS.md standing sections that had thinned: **Lint** now names the
`exclude_files` entries it read rather than pointing at `.luacheckrc`, and **Perf** names the
scenarios as a table re-rendered from the run's own output. Consumers noticed the thinning and one
hand-patched its own `RESULTS.md` to compensate, which `automated-tests-§4` forbids and the next
re-vendor reverts; both are fixed at source, and nothing in either section is hand-written.

## v1.39.0 — 2026-09-16

Versions in this release: **Launcher minor 1** (a new major), **Options minor 21**,
**OptionsWidgets minor 20**, **OptionsTabs minor 1** (a new file in the Options major) and
**OptionsCompose minor 7**. Every other major is unchanged from v1.38.0.

**`LibKa0s-Options-1.0` gains a fifth file: `OptionsTabs.lua`** (issue
[#16](https://github.com/tusharsaxena/LibKa0s/issues/16) and its suite,
[#8](https://github.com/tusharsaxena/LibKa0s/issues/8)). The page's chrome — the tab strip, the
page banner, the host's header block, the secondary strip, the four geometry seams and the client
art all four are drawn from — moves out of `OptionsWidgets.lua`, which was 3700 lines against
`layout-§1`'s 1500-line cap. **No member is added, removed or renamed**, and nothing a host calls
changes: the members attach to the same instance under the same names.

**The cut follows the seam the file was already built along.** The chrome half and the widget half
never reached into each other's module-scope locals — every art local the tab members use lives in
the art block, and none of them was referenced from the makers, the id surface or the flow engine —
which is what made 900 lines a move rather than a rewrite. `Options.lua` 20 → 21 gains one guarded
attach call; `OptionsWidgets.lua` 19 → 20 loses the moved code.

`OptionsTabs.lua` takes the same paired-minor guard the major's other secondary files take
(`__tabsMinor` plus the shell's `__tabsShellMinor`) and the same `LibKa0s-Pool-1.0` floor
`OptionsWidgets.lua` declares. **A file added to a major moves that major's version key**: Options
ran four numbers through `20.19.6.3` and runs five from `21.20.1.7.3`.

**Two cross-file calls are now guarded, and both are honest degradations.** `O.RenderTabbedSchema`
falls back to the untabbed render when `O.TabStrip` is absent — every row with its section
headings, exactly what its no-groups branch already does — and `O.PageBanner` skips its tooltip
when `O.AttachTooltip` is absent. The two files are paired on the **shell's** minor rather than on
each other's, so a copy carrying one and not the other is a state LibStub cannot see; a page that
still draws is a smaller failure than a page that raises.

`lib.__AttachTabs(O)` takes **no descriptor**, unlike the three attach calls around it. The chrome
is geometry and art: it reads no setting, writes none, and calls no host callback but the
`onSelect` its own spec carries. The signature says so.

**The suite peels with it and in the same commit** (`testing-§1`, one suite per module): thirty-six
cases move to `tests/test_options_tabs.lua`, whole, and the repository's total is 1069 before and
1069 after. The cases under *the tabbed page* stayed with `O.RenderTabbedSchema` in
`tests/test_options_widgets.lua`, which is the one place the cut differs from the banner list #8
wrote down: they read a strip because that is what the entry point draws, but what they assert is
which rows a tab shows.

**Neither file is under the cap yet, and the census says so rather than being emptied.**
`OptionsWidgets.lua` is 2812 and its suite 3219, so both keep a row in `CLAUDE.md`'s
*Files over the 1500-line cap*, retargeted at the seam that is left — the id-resolution and
suggestion half, which is widget code and did not move.

**A new major, `LibKa0s-Launcher-1.0`** (Ka0s WoW Addon Standard v2.52.0, `launcher`). Every Ka0s
addon must ship a launcher — a minimap button, and the same addon shown in a broker display — and
`launcher-§1` makes it ONE object registered twice, never two features: a single LibDataBroker-1.1
object of `type = "launcher"`, handed to LibDBIcon-1.0, so one `OnClick`, one icon and one identity
reach both surfaces. Eleven addons were about to write that wiring eleven times, and the second
behavior change is where eleven copies drift (anti-pattern #81).

`lib:New(d)` takes `name` (the FOLDER name, which keys LibDBIcon's saved position and so is not
cosmetic), `icon` (the addon's own logo, the file `## IconTexture` names), `minimap` (LibDBIcon's own
`db.global.minimap` table, or a function answering it — the usual shape, because that table does not
exist when a host builds its descriptor at file load), `openSettings` and, where the addon is on rung
(a) or (b), `onClick`. The instance carries `Register`, `IsRegistered`, `Object`, `IsShown` and
`SetShown`. **The rung is expressed by the PRESENCE of `onClick`** rather than by a flag, so a host
cannot declare a rung it did not implement; right-click always opens the settings panel, on every
addon, which is what lets the left button be spent on something better.

**Neither broker library is a dependency.** LibDataBroker-1.1 and LibDBIcon-1.0 are resolved with
`LibStub(..., true)` at `Register` time — call time rather than load time, because nothing fixes the
order of two `# Libraries` entries — and each degradation is named rather than raised: no
LibDataBroker and there is no object at all; no LibDBIcon and the broker plugin still registers while
the button does not; a `minimap` that answers no table refuses the button and says why. `SetShown`
records the player's choice in every one of those states, so a degraded install still remembers it
and the Master-controls checkbox still reads back correctly.

**What it deliberately does not own:** the settings row (composed by `MasterControls`, below), the
inversion between the row's *shown* and LibDBIcon's `hide` (the host's single write seam, options-ui-§1),
the global scope of the table (launcher-§3), and the icon file itself (layout-§4). Twenty-two cases,
and `docs/api/Launcher/version-1-docs.md`.

**`MasterControls` composes the Minimap button row, and it takes the first column** (Ka0s WoW Addon
Standard v2.52.0, `options-ui-§15` and `launcher-§3`). A new spec field, `minimapPath`, emits an
unconditional *Minimap button* checkbox, its path taken verbatim like the console's because
`launcher-§3` keeps LibDBIcon's `minimap` table in the **global** store rather than under a profile.
It is stored state and carries no `sessionOnly`: a button the player hid stays hidden across a
reload, and across a profile switch and a *Reset all settings*, which is the whole reason the
standard puts the table where it does. The row's boolean says **shown** while LibDBIcon's key says
hidden, so the host's get/set invert at its single write seam and call `Show` / `Hide` there — the
library owns the row, not the inversion.

**`Test mode` moves off `startsLine` and pairs beside it**, so the line reads
`[Minimap button] [Test mode]`. The column order is the standard's and so is its reason: every Ka0s
addon has a minimap button and only some have a test mode, so the always-present row opens the line
and an addon with no test mode draws a tidy single row instead of a hole in the first column with a
lone control to its right. Either row alone still opens its own line — `startsLine` is computed from
what was **emitted**, so `omit = { minimap = true }` reads exactly like a spec that never named the
path — and a call that passes neither renders byte-identically to compose minor 6, which the frozen
golden fixture still confirms.

**This is the seam `launcher-§5` names, and it is what unblocks eleven adoptions.** The standard
requires the Master-controls set to be composed and never hand-written, and until this minor there
was no spec key for the row: an addon adopting the launcher could satisfy `launcher-§3` only by
hand-writing it, which `options-ui-§15`/`§16` forbid. Every consumer's adoption was blocked upstream
rather than overdue, and this release is what ends that.

## v1.38.0 — 2026-09-16

Versions in this release: **Slash minor 11**. Every other major is unchanged from v1.37.0.

**Bare `/<slash>` runs the host's `config` verb; `help` prints the index** (Ka0s WoW Addon Standard
v2.50.0, `slash-commands-§4`). Through minor 10 an empty line printed the help index. The collection
owner changed that for every addon: bare `/<slash>` now opens the settings panel on its landing page,
which renders the same `COMMANDS` table, and the list is one word away at `/<slash> help`. The
dispatcher finds the host's `config` entry (a reserved verb every Ka0s addon carries) and calls it
with an empty remainder, so the panel's own combat refusal is what a player in a fight sees. A host
with no `config` verb still gets the index. No member or descriptor field is added.

## v1.37.0 — 2026-09-16

Versions in this release: **OptionsCompose minor 6**. Every other major is unchanged from v1.36.2.

**`MasterControls` composes the Test mode row** (Ka0s WoW Addon Standard v2.46.0, `options-ui-§15`).
A new spec field, `testModePath`, emits a session-only *Test mode* checkbox on its own line below
*Lock frame* / *Debug console*, its path taken verbatim like the console's. It is opt-in: an addon
passes it exactly when its preview has a switch of its own (a test mode that stays on until turned
off), and a call without it emits the six rows it always did, which the frozen golden fixture still
confirms. `frameless` keeps it, since it drops only the frame rows. Raised by the collection owner
after the first in-game walk of Ka0s Party Frame Enhanced's `/pfe test`, whose switch had been drawn
as the composer's `leadButton`: a button cannot show whether the mode is on. **Adopters:** Ka0s Party
Frame Enhanced and Ka0s Aura Master; every other consumer re-vendors with no change.

## v1.36.2 — 2026-09-15

Versions in this release: **Options minor 20**, **OptionsWidgets minor 19**. Every other major is
unchanged from v1.36.1.

**Withdrawal of a shipped decision, on the owner's in-game feedback, not a defect fix.** v1.36.0
gave `O.ChoiceGrid`'s lit cell a solid yellow fill in place of AceGUI's own checkmark; the owner
has now seen it in-game and asked for it gone: *"The yellow filled square looks awkward, just make
it a checkbox like 'only these categories'"* — the same plain AceGUI checkbox check as the
`Only these categories` checkbox that sits above the grid on the same panel. `OptionsWidgets.lua`
18 → 19 does exactly that: `choiceFill` and its color constants (`CHOICE_FILL_R`/`G`/`B`) are
deleted outright, and `choiceCell` no longer paints the check texture at all. The cells stay
ordinary `CheckBox` widgets rather than reverting to `SetType("radio")` — the owner wants a
checkbox that *behaves* like a radio, which is `choiceCell`'s callback, not a change to the widget.
**The exclusive one-choice-per-row behavior is completely untouched**: it has always lived in that
callback, never in the widget's appearance, across every version from W16 on.

**v1.36.1's pooled-`CheckBox` fix is moot, and is removed as dead code, not left inert.** That
release added an `OnRelease` callback restoring the check texture's vertex color to `(1, 1, 1)`,
to undo the fill's gold tint before AceGUI's pool handed the frame to its next tenant. With no
fill writing a tint, there is nothing left for that callback to undo, so it is deleted along with
`choiceFill`. No other `OnRelease` wiring on these cells is touched.

**The v1.36.1 test kit stays, and its regression test is re-pointed rather than dropped.**
`testkit` revision 21's pooled `CheckBox` check texture — and the coverage built on it — closed a
real Critical (a gold tint leaking into every recycled checkbox, this addon's or another's sharing
the same AceGUI instance) that was invisible before it existed. The leak this version's write
enabled cannot recur with no write to leak, but the coverage is exactly what will make a future
fill attempt safe to try: `tests/test_options_widgets.lua`'s regression test keeps the same shape
(draw a grid, release its cells, acquire another `CheckBox`, its check comes back untinted), with
its comment rewritten to say it no longer exercises a live write and that a future fill MUST
restore the `OnRelease` handler or this regression returns silently.

**A player-facing non-ASCII byte, found by AuraMaster's own T-1 sweep, is fixed here at the
source.** The owner's font draws most non-ASCII glyphs as an empty box (screenshot: a settings
panel reading `General [box] Spell Categories`). AuraMaster's own locale strings were swept for
this in the addon repo, but one instance reaches a player from THIS library and could not be fixed
downstream: `Options.lua`'s Reset-all tooltip (`RESET_ALL_TIP_PROFILES_PAGE`) named `Profiles → Reset
Profile` with a real arrow glyph (`\226\134\146`, U+2192). It now reads `Profiles -> Reset Profile`,
plain ASCII. `OptionsWidgets.lua`'s `O.IdInput` "looking up" status text
(`ID_TEXT.looking`) carried the same problem with an ellipsis (`\226\128\166`, U+2026) rather than
`...`; both are now plain ASCII. The em dash (`\226\128\148`, U+2014) is kept everywhere it already
appears — it renders correctly in the owner's own screenshots, and AuraMaster's parallel sweep kept
its 100 uses on the same basis, so the two repos do not disagree about what is safe. `Options.lua`
19 → 20 for this fix — the string is not a member of the public surface, but its content changed
and minor 19 is already vendored into at least one consumer, so LibStub's mechanism needs a
strictly higher number to win a re-vendor. `OptionsWidgets.lua` needed no second bump: its 18 → 19
bump above was never externally consumed, so the `looking` fix lands in the same released minor 19.

**A guard added so this cannot come back — DECODED, not text-matched, after a fix-round finding
that the first cut of it could not catch the mistake it existed to prevent.** A first version of
`tests/test_prose.lua`'s guard matched the literal source TEXT of a decimal escape (`\226`, the six
characters backslash-2-2-6) and so caught only a hand-written escape; a contributor who pastes a
literal `→` straight into a string — raw UTF-8 bytes, no backslash anywhere — produced a line that
version could not match, and it passed in silence: precisely how the arrow this release removes got
in in the first place. The gate now DECODES each `.lua` line (`decodeLuaEscapes`: only `\ddd` can
decode to a byte ≥ 128, every other Lua 5.1 escape decodes under 128) after stripping its `--`
comment quote-aware (`stripLineComment`, so a `--` or a quote inside a string literal cannot
false-trigger it), then scans the DECODED bytes for anything ≥ 128 — the same shape AuraMaster's
own `tests/test_locale.lua` scans its loaded locale values with, adapted to source text because
this library has no single loaded locale table to walk the way that gate does. Scoped to `.lua`
files only, and to strings rather than comments — this file's own box-drawing rules and 480-odd
literal em dashes among them are free to use real UTF-8 because none of it ships to a tooltip. One
blanket exemption, matching AuraMaster's own gate: the decoded em dash. One ratified, path-scoped
exemption beyond that: `Core.lua`'s close-control fallback glyph, the multiplication sign (decoded
`\195\151`, U+00D7) — predates this gate, sits in Latin-1 Supplement rather than the Arrows block
the owner's screenshot actually broke on, and `Core.lua`'s own doc comment already argues for
keeping it. Not silently exempted forever: flagged in the test's own comment as a row to drop first
if the owner confirms it boxes too. Proved by pasting a literal `→` into `OptionsWidgets.lua`'s
`ID_TEXT.looking` and confirming the suite turned red naming that exact line, then reverting it.

No member is added, removed, renamed or resignatured, and no descriptor field changes. Every host
that draws a `ChoiceGrid` is affected whether or not it uses `extraColumn` or an `IdList` `note` —
the re-vendor of `LibKa0s/` is the whole change; `tests/_kit/` is unchanged at this version.

## v1.36.1 — 2026-09-15

Versions in this release: **OptionsWidgets minor 18**, **testkit revision 21**. Every other major,
and `Options.lua` itself, is unchanged from v1.36.0.

**Critical defect fix, found by a whole-branch review of v1.36.0 before it shipped further.**
`OptionsWidgets.lua`'s `choiceCell` (`O.ChoiceGrid`) paints a lit cell by repainting AceGUI's own
`check` texture gold — there is nowhere else to draw a checkbox's tick. AceGUI **pools** the
CheckBox's underlying frame: a widget's `OnAcquire` resets that texture's texture, texcoord and
blend mode for whoever the pool hands it to next, but never its vertex color, and nothing in
`choiceCell` restored it either. **Consequence: once any host drew a `ChoiceGrid`, every CheckBox
later recycled from that AceGUI instance's pool — not only in the addon that drew the grid, but in
any other addon sharing the same Ace3 embed — drew a gold checkmark instead of a white one, for the
rest of the session.** `OptionsWidgets.lua` 17 → 18 fixes it: `choiceFill` now restores the check
texture's color to its un-painted default (`1, 1, 1`) from an `OnRelease` callback, the same pattern
this file already uses for the landing page's logo texture.

No suite caught this at v1.36.0 because the test kit's `CheckBox` fake carried no `.check` texture
at all, so `choiceFill` always took its early guard and the paint was never exercised — a gap flagged
and accepted as a deferred minor when the feature landed, which is exactly why it reached a release.
`testkit` revision 21 closes it: the stock `CheckBox` fake now carries a real `check` texture,
**pooled across Create/Release** the one way a real one is, so `tests/test_options_widgets.lua` can
pin both the paint and its restoration directly — draw a grid, release its cells, acquire another
CheckBox, and its check texture is white, not the grid's gold.

No member is added, removed, renamed or resignatured, and no descriptor field changes. Every host
that draws a `ChoiceGrid` is affected regardless of whether it uses `extraColumn` or an `IdList`
`note` — the re-vendor of `LibKa0s/` and `tests/_kit/` together is the whole fix.

## v1.36.0 — 2026-09-14

Versions in this release: **Options minor 19**, **OptionsWidgets minor 17**. Every other major is
unchanged from v1.35.0.

Two files move, `Options.lua` 18 → 19 and `OptionsWidgets.lua` 16 → 17. Four changes to the
settings panel, all in `O.ChoiceGrid` and `O.IdList`, plus one new instance member:

- `O.ChoiceGrid` cells are now checkboxes with a yellow fill instead of AceGUI radios. The exclusive
  one-choice-per-row behavior is unchanged — it never lived in the widget, it lives in
  `choiceCell`, and still does.
- `O.ChoiceGrid` takes an optional `extraColumn = { header, cell(row) }`, drawn after the label
  column, for a per-row link a host can supply. Host `cell` code runs `pcall`'d per cell in the
  extracted `choiceExtraCell`, so a raising cell costs that cell and not the row or the page. The
  cell's `onClick` handler is checked with `type(cell.onClick) == "function"` rather than
  truthiness, hardened in the same release so a malformed handler cannot raise at click time.
- An `O.IdList` entry may carry `note = <string>`, drawn as its own line under the entry's name, in
  the same gray the id uses. An empty string or a non-string `note` draws nothing.
- New instance member `O.SelectTab(pageKey, tabKey) -> boolean`. Moves an already-rendered page to
  one tab and refreshes **that page only**, through `O.RefreshPanel(ctx, true)`. Returns `false` for
  a page that has not been rendered, and stores no intent for one that is later rendered — the
  caller still opens the page itself.

No member is removed, renamed or resignatured, and no descriptor field is removed. `ChoiceGrid`'s
signature is unchanged; `extraColumn` is additive on `spec`. `IdList`'s entry shape gains one
optional field, `note`. One new instance member, `SelectTab`, is added.

## v1.35.0 — 2026-09-13

Versions in this release: **Core minor 7**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 9**, **DebugLog minor 12**, **Slash minor 10**, **Options minor 18**,
**OptionsWidgets minor 16**, **OptionsCompose minor 5**, **OptionsScroll minor 3**, **Perf minor 11**,
**PerfPanel minor 5**, **kit revision 20**.

Three additions to the settings panel. One file in `LibKa0s/` moves, `OptionsWidgets.lua` 15 → 16,
and so does the kit:
- `disabledIf` on every widget maker, as a settings path or a predicate, plus a `RenderRows`
  option that draws a whole call disabled;
- `O.ChoiceGrid`, a matrix of radio cells;
- `O.ResolveId`, `O.IdInput` and `O.IdList`, which add an id by number, link or name, with
  `O.UnnamedCandidates` and `O.ID_NAME_HINT` beside them.

`O.IdInput` also suggests matching entries as the player types, and lists every rank of a shared
name as its own row to pick from. That closes
[#31](https://github.com/tusharsaxena/LibKa0s/issues/31). A typed name resolves only against what
the client can name, meaning an item the player carries or carried this session or a spell in the
spellbook, or against the ids the host passes as `candidates`. The client has no item-name search.
So the input looks up the host's uncached item candidates before it takes a name. A name several
ranks share is refused as ambiguous ("pick one from the list, or use the id"), whether its ranks
come from the candidates, the bags or the spellbook. It never adds one rank the player did not
pick, and never adds them all.

Kit revision 20 adds `mock_ids.lua` so a suite can drive the id widgets. All three came out of
AuraMaster's settings rework (feedback batch 5), and ConsumableMaster, BankLedger and LootHistory
adopt the id widgets.

No member is removed, renamed or resignatured, and no descriptor field is added. Six **instance**
members are added: `ChoiceGrid`, `ResolveId`, `UnnamedCandidates`, `IdInput`, `IdList` and
the table `ID_NAME_HINT`. The Options member manifest
lists the library table's members only, so it differs from 18.15.5.3's in the minor alone.

**Re-vendoring moves one case in nine consumers.** With the whole payload in, `LibKa0s/` into
`libs/LibKa0s/` and `testkit/` into `tests/_kit/`, every consumer's Options degradation-stub parity
check (`Kit.assertSurfaceParity`) names the six new members as missing from its hand-written stub:

```
LibKa0s-Options-1.0: the degraded stub diverges from the live surface in 6 place(s) — ChoiceGrid
is missing (live: function); ID_NAME_HINT is missing (live: table); IdInput is missing (live:
function); IdList is missing (live: function); ResolveId is missing (live: function);
UnnamedCandidates is missing (live: function)
```

That is the gate working. A stub owes every instance member, and each consumer adds six inert
members to its stub in the re-vendor commit (a table for `ID_NAME_HINT`). The clones below were
measured when the payload added four; the two added since land in the same single parity case, so
the failure counts stand. ConsumableMaster's stub check does not move. Measured in
scratch clones of all ten, each at the branch it had checked out:

| Consumer | Branch | Commit | Before (v1.34.0, kit 19) | After (v1.35.0, kit 20) |
|---|---|---|---|---|
| AbsorbTracker | `master` | `9590af5` | 588 / 0 failed / 2 skipped / 590 | 587 / 1 / 2 / 590 |
| AuraMaster | `feat/2026-09-13-feedback-batch5` | `59fe8cf` | 702 / 0 failed / 2 skipped / 704 | 701 / 1 / 2 / 704 |
| BankLedger | `master` | `fde0c98` | 869 / 0 failed / 2 skipped / 871 | 868 / 1 / 2 / 871 |
| ConsumableMaster | `master` | `0d19897` | 873 / 0 failed / 2 skipped / 875 | 873 / 0 / 2 / 875 |
| KickCD | `master` | `245e851` | 931 / 0 failed / 2 skipped / 933 | 930 / 1 / 2 / 933 |
| LootHistory | `master` | `3bf24a3` | 736 / 0 failed / 2 skipped / 738 | 735 / 1 / 2 / 738 |
| MultiMeters | `master` | `82eaa4b` | 1823 / 0 failed / 2 skipped / 1825 | 1822 / 1 / 2 / 1825 |
| PanelMaster | `master` | `5d35415` | 810 / 0 failed / 2 skipped / 812 | 809 / 1 / 2 / 812 |
| PrettyChat | `master` | `0b6b9c1` | 349 / 0 failed / 2 skipped / 351 | 348 / 1 / 2 / 351 |
| WhatGroup | `master` | `391df38` | 606 / 0 failed / 2 skipped / 608 | 605 / 1 / 2 / 608 |

In every row of the After column the one failure is that parity case, checked in AbsorbTracker's
clone by name. The two skips are the vendored-payload pair cases, because the clones had no sibling
LibKa0s. Re-vendoring the consumers is a separate step, not taken at this tag. The details are in
[`docs/api/Options/version-18.16.5.3-docs.md`](docs/api/Options/version-18.16.5.3-docs.md) and
[`docs/api/testkit/version-20-docs.md`](docs/api/testkit/version-20-docs.md).

### `OptionsWidgets.lua` minor 16 — `disabledIf` everywhere, and a disabled page

Through minor 15 only the color picker read `row.disabledIf`, and only as a settings path. Every
maker now reads it: checkbox, slider, dropdown (LSM media and numeric enums included), edit box and
color. It may be a path or a predicate, `function(row) -> bool`. It is applied at build and again by
the widget's refresher, so it re-evaluates on every `RefreshScalars`. A predicate that raises reads
as enabled. **A row without `disabledIf` is never touched**, not even with `SetDisabled(false)`,
because five hosts disable their own widgets after drawing them. The class-color swatch still
carries no `disabledIf` (`options-ui-§17`).

`RenderRows(ctx, rows, afterGroup, pairWith, opts)` takes `opts.disabled`. Every widget the call
draws is disabled, including an `afterGroup` hook's `InlineButtonPair` and a `SessionCheckbox`. It
rides on `ctx.__renderDisabled` for the call alone. Makers snapshot it at build, and a nested call
inherits it. The loop now runs under a `pcall` so the flag is restored on a raise. The raise is
re-raised unchanged with `error(err, 0)`, so a traceback shows the re-raise site rather than the
hook's frame. Eight cases in `tests/test_options_widgets.lua` pin it:
- the predicate form across every maker, with the refresh flip;
- the path form;
- a row with no `disabledIf` left alone;
- a raising predicate;
- the page flag;
- the page flag not leaking into a later render;
- a nested render inheriting it;
- an `afterGroup` hook that raises, which still propagates and leaves the flag cleared.

### `OptionsWidgets.lua` minor 16 — `O.ChoiceGrid(ctx, spec)`

This draws rows that share one value list as a grid: a header line of column labels, then per row a
radio cell for each column and the row's label with its tooltip. It is built for a category that is
*Default*, *Whitelist* or *Blacklist*. `spec` is `rows`, `columns` (`{ value, label }`), and the
optional `heading`, `labelHeader` and `disabled`. Cells read and write through the maker seam, so a
click runs `RefreshScalars`, and a stored value no column carries lights no cell. A click on the lit
cell writes nothing. Each line is guarded as a flow row is. It returns the row lines.

### `OptionsWidgets.lua` minor 16 — `O.ResolveId`, `O.IdInput`, `O.IdList`

- **`O.ResolveId(kind, text, candidates)`** is pure. It tries, in order:
  1. a number;
  2. a link of the kind's own type (`|Hspell:`, `|Hitem:`, `|Hcurrency:`, or the bare
     `spell:123`);
  3. the client's name lookup (`C_Spell.GetSpellInfo(name)`, `C_Item.GetItemInfoInstant(name)`);
  4. a case-insensitive exact name over the host's `candidates()`.

  A name two distinct ids carry is `ambiguous`: two candidates, or the client's step-3 hit and a
  different id that is either a candidate or one the client enumerates for the kind (an item in
  the bags, a spell in the spellbook). The client answers one id for a name several share (an
  item's crafted-quality ranks), so the hit alone would add a rank the player did not pick.

  It returns `id, name, icon`, or `nil, reason` for `empty`, `notFound` or `ambiguous`. `kind` is
  `"spell"`, `"item"` or `"currency"`, or a host table with its own `resolve`.
- **`O.IdInput(ctx, parent, spec)`** draws an edit box, an Add button and a status line. Enter or
  Add resolves the text, clears the box and the status line, then calls `spec.onAdd(id)`, so
  `onAdd` may redraw the page synchronously. A raising `onAdd` gets both back. On failure it writes
  the reason in orange and adds nothing.

  The client has no item-name search. `GetItemInfoInstant(name)` answers only for an item the
  player carries or carried this session, and a candidate the client has not cached has no name to
  match. So an `IdInput` (or `IdList`) drawn with item `candidates` asks the client for up to 200 of
  the unnamed ones when it is drawn. Each id is read once a session per instance, and the next
  build moves on to the next 200, so a redraw rescans nothing. A typed **name**, whether it found an
  id or not, is **looked up** while some candidates are unnamed, because a hit may be the one rank
  in the bags of a name whose other ranks are not cached. The unnamed ones are asked for again, 200
  a window, the status line reads *Looking up items…* in a neutral color, and the text is tried once
  more when they land. So a shared name is refused as ambiguous rather than one rank added. Each
  window waits at most five asks at 0.4 s, for every id it asked for, not the first to land. An id
  still unnamed after that is skipped from then on, so retired ids cannot hold the window, and a
  lookup runs at most five windows; the next Enter carries on past them. A number or a link never
  waits. A new submit, a box the player typed over, or a released box drops the lookup.

  A host kind with its own `resolve` joins in by declaring `loads = true` and an `info`, and by
  passing on the `candidates` its resolver is handed to `O.ResolveId("item", text, candidates)`.
  ConsumableMaster's Add-by-ID is that shape.
- **A host kind's `base`.** A host kind whose ids are one library kind's says so with
  `base = "item"` (or `"spell"`, `"currency"`). It takes `info`, `link`, `tooltip`, `loads`,
  `noun` and `plural` from the base where it sets none of its own, and wears the base's
  decorations: an item's quality color on suggestion rows and `IdList` names, the tier icon (or a
  spell's subtext) on suggestion rows, and the item's tooltip on entries. Its own `resolve`, and any
  field it sets, `false` included, win. It never takes the base's client name lookup or its bags or
  spellbook: what it resolves and suggests stay its own. A pick from a based kind's list is handed
  to its `resolve` first, as the id's digits, and a refusal adds nothing and says why. Without
  `base`, or with a value no library kind has, a host kind is drawn exactly as before, and its pick
  still goes straight to `onAdd`. ConsumableMaster's kind, which keeps its own existence checks and
  its no-active-spec refusal, sets `base` to list *Potion of the Hushed Zephyr*'s three ranks with
  their tier icons rather than by id alone.
- **`O.UnnamedCandidates(kind, candidates)`** is pure: the item candidates the client cannot name
  yet, each once, in the host's order, at most 200 of them. It returns none for spells, currencies,
  a host kind that does not declare `loads` and `info`, or on a client that cannot load an item.
- **`O.ID_NAME_HINT`** holds the default hints (`item`, `spell`, `currency`), one copy per instance,
  for a host's tooltip. The not-found words now say where a name can come from, for example "No item
  named '…' that the game can find." followed by the item hint, or "No spell named '…' in your
  spellbook." (`C_Spell.GetSpellInfo(name)` answers only the player's spellbook). The ambiguous
  words say "pick one from the list, or use the id."
- **`O.IdList(ctx, spec)`** draws that input plus one line per entry: icon, name, gray id, then
  Remove, or a checkbox for a toggle entry. An item's name is drawn in its quality color
  (`C_Item.GetItemQualityByID` through `ITEM_QUALITY_COLORS`), as BankLedger's and LootHistory's
  own lists drew it. It is drawn plain until the client answers a quality. Spell and currency names
  are plain. An unknown id reads "Unknown spell 12345". An uncached
  item is asked for through `LibKa0s-Item-1.0`'s `LoadItem` when present. The ids one render asks
  for share one check, 0.4 s later, which redraws the list once if any of them is named by then.
  An id still unnamed is asked for again, up to five asks, then stays "Unknown item N".
- **Suggestions while typing** (closes #31). `O.IdInput`, and so `O.IdList`, lists up to ten
  matching entries under the box as the player types, 0.1 s after the last keystroke: icon, name,
  rank and gray id. Digits match ids by prefix. Two or more characters match names in four tiers
  (the whole name, its start, the start of a word inside it, anywhere), then by shorter name, name,
  rank and id. Every rank is its own row, kept together and labeled: an item's crafted or reagent
  quality tier as the client's tier icon, a spell's subtext. More than ten ends in "+N more". The
  rows come from `candidates()`, plus the bags for items and the spellbook for spells; a currency
  has the candidates alone. A click, or Up/Down and Enter, adds that id through `onAdd`. Enter with
  nothing highlighted still submits the typed text, so a shared name is still refused as ambiguous,
  and the refusal opens the list for that text at once, so "pick one from the list" has a list to
  pick from, even for Enter inside the debounce or a lookup's last try. Add's refusal hands the box
  the keys first. A second Enter with nothing highlighted refuses again, so no rank is added
  unpicked. A keystroke drops the highlight at once, so Enter inside the debounce never takes a
  row the new text no longer matches. Escape, focus loss, the panel hiding and a redraw close it, and drop an update still
  waiting on the debounce whether or not the box shows the list yet, so no list goes up under a box
  the player has left. Focus lost to a click on the dropdown's backdrop goes back to the box, so
  Escape still reaches it. The list is as wide as the box at the dropdown's own scale. There is one
  dropdown frame per instance, its rows built once, at `FULLSCREEN_DIALOG` strata over the panel.
  One render names at most 2000 ids, once, and each keystroke scans those names and re-reads at most
  200 unnamed ones.
  No member is added. ConsumableMaster lists every rank by passing `candidates`.

The widgets never write a path, so the host keeps its stored shape. After an add or a remove,
`O.IdList` redraws through `ctx.rebuild` when the host set one, and otherwise through
`O.RefreshAllPanels()`. The words are a per-call `spec.strings` table, not `lib.STRINGS` keys. Three keys join
`add`, `remove`, `empty`, `notFound`, `ambiguous` and `unknown`: `looking`, `nameHint` and `more`.
Thirty-six cases in `tests/test_options_idsuggest.lua` pin the suggestions, six of them a based
host kind's rows, picks, resolution, the host's own `false` winning over its base, and its view
being collected with a kind built per render (on WoW's Lua 5.1, which has no ephemerons, the view
cache is weak on its values as well as its keys); two in `tests/test_options_widgets.lua` pin a based
kind's entry lines and a host kind without one. What the headless
suite cannot see, and what a host should know, is in the Options 18.16.5.3 API doc under
*Suggestions while typing*: the dropdown following a scrolled box past the page's clip edge, the
200-id pre-warm the suggestions read from, and the index built once per render.

The design's `O.IdInput(ctx, spec)` shipped as `O.IdInput(ctx, parent, spec)`, with `parent`
defaulting to the page scroll, so ConsumableMaster can draw the line into its own container.

### Kit revision 20 — `mock_ids.lua`

It is opt-in, and a harness calls it after defining its own `C_Item` and `C_CurrencyInfo`:
`dofile("tests/_kit/mock_ids.lua")(M)`. It fills only the keys the harness lacks. It provides
`C_Spell.GetSpellInfo`, `C_Item.GetItemInfoInstant`, `C_Item.GetItemNameByID`,
`C_Item.GetItemQualityByID` and `C_CurrencyInfo.GetCurrencyInfo`, looked up by id or by a
case-insensitive name. `M.addIdRecord` and `M.clearIdRecords` seed the records. An item record's
optional sixth argument is its quality, which is nil while the item is uncached.

It lives in a file of its own, and the base mock stays clear of these namespaces, for two reasons.
ConsumableMaster, WhatGroup and MultiMeters reach their Compat fallbacks by clearing `C_Spell` or
`C_Item`. And `mock_base.lua` is 1487 lines against `layout-§1`'s cap of 1500. The AceGUI fake gains
`GetText`, `SetType` and `DisableButton`.

What `O.IdInput`'s suggestions read is a second opt-in, `M.installIdSuggestions()`. It fills, only
where missing, `C_Container`'s bag walk, `C_SpellBook`'s enumeration, `C_TradeSkillUI`'s two
quality-tier lookups and `C_Spell.GetSpellSubtext`, seeded with `M.setBagItems`, `M.setSpellBook`,
`M.setCraftedQuality`, `M.setReagentQuality` and `M.setSpellSubtext`. It also gives the AceGUI
fake's EditBox the `editbox` input frame the keys land on. It is not part of the plain install or
the base, because ConsumableMaster walks its bags through `_G.C_Container`, which a mock-level
namespace would shadow, and PanelMaster's harness adds its own `editbox` only when there is none.

## v1.34.0 — 2026-09-13

Versions in this release: **Core minor 7**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 9**, **DebugLog minor 12**, **Slash minor 10**, **Options minor 18**,
**OptionsWidgets minor 15**, **OptionsCompose minor 5**, **OptionsScroll minor 3**, **Perf minor 11**,
**PerfPanel minor 5**, **kit revision 19**.

Three changes. Three files in `LibKa0s/` move, and so does the kit. `Slash.lua` gives a `string` row
the whole value typed after the path, not its first word. `Options.lua` and `OptionsCompose.lua`
make the *Reset all settings* tooltip say what the reset does, with one new optional descriptor
field, `profilesPage`. Kit revision 19 makes the AceDB fake fire `OnProfileReset` with no key, as
AceDB-3.0 does.

Nothing is removed or renamed and no member is added. With the whole payload in, `LibKa0s/` into
`libs/LibKa0s/` and `testkit/` into `tests/_kit/`, **nothing moves in any consumer**. That was
measured in scratch clones of all ten, each at the branch it had checked out, before and after:

| Consumer | Branch | Commit | Before (v1.33.0, kit 18) | After (v1.34.0, kit 19) |
|---|---|---|---|---|
| AbsorbTracker | `chore/2026-09-12-libka0s-1.33.0` | `8dbda30` | 586 / 0 failed / 2 skipped / 588 | 586 / 0 / 2 / 588 |
| AuraMaster | `test/2026-09-12-coverage` | `e15aa9c` | 667 / 0 failed / 2 skipped / 669 | 667 / 0 / 2 / 669 |
| BankLedger | `chore/2026-09-12-libka0s-1.33.0` | `e6bd2a8` | 869 / 0 failed / 2 skipped / 871 | 869 / 0 / 2 / 871 |
| ConsumableMaster | `feat/2026-09-12-profiles-buttons` | `5cebe6a` | 870 / 0 failed / 2 skipped / 872 | 870 / 0 / 2 / 872 |
| KickCD | `chore/2026-09-12-libka0s-1.33.0` | `cae55d2` | 929 / 0 failed / 2 skipped / 931 | 929 / 0 / 2 / 931 |
| LootHistory | `chore/2026-09-12-libka0s-1.33.0` | `af81ba6` | 736 / 0 failed / 2 skipped / 738 | 736 / 0 / 2 / 738 |
| MultiMeters | `chore/2026-09-12-libka0s-1.33.0` | `e66fa0c` | 1821 / 0 failed / 2 skipped / 1823 | 1821 / 0 / 2 / 1823 |
| PanelMaster | `chore/2026-09-12-libka0s-1.33.0` | `0f487c7` | 805 / 0 failed / 2 skipped / 807 | 805 / 0 / 2 / 807 |
| PrettyChat | `chore/2026-09-12-libka0s-1.33.0` | `43f5afb` | 348 / 0 failed / 2 skipped / 350 | 348 / 0 / 2 / 350 |
| WhatGroup | `chore/2026-09-12-libka0s-1.33.0` | `0fb1ef9` | 606 / 0 failed / 2 skipped / 608 | 606 / 0 / 2 / 608 |

The two skips in every row are the vendored-payload pair cases, because the clones had no sibling
LibKa0s. Re-vendoring the consumers is a separate step, not taken at this tag. The details are in
[`docs/api/Slash/version-10-docs.md`](docs/api/Slash/version-10-docs.md),
[`docs/api/Options/version-18.15.5.3-docs.md`](docs/api/Options/version-18.15.5.3-docs.md) and
[`docs/api/testkit/version-19-docs.md`](docs/api/testkit/version-19-docs.md).

### `Slash.lua` minor 10 — a free-text value keeps every word

Found by an AuraMaster test agent: `/am set container.name My Raid Buffs` stored `"My"`.
`lib.ParseValue` split its text on whitespace for every row type, and a `string` row took the first
token. The same truncation made an enum entry containing a space unsettable from the CLI: an LSM font
such as `"Friz Quadrata TT"`, a statusbar such as `"Blizzard Raid Bar"`, the composers' own
`"OUTLINE, MONOCHROME"` font flag. Nothing was raised; the value was stored and only the echo showed
it. `docs/releasing.md` had carried it since PrettyChat found it as a note, not a defect, because
PrettyChat worked around it with a descriptor `parse`.

A `string` row now takes the whole remainder, trimmed at both ends, with internal spacing kept. When
the row declares `values`, the full string is matched against them. So one input is refused that
used to be accepted: a valid entry followed by more words (`short extra`), which version 9 cut down
to `short`. An empty or blank value is refused with `expected a value`, as before, and nothing is
written. `bool`, `number` and `color` rows parse exactly as before. `CliSet` is the only verb that
feeds a parser, and it already passed everything after the path. Six cases in
`tests/test_slash.lua` pin it; four were red on minor 9.

### `Options.lua` minor 18 and `OptionsCompose.lua` minor 5 — the *Reset all settings* tooltip says what it does

`options-ui-§12` makes the global reset a profile reset on an AceDB host. The control's tooltip
**SHOULD** name the equivalence: *"the same thing Profiles → Reset Profile does"*. The tooltip was one
literal in `OptionsCompose.lua`, *"Restore every setting in this addon to its default."*, whatever
the reset did. A host that supplies `resetProfile` resets the current profile and leaves the others
alone, so the text overstated it, and a host could not change it because the composer is the only
writer of the reset's text (`options-ui-§15`).

The wording now follows the Options descriptor:

| Descriptor | Tooltip |
|---|---|
| no `resetProfile` | Restore every setting in this addon to its default. *(unchanged)* |
| `resetProfile` | Reset the current profile to its defaults. Your other profiles are not affected. |
| `resetProfile`, `profilesPage = true` | Reset the current profile to its defaults — the same thing Profiles → Reset Profile does. Your other profiles are not affected. |

`profilesPage` is the one new descriptor field (**O18**): `true` when the host ships an AceDBOptions
Profiles sub-page. The library cannot see which pages a host registers, so the host says so. It is
read by `MasterControls` alone, only with `resetProfile` supplied, and changes nothing but that
tooltip. The three strings are `lib.STRINGS.RESET_ALL_TIP`, `RESET_ALL_TIP_PROFILE` and
`RESET_ALL_TIP_PROFILES_PAGE`. `lib:New` now passes its descriptor to `lib.__AttachCompose(O, d)`,
which is why `Options.lua` moves as well as the composer. A shell older than O18 passes none, and
the composer reads that as no `resetProfile`. Five cases in `tests/test_options_compose.lua` pin
the three shapes, the unchanged rows and buttons, and the missing descriptor.

### Kit revision 19 — AceDB's `OnProfileReset` carries no key

AceDB-3.0's `ResetProfile` ends `self.callbacks:Fire("OnProfileReset", self)`: no key. The kit's
fake passed the active profile as a third argument, so a reset handler that read one passed under
the kit and got `nil` in the client. Revision 18 recorded the gap and left it for its own revision.
`ResetProfile` now fires with the database alone, and the fake's `fire` is a vararg, so the callback
gets exactly `(event, db)`. `OnProfileChanged` and `OnProfileCopied` keep their keys.
`tests/test_mock_ace.lua` counts the arguments. `framework.lua` changes only its revision number,
and `README.md` gains a paragraph.

**No production handler in the collection reads the key.** Every consumer that registers
`OnProfileReset` gets the name from `db:GetCurrentProfile()`, or, in KickCD, skips its third argument
for a reset. **No consumer test asserts on it**: every reset-log assertion that goes through the
kit's `ResetProfile` builds the name from `GetCurrentProfile()` or hard-codes the active profile.
ConsumableMaster and KickCD replace the fake and still pass a key on a reset, which real AceDB does
not; MultiMeters' wrapper already passes none to its string-form handlers; PanelMaster's and
BankLedger's fakes are their own. The testkit document lists each with its lines.

### Revision 19 is not the geometry flip

The v1.33.0 entry below leaves the flip, deleting `self.__geomLive and` from `GetHeight` and
`GetWidth`, at "19 at the earliest". **Revision 19 does not ship it.** The flip is still its own
revision with its own adoption, because roughly 308 test files lean on the zeros, so the number moves
again: **20 at the earliest**. `testkit/mock_base.lua`'s comment and
`docs/api/testkit/version-19-docs.md` record the move.

### What each consumer can adopt

- **`profilesPage = true`** on the Options descriptor: AbsorbTracker, AuraMaster and KickCD, which
  ship a Profiles page, supply `resetProfile` and compose their Master controls on the `lib:New`
  instance. *Corrected after the tag:* this line also named **MultiMeters**, and it is not a
  one-line adopter. It composes its Master controls with its own compose descriptor: a table of
  its own, attached by `lib.__AttachCompose(C)` at `settings/Schema_Compose.lua` load, before its
  Options descriptor exists. The composer reads `resetProfile` and `profilesPage` off the
  descriptor it was attached with, when `MasterControls` runs, so the field on the `lib:New`
  descriptor never reached its button, and its tooltip did not even move to the second row. It
  adopts by passing `{ profilesPage = true, resetProfile = <forwarder> }` as that call's second
  argument, the forwarder calling its real descriptor's `resetProfile` at call time. ConsumableMaster and
  PanelMaster ship a Profiles page but reset through their own handlers and supply no
  `resetProfile`, so the field does nothing for them until they adopt it (`options-ui-§12`). The
  other four ship no Profiles page. Every consumer draws the button through `MasterControls`.
- **Slash, nothing required.** PrettyChat's `parse` keeps its `||` unescape; its whitespace half is
  now redundant, and it does not trim where the library does. PanelMaster's adapter upper-cases the
  whole remainder before delegating, so `set settings.defaultStrata low junk` is now refused rather
  than stored as `LOW`. KickCD's `parseForHost` only appends a hint on failure and is unaffected.
  ConsumableMaster, BankLedger and WhatGroup tokenize only non-string rows. Rows that start working:
  AuraMaster's `container.name` and `container.attach.frame`, KickCD's `label.text`, MultiMeters'
  `window.name` and `export.whisperTo`, and every LSM font, texture or border name with a space.

## v1.33.0 — 2026-09-12

Versions in this release: **Core minor 7**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 9**, **DebugLog minor 12**, **Slash minor 9**, **Options minor 17**,
**OptionsWidgets minor 15**, **OptionsCompose minor 4**, **OptionsScroll minor 3**, **Perf minor 11**,
**PerfPanel minor 5**, **kit revision 18**.

Three changes. Two files in `LibKa0s/` move, and so does the kit. `Options.lua` loads every
LibSharedMedia font the first time a Ka0s settings panel is shown, so a font dropdown no longer
opens on blank rows. `Options.lua` and `Slash.lua` correct the source docstrings that still called
the bulk bracket's `count` "rows actually written". Kit revision 18 makes the AceDB fake hand
`OnProfileCopied` the source profile's key, as AceDB-3.0 does.

Nothing is removed or renamed, and no member or descriptor field is added. With the whole payload
in, `LibKa0s/` into `libs/LibKa0s/` and `testkit/` into `tests/_kit/`, **nothing moves in any
consumer**. That was measured in scratch clones of all ten, each at the commit shown, before and
after:

| Consumer | Commit | Before (v1.32.0, kit 17) | After (v1.33.0, kit 18) |
|---|---|---|---|
| AbsorbTracker | `f26769c` | 585 / 0 failed / 2 skipped / 587 | 585 / 0 / 2 / 587 |
| AuraMaster | `c1fc62d` | 264 / 0 / 2 / 266 | 264 / 0 / 2 / 266 |
| BankLedger | `996bd9f` | 869 / 0 / 2 / 871 | 869 / 0 / 2 / 871 |
| ConsumableMaster | `3e5a381` | 850 / 0 / 2 / 852 | 850 / 0 / 2 / 852 |
| KickCD | `f16a392` | 927 / 0 / 2 / 929 | 927 / 0 / 2 / 929 |
| LootHistory | `ee2c8ec` | 736 / 0 / 2 / 738 | 736 / 0 / 2 / 738 |
| MultiMeters | `c5441f6` | 1819 / 0 / 2 / 1821 | 1819 / 0 / 2 / 1821 |
| PanelMaster | `a947e35` | 805 / 0 / 2 / 807 | 805 / 0 / 2 / 807 |
| PrettyChat | `a0fdd98` | 348 / 0 / 2 / 350 | 348 / 0 / 2 / 350 |
| WhatGroup | `03860d2` | 600 / 0 / 2 / 602 | 600 / 0 / 2 / 602 |

The two skips in every row are the vendored-payload pair cases, because the clones had no sibling
LibKa0s. Re-vendoring the consumers is a separate step, not taken at this tag. The details are in
[`docs/api/Options/version-17.15.4.3-docs.md`](docs/api/Options/version-17.15.4.3-docs.md),
[`docs/api/Slash/version-9-docs.md`](docs/api/Slash/version-9-docs.md) and
[`docs/api/testkit/version-18-docs.md`](docs/api/testkit/version-18-docs.md).

### `Options.lua` minor 17 — every LSM font loaded on the first panel show

Reported by the owner in every Ka0s addon: the first time a font dropdown opens, many rows are
blank, and the second time they all draw. The dropdown is AceGUI-3.0-SharedMediaWidgets'
`LSM30_Font`, which `O.FontGroup` writes as its `dialogControl`. It builds its list on open, running
`SetFont(face)` then `SetText(name)` for every registered face. The client loads a font file on its
first reference, and text set with a face that is not loaded yet draws blank until something sets it
again. The blank rows were the faces nothing had used yet that session, mostly third-party LSM
faces. The widget is upstream and vendored, and it is not edited.

The library now loads every LSM face the first time any Ka0s settings panel is shown. It is never
done at load or at `PLAYER_LOGIN`. Loading every face costs memory, some of Blizzard's CJK faces are
large, and a player who never opens settings must not pay for it. One frame for the session,
parented to `UIParent`, shown, at full alpha and parked off-screen at 1x1, holds one FontString per
distinct font path: `SetFont(path, 12, "")` then `SetText("Aa")`. The state is library-level
(`lib.__fontPreload`), so every host shares it, a LibStub minor upgrade keeps it, and a session with
several Ka0s addons loads each path once. After the first preload the library subscribes once to
LSM's `LibSharedMedia_Registered` callback, and loads fonts registered later as they arrive. A
missing LSM, a raising `getLSM`, a missing `CreateFrame` or a face the client refuses costs the
preload and never the page, and nothing is reported.

It runs from two places, because two kinds of page exist. `O.SetRenderer`'s OnShow covers every page
with a renderer, and the main page when `buildMain` is set; there it runs **after** the combat
refusal. The refusal closes the window, so no dropdown can open on that show, and loading every face
mid-fight is a hitch that buys nothing; the next show outside combat loads them. An OnShow hook that
`O.CreatePanel` installs covers a page with no renderer. Such a page is still supported, and since
`RenderRows` is public it can hold a font row. The hook makes no combat decision, because that page
has no refusal and its dropdowns are reachable. `SetRenderer`'s `SetScript` replaces the hook, which
is why `SetRenderer`'s handler calls the preload itself.

It lives in the Options major rather than in Media. The trigger is the panel lifecycle, which
Options owns and Media has none of. `getLSM` is already on the Options descriptor. And `LSM30_Font`
is the control this major's own `O.FontGroup` writes. No descriptor field and no instance member is
added. The one new library-level member, `lib.__PreloadFonts(LSM)`, is `__`-prefixed and outside
the member manifest. Eleven cases in a new suite, `tests/test_options_fontpreload.lua`, pin it: once
per path, once per session across a second show and a second host, a late registration, no LSM, no
`CreateFrame`, a raising `SetFont`, combat, a renderer-less page and the main page.

### `Options.lua` minor 17 and `Slash.lua` minor 9 — the `count` docstrings

The API documents were corrected after the v1.32.0 tag (6233e3e, bf8ed91); the source was not.
Five docstrings, three in `Options.lua` and two in `Slash.lua`, still described the bulk bracket's
`count` as the rows "actually written", and the Options descriptor entry told the host to log
"N = count". They now say what the documents say. `count` is the number of rows the walk called
`applyDefault` for and that returned, including rows already at their default. It is **not**
`debug-logging-§10`'s N, which the host tallies itself from the writes that change a stored value.
Comments only, but a comment-only change still bumps (see the v1.8.0 entry), so `Slash.lua` moves
8 → 9 for it alone.

### Kit revision 18 — AceDB's `OnProfileCopied` carries the source key

The kit's AceDB fake fired every profile callback as `(event, db, <active profile>)`. AceDB-3.0's
`CopyProfile` ends `self.callbacks:Fire("OnProfileCopied", self, name)`, with `name` the profile
copied **from**. So under the kit, a copy of `"Raid"` into `"Default"` reached a handler as a copy of
`"Default"`. Every consumer with a copy handler logs `copied profile '<source>' → '<active>'`, and
the four on the kit's AceDB (AbsorbTracker, AuraMaster, PrettyChat, WhatGroup) pinned that line by
calling the handler directly. `CopyProfile` now fires with the source.
`OnProfileChanged` keeps the profile switched to, and `OnProfileReset` keeps the active profile it
always carried here. `tests/test_mock_ace.lua` pins all three. `framework.lua` changes only its
revision number, and `README.md` gains a paragraph.

**No consumer test changes outcome**, as the measurement above shows. Five tests in three consumers
run the kit's `CopyProfile`: AbsorbTracker's `tests/test_slashcmds.lua:521` and `:647`, AuraMaster's
`tests/test_bulklog.lua:126` and `tests/test_containermanager.lua:446`, and PrettyChat's
`tests/test_debuglog.lua:366`. None of them pins the source name, so each passes with either key.
Every test that does pin the source either calls the handler directly or runs through a consumer's
own AceDB fake. ConsumableMaster, KickCD, PanelMaster and BankLedger ship their own, and MultiMeters
re-fires through a wrapper that already passes the source. Five comments that describe the old key
become stale and are each consumer's to correct; the testkit document lists them.

### Revision 18 is not the geometry flip

The v1.32.0 and v1.31.0 entries below leave the flip, deleting `self.__geomLive and` from
`GetHeight` and `GetWidth`, at "18 at the earliest". **Revision 18 does not ship it.** The flip is
still its own revision with its own adoption, because roughly 308 test files lean on the zeros, so
the number moves again: **19 at the earliest**. `testkit/mock_base.lua`'s comment and
`docs/api/testkit/version-18-docs.md` record the move.

## v1.32.0 — 2026-09-12

Versions in this release: **Core minor 7**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 9**, **DebugLog minor 12**, **Slash minor 8**, **Options minor 16**,
**OptionsWidgets minor 15**, **OptionsCompose minor 4**, **OptionsScroll minor 3**, **Perf minor 11**,
**PerfPanel minor 5**, **kit revision 17**.

One change, and two files in `LibKa0s/` move. On 2026-09-12 the owner ruled, and standard v2.44.0
codified in `debug-logging-§10`, that a **bulk copy or reset through the settings helper is logged as
ONE `debug-logging-§8` flow line** naming the act, its scope and the row count
(`[Set] reset General page: 14 rows`), never one `[Set]` per row. Validation and each row's
`onChange` still run per row. The library owns three of the collection's reset walks, and each wrote
row by row through the host's descriptor, so the host's seam logged every Defaults press as N lines
with no way to tell a reset from N single writes. `Options.lua` and `Slash.lua` now call an optional
bulk bracket around those walks, and the host mutes its per-row line inside it.

Nothing is removed or renamed, no member is added, and `testkit/` does not move. A host that
supplies neither new field runs the exact walk it ran at v1.31.0, with no `pcall` on the path. Measured
with the whole payload in on all ten consumers' `fix/2026-09-12-triage` branches, nothing moves on
re-vendor. Adopting the bracket is each host's step. The details and a worked host example are in
[`docs/api/Options/version-16.15.4.3-docs.md`](docs/api/Options/version-16.15.4.3-docs.md) and
[`docs/api/Slash/version-8-docs.md`](docs/api/Slash/version-8-docs.md).

### `Options.lua` minor 16 — `bulkBegin` / `bulkEnd` around `RestoreDefaults` and `RestoreAllDefaults`

Two optional descriptor fields: `bulkBegin(act, scope)` before the act writes its first row, and
`bulkEnd(act, scope, count, err, info)` once after it. `RestoreDefaults(pageKey, ctx)` brackets its
page walk as `"reset"`, scope `pageKey`. `RestoreAllDefaults()` brackets the whole act as `"reset"`,
scope `"all"`: the row walk, then `resetProfile`, then `afterRestoreAll`. A write any of those makes
through the host's seam is part of the reset. Both refreshes run after the bracket closes. `count` is
the rows whose `applyDefault` returned. Vetoed rows, rows the `resetProfile` narrowing skips and a
raising row are not counted, but a row already at its default **is**. So `count` is **not** the N
in §10's line, which counts only rows the act actually changed. The host tallies N itself in its
muted write seam, counting only writes that change a stored value, and logs that tally. It keeps a
depth counter so that nested brackets — an `afterRestoreAll` that calls `RestoreDefaults`, a
`CliResetAll` inside an Options bracket — sum into one line, logged when the depth returns to
zero. A host that mutes in `bulkBegin` must also supply `bulkEnd`. A raise of `nil` or `false`
inside the bracket reaches `bulkEnd` as `err = nil`. The API documents' worked examples show all
of this. (Documentation corrected after the tag, on review; the payload did not change.)

**`info.profileReset` settles who logs a profile reset.** The owner's final ruling in
`debug-logging-§10` (standard v2.44.0, WowAddonStandards 7883278) logs a whole-profile reset
**once**, by the host's profile-event handler (`[Set] reset profile 'Default' to defaults (N rows)`),
and no bulk bracket may add a second line. `info` is `{ profileReset = <boolean> }`, never `nil`.
`profileReset` is `true` only when `RestoreAllDefaults` called `resetProfile` and it returned; the
host then emits nothing from `bulkEnd`. Otherwise it emits exactly `[Set] reset <scope>: N rows`,
with N the rows actually written. The session rows written before the profile reset stay muted, so
a profile-reset Restore All reads as one line. A `resetProfile` that raised leaves the flag `false`,
because the reset may never have reached the handler.

**A begun bracket always closes, so a host's mute cannot stick.** `bulkBegin` and the act share one
`pcall`. If a row, `resetProfile`, `afterRestoreAll` or `bulkBegin` itself raises, `bulkEnd` still
runs, once, with the count so far and the raised value as `err`. The library then re-raises that
same value with `error(err, 0)`, unwrapped. The walk still stops at the first raising row and the
refresh does not run, as before. A `bulkEnd` that raises propagates its own error. Either field
may be supplied alone, but a host that mutes in `bulkBegin` must supply `bulkEnd`, the only place
the mute is released. With neither, the walk runs bare: the same calls in the same order, and a
raising row escapes with its own stack. `tests/test_options_bulk.lua`, a new suite peeled off
`tests/test_options.lua` rather than taking it past `layout-§1`'s 1500-line cap, pins the call
sequence, the traceback and each logging case.

### `Slash.lua` minor 8 — the same bracket around `CliResetAll`

BankLedger's and LootHistory's Defaults button and `/<slash> resetall`, and MultiMeters'
`/mm resetall`, reach the library through `Sl:CliResetAll`, not through Options. It walks every row
through `applyDefault`, which logs 15, 16 and 169 `[Set]` lines respectively. The Slash descriptor
takes the same two fields, with the same names, signatures, call order and error semantics, so a
host passes one pair to both majors. `CliResetAll` brackets its walk as `"reset"`, scope `"all"`, and
prints its acknowledgment after `bulkEnd`, and not at all if the walk raised. With no `applyDefault`
the bracket still runs and counts zero rows. `bulkEnd` receives the same `info` table, and its
`profileReset` is always `false` here, because no Slash walk resets a profile: a host handing one
pair to both majors logs `[Set] reset all: N rows` for a resetall. No other Slash verb loops rows
through the descriptor:
`CliReset` writes one row and `BuildListLines` only reads.

## v1.31.0 — 2026-09-12

Versions in this release: **Core minor 7**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 9**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 15**,
**OptionsWidgets minor 15**, **OptionsCompose minor 4**, **OptionsScroll minor 3**, **Perf minor 11**,
**PerfPanel minor 5**, **kit revision 17**.

Three changes, all approved by the owner on 2026-09-12, and three files in `LibKa0s/` move.
`OptionsCompose.lua` and `OptionsWidgets.lua` add a record-backed arm to the Options composers, so a
page that edits registry records can compose its canonical groups
([PanelMaster#48](https://github.com/tusharsaxena/PanelMaster/issues/48)). `Perf.lua` traces the
retention prune its `Save` makes when the capture ring passes its size, which `debug-logging-§8`
requires. And kit revision 17 gives the kit's Ace fakes the surfaces six consumer harnesses need, so
those harnesses can migrate onto the kit rather than keep replacing it (BankLedger#18 and #19,
ConsumableMaster#38, KickCD#21, PanelMaster#50, WhatGroup#19). Nothing is removed or renamed and no
member is added. Measured with the whole payload in, on all ten consumers' `master` and on their
`fix/2026-09-12-triage` branches, nothing moves on re-vendor except one case in WhatGroup: its
migrated `tests/test_notify.lua` reads the timer handle's `.canceled`, and ports to `.cancelled` —
the one consumer follow-up this release asks for. The details are in
[`docs/api/Options/version-15.15.4.3-docs.md`](docs/api/Options/version-15.15.4.3-docs.md),
[`docs/api/Perf/version-11.5-docs.md`](docs/api/Perf/version-11.5-docs.md) and
[`docs/api/testkit/version-17-docs.md`](docs/api/testkit/version-17-docs.md).

### `OptionsCompose.lua` minor 4 — `spec.bind`, the record-backed arm

`O.BorderGroup` and `O.BarGroup` emitted path-keyed schema rows, and PanelMaster's panel editor edits
registry records, so its three `options-ui-§16` groups — the panel's border, the accent bar, the
accent bar's own border — were typed out by hand (`PANELMASTER-A-03`) and carried three register rows
whose re-check trigger was this arm. Every composer now takes
`spec.bind = { set = function(field, value, row) end, get = function(field, row) end }`, or `record`
in place of `get`. A bound row carries no `path`: it carries `field`, computed exactly as its path
would have been, and `get` / `set` closures over the bind. Extras declare their own `field` under
`bind` and are bound too. The rows, their order and their mandated shapes are the composer's,
unchanged. A bind that cannot both read and write is refused when the block is composed. Bound rows
are rendered directly, never put in a schema.

**Path-keyed callers are byte-for-byte unaffected**, and that is pinned rather than claimed:
`tests/fixture_compose_golden.lua` holds ten composer calls serialized from minor 3, covering every
common-spec field and every composer-specific one, and the suite compares current output against it.
The Options API document carries PanelMaster's three blocks as a worked example, and the suite builds
the same three against a stand-in registry. Adopting it in PanelMaster, and retiring the three rows,
is PanelMaster's step.

### `Perf.lua` minor 11 — `Save` traces its retention prune

`P.Save` trims the capture ring past its size (`ring`, default 10) and did it silently; two consumers
found the prune missing from their logs, and `debug-logging-§8` requires a retention prune to be
traced. A save that trims now writes one line through `P.Log`, the host's console path:
`perf ring at its cap of <ring> — dropped <n> oldest record(s)`. One line per prune, nothing while the
ring is under its cap, and nothing else about `Save` changes. `docs/api/Perf/version-11.5-docs.md`.

### `OptionsWidgets.lua` minor 15 — a row with no path reads and writes through its own `get` / `set`

The flow engine's half. Every maker — checkbox, slider, dropdown, edit box, color picker, the color
picker's throttled and confirmed commits, and every refresher — reads `row.get()` and writes
`row.set(value)` for a row whose `path` is nil. The gate is `path == nil`, not the presence of a
`get`, so a path-keyed row is read and written through the descriptor exactly as before, whatever else
a host's schema gives it. The empty-dropdown report names a bound row by its `field`, `RenderRows`'
`pairWith` finds a bound row's partner under its field, and a path-less row's `disabledIf` is read
with `row.get(key)` — for a composed row, that field of the same record.

### Kit revision 17, `mock_base.lua` — the Ace surfaces six harnesses migrate onto

Each piece was checked against the real Ace3 source vendored in the consumers' `libs/`.

- **AceAddon.** `NewAddon([object,] name, lib, ...)` now honors its mixin list: it embeds exactly the
  named libraries, through `LibStub`, validates the name, names the object (its `tostring` is the
  name), registers it for `GetAddon` and stamps the fourteen mixins. `NewModule` builds child addons
  with prototypes, default libraries and default state. The lifecycle runs the way the client runs
  it, from `ADDON_LOADED` and `PLAYER_LOGIN` on `AceAddon.frame`, so a test fires
  `AceAddon.frame:__fire("OnEvent", "PLAYER_LOGIN")`. `EnableAddon` runs the addon's `OnEnable`, then
  its modules in creation order, and `DisableAddon` calls every embedded library's `OnEmbedDisable`.
- **AceEvent** is two CallbackHandler registries. Messages get string methods, the default method
  named after the message, the optional `arg`, validation, `UnregisterAllMessages`, and a
  registration made mid-dispatch applied when the dispatch ends. `M.__msgRegistry` publishes the
  registry. `M.__fireEvent(event, ...)` dispatches a game event to every registrant.
  `M.__badEvents` makes the client refuse an unknown event on its first registration, after the
  callback is stored, which is where retail raises.
- **AceTimer** is real: `ScheduleTimer`, `ScheduleRepeatingTimer`, `CancelTimer`, `CancelAllTimers`
  and `TimeLeft`, on the kit's own queue. `M.__fireTimers()` skips a canceled entry and answers how
  many ran, and `C_Timer.NewTimer`'s `Cancel` is honored.
- **AceConsole** stamps `Print`, `Printf`, `RegisterChatCommand` and `UnregisterChatCommand`;
  `AceConsole.commands` records a command and `AceConsole:__slash(command, input)` runs it.
- **AceGUI** publishes `WidgetVersions` beside `__widgetVersions`, as the same table, and gains
  `RegisterLayout` / `GetLayout`.

Two divergences are deliberate. `NewAddon(target)` — exactly one argument, a table — keeps revision
16's behavior, for safety; any other call without a string name raises, as the real one does. An error inside a
lifecycle callback lets the cascade finish, as the client does, and is then raised instead of
swallowed; a message or event handler that raises is treated the same way. A canceled AceTimer
handle carries AceTimer's own field, `handle.cancelled`, and a `C_Timer.NewTimer` handle answers
`IsCancelled()`: third-party API identifiers, which the prose gate exempts by name under a new
`localization-§5` row in `CLAUDE.md` (owner decision, 2026-09-12). Declined for this revision: `AceConsole:GetArgs`, a kit
`SetTitle`, and the second return of `LibStub:NewLibrary`, which the kit answers as the new minor where
the real one answers the old. The last was found during this work; BankLedger's harness reads that
return, so fixing it is a revision of its own.

### Revision 17 is not the geometry flip

The v1.30.0 entry below says the flip, deleting `self.__geomLive and` from `GetHeight` and
`GetWidth`, is "17 at the earliest". **Revision 17 does not ship it.** The owner accepted that the
harness surfaces take revision 17, and the plan behind the flip still holds: it ships alone, with its
own adoption, because roughly 308 test files lean on the zeros. So the number moves again. The flip is
the next revision that ships it alone, **18 at the earliest**. That entry is history and stays as it
was written; `testkit/mock_base.lua` and `docs/api/testkit/version-16-docs.md`'s closing section record
the move.

### Adoption: nothing moves

**Measured.** Revision 17's `testkit/` went into fresh clones of all ten consumers, against a baseline
taken with revision 16 at the same commit, and then the whole payload went in with `LibKa0s/` in
`libs/` as well. Every total is identical in all three runs: AbsorbTracker 565, AuraMaster 251,
BankLedger 850, ConsumableMaster 797, KickCD 888, LootHistory 721, MultiMeters 1764, PanelMaster 785,
PrettyChat 333 and WhatGroup 573, each with its two vendored-payload skips. Unlike 16, 17 adds no
consumer-side case. Adoption is the re-vendor, and the six migrations are each consumer's own
follow-up, with what stays local listed per consumer in the testkit document.

**Re-measured after the review**, on the ten consumers' `fix/2026-09-12-triage` branches, where six
harnesses have migrated or are migrating onto kit 17: as each branch stands, with the pre-review
payload, and with this one. Nine are identical across all three. **WhatGroup moves**: its migrated
`tests/test_notify.lua:159` reads `firstHandle.canceled`, the pre-review spelling, and fails once the
field is AceTimer's `cancelled`. Porting that one identifier makes it 579 green again. The table is
in the testkit document.

**Also from the review.** A repeating AceTimer keeps its period when a test never moves the clock
(the drift compensation read an unadvanced clock as the timer being early). The no-name `NewAddon`
path is taken only for a lone table argument, and its `CancelTimer` is honored. A message or event
handler that raises no longer ends the dispatch. `ADDON_LOADED` after the login enables a
load-on-demand addon, reading `IsLoggedIn` at call time. And the AceEvent library object carries
`RegisterMessage`, `UnregisterMessage` and a multi-target `UnregisterAllMessages`.

The standards pointer moves from v2.43.0 to v2.44.0. The only change between them is to
`architecture-§5`, which is not on this repo's `library-stack-§7` applicability list.

## v1.30.0 — 2026-09-12

Versions in this release: **Core minor 7**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 9**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 15**,
**OptionsWidgets minor 14**, **OptionsCompose minor 3**, **OptionsScroll minor 3**, **Perf minor 10**,
**PerfPanel minor 5**, **kit revision 16**.

No file in `LibKa0s/` moved, so every minor above is the one v1.29.0 shipped, and LibStub sees no
difference between the two. The release is kit revision 16. It closes four gaps between the kit's
Ace fakes and the real Ace3, and adds the consumer check `automated-tests-§2` requires. AuraMaster
found all four and shimmed each one locally
([#27](https://github.com/tusharsaxena/LibKa0s/issues/27),
[#28](https://github.com/tusharsaxena/LibKa0s/issues/28),
[#29](https://github.com/tusharsaxena/LibKa0s/issues/29),
[#30](https://github.com/tusharsaxena/LibKa0s/issues/30)). Adoption is the kit re-vendor, deleting
the shims it replaces, and one edit in LootHistory, whose own event shim this revision switches off.
The whole of it is in [`docs/api/testkit/version-16-docs.md`](docs/api/testkit/version-16-docs.md).

### Kit revision 16, `mock_base.lua` — `AceGUI:Release` (#27)

The kit's AceGUI factory handed widgets out and never took one back, so a settings page that
releases the previous render's widgets raised on the call. AuraMaster and AbsorbTracker each carried
their own `Release`. The kit now has one, and it follows `AceGUI-3.0.lua` step for step:

1. A guard, the real `isQueuedForRelease`, against a release reached from the widget's own
   `OnRelease`.
2. The frame is hidden.
3. `"OnRelease"` fires while the widget still has its children and its callbacks. LibKa0s's own
   `OptionsWidgets.lua` depends on that order.
4. `ReleaseChildren` runs, then the widget's own `:OnRelease()`.
5. The widget is wiped: `userdata` and every callback are cleared in place, the size fields the real
   one nils are dropped, and the frame's points and parent are reset.

On top sits the recorder AuraMaster's shim introduced, `w.__released = true` and `AceGUI.__released`
in order, so a suite written against the shim reads the same fields. Where the shim and the client
disagree, the kit follows the client: `Release(nil)` raises instead of returning quietly, and so does
a second release of the same widget, with the real `"Attempt to Release Widget that is already
released"`. The fake raises that one before touching the widget, where the client raises at the end.
Every widget also carries `userdata = {}` and a `widget:Release()` method that is
`AceGUI:Release(widget)`, as the real `WidgetBase.Release` is.

Two differences from the real one are kept on purpose. There is no pool, so a `Create` after a
`Release` is always a fresh widget. And the children go through the fake's own `ReleaseChildren`,
which forgets them rather than releasing each one. Making it release them would change every
re-rendering panel in the collection at once, which is a revision of its own.

### Kit revision 16, `mock_base.lua` — AceEvent's event half on an embed (#29)

The real `AceEvent:Embed` stamps the event half as well as the message half: `RegisterEvent`,
`UnregisterEvent`, `UnregisterAllEvents`. The kit's Embed modeled messages only. So a module that
registers game events on a target of its own, the `NS.NewBusTarget()` shape `architecture-§4`
prescribes, hit a nil field headlessly. Only the `NewAddon` target recorded events.

**Both now share one implementation.** The three functions are module-level locals, stamped onto the
`NewAddon` target and onto every Embed target by one helper, so they are the same function objects
on both. `tests/test_mock_base.lua` asserts that identity. The contract is the one the `NewAddon`
target always had:

- `__events[event]` holds the handler, or `true` when none was given.
- `UnregisterAllEvents` clears it in place and leaves message registrations alone, as the client's
  two separate registries do. It is new on the `NewAddon` target too.
- `RegisterEvent` now validates as CallbackHandler does, with its messages: the event must be a
  string, the method defaults to the event's name, and a string method must be a function on the
  target. So `RegisterEvent("PLAYER_LOGIN")` on a target with no `PLAYER_LOGIN` method raises, as
  does a misspelled method name. What is recorded is unchanged. Every production registration in the
  ten consumers passes the checks.
- The registry is one per mock build, keyed by target, as the real one lives in the library. A
  second `Embed` in the same build keeps what the target had registered; a target table reused by a
  later build starts empty.

### Kit revision 16, `mock_base.lua` — `Printf` beside `Print` (#30)

AceConsole-3.0's mixins are `Print` and `Printf`, so `NewAddon` clobbers an addon's own `NS.Printf`
exactly as it clobbers `NS.Print`, and the addon has to take both back (`architecture-§2`,
anti-pattern #36). The kit stamped only `Print`, so an addon that forgot `Printf` passed every suite.

Both mixins now end in one local shaped like AceConsole's `Print(self, frame, ...)`:

- A first argument with an `AddMessage` member is the frame to print to. That branch is new for
  `Print` as well.
- `Printf` formats with `string.format`.
- Called bare, as `NS.Printf(fmt, ...)`, the format string lands in `self` and what follows it is
  formatted, exactly as in the client. So `NS.Printf("%d items", 3)` prints
  `"|cff33ff99%d items|r: 3"`, and a bare `NS.Printf(fmt)` with nothing after it raises, as
  `string.format()` does.

### Kit revision 16, `vendor_sync.lua` — the runner's recorded mode, in every consumer (#28)

`automated-tests-§2` requires that the vendored-payload gate assert the runner is recorded `100755`.
This repo has asserted it for its own two copies since revision 11, and no consumer had any check.
A byte comparison cannot see a mode, and neither can `ls -l` on DrvFs with `core.fileMode=false`.

`VendorSync.register` now adds a case named
`the automated-test runner is recorded executable (100755)`. It runs
`git -C <root> ls-files -s -- tests/_kit/run-automated-tests.sh` and asserts the mode. It needs no
sibling, so a missing LibKa0s checkout does not skip it. It skips, with a reason saying the mode was
not checked, only where there is no `io.popen`, no git or no work tree, and it never passes
silently. `opts.runner` and `opts.runnerCase` override the path and the name.

In this repo the default path is also correct, because LibKa0s vendors its own kit to `tests/_kit/`.
The library still cannot run `register` end to end, since it has no sibling, so
`tests/test_kitsync.lua` drives the new case through a stand-in test table. It covers five outcomes:
a pass on this repo's copy, a failure on a `100644` path and on an untracked one, and a skip with a
reason for a missing work tree and a missing `io.popen`. The two-copies case stays beside it.

### Revision 16 is not the geometry flip

The v1.27.0 entry below says that revision 16 deletes the `self.__geomLive and` from `GetHeight` and
`GetWidth`. **It does not.** A frame nobody armed still answers 0. The plan's substance holds: the
flip is its own revision with its own adoption, shared with nothing, because roughly 308 test files
lean on the zeros. So the number moves instead. The flip is the next revision that ships it alone,
17 at the earliest. That entry is history and stays as it was written; `testkit/mock_base.lua` and
`docs/api/testkit/version-15-docs.md`'s closing section record the move.

### Adoption: +1 case, one collision, and shims to delete

**Measured.** Revision 16's `testkit/` was dropped into fresh clones of all ten consumers. Every total
went up by exactly one, the runner-mode case, which passes in all ten: AbsorbTracker 560 → 561,
BankLedger 849 → 850, ConsumableMaster 796 → 797, KickCD 870 → 871, LootHistory 720 → 721,
MultiMeters 1748 → 1749, PanelMaster 783 → 784, PrettyChat 328 → 329, WhatGroup 568 → 569 and
AuraMaster 251 → 252.

**LootHistory is the one red.** Its mock installs a private event registry on an Embed target only
when the kit's Embed left `RegisterEvent` unset, which at 16 never happens. So
`browser: a combat transition re-applies visibility through the private event target` fails. The
collision is #29's fix itself. Delete that shim and fire the recorded handler,
`target.__events[event](event, ...)`.

**Delete the shims in the re-vendor commit:**

- **AuraMaster:** the three `tests/wow_mock.lua` blocks ("AceGUI:Release", "AceConsole's Printf",
  "AceEvent's event half on an embed"), and the local runner-mode case in
  `tests/test_vendor_sync.lua`. Measured with all four removed: the total is unchanged and one case
  fails. That case is AuraMaster's citation gate: `DEPENDENCIES.md:45` cites a line of the deleted
  case, so move the citation in the same commit.
- **AbsorbTracker:** the `AceGUI:Release` shim. Measured with it removed: 561 total, all green.
- **PrettyChat:** the `Printf = noop` override. Removing it was not measured.

## v1.29.0 — 2026-09-09

Versions in this release: **Core minor 7**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 9**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 15**,
**OptionsWidgets minor 14**, **OptionsCompose minor 3**, **OptionsScroll minor 3**, **Perf minor 10**,
**PerfPanel minor 5**, **kit revision 15**.

`dump` stops being a step. **This removes a sub-verb and a `Progress()` field**, which is the first
release since v1.20.0 to take anything away — a host reading `Progress().dump`, or offering
`perf dump` in its own help, has one line to delete.

### `Perf.lua` minor 10, `PerfPanel.lua` minor 5 — one review step, two artifacts

`report` printed the summary and `dump` printed the run as one line of JSON. Both went to the same
log, both described the same finished run, and `perf-analysis` asks for **both** — so splitting them
across two verbs and two panel rows was a second click, a second thing to remember, and a run
reported without its dump was the easy mistake to make. It is one step now: `report` writes the
summary and then the JSON.

**The JSON is last on purpose.** The summary is what a person reads and the JSON is what they copy,
and a copy-paste starts at the bottom of the window.

**Folded, not aliased.** `perf dump` is no longer a verb at all, rather than a synonym for `report`:
an alias would be exactly the duplication the fold removes. The unknown-verb path already prints the
usage block, where `report` now says it renders the JSON too, which is a better answer to someone
with the old command in their fingers than a silent synonym would be. The panel loses its `JSON
Dump` row and its `STEP_DUMP` string with it, and the review tracker goes from two keys to one.

## v1.28.0 — 2026-09-09

Versions in this release: **Core minor 7**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 9**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 15**,
**OptionsWidgets minor 14**, **OptionsCompose minor 3**, **OptionsScroll minor 3**, **Perf minor 9**,
**PerfPanel minor 4**, **kit revision 15**.

One file moved, and it is a rendering fix a player reported from three addons at once. `Perf.lua` 9
stops printing a usage block the client mangles and hand-aligns. Adoption is the re-vendor and
nothing else: no member is added, removed or renamed, and `P.Usage()` returns what it always did —
a table of chat lines — with different strings in it.

### `Perf.lua` minor 9 — the usage block stops being eaten, and stops pretending chat is monospaced

**Two defects, one block.** `P.Usage()` printed this:

```
usage: /at perf <start|measure|finish|canceleport|dump|showideoggle>
```

The verbs are pipe-separated alternatives and the client reads `|r` as a color **reset**, `|h` as a
hyperlink and `|t` as the end of a texture. It ate all three: `cancel|report` fused into
`canceleport`, `show|hide|toggle` into `showideoggle`. The eaten `|r` was also the reset that closed
the gold run, which is why the whole line stayed yellow — one bug wearing two symptoms. The pipes are
doubled now, `||` being the escape for a literal one.

**The rest of the block hand-aligned a second column with leading spaces** and pushed the tail of
each description onto a continuation line. Chat is a proportional font and wraps on its own, so the
columns never lined up and the continuations arrived as orphaned fragments under the wrong verb. Each
verb is one row now, through **`lib.FormatRow`** on the Slash major — reached through LibStub rather
than copied, because that major's own API document calls it *the one command-row formatter in the
collection* and a second copy here would make the sentence false. Where Slash is absent the row
degrades to an uncolored `verb — description` rather than to a second gold format: a duplicate that
only appears when a library is missing is still a duplicate.

**A gate went in with it**, over every line `P.Usage()` returns rather than the one that broke: a
bare `|` followed by an escape letter is the finding. The failure needs a pipe and one particular
next letter, so any line added later is one word away from it and nothing else in the harness would
notice.

## v1.27.0 — 2026-09-07

Versions in this release: **Core minor 7**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 9**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 15**,
**OptionsWidgets minor 14**, **OptionsCompose minor 3**, **OptionsScroll minor 3**, **Perf minor 8**,
**PerfPanel minor 4**, **kit revision 15**.

Three files moved and the kit moved with them. `Options.lua` 15 takes over the `LSM30_Border`
fixup five addons each keep a private copy of, and adds the string a handler-less button reports
itself with. `Perf.lua` 8 stops rebuilding a bracket table it can reuse and asks
`C_SpecializationInfo` before the two bare globals it kept as a fallback. Kit revision 15 is the
larger half: the runner finally writes the record `automated-tests-§4` has always MUSTed of it,
the line-ending gate reads the whole tracked set instead of one directory, the shared mock can be
asked how tall something is, and a degradation stub can be checked against the surface it stands
in for. Adoption is the re-vendor plus the two surfaces a consumer chooses to call; nothing here
removes or renames a member, so a host that ignores all of it behaves as it did at v1.26.0.

### `Options.lua` minor 15 — the `LSM30_Border` fixup becomes the library's, once per session

**`lib.__PatchLSM30Border()`**, on the library table rather than on an instance, idempotent behind
`lib.__lsmBorderPatched`. It wraps whatever constructor AceGUI currently holds for `LSM30_Border` and
registers the wrapper one version higher, hiding the 42x42 preview tile upstream
AceGUI-3.0-SharedMediaWidgets pins to the widget's TOPLEFT and putting the label and the dropdown
bar's left cap back on the frame's own edge. Returns true if this call registered, false if there was
nothing to do.

**Why it is here rather than in an addon.** `AceGUI.WidgetRegistry` is one table shared by every
addon in the client, Ka0s or not, and the highest version registered for a name wins for the rest of
the session. Five addons in this collection each ship a private `core/LSMPatch.lua` doing exactly
this — AbsorbTracker, ConsumableMaster, KickCD, MultiMeters and PanelMaster, five distinct files with
one intent. Every one of those wrappers closes over whatever the registry held when its
`PLAYER_LOGIN` fired, so with all five loaded the last addon to log in wraps the fourth, which wraps
the third, and the outermost wrapper belongs to whichever addon the client happened to load last. The
result is a function of load order, which is precisely why no addon's suite could ever see it: each
one loads a single copy, registers once and passes. `library-stack-§9` and anti-pattern #76 now say
so; this is the surface they point at.

**The sentinel is the point, not a detail.** LibStub hands every vendored copy in the session the
same `lib`, so five copies calling this produce exactly one registration — the count is independent
of how many Ka0s addons are installed and in what order. And it is set only after a registration
actually happens: AGSMW is a separate addon, so a call that arrives before it has loaded finds
nothing to wrap and must leave the surface armed for the next one.

**Adoption is not the re-vendor alone, and the order matters.** Nothing in this library calls the new
member, so a host that ignores it is byte-identical to 14.14.3.3. The five addons carrying a private
copy re-vendor and add the call **with every local copy still in place**, confirm in the client with
all five loaded that no Border dropdown depends on load order, and only then delete the copies, one
repository per commit, testing again after the first — AbsorbTracker last, because its copy is a
callable `NS.ApplyLSMBorderPatch()` rather than a `PLAYER_LOGIN` frame. Deleting them together would
leave no bisect point if the sentinel is wrong.

**Registering a new widget type an addon defines for itself is untouched**, and so is the
per-instance answer: hide the child and re-anchor the region at the addon's own creation site, and
leave the registry alone. What this replaces is reaching the same end by editing the table every
other addon in the client reads.

**Also in minor 15: `lib.STRINGS.DEAD_BUTTON`, and a reset button that admits it does nothing.**
The string is `Options.lua`'s, so it rides minor 15; the report site is `InlineButtonPair` in
`OptionsWidgets.lua`, whose own counter stays at 14 because v1.26.0 released it there and the
shell it is paired against moved instead. That pairing — `__widgetsShellMinor` against
`lib.MINOR` — is what makes the unbumped file safe: a v1.26.0 copy loading beside this one
re-attaches or defers on the shell's number, so the winning shell always carries the widgets
file it shipped with, in either load order. It is the case `OptionsScroll.lua`'s comment
describes, reached for real rather than in theory.

`OptionsCompose` builds the master group's *Reset all settings* and *Reset position* whether or not
the host spec supplied `onResetAll`/`onResetPosition` — deliberately, because the pair is the
canonical shape `options-ui-§15` fixes and a composer that quietly dropped one would make the gap
read as a layout decision. What was missing is anyone saying so: `makeBtn`'s `OnClick` simply
returned early, so the player got a live-looking button that absorbed the click in silence and the
author never heard about the handler they forgot. `InlineButtonPair` now reports once at BUILD time
for a spec with no `onClick` and draws the button anyway — the shape `EMPTY_DROPDOWN` already sets,
and not an error, because taking the page down over a convenience would be the worse trade. Said at
build rather than on the press it lands once, in the log of whoever opened the panel, instead of
once per click in the log of whoever pressed it.

**Consumers should expect a line on the first re-vendor.** Because the composer builds both resets
unconditionally, any host not passing `onResetAll` starts printing this the moment it takes the new
copy. That is the point, and the answer is to supply the handler rather than to silence the line.

### `testkit` revision 15 — the runner records what it measured, the mock can be asked how tall something is, a stub can be checked by name, and the kit ships a gate of its own

Three files move and one is new. `run-automated-tests.sh` rewrites the record, `mock_base.lua` grows
a geometry surface that answers nothing until a test asks it to, `framework.lua` grows a second
calling form for `Kit.assertSurfaceParity` and learns to load a suite that ships in the kit, and
`test_eol.lua` is the first suite the kit itself carries; `loader.lua` and `vendor_sync.lua` are
untouched. **Every consumer's case count moves by exactly one on adoption** — the new suite, and
nothing else. Full surface:
[`docs/api/testkit/version-15-docs.md`](docs/api/testkit/version-15-docs.md).

**The skipped count stops vanishing.** `framework.lua` has printed `N passed, N failed, N skipped,
N total` since the skip status existed at revision 8, and the runner's regex could not span
`, N skipped` — so the match stopped at `failed`, the positional read of the total came back empty,
and `TESTS_TOTAL` fell back to `passed + failed`. A suite with three declared skips recorded as a
suite three cases smaller, on every row of every trend line, with no `skipped` key in the manifest to
contradict it. Every figure is now read **by its label** rather than by field position, which is the
actual fix: the summary has grown a column twice and the positional read broke silently both times.
`suites.tests.skipped` joins the manifest and the **Tests** cell becomes `passed/skipped/total` under
the same column name.

**A release run stops being filed against the version it replaces.** `--release X.Y.Z` runs before
the tag (`automated-tests-§6`), so the `.toc` still carries the outgoing version while the run is the
incoming one's evidence. The Version cell now reads `1.24.0 → 1.25.0` when the manifest carries a
release — which is what this repo's own row for `20260903-161751` should have said and did not.

**And a release run is now refused on a dirty tree.** `--release` does not label a run, it makes that
run the evidence for a version — `automated-tests-§3`'s release gate and `/wow-addon:bump-version`
read the manifest it writes and nothing else. A tree with uncommitted changes is not a commit, so the
`git.sha` recorded beside the claim names bytes that were never measured. Of this library's
twenty-nine release bundles, twenty-eight record `"dirty": true`; `20260903-161751` stamps
`"release": "1.25.0"` at sha `895cdf4` on a tree that cannot be checked out, and from a trend line it
is indistinguishable from a reproducible run. The runner now exits 2 before any suite runs, names the
paths that made the tree dirty, and offers no override flag — an escape hatch on this gate would be
reached for on the one release where the gate matters. Nothing else changes: a run without
`--release` is unaffected, so the commit gate and every pre-commit hook keep their behavior and their
exit code. `docs/releasing.md` step 7 carries the order this requires — commit the release, run the
battery on the clean tree, then a second commit for the bundle and its `RESULTS.md` row, and the tag
on that.

**`RESULTS.md` is regenerated whole, rows preserved.** The runner had two write paths: an `awk` that
inserted one row under the header, and a create-the-file branch carrying the header, the lead-in and
everything else — reached only when the file was absent or its column set had changed, which in a
repository that has ever run this script is never. The corrected four-checkpoint lead-in therefore
sat in unreachable code while ten repositories carried the two-sentence text it was written to
replace. The guard that matters stays: a file whose **header** is not the current column set is
still left alone with a warning, because rewriting it would drop every previous row.

**And the two things `automated-tests-§4` MUSTs and no runner had ever emitted.** The complexity
watch list — warned functions (Function / CCN / Location / Disposition) and files by `layout-§1`
band — generated from the run's own `lizard` output, and one standing section per suite generated
from the same manifest. Until now `documentation-§3` called this file generated while
`automated-tests-§4` mandated narrative nothing produced, and the state on the far side of that
collision was not a badly-graded file but no file: the record went stale in ten of ten repositories.
MultiMeters' hand-written watch list reported *"None — `lizard` reports 0 warnings"* above a table
row recording 19; this repository's own test-suite section opened with *"499 cases"* against a suite
running 764. The standard settled the boundary at v2.39.0 and this is the code half of it.

**The one authored cell** is the watch list's `Disposition`. The runner carries it forward verbatim
while its entry is unchanged and leaves it **blank** where the entry is new, so a blank cell is the
record saying something crossed and nobody has ruled on it. The key is the function and its file —
not a line range, which would blank every disposition in a file the moment anything above it grew a
line — with the measured CCN breaking a tie between two warned functions of the same name in one
file. A tie the CCN cannot break leaves the cell blank rather than attaching one entry's ruling to
another.

**`mock_base.lua` can now be asked how tall something is.** It answered `GetHeight()` with 0 for
every frame and defined no `SetAtlas` at all, so `OptionsWidgets.lua`'s tab pitch — measured off the
unselected tab art through a probe texture — always came back 0, always took its `L.TAB_H` fallback,
and every `options-ui-§13` geometry-invariance assertion passed without measuring anything.
AbsorbTracker, MultiMeters, PanelMaster and PrettyChat each filed the missing case and none of them
could write it, because the fidelity it needs lives here. `SetAtlas(name, useAtlasSize)` now records
the atlas name always and the published size when asked, `f:__setGeom(w, h)` is the opt-in that arms
a frame, and `mock.__atlasSizes` is the fixture both read.

**The opt-in belongs to the test and never to the code under test**, and that was learned rather than
designed. The obvious shape — `SetAtlas` writes geometry, `GetHeight` answers it — was written first
and three of this repo's own widget cases went red inside a minute: `tabArtHeight()` began measuring
28 where it had always fallen back to 37, and the strip re-wrapped underneath cases that never
mentioned geometry. Production calls `SetAtlas` on a probe texture no test holds a handle to, so a
`SetAtlas` that arms geometry by itself is next revision's flip arriving by accident, in ten
repositories at once. `GetHeight` therefore reads `(self.__geomLive and self.__geomH) or 0`, and a
frame nobody armed answers exactly what it answered at revision 14.

**Revision 16 deletes the `self.__geomLive and` from those two lines**, and that is the entire flip.
It is a separate revision because roughly 308 test files across ten repositories lean on geometry
answering zero and every assertion that passes *because* of it moves with the default. The surface
lands now; the default moves once each consumer has adopted the opt-in where it needs geometry. Until
then the four filed cases stay deferred and the interval is covered by an operator cycling the tab
strips in the client, which is a weaker check than they asked for and is said here rather than left
unstated.

**A degradation stub can now be checked by name.** Nine addons hand-write a `settings/OptionsSetup.lua`
arm mirroring the `LibKa0s-Options-1.0` surface — 185 to 384 lines each — and only three of them own a
parity case at all, which is how AbsorbTracker's stub omits `SetRenderer` outright with every suite in
that repository green. `Kit.assertSurfaceParity` has been here since revision 8 and went unadopted
because its four-argument form asks the caller to produce the live half first: a grep, a derivation,
and a comment explaining the derivation. It now also takes
`assertSurfaceParity(stub, "LibKa0s-Options-1.0", ignore)` — a string in the second position selects
the form — and resolves the live half itself. The original form is unchanged down to its message text.

**What it compares is the PUBLIC surface**, `Kit.publicMembers`: every string key that is neither
LibStub bookkeeping (`MAJOR`, `MINOR`, `MODULES`) nor `__`-prefixed. No stub in this collection
carries those and none should — `MAJOR` and `MINOR` are how the library answers "which copy am I",
and the `__` keys are a major's internals reached by a sibling file inside the same major. Reported
raw, the Options major alone hands a stub author ten divergences that are all correct omissions, and
a gate whose first run is ten false positives acquires an `ignore` list the size of its own output.

**The harness says where a name resolves**, because the kit cannot know: it has no LibStub, no mock
and no addon namespace, and `loader.lua` hands each chunk a mocked environment rather than writing
into `_G` — a kit reaching for `_G.LibStub` would resolve nothing headlessly and pass every stub.
`Kit.setSurfaceSource` takes a callable (`mocks.LibStub`, answering the library table) or a table
(`{ ["LibKa0s-Options-1.0"] = NS.Helpers }`, for the far commoner case where the stub mirrors the
INSTANCE `lib:New(descriptor)` returned, which the kit could never build for itself). `Kit.expose`
wires the callable shape when the exposed table already carries a mock with a LibStub on it, and only
when nothing is registered yet. An unresolvable name is a **failure** naming the fix, never a quiet
pass — the bargain `assertSuiteInventory` already strikes.

**And each major now publishes its member list as data**, at
`docs/api/<Major>/members-<versionKey>.json`, generated from the live surface by
`tools/gen-api-members.lua` and regenerated-and-compared on every run by `tests/test_versioning.lua`.
`docs/api/` was the source of truth for every public contract and it was prose in every document:
accurate, versioned, and not something a stub could be compared against. It is keyed by version like
everything else in that directory, because a single file describing only HEAD answers the wrong
question for every consumer that has not re-vendored yet. LibKa0s carries the reference
`tests/test_surface_parity.lua` itself rather than asking nine repositories to write a case this repo
does not run.

**The line-ending gate reads the whole tracked set, and every consumer inherits it.** `test_eol.lua`
has been this repo's own suite since revision 10, written beside the fix to the bundle writer, and it
asked git about `docs/automated-tests/` and nothing else — 176 of 508 tracked paths here. That scope
is the entire finding: `line-endings-§7` MUSTs the pin be checked mechanically, ten of ten
repositories fail it, and the one repository that owned a gate ran it green over the directory that
was already clean. Two of the files it could not see are `LibKa0s/DebugLog.lua` and `LibKa0s/Pool.lua`
— the SHIPPED payload — which is why `diff -r LibKa0s <Addon>/libs/LibKa0s`, a SHOULD-be-empty check
in [`docs/releasing.md`](docs/releasing.md), reported thousands of phantom lines in nine repositories
on every re-vendor. A shell redirect is not the only way to write a file past git's clean filters —
sed, an editor across a WSL mount, any generator that opens a path for writing — so the set to hold
to the pin is the set git tracks.

**It moved into the kit rather than being re-typed nine times**, which needed two small things from
`framework.lua`. A suites entry may now carry its own `dir` —
`{ name = "test_eol", dir = "tests/_kit/" }` — and `loadSuites` calls each suite chunk with the kit as
`...` instead of `dofile`ing it, because a kit-shipped suite cannot read an exposed table whose global
name belongs to the consumer. `Kit.assertSuiteInventory` now scans `tests/_kit/` for suites as well as
`tests/`, so a kit suite that lands in a re-vendor and is never wired is a **red** naming the entry to
add rather than a green run over a gate that never executed. One shell-out answers `text` and `eol`
for the whole repository, because asking per path cost about nine seconds a run in ten repositories,
which is the price at which somebody adds a flag to switch a gate off.

Widening that gate to two directories pushed `Kit.assertSuiteInventory` to CCN 20, which the release gate refuses at 15, so it is split here into the four pieces it had grown into: the suites list folded into its lookups, a listing that fails rather than reading an unlistable directory as an empty one, and one collector per direction. Behaviour is unchanged and all three failure messages are word for word what they were — which is how the split was checked, by planting each of the three violations in turn and reading the message back.

**Consumers should expect the record to move on the first run after re-vendoring**, and the count to
move by one: a middle figure in the Tests column, the replaced lead-in, and a watch list with every
disposition blank because there was no generated table to carry them forward from. Expect the EOL
gate itself to be red until the working tree is repaired — `rm <path> && git checkout -- <path>`, per
path it names — because being red there is the whole reason it was widened. Ruling on those
blanks is a one-time cost. Any hand-written prose below the table is replaced, so a disposition worth
keeping is copied into the generated cell in the same commit or it is gone.

### US English across the shipped payload, and a prose gate that uses the published list

**Twenty-seven authored spellings in `LibKa0s/` and `testkit/` were British, and five of them were
text a player reads.** `Perf.lua` wrote `run CANCELLED` to the log and `perf run |cffcc5252CANCELLED|r`
to chat, and reported a capture with no label as `unlabelled` in three places — the report header,
the started line and the announcement. They are `CANCELED` and `unlabeled` now. The other
twenty-two are comments in `DebugLog.lua`, `Options.lua`, `OptionsCompose.lua`, `OptionsWidgets.lua`,
`Perf.lua`, `Slash.lua` and `Widgets.lua`, and prose in the kit's `README.md`, `mock_base.lua` and
`run-automated-tests.sh`. Nothing else moves: no behavior, no signature, no minor.

**The gate that was supposed to catch all of that had six substrings of its own choosing** —
`colour`, `grey`, `behaviour`, `synthesise`, `normalis`, `recognis` — two of which are not in
`localization-§5`'s own table at all. Run over the three spellings live in the payload it matched
zero, which is how `CANCELLED` shipped in chat text for months under a green suite. That is
`testing-§12`'s failure mode, a check that reads as coverage and provides none, sitting inside the
gate for `localization-§5`. The section now publishes the canonical pair — 91 `BRITISH` substrings
and 30 `ALLOWED` words — and requires a gate to carry both whole, so `tests/test_prose.lua` copies
them rather than inventing a seventh opinion. `ALLOWED` exists because the substrings are small on
purpose: *analysis* contains `analys` and *programmer* contains `programme`, so the correct US words
are stripped **as whole words** before the substring scan runs.

**One exemption, and it is ratified rather than hidden.** `lib.ICONS`'s `minimise` key stays. It is
not prose — `lib.Icon` builds the texture path from the key and the file on disk is `minimise.tga`,
vendored into every consumer's `libs/LibKa0s/media/icons/`, so a renamed key alone points at a
texture that does not exist and that failure is silent by construction. The exemption is named by
path and by the exact spelling it covers, never by a pattern, it carries a row in `CLAUDE.md`'s
`## Documented deviations`, and the gate reddens if it ever stops matching — an exemption nobody can
see expire is how this gate got here in the first place.

**Consumers get this on the re-vendor and have nothing to adopt.** The only visible difference is the
wording of the two `perf` lines and the three unlabeled captures.

### `Perf.lua` minor 8 — the capture arm stops allocating, and the spec reader gets its namespaced rung

**Nothing on the surface moves.** No member is added, removed or re-signatured; every adopter gets
this on the re-vendor and has nothing to adopt. What moves is two internals, and both are the same
kind of defect: something the file claimed about itself that was not true.

**`P.Open` allocated a table per bracket while the probe was on.** `{ key = key, t0 = ... }`, once
per `Open`, for the length of a window — so one table per bracketed call, on paths that are
bracketed precisely because they run often. The collector then walks that garbage during the very
capture whose entire job is to hold everything else still and read somebody else's frame cost, which
is the probe perturbing the thing it is measuring. The open slots come from a **high-water free
list** now: one table per nesting depth, built the first time a session nests that deep and reused
by every bracket after it. Depth is two in every descriptor this collection ships, so the list stops
growing almost immediately and the steady state allocates nothing on either arm.

Behavior is otherwise identical. A bracket whose exit forgot its `Close` is still **discarded**
rather than credited with time it never ran for — the slot is simply left above the open depth,
where nothing reads it and the next `Open` at that depth overwrites it in place. `P.Reset` zeroes
the depth and deliberately keeps the list, since emptying it would make the first brackets of every
run allocate again, which is the one cost this shape exists to pay once.

**The suite only measured the arm that was already free.** `tests/test_perf_isolation.lua` held a
dormant-bracket case asserting that 10,000 `Open`/`Close` pairs with the probe **off** grow the heap
by under 1 KB, and nothing at all for the arm a capture actually runs — which is the arm that was
allocating. The active sibling is there now, at the same ceiling: **0.0 KB over three runs, against
1406.2 KB before the free list.** `performance-§2` asks for the "instrumentation is free when off"
claim to be a measured number rather than a comment; this is the other half of that bargain, and the
docstring on `P.Open` states the active arm's cost in the same place it already stated the dormant
one's.

**`P.Context` read the spec through the bare `GetSpecialization`.** `Env.lua` has modeled the
two-rung shape for `C_AddOns` since it was written — the namespaced reader wherever it exists, the
deprecated global where it does not — and this file had only the global. That is exactly why it was
easy to miss: the global still answers on today's client, so nothing is visibly wrong. The day it
stops answering, every saved record names the spec `"?"`, and a record is read weeks later, when
there is nothing left to go and look at. `C_SpecializationInfo.GetSpecialization` is taken first now.
`GetSpecializationInfo` keeps its own guard on the global rather than being paired with a namespaced
rung, because the reader known to have moved is the **index** one and a shim that claims more than
it has checked is the defect being fixed.

## v1.26.0 — 2026-09-07

Versions in this release: **Core minor 7**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 9**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 14**,
**OptionsWidgets minor 14**, **OptionsCompose minor 3**, **OptionsScroll minor 3**, **Perf minor 7**,
**PerfPanel minor 4**, **kit revision 14**.

Two files moved: `OptionsCompose.lua` and `OptionsWidgets.lua`. Everything else is byte-identical to
v1.25.0. Both are silent shipped faults rather than new surface — one emptied every composed media
dropdown in every consumer, the other leaked a set of frames per tab click — so this release adds
nothing to adopt and asks for nothing but the re-vendor.

### `OptionsCompose.lua` minor 3 — the composed media dropdowns actually have options in them

**Every font, border and bar-texture dropdown these composers wrote was empty in the client, in
every consumer, from v1.24.0 onward.** `O.LSMValues(mediaType)` already returns the deferred closure
the flow engine wants, and its own docstring says why the deferral is load-bearing: an LSM-backed row
is a schema-row literal evaluated at file load, long before the addons that register media have run.
The three group composers wrapped that closure a second time — `values = function() return
O.LSMValues("font") end` — and `enumList` unwraps a row's `values` exactly once, so it got a function
where it expected a table and handed back `{}`.

Nothing reported it. The *"no options"* warning is gated on `row.values == nil`, which is the guard
that keeps a legitimately-empty deferred list quiet while media is still loading; a doubly-wrapped
row is not nil, merely useless, so the dropdown opened on nothing in silence. That is how this
shipped past a green suite, and the four cases written the item before this one are what make it
impossible to ship again.

The fix is three lines — the row carries `O.LSMValues("font")` itself — and it adds, removes and
renames nothing.

### `OptionsWidgets.lua` minor 14 — the tab strip stops leaking a set of frames per click

**An options panel left open leaked one full set of tab buttons plus one content panel every time
the player clicked a tab, for the life of the session.** `TabStrip` releases the strip and redraws it
on every click; the redraw called `CreateFrame` per tab and once more for the panel, while the
release only hid and unparented. WoW destroys no frame, so nothing was ever reclaimed.

Nothing about it was visible. The panel drew correctly every time, every case in the suite stayed
green, and the only symptom was a client that got heavier the longer settings stayed open — the same
shape, and the same silence, as the hand-rolled pool leak that got `LibKa0s-Pool-1.0` extracted in
the first place. This library published that pool at minor 3 and was the one repository in the
collection not using it; four consumers already do.

Each `ctx` now carries a `__tabPool` and a `__panelPool`, and `TabStrip` acquires from both.
`makeTab` splits in two: `newTabButton` builds only what a selection cannot change — the button, its
six textures and its font string — and `dressTab` re-applies everything that is per-tab, **`OnClick`
included**, because the handler closes over that dress's selection and tab key. The tooltip moved to
a `SetScript` pair set once at construction and re-aimed per dress: `O.AttachTooltip` takes the
`HookScript` arm for a raw button, and `HookScript` accumulates, so a re-dressed button would have
grown a pair of handlers per click — the same unbounded growth, moved from frames to scripts.

`SubTabStrip` is deliberately left unpooled. Its buttons hang off a frame AceGUI takes back, so they
must be unparented on release, and an unparented button off a free list is a button drawn onto
nothing.

`ctx.__tabKids` keeps its meaning — this render's furniture in draw order — and is now purely a
ledger; the pools do the release.

**One new floor, satisfied by construction.** `OptionsWidgets.lua` requires `LibKa0s-Pool-1.0` minor
≥ 1 and is absent rather than degraded without it, the way `DebugLog.lua` is without `Widgets`.
Degrading would mean falling back to allocating per click in silence, which is the defect this minor
ends. `Pool.lua` ships in the same payload and loads first in `LibKa0s.xml`, so whole-folder
re-vendoring — which is mandatory anyway — satisfies it.

**Adoption is the re-vendor and nothing else.** No member, signature or return value moves. The
strip renders the same pixels; what changes is how long its frames live. Because the headless proof
is a `CreateFrame` count and the harness cannot see geometry, the in-client check belongs to the
adoption wave: open every multi-tab panel, cycle its tabs, and confirm labels, selection state and
band height are unchanged.

**One contract tightened, and it is silent, so read this before re-vendoring.** `lib.__AttachCompose`
lets a host supply its own `O.LSMValues`, and that member **must return a function**. Until now the
composer called it inside a closure at dropdown-render time, so a host whose `LSMValues` returned a
*table* worked by accident — late evaluation covered for it. The composer now reads the member once,
at row-declaration time, so a table-returner lands a literal table frozen at file load: no error, no
warning, and exactly the failure the deferral exists to prevent. A consumer that assigns
`C.LSMValues = function(t) return lsmValues(t)() end` must pass the reader itself instead, in the
same change as its re-vendor. A consumer that never touches the member, or that overrides a composed
row's `values` afterwards, is unaffected.

## v1.25.0 — 2026-09-03

Versions in this release: **Core minor 7**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 9**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 14**,
**OptionsWidgets minor 13**, **OptionsCompose minor 2**, **OptionsScroll minor 3**, **Perf minor 7**,
**PerfPanel minor 4**, **kit revision 14**.

One file moved. Everything else is byte-identical to v1.24.0.

### `OptionsCompose.lua` minor 2 — `MasterControls` takes a `leadButton`

**`§15` fixes the wording of the two reset buttons, and this composer is the only thing that writes
it.** An addon with a verb of its own to put beside them therefore had nowhere to put it: PrettyChat's
*Test* — which prints a sample of every active format string — sat on its own row above *Reset all
settings*, and moving it alongside would have meant the addon drawing the pair itself, keeping a
second copy of *"Reset all settings"* and its tooltip in its own source. That is precisely the drift
this composer was extracted to end, so the answer is a seam rather than a copy: the verb is handed
**in** as `leadButton = { text, tooltip, onClick }`.

**Where it lands is arithmetic, not taste.** A **frameless** addon's pair has exactly one empty cell —
the right half `§15` leaves when there is no *Reset position* — so the verb leads and the reset still
closes the tab: `[Test] [Reset all settings]`. A **framed** addon's pair is already full, and `§15`
forbids splitting or reordering the canonical two, so there the verb takes its own row **above** the
pair rather than displacing a reset. Nothing draws three buttons on one line.

It is **one** button and not a list, because the tab closes with the resets; a row of host verbs
before them is a different design and `§15` does not describe one.

Additive: a host written against 14.13.1.3 is correct here unmodified, and the field's absence is the
old behaviour exactly.

## v1.24.0 — 2026-09-02

Versions in this release: **Core minor 7**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 9**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 14**,
**OptionsWidgets minor 13**, **OptionsCompose minor 1**, **OptionsScroll minor 3**, **Perf minor 7**,
**PerfPanel minor 4**, **kit revision 14**.

**One release, re-vendored into all nine addons at once.** The settings revamp touches four majors
and adds a fifth file, and shipping it in pieces would have given nine parallel implementers four
different libraries to reason about during the one week they are all editing.

### `LibKa0s-Options-1.0` minors 14/13 and the new `OptionsCompose.lua` at 1

**The tab strip's geometry no longer depends on which tab is selected.** This is the reported R4c
defect and it is arithmetic, not art. The selected tab is cut from `Options_Tab_Active_*` and every
other tab from `Options_Tab_*`, and the client does not draw the two families at the same height.
`TabStrip` seeded the wrap pitch from the FIRST tab it built — `ctx.__tabArtH = ctx.__tabArtH or
artH` — so on a page whose strip **wraps**, selecting tab 1 packed the rows by the active art and
selecting any other packed them by the inactive art. That pitch feeds both `__tabPlacement`'s row
offsets and `__tabBand`'s reserved height, and `SetChromeHeight` re-anchors the scroll and the
content panel off the band — which is exactly the reported "a gap opens between the wrapped rows,
and the content container shifts and resizes". It is invisible on an unwrapped strip, because the
pitch is multiplied by (rowCount − 1) = 0. Reported from a client against ConsumableMaster's Macros
page and again on its Macro Bar page.

The pitch is now measured **once**, from the **inactive** cap atlas, on a throwaway texture — never
read back off a tab that was just drawn in whichever state it happened to be in — and cached on
success only, so a call made before the client can answer does not pin the fallback for the session.
`ctx.__tabArtH` and `rowPitch(ctx)` are gone; `drawTabSlices` measures nothing and `drawTabArt`
returns nothing. Each button's `SetHitRectInsets` now takes the **same** number the rows are packed
by, so the invariant its own comment states holds for the selected tab too instead of for all but
one button per strip. `setTabLabel` no longer applies the selected font: a tab's width is measured
off its FontString, and a measurement taken under a selection-dependent font is a wrap index that
moves with the selection. The two fonts are the same size today; pinning the order is what keeps
that true rather than lucky. `O.__tabArtHeight` and `O.__resetTabArtHeight` are published as suite
seams, because the invariant a test has to pin is unassertable without the one number both the band
and every row offset are built from.

*The direction of the residual is worth measuring in a live client once.* Packing by the inactive
height leaves the selected tab's art standing a pixel or two proud into the row above, which is the
direction `TAB_BG_TOP` and `TAB_LABEL_Y` already lift it deliberately. If the active art turns out
to be the *shorter* of the two, the residual disappears entirely and nothing else changes.

**Every page draws a strip, including a page with one section.** `RenderTabbedSchema`'s `#groups <
2` fallback to `RenderSchema` is deleted. "A single tab is chrome for its own sake" is a true
sentence about one page and the wrong rule for a panel: a player moving between pages meets a strip
on most of them and bare rows on the rest, and the page that lost its strip is the one that looks
broken — and the tab is also the only thing naming the group once `noHeadings` has suppressed the
heading, so the fallback took the section's name off the page as well. The one exemption is a page
the host does not render through this engine at all, which today is the AceConfig-drawn Profiles
page; it needs no mechanism, because it never reaches the function. No opt-out flag is offered — a
flag is a thing an addon can set for the wrong reason, and there would be no way to see it in a
test. A page with **no** groups is a different decision: it is reported by name and then rendered
untabbed, because a blank page under an empty strip is a worse failure than a strip-less one.

**Visible change for a one-group page:** it gains a strip and its content moves down by the band. In
the collection that is LootHistory's AH Price page and nothing else routed through this function.
Every page with two or more groups is byte-identical.

**Three new row fields.** `subgroup` draws a heading INSIDE a tab and is *not* suppressed by
`noHeadings` — a tab that mixes bar rows, background rows and border rows has to say where one stops
and the next starts, and there is no tab left to name them with. It uses `O.Section`, the same
AceGUI Heading every other header uses; two heading looks on one canvas is the drift the shared
library exists to end. `wide` renders a row alone at FULL width, which `solo` does not do — `solo`
renders alone in the LEFT HALF — and it takes `RenderGrid`'s existing name rather than redefining
`solo`, which would silently widen every solo row in nine shipped addons. `startsLine` flushes the
pending line *before* a row, so a declared pair — a color swatch and its class-color companion — can
never be split across two lines by an odd number of widgets above it. That parity was a thing every
author was counting by hand.

**Two new members, both seams the revamp needs.** `O.PageHeader(ctx, spec)` pins a host-drawn block
in the band the page banner occupies, for controls that apply to every tab: drawn under one tab they
read as belonging to it, and they vanish the moment the player clicks another. It generalises the
BAND rather than the banner, because `O.PageBanner` draws exactly one Dropdown and is documented as
the page's only picker; the two release the same ledger and write the same `ctx.__bannerHeight`, so
a page gets at most one chrome block and the second call replaces the first. `O.SubTabStrip(ctx,
parent, spec)` draws a SECONDARY strip inside the scroll as ordinary page content, with its own
ledger and its own state key — the primary strip is pinned and does not scroll, while a secondary
division belongs to the content it divides. It packs by the same selection-invariant pitch.

**An empty dropdown now reports itself.** A `type = "string"` row with neither `values` nor
`dialogControl` is a free-text field that forgot to say so: the dispatch sends it to the dropdown
maker and the player gets a control that opens on nothing. The opt-in stays — inference would
silently turn a row whose values function answers empty into a free-text field, which is the
deferred-media case the opt-in exists for — so the warning is keyed on `values` being **nil**, and
an LSM-backed closure that is momentarily empty stays quiet. KickCD's `Label text` is the one
shipped instance in the collection.

**`OptionsCompose.lua` is new, and it is a schema generator rather than a renderer.**
`O.ColorPair`, `O.FontGroup`, `O.BorderGroup`, `O.BarGroup` and `O.MasterControls` each expand one
declaration into the canonical block of ordinary schema rows. Every composer is a **pure function**:
it creates no widget, touches no AceGUI, reads no state and never writes to the spec it was handed.
That is the whole design — what comes out is indistinguishable from hand-written rows, so
`rowsForPage`, `applyDefault`, `RestoreDefaults`, the CLI and the reset sweep all keep working with
nothing added to them, and the composers are testable with no mock at all. Nine hand-written copies
of the same six font rows is exactly the drift this library was extracted to end, and the day the
block grows a row it grows in one addon.

`O.FONT_FLAGS`, `O.FONT_FLAGS_SORT`, `O.VISIBILITY_VALUES`, `O.VISIBILITY_SORT`, `O.MASTER_GROUP`
and `O.CLASS_COLOR_NOTE` are published on the instance, not on the lib table, for the reason the
layout block gives: a lib-level table is shared by every instance, so handing it out lets one host's
mutation retune every other host's dropdowns.

`Options.lua` gains the `lib.__AttachCompose` call, guarded like the other two so a copy vendored
without the file degrades to no composers rather than erroring at `:New`, and `O.ClearScroll` now
resets `ctx.lastSubgroup` alongside `ctx.lastGroup`.

### `LibKa0s-Core-1.0` minor 7 — one class-color resolver for the collection

`lib.ClassColor(unit)` and `lib.ResolveColor(stored, on, unit)`. Three implementations existed and
two of them disagreed about the source: AbsorbTracker read `C_ClassColor.GetClassColor`, PanelMaster
and MultiMeters read `RAID_CLASS_COLORS`. `RAID_CLASS_COLORS` wins, and not by coin toss — it is the
table every other UI on the player's screen is already reading, so it is what the unit frames next
to ours are showing.

**`nil` is an answer.** An NPC, an unresolvable unit, a class the client has not named — none of them
is a color, and substituting one invents a hue nobody chose, appearing only in the cases nobody
tests. The player's own answer is memoized on **success only**, so a class that has not resolved yet
resolves on the next read; **no other unit is ever cached**, because a target's class changes every
time the player retargets and a per-unit cache would need invalidating on two events to save one
table index.

This ratifies three rules that were already unanimous across the three implementations it replaces
and written down in none of them: **the configured alpha survives the mode** (no class-color source
carries an alpha), **an unresolvable class falls through to the stored swatch** rather than to a
default, and **the swatch is read under both modes**, which is why a color row must never be
`disabledIf` its companion. The stored value goes through `lib.RGBA`, so both persisted shapes work
here exactly as they do everywhere else.

*Not moved into the library:* AbsorbTracker's darkened background palette. That is a different set
of hues, not the class color times a constant, and the two must not be substituted for each other.

### `LibKa0s-Widgets-1.0` minor 9 — `ReorderList` grows the row box

**A deliberate reversal, recorded as one.** Minor 8 said the widget owns "the handle, the copy that
follows the cursor, the insertion line, the index arithmetic, the clamp, and nothing else". It now
also owns the **row box** — the faint fill and the hairline border that make a stack of rows read as
blocks you can pick up. "A draggable row looks like this" is a property of the *collection*, and a
property of the collection cannot live in two consumers' private code. It did: MultiMeters drew a 6%
white fill and no border, ConsumableMaster drew nothing at all, and that is the drift.

`lib.ROW_BOX` publishes the values so an audit can read them and a consumer never restates them:
`FILL` `{1,1,1,0.06}` (MultiMeters' shipped fill, now everyone's), `EDGE` `{1,1,1,0.12}` at 1px on
all four sides — the border nobody had — with `FILL_DIM` / `EDGE_DIM` at half for a row that is
present but inert, and `HANDLE_W` **30**, the gutter the handle owns at the row's far left. New
`opts.rowBox` (default **true**) and `opts.rowBoxInset`; new `spec.dimmed` on `AddRow`; the handle's
default width moves 24 → 30.

**A frame carrying five textures, not five textures on the host's frame.** Both consumers hand over
frames their UI framework pools, and a texture is not a widget: nothing releases it and nothing hides
it, so one created on a pooled frame rides that frame back into the pool and reappears the next time
it is handed out for something else. That failure is already written down one widget over, in the
landing-page logo. Boxes are pooled and reclaimed on `Cancel` on exactly the same terms as the
handles, through one shared `reclaim` — a `Cancel` that reclaimed only half of them would be a fix
that looked complete.

**The row's CONTENTS are still entirely the consumer's** and nothing about `AddRow`'s content
contract changes. What moved is the box under them. The handle art still arrives as a resolved path,
for the reason stated at the top of that file: `Media.Icon` takes the consuming addon's name and a
vendored copy cannot know which folder it sits in. No new icon is added and `LibKa0s-Media-1.0` does
not move — a nine-repo re-vendor for art the catalogue already has would be a cost for nothing.

**Re-vendoring this changes the look of MultiMeters' Columns page immediately.** That repo MUST
delete its own `block.bg` fill in the same commit as the re-vendor, or the two fills stack.
ConsumableMaster has nothing to delete. `rowBox = false` exists for a consumer that must keep its
own, and no consumer in the collection uses it.

### Degraded installs

With the Widgets major absent there is now no handle **and** no box. That is an accepted cosmetic
degradation, stated here so nobody re-solves it host-side: a host-drawn box is the drift this change
exists to remove.

## v1.23.0 — 2026-08-31

Versions in this release: **Core minor 6**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 8**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 13**,
**OptionsWidgets minor 12**, **OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**,
**kit revision 14**.

**`LibKa0s-Options-1.0` minors 13/12 — the content box stops touching its own contents, and
wrapped rows of tabs sit flush.**

Two things a client showed that v1.22.0's arithmetic could not. Neither is a new member; both are
geometry the headless suite had no way to be wrong about, because a headless chrome has no width
and a headless atlas has no height.

**A box has to be outside everything it contains.** v1.22.0 anchored the `Options_InnerFrame`
panel on the content column's own edges — the same `CONTENT_LEFT` / `CONTENT_RIGHT` the widgets
use. So the left-hand row labels butted against the left border, and AceGUI's always-shown
scrollbar, which sits *outboard* of `CONTENT_RIGHT` by design, was painted on top of the right one.

The panel now has its own three insets — `PANEL_LEFT`, `PANEL_RIGHT`, `PANEL_BOTTOM`, all smaller
than the content column's — and is anchored horizontally to `ctx.body` rather than to `ctx.chrome`.
The tab strip stays on the content column, which leaves the leftmost tab a few pixels inside the
box's left edge: OPie's arrangement, and the reason its tabs read as sitting *on* the panel rather
than as being its top row.

**A wrapped strip packs by the ART's height, not the button's.** A tab button is 37px carrying an
atlas that is shorter, and the difference is the foot that overlaps the panel — so the empty strip
along each button's top was standing between two rows as a visible gap. The atlas's height is only
knowable from the client, so `drawTabSlices` now measures it (`GetHeight` after `SetAtlas(name,
true)`) and the strip packs rows by that number.

Two consequences worth stating. The next row's button overlaps the previous row's art by exactly
the empty amount, so each button takes a `SetHitRectInsets` that removes its own empty top from the
mouse — without it, row 2 would swallow clicks aimed at row 1. And `__tabBand`'s shape changes to
**(n − 1) pitches plus one whole tab**: every row but the last contributes only its pitch, because
the next row overlaps it, while the last must fit whole since its bottom is the edge the panel
starts at.

`TAB_ROW_GAP` is retired. A measured pitch is not a height plus a gap, and keeping a gap constant
beside it would be two numbers for one decision. `__tabPlacement` and `__tabBand` both take a
`rowPitch` where they took a `tabH` and a `rowGap`; both fall back to `TAB_H` where nothing can be
measured, which is exactly the pre-measurement behavior with no gap.

**Untabbed pages remain untouched.** The panel is still drawn by `TabStrip` and nothing else.

## v1.22.0 — 2026-08-31

Versions in this release: **Core minor 6**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 8**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 12**,
**OptionsWidgets minor 11**, **OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**,
**kit revision 14**.

**`LibKa0s-Options-1.0` minors 12/11 — the tab strip stops imitating client chrome and starts
using it, and a first-render wrap bug goes with it.**

v1.21.0 drew tabs from `Interface/OptionsFrame/`, the client's *old* tab textures. They were the
right idea and the wrong art: those files have sloped transparent shoulders, so a 4px gap between
two tabs read as twelve, and the 1px rule under the strip read as a line the tabs happened to be
sitting near rather than as the edge of anything.

**The reference implementation is now OPie's `Libs/TenSettings.lua`**, and this release copies it
rather than approximating it — the `Options_Tab_*` / `Options_Tab_Active_*` atlases, three slices
a tab with the end caps at natural size, the dark gradient backing, the two glows, the label
anchored to the tab's bottom, `GetStringWidth() + 40`, and a 37px tab. One deliberate departure:
OPie chains its tabs leftward from the frame's right edge and this strip packs them left to right,
because a strip that wraps has to grow downward from a fixed origin and the left edge is the one
the content column already uses.

**The tab/content separator is now a real panel edge.** `TabStrip` draws the client's
`Options_InnerFrame` behind the page — two halves meeting at the midpoint, the left one mirrored
by a reversed u range so both corners stay crisp — anchored to the chrome's bottom and running to
the content's own bottom inset. The selected tab is 37px tall against art that is shorter, and the
difference is a **foot** that lands on that panel edge and merges into it. That merge is the thing
a hairline could not do: three attempts at a 1px rule all read as disconnected, because a line is
not an edge of anything.

`TAB_BASELINE_H` is therefore gone and `__tabBand` no longer reserves it. A panel drawn *below*
the band must not also be reserved *inside* it, or the page opens a one-pixel gap under its own
tabs. `CONTENT_BOTTOM` replaces the literal `8` that `anchorScroll` used, so the scroll and the
art behind it cannot end in different places.

**Untabbed pages are untouched.** The panel is drawn by `TabStrip` and by nothing else, so the
eight consumers that have never called it render exactly as they did at v1.21.0.

**The first page a player opened stacked its tabs vertically.** `ctx.chrome` has zero width until
the settings canvas lays itself out, and the first render happens before that: `placeTabs` read
`0`, fell back to `TAB_MIN_W`, and every tab wrapped onto its own row. It healed the moment you
clicked any tab, because the second render measured a real width — which is exactly why it
survived a suite that only ever rendered twice.

A width cannot be computed from config here; it is the canvas's, and the canvas is Blizzard's. So
the strip re-places itself when the width arrives, through an `OnSizeChanged` script installed once
per panel. Two things keep that from looping: the handler ignores everything but a *change* in
width, and `placeTabs` records the width it used — so the height change `SetChromeHeight` causes,
which fires the same script, is a no-op. The handler reads the current layout out of `ctx` rather
than closing over one strip's buttons, which would pin a released set of buttons alive and
re-place them after they were hidden.

`O.EnsureDefaultsButton` has carried a note about `ctx.body` having zero width at enable time since
minor 7. This is the same client behavior reaching a second piece of chrome, and the note there is
why it was recognized rather than debugged.

**`TAB_H` moves 24 → 37 and `TAB_PAD_X` 18 → 20.** `TAB_H` is published, so a host that reserves
room beside a strip reserves 13px more; nothing else in the surface moves, and no member is added
or removed. `TAB_PAD_X` has now been too small twice — at 12 the label sat on the end cap outright,
at 18 it cleared the cap but left the tabs cramped against every other tab strip in the client.

**`drawTabArt` and `makeTab` were split four ways and two.** Both measured CCN 17 against a release
gate of 15, for the dullest possible reason: every texture path in this file carries the same two
guards, and a function wearing all of them adds a branch per texture. The split is by what the
textures *are* — slices, backing, glow, label — not by line count.

## v1.21.0 — 2026-08-31

Versions in this release: **Core minor 6**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 8**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 11**,
**OptionsWidgets minor 10**, **OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**,
**kit revision 14**.

**`LibKa0s-Options-1.0` minors 11/10 — the tabbed page chrome, seen in a client and fixed there.**

v1.20.0 shipped tabbed pages and a page banner. Everything here comes from looking at that feature
running in the client, which found one bug that no headless suite could have found and three ways
the chrome did not look like the UI it was sitting in. Nothing in this release is a new public
member: a consumer re-vendors and gets the same API, drawn better.

**The strip was drawn on top of the banner, and every tab was unclickable.** `placeTabs` derived
row 1's y offset from the row index alone, which put it at `ctx.chrome`'s `TOPLEFT` — the anchor
`PageBanner`'s dropdown already occupies. The band was *reserved* correctly the whole time; only
the placement ignored the reservation, which is exactly the shape of bug a band-reserving test
passes over. The arithmetic is now `O.__tabPlacement`, a pure rows-to-pixels mapping over numbers,
the same seam `__layoutTabs` already gave the wrap decision, and `placeTabs` does nothing but apply
it with `ctx.__bannerHeight` folded in as the `top` term the inline math never had.

`PageBanner` also stopped forcing its dropdown to `BANNER_H`. It measures the frame and floors at
that number instead, because a Dropdown carrying a label renders taller than a bare control and the
forced height was clipping it. `BANNER_H` moves 30 → 44 to match, and now describes a floor rather
than a fixed height.

**The chrome band spans the content column, not the panel.** `CreatePanel`'s chrome anchor and
`anchorScroll` both read `L.CONTENT_LEFT` / `L.CONTENT_RIGHT` from one seam, so a banner can no
longer run wider than the scroll under it — which it visibly did, and which no test could see
because a headless chrome has no width.

**A gap, a hairline and a second gap separate the banner from the strip** (options-ui-§14), drawn
by `PageBanner` and folded into `ctx.__bannerHeight` by the new pure `O.__bannerBand`, so `TabStrip`
never re-derives that arithmetic.

**Tabs are cut from the client's own tab art.** The three-slice `UI-OptionsFrame-InActiveTab` /
`-ActiveTab` pair the client's own tab template uses — two 20px end caps and a stretched middle —
with the client's `UI-Character-Tab-Highlight` glow on hover. The selected tab hangs 3px lower, so
its foot covers the strip's baseline and the tab joins the page below it; that merge, not a color
change, is what makes a row of buttons read as tabs. The strip's baseline is drawn in the neutral
gray the client borders a panel with rather than in gold, because it is the top edge of the content
area and not a separator between two pieces of chrome.

This is the one place in `OptionsWidgets.lua` that prefers a Blizzard texture to a drawn one, and
the reason is that here the look **is** the requirement. A tab is a piece of client chrome a player
already recognizes, so an approximation reads as a near-miss in a way a drawn slider or a drawn
section rule never does. The first attempt — flat fills and four 1px gold edges per button, shipped
through the branch — was legible, correct, and unmistakably not part of the UI around it.
`TAB_PAD_X` moves 12 → 18 so a label clears the 20px end caps; at 12 the text sat on the rounded
shoulder, which was half of why a tab read as a bordered rectangle.

**Every piece of new furniture travels in the ledger that matches its lifetime.** The banner's
divider is in `ctx.__chromeKids`, redrawn only by a full page render; the strip's baseline is in
`ctx.__tabKids`, redrawn by every tab click. Put the baseline in the wrong one and a click that
shrinks the strip from two rows to one leaves the old line floating over the page's first setting.
Each tab's three art slices are children of the button itself, so `releaseLedger` takes them with it
and they need no ledger entry at all.

New `LAYOUT` keys — `CONTENT_LEFT`, `CONTENT_RIGHT`, `CHROME_DIVIDER_GAP_TOP`, `CHROME_DIVIDER_H`,
`CHROME_DIVIDER_GAP_BOTTOM`, `TAB_BASELINE_H` — are all internal-annotated. No host reads one, and
the published scalars (`CHROME_GAP`, `TAB_H`, `BANNER_H`) are unchanged apart from `BANNER_H`'s new
value and its new meaning as a floor.

## v1.20.0 — 2026-08-27

Versions in this release: **Core minor 6**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 8**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 10**,
**OptionsWidgets minor 9**, **OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**,
**kit revision 14**.

**`LibKa0s-Options-1.0` minors 10/9 — tabbed pages and a page banner, on a chrome slot that
costs an unadopting consumer nothing.**

MultiMeters' settings had reached 137 rows over nine pages, and the shape had run out: one
section held a single control, another held fifteen, and six pages edited whichever window a
picker two pages up had selected without saying so. Both fixes needed the same missing thing —
somewhere to put furniture that does not scroll away — and there was nowhere: `EnsureScroll`
anchored the `ScrollFrame` straight to the body's top edge.

**The chrome slot is a frame and a number, and the number starts at zero.** That is the whole
additive bargain. Eight consumers re-vendor this file without calling anything new, and their
scroll anchors where it always did, because `CHROME_GAP` is the literal `8` the old code used.

**One tab is exactly one group** (options-ui-§13). No second field names a tab, for the reason
§1 gives against a second widget selector: a tab list declared apart from the rows goes stale the
first time a section is renamed, and nothing says so. The wrap rule is a pure function over
widths (`O.__layoutTabs`) rather than something only a measured font can exercise, and a tab
wider than the strip is placed alone rather than dropped — losing one would lose a whole section
of a page silently.

**The banner carries the picker, and it is the only one** (options-ui-§14). A page that had one
deletes it. Two controls over one piece of session state is a synchronisation problem the design
invented and would then own forever.

The tab switch re-enters `RenderTabbedSchema` through `ClearScroll`, the same structural path a
change of subject takes — but that path carries no combat refusal to inherit. `options-ui-§2`'s
guard lives in the host renderer's `OnShow` and covers the category switch Blizzard protects;
redrawing widgets inside an already-open panel was never a protected action, so a tab click needs
no guard here, and none is added (options-ui-§13).

## v1.19.0 — 2026-08-27

Versions in this release: **Core minor 6**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 8**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 9**,
**OptionsWidgets minor 8**, **OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**,
**kit revision 13**.

**`LibKa0s-Widgets-1.0` minor 8 — `ReorderList`, drag-to-reorder for any list, owning the gesture
and none of the rows.**

Two addons wanted the same thing at once. MultiMeters' Columns page had just been rebuilt around
drag-to-reorder, and ConsumableMaster's priority list wanted to retire its up-arrow / down-arrow
pair for the same gesture. That is the second consumer the collection waits for before a widget
earns its way in here — MultiMeters had recorded the deviation and the trigger in its own register
rather than promoting a one-consumer API on spec.

**It owns a gesture, not a list, and that boundary came out of what the two lists actually look
like.** MultiMeters' rows are a state glyph and a statistic name. ConsumableMaster's are a live item
tooltip, a crafting-quality glyph, a pick star, a score button and a remove button. Neither would
accept a widget that owned its row content, and a `render(row, item)` callback wide enough for both
is not an abstraction — it is a hole shaped like two addons.

So `ReorderList` owns the handle, the copy that follows the cursor, the insertion line, the index
arithmetic and the clamp. A host builds its rows however it already does — AceGUI containers, raw
frames, anything — registers each one with `AddRow`, and gets `onMove(from, to)` back. What the host
still decides: where the handle sits, how big it is, what art it wears, how tall a row is, and
whether the list has one group or two. What it does **not** decide is what a drag *looks* like,
because that is the part every list in the collection should share.

**The gesture is redundant on purpose, and that is the expensive lesson this carries.** It begins on
either `OnMouseDown` or `OnDragStart` and ends on any of `OnMouseUp`, `OnDragStop` or a poll of
`IsMouseButtonDown`; both helpers are idempotent. Two earlier implementations each picked one pair,
passed their own suites, and shipped a drag that did nothing at all in a Settings canvas. Which
scripts a client delivers there turned out not to be worth betting on.

**The poll may not act alone.** It has to see the button *held* before it may act on it being
released. An `IsMouseButtonDown` that is unavailable, protected, or simply not true yet on the first
frame would otherwise end the drag with zero rows travelled — no error, no message, and
indistinguishable from a press that was never received. That was the actual bug, and it took a
player's debug log to find it.

`Dropdown`, `CloseMenu`, `CopyWindow` and every one of their fields are unchanged. A host that does
not call the new member needs a re-vendor and no code change.

**The library owns its handles rather than caching them on the host's frames.** Both consumers hand
over containers their UI framework pools, and AceGUI's pool is process-wide — a released container
goes to whatever asks next. A handle cached on one and left shown turned up on an unrelated part of
the page: a *Drag to action bar* row, an ID entry box, a dropdown. A frame's identity is not the
host's to lend. Handles now come from a free list and `Cancel()` gives them back — hidden, unanchored
and reparented away — which also means **a host must Cancel before it renders anything**, not merely
before it rebuilds the list.

**`AddRow` takes `draggable = false`**, registering a row with no handle. It still counts for indices
and still anchors the insertion line: a place a drag can land, not one it can start from.

**Nothing about a drag closes over anything.** Both
consumers hand over a frame their UI framework pools, so `AddRow` re-points a cached handle rather
than building a new one; the handle reads its row at fire time; and `beginDrag`/`finishDrag` reach
the controller through `row.list`. All three are needed, and the third is the one that bites: a
handler closing over the controller that built it keeps calling that controller after the next
render `Cancel()`s it, which is a drag that works exactly once and then freezes.

**The handle takes a hover color and an optional tooltip**, so it says it is a control before you
press it. `handleColor`, `handleHoverColor`, `handleInset` and `handleTooltip` are all optional; the
hover default is the collection's gold, so a host that says nothing matches every other list.

**The shared mock grows a pointer.** `tests/wow_mock.lua` gains `GetCursorPosition`,
`IsMouseButtonDown` and their two setters, and `UIParent` gains a numeric `GetEffectiveScale`. New
globals rather than changes to existing ones, so no suite written against the base can observe the
difference — a drag nothing offline can drive is a drag that ships untested, which is exactly how
those two earlier implementations shipped.

## v1.18.1 — 2026-08-26

Versions in this release: **Core minor 6**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 7**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 9**,
**OptionsWidgets minor 8**, **OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**,
**kit revision 13**.

**`LibKa0s-Options-1.0`, `OptionsWidgets.lua` minor 8 — the landing-page logo stops leaving a copy of
itself in AceGUI's frame pool.**

A host with a `logo` in its landing spec could grow a **second logo** partway down its own settings
page. Intermittently, with nothing in the spec, the art or the host to explain it — because the cause
was none of those: it was pool order.

`landingLogo` draws the art by reaching through the AceGUI SimpleGroup it creates to the real frame
behind it and calling `frame:CreateTexture()`. **A texture is not a widget.** AceGUI pools widget
frames — `Release` hides one and hands the same one back at the next `Create` — and what it releases
is widgets, so nothing released or hid the texture. It rode the frame into the pool and drew again
the next time that frame was handed out, for whatever the page wanted a SimpleGroup for next.
`BuildLandingPage` already calls `ClearScroll` first and it could not help: there was no widget there
to clear.

Both halves are fixed, and both are needed. The texture is kept on the frame and **reused**, so a
frame that comes back for another logo cannot stack a second one under the first; and it is
**hidden on release**, so a frame that comes back for anything else does not show it. AceGUI fires
`"OnRelease"` before it clears a widget's callbacks, which is what makes `SetCallback` a safe place
to hang that.

There is nothing to adopt: no signature, descriptor field or spec key moves. Re-vendor and the
duplicate stops appearing. Reported from MultiMeters, whose landing page is the one it was seen on.

## v1.18.0 — 2026-08-26

Versions in this release: **Core minor 6**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 7**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 9**,
**OptionsWidgets minor 7**, **OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**,
**kit revision 13**.

**`LibKa0s-Options-1.0` minor 9 — `resetProfile`, so a global reset can be a profile reset without
every consumer restating the policy.**

The Ka0s WoW Addon Standard's `options-ui-§12` settles what a global reset is: *Reset all settings*
and the Profiles page's *Reset Profile* are the **same act** — `db:ResetProfile()` on the active
profile — and a row-by-row sweep is the defect it replaces. Two failure modes make that a rule rather
than a preference. Where a consumer's paths are window-relative, a sweep that walks the schema
**once** resets whichever window is selected and silently leaves the others, while a position hook
beside it re-centers all of them: one action, two blast radii, and nothing in the UI to say which you
get. And a sweep cannot reach a stored **array** at all — a column list, a spell list, a category
list — because an array is addressable as a whole and its members deliberately are not, so those
survive a reset that took everything around them.

Before this minor every consumer expressed that for itself: the same two-clause `skipRestoreAll`, and
the same `afterRestoreAll = function() NS.db:ResetProfile() end`, written out once per addon. Nine
copies of one policy is what this library exists to prevent, and the policy is not one a consumer is
allowed to vary — the standard makes it a MUST.

`RestoreAllDefaults` branches on whether the descriptor supplies `resetProfile`. Supplied, the row
walk narrows to the `sessionOnly` rows — the only settings a profile reset cannot reach, because
their storage is their own `set()` — then `resetProfile()` runs, then `afterRestoreAll`, then the
refresh. The narrowing is applied **before** `skipRestoreAll` is consulted, so a host that supplies
both does not have to make its veto agree with a rule the library is already applying. Not supplied,
the behavior is byte-for-byte what it was: every unvetoed row, then the hook, then the refresh. A
host that owns its own reset keeps owning it and nothing here reaches it.

The library still knows nothing about the db. It calls `resetProfile` and stops; AceDB emptying the
profile, the defaults merging back, `OnProfileReset` reaching the host's profile-changed handler, the
migrations and the re-seed are all the consumer's business. This major has never had an opinion about
SavedVariables and does not acquire one here.

Two docstrings are corrected with it. `skipRestoreAll` described itself as the profiles-page veto,
which is now implied for any host on `resetProfile` (an AceDBOptions row is not `sessionOnly`), and
`afterRestoreAll` offered *a dragged frame's saved position* as its example — the exact seam
`options-ui-§12` retires, because a position lives in the profile and comes back with it.

## v1.17.0 — 2026-08-25

Versions in this release: **Core minor 6**, **Env minor 1**, **Pool minor 3**, **Item minor 1**,
**Media minor 3**, **Widgets minor 7**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 8**,
**OptionsWidgets minor 7**, **OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**,
**kit revision 13**.

**`LibKa0s-Pool-1.0` minor 3 — `ReleaseAll` parks the active set backward, so a position gets its
own object back.** `Acquire` pops the free list from the END (`table.remove(pool.free)`) and
`ReleaseAll` parked it walking FORWARD, `for i = 1, #active`. Put those together and every release
reverses the whole object-to-position mapping: position 1's object is parked first, ends up at the
bottom of the free list, and is handed out last on the next pass. That pass parks it back the other
way, so a consumer that assigns position by acquire order alternates between two mappings with
period **2**, on every render, for as long as it keeps drawing.

Nothing about it is observable from the pool. `Counts` answers `n, 0` either way, identity is
preserved either way, no object leaks, and no suite anywhere goes red — the objects are all correct,
they are simply in the wrong places. Only the screen knew.

**MultiMeters is where it surfaced, and it took a bisect to name.** It pools one bar per ranked
player and takes the rank from acquire order, so every bar was handed a different player's figure
four times a second. A damage figure is not free to re-apply: it resolves through a visible
transient, so each bar painted full and then snapped back to its real width, continuously, the whole
fight. Preview mode looked perfect — placeholder figures are plain and apply with no resolve step.
The hand-rolled pool the addon replaced walked its active list backward, which is why the churn
arrived with the adoption commit (`059f0a5`) rather than with any change to the bars.

`ReleaseAll` now walks `for i = #active, 1, -1`. Parking position n first leaves position 1 on top of
the free list, so the next `Acquire` hands position 1 back the object it already had. The other fix
— taking from the FRONT of the free list — works too and puts an O(n) table shift on a per-frame
path; the cost belongs in the release, which runs once per render, not in the acquire, which runs
once per widget.

**The order is now part of the contract, which is the reason this is a minor bump and not a silent
correction.** Version 2's document said nothing about ordering, so a host could not have known
either way, and the guarantee — *after `ReleaseAll`, a subsequent run of `Acquire` hands the objects
back in their original order, and an ordered consumer may rely on it* — is written down at
[docs/api/Pool/version-3-docs.md](docs/api/Pool/version-3-docs.md). `ReleaseAllKeyed` is untouched
and could not have this bug: a keyed host finds its object by key, so its document now says plainly
that `pairs` order carries no meaning there and is deliberately left undefined.

No other shipped file moves. `New`, `Acquire`, `Counts` and all four keyed members are unchanged from
v1.16.0, and adopters need a re-vendor and no code change.

## v1.16.0 — 2026-08-25

Versions in this release: **Core minor 6**, **Env minor 1**, **Pool minor 2**, **Item minor 1**,
**Media minor 3**, **Widgets minor 7**, **DebugLog minor 12**, **Slash minor 7**, **Options minor 8**,
**OptionsWidgets minor 7**, **OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**,
**kit revision 13**.

**Three files, and all three moved because a consumer could not do something.** Nothing here was
found by reading the library; every change is a gap a real addon hit and reported.

**`LibKa0s-Pool-1.0` minor 2 — the keyed pool, and a guard against the leak it used to invite.**
Four new members: `NewKeyed`, `AcquireKeyed`, `ReleaseAllKeyed` and `CountsKeyed`. The pool shape
is unchanged — same free list, same factory contract — and only `active` reads as a map rather than
an array.

It exists because **two consumers keyed their active set by domain identity and therefore could not
adopt the module at all.** KickCD keys icon-grid buttons by spellID so a cooldown-state message
reaches one widget without scanning; MultiMeters carries a third `pool.all` array iterated on every
settings change. Both hand-rolled the pool this module exists to end.

The worse half is what happened to a host that ported anyway. `ReleaseAll` walks
`for i = 1, #active`, which over a keyed table iterates **nothing** — so every object is hidden,
none is returned to the free list, `Acquire` falls through to `factory()` forever, and no suite
anywhere goes red. That is precisely the leak the module was written to describe, handed back
through the documented API with no diagnostic. `ReleaseAll` now raises on a keyed pool instead.
The guard has one hole and it is not closable: a keyed pool whose keys are themselves `1..n` cannot
be told from an array pool. Real keyed hosts key by spellID or frame name, which never form `1..n`,
so the hole is not where the mistake happens — but it is documented rather than left to be
rediscovered.

**`LibKa0s-Widgets-1.0` minor 7 — two optional `CopyWindow` fields, both absent by default.**
`scrollName` gives the copy window's ScrollFrame a global name. `UIPanelScrollFrameTemplate`
derives its scrollbar children's names from its parent's, so an anonymous scroll frame leaves them
unnamed — invisible until somebody tries to skin or find one. The three adopters never named it and
`LibKa0s-DebugLog-1.0`'s own copy window always had; that difference is what the convergence below
surfaced. `makeCloseButton` accepts a host's close-control factory, defaulting to Core's.

**`LibKa0s-DebugLog-1.0` minor 12 — the fifth copy window becomes the fourth caller.** This file
had drawn its own copy frame since minor 3, and it was the last hand-rolled one in the collection.
What kept it here was that it was wired to `escClose` / `applySkin` / `dragBar`, all locals of this
file; what let it go was `scrollName`. `applySkin` is passed straight through, so a host that
re-skins its console still re-skins both windows, and `makeCloseButton` is forwarded — which is why
Widgets grew the matching field rather than hardcoding Core's x, since this library has published
that descriptor field as covering **both** windows since its own minor 4.

Two things a host will notice. `addonName` now falls back to `name`, because `CopyWindow` refuses a
descriptor without one and this library has always treated `addonName` as optional — an unset host
would have lost its copy window on this upgrade rather than gained a shared one. And the window now
**re-anchors to the console on every show** instead of sitting at a fixed center: the popup lands
over the window that spawned it, which is what CopyWindow's three other callers already do.

`NEEDS_WIDGETS = 7` is a hard floor. With Widgets absent or older this module is **absent** rather
than half-wired, because a console whose Copy button silently does nothing is worse than no
console — the host's degradation stub never fires and nobody is told why.

**Kit revision 13 — `CreateFrame` records its arguments.** It returned a bare stub and dropped the
name, so "did this frame get the name it needs?" was a question no suite could ask. It is the kit's
own fidelity rule 3, and the cost of the gap is on disk: Widgets' copy window shipped an anonymous
scroll frame for five versions with nothing able to see it. Recorded on the frame rather than
answered through `GetName()`, which still returns nil — `LibKa0s-Options-1.0`'s scrollbar patch
concatenates that, so handing it a real string would change a code path rather than observe one.
Purely additive: a suite that never reads `__name` sees nothing different.

## v1.15.0 — 2026-08-25

Versions in this release: **Core minor 6**, **Env minor 1**, **Pool minor 1**, **Item minor 1**,
**Media minor 3**, **Widgets minor 6**, **DebugLog minor 11**, **Slash minor 7**, **Options minor 8**,
**OptionsWidgets minor 7**, **OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**,
**kit revision 12**.

**Three new majors, one new widget, and one number.** Every one of them came out of the same
measurement: a sweep of all nine consumer addons for code that had been written more than once, kept
only where the copies agreed on behavior, and dropped where they disagreed on purpose. The test-kit
work this content was stacked on top of is not in it: that shipped on its own, as v1.14.0 below.

**`LibKa0s-Env-1.0` — the client facts every addon reads, read one way.** Four functions over three
Blizzard surfaces: the TOC manifest, the addon's own version string, the player's map id and the
player's zone labels. `GetAddOnMetadata` alone had been written **eleven times across nine addons** —
six in a `core/Compat.lua` in four different spellings, five more inlined at a call site where no
audit of the shim files would ever have found them — and not one of the eleven behaved differently
from any other. The metadata calls take the host's own addon name for the reason
`LibKa0s-Media-1.0`'s do: the library is vendored, so a copy cannot know which folder it sits in.
This is deliberately *not* the wider `Compat` extraction, which was measured against the same
evidence and rejected — a container reader is BankLedger's and a mail decoder is LootHistory's,
where this is nobody's.

**`LibKa0s-Pool-1.0` — the free/active widget pool, with the release half right.** Four functions,
no state of its own, and a pool that is a plain `{ free = {}, active = {} }` table with no metatable,
so a host without the library can still write the nine-line local copy. Four copies of this pool
shipped across two addons and **three of them recycled correctly**: the fourth hid its active objects
and never returned them to the free list, so `Acquire` fell through to `factory()` on every call. That
defect is invisible from outside — the charts draw, the suite stays green — and the only symptom is a
client that gets heavier the longer a window is open, because frames are never destroyed in WoW.

**`LibKa0s-Item-1.0` — item identity as four primitives, and no resolver.** `ItemIDFromLink`,
`QualityFromLink`, `QualityLabel` and `LoadItem`. There is deliberately **no merged "resolve an item"
function**, and the absence is the design: the two addons that resolve items disagree in writing about
what an *uncached* item means. LootHistory guesses from the link's brackets and color, because a
browsable capture log would rather show an approximate row than lose the drop; BankLedger refuses and
records the skip, because "cannot be judged" is not "passes". Both are right for their addon, and a
shared resolver would have had to overturn one of them silently. Two of the four were byte-identical
in both addons; the other two were each written by only one — which is the better argument for a
library than duplication is, since each addon was missing a primitive the other already had.

**`Widgets.CopyWindow` — the export frame the collection had four copies of.** There is no file I/O
in WoW, so every "copy this out" surface ends in the same thing: a frame holding a multi-line
`EditBox` with its text selected and an instruction to press Ctrl+C. BankLedger's and LootHistory's
were the same fifty-two lines with the addon name substituted; MultiMeters' called itself the third
copy and was the fourth. It answers a **handle, not a frame** — nothing is built until the first
`Show`, because a host declares this at file load and most sessions never open it. It lives in
Widgets rather than in a major of its own because Widgets already owns "a frame this collection kept
re-drawing" and every addon that needs a copy window already vendors that file; a new major would
have bought another vendor sweep for nothing. Nothing else in Widgets moves: adopters need a
re-vendor and no code change, and adopting the window itself is a separate decision per host.

**The debug console holds 1500 lines, not 500.** `lib.MAX_BUFFER` is the only thing that moved in
`DebugLog.lua`. The cap is not a display preference — the perf capture workflow pastes out of *this*
buffer, with `perf report` printing its summary into the console and `perf dump` writing a whole JSON
record as a single line — and at 500 a long run overflowed and lost its head silently, because a
buffer that has dropped its oldest lines is indistinguishable from one that was started later. There
is **one number, not two**: the copy window shows `table.concat(buffer)` and caps nothing of its own,
so the buffer cap *is* the copy cap. Two consumer suites pinned the literal `500` rather than reading
the member and go red until they re-vendor, which is the intended way to find them.

## v1.14.0 — 2026-08-25

Versions in this release: **Core minor 6**, **Media minor 3**, **Widgets minor 5**,
**DebugLog minor 10**, **Slash minor 7**, **Options minor 8**, **OptionsWidgets minor 7**,
**OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**, **kit revision 12**.

No shipped library file changed. This release is the **test kit** only, and it is about how long the
green gate takes to answer.

**The loader was re-reading the entire source tree hundreds of times per run.** A suite that wants an
isolated instance re-loads every vendored library file and every file the TOC names, which is the
right shape — isolation comes from re-*running* the chunks under a fresh mock, not from unpicking
what the last instance did. But `loadfile` also re-opens, re-reads and re-*parses* an unchanged file
on every one of those instances. Measured on Ka0s Multi Meters: **1,246 cases drove 60,112 `loadfile`
calls**, 28.5s of the run's 31.4s of CPU, and 2m10s of wall clock — because that checkout is on a
WSL2 `/mnt` mount where each read crosses a 9p boundary.

`Loader.load` now compiles each path once per process and re-calls the cached chunk. Isolation is
untouched, because the cache holds a **function, not a result**: every instance still calls it and
still builds its own tables, closures and upvalues. The property that makes this sound is a Lua 5.1
one — `setfenv` sets the environment a chunk sees when it *next runs*, and a closure created during
that run inherits its parent's environment *at creation time*, so two instances never share a global
namespace. `tests/test_loader.lua` pins that by construction rather than by comment. That suite went
from **2m10s to 11.9s**, with no test changed.

**What was left was subprocess latency, so the runner can now use more processes.** With the reads
gone, the same suite spent 2.4s of CPU inside an 11.9s wall clock; the other 9.5s was 147 `io.popen`
calls — directory listings and `git` invocations that cost tens of milliseconds to spawn and nothing
to compute. `--jobs N` / `-j N` / `--jobs auto` re-invokes the same runner as N children with
`--shard I/N` and adds their counts up. There is no worker script and no second code path, the same
way `--list` has none.

Three properties are load-bearing and tested. Shards take **contiguous** slices and are relayed in
order, so a parallel transcript is byte-identical to a serial one — a gate whose output reshuffles is
a gate nobody diffs. A shard that dies without printing its count line **fails the run**, because its
cases are missing from the totals and a gate that goes quiet when it cannot look is worse than no
gate. And `--shard` forces `jobs = 1`, so a runner carrying `jobs = "auto"` cannot fork a process
tree. Where there is no POSIX shell to background from, the run falls back to serial with a note
rather than failing.

**And the vendored-payload gate was spawning one `git` per file.** With the reads cached and the
fan-out working, that one case was the longest thing left in a consumer's suite: `gitShow` ran
`git show <tag>:<path>` once per file, and a payload is not a few files — 49 icons and a font meant
about 66 process spawns and 7.5 seconds. It capped the fan-out too, because a shard is only as fast
as its slowest case: across 12 shards, eleven finished under 1.3s and the one carrying this took
7.86s.

`vendor_sync` now reads every blob with one `git cat-file --batch`. The request list goes through a
temp file, because Lua 5.1's `io.popen` is unidirectional and cannot write to a child's stdin. Each
reply is sliced by the **length** git states, never by pattern, so a blob carrying newlines, NUL
bytes or CRLF round-trips unharmed — which is what keeps this safe for the TGAs and the TTF as well
as the Lua. Verified by breaking it: a corrupted vendored icon still fails the gate, by name. One
behavior difference, and it is a fix — an empty blob used to read as "the tag does not carry this",
and now compares equal to an empty local file.

End to end on Ka0s Multi Meters — 1,246 cases, WSL2 `/mnt` checkout, 16 cores — **2m10.8s to 3.7s**:
11.6s after the chunk cache, 8.2s after the batched reads, 3.7s at `-j 12`.

Parallelism is **opt-in per repo** (`Kit.run`'s default is `jobs = 1`), because splitting the suites
also splits the process-wide state they share. A suite that quietly depended on an earlier suite
having run first passes serially and fails sharded — always a bug, and `--jobs` is what makes it
visible. The chunk cache has no such caveat and is on for everyone.

## v1.13.0 — 2026-08-24

Versions in this release: **Core minor 6**, **Media minor 3**, **Widgets minor 5**,
**DebugLog minor 10**, **Slash minor 7**, **Options minor 8**, **OptionsWidgets minor 7**,
**OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**, **kit revision 11**.

**`LibKa0s-Widgets-1.0`'s menu was eating the click that closed it, and swallowing a right-click
entirely.** The menu was dismissed by a full-screen `Button` at `FULLSCREEN` strata, shown alongside
it, whose `OnClick` hid the menu. That frame *intercepted* the click, and intercepting was the
defect twice over. A `Button` with no `RegisterForClicks` takes `LeftButtonUp` and nothing else, so
a right-click anywhere while a menu was open landed on the catcher, found no handler and went
nowhere — the menu stayed open and whatever was under the cursor never heard it. And even the
left-click it did handle was consumed: dismissing the menu cost a click that did nothing else.

It survived from minor 1 because neither shipped consumer had a right-click surface on the same
window as a dropdown. LootHistory adopted the major at v1.12.0 and became the first, and there a
right-click on a history row did nothing at all until the player left-clicked to dismiss the menu
first. It was recorded in that addon's smoke tests as expected in-client behavior and reported here
rather than worked around locally.

**The catcher is gone.** The menu registers `GLOBAL_MOUSE_DOWN` while it is shown and closes itself
when the press was neither on the menu nor on the dropdown it dropped from. That event fires for a
press anywhere in the UI, on any button, whether or not something else consumed it — so the menu
reacts to a click it never touched, and the click goes on to reach whatever is under the cursor. One
press now both dismisses the menu and does the thing the player pressed on. The registration is
taken when the menu is shown and dropped by its `OnHide`, not held for the life of the process: a
handler running on every mouse press in the game for the rest of the session, in every host that
ever vendored this file, is a cost no host agreed to.

**This one is visible, and adopters should smoke-test it.** Under minor 4 a click outside an open
menu was absorbed; under minor 5 it dismisses the menu *and* lands. A player closing a menu by
clicking the 3D world, an action bar or another addon's frame will now also click that thing. No
contract moves — `Dropdown`, `CloseMenu`, every instance method, every `opts` field and every
option-row field are unchanged, so adopters need a re-vendor and no code change.

**Ten new cases, six of them red before the change**, covering the right-click that was swallowed,
the left-click that was eaten, a button nobody enumerates, the two presses that are deliberately not
"outside" (on the menu, and on the owning dropdown, each with the failure it prevents), a press on a
*different* dropdown still closing it, and the registration being dropped on hide. The mock gained
real `RegisterEvent` / `UnregisterEvent` / `IsMouseOver` for them: against the catch-all frame stub
every registration silently answered the frame itself, and neither "is it listening?" nor "what does
it do when the event arrives?" was askable at all.

## v1.12.0 — 2026-08-24

Versions in this release: **Core minor 6**, **Media minor 3**, **Widgets minor 4**,
**DebugLog minor 10**, **Slash minor 7**, **Options minor 8**, **OptionsWidgets minor 7**,
**OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**, **kit revision 11**.

**`LibKa0s-Widgets-1.0` can now express a row that selects something other than its own value.** A
*preset* row is one whose `value` is not among the values it picks — "Character: Current" selects
the current player's key, and its own value is the string `"current"`, which is nobody's key.
Through minor 3 the widget had no way to say that in either direction. `rowSelected` could only ask
whether the row's own value was in `_selected`, so a preset row was the one row in a menu that could
never light up even when it was exactly what the dropdown was showing; and `ToggleSelected` could
only toggle the row's own value in, so clicking it filtered on the literal string.

Two additions, both optional and both inert for a host that sets neither. `opt.isActive(dd)` is a
per-option predicate, asked *instead of* the selection set and final in both directions.
`dd.presets` is a plain field on the dropdown, `{ [value] = function(dd) end }`, whose handler runs
in place of the toggle and owns `dd._selected` outright.

**The collapsed multi-select label now counts a selection whose option row is gone, and this one is
a behavior change.** `UpdateMultiLabel` walked `_options` and asked which were selected, so a value
in `_selected` with no row in the *current* option list was invisible to it — and the option lists
are data-driven, so a character with no rows in the current dataset is not in the list and the
button read "Character: All" while the filter was on. It now labels every value in `_selected`,
from its option row when there is one and from the raw value when there is not. A host whose option
list always contains everything selectable sees no difference; a host whose selection can outlive
its option list will see a summary where it previously saw the "All" label. That is the intent, but
it is visible, and [version 3's *Moving to version 4*
section](docs/api/Widgets/version-3-docs.md) says so where an adopter on that copy will read it.

**Nothing is removed and nothing is reshaped.** `Dropdown`, `CloseMenu`, every instance method's
signature and every documented `opts` field are unchanged from minor 3. Adopters need a re-vendor
and, unless they want the new seams, no code change.

**It came upstream rather than being worked around, which is the whole point of the clause that
sent it here.** LootHistory carried its own copy of this widget — the third in the collection, and
the one the major was meant to delete — and that copy had both seams because its Character filter
needed them. Adopting the library there would otherwise have meant either losing the behavior or
keeping the copy. All three releases of this major so far have come from an adopter hitting a gap in
the same step of the same adoption prompt.

**Thirteen new cases**, nine of them red before the change: a preset row lighting up under its own
predicate and staying dark under someone else's, `isActive` overriding membership in both
directions and on a single-select dropdown, a preset click replacing rather than toggling, a preset
overriding the `"all"` sentinel, the four collapsed-label rules including the two that move, and one
that drives a preset row through a **real** row build rather than a seeded stand-in. The collapsed
label had no case at all before this release.

## v1.11.2 — 2026-08-24

Versions in this release: **Core minor 6**, **Media minor 3**, **Widgets minor 3**,
**DebugLog minor 10**, **Slash minor 7**, **Options minor 8**, **OptionsWidgets minor 7**,
**OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**, **kit revision 11**.

**`LibKa0s-Widgets-1.0`'s menu raised on the first click, in every host.** A row's optional glyph
`FontString` was created with no font — `CreateFontString(nil, "OVERLAY")`, no template — and
`paintMenuRow` then set its text unconditionally, on every row of every paint. The client answers
`FontString:SetText(): Font not set` to that, so the first click on any dropdown this major built
errored, wherever the host happened to build its window.

It was not confined to a host that names no `glyphFont`. The face is set only on a row that *has* a
glyph, so a host doing everything right still painted its glyphless rows through a `FontString`
that had never been given a font; a host with no face at all hit it on every row.

The fix is one argument — the glyph is built from the `GameFontHighlightSmall` template, so it
always has a font — and the per-paint `SetFont` that v1.11.0 introduced is untouched, so each host
still imposes its own monospace face. No contract moves: `Dropdown`, `CloseMenu` and every instance
method are unchanged from v1.11.1, and the documented behavior of `opts.glyphFont` is the sentence
it has been since v1.11.0 — *dropping* the glyph column is what it always promised and what this
release is the first to actually do. Adopters need a re-vendor and no code change.

**The test kit's mock now raises `Font not set` too.** 553 cases went green over this, because the
widget suite's FontString stand-in stored any string it was handed. MultiMeters' own mock models
this exact error, with a comment recording the load the live client took down when it hit it — the
consumer had been burned by the class of bug and modelled it; the library it now vendors had not.
`tests/test_widgets.lua`'s frame factory now gives a `FontString` its own identity, records the
template it was built from, and raises on `SetText` when it has neither font nor template. Two new
cases build REAL rows rather than recording stand-ins, because it is the row's *creation* that was
wrong and every existing case seeded rows that bypassed it.

Full contract in [docs/api/Widgets/version-3-docs.md](docs/api/Widgets/version-3-docs.md).

## v1.11.1 — 2026-08-24

Versions in this release: **Core minor 6**, **Media minor 3**, **Widgets minor 2**,
**DebugLog minor 10**, **Slash minor 7**, **Options minor 8**, **OptionsWidgets minor 7**,
**OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**, **kit revision 11**.

**`lib.CloseMenu()` closes `LibKa0s-Widgets-1.0`'s shared popup from outside a click.** The gap was
found by the first adopter, re-vendoring v1.11.0 into BankLedger: the widget's popup is a
process-wide singleton parented to `UIParent` at `FULLSCREEN_DIALOG`, built lazily by the first
dropdown any addon opens — not to any one host's frame, unlike the file-local menu the lift took it
from. Before this minor, closing a host window by any route that was not a click on the dropdown
itself — Escape, a slash command — left the menu orphaned: still shown, still at
`FULLSCREEN_DIALOG`, floating over the game with nothing left to hide it. The click-catcher built
alongside the menu only ever helped when the player actually clicked.

`CloseMenu()` takes no parameters, hides the shared menu if it is open, and is a safe no-op if no
dropdown has ever opened it or if it is already hidden — hiding the menu is sufficient on its own,
because the menu's own `OnHide` script already hides the click-catcher. No other file moves;
`Widgets.lua`'s `Dropdown` constructor and every instance method are unchanged from v1.11.0.

Full contract in [docs/api/Widgets/version-2-docs.md](docs/api/Widgets/version-2-docs.md).

## v1.11.0 — 2026-08-24

Versions in this release: **Core minor 6**, **Media minor 3**, **Widgets minor 1**,
**DebugLog minor 10**, **Slash minor 7**, **Options minor 8**, **OptionsWidgets minor 7**,
**OptionsScroll minor 3**, **Perf minor 7**, **PerfPanel minor 4**, **kit revision 11**.

**New major: `LibKa0s-Widgets-1.0`.** The collection's flat dropdown, lifted out of
BankLedger's `modules/Browser.lua` because MultiMeters was about to grow a second copy of it.
One `Widgets.Dropdown(parent, width, opts)`, one process-wide popup menu behind every instance
of it, and a pooled row list. It takes no dependency on `LibKa0s-Media-1.0` — a vendored copy
cannot know which addon folder it sits in, so the chevron, the multi-select tick and the row
glyph's face all arrive as parameters, each with the Blizzard rung it falls to.

No other shipped file moves. Every other minor above is unchanged from v1.10.2.

## v1.10.2 — 2026-08-23

Versions in this release: **Core minor 6**, **Media minor 3**, **DebugLog minor 10**,
**Slash minor 7**, **Options minor 8**, **OptionsWidgets minor 7**, **OptionsScroll minor 3**,
**Perf minor 7**, **PerfPanel minor 4**, **kit revision 11**. One shipped file moves —
`PerfPanel.lua` — closing the last place in this library where a close button was built without
being told who was asking.

**The perf panel's close button never got the addon name either.** v1.10.1 fixed the console's
forwarder and left the panel's own no-`decorate` path calling `Core.MakeCloseButton(frame, Hide)` —
two arguments onto the three-argument function Core grew at minor 6. So a host that draws no chrome
of its own got a perf panel closing with a multiplication sign beside a debug console closing with
the collection's mark: the same defect as last release, one window over.

This is the second time the same dropped argument has shipped, which says something about the shape
rather than about the week. A close button is built at a handful of call sites, the third argument
cannot be inferred, and omitting it produces a perfectly good button — so no layer errors, no suite
goes red, and the only witness is someone looking at two windows side by side. **The standard now
carries it as a MUST**: an addon builds every close control through one wrapper that supplies its
folder name, and a bare two-argument call is a defect on sight (`standalone-windows`,
`debug-logging-§12`, anti-pattern #65).

**`addonName` joins the Perf descriptor**, optional and falling back to `name`. `name` is also the
frame-global prefix, so a host whose window names differ from its folder now has somewhere to say
so — but every host in the collection already passes its folder name as `name`, which means **the
fix reaches an unmodified consumer on the re-vendor alone.** Three cases pin it: that the fallback
path reaches Core with the name, that `addonName` wins over `name`, and that a host supplying
`decorate` still gets no close button from the library.

Full contract in [docs/api/Perf/version-7.4-docs.md](docs/api/Perf/version-7.4-docs.md).

## v1.10.1 — 2026-08-23

Versions in this release: **Core minor 6**, **Media minor 3**, **DebugLog minor 10**,
**Slash minor 7**, **Options minor 8**, **OptionsWidgets minor 7**, **OptionsScroll minor 3**,
**Perf minor 7**, **PerfPanel minor 3**, **kit revision 11**. One shipped file moves —
`DebugLog.lua` — correcting two things v1.10.0 got wrong in the window it was about.

**The console's close button never got the addon name.** `lib.MakeCloseButton` is a forwarder onto
Core's, and it took two arguments where Core's had grown a third at Core minor 6. So v1.10.0 shipped
a title bar whose copy and clear drew the collection's art beside a close that was still a
multiplication sign — visibly inconsistent with itself, and with the host window two inches away.

A dropped argument is not a failure any layer can report: Core saw no addon name and drew exactly
what it draws without one, which is a perfectly good button. The only symptom was the look, which is
why it took a screenshot to find. Two cases pin it now — that the console hands its close factory the
name for both of its windows, and that the forwarder passes it through to Core.

**The icon tooltip is removed, not repositioned.** It anchored under the control, which put it on top
of the first line of the log — the thing the window exists to show — every time the pointer crossed
the title bar. Anchoring it elsewhere trades one overlap for another on a window that is 700px of
text, and the two marks sit beside a close button that has never needed one. A host that wants the
words back omits `addonName`; there is no third setting.

Full contract in [docs/api/DebugLog/version-10-docs.md](docs/api/DebugLog/version-10-docs.md).

## v1.10.0 — 2026-08-23

Versions in this release: **Core minor 6**, **Media minor 3**, **DebugLog minor 9**,
**Slash minor 7**, **Options minor 8**, **OptionsWidgets minor 7**, **OptionsScroll minor 3**,
**Perf minor 7**, **PerfPanel minor 3**, **kit revision 11**. Two shipped files move — `Core.lua`
and `DebugLog.lua` — and the art they now draw was already in the payload as of v1.9.2.

**The library's own windows can wear the collection's art.** v1.9.2 shipped 113 icons and nothing in
this library drew one: the debug console still closed with a multiplication sign and cleared with the
word "Clear", beside a host window whose own header had been drawing the icon set for a release. Two
changes close that gap.

**`Core.MakeCloseButton(parent, onClick, addonName)`** draws `LibKa0s-Media-1.0`'s `close` icon when
it is told which addon folder is asking. 18×18 as it has always been, with 12px of art inset inside
it, gray at rest and red under the pointer — the same two colors the glyph used. Full contract in
[docs/api/Core/version-6-docs.md](docs/api/Core/version-6-docs.md).

**The console descriptor takes `addonName`** and, given it, draws close, copy and clear as icons on
both its windows. The three title-bar controls become one size and one pitch — they were 18, 42 and
40 wide and only lined up by arithmetic — so the derived Copy offset tightens from `-78` to `-54`.
Each icon carries a **tooltip** with the label it replaced: dropping a word for a mark buys room and
costs the one thing the word was doing, and a clipboard and a bin are not universally legible. Full
contract in [docs/api/DebugLog/version-9-docs.md](docs/api/DebugLog/version-9-docs.md).

**It is a name and not a boolean, in both.** A texture path is absolute from `Interface\AddOns\`
and this library is vendored: there is no one path to it, and a copy cannot know which folder it was
copied into. The host has that string as its first vararg and nothing else does. `DebugLog`'s
documentation says plainly not to pass `d.name` for it — that field seeds frame globals and only
happens to equal the folder name in most hosts.

**Additive, and the old spelling is not deprecated.** A caller that passes nothing gets the
version-8 windows down to the pixel. That path is also what a host without the Media module gets and
what an install missing the art gets — three cases, one branch, so there is no degraded path that
only runs where nobody tests.

## v1.9.2 — 2026-08-23

Versions in this release: **Core minor 5**, **Media minor 3**, **DebugLog minor 8**,
**Slash minor 7**, **Options minor 8**, **OptionsWidgets minor 7**, **OptionsScroll minor 3**,
**Perf minor 7**, **PerfPanel minor 3**, **kit revision 11**. One shipped file moves —
`Media.lua` — plus the payload it carries: the icon set nearly triples and seven statusbar textures
join it.

**64 more icons — `ICONS` goes from 49 to 113.** The left/right arrow family to match the up/down
one, both text-alignment families (`align-*` draws ragged lines, `justify-*` blocked ones — they are
different marks and a toolbar offering both needs both), two more grid densities, `chat` and
`speech-bubble` as separate marks, and the tools, places, sound and session groups. Same source, same
pipeline, same white-so-it-tints rule; `tools/artwork/icon_cleaner.py` is still the record of which
upstream glyph each name draws.

**Seven statusbar textures, and they are generated rather than drawn.**
`tools/artwork/bar_textures.py` synthesizes all of them from named constants, which makes it both the
provenance record and the licensing answer — nothing was traced, sampled or copied.

| LSM display name | File | What it is |
|---|---|---|
| `Ka0s Gradient` | `gradient.tga` | An opaque vertical gradient, pure white at the top, easing to 58% |
| `Ka0s Underline 1` / `2` / `4` | `underline-1/2/4.tga` | Transparent but for a band at the bottom edge — 2px, 4px, 8px |
| `Ka0s Overline 1` / `2` / `4` | `overline-1/2/4.tga` | The same three, mirrored to the top |

Every one is 256×32 whatever the band inside it does, so a bar frame sized for one is sized for all
seven — switching gives a player a different line, never a different-shaped widget. The gradient
peaks at **white** where a typical bar texture peaks at light grey: a texture is tinted by
multiplying, so grey art mutes a saturated bar color and white delivers it undiluted.

**`Texture(addonName, name)` and `TEXTURES`** reach them, and **`RegisterLSM` now returns
`fonts, bars`** and registers the textures as `statusbar` alongside the face. A caller reading the
single return still reads the font count.

`TEXTURES` is keyed by the **display name**, not the filename, for the reason `FONTS` is: that key is
what a dropdown shows and what a profile stores. A texture registered as `underline-2` would leave a
player with a saved setting that reads as a path in every UI that shows it.

Additive throughout. No existing member changed, every version-2 icon name still resolves, and a
consumer that adopts nothing new sees no difference — but re-vendoring is what carries the art, so a
consumer wanting any of it re-vendors `libs/LibKa0s/` and bumps its provenance line. Kit revision 11
is unchanged from v1.9.0 and is still the minimum for any payload with `media/` in it.

Full contract in [docs/api/Media/version-3-docs.md](docs/api/Media/version-3-docs.md).

## v1.9.1 — 2026-08-23

Versions in this release: **Core minor 5**, **Media minor 2**, **DebugLog minor 8**,
**Slash minor 7**, **Options minor 8**, **OptionsWidgets minor 7**, **OptionsScroll minor 3**,
**Perf minor 7**, **PerfPanel minor 3**, **kit revision 11**. One shipped file moves —
`Media.lua` — and the art, the font and every other file are byte-identical to v1.9.0.

**`Media.Icon` answers an extensionless path.** v1.9.0 answered `...\media\icons\settings.tga`,
reasoning that one spelling beats two. The first consumer to adopt the module records the opposite
from a live client: Mythic Meters' header art has failed silently twice, and its surviving note says
a path carrying `.tga` is one of the two spellings that draws **nothing**. The client appends the
extension itself.

Corrected within hours of v1.9.0 rather than argued, because of how this fails — a texture that does
not load draws nothing and raises nothing, so a wrong spelling is invisible in every test, every log
and every green suite, and shows up only as a control that is not on screen. No consumer had released
against v1.9.0. The file on disk is unchanged and still `<name>.tga`; `tests/test_media.lua` now
asserts the path and the file it resolves to, so the two cannot drift.

Full contract in [docs/api/Media/version-2-docs.md](docs/api/Media/version-2-docs.md).

## v1.9.0 — 2026-08-23

Versions in this release: **Core minor 5**, **Media minor 1**, **DebugLog minor 8**,
**Slash minor 7**, **Options minor 8**, **OptionsWidgets minor 7**, **OptionsScroll minor 3**,
**Perf minor 7**, **PerfPanel minor 3**, **kit revision 11**. One shipped file is new —
`Media.lua` — and with it the first non-code payload this library has ever carried. Every other
shipped file is byte-identical to v1.8.3.

**`LibKa0s-Media-1.0` — the art and the type this collection draws with.** `LibKa0s/media/` ships 49
white icon TGAs (Open Iconic, MIT) and JetBrains Mono (SIL OFL), and the module is the three
functions that reach them: `Icon(addonName, name)`, `Font(addonName, name)` and
`RegisterLSM(addonName)`, plus `ICONS` and `FONTS` as the catalog of what is there. Full contract in
[docs/api/Media/version-1-docs.md](docs/api/Media/version-1-docs.md).

**Published because the copying had already started.** Mythic Meters built the 49 icons from Open
Iconic and shipped them under its own `media/`, beside its own copy of JetBrains Mono, built by a
tool living in that one repo. The second addon to want a gear icon would have copied both — and then
there are two sets of bytes, two licenses to track, two provenance stories, and a collection whose
addons stop looking like one author's work the first time one copy is regenerated and the other is
not. The tool came with the art: `tools/artwork/icon_cleaner.py` is the provenance record, naming the
upstream repo, the license, which glyph each name draws and every transformation applied, because it
is the program that produces them.

**Every call takes the host's own addon name, and that is not an oversight.** A texture path is
absolute from `Interface\AddOns\` and this library is vendored, so there is no one path to it and a
copy cannot know which one it was copied into. Guessing would be worse than asking: a wrong texture
path draws nothing and raises nothing. An unknown icon name answers `nil` for the same reason —
`nil` is a value a caller can branch on, an invisible control is not.

**Kit revision 11, and it is required to vendor this release.** `vendor_sync.lua` listed one
directory level and normalized line endings on everything it compared. Both were right for a flat
payload of Lua and wrong the moment `media/` existed: the first listed `media` as a name and then
tried to read a directory as a file, and the second would corrupt the comparison of any binary whose
bytes contain the pair `0D 0A`. It now recurses, and compares a known binary type byte for byte. None
of the 49 TGAs contains that pair today — the gate would have passed, and the next icon added could
have broken it for a reason nobody would have looked for there. See
[docs/api/testkit/version-11-docs.md](docs/api/testkit/version-11-docs.md).

**`tests/test_prose.lua` skipped directories by opening them**, which is true on Windows and false on
Linux, where the failure lands on the first read as `Is a directory`. `LibKa0s/media/` is the first
subdirectory this library has shipped and the first to find that out. It now probes with a read.

Additive-only. No existing member changed, and a consumer that does not adopt the new major sees no
behaviour difference at all — but a consumer re-vendoring to this tag **must take kit revision 11 in
the same commit**, or its own vendored-payload gate fails on `media/`.

## v1.8.3 — 2026-08-07

Versions in this release: **Core minor 5**, **DebugLog minor 8**, **Slash minor 7**,
**Options minor 8**, **OptionsWidgets minor 7**, **OptionsScroll minor 3**, **Perf minor 7**,
**PerfPanel minor 3**. One shipped file moves — `Options.lua` — so `libs/LibKa0s/` must be
re-vendored by any consumer that wants the new member. Everything else is byte-identical to v1.8.2.

**`O.RefreshPanel(ctx, structural)` — refresh ONE page, on either tier.** The per-page half of a trio
that until now only offered sweeps. `structural` true re-runs that ctx's renderer; false runs its
refreshers in place. A hidden page is flagged dirty and repaints on its next `OnShow`, so the caller
never has to ask whether it is on screen. Full contract in
[docs/api/Options/version-8.7.3-docs.md](docs/api/Options/version-8.7.3-docs.md).

**Published because a host reached into `ctx._dirty` and got the name wrong.** `RefreshAllPanels` and
`RefreshScalars` sweep every registered ctx, which is right for a widget maker's `set()` — the write
could be showing anywhere — and wrong for a host whose page repaints off its **own** message bus: it
wants one page repainted and gets all of them, and the library never hears about the change at all.
The workaround left to such a host was the private field `SetRenderer`'s `OnShow` gate reads.
PanelMaster wrote `ctx.dirty`, one underscore out, so its Panels page marked a flag nothing reads.
The gate never opened and the page kept the widget tree it built for the previous profile: after a
profile switch its panel dropdown still listed the old profile's panels while the panels themselves
had correctly left the screen. Both suites stayed green, because the host's own test asserted the
same wrong flag name — which is the argument for publishing rather than documenting. This is
`library-stack-§7`'s publish-on-demonstrated-need bar met, not repetition (anti-pattern #55): a host
bus is a shape the two sweeps genuinely do not serve.

Additive-only, as the API contract requires. `RefreshAllPanels` and `RefreshScalars` are unchanged
and still sweep; nothing a consumer already calls behaves differently, and a consumer that does not
re-vendor is unaffected. `OptionsWidgets.lua` and `OptionsScroll.lua` do not move, and no descriptor
field, row field or drawn pixel changes.

## v1.8.2 — 2026-08-07

Versions in this release: **Core minor 5**, **DebugLog minor 8**, **Slash minor 7**,
**Options minor 7**, **OptionsWidgets minor 7**, **OptionsScroll minor 3**, **Perf minor 7**,
**PerfPanel minor 3**. **No shipped library file moves** — nothing under `LibKa0s/` changed, so no
minor bumps and `libs/LibKa0s/` is byte-identical to v1.8.0 in every consumer. This release is the
test kit alone.

**testkit revision 10 — the runner writes the bundle to the line terminator `.gitattributes`
declares.** `run-automated-tests.sh` now reads the declared terminator per path with
`git check-attr text eol` at the end of a bundling run, and rewrites only the files that disagree.

**It asks for `text` as well as `eol`, and skips any path whose `text` is `unset`.** That is the
binary guard, and it is the primary one. `binary` is a macro for `-text` and says nothing whatever
about `eol`, so a path marked `*.png binary` in a repo pinned `* text=auto eol=crlf` still answers
`eol: crlf` — inherited from the pin — for a file git itself will never convert, and a pass acting on
that answer alone rewrites the asset. A NUL-byte heuristic is kept beside it as a second line of
defence but cannot be the first: a binary format that happens to be NUL-free walks straight through
it, and `line-endings-§4` names the live one — `realesrgan-x4plus-anime.param`, whose ncnn format is
plain ASCII, sitting beside its own weights. `text: unset` is a declaration; a NUL scan is a guess.
This is the same correction `line-endings-§7` made to the audit's working-tree check and
`wow-addon/scripts/normalize-eol.sh` made to the `Write`/`Edit` hook; the three now agree.

Everything the runner writes goes down a plain shell redirect, and a redirect is a kernel write into
the working tree — it never passes through git's clean/smudge filters. So in a repo pinned
`* text=auto eol=crlf`, which is every client-bound repo in this collection and **this one**, the
bundle landed **LF on disk while `.gitattributes` said CRLF**, on every run, for nine revisions.

**Nothing reported it.** The blob is LF in the index either way — that is where LF belongs — so
`git status` is silent before the commit and after it, and `git add --renormalize` does not fix it
because it rewrites the index and the index was never wrong. Only a byte-level line-endings audit
ever saw it, which is how it survived across nine repos.

**One pass at the end rather than a fix at each write site**, for one reason that decides it:
`perf.json` is not written by the runner at all — the addon's own `tests/perf.lua` creates it through
`--out`. Fixing the writers means reaching into eight addons' perf harnesses and still missing
whatever the next suite drops into the bundle. And the terminator is *read from git* rather than
assumed CRLF, so a repo declaring `eol=lf` — or declaring nothing — is left byte-for-byte alone, as
is a second pass over a file that is already correct. Dependencies are `git`, `awk`, `tr`, `cmp`,
`mv` and `rm`; no `unix2dos`.

One byte is not preserved: **a written file whose last line lacked a trailing newline gains one.**
That is the only respect in which the pass is not "byte-identical apart from the terminators", and
it is documented rather than left to be discovered.

**`tests/test_eol.lua` is new here and asserts the invariant, not the implementation** — it asks git
what each tracked file under `docs/automated-tests/` is declared to be and reads the bytes. It
therefore also catches files the runner never writes, including the `ANALYSIS.md` the
`/wow-addon:automated-tests` skill agent drops into the bundle directory after the runner exits,
which this fix does **not** close.

**Every consumer must re-vendor `tests/_kit/` from this tag and move its provenance line in the same
commit.** No case name moves at this revision, so unlike v1.8.1 a consumer's `docs/test-cases.md`
does not need regenerating for the kit's sake. Bundles already on disk are not repaired by adopting:
they need the one-time `rm <path> && git checkout -- <path>` from `.gitattributes`' own footer.

`suites.<name>.gating` in the run manifest is **still emitted**, for the third revision running.
Nothing reads it; dropping a manifest field alongside a one-file bug fix would put two unrelated
adoption costs on one re-vendor.

See [`docs/api/testkit/version-10-docs.md`](docs/api/testkit/version-10-docs.md).

## v1.8.1 — 2026-08-06

Versions in this release: **Core minor 5**, **DebugLog minor 8**, **Slash minor 7**,
**Options minor 7**, **OptionsWidgets minor 7**, **OptionsScroll minor 3**, **Perf minor 7**,
**PerfPanel minor 3**. **No shipped library file moves** — nothing under `LibKa0s/` changed, so no
minor bumps and `libs/LibKa0s/` is byte-identical to v1.8.0 in every consumer. This release is the
test kit alone.

**testkit revision 9 — the LibKa0s provenance line moves to `CLAUDE.md`.**
`testkit/vendor_sync.lua` reads *"Bundles [LibKa0s](…) vX.Y.Z (MIT)."* out of the consuming repo's
`CLAUDE.md` instead of its `README.md`, and names the file through a new `provenanceFile` opt
(default `"CLAUDE.md"`). `readmePattern` is renamed `provenancePattern` and the old name is still
accepted, so no call site breaks.

The line answers "which LibKa0s does this build carry?" — a maintainer's question, on a page written
for players. Across the collection `README.md` is losing its bundled-library inventory entirely, so
the gate's input was about to live in a file whose job is to stop mentioning it.

**There is no fallback to `README.md`, deliberately.** A consumer that re-vendors without moving its
line fails the case, naming `CLAUDE.md`. A fallback would let a repo sit half-migrated with two lines
that can disagree, which is the drift this gate exists to catch.

**Every consumer must re-vendor `tests/_kit/` from this tag, move its provenance line into
`CLAUDE.md`, and regenerate `docs/test-cases.md` in the same commit** — the first case's name changed
to *"libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles"*, which is the only part
of this revision visible outside `tests/_kit/`. `libs/LibKa0s/` does not need recopying; the
provenance line still names the tag both payloads are compared against, so it moves to v1.8.1.

`suites.<name>.gating` in the run manifest was scheduled for removal at kit revision 9 and is
**still emitted**. Dropping a manifest field in a release cut to move one string would put two
unrelated adoption costs on one re-vendor. Nothing reads it; the removal is deferred.

See [`docs/api/testkit/version-9-docs.md`](docs/api/testkit/version-9-docs.md).

## v1.8.0 — 2026-08-05

Versions in this release: **Core minor 5**, **DebugLog minor 8**, **Slash minor 7**,
**Options minor 7**, **OptionsWidgets minor 7**, **OptionsScroll minor 3**, **Perf minor 7**,
**PerfPanel minor 3**. `OptionsScroll.lua` and `PerfPanel.lua` are unchanged and do not move; every
other shipped file does. Six of those eight move for the US-English comment sweep alone — a
comment-only change still bumps, because LibStub picks the winning vendored copy by comparing
minors and a file that does not move never reaches a host already carrying the old copy.

**testkit revision 8**, and it is a substantial one: five additions and three fixes, described
below. **Every consumer must re-vendor both payloads from this tag** — the library folder and the
kit — and the kit's `run-automated-tests.sh` needs its exec bit set in the index on arrival.

**US English across the shipped payload, and a gate that keeps it.** 36 British spellings —
`colour`, `grey`, `behaviour`, `synthesised`, `normalised`, `recognise` — in the comments and
docstrings of every shipped library file and of `testkit/`. `localization-§5` mandates US English and
anti-pattern #46 names code comments explicitly, and **no consumer could fix this**: `libs/LibKa0s/`
and `tests/_kit/` are re-vendored whole-folder, so a local patch is reverted by the next re-vendor
(anti-pattern #48) — which is why one consumer's review carries 29 of these as a finding against
*it*. Comments and docstrings only: no identifier, no `lib.SKIN` key, no user-visible string, and no
Blizzard symbol (`SetColorTexture`, `SetBackdropBorderColor`) moves, and released entries in this
file are history and stay. The same commit retires the two `Ka0s standard §3.4` references in
`Options.lua` to `library-stack-§4` — that file is vendored byte-for-byte into eight addons, so
sweeping it later would redden eight vendor-sync gates against a payload they cannot patch.
`tests/test_prose.lua` fails the run on either regression, listing `file:line`; the sweep alone
regresses on the next feature.

### `LibKa0s-Options-1.0` — `O.PADDING_X`, and the published/internal split written down (**Options minor 7**)

`lib.LAYOUT` holds thirteen constants and the instance published three. `PADDING_X` — the horizontal
inset the library draws its own header, divider and body to — was not among them, so a host aligning
a bespoke widget with any of the three had no way to read it and restated it instead. One did:
`Const.PANEL_PADDING_X = 16`. options-ui-§8's MUST NOT against host copies cannot be complied with
for a number the library keeps to itself.

- **`O.PADDING_X` is published on the instance**, as an individual scalar. Value unchanged, so **no
  panel moves a pixel**; a host deletes its copy and reads this instead.
- **Not `O.LAYOUT = L`, and not the other five.** Handing out the lib-level table lets one host's
  mutation retune every other host's panels. And `HEADER_TOP`, `HEADER_HEIGHT`, `DEFAULTS_W`,
  `SECTION_TOP_SPACER` and `SECTION_BOTTOM_SPACER` have **no demonstrated consumer anywhere in the
  collection** — publishing on repetition rather than on a demonstrated need is anti-pattern #55
  (`library-stack-§7`), and under the additive-only rule a wrong shared abstraction is surface the
  library keeps forever. Each is published the day a host shows it needs it.
- Every unpublished `lib.LAYOUT` key now carries an `-- INTERNAL: <KEY> — <why>` line, and
  `tests/test_options.lua` fails on a key that is neither published nor annotated. That case is the
  durable half: it makes "not yet" a decision on the record rather than a gap nobody notices.

### `LibKa0s-Perf-1.0` — a record that asserts only what it observed (**Perf minor 7**)

`buckets = { { key = "paintBar", within = "repaintPass" } }` was a claim nothing checked. The
descriptor's `within` was written into every record and printed as a containment sentence — *"buckets
nest: repaintPass contains paintBar"* — with no part of the library ever having seen the two run
inside one another. One consumer's descriptor declares two buckets inside a pass neither ever runs
in, and every capture it has archived states that containment as fact. A wrong `within` is worse than
none: a reader who trusts it subtracts the wrong parent's time.

- **`Perf.Note(key, ms, parentKey)`** takes the bucket the work actually ran inside. The third
  argument is optional and **every existing call site keeps working untouched** — containment is
  supplied at the *recording* call rather than inferred from a bracket stack, because the inline
  `local t0 = Perf.on and debugprofilestop()` … `Perf.Note(key, …)` form is what every wired host
  actually uses. A host adopts the parent one call site at a time, or not at all.
- The record carries **`observedWithin`** (and `observedMixed`, when one bucket is seen under two
  different parents) beside the declared `within`. Both are optional and additive within schema 2:
  an older record is unchanged, and a bucket nobody supplied a parent for simply lacks the key.
- The report now distinguishes the three states it was collapsing into one — *observed inside X*,
  *declares itself within X — not observed*, and *declares itself within X but was observed inside
  Y*. The library no longer asserts containment it did not observe (performance-§3).
- **`Perf.Open(key)` / `Perf.Close(key)`.** Shape B's slot now carries the bucket key, so it can be
  matched to its Close and can name the parent of a bracket opened inside it; a bracket nested in
  another therefore records its containment observed. The old `Open()` → `t0` / `Close(t0, key)`
  spelling is **replaced, not deprecated** — a grep of the whole collection finds no call site.
- **The docstring said the pair costs "one boolean test and nothing else, and allocates nothing on
  either path". That was false**: it is two real Lua calls against the inline form's none. It now
  says so, and says which shape to use where (performance-§2). `tests/test_perf_isolation.lua` holds
  the measured zero-allocation case for the dormant path that the claim always needed.
- `Perf.Note` and `Perf.Open` **name the caller** on a nil key instead of raising a bare
  `table index is nil` from inside the library.
- **`perf cancel` clears the context stamp.** It cleared the run, the counters and the label but left
  the character, realm and zone standing, so a `perf report` after a cancel printed empty buckets
  wearing the discarded run's identity.

**testkit revision 8.** Five additions, three fixes. Revision 7 was cut inside this same wave and
never tagged, so its two runner changes are folded in here and no consumer ever saw a rev-7 copy.

- **`Kit.skip(reason)` — a third case status.** A gate that cannot run its comparison used to
  `return` early, which registers as a PASS: six repos' vendor-sync gates reported green on a
  missing sibling checkout. `skip` is counted and printed separately, and the release gate reads a
  `skip` as NOT EVALUATED rather than as a pass.
- **`Loader.xmlFiles(path)` — the vendored-library load list, derived rather than re-typed.** A
  runner that hand-lists the library's files loads a stale set the day a file is added.
- **The suite inventory is pinned in both directions.** A `tests/test_*.lua` on disk but absent from
  the runner's list — and the reverse — fails the run instead of silently never executing.
- **`Kit.assertSurfaceParity(live, degraded, label, ignore)`.** A degraded stub is asserted as a
  SET against the live surface, reporting every divergence in one message, and catching a key that
  is a function live and something else degraded. Member-at-a-time assertions are how three repos
  shipped a stub missing exactly one member.
- **`vendor_sync.lua` — the consumer-side payload gate, once.** `VendorSync.register(T, opts)` is a
  factory, so a consumer keeps its own test global and its own case names while the ~150 lines that
  were copy-pasted into six repos live in one place.
- **Suite durations are milliseconds that cannot be negative.** Every suite was timed with whole
  seconds and reported ×1000, so a sub-second suite recorded `0` and a second boundary crossed the
  wrong way recorded a NEGATIVE duration. A single millisecond clock is resolved once and named in
  `manifest.json` as `host.timingSource`. Committed manifests keep their bad numbers — frozen
  evidence is not rewritten.
- **`run-automated-tests.sh` is 100755 in the index.** It was 100644 in all nine repos, invisible
  because `core.fileMode=false` and DrvFs both hide it. `tests/test_kitsync.lua` now asserts the
  mode from `git ls-files -s` — the index, never `ls -l`, and never the bytes, which do not carry
  it.
- **`RESULTS.md`'s lead-in names the checkpoint, and `gates` replaces a boolean that could not.**
  "`perf` and `complexity` are recorded and never fail a run" is true of the run and the commit and
  false of the tag, which `automated-tests-§3` gates on all four suites at `pass` plus zero
  functions above CCN 15. The lead-in now says which checkpoint each clause is about, and
  `manifest.json` emits `"gates": { "commit": …, "release": … }` beside the legacy `gating`
  boolean, which stays for one revision. Both fields are decorative — `/wow-addon:bump-version`
  reads `suites.<name>.status` and `suites.complexity.warnings` and neither of them.

The runner also now works in a repo with **no `.toc`**. It located the addon by globbing `./*.toc` and
exited when it found none, so the repo that owns this kit could never run it — which is exactly why
two runner bugs survived five revisions: the only repo whose suite runs the kit against itself was
the one repo that could not exercise the kit's output path. A library has no `.toc` by definition,
so identity falls back to the repo directory and version to the newest semver tag. LibKa0s now
produces its own automated-test record like every consumer.

The luacheck skip hint said `pipx install luacheck`. luacheck is a **Lua** package —
`sudo luarocks install luacheck` — and the wrong hint had already been copied into two of the
plugin's command specs. `pipx install lizard` is correct and unchanged.

Every consuming addon has a `.toc`, so that change alone is a no-op for all of them, and the
luacheck hint only alters a message printed when the tool is missing. The other eight are not, and
this is the release to re-vendor for.

## v1.7.0 — 2026-08-04

Versions in this release: **Core minor 4**, **DebugLog minor 7**, **Slash minor 6**,
**Options minor 6**, **OptionsWidgets minor 6**, **OptionsScroll minor 3**, **Perf minor 6**,
**PerfPanel minor 3**. `DebugLog.lua` and `PerfPanel.lua` are unchanged and do not move.

**testkit revision 6** carries two runner fixes, both found by this pass and both silent until it.
`Max CCN` was read from lizard's `!!!! Warnings` block, so it reported `0` for any addon that had
reached zero warnings — the exact moment the number matters most. And `RESULTS.md` rows never
appended in a CRLF repo: the guard matches the header as a substring while the awk that inserts the
row compares it exactly, so the guard passed, nothing was written, and the branch that warns was
never reached. Every consumer is CRLF-pinned, so every run in every addon dropped its row with no
message. Neither was caught earlier because LibKa0s is the only repo whose suite runs the kit
against itself, and it has no `RESULTS.md`. **Consumers must re-vendor and regenerate.**

A complexity pass across the whole collection found the same shapes hand-written in three, four and
six repos at once. Five of them earned promotion here — the test being *present in 2+ repos with the
same semantics, no per-addon escape hatches, a stable abstraction rather than a coincidence of
today's code*. Everything else in this release is internal restructuring: no chat string, event
registration, SavedVariables key or slash output changes, and every existing descriptor keeps
working untouched.

### `LibKa0s-Slash-1.0` gains the sub-command vocabulary — `SplitVerb`, `FindCommand`, `CommandRows`, `ParseBool`

Two hosts had already copied byte-identical `lowerFirst` / `findCommand` file-locals out of this
dispatcher, and both had then hand-rolled a *second* command-row format beside the library's own —
which is exactly the drift the shared formatter exists to end, one level down. All four are
lib-level and stateless, in the shape `FormatRow` / `FormatKV` already set:

- `lib.SplitVerb(rest)` — verb lowercased, remainder's case and internal spacing preserved. The
  asymmetry is the contract: a verb is an identifier, a remainder is user data, and AceDB profile
  names and schema paths are both case-sensitive.
- `lib.FindCommand(list, name)` — linear scan of the `{ name, description, handler }` array the
  `commands` descriptor field has always taken, so a sub level reuses this major's vocabulary
  rather than inventing one.
- `lib.CommandRows(prefix, commands, indent)` — the instance-local `rows(indent)` generalized.
  `Sl:HelpRows` and `Sl:LandingRows` are now one-liners over it, so every level renders through one
  formatter by construction.
- `lib.ParseBool(word)` — the eight-word set `lib.STRINGS.ERR_BOOL` already advertises, as a
  module-level constant table. `nil` means *not a boolean word*, never *false*, which is what lets
  a caller implement toggle-on-absent. Three copies existed, one of them already inside this file
  and unreachable.

The dispatcher itself is deliberately **not** promoted: its control flow is genuinely per-host
(bare `/kcd debug` toggles a window, `/cm priority <cat>` resolves a category between the two
levels), and owning it would cost four escape hatches to save six lines.

### `LibKa0s-Options-1.0` gains `O.BuildLandingPage` and `O.TextRow`

Three hosts each defined a function literally named `Helpers.BuildMainContent` rendering the same
page, with the same four constants at the same values and the same guard pairs; the only real
differences were the logo path and where the one-liner came from. Every primitive underneath it was
already in this major — `EnsureScroll`, `ClearScroll`, `AddSpacer`, `Section` — and `buildMain(ctx)`
was already the seam it hangs off, so the copies were host-side only because the *body* was.

- `O.TextRow(ctx, text, opts)` — a full-width Label, left-justified, added to the scroll. It owns
  the `if w.label and w.label.SetJustifyH` / `SetFontObject` guard pair **once**; that pair was
  written out 28 times across six repos, and every copy is a place for one half to be forgotten,
  which fails silently and only in game.
- `O.BuildLandingPage(ctx, spec)` — logo, one-liner, then a heading and its rows per section.
  `spec.notes` may be a function, called at render time, because a host reading its TOC Notes
  cannot resolve it at declaration; `spec.sections[i].rows` is a function for the same reason, so a
  re-render picks up a command added since registration.
- `lib.LAYOUT` gains `LANDING_LOGO` (300), `LANDING_GAP_LOGO` (8), `LANDING_GAP_DESC` (12) and
  `LANDING_GAP_HEAD` (6) — the four constants the three hosts had already agreed on.
  `LANDING_GAP_HEAD` must stay equal to `SECTION_BOTTOM_SPACER`, which `O.Section` already emits,
  so the page does not draw a second gap under every heading. `tests/test_options.lua` pins that.
- **The descriptor is unchanged.** A host reaches the landing page through the `buildMain(ctx)` it
  already had — `buildMain = function(ctx) O.BuildLandingPage(ctx, spec) end` — and a host wanting
  extra content below calls `O.BuildLandingPage` as line one of its own body. The shell deliberately
  does *not* sniff for a spec field and install a renderer on the host's behalf: that would change
  what `lib:New` **does** rather than add to what it offers, and it would make "what draws my main
  page?" unanswerable from the host's own source. `lib:New` answers exactly what it answered at
  minor 5.

### `LibKa0s-Core-1.0` gains `lib.RGBA`

Promoted mainly because **this library had two disagreeing copies**: `Slash.FormatValue` read both
storage shapes, `OptionsWidgets.decodeColor` read only the keyed one — so the library's own CLI
could render a color its own widget could not decode.

`lib.RGBA(c, dr, dg, db, da)` returns four numbers, never a table, from either the keyed
`{ r =, g =, b =, a = }` or the positional `{ r, g, b, a }` shape. Whichever shape wins, wins for
all four channels, so a `{ r = 1 }` cannot borrow its green from `c[2]`; each channel then falls
back independently, so a three-element color still gets its alpha. Absence is tested with `== nil`
rather than `or`, which is what makes a stored `false` survive — `0` was never at risk, since `0` is
truthy in Lua and `(0 or 99)` is `0`. The defaults are per-channel
parameters and are deliberately not defaulted — the call sites across the collection genuinely
disagree, and inventing a house default would silently recolor one of them.

**The library's own two call sites do not adopt it yet.** `Slash.lua` and `Options.lua` declare
`NEEDS_CORE = 1`, and `docs/releasing.md` treats raising that floor as a breaking change to the
*vendoring* — every consumer still carrying a stale `Core.lua` would lose the whole major. This is
the same reason `enumList` is duplicated verbatim between the two majors rather than hoisted. So
`lib.RGBA` ships for hosts now, and the library folds its own copies in only alongside a floor
raise made for other reasons.

### `LibKa0s-Perf-1.0` gains `P.Open` / `P.Close`

A measurement bracket for **multi-exit** functions, which is where the old ergonomics discouraged
instrumenting exactly the code that most needed it: one adopter's four-exit poll function needed
its own `if __t0 then P.Note(...) end` per exit, and its comment records that the instrumentation
was originally omitted for that reason — an omission that then cost 73.9 ms of unattributed time in
the first live capture.

`P.Open()` returns `debugprofilestop()` or `nil` when the probe is off; `P.Close(t0, key)` treats a
`nil` `t0` as a silent no-op, which collapses every exit to one unconditional statement. Not a
closure-returning `Bracket`: a per-bracket closure would allocate on a path whose entire contract
is costing nothing when disabled. `P.Note` is unchanged, so an existing host keeps working
untouched.

### Internal: every function in `LibKa0s/` is now under CCN 15

`Core.ApplySkin`, `Slash.FormatValue`, `Perf`'s report builder, `OptionsWidgets`' row renderer and
`OptionsScroll`'s gutter patch were each above the collection's complexity cap. They are now
module-level dispatch tables, named file-locals and small builders — `applyBackdrop` /
`ensureInnerBorder` / `applyInnerBorder` / `applyAccents`, `colorChannel`, `addFpsLines` /
`addBucketLines` / `addNestingNote` / `stepState` / `armStates`, `startRow` / `startGroup` /
`drawRow` / `endGroup` / `takeOnce` / `renderRowGuarded`, `thumbOf` / `stepButtons` /
`forceGutter`. Behavior is identical; the tables and the helpers are built once at file load, so
nothing on a hot path gained a per-call allocation.

## v1.6.3 — 2026-08-04

**No library file moved.** `testkit` revision **4 → 5**; `run-automated-tests.sh` only. Three changes
to `RESULTS.md`, all about what the trend table can be trusted to say.

### The table carries size and averages, not just totals

Run · Version · Lint w/e · **Files** · Tests · Perf · **NLOC** · **Funcs** · **Avg NLOC** ·
**Avg CCN** · Max CCN · CCN warn · Verdict.

An average without its total, or a total without its average, cannot be read across a change in
size — which is the one thing a trend line exists to do.

### A suite that was not selected renders as `—`, not as its zeroed counters

`--suite lint` previously wrote `0/0` into the Tests column, indistinguishable from a full run that
found no tests. The trend line would have carried that forever. `skip` (tool absent) and `—` (not
asked for) are different facts about *why* a number is missing, and both differ from zero.

### A changed column set no longer silently recreates the file

The runner appends by matching the header. When it does not match — an older column set — it now
warns and leaves the file alone, rather than starting a fresh table and dropping every previous row.
That is the one failure a trend line cannot survive, and it would have happened on the first run
after any future column change.

## v1.6.2 — 2026-08-04

**No library file moved.** `testkit` revision **3 → 4**; `run-automated-tests.sh` only.

### The manifest records all eight of `lizard`'s footer fields

```
Total nloc   Avg.NLOC  AvgCCN  Avg.token   Fun Cnt  Warning cnt   Fun Rt   nloc Rt
      7532       6.5     1.7       45.9     1047            2      0.00    0.02
```

Revision 3 kept the totals and `AvgCCN` and dropped `Avg.NLOC`, `Avg.token`, `Fun Rt` and `nloc Rt`
on the floor, which meant a run's analysis could only ever report totals.

The averages are what make one run comparable to another **across a change in size**. A total that
rose because the addon grew is a different fact from an average that rose because it got denser, and
only the second is a complexity signal — so totals alone make a growing addon look like a degrading
one, every release, until nobody reads the row. `suites.complexity` now carries `nloc`, `functions`,
`avgNloc`, `avgCcn`, `maxCcn`, `avgToken`, `warnings`, `warnFunRatio`, `warnNlocRatio`, `bandFiles`
and `overCapFiles`, and the console line reports them too.

## v1.6.1 — 2026-08-04

**No library file moved.** `testkit` revision **2 → 3**; `run-automated-tests.sh` only.

Two fixes, both found by *using* revision 2 across the collection rather than by a test — which is
the argument for adopting a new kit widely and quickly rather than in one repo.

### Artifacts are written without ANSI escapes

`luacheck` and the harness colour their output when they believe a terminal is attached, and the raw
escapes were landing verbatim in `lint.txt` and `tests.txt`:

```
Checking core/Compat.lua    <0x1b>[0m<0x1b>[32m<0x1b>[1mOK<0x1b>[0m
```

Unreadable in an editor, and pure noise in a diff between two runs — which is most of what a stored
artifact is *for*. The parsers had always stripped colour for their own use; the stored evidence now
gets the same treatment (`strip_ansi` on every emitted artifact, plus `--no-color` where `luacheck`
supports it, probed once rather than assumed).

### Run directories are stamped in local time, `YYYYMMDD-HHMMSS`

Was `YYYY-MM-DD-HHMMSS` in UTC. A record is read by the person who ran it, usually minutes later, and
a folder name that disagrees with their clock costs a mental conversion on every glance. The manifest's
`startedAt` now carries an explicit UTC **offset** (`2026-08-04T17:03:11+05:30`) rather than a `Z`, so
the instant stays unambiguous once the record outlives the machine — local for reading, offset for
arithmetic.

"Local" is the *machine's* timezone: a host left on `Etc/UTC` stamps UTC and is behaving correctly.
A developer expecting their own wall clock sets the system timezone, not the runner.

## v1.6.0 — 2026-08-04

**Core minor 3**, **DebugLog minor 7**, **Slash minor 5**, **Options minor 5**,
**OptionsWidgets minor 5**, **OptionsScroll minor 2**, **Perf minor 5**, **PerfPanel minor 3**.
**No library file moved** — this release is entirely `testkit/`, whose revision goes **1 → 2**.

### `testkit` — the consolidated automated-test runner

`testkit/run-automated-tests.sh` is new, and it is the only executable in the kit. It runs the four
out-of-game suites — `luacheck`, the headless `tests/run.lua` harness, the offline `tests/perf.lua`
scenarios and `lizard` — and records every result as one frozen bundle under
`docs/automated-tests/<YYYYMMDD-HHMMSS>/`, then rolls the run into `docs/automated-tests/RESULTS.md`.
The normative rules for the artifact are the standard's (`automated-tests`); this is the tool that
produces it.

It lives in the kit rather than in each addon for the reason the rest of the kit does: it must be
byte-identical in nine places, and the vendoring gate already enforces exactly that.

Two properties are load-bearing and deliberate:

- **`lint` and `tests` gate; `perf` and `complexity` do not.** The latter two are measured, recorded
  and diffed, never used to fail the run. `performance-§9`/`§10` are explicit that a wall-clock or
  complexity threshold which fails a run teaches everyone to reach for `--no-verify`, after which
  the gate protects nothing and the habit remains. Folding them into a red/green battery would have
  quietly reversed both rules.
- **A missing tool is a skip, not a failure**, and the skip is recorded *with its reason*, so a
  green run that measured nothing cannot be mistaken for a green run that measured everything.

### The harness summary is parsed in both shapes it comes in

The collection ships two summary lines — `N passed, N failed, N total` and the older
`N passed, N failed`. Matching only the first recorded **0 passed, 0 failed, 0 total** for every
addon using the second, while the run still reported **green** off the harness's zero exit code. A
green run reporting zero tests is the precise failure this runner exists to make impossible, and it
was caught on the first adoption sweep rather than by a test, which is worth recording.

Both shapes now parse, and a zero-exit run whose count cannot be read is recorded as a **skip with
that reason**, never a pass: reporting green off an unparsed summary is worse than reporting a
failure, because it is believed.

### `*.sh text eol=lf` is now required, here and in every consumer

Everything in this collection is CRLF, pinned by `.gitattributes`. A `#!/usr/bin/env bash` line
followed by CRLF makes the kernel look for an interpreter literally named `bash\r`, and every
`case`/`in` becomes a syntax error — so a CRLF-pinned repo that ships a `.sh` must carve it out.
Without that line the vendored runner is broken on **every** checkout rather than in one
contributor's, and it fails identically for everyone, which is the kind of breakage that reads as
"the script is wrong" rather than "the checkout is wrong".

Re-vendoring also now ends with `chmod +x tests/_kit/run-automated-tests.sh`: `cp` does not reliably
carry the executable bit across filesystems.

### Kit revision 1 → 2

Nothing in the Lua surface changed. No suite, mock seam or assertion behaves differently, and a
consumer upgrading from revision 1 re-vendors the folder and gains one file. The revision moved
because the kit's **file set** moved, which is what the byte-identity gate compares — a consumer
still holding four files fails `test_vendor_sync.lua` on the set comparison before it ever reaches a
content diff. Full surface: [`docs/api/testkit/version-2-docs.md`](docs/api/testkit/version-2-docs.md).

## v1.5.0 — 2026-08-02

**Core minor 3**, **DebugLog minor 7**, **Slash minor 5**, **Options minor 5**,
**OptionsWidgets minor 5**, **OptionsScroll minor 2**, **Perf minor 5**, **PerfPanel minor 3**.
Only `DebugLog.lua` moved.

### `DebugLog` — the gated sink can no longer raise on a format it cannot fill

`D.Debug(tag, fmt, ...)` routes every vararg through `safeToString` and then hands the results to
`string.format`. That covers a `%s` slot, which is what the guard was written against — but a WoW
combat "secret" is a **number**, and a host logging one through a **numeric** slot
(`NS.Debug("Absorb", "total=%d", UnitGetTotalAbsorbs("player"))`) handed `"<secret>"` to `%d`, where
`string.format` raises exactly as the unguarded secret would have.

That put the raise back on precisely the path this sink exists to protect (debug-logging-§4): an
unguarded secret reaching a log line inside a repeating ticker kills the ticker, and the feature
stays dead until `/reload`. The pre-stringification made the common case safe and left the case the
guard was *for* no safer than before.

The format is now `pcall`'d, and on failure the line still **lands** — the format string verbatim,
then the stringified arguments, space-joined — because a dropped line is the other way to lose the
diagnostic. A satisfiable format renders byte-for-byte as it did at minor 6, so **no consumer's
output changes**: the only behaviour that moved is a path that previously threw.

Found by **WhatGroup**, the sixth adopter, whose hand-written console had guarded this since its
WG-22 and whose suite went red on the first load of the library's sink. `tests/test_debuglog.lua`
gains the case for the repair and a second one pinning that an ordinary format is *not* routed
through the fallback.

## v1.4.0 — 2026-08-02

**The shipped payload is byte-identical to v1.3.1.** No file in `LibKa0s/` changed, so no LibStub
minor moved: **Core minor 3**, **DebugLog minor 6**, **Slash minor 5**, **Options minor 5**,
**OptionsWidgets minor 5**, **OptionsScroll minor 2**, **Perf minor 5**, **PerfPanel minor 3** —
every one of them exactly where v1.3.1 left it. A consumer that re-vendors gains no library change.

What this release is for is the **test kit** and the **documentation**, and the kit is the part that
is not cosmetic: `testkit/` now carries a revision, so a consumer can be re-vendored against a
release rather than against whatever `master` happened to hold.

### `testkit` — the kit carries a revision (`Kit.VERSION = 1`)

The kit is still not a LibStub major: it registers nothing, no load order depends on it, and two
copies never negotiate — the vendoring gate is byte-identity, not version comparison. What it could
not do before is answer *which* kit a consumer holds, reachable only by diffing against this repo at
the right commit. `Kit.VERSION` at the top of `framework.lua`, reaching suites as `KIT_VERSION`
through `Kit.expose`, answers it and names the kit's API document.

One number for all three files, because they vendor as one folder and are never adopted separately —
the opposite of `LibKa0s/`, where a per-file minor exists precisely because a host may hold a
different vendored copy of each major.

Two gates come with it in `tests/test_kitsync.lua`: `Kit.VERSION` must be a positive integer that
reaches the exposed table, and the API document for the live revision must exist. That is the bargain
`tests/test_versioning.lua` already strikes for the library's minors — a bump cannot land without its
document.

**This is why the release exists at all.** prettychat pins its vendored kit to the LibKa0s tag its
README provenance line names, and asserts it file by file. Kit revision 1 was on `master` and in no
tag, so it could not be vendored into prettychat without that gate failing — correctly. Six other
consumers took the kit anyway, because none of them has an equivalent check, which left their
provenance lines naming a release their `tests/_kit/` no longer matched. Tagging this release is what
makes all seven honest again.

### `docs/api/` — the API reference is versioned by folder

Every public contract now lives in `docs/api/<Major>/version-<minors>-docs.md`, one document per
**shipped** version, frozen once that version stops being current. The version key is the file
minors joined in load order — exactly what `lib.MODULES` reports — so the number read from the game
names the file:

```
/dump LibStub("LibKa0s-Options-1.0").MODULES
--> { Options = 5, OptionsWidgets = 5, OptionsScroll = 2 }
--> docs/api/Options/version-5.5.2-docs.md
```

Thirteen documents, backfilled from source at each tag rather than from memory: Core 2–3, DebugLog
3–6, Slash 4–5, Options 3.3.2/4.4.2/5.5.2, Perf 5.3, and testkit 1. Every table carries a `Since`
column naming the minor a member arrived in. Minors below the v1.0.0 tuple are named in the index and
left undocumented — they existed only en route to the first tag and no consumer ever vendored one.

The reason it is folder-versioned rather than left to git: consumers re-vendor independently, so at
any moment two of them may be on different minors of the same major, and both need an answer to
"what does *my* copy do?".

`README.md` collapses from 792 lines to a map that points at `docs/api/` rather than restating it,
and `docs/releasing.md` gains **step 5** — write the new version's document, mark the old one
superseded — which renumbered tag to 7 and re-vendor to 8.

### Adoption

prettychat is **consumer #7**, taking Core, DebugLog, Slash and Options and declining Perf on the
clearest structural grounds in the collection (`LIBKA0S-12`). It is the first host to pass
`sep = ""`, and the first to use Slash minor 5's `format` hook on a row type the library can already
render. PanelMaster (#6) and LootHistory were recorded earlier in the same window. Only WhatGroup
remains a target.

prettychat also found a gap worth naming here: **a free-text `string` row cannot hold a value
containing a space.** `lib.ParseValue` splits the remainder on whitespace and `parseString` returns
the first token, so `/pc set <path> You receive loot: %s` stores `"You"` — silently, with only the
echo showing it. A descriptor `parse` is the sanctioned workaround and prettychat supplies one, but
this is the ordinary row the `dialogControl = "EditBox"` widget writes, not an exotic type.

### Internals

Ten Markdown files renormalised to the CRLF `.gitattributes` mandates, and four stale step
references in `docs/releasing.md` repointed after the step-5 insertion.

## v1.3.1 — 2026-08-02

Versions in this release: **DebugLog minor 6**. Every other file is unchanged.

### `LibKa0s-DebugLog-1.0` — `makeCloseButton` is documented as the wrong answer

No behaviour change. The field's documentation was written from the point of view of the two hosts
that asked for it and read as an invitation: *"for a host whose other windows close with a different
one"*. Both of them took it, passed their main window's 24×24 class-coloured ×, and shipped debug
consoles and copy windows that matched their own addon and no other — while the three hosts that
passed nothing wore Core's thin 18×18 ×.

That is the same root cause as v1.3.0's border split, one field along, and the same answer: the
**edge** is shared across every Ka0s window (`Core.SKIN`), but the **close control on a
library-drawn window is the library's**. The descriptor comment now says so, notes that the field
has no consumer, and narrows it to a close control that is genuinely *different in kind* rather than
merely the host's own. `standalone-windows` in the Ka0s WoW Addon Standard carries the normative
half.

A regression guard comes with it: a console built with no `makeCloseButton` must reach
`Core.MakeCloseButton` exactly twice — once for the console, once for the copy window. It spies on
the `core` table rather than on the returned button, because `lib.MakeCloseButton` forwards through
that table at call time, so a default that stopped being Core's would stop reaching the counter.

## v1.3.0 — 2026-08-02

One change, and it is a **look** change rather than an API one: the Ka0s window edge is now defined
in the library instead of in whichever host happened to draw it.

Versions in this release: **Core minor 3**, **DebugLog minor 5**. Every other file is unchanged.

### `LibKa0s-Core-1.0` — the window edge is the flat 1px Ka0s double border

`lib.SKIN` changes VALUES, which no release before this one has done. Read the note below before
taking it.

Five consoles side by side did not read as one suite of addons. BankLedger and LootHistory draw
every window with a flat 1px black edge, a 1px light-grey highlight synthesised just inside it, a
gold title and a grey divider under the title bar — and passed `applySkin` at DebugLog minor 4
specifically so their consoles would keep matching their own windows. AbsorbTracker, ConsumableMaster
and KickCD passed nothing and got this library's 12px `UI-Tooltip-Border` with a black divider and an
untinted title. The two groups looked like different addons, which is the one thing a shared skin
exists to prevent.

The definition moved to where the majority of the drawn surface already was:

```lua
lib.SKIN = {
  bgFile      = "Interface\\Buttons\\WHITE8x8",
  edgeFile    = "Interface\\Buttons\\WHITE8x8",   -- was UI-Tooltip-Border
  edgeSize    = 1,                                -- was 12
  insets      = { left = 1, right = 1, top = 1, bottom = 1 },   -- was 3
  bg          = { 0.06, 0.06, 0.08, 0.92 },       -- was 0.06, 0.06, 0.07, 0.95
  border      = { 0, 0, 0, 1 },                   -- unchanged
  innerBorder = { 0.24, 0.24, 0.27, 0.85 },       -- new
  divider     = { 0.24, 0.24, 0.27, 0.85 },       -- new
  title       = { 1.0, 0.82, 0.0 },               -- new
}
```

`lib.ApplySkin` grows to make the three calls a table could never describe — the inner-border child
frame (built once, re-tinted thereafter), the title tint and the divider tint — each guarded on both
the skin key and the frame member being present, so a copy window with no divider and a perf panel
with no divider are both fine, and a caller handing it a plain WoW backdrop table still gets a plain
backdrop rather than a raise.

It also takes an **optional second argument**, `ApplySkin(frame, skin)`, defaulting to `lib.SKIN`.
That is what lets DebugLog's descriptor `skin` override reach this one implementation instead of a
second copy of the same calls.

**This is not an additive change and it should not be read as one.** No field is removed or
repurposed and no signature breaks — but every host that passes no `applySkin` sees its debug console
and its perf panel change appearance on the next re-vendor. That is the intent, it is the standard's
call to make rather than the library's, and `standalone-windows` in the Ka0s WoW Addon Standard now
specifies these values normatively so the next addon inherits them without a decision. A host that
genuinely wants something else still has `applySkin` and the `skin` table.

### `LibKa0s-DebugLog-1.0` — one skin implementation, and a divider that is not hardcoded black

`defaultApplySkin` is now a one-line delegate to `core.ApplySkin(f, skin)`, so the console and the
copy window wear exactly what every other Ka0s window wears. The divider's creation-time colour comes
from the skin rather than from a hardcoded `SetColorTexture(0, 0, 0, 1)` — that literal was invisible
while the default border was also black, and became a visible mismatch the moment the border did not
have to be.


`ApplySkin` decides on the **type** of what a frame answered, never on its truthiness. A frame is a
table with a metatable and this library cannot assume what that metatable does with a key it has
never heard of — a consumer's test mock answers *every* key with a function, so `frame.innerBorder`
read back truthy, the build-once guard never fired, and the tint then indexed a function and raised.
That is the whole reason "run each existing consumer's suite" is a release step: it took fourteen of
that addon's cases down and nothing in this repo would have noticed.

`applySkin` and `makeCloseButton` are unchanged and still default to the library's own. What changed
is why a host would pass them: no longer to rescue itself from a default that did not match its
windows, but for chrome that differs in SHAPE rather than colour, or to keep a console tracking the
host's own re-skin seam.

## v1.2.0 — 2026-08-01

Four gaps, all found by adoption rather than by review. Two are the same shape — a host could
express what it needed everywhere except at one hook nobody had asked for. The third is different
and worse: two majors in this library disagreed about what one schema row IS. The fourth is worse
again: every host on the options module has been shipping a settings canvas half-wired to Blizzard,
and the half that was missing is the one the user clicks.

Versions in this release: **Core minor 2**, **DebugLog minor 4**, **Slash minor 5**,
**Options minor 5**, **OptionsWidgets minor 5**, **OptionsScroll minor 2**,
**Perf minor 5**, **PerfPanel minor 3**.

### `LibKa0s-DebugLog-1.0` — the host can own its window chrome

Two optional descriptor fields, `applySkin` and `makeCloseButton`, both defaulting to exactly what
minor 3 did. No existing consumer changes.

BankLedger and LootHistory draw every window with a flat 1px `WHITE8X8` double border, a synthesised
inner-border child frame, a gold title tint and a grey divider, and close them with a 24x24
class-coloured x. `Core.SKIN` is a 12px `UI-Tooltip-Border` and `Core.MakeCloseButton` is an 18x18
fixed-red x. Adopting the console meant either redesigning every window such a host owns, or
declining a module whose two formatters are already byte-identical to the host's own — a 357-line
deletion turned down over chrome.

The `skin` field that already existed cannot close the gap: it is a TABLE, so it reaches the three
backdrop calls and nothing else. An inner-border frame, a title tint and a divider tint are calls,
not fields. `applySkin` is therefore a function that owns the whole job, for the console and the copy
window alike, and it is handed the fully-built frame — `frame.title` and `frame.divider` are already
assigned, so a host's existing "tint whatever this window has" helper works unmodified. It runs at
the same point the library's own did, after the Hide and the Esc wiring, so a surprise inside a
host's skin still cannot strand a visible window nobody can close.

### The title-bar offsets are derived rather than hard-coded

Falls out of the above, and would have been a real defect without it. Copy | Clear | Close read right
to left with a six-pixel gap each, anchored by absolute offset (not chained) because a close-button
factory may answer nil. Minor 3 hard-coded `-30` and `-78`, which are correct only for an 18-wide
button — a host supplying a 24-wide one would have had Clear's right edge land exactly on that
button's left edge and the gap would have vanished.

The offsets now come from the button's measured width, falling back to Core's 18 when `GetWidth`
is not yet positive (a frame before its first layout pass, or a headless stub). For every existing
consumer the arithmetic yields `-30` and `-78` unchanged. The computed values are recorded on
`frame.titleBarOffsets`, for the same reason `frame.titleText` is recorded: an anchor cannot be read
back through the frame API, so that is the only handle a host's own test has on it.

### `LibKa0s-Slash-1.0` — a host can render a value type the library does not know

One optional descriptor field, `format`, defaulting to `lib.FormatValue`. No existing consumer
changes.

It closes an asymmetry rather than adding a feature. `parse` has been a descriptor field since
`-1.0`, so a host has always been able to teach this CLI to READ a value type the library does not
know — and had no way to teach it to WRITE one back. `lib.FormatValue` handles colour, number, bool
and empty string, then falls through to Core's `SafeToString`.

That fallback is the problem. `SafeToString` probes `table.concat`, which refuses a table, so a row
whose stored value is a SET renders as `<secret>` — the CLI telling a user that a plain settings
value is combat-protected. BankLedger stores its muted-store list exactly that way
(`type = "table"`, rendered `{BANK, GUILD_BANK}` or `(none)` by the code the library replaces), and
prettychat needs `|` doubled to `||` so a stored chat pattern renders literally. Neither is
expressible through `colorDecode`, which only fires on a colour row, or through `SetRowAnnotator`,
which appends a suffix after the closing `|r`.

The hook is handed the value **as stored** and takes precedence over `colorDecode`: a host
supplying both is saying it owns rendering, and decoding first would hand the hook something other
than what the host wrote.

### `LibKa0s-Options-1.0` — a numeric enum renders as a dropdown, not a slider

`O.RenderField` sent every `type = "number"` row to `makeSlider` without ever consulting `values`.
But `LibKa0s-Slash-1.0` has treated a number carrying a `values` list as a constrained **enum**
since `-1.0` — `parseNumber` refuses a value outside the list rather than clamping, and its comment
calls the shape *"a NUMERIC dropdown"* and warns that clamping *"lands BETWEEN two entries, and the
renderer then has no label for what is stored"*.

That renderer did not exist. So a host with such a row — BankLedger has two, a retention preset and
a quality threshold — got a CLI that validated an enum and a panel that drew a 0-to-1 slider over
it, because neither row declares `min`/`max`/`step`. Two majors, one row, two answers.

`RenderField` now routes a number row with a non-empty enum list to `makeDropdown`. `makeDropdown`
needed no change: it is type-agnostic and stores the numeric key unmodified.

**Inferred from `values`, not opted into with a `dialogControl`.** Slash infers, and an opt-in here
would leave the two majors still disagreeing for any row that declares `values` and nothing else —
which is the whole defect. The `enumList` duplication comment already states the requirement: *"The
two readers MUST agree — a CLI that accepts a value the dropdown cannot display is worse than either
being wrong alone."* The inference is safe in the failure direction: a `values` function that
answers empty falls through to `makeSlider`, which is exactly the old behaviour.

Additive for every existing consumer: no row in AbsorbTracker, KickCD or ConsumableMaster is a
number carrying `values`, so not one widget changes. The library's own fixture had no such row
either, which is structurally why the gap survived — every dropdown case in the suite was
`type = "string"`. It has one now.

### `LibKa0s-Options-1.0` — `CreatePanel` stamps the Blizzard canvas contract

Blizzard's Settings window calls three methods on a frame handed to
`RegisterCanvasLayout(Sub)category`: **`OnCommit`** when the user applies, **`OnDefault`** from the
window's own **footer** defaults control, and **`OnRefresh`** on re-show. This library declared none
of them.

So every host on it shipped a canvas whose footer Defaults control did nothing — and all three
consumers did exactly that, without noticing, because the header Defaults button this library *does*
build kept working and looks equivalent to the user. Two controls that appear to do the same thing,
one of them dead, is worse than never having offered the second.

`CreatePanel` now stamps all three. `OnCommit` and `OnRefresh` are inert **by design** rather than by
omission: a host's writes land immediately through its own single write seam (options-ui-§1), so
there is no staged state to apply, and `SetRenderer` already owns re-show, so a second refresh path
would race the renderer it duplicates.

**`OnDefault` is a forwarder, not an assignment**, and the ordering is the whole reason. Every host
parks its click handler on the panel *after* `CreatePanel` returns — the Defaults button does not
exist yet, since `EnsureDefaultsButton` builds it on first OnShow — so
`panel.OnDefault = panel.defaultsOnClick` inside `CreatePanel` would capture `nil` forever while
looking perfectly correct. Resolving through the panel at call time also keeps the footer control and
the header button ONE implementation, which is what matters, rather than two that can drift. A page
with no defaults action gets a callable no-op — the point, since the footer control is not per-page
and can be clicked while a landing page is open.

Additive: no consumer set any of the three, so nothing is overwritten. It is not, however,
invisible — **three shipped addons gain a working footer Defaults control** from the re-vendor. That
is the fix, and it is a user-visible behaviour change rather than a silent repair.

Bumping the shell's MINOR makes `OptionsWidgets.lua` and `OptionsScroll.lua` re-attach on load,
because both guard on `__…ShellMinor == lib.MINOR`. That is the designed behaviour — a replaced
shell must be re-bound — and neither file's own minor moves.

## v1.1.1 — 2026-08-01

A payload release. **No code changed and no file minor moved** — every module is byte-for-byte what
v1.1.0 shipped, so a host that re-vendors gains one file and changes no behaviour.

Versions in this release: **Core minor 2**, **DebugLog minor 3**, **Slash minor 4**,
**Options minor 4**, **OptionsWidgets minor 4**, **OptionsScroll minor 2**,
**Perf minor 5**, **PerfPanel minor 3**.

### `LICENSE` ships inside the library folder

The vendored copy in every consumer held nine `.lua`/`.xml` files and nothing else — no licence, no
copyright header on any file, and no adopter's README naming the library at all. Each one was
publishing an addon zip containing MIT-licensed code with no indication it was there or what it was
under.

`LICENSE` is now part of the ship folder rather than repo furniture, so `cp -r LibKa0s/. <Addon>/libs/LibKa0s/`
carries it with no per-addon step and the `diff -r` gate keeps its shape. That is the whole change.

The reason it is its own version rather than a quiet amend: v1.1.0 is tagged and published, so the
tag cannot move, and three consumers now carry a payload that is v1.1.0 **plus one file**. A number
that names it is cheaper than a footnote explaining it.

Per-file copyright headers were considered and deliberately declined — they would touch all eight
files and bump all eight minors, which is a real release for a change that alters no behaviour.

## v1.1.0 — 2026-08-01

Three gaps found by adoption rather than by review, all of them things a host had worked around
in its own setup file first.

Versions in this release: **Core minor 2**, **DebugLog minor 3**, **Slash minor 4**,
**Options minor 4**, **OptionsWidgets minor 4**, **OptionsScroll minor 2**,
**Perf minor 5**, **PerfPanel minor 3**.

### A raising row costs that row — `OptionsWidgets.lua`

`RenderRows` pcalls each row. Options minor 3 guarded each page BUILDER; this is the more common
failure and the one a host cannot pre-empt — one corrupt saved value, or a `values` function that
raises because the media library it queries is half-loaded. Unguarded, it propagated out of
AceGUI's layout pass, every row after it never drew, and the user saw a panel that stopped
mid-way with nothing naming the row. `docs/releasing.md` carried this as a known gap; it is closed.

### `RenderGrid` — the caller-driven sibling of `RenderRows`

`RenderRows` is schema-driven: it walks declared rows, emits a `Section` when `group` changes, and
pairs them automatically. `RenderGrid(ctx, items)` is the other half — the caller decides what goes
in each cell and in what order, and a cell may be a schema row or `{ make = fn }` for a bespoke
widget. `wide = true` breaks an item onto its own full-width row.

That distinction is what a host needs for a list whose LENGTH is not in the schema: one checkbox
per macro, per unit, per spell. Every host had a hand-rolled copy of this loop, which is the
duplication this library exists to end — ConsumableMaster's `Helpers.Grid` was the third. Items are
guarded individually, like rows.

### `LSMValues` never hands back an empty list — `Options.lua`

An empty list made the row unusable rather than merely unpopulated: a dropdown with no options
cannot be opened, and the CLI's allowed-values check refuses every value, including the one already
stored. A media row whose library has not loaded yet now offers a single `None` placeholder, which
is what the one host that had noticed was already doing in its own wrapper.

`None` is a literal rather than a locale key, deliberately: it is also the STORED value, so a
translated one would be written into the host's SavedVariables.

## v1.0.0 — 2026-08-01

The first tagged release. Five majors — Core, DebugLog, Slash, Options and Perf — vendored into
AbsorbTracker, KickCD and ConsumableMaster. The file minors below are what LibStub actually
compares; the tag is the courtesy number for humans.

Versions in this release: **Core minor 2**, **DebugLog minor 3**, **Slash minor 4**,
**Options minor 3**, **OptionsWidgets minor 3**, **OptionsScroll minor 2**,
**Perf minor 5**, **PerfPanel minor 3**.

Grouped by major, newest first. A file's entries live under the major that owns it, so "what changed
in Perf" is one heading rather than a hunt.

### The page registry grew a renderer seam, a guard and a second tier — `Options.lua`

Three regressions a host could not work around, all of which ConsumableMaster's adoption declined
the whole registry over.

**One raising page builder no longer costs every page after it.** `CreateOptionsPanel` ran the
builders in a bare loop, so a single failure left a half-registered options tree with nothing
naming which page did it. Each builder is pcall'd separately now and reports its key; `O.__pages()`
is what actually built. A page registered *after* the build is built immediately rather than queued
behind a drain that has already happened — queued, it silently never appeared.

**A panel opened during combat refuses.** `O.SetRenderer(ctx, fn)` declares how a page draws
itself, and the library owns *when*: first show, and again after a refresh marked it dirty while it
was hidden. It also builds the Defaults button there (the AceGUI skinning reason, unchanged) and
closes the Settings window with the canonical grey notice under lockdown. That last one matters
because the Blizzard AddOns sidebar reaches a panel **without** going through `OpenOptionsPanel` —
so the one guard that existed was bypassed on exactly the path a user is most likely to take
mid-fight. A raising renderer is reported rather than propagated: inside AceGUI's own dispatch it
would take the click handling of every widget on the frame with it.

**Refreshing is two things, and they now have two names.** `RefreshAllPanels` is STRUCTURAL — it
re-runs the page's renderer, so rows that appeared or disappeared are drawn. `RefreshScalars` is IN
PLACE — refreshers only, no rebuild — and it is what every widget maker's own `set()` calls, since
writing a value does not change which rows exist. A page that is not on screen is flagged dirty and
re-renders on its next show instead of being rebuilt fifteen times per keystroke.

`RefreshAllPanels` keeps its name and gains the renderer, which is the one thing here that changes
meaning for an existing host. The migration is opt-in and costs nothing: a ctx that never went
through `SetRenderer` has no renderer to re-run, so both tiers fall back to running its refreshers
ungated, exactly as before. A host adopts the registry one page at a time, or never.

### Alpha, tooltips and live sliders — `OptionsWidgets.lua`

`hasAlpha` defaults to **true** now. This is a flipped default, and the only one in this release.
The old `row.hasAlpha and true or false` made a declared `false` indistinguishable from an absent
field, so no host could express "no alpha" even deliberately — while the colour codec beside it
models alpha as a first-class component of every colour it stores (`a or 1` on write, `c.a or 1` on
read). Suppressing the slider by default contradicted the codec: a stored alpha the user could
never reach. A host that wants the old behaviour writes `hasAlpha = false`, which it can say for
the first time.

The old default was entirely uncovered — the only assertion read a fixture row that declared
`hasAlpha = true`, so nothing anywhere pinned the false. The fixture now carries a row declaring
neither (that is the one proving the default) and a second declaring `false`, because a default
nothing asserts is a default nothing protects.

A tooltip body reads `row.tooltip` first and falls back to `row.desc`. Every Ka0s host's schema
declares `tooltip`; this library invented `desc`. Reading only `desc` therefore blanked the body on
every widget of any host on the standard's own shape — the label still renders, so it fails
silently and only in game. Both names are accepted; nothing has to move.

Sliders can commit on the drag. `sliderCommit = "change"` on the descriptor, or `commitOn` on a
single row, adds a throttled `OnValueChanged` write alongside the `OnMouseUp` one; the default
stays release-only and an unchanged host is untouched. It exists because a page whose number rows
drive something visible while dragging — a bar's width, a button's scale — has no preview without
it, and there was no hook to ask for one. The drag reuses the colour picker's re-armed single timer
rather than the per-frame write a host would write by hand: a 60 Hz drag otherwise fans a refresh
pass out across every registered panel sixty times a second. Live commits snap to the row's step
exactly as the release commit does, or the release would silently correct what the drag stored.

`SetIsPercent` reads `row.isPercent` instead of being hardcoded false, which is the whole reason
that field exists in the schema.

### Colours: the positional shape renders, and hosts get a codec — `Slash.lua`

`lib.FormatValue` reads both stored colour shapes now. The named keys win when present, so a host
storing `{ r =, g =, b =, a = }` renders exactly as before; a host storing `{ r, g, b, a }`
POSITIONALLY used to render every colour as `{0.00, 0.00, 0.00, 1.00}`.

That is the shape the Ka0s options colour widget itself writes — this library's own
`OptionsWidgets.lua` documents the divergence and takes a codec for it, while `Slash.lua` had no
hook at all: `kv()` called the lib-level formatter directly, so a host could not even override it.
Two majors, one collection, opposite assumptions about the same stored value. It shipped green
because nothing outside the Slash suite asserts a rendered colour's VALUE.

`colorDecode` / `colorEncode` join the Slash descriptor under the same names the Options descriptor
already uses, so a host passes one pair to both majors. `CliSet` encodes into the host's shape
before writing, and both echo sites — `CliSet`'s and `CliReset`'s — read back through it.

### Enum rows: the ordered-array shape is read now — `Slash.lua`, `OptionsWidgets.lua`

Both enum readers accept the Ka0s options schema's own shape — an **ordered array** of
`{ value =, text = }` — alongside AceGUI's key map. The array's position is its order, so a row
declared `{ {value="RIGHT"}, {value="LEFT"} }` offers Right then Left in the dropdown and lists
`RIGHT, LEFT` in the CLI's allowed values.

It has never worked. `allowedValues` iterated `pairs(row.values)` and returned the sorted
`tostring`'d KEYS, and the dropdown handed the raw table to `SetList` — so a standard-shaped row
offered `1, 2` as its allowed values and mapped index to table. Every Ka0s addon declares enums
this way, which is why the options row makers and the schema CLI were both declined during
ConsumableMaster's adoption: one defect, two majors, ~250 lines that could not move.

`enumList` is duplicated **verbatim** in both files rather than hoisted into `Core.lua`. Hoisting
would raise `NEEDS_CORE` in two majors, which `docs/releasing.md` calls a breaking change to the
vendoring — every consumer carrying a stale `Core.lua` would lose both majors outright. The two
copies must agree or the CLI accepts a value the dropdown cannot display, so a cross-major parity
case renders each fixture enum and asserts the CLI accepts every option the dropdown offers, in
both shapes. That is the guarantee the duplication buys.

Three shapes were actually in play, not two. `{ SHORT = true }` — a key *set* — is what both
fixtures and several host rows declare, and its labels rendered as the literal string `"true"` in a
real client. Nothing caught it because the AceGUI mock records the list without reading its text.
A set now labels each entry with its key, which is the only honest label it has.

Two behaviour changes fall out, both deliberate:

- A `type = "number"` row **carrying a values list** now rejects an out-of-list value instead of
  clamping it. Clamping lands between two entries, and the renderer then has no label for what is
  stored — the row reads blank and the user cannot tell what they set. A number row *without* a
  list clamps exactly as before.
- A `type = "string"` row **without** a values list now accepts free text. The old reader walked an
  empty allowed-list and therefore refused every value, so `dialogControl = "EditBox"` rows shipped
  un-settable from the CLI.

### `interface` was always 0 — `Perf.lua`

A record's `interface` field is read from `GetBuildInfo()`'s fourth return now, not from
`GetAddOnMetadata(name, "Interface")`.

Blizzard does not serve `Interface` through the addon-metadata API — it serves `Title`, `Notes`,
`Author`, `Version` and `X-*` — so the old lookup answered nil and **every record ever emitted
stamped `"interface":0`**, making an archived capture unattributable to a game build. Confirmed
against a live 12.0.7 client: `C_AddOns.GetAddOnMetadata("KickCD", "Interface")` returns nothing.

This repo had a case pinning the field at `120007`, and it passed throughout — because
`tests/wow_mock.lua` stubbed `GetAddOnMetadata` to return `"120007"` for **any field asked of it**.
A stub that silently succeeds is worse than no stub (kit fidelity rule 1), and this is what that
rule costs when it is broken: the one case written to catch this exact failure could only ever pass.
The mock now answers only the fields Blizzard actually serves, and supplies `GetBuildInfo`.

The semantics shift slightly and for the better: the field is the **client's** interface version
rather than the host's TOC line. For a current addon they agree; when they disagree the client's is
the one that explains the capture.

### The `L` trap — `DebugLog.lua`, `Slash.lua`, `Perf.lua`

An `L` override is now resolved with `rawget` rather than a plain index, in all three modules that
take one.

Every Ka0s host's locale table carries a metatable fallback that answers an unknown key **with the
key** — the standard mandates it (anti-patterns #2). A plain index therefore accepted that
synthesised string for *every* key, so a host that passed its addon-wide locale table made these
modules' own `STRINGS` unreachable and rendered raw keys in place of English. It fails for every
string at once, cannot fail in a headless case that only checks a label is non-empty, and is visible
only in game.

It shipped: KickCD's perf panel rendered `Ka0s KickCDPANEL_TITLE_SUFFIX` and seven `STEP_*` keys.
AbsorbTracker was unaffected because it passes no `L` at all.

`rawget` asks the only question that matters — did the host actually put a value here? A genuine
entry still overrides; a fallback-only table correctly falls through. **Additive and
behaviour-preserving for every existing consumer**: a real entry is `rawget`-visible, so no host that
was working changes.

`PerfPanel.lua` does NOT bump: it receives `tr` as a parameter from `Perf.lua`, so the fix reaches
the step panel without the file changing.

The README's per-module descriptor tables previously said *"hosts on the Ka0s standard pass their
`NS.L`"*, which was precisely the advice that caused this. Corrected, and a **The `L` trap** section
added to the README and to `docs/adoption-prompt.md` with the one-line assertion that catches it:
a rendered label must not match `^[A-Z][A-Z0-9_]+$`.

### Review fixes — all five majors

Found by the `/wow-addon:review` gate on this branch and fixed before it merged. Every file's
minor moves, because every file changed: the en-US sweep below is comment-only but touches all
eight, and whole-folder re-vendoring is mandatory anyway.

- **`Options.lua`** — `EnsureDefaultsButton` reached `O.AttachTooltip` without the guard its own
  closing comment claimed, so a vendored copy missing `OptionsWidgets.lua` raised from the
  library's shell on the first panel `OnShow` rather than degrading. Guarded, like the sibling
  reach into `PatchAlwaysShowScrollbar` already was.
- **`Options.lua`** — the default `print` was a silent no-op alone among the five majors, so a
  host that omitted it got a combat refusal and a missing-AceGUI notice that vanished with nothing
  to grep for. It now falls back to `DEFAULT_CHAT_FRAME`, matching Core, DebugLog and Slash. The
  library still cannot supply the host's tag, so the descriptor's `print` remains the intended path.
- **`Options.lua`** — `:New` now raises on a missing `mainPanelName`. It is the one field whose
  entire purpose is lost silently: a nil yields an anonymous canvas that `/framestack` cannot
  attribute, with nothing visible in game. The other fields' documented no-validation gap stands.
- **`Options.lua`** — `CreateOptionsPanel` is idempotent. A second call registered a duplicate
  Blizzard category and appended a second ctx per page, permanently doubling the `RefreshAllPanels`
  fan-out.
- **`OptionsWidgets.lua`** — `RenderRows` implemented both one-shot hooks by writing `nil` into
  the tables the CALLER owns, so a host that hoisted its `afterGroup`/`pairWith` to a file-level
  constant silently lost every inline button and paired widget on the second render — which a
  per-unit page does on every unit switch. The bookkeeping is now the library's. One-shot semantics
  per call are unchanged.
- **`Slash.lua`** — `FormatValue` fed three of its branches to `string.format` unguarded, and a
  WoW secret raises there exactly as it does in `table.concat`. The invariant that made this safe
  — a stored settings value is never a combat-protected one — was real but written down nowhere
  and enforced nowhere. Guarded at the input, so every ordinary rendered value is byte-identical.
- **`DebugLog.lua`** — `lib.MakeCloseButton` snapshotted Core's function VALUE at file load.
  LibStub upgrades a major in place, so a newer `Core.lua` over an unchanged `DebugLog.lua` left
  the console drawing the old button while `MODULES.Core` truthfully reported the new minor. Now a
  forwarder through the `core` table, the shape `PerfPanel.lua` already used.
- **`DebugLog.lua`** — `D:Add` did not route its message through the secret-safe stringifier,
  though the gated sink and `initSummary` both did. It is public, ungated by design, and the path a
  host's perf output takes.
- **All eight files, and `testkit/mock_base.lua`** — en-US spelling in comments, per the standard.
  Comments only; no string literal moved.

`tests/test_kitsync.lua` is new and closes the gap that let the previous commit ship a
`testkit/README.md` that was never re-vendored: `testkit/` and `tests/_kit/` are now compared
byte for byte, README included, with no line-ending normalisation, and the failure names the file.
It caught a real divergence during this very change.

### `LibKa0s-Options-1.0`

- New module `LibStub("LibKa0s-Options-1.0")` — the Blizzard settings-canvas shell, the schema-row
  to AceGUI translation and the two-column flow engine, in three files under one major
  (`Options.lua`, `OptionsWidgets.lua`, `OptionsScroll.lua`). `lib:New{ parentTitle, get, set,
  applyDefault, rowsForPage, allRows, … }` returns an instance owning its own panel registry, so
  one addon's Defaults button can never run another's refreshers. The basenames are namespaced
  because the changelog check below plain-searches one file for `<Basename> minor <N>`, and
  `Widgets.lua`/`Panel.lua` are exactly what a future window module would want.
- Five widget types ship in `-1.0`, not four: the edit box (`dialogControl = "EditBox"`) is here
  because adding a type later is additive but retrofitting one into a frozen dispatch table is not.
  No AbsorbTracker row uses it; KickCD's label rows do.
- Colour storage is a descriptor codec rather than a baked-in shape, because AbsorbTracker stores
  `{r=,g=,b=,a=}` and KickCD stores arrays, and picking a winner would force one of them to
  translate at every read site in the addon. The 50 ms colour-drag throttle likewise takes the
  host's `scheduleTimer`: embedding AceTimer would be this library's second dependency breach.
- `OpenOptionsPanel` REFUSES under combat and never defers-and-replays, and the gate lives inside
  the open rather than in a host's dispatcher, so a `/run` script is refused too.
- The always-shown scrollbar marker is `_ka0sAlwaysScrollbar`. AceGUI pools ScrollFrames across
  every addon in a session, so per-addon marker names would let two addons each patch a widget the
  other had already patched.

### `LibKa0s-Slash-1.0`

- New module `LibStub("LibKa0s-Slash-1.0")` — the slash dispatcher, the help renderer, the schema
  CLI (`list`/`get`/`set`/`reset`/`resetall`/`version`) and the type-aware value parser. The parser
  is the reason this shape won rather than the coercing one the other copies carry: a number clamps
  to its row's range instead of storing a value the panel cannot honour, a string outside its enum
  is refused with the allowed values listed, and a colour parses `r g b [a]` instead of printing a
  table address. `SetRowAnnotator` lets a host append a note at the three sites that render a
  setting — list, get and set — and at no others.
- The COMMANDS table stays the host's and is passed into the descriptor. A host renders the same
  table on its own About page, so a library owning it would force the options module to consume
  this one — and two libraries reaching for each other is a real dependency cycle.

### `LibKa0s-DebugLog-1.0`

- New module `LibStub("LibKa0s-DebugLog-1.0")` — the on-screen debug console, which was the most
  duplicated thing in the collection: seven hand-transcribed copies of a window the standard already
  specifies down to the hex codes. `lib:New{ name, title, font, isEnabled, setEnabled, … }` returns
  an instance owning its own buffer and its own frames, with every frame global derived from `name`
  so two addons cannot collide on `UISpecialFrames`. The enable flag stays the host's: the library
  reads and writes it through the `isEnabled`/`setEnabled` pair rather than keeping a second copy
  that its slash command and its settings panel would disagree with. `initSummary` makes the
  `[Init]` line a host callback, which is what five of the sister addons already do.
- The buffer cap is now covered: no addon suite ever wrote 501 lines, so the eviction path had never
  run under test.

### `LibKa0s-Core-1.0`

- New module `LibStub("LibKa0s-Core-1.0")` — the two seams every other module sits on. The
  secret-safe seam (`IsConcatSafe`, `SafeToString`, `SECRET`) carries AbsorbTracker's canonical
  `table.concat` probe, the only detector that fails on what a real combat-protected value actually
  fails on; the window chrome seam (`SKIN`, `ApplySkin`, `MakeCloseButton`) holds the backdrop and
  the close × a host's windows share. `lib:New{ prefix, sep, sink }` returns the prefixed,
  secret-safe chat printer, with `prefix` re-read on every call so a host whose tag constant loads
  later can pass a function instead of capturing nil forever.

### `LibKa0s-Perf-1.0`

- **Fixed:** a combat-protected value logged by a perf run rendered as its raw self, then raised
  inside the host's `table.concat(buffer, "\n")` when the user pressed Copy — killing the Copy
  button for the rest of the session. `Perf minor 2` deletes the private stringifier that caused it
  (it branched on `type()`, and a secret *is* a string or a number) in favour of
  `Core.SafeToString`. Perf now declares a minimum Core and refuses to register below it, so a
  missing Core makes the probe absent — which a host's setup stub reports honestly — rather than
  present and nil-erroring mid-run.
- `PerfPanel minor 2` takes its backdrop from `Core.SKIN` instead of a private lookalike, and draws
  Core's close button when the host supplies no `decorate`. `decorate` itself is unchanged and still
  takes precedence; the contract is additive-only.
- Initial extraction from AbsorbTracker (issue
  [#17](https://github.com/tusharsaxena/AbsorbTracker/issues/17)) — the probe, the record schema, the
  guided run, and the step panel, as `LibStub("LibKa0s-Perf-1.0")`.
- Still minor 1: the whole-branch review's fixes fold into the initial extraction rather than
  following it, since nothing has been released yet. A panel now re-attaches whenever the probe
  beneath it came from a different vendored copy; `:New()` reads `lib` rather than `self` throughout,
  so a LibStub minor upgrade cannot leave an instance reporting one schema while emitting another;
  `descriptor.buckets` entries are validated; `ring` is clamped to at least one record; panel labels
  re-resolve on every repaint; and a panel click prints exactly what typing the same command prints.
- `lib.MODULES` publishes the live minor of every file in the major, so version skew across vendored
  copies is answerable from in-game rather than by reading source.

### Documentation

- Documentation: the descriptor contract, the `suspend`/`resume` host contract, the public surface,
  and the record schema (v2) are written up in `README.md` and `docs/record-schema.md` (issue
  [#4](https://github.com/tusharsaxena/LibKa0s/issues/4)).
