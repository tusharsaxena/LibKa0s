# `LibKa0s-Skin-1.0` — version 3.3.2.1.1.1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Skin surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Skin-1.0` |
| Files and minors | `Skin.lua` minor **3** · `SkinDefs.lua` minor **3** · `SkinPaint.lua` minor **2** · `SkinPaintExtras.lua` minor **1** · `SkinPaintControls.lua` minor **1** · `SkinEUI.lua` minor **1** |
| Shipped in | v1.78.0 (unreleased) |
| Status | **Current** |
| Supersedes | — (first version) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` ≥ 1 (`NEEDS_CORE = 1`). One Core member is used, optionally: `SkinEUI.lua` resolves `SafeRegisterEvent` at call time; with a Core that lacks it no `ADDON_LOADED` / `PLAYER_LOGIN` retry frame is made, and owners register with EllesmereUI only at `RegisterOwner` |
| Confirm in-game | `LibStub("LibKa0s-Skin-1.0").MODULES` → `{ Skin = 3, SkinDefs = 3, SkinPaint = 2, SkinPaintExtras = 1, SkinPaintControls = 1, SkinEUI = 1 }` |

## What this major is

**The skin engine.** Every Ka0s window, panel, dialog and settings page is drawn from constants
today: `Core.SKIN`, Widgets' file-local `SKIN`, the Options palettes, and about ninety literals in
LootHistory alone. A **skin** turns those constants into data, a token table, and a host picks one
**per addon** (Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`, the owner's rulings R1 to R4).
This version is the engine, the nine skins, the paint primitives and the EllesmereUI provider:
**Ka0s Default**, whose tokens are today's constants, so an addon that never picks another skin
draws exactly what it drew before, eight more translated from the owner's mockups (*The eight
skins*, below), the primitives the facade calls (*The primitives*, below), and the `eui` source,
which hands the vocabulary to EllesmereUI's own skinning facade (*The EllesmereUI provider*, below).

The engine holds four things, each keyed by **owner** (the consumer's addon folder name), because
LibStub keeps one copy of this major for the whole client and two addons may wear different skins
at once:

- **the skins**, registered as data by `SkinDefs.lua`;
- **each owner's choice**, `{ source, skin }`, read once from the host's profile at registration and
  moved only through `SetChoice`;
- **the frame registry**, a weak-keyed record of every frame a primitive painted for an owner, so a
  skin switch can repaint it live, with no reload, no OnUpdate and no event;
- **the facade**, one table per owner carrying the painting vocabulary as late-bound trampolines.

The engine paints nothing itself: the primitives (`S.Shell`, `S.Button`, ...) are
`SkinPaint.lua`'s, `SkinPaintExtras.lua`'s and `SkinPaintControls.lua`'s (*The primitives*,
below), and a payload without them has a facade whose every vocabulary entry answers nil and
touches nothing. The EllesmereUI provider (`source = "eui"`) is `SkinEUI.lua`'s; without it `eui` is
a stored choice whose tokens fall back to the owner's Ka0s skin.

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework; the
primitives also read LibSharedMedia-3.0 at call time when it is loaded (faces, border art), and
`Shell` calls `Core.ApplySkin`. `SkinDefs.lua`, the three primitive files and `SkinEUI.lua` are
paired on the shell's minor (`__defsMinor` / `__defsShellMinor`, `__paintMinor` / `__paintShellMinor`,
`__extrasMinor` / `__extrasShellMinor`, `__controlsMinor` / `__controlsShellMinor`, `__euiMinor` /
`__euiShellMinor`), the Widgets
and Sim idiom, so a skin table or a primitive from one vendored copy never attaches to an engine
from another. A payload without it
still runs the engine: no skin is registered and every token resolves to nil.

## Members

