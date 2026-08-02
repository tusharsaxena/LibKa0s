# Evidence — 2026-08-02

Raw command output every claim in this bundle rests on. Run from the LibKa0s repo root on
2026-08-02. Consumer repos are siblings at `../<Addon>`.

---

## §1 — Scope: who is in scope

```
$ ls -d ../*/libs/LibKa0s 2>/dev/null
../AbsorbTracker/libs/LibKa0s
../BankLedger/libs/LibKa0s
../ConsumableMaster/libs/LibKa0s
../KickCD/libs/LibKa0s
../LootHistory/libs/LibKa0s
../PanelMaster/libs/LibKa0s
../WhatGroup/libs/LibKa0s
../prettychat/libs/LibKa0s

$ ls -d ../*/tests/_kit 2>/dev/null
../AbsorbTracker/tests/_kit
../BankLedger/tests/_kit
../ConsumableMaster/tests/_kit
../KickCD/tests/_kit
../LibKa0s/tests/_kit
../LootHistory/tests/_kit
../PanelMaster/tests/_kit
../WhatGroup/tests/_kit
../prettychat/tests/_kit
```

Eight consumers on disk. `docs/releasing.md`'s Consumers table names the same eight in its
`LibKa0s-Core-1.0` row: AbsorbTracker, KickCD, ConsumableMaster, BankLedger, LootHistory,
PanelMaster, prettychat, WhatGroup. No repo with `libs/LibKa0s/` is unnamed by the table, and the
table names no repo without one.

Sibling repos holding no vendored library, as expected: `BuffTextNotifications`, `WhoGotLoots`,
`WowAddonStandards`, and the non-addon repos.

---

## §2 — Version fidelity

```
$ for f in LibKa0s/*.lua; do grep -hoE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *= *("[^"]+", *)?[0-9]+' $f; done
```

**SHIP:**
```
Core.lua             local MAJOR, MINOR = "LibKa0s-Core-1.0", 3
DebugLog.lua         local MAJOR, MINOR = "LibKa0s-DebugLog-1.0", 7
Options.lua          local MAJOR, MINOR = "LibKa0s-Options-1.0", 5
OptionsScroll.lua    local SCROLL_MINOR = 2
OptionsWidgets.lua   local WIDGETS_MINOR = 5
Perf.lua             local MAJOR, MINOR = "LibKa0s-Perf-1.0", 5
PerfPanel.lua        local PANEL_MINOR = 3
Slash.lua            local MAJOR, MINOR = "LibKa0s-Slash-1.0", 5
```

The same extraction against each consumer's `libs/LibKa0s/*.lua` returned **byte-identical output to
the ship block above for all eight consumers**. Reproduced once in full for AbsorbTracker; the other
seven were verified the same way and printed the same eight lines:

```
===== AbsorbTracker =====
Core.lua             local MAJOR, MINOR = "LibKa0s-Core-1.0", 3
DebugLog.lua         local MAJOR, MINOR = "LibKa0s-DebugLog-1.0", 7
Options.lua          local MAJOR, MINOR = "LibKa0s-Options-1.0", 5
OptionsScroll.lua    local SCROLL_MINOR = 2
OptionsWidgets.lua   local WIDGETS_MINOR = 5
Perf.lua             local MAJOR, MINOR = "LibKa0s-Perf-1.0", 5
PerfPanel.lua        local PANEL_MINOR = 3
Slash.lua            local MAJOR, MINOR = "LibKa0s-Slash-1.0", 5
```

**64 / 64 cells at ship minors. No cross-major skew.**

---

## §3 — Byte fidelity, both halves

