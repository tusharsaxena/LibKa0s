# `LibKa0s-Widgets-1.0` — version 9.2

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Widgets surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Widgets-1.0` |
| Files and minors | `Widgets.lua` minor **9** · `WidgetsDragHandle.lua` minor **2** |
| Shipped in | v1.48.1 |

## What changed at 9.2

**The help mark brightens on hover only where a click is wired.** At 9.1 `dhBuildHelp` tinted the
mark to `HELP_TINT_OVER` on `OnEnter` unconditionally, while `dhSetClick` registers no click at all
for a host that passes no `onRightClick`. A host without a right-click therefore shipped a mark that
lit up under the cursor and then did nothing — a control advertising itself and then declining.
The over-tint is now `spec.onRightClick and HELP_TINT_OVER or HELP_TINT`: a host with a click gets
the full-white response unchanged, and a host without one gets a mark that holds its resting gray.

Nothing else moved. A host that passes `onRightClick` sees 9.1's behavior exactly.

| Status | **Current** |
| Supersedes | [version 9](./version-9-docs.md) — which had no drag-handle surface at all |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Widgets-1.0").MODULES` → `{ Widgets = 9, WidgetsDragHandle = 1 }` |

## What changed at this version

**A second file joins the major, and one new lib-level member comes with it: `lib.DragHandle`.**
`Dropdown`, `CloseMenu`, `CopyWindow`, `ReorderList`, `lib.ROW_BOX` and every instance method are
byte-for-byte unchanged, and `Widgets.lua` does not move — it stays at minor **9**. What is new is
`LibKa0s/WidgetsDragHandle.lua` at minor **1**, carrying `lib.DragHandle`, `lib.DRAG_HANDLE` and
`lib.__DragHandleMeasurer`. A file added to an existing major moves that major's version key, which
is why this document is `9.1` and its predecessor was `9`.

**Why a second file rather than more of `Widgets.lua`:** `layout-§1`'s 1500-line cap, and nothing
else. The surface written into `Widgets.lua` took that file to 1540 lines, which is a breach needing
a disposition; the file was already in the 1000–1500 band at 1232. It is guarded with the same
multi-file idiom the Options family uses — `lib.__dragMinor` paired against `lib.__dragShellMinor ==
lib.MINOR` — so a handle from one vendored copy can never attach to a shell from another in silence.
It is **not** a major of its own, which would have cost a `core/<Name>Setup.lua` seam in all eleven
consumers, nine of which will never draw a handle.

### The drag handle, and why it is the widget's

AuraMaster drew one per container (`modules/Anchors.lua`) and ConsumableMaster drew one over its
macro bar (`modules/MacroBar.lua`), and the two were the same widget twice. Byte-identical in both:
`HANDLE_H = 18`, `HANDLE_GAP = 2`, `HANDLE_PAD = 24`, `HANDLE_HELP = 14`; a centered
`GameFontNormalSmall` label at `1, 0.82, 0`; a help `Button` anchored `RIGHT, -4`; the icon taken
from the host's `help` art with `Interface\FriendsFrame\InformationIcon` as the last rung; and the
width `textW + HANDLE_PAD + HANDLE_HELP * 2`. That is the same argument the dropdown was lifted
under and the same argument `lib.ROW_BOX` was published under — a drag handle over a frame the
player moves is a draggable row's sentence one frame up.

**The mark's art is 8px, not 14 — and it matches the chevron in ink, not in box.** It is a fixed
number, derived from nothing at runtime. The precedent is the dropdown's chevron,
`arrow:SetSize(12, 12)` at the same `RIGHT, -4` inset (`LibKa0s/Widgets.lua:331-333`) — but a box is
not a weight. The chevron's art is the catalog's `chevron-down`, whose glyph inks 44 of its 64 rows,
so a 12px box of it draws **8.25px** of mark. This mark's art is `help`, whose `?` inks all 64, and
the Blizzard fallback is a filled disc and is certainly no more inset: a 12px box draws **12px**.
Both measurements are of the catalog TGAs, which is what both hosts resolve `help` to. Against
the small label face's cap height — FRIZQT\_\_ at 10px, a cap of roughly 7px — that is about
**1.7×** the text the mark annotates, where the chevron is about **1.1×**. At 8 the ink is the
chevron's ink. 8 is a floor rather than a direction of travel: below it the `?` loses the gap
between its hook and its dot at 100% UI scale, and the click target never moved with the art.

