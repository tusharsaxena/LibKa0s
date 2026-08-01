# Evidence — 2026-08-01 (run v2)

Raw output. Every claim in `01`–`04` cites a section here.

This is the **second** adoption audit of 2026-08-01. It was taken after the v1.2.0 minor bumps
(DebugLog 4, Slash 5, Options 5, OptionsWidgets 5) and after BankLedger's adoption made it the
fourth consumer. The earlier run of the same day is at
`/mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s/docs/adoption/2026-08-01/`; every one of its
findings referenced below was re-verified from scratch here rather than inherited.

Commands were run from one of five working directories, and every block names its own:

| Label | Directory |
|---|---|
| LIB | `/mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s` |
| AT | `/mnt/d/Profile/Users/Tushar/Documents/GIT/AbsorbTracker` |
| BL | `/mnt/d/Profile/Users/Tushar/Documents/GIT/BankLedger` |
| CM | `/mnt/d/Profile/Users/Tushar/Documents/GIT/ConsumableMaster` |
| KCD | `/mnt/d/Profile/Users/Tushar/Documents/GIT/KickCD` |
| GIT | `/mnt/d/Profile/Users/Tushar/Documents/GIT` (the parent of all repos) |

The collectors' unedited files are preserved under `_raw/` in this same folder:
`consumer-AbsorbTracker.md`, `consumer-BankLedger.md`, `consumer-ConsumableMaster.md`,
`consumer-KickCD.md`, `ship.md` and `cross.md`. Where a step produced no output for a given repo,
that is stated rather than left as a gap.

---

## §1 — Scope: who has vendored the library

cwd=LIB

```
$ ls -d ../*/libs/LibKa0s 2>/dev/null
../AbsorbTracker/libs/LibKa0s
../BankLedger/libs/LibKa0s
../ConsumableMaster/libs/LibKa0s
../KickCD/libs/LibKa0s
```

cwd=LIB

```
$ ls -d /mnt/d/Profile/Users/Tushar/Documents/GIT/*/tests/_kit
.../AbsorbTracker/tests/_kit
.../BankLedger/tests/_kit
.../ConsumableMaster/tests/_kit
.../KickCD/tests/_kit
.../LibKa0s/tests/_kit
```

cwd=GIT — the named remaining targets, checked rather than assumed:

```
$ ls -d AbsorbTracker/libs/LibKa0s BankLedger/libs/LibKa0s ConsumableMaster/libs/LibKa0s KickCD/libs/LibKa0s LootHistory/libs/LibKa0s PanelMaster/libs/LibKa0s prettychat/libs/LibKa0s WhatGroup/libs/LibKa0s 2>&1
ls: cannot access 'LootHistory/libs/LibKa0s': No such file or directory
ls: cannot access 'PanelMaster/libs/LibKa0s': No such file or directory
ls: cannot access 'prettychat/libs/LibKa0s': No such file or directory
ls: cannot access 'WhatGroup/libs/LibKa0s': No such file or directory
AbsorbTracker/libs/LibKa0s
BankLedger/libs/LibKa0s
ConsumableMaster/libs/LibKa0s
KickCD/libs/LibKa0s
```

Four consumer repos on disk. `docs/releasing.md`'s Consumers table names exactly those four, so
there is no unrecorded adoption and no recorded-but-absent one. BankLedger is new since the
2026-08-01 run, whose own evidence file recorded `BankLedger ... (no LibKa0s)`.

Payload inventory, identical in all four (cwd=AT / KCD / CM / BL, `ls libs/LibKa0s/`):

```
Core.lua  DebugLog.lua  LICENSE  LibKa0s.xml  Options.lua  OptionsScroll.lua
OptionsWidgets.lua  Perf.lua  PerfPanel.lua  Slash.lua
```

Kit inventory, identical in all four (`ls tests/_kit/`):

```
README.md  framework.lua  loader.lua  mock_base.lua
```

---

## §2 — Version fidelity

### §2.1 Ship folder — the authority for this run

cwd=LIB

```
$ grep -hoE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *= *("[^"]+", *)?[0-9]+' LibKa0s/*.lua
local MAJOR, MINOR = "LibKa0s-Core-1.0", 2
local MAJOR, MINOR = "LibKa0s-DebugLog-1.0", 4
local MAJOR, MINOR = "LibKa0s-Options-1.0", 5
local SCROLL_MINOR = 2
local WIDGETS_MINOR = 5
local MAJOR, MINOR = "LibKa0s-Perf-1.0", 5
local PANEL_MINOR = 3
local MAJOR, MINOR = "LibKa0s-Slash-1.0", 5

$ grep -nE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *= *' LibKa0s/*.lua
LibKa0s/Core.lua:18:local MAJOR, MINOR = "LibKa0s-Core-1.0", 2
LibKa0s/DebugLog.lua:27:local MAJOR, MINOR = "LibKa0s-DebugLog-1.0", 4
LibKa0s/Options.lua:24:local MAJOR, MINOR = "LibKa0s-Options-1.0", 5
LibKa0s/OptionsScroll.lua:18:local SCROLL_MINOR = 2
LibKa0s/OptionsWidgets.lua:15:local WIDGETS_MINOR = 5
LibKa0s/Perf.lua:25:local MAJOR, MINOR = "LibKa0s-Perf-1.0", 5
LibKa0s/PerfPanel.lua:13:local PANEL_MINOR = 3
LibKa0s/Slash.lua:21:local MAJOR, MINOR = "LibKa0s-Slash-1.0", 5
```

Dependency floors — no floor was raised for v1.2.0, so no consumer can silently lose a module:

```
$ grep -nE 'NEEDS_CORE' LibKa0s/*.lua
LibKa0s/DebugLog.lua:24:local NEEDS_CORE = 1
LibKa0s/DebugLog.lua:25:if not core or (core.MINOR or 0) < NEEDS_CORE then return end   -- no NewLibrary; module absent
LibKa0s/Options.lua:21:local NEEDS_CORE = 1
LibKa0s/Options.lua:22:if not core or (core.MINOR or 0) < NEEDS_CORE then return end   -- no NewLibrary; module absent
LibKa0s/OptionsWidgets.lua:73:-- either being wrong alone — but hoisting would raise NEEDS_CORE in two majors, and
LibKa0s/Perf.lua:22:local NEEDS_CORE = 1
LibKa0s/Perf.lua:23:if not core or (core.MINOR or 0) < NEEDS_CORE then return end   -- no NewLibrary; module absent
LibKa0s/Slash.lua:18:local NEEDS_CORE = 1
LibKa0s/Slash.lua:19:if not core or (core.MINOR or 0) < NEEDS_CORE then return end   -- no NewLibrary; module absent
LibKa0s/Slash.lua:155:-- either being wrong alone — but hoisting would raise NEEDS_CORE in two majors, and
```

The CHANGELOG's v1.2.0 version block agrees with the constants file for file
(cwd=LIB, `CHANGELOG.md:21-23`):

```
Versions in this release: **Core minor 2**, **DebugLog minor 4**, **Slash minor 5**,
**Options minor 5**, **OptionsWidgets minor 5**, **OptionsScroll minor 2**,
**Perf minor 5**, **PerfPanel minor 3**.
```

### §2.2 AbsorbTracker's vendored minors

cwd=AT

```
$ grep -HnoE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *= *("[^"]+", *)?[0-9]+' libs/LibKa0s/*.lua
libs/LibKa0s/Core.lua:18:local MAJOR, MINOR = "LibKa0s-Core-1.0", 2
libs/LibKa0s/DebugLog.lua:27:local MAJOR, MINOR = "LibKa0s-DebugLog-1.0", 4
libs/LibKa0s/Options.lua:24:local MAJOR, MINOR = "LibKa0s-Options-1.0", 5
libs/LibKa0s/OptionsScroll.lua:18:local SCROLL_MINOR = 2
libs/LibKa0s/OptionsWidgets.lua:15:local WIDGETS_MINOR = 5
libs/LibKa0s/Perf.lua:25:local MAJOR, MINOR = "LibKa0s-Perf-1.0", 5
libs/LibKa0s/PerfPanel.lua:13:local PANEL_MINOR = 3
libs/LibKa0s/Slash.lua:21:local MAJOR, MINOR = "LibKa0s-Slash-1.0", 5
```

The re-vendor is legible in history as four separate commits, and the tree is clean:

```
$ git log --oneline -8
fab8fa4 docs: resync the tests badge and the NS.MSG catalog
39620b4 chore(libs): re-vendor LibKa0s (Options minor 5)
6d32bd4 chore(libs): re-vendor LibKa0s (OptionsWidgets minor 5)
87eda52 chore(libs): re-vendor LibKa0s (Slash minor 5)
ebaad1e chore(libs): re-vendor LibKa0s v1.2.0 (DebugLog minor 4)
a242c81 docs: the header is RenderGrid's now, and testing.md was three suites short
bf45bb2 Smoke-test the RenderGrid header and the L trap
d199866 Match the L-trap guard on what the expression evaluates to

$ git status --porcelain
(no output — clean)
```

### §2.3 KickCD's vendored minors

cwd=KCD

```
$ for f in libs/LibKa0s/*.lua; do echo "--- $f"; grep -nE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *=' "$f" | head -3; done
--- libs/LibKa0s/Core.lua
18:local MAJOR, MINOR = "LibKa0s-Core-1.0", 2
--- libs/LibKa0s/DebugLog.lua
27:local MAJOR, MINOR = "LibKa0s-DebugLog-1.0", 4
--- libs/LibKa0s/Options.lua
24:local MAJOR, MINOR = "LibKa0s-Options-1.0", 5
--- libs/LibKa0s/OptionsScroll.lua
18:local SCROLL_MINOR = 2
--- libs/LibKa0s/OptionsWidgets.lua
15:local WIDGETS_MINOR = 5
--- libs/LibKa0s/Perf.lua
25:local MAJOR, MINOR = "LibKa0s-Perf-1.0", 5
--- libs/LibKa0s/PerfPanel.lua
13:local PANEL_MINOR = 3
--- libs/LibKa0s/Slash.lua
21:local MAJOR, MINOR = "LibKa0s-Slash-1.0", 5

$ git log --oneline -8
8e18897 docs: record the numeric-enum widget rule (OptionsWidgets minor 5)
435ec6d chore(libs): re-vendor LibKa0s (Options minor 5)
040cddb chore(libs): re-vendor LibKa0s (OptionsWidgets minor 5)
d24ebe1 chore(libs): re-vendor LibKa0s (Slash minor 5)
1ae16b6 chore(libs): re-vendor LibKa0s v1.2.0 (DebugLog minor 4)
4dc778a docs: the shared cause clause, and a vendor gate that was still one diff
53c8884 Add the LibKa0s seam smoke test this repo never had
cb75d38 Guard the L trap against the and/or spelling, which is the one this repo risks

$ git status --porcelain
(end)
```

### §2.4 ConsumableMaster's vendored minors

cwd=CM

```
$ grep -noE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *= *("[^"]+", *)?[0-9]+' libs/LibKa0s/*.lua
libs/LibKa0s/Core.lua:18:local MAJOR, MINOR = "LibKa0s-Core-1.0", 2
libs/LibKa0s/DebugLog.lua:27:local MAJOR, MINOR = "LibKa0s-DebugLog-1.0", 4
libs/LibKa0s/Options.lua:24:local MAJOR, MINOR = "LibKa0s-Options-1.0", 5
libs/LibKa0s/OptionsScroll.lua:18:local SCROLL_MINOR = 2
libs/LibKa0s/OptionsWidgets.lua:15:local WIDGETS_MINOR = 5
libs/LibKa0s/Perf.lua:25:local MAJOR, MINOR = "LibKa0s-Perf-1.0", 5
libs/LibKa0s/PerfPanel.lua:13:local PANEL_MINOR = 3
libs/LibKa0s/Slash.lua:21:local MAJOR, MINOR = "LibKa0s-Slash-1.0", 5

$ git status --porcelain
(no output — working tree clean)

$ git log --oneline -12
be52e56 docs: fix an un-runnable command in the smoke-test playbook
1a40448 chore(libs): re-vendor LibKa0s (Options minor 5)
9d340f5 chore(libs): re-vendor LibKa0s (OptionsWidgets minor 5)
e592a04 chore(libs): re-vendor LibKa0s (Slash minor 5)
9754b9e chore(libs): re-vendor LibKa0s v1.2.0 (DebugLog minor 4)
867de63 docs: move the badge the two new cases left behind, and write down the vendor gate
6912ce8 Cover the resetall popup on the slash path, and the L trap
46f07c6 Cover the last bare L-trap cell, honestly
505a15f /cm reset takes a path; the global wipe moves to /cm resetall
7cd37bf Pin the L trap in every major that renders its own strings
84fd9c8 Write the test inventory CRLF, the way .gitattributes says
365478a Re-vendor LibKa0s v1.1.0 — the licence arrives with the copy
```

### §2.5 BankLedger's vendored minors

cwd=LIB

```
$ grep -noE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *= *("[^"]+", *)?[0-9]+' ../BankLedger/libs/LibKa0s/*.lua
../BankLedger/libs/LibKa0s/Core.lua:18:local MAJOR, MINOR = "LibKa0s-Core-1.0", 2
../BankLedger/libs/LibKa0s/DebugLog.lua:27:local MAJOR, MINOR = "LibKa0s-DebugLog-1.0", 4
../BankLedger/libs/LibKa0s/Options.lua:24:local MAJOR, MINOR = "LibKa0s-Options-1.0", 5
../BankLedger/libs/LibKa0s/OptionsScroll.lua:18:local SCROLL_MINOR = 2
../BankLedger/libs/LibKa0s/OptionsWidgets.lua:15:local WIDGETS_MINOR = 5
../BankLedger/libs/LibKa0s/Perf.lua:25:local MAJOR, MINOR = "LibKa0s-Perf-1.0", 5
../BankLedger/libs/LibKa0s/PerfPanel.lua:13:local PANEL_MINOR = 3
../BankLedger/libs/LibKa0s/Slash.lua:21:local MAJOR, MINOR = "LibKa0s-Slash-1.0", 5
```

cwd=BL

```
$ git status --porcelain
(no output)

$ git log -5 --oneline
cde66ff Adopt LibKa0s: Core, DebugLog, Slash and Options
b68f429 docs: resync agent-context and ARCHITECTURE to the adopted code
c51fa46 refactor(options): take the canvas contract from the library (LIBKA0S-19)
4c66a89 feat(options): adopt LibKa0s-Options-1.0 for the settings-panel shell
65eb93f docs(ledger): record the Perf decline and the Options state
```

Note the shape of BankLedger's history differs from the other three: its adoption landed whole
rather than as four re-vendor commits, because it vendored for the first time at v1.2.0.

### §2.6 The skew table

Ship against each consumer, file by file:

| File | Constant | Ship | AbsorbTracker | KickCD | ConsumableMaster | BankLedger |
|---|---|---:|---:|---:|---:|---:|
| `Core.lua` | `MINOR` | 2 | 2 | 2 | 2 | 2 |
| `DebugLog.lua` | `MINOR` | 4 | 4 | 4 | 4 | 4 |
| `Slash.lua` | `MINOR` | 5 | 5 | 5 | 5 | 5 |
| `Options.lua` | `MINOR` | 5 | 5 | 5 | 5 | 5 |
| `OptionsWidgets.lua` | `WIDGETS_MINOR` | 5 | 5 | 5 | 5 | 5 |
| `OptionsScroll.lua` | `SCROLL_MINOR` | 2 | 2 | 2 | 2 | 2 |
| `Perf.lua` | `MINOR` | 5 | 5 | 5 | 5 | 5 |
| `PerfPanel.lua` | `PANEL_MINOR` | 3 | 3 | 3 | 3 | 3 |

Thirty-two of thirty-two current. **Zero cross-major skew anywhere in the collection**, which is
the central question this run exists to answer.

---

## §3 — Byte fidelity and line endings, per consumer

### §3.1 All sixteen diffs, run from the ship side

cwd=LIB

```
$ for a in AbsorbTracker KickCD ConsumableMaster BankLedger; do
    diff -rq --strip-trailing-cr LibKa0s ../$a/libs/LibKa0s; echo "exit=$?"
    diff -rq                     LibKa0s ../$a/libs/LibKa0s; echo "exit=$?"
    diff -rq --strip-trailing-cr testkit ../$a/tests/_kit;   echo "exit=$?"
    diff -rq                     testkit ../$a/tests/_kit;   echo "exit=$?"
  done

===== AbsorbTracker =====
-- content (strip-cr) --   (no output)  exit=0
-- bytes --                (no output)  exit=0
-- kit content --          (no output)  exit=0
-- kit bytes --            (no output)  exit=0
===== KickCD =====
-- content (strip-cr) --   (no output)  exit=0
-- bytes --                (no output)  exit=0
-- kit content --          (no output)  exit=0
-- kit bytes --            (no output)  exit=0
===== ConsumableMaster =====
-- content (strip-cr) --   (no output)  exit=0
-- bytes --                (no output)  exit=0
-- kit content --          (no output)  exit=0
-- kit bytes --            (no output)  exit=0
===== BankLedger =====
-- content (strip-cr) --   (no output)  exit=0
-- bytes --                (no output)  exit=0
-- kit content --          (no output)  exit=0
-- kit bytes --            (no output)  exit=0
```

The cross-cutting collector ran the `libs/` half of the same sixteen independently, one command per
line, and got the same answer (cwd=GIT):

```
$ diff -rq LibKa0s/LibKa0s AbsorbTracker/libs/LibKa0s; echo "exit=$?"
exit=0
$ diff -rq --strip-trailing-cr LibKa0s/LibKa0s AbsorbTracker/libs/LibKa0s; echo "exit=$?"
exit=0
$ diff -rq LibKa0s/LibKa0s BankLedger/libs/LibKa0s; echo "exit=$?"
exit=0
$ diff -rq --strip-trailing-cr LibKa0s/LibKa0s BankLedger/libs/LibKa0s; echo "exit=$?"
exit=0
$ diff -rq LibKa0s/LibKa0s ConsumableMaster/libs/LibKa0s; echo "exit=$?"
exit=0
$ diff -rq --strip-trailing-cr LibKa0s/LibKa0s ConsumableMaster/libs/LibKa0s; echo "exit=$?"
exit=0
$ diff -rq LibKa0s/LibKa0s KickCD/libs/LibKa0s; echo "exit=$?"
exit=0
$ diff -rq --strip-trailing-cr LibKa0s/LibKa0s KickCD/libs/LibKa0s; echo "exit=$?"
exit=0
```

**Sixteen diffs, all empty.** There is no fork and no line-ending divergence anywhere, so the
"which side is the anomaly" branch never fires. The characterisation below is recorded anyway, so
the next run has a baseline and cannot mistake a future CR-only difference for drift.

### §3.2 AbsorbTracker — line-ending characterisation

cwd=LIB

```
-- Core.lua --
ship worktree: JavaScript source, Unicode text, UTF-8 text, with CRLF line terminators
ship git blob : JavaScript source, Unicode text, UTF-8 text
AT worktree  : JavaScript source, Unicode text, UTF-8 text, with CRLF line terminators
-- Slash.lua --
ship worktree: Unicode text, UTF-8 text, with CRLF line terminators
ship git blob : Unicode text, UTF-8 text
AT worktree  : Unicode text, UTF-8 text, with CRLF line terminators
-- Options.lua --
ship worktree: Unicode text, UTF-8 text, with CRLF line terminators
ship git blob : Unicode text, UTF-8 text
AT worktree  : Unicode text, UTF-8 text, with CRLF line terminators
-- AT git blob --
AT git blob Core.lua: JavaScript source, Unicode text, UTF-8 text
AT git blob Slash.lua: Unicode text, UTF-8 text
AT git blob Options.lua: Unicode text, UTF-8 text
-- kit --
ship testkit/mock_base.lua: Unicode text, UTF-8 text, with CRLF line terminators
AT tests/_kit/mock_base.lua: Unicode text, UTF-8 text, with CRLF line terminators
```

Commands, for reproduction:

```
file -b LibKa0s/<f>
git cat-file -p HEAD:LibKa0s/<f> | file -b -
file -b ../AbsorbTracker/libs/LibKa0s/<f>
(cd ../AbsorbTracker && git cat-file -p HEAD:libs/LibKa0s/<f> | file -b -)
```

Both working trees CRLF, both blobs LF. That is precisely what `* text=auto eol=crlf` over LF blobs
should produce. It is a **change** from the 2026-08-01 run, which recorded AbsorbTracker and the
ship folder as LF working trees with ConsumableMaster the CRLF outlier; both have converged on CRLF
and the diffs are empty either way, so the change is not itself a finding. Only three of the eight
files were characterised on this consumer — the collector did not sweep the whole payload here, as
it did for KickCD and BankLedger.

### §3.3 KickCD — line-ending characterisation, whole payload

cwd=LIB

```
$ for f in LibKa0s/*; do printf '%s: ' "$f"; file -b "$f"; done
LibKa0s/Core.lua: JavaScript source, Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/DebugLog.lua: Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/LICENSE: ASCII text, with CRLF line terminators
LibKa0s/LibKa0s.xml: HTML document, ASCII text, with CRLF line terminators
LibKa0s/Options.lua: Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/OptionsScroll.lua: Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/OptionsWidgets.lua: Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/Perf.lua: Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/PerfPanel.lua: Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/Slash.lua: Unicode text, UTF-8 text, with CRLF line terminators

$ for f in ../KickCD/libs/LibKa0s/*; do printf '%s: ' "$f"; file -b "$f"; done
../KickCD/libs/LibKa0s/Core.lua: JavaScript source, Unicode text, UTF-8 text, with CRLF line terminators
../KickCD/libs/LibKa0s/DebugLog.lua: Unicode text, UTF-8 text, with CRLF line terminators
../KickCD/libs/LibKa0s/LICENSE: ASCII text, with CRLF line terminators
../KickCD/libs/LibKa0s/LibKa0s.xml: HTML document, ASCII text, with CRLF line terminators
../KickCD/libs/LibKa0s/Options.lua: Unicode text, UTF-8 text, with CRLF line terminators
../KickCD/libs/LibKa0s/OptionsScroll.lua: Unicode text, UTF-8 text, with CRLF line terminators
../KickCD/libs/LibKa0s/OptionsWidgets.lua: Unicode text, UTF-8 text, with CRLF line terminators
../KickCD/libs/LibKa0s/Perf.lua: Unicode text, UTF-8 text, with CRLF line terminators
../KickCD/libs/LibKa0s/PerfPanel.lua: Unicode text, UTF-8 text, with CRLF line terminators
../KickCD/libs/LibKa0s/Slash.lua: Unicode text, UTF-8 text, with CRLF line terminators

$ for f in Core.lua DebugLog.lua Slash.lua Options.lua OptionsWidgets.lua OptionsScroll.lua Perf.lua PerfPanel.lua LibKa0s.xml LICENSE; do printf 'LibKa0s/%s: ' "$f"; git cat-file -p HEAD:LibKa0s/$f | file -b -; done
LibKa0s/Core.lua: JavaScript source, Unicode text, UTF-8 text
LibKa0s/DebugLog.lua: Unicode text, UTF-8 text
LibKa0s/Slash.lua: Unicode text, UTF-8 text
LibKa0s/Options.lua: Unicode text, UTF-8 text
LibKa0s/OptionsWidgets.lua: Unicode text, UTF-8 text
LibKa0s/OptionsScroll.lua: Unicode text, UTF-8 text
LibKa0s/Perf.lua: Unicode text, UTF-8 text
LibKa0s/PerfPanel.lua: Unicode text, UTF-8 text
LibKa0s/LibKa0s.xml: HTML document, ASCII text
LibKa0s/LICENSE: ASCII text
```

cwd=KCD

```
$ for f in Core.lua DebugLog.lua Slash.lua Options.lua OptionsWidgets.lua OptionsScroll.lua Perf.lua PerfPanel.lua LibKa0s.xml LICENSE; do printf 'libs/LibKa0s/%s: ' "$f"; git cat-file -p HEAD:libs/LibKa0s/$f | file -b -; done
libs/LibKa0s/Core.lua: JavaScript source, Unicode text, UTF-8 text
libs/LibKa0s/DebugLog.lua: Unicode text, UTF-8 text
libs/LibKa0s/Slash.lua: Unicode text, UTF-8 text
libs/LibKa0s/Options.lua: Unicode text, UTF-8 text
libs/LibKa0s/OptionsWidgets.lua: Unicode text, UTF-8 text
libs/LibKa0s/OptionsScroll.lua: Unicode text, UTF-8 text
libs/LibKa0s/Perf.lua: Unicode text, UTF-8 text
libs/LibKa0s/PerfPanel.lua: Unicode text, UTF-8 text
libs/LibKa0s/LibKa0s.xml: HTML document, ASCII text
libs/LibKa0s/LICENSE: ASCII text
```

This closes the 2026-08-01 run's `03_DEVIATIONS.md §1` as it affects KickCD: that run found the
ship folder holding four LF files (`Options.lua`, `OptionsWidgets.lua`, `Perf.lua`, `Slash.lua`)
with KickCD holding LF copies of them, so the byte gate inverted. Both sides are now CRLF.

### §3.4 ConsumableMaster — line-ending characterisation, whole payload

cwd=LIB

```
$ for f in Core DebugLog Options OptionsScroll OptionsWidgets Perf PerfPanel Slash; do
    printf 'ship  %-16s %s\n' "$f.lua" "$(file -b LibKa0s/$f.lua)"
    printf 'vend  %-16s %s\n' "$f.lua" "$(file -b ../ConsumableMaster/libs/LibKa0s/$f.lua)"
  done
ship  Core.lua         JavaScript source, Unicode text, UTF-8 text, with CRLF line terminators
vend  Core.lua         JavaScript source, Unicode text, UTF-8 text, with CRLF line terminators
ship  DebugLog.lua     Unicode text, UTF-8 text, with CRLF line terminators
vend  DebugLog.lua     Unicode text, UTF-8 text, with CRLF line terminators
ship  Options.lua      Unicode text, UTF-8 text, with CRLF line terminators
vend  Options.lua      Unicode text, UTF-8 text, with CRLF line terminators
ship  OptionsScroll.lua Unicode text, UTF-8 text, with CRLF line terminators
vend  OptionsScroll.lua Unicode text, UTF-8 text, with CRLF line terminators
ship  OptionsWidgets.lua Unicode text, UTF-8 text, with CRLF line terminators
vend  OptionsWidgets.lua Unicode text, UTF-8 text, with CRLF line terminators
ship  Perf.lua         Unicode text, UTF-8 text, with CRLF line terminators
vend  Perf.lua         Unicode text, UTF-8 text, with CRLF line terminators
ship  PerfPanel.lua    Unicode text, UTF-8 text, with CRLF line terminators
vend  PerfPanel.lua    Unicode text, UTF-8 text, with CRLF line terminators
ship  Slash.lua        Unicode text, UTF-8 text, with CRLF line terminators
vend  Slash.lua        Unicode text, UTF-8 text, with CRLF line terminators

ship  LibKa0s.xml      HTML document, ASCII text, with CRLF line terminators
vend  LibKa0s.xml      HTML document, ASCII text, with CRLF line terminators
ship  LICENSE          ASCII text, with CRLF line terminators
vend  LICENSE          ASCII text, with CRLF line terminators

$ git cat-file -p HEAD:LibKa0s/Core.lua | file -b -
JavaScript source, Unicode text, UTF-8 text
```

cwd=CM

```
$ git cat-file -p HEAD:libs/LibKa0s/Core.lua | file -b -
JavaScript source, Unicode text, UTF-8 text
$ git cat-file -p HEAD:libs/LibKa0s/Options.lua | file -b -
Unicode text, UTF-8 text
```

ConsumableMaster was the one consumer the 2026-08-01 run identified as already correct on line
endings, and it still is. `file` calling `Core.lua` "JavaScript source" is its own heuristic and
says the same thing on both sides of every comparison; it is not a difference.

### §3.5 BankLedger — line-ending characterisation, and the `.gitattributes` that explains it

cwd=LIB

```
$ for f in LibKa0s/*.lua LibKa0s/*.xml LibKa0s/LICENSE; do printf '%-34s %s\n' "$f" "$(file -b "$f")"; done
LibKa0s/Core.lua                   JavaScript source, Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/DebugLog.lua               Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/Options.lua                Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/OptionsScroll.lua          Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/OptionsWidgets.lua         Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/Perf.lua                   Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/PerfPanel.lua              Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/Slash.lua                  Unicode text, UTF-8 text, with CRLF line terminators
LibKa0s/LibKa0s.xml                HTML document, ASCII text, with CRLF line terminators
LibKa0s/LICENSE                    ASCII text, with CRLF line terminators

$ for f in ../BankLedger/libs/LibKa0s/*; do printf '%-52s %s\n' "$f" "$(file -b "$f")"; done
../BankLedger/libs/LibKa0s/Core.lua                  JavaScript source, Unicode text, UTF-8 text, with CRLF line terminators
../BankLedger/libs/LibKa0s/DebugLog.lua              Unicode text, UTF-8 text, with CRLF line terminators
../BankLedger/libs/LibKa0s/LICENSE                   ASCII text, with CRLF line terminators
../BankLedger/libs/LibKa0s/LibKa0s.xml               HTML document, ASCII text, with CRLF line terminators
../BankLedger/libs/LibKa0s/Options.lua               Unicode text, UTF-8 text, with CRLF line terminators
../BankLedger/libs/LibKa0s/OptionsScroll.lua         Unicode text, UTF-8 text, with CRLF line terminators
../BankLedger/libs/LibKa0s/OptionsWidgets.lua        Unicode text, UTF-8 text, with CRLF line terminators
../BankLedger/libs/LibKa0s/Perf.lua                  Unicode text, UTF-8 text, with CRLF line terminators
../BankLedger/libs/LibKa0s/PerfPanel.lua             Unicode text, UTF-8 text, with CRLF line terminators
../BankLedger/libs/LibKa0s/Slash.lua                 Unicode text, UTF-8 text, with CRLF line terminators

$ for f in LibKa0s/Core.lua LibKa0s/Slash.lua LibKa0s/Options.lua; do printf '%-26s %s\n' "$f" "$(git cat-file -p HEAD:$f | file -b -)"; done
LibKa0s/Core.lua           JavaScript source, Unicode text, UTF-8 text
LibKa0s/Slash.lua          Unicode text, UTF-8 text
LibKa0s/Options.lua        Unicode text, UTF-8 text
```

cwd=BL

```
$ for f in libs/LibKa0s/Core.lua libs/LibKa0s/Slash.lua libs/LibKa0s/Options.lua; do printf '%-30s %s\n' "$f" "$(git cat-file -p HEAD:$f | file -b -)"; done
libs/LibKa0s/Core.lua          JavaScript source, Unicode text, UTF-8 text
libs/LibKa0s/Slash.lua         Unicode text, UTF-8 text
libs/LibKa0s/Options.lua       Unicode text, UTF-8 text

$ cat .gitattributes | head -9
# Force every text file to land on disk with CRLF line endings, regardless
# of each contributor's `core.autocrlf` / `core.eol` settings. WoW expects
# CRLF in addon source files, and contributors on Linux/macOS would
# otherwise check out LF.
#
# `text=auto` lets Git auto-detect text vs binary on first add; `eol=crlf`
# pins the working-tree line ending for everything classified as text.
* text=auto eol=crlf

$ git ls-files .gitattributes
.gitattributes

$ git log --oneline -- .gitattributes
9325663 chore(repo): pin CRLF line endings, per the Ka0s WoW Addon Standard

$ for f in core/CoreSetup.lua settings/Slash.lua README.md docs/test-cases.md; do printf '%-26s %s\n' "$f" "$(file -b $f)"; done
core/CoreSetup.lua         Unicode text, UTF-8 text, with CRLF line terminators
settings/Slash.lua         Unicode text, UTF-8 text, with CRLF line terminators
README.md                  Unicode text, UTF-8 text, with very long lines (382), with CRLF line terminators
docs/test-cases.md         Unicode text, UTF-8 text, with CRLF line terminators
```

BankLedger's byte diff is clean **because** it pins the same `* text=auto eol=crlf` the library
does, not by accident. This output is also the evidence that contradicts a live ledger row —
see §6.4.

---

## §4 — Module coverage: which majors are wired, and where

The method's grep, run per consumer, excluding `libs/` and `tests/`.

### §4.1 AbsorbTracker

cwd=AT

```
$ grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
core/PerfSetup.lua:14:LibStub("LibKa0s-Perf-1.0", true)
core/DebugLogSetup.lua:14:LibStub("LibKa0s-DebugLog-1.0", true)
core/CoreSetup.lua:25:LibStub("LibKa0s-Core-1.0", true)
settings/Schema.lua:182:LibStub("LibKa0s-Slash-1.0", true)
settings/OptionsSetup.lua:36:LibStub("LibKa0s-Options-1.0", true)
settings/Slash.lua:24:LibStub("LibKa0s-Slash-1.0", true)
```

The same grep without the `/libs/` filter also returns the library's own internal lookups
(`DebugLog.lua:23`, `Options.lua:20`, `Perf.lua:21`, `Slash.lua:17` on Core; `OptionsWidgets.lua:12`
and `OptionsScroll.lua:15` on Options; `PerfPanel.lua:8`/`:12`) and the test-only lookups in
`tests/test_helpers.lua:850`, `tests/test_ltrap.lua:144/162/177` and the deliberate miss in
`tests/test_loadorder.lua:113`. None of those is host wiring.

Against `docs/releasing.md`'s per-module Consumers column:

