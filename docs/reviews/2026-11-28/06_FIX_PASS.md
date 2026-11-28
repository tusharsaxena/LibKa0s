# Fix pass — 2026-11-28 review

Task `IS-F1` of Ka0s Drop Watcher's plan `docs/superpowers/plans/2026-11-27-itemsearch-split.md`.
Each finding was checked against the code before it was acted on, and each fix was test-first
(a `-- red under:` case seen failing, then green). All land inside v1.119.0, before the tag: every
Verdict file stays at minor 1. The bundle above is as the reviewer wrote it; this note is the only
file added.

| Finding | Outcome | Commit |
|---|---|---|
| F-001 | **Fixed, another way than C-01.** Refilling `lib.C` in place would still leave the files after it holding the sub-tables and values they captured at load (`local A, W = C.ARMOR_SUBCLASS, ...`, `local MH, OH = C.SLOT...`). Instead each secondary carries an `ORDER` and re-runs when a file before it in load order ran after it did (`lib.__Stale` / `lib.__Ran`), so a lone VerdictConstants bump rebuilds everything after it; a same-minor copy runs nothing | `IS-F1.1` |
| F-002 | Fixed: `lib.EventsFor(client)` and `v:Events()` (additive). The consumers' hand-kept `EVENTS` lists move onto it in their own repos | `IS-F1.2` |
| F-003 | Fixed: `StandUp` protects each `host.registerEvent` call; a refused name costs that event alone, with a debug line | `IS-F1.2` |
| F-004 | Fixed (C-03): `v:Config()` fills a missing key from `Settings.DEFAULTS` | `IS-F1.3` |
| F-005 | Fixed: `Request` answers `nil, "unavailable"` while stood down and asks for nothing | `IS-F1.4` |
| F-006 | Fixed: one waiter per callback; `Judge` hands one callback per instance | `IS-F1.4` |
| F-007 | Fixed: the fixture counts registrations and the case asserts each is 1 (seen failing under a double registration) | `IS-F1.2` |
| F-008 | Fixed: the blank line is gone | `IS-F1.5` |
| F-009 | Fixed (C-05): no `spec.print`, no line | `IS-F1.5` |
| F-010 | **Open for the owner.** Widen the slider or clamp the import: a UX ruling, and the behavior is Drop Watcher's, moved unchanged | — |
| F-011 | Fixed: kit revision 66, the runner asks git and names a worktree by its repository | `IS-F1.6` |
| F-012 | **Rejected for now:** unverified, nothing measures it; no change without a measurement | — |

Also fixed: `LibKa0s/Verdict.lua`'s header lists `VerdictSettings.lua` (`IS-F1.5`). The v1.119.0
record (CHANGELOG, Verdict document and manifest, kit documents, `docs/test-cases.md`) moved with
each commit, and the release bundle is taken again after this note is committed.
