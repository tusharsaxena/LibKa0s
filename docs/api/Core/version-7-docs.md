# `LibKa0s-Core-1.0` — version 7

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Core surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Core-1.0` |
| Files and minors | `Core.lua` minor **7** |
| Shipped in | v1.24.0 |
| Status | **Current** |
| Supersedes | [version 6](./version-6-docs.md) |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Core-1.0").MODULES` → `{ Core = 7 }` |

`Since` in the tables below is the Core minor in which the member first appeared. Minors 1 and 2
were never tagged, so they have no document of their own — a `Since` of 1 or 2 means "present for
as long as any consumer could have had this major".

## What changed at this version

**Two new lib-level members, and nothing else moves.** Every other member, value and behavior is
byte-for-byte what version 6 shipped, so a host that does not call the new pair needs a re-vendor
and no code change.

| | | Since |
|---|---|---|
| `ClassColor(unit)` | The class color of a unit, as three numbers, or **`nil`**. `unit` defaults to the player. | **7** |
| `ResolveColor(stored, on, unit)` | Resolve a stored swatch through its *use class color* companion. Four numbers out, always. | **7** |

### The one class-color resolver

Every addon in the collection is growing a *use class color* companion beside every color swatch it
draws (`options-ui-§17`), and each was about to answer the same three questions its own way. Three
implementations already existed and **two of them disagreed about the source**: AbsorbTracker read
`C_ClassColor.GetClassColor`; PanelMaster and MultiMeters read `RAID_CLASS_COLORS`.

`RAID_CLASS_COLORS` wins, and not by coin toss — it is the table every other UI on the player's
screen is already reading, so it is what the unit frames next to ours are showing.

**`nil` is an answer.** An NPC, an out-of-range unit, a token the client rejects, a class the palette
half-knows (an entry with a hex string and no channels) — none of them is a color, and substituting
one invents a hue nobody chose that appears only in the cases nobody tests. Every caller falls
through to the stored swatch instead.

**What is cached, and what is not.** The *player's* own answer is memoized, because a class cannot
change inside a session — and **on success only**, so a class the client has not answered for yet
resolves on the next read rather than being pinned `nil`. **No other unit is ever cached.** A
target's class changes every time the player retargets, and a per-unit cache would need invalidating
on `PLAYER_TARGET_CHANGED` and `PLAYER_FOCUS_CHANGED` to save one table index. `lib.__ResetClassColor()`
forgets the memo; it is a suite seam and a session cannot want it.

`UnitClass` is called inside a `pcall`, because the token is the **caller's**: a unit string the
client rejects raises rather than answering nil, and one bad token must cost this color rather than
the frame being repainted.

### `ResolveColor(stored, on, unit)` — three rules, ratified

All three were already unanimous across the three implementations this replaces, and written down in
none of them:

1. **The configured alpha survives the mode.** No class-color source carries an alpha, so the
   swatch's is always the one used.
2. **An unresolvable class falls through to the stored swatch**, never to a default color.
3. **The swatch is read under both modes**, which is why a color row must never be `disabledIf` its
   companion (`anti-patterns #74`). Setting the color before turning the mode on is the normal order
   of operations, and a disabled control makes it a two-visit job. The panel says it in the swatch's
   tooltip instead.

`stored` goes through `lib.RGBA`, so both persisted shapes — keyed and positional — work here exactly
as they do everywhere else; a host with a codec of its own may decode first, but does not have to.
The defaults are `1, 1, 1, 1`.

**Which unit is passed is the host's call**, and it is the class-color rule's whole content: the unit
the surface **describes**, never the unit whose settings table the value was read from. A per-unit
cast bar or label passes its tracked unit; a player-owned display that merely lives under a
`units.<unit>.` path — an interrupt icon, a ready glow, a mirrored bar — passes `nil`. Because a path
prefix cannot be trusted to say which it is, the schema composers stamp `classColorSource` on both
rows of every pair, and that declaration is what an audit reads.

