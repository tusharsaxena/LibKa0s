# CCN elimination — LibKa0s upstream promotions

Branch `feat/fix-ccn`. Design: `../specs/2026-08-04-ccn-elimination-design.md`.

Five promotions out of ~20 candidates, chosen by: present in 2+ repos with the same semantics,
no per-addon escape hatches, a stable abstraction rather than a coincidence of today's code.

**Order matters.** Slash primitives first (pure additions, no consumer churn), then the Options
landing page, then `Core.RGBA`, then `Perf`, then `testkit` **last and on its own commit** —
giving the base stub a recording `GetWidth` changes what three repos see, and that wants an
unambiguous red/green across all eight suites before re-vendoring.

## Synthesis

```
Five promotions out of roughly twenty candidates. I applied the 2+ repos / no escape hatches / stable abstraction test literally and verified every claim against the sibling repos rather than the summaries, which changed several verdicts in both directions.

WHAT GOES UP, strongest first:

1. LibKa0s-Options gains `O.BuildLandingPage(ctx, spec)` + `O.TextRow(ctx, text, opts)` and four LAYOUT constants. Three repos define a function literally named `Helpers.BuildMainContent` rendering the same page with the same constants (300/8/12/6) and the same guard pairs; the only differences are the logo path and where the one-liner comes from. Every primitive it uses is already in this major (EnsureScroll, ClearScroll, AddSpacer, Section), `buildMain(ctx)` is already the descriptor seam, and `lib.LAYOUT` already owns `SECTION_HEADING_H`. TextRow stands on its own — the `if w.label and w.label.SetJustifyH` guard is in six repos.

2. LibKa0s-Slash gains four lib-level functions: `SplitVerb`, `FindCommand`, `CommandRows`, `ParseBool`. `findCommand` and `lowerFirst` are BYTE-IDENTICAL file-locals in KickCD and ConsumableMaster; both repos also hand-roll a sub-help row format that renders identically to the library's own `FormatRow`; `parseBool`'s eight-word set exists in three places, one of them already inside Slash.lua but unreachable. `CommandRows` is the existing instance-local `rows(indent)` generalized, so HelpRows/LandingRows become one-liners over it and top level and sub level share one formatter by construction.

3. Core gains `lib.RGBA(c, dr, dg, db, da)` — four numbers in, four out, no allocation. Promoted mainly because LIBKA0S ITSELF has two disagreeing copies: `Slash.FormatValue` reads both storage shapes, `OptionsWidgets.decodeColor` reads only the keyed one, so the library's CLI renders colours its own widget cannot decode. KickCD's Util.Unpack and ConsumableMaster's MacroBar.lua:53 are independent arrivals at the same signature.

4. Perf gains `P.Open()` / `P.Close(t0, key)` — a module LibKa0s already owns, three instrumenting adopters, uniform semantics. Deliberately NOT the closure-returning `Bracket` that was proposed: a per-bracket closure allocates on a path whose whole contract is costing nothing when the probe is off.

5. testkit/mock_base.lua gets the geometry-recording `stubFrame` via `__frameMethods` + `__makeStubFrame(extra)`. Four repos independently rewrote the base stub the same way with near-verbatim comments, two of those rewrites are the CCN>15 offenders, and KickCD has already converted its copy to the exact table shape proposed — so the destination is proven, not speculative. This goes to testkit/, never to a shipped module.

THE BIG REJECTION is the schema-migration runner, the most-nominated candidate. It is in 8 repos in five incompatible variants that disagree on who stamps the version, whether stamping happens per step or once at the end, whether a failed step still stamps, and — in KickCD's case — whether the version stamp can be trusted at all, since AceDB backfills it and masks legacy accounts as current. A shared runner needs five escape hatches to own an eight-line loop of CCN 4, while risking silent corruption of users' SavedVariables. I also rejected `core.CallIf` despite it being the single most-repeated shape in the collection (400+ sites, 9 repos): it trades readable method calls for stringly-typed lookups, erases the three distinct reasons those guards exist, and saves about one CCN per site.

TWO CONSTRAINTS THE IMPLEMENTER MUST HONOUR. First, `NEEDS_CORE`: Slash and Options both declare a floor of 1, and docs/releasing.md treats raising it as a breaking change to the vendoring — this is the documented reason `enumList` is duplicated verbatim between two majors rather than hoisted. So `lib.RGBA` ships for hosts now; the library's own two call sites adopt it only alongside a floor raise made for other reasons. Second, adopting RGBA in `Slash.FormatValue` is a real behaviour change for malformed mixed-shape colours (it currently mixes shapes per channel); land it with a case pinning that input.

Suggested order: Slash primitives (pure additions, no consumer churn), then Options landing page, then Core.RGBA, then Perf, then testkit last and on its own commit — giving the base stub a recording `GetWidth` changes what the three repos that never overrode it see, and that wants an unambiguous red/green across all eight suites before re-vendoring.
```

## 1. LibKa0s/Options.lua + LibKa0s/OptionsWidgets.lua (extend LibKa0s-Options-1.0; no new major)

### Rationale

