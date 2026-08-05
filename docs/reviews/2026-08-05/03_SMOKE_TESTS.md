# Smoke tests — LibKa0s, 2026-08-05

Executed **after** the changes in [`02_PROPOSED_CHANGES.md`](02_PROPOSED_CHANGES.md) are applied.

**Read this first.** LibKa0s ships nothing a player installs — it is vendored into a host addon and
has no slash command, no SavedVariables and no frames of its own until a host builds them. There is
therefore **no in-client test of this repo**. Every in-client step below is run **inside a consuming
addon** that has re-vendored the changed `LibKa0s/` folder. Pick one consumer that adopts **Perf** and
**Options** (both are exercised); do the whole checklist in that one addon.

Headless suites are not repeated here — they were run in `01_FINDINGS.md`'s measurement block. One
pre-flight line covers re-running them.

## Pre-flight

1. **Repo, before anything is copied.** From the LibKa0s repo root:
   `luacheck . && lua tests/run.lua` — must be `0 warnings / 0 errors` and `0 failed`.
   If C-4's scenario was added: `lua tests/perf.lua` separately, and confirm it is **not** counted in
   `docs/test-cases.md`.
2. **Inventory moved with the change.** `lua tests/run.lua --list | diff - docs/test-cases.md` must
   be empty, and the total must be **485** (or whatever subset of C-1/C-2/C-5/C-6 landed — see the
   table in `02_PROPOSED_CHANGES.md`).
3. **Re-vendor.** `cp -r LibKa0s/. <Addon>/libs/LibKa0s/` then
   `diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s` — **must be empty**
   (`docs/releasing.md`). Whole folder, every file, every time.
4. **Client.** Retail, live interface version. `/console scriptErrors 1` before logging in, so a Lua
   error is a popup rather than a silence. Any character; a spec that can enter combat on a training
   dummy. Start from a `/reload` after the copy, so the client is running the new files.
5. **Confirm which copy is live** — this is the step that catches a re-vendor that did not happen:
   `/dump LibStub("LibKa0s-Perf-1.0").MODULES` must report `Perf = 7`, `PerfPanel = 3`.
   `/dump LibStub("LibKa0s-Options-1.0").MODULES` must be unchanged (`Options = 6`,
   `OptionsWidgets = 6`, `OptionsScroll = 3`).

---

## C-1 — load lists are gated against their sources

**Change covered:** C-1 — the XML and the suite directory are now the source of truth for
`tests/run.lua`.

**Setup:** LibKa0s repo, clean tree, suite green. This is a **falsification** check, not an in-client
one: the new cases are only worth their line count if they can go red. Take a `cp` backup of each
file you touch and restore from it — **never** `git checkout`, per `testing-§12`.

**Steps:**

1. `cp LibKa0s/LibKa0s.xml /tmp/xml.bak`
2. Create `LibKa0s/Extra.lua` containing a single `error("never loaded")` line, and add
   `<Script file="Extra.lua"/>` to `LibKa0s.xml`.
3. `lua tests/run.lua`
4. Restore: `cp /tmp/xml.bak LibKa0s/LibKa0s.xml && rm LibKa0s/Extra.lua`
5. Create `tests/test_probe_unlisted.lua` containing one case whose body is `T.fail("should be red")`.
6. `lua tests/run.lua`
7. `rm tests/test_probe_unlisted.lua`
8. `lua tests/run.lua` and `git status --porcelain`

**Expected:**

- Step 3 **fails**, naming `LibKa0s/Extra.lua` as present in the XML and absent from the load list.
  *(Before C-1 this printed `480 passed, 0 failed` — that is the defect.)*
- Step 6 **fails**, naming `test_probe_unlisted` as a suite file that is not declared.
- Step 8 is green at the expected total, and `git status --porcelain` is empty.

**Pass / Fail:** PASS only if **both** steps 3 and 6 go red and step 8 restores a clean green tree.
A green run at step 3 or 6 means the case cannot fail and is worse than no case.

---

## C-2 — the API-document gate

**Change covered:** C-2 — a minor bump is blocked until its `docs/api/` document exists.

**Setup:** LibKa0s repo, clean tree, suite green.

**Steps:**

1. `lua tests/run.lua` — note it is green with all five documents present.
2. `mv docs/api/Perf/version-7.3-docs.md /tmp/` (use whatever the current Perf key is).
3. `lua tests/run.lua`
4. `mv /tmp/version-7.3-docs.md docs/api/Perf/`
5. `lua tests/run.lua`

**Expected:** step 3 fails with a message naming the exact missing path
`docs/api/LibKa0s-Perf-1.0/version-7.3-docs.md`; step 5 is green again.

**Pass / Fail:** PASS if step 3 names the path (not merely "a document is missing") and step 5
restores green.

---

## C-3 — descriptor errors say which field

**Change covered:** C-3 — the four descriptor arms assert on the message.

**Setup:** LibKa0s repo. `cp LibKa0s/Perf.lua /tmp/Perf.lua.bak` first.

**Steps:**

1. Replace `required(d, "name", "string")` in `LibKa0s/Perf.lua` with a no-op line.
2. `lua tests/run.lua`
3. `cp /tmp/Perf.lua.bak LibKa0s/Perf.lua`
4. `lua tests/run.lua`

**Expected:** step 2 **fails** on
`lib: New requires a name, an sv global and a suspend/resume pair`, with a message showing the raise
was `attempt to index field 'name'` rather than
`LibKa0s-Perf: descriptor.name must be a string`. Step 4 is green.

**Pass / Fail:** PASS if step 2 goes red. *(Before C-3 this exact mutation left the suite at 480/480 —
that is the finding.)*

---

## C-4 — the bracket cost claim, in a real client

