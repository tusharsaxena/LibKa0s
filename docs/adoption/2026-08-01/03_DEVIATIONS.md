# Deviations — 2026-08-01

Eight. None is a runtime defect. They are ordered by what each one costs if left alone.

Each is labelled on two independent axes, because they have different fixes:
**Deliberate?** — was this a choice, or an accident. **Recorded?** — is the choice written down
where the next person looks.

---

## §1 — The ship folder violates its own line-ending policy, and the `diff -r` gate inverts

**Deliberate:** no. **Recorded:** no. **Severity:** high — the gate is the control.

### What

**16 of this repo's 49 tracked text files sit in the working tree with LF line endings**, against a
`.gitattributes` that pins `* text=auto eol=crlf` and explicitly `*.lua text eol=crlf`,
`*.md text eol=crlf`. Four of them are in the ship folder — `Options.lua`, `OptionsWidgets.lua`,
`Perf.lua`, `Slash.lua`. The rest are `CHANGELOG.md`, `README.md`, three of the four `docs/*.md`,
both copies of `mock_base.lua`, and five files under `tests/`.

So this is not a ship-folder accident. It is a repo-wide working-tree condition, and the ship folder
is simply where it becomes contagious: AbsorbTracker and KickCD hold copies with the same LF
endings, because they were `cp -r`'d from this folder in that state. ConsumableMaster holds CRLF
throughout.

That both `testkit/mock_base.lua` and `tests/_kit/mock_base.lua` are LF is also why
`test_kitsync.lua` is green — the two copies agree by luck rather than by policy.

### Why nothing has caught it

Git stores all nine blobs as **LF** (`git cat-file -p HEAD:LibKa0s/Options.lua | file -b -` → no
CRLF). Under `text=auto eol=crlf`, the clean-filter normalises CRLF→LF on the way in, so a working
tree holding *either* ending round-trips to the same blob. Every one of the four repos reports
`git status` clean. Nothing in any repo's history, status or test suite will ever mention this.

### Why it matters

`docs/releasing.md` names `diff -r` as the proof a vendored copy has not forked, and states plainly
that *"nothing about 'the tests are green' will tell you the copies have diverged."* That gate is
now producing a false positive on the one consumer whose checkout is **correct** — ConsumableMaster's
CRLF is what a fresh clone of any of these repos produces — and passing on the two whose working
trees share the ship folder's corruption.

The documented response to a failing `diff -r` is to re-vendor. Re-vendoring from an LF ship folder
into a CRLF checkout will not converge them; it will just move the LF downstream. The step after a
re-vendor that does not work is the one to worry about: reaching into `libs/` by hand, which
`docs/adoption-prompt.md` names as creating "a fork nobody knows about".

`tests/test_kitsync.lua` compares `testkit/` against `tests/_kit/` byte-for-byte **with no
line-ending normalisation**, deliberately. It is green today only because both copies in this repo
happen to agree. One editor write on one side fires it, with the same non-diagnosis.

### Evidence

`05_EVIDENCE.md` §2, §3.

### Cost of leaving it

The next release's re-vendor sweep hits a `diff -r` that fails for a reason that is not drift, on a
repo that is not at fault. Best case someone loses an hour. Worst case someone edits `libs/`.

---

## §2 — The `L`-trap regression guard covers 1 of 15 module-adoptions

**Deliberate:** no. **Recorded:** the requirement is, in `docs/adoption-prompt.md`. The gap is not.
**Severity:** medium — nothing is broken, and nothing would notice if it broke.

### What

The trap is avoided. Both descriptor `L` overrides in the collection are plain literal tables:

- `KickCD/settings/Slash.lua:331` — `L = NS.L and { LIST_HEADER = ... } or nil`, one key, values
  drawn from `NS.L` but the table itself constructed fresh. Correct.
- `ConsumableMaster/core/SlashCommands.lua:1289` — `L = SLASH_STRINGS`, defined at `:1257` as
  seven string literals. Correct.

AbsorbTracker omits `L` entirely everywhere, which is the documented common case for an addon that
translates nothing.

