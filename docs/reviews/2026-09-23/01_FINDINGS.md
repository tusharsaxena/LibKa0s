# 01 — Findings (LibKa0s, 2026-09-23)

**Verdict: minor issues. Nothing blocks shipping, but there are two High findings to fix before the next re-vendor:** the item-quality fallback can't read the link format the client has shipped since 11.1.5, and the page chrome leaks an AceGUI widget and a frame on every full page render.

Reviewed as **the upstream library**. Fixes to the payload (`LibKa0s/`) and the kit (`testkit/`) land here directly, then go out to the eleven consumers by whole-folder re-vendor. Nothing in this bundle proposes an edit under any consumer's `libs/` or `tests/_kit/`.

Standards cross-check: **done**, against Ka0s WoW Addon Standard **v2.64.0 (2026-09-23)**. That covers `STANDARDS.md` plus all 28 section files its Sections list links to. `tiered-layout` shows up only in the changelog as a retired name, and its URL now returns 404.

## Measurement run (Step 0: everything re-run on 2026-09-23 at `46ccaa6`, clean tree)

`ka0s-bounded` is not on `PATH` in this shell, so each run used it by absolute path: `~/.claude/wow-addon/bin/ka0s-bounded`. Scratch output is in `/tmp/claude-1000/lk-review/`. Nothing was written into the repo apart from this bundle.

| Suite | Result | Command |
|---|---|---|
| luacheck | **pass**: 0 warnings / 0 errors in 81 files | `ka0s-bounded luacheck .` |
| Headless suite | **pass**: 1484 passed, 0 failed, 1 skipped (1485 total) | `ka0s-bounded lua5.1 tests/run.lua` |
| Fresh `--list` inventory | **pass**: byte-identical to the committed `docs/test-cases.md` after CR normalization | `ka0s-bounded lua5.1 tests/run.lua --list > /tmp/claude-1000/lk-review/test-cases.md` |
| `tests/perf.lua` | **skipped**: the file doesn't exist (a library repo ships no offline scenarios; the latest manifest records the same skip) | — |
| lizard | **pass**: 0 warnings, max CCN 15, 30419 NLOC, 4248 functions, avg CCN 2.0 | `ka0s-bounded lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .` |
| `make test` | **skipped**: no root `Makefile` | — |
| Kit sync (in repo) | **pass**: `diff -rq testkit tests/_kit` is empty | `diff -rq LibKa0s/testkit LibKa0s/tests/_kit` |
| Vendor sync (downstream) | **pass**: all 11 consumers show 0 diffs for `libs/LibKa0s` and 0 for `tests/_kit` | `diff -rq LibKa0s/LibKa0s <A>/libs/LibKa0s` and `diff -rq LibKa0s/testkit <A>/tests/_kit` for each A in AbsorbTracker AuraMaster BankLedger ConsumableMaster KickCD LootHistory MultiMeters PanelMaster PartyFrameEnhanced PrettyChat WhatGroup |
| Cross-addon 1: slash tokens | **clean**: 22 roots across 11 addons, `uniq -d` empty; 0 raw `SLASH_*` in any TOC-derived load list | the two loops in the review brief, run over the 11 consumers |
| Cross-addon 2: vendored minors | **clean**: one line across all 11 plus source: `Bus:1 Compat:1 Core:7 DebugLog:12 Env:1 Item:1 Launcher:1 Lifecycle:1 Media:3 Options:23 Perf:12 Pool:3 Schema:1 Slash:14 Widgets:9` | `grep -rhoE 'local MAJOR, MINOR = …'` per repo, then `sort -u` |
| Cross-addon 3: payload bytes | **clean**: every consumer's `libs/LibKa0s` matches the source byte for byte. The recorded baseline's two PrettyChat CR stragglers are gone | `diff -rq`, reference = this repo's `LibKa0s/` |
| Cross-addon 4: `## Interface:` | **clean**: one value, `120100`, across all 11 | `grep -h '^## Interface:' */*.toc \| tr -d '\r' \| sort -u` |

