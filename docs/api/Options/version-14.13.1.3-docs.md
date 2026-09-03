# `LibKa0s-Options-1.0` — version 14.13.1.3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Options surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Options-1.0` |
| Files and minors | `Options.lua` **14** · `OptionsWidgets.lua` **13** · `OptionsCompose.lua` **1** · `OptionsScroll.lua` **3** |
| Version key | `<Options>.<OptionsWidgets>.<OptionsCompose>.<OptionsScroll>`, in load order — the same four numbers `lib.MODULES` reports. **The key gained a component at this version**, because the major gained a file. |
| Shipped in | v1.24.0 |
| Status | Superseded |
| Supersedes | [version 13.12.3](./version-13.12.3-docs.md) |
| Superseded by | [version 14.13.2.3](./version-14.13.2.3-docs.md) — `MasterControls` takes a `leadButton` |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`) |
| Confirm in-game | `LibStub("LibKa0s-Options-1.0").MODULES` → `{ Options = 14, OptionsWidgets = 13, OptionsCompose = 1, OptionsScroll = 3 }` |

`Since` in the tables below names the **file and minor** in which the member first appeared — `O14`
for `Options.lua` minor 14, `W13` for `OptionsWidgets.lua` minor 13, `C1` for `OptionsCompose.lua`
minor 1, `S1` for `OptionsScroll.lua` minor 1. Minors 1 and 2 of each file were never tagged, so
`O1`/`W1`/`S1` means "present for as long as any consumer could have had this major".

## What changed at this version

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
| `resetProfile` | function | no | O9 | Supply it and a global reset becomes a **profile reset**: the `sessionOnly` rows are swept row by row, then this is called, then every panel refreshes. Pass `function() NS.db:ResetProfile() end`. With it supplied the library narrows the row walk itself — see `RestoreAllDefaults` below. |
| `skipRestoreAll` | function(row) | no | O1 | Return true to exclude a row from a global reset. With `resetProfile` supplied the profiles-page veto this was invented for is **implied** (an AceDBOptions row is not `sessionOnly`, so it is already outside the narrowed walk); the field is still honored, and is the whole policy for a host that supplies no `resetProfile`. |
| `afterRestoreAll` | function | no | O1 | Runs after the rows are reset **and after `resetProfile`**, and **before** the panels refresh, for state in neither the schema nor the profile. The order is load-bearing: a refresh first would paint the pre-hook values. A dragged frame's saved position is **not** an example any more — a position lives in the profile and comes back with it. |
| `scheduleTimer` | function(fn, delay) | no | O1 | Backs the 50 ms colour-drag throttle. A descriptor field rather than an AceTimer embed, because embedding would be this library's second dependency-budget breach. Without it a drag commits every frame. |
| `getLSM` | function | no | O1 | Returns LibSharedMedia-3.0, for `LSMValues`. |
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
| `InlineButtonPair(ctx, left, right)` | W1 | Two action buttons (not settings) in one Flow row, each inset to `BUTTON_PAIR_REL`. A **nil** `right` draws the left button alone, at the pair's width, so it still lines up with every other page's — which is the shape a frameless addon's Master controls tab needs. A throwing `onClick` is reported, never propagated into AceGUI's dispatch. |
| `RenderField(ctx, row, parent, relWidth)` | W1 | Dispatch by `row.type` to one of the five makers. Returns nil for an unknown type rather than erroring — a misspelled type costs one row, not the page. |
| `SessionCheckbox(ctx, parent, relWidth, spec)` | W1 | A checkbox wired to caller-supplied `get`/`set` instead of a settings path, for runtime-only toggles that must never persist. |
| `RenderRows(ctx, rows, afterGroup, pairWith, opts)` | W1 (`opts.noHeadings`: **W9**) | The flow engine, over an **explicit** row list — which is what lets a host render a filtered subset through the same code. `opts = { noHeadings = true }` suppresses the automatic `Section` heading, for a page whose sections are drawn as tabs instead (options-ui-§13); the row-boundary flush and `ctx.lastGroup` advance still happen. Omitted by every untabbed caller. |
| `RenderSchema(ctx, pageKey, afterGroup, pairWith)` | W1 | The per-page wrapper. |
| `RenderTabbedSchema(ctx, pageKey, afterGroup, pairWith)` | **W9** | Render one page as a tab strip over its own sections. The partition is by `row.group`, in declaration order — one tab is exactly one group, and there is no second field naming a tab (options-ui-§13). **Every page draws a strip from W13, including a one-group page** — the `#groups < 2` fallback to `RenderSchema` is gone, and the only exemption is a page the host does not route through this function at all (the AceConfig-drawn Profiles page). A page whose rows carry **no** `group` is reported by page key through the descriptor's `print` and rendered untabbed. A stale `ctx.activeTab` heals to the first group. A tab click re-enters through `ClearScroll` and this function again — the same structural path a subject change already takes, but that path carries no combat refusal to inherit: `SetRenderer`'s guard covers opening or switching a category, not redrawing inside an already-open panel, so a tab click needs no guard and none is added (options-ui-§13). Returns the group names, in tab order. |
| `TabStrip(ctx, spec)` | **W9** | A pinned tab strip in `ctx.chrome` (options-ui-§13). `spec = { tabs = { { key, label, tooltip } }, value, onSelect }`. One `Button` per tab, the active tab the disabled one. Wraps its buttons across rows via `__layoutTabs`, places them via `__tabPlacement`, and reserves the band via `__tabBand` + `SetChromeHeight` — **after** the wrap is known. Each tab is three slices of the client's `Options_Tab_*` atlases; the selected one is drawn from the Active family and its foot overlaps the `Options_InnerFrame` content panel `TabStrip` also draws (**W11**). Re-places itself once when `ctx.chrome` first learns a real width (**W11**). **Its geometry is invariant under the selection from W13** — see [What changed at this version](#what-changed-at-this-version). Returns the buttons in tab order, or nil having drawn nothing. |
| `SubTabStrip(ctx, parent, spec)` | **W13** | A **secondary** strip drawn inside the scroll as ordinary page content, parented to a frame the host supplies (options-ui-§13). Same `spec` shape as `TabStrip`, same selection-invariant pitch, its own ledger (`ctx.__subTabKids`) released on entry, and **no** content panel and **no** `SetChromeHeight` — the page already has both. Returns the buttons in tab order **and** the total height the strip occupies, so the host can size the frame it handed in, or nil having drawn nothing. The selection is the host's state: `spec.value` and `spec.onSelect` are the whole contract, and the convention for the collection is `ctx.activeSubTab` as a table keyed by the primary tab's key, session-only and never persisted. |
| `PageBanner(ctx, spec)` | **W9** | The page's picker, pinned above the strip and the scroll (options-ui-§14) — the only picker a page may have. `spec = { label, list, order, value, onSelect, tooltip }`. Draws one AceGUI `Dropdown` into `ctx.chrome`, plus the gap / hairline / gap that separate it from the strip (options-ui-§14); records the whole band in `ctx.__bannerHeight` via `__bannerBand` and reserves it with `SetChromeHeight`. Measures the dropdown and **floors** at `L.BANNER_H` rather than forcing that height (**W10**). **Draw it before `TabStrip`.** Returns the dropdown, or nil having drawn nothing. |
| `PageHeader(ctx, spec)` | **W13** | A host-drawn block pinned in the same band, for controls that apply to **every** tab (options-ui-§14). `spec = { height, build = function(ctx, frame) end, divider = <default true> }`. Anchors a `Frame` across `ctx.chrome`, ledgers it, draws the hairline unless told not to, records the widened band in `ctx.__bannerHeight` via `__bannerBand`, reserves it with `SetChromeHeight`, then calls `build` inside a `pcall` — a raising builder is reported and costs the block, not the page. **A page draws at most one chrome block**: this and `PageBanner` both release `__chromeKids` and both write `ctx.__bannerHeight`, so the second call replaces the first. **Draw it before `TabStrip`.** Returns the frame, or nil having drawn nothing. |
| `SetChromeHeight(ctx, height)` | **O10** | Reserve `height` pixels of pinned chrome above the scroll, and re-anchor a live scroll to match. Idempotent. `height <= 0` hides `ctx.chrome`. Call only after the wrap of whatever is being reserved is known. |
| `__scrollTopInset(ctx)` | **O10** | `L.CHROME_GAP + (ctx.chromeHeight or 0)` — the seam `EnsureScroll` and `SetChromeHeight` both read for the scroll's top anchor, so the two cannot disagree. |
| `__layoutTabs(widths, available, gap)` | **W9** | Pure arithmetic: pack tab pixel widths into rows that fit `available`. A tab wider than `available` is placed alone rather than dropped. Returns rows of 1-based indices into `widths`. Test seam for the wrap rule, callable with no widgets. |
| `__tabPlacement(widths, available, gap, top, rowPitch)` | **W10** (signature: **W12**) | Pure arithmetic: the wrap from `__layoutTabs` turned into `{ index, width, x, y }` per tab, plus the row count. `top` is the banner's finished band, which is why row 1 no longer lands on the banner. `rowPitch` is the tab ART's measured height, not the button's. Callable with no widgets. |
| `__tabBand(top, rowCount, tabH, rowPitch)` | **W10** (signature: **W12**) | Pure arithmetic: how many pixels the strip reserves in total, banner included — which is also where the content panel's top edge lands. **(n − 1) pitches plus one whole tab**, because every row but the last is overlapped by the one under it. Took a `rowGap` through 12.11.3 and a `baselineH` through 11.10.3. |
| `__bannerBand(rawHeight, gapTop, ruleH, gapBottom)` | **W10** | Pure arithmetic: the banner's own height widened by the gap, hairline and gap that separate it from the strip (options-ui-§14). What `ctx.__bannerHeight` holds. |
| `__releaseChrome(ctx)` | **W9** | Test seam. Hides, unparents and forgets every widget in both chrome ledgers (`ctx.__chromeKids`, `ctx.__tabKids`). |
| `__tabArtHeight()` | **W13** | The measured row pitch — the **unselected** tab art's own height, or `TAB_H` where nothing can be measured. Memoized on success only. Published because the invariant a suite has to pin is unassertable without the one number the band and every row offset are both built from. |
| `__resetTabArtHeight()` | **W13** | Forget that measurement. A harness seam; an atlas does not change size mid-session. |
| `RegisterOptionsPage(key, name, builder)` | O1 | Queue a page. Builders run once, in order, at `CreateOptionsPanel`. |
| `CreateOptionsPanel()` | O1 | Resolve AceGUI, hand it to the host, validate, register the main canvas, run every builder. |
| `OpenOptionsPanel()` | O1 (combat refusal: O3) | Open the category. **Refuses** under combat and never defers-and-replays. |
| `RestoreDefaults(pageKey, ctx)` | O1 | The per-page Defaults button. Refreshes only the ctx it was given. |
| `RestoreAllDefaults()` | O1 | Without `resetProfile`: every non-vetoed row, then `afterRestoreAll`, then a full refresh — unchanged. **With `resetProfile` (O9):** only the `sessionOnly` rows, then `resetProfile()`, then `afterRestoreAll`, then a full refresh. |
| `SetRenderer(ctx, fn)` | O1 | Declare how a page draws itself. The library owns *when*: first show, and again after a refresh marked it dirty while hidden. Also builds the Defaults button and refuses to render under combat. |
| `RefreshAllPanels()` | O1 (two tiers: O3) | **Structural.** Re-run each page's renderer, so rows that appeared or disappeared are drawn. Hidden pages are flagged dirty and re-render on their next show. |
| `RefreshScalars()` | O3 | **In place.** Refreshers only, no rebuild — what every widget maker's own `set()` calls, since writing a value does not change which rows exist. Each is pcall'd, so one dead widget cannot take the UI with it. |
| `RefreshPanel(ctx, structural)` | O8 | **One page, either tier.** `structural` true re-runs that ctx's renderer; false runs its refreshers in place. A hidden page is flagged dirty and repaints on its next show, so the caller never has to ask whether it is on screen. For a host whose page repaints off its own message bus rather than off a widget's `set()`. |
| `__pages()` | O1 | The pages that actually built. A raising builder is reported by key and costs only itself. |
| `RenderGrid(ctx, items)` | **W4** | Lay arbitrary widgets out two per row, caller-ordered. The sibling of `RenderRows`: that one walks schema rows and emits sections, this one takes whatever the caller hands it — a schema row, or `{ make = fn }` for a bespoke widget, or `wide = true` for its own line. For a list whose length is not in the schema (one checkbox per macro, per unit, per spell). Items are guarded individually. **Two asymmetries with `RenderRows`, both deliberate today and both tracked:** it does **not** call `scroll:DoLayout()` at the end, so a page rendered through `RenderGrid` alone must call it itself; and it renders into `EnsureScroll(ctx)` with no `parent` override, so it cannot draw into a container the host owns. See [KickCD#10](https://github.com/tusharsaxena/KickCD/issues/10). |
| `ColorPair(spec)` | **C1** | A color swatch and its *use class color* companion, as exactly two adjacent rows. See [The schema composers](#the-schema-composers). |
| `FontGroup(spec)` | **C1** | The canonical six font rows, in the canonical order. |
| `BorderGroup(spec)` | **C1** | The canonical four border rows, optionally preceded by a *Show border* toggle. |
| `BarGroup(spec)` | **C1** | The canonical four bar rows, for a surface with a **fill texture**. |
| `MasterControls(spec)` | **C1** | The canonical Master controls rows **and** the `afterGroup` hook that draws the tab's closing button pair. Returns two values. |
| `FONT_FLAGS` / `FONT_FLAGS_SORT` | **C1** | The font-flag key map and its declared order. |
| `VISIBILITY_VALUES` / `VISIBILITY_SORT` | **C1** | The four general-visibility values and their declared order. General visibility is a dropdown, not a boolean: a boolean can only ever answer two of the four. |
| `MASTER_GROUP` | **C1** | The literal `"Master controls"` — the group name, the tab label and the `afterGroup` key are one string, because the group name **is** the hook key. |
| `CLASS_COLOR_NOTE` | **C1** | The sentence every composed swatch's tooltip carries, in place of the `disabledIf` it must never have. |
| `LSMValues(mediaType)` | W1 (never-empty: **W4**) | A **deferred** closure pulling the live media hash at dropdown-render time. Never empty: a media library that has not loaded yet yields a single `None` placeholder, because a dropdown with no options cannot be opened and the CLI would refuse even the stored value. Deferred is load-bearing: LSM-backed rows evaluate this inside a schema-row literal at file load, long before the addons that register media have run. |
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
| `hasAlpha` / `disabledIf` | W1 | Color picker: alpha channel — **default true**, declare `false` to suppress it — and the sibling path whose truth grays the swatch out. **`disabledIf` must not be used for a class-color companion** (options-ui-§17, anti-patterns #74): the swatch is still read, for its alpha, so graying it says something untrue. No composed row carries it. |
| `classColorSource` / `classColorUnit` | **C1** | `"player"` or `"unit"`, plus the token where it is `"unit"`. Stamped on **both** rows of every composed color pair. The library reads neither — they are the declaration an audit reads, because a path prefix cannot be trusted to say whose class a control means (options-ui-§17). |
| `commitOn` | W1 | `"change"` makes this slider commit on the drag, throttled; `"release"` opts out of a descriptor-wide `sliderCommit`. Default is release-only. |
| `isPercent` | W1 | Slider renders a 0–1 ratio as a percentage. |
| `maxLetters` | W1 | Edit box only. |

## The schema composers

New at `OptionsCompose.lua` minor 1. Five functions, each expanding one declaration into the
canonical block of **ordinary schema rows** — options-ui-§15 for the Master controls tab, §16 for the
font / border / bar groups, §17 for the class-color companion.

**They are pure functions.** No widget, no AceGUI, no state, and nothing the caller handed in is ever
written to — a host may hoist its spec, and its `extra` rows, to a file constant and re-render
freely. What comes out is indistinguishable from hand-written rows, which is what lets every existing
seam keep working unchanged.

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
| `extra` | array | Rows appended **after** the canonical block, order continuing, copied rather than stamped in place. An extra declares its own `path` in full. |

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
label), `frameless`, `debugConsolePath` (default `"state.debugConsole"`), `onResetPosition` and
`onResetAll`.

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
- **The two resets are the tab's closing button pair**, not schema rows — they are acts rather than
  settings, so they would not belong in the CLI or in the reset sweep. The second return value is the
  `afterGroup` hook for the group; wire it as
  `H.RenderTabbedSchema(ctx, page, { ["Master controls"] = tail }, pairWith)`. The **group name is
  the hook key**, so renaming the group detaches the hook.

## Compatibility

The API is **additive-only**: a member, descriptor field or row field may be added in a later minor,
never removed or repurposed, so a host written against `1.1.1` keeps working unmodified here. Six
members and three row fields are added at this version and nothing is taken away.

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

## Moving to version 14.13.2.3

One field, on one composer. `O.MasterControls` takes `leadButton = { text, tooltip, onClick }`, ONE
act of the host's own drawn beside the resets — the pair's empty right half on a frameless addon
(`[<verb>] [Reset all settings]`), its own row above the full pair on a framed one. It exists because
`§15` fixes the resets' wording and the composer is the only thing that writes it, so an addon that
wanted a button beside them had to keep a second copy of *"Reset all settings"* in its own source.

Nothing else in the major moved. A host written against this version is correct at 14.13.2.3
unmodified: the field is additive, and its absence is exactly the behaviour described here.
