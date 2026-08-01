# Evidence — 2026-08-01

Raw output. Every claim in `01`–`04` cites a section here. Commands were run from
`/mnt/d/Profile/Users/Tushar/Documents/GIT` (the parent of all repos) or from `LibKa0s/`, as noted.

---

## §1 — Scope: who has vendored the library

```
$ ls <repo>/libs   # for each sibling repo
AbsorbTracker    ... LibKa0s LibSharedMedia-3.0 LibStub
BankLedger       ... (no LibKa0s)
ConsumableMaster ... LibKa0s LibSharedMedia-3.0 LibStub
KickCD           ... LibKa0s LibSharedMedia-3.0 LibStub
LootHistory      ... (no LibKa0s)
PanelMaster      ... (no LibKa0s)
WhatGroup        ... (no LibKa0s)
prettychat       ... (no LibKa0s)
BuffTextNotifications  (no libs/ at all)
WhoGotLoots            (no libs/ at all)

$ ls <adopter>/libs/LibKa0s      # identical in all three
Core.lua DebugLog.lua LibKa0s.xml Options.lua OptionsScroll.lua
OptionsWidgets.lua Perf.lua PerfPanel.lua Slash.lua

$ ls <adopter>/tests/_kit        # identical in all three
README.md framework.lua loader.lua mock_base.lua
```

Filesystem matches `docs/releasing.md`'s Consumers table exactly.

---

## §2 — Version fidelity

```
$ grep -hoE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *= *("[^"]+", *)?[0-9]+' \
    LibKa0s/*.lua
local MAJOR, MINOR = "LibKa0s-Core-1.0", 2
local MAJOR, MINOR = "LibKa0s-DebugLog-1.0", 3
local MAJOR, MINOR = "LibKa0s-Options-1.0", 4
local SCROLL_MINOR = 2
local WIDGETS_MINOR = 4
local MAJOR, MINOR = "LibKa0s-Perf-1.0", 5
local PANEL_MINOR = 3
local MAJOR, MINOR = "LibKa0s-Slash-1.0", 4
```

The same command against each consumer's `libs/LibKa0s/*.lua` returns the identical eight values.
AbsorbTracker, KickCD and ConsumableMaster all match the ship folder, file for file.

Dependency floors:

```
$ grep -n "NEEDS_CORE" LibKa0s/*.lua
LibKa0s/DebugLog.lua:24:local NEEDS_CORE = 1
LibKa0s/DebugLog.lua:25:if not core or (core.MINOR or 0) < NEEDS_CORE then return end
LibKa0s/Options.lua:21:local NEEDS_CORE = 1
LibKa0s/Perf.lua:22:local NEEDS_CORE = 1
LibKa0s/Slash.lua:18:local NEEDS_CORE = 1
```

Core is at 2 everywhere, so every floor is satisfied and no major is silently absent.

---

## §3 — Byte fidelity and line endings

```
$ diff -rq LibKa0s/LibKa0s AbsorbTracker/libs/LibKa0s
(empty)
$ diff -rq LibKa0s/testkit AbsorbTracker/tests/_kit
(empty)

$ diff -rq LibKa0s/LibKa0s KickCD/libs/LibKa0s
(empty)
$ diff -rq LibKa0s/testkit KickCD/tests/_kit
(empty)

$ diff -rq LibKa0s/LibKa0s ConsumableMaster/libs/LibKa0s
Files LibKa0s/LibKa0s/Options.lua and ConsumableMaster/libs/LibKa0s/Options.lua differ
Files LibKa0s/LibKa0s/OptionsWidgets.lua and ConsumableMaster/libs/LibKa0s/OptionsWidgets.lua differ
Files LibKa0s/LibKa0s/Perf.lua and ConsumableMaster/libs/LibKa0s/Perf.lua differ
Files LibKa0s/LibKa0s/Slash.lua and ConsumableMaster/libs/LibKa0s/Slash.lua differ
$ diff -rq LibKa0s/testkit ConsumableMaster/tests/_kit
Files LibKa0s/testkit/mock_base.lua and ConsumableMaster/tests/_kit/mock_base.lua differ
```

Content-level, all three:

```
$ diff -rq --strip-trailing-cr LibKa0s/LibKa0s <adopter>/libs/LibKa0s
(empty)
$ diff -rq --strip-trailing-cr LibKa0s/testkit <adopter>/tests/_kit
(empty)
```

So: **no content differs anywhere.** The five ConsumableMaster differences are line endings only.

