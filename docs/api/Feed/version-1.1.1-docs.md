# `LibKa0s-Feed-1.0` — version 1.1.1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Feed surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Feed-1.0` |
| Files and minors | `Feed.lua` minor **1** · `FeedModel.lua` minor **1** (paired on `Feed.lua`'s minor) · `FeedRow.lua` minor **1** (paired on `Feed.lua`'s minor) |
| Shipped in | unreleased (v1.119.0) |
| Status | **Current** |
| Supersedes | none (new major) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 20 (`NEEDS_CORE = 20`, for `ClassColor`) |
| Optional at call time | `LibKa0s-Pool-1.0`, `LibKa0s-Media-1.0`, `LibKa0s-Skin-1.0`, `LibKa0s-Widgets-1.0` and LibSharedMedia-3.0, each resolved at call time behind a type check, with no floor |
| Confirm in-game | `LibStub("LibKa0s-Feed-1.0").MODULES` → `{ Feed = 1, FeedModel = 1, FeedRow = 1 }` |

> **Work in progress on `feat/2026-11-27-feed`.** This version is being built in steps (the design is
> `docs/superpowers/specs/2026-11-27-libka0s-feed-design.md`). At this point of the branch the
> lib-level surface, the pure model and the paired files are in place, and every instance member
> answers its degraded value (the table under *The degradation stub*). The contract sections below
> are completed before the release.

## What changed at this version: the major is new

Ka0s Loot History #38 asks for toast feeds: up to ten short-lived rows on screen at once, the newest
at the anchor, merged in place on a repeat, frozen under the pointer. `LibKa0s-Toast-1.0` is the
other shape (the oldest toast at the saved point, one timer per toast), and a feed mode there would be
a behavior flag that turns its members around, so the feed is a major of its own in three files:
`Feed.lua` (the shell), `FeedModel.lua` (the pure model) and `FeedRow.lua` (the rows).

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

`lib.__methods`, `lib.__model` and `lib.__row` are this major's internals (the method table every
`New` copies, the pure half and the rows), for its paired files and its suites only.

## The degradation stub

A host that loads without the library, or with a copy that predates Feed, carries an **instance stub**
and a parity case (`T.assertSurfaceParity(liveFeed, NS.FeedStub, "Feed instance")`, the instance form,
because the member manifest lists the lib-level surface only). Each member answers:

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

`__Step(dt)` is an internal test seam, outside the parity surface.

## Vendoring

Whole-folder, as every major: `LibKa0s.xml` loads `Feed.lua`, `FeedModel.lua` and `FeedRow.lua`
directly after `Toast.lua`. The two secondaries are paired on the shell's minor
(`lib.__modelMinor` / `lib.__modelShellMinor`, `lib.__rowMinor` / `lib.__rowShellMinor`): a
secondary re-attaches whenever the winning shell's minor is not the one it attached to.
