# `LibKa0s-Widgets-1.0` — version 7

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Widgets surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Widgets-1.0` |
| Files and minors | `Widgets.lua` minor **7** |
| Shipped in | v1.16.0 |
| Status | **Current** |
| Supersedes | [version 6](./version-6-docs.md) — whose copy window always built an anonymous scroll frame and always drew Core's close control |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Widgets-1.0").MODULES` → `{ Widgets = 7 }` |

## What changed at this version

**Two optional `CopyWindow` descriptor fields, both absent by default.** `scrollName` and
`makeCloseButton` are the whole of this version. Neither is defaulted to anything a caller can
observe: a descriptor written before minor 7 builds exactly the frame it built at version 6, down to
the anonymous scroll frame and the Core-drawn close control. `Dropdown`, `CloseMenu`, every instance
method, every `opts` field, every option-row field and every other `CopyWindow` field are unchanged.
A host needs a re-vendor and no code change.

**`scrollName` exists because `UIPanelScrollFrameTemplate` names its children after its parent.**
The template derives its scrollbar children's names from the scroll frame's own name, so an
anonymous scroll frame leaves them unnamed — which costs nothing until somebody tries to skin one or
find one by name, and then it is invisible rather than broken. The three adopters at version 6 —
BankLedger, LootHistory and MultiMeters — never named the scroll frame; `LibKa0s-DebugLog-1.0`'s own
hand-rolled copy window always had. That difference is what surfaced when DebugLog minor 12 converged
onto this member. Naming it stays the host's call rather than this file's: a name is a global, and a
caller that never asked for one should not silently acquire one on a re-vendor.

**`makeCloseButton` exists because DebugLog had already published it.** `LibKa0s-DebugLog-1.0` has
carried a `makeCloseButton` descriptor field since **its** minor 4, documented as applying to *both*
of its windows. When its minor 12 converged its copy window onto `CopyWindow`, a hardcoded
`Core.MakeCloseButton` here would have quietly narrowed a contract a host had already been told it
could rely on. So the field is forwarded rather than dropped, and it falls back to
`Core.MakeCloseButton` — which is what all four callers want and what three of them already got.
Nothing in the collection passes it today; it is here so that the DebugLog contract does not become
a lie.

**`CopyWindow` has a fourth caller.** `LibKa0s-DebugLog-1.0` minor 12 was the fifth hand-rolled copy
of this frame in the collection, and it is the last one outside Widgets. Nothing in the collection
draws a copy window of its own any more.

## What this major is

The collection's flat-skin dropdown button, and the one popup menu every instance of it drops.
BankLedger had one, local to `modules/Browser.lua`, and MultiMeters was about to grow a second copy
of the same widget — two skins to keep in step, and the collection stops reading as one author's
work the first time one copy is restyled and the other is not. `Widgets.Dropdown` builds the
dropdown; `Widgets.CloseMenu` closes the shared popup behind every dropdown any host has built. Since
version 6 it also owns `Widgets.CopyWindow`, the collection's one selectable-text export frame — see
*The copy window* below.

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework.

## Why it takes no dependency on `LibKa0s-Media-1.0`

Because it cannot. `Media.Icon` builds a path from the *consuming addon's own name*, and this file is
vendored — every consumer has its own copy at its own path, and a copy cannot know which addon folder
it was copied into. So every piece of art this widget draws arrives as a parameter: `opts.chevron`
and `opts.check` are resolved paths the host already has, each falling to a Blizzard texture when the
host has none. The same reasoning applies to `opts.glyphFont` — the optional leading glyph is a
*character* in a monospace face, and which face a host draws in is that host's decision, not this
library's.

## Lib-level surface

| Name | Since | Meaning |
|---|---|---|
| `Dropdown(parent, width, opts)` | 1 | Builds one flat-skin dropdown button parented to `parent`, `width` px wide and 20px tall, that opens the shared popup menu on click. Returns the dropdown frame. |
| `CopyWindow(descriptor)` | **6** | Builds a lazy, reusable copy window — a selectable multi-line `EditBox` in a movable frame — and returns a handle, or `nil` with no client and without a `descriptor.addonName`. See *The copy window*. |
| `CloseMenu()` | **2** | Closes the shared popup menu if it is open. Safe no-op if no dropdown has ever opened it, and safe no-op if it is already hidden. Takes no parameters. |
| `MODULES` | 1 | `{ Widgets = <minor> }` — the live minor, and the value that picks this document. |

### `Dropdown(parent, width, opts)`