| Member | Answers | What it does |
|---|---|---|
| `Skin:RegisterOwner(owner, opts)` | the owner's facade | Registers `owner` at the consumer's file load. `opts.get()` answers `{ source, skin }` (or two values) from the host's profile; `opts.set(source, skin)` writes it (used by a later copy-to-every-addon action); `opts.label` names the addon; `opts.log(line)`, optional, takes the one line the EllesmereUI provider writes when it refuses a facade or stops painting (a host hands its debug console's writer). The choice is read **once**, here; an unknown source is cleaned to `"ka0s"`, a non-string skin to `"ka0s"`. A second call updates the hooks and keeps the applied choice. With `SkinEUI.lua` loaded it also registers the owner with EllesmereUI (*The EllesmereUI provider*). |
| `Skin:IsOwner(name)` | boolean | True only after `RegisterOwner`. Every factory that takes an owner paints today's way, verbatim, for a name that is not one. |
| `Skin:Owners()` | sorted array | The registered owners. |
| `Skin:For(owner)` | facade `S` | The owner's facade, `lib.facades[owner]`: one table per owner, kept for the session and across minors. Does not register the owner; an unregistered owner's facade reads Ka0s Default. |
| `Skin:GetChoice(owner)` | source, skin | The applied choice. An unregistered owner answers `"ka0s", "ka0s"`. |
| `Skin:SetChoice(owner, source, skin)` | changed, reload | See *Changing the skin* below. `nil` keeps that half. Never writes the host's profile. |
| `Skin:PendingReload(owner)` | boolean | True once the owner needs a reload: it left `eui`, or a gate condition failed, after EllesmereUI painted it this session. |
| `Skin:OnReloadRequest(owner, fn)` | fn | Calls `fn(owner)` once, when `PendingReload` first turns true: on the switch `SetChoice` answers `reload = true` for, or when the gate closes after EllesmereUI painted the owner (read through `GetEUIStatus`). Under pcall; the same function twice is one entry. A caller raises its reload popup from this **or** from `SetChoice`'s answer, not both. |
| `Skin:OnLooksChanged(owner, fn)` | fn | Calls `fn(source, skin)` after each change of the owner's skin, under pcall. The same function twice is one entry. |
| `Skin:Token(owner, name)` | value | The owner's resolved token: from its skin resolved (`ResolveSkin`), or, while EllesmereUI paints the owner, from Ka0s Default with EllesmereUI's accent, panel color and font over it (*The EllesmereUI provider*). An unregistered owner reads Ka0s Default. A color is `{ r, g, b, a }`, a shared table: never write to it. nil for a token the skin leaves alone. |
| `Skin:Color(owner, name)` | r, g, b, a | A color token's components, alpha 1 when it has three; nil otherwise. |
| `Skin:Resolve(owner, kind, value, fromSkin)` | value | `value`, or the owner's token `kind` when `value` is `FROM_SKIN` or `fromSkin` is true. |
| `Skin.ResetToSkin(profile, keys)` | count | Puts each listed key back on the skin (R3). A key holding a color (a table), or one with a `<key>FromSkin` companion beside it (an `OptionsCompose` `fromSkin` picker), keeps its value and gets the companion set to `true` (Skin minor 3); a bool key (a companion named directly) is set to `true`; any other key takes `FROM_SKIN`. Keys may be dotted paths (`"font.face"`); a path through a missing table is skipped and no table is created. The colon form works too. |
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
| `Skin:GetEUIStatus(owner)` | status | `SkinEUI.lua`. Whether the owner may choose `eui`, and why not: `{ ok, painted, refused, conditions }`; see *The EllesmereUI provider*. |
| `skins`, `owners`, `painted`, `byOwner`, `facades`, `prim`, `euiFacade`, `euiRegistered`, `euiPainted`, `euiRefused`, `shared` | tables | The engine's state and the provider's (`SkinEUI.lua` writes the `eui*` tables and `shared`; `Skin.lua` declares `euiPainted` and reads it), named so the major's other files and a newer minor can reach it. **Not contract**, and neither are the `__`-prefixed members (`__Tokens`, the owner's whole token table, which the primitives, `Token` and `Color` read; `__MarkShared(target)`, which the library's own files use to mark a pooled or shared object, weak-keyed, so it is never handed to EllesmereUI): read the skin through the members above and the facade. `painted`, each `byOwner[owner]` and `shared` are weak-keyed. |

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
  provides answers nil and touches nothing. **At this version every one is provided** (*The
  primitives*, below).
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
3. **Leaving `eui` after EllesmereUI painted asks for a reload.** EllesmereUI's paint is one-way.
   A switch from `eui` to anything else, once EllesmereUI painted the owner this session
   (`euiPainted[owner]`), stores the choice, sets the owner's pending-reload flag, fires
   `OnReloadRequest`, and repaints and notifies **nothing**. The second answer, `reload`, is true
   exactly once per owner, on the switch that first set the flag, so a caller raises its reload popup
   at most once. While the flag is up, later changes are stored and not repainted: the reload
   applies them. Leaving an `eui` EllesmereUI never painted is an ordinary change (rule 2): the
   owner was wearing its Ka0s skin all along.
4. **Moving onto `eui`** hands the paint to `SkinEUI.lua` when it is loaded: it paints with
   EllesmereUI when the gate holds (*Entering EllesmereUI*, below), and otherwise the owner stays
   on its Ka0s skin and is repainted as in rule 2.

It answers `changed, reload`.

### FROM_SKIN

A HUD setting that follows the skin (R3) stores `FROM_SKIN` (`"@skin"`), or keeps its value and sets
a companion `<key>FromSkin = true` (a color, which has no natural sentinel). `S.Resolve(kind, value,
fromSkin)` answers the skin's token `kind` for either. `Skin.ResetToSkin(profile, keys)` is the
one-time migration helper: it writes the sentinel or the companion for each listed key. It stamps
nothing; the per-profile step that calls it, and its schema-version stamp, belong to each adopting
addon's own migration runner (`savedvariables`). **The sentinel never enters an LSM list or a CLI
values list.**

**A media pick follows the skin through its companion, never the sentinel** (Skin minor 3, with
`LibKa0s-Options-1.0`'s `OptionsCompose.lua` minor 12). An LSM30 picker shows its list's key as the
label and uses the list's value as the media path, and that list is the CLI's allowed values, so a
sentinel stored in a font, border or bar-texture key would draw no preview and be a value nothing can
render. `O.FontGroup` / `O.BorderGroup` / `O.BarGroup` with `fromSkin = true` emit a bool
`<key>FromSkin` beside the picker instead, and `ResetToSkin` sets that companion to `true` whether
the list names the pick (`"hud.font"`, when `"hud.fontFromSkin"` exists beside it) or the companion
itself; the pick keeps its value for when the player turns the companion off. The host draws with
`S.Resolve(token, pick, fromSkin)`.

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

-- wherever a frame is built, after the host's own SetScript calls (see The primitives)
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

**The library's own controls take the owner too.** `Core.ApplySkin(frame, nil, owner)` and
`Core.MakeCloseButton(parent, onClick, addonName)` (`LibKa0s-Core-1.0` 13), and every Widgets
constructor's `owner` (`LibKa0s-Widgets-1.0` 16.2.6.4.4.1: the dropdown and the shared menu it
drops, the search box, the strip, the copy window through its `addonName`, the autocomplete, the
drag handle, the reorder list and the line chart), paint through the owner's facade once the
owner is registered, and draw exactly what they drew before for any other name. A host passes its
folder name, which it already passes to `MakeCloseButton`. Each major's document lists the tokens
its controls read.

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
| `handle.edge` | color | no | `1, 0.82, 0, 0.6 |`
| `handle.rest` | color | no | `0.7, 0.7, 0.7, 1 |`
| `list.dropLine` | color | no | `1, 0.82, 0, 0.9 |`
| `list.ghostBg` | color | no | `0.12, 0.12, 0.12, 0.95 |`
| `list.box` | color | no | `1, 1, 1, 0.06 |`
| `list.boxDim` | color | no | `1, 1, 1, 0.03 |`
| `list.boxEdge` | color | no | `1, 1, 1, 0.12 |`
| `list.boxEdgeDim` | color | no | `1, 1, 1, 0.06 |`

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