> **An intermediate draft shipped 12 and was wrong for a subtler reason than 14 was.** It cited the
> chevron and matched it in the one dimension that does not reach the player's eye, while leaving
> the mark at full white beside a gold label — so the annotation was both larger and brighter than
> the text it annotates. Size was only half the lever; see **the mark's tint** below.

> An earlier draft of this surface computed the art from the label's font height —
> `round(labelHeight × 1.2)`, floored at 10 and capped at `HEIGHT - 6` — and described it as a size
> that grows with a larger face. It was a derivation in name only. The cap equalled the default, so
> the arithmetic could only ever move the size **down**, and the `GameFontNormalSmall is 10px` fact
> the whole thing rested on had no evidence in this repo and is locale-dependent. The number is the
> same 12; what changed is that it no longer claims to have been computed.

**The mark's tint is the chevron's own, and it brightens under the cursor.** Both copies drew the
mark at full white — the brightest element on a strip whose label is gold `1, 0.82, 0` on a dark
fill. The chevron does not: it carries `arrow:SetVertexColor(0.7, 0.7, 0.72)`
(`LibKa0s/Widgets.lua:335`), set by the widget rather than by the host, which is what makes shared
white art wear the widget's gray instead of its own. The mark takes the same tint from the same
place, at **alpha 1** — vertex color multiplies white art, which is what the catalog's art is built
for, where alpha would fade the mark toward the fill behind it. Unlike the chevron the mark is its
own `Button`, so it goes to full white on `OnEnter` and back on `OnLeave`; a mark dimmed at rest
with no response to the cursor reads as decoration rather than as a control.

**The mark's frame is 18px — the full strip height — and that is a different number from its art.**
The art shrank; the click target did not. This control is a destructive-adjacent one on
ConsumableMaster and the only right-click affordance on AuraMaster's strip, so an 8×8 button was
not acceptable. `HELP_HIT` is the `Button`, `HELP` is the texture centered inside it, and
`HELP_GUTTER` is the `(18 - 8) / 2 = 5px` that separates them on all four sides. It is the same
shape `O.IdList`'s remove icon took one layer down — `ID_REMOVE_SIZE = 16` of atlas inside an
`ID_REMOVE_HIT = 26` frame — rather than a second answer to the same question.

**The clearance beside the label is 12px, where both copies spent 8.** That gap was the actual
complaint, and shrinking the art alone did not touch it: both copies reserved
`PAD / 2 + HELP - HELP_INSET` on the label's right, and because `HELP` sat on both sides of that
expression, 14 → 12 left the 8 exactly where it was. `HELP_CLEAR` names the gap so it can be moved
on its own, and it is also the label's own right **bound** — the label is anchored `LEFT` and
`RIGHT` at `RESERVE`, with word wrap off, so a label longer than the strip truncates inside its half
instead of running under the mark, and `RESERVE` — what each side of the label gives up — is computed from
`HELP_INSET + HELP_HIT - HELP_GUTTER + HELP_CLEAR`, never typed.

**The reserve feeds the layout, which is why `Measure()` is on the widget.** `RESERVE` is spent
**twice**: once on the right, where it pays for the inset, the frame and the clearance in front of
the art, and once on the left as the matching empty gap that keeps the label optically centered. At
29 per side against the copies' 26, a strip's natural width grows by **6px**. Invisible wherever
the strip is floored by something wider (ConsumableMaster's bar, AuraMaster's element size); visible
on a narrow strip, which is exactly where the crowding was. Because the arithmetic lives beside the
constants, the two cannot drift apart again — and a host that keeps a local copy of the formula
reintroduces the drift the move exists to remove.

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
| `ReorderList(opts)` | **8** | Builds a drag-to-reorder controller for one render of a list. Returns the controller. See *The reorderable list*. |
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

## The reorderable list

`ReorderList(opts)` returns a **controller for one render**. It holds the rows of the pass that
built it, so a repaint builds a new one — and `Cancel()` on the old one is what stops a drag
outliving the list it was describing.

### `opts`

Every field is optional except the ones a working list needs.

