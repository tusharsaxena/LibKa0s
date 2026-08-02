# `LibKa0s-Core-1.0` — version 2

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Core surface points here rather than restating it. It describes the
> contract *as it was at this version* — a later version is a different document, not an edit to
> this one.

| | |
|---|---|
| Major | `LibKa0s-Core-1.0` |
| Files and minors | `Core.lua` minor **2** |
| Shipped in | v1.0.0, v1.1.0, v1.1.1, v1.2.0 |
| Status | Superseded |
| Supersedes | minor 1 (pre-release, never vendored) |
| Superseded by | [version 3](./version-3-docs.md) |
| Confirm in-game | `LibStub("LibKa0s-Core-1.0").MODULES` → `{ Core = 2 }` |

`Since` in the tables below is the Core minor in which the member first appeared. Minor 1 was never
tagged, so a `Since` of 1 means "present for as long as any consumer could have had this major".

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

| Name | Since | Meaning |
|---|---|---|
| `IsConcatSafe(v)` | 1 | Whether `v` survives the `table.concat` every emitted line ends in. Probes `table.concat` itself, not `..` — `..` silently propagates secretness and reports a secret as safe. |
| `SafeToString(v)` | 1 | Concat-safe stringifier. Ordinary values → `tostring(v)`; an un-concatenable (secret) value → `lib.SECRET`. `nil` and booleans are answered up front, so they are never masked. |
| `SECRET` | 1 | What an un-renderable value renders as (`"<secret>"`). Exported so a host's tests, its docs and this implementation cannot drift apart. |
| `SKIN` | 1 | The one skin every Ka0s window wears — the backdrop fields plus `bg` and `border`, in one table because taking the backdrop without the colours is exactly the drift this prevents. See [The skin table](#the-skin-table). |
| `ApplySkin(frame)` | 1 | Wear the skin. Takes **no second argument at this version** — the skin applied is always `lib.SKIN`. A no-op on a frame with no `SetBackdrop`: undecorated is not broken. |
| `MakeCloseButton(parent, onClick)` | 1 | The thin × a Ka0s window closes with, returned unanchored for the caller to place. Returns `nil` where `CreateFrame` is unavailable (headless harness, or a load path with no UI). |
| `MODULES` | 1 | `{ Core = <minor> }` — the live minor of every file in this major. |
| `lib:New(descriptor)` | 1 | Build a prefixed chat printer for one host. See below. |

### The skin table

`lib.SKIN` at minor 2 — the 12px tooltip border, before the flat Ka0s edge of minor 3.

| Key | Value at minor 2 |
|---|---|
| `bgFile` | `Interface\Buttons\WHITE8x8` |
| `edgeFile` | `Interface\Tooltips\UI-Tooltip-Border` |
| `edgeSize` | `12` |
| `insets` | `{ left = 3, right = 3, top = 3, bottom = 3 }` |
| `bg` | `{ 0.06, 0.06, 0.07, 0.95 }` |
| `border` | `{ 0, 0, 0, 1 }` |

There is no `innerBorder`, `divider` or `title` key at this version. A host that wanted a flat edge,
a tinted title or a divider drew them itself — which is exactly why five consoles side by side did
not read as one suite, and why minor 3 moved the definition here.

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

## Moving to version 3

Nothing to change at a call site — the API shape is identical and additive. What moves is the
**look**: `lib.SKIN`'s values change and gain `innerBorder`, `divider` and `title`, and `ApplySkin`
gains an optional second argument. A host that reads `lib.SKIN` gets the new Ka0s edge for free.
