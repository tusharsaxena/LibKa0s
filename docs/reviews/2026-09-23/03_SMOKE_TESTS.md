# 03 — In-client smoke tests (LibKa0s, 2026-09-23)

LibKa0s has no TOC. Every in-client check runs **through a consumer** after it has been re-vendored with the fixed payload. The host named in each section is the cheapest one to test on. Any consumer that exercises the same path works too.

## Pre-flight

1. **Headless first, in this repo:**
   - `~/.claude/wow-addon/bin/ka0s-bounded lua5.1 tests/run.lua` must show 0 failed.
   - `~/.claude/wow-addon/bin/ka0s-bounded luacheck .` must show 0/0.
   - `diff -rq testkit tests/_kit` must be empty.
2. Re-vendor `LibKa0s/` into the test host's `libs/LibKa0s/` and `testkit/` into its `tests/_kit/`, as whole folders. Check both with `diff -rq`, and run that host's own `tests/run.lua`.
3. Client: Retail on `## Interface: 120100`. Type `/console scriptErrors 1`, then `/reload`. Keep BugSack or BugGrabber on if you have it.
4. Where a check needs a specific locale, it says so.

## S-001: C-01, item links read the quality from `|cnIQ` (F-001)

- **Setup:** LootHistory re-vendored, logged in, and an item the client **hasn't cached this session** within reach. Any fresh world drop or a vendor item never viewed works; a `/reload` beforehand clears the in-memory item cache for most items.
- **Steps:**
  1. `/run local l=select(2,C_Item.GetItemInfo(6948)) or "" print((l:gsub("|","||")))`. Note the prefix: it should start `||cnIQ1`.
  2. `/run print(LibStub("LibKa0s-Item-1.0").QualityFromLink(select(2,C_Item.GetItemInfo(6948))))`
  3. Loot an item you haven't cached yet, then open the LootHistory window.
- **Expected:**
  - Step 1 shows `|cnIQ…` (this confirms the finding on the live client).
  - Step 2 prints `1`.
  - In step 3, the new row shows the item's real quality color and label, not blank or "Poor".
- **Pass/Fail:** Pass if step 2 prints a number equal to the item's quality and the row in step 3 is labeled correctly. **Fail** if it prints `nil`.

## S-002: C-02, the banner and header reuse their widgets (F-002)

- **Setup:** MultiMeters (banner, Windows page) and AbsorbTracker (header, Appearance page) re-vendored, out of combat.
- **Steps:**
  1. `/run UpdateAddOnMemoryUsage() print(GetAddOnMemoryUsage("MultiMeters"))`
  2. Open `/mm config`, go to Windows, and switch the window picker 30 times.
  3. Repeat step 1.
  4. On AbsorbTracker's Appearance page, switch the Unit picker 30 times, and check `/fstack` over the chrome band.
  5. `/framestack` over the banner once and confirm that exactly one Dropdown frame sits under the chrome band.
- **Expected:**
  - Memory in step 3 is within a few KB of step 1. Before the fix it climbs with every switch.
  - The divider hairline is drawn once, and no texture error appears from `SetParent`.
  - The picker still works: selecting a window re-targets the page, and the dropdown's selection sticks.
- **Pass/Fail:** Pass if there's no monotonic memory climb across the 30 switches, the picker is functional and there are no Lua errors. **Fail** on growth that scales with the number of switches, or on an error about `SetParent` or `Release`.

## S-003: C-03, the slash `set` reports a rejected value (F-003)

- **Setup:** AuraMaster re-vendored, with its Slash `set` wrapper migrated to `return NS.SetByPath(path, v)` (M6). AuraMaster has string rows whose `validate` rejects blank-looking input (`settings/Containers.lua:56`). BankLedger works too if it gains a validated row.
- **Steps:**
  1. `/am list` and pick a row with a validator.
  2. `/am set <path> <value the parser accepts but validate rejects>`.
- **Expected:** `Invalid value for <path>` and, indented, the host's reason. There's **no** `<path> = <old>` echo.
- **Pass/Fail:** Pass if the refusal is printed and the stored value is unchanged (`/am get <path>`).

## S-004: C-04, JetBrains Mono registers on a non-Western client (F-004)

- **Setup:** Switch the client locale to **ruRU** (Battle.net → Game Settings → Text Language), then re-log.
- **Steps:**
  1. `/run print(LibStub("LibSharedMedia-3.0"):IsValid("font","JetBrains Mono"))`
  2. Open any consumer's font dropdown, for example MultiMeters → Appearance → font.
