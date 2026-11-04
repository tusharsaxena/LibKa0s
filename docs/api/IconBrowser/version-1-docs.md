# `LibKa0s-IconBrowser-1.0` — version 1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the IconBrowser surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-IconBrowser-1.0` |
| File | `IconBrowserSources.lua` minor **1** |
| Shipped in | v1.86.0 (unreleased; the browser window joins the major before the tag) |
| Status | Superseded (never shipped) |
| Supersedes | — |
| Superseded by | [version 1.1.1](./version-1.1.1-docs.md) — the browser window joined the major before the tag. |
| Requires | `LibKa0s-Core-1.0` ≥ 1 (no Core member is called) and `LibKa0s-Media-1.0` ≥ 5 (the icon sets and their prefixes) |
| Optional at call time | `LibKa0s-Compat-1.0`, no floor: its `IsSecret` guards the macro icon lists when it is present |
| Confirm in-game | `LibStub("LibKa0s-IconBrowser-1.0").MODULES` → `{ IconBrowserSources = 1 }` |

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
| `STRINGS` | 1 | Every word this file can show, by key (`TAB_MARKERS`, `TEXTURE_ID`, `MARKER_1`..`MARKER_8`, `SET_*`, `GLYPH_*` and the rest). A host overrides any of them with `spec.L`, read with `rawget`, so a locale table that answers its own key is ignored. |
| `GLYPH_LABELS` | 1 | The curated glyphs' labels: catalog name → `STRINGS` key. Every other glyph is labeled from its name. |
| `MAJOR` · `MINOR` | 1 | `"LibKa0s-IconBrowser-1.0"` and the live minor. |
| `MODULES` | 1 | `{ IconBrowserSources = <minor> }`: the value that picks this document. |

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

## What is not here

- **The window.** The browser itself (the strip, the grid, the toolbar, Choose and Cancel) joins this
  major as its own file before v1.86.0 is tagged.
- **Storage.** A host stores a pick as it likes. The values handed out are a marker path, a texture
  id, or a glyph path with `"rrggbb"` or none for white; `IsGlyph` turns a glyph path into the catalog
  name a host may store instead.
