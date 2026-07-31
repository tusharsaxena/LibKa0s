# 03 — Smoke Tests

Manual, in-client verification to run **after** the changes in `02_PROPOSED_CHANGES.md` are applied.
LibKa0s is a library, not an addon: there is no TOC of its own and nothing to `/reload` on its own.
Every test therefore runs inside a **host addon** with LibKa0s re-vendored.

---

## Pre-flight

1. **Headless first — this is the cheap gate, run it before the client.**
   ```
   cd <LibKa0s>
   lua tests/run.lua          # must read "N passed, 0 failed"
   luacheck .                 # must read "0 warnings / 0 errors"
   diff -r testkit tests/_kit # must be empty (and after C-10 the suite asserts this too)
   ```
2. **Re-vendor into the host**, whole folder, never one module:
   ```
   cp -r <LibKa0s>/LibKa0s/. <Host>/libs/LibKa0s/
   cp -r <LibKa0s>/testkit/. <Host>/tests/_kit/
   diff -r <LibKa0s>/LibKa0s <Host>/libs/LibKa0s   # must be empty
   ```
3. **Host TOC:** confirm `libs/LibKa0s/LibKa0s.xml` is listed in the `# Libraries` section, before
   any host file that calls `LibStub("LibKa0s-*")`. Single latest-Retail `## Interface:`.
4. **Client setup**, before logging in:
   - `/console scriptErrors 1` — every Lua error must raise a visible popup.
   - Retail only. Any character; a **healer or tank with a per-unit settings page** if the host has
     one (needed for C-8).
   - Have a target dummy reachable (Stormwind / Valdrakken) for every combat test.
5. **Baseline capture:** `/run print(collectgarbage("count"))` — record the number for C-9.
6. **Version sanity, in-game:**
   ```
   /run local m=LibStub("LibKa0s-Options-1.0",true); for k,v in pairs(m.MODULES) do print(k,v) end
   ```
   Must list `Options`, `OptionsWidgets`, `OptionsScroll` and every minor must match the
   `## Unreleased` block in `CHANGELOG.md`.

---

## C-1 — Options refuses a partial vendor at `:New`, and the Defaults button no longer needs the tooltip maker

**Setup:** a scratch copy of the host. Fresh SavedVariables not required.

**Steps**
1. Log in normally, open the host's settings panel, and confirm the **Defaults** button is present in
   the top-right of a sub-page and shows its tooltip on hover. This is the control case.
2. Exit the client. Delete `<Host>/libs/LibKa0s/OptionsWidgets.lua`.
3. Log in.
4. Note the error text in the popup, then exit and restore the file.
5. Log in again and re-confirm step 1.

**Expected**
- Step 1 and step 5: panel builds, Defaults button present, tooltip shows on hover, no error popup.
- Step 3: a **single** error at addon-enable time whose text contains
  `LibKa0s-Options-1.0:New — OptionsWidgets.lua did not load`. It must fire at `:New`, **not** at
  panel open, and must **not** be `attempt to call a nil value (field 'AttachTooltip')`.

**Pass / Fail:** PASS when the failure names the missing file at `:New`; FAIL on any nil-call error,
or if step 3 produces no error at all.

---

## C-2 — Options descriptor validation

**Setup:** a scratch copy of the host with a temporary edit to its options bootstrap.

**Steps**
1. In the host, comment out the `mainPanelName` field in the table passed to
   `LibStub("LibKa0s-Options-1.0"):New{ ... }`. Log in.
2. Restore it; comment out `allRows` instead. Log in.
3. Restore everything. Log in.
4. With everything restored, open the panel and run `/framestack` (mouse over the settings canvas).

**Expected**
- Steps 1 and 2: one error naming the exact field,
  `LibKa0s-Options-1.0:New requires descriptor.mainPanelName (a string)` /
  `…descriptor.allRows (a function)`. Not an `attempt to index a nil value`.