**Change covered:** C-4 — corrected docstring, corrected API document, optional zero-overhead
scenario.

**Setup:** the consuming addon, logged in, out of combat, no perf run started. This checks that
correcting a comment changed nothing about behavior, and produces the one in-client number the
offline scenario cannot.

**Steps:**

1. `/dump LibStub("LibKa0s-Perf-1.0").MODULES` — confirm `Perf = 7`.
2. Run the host's normal workload for ~60 s with **no** capture running (open the UI, target things,
   whatever exercises the host's bracketed paths). Confirm no Lua error popup.
3. Start a capture and follow the host's two-arm protocol exactly as `performance-§7` specifies:
   `/<slash> perf start baseline`, then `measure a` (clean arm, host active), fight a training dummy
   until combat ends; then `measure b` (the suspend arm), fight the **same** dummy the same way; then
   `finish`. **No `/reload` between arms**, no addon-set changes, windows opened on the player's
   combat state (the sampler does this itself).
4. `/<slash> perf report` and read the **bucket** table — calls, total ms, ms/s, max ms.
5. `/reload`, then commit the record from the host's `<Addon>PerfDB` ring into that addon's
   `docs/perf-runs/<YYYY-MM-DD>-ingame-<label>.json`.

**Expected:** no Lua errors at any step; the bucket table lists every bucket the host declared, each
with a non-zero `calls` count; the nesting note appears if the host declares `within`.

**Pass / Fail:** PASS if the run completes with no error and every declared bucket shows calls > 0.
**Read the bucket figures, not the frame-time delta** — the delta between arms is unresolved below
the harness's own run-to-run spread and must not be the basis of any conclusion here.

---

## C-5 — a keyless bracket close does not raise mid-capture

**Change covered:** C-5 — `P.Note` refuses a non-string key.

**Setup:** the consuming addon, logged in, out of combat.

**Steps:**

1. `/run local P = <AddonNS>.Perf; P.Close(P.Open())` — out of combat, capture off. (Substitute the
   host's own accessor for its perf instance.)
2. Start a run and arm window A: `/<slash> perf start guardcheck`, `/<slash> perf measure a`, and
   enter combat on a dummy so the window opens.
3. While recording, `/run local P = <AddonNS>.Perf; P.Close(P.Open())`
4. Leave combat, `/<slash> perf cancel`.

**Expected:** no Lua error popup at step 1 **or step 3**. Step 3 is the one that matters — before
C-5 it raised `table index is nil`, and only while a capture was live.

**Pass / Fail:** PASS if neither step produces an error and the panel keeps rendering afterward.

---

## C-6 — a cancelled run leaves no context behind

**Change covered:** C-6 — `P.Cancel` clears `P.context`.

**Setup:** the consuming addon, logged in.

**Steps:**

1. `/<slash> perf start contextcheck` — the chat ack prints `who:` / `where:` / `group:` lines.
2. `/<slash> perf cancel` — expect `perf run CANCELLED — nothing saved`.
3. `/<slash> perf report`
4. Open the host's debug console (`/<slash> debug`) and read the report block just written.

**Expected:** the report at step 3/4 shows `capture: unlabelled`, both arms `(not sampled)`, an empty
bucket table, and **no** `who:` / `where:` / `group:` lines. Before C-6 those three lines were
present and described the discarded run.

**Pass / Fail:** PASS if the three context lines are absent.

---

## Regression suite

Not tied to any one change. Run in the consuming addon after the re-vendor.

| # | Check | Expected |
|---|---|---|
| R-1 | Fresh login → `PLAYER_LOGIN` → `PLAYER_ENTERING_WORLD` | No Lua error popup, no red `Interface action failed` text |
| R-2 | `/reload` twice in a row | Clean both times |
| R-3 | Wipe the host's SavedVariables, log in fresh | Defaults populate; the perf ring is created on first `finish`, not before |
| R-4 | `/<slash> config` out of combat | Panel opens on the host's landing page; the left tree is expanded |
| R-5 | `/<slash> config` **in** combat | Gray refusal `cannot open settings during combat — Blizzard's category-switch is protected`; panel does **not** open; no taint error |
| R-6 | Open the settings panel from **Esc → Options → AddOns**, in combat | The Settings window closes and the same gray refusal prints — the sidebar path is guarded too |
| R-7 | Every options page: open each, toggle each control once, drag a slider, drag a color | Values persist; paired controls re-sync; no error |
| R-8 | Page **Defaults** button, then the Settings window's own **footer** defaults control | Both reset the same page identically |
| R-9 | `/<slash> debug`, log some lines, **Copy**, **Clear** | Console opens; copy box holds the whole buffer in order; clear empties both the view and the count |
| R-10 | `/<slash> list`, `get`, `set` on a number, a bool, a string and a color | Echo reports what was **stored** (a clamped number reads back clamped); a color prints `{r, g, b, a}`, never a table address |
| R-11 | Full perf cycle: `start` → `measure a` → fight → `measure b` → fight → `finish` → `report` → `dump` → `/reload` | Host is **resumed** after `finish` (its frames and events are back); the record is in `<Addon>PerfDB` after the reload |
| R-12 | Perf panel: click every row that is clickable; click a locked row | Clicking a locked row does nothing; a click prints exactly what typing the same command prints |
| R-13 | Enter and leave combat with the console and the perf panel both open | Both stay visible and keep repainting; no error |
| R-14 | Press **Esc** with the console open, then with the perf panel open | Each closes; the run is unaffected |

## Sign-off

| ID | Tested? | Pass/Fail | Notes |
|---|---|---|---|
| C-1 | | | |
| C-2 | | | |
| C-3 | | | |
| C-4 | | | |
| C-5 | | | |
| C-6 | | | |
| Regression R-1…R-14 | | | |
