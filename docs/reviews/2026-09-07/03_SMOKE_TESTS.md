# 03 — Manual smoke tests (in-client)

Executed **after** the changes in `02_PROPOSED_CHANGES.md` have landed. Everything that runs headless
already ran in Step 0 and lives in `01_FINDINGS.md`'s measurement block — it is not repeated here.

**LibKa0s has no install of its own.** Every check below is performed **in a consumer addon** with the
changed `LibKa0s/` re-vendored into its `libs/LibKa0s/`. Pick a host that exercises the changed
surface: for Theme A you need a host whose General page has **many** tabs (MultiMeters, per
`docs/releasing.md:268`, decorates fourteen page files and is the widest surface); for Theme C you
need any host on `LibKa0s-Options-1.0`.

---

## Pre-flight

**One command, not a checklist** — re-run the headless gate from the LibKa0s repo root before
touching the client:

```sh
lua5.1 tests/run.lua && luacheck .
```

Both must be clean (expect ~768 passing after C-1, and expect C-4 to have gone red once and been
repaired). Then:

1. Copy the whole `LibKa0s/` folder into `<Host>/libs/LibKa0s/` — the entire folder, every time
   (`library-stack-§7`). Confirm all **fourteen** `.lua` files and `media/` arrived, and confirm the
   host's TOC still lists `libs\LibKa0s\LibKa0s.xml` after Ace3.
2. Update the host's `CLAUDE.md` provenance line to the new LibKa0s tag, and run the host's own
   `tests/test_vendor_sync.lua` — it resolves that tag and diffs both payloads.
3. Retail client, current Interface version (the host's TOC decides; LibKa0s has none).
4. `/console scriptErrors 1` — a Lua error must produce a popup, not a swallowed line.
5. `/reload` once before starting, so the session begins from a known state.
6. Have `/framestack` bound or reachable (`/fstack`), and open the chat frame wide enough to read a
   diagnostic line.

**Character:** any max-level character with an accessible target dummy (Valdrakken or Stormwind).
Realm type irrelevant. Both a combat and a non-combat pass are needed for the Options tests.

---

## C-1 — Pooled tab strip

**Change covered:** C-1 — tab buttons and the content panel are acquired from a pool instead of
constructed on every render (F-001).

**Setup.** Fresh `/reload`. Host with a General page carrying at least eight sections, so the strip
has eight or more tabs (and, ideally, wraps to two rows). Out of combat.

**Steps.**
1. `/run local n=0 local f=EnumerateFrames() while f do n=n+1 f=EnumerateFrames(f) end print("frames:",n)` — record the number as **N0**.
2. Open the host's settings: `/<host> config`.
3. Click every tab on the General page, left to right, then right to left. Repeat the full sweep
   **ten times** (so ~160 tab clicks on an eight-tab page).
4. Close the settings panel.
5. Re-run the frame count from step 1 — record as **N1**.

**Expected.** `N1 - N0` is **under 30** — the pool's high-water mark plus whatever the panel itself
built once. Before this change the same sweep would add roughly *tabs × clicks* frames (~1,400 on an
eight-tab page, ~2,300 on a thirteen-tab one).

**Pass / Fail.** PASS if `N1 - N0 < 30` **and** no Lua error popup appeared during the sweep.
FAIL if the delta scales with the number of clicks.

### C-1b — a reused tab still works

**Steps.**
1. On the General page, click tab 3. Confirm tab 3's rows render and tab 3 is the disabled (selected)
   one.
2. Click tab 1, then tab 3 again — so tab 3's button has now been released and re-acquired at least
   once.
3. Confirm tab 3 renders the same rows, is disabled, and carries the **selected** atlas (visibly
   brighter, label lifted 2px) — not the unselected art.
4. Click tab 5. Confirm it renders and that tab 3 has returned to the unselected art.

**Pass / Fail.** PASS if selection art and enabled state track the click every time.
FAIL on any tab that is visually selected but still clickable, or clickable but drawn selected — that
is a reused button whose state was not fully re-dressed.

### C-1c — wrap stability survives the pool (`options-ui-§13`)

**Setup.** A page with enough tabs to wrap to **three** rows. Drag the settings window narrower if
needed to force the wrap.

**Steps.**
1. Note the vertical position of the content panel's top edge (the line the selected tab's foot merges
   into). Use `/fstack` over it and read the anchor, or take a screenshot.
2. Click a tab in the **first** row. Re-read the edge position.
3. Click a tab in the **last** row. Re-read the edge position.
4. Click a tab in each remaining row in turn.

**Expected.** The content panel's top edge and the row offsets are **identical at every selection**.
No gap opens between wrapped rows; the content panel does not move or resize.

