# `LibKa0s-Feed-1.0` — version 1.1.1.1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Feed surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Feed-1.0` |
| Files and minors | `Feed.lua` minor **1** · `FeedModel.lua` minor **1** (paired on `Feed.lua`'s minor) · `FeedRow.lua` minor **1** (paired on `Feed.lua`'s minor) · `FeedInput.lua` minor **1** (paired on `Feed.lua`'s minor) |
| Shipped in | unreleased (v1.119.0) |
| Status | **Current** |
| Supersedes | none (new major) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 20 (`NEEDS_CORE = 20`, for `ClassColor`) |
| Optional at call time | `LibKa0s-Skin-1.0` (through Core's `__SkinFacade`), `LibKa0s-Widgets-1.0` (the drag handle and the strips) and LibSharedMedia-3.0 (a named font, bar or background), each resolved at call time behind a type check, with no floor |
| Confirm in-game | `LibStub("LibKa0s-Feed-1.0").MODULES` → `{ Feed = 1, FeedModel = 1, FeedRow = 1, FeedInput = 1 }` |

## What changed at this version: the major is new

Ka0s Loot History #38 asks for toast feeds: up to ten short-lived rows on screen at once, the newest
at the anchor, merged in place on a repeat, frozen under the pointer. `LibKa0s-Toast-1.0` is the
other shape (the oldest toast at the saved point, one timer per toast), and a feed mode there would be
a behavior flag that turns its members around, so the feed is a major of its own in four files:
`Feed.lua` (the shell), `FeedModel.lua` (the pure model), `FeedRow.lua` (the rows) and
`FeedInput.lua` (the pointer, the drag and the strip). The design planned three; it named the
fourth as the peel to make if `Feed.lua` passed 900 lines, and with the input written into it the
shell was 954, so the input left on that seam before the release, which is why the version key has
four parts. The design is `docs/superpowers/specs/2026-11-27-libka0s-feed-design.md`.

## Why this exists: the promotion record

`library-stack-§7` bar 1 asks for two consumers before a component is promoted into the library, as a
SHOULD; a promotion the owner rules a suite-wide component is conformant and takes no deviation row.
This one is that ruling:

| | |
|---|---|
| Ruled by | Tushar Saxena (owner) |
| Date | 2026-11-27 |
| Where | Ka0s Loot History plan `docs/superpowers/plans/2026-11-27-tooltip-toasts-farm.md`, decision D24 (ruling X1 of the #38 design): extend LibKa0s upstream, as a Toast minor 5 or a new major, whichever the M3.0 design shows fits the library's conventions; that design chose the new major |
| Ships with | Ka0s Loot History #38 |
| Second consumer | none named yet |

Bar 2 holds because there is one presentation argument (`d.content`) and one optional reducer
(`d.merge`); every other field is a value or a getter carrying a player's setting (where, how big,
how it moves, how it looks), never a switch that says which consumer is calling, and overflow has no
option: a full feed drops its oldest row. The two fields closest to the line, `motion.pin` and
`motion.rightDismiss`, are player toggles: hover always pauses, and `pin` only widens the pause from
the hovered row to the whole feed.

## The lib-level surface

| Member | What it is | Since |
|---|---|---|
| `New(d)` | A new feed instance. Raises naming `d.content` when `d` is not a table or `d.content` is not a function | **1** |
| `STRATA` | `"HIGH"`, frame-layering's T5 interactive toast tier: the container's strata | **1** |
| `SLOTS` | `{ "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }`, the anchor slots. Never mutate it | **1** |
| `MAX_QUEUE` | `10` payloads waiting while frozen or held | **1** |
| `SHOWN`, `SHOWN_MAX` | `5` and `10` rows on screen at once: the default and the most | **1** |
| `WIDTH`, `ROW_HEIGHT`, `ICON_SIZE`, `PADDING`, `GAP` | `320`, `48`, `36`, `6`, `5` px | **1** |
| `SLOT_INSET` | `20` px a slot keeps from the screen edge | **1** |
| `NUDGE_MAX` | `600` UIParent units a nudge may move the feed from its slot, either way | **1** |
| `ENTER_TIME`, `HOLD`, `FADE_TIME` | `0.25`, `5`, `1` s | **1** |
| `MERGE_WINDOW` | `3` s a key stays open to a merge after its last push | **1** |
| `PULSE_TIME`, `SLIDE_TIME`, `DROP_FADE` | `0.6`, `0.15`, `0.2` s | **1** |
| `MAX_DT` | `0.1` s, the most one tick advances | **1** |

`lib.__methods`, `lib.__model`, `lib.__row`, `lib.__input` and `lib.__shell` are this major's
internals (the method table every `New` copies, the pure half, the rows, the input, and the shell's
own steps the input calls back into), for its paired files and its suites only. They are not
contract, and the member manifest leaves them out.

## The contract

### The constructor

```lua
local Feed = LibStub("LibKa0s-Feed-1.0", true)
local feed = Feed:New(d)   -- one feed instance; raises when d.content is not a function
```

One `New` per on-screen feed (Loot History makes three). Nothing is built until the first `Push`,
`Preview` or `SetLocked(false)`. `New` copies the shell's method table into the instance; the shell
reaches its model, row and input halves through `lib.__model`, `lib.__row` and `lib.__input` at call
time, so a newer secondary reaches an existing feed on its next call.

### The descriptor `d`

"Value or getter" means the field may be a plain value or a function of no arguments that answers
one. Getters are read **only** on the first build and on `Refresh()`, once each into a cached
snapshot; the clock never calls a getter. A getter that raises answers nothing, and a field that
answers nothing usable falls back to the published default.

| Field | Type | Default | Meaning | Since |
|---|---|---|---|---|
| `content` | **function, required** | — | `content(spec, payload, key)` fills the reused row spec (below). Answers `false` to skip the payload (a `Push` of it answers `false`). Runs under `pcall`; an error goes to `geterrorhandler()` and the payload is skipped. Called on present, merge, `Update`, `Repaint`, `RepaintAll`, a skin switch and the settle re-read, **never** from the clock's per-frame path | **1** |
| `merge` | function or nil | nil | `merge(old, new, key)` answers the merged payload, under `pcall`. nil, a reducer answering nil, or one that raises (its error to `geterrorhandler()`) keeps the newer payload. Called only on a merge | **1** |
| `owner` | string or nil | nil | The skin owner (the addon's folder name). The rows, the drag handle and the strips follow that owner's skin. nil, or an unregistered owner, draws the plain look | **1** |
| `name` | string or nil | nil | Global name of the container; rows are unnamed | **1** |
| `layout` | table, or a getter answering one | see below | Placement and size | **1** |
| `motion` | table, or a getter answering one | see below | Enter, hold, fade, merge window, pulse, bar, slide, pin, settle | **1** |
| `style` | table, or a getter answering one | see *Style over the skin* | The style overrides over the owner's skin | **1** |
| `maxQueue` | number, or a getter | `MAX_QUEUE` (10) | Payloads waiting while frozen or held; the oldest is dropped past it. Floored; under 1 takes the default | **1** |
| `onEnter` | function or nil | nil | `onEnter(row, payload, key)` on pointer enter, under `pcall`. For the host's tooltip | **1** |
| `onLeave` | function or nil | nil | `onLeave(row, payload, key)`, under `pcall`. Called exactly once for every `onEnter`, a row dropped or freed while hovered included | **1** |
| `onClick` | function or nil | nil | `onClick(payload, button, key)` on mouse up, under `pcall`. Not called for a right-click while `rightDismiss` is on, nor for the left button while unlocked. The host reads modifiers itself | **1** |
| `onMoved` | function or nil | nil | `onMoved(x, y)` after a drag, with the nudge for the current slot in UIParent units, already clamped. The host writes it through its write seam; the library has already re-anchored | **1** |
| `strings` | table or nil | nil | `{ HANDLE = "...", HANDLE_TIP = "..." }`, the drag handle's label and its tooltip's body (titled with the label), read raw. Every string the library draws comes from the host | **1** |
| `debug` | function or nil | nil | `debug(tag, fmt, ...)` sink, under `pcall`, tag `"Feed"` | **1** |

The three grouped tables are read with `rawget`, and an unknown key is ignored, so a later minor adds
keys additively.

#### `layout` keys

| Key | Values | Default | Since |
|---|---|---|---|
| `slot` | one of `SLOTS` | `"BOTTOMRIGHT"` | **1** |
| `x`, `y` | nudge in UIParent units, clamped to `±NUDGE_MAX` | `0`, `0` | **1** |
| `grow` | `"UP"` or `"DOWN"` | `"UP"` | **1** |
| `shown` | rows on screen at once, floored and clamped to 1..`SHOWN_MAX` | `SHOWN` (5) | **1** |
| `width` | px, the container's and every row's | `WIDTH` (320) | **1** |
| `rowHeight` | the least a row is high, px | `ROW_HEIGHT` (48) | **1** |
| `iconSize` | px, clamped to the row's inner height (`rowHeight - 2 * padding`) | `ICON_SIZE` (36) | **1** |
| `padding` | px inside a row | `PADDING` (6) | **1** |
| `gap` | px between rows | `GAP` (5) | **1** |
| `align` | `"left"` or `"right"`: text justification; `"right"` also swaps each secondary line's left and right parts | `"left"` | **1** |
| `iconSide` | `"left"` or `"right"` | `"left"` | **1** |
| `scale` | the container's scale | `1` | **1** |

#### `motion` keys

| Key | Values | Default | Since |
|---|---|---|---|
| `enter` | `"none"`, `"fade"`, `"left"`, `"right"`, `"up"`, `"down"` (a slide from that side) | `"fade"` | **1** |
| `enterTime` | s; `"none"` forces 0 | `ENTER_TIME` (0.25) | **1** |
| `hold` | s at full alpha | `HOLD` (5) | **1** |
| `fadeTime` | s; 0 vanishes | `FADE_TIME` (1) | **1** |
| `mergeWindow` | s; 0 never merges | `MERGE_WINDOW` (3) | **1** |
| `pulse` | bool: a merge pulses the border and the count | `true` | **1** |
| `timerBar` | bool: the countdown bar along the row's foot | `false` | **1** |
| `smooth` | bool: rows slide to a new Y at a constant speed that covers the distance in `SLIDE_TIME`; off snaps | `true` | **1** |
| `pin` | bool: hover freezes the **whole** feed (true) or pauses only the hovered row (false) | `true` | **1** |
| `rightDismiss` | bool: a right-click dismisses the row | `true` | **1** |
| `settle` | s; 0 is off. One extra `content` call at `paintedAt + settle`, for state that lags its own event (client-quirks-§3) | `0` | **1** |

### The payload and the row spec

The library stores the host's `payload` untouched (it never reads into it) and hands it back to
`content`, `merge`, the callbacks and `Get`. `content` fills a **reused flat spec**: one spec table
per pooled row, wiped before each call (its three `lines` tables kept and wiped too), so a push or a
merge allocates nothing once the pools are warm.

| Spec field | Type | Drawn as | Since |
|---|---|---|---|
| `icon` | texture path or file id | the row's icon, cropped at 0.07 | **1** |
| `tint` | `{ r, g, b[, a] }` | the payload's meaning color (quality, for example): the icon's edge, and the row border when `style.borderTint` is on | **1** |
| `badge` | string | small text over the icon's top-left corner (an item level) | **1** |
| `title`, `titleColor` | string, color | the first line | **1** |
| `count`, `countColor` | string, color | a chip after the title (`"x3"`); while the row pulses it is drawn in the glow color unless `countColor` is set | **1** |
| `prefix`, `prefixColor` | string, color | dim text before the title | **1** |
| `lines[1..3]` | `{ left, leftColor, right, rightColor }` | up to three secondary lines | **1** |
| `sub`, `subColor` | string, color | a last small line | **1** |
| `highlight` | bool, or a color | the ADD-blend glow edge, breathing on the clock; `true` takes the glow color | **1** |

Strings arrive finished: inline icon markup and colored coin text are the host's. A color left nil
takes the style's text color. The spec has no kind, quality rule, price or source; those stay in the
host. A row is never under `rowHeight`, and grows by `fontSize2 + 2` for each filled secondary line
(`sub` included) past the padding and the title's `fontSize + 2`.

### Instance members

Every member raises when called on anything but an instance from `Feed:New`.

| Member | Answers | Contract | Since |
|---|---|---|---|
| `Push(key, payload, opts)` | `"new"`, `"merged"`, `"queued"` or `false` | `key` may be nil (never merges). `opts.sticky` gives the row no countdown. A live (not dropping) or waiting entry under `key` whose last push is within `mergeWindow` takes a merge (below) and answers `"merged"`, or `false` when the merged payload's content skips it (its row drops). Else, while frozen or held, the payload waits (`"queued"`). Else it presents at the anchor (`"new"`), the oldest row past `shown` dropping. `false` when `content` answered false or raised. The host plays its own sound on `"new"` | **1** |
| `Get(key)` | payload or nil | The live or waiting payload under `key` (a dropping row's is gone) | **1** |
| `Update(key, payload)` | bool | Replace the payload and repaint in place: no hold restart, no pulse, no move. A row whose content now skips it drops. A waiting entry takes the payload only | **1** |
| `Repaint(key)` | bool | Re-run `content` for the row on screen under `key`; false when there is none | **1** |
| `RepaintAll()` | — | Re-run `content` and the style paint for every live row (a dropping row is restyled only). Also run by the library on the owner's `OnLooksChanged` | **1** |
| `Dismiss(key)` | bool | Start that row's drop fade (`DROP_FADE`); a waiting payload under `key` is let go at once | **1** |
| `Clear()` | — | The stand-down: every row released and hidden, entries freed, the waiting list emptied, the clock disarmed, hover and freeze cleared, the strip forgotten and hidden, the handle hidden, locked again. The pools are kept and the instance is reusable | **1** |
| `Hold()` / `Release()` | — | While held, new payloads wait (merging there). Live rows keep running. `Release` drains. The host's "show in combat: off" calls these; the library carries no combat flag | **1** |
| `Refresh()` | — | Re-read every getter, re-snapshot `layout`, `motion` and `style`, re-anchor, apply the shown cap, re-lay out and repaint. After a profile switch or a settings write. Nothing before the first build | **1** |
| `Preview(list)` | number | `list` is `{ { key, payload }, ... }`; each presents sticky and marked a preview row through the same present and paint path (preview-mode's same-render-path rule). Neither a hold nor a freeze queues them, and they take no merge and no `Get`. Replaces the previous preview rows. Answers how many show | **1** |
| `ClearPreview()` | — | Frees only the preview rows, at once (no drop fade) | **1** |
| `SetLocked(locked)` | bool (now locked) | `false` makes the container movable and docks a `LibKa0s-Widgets-1.0` `DragHandle` on the stack's far edge with `d.strings.HANDLE`. Refused (answers true) in combat and without Widgets. `true` hides the handle; a lock during a drag ends the move and saves it through `onMoved` | **1** |
| `IsLocked()` | bool | | **1** |
| `SetClickThrough(on)` | — | `EnableMouse(not on)` on every row, and on every row acquired while on. Turning it on **also** ends every hover (each with its `onLeave`) and the freeze, and drains the waiting list, because the client fires no `OnLeave` when the mouse is disabled | **1** |
| `SetStrip(kind, text)` | — | `kind` `"test"` or `"sim"` docks a `W.TestStrip` with the host's `text` across the stack's far edge; any other `kind` hides it. Hidden while the drag handle shows. Called before the build, it applies when the feed builds | **1** |
| `Visible()` | array of keys | Newest first; `false` for a key-less row. A new table per call (not a hot path) | **1** |
| `Stats()` | table | `{ live, waiting, dropping, frozen, held, locked, clickThrough, awake, shown, built }`, every field always present; `shown` is the layout's cap once built, else 0 | **1** |
| `Frame()` | frame or nil | The container once built | **1** |

`__Step(dt)` is an **internal test seam**: one tick of exactly `dt` seconds (no `MAX_DT` clamp),
whether the clock is armed or not, and nothing before the first build. It is not contract
(`library-stack-§7`), and `Kit.publicMembers` leaves it out of the parity surface.

### Merge in place

On a merge the library:

1. sets the payload to `d.merge(old, new, key)` under `pcall`, or to `new` when there is no reducer,
   it answers nil, or it raises;
2. sets the entry's last push time to now, which reopens the merge window;
3. restarts the hold. A row still entering keeps its enter (the enter never replays and never cuts
   short); any other row goes back to the start of its hold, and a fading row snaps back to alpha 1;
4. sets the pulse to `PULSE_TIME` when `motion.pulse` is on;
5. moves the entry to the newest slot, unless the feed is frozen, in which case it stays put;
6. repaints through `content`, re-lays out and wakes the clock.

A merge into a waiting entry replaces its payload and its time only. A dropping entry never takes a
merge: the push is a new entry. The window is wall-clock time since the last push, so a row frozen
under the pointer, or one already fading at default motion, can fall outside it.

### The waiting list and the drain

Entries wait while the feed is frozen or held, in arrival order, capped at `maxQueue` (the oldest
dropped silently). On unfreeze, `Release()` or `SetClickThrough(true)`, only the **newest `shown`**
waiting entries present, oldest first, so the newest ends at the anchor and nothing flashes in only
to be dropped. The rest are freed.

### Placement

The container is anchored by its **grow-origin edge** at the slot (`BOTTOM` growing up, `TOP` growing
down, joined to the slot's column), so a height change never moves the newest row. The slot keeps
`SLOT_INSET` from the screen edges it touches, and the nudge is added to that inset; the offsets are
divided by the container's scale, so the stored nudge stays in UIParent units and a scale change grows
the stack about its anchor. Rows fill the container's width, the newest at Y 0 and each next one above
(or below) it by its height and the gap. The container is clamped to the screen, so a grow-up stack in
a `TOP` slot is pushed down by the clamp.

A drag stop turns the container's rect into the nudge from the slot (the inverse of the placement,
clamped to `±NUDGE_MAX`), keeps it in the snapshot until the host's next `Refresh`, re-anchors from
the slot and calls `onMoved(x, y)`. The slot is the save: the container is not left user-placed.

## Style over the skin

The facade is Core's `__SkinFacade(d.owner)`, read at **call time** (the Feed files load before the
Skin major), and every name used on it is one of Skin's trampolines, so a newer Skin minor's code
draws. Every part has a `<part>FromSkin` companion that defaults to **true**, so a host that passes no
`style` draws the skin (skinning-§9). Every color is `{ r, g, b, a }` (or `r`, `g`, `b`, `a` keys),
clamped to 0..1.

| Part | Keys (defaults) | Resolution | Since |
|---|---|---|---|
| Background | `bgFromSkin`, `bgType` (`"solid"`; or `"none"`, `"gradient"`, `"texture"`), `bgColor` (`{0, 0, 0, 0.7}`), `bgColor2` (`{0.15, 0.15, 0.15, 0.7}`), `bgTexture` (an LSM `background` name) | From skin: `S.Shell(row, { noTopBar = true, noBands = true, noBorder = true })`, recorded, so a skin switch repaints it. Override: the row's Shell record is replaced with `keepEdge`, so a skin repaint leaves the host's fill alone, and the row's own fill draws nothing, a tinted `WHITE8X8`, a horizontal gradient from `bgColor` to `bgColor2`, or the LSM background (solid when LibSharedMedia-3.0 or the name is absent) | **1** |
| Border | `borderStyleFromSkin`, `borderStyle`, `borderSize` (`1`), `borderColorFromSkin`, `borderColor` (`{0.3, 0.3, 0.3, 1}`), `borderTint` (`false`), `borderClass` (`false`) | The style, whether it shows and its size from `S.BarBorder(borderStyle, true, borderSize, borderStyleFromSkin)`, drawn on the row's own edge. The color, meaning and class first (skinning-§6): `borderTint` with a `spec.tint`, then `borderClass` (`core.ClassColor("player")`), then the skin's `bar.border`, else `borderColor`. While a row pulses the border's alpha breathes `0.6 + 0.4 * sin(pulse / PULSE_TIME * pi)` | **1** |
| Fonts | `fontFromSkin`, `font` (an LSM `font` name or a path), `fontSizeFromSkin`, `fontSize` (`12`, the title), `fontSize2` (`10`, every other string), `fontFlags` (`"@skin"`), `fontShadowFromSkin`, `fontShadow` (`true`) | Every string through `S.HudFont` with the face from `S.Resolve("hud.font", font, fontFromSkin)`, the size from `S.HudFontSize`, the flags from `S.FontFlags`. One font object per look; no string gets a `SetFont` of its own. The owner's *Ignore fonts* is honored by the facade itself | **1** |
| Text color | `fontColorFromSkin`, `fontColor` (white), `fontClass` (`false`) | The spec's own color wins (meaning first). Then `fontClass` (the class color); then from skin, `S.HudTextColor()` for the title and `S.HudLabelColor()` for the prefix, the secondary lines and the sub; else `fontColor` | **1** |
| Countdown bar | `barFromSkin`, `barTexture` (an LSM `statusbar` name), `barColor` (white) | From skin: `S.BarTexture` in `S.BarFillColor()`. Else the named bar in `barColor`, flat where none resolves. Drawn only with `motion.timerBar` on, along the row's foot, at `1 - (t - enterTime) / hold` | **1** |
| Icon | — | `S.IconBorder(holder, { fromSkin = true, hud = true })` crops 0.07 and draws the HUD's icon edge; a `spec.tint` draws a 1 px edge of its own in the tint, over the skin's, with the badge on the same frame | **1** |
| Glow | `glowColorFromSkin`, `glowColor` (`{1, 0.82, 0, 1}`) | ADD-blend `WHITE8X8` strips on a holder one level over the row (skinning-§1's overlay rule), shown while `spec.highlight` is set. The color: `spec.highlight` when it is a color; else, from skin, `S.GlowColor()`, then the `sem.gold` token; else `glowColor`. Its alpha breathes `0.35 + 0.35 * sin(clock * 4)` on the clock. No `LibKa0s-Glow-1.0` (it needs LibCustomGlow) | **1** |

**A live skin switch.** On the first build the library subscribes `OnLooksChanged` on the owner's
facade and runs `RepaintAll` from it; the host wires nothing. A `style` change is the host's
`Refresh()`.

## The plain look (degraded)

No Core facade, no Skin major or an unregistered owner: a `WHITE8X8` fill at `{0, 0, 0, 0.7}`, a 1 px
edge at `{0.3, 0.3, 0.3, 1}`, `GameFontHighlight` for the title and `GameFontHighlightSmall` for the
rest (the client's templates, not a typed face), white text and the spec's colors where given, the bar
flat white. A host's style overrides still draw. Without `LibKa0s-Widgets-1.0` there is no drag
handle and no strip: `SetLocked(false)` answers true and stays locked, and the host's nudge rows still
move the feed. Every facade call is presence-checked; none raises. This is the Toast plain-skin
precedent.

## Motion: one clock and the phase machine

One clock drives every row: an **unparented** frame (a hidden UI never stops a countdown) whose
`OnUpdate` is set only while some row needs a tick, and cleared at the end of a tick where none does
(`Stats().awake`). A feed at rest costs nothing (performance-§2). A tick is the time since the last
one, capped at `MAX_DT`, so a loading-screen hitch never skips a row's life. A row needs a tick while
it enters, holds with a countdown and is not paused, fades, drops, slides toward a new Y, pulses,
glows, or has a settle re-read due; so a feed showing only sticky, unhighlighted rows sleeps, and so
does a frozen one with no pulse or glow. Every member that can make work (`Push`, a merge, `Dismiss`,
an unfreeze, `Release`, `Refresh`) wakes it. There are no AnimationGroups.

Each row's `t` advances by the tick only while it is not paused; the pulse and the glow run even
while paused, so a merge under the pin still pulses. A row is paused while the feed is frozen, or
while it is hovered and `pin` is off.

| Phase | While | Alpha | Offset | Bar |
|---|---|---|---|---|
| enter | `t < enterTime` | `k` for `"fade"`, 1 for a slide | a slide: `(1 - k)` of the distance, toward the side it comes from; the distance is the width (left, right) or the row's height (up, down) | 1 |
| hold | `t < enterTime + hold` | 1 | 0 | `1 - (t - enterTime) / hold` |
| fade | `t < enterTime + hold + fadeTime` | `1 - (t - enterTime - hold) / fadeTime` | 0 | 0 |
| done | past that | the row is freed | — | — |
| drop (forced) | its own time `< DROP_FADE` | the alpha it had when the drop began, falling linearly to 0 | 0 | 0 |

`k = 1 - (1 - t / enterTime)^2`, an ease-out. A sticky row stops at the end of its enter and draws no
bar. The bar and the fade read the same `t`, so the two cannot drift. A row dropped by the shown cap,
by `Dismiss` or a right-click, or by its content skipping it leaves the stack at once and fades where
it stood, so the stack closes up without it; a row past its fade is freed directly.

With `smooth` on, a row moves toward its new Y at a constant speed set at each re-layout (the
distance over `SLIDE_TIME`); off, it snaps. `SetPoint` is called only when a row's Y or offsets
changed. While frozen, rows hold their Y; the freeze ending re-lays them out and drains.

The settle re-read (`motion.settle > 0`) runs `content` once more at the paint time plus `settle`,
and never again for that paint.

## Input

- **Rows** take the mouse unless the feed is click-through, and carry three scripts, set once when a
  pooled row is built: `OnEnter`, `OnLeave` and `OnMouseUp`. The container takes no mouse.
- **Hover.** `OnEnter` marks the row hovered and calls `onEnter`; `OnLeave` clears the mark and
  calls `onLeave`. The freeze is **derived**, recomputed as "a live row is hovered and `pin` is on"
  on every enter, leave, drop, release, `Clear` and click-through change, never latched. A row that
  drops or is freed while hovered clears its own mark first, with its `onLeave`.
- **Clicks.** `OnMouseUp(button)`: the left button while unlocked is a drag's and reaches nobody; the
  right button with `rightDismiss` on dismisses the row; anything else is
  `onClick(payload, button, key)`.
- **The drag.** `SetLocked(false)` builds the feed if it is not built, makes the container movable
  and docks a Widgets `DragHandle` (`label = d.strings.HANDLE`, `owner = d.owner`, a tooltip when
  `HANDLE_TIP` is set) centered 2 px off the stack's far edge: over it growing up, under it growing
  down. A drag stop writes the nudge and re-anchors (see *Placement*). Combat refuses an unlock; the
  host also locks at `PLAYER_REGEN_DISABLED`, since it owns the combat rows.
- **The strip.** `SetStrip` docks the strip across the same far edge, 2 px off; each kind is built
  once and reused with new text. It shows while the feed is locked and hides under the handle.
- **No polling.** `OnEnter` and `OnLeave` are the source; there is no `IsMouseOver` or `GetMouseFoci`
  call, so no client split is needed.

Nothing the feed calls is protected (`Show`, `Hide`, `SetAlpha`, `SetPoint` on unprotected frames,
`EnableMouse`), so every member is legal in combat (events-frames-taint-§2), with `SetLocked(false)`
the one refusal, by choice.

## Frame layering

- **The container:** `STRATA` (`"HIGH"`), frame-layering's T5 **interactive** toast tier. Not toplevel
  (rows must not raise over each other or over a window the player clicks), clamped to the screen,
  mouse off. A host never sets a strata on it.
- **Rows:** children of the container, the strata inherited, one level over it; the glow holder one
  level over its row (skinning-§1's overlay rule).
- **The drag handle and the strip:** Widgets sets their own levels.
- Click-through keeps the strata; only the mouse changes.
- **Upstream:** frame-layering-§6's table of library-owned tiers gains the Feed row beside Callout's
  at the release (`LibKa0s-Feed-1.0 feed container | HIGH | inherited | not toplevel, clamped`). A
  library row is a standard change first, so that edit is made in WowAddonStandards after the tag.

## Adopting it

A host keeps the content, the decision to push, which feed gets what, the sounds, the settings rows
and every string. It leases the major once in a setup file and wraps `New` so every feed gets its
skin owner, Loot History's shape:

```lua
-- core/FeedSetup.lua
local Feed = LibStub and LibStub("LibKa0s-Feed-1.0", true)
function NS.NewFeed(d)
    if not Feed then return NS.FeedStub end
    d.owner = addonName
    return Feed:New(d)
end
```

The host's stand-down calls `Clear()`; its profile reload and its settings writes call `Refresh()`;
its test mode calls `Preview(samples)` and `SetStrip("test", text)`, and `ClearPreview()` and
`SetStrip(nil)` off. A "show in combat: off" row becomes `Hold()` on `PLAYER_REGEN_DISABLED` and
`Release()` on `PLAYER_REGEN_ENABLED`.

### The degradation stub

A host that loads without the library, or with a copy that predates Feed, carries a stub of the
**instance**, since that is what it calls (anti-pattern #47). Each member answers what an empty,
locked feed answers:

```lua
NS.FeedStub = {
    Push = function() return false end, Get = function() return nil end,
    Update = function() return false end, Repaint = function() return false end,
    RepaintAll = function() end, Dismiss = function() return false end,
    Clear = function() end, Hold = function() end, Release = function() end,
    Refresh = function() end, Preview = function() return 0 end, ClearPreview = function() end,
    SetLocked = function() return true end, IsLocked = function() return true end,
    SetClickThrough = function() end, SetStrip = function() end,
    Visible = function() return {} end, Frame = function() return nil end,
    Stats = function() return { live = 0, waiting = 0, dropping = 0, frozen = false,
        held = false, locked = true, clickThrough = false, awake = false, shown = 0,
        built = false } end,
}
```

Pin it with a parity case against a live instance (`T.assertSurfaceParity(liveFeed, NS.FeedStub,
"Feed instance")`), the instance form, because `members-1.1.1.1.json` lists the lib-level surface
only, which a host reads through `Feed:New`. `__Step` is outside the parity surface; a host test that
steps a live feed reaches it only after checking it exists.

## What is not here

| Not in Feed-1.0 | Stays in | Re-check trigger |
|---|---|---|
| Row content, kinds, prices, sources, the upgrade rule | the host's `content` | — (the one presentation argument) |
| When to push, filters, which feed gets what | the host | — |
| A combat flag | the host's event rows calling `Hold` / `Release`, `SetClickThrough` and `SetLocked(true)` | a behavior only the library can express (it would fail bar 2) |
| Sounds | the host, on `Push` answering `"new"` | a second consumer plays sounds the same way |
| An overflow policy (queue instead of drop) | — | a consumer asks for one |
| Settings rows (`O.FeedGroup` or `SchemaRows`) | each host's schema | a second consumer's rows converge (Callout's `SchemaRows` precedent) |
| Item tooltips on hover | the host's `onEnter` | — |
| A close-reason callback | — | a host needs to tell an expiry from a dismiss |

## Compatibility

The API is **additive-only**: a member, a descriptor field, a `layout`, `motion` or `style` key or a
spec field may be added in a later minor, never removed or repurposed. Every member and field above is
`Since 1`.

## Vendoring

Whole-folder, exactly as every other major in this payload:

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s   # content — MUST be empty
diff -r LibKa0s <Addon>/libs/LibKa0s                       # bytes  — SHOULD be empty
```

`LibKa0s.xml` loads `Feed.lua`, `FeedModel.lua`, `FeedRow.lua` and `FeedInput.lua` directly after
`Toast.lua`, so the whole-folder copy brings them in with no load-list change in the host. The three
secondaries are paired on the shell's minor (`lib.__modelMinor` / `lib.__modelShellMinor`,
`lib.__rowMinor` / `lib.__rowShellMinor`, `lib.__inputMinor` / `lib.__inputShellMinor`): a
secondary re-attaches whenever the winning shell's minor is not the one it attached to. A host that
vendors the four files alone ahead of a full re-vendor lists them in its TOC after `LibKa0s.xml` and
records that as a temporary deviation.
