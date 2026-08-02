# Recommendations — 2026-08-02

Proposals only. **This report changes nothing.** Each carries the command that would do it and its
blast radius. Ordered by value, not by effort.

Nothing here is urgent in the sense of "a user is affected today". No consumer is broken, behind, or
forked. The two proposals worth doing this week are §1 and §2, both of which close paths by which a
*future* change could ship wrong.

---

## §1 — Fix the consumer list in the additive-change proof (`03_DEVIATIONS.md` §3)

**Do this one first.** It is the only finding in the run with a path to a real defect: a library
author following step 8 literally re-runs four suites out of eight and never touches the four hosts
that are the sole consumers of `applySkin`, `format`, `sep`, `pairWith` and most of the instance-member
wrapping.

The fix is to stop hardcoding the list at all, since step 7 immediately above already says the list
lives in `docs/releasing.md` and must be checked rather than assumed. Replace the four-suite roll
call at `docs/adoption-prompt.md:610-613` with the current eight *and* a command that regenerates it,
so the next drift is self-correcting:

```
for a in AbsorbTracker BankLedger ConsumableMaster KickCD LootHistory PanelMaster prettychat WhatGroup; do
    printf '%-18s ' "$a"; (cd ../$a && lua tests/run.lua 2>&1 | tail -3 | tr -d '\n'); echo
done
```

Current totals, measured this run, for whoever writes the replacement: **AbsorbTracker 469, BankLedger
687, ConsumableMaster 561, KickCD 648, LootHistory 534, PanelMaster 609, prettychat 255, WhatGroup
415** — 4,197 in total, each 0 failed.

Also correct the two sentences that reinforce the count: *"Run all four, and know which one is
load-bearing for what you touched"* (line ~615) and *"before deciding a three-suite run was enough"*
(line 619). The paragraph's *argument* is correct and should be kept verbatim; only its arithmetic is
wrong.

**Blast radius:** one documentation file, no code. Nothing re-vendors, no suite moves. Mind the CRLF
hazard the prompt documents at line 549 — `sed -i` with a `$` anchor will silently match nothing.

---

## §2 — Re-title and re-state "Provisional surfaces" (`03_DEVIATIONS.md` §2)

The section heading — *"one consumer each, and treated as unsettled"* — is now false for four of its
own entries. Propose retitling it to something like **"Thinly-consumed surfaces"** and giving each
entry an explicit consumer count, so the next drift is visible rather than implicit:

| Entry | Current text says | Should say |
|---|---|---|
| `applySkin` | "One implementation behind them" | **2** — BankLedger, LootHistory. Second-host contact already discharged. |
| `makeCloseButton` | (bundled with `applySkin`) | **0** — split it out; see §3 below. |
| numeric-enum dropdown | one consumer | **2** — BankLedger, LootHistory. Keep every word of the inference warning; it verified clean. |
| `format` hook | one consumer, updated in place | **3** — BankLedger, LootHistory, prettychat. Move out from under the "one consumer each" heading. |

Add the three surfaces that genuinely *are* single-consumer today and are not currently listed:
`skin` (BankLedger), `sliderCommit` (ConsumableMaster), `pairWith` (prettychat).

Two substantive claims in that section were re-verified this run and **must be kept**: that KickCD's
31 number rows all carry min/max/step and none carries `values`, and that the numeric-enum route has
never been rendered alongside `sliderCommit` (ConsumableMaster has 22 number rows, zero with
`values`). Both still hold. Worth adding: both numeric-enum consumers spell `widget = "Dropdown"`
alongside `values`, and the library reads only `values` — so the inference itself is still untested
by any host.

**Blast radius:** one documentation file, no code.

---

## §3 — Decide, on the record, whether `makeCloseButton` stays in the contract
(`03_DEVIATIONS.md` §1)

A surface with zero shipped consumers, frozen against removal inside `-1.0`. Three honest options:

**Option A — keep it and say why.** Add a line to the DebugLog API document recording that the hook
is intentionally retained for hosts with non-Ka0s chrome, that no shipped consumer passes it as of
v1.5.0, and that its behaviour is pinned by the library's own six cases rather than by any host. This
is the low-cost answer and it makes the next reader's question unnecessary. **Recommended.**

**Option B — mark it deprecated in documentation only.** `-1.0` forbids removal, but nothing forbids
the API document from saying "retained for compatibility; not recommended for new hosts; `applySkin`
covers the whole chrome job." Costs nothing at runtime and steers a `-2.0` conversation.

**Option C — leave it entirely alone.** Defensible: it is tested, it is harmless, and the question
can wait for a `-2.0` planning session. The cost is that this finding will resurface in every future
run of this report with no record of it having been considered — which is exactly the
"unrecorded decision is indistinguishable from a mistake" failure the adoption prompt warns about at
line 524.

Whichever is chosen, record it — the library's own `CHANGELOG.md` version block or the DebugLog API
document, not this bundle, which is frozen.

**Blast radius:** documentation only under A and B. No code change, no re-vendor, no minor bump, and
in particular **no removal** — removing it would break the additive-only contract for any host that
holds a copy.

---

## §4 — Assert the `format` × `colorDecode` precedence in the library's own suite
(`03_DEVIATIONS.md` §4)

The two host sets are disjoint and no ninth adopter is coming, so waiting for a host to exercise this
ordering means waiting indefinitely. The library can pin its own documented behaviour without one.

Add a case to `tests/test_slash.lua` that builds a descriptor passing **both** `format` and
`colorDecode` for a colour row and asserts `format` wins, matching what the API document states. If
the assertion turns out to be awkward to write, the adoption prompt already names that as the signal
worth acting on: *"that is the signal the ordering wants revisiting while it still can be."*

**Blast radius:** one new case in the library's suite; 419 → 420. No minor bump (no behaviour
change), no re-vendor, no consumer suite moves. If it *fails*, that is a real library defect found
cheaply and the recommendation becomes a fix.

---

## §5 — Move the provenance template to v1.5.0 (`03_DEVIATIONS.md` §7)

`docs/releasing.md:99` says the template *"moves with"* each release rather than being corrected
afterwards, and it did not move at v1.5.0. Update both literals — `docs/releasing.md:96` and
`docs/adoption-prompt.md:458` — to v1.5.0, and consider whether the release checklist should name
this as a step so it moves by process rather than by memory.

**Blast radius:** two documentation lines. No consumer is affected; all eight already name v1.5.0
correctly and none copied the stale literal.

---

## §6 — Nothing to do about the two mid-sentence provenance lines
(`03_DEVIATIONS.md` §6)

Explicitly recommending **no action** on LootHistory's and WhatGroup's phrasing, so that a future
sweep does not spend effort "fixing" two correct lines. Both are true, both name v1.5.0, and both are
matched by the `[Bb]undles` gate pattern — which exists in that form precisely because an earlier
capital-anchored grep produced a false negative on LootHistory.

If anything is done here, it should be the reverse of a fix: a sentence in `docs/releasing.md` noting
that the template is a shape, not a required literal, and that the gate matches either phrasing.

---

## Not recommended

- **Re-vendoring anything.** All 64 minor cells are current and all 32 diffs are empty. There is
  nothing to re-vendor and running the sweep would only risk introducing the line-ending divergence
  the v1 run of 2026-08-01 had to disentangle.
- **Touching any `libs/` folder anywhere**, for any reason, per the standing rule.
- **Adding consumers.** `WhoGotLoots` and `BuffTextNotifications` remain correctly out of scope until
  they are on the standard at all, and neither holds a vendored library today.
- **Chasing the +2 test-count drift as a defect.** It is four repos each having added a
  `test_vendor_sync.lua` pair, which is the gate that made this report's byte-fidelity section
  self-verifying. The drift is the system working.