```
$ for a in <all eight>; do
    diff -rq LibKa0s ../$a/libs/LibKa0s | wc -l
    diff -rq --strip-trailing-cr LibKa0s ../$a/libs/LibKa0s | wc -l
    diff -rq testkit ../$a/tests/_kit | wc -l
    diff -rq --strip-trailing-cr testkit ../$a/tests/_kit | wc -l
  done

AbsorbTracker      lib byte:0 content:0 | kit byte:0 content:0
BankLedger         lib byte:0 content:0 | kit byte:0 content:0
ConsumableMaster   lib byte:0 content:0 | kit byte:0 content:0
KickCD             lib byte:0 content:0 | kit byte:0 content:0
LootHistory        lib byte:0 content:0 | kit byte:0 content:0
PanelMaster        lib byte:0 content:0 | kit byte:0 content:0
prettychat         lib byte:0 content:0 | kit byte:0 content:0
WhatGroup          lib byte:0 content:0 | kit byte:0 content:0
```

All 32 diffs empty. Byte and content agree in every case, so there is **no line-ending divergence**
anywhere and no `file -b` adjudication was required.

Library's own kit copy:
```
$ diff -rq testkit tests/_kit
(no output)
```

---

## §4 — Module coverage

```
$ grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' ../<Addon> --include='*.lua' \
    | grep -v '/libs/' | grep -v '/tests/'
```

```
===== AbsorbTracker =====
core/CoreSetup.lua:25:LibStub("LibKa0s-Core-1.0", true)
core/DebugLogSetup.lua:14:LibStub("LibKa0s-DebugLog-1.0", true)
core/PerfSetup.lua:14:LibStub("LibKa0s-Perf-1.0", true)
settings/Schema.lua:182:LibStub("LibKa0s-Slash-1.0", true)
settings/OptionsSetup.lua:36:LibStub("LibKa0s-Options-1.0", true)
settings/Slash.lua:24:LibStub("LibKa0s-Slash-1.0", true)
===== BankLedger =====
core/DebugLogSetup.lua:20:LibStub("LibKa0s-DebugLog-1.0", true)
core/CoreSetup.lua:34:LibStub("LibKa0s-Core-1.0", true)
settings/OptionsSetup.lua:26:LibStub("LibKa0s-Options-1.0", true)
settings/Slash.lua:99:LibStub("LibKa0s-Slash-1.0", true)
===== ConsumableMaster =====
core/CoreSetup.lua:33:LibStub("LibKa0s-Core-1.0", true)
core/SlashCommands.lua:1302:LibStub("LibKa0s-Slash-1.0", true)
modules/DebugLog.lua:55:LibStub("LibKa0s-DebugLog-1.0", true)
modules/PerfSetup.lua:29:LibStub("LibKa0s-Perf-1.0", true)
settings/Panel.lua:184:LibStub("LibKa0s-Options-1.0", true)
===== KickCD =====
core/CoreSetup.lua:64:LibStub("LibKa0s-Core-1.0", true)
core/DebugLogSetup.lua:45:LibStub("LibKa0s-DebugLog-1.0", true)
core/PerfSetup.lua:33:LibStub("LibKa0s-Perf-1.0", true)
settings/Slash.lua:55:LibStub("LibKa0s-Slash-1.0", true)
settings/OptionsSetup.lua:35:LibStub("LibKa0s-Options-1.0", true)
===== LootHistory =====
core/DebugLogSetup.lua:25:LibStub("LibKa0s-DebugLog-1.0", true)
core/CoreSetup.lua:32:LibStub("LibKa0s-Core-1.0", true)
settings/Slash.lua:103:LibStub("LibKa0s-Slash-1.0", true)
settings/OptionsSetup.lua:35:LibStub("LibKa0s-Options-1.0", true)
===== PanelMaster =====
core/DebugLogSetup.lua:79:LibStub("LibKa0s-DebugLog-1.0", true)
core/CoreSetup.lua:32:LibStub("LibKa0s-Core-1.0", true)
settings/OptionsSetup.lua:26:LibStub("LibKa0s-Options-1.0", true)
settings/Slash.lua:252:LibStub("LibKa0s-Slash-1.0", true)
===== prettychat =====
core/CoreSetup.lua:41:LibStub("LibKa0s-Core-1.0", true)
core/DebugLogSetup.lua:39:LibStub("LibKa0s-DebugLog-1.0", true)
settings/Slash.lua:72:LibStub("LibKa0s-Slash-1.0", true)
settings/Schema.lua:229:LibStub("LibKa0s-Slash-1.0", true)
settings/OptionsSetup.lua:17:LibStub("LibKa0s-Options-1.0", true)
===== WhatGroup =====
core/DebugLogSetup.lua:20:LibStub("LibKa0s-DebugLog-1.0", true)
core/CoreSetup.lua:39:LibStub("LibKa0s-Core-1.0", true)
settings/Slash.lua:73:LibStub("LibKa0s-Slash-1.0", true)
settings/OptionsSetup.lua:17:LibStub("LibKa0s-Options-1.0", true)
```

