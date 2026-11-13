# `testkit` — version 56

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 55 lists |
| Version | **56** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | unreleased (v1.97.0) |
| Status | **Current** |
| Supersedes | [version 55](version-55-docs.md) — the same surface, with a face list of thirty-three files |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `56` |

Everything revision 55 describes is unchanged here except what follows. No file is added. Two
change: `framework.lua`, whose `Kit.VERSION` is 56, and `glyphs.lua`.

## What changed

### `glyphs.lua`'s generated face list gains the Callout's two faces

LibKa0s v1.97.0 ships two display faces for `LibKa0s-Callout-1.0` (`LibKa0s-Media-1.0` 13.1):
`BebasNeue-Regular.ttf` and `RussoOne-Regular.ttf`. `tools/glyph_safe_set.py` reads every face in
`LibKa0s/media/fonts/`, so the generated block's `FACES` (`Kit.GLYPH_FACES`) gains both, by file name
and byte size, and holds thirty-five.

**`RANGES` (`Kit.GLYPH_RANGES`) does not move.** Both faces draw every character the safe set held,
so it stays at 117 non-ASCII code points beside printable ASCII, and every string that passed the
guard at revision 55 passes at 56. Orbitron Bold, the third face the Callout's plan named, would have
cut it to 89 (the middle dot, the plus-minus sign, the guillemets, the copyright and trademark signs
among the 28 it lacks), and does not ship on the owner's ruling of 2026-11-13.

## What a consumer owes

Re-vendor the kit with the library, per `docs/releasing.md`. Nothing else: no assertion, mock or
gate moves, and no string a consumer paints changes verdict.
