# `LibKa0s-Compat-1.0` — version 1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Compat surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Compat-1.0` |
| Files and minors | `Compat.lua` minor **1** |
| Shipped in | v1.55.0 |
| Status | **Current** |
| Supersedes | — (first version) |
| Superseded by | — |
| Confirm in-game | `LibStub("LibKa0s-Compat-1.0").MODULES` → `{ Compat = 1 }` |

## What this major is

**The version-variant client readers that two or more Ka0s addons wrote the same way, plus the
secret-value seam every guard has to ask before it compares.** Nine stateless functions: six
readers over APIs Blizzard has already moved once (`C_Spell` in 11.0, `C_SpecializationInfo` in
12.0), and three guards over 12.0's own secret tests (`issecretvalue`, `canaccessvalue`). No state,
no frames, no events, no addon framework.

Nine addons carry a `core/Compat.lua`, and AuraMaster and MultiMeters also carry a
`core/Secrets.lua`. Most of those files are honestly addon-specific. The shapes here were written two
to four times each, and the copies had drifted. Two addons read the deprecated `GetSpellInfo`
global's rank as the icon. One compared a possibly-secret spell name with `""`, which raises in
combat. One read a legacy `isEnabled` of `0` as enabled. This major is the one copy, with each of
those resolved in writing below.