Which side is the anomaly:

```
$ file -b LibKa0s/LibKa0s/Options.lua
Unicode text, UTF-8 text
$ file -b AbsorbTracker/libs/LibKa0s/Options.lua
Unicode text, UTF-8 text
$ file -b KickCD/libs/LibKa0s/Options.lua
Unicode text, UTF-8 text
$ file -b ConsumableMaster/libs/LibKa0s/Options.lua
Unicode text, UTF-8 text, with CRLF line terminators
```

Full working-tree survey — CRLF unless marked:

| File | Ship | AbsTr | KickCD | ConsM |
|---|---|---|---|---|
| Core.lua | CRLF | CRLF | CRLF | CRLF |
| DebugLog.lua | CRLF | CRLF | CRLF | CRLF |
| LibKa0s.xml | CRLF | CRLF | CRLF | CRLF |
| Options.lua | **LF** | **LF** | **LF** | CRLF |
| OptionsScroll.lua | CRLF | CRLF | CRLF | CRLF |
| OptionsWidgets.lua | **LF** | **LF** | **LF** | CRLF |
| Perf.lua | **LF** | **LF** | **LF** | CRLF |
| PerfPanel.lua | CRLF | CRLF | CRLF | CRLF |
| Slash.lua | **LF** | **LF** | **LF** | CRLF |

What git actually stores (from `LibKa0s/`):

```
$ git cat-file -p HEAD:LibKa0s/Core.lua    | file -b -   → LF
$ git cat-file -p HEAD:LibKa0s/Options.lua | file -b -   → LF
$ git cat-file -p HEAD:LibKa0s/Slash.lua   | file -b -   → LF
$ git cat-file -p HEAD:LibKa0s/Perf.lua    | file -b -   → LF
$ git cat-file -p HEAD:LibKa0s/OptionsWidgets.lua | file -b - → LF
```

and from `ConsumableMaster/`:

```
$ git cat-file -p HEAD:libs/LibKa0s/Core.lua    | file -b -  → LF
$ git cat-file -p HEAD:libs/LibKa0s/Options.lua | file -b -  → LF
$ git cat-file -p HEAD:libs/LibKa0s/Slash.lua   | file -b -  → LF
```

All blobs LF on both sides. Both working trees clean:

```
$ git -C LibKa0s status --porcelain LibKa0s testkit    → (empty)
$ git -C AbsorbTracker status --porcelain              → (empty)
$ git -C KickCD status --porcelain                     → (empty)
$ git -C ConsumableMaster status --porcelain           → (empty)
```

Repo-wide scope — every tracked text file in `LibKa0s/`, checked:

```
$ for f in $(git ls-files '*.lua' '*.md' '*.xml' '*.toc'); do
      file -b "$f" | grep -q CRLF || echo "LF: $f"; done
LF: CHANGELOG.md
LF: LibKa0s/Options.lua
LF: LibKa0s/OptionsWidgets.lua
LF: LibKa0s/Perf.lua
LF: LibKa0s/Slash.lua
LF: README.md
LF: docs/adoption-prompt.md
LF: docs/record-schema.md
LF: docs/releasing.md
LF: testkit/mock_base.lua
LF: tests/_kit/mock_base.lua
LF: tests/fixture_options.lua
LF: tests/test_options.lua
LF: tests/test_options_widgets.lua
LF: tests/test_slash.lua
LF: tests/wow_mock.lua
---- 16 of 49 text files are LF in the working tree
```

Note `testkit/mock_base.lua` and `tests/_kit/mock_base.lua` are both LF — which is why
`tests/test_kitsync.lua`, a deliberately unnormalised byte comparison, is green.

`LibKa0s/.gitattributes` pins the policy the LF files violate:

```
* text=auto eol=crlf
*.lua  text eol=crlf
*.toc  text eol=crlf
*.xml  text eol=crlf
*.md   text eol=crlf
```

All four repos carry an equivalent `* text=auto eol=crlf`.

---

## §4 — Majors wired, per consumer

```
$ grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' <adopter> --include='*.lua' \
    | grep -v '/libs/' | grep -v '/tests/'
```

**AbsorbTracker**
```
core/PerfSetup.lua        → LibKa0s-Perf-1.0
core/CoreSetup.lua        → LibKa0s-Core-1.0
core/DebugLogSetup.lua    → LibKa0s-DebugLog-1.0
settings/Schema.lua       → LibKa0s-Slash-1.0
settings/Slash.lua        → LibKa0s-Slash-1.0
settings/OptionsSetup.lua → LibKa0s-Options-1.0
```

