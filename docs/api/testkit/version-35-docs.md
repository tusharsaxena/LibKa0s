# `testkit` — version 35

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, **`lizard_sighted.lua`**, **`test_lizard_sighted.lua`**, `run-automated-tests.sh`, `README.md` |
| Version | **35** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.66.0 |
| Status | **Current** |
| Supersedes | [version 34](version-34-docs.md) — the diagnostics contract has a run turn logging on |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `35` |

Everything revision 34 describes is unchanged here except what follows. Two files are added,
`lizard_sighted.lua` and `test_lizard_sighted.lua`. Seven change: `run-automated-tests.sh` (the
complexity suite), `inventory.lua` (one gate-rule row), `framework.lua` (`Kit.VERSION` is 35, and
the `--list` renderer split into helpers), `asserts.lua` (`assertSurfaceParity` split into
helpers), `test_eol.lua` (case two split into one helper per check), `mock_base.lua` (a comment, no
line added) and `README.md`. No public member, mock behavior, rendered inventory byte or existing
case name changes. WowAddonStandards#6, LibKa0s#17–#20.

## What changed

### The complexity suite measures a sighted shadow, with parity (`automated-tests-§3`)

lizard 1.24.0 reads Lua through a reader that is not a Lua reader, and loses whole functions without
a word. Measured on 2026-10-01 across the collection: about 1,600 `function` tokens lizard never
listed, 29 of them above CCN 15, every one of them reported as "no function above CCN 15". The
blind spots, each measured against 1.24.0:

| Hazard | What lizard does | Example that loses its function |
|---|---|---|
| `#` | reads it as a C preprocessor line, which swallows the rest of the line, `end` included | `local function len(t) return #t end` |
| `it` | enters the Ruby-like reader's RSpec state, wherever it stands, field and method names included | `for _, it in ipairs(t) do`, `x.it`, `x:it()` |
| `class`, `module`, `begin` | open a block that wants an `end`, bare or after `:`; never after `.` | `{ class = "?" }`, `local module = m`, `x:begin()` |
| `unless` | opens a block wherever it stands, field names included: after `.` it loses the next function on the same line | `{ unless = 1 }`, `local function a(u) return u.unless end local function b() return 1 end` |

The runner no longer runs lizard over the tree. It copies every file the fixed command would read
into a temporary directory, through `lizard_sighted.lua`, and runs the same command there, so
`complexity.txt`'s paths and line numbers are the real files':

- `#` becomes a space;
- `it` and `unless` become `it_` and `unless_` everywhere, and `class` / `module` / `begin` become
  `class_` and so on everywhere but after `.`;
- `function a:b(x)` becomes `function a.b(self, x)` (`function a.b(self)` with no parameters), so a
  method is listed under its own name, `a.b`, where lizard listed `a`. **Watch-list names of methods
  change once** in every consumer's next `RESULTS.md`, and a carried Disposition does not follow a
  renamed entry: re-rule it.
- strings, long strings and comments are copied byte for byte, and no newline is added or removed.

**Parity is what makes the shadow safe.** The sanitizer is a heuristic, and the next blind spot will
not be on its list. So the runner then counts the `function` keyword tokens in every shadow file and
compares them with the `function_cnt` lizard reports for it. A file where the two differ is a file
lizard was blind in, and its functions went unmeasured:

- `suites.complexity.status` is **`fail`**, and the run's verdict is `amber`. It never turns the run
  red and never blocks a commit; at the tag it blocks the release the way a `skip` does.
- the console prints `lizard blind in N file(s): \`path\` (listed of tokens functions listed), ...`
  under the suite's line;
- `manifest.json` carries a new field, **`suites.complexity.blindFiles`** (0 on a sighted run);
- `RESULTS.md`'s watch list opens with **Not sighted — complexity did not pass** and the same list.

One more blind spot was found by parity while this revision was cut, and the sanitizer does not
rewrite it: **a function literal in a `for ... in` header** (`for _, p in ipairs({ function() end })
do`) is not listed. Inside a function its body is folded into the enclosing function's CCN, so
nothing goes unmeasured there, but parity still counts it; hoist the table into a local first.

The suite is a **`skip`** when the shadow cannot be built: no Lua interpreter, no
`lizard_sighted.lua` beside the runner, or no `mktemp`. lizard alone is blind in Lua, so a raw run
would be a pass that measured less than it says.

### lizard's length threshold is the file cap: `-L 1500` (`automated-tests-§3`)