**It is deliberately narrow.** The wide extraction (the union of the nine files) was measured and
rejected, and `LibKa0s/Env.lua`'s header still says so; that record stays true. A member is here only
when two or more addons have a production caller for it and every copy agrees on what the right
answer is (`library-stack-§7`). What was considered and left out is under
[What is not here](#what-is-not-here).

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework. **No Core
member is called.** The gate is there so that a host holding a partial payload gets every module
absent rather than a working half.

## Lib-level surface

Read straight off the LibStub table. Every function is stateless.

| # | Name | Since | Returns (arity) | Ladder | All rungs absent | Bad input |
|---|---|---|---|---|---|---|
| 1 | `IsSecret(v)` | 1 | `boolean` (exactly 1) | `issecretvalue(v)`, normalized to a boolean | `false` | none; any value, `nil` included |
| 2 | `CanAccess(v)` | 1 | `boolean` (exactly 1) | `canaccessvalue(v)`, normalized; else `not IsSecret(v)` | `true` | none |
| 3 | `IsSafeKey(v)` | 1 | `boolean` (exactly 1) | `false` for a secret (IsSecret, **not** CanAccess); else `v ~= nil` | `v ~= nil` | none |
| 4 | `GetSpellInfo(id)` | 1 | hit: `name, iconID, castTime, minRange, maxRange, spellID` (exactly 6); miss: `nil` (exactly 1) | `C_Spell.GetSpellInfo(id)` flattened, authoritative; else the global `GetSpellInfo(id)` **remapped** from its real shape `name, rank, icon, castTime, minRange, maxRange, spellID` (rank dropped) | `nil` | not a number or string → `nil`, no rung called |
| 5 | `GetSpellName(id)` | 1 | `string` or `nil` (exactly 1; may be a secret string) | `C_Spell.GetSpellName(id)` → `C_Spell.GetSpellInfo(id).name` → the global `GetSpellInfo(id)`'s first return. **The first rung that answers wins**: a secret (returned untouched) or a plain non-empty string answers; `nil` or plain `""` falls through | `nil` | not a number or string → `nil`, no rung called |
| 6 | `GetSpellTexture(id)` | 1 | file id or `nil` (exactly 1; the client's second return, `originalIconID`, is dropped) | `C_Spell.GetSpellTexture(id)`, authoritative; else the global `GetSpellTexture(id)` | `nil` | not a number or string → `nil`, no rung called |
| 7 | `GetSpellCooldown(id)` | 1 | `startTime, duration, isEnabled, modRate, isActive` (**always** exactly 5) | Modern: `C_Spell.GetSpellCooldown(id)`; a `nil` info is the inert tuple; else `startTime or 0, duration or 0, isEnabled ~= false, modRate or 1, isActive == true`. Legacy: `s, d, e, m = GetSpellCooldown(id)` → `s or 0, d or 0, (e ~= false and e ~= 0), m or 1, active`, where `active` is `d > 0` asked only when `d` is a plain, non-secret number | `0, 0, false, 1, false` | not a number or string → the inert tuple, no rung called |
| 8 | `GetSpecialization()` | 1 | `number` or `nil` (exactly 1) | `C_SpecializationInfo.GetSpecialization()`, authoritative; else the global `GetSpecialization()` | `nil` | — |
| 9 | `GetSpecializationInfo(index)` | 1 | the rung's **own returns, unmodified and variable in count** (client: `specID, name, description, icon, role, primaryStat, ...`); `nil` (exactly 1) on no answer | `C_SpecializationInfo.GetSpecializationInfo(index)`, authoritative; else the global `GetSpecializationInfo(index)` | `nil` | `nil` or `false` index → `nil`, no rung called |
| — | `MAJOR` · `MINOR` | 1 | `"LibKa0s-Compat-1.0"` and the live minor | | | |
| — | `MODULES` | 1 | `{ Compat = <minor> }`, the live minor and the value that picks this document | | | |

### The rules every member obeys

1. **Globals are read bare and at call time**, never through an explicit global-table lookup and
   never captured into an upvalue at load. The headless kit resolves a bare name through its mock
   first, so a suite can remove a rung after load and watch the ladder move. An explicit
   global-table lookup steps around the mock, and a degraded case written against it tests a client
   nobody runs. `tests/test_compat.lua` pins this on the source text.
2. **Namespaced rung first, deprecated global second, the no-answer value last.** "Absent" is the
   presence test `ns and ns.fn`.
3. **Authority.** For every reader but `GetSpellName`, the first rung that **exists** is
   authoritative: a `nil` from it is the answer and the next rung is not consulted. For
   `GetSpellName` the first rung that **answers** wins. Every rung reads the same spell data, so they
   can disagree only about whether the data is there yet, and falling through cannot hide a real
   disagreement the way it would for a boolean like "is this spell known".
4. **A value that may be secret is returned untouched.** Spell names, cooldown timings and modRate
   are never compared, formatted or used in arithmetic here. The operations performed on client
   values are: `type()` (legal on a secret); `x or default` on a timing or modRate (truthiness of a
   secret number is legal; only a secret *boolean* may not be tested); `n ~= ""` only after
   `IsSecret(n)` is false; `d > 0` only after `type(d) == "number"` and `not IsSecret(d)`; and
   `info.isEnabled ~= false` / `info.isActive == true` on the modern cooldown table. `isActive` is
   the plain boolean Blizzard provides for in-combat gating. That `isEnabled` is plain is the shipped
   behavior of both copies this member replaces, **not a recorded in-game measurement**.
5. **Identifier domain.** Spell members accept a `number` or a `string`, because the client's
   `spellIdentifier` accepts an id, a name or a link, and KickCD resolves typed names through
   `GetSpellInfo`. Any other type, `nil` included, answers the member's no-answer value without
   calling any rung. `type()` on a secret is legal, so the guard is secret-safe. A host that wants a
   narrower domain (AuraMaster takes numbers only) keeps a one-line guard in front of the call; a
   domain flag here would be the per-consumer switch `library-stack-§7` forbids.
6. **No `pcall`** around a client call. A client defect raises where it happens instead of reading
   as silence.
7. **Arity is exact** everywhere but `GetSpecializationInfo`, so a caller spreading a result into the
   last argument of a C call (`SetTexture`, `SetCooldown`) never forwards a stray value.
8. **Internal calls go through file locals, never back through the LibStub table.** The table is
   shared by every addon that loaded this copy; one host replacing `IsSecret` on it must not change
   what another host's `GetSpellName` answers.

### Notes on specific members

- **`GetSpellInfo`'s legacy remap is a correction, not a preference.** The deprecated global's second
  return is the rank. Two of the three copies passed it through raw and their fixtures encoded the
  wrong shape; AuraMaster remapped it and pinned that. The branch is reachable only in a harness or on
  a client that still carries the global.
- **`GetSpellName`'s secret handling is new and deliberate.** ConsumableMaster compared every rung's
  answer with `""`; a secret name there raises in combat. This member asks `IsSecret` first and
  returns a secret untouched, and a secret ends the ladder even where its plain spelling would be
  `""`. The middle rung (`C_Spell.GetSpellInfo(id).name`) is ConsumableMaster's; it can only turn a
  `nil` into a name, and it is the rung the kit's `mock_ids` answers.
- **`GetSpellCooldown`'s legacy `isEnabled`.** The legacy global historically answered `1`/`0`.
  WhatGroup read `0` as disabled; KickCD's `e ~= false` read it as enabled. This major takes
  WhatGroup's reading. `nil` reads enabled in every copy and here.
- **`IsSafeKey` asks IsSecret, not CanAccess.** The key restriction is about the value being secret
  at all, not about whether this context may read it, and a value can be secret yet accessible. The
  secret test runs first so no secret ever meets a comparison, even with `nil`; the answer is
  identical on every input to the copies' `v == nil`-first ordering.
- **`GetSpecializationInfo` keeps the passthrough.** Every copy passed the multi-return through
  untouched and the callers read positions one and two; fixing an arity here would invent a contract
  nobody asked for. ConsumableMaster's `nil`-index guard is taken for everyone: a `nil` index answers
  `nil` rather than calling the client with it.

## What a headless harness answers

The consumer kit (`testkit/mock_base.lua`) carries **no** `C_Spell`, no `C_SpecializationInfo`, no
`issecretvalue`/`canaccessvalue`, but **does** carry the legacy globals `GetSpecialization → 1` and
`GetSpecializationInfo → 250, <spec name>`. `testkit/mock_ids.lua`, where a repo opts in, adds
`C_Spell.GetSpellInfo`.

| Member | On a bare kit harness | With `mock_ids` installed |
|---|---|---|
| `IsSecret` / `CanAccess` / `IsSafeKey` | `false` / `true` / `v ~= nil` | same |
| `GetSpellInfo` | `nil` | the six values for a seeded id (modern rung) |
| `GetSpellName` | `nil` | the seeded name, through the `C_Spell.GetSpellInfo` middle rung |
| `GetSpellTexture` | `nil` | `nil` |
| `GetSpellCooldown` | `0, 0, false, 1, false` | same |
| `GetSpecialization` | `1` (legacy rung) | same |
| `GetSpecializationInfo(1)` | `250, <spec name>` (legacy rung) | same |

## Degradation

A host resolves the major with `LibStub("LibKa0s-Compat-1.0", true)` and falls back to a stub when it
is absent. The library cannot publish its own stand-in: a stand-in would live in the payload that is
absent by definition. **The two kinds of member take two different stub rules, and the difference is
the design.**

### The absent table

With every rung removed at once, each member answers exactly this. `tests/test_compat.lua` holds the
same table as a literal (`ABSENT_ANSWERS`) and asserts every member against it, value and arity.

| Call | Answer |
|---|---|
| `IsSecret(300)` | `false` |
| `CanAccess(300)` | `true` |
| `IsSafeKey(300)` | `true` |
| `IsSafeKey(nil)` | `false` |
| `GetSpellInfo(774)` | `nil` |
| `GetSpellName(774)` | `nil` |
| `GetSpellTexture(774)` | `nil` |
| `GetSpellCooldown(774)` | `0, 0, false, 1, false` |
| `GetSpecialization()` | `nil` |
| `GetSpecializationInfo(1)` | `nil` |

### Readers: the stub answers the absent value

Members 4 to 9. The stub returns the absent table's answer: `nil`, or `0, 0, false, 1, false`. A
degraded install loses spell names, icons and spec, and never raises; every caller already handles
these values, because they are the documented contract. A stub that re-implemented the top rung would
re-create the duplication this major removes, so it is **not** the recommended shape.

### Guards: the stub re-implements the body

Members 1 to 3. **The stub MUST re-implement the one-rung body**, three to four lines each. For a
guard, "the library is absent" is not "the client has no secrets system". A stub answering
`IsSecret → false` on a 12.x client sends a secret into a comparison and raises in combat, on exactly
the degraded path the stub exists to survive. This is a deliberate, documented duplication, and the
host's copy carries a comment naming this section.

### How a host wires it

The host keeps `core/Compat.lua` as its single seam and keeps `NS.Compat.X` as the call surface, so
every existing call site and every test that replaces a member at runtime keeps working:

```lua
local CompatLib = LibStub and LibStub("LibKa0s-Compat-1.0", true)

-- Reader: the library, or its documented no-rung answer.
Compat.GetSpellName = CompatLib and CompatLib.GetSpellName or function() return nil end

-- Guard: the library, or the same one-rung body. Deliberate duplication: see
-- LibKa0s docs/api/Compat/version-1-docs.md, "Degradation".
Compat.IsSecret = CompatLib and CompatLib.IsSecret or function(v)
    return issecretvalue ~= nil and issecretvalue(v) and true or false
end
```

No separate "library missing" message: a Compat-only absence can arise only from a partial copy,
which `library-stack-§7` forbids, and a whole-payload absence is already announced by the host's
`core/CoreSetup.lua`.

**The gate.** Each adopter adds a degraded-load case (library files skipped, never the member
stubbed, `testing-§8`) asserting every wired member's answer equals the absent table (readers) or the
library's own answer under the same `issecretvalue` fixture (guards). Where a repo wires members onto
one table, `Kit.assertSurfaceParity(NS.Compat, "LibKa0s-Compat-1.0", ignore)`, with `ignore` listing
the members it deliberately does not wire. A member added to the major later then fails parity until
the host decides, which is the intended pressure.

That one call runs as written only when two things hold, and at v1.55.0 one or both fail for six of
the seven adopters:

- **The runner's surface source has to answer this name.** The by-name form looks the live half up
  through the source `Kit.setSurfaceSource` registered. `Kit.expose` wires the mock's `LibStub` as
  that source **only when the runner registered none**. A runner that registers a **table map**
  (because its Options, DebugLog or Slash stubs mirror instances) MUST add a row for this major to
  that map. Without the row the call raises `the surface source answers nil ... the live surface
  never loaded`:

  ```lua
  Kit.setSurfaceSource{
    -- ...the runner's existing rows...
    ["LibKa0s-Compat-1.0"] = mocks.LibStub("LibKa0s-Compat-1.0", true),
  }
  ```

  `mocks` is whatever the runner calls the mock its live load used. AuraMaster, KickCD, LootHistory,
  MultiMeters, PartyFrameEnhanced and WhatGroup register a table map and need the row.
  ConsumableMaster registers none, so `Kit.expose` wires its mock's `LibStub` and it needs nothing.
- **The members have to sit on the table the call names.** AuraMaster and MultiMeters wire the guard
  trio onto `NS.Secrets`, not `NS.Compat`. Their gate is two calls, each ignoring what the other
  table carries:

  ```lua
  local READERS = { "GetSpellInfo", "GetSpellName", "GetSpellTexture", "GetSpellCooldown",
                    "GetSpecialization", "GetSpecializationInfo" }
  -- NS.Compat: ignore the trio (it lives on NS.Secrets) and every reader this host does not wire.
  local notWired = { "IsSecret", "CanAccess", "IsSafeKey" --[[, the unwired readers ]] }
  Kit.assertSurfaceParity(NS.Compat, "LibKa0s-Compat-1.0", notWired)
  -- NS.Secrets: ignore every reader.
  Kit.assertSurfaceParity(NS.Secrets, "LibKa0s-Compat-1.0", READERS)
  ```

  A member added to the major later is ignored by neither call, so it fails at least one of them
  until the host decides where it goes.

## Relation to `LibKa0s-Core-1.0`

Core ships `IsConcatSafe(v)` and `SafeToString(v)`. They answer a **different question**: whether
`table.concat` will accept `v`, probed version-agnostically. On a plain boolean the two verdicts
point opposite ways: `IsConcatSafe(true)` is `false` (concat rejects a boolean), yet `true` is not
secret, so `IsSecret(true)` is `false` too. On a secret, `IsConcatSafe` is `false` and `IsSecret` is
`true`. And `IsConcatSafe` never consults `issecretvalue`. Core
chooses the probe over `issecretvalue` for rendering on purpose, and that choice stands: rendering
keeps going through `SafeToString`, and guards that decide comparability go through this major.
`tests/test_compat.lua` pins the disagreement so nobody later "deduplicates" the two.

The secret guards live in **this** major, not in Core. `issecretvalue` and `canaccessvalue` are 12.0
globals, which makes them version-variant and `compat`'s subject, and a promotion into Core would
raise the Core-floor question for every sibling major.

## What is not here

Recorded because `library-stack-§7` asks for the rejection record, and because the next person to
look at nine `core/Compat.lua` files will ask why these did not move.

### Consumers disagree about correctness

| Shape | Disagreement |
|---|---|
| Spell known / available (WhatGroup `IsSpellKnown`, KickCD `IsSpellAvailable`) | WhatGroup treats `C_SpellBook.IsSpellKnown` as final and forbids an either-says-yes ladder; KickCD's is exactly that ladder. |
| Cast info (KickCD `GetCastingInfo` / `GetChannelInfo`, PartyFrameEnhanced `CastInfo`) | KickCD overrides `notInterruptible` to true for a unit the player cannot attack; PartyFrameEnhanced returns the raw flag. Different answers to "is this interruptible". |
| A secret boolean handed to a C-side setter (PartyFrameEnhanced `BoolValue` / `AlphaFromBool`, KickCD `State.ApplyInterruptibleAlpha`) | PartyFrameEnhanced gates on `IsSecret` first; KickCD calls the setter ungated on purpose. |
| Cooldown remaining with a GCD floor (WhatGroup `GetSpellCooldownRemaining`) | WhatGroup policy (a 1.5 s floor, `GetTime()` arithmetic on plain values). It stays in WhatGroup, built on `GetSpellCooldown`. |
| Item resolver (LootHistory `GetItemInfo`, BankLedger `GetItemDetails`) | Already recorded by `LibKa0s-Item-1.0`: one host guesses, the other refuses. |

### Two consumers, but no content

| Shape | Why it stays inline |
|---|---|
| `Enum.StatusBarInterpolation` read (AuraMaster, MultiMeters, PartyFrameEnhanced inline) | One enum-member presence read: the optional-object-guard shape `library-stack-§7` names as the worked example of what not to promote. A library call would add a stub obligation to each host and remove no logic. |
| `C_StringUtil.CreateNumericRuleFormatter` (AuraMaster, MultiMeters) | A presence guard around one constructor. The rest has one consumer, and the two copies differ on whether a raising constructor propagates or reads as `nil`. |

### One consumer

Everything else in the nine files: AuraMaster's aura-container readers and duration formatters,
KickCD's charges and usability readers, MultiMeters' damage-meter and death-recap blocks,
ConsumableMaster's class-ID spec readers, LootHistory's bind-state scanner and mail readers,
WhatGroup's spell link and activity readers, BankLedger's and PanelMaster's whole files, and
PartyFrameEnhanced's unit readers. Also the non-trio members of the two `core/Secrets.lua` files
(`IsReadableNumber`, `NumberOr`, `CanCompare`, `CanCompare2`, the table members, `SafeIterate`).

### The library's own inline spec read

`LibKa0s/Perf.lua` reads the specialization inline for a perf record's context. It stays: making Perf
call this major would be a new floor for Perf, which `library-stack-§7` treats as a breaking change
to the vendoring, and this release is additive-only.

## Adopting it

Adoption happens with the re-vendor that brings this major, one commit per member group after the
re-vendor commit. Call sites keep calling `NS.Compat.X` (or `NS.Secrets.X`); only the definitions
change, as in [How a host wires it](#how-a-host-wires-it). Each adopter adds the degraded-load case
described there. The six adopters whose runner registers a table-map surface source (AuraMaster,
KickCD, LootHistory, MultiMeters, PartyFrameEnhanced, WhatGroup) add this major's row to
`tests/run.lua`'s `Kit.setSurfaceSource{...}` in the same commit. AuraMaster and MultiMeters gate
`NS.Compat` and `NS.Secrets` in two calls ([the gate](#how-a-host-wires-it)).

## Vendoring

Whole-folder, exactly as every other major in this payload:

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s   # content — MUST be empty
diff -r LibKa0s <Addon>/libs/LibKa0s                       # bytes  — SHOULD be empty
```

`Compat.lua` is a new entry in `LibKa0s.xml`, immediately after `Env.lua`. A consumer whose test
harness derives its load list from that XML picks it up with no edit; a consumer that re-types the
list adds one row after `libs/LibKa0s/Env.lua`.