Three repos define a function literally named `Helpers.BuildMainContent` that renders the same page: AbsorbTracker/settings/About.lua:38, KickCD/settings/Panel.lua:469, WhatGroup/settings/Panel.lua:91. All three declare the same four constants with the same values (300 / 8 / 12 / 6). All three build the logo as a full-width SimpleGroup with SetLayout(nil) at height 300, containing a texture anchored TOPLEFT at native size. All three build the notes Label with the identical pair of guards (`SetFontObject(_G.GameFontHighlight)`, `SetJustifyH("LEFT")`). All three render one Label per `Slash:LandingRows()` entry with the same justify guard. The only differences are DATA: the logo path, and whether the one-liner comes from TOC Notes (AbsorbTracker, WhatGroup) or a localized literal (KickCD).

This is the last host-side copy in a stack the library already owns end to end: EnsureScroll, ClearScroll, AddSpacer and Section are all LibKa0s-Options; LandingRows and FormatRow are LibKa0s-Slash; `buildMain(ctx)` is already the descriptor seam the page hangs off. WhatGroup's own comment concedes the point — "options-ui-§8 lists these as the host's, because the body is" — the constants are host-side only because the body is. Move the body and the constants follow.

Both KickCD's and WhatGroup's files carry a comment recording that this page previously hand-rolled a SECOND command-row formatter and drifted from `/kcd help` until it was converged onto the library's. The page body is the same class of drift, one level up, and is still uncorrected in three places.

O.TextRow earns its place independently of the landing page: the `if w.label and w.label.SetJustifyH` guard appears 10x in ConsumableMaster, 5x in WhatGroup, 4x in AbsorbTracker, 4x in KickCD, 3x in BankLedger, 2x in LootHistory — six repos, and only three of them have a landing page in this shape.

### API

```
lib.LAYOUT gains four constants, moved from three host copies that already agree:
  LANDING_LOGO      = 300
  LANDING_GAP_LOGO  = 8
  LANDING_GAP_DESC  = 12
  LANDING_GAP_HEAD  = 6

OptionsWidgets.lua (attached on O, beside AddSpacer/Section):
  O.TextRow(ctx, text, opts) -> widget
    Creates a full-width AceGUI Label, sets `text`, left-justifies it, adds it to
    O.EnsureScroll(ctx), returns it. `opts` optional:
      opts.fontObject  string  a _G font-object NAME ("GameFontHighlight"); applied only when
                               both widget.label.SetFontObject and _G[name] exist.
      opts.justify     string  default "LEFT".
    No-op returning nil when AceGUI or the scroll is absent. Owns the
    `if w.label and w.label.SetJustifyH then` / `SetFontObject` guard pair once.

  O.BuildLandingPage(ctx, spec)
    Renders the whole landing body: ClearScroll -> EnsureScroll -> logo -> notes -> per section
    (heading + rows). `spec`:
      spec.logo      string             texture path. Omitted = no logo block.
      spec.logoSize  number             default lib.LAYOUT.LANDING_LOGO.
      spec.notes     string|function()  the one-liner. A function is called at RENDER time (a
                                        host reading TOC Notes cannot resolve it at declaration).
                                        Empty/nil = the notes block and its spacer are both
                                        skipped, matching AbsorbTracker today.
      spec.sections  array of { heading = string, rows = function() -> array of string }
                                        `rows` is a function, not an array, so a re-render picks
                                        up a command added since registration.
    Headings go through the existing O.Section; rows through O.TextRow; gaps through O.AddSpacer
    with the LAYOUT constants. Returns nothing.

Options.lua descriptor gains one optional field (additive-only rule honoured):
  landing  table  optional. When `buildMain` is absent, the shell installs
                  `buildMain = function(ctx) O.BuildLandingPage(ctx, d.landing) end`.
                  A host that wants extra content below keeps its own buildMain and calls
                  O.BuildLandingPage itself as line one.
```

### Consumers

- AbsorbTracker:Helpers.BuildMainContent (settings/About.lua:38)
- KickCD:Helpers.BuildMainContent (settings/Panel.lua:469)
- WhatGroup:Helpers.BuildMainContent (settings/Panel.lua:91)
- AbsorbTracker:addBlock (settings/About.lua:28 — deleted, becomes O.AddSpacer)
- KickCD:addBlock (settings/Panel.lua:460 — deleted, becomes O.AddSpacer)
- ConsumableMaster:settings/Panel.lua (10 Label+justify sites -> O.TextRow)
- BankLedger:settings/Panel.lua (3 sites -> O.TextRow)
- LootHistory:settings/Browser + settings panels (2 sites -> O.TextRow)

### Keeping the helper itself under 15

```
Four file-locals plus a four-line orchestrator; nothing approaches the limit.

  applyLabelFont(w, fontName)   CCN 4  -- the `w.label and w.label.SetFontObject and _G[name]` triple
  O.TextRow(ctx, text, opts)    CCN 5  -- scroll guard, SetText, applyLabelFont, the justify guard
  landingLogo(ctx, spec)        CCN 4  -- `if not spec.logo then return end` + the SimpleGroup block
  landingNotes(ctx, spec)       CCN 5  -- string-or-function resolve, empty-skip, one O.TextRow call
  landingSections(ctx, spec)    CCN 5  -- `for` over sections, `for` over rows(), one O.Section each
  O.BuildLandingPage(ctx, spec) CCN 4  -- AceGUI/scroll guard, spec default, four calls

The branchy part is the guard pairs, and each is now written exactly once instead of once per
widget per host. The spec table is built by the host at file scope, so nothing is allocated per
render beyond the widgets themselves — the same count as today.
```

