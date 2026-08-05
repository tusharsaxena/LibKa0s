# `LibKa0s-Options-1.0` — version 7.6.3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Options surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Options-1.0` |
| Files and minors | `Options.lua` **7** · `OptionsWidgets.lua` **6** · `OptionsScroll.lua` **3** |
| Version key | `<Options>.<OptionsWidgets>.<OptionsScroll>`, in load order — the same three numbers `lib.MODULES` reports |
| Shipped in | v1.8.0 |
| Status | **Current** |
| Supersedes | [version 6.6.3](./version-6.6.3-docs.md) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`) |
| Confirm in-game | `LibStub("LibKa0s-Options-1.0").MODULES` → `{ Options = 7, OptionsWidgets = 6, OptionsScroll = 3 }` |

`Since` in the tables below names the **file and minor** in which the member first appeared — `O7`
for `Options.lua` minor 7, `W4` for `OptionsWidgets.lua` minor 4, `S1` for `OptionsScroll.lua`
minor 1. Minors 1 and 2 of each file were never tagged, so `O1`/`W1`/`S1` means "present for as long
as any consumer could have had this major".

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

## What changed at this version

**`O.PADDING_X` is published on the instance, and the published/internal split is written down.**
One new instance member; `OptionsWidgets.lua` and `OptionsScroll.lua` do not move, and no descriptor
field, row field or drawn pixel changes.

`lib.LAYOUT` holds thirteen constants and version 6.6.3 published three of them — `ROW_VSPACER`,
`SECTION_HEADING_H`, `BUTTON_PAIR_REL`. `PADDING_X`, the horizontal inset this library draws its own
header, divider and body to, was not among them. A host aligning a bespoke widget with any of the
three therefore had no way to **read** the number, and one host restated it as
`Const.PANEL_PADDING_X = 16` and positioned against that. `options-ui-§8`'s MUST NOT against host
copies of a library constant cannot be complied with for a constant the library keeps to itself.

- **`Options.lua` minor 7** — `O.PADDING_X` on the instance, at the same value the library draws
  with. **Nothing moves**: a host deletes its copy and reads this instead.

**One scalar, not six, and never the table.** `O.LAYOUT = L` is deliberately not offered: `lib.LAYOUT`
is shared by every instance, so handing it out lets one host's mutation retune every other host's
panels — a worse failure than the copying this fixes. And `HEADER_TOP`, `HEADER_HEIGHT`,
`DEFAULTS_W`, `SECTION_TOP_SPACER` and `SECTION_BOTTOM_SPACER` stay internal because **no host in
the collection has demonstrated a need for any of them**. Publishing them on the grounds that they
are repeated rather than that they are shared is anti-pattern **#55** (`library-stack-§7`): under
the additive-only rule a wrong shared abstraction is surface this library keeps forever. Each is
published the day a host shows it needs it.

Every unpublished `lib.LAYOUT` key now carries an `-- INTERNAL: <KEY> — <why>` line in the source,
and `tests/test_options.lua` fails on a key that is neither published nor annotated — so the next
constant added cannot recreate the gap quietly.

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
| `skipRestoreAll` | function(row) | no | O1 | Return true to exclude a row from a global reset. AbsorbTracker vetoes its profiles page, where a reset would delete user data. |
| `afterRestoreAll` | function | no | O1 | Runs after the rows are reset and **before** the panels refresh, for state no schema row owns — a dragged frame's saved position. The order is load-bearing: a refresh first would paint the pre-hook values. |
| `scheduleTimer` | function(fn, delay) | no | O1 | Backs the 50 ms colour-drag throttle. A descriptor field rather than an AceTimer embed, because embedding would be this library's second dependency-budget breach. Without it a drag commits every frame. |
| `getLSM` | function | no | O1 | Returns LibSharedMedia-3.0, for `LSMValues`. |
| `validate` | function | no | O1 | Runs once, before the page builders. A host's schema-shape check. |
| `onAceGUI` | function(AceGUI) | no | O1 | Handed the resolved AceGUI so the host can stash it (Ka0s standard §3.4) for its own page files. |
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

## The instance surface

Everything `lib:New(descriptor)` returns on the instance.

| Name | Since | Meaning |
|---|---|---|
| `CreatePanel(name, title, opts)` | O1 (canvas contract: **O5**) | A canvas Frame with the unified header stamped on top, returning the `ctx` every render call threads through. `opts` = `{ pageKey, isMain, defaultsButton, defaultsTooltip }`. Registers the ctx so the refresh fan-out reaches it. Also stamps the **Blizzard canvas contract** — `OnCommit` and `OnRefresh` inert (writes land immediately through the host's write seam, and `SetRenderer` already owns re-show), and `OnDefault` **forwarding** to the panel's `defaultsOnClick` so the Settings window's footer control and the header Defaults button stay one implementation. A forwarder rather than an assignment because hosts park `defaultsOnClick` *after* this returns. |
| `EnsureDefaultsButton(panel)` | O1 | Builds the header's Defaults button on the panel's **first OnShow**, never at build time. Idempotent, and a no-op on a panel that did not ask. |
| `EnsureScroll(ctx)` | O1 | The lazy AceGUI ScrollFrame, patched for an always-visible scrollbar. |
| `ClearScroll(ctx)` | O1 | Release the children, reset the section tracker, and **reassign** `ctx.refreshers`. |
| `Section(ctx, label)` | W1 | A full-width Heading, with the inter-section spacers. |
| `AddSpacer(scroll, height)` | W1 | An invisible full-width row. |
| `TextRow(ctx, text, opts)` | **W6** | A full-width Label, left-justified, added to `EnsureScroll(ctx)` and returned. `opts.fontObject` is a `_G` font-object **name**; `opts.justify` defaults to `"LEFT"`. Returns nil when AceGUI or the scroll is absent. Owns the `w.label` / `SetJustifyH` / `SetFontObject` guard pair **once**. |
| `BuildLandingPage(ctx, spec)` | **W6** | The whole landing body: clear, logo, one-liner, then a heading and its rows per section. See [The landing page](#the-landing-page). |
| `AttachTooltip(widget, label, tooltip)` | W1 | Works on AceGUI widgets and on plain frames. |
| `InlineButtonPair(ctx, left, right)` | W1 | Two action buttons (not settings) in one Flow row, each inset to `BUTTON_PAIR_REL`. A throwing `onClick` is reported, never propagated into AceGUI's dispatch. |
| `RenderField(ctx, row, parent, relWidth)` | W1 | Dispatch by `row.type` to one of the five makers. Returns nil for an unknown type rather than erroring — a misspelled type costs one row, not the page. |
| `SessionCheckbox(ctx, parent, relWidth, spec)` | W1 | A checkbox wired to caller-supplied `get`/`set` instead of a settings path, for runtime-only toggles that must never persist. |
| `RenderRows(ctx, rows, afterGroup, pairWith)` | W1 | The flow engine, over an **explicit** row list — which is what lets a host render a filtered subset through the same code. |
| `RenderSchema(ctx, pageKey, afterGroup, pairWith)` | W1 | The per-page wrapper. |
| `RegisterOptionsPage(key, name, builder)` | O1 | Queue a page. Builders run once, in order, at `CreateOptionsPanel`. |
| `CreateOptionsPanel()` | O1 | Resolve AceGUI, hand it to the host, validate, register the main canvas, run every builder. |
| `OpenOptionsPanel()` | O1 (combat refusal: O3) | Open the category. **Refuses** under combat and never defers-and-replays. |
| `RestoreDefaults(pageKey, ctx)` | O1 | The per-page Defaults button. Refreshes only the ctx it was given. |
| `RestoreAllDefaults()` | O1 | Every non-vetoed row, then `afterRestoreAll`, then a full refresh. |
| `SetRenderer(ctx, fn)` | O1 | Declare how a page draws itself. The library owns *when*: first show, and again after a refresh marked it dirty while hidden. Also builds the Defaults button and refuses to render under combat. |
| `RefreshAllPanels()` | O1 (two tiers: O3) | **Structural.** Re-run each page's renderer, so rows that appeared or disappeared are drawn. Hidden pages are flagged dirty and re-render on their next show. |
| `RefreshScalars()` | O3 | **In place.** Refreshers only, no rebuild — what every widget maker's own `set()` calls, since writing a value does not change which rows exist. Each is pcall'd, so one dead widget cannot take the UI with it. |
| `__pages()` | O1 | The pages that actually built. A raising builder is reported by key and costs only itself. |
| `RenderGrid(ctx, items)` | **W4** | Lay arbitrary widgets out two per row, caller-ordered. The sibling of `RenderRows`: that one walks schema rows and emits sections, this one takes whatever the caller hands it — a schema row, or `{ make = fn }` for a bespoke widget, or `wide = true` for its own line. For a list whose length is not in the schema (one checkbox per macro, per unit, per spell). Items are guarded individually. **Two asymmetries with `RenderRows`, both deliberate today and both tracked:** it does **not** call `scroll:DoLayout()` at the end, so a page rendered through `RenderGrid` alone must call it itself; and it renders into `EnsureScroll(ctx)` with no `parent` override, so it cannot draw into a container the host owns. See [KickCD#10](https://github.com/tusharsaxena/KickCD/issues/10). |
| `LSMValues(mediaType)` | W1 (never-empty: **W4**) | A **deferred** closure pulling the live media hash at dropdown-render time. Never empty: a media library that has not loaded yet yields a single `None` placeholder, because a dropdown with no options cannot be opened and the CLI would refuse even the stored value. Deferred is load-bearing: LSM-backed rows evaluate this inside a schema-row literal at file load, long before the addons that register media have run. |
| `PatchAlwaysShowScrollbar(scroll)` | S1 | The scrollbar override. Idempotent, and reversed on `OnRelease` — AceGUI pools ScrollFrames, so an unreleased patch escapes into whichever addon recycles the widget next. |
| `ROW_VSPACER` / `SECTION_HEADING_H` / `BUTTON_PAIR_REL` | W1 | The cross-slice layout constants, mirrored onto the instance so a host's own page code stays in lockstep with the engine's spacing. |
| `PADDING_X` | **O7** | The horizontal inset the library draws its own header, divider and body to. Read it to align a bespoke widget with any of the three; **do not restate it** (options-ui-§8). |
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

## Row fields the flow engine reads

Beyond `path`, `type`, `label`, `default` and the tooltip body — `tooltip`, which is what every
Ka0s host's schema declares, or `desc`, this library's own name for it; both are read:

| Field | Since | Meaning |
|---|---|---|
| `group` | W1 | Section heading. A new value emits a `Section` and flushes the row in progress. |
| `solo` | W1 | Render alone in the left half of its own line, for visual pivots. |
| `skipRender` | W1 | Keep the row in the schema — so resets and the CLI still see it — but let the host draw it bespoke. |
| `min` / `max` / `step` | W1 | Slider range. Snapping is relative to `min`, not to zero. |
| `values` on a `number` row | **W5** | Makes it a **dropdown** rather than a slider, matching what `LibKa0s-Slash-1.0`'s parser has always understood the shape to mean. Inferred, not opted into — a `values` list that resolves empty falls back to the slider. |
| `values` / `sorting` | W1 (ordered-array shape: W3) | Dropdown list, in either shape: an **ordered array** of `{ value =, text = }` (position is the order, and `sorting` is ignored) or a **key map** `{ KEY = "Label" }` (`sorting` keeps a deliberate order instead of alphabetising). A degenerate key *set* `{ KEY = true }` labels each entry with its key. `values` may be a function, evaluated at render and parse time. |
| `dialogControl` | W1 | An in-tree widget type (`LSM30_*`, `EditBox`). Unregistered types fall back to a plain Dropdown, so an optional media-widget library staying absent costs a swatch, not the option. |
| `hasAlpha` / `disabledIf` | W1 | Colour picker: alpha channel — **default true**, declare `false` to suppress it — and the sibling path whose truth greys the swatch out. |
| `commitOn` | W1 | `"change"` makes this slider commit on the drag, throttled; `"release"` opts out of a descriptor-wide `sliderCommit`. Default is release-only. |
| `isPercent` | W1 | Slider renders a 0–1 ratio as a percentage. |
| `maxLetters` | W1 | Edit box only. |

## Compatibility

The API is **additive-only**: a member, descriptor field or row field may be added in a later minor,
never removed or repurposed, so a host written against `1.1.1` keeps working unmodified here. This
version adds `O.PADDING_X` and nothing else, at the value 6.6.3 already drew with — so adopting it
cannot move a panel.

**`lib.LAYOUT` is not itself part of the instance surface, and will not become so.** The keys a host
may read are the individual scalars listed above. The rest are internal, each annotated in the source
with why, and each is published — as its own scalar — the day a host demonstrates it needs it.
Publishing the table would hand every host a mutable handle on every other host's spacing.

The three files move as one. A consumer holding `Options.lua` from one vendored copy and
`OptionsWidgets.lua` from another is not a supported state and LibStub cannot detect it — which is
why `docs/releasing.md` mandates whole-folder re-vendoring.
