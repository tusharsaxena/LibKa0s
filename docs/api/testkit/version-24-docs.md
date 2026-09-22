# `testkit` — version 24

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, **`test_prose.lua`**, `run-automated-tests.sh`, `README.md` |
| Version | **24** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.54.0 |
| Status | **Current** |
| Supersedes | [version 23](version-23-docs.md) — the resource guard |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `24` |

Everything revision 23 describes is unchanged here. **One file is added and nothing else moves**:
`test_prose.lua`, the kit's second own suite. `framework.lua` changes by one integer, the version
constant. No member a suite calls is added, removed, renamed or resignatured.

**Adoption is one line, and it is not automatic.** Unlike revision 23, re-vendoring alone does not
turn this on: `Kit.assertSuiteInventory` scans `tests/_kit/` for suites as well as `tests/`, so a
re-vendor that lands the file in a repo which has not declared it goes **red** naming the entry to
add. That is deliberate and it is the same bargain `test_eol.lua` struck — a gate that arrives
silently and runs nothing is the failure this kit refuses everywhere else.

## `test_prose.lua` — the US-English gate (localization-5)

`localization-5` makes US English the source dialect, publishes the `BRITISH` and `ALLOWED` lists a
gate MUST carry **whole**, and requires the rule to be enforced mechanically. `luacheck` does not read
English and a repo's own suites read behavior, so without a suite the rule is enforced by whoever
remembers to sweep.

It is in the kit because by the time it shipped, **seven** repositories had written it by hand and
the copies had already diverged in the part that costs most to get wrong: three called the file
`test_prose.lua`, three `test_spelling.lua`, and two folded it into `test_docs.lua`, so nothing
could tell at a glance which repositories had a gate at all. **Four more had none**, and the drift
in them was found only by a sweep somebody happened to run. A rule enforced by eleven hand-written
copies is eleven chances to carry a subset, and a subset is a gate whose green means nothing.

Wire it in the consuming runner's suite list:

```lua
Kit.run{ dir = "tests/", suites = { "test_schema", ..., { name = "test_prose", dir = "tests/_kit/" } } }
```

**A repo that already has its own copy wires one or the other, never both.** Two gates over one rule
is two lists to keep whole, which is the divergence this file exists to end.

### What it scans

Every authored path `git ls-files` reports — `.lua`, `.md`, `.toc` and `.luacheckrc` — minus the
exclusions `localization-5` names, each one a directory or a file rather than a pattern so the list
cannot quietly grow: vendored code (`libs/`, `Libs/`, `tests/_kit/`), the frozen dated bundles under
`docs/`, `locales/enGB.lua`, and the gate itself.

It **fails rather than passes when it cannot look**. No `io.popen`, no git, an unreadable tracked
file, or a tracked set that comes back empty — each is a red. A gate that goes quiet when it is
blind reports success, which is worse than not existing.

### `tests/prose_waivers.lua` — optional, and why the seam exists

Some British spellings in a Ka0s tree are not the repository's English to correct, and the kit
cannot know which. AceTimer's flag field carries the British double-L spelling of *canceled*, and a
handle records the flag under that name because it is what `mock_record.lua`'s live-timer survey
reads off it — correct the spelling and the survey stops seeing a canceled timer as canceled,
leaving a stand-down assertion quietly unfalsifiable, which is what `slash-commands-7` forbids.
Blizzard spells its `LFG_LIST_APPLICATION_STATUS_UPDATED` status the same way and an addon matches
it verbatim off the event. British spellings of *color* and *gray* sit inside Blizzard's generated
`GlobalStrings` dump, which is the game's English arriving whole from the client. `localization-5`
already says to match game data on the token the game uses; this is that rule meeting this gate.

So a consumer **MAY** ship `tests/prose_waivers.lua`. Absent is the normal case:

```lua
return {
  skipDirs  = { "GlobalStrings/" },                 -- named, never patterned
  skipFiles = { ["docs/vendor-notes.md"] = true },
  waived    = { ["core/LifecycleSetup.lua"] = { ["cancel" .. "led"] = true } },
}
```

The shape is per **file** and per **word**, never per file alone: a whole-file waiver hides every
other British spelling in a file the repo edits often, which is how a gate acquires a blind spot the
size of a module. A waiver file that exists but does not return a table is a **failure**, not an
empty one — the alternative silently widens the gate.

### The one file the library's own gate does not scan

`tests/test_prose.lua` in this repo holds the shipped payload to the same rule, and it exempts
`testkit/test_prose.lua` by name. That is not a hole: the kit gate **is** a copy of the `BRITISH`
list, ninety-one British spellings by construction, and scanning it would redden on every entry the
standard obliges it to carry. `localization-5` names this case as the fourth of its four exclusions.
Every other file under `testkit/` is still scanned, including the README beside it — which is why
that README describes the waived spellings rather than quoting them.
