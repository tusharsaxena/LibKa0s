# `LibKa0s-Options-1.0` — version 18.16.5.3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Options surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Options-1.0` |
| Files and minors | `Options.lua` **18** · `OptionsWidgets.lua` **16** · `OptionsCompose.lua` **5** · `OptionsScroll.lua` **3** |
| Version key | `<Options>.<OptionsWidgets>.<OptionsCompose>.<OptionsScroll>`, in load order — the same four numbers `lib.MODULES` reports. |
| Shipped in | v1.35.0 |
| Status | **Current** |
| Supersedes | [version 18.15.5.3](./version-18.15.5.3-docs.md) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`); `OptionsWidgets.lua` additionally requires `LibKa0s-Pool-1.0` minor ≥ 1 (`NEEDS_POOL = 1`), since 14.14.3.3. `O.IdList` uses `LibKa0s-Item-1.0`'s `LoadItem` when it is present, looked up at call time; it is not a floor, and without it an uncached item stays unnamed. |
| Confirm in-game | `LibStub("LibKa0s-Options-1.0").MODULES` → `{ Options = 18, OptionsWidgets = 16, OptionsCompose = 5, OptionsScroll = 3 }` |

`Since` in the tables below names the **file and minor** in which the member first appeared — `O18`
for `Options.lua` minor 18, `W16` for `OptionsWidgets.lua` minor 16, `C5` for `OptionsCompose.lua`
minor 5, `S1` for `OptionsScroll.lua` minor 1. Minors 1 and 2 of each file were never tagged, so
`O1`/`W1`/`S1` means "present for as long as any consumer could have had this major".

## What changed at this version

**One file moves, `OptionsWidgets.lua` 15 → 16.** It adds four instance members, `O.ChoiceGrid`,
`O.ResolveId`, `O.IdInput` and `O.IdList`, all **W16**. It widens one row field: `disabledIf` is read
by every maker, and it may be a predicate as well as a path. It adds one `RenderRows` option,
`opts.disabled`. No member is removed, renamed or resignatured. The member manifest differs from
18.15.5.3's in the `OptionsWidgets` minor alone, because it lists the library table's members, and
all four additions hang off the instance `lib:New` returns. `lib.STRINGS` gains no key. The id
widgets' words are a table of their own, overridable per call (see
[the id input and the id list](#the-id-input-and-the-id-list)).

**Why.** AuraMaster's settings rework (feedback batch 5, 2026-09-13) asked for three things the
flow engine could not draw:
- a Filters page whose rows are spell categories and whose columns are *Default · Whitelist ·
  Blacklist*, one choice per row;
- rows that dim when their subject does not apply, and a whole Bars page drawn disabled over an
  icons container;
- spell lists a player adds to by id, by a shift-clicked link or by name.

Three more hosts had a hand-written id editor of their own, and they are the adopters:
ConsumableMaster's add-by-id line, and BankLedger's and LootHistory's black- and whitelists. Each
had its own edit box, its own Add button, and no name lookup.

### `disabledIf` on every maker, as a path or a predicate

Through W15 only the color picker read `row.disabledIf`, and only as a settings path. From W16 every
maker reads it: the checkbox, the slider, the dropdown (the LSM media dropdowns and a numeric enum
included), the edit box and the color picker. It is applied when the widget is built and again by
the widget's refresher, so a write that changes the answer re-dims or brightens the row on the next
`RefreshScalars`. AceGUI's own disabled state does the dimming.

| Value | Read as |
|---|---|
| a string | A settings path. Truthy means disabled. A row with no `path` reads it through its own `row.get(key)`, as at W15. |
| a function | `disabledIf(row)`, `pcall`'d. A truthy return means disabled. **A predicate that raises reads as enabled**: a raise at build would otherwise cost the whole row for the sake of its dimming. |
| `nil` | Nothing. **The widget is never touched.** |

The last row is deliberate. A row without `disabledIf`, drawn outside a disabled render, gets no
`SetDisabled` call at all, not even `SetDisabled(false)`. Five hosts disable their own widgets
after drawing them, and a refresher that re-enabled them on the next write anywhere would undo that.

The class-color companion rule does not move: a composed swatch still carries no `disabledIf`
(`options-ui-§17`, `OptionsCompose.lua`), because its alpha is read under class color.

### `RenderRows(ctx, rows, afterGroup, pairWith, opts)` — `opts.disabled`

`opts = { disabled = true }` draws every widget of the call disabled. That covers the rows, and
also the buttons an `afterGroup` or `pairWith` hook draws through `O.InlineButtonPair` or
`O.SessionCheckbox`. It exists for a page whose subject does not apply, such as a Bars page shown
over an icons container.

- **It rides on `ctx.__renderDisabled` for the call's duration only.** Each maker snapshots the flag
  when it builds and never re-reads it from the ctx. A refresher that read it live would lift a
  disabled page's dimming on the first write anywhere, and a later render's flag could reach an
  earlier page's widgets.
- **A nested call inherits it.** A `RenderRows` or `O.ChoiceGrid` drawn from inside a disabled call,
  with no `disabled` of its own, draws disabled too, because its widgets are part of the same page.
- **The outer value is restored on the way out, including on a raise.** The call's loop now runs
  inside a `pcall`, and the raise is re-raised unchanged with `error(err, 0)`. A single row was
  already guarded on its own and still is. What can escape is a raising `afterGroup` hook or a
  raising heading, as before. The value, a string's `file:line:` prefix included, is the same one.
  The only difference is the stack: a traceback now shows the re-raise site in `RenderRows`
  rather than the hook's frame. This is the same trade the 16.15.4.3 bulk bracket made.
- `opts.disabled` disables a widget inside the call and nothing more. It does not stop a host's
  own `SetDisabled(false)` from running later.

### `O.ChoiceGrid(ctx, spec)` — a matrix of radio cells

Rows that share one value list are drawn as a grid. A header line carries the column labels. Each
row then gets one line: a radio cell per column, then the row's label, with its tooltip, across the
rest of the width. See [the choice grid](#the-choice-grid) for the spec. Each cell reads and writes
through the same seam every maker uses, so a click runs `RefreshScalars` and every cell on the page
re-syncs.

- A stored value that no column carries lights **no** cell. Guessing a column would hide a stale
  value behind a choice.
- A click on the lit cell writes nothing. AceGUI toggles a radio-typed `CheckBox` off on every
  click, so the cell re-lights itself rather than writing `false`.
- Each line is guarded, as `RenderRows` guards each row: a row whose `get` raises costs that line
  and is reported, and every line after it still draws.

### `O.ResolveId`, `O.IdInput` and `O.IdList` — add by id, link or name

`O.ResolveId(kind, text, candidates)` turns typed text into an id. It is pure and needs no ctx.
`O.IdInput(ctx, parent, spec)` is one line an id is added through: an edit box, an Add button and
a status line. `O.IdList(ctx, spec)` is that line plus one line per entry. See
[the id input and the id list](#the-id-input-and-the-id-list).

- **The host owns storage.** Neither widget writes a path. They call back (`onAdd`, `onRemove`,
  `onToggle`), and the host keeps whatever stored shape it already has. ConsumableMaster, for
  example, stores a spell as a negative id.
- **Input that resolves to nothing, or to more than one id, adds nothing.** The status line says
  why, in orange, and keeps the text so the player can correct it.
- **Degraded mode.** The client APIs are read at call time and each one is guarded. With no
  `C_Spell` or `C_Item`, a number or a link still resolves and a name finds nothing. Nothing raises.

The design (X-1) named the input line `O.IdInput(ctx, spec)`. It shipped as
`O.IdInput(ctx, parent, spec)`, with `parent` defaulting to the page's scroll, so a host can draw
the line into a container of its own. ConsumableMaster's priority list does exactly that.

### What the host does

**Nothing, on the re-vendor.** A host that calls none of the four members, passes no
`opts.disabled`, and carries `disabledIf` only in the color picker's path form, which reads as it
always did, renders as it did at 18.15.5.3. A row of any other type that already carried a
`disabledIf` would start dimming, since the field was ignored there until W16. A sweep of the ten
consumers' own source (their `libs/` and `tests/` excluded) on 2026-09-13 found no row carrying one
at all, only comments explaining why a color row must not.

Adopting is per host. AuraMaster takes `ChoiceGrid`, `IdList`, `disabledIf` and `opts.disabled`.
ConsumableMaster takes `O.IdInput` alone and keeps its own rows. BankLedger and LootHistory take
`O.IdList`, with `kind = "item"`, and LootHistory also with `kind = "currency"`. A suite driving the
id widgets installs kit revision 20's `mock_ids.lua` (see
[testkit version 20](../testkit/version-20-docs.md)).

### Previously, at 18.15.5.3

**Two files move, `Options.lua` 17 → 18 and `OptionsCompose.lua` 4 → 5, and the *Reset all
settings* button's tooltip now says what the reset does.** One descriptor field is added,
`profilesPage` (**O18**). No member is added, removed, renamed or resignatured: the member manifest
differs from 17.15.4.3's in the minors alone. Three strings are added to `lib.STRINGS`.

**Why.** `options-ui-§12` makes the global reset a **profile reset** on an AceDB host, and a host says
it is one by supplying `resetProfile`. The reset puts the current profile back to its defaults and
leaves every other profile alone. The control's tooltip was one literal in `OptionsCompose.lua`,
*"Restore every setting in this addon to its default."*, whatever the reset did. For a profile
reset that overstates the blast radius, and §12 says the tooltip **SHOULD** name the equivalence
instead: *"the same thing Profiles → Reset Profile does"*. A host could not fix it, because the
composer is the only writer of the reset's text (`options-ui-§15`), which is the reason
`leadButton` exists.

The wording now follows the descriptor:

| Descriptor | Tooltip | `lib.STRINGS` key |
|---|---|---|
| no `resetProfile` (`profilesPage` ignored) | Restore every setting in this addon to its default. | `RESET_ALL_TIP` |
| `resetProfile` | Reset the current profile to its defaults. Your other profiles are not affected. | `RESET_ALL_TIP_PROFILE` |
| `resetProfile` and `profilesPage = true` | Reset the current profile to its defaults — the same thing Profiles → Reset Profile does. Your other profiles are not affected. | `RESET_ALL_TIP_PROFILES_PAGE` |

The first row is 17.15.4.3's text, byte for byte. "Supplied" means `type(d.resetProfile) ==
"function"`, the same test `RestoreAllDefaults` uses to decide it is doing a profile reset, so the
tooltip and the act cannot disagree about which kind of reset this is.

**Why a field.** The library cannot see which pages a host registers: a Profiles page is AceConfig's
`AceDBOptions-3.0` table in a host's own file, not something built through this major. So the host
declares it. `profilesPage` is read by `MasterControls` alone, and changes nothing but that tooltip.

**How.** `lib:New` hands its descriptor to `lib.__AttachCompose(O, d)`, where 17.15.4.3 passed `O`
alone. `MasterControls` reads `resetProfile` and `profilesPage` when it is called, which is when a
host's page file declares its General page: after `lib:New`. The rows, the buttons, their order and
their handlers do not move, and `tests/test_options_compose.lua` pins that across all three
descriptor shapes. A shell older than O18 passes no descriptor; the composer reads that as no
`resetProfile` and keeps the first row's text.

The strings live in `lib.STRINGS` beside the shell's other user-visible text. The em dash and the
arrow are byte escapes in the source, for the reason `COMBAT_REFUSED`'s em dash is.

### What the host does

- **A Profiles page and `resetProfile`:** add `profilesPage = true` to the `lib:New` descriptor.
  Without it the tooltip takes the second row, which is correct but does not point at the page.
- **`resetProfile` and no Profiles page:** nothing. The tooltip moves to the second row on the
  re-vendor.
- **No `resetProfile`:** nothing changes, whether or not a Profiles page exists. Such a host's reset
  is its own act or a walk of every row, and the library cannot tell which. A host that ships a
  Profiles page and resets through its own handler is a candidate for `resetProfile` first
  (`options-ui-§12`); the tooltip follows from that.
- **A host that attaches the composers itself**, calling `lib.__AttachCompose(C)` onto a table of
  its own rather than composing on the instance `lib:New` returns: the `lib:New` descriptor never
  reaches that table, so the tooltip keeps the first row whatever it says. Pass a compose
  descriptor as the second argument instead. The composer reads nothing off it but `resetProfile`
  and `profilesPage`, and only for this tooltip, so `{ profilesPage = true, resetProfile =
  <forwarder> }` is enough, with the forwarder calling the real descriptor's `resetProfile` at call
  time rather than restating it. MultiMeters is that host (`settings/Schema_Compose.lua`). *Added
  after the tag, 2026-09-13; no code changed.*

### Previously, at 17.15.4.3

**One file moves, `Options.lua` 16 → 17, and it loads every LibSharedMedia font the first time a
Ka0s settings panel is shown.** No member is added, removed, renamed or resignatured, and no
descriptor field is added: the member manifest differs from 16.15.4.3's in the `Options` minor
alone, and the preload reads the `getLSM` the descriptor already carries. One library-level member
arrives, `lib.__PreloadFonts(LSM)`. It is `__`-prefixed, so it is outside the manifest, and no host
calls it; see [The library surface](#the-library-surface). The same minor corrects three source
docstrings on the bulk bracket's `count`. That is a comment change, and the contract below already
said it.

**Why.** Reported by the owner against every Ka0s addon: the first time a font dropdown opens in a
session, many of its rows are blank, and the second time every row draws. The dropdown is
AceGUI-3.0-SharedMediaWidgets' `LSM30_Font`, the `dialogControl` `O.FontGroup` writes. It builds its
pull-out list when it opens, running `f.text:SetFont(font, size, outline); f.text:SetText(k)` for
every registered face (`FontWidget.lua`, `ToggleDrop`). The client loads a font file the first time
something references it, and text set with a face that is not loaded yet draws blank until
something sets it again. The blank rows are exactly the faces nothing had used yet that session,
which in practice means third-party LSM faces; the ones the client had already loaded (Blizzard's
2002, AR Hei and the like) drew fine. The widget is an upstream vendored library and is not edited.
What the library can do is make sure every face is loaded before a dropdown can be opened, and a
dropdown can only be opened from a panel that has been shown.

#### When it runs

| Trigger | Covers | In combat |
|---|---|---|
| `O.SetRenderer`'s OnShow, after the combat refusal and before the render check | Every page with a renderer, and the main page when `buildMain` is set | Skipped. The refusal has just closed the window, so no dropdown can open on that show. |
| An OnShow hook `O.CreatePanel` installs on every panel | A page that never goes through `SetRenderer`, including the main page without `buildMain` | Runs. That page has no refusal, so if it is on screen its dropdowns can be opened. |

**Never at load or at `PLAYER_LOGIN`.** Loading every face costs memory, and some of Blizzard's CJK
faces are large. A player who never opens settings must not pay for it. Opening a font dropdown
loads every face anyway, so a player who does open settings pays nothing extra, only earlier.

**Why the two triggers.** `SetRenderer` is the seam every page in the collection draws through, and
the main page takes it when `buildMain` is set. A page without a renderer is still supported: the
refresh tiers keep a migration seam for it, and `RenderRows` / `RenderField` are public, so such a
page can hold an `LSM30_Font` row the library never sees drawn. `CreatePanel` is the one call every
page passes through, so the hook goes there. `SetRenderer`'s `SetScript` replaces that hook, which
is why its own handler calls the preload itself. A host that `SetScript`s its own OnShow onto a
renderer-less page replaces the hook as well. No consumer did, in the sweep taken for this release.

**Why skip it in combat on the renderer path.** Creating FontStrings is not protected, so this is a
cost decision rather than a taint one. Loading every face is a disk hitch, the middle of a fight is
the worst time for one, and the show being refused cannot open a dropdown. The next show outside
combat is the first one on which a dropdown can be opened, and it preloads before anything is drawn.

**On every show, not only the first.** After the first, the call walks LSM's font table and loads
nothing. It also retries a show that found no LSM or no `CreateFrame`.

#### What it does

- **One frame for the whole session**, parented to `UIParent`, shown, at full alpha, 1x1 and parked
  off the left edge of the screen. It is not hidden and not alpha 0, because the client may skip work
  for a region it will not draw. It is not parented to a page, because a page's hide would hide it.
- **One FontString per distinct font path**, not per LSM key, since several keys can name one file:
  `fs:SetFont(path, 12, "")` then `fs:SetText("Aa")`, `pcall`'d together. A `SetFont` that fails
  without raising leaves a string whose `SetText` raises instead.
- **A path is marked before it is tried**, so a face the client refuses is tried once rather than on
  every show, and costs that face alone.
- **Faces registered later are loaded as they register.** After the first preload the library
  subscribes once to LSM's `LibSharedMedia_Registered` callback, and a `font` registration re-runs
  the preload, which loads only the new path. A player who never opens settings is never
  subscribed.
- **Nothing is reported.** No LSM, an LSM without `HashTable`, a `getLSM` that raises, no
  `CreateFrame`, a face the client refuses: each costs the preload and never the page, and none of
  them is the page's fault. With no `CreateFrame`, nothing is marked, and the next show tries again.

**The state is library-level**, on `lib.__fontPreload`, and so is the subscription. Every host's
`lib:New` shares it, and a LibStub minor upgrade keeps it, because every vendored copy in the
session is handed the same `lib`. A client running several Ka0s addons loads each face once.
Both callers, an instance's trigger and the LSM callback, look `lib.__PreloadFonts` up on `lib`
at call time, so after an upgrade the newest copy's code is what runs.

#### What the host does

**Nothing.** A host that passes `getLSM` gets the preload on re-vendor. A host that does not pass it
gets none, and it has no LSM-backed values either, because `O.LSMValues` reads the same field.

**WhatGroup** wraps `SetRenderer` and `EnsureDefaultsButton` so that the page body and the Defaults
button build one frame after OnShow rather than inside it. The preload runs in the library's own
OnShow, so under that wrapper it still runs synchronously, on the first show. It creates one plain
frame and its FontStrings and no AceGUI widget. WhatGroup's `tests/test_panel.lua` pins that no AceGUI
widget is created synchronously on OnShow, and that stays true. Its GameMenu Logout taint smoke test
is still the check to run after the re-vendor.

#### The `count` docstrings

Three source docstrings in `Options.lua`, all on the bulk bracket, still described `count` as "the
rows actually written". They were the descriptor's `bulkEnd` entry, `runBulk`'s, and
`RestoreAllDefaults`'. The descriptor entry also told the host to emit its line with "N = count".
This document and 16.15.4.3's were corrected after the v1.32.0 tag. The source now says the same:
`count` is the number of rows the walk called `applyDefault` for and that returned, including a row
already at its default. It is therefore **not** `debug-logging-§10`'s N, which the host tallies
itself. No behavior changed.

### Previously, at 16.15.4.3

**One file moves, `Options.lua` 15 → 16, and it gives the two reset walks an optional bulk
bracket.** No member is added, removed, renamed or resignatured — the member manifest differs from
15.15.4.3's in the `Options` minor alone. What is added is two optional descriptor fields,
`bulkBegin` and `bulkEnd`, which `RestoreDefaults` and `RestoreAllDefaults` call around their walks.
A host that supplies neither runs exactly minor 15's walk: the same calls in the same order, and no
`pcall` anywhere on the path.

**Why.** On 2026-09-12 the owner ruled, and the standard codified at v2.44.0 in
`debug-logging-§10`, that a **bulk copy or reset through the settings helper is logged as ONE
`debug-logging-§8` flow line** naming the act, its scope and the row count — for example
`[Set] reset General page: 14 rows` — and **MUST NOT** emit a per-row `[Set]` line. Validation and
each row's `onChange` still run per row. Most Ka0s addons' Defaults buttons go through
`RestoreDefaults`, and their global reset through `RestoreAllDefaults`. Both walk rows and call the
descriptor's `applyDefault` per row, and the host's write seam logs one `[Set]` per call, so until
this minor every Defaults press was N lines and the host had no way to tell a reset from N single
writes. The library knows when the act starts and ends; the bracket tells the host.

#### The two fields

| Field | Signature | Called |
|---|---|---|
| `bulkBegin` | `function(act, scope)` | Once, before the act writes its first row. |
| `bulkEnd` | `function(act, scope, count, err, info)` | Once, after the act — **always**, whenever the bracket was begun. |

`info` is a table, `{ profileReset = <boolean> }`, and it is never `nil` when `bulkEnd` is called.

| Walk | `act` | `scope` | What the bracket spans | `count` | `info.profileReset` |
|---|---|---|---|---|---|
| `O.RestoreDefaults(pageKey, ctx)` | `"reset"` | `pageKey`, as passed | the page's row walk | rows whose `applyDefault` returned | always `false` |
| `O.RestoreAllDefaults()` | `"reset"` | `"all"` | the row walk, then `resetProfile`, then `afterRestoreAll` | rows whose `applyDefault` returned — with `resetProfile` supplied, the `sessionOnly` rows alone, because the profile is reset whole | `true` when `resetProfile` was called **and returned**; otherwise `false` |

**`count` is not the N a host logs.** It counts the rows the library handed to `applyDefault` and
that returned. That includes a row whose value was **already at its default**, which the host
stored again, unchanged. `debug-logging-§10` (standard v2.44.0, 7883278) makes N "the number of
rows the act actually wrote", and a row already at its default is not one. The library cannot
tell the difference, because only the host's write seam sees the old value. The host computes N
itself, as the worked example below does: while the bracket is open, its muted seam tallies the
writes that change a stored value. `count` is an upper bound on that tally and is useful for
diagnostics, but it is not the logged figure.

The refresh (`ctx.refreshers` for a page, `RefreshAllPanels` for all) runs **after** `bulkEnd`,
outside the bracket: it writes nothing. `resetProfile` and `afterRestoreAll` run **inside** it, so
the `sessionOnly` rows the library writes one by one before the profile reset, and any write a
hook makes through the host's seam, stay under the mute.

**The fields are independently optional, but a mute needs both.** A host may supply `bulkEnd`
alone, to observe acts without muting anything. **A host that mutes its seam in `bulkBegin` MUST
also supply `bulkEnd`.** `bulkEnd` is the only place the mute is released. A `bulkBegin` with no
`bulkEnd` leaves the seam silent for the rest of the session, and the library cannot detect that.

#### What the host logs — the contract

`debug-logging-§10` (standard v2.44.0, the owner's final ruling) fixes the line, and `info` is how
the host knows which case it is in:

- **`info.profileReset` is `true`: the host MUST NOT emit a bulk line.** The act included a
  whole-profile reset. AceDB replaced the profile (`db:ResetProfile()`), and §10 logs that
  **once**, by the host's profile-event handler — `[Set] reset profile 'Default' to defaults
  (N rows)` — and forbids any bulk bracket from adding a second line. The host still releases its
  mute. Because the session rows were written under that mute, a Restore All on a profile-reset
  host reads as exactly one line, the handler's.
- **Otherwise the host emits exactly one line, `[Set] reset <scope>: N rows`**, once, when the
  outermost bracket closes (see [the nesting rule](#brackets-nest-and-the-host-logs-once-for-the-outermost)).
  The tag **MUST** be `[Set]`. `N` is the rows the act **actually wrote** — the host's own tally of
  writes that changed a stored value — never the rows in its scope and never `count`. A page reset
  that walked 14 rows, 9 of them off their default, reads `[Set] reset general: 9 rows`.
- **A `resetProfile` that raised leaves `profileReset` false.** The reset may never have reached the
  profile-event handler, so the host logs its line and `err` says why.

#### Call order and error semantics

```
bulkBegin(act, scope)        -- inside the protected region
  applyDefault(row) × N      -- stops at the first row that raises, exactly as unbracketed
  resetProfile()             -- RestoreAllDefaults only, when supplied;
                             --   info.profileReset = true once it returns
  afterRestoreAll()          -- RestoreAllDefaults only, when supplied