| Field | Meaning | Fallback |
|---|---|---|
| `stride` | Row top to next row top, in pixels. The drop target is **arithmetic on this**, never a hit test, so nothing depends on the rows having been laid out yet, on the scroll position, or on a layout pass having finished — all three of which are true at different moments during a drag. | `30` |
| `onMove` | `function(from, to)`. Called **once** when a drag lands somewhere new. Never called for a drag that lands where it started, because that would have the host rewrite its list and repaint for no change. | no callback; the drag is inert |
| `boundary` | How many rows are in the **first** group. `nil` or `0` means one flat list. With a boundary, a row may not be dragged out of its own group — the drop clamps at the divide. | `nil`, one flat list |
| `handleIcon` | Resolved texture path for the handle art. A vendored copy cannot know which addon folder it sits in, so art arrives as a parameter — the same reason `chevron` and `check` do. | `Interface\Buttons\UI-SortArrow` |
| `handleSize` | The handle's hit width. Its height is the row's. **The default moved at minor 9** — 30 is the gutter every list in the collection gives its handle, and MultiMeters was already passing it by hand. | `lib.ROW_BOX.HANDLE_W`, **30** |
| `handleInset` | Pixels from the parent's left edge. | `0` |
| `handleColor` | `{ r, g, b }` for the handle at rest. | a neutral gray, `{ 0.7, 0.7, 0.7 }` |
| `handleHoverColor` | `{ r, g, b }` under the pointer. A host whose list has its own palette says so; one that says nothing matches every other list in the collection. | gold, `{ 1, 0.82, 0 }` |
| `handleTooltip` | One line shown on hover, e.g. "Drag to reorder". | no tooltip at all |
| `iconSize` | The art drawn inside the handle. | `16` |
| `rowBox` | **New at 9.** `false` suppresses the bounded box behind every row. Defaults **ON**: the box is half of what makes a list read as blocks you can pick up, and a host that draws its own has to say so — and should instead delete its own, or the two fills stack. | `true` |
| `rowBoxInset` | **New at 9.** Pixels the box is inset from the row frame's edges. | `0` |
| `lineColor` | `{ r, g, b, a }` for the insertion line. | gold, `{ 1, 0.82, 0, 0.9 }` |
| `debug` | `function(fmt, ...)`, called on grab and on drop. | no logging |

### Controller methods

| Method | Meaning |
|---|---|
| `AddRow(frame, spec)` | Registers one row, **in display order** — the index is the call order. Creates the handle as a child of `spec.parent or frame`, anchored `LEFT`, and returns it so the host may re-anchor it. |
| `Finish(container)` | Names the frame the insertion line lives on — normally the scroll's content frame, or whatever the rows share as a parent. Call once, after the rows. |
| `Cancel()` | Stops any drag in flight, puts the chrome away, and **gives every handle and every row box back**. Idempotent. **A host must call this before it renders anything** — see below. |

`spec` on `AddRow`, all optional: `ghostText`, `ghostIcon`, `ghostIconColor`, `ghostTextColor`,
`height`, `parent`, `draggable`, and **`dimmed`** (new at 9).

**`draggable = false` registers the row with no handle.** It still counts for indices and still
anchors the insertion line — it is a place a drag can *land*, not one a drag can start from. Use it
for rows that have an order nothing can act on.

**`dimmed = true` paints that row's box in the muted variant**, for a row that is present but inert —
MultiMeters' hidden columns, LootHistory's sources it is not collecting. The box is drawn for **every**
registered row, draggable or not, and before the handle: a row you cannot pick up is still one of the
blocks the list is made of, and a stack where only some rows have an edge reads as a rendering fault
rather than as a rule.

### Behavior a host must know

**The library owns its handles and its row boxes, and `Cancel()` must run before the host renders anything.** Both come from free lists here and are parented to the host's frame only while live; `Cancel()` hides, unanchors and reparents them away in one step, through one shared reclaim so neither can be forgotten without the other.

They are **not** cached on the host's frames, and that distinction cost a release. Both consumers hand over containers their UI framework pools — and AceGUI's pool is process-wide, so a released container goes to whatever asks next. A handle left parented and shown turned up on an unrelated part of the page: on a *Drag to action bar* row, on an ID entry box, on a dropdown. A frame's identity is not the host's to lend, so a cache keyed on it is a cache keyed on nothing.