**KickCD**
```
core/PerfSetup.lua        → LibKa0s-Perf-1.0
core/DebugLogSetup.lua    → LibKa0s-DebugLog-1.0
core/CoreSetup.lua        → LibKa0s-Core-1.0
settings/OptionsSetup.lua → LibKa0s-Options-1.0
settings/Slash.lua        → LibKa0s-Slash-1.0
```

**ConsumableMaster**
```
core/CoreSetup.lua        → LibKa0s-Core-1.0
core/SlashCommands.lua    → LibKa0s-Slash-1.0
modules/DebugLog.lua      → LibKa0s-DebugLog-1.0
modules/PerfSetup.lua     → LibKa0s-Perf-1.0
settings/Panel.lua        → LibKa0s-Options-1.0
```

TOC wiring:

```
AbsorbTracker.toc:5:  ## Version: 1.9.0
AbsorbTracker.toc:7:  ## SavedVariables: AbsorbTrackerDB, AbsorbTrackerPerfDB
AbsorbTracker.toc:27: libs\LibKa0s\LibKa0s.xml
AbsorbTracker.toc:41: core\CoreSetup.lua
AbsorbTracker.toc:42: core\PerfSetup.lua
AbsorbTracker.toc:47: core\DebugLogSetup.lua
AbsorbTracker.toc:61: settings\OptionsSetup.lua

KickCD.toc:5:  ## Version: 1.2.1
KickCD.toc:7:  ## SavedVariables: KickCDDB, KickCDPerfDB
KickCD.toc:26: libs\LibKa0s\LibKa0s.xml
KickCD.toc:39: core\CoreSetup.lua
KickCD.toc:40: core\DebugLogSetup.lua
KickCD.toc:45: core\PerfSetup.lua
KickCD.toc:62: settings\OptionsSetup.lua

ConsumableMaster.toc:5:   ## Version: 1.5.0
ConsumableMaster.toc:11:  ## SavedVariables: ConsumableMasterDB, ConsumableMasterPerfDB
ConsumableMaster.toc:36:  libs\LibKa0s\LibKa0s.xml
ConsumableMaster.toc:55:  core\CoreSetup.lua
ConsumableMaster.toc:101: modules\PerfSetup.lua
```

---

## §5 — Adoption depth

Surface usage (files calling each, excluding `libs/` and `tests/`):

```
$ grep -rl '<surface>' <adopter> --include='*.lua' | grep -v libs | grep -v tests | wc -l

                 RenderGrid  RenderRows  LSMValues
AbsorbTracker         0           4          4
KickCD                0           3          5
ConsumableMaster      1           1          2
```

Schema-CLI verbs:

```
$ grep -rnoE "Cli(List|Get|Set|Reset)" <adopter> --include='*.lua' | grep -v libs | grep -v tests

AbsorbTracker    settings/Slash.lua:128 CliList
                 settings/Slash.lua:129 CliGet
                 settings/Slash.lua:130 CliSet
                 settings/Slash.lua:159 CliReset

KickCD           core/KickCD.lua:310    CliList
                 core/KickCD.lua:315    CliGet
                 core/KickCD.lua:320    CliSet
                 settings/Slash.lua:189 CliReset

ConsumableMaster core/SlashCommands.lua:1244  CliList, CliGet, CliSet
                 core/SlashCommands.lua:1323  CliList
                 core/SlashCommands.lua:1324  CliGet
                 core/SlashCommands.lua:1325  CliSet
                 (no CliReset)
```

`LandingRows` callers:

```
AbsorbTracker     settings/About.lua, settings/Slash.lua
KickCD            core/KickCD.lua, settings/Panel.lua, settings/Slash.lua
ConsumableMaster  (none)
```

ConsumableMaster's settings tree, showing there is no landing page to converge:

```
$ ls ConsumableMaster/settings/
Category.lua  General.lua  MacroBar.lua  Panel.lua  StatPriority.lua

$ grep -rn "COMMANDS\|slash" ConsumableMaster/settings/*.lua
(no matches)
```

It does take the chat-help formatter:

```
ConsumableMaster/tests/test_slashsetup.lua:57:  t.eq(KCM.SlashCommands.instance:HelpRows()[1],
ConsumableMaster/tests/test_slashsetup.lua:58:      "  " .. lib.FormatRow("/cm " .. first[1], first[2]),
ConsumableMaster/tests/test_slashsetup.lua:59:      "the first help row is lib.FormatRow's output, indented")
```