`opts` is optional; every field inside it is optional too, and each has an explicit fallback:

| `opts` field | Since | Meaning | Fallback with no value |
|---|---|---|---|
| `chevron` | 1 | Resolved texture path for the collapsed button's ▼ affordance. | `Interface\Buttons\Arrow-Down-Up` (Blizzard's own arrow) |
| `check` | 1 | Resolved texture path for the tick a multi-select row draws in front of a selected value. Built once per dropdown into inline `\|T…:0\|t ` markup and stored on `dd.__check`. | `Interface\Buttons\UI-CheckBox-Check` |
| `glyphFont` | 1 | Resolved font path for the optional leading glyph a row may carry (`opt.glyph`). **A precondition for any option carrying `glyph`** — see *Behavior a host must know* below. | No glyph column is drawn at all: the glyph `FontString` is hidden on every row regardless of whether that row's option has a `glyph`. |

### `CloseMenu()`

Takes no arguments and returns nothing. **A host cannot do this itself**: the popup is a
process-wide singleton, built lazily by the first dropdown any addon in the process opens and
parented to `UIParent`, not to any one host's frame — it outlives every window that ever opened it,
and no host holds a reference to it. Call it from every place a host closes its own window by a
route that is not a click on the dropdown — an `OnHide` handler, an Escape binding, a slash command
that hides the frame — so the shared menu never outlives the window it dropped from.

## Option rows

Every row handed to `dd:SetOptions` is a table. `value` and `label` are expected; the rest are
optional and each is inert when absent.

| Field | Since | Meaning |
|---|---|---|
| `value` | 1 | What this row selects. For an ordinary row it is also what lands in `_selected` (multi) or `_value` (single). The sentinel `"all"` is special-cased by `ToggleSelected` and `UpdateMultiLabel`. |
| `label` | 1 | The row's text, and the collapsed button's text when this row is the single selection. Inline `\|T…\|t` texture markup is allowed and is measured — a class icon folded into a label is the supported way to put art on a row. |
| `color` | 1 | `{ r, g, b }`. The row's text color when the row is not selected; a selected row is gold regardless. |
| `glyph` | 1 | A single character drawn in a leading column, in `opts.glyphFont`. **Requires `opts.glyphFont`** — see *Behavior a host must know*. |
| `isActive` | **4** | `function(dd) → boolean`. When present it decides this row's highlight **instead of** the selection set, and its label becomes the collapsed button's label while it reports true. A row that selects something other than its own value has no other way to report itself active. Called on every paint and on every label refresh, so it must be cheap and must not mutate the dropdown. |

## Instance methods

Every method below is a member of the frame `Dropdown` returns, and every one of them has
existed since minor 1. Behavior added to a method at a later minor is marked in that method's own
row rather than by a `Since` column.

| Method | Parameters | Meaning |
|---|---|---|
| `dd:SetOptions(opts)` | `opts` — array of `{ value, label, glyph?, color?, isActive? }` rows | Sets the row list the popup menu populates from. If the dropdown is in multi-select mode, also refreshes the collapsed button's summary label. |
| `dd:SetValue(v, label)` | `v` — the value to store; `label` — text to show on the collapsed button | Single-select only. Stores `v` on `dd._value` and sets the collapsed button's text to `label` (or blank if `label` is nil). Does not consult `_options`. |
| `dd:SelectValue(v)` | `v` — a value expected to appear in the current `_options` | Single-select only. Looks `v` up in `_options` and calls `SetValue` with the matching row's own label; if no row matches, calls `SetValue(v, tostring(v))`. |
| `dd:SetMulti(on)` | `on` — truthy/falsy | Switches the dropdown between single-select (falsy) and multi-select (truthy). Stored as the boolean `dd.multi`. |
| `dd:SetSelected(set)` | `set` — a table of `value = true` pairs, or any non-table (treated as empty) | Multi-select only. Replaces `dd._selected` with a fresh copy of the truthy keys in `set`, then refreshes the collapsed label. |
| `dd:ToggleSelected(value)` | `value` — one option's value, or the sentinel `"all"` | Multi-select only. A value with a handler in `dd.presets` has that handler run instead (**since 4**, and asked before the sentinel); otherwise `"all"` clears the whole selection (the empty set *is* "All") and any other value toggles its membership in `dd._selected`. Refreshes the collapsed label. |
| `dd:UpdateMultiLabel()` | — | Multi-select only. Recomputes the collapsed button's summary text. **Since 4**: the label of the first option whose `isActive` reports true, if any; otherwise the `"all"` row's own label when nothing is picked, the one picked value's label when exactly one is picked, or `"<Prefix>: N selected"` (the prefix is the `"all"` row's label, up to its first `:`) otherwise — counting **every value in `_selected`**, labeled from its option row when there is one and from the raw value when there is not. Called automatically by the methods above; a host that mutates `_selected` directly must call it explicitly. |