35 module-adoptions. Every file above is named in `docs/releasing.md`'s "Where the wiring lives"
column, including both second Slash lookups (`AbsorbTracker/settings/Schema.lua:182`,
`prettychat/settings/Schema.lua:229`).

---

## §5 — Descriptor surfaces: who passes what

```
$ for k in applySkin makeCloseButton skin format colorDecode colorEncode sliderCommit parse sep pairWith; do
    for a in <all eight>; do
      grep -rlE "(^|[,{ \t])${k}[ \t]*=" ../$a --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
    done
  done
```

```
applySkin -> BankLedger LootHistory
makeCloseButton ->
skin -> BankLedger
format -> BankLedger LootHistory prettychat
colorDecode -> AbsorbTracker ConsumableMaster KickCD
colorEncode -> AbsorbTracker ConsumableMaster KickCD
sliderCommit -> ConsumableMaster
parse -> BankLedger KickCD PanelMaster prettychat WhatGroup
sep -> prettychat WhatGroup
pairWith -> prettychat
```

`makeCloseButton` returns **no consumer**.

**Two lines of that output are false positives, annotated rather than removed** — the raw sweep is
left exactly as it printed. `skin -> BankLedger` is `../BankLedger/modules/SessionWindow.lua:456`, a
file-local `local skin = (NS.Browser and NS.Browser.SKIN) or { titleBarH = 30 }` reading
BankLedger's *own* skin table; no host passes the descriptor's `skin`, so every one falls through to
`core.SKIN` at `LibKa0s/DebugLog.lua:195` and the true count is **zero**. `sep -> … WhatGroup` is
`../WhatGroup/modules/Frame.lua:84`, `local sep = f:CreateTexture(nil, "ARTWORK")`, a divider
texture; only prettychat passes `sep`, at `../prettychat/core/CoreSetup.lua:103`, so the true count
is **one**. Both were caught by adversarial review the same day and corrected in `02_MATRIX.md` §5
and `03_DEVIATIONS.md` §5. The method lesson is the one §6 already records for the `-A6` window:
**a grep for a bare key name finds locals; only reading the descriptor tells you who passes one.**

Both hosts that formerly passed `makeCloseButton` carry an explicit note in its place:

```
$ grep -rnE "(applySkin|makeCloseButton|[,{ \t]skin[ \t]*=)" ../BankLedger ../LootHistory --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'

../BankLedger/core/DebugLogSetup.lua:96:  -- `applySkin` ONLY, and the reason is no longer that Core's chrome is different. As of Core minor
../BankLedger/core/DebugLogSetup.lua:107:  applySkin = function(frame)
../BankLedger/core/DebugLogSetup.lua:111:  -- NO `makeCloseButton`. The console and the copy window are the LIBRARY's windows, so they wear
../BankLedger/core/DebugLogSetup.lua:116:  -- on a library-drawn window is the library's. `applySkin` above is the opposite case and stays.
../BankLedger/modules/SessionWindow.lua:456:  local skin = (NS.Browser and NS.Browser.SKIN) or { titleBarH = 30 }
../LootHistory/core/DebugLogSetup.lua:11:-- 4 added `applySkin` and `makeCloseButton`, both defaulting to what minor 3 did, precisely so a
../LootHistory/core/DebugLogSetup.lua:121:  applySkin = function(frame)
../LootHistory/core/DebugLogSetup.lua:125:  -- NO `makeCloseButton`. The console and the copy window are the LIBRARY's windows, so they wear
../LootHistory/core/DebugLogSetup.lua:130:  -- on a library-drawn window is the library's. `applySkin` above is the opposite case and stays.
```

