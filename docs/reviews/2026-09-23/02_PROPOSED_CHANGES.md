# 02 — Proposed changes (LibKa0s, 2026-09-23)

**Standard resolved:** Ka0s WoW Addon Standard **v2.64.0 (2026-09-23)**. I fetched `STANDARDS.md` and every section file its Sections list links to, via `curl` from `raw.githubusercontent.com/tusharsaxena/WowAddonStandards/master`, and checked every change below against it.

**Ground rules that apply to all of this:**
- Every change goes into this repo (`LibKa0s/` or `testkit/`).
- Every payload change bumps the changed **file's** LibStub minor (and the major's version key where the major spans files), updates `CHANGELOG.md` and its API document, and regenerates `members-<key>.json` (`docs/releasing.md`).
- Everything then goes out by a **whole-folder re-vendor into all eleven consumers, one commit per consumer**.
- **No change raises any floor.** A floor raise breaks vendoring (library-stack-§7), and none of these fixes needs one.
- **No descriptor field is removed or repurposed.** Every contract change is a new optional field or a new reading of a return value that nothing used before.

There is no separate upstream change-set, because this *is* the upstream. No entry targets a consumer's `libs/` or `tests/_kit/`.

## HLD: themes

### T1. Read the item links the client actually emits (F-001, F-013)
The quality fallback needs a rung for `|cnIQ<n>` ahead of the hex rung. The hex rung stays, because stored link text written before 11.1.5 still carries it. The fixtures move to the current link shape, and one case keeps the old shape as the legacy rung's pin.
- **Rejected:** replacing the hex rung outright. LootHistory's saved history holds older links, and re-rendering them would lose quality.
- **Rejected:** deriving quality from `C_Item.GetItemQualityByID`. That's the cached, base-item answer, which is exactly what the link fallback exists to avoid (the header at `Item.lua:75-79`).

### T2. The page chrome pools what it draws (F-002)
This finishes minor 14's work in the half of `OptionsTabs.lua` it didn't reach:
- the header frame and the divider texture get a pool per `ctx`, the way `__tabPool`/`__panelPool` already work;
- the banner's AceGUI Dropdown is **released to AceGUI** instead of being unparented.

- **Rejected:** keep allocating but `SetParent(UIParent)` and hide. That still grows without bound (events-frames-taint-§6).
- **Rejected:** keep one Dropdown per `ctx` alive across renders. AceGUI widgets are pooled process-wide, so holding one outside a container fights the rule this file documents for AceGUI-pooled frames (`Widgets.lua:783-795`).

### T3. The library's own seams agree with each other (F-003, F-008, F-014)
- Slash already takes `set` as a value and Schema's `Set` already answers `false, err`, so the CLI should read that answer.
- Core's printer should take the same `pcall` fallback DebugLog took for the identical failure.
- Both changes are additive readings of returns that nothing read before.
- **Rejected:** moving the Slash refusal into Schema, which would have Schema print. Schema deliberately "sends no message" (`Schema.lua:15-21`).

### T4. Survive the libraries we sit on (F-004, F-005)
- LSM's langmask rule and first-registration-wins behavior are correct upstream behavior, so we pass the mask and count what actually registered.
- AceEvent re-embedding on upgrade is also correct upstream behavior, so the Bus re-stamps its wrappers at its two edges.
- **Rejected for F-005:** a metatable proxy in front of the target. AceEvent writes fields directly onto the target and would bypass a proxy. Patching AceEvent is ruled out because forking Ace3 is forbidden (library-stack-§5).

### T5. The one click implementation owns the disabled refusal (F-006, F-009)
Two new optional fields go on the Launcher descriptor, so the rung (a)/(b) refusal lives in the one place anti-patterns #81 says it must.
- Rung (c) is still expressed by leaving out `onClick`, so the carve-out in launcher-§2 needs no flag.
- The missing-library notices print once, without the library's own tag.
- **Rejected:** having the Launcher resolve `LibKa0s-Slash-1.0` itself. That would couple two majors, and the host already holds its Slash instance and can pass its `DisabledLine` in as a function.

### T6. Tests that can go red (F-007)
The discarded `assertError` results are captured and asserted on. The kit also gains an additive `Kit.assertErrorMatches` so writing the correct form is the easy path.
- **Rejected:** changing what `assertError`'s `msg` argument means. Consumers already pass a failure message there, so repurposing it would break the kit's contract.