| Module | releasing.md says (AbsorbTracker) | Found at | Agrees |
|---|---|---|---|
| `LibKa0s-Core-1.0` | `core/CoreSetup.lua` | `core/CoreSetup.lua:25` | yes |
| `LibKa0s-DebugLog-1.0` | `core/DebugLogSetup.lua` | `core/DebugLogSetup.lua:14` | yes |
| `LibKa0s-Slash-1.0` | `settings/Slash.lua` | `settings/Slash.lua:24` | yes (+ a second, undocumented lookup at `settings/Schema.lua:182`) |
| `LibKa0s-Options-1.0` | `settings/OptionsSetup.lua` + `settings/UnitPanel.lua` | `settings/OptionsSetup.lua:36` | yes (`UnitPanel.lua` decorates `NS.Helpers` rather than calling `LibStub`, so it does not appear in this grep — the table's description of it is accurate) |
| `LibKa0s-Perf-1.0` | `core/PerfSetup.lua` | `core/PerfSetup.lua:14` | yes |

The undocumented second Slash site, and what it reaches:

```
$ sed -n '182,192p' settings/Schema.lua  (extract, via grep)
settings/Schema.lua:182:LibStub("LibKa0s-Slash-1.0", true)
settings/Schema.lua:190:    if SlashLib then return SlashLib.FormatValue(row, v) end
```

The ship-side collector captured the surrounding context (cwd=LIB,
`AbsorbTracker/settings/Schema.lua:175-190`):

```
-- Resolved once, here at file load, and stashed (library-stack-§4). The TOC loads
-- libs\LibKa0s\LibKa0s.xml (which pulls in Slash.lua) in the lib block, long before
-- settings\Schema.lua, so by this line the major is either registered or permanently absent —
local SlashLib = LibStub and LibStub("LibKa0s-Slash-1.0", true)
...
function NS.FormatSchemaValue(row, v)
    if SlashLib then return SlashLib.FormatValue(row, v) end
```

`lib.FormatValue` is exactly the surface Slash minor 5 extended with the `format` descriptor hook.

Host files the modules replaced, and seam sizes:

```
$ ls core/ modules/
core/:
AbsorbTracker.lua  Bus.lua  Compat.lua  Constants.lua  CoreSetup.lua  Data.lua
Database.lua  DebugLogSetup.lua  LSMPatch.lua  Namespace.lua  PerfSetup.lua
State.lua  Units.lua

modules/:
Bar.lua  Display.lua  Timer.lua

$ wc -l core/CoreSetup.lua core/DebugLogSetup.lua core/PerfSetup.lua \
        settings/Slash.lua settings/OptionsSetup.lua settings/UnitPanel.lua
   78 core/CoreSetup.lua
  110 core/DebugLogSetup.lua
  130 core/PerfSetup.lua
  471 settings/Slash.lua
  199 settings/OptionsSetup.lua
  212 settings/UnitPanel.lua
 1200 total
```

No host `DebugLog.lua` and no host `Perf.lua` survive anywhere in the repo — both deleted outright
(`core/Perf.lua`'s removal is recorded in the ledger at ISS-19).

TOC load order:

```
$ grep -n -i 'libka0s\|CoreSetup\|DebugLogSetup\|PerfSetup\|OptionsSetup\|Slash\|UnitPanel\|AbsorbTracker.lua' AbsorbTracker.toc
27:libs\LibKa0s\LibKa0s.xml
41:core\CoreSetup.lua
42:core\PerfSetup.lua
47:core\DebugLogSetup.lua
48:core\AbsorbTracker.lua
60:settings\Slash.lua
61:settings\OptionsSetup.lua
62:settings\UnitPanel.lua
```

### §4.2 KickCD

cwd=KCD

```
$ grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
core/CoreSetup.lua:64:LibStub("LibKa0s-Core-1.0", true)
core/PerfSetup.lua:33:LibStub("LibKa0s-Perf-1.0", true)
core/DebugLogSetup.lua:45:LibStub("LibKa0s-DebugLog-1.0", true)
settings/OptionsSetup.lua:35:LibStub("LibKa0s-Options-1.0", true)
settings/Slash.lua:55:LibStub("LibKa0s-Slash-1.0", true)
```

The same grep with `/tests/` retained, showing a seam test exists per major:

```
core/PerfSetup.lua:33          settings/OptionsSetup.lua:35     settings/Slash.lua:55
core/DebugLogSetup.lua:45      core/CoreSetup.lua:64
tests/test_coresetup.lua:195,239,314        (Core)
tests/test_debuglogsetup.lua:258,313        (DebugLog)
tests/test_slash.lua:326,391                (Slash)
tests/test_options_panel.lua:279            (Options)
tests/test_perfsetup.lua:467                (Perf)
```

| Module | `releasing.md` says (KickCD) | Actual file:line | Agrees? |
|---|---|---|---|
| `LibKa0s-Core-1.0` | `core/CoreSetup.lua` | `core/CoreSetup.lua:64` | yes |
| `LibKa0s-DebugLog-1.0` | `core/DebugLogSetup.lua` | `core/DebugLogSetup.lua:45` | yes |
| `LibKa0s-Slash-1.0` | `settings/Slash.lua` | `settings/Slash.lua:55` | yes |
| `LibKa0s-Options-1.0` | `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`, `Panel_Widgets.lua`, `Panel_Render.lua` | `settings/OptionsSetup.lua:35`; all three decorators confirmed present | yes |
| `LibKa0s-Perf-1.0` | `core/PerfSetup.lua` | `core/PerfSetup.lua:33` | yes |

TOC placement:

```
$ grep -n 'LibKa0s\|Setup.lua\|Slash.lua\|PerfDB\|SavedVariables' KickCD.toc
7:## SavedVariables: KickCDDB, KickCDPerfDB
26:libs\LibKa0s\LibKa0s.xml
39:core\CoreSetup.lua
40:core\DebugLogSetup.lua
45:core\PerfSetup.lua
61:settings\Slash.lua
62:settings\OptionsSetup.lua
```

Host files replaced, and the whole-repo line count for context:

```
$ ls modules/
Castbar.lua  Castbar_Debug.lua  Castbar_Skin.lua  Cooldowns.lua
IconGrid.lua  IconGrid_Layout.lua  IconGrid_Render.lua  UnitLabel.lua

$ wc -l core/*.lua settings/*.lua modules/*.lua
   472 core/Compat.lua          154 core/Constants.lua       122 core/CoreSetup.lua
   835 core/Database.lua        170 core/DebugLogSetup.lua   771 core/KickCD.lua
    68 core/LSMPatch.lua        218 core/PerfSetup.lua       159 core/State.lua
   111 core/Units.lua           412 core/Util.lua
   562 settings/Castbar.lua     184 settings/General.lua     418 settings/Icons.lua
   194 settings/Label.lua       234 settings/OptionsSetup.lua 622 settings/Panel.lua
   271 settings/Panel_Render.lua  65 settings/Panel_Widgets.lua  67 settings/Profiles.lua
   347 settings/Slash.lua      1047 settings/Spells.lua
  1296 modules/Castbar.lua        95 modules/Castbar_Debug.lua  412 modules/Castbar_Skin.lua
   590 modules/Cooldowns.lua    1100 modules/IconGrid.lua       249 modules/IconGrid_Layout.lua
   864 modules/IconGrid_Render.lua 154 modules/UnitLabel.lua
 12263 total
```

`modules/DebugLog.lua` is gone — deleted outright. `core/DebugLogSetup.lua:12` states the delta:
*"It replaces modules/DebugLog.lua (518 lines), which is deleted."* There was never a host perf
file; Perf was purely additive.

### §4.3 ConsumableMaster

cwd=CM

```
$ grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
core/CoreSetup.lua:33:LibStub("LibKa0s-Core-1.0", true)
core/SlashCommands.lua:1301:LibStub("LibKa0s-Slash-1.0", true)
modules/DebugLog.lua:55:LibStub("LibKa0s-DebugLog-1.0", true)
modules/PerfSetup.lua:29:LibStub("LibKa0s-Perf-1.0", true)
settings/Panel.lua:184:LibStub("LibKa0s-Options-1.0", true)
```

| Module | Table says (ConsumableMaster) | Found at | Agrees |
|---|---|---|---|
| `LibKa0s-Core-1.0` | `core/CoreSetup.lua` | `core/CoreSetup.lua:33` | yes |
| `LibKa0s-DebugLog-1.0` | `modules/DebugLog.lua` | `modules/DebugLog.lua:55` | yes |
| `LibKa0s-Slash-1.0` | `core/SlashCommands.lua` | `core/SlashCommands.lua:1301` | yes |
| `LibKa0s-Options-1.0` | `settings/Panel.lua` | `settings/Panel.lua:184` | yes |
| `LibKa0s-Perf-1.0` | `modules/PerfSetup.lua` | `modules/PerfSetup.lua:29` | yes |

Seam and page sizes:

```
$ wc -l core/CoreSetup.lua modules/DebugLog.lua core/SlashCommands.lua settings/Panel.lua modules/PerfSetup.lua settings/General.lua settings/Category.lua settings/MacroBar.lua settings/StatPriority.lua
    99 core/CoreSetup.lua
   208 modules/DebugLog.lua
  1385 core/SlashCommands.lua
   920 settings/Panel.lua
   103 modules/PerfSetup.lua
   169 settings/General.lua
   634 settings/Category.lua
   508 settings/MacroBar.lua
   304 settings/StatPriority.lua
  4330 total
```

**Not captured this run:** ConsumableMaster's TOC ordering. Its collector read the load-order
claims in `core/CoreSetup.lua:10-20` and `settings/Panel.lua` but did not verify them against
`ConsumableMaster.toc`, so the ordering evidence for this consumer is the 2026-08-01 run's, not
this one's.

### §4.4 BankLedger

cwd=LIB

```
$ grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' ../BankLedger --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
../BankLedger/core/CoreSetup.lua:34:LibStub("LibKa0s-Core-1.0", true)
../BankLedger/core/DebugLogSetup.lua:20:LibStub("LibKa0s-DebugLog-1.0", true)
../BankLedger/settings/OptionsSetup.lua:26:LibStub("LibKa0s-Options-1.0", true)
../BankLedger/settings/Slash.lua:99:LibStub("LibKa0s-Slash-1.0", true)
```

Widened to include tests, proving nothing else resolves a major anywhere:

```
$ grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0"[^)]*\)' ../BankLedger --include='*.lua' | grep -v '/libs/'
../BankLedger/core/CoreSetup.lua:34:LibStub("LibKa0s-Core-1.0", true)
../BankLedger/core/DebugLogSetup.lua:20:LibStub("LibKa0s-DebugLog-1.0", true)
../BankLedger/settings/OptionsSetup.lua:26:LibStub("LibKa0s-Options-1.0", true)
../BankLedger/settings/Slash.lua:99:LibStub("LibKa0s-Slash-1.0", true)
../BankLedger/tests/test_libka0s.lua:23:LibStub("LibKa0s-Core-1.0", true)
../BankLedger/tests/test_libka0s.lua:113:LibStub("LibKa0s-Core-1.0", true)
../BankLedger/tests/test_libka0s.lua:163:LibStub("LibKa0s-Core-1.0", true)
../BankLedger/tests/test_libka0s.lua:333:LibStub("LibKa0s-DebugLog-1.0", true)
../BankLedger/tests/test_libka0s.lua:452:LibStub("LibKa0s-DebugLog-1.0", true)
../BankLedger/tests/test_libka0s.lua:526:LibStub("LibKa0s-Slash-1.0", true)
../BankLedger/tests/test_libka0s.lua:725:LibStub("LibKa0s-Slash-1.0", true)
../BankLedger/tests/test_slash.lua:178:LibStub("LibKa0s-Slash-1.0", true)
../BankLedger/tests/_kit/mock_base.lua:515:LibStub("LibKa0s-Options-1.0")
```

cwd=BL

```
$ ls core/ | grep -i perf || echo "no PerfSetup"
no PerfSetup
```

| Module | releasing.md says (for BankLedger) | Evidence | Agrees? |
|---|---|---|---|
| `LibKa0s-Core-1.0` | listed; `core/CoreSetup.lua` | `core/CoreSetup.lua:34` | yes |
| `LibKa0s-DebugLog-1.0` | listed; `core/DebugLogSetup.lua` | `core/DebugLogSetup.lua:20` | yes |
| `LibKa0s-Slash-1.0` | listed; `settings/Slash.lua` | `settings/Slash.lua:99` | yes |
| `LibKa0s-Options-1.0` | listed; `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua` | `settings/OptionsSetup.lua:26`; `settings/Panel.lua` reaches 18 distinct `O.*` surfaces (§5.5) | yes |
| `LibKa0s-Perf-1.0` | **not** listed; declined, LEDGER LIBKA0S-17 | no `LibStub("LibKa0s-Perf-1.0"…)` anywhere; no `core/PerfSetup.lua` | yes |

The TOC, verbatim, because it is where the three seams' load-order constraints are written down:

```
$ cat BankLedger.toc
## Interface: 120007
## Title: Ka0s Bank Ledger
## Notes: A passbook of every item and gold movement between your bags and your banks.
## Author: add1kted2ka0s
## Version: 1.0.0
## IconTexture: Interface\Icons\inv_misc_bag_15
## SavedVariables: BankLedgerDB
## OptionalDeps: Ace3, LibStub, CallbackHandler-1.0, LibSharedMedia-3.0, LibDataBroker-1.1, LibDBIcon-1.0
## DefaultState: enabled
## Category-enUS: Misc
## X-License: MIT
## X-Standard: https://github.com/tusharsaxena/WowAddonStandards
## X-Curse-Project-ID: 1629058

# Libraries (vendored in libs/ — load first)
libs\LibStub\LibStub.lua
libs\CallbackHandler-1.0\CallbackHandler-1.0.xml
libs\AceAddon-3.0\AceAddon-3.0.xml
libs\AceEvent-3.0\AceEvent-3.0.xml
libs\AceTimer-3.0\AceTimer-3.0.xml
libs\AceConsole-3.0\AceConsole-3.0.xml
libs\AceDB-3.0\AceDB-3.0.xml
libs\AceGUI-3.0\AceGUI-3.0.xml
libs\LibSharedMedia-3.0\lib.xml
libs\LibDataBroker-1.1\LibDataBroker-1.1.lua
libs\LibDBIcon-1.0\LibDBIcon-1.0.lua
# LibKa0s last in the block: every module but Core resolves LibKa0s-Core-1.0 through LibStub before
# it registers, and Options resolves AceGUI-3.0 at panel-build time rather than at load.
libs\LibKa0s\LibKa0s.xml

# Locales
locales\enUS.lua
locales\PostLoad.lua

# Core (Compat loads first)
core\Compat.lua
core\Constants.lua
core\Namespace.lua
# The LibKa0s-Core seam. After Namespace (NS.PREFIX), and before every file that takes NS.Print as a
# load-time upvalue or reclaims it from NS.Util.print — see the header of core/CoreSetup.lua.
core\CoreSetup.lua
# The LibKa0s-DebugLog seam. After Constants (FONT_MONO) and after CoreSetup
# (NS.LIBKA0S_MISSING). Everything else it touches is reached through a closure, so it no
# longer has to sit after modules/Browser.lua the way modules/DebugLog.lua did.
core\DebugLogSetup.lua
core\State.lua
core\Util.lua
core\BankLedger.lua
core\Database.lua

# Defaults
defaults\Global.lua

# Modules (Filters before Ledger — the capture gate reads the lists)
modules\Filters.lua
modules\Ledger.lua
modules\Browser.lua
modules\LedgerTable.lua
modules\SessionWindow.lua
modules\InsightsWidgets.lua
modules\Insights.lua
modules\Export.lua

# Settings (last — depend on everything else being initialized)
settings\Schema.lua
settings\Slash.lua
# The LibKa0s-Options seam. After the schema and the write seam it reads, and BEFORE
# settings/Panel.lua, which captures the instance at file scope (options-ui-§1).
settings\OptionsSetup.lua
settings\Panel.lua

$ ls modules/
Browser.lua
Export.lua
Filters.lua
Insights.lua
InsightsWidgets.lua
Ledger.lua
LedgerTable.lua
SessionWindow.lua

$ wc -l modules/Browser.lua settings/Panel.lua settings/Schema.lua core/CoreSetup.lua core/DebugLogSetup.lua settings/Slash.lua settings/OptionsSetup.lua
  1303 modules/Browser.lua
   608 settings/Panel.lua
   286 settings/Schema.lua
    98 core/CoreSetup.lua
   131 core/DebugLogSetup.lua
   249 settings/Slash.lua
   169 settings/OptionsSetup.lua
  2844 total
```

`modules/DebugLog.lua` (357 lines) is gone from the TOC and from disk;
`core/DebugLogSetup.lua` is 131 lines, a net −226 for the module.

### §4.5 The ship-side view of the same question

cwd=LIB — the wiring grep run across all four at once, which is what release step 7 reads:

```
$ grep -rnoE 'LibStub\("LibKa0s-[A-Za-z]+-1\.0", true\)' <Addon> --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'

===== AbsorbTracker =====
AbsorbTracker/core/DebugLogSetup.lua:14:LibStub("LibKa0s-DebugLog-1.0", true)
AbsorbTracker/core/PerfSetup.lua:14:LibStub("LibKa0s-Perf-1.0", true)
AbsorbTracker/core/CoreSetup.lua:25:LibStub("LibKa0s-Core-1.0", true)
AbsorbTracker/settings/Schema.lua:182:LibStub("LibKa0s-Slash-1.0", true)
AbsorbTracker/settings/OptionsSetup.lua:36:LibStub("LibKa0s-Options-1.0", true)
AbsorbTracker/settings/Slash.lua:24:LibStub("LibKa0s-Slash-1.0", true)
===== KickCD =====
KickCD/core/CoreSetup.lua:64:LibStub("LibKa0s-Core-1.0", true)
KickCD/core/DebugLogSetup.lua:45:LibStub("LibKa0s-DebugLog-1.0", true)
KickCD/core/PerfSetup.lua:33:LibStub("LibKa0s-Perf-1.0", true)
KickCD/settings/OptionsSetup.lua:35:LibStub("LibKa0s-Options-1.0", true)
KickCD/settings/Slash.lua:55:LibStub("LibKa0s-Slash-1.0", true)
===== ConsumableMaster =====
ConsumableMaster/core/CoreSetup.lua:33:LibStub("LibKa0s-Core-1.0", true)
ConsumableMaster/core/SlashCommands.lua:1301:LibStub("LibKa0s-Slash-1.0", true)
ConsumableMaster/modules/DebugLog.lua:55:LibStub("LibKa0s-DebugLog-1.0", true)
ConsumableMaster/modules/PerfSetup.lua:29:LibStub("LibKa0s-Perf-1.0", true)
ConsumableMaster/settings/Panel.lua:184:LibStub("LibKa0s-Options-1.0", true)
===== BankLedger =====
BankLedger/core/CoreSetup.lua:34:LibStub("LibKa0s-Core-1.0", true)
BankLedger/core/DebugLogSetup.lua:20:LibStub("LibKa0s-DebugLog-1.0", true)
BankLedger/settings/OptionsSetup.lua:26:LibStub("LibKa0s-Options-1.0", true)
BankLedger/settings/Slash.lua:99:LibStub("LibKa0s-Slash-1.0", true)
```

The Consumers table itself, for comparison (cwd=GIT, `LibKa0s/docs/releasing.md:148-154`):

```
| Module | Consumers | Where the wiring lives |
|---|---|---|
| `LibKa0s-Core-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger | `core/CoreSetup.lua` (all four) |
| `LibKa0s-DebugLog-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger | `core/DebugLogSetup.lua` (AbsorbTracker, KickCD, BankLedger); ConsumableMaster: `modules/DebugLog.lua` |
| `LibKa0s-Slash-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger | `settings/Slash.lua` (AbsorbTracker, KickCD, BankLedger); ConsumableMaster: `core/SlashCommands.lua` |
| `LibKa0s-Options-1.0` | AbsorbTracker, KickCD, ConsumableMaster, BankLedger | BankLedger: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`. AbsorbTracker: `settings/OptionsSetup.lua` + `settings/UnitPanel.lua`. KickCD: `settings/OptionsSetup.lua`, decorated by `settings/Panel.lua`, `Panel_Widgets.lua`, `Panel_Render.lua`. ConsumableMaster: `settings/Panel.lua` |
| `LibKa0s-Perf-1.0` | AbsorbTracker, KickCD, ConsumableMaster | `core/PerfSetup.lua` (first two); ConsumableMaster: `modules/PerfSetup.lua` |
```

Every row is corroborated at the repo level, including the Perf row correctly listing three
consumers. The single file-level omission is `AbsorbTracker/settings/Schema.lua:182`.

Also relevant to the table's accuracy, from KickCD's slice (cwd=KCD) — the paragraph at
`releasing.md:1227-1231` attributes library-instance decoration only to AbsorbTracker, but
`settings/OptionsSetup.lua:224` assigns `NS.Settings.Helpers = lib:New(descriptor)` and the file
header at `:12-17` states the rule ("Never a fresh table that copies members across"). The member
census proving KickCD decorates that same instance is at §5.4.

---

## §5 — Adoption shape, surface by surface

### §5.1 The denominator: what the library actually exports

Enumerated from the library source rather than from the README. cwd=GIT.

Lib-level members, per file:

```
$ grep -nE '^(function )?lib[.:][A-Za-z_]+ *(=|\()' LibKa0s/LibKa0s/Core.lua
31:lib.MODULES = lib.MODULES or {}
38:lib.SECRET = "<secret>"
57:function lib.IsConcatSafe(v)
67:function lib.SafeToString(v)
80:lib.SKIN = {
92:function lib.ApplySkin(frame)
103:function lib.MakeCloseButton(parent, onClick)
135:function lib:New(d)

$ grep -nE '^(function )?lib[.:][A-Za-z_]+ *(=|\()' LibKa0s/LibKa0s/DebugLog.lua
35:lib.MODULES = lib.MODULES or {}
41:lib.MAX_BUFFER = 500
54:function lib.MakeCloseButton(parent, onClick)
64:lib.STRINGS = {
93:function lib.FormatPlain(ts, tag, msg)
101:function lib.FormatColored(ts, tag, msg)
175:function lib:New(d)

$ grep -nE '^(function )?lib[.:][A-Za-z_]+ *(=|\()' LibKa0s/LibKa0s/Options.lua
32:lib.MODULES = lib.MODULES or {}
43:lib.LAYOUT = {
71:lib.STRINGS = {
122:function lib:New(d)

$ grep -nE '^(function )?lib[.:][A-Za-z_]+ *(=|\()' LibKa0s/LibKa0s/OptionsScroll.lua
26:lib.__scrollMinor      = SCROLL_MINOR
27:lib.__scrollShellMinor = lib.MINOR
29:lib.MODULES = lib.MODULES or {}
46:function lib.PatchAlwaysShowScrollbar(scroll)
164:function lib.__AttachScroll(O)

$ grep -nE '^(function )?lib[.:][A-Za-z_]+ *(=|\()' LibKa0s/LibKa0s/OptionsWidgets.lua
20:lib.__widgetsMinor      = WIDGETS_MINOR
21:lib.__widgetsShellMinor = lib.MINOR
23:lib.MODULES = lib.MODULES or {}
117:function lib.__AttachWidgets(O, d)

$ grep -nE '^(function )?lib[.:][A-Za-z_]+ *(=|\()' LibKa0s/LibKa0s/Perf.lua
38:lib.MODULES = lib.MODULES or {}
42:lib.SCHEMA = 2
46:lib.DEFAULT_RING = 10
86:function lib.EncodeJSON(value)
113:lib.STRINGS = {
192:function lib:New(descriptor)

$ grep -nE '^(function )?lib[.:][A-Za-z_]+ *(=|\()' LibKa0s/LibKa0s/PerfPanel.lua
22:lib.__panelMinor = PANEL_MINOR
23:lib.__panelProbeMinor = lib.MINOR
27:lib.MODULES = lib.MODULES or {}
75:function lib.__AttachPanel(P, d, tr, runCommand)

$ grep -nE '^(function )?lib[.:][A-Za-z_]+ *(=|\()' LibKa0s/LibKa0s/Slash.lua
29:lib.MODULES = lib.MODULES or {}
34:lib.STRINGS = {
68:function lib.FormatRow(command, description)
74:function lib.FormatKV(path, valueStr)
87:function lib.FormatValue(row, v)
243:function lib.ParseValue(row, text)
286:function lib:New(d)
```

Instance members returned by each `lib:New`:

```
$ grep -nE '^  function (D|O|P|Sl)[.:][A-Za-z_]+' LibKa0s/LibKa0s/*.lua
LibKa0s/LibKa0s/DebugLog.lua:214:  function D:Text(key)
LibKa0s/LibKa0s/DebugLog.lua:478:  function D:Add(tag, msg)
LibKa0s/LibKa0s/DebugLog.lua:498:  function D.Debug(tag, fmt, ...)
LibKa0s/LibKa0s/DebugLog.lua:510:  function D:BufferSize() return #D.buffer end
LibKa0s/LibKa0s/DebugLog.lua:512:  function D:LastLine() return D.buffer[#D.buffer] end
LibKa0s/LibKa0s/DebugLog.lua:516:  function D:FindLine(substr)
LibKa0s/LibKa0s/DebugLog.lua:523:  function D:Clear()
LibKa0s/LibKa0s/DebugLog.lua:530:  function D:UpdateScrollBar()
LibKa0s/LibKa0s/DebugLog.lua:543:  function D:UpdateStatus()
LibKa0s/LibKa0s/DebugLog.lua:551:  function D:CopyText() return table.concat(D.buffer, "\n") end
LibKa0s/LibKa0s/DebugLog.lua:553:  function D:ShowCopy()
LibKa0s/LibKa0s/DebugLog.lua:567:  function D:Show() local f = EnsureFrame(); if f then f:Show() end end
LibKa0s/LibKa0s/DebugLog.lua:571:  function D:Hide() if frame then frame:Hide() end end
LibKa0s/LibKa0s/DebugLog.lua:573:  function D:IsShown() return (frame and frame:IsShown()) and true or false end
LibKa0s/LibKa0s/DebugLog.lua:575:  function D:Toggle()
LibKa0s/LibKa0s/DebugLog.lua:583:  function D:IsEnabled() return not not d.isEnabled() end
LibKa0s/LibKa0s/DebugLog.lua:585:  function D:RefreshHeader()
LibKa0s/LibKa0s/DebugLog.lua:598:  function D:SetEnabled(on)
LibKa0s/LibKa0s/DebugLog.lua:629:  function D:ConsoleCheckbox()
LibKa0s/LibKa0s/Options.lua:201:  function O.CreatePanel(name, title, opts)
LibKa0s/LibKa0s/Options.lua:273:  function O.EnsureDefaultsButton(panel)
LibKa0s/LibKa0s/Options.lua:305:  function O.EnsureScroll(ctx)
LibKa0s/LibKa0s/Options.lua:340:  function O.ClearScroll(ctx)
LibKa0s/LibKa0s/Options.lua:359:  function O.RestoreDefaults(pageKey, ctx)
LibKa0s/LibKa0s/Options.lua:377:  function O.RestoreAllDefaults()
LibKa0s/LibKa0s/Options.lua:439:  function O.SetRenderer(ctx, fn)
LibKa0s/LibKa0s/Options.lua:470:  function O.RefreshAllPanels()
LibKa0s/LibKa0s/Options.lua:474:  function O.RefreshScalars()
LibKa0s/LibKa0s/Options.lua:485:  function O.LSMValues(mediaType)
LibKa0s/LibKa0s/Options.lua:519:  function O.RegisterOptionsPage(key, name, builder)
LibKa0s/LibKa0s/Options.lua:528:  function O.__pages() return builtPages end
LibKa0s/LibKa0s/Options.lua:553:  function O.CreateOptionsPanel()
LibKa0s/LibKa0s/Options.lua:613:  function O.OpenOptionsPanel()
LibKa0s/LibKa0s/Options.lua:633:  function O.__panels() return renderedPanels end
LibKa0s/LibKa0s/Options.lua:635:  function O.__panelFor(pageKey)
LibKa0s/LibKa0s/OptionsWidgets.lua:152:  function O.AttachTooltip(widget, label, tooltip)
LibKa0s/LibKa0s/OptionsWidgets.lua:181:  function O.AddSpacer(scroll, height)
LibKa0s/LibKa0s/OptionsWidgets.lua:192:  function O.Section(ctx, label)
LibKa0s/LibKa0s/OptionsWidgets.lua:217:  function O.InlineButtonPair(ctx, leftSpec, rightSpec)
LibKa0s/LibKa0s/OptionsWidgets.lua:464:  function O.RenderField(ctx, row, parent, relativeWidth)
LibKa0s/LibKa0s/OptionsWidgets.lua:497:  function O.SessionCheckbox(ctx, parent, relativeWidth, spec)
LibKa0s/LibKa0s/OptionsWidgets.lua:550:  function O.RenderGrid(ctx, items)
LibKa0s/LibKa0s/OptionsWidgets.lua:603:  function O.RenderRows(ctx, rows, afterGroup, pairWith)
LibKa0s/LibKa0s/OptionsWidgets.lua:678:  function O.RenderSchema(ctx, pageKey, afterGroup, pairWith)
LibKa0s/LibKa0s/Perf.lua:271:  function P.Note(key, ms)
LibKa0s/LibKa0s/Perf.lua:282:  function P.Reset()
LibKa0s/LibKa0s/Perf.lua:293:  function P.__buckets()   return buckets   end
LibKa0s/LibKa0s/Perf.lua:294:  function P.__fpsArms()   return fpsArms   end
LibKa0s/LibKa0s/Perf.lua:295:  function P.__completed() return completed end
LibKa0s/LibKa0s/Perf.lua:296:  function P.__reviewed()  return reviewed  end
LibKa0s/LibKa0s/Perf.lua:299:  function P.Log(fmt, ...)
LibKa0s/LibKa0s/Perf.lua:305:  function P.Announce(fmt, ...)
LibKa0s/LibKa0s/Perf.lua:321:  function P.MarkReviewed(key)
LibKa0s/LibKa0s/Perf.lua:334:  function P.Progress()
LibKa0s/LibKa0s/Perf.lua:395:  function P.Context()
LibKa0s/LibKa0s/Perf.lua:418:  function P.ContextLines(ctx)
LibKa0s/LibKa0s/Perf.lua:431:  function P.BuildRecord(label)
LibKa0s/LibKa0s/Perf.lua:469:  function P.Save(record)
LibKa0s/LibKa0s/Perf.lua:492:  function P.FormatReport(record)
LibKa0s/LibKa0s/Perf.lua:606:  function P.__sampler() return sampler end
LibKa0s/LibKa0s/Perf.lua:677:  function P.Start(label)
LibKa0s/LibKa0s/Perf.lua:701:  function P.Measure(token)
LibKa0s/LibKa0s/Perf.lua:730:  function P.Stop()
LibKa0s/LibKa0s/Perf.lua:752:  function P.Cancel()
LibKa0s/LibKa0s/Perf.lua:784:  function P.Suspend()
LibKa0s/LibKa0s/Perf.lua:792:  function P.Resume()
LibKa0s/LibKa0s/Perf.lua:810:  function P.Usage()
LibKa0s/LibKa0s/Perf.lua:922:  function P.StatusLines()
LibKa0s/LibKa0s/Perf.lua:939:  function P.OnCommand(args)
LibKa0s/LibKa0s/PerfPanel.lua:94:  function P.PanelStateOf(key)
LibKa0s/LibKa0s/PerfPanel.lua:101:  function P.PanelIsActionable(key)
LibKa0s/LibKa0s/PerfPanel.lua:207:  function P.RefreshPanel()
LibKa0s/LibKa0s/PerfPanel.lua:231:  function P.ShowPanel()
LibKa0s/LibKa0s/PerfPanel.lua:238:  function P.HidePanel() if frame then frame:Hide() end end
LibKa0s/LibKa0s/PerfPanel.lua:239:  function P.IsPanelShown() return (frame and frame:IsShown()) and true or false end
LibKa0s/LibKa0s/PerfPanel.lua:241:  function P.TogglePanel()
LibKa0s/LibKa0s/PerfPanel.lua:246:  function P.__panel() return frame end
LibKa0s/LibKa0s/Slash.lua:319:  function Sl:Text(key)
LibKa0s/LibKa0s/Slash.lua:329:  function Sl:SetRowAnnotator(fn)
LibKa0s/LibKa0s/Slash.lua:375:  function Sl:HelpRows() return rows("  ") end
LibKa0s/LibKa0s/Slash.lua:379:  function Sl:LandingRows() return rows("") end
LibKa0s/LibKa0s/Slash.lua:381:  function Sl:HelpHeader()
LibKa0s/LibKa0s/Slash.lua:389:  function Sl:PrintHelp()
LibKa0s/LibKa0s/Slash.lua:408:  function Sl:BuildListLines()
LibKa0s/LibKa0s/Slash.lua:434:  function Sl:CliList()
LibKa0s/LibKa0s/Slash.lua:438:  function Sl:CliGet(rest)
LibKa0s/LibKa0s/Slash.lua:446:  function Sl:CliSet(rest)
LibKa0s/LibKa0s/Slash.lua:473:  function Sl:CliReset(rest)
LibKa0s/LibKa0s/Slash.lua:484:  function Sl:CliResetAll()
LibKa0s/LibKa0s/Slash.lua:492:  function Sl:CliVersion()
LibKa0s/LibKa0s/Slash.lua:505:  function Sl:OnSlash(msg)
```

Every descriptor field each module reads — the denominator for the descriptor-field counts in §5.7:

```
$ grep -noE 'd\.[A-Za-z_]+|descriptor\.[A-Za-z_]+' LibKa0s/LibKa0s/Core.lua | sed 's/^[0-9]*://' | sort -u
d.prefix d.sep d.sink descriptor.prefix

$ ... LibKa0s/LibKa0s/DebugLog.lua
d.L d.applySkin d.font d.fontSize d.initSummary d.isEnabled d.makeCloseButton d.name d.onVisibilityChanged d.print d.safeToString d.setEnabled d.skin d.slash d.title

$ ... LibKa0s/LibKa0s/Options.lua
d.afterRestoreAll d.allRows d.applyDefault d.buildMain d.debug d.getLSM d.mainPanelName d.onAceGUI d.parentTitle d.print d.rowsForPage d.skipRestoreAll d.validate descriptor.mainPanelName

$ ... LibKa0s/LibKa0s/OptionsScroll.lua
(none)

$ ... LibKa0s/LibKa0s/OptionsWidgets.lua
d.colorDecode d.colorEncode d.get d.print d.rowsForPage d.scheduleTimer d.set d.sliderCommit

$ ... LibKa0s/LibKa0s/Perf.lua
d.L d.buckets d.log d.name d.onChange d.print d.resume d.ring d.showLog d.slash d.suspend d.sv d.title d.version descriptor.buckets

$ ... LibKa0s/LibKa0s/PerfPanel.lua
d.decorate d.name

$ ... LibKa0s/LibKa0s/Slash.lua
d.L d.aliases d.allRows d.applyDefault d.colorDecode d.colorEncode d.commands d.findRow d.format d.get d.groupKey d.parse d.print d.set d.slash d.slashAliases d.version descriptor.commands descriptor.slash
```

Note the five widget makers are **local** functions inside `OptionsWidgets.lua`
(`makeCheckbox:254`, `makeSlider:275`, `makeDropdown:332`, `makeEditBox:374`,
`makeColorPicker:394`), not instance members. A host reaches them only through `O.RenderField`,
`O.RenderRows` or `O.RenderGrid`.

### §5.2 AbsorbTracker — Options

cwd=AT

| Surface | Used | Evidence |
|---|---|---|
| `RenderRows` | yes | `settings/UnitPanel.lua:147`, `:149` |
| `RenderGrid` | yes | `settings/UnitPanel.lua:143` (adopted this cycle, ledger LIBKA0S-02) |
| `RenderSchema` | yes | listed in the degraded-stub member list `settings/OptionsSetup.lua:162`; page builders drive it |
| `RenderField` (the maker dispatcher) | yes | `settings/OptionsSetup.lua:161` |
| `SessionCheckbox` | yes | `settings/OptionsSetup.lua:162` |
| `InlineButtonPair` | yes | `settings/OptionsSetup.lua:161` |
| `Section` / `AddSpacer` | yes | `settings/OptionsSetup.lua:160`, `:161` |
| `AttachTooltip` | yes | `settings/UnitPanel.lua:114`, `:128` |
| `LSMValues` | yes | `settings/Font.lua:45`, `settings/Border.lua:31`, `settings/Bar.lua:60`, `:98` |
| `SetRenderer` | **no** | zero non-lib hits |
| `RefreshAllPanels` | yes | `settings/OptionsSetup.lua:199`, `core/DebugLogSetup.lua:103`, `settings/UnitPanel.lua:161/174` |
| `RefreshScalars` | **no** | zero non-lib hits |
| `RestoreDefaults` / `RestoreAllDefaults` | yes | 8 files (`settings/Slash.lua:runResetAll`, `settings/General.lua:124`, panel Defaults buttons) |
| page registry (`RegisterOptionsPage`) | yes | `settings/General.lua:200`, `Bar.lua:182`, `Border.lua:103`, `Font.lua:107`, `Profiles.lua:69`; republished at `settings/OptionsSetup.lua:193` |
| `CreatePanel` | yes | five pages: `General.lua:147`, `Bar.lua:161`, `Border.lua:82`, `Font.lua:86`, `Profiles.lua:41` |
| `EnsureDefaultsButton` / `EnsureScroll` / `ClearScroll` | yes | `settings/OptionsSetup.lua:160` |
| `PatchAlwaysShowScrollbar` | yes | `settings/OptionsSetup.lua:163` |
| `colorDecode` / `colorEncode` | yes | `settings/OptionsSetup.lua:95`, `:99` |
| numeric-enum dropdown (Options minor 5) | **n/a** | no `type="number"` row in this addon carries `values` |
| `OnCommit`/`OnDefault`/`OnRefresh` (Options minor 5) | inherited | stamped by `CreatePanel`; no host code and no host test touches them |

Slash — the four CLI verbs counted separately:

```
$ grep -rn 'Cli\(List\|Get\|Set\|Reset\)' settings/Slash.lua
settings/Slash.lua:128:function listSettings() cli:CliList() end
settings/Slash.lua:129:function getSetting(rest) cli:CliGet(rest) end
settings/Slash.lua:130:function setSetting(rest) cli:CliSet(rest) end
settings/Slash.lua:159:function runReset(rest) cli:CliReset(rest) end

$ grep -rn 'CliResetAll' . --include='*.lua' | grep -v '/libs/'
(no output)

$ sed -n '160,175p' settings/Slash.lua
function runResetAll()
    -- Delegate to the single shared helper so the slash command and the
    -- "Reset All Settings" popup can never diverge — same rows reset,
    -- same position clear + recenter, same panel refresh.
    ...
    if NS.Helpers and NS.Helpers.RestoreAllDefaults then
        NS.Helpers.RestoreAllDefaults()
        print("All settings reset to defaults")
    else
        print("Cannot reset settings \226\128\148 the settings helpers failed to load")
    end
end
```

| Surface | Used | Evidence |
|---|---|---|
| dispatcher (`OnSlash`) | yes | `settings/Slash.lua:463` |
| `HelpRows` | yes, transitively | `settings/Slash.lua:112` `function printHelp() cli:PrintHelp() end`; `PrintHelp` renders `HelpRows` internally (`LibKa0s/Slash.lua:391`) |
| `LandingRows` | yes | `settings/Slash.lua:461`, rendered at `settings/About.lua:93` |
| `FormatRow` (direct) | yes | `settings/Slash.lua:33` (`PrintCmd`), for the seven host-owned `/at profile` sub-rows at `:309`–`:315` |
| `FormatValue` | yes | `settings/Schema.lua:190` |
| `SetRowAnnotator` | yes | `settings/Slash.lua:457` (`MirrorNote`) |
| `parse` descriptor field | yes (as `findRow`/`applyDefault`/`groupKey` adapters) | `settings/Slash.lua:440`–`:452` |
| `format` descriptor field (Slash minor 5) | **no** | zero hits; no `table`-typed row exists here |
| `colorDecode` / `colorEncode` on Slash | via Options descriptor only | `settings/OptionsSetup.lua:95`, `:99` |

Core:

| Surface | Used | Evidence |
|---|---|---|
| printer | yes | `core/CoreSetup.lua:77` `NS.Print = printer.Print`; `:78` `Util.print = NS.Print` |
| `SafeToString` | yes | `core/CoreSetup.lua:63`; consumed at `core/DebugLogSetup.lua:87/96/97`, `settings/UnitPanel.lua:210` |
| `SKIN` | **declined** | `grep -rn 'SKIN' --include='*.lua' .` returns zero non-`libs/` hits |
| `MakeCloseButton` | yes, indirectly | `core/PerfSetup.lua:116`, `:121` via `NS.DebugLog.MakeCloseButton`; stubbed at `core/DebugLogSetup.lua:58` |

The v1.2.0 chrome overrides are not taken:

```
$ grep -rn 'applySkin\|makeCloseButton' . --include='*.lua' | grep -v '/libs/'
(no output)
```

### §5.3 KickCD — the instance census and the surface tables

cwd=KCD

```
$ grep -rhoE '\b(Helpers|H|NS\.Settings\.Helpers)\.[A-Za-z_]+' settings core modules --include='*.lua' | sed 's/^.*\.//' | sort | uniq -c | sort -rn
     14 SetAndRefresh      (host)
     13 Set                (host)
     11 LSMValues          LIBRARY
     11 EnsureDefaultsButton  LIBRARY
     11 CreatePanel        LIBRARY
      9 RenderUnitPanel    (host)
      8 FireConfigChanged  (host)
      7 RenderSchema       LIBRARY
      7 Get                (host)
      7 FindSchema         (host)
      7 AnchorValues       (host)
      6 SchemaForPanel     (host)
      6 RestoreUnitLinks   (host)
      6 ResetAllPositions  (host)
      6 ResetAll           (host)
      5 RefreshAllPanels   LIBRARY
      4 ValidateSchema     (host)
      4 RestoreDefaults    LIBRARY
      4 ResetIconPosition  (host)
      4 ROW_VSPACER        LIBRARY (constant)
      4 EnsureScroll       LIBRARY
      4 ClearScroll        LIBRARY
      4 BuildMainContent   (host)
      3 Resolve            (host)
      3 RenderRows         LIBRARY
      3 AnchorOrder        (host)
      3 AddSpacer          LIBRARY
      2 SessionToggle      (host)
      2 RestoreAllDefaults LIBRARY
      2 RerenderUnitPanel  (host)
      2 RenderField        LIBRARY
      2 PatchAlwaysShowScrollbar LIBRARY
      2 PartitionUnitRows  (host)
      2 InlinePair         (host)
      1 __panels           LIBRARY (introspection)
      1 __panelFor         LIBRARY (introspection)
      1 SessionCheckbox    LIBRARY
      1 SECTION_HEADING_H  LIBRARY (constant)
      1 RegisterOptionsPage LIBRARY
      1 PrintSchemaError   (host)
      1 OpenOptionsPanel   LIBRARY
      1 InlineButtonPair   LIBRARY
      1 FireOnChange       (host)
      1 CreateOptionsPanel LIBRARY
      1 BUTTON_PAIR_REL    LIBRARY (constant)
      1 AttachTooltip      LIBRARY
```

The "(host)" rows sit **on** the library instance: `settings/OptionsSetup.lua:224` is
`NS.Settings.Helpers = lib:New(descriptor)`, decorated in place by `settings/Panel.lua`,
`Panel_Widgets.lua` and `Panel_Render.lua`.

Options, surface by surface:

| Surface | KickCD | Evidence |
|---|---|---|
| `RenderRows` | **calls** | `settings/Panel.lua:44,184,428`; `settings/Panel_Render.lua:127,269` (+ via `RenderSchema`) |
| `RenderGrid` | **declines** | 0 host call sites; recorded `docs/pending/LEDGER.md` LIBKA0S-04 as wont-do with a three-part not-expressible verdict |
| the five makers | **uses all, indirectly** | library-locals reached through `RenderField`/`RenderRows`: `settings/General.lua:151`, `settings/Panel_Widgets.lua:6`, `settings/Panel_Render.lua:8`, `settings/OptionsSetup.lua:201` |
| `LSMValues` | **calls** | 11 sites — `settings/OptionsSetup.lua:144,153,154`; `settings/Panel.lua:281`; `settings/Icons.lua:196,220`; `settings/Label.lua:147`; `settings/Castbar.lua:280,401,438,463,500` |
| `SetRenderer` | **no direct call** | reached transitively — `RegisterOptionsPage` (`Options.lua:519`) and `buildMain` (`Options.lua:543`) call it for the host |
| `RefreshAllPanels` | **calls** | `settings/OptionsSetup.lua:234`; `core/DebugLogSetup.lua:162`; `settings/Panel_Render.lua:143,163,269`; `settings/Castbar.lua:135,150` |
| `RefreshScalars` | **no direct call** | the widget makers call it internally (`OptionsWidgets.lua:132`) |
| page registry | **fully adopted** | `settings/OptionsSetup.lua:228,229,230` |
| `RestoreDefaults` / `RestoreAllDefaults` | **calls** | 4 + 2 sites |
| `EnsureScroll` / `ClearScroll` / `Section` / `AddSpacer` / `InlineButtonPair` / `SessionCheckbox` / `AttachTooltip` / `EnsureDefaultsButton` / `PatchAlwaysShowScrollbar` | **calls all** | counts above |
| layout constants | **reads, no host copy** | 4 / 1 / 1 sites |

The single non-`libs/` hit for a maker name is a stale comment, not a call:

```
$ grep -rn 'make\(Check\|Slider\|Dropdown\|Color\|EditBox\)' --include='*.lua' . | grep -v '/libs/' | grep -v '/tests/'
settings/Castbar.lua:166:    -- it refreshes (Panel.lua's makeDropdown re-runs `applyList`
```

Descriptor fields KickCD supplies (`settings/OptionsSetup.lua:47-134`): `parentTitle`,
`mainPanelName`, `print`, `debug`, `get`, `set`, `applyDefault`, `rowsForPage`, `allRows`,
`skipRestoreAll`, `afterRestoreAll`, `scheduleTimer`, `getLSM`, `validate`, `onAceGUI`,
`buildMain`, `colorDecode`, `colorEncode` — the widest Options descriptor of any consumer.

Slash:

| Surface | KickCD | Evidence |
|---|---|---|
| dispatcher (`OnSlash` / `PrintHelp`) | **adopted** | `settings/Slash.lua:346,347`; entry point `core/KickCD.lua:279-280` |
| `HelpRows` | **adopted** | via `PrintHelp`, `core/KickCD.lua:243-244` + `settings/Slash.lua:232,239` |
| `LandingRows` | **adopted** | `settings/Slash.lua:344`; rendered at `settings/Panel.lua:531` |
| `CliList` / `CliGet` / `CliSet` | **adopted** | `core/KickCD.lua:310`, `:315`, `:320` |
| `CliReset` | **adopted** | `settings/Slash.lua:189` (behind the retired-page shim) |
| `ParseValue` | **adopted, wrapped** | `settings/Slash.lua:142` inside `parseForHost` |
| `FormatValue` | comment only (`settings/Slash.lua:48`); used by the library internally | |
| `SetRowAnnotator` | **not used** on the live path — only the degradation stub defines it (`settings/Slash.lua:217`) | |
| `format` (Slash minor 5) | **not used** | 0 host sites |
| `colorDecode`/`colorEncode` on Slash | **deliberately not passed** — rationale at `settings/Slash.lua:31-53` | |

Core:

```
$ grep -rn 'SKIN\|ApplySkin\|MakeCloseButton' --include='*.lua' settings core modules
core/DebugLogSetup.lua:91:        MakeCloseButton = function() return nil end,     <- degradation stub member
core/PerfSetup.lua:13:--   * core/DebugLogSetup.lua has run, so the log sink and MakeCloseButton exist;
core/PerfSetup.lua:209:        if not (NS.DebugLog and NS.DebugLog.MakeCloseButton) then return end
core/PerfSetup.lua:210:        local close = NS.DebugLog.MakeCloseButton(frame, api.Hide)
```

| Surface | KickCD |
|---|---|
| printer | **adopted** — `core/CoreSetup.lua:118-122`, published as `NS.Util.print` (never `NS.Print`, to dodge the AceConsole embed; rationale `:35-41`). Prefix in **function form** (`:119`) |
| `SafeToString` | **adopted** — `core/CoreSetup.lua:110` |
| `IsConcatSafe` | **adopted** — `core/CoreSetup.lua:109` |
| `SECRET` | not read directly; the sentinel is reproduced only inside the no-library fallback at `core/CoreSetup.lua:91` |
| `SKIN` / `ApplySkin` | **declined** — 0 host references |
| `MakeCloseButton` | **adopted indirectly** via the DebugLog instance's re-export, `core/PerfSetup.lua:210` (`:203-207`) |
| `sep` | left at default; `NS.PREFIX` carries no trailing space (`core/CoreSetup.lua:116-117`) |

Which of the four v1.2.0 additions KickCD actually reaches:

```
$ grep -rn 'applySkin\|makeCloseButton\|OnDefault\|OnCommit\|OnRefresh\|format *=' --include='*.lua' core settings | grep -v Format
(no output)

$ grep -rn 'type *= *"number"' --include='*.lua' settings | wc -l
31
$ grep -rn -A4 'type *= *"number"' --include='*.lua' settings | grep -c 'values'
0

$ grep -rn 'defaultsOnClick' --include='*.lua' . | grep -v '/libs/'
settings/Castbar.lua:537:    ctx.panel.defaultsOnClick = function()
settings/Icons.lua:393:     ctx.panel.defaultsOnClick = function()
settings/Label.lua:178:     ctx.panel.defaultsOnClick = function()
settings/Spells.lua:941:    panel.defaultsOnClick = function()
settings/General.lua:129:   ctx.panel.defaultsOnClick = function()
```

Three of the four are inert here; `CreatePanel`'s `OnDefault` forwarder gives KickCD a working
Blizzard footer Defaults control on five pages with no host edit.

### §5.4 ConsumableMaster

cwd=CM. Host-side bindings, all in `settings/Panel.lua` unless noted:

```
$ grep -rnE 'RenderRows|RenderGrid|make(Check|Slider|Dropdown|Color|EditBox)|LSMValues|SetRenderer|RefreshAllPanels|RefreshScalars|RegisterOptionsPage|CreateOptionsPanel|CreatePanel|__pages|AttachTooltip|PatchAlwaysShowScrollbar|EnsureScroll|AddSpacer|OnDefault|OnCommit|OnRefresh' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/_kit/'

settings/Panel.lua:239:    UI.AceGUI = AceGUI
settings/Panel.lua:241:    Helpers.PatchAlwaysShowScrollbar = UI.PatchAlwaysShowScrollbar
settings/Panel.lua:242:    ensureScroll = function(ctx) return UI.EnsureScroll(ctx) end
settings/Panel.lua:243:    Helpers.EnsureScroll = ensureScroll
settings/Panel.lua:276:local attachTooltip = UI and UI.AttachTooltip
settings/Panel.lua:277:Helpers.AttachTooltip = attachTooltip
settings/Panel.lua:301:    local ctx = UI.CreatePanel(name, title, {
settings/Panel.lua:349:Helpers.SetRenderer = UI and UI.SetRenderer
settings/Panel.lua:359:Helpers.ResetScroll = UI and UI.ClearScroll
settings/Panel.lua:381:local addSpacer = UI and UI.AddSpacer
settings/Panel.lua:382:Helpers.AddSpacer = addSpacer
settings/Panel.lua:391:    local h = UI.Section(ctx, label)
settings/Panel.lua:446:    local hash = UI and UI.LSMValues(mediaType)() or {}
settings/Panel.lua:456:Helpers.RenderField = UI and UI.RenderField
settings/Panel.lua:517:Helpers.Grid = UI and UI.RenderGrid
settings/Panel.lua:525:Helpers.CustomCheckbox = UI and UI.SessionCheckbox
settings/Panel.lua:569:Helpers.RefreshAllPanels = UI and UI.RefreshAllPanels
settings/Panel.lua:570:Helpers.RefreshScalars   = UI and UI.RefreshScalars
```

Call sites in the page files:

```
settings/General.lua:36,50,63,86:    H.RefreshAllPanels()
settings/General.lua:101:           local scroll = H.EnsureScroll(ctx)
settings/General.lua:129:           H.Grid(ctx, { enabledDef, debugConsole })
settings/General.lua:157:           local ctx = H.CreatePanel("KCMGeneralPanel", L["General"], {
settings/General.lua:163:           H.SetRenderer(ctx, render)
settings/MacroBar.lua:135,166:      values = function() return H.LSMValues("border") end,
settings/MacroBar.lua:372,383:      H.RefreshAllPanels()
settings/MacroBar.lua:416,424,438,446,454,463,472,484:  H.Grid(ctx, …)
settings/MacroBar.lua:421:          local scroll = H.EnsureScroll(ctx)
settings/MacroBar.lua:498:          local ctx = H.CreatePanel("KCMMacroBarPanel", L["Macro Bar"], {
settings/MacroBar.lua:502:          H.SetRenderer(ctx, render)
settings/Category.lua:106:          H.RefreshAllPanels()
settings/Category.lua:203,214,247,272,287:  H.AttachTooltip(…)
settings/Category.lua:298,513:      local scroll = H.EnsureScroll(ctx)
settings/Category.lua:304,390,495,521,596:  H.AddSpacer(…)
settings/Category.lua:616:          local ctx = H.CreatePanel(panelName, cat.displayName, {
settings/Category.lua:622:          H.SetRenderer(ctx, function(c) …
settings/StatPriority.lua:149,225:  H.RefreshAllPanels()
settings/StatPriority.lua:190:      H.AttachTooltip(dd, opts.label, opts.tooltip)
settings/StatPriority.lua:211:      local scroll  = H.EnsureScroll(ctx)
settings/StatPriority.lua:278:      H.AddSpacer(scroll, 8)
settings/StatPriority.lua:292:      local ctx = H.CreatePanel("KCMStatPriorityPanel", L["Stat Priority"], {
settings/StatPriority.lua:298:      H.SetRenderer(ctx, render)
```

The two Options surfaces declined, with their recorded reasons:

```
$ grep -rn 'RenderRows\|RenderGrid\|Helpers.Grid\|H.Grid' --include='*.lua' . | grep -v '/libs/' | grep -v '/tests/_kit/'
settings/MacroBar.lua:416:    H.Grid(ctx, items)
settings/MacroBar.lua:424:    H.Grid(ctx, { defs.enabled, defs.locked })
settings/MacroBar.lua:438,446,454,463,472:    H.Grid(ctx, { … })
settings/MacroBar.lua:484:    H.Grid(ctx, { defs.combatMode, defs.fadeUnlessHover, defs.fadeAlpha })
settings/General.lua:129:    H.Grid(ctx, { enabledDef, debugConsole })
settings/Panel.lua:510-517: (comment) …had its own copy until LibKa0s-Options-1.0 grew RenderGrid…
settings/Panel.lua:517:Helpers.Grid = UI and UI.RenderGrid

$ grep -rn 'RegisterOptionsPage\|CreateOptionsPanel\|__pages' --include='*.lua' . | grep -v '/libs/' | grep -v '/tests/_kit/'
settings/Panel.lua:238:    -- it only inside its own CreateOptionsPanel, which this addon never calls.
```

`settings/Panel.lua:509-517`, the recorded reason `RenderRows` could not replace the host's grid:

> This addon had its own copy until LibKa0s-Options-1.0 grew RenderGrid. Its RenderRows could never
> replace it: that one is SCHEMA-driven and auto-sections by `group`, where these pages pair their
> rows by hand and — the case that forced the issue — settings/MacroBar.lua's per-macro toggle list
> has one checkbox per macro, a length no schema knows.

The Options descriptor (`settings/Panel.lua:185-236`):

```lua
UI = optionsLib:New({
    mainPanelName = "KCMMainPanel",
    parentTitle   = PANEL_TITLE,
    print         = function(line) KCM.Say(line) end,
    colorDecode   = function(c) … return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end,
    colorEncode   = function(r, g, b, a) return { r, g, b, a or 1 } end,
    sliderCommit  = "change",
    getLSM        = function() return LibStub and LibStub("LibSharedMedia-3.0", true) end,
    get           = function(path) return Helpers.Get(path) end,
    set           = function(path, value) Helpers.SetAndRefresh(path, value) end,
})
```

Slash — the four CLI verbs, and the one deliberately not taken:

```
$ sed -n '1350,1361p' core/SlashCommands.lua
    KCM.SlashCommands.instance = Sl

    printHelp = function() Sl:PrintHelp() end
    cliList   = function() Sl:CliList() end
    cliGet    = function(rest) Sl:CliGet(rest) end
    cliSet    = function(rest) Sl:CliSet(rest) end
    -- Sl:CliReset only, never Sl:CliResetAll: the library's resetall walks the
    -- schema rows, and this addon's global reset is KCM.ResetAllToDefaults,
    -- which also wipes the priority lists and the stat overrides — data the
    -- schema does not describe. `/cm resetall` keeps the host body.
    cliReset  = function(rest) Sl:CliReset(rest) end
```

| Slash surface | State | Evidence |
|---|---|---|
| dispatcher (`OnSlash`) | adopted | `core/SlashCommands.lua:1384` |
| `PrintHelp` / `HelpRows` | adopted | `:1352`; pinned byte-for-byte at `tests/test_slashsetup.lua:57-59` |
| `HelpHeader` | adopted | `tests/test_slashsetup.lua:95` |
| `LandingRows` | **not called** | 0 occurrences outside `libs/` — see §6.3 |
| `CliList` / `CliGet` / `CliSet` / `CliReset` | adopted | `:1353`, `:1354`, `:1355`, `:1360` |
| `CliResetAll` | **declined**, recorded inline at `:1356-1359` and in `LIBKA0S-12` | host keeps `KCM.ResetAllToDefaults` |
| `CliVersion` | adopted | via the dispatcher's `version` verb |
| `SetRowAnnotator` | not used | 0 host occurrences |
| `format` (Slash minor 5) | not used | 0 host occurrences; default `lib.FormatValue` suffices |
| `colorDecode`/`colorEncode` | adopted | `:1341-1348` |
| `groupKey` | adopted | `:1338` — rows carry `panel`, not `page` |

Core:

```
$ sed -n '73,99p' core/CoreSetup.lua
KCM.IsConcatSafe = lib.IsConcatSafe
KCM.SafeToString = lib.SafeToString

local printer = lib:New({
    prefix = function() return KCM.PREFIX end,
    sink = function(line) print(line) end,
})
…
KCM.Say = printer.Format
```

| Core surface | State |
|---|---|
| printer (`lib:New` → `.Format`) | adopted, `core/CoreSetup.lua:76-99` |
| `SafeToString` | adopted, `:74` (identity-asserted at `tests/test_coresetup.lua:33`) |
| `IsConcatSafe` | adopted, `:73` (identity-asserted at `tests/test_coresetup.lua:34`) |
| `SECRET` | adopted transitively; asserted as `"<secret>"` at `tests/test_coresetup.lua:41-42` |
| `SKIN` / `ApplySkin` | not called directly by the host (0 host hits) |
| `MakeCloseButton` | not called directly by the host (0 host hits) |

The skin decline, written into `modules/DebugLog.lua:167-171`:

> `skin` is deliberately NOT passed: Core.SKIN is byte-identical to the backdrop this file used to
> carry, and a plain backdrop table would drop the bg/border color arrays the library guards for.
> Nor `L` (the library's English already matches ours) nor `safeToString` (it defaults to Core's,
> which is the same function object KCM.SafeToString is bound to).

DebugLog's host file survives at 208 lines but is a **seam**, not a console — the `lib:New`
descriptor plus a re-publication of the old public names (`:107-172`):

```lua
local D = lib:New({
    name  = "ConsumableMaster",
    title = "Consumable Master",
    font     = fontPath(),
    fontSize = FONT_SIZE,
    isEnabled  = function() return KCM.State and KCM.State.debug == true end,
    setEnabled = function(on) … end,
    print = function(line) KCM.Say(line) end,
    initSummary = function() … end,
    onVisibilityChanged = function() … end,
    slash = "/cm",
})
…
function DL.AddLine(tag, msg)  D:Add(tag, msg) end
function DL.IsEnabled()        return D:IsEnabled() end
function DL.Show()             D:Show() end
```

`modules/PerfSetup.lua` is 103 lines and likewise a pure descriptor (`:61-102`).

The v1.2.0 surface this host gains without asking:

```
$ grep -rn 'OnDefault\|OnCommit\|OnRefresh' --include='*.lua' . | grep -v '/libs/'
(no host-side hit; the only matches are libs/LibKa0s/Options.lua:219-231 and the vendored AceGUI
 BlizOptionsGroup widget)
```

### §5.5 BankLedger

cwd=BL. Every distinct library surface `settings/Panel.lua` reaches off the instance:

```
$ grep -ohE 'O\.[A-Za-z_]+' settings/Panel.lua | sort -u
O.AceGUI
O.AddSpacer
O.BUTTON_PAIR_REL
O.ClearScroll
O.CreateOptionsPanel
O.CreatePanel
O.EnsureScroll
O.OpenOptionsPanel
O.ROW_VSPACER
O.RefreshAllPanels
O.RefreshScalars
O.RegisterOptionsPage
O.RenderSchema
O.SECTION_HEADING_H
O.Section
O.SetMainBuilder
O.SetRenderer
O.__panels

$ grep -noE 'O\.[A-Za-z_]+' settings/Panel.lua | grep -vE ':O\.AceGUI$' | sort -t: -k1 -n
33:O.BUTTON_PAIR_REL
32:O.ROW_VSPACER
68:O.BUTTON_PAIR_REL
73:O.BUTTON_PAIR_REL
123:O.EnsureScroll
227:O.EnsureScroll
233:O.AddSpacer
261:O.AddSpacer
278:O.AddSpacer
311:O.RefreshAllPanels
319:O.EnsureScroll
328:O.AddSpacer
336:O.AddSpacer
344:O.AddSpacer
471:O.RefreshScalars
507:O.ClearScroll
518:O.ClearScroll
524:O.RegisterOptionsPage
526:O.CreatePanel
538:O.ClearScroll
542:O.RenderSchema
559:O.EnsureScroll
561:O.AddSpacer
572:O.RegisterOptionsPage
574:O.CreatePanel
592:O.ClearScroll
600:O.CreateOptionsPanel
607:O.OpenOptionsPanel

$ grep -rn 'O\.RenderSchema\|O\.RenderRows\|O\.RenderGrid\|O\.RenderField' --include='*.lua' . | grep -v '/libs/'
settings/OptionsSetup.lua:13:-- section, the whole Filters page — so a host page helper can call `O.RenderRows` like any other
settings/Panel.lua:542:      O.RenderSchema(c, "general", nil, {

$ grep -rn 'SetRowAnnotator\|HelpRows\|LSMValues' --include='*.lua' . | grep -v '/libs/'
(no output)
```

The Options descriptor (`settings/OptionsSetup.lua:36-94`):

```lua
local descriptor = {
  parentTitle   = PARENT_TITLE,
  mainPanelName = "BankLedgerMainPanel",

  print = function(line) print(line) end,
  debug = function(tag, fmt, ...) if NS.Debug then NS.Debug(tag, fmt, ...) end end,

  get          = function(path) return NS.Schema:Get(path) end,
  set          = function(path, value) NS.Schema:Set(path, value) end,
  applyDefault = function(row) NS.Schema:Set(row.path, NS.Schema:Default(row.path)) end,
  allRows      = function() return NS.Schema.Schema end,

  rowsForPage = function(pageKey)
    if pageKey ~= "general" then return {} end
    return NS.Schema.Schema
  end,

  buildMain = function(ctx)
    if buildMainBody then return buildMainBody(ctx) end
  end,

  onAceGUI = function(AceGUI) NS.AceGUI = AceGUI end,
  validate = function() if NS.Schema.Register then NS.Schema:Register() end end,
  scheduleTimer = function(fn, delay)
    if NS.addon and NS.addon.ScheduleTimer then return NS.addon:ScheduleTimer(fn, delay) end
  end,
}
```

Four deliberate omissions are documented in comments at `settings/OptionsSetup.lua:82-93`: no
`colorDecode`/`colorEncode` (no colour row), no `skipRestoreAll`, no `afterRestoreAll` and no use
of `RestoreAllDefaults` (LIBKA0S-22), no `getLSM` (no LSM-backed row).

| Surface | Used? | Note |
|---|---|---|
| `RenderRows` | yes, indirectly | via `O.RenderSchema` at `settings/Panel.lua:542` |
| `RenderSchema` | yes | `settings/Panel.lua:542` |
| `RenderGrid` | **no** | host draws its store grid and MultiCheck itself (`makeMultiCheck`, LIBKA0S-23) |
| `RenderField` | no (direct) | reached by the flow engine |
| four makers + `makeEditBox` | yes, indirectly | dispatched by `RenderField`; no colour row, so `makeColor` never fires |
| `LSMValues` | **no** | no LSM-backed row (`getLSM` deliberately omitted) |
| `SetRenderer` | yes | `settings/Panel.lua:537`, `:591` |
| `RefreshAllPanels` | yes | `settings/Panel.lua:311`; also `settings/OptionsSetup.lua:148` stub |
| `RefreshScalars` | yes | `settings/Panel.lua:471` (×2) |
| page registry (`RegisterOptionsPage`, `CreateOptionsPanel`, `__pages`, `__panels`) | yes | `settings/Panel.lua:524`, `:572`, `:600`, `:459`, and `tests/test_panel.lua:127/197/223` |
| `CreatePanel` | yes | `settings/Panel.lua:526`, `:574` |
| `OpenOptionsPanel` | yes | `settings/Panel.lua:607` |
| `EnsureScroll` / `ClearScroll` / `Section` / `AddSpacer` | yes | sites listed above |
| layout constants | yes | `settings/Panel.lua:32,33,68,73,561` |
| `InlineButtonPair` | **no** | declined, LIBKA0S-22 |
| `RestoreAllDefaults` | **no** | declined, LIBKA0S-22 — reset stays one host-owned body shared with `/bl resetall` |
| `AttachTooltip` | no (direct) | library calls it internally |

The Slash descriptor and the republished verbs, `settings/Slash.lua:174-249`:

```lua
local cli = lib:New({
  slash        = "/bl",
  slashAliases = { "/bankledger" },
  commands     = NS.COMMANDS,
  print        = function(line) print(line) end,
  version      = function() return Sl:Version() end,

  get          = function(path) return NS.Schema:Get(path) end,
  set          = function(path, v) NS.Schema:Set(path, v) end,
  findRow      = function(path) return NS.Schema:FindRow(path) end,
  allRows      = function() return NS.Schema.Schema end,
  applyDefault = function(row) NS.Schema:Set(row.path, NS.Schema:Default(row.path)) end,

  groupKey = function(row) return row.group or "?" end,

  format = function(row, v)
    local mine = formatValue(row, v)
    if mine ~= nil then return mine end
    return lib.FormatValue(row, v)
  end,

  parse = function(row, text)
    if row and row.type == "table" then
      return nil, "edit this one in the settings panel (/bl config)"
    end
    return lib.ParseValue(row, text)
  end,
})

function Sl:OnSlash(input) return cli:OnSlash(input) end
function Sl:PrintHelp() return cli:PrintHelp() end
function Sl:BuildListLines() return cli:BuildListLines() end
function Sl:CliList() return cli:CliList() end
function Sl:CliGet(rest) return cli:CliGet(rest) end
function Sl:CliSet(rest) return cli:CliSet(rest) end
function Sl:CliReset(rest) return cli:CliReset(rest) end
function Sl:CliVersion() return cli:CliVersion() end
function Sl:LandingRows() return cli:LandingRows() end

function Sl:CliResetAll()
  if NS.Filters and NS.Filters.ClearAll then NS.Filters:ClearAll() end
  if NS.Browser and NS.Browser.ResetView then NS.Browser:ResetView(true) end
  if NS.Panel and NS.Panel.Batch then
    return NS.Panel:Batch(function() cli:CliResetAll() end)
  end
  return cli:CliResetAll()
end
```

| Surface | Used? | Where |
|---|---|---|
| dispatcher (`OnSlash`) | yes | `settings/Slash.lua:215` |
| `HelpRows` | yes, indirectly | via `cli:PrintHelp` (`libs/LibKa0s/Slash.lua:391`); no direct host call |
| `LandingRows` | **yes** | `settings/Slash.lua:228`, consumed at `settings/Panel.lua:346,356` |
| `CliList` / `CliGet` / `CliSet` / `CliReset` | **yes** | `settings/Slash.lua:218`–`:221` |
| `CliResetAll` | yes, wrapped | `settings/Slash.lua:239-249` — carve-outs wrapped **around** the library call, not forked from it |
| `CliVersion` | yes | `settings/Slash.lua:222` |
| `FormatValue` | yes, as fallback | `settings/Slash.lua:201` inside the `format` hook |
| `ParseValue` | yes, as fallback | `settings/Slash.lua:211` inside the `parse` hook |
| `SetRowAnnotator` | **no** | not called |

Core (`core/CoreSetup.lua:76-98`):

```lua
NS.IsConcatSafe = lib.IsConcatSafe
NS.SafeToString = lib.SafeToString

local printer = lib:New({
  prefix = function() return NS.PREFIX end,
})

NS.Print = printer.Print
Util.print = NS.Print
```

| Surface | Used? | Note |
|---|---|---|
| printer (`lib:New`) | **yes** | `core/CoreSetup.lua:88`; function form of `prefix`, no `sep`, no `sink` |
| `SafeToString` | **yes** | `core/CoreSetup.lua:77`; used at `core/Util.lua:168`, `settings/Slash.lua:158` |
| `IsConcatSafe` | **yes** | `core/CoreSetup.lua:76` |
| `SECRET` | no | host never reads the sentinel directly |
| `SKIN` / `ApplySkin` | **DECLINED** | LIBKA0S-05. Host owns its own — `modules/Browser.lua:16,17,35,67,72-85,192,211,218,225,1061-1113,1177` |
| `MakeCloseButton` | **DECLINED** | LIBKA0S-05. Host owns a 24×24 class-coloured × — `modules/Browser.lua:90,1106`; `modules/Export.lua:242,326`; `modules/SessionWindow.lua:482` |

The chrome hooks that decline drove upstream, `core/DebugLogSetup.lua:111-122`:

```lua
  applySkin = function(frame)
    if NS.Browser and NS.Browser.ApplySkin then NS.Browser:ApplySkin(frame) end
  end,

  makeCloseButton = function(parent, onClick)
    if NS.Browser and NS.Browser.MakeCloseButton then
      return NS.Browser:MakeCloseButton(parent, onClick)
    end
    return nil
  end,
```

and `core/DebugLogSetup.lua:125-126`, the `L` decision stated rather than left to omission:

```lua
  -- No `L`. This addon translates none of the console's strings, and handing a descriptor an
  -- addon-wide locale table is the one mistake that renders every label as its own key at once.
```

### §5.6 Cross-consumer surface counts

Two independent sweeps were run. They count different things — the first counts **files**
containing a name, the second counts **lines** — so their numbers differ and neither is a call-site
count on its own. The call sites themselves are verified in §11.1.

Sweep A (files, from AbsorbTracker's slice). cwd=GIT:

```
$ for s in <surface>; do for a in AbsorbTracker KickCD ConsumableMaster BankLedger; do
    grep -rl "$s" $a --include='*.lua' | grep -v '/libs/' | grep -v '/tests/' | wc -l; done; done

SessionCheckbox           AbsorbTracker=2 KickCD=2 ConsumableMaster=1 BankLedger=1
InlineButtonPair          AbsorbTracker=2 KickCD=3 ConsumableMaster=0 BankLedger=1
SetRenderer               AbsorbTracker=0 KickCD=0 ConsumableMaster=5 BankLedger=2
RestoreAllDefaults        AbsorbTracker=4 KickCD=3 ConsumableMaster=0 BankLedger=1
RefreshScalars            AbsorbTracker=0 KickCD=0 ConsumableMaster=1 BankLedger=2
LSMValues                 AbsorbTracker=4 KickCD=5 ConsumableMaster=2 BankLedger=0
SetRowAnnotator           AbsorbTracker=1 KickCD=1 ConsumableMaster=0 BankLedger=0
CliResetAll               AbsorbTracker=0 KickCD=0 ConsumableMaster=1 BankLedger=5
RenderGrid                AbsorbTracker=2 KickCD=0 ConsumableMaster=1 BankLedger=1
LandingRows               AbsorbTracker=2 KickCD=3 ConsumableMaster=0 BankLedger=2
RenderSchema              AbsorbTracker=4 KickCD=6 ConsumableMaster=0 BankLedger=2
EnsureDefaultsButton      AbsorbTracker=5 KickCD=7 ConsumableMaster=1 BankLedger=1
Section                   AbsorbTracker=2 KickCD=2 ConsumableMaster=6 BankLedger=5
AddSpacer                 AbsorbTracker=2 KickCD=4 ConsumableMaster=3 BankLedger=2
ClearScroll               AbsorbTracker=2 KickCD=3 ConsumableMaster=1 BankLedger=2
EnsureScroll              AbsorbTracker=3 KickCD=4 ConsumableMaster=5 BankLedger=2
RenderField               AbsorbTracker=2 KickCD=4 ConsumableMaster=1 BankLedger=2
OpenOptionsPanel          AbsorbTracker=2 KickCD=1 ConsumableMaster=0 BankLedger=2
CreateOptionsPanel        AbsorbTracker=2 KickCD=1 ConsumableMaster=1 BankLedger=2
AttachTooltip             AbsorbTracker=2 KickCD=2 ConsumableMaster=4 BankLedger=1
PatchAlwaysShowScrollbar  AbsorbTracker=1 KickCD=3 ConsumableMaster=1 BankLedger=0
CliList/CliGet/CliSet     AbsorbTracker=1 KickCD=1 ConsumableMaster=1 BankLedger=2
CliReset                  AbsorbTracker=1 KickCD=1 ConsumableMaster=1 BankLedger=5
HelpRows                  AbsorbTracker=0 KickCD=2 ConsumableMaster=0 BankLedger=0
FormatRow                 AbsorbTracker=1 KickCD=0 ConsumableMaster=0 BankLedger=0
FormatValue               AbsorbTracker=1 KickCD=1 ConsumableMaster=1 BankLedger=1
SafeToString              AbsorbTracker=3 KickCD=3 ConsumableMaster=3 BankLedger=4
MakeCloseButton           AbsorbTracker=2 KickCD=2 ConsumableMaster=0 BankLedger=4
.SKIN                     AbsorbTracker=0 KickCD=0 ConsumableMaster=1 BankLedger=3
BuildListLines            AbsorbTracker=0 KickCD=0 ConsumableMaster=0 BankLedger=1
ConsoleCheckbox           AbsorbTracker=2 KickCD=1 ConsumableMaster=1 BankLedger=0
```

Sweep B (lines, from ConsumableMaster's slice). cwd=GIT:

```
$ for s in RenderGrid RenderRows SessionCheckbox RenderField sliderCommit LSMValues SetRowAnnotator CliResetAll LandingRows CliList CliGet CliSet CliReset RegisterOptionsPage CreateOptionsPanel applySkin makeCloseButton MakeCloseButton ApplySkin; do … done

surface                AbsorbTracker  KickCD  ConsumableMaster  BankLedger
RenderGrid                    9          1           5              1
RenderRows                   39         27           4              3
SessionCheckbox              12          5           2              1
RenderField                  22         19           7              3
sliderCommit                  0          0           4              0     <-- SOLE CONSUMER
LSMValues                    67         21          10              0
SetRowAnnotator               3          1           0              0
CliResetAll                   0          1           2             23
LandingRows                  14          6           0              5
CliList                       1          1           2              3
CliGet                        1          1           4              6
CliSet                        3          1           2             10
CliReset                      1          3           5             35
RegisterOptionsPage          30          2           0              4
CreateOptionsPanel           40          3           1              5
applySkin                     0          0           0              3
makeCloseButton               0          0           0              3
MakeCloseButton               7          4           0             13
ApplySkin                     2          3           0             18
```

Read these with the collector's own caveats: ConsumableMaster's `RenderRows` count of 4 is comment
text at `settings/Panel.lua:510-515`, not call sites, and its `CliResetAll` count of 2 is the two
comment lines at `:1356-1357` declining it.

Sweep C (lines, from the cross-cutting slice), which covers the lib-level members, the Options
instance surface and the Slash instance surface. cwd=GIT:

```
$ for s in SafeToString IsConcatSafe SECRET SKIN ApplySkin MakeCloseButton FormatPlain FormatColored MAX_BUFFER FormatRow FormatKV FormatValue ParseValue EncodeJSON DEFAULT_RING; do … done
SafeToString: AbsorbTracker=9 BankLedger=7 ConsumableMaster=9 KickCD=9
IsConcatSafe: AbsorbTracker=6 BankLedger=4 ConsumableMaster=3 KickCD=3
SECRET: AbsorbTracker=0 BankLedger=0 ConsumableMaster=2 KickCD=0
SKIN: AbsorbTracker=0 BankLedger=18 ConsumableMaster=1 KickCD=0
ApplySkin: AbsorbTracker=0 BankLedger=8 ConsumableMaster=0 KickCD=0
MakeCloseButton: AbsorbTracker=3 BankLedger=11 ConsumableMaster=0 KickCD=4
FormatPlain: AbsorbTracker=0 BankLedger=0 ConsumableMaster=1 KickCD=3
FormatColored: AbsorbTracker=0 BankLedger=0 ConsumableMaster=1 KickCD=2
MAX_BUFFER: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
FormatRow: AbsorbTracker=3 BankLedger=0 ConsumableMaster=0 KickCD=0
FormatKV: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
FormatValue: AbsorbTracker=1 BankLedger=2 ConsumableMaster=1 KickCD=1
ParseValue: AbsorbTracker=1 BankLedger=1 ConsumableMaster=0 KickCD=2
EncodeJSON: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
DEFAULT_RING: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0

$ for s in RenderRows RenderGrid RenderSchema RenderField SessionCheckbox InlineButtonPair Section AddSpacer AttachTooltip LSMValues SetRenderer RefreshAllPanels RefreshScalars RegisterOptionsPage CreateOptionsPanel OpenOptionsPanel CreatePanel EnsureScroll ClearScroll RestoreDefaults RestoreAllDefaults EnsureDefaultsButton PatchAlwaysShowScrollbar; do … done
RenderRows: AbsorbTracker=8 BankLedger=3 ConsumableMaster=1 KickCD=9
RenderGrid: AbsorbTracker=4 BankLedger=1 ConsumableMaster=3 KickCD=0
RenderSchema: AbsorbTracker=5 BankLedger=3 ConsumableMaster=0 KickCD=17
RenderField: AbsorbTracker=2 BankLedger=2 ConsumableMaster=1 KickCD=4
SessionCheckbox: AbsorbTracker=2 BankLedger=1 ConsumableMaster=2 KickCD=4
InlineButtonPair: AbsorbTracker=2 BankLedger=1 ConsumableMaster=0 KickCD=4
Section: AbsorbTracker=2 BankLedger=7 ConsumableMaster=23 KickCD=3
AddSpacer: AbsorbTracker=2 BankLedger=8 ConsumableMaster=8 KickCD=4
AttachTooltip: AbsorbTracker=4 BankLedger=1 ConsumableMaster=9 KickCD=2
LSMValues: AbsorbTracker=11 BankLedger=0 ConsumableMaster=5 KickCD=13
SetRenderer: AbsorbTracker=0 BankLedger=3 ConsumableMaster=8 KickCD=0
RefreshAllPanels: AbsorbTracker=8 BankLedger=6 ConsumableMaster=13 KickCD=8
RefreshScalars: AbsorbTracker=0 BankLedger=3 ConsumableMaster=4 KickCD=0
RegisterOptionsPage: AbsorbTracker=12 BankLedger=3 ConsumableMaster=0 KickCD=2
CreateOptionsPanel: AbsorbTracker=4 BankLedger=3 ConsumableMaster=1 KickCD=3
OpenOptionsPanel: AbsorbTracker=3 BankLedger=3 ConsumableMaster=0 KickCD=2
CreatePanel: AbsorbTracker=7 BankLedger=4 ConsumableMaster=9 KickCD=13
EnsureScroll: AbsorbTracker=4 BankLedger=5 ConsumableMaster=7 KickCD=5
ClearScroll: AbsorbTracker=4 BankLedger=5 ConsumableMaster=2 KickCD=6
RestoreDefaults: AbsorbTracker=8 BankLedger=4 ConsumableMaster=0 KickCD=9
RestoreAllDefaults: AbsorbTracker=8 BankLedger=2 ConsumableMaster=0 KickCD=7
EnsureDefaultsButton: AbsorbTracker=9 BankLedger=1 ConsumableMaster=1 KickCD=13
PatchAlwaysShowScrollbar: AbsorbTracker=1 BankLedger=0 ConsumableMaster=1 KickCD=6

$ for s in HelpRows LandingRows HelpHeader PrintHelp BuildListLines CliList CliGet CliSet CliReset CliResetAll CliVersion OnSlash SetRowAnnotator Text; do … done
HelpRows: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=3
LandingRows: AbsorbTracker=5 BankLedger=4 ConsumableMaster=0 KickCD=6
HelpHeader: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
PrintHelp: AbsorbTracker=4 BankLedger=5 ConsumableMaster=1 KickCD=5
BuildListLines: AbsorbTracker=0 BankLedger=2 ConsumableMaster=0 KickCD=0
CliList: AbsorbTracker=1 BankLedger=3 ConsumableMaster=2 KickCD=1
CliGet: AbsorbTracker=1 BankLedger=3 ConsumableMaster=3 KickCD=1
CliSet: AbsorbTracker=1 BankLedger=3 ConsumableMaster=2 KickCD=1
CliReset: AbsorbTracker=1 BankLedger=3 ConsumableMaster=3 KickCD=1
CliResetAll: AbsorbTracker=0 BankLedger=13 ConsumableMaster=1 KickCD=0
CliVersion: AbsorbTracker=0 BankLedger=3 ConsumableMaster=0 KickCD=1
OnSlash: AbsorbTracker=5 BankLedger=5 ConsumableMaster=1 KickCD=4
SetRowAnnotator: AbsorbTracker=2 BankLedger=0 ConsumableMaster=0 KickCD=1
Text: AbsorbTracker=0 BankLedger=1 ConsumableMaster=2 KickCD=16
```

### §5.7 Descriptor fields, per consumer

cwd=GIT

```
$ for s in initSummary onVisibilityChanged safeToString fontSize font skin applySkin makeCloseButton afterRestoreAll allRows applyDefault buildMain getLSM mainPanelName onAceGUI parentTitle rowsForPage skipRestoreAll validate colorDecode colorEncode scheduleTimer sliderCommit findRow groupKey aliases slashAliases parse format decorate buckets ring showLog suspend resume sv log debug; do … grep -rnE "^\s*$s\s*=" … done
initSummary: AbsorbTracker=1 BankLedger=1 ConsumableMaster=1 KickCD=1
onVisibilityChanged: AbsorbTracker=1 BankLedger=1 ConsumableMaster=1 KickCD=1
safeToString: AbsorbTracker=1 BankLedger=0 ConsumableMaster=0 KickCD=1
fontSize: AbsorbTracker=1 BankLedger=0 ConsumableMaster=1 KickCD=1
font: AbsorbTracker=2 BankLedger=1 ConsumableMaster=1 KickCD=3
skin: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
applySkin: AbsorbTracker=0 BankLedger=1 ConsumableMaster=0 KickCD=0
makeCloseButton: AbsorbTracker=0 BankLedger=1 ConsumableMaster=0 KickCD=0
afterRestoreAll: AbsorbTracker=1 BankLedger=0 ConsumableMaster=0 KickCD=1
allRows: AbsorbTracker=2 BankLedger=2 ConsumableMaster=1 KickCD=2
applyDefault: AbsorbTracker=2 BankLedger=2 ConsumableMaster=1 KickCD=2
buildMain: AbsorbTracker=1 BankLedger=1 ConsumableMaster=0 KickCD=1
getLSM: AbsorbTracker=1 BankLedger=0 ConsumableMaster=1 KickCD=1
mainPanelName: AbsorbTracker=1 BankLedger=1 ConsumableMaster=1 KickCD=1
onAceGUI: AbsorbTracker=1 BankLedger=1 ConsumableMaster=0 KickCD=1
parentTitle: AbsorbTracker=1 BankLedger=1 ConsumableMaster=1 KickCD=1
rowsForPage: AbsorbTracker=1 BankLedger=1 ConsumableMaster=0 KickCD=1
skipRestoreAll: AbsorbTracker=1 BankLedger=0 ConsumableMaster=0 KickCD=1
validate: AbsorbTracker=1 BankLedger=1 ConsumableMaster=0 KickCD=1
colorDecode: AbsorbTracker=1 BankLedger=0 ConsumableMaster=2 KickCD=1
colorEncode: AbsorbTracker=1 BankLedger=0 ConsumableMaster=2 KickCD=1
scheduleTimer: AbsorbTracker=1 BankLedger=1 ConsumableMaster=0 KickCD=1
sliderCommit: AbsorbTracker=0 BankLedger=0 ConsumableMaster=1 KickCD=0
findRow: AbsorbTracker=1 BankLedger=1 ConsumableMaster=1 KickCD=1
groupKey: AbsorbTracker=1 BankLedger=1 ConsumableMaster=1 KickCD=1
aliases: AbsorbTracker=1 BankLedger=0 ConsumableMaster=1 KickCD=1
slashAliases: AbsorbTracker=1 BankLedger=1 ConsumableMaster=1 KickCD=1
parse: AbsorbTracker=0 BankLedger=1 ConsumableMaster=0 KickCD=1
format: AbsorbTracker=0 BankLedger=1 ConsumableMaster=0 KickCD=0
decorate: AbsorbTracker=1 BankLedger=0 ConsumableMaster=0 KickCD=1
buckets: AbsorbTracker=1 BankLedger=0 ConsumableMaster=1 KickCD=1
ring: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
showLog: AbsorbTracker=1 BankLedger=0 ConsumableMaster=1 KickCD=1
suspend: AbsorbTracker=1 BankLedger=0 ConsumableMaster=1 KickCD=1
resume: AbsorbTracker=1 BankLedger=0 ConsumableMaster=1 KickCD=1
sv: AbsorbTracker=1 BankLedger=0 ConsumableMaster=1 KickCD=1
log: AbsorbTracker=1 BankLedger=0 ConsumableMaster=1 KickCD=1
debug: AbsorbTracker=1 BankLedger=1 ConsumableMaster=0 KickCD=1
```

The same question asked with the assignment lines printed rather than counted (cwd=GIT):

```
$ for f in format applySkin makeCloseButton groupKey buildMain onAceGUI validate scheduleTimer skipRestoreAll afterRestoreAll getLSM colorDecode colorEncode sliderCommit; do printf '\n--- %s = ---\n' "$f"; grep -rnE "^\s*${f}\s*=" AbsorbTracker KickCD ConsumableMaster BankLedger --include='*.lua' 2>/dev/null | grep -v '/libs/' | grep -v '/tests/' | cut -c1-120; done

--- format = ---
BankLedger/settings/Slash.lua:198:  format = function(row, v)

--- applySkin = ---
BankLedger/core/DebugLogSetup.lua:111:  applySkin = function(frame)

--- makeCloseButton = ---
BankLedger/core/DebugLogSetup.lua:115:  makeCloseButton = function(parent, onClick)

--- groupKey = ---
AbsorbTracker/settings/Slash.lua:448:    groupKey = function(row)
KickCD/settings/Slash.lua:329:    groupKey = function(row) return row.panel or "?" end,
ConsumableMaster/core/SlashCommands.lua:1336:        groupKey     = function(row) return row.panel or "?" end,
BankLedger/settings/Slash.lua:193:  groupKey = function(row) return row.group or "?" end,

--- buildMain = ---
AbsorbTracker/settings/OptionsSetup.lua:87:    buildMain = function(ctx)
KickCD/settings/OptionsSetup.lua:118:    buildMain = function(ctx)
BankLedger/settings/OptionsSetup.lua:61:  buildMain = function(ctx)

--- onAceGUI = ---
AbsorbTracker/settings/OptionsSetup.lua:83:    onAceGUI = function(AceGUI) NS.AceGUI = AceGUI end,
KickCD/settings/OptionsSetup.lua:113:    onAceGUI = function(AceGUI) NS.AceGUI = AceGUI end,
BankLedger/settings/OptionsSetup.lua:67:  onAceGUI = function(AceGUI) NS.AceGUI = AceGUI end,

--- validate = ---
AbsorbTracker/settings/OptionsSetup.lua:79:    validate = function() NS.ValidateSchema() end,
KickCD/settings/OptionsSetup.lua:105:    validate = function()
BankLedger/settings/OptionsSetup.lua:72:  validate = function() if NS.Schema.Register then NS.Schema:Register() end end,

--- scheduleTimer = ---
AbsorbTracker/settings/OptionsSetup.lua:76:    scheduleTimer = function(fn, delay) return NS.addon:ScheduleTimer(fn, del
KickCD/settings/OptionsSetup.lua:102:    scheduleTimer = function(fn, delay) return C_Timer.After(delay, fn) end,
BankLedger/settings/OptionsSetup.lua:78:  scheduleTimer = function(fn, delay)

--- skipRestoreAll = ---
AbsorbTracker/settings/OptionsSetup.lua:62:    skipRestoreAll = vetoedFromResetAll,
KickCD/settings/OptionsSetup.lua:85:    skipRestoreAll = vetoedFromResetAll,

--- afterRestoreAll = ---
AbsorbTracker/settings/OptionsSetup.lua:69:    afterRestoreAll = function()
KickCD/settings/OptionsSetup.lua:93:    afterRestoreAll = function()

--- getLSM = ---
AbsorbTracker/settings/OptionsSetup.lua:78:    getLSM   = function() return NS.GetLSM() end,
KickCD/settings/OptionsSetup.lua:104:    getLSM   = function() return LibStub and LibStub("LibSharedMedia-3.0", true) en
ConsumableMaster/settings/Panel.lua:231:        getLSM = function() return LibStub and LibStub("LibSharedMedia-3.0", tru

--- colorDecode = ---
AbsorbTracker/settings/OptionsSetup.lua:95:    colorDecode = function(c)
KickCD/settings/OptionsSetup.lua:129:    colorDecode = function(c)
ConsumableMaster/core/SlashCommands.lua:1342:        colorDecode  = function(c)
ConsumableMaster/settings/Panel.lua:216:        colorDecode = function(c)

--- colorEncode = ---
AbsorbTracker/settings/OptionsSetup.lua:99:    colorEncode = function(r, g, b, a) return { r = r, g = g, b = b, a = a or
KickCD/settings/OptionsSetup.lua:133:    colorEncode = function(r, g, b, a) return { r = r, g = g, b = b, a = a or 1 } e
ConsumableMaster/core/SlashCommands.lua:1346:        colorEncode  = function(r, g, b, a) return { r, g, b, a or 1 } end,
ConsumableMaster/settings/Panel.lua:216:        colorEncode = function(r, g, b, a) return { r, g, b, a or 1 } end,

--- sliderCommit = ---
ConsumableMaster/settings/Panel.lua:226:        sliderCommit = "change",
```

### §5.8 The Perf imperative API

cwd=GIT

```
$ grep -rnE "Perf\.(Measure|Context|Progress|Cancel|Start|Reset|Save|Resume|ShowPanel|TogglePanel|HidePanel|IsPanelShown|Log|Announce|MarkReviewed|StatusLines|FormatReport|BuildRecord|EncodeJSON)" AbsorbTracker BankLedger ConsumableMaster KickCD --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'; echo "exit=$? (1 = no matches anywhere)"
exit=1 (1 = no matches anywhere)

$ grep -rnE 'Perf\.(Note|OnCommand)' AbsorbTracker BankLedger ConsumableMaster KickCD --include='*.lua' | grep -v '/libs/' | grep -v '/tests/' | head -20
AbsorbTracker/core/AbsorbTracker.lua:184:    if t0 then Perf.Note("absorbEvent", debugprofilestop() - t0) end
AbsorbTracker/modules/Timer.lua:41:    if t0 then Perf.Note("repaintPass", debugprofilestop() - t0) end
AbsorbTracker/modules/Display.lua:105:    if t0 then Perf.Note("appearance", debugprofilestop() - t0) end
AbsorbTracker/modules/Display.lua:165:    if t0 then Perf.Note("visibility", debugprofilestop() - t0) end
AbsorbTracker/modules/Display.lua:202:    if t0 then Perf.Note("paintBar", debugprofilestop() - t0) end
AbsorbTracker/settings/Slash.lua:202:    for _, line in ipairs(NS.Perf.OnCommand(rest or "")) do print(line) end
ConsumableMaster/core/SlashCommands.lua:1146:            if not (KCM.Perf and KCM.Perf.OnCommand) then
ConsumableMaster/core/SlashCommands.lua:1149:            for _, line in ipairs(KCM.Perf.OnCommand(rest)) do say(line) end
KickCD/core/KickCD.lua:185:            for _, line in ipairs(NS.Perf.OnCommand(rest or "")) do p(NS, line) end
KickCD/modules/IconGrid_Render.lua:720:    if __t0 then Perf.Note("iconApply", debugprofilestop() - __t0) end
KickCD/modules/IconGrid_Render.lua:817:    if __t0 then Perf.Note("cdText", debugprofilestop() - __t0) end
KickCD/modules/Castbar.lua:716:    if __t0 then Perf.Note("castTick", debugprofilestop() - __t0) end
KickCD/modules/IconGrid.lua:785:    if __t0 then Perf.Note("spellState", debugprofilestop() - __t0) end
KickCD/modules/IconGrid.lua:904:    if __t0 then Perf.Note("visibility", debugprofilestop() - __t0) end
KickCD/modules/IconGrid.lua:918:    if __t0 then Perf.Note("castEvent", debugprofilestop() - __t0) end
KickCD/modules/Cooldowns.lua:109:        if __t0 then Perf.Note("pollSpell", debugprofilestop() - __t0) end
KickCD/modules/Cooldowns.lua:117:        if __t0 then Perf.Note("pollSpell", debugprofilestop() - __t0) end
KickCD/modules/Cooldowns.lua:128:        if __t0 then Perf.Note("pollSpell", debugprofilestop() - __t0) end
KickCD/modules/Cooldowns.lua:197:    if __t0 then Perf.Note("pollSpell", debugprofilestop() - __t0) end
KickCD/modules/Cooldowns.lua:443:    if __t0 then Perf.Note("spellPoll", debugprofilestop() - __t0) end

$ for s in BUCKET_ORDER LABELS EXPERIMENTS STEPS PanelStateOf PanelIsActionable StatusLines ContextLines FormatReport BuildRecord MarkReviewed; do … done
BUCKET_ORDER: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
LABELS: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
EXPERIMENTS: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
STEPS: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
PanelStateOf: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
PanelIsActionable: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
StatusLines: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
ContextLines: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
FormatReport: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
BuildRecord: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
MarkReviewed: AbsorbTracker=0 BankLedger=0 ConsumableMaster=0 KickCD=0
```

`Perf.lua` is 982 lines and `PerfPanel.lua` 247; every host reaches them through `Perf.Note`,
`Perf.OnCommand` and the plain flags only.

---

## §6 — The two convergences

### §6.1 Four-consumer view

cwd=GIT

```
$ grep -rn 'CliReset' AbsorbTracker BankLedger ConsumableMaster KickCD --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
AbsorbTracker/settings/Slash.lua:159:function runReset(rest) cli:CliReset(rest) end
BankLedger/settings/Schema.lua:237:  { "reset",    "Reset one setting",       function(a) NS.Slash:CliReset(a) end },
BankLedger/settings/Slash.lua:123:  function Sl:CliReset() print(UNAVAILABLE) end
BankLedger/settings/Slash.lua:221:function Sl:CliReset(rest) return cli:CliReset(rest) end
ConsumableMaster/core/SlashCommands.lua:1285:    -- string — Sl:CliReset formats it with (d.slash) alone, so ONE %s, and
ConsumableMaster/core/SlashCommands.lua:1356:    -- Sl:CliReset only, never Sl:CliResetAll: the library's resetall walks the
ConsumableMaster/core/SlashCommands.lua:1360:    cliReset  = function(rest) Sl:CliReset(rest) end
KickCD/settings/Slash.lua:189:    NS.Slash.cli:CliReset(rest)

$ grep -rn 'LandingRows' AbsorbTracker BankLedger ConsumableMaster KickCD --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
AbsorbTracker/settings/About.lua:4:-- one-liner, "Slash Commands" heading, and one row per NS.Slash:LandingRows()
AbsorbTracker/settings/About.lua:93:    for _, row in ipairs(NS.Slash:LandingRows()) do
AbsorbTracker/settings/Slash.lua:394:        stub.LandingRows = function()
AbsorbTracker/settings/Slash.lua:403:            for _, row in ipairs(stub.LandingRows()) do print("  " .. row) end
AbsorbTracker/settings/Slash.lua:461:function Sl:LandingRows() return cli:LandingRows() end
BankLedger/settings/Panel.lua:346:  -- Rendered through NS.Slash:LandingRows(), which is LibKa0s-Slash-1.0's ONE command-row
BankLedger/settings/Panel.lua:356:  for _, row in ipairs((NS.Slash and NS.Slash.LandingRows and NS.Slash:LandingRows()) or {}) do
BankLedger/settings/Slash.lua:125:  function Sl:LandingRows() return { UNAVAILABLE } end
BankLedger/settings/Slash.lua:228:function Sl:LandingRows() return cli:LandingRows() end
KickCD/core/KickCD.lua:244:    -- through LandingRows, un-indented, so the two can no longer drift.
KickCD/settings/Panel.lua:519:    -- through (NS.Slash:LandingRows -> LibKa0s-Slash-1.0's one row formatter),
KickCD/settings/Panel.lua:531:    for _, text in ipairs(NS.Slash and NS.Slash:LandingRows() or {}) do
KickCD/settings/Slash.lua:225:        stub.LandingRows = function()
KickCD/settings/Slash.lua:234:            for _, r in ipairs(stub.LandingRows()) do rows[#rows + 1] = "  " .. r end
KickCD/settings/Slash.lua:344:function NS.Slash:LandingRows() return NS.Slash.cli:LandingRows() end
```

**Convergence #1 — `reset` takes a PATH, not a page: 4/4 adopted.**
**Convergence #2 — the landing page renders through the one row formatter: 3 adopted, 1 in
dispute.** ConsumableMaster returns no `LandingRows` hit; whether that is "not applicable" or a
live undocumented decline is settled in §6.3, which shows the grep misses the host's indirection.

### §6.2 AbsorbTracker — both adopted

cwd=AT

```
$ sed -n '152,160p' settings/Slash.lua
-- ---------------------------------------------------------------------
-- /at reset / /at resetall / /at resetposition
-- ---------------------------------------------------------------------

-- `/at reset <path>` resets ONE setting, which is the shape the whole collection uses. The
-- page-shaped form this addon used to carry is gone: a page is a property of a settings panel,
-- and every schema-driven page already has a Defaults button that resets it across every unit.
-- That path is untouched — see NS.Helpers.RestoreDefaults and tests/test_helpers.lua.
function runReset(rest) cli:CliReset(rest) end

$ grep -n 'reset' settings/Slash.lua | sed -n '1,4p'
settings/Slash.lua:72:    {"reset",        "Reset one setting to its default \226\128\148 `/at reset <path>`",
settings/Slash.lua:74:    {"resetall",      "Reset every setting to defaults",

$ sed -n '459,462p' settings/Slash.lua
--- The command list the About page renders. Same coloring and spacing as `/at help`, without the
--- chat indent: each row there is its own label, where a leading indent reads as a mistake.
function Sl:LandingRows() return cli:LandingRows() end

$ sed -n '91,94p' settings/About.lua
    -- 4) Slash-command rows, rendered by the same formatter `/at help` uses so the two can never
    -- drift. Adding a command to NS.COMMANDS surfaces here automatically.
    for _, row in ipairs(NS.Slash:LandingRows()) do
```

Pinned by `tests/test_slashcmds.lua:192`–`:265` (reset) and `:67`–`:84` (landing rows). Neither
convergence is declined, so this consumer had no decision to record. The ledger was read anyway:

```
$ ls docs/pending/
LEDGER.md

$ grep -inE 'libka0s|reset|landing|converg' docs/pending/LEDGER.md
37:| ISS-19  | ... the probe moved into LibKa0s and `core/Perf.lua` no longer exists here ...
39:| PLAN-04 | ... `NS.LIBKA0S_MISSING` in `core/CoreSetup.lua` is the single cause clause, and all
         five seams append their own "so <what> is unavailable".
50:| LIBKA0S-01 | 🟢 done | Re-vendored `libs/LibKa0s/` and `tests/_kit/` whole-folder from
         LibKa0s v1.1.0. ... All eight minors unmoved (Core 2, DebugLog 3, Slash 4, Options 4,
         OptionsWidgets 4, OptionsScroll 2, Perf 5, PerfPanel 3). ...
51:| LIBKA0S-02 | 🟢 done | ... `settings/UnitPanel.lua`'s mirror header hand-rolled `RenderGrid`'s
         flow engine verbatim ... Now expressed as four `RenderGrid` items ...
52:| LIBKA0S-03 | 🟢 done | The `L`-trap guard, which this repo had none of. Twelve cases ...
53:| LIBKA0S-04 | 🟢 done | `README.md` grew a **Credits and libraries** section naming LibKa0s
         v1.1.0 (MIT). ... No `CHANGELOG.md` exists in this repo, so the README is the whole
         record; the line has to be moved by hand at each re-vendor.
54:| LIBKA0S-05 | 🔵 wont-do | `settings/About.lua:93` ... is **not** converted to `RenderGrid` ...
         **The finding, for upstream:** `RenderGrid` expresses a caller-driven list of two-column
         FORM widgets but not a caller-driven list of dense single-column TEXT lines ... Preferred
         remedy is an item-level `tight = true` ... Revisit when that lands.
```

The ledger's last entry is `LIBKA0S-05`. There is **no `LIBKA0S-06` recording the v1.2.0
re-vendor**, and `LIBKA0S-01`'s quoted minors (`DebugLog 3, Slash 4, Options 4, OptionsWidgets 4`)
are now four release-old numbers stated in the present tense.

### §6.3 ConsumableMaster — #1 adopted and recorded; #2 declined and undocumented

cwd=CM. Convergence #1:

```
$ sed -n '1360p' core/SlashCommands.lua
    cliReset  = function(rest) Sl:CliReset(rest) end
```

Recorded in two places — `docs/pending/LEDGER.md:68`, `LIBKA0S-12`:

> | LIBKA0S-12 | `reset-convergence` | adoption report 2026-08-01 — deviations §3, recommendations §3
> Option A | 🟢 done | 2026-08-01 | The user chose Option A: converge, keep the guard. `/cm reset
> <path>` is now the library's `Sl:CliReset` — one schema row back to its `default`, path resolved
> through `findRow`, case preserved — which is what `reset` means in `/at` and `/kcd` and now means
> here. The confirm-gated global wipe moved to `/cm resetall` **intact**: same `KCM_CONFIRM_RESET`
> dialog, same wording, same `KCM.ResetAllToDefaults` body, only the verb that raises it changed. …
> `Sl:CliResetAll` is deliberately NOT taken: it walks the schema rows, and this addon's global reset
> also wipes `categories` and `statPriority`, which the schema does not describe. The break ships
> loudly rather than silently — `USAGE_RESET` is overridden to say the verb resets one setting and to
> name `/cm resetall` in gold … A new `CHANGELOG.md` carries the breaking entry; this repo had none,
> and a user-visible break is exactly what one is for. No version bump. The report's finding was that
> this divergence existed with **zero** occurrences of "reset" anywhere in this ledger; that is what
> this row closes. Three cases pin it … Each was verified red first, and the two obvious wrong moves
> were mutated in: making `resetall` wipe without asking, and pointing `reset` back at the popup. |

and `CHANGELOG.md:14-30`:

```
- **`/cm reset` no longer wipes everything. It now resets ONE setting, and the
  global wipe moved to `/cm resetall`.**
  `/cm reset <path>` puts a single settings row back to its default, e.g.
  `/cm reset macroBar.orientation`. It touches nothing else — your priority …
  `/cm resetall` is the old command under a new name, unchanged in every other
  respect: same wording, same confirmation dialog, same wipe. The **Reset all …
  **If you have `/cm reset` in a macro or a keybind, change it to
  `/cm resetall`.** A bare `/cm reset` prints a usage line that says so rather …
  runs the safe way. This brings `/cm` in line with `/at reset <path>` and
  `/kcd reset <path>` across the Ka0s addons, where `reset` has always taken a
```

The deprecation is wired through the descriptor's `L` (`core/SlashCommands.lua:1284-1288`):

```lua
    USAGE_RESET     = "Usage: %s reset <path> \226\128\148 this resets ONE setting. " ..
                      "The old global wipe is now |cffffff00/cm resetall|r, " ..
                      "which still asks before it wipes.",
```

Convergence #2. The prior run's evidence was a grep of `settings/` for `COMMANDS`, which does
return nothing:

```
$ grep -rn 'COMMANDS' settings/
(none)
```

But the command rows reach the landing page through an indirection that grep does not see:

```
$ grep -rn 'GetCommandSummary\|LandingRows\|BuildAboutContent' --include='*.lua' . | grep -v '/libs/'
core/SlashCommands.lua:1254:-- note and it matters here: KCM.SlashCommands.GetCommandSummary below renders
core/SlashCommands.lua:1374:function KCM.SlashCommands.GetCommandSummary()
settings/Panel.lua:674:function Helpers.BuildAboutContent(ctx)
settings/Panel.lua:718:    local rows = (KCM.SlashCommands and KCM.SlashCommands.GetCommandSummary)
settings/Panel.lua:719:        and KCM.SlashCommands.GetCommandSummary() or {}
settings/Panel.lua:770:    Helpers.SetRenderer(mainCtx, Helpers.BuildAboutContent)
tests/test_perfsetup.lua:103, tests/test_slash.lua:128,151 (test-side iteration)

$ sed -n '707,730p' settings/Panel.lua
    local heading = AceGUI:Create("Heading")
    …
    heading:SetText(L["Slash Commands"])
    …
    local rows = (KCM.SlashCommands and KCM.SlashCommands.GetCommandSummary)
        and KCM.SlashCommands.GetCommandSummary() or {}
    for _, entry in ipairs(rows) do
        local row = AceGUI:Create("Label")
        row:SetFullWidth(true)
        row:SetText(("|cffffff00/cm %s|r  |cffffffff—|r  %s")
            :format(entry.name or entry[1] or "", entry.desc or entry[2] or ""))
        …
        scroll:AddChild(row)
    end
end
```

The byte-level comparison of the two formatters, which is the load-bearing evidence because the
divergence is entirely whitespace and colour spans:

```
$ sed -n '723,724p' settings/Panel.lua | od -c | head -4
0000000                                   r   o   w   :   S   e   t   T
0000020   e   x   t   (   (   "   |   c   f   f   f   f   f   f   0   0
0000040   /   c   m       %   s   |   r           |   c   f   f   f   f
0000060   f   f   f   f 342 200 224   |   r           %   s   "   )  \r

$ sed -n '69,70p' ../LibKa0s/LibKa0s/Slash.lua | od -c | head -4
0000000           r   e   t   u   r   n       (   "   |   c   F   F   F
0000020   F   F   F   0   0   %   s   |   r       \   2   2   6   \   1
0000040   2   8   \   1   4   8       |   c   F   F   F   F   F   F   F
0000060   F   %   s   |   r   "   )   :   f   o   r   m   a   t   (   t
```

| | Host About page | `lib.FormatRow` |
|---|---|---|
| spacing round the em dash | **two** spaces each side | **one** space each side |
| the em dash | wrapped `|cffffffff—|r` (white) | bare |
| the description | **bare**, uncoloured | wrapped `|cFFFFFFFF…|r` |
| the command | `|cffffff00…|r` | `|cFFFFFF00…|r` (same colour, different case) |

The chat half is already the library's, so this host carries two divergent formatters for the same
data:

```
$ sed -n '57,59p' tests/test_slashsetup.lua
    t.eq(KCM.SlashCommands.instance:HelpRows()[1],
        "  " .. lib.FormatRow("/cm " .. first[1], first[2]),
        "the first help row is lib.FormatRow's output, indented")
```

The formatter predates the adoption:

```
$ git log --oneline -3 -L 718,729:settings/Panel.lua
f844f78 Migrate Settings UI to KickCD-style canvas framework
+        row:SetText(("|cffffff00/cm %s|r  |cffffffff—|r  %s")
```

And nothing records the choice:

```
$ grep -rn -i 'landing\|LandingRows\|FormatRow\|About page\|BuildAboutContent\|converg' docs/pending/LEDGER.md
docs/pending/LEDGER.md:52: (LIBKA0S-01 — "convergence across the collection was judged worth more than the line count"; about the dispatcher/help/version, not the landing page)
docs/pending/LEDGER.md:68: (LIBKA0S-12 — reset, i.e. convergence #1)

$ grep -n -i 'reset\|landing\|converg' CHANGELOG.md
(only the /cm reset entries at :14-30 — nothing about the landing page)

$ grep -rn -i 'landing' docs/ CHANGELOG.md README.md | grep -v '/audits/'
docs/smoke-tests.md:136:### 7. Settings panel — landing + General page

$ grep -oE '^\| (LIBKA0S-[0-9]+) \| [^|]+\| [^|]*\| [^|]*\|' docs/pending/LEDGER.md
| LIBKA0S-01 | `slash-cli` | … | 🟢 done |
| LIBKA0S-04 | `options-makers-3` | … | 🟢 done |
| LIBKA0S-05 | `options-registry-3` | … | 🟢 done |
| LIBKA0S-02 | `slash-upstream` | … | 🟢 done |
| LIBKA0S-06 | `adoption-tail` | … | 🟢 done |
| LIBKA0S-07 | `rowguard` | … | 🟢 done |
| LIBKA0S-08 | `licence-record` | … | 🟢 done |
| LIBKA0S-09 | `errstrings-upstream` | … | 🟡 deferred |
| LIBKA0S-10 | `ltrap-guards` | … | 🟢 done |
| LIBKA0S-11 | `usageget-arity` | … | 🟢 done |
| LIBKA0S-12 | `reset-convergence` | … | 🟢 done |
$ grep -c 'LIBKA0S-03' docs/pending/LEDGER.md
0
```

The 2026-08-01 run recorded this as *not applicable*
(`docs/adoption/2026-08-01/03_DEVIATIONS.md` §4) and `docs/adoption-prompt.md:438-446` now uses
ConsumableMaster as the worked example of that state. On this evidence both are wrong: the state
is a live, undocumented decline.

### §6.4 KickCD — both adopted

cwd=KCD. `settings/Slash.lua:150-191`:

```lua
-- `/kcd reset` used to take a PAGE — general | icons | castbar | label | spells.
-- It now takes a schema PATH and resets exactly one row …
local RETIRED_RESET_PAGES = { general = true, icons = true, castbar = true, label = true }

local function runReset(rest)
    local token = (rest or ""):match("^(%S+)")
    if token then
        local lowered = token:lower()
        if lowered == "spells" then
            out("`/kcd reset spells` has moved to |cFFFFFF00/kcd spells resetall|r …")
            return
        end
        if RETIRED_RESET_PAGES[lowered] then
            out(("`/kcd reset %s` is gone \226\128\148 `reset` now takes a setting path. "):format(lowered)
                .. "Use the " .. lowered .. " panel's |cFFFFFF00Defaults|r button …")
            return
        end
    end
    NS.Slash.cli:CliReset(rest)
end
```

`settings/Panel.lua:518-539`:

```lua
    -- 4) Slash-command rows, rendered by the SAME formatter `/kcd help` prints
    -- through (NS.Slash:LandingRows -> LibKa0s-Slash-1.0's one row formatter),
    -- minus the chat indent …
    --
    -- This file used to carry its own format string for the same NS.COMMANDS
    -- data: two spaces either side of the dash, the dash itself wrapped in the
    -- white colour run, and the description left uncoloured. … That is the
    -- divergence the convergence exists to end, and the visible cost is this
    -- page's spacing halving and its descriptions turning white.
    for _, text in ipairs(NS.Slash and NS.Slash:LandingRows() or {}) do
```

The destructive global path keeps its confirmation on both entry points:
`settings/General.lua:103-114` registers the popup whose `OnAccept` calls `H.ResetAll()`, and
`core/KickCD.lua:172-173` routes `/kcd resetall` to the same body. The ledger, for completeness:

```
$ ls -la docs/pending/
-rwxrwxrwx 1 tushar tushar 14064 Aug  1 11:23 LEDGER.md

$ grep -n 'LIBKA0S-' docs/pending/LEDGER.md   (truncated to the ID / state / subject)
LIBKA0S-01 | 9533c453 | ship the licence with the library                  | 🟢 done
LIBKA0S-02 | 0ff0c73c | L-trap regression guard covers 1 of 15             | 🟢 done
LIBKA0S-03 | 8f8b97c9 | no adopter records which LibKa0s it ships          | 🟢 done
LIBKA0S-04 | d06a4940 | point a second consumer at RenderGrid              | 🔵 wont-do
LIBKA0S-05 | 1ca42787 | degradation-stub idiom differs across the three    | 🟢 done
```

### §6.5 BankLedger — both adopted, both recorded

cwd=BL. Convergence #1, `settings/Slash.lua:221`, `:239-249` and the confirm-gated wipe at
`:19-27`:

```lua
function Sl:CliReset(rest) return cli:CliReset(rest) end
```

```lua
  StaticPopupDialogs["KA0S_BANKLEDGER_RESETALL"] = {
    text = "Reset ALL Ka0s Bank Ledger settings AND delete ALL recorded history? "
      .. "This cannot be undone.",
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = function() Sl:ResetEverything() end,
    timeout = 0, whileDead = true, hideOnEscape = true, showAlert = true,
    preferredIndex = 3,
  }
```

Recorded at LIBKA0S-10 and pinned by a case:

```
| LIBKA0S-10 | `3f7c05d8` | `../LibKa0s/docs/adoption-prompt.md` convergence #1 (`reset` takes a path) | 🟢 done | 2026-08-01 | **Adopted — and it was already converged, which is not the same as "not applicable".** `/bl reset <path>` was path-scoped and …

  PASS  LibKa0s-Slash: reset takes a PATH and resetall takes none — already converged
```

Convergence #2, `settings/Slash.lua:224-228`:

```lua
-- The settings landing page renders the same verbs, through the same one row formatter, in the help
-- colours — un-indented, because there each row is its own label. This is the convergence: the panel
-- used to carry a SECOND formatter for the same data, with doubled spaces around a white-wrapped em
-- dash and a bare description, and the two drifted apart the moment either was touched.
function Sl:LandingRows() return cli:LandingRows() end
```

```
$ grep -rn 'LandingRows' --include='*.lua' . | grep -v '/libs/' | grep -v '/tests/'
settings/Panel.lua:346:… LandingRows …
settings/Panel.lua:356:… LandingRows …
settings/Slash.lua:125:  function Sl:LandingRows() return { UNAVAILABLE } end
settings/Slash.lua:228:function Sl:LandingRows() return cli:LandingRows() end
```

Recorded at LIBKA0S-11, with the rendered deltas itemised separately at LIBKA0S-13:

```
| LIBKA0S-11 | `6a91be44` | `../LibKa0s/docs/adoption-prompt.md` convergence #2 (one command-row formatter) | 🟢 done | 2026-08-01 | **Adopted, and it is user-visible.** `settings/Panel.lua`'s landing page carried a SECOND formatter for `NS.COMMANDS` — …

  PASS  LibKa0s-Slash: the landing page and the chat help render the SAME rows
```

The full LIBKA0S ledger row set (truncated to 260 characters each for legibility):

```
$ grep -n 'LIBKA0S-' docs/pending/LEDGER.md | cut -c1-260
49:| LIBKA0S-01 | `48867ab5` | `../LibKa0s/docs/adoption-prompt.md` step 2 (vendor the test kit) | 🟢 done | 2026-08-01 | The kit is vendored to `tests/_kit/` and `tests/run.lua` / `tests/wow_mock.lua` are rebuilt on it; `tests/loader.lua` is deleted in favo
50:| LIBKA0S-02 | `1a7f0b3e` | `tests/_kit/framework.lua:79-96` (a listed suite with no file is SKIPPED) | 🟢 done | 2026-08-01 | Accepted, with a guard rather than a fork. The old runner raised on a missing suite; the kit skips it, which turns a typo into a
51:| LIBKA0S-03 | `6c2d94af` | `tests/_kit/mock_base.lua` vs the pre-adoption `tests/wow_mock.lua` | 🟢 done | 2026-08-01 | Ten base behaviours are deliberately overridden in the extender rather than adopted, each named in that file's header with the suite t
52:| LIBKA0S-04 | `2d1e57c9` | `../LibKa0s/docs/adoption-prompt.md` step 4 (Core) + `../LibKa0s/README.md` ▸ the printer descriptor | 🟢 done | 2026-08-01 | `LibKa0s-Core-1.0` adopted in `core/CoreSetup.lua`; the printer block leaves `core/Util.lua` (202 …
53:| LIBKA0S-05 | `9f4c31d2` | `../LibKa0s/README.md` ▸ `LibKa0s-Core-1.0` (`SKIN`, `ApplySkin`, `MakeCloseButton`) | 🔵 wont-do | 2026-08-01 | **Core's window chrome is DECLINED, deliberately.** `lib.SKIN` is a 12px `UI-Tooltip-Border` look against this a
54:| LIBKA0S-06 | `7b30d8e4` | `../LibKa0s/docs/adoption-prompt.md` "Standing hazards" (CRLF) + this repo's missing `.gitattributes` | 🟡 deferred | 2026-08-01 | **A standards deviation surfaced by the adoption, not caused by it, and not fixed here.** The ad
55:| LIBKA0S-07 | `4e8b21c7` | `../LibKa0s/docs/adoption-prompt.md` "When the library itself has to change" | 🟢 done | 2026-08-01 | **A library gap, fixed upstream rather than worked around here.** `LibKa0s-DebugLog-1.0` adopted in `core/DebugLogSetup.lua`
56:| LIBKA0S-08 | `5c9a76b1` | `../LibKa0s/README.md` ▸ `ConsoleCheckbox()` data contract | 🔵 wont-do | 2026-08-01 | **`D:ConsoleCheckbox()` is DECLINED.** Its label is byte-identical to this addon's (`Debug console`) but its tooltip is not, and adopting
57:| LIBKA0S-09 | `8d40e2f5` | `modules/DebugLog.lua:300-309` vs `../LibKa0s/LibKa0s/DebugLog.lua` `onVisibilityChanged` | 🟢 done | 2026-08-01 | **A bug fixed by the adoption, recorded so it is not mistaken for drift.** The old console called `syncPanel()`
58:| LIBKA0S-10 | `3f7c05d8` | `../LibKa0s/docs/adoption-prompt.md` convergence #1 (`reset` takes a path) | 🟢 done | 2026-08-01 | **Adopted — and it was already converged, which is not the same as "not applicable".** `/bl reset <path>` was path-scoped and
59:| LIBKA0S-11 | `6a91be44` | `../LibKa0s/docs/adoption-prompt.md` convergence #2 (one command-row formatter) | 🟢 done | 2026-08-01 | **Adopted, and it is user-visible.** `settings/Panel.lua`'s landing page carried a SECOND formatter for `NS.COMMANDS` —
60:| LIBKA0S-12 | `bd25e103` | `settings/Schema.lua` row types and option lists | 🟢 done | 2026-08-01 | The schema's vocabulary moved to the one the library reads: `type = "boolean"` → `"bool"` (6 rows), `options` → `values` (3 rows), and each option en
61:| LIBKA0S-13 | `c47a9f16` | `settings/Slash.lua` rendered output vs `../LibKa0s/LibKa0s/Slash.lua` | 🟢 done | 2026-08-01 | **The rendered-output changes a user will notice, accepted knowingly.** (1) The help header gains an em dash: `v1.0.0 slash command
62:| LIBKA0S-14 | `e820d4b7` | `settings/Slash.lua:146-147` (`LIST_GROUP_ORDER`) | 🔵 wont-do | 2026-08-01 | The hand-maintained `/bl list` group-order constant is **deleted rather than ported**. It is the F-007 defect itself: it named `"Window"`, a group th
63:| LIBKA0S-15 | `a1d9f30b` | `standards/options-ui.md` §11 and §41 (WowAddonStandards v2.15.0) | 🟢 done | 2026-08-01 | **A conformance defect, found by using the addon rather than by the adoption, and fixed here.** options-ui-§11 requires that "an open
64:| LIBKA0S-16 | `f52b7c6e` | `standards/options-ui.md` §11/§41 vs `../LibKa0s/README.md` ▸ Options descriptor | 🔵 wont-do | 2026-08-01 | **No upstream change: neither the standard nor the library has a gap here.** The standard already states the rule
65:| LIBKA0S-17 | `7e3a15d0` | `../LibKa0s/LibKa0s/Perf.lua:634-665` vs `modules/Ledger.lua:483-486` | 🔵 wont-do | 2026-08-01 | **`LibKa0s-Perf-1.0` DECLINED, and the reason is structural rather than a judgement about thresholds.** The instrument measures i
66:| LIBKA0S-18 | `b6f2c84a` | `../LibKa0s/LibKa0s/OptionsWidgets.lua:466` vs `Slash.lua:198-214` | 🟢 done | 2026-08-01 | **A library gap found ahead of the Options adoption and fixed upstream: two majors disagreed about what one schema row IS.** `LibKa0s-S
67:| ~~LIBKA0S-19~~ | `d4c1907f` | `../LibKa0s/LibKa0s/Options.lua` (no `OnCommit`/`OnDefault`/`OnRefresh`) vs `standards/options-ui.md` §1 | 🟡 deferred | 2026-08-01 | ~~**Raised, not acted on.**~~ **SUPERSEDED by LIBKA0S-24 — done, upstream, in all thre
68:| ~~LIBKA0S-20~~ | `0b58e9c3` | `../LibKa0s/docs/adoption-prompt.md` step 4 (Options) | 🟡 deferred | 2026-08-01 | ~~**`LibKa0s-Options-1.0` prepared but NOT adopted.**~~ **SUPERSEDED by LIBKA0S-21 — adopted.** Row preserved rather than deleted so the r
69:| LIBKA0S-21 | `c93f1a07` | `../LibKa0s/docs/adoption-prompt.md` step 4 (Options) | 🟢 done | 2026-08-01 | **`LibKa0s-Options-1.0` adopted.** `settings/OptionsSetup.lua` (169 lines) holds the descriptor and `NS.Helpers`, which **IS** the library instance
70:| LIBKA0S-22 | `2b7e5d41` | `../LibKa0s/LibKa0s/Options.lua` `RestoreAllDefaults` / `InlineButtonPair` / `runRefreshers` | 🔵 wont-do | 2026-08-01 | **Three library surfaces knowingly DECLINED.** (1) `O.RestoreAllDefaults` — this addon's global reset mu
71:| LIBKA0S-23 | `8f04c6b2` | `settings/Panel.lua` `makeMultiCheck`; `tests/test_panel.lua` canvas-contract cases | 🟢 done | 2026-08-01 | **Two real bugs the adoption's new render coverage caught immediately, neither of which any prior test could see.** (1
72:| LIBKA0S-24 | `5aeb2f18` | `standards/options-ui.md` §1 + `../LibKa0s/LibKa0s/Options.lua` `CreatePanel` | 🟢 done | 2026-08-01 | **Closes LIBKA0S-19, upstream in all three places rather than locally.** The standard now REQUIRES the trio on every frame
73:| LIBKA0S-25 | `9c07be44` | `tests/test_panel.lua` "An assertion changed to accommodate a change I made, recorded because that is the move that deserves saying out lou
```

Every decline is recorded — LIBKA0S-05 (Core chrome), -08 (`ConsoleCheckbox`), -14
(`LIST_GROUP_ORDER`), -17 (Perf), -22 (three Options surfaces). One row is factually stale:

```
$ sed -n '54p' docs/pending/LEDGER.md
| LIBKA0S-06 | … | 🟡 deferred | 2026-08-01 | **A standards deviation surfaced by the adoption, not caused by it, and not fixed here.** The adoption prompt states that every repo in the collection pins `* text=auto eol=crlf` in `.gitattributes`; this repo has **no `.gitattributes` at all** and its working tree is pure LF. … Adding the pin is a repo-wide working-tree change well outside this adoption and is the user's call. |
```

Both halves of that sentence are contradicted by §3.5: `.gitattributes` exists, is tracked, pins
CRLF at commit `9325663`, and the working tree is CRLF throughout. The item was done, not deferred.

---

## §7 — The `L` trap

### §7.1 Half one: every descriptor `L` in host code

cwd=AT

```
$ grep -rnE '(^|[,{[:space:]])L[[:space:]]*=' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/' | grep -v 'local L'
(no output)
```

Without the `/tests/` filter, every hit is inside the guard suite itself:

```
tests/test_ltrap.lua:63:--   L = NS.L                     -- the table itself                        OFFENDER
tests/test_ltrap.lua:64:--   L = NS.L or { ... }          -- NS.L is always truthy, so: the table    OFFENDER
tests/test_ltrap.lua:65:--   L = NS.L and { ... } or nil  -- evaluates to the plain table            fine
tests/test_ltrap.lua:87:    "  L = NS.L,",
tests/test_ltrap.lua:89:    "    L = NS.L or {},",
tests/test_ltrap.lua:90:    "  L = NS.L or { FOO = 'bar' },",
tests/test_ltrap.lua:91:    "  { L = NS.L, other = 1 }",
tests/test_ltrap.lua:97:    "  L = NS.L and { FOO = 'bar' } or nil,",
tests/test_ltrap.lua:98:    "  L = NS.L and {",
tests/test_ltrap.lua:100:    "  L = STRINGS,",
tests/test_ltrap.lua:101:    "  L = nil,",
tests/test_ltrap.lua:102:    "  -- L = NS.L, in a comment",   -- documentation, not a descriptor
tests/test_ltrap.lua:152:    L = fallbackLocale(),
tests/test_ltrap.lua:167:    L = fallbackLocale(),
tests/test_ltrap.lua:182:    L = fallbackLocale(),
```

cwd=KCD

```
$ grep -rnE '(^|[,{[:space:]])L[[:space:]]*=' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/' | grep -v 'local L'
settings/Slash.lua:335:    L = NS.L and {
```

The full expression, `settings/Slash.lua:335-338` — the legitimate third form, which evaluates to
a plain one-key table and never to the locale table:

```lua
    L = NS.L and {
        LIST_HEADER = NS.L["Available settings"]
            and ("|cff33ff99" .. NS.L["Available settings"] .. "|r") or nil,
    } or nil,
```

cwd=CM

```
$ grep -rnE '(^|[,{[:space:]])L[[:space:]]*=' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/' | grep -v 'local L'
core/SlashCommands.lua:362:                        say(("    [%2d] L=%q  R=%q"):format(i, left, right))
core/SlashCommands.lua:1319:        L            = SLASH_STRINGS,
```

`:362` is a format string in a diff dump, not a descriptor. `:1319` is the only real descriptor `L`
in the repo, and `SLASH_STRINGS` is a plain table of literals:

```
$ sed -n '1265,1298p' core/SlashCommands.lua
-- The strings whose wording the addon already shipped. A plain table,
-- deliberately NOT KCM.L: Sl:Text resolves through rawget precisely so a
-- key-echoing locale table falls through, which also means KCM.L could never
-- supply these.
local SLASH_STRINGS = {
    HELP_HEADER     = "|cffffd100Ka0s Consumable Master|r v%s \226\128\148 slash commands",
    HELP_ALIAS      = " (alias: |cffffff00%s|r)",
    USAGE_GET       = "Usage: %s get <path>  (try /cm list)",
    USAGE_RESET     = "Usage: %s reset <path> \226\128\148 this resets ONE setting. …",
    ERR_BOOL        = "expected true/false/on/off/1/0",
    ERR_ALLOWED     = "Allowed values: %s",
    ERR_COLOR       = "expected: r g b [a] (each 0-1 or 0-255)",
}
```

cwd=BL

```
$ grep -rnE '(^|[,{[:space:]])L[[:space:]]*=' . --include='*.lua' | grep -v '/libs/' | grep -v '/tests/' | grep -v 'local L'
(no output)

$ grep -rnE '(^|[,{[:space:]])L[[:space:]]*=' . --include='*.lua' | grep -v '/libs/' | grep -v 'local L'
tests/test_libka0s.lua:252:  assertTrue(offendingLocaleDescriptor("    L = NS.L,") ~= nil, "the bare table must be caught")
tests/test_libka0s.lua:253:  assertTrue(offendingLocaleDescriptor("    L = NS.L or { A = 'x' },") ~= nil,
tests/test_libka0s.lua:255:  assertTrue(offendingLocaleDescriptor("    L = NS.L and { A = 'x' } or nil,") == nil,
tests/test_libka0s.lua:257:  assertTrue(offendingLocaleDescriptor("    L = { A = 'x' },") == nil, "a plain table is fine")
```

No host descriptor anywhere in the collection is handed a key-returning locale table.

### §7.2 Half two: the rendered-string guard, all four consumers

cwd=GIT

```
$ for a in AbsorbTracker BankLedger ConsumableMaster KickCD; do echo "--- $a"; grep -rn 'A-Z0-9_' $a/tests --include='*.lua' | grep -v '_kit'; done
--- AbsorbTracker
AbsorbTracker/tests/test_debuglog.lua:147:  assertNil(label:match("^[A-Z][A-Z0-9_]+$"),
AbsorbTracker/tests/test_debuglog.lua:153:  assertNil(suffix:match("^[A-Z][A-Z0-9_]+$"),
AbsorbTracker/tests/test_helpers.lua:846:  assertNil(text:match("^[A-Z][A-Z0-9_]+$"),
AbsorbTracker/tests/test_slash.lua:167:  assertNil(header:match("^[A-Z][A-Z0-9_]+$"),
AbsorbTracker/tests/test_perf.lua:418:    assertNil(step.label:match("^[A-Z][A-Z0-9_]+$"),
AbsorbTracker/tests/test_ltrap.lua:155:  assertNil(label:match("^[A-Z][A-Z0-9_]+$"),
AbsorbTracker/tests/test_ltrap.lua:170:  assertNil(line:match("^[A-Z][A-Z0-9_]+$"),
AbsorbTracker/tests/test_ltrap.lua:186:    assertNil(step.label:match("^[A-Z][A-Z0-9_]+$"),
--- BankLedger
BankLedger/tests/test_libka0s.lua:425:  -- label matching ^[A-Z][A-Z0-9_]+$ means the descriptor was handed a locale table whose metatable
BankLedger/tests/test_libka0s.lua:433:    assertTrue(value:match("^[A-Z][A-Z0-9_]+$") == nil,
BankLedger/tests/test_libka0s.lua:706:    assertTrue(bare:match("^[A-Z][A-Z0-9_]+$") == nil,
BankLedger/tests/test_libka0s.lua:709:      assertTrue(word:match("^[A-Z][A-Z0-9]*_[A-Z0-9_]*$") == nil,
--- ConsumableMaster
ConsumableMaster/tests/test_coresetup.lua:148:    t.falsy(tag:match("^[A-Z][A-Z0-9_]+$"),
ConsumableMaster/tests/test_perfsetup.lua:60:        t.falsy(step.label:match("^[A-Z][A-Z0-9_]+$"),
ConsumableMaster/tests/test_debuglog.lua:274:    t.falsy(spec.label:match("^[A-Z][A-Z0-9_]+$"),
ConsumableMaster/tests/test_debuglog.lua:276:    t.falsy(spec.tooltip:match("^[A-Z][A-Z0-9_]+$"),
ConsumableMaster/tests/test_debuglog.lua:288:    t.falsy(ack:match("^[A-Z][A-Z0-9_]+$"),
ConsumableMaster/tests/test_settingsui.lua:121:        t.falsy(values[1].text:match("^[A-Z][A-Z0-9_]+$"),
ConsumableMaster/tests/test_settingsui.lua:137:        t.falsy(notice:match("^[A-Z][A-Z0-9_]+$"),
ConsumableMaster/tests/test_slashsetup.lua:96:    t.falsy(header:match("^[A-Z][A-Z0-9_]+$"),
ConsumableMaster/tests/test_slashsetup.lua:104:    t.falsy(listHeader:match("^[A-Z][A-Z0-9_]+$"),
--- KickCD
KickCD/tests/test_debuglogsetup.lua:268:        -- this way rather than as the bare `^[A-Z][A-Z0-9_]+$` sweep because
KickCD/tests/test_debuglogsetup.lua:275:        assertNil(rendered:match("^[A-Z][A-Z0-9]*_[A-Z0-9_]*$"),
KickCD/tests/test_debuglogsetup.lua:298:        assertNil(v:match("^[A-Z][A-Z0-9_]+$"),
KickCD/tests/test_coresetup.lua:272:        assertNil(word:match("^[A-Z][A-Z0-9]*_[A-Z0-9_]*$"),
KickCD/tests/test_perfsetup.lua:375:        assertNil(step.label:match("^[A-Z][A-Z0-9_]+$"),
KickCD/tests/test_perfsetup.lua:478:        assertNil(step.label:match("^[A-Z][A-Z0-9_]+$"),
KickCD/tests/test_options_panel.lua:349:            if label:match("^[A-Z][A-Z0-9]*_[A-Z0-9_]*$") then
KickCD/tests/test_options_panel.lua:355:                if row.desc:match("^[A-Z][A-Z0-9]*_[A-Z0-9_]*$") then
KickCD/tests/test_options_panel.lua:377:            assertNil(row.group:match("^[A-Z][A-Z0-9]*_[A-Z0-9_]*$"),
KickCD/tests/test_slash.lua:338:        assertNil(rendered:match("^[A-Z][A-Z0-9_]+$"),
KickCD/tests/test_slash.lua:375:                    assertNil(word:match("^[A-Z][A-Z0-9]*_[A-Z0-9_]*$"),
KickCD/tests/test_slash.lua:401:        assertNil(rendered:match("^[A-Z][A-Z0-9_]+$"),
```

The 2026-08-01 run found this guard in exactly one place in the whole collection
(`KickCD/tests/test_perfsetup.lua:375`) — 1 of 15 module-adoptions. All four consumers now carry it.

### §7.3 Coverage, per consumer

**AbsorbTracker — 4 of 5 module-adoptions carry a rendered or library-regression assertion; 5 of 5
carry the source check.**

```
$ sed -n '13,33p' tests/test_ltrap.lua
-- THREE GUARDS, and they are honest about which half of the failure each one can see.
--
--   1. The SOURCE check below. It is the one that reddens on the mistake itself — adding
--      `L = NS.L` to any of the five seam descriptors ...
--   2. The RENDERED checks, in each module's own suite (tests/test_debuglog.lua,
--      tests/test_slash.lua, tests/test_perf.lua, tests/test_helpers.lua) ...
--   3. The LIBRARY-REGRESSION checks below. The vendored copy resolves an override with `rawget`
--      (DebugLog 3 / Slash 4 / Perf 5) ...
--
-- Only DebugLog, Slash and Perf take an `L` at all. LibKa0s-Core-1.0 has no STRINGS table and no
-- `L` descriptor field, and LibKa0s-Options-1.0's `L` is `lib.LAYOUT` — a geometry table, not a
-- locale one; its user-visible strings come from `lib.STRINGS` with no override path. Writing a
-- descriptor-mutation case for either would be a case that cannot fail, so neither has one. The
-- source check still covers both files, because the mistake to catch is someone ADDING an `L`.

$ sed -n '42,49p' tests/test_ltrap.lua
local SEAMS = {
  "core/CoreSetup.lua",
  "core/DebugLogSetup.lua",
  "core/PerfSetup.lua",
  "settings/Slash.lua",
  "settings/OptionsSetup.lua",
}
```

| Major | Source check | Rendered assertion | Library-regression case |
|---|---|---|---|
| Core | yes (`CoreSetup.lua` in `SEAMS`) | **none** | n/a (no `STRINGS`) |
| DebugLog | yes | `tests/test_debuglog.lua:147`, `:153` | `tests/test_ltrap.lua:144`–`:158` |
| Slash | yes | `tests/test_slash.lua:167` | `tests/test_ltrap.lua:162`–`:174` |
| Options | yes | `tests/test_helpers.lua:834`–`:853` | n/a (`L` is `lib.LAYOUT`) |
| Perf | yes | `tests/test_perf.lua:418` | `tests/test_ltrap.lua:177`–`:190` |

The prompt's "Pinning it" point 2 claims AbsorbTracker carries a library tripwire for Core and
Options. It carries neither:

```
$ grep -rn 'STRINGS' tests --include='*.lua' | grep -v '_kit'
tests/test_debuglog.lua:137:test("the console checkbox label the library renders is prose, not its own STRINGS key", ...
tests/test_helpers.lua:834:test("the Defaults button the library renders is prose, not its own STRINGS key", ...
tests/test_helpers.lua:838:  -- on screen through Options: EnsureDefaultsButton sets lib.STRINGS.DEFAULTS_LABEL ...
tests/test_helpers.lua:851:  assertEqual(text, lib.STRINGS.DEFAULTS_LABEL, ...
tests/test_slash.lua:155:test("the schema CLI's list header the library renders is prose, not its own STRINGS key", ...
tests/test_ltrap.lua:4,30,32,100,157,172,188 (comments + the three regression cases)
tests/test_perf.lua:408,410
```

For Options it ships something stronger — a rendered assertion on `lib.STRINGS.DEFAULTS_LABEL` read
back off the built Defaults button, with an explicit non-vacuity coupling
(`tests/test_helpers.lua:840`–`:853`). For Core it ships nothing beyond the source check.

**KickCD — 5 of 5.** Core `tests/test_coresetup.lua:272`, DebugLog
`tests/test_debuglogsetup.lua:275,298`, Slash `tests/test_slash.lua:338,375,401`, Options
`tests/test_options_panel.lua:349,355,377`, Perf `tests/test_perfsetup.lua:375,478`. Its source
matcher, `tests/test_perfsetup.lua:382-431`:

```lua
test("no LibKa0s descriptor is handed the key-returning locale table", function()
    --   L = NS.L                     -- the table itself                        OFFENDER
    --   L = NS.L or { ... }          -- NS.L is always truthy, so: the table    OFFENDER
    --   L = NS.L and { ... } or nil  -- evaluates to the plain table            fine
    local function handedTheLocaleTable(line)
        local tail = line:match("^%s*L%s*=%s*NS%.L(.*)$")
                  or line:match("[{,]%s*L%s*=%s*NS%.L(.*)$")
        if not tail then return false end
        return not (tail:match("^%s*and$") or tail:match("^%s*and[^%w_]"))
    end

    -- Non-vacuity: pin the matcher against all three forms …
    assertTrue(handedTheLocaleTable("    L = NS.L,"), "the bare form must be flagged")
    assertTrue(handedTheLocaleTable("    L = NS.L or {},"), "the `or` form is the same trap and must be flagged")
    assertFalse(handedTheLocaleTable("    L = NS.L and { LIST_HEADER = x } or nil,"),
        "the `and` form evaluates to the plain table and must NOT be flagged")

    local offenders = {}
    for _, rel in ipairs({
        "core/CoreSetup.lua", "core/DebugLogSetup.lua", "core/PerfSetup.lua",
        "settings/Slash.lua", "settings/OptionsSetup.lua",
    }) do …
```

**ConsumableMaster — 5 of 5 rendered, no source guard.**

| Major | Guard | File:line |
|---|---|---|
| Core | prefix tag is prose | `tests/test_coresetup.lua:148` |
| DebugLog | checkbox label, tooltip, ack line | `tests/test_debuglog.lua:274,276,288` |
| Slash | help header, list header | `tests/test_slashsetup.lua:96,104` |
| Options | LSM placeholder text, render-failure notice | `tests/test_settingsui.lua:121,137` |
| Perf | step label | `tests/test_perfsetup.lua:60` |

`tests/test_settingsui.lua:107-138` explains why Options gets a substitute rather than a case that
cannot fail:

> The L trap's shape, applied to the one adopted major that cannot take the trap: Options.lua has no
> locale seam at all -- its local `L` is lib.LAYOUT … There is no descriptor field here to get wrong,
> so what these pin is the other half of the same requirement: that the library's own STRINGS reach
> the user as English through the accessors this addon actually drives.
>
> The media placeholder first, and it is the sharper of the two: the string is both the label shown
> in the dropdown AND the value stored in SavedVariables, so a key leaking here is written to disk.

and the chat half is read off the emitted line rather than off `lib.STRINGS`:

```
        local notice = (mock.output[1] or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        notice = notice:gsub("^%[CM%]%s*", "")
        t.truthy(#notice > 0, "the failure was reported at all")
        t.falsy(notice:match("^[A-Z][A-Z0-9_]+$"), …)
```

The source guard the prompt's points 3 and 4 ask for is absent:

```
$ grep -rn 'L%s*=\|handsLocale\|sourceGuard\|seamSources' tests/*.lua
(no matching case; the only 'offender' hit is tests/test_slash.lua:354, an unrelated stat-name message)
```

**BankLedger — 3 of 4 adopted majors guarded.** Its source matcher and Core tripwire,
`tests/test_libka0s.lua:228-260` and `:208-218`:

```lua
local function offendingLocaleDescriptor(src)
  for line in src:gmatch("[^\r\n]+") do
    local rest = line:match("[%s,{]L%s*=%s*(.*)$") or line:match("^L%s*=%s*(.*)$")
    if rest then
      local head, next_ = rest:match("^(NS%.L)%s*([%w_]*)")
      if head and next_ ~= "and" then return line end
    end
  end
  return nil
end

local SEAM_FILES = { "core/CoreSetup.lua", "core/DebugLogSetup.lua", "settings/Slash.lua" }

test("LibKa0s: no seam file hands a descriptor the addon-wide locale table", function()
  for _, path in ipairs(SEAM_FILES) do
    local bad = offendingLocaleDescriptor(Loader.readFile(path))
    assertTrue(bad == nil, path .. " passes NS.L (or a chain evaluating to it) as a descriptor L: "
      .. tostring(bad))
  end
end)

test("LibKa0s: the locale-descriptor matcher catches all three spellings", function()
  -- A matcher nothing tests can be narrowed back to a single anchored form while still reporting
  -- green, which is exactly how it got there in a sibling addon.
  assertTrue(offendingLocaleDescriptor("    L = NS.L,") ~= nil, "the bare table must be caught")
  assertTrue(offendingLocaleDescriptor("    L = NS.L or { A = 'x' },") ~= nil,
    "`or` still evaluates to the locale table — it must be caught")
  assertTrue(offendingLocaleDescriptor("    L = NS.L and { A = 'x' } or nil,") == nil,
    "the `and` form evaluates to the plain table and is legitimate")
  assertTrue(offendingLocaleDescriptor("    L = { A = 'x' },") == nil, "a plain table is fine")
  assertTrue(offendingLocaleDescriptor("local L = NS.L") ~= nil,
    "a file-scope capture handed on is still the locale table")
end)
```

```lua
test("LibKa0s-Core tripwire: Core ships no STRINGS and reads no descriptor L", function()
  assertTrue(rawget(lib, "STRINGS") == nil,
    "LibKa0s-Core-1.0 has grown a STRINGS table — it can now express the L trap, so this tripwire "
    .. "must be replaced by a real rendered-string assertion")
  local src = Loader.readFile("libs/LibKa0s/Core.lua")
  assertTrue(src:find("STRINGS", 1, true) == nil, "Core.lua now names STRINGS")
  assertTrue(src:find("d.L", 1, true) == nil, "Core.lua now reads a descriptor L")
end)
```

```
$ grep -rn 'resolves to prose' tests/*.lua
tests/test_libka0s.lua:423:test("LibKa0s-DebugLog: every user-visible string resolves to prose, not to its own key", function()
tests/test_libka0s.lua:690:test("LibKa0s-Slash: every user-visible string resolves to prose, not to its own key", function()
```

| Major | Can express the trap? | Guard present | Where |
|---|---|---|---|
| `DebugLog` | yes (takes `d.L`) | rendered-prose assertion | `tests/test_libka0s.lua:423-435` |
| `Slash` | yes (takes `d.L`) | rendered-prose assertion | `tests/test_libka0s.lua:690-712` |
| `Core` | no (ships no `STRINGS`, reads no `d.L`) | **tripwire** | `tests/test_libka0s.lua:208-218` |
| `Options` | no (ships `STRINGS` but reads **no** `d.L`) | **NONE** | — |
| `Perf` | n/a — not adopted | n/a | — |

The Options gap is real but the trap genuinely cannot fire today, and the gap is collection-wide:

```
$ cd /mnt/d/Profile/Users/Tushar/Documents/GIT/LibKa0s && grep -n 'STRINGS\|d\.L\b' LibKa0s/Options.lua | head
LibKa0s/Options.lua:71:lib.STRINGS = {
LibKa0s/Options.lua:172:      displayTitle = (d.parentTitle or "") .. lib.STRINGS.BREADCRUMB_SEP .. title
LibKa0s/Options.lua:282:    btn:SetText(lib.STRINGS.DEFAULTS_LABEL)
LibKa0s/Options.lua:292:      O.AttachTooltip(btn, lib.STRINGS.DEFAULTS_LABEL, panel.defaultsTooltip)
LibKa0s/Options.lua:431:      print(lib.STRINGS.RENDER_FAILED:format(tostring(ctx.pageKey or "?"))…
(no `d.L` hit anywhere in Options.lua)

$ cd /mnt/d/Profile/Users/Tushar/Documents/GIT && grep -rn -i 'Options tripwire\|Options.*STRINGS\|Options reads no descriptor' AbsorbTracker/tests KickCD/tests ConsumableMaster/tests BankLedger/tests 2>/dev/null | grep -v '_kit'
AbsorbTracker/tests/test_helpers.lua:838:  -- on screen through Options: EnsureDefaultsButton sets lib.STRINGS.DEFAULTS_LABEL on the widget,
```

### §7.4 A host-side skew alarm, beyond what the method asks

cwd=CM — `tests/test_libka0s.lua` drives a `MAJORS` table (`:40-61`) mirroring `tests/run.lua`'s and
asserts: the harness load list equals `libs/LibKa0s/LibKa0s.xml` in XML order (`:63-75`), every
named file exists (`:77-81`), the TOC loads the aggregate XML and does **not** name individual
module files (`:83-91`), every major registers reporting the minor of every one of its files with
`MODULES.<primary> == lib.MINOR` (`:93-121`), no file registers under a foreign major (`:123-137`),
and each attach file is paired to the shell minor it actually attached to (`:139-`). This is the
nearest thing in the collection to a host-side skew alarm.

---

## §8 — The green gate, actually run

### §8.1 AbsorbTracker — 462 / 0, 0 warnings in 28 files

cwd=AT

```
$ lua tests/run.lua
  ... (tail)
  PASS  every schema page registered a real Blizzard subcategory at build time
  PASS  the Profiles page self-skips when AceDBOptions is unavailable
  PASS  a page renders nothing until its first OnShow
  PASS  first OnShow builds the Defaults button and renders the page
  PASS  the Defaults button restores just its own page
  PASS  a second OnShow rebuilds the panel body without stacking duplicate widgets
  PASS  showing every page builds it without error
  PASS  the main page's About content renders on its first OnShow
  PASS  README.md carries no angle-bracket argument placeholders
  PASS  the addon's own files use US spellings
  PASS  the source matcher tells the three `L =` spellings apart
  PASS  no LibKa0s descriptor in this addon is handed the key-returning locale table
  PASS  locales/enUS.lua really does answer every key, so the check above guards something
  PASS  vendored DebugLog resolves a fallback-only override to its own strings
  PASS  vendored Slash resolves a fallback-only override to its own strings
  PASS  vendored Perf resolves a fallback-only override to its own strings

462 passed, 0 failed, 462 total

$ luacheck .
  ... (tail)
Checking core/PerfSetup.lua                       OK
Checking core/State.lua                           OK
Checking core/Units.lua                           OK
Checking defaults/Profile.lua                     OK
Checking locales/enUS.lua                         OK
Checking modules/Bar.lua                          OK
Checking modules/Display.lua                      OK
Checking modules/Timer.lua                        OK
Checking settings/About.lua                       OK
Checking settings/Bar.lua                         OK
Checking settings/Border.lua                      OK
Checking settings/Font.lua                        OK
Checking settings/General.lua                     OK
Checking settings/OptionsSetup.lua                OK
Checking settings/Profiles.lua                    OK
Checking settings/Schema.lua                      OK
Checking settings/Slash.lua                       OK
Checking settings/UnitPanel.lua                   OK

Total: 0 warnings / 0 errors in 28 files
```

Nothing to attribute — no warnings inside the five seam files and none elsewhere. `libs/` and
`tests/_kit/` sit outside `luacheck` via `exclude_files` (`CLAUDE.md:38`), so the figure is scoped
to this repo's own 28 files.

Cross-checks on the number:

```
$ grep -n -A6 'Totals' docs/test-cases.md
531:## Totals
533:| Suite | Cases |
534:|-------|------:|
535:| test_loadorder.lua | 10 |
...
555:| **Total** | **462** |

$ grep -n 'tests-' README.md
7:![Tests](https://img.shields.io/badge/Tests-462%2F462_passing-green)
```

Suite = 462, `docs/test-cases.md` Totals = 462, README badge = 462,
`docs/adoption-prompt.md:538` = 462. The 2026-08-01 run recorded **449**; the +13 came from this
addon's own new cases (`d199866` / `bf45bb2` / `a242c81`), all committed **before** the four
re-vendor commits `ebaad1e`…`39620b4`. Across the re-vendor commits themselves the total stayed at
462 — the evidence that v1.2.0 was additive for this consumer.

BankLedger's collector re-ran the same suite independently (cwd=AT):

```
$ lua tests/run.lua | tail -2

462 passed, 0 failed, 462 total
```

### §8.2 KickCD — 643 / 0, 0 warnings in 32 files

cwd=KCD

```
$ lua tests/run.lua
… (tail)
  PASS  nesting is declared for every bucket that runs inside another
  PASS  instrumentation is inert when capture is off
  PASS  the show decisions consult Perf.suspended as step 0, at the source
  PASS  suspend releases the per-unit dispatch frames AceEvent cannot reach
  PASS  enabling a unit while suspended does not re-register its frames mid-capture
  PASS  resume restores from CURRENT state, not from a snapshot
  PASS  the suspended flag is session-only and never persisted
  PASS  `perf` is a host verb in NS.COMMANDS, not registered by the library
  PASS  a bare /kcd perf answers through the addon's tagged printer
  PASS  with LibKa0s absent the probe stub answers every member the addon calls
  PASS  with LibKa0s absent the bracketed paths still run
  PASS  the perf panel resolves real English, never a raw STRINGS key
  PASS  no LibKa0s descriptor is handed the key-returning locale table
  PASS  the panel title is the host's brand plus the library's resolved suffix
  PASS  the VENDORED library ignores a fallback-synthesised locale entry
  PASS  the record stamps a real addon version, never "?"
  PASS  the perf version agrees with the one /kcd version prints
  PASS  the version fallback is reachable, not dead
  PASS  every PollSpell exit is measured, including the rejections
  PASS  the record stamps a real client interface version, never 0

test_list_mode.lua
  PASS  --list emits a generated '# Test Cases' inventory header + regen note
  PASS  --list stdout is inventory-only, no run output
  PASS  --list emits CRLF line endings (matches the repo eol=crlf policy)
  PASS  --list per-suite header counts match their bullet counts
  PASS  --list Totals row equals the grand total of bullets

-------------------
643 passed, 0 failed
EXIT=0

$ luacheck .
… (tail)
Checking modules/Castbar_Debug.lua                 OK
Checking modules/Castbar_Skin.lua                  OK
Checking modules/Cooldowns.lua                     OK
Checking modules/IconGrid.lua                      OK
Checking modules/IconGrid_Layout.lua               OK
Checking modules/IconGrid_Render.lua               OK
Checking modules/UnitLabel.lua                     OK
Checking settings/Castbar.lua                      OK
Checking settings/General.lua                      OK
Checking settings/Icons.lua                        OK
Checking settings/Label.lua                        OK
Checking settings/OptionsSetup.lua                 OK
Checking settings/Panel.lua                        OK
Checking settings/Panel_Render.lua                 OK
Checking settings/Panel_Widgets.lua                OK
Checking settings/Profiles.lua                     OK
Checking settings/Slash.lua                        OK
Checking settings/Spells.lua                       OK

Total: 0 warnings / 0 errors in 32 files
EXIT=0

$ grep -n -i 'total' docs/test-cases.md | tail -3
774:## Totals
820:| **Total** | **643** |

$ grep -n -i 'tests-' README.md | head -3
7:![Tests](https://img.shields.io/badge/Tests-643%2F643_passing-green)
```

The 2026-08-01 run recorded **7 warnings / 0 errors** for KickCD, all seven outside the seam files
and correctly not counted against the adoption. That is now fixed. The suite total has not moved
from the 643 the prompt quotes.

### §8.3 ConsumableMaster — 554 / 0, 0 warnings in 50 files

cwd=CM

```
$ lua tests/run.lua
… (554 PASS lines; tail shown)
  PASS  WeaponSlots: a slot the client cannot report is safe to query
  PASS  Widgets: every custom widget registers itself with AceGUI
  PASS  Widgets: each registration supplies a constructor function
  PASS  Widgets: each registration declares a positive integer version
  PASS  Widgets: the version guard skips a widget already registered at that version
  PASS  Widgets: no two widgets claim the same type name
  PASS  Widgets: every widget name used by the settings pages is registered

  554 passed, 0 failed, 554 total

$ luacheck .
… (tail shown)
Checking modules/PerfSetup.lua                     OK
Checking modules/Ranker.lua                        OK
Checking modules/Selector.lua                      OK
Checking settings/Category.lua                     OK
Checking settings/General.lua                      OK
Checking settings/MacroBar.lua                     OK
Checking settings/Panel.lua                        OK
Checking settings/StatPriority.lua                 OK

Total: 0 warnings / 0 errors in 50 files

$ grep -n -A 8 'Totals' docs/test-cases.md | sed -n '1,4p'
653:## Totals
655-| Suite | Cases |
$ grep -n '\*\*Total\*\*' docs/test-cases.md
687:| **Total** | **554** |

$ grep -n 'Tests-' README.md
7:![Tests](https://img.shields.io/badge/Tests-554%2F554_passing-green)
```

Zero warnings, therefore zero inside the five seam files (`core/CoreSetup.lua`,
`modules/DebugLog.lua`, `core/SlashCommands.lua`, `settings/Panel.lua`, `modules/PerfSetup.lua`)
and zero elsewhere. The host also now documents the vendor gate itself:

```
$ grep -n -A 14 'strip-trailing-cr' docs/testing.md | head -20
26:diff -r --strip-trailing-cr ../LibKa0s/LibKa0s libs/LibKa0s    # content — MUST be empty
27-diff -r ../LibKa0s/LibKa0s libs/LibKa0s                        # bytes  — SHOULD be empty
28:diff -r --strip-trailing-cr ../LibKa0s/testkit tests/_kit       # content — MUST be empty
29-diff -r ../LibKa0s/testkit tests/_kit                           # bytes  — SHOULD be empty
30-```
32-Both halves, because the two answers are different findings.
34-**Content differs** → a real fork in `libs/`, which is the forbidden state. Name every hunk.
36-**Bytes differ but content matches** → a line-ending divergence, not a fork. Both repos pin
37-`* text=auto eol=crlf` over LF blobs, so a working tree holding *either* ending reads clean to
38-`git status` and neither side's cleanliness proves anything. Find which side drifted (`file -b
39-<path>`, and `git cat-file -p HEAD:<path> | file -b -` for what git stores) and renormalise it.
40-**Re-vendoring will not converge it, and the fix is never an edit to `libs/`** — that makes a fork
```

### §8.4 BankLedger — 684 / 0, 0 warnings in 24 files

cwd=BL. Tail of the run, showing the whole LibKa0s block:

```
$ lua tests/run.lua
…
  PASS  LibKa0s: the harness loads every file LibKa0s.xml declares, in XML order
  PASS  LibKa0s: the vendored folder carries the licence it ships under
  PASS  LibKa0s-Core: the seam loads after core/Namespace.lua, which defines NS.PREFIX
  PASS  LibKa0s-Core: the seam loads before the AceConsole reclaim in core/BankLedger.lua
  PASS  LibKa0s-Core: the seam loads before every file that captures NS.Print at load
  PASS  LibKa0s-DebugLog: the vendored major registered and the console is running on it
  PASS  LibKa0s-DebugLog: the module needs the minor that carries the chrome hooks
  PASS  LibKa0s-DebugLog: NS.Debug is bound and still gates on the session-only flag
  PASS  LibKa0s-DebugLog: the enable seam reads and writes NS.State.debug, never SavedVariables
  PASS  LibKa0s-DebugLog: the window title composes to exactly what the old console rendered
  PASS  LibKa0s-DebugLog: the console wears THIS addon's chrome, not Core's
  PASS  LibKa0s-DebugLog: a 24-wide host close button does not collide with Clear
  PASS  LibKa0s-DebugLog: every user-visible string resolves to prose, not to its own key
  PASS  LibKa0s-DebugLog degraded: the console degrades to an honest stub, not an error
  PASS  LibKa0s-DebugLog degraded: the consequence is appended to the SHARED cause clause
  PASS  LibKa0s-DebugLog degraded: the session flag still flips, because it gates more than the window
  PASS  LibKa0s-DebugLog: the seam loads after Constants (FONT_MONO) and after the Core seam
  PASS  LibKa0s-DebugLog: modules/DebugLog.lua is gone from the TOC and from disk
  PASS  LibKa0s-DebugLog: the chat acknowledgement still carries the [BL] tag
  PASS  LibKa0s-DebugLog: hiding the console repaints the settings panel
  PASS  LibKa0s-Slash: the vendored major registered and the CLI is running on it
  PASS  LibKa0s-Slash: the module needs the minor that carries the format hook
  PASS  LibKa0s-Slash: every printed line still carries the [BL] tag
  PASS  LibKa0s-Slash: /bl list keeps its section headings
  PASS  LibKa0s-Slash: a set-typed row renders as a set, never as the secret sentinel
  PASS  LibKa0s-Slash: the format hook defers to the library for every OTHER row type
  PASS  LibKa0s-Slash: booleans are settable, because the schema says 'bool'
  PASS  LibKa0s-Slash: a numeric dropdown now REFUSES a value outside its list
  PASS  LibKa0s-Slash: a slider value out of range CLAMPS rather than storing what was typed
  PASS  LibKa0s-Slash: a set-typed row refuses a chat edit, and says where it CAN be edited
  PASS  LibKa0s-Slash: CliResetAll keeps this addon's two carve-outs
  PASS  LibKa0s-Slash: the landing page and the chat help render the SAME rows
  PASS  LibKa0s-Slash: reset takes a PATH and resetall takes none — already converged
  PASS  LibKa0s-Slash: every user-visible string resolves to prose, not to its own key
  PASS  LibKa0s-Slash degraded: the verbs that never needed the library still work
  PASS  LibKa0s-Slash degraded: the CLI explains itself through the SHARED cause clause
  PASS  LibKa0s-Slash degraded: resetall still WORKS rather than merely explaining itself
  PASS  LibKa0s-Slash: the seam loads after the schema it reads

684 passed, 0 failed, 684 total
```

```
$ luacheck .
Checking core/BankLedger.lua                      OK
Checking core/Compat.lua                          OK
Checking core/Constants.lua                       OK
Checking core/CoreSetup.lua                       OK
Checking core/Database.lua                        OK
Checking core/DebugLogSetup.lua                   OK
Checking core/Namespace.lua                       OK
Checking core/State.lua                           OK
Checking core/Util.lua                            OK
Checking defaults/Global.lua                      OK
Checking locales/PostLoad.lua                     OK
Checking locales/enUS.lua                         OK
Checking modules/Browser.lua                      OK
Checking modules/Export.lua                       OK
Checking modules/Filters.lua                      OK
Checking modules/Insights.lua                     OK
Checking modules/InsightsWidgets.lua              OK
Checking modules/Ledger.lua                       OK
Checking modules/LedgerTable.lua                  OK
Checking modules/SessionWindow.lua                OK
Checking settings/OptionsSetup.lua                OK
Checking settings/Panel.lua                       OK
Checking settings/Schema.lua                      OK
Checking settings/Slash.lua                       OK

Total: 0 warnings / 0 errors in 24 files

$ grep -n 'exclude_files' -A3 .luacheckrc
4:exclude_files = { "libs/", "docs/audits/", "docs/reviews/", "_dev/", "tests/" }
5-ignore = {
6-  "212/self",   -- unused argument self
7-  "212/event",  -- unused argument event
8-}
```

All four seam files are inside the checked set and all four are `OK`, so the clean result is
meaningful rather than an artefact of exclusion. `tests/` is unlinted.

The silently-skipped-suite hazard, checked in both directions:

```
$ ls tests/test_*.lua
tests/test_browser.lua
tests/test_compat.lua
tests/test_constants.lua
tests/test_database.lua
tests/test_debuglog.lua
tests/test_export.lua
tests/test_filters.lua
tests/test_harness.lua
tests/test_insights.lua
tests/test_ledger.lua
tests/test_ledgertable.lua
tests/test_libka0s.lua
tests/test_panel.lua
tests/test_schema.lua
tests/test_sessionwindow.lua
tests/test_slash.lua
tests/test_stats.lua
tests/test_util.lua

$ grep -n -A7 'local SUITES = {' tests/run.lua
18:local SUITES = {
19-  "test_util", "test_compat", "test_constants", "test_filters",
20-  "test_ledger", "test_database", "test_stats", "test_ledgertable",
21-  "test_browser", "test_sessionwindow", "test_insights",
22-  "test_export", "test_debuglog", "test_schema", "test_slash",
23-  "test_panel", "test_harness", "test_libka0s",
24-}

$ grep -n -A12 'local LIBKA0S_FILES' tests/run.lua
31:local LIBKA0S_FILES = {
32-  "libs/LibKa0s/Core.lua",
33-  "libs/LibKa0s/DebugLog.lua",
34-  "libs/LibKa0s/Slash.lua",
35-  "libs/LibKa0s/Options.lua",
36-  "libs/LibKa0s/OptionsWidgets.lua",
37-  "libs/LibKa0s/OptionsScroll.lua",
38-  "libs/LibKa0s/Perf.lua",
39-  "libs/LibKa0s/PerfPanel.lua",
40-}
```

18 listed, 18 on disk, and the runner loads all eight library files rather than only the four
adopted majors. Badge, inventory and live run all agree:

```
$ grep -n -i 'Tests' README.md | head -3
7:![Tests](https://img.shields.io/badge/Tests-684%2F684_passing-green)

$ awk '/^## Totals/,0' docs/test-cases.md
## Totals

| Suite | Cases |
|-------|------:|
| test_util.lua | 31 |
| test_compat.lua | 21 |
| test_constants.lua | 21 |
| test_filters.lua | 15 |
| test_ledger.lua | 113 |
| test_database.lua | 42 |
| test_stats.lua | 59 |
| test_ledgertable.lua | 49 |
| test_browser.lua | 33 |
| test_sessionwindow.lua | 32 |
| test_insights.lua | 72 |
| test_export.lua | 34 |
| test_debuglog.lua | 18 |
| test_schema.lua | 26 |
| test_slash.lua | 33 |
| test_panel.lua | 23 |
| test_harness.lua | 7 |
| test_libka0s.lua | 55 |
| **Total** | **684** |
```

The vendor gate is written into `docs/testing.md`:

```
$ grep -n -A14 'strip-trailing-cr' docs/testing.md | head -18
25:diff -r --strip-trailing-cr ../LibKa0s/LibKa0s libs/LibKa0s    # content — MUST be empty
26-diff -r ../LibKa0s/LibKa0s libs/LibKa0s                        # bytes  — SHOULD be empty
27:diff -r --strip-trailing-cr ../LibKa0s/testkit tests/_kit      # content — MUST be empty
28-diff -r ../LibKa0s/testkit tests/_kit                          # bytes  — SHOULD be empty
29-```
30-
31-**Run both of each pair and read the difference between them.**
32-
33-- **Content differs** — a copy has genuinely forked. That is the forbidden state. The fix is to
34-  re-vendor whole-folder (`cp -r ../LibKa0s/LibKa0s/. libs/LibKa0s/`), never to edit `libs/`.
35-- **Content identical, bytes differ** — nothing has forked; the two checkouts merely disagree about
36-  line endings. Renormalise whichever side drifted. It is **never** an edit to `libs/`, and
37-  re-vendoring will not converge it either — that just moves the wrong endings downstream.
38-- **Both empty** — the vendored copies are current.
```

### §8.5 The four suite totals side by side

cwd=GIT

```
$ for a in AbsorbTracker BankLedger ConsumableMaster KickCD; do echo -n "$a "; grep -iE '^\|?\s*\*?\*?(Total)' $a/docs/test-cases.md | tail -1; done
AbsorbTracker | **Total** | **462** |
BankLedger | **Total** | **684** |
ConsumableMaster | **Total** | **554** |
KickCD | **Total** | **643** |
```

**Not checked:** AbsorbTracker's `docs/testing.md` does not carry the vendor gate. Two greps
(cwd=AT):

```
$ grep -n 'diff -r' docs/testing.md
(no output)

$ grep -n -i 'vendor\|diff\|strip-trailing-cr\|libka0s' docs/testing.md
5:`## Interface:` / refreshing vendored libs. Conforms to the Ka0s WoW Addon Standard `testing`
32:`tests/test_perf.lua`, covering this addon's side of the `LibKa0s-Perf-1.0` harness (issue #17) —
35:LibKa0s repo, not duplicated here.
39:`LibKa0s-DebugLog-1.0` and is tested in the LibKa0s repo; what stays here is this addon's wiring,
40:plus the degradation stub that answers when the vendored library is missing. ...
47:check and its color rescale — is `LibKa0s-Slash-1.0` and is tested in the LibKa0s repo. ...
58:patch are `LibKa0s-Options-1.0` and are tested in the LibKa0s repo. ...
70:environment from the TOC with `libs/LibKa0s/` absent and asserts `#NS.Schema` against the ...
76:rather than running it. Every LibKa0s module taking an `L` override resolves the descriptor's ...
86:vendored DebugLog, Slash and Perf the exact fallback shape every Ka0s host has and require ...
120:diff <(lua tests/run.lua --list) docs/test-cases.md   # no output == in sync
```

The only `diff` documented there is the test-case-list sync at line 120. `CLAUDE.md:34`–`:46`
states the rule ("never edit it here — change it upstream and re-vendor"); the check is absent.

KickCD's `docs/testing.md` was not examined by its collector, so this run has no evidence either
way for that repo.

---

## §9 — Provenance

### §9.1 The four README lines and the four LICENSE files, side by side

cwd=GIT

```
$ for a in AbsorbTracker BankLedger ConsumableMaster KickCD; do echo "--- $a"; ls $a/libs/LibKa0s/; grep -in 'LibKa0s' $a/README.md | head -2; done
--- AbsorbTracker
Core.lua
DebugLog.lua
LICENSE
LibKa0s.xml
Options.lua
OptionsScroll.lua
OptionsWidgets.lua
Perf.lua
PerfPanel.lua
Slash.lua
143:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.2.0 (MIT) — the shared Ka0s
145:settings panel toolkit and the perf harness. It ships in `libs/LibKa0s/`, license included.
--- BankLedger
Core.lua
DebugLog.lua
LICENSE
LibKa0s.xml
Options.lua
OptionsScroll.lua
OptionsWidgets.lua
Perf.lua
PerfPanel.lua
Slash.lua
11:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.2.0 (MIT).
--- ConsumableMaster
Core.lua
DebugLog.lua
LICENSE
LibKa0s.xml
Options.lua
OptionsScroll.lua
OptionsWidgets.lua
Perf.lua
PerfPanel.lua
Slash.lua
274:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.2.0 (MIT).
276:It supplies the chat printer, the debug console, the slash dispatcher and schema CLI, the settings-panel shell and its row widgets, and the perf-capture harness. It is vendored under `libs/LibKa0s/` and ships with its own `LICENSE`. The version named above is the answer to "which LibKa0s does this build carry?" — it moves whenever `libs/LibKa0s/` is re-vendored, and nothing else in the package records it.
--- KickCD
Core.lua
DebugLog.lua
LICENSE
LibKa0s.xml
Options.lua
OptionsScroll.lua
OptionsWidgets.lua
Perf.lua
PerfPanel.lua
Slash.lua
197:*   Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.2.0 (MIT). The shared Ka0s addon library — KickCD takes five of its modules: Core (the secret-safe printer), DebugLog (the on-screen console), Slash (the `/kcd` dispatcher and schema CLI), Options (the settings panel) and Perf (the A/B capture harness). Its licence travels with the code at `libs/LibKa0s/LICENSE`.
200:Whenever the vendored copy is refreshed, the LibKa0s version named above moves with it — that line is the answer to "which LibKa0s does this build carry?", so nobody has to grep minors out of `libs/LibKa0s/*.lua`.
```

All four name **v1.2.0**, and v1.2.0 is exactly what §2 shows is vendored. The 2026-08-01 run found
no provenance line in any consumer and no `LICENSE` inside any `libs/LibKa0s/`; both are fixed
across the collection.

### §9.2 Per-consumer detail

cwd=AT — the README line is the whole record, because there is no CHANGELOG:

```
$ grep -n -i 'libka0s' README.md
143:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.2.0 (MIT) — the shared Ka0s
145:settings panel toolkit and the perf harness. It ships in `libs/LibKa0s/`, license included.

$ ls
AbsorbTracker.toc  CLAUDE.md  LICENSE  README.md  core  defaults  docs  libs
locales  media  modules  settings  tests

$ head -3 libs/LibKa0s/LICENSE
MIT License

Copyright (c) 2026 Ka0s

$ cat .pkgmeta
package-as: AbsorbTracker

enable-nolib-creation: no

ignore:
  - docs
  - tests
  - _dev
  - .luacheckrc
  - .gitattributes
  - .gitignore
  - "*.bak"
```

`tests/` is ignored so the kit is never zipped, and `libs/` is the ship payload carrying the licence.

cwd=KCD:

```
$ ls CHANGELOG.md docs/release-notes*
(no such files — KickCD keeps no CHANGELOG; ledger LIBKA0S-03 records that)

$ grep -c -i copyright libs/LibKa0s/*.lua
libs/LibKa0s/Core.lua:0
libs/LibKa0s/DebugLog.lua:3
libs/LibKa0s/Options.lua:0
libs/LibKa0s/OptionsScroll.lua:0
libs/LibKa0s/OptionsWidgets.lua:0
libs/LibKa0s/Perf.lua:0
libs/LibKa0s/PerfPanel.lua:0
libs/LibKa0s/Slash.lua:0
```

cwd=CM — the licence is proven to have arrived by whole-folder copy:

```
$ ls -l libs/LibKa0s/LICENSE
-rwxrwxrwx 1 tushar tushar 1084 Aug  1 15:32 libs/LibKa0s/LICENSE
$ diff libs/LibKa0s/LICENSE ../LibKa0s/LibKa0s/LICENSE && echo "LICENSE identical to ship"
LICENSE identical to ship
```

cwd=BL:

```
$ ls -la libs/LibKa0s/
total 216
drwxrwxrwx 1 tushar tushar  4096 Aug  1 17:34 .
drwxrwxrwx 1 tushar tushar  4096 Aug  1 17:34 ..
-rwxrwxrwx 1 tushar tushar 10481 Aug  1 17:34 Core.lua
-rwxrwxrwx 1 tushar tushar 34257 Aug  1 17:34 DebugLog.lua
-rwxrwxrwx 1 tushar tushar  1084 Aug  1 17:34 LICENSE
-rwxrwxrwx 1 tushar tushar   309 Aug  1 17:34 LibKa0s.xml
-rwxrwxrwx 1 tushar tushar 35337 Aug  1 17:34 Options.lua
-rwxrwxrwx 1 tushar tushar  7559 Aug  1 17:34 OptionsScroll.lua
-rwxrwxrwx 1 tushar tushar 30778 Aug  1 17:34 OptionsWidgets.lua
-rwxrwxrwx 1 tushar tushar 47242 Aug  1 17:34 Perf.lua
-rwxrwxrwx 1 tushar tushar 11594 Aug  1 17:34 PerfPanel.lua
-rwxrwxrwx 1 tushar tushar 26505 Aug  1 17:34 Slash.lua

  PASS  LibKa0s: the vendored folder carries the licence it ships under
```

`tests/test_libka0s.lua` states the reason that case exists: the licence's absence "means someone
vendored file-by-file, which is the thing whole-folder vendoring exists to stop."

AbsorbTracker's `libs/LibKa0s/` listing was captured with sizes and timestamps (cwd=AT), which is
what shows all ten files arrived in one operation:

```
$ ls -la libs/LibKa0s/
total 216
drwxrwxrwx 1 tushar tushar  4096 Aug  1 11:20 .
drwxrwxrwx 1 tushar tushar  4096 Jul 31 08:34 ..
-rwxrwxrwx 1 tushar tushar 10481 Aug  1 15:32 Core.lua
-rwxrwxrwx 1 tushar tushar 34257 Aug  1 15:32 DebugLog.lua
-rwxrwxrwx 1 tushar tushar  1084 Aug  1 15:32 LICENSE
-rwxrwxrwx 1 tushar tushar   309 Aug  1 15:32 LibKa0s.xml
-rwxrwxrwx 1 tushar tushar 35337 Aug  1 15:32 Options.lua
-rwxrwxrwx 1 tushar tushar  7559 Aug  1 15:32 OptionsScroll.lua
-rwxrwxrwx 1 tushar tushar 30778 Aug  1 15:32 OptionsWidgets.lua
-rwxrwxrwx 1 tushar tushar 47242 Aug  1 15:32 Perf.lua
-rwxrwxrwx 1 tushar tushar 11594 Aug  1 15:32 PerfPanel.lua
-rwxrwxrwx 1 tushar tushar 26505 Aug  1 15:32 Slash.lua
```

KickCD's is identical in every size (cwd=KCD, `ls -la libs/LibKa0s/`, same ten entries, same byte
counts, timestamps `Aug 1 15:32`).

### §9.3 Per-file copyright headers — a library fact, not a consumer one

cwd=LIB

```
$ grep -c -i copyright LibKa0s/*.lua
LibKa0s/Core.lua:0
LibKa0s/DebugLog.lua:3
LibKa0s/Options.lua:0
LibKa0s/OptionsScroll.lua:0
LibKa0s/OptionsWidgets.lua:0
LibKa0s/Perf.lua:0
LibKa0s/PerfPanel.lua:0
LibKa0s/Slash.lua:0

$ grep -n -i copyright LibKa0s/DebugLog.lua
319:    local copyRight  = clearRight - CLEAR_W - PAD
324:    frame.titleBarOffsets = { close = -PAD, clear = clearRight, copy = copyRight }
329:    copyBtn:SetPoint("RIGHT", titleBar, "RIGHT", copyRight, 0)
```

DebugLog's three hits are a `copyRight` local holding the Copy button's x-offset, not a notice, so
the true header count is **zero of eight**. That is the deliberate state recorded at
`CHANGELOG.md:166-167` (v1.1.1): per-file headers were considered and declined because they would
touch all eight files and bump all eight minors without altering behaviour. Because the ship folder
is byte-identical in every consumer, the same count holds in all four and is not a consumer finding.

---

## §10 — Ship side: line endings, release state, kit sync

### §10.1 Line endings across the whole library repo

cwd=LIB. `.gitattributes`, verbatim:

```
# Force every text file to land on disk with CRLF line endings, regardless
# of each contributor's `core.autocrlf` / `core.eol` settings. WoW expects
# CRLF in addon source files, and contributors on Linux/macOS would
# otherwise check out LF.
#
# `text=auto` lets Git auto-detect text vs binary on first add; `eol=crlf`
# pins the working-tree line ending for everything classified as text.
* text=auto eol=crlf

# Explicit text — same effect as the default but documents intent for the
# files we know are source.
*.lua  text eol=crlf
*.toc  text eol=crlf
*.xml  text eol=crlf
*.md   text eol=crlf
*.json text eol=crlf

# Binaries — never touch line endings, never try to diff as text.
*.png  binary
*.jpg  binary
*.jpeg binary
*.tga  binary
*.blp  binary
*.ttf  binary
*.otf  binary
*.mp3  binary
*.ogg  binary
```

Every tracked file in the working tree:

```
$ git ls-files | wc -l
60
$ git ls-files | while read -r f; do file -b "$f"; done | grep -c CRLF
60
$ git ls-files | while read -r f; do file -b "$f"; done | grep -vc CRLF
0
```

Per-file, abridged to the ship folder and the kit (every one of the 60 reported CRLF):

```
Unicode text, UTF-8 text, with CRLF line terminators | .gitattributes
ASCII text, with CRLF line terminators | .gitignore
Unicode text, UTF-8 text, with CRLF line terminators | .luacheckrc
Unicode text, UTF-8 text, with CRLF line terminators | CHANGELOG.md
ASCII text, with CRLF line terminators | LICENSE
JavaScript source, Unicode text, UTF-8 text, with CRLF line terminators | LibKa0s/Core.lua
Unicode text, UTF-8 text, with CRLF line terminators | LibKa0s/DebugLog.lua
ASCII text, with CRLF line terminators | LibKa0s/LICENSE
HTML document, ASCII text, with CRLF line terminators | LibKa0s/LibKa0s.xml
Unicode text, UTF-8 text, with CRLF line terminators | LibKa0s/Options.lua
Unicode text, UTF-8 text, with CRLF line terminators | LibKa0s/OptionsScroll.lua
Unicode text, UTF-8 text, with CRLF line terminators | LibKa0s/OptionsWidgets.lua
Unicode text, UTF-8 text, with CRLF line terminators | LibKa0s/Perf.lua
Unicode text, UTF-8 text, with CRLF line terminators | LibKa0s/PerfPanel.lua
Unicode text, UTF-8 text, with CRLF line terminators | LibKa0s/Slash.lua
Unicode text, UTF-8 text, with very long lines (804), with CRLF line terminators | README.md
Unicode text, UTF-8 text, with CRLF line terminators | testkit/README.md
HTML document, Unicode text, UTF-8 text, with CRLF line terminators | testkit/framework.lua
Unicode text, UTF-8 text, with CRLF line terminators | testkit/loader.lua
Unicode text, UTF-8 text, with CRLF line terminators | testkit/mock_base.lua
Unicode text, UTF-8 text, with CRLF line terminators | tests/_kit/README.md
HTML document, Unicode text, UTF-8 text, with CRLF line terminators | tests/_kit/framework.lua
Unicode text, UTF-8 text, with CRLF line terminators | tests/_kit/loader.lua
Unicode text, UTF-8 text, with CRLF line terminators | tests/_kit/mock_base.lua
...
(all 60 tracked files reported CRLF; none reported otherwise)
```

What git stores:

```
$ git ls-files | while read -r f; do echo "$(git cat-file -p "HEAD:$f" | file -b -) | $f"; done
Unicode text, UTF-8 text | LibKa0s/Slash.lua
Unicode text, UTF-8 text | LibKa0s/PerfPanel.lua
Unicode text, UTF-8 text | LibKa0s/Perf.lua
Unicode text, UTF-8 text | LibKa0s/OptionsWidgets.lua
Unicode text, UTF-8 text | LibKa0s/OptionsScroll.lua
Unicode text, UTF-8 text | LibKa0s/Options.lua
Unicode text, UTF-8 text | LibKa0s/DebugLog.lua
JavaScript source, Unicode text, UTF-8 text | LibKa0s/Core.lua
HTML document, ASCII text | LibKa0s/LibKa0s.xml
ASCII text | LibKa0s/LICENSE
Unicode text, UTF-8 text | CHANGELOG.md
Unicode text, UTF-8 text, with very long lines (804) | README.md
Unicode text, UTF-8 text | testkit/framework.lua  (HTML document, per file(1) heuristic)
...
(no blob reported "with CRLF line terminators" — every blob is LF)
```

The 2026-08-01 run's §1 found 16 of 49 tracked files LF in the working tree, including four ship
files, `README.md`, `CHANGELOG.md` and three docs. Today: 60 of 60 CRLF, zero LF, every blob LF,
`git status` clean, and the sixteen vendor diffs empty (§3.1). **How** it was fixed could not be
established — no commit in the last 25 is named as a renormalisation, so this establishes current
state, not cause.

### §10.2 Release state — tags, log, working tree

cwd=LIB

```
$ git tag
v1.0.0
v1.1.0
v1.1.1

$ git describe --tags
v1.1.1-7-g8d1d879

$ git log --oneline -25
8d1d879 feat(options): stamp the Blizzard canvas contract in CreatePanel (Options minor 5)
3ea1c51 docs(releasing): record BankLedger as an Options consumer, and its Perf decline
c868556 feat(options): render a numeric enum as a dropdown (OptionsWidgets minor 5)
410da0b docs(releasing): record BankLedger as a Slash consumer
1aab478 feat(slash): let a host render a value type the library does not know (Slash minor 5)
ff08aef docs(releasing): record BankLedger as a Core and DebugLog consumer
3b47c9f feat(debuglog): let a host own its window chrome (DebugLog minor 4)
daf7511 Fold the 2026-08-01 adoption learnings into the prompt
2d0abed docs: sync the README to what the library actually ships
84797aa Cut v1.1.1, and stop the additive-change proof going stale
0aca70f docs: make the vendoring gate line-ending-proof, and fix what the prompt got wrong
17d6137 Ship LICENSE inside the library payload
e210d6c docs: commit the 2026-08-01 adoption report bundle
9de8d1e docs: ConsumableMaster is an adopter, not a target
b3daa04 Release v1.1.0
9126691 Guard each row, add RenderGrid, never offer an empty media list
60ad9cb Release v1.0.0
5db964e docs: the release's surface, and ConsumableMaster as a consumer
c80a65f Options 3: page guards, a combat refusal, and two refresh tiers
4cd5d6c Alpha on by default, tooltip alias, opt-in live sliders
334a325 Render positional colours and give Slash a codec
e97fca1 Read the ordered-array enum shape: Slash 4, OptionsWidgets 3
2924143 Perf 5: read `interface` from GetBuildInfo — it was always 0
629658f Resolve L overrides with rawget: DebugLog 3, Slash 3, Perf 4
9473d49 docs: say what to do when adoption reveals a library gap

$ git status
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean

$ grep -nE '^## ' CHANGELOG.md | head -20
13:## v1.2.0 — 2026-08-01
142:## v1.1.1 — 2026-08-01
168:## v1.1.0 — 2026-08-01
207:## v1.0.0 — 2026-08-01
```

**There is no `v1.2.0` tag.** HEAD is seven commits past `v1.1.1` — the four feature commits and
the three `docs(releasing)` commits. Release step 6 ("commit and tag the repo semver") has not been
done, while steps 1–5 and 7 have: the CHANGELOG block exists, the eight minors are bumped, all four
consumers are re-vendored to those minors (§2, §3.1), all four carry `LICENSE` inside
`libs/LibKa0s/` and all four README provenance lines read v1.2.0 (§9).

The step-7 sweep the ship-side collector ran, verbatim:

```
$ for a in AbsorbTracker KickCD ConsumableMaster BankLedger; do
    grep -hoE 'local (MAJOR, )?(MINOR|WIDGETS_MINOR|SCROLL_MINOR|PANEL_MINOR) *= *("[^"]+", *)?[0-9]+' ../$a/libs/LibKa0s/*.lua
    grep -n -i 'LibKa0s.*v[0-9]' ../$a/README.md
  done

===== AbsorbTracker vendored minors =====
local MAJOR, MINOR = "LibKa0s-Core-1.0", 2
local MAJOR, MINOR = "LibKa0s-DebugLog-1.0", 4
local MAJOR, MINOR = "LibKa0s-Options-1.0", 5
local SCROLL_MINOR = 2
local WIDGETS_MINOR = 5
local MAJOR, MINOR = "LibKa0s-Perf-1.0", 5
local PANEL_MINOR = 3
local MAJOR, MINOR = "LibKa0s-Slash-1.0", 5
-- README provenance --
143:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.2.0 (MIT) — the shared Ka0s
-- LICENSE present --
Core.lua DebugLog.lua LICENSE LibKa0s.xml Options.lua OptionsScroll.lua OptionsWidgets.lua Perf.lua PerfPanel.lua Slash.lua

===== KickCD vendored minors =====
(identical eight values)
-- README provenance --
197:*   Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.2.0 (MIT). The shared Ka0s addon library — KickCD takes five of its modules: …
-- LICENSE present --
Core.lua DebugLog.lua LICENSE LibKa0s.xml Options.lua OptionsScroll.lua OptionsWidgets.lua Perf.lua PerfPanel.lua Slash.lua

===== ConsumableMaster vendored minors =====
(identical eight values)
-- README provenance --
274:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.2.0 (MIT).
-- LICENSE present --
Core.lua DebugLog.lua LICENSE LibKa0s.xml Options.lua OptionsScroll.lua OptionsWidgets.lua Perf.lua PerfPanel.lua Slash.lua

===== BankLedger vendored minors =====
(identical eight values)
-- README provenance --
11:Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.2.0 (MIT).
-- LICENSE present --
Core.lua DebugLog.lua LICENSE LibKa0s.xml Options.lua OptionsScroll.lua OptionsWidgets.lua Perf.lua PerfPanel.lua Slash.lua
```

`tests/run.lua`'s `MAJORS` table carries five rows (Core, DebugLog, Slash, Options with
`files = { Options, OptionsWidgets, OptionsScroll }` and two `paired` entries, Perf with
`paired = { PerfPanel }`), matching `LibKa0s/LibKa0s.xml`'s eight `<Script>` lines in order. No
major was added this release.

### §10.3 The library's own green gate

cwd=LIB

```
$ lua tests/run.lua
...
  PASS  versioning: every declared major is actually registered
  PASS  versioning: every file in every major registers its live version
  PASS  versioning: no file registers under a major it does not belong to
  PASS  versioning: every registered version is a positive integer
  PASS  versioning: file basenames are unique across every major
  PASS  versioning: the changelog accounts for the version every file is at
  PASS  versioning: every paired secondary file records which primary it attached to
  PASS  kitsync: testkit/ and tests/_kit/ hold the same set of files
  PASS  kitsync: every kit file is byte-identical in testkit/ and tests/_kit/, README included

407 passed, 0 failed, 407 total

$ luacheck .
Checking LibKa0s/Core.lua                         OK
Checking LibKa0s/DebugLog.lua                     OK
Checking LibKa0s/Options.lua                      OK
Checking LibKa0s/OptionsScroll.lua                OK
Checking LibKa0s/OptionsWidgets.lua               OK
Checking LibKa0s/Perf.lua                         OK
Checking LibKa0s/PerfPanel.lua                    OK
Checking LibKa0s/Slash.lua                        OK
Checking testkit/framework.lua                    OK
Checking testkit/loader.lua                       OK
Checking testkit/mock_base.lua                    OK

Total: 0 warnings / 0 errors in 11 files

$ grep -n -i 'Total' docs/test-cases.md | tail -3
452:## Totals
468:| **Total** | **407** |

$ lua tests/run.lua --list | tail -5
| test_perf_command.lua | 17 |
| test_perf_isolation.lua | 9 |
| test_versioning.lua | 7 |
| test_kitsync.lua | 2 |
| **Total** | **407** |
```

`.luacheckrc` carries `exclude_files = { "tests/", "docs/" }`, so 11 files are linted — the eight
ship files plus the three `testkit/` files. The 21 files under `tests/`, including the vendored
`tests/_kit/` copies, are never linted here. This repo's README carries no `[tests]` badge, so
there is nothing to drift.

### §10.4 Kit sync — `testkit/` against `tests/_kit/`

cwd=LIB

```
$ diff -rq testkit tests/_kit
exit=0
$ diff -rq --strip-trailing-cr testkit tests/_kit
exit=0

$ md5sum testkit/* tests/_kit/*
dd87b53273a412b0311af603e819230a  testkit/README.md
e7ef488b4c7579d0ce5fb8675161cb9e  testkit/framework.lua
b864e057bd1ac1b384e202cf876f25e7  testkit/loader.lua
53b60463eeecbb552447cd7865fabc62  testkit/mock_base.lua
dd87b53273a412b0311af603e819230a  tests/_kit/README.md
e7ef488b4c7579d0ce5fb8675161cb9e  tests/_kit/framework.lua
b864e057bd1ac1b384e202cf876f25e7  tests/_kit/loader.lua
53b60463eeecbb552447cd7865fabc62  tests/_kit/mock_base.lua

$ wc -c testkit/* tests/_kit/*
 5933 testkit/README.md
 7467 testkit/framework.lua
 3703 testkit/loader.lua
28093 testkit/mock_base.lua
 5933 tests/_kit/README.md
 7467 tests/_kit/framework.lua
 3703 tests/_kit/loader.lua
28093 tests/_kit/mock_base.lua
90392 total
```

Four files each side, identical hash and byte count, and `test_kitsync`'s two cases pass. Both
sides are now CRLF, where the earlier report noted they were both LF and therefore agreed by
accident — one stray editor write from firing.

### §10.5 Licence, ship side

cwd=LIB

```
$ ls -l LibKa0s/
-rwxrwxrwx 10481 Core.lua
-rwxrwxrwx 34257 DebugLog.lua
-rwxrwxrwx  1084 LICENSE
-rwxrwxrwx   309 LibKa0s.xml
-rwxrwxrwx 35337 Options.lua
-rwxrwxrwx  7559 OptionsScroll.lua
-rwxrwxrwx 30778 OptionsWidgets.lua
-rwxrwxrwx 47242 Perf.lua
-rwxrwxrwx 11594 PerfPanel.lua
-rwxrwxrwx 26505 Slash.lua

$ diff LICENSE LibKa0s/LICENSE
(no output — identical)

$ head -4 LibKa0s/LICENSE
MIT License

Copyright (c) 2026 Ka0s
```

### §10.6 Stale references in the library's own documents

cwd=LIB

```
$ grep -rn 'v1\.1\.1\|v1\.2\.0' docs/releasing.md docs/adoption-prompt.md README.md
docs/releasing.md:7:| Repo semver (`v1.2.0`) | git tag, `CHANGELOG.md` heading | humans | once per release |
docs/releasing.md:62:> Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.1.1 (MIT).
docs/adoption-prompt.md:393:11. **Provenance.** `LICENSE` ships inside the payload as of v1.1.1, so a whole-folder copy carries
docs/adoption-prompt.md:398:    Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.1.1 (MIT).
README.md:741:different vendored copy of each. As of **v1.2.0**: `Core = { Core = 2 }`,
```

`docs/releasing.md:7` already says v1.2.0, but the provenance template five lines later (`:62`)
still says v1.1.1, as does the adoption prompt's copy (`:398`). All four consumers already carry
v1.2.0, so following the written template today would downgrade a correct line.
`adoption-prompt.md:393`'s "as of v1.1.1" is a historical statement about when `LICENSE` started
shipping and is correct.

`README.md:741-744`'s `MODULES` recital — `Core = { Core = 2 }`, `DebugLog = { DebugLog = 4 }`,
`Slash = { Slash = 5 }`, `Options = { Options = 5, OptionsWidgets = 5, OptionsScroll = 2 }`,
`Perf = { Perf = 5, PerfPanel = 3 }` — matches the live constants.

---

## §11 — Cross-cutting

### §11.1 Call-site verification for the single- and zero-consumer candidates

The counts in §5.6 are name matches. These are the actual call sites. cwd=GIT throughout; every
grep excludes `/libs/` and `/tests/`.

```
$ grep -rn 'SKIN' AbsorbTracker BankLedger ConsumableMaster KickCD --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
BankLedger/core/DebugLogSetup.lua:97:  -- LIBKA0S-05): Core.SKIN is a 12px UI-Tooltip-Border where every Bank Ledger window wears a flat
BankLedger/modules/Browser.lua:16:-- Flat skin, built from stock Blizzard textures only. Centralised here as one SKIN table + one
BankLedger/modules/Browser.lua:21:local SKIN = {
BankLedger/modules/Browser.lua:35:B.SKIN = SKIN
BankLedger/modules/Browser.lua:72:  f:SetBackdropColor(unpack(SKIN.bg))
BankLedger/modules/Browser.lua:73:  f:SetBackdropBorderColor(unpack(SKIN.border))
BankLedger/modules/Browser.lua:82:  f.innerBorder:SetBackdropBorderColor(unpack(SKIN.innerBorder))
BankLedger/modules/Browser.lua:84:  if f.title then f.title:SetTextColor(unpack(SKIN.title)) end
BankLedger/modules/Browser.lua:85:  if f.divider then f.divider:SetColorTexture(unpack(SKIN.divider)) end
BankLedger/modules/Browser.lua:192:    frame.tabs[t].label:SetTextColor(unpack(active and SKIN.tabActive or SKIN.tabIdle))
BankLedger/modules/Browser.lua:211:  strip:SetHeight(SKIN.tabStripH)
BankLedger/modules/Browser.lua:218:    tab:SetSize(90, SKIN.tabStripH)
BankLedger/modules/Browser.lua:225:    underline:SetColorTexture(unpack(SKIN.tabActive))
BankLedger/modules/Browser.lua:1061:  local minW, minH = B:MinWidth(), SKIN.minH
BankLedger/modules/Browser.lua:1063:  frame:SetSize(minW, SKIN.defaultH)
BankLedger/modules/Browser.lua:1078:  titleBar:SetHeight(SKIN.titleBarH)
BankLedger/modules/Browser.lua:1113:  local barTop  = SKIN.titleBarH + SKIN.tabStripH + SKIN.contentGap
BankLedger/modules/SessionWindow.lua:456:  local skin = (NS.Browser and NS.Browser.SKIN) or { titleBarH = 30 }
ConsumableMaster/modules/DebugLog.lua:167:    -- `skin` is deliberately NOT passed: Core.SKIN is byte-identical to the

$ grep -rn 'ApplySkin' … 
BankLedger/core/DebugLogSetup.lua:112:    if NS.Browser and NS.Browser.ApplySkin then NS.Browser:ApplySkin(frame) end
BankLedger/modules/Export.lua:258:  if NS.Browser and NS.Browser.ApplySkin then NS.Browser:ApplySkin(copyFrame) end
BankLedger/modules/Export.lua:350:  if NS.Browser and NS.Browser.ApplySkin then NS.Browser:ApplySkin(frame) end
BankLedger/modules/Browser.lua:17:-- ApplySkin seam so a future settings-driven re-skin has a single touch point; the debug console
BankLedger/modules/Browser.lua:67:function B:ApplySkin(f)
BankLedger/modules/Browser.lua:1177:  B:ApplySkin(frame)
BankLedger/modules/SessionWindow.lua:536:  if NS.Browser and NS.Browser.ApplySkin then
BankLedger/modules/SessionWindow.lua:537:    NS.Browser:ApplySkin(frame)

$ grep -rn 'MakeCloseButton' …
AbsorbTracker/core/PerfSetup.lua:116:        if NS.DebugLog and NS.DebugLog.MakeCloseButton then
AbsorbTracker/core/PerfSetup.lua:121:            local close = NS.DebugLog.MakeCloseButton(frame, api.Hide)
AbsorbTracker/core/DebugLogSetup.lua:58:        MakeCloseButton = function() return nil end,
BankLedger/core/DebugLogSetup.lua:99:  -- Core.MakeCloseButton is an 18×18 fixed-red × where ours is 24×24 and takes the player's CLASS
BankLedger/core/DebugLogSetup.lua:116:    if NS.Browser and NS.Browser.MakeCloseButton then
BankLedger/core/DebugLogSetup.lua:117:      return NS.Browser:MakeCloseButton(parent, onClick)
BankLedger/modules/Browser.lua:90:function B:MakeCloseButton(parent, onClick)
BankLedger/modules/Browser.lua:1106:  local close = B:MakeCloseButton(titleBar, function() B:Hide() end)
BankLedger/modules/SessionWindow.lua:482:  if NS.Browser and NS.Browser.MakeCloseButton then
BankLedger/modules/SessionWindow.lua:483:    local close = NS.Browser:MakeCloseButton(titleBar, function() SW:Hide() end)
BankLedger/modules/Export.lua:242:  if NS.Browser and NS.Browser.MakeCloseButton then
BankLedger/modules/Export.lua:243:    NS.Browser:MakeCloseButton(tbar, function() copyFrame:Hide() end)
BankLedger/modules/Export.lua:326:  if NS.Browser and NS.Browser.MakeCloseButton then
BankLedger/modules/Export.lua:327:    NS.Browser:MakeCloseButton(tbar, function() frame:Hide() end)
KickCD/core/DebugLogSetup.lua:91:        MakeCloseButton = function() return nil end,
KickCD/core/PerfSetup.lua:13:--   * core/DebugLogSetup.lua has run, so the log sink and MakeCloseButton exist;
KickCD/core/PerfSetup.lua:209:        if not (NS.DebugLog and NS.DebugLog.MakeCloseButton) then return end
KickCD/core/PerfSetup.lua:210:        local close = NS.DebugLog.MakeCloseButton(frame, api.Hide)

$ grep -rn 'SECRET' …
ConsumableMaster/core/Compat.lua:53:-- True when the client handed us a SECRET value.
ConsumableMaster/core/MacroDisplay.lua:84:-- startTime, duration and modRate come back as SECRET numbers. Tainted code may

$ grep -rn 'FormatRow' …
AbsorbTracker/settings/Slash.lua:33:    print("  " .. SlashLib.FormatRow(cmd, desc))
AbsorbTracker/settings/Slash.lua:384:    SlashLib = { FormatRow = function(cmd, desc) return cmd .. " \226\128\148 " .. desc end }
AbsorbTracker/settings/Slash.lua:397:                out[#out + 1] = SlashLib.FormatRow("/at " .. e[1], e[2])

$ grep -rn 'FormatKV' …
(no output)

$ grep -rn 'FormatValue' …
AbsorbTracker/settings/Schema.lua:190:    if SlashLib then return SlashLib.FormatValue(row, v) end
BankLedger/settings/Slash.lua:158:-- stores, and lib.FormatValue ends at Core's SafeToString — which probes table.concat, refuses a
BankLedger/settings/Slash.lua:201:    return lib.FormatValue(row, v)
ConsumableMaster/core/SlashCommands.lua:1259:-- fixed both blockers upstream: lib.FormatValue reads this addon's positional
KickCD/settings/Slash.lua:48:-- both majors, and `lib.FormatValue` reads the positional shape directly — the

$ grep -rn 'ParseValue' …
AbsorbTracker/settings/Schema.lua:263:-- The type-aware value parser moved to LibKa0s-Slash-1.0 (`lib.ParseValue`): clamping, the
BankLedger/settings/Slash.lua:211:    return lib.ParseValue(row, text)
KickCD/settings/Slash.lua:142:    local v, err = SlashLib.ParseValue(row, text)
KickCD/settings/Slash.lua:214:    SlashLib.ParseValue = function() return nil, "the LibKa0s library is missing" end

$ grep -rn 'FormatPlain' …
ConsumableMaster/modules/DebugLog.lua:203:DL.FormatPlain, DL.FormatColored = lib.FormatPlain, lib.FormatColored
KickCD/core/DebugLogSetup.lua:61:    -- one duplicate testing-§8 most specifically forbids. FormatPlain and
KickCD/core/DebugLogSetup.lua:94:        FormatPlain     = function(ts, tag, msg)
KickCD/core/DebugLogSetup.lua:114:    D.FormatColored = D.FormatPlain

$ grep -rn 'LastLine' …
AbsorbTracker/core/DebugLogSetup.lua:56:        LastLine        = function() return nil end,
KickCD/core/DebugLogSetup.lua:89:        LastLine        = function() return nil end,

$ grep -rn 'MAX_BUFFER' …
(no output)
$ grep -rn 'EncodeJSON' …
(no output)
$ grep -rn 'DEFAULT_RING' …
(no output)
$ grep -rn 'HelpHeader' …
(no output)

$ grep -rn 'HelpRows' …
KickCD/core/KickCD.lua:243:    -- library's HelpRows form; the settings landing page renders the SAME rows
KickCD/settings/Slash.lua:232:        stub.HelpRows = function()
KickCD/settings/Slash.lua:239:            for _, r in ipairs(stub.HelpRows()) do out(r) end

$ grep -rn 'PrintHelp' …
AbsorbTracker/settings/Slash.lua:112:function printHelp() cli:PrintHelp() end
AbsorbTracker/settings/Slash.lua:401:        stub.PrintHelp = function()
AbsorbTracker/settings/Slash.lua:407:            if raw == "" then return stub.PrintHelp() end
AbsorbTracker/settings/Slash.lua:415:            stub.PrintHelp()
BankLedger/settings/Slash.lua:118:  function Sl:PrintHelp() print(UNAVAILABLE) end
BankLedger/settings/Slash.lua:145:    if raw == "" then return Sl:PrintHelp() end
BankLedger/settings/Slash.lua:152:    Sl:PrintHelp()
BankLedger/settings/Slash.lua:216:function Sl:PrintHelp() return cli:PrintHelp() end
BankLedger/settings/Schema.lua:285:  { "help",     "Show this help",          function() NS.Slash:PrintHelp() end },
ConsumableMaster/core/SlashCommands.lua:1352:    printHelp = function() Sl:PrintHelp() end
KickCD/core/KickCD.lua:245:    if NS.Slash and NS.Slash.cli then return NS.Slash.cli:PrintHelp() end
KickCD/settings/Slash.lua:237:        stub.PrintHelp = function()
KickCD/settings/Slash.lua:243:            if raw == "" then return stub.PrintHelp() end
KickCD/settings/Slash.lua:251:            stub.PrintHelp()
KickCD/settings/Slash.lua:347:function NS.Slash:PrintHelp() return NS.Slash.cli:PrintHelp() end

$ grep -rn 'BuildListLines' …
BankLedger/settings/Slash.lua:119:  function Sl:BuildListLines() return { UNAVAILABLE } end
BankLedger/settings/Slash.lua:217:function Sl:BuildListLines() return cli:BuildListLines() end

$ grep -rn 'CliVersion' …
BankLedger/settings/Slash.lua:124:  function Sl:CliVersion() print("v" .. tostring(Sl:Version())) end
BankLedger/settings/Slash.lua:222:function Sl:CliVersion() return cli:CliVersion() end
BankLedger/settings/Schema.lua:233:  { "version",  "Print addon version",     function() NS.Slash:CliVersion() end },
KickCD/settings/Slash.lua:224:        stub.CliVersion = function() out("v" .. tostring(d.version and d.version() or "?")) end

$ grep -rn 'CliResetAll' …
BankLedger/modules/Filters.lua:114:-- reset paths (Slash:CliResetAll, the Filters page's Defaults button).
BankLedger/modules/Browser.lua:856:-- programmatic callers (Slash:CliResetAll prints its own single confirmation); the bar's Reset
BankLedger/settings/Panel.lua:489:  if NS.Slash and NS.Slash.CliResetAll then NS.Slash:CliResetAll() end
BankLedger/settings/Panel.lua:490:  -- CliResetAll already batches its own row walk; this call is what repaints after the two window
BankLedger/settings/Schema.lua:238:  { "resetall", "Reset all settings",      function() NS.Slash:CliResetAll() end },
BankLedger/settings/Slash.lua:71:-- to its stock shape. CliResetAll covers the schema settings and the filter lists; this adds the
BankLedger/settings/Slash.lua:75:  Sl:CliResetAll()   -- resets settings + filter lists and prints the confirmation line
BankLedger/settings/Slash.lua:130:  function Sl:CliResetAll()
BankLedger/settings/Slash.lua:230:-- Reset every user setting to its default. The library's CliResetAll walks the schema rows and
BankLedger/settings/Slash.lua:239:function Sl:CliResetAll()
BankLedger/settings/Slash.lua:242:  -- Batched: the library's CliResetAll walks every schema row and each one goes through the write
BankLedger/settings/Slash.lua:246:    return NS.Panel:Batch(function() cli:CliResetAll() end)
BankLedger/settings/Slash.lua:248:  return cli:CliResetAll()
ConsumableMaster/core/SlashCommands.lua:1356:    -- Sl:CliReset only, never Sl:CliResetAll: the library's resetall walks the

$ grep -rn 'SetRowAnnotator' …
AbsorbTracker/settings/Slash.lua:387:        local stub = { SetRowAnnotator = function() end }
AbsorbTracker/settings/Slash.lua:457:cli:SetRowAnnotator(MirrorNote)
KickCD/settings/Slash.lua:217:        local stub = { SetRowAnnotator = function() end }

$ grep -rn 'SetRenderer' …
BankLedger/settings/OptionsSetup.lua:145:    SetRenderer = function() end,
BankLedger/settings/Panel.lua:537:    O.SetRenderer(ctx, function(c)
BankLedger/settings/Panel.lua:591:    O.SetRenderer(ctx, function(c)
ConsumableMaster/settings/Category.lua:622:        H.SetRenderer(ctx, function(c)
ConsumableMaster/settings/StatPriority.lua:298:    H.SetRenderer(ctx, render)
ConsumableMaster/settings/General.lua:163:    H.SetRenderer(ctx, render)
ConsumableMaster/settings/Panel.lua:333:-- A panel module calls SetRenderer(ctx, fn) to declare how to render its
ConsumableMaster/settings/Panel.lua:349:Helpers.SetRenderer = UI and UI.SetRenderer
ConsumableMaster/settings/Panel.lua:548:-- Helpers.SetRenderer; Refresh re-runs every renderer that has been shown
ConsumableMaster/settings/Panel.lua:770:    Helpers.SetRenderer(mainCtx, Helpers.BuildAboutContent)
ConsumableMaster/settings/MacroBar.lua:502:    H.SetRenderer(ctx, render)

$ grep -rn 'RefreshScalars' …
BankLedger/settings/OptionsSetup.lua:149:    RefreshScalars = function() end,
BankLedger/settings/Panel.lua:283:  -- registry now owns that distinction: a scalar write runs refreshers (RefreshScalars), a
BankLedger/settings/Panel.lua:471:  if O.RefreshScalars then O.RefreshScalars() end
ConsumableMaster/settings/Panel.lua:521:-- refreshers so a scalar refresh (RefreshScalars) re-syncs it in place.
ConsumableMaster/settings/Panel.lua:556:-- appeared or disappeared are drawn. RefreshScalars is IN PLACE: it re-syncs
ConsumableMaster/settings/Panel.lua:570:Helpers.RefreshScalars   = UI and UI.RefreshScalars
ConsumableMaster/settings/Panel.lua:618:    Helpers.RefreshScalars()

$ grep -rn 'RenderGrid' …
AbsorbTracker/settings/OptionsSetup.lua:161:        "AddSpacer", "AttachTooltip", "InlineButtonPair", "RenderField", "RenderGrid", "RenderRows",
AbsorbTracker/settings/UnitPanel.lua:9:-- model. Everything they stand on — ClearScroll, EnsureScroll, RenderGrid, RenderRows,
AbsorbTracker/settings/UnitPanel.lua:73:    -- OptionsWidgets minor 4 shipped RenderGrid to end. RenderGrid's HALF is the same 0.5 the copy
AbsorbTracker/settings/UnitPanel.lua:143:    Helpers.RenderGrid(ctx, items)
BankLedger/settings/OptionsSetup.lua:144:    RenderGrid = function() end,
ConsumableMaster/settings/Panel.lua:510:-- This addon had its own copy until LibKa0s-Options-1.0 grew RenderGrid. Its
ConsumableMaster/settings/Panel.lua:515:-- it a library gap rather than something to work around here. RenderGrid also
ConsumableMaster/settings/Panel.lua:517:Helpers.Grid = UI and UI.RenderGrid

$ grep -rn 'PatchAlwaysShowScrollbar' …
AbsorbTracker/settings/OptionsSetup.lua:163:        "PatchAlwaysShowScrollbar",
ConsumableMaster/settings/Panel.lua:241:    Helpers.PatchAlwaysShowScrollbar = UI.PatchAlwaysShowScrollbar
KickCD/settings/OptionsSetup.lua:203:        "PatchAlwaysShowScrollbar",
KickCD/settings/Panel.lua:383:    -- Helpers.PatchAlwaysShowScrollbar.
KickCD/settings/Panel.lua:384:    Helpers.PatchAlwaysShowScrollbar(scroll)
KickCD/settings/Panel.lua:620:-- (CreatePanel, EnsureDefaultsButton, PatchAlwaysShowScrollbar and Section are
KickCD/settings/Spells.lua:902:    if PanelHelpers and PanelHelpers.PatchAlwaysShowScrollbar then
KickCD/settings/Spells.lua:903:        PanelHelpers.PatchAlwaysShowScrollbar(container)

$ grep -rn 'InlineButtonPair' …
AbsorbTracker/settings/General.lua:168:                H.InlineButtonPair(ctxRef,
AbsorbTracker/settings/OptionsSetup.lua:161:        "AddSpacer", "AttachTooltip", "InlineButtonPair", "RenderField", "RenderGrid", "RenderRows",
BankLedger/settings/OptionsSetup.lua:146:    InlineButtonPair = function() end,
KickCD/settings/General.lua:24:-- followed by an InlineButtonPair afterGroup row:
KickCD/settings/General.lua:163:                H.InlineButtonPair(ctxRef,
KickCD/settings/Panel_Widgets.lua:8:-- InlineButtonPair. They were ~300 lines and one of several near-identical
KickCD/settings/OptionsSetup.lua:201:        "AddSpacer", "AttachTooltip", "InlineButtonPair", "RenderField", "RenderRows",

$ grep -rn 'SessionCheckbox' …
AbsorbTracker/settings/OptionsSetup.lua:162:        "RenderSchema", "SessionCheckbox", "RefreshAllPanels", "RestoreDefaults",
AbsorbTracker/settings/General.lua:189:                    H.SessionCheckbox(ctxRef, rowGroup, 0.5, NS.DebugLog:ConsoleCheckbox())
BankLedger/settings/OptionsSetup.lua:147:    SessionCheckbox = function() return nil end,
ConsumableMaster/settings/Panel.lua:522:-- The library spells it SessionCheckbox — a checkbox backed by a get/set pair
ConsumableMaster/settings/Panel.lua:525:Helpers.CustomCheckbox = UI and UI.SessionCheckbox
KickCD/settings/Panel_Widgets.lua:22:--     library has this as SessionCheckbox, but with the argument order
KickCD/settings/Panel_Widgets.lua:56:--- A pure argument-order adapter over the library's SessionCheckbox. This
KickCD/settings/Panel_Widgets.lua:64:    return Helpers.SessionCheckbox(ctx, parent, relativeWidth or 0.5, spec)
KickCD/settings/OptionsSetup.lua:202:        "RenderSchema", "SessionCheckbox", "RefreshAllPanels", "RestoreDefaults",

$ grep -rn 'ConsoleCheckbox' …
AbsorbTracker/core/DebugLogSetup.lua:59:        ConsoleCheckbox = function()
AbsorbTracker/settings/General.lua:38:-- pair off as 2 + 2 + 1. Its get/set lives in NS.DebugLog:ConsoleCheckbox().
AbsorbTracker/settings/General.lua:188:                if NS.DebugLog and NS.DebugLog.ConsoleCheckbox then
AbsorbTracker/settings/General.lua:189:                    H.SessionCheckbox(ctxRef, rowGroup, 0.5, NS.DebugLog:ConsoleCheckbox())
ConsumableMaster/settings/General.lua:110:    -- The spec is the library's: D:ConsoleCheckbox() returns the
ConsumableMaster/settings/General.lua:124:            local spec = DL and DL.instance and DL.instance:ConsoleCheckbox()
KickCD/core/DebugLogSetup.lua:105:        ConsoleCheckbox = function()

$ grep -rn 'RestoreAllDefaults' …
AbsorbTracker/settings/OptionsSetup.lua:123:-- RestoreAllDefaults is kept even though it measured as call-time, because the call it answers is
AbsorbTracker/settings/OptionsSetup.lua:149:    Helpers.RestoreAllDefaults = function()
AbsorbTracker/settings/Schema.lua:56:--- unit's rows — which is what RestoreDefaults / RestoreAllDefaults / `/at list` want.
AbsorbTracker/settings/Slash.lua:169:    if NS.Helpers and NS.Helpers.RestoreAllDefaults then
AbsorbTracker/settings/Slash.lua:170:        NS.Helpers.RestoreAllDefaults()
AbsorbTracker/settings/General.lua:123:-- before wiping. The OnAccept body calls NS.Helpers.RestoreAllDefaults,
AbsorbTracker/settings/General.lua:134:        if NS.Helpers and NS.Helpers.RestoreAllDefaults then
AbsorbTracker/settings/General.lua:135:            NS.Helpers.RestoreAllDefaults()
BankLedger/settings/OptionsSetup.lua:88:  -- No `afterRestoreAll` and no use of the library's RestoreAllDefaults — see settings/Panel.lua's
BankLedger/settings/OptionsSetup.lua:151:    RestoreAllDefaults = function() end,
KickCD/settings/Panel_Render.lua:203:-- screen position. Anchors aren't schema rows, so RestoreAllDefaults skips
KickCD/settings/Panel_Render.lua:232:-- in RenderUnitPanel — so RestoreAllDefaults can't reach it. Without this, an
KickCD/settings/Panel_Render.lua:260:    Helpers.RestoreAllDefaults()
KickCD/settings/Panel_Render.lua:270:-- RestoreAllDefaults are LibKa0s-Options-1.0's now: the two-column flow engine,
KickCD/settings/Panel.lua:131:-- used by RestoreDefaults/RestoreAllDefaults, which reset every unit's
KickCD/settings/OptionsSetup.lua:90:    -- hook is how the library's own RestoreAllDefaults gets there too. It runs
KickCD/settings/OptionsSetup.lua:187:    Helpers.RestoreAllDefaults = function()

$ grep -rn 'RegisterOptionsPage' …
AbsorbTracker/settings/Font.lua:106:if NS.RegisterOptionsPage then
AbsorbTracker/settings/Font.lua:107:    NS.RegisterOptionsPage("font", "Font", build)
AbsorbTracker/settings/Border.lua:102:if NS.RegisterOptionsPage then
AbsorbTracker/settings/Border.lua:103:    NS.RegisterOptionsPage("border", "Border", build)
AbsorbTracker/settings/Profiles.lua:68:if NS.RegisterOptionsPage then
AbsorbTracker/settings/Profiles.lua:69:    NS.RegisterOptionsPage("profiles", "Profiles", build)
AbsorbTracker/settings/Bar.lua:181:if NS.RegisterOptionsPage then
AbsorbTracker/settings/Bar.lua:182:    NS.RegisterOptionsPage("bar", "Bar", build)
AbsorbTracker/settings/OptionsSetup.lua:173:    NS.RegisterOptionsPage = function() end
AbsorbTracker/settings/OptionsSetup.lua:193:NS.RegisterOptionsPage = function(key, name, builder) Helpers.RegisterOptionsPage(key, name, builder) end
AbsorbTracker/settings/General.lua:199:if NS.RegisterOptionsPage then
AbsorbTracker/settings/General.lua:200:    NS.RegisterOptionsPage("general", "General", build)
BankLedger/settings/OptionsSetup.lua:128:    RegisterOptionsPage = function() end,
BankLedger/settings/Panel.lua:524:  O.RegisterOptionsPage("general", "General", function(mainCategory)
BankLedger/settings/Panel.lua:572:  O.RegisterOptionsPage("filters", "Filters", function(mainCategory)
KickCD/settings/OptionsSetup.lua:210:    NS.RegisterOptionsPage = function() end
KickCD/settings/OptionsSetup.lua:228:NS.RegisterOptionsPage = function(key, name, builder) Helpers.RegisterOptionsPage(key, name, builder) end

$ grep -rn '__pages' …
BankLedger/settings/OptionsSetup.lua:154:    __pages = function() return {} end,

$ grep -rn '__panels' …
AbsorbTracker/settings/OptionsSetup.lua:170:    Helpers.__panels   = function() return {} end
BankLedger/settings/OptionsSetup.lua:152:    __panels = function() return {} end,
BankLedger/settings/Panel.lua:459:function P.__pagesForTest() return O.__panels and O.__panels() or {} end
KickCD/settings/OptionsSetup.lua:207:    Helpers.__panels   = function() return {} end

$ grep -rn '__panelFor' …
AbsorbTracker/settings/OptionsSetup.lua:171:    Helpers.__panelFor = function() return nil end
BankLedger/settings/OptionsSetup.lua:153:    __panelFor = function() return nil end,
ConsumableMaster/settings/Panel.lua:303:        -- The library's own key for the same thing, so UI.__panelFor can find
KickCD/settings/OptionsSetup.lua:208:    Helpers.__panelFor = function() return nil end

$ grep -rn 'LSMValues' …
AbsorbTracker/settings/Font.lua:45:            values = NS.Helpers.LSMValues("font"),
AbsorbTracker/settings/Border.lua:31:            values = NS.Helpers.LSMValues("border"),
AbsorbTracker/settings/Bar.lua:60:            values = NS.Helpers.LSMValues("statusbar"),
AbsorbTracker/settings/Bar.lua:98:            values = NS.Helpers.LSMValues("statusbar"),
AbsorbTracker/settings/OptionsSetup.lua:18:-- files call NS.Helpers.LSMValues at file load. See the stub below for what that costs.
AbsorbTracker/settings/OptionsSetup.lua:110:-- settings/Bar.lua evaluates `NS.Helpers.LSMValues("statusbar")` inside a schema-row literal, at
AbsorbTracker/settings/OptionsSetup.lua:111:-- FILE LOAD. Border.lua and Font.lua do the same. With LSMValues nil that is `attempt to call field
AbsorbTracker/settings/OptionsSetup.lua:112:-- 'LSMValues' (a nil value)`, so settings/Bar.lua never finishes loading, so NS.RegisterSchemaRows
AbsorbTracker/settings/OptionsSetup.lua:119:-- whether #NS.Schema still matches the fully-loaded environment: LSMValues is the ONLY load-time
AbsorbTracker/settings/OptionsSetup.lua:120:-- member. Dropping it gives `settings/Bar.lua:60: attempt to call field 'LSMValues' (a nil value)`
AbsorbTracker/settings/OptionsSetup.lua:147:    Helpers.LSMValues = function() return function() return {} end end
ConsumableMaster/settings/Panel.lua:426:-- Helpers.EnumValues and Helpers.LSMValues stay here: they are the addon's own
ConsumableMaster/settings/Panel.lua:435:function Helpers.LSMValues(mediaType)
ConsumableMaster/settings/Panel.lua:446:    local hash = UI and UI.LSMValues(mediaType)() or {}
ConsumableMaster/settings/MacroBar.lua:135:    values = function() return H.LSMValues("border") end,
ConsumableMaster/settings/MacroBar.lua:166:    values = function() return H.LSMValues("border") end,
KickCD/settings/Castbar.lua:280:    values  = function() return H.LSMValues("font") end,
KickCD/settings/Castbar.lua:401:    values  = function() return H.LSMValues("statusbar") end,
KickCD/settings/Castbar.lua:438:    values  = function() return H.LSMValues("border") end,
KickCD/settings/Castbar.lua:463:    values  = function() return H.LSMValues("statusbar") end,
KickCD/settings/Castbar.lua:500:    values  = function() return H.LSMValues("border") end,
KickCD/settings/Label.lua:147:         values = function() return H.LSMValues("font") end }
KickCD/settings/Icons.lua:196:    values  = function() return H.LSMValues("border") end,
KickCD/settings/Icons.lua:220:    values  = function() return H.LSMValues("font") end,
KickCD/settings/OptionsSetup.lua:21:-- Helpers.LSMValues and Helpers.AnchorValues inside schema-row literals AT FILE
KickCD/settings/OptionsSetup.lua:144:-- settings/Icons.lua and settings/Castbar.lua evaluate `H.LSMValues("border")`
KickCD/settings/OptionsSetup.lua:153:-- consumer. AbsorbTracker takes LSMValues from the LIBRARY, so its stub must
KickCD/settings/OptionsSetup.lua:154:-- publish one or its page files raise. KickCD keeps LSMValues, AnchorValues and
KickCD/settings/Panel.lua:281:function Helpers.LSMValues(mediaType)
```

### §11.2 Uptake of the four v1.2.0 additions

cwd=GIT

```
$ grep -rnE 'applySkin|makeCloseButton' AbsorbTracker BankLedger ConsumableMaster KickCD --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
BankLedger/core/DebugLogSetup.lua:111:  applySkin = function(frame)
BankLedger/core/DebugLogSetup.lua:115:  makeCloseButton = function(parent, onClick)

$ grep -rn 'titleBarOffsets' AbsorbTracker BankLedger ConsumableMaster KickCD --include='*.lua' | grep -v '/libs/'
BankLedger/tests/test_libka0s.lua:415:  local off = D._frameForTest.titleBarOffsets

$ grep -rnE '^\s*format\s*=' AbsorbTracker BankLedger ConsumableMaster KickCD --include='*.lua' | grep -v '/libs/' | grep -v '/tests/'
BankLedger/settings/Slash.lua:198:  format = function(row, v)
```

The `format` hook and the reason it exists, `BankLedger/settings/Slash.lua:155-215`:

```
-- Render a stored value the library has no type for. `settings.excludedStores` is a SET of muted
-- stores, and lib.FormatValue ends at Core's SafeToString — which probes table.concat, refuses a
-- table, and answers "<secret>". A user being told a plain settings value is combat-protected is
-- worse than an ugly one, so this is the reason LibKa0s grew a `format` hook at Slash minor 5.
-- Byte-identical to what the deleted Sl.FormatSchemaValue rendered.
local function formatValue(row, v)
  if row and row.type == "table" then
    if type(v) ~= "table" then return tostring(v) end
    local keys = {}
    for k, on in pairs(v) do if on then keys[#keys + 1] = tostring(k) end end
    table.sort(keys)
    if #keys == 0 then return "(none)" end
    return "{" .. table.concat(keys, ", ") .. "}"
  end
  return nil   -- nil means "not mine" — the caller falls through to the library's own renderer
end
```

The numeric-enum dispatch, `LibKa0s/LibKa0s/OptionsWidgets.lua:464-482`:

```
  function O.RenderField(ctx, row, parent, relativeWidth)
    if row.type == "bool"   then return makeCheckbox(ctx, row, parent, relativeWidth)    end
    if row.type == "number" then
      -- A number carrying a `values` list is an ENUM, not a range, and Slash.lua has said so
      -- since -1.0: its parseNumber refuses a value outside the list rather than clamping, and
      -- its comment calls the shape "a NUMERIC dropdown" and warns that clamping "lands BETWEEN
      -- two entries, and the renderer then has no label for what is stored". That renderer did
      -- not exist — this line is it. Until now the two majors read one row as two different
      -- things, and a host with such a row got a CLI that validated an enum and a panel that drew
      -- a slider over it.
      --
      -- INFERRED from `values`, not opted into with a `dialogControl`, because Slash infers too
      -- and an opt-in would leave the two disagreeing for every row that declares `values` and
      -- nothing else. The enumList duplication comment above states the requirement outright: the
      -- two readers MUST agree. Safe in the failure direction — a values function that answers
      -- empty falls through to the slider, which is exactly the old behaviour.
      if #enumList(row) > 0 then return makeDropdown(ctx, row, parent, relativeWidth) end
      return makeSlider(ctx, row, parent, relativeWidth)
    end
```

and the only rows in the collection that trigger it:

```
$ for a in AbsorbTracker BankLedger ConsumableMaster KickCD; do echo "--- $a"; grep -rn -A4 'type *= *"number"' $a --include='*.lua' | grep -v '/libs/' | grep -v '/tests/' | grep -E 'values'; done
--- AbsorbTracker
--- BankLedger
BankLedger/settings/Schema.lua-77-    group = "Capture", label = "Minimum quality", values = C.QUALITY_OPTIONS,
BankLedger/settings/Schema.lua-84-    group = "Capture", label = "Keep history for", values = C.RETENTION_OPTIONS,
--- ConsumableMaster
--- KickCD

$ sed -n '74,89p' BankLedger/settings/Schema.lua
  -- What gets recorded: the two scope dropdowns first, then the kind toggles, then the per-store
  -- grid — narrowest-to-widest, as the sibling addons order their collection section.
  { path = "settings.qualityThreshold", default = 0, type = "number", widget = "Dropdown",
    group = "Capture", label = "Minimum quality", values = C.QUALITY_OPTIONS,
    tooltip = "Only record items at or above this quality. Whitelisted items ignore this.",
    onChange = function()
      if NS.bus then NS.bus:SendMessage("Ka0s_BankLedger_SettingsChanged", "quality") end
    end },

  { path = "settings.retentionDays", default = 30, type = "number", widget = "Dropdown",
    group = "Capture", label = "Keep history for", values = C.RETENTION_OPTIONS,
    tooltip = "Automatically drop movements older than this. 'Always' keeps everything.",
    onChange = function()
      if NS.bus then NS.bus:SendMessage("Ka0s_BankLedger_SettingsChanged", "quality") end
    end },
```

The canvas contract, `LibKa0s/LibKa0s/Options.lua:206-232`:

```
    panel:Hide()

    -- The Blizzard canvas contract. The Settings window calls all three on a frame handed to
    -- RegisterCanvasLayout(Sub)category: OnCommit when the user applies, OnDefault from the
    -- window's own FOOTER defaults control, OnRefresh on re-show. This library declared none of
    -- them until minor 5, so every host on it shipped a canvas whose footer Defaults control did
    -- nothing — and three did, without noticing, because the header Defaults button this library
    -- DOES build kept working and looks equivalent to the user.
    --
    -- OnCommit and OnRefresh are inert BY DESIGN rather than by omission. A host's writes land
    -- immediately through its own single write seam (options-ui-§41), so there is no staged state
    -- to apply; and SetRenderer already owns re-show, so a second refresh path would race the
    -- renderer it duplicates.
    panel.OnCommit  = function() end
    panel.OnRefresh = function() end

    -- A FORWARDER, not `panel.OnDefault = panel.defaultsOnClick`, and the ordering is the whole
    -- reason: every host parks its click handler on the panel AFTER this function returns, because
    -- the Defaults button does not exist yet (EnsureDefaultsButton builds it on first OnShow). An
    -- assignment here would capture nil forever while looking perfectly correct.
    --
    -- Resolving through the panel at call time also keeps the footer control and the header button
    -- ONE implementation — which is what matters — rather than two that can drift. A page with no
    -- defaults action (a landing page) gets a callable no-op, which is the point: the footer
    -- control is not per-page and can be clicked while such a page is open.
    panel.OnDefault = function()
      if panel.defaultsOnClick then panel.defaultsOnClick() end
```

Who parks a handler, and who asserts the forwarder:

```
$ grep -rn 'defaultsOnClick\|OnDefault\|OnCommit\|OnRefresh' AbsorbTracker BankLedger ConsumableMaster KickCD --include='*.lua' | grep -v '/libs/'
AbsorbTracker/settings/Border.lua:89:    ctx.panel.defaultsOnClick = function()
AbsorbTracker/settings/Font.lua:93:    ctx.panel.defaultsOnClick = function()
AbsorbTracker/settings/Bar.lua:168:    ctx.panel.defaultsOnClick = function()
AbsorbTracker/settings/General.lua:154:    ctx.panel.defaultsOnClick = function()
AbsorbTracker/tests/test_helpers.lua:65:  ctx.panel.defaultsOnClick = function() clicked = clicked + 1 end
BankLedger/settings/Panel.lua:47:-- Only `defaultsOnClick` is set. The library's CreatePanel stamps an `OnDefault` that FORWARDS here
BankLedger/settings/Panel.lua:49:-- remember to set both. Setting OnDefault as well would replace that forwarder with a copy — the
BankLedger/settings/Panel.lua:52:  panel.defaultsOnClick = fn
BankLedger/tests/test_panel.lua:28:-- Blizzard's Settings window calls all three on the registered canvas — OnCommit on apply, OnDefault
BankLedger/tests/test_panel.lua:29:-- from its own footer defaults control, OnRefresh on re-show. LibKa0s sets none of them, so this
BankLedger/tests/test_panel.lua:32:-- RAWGET, not `type(p.OnCommit)`, and that is the whole point of this case. The mock's frame stub
BankLedger/tests/test_panel.lua:33:-- synthesises a no-op function for ANY PascalCase key, so `type(p.OnCommit) == "function"` is true
BankLedger/tests/test_panel.lua:37:test("Panel: each canvas frame defines OnCommit, OnDefault and OnRefresh", function()
BankLedger/tests/test_panel.lua:40:    assertEqual(type(rawget(p, "OnCommit")),  "function", name .. " OnCommit")
BankLedger/tests/test_panel.lua:41:    assertEqual(type(rawget(p, "OnDefault")), "function", name .. " OnDefault")
BankLedger/tests/test_panel.lua:42:    assertEqual(type(rawget(p, "OnRefresh")), "function", name .. " OnRefresh")
BankLedger/tests/test_panel.lua:46:test("Panel: the landing page's OnDefault is inert — it manages no settings", function()
BankLedger/tests/test_panel.lua:48:  assertTrue(rawget(p, "defaultsOnClick") == nil, "no defaults action parked on the landing page")
BankLedger/tests/test_panel.lua:49:  rawget(p, "OnDefault")()   -- must not raise
BankLedger/tests/test_panel.lua:56:-- while the host set both from a single closure. LibKa0s-Options-1.0 minor 5 stamps an `OnDefault`
BankLedger/tests/test_panel.lua:57:-- that FORWARDS to whatever the page parked as `defaultsOnClick` — so they are deliberately no
BankLedger/tests/test_panel.lua:60:test("Panel: OnDefault runs the same action as the header Defaults button", function()
BankLedger/tests/test_panel.lua:63:    local parked = rawget(p, "defaultsOnClick")
BankLedger/tests/test_panel.lua:66:    p.defaultsOnClick = function() ran = ran + 1 end
BankLedger/tests/test_panel.lua:67:    rawget(p, "OnDefault")()
BankLedger/tests/test_panel.lua:68:    p.defaultsOnClick = parked
BankLedger/tests/test_panel.lua:83:  local ok, err = pcall(function() panel("General").OnDefault() end)
BankLedger/tests/test_panel.lua:91:test("Panel: OnCommit and OnRefresh are inert — writes land immediately and OnShow refreshes", function()
BankLedger/tests/test_panel.lua:94:    p.OnCommit()
BankLedger/tests/test_panel.lua:95:    p.OnRefresh()
BankLedger/tests/wow_mock.lua:369:  -- registered under. options-ui-§1 makes the frame's OnCommit/OnDefault/OnRefresh a contract with
ConsumableMaster/settings/Panel.lua:317:        ctx.panel.defaultsOnClick = function()
KickCD/settings/Castbar.lua:537:    ctx.panel.defaultsOnClick = function()
KickCD/settings/Icons.lua:393:    ctx.panel.defaultsOnClick = function()
KickCD/settings/General.lua:129:    ctx.panel.defaultsOnClick = function()
KickCD/settings/Label.lua:178:    ctx.panel.defaultsOnClick = function()
KickCD/settings/Spells.lua:941:    panel.defaultsOnClick = function()
```

All four consumers park `defaultsOnClick` and therefore depend on the forwarder; only BankLedger
asserts it, and only via `rawget`, because the frame mock synthesises a no-op for any PascalCase key.

### §11.3 Is `docs/adoption-prompt.md` stale?

cwd=GIT — the prompt's own words:

```
$ sed -n '1,10p' LibKa0s/docs/adoption-prompt.md
# Adoption prompt — drop this into any Ka0s addon repo

Copy everything below the line into a fresh Claude Code session **in the addon's own repo**. It is
self-contained: it names what to read rather than restating rules that may have moved on.

Adopted: **AbsorbTracker** (consumer #1), **KickCD**, **ConsumableMaster** — all five modules each.

Remaining targets: `BankLedger`, `LootHistory`, `PanelMaster`, `prettychat`, `WhatGroup`.
`WhoGotLoots` and `BuffTextNotifications` are out of scope until they are on the standard at all.

$ sed -n '296,306p' LibKa0s/docs/adoption-prompt.md
| Addon | Order | Why |
|---|---|---|
| KickCD | Core → DebugLog → Slash → Options → Perf | Core alone and first, then re-run `/kcd debug spells`, `/kcd debug interrupt` and `/kcd list` in combat before proceeding. … |
| ~~ConsumableMaster~~ | **done** — Core → DebugLog → Slash → Options → Perf | Adopted in full. … Convergence #2 does not apply to it at all — no landing page; see the note under that convergence. |
| prettychat | Core → DebugLog → Options (shell only) → Slash (partial) → Perf | Slash last and partial: only the dispatcher, help renderer and landing rows. … |
| WhatGroup | Core → DebugLog → Options → Slash → Perf | Options early because it is the biggest clean win, gated on the deferred-OnShow check. … |
| PanelMaster | Core → DebugLog → Slash → Options → Perf | Slash before Options: the `COMMANDS` flip and the `"boolean"`→`"bool"` rename are prerequisites … |
| BankLedger | Core (printer only) → DebugLog → Slash → Options → Perf | DebugLog immediately after Core: highest value, lowest risk, and it validates the seam. |
| LootHistory | Core (printer only) → DebugLog → Slash → Options → Perf | Same, but write panel tests **before** Options — there are none today. |

$ sed -n '536,540p' LibKa0s/docs/adoption-prompt.md
   proves your "additive" change was additive. At the time of writing: **AbsorbTracker 462**,
   **KickCD 643**, **ConsumableMaster 554**, each 0 failed. If any of those moves *while you are
   changing the library*, your change was not additive and you need to know before it ships rather
   than after.
```

cwd=LIB — the full BankLedger mention list:

```
$ grep -n 'BankLedger' docs/adoption-prompt.md
8:Remaining targets: `BankLedger`, `LootHistory`, `PanelMaster`, `prettychat`, `WhatGroup`.
268:**BankLedger** and **LootHistory** — architectural twins; treat them as one job done twice. ...
303:| BankLedger | Core (printer only) → DebugLog → Slash → Options → Perf | ...
431:   and adds one to the description. BankLedger, LootHistory and PanelMaster all change here; ...
```

Against `docs/releasing.md`, which is correct on every point (cwd=GIT,
`LibKa0s/docs/releasing.md:1246-1250`):

```
Add each addon here as it adopts a module, so "every consumer" in step 7 is a list rather than a
memory. Remaining, per `docs/adoption-prompt.md`: LootHistory, PanelMaster, prettychat
and WhatGroup. BankLedger has Core, DebugLog, Slash and Options; it **declines Perf** (its capture engine never runs in combat, and the probe's windows are combat-gated, so every bucket would read 0.000 by construction — see its `docs/pending/LEDGER.md`, LIBKA0S-17).
`WhoGotLoots` and `BuffTextNotifications` are out of scope until they are on the standard at all.
```

And against the filesystem (§1, §4.4): BankLedger has `libs/LibKa0s/` at the current eight minors,
wires four majors, and carries a recorded structural Perf decline. `releasing.md` is right; the
prompt is stale in four places — lines 6, 8, 303 and 538 — and half-stale at 268 and 431. The three
suite figures the prompt quotes are themselves still accurate (§8.5); 684 is simply absent.

### §11.4 Continuity against `docs/adoption/2026-08-01/`

The prior run's own BankLedger statements, read verbatim (cwd=`LibKa0s/docs/adoption/2026-08-01`):

```
$ grep -rn -i 'bankledger' .
02_MATRIX.md:9:Not adopted, per `docs/adoption-prompt.md`: BankLedger, LootHistory, PanelMaster, prettychat,
03_DEVIATIONS.md:155:The prompt's convergence #2 section reads: *"BankLedger, LootHistory and PanelMaster all change
05_EVIDENCE.md:13:BankLedger       ... (no LibKa0s)
01_SUMMARY.md:142:- **The five unadopted targets** (BankLedger, LootHistory, PanelMaster, prettychat, WhatGroup)
```

The shared `LIBKA0S_MISSING` cause clause, which was the prior run's finding 8 (KickCD: 0 sites).
cwd=GIT:

```
$ for a in AbsorbTracker BankLedger ConsumableMaster KickCD; do echo "--- $a: $(grep -rn 'LIBKA0S_MISSING' $a --include='*.lua' | grep -v '/libs/' | grep -v '/tests/' | wc -l | tr -d ' ') sites"; done
--- AbsorbTracker: 6 sites
--- BankLedger: 6 sites
--- ConsumableMaster: 5 sites
--- KickCD: 10 sites
```

KickCD's own slice locates them: `core/CoreSetup.lua:61-62` defines the clause outside the branch,
and it is appended at `core/CoreSetup.lua:100`, `core/DebugLogSetup.lua:65`, `core/PerfSetup.lua:51`,
`settings/OptionsSetup.lua:173` and `settings/Slash.lua:212` (ledger LIBKA0S-05).

Per-consumer continuity tables, as each collector recorded them.

**AbsorbTracker** (cwd=AT):

| Prior finding | State now | Evidence |
|---|---|---|
| Grade **High**; minors current, content identical | holds | §2.2, §3.2 |
| Gate 449 passed / 0 failed, luacheck 0/0 | moved, cleanly | §8.1 — now 462/0, 0/0 |
| §"L trap": *"AbsorbTracker and ConsumableMaster have none at all"* | fixed | §7.2, ledger LIBKA0S-03 |
| §6: no README provenance line | fixed | §9.2 — `README.md:143`, naming v1.2.0 |
| §7: *"`RenderGrid` has exactly one consumer"* | fixed for this host | §11.1 — `settings/UnitPanel.lua:143` |
| §8: `NS.LIBKA0S_MISSING` shared cause clause, 6 sites | holds | §11.4 |
| Line-ending position (AbsorbTracker LF, ConsumableMaster the CRLF outlier) | changed, harmlessly | §3.2 |

**KickCD** (cwd=KCD):

| Prior finding | State now | Evidence here |
|---|---|---|
| `03_DEVIATIONS.md §1` — ship folder holds four LF files; KickCD holds LF copies, so the byte gate inverts | fixed | §3.3 |
| `01_SUMMARY.md` — luacheck 7 warnings / 0 errors against a documented 0/0 gate | fixed | §8.2 |
| `03_DEVIATIONS.md §2` — the guard exists in exactly one place | fixed | §7.2, §7.3; ledger LIBKA0S-02 |
| shared `LIBKA0S_MISSING` clause: KickCD 0 sites | fixed | §11.4 — 10 sites; ledger LIBKA0S-05 |
| `04_RECOMMENDATIONS.md §7` — `RenderGrid` has one consumer | persists, now deliberate and recorded | §5.3; ledger LIBKA0S-04 wont-do |
| `03_DEVIATIONS.md:75` — `L = NS.L and { … } or nil`, one key | persists, and is correct | §7.1 — now at `:335`; the matcher pins the `and` form as legal |

**ConsumableMaster** (cwd=CM):

| Prior finding | State now | Evidence |
|---|---|---|
| §2 — L-trap guard coverage incomplete | fixed | §7.3, 5/5 guarded, `LIBKA0S-10` |
| §3 — convergence #1 declined, unrecorded | fixed | §6.3, `LIBKA0S-12` + `CHANGELOG.md:14-30` |
| §4 — "prompt misstates CM's landing page; it is not applicable" | **the prior finding is itself wrong**, and the state it described is a live undocumented decline | §6.3 |
| §5/§6 — no licence, no provenance line | fixed | §9.2, `LIBKA0S-08` |
| line endings — CM was the correct side | still correct | §3.4 |

**BankLedger**: nothing to carry forward. The prior run's only BankLedger statement was "not
adopted", and that statement is now false; every BankLedger item in this bundle is new.

---

## §12 — What this run did NOT check

Named explicitly, because an unchecked area silently omitted reads as a clean one.

**In-game behaviour, everywhere.** Nothing in this run touches the WoW client. Specifically
unverified: the Blizzard footer Defaults control that Options minor 5 makes live in all four
consumers; DebugLog's derived title-bar offsets (for AbsorbTracker they should compute to the same
−30 / −78 as the hard-coded minor-3 values, but that was reasoned from the CHANGELOG, not
observed); BankLedger's console wearing its own chrome via `applySkin` and the 24-wide close
button's gap against Clear; BankLedger's two numeric rows drawing as dropdowns rather than sliders;
ConsumableMaster's About page rendering as its format string implies and `sliderCommit = "change"`
under a real 60 Hz drag; KickCD's converged landing-page spacing and white descriptions; and the
on-screen half of the `L` trap in every repo.

**`docs/smoke-tests.md` was not executed** in any repo. AbsorbTracker's and ConsumableMaster's were
confirmed to exist (ConsumableMaster's only grepped for the word "landing"); KickCD's was noted to
carry 12 LibKa0s/SCREAMING-case references; BankLedger's was not audited for whether the prompt's
step-10 steps are present at all.

**Mutation verification of any consumer's own assertions.** AbsorbTracker's ledger (LIBKA0S-03),
ConsumableMaster's (LIBKA0S-12), KickCD's (LIBKA0S-02) and BankLedger's all claim their cases were
verified red first. Those claims were read, not reproduced — re-running them would require editing
a repo, which this audit forbids.

**The degraded-install path exercised for real.** Every consumer has degraded-mode cases and they
pass, but no run renamed `libs/LibKa0s` aside and reloaded to confirm the seams degrade in concert
and the shared `NS.LIBKA0S_MISSING` clause is said exactly once.

**Lint scope.** Every consumer's `luacheck` figure excludes `libs/`, and BankLedger's and the
library's also exclude `tests/`. The library's 0/0 covers 11 files, not the repo: `.luacheckrc:4`
carries `exclude_files = { "tests/", "docs/" }`, so the 21 files under `tests/` — the suites, the
fixtures, `wow_mock.lua` and the vendored `tests/_kit/` copies — are never linted there.

**How the CRLF condition was fixed.** `git status` is clean and no commit in the last 25 is named
as a renormalisation, so §10.1 establishes current state, not cause.

**Whether `origin/master` holds the same seven post-v1.1.1 commits.** `git status` reports "up to
date with origin/master" from local refs only; no fetch was run.

**ConsumableMaster's TOC ordering** was not verified against its source's load-order claims (§4.3),
and **KickCD's `docs/testing.md`** was not read for the vendor gate the way AbsorbTracker's,
ConsumableMaster's and BankLedger's were (§8.3, §8.4, §8.5).

**The remaining unadopted targets** (LootHistory, PanelMaster, prettychat, WhatGroup) beyond
confirming none of them has a `libs/LibKa0s` directory.

**Cross-consumer counts are grep counts.** In §5.6 and §5.7 a zero means "no textual occurrence
outside `libs/` and `tests/`", not "verified absent by reading the seam". The call sites in §11.1
are the read-and-verified half; the count tables are not.






