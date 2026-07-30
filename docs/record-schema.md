# Perf record schema

The shape `BuildRecord` emits and `Save` persists, for `LibKa0s-Perf-1.0`. `schema` is the version
stamp — this document covers **schema 2**.

## Schema 2 vs. schema 1

Schema 1 was AbsorbTracker's own, addon-local format, documented in
`AbsorbTracker/docs/perf-runs/README.md`. Extracting the probe into a shared library that any host
can adopt added two fields schema 1 didn't need:

- **`addon`**, top level — schema 1 had exactly one possible host, so the record didn't need to say
  which addon produced it. A shared library's SavedVariables ring can in principle hold captures
  from more than one consumer's history, so every record now names its host.
- **`within`**, per bucket — schema 1's bucket nesting (`repaintPass` contains `paintBar`) was
  implicit, hardcoded into `FormatReport`'s printing order and known only by reading the source.
  Nesting is now a property of the descriptor's `buckets` declaration, carried onto each bucket in
  the record so a reader can reconstruct the nesting without the addon's source in hand.

## Clean break, no migration

`Save` stamps every write with `lib.SCHEMA` (currently `2`). If the ring under the host's `sv` global
is found stamped with any *other* schema — including no schema at all — it is **discarded**, not
migrated: `db.runs` is dropped, then rebuilt fresh under the new schema. These are diagnostic
snapshots read by hand, not user data, and a half-converted record (old shape, new stamp) is worse
than an absent one — it would fail silently wherever a reader trusts the stamp.

This means a schema-1 ring predating the extraction is never read by `LibKa0s-Perf-1.0`. The
schema-1 capture already committed to AbsorbTracker's `docs/perf-runs/` stays there as history; it
is not re-read or re-migrated by the addon after adopting the library.

## Fields

```jsonc
{
  "schema": 2,
  "addon": "AbsorbTracker",             // NEW in schema 2 — which host produced this record
  "source": "ingame",
  "version": "1.9.0",                    // host addon version
  "interface": 120007,                    // TOC interface; 0 if unresolvable
  "timestamp": 1785110400,                // epoch seconds; 0 if the client has no time()
  "label": "2026-07-30 14:02 dummy-blooddk",

  // OPTIONAL — see the field note below. Who / where / what, captured once at Start().
  // Existence-checked field by field, so a headless harness (or a client missing one of these
  // globals) degrades to "?" rather than erroring.
  "context": {
    "character": "Kaosdk", "realm": "Silvermoon", "level": 80,
    "class": "Death Knight", "spec": "Blood",
    "zone": "Nexus-Point Xenas", "subZone": "The Approach",
    "group": "party (5) / party"
  },

  // Per-bucket totals, keyed by the Note() bracket key. THESE MAY NEST — see `within`. Never sum a
  // parent and its children as if they were disjoint.
  "buckets": {
    "repaintPass": { "calls": 118, "totalMs": 42.6, "maxMs": 1.8 },
    "paintBar":    { "calls": 1869, "totalMs": 98.1, "maxMs": 0.92, "within": "repaintPass" }
  },

  // Frame sampling, one arm per suspend state.
  "fps": {
    "active":    { "seconds": 62.3, "frames": 4821, "avgFps": 77.4, "msPerFrame": 12.92 },
    "suspended": { "seconds": 60.1, "frames": 5903, "avgFps": 98.2, "msPerFrame": 10.18 },
    "deltaMsPerFrame": 2.74
  }
}
```

Object keys are emitted in sorted order (`lib.EncodeJSON`'s `sortedKeys`) so two records diff
cleanly. Empty tables — an empty `buckets`, or a `context` that never resolved — encode as `{}`
either way: Lua has a single table type, so an empty list and an empty map are indistinguishable to
the encoder.

## Field notes

- **`addon`** is `descriptor.name`, exactly as passed to `lib:New`. It is what makes it safe, in
  principle, for one SavedVariables ring to outlive a rename or hold captures across more than one
  consumer's lifetime.
- **`buckets[*].within`** is present only for a bucket the descriptor declared with a `within`
  parent (see the descriptor's `buckets` field in `README.md`). A bucket recorded via `Note()` that the
  descriptor never declared still appears here, just without a `within` key — membership in
  `buckets` (the descriptor field) controls only *presentation order and nesting*, never whether a
  measurement is captured.
- **`context`** is the one **optional** top-level field, and it is absent entirely rather than
  empty when it is missing. It is snapshotted by `Start()`, so a record built before any run — which
  `report` and `dump` will happily do on a fresh instance — carries no `"context"` key at all, and
  the report simply prints no who/where/group lines. Every record from a real capture has it.
- **`fps.deltaMsPerFrame`** is `0` unless *both* arms were sampled — with one arm empty, subtracting
  would report the whole frame time as the host's cost, which is worse than reporting nothing.
- **`interface`** comes from the host's own TOC metadata (`C_AddOns.GetAddOnMetadata`, or the
  pre-10.1 global), looked up by `descriptor.name`. `0` if neither accessor exists.
- **`timestamp`** is `0` if the client has no global `time()` — true of the headless test harness,
  never true in a live client.

## Reading captures off disk

A schema-2 ring persists to whatever global the host passed as `descriptor.sv` — e.g.
`AbsorbTrackerPerfDB` — inside that addon's SavedVariables file:

```
_retail_/WTF/Account/<ACCOUNT>/SavedVariables/<Addon>.lua
```

WoW names the file after the addon, not after the individual SavedVariables globals it declares, so
a host with both a settings DB and a perf ring finds both tables in the same file.

The ring is a top-level global, deliberately outside any AceDB profile tree `Save` might otherwise
have used — see the rationale on `Save` in `LibKa0s/Perf.lua`. It is never copied by "copy profile",
wiped by "reset profile", or swapped out by a profile switch.