The guard is what is missing. `docs/adoption-prompt.md` requires "one cheap assertion per adopted
module: a rendered label MUST NOT match `^[A-Z][A-Z0-9_]+$`", and the gate restates it as *"each
adopted module has a case proving its user-visible strings resolve to prose rather than to their own
keys."* That assertion appears in exactly one file, for one module:
`KickCD/tests/test_perfsetup.lua:375` and `:450`.

AbsorbTracker: zero. ConsumableMaster: zero. KickCD's other four majors: zero.

### Why it matters

KickCD **shipped** this bug — a perf panel rendering `PANEL_TITLE_SUFFIX`, `STEP_START`,
`STEP_MEASURE_A` as raw keys. It is the only failure in the whole exercise with a shipped-broken
precedent, it fails for every key at once, and it is invisible outside the game client. The two
assertions that exist are exactly the ones written *after* it happened.

Nothing currently stops a future edit — adding an `L` to a descriptor that does not have one,
"simplifying" `SLASH_STRINGS` to `KCM.L` — from reintroducing it in thirteen places.

### Evidence

`05_EVIDENCE.md` §6.

---

## §3 — ConsumableMaster declines convergence #1 with no decision recorded

**Deliberate:** almost certainly. **Recorded:** no. **Severity:** medium.

### What

`ConsumableMaster/core/SlashCommands.lua:1199` still defines:

```
{"reset", "Reset all priority lists and stat overrides to defaults", function() ... StaticPopup_Show("KCM_CONFIRM_RESET") ... end}
```

`CliReset` is never called anywhere in the addon. It is the only one of the four schema-CLI verbs
CM does not take — `:1244` wires `CliList`, `CliGet` and `CliSet`. There is no `resetall`.

The other two adopters converged: `/at reset <path>` + `/at resetall`,
`/kcd reset <path>` + `/kcd resetall` with the spell-database rebuild re-homed under a subcommand
group.

### Why it is probably right, and why it is still a finding

The prompt itself flags the hazard: CM's reset "is a confirm-gated global wipe that becomes a
one-row reset, so re-anchor the popup to `resetall` or the destructive path loses its guard."
Keeping the popup is a defensible reading. The `resetall` half was simply never built.

The problem is the silence. `ConsumableMaster/docs/pending/LEDGER.md` contains **zero** occurrences
of the string "reset" across its seven LibKa0s entries — a ledger otherwise detailed enough to
record which shade of grey the combat notice uses. The addon has no `CHANGELOG.md`. The prompt asks
for this decision to ship "with a CHANGELOG breaking-change entry and a deprecation message, not
silently."

So the collection now has one addon whose `reset` verb means something different from the other
two, and no artefact anywhere says that was intended. A future consistency sweep will read it as an
oversight and "fix" it — removing a confirmation guard from a destructive path.

### Evidence

`05_EVIDENCE.md` §5, §7.

---

## §4 — `docs/adoption-prompt.md` misstates ConsumableMaster's landing page

**Deliberate:** n/a. **Recorded:** n/a — this is the record being wrong. **Severity:** medium for
the next adopter, zero at runtime.

### What

The prompt's convergence #2 section reads: *"BankLedger, LootHistory and PanelMaster all change
here; so do KickCD, ConsumableMaster, prettychat and WhatGroup."*

ConsumableMaster has no landing page carrying command rows. `settings/` holds `Category.lua`,
`General.lua`, `MacroBar.lua`, `Panel.lua`, `StatPriority.lua`, and a grep across all five for
`COMMANDS` or a slash listing returns nothing. `LandingRows` is never called. The addon takes
`HelpRows` for chat help — `tests/test_slashsetup.lua:57` pins the first row byte-for-byte against
`lib.FormatRow` — and there is nothing else for the convergence to apply to.

This is **not applicable**, not declined. The distinction matters: a declined convergence is a
decision to review, an inapplicable one is nothing at all.

### Cost of leaving it

The prompt is the artefact every future adopter reads first, and it is described as authoritative
about what is already known. A reader checking CM as a worked reference for convergence #2 finds no
landing page and has to work out whether the prompt is wrong or the adoption is incomplete.

