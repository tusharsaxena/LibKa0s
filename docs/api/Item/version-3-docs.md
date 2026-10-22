# `LibKa0s-Item-1.0` — version 3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Item surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Item-1.0` |
| Files and minors | `Item.lua` minor **3** |
| Shipped in | v1.75.0 |
| Status | **Current** |
| Supersedes | [version 2](./version-2-docs.md) |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Item-1.0").MODULES` → `{ Item = 3 }` |

## What changed at this version

**One member is added, `BonusIDsFromLink`, and nothing else moves.** No member is removed or
renamed, no signature changes and no floor rises: `NEEDS_CORE` stays 1 and the major gains no
edge to another. A host gets it by re-vendoring and owes nothing until it adopts it.
From [LibKa0s#51](https://github.com/tusharsaxena/LibKa0s/issues/51), item 1, on the owner's
2026-10-22 ruling.

| | | Since |
|---|---|---|
| `BonusIDsFromLink(link)` | The bonus ids an item link or bare itemString carries, as numbers, in link order. `{}` for an item with none, `nil` for anything that is not an item. | **3** |

BankLedger (its Wowhead URL builder) and LootHistory (its Wowhead export link) each wrote the same
positional walk to build the bonus string, and DropWatcher's item read does it a third time. The
walk carries the one piece of domain knowledge a copy can get wrong — field 13 is the count, and
empty fields must be kept for the count to be in field 13 — and holds no policy, so it joins the
four link and quality primitives as a fifth. The rest of #51's item read was judged and rejected;
the record is under [What this major is not](#what-this-major-is-not).

## What this major is

**Item identity, as five primitives, and no policy.** Nothing here decides what an item *is worth*
— the five functions read an item link, name a quality and ask the client to cache an id. The one
piece of state is `QualityFromLink`'s reverse color map, built lazily and kept once it is non-empty.

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

## What this major is not

[LibKa0s#51](https://github.com/tusharsaxena/LibKa0s/issues/51) proposed lifting DropWatcher's
whole item read (`core/ItemRead.lua`) and a loot-line parser into the library. Only
`BonusIDsFromLink` cleared `library-stack-§7`'s promotion bar. Everything else was considered on
2026-10-22 and rejected, and `library-stack-§7` asks for each rejection to be recorded with its
reason where the next author will look. This is that place. A row is reopened when its trigger
fires, not before.

| Rejected | Why | Re-check trigger |
|---|---|---|
| `LinkDetail` / `BetterLink` — how complete a link is, and keep the more complete of two links of one item | One consumer. Only DropWatcher merges two reports of the same item; BankLedger and LootHistory keep the first link per id while scanning containers, which is a variant-collapse policy over different items, and container links are always complete. The score and the tie rule are DropWatcher's feed policy. | A second addon must merge two reports of the same item from sources whose links differ in completeness (a chat line against a loot-window link, say). A first-link-per-id container scan does not count. |
| `IdentityKey` / `SameItem` — identity as the id plus the sorted bonus ids | One consumer, DropWatcher's trade timer. BankLedger and LootHistory deliberately key by base item id ("two ilvl variants of one id are one holding"), a different identity, so they are not even latent consumers. | A second addon needs to tell variants of one item id apart, for example BankLedger or LootHistory moving to per-variant rows. |
| `EffectiveItemLevel` — the gear level read (detailed, else base, gear only) | The shapes match and the semantics do not. DropWatcher answers a level for non-gear (tier tokens, reagents) and LootHistory answers `nil` there on purpose; DropWatcher gates on the cached `GetItemInfo` and LootHistory on `GetItemInfoInstant`, so uncached gear answers differently; and LootHistory takes an item id where DropWatcher takes a link or a `{bag, slot}`. | DropWatcher and LootHistory settle on one non-gear rule and one gear gate, and DropWatcher's simulator stops routing this read through its `NS.Compat`; or a third addon needs a gear level read. |
| `ItemLevelAt` / `QualityAt` — exact level and quality at a bag `ItemLocation` | One consumer, and that consumer could not adopt it: DropWatcher's simulator provides `BagItemLevelQuality` for simulated bag items, which have no `ItemLocation`, and a library read calling `C_Item` directly would bypass that seam and answer `nil` for every simulated drop. | A second addon reads an exact level or quality at a bag or inventory `ItemLocation`; even then, re-judge whether the read can honor DropWatcher's simulator seam. |
| `QualityOf` — the client's quality, else the link's color | This is the uncached-item policy this major was built not to own (*What this major is not, first*). DropWatcher returns a `(quality, source)` pair and routes it through its `NS.Compat` for secret stripping and its simulator; LootHistory folds the same `or` into its Compat; BankLedger refuses the color fallback on purpose and records the skip as uncached. Once `QualityFromLink` exists the merge is a one-line `or` over a client call. | BankLedger reverses its uncached ruling and adopts the color fallback, so the collection has one uncached-quality policy. |
| A Wowhead item URL builder (BankLedger `Util.WowheadURL`, LootHistory `Export:WowheadLink`) | Presentation tied to a third-party site's URL scheme, not item identity, and outside this major's "primitives, no policy" remit. The shared content was the bonus walk, which is `BonusIDsFromLink`; what is left in each copy is about five lines of string formatting. | A third addon exports Wowhead item URLs, or the two copies diverge in a way one of them gets wrong. |
| The loot-line parser (DropWatcher `modules/LootParser.lua`, LootHistory `ParseSelfLoot`; [#49](https://github.com/tusharsaxena/LibKa0s/issues/49) item 3 and #51 item 2) | The consumers disagree on correctness, not only on scope. LootHistory treats crafting and refund lines as receipts with a source tag; DropWatcher rejects crafting lines as not a drop and has no refund shape. Their outputs differ too (a link, a quantity and a source tag against a looter record). A shared parser would need a "which lines are receipts" flag and an adapter per consumer, which is policy. | A second addon needs every looter's loot **and** the consumers agree in writing on which line kinds are receipts (crafted, refund, bonus roll, pushed); or a third loot addon appears whose receipt set matches one of the two exactly. |

## Why these five

`QualityLabel` and `LoadItem` were byte-identical in both addons. The next two were each written by
only **one** of them — BankLedger had `ItemIDFromLink`, LootHistory had `QualityFromLink` — which is
the better argument for a library than duplication is: each addon was missing a primitive the other
had already written, and the color fallback is the one whose absence had already cost a misclassified
item. The fifth, `BonusIDsFromLink`, was written twice, by BankLedger and LootHistory, for the same
purpose and with the same walk, and it is the one whose positions are easy to get wrong.

## Lib-level surface

Read straight off the LibStub table.

| Name | Since | Meaning |
|---|---|---|
| `ItemIDFromLink(link)` | 1 | The itemID carried by an item link or a bare itemString, or `nil` for anything that is not one. |
| `BonusIDsFromLink(link)` | 3 | The bonus ids an item link or a bare itemString carries, as numbers in link order: `{}` for an item with none, `nil` for a non-string or a string with no `item:<id>`. Reads fields 14 to 13+*n*, where field 13 declares *n*, and nothing after them. |
| `QualityFromLink(link)` | 1 | The quality id encoded in the link's color prefix, or `nil` when the link carries no color or carries one no quality uses. The `\|cnIQ<n>` prefix since **2**; the legacy `\|cAARRGGBB` hex prefix since 1. |
| `QualityLabel(q)` | 1 | A quality id's display label — the client's own localized string first, a static English map second, the number itself last. |
| `LoadItem(id[, cb])` | 1 | Asks the server to cache `id`, and fires `cb` once it should have arrived. |
| `MAJOR` · `MINOR` | 1 | `"LibKa0s-Item-1.0"` and the live minor. |
| `MODULES` | 1 | `{ Item = <minor> }` — the live minor, and the value that picks this document. |

### `ItemIDFromLink` reads structure, never a name

It matches on the link's own `item:<id>` segment, so it is locale-independent and works equally on a
full link and on the bare itemString a saved variable is likely to hold. A non-string — including a
number that already *is* an id — answers `nil` rather than being passed through, because a caller
that cannot tell the two apart has a bug the library should not hide.

### `BonusIDsFromLink` walks the itemString by position

An itemString is colon-separated and **positional**: an empty field is a position, not a missing
value. The layout this function relies on:

| Field | Meaning |
|---|---|
| 1 | itemID — must be numeric, or the string holds no item and the answer is `nil` |
| 2 – 12 | enchant, four gems, suffix, unique id, link level, spec, upgrade type, difficulty |
| 13 | the declared bonus count, *n* (empty or absent reads as 0) |
| 14 – 13+*n* | the bonus ids, in link order |
| after 13+*n* | the modifier block, relic and crafting data — **never read** |

So the walk splits **keeping empty fields** (a split that drops them reads field 13 out of the
wrong place, the trap BankLedger's own copy recorded), reads field 13 as the count, and stops at
the declared count however many fields follow. A non-numeric field inside the declared span is
skipped, not read as `0`.

The body is the run of digits, `-` and `:` after `item:`, so it reads the same out of a full
link — `|cnIQ<n>` or legacy `|cAARRGGBB` colored — and out of a bare itemString. A field holding
any other character ends the body there; real links never carry one. That differs on malformed
input from BankLedger's hand-written walk, which matched up to the next `|` and skipped any
non-numeric field, and the difference is the challenger's point recorded in the run that promoted
this (Ka0sAddonsCommonTasks `docs/2026-10-22-LIBKA0S_ISSUES_45_58/`): an adopter whose
characterization tests feed a malformed field sees it there.

The answer is a fresh table on every call: `{}` for an item with no bonuses, `nil` for a
non-string or a string with no `item:<id>`. Like `ItemIDFromLink`, a number is not passed through.

### `QualityFromLink` is the uncached fallback, and the reason this major exists

`GetItemInfo` answers nothing until the client has cached the item, and when handed a bare itemID it
can only ever answer with the **base** item — so an upgrade-track drop reads back at the quality it
started as. The link's color is the real one, available immediately, out of the string the game
already handed the addon.

Two rungs, in this order. A `|cnIQ<n>` prefix, the shape every link has carried since patch 11.1.5,
answers `n` directly. A legacy `|cAARRGGBB` prefix, the shape a link stored before that patch still
carries, is looked up in a reverse map from color hex to quality id.

That map is built from `ITEM_QUALITY_COLORS` **on first use**, not at load. That is a requirement
rather than a style preference: this file runs from inside `libs/` before the client has populated
that table, so a map built at load would be empty for the life of the session and every lookup would
answer `nil` — silently, since `nil` is also the legitimate answer for an uncolored link. For the
same reason a build that finds nothing to map is not kept, and the next call tries again.

### `QualityLabel` matches on the id, never on a localized string

localization-§4. The client's `ITEM_QUALITY<n>_DESC` first, the static English map second, and
`tostring(q)` for a quality neither knows — a visible answer rather than a `nil` that renders as a
blank cell nobody can explain. `nil` is treated as quality 0, so a caller with nothing gets "Poor"
rather than an error.

### `LoadItem` is inert when it cannot help

No id, or no `C_Item.RequestLoadItemDataByID` on this client, and it returns having done nothing.
Both mean the same thing to a caller: no name yet, show the placeholder, try again later. The
callback is deferred through `C_Timer.After` rather than fired inline, because the data does not
arrive within the call. The 0.4 s delay is fixed and does not wait for the data; see
[version 2](./version-2-docs.md#loaditem-is-deliberately-unchanged), where it was left as it is on purpose.

## Adopting it

```lua
local Item = LibStub and LibStub("LibKa0s-Item-1.0", true)

local function Row(link)
    local id      = Item and Item.ItemIDFromLink(link)
    local bonuses = Item and Item.BonusIDsFromLink(link) or {}
    local quality = Item and Item.QualityFromLink(link)
    if id and not quality then
        Item.LoadItem(id, function() Panel:Refresh() end)
    end
    return id, bonuses, quality, Item and Item.QualityLabel(quality)
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

`Item.lua` is already an entry in `LibKa0s.xml`, so moving from version 2 is a whole-folder copy and
no load list changes.