bulkEnd(act, scope, count, err, info)   -- ALWAYS, once; err is nil unless something above raised
error(err, 0)                -- only if something raised: the same value, re-raised unchanged
refresh                      -- only if nothing raised, as before
```

- **A begun bracket always closes, so a host's mute cannot stick.** `bulkBegin` and the whole act
  run inside one `pcall`. Whatever raises — a row, `resetProfile`, `afterRestoreAll`, or
  `bulkBegin` itself after setting its mute flag — `bulkEnd` still runs, once.
- **A raise of `nil` or `false` reaches `bulkEnd` as `err = nil`.** A known limitation. `pcall`
  returns the raised value itself, so `error(nil)` or `error(false)` inside the bracket arrives
  looking like success. `bulkEnd` still runs once, and the library still re-raises the same value
  afterwards, so the act still fails for its caller. But a host that decides from `err` alone
  cannot tell, and `count` is then a partial figure. Nothing in this library or the collection
  raises either value. A host that must know should not raise them.
- **`count` is rows whose `applyDefault` returned** — including a row already at its default, which
  is why it is not §10's N (see [the two fields](#the-two-fields)). A vetoed
  row, a row the `resetProfile` narrowing skips and the row that raised are not counted.
- **The error is not swallowed and not re-wrapped.** `bulkEnd` receives the raised value as `err`,
  then the library re-raises that same value with `error(err, 0)`, so a string keeps its original
  `file:line:` prefix and a table error is the same table. The refresh does not run, which is what
  a raising row has always meant. What changes under a bracket is the stack: the error is re-raised
  from the library, so a traceback shows the re-raise site rather than the row's frame.
- **A `bulkEnd` that raises propagates its own error.** It was handed the original first, as `err`.
- **Unbracketed — neither field a function — nothing above applies.** The walk runs bare, a raising
  row escapes with its own stack, and the call sequence is minor 15's. Pinned by
  `tests/test_options_bulk.lua`, which compares the call sequence and checks the traceback still
  holds the row's frame.

#### Brackets nest, and the host logs once, for the outermost

A bracket can open inside another one, and each level calls `bulkEnd`:

- a host's `afterRestoreAll` that calls `RestoreDefaults` for a page — an Options bracket inside an
  Options bracket;
- a profile-event handler that calls `RestoreDefaults` while `resetProfile` is running;
- a Slash `CliResetAll` reached from inside an Options bracket, or a host's own bulk act that calls
  either.

A host that logged from every `bulkEnd` would log each of those twice or more. A depth counter on
its own does not prevent that: it unmutes at the right time, but each level still emits its line.
So the host keeps **one** record per outermost act. It sums the changed-write tally across every
level, logs **only when the depth returns to 0**, and stays **silent if any level reported
`info.profileReset`**. The outermost act's `act` and `scope` name the line. A host that brackets
an act of its own calls the same two functions itself, so its act is the outer one.

#### Worked example: tally the writes, log once — or not at all

The shape `debug-logging-§10` asks for, on a host whose single write seam logs every write and whose
`NS.Debug(tag, fmt, …)` prints `[tag] …`. The pair is built once, because the Slash descriptor takes
the same two fields.

```lua
-- settings/Schema.lua — the host's single write seam, and the host half of the bulk bracket
local bulk = { depth = 0, changed = 0, profileReset = false }

function NS.Set(path, value)
  local old = NS.GetStored(path)
  -- … validate, store, fire the row's onChange — all still per row …
  if bulk.depth > 0 then
    -- Muted. Tally only a write that CHANGED the stored value: a row already at its default
    -- was not written in §10's sense and is not counted. (Compare colors by channel.)
    if not NS.ValuesEqual(old, value) then bulk.changed = bulk.changed + 1 end
  else
    NS.Debug("Set", "%s = %s", path, NS.FormatSchemaValue(path, value))
  end
end

NS.Bulk = {
  begin = function(act, scope)
    if bulk.depth == 0 then                         -- the OUTERMOST act opens the record
      bulk.act, bulk.scope, bulk.changed, bulk.profileReset = act, scope, 0, false
    end
    bulk.depth = bulk.depth + 1                     -- the mute: NS.Set checks depth > 0
  end,
  finish = function(act, scope, count, err, info)  -- count is NOT N: see the table above
    if info.profileReset then bulk.profileReset = true end   -- sticky across levels
    bulk.depth = bulk.depth - 1
    if bulk.depth > 0 then return end               -- an inner level: the outermost logs
    -- A whole-profile reset anywhere in the act is logged once, by OnProfileReset. Add nothing.
    if bulk.profileReset then return end
    NS.Debug("Set", "%s %s: %d rows", bulk.act, tostring(bulk.scope), bulk.changed)
  end,
}

-- core/Database.lua — the profile-event handler: a profile reset's one line
function NS:OnProfileReset(_, db)
  NS.Debug("Set", "reset profile '%s' to defaults (%d rows)", db:GetCurrentProfile(), NS.SchemaRowCount())
end

