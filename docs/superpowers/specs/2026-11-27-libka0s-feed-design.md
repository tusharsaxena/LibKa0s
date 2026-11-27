# M3.0 design: `LibKa0s-Feed-1.0`, the toast-feed major (Loot History #38)

**Date:** 2026-11-27
**Repo:** `../LibKa0s` (master at `4dbc1636`, v1.118.0). Consumer: Ka0s Loot History, issue #38.
**Ruling it serves:** X1 / plan D24 of 2026-11-27 (owner): extend LibKa0s upstream, either as a Toast minor 5
feed mode or as a new major, "whichever the M3.0 design shows fits the library's conventions"
(`2026-11-27-38-loot-toasts-design.md:18-28`).
**Inputs:** the #38 design (sections 7.3-7.6 and 8.1-8.8, `:564-847`), the owner-approved mockups
(`docs/superpowers/specs/2026-11-27-tooltip-toasts-farm-mockups.html:272-471`), the standard
(`WowAddonStandards/standards/standards/`), and the library's own conventions (`CLAUDE.md`,
`docs/releasing.md`, `docs/api/README.md`).
**Status:** Architect's design. L1 can start on the owner's go. Every line anchor below was re-read on
2026-11-27.

---

## 1. Decision: a new major, `LibKa0s-Feed-1.0`, not Toast minor 5

**Ruling F1.** The feed is a new LibStub major, `LibKa0s-Feed-1.0`, in three files. `Toast.lua` is not touched
and stays at minor 4.