**Not moved into the library:** AbsorbTracker's darkened per-class *background* palette. That is a
different set of hues, not the class color times a constant, and the two must not be substituted for
each other. A background swatch resolves through the addon's own palette where it has one, and
through `ResolveColor` where it does not.

### Which close control you get

**The argument is a name and not a boolean** because a texture path is absolute from
`Interface\AddOns\` and this library is **vendored**: there is no one path to it, there are as many
as there are consumers, and a copy cannot know which folder it was copied into. Core cannot ask
Media for a path without being told that, and it must not guess — a wrong texture path draws nothing
and raises nothing.

**The × is not a legacy spelling to migrate away from.** It is what a caller that has not been
updated gets, what a host without the Media module gets, and what an install missing the art gets.
All three are the same branch, which is why there is no separate degraded path to keep working.

Either way the control is **18×18** — every window in the collection lays its title bar out around
that number, and `LibKa0s-DebugLog-1.0` derives two more offsets from it. The art is inset to 12px
inside that slot, because a glyph that reaches its own edges reads far heavier than the title beside
it. Both spellings are gray at rest (`0.7, 0.7, 0.72`) and red under the pointer (`1, 0.3, 0.3`).

The Media lookup happens at **call** time, not at load: Core is the first file in `LibKa0s.xml` and
Media the second, so a load-time lookup would answer nil for the life of the session.

## What this major is

Two seams that have nothing to do with each other except that both are tiny, stateless and wanted by
everything. The **secret-safe seam**: a value WoW protects in combat survives `tostring()` and the
`..` operator and raises only inside `table.concat`, so a detector has to probe the operation that
actually rejects it. The **window chrome seam**: a debug console and a perf panel that each draw
their own lookalike backdrop drift apart one hex digit at a time, so the values are shared rather
than copied. On top of both sits the prefixed chat printer, the one instance-shaped thing here.

Core depends on LibStub and nothing else — no Ace3 — which is what keeps `LibKa0s-Perf-1.0`
adoptable by addons that are not on the Ace substrate even now that Perf requires it.

Everything on the cross-module path is a lib-level function, never a handed-around instance: a
stateless function that exists at minor 1 still exists at minor 9, which makes "a Core from any
vendored copy works with a caller from any other" true by construction.

## Lib-level surface

Read straight off the LibStub table — `LibStub("LibKa0s-Core-1.0").SafeToString(v)`.

| Name | Since | Meaning |
|---|---|---|
| `IsConcatSafe(v)` | 1 | Whether `v` survives the `table.concat` every emitted line ends in. Probes `table.concat` itself, not `..` — `..` silently propagates secretness and reports a secret as safe. |
| `SafeToString(v)` | 1 | Concat-safe stringifier. Ordinary values → `tostring(v)`; an un-concatenable (secret) value → `lib.SECRET`. `nil` and booleans are answered up front, so they are never masked. |
| `SECRET` | 1 | What an un-renderable value renders as (`"<secret>"`). Exported so a host's tests, its docs and this implementation cannot drift apart. |
| `SKIN` | 1 | The one skin every Ka0s window wears. **Values changed at minor 3** and three keys were added — see [The skin table](#the-skin-table). Backdrop fields and every colour travel in one table, because taking the backdrop without the colours is exactly the drift this prevents. |
| `ApplySkin(frame[, skin])` | 1 (2nd arg: 3) | Wear the skin. Makes the three calls a table cannot describe as well as the backdrop: the inner-border child frame (built once, re-tinted after), the title tint and the divider tint — each guarded on the skin key AND the frame member, so a window with no divider is fine. `skin` defaults to `lib.SKIN`; it exists so DebugLog's `skin` override reaches one implementation. A no-op on a frame with no `SetBackdrop`: undecorated is not broken. |
| `RGBA(c, dr, dg, db, da)` | 4 | Read a stored color in **either** shape the collection persists — keyed `{ r =, g =, b =, a = }` or positional `{ r, g, b, a }` — and return four **numbers**, never a table. See [Reading a stored color](#reading-a-stored-color). |
| `ClassColor([unit])` | **7** | `r, g, b` for the unit's class, out of `RAID_CLASS_COLORS`, or **`nil`** where there is no class color to give. `unit` defaults to `"player"`, whose answer is memoized on success; no other unit is cached. See [The one class-color resolver](#the-one-class-color-resolver). |
| `ResolveColor(stored, on[, unit])` | **7** | `r, g, b, a` for a stored swatch read through its *use class color* companion. The stored alpha always applies; an unresolvable class falls through to the stored rgb. See [`ResolveColor(stored, on, unit)` — three rules, ratified](#resolvecolorstored-on-unit--three-rules-ratified). |
| `__ResetClassColor()` | **7** | Forget the memoized player color. A suite seam — `__`-prefixed, and a live session cannot need it. |
| `MakeCloseButton(parent, onClick[, addonName])` | 1 (3rd arg: **6**) | The close control a Ka0s window closes with, returned unanchored for the caller to place. Returns `nil` where `CreateFrame` is unavailable (headless harness, or a load path with no UI). With `addonName` it draws the collection's own `close` icon; without, the multiplication sign. See [Which close control you get](#which-close-control-you-get). |
| `MODULES` | 1 | `{ Core = <minor> }` — the live minor of every file in this major. The in-game answer to "which version am I actually running?", and the value that picks this document. |
| `lib:New(descriptor)` | 1 | Build a prefixed chat printer for one host. See below. |

### The skin table

`lib.SKIN` at minor 3. The values are part of the contract: a host that hard-codes a matching
backdrop instead of reading this table is the drift the table exists to prevent.

| Key | Value at minor 3 | Note |
|---|---|---|
| `bgFile` | `Interface\Buttons\WHITE8x8` | unchanged since 1 |
| `edgeFile` | `Interface\Buttons\WHITE8x8` | **changed at 3** — was `Interface\Tooltips\UI-Tooltip-Border` |
| `edgeSize` | `1` | **changed at 3** — was `12` |
| `insets` | `{ left = 1, right = 1, top = 1, bottom = 1 }` | **changed at 3** — was `3` on every side |
| `bg` | `{ 0.06, 0.06, 0.08, 0.92 }` | **changed at 3** — was `{ 0.06, 0.06, 0.07, 0.95 }` |
| `border` | `{ 0, 0, 0, 1 }` | unchanged since 1 |
| `innerBorder` | `{ 0.24, 0.24, 0.27, 0.85 }` | **new at 3** |
| `divider` | `{ 0.24, 0.24, 0.27, 0.85 }` | **new at 3** |
| `title` | `{ 1.0, 0.82, 0.0 }` | **new at 3** |

A host on Core 3 that passes its own `applySkin` to DebugLog is now overriding a default that
already draws the full Ka0s edge — see the DebugLog docs for why that is usually the wrong answer.

## Reading a stored color

`lib.RGBA(c, dr, dg, db, da) -> r, g, b, a`, new at minor 4.

The collection persists colors in **both** shapes, and neither can be retired without migrating
users' SavedVariables — so a reader that handles both is permanent rather than transitional:

| Shape | Written by |
|---|---|
| keyed `{ r =, g =, b =, a = }` | AbsorbTracker, KickCD, `LibKa0s-Slash-1.0`'s color parser |
| positional `{ r, g, b, a }` | the Ka0s options color widget |

The rules, in order:

1. A non-table (`nil` included) yields the four defaults, unchanged.
2. Any of `c.r` / `c.g` / `c.b` present means the **keyed** shape wins for all four channels — so a
   `{ r = 1 }` cannot silently borrow its green from `c[2]`.
3. Otherwise the positional shape.
4. Each channel falls back **independently**, so a three-element color still gets its alpha.

Absence is tested with `== nil`, not `or`. That is what makes a stored `false` survive: `or` would
swallow it and hand back the default. A stored `0` was never at risk: `0` is **truthy** in Lua, so
`(0 or 99)` evaluates to `0` and the `or` chain this replaced already returned it. `false` and `nil`
are the only two values `or` swallows.

The four defaults are **per-channel parameters and are deliberately not defaulted here.** The call
sites across the collection genuinely disagree — `0,0,0,1` for a chat echo, `1,1,1,1` for a swatch,
a per-widget tint elsewhere — and inventing a house default would silently recolor one of them.

Nothing is allocated: four numbers in, four numbers out, which is what makes it safe on a repaint
path.

**Why it is in Core.** This library itself had two disagreeing readers: `LibKa0s-Slash-1.0`'s
`FormatValue` read both shapes, `OptionsWidgets`' `decodeColor` read only the keyed one — so the
library's own CLI could render a color its own widget could not decode. One decoder ends that.

**Neither of those two call sites has adopted it yet, and that is deliberate.** `Slash.lua` and
`Options.lua` declare `NEEDS_CORE = 1`, and [`../../releasing.md`](../../releasing.md) treats
raising that floor as a breaking change to the *vendoring*: every consumer whose `libs/` still holds
an older `Core.lua` would lose the whole major until it is re-vendored. It is the same reason
`enumList` is duplicated verbatim between two majors rather than hoisted. So `lib.RGBA` ships for
hosts now; the library folds its own copies in only alongside a floor raise made for other reasons.

## What changed at this version

**Comments only. The surface does not move.** Every member, descriptor field, row field, value and
behaviour described below is exactly what version 4 shipped, so a host written against version
4 is correct here unmodified and there is nothing to migrate.

`Core.lua`'s comments and docstrings were rewritten to US English — `colour` → `color`,
`behaviour` → `behavior`, `synthesised` → `synthesized`, `normalised` → `normalized`,
`recognise` → `recognize`. `localization-§5` mandates US English and anti-pattern #46 names code
comments explicitly. **No identifier, no key, no user-visible string and no Blizzard symbol moves**,
and `tests/test_prose.lua` fails the run on a regression. `lib.SKIN`'s keys and values are
untouched, so nothing redraws.

The bump exists because the file's bytes changed and LibStub decides which vendored copy wins by
comparing minors: a minor that does not move is a minor that does not ship, so a consumer already
carrying version 4 would keep running it and never receive the corrected source. That is why a
comment-only change still bumps — see [`docs/releasing.md`](../../releasing.md) step 2.
## The printer descriptor

Everything a host supplies to `lib:New(descriptor)`.

| Field | Type | Required | Since | Meaning |
|---|---|---|---|---|
| `prefix` | string or function | yes | 1 | The tag, **verbatim** — never synthesised from an abbreviation, because the collection's tags differ in case, colour and trailing space. A function is re-read on *every* call, which is what lets a host whose prefix constant lives in a later-loading file pass `function() return NS.PREFIX end` instead of capturing `nil` forever. A prefix that has not resolved yet emits the body alone: an untagged line beats one reading `nil something happened`. |
| `sep` | string | no | 1 | Separates the prefix from the body. Defaults to `" "`; a tag that carries its own trailing space passes `""`. |
| `sink` | function(line) | no | 1 | Where a finished line goes. Defaults to `DEFAULT_CHAT_FRAME:AddMessage`. Injectable because hosts capture chat at exactly this seam in their headless harnesses. |

## The instance surface

Everything `lib:New(descriptor)` returns. Both members are plain functions, not methods — a host
does `local print = NS.Print` at file scope and calls it bare, so neither may need a `self`:

| Name | Since | Meaning |
|---|---|---|
| `Print(...)` | 1 | Space-joined, prefix-tagged, secret-safe. Mirrors `print()`'s shape, so a host's existing naked `print(...)` call sites keep working once `print` is bound to this. |
| `Format(fmt, ...)` | 1 | `format()` over pre-stringified arguments, so a secret reaching a `%s` slot renders as the sentinel instead of raising on its way to the chat frame. |

## Compatibility

The API is **additive-only**: a member or descriptor field may be added in a later minor, never
removed or repurposed, so a host written against minor 1 keeps working unmodified here.

`lib.SKIN` is the one documented exception, and it is a *values* change rather than a shape change —
minor 3 is the only release in this major's history to have moved them. A host that read the table
gets the new look for free; a host that copied the old values keeps the old look and no longer
matches the collection.