The same reasoning fixes the timing: a `Cancel()` that runs after the page has begun rebuilding runs after some other widget may already hold the frame. **Cancel at the very top of the render, before the first `AceGUI:Create`.**

**Nothing about a drag closes over anything.** Both shipped consumers hand over a frame
their UI framework *pools*, so `AddRow` caches the handle on it and re-points it rather than building
a new one. It also reads `handle.__row` at fire time, and `beginDrag`/`finishDrag` reach the
controller through `row.list` rather than closing over it. **All three are needed.** A handle built
fresh each render piles up on a recycled frame; one that closes over its row drives the wrong row;
one that closes over its *controller* drives a controller that was `Cancel()`led on the last render
— and that last one is a drag that works exactly once and then freezes, while still passing a test
written against the first two.

**The handle is the library's, deliberately.** It is what a player has to recognize as "drag me",
and a collection whose lists each invented their own affordance would defeat the point of sharing
this. The host still decides where it sits and how big it is; it does not decide what it is.

**Only the handle starts a drag.** Rows in these lists carry other controls — a remove button, a
score button, a toggle glyph — and a row that was draggable anywhere would swallow presses aimed at
those. They sit a few pixels apart.

**Every input path can start the drag and every path can end it.** `OnMouseDown` and `OnDragStart`
both begin it; `OnMouseUp`, `OnDragStop` and a poll of `IsMouseButtonDown` all end it. Both helpers
are idempotent, so whichever order a client delivers them in, one grab begins once and completes
once. This redundancy is not belt-and-braces for its own sake: which of these a client actually
sends inside a Settings canvas turned out not to be something worth betting on, and two earlier
implementations that each picked one pair shipped a drag that did nothing at all.

**The poll may not act alone**, and it has to see the button *held* before it may act on it being
released. If `IsMouseButtonDown` is unavailable, protected, or simply not true yet on the first
frame, a poll that ended on `not held` would finish the drag with zero rows travelled — no error, no
message, and indistinguishable from a press that was never received.

**The ghost is a process-wide singleton on `UIParent`.** It must escape whatever scroll frame the
list sits in to follow the cursor past the ends of the list, which a child of that scroll cannot do.
Its mouse is disabled, and that is load-bearing rather than tidy: a frame sitting under the pointer
that accepts the mouse eats the very button-release that ends the drag it is drawing.

**The insertion line is a frame carrying a texture**, not a bare texture, and it is cached on the
container. A texture belongs to its own frame's draw layers, so one created on the container draws
*under* every row — a parent's `OVERLAY` still loses to a child frame.

**A clamped drag still shows the line**, stopped at the divide. A drop that clamps writes nothing,
so the line stopping is the only feedback there is; without it a working clamp is indistinguishable
from a broken drag.

## The unlocked drag handle

**`lib.DragHandle(parent, spec)` → `handle` or `nil`.** A labeled strip with a help mark in its far
end, shown while a movable frame is unlocked and dragged to move it. A plain constructor with
everything per-instance: AuraMaster calls it once per container and ConsumableMaster exactly once,
and nothing in the file is shared between instances but the measuring FontStrings.

It answers `nil` with no `parent`, and `nil` in a process with no `CreateFrame` — a host must be
ready for that and simply not draw a strip, the same posture every other member here takes.

### `lib.DRAG_HANDLE`

The canonical values, published for the reason `lib.ROW_BOX`'s are: a host that copies them into its
own constants file is the drift this replaces. Read them off the table.

| Field | Value | Meaning |
|---|---|---|
| `HEIGHT` | `18` | the strip's height |
| `GAP` | `2` | the gap a host leaves between the strip and the frame it moves |
| `HELP` | `8` | the mark's **art**: the texture's edge — **14 in both copies before this version** |
| `HELP_HIT` | `18` | the mark's **frame**: the click target, the strip's full height |
| `HELP_INSET` | `4` | px from the strip's right edge to the mark's frame |
| `HELP_CLEAR` | `12` | px of empty space between the label's bound and the mark's art — **8 in both copies** |
| `HELP_GUTTER` | `5` | computed: `(HELP_HIT - HELP) / 2` exactly, never floored, the margin the art is centered in |
| `RESERVE` | `29` | computed: `HELP_INSET + HELP_HIT - HELP_GUTTER + HELP_CLEAR`, what each side of the label keeps clear |

