# `LibKa0s-Widgets-1.0` — version 5

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Widgets surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Widgets-1.0` |
| Files and minors | `Widgets.lua` minor **5** |
| Shipped in | v1.13.0 |
| Status | **Current** |
| Supersedes | [version 4](./version-4-docs.md) — whose click-catcher swallowed a right-click instead of closing the menu |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Widgets-1.0").MODULES` → `{ Widgets = 5 }` |

## What changed at this version

**An outside click closes the menu without being eaten.** Through version 4 the menu was dismissed
by a full-screen `Button` at `FULLSCREEN` strata, shown alongside it, whose `OnClick` hid the menu.
That frame *intercepted* the click, and intercepting was the defect — twice over:

- A `Button` with no `RegisterForClicks` takes `LeftButtonUp` and nothing else. **A right-click
  anywhere while a menu was open was swallowed**: it landed on the catcher, found no handler for
  that button, and went nowhere. The menu stayed open and whatever was under the cursor never heard
  the click. It survived from version 1 because neither shipped consumer had a right-click surface
  on the same window as a dropdown. LootHistory was the first, and there a right-click on a history
  row did nothing at all until the player left-clicked to dismiss the menu first.
- Even the left-click it did handle was consumed. Dismissing the menu cost a click that did nothing
  else.

**The catcher is gone.** The menu now registers `GLOBAL_MOUSE_DOWN` while it is shown and closes
itself when the press was neither on the menu nor on the dropdown it dropped from. That event fires
for a press anywhere in the UI, on any button, whether or not something else consumed it — so the
menu reacts to a click it never touched, and the click goes on to reach whatever is under the
cursor. **One press now both dismisses the menu and does the thing the player pressed on.**

**This is a visible behavior change, and it is the reason to read this section.** Under version 4 a
click outside an open menu was absorbed. Under version 5 it is not: it dismisses the menu *and*
lands. A player closing a menu by clicking on the 3D world, an action bar or another addon's frame
will now also click that thing. This is what a host asked for and what the issue behind this version
described, but a host whose window sits under its own dropdowns should smoke-test it.

**The registration is scoped to the open menu**, taken when the menu is shown and dropped by its
`OnHide` — not held for the life of the process. A handler running on every mouse press in the game
for the rest of the session, in every host that ever vendored this file, is a cost no host agreed
to.

**Two presses are deliberately not "outside".** A press on the menu itself, because otherwise the
menu would close under the player's own row click, on the press, before the release the row needs.
And a press on the dropdown that dropped it, because that button's `OnClick` is the toggle — close
on the press and the release finds the menu hidden and re-opens it, making the menu impossible to
close by the button that opened it. Only the *owner* is exempt: a press on a different dropdown
closes this menu, and that dropdown's own `OnClick` then opens its own, which is how exactly one
menu stays open across the process.

**No contract moves.** `Dropdown`, `CloseMenu`, every instance method, every documented `opts` field
and every option-row field are unchanged from version 4. A host needs a re-vendor and no code
change.

## What this major is

The collection's flat-skin dropdown button, and the one popup menu every instance of it drops.
BankLedger had one, local to `modules/Browser.lua`, and MultiMeters was about to grow a second copy
of the same widget — two skins to keep in step, and the collection stops reading as one author's
work the first time one copy is restyled and the other is not. `Widgets.Dropdown` builds the
dropdown; `Widgets.CloseMenu` closes the shared popup behind every dropdown any host has built.

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

## Known and intentional absences

Inside a frozen `-1.0` major, anything added is permanent — so what is *not* here at version 5 is a
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

None of these is wanted by either shipped consumer, and a widget that grows features nobody asked for
is a widget whose degraded behavior nobody has tested.

## Degraded

With `LibKa0s-Widgets-1.0` absent — no vendored copy, or a copy whose `NEEDS_CORE` floor the host's
`LibKa0s-Core-1.0` does not meet — `LibStub("LibKa0s-Widgets-1.0", true)` answers `nil`, exactly as
for any other major. There is no partial module here to leave half-wired: this is a single-file
major, so the host either gets the whole surface or none of it. The host must have a plan for `nil`
— both shipped consumers refuse to draw the surface that would use this widget rather than build a
dead control that opens no menu, and a host with no library also has no `CloseMenu()` to call, so any
non-click close path must itself become a no-op alongside the rest of the degraded surface.