The command is now `lizard -l lua -L 1500 -x "./libs/*" -x "./tests/_kit/*" .`. lizard warns on a
function longer than 1000 lines by default, and the sighted shadow listed two for the first time in
this repository: closures that wrap their whole file (`lib.__AttachIdList`, CCN 1, and
`lib.__AttachWidgets`, CCN 6). A function cannot be longer than its file, so `-L 1500` sets the
length threshold to `layout-§1`'s file cap and leaves length to that rule alone.
**`suites.complexity.warnings` now counts functions above CCN 15 and nothing else.** Case:
`tests/test_kit_runner.lua`, an 1100-line CCN-1 function records 0 warnings.

### `lizard_sighted.lua`

Pure Lua 5.1, no dependencies. `dofile` returns the module; run as a script it is the runner's CLI.

| Member | Contract |
|---|---|
| `S.HAZARDS` | the set `{ it, class, module, begin, unless }` |
| `S.renamed(word, prev)` | `word` as the shadow spells it, given the last significant character before it |
| `S.sanitize(src)` | `src` with every hazard neutralized and every method definition in dot form; same line count, same terminators |
| `S.countFunctions(src)` | the number of `function` keyword tokens outside strings and comments |
| `S.listedCounts(text)` | path → `function_cnt`, read from lizard's per-file table (the warnings block's repeated rows are not counted); a leading `./` is dropped |
| `S.parity(paths, text, read)` | an array of `{ path, tokens, listed }` for every path whose counts differ, in `paths` order; `read(path)` answers the file's bytes; a path lizard never listed counts as 0 |

```sh
lua lizard_sighted.lua shadow <dir>    < paths    # sanitized copies under <dir>
lua lizard_sighted.lua parity <lizard-output> < paths   # run from the shadow; path<TAB>tokens<TAB>listed per blind file
```

### A fifth kit suite: `test_lizard_sighted.lua` (`automated-tests-§3`)

Pins the module: every hazard above rewritten, and fields, strings, comments and look-alike names
(`itself`, `classic`) left alone; the method rewrite; line count and CRLF terminators preserved,
including a short string continued past its line; the token count; the per-file table read once per
file; parity naming exactly the files that differ. When lizard is on PATH, one more case sanitizes a
fixture holding every hazard, runs lizard on it and asserts full parity and the method's own name;
without lizard it is a declared skip. It needs no consumer facts. `inventory.lua`'s gate-rule table
gains `test_lizard_sighted = "automated-tests-§3"`.

### Three kit functions the sighted suite found above CCN 15

Measured sighted for the first time, three kit functions were over the line: `test_eol.lua`'s case
two body (34), `Kit.assertSurfaceParity` (19) and `framework.lua`'s inventory renderer (17). Each is
split into helpers with no behavior change: every failure message is the same string, raised at the
same level; `assertSurfaceParity`'s two forms compare the same keys in the same order; and
`lua tests/run.lua --list` renders byte-identical output. LibKa0s's `tests/test_kit_eol.lua` and
`tests/test_kit_asserts.lua` gained characterization cases for case two's ten verdicts and the
table form's contract first, green before and after.

### `mock_base.lua`: the geometry flip is retired

The comment above `GetHeight` / `GetWidth` promised, from revision 15, a revision that would make
every mock frame answer its recorded geometry, "20 at the earliest". It never shipped, and it is now
retired: it would churn some 308 consumer test files to re-test geometry the four consumers that
draw tab strips all draw through one library helper. The defect it was meant to catch, a strip whose
band moves with the selection (LibKa0s#17–#20), is pinned where the pitch and band are computed, by
the selection-invariance cases in LibKa0s's `tests/test_options_tabs.lua`, which arm geometry
through an instrumented harness whose two atlas families answer different heights. The comment now
says so, in the same ten lines; `mock_base.lua` stays at 1456. An unarmed frame answering 0 is the
kit's contract, not a stopgap.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

Then, in the same commit:

1. Wire the new suite in `tests/run.lua`: `{ name = "test_lizard_sighted", dir = "tests/_kit/" }`.
   `Kit.assertSuiteInventory` fails the run until it is wired.
2. Regenerate `docs/test-cases.md` (eight new cases), and the README's test badge if it counts.
3. Replace any green-gate line that quotes the raw `lizard -l lua -x ...` command with
   `bash tests/_kit/run-automated-tests.sh --suite complexity`: the raw command is the blind one.
4. Run the complexity suite. Every function it newly reports above CCN 15 was there before, unseen;
   it blocks the next release until it is refactored or ruled on. A `blindFiles` above 0 names the
   files to fix; hoisting a function literal out of a `for ... in` header is the usual one.
5. A consumer's own prose that names the revision it holds (`kit revision 34`) moves to 35.
