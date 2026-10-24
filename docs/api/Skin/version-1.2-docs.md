# `LibKa0s-Skin-1.0` — version 1.2

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Skin surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Skin-1.0` |
| Files and minors | `Skin.lua` minor **1** · `SkinDefs.lua` minor **2** |
| Shipped in | v1.78.0 (unreleased) |
| Status | **Current** |
| Supersedes | — (first version) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` ≥ 1 (`NEEDS_CORE = 1`; no Core member is called) |
| Confirm in-game | `LibStub("LibKa0s-Skin-1.0").MODULES` → `{ Skin = 1, SkinDefs = 2 }` |

## What this major is

**The skin engine.** Every Ka0s window, panel, dialog and settings page is drawn from constants
today: `Core.SKIN`, Widgets' file-local `SKIN`, the Options palettes, and about ninety literals in
LootHistory alone. A **skin** turns those constants into data, a token table, and a host picks one
**per addon** (Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`, the owner's rulings R1 to R4).
This version is the engine and the nine skins: **Ka0s Default**, whose tokens are today's
constants, so an addon that never picks another skin draws exactly what it drew before, and eight
more translated from the owner's mockups (*The eight skins*, below).

The engine holds four things, each keyed by **owner** (the consumer's addon folder name), because
LibStub keeps one copy of this major for the whole client and two addons may wear different skins
at once:

- **the skins**, registered as data by `SkinDefs.lua`;
- **each owner's choice**, `{ source, skin }`, read once from the host's profile at registration and
  moved only through `SetChoice`;
- **the frame registry**, a weak-keyed record of every frame a primitive painted for an owner, so a
  skin switch can repaint it live, with no reload, no OnUpdate and no event;
- **the facade**, one table per owner carrying the painting vocabulary as late-bound trampolines.

It paints nothing itself. The primitives (`S.Shell`, `S.Button`, ...) arrive in `SkinPaint.lua`
(a later file of this major); until then every vocabulary entry answers nil and touches nothing. The
EllesmereUI provider (`source = "eui"`) arrives in `SkinEUI.lua`; at this version `eui` is a stored
choice whose tokens fall back to the owner's Ka0s skin.

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework. `SkinDefs.lua`
is paired on the shell's minor (`__defsMinor` / `__defsShellMinor`), the Widgets and Sim idiom, so a
skin table from one vendored copy never attaches to an engine from another. A payload without it
still runs the engine: no skin is registered and every token resolves to nil.

## Members

| Member | Answers | What it does |
|---|---|---|
| `Skin:RegisterOwner(owner, opts)` | the owner's facade | Registers `owner` at the consumer's file load. `opts.get()` answers `{ source, skin }` (or two values) from the host's profile; `opts.set(source, skin)` writes it (used by a later copy-to-every-addon action); `opts.label` names the addon. The choice is read **once**, here; an unknown source is cleaned to `"ka0s"`, a non-string skin to `"ka0s"`. A second call updates the hooks and keeps the applied choice. |
| `Skin:IsOwner(name)` | boolean | True only after `RegisterOwner`. Every factory that takes an owner paints today's way, verbatim, for a name that is not one. |
| `Skin:Owners()` | sorted array | The registered owners. |
| `Skin:For(owner)` | facade `S` | The owner's facade, `lib.facades[owner]`: one table per owner, kept for the session and across minors. Does not register the owner; an unregistered owner's facade reads Ka0s Default. |
| `Skin:GetChoice(owner)` | source, skin | The applied choice. An unregistered owner answers `"ka0s", "ka0s"`. |
| `Skin:SetChoice(owner, source, skin)` | changed, reload | See *Changing the skin* below. `nil` keeps that half. Never writes the host's profile. |
| `Skin:PendingReload(owner)` | boolean | True once the owner left `eui` this session. |
| `Skin:OnLooksChanged(owner, fn)` | fn | Calls `fn(source, skin)` after each change of the owner's skin, under pcall. The same function twice is one entry. |
| `Skin:Token(owner, name)` | value | The owner's resolved token. A color is `{ r, g, b, a }`, a shared table: never write to it. nil for a token the skin leaves alone. |
| `Skin:Color(owner, name)` | r, g, b, a | A color token's components, alpha 1 when it has three; nil otherwise. |
| `Skin:Resolve(owner, kind, value, fromSkin)` | value | `value`, or the owner's token `kind` when `value` is `FROM_SKIN` or `fromSkin` is true. |
| `Skin.ResetToSkin(profile, keys)` | count | Puts each listed key back on the skin (R3). A key holding a color (a table) keeps its color and gets its companion `<key>FromSkin = true`; any other key takes `FROM_SKIN`. Keys may be dotted paths (`"font.face"`); a path through a missing table is skipped and no table is created. The colon form works too. |
| `Skin.IsFromSkin(value)` | boolean | `value == FROM_SKIN`. |
| `Skin:RegisterSkin(def)` | def | Registers `{ key, label, desc, swatches = { 4 hex }, tokens }`. `key` and `tokens` are required; `label` defaults to the key, `desc` to `""`, `swatches` to `{}`. Re-registering a key replaces it in place (a newer `SkinDefs.lua`). Empties the resolve cache. |
| `Skin:GetSkin(key)` | def or nil | The registered definition. |
| `Skin:Skins()` | array | Every definition in registration order, Ka0s Default first: the source of a skin picker's labels, descriptions and swatches. A caller that translates reads `label` and `desc` from here and overrides them through its own strings table. |
| `Skin:ResolveSkin(key)` | token table | Ka0s Default's tokens with the skin's own over them, cached. An unregistered key resolves as Ka0s Default. Shared: never write to it. |
| `Skin:Track(owner, frame, prim, ...)` | record | For the primitives: records that `prim` painted `frame` for `owner` with these arguments. One record per frame; a frame painted for a second owner (a pooled frame) moves to it; repeating a primitive replaces its arguments and keeps its replay position. The record's `regions` table is the primitive's own. |
| `Skin:Untrack(frame)` | — | Forgets a frame (a pooled widget handed back). |
| `Skin:Repaint(owner)` | calls | Replays every primitive recorded for the owner's frames, each frame once: frames in the order they were first painted for the owner (a frame that moved to it counts from the move), and each frame's primitives in their first-paint order, each call under pcall; `lib.__repainting` is true while it runs. `SetChoice` calls it. |
| `FROM_SKIN` | `"@skin"` | The stored value meaning "take this setting from the skin". |
| `DEFAULT` | `"ka0s"` | The skin every owner wears until it picks another, and the one an unknown key resolves as. |
| `SOURCES` | `{ "ka0s", "eui" }` | The two skin sources. |
| `SCHEMA` | array | Every token, as `{ name, kind, nilable, group }` (the reference below). Read-only. |
| `VOCAB` | array | The names the facade carries as trampolines. |
| `skins`, `owners`, `painted`, `byOwner`, `facades`, `prim` | tables | The engine's state, named so the major's other files and a newer minor can reach it. **Not contract**: read the skin through the members above and the facade. `painted` and each `byOwner[owner]` are weak-keyed. |

### The facade

`S = Skin:For(owner)` carries:

- **The painting vocabulary** (`VOCAB`), each a late-bound trampoline: `S.Button(...)` looks
  `lib.prim.Button` up **at call time** and calls it as `(owner, ...)`. EllesmereUI's names first
  (`Shell`, `Panel`, `Inset`, `FadeRegions`, `FadeNineSlice`, `Button`, `WhiteButtonLabel`,
  `StateButtonLabel`, `EditBox`, `Checkbox`, `Dropdown`, `ScrollBar`, `Tab`, `SetTabSelection`,
  `CloseButton`, `PageButton`, `SquareIcon`, `SortHeaderBar`, `Font`, `White`, `ApplyBarFill`,
  `GetAccentColor`, `GetPanelColor`, `GetFont`), then the Ka0s extras (`TitleBar`, `Divider`,
  `Footer`, `Card`, `Slider`, `NavItem`, `Drawer`, `ListRow`, `MenuFrame`, `Tooltip`, `Strip`,
  `Cover`, `Text`, `ChartStyle`, `BarStyle`, `IconBorder`, `GlowColor`). A primitive no loaded file
  provides answers nil and touches nothing. **At this version none is provided.**
- **The engine, bound to the owner:** `S.Token(name)`, `S.Color(name)`, `S.Resolve(kind, value,
  fromSkin)`, `S.OnLooksChanged(fn)`, `S.IsEnabled()` (true for a registered owner), `S.GetStyle()`
  (`"ka0s:<skin key>"`), `S.apiVersion` (3, EllesmereUI's facade API version), `S.owner` and
  `S.FROM_SKIN`.

**Why trampolines.** A host caches S at file load (`NS.Skin = Skin:For("LootHistory")`). If S held
the closures of the minor that built it, a newer copy loading later would leave that host painting
with the old minor's primitives against the new minor's state. So no facade closure captures a
primitive: each reaches `lib.prim` at call time, and a newer minor re-fills every existing facade's
entries **in place** on load, so the cached table runs the winning copy's code. The facade table
itself is never replaced.

### Changing the skin

`SetChoice(owner, source, skin)`:

1. **Idempotent.** A choice equal to `GetChoice` changes nothing and answers `false, false`; an
   unregistered owner answers the same.
2. **Resolve, repaint, notify.** The new skin is resolved first, then every frame recorded for the
   owner is repainted (one pass, each frame once), then the owner's `OnLooksChanged` listeners fire.
   Another owner's frames and listeners are never touched.
3. **Leaving `eui` asks for a reload.** EllesmereUI's paint is one-way. A switch from `eui` to
   anything else stores the choice, sets the owner's pending-reload flag, and repaints and notifies
   **nothing**. The second answer, `reload`, is true exactly once per owner, on the switch that first
   set the flag, so a caller raises its reload popup at most once. While the flag is up, later
   changes are stored and not repainted: the reload applies them.

It answers `changed, reload`.

### FROM_SKIN

A HUD setting that follows the skin (R3) stores `FROM_SKIN` (`"@skin"`), or keeps its value and sets
a companion `<key>FromSkin = true` (a color, which has no natural sentinel). `S.Resolve(kind, value,
fromSkin)` answers the skin's token `kind` for either. `Skin.ResetToSkin(profile, keys)` is the
one-time migration helper: it writes the sentinel or the companion for each listed key. It stamps
nothing; the per-profile step that calls it, and its schema-version stamp, belong to each adopting
addon's own migration runner (`savedvariables`). **The sentinel never enters an LSM list or a CLI
values list.**

## Adopting it

```lua
-- core/SkinSetup.lua, loaded before any file that builds a frame
local Skin = LibStub("LibKa0s-Skin-1.0", true)
if Skin then
  NS.Skin = Skin:RegisterOwner(addonName, {
    label = "My Addon",
    -- At file load AceDB is not up yet: answer nothing, and the owner wears Ka0s Default until
    -- the SetChoice below applies the profile.
    get = function()
      local db = NS.db
      if not db then return end
      local a = db.profile.appearance
      return a.source, a.skin
    end,
    set = function(source, skin)
      local a = NS.db.profile.appearance
      a.source, a.skin = source, skin
    end,
  })
end

-- wherever a frame is built (the primitives arrive with SkinPaint.lua)
NS.Skin.Shell(frame)
local r, g, b = NS.Skin.Color("title.text")

-- once AceDB is up (OnInitialize, right after AceDB:New), in the Appearance row's onChange, and
-- after a profile switch, copy or reset
local changed, reload = Skin:SetChoice(addonName, NS.db.profile.appearance.source,
  NS.db.profile.appearance.skin)
if reload then StaticPopup_Show("MYADDON_RELOAD") end
```

`get` is read at `RegisterOwner` only. Registered at file load, as above, it runs before AceDB is
up, so it must nil-guard the database: a getter that raises is reported through `geterrorhandler()`
(a visible Lua error) and the owner falls back to Ka0s Default. Call `SetChoice` with the
profile's values once AceDB is up. A host's degradation arm (library absent) needs no stub of this major:
with no `NS.Skin` the host paints today's way.

## Ka0s Default and the token schema

A skin is `{ key, label, desc, swatches, tokens }`. Tokens are flat names. Kinds: `color`
(`{ r, g, b, a }`, 0 to 1), `colors` (an ordered list of colors), `number`, `string` (an LSM key, a
texture path, an anchor word) and `bool`. A skin derives from Ka0s Default: it names only the tokens
it changes, and `false` says "none" for a token Ka0s Default sets (it resolves to nil; a `bool` token
keeps its `false`).

**Nil means "leave the stock value alone".** A token marked nilable may resolve to nil, and a
primitive then does not touch that property: Ka0s Default leaves **every font token nil**, so a
FontString keeps its font object, its size and whatever a font-replacement addon did to it, and a
primitive calls `SetFont`/`SetFontObject` only for a non-nil token (recording the prior object and
restoring it on a switch back). The `q.*` tokens are nil in Ka0s Default, which reads the client's
`ITEM_QUALITY_COLORS`.

**Geometry is skin-invariant in leg 1.** `title.height`, `scroll.width`, `scroll.gutter` and
`win.inset` keep Ka0s Default's value in every skin, and border or nine-slice art is drawn outset or
inside a fixed inset, so content anchors never move and a live switch lays out exactly as a reload.

**Every Ka0s Default value is a constant drawn today**, pinned by `tests/test_skin.lua` against the
constant it replaces: `Core.SKIN`, `LINE_CHART`, `AUTOCOMPLETE`, and the file-local tables of
`Core.lua`, `Widgets.lua`, `OptionsNav.lua`, `OptionsDrawer.lua`, `OptionsTabs.lua`,
`OptionsScroll.lua` and `DebugLog.lua`, read out of their source; LootHistory's constants are
restated there with their sites. None comes from the mockups' CSS.

### Split roles (candidates for leg 2)

Where two sites draw one role in two colors today, both survive as two tokens rather than one pixel
changing:

| Role | Tokens | Sites |
|---|---|---|
| Heading gold | `text.heading` `1, .82, 0` · `text.headingAlt` `.91, .77, .42` | every heading · LootHistory's AH table header |
| Menu edge | `menu.border` `0, 0, 0` · `menu.borderAlt` `.62, .5, .18` | Widgets' shared popup menu · LootHistory's row menu |
| Window fill | `win.bg` `.06, .06, .08, .92` · `win.bgDense` `.06, .06, .08, .95` | `Core.SKIN` · `W.CopyWindow` |
| Chart axis | `chart.axis` `.45, .45, .5, .8` · `chart.axisAlt` `.55, .55, .6, .9` | `LINE_CHART`, Insights · the ledger's center axis |
| "Other" series | `chart.other` `.55, .62, .72` · `chart.otherLine` `.7, .7, .72` | Insights `NEUTRAL` · Timeline `OTHER` |
| Gain / loss | `sem.good` / `sem.bad` · `sem.statusOk` / `sem.statusBad` | `C.DirRGB` · the AH status lights |
| Simulation cyan | `sem.info` `.3, .8, 1` · `strip.sim` `.35, .8, 1, .12` | LootHistory `SIM_MARK` · Widgets `STRIP_FILL` |
| Idle label | `tab.text` `.7, .7, .72` (LootHistory's browser tabs) · the Options tab strip's font objects (no token: stock) | Browser `SKIN.tabIdle` · `OptionsTabs` |
| Selected vs idle | `nav.text` gold / `nav.selText` white · `drawer.text` white / `drawer.textSet` gold | `OptionsNav` · `OptionsDrawer` (opposite conventions) |

Identity colors that carry meaning by hue (LootHistory's 36 per-source colors and its bind-state
locks, class colors) are not tokens: no skin changes what they mean.

### Token reference

Every token in `SCHEMA` and its Ka0s Default value. The other eight skins' values are under *The
eight skins*, below.

### Fonts

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `font.body` | string | yes | nil (leave alone) |
| `font.title` | string | yes | nil (leave alone) |
| `font.mono` | string | yes | nil (leave alone) |
| `font.bodySize` | number | yes | nil (leave alone) |
| `font.titleSize` | number | yes | nil (leave alone) |
| `font.outline` | string | yes | nil (leave alone) |
| `font.shadow` | bool | yes | nil (leave alone) |

### Window

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `win.bg` | color | no | `0.06, 0.06, 0.08, 0.92` |
| `win.bgTop` | color | yes | nil (leave alone) |
| `win.bgBottom` | color | yes | nil (leave alone) |
| `win.bgTexture` | string | yes | nil (leave alone) |
| `win.bgDense` | color | no | `0.06, 0.06, 0.08, 0.95` |
| `win.border` | color | no | `0, 0, 0, 1` |
| `win.borderSize` | number | no | `1` |
| `win.borderStyle` | string | no | `"flat"` |
| `win.inner` | color | yes | `0.24, 0.24, 0.27, 0.85` |
| `win.inset` | number | no | `1` |
| `win.radius` | number | no | `0` |
| `title.bg` | color | yes | nil (leave alone) |
| `title.bgTop` | color | yes | nil (leave alone) |
| `title.bgBottom` | color | yes | nil (leave alone) |
| `title.text` | color | no | `1, 0.82, 0, 1` |
| `title.align` | string | yes | nil (leave alone) |
| `title.height` | number | no | `30` |
| `divider` | color | no | `0.24, 0.24, 0.27, 0.85` |
| `foot.bg` | color | yes | nil (leave alone) |
| `close.rest` | color | no | `0.7, 0.7, 0.72, 1` |
| `close.hot` | color | no | `1, 0.3, 0.3, 1` |

### Text

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `text.body` | color | no | `0.9, 0.9, 0.9, 1` |
| `text.muted` | color | no | `0.7, 0.7, 0.72, 1` |
| `text.heading` | color | no | `1, 0.82, 0, 1` |
| `text.headingAlt` | color | no | `0.91, 0.77, 0.42, 1` |
| `text.accent` | color | no | `1, 0.82, 0, 1` |
| `text.disabled` | color | no | `0.5, 0.5, 0.5, 1` |
| `text.link` | color | no | `1, 0.5, 0, 1` |
| `text.linkHot` | color | no | `1, 0.72, 0.28, 1` |
| `gtip.title` | color | no | `1, 0.82, 0, 1` |
| `gtip.body` | color | no | `0.9, 0.9, 0.9, 1` |
| `gtip.muted` | color | no | `0.5, 0.5, 0.5, 1` |

### Buttons

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `btn.bg` | color | no | `0.1, 0.1, 0.12, 0.9` |
| `btn.bgTop` | color | yes | nil (leave alone) |
| `btn.bgBottom` | color | yes | nil (leave alone) |
| `btn.border` | color | no | `0.24, 0.24, 0.27, 0.9` |
| `btn.borderSize` | number | yes | `1` |
| `btn.borderStyle` | string | yes | `"flat"` |
| `btn.text` | color | no | `1, 1, 1, 1` |
| `btn.hover` | color | no | `1, 0.82, 0, 1` |
| `btn.icon` | color | no | `0.85, 0.85, 0.85, 1` |
| `btn.radius` | number | no | `0` |
| `btnPrimary.bg` | color | no | `0.1, 0.1, 0.12, 0.9` |
| `btnPrimary.bgTop` | color | yes | nil (leave alone) |
| `btnPrimary.bgBottom` | color | yes | nil (leave alone) |
| `btnPrimary.border` | color | no | `0.24, 0.24, 0.27, 0.9` |
| `btnPrimary.borderSize` | number | yes | `1` |
| `btnPrimary.borderStyle` | string | yes | `"flat"` |
| `btnPrimary.text` | color | no | `1, 1, 1, 1` |
| `btnPrimary.hover` | color | no | `1, 0.82, 0, 1` |
| `btnPrimary.icon` | color | no | `0.85, 0.85, 0.85, 1` |
| `btnPrimary.radius` | number | no | `0` |

### Inputs

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `input.bg` | color | no | `0.1, 0.1, 0.12, 0.9` |
| `input.border` | color | no | `0.24, 0.24, 0.27, 0.9` |
| `input.borderSize` | number | yes | `1` |
| `input.borderStyle` | string | yes | `"flat"` |
| `input.text` | color | yes | nil (leave alone) |
| `input.placeholder` | color | yes | nil (leave alone) |
| `input.focus` | color | no | `1, 0.82, 0, 0.9` |
| `input.radius` | number | no | `0` |
| `check.bg` | color | no | `0.24, 0.24, 0.27, 1` |
| `check.border` | color | yes | nil (leave alone) |
| `check.borderSize` | number | yes | nil (leave alone) |
| `check.borderStyle` | string | yes | nil (leave alone) |
| `check.mark` | color | no | `1, 0.82, 0, 1` |
| `check.radius` | number | no | `0` |
| `check.texture` | string | yes | nil (leave alone) |
| `check.markTexture` | string | yes | nil (leave alone) |
| `slider.track` | color | yes | nil (leave alone) |
| `slider.trackBorder` | color | yes | nil (leave alone) |
| `slider.fill` | color | yes | nil (leave alone) |
| `slider.thumb` | color | yes | nil (leave alone) |
| `scroll.track` | color | no | `0.24, 0.24, 0.27, 0.3` |
| `scroll.thumb` | color | no | `0.5, 0.5, 0.55, 0.85` |
| `scroll.thumbOn` | color | no | `1, 1, 1, 1` |
| `scroll.thumbOff` | color | no | `0.5, 0.5, 0.5, 0.6` |
| `scroll.width` | number | no | `8` |
| `scroll.gutter` | number | no | `20` |
| `scroll.radius` | number | no | `0` |
| `scroll.thumbTexture` | string | yes | nil (leave alone) |

### Tabs and navigation

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `tab.bg` | color | no | `0.1, 0.1, 0.1, 0.85` |
| `tab.bgTop` | color | yes | `0.15, 0.15, 0.15, 0.85` |
| `tab.bgBottom` | color | yes | `0.1, 0.1, 0.1, 0.85` |
| `tab.glow` | color | no | `1, 1, 1, 0.15` |
| `tab.text` | color | no | `0.7, 0.7, 0.72, 1` |
| `tab.border` | color | yes | nil (leave alone) |
| `tab.borderSize` | number | yes | nil (leave alone) |
| `tab.borderStyle` | string | yes | nil (leave alone) |
| `tab.onBg` | color | yes | nil (leave alone) |
| `tab.onText` | color | no | `1, 0.82, 0, 1` |
| `tab.onLine` | color | no | `1, 0.82, 0, 1` |
| `tab.rule` | color | no | `1, 0.82, 0, 0.16` |
| `tab.radius` | number | no | `0` |
| `tab.texture` | string | yes | nil (leave alone) |
| `tab.onTexture` | string | yes | nil (leave alone) |
| `nav.bg` | color | no | `0.1, 0.1, 0.1, 0.5` |
| `nav.border` | color | no | `0.4, 0.4, 0.4, 1` |
| `nav.borderSize` | number | yes | nil (leave alone) |
| `nav.borderStyle` | string | yes | nil (leave alone) |
| `nav.text` | color | no | `1, 0.82, 0, 1` |
| `nav.selBg` | color | no | `0.3, 0.5, 1, 1` |
| `nav.selText` | color | no | `1, 1, 1, 1` |
| `nav.selBar` | color | yes | nil (leave alone) |

### Drawers and menus

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `drawer.bg` | color | no | `0.08, 0.07, 0.06, 0.9` |
| `drawer.bgOpen` | color | no | `0.13, 0.11, 0.08, 0.95` |
| `drawer.border` | color | no | `0.18, 0.16, 0.14, 1` |
| `drawer.borderOpen` | color | no | `0.42, 0.33, 0.13, 1` |
| `drawer.borderSize` | number | yes | `1` |
| `drawer.borderStyle` | string | yes | `"flat"` |
| `drawer.boxBg` | color | no | `0.08, 0.07, 0.05, 0.9` |
| `drawer.boxBorder` | color | no | `0.24, 0.2, 0.13, 1` |
| `drawer.text` | color | no | `1, 1, 1, 1` |
| `drawer.textSet` | color | no | `1, 0.82, 0, 1` |
| `drawer.summary` | color | no | `0.5, 0.5, 0.5, 1` |
| `drawer.summarySet` | color | no | `0.91, 0.85, 0.66, 1` |
| `menu.bg` | color | no | `0.06, 0.06, 0.08, 0.98` |
| `menu.border` | color | no | `0, 0, 0, 1` |
| `menu.borderAlt` | color | no | `0.62, 0.5, 0.18, 1` |
| `menu.borderSize` | number | yes | `1` |
| `menu.borderStyle` | string | yes | `"flat"` |
| `menu.hover` | color | no | `1, 0.82, 0, 0.15` |
| `menu.text` | color | no | `0.9, 0.9, 0.9, 1` |
| `menu.textSel` | color | no | `1, 0.82, 0, 1` |

### Lists and cards

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `list.header.bg` | color | yes | nil (leave alone) |
| `list.header.text` | color | no | `1, 0.82, 0, 1` |
| `list.stripe` | color | no | `1, 1, 1, 0.03` |
| `list.hover` | color | no | `1, 0.82, 0, 0.1` |
| `list.sel` | color | yes | nil (leave alone) |
| `list.selOutline` | color | yes | nil (leave alone) |
| `card.bg` | color | no | `0.1, 0.1, 0.12, 0.85` |
| `card.border` | color | no | `0.24, 0.24, 0.27, 0.9` |
| `panel.bg` | color | no | `0.08, 0.08, 0.1, 0.6` |
| `panel.border` | color | no | `0.24, 0.24, 0.27, 0.7` |
| `section.rule` | color | no | `1, 0.82, 0, 0.35` |
| `icon.tint` | color | no | `0.7, 0.7, 0.72, 1` |
| `icon.hot` | color | no | `1, 1, 1, 1` |
| `handle.bg` | color | no | `0, 0, 0, 0.75` |

### Overlays

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `popup.bg` | color | no | `0, 0, 0, 0.92` |
| `popup.border` | color | yes | nil (leave alone) |
| `popup.borderSize` | number | yes | nil (leave alone) |
| `popup.borderStyle` | string | yes | nil (leave alone) |
| `popup.radius` | number | no | `0` |
| `tooltip.bg` | color | yes | nil (leave alone) |
| `tooltip.border` | color | yes | nil (leave alone) |
| `strip.test` | color | no | `1, 0.65, 0.15, 0.12` |
| `strip.sim` | color | no | `0.35, 0.8, 1, 0.12` |
| `cover.dim` | color | no | `0, 0, 0, 0.6` |
| `cover.text` | color | no | `0.667, 0.667, 0.667, 1` |

### HUD

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `bar.texture` | string | no | `"Blizzard"` |
| `bar.gloss` | bool | no | `false` |
| `bar.bg` | color | yes | nil (leave alone) |
| `bar.border` | color | yes | nil (leave alone) |
| `bar.borderStyle` | string | no | `"None"` |
| `bar.borderSize` | number | no | `1` |
| `icon.border` | color | yes | nil (leave alone) |
| `glow.color` | color | yes | nil (leave alone) |
| `hud.font` | string | no | `"Friz Quadrata TT"` |
| `hud.fontSize` | number | no | `12` |
| `hud.outline` | string | no | `"OUTLINE"` |

### Charts

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `chart.axis` | color | no | `0.45, 0.45, 0.5, 0.8` |
| `chart.axisAlt` | color | no | `0.55, 0.55, 0.6, 0.9` |
| `chart.grid` | color | no | `1, 1, 1, 0.07` |
| `chart.crosshair` | color | no | `1, 1, 1, 0.35` |
| `chart.marker` | color | no | `0.8, 0.8, 0.8, 0.6` |
| `chart.line` | color | no | `0.4, 0.6, 0.95, 1` |
| `chart.bar` | color | no | `0.4, 0.6, 0.95, 0.9` |
| `chart.track` | color | no | `1, 1, 1, 0.06` |
| `chart.total` | color | no | `1, 0.82, 0, 1` |
| `chart.other` | color | no | `0.55, 0.62, 0.72, 1` |
| `chart.otherLine` | color | no | `0.7, 0.7, 0.72, 1` |
| `chart.series` | colors | no | 21 colors (LootHistory's `PALETTE`) |

### Semantic

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `q.poor` | color | yes | nil (leave alone) |
| `q.common` | color | yes | nil (leave alone) |
| `q.uncommon` | color | yes | nil (leave alone) |
| `q.rare` | color | yes | nil (leave alone) |
| `q.epic` | color | yes | nil (leave alone) |
| `q.legendary` | color | yes | nil (leave alone) |
| `sem.good` | color | no | `0.35, 0.8, 0.45, 1` |
| `sem.bad` | color | no | `1, 0.33, 0.33, 1` |
| `sem.neutral` | color | no | `0.62, 0.62, 0.66, 1` |
| `sem.warn` | color | no | `1, 0.5, 0, 1` |
| `sem.info` | color | no | `0.3, 0.8, 1, 1` |
| `sem.gold` | color | no | `1, 0.86, 0.55, 1` |
| `sem.warband` | color | no | `0.25, 0.75, 0.95, 1` |
| `sem.statusOk` | color | no | `0.3, 0.95, 0.35, 1` |
| `sem.statusWarn` | color | no | `1, 0.82, 0.1, 1` |
| `sem.statusBad` | color | no | `1, 0.32, 0.32, 1` |
| `sem.modeTest` | color | no | `1, 0.15, 0.15, 1` |
| `sem.on` | color | no | `0.3, 0.85, 0.3, 1` |
| `sem.off` | color | no | `0.9, 0.3, 0.3, 1` |

**197 tokens.** The five art tokens (`check.texture`, `check.markTexture`, `scroll.thumbTexture`,
`tab.texture`, `tab.onTexture`) joined at this version, for WoW Default's Blizzard art.

## The eight skins

Obsidian, Azeroth, Glass, High Contrast, Ember, WoW Default, WoW Midnight and WoW Forever, in that
order after Ka0s Default (`Skin:Skins()`), pinned by `tests/test_skin_defs.lua`.

### Where they come from

Each is **translated from the owner's mockups** (`docs/skins/`; the token source is
Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/inputs/mockup-tokens.dc.html`, its `SKINS` table).
In `SkinDefs.lua` each skin's `mock` table is its mockup entry key for key, with the CSS turned
into Lua, and one map (`MOCK_MAP`) carries every mockup key to the schema tokens it draws:

- **Keys.** The mockup's `classic` is `ka0s` and its `wowdefault` is `wow`; every other key is
  unchanged. Its `eui` entry is only the EllesmereUI preview and is never registered: the `eui`
  source reads EllesmereUI itself.
- **Inheritance.** A key a mockup skin leaves out inherits **Ka0s Default's Lua value**, never the
  mockup's `BASE`, and so does every token the mockups do not draw. Ka0s Default itself stays
  today's constants and is not touched by the mockup.
- **Extras.** Where the mockup draws nothing a surface needs (an opened drawer, KPI cards and
  list panels, disabled text, the hover wash on a primary button), a skin sets that token itself
  in its `extra` table, chosen from the skin's own palette. That includes `drawer.textSet` wherever
  the mockup draws the drawer label in the body color: OptionsDrawer's label color is the set /
  unset cue, so Obsidian, Azeroth and Glass take their accent and WoW Forever its heading gold. Azeroth, the one light skin, also sets
  its headings, quality colors, semantic colors and chart colors, which Ka0s Default draws for a
  dark window.
- **Derived washes.** `list.hover`, `menu.hover`, `section.rule` and `drawer.borderOpen` are the
  skin's accent at Ka0s Default's alphas (.10, .15, .35, .6), the way Ka0s Default draws them in
  gold.