Host console files surviving:

```
AbsorbTracker     (none — deleted)
KickCD            (none — deleted)
ConsumableMaster  modules/DebugLog.lua, 208 lines (the seam itself)
```

Seam file line counts:

```
AbsorbTracker    core/CoreSetup.lua 78    core/DebugLogSetup.lua 110  core/PerfSetup.lua 130
                 settings/OptionsSetup.lua 199   settings/Slash.lua 471
KickCD           core/CoreSetup.lua 102   core/DebugLogSetup.lua 169  core/PerfSetup.lua 215
                 settings/OptionsSetup.lua 232   settings/Slash.lua 343   settings/Panel.lua 622
ConsumableMaster core/CoreSetup.lua 99    modules/DebugLog.lua 208    modules/PerfSetup.lua 103
                 settings/Panel.lua 920   core/SlashCommands.lua 1350
```

---

## §6 — The `L` trap

Every descriptor `L` in host code:

```
$ grep -rnE '(^|[,{[:space:]])L[[:space:]]*=' <adopter> --include='*.lua' \
    | grep -v '/libs/' | grep -v '/tests/' | grep -v 'local L'

AbsorbTracker     (no matches — omits L everywhere)
KickCD            settings/Slash.lua:331:    L = NS.L and {
ConsumableMaster  core/SlashCommands.lua:1289:        L = SLASH_STRINGS,
```

KickCD, `settings/Slash.lua:326-335` — a fresh table, one key:

```lua
    -- The library's strings are already byte-identical to this addon's for the
    -- list header, the group heading, the not-found line and the get usage. Only
    -- the ones that genuinely differ are overridden, and none is overridden just
    -- to avoid a convergence the standard asked for.
    L = NS.L and {
        LIST_HEADER = NS.L["Available settings"]
            and ("|cff33ff99" .. NS.L["Available settings"] .. "|r") or nil,
    } or nil,
```

ConsumableMaster, `core/SlashCommands.lua:1257-1269` — seven literals:

```lua
local SLASH_STRINGS = {
    HELP_HEADER     = "|cffffd100Ka0s Consumable Master|r v%s \226\128\148 slash commands",
    HELP_ALIAS      = " (alias: |cffffff00%s|r)",
    UNKNOWN_COMMAND = "Unknown command: |cffffff00%s|r",
    USAGE_GET       = "Usage: %s get <path>  (try %s list)",
    ERR_BOOL        = "expected true/false/on/off/1/0",
    ERR_ALLOWED     = "Allowed values: %s",
    ERR_COLOR       = "expected: r g b [a] (each 0-1 or 0-255)",
}
```

Neither is the addon's locale table. The trap is avoided in both.

The regression guard:

```
$ grep -rn 'A-Z0-9_' <adopter>/tests --include='*.lua' | grep -v '_kit'

AbsorbTracker     (no matches)
KickCD            tests/test_perfsetup.lua:375: assertNil(step.label:match("^[A-Z][A-Z0-9_]+$"),
                  tests/test_perfsetup.lua:450: assertNil(step.label:match("^[A-Z][A-Z0-9_]+$"),
ConsumableMaster  (no matches)
```

Coverage: 1 of 15 module-adoptions (KickCD / Perf).

---

## §7 — Convergence #1, `reset`

```
$ grep -rnE '"reset(all)?"' <adopter> --include='*.lua' | grep -v libs | grep -v tests

AbsorbTracker
  settings/Slash.lua:72:  {"reset",    "Reset one setting to its default \226\128\148 `/at reset <path>`",
  settings/Slash.lua:74:  {"resetall", "Reset every setting to defaults",

KickCD
  core/KickCD.lua:170:    {"reset",    "Reset one setting to its default — `/kcd reset <path>`",
  core/KickCD.lua:172:    {"resetall", "Reset every schema-driven panel AND every spec's spell list to defaults",
  core/KickCD.lua:661:    {"reset",    "Reset one spec to defaults — `... reset [CLASS SPEC]`",
  core/KickCD.lua:667:    {"resetall", "Rebuild EVERY spec's list from the defaults — `... resetall`",

ConsumableMaster
  core/SlashCommands.lua:740:  {"reset", "Clear added/blocked/pins for this cat — `/cm priority <cat> reset`",
  core/SlashCommands.lua:876:  {"reset", "Drop user override — `/cm stat reset [specKey]`",
  core/SlashCommands.lua:1032: {"reset", "Restore enabled + order to defaults — `/cm aio <key> reset`",
  core/SlashCommands.lua:1085: {"reset", "Move the bar back to the center of the screen",
```