The library still ships and exercises it:

```
$ grep -n "makeCloseButton\|applySkin" LibKa0s/DebugLog.lua
166:---   applySkin   function  optional, minor 4. function(frame) — owns the whole skin job for BOTH
171:---   makeCloseButton function optional, minor 4. function(parent, onClick) -> button or nil.
241:  -- `applySkin` remains, and still owns the WHOLE job for both windows when a host supplies it —
247:  local applySkin = type(d.applySkin) == "function" and d.applySkin or defaultApplySkin
257:  local makeCloseButton = type(d.makeCloseButton) == "function" and d.makeCloseButton
321:    local close = makeCloseButton(titleBar, function() D:Hide() end)
435:    applySkin(frame)
462:    local close = makeCloseButton(titleBar, function() copyFrame:Hide() end)
483:    applySkin(copyFrame)      -- after the Hide and the Esc wiring, for the reason above

$ grep -rn "makeCloseButton" tests/*.lua
tests/test_debuglog.lua:600:test("dbg: with no makeCloseButton, BOTH windows close with Core's x", function()
tests/test_debuglog.lua:672:  local D = newLog{ makeCloseButton = function(parent, onClick)
tests/test_debuglog.lua:686:  local D = newLog{ makeCloseButton = function(_, onClick)
tests/test_debuglog.lua:699:  local D = newLog{ makeCloseButton = function() return nil end }
tests/test_debuglog.lua:721:  local D = newLog{ makeCloseButton = function()
tests/test_debuglog.lua:736:  local D = newLog{ makeCloseButton = function() return T.mocks.__stubFrame() end }
tests/test_debuglog.lua:742:  local D = newLog{ makeCloseButton = function() return nil end }
```

---

## §6 — The numeric-enum dropdown, and the `sliderCommit` cross-check

```
$ grep -rn 'type *= *"number"' ../BankLedger ../LootHistory --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'

../BankLedger/settings/Schema.lua:54:  { path = "settings.windowScale", default = 1.0, type = "number", min = 0.6, max = 1.6,
../BankLedger/settings/Schema.lua:76:  { path = "settings.qualityThreshold", default = 0, type = "number", widget = "Dropdown",
../BankLedger/settings/Schema.lua:83:  { path = "settings.retentionDays", default = 30, type = "number", widget = "Dropdown",
../LootHistory/settings/Schema.lua:52:  { path = "settings.windowScale", default = 1.0, type = "number", min = 0.6, max = 1.6, widget = "Slider",
../LootHistory/settings/Schema.lua:61:  { path = "settings.qualityThreshold", default = 1, type = "number", widget = "Dropdown",
../LootHistory/settings/Schema.lua:70:  { path = "settings.retentionDays", default = 30, type = "number", widget = "Dropdown",
```

Two consumers, two rows each.

Number rows per consumer:
```
AbsorbTracker: 5    BankLedger: 3    ConsumableMaster: 22    KickCD: 31
LootHistory: 3      PanelMaster: 2   prettychat: 0           WhatGroup: 1
```

ConsumableMaster's 22 number rows, all min/max/step, none with `values` — so the `sliderCommit` host
still has no enum row:

```
$ grep -rn -A7 'type *= *"number"' ../ConsumableMaster --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'

../ConsumableMaster/settings/MacroBar.lua:76:    path = "macroBar.perRow", type = "number", min = 1, max = 13, step = 1, group = "Layout",
../ConsumableMaster/settings/MacroBar.lua:81:    path = "macroBar.buttonSize", type = "number", min = 16, max = 64, step = 1, group = "Layout",
    … (20 more, every one carrying min/max/step)
../ConsumableMaster/settings/MacroBar.lua-101-    path = "macroBar.orientation", type = "string", group = "Layout",
../ConsumableMaster/settings/MacroBar.lua-102-    values = enum("HORIZONTAL", …),
```