### T7. Small correctness and hygiene fixes (F-010, F-011, F-012, F-015, F-016, F-017)
Each is internal: a ring buffer, raw-initialized Perf fields, a library-owned drag poll and a pooled drop line, `openDepth` reset per window, documented re-entrancy for Lifecycle. For F-015 it's only a watch-list note.

## LLD: change set

### C-01: `Item.lua` reads `|cnIQ` (F-001, F-013) → Item minor 1 → 2
```lua
function lib.QualityFromLink(link)
  if type(link) ~= "string" then return nil end
  local iq = link:match("|cnIQ(%d+)")          -- 11.1.5+: named quality color
  if iq then return tonumber(iq) end
  local hex = link:match("|c%x%x(%x%x%x%x%x%x)")  -- pre-11.1.5 stored links
  if not hex then return nil end
  if not qualityByHex then buildQualityByHex() end
  return qualityByHex[hex]
end
-- buildQualityByHex: build into a local, and assign it to qualityByHex only if at least one entry landed.
```
- **Tests (`tests/test_item.lua`):** add fixtures in the current `|cnIQ4:|Hitem:…` shape, and keep the `|cff` fixtures as the legacy-rung case. Add a case for the empty-map retry (the map is built empty, then `ITEM_QUALITY_COLORS` is populated, and the next call answers). The new `-- red under:` comment is "drop the `|cnIQ` rung".
- **Pass count:** goes up by about 2. `docs/test-cases.md` and the README `[tests]` badge move **in the same commit** (testing-§5).
- **Risk:** low. A link that contains both forms can't occur.

### C-02: Chrome pools (F-002) → OptionsTabs minor 3 → 4, and the Options version key moves
- `O.PageHeader`: take the frame from `ctx.__headerPool` (Pool.New/Acquire). Its release goes in `releaseChrome` through `Pool.ReleaseAll`, and it keeps `ctx.chrome` as its parent.
- `drawChromeDivider`: take the texture from a `ctx.__ruleTex` built once, then re-anchor it and show it. Release hides it and never calls `SetParent(nil)` on a Region.
- `O.PageBanner`: keep `ctx.__bannerWidget`. At the top of the next `releaseChrome`, call `AceGUI:Release(ctx.__bannerWidget)` (or `widget:Release()`) and clear it. Only the frames that are neither AceGUI widgets nor pooled go into the `__chromeKids` ledger.
- **Kit (kit revision +1):** the mock AceGUI counts `Create`/`Release` per type (a read-only `__created`/`__released` survey), so a suite can assert that `created - released` stays bounded. This is additive to the kit and doesn't change what any existing reader sees.
  - The survey belongs in `testkit/mock_record.lua` (618 lines), which already holds the kit's recording surveys, with only a two-line counter hook in `mock_base.lua`.
  - `mock_base.lua` is at 1446 lines, 54 short of layout-§1's cap, so it shouldn't take the survey itself.