KickCD's spell-database rebuild was re-homed under a subcommand group (`:661`, `:667`) rather than
lost — the prompt's stated risk did not materialise.

ConsumableMaster's top-level `reset`, `core/SlashCommands.lua:1199-1205`:

```lua
    {"reset",         "Reset all priority lists and stat overrides to defaults",
        function()
            if StaticPopup_Show then
                StaticPopup_Show("KCM_CONFIRM_RESET")
            else
                say("StaticPopup unavailable.")
            end
```

Still the confirm-gated global wipe. No `/cm reset <path>`, no `/cm resetall`.

Whether the decision is recorded:

```
$ grep -c -i "reset" ConsumableMaster/docs/pending/LEDGER.md
0
$ ls ConsumableMaster/CHANGELOG.md
ls: cannot access 'ConsumableMaster/CHANGELOG.md': No such file or directory
```

Zero. The ledger's seven LibKa0s entries (LIBKA0S-01 … -07) never mention it.

---

## §8 — Provenance

```
$ ls <adopter>/libs/LibKa0s
Core.lua DebugLog.lua LibKa0s.xml Options.lua OptionsScroll.lua
OptionsWidgets.lua Perf.lua PerfPanel.lua Slash.lua
                                              # no LICENSE, all three

$ grep -c -i "copyright" LibKa0s/*.lua LibKa0s/*.xml
LibKa0s/Core.lua:0            LibKa0s/DebugLog.lua:0        LibKa0s/Options.lua:0
LibKa0s/OptionsScroll.lua:0   LibKa0s/OptionsWidgets.lua:0  LibKa0s/Perf.lua:0
LibKa0s/PerfPanel.lua:0       LibKa0s/Slash.lua:0           LibKa0s/LibKa0s.xml:0

$ grep -o "\bMIT\b" LibKa0s/*.lua
(no matches)

$ head -3 LibKa0s/LICENSE          # the repo root licence
MIT License

Copyright (c) 2026 Ka0s

$ grep -ci libka0s <adopter>/README.md
AbsorbTracker 0    KickCD 0    ConsumableMaster 0

$ ls <adopter>/CHANGELOG.md
No such file or directory  (all three)
```

Each adopter's root, for completeness — none has a `CHANGELOG.md`:

```
AbsorbTracker     AbsorbTracker.toc CLAUDE.md LICENSE README.md core defaults docs libs locales media modules settings tests
KickCD            CLAUDE.md KickCD.toc LICENSE README.md core defaults docs libs locales media modules settings tests
ConsumableMaster  CLAUDE.md ConsumableMaster.toc LICENSE README.md core defaults docs libs locales media modules settings tests
```

Consumers' `.pkgmeta` correctly excludes the kit:

```
$ grep -n "ignore\|tests" AbsorbTracker/.pkgmeta
5:ignore:
7:  - tests
```

---

## §9 — Degradation stubs

```
$ grep -rn 'LIBKA0S_MISSING\|libka0sMissing' <adopter> --include='*.lua' \
    | grep -v libs | grep -v tests | wc -l

AbsorbTracker     6
KickCD            0
ConsumableMaster  5
```

KickCD degrades through its own idiom — `core/CoreSetup.lua:45-86`:

```
 45: if not lib then
 51:     -- So the fallbacks WORK — they are the pre-library implementations, kept
 55:     -- The guard is reproduced here even though the stub "must not re-implement
 60:     local function probeConcat(v) return table.concat({ v }) end
 63:         return (pcall(probeConcat, v))
 67:         if v == nil then return "nil" end
 68:         if type(v) == "boolean" then return tostring(v) end
 69:         if NS.IsConcatSafe(v) then return tostring(v) end
 70:         return "<secret>"
 75:         if not DEFAULT_CHAT_FRAME then return end
 76:         if not announced then
 80:             "(expected in libs/LibKa0s); running on reduced built-in fallbacks.")
 86:     return
```

and `settings/OptionsSetup.lua:137-180` documents why its stub needs less than AbsorbTracker's:

```
137: -- The degradation stub — LOAD-COMPLETING, not member-answering
151: -- MEASURED, not assumed (options-ui-§1 requires exactly that): this stub needs
153: -- consumer. AbsorbTracker takes LSMValues from the LIBRARY, so its stub must
157: -- load-time hole AbsorbTracker's stub exists to plug does not exist here.
169: if not lib then
```