**Note on method:** an initial `-A6` window reported ConsumableMaster as having 2 numeric-enum rows.
That was a false positive — the `values` key belongs to the *following* `type = "string"` row at
`:101-102`, not to the number row above it. Row-by-row inspection above is what the matrix records.
The same re-check was applied to BankLedger and LootHistory, where the `values` keys do belong to the
number rows.

The library dispatches on `values`, never on the host's `widget` key:

```
$ grep -n -A12 'row.type == "number"' LibKa0s/OptionsWidgets.lua
466:    if row.type == "number" then
467:      -- A number carrying a `values` list is an ENUM, not a range, and Slash.lua has said so
475:      -- INFERRED from `values`, not opted into with a `dialogControl`, because Slash infers too
```

`sliderCommit`:
```
$ grep -rn "sliderCommit" ../ConsumableMaster --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
../ConsumableMaster/settings/Panel.lua:226:        sliderCommit = "change",
../ConsumableMaster/settings/Panel.lua:419:--   * `sliderCommit` exists at all, so the Macro Bar page keeps its live drag
```

---

## §7 — The `L` trap, both halves

**Half one — every descriptor `L`:**

```
$ grep -rnE '(^|[,{[:space:]])L[[:space:]]*=' ../<Addon> --include='*.lua' \
    | grep -v '/libs/' | grep -v '/tests/' | grep -v 'local L'

===== AbsorbTracker =====   (none)
===== BankLedger =====      (none)
===== ConsumableMaster =====
core/SlashCommands.lua:362:                        say(("    [%2d] L=%q  R=%q"):format(i, left, right))
core/SlashCommands.lua:1320:        L            = SLASH_STRINGS,
===== KickCD =====
settings/Slash.lua:335:    L = NS.L and {
===== LootHistory =====     (none)
===== PanelMaster =====
settings/Slash.lua:328:  L = { RESET_ALL = "all settings reset to defaults (your panels are untouched)" },
===== prettychat =====      (none)
===== WhatGroup =====
settings/Slash.lua:182:    L = { ERR_BOOL = "expected true/false/on/off/1/0/toggle" },
```

`core/SlashCommands.lua:362` is a debug format string, not a descriptor. The four real descriptors
resolve as follows.

ConsumableMaster — a plain literal table, with per-key arity comments:
```
$ sed -n '/^local SLASH_STRINGS/,/^}/p' ../ConsumableMaster/core/SlashCommands.lua
local SLASH_STRINGS = {
    HELP_HEADER     = "|cffffd100Ka0s Consumable Master|r v%s … slash commands",
    HELP_ALIAS      = " (alias: |cffffff00%s|r)",
    UNKNOWN_COMMAND = "Unknown command: |cffffff00%s|r",
    USAGE_GET       = "Usage: %s get <path>  (try /cm list)",
    USAGE_RESET     = "Usage: %s reset <path> … this resets ONE setting. " ..
    …
```

KickCD — the legitimate `and`/`or` form that evaluates to a plain table:
```
$ sed -n '333,338p' ../KickCD/settings/Slash.lua
    L = NS.L and {
        LIST_HEADER = NS.L["Available settings"]
            and ("|cff33ff99" .. NS.L["Available settings"] .. "|r") or nil,
    } or nil,
```

**No descriptor anywhere is handed an addon-wide locale table.**

**Half two — the regression guards.** `grep -rn 'A-Z0-9_' ../<Addon>/tests --include='*.lua' | grep -v '_kit'`
returned matches in every consumer. Condensed, one line per module-adoption:

```
AbsorbTracker    test_ltrap.lua:154 (Core tw) 167 (Options tw) 204,219,235 · test_debuglog.lua:147,153
                 test_slash.lua:167 · test_helpers.lua:886 · test_perf.lua:418
BankLedger       test_libka0s.lua:208 (Core tw) 222/234 (Options tw) 461 734 737
ConsumableMaster test_coresetup.lua:124,128 (Core tw) · test_settingsui.lua:43-56 (Options tw) 198,214
                 test_debuglog.lua:274,276,288 · test_slashsetup.lua:117,125 · test_perfsetup.lua:60
KickCD           test_coresetup.lua:241,247,272 (Core tw) · test_options_panel.lua:423-450 (Options tw) 388,394,416
                 test_debuglogsetup.lua:275,298 · test_slash.lua:338,375,401 · test_perfsetup.lua:375,478
LootHistory      test_libka0s.lua:168 (Core tw, STRINGS half) 175 (source half) 188 (Options tw) 201
                 test_debuglog.lua:159,173,184 · test_slash.lua:225
PanelMaster      test_libka0s.lua:593,596 (Core tw) 461-470 (Options tw) 184 290
prettychat       test_libka0s.lua:119,121-123 (Core tw) 295-305 (Options tw) 195,200,204,205,449
WhatGroup        test_libka0s.lua:625,628,631 (Core tw) 636-642 (Options tw) 176,177,393,394,407,410
```

Every consumer carries **both** the Core tripwire (the `lib.STRINGS`-absent assertion and the source
check) and the Options tripwire (source half only). Representative messages showing the tripwires are
written to go red rather than to pass vacuously:

```
../LootHistory/tests/test_libka0s.lua:171:  assertEqual(core.STRINGS, nil,
  "Core grew a STRINGS table: it can now express the L trap and needs a rendered assertion")
../PanelMaster/tests/test_libka0s.lua:466:  assertTrue(rawget(o, "STRINGS") ~= nil, "Options lost its STRINGS table")
../ConsumableMaster/tests/test_settingsui.lua:56:  t.eq(type(rawget(lib, "STRINGS")), "table", …)
../WhatGroup/tests/test_libka0s.lua:393:  assertTrue(Sl:Text("ERR_BOOL") ~= lib.STRINGS.ERR_BOOL, "the override really took")
../WhatGroup/tests/test_libka0s.lua:394:  assertEqual(Sl:Text("ERR_NUMBER"), lib.STRINGS.ERR_NUMBER, "and nothing else was overridden")
```

**Coverage: 35 / 35 module-adoptions guarded.**

---

## §8 — Adoption depth, production source only

```
$ for s in CliList CliGet CliSet CliReset LandingRows HelpRows RenderRows RenderGrid RenderField \
           LSMValues SetRenderer SafeToString SKIN MakeCloseButton ApplySkin; do
    grep -rlo "[.:]$s\b" ../$a --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
  done

AbsorbTracker      CliList CliGet CliSet CliReset LandingRows RenderRows RenderGrid LSMValues SafeToString MakeCloseButton
BankLedger         CliList CliGet CliSet CliReset LandingRows RenderRows SetRenderer SafeToString SKIN MakeCloseButton ApplySkin
ConsumableMaster   CliList CliGet CliSet CliReset LandingRows RenderGrid RenderField LSMValues SetRenderer SafeToString SKIN
KickCD             CliList CliGet CliSet CliReset LandingRows HelpRows RenderRows RenderField LSMValues SafeToString MakeCloseButton
LootHistory        CliList CliGet CliSet CliReset LandingRows HelpRows RenderRows SetRenderer SafeToString SKIN MakeCloseButton ApplySkin
PanelMaster        CliList CliGet CliSet CliReset LandingRows HelpRows RenderRows RenderField LSMValues SetRenderer SafeToString SKIN
prettychat         CliList CliGet CliSet CliReset LandingRows RenderRows RenderField SetRenderer SafeToString
WhatGroup          CliList CliGet CliSet CliReset LandingRows HelpRows RenderRows RenderGrid RenderField LSMValues SetRenderer SafeToString SKIN MakeCloseButton ApplySkin
```

All four schema-CLI verbs and `LandingRows` present in all eight — both convergences adopted
everywhere.

`MakeCloseButton` / `ApplySkin` appearing in this list is **Core's** `lib.MakeCloseButton` /
`lib.ApplySkin`, which hosts call directly on their own windows. It is not DebugLog's descriptor
`makeCloseButton` hook (§5), which no host passes.

