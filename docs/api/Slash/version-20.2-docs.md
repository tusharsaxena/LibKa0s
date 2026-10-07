# `LibKa0s-Slash-1.0` — version 20.2

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Slash surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Slash-1.0` |
| Files and minors | `Slash.lua` **20** · `SlashParse.lua` **2** |
| Version key | `<Slash>.<SlashParse>`, in load order — the same two numbers `lib.MODULES` reports |
| Shipped in | v1.71.0 |
| Status | **Current** |
| Supersedes | [version 19.1](./version-19.1-docs.md) — whose number rows took `nan` and the infinities |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`) |
| Confirm in-game | `LibStub("LibKa0s-Slash-1.0").MODULES` → `{ Slash = 20, SlashParse = 2 }` |

`Since` in the tables below is the Slash minor in which the member first appeared; `lib.ParseBool`
and `lib.ParseValue` live in `SlashParse.lua` from 19, and their `Since` is still the Slash minor. Minors 1–3 were
never tagged, so a `Since` of 1, 2 or 3 means "present for as long as any consumer could have had
this major".

## What this major is

The slash dispatcher, the help renderer, the schema CLI and the value parser — everything between
"the user typed `/at something`" and "a setting changed", minus the settings themselves.

Four-plus copies of it exist across the collection, in two different shapes, and the divergence is
not cosmetic. One shape parses values by bare coercion, so `set barWidth 99999` stores 99999 and a
`get` on a color prints a table address. This library takes the type-aware shape — clamping, enum
validation, color tuples — on the view that a CLI silently accepting a value it cannot honor is
worse than one that refuses.

Like DebugLog, it depends on LibStub and `LibKa0s-Core-1.0` and on no addon framework, and it
returns before `NewLibrary` if Core is missing or below the minor it needs.

Two files, one major, from version 19.1 — `Slash.lua` (the strings, the formatters, the command
primitives, profiles and the instance) and `SlashParse.lua` (`lib.ParseBool`, `lib.ParseValue` and
the row type parsers behind them). One major for the same reason Perf is one: a shell and a parser
from different vendored copies is not a state LibStub can detect. **This is why the version key above
has two components.**

## What changed at this version

**A number row refuses `nan` and the infinities** (2026-10-07 review, `LK-R-06`). Lua's `tonumber`
reads `nan`, `inf` and `-inf` as numbers, and a literal such as `1e400` overflows to `inf`. Through
`SlashParse.lua` 1, `lib.ParseValue` took any of them: a bounded row's clamp happened to absorb a
NaN, only because `n` is the second argument to `math.max` / `math.min` (Lua 5.1's
`math.max(0/0, -100)` answers NaN, `math.max(-100, 0/0)` answers -100), and an **unbounded** row
had no clamp at all, so `/<slash> set <path> nan` stored a NaN through the shared write seam.

