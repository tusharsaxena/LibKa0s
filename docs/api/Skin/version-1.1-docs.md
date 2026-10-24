# `LibKa0s-Skin-1.0` — version 1.1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Skin surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Skin-1.0` |
| Files and minors | `Skin.lua` minor **1** · `SkinDefs.lua` minor **1** |
| Shipped in | v1.78.0 (unreleased) |
| Status | **Current** |
| Supersedes | — (first version) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` ≥ 1 (`NEEDS_CORE = 1`; no Core member is called) |
| Confirm in-game | `LibStub("LibKa0s-Skin-1.0").MODULES` → `{ Skin = 1, SkinDefs = 1 }` |

## What this major is

**The skin engine.** Every Ka0s window, panel, dialog and settings page is drawn from constants
today: `Core.SKIN`, Widgets' file-local `SKIN`, the Options palettes, and about ninety literals in
LootHistory alone. A **skin** turns those constants into data, a token table, and a host picks one
**per addon** (Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`, the owner's rulings R1 to R4).
This version is the engine and one skin, **Ka0s Default**, whose tokens are today's constants, so an
addon that never picks another skin draws exactly what it drew before.

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
| `Skin:Repaint(owner)` | calls | Replays every primitive recorded for the owner's frames, each frame once, in first-paint order, each call under pcall; `lib.__repainting` is true while it runs. `SetChoice` calls it. |
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
    get = function() local a = NS.db.profile.appearance; return a.source, a.skin end,
    set = function(source, skin)
      local a = NS.db.profile.appearance
      a.source, a.skin = source, skin
    end,
  })
end

-- wherever a frame is built (the primitives arrive with SkinPaint.lua)
NS.Skin.Shell(frame)
local r, g, b = NS.Skin.Color("title.text")

-- the Appearance row's onChange, and after a profile switch, copy or reset
local changed, reload = Skin:SetChoice(addonName, NS.db.profile.appearance.source,
  NS.db.profile.appearance.skin)
if reload then StaticPopup_Show("MYADDON_RELOAD") end
```

`get` is read at `RegisterOwner` only, so call it after AceDB is up, or call `SetChoice` with the
profile's values once it is. A host's degradation arm (library absent) needs no stub of this major:
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

Every token in `SCHEMA` and its Ka0s Default value. The other skins' columns join this table with
their tables.

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

**192 tokens.**

## What is not here

- **No painting.** The primitives are `SkinPaint.lua`'s, a later file of this major.
- **No EllesmereUI.** The `eui` provider, its gate and its reads are `SkinEUI.lua`'s.
- **No other skin.** Obsidian, Azeroth, Glass, High Contrast, Ember, WoW Default, WoW Midnight and
  WoW Forever join `SkinDefs.lua` in a later change of this release.
- **No SavedVariables.** The host stores `{ source, skin }` in its own profile; `SetChoice` never
  writes it.
- **No migration stamp.** `ResetToSkin` is a helper; the step that runs it is each addon's.

## Vendoring

Whole-folder, like every major. `Skin.lua` returns before `NewLibrary` when Core is missing or below
minor 1, and `SkinDefs.lua` then returns on its own `LibStub("LibKa0s-Skin-1.0", true)` lookup, so
the major is absent rather than half-wired. Without `SkinDefs.lua` the engine still loads and every
token resolves to nil. The engine's state is written `lib.x = lib.x or {}`, so a newer copy that wins
the LibStub race later keeps every owner, record and facade; the resolve cache alone is rebuilt.
