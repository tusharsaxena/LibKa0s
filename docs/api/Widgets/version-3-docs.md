# `LibKa0s-Widgets-1.0` — version 3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Widgets surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Widgets-1.0` |
| Files and minors | `Widgets.lua` minor **3** |
| Shipped in | v1.11.2 |
| Status | **Current** |
| Supersedes | [version 2](./version-2-docs.md) — whose menu raised `FontString:SetText(): Font not set` on the first click, in every host |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Widgets-1.0").MODULES` → `{ Widgets = 3 }` |

## What changed at this version

**The menu no longer raises on the first click.** Versions 1 and 2 built a row's glyph `FontString`
with no font — `CreateFontString(nil, "OVERLAY")`, no template — and then set its text on every
paint. The client answers `FontString:SetText(): Font not set` to that, so the first click on any
dropdown built by any host errored, and the error landed at whatever point the host built its
window. The fix is one argument: the glyph is built from the `GameFontHighlightSmall` template, so
it always has a font, while the per-paint `SetFont` still lets each host impose its own monospace
face.

**It reached every host, not only a host with no `glyphFont`.** The face is set only on a row that
*has* a glyph, so even a host that supplies a face — the case version 1 was designed around —
painted its glyphless rows through a `FontString` that had never been given one. A host with no
`glyphFont` at all hit it on every row.

**No contract moves.** `Dropdown`, `CloseMenu` and every instance method are unchanged from version
2, and the documented behavior of `opts.glyphFont` is unchanged — *dropping* the glyph column with
no face named is what version 1 promised and what this version is the first to actually do. A host
on version 2 needs no code change, only a re-vendor.

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

## Instance methods

Every method below is a member of the frame `Dropdown` returns. `Since` is 1 for all of them.

| Method | Parameters | Meaning |
|---|---|---|
| `dd:SetOptions(opts)` | `opts` — array of `{ value, label, glyph?, color? }` rows | Sets the row list the popup menu populates from. If the dropdown is in multi-select mode, also refreshes the collapsed button's summary label. |
| `dd:SetValue(v, label)` | `v` — the value to store; `label` — text to show on the collapsed button | Single-select only. Stores `v` on `dd._value` and sets the collapsed button's text to `label` (or blank if `label` is nil). Does not consult `_options`. |
| `dd:SelectValue(v)` | `v` — a value expected to appear in the current `_options` | Single-select only. Looks `v` up in `_options` and calls `SetValue` with the matching row's own label; if no row matches, calls `SetValue(v, tostring(v))`. |
| `dd:SetMulti(on)` | `on` — truthy/falsy | Switches the dropdown between single-select (falsy) and multi-select (truthy). Stored as the boolean `dd.multi`. |
| `dd:SetSelected(set)` | `set` — a table of `value = true` pairs, or any non-table (treated as empty) | Multi-select only. Replaces `dd._selected` with a fresh copy of the truthy keys in `set`, then refreshes the collapsed label. |
| `dd:ToggleSelected(value)` | `value` — one option's value, or the sentinel `"all"` | Multi-select only. `"all"` clears the whole selection (the empty set *is* "All"); any other value toggles its membership in `dd._selected`. Refreshes the collapsed label. |
| `dd:UpdateMultiLabel()` | — | Multi-select only. Recomputes the collapsed button's summary text from `_options` and `_selected`: the `"all"` row's own label when nothing is picked, the one picked row's label when exactly one is picked, or `"<Prefix>: N selected"` (the prefix is the `"all"` row's label, up to its first `:`) otherwise. Called automatically by the methods above; a host that mutates `_selected` directly must call it explicitly. |

## `dd.onSelect` / `dd.onMultiSelect`

Both are plain fields on the dropdown frame, unset by default — a host wires either or both after
building the dropdown:

| Field | Since | Called | Signature |
|---|---|---|---|
| `dd.onSelect` | 1 | Single-select only, after a row click sets the value and the menu closes. | `function(value)` |
| `dd.onMultiSelect` | 1 | Multi-select only, after a row click toggles membership; the menu stays open. | `function(selectedSet)` — the live `dd._selected` table, `value = true` for every chosen row |

## Fields a host may read

| Field | Since | Meaning |
|---|---|---|
| `dd.text` | 1 | The collapsed button's label `FontString`. Read-only from outside; written by `SetValue` / `UpdateMultiLabel`. |
| `dd.arrow` | 1 | The ▼ affordance `Texture`. Kept for the out-of-game art suite; nothing at runtime reads it back. |
| `dd._value` | 1 | Single-select only. The currently stored value, or nil before one is set. |
| `dd._selected` | 1 | Multi-select only. The live selection set, `value = true` for each chosen row. Empty means "All". |
| `dd.multi` | 1 | Boolean, set by `SetMulti`. Whether this dropdown is in multi-select mode. |

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
  over the game with nothing left to hide it. The click-catcher built alongside the menu only ever
  helps when the player clicks outside it; it does nothing for a window closed any other way.
- **Rows are pooled across dropdowns, and every field is repainted on every pass.** The popup's row
  buttons are reused rather than rebuilt, and they are shared by every dropdown that has ever opened
  in this process, not just the one currently open. Every visible field of a row — its text, its
  color, its glyph, the glyph's own font — is written on every `Populate`, including the fields that
  are blank for this row's option, precisely so that nothing leaks from whichever dropdown last
  painted that pooled row button.
- **The glyph column is absent unless `opts.glyphFont` is given.** Without a face to draw it in, an
  option's `glyph` is silently dropped: the glyph `FontString` stays hidden — it keeps the font
  template it was built with, so nothing raises — and the row's label
  starts at the plain margin rather than indented past a glyph slot. `opts.glyphFont` is therefore a
  **precondition** for any option that will carry `glyph`, not an optional decoration — raising at
  draw time inside a UI widget would be worse than drawing one column less, and this library carries
  no printer to warn a host through. A host that wants glyphed rows must supply the face; a host that
  never sets `glyph` on any option needs never know the field exists.

## Known and intentional absences

Inside a frozen `-1.0` major, anything added is permanent — so what is *not* here at version 3 is a
decision, not an oversight, and every one of these is reachable later without a major bump:

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
- **No per-row disable.**

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