---

## 2. LibKa0s/Slash.lua (extend LibKa0s-Slash-1.0; four lib-level functions, no instance change)

### Rationale

`findCommand` and `lowerFirst` are BYTE-IDENTICAL file-locals in KickCD/core/KickCD.lua and ConsumableMaster/core/SlashCommands.lua — same names, same bodies, same `^(%S*)%s*(.*)$` pattern, same lowercase-the-verb-only rule. That is not two addons converging by accident; it is one shape copied and now maintained twice.

Both of those repos also hand-roll the sub-help row format: `("  |cffffff00/kcd debug %s|r — |cffffffff%s|r")` and `("  |cffffff00/cm priority <cat> %s|r — |cffffffff%s|r")`. That renders identically to `"  " .. lib.FormatRow(...)` — same colours (hex case differs, which the client ignores), same em dash, same spacing. So both files already use the library's formatter for their top-level help and a private copy of it for their second level, which is precisely the drift KickCD's own comment says the convergence exists to end. Seven sub-command tables across the two repos are affected (KickCD: debug, spells; ConsumableMaster: priority, stat, aio, bar).

AbsorbTracker's runProfile (settings/Slash.lua:298, CCN 21) is the unconverged holdout — a seven-arm if/elseif doing by hand what the other two do by table. Giving it SplitVerb/FindCommand/CommandRows converts it to the shape its siblings already run, which is the real reason its CCN is high.

ParseBool is the cheapest promotion in the set because the code is ALREADY IN THIS FILE and merely unreachable. PanelMaster has a second copy (Util.ParseBool + Util.BOOL_USAGE, core/Util.lua:52-60) and ConsumableMaster has a third inlined in aioToggle (core/SlashCommands.lua:646-654) — three implementations of a closed eight-word set, one of them inside the library that defines the set in its own error string.

The row shape is stable by construction: `{ name, description, handler }` is what `lib:New`'s `commands` descriptor field has always taken, so the sub level reuses the major's existing vocabulary rather than inventing one.

### API

```
lib.SplitVerb(rest) -> verb, remainder
  `((rest or ""):match("^(%S*)%s*(.*)$"))` with the verb LOWERCASED and the remainder's case
  PRESERVED, both defaulted to "". The case asymmetry is the contract: verbs are identifiers,
  arguments are user data (AceDB profile names and schema paths are case-sensitive).

lib.FindCommand(list, name) -> entry | nil
  Linear scan of an ordered { name, description, handler } array — the SAME row shape the
  descriptor's `commands` field already takes — returning the matched triple. Compares
  `entry[1] == name` verbatim; callers lowercase through SplitVerb first, exactly as today.

lib.CommandRows(prefix, commands, indent) -> array of string
  One rendered row per entry: `indent .. lib.FormatRow(prefix .. " " .. entry[1], entry[2])`.
  `indent` defaults to "". This is the existing instance-local `rows(indent)` (Slash.lua:366-373)
  generalized off `d.slash`/`d.commands`; Sl:HelpRows and Sl:LandingRows become one-liners over it
  (`lib.CommandRows(d.slash, d.commands, "  ")` and `... , "")`), so the top level and every sub
  level render through one formatter by construction.

lib.ParseBool(word) -> true | false | nil
  Module-level constant lookup over the exact word set lib.STRINGS.ERR_BOOL already advertises:
  true/1/on/yes and false/0/off/no, case-insensitive. nil means "not a boolean word" — never
  "false" — which is what lets a caller implement toggle-on-absent. The existing file-local
  parseBool (Slash.lua:131-136) becomes `local v = lib.ParseBool(args[1]); if v == nil then
  return nil, lib.STRINGS.ERR_BOOL end; return v`.

DELIBERATELY NOT PROMOTED: the sub-dispatcher itself. See `rejected`.
```

### Consumers

- KickCD:runDebug + KickCD:findCommand + KickCD:lowerFirst (core/KickCD.lua:240-268, 670-694)
- KickCD:runSpells (core/KickCD.lua:677)
- ConsumableMaster:runPriority / runStat / runAio / runBar + findCommand + lowerFirst (core/SlashCommands.lua)
- AbsorbTracker:runProfile (settings/Slash.lua:298, CCN 21)
- PanelMaster:Util.ParseBool + Registry:Set boolean arm (core/Util.lua:60, modules/Registry.lua:668)
- ConsumableMaster:aioToggle (core/SlashCommands.lua:646)
- LibKa0s:Sl:HelpRows / Sl:LandingRows / parseBool (become wrappers over the new lib-level pair)

### Keeping the helper itself under 15

```
All four are straight-line and lib-level (stateless), matching FormatRow/FormatKV's existing shape:

  lib.SplitVerb      CCN 2  -- two `or` defaults around one match
  lib.FindCommand    CCN 3  -- type guard, loop, compare
  lib.CommandRows    CCN 3  -- indent default, type guard, loop
  lib.ParseBool      CCN 2  -- `if type(w) ~= "string" then return nil end; return BOOL_WORDS[w:lower()]`

BOOL_WORDS is a module-level constant table (eight entries, booleans only, so nil is unambiguous),
built once at file load. The instance-side change is a net REDUCTION: `rows(indent)` is deleted
and its two callers become one-liners, so lib:New's body shrinks.
```

