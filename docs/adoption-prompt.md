# Adoption prompt — drop this into any Ka0s addon repo

Copy everything below the line into a fresh Claude Code session **in the addon's own repo**. It is
self-contained: it names what to read rather than restating rules that may have moved on.

Adopted: **AbsorbTracker** (consumer #1), **KickCD**, **ConsumableMaster** — all five modules each —
and **BankLedger**, which took Core, DebugLog, Slash and Options and **declines Perf** on structural
grounds (its capture engine never runs in combat and the probe's windows are combat-gated, so every
bucket would read 0.000 by construction; recorded at its `LIBKA0S-17`).

Remaining targets: `LootHistory`, `PanelMaster`, `prettychat`, `WhatGroup`.
`WhoGotLoots` and `BuffTextNotifications` are out of scope until they are on the standard at all.

Each adopter so far has surfaced a descriptor assumption that only held for the ones before it, which
is the point of the ordering rather than a sign it went badly: KickCD found the colour-shape
divergence; ConsumableMaster found the ordered-array enum shape, the `hasAlpha` default, the missing
slider-commit hook, `row.desc` vs `row.tooltip`, and the absence of any caller-driven grid; and
BankLedger found all four of v1.2.0's gaps at once — a console it could not skin, a value type Slash
could not render, a numeric enum that drew as a slider, and a settings canvas half-wired to Blizzard.
Expect the fifth to find something too, and prefer fixing it upstream over working around it in the
setup file — the rule of thumb that has held is that one host's misfit is a setup-file concern and
two is a library gap.

**A caution that comes out of BankLedger specifically.** All four v1.2.0 surfaces were built for one
host, and three of them are still called by that host and nobody else. Inside a frozen `-1.0` major
there is no deprecation available, so an assumption baked in against a single shape can only ever be
worked around. If you are the second host to touch one of the surfaces listed under "Provisional
surfaces" below, treat a misfit as a library gap on first contact rather than second.

---

## Task: adopt LibKa0s — five majors, eight files, plus the perf run

This addon needs the shared library the Ka0s WoW Addon Standard now points at. LibKa0s ships five
majors: `LibKa0s-Core-1.0` (secret-safe stringification, the window skin, the prefixed chat printer),
`LibKa0s-DebugLog-1.0` (the on-screen console), `LibKa0s-Slash-1.0` (dispatcher, help, schema CLI),
`LibKa0s-Options-1.0` (settings-canvas shell, widget makers, flow engine, scrollbar patch) and
`LibKa0s-Perf-1.0` (the A/B capture). Plus `testkit/`, a shared headless harness vendored to
`tests/_kit/`.

### The one thing that makes this different from the perf work

Perf **added** a capability the addon did not have. A capability you add cannot regress: nothing was
deleted, no existing test could break, and the whole risk lived in code that did not exist yet.

The other four majors are different in kind. **They replace code this addon currently owns and
ships.** Adopting them means deleting real files — a 400-to-500-line `DebugLog.lua`, two-thirds of a
`Slash.lua`, a third to a half of a `Panel.lua` — and rewiring what survives onto a library seam
through an adapter you write. Every one of those deletions is a chance to change rendered output,
lose a behavior nobody wrote a test for, or silently drop a schema row.

That changes the sequencing and it changes what "done" means:

- **Recon is not optional and it is not fast.** You must know, with file:line evidence, what each
  file owns before you delete any of it. See "Before you write anything".
- **Sequence smallest-blast-radius first.** Core, then the module with the cleanest 1:1 mapping, then
  the ones with adapters, then Options, then Perf. Per-addon order is below.
- **A test that passed before and after proves nothing if the code path moved.** The library-vs-host
  question is "does this render the same bytes", not "does this still run".
- **Some divergences fail silently and only in-game.** Colour codecs, EditBox-vs-Dropdown dispatch,
  `hasAlpha`, an unknown `row.type` dropping one row from a page, and **the `L` trap below**. Those
  are named per addon below. None of them raises. None of them shows up headless unless you write
  the assertion.

### Read these first, in this order. Do not work from memory or from this prompt's summaries.

1. **The standard** — <https://github.com/tusharsaxena/WowAddonStandards> — fetched with
   `curl -fsSL`, **not** WebFetch (its summarizer mangles verbatim content). The rewritten sections
   you need: `debug-logging`, `options-ui`, `slash-commands`, `testing`, `library-stack`,
   `performance`. Plus the anti-patterns index.
2. **`LibKa0s/README.md`** — the per-module descriptor tables, field by field, for all five majors,
   plus "What stays the host's", "Two divergences absorbed rather than decided", "`reset` takes a
   path, not a page", and the `suspend`/`resume` host contract. **This is authoritative over
   anything below.** Never invent a descriptor field; if a field you want is not in that README, the
   library does not have it and that is a finding to report.
3. **`LibKa0s/docs/releasing.md`** and **`LibKa0s/docs/record-schema.md`**.
4. **The worked references, in sibling repo `../AbsorbTracker`** — `core/CoreSetup.lua`,
   `core/DebugLogSetup.lua`, `settings/Slash.lua`, `settings/OptionsSetup.lua`,
   `settings/UnitPanel.lua`, `core/PerfSetup.lua`, `settings/About.lua`. Read them as **shapes to
   follow, not text to copy** — every adapter in them is specific to what that addon does, and this
   addon's write seam, schema vocabulary and load order are almost certainly different.

The library repo is a sibling: `../LibKa0s` relative to this addon's repo root.

### The `L` trap — read this before you write a single descriptor

This one has already shipped a broken panel, in the first addon to adopt after AbsorbTracker, and it
is the cheapest mistake in the whole exercise to make.

Every module that takes an `L` override resolves the descriptor's table first and falls through to
its own `STRINGS` only when the override **is not a string**. Your addon's locale table answers
*every* key with a string, because the standard mandates the metatable fallback:

```lua
local L = setmetatable({}, { __index = function(_, k) return k end })   -- locales/enUS.lua
```

So `L = NS.L` in a descriptor means `L["STEP_START"]` returns `"STEP_START"`, the library's own
strings are never reached, and the addon renders **raw keys** in place of English. KickCD shipped a
perf panel reading `Ka0s KickCDPANEL_TITLE_SUFFIX` / `STEP_START` / `STEP_MEASURE_A` exactly this
way. It fails for every key at once and only in game.

- **Translating nothing? Omit `L`.** That is the common case and what AbsorbTracker does everywhere —
  which is precisely why AbsorbTracker never hit this and why copying its shape does not protect you.
- **Translating something?** Pass a **plain** table of only those keys. The values may come from your
  locale table; the table you pass must not be it.
- The README's per-module descriptor tables used to say *"hosts on the Ka0s standard pass their
  `NS.L`"*. That advice was wrong and has been corrected — see **The `L` trap** in `LibKa0s/README.md`.

#### Pinning it — four things, and three of them were learned the expensive way

**1. One rendered assertion per adopted module.** A rendered label **MUST NOT** match
`^[A-Z][A-Z0-9_]+$`. A resolved string is prose; an unresolved one is the key, and no English label
is SCREAMING_SNAKE_CASE. Assert on the string the library actually rendered, reached through a real
accessor — a case that guards on `if label then` passes vacuously when the accessor does not exist,
which is how the first attempt at this test proved nothing.

**2. Only three of the five majors can express the trap.** `DebugLog`, `Slash` and `Perf` take an
`L`. **Core ships no `STRINGS` and Options reads no descriptor `L`**, so a rendered assertion there
is a case that cannot fail — worse than no case, because it reads as coverage. Write a **tripwire on
the library** for those two instead. The two tripwires are not the same shape, because the two
modules are not in the same position:

- **Core** — assert `lib.STRINGS` is absent *and* that `Core.lua`'s source names neither `STRINGS`
  nor a `d.L` read. Both halves hold today. AbsorbTracker, KickCD, ConsumableMaster and BankLedger
  all carry this one; copy any of them.
- **Options** — `Options.lua` **does** ship a `STRINGS` table, so the `lib.STRINGS`-is-absent half
  does not transfer and asserting it would fail on a module that is behaving correctly. The Options
  tripwire is the source half alone: assert the module reads no descriptor `L`. It passes today and
  goes red the day Options grows one, which is the whole point — the settings panel is where a raw
  SCREAMING_SNAKE key is most visible.

**This tripwire is required, not optional, for every adopted major that cannot express the trap.**
The 2026-08-01 v2 adoption run found this paragraph claiming three consumers carried an Options
substitute when none did; all four carry both tripwires now. Mutation-verify yours rather than
trusting it: add a `d.L` read to a scratch copy of the module and confirm the case goes red. A
tripwire that survives that mutation is not a tripwire.

Where the module *does* render a real library string, a rendered assertion beats a tripwire and
should be written as well as one — AbsorbTracker reads `lib.STRINGS.DEFAULTS_LABEL` back off the
built Defaults button with an explicit non-vacuity coupling, which is stronger than any source check
and is the pattern to follow when a real string exists to assert on.

**3. A source guard must match on what the expression EVALUATES TO, not on one spelling.** Every
adopter also greps its seam files for a descriptor handed the locale table, because a descriptor
field is not observable after `lib:New` returns. The obvious pattern is wrong:

```lua
L = NS.L                     -- the table itself                        OFFENDER
L = NS.L or { ... }          -- NS.L is always truthy, so: the table    OFFENDER
L = NS.L and { ... } or nil  -- evaluates to the plain table            fine
```

An end-of-line-anchored `L = NS.L` misses the `or` spelling completely. It also never looks at the
third line — which is the *legitimate* form KickCD actually ships, one `and`→`or` typo away from
being the live trap. Flag any `L =` whose value starts with the locale table unless the next token
is `and`.

**4. Give the matcher its own case, driving it against all three spellings.** A matcher nothing
tests can be narrowed back to a single anchored form while still reporting green — which is exactly
how it got there. Then **mutation-verify every assertion you wrote**: hand the descriptor your
addon's locale table, run, confirm red *with the message you expect*, and restore from a `cp`
backup — never `git checkout`, your work is uncommitted.

Finally, add the in-game half to `docs/smoke-tests.md`: walk every settings page, the console and
the perf panel, and confirm not one SCREAMING_SNAKE string is on screen. The source guard and the
rendered assertions are both blind to whatever the client actually draws.

### Before you write anything: work out what this addon actually does

Establish, with file:line evidence in your report, before touching a line:

- **What each module would replace, per file, in lines.** Which files delete outright, which shrink
  and to roughly what, and which survive untouched. If a file only half-maps, say which half.
- **The write seam.** How does one setting get written today? Its **arity** is the single most
  common adapter. The library calls `set(path, value)`. If this addon's is
  `Set(path, section, value)`, or dispatches to a per-row `row.set`, you need a closure — and it has
  to resolve the extra argument from the row, at call time.
- **The schema-row vocabulary.** The library's widget makers and parser read a fixed set of row
  fields (README, "Row fields the flow engine reads"). List every field this addon's rows use and
  map each one. Watch for: `tooltip` where the library reads `desc`; a `widget` key held separately
  from `type`; `options` where the library reads `values`; `type = "boolean"` where the library
  dispatches on `"bool"`; dropdown `values` shaped as an ordered array of records where the library
  wants a keyed table. An unmapped field is not an error — it is a row that silently vanishes from a
  page, or a `set` that answers `ERR_TYPE`.
- **The printer seam and every load-time capture of it.** `grep -n "local print" ` and
  `grep -n "\.print\|\.Print"` across the repo. Ace3's `AceConsole-3.0` embeds its `:Print` onto
  whatever table you passed to `NewAddon` — if that is the namespace, it clobbers a same-named
  custom printer. Find where the clobber is handled today and do not break it. Then find every file
  that takes the printer as a **file-scope upvalue**: those pin where a `CoreSetup.lua` may sit in
  the TOC, and if you get it wrong the swap silently no-ops while appearing to work.
- **The sink.** Where does chat output actually go — `DEFAULT_CHAT_FRAME:AddMessage`, or the Lua
  global `print`? Core's default is the former. If this addon uses the latter and the test mock only
  captures the latter, every chat assertion in the suite goes silent without one explicit `sink`.
- **The prefix.** Does the tag carry a trailing space of its own? If so Core needs `sep = ""`. Is
  the prefix defined in a file that loads *after* the seam has to sit? Then pass the **function**
  form of `prefix`, which is re-read on every call.
- **The `reset` verb's current argument.** Path, page, or nothing at all? See "The two
  convergences".
- **The landing page's command-row formatter**, and whether it differs from the chat help
  formatter in the same repo. In most of these addons it does.
- **The test harness delta.** Assertion names, case signature, whether the runner collects-then-runs
  or executes at registration, whether the loader sandbox has a `__newindex`, and every mock member
  the suites drive that `testkit/mock_base.lua` does not provide. `mock_base.lua`'s own header
  states what it deliberately omits — read it.
- **The hot paths, the nesting, the show/act decision, the event surface** — for Perf. A path that
  runs twice a session is not a bucket; it reads `0.000` forever and adds a row that says nothing.
  "This addon has almost no hot path" is a legitimate finding.

### What is already known about this addon

Surveys were run against all seven repos. Use these as a starting point to **verify**, not as facts
to trust — they were read-only recon and every line number below can have moved.

**KickCD** — the riskiest of the seven, and the reason it goes first. Core is *not* a pure refactor
here: three correct `issecretvalue` guards exist (`core/Compat.lua`, `modules/DebugLog.lua`,
`modules/Cooldowns.lua`) but the shared printer at `core/Util.lua` is **unguarded**, two of the
guards emit a bare `"secret"` sentinel where `lib.SECRET` is `"<secret>"`, and the probe mechanism
changes from `issecretvalue` to `pcall(table.concat)` — which diverges in-game for a non-secret,
non-concatable value such as a table. Audit all 22 `NS.Util.print` call sites before flipping, and
publish to the existing `NS.Util.print` key, never `NS.Print`, because AceConsole's embed at
`core/KickCD.lua` runs after any seam file that could sit early enough. Options is the hard one:
1,687 lines across `settings/Panel.lua`, `Panel_Widgets.lua`, `Panel_Render.lua`, of which roughly
450 (`RenderUnitPanel`, `PartitionUnitRows`, `RerenderUnitPanel`, `RestoreUnitLinks`,
`ResetAllPositions`, `ResetIconPosition`, `SetAndRefresh`, `ValidateSchema`, `AnchorValues`,
`BuildMainContent`) have **no library equivalent** and must be re-homed by hand. Three divergences
fail silently and only in-game: colours stored as a positional `{r,g,b,a}` array against the
library's keyed default (every saved colour reads white without `colorDecode`/`colorEncode`);
free-text `string` rows selected by the *absence* of `values` rather than by `dialogControl`; and
`hasAlpha` unconditionally true today but row-driven in the library. Plus a `tooltip`→`desc` rename
across ~94 rows, `panelKey`→`pageKey` across six builders, a 3-arg `Helpers.Set(path, section,
value)` write seam, `groupKey` on `row.panel`, and 14 `COMMANDS` handlers taking `(self, rest)` that
must become `(rest)` closures. DebugLog is the cleanest win in the repo — `modules/DebugLog.lua` is
518 lines with byte-identical formatters. `/kcd reset` takes a **page** and `/kcd reset spells`
rebuilds the spell database; converging removes five working commands and orphans that rebuild.

**ConsumableMaster** — riskiest for the harness, by a wide margin. Its suites use a `function(t)`
case signature with an assertion table (`t.eq`, `t.truthy`, `t.falsy`, `t.eqList`, `t.ne`,
`t.contains`, `t.near`) — the kit has none of that shape, and `eqList`/`contains`/`ne` have no kit
equivalent at all across ~73 call sites. `tests/wow_mock.lua` installs stubs directly into `_G`
rather than returning a builder table, so ~70 global assignments invert. And its suites depend on
**secret-value modelling** — `secretMeta`, `issecretvalue`, `M.secret()`,
`M.setCooldownsRestricted()` — which `mock_base.lua` does not provide at all. Treat the harness as a
multi-day rewrite, not a swap, and consider doing the four code modules against the existing harness
first. Elsewhere it is comfortable: the secret guard is already the `table.concat` probe with the
same sentinel, `COMMANDS` is already positional, and the chat help row already matches
`Sl:HelpRows()` including the indent. Watch `KCM.Say(fmt, ...)` — it is variadic-format, so the
alias onto `Print`/`Format` must handle both arms or ~1,000 call sites regress. `/cm reset` is a
confirm-gated global wipe; see the convergences.

**prettychat** — riskiest for Core, though not for the reason you would guess. The guard itself is
already the reference implementation, the AceConsole clobber is already reclaimed and cited by
anti-pattern number, and nothing captures the printer at file load. The risk is **placement**:
`settings/Schema.lua` calls `ns.Print` at *file load*, and the seam must also sit after
`core/PrettyChat.lua` (the clobber), which leaves exactly a one-file window. Get it wrong and either
the clobber wins or a load-time call hits a nil printer. Also `Const.PREFIX` already bakes a
trailing space, so Core needs `sep = ""` or every line double-spaces. Slash is the highest-risk
single item in either of its modules: `reset` takes a **page** with prefix matching, the library's
`ParseValue` rejects free-text strings and ~170 rows are free text, and `FormatValue`'s `|`→`||`
doubling has **no descriptor hook** — the realistic scope is adopting the dispatcher, help renderer
and landing-row formatter while keeping `list/get/set/reset` host-owned. Options is shell-only:
~233 of 725 lines delete cleanly, but the per-string editor is a documented 40/60 three-row block
against the library's fixed 50/50 grid, so the widget makers and flow engine go unused. (`RenderGrid`,
added in OptionsWidgets minor 4, is caller-driven and takes a bespoke `make` per cell — worth
re-checking that estimate against it before assuming the makers are unusable here.)

