# 03 — Smoke tests (LibKa0s, 2026-10-07)

LibKa0s has no TOC and no in-game surface of its own, so every in-client check runs **through a consumer** after the v1.71.0 re-vendor. The two consumers that exercise these changes are LootHistory (chart and autocomplete) and BankLedger (autocomplete). Any consumer exercises the slash CLI. The owner runs these and records the results. They are never marked passed by an agent.

**Pre-flight (headless, one line):** `lua tests/run.lua` (0 failed) and `luacheck .` (0/0) in LibKa0s, then the same in each re-vendored consumer.

**Pre-flight (client):** retail `## Interface: 120100`. All 11 Ka0s addons enabled on the re-vendored branches. `/console scriptErrors 1`. `/reload` once before starting.

## Per-change tests

### C-01 — Chart segments clipped to the plot (F-001)
- **Setup:** LootHistory with at least a week of loot in the ledger. Open the browser on the **Timeline** tab.
- **Steps:**
  1. View a span that includes today, so the provisional (dashed) range is drawn.
  2. Resize the browser from smallest to largest, then back.
  3. `/run collectgarbage() print(collectgarbage("count"))` before and after step 2.
- **Expected:** lines and dashes stay inside the plot area. No hitch. Memory after step 2 is within a few hundred KB of before. No Lua error.
- **Pass/Fail:** pass if nothing is drawn outside the plot and no error appears.

### C-02 — Hover follows new data (F-003)
- **Setup:** LootHistory Timeline tab open, cursor resting on the chart with the tooltip up.
- **Steps:**
  1. Keep the cursor still.
  2. Toggle a series off and on from the legend, which triggers a repaint.
  3. Loot an item, or trigger a ledger change, while hovering.
- **Expected:** the tooltip shows the **new** data's values within one frame of each repaint. The crosshair sits at the hovered x after a resize.
- **Pass/Fail:** pass if no stale tooltip value survives a repaint.

### C-03 — Autocomplete hardening (F-002, F-005, F-008, F-009)
- **Setup:** LootHistory browser open, and separately BankLedger's browser open.
- **Steps:**
  1. Type two letters of a known item name in each search box. Wait about 0.2 s.
  2. Press Down twice, then Enter.
  3. Type again, then click outside the browser.
  4. Type again, then press Esc.
  5. Switch LootHistory tabs (History → Insights → Timeline → Holdings) and type in the search box on each.
- **Expected:**
  1. A list appears under the box, the box's width, in the box's skin.
  2. The second row is picked and the list closes.
  3. The list closes on the next frame.
  4. The list closes and the text stays.
  5. The list works on every tab.
  - No Lua error at any step.
- **Pass/Fail:** pass if every step behaves as expected.

### C-04 — CLI rejects non-finite numbers (F-006)
- **Setup:** any consumer with a number setting, for example AbsorbTracker.
- **Steps:**
  1. `/at set <a number path> nan`
  2. `/at set <same path> inf`
  3. `/at get <same path>`
- **Expected:** steps 1 and 2 print the "not a number" refusal (the `ERR_NUMBER` text) and write nothing. Step 3 shows the unchanged value.
- **Pass/Fail:** pass if the stored value is unchanged.

### C-05 — Chart x-axis locale (F-010), observation only
- **Setup:** a deDE or frFR client (or `SET textLocale` on a test client), LootHistory Timeline over a 30-day span.
- **Steps:** read the x-axis labels.
- **Expected:** record whether the month abbreviations render in English. This **verifies or refutes F-010's premise**, and it decides whether the LootHistory follow-up is needed.
- **Pass/Fail:** this check records an observation and has no pass or fail.

### C-06 — Mutation notes (F-011)
Headless only. No in-client step.

## Regression suite
- `/reload` cleanly with all 11 addons. No Lua error from ADDON_LOADED through PLAYER_ENTERING_WORLD.
- **Cross-addon dispatch (required even though the greps were clean):** type each of the 11 roots (`/at /am /bl /cm /kcd /lh /mm /pm /pfe /pc /wg`) and confirm that each reaches its own addon. Open Settings → AddOns and confirm that each addon appears exactly once and that each multi-page addon's pages appear once each.
- Enter and leave combat with the LootHistory and BankLedger browsers open. No error, and the search boxes still work after combat.
- Open each addon's settings panel and toggle one option.

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| C-01 | | | |
| C-02 | | | |
| C-03 | | | |
| C-04 | | | |
| C-05 | | | (observation) |
| C-06 | n/a (headless) | | |
| Regression | | | |