`HELP_GUTTER` and `RESERVE` are computed at load from the four fields above them rather than typed,
so a host reading them can never be reading a stale copy of the arithmetic. `PAD` is gone: it was
`24` of "horizontal padding around the label" that in fact carried the clearance, the inset and half
the mark, and splitting it is what made the clearance changeable on its own.

`GAP` is published rather than used: the widget never places itself, so the host spends it. AuraMaster
also spends it in its clamp reach, `HEIGHT + GAP`.

### `spec`

`label` and `moveFrame` are the only required fields.

| Field | Meaning | Absent |
|---|---|---|
| `label` **(required)** | the strip's centered text, already localized | empty |
| `moveFrame` **(required)** | the frame `StartMoving` / `StopMovingOrSizing` are called on | the drag moves nothing |
| `name` | global frame name (`"KCMMacroBarHandle"`) | anonymous |
| `helpIcon` | resolved texture path for the mark, the host's `Icon("help")` | `Interface\FriendsFrame\InformationIcon` |
| `canDrag` | `function() -> boolean`, asked at `OnDragStart` | always allowed |
| `onDragStart` / `onDragStop` | called once the move has started / stopped; a host saves its position in the second | no-op |
| `onRightClick` | `function()`; **without it neither the strip nor the mark registers for clicks at all** | no right-click |
| `tooltip` | the descriptor below — shown by the strip, and by the mark unless `helpTooltip` says otherwise | no tooltip |
| `helpTooltip` | a **second** descriptor of the same shape, shown by the help mark alone | the mark shows `tooltip` |
| `tooltipOwner` | the default for both descriptors: `"cursor"` owns by `UIParent` at `ANCHOR_CURSOR`; anything else owns by the frame hovered | by the frame hovered |
| `tooltipAnchor` | the default anchor point used when owning by the frame | `"ANCHOR_TOP"` |
| `edge` | `function(frame, size, r, g, b, a)` — the host's own 1px edge painter | the widget's four strips |
| `number` | `function(v, fallback) -> number` — a secret-safe numeric guard | `tonumber(v) or fallback` |
| `labelFont` | the font object the label is **drawn in and measured in** | `"GameFontNormalSmall"` |

**`labelFont` sets both or neither, and that is the whole point of the field.** An earlier draft
drew the label in a hardcoded face and measured it through a separate `measureFont`, so a host that
set one and not the other measured a width the strip never drew — and a label measured narrower than
it renders runs into the mark. One face, read by `dhBuildLabel` and by `lib.__DragHandleMeasurer`.

**One tooltip or two.** The common case is one descriptor for both frames and stays one field:
AuraMaster shows the container's name and the same two lines whichever of the two the cursor is
over. ConsumableMaster does not — its strip is titled *"Consumable Master"* with a one-line body and
its mark is titled *"Macro bar"* with three body lines, a gray footer and a different anchor
(`MacroBar.lua`). A shape with one descriptor for both frames would have merged those two tooltips
on adoption, silently, in the host this widget exists for. `helpTooltip` is absent in the simple
case and costs the simple host nothing.

**`tooltipOwner` is a correctness knob, not a style one, and it is why the field exists.**
AuraMaster's anchor inherits `DisableUntrustedLayoutScriptsTemplate` and the restriction reaches
every frame anchored under it, so the client **refuses** `GameTooltip:SetOwner` on the strip or the
mark — *"Anchoring disallowed as dependent object would inherit forbidden aspects:
UntrustedLayoutScriptExecution"*. That host must own by `UIParent` at the cursor, which depends on
nothing under the anchor. ConsumableMaster owns by the frame hovered — `ANCHOR_TOP` off the strip,
`ANCHOR_TOPRIGHT` off the mark. A widget that hard-coded either would leave the other host with no
tooltip at all, and only in-game — the headless suite cannot see it.

**"The frame hovered" means the frame the cursor is actually on**: the strip owns by the strip and
the mark owns by the mark. An earlier draft documented that in four places and owned by the strip in
all cases; the code is what changed. `owner` and `anchor` may also be set on a descriptor itself,
which is what lets ConsumableMaster's two anchors differ, and a descriptor's own value wins over the
spec-level default.

### The tooltip descriptor

