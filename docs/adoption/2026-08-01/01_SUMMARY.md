# Adoption report — 2026-08-01

Run against LibKa0s at **v1.1.0** (Core 2, DebugLog 3, Slash 4, Options 4, OptionsWidgets 4,
OptionsScroll 2, Perf 5, PerfPanel 3). Method: `docs/adoption-report.md`.

## Verdict

**Adoption is materially sound.** Three adopters, five majors each — fifteen of fifteen
module-adoptions wired and running. Every consumer carries all eight files at the **current**
minor. There is no version skew anywhere, and after line-ending normalisation every vendored byte
matches the ship folder. All four suites are green: 382 / 449 / 629 / 544, zero failures.

What the report found is not drift in the code. It is that **the gate meant to detect drift is
currently lying**, in the direction that matters least intuitively and most practically — the one
consumer whose checkout is correct is the one the documented gate reports as broken. Everything
else is bookkeeping: guards that were never written, a decision that was never recorded, and a
licence that never got vendored.

## Confidence

| Consumer | Grade | Why |
|---|---|---|
| **AbsorbTracker** | High | Minors current, content identical, gate clean at 449/0 and 0/0, seam tests for all five majors, degradation clause consistent across six sites. The reference adoption, and it reads like one. |
| **KickCD** | High | Same version and content position. Two bounded gaps, neither in the adoption: `luacheck` is 7/0 against a documented 0/0 gate with **all seven warnings outside the seam files**, and it carries the only `L`-trap regression guard in the collection — which is to its credit, not against it. |
| **ConsumableMaster** | Medium | Version and content correct. Two things hold it below High: `/cm reset` declines the path-scoped convergence with **no decision recorded anywhere**, and its correctly-CRLF checkout fails the documented `diff -r` gate through no fault of its own. Its ledger is otherwise the best adoption record of the three by a wide margin. |

No consumer is Low. Nothing here is a runtime defect.

## Findings, ranked

### 1 — The `diff -r` gate gives the wrong answer, and the correct repo is the one it fails

`docs/releasing.md` names `diff -r` as *the* proof a vendored copy has not forked. Right now **16 of
this repo's 49 tracked text files** sit in the working tree with **LF** endings despite
`.gitattributes` pinning `* text=auto eol=crlf` — including four of the nine ship files
(`Options.lua`, `OptionsWidgets.lua`, `Perf.lua`, `Slash.lua`), `README.md`, `CHANGELOG.md` and
three of the four `docs/*.md`. AbsorbTracker and KickCD mirror the ship folder's LF, so their
`diff -r` is empty. ConsumableMaster's working tree is CRLF throughout — which is what a fresh
clone produces — so its `diff -r` reports four library files plus `mock_base.lua` as differing.

Content is byte-identical in all three once CR is normalised. Nobody has forked anything.

The reason this is the top finding rather than a footnote: git stores all blobs LF, and under
`eol=crlf` a working tree holding **either** ending reads clean to `git status`. So the state is
invisible, self-perpetuating, and the gate that exists to catch real forks now cries wolf. The
documented next move for a failing `diff -r` is to re-vendor — which will not fix it — and the move
after that is to reach into `libs/`, which is the one action the whole vendoring discipline
forbids. See `03_DEVIATIONS.md` §1.

`tests/test_kitsync.lua` compares byte-for-byte with no normalisation by design. It is green only
because `testkit/mock_base.lua` and `tests/_kit/mock_base.lua` are *both* LF — they agree by
accident, not by policy, and the same class of divergence is one stray editor write away from
firing inside this repo too.

### 2 — The `L`-trap regression guard covers 1 of 15 module-adoptions

The trap itself is **avoided everywhere**. Both descriptor `L` overrides in the collection —
`KickCD/settings/Slash.lua:331` and `ConsumableMaster/core/SlashCommands.lua:1289` — are plain
tables of literals, exactly as the prompt requires. No addon hands the library its locale table.

But the prompt's gate asks for more than that: *"each adopted module has a case proving its
user-visible strings resolve to prose rather than to their own keys."* The
`^[A-Z][A-Z0-9_]+$` assertion exists in exactly one place — `KickCD/tests/test_perfsetup.lua:375`
and `:450`, both for Perf. AbsorbTracker and ConsumableMaster have none at all.