- **Expected:** `true`, and "JetBrains Mono" is listed in the dropdown and draws Cyrillic.
- **Pass/Fail:** Pass if both hold. Also run it on enUS to confirm nothing changed there.

## S-005: C-05, the Bus survives an AceEvent re-embed (F-005)

- **Setup:** A consumer on the Bus (for example AbsorbTracker).
- **Steps:**
  1. `/run local E=LibStub("AceEvent-3.0") for t in pairs(E.embeds) do E:Embed(t) end`. This simulates a newer AceEvent loading later.
  2. `/at disable`
  3. `/etrace` for UNIT_AURA for 10 s in a group.
  4. `/at enable`
- **Expected:** After step 2 no handler of the host fires. After step 4 the display comes back and updates normally.
- **Pass/Fail:** Pass if it's fully inert while disabled and fully restored after. **Fail** if any registration survives the disable or is missing after enable.

## S-006: C-06, launcher refusal lives in the library (F-006, F-009)

- **Setup:** BankLedger (rung a) and PrettyChat (rung c), re-vendored, with each host's descriptor migrated (M6).
- **Steps:**
  1. `/bl disable`, then left-click BankLedger's minimap button.
  2. Right-click it.
  3. `/pc disable`, then left-click PrettyChat's button.
  4. On a test install with LibDBIcon removed, `/reload` twice.
- **Expected:**
  - Step 1 prints exactly one line, `Ka0s Bank Ledger is disabled — enable it with /bl enable`, and nothing else happens or gets written.
  - Step 2 opens the settings panel.
  - Step 3 opens PrettyChat's settings panel (the rung (c) carve-out).
  - Step 4 shows the NO_ICON notice once per session with no `[LibKa0s]` tag.
- **Pass/Fail:** Pass if all four hold.

## S-007: C-07, Core printer with a secret in a numeric slot (F-008)

- **Setup:** Any consumer on `printer.Format`, **in combat** against a target dummy.
- **Steps:** `/run local P=LibStub("LibKa0s-Core-1.0"):New{prefix="[t]"} P.Format("absorb=%d", UnitGetTotalAbsorbs("player"))` while you're shielded.
- **Expected:** One line: `[t] absorb=%d <secret>` (or the number, out of combat). No Lua error.
- **Pass/Fail:** Pass if nothing raises.

## S-008: C-10/C-11/C-12, drag, console and perf hygiene (F-010, F-011, F-012, F-016)

- **Drag (MultiMeters Columns, ConsumableMaster priority list):** drag a row in each. The ghost follows the cursor, the gold line shows, the drop reorders, and a second list has its own line color. Pass if there are no Lua errors and nothing stays hidden.
- **Console:** `/mm debug on`, generate more than 1600 lines (for example `/mm perf report` repeatedly), then press Copy. The copy window shows the newest 1500 lines in order, with the oldest line dropped. Pass on correct order and count.
- **Perf:** run the full two-arm protocol on one consumer: `/mm perf start`, `measure a`, pull, `measure b`, pull, `finish`, `report`. Pass if the report and the JSON line print, the addon is restored after `finish`, and the bucket figures look plausible. Record it as a frozen `docs/perf-analysis/<stamp>/` bundle in that consumer (via `/wow-addon:perf-analysis`) as evidence that the bracket cost didn't move.

## Regression suite (run on at least two consumers)

- `/reload` is clean. So are login and the ADDON_LOADED → PLAYER_LOGIN → PLAYER_ENTERING_WORLD sequence, with no errors.
- Open Settings → AddOns. Each addon appears exactly once, and each multi-page addon's pages appear once each.
- Type each of the eleven roots (`/at /am /bl /cm /kcd /lh /mm /pm /pc /pfe /wg`). Each one reaches its own addon.
- Enter combat with a settings page open. The page is covered, and after combat it's drawn from current state (the options-ui-§2 lock).
- Profile switch → the panel refreshes. Reset all → the one "reset" line appears.
- Toggle every option on one page at least once.
- `/<slash> disable` then `/<slash> enable` on three consumers. It's inert while disabled and fully restored after.

## Taint

- With a banner page open, enter combat and click an action bar button. There should be no `Interface action failed because of an AddOn`.
- Open settings through `/<slash> config` **and** through Esc → Options → AddOns. Both open, and in combat both are refused or covered without errors.

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| S-001 / C-01 | | | |
| S-002 / C-02 | | | |
| S-003 / C-03 | | | |
| S-004 / C-04 | | | |
| S-005 / C-05 | | | |
| S-006 / C-06 | | | |
| S-007 / C-07 | | | |
| S-008 / C-10, C-11, C-12 | | | |
| Regression | | | |
| Taint | | | |
