# Analysis — 20260824-185459

- **Addon:** LibKa0s 1.12.0 (manifest `release` 1.13.0 — the pre-tag release run)
- **Verdict:** green
- **Commit:** 20f6112 (master, dirty)
- **Previous run:** [`20260824-153936`](../20260824-153936/) — the pre-tag release run for v1.12.0

## Headline

Green: `luacheck` clean over 14 files, 577 of 577 harness cases, complexity zero above CCN 15 for the
sixteenth consecutive run. `LibKa0s-Widgets-1.0` moves to minor 5; nothing else in the library moves.

**This release deletes a frame, and the frame was the bug.** The menu was dismissed by a full-screen
`Button` at `FULLSCREEN` strata whose `OnClick` hid it — a click-*catcher*, which is to say a frame
whose whole job was to intercept. It never called `RegisterForClicks`, so it took `LeftButtonUp` and
nothing else: a right-click anywhere while a menu was open landed on it, found no handler, and went
nowhere. The menu stayed open and whatever was under the cursor never heard the click. Even the
left-click it did handle was consumed.

**It took an adopter with a right-click surface to see it.** The defect has been there since minor 1
and neither shipped consumer had a right-click menu on the same window as a dropdown. LootHistory
adopted at v1.12.0 and became the first; there a right-click on a history row did nothing at all
until the player left-clicked to dismiss the menu first. That is the fourth release of this major in
a row to come from an adopter hitting a gap during the same adoption prompt.

**The fix is to stop intercepting.** The menu registers `GLOBAL_MOUSE_DOWN` while shown and closes
itself when the press was neither on the menu nor on the dropdown it dropped from. The event fires
for a press anywhere on any button whether or not something else consumed it, so the menu reacts to
a click it never touched and the click still lands. One press now dismisses the menu *and* does the
thing the player pressed on — which is a **visible behavior change**, because under minor 4 that
click was absorbed. Adopters get a smoke-test line, not a code change.

**The mock could not express any of this, and that is the second half of the release.** Against
`test_widgets.lua`'s frame factory, every `RegisterEvent` fell through the catch-all metatable and
silently answered the frame itself, so neither "is the menu listening?" nor "what does it do when
the event arrives?" was an askable question. The factory now models `RegisterEvent`,
`UnregisterEvent`, `IsEventRegistered` and `IsMouseOver` — the cursor defaulting to *not* over the
frame, which is the honest default for a suite about clicking elsewhere. This is the same
mock-fidelity move v1.11.2 made for `FontString:SetText(): Font not set`, and for the same reason:
a stub friendlier than the client is a suite that cannot fail.

## Suites

| Suite | Status | Result | Artifact | Moved since `20260824-153936` |
|---|---|---|---|---|
| lint | pass | 0 warnings / 0 errors in 14 files | [`lint.txt`](lint.txt) | No change |
| tests | pass | 577 passed, 0 skipped, 0 failed, 577 total | [`tests.txt`](tests.txt) · [`test-cases.md`](test-cases.md) | **+9 net** — ten new cases in `test_widgets.lua`, one retired |
| perf | skip | 0 scenarios — no `tests/perf.lua` | none — the suite did not run | No change — permanent skip |
| complexity | pass | see below | [`complexity.txt`](complexity.txt) | **NLOC +70**, functions +15; every average and the max unmoved |

The one retired case is `Widgets.CloseMenu hides the click-catcher too`, which tested a frame that no
longer exists. It was rewritten rather than deleted: the claim it was really making — that
`CloseMenu` hides and leaves the teardown to the menu's own `OnHide` — is still true, and is now
pinned against the event registration instead.

**Complexity, in full** — every field of `lizard`'s footer as recorded in
[`manifest.json`](manifest.json) `suites.complexity`:

| Metric | Value | Previous |
|---|---|---|
| Total NLOC | 9917 | 9847 |
| Functions | 1447 | 1432 |
| Average NLOC | 6.3 | 6.3 |
| Average CCN | 1.9 | 1.9 |
| Max CCN | 14 | 14 |
| Average tokens | 48.4 | 48.6 |
| Functions above CCN 15 | 0 | 0 |
| Warning rate | 0.00 | 0.00 |

`Widgets.lua` is close to NLOC-neutral — a catcher and its `OnClick` out, an `OnEvent`, an `OnHide`
and a four-line `__OutsideClick` in. Most of the move is the ten cases and the four mock methods.

## What this run does not cover

- **That `GLOBAL_MOUSE_DOWN` behaves as assumed.** The suite fires the event by hand. That it
  actually fires for every button, in every host, whether or not another frame consumed the click,
  is a client behavior no headless run can check — it is the load-bearing assumption of this release
  and it belongs in each adopter's smoke tests.
- **That the click now passes through.** The mock has no notion of a click reaching a frame
  underneath; the suite can only show that the menu no longer builds anything to stand in the way.
- **That any of it draws.** No suite renders a pixel.
- **Every other place a mock is friendlier than the client.** Two have now been found and fixed, both
  by an adopter meeting the real client. There is still no inventory of the rest.