This is a missing guard, not a live bug, and it is cheap: one assertion per adopted module. It
matters because the failure mode is total (every key at once), silent, and in-game only — the
category of bug a test suite is worth having for.

### 3 — ConsumableMaster declines the `reset` convergence, unrecorded

`/cm reset` is still the confirm-gated global wipe (`core/SlashCommands.lua:1199`), and
`CliReset` is never called — the only one of the four schema-CLI verbs CM does not take
(`:1244` takes `CliList`, `CliGet`, `CliSet`). There is no `resetall`.

The divergence may well be right; the popup guards a destructive path and the prompt itself flags
re-anchoring it as the open question. What is missing is the record. `docs/pending/LEDGER.md`
contains **zero** occurrences of "reset" across its LibKa0s entries, and the addon has no
`CHANGELOG.md`. The prompt asks for this to ship "with a CHANGELOG breaking-change entry and a
deprecation message, not silently". It shipped silently.

### 4 — `docs/adoption-prompt.md` is wrong about ConsumableMaster and the landing page

The prompt lists ConsumableMaster among the addons whose landing page changes under convergence #2.
ConsumableMaster **has no landing page with command rows** — `settings/` contains no reference to
`COMMANDS` or to a slash listing, and `LandingRows` is never called. It takes `HelpRows` for chat
help and stops there, which is complete for what it has.

Not a deviation in the addon. An error in the prompt, and the sort that costs a future adopter an
afternoon looking for a page that does not exist.

### 5 — The vendored library carries no licence or copyright notice

`libs/LibKa0s/` in all three consumers holds nine `.lua`/`.xml` files and nothing else. No
`LICENSE`, and `grep -c -i copyright` over the ship files returns 0 for all nine. No adopter's
README mentions LibKa0s at all.

The library is MIT (`LICENSE`, "Copyright (c) 2026 Ka0s"), and MIT asks that the notice accompany
copies. Every adopter currently ships an addon zip containing the library with no indication it is
there or what it is under. Fix is one file in the ship folder; see `04_RECOMMENDATIONS.md` §5.

### 6 — No adopter records which LibKa0s it ships

None of the three has a `CHANGELOG.md`, and no README names the library. Combined with §5, there is
no way to answer "which LibKa0s does AbsorbTracker 1.9.0 carry?" without diffing minors out of the
source. That is precisely the question a re-vendor sweep needs answered fast, and step 7 of a
release is documented as the step that gets forgotten.

### 7 — `RenderGrid` has exactly one consumer

Shipped in OptionsWidgets minor 4 specifically because *"every host had a hand-rolled copy of this
loop"*. ConsumableMaster is the only one calling it. AbsorbTracker and KickCD have not revisited
their caller-driven lists since it landed — KickCD notably still carries the ~450 lines of
`Panel_Render.lua` the prompt records as having no library equivalent.

Not a defect. A note that the newest surface in the library has been contract-tested against one
shape, and the second consumer is where such surfaces historically break.

### 8 — Degradation-stub idiom diverges across the three

AbsorbTracker's PLAN-04 established `NS.LIBKA0S_MISSING` as a single shared cause clause every seam
appends to: 6 sites. ConsumableMaster follows it: 5 sites. KickCD has **0** — it degrades correctly
(`core/CoreSetup.lua:45-86` keeps working pre-library fallbacks and announces once), but with its
own wording.

All three degrade. The user-visible message just differs per addon, which is a consistency gap
rather than a fault, and worth a decision one way or the other before five more addons invent a
sixth phrasing.

## What this report did not check

- **Anything in-game.** Colour codecs, widget dispatch, `hasAlpha`, panel layout, the suspended arm
  and every rendered-output convergence are unobservable headless. Nothing here is evidence about
  live behaviour.
- **Whether host suites would catch a library regression.** Coverage was counted, not evaluated;
  no mutation testing was run against any consumer.
- **The five unadopted targets** (BankLedger, LootHistory, PanelMaster, prettychat, WhatGroup)
  beyond confirming none has `libs/LibKa0s/`. The recon in `docs/adoption-prompt.md` was not
  re-verified and its line numbers may have moved.
- **`WhoGotLoots` / `BuffTextNotifications`** — out of scope, and confirmed to have no `libs/` tree
  at all.