---

## 3. LibKa0s/Core.lua (one lib-level function; NOT consumed by the library's own modules yet — see ownComplexity)

### Rationale

This one is promoted primarily because THE LIBRARY ITSELF has two copies that disagree. Slash.lua:102-105 reads both shapes (`v.r or v[1] or 0`); OptionsWidgets.lua:141 reads only the keyed shape (`c.r or 1, ...`). So LibKa0s's own CLI can render a positional colour the library's own options widget cannot decode — inside the exact area Slash.lua's comment documents as a known two-shape problem ("AbsorbTracker keeps { r =, g =, b =, a = } and the Ka0s options colour widget writes { r, g, b, a } POSITIONALLY"). One decoder ends that.

Outside the library: KickCD has Util.Unpack (core/Util.lua:22) handling both shapes with 1,1,1,1 defaults, plus safeUnpackColor wrapping it for per-call defaults (modules/IconGrid_Render.lua:48) — i.e. it independently arrived at the parametrized-default signature. ConsumableMaster has roughly nine positional sites (MacroBarButton.lua:247/274/290, MacroBarFlyout.lua:360/373/393/457, MacroBar.lua:53), and MacroBar.lua:53 is literally `t[1] or dr, t[2] or dg, t[3] or db, t[4] or da` — the proposed function, already written, for one repo.

It is a stable abstraction because the two shapes are fixed by what is already persisted in users' SavedVariables across the collection; neither can be retired without a migration, so a reader that handles both is permanent. It needs no escape hatch: four numbers in, four numbers out, no policy, no allocation — which is what makes it safe on ConsumableMaster's and KickCD's per-repaint paths.

### API

```
lib.RGBA(c, dr, dg, db, da) -> r, g, b, a
  Reads a stored colour in EITHER of the two shapes the collection actually holds and returns four
  NUMBERS, never a table:
    keyed       { r = , g = , b = , a = }   -- AbsorbTracker, KickCD, the Slash parser's output
    positional  { r,   g,   b,   a   }      -- what the Ka0s options colour widget writes
  Rules, in order:
    1. `type(c) ~= "table"` (nil included) -> the four defaults, unchanged.
    2. Any of c.r / c.g / c.b non-nil -> the KEYED shape wins for all four channels.
    3. Otherwise the positional shape.
    4. Each channel falls back INDEPENDENTLY to its default, so a three-element colour still gets
       its alpha and a `{ r = 1 }` does not silently borrow g from c[2].
  Defaults are per-channel parameters and are NOT defaulted by the library: call sites disagree
  today (Slash.FormatValue uses 0,0,0,1; OptionsWidgets.decodeColor and KickCD's Util.Unpack use
  1,1,1,1; ConsumableMaster uses a different tint per widget), and inventing a house default would
  silently recolour one of them.
  Absence is tested with `== nil`, not `or`. Value-identical for numeric channels (0 is truthy in
  Lua) and correct for a stored `false`, which `or` would swallow.
```

### Consumers

- LibKa0s:Slash.lua lib.FormatValue colour arm (Slash.lua:102-105) — behaviour-change caveat below
- LibKa0s:OptionsWidgets.lua decodeColor default (OptionsWidgets.lua:141)
- KickCD:Util.Unpack + safeUnpackColor (core/Util.lua:22, modules/IconGrid_Render.lua:48)
- KickCD:UnitLabel:Apply, Castbar:ApplyState (colour reads)
- ConsumableMaster:MacroBarButton.ApplyStyle (modules/MacroBarButton.lua:247/274/290)
- ConsumableMaster:MacroBarFlyout.bindEntry (modules/MacroBarFlyout.lua:360/373/393/457)
- ConsumableMaster:MacroBar.lua:53 (deleted outright — it is this function)

### Keeping the helper itself under 15

```
  local function pick(v, d) if v == nil then return d end return v end   -- CCN 2
  lib.RGBA                                                               -- CCN 5

RGBA is: one `type(c) ~= "table"` guard, one three-term keyed-shape test, two four-call return
statements. Replacing the eight `or` short-circuits with `pick` is what keeps it at 5 instead of
11 — each `or` is a decision to lizard, `pick` is one.

TWO ADOPTION CONSTRAINTS, both mandatory:

1. LibKa0s's OWN two call sites cannot adopt it yet. Slash.lua and Options.lua declare
   NEEDS_CORE = 1, and docs/releasing.md treats a floor raise as a breaking change to the
   VENDORING — every consumer carrying a stale Core.lua would lose the whole major. This is the
   documented reason enumList is duplicated verbatim between Slash.lua and OptionsWidgets.lua
   rather than hoisted. So: ship lib.RGBA for HOSTS now; fold the library's two copies in only
   as part of a change that raises NEEDS_CORE for its own reasons.

2. When Slash.FormatValue does adopt it, that is a real behaviour change for MALFORMED input.
   Today it mixes shapes per channel (`v.r or v[1] or 0`), so `{ r = 1, [2] = 0.5 }` yields
   g = 0.5; lib.RGBA's shape-wins rule yields g = the default. Well-formed colours of either
   shape are byte-identical. Land it with a case pinning the mixed-shape input rather than
   assuming nobody stores one.
```

---

## 4. LibKa0s/Perf.lua (two instance functions on the object lib:New returns, beside P.Note)