### What WoW cannot draw

- **No blur.** Glass is translucency (`win.bg` alpha .55) on the shipped `Ka0s Glass` art.
- **One rounded art.** Glass's radius-8 nine-slice (`Ka0s Glass`, `LibKa0s-Media-1.0` 6.1) is the
  only rounded art shipped, so Glass's window, buttons, inputs, tabs, drawers, popups and menus
  are `nine:Ka0s Glass` at radius 8 and edge size 8, and **every other mockup radius is square**
  (0): Obsidian's 3px, Azeroth's 4px, Ember's 2px and the rest. Glass's checkbox and scroll thumb
  are too small for 8px corners and stay square too.
- **Gradients are vertical.** `linear-gradient(a, b)` is `<ctl>.bgTop = a`, `<ctl>.bgBottom = b`
  (drawn with `SetGradient` on a white texture), and the flat `<ctl>.bg` is their blend, the
  fallback. A radial fill (WoW Default's and WoW Forever's windows) becomes a vertical gradient or,
  for WoW Default, the dialog background art. A flat fill clears Ka0s Default's tab gradient.
- **Edges.** A CSS `ridge`, `outset`, `inset` or `groove` edge is Blizzard's dialog art (WoW
  Default's window and popups) or a two-tone bevel: `bevelOut` (raised: light top-left, dark
  bottom-right) or `bevelIn` (sunken). `none` and `transparent` edges are a clear 1px edge, so
  nothing moves.