- Step 3: clean login, no error.
- Step 4: `/framestack` names the main canvas frame with the host's `mainPanelName`, **not** as an
  unnamed frame.

**Pass / Fail:** PASS when both omissions error by name and `/framestack` attributes the canvas.

---

## C-3 — The combat refusal is audible even with no descriptor printer

**Setup:** temporarily comment out the `print` field in the host's Options descriptor.

**Steps**
1. Log in. Pull a target dummy and stay in combat.
2. Run the host's config verb (e.g. `/<slash> config`).
3. Also run `/run LibStub("LibKa0s-Options-1.0",true) and _G.<Host>OptionsInstance.OpenOptionsPanel()`
   — or whatever the host exposes — to confirm the gate is inside the open, not the dispatcher.
4. Leave combat, run the config verb again.
5. Restore the `print` field, `/reload`, and repeat step 2.

**Expected**
- Steps 2 and 3, in combat: a gray chat line reading
  `cannot open settings during combat — Blizzard's category-switch is protected`. The panel does
  **not** open. Nothing appears when combat ends (no defer-and-replay).
- Step 4: the panel opens normally.
- Step 5: the same sentence, now carrying the host's cyan prefix tag.

**Pass / Fail:** PASS when the refusal is visible in **both** configurations and the panel never
opens itself after combat drops.

---

## C-4 — `CreateOptionsPanel` is idempotent

**Setup:** normal login, panel not yet opened.

