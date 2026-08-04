# `LibKa0s-Core-1.0` — version 4

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Core surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Core-1.0` |
| Files and minors | `Core.lua` minor **4** |
| Shipped in | unreleased |
| Status | **Current** |
| Supersedes | [version 3](./version-3-docs.md) |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Core-1.0").MODULES` → `{ Core = 4 }` |

`Since` in the tables below is the Core minor in which the member first appeared. Minors 1 and 2
were never tagged, so they have no document of their own — a `Since` of 1 or 2 means "present for
as long as any consumer could have had this major".

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
| `MakeCloseButton(parent, onClick)` | 1 | The thin × a Ka0s window closes with, returned unanchored for the caller to place. Returns `nil` where `CreateFrame` is unavailable (headless harness, or a load path with no UI). |
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

**One addition, `lib.RGBA`, and nothing else.** No existing member, descriptor field or value moved,
so a host written against minor 3 is byte-for-byte correct here — the skin table, `ApplySkin`,
`MakeCloseButton` and the printer are all exactly what they were.

`ApplySkin`'s body was restructured internally (the backdrop, the inner border and the two accent
tints are now four named file-locals rather than one run of guards) to bring it under the
collection's complexity cap. The order of the calls, every guard it makes and the frame it leaves
behind are unchanged; nothing about it is observable from a call site.

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