**WhatGroup** — the best Options return in the collection: ~568 of 822 lines of `settings/Panel.lua`
delete against identical layout constants and a byte-identical breadcrumb separator. **Gate it on
one check**: WhatGroup wraps both panel bodies in `C_Timer.After(0, …)` inside OnShow with an
explicit `ADDON_ACTION_FORBIDDEN` taint rationale. Confirm whether `O.RegisterOptionsPage` defers
the first build the same way; if it does not, adoption reintroduces a bug this repo already fixed.
Core is mechanical in-game but test-breaking: `core/WhatGroup.lua` captures `local p = NS.Util.print`
at file load so the seam must land before it, `NS.PREFIX` is defined *after* `core/Util.lua` so the
prefix must be the function form, and the mock has no `DEFAULT_CHAT_FRAME` so an explicit `sink` is
mandatory or ~1,100 lines of print-asserting suites go silent. `/wg reset` takes **no argument** —
it is a confirmed global reset that wipes `db.profile` to drop orphaned keys. `set <bool> toggle`
has no library grammar. Harness-wise it is cheap: assertion names already match the kit exactly.
Its mock, however, models distinct `CreateTexture`/`CreateFontString` objects, real `SetPoint`
overloads, recording `hooksecurefunc` and numeric `GetLeft/Right/Top/Bottom` — all of which
`mock_base.lua` either omits or deliberately declines. Keep the host mock as an extender.