**Steps**
1. `/run <Host>.Options.CreateOptionsPanel()` (or the host's equivalent) twice.
2. Open Esc → Options and scroll the left-hand addon list.
3. Open a sub-page, toggle any checkbox, and watch the chat/debug output.

**Expected**
- Exactly **one** entry for the addon in the options list, with one set of sub-pages.
- Toggling a checkbox produces the host's usual single settings-change line, not two.
- No error popup.

**Pass / Fail:** PASS when the options list shows one entry and one write produces one line.

---

## C-5 — DebugLog draws the live Core's close button

**Setup:** this needs a deliberate version-skew rig, which is the only way to observe the bug.

**Steps**
1. In the host's `libs/LibKa0s/`, bump `Core.lua`'s `MINOR` from 1 to 2 and change
   `MakeCloseButton`'s glyph from `"\195\151"` (×) to `"X"`. Leave `DebugLog.lua` untouched.
2. Log in and open the host's debug console.
3. Restore both files from the ship folder and confirm `diff -r` is empty; `/reload`.

**Expected**
- Step 2: the console's close control renders **`X`** — proving DebugLog resolved through the live
  Core. Before C-5 it renders `×`.
- Step 3: back to `×`, no error.

**Pass / Fail:** PASS when the rigged glyph reaches the console. FAIL if it still shows `×` — the
snapshot is still in place.

---

## C-6 — Shell floors

**Setup:** scratch copy.

**Steps**
1. Edit `libs/LibKa0s/OptionsWidgets.lua` and set `NEEDS_SHELL = 99`. Log in.
2. Restore. Set `PerfPanel.lua`'s shell floor to 99. Log in and run the host's perf verb.
3. Restore both; `/reload`.

**Expected**
- Step 1: the module is **absent** — after C-1 that surfaces as the C-1 refusal message naming the
  missing widgets, not as a nil-call.
- Step 2: the perf panel is absent; the host's perf verb still runs its text output, or reports the
  panel as unavailable. No error popup.
- Step 3: everything back to normal.

**Pass / Fail:** PASS when a raised floor produces absence-with-a-message, never a nil-call.

---

## C-7 — The secret-safe seam is total

**Setup:** requires an actual combat-protected value. `UnitGetTotalAbsorbs("player")` is secret in
combat on retail.

**Steps**
1. Enable the host's debug logging and open the console.
2. Pull the target dummy. **While in combat**, run:
   ```
   /run <Host>.Debug("Test", "absorb=%s", UnitGetTotalAbsorbs("player"))
   ```
3. Still in combat, exercise the **ungated** path directly:
   ```
   /run <Host>.DebugConsole:Add("Test", UnitGetTotalAbsorbs("player"))
   ```
4. Still in combat, press **Copy** on the console.
5. Still in combat, run the host's schema list verb (`/<slash> list`) and its `get` on a numeric
   setting.
6. Leave combat, `/reload`, repeat step 5.

**Expected**
- Steps 2 and 3: a console line rendering `<secret>`. **No** error popup, and no
  `invalid value (secret) ... for 'concat'`.
- Step 4: the copy window opens with the full buffer, `<secret>` included. No error.
- Steps 5 and 6: identical, correctly-formatted settings output in and out of combat.

**Pass / Fail:** PASS when every step renders `<secret>` or a normal value and **zero** Lua errors
appear. Step 3 is the one that fails before C-7.

---

## C-8 — Per-page Defaults respects the page filter; a re-rendered page keeps its buttons

**Setup:** a host with a per-unit (or otherwise filtered) settings page, and at least two units
configured differently. Note the current values of one setting on **both** units.

**Steps**
1. Open the per-unit page for unit A. Change one setting on unit A away from its default, and change
   the **same** setting on unit B away from its default. Note both.
2. Return to unit A's page. Click **Defaults**.
3. Switch the page to unit B and inspect that setting.
4. Switch back and forth between unit A and unit B **three times**, without leaving the panel.
5. On each switch, confirm any inline action buttons (`InlineButtonPair` / `afterGroup`) and any
   paired non-schema widget (`pairWith`) are still drawn.

**Expected**
- Step 2: unit A's rows reset.
- Step 3: **unit B's value is untouched.** This is the bug — before C-8 it is also reset.
- Steps 4–5: every re-render draws the full page, including every inline button and paired widget, on
  every pass. Before C-8 the second pass silently drops them if the host hoisted its table.
- No error popup at any point.

**Pass / Fail:** PASS when unit B survives unit A's Defaults **and** the third re-render looks
identical to the first.

---

## C-9 — Small cleanups

**Steps**
1. `/run <Host>.Print("100%% done")` and `/run <Host>.Print("100%% done", 1)`.
2. Enable debug logging, generate **600+** console lines (`/run for i=1,700 do <Host>.Debug("T","line %d",i) end`).
3. Check the console's line counter and press **Copy**.
4. `/run print(collectgarbage("count"))` and compare with the pre-flight baseline.

**Expected**
- Step 1: both print `100% done` — the zero-argument and many-argument forms agree.
- Step 2–3: the counter reads `500 / 500`; the copy window holds exactly 500 lines, the **newest**
  500, in order, ending at `line 700`.
- Step 4: memory at or below baseline for the same workload. Not a hard gate; record the number.

**Pass / Fail:** PASS when the format forms agree and the buffer holds the newest 500 lines in order.

---

## C-10 — Kit sync gate

**Steps** (headless, no client)
1. `echo "-- drift" >> tests/_kit/framework.lua`
2. `lua tests/run.lua`
3. `git checkout tests/_kit/framework.lua && lua tests/run.lua`

**Expected**
- Step 2: the suite **fails**, with a message naming `framework.lua`.
- Step 3: back to green.

**Pass / Fail:** PASS when the suite goes red on drift and green on restore.

---

## Regression suite

Not tied to any one change; these cover what the change-set could plausibly break.

| # | Check | Expected |
|---|---|---|
| R-1 | Cold login on a **fresh** SavedVariables (delete the host's SV file) | `ADDON_LOADED` → `PLAYER_LOGIN` → `PLAYER_ENTERING_WORLD` with zero errors; defaults populate |
| R-2 | `/reload` three times in a row | No errors; panel state, console visibility and logging flag behave as documented (logging is session-only and returns to off) |
| R-3 | Open Esc → Options; visit **every** sub-page | Each builds on first show; the header title, gold divider and breadcrumb render; the Defaults button appears top-right on every sub-page |
| R-4 | Toggle **every** option on every page at least once | Each write echoes once; paired controls (a toggle and the swatch it greys) update together |
| R-5 | Short page vs. long page | The scrollbar is **shown on both**, greyed and inert on the short one; the body's right edge sits at the same x on both |
| R-6 | A 50/50 action-button pair at the foot of a group | Neither button's right border is shaved by the scroll clip |
| R-7 | Enter and leave combat with the panel open and the debug console open | Both stay visible; no taint text; no error |
| R-8 | Esc with the debug console focused, then with the copy window focused | Each closes its own window, not the other's |
| R-9 | Two Ka0s hosts loaded at once, both with consoles | Two separate console windows, two separate Esc registrations; closing one leaves the other open |
| R-10 | `/framestack` over each host's console, copy window and perf panel | Every frame name is prefixed with that host's descriptor `name` — no shared or anonymous frame |
| R-11 | Profile switch, if the host uses AceDB | Every open panel's widgets re-read the new profile in place; no page rebuild stall |
| R-12 | Host's `resetall` verb and the panel's global Defaults | Identical outcome; any `skipRestoreAll` page (profiles) is untouched by both |
| R-13 | `/<slash>` with no argument, an unknown verb, and every documented verb | Help header + rows; unknown verb prints the message then the help |
| R-14 | `/<slash> set <numeric path> 99999` | Clamps, and the **echo reports the clamped value**, not the typed one |
| R-15 | `/<slash> set <color path> 255 128 0` | Stores a jointly-rescaled colour; `get` echoes `{1.00, 0.50, 0.00, 1.00}` |
| R-16 | Perf panel: run a full capture cycle | Steps progress through their states; the panel wears Core's skin and Core's × close button |

---

## Taint-specific tests

C-3 and C-4 touch the Settings-category path, so:

| # | Check | Expected |
|---|---|---|
| T-1 | In combat on a dummy, run the config verb, then click an action bar slot | Refusal line printed; **no** `Interface action failed because of an AddOn` red text |
| T-2 | Out of combat, open the panel from `/<slash> config` | Opens to the host's category, parent expanded in the left tree |
| T-3 | Out of combat, open the same panel from Esc → Options → the addon's entry | Opens identically; the two routes must not differ |
| T-4 | After T-1's in-combat refusal, leave combat and repeat T-2 and T-3 | Both still work — a refused open must not have tainted the panel |
| T-5 | Fresh session: open Esc → Options **before** ever touching the addon | The addon's entry is already present (eager category, lazy body) |

---

## Performance spot-checks

Only C-9 is perf-tagged, and only weakly.

1. `/console scriptProfile 1` → `/reload` → drive 1000 debug lines → `/run UpdateAddOnCPUUsage()` →
   `/run print(GetAddOnCPUUsage("<Host>"))`. Record before and after C-9.
2. `/run collectgarbage("collect"); print(collectgarbage("count"))` before and after the same 1000-line
   burst. The C-9 (F-013) scratch-table change should reduce the delta; a flat result is acceptable
   and not a fail.
3. `/console scriptProfile 0` afterwards — profiling itself is a tax.

---

## Localization sanity

No locale finding was raised and no user-facing English string is added or renamed by this
change-set, so a full non-enUS pass is **not required**. One cheap check, because C-3 adds an output
path: switch the client to deDE, run the C-3 in-combat refusal, and confirm the sentence renders
(untranslated is fine and expected — these strings are host-overridable via the descriptor's `L`)
without mojibake on the em dash.

---

## Sign-off

| ID | Tested? | Pass / Fail | Notes |
|---|---|---|---|
| C-1 | | | |
| C-2 | | | |
| C-3 | | | |
| C-4 | | | |
| C-5 | | | |
| C-6 | | | |
| C-7 | | | |
| C-8 | | | |
| C-9 | | | |
| C-10 | | | |
| R-1 … R-16 | | | |
| T-1 … T-5 | | | |