**Pass / Fail.** PASS only if the geometry is unchanged across all selections. Any movement is the
selection-dependent-pitch bug returning through a pooled button whose atlas height was measured after
its state was set rather than before.

### C-1d — two pages do not share a button

**Steps.**
1. Open the host's General page, click tab 2.
2. Switch to a different sub-page in the Blizzard left tree, click one of its tabs.
3. Switch back to General.

**Expected.** General still shows tab 2 selected with its own rows; the second page's tab labels
appear nowhere on General's strip.

**Pass / Fail.** PASS if no tab label from one page ever appears on another's strip.

---

## C-2 — `Widgets.lua` reorder list on `LibKa0s-Pool-1.0`

**Change covered:** C-2 — handle and box pools migrated to the shared module (F-005).

**Setup.** A host with a drag-reorderable list (MultiMeters' Columns page is the documented one, with
a group boundary). Out of combat.

**Steps.**
1. Open the page with the reorder list.
2. Drag row 1 to position 4. Release.
3. Drag row 4 back to position 1. Release.
4. Switch to a different tab and back (forcing a re-render and a `Cancel`).
5. Repeat steps 2-4 five times.
6. Drag a row and, mid-drag, press `Esc` to close the panel without releasing the button.
7. Re-open the panel.

**Expected.**
- Every drag shows exactly **one** ghost under the cursor and **one** insertion line.
- The dragged row fades to 35% in the list while carried, and returns to full opacity on drop.
- After step 4, every row has exactly **one** handle and **one** row box — no doubled art, no handle
  left floating on an unrelated widget.
- After step 6/7, no orphan ghost, handle or box is visible anywhere on screen.
- If the list has a boundary (shown vs. hidden columns), a row still cannot be dropped across it.

**Pass / Fail.** PASS if no duplicated or orphaned chrome appears at any point and every drag lands
where it was dropped. FAIL on any handle or box visible on a frame the list did not draw — that is the
`before`-hook reparent missing from the migration.

---

## C-6 / C-7 — Diagnostics reach chat

**Change covered:** C-6 (one printer per instance, F-006) and C-7 (a handler-less button is reported,
F-008).

**Setup.** This needs a **deliberately mis-wired host**, so use a scratch copy of a host addon or a
`/run` harness. Out of combat.

**Steps.**
1. In a scratch copy of a host, remove `print = ...` from its `LibKa0s-Options-1.0` descriptor.
2. `/reload`, open the settings panel, navigate to a page whose rows carry a `group`.
3. Now edit the scratch host's schema so one page's rows carry **no** `group` at all. `/reload`, open
   that page.
4. Restore the schema. Now edit the host's `MasterControls` call to omit `onResetAll`. `/reload`, open
   the General page.

**Expected.**
- Step 3 prints `settings page '<key>' has no grouped rows; rendering untabbed` **to the default chat
  frame**, and the page still renders its rows untabbed rather than blank. Before C-6 this line went
  nowhere.
- Step 4 prints the new `DEAD_BUTTON` line naming `Reset all settings`, at page-build time, and the
  button still draws.

**Pass / Fail.** PASS if both lines appear in chat with the descriptor's `print` absent, and neither
condition raises a Lua error popup. FAIL if either is silent, or if either raises.

---

## C-10 — Perf bracket cost, in-client

**Change covered:** C-10 — `P.Open`'s active-arm allocation (F-007).

Run only in a host that has adopted **Shape B** `Open`/`Close` brackets. This is the standard's own
two-arm capture protocol, not an ad-hoc measurement.

**Setup.** A host with `## SavedVariables: <Host>PerfDB` declared and a perf descriptor wired. Fresh
`/reload`. **No other addons enabled** beyond the host and its libs — a capture is only comparable
against itself under the same addon set.

**Steps.**
1. `/<host> perf start`.
2. `/<host> perf a` — arm window A. Enter combat on a target dummy and fight continuously through the
   whole window. This is the **clean** arm and it goes first.
3. When window A closes, **without `/reload`**, `/<host> perf b` — arm window B, which suspends the
   host. Enter combat again and fight for a comparable duration.
4. `/<host> perf stop`, then `/<host> perf report`.
5. `/<host> perf dump` and capture the JSON verbatim.

**Expected / how to read it.** Compare the **bucket figures** — `calls`, `totalMs`, `maxMs` per
bucket — between this capture and the pre-change one at the same host version. Do **not** build any
conclusion on `fps.deltaMsPerFrame`: the standard states it is unresolved below the harness's measured
run-to-run spread, and F-007 is precisely a small bias in that number.

