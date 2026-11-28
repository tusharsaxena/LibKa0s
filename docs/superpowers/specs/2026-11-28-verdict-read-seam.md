# Verdict read seam: a host overrides only the reads it names — design

**Date:** 2026-11-28
**Issue:** LibKa0s#111 (filed from the Item Search split run, DropWatcher#19)
**Ruling:** the owner, 2026-11-28: seam-wrapping (option 1), not a parity test. A host overrides only
the reads it names; Drop Watcher drops its duplicate compat reads.
**Plan:** Drop Watcher `docs/superpowers/plans/2026-11-28-issue-fixes.md`, task L4.

## The problem

`LibKa0s-Verdict-1.0` resolves every read an instance makes as `host.reads[name] or lib.Reads[name]`,
at call time (`Verdict.lua`'s `readsFor`). Drop Watcher's host hands a `reads` table whose `__index`
answers `NS.Compat[name]` for every name, so 50 of the 53 `lib.Reads` members are shadowed by a
same-named addon copy (33 of them with no other caller in the addon). It does that for one reason:
its simulator (`LibKa0s-Sim-1.0`'s seam, `core/SimSetup.lua`) wraps `NS.Compat` in place, and a read
the instance makes through `lib.Reads` would escape the seam. A provider for `InventoryItemLink`,
`BagItemLink`, `BagSlotCount`, `BagItemLevelQuality`, `InventoryItemLevel` or `UnitClass` would not be
asked, and a guarded member would not be guarded. Nothing checks that the two copies still agree.

## The design

Two library changes, one per major. Neither changes what an existing host sees.

### 1. Verdict: the instance read table is a real table (`Verdict.lua` minor 3)

`v.R` is built at `New` with one **forwarder per read**: a plain function member for every name in
`lib.Reads` and every name in a plain `host.reads` table, each resolving `host.reads[name]`, else
`lib.Reads[name]`, **at each call**. So:

- a host that names one read (`host.reads = { PlayerRole = fn }`) gets its own for that read and
  `lib.Reads` for every other, and `host.reads` may still be replaced or cleared later (call time);
- a newer `VerdictReads.lua` that replaces `lib.Reads` after the instance was built is read at once;
- because the members are real function members, a seam can wrap the table **in place**, the way it
  wraps a host's Compat table. A name added by a later minor after `New` still resolves (through the
  table's `__index`, as before), but is outside any seam until the next reload.

What moves for a reader: `v.R.X` is the instance's forwarder, no longer `rawequal` to
`lib.Reads.X` or to the host's function. Calling it answers what they answer, arguments, returns and
nil holes passing through. `v.R` is the documented name of the table (it already was).

### 2. Sim: one seam covers a second table (`Sim.lua` minor 6)

```lua
local keys = Sim:Cover(seam, tbl, opts)   -- opts = { pure = {[key]=true}?, guarded = {[key]=fn}? }
```

`Sim:Cover` wraps every function member of `tbl` not pure (the seam's `pure` or `opts.pure`) in
place, under the **same seam state** as the seam's own Compat table: the same active flag, the same
`Live` bypass and the **same providers**, keyed by member name. So:

- a provider the host already registers for `InventoryItemLink` answers the instance's
  `R.InventoryItemLink` too, handed the read's own live member (the forwarder, so `lib.Reads`) as its
  fallback;
- a key the seam guards (`NewSeam`'s `opts.guarded`) is guarded on the covered table as well, and a
  covered table may guard keys of its own (`opts.guarded`, validated as `NewSeam` validates);
- `SetProvider` accepts a key that exists only on a covered table (a read the host no longer copies),
  so `Cover` runs before the providers register;
- `seam:Keys()` lists the covered keys too, and `seam:Unwrapped()` reports a member added to or
  replaced on a covered table after `Cover`, as it does for the Compat table;
- a table is wrapped once: `Cover` raises on a table `NewSeam` or `Cover` already wrapped, on a seam
  `NewSeam` did not make, and on a guarded key that is not a wrapped member of `tbl`.

`Cover` is a library member, beside `NewSeam`, **not a seam member**: the seam stays exactly
`SetProvider`, `Live`, `Keys` and `Unwrapped`, so no host's inert seam stub (the reference in
`tests/test_sim_stub.lua`, parity-checked in every Sim host's suite) grows. A host calls it only when
the library is present, which it already knows (`NS.SimSeam` is its stub otherwise).

### What a host writes

```lua
-- core/VerdictSetup.lua, once the instance exists and before the simulator's providers register
NS.VerdictEngine = V:New({ client = CLIENT, reads = { PlayerRole = NS.Compat.PlayerRole }, ... })
if Sim then Sim:Cover(NS.SimSeam, NS.VerdictEngine.R, { pure = { PlayerRole = true } }) end
```

`pure = { PlayerRole = true }` because the host's `PlayerRole` is already a member of the wrapped
`NS.Compat`: covering it again would route one call through the seam twice (a provider consulted
twice). Leaving it out is not a leak, only a second consultation.

## Why not the parity test

A parity test (option 2) checks that 50 copies still agree on the kit's mocks; it would keep the
copies, run in every consumer, and still let a live-client difference through. Seam-wrapping deletes
the copies, so there is nothing to keep in parity.

## What stays the host's

- `host.reads.PlayerRole` in Drop Watcher: its role comes from its own role store (the override and
  the saved answer), which `lib.Reads.PlayerRole` (no store) does not read.
- Nothing in Item Search: it has no simulator and no role store, so it hands no `reads` at all.

## Tests

- Verdict (`tests/test_verdict_instances.lua`): a host naming one read gets its own for it and
  `lib.Reads` for every other, both at call time; `v.R`'s members are real (rawget) members, one per
  `lib.Reads` name; a newer `lib.Reads` is read through an old instance; a Sim-covered instance read
  is answered by the seam's provider and guarded by the seam's guard while a session runs, with no
  host copy, and answers live when idle.
- Sim (`tests/test_sim_seam.lua`, idle; `tests/test_sim_session.lua`, active): `Cover` wraps in
  place, lists the keys, extends `Keys` and `Unwrapped`, raises on every bad argument; under a
  session a shared provider answers both tables with each table's own fallback, the seam's guard and
  `Cover`'s own guard hold inside `Live`, and `Live` reads the covered table live.