### Rationale

LibKa0s already owns this module, and the tax is real and measured. Three repos instrument today: KickCD (11 Note sites), AbsorbTracker (5), ConsumableMaster (2). KickCD's Cooldowns:PollSpell carries FOUR exits, each needing its own `if __t0 then P.Note("pollSpell", debugprofilestop() - __t0) end` — eight of that function's nineteen CCN is instrumentation, not logic. The function's own comment records that this instrumentation was originally OMITTED because the exits made it awkward, and that the omission then cost 73.9 ms of unattributed time in the first live capture.

That is the shape of the problem worth fixing upstream: a measurement seam whose ergonomics discourage instrumenting exactly the multi-exit functions that most need measuring. Every addon subject to the performance section of the standard hits it, and each one currently pays the branch per exit.

The semantics are uniform across all three adopters — open above the guards, close on every exit, key unchanged — with no per-addon variation to hatch out. And it preserves the invariant KickCD's tests/test_perfsetup.lua pins (the declared bucket list and the bracketed call sites must agree exactly), because the key set is untouched.

### API

```
P.Open() -> t0 | nil
  `if not P.on then return nil end; return debugprofilestop()`. Returns nil when the probe is off,
  so the caller pays one boolean test and nothing else.

P.Close(t0, key)
  `if not t0 then return end; P.Note(key, debugprofilestop() - t0)`. A nil t0 is a silent no-op,
  which is what collapses every exit to ONE unconditional statement:

    local t0 = P.Open()
    if not isPollable(id) then P.Close(t0, "pollSpell"); return nil end
    ...
    P.Close(t0, "pollSpell")
    return state

  Deliberately NOT a closure-returning `P.Bracket(key)`: a closure per bracket allocates on a
  path whose entire contract is costing nothing when disabled, and P.on is read directly by every
  call site precisely so it stays a plain boolean field on a plain table (Perf.lua:255-257).
  P.Note is unchanged, so an existing host keeps working untouched.
```

### Consumers

- KickCD:Cooldowns:PollSpell (modules/Cooldowns.lua:93-199, 4 exits)
- KickCD:core/PerfSetup.lua + the other 10 Note sites
- AbsorbTracker:core/PerfSetup.lua (5 Note sites)
- ConsumableMaster:P.Recompute (core/ConsumableMaster.lua:261) + modules/PerfSetup.lua

### Keeping the helper itself under 15

```
  P.Open   CCN 2
  P.Close  CCN 2

Two statements each. They are instance functions (P.Note closes over the instance's `buckets`
table, so these must live beside it inside lib:New, not at lib level). No allocation on either
path: Open returns a number or nil, Close returns nothing. lib:New's own CCN is unaffected —
these are two more `function P.X()` definitions in a body that is already a list of them.
```

---

## 5. testkit/mock_base.lua (the shared headless kit — NOT a shipped LibKa0s module, and must not become one)

### Rationale

This is the largest single duplication in the collection and the semantics have already converged
without coordination. Four repos independently rewrote stubFrame to record real geometry —
BankLedger/tests/wow_mock.lua (its __index is CCN 33, the worst function in that repo),
PanelMaster/tests/wow_mock.lua (CCN 21), KickCD/tests/wow_mock.lua, WhatGroup/tests/wow_mock.lua —
and two more wrap M.__stubFrame (LootHistory:139, prettychat:234). Their comments are near
verbatim across repos: "SetPoint's two overloads are both modeled because addon code uses both",
and "without a SetPoint/GetPoint round trip, 'we saved the position' and 'we applied garbage'
look identical". When four consumers override the same base default the same way, the default is
wrong, not the consumers.

The destination shape is already proven rather than speculative: KickCD has ALREADY converted its
copy to a FRAME_METHODS table of plain methods, which is exactly the refactor the CCN analysis
independently proposes for BankLedger's and PanelMaster's if/elseif chains. Promoting it kills
two CCN>15 offenders outright instead of fixing the same chain twice more.

Why plain methods rather than the closure-factory shape: the current base __index returns
`function() return f end`, allocating a fresh closure on every property miss. A table of plain
methods resolved through __index returns the SHARED function and gets `self` from the colon call —
fewer allocations and one less indirection, in code every suite in the collection runs.

This belongs in testkit/, NOT in LibKa0s/. The kit "is not a LibStub major and never ships"; a
frame stub compiled into a shipped addon would be a defect. It is in scope here only because
testkit/ lives in the LibKa0s repo and is vendored into every addon as tests/_kit/.

### API