**Pass / Fail.** PASS if every declared bucket appears in the report with a non-zero `calls` (a
declared bucket no bracket reaches is a lie in every report) and no bucket's `observedMixed` flag is
set unexpectedly. The allocation improvement itself is **not** judged from this capture — it is judged
from the headless active-arm case C-10 adds. This capture exists to confirm nothing regressed.

**Record it.** Freeze the result as `docs/perf-analysis/<YYYYMMDD-HHMMSS>/` **in the host addon** (via
`/wow-addon:perf-analysis`) — `report.md`, the verbatim `dump.json`, and that capture's `ANALYSIS.md`.
LibKa0s itself keeps no `perf-analysis/` store; the capture belongs to the host that produced it.

---

## Regression suite

Not tied to any one change. Run all of these in a host with the new payload.

| # | Check | Expected |
|---|---|---|
| R-1 | `/reload` from a fully loaded state | No Lua error popup; settings panel re-opens cleanly |
| R-2 | Fresh SavedVariables (delete `<Host>.lua` from `WTF`), then login | Defaults populate; General page opens on the **Master controls** tab |
| R-3 | Login sequence `ADDON_LOADED` → `PLAYER_LOGIN` → `PLAYER_ENTERING_WORLD` | No errors; `/etrace` shows no repeated registration |
| R-4 | Open settings **while in combat**, via `/<host> config` | Refused: the panel does not open, and `cannot open settings during combat…` prints to chat |
| R-5 | Open settings while in combat via **Esc → Options → AddOns → \<Host\>** | Same refusal — the panel **closes itself** and prints the same line. This is the path that bypasses `OpenOptionsPanel`'s guard and is covered by `SetRenderer`'s `OnShow` guard (`Options.lua:699-711`) |
| R-6 | Leave combat, re-open settings | Opens normally; the panel does **not** open itself the instant combat drops |
| R-7 | Toggle every control on every page at least once | Each write lands, paired controls (a class-color companion and its swatch) update on the **same** frame, no errors |
| R-8 | Class-color companion: turn it on, then change the swatch's **alpha** | The bar's opacity changes; its hue does not. The swatch is never disabled (`options-ui-§17`) |
| R-9 | AceDB profile switch, then re-open settings | Every page repaints from the new profile; no doubled Blizzard category in the left tree |
| R-10 | `Reset all settings` from the Master controls tab | One confirmation, one blast radius; every page repaints; no per-row chat spam |
| R-11 | Debug console toggle on the Master controls tab | Console opens; its copy window opens; both close; the setting does **not** persist across `/reload` (it is `sessionOnly`) |
| R-12 | Every icon, the monospace face and every bar texture render | No blank/green squares — a texture path that fails draws nothing and raises nothing, so this must be checked by eye |

---

## Taint tests

The review raised **no taint findings**. The library's two protected-surface interactions are already
guarded and are covered by R-4/R-5/R-6 above:

- `Settings.OpenToCategory` behind `InCombatLockdown()` (`Options.lua:899-903`);
- `SettingsPanel` internals reached only inside `pcall` (`Options.lua:908-922`).

One extra check, because the tab strip is new and a click handler is involved:

**T-1.** Enter combat on a target dummy with the settings panel **already open** on a tabbed page.
Click between tabs while in combat. Then click an action bar slot.

**Expected.** Tabs switch normally (a redraw inside an already-open panel was never a protected
action, and `OptionsWidgets.lua:1817-1822` documents that no guard is added). The action bar slot
fires. **No** `Interface action failed because of an AddOn` red text.

**Pass / Fail.** PASS if the action bar is unaffected. FAIL on any red taint text — which would mean
the pooled button reuse introduced a secure-frame interaction, and C-1 must be re-examined.

---

## Localization

The review raised no locale findings, and a library ships no `locales/`. One check anyway, because
C-7 adds a user-visible string and the Options major's strings are library-owned literals:

**L-1.** Switch the client to **deDE**. Re-run C-6/C-7 and R-4/R-5.

**Expected.** The library's own diagnostics still print (they are deliberately untranslated English
literals — `Options.lua:190-219`), the host's own strings are translated, and no string concatenation
produces mangled word order. `lib.STRINGS.LSM_NONE` (`"None"`) is a **stored value** and must remain
untranslated — confirm a media dropdown with no LSM still stores the literal `None`.

---

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| C-1 | | | frame delta N1−N0 = |
| C-1b | | | |
| C-1c | | | |
| C-1d | | | |
| C-2 | | | |
| C-6 | | | |
| C-7 | | | |
| C-10 | | | capture stamp = |
| R-1 … R-12 | | | |
| T-1 | | | |
| L-1 | | | |

Changes **C-3, C-4, C-5, C-8, C-9** have no in-client surface — they are verified entirely by the
Step 0 suites and by reading the regenerated artefacts. Do not invent client steps for them.
