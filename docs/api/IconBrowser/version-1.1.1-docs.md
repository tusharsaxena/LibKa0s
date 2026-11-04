# `LibKa0s-IconBrowser-1.0` — version 1.1.1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the IconBrowser surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-IconBrowser-1.0` |
| Files and minors | `IconBrowserSources.lua` minor **1** · `IconBrowserWindow.lua` minor **1** · `IconBrowser.lua` minor **1** |
| Shipped in | v1.86.0 |
| Status | **Current** |
| Supersedes | [version 1](./version-1-docs.md) (never shipped) — the sources alone, before the browser window joined the major. |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` ≥ 1 and `LibKa0s-Media-1.0` ≥ 5 (the shell's floors); the browser needs the host's LibKa0s Options instance (`spec.helpers`) and AceGUI-3.0 through it |
| Optional at call time | `LibKa0s-Compat-1.0` (the macro lists' secret guard), `LibKa0s-Skin-1.0` (the owner's facade and the four owner tokens), `LibKa0s-Widgets-1.0` (`CopyWindow`, the Wowhead link window) |
| Confirm in-game | `LibStub("LibKa0s-IconBrowser-1.0").MODULES` → `{ IconBrowserSources = 1, IconBrowserWindow = 1, IconBrowser = 1 }` |

## What changed at this version: the browser window joins the major

`IconBrowserWindow.lua` and `IconBrowser.lua` are new, each paired on the shell's minor
(`__windowMinor` / `__windowShellMinor`, `__browserMinor` / `__browserShellMinor`). They are Quick
Comms' `settings/IconBrowser.lua`, the part of its `settings/ModalWindow.lua` the browser uses and
its window icon edge (`modules/IconStyle.lua`), with every Quick Comms dependency turned into a
`spec` field. New members: `New`, `SKIN_TOKENS`, `WOWHEAD_ICONS`, and the browser's words in
`STRINGS`. `IconBrowserSources.lua` is unchanged.

## What this major is

**The icon browser's sources**: what each tab of an icon browser offers, what it calls an icon, the
search over it, the client's macro icon lists, and the stored shape of a glyph pick. Pure: it draws
nothing.

Promoted from Ka0s Quick Comms (`settings/IconBrowser_Sources.lua`, the glyph helpers of its
`modules/Library.lua` and its `Compat.MacroIcons`), because Outfitter Reborn wants the same browser
with the same semantics (`library-stack-§7`, *What earns promotion*). The one change on the way in is
that **a tab is a descriptor**, so a host adds tabs of its own and hides built-in ones.

## Members

Read straight off the LibStub table. Every function is dot-called.

| Name | Since | Meaning |
|---|---|---|
| `BUILTIN_TABS` | 1 | `{ "markers", "game", "glyphs" }`, the built-in tabs' keys in their order. |
| `Sources` | 1 | The sources table (below). |
| `IsGlyph(path)` | 1 | The Media catalog name (`"ph:arrow-up"`) of a glyph path at **any** host's folder, else nil: a texture id, a raid marker, any other texture. Checked by building the path back with `Media.Icon`, and kept per path for the session. |
| `ValidColor(hex)` | 1 | `true` for none (nil, false) or six lowercase hex digits; else `false, "badColor"`. |
| `ColorFrom(r, g, b)` | 1 | The stored color for a picked r, g, b (0..1, clamped): six lowercase hex digits, or `false` for white. |
| `Tint(hex)` | 1 | `r, g, b` (0..1) for a stored color; white (1, 1, 1) for none or a malformed one. |
| `MacroIcons(kind)` | 1 | The macro icon selector's texture ids for `"spells"` (`GetLooseMacroIcons`, then `GetMacroIcons`) or `"items"` (`GetLooseMacroItemIcons`, then `GetMacroItemIcons`): plain numbers only, repeats kept. A reader that is absent, raises or has not loaded adds nothing; any other kind answers `{}`. |
| `STRINGS` | 1 | Every word the major can show (the browser's joined at 1.1.1: `HEADER`, `CHOOSE`, `CANCEL`, `COMBAT`, `HINT`, `COUNT`, `COUNT_OF` and the rest), by key (`TAB_MARKERS`, `TEXTURE_ID`, `MARKER_1`..`MARKER_8`, `SET_*`, `GLYPH_*` and the rest). A host overrides any of them with `spec.L`, read with `rawget`, so a locale table that answers its own key is ignored. |
| `GLYPH_LABELS` | 1 | The curated glyphs' labels: catalog name → `STRINGS` key. Every other glyph is labeled from its name. |
| `MAJOR` · `MINOR` | 1 | `"LibKa0s-IconBrowser-1.0"` and the live minor. |
| `MODULES` | 1 | `{ IconBrowserSources = <minor>, IconBrowserWindow = <minor>, IconBrowser = <minor> }`: the value that picks this document. |
| `New(spec)` | 1.1.1 | Colon-called: `IB:New(spec)` → a browser (below). Raises when `spec.owner` or `spec.helpers` is missing. |
| `SKIN_TOKENS` | 1.1.1 | The four owner tokens the browser draws in (below). |
| `WOWHEAD_ICONS` | 1.1.1 | `"https://www.wowhead.com/icons"`, the address the Game icons hint's button shows. |

### The tab descriptor

```lua
{
  key     = "rec",                      -- unique within the tabs
  label   = "Recommended",              -- the strip's text
  tooltip = "...",                      -- optional
  list    = function(filter) return icons, loaded end,
  name    = function(icon) return "..." end,   -- optional: what the tab calls an icon
  search  = function(icon) return "..." end,   -- optional: the text a search reads
  owns    = function(icon) return true end,    -- optional: a stored icon opens on this tab
  swatch  = false,                      -- optional: the tab's icons take a color
}
```

`icons` is a list of icon **values**: a texture path or a texture id, never a table per icon. A
`loaded` of `false` says the client has not answered yet; nil reads as loaded. A descriptor without
a string `key` or a `list` function is skipped.

The built-ins:

| Key | Lists | `filter` | `swatch` |
|---|---|---|---|
| `markers` | the eight raid target markers, `Interface\TargetingFrame\UI-RaidTargetingIcon_1`..`_8` | ignored | no |
| `game` | `GameIcons(filter)`: both macro lists, spells first, each id once | `"all"`, `"spells"`, `"items"` | no |
| `glyphs` | `Glyphs(owner, filter)`: the Media catalog at the host's folder | `"all"` or a set id | yes |

### `Sources`

| Name | Since | Meaning |
|---|---|---|
| `Tabs(spec)` | 1 | The tabs a host is offered: `spec.tabs` first in the host's order (a repeated key keeps the first), then the built-ins `spec.hide` (`{ markers = true, ... }`) does not name and no host tab replaced. `spec.owner` is the host's folder, the glyph tab's paths; `spec.L` its override of `STRINGS`. The built-ins are built once per owner and `L`, so a descriptor keeps its identity for the session. |
| `TabFor(icon, tabs)` | 1 | The key of the first of `tabs` whose `owns(icon)` is true, else nil. Host tabs come first, so they are asked first. |
| `List(tab, filter)` | 1 | `tab.list(filter)`: `icons, loaded`, `loaded` true unless the descriptor answered `false`. |
| `Label(tab, icon)` | 1 | `tab.name(icon)` when it answers a string, else `"Texture id N"` for a texture id, else the path (`""` for nil). `tab` may be nil. |
| `Search(list, tab, query)` | 1 | The icons of `list` whose text on `tab` holds `query`: case-insensitive, plain text, trimmed; a blank query answers `list` itself. The text is `tab.search(icon)`, else `tab.name(icon)` (with a texture id's digits), else the id's digits or the path. Memoized per list and tab (weak), and a query that holds the last one narrows the last results. |
| `Markers()` · `MarkerPath(i)` | 1 | The eight markers' paths; one marker's. |
| `Glyphs(owner, set)` | 1 | The catalog's glyph paths at `owner`'s folder: every one (`set` nil or `"all"`) or one set's. The same table on every call for the same owner and set; `{}` without an owner. |
| `GlyphSets(L)` | 1 | `{ id, label, prefix }` for each of `Media.ICON_SETS`, in its order. |
| `GlyphLabel(name, L)` | 1 | A catalog name's label: the curated one, else the name without its set's prefix, dashes as spaces, first letter capitalized (`"ph:arrow-up"` → `"Arrow up"`). |
| `SetOf(icon)` | 1 | The set id of a glyph path, else nil. |
| `Credit(icon, L)` | 1 | The set's shown name for a glyph path, with its author where the set's license asks (`"Game-icons, by Lorc"`), else nil. |
| `GameIcons(filter)` | 1 | The game list for `filter`, and whether it is loaded. Kept once the client answered with icons; an empty answer is asked again on the next call. |

## The browser (`IB:New(spec)`)

```lua
local browser = IB:New({
  owner   = "MyAddon",          -- required: the host's folder (its skin owner, its glyphs' path)
  helpers = O,                  -- required: the host's LibKa0s Options instance
  title   = "Ka0s My Addon",    -- the window's title: the host's brand
  layers  = { strata = "FULLSCREEN", level = 1200, over = 1400, popup = "FULLSCREEN_DIALOG" },
  tabs    = { recommended },    -- host tab descriptors, shown first
  hide    = { markers = true }, -- built-in tabs not offered
  L       = L,                  -- overrides of STRINGS, read with rawget
  name    = "MyAddonIconBrowser",
  print   = function(line) end, -- the combat refusal's chat line
  inCombat = function() return InCombatLockdown() end,
  schedule = function(sec, fn) return handle end,
  copyWindow = function(d) return window end,
  trackPicker = function(swatch) end, releasePicker = function(swatch) end,
})
```

Only `owner` and `helpers` are required. `layers`: the catcher and the window sit in `strata`
(default `DIALOG`), at a band of levels whose base is UIParent's level plus `over` when given (a
browser over another modal of the host's) else `level`: the catcher at the base, the template's
background +1, the window +2, the page +3, the close X +5. `popup` (default: the strata over
`strata`) is where the Wowhead link window goes. `name` defaults to the owner's folder and
`IconBrowser`, numbered from an owner's second browser. Without `inCombat` the client's
`InCombatLockdown` is read; without `schedule`, `C_Timer.After`; without `copyWindow`,
`LibKa0s-Widgets-1.0`'s `CopyWindow` (the owner's folder as its `addonName`); without
`trackPicker` / `releasePicker`, the browser hides a color picker its own swatch opened.

The browser is built on its first Open, once. Each browser holds its own selection, search, filter,
glyph set and window: two browsers share nothing.

| Method | Meaning |
|---|---|
| `Open(req)` | `req = { icon, color, onChoose(icon, color|nil), owner, lift = { names }, valid() }`. Replaces an open request. The first tab whose `owns` answers for `icon` (host tabs first) is opened, scrolled to it and the icon selected; an icon no tab owns, or none, opens the first tab with nothing selected. `color` is kept only for a glyph and only when valid. `lift` names the opener's special frames, taken out of `UISpecialFrames` while open and put back on the next frame after. Answers false while stood down, without AceGUI, or with no tab offered. |
| `Choose()` | `true`, or `false` and `"notOpen"` / `"combat"` / `"noSelection"`. Hands `onChoose` the icon and, for a glyph, its color (`"rrggbb"`, nil for white), then closes. In combat nothing is handed out, the browser stays open and `spec.print` gets one gray line. An opener whose `valid` answers false closes it and answers `"notOpen"`. |
| `Cancel(owner?)` | Close without choosing; with `owner`, only a browser opened for that `req.owner`. The close X, Escape and a hide of the window are a Cancel. |
| `Revalidate()` | Close when the open request's `valid` answers false. The library registers no bus message: the host calls this (or Cancel) from its own handlers. |
| `IsOpen()` | Whether a request is open. |
| `Select(icon)` | Select `icon` (nil clears). |
| `SetTab(key)` | Show a tab the host is offered; a hidden built-in's key is refused. |
| `SetFilter(key)` | Game icons: `"all"`, `"spells"`, `"items"`. |
| `SetGlyphSet(key)` | Glyphs: `"all"` or a set id; an unknown one is refused. |
| `SetSearch(text)` | Filter the shown tab (Sources.Search), from the top; kept for the session. |
| `SetColor(hex)` | The glyph color, `"rrggbb"` or nil; a malformed one is refused. |
| `ScrollTo(row)` | Scroll the grid. |
| `State()` | `{ tab, filter, glyphSet, selected, color, offset, count, total, search, loaded, owner }`, nil while closed. |
| `Widgets()` | The toolbar's, grid's and footer's parts, for tests; nil before the first Open. |
| `LinkWindow()` | The Wowhead copy window, built on first use, in `layers.popup`. |
| `StandDown()` · `StandUp()` | The host's lifecycle: a stand-down closes the browser and refuses Open until the stand-up. |

Fields: `tabs` (the descriptors offered, in order), `cells` (the `COLS` × `ROWS` virtualized cells,
each with `ibIcon`), `COLS` (12), `ROWS` (7), `GRID_TOP`, and after the first Open `frame`, `catcher`,
`chrome` and `ctx` (the page's Options panel context).

### The window

`SettingsFrameTemplate` (wow-ui-source@297d7aa:Interface/AddOns/Blizzard_Settings_Shared/Mainline/
Blizzard_SettingsPanelTemplates.xml:4-29) when `C_XMLUtil.GetTemplateInfo` does not deny it and it
still has `NineSlice` (with `Text`), `Bg` and `ClosePanelButton`; else a plain frame with the owner's
Shell, the title on its band and Core's close mark. A full-screen catcher under it swallows clicks
and the wheel, dimmed in `ib.modalDim`. Clamped to the screen, never toplevel. The page is the
helpers' `CreatePanel` (header `Choose an icon`), laid under the title band and again on every looks
change.

### The owner tokens (`SKIN_TOKENS`)

| Token | Ka0s Default | Follows | Drawn as |
|---|---|---|---|
| `ib.selStrong` | gold at 0.7 | `list.sel` | the selected cell |
| `ib.note` | `#aaaaaa` | `text.muted` | the footer's "Click an icon to select it." |
| `ib.markGray` | 0.54 gray | `icon.dim` | the search box's clear mark |
| `ib.modalDim` | black at 0.45 | `cover.dim` | the catcher's dim |

Laid onto the host's own skin owner with `Skin:RegisterOwner(owner, { tokens = SKIN_TOKENS })` on
the browser's first build, once the host is a registered owner. A host that is not a skin owner gets
these Ka0s Default values and the window unskinned.

## What is not here

- **Storage.** A host stores a pick as it likes. The values handed out are a marker path, a texture
  id, or a glyph path with `"rrggbb"` or none for white; `IsGlyph` turns a glyph path into the catalog
  name a host may store instead.
- **Bus messages.** The browser listens to nothing; the host closes it from its own lifecycle and
  handlers.