**PanelMaster** — the harness is essentially the kit's ancestor; `Kit.expose(_G.PM_TEST)` is a
drop-in and suites need zero edits. Two mechanical blockers dominate Slash: `NS.COMMANDS` is
**keyed** (`{name=, desc=, fn=}`) and the library reads positional triples, so 18 entries plus
`OnSlash`, `PrintHelp`, the landing page and `tests/test_slash.lua` all move together; and schema
rows say `type = "boolean"` where the library dispatches on `"bool"`, which silently drops the row
from the page and `ERR_TYPE`s every `set`. Reset semantics are **already converged** — `/pm reset
<path>` and `/pm resetall` match — but preserve the "your panels are untouched" resetall wording via
the descriptor's `L`. Options is coupled: `settings/PanelEditor.lua` (814 lines) draws into
`settings/Panel.lua`'s scroll through a `P.__ui` export table, three of whose keys
(`trackDropdown`, `forgetDropdowns`, `makePairButton`) plus `safeRun` and `LSM_WIDGET` have no
library equivalent. The open-dropdown registry is PanelMaster's own invention, is tested, and stays.
Two DebugLog survivors need a new home: `NS.DebugBuild` (deferred-argument sink, no library
equivalent) and `D:Diagnose()`. Note the AceConsole reclaim already exists and is load-bearing;
five files capture `local print = NS.Print` at load.