```lua
tooltip = {
  title  = <entry>,              -- gold, 1, 0.82, 0
  body   = { <entry>, … },       -- white, wrapped
  footer = { <entry>, … },       -- gray, after one blank line
  owner  = <"cursor" | nil>,     -- overrides spec.tooltipOwner for this descriptor
  anchor = <string | nil>,       -- overrides spec.tooltipAnchor for this descriptor
}

-- <entry> is any of:
--   "text"                     used as it stands, in its band's color
--   function() -> string|nil   called on every hover; a nil return drops the line
--   { <either>, r, g, b }      the same, in a color of its own rather than its band's
```

Three bands, and the host supplies the strings. **Every entry may be a function, and it is called on
every hover** — a string is used as it stands, a function is called and a `nil` return drops that
line entirely. That single rule covers both hosts: ConsumableMaster's last line reads
*"Locked. Unlock the bar…"* or *"Lock the bar…"* off the live config, and AuraMaster's
*"Attached — set its offsets on the Layout page."* appears only while the container is attached. A
descriptor whose strings were resolved once, in the constructor, would tell a player to unlock a bar
they had already unlocked, forever.

The blank spacer is emitted from **what survived the hover**, not from the descriptor: a `footer`
whose every entry answers `nil` draws no spacer either.

**An entry may carry its own color**, which exists for one live line. AuraMaster draws its
conditional *"Attached — set its offsets on the Layout page."* gold, in the body, with no blank line
above it. Bands that were each one color would have recolored that line white or pushed it into the
gray footer behind a spacer — a visual change nobody asked for, arriving under a refactor. Written
as `{ fn, 1, 0.82, 0 }` it is the pixels the host draws today. A `nil` return still drops the line,
colored or not.

### Instance methods

| Member | Meaning |
|---|---|
| `handle:SetLabel(text)` | re-texts the strip. It does **not** re-apply the width |
| `handle:Measure()` | the natural width: `labelWidth + DRAG_HANDLE.RESERVE * 2` |
| `handle:ApplyWidth(minWidth)` | sets the width to `max(Measure(), minWidth or 0)` and returns it |

`handle.label`, `handle.help`, `handle.help.icon` and `handle.bg` are readable; the strip itself is a
`Button` and the host shows, hides, anchors and levels it.

**`SetLabel` deliberately touches no geometry**, and `ApplyWidth` is a method the host calls rather
than a pass the widget runs. Both hosts parent this strip beside a protected frame — AuraMaster's
anchor parents an aura engine, ConsumableMaster's bar holds `SecureActionButtonTemplate` slots — and
both defer layout work to `PLAYER_REGEN_ENABLED`. **After the constructor returns**, nothing here
calls `SetPoint`, `SetShown`, `Show`, `Hide` or `SetWidth` of its own accord, and nothing here
listens to an event or runs an `OnUpdate`. A widget that re-measured itself on either would poke a
protected frame mid-fight from inside the library, where neither host's combat contract can see it.

The one exception is birth: **the constructor ends on `handle:Hide()`**, and the handle comes back
hidden. A strip is born with no width and no anchor point, because placing and sizing it are the
host's calls, so a handle that returned visible would flash a zero-width box at its parent's center
until the host's first pass. AuraMaster's own copy hid its handle in the same breath it built it.
Nothing shows it again; the host says when.

### `lib.__DragHandleMeasurer(face)`

The hidden, **unanchored** FontString a label is measured on, one per face — `spec.labelFont`, and
`GameFontNormalSmall` by default: the same face the label is drawn in. A test replaces this function to measure on a stand-in; that is what the `__` says.

It is not tidiness. AuraMaster's label hangs off the strip, the strip off an anchor, and an anchor
attached to an engine container inherits its **secret** geometry — reading the label's own width
answered a secret number and the width arithmetic raised *"attempt to perform arithmetic on a secret
number value"* out of combat. That host had already paid for this once; measuring on a string
parented to a hidden frame on `UIParent` is what it had to do, and it is the widget's now. A host
whose frames can read secret must also pass `number`, or the guard is decorative in the one place it
matters.

### Chrome: a plain `Button`, never a `BackdropTemplate`