-- settings/OptionsSetup.lua — the Options descriptor
NS.Helpers = O:New({
  -- … parentTitle, mainPanelName, get, set, applyDefault, rowsForPage, allRows …
  resetProfile = function() NS.db:ResetProfile() end,
  bulkBegin    = NS.Bulk.begin,
  bulkEnd      = NS.Bulk.finish,
})
```

What the console shows, case by case:

| Act | Lines logged |
|---|---|
| The General page's Defaults button — `RestoreDefaults("general", ctx)` walks 14 rows (`count` 14), 9 of them off their default | `[Set] reset general: 9 rows` |
| Restore All on this host — `resetProfile` supplied, so `info.profileReset` is `true` | `[Set] reset profile 'Default' to defaults (31 rows)`, from `OnProfileReset`, and **nothing** from `bulkEnd`. The two `sessionOnly` rows written first were muted. |
| Restore All on a host with **no** `resetProfile` — 31 unvetoed rows walked (`count` 31), 12 of them off their default | `[Set] reset all: 12 rows` |
| `/<slash> resetall` through Slash minor 8, handed the same pair | `[Set] reset all: <rows changed>` — `info.profileReset` is always `false` there |
| Restore All whose `afterRestoreAll` calls `RestoreDefaults("bars", ctx)` — a bracket inside a bracket | One line, when the outer bracket closes. The inner level's changed writes add to the same tally, and its `bulkEnd` returns at depth 1. With `resetProfile` supplied, no line at all: the outer level's `profileReset` makes the whole act silent. |

Before this minor each of those was one `[Set]` line per row.

**What the tests pin, and what they do not.** `tests/test_options_bulk.lua` pins the library's
half of the contract: the call order, `count`, `info.profileReset` in each case, the error paths,
and the unbracketed walk. It also runs a simplified host, a per-write mute and a `bulkEnd` that
is silent on `profileReset`, to show the two logging cases end to end. It does **not** run the
changed-write tally or the nesting rule above. Those live in the host, and each adopting host
tests them in its own suite.

#### What the bracket does not do

- It does not batch the writes or defer `onChange`. Every row is still written through
  `applyDefault`, one at a time, in the same order. Only the host's log collapses.
- It does not bracket a host's own bulk acts (a copy from one unit to another, a section reset the
  host writes itself). Those are the host's to bracket in its own seam; `debug-logging-§10` binds
  them the same way.
- No other loop in this library resets or copies rows through the descriptor. `OptionsCompose.lua`
  composes rows and writes none; `MasterControls`' two reset buttons call the host's own
  `onResetAll` / `onResetPosition`; `PerfPanel.lua` and `OptionsWidgets.lua` write one row per user
  gesture.

### Previously, at 15.15.4.3

**Two files move, `OptionsWidgets.lua` 14 → 15 and `OptionsCompose.lua` 3 → 4, and together they add
a record-backed arm to the composers.** No member is added, removed, renamed or resignatured — the
member manifest differs from 15.14.3.3's in its version key alone. What is added is one spec field,
`bind`, on every composer, and two row fields the flow engine reads, `get` and `set`, on a row with
no `path`. A host that passes neither renders byte-identically to 15.14.3.3.

It exists for [PanelMaster#48](https://github.com/tusharsaxena/PanelMaster/issues/48), finding
`PANELMASTER-A-03` under `options-ui-§16`. `O.BorderGroup` and `O.BarGroup` emitted **path-keyed**
schema rows, and PanelMaster's panel editor edits **registry records** — a panel is a record with an
id, not a settings path — so its three canonical groups (the panel's border, the accent bar, and the
accent bar's own border) were typed out by hand in `settings/PanelEditor.lua` and ratified as three
register rows whose re-check trigger was exactly this arm. The rows, their order and their shapes are
still the composer's; the arm changes only where a value is read from and written to.

#### `OptionsCompose.lua` minor 4 — `spec.bind`

```lua
spec.bind = {
  set    = function(field, value, row) end,   -- required: the record's single write seam
  get    = function(field, row) return v end, -- read the LIVE record
  record = function() return rec end,         -- or this instead of get: get becomes record()[field]
}
```

Under `spec.bind` every composed row carries **no `path`**. It carries `field` — the record key,
computed exactly as its path would have been, so `prefix` and `keys` rename a record field the way
they rename a leaf — and `get()` / `set(value)` closures over the bind. Everything else on the row is
unchanged: the leaves, their order, the labels and defaults, `startsLine`, the class-color stamps, the
media rows' `values`. `extra` rows follow the same rule: under `bind`, an extra declares its record
`field` in full and is bound like a canonical row; an extra that declares a `path`, or brings its own
`get`/`set`, is left exactly as given.

A bind that cannot both read and write is **refused when the block is composed** — no `set`, or
neither `get` nor `record` — because a bound control with nowhere to write is a dead control that
looks alive.

**Bound rows are not settings.** They have no path, so the CLI cannot address them and
`RestoreDefaults` cannot reset them, and they must never be put in the host's schema. Render them
directly: `O.RenderField(ctx, row, parent, relWidth)` into the host's own container, or
`O.RenderRows(ctx, rows)` over the returned list. Resetting a record stays the host's operation, as
it always was.

#### `OptionsWidgets.lua` minor 15 — a row with no path reads and writes through its own `get` / `set`

Every maker used to read `d.get(row.path)` and write `d.set(row.path, value)`. From W15 a row whose
`path` is nil and which carries a `get` function is read with `row.get()`, and one carrying a `set`
function is written with `row.set(value)` — the checkbox, slider, dropdown, edit box and color picker
alike, the color picker's throttled and confirmed commits included. The refreshers read the same way,
so a write that lands on the record from anywhere else repaints the control on the next
`RefreshScalars`, exactly as a settings row repaints.

**The gate is `path == nil`, not "has a get".** A row that has a path goes through the descriptor
exactly as before, whatever other fields a host's schema happens to give it, so no path-keyed row
anywhere in the collection can change behavior because of this minor. The color codec is still the
descriptor's (`colorDecode` / `colorEncode`): a bind over a record that stores colors in another
shape converts in its own `get` and `set`, which receive the row and can test `row.type`.

`lib.STRINGS.EMPTY_DROPDOWN` names a bound row by its `field`; for a path row it names the path, as
before. Two other path-keyed lookups follow the row: `RenderRows`' `pairWith` is keyed by
`row.path or row.field`, so a bound row takes its partner under its field, and a path-less row's
`disabledIf` is read with `row.get(key)` — for a composed row, that field of the same record — rather
than as a settings path. A composed row's `get` takes that optional key for exactly this reason.

#### What the arm does not change

- **Path-keyed output is byte-for-byte what compose minor 3 emitted.** `tests/fixture_compose_golden.lua`
  holds ten composer calls serialized from OptionsCompose.lua minor 3 — every spec field the common
  spec documents and every composer-specific one — and `tests/test_options_compose.lua` compares the
  current output against it on every run.
- **Nothing reads `bind` outside `emit` and `appendExtra`.** `MasterControls` takes it like any other
  composer (its `debugConsole` row's verbatim path becomes that row's `field`), but its closing button
  pair is not a row and is not bound.
- **The composers still create no widget and touch no AceGUI.** A bound row's closures read state only
  when the flow engine calls them.

#### Adopting it

Re-vendoring changes nothing for a host that passes no `bind`. PanelMaster adopts by composing its
three blocks with a bind over `NS.Registry` — see [the worked example](#worked-example-panelmasters-three-groups)
— and retiring the three `options-ui-§16` register rows in its `docs/ARCHITECTURE.md` in the same
change. That adoption is PanelMaster's step; nothing in this release makes it.

### Previously, at 15.14.3.3

**`Options.lua` minor 15 — the library registers the `LSM30_Border` fixup, because AceGUI's widget
registry belongs to the process and not to any one addon.** One file moved; everything else in this
major is unchanged from 14.14.3.3. **One member is added and nothing is removed, renamed or
resignatured** — but unlike the last two versions this one is not adopted by re-vendoring alone: the
five addons that carry a private copy of this patch have a call site to add and a file to delete.

`AceGUI:RegisterWidgetType(name, ctor, version)` writes into `AceGUI.WidgetRegistry`, which is **one
table shared by every addon loaded in the client**, Ka0s or not, and the highest version registered
for a name wins for the rest of the session. Five addons in this collection each shipped a private
`core/LSMPatch.lua` doing exactly that to `LSM30_Border` — AbsorbTracker, ConsumableMaster, KickCD,
MultiMeters and PanelMaster, five distinct files with one intent — to collapse the 42x42
`displayButton` preview tile that upstream AceGUI-3.0-SharedMediaWidgets pins to the widget's
TOPLEFT, and which leaves the closed dropdown sitting 42px right of every slider and checkbox stacked
with it on a canvas-layout settings page.

Read one at a time each of those is defensible. Read together they are a different object: every
wrapper closes over whatever the registry held when its `PLAYER_LOGIN` fired, so with all five loaded
the last addon to log in wraps the fourth, which wraps the third — the same work done five times,
five constructors deep, with the outermost one belonging to **whichever addon the client happened to
load last**. And the registration is the *session's*: the next Border dropdown anything opens is
drawn by a Ka0s wrapper it never asked for. No addon's own suite could see any of it, because each
one loads a single copy, registers once and passes.

`library-stack-§9` now states the rule — a re-registration of a widget type the addon did not itself
define is `LibKa0s`'s, published as a member of the owning major, and never done from an addon's
`core/`, `modules/` or `settings/` — and anti-pattern #76 names the tell. This version is the surface
that rule points at. It belongs to the Options major on the evidence: `OptionsCompose.lua` is what
writes `dialogControl = "LSM30_Border"` in the first place, and the panel descriptor already takes
`getLSM()`.

#### `lib.__PatchLSM30Border()` — library-level, and idempotent behind a sentinel

It is on **`lib`**, not on the instance, and that placement is the contract rather than a convenience.
A per-instance member would be called once per host, so five hosts in one client would be five
registrations deep again — a smaller version of the defect is still the defect — and a sentinel on
`O` could not stop it either, because every host has its own `O`.

`lib.__lsmBorderPatched` is that sentinel, and it lives on the library table because LibStub hands
**every vendored copy in the session the same `lib`**. N copies calling this therefore produce
exactly one registration, and the count is independent of how many Ka0s addons are installed and in
what order they load. That is the property `library-stack-§9` asks for by name.

The sentinel records that a registration **happened**, not that the function was called. AGSMW is a
separate addon, so a host calling this before that library has run finds nothing to wrap, registers
nothing and leaves the surface armed for the next call. Setting the flag on either early return would
disarm the patch for the whole session, silently, in exactly the load order it exists to survive.

The per-instance work inside the wrapper is unchanged from what the five private copies did: hide
`frame.displayButton`, re-anchor `frame.label` to the frame's own two top corners, and put
`frame.DLeft` — the left cap of the dropdown bar, which upstream moves to the tile's BOTTOMRIGHT —
back on `GetBaseFrame`'s own numbers. `LSM30_Font` and `LSM30_Statusbar` take `AGSMW:GetBaseFrame`,
which has no `displayButton`, so this is Border-specific, and the popup's per-row hover preview is
untouched.

#### Adopting it

**The re-vendor alone changes nothing.** Nothing in this library calls the new member; a host that
never calls it is byte-identical in behavior to 14.14.3.3.

For the five addons carrying a private copy the sequence matters, because the failure mode is a
function of load order and no headless suite can see it. Re-vendor and add the call from the live arm
of `settings/OptionsSetup.lua`, **leaving every local `core/LSMPatch.lua` in place**; confirm in the
client with all five loaded together that each addon's Border dropdown draws the same styled control
whatever the load order; and only then delete the five copies, **one repository per commit**, testing
again after the first. Deleting them together leaves no bisect point if the sentinel is wrong.
AbsorbTracker's copy goes last: it is the one real divergence, exposing a callable
`NS.ApplyLSMBorderPatch()` invoked from its own core file rather than installing a `PLAYER_LOGIN`
frame.

**Registering a NEW widget type an addon defines for itself is untouched by any of this.** A name
nothing else in the process claims collides with nobody, and `library-stack-§5`'s extend-don't-fork
sanction applies to it unchanged. And where the wanted change is genuinely per-instance, an addon may
still make it at its own creation site on the widget it just acquired, and leave the registry alone.

### Previously, at 14.14.3.3

**`OptionsWidgets.lua` minor 14 — the tab strip borrows its frames from `LibKa0s-Pool-1.0` instead
of building them on every click.** One file moved; everything else in this major is unchanged from
14.13.3.3. **No member is added, removed or renamed, and no signature moves** — this is a change of
lifetime, not of behaviour, and a host adopting it changes nothing.

`TabStrip` releases the strip and redraws it on **every** click of it. Through 14.13.3.3 that redraw
called `CreateFrame` once per tab plus once for the content panel, while the release only `Hide()`d
and `SetParent(nil)`d. WoW never destroys a frame, so an options panel left open leaked one full set
of tab buttons plus one content panel per click, for the life of the session. Nothing reported it and
nothing looked wrong: the panel drew correctly every time, and the only symptom was a client that got
heavier the longer settings stayed open — the same shape as the pool leak `LibKa0s-Pool-1.0`'s own
header describes, in the one repository that publishes that pool and had not used it.

At this version each `ctx` carries two pools of its own and the strip acquires from them:

```lua
ctx.__tabPool    -- the tab buttons,   Pool.New()
ctx.__panelPool  -- the content panel, Pool.New()
```

`makeTab` splits in two. `newTabButton(parent)` is the pool's factory and builds only what a
selection cannot change — the `Button`, its six textures and its `FontString`. `dressTab(b, tab,
active, onSelect)` applies everything that *is* per-tab: the label and its measured width, the atlas
family, the backing height, which glow is lit, the enabled state, the tooltip strings, and
**`OnClick`, re-set on every dress**, because the handler closes over that dress's `active` and
`tab.key` and a button carrying the previous dress's closure would select the wrong tab.

The tooltip moved off `O.AttachTooltip` for this widget alone, and for one reason: a raw `Button` has
no AceGUI `SetCallback`, so it takes that function's `HookScript` arm — and `HookScript` accumulates.
A pooled button re-dressed per click would grow a pair of handlers per click, which is the same
unbounded growth in scripts that this minor removes in frames. The strip now sets one `SetScript`
pair at construction that reads the current tab's strings off the button, so a tab re-dressed as one
that has **no** tooltip actually loses the one it had. `O.AttachTooltip` itself is unchanged and every
other widget in the file still uses it.

**`SubTabStrip` is deliberately not pooled**, and the asymmetry is the parent. A secondary strip hangs
off a frame the *host* added as an AceGUI child, and `ClearScroll`'s `ReleaseChildren` gives that
frame back to AceGUI's own pool — so its buttons must be unparented on release, and an unparented
button coming back off a free list is a button drawn onto nothing. It calls `newTabButton` +
`dressTab` in sequence, which is exactly what `makeTab` did, and keeps its own `ctx.__subTabKids`
ledger released the way it always was.

#### `ctx.__tabKids` is still the ledger, and no longer the release

`__tabKids` continues to hold this render's furniture in draw order — every tab button, then the
content panel — and `__releaseChrome` still empties it. What changed is that emptying it no longer
*is* the release: the pools hand the frames back, hidden and still parented to `ctx.chrome`, and the
ledger is rebuilt from scratch by the next render. A suite reading `#ctx.__tabKids` or
`ctx.__tabKids[n]` reads exactly what it read at 14.13.3.3.

#### `OptionsWidgets.lua` now has a hard floor on `LibKa0s-Pool-1.0`

The file refuses to attach — no `lib.MODULES.OptionsWidgets`, no widget makers — when
`LibKa0s-Pool-1.0` is absent or below minor 1, the same way `DebugLog.lua` refuses without
`LibKa0s-Widgets-1.0`. Degrading instead would mean falling back to allocating per click, in silence,
which is the defect this minor exists to end.

**In a well-formed payload the floor is unreachable.** `Pool.lua` and `Options.lua` both gate on
`LibKa0s-Core-1.0`, and `Pool.lua` loads first in `LibKa0s.xml`, so a tree with no pool has no Options
major for this file to attach to either. Whole-folder re-vendoring is mandatory (`docs/releasing.md`),
so a host that trips this has a broken copy rather than an unlucky one.

### Previously, at 14.13.3.3

**`OptionsCompose.lua` minor 3 — the three media rows hand the flow engine the deferred reader
itself, not a closure wrapped around it.** This was a **fix to shipped, player-facing behaviour**:
every dropdown `FontGroup`, `BorderGroup` and `BarGroup` composed was empty in the client, in every
consumer, from 14.13.1.3 onward.

`O.LSMValues(mediaType)` already returns the deferred closure the engine wants. The three group
composers wrapped it a second time:

```lua
values = function() return O.LSMValues("font") end,   -- 14.13.1.3 and 14.13.2.3
values = O.LSMValues("font"),                         -- 14.13.3.3
```

`enumList` unwraps a row's `values` **exactly once**. Handed a closure around a closure it got a
function where it expected a table and returned `{}` — and nothing said so, because the *"no
options"* report is gated on `row.values == nil` and a doubly-wrapped row is not nil, merely useless.
That gate is correct and stays: it is what keeps a legitimately-empty deferred media list quiet while
the addons that register fonts are still loading. What it cannot do is tell an empty list from a
wrapper, which is why this shipped green.

#### The one contract that tightened, for a host that supplies its own `LSMValues`

`lib.__AttachCompose(O)` lets a host hand in its own `O.LSMValues`, and **that member must return a
function**. It always had to; until 14.13.3.3 the composer read it inside a closure, at
dropdown-render time, so a host whose `LSMValues` returned a *table* worked by accident — late
evaluation covered for it.

The composer now reads that member **once, at row-declaration time**, and assigns the result
straight into `values`. A table-returning host therefore lands a literal table frozen at file load:
no error, no warning, and precisely the failure the deferral exists to prevent — the addons that
register media have not run when a schema-row literal is evaluated.

**This is the one thing to check before adopting 14.13.3.3 or anything after it.** A host that never
touches `O.LSMValues` is unaffected; so is one that overrides a composed row's `values` afterwards. A
host that assigns `C.LSMValues = function(t) return lsmValues(t)() end` must pass the reader itself
instead — `C.LSMValues = lsmValues` — in the same change as the re-vendor.

### Previously, at 14.13.2.3

**`OptionsCompose.lua` minor 2 — `MasterControls` takes a `leadButton`.** One file moved; everything
else in this major is unchanged from 14.13.1.3.

`§15` fixes the wording of the two reset buttons, and the composer is the only thing that writes it.
An addon with a verb of its own to put beside them — PrettyChat's *Test*, which prints a sample of
every active format string — therefore had nowhere to put it: drawing the pair itself means keeping a
second copy of *"Reset all settings"* and its tooltip in the addon, which is the drift this composer
exists to end. So the verb is handed **in**:

```lua
local rows, tail = O.MasterControls{
  page = "General", addonName = "PrettyChat", frameless = true,
  leadButton = { text = "Test", tooltip = "…", onClick = runTest },
  onResetAll = function() … end,
}
```

**Where it lands is not a preference.** A **frameless** addon's pair has exactly one empty cell — the
right half `§15` leaves when there is no *Reset position* — so the verb leads and the reset still
closes the tab: `[Test] [Reset all settings]`. A **framed** addon's pair is already full, and `§15`
forbids splitting or reordering the canonical two, so there the verb takes its **own row above** the
pair rather than displacing a reset. Nothing draws three buttons on one line.

It is **one** button, not a list. The tab closes with the resets; a row of host verbs before them is a
different design, and `§15` does not describe one.

A host written against 14.13.1.3 is correct here unmodified — the field is additive and its absence
is the old behaviour exactly.

### Previously, at 14.13.1.3

**`Options.lua` minor 14 / `OptionsWidgets.lua` minor 13 / `OptionsCompose.lua` minor 1 — the tab
strip becomes mandatory and selection-invariant, and the canonical control blocks become composers**
(options-ui-§13, §15, §16, §17).

The largest single move this major has made. Four things, and one of them is a shipped defect.

### The strip's geometry no longer depends on which tab is selected

The selected tab is cut from `Options_Tab_Active_*` and every other tab from `Options_Tab_*`, and the
client does not draw the two families at the same height. `TabStrip` seeded the wrap pitch from the
**first** tab it built — `ctx.__tabArtH = ctx.__tabArtH or artH` — so on a page whose strip **wraps**,
selecting tab 1 packed the rows by the active art and selecting any other packed them by the
inactive art. That pitch feeds both `__tabPlacement`'s row offsets and `__tabBand`'s reserved band,
and `SetChromeHeight` re-anchors the scroll **and** the content panel off the band. So clicking one
particular tab opened a gap between the wrapped rows and moved and resized the whole page under
them, and clicking any other healed it — which is what made it read as a rendering glitch rather
than as arithmetic. It is invisible on an unwrapped strip, because the pitch is multiplied by
(rowCount − 1) = 0.