- **Tests:** new `tests/test_options_tabs.lua` cases: "a second PageBanner render releases the first dropdown", "PageHeader reuses its frame across renders", "the divider texture is drawn once per ctx". The red-under mutation for each is "restore `releaseLedger` for that item".
- **Standards:** events-frames-taint-§6 (pooling), options-ui-§14 (the band's geometry is unchanged). The file stays under the cap: it's 1197 lines now and should grow by about 40.
- **Risk:** medium. AceGUI's `Release` fires `OnRelease` and resets the widget's callbacks. The `OnValueChanged` closure must not be kept anywhere else. This needs smoke test S-002.

### C-03: Slash reads the seam's refusal (F-003) → Slash minor 14 → 15
```lua
local ok, err = true, nil
if type(d.set) == "function" then ok, err = d.set(row.path, v) end
if ok == false then
  emit(self:Text("INVALID"):format(row.path))
  if type(err) == "string" and err ~= "" then emit("  " .. err) end
  return
end
emit(kv(row, read(row.path)))
```
- `CliReset` does the same when `applyDefault` answers exactly `false`: it prints a new `NO_DEFAULT` string, "`%s` has no default to restore", instead of an echo.
- **Descriptor doc:** `set` may answer `false, reason`, and `nil`/`true` keep the old behavior (library-stack-§7, additive).
- **Tests:** in `tests/test_slash.lua`, a `set` answering `false,"why"` prints INVALID and `why` and no echo. Also pin that `nil` still echoes.
- **Risk:** a host whose `set` returns `false` to mean something else.
  - I read five wrappers: AbsorbTracker (`settings/Slash.lua:600-603`), AuraMaster (`:467-471`), ConsumableMaster (`:524-527`), KickCD (`:378-381`) and MultiMeters (`:295`). All of them return `nil`, so none changes behavior.
  - BankLedger hands `Schema.Set` over directly and gains the refusal, which is the intended effect.
  - AuraMaster prints the refusal itself inside its wrapper. After the re-vendor it should `return NS.SetByPath(path, v)` and delete its own prints (M6), otherwise it prints nothing new but keeps a second copy.
  - Re-check the remaining hosts during the re-vendor.

### C-04: Media registers and counts honestly (F-004) → Media minor 3 → 4
```lua
local mask = (LSM.LOCALE_BIT_western or 0) + (LSM.LOCALE_BIT_ruRU or 0)
LSM:Register(mt.FONT or "font", name, path, mask ~= 0 and mask or nil)
if LSM:IsValid(mt.FONT or "font", name) then fonts = fonts + 1 end
```
- The same `IsValid` count applies to statusbars.
- Rewrite the comment at `:251-258` to say "first registration wins; every consumer's path names identical bytes."
- **Tests:** `tests/test_media.lua` gets a fake LSM with `locale_is_western = false` that refuses a font without a mask. Assert that the call passes the mask and that the count reflects `IsValid`.
- **Risk:** low. On Western clients the mask is a no-op.

### C-05: Bus re-stamps its wrappers (F-005) → Bus minor 1 → 2
- Keep `rec.wrap[kind] = { reg = fnR, unreg = fnU, all = fnA }`.
- Add a `restamp(rec)` that re-assigns each of the six members whose current value `~=` its wrapper. It also takes the new raw member as `rec.raw[kind]` when the member differs from both, because the upgraded AceEvent's functions are the ones to call.
- `StandDown` and `StandUp` call `restamp` for every target the bus created. That requires a `created` list, weak-keyed, next to `held`, because an untracked target is exactly the one that isn't in `held`. Both answer an extra trailing `restamped` count.
- **Tests:** in `tests/test_bus.lua`, simulate the re-embed by overwriting the members with fresh AceEvent ones, register through them, then check that StandDown takes the new registration down and StandUp puts it back. The red-under mutation is "drop `restamp`".
- **Risk:** a registration made between the re-embed and the next edge is only recorded if it went through the restamped wrapper. Registrations made before restamping remain live and untracked until the next `StandDown`, which still takes them down through `raw.all`. Say this in the docstring.

### C-06: Launcher owns the refusal and prints once (F-006, F-009) → Launcher minor 1 → 2
- New optional fields: `isEnabled` (function) and `disabledLine` (function returning a string).
- In `click`: `if not right and type(d.onClick)=="function" and isEnabled and not isEnabled() then emit(disabledLine()) return end`. Nothing is written, and right-click is unchanged (launcher-§2).
- Each notice prints through a `once[key]` guard. The strings drop the `[LibKa0s] ` tag: keys unchanged, values changed. `L` overrides keep working.
- **Tests:** in `tests/test_launcher.lua`, cover rung (a) refused while disabled, rung (c) unchanged while disabled, right-click unchanged, and one NO_ICON across two Register calls.
- **Consumer follow-up:** after the re-vendor, each host drops its hand-written gate and passes the two fields. That's per-host work, listed in `04_EXECUTION_PLAN.md` M6.

### C-07: Core printer `Format` falls back like DebugLog (F-008) → Core minor 7 → 8
```lua
local ok, out = pcall(string.format, lib.SafeToString(fmt), unpack(parts))
if not ok then
  local joined = { lib.SafeToString(fmt) }
  for i = 1, n do joined[i + 1] = parts[i] end
  out = table.concat(joined, " ")
end
emit(out)
```
- No floor moves: a DebugLog on any Core ≥ 1 still loads.
- **Tests:** in `tests/test_core.lua`, a secret into `%d` lands as the format string followed by `<secret>`. The red-under mutation is "remove the pcall".

### C-08: Schema passes `instanceId` through (F-014) → Schema minor 1 → 2 (**optional; defer until an instanced host adopts**)
- `S.ApplyDefault(row, instanceId)` forwards it to `S.Set`.
- In `S.Get`, a row's own `get` is called as `get(instanceId)`. Both changes are additive.

### C-09: Kit and test hygiene (F-007) → kit revision +1
- `testkit/framework.lua`: add `Kit.assertErrorMatches(fn, needle, msg)`, which returns the error and fails if `needle` isn't a plain substring of it.
  - The file is already over the cap (1583) under a ratified row whose re-check trigger is "the next kit revision that touches the suite inventory". This change doesn't touch the inventory, but it adds about 10 lines.
  - **Chosen:** put the helper in a new `testkit/asserts.lua` that `framework.lua` loads, so the cap row doesn't grow (layout-§1).
  - **Rejected:** appending to `framework.lua`, which would grow a census row with no disposition change.
- Rewrite the 23 call sites to assert on what was raised. The biggest win is `test_launcher.lua:123-128`, whose expected strings become `needle`s.
- **Pass count:** unchanged (same cases, stronger assertions).

### C-10: Widgets drag poll on the library's own frame (F-012) → Widgets minor 9 → 10
- The `OnUpdate` goes on `ghost`, which already follows the cursor, reading `ghost.__row`. `finishDrag`/`Cancel` clear the ghost's script instead of the host frame's.
- The drop line comes from a per-process pool, is re-parented per `Finish`, gets the current list's color, and is reclaimed in `Cancel`.
- **Tests:** in `tests/test_widgets.lua`, the host frame's `OnUpdate` is untouched across a drag, and a second list on the same container gets its own color.

### C-11: DebugLog ring buffer (F-010) → DebugLog minor 12 → 13
- Use a fixed-size array with a head index. `BufferSize`, `LastLine`, `FindLine` and `CopyText` walk it in order.
- **Tests:** existing buffer cases, plus "1501st line drops the first".
- **Risk:** `D.buffer` is a public field. Keep `D.buffer` as a **view** (ordered) rebuilt lazily for readers, or document the change. Grep the consumers for `.buffer`; if any read it, keep the array and move to a batched trim (compact every 64 lines).

### C-12: Perf hygiene (F-011, F-016) → Perf minor 12 → 13
- Initialize `P.armed`, `P.recording` and `P.label` with `rawset(P, k, false)` before `setmetatable`. Every `if P.armed`-style read is truthiness, so it's unchanged. Audit `== nil` reads first.
- Rewrite the comment at `:400-401` to say "the GATE is a raw field; the instance carries a metatable only for `suspended`".
- Reset `openDepth = 0` in `openWindow` and `closeWindow`.
- **Tests:** in `tests/test_perf_core.lua`, a leaked Open in window A doesn't parent a bracket in window B. `tests/test_perf_isolation.lua`'s 0 KB pin must stay green.

### C-13: Lifecycle re-entrancy documented and pinned (F-017) → Lifecycle minor 1 → 2 (doc and test only; no behavior change if "document" is chosen)
- Add a docstring for `New`: a callback MUST NOT take or release a hold. Add a case that pins today's nested-edge behavior, so any change to it is deliberate.

### C-14: F-015 watch entries (no code)
- Add `lib.Catalog`, `lib.GetSpellCooldown`, `idHelpIcon` and `liveTimers` to the Disposition column of `RESULTS.md`'s watch list at the **next release run**: "at CCN 15; next edit peels".
- Don't regenerate `RESULTS.md` now. Don't gate a commit on complexity (performance-§10).

## Standards conformance per change

| Change | Constrained by | Note |
|---|---|---|
| C-01 | localization-§4 (match on IDs), library-stack-§7 (additive) | reads the numeric quality id |
| C-02 | events-frames-taint-§6, options-ui-§14 | band geometry unchanged, pooling added |
| C-03 | library-stack-§7 (additive), architecture-§5 (single write seam) | the seam's answer is honored, not bypassed |
| C-04 | library-stack-§8 | registration stays in Media |
| C-05 | library-stack-§5 (no forking Ace), anti-patterns #85 | the stand-down stays total |
| C-06 | launcher-§1/§2, anti-patterns #81, slash-commands-§7 | one click implementation, the refusal line stays the dispatcher's |
| C-07 | debug-logging-§4 | the same fallback as DebugLog |
| C-09 | testing-§12, layout-§1 | the helper goes in a new kit file, not a capped one |
| C-10 | events-frames-taint-§6 | the library owns what it parents |
| C-11/C-12/C-13 | performance-§2 (the gate stays a raw boolean), testing-§13 (characterization before refactor) | C-11 changes a data structure, so characterization cases first |

## Test and complexity movement (for the release to confirm)
- Pass count: about +12 to +16 across C-01 to C-13. `docs/test-cases.md` and the README badge move with each commit that moves the count, never deferred.
- Watch-list direction: `lib.QualityFromLink` goes from 3 to 4 CCN, and `click` in the Launcher goes up by about 3 (still under 10). None of the four CCN-15 functions is touched except by C-14's note. Regenerated at the release run, not here.