**How today compares with what's on disk and with the baselines:**
- `docs/test-cases.md` matches the fresh inventory. Not stale.
- `docs/automated-tests/RESULTS.md`, newest row `20260923-144526` (`ae48f3f`, clean, 1.54.2 → 1.55.0): today's lizard totals match it exactly (30419 / 4248 / 2.0 / max 15 / 0 warnings), and so do the test counts. Not stale. The two commits since `ae48f3f` changed documentation only.
- The cross-addon baseline dated 2026-09-07 moved in three expected ways, none of them a finding. The roster grew from 9 to 11 addons (AuraMaster and PartyFrameEnhanced, 22 roots). The Interface value moved `120007 → 120100`, still uniform. The minors moved up uniformly, including four new majors.
- Census scope for the line-ending check: the whole tracked set (`git ls-files`, binaries excluded by extension). Result: 0 text stragglers. `media/logos/ka0s.logo.jpg` showed an uneven CR/LF count, but it's a binary marked in `.gitattributes`, so it isn't a straggler.
- Census scope for the LOC cap: the default (`git ls-files '*.lua' | grep -vE '^(libs/|tests/_kit/)'`, 81 files). Three files are over 1500: `tests/test_options_widgets.lua` 4086, `LibKa0s/OptionsWidgets.lua` 3922, `testkit/framework.lua` 1583. All three are in CLAUDE.md's census (issues #33 and #32, plus a ratified row), so none is a finding.

**Conventions found in the sweep:**
- No `CHAT_PREFIX`. Printers are descriptor-injected: `Core:New`'s `prefix`/`sink`, and every major's `print`.
- The `COMMANDS` table is owned by the host and handed to `Slash:New`.
- The single write seam is `LibKa0s-Schema-1.0`'s `S.Set`.
- The secret-value seam is `Core.IsConcatSafe`/`SafeToString` plus `Compat.IsSecret`/`CanAccess`/`IsSafeKey`.
- `.gitattributes` carries the client-bound CRLF pin, the `*.sh`/`*.py` LF carve-outs and the binary list.
- The media catalog is shipped by `Media.lua`.
- The kit is authored in `testkit/` and consumed through `tests/_kit/`.
- The runner's load list is derived from `LibKa0s.xml` (`tests/run.lua:24`).
- The suite list is hand-typed, but `Kit.assertSuiteInventory` guards it.

---

## High

### F-001: `Item.QualityFromLink` can't read the item-link color the shipping client emits, and the suite pins the retired format `[deprecated-api]` `[tests]`

- **Where:**
  - `LibKa0s/Item.lua:85`: `local hex = link:match("|c%x%x(%x%x%x%x%x%x)")`
  - `tests/test_item.lua:14-16`: `local EPIC_LINK = "|cffa335ee|Hitem:258586…"` and `local RARE_LINK = "|cff0070dd|Hitem:19019…"`
- **Problem:** Patch 11.1.5 changed the color sequence in item links from `|cff<hex>` to the named quality color `|cnIQ<n>:`, so that players can customize item quality colors. warcraft.wiki.gg's *ItemLink* page quotes it: "Color sequence used in item links has been replaced with `|cnIQx`", with the example `|cnIQ1|Hitem:6948…|h[Hearthstone]|h|r`. The pattern here only matches `|c` followed by eight hex digits, so on the `120100` client every real link answers `nil`.
- **Impact:** This fallback is the module's stated reason to exist (the "THIS IS THE UNCACHED FALLBACK" header at `Item.lua:75`), and today it answers nothing. LootHistory's `Compat.GetItemInfo` falls back to it for any item that isn't cached yet (`LootHistory/core/Compat.lua:163`: `quality = quality or NS.Item.QualityFromLink(link)`), so those drops are recorded with a `nil` quality. That's the misclassification the module was extracted to end.
- **Reachability:** Any LootHistory player, every session, for every looted item the client hasn't cached yet. That's the common case for fresh drops and upgrade-track items. BankLedger vendors the member but has no production caller.
- **Evidence and coverage:** Three cases claim to cover this path (`item: QualityFromLink reads the quality out of the colour prefix` and its two siblings), plus LootHistory's `test_itemsetup.lua:14`. Every fixture uses the pre-11.1.5 `|cff` shape, so the cases pass against a link format the client stopped emitting. The source for the format change is warcraft.wiki.gg's `ItemLink` and `UI_escape_sequences` pages, fetched today. The in-client confirmation is smoke test S-001.
- **Fix direction:** Add a rung that reads the quality number out of `|cnIQ(%d+)` directly (anchor on the digits and do not require the trailing `:`, since the wiki example quoted above renders without it), ahead of the hex rung. Keep the hex rung for older link text that's still stored. This is an additive change to one member: bump `Item.lua` to minor 2 and re-vendor.

