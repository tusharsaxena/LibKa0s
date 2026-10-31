# `LibKa0s-Charts-1.0` — version 1.1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Charts surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Charts-1.0` |
| Files and minors | `Charts.lua` minor **1** · `ChartsRender.lua` minor **1** |
| Shipped in | v1.84.0 |
| Status | **Current** |
| Supersedes | — (first version) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` ≥ 1 (`NEEDS_CORE = 1`) |
| Optional at call time | `LibKa0s-Pool-1.0` (the default `host.pool`), `LibKa0s-Skin-1.0` (`host.owner`), `GameTooltip` (the default tooltip) |
| Confirm in-game | `LibStub("LibKa0s-Charts-1.0").MODULES` → `{ Charts = 1, ChartsRender = 1 }` |

## What this major is

**The Insights chart renderers.** Pooled horizontal bars, stacked bars, range bars, vertical strips,
ranked list panels, swatch legends, stat cards and section dividers, drawn into a content frame the
host owns, with every number in the hover. The library owns the widgets and their geometry; the host
owns the rows, the layout pass that walks the sections, and when to render.

It is promoted from Ka0s Loot History's Insights tab (`modules/AnalyticsCharts.lua`,
`AnalyticsFormat.lua`, the cards in `Analytics.lua`) by way of Ka0s DPS Race's host-agnostic port
(`modules/Results_InsightsCharts.lua`, DpsRace#12), under
[LibKa0s#66](https://github.com/tusharsaxena/LibKa0s/issues/66). `library-stack-§7`'s three bars:

1. **Two consumers, same semantics.** Loot History and DPS Race each carry a copy of these shapes, and
   the port kept Loot History's names so the two diff. Ka0s Bank Ledger and Ka0s Drop Watcher (its
   DropWatcher#12) are the next in line.
2. **No per-consumer escape hatches.** Every `host` field is a look or a seam, never a behavior flag.
   Neither consumer needs a branch here.
3. **A stable abstraction.** A label, a track and a value is a long-lived shape.

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework. Nothing here
is a protected call, so it works in combat.

## Members

Read straight off the LibStub table. The manifest beside this document is the same list as data.

| Name | Since | Meaning |
|---|---|---|
| `Charts:New(content, host)` | 1 | A context drawing into `content`. `host` is optional. Raises when neither `host.pool` nor `LibKa0s-Pool-1.0` is there. One per content frame, for the session |
| `Charts.K` | 1 | The layout constants. Shared across addons: read them and never write them |
| `Charts.OTHER` | 1 | The key `StackSegments` folds a remainder under |
| `Charts.truncate(text, maxChars)` | 1 | `text` capped at `maxChars` glyphs, `"..."` among them, and whether it was cut. Counts UTF-8 glyphs, so a cut never splits one |
| `Charts.tipText(label, value)` | 1 | The hover text: the whole label and the value it encodes |
| `Charts.fitFontSize(stringWidth, maxWidth, baseSize, minSize)` | 1 | `baseSize`, shrunk only when the string overflows, never under `minSize` |
| `Charts.StackSegments(mags, order, maxSegs)` | 1 | `{ key -> magnitude }` as at most `maxSegs` segments, the rest under `OTHER`, in `order`'s order, and the total. Pure |
| `Charts.RangeScale(rows)` | 1 | A range section's two ends. Pure |
| `Charts.StripSlots(innerW, n)` | 1 | A strip's slot and column widths. Pure |
| `Charts.StripLabels(buckets, slot, innerW)` | 1 | `{ [bucket index] = x offset }` for the labels that show. Pure |
| `MAJOR`, `MINOR`, `MODULES` | 1 | As on every major |

## The host table

Every field is optional, so `Charts:New(content)` draws a working chart in Ka0s Default's look.

| Field | Shape | Left out |
|---|---|---|
| `owner` | a registered skin owner (the addon's folder name) | no skin. An owner `LibKa0s-Skin-1.0` does not know, or no Skin at all, is the same |
| `pool` | `New()`, `Acquire(pool, factory)`, `ReleaseAll(pool)` | `LibKa0s-Pool-1.0`. `Reskin` also reads a pool's `active` and `free` arrays when it has them |
| `panel` | `function(parent) -> frame` | the owner's `Panel`, else a plain `BackdropTemplate` frame |
| `tip` | `function(owner, lines, anchor)` | `GameTooltip`: the first line as a title in `tipTitle`, the rest in `tipBody`, wrapped |
| `hideTip` | `function()` | `GameTooltip:Hide()` |
| `colors` | a table by the names below, each `{ r, g, b[, a] }` or a function answering one | per name, the owner's token, else Ka0s Default's value |
| `fonts` | `{ label, axis, heading, divider, panelTitle, caption, figure }`, font object names | per name, `GameFontHighlightSmall`, `GameFontDisableSmall`, `GameFontNormal`, `GameFontNormalLarge`, `GameFontNormalSmall`, `GameFontDisableSmall`, `GameFontNormalHuge` |
| `palette` | a list of `{ r, g, b }`, or a function answering one, read at every draw | the owner's `chart.series`, else Ka0s Default's 21 hues. A function answering an empty list reads the same defaults |
| `text` | `function(parent, font, justify) -> FontString` | a plain FontString in that font object, and with an owner on the owner's face (`S.Font`) |
| `paint` | `function(fs, color)` | `SetTextColor` |
| `fill` | `function(texture, color, alpha)`, for flat color: tracks, rules, swatches, the axis, the mark | `SetColorTexture` |
| `barFill` | `function(texture, color, alpha)`, for a bar of data | the owner's `BarTexture`, else `host.fill`, else `SetColorTexture` |
| `onReskin` | `function(ctx)` | nothing. See *Reskin* |

### Where a look comes from

The host first, then the owner's skin, then Ka0s Default's value, field by field.

| Color | Token | Draws |
|---|---|---|
| `body` | `text.body` | a stacked or list row's default label, a range bar's mark |
| `value` | `text.value` | the value column, legend labels |
| `muted` | `text.muted` | a sublabel, axis labels, a range scale |
| `heading` | `text.heading` | headings, dividers, panel titles, a card's figure |
| `caption` | `text.disabled` | a card's caption |
| `rule` | `section.rule` | a divider's rules |
| `track` | `chart.track` | a bar's track |
| `bar` | `chart.bar` | a bar or a column with no color of its own |
| `axis` | `chart.axis` | a strip's axis line |
| `tipTitle` | `gtip.title` | the default tooltip's title |
| `tipBody` | `gtip.value` | the default tooltip's lines |

## The context

`ctx.colors` and `ctx.fonts` are readable. `ctx.colors` is filled in place, so a reference a host
keeps moves with `Reskin`. `ctx.content` is the frame given to `New`.

| Member | Meaning |
|---|---|
| `ctx:Pool(name)` | The pool called `name`, made on first ask |
| `ctx:ReleaseAll()` | Park every pool made here. A layout pass starts here, and a pass after the first builds no frame |
| `ctx:Reskin()` | See *Reskin* |
| `ctx:paletteColor(rank)` | The palette color at 1-based `rank`, cycling |
| `ctx:paletteMap(orderedKeys)` | `{ key -> color }` by position, so a key keeps one color across charts |
| `ctx:showTip(owner, tip, anchor)` | Show a string, or lines (a title, then strings). Nothing for nil, `""` or an empty table. The anchor defaults to `ANCHOR_CURSOR_RIGHT` |
| `ctx:acquire(pool, factory, parent)` | A pooled widget from `factory(ctx, parent or content)`, for a host's own widget in a context's pool |
| `ctx:sectionHeader(parent, title)` | A heading FontString; the renderer or the caller places it |
| `ctx:sectionDivider(parent, title)` | A centered title flanked by two rules; the caller anchors its TOPLEFT |
| `ctx:listPanel(parent, title)` | A list panel with its title |
| `ctx:strip(parent)` | A strip's frame |
| `ctx:card(parent, caption)` | A stat card: `{ frame, label, value, caption }` |
| `ctx:setCard(card, value, tip, maxW, color)` | Its figure, its color (`color`, else `heading`, and `Reskin` keeps a caller's color), its hover (`tip`, else `caption:  value`). `maxW` shrinks an overflowing figure, and each call starts from the full size |
| `ctx:placeHeader(header, y, pad)` | Place a heading at the cursor; answers the cursor under it |
| `ctx:bindBarText(bar, row, labelColor)` | A bar row's words, for a host binding a pooled row of its own |
| `ctx:placeScale(pool, y, w, pad, lo0, hi0, fmt)` | The scale line under a range section |
| `ctx:placeAxisLine(strip, width)` | The axis line under a strip's columns |

`parent` defaults to `ctx.content` everywhere.

### The renderers

Each answers the cursor under what it drew and skips an empty `rows`, hiding its header and leaving
the cursor. `w` is the content's width and `pad` the left and right margin. No renderer writes a
row.

| Renderer | Rows |
|---|---|
| `ctx:renderBarSection(pool, header, rows, y, w, pad, legendPool)` | `{ label, sublabel, color, labelColor, frac, value, tip }`. The longest `frac` fills the track. `color` defaults to `bar`, `labelColor` to the bar's color. A `sublabel` is a second, muted line, and every row of the section is then `K.BAR_H2` tall. With `legendPool`, a legend of the rows follows |
| `ctx:renderStackedBarSection(pool, header, rows, y, w, pad)` | `{ label, sublabel, labelColor, value, tip, segments }`, a segment `{ frac, color, tip }`. Fracs are already relative to the longest row. A row draws at most `K.MAX_STACK_SEGS` |
| `ctx:renderRangeSection(pool, header, rows, y, w, pad, scalePool, fmt)` | `{ label, sublabel, color, labelColor, lo, hi, mark, value, tip }`, from `lo` to `hi` with a mark at `mark` (optional), on one scale from the lowest `lo` to the highest `hi` (not 0-based). With `scalePool` and `fmt`, a line names the scale's two ends |
| `ctx:renderLegend(pool, rows, y, w, pad, x0)` | `{ label, color, value, tip }`. Chips start at `x0`, by default the track's left edge, and wrap |
| `ctx:renderStrip(pool, header, strip, buckets, y, w, pad, top)` | `{ count, label, info, color }`. A column's height is `count / top`, `top` being the largest count (at least 1) when nil. A zero column is a faint stub. `info` is the hover. `Charts.StripLabels` picks the labels that show, level, in a band under the axis |
| `ctx:renderListPanel(pool, panel, rows, y, colW, pad, rightW)` | `{ name, nameColor, right, tip, onClick }`, at most `K.LIST_MAX`. `rightW` sizes the value column (48 without). Answers the panel's **height**, not a cursor. A reused row forgets the last one's click |

A row's `tip` (a string, or lines) replaces the default hover, which is `Charts.tipText` of its label
and value.

## Reskin

`ctx:Reskin()` refills `ctx.colors`, repaints every pooled widget on the active **and** the free
list and the chrome the context made, then calls `host.onReskin(ctx)`. What a row was bound with is
the host's data, so `onReskin` is where a host re-runs its layout. A context with an `owner` runs this
itself on the owner's `OnLooksChanged`, and its faces, panels and bar textures are recorded with the
engine, so the skin switch reaches them without a call. Any other host calls `Reskin` when its look
moves, and needs it only for colors that are functions or for a redraw through `onReskin`.

## Adopting it

Nothing is owed until a host adopts. The names are the ones both addons already call, except the
constructor, which is a colon call here (the port's `Charts.New`), and `Charts.Host`, which stays in
DPS Race.

- **Set up a host table,** in the addon's own setup seam, and fall back to its existing drawing path or
  to an empty tab when the major is absent. A host that names `owner` and nothing else has Loot
  History's look.
- **Ka0s DPS Race:** `modules/Results_InsightsCharts.lua` becomes its `Charts.Host()` section. Pass
  `barFill` as well as `fill` only if a data bar should differ from a track. Then delete the private
  port and its deviation row in that repo's `docs/ARCHITECTURE.md`.
- **Ka0s Loot History:** `modules/AnalyticsCharts.lua` moves its renderers from `Analytics:render*`
  onto a context, and `Analytics:Reskin` keeps only what is Insights' own. It stays the owner of
  `renderCharCompanion` and its row builder, which call `Charts.StackSegments` in place of
  `Analytics._charStackSegments`.

Three things a Loot History adoption sees change, all from DPS Race's owner round of 2026-10-28:

- A strip's labels are level, in a band `K.STRIP_LABEL_H` (16) tall, not rotated in one 44 tall, and a
  column may be `K.STRIP_BAR_MAX` (36) wide, not 14.
- `truncate` counts glyphs, and writes `"..."`: the ellipsis glyph is the one thing the port kept that
  `tests/test_prose.lua` refuses in a shipped file, because a skin's face may draw it as an empty box.
  `K.LABEL_MAXCHARS` is the whole string's cap, the periods among it.
- Loot History's `tests/analytics_golden.txt` pins its draw calls, so it moves with the adoption.

## What is not here

- **Row building.** What a bar means, class and quality colors, money strings, day keys, and sorting a
  map are each one addon's domain, or one line.
- **The layout pass.** A host walks its own sections, passing the cursor along.
- **Rotated axis labels,** for the reason above.
- **Line charts.** `LibKa0s-Widgets-1.0`'s `LineChart` is the time-series chart, with its own math.
- **Per-section sizes.** `K` is one set of numbers shared by every consumer, which is the point.

## Vendoring

A new major in a whole-folder re-vendor: two new files, `Charts.lua` and `ChartsRender.lua`, and two
new rows in `LibKa0s.xml`. A consumer whose degradation stub does not name this major owes nothing
until it adopts. `ChartsRender.lua` is paired on the shell's minor (`__renderMinor`,
`__renderShellMinor`), as `WidgetsLineChart.lua` is on Widgets'.

## Consumers

None as of v1.84.0's first cut. Loot History and DPS Race adopt it at their re-vendor
(Ka0sAddonsCommonTasks `docs/2026-10-31-FINDINGS_REMEDIATION/M2_LIBRARY_RELEASE.md`, step 4).