---

## §5 — The vendored library ships with no licence or attribution

**Deliberate:** no. **Recorded:** no. **Severity:** medium, and non-technical.

### What

`libs/LibKa0s/` in all three consumers contains nine files — `Core.lua`, `DebugLog.lua`,
`LibKa0s.xml`, `Options.lua`, `OptionsScroll.lua`, `OptionsWidgets.lua`, `Perf.lua`,
`PerfPanel.lua`, `Slash.lua` — and nothing else. No `LICENSE`.

The ship files carry no notice either: `grep -c -i copyright LibKa0s/*.lua` returns 0 for all nine,
and `\bMIT\b` matches nothing in any of them.

No adopter's README mentions LibKa0s. None has a `CHANGELOG.md`.

This repo's root `LICENSE` is MIT, "Copyright (c) 2026 Ka0s" — whose terms ask that the notice
accompany copies of the software.

### Why it matters

Each adopter publishes an addon zip that includes this library with no indication it is present, no
statement of what it is, and no licence text. That is a distribution issue rather than a code one,
and it applies to every release already published. It is also the cheapest finding here to fix.

### Evidence

`05_EVIDENCE.md` §8.

---

## §6 — No adopter records which LibKa0s version it carries

**Deliberate:** no. **Recorded:** n/a. **Severity:** low, compounding.

### What

None of the three has a `CHANGELOG.md`. No README names the library. The only way to establish what
version an installed adopter is running is to grep the eight minor constants out of its vendored
source.

`docs/releasing.md` says of the re-vendor step: *"This is the step that gets forgotten. It already
happened once… both repos' test suites stayed green the whole time."* The mitigation offered is an
after-the-fact `diff -r` — which, per §1, currently misreports.

With three consumers this is manageable by hand. The remaining-targets list adds five more.

---

## §7 — `RenderGrid` has one consumer

**Deliberate:** yes, implicitly. **Recorded:** partially — CM's LIBKA0S-06 records why it needed it.
**Severity:** low, forward-looking.

### What

`RenderGrid` landed in OptionsWidgets minor 4 with the rationale that *"every host had a
hand-rolled copy of this loop, which is the duplication this library exists to end —
ConsumableMaster's `Helpers.Grid` was the third."*

ConsumableMaster calls it. AbsorbTracker and KickCD do not — neither has revisited its
caller-driven lists since the surface appeared. KickCD in particular still carries
`settings/Panel_Render.lua`, part of the ~450 lines the prompt records as having no library
equivalent.

If the third hand-rolled copy justified building it, the first two are still there.

### Why it is worth writing down

`RenderGrid` is the newest public surface in the library and its contract has been shaped against
exactly one host. The pattern the prompt describes — *"each of the three adopters so far has
surfaced a descriptor assumption that only held for the ones before it"* — says its second consumer
is where it bends. Better to find that now than during a sixth adoption.

---

## §8 — Degradation-stub idiom differs across the three

**Deliberate:** partly. **Recorded:** AbsorbTracker's side is (PLAN-04). KickCD's divergence is not.
**Severity:** low.

### What

AbsorbTracker's PLAN-04 established a single shared cause clause: *"`NS.LIBKA0S_MISSING` in
`core/CoreSetup.lua` is the single cause clause, and all five seams append their own 'so <what> is
unavailable'."* Six sites.

ConsumableMaster follows the same shape — five sites.

KickCD has zero. It degrades correctly: `core/CoreSetup.lua:45-86` returns early when the library
is absent, keeps the pre-library implementations as working fallbacks (including the
`pcall(table.concat)` secret probe and the `<secret>` sentinel), and announces once via its own
message — *"(expected in libs/LibKa0s); running on reduced built-in fallbacks."*
`settings/OptionsSetup.lua:137-180` documents its stub as deliberately load-completing rather than
member-answering, and explains — correctly — why it needs less than AbsorbTracker's.

All three degrade. Nothing is broken. But a user with a broken install sees a different sentence
depending on which addon they have, and the shared clause exists precisely so they would not.

### Evidence

`05_EVIDENCE.md` §9.