### F-002: Every full render of a page with a banner or header leaks an AceGUI Dropdown or a raw Frame, plus a texture `[perf]` `[design]`

- **Where:**
  - `LibKa0s/OptionsTabs.lua:1036`: `local dd = AceGUI:Create("Dropdown")` (in `O.PageBanner`)
  - `:1117`: `local frame = CreateFrame("Frame", nil, ctx.chrome)` (in `O.PageHeader`)
  - `:577`: `local tex = edgeTexture(ctx.chrome, "ARTWORK", CHROME_RULE_COLOR)` (in `drawChromeDivider`)
  - The release is `releaseLedger` at `:734-741`: `f:Hide()` / `f:SetParent(nil)` / `ctx[key] = {}`
- **Problem:** The chrome ledger is emptied by hiding and unparenting whatever it holds.
  - Nothing ever returns the banner's Dropdown to AceGUI with `AceGUI:Release`. The widget object, its pull-out, its callbacks and the `spec` its closure captures all stay alive, and the next `AceGUI:Create` can't reuse it.
  - `PageHeader` creates a new raw `Frame` every call.
  - The hairline divider creates a new texture on `ctx.chrome` every call. Textures can't be destroyed, so they pile up on the chrome frame.

  This is the per-render allocation that minor 14 removed from the tab strip, with a pool (`OptionsTabs.lua:29-32`: "falling back to allocating per click, is precisely the leak that minor ended"). It survived in the banner/header half of the same file.
- **Impact:** Memory grows without bound for the session, one widget or frame plus one texture per full page render. Nothing reports it and every suite stays green. The kit's mock AceGUI "never reuses a widget" (`testkit/mock_base.lua:1364`), so no case can see the difference.
- **Reachability:** Any player opening a settings page with a banner (AuraMaster `settings/OptionsSetup.lua`, ConsumableMaster `settings/StatPriority.lua`, KickCD `settings/Panel_Render.lua`, MultiMeters `settings/Windows.lua`) or a header (AbsorbTracker `settings/UnitPanel.lua`, AuraMaster, KickCD `settings/Spells.lua`, PanelMaster `settings/PanelEditor.lua`). The leak repeats on every banner pick (MultiMeters re-renders with `H.RefreshPanel(ctx, true)`, `Windows.lua:465`), every `O.SelectTab`, every profile switch and every Reset-all.
- **Coverage:** `docs/test-cases.md` claims `widgets: PageBanner draws a seeded picker and reserves the banner band` and `widgets: PageHeader reserves the band, and the strip lands beneath it`. No case asserts that a second render releases the first render's widget.
- **Unverified side issue:** `releaseLedger` calls `SetParent(nil)` on a **texture** (the divider). Whether the client accepts a nil parent for a Region is unverified out of game. It's folded into smoke test S-002.
- **Fix direction:** Pool the header frame and the divider texture per `ctx`, the way minor 14 pools tabs and panels (`LibKa0s-Pool-1.0`). Release the banner Dropdown with `AceGUI:Release` (or `dd:Release()`) and don't just unparent it. This is internal only, with no descriptor change (events-frames-taint-§6).

## Medium

### F-003: The slash CLI throws away the write seam's refusal, so `set` on a rejected value echoes the old value as though it worked `[ux]` `[design]`