**LootHistory** — BankLedger's architectural twin, and **BankLedger is the worked half**. This is the
most valuable thing that adoption produced for the next one: nearly every judgement below has already
been made once, in a repo you can read, against a codebase shaped like this one. Read
`../BankLedger/core/CoreSetup.lua`, `core/DebugLogSetup.lua`, `settings/Slash.lua`,
`settings/OptionsSetup.lua` and `settings/Panel.lua` before deciding anything here, and read its
`docs/pending/LEDGER.md` for the declines — `LIBKA0S-01` through `LIBKA0S-25` are the record of which
misfits went upstream and which stayed local.

DebugLog is the standout: `modules/DebugLog.lua` (357 / 359 lines) deletes outright, both formatters
are byte-identical to the library's, and the frame globals the descriptor generates from `name` match
today's hardcoded names exactly. **The window chrome no longer forces a decline.** DebugLog minor 4
added `applySkin` and `makeCloseButton`, both defaulting to what minor 3 did, precisely so these two
addons could keep their flat 1px `WHITE8X8` double border with its synthesized inner border and gold
title tint and their 24×24 class-coloured close button while still adopting the module. BankLedger
passes both and is the only host that does — see "Provisional surfaces". Take the printer and
`SafeToString` from Core; the guard half is a semantic no-op in both. The Core ordering trap is
sharp: five files per repo capture `local print = NS.Print` at load, and the AceConsole reclaim reads
`NS.Util.print`, so a seam that publishes only `NS.Print` is silently undone by that reclaim and the
whole change appears to work while doing nothing. Slash: `NS.COMMANDS` is keyed and must go
positional (15 / 13 entries, plus five test files iterating `cmd.name`/`cmd.desc`), rows say
`"boolean"`, and roughly a dozen exact-string assertions break on hex case and wording alone — and
where a value type the library cannot render is the blocker, Slash minor 5's `format` hook is the
supported answer rather than a host-side workaround.

Options carries the same schema-vocabulary mismatch. Of the two shapes this prompt used to say had no
maker, **one is now the library's**: a `type="number"` row carrying a `values` list renders as a
dropdown as of OptionsWidgets minor 5, so BankLedger's numeric dropdowns are no longer host-drawn and
LootHistory's should not be either. The `type="table", widget="MultiCheck"` inverted set picker is
still host-drawn and is a genuine gap. LootHistory remains the worse of the two for Options because
it has **no `tests/test_panel.lua`**, so a panel regression is invisible to the green gate — write
that file before you start Options, not after.

It is also the clearest remaining case for the landing-page convergence — BankLedger took it at
`settings/Panel.lua:356` and recorded the cost at `LIBKA0S-11`, so the answer to "what does this look
like afterwards" is a screenshot away rather than a judgement call. See below.

### Suggested module order

**Core first, always.** DebugLog, Slash, Options and Perf all carry `local NEEDS_CORE = 1` and
`return` **before** `LibStub:NewLibrary` when Core is absent or too old — the major is simply never
registered. Nothing else works until Core does.

After that, order by blast radius and by what this addon actually has:

| Addon | Order | Why |
|---|---|---|
| KickCD | Core → DebugLog → Slash → Options → Perf | Core alone and first, then re-run `/kcd debug spells`, `/kcd debug interrupt` and `/kcd list` in combat before proceeding. DebugLog is the clean −450. Options last of the four; do not start it until the kit's fireable AceGUI mock is in place, because the current suite cannot drive a single widget. |
| ~~ConsumableMaster~~ | **done** — Core → DebugLog → Slash → Options → Perf | Adopted in full. Ran Slash *before* Options in the end, and the planned reason for the reverse (re-anchoring `/cm reset`'s confirm popup) never materialised — the popup is registered at file scope and reached through the global `StaticPopup_Show`, so the dispatcher swap never touched it. The schema-CLI half waited on the enum and colour fixes rather than on the panel. Convergence #1 **is** taken: `/cm reset <path>` delegates to `Sl:CliReset` and a new `/cm resetall` inherits the confirm popup and the global wipe, matching AbsorbTracker and KickCD. It landed after the initial adoption rather than with it, which is why an earlier reading of this addon looked like a decline. Convergence #2 **is** taken too, as of the 2026-08-01 v2 report — but it was recorded as *not applicable* first, and how that happened is the useful part: the About panel reaches its command rows through `KCM.SlashCommands.GetCommandSummary()`, so a grep of `settings/` for `COMMANDS` returned nothing and the page looked absent. It was there the whole time, drawing its own format string while the chat half already went through `lib.FormatRow`. Now converged behind a `GetLandingRows()` delegating to `Sl:LandingRows()`, recorded at `LIBKA0S-13` with the spacing change in its CHANGELOG. Follow the render path, not the name. |
| prettychat | Core → DebugLog → Options (shell only) → Slash (partial) → Perf | Slash last and partial: only the dispatcher, help renderer and landing rows. Perf is low value here — a one-shot `_G` rewrite has no A/B story. |
| WhatGroup | Core → DebugLog → Options → Slash → Perf | Options early because it is the biggest clean win, gated on the deferred-OnShow check. Slash after, because the reset story needs a decision, not a translation. |
| PanelMaster | Core → DebugLog → Slash → Options → Perf | Slash before Options: the `COMMANDS` flip and the `"boolean"`→`"bool"` rename are prerequisites for the widget makers reading the same rows. |
| ~~BankLedger~~ | **done** — Core (printer only) → DebugLog → Slash → Options | Adopted in that order, DebugLog immediately after Core: highest value, lowest risk, and it validated the seam. **Perf is declined**, not pending — the capture engine never runs in combat and the probe's windows are combat-gated, so every bucket would read 0.000 by construction (`LIBKA0S-17`). The adoption drove all four of v1.2.0's library changes. |
| LootHistory | Core (printer only) → DebugLog → Slash → Options → Perf | Same, but write panel tests **before** Options — there are none today. |

Perf is last everywhere. Nothing it adds can regress, so it is the safest to defer and the easiest
to land once the other four are green.

### Then do the work

1. **Vendor the library.** Copy the **whole** `../LibKa0s/LibKa0s/` folder into `libs/LibKa0s/`
   (`cp -r ../LibKa0s/LibKa0s/. libs/LibKa0s/`) — never a file at a time: four of the five majors
   sit on `LibKa0s-Core-1.0` and refuse to register against an older minor than they name, and
   `Options` and `Perf` are each split across multiple files with paired attach guards. Copy from
   the library repo's own ship folder — **never** from a sibling addon's `libs/`, which may have
   drifted. Do not edit anything under `libs/`: a library problem is a finding to report, not an
   edit to make here.
2. **Vendor the test kit** the same way: `cp -r ../LibKa0s/testkit/. tests/_kit/`. Confirm the
   packaging metadata already excludes `tests/` before assuming it does.
3. **TOC.** Add `libs\LibKa0s\LibKa0s.xml` to the `# Libraries` block **after** LibStub and after
   Ace3. Then place each setup file against the load-order facts you established, not against
   AbsorbTracker's positions. The constraints that actually bind: the Core seam must sit after the
   file defining the prefix (or use the function form), after the AceConsole embed if the printer is
   published on the addon table, and before every file taking the printer as a load-time upvalue;
   the Options seam must sit before any file taking the helpers table as a load-time upvalue; and
   moving the console out of `modules/` can invert a dependency where it currently borrows a skin or
   close button from another module. Add `<Addon>PerfDB` to `## SavedVariables:` as a second global
   when you get to Perf.
4. **Write the seam files.** One per module, shaped like AbsorbTracker's but adapted:
   `core/CoreSetup.lua`, `core/DebugLogSetup.lua`, `settings/Slash.lua` (or fold into the existing
   one), `settings/OptionsSetup.lua`, `core/PerfSetup.lua`. Each must **degrade, not error**, when
   its major is absent — build a stub carrying every member the addon actually calls, then grep the
   repo for that namespace key and make the stub answer all of it.

   **The wording of that degradation is standardised. Follow it; do not invent a sixth phrasing.**
   One shared cause clause, defined in `core/CoreSetup.lua` because that is the first of the seams
   the TOC loads, set *outside* the `if not lib` branch because the later seams read it on both
   paths:

   ```lua
   NS.LIBKA0S_MISSING = "The LibKa0s library is missing from this installation of <Addon Name> " ..
       "(expected in libs/LibKa0s)"
   ```

   Every seam then appends its own consequence and its own terminal punctuation —
   `NS.LIBKA0S_MISSING .. ", so the debug console window is unavailable."`,
   `", so the settings panel is unavailable."`, `", so performance measurement is unavailable."` —
   and the Core fallback printer announces once, on the first line the addon prints, with
   `NS.LIBKA0S_MISSING .. "; running on reduced built-in fallbacks."`. A degraded install therefore
   says the same thing about **why** at every site and a different thing about **what** at each one.

   This is AbsorbTracker's PLAN-04 pattern (six sites), which ConsumableMaster follows (five) and
   KickCD has converged onto. It is the standard because the alternative is a user with a broken
   install seeing a different sentence depending on which of these addons they happen to have open,
   which is exactly what a shared clause exists to prevent. Copy the constant and the append shape;
   the only thing that varies is the addon's own name and the `so <what> is unavailable` tail.
5. **Keep the host's existing keys alive.** Every one of these addons has dozens to a thousand call
   sites reading a printer, a `Debug` function or a helpers table by name. Republish through those
   names — `NS.Debug = D.Debug` (it is a plain bindable function, no `self`), a shim table
   re-exporting the helper names the page builders already use — rather than renaming call sites.
   The migration is large enough without touching every consumer.
6. **Delete what the library now owns**, file by file, and only after the seam is green. Report the
   line delta per file.
7. **`.luacheckrc`.** New globals and `debugprofilestop` for Perf, each with a comment.
8. **Tests.** Failing first, then the module, then the consumer. For each module: descriptor
   well-formed; the seam degrading correctly with the library **absent** (exercised by loading the
   addon without it, not by hand-stubbing); and — the part that matters here — an assertion on
   **rendered output** wherever a formatter changed hands, comparing bytes, not "did it run". For
   Options specifically, drive the schema→widget→write path through the kit's fireable AceGUI mock;
   in several of these addons that path has never been tested at all.
9. **Docs.** Update `docs/ARCHITECTURE.md`, the file index / module map, and `docs/testing.md`.
   Regenerate `docs/test-cases.md` and move the README `[tests]` badge **count** in the same change
   — the count only, never the version. The badge and the inventory drift the moment they are not
   moved together, and every one of these repos has a rule saying so that has been broken at least
   once.

   Three specific things the last audit found missing in docs that were otherwise current:
   - **The vendor gate, written down where a maintainer will look.** `docs/testing.md` documents the
     green gates, and none of them can see a stale vendored library — the library's suite passes
     against the library, and the addon's passes against a stale copy that still works. Put the four
     diffs from **The gate** below into `docs/testing.md`, with what each answer means.
   - **The shared cause clause, in the module map and ARCHITECTURE.** `core/CoreSetup.lua` publishing
     `NS.LIBKA0S_MISSING` is a cross-file contract four other seams depend on, not an implementation
     detail of one file.
   - **`docs/smoke-tests.md`**, in that file's existing format — see step 10.
10. **Smoke tests for what no headless suite can reach.** At minimum: the degraded install (rename
    `libs/LibKa0s` aside, `/reload`, confirm zero Lua errors, a **complete** `list` output, the
    notice said exactly **once**, and the cause clause matching the other adopters word for word);
    the `L` trap (walk every page, the console and the perf panel, confirm no SCREAMING_SNAKE on
    screen); any convergence whose destructive path carries a confirmation, on **both** entry points;
    and a parity check for any layout that changed hands, framed as "nothing moved" — anything that
    looks different is the finding. Rename the folder back before you finish.
11. **Provenance.** `LICENSE` ships inside the payload as of v1.1.1, so a whole-folder copy carries
    it — do not hand-copy it into `libs/`, which would make the vendored folder differ from the ship
    folder and break the gate for real. Add one line to the addon's README naming what it bundles:

    ```
    Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v1.2.0 (MIT).
    ```

    The version there is **whatever is being released**, not a literal to copy — read it out of
    `../LibKa0s/CHANGELOG.md`'s top block and confirm `git -C ../LibKa0s tag` actually carries that
    ref, because a provenance line naming an untagged release answers with a string nobody can check
    out. Without the line at all there is no way to answer "which LibKa0s does this addon ship?"
    short of grepping minors out of vendored source — which is the question a re-vendor sweep needs
    answered fastest.
12. **Record every decision in `docs/pending/LEDGER.md` as you go**, one entry per module, naming the
    upstream minor that unblocked anything that needed one. ConsumableMaster's `LIBKA0S-01` … `-08`
    entries — superseded rows preserved rather than deleted — are the model, and the reason its
    adoption is auditable where the others' are only inspectable. Write the entry when you make the
    call, not at the end: the ones that get lost are the decisions that felt obvious at the time.

### The two user-visible convergences — deliberate, do not "fix" them back

1. **`reset` takes a PATH, not a page.** `Sl:CliReset(rest)` resolves `rest` through `findRow` and
   applies one row's default. Page-scoped reset lives on the settings panel's **Defaults** button,
   which is where it belongs. This is a real removal for several addons: KickCD loses
   `/kcd reset general|icons|castbar|label` and must re-home `/kcd reset spells`'s database rebuild;
   prettychat loses `/pc reset <category>` including its prefix matching, and its `ResetCategory`
   clears a second dimension no single `applyDefault` reproduces; ConsumableMaster's `/cm reset` was
   a confirm-gated global wipe that becomes a one-row reset, and it is the worked example of the
   right answer — the popup was re-anchored to `/cm resetall`, so the destructive path kept its
   guard and the path-scoped verb still means what it means everywhere else; WhatGroup's
   `/wg reset` is a confirmed global reset that
   also wipes the profile table to drop orphaned keys, and the code exists precisely so the button
   and the slash share one body — naive adoption forks them. Decide the story **before** writing the
   descriptor, and ship it with a CHANGELOG breaking-change entry and a deprecation message, not
   silently.
2. **The landing page renders command rows through the one row formatter, in the help colours.**
   `Sl:LandingRows()` returns `lib.FormatRow(command, description)` un-indented; `Sl:HelpRows()`
   returns the same rows with a two-space indent. Most of these addons currently carry **two
   divergent formatters for the same data** — a chat one that already matches `FormatRow`, and a
   landing-page one with double spaces around the em dash, the dash explicitly white-wrapped and the
   description bare. Converging collapses the double spaces to single, drops the dash's colour span
   and adds one to the description. BankLedger, LootHistory and PanelMaster all change here; so do
   KickCD, prettychat and WhatGroup. **That is the accepted cost** — it eliminates a silent drift
   between `settings/Panel.lua` and `settings/Slash.lua` that exists in every one of these repos.
   Only the panel changes; the chat help is already correct nearly everywhere. Where a
   header line's wording matters (an alias sentence, a reassurance about untouched data), preserve
   it through the descriptor's `L` table rather than reformatting the rows.

   **"Not applicable" is not "declined", and the two need different write-ups.** An addon with no
   landing page carrying command rows has nothing to converge — there is no divergent formatter to
   collapse, so there is no decision to record and nothing for a future reader to review. Do not
   build a landing page to satisfy a convergence. A **declined** convergence is different in kind:
   the thing existed, you chose not to converge it, and that choice must be written down — in the
   addon's ledger or CHANGELOG — or the next consistency sweep will read it as an oversight and
   "fix" it.

   **Prove "not applicable" by following the render path, never by grepping for a name.** There is no
   worked example of it here on purpose: all four consumers turned out to *have* a landing page. This
   paragraph used to name ConsumableMaster as the example, on the strength of a grep of `settings/`
   for `COMMANDS` that genuinely returns nothing — and it was wrong. Its landing page reaches its
   command rows through `KCM.SlashCommands.GetCommandSummary()`, one helper-function indirection away
   from any name a grep would match, and it was carrying its own formatter the whole time. Start from
   the frame the config command opens, find its renderer, and read what that renderer draws. A name
   that does not appear is evidence about the name, not about the page.

**For BOTH convergences, put this addon in exactly one of three states and say which in your
report: adopted, declined, or not applicable.** This is not bookkeeping. The 2026-08-01 adoption
report found ConsumableMaster's `reset` divergence with **zero** occurrences of the word "reset"
anywhere in its ledger — a deliberate, defensible choice that no artefact recorded, in a repo whose
ledger is otherwise the best in the collection. The next sweep would have read it as an oversight
and "fixed" a confirmation guard off a destructive path. An unrecorded decision is indistinguishable
from a mistake, and the cost lands on whoever finds it, not on you.

Where a convergence removes a destructive verb's confirmation, **re-anchor the popup before you
ship** — `/cm resetall` is the worked example — and add a smoke-test step proving the guard survived
on **both** entry points. A settings button and a slash verb that reach the same popup are two
paths, and a suite that only clicks the button proves nothing about the verb.

### The working method that survived twelve milestones

1. **Recon before code.** Read the target files end to end. Produce the file:line evidence above.
   Do not start from what a summary says the code does.
2. **Failing tests first**, and **confirm each fails for the stated reason** — read the actual
   failure message. A test that fails because the file does not exist yet is not testing what you
   think.
3. **Then the module, then the consumer.** Library seam green in isolation before the addon is
   rewired onto it.
4. **Adversarial verification, including mutation.** Break the implementation on purpose — invert a
   condition, return a constant, drop a field — and confirm the suite goes red. Any assertion that
   survives a mutation it should have caught is not an assertion; fix it or delete it.
5. **Fix, re-verify, regenerate the case list, record deviations.** Every place the library did not
   fit this addon's shape is the most valuable thing in your report — the contracts are still
   unfrozen.

### Standing hazards — each of these cost a milestone

- **`sed -i` with a `$` anchor never matches a CRLF line**, and reports success. This repo and every
  addon repo pin `* text=auto eol=crlf`. Use a real editor operation, or match `\r\?$`, and verify
  the edit landed by reading the file back.
- **A suite listed in a runner but missing from disk is SKIPPED, not failed.** A typo in the suite
  list is a silently green run. Cross-check the list against `ls tests/test_*.lua`.
- **Restore a mutated file from a `cp` backup, never `git checkout`** — the milestone is
  uncommitted, and `git checkout` takes the whole file back to the last commit, discarding work.
- **`and`/`or` is not a conditional when the value can be `false`.** `x and a or b` returns `b` when
  `a` is `false`. Every settings row in these addons is a boolean.
- **A test that cannot fail is worse than no test.** It reads as coverage and buys nothing. This is
  what step 4 above exists to catch.
- **Editing `libs/` to fix a library problem** creates a fork nobody knows about, and the next
  re-vendor silently reverts it.
- **Counting `tests/perf.lua`'s scenarios** in `docs/test-cases.md` or the `[tests]` badge. They are
  not test cases.

### When the library itself has to change

Expect this. AbsorbTracker is one addon, and every descriptor field was shaped against it — so the
first thing a second adopter does is find the assumptions. A gap here is the most valuable output of
the whole exercise, and it is **not** something to work around locally.

**Never edit `libs/`.** The next re-vendor reverts it silently and the revert reads as a regression
with no cause anywhere in this repo's history. A library problem is fixed in `../LibKa0s` and
re-vendored back. That is the whole rule, and it has no exceptions.

**First, decide whether it is actually a library problem.** Most misfits are host-shaped and belong
in the adapter you write in the setup file — a 3-arg write seam wrapped down to 2, a `groupKey` that
reads a differently-named row field, a colour codec. Reach for a library change only when the
descriptor genuinely cannot express what the host needs. If you can write it as a closure in the
setup file, it is not a library change.

**The contract is additive-only within `-1.0`.** You may ADD an optional field with a default that
preserves today's behaviour for every existing consumer. You may **not** remove a field, rename one,
change what one means, or make an optional field required — several addons have vendored copies and
you cannot know who holds what. If the change cannot be expressed additively, stop and report it
rather than doing it: that is a `-2.0` conversation, not a migration step.

When it is a real, additive library change, do it in this order and do not skip the middle:

1. **Write the failing test in `../LibKa0s` first**, in that module's own suite, and confirm it fails
   for the reason you expect — the individual message, not "the suite is red".
2. **Make the change.** Default the new field so an existing consumer that does not pass it behaves
   exactly as it does today.
3. **Bump that file's `MINOR`** — `MINOR` in `Core.lua` / `DebugLog.lua` / `Slash.lua` /
   `Options.lua` / `Perf.lua`, `WIDGETS_MINOR` in `OptionsWidgets.lua`, `SCROLL_MINOR` in
   `OptionsScroll.lua`, `PANEL_MINOR` in `PerfPanel.lua`. Only the files you touched.
4. **Update `../LibKa0s/CHANGELOG.md`.** The version block must contain the literal substring
   `<FileBasename> minor <N>` for every file, at its new number. `tests/test_versioning.lua` fails
   otherwise — this is enforced, not remembered.
5. **Document the new field** in `../LibKa0s/README.md`'s descriptor table for that module. A field
   that exists and is undocumented is a field the next adopter re-invents.
6. **Green the library**: `lua tests/run.lua` and `luacheck .` (0/0) in `../LibKa0s`.
7. **Re-vendor into EVERY consumer, not just this addon.** The consumer list is in
   `../LibKa0s/docs/releasing.md`. It starts at AbsorbTracker and grows by one every time an addon
   completes this migration — so check it, do not assume it is still just the one.
8. **Run each existing consumer's full suite** and confirm it is unchanged. This is the step that
   proves your "additive" change was additive. At the time of writing: **AbsorbTracker 467**,
   **KickCD 646**, **ConsumableMaster 559**, **BankLedger 685**, each 0 failed. If any of those moves
   *while you are changing the library*, your change was not additive and you need to know before it
   ships rather than after.

   **Run all four, and know which one is load-bearing for what you touched.** A surface with a single
   consumer is proved additive by that consumer's suite and by nothing else — the other three stay
   green through a regression in it, because they never call it. Everything v1.2.0 added is in that
   position today and BankLedger is the one host that exercises it, which is why the fourth total
   above is not a formality. Check "Provisional surfaces" before deciding a three-suite run was
   enough.

   Read the CURRENT number from that addon's own `docs/test-cases.md` Totals table before you start,
   and compare against your own before/after — do not trust the three above. They are a snapshot,
   they go stale every time an addon adds a test of its own for reasons that have nothing to do with
   you, and a stale figure here reads as a regression that is not one. (The 449 this line used to
   carry went stale exactly that way.)
9. **Commit the library change in `../LibKa0s` on its own**, then the re-vendor in each consumer as
   its own commit, so the sync is legible in history rather than buried in a feature diff.
10. **Add this addon to the Consumers table** in `../LibKa0s/docs/releasing.md`, per module, naming
    the file its wiring lives in.

**If you have to raise a `NEEDS_CORE` floor, stop and say so.** That is a breaking change to the
*vendoring* rather than to the API: every consumer whose `libs/` still holds the older `Core.lua`
loses the whole module until it is re-vendored. It is legitimate, but it is a decision, not a step.

**Report every library change you made, and every one you decided against.** The ones you rejected
are as useful as the ones you made — they are the record of where the contract held under pressure.

### The gate

Run in this addon's repo and paste the real output — do not summarise a run you did not do:

```
lua tests/run.lua                                              # all green
luacheck .                                                     # 0 warnings / 0 errors
diff -r --strip-trailing-cr ../LibKa0s/LibKa0s libs/LibKa0s    # content — MUST be empty
diff -r ../LibKa0s/LibKa0s libs/LibKa0s                        # bytes  — SHOULD be empty
diff -r --strip-trailing-cr ../LibKa0s/testkit tests/_kit      # content — MUST be empty
diff -r ../LibKa0s/testkit tests/_kit                          # bytes  — SHOULD be empty
```

**The `luacheck` figure is scoped, not repo-wide**, and reading it as repo-wide is how a clean run
gets mistaken for a clean adoption. Every `.luacheckrc` here excludes `libs/` — correctly; vendored
code is not the host's to lint — and most exclude `tests/` as well. Before you quote 0/0, print what
was actually checked and confirm **every seam file you wrote is inside that set**:

```
cat .luacheckrc | grep -A5 exclude_files
luacheck . --formatter plain | tail -1        # and check the file count it reports
```

A warning inside a seam file is an adoption defect. A warning elsewhere is pre-existing host hygiene
and is not yours. Neither statement means anything if the lint never opened the file.

**Run both of each pair, and read the difference between them.** A non-empty *content* diff means a
copy has genuinely forked, and the fix is to re-vendor. But if the content diff is empty and only
the *byte* diff reports files, **nothing has forked** — the two checkouts merely disagree about line
endings. Every repo here pins `* text=auto eol=crlf` in `.gitattributes` while git stores the blobs
as LF, so a working tree holding either ending round-trips to the same blob and `git status` stays
clean on both sides; the state is invisible and self-perpetuating. The fix is to renormalise
whichever side drifted — `git add --renormalize .`, and if the working tree does not flip, delete
the affected paths and `git checkout -- .` to pull them back through the filter. It is **never** an
edit to `libs/`. Re-vendoring will not converge a line-ending divergence either; it just moves the
wrong endings downstream, and the step people reach for after a re-vendor that did not work is the
one this whole discipline forbids.

Then confirm, explicitly:

- the TOC load order satisfies every constraint you established in recon, and you say which file
  pins which;
- the degradation stub for each adopted major answers every member the addon calls, and every one of
  them explains the absence through the shared `NS.LIBKA0S_MISSING` cause clause rather than through
  wording of its own;
- every formatter that changed hands has a byte-level assertion, and you name the rendered strings
  that deliberately changed;
- no descriptor was handed an addon-wide locale table, and each adopted module has a case proving
  its user-visible strings resolve to prose rather than to their own keys — or, for Core and Options
  which cannot express the trap, the library tripwire that stands in for it;
- every one of those assertions was mutation-verified, and you name the failure message each
  produced;
- both convergences are in a stated state — adopted, declined or not applicable — and every
  *declined* one is written down where the next reader will find it;
- the `[tests]` badge, `docs/test-cases.md` and the suite all agree;
- the addon's README names the library version it bundles.

Follow this repo's own `CLAUDE.md` on committing and version bumps — **do not** bump the addon
version for this work, and do not push.

Report at the end: the line delta per file, the adapters you had to write and why, every place the
descriptor contract did not fit this addon's shape (the most valuable thing you can tell me), the
rendered-output changes a user will notice, and anything you left undone.

Finally: several of these changes are only observable **in-game** — colour codecs, widget dispatch,
alpha, panel layout, the suspended arm. Tell me exactly what to run to verify it live: the commands,
in order, and what should appear if it is wired correctly.

### You will be audited — read the audit first

`../LibKa0s/docs/adoption-report.md` is a reusable report run across every adopter. It checks
version fidelity, byte fidelity (both halves), module coverage, adoption **depth** as opposed to
presence, convergence state, `L`-trap guard coverage counted as *guarded module-adoptions / total*,
the green gate with warnings **attributed** to adoption or to pre-existing host hygiene, and
provenance. Its output is a frozen dated bundle under `docs/adoption/<YYYY-MM-DD>/`.

Read it before you start and build so you would pass it. Two of its scoring rules are worth knowing
up front because they cut against the obvious instinct:

- **Depth is not measured by how much code you deleted.** A host that correctly declines half the
  library — the skin, a widget maker that does not fit — is a faithful adopter. A host that took
  everything and pinned none of it is not.
- **A surface with one consumer is a finding**, not a success. Its contract has been tested against
  exactly one shape, and every adopter so far has surfaced an assumption that only held for the ones
  before it.

### Known library gaps — check these before you plan around them

Open shortfalls, so you do not rediscover them mid-adoption or design a page around a surface that
cannot reach where you need it:

- **`RenderGrid` takes no `parent` and never calls `DoLayout()`.** It renders into
  `EnsureScroll(ctx)`, which anchors flush to the whole of `ctx.body`. If your addon owns its own
  scroll container — a list with a hand-anchored header above it — `RenderGrid` cannot draw into it,
  and calling it there silently creates a second, overlapping full-body scroll frame. Every sibling
  maker takes a `parent`; this one does not. It also ends without the `scroll:DoLayout()` that
  `RenderRows` ends with, so a page rendered through `RenderGrid` **alone** must call it itself.
  Tracked at <https://github.com/tusharsaxena/KickCD/issues/10>. If your list needs either, say so
  and fix it upstream rather than working around it — that issue exists because a recon concluded
  "not expressible", which was the correct and useful answer.
- **`RenderGrid` offers two cell widths only** — `HALF` (0.5) or full-width via `wide = true` — and
  emits `AddSpacer(ROW_VSPACER)` after every flushed row with no opt-out. A dense multi-column strip,
  or a contiguous block of text lines with no gutter, is not expressible today without changing its
  appearance.

If you find another, add it here in the same shape: what the contract cannot express, the file:line
where it binds, and the issue tracking it.

### Provisional surfaces — one consumer each, and treated as unsettled

A gap is a contract that cannot express what a host needs. These are the opposite failure: contracts
that **can** express exactly one host's need, because exactly one host has ever used them. Every
surface v1.2.0 added was driven by BankLedger, and three of the four are called by BankLedger and
nobody else. `-1.0` is frozen additive-only, so there is no deprecation available inside it — an
assumption baked in here can be worked around later but never renamed. If you are the second host to
touch one of these, treat a misfit as a library gap on first contact.

- **`applySkin` / `makeCloseButton` (DebugLog minor 4).** One implementation behind them. The
  contract is that you are handed a **fully built** frame with `frame.title` and `frame.divider`
  already assigned; that it tolerates a missing divider is an accident of BankLedger's helper, not a
  promise. If your chrome helper needs anything else on the frame, say so rather than reaching for a
  global.
- **The Slash `format` hook (Slash minor 5).** Documented to take precedence over `colorDecode`, and
  **that precedence has never executed** — BankLedger passes no colour codecs, so no host has ever
  set both. Treat the ordering as *documented but unexercised*: the first host to pass both should
  assert it rather than assume it, and if the assertion is awkward to write, that is the signal the
  ordering wants revisiting while it still can be. The second motivating case — prettychat's `|`
  doubling, i.e. `format` applied to rows the library *can* already render — has not been tried
  either.
- **The numeric-enum dropdown (OptionsWidgets minor 5).** The route is **inferred** from the presence
  of a `values` list on a `type="number"` row, not opted into. Any existing number row that grows a
  `values` key silently reclassifies from slider to dropdown, with no code change and no test
  anywhere that would see it. KickCD's 31 number rows all carry min/max/step today; the first one to
  gain a list flips. It has also never been rendered alongside `sliderCommit`, because the one host
  with `sliderCommit` has no enum rows.

The fourth v1.2.0 addition, `CreatePanel` stamping `OnCommit`/`OnRefresh`/`OnDefault`, is **not** in
this list for the opposite reason: it is not opt-in, so all four consumers gained it at once. It is
guarded in the library's own suite and in all four hosts.