The pitch is now measured **once**, from the **inactive** cap atlas, on a throwaway texture — never
read back off a tab that was just drawn in whichever state it happened to be in — and cached on
**success only**, so a call made before the client can answer does not pin the fallback for the
session. `ctx.__tabArtH` and the internal `rowPitch(ctx)` are gone; `drawTabSlices` measures nothing.

Two consequences. Every button's `SetHitRectInsets` now takes the **same** number the rows are
packed by, so the invariant it exists for holds for the selected tab too rather than for all but one
button per strip. And `setTabLabel` no longer applies the selected font: a tab's width is measured
off its FontString, and a measurement taken under a selection-dependent font is a wrap index that
moves with the selection. The two fonts are the same size today, so no wrap index moves; pinning the
order is what keeps that true rather than lucky.

`O.__tabArtHeight()` and `O.__resetTabArtHeight()` are published as test seams, because the invariant
a suite has to pin — *the band and every row offset are identical for every value of the selection* —
is unassertable without the one number both are built from. **A harness that answers one height for
every atlas cannot fail that case**, which is exactly how the defect shipped green.

*The direction of the residual is worth measuring in a live client once.* Packing by the inactive
height leaves the selected tab's art standing a pixel or two proud into the row above, which is the
direction `TAB_BG_TOP` and `TAB_LABEL_Y` already lift it deliberately. If the active art turns out to
be the shorter of the two, the residual disappears entirely and nothing else changes.

### Every page draws a strip, including a page with one section

`RenderTabbedSchema`'s `#groups < 2` fallback to `RenderSchema` is **deleted**. "A single tab is
chrome for its own sake" is a true sentence about one page and the wrong rule for a panel: a player
moving between pages meets a strip on most of them and bare rows on the rest, and the page that lost
its strip is the one that looks broken. The tab is also the only thing naming the group once
`noHeadings` has suppressed the heading, so the fallback took the section's name off the page as
well.

The one exemption is **a page the host does not render through this engine at all** — today the
AceConfig-drawn Profiles page, which never reaches this function. The exemption is a property of the
call graph rather than of a page's name, because a name-match stops being true the first time a page
is renamed and says nothing when it does. **No opt-out flag is offered**: a flag is a thing an addon
can set for the wrong reason, and there would be no way to see it in a test.

A page with **no** groups is a different decision. There is nothing to name a tab with, so it is
reported by page key through the descriptor's `print` and then rendered untabbed — a blank page under
an empty strip is a worse failure than a strip-less one. The missing `group` is the defect to fix.

**Visible change** for any page that today has exactly one group: it gains a strip and its content
moves down by the band. Every page with two or more groups is byte-identical.

### Three new row fields, and two new members

`subgroup` draws a heading **inside** a tab and is *not* suppressed by `noHeadings` — a tab mixing
bar rows, background rows and border rows has to say where one stops and the next starts, and there
is no tab left to name them with (options-ui-§7). It draws through `O.Section`, the same AceGUI
Heading every other header uses; two heading looks on one canvas is the drift the shared library
exists to end. One tab is still exactly one `group`, so the tab list stays derivable from `group`
alone.

`wide` renders a row alone at **full** width. `solo` does not do this — it renders alone in the
**left half** — and `wide` takes `RenderGrid`'s existing name rather than redefining `solo`, which
would silently widen every solo row in nine shipped addons.

`startsLine` flushes the pending line **before** a row, so a declared pair — a color swatch and its
class-color companion — can never be split across two lines by an odd number of widgets above it.
That parity was a property of how many rows happened to precede the pair, which every author was
counting by hand.

`O.PageHeader(ctx, spec)` pins a host-drawn block in the band the page banner occupies, for controls
that apply to **every** tab: drawn under one tab they read as belonging to it, and they vanish the
moment the player clicks another (options-ui-§14). It generalises the **band**, not the banner —
`O.PageBanner` draws exactly one Dropdown and is documented as the page's only picker. The two
release the same ledger and write the same `ctx.__bannerHeight`, so a page gets **at most one**
chrome block and the second call replaces the first; a page needing both a picker and other
page-wide controls puts the picker inside the block.

`O.SubTabStrip(ctx, parent, spec)` draws a **secondary** strip inside the scroll as ordinary page
content. The primary strip is pinned and does not scroll; a secondary division belongs to the content
it divides, and pinning a second band would double the chrome and push the page down twice. It has
its own ledger (`ctx.__subTabKids`), packs by the same selection-invariant pitch, and its selection is
the **host's** state — `spec.value` and `spec.onSelect` are the whole contract.

### An empty dropdown reports itself

A `type = "string"` row with neither `values` nor `dialogControl` is a free-text field that forgot to
say so: the dispatch sends it to `makeDropdown` and the player gets a control that opens on nothing.
The opt-in stays — inference would silently turn a row whose `values` function answers empty into a
free-text field, which is the deferred-media case the opt-in exists for — so the warning is keyed on
`row.values` being **nil**, and an LSM-backed closure that is momentarily empty stays quiet.

### `OptionsCompose.lua` — the schema composers

**A schema generator, not a renderer.** `O.ColorPair`, `O.FontGroup`, `O.BorderGroup`, `O.BarGroup`
and `O.MasterControls` each expand one declaration into the canonical block of **ordinary schema
rows** (options-ui-§15, §16, §17). Every composer is a pure function: it creates no widget, touches
no AceGUI, reads no state and never writes to the spec it was handed. That is the whole design —
what comes out is indistinguishable from hand-written rows, so `rowsForPage`, `applyDefault`,
`RestoreDefaults`, the CLI and the reset sweep all keep working with nothing added to them, and the
composers are testable with no mock at all. A composer that *rendered* would have needed a `ctx`, and
every one of those seams would have needed a second implementation.