- **Where:**
  - `LibKa0s/Slash.lua:688`: `if type(d.set) == "function" then d.set(row.path, v) end`
  - `:703`: `if type(d.applyDefault) == "function" then d.applyDefault(row) end`
- **Problem:** This library's own write seam answers `false, err[, why]` when a row's `validate` rejects a value or when there is nowhere to store it (`LibKa0s/Schema.lua:451`: `if invalid then return false, invalid, why end`). `CliSet` ignores that return and prints `path = <stored value>`, which is the unchanged value, with no refusal and no reason. `CliReset` does the same with `ApplyDefault`'s `false`.
- **Impact:** The player types `/x set path value`, sees `path = old`, and can't tell a rejection from a typo in what they typed.
- **Reachability:** A player on any host that hands `Schema.Set` straight to Slash (BankLedger, `settings/Slash.lua:439`: `set = NS.SchemaRuntime.Set`) and has rows with a `validate`. MultiMeters has fourteen rows with a `validate` (`settings/Schema.lua:182`–`:801`) behind its own `SetByPath` (`settings/Slash.lua:295`). Values the parser accepts and the validator rejects reach this path today. AuraMaster has already written the workaround by hand, inside its own `set` wrapper (`AuraMaster/settings/Slash.lua:467-471`: `local ok, err, why = NS.SetByPath(path, v)` / `if not ok and err then print(err) end`). That's a host carrying a copy of a behavior the library should own.
- **Fix direction:** Additive. When `d.set` answers exactly `false` and a string, print `INVALID` plus that string instead of the echo. A host returning `nil` sees no change (library-stack-§7, additive-only).

### F-004: `RegisterLSM` doesn't register the monospace face on non-Western clients, but still counts it `[locale]` `[bug]`

- **Where:** `LibKa0s/Media.lua:274-275`: `LSM:Register(mt.FONT or "font", name, path)` / `fonts = fonts + 1`. The comment at `:251` is also wrong: "`Register` for an identical (mediatype, key, path) triple costs nothing".
- **Problem:** LibSharedMedia-3.0 silently refuses a font that has no `langmask` on a non-Western client (vendored `LibSharedMedia-3.0.lua:247-249`: `…or not (langmask or locale_is_western)) then return false`). This call passes no langmask and ignores the `false`, so on ruRU, koKR, zhCN and zhTW JetBrains Mono is never registered while the function reports `1`.
  - JetBrains Mono does cover Cyrillic, so ruRU loses a face it could draw.
  - The comment is wrong too. Every consumer registers a **different** path (`Interface\AddOns\<consumer>\libs\…`) under the same key, so what actually happens is that the first registration wins. Nothing guarantees the triples are identical.
- **Impact:** On those locales, a host default that names `"JetBrains Mono"` resolves to LSM's fallback face, and the face doesn't appear in any font dropdown. The debug console's own font comes from `Media.Font`, not LSM, so it isn't affected.
- **Reachability:** Every player on a ruRU, koKR, zhCN or zhTW client, on every host that calls `RegisterLSM` and stores the LSM name.
- **Fix direction:** Pass `LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU` as the langmask, count a font as registered only if `LSM:IsValid(type, name)` after the call, and correct the comment. Bump Media to minor 4.

### F-005: A newer AceEvent-3.0 loading later silently removes the Bus's tracking wrappers `[design]`

- **Where:** `LibKa0s/Bus.lua:196` (`AceEvent:Embed(t)`), with the wrappers stamped at `:165-184`.
- **Problem:** AceEvent-3.0 ends with `for target, v in pairs(AceEvent.embeds) do AceEvent:Embed(target) end` (vendored `AceEvent-3.0.lua`, last lines). When a later-loading addon ships a higher AceEvent minor, every embedded table has its six members overwritten, including the Bus wrappers. Registrations after that point go straight to CallbackHandler and are never recorded.
- **Impact:**
  - A target whose registrations all came after the re-embed never enters `held`, so `StandDown` leaves it live. That's the draw gate (anti-patterns #85) coming back with no error.
  - A target that is held has its untracked registrations unregistered by `StandDown`, but they're never replayed by `StandUp`, so the feature is dead after re-enabling until `/reload`.