## `dd.onSelect` / `dd.onMultiSelect`

Both are plain fields on the dropdown frame, unset by default — a host wires either or both after
building the dropdown:

| Field | Since | Called | Signature |
|---|---|---|---|
| `dd.onSelect` | 1 | Single-select only, after a row click sets the value and the menu closes. | `function(value)` |
| `dd.onMultiSelect` | 1 | Multi-select only, after a row click toggles membership; the menu stays open. | `function(selectedSet)` — the live `dd._selected` table, `value = true` for every chosen row |

## Fields a host may read, and one it may write

| Field | Since | Meaning |
|---|---|---|
| `dd.text` | 1 | The collapsed button's label `FontString`. Read-only from outside; written by `SetValue` / `UpdateMultiLabel`. |
| `dd.arrow` | 1 | The ▼ affordance `Texture`. Kept for the out-of-game art suite; nothing at runtime reads it back. |
| `dd._value` | 1 | Single-select only. The currently stored value, or nil before one is set. |
| `dd._selected` | 1 | Multi-select only. The live selection set, `value = true` for each chosen row. Empty means "All". |
| `dd.multi` | 1 | Boolean, set by `SetMulti`. Whether this dropdown is in multi-select mode. |
| `dd.presets` | **4** | Writable by the host: `{ [value] = function(dd) end }`. A value with a handler has that handler run by `ToggleSelected` in place of the toggle; the handler owns `dd._selected` and is responsible for writing it. Unset by default. It is a field rather than an `opts` entry because the closure it carries usually needs the dropdown the host is still in the middle of building. |

## `__`-prefixed instance fields are INTERNAL

`dd.__check` and `dd.__glyphFont` are implementation state, not contract. This library's own test
suite reads them, because a suite pinning behavior needs some seam to pin it through — but that is
the suite exercising its own library from the inside, not a precedent for a host. **A host may not
read or write a `__`-prefixed field on a dropdown.** This major has no deprecation mechanism: once
published, a field that a host has come to depend on cannot be removed or reshaped without breaking
someone silently. Keeping the internal/contract line explicit here is what keeps the surface above
this line — and only that surface — permanent.

## Behavior a host must know

- **The popup menu is a process-wide singleton.** One shared frame, built lazily on the first click
  of any dropdown in the process, drops for every dropdown built by every addon that has adopted this
  major. Exactly one dropdown is open at a time across the whole client — opening a second closes the
  first, the way a native game menu does. It outlives any one host's window, which is exactly why a
  host cannot reach it through its own frame and must call `CloseMenu()` instead — see below.
- **A host must call `CloseMenu()` from every non-click close path it has.** Because the popup does
  not belong to any one host's frame, hiding a host's window — by `OnHide`, by Escape, by a slash
  command — does not hide the menu. Without the call, closing the host window by any route other
  than a click on the dropdown leaves the menu orphaned: still shown at `FULLSCREEN_DIALOG`, floating
  over the game with nothing left to hide it. **Since version 5 the menu closes itself on a mouse
  press anywhere outside it, and that narrows the window without closing it** — a host window hidden
  by Escape or by a slash command is hidden with no click at all, so there is nothing for the menu
  to hear. The call is still required from every non-click close path.
- **Rows are pooled across dropdowns, and every field is repainted on every pass.** The popup's row
  buttons are reused rather than rebuilt, and they are shared by every dropdown that has ever opened
  in this process, not just the one currently open. Every visible field of a row — its text, its
  color, its glyph, the glyph's own font — is written on every `Populate`, including the fields that
  are blank for this row's option, precisely so that nothing leaks from whichever dropdown last
  painted that pooled row button.
