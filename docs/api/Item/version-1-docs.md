# `LibKa0s-Item-1.0` — version 1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Item surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Item-1.0` |
| Files and minors | `Item.lua` minor **1** |
| Shipped in | v1.14.0 |
| Status | **Current** |
| Supersedes | — (first version) |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Item-1.0").MODULES` → `{ Item = 1 }` |

## What this major is

**Item identity, as four primitives, and no policy.** Nothing here holds state, nothing caches, and
nothing decides what an item *is worth* — the four functions read an item link, name a quality and
ask the client to cache an id.

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework. **No Core
member is called** — the gate is there so that a host holding a partial payload gets every module
absent rather than a working half, and "is LibKa0s here?" stays one question.

## What this major is not, first

There is **no merged "resolve an item" function** here, and its absence is the design.

Two addons in this collection resolve items, and they disagree — deliberately, in writing — about
what an **uncached** item means. LootHistory guesses: it falls back to the name in the link's
brackets and the quality in its color, because a browsable capture log would rather show an
approximate row than lose the drop. BankLedger refuses: its quality gate records the skip as
"uncached" and asks the client to cache the id, because "cannot be judged" is not "passes" and a row
it can never classify is not one a threshold ever asked for.

Both are correct for their addon. A shared resolver would have to pick one, and picking would have
silently overturned a decision the other addon wrote down and tested — the "shared bug surface" a
module is supposed to avoid being. So this major carries the primitives both compose, and holds no
opinion about how.

## Why these four

`QualityLabel` and `LoadItem` were byte-identical in both addons. The other two were each written by
only **one** of them — BankLedger had `ItemIDFromLink`, LootHistory had `QualityFromLink` — which is
the better argument for a library than duplication is: each addon was missing a primitive the other
had already written, and the color fallback is the one whose absence had already cost a misclassified
item.

## Lib-level surface

Read straight off the LibStub table. Every function is stateless.

| Name | Since | Meaning |
|---|---|---|
| `ItemIDFromLink(link)` | 1 | The itemID carried by an item link or a bare itemString, or `nil` for anything that is not one. |
| `QualityFromLink(link)` | 1 | The quality id encoded in the link's color prefix, or `nil` when the link carries no color or carries one no quality uses. |
| `QualityLabel(q)` | 1 | A quality id's display label — the client's own localized string first, a static English map second, the number itself last. |
| `LoadItem(id[, cb])` | 1 | Asks the server to cache `id`, and fires `cb` once it should have arrived. |
| `MAJOR` · `MINOR` | 1 | `"LibKa0s-Item-1.0"` and the live minor. |
| `MODULES` | 1 | `{ Item = <minor> }` — the live minor, and the value that picks this document. |

### `ItemIDFromLink` reads structure, never a name

It matches on the link's own `item:<id>` segment, so it is locale-independent and works equally on a
full link and on the bare itemString a saved variable is likely to hold. A non-string — including a
number that already *is* an id — answers `nil` rather than being passed through, because a caller
that cannot tell the two apart has a bug the library should not hide.

### `QualityFromLink` is the uncached fallback, and the reason this major exists

`GetItemInfo` answers nothing until the client has cached the item, and when handed a bare itemID it
can only ever answer with the **base** item — so an upgrade-track drop reads back at the quality it
started as. The link's color is the real one, available immediately, out of the string the game
already handed the addon.

The reverse map from color hex to quality id is built from `ITEM_QUALITY_COLORS` **on first use**,
not at load. That is a requirement rather than a style preference: this file runs from inside `libs/`
before the client has populated that table, so a map built at load would be empty for the life of the
session and every lookup would answer `nil` — silently, since `nil` is also the legitimate answer for
an uncolored link.

### `QualityLabel` matches on the id, never on a localized string

localization-§4. The client's `ITEM_QUALITY<n>_DESC` first, the static English map second, and
`tostring(q)` for a quality neither knows — a visible answer rather than a `nil` that renders as a
blank cell nobody can explain. `nil` is treated as quality 0, so a caller with nothing gets "Poor"
rather than an error.

### `LoadItem` is inert when it cannot help

No id, or no `C_Item.RequestLoadItemDataByID` on this client, and it returns having done nothing.
Both mean the same thing to a caller: no name yet, show the placeholder, try again later. The
callback is deferred through `C_Timer.After` rather than fired inline, because the data does not
arrive within the call.

## Adopting it

```lua
local Item = LibStub and LibStub("LibKa0s-Item-1.0", true)

local function Row(link)
    local id      = Item and Item.ItemIDFromLink(link)
    local quality = Item and Item.QualityFromLink(link)
    if id and not quality then
        Item.LoadItem(id, function() Panel:Refresh() end)
    end
    return id, quality, Item and Item.QualityLabel(quality)
end
```

What the host does when `quality` is `nil` is the host's decision, and the two addons that made it
made it differently on purpose. This major will not make it for you.

**A host with no LibKa0s** (the degraded install every Ka0s addon models) gets `nil` from the
`LibStub` lookup and must degrade as it does for every other module — which for this major means
keeping the local helpers it already had.

## Vendoring

Whole-folder, exactly as every other major in this payload:

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s   # content — MUST be empty
diff -r LibKa0s <Addon>/libs/LibKa0s                       # bytes  — SHOULD be empty
```

`Item.lua` is a new entry in `LibKa0s.xml`, so a consumer whose test harness derives its load list
from that XML picks it up with no edit; a consumer that re-types the list adds one row.