- **Geometry.** The mockup's scrollbar widths (`scW`) are not translated: `title.height`,
  `scroll.width`, `scroll.gutter` and `win.inset` are Ka0s Default's in all nine skins.
- **Fonts.** A mockup family is the shipped face that stands for it: Inter (Obsidian) and Manrope
  (Glass) are Barlow, the face WoW Forever names; Azeroth, Ember and WoW Midnight draw Cinzel
  titles over the client body font; High Contrast is Atkinson Hyperlegible, body 2pt above the
  Barlow skins' 12; Ka0s Default and WoW Default keep the client's fonts (no font token).
- **GameTooltip lines.** `gtip.*` are drawn on Blizzard's dark GameTooltip whatever the skin, so
  each skin's `gtip.title`, `gtip.body` and `gtip.muted` read at 4.5:1 or better on
  `(.05, .05, .08)`; Azeroth's are its parchment and gold rather than the mockup's dark ink.
- **Legibility.** Each skin's `text.body` reads at 4.5:1 or better on its own `win.bg`, and its
  other text roles at 3:1 or better.

### Blizzard art and the per-skin choices

This closes the open texture point of the run's spec (§9 there: which Blizzard textures serve WoW
Default and Midnight, and WoW Forever's window texture).

| Skin | Choice |
|---|---|
| **WoW Default** | The window is `BACKDROP_DIALOG_32_32`'s edge, LSM `Blizzard Dialog` (`Interface\DialogFrame\UI-DialogBox-Border`), `win.borderStyle = "nine:Blizzard Dialog"` at `win.borderSize = 32`, over `win.bgTexture = Interface\DialogFrame\UI-DialogBox-Background-Dark` tiled on a `#1E1C19` fill. Popups and menus wear the same edge at 16. Buttons (and the primary button) are a red gradient `#B3200F` to `#640C05` with a 2px `bevelOut` gold `#A07C2C` edge and gold `#FFD100` text, white on hover. Tabs are `tab.texture = Interface\OptionsFrame\UI-OptionsFrame-InActiveTab` and `tab.onTexture = ...-ActiveTab`. The scroll thumb is `scroll.thumbTexture = Interface\Buttons\UI-ScrollBar-Knob`; the checkbox is `check.texture = Interface\Buttons\UI-CheckBox-Up` with `check.markTexture = ...UI-CheckBox-Check`. Inputs, checkboxes and the nav rail have a 2px `bevelIn` gray edge. The client's own fonts. |
| **WoW Midnight** | Flat `WHITE8x8` everywhere, **no Blizzard art**: a 2px `#B08A3E` window and popup edge over a `#3D2F12` inner rule, the window gradient `#171A2E` to `#0F1020`, the title bar gradient `#2A2347` to `#17142B` with a centered `#F6D27A` Cinzel title, violet `#B48CFF` accent, red-gradient buttons and a gold-gradient primary. |
| **WoW Forever** | Warm charcoal `#27231F` to `#13110F` (the mockup's radial fill as a vertical gradient, **no window texture**), black `#050505` title bars with centered white titles, a tan `#C9A07A` accent, gold `#F2B33D` headings, thin 1px edges on every control, Barlow (OWNER_SCOPE R4). |
| **Glass** | `nine:Ka0s Glass` at radius 8 (above), translucent white washes, lilac `#B69CFF` accent, `bar.gloss = true`. |
| **High Contrast** | Black, white 2px edges on the window and every control (3px yellow on popups and menus), yellow `#FFE600` titles, accent, selection outline and focus, Atkinson Hyperlegible 14 / 17. |
| **Obsidian** | Near-black flat panels, hairline `#2A2A2F` edges, no inner rule, a cool blue `#4DB8FF` accent and primary button, Barlow. |
| **Azeroth** | Parchment `#E9DDBC` window with a 3px leather `#6B4A22` edge and a `#C9A45C` inner rule, a dark `#3A2412` title bar with a gold Cinzel title, red wax-seal gradient buttons, ink `#2A1C0C` text. |
| **Ember** | Charred brown, a `#6A2E17` edge over an amber inner rule, orange `#FF7A33` accent, gradient title bar and buttons, Cinzel titles. |

An **art token** (`win.bgTexture`, `tab.texture`, `tab.onTexture`, `scroll.thumbTexture`,
`check.texture`, `check.markTexture`) draws that art at its own colors; the color token beside it
(`win.bg`, `tab.bg`, `scroll.thumb`, `check.bg`, `check.mark`) is the fallback when the art does
not load. Only WoW Default names art. For a `nine:<key>` edge, `<ctl>.border` is the art's vertex
color (white leaves Blizzard's art as drawn) and `<ctl>.borderSize` its edge size.

### The eight skins' tokens

Each skin's own tokens, in schema order; `·` inherits Ka0s Default's value (the *Token reference*
above), `none` resolves to nil. Colors are `#RRGGBB`, then the alpha when it is below 1. A group
none of the eight sets is left out (HUD apart from `bar.gloss`, and the charts apart from
Azeroth's). Generated from the live tables, so this list is what `SkinDefs.lua` holds.

#### Fonts

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `font.body` | `Ka0s Barlow` | · | `Ka0s Barlow` | `Ka0s Atkinson` | · | · | · | `Ka0s Barlow` |
| `font.title` | `Ka0s Barlow SemiBold` | `Ka0s Cinzel` | `Ka0s Barlow SemiBold` | `Ka0s Atkinson Bold` | `Ka0s Cinzel` | · | `Ka0s Cinzel` | `Ka0s Barlow SemiBold` |
| `font.bodySize` | `12` | · | `12` | `14` | · | · | · | `12` |
| `font.titleSize` | `14` | `15` | `14` | `17` | `15` | · | `15` | `14` |

#### Window

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `win.bg` | `#121214` | `#E9DDBC` | `#121622 .55` | `#000000` | `#1A0E0A .95` | `#1E1C19` | `#131527` | `#1D1A17` |
| `win.bgTop` | · | · | · | · | · | · | `#171A2E` | `#27231F` |
| `win.bgBottom` | · | · | · | · | · | · | `#0F1020` | `#13110F` |
| `win.bgTexture` | · | · | · | · | · | `UI-DialogBox-Background-Dark` | · | · |
| `win.bgDense` | `#121214` | `#E9DDBC` | `#121622 .55` | `#000000` | `#1A0E0A .95` | `#1E1C19` | `#131527` | `#1D1A17` |
| `win.border` | `#2A2A2F` | `#6B4A22` | `#FFFFFF .18` | `#FFFFFF` | `#6A2E17` | `#FFFFFF` | `#B08A3E` | `#3A3530` |
| `win.borderSize` | `1` | `3` | `8` | `2` | `1` | `32` | `2` | `1` |
| `win.borderStyle` | `flat` | `flat` | `nine:Ka0s Glass` | `flat` | `flat` | `nine:Blizzard Dialog` | `flat` | `flat` |
| `win.inner` | none | `#C9A45C` | none | none | `#C98A3A .45` | none | `#3D2F12` | none |
| `win.radius` | `0` | `0` | `8` | `0` | `0` | `0` | `0` | `0` |
| `title.bg` | `#0B0B0D` | `#3A2412` | `#FFFFFF .06` | `#000000` | `#2F150D` | `#383838` | `#211C39` | `#050505` |
| `title.bgTop` | · | · | · | · | `#3A1A0F` | `#4B4B4B` | `#2A2347` | · |
| `title.bgBottom` | · | · | · | · | `#24100A` | `#252525` | `#17142B` | · |
| `title.text` | `#F2F2F4` | `#F5C542` | `#FFFFFF` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#FFFFFF` |
| `title.align` | · | · | · | · | · | · | `CENTER` | `CENTER` |
| `divider` | `#26262B` | `#B8955A` | `#FFFFFF .12` | `#FFFFFF` | `#6A2E17` | `#6E6E6E` | `#4A3D1E` | `#2E2A26` |
| `foot.bg` | `#0B0B0D` | `#D8C697` | `#FFFFFF .04` | `#000000` | `#000000 .3` | `#000000 .3` | `#000000 .3` | `#050505` |
| `close.rest` | `#9B9BA4` | `#F5C542` | `#C9CFDB` | `#FFFFFF` | `#C7A993` | `#D9D9D9` | `#F6D27A` | `#FFFFFF` |
| `close.hot` | · | `#FF6B4A` | · | `#FF5050` | · | · | · | · |

#### Text

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `text.body` | `#E8E8EC` | `#2A1C0C` | `#F2F4F8` | `#FFFFFF` | `#F4E7DC` | `#FFFFFF` | `#F2EEF8` | `#FFFFFF` |
| `text.muted` | `#9B9BA4` | `#6A5233` | `#C9CFDB` | `#E0E0E0` | `#C7A993` | `#B8B8B8` | `#B4AFC8` | `#A39E97` |
| `text.heading` | `#F2F2F4` | `#5E3A14` | `#FFFFFF` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#F2B33D` |
| `text.headingAlt` | `#F2F2F4` | `#5E3A14` | `#FFFFFF` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#F2B33D` |
| `text.accent` | `#4DB8FF` | `#8E1B10` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFD100` | `#B48CFF` | `#C9A07A` |
| `text.disabled` | `#6A6A72` | `#7A6A50` | `#8A90A0` | `#B0B0B0` | `#8A6E5C` | `#808080` | `#7A7590` | `#7A756E` |
| `text.link` | `#4DB8FF` | `#8E1B10` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFD100` | `#B48CFF` | `#C9A07A` |
| `text.linkHot` | `#8FD3FF` | `#B8321F` | `#D4C4FF` | `#FFFFFF` | `#FFA36B` | · | `#D4BFFF` | `#E0C3A6` |
| `gtip.title` | · | `#F5C542` | · | `#FFE600` | `#FFB45A` | · | `#F6D27A` | `#FFD100` |
| `gtip.body` | · | `#E9DDBC` | · | `#FFFFFF` | · | · | · | · |
| `gtip.muted` | `#9B9BA4` | `#B8955A` | `#C9CFDB` | `#E0E0E0` | `#C7A993` | `#B8B8B8` | `#B4AFC8` | `#A39E97` |

#### Buttons

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `btn.bg` | `#1D1D21` | `#811A12` | `#FFFFFF .1` | `#000000` | `#3A190E` | `#8B160A` | `#6D140E` | `#1F1D1B` |
| `btn.bgTop` | · | `#A3241A` | · | · | `#4A2012` | `#B3200F` | `#8A1C14` | · |
| `btn.bgBottom` | · | `#5E1009` | · | · | `#2A120A` | `#640C05` | `#4F0D08` | · |
| `btn.border` | `#303036` | `#3A1206` | `#FFFFFF .18` | `#FFFFFF` | `#8A3C1C` | `#A07C2C` | `#C9A24A` | `#48433D` |
| `btn.borderSize` | `1` | `1` | `8` | `2` | `1` | `2` | `1` | `1` |
| `btn.borderStyle` | `flat` | `flat` | `nine:Ka0s Glass` | `flat` | `flat` | `bevelOut` | `flat` | `flat` |
| `btn.text` | `#E8E8EC` | `#FFD866` | `#F2F4F8` | `#FFFFFF` | `#FFCF9A` | `#FFD100` | `#FFD866` | `#FFFFFF` |
| `btn.hover` | `#4DB8FF` | `#FFFFFF` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFFFFF` | `#FFFFFF` | `#C9A07A` |
| `btn.icon` | `#E8E8EC` | `#FFD866` | `#F2F4F8` | `#FFFFFF` | `#FFCF9A` | `#FFD100` | `#FFD866` | `#FFFFFF` |
| `btn.radius` | `0` | `0` | `8` | `0` | `0` | `0` | `0` | `0` |
| `btnPrimary.bg` | `#4DB8FF` | `#811A12` | `#B69CFF` | `#FFE600` | `#C3521E` | `#8B160A` | `#CC9E35` | `#1F1D1B` |
| `btnPrimary.bgTop` | · | `#A3241A` | · | · | `#E0662A` | `#B3200F` | `#F0C14B` | · |
| `btnPrimary.bgBottom` | · | `#5E1009` | · | · | `#A63D12` | `#640C05` | `#A87A1E` | · |
| `btnPrimary.border` | `#4DB8FF` | `#3A1206` | `#B69CFF` | `#FFE600` | `#FF9A5A` | `#A07C2C` | `#FFE08A` | `#C9A07A` |
| `btnPrimary.borderSize` | `1` | `1` | `8` | `2` | `1` | `2` | `1` | `1` |
| `btnPrimary.borderStyle` | `flat` | `flat` | `nine:Ka0s Glass` | `flat` | `flat` | `bevelOut` | `flat` | `flat` |
| `btnPrimary.text` | `#06121C` | `#FFD866` | `#1A1033` | `#000000` | `#1C0A04` | `#FFD100` | `#1A1205` | `#FFFFFF` |
| `btnPrimary.hover` | `#000000` | `#FFFFFF` | `#3A2A66` | `#000000` | `#1C0A04` | `#FFFFFF` | `#1A1205` | `#C9A07A` |
| `btnPrimary.icon` | `#06121C` | `#FFD866` | `#1A1033` | `#000000` | `#1C0A04` | `#FFD100` | `#1A1205` | `#FFFFFF` |
| `btnPrimary.radius` | `0` | `0` | `8` | `0` | `0` | `0` | `0` | `0` |

#### Inputs

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `input.bg` | `#0A0A0B` | `#F7EED6` | `#000000 .28` | `#000000` | `#140A07` | `#000000` | `#08091A` | `#0A0908` |
| `input.border` | `#2E2E34` | `#A8864E` | `#FFFFFF .16` | `#FFFFFF` | `#5A2A16` | `#7A7A7A` | `#5A4A26` | `#3E3934` |
| `input.borderSize` | `1` | `1` | `8` | `2` | `1` | `2` | `1` | `1` |
| `input.borderStyle` | `flat` | `flat` | `nine:Ka0s Glass` | `flat` | `flat` | `bevelIn` | `flat` | `flat` |
| `input.text` | `#E8E8EC` | `#2A1C0C` | `#F2F4F8` | `#FFFFFF` | `#F4E7DC` | `#FFFFFF` | `#F2EEF8` | `#FFFFFF` |
| `input.placeholder` | `#8A8A93` | `#7A6342` | `#B8BFCC` | `#D0D0D0` | `#A88A76` | `#9A9A9A` | `#9A95B0` | `#8F8A83` |
| `input.focus` | `#4DB8FF` | `#8E1B10` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFD100` | `#B48CFF` | `#C9A07A` |
| `input.radius` | `0` | `0` | `8` | `0` | `0` | `0` | `0` | `0` |
| `check.bg` | `#0A0A0B` | `#F7EED6` | `#000000 .3` | `#000000` | `#140A07` | `#111111` | `#08091A` | `#0A0908` |
| `check.border` | `#3A3A42` | `#6B4A22` | `#FFFFFF .3` | `#FFFFFF` | `#8A3C1C` | `#8A8A8A` | `#B08A3E` | `#8A7A52` |
| `check.borderSize` | `1` | `1` | `1` | `2` | `1` | `2` | `1` | `1` |
| `check.borderStyle` | `flat` | `flat` | `flat` | `flat` | `flat` | `bevelIn` | `flat` | `flat` |
| `check.mark` | `#4DB8FF` | `#8E1B10` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFD100` | `#F6D27A` | `#FFD100` |
| `check.radius` | `0` | `0` | `0` | `0` | `0` | `0` | `0` | `0` |
| `check.texture` | · | · | · | · | · | `UI-CheckBox-Up` | · | · |
| `check.markTexture` | · | · | · | · | · | `UI-CheckBox-Check` | · | · |
| `slider.track` | `#2A2A2F` | `#D0BC8E` | `#FFFFFF .15` | `#000000` | `#2A140C` | `#000000` | `#1A1730` | `#3A3632` |
| `slider.trackBorder` | `#000000 0` | `#8A6A36` | `#000000 0` | `#FFFFFF` | `#5A2A16` | `#7A7A7A` | `#5A4A26` | `#000000 0` |
| `slider.fill` | `#4DB8FF` | `#8E1B10` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#000000 0` | `#B48CFF` | `#C9A07A` |
| `slider.thumb` | `#F2F2F4` | `#5E3A14` | `#FFFFFF` | `#FFFFFF` | `#FFCF9A` | `#C9A84A` | `#F6D27A` | `#C9A07A` |
| `scroll.track` | `#000000 0` | `#5A3C14 .15` | `#000000 0` | `#000000` | `#000000 .4` | `#000000` | `#000000 .4` | `#000000 0` |
| `scroll.thumb` | `#3A3A42` | `#8A6A36` | `#FFFFFF .35` | `#FFFFFF` | `#8A3C1C` | `#9A7B2A` | `#B08A3E` | `#D9D4CC` |
| `scroll.thumbOn` | `#5A5A64` | `#5E3A14` | `#FFFFFF .6` | `#FFE600` | `#C7A993` | · | `#F6D27A` | `#FFFFFF` |
| `scroll.thumbOff` | `#3A3A42` | `#8A6A36` | `#FFFFFF .35` | `#FFFFFF` | `#8A3C1C` | `#9A7B2A` | `#B08A3E` | `#D9D4CC` |
| `scroll.radius` | `0` | `0` | `0` | `0` | `0` | `0` | `0` | `0` |
| `scroll.thumbTexture` | · | · | · | · | · | `UI-ScrollBar-Knob` | · | · |

#### Tabs and navigation

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `tab.bg` | `#000000 0` | `#CDB789` | `#FFFFFF .05` | `#000000` | `#2A140C` | `#262626` | `#1A1730` | `#000000 0` |
| `tab.bgTop` | none | none | none | none | none | none | none | none |
| `tab.bgBottom` | none | none | none | none | none | none | none | none |
| `tab.glow` | `#FFFFFF .06` | `#FFFFFF .25` | · | `#FFFFFF .25` | · | · | · | · |
| `tab.text` | `#9B9BA4` | `#4A3418` | `#C9CFDB` | `#FFFFFF` | `#C7A993` | `#C9B048` | `#B4AFC8` | `#A39E97` |
| `tab.border` | `#000000 0` | `#8A6A36` | `#FFFFFF .1` | `#FFFFFF` | `#5A2A16` | `#7A7A7A` | `#5A4A26` | `#000000 0` |
| `tab.borderSize` | `1` | `1` | `8` | `2` | `1` | `2` | `1` | `1` |
| `tab.borderStyle` | `flat` | `flat` | `nine:Ka0s Glass` | `flat` | `flat` | `bevelOut` | `flat` | `flat` |
| `tab.onBg` | `#000000 0` | `#E9DDBC` | `#B69CFF .3` | `#FFE600` | `#4A2012` | `#4A4A4A` | `#2C2550` | `#000000 .4` |
| `tab.onText` | `#F2F2F4` | `#8E1B10` | `#FFFFFF` | `#000000` | `#FFB45A` | `#FFFFFF` | `#F6D27A` | `#FFFFFF` |
| `tab.onLine` | `#4DB8FF` | `#000000 0` | `#000000 0` | `#FFE600` | `#FF7A33` | `#000000 0` | `#B48CFF` | `#C9A07A` |
| `tab.rule` | `#26262B` | `#B8955A` | `#FFFFFF .12` | `#FFFFFF` | `#6A2E17` | `#6E6E6E` | `#4A3D1E` | `#2E2A26` |
| `tab.radius` | `0` | `0` | `8` | `0` | `0` | `0` | `0` | `0` |
| `tab.texture` | · | · | · | · | · | `UI-OptionsFrame-InActiveTab` | · | · |
| `tab.onTexture` | · | · | · | · | · | `UI-OptionsFrame-ActiveTab` | · | · |
| `nav.bg` | `#000000 0` | `#78501E .08` | `#000000 0` | `#000000` | `#000000 .3` | `#000000 .4` | `#000000 .3` | `#000000 .3` |
| `nav.border` | `#000000 0` | `#B8955A` | `#000000 0` | `#FFFFFF` | `#5A2A16` | `#6E6E6E` | `#4A3D1E` | `#000000 0` |
| `nav.borderSize` | `1` | `1` | `1` | `2` | `1` | `2` | `1` | `1` |
| `nav.borderStyle` | `flat` | `flat` | `flat` | `flat` | `flat` | `bevelIn` | `flat` | `flat` |
| `nav.text` | `#9B9BA4` | `#4A3418` | `#C9CFDB` | `#FFFFFF` | `#C7A993` | `#FFD100` | `#F6D27A` | `#D8D3CB` |
| `nav.selBg` | `#FFFFFF .06` | `#8E1B10` | `#FFFFFF .12` | `#FFE600` | `#FF7A33 .2` | `#5A78DC .38` | `#B48CFF .25` | `#FFFFFF .07` |
| `nav.selText` | `#F2F2F4` | `#FFE7A8` | `#FFFFFF` | `#000000` | `#FFE2C4` | `#FFFFFF` | `#FFFFFF` | `#FFFFFF` |
| `nav.selBar` | `#4DB8FF` | `#000000 0` | `#000000 0` | `#000000 0` | `#FF7A33` | `#000000 0` | `#B48CFF` | `#C9A07A` |

#### Drawers and menus

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `drawer.bg` | `#18181B` | `#D8C697` | `#FFFFFF .05` | `#000000` | `#2A140C` | `#262626` | `#1A1730` | `#1C1A17` |
| `drawer.bgOpen` | `#1D1D21` | `#CDB789` | `#FFFFFF .09` | `#000000` | `#4A2012` | `#3A3A3A` | `#2C2550` | `#24211E` |
| `drawer.border` | `#2A2A2F` | `#8A6A36` | `#FFFFFF .12` | `#FFFFFF` | `#6A2E17` | `#6E6E6E` | `#5A4A26` | `#2E2A26` |
| `drawer.borderOpen` | `#4DB8FF .6` | `#8E1B10 .6` | `#B69CFF .6` | `#FFE600` | `#FF7A33 .6` | `#FFD100 .6` | `#B48CFF .6` | `#C9A07A .6` |
| `drawer.borderSize` | `1` | `1` | `8` | `2` | `1` | `2` | `1` | `1` |
| `drawer.borderStyle` | `flat` | `flat` | `nine:Ka0s Glass` | `flat` | `flat` | `bevelOut` | `flat` | `flat` |
| `drawer.boxBg` | `#121214` | `#F7EED6` | `#000000 .2` | `#000000` | `#140A07` | `#111111` | `#08091A` | `#0A0908` |
| `drawer.boxBorder` | `#2A2A2F` | `#8A6A36` | `#FFFFFF .12` | `#FFFFFF` | `#6A2E17` | `#6E6E6E` | `#5A4A26` | `#2E2A26` |
| `drawer.text` | `#E8E8EC` | `#2A1C0C` | `#F2F4F8` | `#FFFFFF` | `#F4E7DC` | `#FFFFFF` | `#F2EEF8` | `#FFFFFF` |
| `drawer.textSet` | `#4DB8FF` | `#8E1B10` | `#B69CFF` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#F2B33D` |
| `drawer.summary` | `#9B9BA4` | `#6A5233` | `#C9CFDB` | `#E0E0E0` | `#C7A993` | `#B8B8B8` | `#B4AFC8` | `#A39E97` |
| `drawer.summarySet` | `#A8DBFF` | `#8E1B10` | `#D4C4FF` | `#FFE600` | `#FFCF9A` | · | `#F6D27A` | `#E0C3A6` |
| `menu.bg` | `#121214` | `#E9DDBC` | `#121622 .6` | `#000000` | `#1A0E0A .97` | `#1E1C19` | `#131527` | `#1D1A17` |
| `menu.border` | `#34343A` | `#6B4A22` | `#FFFFFF .18` | `#FFE600` | `#8A3C1C` | `#FFFFFF` | `#B08A3E` | `#3A3530` |
| `menu.borderAlt` | `#34343A` | `#6B4A22` | `#FFFFFF .18` | `#FFE600` | `#8A3C1C` | `#FFFFFF` | `#B08A3E` | `#3A3530` |
| `menu.borderSize` | `1` | `3` | `8` | `3` | `1` | `16` | `2` | `1` |
| `menu.borderStyle` | `flat` | `flat` | `nine:Ka0s Glass` | `flat` | `flat` | `nine:Blizzard Dialog` | `flat` | `flat` |
| `menu.hover` | `#4DB8FF .15` | `#8E1B10 .15` | `#B69CFF .15` | `#FFE600 .25` | `#FF7A33 .15` | `#FFD100 .15` | `#B48CFF .15` | `#C9A07A .15` |
| `menu.text` | `#E8E8EC` | `#2A1C0C` | `#F2F4F8` | `#FFFFFF` | `#F4E7DC` | `#FFFFFF` | `#F2EEF8` | `#FFFFFF` |
| `menu.textSel` | `#4DB8FF` | `#8E1B10` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFD100` | `#B48CFF` | `#C9A07A` |

#### Lists and cards

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `list.header.bg` | `#18181B` | `#D8C697` | `#FFFFFF .06` | `#1A1A1A` | `#FF7A33 .08` | `#FFFFFF .07` | `#B48CFF .08` | `#000000 .35` |
| `list.header.text` | `#9B9BA4` | `#3A2412` | `#C9CFDB` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#FFFFFF` |
| `list.stripe` | `#FFFFFF .02` | `#78501E .07` | `#FFFFFF .03` | `#0D0D0D` | `#FFFFFF .025` | `#FFFFFF .03` | `#FFFFFF .025` | `#FFFFFF .025` |
| `list.hover` | `#4DB8FF .1` | `#8E1B10 .1` | `#B69CFF .1` | `#FFE600 .2` | `#FF7A33 .1` | `#FFD100 .1` | `#B48CFF .1` | `#C9A07A .1` |
| `list.sel` | `#4DB8FF .14` | `#8E1B10 .16` | `#B69CFF .24` | `#000000` | `#FF7A33 .18` | `#FFD100 .18` | `#B48CFF .2` | `#C9A07A .16` |
| `list.selOutline` | · | · | · | `#FFE600` | · | · | · | · |
| `card.bg` | `#18181B` | `#F3E8CB` | `#FFFFFF .06` | `#000000` | `#2A140C .85` | `#000000 .4` | `#1A1730 .85` | `#1C1A17` |
| `card.border` | `#2A2A2F` | `#B8955A` | `#FFFFFF .14` | `#FFFFFF` | `#5A2A16` | `#6E6E6E` | `#4A3D1E` | `#2E2A26` |
| `panel.bg` | `#0F0F11` | `#78501E .08` | `#FFFFFF .04` | `#000000` | `#000000 .3` | `#000000 .3` | `#000000 .3` | `#000000 .3` |
| `panel.border` | `#26262B` | `#B8955A` | `#FFFFFF .12` | `#FFFFFF` | `#5A2A16` | `#6E6E6E` | `#4A3D1E` | `#2E2A26` |
| `section.rule` | `#4DB8FF .35` | `#8E1B10 .35` | `#B69CFF .35` | `#FFE600` | `#FF7A33 .35` | `#FFD100 .35` | `#B48CFF .35` | `#C9A07A .35` |
| `icon.tint` | `#9B9BA4` | `#6A5233` | `#C9CFDB` | `#E0E0E0` | `#C7A993` | `#B8B8B8` | `#B4AFC8` | `#A39E97` |
| `icon.hot` | `#4DB8FF` | `#8E1B10` | `#FFFFFF` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#C9A07A` |

#### Overlays

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `popup.bg` | `#121214` | `#E9DDBC` | `#121622 .6` | `#000000` | `#1A0E0A .97` | `#1E1C19` | `#131527` | `#1D1A17` |
| `popup.border` | `#34343A` | `#6B4A22` | `#FFFFFF .18` | `#FFE600` | `#8A3C1C` | `#FFFFFF` | `#B08A3E` | `#3A3530` |
| `popup.borderSize` | `1` | `3` | `8` | `3` | `1` | `16` | `2` | `1` |
| `popup.borderStyle` | `flat` | `flat` | `nine:Ka0s Glass` | `flat` | `flat` | `nine:Blizzard Dialog` | `flat` | `flat` |
| `popup.radius` | `0` | `0` | `8` | `0` | `0` | `0` | `0` | `0` |
| `tooltip.bg` | `#0E0E10` | `#F3E8CB` | `#0F121C .75` | `#000000` | `#140A07` | `#000010 .92` | `#0A0A1A .95` | `#0E0D0B` |
| `tooltip.border` | `#34343A` | `#6B4A22` | `#FFFFFF .18` | `#FFFFFF` | `#8A3C1C` | `#9A9A9A` | `#B08A3E` | `#3A3530` |

#### HUD

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `bar.gloss` | none | · | `true` | none | · | · | · | none |

#### Charts

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `chart.axis` | · | `#3A2412 .6` | · | · | · | · | · | · |
| `chart.axisAlt` | · | `#3A2412 .75` | · | · | · | · | · | · |
| `chart.grid` | · | `#3A2412 .12` | · | · | · | · | · | · |
| `chart.crosshair` | · | `#3A2412 .45` | · | · | · | · | · | · |
| `chart.marker` | · | `#3A2412 .5` | · | · | · | · | · | · |
| `chart.line` | · | `#00519E` | · | · | · | · | · | · |
| `chart.bar` | · | `#00519E .85` | · | · | · | · | · | · |
| `chart.track` | · | `#3A2412 .08` | · | · | · | · | · | · |
| `chart.total` | · | `#8E1B10` | · | · | · | · | · | · |
| `chart.other` | · | `#6A5233` | · | · | · | · | · | · |
| `chart.otherLine` | · | `#8A7656` | · | · | · | · | · | · |

#### Semantic

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `q.poor` | · | `#5A5A5A` | · | · | · | · | · | · |
| `q.common` | · | `#2A1C0C` | · | · | · | · | · | · |
| `q.uncommon` | · | `#1C6B12` | `#5CFF5C` | `#5CFF5C` | · | · | · | · |
| `q.rare` | · | `#00519E` | `#5AA9FF` | `#6DB6FF` | · | · | · | · |
| `q.epic` | · | `#6A1FA8` | `#C58BFF` | `#D199FF` | · | · | · | · |
| `q.legendary` | · | `#A65A00` | · | · | · | · | · | · |
| `sem.good` | · | `#1C6B12` | · | · | · | · | · | · |
| `sem.bad` | · | `#B3261E` | · | · | · | · | · | · |
| `sem.neutral` | · | `#6A5233` | · | · | · | · | · | · |
| `sem.warn` | · | `#A65A00` | · | · | · | · | · | · |
| `sem.info` | · | `#00519E` | · | · | · | · | · | · |
| `sem.gold` | · | `#7A5A10` | · | · | · | · | · | · |
| `sem.warband` | · | `#00628A` | · | · | · | · | · | · |
| `sem.statusOk` | · | `#1C7B22` | · | · | · | · | · | · |
| `sem.statusWarn` | · | `#9A7400` | · | · | · | · | · | · |
| `sem.statusBad` | · | `#B3261E` | · | · | · | · | · | · |
| `sem.on` | · | `#1C7B22` | · | · | · | · | · | · |
| `sem.off` | · | `#B3261E` | · | · | · | · | · | · |

Tokens each skin sets of its own: Obsidian 125, Azeroth 158, Glass 127, High Contrast 132, Ember 128, WoW Default 128, WoW Midnight 131, WoW Forever 128.

## What is not here

- **No painting.** The primitives are `SkinPaint.lua`'s, a later file of this major.
- **No EllesmereUI.** The `eui` provider, its gate and its reads are `SkinEUI.lua`'s.
- **No SavedVariables.** The host stores `{ source, skin }` in its own profile; `SetChoice` never
  writes it.
- **No migration stamp.** `ResetToSkin` is a helper; the step that runs it is each addon's.

## Vendoring

Whole-folder, like every major. `Skin.lua` returns before `NewLibrary` when Core is missing or below
minor 1, and `SkinDefs.lua` then returns on its own `LibStub("LibKa0s-Skin-1.0", true)` lookup, so
the major is absent rather than half-wired. Without `SkinDefs.lua` the engine still loads and every
token resolves to nil. The engine's state is written `lib.x = lib.x or {}`, so a newer copy that wins
the LibStub race later keeps every owner, record and facade; the resolve cache alone is rebuilt.
