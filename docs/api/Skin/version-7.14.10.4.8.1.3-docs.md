# `LibKa0s-Skin-1.0` — version 7.14.10.4.8.1.3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Skin surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Skin-1.0` |
| Files and minors | `Skin.lua` minor **7** · `SkinDefs.lua` minor **14** · `SkinPaint.lua` minor **10** · `SkinPaintExtras.lua` minor **4** · `SkinPaintControls.lua` minor **8** · `SkinEUI.lua` minor **1** · `SkinAce.lua` minor **3** |
| Shipped in | unreleased (v1.80.0) |
| Status | **Current** |
| Supersedes | [version 6.14.10.4.8.1.3](./version-6.14.10.4.8.1.3-docs.md) (shipped in v1.79.0) — the same surface without owner tokens (`RegisterOwner`'s `opts.tokens`) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` ≥ 1 (`NEEDS_CORE = 1`). One Core member is used, optionally: `SkinEUI.lua` resolves `SafeRegisterEvent` at call time; with a Core that lacks it no `ADDON_LOADED` / `PLAYER_LOGIN` retry frame is made, and owners register with EllesmereUI only at `RegisterOwner` |
| Confirm in-game | `LibStub("LibKa0s-Skin-1.0").MODULES` → `{ Skin = 7, SkinDefs = 14, SkinPaint = 10, SkinPaintExtras = 4, SkinPaintControls = 8, SkinEUI = 1, SkinAce = 3 }` |

## What this major is

**The skin engine.** Every Ka0s window, panel, dialog and settings page is drawn from constants
today: `Core.SKIN`, Widgets' file-local `SKIN`, the Options palettes, and about ninety literals in
LootHistory alone. A **skin** turns those constants into data, a token table, and a host picks one
**per addon** (Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/`, the owner's rulings R1 to R4).
This version is the engine, the nine skins, the paint primitives and the EllesmereUI provider:
**Ka0s Default**, whose tokens are today's constants, so an addon that never picks another skin
keeps the library's own look (since SkinPaint minor 6 it is painted like any other skin, stock
controls included: *Ka0s Default is a skin like the others*, below), eight more translated from the owner's mockups (*The eight
skins*, below), the primitives the facade calls (*The primitives*, below), and the `eui` source,
which hands the vocabulary to EllesmereUI's own skinning facade (*The EllesmereUI provider*, below),
and the AceGUI rows a settings page acquires, painted for its owner and given back to AceGUI's shared
pool stock (*AceGUI rows*, below).

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
a stored choice whose tokens fall back to the owner's Ka0s skin. The AceGUI rows are `SkinAce.lua`'s;
without it a settings page's widgets stay stock AceGUI whatever its owner wears.

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework; the
primitives also read LibSharedMedia-3.0 at call time when it is loaded (faces, border art), and
`Shell` calls `Core.ApplySkin`. `SkinDefs.lua`, the three primitive files and `SkinEUI.lua` are
paired on the shell's minor (`__defsMinor` / `__defsShellMinor`, `__paintMinor` / `__paintShellMinor`,
`__extrasMinor` / `__extrasShellMinor`, `__controlsMinor` / `__controlsShellMinor`, `__euiMinor` /
`__euiShellMinor`, and `SkinAce.lua`'s `__aceMinor` / `__aceShellMinor`), the Widgets
and Sim idiom, so a skin table or a primitive from one vendored copy never attaches to an engine
from another. A payload without it
still runs the engine: no skin is registered and every token resolves to nil.

## Members

| Member | Answers | What it does |
|---|---|---|
| `Skin:RegisterOwner(owner, opts)` | the owner's facade | Registers `owner` at the consumer's file load. `opts.get()` answers `{ source, skin }` (or two values) from the host's profile; `opts.set(source, skin, ignore, media)` writes it (the Appearance tab's copy to every Ka0s addon calls it, through `WriteChoice`; `ignore`, since Skin minor 5, is `{ panel, fonts }` or nil, `media`, since Skin minor 6, `{ font, texture }` or nil, and a setter written before either ignores it); `opts.label` names the addon; `opts.log(line)`, optional, takes the one line the EllesmereUI provider writes when it refuses a facade or stops painting (a host hands its debug console's writer). The choice is read **once**, here; an unknown source is cleaned to `"ka0s"`, a non-string skin to `"ka0s"`. A second call updates the hooks and keeps the applied choice. `opts.tokens`, optional (Skin minor 7), is the owner's own tokens (*Owner tokens*, below): a second call adds its tokens and replaces a name it repeats. With `SkinEUI.lua` loaded it also registers the owner with EllesmereUI (*The EllesmereUI provider*). |
| `Skin:IsOwner(name)` | boolean | True only after `RegisterOwner`. Every factory that takes an owner paints today's way, verbatim, for a name that is not one. |
| `Skin:Owners()` | sorted array | The registered owners. |
| `Skin:OwnerLabel(owner)` | string or nil | The label the owner registered with (`opts.label`, else its folder name); nil for a name that never called `RegisterOwner`. What the Appearance tab's copy confirmation names each addon by (Skin minor 4). |
| `Skin:GetIgnore(owner)` | ignorePanel, ignoreFonts | The owner's two exceptions, the Appearance tab's *Ignore settings panel* and *Ignore fonts* (Skin minor 5). `false, false` for an unregistered owner. |
| `Skin:SetIgnore(owner, panel, fonts)` | changed, reload | Sets the exceptions; nil keeps that half, any value but `true` is false. A change repaints every frame recorded for the owner and fires its `OnLooksChanged` listeners: with fonts ignored, `P.font` hands every string back its own face, size and shadow (the skin still colors it), and with the panel ignored the Options chrome (`LibKa0s-Options-1.0`'s `__chromeSkin`) and the AceGUI rows (`PaintAce`) paint nothing for the owner, and the chrome they painted is handed back as it was, live. `reload` is always false (kept so a two-value read holds). Never writes the host's profile (Skin minor 5). |
| `Skin:WriteChoice(owner, source, skin, ignore, media)` | boolean | Writes `(source, skin)`, cleaned as `RegisterOwner` cleans a read, into the owner's profile through the `opts.set` it registered, under pcall: the write of the Appearance tab's copy to every Ka0s addon (`LibKa0s-Options-1.0`'s `OptionsAppearance.lua`), which reaches each addon only through its own write seam. `ignore`, optional (Skin minor 5), `{ panel, fonts }`, reaches the setter as its third argument, each half `true` or false; without it the setter gets nil. `media`, optional (Skin minor 6), `{ font = key|false, texture = key|false }`, reaches the setter as its fourth argument, each half a non-empty LSM key or `false` for "the skin's own" (a missing half, an empty string or a non-string is `false`); without it the setter gets nil, and it never moves the applied overrides (`SetOverride` does). **Never moves the applied choice**: the tab calls `SetChoice` first (the live repaint), then this. Answers true when a setter ran and did not raise; false for an unregistered owner, one with no setter, or a raise, which goes to the client's error handler (Skin minor 4). |
| `Skin:GetOverride(owner)` | font, texture | The owner's overrides, the Appearance tab's *Font and texture* (Skin minor 6, LibKa0s#63): each an LSM key (a `font` key, a `statusbar` key), or nil for "the skin's own". `nil, nil` for an unregistered owner. |
| `Skin:SetOverride(owner, font, texture)` | changed | Sets the overrides; nil keeps that half, `false`, `""` or `FROM_SKIN` (`"@skin"`) clears it. Idempotent: the same pair answers false and does nothing. A font override replaces `font.body`, `font.title` and `hud.font` in every token read (`Token`, `Color`, the facade, every primitive: `__Tokens` lays the overrides over the owner's table); `font.mono` stays the skin's (the console and the tables need a monospace face) and so does every size. A texture override replaces `bar.texture` (`BarStyle`, and every bar drawn through it). *Ignore fonts* wins: with it on, `P.font` gives every string its own face and the font override is kept with no effect. A change repaints every frame recorded for the owner and fires its `OnLooksChanged` listeners, unless a reload is pending (then it is stored and the reload applies it). Never writes the host's profile (`WriteChoice`'s `media` does). A host applies its stored overrides with one `SetOverride` after `RegisterOwner`. `ResolveSkin` stays override-free. **An override that does not resolve** (a key no loaded LibSharedMedia pack registers, and not a file path) is stored, and `GetOverride` answers it, but every token read keeps the skin's own face or texture, so the strings never drop to the client's stock font nor the bars to flat. The first time an override is checked against LibSharedMedia the engine subscribes once to its `LibSharedMedia_Registered` callback; a key registered later repaints and notifies every owner whose override names it (unless a reload is pending). |
| `Skin:For(owner)` | facade `S` | The owner's facade, `lib.facades[owner]`: one table per owner, kept for the session and across minors. Does not register the owner; an unregistered owner's facade reads Ka0s Default. |
| `Skin:GetChoice(owner)` | source, skin | The applied choice. An unregistered owner answers `"ka0s", "ka0s"`. |
| `Skin:SetChoice(owner, source, skin)` | changed, reload | See *Changing the skin* below. `nil` keeps that half. Never writes the host's profile. |
| `Skin:PendingReload(owner)` | boolean | True once the owner needs a reload: it left `eui`, or a gate condition failed, after EllesmereUI painted it this session. |
| `Skin:OnReloadRequest(owner, fn)` | fn | Calls `fn(owner)` once, when `PendingReload` first turns true: on the switch `SetChoice` answers `reload = true` for, or when the gate closes after EllesmereUI painted the owner (read through `GetEUIStatus`). Under pcall; the same function twice is one entry. A caller raises its reload popup from this **or** from `SetChoice`'s answer, not both. |
| `Skin:OnLooksChanged(owner, fn)` | fn | Calls `fn(source, skin)` after each change of the owner's skin, under pcall. The same function twice is one entry. |
| `Skin:Token(owner, name)` | value | The owner's resolved token: from its skin resolved (`ResolveSkin`), or, while EllesmereUI paints the owner, from Ka0s Default with EllesmereUI's accent, panel color and font over it (*The EllesmereUI provider*); with the owner's font and texture overrides over either (Skin minor 6, `SetOverride`), and the owner's own tokens over that (Skin minor 7, *Owner tokens*). An unregistered owner reads Ka0s Default. A color is `{ r, g, b, a }`, a shared table: never write to it. nil for a token the skin leaves alone. |
| `Skin:Color(owner, name)` | r, g, b, a | A color token's components, alpha 1 when it has three; nil otherwise. |
| `Skin:Resolve(owner, kind, value, fromSkin)` | value | `value`, or the owner's token `kind` when `value` is `FROM_SKIN` or `fromSkin` is true. |
| `Skin.ResetToSkin(profile, keys)` | count | Puts each listed key back on the skin (R3). A key holding a color (a table), or one with a `<key>FromSkin` companion beside it (an `OptionsCompose` `fromSkin` picker), keeps its value and gets the companion set to `true` (Skin minor 3); a bool key (a companion named directly) is set to `true`; any other key takes `FROM_SKIN`. Keys may be dotted paths (`"font.face"`); a path through a missing table is skipped and no table is created. The colon form works too. |
| `Skin.IsFromSkin(value)` | boolean | `value == FROM_SKIN`. |
| `Skin:RegisterSkin(def)` | def | Registers `{ key, label, desc, swatches = { 4 hex }, tokens }`. `key` and `tokens` are required; `label` defaults to the key, `desc` to `""`, `swatches` to `{}`. Re-registering a key replaces it in place (a newer `SkinDefs.lua`). Empties the resolve cache. |
| `Skin:GetSkin(key)` | def or nil | The registered definition. |
| `Skin:Skins()` | array | Every definition in registration order, Ka0s Default first: the source of a skin picker's labels, descriptions and swatches. A caller that translates reads `label` and `desc` from here and overrides them through its own strings table. |
| `Skin:ResolveSkin(key)` | token table | Ka0s Default's tokens with the skin's own over them, cached. An unregistered key resolves as Ka0s Default. Shared: never write to it. Never carries an owner's overrides (Skin minor 6): a skin picker reads every skin's own faces through it. |
| `Skin:Track(owner, frame, prim, ...)` | record | For the primitives: records that `prim` painted `frame` for `owner` with these arguments. One record per frame; a frame painted for a second owner (a pooled frame) moves to it; repeating a primitive replaces its arguments and keeps its replay position. The record's `regions` table is the primitive's own. |
| `Skin:Untrack(frame)` | — | Forgets a frame (a pooled widget handed back). |
| `Skin:Repaint(owner)` | calls | Replays every primitive recorded for the owner's frames, each frame once: frames in the order they were first painted for the owner (a frame that moved to it counts from the move), and each frame's primitives in their first-paint order, each call under pcall; `lib.__repainting` is true while it runs. `SetChoice` calls it. |
| `FROM_SKIN` | `"@skin"` | The stored value meaning "take this setting from the skin". |
| `DEFAULT` | `"ka0s"` | The skin every owner wears until it picks another, and the one an unknown key resolves as. |
| `SOURCES` | `{ "ka0s", "eui" }` | The two skin sources. |
| `SCHEMA` | array | Every token, as `{ name, kind, nilable, group }` (the reference below). Read-only. |
| `VOCAB` | array | The names the facade carries as trampolines. |
| `Skin:PaintAce(owner, widget)` | boolean | `SkinAce.lua`. Paints an AceGUI widget a host acquired for `owner`'s page and wraps its release so the widget goes back to the pool stock; see *AceGUI rows*. Answers false, painting nothing, for an owner that is not registered, an owner on Ka0s Default, a type with no painter, or a widget another skinning addon skinned. |
| `Skin:PaintAceTree(owner, container)` | count | `SkinAce.lua`. `PaintAce` over `container` and every widget under it (`children`, depth first); answers how many it painted. |
| `Skin:OnRelease(widget, fn)` | fn | `SkinAce.lua`. Chains `fn(widget)` onto the widget's own `OnRelease` for its next release: the previous `OnRelease` is put back first, `fn` runs under pcall (a failure is logged once) and the previous one always runs after it. The way a host's release work and the skin's restore coexist, since AceGUI keeps one callback per event name (options-ui-§19). |
| `Skin:GetEUIStatus(owner)` | status | `SkinEUI.lua`. Whether the owner may choose `eui`, and why not: `{ ok, painted, refused, conditions }`; see *The EllesmereUI provider*. |
| `skins`, `owners`, `painted`, `byOwner`, `facades`, `prim`, `euiFacade`, `euiRegistered`, `euiPainted`, `euiRefused`, `shared` | tables | The engine's state and the provider's (`SkinEUI.lua` writes the `eui*` tables and `shared`; `Skin.lua` declares `euiPainted` and reads it), named so the major's other files and a newer minor can reach it. **Not contract**, and neither are the `__`-prefixed members (`__Tokens`, the owner's whole token table, which the primitives, `Token` and `Color` read; `__BaseTokens`, the same table without the owner's overrides or owner tokens, which the Skin tab's "Skin's own" entries name; `__MediaRegistered(kind, key)`, the LibSharedMedia callback's repaint; `__MarkShared(target)`, which the library's own files use to mark a pooled or shared object, weak-keyed, so it is never handed to EllesmereUI): read the skin through the members above and the facade. `painted`, each `byOwner[owner]` and `shared` are weak-keyed. |

### The facade

`S = Skin:For(owner)` carries:

- **The painting vocabulary** (`VOCAB`), each a late-bound trampoline: `S.Button(...)` looks
  `lib.prim.Button` up **at call time** and calls it as `(owner, ...)`. EllesmereUI's names first
  (`Shell`, `Panel`, `Inset`, `FadeRegions`, `FadeNineSlice`, `Button`, `WhiteButtonLabel`,
  `StateButtonLabel`, `EditBox`, `Checkbox`, `Dropdown`, `ScrollBar`, `Tab`, `SetTabSelection`,
  `CloseButton`, `PageButton`, `SquareIcon`, `SortHeaderBar`, `Font`, `White`, `ApplyBarFill`,
  `GetAccentColor`, `GetPanelColor`, `GetFont`), then the Ka0s extras (`TitleBar`, `Divider`,
  `Footer`, `Card`, `Slider`, `NavItem`, `Drawer`, `ListRow`, `MenuFrame`, `Tooltip`, `Strip`,
  `Cover`, `Text`, `ChartStyle`, `BarStyle`, `IconBorder`, `GlowColor`, and since Skin minor 6
  `BarTexture`). A primitive no loaded file
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

### Owner tokens

**An addon's own colors are tokens too** (Skin minor 7; LK-01 of Ka0sAddonsCommonTasks
`docs/2026-10-29-SKINNING_ROLLOUT/`). The rollout's inventory found thirty colors the fourteen
addons draw under Ka0s Default whose exact value no library token holds: a note gray at 0.533
against `text.muted`'s 0.7, Drop Watcher's verdict tones, DPS Race's ahead and caution hues.
Snapping each to the nearest library token would move Ka0s Default by a few levels per channel,
and giving each a schema row would make every skin carry fourteen addons' palettes. An owner token
is the third way: the addon names the color once, with its Ka0s Default value and the library ROLE
it stands nearest to, and every skin draws it from that.

```lua
local S = Skin:RegisterOwner("DropWatcher", {
  get = ..., set = ..., label = "Drop Watcher", log = NS.DebugLine,
  tokens = {
    ["dw.upgrade"] = { default = { 0.36, 0.86, 0.46, 1 }, follow = "sem.good" },
    ["dw.idle"]    = { default = { 0.533, 0.533, 0.533, 1 }, follow = "text.muted",
                       skins = { contrast = { 0.8, 0.8, 0.8, 1 } } },
  },
})
fs:SetTextColor(S.Color("dw.idle"))
S.Divider(rule, { token = "dw.idle" })
```

- **The name** carries the owner's namespace and a dot (`dw.upgrade`, `dr.ahead`), and is never a
  library token's name (`lib.SCHEMA`). A name with no dot, one that starts or ends with a dot, or
  one that collides with a schema name is **refused**; so is a definition that is not a table, has
  no `default`, names a `follow` that is not a library token, or gives a `skins` that is not a
  table. Each refusal is logged **once** per owner and name, through `opts.log` when the owner gave
  one, else to the client's error handler, and the good names beside it still land.
- **What it resolves to.** Ka0s Default answers `default`, so the addon's look under it is today's,
  pixel for pixel. Any other skin answers its own `skins[<skin key>]` entry when it has one (`false`
  there is that skin's none, nil to every read, unless the token is a bool), else the `follow`
  token's value **in that skin**, so every skin draws it in its own palette; a token with no
  `follow` keeps `default`. While EllesmereUI paints the owner (*The EllesmereUI provider*) it
  answers the follow token's EllesmereUI value (an accent token follows EllesmereUI's accent), else
  `default`; before EllesmereUI paints, an owner on `eui` wears its Ka0s skin and resolves as that
  skin.
- **Where it resolves.** `__Tokens` lays the owner tokens over the owner's table **after** its font
  and texture overrides (Skin minor 6), so `Token`, `Color`, `Resolve`, the facade's `S.Token` /
  `S.Color` / `S.Resolve` and every primitive that takes a token name (`S.Divider`'s `opts.token`)
  read them like a library token, and a token that follows `font.body` follows the font override.
  `ResolveSkin` and `__BaseTokens` never carry them. One owner's tokens never reach another owner.
  The derived table is cached per owner and rebuilt when the skin, the overrides, EllesmereUI's
  looks or the owner's tokens change.
- **Repaint.** A skin switch, an override change and EllesmereUI's live looks change repaint the
  owner's recorded frames as before, and a primitive that named an owner token paints its new value.
  Registering tokens repaints nothing: register them at file load, before the first paint. A second
  `RegisterOwner` adds its tokens and replaces a name it repeats.
- **No schema change.** An owner token is not a vocabulary entry, not a schema row and not in any
  skin's table, so no skin owes a value for it and the Skin Tester's coverage suite does not list it.
  The values are the host's tables: shared, never written.

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
drag handle, the reorder list and the line chart), and the tool windows' descriptors (the debug
console's `addonName`, `LibKa0s-DebugLog-1.0` 22.4.1.1; the perf panel's `addonName` or `name`,
`LibKa0s-Perf-1.0` 15.1.1.10; the sim panel's `name`, `LibKa0s-Sim-1.0` 2.3.7), paint through the
owner's facade once the owner is registered, and draw exactly what they drew before for any other
name. A host passes its
folder name, which it already passes to `MakeCloseButton`. Each major's document lists the tokens
its controls read.

## Ka0s Default and the token schema

A skin is `{ key, label, desc, swatches, tokens }`. Tokens are flat names. Kinds: `color`
(`{ r, g, b, a }`, 0 to 1), `colors` (an ordered list of colors), `number`, `string` (an LSM key, a
texture path, an anchor word) and `bool`. A skin derives from Ka0s Default: it names only the tokens
it changes, and `false` says "none" for a token Ka0s Default sets (it resolves to nil; a `bool` token
keeps its `false`).

**Ka0s Default sets every token** (SkinDefs minor 8, the owner's ruling of 2026-10-26: "make sure
even the Ka0s Default has a setting for everything"). No schema token is nil in it: its faces are
Oxanium, SemiBold for body and HUD text and Bold for titles (since SkinDefs minor 14, the owner's
choice of 2026-10-28; Friz Quadrata until then), set by name, its `q.*` the client's quality colors written out, and a decoration it
does not draw (a gradient stop, an art texture, a selection outline) is `false`, the explicit "none".
A skin derives from it, so every skin resolves every token. A nil that still reaches a primitive (a
payload with no SkinDefs.lua, or a skin that names a face the client cannot resolve) leaves that
property alone: a primitive calls `SetFont`/`SetFontObject` only for a resolved face, recording the
prior object and restoring it on a switch away.

**Ka0s Default's face and bar stay its own** (SkinDefs minor 14). Ka0s Default draws
`Ka0s Oxanium SemiBold` for `font.body` and `hud.font`, `Ka0s Oxanium Bold` for `font.title`, and
the generated `Ka0s Default` bar for `bar.texture`, all shipped by `LibKa0s-Media-1.0` minor 9. Every other skin derives from Ka0s Default, so `SkinDefs.lua`'s `KEEP`
table gives each skin that sets none of those four its earlier inherited values: Friz Quadrata TT
for the three faces and the client's `Blizzard` bar. A skin that sets its own keeps it.

**Every skin draws a bar of its own** (still SkinDefs minor 14; SO-04, the owner's approved
mockup). A mockup entry's `barTex` writes `bar.texture`: Obsidian `Ka0s Matte`, Azeroth
`Ka0s Parchment`, Glass `Ka0s Glass Bar`, High Contrast `Ka0s Solid`, Ember `Ka0s Forge`, WoW
Midnight `Ka0s Satin` and WoW Forever `Ka0s Classic`, all generated and shipped by
`LibKa0s-Media-1.0` minor 9. WoW Default sets none, so `KEEP` gives it the client's `Blizzard` bar.

**Geometry is skin-invariant in leg 1.** `title.height`, `scroll.width`, `scroll.gutter` and
`win.inset` keep Ka0s Default's value in every skin, and border or nine-slice art is drawn outset or
inside a fixed inset, so content anchors never move and a live switch lays out exactly as a reload.

**Every Ka0s Default value is a constant drawn today**, pinned by `tests/test_skin.lua` against the
constant it replaces: `Core.SKIN`, `LINE_CHART`, `AUTOCOMPLETE`, and the file-local tables of
`Core.lua`, `Widgets.lua`, `OptionsNav.lua`, `OptionsDrawer.lua`, `OptionsTabs.lua`,
`OptionsScroll.lua`, `DebugLogWindow.lua`, `PerfPanel.lua` and `SimPanel.lua`, read out of their source; LootHistory's constants are
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
| Bind on pickup | `sem.boundBoP` `.3, .82, .42` (green) · `sem.boundBoPAlt` `.85, .45, .45` (red) | LootHistory `BOUND_STYLE` (the table's padlocks) · `BOUND_COLOR` (Insights) |
| Bind on equip | `sem.boundBoE` `.92, .92, .92, .95` · `sem.boundBoEAlt` `.55, .8, .6` | the same two sites |
| Not bound | `sem.boundNone` `.6, .6, .6, .4` · `sem.boundNoneAlt` `.6, .6, .65` | the same two sites |
| Destructive item | `sem.danger` `1, 1/3, 1/3` · `sem.bad` `1, .33, .33` | the row menu's Delete and Forget (`\|cffff5555`) · `C.DirRGB`'s loss |
| Secondary text | `text.muted` `.7, .7, .72` · `text.value` `.8, .8, .82` | axis labels, Insights' strip labels · Insights' value and legend column (AnalyticsCharts.lua:170/:256/:283/:393) |
| Body text | `text.body` `.9, .9, .9` · `text.bodyAlt` `.86, .86, .86` · `text.subtle` `.85, .85, .85` · `text.highlight` `1, 1, 1` | menu rows, table cells, the AH table's price module · its live addon name (Panel.lua:707-708) · Holdings' holder total and fresh age (HoldingsTab.lua:416/:418) · Holdings' cell default (HoldingsTab.lua:391) |
| Tooltip value | `gtip.body` `.9, .9, .9` · `gtip.value` `1, 1, 1` | a label or body line · the value column (Compat.lua:647/:661/:674, Timeline.lua:542, TimelineModel.lua:386, AnalyticsCharts.lua:29/:140, Panel.lua:647) |
| Tooltip gray | `gtip.muted` `.5, .5, .5` · `gtip.subtle` `.7, .7, .7` | a hint line · the launcher's record count (LauncherSetup.lua:206) |
| Dimmed icon | `icon.tint` `.7, .7, .72` · `icon.dim` `.55, .55, .55` | a resting icon · the AH table's inactive info icon (Panel.lua:721-722) |
| Signed figure | `sem.good` / `sem.bad` · `sem.goodAlt` `.25, 1, .25` / `sem.badAlt` `1, .25, .25` | `C.DirRGB` · LedgerFormat's `\|cff40ff40` / `\|cffff4040` (LedgerFormat.lua:35-44) |
| Warband | `sem.warband` `.25, .75, .95` · `sem.warbandAlt` `.4, .78, 1` | `C.TIMELINE.WARBAND` · Holdings' Warband label (HoldingsTab.lua:309) |
| Missing class or quality | `text.muted` `.7, .7, .72` · `sem.unknown` `.6, .6, .6` | Insights' no-class fallback · its no-quality fallback (AnalyticsFormat.lua:99 / :106) |
| Idle label | `tab.text` `.7, .7, .72` (LootHistory's browser tabs) · the Options tab strip's font objects (no token: stock) | Browser `SKIN.tabIdle` · `OptionsTabs` |
| Selected vs idle | `nav.text` gold / `nav.selText` white · `drawer.text` white / `drawer.textSet` gold | `OptionsNav` · `OptionsDrawer` (opposite conventions) |

Identity colors that carry meaning by hue (LootHistory's 36 per-source colors, class colors) are
not tokens: no skin changes what they mean. The bind states were on that list until SkinDefs minor
5 made them tokens, because a near-white `BoE` lock and a faint gray unbound one could not be read on
Azeroth's light parchment (dark since SkinDefs minor 8): the skins inherit Ka0s Default's hues and
only a skin that needs it overrides (*Token reference*, below).

### Token reference

Every token in `SCHEMA` and its Ka0s Default value. The other eight skins' values are under *The
eight skins*, below.

### Fonts

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `font.body` | string | yes | `"Ka0s Oxanium SemiBold"` (`"Friz Quadrata TT"` until SkinDefs minor 14) |
| `font.title` | string | yes | `"Ka0s Oxanium Bold"` (`"Friz Quadrata TT"` until SkinDefs minor 14) |
| `font.mono` | string | yes | `"JetBrains Mono"` |
| `font.bodySize` | number | yes | `12` (the reference) |
| `font.titleSize` | number | yes | `14` (the reference) |
| `font.outline` | string | yes | `""` |
| `font.shadow` | bool | yes | `true` |

### Window

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `win.bg` | color | no | `0.06, 0.06, 0.08, 0.92` |
| `win.bgTop` | color | yes | none (`false`) |
| `win.bgBottom` | color | yes | none (`false`) |
| `win.bgTexture` | string | yes | none (`false`) |
| `win.bgDense` | color | no | `0.06, 0.06, 0.08, 0.95` |
| `win.border` | color | no | `0, 0, 0, 1` |
| `win.borderSize` | number | no | `1` |
| `win.borderStyle` | string | no | `"flat"` |
| `win.inner` | color | yes | `0.24, 0.24, 0.27, 0.85` |
| `win.inset` | number | no | `1` |
| `win.radius` | number | no | `0` |
| `title.bg` | color | yes | `0.04, 0.04, 0.05, 0.9` |
| `title.bgTop` | color | yes | none (`false`) |
| `title.bgBottom` | color | yes | none (`false`) |
| `title.text` | color | no | `1, 0.82, 0, 1` |
| `title.align` | string | yes | `"CENTER"` |
| `title.height` | number | no | `30` |
| `divider` | color | no | `0.24, 0.24, 0.27, 0.85` |
| `foot.bg` | color | yes | `0.04, 0.04, 0.05, 0.9` |
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
| `text.faint` | color | no | `0.45, 0.45, 0.48, 1` |
| `log.ts` | color | no | `#6F8FAF` (`0.435, 0.561, 0.686, 1`) |
| `log.tag` | color | no | `#C9A66B` (`0.788, 0.651, 0.42, 1`) |
| `log.text` | color | no | `1, 1, 1, 1` |
| `log.count` | color | no | `0.6, 0.6, 0.62, 1` |
| `text.value` | color | no | `0.8, 0.8, 0.82, 1` |
| `text.bodyAlt` | color | no | `0.86, 0.86, 0.86, 1` |
| `text.subtle` | color | no | `0.85, 0.85, 0.85, 1` |
| `text.highlight` | color | no | `1, 1, 1, 1` |
| `gtip.value` | color | no | `1, 1, 1, 1` |
| `gtip.subtle` | color | no | `0.7, 0.7, 0.7, 1` |

### Buttons

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `btn.bg` | color | no | `0.1, 0.1, 0.12, 0.9` |
| `btn.bgTop` | color | yes | none (`false`) |
| `btn.bgBottom` | color | yes | none (`false`) |
| `btn.border` | color | no | `0.24, 0.24, 0.27, 0.9` |
| `btn.borderSize` | number | yes | `1` |
| `btn.borderStyle` | string | yes | `"flat"` |
| `btn.text` | color | no | `1, 1, 1, 1` |
| `btn.hover` | color | no | `1, 0.82, 0, 1` |
| `btn.icon` | color | no | `0.85, 0.85, 0.85, 1` |
| `btn.radius` | number | no | `0` |
| `btnPrimary.bg` | color | no | `0.2, 0.16, 0.03, 0.95` |
| `btnPrimary.bgTop` | color | yes | none (`false`) |
| `btnPrimary.bgBottom` | color | yes | none (`false`) |
| `btnPrimary.border` | color | no | `1, 0.82, 0, 0.8` |
| `btnPrimary.borderSize` | number | yes | `1` |
| `btnPrimary.borderStyle` | string | yes | `"flat"` |
| `btnPrimary.text` | color | no | `1, 0.82, 0, 1` |
| `btnPrimary.hover` | color | no | `1, 1, 1, 1` |
| `btnPrimary.icon` | color | no | `0.85, 0.85, 0.85, 1` |
| `btnPrimary.radius` | number | no | `0` |

### Inputs

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `input.bg` | color | no | `0.1, 0.1, 0.12, 0.9` |
| `input.border` | color | no | `0.24, 0.24, 0.27, 0.9` |
| `input.borderSize` | number | yes | `1` |
| `input.borderStyle` | string | yes | `"flat"` |
| `input.text` | color | yes | `0.9, 0.9, 0.9, 1` |
| `input.placeholder` | color | yes | `0.5, 0.5, 0.5, 1` |
| `input.focus` | color | no | `1, 0.82, 0, 0.9` |
| `input.radius` | number | no | `0` |
| `check.bg` | color | no | `0.1, 0.1, 0.12, 0.9` |
| `check.border` | color | yes | `0.24, 0.24, 0.27, 0.9` |
| `check.borderSize` | number | yes | `1` |
| `check.borderStyle` | string | yes | `flat` |
| `check.mark` | color | no | `1, 0.82, 0, 1` |
| `check.radius` | number | no | `0` |
| `check.texture` | string | yes | none (`false`) |
| `check.markTexture` | string | yes | none (`false`) |
| `slider.track` | color | yes | `0.24, 0.24, 0.27, 0.9` |
| `slider.trackBorder` | color | yes | none (`false`) |
| `slider.fill` | color | yes | `1, 0.82, 0, 1` |
| `slider.thumb` | color | yes | `0.9, 0.9, 0.9, 1` |
| `scroll.track` | color | no | `0.24, 0.24, 0.27, 0.4` |
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
| `tab.border` | color | yes | `0.24, 0.24, 0.27, 0.9` |
| `tab.borderSize` | number | yes | `1` |
| `tab.borderStyle` | string | yes | `"flat"` |
| `tab.onBg` | color | yes | `0.18, 0.18, 0.18, 0.9` |
| `tab.onText` | color | no | `1, 0.82, 0, 1` |
| `tab.onLine` | color | no | `1, 0.82, 0, 1` |
| `tab.rule` | color | no | `1, 0.82, 0, 0.16` |
| `tab.radius` | number | no | `0` |
| `tab.texture` | string | yes | none (`false`) |
| `tab.onTexture` | string | yes | none (`false`) |
| `nav.bg` | color | no | `0.1, 0.1, 0.1, 0.5` |
| `nav.border` | color | no | `0.4, 0.4, 0.4, 1` |
| `nav.borderSize` | number | yes | `1` |
| `nav.borderStyle` | string | yes | `"flat"` |
| `nav.text` | color | no | `1, 0.82, 0, 1` |
| `nav.selBg` | color | no | `0.3, 0.5, 1, 1` |
| `nav.selText` | color | no | `1, 1, 1, 1` |
| `nav.selBar` | color | yes | none (`false`) |

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
| `list.header.bg` | color | yes | `1, 1, 1, 0.04` |
| `list.header.text` | color | no | `1, 0.82, 0, 1` |
| `list.stripe` | color | no | `1, 1, 1, 0.03` |
| `list.hover` | color | no | `1, 0.82, 0, 0.1` |
| `list.sel` | color | yes | `1, 0.82, 0, 0.18` |
| `list.selOutline` | color | yes | none (`false`) |
| `card.bg` | color | no | `0.1, 0.1, 0.12, 0.85` |
| `card.border` | color | no | `0.24, 0.24, 0.27, 0.9` |
| `panel.bg` | color | no | `0.08, 0.08, 0.1, 0.6` |
| `panel.border` | color | no | `0.24, 0.24, 0.27, 0.7` |
| `section.rule` | color | no | `1, 0.82, 0, 0.35` |
| `icon.tint` | color | no | `0.7, 0.7, 0.72, 1` |
| `icon.hot` | color | no | `1, 1, 1, 1` |
| `icon.arrow` | color | no | `1, 0.82, 0, 1` |
| `handle.bg` | color | no | `0, 0, 0, 0.75` |
| `handle.edge` | color | no | `1, 0.82, 0, 0.6 |`
| `handle.rest` | color | no | `0.7, 0.7, 0.7, 1 |`
| `list.dropLine` | color | no | `1, 0.82, 0, 0.9 |`
| `list.ghostBg` | color | no | `0.12, 0.12, 0.12, 0.95 |`
| `list.box` | color | no | `1, 1, 1, 0.06 |`
| `list.boxDim` | color | no | `1, 1, 1, 0.03 |`
| `list.boxEdge` | color | no | `1, 1, 1, 0.12 |`
| `list.boxEdgeDim` | color | no | `1, 1, 1, 0.06 |`
| `icon.dim` | color | no | `0.55, 0.55, 0.55, 1` |

### Overlays

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `popup.bg` | color | no | `0, 0, 0, 0.92` |
| `popup.border` | color | yes | `0.24, 0.24, 0.27, 0.9` |
| `popup.borderSize` | number | yes | `1` |
| `popup.borderStyle` | string | yes | `"flat"` |
| `popup.radius` | number | no | `0` |
| `tooltip.bg` | color | yes | `0.05, 0.05, 0.08, 0.95` |
| `tooltip.border` | color | yes | `0.24, 0.24, 0.27, 0.9` |
| `strip.test` | color | no | `1, 0.65, 0.15, 0.12` |
| `strip.sim` | color | no | `0.35, 0.8, 1, 0.12` |
| `cover.dim` | color | no | `0, 0, 0, 0.6` |
| `cover.text` | color | no | `0.667, 0.667, 0.667, 1` |

### HUD

| Token | Kind | Nilable | Ka0s Default |
|---|---|---|---|
| `bar.texture` | string | no | `"Ka0s Default"` (`"Blizzard"` until SkinDefs minor 14) |
| `bar.gloss` | bool | no | `false` |
| `bar.bg` | color | yes | `0, 0, 0, 0.5` |
| `bar.border` | color | yes | `0, 0, 0, 1` |
| `bar.borderStyle` | string | no | `"None"` |
| `bar.borderSize` | number | no | `1` |
| `icon.border` | color | yes | `0, 0, 0, 1` |
| `glow.color` | color | yes | `1, 0.82, 0, 1` |
| `hud.font` | string | no | `"Ka0s Oxanium SemiBold"` (`"Friz Quadrata TT"` until SkinDefs minor 14) |
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
| `q.poor` | color | yes | `0.62, 0.62, 0.62, 1` |
| `q.common` | color | yes | `1, 1, 1, 1` |
| `q.uncommon` | color | yes | `0.12, 1, 0, 1` |
| `q.rare` | color | yes | `0, 0.44, 0.87, 1` |
| `q.epic` | color | yes | `0.64, 0.21, 0.93, 1` |
| `q.legendary` | color | yes | `1, 0.5, 0, 1` |
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
| `sem.stepReady` | color | no | `0.9, 0.9, 0.92, 1` |
| `sem.stepBusy` | color | no | `1, 0.82, 0, 1` |
| `sem.stepLocked` | color | no | `0.4, 0.4, 0.42, 1` |
| `sem.stepCancel` | color | no | `0.8, 0.32, 0.32, 1` |
| `sem.stepCancelHot` | color | no | `1, 0.45, 0.45, 1` |
| `sem.boundNone` | color | no | `0.6, 0.6, 0.6, 0.4` |
| `sem.boundBoE` | color | no | `0.92, 0.92, 0.92, 0.95` |
| `sem.boundBoP` | color | no | `0.3, 0.82, 0.42, 1` |
| `sem.boundWarband` | color | no | `0.3, 0.58, 0.98, 1` |
| `sem.boundWarbandUE` | color | no | `0.95, 0.52, 0.12, 1` |
| `sem.boundBoPAlt` | color | no | `0.85, 0.45, 0.45, 1` |
| `sem.boundBoEAlt` | color | no | `0.55, 0.8, 0.6, 1` |
| `sem.boundNoneAlt` | color | no | `0.6, 0.6, 0.65, 1` |
| `sem.danger` | color | no | `1, 1/3, 1/3, 1` (hex-encodes to `ff5555`) |
| `sem.goodAlt` | color | no | `0.25, 1, 0.25, 1` (hex-encodes to `40ff40`) |
| `sem.badAlt` | color | no | `1, 0.25, 0.25, 1` (hex-encodes to `ff4040`) |
| `sem.warbandAlt` | color | no | `0.4, 0.78, 1, 1` |
| `sem.unknown` | color | no | `0.6, 0.6, 0.6, 1` |

**235 tokens.** `icon.arrow` joined at SkinDefs minor 12: the in-client arrow art's color (the paging, dropdown and sort arrows), Ka0s Default's gold and every other skin's accent, which it follows. `scroll.thumbFill` (SkinDefs minor 9) and `scroll.thumbTexture` (minor 2) left at SkinDefs minor 10, never released: the scroll bar's knob is one flat `scroll.thumb` over the faded thumb art in every skin. The four art tokens (`check.texture`, `check.markTexture`,
`tab.texture`, `tab.onTexture`) joined at SkinDefs minor 2, for WoW Default's Blizzard art. The
eight **Widgets tokens** (`handle.edge`, `handle.rest`, `list.dropLine`, `list.ghostBg`, `list.box`,
`list.boxDim`, `list.boxEdge`, `list.boxEdgeDim`) joined at SkinDefs minor 3, so the drag handle and
the reorder list (`LibKa0s-Widgets-1.0` 16.2.6.4.4.1, *Skin owners*) follow a skin with Ka0s
Default's pixels unchanged: each is the constant that widget drew, where no existing token carried
that exact value (`icon.tint` is `0.7, 0.7, 0.72`, the handle's rest gray `0.7, 0.7, 0.7`). The other
eight skins derive them: `handle.edge` and `list.dropLine` from the skin's accent at 0.6 and 0.9
(as `list.hover` is at 0.1), the four boxes from its body text at 0.06, 0.03, 0.12 and 0.06,
`handle.rest` from its muted text and `list.ghostBg` from its popup fill. The ten **tool-window
tokens** (`text.faint`, `log.ts`, `log.tag`, `log.text`, `log.count`, `sem.stepReady`,
`sem.stepBusy`, `sem.stepLocked`, `sem.stepCancel`, `sem.stepCancelHot`) joined at SkinDefs minor
4, so the debug console, the perf panel and the sim panel (`LibKa0s-DebugLog-1.0` 22.4.1.1,
`LibKa0s-Perf-1.0` 15.1.1.10, `LibKa0s-Sim-1.0` 2.3.7) follow a skin with Ka0s Default's pixels
unchanged: each is the constant those windows drew (the command column, the console line's stamp,
tag and white message, its line counter, the step states; done and used are `sem.on`). The other
eight skins derive them by following a token the skin sets (`FOLLOW` in `SkinDefs.lua`): the
message and the ready step from the body text, the counter and the command column from the muted
text, the tag from the heading, the stamp from `sem.info`, the busy step from the accent, the
locked step from the disabled text, cancel from `sem.off` and its hover from `sem.bad`; a skin that
sets neither keeps the constant. The nine **bind-state and danger tokens** joined at SkinDefs minor
5, so LootHistory's padlocks, its Insights binding split and its row menu's destructive items follow
a skin with Ka0s Default's pixels unchanged: the five bind states are LootHistory's `BOUND_STYLE`
(the table's padlocks, legend and filter), the three `Alt` tokens its `BOUND_COLOR` split (Insights
draws bind on pickup red, bind on equip green and unbound in a cooler gray; its warband pair is the
table's own), and `sem.danger` the row menu's Delete and Forget, kept apart from `sem.bad` because
`1, 0.33, 0.33` hex-encodes to `ff5454` and the menu writes `|cffff5555`. They follow no other token:
the hue is the meaning, so the skins inherit Ka0s Default's values (Azeroth set all nine in ink until
SkinDefs minor 8 made it dark), and High Contrast sets the gray and off-white ones (`sem.boundNone`,
`sem.boundBoE`, `sem.boundNoneAlt`) opaque in its own palette. `tests/test_skin_defs.lua` holds every
skin's nine to a 3:1 contrast on its window. The eleven tokens for **the rest of LootHistory's
constants** (`text.value`, `text.bodyAlt`, `text.subtle`, `text.highlight`, `gtip.value`,
`gtip.subtle`, `icon.dim`, `sem.goodAlt`, `sem.badAlt`, `sem.warbandAlt`, `sem.unknown`) joined at
SkinDefs minor 6, from one sweep of every LootHistory surface still to be skinned for a constant no
token reproduced exactly under Ka0s Default; each pair they make with an older token is a row of
*Split roles*, above. Every other constant there already had its token (LedgerFormat's `|cff808080`
zero is `text.disabled`, Slash's `|cffffd100` is `text.accent`), and an alpha a call site applies to
a token's color (the 0.95 series fills, the 0.9 flow bars) stays the call site's. They follow no
other token, so the skins inherit Ka0s Default's values (Azeroth set the window ones in ink until
SkinDefs minor 8); High Contrast sets the grays in its own palette (`text.value` and
`gtip.subtle` `#E0E0E0`, `text.bodyAlt` and `text.subtle` white, `icon.dim` and `sem.unknown`
`#B0B0B0`). `tests/test_skin_defs.lua` holds every skin's window ones to a 3:1 contrast on its
window and its `gtip` ones to 4.5:1 on the dark tooltip.

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
- **Stock art is faded under every skin.** A target that carries template art has it faded and is
  painted from the skin's tokens, Ka0s Default's included (SkinPaint minor 6; until then Ka0s Default
  left a stock target as the client drew it). A custom target (a BackdropTemplate frame the library
  or the host built) is painted the same way.
- **The holder, and fills under the target.** **Edges** (borders, a divider's line, a tab's
  underline, a nav entry's selection bar, a list row's selection outline) go on the **holder**, a child
  frame of the target made once, `SetAllPoints` over it, BackdropTemplate, at the target's frame
  level + 1, so a nine-slice edge can be its backdrop and every edge draws over the target. A
  **window's** edge and inner rule (`Shell`, since SkinPaint minor 9) go on the **edge holder**
  instead, the same kind of child at the window's level + 10, over the window's own children: a title
  bar or footer one level up reached into a 2px or 3px edge and covered it at the four corners (the
  owner's round-5 notes on Azeroth, High Contrast and WoW Midnight). **Fills and
  washes** (a list row's stripe, hover and selection washes, the strip and cover washes, the extras'
  fills and gradients: `TitleBar`, `Footer`, `Card`, `SortHeaderBar`, a boxed `Drawer` header) are, since
  SkinPaint minor 7, **regions of the target itself** at the bottom sublevels of BACKGROUND (`P.SUB`:
  fill -8 and gradient -7; stripe -8, hover -7, selection -6; a wash -8), under every region the target
  draws and, as the target's own, always drawn over its parent. Until minor 7 they sat on a fill holder
  one frame level below the target, which tied the target's parent whenever the target was one level
  above it, and the client draws two frames of one level in either order (Loot History's title bar
  under its window's backdrop, 2026-10-27). They are made through `P.subTex`, which sets the region's
  alpha back to 1 on every paint: EllesmereUI's FadeRegions fades every direct region of a frame it
  skins, and a fade from a stint on that provider (Ka0s's regions hidden meanwhile) is undone on the
  way back. `P.under`, the old fill holder, stays for a sibling file's older copy. On an extra that
  wears a backdrop and gets a gradient, the gradient is the fill and the backdrop's own fill is
  cleared.
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
- **Fonts** go through one font object per owner, role and size
  (`LibKa0sSkin_<owner>_<role>_<tenths>`, role `body`, `title` or `mono`, since SkinPaint minor 4;
  one object per role let two strings of one role at two sizes share its last size), created with
  `CreateFont`, given the face, size, outline and (unless
  `font.shadow` is false) a 1, -1 black shadow, then set on the string with `SetFontObject`: from
  12.0.7 a runtime `SetShadow*` on a FontString no longer renders, a font object's shadow does. A nil
  face token (every font token in Ka0s Default) leaves the string's font alone, and puts back the
  font it had before a skin's face reached it: its font object when that was a named font, else
  its face by path, size and flags. An EditBox in the client answers `GetFontObject` with an
  anonymous font object rather than the one it was given, and handing that back through
  `SetFontObject` overflows the client's stack (SkinPaint minor 3). Faces resolve through
  LibSharedMedia.
- **Labels.** Every string a primitive colors also takes the skin's face (`P.label`, SkinPaint minor 5):
  an EditBox's hint, a sort header's texts, a footer, a card, a cover, a nav item, a tab and a state
  label no longer keep the client's font and its shadow under a skin that sets a face. A dark label
  (relative luminance under .3) takes a shadowless font object (`..._ns`): the black drop shadow
  smeared dark strokes on a bright primary button or a selected tab.
- **Sizes are relative** (SkinPaint minor 4, `P.fontSize`). Every skin sets `font.bodySize` and
  `font.titleSize`, and Ka0s Default's (12 and 14) are the reference: a string keeps its own stock
  size times the skin's size over the reference, so a 10pt caption under a skin at 12.5 is about
  10.4pt and every layout measured against the stock fonts holds. The skins sit within a point and a
  half of the reference (`tests/test_skin_defs.lua`), each tuned to its face's measure (SkinDefs
  minor 11): Inter, Bitter and Fira Sans 12, Nunito and Philosopher 12.5, Vollkorn 13 (a small
  x-height), titles 14 (Bitter's 13.5, a wide face), and High Contrast 13.5 and 15 (which still
  reads larger).
- **Colors.** A text or vertex color whose alpha is 1 is passed as three components, as every call
  site writes them; fills and backdrop colors as four. A color from a nilable token, or any color on
  a stock target, records the prior color first and puts it back when the token resolves to nil.
- **Hover and focus** are `HookScript`'d once per target and read the target's record at call time,
  so a skin switch needs no new hook and a pooled control that moved to another owner hovers in that
  owner's skin. Call a primitive **after** the host sets its own scripts: a later `SetScript`
  replaces the hook. `S.CloseButton(btn, { own = true })` is the one primitive that SetScripts, for
  a close button the library built and that has no host script, as Core's does today.

### Ka0s Default is a skin like the others

Since SkinPaint minor 6 no primitive branches on Ka0s Default: it paints from Ka0s Default's tokens
exactly as from any skin's, and those tokens carry the library's own look (Core.SKIN, Widgets' SKIN,
LootHistory's constants). `tests/test_skin_paint.lua` and `tests/test_skin_paint_controls.lua` pin
each primitive's Ka0s Default draw against the code it stands for; where a row below says a call is
that code's call, the tokens carry that code's values:

| Primitive | Pinned against |
|---|---|
| `Shell(frame)` | `Core.ApplySkin(frame)`'s look: Core's backdrop built from Ka0s Default's tokens, which carry Core.SKIN's fill, edge and inner rule, for a registered owner and for an unregistered name alike |
| `Panel(frame)` | LootHistory's list panel (`modules/AnalyticsCharts.lua`) |
| `Panel(frame, { nav = true })` | OptionsNav's rail recolor (`PANE_FILL` four components, `PANE_BORDER` three) |
| `Card(frame)` | LootHistory's KPI card (`modules/Analytics.lua`) |
| `MenuFrame(frame)` | Widgets' shared popup menu (`EnsureMenu`: the WHITE8X8 table with no insets) |
| `Divider(texture)` | Core.ApplySkin's divider |
| `Strip(texture, opts)` | `W.TestStrip`'s fill (`STRIP_FILL`, test and sim) |
| `Cover(texture, { text })` | OptionsCombat's dim and its line |
| `TitleBar(bar)` | the gold title, centered, over Ka0s Default's `title.bg` (SkinDefs minor 8) |
| `Footer(frame)`, `Tooltip(frame)` | Ka0s Default's `foot.bg` band and `tooltip.bg` / `tooltip.border` (SkinDefs minor 8) |
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
skins' own (`win.bgTexture`, `tab.texture`, `tab.onTexture`,
`check.texture`, `check.markTexture`, the `nine:` border keys) plus `PageButton`'s arrow,
`Interface\ChatFrame\ChatFrameExpandArrow`.

**The window family** (`SkinPaint.lua`, `SkinPaintExtras.lua`):

| Primitive | Paints | Tokens |
|---|---|---|
| `Shell(frame, opts)` | A window. On a backdrop frame, `Core.ApplySkin` with the skin's table (the backdrop with its own edge clear, `frame.title`'s color, `frame.divider`'s); a frame with no backdrop gets its fill as a region. On any frame the edge (`win.border*`, flat, bevel or nine-slice) and the inner rule (`win.inner`, 1px inside the edge) on the edge holder, over the window's children (SkinPaint minor 9; Core's own inner rule is cleared and given back on unpaint), the window gradient, the tiled art, the top bar (unless `opts.noTopBar`) and the bottom bar (`opts.bottomBar`, true or a height), and the title font on `frame.title`. `opts.noBorder` draws no edge and no inner rule. | `win.*`, `title.bg` / `bgTop` / `bgBottom`, `title.text`, `title.height`, `divider`, `foot.bg`, `font.title` |
| `Panel(frame, opts)` | A flat panel; `opts.inset` paints it as an inset, `opts.noBg` / `opts.noBorder` leave out a half, `opts.nav` recolors the backdrop the frame already wears. | `panel.bg`, `panel.border`; `nav.bg`, `nav.border` |
| `Inset(frame, opts)` | A recessed area. | `input.bg`, `input.border`, `input.borderStyle`, `input.borderSize` |
| `FadeRegions(frame, ...)` | Fades every texture region of the frame (and of each further frame) that no primitive made. Ka0s Default fades nothing and puts them back. | none |
| `FadeNineSlice(frame)` | Fades `frame.NineSlice`'s nine pieces. Ka0s Default puts them back. | none |
| `TitleBar(bar, opts)` | A title bar: the fill (the bar's backdrop, or a region of the bar under its text), its text (`opts.text`, else `bar.title` / `bar.text`) in the title color, font and alignment (the prior alignment put back when the skin sets none). | `title.bg` / `bgTop` / `bgBottom`, `title.text`, `title.align`, `font.title` |
| `Divider(target, opts)` | A texture colored in place, or a line filling a frame on its holder; `opts.token` names another color (`section.rule`, `tab.rule`). | `divider` |
| `Footer(frame, opts)` | A footer band; its text (`opts.text`, else `frame.text`) muted. | `foot.bg`, `text.muted` |
| `Card(frame, opts)` | A card: `opts.title` in the heading color, `opts.text` in the body color. | `card.bg`, `card.border`, `text.heading`, `text.body` |
| `Strip(target, opts)` | The test or simulation strip's wash (`opts.kind` `"test"` / `"sim"`), a texture in place or a region of the frame. The meaning colors are the library's; a skin changes only their legibility. | `strip.test`, `strip.sim` |
| `Cover(target, opts)` | The combat cover's dim, and `opts.text`. | `cover.dim`, `cover.text` |
| `Tooltip(frame)` | A **library-owned** tooltip's backdrop, recolored; never GameTooltip. | `tooltip.bg`, `tooltip.border` |
| `MenuFrame(frame, opts)` | A popup menu's flat backdrop (no insets); `opts.alt` the alternate edge; `opts.popup` recolors the backdrop the frame already wears, and a nil `popup.*` token puts that half back as the frame wore it before the first paint (a skin switch to Ka0s Default gives the edge back). | `menu.bg`, `menu.border`, `menu.borderAlt`, `menu.borderStyle`, `menu.borderSize`; `popup.bg`, `popup.border` |
| `Text(fs, role)` | A text role's color and font: `body`, `muted`, `heading`, `headingAlt`, `accent`, `disabled`, `link`, `linkHot`, `title` (the title font for `title` and the headings, the body font otherwise). | `text.*`, `title.text`, `font.*` |
| `Font(fs, r, g, b)` | The body font, and the color when given. | `font.body`, `font.bodySize`, `font.outline`, `font.shadow` |
| `White(fs)` | The body font and the body color (EllesmereUI's `White`, legible in a light skin). | `font.body`, `text.body` |
| `BarTexture(target, r, g, b, a)` | A bar of data (SkinPaintExtras minor 4, LibKa0s#63): the owner's bar texture, its texture override when it sets one (`SetOverride`), tinted. A Texture takes `SetTexture(path)` and `SetVertexColor(r, g, b, a)`; a StatusBar `SetStatusBarTexture(path)` and `SetStatusBarColor(r, g, b, a)`. With no texture resolved (no LibSharedMedia, or a key it lacks) a Texture falls back to `SetColorTexture(r, g, b, a)` with a white vertex color, the flat look a host's chart bar draws today, and a StatusBar to `WHITE8X8`. Recorded, so a skin switch and an override change re-apply the texture live. The color is the bar's own from then on: a host's call that names a color paints it; a nil color, and every repaint, paint the color the bar wears at that moment (a Texture's vertex color, a StatusBar's bar color), so a host's direct `SetVertexColor` or `SetStatusBarColor` between paints holds. A flat Texture's tint lives in `SetColorTexture` and cannot be read back, so it is remembered while the vertex color stays the white the primitive set. A texture `Untrack` handed back starts from its own color. Any other target is left alone and nothing is recorded. | `bar.texture` |

**The controls** (`SkinPaintControls.lua`):

| Primitive | Paints | Tokens |
|---|---|---|
| `Button(btn, keepKeys \| opts)` | A push button: its stock art faded, the flat-control box, the label (the button's font string, else `btn.text` / `btn.Text`) in the text color and body font, the hover color under the pointer, `text.disabled` while the button is disabled (following `OnEnable` / `OnDisable`, SkinPaintControls minor 2), `btn.icon` tinted. `keepKeys == true` or `opts.keep` keeps the stock art and paints only the label; `opts.primary` reads `btnPrimary.*`. | `btn.*` / `btnPrimary.*` (`bg`, `bgTop`, `bgBottom`, `border`, `borderStyle`, `borderSize`, `text`, `hover`, `icon`) |
| `WhiteButtonLabel(btn)` | The label in the button text color and body font. | `btn.text` |
| `StateButtonLabel(btn, on)` | The label in the accent while on, muted otherwise. | `text.accent`, `text.muted` |
| `EditBox(eb, opts)` | A text input: the template's pieces faded, the flat-control box, the typed text and the hint (`opts.placeholder`, else `eb.hint`), the focus edge while it has the keys. `opts.padInput` sets 6px insets; `opts.noBorder` draws no edge and hooks no focus. | `input.*` |
| `Checkbox(cb, opts)` | A check button, under every skin including Ka0s Default (SkinPaintControls minor 2: a square box rather than the client's round check button): its stock art faded (the stock check too unless `opts.stockCheck`), a box `opts.borderInset` inside it, an edge on the holder, a mark three pixels inside the box shown while checked (following `OnClick`, `OnShow` and `SetChecked`), and with `opts.hover` a highlight. | `check.*`, `menu.hover` |
| `Dropdown(dd, opts)` | A dropdown button: the template's pieces faded, the flat-control box, the arrow (`dd.arrow` / `dd.Arrow`, desaturated and colored `icon.arrow` since SkinPaintControls minor 8: the art is yellow and a tint only multiplies it), the label (`dd.text` / `dd.Text`). | `input.*`, `icon.arrow` |
| `ScrollBar(sb, opts)` | A scroll bar, a corridor and one knob in every skin (SkinPaintControls minor 7): `opts.track` / `opts.thumb` (textures the caller drew) filled; otherwise the bar's own thumb art is faded and a flat knob laid in its place, `scroll.thumb` (`scroll.thumbOn` / `scroll.thumbOff` for `opts.state` `"on"` / `"off"`), 3px inside the bar's sides and 2px inside the thumb's ends, anchored to the thumb and shown and hidden with it, over a `scroll.track` corridor the bar's full size. The client's art is never tinted. | `scroll.*` |
| `Slider(slider, opts)` | A slider's track (a 4px bar centered in the slider since SkinPaintControls minor 3, Ka0s Default's host-drawn shape; its edge on the holder, none in every shipped skin), fill (`opts.fill`) and thumb (`opts.thumb`, else its own). Every slider token is nil in Ka0s Default. | `slider.*` |
| `Tab(tab, opts)` | A tab: its stock art (and `opts.stock`) faded, the backing (`opts.fill`, else a region: the tab art, else the color and gradient), an underline on the holder while selected, the label (`opts.text`, else its own). `opts.selected` is the first state. | `tab.*` |
| `SetTabSelection(tab, selected)` | Moves a painted tab's state and repaints it; the state lives in the tab's record, so a skin switch keeps it. | as `Tab` |
| `CloseButton(btn, opts)` | A close control: its art (`btn.icon`, a texture, or `btn.glyph`) at rest and under the pointer. A stock close button has its art faded and an ASCII `x` drawn, under every skin. `opts.own` SetScripts the hover pair. | `close.rest`, `close.hot` |
| `PageButton(btn, dir)` | A paging arrow (`prev`, `next`, `up`, `down`, `left`, `right`): the button look and the in-client arrow, turned, desaturated and colored `icon.arrow` (`btn.icon` until SkinPaintControls minor 8). | `btn.*`, `icon.arrow` |
| `SquareIcon(frame, opts)` | An icon button: `opts.crop` trims the icon art (`opts.icon`, else `frame.icon` / `frame.Icon`) to .08-.92; an edge on the holder. | `icon.border` |
| `IconBorder(frame, opts)` | An icon edge, `opts.size` pixels, on the holder. | `icon.border` |
| `SortHeaderBar(bar, opts)` | A list header: the fill, each of `opts.texts`, each of `opts.arrows` (desaturated, since minor 8). | `list.header.bg`, `list.header.text`, `icon.arrow` |
| `ApplyBarFill(target)` | The accent on a status bar (`SetStatusBarColor`) or a texture. | `text.accent` |
| `NavItem(item, opts)` | A nav-rail entry: `opts.label` selected or not, `opts.sel` (the selection texture), a selection bar on the holder while `opts.selected`. | `nav.text`, `nav.selText`, `nav.selBg`, `nav.selBar` |
| `Drawer(head, opts)` | A settings drawer: `opts.label` and `opts.summary` set or not (`opts.set`), then the edge set (`opts.edges`, OptionsDrawer's `{ fill, left, right, bottom, top }`) open or not (`opts.open`), and the box's (`opts.box`). A header with no edge set is boxed on its holders (the fill under its text, the edge over it). | `drawer.*` |
| `ListRow(row, state)` | A list row's washes as regions of the row, under its text (stripe, hover, selection), and the selection outline on its holder. `state` is a table or `"stripe"`, `"hover"`, `"selected"`, `"normal"`. | `list.stripe`, `list.hover`, `list.sel`, `list.selOutline` |

**The getters** (record nothing):

| Getter | Answers |
|---|---|
| `GetAccentColor()` | r, g, b, a of `text.accent` |
| `GetPanelColor()` | r, g, b, a of `win.bg` |
| `GetFont()` | the body face's path, or the client's `STANDARD_TEXT_FONT` when the skin names none |
| `GlowColor()` | r, g, b, a of `glow.color` (Ka0s Default's gold since SkinDefs minor 8) |
| `ChartStyle()` | a fresh table of the `chart.*` tokens by short name (`axis`, `axisAlt`, `grid`, `crosshair`, `marker`, `line`, `bar`, `track`, `total`, `other`, `otherLine`, `series`); the colors are shared |
| `BarStyle()` | a fresh table: `texture` (the LSM path or nil), `textureKey`, `gloss`, `bg`, `border`, `borderStyle`, `borderSize`, `font` (path or nil), `fontKey`, `fontSize`, `outline`, `iconBorder` |

### WoW Default and WoW Midnight on the primitives

The choices (*Blizzard art and the per-skin choices*, below) are drawn as follows. WoW
Default's window is `Shell`'s nine-slice edge, `Blizzard Dialog` at 32 outset by 8 on the holder,
the backdrop's own edge clear, over a `#1E1C19` backdrop fill with `UI-DialogBox-Background-Dark`
tiled in a band above it; its buttons are `Button`'s red gradient under a 1px dark rim (a 2px `bevelOut` gold edge until SkinDefs minor 7) on
the holder; its tabs are `Tab`'s `UI-OptionsFrame-ActiveTab` art in both states (since SkinDefs minor 7: the
`-InActiveTab` art is drawn shorter); its scroll knob
`ScrollBar`'s flat gold knob over a black corridor (the `UI-ScrollBar-Knob` art until SkinDefs minor 10); its checkbox `Checkbox`'s `UI-CheckBox-Up` box and
`UI-CheckBox-Check` mark; its inputs and nav rail a 1px `bevelIn` edge (2px until SkinDefs minor 7). WoW Midnight
draws no art: `Shell`'s window and title gradients, its 2px flat window edge, `Button`'s violet
gradients under a 1px gold edge.

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
  mockup's `BASE`, and so does every token the mockups do not draw, except the four `KEEP` holds
  (`font.body`, `font.title`, `hud.font`, `bar.texture`: Friz Quadrata TT and `Blizzard`, since
  SkinDefs minor 14; every skin but WoW Default now sets its own `bar.texture` through `barTex`). Ka0s Default itself stays today's constants and is not touched by the mockup.
- **Extras.** Where the mockup draws nothing a surface needs (an opened drawer, KPI cards and
  list panels, disabled text, the hover wash on a primary button), a skin sets that token itself
  in its `extra` table, chosen from the skin's own palette. That includes `drawer.textSet` wherever
  the mockup draws the drawer label in the body color: OptionsDrawer's label color is the set /
  unset cue, so Obsidian, Azeroth and Glass take their accent and WoW Forever its heading gold. Azeroth, the one light skin until SkinDefs minor 8, also set
  its headings, quality colors, semantic colors and chart colors, which Ka0s Default draws for a
  dark window.
- **Derived washes.** `menu.hover`, `section.rule` and `drawer.borderOpen` are the skin's accent
  at Ka0s Default's alphas (.15, .35, .6), the way Ka0s Default draws them in gold. `list.hover` is
  the skin's body text at .10 (SkinDefs minor 7): in the accent it sat a shade from `list.sel`, and a
  hovered row could not be told from a selected one. Ka0s Default keeps its gold hover.

### What WoW cannot draw

- **No blur.** Glass is translucency (`win.bg` alpha .88, popups and tooltips .92, since SkinDefs
  minor 7; the mockup's .55 let the world through) on the shipped `Ka0s Glass` art.
- **One rounded art.** Glass's radius-8 nine-slice (`Ka0s Glass`, `LibKa0s-Media-1.0` 6.1) is the
  only rounded art shipped. Since SkinDefs minor 7 only Glass's window, popups and menus wear it, at
  radius 8 and edge size 8: its buttons, inputs, tabs and drawers looked awkward on it at control
  size and take a flat 1px frosted edge, the tabs boxless with a lilac underline. **Every other
  mockup radius is square** (0): Obsidian's 3px, Azeroth's 4px, Ember's 2px and the rest. Glass's
  checkbox and scroll thumb stay square too.
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
- **Fonts.** Every skin draws one family of its own, for body and titles alike (SkinDefs minor 11,
  the owner's round-5 notes: titles that did not match the body, and faces three skins shared):
  Obsidian Inter (its mockup's own face), Glass Nunito (rounded, as its corners are; the mockup's
  Manrope), Azeroth Vollkorn (a dark old-style book face for the parchment), Ember Bitter (a sturdy
  slab), WoW Midnight Philosopher, WoW Forever Fira Sans (crisp at small sizes) and High Contrast
  Atkinson Hyperlegible, a step larger than the rest (*Sizes are relative*, above). WoW Default
  draws Friz Quadrata, the client's own face, set by name through `KEEP`; Ka0s Default drew it too
  until SkinDefs minor 14 gave it Oxanium (the owner's choice). Until minor 11 Obsidian and Glass
  drew Barlow, and Azeroth, Ember and WoW Midnight titled in Cinzel, an all-capitals face no body text can share.
- **GameTooltip lines.** `gtip.*` are drawn on Blizzard's dark GameTooltip whatever the skin, so
  each skin's `gtip.title`, `gtip.body` and `gtip.muted` read at 4.5:1 or better on
  `(.05, .05, .08)`; Azeroth's are its parchment and gold.
- **Legibility.** Each skin's `text.body` reads at 4.5:1 or better on its own `win.bg`, and its
  other text roles at 3:1 or better.

### Blizzard art and the per-skin choices

This closes the open texture point of the run's spec (§9 there: which Blizzard textures serve WoW
Default and Midnight, and WoW Forever's window texture).

| Skin | Choice |
|---|---|
| **WoW Default** | The window is `BACKDROP_DIALOG_32_32`'s edge, LSM `Blizzard Dialog` (`Interface\DialogFrame\UI-DialogBox-Border`), `win.borderStyle = "nine:Blizzard Dialog"` at `win.borderSize = 32`, over `win.bgTexture = Interface\DialogFrame\UI-DialogBox-Background-Dark` tiled on a `#1E1C19` fill. Popups and menus wear the same edge at 16. Buttons are the red gradient `#B3200F` to `#640C05` under a 1px `#1A0805` rim with gold `#FFD100` text, white on hover, the client's own button; the primary a brighter red `#D42A16` to `#7E1007` under a 1px gold `#E0B040` edge with white text, gold on hover (both had a 2px `bevelOut` gold edge until SkinDefs minor 7). Tabs are `tab.texture` and `tab.onTexture` = `Interface\OptionsFrame\UI-OptionsFrame-ActiveTab`, one height in both states, the selected one told by its white label. The scroll knob is a flat gold `scroll.thumb` over a black corridor (the `UI-ScrollBar-Knob` art until SkinDefs minor 10); the checkbox is `check.texture = Interface\Buttons\UI-CheckBox-Up` with `check.markTexture = ...UI-CheckBox-Check`. Inputs, dropdowns and the nav rail have a 1px `bevelIn` gray edge, the primary button's size (2px until SkinDefs minor 7); the checkbox art is its own box, with no edge. The client's own fonts. |
| **WoW Midnight** | Flat `WHITE8x8` everywhere, **no Blizzard art**: a 2px `#B08A3E` window and popup edge over a `#3D2F12` inner rule, the window gradient `#171A2E` to `#0F1020`, the title bar gradient `#2A2347` to `#17142B` with a centered `#F6D27A` Philosopher title, violet `#B48CFF` accent, night-violet gradient buttons (`#3A2F6B` to `#1D1838`) under a 1px `#B08A3E` gold edge with gold `#F6D27A` text, and a brighter violet primary (`#7A5AD6` to `#3F2C86`, `#F6D27A` edge, white text) since SkinDefs minor 7. |
| **WoW Forever** | Warm brown charcoal `#2E251C` to `#18120D` (a step browner since SkinDefs minor 8) (the mockup's radial fill as a vertical gradient, **no window texture**), black `#050505` title bars with centered white titles, a tan `#C9A07A` accent, gold `#F2B33D` headings, thin 1px edges on every control, a `#9C7A58` primary with white text under its tan edge, Fira Sans (SkinDefs minor 11; Barlow until minor 8, which read blurry, then Atkinson Hyperlegible; OWNER_SCOPE R4). |
| **Glass** | A `#121622` window at .88 on `nine:Ka0s Glass` at radius 8 (above), popups the same; flat 1px frosted control edges and boxless tabs underlined in the lilac `#B69CFF` accent; translucent white washes, `bar.gloss = true`. |
| **High Contrast** | Black, a white 2px window edge and white 1px edges on every control (2px yellow on popups and menus; controls were 2px and popups 3px until SkinDefs minor 7), yellow `#FFE600` titles, accent, selection outline and focus; the primary button and the selected tab yellow on black (since SkinDefs minor 7; black on yellow before); Atkinson Hyperlegible 13.5 / 15. |
| **Obsidian** | True-black flat panels (a `#0A0A0B` window and a `#050506` title bar since SkinDefs minor 7, darker than Ka0s Default's navy), hairline `#202024` edges, no inner rule, a cool blue `#4DB8FF` accent, a deeper `#2A86D1` primary button with white text, Inter. |
| **Azeroth** | Dark tooled leather `#2B1D12` (SkinDefs minor 8; light parchment until then, which did not read in Loot History) under a 1px leather `#6B4A22` edge and a `#8A6A36` inner rule (a 3px edge until SkinDefs minor 13, which read much thicker than every other skin's frame), a `#1A110A` title bar with a gold title, parchment `#E9DDBC` text, Vollkorn throughout, gold `#E2B659` headings and accent, leather buttons with cream text, and the red wax seal for the primary button and the selected tab. As a dark skin it inherits Ka0s Default's semantic, quality, tooltip and chart colors. |
| **Ember** | Charred brown, a `#6A2E17` edge over an amber inner rule, orange `#FF7A33` accent, gradient title bar and buttons, the primary's text white, Bitter. |

An **art token** (`win.bgTexture`, `tab.texture`, `tab.onTexture`,
`check.texture`, `check.markTexture`) draws that art at its own colors; the color token beside it
(`win.bg`, `tab.bg`, `check.bg`, `check.mark`) is the fallback when the art does
not load. Only WoW Default names art. For a `nine:<key>` edge, `<ctl>.border` is the art's vertex
color (white leaves Blizzard's art as drawn) and `<ctl>.borderSize` its edge size.

### The eight skins' tokens

Each skin's own tokens, in schema order; `·` inherits Ka0s Default's value (the *Token reference*
above), `none` resolves to nil. Colors are `#RRGGBB`, then the alpha when it is below 1. A group
none of the eight sets is left out (HUD apart from `bar.texture`, `bar.gloss` and the `KEEP` value
`hud.font`, and the charts apart from Azeroth's). Generated from the live tables, so this list is what `SkinDefs.lua` holds.

#### Fonts

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `font.body` | `Ka0s Inter` | `Ka0s Vollkorn` | `Ka0s Nunito` | `Ka0s Atkinson` | `Ka0s Bitter` | `Friz Quadrata TT` | `Ka0s Philosopher` | `Ka0s Fira Sans` |
| `font.title` | `Ka0s Inter SemiBold` | `Ka0s Vollkorn Bold` | `Ka0s Nunito SemiBold` | `Ka0s Atkinson Bold` | `Ka0s Bitter Bold` | `Friz Quadrata TT` | `Ka0s Philosopher Bold` | `Ka0s Fira Sans SemiBold` |
| `font.bodySize` | `12` | `13` | `12.5` | `13.5` | `12` | `12` | `12.5` | `12` |
| `font.titleSize` | `14` | `14` | `14` | `15` | `13.5` | `14` | `14` | `14` |

#### Window

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `win.bg` | `#0A0A0B` | `#2B1D12` | `#121622 .88` | `#000000` | `#1A0E0A .95` | `#1E1C19` | `#131527` | `#231C14` |
| `win.bgTop` | none | none | none | none | none | none | `#171A2E` | `#2E251C` |
| `win.bgBottom` | none | none | none | none | none | none | `#0F1020` | `#18120D` |
| `win.bgTexture` | · | · | · | · | · | `UI-DialogBox-Background-Dark` | · | · |
| `win.bgDense` | `#0A0A0B` | `#2B1D12` | `#121622 .88` | `#000000` | `#1A0E0A .95` | `#1E1C19` | `#131527` | `#231C14` |
| `win.border` | `#202024` | `#6B4A22` | `#FFFFFF .18` | `#FFFFFF` | `#6A2E17` | `#FFFFFF` | `#B08A3E` | `#3A3530` |
| `win.borderSize` | `1` | `1` | `8` | `2` | `1` | `32` | `2` | `1` |
| `win.borderStyle` | `flat` | `flat` | `nine:Ka0s Glass` | `flat` | `flat` | `nine:Blizzard Dialog` | `flat` | `flat` |
| `win.inner` | none | `#8A6A36` | none | none | `#C98A3A .45` | none | `#3D2F12` | none |
| `win.radius` | `0` | `0` | `8` | `0` | `0` | `0` | `0` | `0` |
| `title.bg` | `#050506` | `#1A110A` | `#FFFFFF .06` | `#000000` | `#2F150D` | `#383838` | `#211C39` | `#050505` |
| `title.bgTop` | none | none | none | none | `#3A1A0F` | `#4B4B4B` | `#2A2347` | none |
| `title.bgBottom` | none | none | none | none | `#24100A` | `#252525` | `#17142B` | none |
| `title.text` | `#F2F2F4` | `#F5C542` | `#FFFFFF` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#FFFFFF` |
| `title.align` | · | · | · | · | · | · | `CENTER` | `CENTER` |
| `divider` | `#1C1C20` | `#6B4A22` | `#FFFFFF .12` | `#FFFFFF` | `#6A2E17` | `#6E6E6E` | `#4A3D1E` | `#2E2A26` |
| `foot.bg` | `#050506` | `#1A110A` | `#FFFFFF .04` | `#000000` | `#000000 .3` | `#000000 .3` | `#000000 .3` | `#050505` |
| `close.rest` | `#9B9BA4` | `#F5C542` | `#C9CFDB` | `#FFFFFF` | `#C7A993` | `#D9D9D9` | `#F6D27A` | `#FFFFFF` |
| `close.hot` | · | `#FF6B4A` | · | `#FF5050` | · | · | · | · |

#### Text

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `text.body` | `#E8E8EC` | `#E9DDBC` | `#F2F4F8` | `#FFFFFF` | `#F4E7DC` | `#FFFFFF` | `#F2EEF8` | `#FFFFFF` |
| `text.muted` | `#9B9BA4` | `#B8A07A` | `#C9CFDB` | `#E0E0E0` | `#C7A993` | `#B8B8B8` | `#B4AFC8` | `#A39E97` |
| `text.heading` | `#F2F2F4` | `#E2B659` | `#FFFFFF` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#F2B33D` |
| `text.headingAlt` | `#F2F2F4` | `#D4A84A` | `#FFFFFF` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#F2B33D` |
| `text.accent` | `#4DB8FF` | `#E2B659` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFD100` | `#B48CFF` | `#C9A07A` |
| `text.disabled` | `#6A6A72` | `#8A7A60` | `#8A90A0` | `#B0B0B0` | `#8A6E5C` | `#808080` | `#7A7590` | `#7A756E` |
| `text.link` | `#4DB8FF` | `#E2B659` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFD100` | `#B48CFF` | `#C9A07A` |
| `text.linkHot` | `#8FD3FF` | `#FFD866` | `#D4C4FF` | `#FFFFFF` | `#FFA36B` | · | `#D4BFFF` | `#E0C3A6` |
| `gtip.title` | · | `#F5C542` | · | `#FFE600` | `#FFB45A` | · | `#F6D27A` | `#FFD100` |
| `gtip.body` | · | `#E9DDBC` | · | `#FFFFFF` | · | · | · | · |
| `gtip.muted` | `#9B9BA4` | `#B8A07A` | `#C9CFDB` | `#E0E0E0` | `#C7A993` | `#B8B8B8` | `#B4AFC8` | `#A39E97` |
| `text.faint` | `#9B9BA4` | `#B8A07A` | `#C9CFDB` | `#E0E0E0` | `#C7A993` | `#B8B8B8` | `#B4AFC8` | `#A39E97` |
| `log.tag` | `#F2F2F4` | `#D4A84A` | `#FFFFFF` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#F2B33D` |
| `log.text` | `#E8E8EC` | `#E9DDBC` | `#F2F4F8` | `#FFFFFF` | `#F4E7DC` | `#FFFFFF` | `#F2EEF8` | `#FFFFFF` |
| `log.count` | `#9B9BA4` | `#B8A07A` | `#C9CFDB` | `#E0E0E0` | `#C7A993` | `#B8B8B8` | `#B4AFC8` | `#A39E97` |
| `text.value` | · | · | · | `#E0E0E0` | · | · | · | · |
| `text.bodyAlt` | · | · | · | `#FFFFFF` | · | · | · | · |
| `text.subtle` | · | · | · | `#FFFFFF` | · | · | · | · |
| `gtip.subtle` | · | · | · | `#E0E0E0` | · | · | · | · |

#### Buttons

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `btn.bg` | `#141416` | `#4A3218` | `#FFFFFF .08` | `#000000` | `#3A190E` | `#8B160A` | `#2C2452` | `#1F1D1B` |
| `btn.bgTop` | none | `#5A3D1D` | none | none | `#4A2012` | `#B3200F` | `#3A2F6B` | none |
| `btn.bgBottom` | none | `#3A2614` | none | none | `#2A120A` | `#640C05` | `#1D1838` | none |
| `btn.border` | `#2A2A30` | `#24160A` | `#FFFFFF .22` | `#FFFFFF` | `#8A3C1C` | `#1A0805` | `#B08A3E` | `#48433D` |
| `btn.borderSize` | `1` | `1` | `1` | `1` | `1` | `1` | `1` | `1` |
| `btn.borderStyle` | `flat` | `flat` | `flat` | `flat` | `flat` | `flat` | `flat` | `flat` |
| `btn.text` | `#E8E8EC` | `#F2E3BD` | `#F2F4F8` | `#FFFFFF` | `#FFCF9A` | `#FFD100` | `#F6D27A` | `#FFFFFF` |
| `btn.hover` | `#4DB8FF` | `#FFFFFF` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFFFFF` | `#FFFFFF` | `#C9A07A` |
| `btn.icon` | `#E8E8EC` | `#F2E3BD` | `#F2F4F8` | `#FFFFFF` | `#FFCF9A` | `#FFD100` | `#F6D27A` | `#FFFFFF` |
| `btn.radius` | `0` | `0` | `0` | `0` | `0` | `0` | `0` | `0` |
| `btnPrimary.bg` | `#2A86D1` | `#811A12` | `#B69CFF` | `#000000` | `#C3521E` | `#A91D0F` | `#5D43AE` | `#9C7A58` |
| `btnPrimary.bgTop` | none | `#A3241A` | none | none | `#E0662A` | `#D42A16` | `#7A5AD6` | none |
| `btnPrimary.bgBottom` | none | `#5E1009` | none | none | `#A63D12` | `#7E1007` | `#3F2C86` | none |
| `btnPrimary.border` | `#4DB8FF` | `#E2B659` | `#B69CFF` | `#FFE600` | `#FF9A5A` | `#E0B040` | `#F6D27A` | `#C9A07A` |
| `btnPrimary.borderSize` | `1` | `1` | `1` | `1` | `1` | `1` | `1` | `1` |
| `btnPrimary.borderStyle` | `flat` | `flat` | `flat` | `flat` | `flat` | `flat` | `flat` | `flat` |
| `btnPrimary.text` | `#FFFFFF` | `#FFD866` | `#1A1033` | `#FFE600` | `#FFFFFF` | `#FFFFFF` | `#FFFFFF` | `#FFFFFF` |
| `btnPrimary.hover` | `#D6EEFF` | `#FFFFFF` | `#3A2A66` | `#FFFFFF` | `#FFFFFF` | `#FFD100` | `#FFFFFF` | `#FFE9D2` |
| `btnPrimary.icon` | `#FFFFFF` | `#FFD866` | `#1A1033` | `#FFE600` | `#FFFFFF` | `#FFFFFF` | `#FFFFFF` | `#FFFFFF` |
| `btnPrimary.radius` | `0` | `0` | `0` | `0` | `0` | `0` | `0` | `0` |

#### Inputs

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `input.bg` | `#040405` | `#1C130B` | `#000000 .3` | `#000000` | `#140A07` | `#000000` | `#08091A` | `#0A0908` |
| `input.border` | `#26262B` | `#6B4A22` | `#FFFFFF .18` | `#FFFFFF` | `#5A2A16` | `#7A7A7A` | `#5A4A26` | `#3E3934` |
| `input.borderSize` | `1` | `1` | `1` | `1` | `1` | `1` | `1` | `1` |
| `input.borderStyle` | `flat` | `flat` | `flat` | `flat` | `flat` | `bevelIn` | `flat` | `flat` |
| `input.text` | `#E8E8EC` | `#E9DDBC` | `#F2F4F8` | `#FFFFFF` | `#F4E7DC` | `#FFFFFF` | `#F2EEF8` | `#FFFFFF` |
| `input.placeholder` | `#8A8A93` | `#8E7A58` | `#B8BFCC` | `#D0D0D0` | `#A88A76` | `#9A9A9A` | `#9A95B0` | `#8F8A83` |
| `input.focus` | `#4DB8FF` | `#E2B659` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFD100` | `#B48CFF` | `#C9A07A` |
| `input.radius` | `0` | `0` | `0` | `0` | `0` | `0` | `0` | `0` |
| `check.bg` | `#040405` | `#1C130B` | `#000000 .3` | `#000000` | `#140A07` | `#111111` | `#08091A` | `#0A0908` |
| `check.border` | `#34343B` | `#8A6A36` | `#FFFFFF .3` | `#FFFFFF` | `#8A3C1C` | none | `#B08A3E` | `#8A7A52` |
| `check.borderSize` | `1` | `1` | `1` | `1` | `1` | `0` | `1` | `1` |
| `check.borderStyle` | `flat` | `flat` | `flat` | `flat` | `flat` | `flat` | `flat` | `flat` |
| `check.mark` | `#4DB8FF` | `#E2B659` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFD100` | `#F6D27A` | `#C9A07A` |
| `check.radius` | `0` | `0` | `0` | `0` | `0` | `0` | `0` | `0` |
| `check.texture` | · | · | · | · | · | `UI-CheckBox-Up` | · | · |
| `check.markTexture` | · | · | · | · | · | `UI-CheckBox-Check` | · | · |
| `slider.track` | `#202024` | `#5A3D1D` | `#FFFFFF .15` | `#FFFFFF` | `#4A2416` | `#3A3A3A` | `#2C2550` | `#3A3632` |
| `slider.trackBorder` | `#000000 0` | `#000000 0` | `#000000 0` | `#000000 0` | `#000000 0` | `#000000 0` | `#000000 0` | `#000000 0` |
| `slider.fill` | `#4DB8FF` | `#C0392B` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#C9A24A` | `#B48CFF` | `#C9A07A` |
| `slider.thumb` | `#F2F2F4` | `#E2B659` | `#FFFFFF` | `#FFFFFF` | `#FFCF9A` | `#C9A84A` | `#F6D27A` | `#C9A07A` |
| `scroll.track` | `#1C1C20` | `#000000 .35` | `#FFFFFF .08` | `#262626` | `#2E1810` | `#000000` | `#22224A` | `#0A0806` |
| `scroll.thumb` | `#4DB8FF .9` | `#8A6A36` | `#FFFFFF .5` | `#FFFFFF` | `#FF7A33 .9` | `#FFD100 .9` | `#F6D27A .9` | `#C9A07A` |
| `scroll.thumbOn` | `#4DB8FF .9` | `#8A6A36` | `#FFFFFF .6` | · | `#FF7A33 .9` | `#FFD100 .9` | `#F6D27A` | `#C9A07A` |
| `scroll.thumbOff` | `#3A3A42` | `#8A6A36` | `#FFFFFF .25` | `#808080` | `#8A3C1C` | `#9A7B2A` | `#B08A3E` | `#6E5A46` |
| `scroll.radius` | `0` | `0` | `0` | `0` | `0` | `0` | `0` | `0` |

#### Tabs and navigation

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `tab.bg` | `#000000 0` | `#3A2614` | `#000000 0` | `#000000` | `#2A140C` | `#262626` | `#1A1730` | `#000000 0` |
| `tab.bgTop` | none | none | none | none | none | none | none | none |
| `tab.bgBottom` | none | none | none | none | none | none | none | none |
| `tab.glow` | `#FFFFFF .06` | `#FFFFFF .1` | · | `#FFFFFF .25` | · | · | · | · |
| `tab.text` | `#9B9BA4` | `#CDB78A` | `#C9CFDB` | `#FFFFFF` | `#C7A993` | `#C9B048` | `#B4AFC8` | `#A39E97` |
| `tab.border` | `#000000 0` | `#24160A` | `#000000 0` | `#FFFFFF` | `#5A2A16` | `#7A7A7A` | `#5A4A26` | `#000000 0` |
| `tab.borderSize` | `1` | `1` | `1` | `1` | `1` | `2` | `1` | `1` |
| `tab.borderStyle` | `flat` | `flat` | `flat` | `flat` | `flat` | `bevelOut` | `flat` | `flat` |
| `tab.onBg` | `#000000 0` | `#7A1A10` | `#B69CFF .1` | `#000000` | `#4A2012` | `#4A4A4A` | `#2C2550` | `#000000 .4` |
| `tab.onText` | `#F2F2F4` | `#FFD866` | `#FFFFFF` | `#FFE600` | `#FFB45A` | `#FFFFFF` | `#F6D27A` | `#FFFFFF` |
| `tab.onLine` | `#4DB8FF` | `#000000 0` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#000000 0` | `#B48CFF` | `#C9A07A` |
| `tab.rule` | `#1C1C20` | `#6B4A22` | `#FFFFFF .12` | `#FFFFFF` | `#6A2E17` | `#6E6E6E` | `#4A3D1E` | `#2E2A26` |
| `tab.radius` | `0` | `0` | `0` | `0` | `0` | `0` | `0` | `0` |
| `tab.texture` | · | · | · | · | · | `UI-OptionsFrame-ActiveTab` | · | · |
| `tab.onTexture` | · | · | · | · | · | `UI-OptionsFrame-ActiveTab` | · | · |
| `nav.bg` | `#000000 0` | `#000000 .25` | `#000000 0` | `#000000` | `#000000 .3` | `#000000 .4` | `#000000 .3` | `#000000 .3` |
| `nav.border` | `#000000 0` | `#6B4A22` | `#000000 0` | `#FFFFFF` | `#5A2A16` | `#6E6E6E` | `#4A3D1E` | `#000000 0` |
| `nav.borderSize` | `1` | `1` | `1` | `1` | `1` | `1` | `1` | `1` |
| `nav.borderStyle` | `flat` | `flat` | `flat` | `flat` | `flat` | `bevelIn` | `flat` | `flat` |
| `nav.text` | `#9B9BA4` | `#E2B659` | `#C9CFDB` | `#FFFFFF` | `#C7A993` | `#FFD100` | `#F6D27A` | `#D8D3CB` |
| `nav.selBg` | `#FFFFFF .06` | `#7A1A10` | `#FFFFFF .12` | `#FFE600` | `#FF7A33 .2` | `#5A78DC .38` | `#B48CFF .25` | `#FFFFFF .07` |
| `nav.selText` | `#F2F2F4` | `#FFE7A8` | `#FFFFFF` | `#000000` | `#FFE2C4` | `#FFFFFF` | `#FFFFFF` | `#FFFFFF` |
| `nav.selBar` | `#4DB8FF` | `#000000 0` | `#000000 0` | `#000000 0` | `#FF7A33` | `#000000 0` | `#B48CFF` | `#C9A07A` |

#### Drawers and menus

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `drawer.bg` | `#101012` | `#3A2614` | `#FFFFFF .05` | `#000000` | `#2A140C` | `#262626` | `#1A1730` | `#1C1A17` |
| `drawer.bgOpen` | `#141416` | `#4A3018` | `#FFFFFF .09` | `#000000` | `#4A2012` | `#3A3A3A` | `#2C2550` | `#24211E` |
| `drawer.border` | `#202024` | `#6B4A22` | `#FFFFFF .14` | `#FFFFFF` | `#6A2E17` | `#6E6E6E` | `#5A4A26` | `#2E2A26` |
| `drawer.borderOpen` | `#4DB8FF .6` | `#E2B659 .6` | `#B69CFF .6` | `#FFE600` | `#FF7A33 .6` | `#FFD100 .6` | `#B48CFF .6` | `#C9A07A .6` |
| `drawer.borderSize` | `1` | `1` | `1` | `1` | `1` | `2` | `1` | `1` |
| `drawer.borderStyle` | `flat` | `flat` | `flat` | `flat` | `flat` | `bevelOut` | `flat` | `flat` |
| `drawer.boxBg` | `#0A0A0B` | `#1C130B` | `#000000 .2` | `#000000` | `#140A07` | `#111111` | `#08091A` | `#0A0908` |
| `drawer.boxBorder` | `#202024` | `#6B4A22` | `#FFFFFF .14` | `#FFFFFF` | `#6A2E17` | `#6E6E6E` | `#5A4A26` | `#2E2A26` |
| `drawer.text` | `#E8E8EC` | `#E9DDBC` | `#F2F4F8` | `#FFFFFF` | `#F4E7DC` | `#FFFFFF` | `#F2EEF8` | `#FFFFFF` |
| `drawer.textSet` | `#4DB8FF` | `#E2B659` | `#B69CFF` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#F2B33D` |
| `drawer.summary` | `#9B9BA4` | `#B8A07A` | `#C9CFDB` | `#E0E0E0` | `#C7A993` | `#B8B8B8` | `#B4AFC8` | `#A39E97` |
| `drawer.summarySet` | `#A8DBFF` | `#E2B659` | `#D4C4FF` | `#FFE600` | `#FFCF9A` | · | `#F6D27A` | `#E0C3A6` |
| `menu.bg` | `#0A0A0B` | `#2B1D12` | `#121622 .92` | `#000000` | `#1A0E0A .97` | `#1E1C19` | `#131527` | `#231C14` |
| `menu.border` | `#2C2C32` | `#6B4A22` | `#FFFFFF .18` | `#FFE600` | `#8A3C1C` | `#FFFFFF` | `#B08A3E` | `#3A3530` |
| `menu.borderAlt` | `#2C2C32` | `#6B4A22` | `#FFFFFF .18` | `#FFE600` | `#8A3C1C` | `#FFFFFF` | `#B08A3E` | `#3A3530` |
| `menu.borderSize` | `1` | `2` | `8` | `2` | `1` | `16` | `2` | `1` |
| `menu.borderStyle` | `flat` | `flat` | `nine:Ka0s Glass` | `flat` | `flat` | `nine:Blizzard Dialog` | `flat` | `flat` |
| `menu.hover` | `#4DB8FF .15` | `#E2B659 .15` | `#B69CFF .15` | `#FFE600 .25` | `#FF7A33 .15` | `#FFD100 .15` | `#B48CFF .15` | `#C9A07A .15` |
| `menu.text` | `#E8E8EC` | `#E9DDBC` | `#F2F4F8` | `#FFFFFF` | `#F4E7DC` | `#FFFFFF` | `#F2EEF8` | `#FFFFFF` |
| `menu.textSel` | `#4DB8FF` | `#E2B659` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFD100` | `#B48CFF` | `#C9A07A` |

#### Lists and cards

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `list.header.bg` | `#101012` | `#3A2614` | `#FFFFFF .06` | `#1A1A1A` | `#FF7A33 .08` | `#FFFFFF .07` | `#B48CFF .08` | `#000000 .35` |
| `list.header.text` | `#9B9BA4` | `#E2B659` | `#C9CFDB` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#FFFFFF` |
| `list.stripe` | `#FFFFFF .02` | `#E9DDBC .04` | `#FFFFFF .03` | `#0D0D0D` | `#FFFFFF .025` | `#FFFFFF .03` | `#FFFFFF .025` | `#FFFFFF .025` |
| `list.hover` | `#E8E8EC .1` | `#E9DDBC .1` | `#F2F4F8 .1` | `#FFE600 .2` | `#F4E7DC .1` | `#FFFFFF .1` | `#F2EEF8 .1` | `#FFFFFF .1` |
| `list.sel` | `#4DB8FF .14` | `#A3241A .35` | `#B69CFF .24` | `#000000` | `#FF7A33 .18` | `#FFD100 .18` | `#B48CFF .2` | `#C9A07A .16` |
| `list.selOutline` | · | · | · | `#FFE600` | · | · | · | · |
| `card.bg` | `#101012` | `#3A2614` | `#FFFFFF .06` | `#000000` | `#2A140C .85` | `#000000 .4` | `#1A1730 .85` | `#1C1A17` |
| `card.border` | `#202024` | `#6B4A22` | `#FFFFFF .14` | `#FFFFFF` | `#5A2A16` | `#6E6E6E` | `#4A3D1E` | `#2E2A26` |
| `panel.bg` | `#070708` | `#000000 .2` | `#FFFFFF .04` | `#000000` | `#000000 .3` | `#000000 .3` | `#000000 .3` | `#000000 .3` |
| `panel.border` | `#1C1C20` | `#6B4A22` | `#FFFFFF .12` | `#FFFFFF` | `#5A2A16` | `#6E6E6E` | `#4A3D1E` | `#2E2A26` |
| `section.rule` | `#4DB8FF .35` | `#E2B659 .35` | `#B69CFF .35` | `#FFE600` | `#FF7A33 .35` | `#FFD100 .35` | `#B48CFF .35` | `#C9A07A .35` |
| `icon.tint` | `#9B9BA4` | `#B8A07A` | `#C9CFDB` | `#E0E0E0` | `#C7A993` | `#B8B8B8` | `#B4AFC8` | `#A39E97` |
| `icon.hot` | `#4DB8FF` | `#E2B659` | `#FFFFFF` | `#FFE600` | `#FFB45A` | `#FFD100` | `#F6D27A` | `#C9A07A` |
| `icon.arrow` | `#4DB8FF` | `#E2B659` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFD100` | `#B48CFF` | `#C9A07A` |
| `handle.edge` | `#4DB8FF .6` | `#E2B659 .6` | `#B69CFF .6` | `#FFE600 .6` | `#FF7A33 .6` | `#FFD100 .6` | `#B48CFF .6` | `#C9A07A .6` |
| `handle.rest` | `#9B9BA4` | `#B8A07A` | `#C9CFDB` | `#E0E0E0` | `#C7A993` | `#B8B8B8` | `#B4AFC8` | `#A39E97` |
| `list.dropLine` | `#4DB8FF .9` | `#E2B659 .9` | `#B69CFF .9` | `#FFE600 .9` | `#FF7A33 .9` | `#FFD100 .9` | `#B48CFF .9` | `#C9A07A .9` |
| `list.ghostBg` | `#0A0A0B` | `#2B1D12` | `#121622 .92` | `#000000` | `#1A0E0A .97` | `#1E1C19` | `#131527` | `#231C14` |
| `list.box` | `#E8E8EC .06` | `#E9DDBC .06` | `#F2F4F8 .06` | `#FFFFFF .06` | `#F4E7DC .06` | `#FFFFFF .06` | `#F2EEF8 .06` | `#FFFFFF .06` |
| `list.boxDim` | `#E8E8EC .03` | `#E9DDBC .03` | `#F2F4F8 .03` | `#FFFFFF .03` | `#F4E7DC .03` | `#FFFFFF .03` | `#F2EEF8 .03` | `#FFFFFF .03` |
| `list.boxEdge` | `#E8E8EC .12` | `#E9DDBC .12` | `#F2F4F8 .12` | `#FFFFFF .12` | `#F4E7DC .12` | `#FFFFFF .12` | `#F2EEF8 .12` | `#FFFFFF .12` |
| `list.boxEdgeDim` | `#E8E8EC .06` | `#E9DDBC .06` | `#F2F4F8 .06` | `#FFFFFF .06` | `#F4E7DC .06` | `#FFFFFF .06` | `#F2EEF8 .06` | `#FFFFFF .06` |
| `icon.dim` | · | · | · | `#B0B0B0` | · | · | · | · |

#### Overlays

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `popup.bg` | `#0A0A0B` | `#2B1D12` | `#121622 .92` | `#000000` | `#1A0E0A .97` | `#1E1C19` | `#131527` | `#231C14` |
| `popup.border` | `#2C2C32` | `#6B4A22` | `#FFFFFF .18` | `#FFE600` | `#8A3C1C` | `#FFFFFF` | `#B08A3E` | `#3A3530` |
| `popup.borderSize` | `1` | `2` | `8` | `2` | `1` | `16` | `2` | `1` |
| `popup.borderStyle` | `flat` | `flat` | `nine:Ka0s Glass` | `flat` | `flat` | `nine:Blizzard Dialog` | `flat` | `flat` |
| `popup.radius` | `0` | `0` | `8` | `0` | `0` | `0` | `0` | `0` |
| `tooltip.bg` | `#070708` | `#1C130B` | `#0F121C .92` | `#000000` | `#140A07` | `#000010 .92` | `#0A0A1A .95` | `#0E0D0B` |
| `tooltip.border` | `#2C2C32` | `#6B4A22` | `#FFFFFF .18` | `#FFFFFF` | `#8A3C1C` | `#9A9A9A` | `#B08A3E` | `#3A3530` |

#### HUD

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `bar.texture` | `Ka0s Matte` | `Ka0s Parchment` | `Ka0s Glass Bar` | `Ka0s Solid` | `Ka0s Forge` | `Blizzard` | `Ka0s Satin` | `Ka0s Classic` |
| `bar.gloss` | none | · | `true` | none | · | · | · | none |
| `hud.font` | `Friz Quadrata TT` | `Friz Quadrata TT` | `Friz Quadrata TT` | `Friz Quadrata TT` | `Friz Quadrata TT` | `Friz Quadrata TT` | `Friz Quadrata TT` | `Friz Quadrata TT` |

#### Semantic

| Token | Obsidian | Azeroth | Glass | High Contrast | Ember | WoW Default | WoW Midnight | WoW Forever |
|---|---|---|---|---|---|---|---|---|
| `q.uncommon` | · | · | `#5CFF5C` | `#5CFF5C` | · | · | · | · |
| `q.rare` | · | · | `#5AA9FF` | `#6DB6FF` | · | · | · | · |
| `q.epic` | · | · | `#C58BFF` | `#D199FF` | · | · | · | · |
| `sem.stepReady` | `#E8E8EC` | `#E9DDBC` | `#F2F4F8` | `#FFFFFF` | `#F4E7DC` | `#FFFFFF` | `#F2EEF8` | `#FFFFFF` |
| `sem.stepBusy` | `#4DB8FF` | `#E2B659` | `#B69CFF` | `#FFE600` | `#FF7A33` | `#FFD100` | `#B48CFF` | `#C9A07A` |
| `sem.stepLocked` | `#6A6A72` | `#8A7A60` | `#8A90A0` | `#B0B0B0` | `#8A6E5C` | `#808080` | `#7A7590` | `#7A756E` |
| `sem.boundNone` | · | · | · | `#B0B0B0` | · | · | · | · |
| `sem.boundBoE` | · | · | · | `#FFFFFF` | · | · | · | · |
| `sem.boundNoneAlt` | · | · | · | `#B0B0B0` | · | · | · | · |
| `sem.unknown` | · | · | · | `#B0B0B0` | · | · | · | · |

`gtip.value` is in no row: every skin inherits Ka0s Default's white.

Tokens each skin sets of its own (re-counted from the live tables at SkinDefs minor 9): Obsidian 149, Azeroth 150, Glass 150, High Contrast 165, Ember 147, WoW Default 148, WoW Midnight 148, WoW Forever 149.

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

## AceGUI rows

`SkinAce.lua` (minor 1, Ka0sAddonsCommonTasks `docs/2026-10-25-SKINNING/` item LK-08). AceGUI keeps
**one pool per widget type for the whole client**: a CheckBox one Ka0s page releases can be the next
one another addon's options acquire. So an AceGUI row is painted outside the frame registry, for
exactly one acquisition, and is **never repainted in place**.

**Where it is painted.** One choke point: the Options major hands each instance to
`__AttachSkinAce(O, d)` (internal) when it resolves AceGUI (`lib:New`, `CreateOptionsPanel`), which,
once `d.addonName` is a registered owner, replaces `O.AceGUI` with a **proxy**: its `Create(type)` is
AceGUI's own Create followed by `PaintAce(d.addonName, widget)`; every other field and method is
AceGUI's (a method called on the proxy runs on AceGUI itself; a write lands on AceGUI). An
unregistered name, no name, no AceGUI or no `SkinAce.lua` leave `O.AceGUI` as AceGUI itself. A host
that acquires a widget another way paints it with `PaintAce` or `PaintAceTree`.

**What a paint does.** Only for a registered owner away from Ka0s Default (Ka0s Default is stock
AceGUI, as today: nothing is painted and nothing is wrapped). Stock regions are faded by alpha, their
prior alpha recorded; fonts, text and vertex colors and backdrops are recorded before the first
change; Ka0s overlays are textures made **once per widget object** and reused by every later
acquisition. State lives in the weak `lib.__ace` table (not contract); the only things written onto a
widget's table are the release wrapper and the durability post-hooks below.

| Widget | What its owner's skin paints |
|---|---|
| `CheckBox` | The stock box, check and highlight faded; a box over the stock box's place (`check.texture` art or `check.bg`, a `check.border` edge) and a mark inside it (`check.markTexture` or `check.mark`) shown while AceGUI shows its check, at half alpha while disabled or in the tri-state's unknown value; the label `text.body` (`text.disabled`), the description `text.muted`; the body font |
| `Slider` | The bar's backdrop flattened into `slider.track` / `slider.trackBorder` (when the skin sets a track), the thumb `slider.thumb`; the edit box's backdrop into `input.bg` / `input.border`, its text `input.text`; the label `text.body`, the range labels `text.muted` |
| `Dropdown` | The template's pieces faded; a box over the 25px bar AceGUI clicks (`button_cover`) in `input.bg` / `input.border`; the value `input.text`, the label `text.body`. Its **pull-out** is painted on open for the dropdown's owner (`menu.bg` / `menu.border`, the items' text `menu.text`, their highlight `menu.hover`, the scroll thumb `scroll.thumb`) and put back on close, on `Clear` and on the dropdown's release |
| `EditBox` | The template's pieces faded; a box in `input.bg` / `input.border` (`input.focus` while it has the keys); the text `input.text`; the label `text.body`; its "Okay" button as a `Button` |
| `MultiLineEditBox` | The scroll backdrop into `input.bg` / `input.border`; the text `input.text`; the label `text.body`; its button as a `Button` |
| `Button` | The template's art faded; a box in `btn.bg` (its gradient) / `btn.border`; the label `btn.text`, `btn.hover` under the pointer, `text.disabled` while disabled |
| `Heading` | The label `text.heading`; the two stock rules faded and redrawn as 1px `section.rule` lines |
| `Label`, `InteractiveLabel`, `Icon` | The label `text.body` and the body font (a color the host sets after acquiring wins) |
| `ColorPicker` | The label `text.body`; a 1px `input.border` edge around the swatch |
| `InlineGroup` | The title `text.heading`; the border frame's backdrop into `panel.bg` / `panel.border` |
| `ScrollFrame` | The bar's stock background faded under a `scroll.track` region (the always-shown thumb is Options' own) |

`SimpleGroup` has no art and no painter. **Stock, always:** LSM30_* widgets and their pull-out lists,
TabGroup, and Blizzard's `ColorPickerFrame` (the spec's non-goals). Every field is guarded: a widget
type or a field a later AceGUI drops is skipped.

**The release.** `PaintAce` chains the restore onto the widget's own `OnRelease` (`Skin:OnRelease`):
before AceGUI's own `OnRelease` runs, every recorded alpha, font, color and backdrop goes back, every
overlay hides, the pull-out is put back and the owner entry clears. The wrapper puts the previous
`OnRelease` back first, restores under pcall (a failure is logged once through the error handler) and
always calls the previous one, because `AceGUI:Release` calls `OnRelease` raw: a failing restore never
keeps a widget out of the pool. A widget whose wrapper a host replaced outright comes back through the
proxy still owned, and is put back before it is painted again.

**Durable.** AceGUI recolors a widget's text from `SetDisabled` (a CheckBox's `SetValue` calls it), the
Slider recolors its edit box's edge on enter and leave, a CheckBox's `SetType` resizes its box, and a
Label's `SetFontObject` sets a new font. Each is post-hooked **once per widget object**
(`hooksecurefunc` / `HookScript`), and the hook re-applies the owner's tokens only while the widget is
owned; a hook that rides the widget into another addon's hands does nothing there. A Label's
`SetFontObject` first makes the host's new font the one its release puts back.

**A skin switch** never walks AceGUI rows. The Options instance re-renders its owner's open pages one
frame later (`OptionsScroll.lua` minor 6): the re-render releases every row, which gives it back stock,
and acquires fresh ones, painted in the new skin (or left alone under Ka0s Default).

**Other skinning addons.** A widget ElvUI or AddOnSkins already skinned (a frame carrying their
`backdrop`, `template` or `isSkinned` mark) is left to them: `PaintAce` answers false.

**Under `eui`.** A pooled widget is never handed to an EllesmereUI primitive (*The EllesmereUI
provider*): the painting is this file's, from the provider's derived tokens.

Cases: `tests/test_skin_ace.lua`, on a pooled AceGUI fake with AceGUI's anatomy
(`tests/fixture_skin_ace.lua`).

## What is not here

- **No routing yet.** The library's own windows, widgets and settings chrome still paint with
  their constants; they take an owner and route through the primitives in later files of this
  release's run.
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
`eui` is a stored choice on the owner's Ka0s skin and nothing is registered with EllesmereUI. Without
`SkinAce.lua` (which needs `SkinPaint.lua`'s helpers from the same copy) no AceGUI row is painted and
no Options instance's `O.AceGUI` is wrapped. The engine's state is written `lib.x = lib.x or {}`, so a newer copy that wins
the LibStub race later keeps every owner, record and facade; the resolve cache alone is rebuilt.
