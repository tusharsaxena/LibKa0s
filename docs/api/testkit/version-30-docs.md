# `testkit` — version 30

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **30** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | unreleased — superseded by revision 31 before v1.62.0 was cut |
| Status | Superseded |
| Supersedes | [version 29](version-29-docs.md) — the prose gate's machinery and self-tests beside it |
| Superseded by | [version 31](version-31-docs.md) — generated files out of the band table |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `30` |

Everything revision 29 describes is unchanged here except what follows. No file is added. Three
files change: `run-automated-tests.sh`, which writes the complexity watch list; `README.md`, whose
runner notes describe it; and `framework.lua`, whose `Kit.VERSION` is 30. No member is added,
removed or renamed, no kit case is added, removed or renamed, and no mock changes.

## What changed

### An empty watch-list table says `None.` under its header

`RESULTS.md`'s `## Complexity watch list` carries two generated tables, the functions `lizard`
warned on and the files by `layout-§1` band. When one of them has nothing to list, the runner now
prints its header row and separator, a blank line, and then `None.`:

```markdown
### Functions `lizard` warned on

| Function | CCN | Location | Disposition |
|---|---|---|---|

None.
```

The history of that one case:

- **Revision 25 and earlier** printed `None.` in place of the table, so the section changed shape the
  day a repo reached zero warnings.
- **Revisions 26 to 29** printed the header and separator alone. `automated-tests-§4` asks for two
  tables with header rows, and that held, but a table with no rows under it reads as a record that
  was cut short. The 2026-09-26 automated-tests sweep saw it in every addon's `RESULTS.md` and filed
  it as `ATS-20`.
- **Revision 30** prints both, as the `AUTOMATED_TESTS.md` playbook's Step 3 asks: `None.` where a
  table would be empty, because an empty watch list is a result and not a reason to drop the heading.

**The blank line matters.** GitHub-flavored Markdown reads a line with no pipes that sits directly
under a table as one more row of it, so without the blank line `None.` would render as a one-cell
table row. The runner's reader of the previous watch list, which carries each entry's disposition
forward, only reads lines that open with `|`, so `None.` is never read back as an entry.

A table with rows prints no `None.`. The `manifest.json` figures, the trend row and the watch list's
opening sentence are unchanged.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

Nothing else. The suites list does not change and no case name changes, so `docs/test-cases.md`
does not change. The next run of `run-automated-tests.sh` writes `None.` under whichever watch-list
table is empty. The previous `RESULTS.md` needs no edit: the watch list is regenerated whole on every
run that measures complexity.