- **`SlashParse.lua` 2** refuses a non-finite number with the existing `ERR_NUMBER` reason
  (`expected a number`, or the host's `L` through the resolver), before the enum and the clamp, on
  every number row. A finite number parses, clamps and matches a numeric dropdown exactly as at
  19.1, `1e300` included.
- The argument order of the clamp is kept, and a comment now records why.
- `Schema.Set` stays type-agnostic: the refusal belongs to the CLI's parser, which is the seam that
  reads text.
- **`Slash.lua` 20 changes one comment and nothing that runs.** The profile-store comment cited the
  standard by file and line (`slash-commands.md:34`); it now cites `slash-commands-§1` (LibKa0s#43).
  The payload changed, so the minor moves; `SlashParse.lua`'s pairing guard re-runs on the new shell
  minor by design.
- No member, string, descriptor field or `NEEDS_*` floor moves; the member manifest is unchanged
  apart from its version key.

The cases are in `tests/test_slash_parse.lua`.

### Previously, at version 19.1

**The host's `L` reaches every parse refusal and the empty-string `(none)`** (issue #40). Through
version 18 the file-level parsers behind `set` and the `string` formatter behind every echo read
`lib.STRINGS` directly, while the instance resolved its own lines through `Sl:Text`. So a host's `L`
overrode `INVALID` but never the reason printed under it: `ERR_BOOL`, `ERR_NUMBER`, `ERR_STRING`,
`ERR_ALLOWED`, `ERR_COLOR` and `ERR_TYPE` were unreachable, and so was `NONE`. ConsumableMaster
carried three of them in its table, marked dead for exactly that reason.

- **`lib.ParseValue(row, text, textOf)` and `lib.FormatValue(row, v, textOf)`** take an optional
  third argument, a key → string resolver. Absent, each reads `lib.STRINGS` as before, so a
  two-argument call answers byte for byte what version 18 answered.
- **The instance passes `Sl:Text`**, so its default parse and every echo read the host's `L` first,
  with the same `rawget` rule (a key-echoing locale still falls through to the library's string).
- **A host's own `parse` is handed the resolver as a third argument**, to pass on to
  `lib.ParseValue`. A `parse` that takes two arguments ignores it. A host's `format` replaces
  `lib.FormatValue` outright and is called exactly as before.
- The disabled refusal line still does not read `L`. No member, string or `NEEDS_*` floor moves;
  the member manifest is unchanged apart from its version key.
- **The parser moved, unchanged, to a file of its own**, `LibKa0s/SlashParse.lua` minor 1, loaded
  by `LibKa0s.xml` after `Slash.lua`: `lib.ParseBool`, `lib.ParseValue` and the row type parsers
  (`parseBool`, `enumList`, `allowedText`, `parseNumber`, `parseString`, `parseColor`). It attaches
  to the live shell and records `lib.__parseMinor` and `lib.__parseShellMinor`, so a parser from one
  vendored copy never pairs with a shell from another without saying so. `Slash.lua` is 877 lines,
  out of `layout-§1`'s 1000–1500 band. The version key gains a component, 19 → 19.1.
- **A payload without `SlashParse.lua`** loads whole, with no `lib.ParseBool` and no
  `lib.ParseValue`. An instance whose host passes no `parse` answers `set` with its `INVALID` line
  and, under it, one line naming the missing file; nothing is written. A consumer re-vendors the
  whole folder, so this arises only from a hand-trimmed copy.

The cases are in `tests/test_slash_parse.lua`, including the two-argument default, the
key-echoing locale, the file's pairing and the payload without it.

### Previously, at version 18

**The dispatcher's own refusals reach the host's debug log.** Every refusal Slash decides itself
reached chat and nothing else, so a support read of the log could not see that a verb was refused, or
why; AbsorbTracker matched the disabled gate's chat line to find them. Version 18 takes the host's
gated log seam on the descriptor, exactly as `LibKa0s-Launcher-1.0` does, and writes one line per
refusal (gap G1 of the 2026-09-30 LibKa0s debug-gaps run).

- **Descriptor field `debug`** (optional): `debug(tag, message)`, the host's gated sink. Absent, or
  not a function, the module writes nothing, exactly as at version 17.
- **One `Cmd` line per refusal, after the chat line**, shaped `refused <verb>[ <arg>]: <guard>`:

  | Refusal | Line |
  |---|---|
  | The disabled gate refusing a shipped feature verb | `refused <verb>: disabled` |
  | An unknown verb (enabled or disabled) | `refused <verb>: unknown verb` |
  | `get` / `set` / `reset` with no path | `refused get: usage` (and `set`, `reset`) |
  | A path with no row | `refused get <path>: not found` (and `set`, `reset`) |
  | A value the parser refuses | `refused set <path>: parse (<reason>)`, or `parse` alone with no reason |
  | A write the host's `set` refuses | `refused set <path>: write refused (<reason>)`, or `write refused` alone |
  | `applyDefault` answering `false` | `refused reset <path>: no default` |
  | No profile store | `refused profile: unavailable` |
  | The current profile named | `refused profile <name>: already current` |
  | A switch in combat | `refused profile <name>: in combat` |
  | A name the store does not list | `refused profile <name>: unknown profile` |

- **Nothing a command answers writes a line**, and the chat is byte for byte version 17's with or
  without a sink. No member, no string and no `NEEDS_*` floor moves; the member manifest is
  unchanged apart from its version key.

The cases are in `tests/test_slash_debug.lua`, including the silent default.

### Previously, at version 17

**The `profile` verb's behavior ships here, once, and each host registers its own row for it.**
Two consumers had hand-written profile verbs and they disagreed: AbsorbTracker's `use <name>` called
`SetProfile` with no existence check, so a typo silently created a profile, while
PartyFrameEnhanced's refused an unknown name. The other nine had none. Version 17 gives every host
the same `profile <name>` and the same list, through the descriptor, without the library requiring
AceDB (`slash-commands.md:34`).

- **Descriptor field `profiles`** (optional): a function answering the host's profile store, asked
  at call time. The store is duck-typed on AceDB-3.0's shape: `GetProfiles(tbl) -> tbl, n`,
  `GetCurrentProfile() -> name`, `SetProfile(name)`. A store missing any of the three is treated
  as no store.
- **`Sl:CliProfile(rest)`**: the verb. Bare lists the profiles with the current one marked;
  `profile <name>` switches to an existing profile. See [The profile verb](#the-profile-verb).
- **`Sl:ProfileSwitch(name)`**: the switch alone, for an already-parsed name, answering `true` when
  it switched. A host's own `profile use <name>` sub-verb routes here.
- **`lib.ProfileNames(store)`**: → the store's names sorted case-insensitively, and the current one.
- **Nine `lib.STRINGS` keys**, `PROFILE_UNAVAILABLE`, `PROFILE_LIST_HEADER`,
  `PROFILE_CURRENT_MARK`, `PROFILE_HINT`, `PROFILE_ALREADY`, `PROFILE_COMBAT`, `PROFILE_SWITCHED`,
  `PROFILE_UNKNOWN` and `PROFILE_DID_YOU_MEAN`, all reachable through `L`.
- **`profile` is not added to `lib.LIVE_VERBS`, and is not reserved.** It is a host verb
  (`slash-commands.md:7`). A host that wants it live while disabled widens its own `liveVerbs`, which
  the descriptor has allowed since 12, so every consumer's hand-copied thirteen-verb pin stays green.
- **No `NEEDS_*` floor moves.** The member manifest gains `ProfileNames`; the two instance members
  are not in it, because the manifest lists the lib-level surface.

The cases are in `tests/test_slash_profile.lua`, a suite of its own on the seam it tests.

### Previously, at version 16

**`lib.LIVE_VERBS` gains `diagnostics`, so the live set is the standard's thirteen reserved verbs.**
The Ka0s WoW Addon Standard v2.68.0 adds the diagnostics dump (`debug-logging-§14`) and reserves
`diagnostics` as a verb every addon registers (`slash-commands-§2`), live while the addon is
disabled (`slash-commands-§7`). A disabled addon is exactly the one a player is most likely to be
reporting, so the report has to answer in that state.

- **`lib.LIVE_VERBS`** reads `help, config, version, enable, disable, debug, perf, diagnostics, get,
  set, list, reset, resetall`, in that order. `diagnostics` sits after `perf`, beside the other two
  diagnostic verbs.
- **No member, no descriptor field and no `NEEDS_*` floor moves.** The member manifest differs from
  version 15's in the minor alone.
- **A host that passes no `liveVerbs`** inherits the new verb on re-vendor. **A host that builds its
  own `liveVerbs` from `lib.LIVE_VERBS`** inherits it too. **A host that passes a literal array**
  does not, and adds `"diagnostics"` to it when it registers the verb.
- The `debug diagnostics` form needs nothing here: it is a word of `debug`, which was already live.

The pin is in `tests/test_slash.lua` (*liveVerbs defaults to the standard's thirteen reserved
verbs*). Nothing else in the dispatcher changes; the gate still sits after the COMMANDS lookup, so
a host that has not registered `diagnostics` yet answers it with `unknown command` in either state,
as version 14 made true of every reserved verb.

### Previously, at version 15

**`CliSet` and `CliReset` hear the write seam's refusal.** Through version 14 both discarded what the
descriptor's `set` and `applyDefault` answered. `LibKa0s-Schema-1.0`'s `S.Set` answers
`false, err[, why]` with nothing stored when a row's `validate` rejects a value, so a player's
refused `set` printed `path = <the old value>` — an echo that reads as success for a write that did
not land, and no reason anywhere (review finding `LibKa0s-R-03`). One host, AuraMaster, printed the
refusal by hand in its own `set` wrapper; BankLedger passed `Schema.Set` straight through and printed
nothing.

- **`set` may answer `false, reason[, why]`.** When its first return is exactly `false`, `CliSet`
  prints `INVALID` for the path, then `reason` and `why` each on a line indented two spaces, and
  returns without the echo. A `reason` that is itself the `INVALID` line for the path — which is
  what `S.Set` answers for a `validate` refusal — is not printed a second time. `nil` and `true`
  both still mean the write landed, and the echo re-reads the stored value as before.
- **`applyDefault` answering exactly `false`** — which `S.ApplyDefault` does for a row whose
  `default` is nil — makes `CliReset` print the new `lib.STRINGS.NO_DEFAULT`
  (`"%s has no default to restore"`) instead of echoing the unchanged value.
- **`lib.STRINGS.NO_DEFAULT`** is new, and reachable through `L` like every other key.

No member is added or removed, and the descriptor gains no field: `set` and `applyDefault` keep their
signatures and gain a meaning for a return value they previously had none for. The member manifest
differs from version 14's in the minor alone. `CliResetAll` is unchanged — its walk still counts
every row `applyDefault` returned for, whatever it answered.

The cases are in `tests/test_slash_refusal.lua`, a suite of its own because `tests/test_slash.lua`
sits in the 1000–1500 band.

**Version 15's document also prescribes the degradation stub**: the shape a host's library-absent
Slash stub takes, and the one library string it may carry. See
[The degradation stub](#the-degradation-stub). That is documentation of the host's side of the
contract; `Slash.lua` did not change for it, and this document carries it forward unchanged.

## The disabled surface at this version

### The live set is the standard's thirteen reserved verbs

```lua
lib.LIVE_VERBS = {
  "help", "config", "version", "enable", "disable", "debug",
  "perf", "diagnostics", "get", "set", "list", "reset", "resetall",
}
```

They all answer while disabled, and the bare `/<slash>` opens the panel exactly as it does when the
addon is running (`slash-commands-§2`, `§7`). The reasoning is that a player must be able to **read
and repair settings** and to **reach the panel** while the addon is off — which is precisely when
they are most likely to need to — and **`enable` above all**, or the switch only goes one way.
`debug`, `perf` and `diagnostics` are diagnostics rather than features: the usual reason to reach
for any of them is that the addon is misbehaving.

The set is the set of verbs the standard **reserves**. It is not a claim that any given host ships
all thirteen, and from version 14 the dispatcher does not behave as though it were.

### So the gate refuses exactly the host's own FEATURE verbs

A verb that **drives the addon's features** — anything that draws, shows, hides, tracks, records,
tests, clears or exports the thing the addon exists to do, `lock` and `unlock` among them — answers
on **one** tagged line naming `/<slash> enable`, and does nothing else. No partial work, no side
effect, no second line, and never the help index. That is `slash-commands-§2`'s **SHOULD**, it
survived the standard's v2.57.0 reversal unchanged, and it is the only refusal in the disabled state.

It is a SHOULD rather than a MUST, deliberately: nothing breaks when a disabled addon's one feature
verb quietly does nothing, and a host that would rather let its feature verbs act declares them in
`liveVerbs`. That is a conformant choice and owes no deviation row — what a host **MUST NOT** do is
refuse anything on the live set above.

### What a disabled addon answers

| Input while disabled | What it answers | Since |
|---|---|---|
| `/<slash>` (bare) | **opens the panel**, via the host's `config` verb | 13 |
| `config` | **opens the panel** | 13 |
| `version` | **prints the version** | 13 |
| `get` / `set` / `list` / `reset` / `resetall` | **reads and repairs settings** | 13 |
| `debug` / `perf`, when the host SHIPS them | **runs**, as the diagnostics they are | 13 |
| `diagnostics`, when the host SHIPS it | **writes the report**, as the standard requires | **16** |
| `profile`, when the host SHIPS it | dispatched **only if the host lists it in `liveVerbs`**; otherwise the refusal line, as for any host verb | **17** |
| `enable` / `disable` | dispatched | 12 |
| `help` | the full index, refusal line under the header | 12 |
| a host FEATURE verb (`lock`, `show`, `export`, …) | the refusal line | 12 |
| a typo (no `commands` entry) | `unknown command '<verb>'` + the index | 13 |
| **a reserved verb the host never registered** (`perf` on an exempt addon) | **`unknown command '<verb>'` + the index** | **14** |

**One row was new at version 17: `profile`**, and it states what was already true of any host verb:
`profile` is not in `lib.LIVE_VERBS`, so a host that wants it answered while disabled widens its own
`liveVerbs`. At version 16 the `diagnostics` row was new; a disabled host that shipped `diagnostics`
and passed no `liveVerbs` had answered it with the refusal line at 15. The last row moved at version 14, where version 13 read *the
refusal line*.

Two rows are worth their own sentence.

- **`help` still prints the refusal line immediately after its header, unindented.** It is not a
  refusal *of* `help` — the index prints in full, because the player has to be able to SEE `enable`
  in the list. It is a statement about the whole index: some of the rows below it are the host's own
  feature verbs, and those are the one thing still refused. Below the rows it would read as a
  footnote to the last command.
- **A verb with no `commands` entry gets `unknown command '<verb>'` and the index; a FEATURE verb
  gets the one line.** The gate sits AFTER the COMMANDS lookup, and the order is the whole of it. A
  verb the addon ships and is standing down from is refused, because the addon understood perfectly
  well and is off. A word it does not ship is a different case, whether it is a misspelling or a
  reserved verb this host never wired: nothing was refused, and `slash-commands-§3`'s unknown-verb
  MUST is unqualified — the disabled state does not carve it out. Gating before the lookup conflated
  the two and answered a misspelling with "the addon is disabled", which is a true sentence and the
  wrong answer. Version 13 fixed that for the misspelling and kept one exception for a reserved verb
  the host never registered; **version 14 removed the exception**, because the exception was the
  same mistake in a narrower window.

### None of this weakens the stand-down

`slash-commands-§7`'s *What MUST stand down* is untouched, and it is the substance. A disabled addon
registers nothing, runs no timer, draws nothing and writes nothing from a game event. The dispatcher
and the settings registration are **setup, not features** — they come up on load in either state — so
keeping them live costs nothing the stand-down was trying to reclaim. The addon is inert; its command
surface is not the addon.

### The wording still lives in exactly one place

`lib.DISABLED_LINE_FORMAT` is the format string and `cli:DisabledLine()` builds the line, unchanged
from version 12. It is one sentence, so re-spelling it per addon costs nothing — which is exactly
why eleven addons would each end up with their own, one saying "disabled", one "turned off", one
adding a second line about the settings panel, and a player who uses four of them reading four
different answers to the same question. **The launcher's left-click handler calls this same member**;
it MUST NOT be re-spelled host-side.

The format is exported beside the builder so a conformance suite matches the SHAPE rather than
hard-coding the words. `brandName` is the plain-text `Ka0s <Name>` a host already gives its LDB
object as `label`; `launcher-§1` forbids escape sequences in that field, which is what makes it safe
to drop into a colored line. A gated host with no `brandName` is still refused at `New` rather than
rendering `nil is disabled` at the one moment a confused player is reading the line. The `L`
override still does not reach this wording: the line is the collection's, not the addon's.

### What the host does

- **A host already on version 15: re-vendor.** No member and no descriptor field moves. A host that
  passes a literal `liveVerbs` array adds `"diagnostics"` to it when it registers the verb; a host
  that passes none, or builds its array from `lib.LIVE_VERBS`, has nothing to change. A suite that
  pins the live set by value re-pins it with `diagnostics` after `perf`.
- **A host on version 13:** as above, and look at its `tests/test_disabled.lua`: a host that
  asserted the refusal line for a reserved verb it does not ship (the exempt addons asserting it for
  `perf`) inverts that one expectation to the unknown-command line, which is what version 14
  changed.
- **A host not yet gated:** wire `isEnabled` and `brandName` onto the descriptor and nothing else.
  `isEnabled` is asked at dispatch time, never cached, so the command after an `enable` works.
- **Call `cli:DisabledLine()` from the launcher's left-click**, rather than writing the line again.
- **A host that passes no `isEnabled` is unaffected** and can adopt later.

### Previously, at version 13

**The disabled slash surface was restored, and `lib.LIVE_VERBS` was the only thing that moved.**
It went from `{ "enable", "help", "disable" }` back to the standard's twelve reserved verbs, and
the bare `/<slash>` opened the settings panel while disabled instead of being refused. The Ka0s WoW
Addon Standard narrowed that surface at **v2.56.0**, which is what version 12 implements, and
**reversed it at v2.57.0** the same day: a rule under which `/<slash>` answers a refusal instead of
opening the one surface a player switches the addon back on from had mistaken which half of the pair
it protects.

Version 13 also moved the gate to sit **after** the COMMANDS lookup, so a typo stopped being
answered with "the addon is disabled" — with one exception, for a reserved verb the host never
registered, which version 14 removed. Version 13's document says input by input what moved at 13.

### Previously, at version 12

**The disabled gate arrived: three descriptor fields, two exported constants and one instance
member, all additive.** `isEnabled`, `brandName` and `liveVerbs` on the descriptor;
`lib.DISABLED_LINE_FORMAT` and `lib.LIVE_VERBS` at lib level; `cli:DisabledLine()` on the instance.
A host that passed no `isEnabled` got version 11's dispatcher byte for byte, and that is still true
here — there was never a half-adopted state to reason about.

Where version 12 differs from version 13 is `lib.LIVE_VERBS` alone. At version 12 it read
`{ "enable", "help", "disable" }`, and **every other input** — `config`, `version`, the whole schema
CLI, `debug`, `perf`, the bare `/<slash>` and an unknown verb — printed the refusal line and did
nothing else. That was the standard's v2.56.0 narrowing, and v2.57.0 reversed it. Version 13's
document says input by input what moved there; the moves since, at versions 14 and 16, are above.

A host that vendored version 12 is not broken: it refuses more than it needs to, and a player has to
reach the settings panel through Blizzard's AddOns tree or the launcher's right-click instead of
typing `/<slash>`. The fix is a re-vendor.

### Previously, at version 11

**One behavior moved: an empty line ran the host's `config` verb instead of printing the help
index.** No member was added, removed, renamed or resignatured, and no descriptor field was added.
The member manifest differed from version 10's in the minor alone.

The Ka0s WoW Addon Standard v2.50.0 (`slash-commands-§4`) made bare `/<slash>` open the settings
panel on its landing page, and `/<slash> help` the command list. `OnSlash("")` (and whitespace-only
input) finds the host's `config` entry in `commands` and calls its handler with `""`. A host with no
`config` entry gets the help index, exactly as through version 10.

### Previously, at version 10


**One behavior moves: a `string` row's value is the whole remainder, trimmed at both ends, not its
first token.** No member is added, removed, renamed or resignatured, and no descriptor field is
added. The member manifest differs from version 9's in the minor alone.

Through version 9, `lib.ParseValue` split `text` on whitespace for every row type, and a `string`
row took the first token. So `/am set container.name My Raid Buffs` stored `"My"`. An enum whose
entries contain a space could not be named at all: an LSM font such as `"Friz Quadrata TT"`, a
statusbar such as `"Blizzard Raid Bar"`, or the Options composers' own `"OUTLINE, MONOCHROME"` font
flag. Nothing was raised. The value was stored, and only the echo showed the truncation. An
AuraMaster test agent found it; PrettyChat had already worked around it with a descriptor `parse`.

A `string` row now reads all of `text`, trimmed at both ends. Internal spacing is kept verbatim,
because it is the user's data. When the row declares `values`, the **full** string is matched
against them. Every other type reads whitespace-separated tokens exactly as before.

| `text` | Row | Version 9 | Version 10 |
|---|---|---|---|
| `"My Raid Buffs"` | `string`, no `values` | `"My"` | `"My Raid Buffs"` |
| `"   My Raid Buffs  "` | `string`, no `values` | `"My"` | `"My Raid Buffs"` |
| `"a  b"` | `string`, no `values` | `"a"` | `"a  b"` |
| `"Friz Quadrata TT"` | `string`, `values` holding it | refused: `"Friz"` is not an entry | `"Friz Quadrata TT"` |
| `"short extra"` | `string`, `values = { short = true }` | `"short"` | refused, `allowed values: short` |
| `""`, `"   "` | `string` | `nil`, `expected a value` | unchanged |
| `"on and more"` | `bool` | `true` | unchanged |
| `"250 px"` | `number` | `250` | unchanged |
| `"0.1 0.2 0.3 0.4 extra"` | `color` | the four channels | unchanged |

**One input is refused now that was accepted before**: a constrained string followed by more words.
Version 9 dropped the extra words and stored the first; version 10 refuses the whole string rather
than guess which part was meant. That is the same rule the parser has always applied to a misspelt
entry.

`CliSet` is the only verb in this major that feeds a parser. It already handed the parser everything
after the path, so nothing changed there: the change is in how `lib.ParseValue` reads what it is
handed. A path with no value still reaches the parser as `""`, and still prints
`Invalid value for <path>` and `  expected a value`, writing nothing.

#### What the host did

- **No descriptor `parse`:** nothing. A free-text row accepts several words and an enum entry with a
  space is settable, from the re-vendor on.
- **A `parse` adapter that delegates to `lib.ParseValue`:** nothing, unless it tokenizes or
  truncates the text itself before delegating. It gets the new reading for its string rows.
- **A `parse` adapter that exists to keep a multi-word string:** that part is now redundant, and the
  host can delete it on its own schedule. It is not wrong to keep it; note that the library trims
  both ends and an adapter that does not will keep a trailing space.

### Previously, at version 9

**Comments only. The surface does not move.** Every member, descriptor field, value and behavior
described below is exactly what version 8 shipped. A host written against version 8 is correct here
unmodified, and there is nothing to migrate.

Two docstrings in `Slash.lua`, the descriptor's `bulkEnd` entry and `runBulk`'s, still called
`count` "the rows actually written". The descriptor entry also told the host to emit
`[Set] reset all: N rows` without saying where N comes from. Both now say what this document has
said since its correction after the v1.32.0 tag (6233e3e, bf8ed91). `count` is the number of rows
the walk called `applyDefault` for and that returned, including a row already at its default, so it
is **not** `debug-logging-§10`'s N. The host tallies N itself, counting only writes that change a
stored value. `Options.lua` carried the same phrasing and is corrected in the same release, at
Options 17.15.4.3.

The bump exists because the file's bytes changed, and LibStub decides which vendored copy wins by
comparing minors. A comment-only change still bumps: see [`docs/releasing.md`](../../releasing.md)
step 2, and the v1.8.0 entry in `CHANGELOG.md`.

### Previously, at version 8

**`CliResetAll` gains an optional bulk bracket — the same one the Options major gains at
16.15.4.3, with the same field names, signatures, call order and error semantics, so a host passes
one pair to both.** No member is added, removed, renamed or resignatured; the member manifest differs
from version 7's in its version key alone. What is added is two optional descriptor fields,
`bulkBegin` and `bulkEnd`. A host that supplies neither runs exactly version 7's walk, with no
`pcall` on the path.

**Why.** On 2026-09-12 the owner ruled, and standard v2.44.0 codified in `debug-logging-§10`, that a
**bulk copy or reset through the settings helper is ONE `debug-logging-§8` flow line** naming the
act, its scope and the row count, and **MUST NOT** emit a per-row `[Set]` line. Validation and each
row's `onChange` still run per row. `CliResetAll` walks every row through the descriptor's
`applyDefault`, and three hosts reach their global reset through it rather than through the Options
major: BankLedger's and LootHistory's Defaults button and `/<slash> resetall`, and MultiMeters'
`/mm resetall`. Their seams logged 15, 16 and 169 `[Set]` lines per reset.

#### The two fields

| Field | Signature | Called |
|---|---|---|
| `bulkBegin` | `function(act, scope)` | Once, before `CliResetAll` writes its first row: act `"reset"`, scope `"all"`. |
| `bulkEnd` | `function(act, scope, count, err, info)` | Once, after the walk — **always**, whenever the bracket was begun. |

`count` is the rows whose `applyDefault` returned, and a row whose value was **already at its
default** counts. It is therefore **not** the N a host logs. `debug-logging-§10` (standard v2.44.0,
7883278) makes N the rows the act actually wrote, and a row already at its default is not one. Only
the host's write seam sees the old value, so the host tallies N itself while the bracket is open,
as the worked example below does. A descriptor with no `applyDefault` still gets the bracket, with
a count of zero. `info` is the Options major's table, `{ profileReset = <boolean> }`, and here
`profileReset` is **always `false`**: no Slash walk resets a profile. The `RESET_ALL`
acknowledgment is printed **after** `bulkEnd`, and not at all if the walk raised.

**The fields are independently optional, but a mute needs both.** A host may supply `bulkEnd`
alone, to observe the act. **A host that mutes its seam in `bulkBegin` MUST also supply
`bulkEnd`**, because that is the only place the mute is released.

**What the host logs.** `debug-logging-§10`: exactly one line, `[Set] reset all: N rows`, for the
**outermost** open bracket. The tag **MUST** be `[Set]`, and N is the host's own tally of writes
that changed a stored value, never `count`. If any bracket open at the time reported
`info.profileReset`, the host logs nothing, because its profile-event handler logs the reset. That
flag cannot come from this major, but a `CliResetAll` can run inside an Options bracket that
carries it; see the nesting rule in the Options document.

#### Call order and error semantics

```
bulkBegin("reset", "all")        -- inside the protected region
  applyDefault(row) × N          -- stops at the first row that raises, exactly as unbracketed
bulkEnd("reset", "all", count, err, info)   -- ALWAYS, once; info.profileReset is false
error(err, 0)                    -- only if something raised: the same value, re-raised unchanged
print RESET_ALL                  -- only if nothing raised, as before
```

- **A begun bracket always closes, so a host's mute cannot stick.** `bulkBegin` and the walk share
  one `pcall`. Whatever raises — a row, or `bulkBegin` itself after setting its mute flag —
  `bulkEnd` still runs, once.
- **The error is not swallowed and not re-wrapped.** `bulkEnd` receives it as `err`, then the
  library re-raises the same value with `error(err, 0)`, so a string keeps its original
  `file:line:` prefix. What changes under a bracket is the stack: a traceback shows the re-raise
  site rather than the row's frame. A `bulkEnd` that raises propagates its own error.
- **A raise of `nil` or `false` reaches `bulkEnd` as `err = nil`.** A known limitation, the same
  as the Options major's. `pcall` hands back the raised value itself, so the act looks successful
  from `err` alone. `bulkEnd` still runs once and the value is still re-raised afterwards.
- **Unbracketed — neither field a function — nothing above applies.** The walk runs bare and a
  raising row escapes with its own stack. Pinned by `tests/test_slash.lua`.

No other verb here loops rows through the descriptor: `CliReset` writes one row, which is one
`[Set]` line either way, and `BuildListLines` only reads.

#### Worked example: tally the writes, log once

The same host pair as the Options document's — build it once and hand it to both descriptors. The
seam tallies only the writes that change a stored value, and the depth counter sums the tally
across nested brackets and logs once, when the outermost closes. The nesting rule is written out
in the Options document, under "Brackets nest, and the host logs once, for the outermost".

```lua
-- settings/Schema.lua — the host's single write seam, and the host half of the bulk bracket
local bulk = { depth = 0, changed = 0, profileReset = false }

function NS.Set(path, value)
  local old = NS.GetStored(path)
  -- … validate, store, fire the row's onChange — all still per row …
  if bulk.depth > 0 then
    -- Muted. Tally only a write that CHANGED the stored value (§10's N).
    if not NS.ValuesEqual(old, value) then bulk.changed = bulk.changed + 1 end
  else
    NS.Debug("Set", "%s = %s", path, NS.FormatSchemaValue(path, value))
  end
end

NS.Bulk = {
  begin = function(act, scope)
    if bulk.depth == 0 then                         -- the OUTERMOST act opens the record
      bulk.act, bulk.scope, bulk.changed, bulk.profileReset = act, scope, 0, false
    end
    bulk.depth = bulk.depth + 1
  end,
  finish = function(act, scope, count, err, info)  -- count is NOT N
    if info.profileReset then bulk.profileReset = true end   -- never set by a Slash walk
    bulk.depth = bulk.depth - 1
    if bulk.depth > 0 then return end               -- an inner level: the outermost logs
    if bulk.profileReset then return end            -- the profile handler logged the reset
    NS.Debug("Set", "%s %s: %d rows", bulk.act, tostring(bulk.scope), bulk.changed)
  end,
}

-- settings/Slash.lua — the Slash descriptor
NS.Slash = SlashLib:New({
  -- … slash, commands, get, set, findRow, allRows, applyDefault …
  bulkBegin = NS.Bulk.begin,
  bulkEnd   = NS.Bulk.finish,
})
-- settings/OptionsSetup.lua passes the same two to the Options descriptor.
```

A `/<slash> resetall` over MultiMeters' 169 rows used to log 169 `[Set]` lines. It now logs one,
`[Set] reset all: N rows`, where N is how many of those rows were off their default. If a host's
own act, or an Options bracket, is already open around `CliResetAll`, the inner `bulkEnd` only
adds to the tally, and the single line comes when the outermost closes. The depth counter alone
would not do this: it unmutes at the right time, but without the shared tally and the
log-at-zero rule, each level would emit its own line.

### Previously, at version 7

**Comments only. The surface does not move.** Every member, descriptor field, row field, value and
behavior described below is exactly what version 6 shipped, so a host written against version
6 is correct here unmodified and there is nothing to migrate.

`Slash.lua`'s comments and docstrings were rewritten to US English — the *-our*, *-ise* and
*-yse* spellings became *-or*, *-ize* and *-yze*. `localization-§5` mandates US English and
anti-pattern #46 names code comments explicitly. **No identifier, no key, no user-visible string
and no Blizzard symbol moves**,
and `tests/test_prose.lua` fails the run on a regression.

The bump exists because the file's bytes changed and LibStub decides which vendored copy wins by
comparing minors: a minor that does not move is a minor that does not ship, so a consumer already
carrying version 6 would keep running it and never receive the corrected source. That is why a
comment-only change still bumps — see [`docs/releasing.md`](../../releasing.md) step 2.
## Why the commands table stays the host's

`commands` is required, and it is the host's own ordered `{ name, description, handler }` table,
passed in rather than owned. That is the load-bearing decision in this module.

A host owns its verbs; it also renders them on its own About or landing page. If the library owned
the table, the options module drawing that page would have to resolve `LibKa0s-Slash-1.0` to read
it — and an options library and a slash library each reaching for the other is a real dependency
cycle between two majors at load time. The table crossing between them as plain data is what keeps
them independent. It is the same argument as DebugLog's `ConsoleCheckbox()` data contract, run in
the other direction.

The practical consequence is that the seven-or-so verbs a host actually implements (`lock`, `test`,
`toggle`, …) never leave the host, so adopting this library cannot break them. What moves here is
the dispatch, the help rendering, and the schema verbs.

## `reset` takes a path, not a page

`CliReset(rest)` resets **one** setting, named by its path. There is deliberately no page-shaped
form (`reset general`, `reset bar`): a page is a property of a settings panel, not of the data, and
every schema-driven panel that asks for one carries a Defaults button that resets its page across
every unit. The capability is not lost, it just lives where the concept does. `CliResetAll()` is
unaffected and resets everything.

## Lib-level formatters and parser

Stateless and lib-level, never per-instance: a host's tests call them directly, and nothing about a
rendered row depends on which instance rendered it.

| Name | Since | Meaning |
|---|---|---|
| `lib.FormatRow(command, description)` | 1 | One command row: `\|cFFFFFF00` command, an em dash with a single space either side, `\|cFFFFFFFF` description. **Not** indented — the indent belongs to whoever renders, because a chat line sits under a header and a settings-panel label does not. This is the one command-row formatter in the collection; the `/at list` header, its group headings and any host annotation are a different, lower-case-hex family and stay that way. |
| `lib.FormatKV(path, valueStr)` | 1 | One `key = value` pair, gold key and white value, no trailing colon. Used by the list rows and by the get/set echo, so a setting reads identically wherever it is printed. |
| `lib.FormatValue(row, v, textOf)` | 1 | Render a stored value by the row's declared type — a color as `{r, g, b, a}` to two places, a number through the row's `fmt`, an empty string as `NONE`, anything else through Core's `SafeToString`. `textOf` (**19**, optional) resolves `NONE`; absent, it is `lib.STRINGS`'. At this minor the descriptor's `format` hook, when present, takes precedence over this entirely. |
| `lib.ParseValue(row, text, textOf)` | 1 | The type-aware parser. Returns the value, or `nil` plus a reason. A `number` row refuses `nan`, `inf` and `-inf` (and an overflowing literal such as `1e400`) with `ERR_NUMBER` (**20**). A `string` row reads the whole of `text`, trimmed at both ends, and an enum is matched on that full string (**10**); every other type reads whitespace-separated tokens. `textOf` (**19**, optional) is a key → string resolver for the reason; absent, the reason is `lib.STRINGS`'. |
| `lib.SplitVerb(rest)` | **6** | → `verb, remainder`. The verb **lowercased**, the remainder's case *and* internal spacing preserved. The asymmetry is the contract, not an oversight — see below. Both default to `""`. |
| `lib.FindCommand(list, name)` | **6** | → the matched `{ name, description, handler }` entry, or `nil`. Linear scan, compared verbatim; callers lowercase through `lib.SplitVerb` first. |
| `lib.CommandRows(prefix, commands, indent)` | **6** | → an array of rendered rows, one per entry: `indent .. lib.FormatRow(prefix .. " " .. entry[1], entry[2])`. `indent` defaults to `""`. |
| `lib.ParseBool(word)` | **6** | → `true`, `false`, or **`nil` meaning "not a boolean word"** — never "false". Case-insensitive over the exact eight-word set `lib.STRINGS.ERR_BOOL` advertises. |
| `lib.DISABLED_LINE_FORMAT` | **12** | `"%s is disabled \226\128\148 enable it with \|cFFFFFF00%s\|r"`. Two substitutions: the brand name, and the command **with its leading slash**. Gold `FFFFFF00` on the command — the same gold `lib.FormatRow` gives a command in the help index — an em dash with a single space either side, no trailing colon and no trailing period. |
| `lib.LIVE_VERBS` | **12** | The verbs that still answer while disabled. **At 16 it is the standard's thirteen reserved verbs** — `help`, `config`, `version`, `enable`, `disable`, `debug`, `perf`, `diagnostics`, `get`, `set`, `list`, `reset`, `resetall`. At 13 to 15 it was the same set without `diagnostics`, and at 12 it read `{ "enable", "help", "disable" }`. A host MAY narrow it to the verbs it ships. The library ships exactly one default, exported so a host that must name the set names THIS one rather than a copy of it. |
| `lib.ProfileNames(store)` | **17** | → the store's profile names sorted case-insensitively, and the current one; `{}, nil` for anything that is not a profile store. See [The profile verb](#the-profile-verb). |
| `lib.STRINGS` | 1 | Every user-visible string, keyed for the descriptor's `L` override. `NO_DEFAULT` from **15**; the nine `PROFILE_*` keys from **17**. |
| `lib.MODULES` | 1 | `{ Slash = <minor> }` — the live minor of every file in this major. |
| `lib:New(descriptor)` | 1 | Build a dispatcher for one host. |

`ParseValue` is where the type-awareness lives, and its two failure modes are deliberately not the
same. A **number out of range clamps** rather than failing, because a user typing a width larger
than the panel allows means "as wide as it goes". A **string outside its enum fails**, because there
is no such reading of a misspelt texture name. A row's `values` may be a function, evaluated at call
time rather than at load, since a host's media list is populated by another addon and is not
knowable when the schema row is declared. Colors accept `r g b [a]` in either 0–1 or 0–255 and are
rescaled **jointly** — `255 128 0` is one color expressed in one scale, and dividing only the
channels that happen to exceed 1 would mangle the rest.

Failure is signaled by a `nil` first return plus a message. No row type has a valid value that is
itself `nil`, which is what makes that unambiguous; adding one would be a contract change rather
than a new type.

A `string` row's value is the whole of `text`, trimmed at both ends (**since 10**), so a free-text
row holds several words and an enum entry containing a space, such as an LSM font name, can be
named. A `bool` and a `number` read their first token and a color its first four, as they always
have.

A `number` row refuses a token Lua reads as NaN or as an infinity (**since 20**), with the same
`ERR_NUMBER` reason as a word, before any enum or clamp: a clamp would answer the bound for an
infinity on a bounded row, and an unbounded row would store it.

## The sub-command vocabulary

New at minor 6. Four stateless functions in the shape `FormatRow` / `FormatKV` already set, for the
hosts that run a second command level under a verb (`/kcd debug <verb>`, `/cm priority <cat>
<verb>`).

### `lib.SplitVerb(rest)` → `verb, remainder`

`lib.SplitVerb`: three consumers as of v1.67.0, AbsorbTracker, ConsumableMaster and KickCD, which retired their `lowerFirst` copies and the inline split (AbsorbTracker#33, ConsumableMaster#44, KickCD#36). See [`CONSUMERS.md`](../CONSUMERS.md).

`("^(%S*)%s*(.*)$")`, with the verb **lowercased** and the remainder returned untouched. The
asymmetry is the whole point: a verb is an identifier, while the remainder is **user data** — AceDB
profile names and schema paths are both case-sensitive, so folding them would resolve something the
user did not name. The remainder also keeps its internal spacing, because a color is several tokens.
This is the same rule `Sl:OnSlash` has always applied to the top level; minor 6 just makes it
callable.

### `lib.FindCommand(list, name)` → entry or `nil`

`lib.FindCommand`: two consumers as of v1.67.0, ConsumableMaster and KickCD, which retired the copies they carried from before it existed (ConsumableMaster#44, KickCD#36). See [`CONSUMERS.md`](../CONSUMERS.md).

A linear scan of an ordered `{ name, description, handler }` array — **the same row shape the
`commands` descriptor field has always taken**, so a sub level reuses this major's existing
vocabulary rather than inventing one. `entry[1]` is compared verbatim; lowercase through
`lib.SplitVerb` first, exactly as the top level does.

### `lib.CommandRows(prefix, commands, indent)` → array of strings

`lib.CommandRows`: two consumers as of v1.67.0, ConsumableMaster and KickCD, which retired the second row format they hand-rolled beside it (ConsumableMaster#44, KickCD#36). See [`CONSUMERS.md`](../CONSUMERS.md).

One rendered row per entry, `indent .. lib.FormatRow(prefix .. " " .. entry[1], entry[2])`, with
`indent` defaulting to `""` — the indent belongs to whoever renders, for the same reason it does in
`lib.FormatRow`.

This is what makes the anti-drift guarantee mechanical rather than remembered: `Sl:HelpRows` is
`lib.CommandRows(slash, commands, "  ")` and `Sl:LandingRows` is `lib.CommandRows(slash, commands,
"")`, so the top level, the settings-panel landing page and every sub level render through **one**
formatter by construction. A host's own `("  |cffffff00%s|r — |cffffffff%s|r")` renders the same
line today and stops doing so the moment this one changes.

### `lib.ParseBool(word)` → `true`, `false`, or `nil`

Case-insensitive over `true` / `1` / `on` / `yes` and `false` / `0` / `off` / `no` — the exact set
`lib.STRINGS.ERR_BOOL` already names in its error text. The table is module-level, built once at
file load, and holds booleans only, so a miss is unambiguously `nil` rather than a stored `false`.

**`nil` means "not a boolean word", never "false".** That distinction is what lets a caller
implement toggle-on-absent (`/xx debug` with no argument flips it, `/xx debug off` sets it) without
re-reading the raw text to tell the two cases apart.

## The profile verb

New at minor 17. The host owns the COMMANDS row, the description and whether the verb is live while
disabled; the library owns what the verb does. A host wires it in two lines:

```lua
-- descriptor
profiles = function() return NS.db end,
-- COMMANDS
{ "profile", L["List profiles, or switch to one: profile <name>"],
  function(rest) cli:CliProfile(rest) end },
```

### `Sl:CliProfile(rest)`

1. `rest` is trimmed, **one** pair of matching surrounding quotes (`"x"` or `'x'`) is stripped, and
   the result is trimmed again. Case and inner spaces are kept, because profile names are
   case-sensitive user data. A lone or mismatched quote is part of the name.
2. An empty name prints the list: the header `PROFILE_LIST_HEADER`, green like `LIST_HEADER` and with
   no trailing colon; one row per profile, indented two spaces, sorted case-insensitively, the
   current one followed by `PROFILE_CURRENT_MARK`; then `PROFILE_HINT` formatted with the host's
   `slash`.
3. Anything else goes to `ProfileSwitch`.

With no `profiles` field, a `profiles` function answering nil, or a store missing a method,
`CliProfile` prints `PROFILE_UNAVAILABLE` and does nothing else.

### `Sl:ProfileSwitch(name)` → `true` or `false`

The name is used as given: no trimming and no quote stripping, so a host sub-tree that has split its
own words keeps them. An empty name prints the list and answers `false`.

| The name | What it prints | Answers |
|---|---|---|
| the current profile | `PROFILE_ALREADY` | `false` |
| an existing profile (exact match), `InCombatLockdown()` true | `PROFILE_COMBAT` | `false` |
| an existing profile (exact match), otherwise | `PROFILE_SWITCHED`, after `store:SetProfile(name)` | `true` |
| no such profile | `PROFILE_UNKNOWN`; `PROFILE_DID_YOU_MEAN` when exactly one stored name matches case-insensitively; then the list | `false` |

**An unknown name is never created.** `SetProfile` creates a missing profile, which is how a typo
becomes a stray profile, so the library only calls it for a name the store already lists. A client
with no `InCombatLockdown` global switches. The combat check covers only the switch itself: the list,
`PROFILE_ALREADY` and the unknown-name refusal still answer in combat.

**The library logs its refusals only** (from **18**, through the descriptor's `debug`: unavailable,
already current, in combat, unknown profile). `SetProfile` fires the store's own profile callback,
and the one switch line `debug-logging-§10` asks for belongs to the host's profile handler, under
whatever tag the host's profile tracing already uses. Every line goes through the descriptor's `print`, so it carries
the host's tag (`slash-commands-§4`).

### `lib.ProfileNames(store)` → `names, current`

`lib.ProfileNames`: one consumer as of v1.67.0, AbsorbTracker, whose `/at profile list` now lists through it instead of printing its own unsorted list (AbsorbTracker#33). `Sl:CliProfile` lists through it in every host. See [`CONSUMERS.md`](../CONSUMERS.md).

The store's names sorted case-insensitively, with a case-sensitive tie-break so `Main` and `main`
always print in the same order, and the current profile. The current profile is in the list even
when the store's `GetProfiles` leaves it out. Anything that is not a store with all three methods
answers `{}, nil`, so a host sub-tree can call it without a guard.

### The strings

| Key | English | Since |
|---|---|---|
| `PROFILE_UNAVAILABLE` | `Profiles are not available.` | **17** |
| `PROFILE_LIST_HEADER` | `Profiles` | **17** |
| `PROFILE_CURRENT_MARK` | `(current)` | **17** |
| `PROFILE_HINT` | `%s profile <name> switches profile` (the host's `slash`) | **17** |
| `PROFILE_ALREADY` | `Already on profile '%s'.` | **17** |
| `PROFILE_COMBAT` | `Can't switch profiles in combat.` | **17** |
| `PROFILE_SWITCHED` | `Switched to profile '%s'.` | **17** |
| `PROFILE_UNKNOWN` | `No profile named '%s'.` | **17** |
| `PROFILE_DID_YOU_MEAN` | `Did you mean '%s'?` | **17** |

## The dispatcher descriptor

Everything a host supplies to `lib:New(descriptor)`.

| Field | Type | Required | Since | Meaning |
|---|---|---|---|---|
| `slash` | string | yes | 1 | The command prefix, **with** its slash: `"/at"`. Every usage line and every help row is composed from it. |
| `commands` | table | yes | 1 | The host's ordered `{ name, description, handler }` triples. Passed in, never owned — see above. The handler is called with the rest of the line, verbatim. |
| `slashAliases` | table | no | 1 | Other chat commands reaching the same dispatcher. The first is named in the help header. Registering them is the host's job; this library registers no slash command of its own. |
| `aliases` | table | no | 1 | Map of typed verb → real verb, for backwards compatibility (`{ options = "config" }`). |
| `print` | function(line) | no | 1 | Where lines go. Defaults to the chat frame. Hosts pass their prefixed printer. |
| `version` | function | no | 1 | Returns the host's version string, for the help header and `version`. |
| `get` | function(path) | no | 1 | Read one setting by path. |
| `set` | function(path, v) | no | 1 | Write one setting by path. **From 15** it MAY answer `false, reason[, why]` to refuse the write, as `LibKa0s-Schema-1.0`'s `S.Set` does; `CliSet` then prints the refusal instead of the echo. `nil` or `true` means the write landed. |
| `findRow` | function(path) | no | 1 | Resolve a path to a schema row, or nil. |
| `allRows` | function | no | 1 | Every row, in declaration order — which is the order `list` prints. |
| `applyDefault` | function(row) | no | 1 | Restore one row to its default. **From 15**, answering exactly `false` (as `S.ApplyDefault` does for a row with no default) makes `CliReset` print `NO_DEFAULT` instead of the echo. |
| `bulkBegin` | function(act, scope) | no | **8** | Called once before `CliResetAll` writes its first row: act `"reset"`, scope `"all"`. Mute the host seam's per-row `[Set]` line here — `debug-logging-§10`. Same field as the Options descriptor's. See [The two fields](#the-two-fields). |
| `bulkEnd` | function(act, scope, count, err, info) | no | **8** | The fifth argument is the Options major's `info` table, whose `profileReset` is always `false` here. The host emits `[Set] reset all: N rows` when its outermost bracket closes, with N its own tally of writes that changed a stored value — **not** `count`, which includes rows already at their default. A host that mutes in `bulkBegin` MUST supply this field. Called once after the walk, **always** when the bracket was begun — even if a row or `bulkBegin` raised. `count` is the number of rows `applyDefault` returned for, including rows already at their default — the host logs its own tally of changed writes instead; `err` is the raised value or `nil` (a raise of `nil`/`false` also arrives as `nil`), re-raised unchanged after this returns. Unmute here, and emit the one summary line only when the outermost bracket closes. A host supplying neither runs version 7's walk exactly. |
| `parse` | function(row, text, textOf) | no | 1 | Defaults to `lib.ParseValue`. Called with the row and everything after the path, untrimmed. From **19** also handed the instance's key → string resolver (`Sl:Text`), to pass on to `lib.ParseValue` so the host's `L` reaches its refusals. |
| `format` | function(row, stored) | no | **5** | Renders a value for display, replacing `lib.FormatValue` outright, at every list/get/set/reset echo. The counterpart of `parse`: for a row type this library does not know — a set, a pattern needing its pipes doubled. Handed the value **as stored**, and taking precedence over `colorDecode`. |
| `groupKey` | function(row) | no | 1 | Row → the heading it lists under. Defaults to `row.page or "settings"` — a row with no page still lists somewhere. |
| `colorDecode` | function(stored) | no | 4 | → `r, g, b, a`. Same field name as the Options descriptor's, so a host passes one pair to both majors. Defaults to reading the named-key form, then the positional one. |
| `colorEncode` | function(r,g,b,a) | no | 4 | → stored. Defaults to `{r=,g=,b=,a=}`. |
| `isEnabled` | function | no | **12** | → boolean. **Absent, the gate is off** and the dispatcher behaves exactly as at version 11. Present and answering false, the verbs in `liveVerbs` dispatch as usual — as does the bare command, which opens the panel (**13**) — and every other verb the host SHIPS prints the refusal line. A verb with no `commands` entry behind it is not refused at all (**14**). Asked at dispatch time, never cached. |
| `brandName` | string | **when `isEnabled` is given** | **12** | The addon's brand name in plain text, `Ka0s <Name>` — the same string the LDB object takes as its `label`. Never derived from the TOC `Title`, which may carry color escapes. Missing it alongside `isEnabled` raises at `New`. |
| `liveVerbs` | table | no | **12** | Array of the verbs that still answer while disabled. Defaults to `lib.LIVE_VERBS`, which is the standard's reserved verbs from **13**, thirteen of them from **16** (`diagnostics`). It names the verbs that stay live, not the verbs the host registers: from **14** a verb listed here with no `commands` entry behind it is answered as unknown rather than refused. Present so the set is data rather than a hard-coded branch; a host MAY narrow it to the verbs it actually ships. |
| `profiles` | function | no | **17** | → the host's profile store, or nil. Duck-typed on AceDB-3.0's shape, `GetProfiles(tbl) -> tbl, n`, `GetCurrentProfile()`, `SetProfile(name)`, and never required to be AceDB. Asked at call time, because a host's db is built after its slash file runs. Absent, answering nil, or a store missing a method: `CliProfile` prints `PROFILE_UNAVAILABLE`. |
| `debug` | function(tag, message) | no | **18** | The host's gated log seam, as Launcher's. Each refusal this module decides writes one `Cmd` line after its chat line: see [Previously, at version 18](#previously-at-version-18). Absent or not a function: no line. |
| `L` | table | no | 1 | Locale override, keyed identically to `lib.STRINGS`. From **19** it reaches every parse refusal and the empty-string `NONE` as well. **It does not reach the disabled refusal line** (**12**): that wording is the collection's rather than the addon's. **Pass a PLAIN table holding only the keys you actually translate — never an addon-wide locale table.** See [The `L` trap](#the-l-trap). |

Only `slash` and `commands` are required, and both raise rather than defaulting: a dispatcher with
no prefix has nothing to compose usage lines from, and one with no verb table answers every input
with "unknown command". Everything schema-shaped is optional, so a host with no settings schema gets
a working dispatcher and help renderer and simply never wires the CLI verbs into `commands`.

## The instance surface

Everything `lib:New(descriptor)` returns on the instance.

| Name | Since | Meaning |
|---|---|---|
| `OnSlash(msg)` | 1 | The entry point. **From 12**, when `isEnabled` answers false: the verb is lower-cased and aliases resolve as always, every verb in `liveVerbs` dispatches normally, and anything else prints `DisabledLine()` and returns. **From 13** the gate moved AFTER the COMMANDS lookup, so only a verb the host SHIPS is refused; a typo falls through to `unknown command` and the index, per slash-commands-§3. **From 13** the live set is the standard's reserved verbs (twelve; thirteen from **16**, with `diagnostics`) and the bare command runs the host's `config` verb in either state, where at 12 the bare command was refused. **From 14** a verb that is in `liveVerbs` but has no COMMANDS entry behind it — `perf` on an addon holding a no-combat-path exemption — is no longer refused either: it is not one of the host's commands, so it takes the same `unknown command` path it takes while enabled, where 13 answered it with `DisabledLine()`. Enabled, or with no `isEnabled` at all: an empty line runs the host's `config` verb, or prints help when the host has none (**11**; through 10 it always printed help); otherwise the first token is lowercased, mapped through `aliases`, and dispatched. Only the verb is lowercased — `rest` keeps its case, because schema paths are case-sensitive, and its internal spacing, because a color is several tokens. An unknown verb says so and then prints help. |
| `DisabledLine()` | **12** | The one refusal line, built from `lib.DISABLED_LINE_FORMAT` and the descriptor's `brandName` and `slash`. Every call site — the dispatcher's gate, the help header, the launcher's left-click — calls THIS. The host's own `print` adds `NS.PREFIX` as it does for every other line, so the tag is not built in. |
| `PrintHelp()` | 1 | The header, then `HelpRows()`, through the descriptor's `print`. **From 12**, when the gate is closed, the refusal line is emitted immediately after the header and before the first row, unindented. |
| `HelpHeader()` | 1 | `v<version> — slash commands`, plus the alias note when `slashAliases` has one. |
| `HelpRows()` | 1 | The command rows, indented two spaces, because each sits under a header in chat. |
| `LandingRows()` | 1 | The same rows, same colors and spacing, **no** indent — for a settings panel, where each row is its own label and a leading indent reads as a mistake. |
| `BuildListLines()` | 1 | The `list` output as lines, without printing: header, then each `groupKey` heading in declaration order with its rows beneath. Returns the empty-state line when there are no rows. Grouped in declaration order rather than alphabetically, because a schema's order is the order its panel shows and a listing that disagreed with the panel would be its own puzzle. |
| `CliList()` | 1 | `BuildListLines()`, printed. |
| `CliGet(rest)` | 1 | Echo one setting. |
| `CliSet(rest)` | 1 | Parse and store one setting, then echo it by **re-reading** — a clamped number is only visible to the user because the echo reports what was actually stored, not what was typed. **From 15**, when `set` answers `false, reason[, why]`: the `INVALID` line for the path, then `reason` (unless it is that same line) and `why`, each indented two spaces, and no echo. |
| `CliReset(rest)` | 1 | Reset one setting by path, and echo it. Never annotated. **From 15**, when `applyDefault` answers exactly `false`, prints `NO_DEFAULT` for the path instead of the echo. |
| `CliResetAll()` | 1 | `applyDefault` over every row, then one acknowledgment. **From 8** the walk runs inside the descriptor's optional `bulkBegin` / `bulkEnd` bracket (act `"reset"`, scope `"all"`), and the acknowledgment is printed after `bulkEnd` — not at all if the walk raised. |
| `CliVersion()` | 1 | The host's version. |
| `CliProfile(rest)` | **17** | The `profile` verb: bare lists the profiles, current marked; a name (quotes stripped, case kept) goes to `ProfileSwitch`. `PROFILE_UNAVAILABLE` with no store. See [The profile verb](#the-profile-verb). |
| `ProfileSwitch(name)` | **17** | Switch to an already-parsed name: `PROFILE_ALREADY`, `PROFILE_COMBAT`, `PROFILE_SWITCHED`, or `PROFILE_UNKNOWN` with a did-you-mean and the list. Never creates a profile. Answers `true` only when it switched. |
| `SetRowAnnotator(fn)` | 1 | Install a host suffix appended to a rendered setting — most usefully a note that the stored value is not the one in effect. Applied at exactly three sites: a list row, a get echo and a set echo. Never on reset or resetall, where an explanation of what a value means is noise stapled to an acknowledgment that the value went away. |
| `Text(key)` | 1 | Resolve one user-visible string, the descriptor's `L` first, then `lib.STRINGS`. |

**Consumer census, v1.67.0** ([`CONSUMERS.md`](../CONSUMERS.md)). No host calls or passes these:

- `CliResetAll`: no consumer as of v1.67.0, kept because the library's `resetall` verb runs it in every host that does not replace it; BankLedger and LootHistory replace it on purpose with a confirmed profile reset.

## The degradation stub

A host's library-absent build — `libs/LibKa0s/` missing, or `LibStub("LibKa0s-Slash-1.0", true)`
answering nil — still has a slash command, and something has to answer it. That something is the
host's **degradation stub**: a small table standing in for the instance `lib:New(descriptor)` would
have returned. `slash-commands-§1` bounds what it may carry, and this section is the shape that
meets the bound. Nothing in `Slash.lua` changes for it; the contract is the host's, and the pin
that keeps it honest is `Kit.assertLibraryConstant` (test kit revision 26).

**Minimal `OnSlash` dispatch is sanctioned.** Split the verb off, lower-case it, look it up in the
host's own `commands` table, call the handler with the rest. An unknown verb says so and prints
the rows. That is all: no alias map, no disabled gate beyond the one below, no schema CLI. The
stub is not a second dispatcher and MUST NOT grow into one.

**`DisabledLine` is built from `DISABLED_LINE_FORMAT`'s bytes, copied verbatim — and that is the
one library string a stub may carry.** Wording the refusal differently in a degraded build is the
drift `slash-commands-§7`'s one-refusal-line rule exists to prevent, and the library is not there
to ask. So the host copies the format string once, byte for byte (the em dash is
`\226\128\148`), and formats it the way `cli:DisabledLine()` does: the plain-text `brandName`,
then `<slash> enable`. A case in the host's suite then pins the copy against the live library:

```lua
T.assertLibraryConstant(Sl.__DISABLED_LINE_FORMAT, "LibKa0s-Slash-1.0", "DISABLED_LINE_FORMAT")
```

The assertion resolves the major through the runner's surface source and, when that source maps
the name to the Slash **instance** (as a runner does for the parity gate), falls back to the mock's
LibStub for this lib-level member. It fails naming both strings, so a red run shows which byte
drifted. The string is the only one: `lib.STRINGS`, the help header and every other wording stay
the library's, and a stub that needs one of them prints its own plain sentence instead.

**Help rows print `cmd  desc`, plainly — no `FormatRow` copy.** `lib.FormatRow`'s colors and its
` — ` separator are rendering, and a stub that re-implements the library's rendering is the thing
anti-pattern #73 forbids. Two spaces between the command and its description, no color escapes, no
em dash. A degraded help index is allowed to look degraded.

**A verb whose write targets a composed row takes one of `options-ui-§1`'s two routes, and never
raises.** `enable`, `disable`, `lock`, `unlock`, test mode, the combat re-lock: each writes a row
the library's composers build, and on a library-absent load there is no row. The verb either:

- **(a) writes through** the path the host declares in the Schema seam's `writeThrough` list
  (`LibKa0s-Schema-1.0` minor 2) — the same list handed to the live instance and to the
  runtime-completing Schema stub, so the stored value lands without a hand-written row; or
- **(b) prints the library-absent line** and writes nothing:

  ```lua
  -- one sentence, one placeholder, routed through the host's locale
  L["%s is unavailable: the LibKa0s library did not load."]:format("/wg enable")
  ```

  `%s` is the full verb as the player typed it. The verb MUST NOT raise a Lua error and MUST NOT
  acknowledge a write that did not land.

`enable` and `disable` SHOULD take route (a); a host that takes (b) for them records the SHOULD
deviation. Every other verb the stub cannot serve — `get`, `set`, `list` with no schema behind them
— prints the library-absent line for itself in the same way.

**From version 17 the stub carries `CliProfile` and `ProfileSwitch`**, because the live instance
has both. With the library absent there is no store adapter to trust, so both take route (b): each
prints the library-absent line for `<slash> profile` and switches nothing. A stub checked by the
kit's by-name form, `T.assertSurfaceParity(<stub>, "LibKa0s-Slash-1.0", ignore)`, owes both
whether or not its own `profile` row or sub-tree calls them, because that form compares the stub
against every public function on the live dispatcher instance the runner registered. A host whose
stub never reaches `ProfileSwitch` may name it in the call's `ignore` list instead of carrying it;
see [Compatibility](#compatibility) for what the re-vendor alone does to that case.

A minimal stub, with route (b) throughout:

```lua
local STUB_DISABLED_LINE_FORMAT = "%s is disabled \226\128\148 enable it with |cFFFFFF00%s|r"
local UNAVAILABLE = L["%s is unavailable: the LibKa0s library did not load."]

local Sl = { __DISABLED_LINE_FORMAT = STUB_DISABLED_LINE_FORMAT }

function Sl:DisabledLine()
  return STUB_DISABLED_LINE_FORMAT:format(BRAND, SLASH .. " enable")
end

function Sl:OnSlash(msg)
  local verb, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
  verb = verb:lower()
  for _, entry in ipairs(COMMANDS) do
    if entry[1] == verb then return entry[3](rest) end
  end
  -- the host's own words: UNKNOWN_COMMAND is lib.STRINGS', and a stub does not copy it
  if verb ~= "" and verb ~= "help" then Print(("%s %s: no such command"):format(SLASH, verb)) end
  for _, entry in ipairs(COMMANDS) do Print(SLASH .. " " .. entry[1] .. "  " .. entry[2]) end
end

-- a composed-row verb on route (b)
local function degradedEnable() Print(UNAVAILABLE:format(SLASH .. " enable")) end

-- the profile verb on route (b), from version 17; both members, because the live instance has both
function Sl:CliProfile() Print(UNAVAILABLE:format(SLASH .. " profile")) end
function Sl:ProfileSwitch() Print(UNAVAILABLE:format(SLASH .. " profile")); return false end
```

## The `L` trap

`L` must be a **plain table holding only the keys you actually translate** — never an addon-wide
locale table. Many locale tables carry a metatable whose `__index` answers the key itself, so a
missing key answers its own name rather than `nil` and the library's default never resolves. From
Slash minor 3 the resolver uses `rawget`, so a metatable-backed table no longer poisons the
lookup — but passing a scoped table is still the contract, because it is the only form that is
correct on every minor.

## Compatibility

The API is **additive-only**: a member or descriptor field may be added in a later minor, never
removed or repurposed, so a host written against minor 1 keeps working unmodified here.

**What moves at version 20 is one refusal.** `set <path> nan`, `inf`, `-inf` or `1e400` on a number
row answers the `INVALID` line with `ERR_NUMBER` under it, where version 19.1 stored the value (an
unbounded row) or the bound (a bounded row's infinity). Every finite input answers as before. No
consumer test in the collection pinned the old acceptance when this was written.

**What moves at version 19 is wording, and only for a host that asked for it.** A host whose `L`
carries `ERR_BOOL`, `ERR_NUMBER`, `ERR_STRING`, `ERR_ALLOWED`, `ERR_COLOR`, `ERR_TYPE` or `NONE` now
sees its own text where it saw the library's. A host with no such keys sees no change. A host
`parse` taking a third positional argument for something else would now receive the resolver there;
no consumer's did when this was written.

**What is added at version 18 is one descriptor field, `debug`, and no chat moves.** A host that
passes none sees no change on re-vendor; one that passes its gated sink gains a `Cmd` line per
refusal and SHOULD delete any host line that duplicates it (AbsorbTracker's DisabledLine match). No
instance or lib-level member is added, so no parity gate moves.

**What is added at version 17 is the profile verb, and no runtime behavior moves; one kind of
parity gate does.** A descriptor field (`profiles`), two instance members (`CliProfile`,
`ProfileSwitch`), one lib-level function (`ProfileNames`) and nine strings. A host that passes no
`profiles` and registers no `profile` row sees no change in the client on re-vendor, and
`lib.LIVE_VERBS` is unchanged.

**Its test suite can go red on the re-vendor alone.** The kit's by-name form,
`T.assertSurfaceParity(<stub>, "LibKa0s-Slash-1.0", ignore)`, does not read the member manifest. It
resolves the live half through the surface source the runner registered with
`Kit.setSurfaceSource`, and compares the stub against `Kit.publicMembers` of that live table. A
runner that maps the name to the Slash **instance** (`lib:New(descriptor)`'s return) — the usual
shape, because a host's stub mirrors the instance — now compares against an instance with two more
public functions, and a stub that has neither fails:

```text
LibKa0s-Slash-1.0: the degraded stub diverges from the live surface in 2 place(s) —
CliProfile is missing (live: function); ProfileSwitch is missing (live: function)
```

It stays red until the stub carries **both** members (route (b), see
[The degradation stub](#the-degradation-stub)) or the call's `ignore` list names the one it does
not carry. This does not depend on whether the host ships a `profile` verb or which member its
`profile` row calls. The member manifest, `members-17.json`, lists only the lib-level table, so it
gains `ProfileNames` and neither instance member; a runner whose source answers the **library
table** for the name (`Kit.setSurfaceSource(mocks.LibStub)`) holds a lib-level stub to
`ProfileNames` the same way.

Measured on 2026-09-29 on all eleven consumers: each consumer's `master`, cloned into a scratch
directory, with the v1.63.0 payloads dropped in (`LibKa0s/` into `libs/LibKa0s/`, `testkit/` into
`tests/_kit/`) and the provenance line moved, then `lua tests/run.lua`. Six go red in this case and
nowhere else, one failed case each, with the message above: AbsorbTracker, AuraMaster, KickCD,
PartyFrameEnhanced, PrettyChat and WhatGroup, all of which check the dispatcher instance by name.
Five stay green: BankLedger, ConsumableMaster, LootHistory and PanelMaster compare two tables they
build themselves (the four-argument form, the host's own Slash table on both arms), and MultiMeters
has no Slash parity case. No consumer checks a lib-level Slash stub by name, so none goes red on
`ProfileNames`.

**What moves at version 16 is the default live set, by one verb.** `diagnostics` joins
`lib.LIVE_VERBS`, so a disabled host that ships the verb and passes no `liveVerbs` (or one built on
`lib.LIVE_VERBS`) runs it where version 15 answered the refusal line. A host that does not register
`diagnostics` sees no change in either state. A host that passes a literal array keeps its own set
until it adds the verb. No member and no descriptor field moves.

**What moves at version 15 is behavior, and only for a host whose seam refuses.** A `set` that
answers `false` gets its refusal printed instead of an echo of the unchanged value, and an
`applyDefault` that answers `false` gets `NO_DEFAULT`. A host whose `set` and `applyDefault` answer
nothing — every host written against version 14 that does not route through `S.Set` — sees no
change. A host that prints its own refusal inside a `set` wrapper would now print it twice, and
should return the seam's answer instead.

**What moves at version 14 is behavior, and it is one input.** A reserved verb the host never
registered answers `unknown command '<verb>'` and the index while disabled, where version 13 answered
the refusal line. No member and no descriptor field moves, and `lib.LIVE_VERBS` is unchanged — the
set of verbs the standard reserves is not a claim about which of them a given host ships. A host
written against version 13 needs no change; a `tests/test_disabled.lua` that pinned the refusal for a
verb its addon does not ship inverts that one expectation.

**What moves at version 13 is behavior, by the standard's reversal (v2.57.0), and it moves in the
direction of answering.** Every input version 12 answered, version 13 answers the same way; nine
kinds of input version 12 refused are answered now — the bare `/<slash>`, `config`, `version`,
`debug`, `perf` and the five schema verbs. Nothing a host wrote against version 12 needs to change,
except a `liveVerbs` array passed to reproduce version 12's narrowing, which now narrows the restored
set instead. A host with no `isEnabled` is unaffected, as it was at 12.

**What moves at version 11 is behavior, by the standard's decision (v2.50.0).** An empty line runs the
host's `config` verb instead of printing the help index; `help` is unchanged, and a host with no
`config` verb sees no change. Every Ka0s consumer carries `config` (a reserved verb), so every one
of them changes on re-vendor, which is the point.

**What moved at version 10 is behavior, in the direction of working.** A `string` row stores the
whole trimmed value where it stored the first word. Every input version 9 accepted is still
accepted, with one exception: a constrained string with trailing words is refused instead of cut
short. No consumer test in the collection pinned the old truncation when this was measured.

**What is added at version 8 is `bulkBegin` / `bulkEnd` on the descriptor, and nothing else.** A host
that supplies neither runs `CliResetAll` exactly as version 7 did — the same `applyDefault` calls in
the same order, the same acknowledgment, and no `pcall` on the path. That is pinned in
`tests/test_slash.lua` and was measured on all ten consumers with the payload dropped in: nothing
moves on re-vendor.