AbsorbTracker's shared clause is recorded in its ledger:

```
AbsorbTracker/docs/pending/LEDGER.md:39
  PLAN-04 | fc0521e5 | docs/reviews/2026-07-31/01_FINDINGS.md (F-013) | done | 2026-07-31 |
  Implemented C-13 as designed: `NS.LIBKA0S_MISSING` in `core/CoreSetup.lua` is the single
  cause clause, and all five seams append their own "so <what> is unavailable".
```

---

## §10 — The green gate

Run in each repo root.

```
$ cd LibKa0s && lua tests/run.lua
  PASS  kitsync: testkit/ and tests/_kit/ hold the same set of files
  PASS  kitsync: every kit file is byte-identical in testkit/ and tests/_kit/, README included

382 passed, 0 failed, 382 total

$ luacheck .
Total: 0 warnings / 0 errors in 11 files
```

```
$ cd AbsorbTracker && lua tests/run.lua
  PASS  README.md carries no angle-bracket argument placeholders
  PASS  the addon's own files use US spellings

449 passed, 0 failed, 449 total

$ luacheck .
Total: 0 warnings / 0 errors in 28 files
```

```
$ cd KickCD && lua tests/run.lua
  PASS  --list Totals row equals the grand total of bullets

-------------------
629 passed, 0 failed

$ luacheck .
Total: 7 warnings / 0 errors in 32 files
```

```
$ cd ConsumableMaster && lua tests/run.lua
  PASS  Widgets: no two widgets claim the same type name
  PASS  Widgets: every widget name used by the settings pages is registered

  544 passed, 0 failed, 544 total

$ luacheck .
Total: 0 warnings / 0 errors in 50 files
```

KickCD's seven, attributed:

```
core/Database.lua:430:17:    (W213) unused loop variable 'i'
core/KickCD.lua:734:11:      (W431) shadowing upvalue 'p' on line 96
core/LSMPatch.lua:26:18:     (W211) unused variable 'NS'
modules/Cooldowns.lua:137:16:(W211) unused variable 'maxC'
modules/IconGrid.lua:855:42: (W212) unused argument 'payload'
settings/Profiles.lua:13:7:  (W211) unused variable 'Profiles'
settings/Spells.lua:506:33:  (W212) unused argument 'parent'
```

None in a seam file. `luacheck` reports `core/CoreSetup.lua`, `core/DebugLogSetup.lua`,
`core/PerfSetup.lua`, `settings/OptionsSetup.lua` and `settings/Slash.lua` as **OK**.

AbsorbTracker's 449 matches the figure `docs/adoption-prompt.md` quotes as its additive-change
proof, unchanged.

---

## §11 — Adoption records

```
$ grep -in "libka0s\|library" <adopter>/docs/pending/LEDGER.md

AbsorbTracker     2 entries — ISS-19 (perf extraction, done), PLAN-04 (shared cause clause, done)
KickCD            1 entry  — PLAN-01 (pruned libs/AceTimer-3.0/, done). Not adoption-specific.
ConsumableMaster  7 entries — LIBKA0S-01 … LIBKA0S-07, with superseded rows preserved
```

ConsumableMaster's ledger is the fullest record in the collection. Representative entries:

- **LIBKA0S-02** — the two upstream shape mismatches (positional colour, ordered-array enum), traced
  to `lib.FormatValue:92` and `allowedValues:135`, fixed in Slash minor 4 / OptionsWidgets minor 3
  and re-vendored.
- **LIBKA0S-04** — the widget makers, with all three original blockers and the fourth
  (`row.desc` vs `tooltip`) the ledger notes it never recorded. ~160 lines out.
- **LIBKA0S-06** — the tail, naming why `RenderGrid` and the non-empty `LSMValues` had to exist
  before `Helpers.Grid` and `Helpers.LSMValues` could go.
- **LIBKA0S-07** — `RenderRows` not pcall'ing each row, fixed in OptionsWidgets minor 4 and
  re-vendored to all three consumers.

Two accepted user-visible differences it records, both from LIBKA0S-05:

> a failing renderer reports as "settings page '<key>' failed to render" rather than "panel render
> failed", and the **sidebar** combat notice is the library's `|cffaaaaaa` while `/cm config` keeps
> this addon's `|cff808080` (`Options.lua` has no `L` seam).