- **A preset row's own value never enters the selection.** `dd.presets[value]` runs *instead of*
  the toggle, so unless the handler puts it there, the row's value is not in `_selected` afterwards
  — which is why such a row needs `isActive` to light up and why its label, not the selection
  count, is what the collapsed button shows. The two seams are independent and each is useful
  alone: a row may report itself active without being a preset (a synthetic "everything matching
  the search" row), and a preset may run without lighting up.
- **The glyph column is absent unless `opts.glyphFont` is given.** Without a face to draw it in, an
  option's `glyph` is silently dropped: the glyph `FontString` stays hidden — it keeps the font
  template it was built with, so nothing raises — and the row's label
  starts at the plain margin rather than indented past a glyph slot. `opts.glyphFont` is therefore a
  **precondition** for any option that will carry `glyph`, not an optional decoration — raising at
  draw time inside a UI widget would be worse than drawing one column less, and this library carries
  no printer to warn a host through. A host that wants glyphed rows must supply the face; a host that
  never sets `glyph` on any option needs never know the field exists.

## The copy window

`Widgets.CopyWindow(descriptor)` answers a **handle**, not a frame. Nothing is created until the
first `Show`, because a host builds this at file load and most sessions never open it.

It answers `nil` in two cases: with no `CreateFrame` (a host with no UI loaded at all), and with a
descriptor that is not a table or carries no string `addonName`. The name is required rather than
optional because the close control — `Core.MakeCloseButton` by default, or whatever `makeCloseButton`
names since version 7 — resolves the collection's own art out of the *consuming addon's* folder, and
a vendored copy cannot know which folder it sits in. That is the same bargain
`LibKa0s-Media-1.0` already strikes, and it is why `addonName` is handed to the close-control
builder as its third argument rather than assumed by it.

### The descriptor

Every field but `addonName` is optional, and the descriptor a host passes is never mutated — the
defaults are filled into a copy.

| Field | Since | Meaning | Default |
|---|---|---|---|
| `addonName` | 6 | **Required.** The consuming addon's name, used to resolve the close control's art. | — |
| `name` | 6 | The frame's **global** name. It is what goes into `UISpecialFrames`, so it must be unique across the client. | `"<addonName>CopyWindow"` |
| `width` / `height` | 6 | Frame size in px. | `640` / `420` |
| `title` | 6 | The title-bar text. | `"Export"` |
| `font` | 6 | A resolved **font path** for the `EditBox`. Not a LibSharedMedia name — `SetFont` does not take one — and a CSV is columns of digits that line up only in a fixed-width face. | Unset: the `EditBox` keeps the client's default face |
| `fontSize` | 6 | Point size, applied only when `font` is given. | `10` |
| `editWidth` | 6 | Fallback `EditBox` width, used when the scroll frame cannot report one. | `width - 50` |
| `applySkin` | 6 | `function(frame)`. Runs **instead of** `Core.ApplySkin` for hosts that skin their own way. | Unset: `Core.ApplySkin` is used when Core offers it |
| `backdrop` | 6 | `{ r, g, b, a }` applied after the skin. Denser than the shared skin on purpose: this frame is a wall of small text, and the world bleeding through costs legibility. | `{ 0.06, 0.06, 0.08, 0.95 }` |
| `anchorTo` | 6 | `function() → frame\|nil`. Consulted on **every** `Show`, never once at build, so the popup follows a window the user has since dragged. A frame that is not shown, or a `nil`, anchors to `UIParent` instead. | Unset: always centered on `UIParent` |
| `scrollName` | **7** | A **global** name for the window's `ScrollFrame`. `UIPanelScrollFrameTemplate` derives its scrollbar children's names from their parent's, so naming the scroll frame is what makes those children findable and skinnable; leaving it anonymous leaves them unnamed. Must be unique across the client, like `name`. | Unset: the scroll frame is anonymous, exactly as at version 6 |
| `makeCloseButton` | **7** | `function(parent, onClick, addonName) → button\|nil`. Builds the title bar's close control. What it returns is anchored to the bar's right edge; a `nil` return draws no control. Present because `LibKa0s-DebugLog-1.0` has published this field on its own descriptor since its minor 4, for both of its windows. | `Core.MakeCloseButton`, when Core offers it |

### The handle

| Method | Meaning |
|---|---|
| `win:Show(text)` | Re-anchors, sizes the box, sets `text` (or `""`), sends the cursor to the top, shows the frame, focuses and selects. Builds the frame on first call. Returns the frame. |
| `win:Hide()` | Hides the frame if one has been built. A no-op before the first `Show`. |
| `win:GetText()` | The `EditBox`'s current text, or `nil` before the frame exists. |
| `win:GetFrame()` | The frame, **building it if this is the first call**. The escape hatch for a host that needs to reposition or re-parent it. |

### Behavior a host must know

- **The order inside `Show` is load-bearing**: width, then text, then cursor, then show, then focus,
  then highlight. Highlighting before the frame is shown selects nothing, and focusing before the
  text is set leaves the cursor wherever the last export left it. All four hand-rolled copies had
  found this out separately.
- **The frame is built once and reused.** Frames are never destroyed in WoW, so a modal rebuilt per
  open leaks one frame per open for the life of the session.
- **Esc closes it, via `UISpecialFrames`.** The frame's `name` is appended to that list at build,
  guarded on the list actually being a table, so `name` must be globally unique.
- **It sits at `FULLSCREEN` strata**, above the `DIALOG`-strata modal that usually opens it, so the
  modal stays visible underneath and "copy this, then pick a different set" is one trip.
- **Nothing is written back.** The `EditBox` is not read-only in the client's sense — a player can
  type into it — but the handle never consults what they typed, and the next `Show` overwrites it.
- **The scroll frame is anonymous unless `scrollName` says otherwise.** Its scrollbar, and that
  scrollbar's up and down buttons, take their names from it, so with no `scrollName` none of them
  has a name for a skin or a `_G` lookup to reach. A host that never asks for one loses nothing it
  had — which is why the field defaults to absent rather than to a name derived from `name`.
- **The close control is resolved when the frame is built, not at file load.** `makeCloseButton`, or
  `Core.MakeCloseButton` when the host names none, is looked up on the first `Show`, because
  `MakeCloseButton` itself resolves Media at call time and one rule about when the payload is
  resolvable is easier to keep than two.

## Known and intentional absences

Inside a frozen `-1.0` major, anything added is permanent — so what is *not* here at version 7 is a
decision, not an oversight, and every one of these is reachable later without a major bump:

- **No per-row disable**, still — an `isActive` predicate reports a state, it does not gate a
  click. A row that must not be clickable is not expressible at this version.
- **No setters to restyle a dropdown after it is built.** `chevron`, `check` and `glyphFont` are
  read once, at construction, from `opts`; there is no `dd:SetChevron(...)` or equivalent to change
  them on a live instance.
- **No "is the menu open" query.** `CloseMenu()` is a command, not a toggle, and neither shipped
  consumer needs to ask the question before issuing it — a query added on spec ahead of a caller is
  a surface nobody has tested.
- **No search box.**
- **No keyboard navigation.**
- **No scrolling for a long option list** — every row in `_options` gets a row in the menu, and the
  menu grows to fit them.
- **No sub-menus.**
- **No "save to file" on the copy window**, because the client has no file I/O — Ctrl+C is the
  whole mechanism.
- **No `win:Destroy()`.** Frames are not destroyable in WoW; a handle whose frame is built stays
  built for the session.

None of these is wanted by either shipped consumer, and a widget that grows features nobody asked for
is a widget whose degraded behavior nobody has tested.

## Degraded

With `LibKa0s-Widgets-1.0` absent — no vendored copy, or a copy whose `NEEDS_CORE` floor the host's
`LibKa0s-Core-1.0` does not meet — `LibStub("LibKa0s-Widgets-1.0", true)` answers `nil`, exactly as
for any other major. There is no partial module here to leave half-wired: this is a single-file
major, so the host either gets the whole surface or none of it. The host must have a plan for `nil`
— both shipped consumers refuse to draw the surface that would use this widget rather than build a
dead control that opens no menu, and a host with no library also has no `CloseMenu()` to call, so any
non-click close path must itself become a no-op alongside the rest of the degraded surface. The same
holds for `CopyWindow`: with the major absent there is nothing to call, and with the major present in
a host that has no UI at all the call answers `nil` rather than raising — a host must be ready for a
`nil` handle and simply not offer the export.

## Cross-consumer smoke check — recorded, NOT run

BankLedger, LootHistory and MultiMeters each replaced a hand-rolled export copy window with
`CopyWindow` at Widgets minor 6, and `LibKa0s-DebugLog-1.0` minor 12 joined them at minor 7. They
were copies of one design, so the adoption is only correct if the windows still look identical to
each other. Each host recorded its own single-addon check in its `docs/smoke-tests.md`; the
comparison across all four has no single host to live in, so it is recorded here:

- Open the CSV export copy window in all three addons in **one** client session and compare size,
  strata, backdrop alpha, monospace face and title placement. Any one of them differing from the
  other two means the descriptor is wrong, not that one host is nicer.
- Open the debug log's copy window in the same session and compare it against those three. It is
  the one caller that names its scroll frame, so it is also the one place a `scrollName` collision
  would show — a second window failing to open, or opening on top of the first, is the symptom.

This has **not** been run — it needs a live client. Until someone runs it, treat the descriptor's
visual fidelity as unverified.