A fill texture at `0, 0, 0, 0.75` and four 1px edge strips at `1, 0.82, 0, 0.6`. Under an anchor
attached to another frame the strip's size can read secret, and `SetBackdrop` does arithmetic on the
size on every set and every resize; four rectangles read nothing. ConsumableMaster's handle **was** a
`BackdropTemplate` and loses it on adoption — the pixels are the same, the hazard is not, and
anything downstream that called `SetBackdropColor` on `bar.handle` would break. Nothing in the
collection does. `spec.name` exists so the frame's global name survives the move, because a named
frame is reachable from a player macro.

### The mark is a big frame around a small texture

The `Button` is `HELP_HIT` square — 18px, the strip's full height — and the texture is `HELP` square
at 8px, centered, leaving `HELP_GUTTER = 5px` on every side. `handle.help` is the frame and
`handle.help.icon` is the art; a host that reads a size back wants one or the other and they are not
the same number. Both copies sized the button to its art, which on this widget's smaller art would
have left an 8×8 click target on a control that opens a settings page.

**`HELP_GUTTER` is exact, never floored**, and that is what keeps the published clearance honest:
the art is placed by `SetPoint("CENTER")`, which splits `HELP_HIT - HELP` in half whatever its
parity, so a floored term in `RESERVE` would advertise a clearance the layout does not draw the
moment those two values differ by an odd amount.

### The label is bounded, not only centered

The label is anchored `LEFT` at `+RESERVE` and `RIGHT` at `-RESERVE` with `SetJustifyH("CENTER")`,
`SetWordWrap(false)` and `SetMaxLines(1)`. Equal bounds and a centered justify draw exactly where a
lone `CENTER` point drew, and the difference only shows on a label longer than the strip: a
`FontString` with one center point has no width of its own and grows both ways, under the mark and
out past the gold edge. `Measure()` normally sizes the strip to its own label, so the ways to get
there are the ways the strip stops tracking the label — a host floors the width at something
narrower (`ApplyWidth(minWidth)`), a host calls `SetLabel` and does not call `ApplyWidth` again,
which `SetLabel` deliberately leaves to the host, or a client that cannot build a measurer measures
`0` while still drawing the real string. Bounded, every one of them truncates inside the label's own
half and the mark keeps its `HELP_CLEAR`.

### The mark takes the strip's drag scripts

A left-drag that starts on the `?` moves the frame, rather than landing in a dead zone. AuraMaster's
copy did this and ConsumableMaster's did not; both get it from here.

### What the host keeps

Everything about **what it says and where it sits**: every string, the placement and the side, the
frame level, the clamp, when the strip shows, whether a drag is allowed, what a right-click does, and
where the moved position is saved. AuraMaster keeps `openSettings` and its combat refusal,
`SavePosition` and its `Secrets` guards, `handleLevel` / `placeHandle` / `clampToHandle`, and one
handle per container. ConsumableMaster keeps `savePosition`, the lock model, `applyLock`'s
`SetShown`, the bar's `moveHint` and its own `OnDragStart`, and passes `bar:GetWidth()` to
`ApplyWidth`.

**Neither host needs a `core/…Setup.lua` seam.** Both files are in `LibKa0s.xml` and therefore
already vendored and loaded in both addons, so adoption is one
`LibStub("LibKa0s-Widgets-1.0", true)` at the module that draws a strip, plus a nil-tolerant
fallback — and the honest fallback is that a build with no library draws no handle.

## Degraded

**With the major absent there is no reorder handle, no row box and — from this version — no drag
handle either.** That is an accepted
cosmetic degradation, stated here so nobody re-solves it host-side: a host-drawn box is the drift the
change exists to remove.

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

**`ReorderList`, at minor 8.** MultiMeters' Columns page and ConsumableMaster's priority list adopt
it together, and the adoption is only correct if a drag feels the same in both. The comparison has
no single host to live in, so it is recorded here:

- Drag a row in **both** addons in one client session. The handle art, the carried copy's alpha and
  offset from the cursor, the gold insertion line and the fade on the picked-up row must be
  identical. Any one differing means a host is overriding something it should not.
- MultiMeters' list has a boundary and ConsumableMaster's does not. Drag a shown column down past
  the divide in MultiMeters: the line must stop at it. Drag the last row of ConsumableMaster's list
  down: it must simply stay put, with no divide to stop at.

This has **not** been run — it needs a live client.


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