Nine hand-written copies of the same six font rows is exactly the drift this library was extracted to
end, and the day the block grows a row it grows in one addon. See
[The schema composers](#the-schema-composers).

`Options.lua` gains the `lib.__AttachCompose` call, guarded like the other two so a copy vendored
without the file degrades to no composers rather than erroring at `:New`, and `O.ClearScroll` now
resets `ctx.lastSubgroup` alongside `ctx.lastGroup`.

## Previously, at 13.12.3

**`Options.lua` minor 13 / `OptionsWidgets.lua` minor 12 — the content box stops touching its own
contents, and wrapped rows of tabs sit flush** (options-ui-§13).

Two things a client showed that 12.11.3's arithmetic could not. Neither adds a member; both are
geometry the headless suite had no way to be wrong about, because a headless chrome has no width
and a headless atlas has no height.

**A box has to be outside everything it contains.** 12.11.3 anchored the `Options_InnerFrame`
panel on the content column's own edges — the same `CONTENT_LEFT` / `CONTENT_RIGHT` the page's
widgets use. So the left-hand row labels butted against the left border, and AceGUI's always-shown
scrollbar, which sits *outboard* of `CONTENT_RIGHT` by design, was painted on top of the right one.

The panel now carries its own three internal insets — `PANEL_LEFT`, `PANEL_RIGHT`, `PANEL_BOTTOM`,
each smaller than the content column's — and is anchored horizontally to `ctx.body` rather than to
`ctx.chrome`. The tab strip stays on the content column, which leaves the leftmost tab a few pixels
inside the box's left edge: OPie's arrangement, and the reason its tabs read as sitting *on* the
panel rather than as being its top row.

**A wrapped strip packs by the ART's height, not the button's** (W12). A tab button is `TAB_H`
(37px) carrying an atlas that is shorter, and the difference is the foot that overlaps the panel —
so the empty strip along each button's top stood between two rows as a visible gap. The atlas's
height is only knowable from the client, so `drawTabSlices` measures it (`GetHeight` after
`SetAtlas(name, true)`) and the strip packs rows by that number.

Two consequences worth stating:

- The next row's button overlaps the previous row's art by exactly the empty amount, so each
  button takes a `SetHitRectInsets` removing its own empty top from the mouse. Without it, row 2
  would swallow clicks aimed at the bottom of row 1.
- `__tabBand`'s shape becomes **(n − 1) pitches plus one whole tab**. Every row but the last
  contributes only its pitch, because the next row overlaps it; the last must fit whole, since its
  bottom is the edge the content panel starts at.

**`TAB_ROW_GAP` is retired**, and `__tabPlacement` / `__tabBand` take a `rowPitch` where they took
a `tabH` and a `rowGap`. A measured pitch is not a height plus a gap, and keeping a gap constant
beside it would be two numbers for one decision. Both fall back to `TAB_H` where nothing can be
measured, which is exactly the pre-measurement behavior with no gap.

**Untabbed pages remain untouched.** The panel is drawn by `TabStrip` and nothing else.

### Previously, at 12.11.3

**`Options.lua` minor 12 / `OptionsWidgets.lua` minor 11 — the tab strip stops imitating client
chrome and starts using it, and a first-render wrap bug goes with it** (options-ui-§13).

11.10.3 drew tabs from `Interface/OptionsFrame/`, the client's *old* tab textures. Right idea,
wrong art: those files have sloped transparent shoulders, so a 4px gap between two tabs read as
twelve, and the 1px rule under the strip read as a line the tabs happened to be near rather than
as the edge of anything.

**No member is added or removed at this version.** One published scalar moves — `TAB_H`, 24 → 37 —
and one internal key is retired.

**The reference implementation is OPie's `Libs/TenSettings.lua`**, copied rather than approximated:
the `Options_Tab_*` / `Options_Tab_Active_*` atlases, three slices a tab with the end caps at
natural atlas size and only the middle stretched, the dark gradient backing, the hover glow and
the selected glow, the label anchored to the tab's bottom, `GetStringWidth() + 40`, and a 37px
tab. One deliberate departure: OPie chains its tabs leftward from the frame's right edge and this
strip packs them left to right, because a strip that wraps has to grow downward from a fixed
origin and the left edge is the one the content column already uses.

**The tab/content separator is now a real panel edge, not a rule.** `TabStrip` draws the client's
`Options_InnerFrame` behind the page — two halves meeting at the midpoint, the left one mirrored
by a reversed u range so both corners stay crisp — parented to `ctx.body`, anchored to
`ctx.chrome`'s bottom, and running down to `L.CONTENT_BOTTOM`. It is forced to the body's **own**
frame level, because a child frame otherwise sits one level above its parent and the art would
land in front of the scroll it is meant to sit behind.

A tab is 37px tall against art that is shorter, and the difference is a **foot** that lands on
that panel edge and merges into it. That merge is what a hairline could not do: three attempts at
a 1px rule all read as disconnected, because a line is not the edge of anything.

**`TAB_BASELINE_H` is retired and `__tabBand` no longer takes or reserves it.** Its signature is
now `__tabBand(top, rowCount, tabH, rowGap)` returning one number. A panel drawn *below* the band
must not also be reserved *inside* it, or the page opens a one-pixel gap under its own tabs. The
new internal `CONTENT_BOTTOM` replaces the literal `8` `anchorScroll` used, so the scroll and the
art behind it cannot end in different places.

**Untabbed pages are untouched.** The panel is drawn by `TabStrip` and nothing else, so a consumer
that has never called it renders exactly as it did at 11.10.3 — which is eight of the nine.

**The first page a player opened stacked its tabs vertically** (W11). `ctx.chrome` has zero width
until the settings canvas lays itself out, and the first render happens before that: `placeTabs`
read `0`, fell back to `TAB_MIN_W`, and every tab wrapped onto its own row. It healed the moment
you clicked any tab, because the second render measured a real width — which is exactly why it
survived a suite that only ever rendered twice.

A width cannot be computed from config here; it is the canvas's, and the canvas is Blizzard's. So
the strip re-places itself when the width arrives, through an `OnSizeChanged` script installed once
per panel. Two things keep that from looping: the handler ignores everything but a *change* in
width, and `placeTabs` records the width it used — so the height change `SetChromeHeight` causes,
which fires the same script, is a no-op. The handler reads the current layout out of `ctx` rather
than closing over one strip's buttons, which would pin a released set alive and re-place them
after they were hidden.

`O.EnsureDefaultsButton` has carried a note about `ctx.body` having zero width at enable time since
`O7`. This is the same client behavior reaching a second piece of chrome, and that note is why it
was recognized rather than debugged.

**`TAB_PAD_X` moves 18 → 20** (O12, internal). It has now been too small twice: at 12 the label sat
on the end cap outright, at 18 it cleared the cap but left the tabs cramped against every other tab
strip in the client. 20 a side is OPie's `+ 40`.

**Twelve internal `lib.LAYOUT` keys stay unpublished**, each annotated in `Options.lua` with why:
`TAB_PAD_X`, `TAB_GAP`, `TAB_MIN_W`, `CONTENT_LEFT`, `CONTENT_RIGHT`, `CONTENT_BOTTOM`,
`CHROME_DIVIDER_GAP_TOP`, `CHROME_DIVIDER_H`, `CHROME_DIVIDER_GAP_BOTTOM`, and at 13.12.3
`PANEL_LEFT`, `PANEL_RIGHT`, `PANEL_BOTTOM`. `TAB_ROW_GAP` was retired here; `TAB_BASELINE_H` at
12.11.3.

## What this major is

The settings panel: the canvas shell, the page registry, the lazy Defaults button, the reset and
refresh trio, the five widget makers, and the two-column flow engine that turns a list of schema
rows into a laid-out page.

Three files, one major — `Options.lua` (shell), `OptionsWidgets.lua` (makers and flow),
`OptionsScroll.lua` (the always-shown scrollbar patch). One major because they are one feature: a
host that ended up with a shell from one vendored copy and a flow engine from another would build
panels that lay out wrong, and no version negotiation would catch it. **This is why the version key
above is a triple and why re-vendoring is whole-folder** — the three minors are not independently
adoptable.

Like the others it depends on LibStub and `LibKa0s-Core-1.0` and on no addon framework. AceGUI-3.0
is resolved through LibStub at panel-build time and its absence is survivable — one honest line and
no panel — which is not the same thing as a dependency.

**Previously, in `Options.lua` minor 8 — `O.RefreshPanel(ctx, structural)`, the per-page half of the refresh trio.** One new instance
member, additive. `OptionsWidgets.lua` and `OptionsScroll.lua` do not move. No descriptor field, row
field or drawn pixel changes.

`O.RefreshAllPanels()` and `O.RefreshScalars()` sweep **every** registered ctx, which is right for a
write that could be showing on any page — that is why each widget maker's own `set()` calls one. It
is wrong for a host whose page repaints off its **own** message bus: that host wants one page
repainted and gets three, and the library never hears about the change at all.

What was left for such a host was the private field. `SetRenderer`'s `OnShow` gate reads
`ctx._dirty`, and a host deferring a repaint on a hidden page had to write that flag itself, under a
name nothing published. **PanelMaster guessed `ctx.dirty`** — one underscore out — so its Panels page
marked a flag no code reads. The gate never opened, and the page kept the widget tree it had built
for the previous profile: after a profile switch its panel dropdown still listed the old profile's
panels, while the panels themselves had correctly left the screen. Both suites stayed green, because
the host's own test asserted the same wrong flag name.

- **`Options.lua` minor 8** — `O.RefreshPanel(ctx, structural)` on the instance. It is
  `RefreshAllPanels`/`RefreshScalars` scoped to one ctx and shares their implementation, so the
  shown/hidden decision, the dirty flag and the two tiers stay the library's. A non-table `ctx` is a
  no-op rather than a raise.

**Published on a demonstrated need, which is the bar this library sets** (`library-stack-§7`,
anti-pattern #55). The need here is not repetition: a host bus is a shape the two sweeps genuinely
do not serve, and the only workaround was reaching into a private field by guessing its name — which
is exactly the failure that arrived.

## What stays the host's

The library never learns a settings path, a page name, or a database. It also never learns what a
page *contains*: a host registers builders, and each builder draws its own page through the makers.
What the library owns is everything that is the same in every addon — the canvas registration, the
header and breadcrumb, the button that must not be built too early, the row-pairing arithmetic, and
the refresh fan-out.

## Two divergences absorbed rather than decided

**Colour storage** is a descriptor codec, in **both** majors. AbsorbTracker stores
`{r=,g=,b=,a=}`; KickCD and the Ka0s options colour widget store arrays. Baking either in would
force the other to translate at every read site in the addon, so `colorDecode` / `colorEncode` are
descriptor options — under the same names on the Options and Slash descriptors, so a host passes
one pair to both — and the named-key form is only the default. `Slash.FormatValue` additionally
reads the positional shape directly, so the common case needs no descriptor at all.

**The fifth widget type** ships in `-1.0` rather than being added later. KickCD has a free-text
edit box; AbsorbTracker has no equivalent. Adding a *type* later is additive, but retrofitting one
into a dispatch table the major has already frozen is not. It is opted into with
`dialogControl = "EditBox"` rather than inferred from a missing `values` list, because inference
would silently turn a row whose values function happened to return empty into a free-text field.

## The panel descriptor

Everything a host supplies to `lib:New(descriptor)`.

| Field | Type | Required | Since | Meaning |
|---|---|---|---|---|
| `parentTitle` | string | yes | O1 | The brand. Shown on the main page and as the breadcrumb prefix on every sub-page. |
| `mainPanelName` | string | yes | O1 | Frame name for the main canvas, so `/framestack` attributes it to the host and two addons cannot collide. |
| `print` | function(line) | no | O1 | Where a user-facing line goes. Hosts pass their prefixed printer. |
| `get` | function(path) | yes | O1 | Read one stored value. |
| `set` | function(path, v) | yes | O1 | Write one. Route it through the host's single write seam, so a panel change takes the same path a slash command does — same debug line, same `onChange`, same refresh. |
| `applyDefault` | function(row) | yes | O1 | Reset one row. Same reasoning. |
| `rowsForPage` | function(pageKey, filter) | yes | O1 | The rows of one page, in render order. `filter` is `ctx.unit`, passed through untouched — the library never interprets it. |
| `allRows` | function | yes | O1 | Every row, for `RestoreAllDefaults`. |
| `resetProfile` | function | no | O9 | Supply it and a global reset becomes a **profile reset**: the `sessionOnly` rows are swept row by row, then this is called, then every panel refreshes. Pass `function() NS.db:ResetProfile() end`. With it supplied the library narrows the row walk itself — see `RestoreAllDefaults` below. **Since O18 / C5** it also picks the wording of `MasterControls`' *Reset all settings* tooltip: see [Previously, at 18.15.5.3](#previously-at-1815553). |
| `profilesPage` | boolean | no | **O18** | `true` when the host ships an AceDBOptions Profiles sub-page (`options-ui-§3`). Read by `MasterControls` alone, and only with `resetProfile` supplied: the *Reset all settings* tooltip then names the equivalence `options-ui-§12` asks for, *"the same thing Profiles → Reset Profile does"*. The library cannot see which pages a host registers, so the host declares it. Ignored without `resetProfile`, and changes nothing but that tooltip. |
| `skipRestoreAll` | function(row) | no | O1 | Return true to exclude a row from a global reset. With `resetProfile` supplied the profiles-page veto this was invented for is **implied** (an AceDBOptions row is not `sessionOnly`, so it is already outside the narrowed walk); the field is still honored, and is the whole policy for a host that supplies no `resetProfile`. |
| `afterRestoreAll` | function | no | O1 | Runs after the rows are reset **and after `resetProfile`**, and **before** the panels refresh, for state in neither the schema nor the profile. The order is load-bearing: a refresh first would paint the pre-hook values. A dragged frame's saved position is **not** an example any more — a position lives in the profile and comes back with it. |
| `bulkBegin` | function(act, scope) | no | **O16** | Called once before `RestoreDefaults` (act `"reset"`, scope the `pageKey`) or `RestoreAllDefaults` (act `"reset"`, scope `"all"`) writes its first row. Mute the host seam's per-row `[Set]` line here — `debug-logging-§10`. See [The two fields](#the-two-fields). |
| `bulkEnd` | function(act, scope, count, err, info) | no | **O16** | Called once when the act ends, **always** when the bracket was begun — even if a row, `resetProfile`, `afterRestoreAll` or `bulkBegin` raised. `count` is the rows whose `applyDefault` returned, including rows already at their default, so it is **not** §10's N; `err` is the raised value or `nil` (a raise of `nil`/`false` also arrives as `nil`), and is re-raised unchanged after this returns; `info` is `{ profileReset = <boolean> }`, `true` only when `RestoreAllDefaults` called `resetProfile` and it returned. Unmute here. Then, only when the outermost bracket closes: if any level reported `info.profileReset`, the host **MUST NOT** emit a bulk line (its profile-event handler logs the reset once); otherwise it emits `[Set] reset <scope>: N rows`, with N its own tally of writes that changed a stored value. A host that mutes in `bulkBegin` MUST supply this field. See [What the host logs](#what-the-host-logs--the-contract). A host supplying neither field runs minor 15's walk exactly. |
| `scheduleTimer` | function(fn, delay) | no | O1 | Backs the 50 ms colour-drag throttle. A descriptor field rather than an AceTimer embed, because embedding would be this library's second dependency-budget breach. Without it a drag commits every frame. |
| `getLSM` | function | no | O1 | Returns LibSharedMedia-3.0, for `LSMValues` and, **since O17**, for the font preload a panel's show runs ([`lib.__PreloadFonts`](#lib__preloadfontslsm--number)). Absent, a host gets no preload. |
| `validate` | function | no | O1 | Runs once, before the page builders. A host's schema-shape check. |
| `onAceGUI` | function(AceGUI) | no | O1 | Handed the resolved AceGUI so the host can stash it (library-stack-§4) for its own page files. |
| `buildMain` | function(ctx) | no | O1 | Draws the main page's body, on its first OnShow. |
| `colorDecode` | function(stored) | no | O1 | → `r, g, b, a`. Defaults to the `{r=,g=,b=,a=}` shape. |
| `colorEncode` | function(r,g,b,a) | no | O1 | → stored. Defaults to the same. |
| `sliderCommit` | string | no | O1 | `"change"` makes every slider commit on the drag as well as on release, throttled through `scheduleTimer`. Default is release-only; a single row overrides either way with `commitOn`. |
| `debug` | function(tag, fmt, …) | no | O1 | Developer log line. |

Unlike Core, DebugLog and Slash, this module performs **no descriptor validation at all** — `d` is
indexed directly, so only a nil descriptor raises. The fields marked required above are required in
practice rather than enforced: a missing `parentTitle` silently becomes `""`, and a missing
`get`/`set`/`applyDefault`/`rowsForPage`/`allRows` surfaces at panel-build time, when a widget maker
reaches for it, not at `:New`. Treat the column as a contract you keep rather than one the library
keeps for you.

## The library surface

Almost everything this major publishes hangs off the instance `lib:New(descriptor)` returns. Two
members do not, and cannot. A widget-registry entry is per **process**, and so is a loaded font
file, so the thing that writes either has to be per library rather than per host.

### `lib.__PatchLSM30Border()` → boolean

**Since O15.** Wrap AceGUI-3.0-SharedMediaWidgets' `LSM30_Border` so it lines up on a canvas-layout
settings page, and register the wrapper one version above whatever the registry currently holds.
Returns `true` if this call performed the registration and `false` if there was nothing to do.

| | |
|---|---|
| Where to call it | From the live arm of the host's options setup — the same place it resolves AceGUI. Safe at file load, and safe to call again later. |
| What it does per instance | Hides `frame.displayButton`, re-anchors `frame.label` to the frame's own TOPLEFT and TOPRIGHT, and restores `frame.DLeft` to `GetBaseFrame`'s `BOTTOMLEFT, -17, -21`. |
| What it wraps | Whatever constructor the registry holds when it runs — which may already be a skinning addon's — never a reimplementation of the widget. |
| Idempotence | `lib.__lsmBorderPatched`, on the **library** table. Every vendored copy in the session shares one `lib`, so N copies calling this produce exactly one registration. |
| Returns false when | The library is already patched, AceGUI is absent, or `LSM30_Border` is not in the registry yet. |
| Scope | Border only. `LSM30_Font` and `LSM30_Statusbar` take `AGSMW:GetBaseFrame`, which has no `displayButton`. |

**A `false` return is not an error and does not need handling.** The three reasons for it are all
ordinary: another Ka0s addon got there first, this client has no AceGUI, or AGSMW has not loaded yet.
The last of those is the reason the sentinel is set **only after a registration actually happens** —
a host that calls this early and again after login gets its patch on the second call, where a flag
set on the early return would have disarmed the surface for the whole session in silence.

**`lib.__lsmBorderPatched` is readable but is not a supported write.** Clearing it does not
un-register the wrapper; it only invites a second one to be registered on top of the first, which is
the five-deep stack this member exists to end.

### `lib.__PreloadFonts(LSM)` → number

**Since O17.** Load every LibSharedMedia font face not loaded yet, then subscribe once to faces
registered later. Returns how many faces this call loaded. See
[What changed at this version](#what-changed-at-this-version) for why.

| | |
|---|---|
| Who calls it | The library, from every panel show: `O.SetRenderer`'s OnShow after its combat refusal, and the OnShow hook `O.CreatePanel` installs. A host does not call it. |
| `LSM` | What the host's `getLSM()` returns. Anything that is not a table with `HashTable` answers 0 and creates nothing. |
| What it creates | On the first call that loads anything: one frame for the session, parented to `UIParent`, shown, full alpha, 1x1, off the left edge of the screen. Then one FontString per distinct font path, `SetFont(path, 12, "")` and `SetText("Aa")`, `pcall`'d together. |
| Idempotence | `lib.__fontPreload`, on the **library** table: `{ paths = { [path] = true }, frame, subscribed }`. Every host and every vendored copy shares it, so each path is loaded once per session. A path is marked before it is tried, so a face the client refuses is not retried. |
| Late faces | After the first call that finds a `CreateFrame`, one subscription to `LibSharedMedia_Registered`, with the state table as its target. A `font` registration re-runs this, which loads only the new path. |
| Degrades | No `CreateFrame` answers 0 and marks nothing, so the next call tries again. A raising `HashTable` answers 0. The instance trigger `pcall`s the whole call, `getLSM` included, and reports nothing. |
| After an upgrade | Both callers look the member up on `lib` at call time, so the newest copy's code runs against the state the older copy left. |

**`lib.__fontPreload` is readable but is not a supported write.** The suite resets it between cases.
A host that clears it loads every face a second time, into a second frame, for nothing.

## The instance surface

Everything `lib:New(descriptor)` returns on the instance.

| Name | Since | Meaning |
|---|---|---|
| `CreatePanel(name, title, opts)` | O1 (canvas contract: **O5**; chrome slot: **O10**) | A canvas Frame with the unified header stamped on top, returning the `ctx` every render call threads through. `opts` = `{ pageKey, isMain, defaultsButton, defaultsTooltip }`. Registers the ctx so the refresh fan-out reaches it. Also stamps the **Blizzard canvas contract** — `OnCommit` and `OnRefresh` inert (writes land immediately through the host's write seam, and `SetRenderer` already owns re-show), and `OnDefault` **forwarding** to the panel's `defaultsOnClick` so the Settings window's footer control and the header Defaults button stay one implementation. A forwarder rather than an assignment because hosts park `defaultsOnClick` *after* this returns. The returned `ctx` now also carries `chrome` (a pinned `Frame` between the header and the scroll) and `chromeHeight` (starting at `0`) — see [What changed at this version](#what-changed-at-this-version). |
| `EnsureDefaultsButton(panel)` | O1 | Builds the header's Defaults button on the panel's **first OnShow**, never at build time. Idempotent, and a no-op on a panel that did not ask. |
| `EnsureScroll(ctx)` | O1 | The lazy AceGUI ScrollFrame, patched for an always-visible scrollbar. |
| `ClearScroll(ctx)` | O1 (`lastSubgroup`: **O14**) | Release the children, reset **both** heading trackers (`ctx.lastGroup` and `ctx.lastSubgroup`), and **reassign** `ctx.refreshers`. |
| `Section(ctx, label)` | W1 | A full-width Heading, with the inter-section spacers. |
| `AddSpacer(scroll, height)` | W1 | An invisible full-width row. |
| `TextRow(ctx, text, opts)` | **W6** | A full-width Label, left-justified, added to `EnsureScroll(ctx)` and returned. `opts.fontObject` is a `_G` font-object **name**; `opts.justify` defaults to `"LEFT"`. Returns nil when AceGUI or the scroll is absent. Owns the `w.label` / `SetJustifyH` / `SetFontObject` guard pair **once**. |
| `BuildLandingPage(ctx, spec)` | **W6** | The whole landing body: clear, logo, one-liner, then a heading and its rows per section. See [The landing page](#the-landing-page). |
| `AttachTooltip(widget, label, tooltip)` | W1 | Works on AceGUI widgets and on plain frames. |
| `InlineButtonPair(ctx, left, right)` | W1 | Two action buttons (not settings) in one Flow row, each inset to `BUTTON_PAIR_REL`. A **nil** `right` draws the left button alone, at the pair's width, so it still lines up with every other page's — which is the shape a frameless addon's Master controls tab needs. A throwing `onClick` is reported, never propagated into AceGUI's dispatch. A spec carrying **no** `onClick` is reported once at BUILD time (`lib.STRINGS.DEAD_BUTTON`, naming the button's text) and drawn anyway — the composer emits the master group's two resets unconditionally, so a host that never supplied `onResetAll`/`onResetPosition` is told rather than shipping a live-looking button that swallows the click. **From W16**, drawn inside a disabled render (`RenderRows`' `opts.disabled`, or a disabled `ChoiceGrid` / `IdInput` / `IdList`), both buttons are drawn disabled. |
| `RenderField(ctx, row, parent, relWidth)` | W1 (path-less rows: **W15**; `disabledIf` on every maker: **W16**) | Dispatch by `row.type` to one of the five makers. Returns nil for an unknown type rather than erroring — a misspelled type costs one row, not the page. A row with no `path` is read and written through its own `get` / `set` from W15 — see [Previously, at 15.15.4.3](#previously-at-1515543). From W16 every maker honors `row.disabledIf` — see [What changed at this version](#what-changed-at-this-version). |
| `SessionCheckbox(ctx, parent, relWidth, spec)` | W1 (disabled render: **W16**) | A checkbox wired to caller-supplied `get`/`set` instead of a settings path, for runtime-only toggles that must never persist. From W16 it is drawn disabled when drawn inside a disabled render. |
| `RenderRows(ctx, rows, afterGroup, pairWith, opts)` | W1 (`opts.noHeadings`: **W9**; `opts.disabled`: **W16**) | The flow engine, over an **explicit** row list — which is what lets a host render a filtered subset through the same code. `opts = { noHeadings = true }` suppresses the automatic `Section` heading, for a page whose sections are drawn as tabs instead (options-ui-§13); the row-boundary flush and `ctx.lastGroup` advance still happen. Omitted by every untabbed caller. **`opts.disabled = true` (W16)** draws every widget of the call disabled, the widgets an `afterGroup` or `pairWith` hook draws included, through `ctx.__renderDisabled` held for the call alone. A nested call inherits it, and the outer value is restored on a raise, which is re-raised unchanged — see [What changed at this version](#what-changed-at-this-version). |
| `RenderSchema(ctx, pageKey, afterGroup, pairWith)` | W1 | The per-page wrapper. |
| `RenderTabbedSchema(ctx, pageKey, afterGroup, pairWith)` | **W9** | Render one page as a tab strip over its own sections. The partition is by `row.group`, in declaration order — one tab is exactly one group, and there is no second field naming a tab (options-ui-§13). **Every page draws a strip from W13, including a one-group page** — the `#groups < 2` fallback to `RenderSchema` is gone, and the only exemption is a page the host does not route through this function at all (the AceConfig-drawn Profiles page). A page whose rows carry **no** `group` is reported by page key through the descriptor's `print` and rendered untabbed. A stale `ctx.activeTab` heals to the first group. A tab click re-enters through `ClearScroll` and this function again — the same structural path a subject change already takes, but that path carries no combat refusal to inherit: `SetRenderer`'s guard covers opening or switching a category, not redrawing inside an already-open panel, so a tab click needs no guard and none is added (options-ui-§13). Returns the group names, in tab order. |
| `TabStrip(ctx, spec)` | **W9** | A pinned tab strip in `ctx.chrome` (options-ui-§13). `spec = { tabs = { { key, label, tooltip } }, value, onSelect }`. One `Button` per tab, the active tab the disabled one. Wraps its buttons across rows via `__layoutTabs`, places them via `__tabPlacement`, and reserves the band via `__tabBand` + `SetChromeHeight` — **after** the wrap is known. Each tab is three slices of the client's `Options_Tab_*` atlases; the selected one is drawn from the Active family and its foot overlaps the `Options_InnerFrame` content panel `TabStrip` also draws (**W11**). Re-places itself once when `ctx.chrome` first learns a real width (**W11**). **Its geometry is invariant under the selection from W13.** **From W14 the buttons and the content panel are acquired from `LibKa0s-Pool-1.0` pools held on the `ctx` rather than created per click** — see [What changed at this version](#what-changed-at-this-version). Returns the buttons in tab order, or nil having drawn nothing. |
| `SubTabStrip(ctx, parent, spec)` | **W13** | A **secondary** strip drawn inside the scroll as ordinary page content, parented to a frame the host supplies (options-ui-§13). Same `spec` shape as `TabStrip`, same selection-invariant pitch, its own ledger (`ctx.__subTabKids`) released on entry, and **no** content panel and **no** `SetChromeHeight` — the page already has both. **Not pooled at W14**, unlike the primary strip: its parent is a frame AceGUI takes back, so its buttons are unparented on release and cannot be recycled. Returns the buttons in tab order **and** the total height the strip occupies, so the host can size the frame it handed in, or nil having drawn nothing. The selection is the host's state: `spec.value` and `spec.onSelect` are the whole contract, and the convention for the collection is `ctx.activeSubTab` as a table keyed by the primary tab's key, session-only and never persisted. |
| `PageBanner(ctx, spec)` | **W9** | The page's picker, pinned above the strip and the scroll (options-ui-§14) — the only picker a page may have. `spec = { label, list, order, value, onSelect, tooltip }`. Draws one AceGUI `Dropdown` into `ctx.chrome`, plus the gap / hairline / gap that separate it from the strip (options-ui-§14); records the whole band in `ctx.__bannerHeight` via `__bannerBand` and reserves it with `SetChromeHeight`. Measures the dropdown and **floors** at `L.BANNER_H` rather than forcing that height (**W10**). **Draw it before `TabStrip`.** Returns the dropdown, or nil having drawn nothing. |
| `PageHeader(ctx, spec)` | **W13** | A host-drawn block pinned in the same band, for controls that apply to **every** tab (options-ui-§14). `spec = { height, build = function(ctx, frame) end, divider = <default true> }`. Anchors a `Frame` across `ctx.chrome`, ledgers it, draws the hairline unless told not to, records the widened band in `ctx.__bannerHeight` via `__bannerBand`, reserves it with `SetChromeHeight`, then calls `build` inside a `pcall` — a raising builder is reported and costs the block, not the page. **A page draws at most one chrome block**: this and `PageBanner` both release `__chromeKids` and both write `ctx.__bannerHeight`, so the second call replaces the first. **Draw it before `TabStrip`.** Returns the frame, or nil having drawn nothing. |
| `SetChromeHeight(ctx, height)` | **O10** | Reserve `height` pixels of pinned chrome above the scroll, and re-anchor a live scroll to match. Idempotent. `height <= 0` hides `ctx.chrome`. Call only after the wrap of whatever is being reserved is known. |
| `__scrollTopInset(ctx)` | **O10** | `L.CHROME_GAP + (ctx.chromeHeight or 0)` — the seam `EnsureScroll` and `SetChromeHeight` both read for the scroll's top anchor, so the two cannot disagree. |
| `__layoutTabs(widths, available, gap)` | **W9** | Pure arithmetic: pack tab pixel widths into rows that fit `available`. A tab wider than `available` is placed alone rather than dropped. Returns rows of 1-based indices into `widths`. Test seam for the wrap rule, callable with no widgets. |
| `__tabPlacement(widths, available, gap, top, rowPitch)` | **W10** (signature: **W12**) | Pure arithmetic: the wrap from `__layoutTabs` turned into `{ index, width, x, y }` per tab, plus the row count. `top` is the banner's finished band, which is why row 1 no longer lands on the banner. `rowPitch` is the tab ART's measured height, not the button's. Callable with no widgets. |
| `__tabBand(top, rowCount, tabH, rowPitch)` | **W10** (signature: **W12**) | Pure arithmetic: how many pixels the strip reserves in total, banner included — which is also where the content panel's top edge lands. **(n − 1) pitches plus one whole tab**, because every row but the last is overlapped by the one under it. Took a `rowGap` through 12.11.3 and a `baselineH` through 11.10.3. |
| `__bannerBand(rawHeight, gapTop, ruleH, gapBottom)` | **W10** | Pure arithmetic: the banner's own height widened by the gap, hairline and gap that separate it from the strip (options-ui-§14). What `ctx.__bannerHeight` holds. |
| `__releaseChrome(ctx)` | **W9** | Test seam. Releases everything the page parked in its chrome band. The banner's ledger (`ctx.__chromeKids`) is hidden, unparented and forgotten; **from W14 the strip's furniture is returned to `ctx.__tabPool` / `ctx.__panelPool` instead** — hidden, still parented to `ctx.chrome`, and ready to be dressed again — and `ctx.__tabKids` is emptied as the ledger it now purely is. |
| `__tabArtHeight()` | **W13** | The measured row pitch — the **unselected** tab art's own height, or `TAB_H` where nothing can be measured. Memoized on success only. Published because the invariant a suite has to pin is unassertable without the one number the band and every row offset are both built from. |
| `__resetTabArtHeight()` | **W13** | Forget that measurement. A harness seam; an atlas does not change size mid-session. |
| `RegisterOptionsPage(key, name, builder)` | O1 | Queue a page. Builders run once, in order, at `CreateOptionsPanel`. |
| `CreateOptionsPanel()` | O1 | Resolve AceGUI, hand it to the host, validate, register the main canvas, run every builder. |
| `OpenOptionsPanel()` | O1 (combat refusal: O3) | Open the category. **Refuses** under combat and never defers-and-replays. |
| `RestoreDefaults(pageKey, ctx)` | O1 | The per-page Defaults button. Refreshes only the ctx it was given. **From O16** the page walk runs inside the descriptor's optional `bulkBegin` / `bulkEnd` bracket (act `"reset"`, scope `pageKey`); the refresh runs after it closes. |
| `RestoreAllDefaults()` | O1 | Without `resetProfile`: every non-vetoed row, then `afterRestoreAll`, then a full refresh — unchanged. **With `resetProfile` (O9):** only the `sessionOnly` rows, then `resetProfile()`, then `afterRestoreAll`, then a full refresh. **From O16** everything before the refresh — the row walk, `resetProfile` and `afterRestoreAll` — runs inside the descriptor's optional `bulkBegin` / `bulkEnd` bracket (act `"reset"`, scope `"all"`). |
| `SetRenderer(ctx, fn)` | O1 | Declare how a page draws itself. The library owns *when*: first show, and again after a refresh marked it dirty while hidden. Also builds the Defaults button and refuses to render under combat. |
| `RefreshAllPanels()` | O1 (two tiers: O3) | **Structural.** Re-run each page's renderer, so rows that appeared or disappeared are drawn. Hidden pages are flagged dirty and re-render on their next show. |
| `RefreshScalars()` | O3 | **In place.** Refreshers only, no rebuild — what every widget maker's own `set()` calls, since writing a value does not change which rows exist. Each is pcall'd, so one dead widget cannot take the UI with it. |
| `RefreshPanel(ctx, structural)` | O8 | **One page, either tier.** `structural` true re-runs that ctx's renderer; false runs its refreshers in place. A hidden page is flagged dirty and repaints on its next show, so the caller never has to ask whether it is on screen. For a host whose page repaints off its own message bus rather than off a widget's `set()`. |
| `__pages()` | O1 | The pages that actually built. A raising builder is reported by key and costs only itself. |
| `RenderGrid(ctx, items)` | **W4** | Lay arbitrary widgets out two per row, caller-ordered. The sibling of `RenderRows`: that one walks schema rows and emits sections, this one takes whatever the caller hands it — a schema row, or `{ make = fn }` for a bespoke widget, or `wide = true` for its own line. For a list whose length is not in the schema (one checkbox per macro, per unit, per spell). Items are guarded individually. **Two asymmetries with `RenderRows`, both deliberate today and both tracked:** it does **not** call `scroll:DoLayout()` at the end, so a page rendered through `RenderGrid` alone must call it itself; and it renders into `EnsureScroll(ctx)` with no `parent` override, so it cannot draw into a container the host owns. See [KickCD#10](https://github.com/tusharsaxena/KickCD/issues/10). |
| `ChoiceGrid(ctx, spec)` | **W16** | A matrix of radio cells over rows that share one value list: a header line of column labels, then per row one radio per column and the row's label with its tooltip. Reads and writes through the maker seam and re-syncs on `RefreshScalars`. Returns the row lines. See [The choice grid](#the-choice-grid). |
| `ResolveId(kind, text, candidates)` | **W16** | Pure. Typed text → `id, name, icon`, or `nil, reason` (`"empty"`, `"notFound"`, `"ambiguous"`): a number, a link of the kind's own type, the client's name lookup, then the host's candidates by name. See [The id input and the id list](#the-id-input-and-the-id-list). |
| `IdInput(ctx, parent, spec)` | **W16** | One add-by-id line — an edit box, an Add button and a status line — into `parent`, default the page's scroll. Resolves through `ResolveId` and calls `spec.onAdd(id)`; never writes a path and redraws nothing. Returns the group, the edit box, the button and the status label. |
| `IdList(ctx, spec)` | **W16** | An optional heading, the `IdInput` line, then one line per `spec.entries()` entry — icon, name, gray id, and Remove or a toggle checkbox. Redraws after an add or a remove through `ctx.rebuild`, else `RefreshAllPanels()`. Returns the entry lines. |
| `ColorPair(spec)` | **C1** (`spec.bind`: **C4**) | A color swatch and its *use class color* companion, as exactly two adjacent rows. See [The schema composers](#the-schema-composers). |
| `FontGroup(spec)` | **C1** (`spec.bind`: **C4**) | The canonical six font rows, in the canonical order. Its `font` row's `values` is `O.LSMValues("font")` itself (**C3**). |
| `BorderGroup(spec)` | **C1** (`spec.bind`: **C4**) | The canonical four border rows, optionally preceded by a *Show border* toggle. Its `borderStyle` row's `values` is `O.LSMValues("border")` itself (**C3**). |
| `BarGroup(spec)` | **C1** (`spec.bind`: **C4**) | The canonical four bar rows, for a surface with a **fill texture**. Its `barTexture` row's `values` is `O.LSMValues("statusbar")` itself (**C3**). |
| `MasterControls(spec)` | **C1** (`spec.bind`: **C4**) | The canonical Master controls rows **and** the `afterGroup` hook that draws the tab's closing button pair. Returns two values. Takes `leadButton` since **C2**. Its *Reset all settings* tooltip follows the descriptor's `resetProfile` and `profilesPage` since **C5**. |
| `FONT_FLAGS` / `FONT_FLAGS_SORT` | **C1** | The font-flag key map and its declared order. |
| `VISIBILITY_VALUES` / `VISIBILITY_SORT` | **C1** | The four general-visibility values and their declared order. General visibility is a dropdown, not a boolean: a boolean can only ever answer two of the four. |
| `MASTER_GROUP` | **C1** | The literal `"Master controls"` — the group name, the tab label and the `afterGroup` key are one string, because the group name **is** the hook key. |
| `CLASS_COLOR_NOTE` | **C1** | The sentence every composed swatch's tooltip carries, in place of the `disabledIf` it must never have. |
| `LSMValues(mediaType)` | W1 (never-empty: **W4**) | A **deferred** closure pulling the live media hash at dropdown-render time. Never empty: a media library that has not loaded yet yields a single `None` placeholder, because a dropdown with no options cannot be opened and the CLI would refuse even the stored value. Deferred is load-bearing: LSM-backed rows evaluate this inside a schema-row literal at file load, long before the addons that register media have run. **Since C3 the media composers assign what this returns directly into a row's `values`**, which is why a host that replaces this member must return a function; see [The schema composers](#the-schema-composers). |
| `PatchAlwaysShowScrollbar(scroll)` | S1 | The scrollbar override. Idempotent, and reversed on `OnRelease` — AceGUI pools ScrollFrames, so an unreleased patch escapes into whichever addon recycles the widget next. |
| `ROW_VSPACER` / `SECTION_HEADING_H` / `BUTTON_PAIR_REL` | W1 | The cross-slice layout constants, mirrored onto the instance so a host's own page code stays in lockstep with the engine's spacing. |
| `PADDING_X` | **O7** | The horizontal inset the library draws its own header, divider and body to. Read it to align a bespoke widget with any of the three; **do not restate it** (options-ui-§8). |
| `CHROME_GAP` | **O10** | Gap between the bottom of the chrome band and the top of the scroll (`8`, the literal `EnsureScroll` always used). |
| `TAB_H` | **O10** (value: **O12**) | Height of one row of tabs (`37`), taller than the art it carries — the bottom of a tab is the foot that overlaps the content panel. Was `24` through 11.10.3. |
| `BANNER_H` | **O10** (value and meaning: **O11**) | **Floor** for the page banner (`44`), not a fixed height: `PageBanner` measures its dropdown and takes the larger. |
| `chrome` (on `ctx`) | **O10** | The pinned chrome `Frame`, returned on every `ctx` from `CreatePanel`, inset to `PADDING_X` on both edges. What `TabStrip` and `PageBanner` parent their widgets to. |
| `chromeHeight` (on `ctx`) | **O10** | The pixels of chrome the page has reserved, starting at `0`. Set only through `SetChromeHeight` — never write it directly, or the scroll's anchor and the frame's actual height will disagree. |
| `AceGUI` | O1 | The resolved AceGUI-3.0, or nil. Filled in at `:New` and re-resolved at `CreateOptionsPanel`, which is the copy `onAceGUI` hands the host. |
| `__panels()` / `__panelFor(pageKey)` | O1 | Test seams, following Perf's `__buckets()` idiom. The registry is private, so a host suite otherwise has no handle on a live ctx — and a real bug once shipped precisely because one page's ctx was unreachable. |

## The landing page

New at `OptionsWidgets.lua` minor 6 / `Options.lua` minor 6.

### `O.TextRow(ctx, text, opts)` → widget or `nil`

A full-width AceGUI `Label`, left-justified, added to `O.EnsureScroll(ctx)` and returned. A no-op
returning `nil` when AceGUI or the scroll is absent, like every other maker here.

| `opts` field | Type | Meaning |
|---|---|---|
| `fontObject` | string | A `_G` font-object **name** (`"GameFontHighlight"`), applied only when both `widget.label.SetFontObject` and `_G[name]` exist. A name rather than the object itself, so a host declaring a spec at file load does not have to have resolved a global yet. |
| `justify` | string | Defaults to `"LEFT"`. |

It earns its place independently of the landing page: it owns the
`if w.label and w.label.SetJustifyH then` / `SetFontObject` pair **once**. That pair was written out
per text widget per host — 28 times across six repos — and every copy is a place for one of the two
halves to be forgotten, which fails silently and only in game.

### `O.BuildLandingPage(ctx, spec)`

Renders a whole landing body: `ClearScroll`, then the logo, the one-liner, and a heading plus its
rows per section.

| `spec` field | Type | Meaning |
|---|---|---|
| `logo` | string | Texture path. Omitted = no logo block and no gap under it. |
| `logoSize` | number | Defaults to `lib.LAYOUT.LANDING_LOGO`. |
| `notes` | string **or** function() → string | The one-liner. **A function is called at render time**, because a host reading its own TOC `Notes` cannot resolve it at declaration. Empty or nil skips both the notes block and its spacer. |
| `sections` | array of `{ heading = string, rows = function() → array of string }` | `rows` is a **function**, not an array, for the same reason: a re-render then picks up a command registered since the spec was declared. Feed it `Sl:LandingRows`. |

**The renderer owns the clear, not the registry.** A landing page re-renders on every re-show, and
stacking a second copy of the logo under the first is what happens without it.

Headings go through `O.Section`, rows through `O.TextRow`, gaps through `O.AddSpacer` — so the page
is composed of this major's existing vocabulary and inherits every fix to it.

### The four `lib.LAYOUT` constants

Read off the LibStub table (`LibStub("LibKa0s-Options-1.0").LAYOUT`), not the instance.

| Key | Value | Meaning |
|---|---|---|
| `LANDING_LOGO` | 300 | The logo block's height, and the default `spec.logoSize`. |
| `LANDING_GAP_LOGO` | 8 | The gap under the logo. |
| `LANDING_GAP_DESC` | 12 | The gap under the one-liner. |
| `LANDING_GAP_HEAD` | 6 | The gap under a landing heading. |

All four are promoted verbatim from three hosts that had each declared them and agreed on every
value.

`LANDING_GAP_HEAD` **must stay equal to `SECTION_BOTTOM_SPACER`**, which `O.Section` already emits
under every heading — `BuildLandingPage` therefore does not draw a second one, and the day the two
values diverge every landing heading loses its gap. `tests/test_options.lua` pins the equality.

## The choice grid

New at `OptionsWidgets.lua` minor 16.

### `O.ChoiceGrid(ctx, spec)` → lines or `nil`

| `spec` field | Type | Meaning |
|---|---|---|
| `rows` | array of schema rows | Each carries `path` (or a path-less `get` / `set`), `label`, the tooltip body (`tooltip` or `desc`), and optionally `disabledIf`. Read and written through the same seam every maker uses. Give them `skipRender = true` so the flow engine leaves them to the grid; the grid draws them regardless, and they stay in the schema for the CLI and the resets. |
| `columns` | ordered array of `{ value =, label = }` | One radio cell per entry, in this order. A column with no `label` is headed by its `value`. |
| `heading` | string | Optional. Drawn with `O.Section`, and recorded as `ctx.lastGroup`. |
| `labelHeader` | string | Optional heading for the label column. `"Category"` when absent: a literal, as `lib.STRINGS`' own are, since the library carries no locale. |
| `disabled` | boolean | Optional. Draws every cell and label disabled, as `RenderRows`' `opts.disabled` does. A grid drawn inside a disabled render inherits that render's flag either way. |

Each line is a full-width Flow `SimpleGroup`: a `CheckBox` per column, `SetType("radio")` where the
widget has it, at relative width `0.12`, then an `InteractiveLabel` taking the rest less `0.02`.
The label gives back `0.02` for the reason `BUTTON_PAIR_REL` sits under half: the widget ending at
the right edge is clipped by the ScrollFrame (options-ui-§8).

- A cell is lit while `read(row) == column.value`, and each cell's refresher re-lights it. A stored
  value no column carries lights **none**.
- A click on an unlit cell writes `column.value` through the row's seam, whose `set` runs
  `RefreshScalars`, so every cell on the line re-syncs to exactly one lit.
- A click on the lit cell writes nothing and re-lights it. AceGUI toggles a checkbox on every click,
  a radio-typed one included.
- `disabledIf` dims the row's cells **and** its label, and both re-evaluate on refresh.
- Each line is guarded as a flow row is: a row whose `get` raises is reported through
  `lib.STRINGS.ROW_FAILED`, costs that line, and is left out of the return.

It returns the row lines in row order, not the header. With no AceGUI or scroll it returns nil and
draws nothing.

## The id input and the id list

New at `OptionsWidgets.lua` minor 16. The host owns storage. None of these writes a path: the
widgets call back, and the host keeps whatever stored shape it has.

### `O.ResolveId(kind, text, candidates)` → `id, name, icon` or `nil, reason`

Pure, and needs no ctx. `text` is trimmed first, and a number `text` is taken as its string.

| Step | Resolves | Kinds |
|---|---|---|
| 1 | a number, `^(%d+)$` | all |
| 2 | a link of the kind's own type — `|Hspell:123:…`, `|Hitem:123:…`, `|Hcurrency:123:…` — or the bare `spell:123` / `item:123` / `currency:123`. An item link typed into a spell list is not a spell. | spell, item, currency |
| 3 | the client's name lookup: `C_Spell.GetSpellInfo(name)` → `spellID`; `C_Item.GetItemInfoInstant(name)` → the first return | spell, item |
| 4 | a case-insensitive exact name over the ids `candidates()` returns, named through the kind's own id lookup. Two **distinct** ids with the name → `"ambiguous"`; one id listed twice is one. | spell, item, currency |

`reason` is `"empty"`, `"notFound"` or `"ambiguous"`. A number the client cannot name still
resolves, with no name: that is the degraded mode. Every client API is read at call time and
guarded, so with no `C_Spell` or `C_Item` a number or a link resolves, a name finds nothing, and
nothing raises. A raising `candidates()` costs step 4 and is not reported.

`kind`:

| `kind` | Id → name, icon | Tooltip |
|---|---|---|
| `"spell"` | `C_Spell.GetSpellInfo(id)` | `GameTooltip:SetSpellByID` |
| `"item"` | icon from `C_Item.GetItemInfoInstant(id)` (no cache needed), name from `C_Item.GetItemNameByID(id)` (cache needed) | `GameTooltip:SetItemByID` |
| `"currency"` | `C_CurrencyInfo.GetCurrencyInfo(id)`; an empty name is the client's answer for an id it does not have | `GameTooltip:SetCurrencyByID` |
| a host table | `{ resolve = function(text, candidates) -> id, name, icon \| nil, reason; info = function(id) -> name, icon; noun; plural; tooltip = function(tooltip, id) or a GameTooltip method name }`. `resolve` replaces all four steps, is handed the trimmed text, and is `pcall`'d — a raise or an unknown reason reads as `"notFound"`. | as given |
| anything else | numbers only | none |

### `O.IdInput(ctx, parent, spec)` → group, editBox, button, status

One line, into `parent`, which is the page's scroll when nil: an AceGUI `EditBox` at relative width
`0.78`, with its own Okay button turned off through `DisableButton(true)` where the widget has it,
an Add `Button` at `0.20`, and a full-width status `Label` under both. The two sum to `0.98` for the
clip reason above.

| `spec` field | Meaning |
|---|---|
| `kind` | As `ResolveId`'s. |
| `onAdd` | `function(id)`, called once per successful add. A raise is reported through `lib.STRINGS.BUTTON_FAILED` and counts as a failure: the text stays. |
| `candidates` | Optional `function() -> ids`, searched by name at step 4. |
| `label`, `tooltip` | The edit box's label, and the tooltip on both widgets. |
| `strings` | Optional overrides of the words, by key — see below. |
| `disabled` | Optional; draws both widgets disabled. A disabled render is inherited. |

Enter in the box, or Add, resolves the trimmed text. Success calls `onAdd(id)`, then clears the box
and the status line. Failure writes the reason on the status line in orange (`1, 0.5, 0`), keeps the
text, and calls nothing. **It redraws nothing after an add**: a host that draws its own rows redraws
them itself. It returns nil, drawing nothing, with no AceGUI.

The words, and their defaults. `{name}` tokens rather than format specifiers, so a translation can
reorder them:

| Key | Default |
|---|---|
| `add` | `Add` |
| `remove` | `Remove` (IdList) |
| `empty` | `Type an id, a link or a name.` |
| `notFound` | `No {noun} named '{text}'.` |
| `ambiguous` | `Several {plural} are named '{text}' — use the id.` |
| `unknown` | `Unknown {noun} {id}` (IdList) |

`{noun}` / `{plural}` are `spell`/`spells`, `item`/`items`, `currency`/`currencies`, a host
kind's own `noun` / `plural`, or `entry`/`entries`.

### `O.IdList(ctx, spec)` → lines or `nil`

Everything `IdInput` takes, plus:

| `spec` field | Meaning |
|---|---|
| `entries` | `function() -> ordered { { id =, toggle = bool?, on = bool? }, … }`. A raise is reported through `lib.STRINGS.ROW_FAILED` and costs the lines, not the input. |
| `onRemove` | `function(id)`, from an entry's Remove. |
| `onToggle` | `function(id, on)`, from a toggle entry's checkbox. |
| `heading` | Optional section heading, drawn with `O.Section` and recorded as `ctx.lastGroup`. |
| `emptyText` | Optional line drawn, through `O.TextRow`, when there are no entries. |
| `toggleLabel` | Optional label beside a toggle entry's checkbox. |

It draws into the page's scroll: the heading, the input line, then one line per entry, guarded per
line. Each entry line has an `InteractiveLabel` at `0.78` and the action at `0.20`. The label shows
the entry's icon (16px), its name, and its id in gray, or `Unknown <noun> <id>` when the kind cannot
name it. Hovering it shows the client's own tooltip for that kind. The action is Remove, or a
`CheckBox` for a `toggle` entry (a starter the host can switch off without forgetting it), lit by
`on`.

- **Redraws.** After an add, or a Remove whose `onRemove` returned, the list redraws through
  `ctx.rebuild` when the host set one, and otherwise through `O.RefreshAllPanels()`, which is
  structural, because the set of lines changed. A toggle redraws nothing.
- **Uncached items.** An item the client cannot name yet is asked for once per id per instance,
  through `LibStub("LibKa0s-Item-1.0", true).LoadItem`, looked up at call time. The list redraws
  when the load lands. Without the Item major the entry stays unnamed, and nothing raises.

It returns the entry lines in order. It returns nil, drawing nothing, with no AceGUI.

## Row fields the flow engine reads

Beyond `path`, `type`, `label`, `default` and the tooltip body — `tooltip`, which is what every
Ka0s host's schema declares, or `desc`, this library's own name for it; both are read:

| Field | Since | Meaning |
|---|---|---|
| `group` | W1 | Section heading. A new value emits a `Section` and flushes the row in progress. |
| `solo` | W1 | Render alone in the left half of its own line, for visual pivots. |
| `subgroup` | **W13** | A heading drawn **inside** a group, through `O.Section` (options-ui-§7). Emitted whenever the value changes within a group, and cleared at every group boundary so the same name under two groups draws twice. **Not** suppressed by `opts.noHeadings`, which covers the group heading only: a tab that mixes control types has to name each block, and the tab label is already spent on the section. |
| `wide` | **W13** | Render alone at **full** width, spanning both columns. Not what `solo` does — `solo` renders alone in the left half — and it shares `RenderGrid`'s field name and meaning rather than redefining `solo`. |
| `startsLine` | **W13** | Flush the pending line **before** this row, so a declared two-row pair lands as `[left][right]` and can never be split by an odd number of preceding widgets. |
| `skipRender` | W1 | Keep the row in the schema — so resets and the CLI still see it — but let the host draw it bespoke. |
| `min` / `max` / `step` | W1 | Slider range. Snapping is relative to `min`, not to zero. |
| `values` on a `number` row | **W5** | Makes it a **dropdown** rather than a slider, matching what `LibKa0s-Slash-1.0`'s parser has always understood the shape to mean. Inferred, not opted into — a `values` list that resolves empty falls back to the slider. |
| `values` / `sorting` | W1 (ordered-array shape: W3) | Dropdown list, in either shape: an **ordered array** of `{ value =, text = }` (position is the order, and `sorting` is ignored) or a **key map** `{ KEY = "Label" }` (`sorting` keeps a deliberate order instead of alphabetising). A degenerate key *set* `{ KEY = true }` labels each entry with its key. `values` may be a function, evaluated at render and parse time. |
| `dialogControl` | W1 | An in-tree widget type (`LSM30_*`, `EditBox`). Unregistered types fall back to a plain Dropdown, so an optional media-widget library staying absent costs a swatch, not the option. |
| `hasAlpha` | W1 | Color picker: alpha channel — **default true**, declare `false` to suppress it. |
| `disabledIf` | W1 (every maker, and the predicate form: **W16**) | Draw the row disabled while it holds. A **settings path** whose truth disables (a path-less row reads it through `row.get(key)`), or **from W16** a predicate `function(row) -> bool`, `pcall`'d, whose raise reads as enabled. Through W15 the color picker alone read it; from W16 the checkbox, slider, dropdown, edit box and color picker all do, at build and on every refresh. A row without it is never touched. **`disabledIf` must not be used for a class-color companion** (options-ui-§17, anti-patterns #74): the swatch is still read, for its alpha, so graying it says something untrue. No composed row carries it. |
| `classColorSource` / `classColorUnit` | **C1** | `"player"` or `"unit"`, plus the token where it is `"unit"`. Stamped on **both** rows of every composed color pair. The library reads neither — they are the declaration an audit reads, because a path prefix cannot be trusted to say whose class a control means (options-ui-§17). |
| `commitOn` | W1 | `"change"` makes this slider commit on the drag, throttled; `"release"` opts out of a descriptor-wide `sliderCommit`. Default is release-only. |
| `isPercent` | W1 | Slider renders a 0–1 ratio as a percentage. |
| `maxLetters` | W1 | Edit box only. |
| `get` / `set` | **W15** | On a row with **no `path`** only: the row is read with `row.get()` and written with `row.set(value)` instead of through the descriptor's `get` / `set`. `row.get(key)` with an argument reads another key on the row's behalf: the flow engine resolves a path-less row's `disabledIf` that way, and a composed row reads that field of the same record. What a composer's `spec.bind` produces; a hand-written record row may carry them too. A row that has a `path` is always read and written through the descriptor, whatever else it carries. |
| `field` | **C4** | On a row a composer bound with `spec.bind`: the record key the row reads and writes, exactly what its path would have been. The flow engine reads it to name the row in the empty-dropdown report, and as the row's `pairWith` key — `RenderRows` looks a partner up by `row.path or row.field` (**W15**). |

## The schema composers

New at `OptionsCompose.lua` minor 1. Five functions, each expanding one declaration into the
canonical block of **ordinary schema rows** — options-ui-§15 for the Master controls tab, §16 for the
font / border / bar groups, §17 for the class-color companion.

**They are pure functions.** No widget, no AceGUI, no state, and nothing the caller handed in is ever
written to — a host may hoist its spec, and its `extra` rows, to a file constant and re-render
freely. What comes out is indistinguishable from hand-written rows, which is what lets every existing
seam keep working unchanged.

**Since C4 a composer can also bind its rows to a registry record** (`spec.bind`, below). A bound
row is still an ordinary table and the composer still reads no state — the row's `get` and `set`
closures read and write the record when the flow engine calls them — but a bound row has no path, so
it is rendered directly and never put in the schema.

### The media rows, and what a host's own `LSMValues` must return

`FontGroup`, `BorderGroup` and `BarGroup` each carry one LSM-backed dropdown — `font`,
`borderStyle`, `barTexture` — and each assigns `O.LSMValues(<mediaType>)` **as** the row's `values`
(**C3**). Not a closure around it: `enumList` unwraps `values` exactly once, so a second wrapper
reaches it as a function and the dropdown comes back empty with no report.

That makes `O.LSMValues` part of the composer's contract rather than an implementation detail of one
row. A host that supplies its own — `__AttachCompose` reads the member off the instance it is handed
— **must return a function**. Return a table and the composer stores that table, frozen at the
moment the schema file loaded, before any addon that registers media has run. Nothing errors and
nothing warns; the dropdown simply never learns about anything registered later.

A host that overrides a composed row's `values` after the composer returns is unaffected, and so is
one that never touches `O.LSMValues` at all — which is every consumer that just calls the composers.

### The common spec

Every composer takes these, and each is optional except `page` and `group` in practice:

| Field | Type | Meaning |
|---|---|---|
| `prefix` | string | Path prefix, e.g. `"units.target."` or `""`. Each canonical row's path is `prefix .. leaf`. |
| `page` | any | Copied onto every row. |
| `group` | string | The tab name, copied onto every row. `MasterControls` defaults it to `"Master controls"`. |
| `subgroup` | string | The intra-tab heading, copied onto every row. |
| `order` | number | Order of the first row; each subsequent row `+10`. Ten, so a host can splice a row of its own between two canonical ones without renumbering either. Defaults to `0`. |
| `keys` | table | `{ <canonicalLeaf> = "myLeaf" }` — path-leaf overrides. **The composer must not change what is stored**, and this is the override that protects a live SavedVariables. |
| `labels` | table | `{ <canonicalLeaf> = "My label" }` — host-localised label overrides. |
| `defaults` | table | `{ <canonicalLeaf> = <value> }` — default overrides. |
| `omit` | table | `{ <canonicalLeaf> = true }` — leave the row out. The survivors stay contiguous, so an omission leaves no hole in the order. |
| `classColor` | table | `{ source = "player" \| "unit", unit = <token>, default = <boolean> }`. Stamped on both rows of every color pair. |
| `extra` | array | Rows appended **after** the canonical block, order continuing, copied rather than stamped in place. An extra declares its own `path` in full — or, under `bind`, its own record `field` (**C4**). |
| `bind` | table | **C4.** `{ set, get \| record }` — bind every row to a registry record instead of a settings path. See [The record-backed arm](#the-record-backed-arm-specbind). |

### The record-backed arm: `spec.bind`

New at `OptionsCompose.lua` minor 4, read by `OptionsWidgets.lua` minor 15.

| Field | Type | Meaning |
|---|---|---|
| `bind.set(field, value, row)` | function | **Required.** Write `value` to the record's `field`. The row is handed through so a bind can convert by `row.type`. |
| `bind.get(field, row)` | function | Read the record's `field`. Read the **live** record here, not one captured when the block was composed. |
| `bind.record()` | function | Instead of `get`: answer the live record, and `get` becomes `record()[field]`. |

What a bound row carries, in place of `path`:

| Field | Value |
|---|---|
| `field` | `(prefix or "") .. (keys[leaf] or leaf)` — or an extra's own `field` |
| `get` | `function() return bind.get(field, row) end` |
| `set` | `function(value) return bind.set(field, value, row) end` |

A missing `set`, or a bind with neither `get` nor `record`, raises when the block is composed.

#### Worked example: PanelMaster's three groups

`settings/PanelEditor.lua` in PanelMaster types out three `options-ui-§16` groups over a panel
record — at `b884ca8`, `:776-790` (the panel's border), `:818-838` (the accent bar) and `:852-866`
(the accent bar's own border); PanelMaster#48 cites the same three blocks at `:738-757`, `:770-800`
and `:814-830`, where they sat when it was filed. All three compose. `tests/test_options_compose.lua`
builds exactly these three blocks against a stand-in registry and asserts the field order, the
binding and a write through it, so this example is checked rather than illustrative.

```lua
-- Inside buildPanelEditor(ctx, parent, rec). `O` is NS.Helpers, the lib:New instance; `group`,
-- `editorRow`, `editorSpacer` and EDITOR_ROW_GAP are the editor's own, unchanged.

-- ONE bind for all three blocks. It reads the LIVE record by id -- a profile switch replaces the
-- panel tables, which is why the hand-written refreshers look the record up again -- and writes
-- through NS.Registry:Set, the registry writer architecture-§5 names. Panel colors are stored as
-- { r, g, b, a } arrays and the descriptor codec reads named keys, so the bind converts the one row
-- type whose shape differs.
local function recordBind(rec)
  local function live() return NS.Registry:Get(rec.id) or rec end
  return {
    get = function(field, row)
      local v = live()[field]
      if row.type ~= "color" then return v end
      local c = NS.Util.Color(v)
      return { r = c[1], g = c[2], b = c[3], a = c[4] }
    end,
    set = function(field, v, row)
      if row.type == "color" then v = { v.r, v.g, v.b, v.a } end
      NS.Registry:Set(rec.id, field, v)
    end,
  }
end

-- The editor draws into its own container, two controls to a line. A composed block's first and
-- third rows carry startsLine, so pairing them in twos IS the canonical layout.
local function renderBlock(rows)
  for i = 1, #rows, 2 do
    local line = editorRow(group)
    O.RenderField(ctx, rows[i], line, 0.5)
    if rows[i + 1] then O.RenderField(ctx, rows[i + 1], line, 0.5) end
    editorSpacer(group, EDITOR_ROW_GAP)
  end
end

-- Composed rows are fresh plain tables, so the page may retune one before drawing it. This
-- addon's border reaches C.MAX_BORDER (32), not the composer's 16, and its media lists come from
-- NS.Compat.MediaList, which carries its own 'Solid' and 'None', rather than from O.LSMValues.
local function mediaValues(kind)
  return function()
    local list = {}
    for _, name in ipairs(NS.Compat.MediaList(kind)) do list[name] = name end
    return list
  end
end

local bind = recordBind(rec)

-- 1. The panel's own border (TAB_SURFACE).
local border = O.BorderGroup{
  bind = bind,
  keys = { borderStyle = "borderTexture", borderSize = "borderSize",
           borderColor = "borderColor", useClassColorBorder = "borderClassColor" },
  extra = { { field = "borderOffset", type = "number", label = "Border offset",
              min = C.MIN_BORDER_OFFSET, max = C.MAX_BORDER_OFFSET, step = 1,
              tooltip = "How far the border sits from the panel's edge." } },
}
border[1].values = mediaValues("border")
border[2].max = C.MAX_BORDER
renderBlock(border)

-- 2. The accent bar (TAB_ACCENT). Its "Enable accent bar" toggle stays the page's own row above the
--    block: only a border's "Show border" may lead a composed block (options-ui-§16).
local bar = O.BarGroup{
  bind = bind,
  keys = { barTexture = "accentTexture", barAlpha = "accentAlpha",
           barColor = "accentColor", useClassColorBar = "accentClassColor" },
  extra = {
    { field = "accentThickness", type = "number", label = "Bar thickness",
      min = C.MIN_ACCENT_THICKNESS, max = C.MAX_ACCENT_THICKNESS, step = 1 },
    { field = "accentOffset", type = "number", label = "Bar offset",
      min = C.MIN_ACCENT_OFFSET, max = C.MAX_ACCENT_OFFSET, step = 1 },
  },
}
bar[1].values = mediaValues("statusbar")
renderBlock(bar)

-- 3. The accent bar's own border (TAB_ACCENT, after the Edges heading).
local barBorder = O.BorderGroup{
  bind = bind,
  keys = { borderStyle = "accentBorderTexture", borderSize = "accentBorderSize",
           borderColor = "accentBorderColor", useClassColorBorder = "accentBorderClassColor" },
  extra = { { field = "accentBorderOffset", type = "number", label = "Border offset",
              min = C.MIN_BORDER_OFFSET, max = C.MAX_BORDER_OFFSET, step = 1 } },
}
barBorder[1].values = mediaValues("border")
barBorder[2].max = C.MAX_BORDER
renderBlock(barBorder)
```

The three blocks come out as:

| Block | Fields, in order |
|---|---|
| Panel border | `borderTexture` · `borderSize` · `borderColor` · `borderClassColor` · `borderOffset` |
| Accent bar | `accentTexture` · `accentAlpha` · `accentColor` · `accentClassColor` · `accentThickness` · `accentOffset` |
| Accent bar border | `accentBorderTexture` · `accentBorderSize` · `accentBorderColor` · `accentBorderClassColor` · `accentBorderOffset` |

— the order the editor draws today, with the mandated four first and the addon's own rows after them.

**What adoption changes on screen, for PanelMaster to decide.** The canonical tooltips replace the
page's longer ones (a host may retune `tooltip` the same way it retunes `max`). *Bar opacity* renders
as a percentage, because the canonical row carries `isPercent`. And the swatch stops relabeling itself
*Border color (opacity)* while its companion is ticked: the composed swatch says the same thing in its
tooltip, in `O.CLASS_COLOR_NOTE`'s words, which is the form `options-ui-§17` fixes. The
`dd:SetValue(value)` push the hand-written media dropdown needs after an AceGUI-3.0-SharedMediaWidgets
change is not needed: the flow engine's `set` runs `RefreshScalars`, and the refresher re-applies
the value.

### `O.ColorPair(spec)` → rows

The primitive the three group composers are built out of, and what a host calls for a standalone
swatch. Additionally takes `key` (the swatch leaf, default `"color"`), `companionKey` (default
`"useClassColor" .. Key`), `label` (default `"Color"`) and `hasAlpha` (default true).

Returns **exactly two** rows: the swatch, carrying `startsLine = true`, and the `Use class color`
checkbox immediately after it — which is what puts the companion in the right-hand column and what
makes that placement impossible to break by inserting a row above the pair.

**Neither row ever carries `disabledIf`,** and that is a recorded reversal of two addons' shipped
behavior: the swatch's **alpha** is live under class color, so a grayed swatch is a lie. The swatch's
tooltip carries `O.CLASS_COLOR_NOTE` instead — *"Not read while Use class color is on, except for its
opacity, which always applies."*

### `O.FontGroup(spec)` → rows

Six leaves, in this order, landing as three lines:

| | |
|---|---|
| `font` (`LSM30_Font`) | `fontSize` |
| `fontColor` | `useClassColorFont` |
| `fontFlags` | `fontShadow` |

An even row count plus `startsLine` on rows 1 and 3 is what makes that layout parity-proof rather
than a property of how many rows happen to precede the block.

### `O.BorderGroup(spec)` → rows

`borderStyle` (`LSM30_Border`), `borderSize` (*Border thickness (px)*), `borderColor`,
`useClassColorBorder`. `spec.show = true` prepends `borderShow` (*Show border*), which is the only
thing that may lead the block. A border offset or anything else the addon legitimately has goes in
`spec.extra`, **after** the mandated rows, never interleaved.

### `O.BarGroup(spec)` → rows

`barTexture` (`LSM30_Statusbar`), `barAlpha` (*Bar opacity*, a percentage), `barColor`,
`useClassColorBar`.

**A group over a background is not a bar group.** A container with a backdrop and no fill texture
takes `O.ColorPair` and nothing else; inventing a texture picker for a surface that has no texture is
a control wired to nothing.

### `O.MasterControls(spec)` → rows, afterGroup

The canonical General-page tab (options-ui-§15). Additionally takes `addonName` (for the *Enable*
label), `frameless`, `debugConsolePath` (default `"state.debugConsole"`), `onResetPosition`,
`onResetAll` and — since **C2** — `leadButton`.

| | |
|---|---|
| `enabled` — *Enable `<AddonName>`* | `visibility` — *General visibility* |
| `scale` — *Master scale* | `alpha` — *Master alpha* |
| `locked` — *Lock frame* | `debugConsole` — *Debug console* |
| *Reset position* (button) | *Reset all settings* (button) |

- **The set is canonical, not a menu.** An addon includes every row that applies to it and must not
  reorder, rename or split them.
- **`frameless = true` omits exactly the frame-only rows** — `scale`, `alpha`, `locked`, and the
  *Reset position* button — and nothing else. General visibility stays: `Never` is a meaningful
  master off-switch distinct from *Enable*. A frameless addon must not invent a movable frame to fill
  the tab out.
- **`visibility` is a dropdown**, over `O.VISIBILITY_VALUES` / `O.VISIBILITY_SORT`. An addon shipping
  a *show only in combat* boolean migrates it (`true` → `"inCombat"`, `false` → `"always"`), because
  a boolean can only ever answer two of the four.
- **`debugConsole` is `sessionOnly`**, and its path is taken **verbatim** rather than prefixed:
  session state lives outside the block's own prefix.
- **`leadButton` = `{ text, tooltip, onClick }`** (**C2**) is ONE act of the host's own, closing the
  tab beside the resets. On a **frameless** addon it takes the pair's empty right half, so the row
  reads `[<verb>] [Reset all settings]`; on a **framed** addon, whose pair is already full and may
  not be split or reordered, it takes its own row **above** the pair. It exists so an addon never has
  to restate the reset's canonical wording in order to sit a button next to it.
- **The two resets are the tab's closing button pair**, not schema rows — they are acts rather than
  settings, so they would not belong in the CLI or in the reset sweep. The second return value is the
  `afterGroup` hook for the group; wire it as
  `H.RenderTabbedSchema(ctx, page, { ["Master controls"] = tail }, pairWith)`. The **group name is
  the hook key**, so renaming the group detaches the hook.
- **The *Reset all settings* tooltip comes from the descriptor, not the spec** (**C5**). Without
  `resetProfile` it reads *"Restore every setting in this addon to its default."*; with it, that
  the current profile is reset and other profiles are not affected; with `profilesPage` as well,
  that it is the same thing Profiles → Reset Profile does. See
  [Previously, at 18.15.5.3](#previously-at-1815553). *Reset position*'s tooltip is
  unchanged.

## Compatibility

The API is **additive-only**: a member, descriptor field or row field may be added in a later minor,
never removed or repurposed, so a host written against `1.1.1` keeps working unmodified here. Four
instance members are added at this version, one row field widens, and nothing is taken away.

**What is added at 18.16.5.3 is four instance members, `disabledIf` on every maker, and
`RenderRows`' `opts.disabled`.** A host that calls none of the four, passes no `opts.disabled`, and
carries `disabledIf` only on color rows (as a path) renders as it did at 18.15.5.3. Two things move
underneath it. First, `RenderRows` now re-raises an escaping hook error from its own frame, with
the same value. Second, a hand-written degradation stub of this instance owes four more members:
`Kit.assertSurfaceParity` names them on the re-vendor, and each consumer adds them in that commit.

**What moves at 18.15.5.3 is one tooltip, and what is added is `profilesPage`.** A host that
supplies no `resetProfile` renders byte-identically to 17.15.4.3. A host that supplies it sees the
*Reset all settings* tooltip say "current profile", and nothing else moves. Adopting the field is
one line on the descriptor, for a host that ships a Profiles page.

**What is added at 16.15.4.3 is `bulkBegin` / `bulkEnd` on the descriptor, and nothing else.** A host
that supplies neither runs `RestoreDefaults` and `RestoreAllDefaults` exactly as 15.15.4.3 did — the
same `applyDefault` calls in the same order, the same refresh, and no `pcall` on the path, so a
raising row still escapes with its own stack. That is pinned in `tests/test_options_bulk.lua` and was
measured on all ten consumers with the payload dropped in: nothing moves on re-vendor. Adopting it is
two descriptor fields and a mute in the host's write seam, per [the worked
example](#worked-example-mute-the-seam-emit-one-line).

**What is added at 15.15.4.3 is `spec.bind` on every composer, and `get` / `set` / `field` on a row
with no path.** A host that passes no `bind` and renders no path-less row renders byte-identically to
15.14.3.3: the composers' path-keyed output is pinned against a record taken from compose minor 3, and
the flow engine's record branch opens only for a row whose `path` is nil. The re-vendor is the whole
adoption for every consumer but PanelMaster, whose adoption is the worked example above.

**What is added at 15.14.3.3 is `lib.__PatchLSM30Border()`, and nothing in this library calls it.** A
host that ignores it renders byte-identically to 14.14.3.3, so the re-vendor on its own is a no-op —
which is deliberate, because the addons this member is for have five private copies of the same patch
to retire and that retirement cannot be proved out of game. The order is: re-vendor and add the call
with every local copy still in place, confirm in the client with all five addons loaded that no
Border dropdown depends on load order, then delete the copies one repository per commit. See
[What changed at this version](#what-changed-at-this-version).

**What moved at 14.14.3.3 is a lifetime, and nothing else.** The tab strip's buttons and the page's
content panel are recycled rather than rebuilt on every click, so an options panel stops leaking one
set per click. Every published member, signature and return value is identical to 14.13.3.3, the
strip renders the same pixels, and **the adoption step is the re-vendor and nothing more**. The one
thing to know is the new hard floor: `OptionsWidgets.lua` requires `LibKa0s-Pool-1.0` minor ≥ 1, which
ships in the same payload and loads before it, so whole-folder re-vendoring satisfies it by
construction.

**What moved at 14.13.3.3 is behaviour, and it moved in the direction of working.** The three
composed media dropdowns populate. A consumer that worked around the empty lists — by overriding a
composed row's `values`, or by patching `fixMediaValues`-style over the block — keeps working, and
its workaround is now dead code it can delete on its own schedule.

**The single incompatibility on this path is a host-supplied `O.LSMValues` that returns a table.** It
must return a function; see [The schema composers](#the-schema-composers). This was the only adoption
step 14.13.3.3 asked of anybody, it cannot be detected at runtime, and it fails silently, so a host
coming from 14.13.2.3 or earlier checks it before re-vendoring rather than after.

**One behavior change is visible without a code change**, and it is deliberate: a page rendered
through `RenderTabbedSchema` whose rows declare exactly **one** group now draws a one-tab strip and
its content moves down by the band. A page with two or more groups is byte-identical, and a page that
never called `RenderTabbedSchema` is untouched.

**`ctx.__tabArtH` is gone.** It was a `__`-prefixed internal read by nothing outside
`OptionsWidgets.lua` — grepped across `tests/` and all nine consumers — and it is named here only
because a host that reached for it anyway would find nothing.

A consumer that calls none of the chrome surface still renders byte-identically to 9.8.3, for the
reason it always did: `ctx.chromeHeight` starts at `0`, so `EnsureScroll`'s anchor computes to the
same `CHROME_GAP` (`8`). A consumer that draws a banner but no strip gets no content panel, because
`TabStrip` is the only thing that draws one.

**A vendored folder holding `Options.lua` 14 but no `OptionsCompose.lua`** degrades to no composers
rather than erroring at `:New` — the attach call is guarded exactly as the other two are. The
re-vendor is whole-folder, so that state should never ship.

**`lib.LAYOUT` is not itself part of the instance surface, and will not become so.** The keys a host
may read are the individual scalars listed above. The rest are internal, each annotated in the source
with why, and each is published — as its own scalar — the day a host demonstrates it needs it.
Publishing the table would hand every host a mutable handle on every other host's spacing.

The **four** files move as one. A consumer holding `Options.lua` from one vendored copy and
`OptionsWidgets.lua` from another is not a supported state and LibStub cannot detect it — which is
why `docs/releasing.md` mandates whole-folder re-vendoring.
