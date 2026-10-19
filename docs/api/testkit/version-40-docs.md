# `testkit` — version 40

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `secrets.lua`, `latch.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_lines.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **40** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | unreleased — the first LibKa0s release after v1.74.0 |
| Status | **Current** |
| Supersedes | [version 39](version-39-docs.md) — `vendor_sync.lua` compared `libs/LibKa0s/` whole, so a consumer could not ship fewer than all 5,836 icons |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `40` |

Everything revision 39 describes is unchanged here except what follows. No file is added. Three
change: `framework.lua`, whose `Kit.VERSION` is 40; `vendor_sync.lua`, which reads the consumer's
icon declaration and gains the pure functions below; and `README.md`, which says so. No public
member is renamed or removed and no kit case name changes.

## What changed

### `vendor_sync.lua` holds `media/icons/` to the consumer's declaration

LibKa0s v1.74.0 took `LibKa0s/media/icons/` to 5,836 TGAs, about 18 MB (28 MB on disk): 224 Open Iconic marks flat
in the folder, 1,434 Phosphor marks in `phosphor/` and 4,178 Game-icons marks in `game-icons/`.
Every consumer vendored all of it, because the payload rule was whole-folder and this gate compared
the whole folder. `library-stack-§7` (standard v2.85.0) now makes the icon folder the one
carve-out: a consumer ships **exactly the icons it declares**, and an addon that offers the player
a choice among the catalog (an icon picker) declares them all.

The declaration is **one line in the consumer's root `CLAUDE.md`, directly under its provenance
line** (blank lines between the two are allowed, any other line is not), in one of three forms:

```text
Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) vX.Y.Z (MIT).
LibKa0s icons: all (icon picker).
LibKa0s icons: none.
LibKa0s icons: settings, close, ph:sword, gi:skull.
```

(one of the three, not all of them). Names are `lib.ICONS` names: Open Iconic unprefixed, `ph:`
Phosphor, `gi:` Game-icons, comma-separated, the line ending in a period. `all` must carry a
parenthesized reason naming the player-facing chooser. The marker is anchored to the start of a
line (an optional `- ` or `* ` list marker before it), so prose or a code span that mentions
`LibKa0s icons:` mid-line is not read as a second declaration.

**Icons the library draws for the host are the host's to declare.** `close` is drawn by
`Core.MakeCloseButton` given the addon name (the DebugLog console, `PerfPanel.lua` without a
`decorate`, the Widgets copy window), `clear` and `copy` by the DebugLog console, and `info` by the
Options id list's help mark unless the spec passes its own `helpIcon`. A host that wires the debug
console declares at least `close, copy, clear`. This gate cannot catch an omission: a pruned icon
still resolves to a path, so the module's text fallback never runs and the control draws blank.

What the library pair's case then asserts, from revision 40:

| Declaration | Under `libs/LibKa0s/media/icons/` | Everywhere else under `libs/LibKa0s/` |
|---|---|---|
| none at all | the whole folder, byte-identical (revision 39's gate, unchanged) | whole, byte-identical |
| `all (<reason>).` | the whole folder, byte-identical | whole, byte-identical |
| `none.` | no file at all: no icon and no icon license file (an empty or absent folder passes) | whole, byte-identical |
| a list | each declared icon, plus its set's attribution files, byte-identical; nothing else | whole, byte-identical |

A **set's attribution files** are the non-TGA files in that set's folder: at v1.74.0
`LICENSE-open-iconic.txt` for Open Iconic, `phosphor/LICENSE-phosphor.txt` for Phosphor, and
`game-icons/LICENSE-game-icons.txt` with `game-icons/AUTHORS.txt` for Game-icons. They ship when
any of the set's icons ships and must be absent when none does.

The failures, each naming what to do:

- **An undeclared file ships**: `N undeclared file(s) ship under libs/LibKa0s/media/icons/`, the
  first ten named and a count of the rest, with the fix (`lua tools/prune-icons.lua <this repo>`
  from the LibKa0s checkout, or declare the icons you draw).
- **A declared file is missing**: counted and named the same way; re-copy, then prune.
- **An unknown name**: a declared name the **tag's** catalog does not carry. The catalog is derived
  from the tag's file list under `LibKa0s/media/icons/` (`<n>.tga` is `<n>`, `phosphor/<n>.tga` is
  `ph:<n>`, `game-icons/<n>.tga` is `gi:<n>`), never from the consumer's copy, so a stray local file
  cannot vouch for a name.
- **A malformed line**: no period, an empty entry, a token that is not a name, `all` without its
  reason, the line declared twice, or the line anywhere but directly under the provenance line.
- **Content**: a declared file that differs from the tag, as before.

A file in a folder of `media/icons/` that belongs to no known set (none at v1.74.0) is treated as
payload, not as an icon: it always ships and is never pruned.

**Speed.** `ls-tree` still lists the tag's whole payload once, but in the declared shape only the
required blobs are read: `none` or a short list costs a few dozen blobs, not 5,836.

**The transition.** A consumer with no `LibKa0s icons:` line is gated exactly as under revision 39,
so taking revision 40 turns nothing red. The rule's MUST binds from the first LibKa0s release whose
kit carries this gate; each consumer adds its line and prunes in its re-vendor commit.

### The parser and the catalog are published, for `tools/prune-icons.lua`

The tool that cuts a copy down to its declaration loads this file and calls these, so the tool and
the gate cannot disagree about what a line means. Since 40:

| Member | Answers |
|---|---|
| `VendorSync.parseIconLine(body)` | The body after `LibKa0s icons:` as `{ mode = "all", reason }`, `{ mode = "none", names = {} }` or `{ mode = "list", names }` (sorted, duplicates dropped), or `nil, reason` |
| `VendorSync.iconDeclaration(doc[, opts])` | The declaration in a document's text: `decl`, `nil, nil` when there is no line, or `nil, reason`. `opts.provenancePattern`, `opts.iconsPattern` |
| `VendorSync.iconCatalog(paths)` | From paths relative to an icons folder: `{ names = { [name] = path }, attribution = { [prefix] = { path, ... } }, other = { path, ... } }` |
| `VendorSync.requiredIcons(decl, cat, paths)` | The paths a declaration requires (sorted) and the declared names the catalog lacks (sorted) |
| `VendorSync.cappedList(names)` | The names sorted, the first ten joined, then `... and N more` |
| `VendorSync.splitUnder(names, dir)` | The names under `dir/` (relative to it) and the rest |
| `VendorSync.localNames(dir)` | The files under a local directory, recursive, sorted, relative to it |

`register`'s opts gain **`iconsPattern`** (default `"LibKa0s icons:%s*(.-)%s*$"`), and a pair gains
an optional **`icons`** field naming the subfolder held to the declaration; the default library pair
carries `icons = "media/icons"`. A pair without it is compared whole.

### `localNames` tries the cmd.exe fallback only on Windows

The listing falls back to `dir /b /s` when `find` returns nothing. On Linux that ran coreutils' own
`dir` and left a file named `NUL` in the working directory, which an empty icon folder (a `none`
copy) would now reach. The fallback is taken only where `package.config` says Lua is on Windows.

Nineteen cases in this repository's `tests/test_kit_vendor_sync.lua` pin it, against a real
library repo tagged in a temporary directory and a consumer beside it: the three forms and every
refusal of the parser, the line's placement, the catalog and the attribution rule, the gate with no
line, `none`, a list, an undeclared icon, an unknown name a stray file tries to vouch for, a changed
icon, the rest of the payload still compared whole, `all` with and without its reason, and the tool
(a list, `none`, `all` and no line, an unknown name refused with nothing removed). They are **not**
kit cases, so a consumer's suites list does not change.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
lua tests/run.lua --list > docs/test-cases.md
```

The suites list and every kit case name are unchanged. Then, in the re-vendor commit that brings the
library's payload, add the `LibKa0s icons:` line under the provenance line and run
`lua tools/prune-icons.lua <Addon>` from the LibKa0s checkout (see `docs/releasing.md`,
*Re-vendoring consumers*). A consumer's own prose that names the revision it holds
(`kit revision 39`) moves to 40 in the same commit.