---

## §9 — The convergences and their ledgers

```
$ for a in <all eight>; do grep -coE 'LIBKA0S-[0-9]+' ../$a/docs/pending/LEDGER.md; done

AbsorbTracker: LEDGER yes, LIBKA0S rows=11, 'reset' mentions=1, 'landing' mentions=1
BankLedger: LEDGER yes, LIBKA0S rows=36, 'reset' mentions=5, 'landing' mentions=2
ConsumableMaster: LEDGER yes, LIBKA0S rows=25, 'reset' mentions=1, 'landing' mentions=1
KickCD: LEDGER yes, LIBKA0S rows=6, 'reset' mentions=2, 'landing' mentions=1
LootHistory: LEDGER yes, LIBKA0S rows=29, 'reset' mentions=6, 'landing' mentions=3
PanelMaster: LEDGER yes, LIBKA0S rows=34, 'reset' mentions=6, 'landing' mentions=4
prettychat: LEDGER yes, LIBKA0S rows=18, 'reset' mentions=2, 'landing' mentions=1
WhatGroup: LEDGER yes, LIBKA0S rows=19, 'reset' mentions=3, 'landing' mentions=2
```

All eight have a ledger. ConsumableMaster's — the repo the two 2026-08-01 runs found deficient here —
now records both convergences explicitly:

```
$ grep -n -i 'reset\|landing' ../ConsumableMaster/docs/pending/LEDGER.md
68:| LIBKA0S-12 | `reset-convergence` | adoption report 2026-08-01 — deviations §3, recommendations §3 Option A | 🟢 done | 2026-08-01 | The user chose Option A: converge, ke…
69:| LIBKA0S-13 | `landing-convergence` | adoption report 2026-08-01 (run v2) — deviations §4, recommendations §5 Option A | 🟢 done | 2026-08-01 | The user chose Option A: c…
```

---

## §10 — The green gate

```
$ lua tests/run.lua ; luacheck .
```

```
===== LibKa0s =====
  PASS  kitsync: testkit/ and tests/_kit/ hold the same set of files
  PASS  kitsync: every kit file is byte-identical in testkit/ and tests/_kit/, README included
419 passed, 0 failed, 419 total
Total: 0 warnings / 0 errors in 11 files

===== AbsorbTracker =====
  PASS  tests/_kit is the test kit that shipped with that release
469 passed, 0 failed, 469 total
Total: 0 warnings / 0 errors in 28 files

===== BankLedger =====
  PASS  tests/_kit is the test kit that shipped with that release
687 passed, 0 failed, 687 total
Total: 0 warnings / 0 errors in 24 files

===== ConsumableMaster =====
  PASS  Widgets: every widget name used by the settings pages is registered
  561 passed, 0 failed, 561 total
Total: 0 warnings / 0 errors in 50 files

===== KickCD =====
648 passed, 0 failed
Total: 0 warnings / 0 errors in 32 files

===== LootHistory =====
  PASS  tests/_kit is the test kit that shipped with that release
534 passed, 0 failed, 534 total
Total: 0 warnings / 0 errors in 23 files

===== PanelMaster =====
  PASS  tests/_kit is the test kit that shipped with that release
609 passed, 0 failed, 609 total
Total: 0 warnings / 0 errors in 23 files

===== prettychat =====
  PASS  the parent page shows the TOC tagline
255 passed, 0 failed, 255 total
Total: 0 warnings / 0 errors in 17 files

===== WhatGroup =====
  PASS  debuglog: enable ack is colour-coded green/red matching the header (debug-logging-§5)
415 passed, 0 failed, 415 total
Total: 0 warnings / 0 errors in 14 files
```

**4,197 cases, 0 failed. 0 warnings / 0 errors in all nine repos.** No warning needed attributing to
adoption versus host hygiene.

Against the figures `docs/adoption-prompt.md:610-611` quotes as the additive-change proof:

| Consumer | Prompt says | Measured | Δ |
|---|---|---|---|
| AbsorbTracker | 467 | **469** | +2 |
| KickCD | 646 | **648** | +2 |
| ConsumableMaster | 559 | **561** | +2 |
| BankLedger | 685 | **687** | +2 |

The prompt names no figure at all for LootHistory (534), PanelMaster (609), prettychat (255) or
WhatGroup (415). See `03_DEVIATIONS.md` §3.

---

## §11 — Provenance and tag fidelity

```
$ for a in <all eight>; do test -f ../$a/libs/LibKa0s/LICENSE; grep -ihoE '[Bb]undles \[?LibKa0s\]?[^)]*\)? v[0-9.]+' ../$a/README.md; done

AbsorbTracker      LICENSE:yes  Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.5.0
BankLedger         LICENSE:yes  Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.5.0
ConsumableMaster   LICENSE:yes  Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.5.0
KickCD             LICENSE:yes  Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.5.0
LootHistory        LICENSE:yes  bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.5.0
PanelMaster        LICENSE:yes  Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.5.0
prettychat         LICENSE:yes  Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.5.0
WhatGroup          LICENSE:yes  bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.5.0
```

LootHistory's and WhatGroup's lowercase `bundles` is the mid-sentence phrasing; both were found only
because the pattern is `[Bb]undles`. See `03_DEVIATIONS.md` §6.

```
$ git tag | tail -5
v1.2.0
v1.3.0
v1.3.1
v1.4.0
v1.5.0

$ git describe --tags
v1.5.0

$ git log --oneline -1
4a33bad Record WhatGroup as a consumer; no adoption targets remain

$ git log --oneline -1 v1.5.0
4a33bad Record WhatGroup as a consumer; no adoption targets remain

$ git diff --stat v1.5.0 -- LibKa0s testkit
(no output)

$ grep -n -m1 '^## v' CHANGELOG.md
13:## v1.5.0 — 2026-08-02
```

The tag exists, resolves, points at HEAD, and the payload at that tag is byte-identical to what all
eight consumers vendor. **The 2026-08-01 v2 run's headline finding — four addons naming a release
that did not resolve to a ref — is closed.**

---

## §12 — Stale claims located, with line numbers

```
$ grep -rn '467\|646\|559\|685\|449' docs/adoption-prompt.md
610:   proves your "additive" change was additive. At the time of writing: **AbsorbTracker 467**,
611:   **KickCD 646**, **ConsumableMaster 559**, **BankLedger 685**, each 0 failed. If any of those moves
625:   you, and a stale figure here reads as a regression that is not one. (The 449 this line used to

$ grep -rn 'v1\.4\.0' docs/*.md
docs/adoption-prompt.md:458:    Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.4.0 (MIT).
docs/releasing.md:7:| Repo semver (`v1.4.0`) | git tag, `CHANGELOG.md` heading | humans | once per release |
docs/releasing.md:96:> Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.4.0 (MIT).
docs/releasing.md:98:The version in that template is **the one being released**, not a literal to copy — at v1.4.0 the
docs/releasing.md:99:line reads v1.4.0, and this template moves with it rather than being corrected after the fact.

$ grep -n 'Provisional surfaces\|One implementation behind them\|numeric-enum dropdown (OptionsWidgets minor 5)' docs/adoption-prompt.md
755:### Provisional surfaces — one consumer each, and treated as unsettled
764:- **`applySkin` / `makeCloseButton` (DebugLog minor 4).** One implementation behind them. The
779:- **The numeric-enum dropdown (OptionsWidgets minor 5).** The route is **inferred** from the presence
```

---

## §13 — What was not run

- No in-game verification of any kind. No `docs/smoke-tests.md` in any consumer was executed.
- No consumer's `docs/test-cases.md` or `[tests]` badge was checked against its suite total.
- No mutation verification of any consumer's guard cases was performed this run; guard presence and
  message text were read, not falsified.
- `WhoGotLoots` and `BuffTextNotifications` were confirmed to hold no vendored library and were
  otherwise not examined.