```
M.__frameMethods -> table
  Named PascalCase methods keyed by name, PLAIN METHODS taking `self` (KickCD's proven shape),
  not closure factories. Base set grows from today's Show/Hide/SetShown/IsShown/IsVisible/
  SetScript/GetScript/HookScript/__fire/GetName/GetWidth/GetHeight/RegisterUnitEvent/
  UnregisterAllEvents to add the geometry four repos already added by hand:
    SetPoint(self, ...)      -- BOTH overloads normalized into one record appended to self.__points
    GetPoint(self, i)        -- unpacked from that record, nil when absent
    GetNumPoints(self)
    ClearAllPoints(self)     -- self.__points = {}
    SetSize/SetWidth/SetHeight  -- write self.__w / self.__h
    GetWidth/GetHeight/GetSize  -- return the RECORDED value, including 0
    SetScale(self, s) / GetScale(self)  -- GetScale defaults to 1 when never set

M.__makeStubFrame(extra) -> function() -> frame
  Returns a constructor whose metatable __index resolves:
    1. `setmetatable(extra or {}, { __index = M.__frameMethods })` — an addon's own methods win,
       and are scoped to that addon rather than mutating the shared table.
    2. else, a capitalized string key -> the shared no-op `function(self) return self end`.
    3. else nil (lowercase and non-string keys still miss, so addon code can stash custom fields).
  M.__stubFrame stays exactly as it is today (`M.__makeStubFrame()`), so nothing that calls it
  breaks.

EXPLICITLY UNCHANGED: the initial `__shown` value. The base starts frames HIDDEN; BankLedger and
PanelMaster start them SHOWN and document it as a deliberate divergence. Flipping the base would
silently invert assertions in the repos that did NOT override. It stays a host override.
```

### Consumers

- BankLedger:tests/wow_mock.lua stubFrame __index (CCN 33 — deleted)
- PanelMaster:tests/wow_mock.lua stubFrame __index (CCN 21 — deleted)
- KickCD:tests/wow_mock.lua FRAME_METHODS (becomes `extra` — its SetPoint normalizer is the base)
- WhatGroup:tests/wow_mock.lua api.SetPoint/SetSize/GetWidth/GetRight block
- LootHistory:tests/wow_mock.lua M.__stubFrame wrapper (line 139)
- prettychat:tests/wow_mock.lua M.__stubFrame = newFrame (line 234)
- AbsorbTracker, ConsumableMaster — no override today; they inherit the recorders

### Keeping the helper itself under 15

```
  __index resolver        CCN 4  -- table lookup, uppercase-string test, nil
  M.__makeStubFrame       CCN 2  -- one setmetatable over `extra or {}`
  SetPoint (base method)  CCN 4  -- the two-overload normalizer, KickCD's version verbatim
  every other method      CCN 1-2

The 33-branch and 21-branch chains become a hash lookup; no method in the table exceeds 4.

MIGRATION RISK, and it is the reason this lands last: giving the base a recording GetWidth
changes what AbsorbTracker, ConsumableMaster and prettychat see — they currently get a hard 0 and
would now get the real value. Any assertion of `GetWidth() == 0` after a SetSize flips. That is a
loud, immediate red in those suites rather than a silent drift, and tests/test_kitsync.lua already
enforces byte-identity so the re-vendor cannot be done halfway. Land it after every addon-side
refactor, on its own commit, and run all eight suites before re-vendoring.
```

---

## Deliberately not promoted

Each of these was nominated and rejected. The reasons are load-bearing — do not re-promote
one without re-reading its entry.

- SCHEMA-MIGRATION RUNNER (core.RunSchemaSteps / LibKa0s/Migrate.lua) — the most-nominated candidate, and the clearest wrong abstraction in the set. It is in 8 repos but in FIVE incompatible variants, and they disagree on exactly the things a shared runner would have to own. Who stamps: LootHistory and AbsorbTracker stamp in the RUNNER after apply; KickCD's steps stamp THEMSELVES (`[1] = function(db) ...; db.global.schemaVersion = 2 end`). When: prettychat stamps ONCE at the end, unconditionally, even when a step raised; LootHistory stamps per step, so a raise correctly leaves the account un-advanced. Failure policy: prettychat pcalls each step and prints; nobody else pcalls. Missing step: KickCD bumps-and-breaks to avoid an infinite loop; nobody else has the case. And KickCD's whole design premise is that the version stamp CANNOT BE TRUSTED under AceDB — its FoldLegacyUnits runs unconditionally and shape-driven because "AceDB's defaults merge backfills db.global.schemaVersion to CURRENT the moment db.global is first accessed, which would mask a legacy account as already-current" (the KCD-20 trap, documented three times in that one file). A shared runner would need stampOwner, pcall, stampOnFailure, onMissingStep and a shape-driven bypass — five escape hatches for an eight-line loop of CCN 4. The CCN win in LootHistory (56 -> 8) comes from moving the seven step BODIES into a local ordered table, which each addon does for itself without a library. Meanwhile the risk is a silent corruption of users' SavedVariables. Duplication is the cheaper answer here; if convergence is wanted it is a Ka0s standard ruling on stamp ownership, not a LibKa0s function.

- core.CallIf(obj, method, ...) — the optional-object/optional-method guard. By raw frequency the biggest hit in the collection (400+ matches across 9 repos, 103 in LootHistory alone) and I still reject it, for three reasons. (1) It converts a compile-time method call into a stringly-typed lookup: `core.CallIf(frame, "SetPoint", "TOPLEFT", 1, -1)` is worse to read than `frame:SetPoint(...)`, is invisible to grep-for-callers, and hides the method name from luacheck. (2) The guards exist for THREE different reasons — a Blizzard API absent on this client build (Classic/Midnight), an optional host module that may not have loaded yet, and a headless mock with holes — and each currently carries a comment saying which. One spelling erases that distinction at 400 sites. (3) It buys ~1 CCN per site and only where the body is a bare one-liner; anywhere the guard wraps two statements the `if` survives anyway. High frequency plus low semantic content is the signature of a shape that should stay inline. LibKa0s's own ApplySkin is the counter-example that proves it: it uses `type(x) == "function"` rather than truthiness, and the comment explains that a consumer's mock answering every key truthily is what broke fourteen cases on a re-vendor — a shared CallIf would have to pick one of the two guard styles and be wrong for the other.

