# `testkit` — version 37

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_lines.lua`, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **37** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.69.0 |
| Status | Superseded |
| Supersedes | [version 36](version-36-docs.md) — no Line regions |
| Superseded by | [version 38](version-38-docs.md) — `--list` Totals count only the cases that run |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `37` |

Everything revision 36 describes is unchanged here except what follows. **One file is added,
`mock_lines.lua`**, and three change: `mock_base.lua`, which loads it and passes every tracked frame
through it (two lines); `framework.lua`, whose `Kit.VERSION` is 37 and which changes in nothing
else; and `README.md`, whose file table and "vendor as one folder" sentence name the new file. No
public member is renamed or removed, and no kit case or runner output changes.

## What changed

### Mock frames make recording Line regions (`mock_lines.lua`)

LibKa0s v1.69.0 ships a line chart (`LibKa0s-Widgets-1.0`'s `WidgetsLineChart.lua`) that draws every
segment, grid rule and crosshair as a `Line` from `Region:CreateLine`. Through revision 36
`CreateLine` answered from `mock_base.lua`'s metatable, which hands back the frame itself, so every
line a chart drew was the same object as its parent and every endpoint it set was dropped (fidelity
rules 1 and 3). Every frame the mock tracks now carries a recording `CreateLine(name, layer,
template, sublevel)` that answers a **new** Line per call, listed in creation order on the frame as
`__madeLines`. A Line carries, as plain recording methods:

| Method | What it records and answers |
|---|---|
| `Show()` / `Hide()` / `SetShown(v)` / `IsShown()` | A boolean, `true` on a new line, as a new region is shown in the client. Field `__shown`. |
| `SetStartPoint(relPoint, relTo, x, y)` / `GetStartPoint()` | The four values as given (`x`, `y` default 0), answered as four values; `nil` before any start is set. Field `__start`. |
| `SetEndPoint(relPoint, relTo, x, y)` / `GetEndPoint()` | The same, for the other end. Field `__end`. |
| `ClearAllPoints()` | Forgets both ends, as it does on a Region. |
| `SetThickness(n)` / `GetThickness()` | The number; 1 on a new line. Field `__thickness`. |
| `SetColorTexture(r, g, b, a)` | The color, `a` defaulting to 1. Field `__color`. |
| `SetVertexColor(r, g, b, a)` | The same shape. Field `__vertex`. |
| `SetTexture(path)` | The path. Field `__texture`. |
| `SetAlpha(a)` / `GetAlpha()` | The number; 1 before any is set. Field `__alpha`. |
| `SetDrawLayer(layer, sub)` | Fields `__layer`, `__sublevel`; `CreateLine`'s own layer and sublevel arguments land in the same fields. |

**What is not modeled, and why.** A Line is not a Frame: it has no scripts, no mouse, no children
and no geometry of its own, so **any capitalized method `mock_lines.lua` does not define raises**,
naming itself (`testkit: a Line has no SetScript ...`). A chart that called `SetScript` on a line
would fail in the client; it fails here. A Line is not a tracked frame, so `M.__shownFrames()`
and every other frame survey are unchanged.

The five cases that pin this live in this repo's `tests/test_mock_lines.lua`; they are **not** kit
cases, so a consumer's suites list and `docs/test-cases.md` do not change.

**What a consumer suite may notice.** A consumer suite that called `CreateLine` on a kit frame and
relied on getting the frame back now gets a Line, and a frame method called on it raises. Three
consumers model `CreateLine` in their own harnesses, and each copy keeps working: AuraMaster
(`tests/wow_mock.lua`, assigned after `trackFrame`, so its own copy wins over the kit's), KickCD
(`tests/wow_mock_frames.lua`) and MultiMeters (`tests/mock_frame.lua`, its own frame factories).
AuraMaster's `modules/Anchors_Snap.lua` calls `CreateLine` in addon code. Each consumer's re-vendor
must run its own suite to confirm nothing relied on the old answer.

**What a consumer owes:** the whole-folder copy.

## Adoption

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

Nothing else. The suites list does not change and no kit case name changes, so a consumer's
`docs/test-cases.md` does not change. A copy that leaves out `mock_lines.lua` fails at load, like
one missing `mock_record.lua`, `mock_events.lua` or `mock_resize.lua`. A consumer's own prose that
names the revision it holds (`kit revision 36`) moves to 37 in the same commit.

## Moving to 38

Copy the kit whole and regenerate `docs/test-cases.md` in the same commit: the `## Totals` table's
count rows and Total stop counting declared skips, which move to a `| Skipped | N |` row of their
own, so Total equals the README badge. No suite and no case name changes.