- **Reachability:** Latent. It needs a session where an addon loading after the host ships a newer AceEvent-3.0 minor than the host vendors. Every Ka0s addon vendors the same one today, and third-party addons are outside our control.
- **Fix direction:** Keep each wrapper on `rec`. In `StandDown`/`StandUp`, re-stamp any member that no longer matches its wrapper and report the count through `isDown`'s host debug seam. It's internal: bump Bus to minor 2.

### F-006: The launcher's one click implementation has no disabled-state seam, so every host writes the rung (a)/(b) refusal itself, in three different spellings `[design]` `[ux]`

- **Where:** `LibKa0s/Launcher.lua:178-185` (`click`). The descriptor at `:98-127` has no `isEnabled` field.
- **Problem:** launcher-§2 requires a left-click on rung (a) or (b) to be refused while disabled, printing the dispatcher's one line and writing nothing. The module that owns the one `OnClick` (anti-patterns #81) can't express that, so each host puts the gate inside its `onClick`:
  - BankLedger: `NS.Slash:RefuseIfDisabled()` (`core/LauncherSetup.lua:156`)
  - AuraMaster: `NS.Print(NS.Slash.DisabledLine())` (`:120`)
  - AbsorbTracker: `return print(NS.Slash:DisabledLine())` (`:161`)