- MULTI-SELECT FILTER DROPDOWN + the shared popup menu (MakeDropdown / EnsureMenu / menu:Populate / UpdateMultiLabel). Exactly 2 repos (BankLedger/modules/Browser.lua:248-445, LootHistory/modules/Browser.lua:220-415), ~90% identical — and already diverging in the two places that matter: BankLedger's rows carry a mono-font glyph column (the direction arrows) that LootHistory has no concept of, and LootHistory's UpdateMultiLabel has grown `isActive` preset predicates and a `^(.-):` label-prefix extraction that BankLedger's has not. Sharing means optional glyph + optional isActive + optional prefix on day one. Worse, it is raw CreateFrame widgetry for a standalone window, whereas LibKa0s-Options is an AceGUI vocabulary for the Blizzard settings canvas — promoting this puts two incompatible widget systems in one library. And neither copy has ANY headless coverage (menu:Populate is untested in both), so there is no safety net for the merge. 2 of 9 repos, actively diverging, untested, wrong layer.

- setToFilter / asSet (the filter-set converters). Byte-identical in BankLedger/modules/Browser.lua:606,764 and LootHistory/modules/Browser.lua:624,633 — the strongest raw-duplication evidence I found — and still rejected. They are six-line pure functions in 2 of 9 repos, and they are the tail of the dropdown stack I rejected above: promoting them alone leaves the 150 lines of frame plumbing duplicated, so it does not fix the actual duplication, it just adds two permanent names to Core's additive-only surface. The bug they are associated with (F-013, a captured view aliasing a live `_selected` table) lives in the CALLER, not in setToFilter, so promoting them prevents nothing.

- Query.Compile / declarative record filtering (Database:QueryList). 2 repos and NOT the same code: BankLedger uses a `matches(spec, value)` closure over a clean `and` chain; LootHistory hoists twelve `xIsSet` locals and runs sequential `if ok and ...` guards. The field sets are disjoint (kind/direction/store vs source/zone/bound), the defaults differ (LootHistory defaults zone to "" and bound to "NONE"; BankLedger has neither), and BankLedger matches on an EFFECTIVE type computed by a host function (NS.Util.EntryType) rather than a stored field. A shared matcher needs per-field accessors, per-field defaults, and four distinct field kinds (scalarOrSet, numberOrSet, setOnly, range, substring) — a small query language for two consumers, on the hottest read path in both addons.

