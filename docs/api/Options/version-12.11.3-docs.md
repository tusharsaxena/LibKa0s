# `LibKa0s-Options-1.0` — version 12.11.3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Options surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Options-1.0` |
| Files and minors | `Options.lua` **12** · `OptionsWidgets.lua` **11** · `OptionsScroll.lua` **3** |
| Version key | `<Options>.<OptionsWidgets>.<OptionsScroll>`, in load order — the same three numbers `lib.MODULES` reports |
| Shipped in | v1.22.0 |
| Status | **Current** |
| Supersedes | [version 11.10.3](./version-11.10.3-docs.md) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`) |
| Confirm in-game | `LibStub("LibKa0s-Options-1.0").MODULES` → `{ Options = 12, OptionsWidgets = 11, OptionsScroll = 3 }` |

`Since` in the tables below names the **file and minor** in which the member first appeared — `O12`
for `Options.lua` minor 12, `W11` for `OptionsWidgets.lua` minor 11, `S1` for `OptionsScroll.lua`
minor 1. Minors 1 and 2 of each file were never tagged, so `O1`/`W1`/`S1` means "present for as long
as any consumer could have had this major".

## What changed at this version

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

**Ten internal `lib.LAYOUT` keys stay unpublished**, each annotated in `Options.lua` with why:
`TAB_PAD_X`, `TAB_GAP`, `TAB_MIN_W`, `TAB_ROW_GAP`, `CONTENT_LEFT`, `CONTENT_RIGHT`,
`CHROME_DIVIDER_GAP_TOP`, `CHROME_DIVIDER_H`, `CHROME_DIVIDER_GAP_BOTTOM`, and at 12.11.3
`CONTENT_BOTTOM`, which replaced `TAB_BASELINE_H`.

## Previously, at 11.10.3

**`Options.lua` minor 11 / `OptionsWidgets.lua` minor 10 — the tabbed page chrome, seen in a client
and fixed there** (options-ui-§13, §14).

10.9.3 introduced the chrome slot, the tab strip and the page banner. Everything at this version
comes from looking at that feature running in the client: one bug no headless suite could have
found, and three ways the chrome did not look like the UI around it. **Nothing here is a new public
member.** A consumer re-vendors and gets the same surface, drawn correctly — the only published
number that moves is `BANNER_H`, and it moves from a fixed height to a floor.

**The strip was drawn on top of the banner, and every tab was unclickable** (W10). `placeTabs`
derived row 1's y offset from the row index alone, which put it at `ctx.chrome`'s `TOPLEFT` — the
anchor `PageBanner`'s dropdown already occupies. The band was *reserved* correctly the whole time;
only the placement ignored the reservation, which is why a suite that asserted the reservation
passed straight over it.

The arithmetic is now `O.__tabPlacement`, pure rows-to-pixels over numbers — the same kind of seam
`__layoutTabs` already gave the wrap decision — and `placeTabs` does nothing but apply it, with
`ctx.__bannerHeight` folded in as the `top` term the inline math never had.

**`BANNER_H` is a floor, not a height, and it moves 30 → 44** (O11). `PageBanner` no longer forces
its dropdown to `BANNER_H`; it measures the frame and floors at that number. An AceGUI `Dropdown`
carrying a label renders taller than a bare control, and the forced height was clipping it.

**The chrome band spans the content column, not the panel** (O11). `CreatePanel`'s chrome anchor and
`anchorScroll` both read `L.CONTENT_LEFT` / `L.CONTENT_RIGHT` from one seam, so a banner can no
longer run wider than the scroll beneath it. No test could see this: a headless chrome has no width.

**A gap, a hairline rule and a second gap separate the banner from the strip** (W10,
options-ui-§14). Drawn by `PageBanner`, and folded into `ctx.__bannerHeight` by the new pure
`O.__bannerBand`, so `TabStrip`'s placement never re-derives that arithmetic. The strip's own band —
its rows plus its 1px baseline — is reserved through the matching pure `O.__tabBand`.

**Tabs are cut from the client's own tab art** (W10). The three-slice
`Interface\OptionsFrame\UI-OptionsFrame-InActiveTab` / `-ActiveTab` pair the client's own tab
template uses — two 20px end caps and a middle stretched between them — with the client's
`UI-Character-Tab-Highlight` glow on hover. The **selected** tab's art hangs 3px lower, so its foot
covers the strip's baseline and the tab joins the page below it. That merge, not a color change, is
what makes a row of buttons read as tabs; the selected tab is still the *disabled* one, which is how
Blizzard marks selection and why clicking the tab you are on cannot re-render the page you are
already looking at.

This is the one place in `OptionsWidgets.lua` that prefers a Blizzard texture to a drawn one, and
the reason is that here the look **is** the requirement: a tab is a piece of client chrome a player
already recognizes, so an approximation reads as a near-miss in a way a drawn slider or a drawn
section rule never does. The first attempt — flat fills and four 1px gold edges per button — was
legible, correct, and unmistakably not part of the UI around it.

The strip's baseline is drawn in the neutral gray the client borders a panel with rather than in
gold, because it is the top edge of the content area and not a separator between two pieces of
chrome. The banner/strip hairline keeps its dim gold, for the opposite reason: a separator between
two pieces of chrome should disappear rather than read.

**`TAB_PAD_X` moves 12 → 18** (O11, internal). A label has to clear the 20px end caps; at 12 it sat
on the rounded shoulder, which was half of why a tab read as a bordered rectangle.

**Every piece of new furniture travels in the ledger that matches its lifetime.** The banner's
divider is in `ctx.__chromeKids`, redrawn only by a full page render; the strip's baseline is in
`ctx.__tabKids`, redrawn by every tab click. Put the baseline in the wrong one and a click that
shrinks the strip from two rows to one leaves the old line floating over the page's first setting.
Each tab's three art slices are children of the button itself, so `releaseLedger` takes them with it
and they need no ledger entry at all.

**Six new internal `lib.LAYOUT` keys**, none published, each annotated in `Options.lua` with why:
`CONTENT_LEFT`, `CONTENT_RIGHT`, `CHROME_DIVIDER_GAP_TOP`, `CHROME_DIVIDER_H`,
`CHROME_DIVIDER_GAP_BOTTOM`, `TAB_BASELINE_H`.

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
| `ClearScroll(ctx)` | O1 | Release the children, reset the section tracker, and **reassign** `ctx.refreshers`. |
| `Section(ctx, label)` | W1 | A full-width Heading, with the inter-section spacers. |
| `AddSpacer(scroll, height)` | W1 | An invisible full-width row. |
| `TextRow(ctx, text, opts)` | **W6** | A full-width Label, left-justified, added to `EnsureScroll(ctx)` and returned. `opts.fontObject` is a `_G` font-object **name**; `opts.justify` defaults to `"LEFT"`. Returns nil when AceGUI or the scroll is absent. Owns the `w.label` / `SetJustifyH` / `SetFontObject` guard pair **once**. |
| `BuildLandingPage(ctx, spec)` | **W6** | The whole landing body: clear, logo, one-liner, then a heading and its rows per section. See [The landing page](#the-landing-page). |
| `AttachTooltip(widget, label, tooltip)` | W1 | Works on AceGUI widgets and on plain frames. |
| `InlineButtonPair(ctx, left, right)` | W1 | Two action buttons (not settings) in one Flow row, each inset to `BUTTON_PAIR_REL`. A throwing `onClick` is reported, never propagated into AceGUI's dispatch. |
| `RenderField(ctx, row, parent, relWidth)` | W1 | Dispatch by `row.type` to one of the five makers. Returns nil for an unknown type rather than erroring — a misspelled type costs one row, not the page. |
| `SessionCheckbox(ctx, parent, relWidth, spec)` | W1 | A checkbox wired to caller-supplied `get`/`set` instead of a settings path, for runtime-only toggles that must never persist. |
| `RenderRows(ctx, rows, afterGroup, pairWith, opts)` | W1 (`opts.noHeadings`: **W9**) | The flow engine, over an **explicit** row list — which is what lets a host render a filtered subset through the same code. `opts = { noHeadings = true }` suppresses the automatic `Section` heading, for a page whose sections are drawn as tabs instead (options-ui-§13); the row-boundary flush and `ctx.lastGroup` advance still happen. Omitted by every untabbed caller. |
| `RenderSchema(ctx, pageKey, afterGroup, pairWith)` | W1 | The per-page wrapper. |
| `RenderTabbedSchema(ctx, pageKey, afterGroup, pairWith)` | **W9** | Render one page as a tab strip over its own sections. The partition is by `row.group`, in declaration order — one tab is exactly one group, and there is no second field naming a tab (options-ui-§13). Fewer than two groups draws no strip and falls back to `RenderSchema` byte-for-byte. A stale `ctx.activeTab` heals to the first group. A tab click re-enters through `ClearScroll` and this function again — the same structural path a subject change already takes, but that path carries no combat refusal to inherit: `SetRenderer`'s guard covers opening or switching a category, not redrawing inside an already-open panel, so a tab click needs no guard and none is added (options-ui-§13). Returns the group names, in tab order. |
| `TabStrip(ctx, spec)` | **W9** | A pinned tab strip in `ctx.chrome` (options-ui-§13). `spec = { tabs = { { key, label, tooltip } }, value, onSelect }`. One `Button` per tab, the active tab the disabled one. Wraps its buttons across rows via `__layoutTabs`, places them via `__tabPlacement`, and reserves the band via `__tabBand` + `SetChromeHeight` — **after** the wrap is known. Each tab is three slices of the client's `Options_Tab_*` atlases; the selected one is drawn from the Active family and its foot overlaps the `Options_InnerFrame` content panel `TabStrip` also draws (**W11**). Re-places itself once when `ctx.chrome` first learns a real width (**W11**). Returns the buttons in tab order, or nil having drawn nothing. |
| `PageBanner(ctx, spec)` | **W9** | The page's picker, pinned above the strip and the scroll (options-ui-§14) — the only picker a page may have. `spec = { label, list, order, value, onSelect, tooltip }`. Draws one AceGUI `Dropdown` into `ctx.chrome`, plus the gap / hairline / gap that separate it from the strip (options-ui-§14); records the whole band in `ctx.__bannerHeight` via `__bannerBand` and reserves it with `SetChromeHeight`. Measures the dropdown and **floors** at `L.BANNER_H` rather than forcing that height (**W10**). **Draw it before `TabStrip`** — see [What changed at this version](#what-changed-at-this-version). Returns the dropdown, or nil having drawn nothing. |
| `SetChromeHeight(ctx, height)` | **O10** | Reserve `height` pixels of pinned chrome above the scroll, and re-anchor a live scroll to match. Idempotent. `height <= 0` hides `ctx.chrome`. Call only after the wrap of whatever is being reserved is known. |
| `__scrollTopInset(ctx)` | **O10** | `L.CHROME_GAP + (ctx.chromeHeight or 0)` — the seam `EnsureScroll` and `SetChromeHeight` both read for the scroll's top anchor, so the two cannot disagree. |
| `__layoutTabs(widths, available, gap)` | **W9** | Pure arithmetic: pack tab pixel widths into rows that fit `available`. A tab wider than `available` is placed alone rather than dropped. Returns rows of 1-based indices into `widths`. Test seam for the wrap rule, callable with no widgets. |
| `__tabPlacement(widths, available, gap, top, tabH, rowGap)` | **W10** | Pure arithmetic: the wrap from `__layoutTabs` turned into `{ index, width, x, y }` per tab, plus the row count. `top` is the banner's finished band, which is why row 1 no longer lands on the banner. Callable with no widgets. |
| `__tabBand(top, rowCount, tabH, rowGap)` | **W10** (signature: **W11**) | Pure arithmetic: how many pixels the strip reserves in total, banner included — which is also where the content panel's top edge lands. Took a fifth `baselineH` and returned two numbers through 11.10.3. |
| `__bannerBand(rawHeight, gapTop, ruleH, gapBottom)` | **W10** | Pure arithmetic: the banner's own height widened by the gap, hairline and gap that separate it from the strip (options-ui-§14). What `ctx.__bannerHeight` holds. |
| `__releaseChrome(ctx)` | **W9** | Test seam. Hides, unparents and forgets every widget in both chrome ledgers (`ctx.__chromeKids`, `ctx.__tabKids`). |
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
version adds **no member at all** either. It replaces the tab art with the client's own atlases,
replaces the strip's 1px rule with the content panel whose edge it was pretending to be, and fixes
the first-render wrap.

Two things move that a careful host could notice. `TAB_H` goes `24` → `37`, so a host that reads it
to reserve room beside a strip reserves 13px more and is still correct. And `__tabBand` — an
internal test seam, not part of the surface — loses its fifth argument and its second return along
with `TAB_BASELINE_H`; no host calls it, and this note exists because the *library's own tests* did.

A consumer that calls none of the chrome surface still renders byte-identically to 9.8.3, for the
reason it always did: `ctx.chromeHeight` starts at `0`, so `EnsureScroll`'s anchor computes to the
same `CHROME_GAP` (`8`). A consumer that draws a banner but no strip gets no content panel, because
`TabStrip` is the only thing that draws one.

**`lib.LAYOUT` is not itself part of the instance surface, and will not become so.** The keys a host
may read are the individual scalars listed above. The rest are internal, each annotated in the source
with why, and each is published — as its own scalar — the day a host demonstrates it needs it.
Publishing the table would hand every host a mutable handle on every other host's spacing.

The three files move as one. A consumer holding `Options.lua` from one vendored copy and
`OptionsWidgets.lua` from another is not a supported state and LibStub cannot detect it — which is
why `docs/releasing.md` mandates whole-folder re-vendoring.