**205 tokens.** The five art tokens (`check.texture`, `check.markTexture`, `scroll.thumbTexture`,
`tab.texture`, `tab.onTexture`) joined at SkinDefs minor 2, for WoW Default's Blizzard art. The
eight **Widgets tokens** (`handle.edge`, `handle.rest`, `list.dropLine`, `list.ghostBg`, `list.box`,
`list.boxDim`, `list.boxEdge`, `list.boxEdgeDim`) joined at SkinDefs minor 3, so the drag handle and
the reorder list (`LibKa0s-Widgets-1.0` 16.2.6.4.4.1, *Skin owners*) follow a skin with Ka0s
Default's pixels unchanged: each is the constant that widget drew, where no existing token carried
that exact value (`icon.tint` is `0.7, 0.7, 0.72`, the handle's rest gray `0.7, 0.7, 0.7`). The other
eight skins derive them: `handle.edge` and `list.dropLine` from the skin's accent at 0.6 and 0.9
(as `list.hover` is at 0.1), the four boxes from its body text at 0.06, 0.03, 0.12 and 0.06,
`handle.rest` from its muted text and `list.ghostBg` from its popup fill.

## The primitives

`SkinPaint.lua`, `SkinPaintExtras.lua` and `SkinPaintControls.lua` fill `lib.prim` with one
function per `VOCAB` name, `fn(owner, target, ...)`, which the facade's trampolines reach at call
time: `S.Button(btn, opts)` is `lib.prim.Button(owner, btn, opts)`. Each file is paired on the
shell's minor (`__paintMinor` / `__paintShellMinor`, `__extrasMinor` / `__extrasShellMinor`,
`__controlsMinor` / `__controlsShellMinor`); the extras and the controls paint with
`SkinPaint.lua`'s helpers (`lib.__P`, not contract) and attach only when that file attached to the
same shell, so a payload missing `SkinPaint.lua` has no primitive at all and every vocabulary entry
answers nil.

### How every primitive paints

- **Recorded.** A primitive that paints a target records itself on it (`Skin:Track`) with the
  arguments it was given, so `SetChoice` replays it with the new skin. Calling it again replaces
  the arguments and keeps its place in the replay order (`S.ListRow(row, state)` from a pooled row's
  bind step repaints with the latest state). The getters record nothing.
- **Idempotent.** Every Ka0s region (a fill, an edge, a gradient, a mark, a glyph) is created once
  per target, kept in the target's weak record (`rec.regions`) and reused by every later call and
  every repaint. Nothing is written onto a frame's table.
- **Stock art is faded, never destroyed.** A template's art (a button's normal, pushed, disabled
  and highlight textures, a template's `Left` / `Middle` / `Right` pieces, a `NineSlice`'s nine
  pieces, and any regions the caller names in `opts.stock`) is faded with `SetAlpha(0)` and its
  prior alpha recorded. No primitive calls `Hide`, `SetParent`, `SetScript` (bar the one below) or
  `SetTexture("")` on a frame it did not make, and none replaces a method.
- **Ka0s Default keeps stock art.** On Ka0s Default a target that carries template art is left as
  the client draws it: nothing is painted, and everything a previous skin faded, recolored or drew
  on it is put back. Ka0s Default is today's look, and today a stock control is stock. A custom
  target (a BackdropTemplate frame the library or the host built) is painted from Ka0s Default's
  tokens, which are today's constants.
- **The holders.** Every Ka0s overlay that is not the target's own fill lives on one of two child
  frames of the target, each made once, `SetAllPoints` over it and made with BackdropTemplate. Never
  a direct region of a frame an EllesmereUI primitive may reach, because EllesmereUI's FadeRegions
  fades every direct region of the frame it skins. **Edges** (borders, a divider's line, a tab's
  underline, a nav entry's selection bar, a list row's selection outline) go on the **holder**, at the
  target's frame level + 1, so a nine-slice edge can be its backdrop and every edge draws over the
  target. **Fills and washes** (a list row's stripe, hover and selection washes, the strip and cover
  washes, the extras' fills and gradients: `TitleBar`, `Footer`, `Card`, `SortHeaderBar`, a boxed
  `Drawer` header) go on the **fill holder**, at the target's frame level - 1 (never below 0): a region
  of a higher frame draws over every region of a lower one whatever its layer, so a fill one level up
  would bury the target's own text, which is how BackdropTemplate frames sit under their parent. On an
  extra that wears a backdrop and gets a gradient, the gradient on the fill holder is the fill, and
  the backdrop's own fill is cleared.