- GroupedTable / groupOf. 2 repos, and the group MODES barely overlap (BankLedger: store, direction, kind, type, subtype, quality, char, day; LootHistory: source, zone, char, type, quality, day). The only genuinely shared thing is the collapsed-state key format `mode .. "\001" .. raw`, which is one line. A library that owns one line of string concatenation is not a library. The key format is worth recording as a convention in the Ka0s standard — it is load-bearing (changing it silently resets every user's collapsed groups) — but that is documentation, not code.

- Saved-view Capture/Apply driven by a field spec. 2 repos, and entirely coupled to the dropdown widget rejected above — every field it marshals is a `dd.X._selected`. Its two real hazards are ordering rules specific to each host (BankLedger must SetText the search box BEFORE rebuilding activeFilter because OnTextChanged fires on SetText; LootHistory must call SetCharSet last as its single refresh), and a library that owned the apply loop would own exactly the ordering it cannot know.

- LibKa0s.Diag (frame introspection for skinning diagnostics: describeTexture / dumpRegions / parent-chain walk). One repo. BankLedger/settings/Panel.lua:371 is the only implementation; PanelMaster's D:Diagnose dumps the registry and the renderer and never touches frame art. A one-addon helper.

- lib.NewDump() — the `local function add(fmt, ...) out[#out+1] = select("#", ...) > 0 and fmt:format(...) or fmt end` line collector. Byte-identical in BankLedger/modules/Ledger.lua:260, BankLedger/settings/Panel.lua:373 and PanelMaster/core/DebugLogSetup.lua:35 — but that is 2 repos and 3 lines, and LibKa0s-DebugLog has no Diagnose seam at all today, so promoting it means inventing a new seam in a shipped major to save three lines in two addons. Below the bar. Revisit if a third addon grows a Diagnose, at which point the seam (not just the collector) is the thing to design.

- core.ApplyDefaults / core.CopyFields / core.ApplyClamps — table-driven field defaulting. Nominated from three directions (WhatGroup:CaptureGroupInfo, PanelMaster:R.Sanitize, ConsumableMaster:ResetAllToDefaults) and rejected because the three want incompatible rules: PanelMaster clamps numerics into ranges and re-sanitizes on every write; WhatGroup maps source keys to differently-named destination keys with per-field defaults; ConsumableMaster deep-copies whole sub-tables. Worse, the `or` vs `== nil` question — which decides whether a stored `false` or a legitimately-empty value survives — has to be answered ONE way by a shared helper, and PanelMaster explicitly carves out three fields whose semantics differ (`enabled` is `~= false`; an EMPTY accentEdges set is a user choice; an EMPTY artCustomPath string is a user choice). A shared defaulter would normalize exactly those away, silently, in SavedVariables. Each addon should build its own module-level rule table; that is where its CCN win is anyway.

- core.EnsureTables(t, fields) — filling a fixed list of sub-tables on a saved-variables bucket. One repo (ConsumableMaster/modules/Selector.lua:45-48, 65-68). The duplication is intra-file (three places listing the same four field names) and the fix is a file-local constant array, not a library.

- core.Set(list) / core.Plural(n, s, p) / core.Count(...) — one repo each (prettychat/tests/loader.lua:79, modules/Override.lua:283). Genuine three-line idioms, genuinely local.

- core.Clamp(n, lo, hi, fallback) / core.ClampInt — only PanelMaster has a NAMED four-argument clamp with fallback semantics (core/Util.lua:17). Everyone else writes inline math.max/math.min with no fallback, and LibKa0s's own is a two-argument `clamp01` inside the colour parser. Same word, three different contracts; promoting one of them invites the other two to be quietly wrong.

- LibKa0s.Options:ValidateValue(def, value) — schema-row type validation. One repo. PanelMaster/settings/Panel.lua:576 is the only implementation of validate-an-already-typed-value; every other addon reaches the same place through lib.ParseValue, which parses FROM A STRING and already exists upstream. The two are not the same function (ParseValue tokenizes and clamps; ValidateValue type-checks and rejects), and building the second for one consumer would give the library two overlapping validators with subtly different enum handling — the exact drift the enumList parity case exists to prevent.

- Sub-verb DISPATCHER (cli:SubDispatcher(descriptor) owning the parse, the sub-help, the requiresArg guard, the lookup and the unknown-verb path). I promoted the four primitives underneath it and deliberately stopped there. The dispatcher itself would have to own control flow that is genuinely per-host: KickCD's bare `/kcd debug` TOGGLES THE CONSOLE WINDOW before printing help; ConsumableMaster's `/cm priority <cat> <verb>` resolves a category object between the two levels and passes it to every handler; both append extra context lines after the rows (known category keys, the default class/spec); AbsorbTracker's arms need per-verb `Usage:` guards. That is onEmpty + context + extraLines + requiresArg — four hooks to own a control flow each host can write in six lines with the primitives. Owning the vocabulary (rows, lookup, split, bool words) buys the anti-drift guarantee; owning the flow buys nothing and costs four hatches.

- AceDB profile sub-CLI (`/xx profile list|current|use|new|copy|delete|reset`). Only AbsorbTracker/settings/Slash.lua:298 implements it. Every other repo touches AceDB profiles only to read GetCurrentProfile for an init-summary line. One addon. It becomes a good candidate the moment a second addon grows the verb set — and by then it should be written with the Slash primitives above, which makes the eventual promotion mechanical.

- Locale-safe class + spec dropdown entries (ResolveSpecID / SpecDisplayName / ClassColorHex / SpecEntries). One repo — KickCD, driven by its issue #8 (localized spec names used as storage keys broke every non-English client). Real and well-solved, but nothing else in the collection stores per-spec configuration, and LibKa0s deliberately depends on LibStub and nothing else: importing WoW class/spec taxonomy would change what the library IS. It belongs in each addon's core/Compat.lua, which is where the collection already puts game-API knowledge.

- RAID_CLASS_COLORS class-colour lookup with the headless-nil guard, and LibKa0s.Color generally. 4 repos (BankLedger x3 + a helper, LootHistory x3 + a helper, KickCD, PanelMaster/core/Compat.lua:95), and I still reject it for LibKa0s specifically: it is a WoW-API compat seam, and every addon already has core/Compat.lua as the designated home for exactly this ("deprecated-API access routes through the single Compat shim"). Core is documented as the seams the library's OWN modules sit on — secret-safety, window chrome, the printer — none of which touch game data. lib.RGBA is promoted because the library itself has two disagreeing copies; a class-colour table has no such claim. If the collection wants one class-colour reader, the honest move is a shared Compat, and that is a Ka0s standard question about what core/Compat.lua must contain.

- LibKa0s.OptionsWidgets:IconButton / :ReorderControls — reorderable-list row controls. One repo (KickCD/settings/Spells.lua's makeRowIconBtn and the up/down/remove triple inside buildRow). Generic-LOOKING, but no second consumer exists; nothing else in the collection has a user-reorderable list. Promoting on the strength of "this could be reused" is how a library grows surface it then has to keep forever under the additive-only rule.

- OptionsScroll.PatchAlwaysShowScrollbar — already upstream (LibKa0s/OptionsScroll.lua:46). Listed here only because it was nominated as a promotion; KickCD reaches it through its own Helpers wrapper, which is the intended shape, not a duplication.

- kit.Rng(seed) / kit.Pick(rng, weighted) — the deterministic Park-Miller generator and weighted picker behind the demo datasets. 2 repos (BankLedger/modules/LedgerTable.lua, LootHistory/modules/BrowserTable.lua) and rejected on blast radius, not on shape: in BOTH repos the generated dataset is asserted byte-identical run to run, and that identity is a property of the RNG CALL SEQUENCE, not of the generator. Sharing the generator means one library edit can silently regenerate two addons' fixtures. If it is ever promoted it must ship with the sequence pinned by a golden fixture in the kit itself, and that is a bigger piece of work than the duplication costs. It is also test-only, so testkit/, never LibKa0s/.
