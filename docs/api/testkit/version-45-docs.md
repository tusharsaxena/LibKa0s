# `testkit` — version 45

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `secrets.lua`, `latch.lua`, `bindings_xml.lua`, `glyphs.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_lines.lua`, `mock_ids.lua`, `mock_bindings.lua`, `mock_layers.lua`, `mock_paint.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **45** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.82.0 |
| Status | Superseded |
| Supersedes | [version 44](version-44-docs.md) — no display-glyph guard, and `mock_paint.lua`'s `SetTextColor` reset a string's alpha to 1 when given three numbers |
| Superseded by | [version 46](version-46-docs.md) — the safe set read from the v1.83.0 faces |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `45` |

Everything revision 44 describes is unchanged here except what follows. One file is added,
`glyphs.lua`, which `framework.lua` loads beside `bindings_xml.lua`. Revision 45 is one
release's kit (v1.82.0, Ka0sAddonsCommonTasks `docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/`): a later
kit change in that release extends this document rather than taking a revision of its own.

## What changed

### `glyphs.lua`: the display-glyph guard (`LK-12`)

The owner's item 5b and ruling D-19: LootHistory's footer read "Database [] 1.6 MB" under Obsidian,
because its string carried U+2248 (written as the escape `"\226\137\136"`) and Expressway has no
such glyph. The guard fails a display string carrying a character some shipped skin face cannot
draw. Published on the kit table and by `Kit.expose`:

| Member | Answer |
|---|---|
| `Kit.glyphUnsafe(s)` | every character of `s` outside the safe set, in order: `{ cp, char }`, or `{ byte }` for a byte that is not valid UTF-8; `\|T...\|t` and `\|A...\|a` markup left out. Empty when safe; a non-string is empty |
| `Kit.assertGlyphSafe(s, label)` | fails naming each unsafe character as `U+XXXX` |
| `Kit.scanGlyphSource(text, path, opts)` | the hits in one Lua chunk: `{ path, line, cp, char, text }`, `line` the line the literal starts on |
| `Kit.scanDisplayGlyphs(opts)` | the hits and the files read, over `git ls-files '*.lua'` (or `opts.paths`) |
| `Kit.assertDisplayGlyphs(opts)` | fails listing the first 20 hits and the count |

`Kit.GLYPH_FACES` and `Kit.GLYPH_RANGES` (on the kit table, not exposed) are the generated block.

**The safe set** is every byte under 0x80 (printable ASCII, tab, newline) and the non-ASCII code
points every face in `LibKa0s/media/fonts` draws, read from their cmaps by LibKa0s's
`tools/glyph_safe_set.py` (fontTools), which rewrites the block between `-- BEGIN GENERATED` and
`-- END GENERATED`; `--check` reports a stale one. At this revision that is the fifteen shipped faces
(the skins' body, title and HUD faces and JetBrains Mono, the mono role) and 118 code points:
NBSP to U+00A3, U+00A5 to U+00AB, U+00AE to U+00BB, U+00BF to U+00FF (the Latin-1 letters, `°`,
`±`, `·`, `×`, `§`), `Œ œ Š š Ÿ Ž ž`, four spacing accents, `– —`, the curly quotes and `‚ „`,
`† ‡ •`, `…`, `‹ ›`, `⁄` and `™`. Not in it: `≈`, `≠`, the arrows `← ↑ → ↓ ↔ ⇄`, `▲ ▼ ▸ ▾`, `✓ ✗`,
`€` and every non-Latin script. Real Friz Quadrata (WoW Default's face) is not measured (D-05,
IS-07), and a font override guarantees nothing beyond ASCII. LibKa0s's
`tests/test_glyph_guard.lua` is red while the face list (file name and byte size) disagrees with the
folder.

**What is scanned.** Every string literal: quoted (escapes decoded: `\ddd`, `\xNN`, `\u{X}`, `\z`
and the letter escapes) and long (`[[...]]`, `[==[...]==]`), so a locale file's values are read too.
Left out: comments; the arguments of a debug-log call, to its closing paren over any number of lines
(a callee whose last name is exactly one of the collection's debug sinks: `Debug`, `Debugf`,
`DebugOnce`, `DebugErrorOnce`, `DebugSteady`, `DebugChanged`, `DebugAtEnable`, `DebugMessage`,
`AddDebugMessage`, `DebugTable`, `DebugStack`, `debug`, `dbg`, `Dbg`, plus `opts.debugNames`; a
display helper whose name merely carries "Debug", such as `DebugLabel`, is scanned), and the one
literal of a debug sink's string call (`NS.Debug "..."`); a line carrying the comment marker `glyph: mono` (a string drawn in the mono
role, or a glyph its own FontString pins to JetBrains Mono) or `glyph: data` (a string never drawn),
and every line between a `glyph: mono begin` / `glyph: data begin` and its `end`; texture markup;
and a stray byte that is not valid UTF-8 (byte data, a pattern's `[\128-\191]` class; RFC 3629's
rules, so a lead byte past `0xF4`, a surrogate or an overlong form is byte data, not a character).
A `begin` left open at the end of a file, or an `end` with no `begin`, fails naming the line: a
mistyped marker never exempts the rest of a file.

**opts:** `paths` (read exactly these), `include` (path prefixes kept), `skip`
(`{ [prefix] = "why" }`, a missing or empty reason fails), `debugNames` (a list or a set), `label`.
`libs/`, `tests/` and `tools/` are never read. No `io.popen`, no git or no tracked `.lua` file fails
rather than passing.

It is a helper, not a kit suite: nothing goes red on a re-vendor before an addon has fixed its own
strings. A consumer wires one case:

```lua
test("display strings use only characters every shipped skin face draws", function()
  T.assertDisplayGlyphs{ label = "LootHistory" }
end)
```


### `mock_paint.lua`: `SetTextColor` keeps the alpha it is not given (`LK-14`)

A FontString told `SetTextColor(r, g, b)` with no fourth number keeps the alpha it already had;
told an alpha, it takes it; a string never given one is opaque. Revision 44 reset the alpha to 1 on
every three-number call. The client keeps it, and the difference hid a real defect: DpsRace's Arm
Race label, painted once in a 0.4-alpha disabled color, drew its enabled `btnPrimary.text` at 0.4 in
three skins (the bundle's image-55..57, measured to the pixel: Obsidian's white at 0.4 over its
`#1E80D0` fill is `(121, 179, 227)`). `tests/test_mock_paint.lua` pins the rule, and
`tests/test_skin_button_contrast.lua` the library fix it exposed (SkinPaint minor 13's `P.color`).

**Fidelity note.** Only the recorder's FontString changes. `SetVertexColor`, `SetShadowColor` and the
base mock's own frames are as revision 44 left them: nothing has measured the client's rule for them.

### `vendor_sync.lua`: every binary pin is compared byte for byte (`LK-A2`)

The vendor-sync gate strips CR from the working-tree side of a text file before comparing it with the
tag's blob, and leaves a binary alone. Which files count as binary is the extension table
`BINARY_EXT`, which said it matched `.gitattributes`' binary pins and stopped at `zip`: `tar`, `gz`,
`7z`, `pdf`, `bin` and `param` were missing. v1.82.0 is the first payload to ship a PDF
(`media/fonts/Expressway-EULA.pdf`), and a byte-identical vendored copy failed *libs/LibKa0s is the
LibKa0s release CLAUDE.md says this addon bundles* with `media/fonts/Expressway-EULA.pdf matches the
library repo at v1.82.0`, because its CR LF pairs had been rewritten before the comparison. The
table now carries all twenty extensions `.gitattributes` pins, and the module publishes the
predicate as `VendorSync.isBinary(path)` (case-insensitive on the extension).

The table stays pinned rather than read at run time: the bytes compared are the library's, and the
only `.gitattributes` the gate could reach is the consumer's. `tests/test_kit_vendor_sync.lua` keeps
the two in step instead. One case reads this repo's `.gitattributes` and fails naming any `*.<ext>
binary` line the table lacks; another vendors a fixture PDF holding CR LF pairs and a NUL, passes the
byte-identical copy and fails one that lost its CRs. Every fixture library in that suite now carries
the PDF beside its face, and beside it a text file (`Guide.html`, standing in for
`Expressway-EULA-Guide.html`) whose blob is LF: a third case writes the consumer's copy CR LF, as a
CRLF working tree checks it out, passes it, and fails a CR LF copy with one changed content byte, so
the normalization the text side still needs is pinned too.

No documented member is renamed or removed and no case name changes.

## What a consumer owes

Re-vendor `tests/_kit/` whole (it now carries `glyphs.lua`):

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
lua tests/run.lua --list > docs/test-cases.md
```

A suite that paints a string translucent under the recorder and then asserts an opaque color it set
with three numbers now reads the kept alpha: that is the client's answer, and the code under test
passes the alpha itself. Wiring the glyph guard is the addon's own
item, not the re-vendor's: run it once, fix or mark each hit, then add the case. A consumer's own
prose that names the revision it holds moves to 45 in the same commit.