- **Lasting regions, and owner moves.** A target's regions, holders, saved values and hook flags are
  kept in a weak per-target table (`lib.__regions`) that outlives its record, so a record dropped by
  `Skin:Untrack` and painted again, or a target moved to another owner, reuses them: a frame is never
  collected and a hook never removed, so making them again would grow without bound on a pooled
  widget. A target painted for a second owner is first **given back** (everything the first owner's
  skin faded, recolored, re-fonted, backdropped or drew put back), then painted for the new one, so no
  skin leaks into another addon's frame.
- **Backdrops.** A frame wears a backdrop when it carries BackdropTemplate, which the primitives
  read from the frame's own table (the template's mixin copies `SetBackdrop` there). Only such a
  frame, or the holder, is ever given `SetBackdrop`, and only a target the library or the owner
  created: never pass a Blizzard frame you did not create. A stock frame's own backdrop is recorded
  before the first change and put back on Ka0s Default and when the target moves to another owner.
- **Borders.** A token's `borderStyle` is `flat` (the backdrop's own edge, or four 1px-and-up edge
  textures on the holder for a frame with no backdrop), `bevelOut` / `bevelIn` (two-tone edges on the
  holder, light top-left and dark bottom-right, or the reverse) or `nine:<LibSharedMedia border
  key>` (the holder's backdrop edge at `borderSize`, drawn outset by a quarter of its size so the art's
  soft band sits outside the target and content anchors never move; `border` is the art's vertex
  color). An unknown key draws a flat 1px edge. `Blizzard Dialog`, `Blizzard Dialog Gold` and
  `Blizzard Tooltip` resolve to the client's own paths when LibSharedMedia lacks them.
- **Gradients** are `SetGradient("VERTICAL", bottom, top)` on a white color texture, from a fill
  token's `<fill>Top` / `<fill>Bottom` pair; a later flat fill resets the gradient to white.
- **Fonts** go through one font object per owner and role (`LibKa0sSkin_<owner>_<role>`, role
  `body`, `title` or `mono`), created with `CreateFont`, given the face, size, outline and (unless
  `font.shadow` is false) a 1, -1 black shadow, then set on the string with `SetFontObject`: from
  12.0.7 a runtime `SetShadow*` on a FontString no longer renders, a font object's shadow does. A nil
  face token (every font token in Ka0s Default) leaves the string's font alone, and puts back the
  font object it had before a skin's face reached it. Faces resolve through LibSharedMedia.
- **Colors.** A text or vertex color whose alpha is 1 is passed as three components, as every call
  site writes them; fills and backdrop colors as four. A color from a nilable token, or any color on
  a stock target, records the prior color first and puts it back when the token resolves to nil.
- **Hover and focus** are `HookScript`'d once per target and read the target's record at call time,
  so a skin switch needs no new hook and a pooled control that moved to another owner hovers in that
  owner's skin. Call a primitive **after** the host sets its own scripts: a later `SetScript`
  replaces the hook. `S.CloseButton(btn, { own = true })` is the one primitive that SetScripts, for
  a close button the library built and that has no host script, as Core's does today.

### Ka0s Default is today's paint, call for call

For a registered owner on Ka0s Default, each primitive makes the paint calls the code it stands for
makes today, in the same order, with the same arity, on the same objects. `tests/test_skin_paint.lua`
and `tests/test_skin_paint_controls.lua` pin each with the kit's paint recorder and a call tracer:

| Primitive | Pinned against |
|---|---|
| `Shell(frame)` | `Core.ApplySkin(frame)`, run on an identical frame: it **is** that call, handed Core's own `SKIN` table, for a registered owner and for an unregistered name alike |
| `Panel(frame)` | LootHistory's list panel (`modules/AnalyticsCharts.lua`) |
| `Panel(frame, { nav = true })` | OptionsNav's rail recolor (`PANE_FILL` four components, `PANE_BORDER` three) |
| `Card(frame)` | LootHistory's KPI card (`modules/Analytics.lua`) |
| `MenuFrame(frame)` | Widgets' shared popup menu (`EnsureMenu`: the WHITE8X8 table with no insets) |
| `Divider(texture)` | Core.ApplySkin's divider |
| `Strip(texture, opts)` | `W.TestStrip`'s fill (`STRIP_FILL`, test and sim) |
| `Cover(texture, { text })` | OptionsCombat's dim and its line |
| `TitleBar(bar)` | the title color only (Ka0s Default sets no title fill and no alignment) |
| `Footer(frame)`, `Tooltip(frame)` | nothing (their tokens are nil in Ka0s Default) |
| `Button(btn)` | LootHistory's flat button (`modules/BrowserFilterBar.lua`), its gold-on-hover label |
| `EditBox(eb)` | `W.SearchBox`, run for real: its backdrop, fill and edge |
| `Dropdown(dd)` | `W.Dropdown`, run for real: its backdrop, fill, edge and the arrow's gray |
| `CloseButton(btn, { own = true })` | `Core.MakeCloseButton`'s glyph tint and its hover pair |
| `NavItem(item, opts)` | OptionsNav's entry (the selection tint, the white / gold label) |
| `Drawer(head, opts)` | OptionsDrawer's header (label, summary, then the edge set) |
| `ScrollBar(sb, { state })` | OptionsScroll's `THUMB_ON` / `THUMB_OFF` |
| `ScrollBar(bar, { track, thumb })` | DebugLog's console bar |

The library code itself is not routed through the primitives at this version: that is the next
items of the run (Core and Widgets, the settings chrome, the tool windows), each of which keeps its
owner-less and Ka0s Default trace pinned when it moves.

### Primitive reference