| # | Reason | Evidence |
|---|---|---|
| 1 | **A feed mode is a behaviour flag (bar 2).** A `mode = "feed"` switch would flip which end is the head, swap hide for fade, and stop re-chaining followers. "A flag that changes what the function *does* is the tell." Toast minor 4's `stack` was allowed only because without it the descriptor is the minor 3 toast, byte for byte. | `library-stack.md:358-361`; `Toast.lua:27-31` ("Without d.stack, or with 1, it is the minor 3 toast") |
| 2 | **It repurposes members (additive-only MUST).** In Toast the head is the *oldest* toast, held at the saved point; `Current()`, `Frame()` and `Dismiss()` answer that head. The feed puts the *newest* row at the anchor (#38 T1). The same names would mean the opposite thing. | `library-stack.md:152`; `Toast.lua:27-31`, `:673-713`; #38 design `:57` |
| 3 | **A different engine.** Toast runs one `C_Timer` per record plus a 0.2 s `IsMouseOver` poll to notice the pointer leaving. The feed needs one clock driving enter, hold, fade, pulse, the bar and the slide, so that the bar and the fade cannot drift apart (#38 T3). Two clock models in one file is the RLF failure (`TimerBarCoordinator` beside AnimationGroups). | `Toast.lua:89` (`WATCH_POLL`), `:155-214`; #38 `:59`, `:780-793` |
| 4 | **A different layout.** Toast chains each frame to the one before and gives each toast its own toplevel `UIParent` child sized by its builder. The feed lays rows out by an absolute Y inside one container and gives them the container's width, which is what makes smooth reposition and pin-in-place cheap. | `Toast.lua:238-288`, `:346-357`; #38 `:634-651`, `:673-685` |
| 5 | **Toast's own "not here" table parks exactly these behaviours** (fade-in/out until "both hosts ask"; per-toast position; close-reason callback). Building them into Toast fires those triggers for one host, against the table's wording. | `docs/api/Toast/version-4-docs.md:227-238` |
| 6 | **Blast radius.** LibStub serves the highest minor of every installed copy to every host (`docs/releasing.md:11-14`). Toast minor 5 shipped in Loot History would run inside Drop Watcher, Combat Trail, Quick Comms and Skill Master on players' machines without their re-vendor. Skill Master's getters depend on `present()` calling build, then the sound, then the duration, in that order. Any default-path change is a live regression in four addons. A new major has no other caller. | `Toast.lua:436-451`; `docs/api/CONSUMERS.md:1038` (`lib.New` - 4 callers); SkillMaster `modules/Alerts.lua:463-469` |
| 7 | **Size.** `Toast.lua` is 725 lines. The feed engine is about 1500 lines in all (section 7), so a feed mode puts Toast past the 1500 cap or forces an immediate peel, and either way it changes Toast's version key for every host. | `layout.md:62`; LibKa0s `CLAUDE.md:79-80` (the band register rows) |
| 8 | **Stub churn.** Any new Toast instance member reddens five instance stubs at their next re-vendor (`docs/api/README.md:39-42`), and Loot History pins `Toast == 4` exactly (`tests/test_libka0s_releases.lua:516`). A new major reddens nothing. | as cited |

**How the new major clears the promotion bars.**

- **Bar 1 (SHOULD), satisfied by the owner's ruling.** One consumer, ruled a suite-wide component (X1 / D24,
  2026-11-27). This is conformant and takes **no** deviation-register row. The ruling **MUST** be recorded in
  `docs/api/Feed/version-1.1.1-docs.md` and in the CHANGELOG entry of the release that ships it, naming who
  ruled (Tushar Saxena, owner), the date (2026-11-27), where it was decided (Loot History plan
  `docs/superpowers/plans/2026-11-27-tooltip-toasts-farm.md`, D24, ruling X1 of the #38 design) and the consumer
  it ships with (Ka0s Loot History #38). It **SHOULD** name an expected second consumer when one is known. None
  is verified, so the document says "none named yet" rather than guess (`library-stack.md:345-357`).
- **Bar 2.** One presentation argument (`d.content`) and an optional merge reducer (`d.merge`). Every other field
  is a value or getter carrying a *player's* setting (where, how big, how it moves, how it looks), never a
  switch that says which consumer is calling. Overflow has no option: a full feed drops its oldest row (#38 T5).
  The two places closest to the line, `motion.pin` and `motion.rightDismiss`, are argued in section 2.4.
- **Bar 3, asked harder.** The surface is kept small and flat: one constructor, seventeen instance members, a
  flat row spec with no per-kind fields, and no settings composer (deferred, section 13).

**What carries over from Toast as convention, not code:** a descriptor of values or getters read at call time;
`Clear()` as the stand-down hook; `Hold()`/`Release()` in place of a combat flag (`version-4-docs.md:233`); the
one presentation callback under `pcall` with its error handed to `geterrorhandler()`; `Refresh()`; `Stats()`;
`Preview()`; the instance degradation stub with a parity case (`version-4-docs.md:201-225`); `lib.STRATA =
"HIGH"`, the T5 interactive alert tier (`Toast.lua:86`, `frame-layering.md:20`).

---

## 2. Public contract

### 2.1 Constructor

```lua
local Feed = LibStub("LibKa0s-Feed-1.0", true)
local feed = Feed:New(d)   -- one feed instance; raises when d.content is not a function
```

One `New` per on-screen feed. Loot History makes three (main, progress, extra). Nothing is built until the
first `Push`, `Preview` or `SetLocked(false)` (lazy, #38 `:683-684`).

### 2.2 Descriptor `d`

"Value or getter" means the field may be a plain value or a function of no arguments that answers one. Getters
are read **only** on the first build, on `Refresh()`, and (for `layout`, `motion`, `style`) once into a cached
snapshot. The ticker never calls a getter. A field that answers nothing usable falls back to the published
default.

| Field | Type | Default | Meaning |
|---|---|---|---|
| `content` | **function, required** | — | `content(spec, payload, key)` fills the reused row spec (2.5). Answers `false` to skip the payload (a `Push` of it answers `false`). Runs under `pcall`; an error goes to `geterrorhandler()` and the payload is skipped. Called on present, merge, `Update`, `Repaint`, `RepaintAll`, a skin switch and the settle re-read, **never** from the ticker's per-frame path. |
| `merge` | function or nil | nil | `merge(old, new, key)` answers the merged payload. nil means the newer payload replaces the older one. Called only on a merge (2.6). |
| `owner` | string or nil | nil | The skin owner (the addon's folder name). The row paint, the drag handle and the strips follow that owner's skin. nil, or an unregistered owner, draws the undecorated look (3.6). |
| `name` | string or nil | nil | Global name of the container; rows are unnamed. |
| `layout` | table, or getter answering one | see 2.3 | Placement and size. |
| `motion` | table, or getter answering one | see 2.4 | Enter, hold, fade, merge window, pulse, bar, slide, pin, settle. |
| `style` | table, or getter answering one | see 3.5 | The style override table over the owner's skin. |
| `maxQueue` | number, or getter | `lib.MAX_QUEUE` (10) | Payloads waiting while frozen or held; the oldest is dropped past it. |
| `onEnter` | function or nil | nil | `onEnter(row, payload, key)` on pointer enter, under `pcall`. For the host's tooltip. |
| `onLeave` | function or nil | nil | `onLeave(row, payload, key)`, under `pcall`. |
| `onClick` | function or nil | nil | `onClick(payload, button, key)` on mouse up, under `pcall`. Not called for a right-click while `rightDismiss` is on, and not called for the left button while unlocked. The host reads modifiers itself. |
| `onMoved` | function or nil | nil | `onMoved(x, y)` after a drag, with the nudge for the current slot in UIParent units, already clamped. The host writes it through its write seam; the library has already re-anchored. |
| `strings` | table or nil | nil | `{ HANDLE = "...", HANDLE_TIP = "..." }`, the drag handle's label and tooltip, read raw. Every string the library draws comes from the host (localization). |
| `debug` | function or nil | nil | `debug(tag, fmt, ...)` sink, as Toast's (`Toast.lua:110-113`). |

The three grouped tables (`layout`, `motion`, `style`) are a deliberate change from Toast's flat fields: the
feed has about forty knobs, a host builds each table from one profile subtable, and the library snapshots each
once instead of calling forty getters. Each table is read with `rawget`, and an unknown key is ignored, so a
later minor adds keys additively.

### 2.3 `layout` keys

| Key | Values | Default (`lib.*`) | Since |
|---|---|---|---|
| `slot` | `"TOPLEFT"`, `"TOP"`, `"TOPRIGHT"`, `"LEFT"`, `"CENTER"`, `"RIGHT"`, `"BOTTOMLEFT"`, `"BOTTOM"`, `"BOTTOMRIGHT"` (`lib.SLOTS`) | `"BOTTOMRIGHT"` | 1 |
| `x`, `y` | nudge in UIParent units, clamped to `±lib.NUDGE_MAX` (600) | 0, 0 | 1 |
| `grow` | `"UP"` or `"DOWN"` | `"UP"` | 1 |
| `shown` | rows on screen at once, 1..`lib.SHOWN_MAX` (10) | `lib.SHOWN` (5) | 1 |
| `width` | px | `lib.WIDTH` (320) | 1 |
| `rowHeight` | minimum row height, px | `lib.ROW_HEIGHT` (48) | 1 |
| `iconSize` | px, clamped to the row's inner height | `lib.ICON_SIZE` (36) | 1 |
| `padding` | px inside a row | `lib.PADDING` (6) | 1 |
| `gap` | px between rows | `lib.GAP` (5) | 1 |
| `align` | `"left"` or `"right"`: text justification; `"right"` also swaps each secondary line's left and right parts | `"left"` | 1 |
| `iconSide` | `"left"` or `"right"` | `"left"` | 1 |
| `scale` | the container's scale | 1 | 1 |

### 2.4 `motion` keys

| Key | Values | Default | Since |
|---|---|---|---|
| `enter` | `"none"`, `"fade"`, `"left"`, `"right"`, `"up"`, `"down"` (slide from that side) | `"fade"` | 1 |
| `enterTime` | s; `"none"` forces 0 | `lib.ENTER_TIME` (0.25) | 1 |
| `hold` | s at full alpha | `lib.HOLD` (5) | 1 |
| `fadeTime` | s; 0 = vanish | `lib.FADE_TIME` (1) | 1 |
| `mergeWindow` | s; 0 = never merge | `lib.MERGE_WINDOW` (3) | 1 |
| `pulse` | bool: a merge pulses the border | true | 1 |
| `timerBar` | bool: the countdown bar along the row's foot | false | 1 |
| `smooth` | bool: rows slide to a new Y over `lib.SLIDE_TIME` (0.15); off snaps | true | 1 |
| `pin` | bool: hover freezes the **whole** feed (true) or pauses only the hovered row (false) | true | 1 |
| `rightDismiss` | bool: right-click dismisses the row | true | 1 |
| `settle` | s; 0 = off. One extra `content` call at `paintedAt + settle`, for state that lags its own event (client-quirks-§3) | 0 | 1 |

**Bar-2 argument for the closest two.** `pin` and `rightDismiss` are D14 rows a player toggles on the Toasts page
(the mockup shows both as checkboxes). Hover always pauses; `pin` only widens the pause from one row to the feed,
so neither value changes what a member *does* for a consumer. They are player settings carried through, like
Toast's `draggable` getter (`version-4-docs.md:99-101`).

### 2.5 Payload and row spec

The library stores the host's `payload` untouched (it never reads into it) and hands it back to `content`,
`merge`, the callbacks and `Get`. `content` fills a **reused flat spec**: one spec table per pooled row record,
wiped before each call, so a push or merge allocates nothing once the pool is warm.

| Spec field | Type | Drawn as |
|---|---|---|
| `icon` | texture path or file id | the row's icon, cropped at 0.07 (`docs/api/README.md:719-726`) |
| `tint` | `{r,g,b[,a]}` | the payload's meaning colour (quality, for example): the icon border, and the row border when `style.borderTint` is on |
| `badge` | string | small text over the icon's top-left corner (an item level) |
| `title`, `titleColor` | string, colour | the first line |
| `count`, `countColor` | string, colour | a chip after the title (`"x3"`); while the row pulses it is drawn in `glow.color` unless `countColor` is set |
| `prefix`, `prefixColor` | string, colour | dim text before the title (`‹Friendly›`) |
| `lines[1..3]` | `{ left, leftColor, right, rightColor }` | up to three secondary lines; the library keeps the three sub-tables and wipes them |
| `sub`, `subColor` | string, colour | a last small line |
| `highlight` | bool, or a colour | the ADD-blend glow edge, pulsing on the ticker; `true` uses `glow.color`, falling back to `sem.gold` |

Strings arrive finished: inline icon markup and coloured coin text are the host's. A colour left nil takes the
style's text colour (3.5). The spec has no kind, quality rule, price or source: those stay in the host (#38
section 7.4).

### 2.6 Instance members (all `Since 1`)

| Member | Answers | Contract |
|---|---|---|
| `Push(key, payload, opts)` | `"new"`, `"merged"`, `"queued"` or `false` | `key` may be nil (never merges). `opts.sticky` gives the row no countdown. Merge: a live (not dropping) or waiting entry with this key whose `lastAt` is within `mergeWindow` takes `merge(old, new, key)` (2.7). Else, while frozen or held, the payload waits (`"queued"`). Else it presents at the anchor (`"new"`). `false` when `content` answered false or raised. The host plays its own highlight sound on `"new"`. |
| `Get(key)` | payload or nil | The live or waiting payload under `key`. For the host's absorb rule (an appearance folded into its item). |
| `Update(key, payload)` | bool | Replace the payload and repaint in place: no hold restart, no pulse, no move. |
| `Repaint(key)` | bool | Re-run `content` for that row. |
| `RepaintAll()` | — | Re-run `content` and the style paint for every live row. Also run by the library on the owner's `OnLooksChanged`. |
| `Dismiss(key)` | bool | Start that row's drop fade (`lib.DROP_FADE`, 0.2 s). |
| `Clear()` | — | Stand-down: every row released and hidden, entries freed, waiting list emptied, clock disarmed, hover and freeze cleared, handle and strips hidden, locked again. The pools are kept. |
| `Hold()` / `Release()` | — | While held, new payloads wait (merging there). Live rows keep running. `Release` drains (2.8). The host's "show in combat: off" calls these; the library carries no combat flag. |
| `Refresh()` | — | Re-read every getter, re-snapshot `layout`/`motion`/`style`, re-anchor, re-layout and repaint. After a profile switch or a settings write. |
| `Preview(list)` | number | `list` is `{ {key, payload}, ... }`; each pushes sticky and is marked a preview row through the same present and paint path (preview-mode same-render-path SHOULD). Replaces the previous preview rows. Answers how many showed. |
| `ClearPreview()` | — | Drops only the preview rows. |
| `SetLocked(locked)` | bool (now locked) | `false` makes the container movable and docks a `LibKa0s-Widgets-1.0` `DragHandle` on the stack's far edge with `d.strings.HANDLE`. Refused (answers true) in combat. `true` hides the handle. |
| `IsLocked()` | bool | |
| `SetClickThrough(on)` | — | `EnableMouse(not on)` on every live row and every row acquired while on. Turning it on **also** clears every row's hovered flag and the freeze, and drains the waiting list, because the client fires no `OnLeave` when the mouse is disabled. |
| `SetStrip(kind, text)` | — | `kind` `"test"` or `"sim"` docks a `W.TestStrip` with the host's `text` on the stack's far edge; `nil` hides it. Hidden while the drag handle shows. |
| `Visible()` | array of keys | Newest first; `false` for a key-less row. A new table per call (not hot path). |
| `Stats()` | table | `{ live, waiting, dropping, frozen, held, locked, clickThrough, awake, shown, built }`, all always present. |
| `Frame()` | frame or nil | The container once built. |

`__Step(dt)` is a documented **internal test seam**: one tick of `dt` seconds, whether the clock is armed or not.
It is not contract (`library-stack.md:153`), and `Kit.publicMembers` leaves it out of the parity surface.

### 2.7 Merge in place

On a merge the library:

1. sets `payload = d.merge and d.merge(old, new, key) or new` (under `pcall`; on error, keeps `new`);
2. sets `lastAt = now`;
3. restarts the hold: `t = max(t, enterTime)` while still entering, else `t = enterTime`. The enter never
   replays, and a fading row snaps back to alpha 1;
4. sets `pulse = lib.PULSE_TIME` (0.6 s) when `motion.pulse`;
5. moves the entry to index 1 (the newest slot) unless the feed is frozen, in which case it stays put;
6. repaints through `content`, re-lays out, and wakes the clock.

A merge into a waiting entry replaces its payload and its `lastAt`, and answers `"merged"`. A dropping entry
never takes a merge: the push is a new entry.

### 2.8 Waiting list and drain

Entries wait while `frozen or held`, in arrival order, capped at `maxQueue` (the oldest dropped silently). On
unfreeze, `Release()` or `SetClickThrough(true)`, only the **newest `shown`** waiting entries present, oldest
first, so the newest ends at the anchor and nothing flashes in only to be dropped. The rest are freed.

---

## 3. Internal design

### 3.1 State, files and the shell

- `STATE[inst]` is weak-keyed, reached through `state(self)`, which raises for a non-instance (`Toast.lua:545-551`).
  It holds `{ d, cfg = { layout, motion, style }, live = {}, leaving = {}, waiting = {}, rows = {}, free = {},
  entryFree = {}, byKey = {}, frozen, held, locked, clickThrough, awake, clock, container, handle, strip }`.
- `Feed.lua` (shell) publishes its methods table as `lib.__methods` (CalloutSettings attaches the same way,
  `CalloutSettings.lua:114`), and `New` copies it into each instance at call time, so a secondary's later minor
  reaches existing instances only on the next `New`. The shell calls the model and row halves through
  `lib.__model` and `lib.__row`, read at call time.
- `FeedModel.lua` is pure: no frames, no globals beyond `math`. It exposes `lib.__model = { Snapshot, SlotOffset,
  NudgeFromRect, RowHeight, Layout, Advance, Merge, Drain }`. Pure so headless suites step it without frames.
- `FeedRow.lua` builds and paints rows: `lib.__row = { Build, Paint, Place, Restyle }`.

### 3.2 Pools

The feed owns its pools and does **not** floor on `LibKa0s-Pool-1.0`. Pool's keyed map has no single-key
release (`Pool.lua:164-222` has `NewKeyed`, `AcquireKeyed`, `ReleaseAllKeyed` and `CountsKeyed` only), and a
`NEEDS_POOL` floor would be a new inter-module edge the standard counts (`library-stack.md:160`).

- **Row records.** `R = { frame, regions..., spec = {lines = {{},{},{}}}, entry }`. `S.free` is a free list.
  Acquire pops it or calls `Build(container)`. Release hides the frame, clears its scripts' state (hovered,
  alpha 1, glow off), detaches the entry and pushes it back.
- **Entries.** `e = { key, payload, t, phase, alpha, pulse, y, targetY, h, lastAt, paintedAt, settled, sticky,
  preview, hovered, row }`, from `S.entryFree`, wiped on free.
- `S.byKey[key]` indexes live and waiting entries for O(1) merge and `Get`.

### 3.3 The clock: one `OnUpdate`, armed only while needed

- `S.clock = CreateFrame("Frame")`, **unparented**, so a hidden UI never stops a countdown. This is Callout's clock
  (`Callout.lua:749`, `:759-770`), and `tests/fixture_callout.lua:148-160` already finds and fires exactly that
  shape, so no kit change is needed.
- `wake(S)` sets `OnUpdate` only when it is not set; `sleep(S)` sets it to nil. `Stats().awake` reports it
  (Callout's `Stats().awake`, `Callout.lua:1043`).
- Each tick: `dt = min(GetTime() - S.lastTick, lib.MAX_DT)` (0.1 s, so a loading-screen hitch does not skip a
  whole row's life), then for each live and leaving entry run `Advance`, then apply only what changed.
- **Needs a tick** when any entry is entering, holding with a countdown and not paused, fading, dropping,
  moving (`y ~= targetY`), pulsing, highlighted, or has a settle re-read due. At the end of a tick with no such
  entry, `sleep`. A feed showing only sticky, unhighlighted rows, or frozen with no pulse or glow, sleeps. Every
  member that can create work (`Push`, a merge, `Dismiss`, unfreeze, `Release`, `Refresh`) calls `wake`.
- No AnimationGroups anywhere (RLF pitfalls 4, 6, 7, 8 in the scout record).

### 3.4 Layout math

**The container** is anchored by its **grow-origin edge** at the slot, so its height changes never move the
newest row:

```
hpart(slot)  = "LEFT" | "" | "RIGHT"          -- from the slot's column
vrow(slot)   = "TOP"  | "MID" | "BOTTOM"      -- from the slot's row
origin       = (grow == "UP" and "BOTTOM" or "TOP") .. hpart
insetX       = LEFT column +I, RIGHT column -I, CENTER 0      (I = lib.SLOT_INSET, 20)
insetY       = BOTTOM row  +I, TOP row    -I, MID    0
SlotOffset(slot, x, y) -> slot, ox = x + insetX, oy = y + insetY
container:SetPoint(origin, UIParent, slot, ox / scale, oy / scale)
```

The offsets are divided by the container's scale so the stored nudge stays in UIParent units and a scale change
grows the stack about its anchor (Toast's position rule, `Toast.lua:41-43`).

**Rows** fill the container's width (`LEFT` and `RIGHT` to the container's), so their horizontal offset is the
enter slide only. Entry `i` (1 = newest) gets:

```
h_i      = max(rowHeight, pad*2 + titleH + sum over filled secondary lines of lineH)
titleH   = fontSize + 2;  lineH = fontSize2 + 2   (sub counts as a secondary line)
y_1      = 0;  y_i = y_{i-1} + h_{i-1} + gap
grow UP:   row:SetPoint("BOTTOM", container, "BOTTOM", dx, y + dy)   -- y counts up
grow DOWN: row:SetPoint("TOP",    container, "TOP",    dx, -(y) + dy)
container height = y_n + h_n  (1 when empty)
```

`targetY` is recomputed by `Layout` on every present, merge, drop, repaint that changes a height, and unfreeze;
`y` moves toward it over `SLIDE_TIME` when `smooth`, or snaps. `SetPoint` is called only when `y`, `dx` or `dy`
changed since the last call (RLF's re-chain storm is the thing avoided).

**Leaving rows** (dropped by overflow, dismissed, or past their fade) are taken out of `live` at once and moved to
`leaving` at their current Y, so the stack re-lays out without them and the next row has room. They fade from
their current alpha over `DROP_FADE` and are released when done.

**The nudge from a drag** (`NudgeFromRect(slot, grow, left, bottom, right, top, W, H)`), with the rect in
UIParent units (`GetLeft() * GetEffectiveScale() / UIParent:GetEffectiveScale()`):

```
originX = LEFT: left   | CENTER: (left+right)/2 | RIGHT: right
slotX   = LEFT: 0      | CENTER: W/2            | RIGHT: W
originY = UP: bottom   | DOWN: top
slotY   = BOTTOM: 0    | MID: H/2               | TOP: H
x = clamp(originX - slotX - insetX, ±NUDGE_MAX);  y = clamp(originY - slotY - insetY, ±NUDGE_MAX)
```

`SlotOffset(slot, NudgeFromRect(...))` reproduces the rect (a model case pins the round trip for every slot,
both grows and two scales). `SetClampedToScreen(true)` on the container keeps the whole stack on screen; a
grow-up stack in a TOP slot is pushed down by the clamp, which the API doc states.

### 3.5 Style over the owner's skin

The facade is `core.__SkinFacade(d.owner)` (`Core.lua:201-207`), read at **call time**: `Feed.lua` loads before
`Media.lua`, `Skin.lua` and `Widgets.lua` (`LibKa0s.xml:15,24,26,38`), so a load-time read answers nil for the
session. Every name used is a `VOCAB` trampoline (`Skin.lua:157-166`), so a newer Skin minor's code runs.

`style` keys (every colour `{r,g,b,a}`; every part has a `FromSkin` companion that defaults to **true**, so a host
that passes no style draws the skin, skinning-§9):

| Part | Keys | Resolution |
|---|---|---|
| Background | `bgFromSkin`, `bgType` (`"none"`, `"solid"`, `"gradient"`, `"texture"`), `bgColor`, `bgColor2`, `bgTexture` (LSM name) | From skin: `S.Shell(row, { noTopBar = true, noBands = true })`, recorded, so a skin switch repaints it. Override: the row's Shell record is replaced with `{ keepEdge = true, noTopBar = true, noBands = true }` so a skin repaint leaves the host's fill alone, then `none` / `WHITE8X8` tinted / `SetGradient("HORIZONTAL", c1, c2)` / `LibSharedMedia-3.0:Fetch("background", name)` (resolved at call time, absent LSM falls back to solid) |
| Border | `borderStyleFromSkin`, `borderStyle`, `borderSize`, `borderColorFromSkin`, `borderColor`, `borderTint` (bool), `borderClass` (bool) | `style, show, size = S.BarBorder(borderStyle, true, borderSize, borderStyleFromSkin)`. Colour in skinning-§6 order, meaning and class first: `borderTint` and `spec.tint` -> the tint; `borderClass` -> `core.ClassColor("player")` (Core minor 20, `Core.lua:464`); `borderColorFromSkin` -> `S.Token("bar.border")`; else `borderColor`. While pulsing, the border alpha is `0.6 + 0.4 * sin(pulse / PULSE_TIME * pi)` |
| Fonts | `fontFromSkin`, `font`, `fontSizeFromSkin`, `fontSize`, `fontSize2`, `fontFlags` (`"@skin"` allowed), `fontShadowFromSkin`, `fontShadow` | Every string through `S.HudFont(fs, { face = S.Resolve("hud.font", font, fontFromSkin), size = S.HudFontSize(size, fontSizeFromSkin), flags = S.FontFlags(fontFlags), shadow = ... })`. One font object per look; no string gets a `SetFont` of its own (Skin doc rule, `version-18...-docs.md:173`, `:193`). Ignore fonts is honoured by the facade itself |
| Text colour | `fontColorFromSkin`, `fontColor`, `fontClass` (bool) | The spec's own colour wins (meaning first). Then `fontClass` -> class colour; then from skin -> `S.HudTextColor()` for the title, `S.HudLabelColor()` for prefix, secondary lines and sub; else `fontColor` |
| Countdown bar | `barFromSkin`, `barTexture`, `barColor` | `S.BarTexture(bar, r, g, b, a)` with `S.BarFillColor()` from skin |
| Icon | — | `S.IconBorder(iconHolder, { fromSkin = true, hud = true })`, recoloured with `spec.tint` when given |
| Glow | `glowColorFromSkin`, `glowColor` | `ADD`-blend `WHITE8X8` edge strips on a holder one level over the row (skinning-§1 overlay rule); colour `spec.highlight` (if a colour), else `S.GlowColor()`, else `S.Token("sem.gold")`; alpha `0.35 + 0.35 * sin(clock * 4)` on the ticker. No `LibKa0s-Glow-1.0` (it needs LibCustomGlow, #38 T6) |

**Live skin switch.** On the first build, the library subscribes `S.OnLooksChanged(function() RepaintAll end)` for
`d.owner` (Callout precedent, `Callout.lua:755-756`). The host wires nothing. A `style` change is the host's
`Refresh()`.

### 3.6 Degraded look

No Core facade, no Skin major, or an unregistered owner: a `WHITE8X8` fill at `{0, 0, 0, 0.7}`, a 1 px edge at
`{0.3, 0.3, 0.3, 1}`, `GameFontHighlight` and `GameFontHighlightSmall` (the client's templates, not a typed face),
white text and the spec's colours where given, the bar flat white. No drag handle or strip without `Widgets`
(`SetLocked(false)` answers true and stays locked; the host's nudge rows still move the feed). Every facade call
is presence-checked; none raises. This is the Toast degraded-skin precedent (`version-4-docs.md:73-78`).

### 3.7 Motion: the phase machine (`Advance(e, m, dt, paused)`)

`t` advances by `dt` only while `not paused`; `pulse` and the glow run even while paused (so a merge under a pin
still pulses). Answers `alpha, dx, dy, bar, done`.

| Phase | While | alpha | offset | bar |
|---|---|---|---|---|
| `enter` | `t < enterTime` | `k` for fade, 1 for a slide | slide: `(1 - k) * dist` toward the slide's side; `dist` = width (left/right) or `h` (up/down) | 1 |
| `hold` | `t < enterTime + hold` | 1 | 0 | `1 - (t - enterTime) / hold` |
| `fade` | `t < enterTime + hold + fadeTime` | `1 - (t - enterTime - hold) / fadeTime` | 0 | 0 |
| done | past that | — | — | — |
| `drop` (forced) | `td < DROP_FADE` | `a0 * (1 - td / DROP_FADE)` from the alpha it had | 0 | 0 |

`k = 1 - (1 - t/enterTime)^2` (ease-out). A sticky entry clamps `t` at `enterTime` and draws no bar. `paused` is
`S.frozen or (e.hovered and not m.pin)`. The bar and the fade read the same `t`, so they cannot drift (#38 T3).

### 3.8 Input

- **Rows** carry `EnableMouse(true)` (unless click-through) and three scripts set once in `Build`: `OnEnter`,
  `OnLeave`, `OnMouseUp`. The container takes no mouse itself.
- **Hover.** `OnEnter` sets `e.hovered`; with `pin` on, `S.frozen = true`. `OnLeave` clears it. `S.frozen` is
  **derived**, recomputed as "any live row hovered and pin on" on every enter, leave, release, `Clear` and
  click-through change, never a latch (RLF pitfall 2). The freeze ending re-lays out and drains (2.8). A
  released row clears its own hovered flag first.
- **Clicks.** `OnMouseUp(button)`: unlocked and left button -> ignored (a drag). Right with `rightDismiss` ->
  drop. Otherwise `d.onClick(payload, button, key)`.
- **Drag.** `SetLocked(false)`: `container:SetMovable(true)`, `W.DragHandle(container, { owner = d.owner, label =
  strings.HANDLE, ... })` docked on the far edge (grow UP: top of the stack; DOWN: bottom), its drag calling
  `StartMoving` / `StopMovingOrSizing`, then `NudgeFromRect`, then re-anchor from the slot, then `d.onMoved(x,
  y)`. Combat refuses unlock; the host also re-locks at `PLAYER_REGEN_DISABLED` (it owns the combat rows).
- **Pointer probes.** No polling. `OnEnter`/`OnLeave` are the source; there is no `IsMouseOver` or `GetMouseFoci`
  call, so no client split is needed.

### 3.9 Lifecycle

Lazy build on the first `Push`, `Preview` or `SetLocked(false)`. `Clear()` is the stand-down and leaves the
instance reusable. Nothing the feed calls is protected (`Show`, `Hide`, `SetAlpha`, `SetPoint` on unprotected
frames, `EnableMouse`), so every member is legal in combat (events-frames-taint-§2), with `SetLocked(false)` the
one refusal, by choice.

### 3.10 Performance

- One `OnUpdate` per feed, nil when idle (a case pins it); zero cost at rest (performance-§2).
- No allocation per frame, per push or per merge after warm-up: pooled rows, pooled entries, reused spec tables,
  the cfg snapshot rebuilt only on `Refresh`.
- `content` never runs per frame; per-frame work is `SetAlpha`, the bar's width, the glow's alpha, and `SetPoint`
  only on a change.

---

## 4. Frame layering

- **Container:** `lib.STRATA = "HIGH"`, frame-layering's T5 **interactive** toast tier (`frame-layering.md:20`).
  Not toplevel (rows must not raise over each other or over a window the player clicks), clamped to screen,
  mouse off. Hosts never set a strata on it (QuickComms `core/ToastSetup.lua:7-8`'s rule for Toast).
- **Rows:** children of the container, strata inherited, level `container + 1`; the glow holder `row + 1`
  (skinning-§1 overlay rule).
- **Drag handle and strip:** `Widgets` sets their own levels (`WidgetsDragHandle.lua:968`, `dhLevel`).
- Click-through keeps the strata; only the mouse changes.
- **Upstream:** frame-layering-§6's library-owned tiers table gains a row beside Callout's (`frame-layering.md:116`):
  `LibKa0s-Feed-1.0 feed container (T5 interactive toast, from LibKa0s v1.119.0; rows mouse-on unless
  click-through, its drag handle over it while unlocked) | HIGH | inherited | not toplevel / clamped`. "Changing a
  library row is a standard change first" (`frame-layering.md:110`), so this is a standards edit, flagged in
  section 11.

---

## 5. Files and `LibKa0s.xml` placement

| File | Constant | Responsibility | Est. lines |
|---|---|---|---|
| `LibKa0s/Feed.lua` | `MINOR = 1` | Preamble, constants, `New`, `METHODS` (published as `lib.__methods`), STATE, container, clock, push, merge, queue and drain, input, unlock, strip, `Stats` | 700 |
| `LibKa0s/FeedModel.lua` | `MODEL_MINOR = 1` | Pure: snapshot and normalise `layout`/`motion`/`style`, `SlotOffset`, `NudgeFromRect`, `RowHeight`, `Layout`, `Advance`, `Merge`, `Drain` | 380 |
| `LibKa0s/FeedRow.lua` | `ROW_MINOR = 1` | Row template (regions made once), `Place` (icon side, align, heights), `Paint` (style over facade), degraded look | 560 |

Each stays under 1000 (layout-§1 band); measure at L6 before committing, and if `Feed.lua` passes 900, peel
input and unlock into `FeedInput.lua` before release rather than after.

**Placement:** directly after `Toast.lua`, before `Callout.lua` (`LibKa0s.xml:15-16`):

```xml
	<Script file="Toast.lua"/>
	<Script file="Feed.lua"/>
	<Script file="FeedModel.lua"/>
	<Script file="FeedRow.lua"/>
	<Script file="Callout.lua"/>
```

**Preamble** (`Toast.lua:64-75` is the template):

```lua
local core = LibStub and LibStub("LibKa0s-Core-1.0", true)
local NEEDS_CORE = 20   -- ClassColor (Core minor 20, docs/api/README.md:101)
if not core or (core.MINOR or 0) < NEEDS_CORE then return end
local MAJOR, MINOR = "LibKa0s-Feed-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end
lib.MAJOR, lib.MINOR = MAJOR, MINOR
lib.MODULES = lib.MODULES or {}
lib.MODULES.Feed = MINOR
```

The Core floor is 20 because the feed calls `ClassColor`. A floor on a major you call into is the standard's
floor rule, not a new edge: every other major floors on Core already. Pool, Media, Skin, Widgets and LSM are
resolved at call time behind type checks, with no floor (the Charts and Callout precedent).

**Secondaries** (`CalloutSettings.lua:73`, `:102-112` is the template):

```lua
local lib = LibStub and LibStub("LibKa0s-Feed-1.0", true)
if not lib then return end
local MODEL_MINOR = 1
if lib.__modelMinor and lib.__modelMinor >= MODEL_MINOR and lib.__modelShellMinor == lib.MINOR then return end
lib.__modelMinor, lib.__modelShellMinor = MODEL_MINOR, lib.MINOR
lib.MODULES.FeedModel = MODEL_MINOR
```

**Published constants** (lib-level, so they reach `members-1.1.1.json`): `New`, `STRATA`, `SLOTS`, `MAX_QUEUE`,
`SHOWN`, `SHOWN_MAX`, `WIDTH`, `ROW_HEIGHT`, `ICON_SIZE`, `PADDING`, `GAP`, `SLOT_INSET`, `NUDGE_MAX`,
`ENTER_TIME`, `HOLD`, `FADE_TIME`, `MERGE_WINDOW`, `PULSE_TIME`, `SLIDE_TIME`, `DROP_FADE`, `MAX_DT`. The model
and row halves stay `__` internals.

**Library bookkeeping** (all in L1 or L7):

- `tests/majors.lua`: a row after Toast's (`:80-84`):
  `{ major = "LibKa0s-Feed-1.0", files = { "Feed", "FeedModel", "FeedRow" }, primary = "Feed", paired = { { file
  = "FeedModel", minorField = "__modelMinor", probeField = "__modelShellMinor" }, { file = "FeedRow",
  minorField = "__rowMinor", probeField = "__rowShellMinor" } } }`.
- `docs/releasing.md` step 2's constant list (`:28-39`): `MINOR` in `Feed.lua`, `MODEL_MINOR` in `FeedModel.lua`,
  `ROW_MINOR` in `FeedRow.lua`, and the count "eighty-seven" becomes ninety; and the File-minor row's constant
  list (`:8`) gains `MODEL_MINOR` and `ROW_MINOR`.
- `LibKa0s/DebugLogDiagnostics.lua`: `"Feed"` after `"Toast"` in `MAJORS` (`:92-96`), the header line "Minor 13
  adds Feed (v1.119.0)", `DIAG_MINOR` 12 -> 13 (`:50`). `tests/test_debuglog_diagnostics.lua` fails without it.
  DebugLog's key moves; its API doc gets a new version too.
- `tests/run.lua`: `feed = mocks.LibStub("LibKa0s-Feed-1.0")` after `toast` (`:57`), and the suites after
  `"test_toast_stack"` (`:103`).

---

## 6. Versioned API doc, manifest, README

- `docs/api/Feed/version-1.1.1-docs.md` (key = `Feed`.`FeedModel`.`FeedRow` minors in XML order,
  `docs/api/README.md:52-107`). Status **Current**, Supersedes "none (new major)". Sections: Why this exists, with
  the **promotion record** (who ruled, date, where, consumer, "second consumer: none named yet"); The contract
  (2.1-2.8 above); Style over the skin (3.5); Degraded look (3.6); Motion (3.7); Input (3.8); Frame layering (4);
  The degradation stub and its parity form (section 8); What is not here (section 13); Vendoring. Every member
  and field has `Since 1`.
- `docs/api/Feed/members-1.1.1.json` from `lua tools/gen-api-members.lua`.
- `docs/api/README.md`: the key table row (`Feed` | `<Feed>.<FeedModel>.<FeedRow>`) and a `### LibKa0s-Feed-1.0`
  versions table after Toast's (`:223-230`): `[1.1.1] | Feed.lua 1, FeedModel.lua 1, FeedRow.lua 1 (new: the toast
  feed, Loot History #38, owner ruling X1/D24) | v1.119.0 | Current`.
- DebugLog: a new version doc for its moved key, the old one Superseded with its "Moving to" section
  (README `:695-709`).
- `docs/releasing.md` `## Consumers` table (`:823-845`): a Feed row, Consumers `LootHistory`, seam
  `core/FeedSetup.lua` as `NS.NewFeed`, stub `NS.FeedStub`. The Toast row's stale cell (only DropWatcher) is a
  separate fix, not part of this run (section 11, drift).
- `docs/api/CONSUMERS.md`: Feed's census rows at the step-9 sweep after Loot History adopts.
- `docs/test-cases.md` regenerated (`lua tests/run.lua --list`, CRLF).
- `README.md`: the Feed row in the module table, the payload tree.

---

## 7. CHANGELOG entry

```
## v1.119.0 — unreleased

Opened 2026-11-27, on `feat/2026-11-27-feed`: Ka0s Loot History #38 (its plan
`docs/superpowers/plans/2026-11-27-tooltip-toasts-farm.md`, task M3.0), items L1 to L8. Built to
WowAddonStandards v2.121.0.

Versions in this release: `LibKa0s-Feed-1.0` key **1.1.1** (Feed minor 1, FeedModel minor 1, FeedRow minor 1;
new); `LibKa0s-DebugLog-1.0` (DebugLogDiagnostics minor 13); every other file at its v1.118.0 minor, and the test
kit at revision **65**. No `NEEDS_*` floor rises.

### A toast feed (`L1` to `L6`)

- **New major `LibKa0s-Feed-1.0`** ([docs](docs/api/Feed/version-1.1.1-docs.md)), promoted with one consumer on
  the owner's ruling: Tushar Saxena (owner), 2026-11-27, Loot History plan D24 (ruling X1 of the #38 design),
  shipping with Ka0s Loot History #38. Second consumer: none named yet. Conformant under library-stack-§7
  bar 1, so no deviation row. <what it does, one paragraph>
- **DebugLogDiagnostics minor 13**: Feed in the report's major list.
- Tests: <suites and counts>.
- Documentation: <files>.

Release gate (`docs/automated-tests/<stamp>/`): lint pass, 0/0 in N files; tests pass, N tests, 0 failed;
complexity pass, 0 over CCN 15. Perf SKIPPED, not measured — no `tests/perf.lua`.

Preview and simulation re-look: <the feed's Preview and SetStrip ride the same paint path; no Sim file moved>.
```

`tests/test_versioning.lua:233-238` lets an `unreleased` heading owe nothing yet, so the branch carries it until
the owner says go; at release the date replaces `unreleased` (`docs/releasing.md:68`).

---

## 8. Degraded surface for consumers

A host that loads without the library, or with a copy that predates Feed, carries an **instance stub** and a
parity case (anti-pattern #47; `version-4-docs.md:201-225` is the form):

| Member | Stub answer |
|---|---|
| `Push` | `false` |
| `Get` | `nil` |
| `Update`, `Repaint`, `Dismiss` | `false` |
| `RepaintAll`, `Clear`, `Hold`, `Release`, `Refresh`, `ClearPreview`, `SetClickThrough`, `SetStrip` | nothing |
| `Preview` | `0` |
| `SetLocked`, `IsLocked` | `true` |
| `Visible` | `{}` |
| `Stats` | `{ live = 0, waiting = 0, dropping = 0, frozen = false, held = false, locked = true, clickThrough = false, awake = false, shown = 0, built = false }` |
| `Frame` | `nil` |

Parity: `T.assertSurfaceParity(liveFeed, NS.FeedStub, "Feed instance")` (`testkit/asserts.lua:320-333`), the
instance form, because `members-1.1.1.json` lists the lib-level surface only. `__Step` is outside the parity
surface; a host test that steps a live feed reaches it only after checking it exists.

**In Loot History** (M3.x, not this run): `core/FeedSetup.lua` leases the major once and publishes
`NS.NewFeed(d)` (setting `d.owner = addonName`) and `NS.FeedStub`, as `core/ToastSetup.lua` does in the Toast
hosts (`CONSUMERS.md:24-34`); `tests/test_surface_parity.lua` gains the instance case and the seam case;
`tests/test_libka0s.lua`'s by-name payload list (`:51-53`) gains `Feed.lua`, `FeedModel.lua` and `FeedRow.lua`
(`docs/releasing.md:255-275`); `tests/test_libka0s_releases.lua` gains a v1.119.0 block pinning
`modules("LibKa0s-Feed-1.0")` at 1/1/1 and `DebugLogDiagnostics >= 13`.

---

## 9. Tests (library)

A shared bench, `tests/fixture_feed.lua`, in the shape of `fixture_toast.lua:1-60` and
`fixture_callout.lua:148-160`: `F.env()` builds fresh kit mocks, instruments `CreateFrame` (strata, toplevel,
clamp, mouse, points, `SetPoint` count, alpha, size, scripts), loads Core and the three Feed files (plus Skin,
Media and Widgets when a case asks for the skinned path), and offers `F.feed(d)`, `F.step(feed, dt)` (sets
`m.__now` forward and fires the clock's `OnUpdate`), `F.clock(feed)` (the armed unparented frame or nil) and
`F.rows(feed)` (shown rows newest first). Suites register in `tests/run.lua` after `test_toast_stack`. Each stays
under 1500 lines; budget about 300-500 each.

| Suite | Cases |
|---|---|
| `test_feed` | MINOR and MODULES pin (`Feed`, `FeedModel`, `FeedRow` = 1); the paired guards; `New` raises without `content`; lazy build (no frame until the first push); `Push` answers `"new"`; newest at index 1 for both grows; `shown` cap drops the oldest into a 0.2 s drop and releases it; `Visible` order; `content` answering false skips and answers false; `content` raising reaches `geterrorhandler` and skips; `Get`, `Update` (no move, no pulse), `Repaint`, `Dismiss`; `Clear` stands down (clock nil, rows hidden, waiting empty, locked, reusable); `Hold`/`Release` queue, merge in waiting, cap `maxQueue`, drain only the newest `shown`; `Preview` sticky and `ClearPreview` drops only previews; `Stats` full shape always; frames created stay constant over 200 pushes (pool reuse); `Refresh` re-reads getters and re-anchors |
| `test_feed_model` | `SlotOffset` for all nine slots (inset signs); `NudgeFromRect` round trip for nine slots x two grows x scales 1 and 1.5, and the ±`NUDGE_MAX` clamp; `RowHeight` floor and line sums; `Layout` Y for mixed heights and gap; `Advance`: enter fade (eased), four slide directions and their distances, `none` = 0 enter, hold, exact bar `1 - (t-enter)/hold`, fade, done, drop from the current alpha, sticky clamps at hold with no bar, paused stops `t` but not `pulse`; snapshot defaults for empty tables and garbage values; value-or-getter reads |
| `test_feed_motion` | the clock armed on push and nil when idle; sleeps with only sticky rows; sleeps while frozen with no pulse; `MAX_DT` clamp; merge inside the window calls `d.merge`, answers `"merged"`, restarts the hold without replaying the enter (alpha 1 at once), pulses, moves to index 1; merge while entering keeps the enter; outside the window or with `mergeWindow = 0` is new; a dropping key is never merged; smooth reposition reaches `targetY` in `SLIDE_TIME` and calls `SetPoint` only while moving; `smooth = false` snaps; settle calls `content` once at `paintedAt + settle` and never again |
| `test_feed_input` | with `pin`: hovering any row freezes every row's `t`, holds Y, queues new pushes, merges in place without moving; leave unfreezes and drains; freeze is derived (dismissing the hovered row unfreezes); without `pin`: only the hovered row pauses; right-click drops with `rightDismiss`, reaches `onClick` without it; `onClick(payload, button, key)`; left click while unlocked never calls `onClick`; `SetClickThrough(true)` disables mouse on live and later rows, clears hover and freeze, drains; `SetLocked(false)` docks a DragHandle with the host's label, refuses in combat, answers true without Widgets; drag stop calls `onMoved(x, y)` with the round-tripped nudge and re-anchors; `SetStrip` docks and hides, hidden under the handle |
| `test_feed_style` | from skin: `Shell` with `noTopBar` and `noBands`; each `bgType` override and the `keepEdge` record; border colour order tint > class > skin > custom; `BarBorder` called with the style triple; every string through `HudFont`, none through a bare `SetFont`; text colour order spec > class > skin > custom; icon cropped 0.07 and `IconBorder` with `hud = true`; glow colour order and ADD blend; `OnLooksChanged` repaints live rows; degraded (no Skin, unregistered owner, no Core facade) draws without error; strata HIGH, not toplevel, clamped; rows above the container |

The library's existing gates cover the rest without new code: `test_versioning` (doc, manifest, CHANGELOG
agreement), `test_debuglog_diagnostics` (the MAJORS list), the kit's `Kit.publicMembers` surface and
`clientGlobals`.

---

## 10. Release path

1. **Branch in LibKa0s:** `feat/2026-11-27-feed`, cut from master at `4dbc1636` (v1.118.0). The owner's go is
   needed before the branch is cut, because this design is read-only.
2. Build L1-L7 on it, green gate each task (`lua tests/run.lua`; `ka0s-bounded luacheck .` 0/0), CHANGELOG
   heading `## v1.119.0 — unreleased`.
3. **Loot History vendors it unreleased:** `libs/LibKa0s/` and `tests/_kit/` copied whole from the branch head,
   and the CLAUDE.md provenance line written `Bundles [LibKa0s](...) v1.119.0 (unreleased, branch
   feat/2026-11-27-feed) (MIT).` `tests/test_vendor_sync.lua:46`'s pattern accepts it and diffs against the
   branch head in the sibling checkout. Any later commit on the branch desyncs that gate until Loot History
   re-vendors, so each library fix is followed by a re-vendor commit in the same session. The `LibKa0s icons:`
   line is unchanged (the feed draws no library icon; the drag handle's marks are already declared). The
   number is `v1.119.0`, the release the branch becomes; the owner's ruling text wrote `v1.118.0` as an
   example of the form, and the gate reads only the branch name.
4. **On the owner's merge go-ahead:** the release order (`docs/releasing.md:15-200`): date the heading, regenerate
   manifests and `docs/test-cases.md`, move the version pointers, gate, commit, `tests/_kit/run-automated-tests.sh
   --release 1.119.0` on a clean tree, ANALYSIS.md and the release-notes line, the second commit, tag `v1.119.0`,
   merge. Then Loot History re-vendors from the tag and writes the line back in its tagged shape.
5. **Other consumers** need nothing: no file they load moved except DebugLogDiagnostics (a report line). Their
   next routine re-vendor picks it up; a host pinning `DebugLogDiagnostics` exactly re-pins (Loot History pins
   `>=`).
6. **Upstream standard** (after the tag, as the Callout precedent): library-stack-§7's census ("twenty-six
   LibStub majors across eighty-seven files" becomes twenty-seven across ninety, `library-stack.md:84`) and its
   modules table gain the Feed row; frame-layering-§6 gains the row in section 4. `scripts/check-standard.sh`
   compares the count with the newest tag, so the count edit waits for the tag.

---

## 11. Deviations to flag

None in the design itself. Three items need the owner's attention as **standard changes**, not deviations:

| Rule | What | Disposition |
|---|---|---|
| `frame-layering-§6` | A new library-owned frame (the feed container, HIGH, not toplevel, clamped) needs its row in the reference table; the section says a library row is a standard change first (`frame-layering.md:108-110`). | Upstream edit in WowAddonStandards, after the tag, with the census below. |
| `library-stack-§7` | The modules census and table gain `LibKa0s-Feed-1.0` (twenty-seven majors, ninety files). | Upstream edit after the tag. |
| `library-stack-§7` bar 1 | Single-consumer promotion. Conformant on the owner's ruling; recorded in the API doc and CHANGELOG, **no register row**. | Recorded as in section 1. |

**Drift found, out of scope:** `docs/releasing.md:845`'s Toast Consumers cell names only DropWatcher, while
`docs/api/CONSUMERS.md:1038` counts four callers (CombatTrail, DropWatcher, QuickComms, SkillMaster) and DpsRace
is retired. File it separately; this run does not touch Toast.

---

## 12. Task breakdown

| Task | What | Done when |
|---|---|---|
| **L1** | Skeleton: `Feed.lua` preamble, constants, `New`, STATE, `lib.__methods`, stubbed members; `FeedModel.lua` and `FeedRow.lua` shells with paired guards; XML placement; `tests/majors.lua` row; `tests/run.lua` handle; `DebugLogDiagnostics` minor 13; `releasing.md` step 2 list; `fixture_feed.lua`; `test_feed` MINOR/MODULES/guard/New cases | gate green; `test_versioning` red only for the missing doc, which L7 fills (or a stub doc now) |
| **L2** | `FeedModel.lua`: snapshot, `SlotOffset`, `NudgeFromRect`, `RowHeight`, `Layout`, `Advance`, `Merge`, `Drain`; `test_feed_model` | all model cases green |
| **L3** | Shell engine: container, lazy build, push/present/drop, leaving set, waiting and drain, Hold/Release, Clear, Get/Update/Repaint/Dismiss, Preview, Stats, the clock (wake/sleep, `MAX_DT`), `__Step`, settle; `test_feed` and `test_feed_motion` | idle clock nil pinned; 200-push pool case green |
| **L4** | `FeedRow.lua`: template, `Place` (align, icon side, heights), `Paint` over the facade, glow, bar, degraded look, `OnLooksChanged`; `test_feed_style` | skinned and degraded both green |
| **L5** | Input: hover and derived freeze, pin on/off, clicks, rightDismiss, click-through, unlock with DragHandle, NudgeFromRect on drag stop, `onMoved`, strip; `test_feed_input` | |
| **L6** | Size check (each file under 1000; peel `FeedInput.lua` if `Feed.lua` > 900), CCN 15 sweep with lizard, luacheck 0/0 | |
| **L7** | Docs: `docs/api/Feed/version-1.1.1-docs.md` with the promotion record, `members-1.1.1.json`, DebugLog's new version doc, `docs/api/README.md` rows, `releasing.md` Consumers row, `README.md`, CHANGELOG `v1.119.0 — unreleased` block, `docs/test-cases.md` | `test_versioning` green; gate green |
| **L8** | Hand-off to Loot History: vendor the branch head with the unreleased provenance line; `core/FeedSetup.lua` + `NS.FeedStub`; parity and seam cases; by-name loader lines; release pins; both client runs green | Loot History gate green on Retail and Forever |
| **L9** (owner go) | Release v1.119.0 per section 10.4; re-vendor Loot History from the tag; upstream standard edits (section 11) | tag cut; standard counts match |

---

## 13. What is not here (the Feed doc's table)

| Not in Feed-1.0 | Stays in | Re-check trigger |
|---|---|---|
| Row content, kinds, prices, sources, upgrade rule | the host's `content` | — (the one presentation argument) |
| When to push, filters, which feed gets what | the host | — |
| A combat flag | the host's event rows calling `Hold`/`Release`, `SetClickThrough`, `SetLocked(true)` | a behaviour only the library can express (would fail bar 2) |
| Sounds | the host, on `Push` answering `"new"` | a second consumer plays sounds the same way |
| Overflow policy (queue instead of drop) | — | a consumer asks for it |
| Settings rows (`O.FeedGroup` / `SchemaRows`) | each host's schema | a second consumer's rows converge (Callout's `SchemaRows` precedent) |
| Item tooltips on hover | the host's `onEnter` | — |
| A close-reason callback | — | a host needs to tell expiry from dismiss |