- **Impact:** These are three copies of a MUST that should live in one place. A host that forgets it ships a minimap click that writes SavedVariables on a disabled addon (anti-patterns #85).
- **Reachability:** Every host on rung (a) or (b), every time the player left-clicks the minimap button while the addon is disabled. Whether the refusal is right depends on each host's copy.
- **Fix direction:** Add optional descriptor fields `isEnabled` (function) and `disabledLine` (function returning the Slash line). When both are present and `onClick` exists, the library's `click` refuses the left button. Rung (c) is still expressed by leaving out `onClick`, so it stays unchanged. Additive: bump Launcher to minor 2.

### F-007: 23 `assertError` calls assert only that something raised, and four of them pass the expected text as the failure message `[tests]`

- **Where:**
  - `tests/test_launcher.lua:123-128`: `assertError(function() lib:New{ icon = "x", … } end, "descriptor.name")` and three more like it
  - `tests/test_kit_inventory.lua:173,182,190,202,230`
  - `tests/test_mock_ace.lua` (9 calls), `tests/test_loader.lua:116-117`, `tests/test_options_compose.lua:674-675`, `tests/test_schema.lua:548`
- **Problem:** `Kit.assertError(fn, msg)` treats `msg` as the message printed on **failure**. What was raised is only *returned* (`testkit/framework.lua:266-273`). The launcher case's `-- red under:` comment claims it checks which field was refused, but it doesn't. The kit-inventory cases can pass because `assertSuiteInventory` raises for an unrelated reason. testing-§12: "MUST NOT treat *'it raised'* as sufficient."
- **Impact:** These cases read as coverage for refusal paths without checking them.
- **Reachability:** Test inventory only. The shipped code behaves correctly (so graded Medium at most).
- **Command and scope:** `grep -nE '^\s*(T\.)?assertError\(' tests/*.lua | wc -l` gives 23 statement-position calls. Scope is `tests/*.lua` only, excluding `tests/_kit/`.
- **Fix direction:** Capture the return value and assert on a substring. Optionally add an additive `Kit.assertErrorMatches(fn, needle, msg)` so the correct form is the easy one to write.

### F-008: `Core` printer's `Format` still raises on a secret reaching a numeric specifier, which is the bug `DebugLog.Debug` already fixed `[design]`

- **Where:** `LibKa0s/Core.lua:459`: `emit(lib.SafeToString(fmt):format(unpack(parts)))`
- **Problem:** Arguments are converted to strings before formatting. A secret becomes the string `"<secret>"`, and `%d` or `%.1f` then raises `number expected, got string`. That puts the combat raise back on the path the member exists to protect. `DebugLog.lua:640-658` documents exactly this failure (found by WhatGroup) and fixes it with a `pcall` and a verbatim fallback. Core's printer, the other half of the same seam, doesn't have the fix.
- **Reachability:** Latent. Scope: the 425 tracked non-test `.lua` files of the 11 consumers (`git ls-files '*.lua' | grep -vE '^(libs/|tests/)'`). There, `grep -nE '(printf|Printf|KCM\.Say|NS\.Format)\(' | grep -E '%[-0-9.]*[dfxi]'` finds **0** call sites passing a numeric specifier through `printer.Format` today. The first one written will raise in combat.
- **Fix direction:** Use DebugLog's `pcall`-and-join fallback, internal to `printer.Format`. Bump Core to minor 8. This is not a floor raise.

## Low

### F-009: Launcher repeats its missing-library notices on every `Register`, and double-tags them `[ux]`

- **Where:** `LibKa0s/Launcher.lua:203`, `:228`, `:235` (`emit(text("NO_BROKER"|"NO_ICON"|"NO_MINIMAP"):format(name))`), with the strings at `:70-75`, which start with `"[LibKa0s] %s: …"`.
- **Problem:** `Register` is documented as callable from both `OnInitialize` and a login handler, so each notice prints twice. Each one also goes through the host's tagged printer, so it reads `<HostTag> [LibKa0s] <Host>: …`. No other major tags its own strings.
- **Reachability:** Only installs where the broker libraries are missing. Every Ka0s host vendors them.
- **Fix direction:** Emit once per instance, and drop the `[LibKa0s]` tag.

### F-010: The debug buffer trims with an O(n) `table.remove(1)` on every line once it hits the cap `[perf]`

- **Where:** `LibKa0s/DebugLog.lua:623`: `if #D.buffer > lib.MAX_BUFFER then table.remove(D.buffer, 1) end`
- **Problem:** At the 1500-line cap, every `Add` shifts 1500 slots.
- **Reachability:** A developer with debug logging on in a busy session, or `perf report` output. It's Low because it only happens under debug logging.
- **Fix direction:** Use a ring index, with `CopyText`/`FindLine`/`LastLine` walking it in order.

### F-011: Perf's gate comment says "no metatable" while the instance has one, and nil-initialized fields go through it every sampler frame `[naming]` `[perf]`

- **Where:**
  - `LibKa0s/Perf.lua:400-401`: "…it must stay a plain boolean field on a plain table — no metatable, no accessor."
  - `:424`: `setmetatable(P, {`
  - `:404-405`: `P.armed = nil` / `P.recording = nil` (assigning `nil` creates no raw key)
- **Problem:** `P.on` is raw, so the bracket gate itself is fine (performance-§2 holds). But `P.recording`, `P.armed` and `P.label` are never raw keys, so every read in `onUpdate` (`:940`) while nothing is recording calls the `__index` closure, and every write calls `__newindex`. The comment now describes a table that doesn't exist.
- **Reachability:** Only during a perf run. The cost is small and equal in both arms.
- **Fix direction:** Initialize them with `rawset(P, "armed", false)` (or a `false` sentinel), and correct the comment.

### F-012: `ReorderList` writes the host frame's `OnUpdate` script slot and caches its insertion line on the host's pooled container `[design]`

- **Where:**
  - `LibKa0s/Widgets.lua:999`: `row.frame:SetScript("OnUpdate", function() trackDrag(row) end)`, cleared at `:915` and `:1080`
  - `:753`: `container.__ka0sDropLine = line`
- **Problem:** The file itself documents that host frames are pooled by AceGUI and that caching on them is "a cache keyed on nothing" (`:783-795`), which is why handles are pooled. The drag poll takes over (and then clears) any `OnUpdate` the host frame carried. The insertion line rides back into AceGUI's pool on the container and keeps the **first** caller's `lineColor`.
- **Reachability:** No shipped row frame carries an `OnUpdate` today (MultiMeters Columns, ConsumableMaster priority list).
- **Fix direction:** Run the poll on the library-owned ghost frame, and pool the line the way handles are pooled.

### F-013: `Item`'s quality-color map is cached even when it was built empty, and `LoadItem` waits on a fixed timer `[bug]`

- **Where:** `LibKa0s/Item.lua:64` (`qualityByHex = {}`), with the cache test at `:87`, and `:124` (`C_Timer.After(0.4, cb)`).
- **Problem:** If the first call comes before `ITEM_QUALITY_COLORS` is populated, the empty map is kept for the whole session, which is the failure the comment at `:57-60` says the lazy build avoids. `LoadItem` fires its callback after 0.4 s whether or not the data arrived.
- **Reachability:** Unlikely in the client, since the FrameXML constant exists before addons load. It mostly matters once F-001 routes through `|cnIQ`, which doesn't need the map at all.
- **Fix direction:** Only cache a non-empty map. Leave `LoadItem` alone (it was byte-identical in both hosts) and record that decision.

### F-014: Schema's `ApplyDefault` and a row's own `get` drop `instanceId` `[design]`

- **Where:** `LibKa0s/Schema.lua:358` (`if type(get) == "function" then return get() end`) and `:497-502` (`S.ApplyDefault(row)` calls `S.Set(row.path, …)` with no id).
- **Problem:** `Set`/`Get` take an `instanceId` that goes through `resolveRoot`, but a reset can't target an instance and a closure row can't see which instance it's being read for.
- **Reachability:** Nobody today. AuraMaster, the one instanced host, keeps its own runtime (`AuraMaster/settings/Schema.lua:147`).
- **Fix direction:** Add an optional trailing `instanceId` to `ApplyDefault`, and pass `instanceId` to `row.get`. Additive, and only worth doing when an instanced host adopts the runtime.

### F-015: Four functions sit exactly at the release gate's CCN ceiling of 15 `[complexity]`

- **Where:** from today's lizard run:
  - `lib.Catalog`, `LibKa0s/Bus.lua:295-347`
  - `lib.GetSpellCooldown`, `LibKa0s/Compat.lua:243-260`
  - `idHelpIcon`, `LibKa0s/OptionsWidgets.lua:2944-2953`
  - `liveTimers`, `testkit/mock_record.lua:95-113`
- **Problem:** The next branch added to any of them fails the tag (automated-tests-§3). None of them is tangled. `GetSpellCooldown` is dense `or`-defaulting across five returns, and `Catalog` is a validation list.
- **Reachability:** A comment/process matter. No runtime effect.
- **Fix direction:** None now. Record them as watch entries so the next edit to each one peels instead of appending.

### F-016: A bracket left open by an error misattributes later brackets' observed parent for the rest of the run `[perf]`

- **Where:** `LibKa0s/Perf.lua:569-584` (`P.Close`). `openDepth` is only reset at `:592` (`P.Reset`, reached from `Start`).
- **Problem:** If the host raises between `Open` and `Close`, the slot is left open. Every later `Open` in that run stacks on top of it, so `Close` records the leaked key as the observed parent. A window closing doesn't reset the depth.
- **Reachability:** A capture where a bracketed host function raises mid-window. Only the `observedWithin` field in the record is wrong.
- **Fix direction:** Reset `openDepth = 0` in `openWindow`/`closeWindow`.

### F-017: The Lifecycle edge is re-entrant, and the file doesn't say so `[design]`

- **Where:** `LibKa0s/Lifecycle.lua:123-129` (`edge`).
- **Problem:** A `standDown` callback that takes or releases a hold fires a nested edge. That can mean a `standUp` running inside the `standDown` that's still unwinding. The ordering invariant (state before callback) keeps the latch consistent, but the host's teardown can be interleaved.
- **Reachability:** Nobody today. No shipped callback touches the latch.
- **Fix direction:** Document it as forbidden, or queue a nested edge until the outer callback returns. Pin whichever is chosen with a case.

---

**Upstream findings:** none. This is the upstream repo, and nothing here belongs to a third-party library. The `LibSharedMedia-3.0` and `AceEvent-3.0` behavior cited in F-004 and F-005 is correct upstream behavior that this library has to accommodate. Neither is a defect in those libraries.