No primitive draws a `LibKa0s-Media-1.0` icon: every texture is `WHITE8X8` or in-client art, so a
host owes no new `LibKa0s icons:` declaration for any of them. The in-client art they draw is the
skins' own (`win.bgTexture`, `tab.texture`, `tab.onTexture`, `scroll.thumbTexture`,
`check.texture`, `check.markTexture`, the `nine:` border keys) plus `PageButton`'s arrow,
`Interface\ChatFrame\ChatFrameExpandArrow`.

**The window family** (`SkinPaint.lua`, `SkinPaintExtras.lua`):

| Primitive | Paints | Tokens |
|---|---|---|
| `Shell(frame, opts)` | A window. On a backdrop frame, `Core.ApplySkin` with the skin's table (backdrop, inner rule, `frame.title`'s color, `frame.divider`'s), an inner rule cleared when the skin has none, a non-flat edge on the holder; on any frame the window gradient, the tiled art, the top bar (unless `opts.noTopBar`) and the bottom bar (`opts.bottomBar`, true or a height), and the title font on `frame.title`. A frame with no backdrop gets its fill as a region and its edge on the holder. `opts.noBorder` draws no edge and no inner rule. | `win.*`, `title.bg` / `bgTop` / `bgBottom`, `title.text`, `title.height`, `divider`, `foot.bg`, `font.title` |
| `Panel(frame, opts)` | A flat panel; `opts.inset` paints it as an inset, `opts.noBg` / `opts.noBorder` leave out a half, `opts.nav` recolors the backdrop the frame already wears. | `panel.bg`, `panel.border`; `nav.bg`, `nav.border` |
| `Inset(frame, opts)` | A recessed area. | `input.bg`, `input.border`, `input.borderStyle`, `input.borderSize` |
| `FadeRegions(frame, ...)` | Fades every texture region of the frame (and of each further frame) that no primitive made. Ka0s Default fades nothing and puts them back. | none |
| `FadeNineSlice(frame)` | Fades `frame.NineSlice`'s nine pieces. Ka0s Default puts them back. | none |
| `TitleBar(bar, opts)` | A title bar: the fill (the bar's backdrop, or the fill holder), its text (`opts.text`, else `bar.title` / `bar.text`) in the title color, font and alignment (the prior alignment put back when the skin sets none). | `title.bg` / `bgTop` / `bgBottom`, `title.text`, `title.align`, `font.title` |
| `Divider(target, opts)` | A texture colored in place, or a line filling a frame on its holder; `opts.token` names another color (`section.rule`, `tab.rule`). | `divider` |
| `Footer(frame, opts)` | A footer band; its text (`opts.text`, else `frame.text`) muted. | `foot.bg`, `text.muted` |
| `Card(frame, opts)` | A card: `opts.title` in the heading color, `opts.text` in the body color. | `card.bg`, `card.border`, `text.heading`, `text.body` |
| `Strip(target, opts)` | The test or simulation strip's wash (`opts.kind` `"test"` / `"sim"`), a texture in place or the fill holder. The meaning colors are the library's; a skin changes only their legibility. | `strip.test`, `strip.sim` |
| `Cover(target, opts)` | The combat cover's dim, and `opts.text`. | `cover.dim`, `cover.text` |
| `Tooltip(frame)` | A **library-owned** tooltip's backdrop, recolored; never GameTooltip. | `tooltip.bg`, `tooltip.border` |
| `MenuFrame(frame, opts)` | A popup menu's flat backdrop (no insets); `opts.alt` the alternate edge; `opts.popup` recolors the backdrop the frame already wears. | `menu.bg`, `menu.border`, `menu.borderAlt`, `menu.borderStyle`, `menu.borderSize`; `popup.bg`, `popup.border` |
| `Text(fs, role)` | A text role's color and font: `body`, `muted`, `heading`, `headingAlt`, `accent`, `disabled`, `link`, `linkHot`, `title` (the title font for `title` and the headings, the body font otherwise). | `text.*`, `title.text`, `font.*` |
| `Font(fs, r, g, b)` | The body font, and the color when given. | `font.body`, `font.bodySize`, `font.outline`, `font.shadow` |
| `White(fs)` | The body font and the body color (EllesmereUI's `White`, legible in a light skin). | `font.body`, `text.body` |

**The controls** (`SkinPaintControls.lua`):

| Primitive | Paints | Tokens |
|---|---|---|
| `Button(btn, keepKeys \| opts)` | A push button: its stock art faded, the flat-control box, the label (the button's font string, else `btn.text` / `btn.Text`) in the text color and body font, the hover color under the pointer, `btn.icon` tinted. `keepKeys == true` or `opts.keep` keeps the stock art and paints only the label; `opts.primary` reads `btnPrimary.*`. | `btn.*` / `btnPrimary.*` (`bg`, `bgTop`, `bgBottom`, `border`, `borderStyle`, `borderSize`, `text`, `hover`, `icon`) |
| `WhiteButtonLabel(btn)` | The label in the button text color and body font. | `btn.text` |
| `StateButtonLabel(btn, on)` | The label in the accent while on, muted otherwise. | `text.accent`, `text.muted` |
| `EditBox(eb, opts)` | A text input: the template's pieces faded, the flat-control box, the typed text and the hint (`opts.placeholder`, else `eb.hint`), the focus edge while it has the keys. `opts.padInput` sets 6px insets; `opts.noBorder` draws no edge and hooks no focus. | `input.*` |
| `Checkbox(cb, opts)` | A check button: its stock art faded (the stock check too unless `opts.stockCheck`), a box `opts.borderInset` inside it, an edge on the holder, a mark three pixels inside the box shown while checked (following `OnClick`, `OnShow` and `SetChecked`), and with `opts.hover` a highlight. | `check.*`, `menu.hover` |
| `Dropdown(dd, opts)` | A dropdown button: the template's pieces faded, the flat-control box, the arrow (`dd.arrow` / `dd.Arrow`), the label (`dd.text` / `dd.Text`). | `input.*`, `icon.tint` |
| `ScrollBar(sb, opts)` | A scroll bar: `opts.track` / `opts.thumb` (textures the caller drew) filled; `opts.state` `"on"` / `"off"` tints the bar's own thumb; otherwise, away from Ka0s Default, the bar's own thumb takes the knob art or the thumb color over a track region. | `scroll.*` |
| `Slider(slider, opts)` | A slider's track (a region, its edge on the holder), fill (`opts.fill`) and thumb (`opts.thumb`, else its own). Every slider token is nil in Ka0s Default. | `slider.*` |
| `Tab(tab, opts)` | A tab: its stock art (and `opts.stock`) faded, the backing (`opts.fill`, else a region: the tab art, else the color and gradient), an underline on the holder while selected, the label (`opts.text`, else its own). `opts.selected` is the first state. | `tab.*` |
| `SetTabSelection(tab, selected)` | Moves a painted tab's state and repaints it; the state lives in the tab's record, so a skin switch keeps it. | as `Tab` |
| `CloseButton(btn, opts)` | A close control: its art (`btn.icon`, a texture, or `btn.glyph`) at rest and under the pointer. A stock close button is left stock on Ka0s Default; in a skin its art is faded and an ASCII `x` drawn. `opts.own` SetScripts the hover pair. | `close.rest`, `close.hot` |
| `PageButton(btn, dir)` | A paging arrow (`prev`, `next`, `up`, `down`, `left`, `right`): the button look and the in-client arrow, turned. | `btn.*` |
| `SquareIcon(frame, opts)` | An icon button: `opts.crop` trims the icon art (`opts.icon`, else `frame.icon` / `frame.Icon`) to .08-.92; an edge on the holder. | `icon.border` |
| `IconBorder(frame, opts)` | An icon edge, `opts.size` pixels, on the holder. | `icon.border` |
| `SortHeaderBar(bar, opts)` | A list header: the fill, each of `opts.texts`, each of `opts.arrows`. | `list.header.bg`, `list.header.text`, `icon.tint` |
| `ApplyBarFill(target)` | The accent on a status bar (`SetStatusBarColor`) or a texture. | `text.accent` |
| `NavItem(item, opts)` | A nav-rail entry: `opts.label` selected or not, `opts.sel` (the selection texture), a selection bar on the holder while `opts.selected`. | `nav.text`, `nav.selText`, `nav.selBg`, `nav.selBar` |
| `Drawer(head, opts)` | A settings drawer: `opts.label` and `opts.summary` set or not (`opts.set`), then the edge set (`opts.edges`, OptionsDrawer's `{ fill, left, right, bottom, top }`) open or not (`opts.open`), and the box's (`opts.box`). A header with no edge set is boxed on its holders (the fill under its text, the edge over it). | `drawer.*` |
| `ListRow(row, state)` | A list row's washes on its fill holder, under the row's text (stripe, hover, selection), and the selection outline on its holder. `state` is a table or `"stripe"`, `"hover"`, `"selected"`, `"normal"`. | `list.stripe`, `list.hover`, `list.sel`, `list.selOutline` |

**The getters** (record nothing):

| Getter | Answers |
|---|---|
| `GetAccentColor()` | r, g, b, a of `text.accent` |
| `GetPanelColor()` | r, g, b, a of `win.bg` |
| `GetFont()` | the body face's path, or the client's `STANDARD_TEXT_FONT` when the skin names none |
| `GlowColor()` | r, g, b, a of `glow.color`, or nil (the host's own glow color stands) |
| `ChartStyle()` | a fresh table of the `chart.*` tokens by short name (`axis`, `axisAlt`, `grid`, `crosshair`, `marker`, `line`, `bar`, `track`, `total`, `other`, `otherLine`, `series`); the colors are shared |
| `BarStyle()` | a fresh table: `texture` (the LSM path or nil), `textureKey`, `gloss`, `bg`, `border`, `borderStyle`, `borderSize`, `font` (path or nil), `fontKey`, `fontSize`, `outline`, `iconBorder` |

### WoW Default and WoW Midnight on the primitives

The choices (*Blizzard art and the per-skin choices*, below) are drawn as follows. WoW
Default's window is `Shell`'s nine-slice edge, `Blizzard Dialog` at 32 outset by 8 on the holder,
the backdrop's own edge clear, over a `#1E1C19` backdrop fill with `UI-DialogBox-Background-Dark`
tiled in a band above it; its buttons are `Button`'s red gradient under a 2px `bevelOut` gold edge on
the holder; its tabs are `Tab`'s `UI-OptionsFrame-ActiveTab` / `-InActiveTab` art; its scroll thumb
`ScrollBar`'s `UI-ScrollBar-Knob`; its checkbox `Checkbox`'s `UI-CheckBox-Up` box and
`UI-CheckBox-Check` mark; its inputs, checkboxes and nav rail a 2px `bevelIn` edge. WoW Midnight
draws no art: `Shell`'s window and title gradients, its 2px flat edges, `Button`'s gradients.

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
| `handle.edge` | `#4DB8FF .6` | `#8E1B10 .6` | `#B69CFF .6` | `#FFE600 .6` | `#FF7A33 .6` | `#FFD100 .6` | `#B48CFF .6` | `#C9A07A .6` |
| `handle.rest` | `#9B9BA4` | `#6A5233` | `#C9CFDB` | `#E0E0E0` | `#C7A993` | `#B8B8B8` | `#B4AFC8` | `#A39E97` |
| `list.dropLine` | `#4DB8FF .9` | `#8E1B10 .9` | `#B69CFF .9` | `#FFE600 .9` | `#FF7A33 .9` | `#FFD100 .9` | `#B48CFF .9` | `#C9A07A .9` |
| `list.ghostBg` | `#121214` | `#E9DDBC` | `#121622 .6` | `#000000` | `#1A0E0A .97` | `#1E1C19` | `#131527` | `#1D1A17` |
| `list.box` | `#E8E8EC .06` | `#2A1C0C .06` | `#F2F4F8 .06` | `#FFFFFF .06` | `#F4E7DC .06` | `#FFFFFF .06` | `#F2EEF8 .06` | `#FFFFFF .06` |
| `list.boxDim` | `#E8E8EC .03` | `#2A1C0C .03` | `#F2F4F8 .03` | `#FFFFFF .03` | `#F4E7DC .03` | `#FFFFFF .03` | `#F2EEF8 .03` | `#FFFFFF .03` |
| `list.boxEdge` | `#E8E8EC .12` | `#2A1C0C .12` | `#F2F4F8 .12` | `#FFFFFF .12` | `#F4E7DC .12` | `#FFFFFF .12` | `#F2EEF8 .12` | `#FFFFFF .12` |
| `list.boxEdgeDim` | `#E8E8EC .06` | `#2A1C0C .06` | `#F2F4F8 .06` | `#FFFFFF .06` | `#F4E7DC .06` | `#FFFFFF .06` | `#F2EEF8 .06` | `#FFFFFF .06` |

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

## The EllesmereUI provider

`SkinEUI.lua` (minor 1), paired on the shell's minor (`__euiMinor` / `__euiShellMinor`). With an
owner's source set to `eui`, EllesmereUI's own skinning facade paints the vocabulary names it has, in
the player's EllesmereUI theme, and the Ka0s extras paint from EllesmereUI's accent, panel color and
font (skinning-§5 of the Ka0s WoW Addon Standard, v2.89.0). EllesmereUI's API is read from its
`SKINNING_API.md` (API version 3): its names and token model are mirrored, and nothing of its code
or media is copied, since its license reserves every right.

### Registration

`RegisterOwner` registers the owner with `EllesmereUI.RegisterSkin(owner, cb)`, presence-guarded.
That lists the addon in EllesmereUI's Third-Party Addons list whatever the owner's choice, which is
how EllesmereUI asks to be used ("registering is free"). `cb` is a trampoline,
`function(S) LibStub("LibKa0s-Skin-1.0"):__OnEUIFacade(owner, S) end`, so the copy of this major
that is live when EllesmereUI calls back (once per session, at PLAYER_LOGIN or at once when
registered later) receives the facade, even when a newer minor loaded after the registration. The
facade is kept in `euiFacade[owner]`. An owner registered before the EllesmereUI global exists is
retried, with every other owner not yet registered, at each `RegisterOwner`, on
`ADDON_LOADED("EllesmereUI")` and at `PLAYER_LOGIN`, on one private frame made at the first
`RegisterOwner` (no frame exists before a host adopts) and registered through Core's
`SafeRegisterEvent`, resolved at call time (no Core floor rises). The frame lets go of both events at
login. With a Core that lacks `SafeRegisterEvent` no frame is made: owners register only at each
`RegisterOwner`, so an owner registered before the EllesmereUI global exists is not retried unless
another owner registers later.

### The gate

`Skin:GetEUIStatus(owner)` answers `{ ok, painted, refused, conditions }`. `conditions` lists four,
in display order, each `{ key, ok, label, hint }`:

| Key | Holds when | Hint |
|---|---|---|
| `eui` | `EllesmereUI.RegisterSkin` is a function and `C_AddOns.IsAddOnLoaded("EllesmereUIBlizzardSkin")` (the child holds the dispatcher; without it RegisterSkin only queues) | Install and enable EllesmereUI, including EllesmereUI Blizzard Skin. |
| `master` | the first holds and `EllesmereUIDB.thirdPartySkinsOff` is not truthy | In EllesmereUI, turn on Skin Third-Party Addons under Blizzard Window Skins. |
| `own` | the first holds and `EllesmereUIDB.thirdPartySkinAddons[owner]` is not `false` (nil is on) | In EllesmereUI's Third-Party Addons list, turn on `<label>`. |
| `facade` | EllesmereUI handed the owner its facade this session | Reload the UI. |

`ok` is true only when all four hold and nothing was refused (below): the Appearance tab offers the
EllesmereUI source only then. `painted` is `euiPainted[owner]`; `refused` the latched reason
EllesmereUI does not paint the owner, or nil. The strings are US English, keyed so a
caller translates by `key` (the strings themselves are file-local). Every read is made at call time, nil-guarded, and nothing is written.

**The two `EllesmereUIDB` reads are library-stack-§6's skinning exception** (WowAddonStandards
v2.89.0): `LibKa0s/SkinEUI.lua`, and no other file, MAY read `EllesmereUIDB.thirdPartySkinsOff` and
`EllesmereUIDB.thirdPartySkinAddons[<owner>]`, read-only, at call time, nil-guarded, never written,
because EllesmereUI publishes no query for either switch. An addon reaches the answer through
`GetEUIStatus` and never reads `EllesmereUIDB` itself (anti-pattern #29). `tests/test_skin_eui.lua`
fails when the name appears in any other payload file.

### Entering EllesmereUI

One internal step, `__EnterEUI(owner)`, serves the live switch (`SetChoice` onto `eui`) and the
facade arriving after the owner chose `eui` (a profile on `eui` at login). It runs when the owner is
on `eui`, the facade is held and of the right shape, nothing was refused and the gate's first three
conditions hold. It gives back the Ka0s paint of every recorded frame whose record names one of
EllesmereUI's primitives (holders hidden, faded art and colors restored), latches
`euiPainted[owner]` for the session, replays the owner's records (EllesmereUI's names go to its
facade, the Ka0s extras repaint from its getters) and fires the owner's `OnLooksChanged`.

- **Before EllesmereUI paints**, an owner on `eui` wears its own Ka0s skin: the live fallback while
  the gate is closed or the facade has not arrived.
- **After it paints**, nothing falls back live. Leaving `eui` asks for a reload (*Changing the skin*,
  rule 3); so does a gate condition failing, noticed when `GetEUIStatus` is read or when `SetChoice`
  moves the owner between skins while on `eui`. Frames built later keep going to EllesmereUI.
- **Calls while it paints.** Every call of an EllesmereUI name for the owner is recorded on the
  target (so a later repaint replays it) and handed to the facade under pcall. A Ka0s extra
  (`TitleBar`, `Divider`, `ListRow`, `Card`, `Strip`, ...) never reaches EllesmereUI: it paints with
  the library's technique from the owner's token table (`__Tokens`), which answers Ka0s Default with these over it:

| From | Tokens |
|---|---|
| `S.GetAccentColor()` | `text.accent`, `tab.onLine`, `nav.selBar`, `check.mark`, `slider.fill`, `input.focus`, `list.selOutline` |
| `S.GetPanelColor()` | `win.bg`, `panel.bg`, `menu.bg`, `popup.bg`, `drawer.bg`, `card.bg`; and `win.bgTop`, `win.bgBottom`, `win.bgTexture`, `title.bgTop`, `title.bgBottom` cleared (flat) |
| `S.GetFont()` | `font.body`, `font.title` |

  The table is cached per owner and rebuilt when EllesmereUI's looks change: the provider hooks the
  facade's `OnLooksChanged` once per owner, and a live accent or theme change repaints the owner's
  records and fires its `OnLooksChanged`. `S.Token` and `S.Color` read the same table, so a host's
  custom drawing follows EllesmereUI too.
- **Ka0s-only options are stripped.** EllesmereUI sees only the keys it reads: `Shell`'s `noBorder`,
  `noTopBar`, `bottomBar`; `Panel`'s `inset`, `noBorder`, `noBg`; `EditBox`'s `padInput`,
  `noBorder`; `Checkbox`'s `stockCheck`; and `Button`'s array of region names (its `keepKeys`). Any
  other options table (`primary`, `role`, ...) is dropped. The record keeps the caller's arguments
  whole.
- **Pooled and shared objects are never handed to EllesmereUI.** An AceGUI widget or its frame
  (AceGUI sets `frame.obj`), a region of such a frame, and any `__MarkShared` target or a region of one
  keep the library's technique, colored from EllesmereUI's getters, because EllesmereUI's paint is
  one-way and a pooled frame would carry it into another addon. Under `eui`, a stock target there is
  painted (Ka0s Default's stock rule does not apply while EllesmereUI paints the owner).

### Fail closed

A facade missing a primitive the provider needs (every EllesmereUI name but `SetTabSelection`, which
arrived in its API version 2, and the three getters) is refused the moment it arrives, whatever the
owner's source, so `GetEUIStatus` never offers a choice the provider would refuse; nothing is painted: the
reason is latched in `euiRefused[owner]`, written once through the owner's `opts.log`, and the owner
stays on its Ka0s skin. A primitive that raises latches the same way; EllesmereUI's paint so far
stays (only a reload removes it), and from then on the owner's EllesmereUI names take the library's
technique. A facade without `SetTabSelection` leaves EllesmereUI's own tab selection showing.

### For a host

Register with `opts.log` (the debug console's writer), list `EllesmereUI` under `## OptionalDeps`
(skinning-§5), raise the reload popup from `SetChoice`'s `reload` or from `OnReloadRequest`, and
read the choice's availability from `GetEUIStatus`. A host never calls `EllesmereUI.RegisterSkin`
for itself once it adopts.

## What is not here

- **No routing yet.** The library's own windows, widgets and settings chrome still paint with
  their constants; they take an owner and route through the primitives in later files of this
  release's run.
- **No AceGUI.** Skinning the AceGUI rows a settings page acquires, and restoring them on release,
  is a later file of this major (`SkinAce.lua`).
- **No SavedVariables.** The host stores `{ source, skin }` in its own profile; `SetChoice` never
  writes it.
- **No migration stamp.** `ResetToSkin` is a helper; the step that runs it is each addon's.

## Vendoring

Whole-folder, like every major. `Skin.lua` returns before `NewLibrary` when Core is missing or below
minor 1, and `SkinDefs.lua` then returns on its own `LibStub("LibKa0s-Skin-1.0", true)` lookup, so
the major is absent rather than half-wired. Without `SkinDefs.lua` the engine still loads and every
token resolves to nil, and every primitive paints only what it has a token for (`Shell` is still
`Core.ApplySkin(frame)`). Without `SkinPaint.lua` neither `SkinPaintExtras.lua` nor
`SkinPaintControls.lua` attaches, and every vocabulary entry answers nil. Without `SkinEUI.lua`
`eui` is a stored choice on the owner's Ka0s skin and nothing is registered with EllesmereUI. The engine's state is written `lib.x = lib.x or {}`, so a newer copy that wins
the LibStub race later keeps every owner, record and facade; the resolve cache alone is rebuilt.
