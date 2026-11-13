# `testkit` — version 55

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 54 lists |
| Version | **55** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.96.0 |
| Status | Superseded |
| Supersedes | [version 54](version-54-docs.md) — the same surface, with `media/sounds/` compared whole like the rest of the payload |
| Superseded by | [version 56](version-56-docs.md) — `glyphs.lua`'s face list gains Bebas Neue and Russo One; the safe set is unchanged |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `55` |

Everything revision 54 describes is unchanged here except what follows. No file is added. Two
change: `framework.lua`, whose `Kit.VERSION` is 55, and `vendor_sync.lua`.

## What changed

### `vendor_sync.lua` holds `media/sounds/` to the consumer's sound declaration

LibKa0s v1.96.0 ships the voice packs `LibKa0s-Callout-1.0` speaks with, one folder per pack at
`LibKa0s/media/sounds/callout/<voice>/`, each holding its `.ogg` lines and its own license and
credits files. They are the **second carve-out** from whole-folder vendoring (`library-stack-§7`,
*The sound subset*, standard v2.108.0; `testing-§11`): a consumer declares the packs it ships on one
line, the first non-blank line after its `LibKa0s icons:` line in root `CLAUDE.md`:

```text
LibKa0s sounds: none.
LibKa0s sounds: all.
LibKa0s sounds: callout/female-kathleen, callout/male-joe.
```

**No line means `none`.** This is the opposite of the icons line, on purpose: almost no consumer
plays a voice, and v1.96.0 is the first tag carrying `media/sounds/`, so there is no transition to
keep green. The re-vendor that brings the folder is the one that prunes it.

The library pair (the default `pairs` entry) now carries `sounds = "media/sounds"` beside
`icons = "media/icons"`, and its case holds the consumer's `libs/LibKa0s/media/sounds/` to exactly
the declared packs: every file of each declared pack present and byte-identical to the tag (an
`.ogg` compared raw, as every binary is), every other file under the folder absent, counted and ten
named. With `none` or no line, an empty or absent folder passes and any file fails, the failure
saying when there is no line that no line means none. A pack the **tag** does not carry fails,
whatever the consumer's copy holds. `all` compares `media/sounds/` whole, with the rest of the
payload. Everything outside `media/icons/` and `media/sounds/` is compared whole, as before; the
set-mismatch message names both folders when both are carved.

The grammar is `testing-§11`'s icons grammar with its four differences: the placement (directly
under the icons line, so a sounds line with no icons line above it is malformed), the prefix, a
**bare** `all` (`all (…)` is malformed), and names that are pack folders under `media/sounds/`
(`<group>/<pack>`, such as `callout/female-kathleen`). A duplicate name, an empty entry, or `all` or
`none` as a list item is malformed. A malformed, misplaced or doubled line fails the case, naming
why. A line that merely mentions `LibKa0s sounds:` mid-sentence is prose, not a declaration.

### The parser and the catalog are published, for `tools/prune-icons.lua`

Pure functions on the module, so the prune tool reads the line with the gate's own code:

- **`VendorSync.parseSoundLine(body)`** → `{ mode = "none" | "all", names = {} }` or
  `{ mode = "list", names = { … } }` (sorted), or `nil, reason`.
- **`VendorSync.soundDeclaration(doc, opts)`** → the parsed line; with no line,
  `{ mode = "none", names = {}, implicit = true }` (never nil); `nil, reason` when malformed,
  misplaced or doubled. `opts.iconsPattern` and `opts.soundsPattern` override the two markers.
- **`VendorSync.soundCatalog(paths)`** → `{ packs = { [pack] = { paths… } }, loose = { … } }` from
  paths relative to the sounds folder: a pack is the first two path segments, so its license and
  credits are in it by construction; a file in no pack folder is `loose` and ships only under `all`.
- **`VendorSync.requiredSounds(decl, cat, paths)`** → the required paths (sorted) and the declared
  packs the catalog lacks (sorted).

`register` takes a `soundsPattern` opt (default `^[%s%-%*]*LibKa0s sounds:%s*(.-)%s*$`), and a pair
takes a `sounds` field naming the folder held to the line. The icons functions are unchanged; they
now share one line reader with the sounds functions.

## What a consumer owes

Re-vendor the kit with the library, per `docs/releasing.md`, and run the tag's
`tools/prune-icons.lua <addon>` after the `cp -r`, as before: from v1.96.0 the same run prunes
`media/sounds/` to the sounds line, so a consumer with no line ends with no sound file and its gate
stays green. A consumer that adopts the Callout with a bundled voice adds its `LibKa0s sounds:` line
directly under its icons line, in the re-vendor commit, and prunes. A consumer that passes its own
`pairs` to `register` adds `sounds = "media/sounds"` to its library pair, or that pair compares the
folder whole and goes red after the prune.
