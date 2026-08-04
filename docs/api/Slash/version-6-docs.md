# `LibKa0s-Slash-1.0` — version 6

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Slash surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Slash-1.0` |
| Files and minors | `Slash.lua` minor **6** |
| Shipped in | unreleased |
| Status | **Current** |
| Supersedes | [version 5](./version-5-docs.md) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`) |
| Confirm in-game | `LibStub("LibKa0s-Slash-1.0").MODULES` → `{ Slash = 6 }` |

`Since` in the tables below is the Slash minor in which the member first appeared. Minors 1–3 were
never tagged, so a `Since` of 1, 2 or 3 means "present for as long as any consumer could have had
this major".

## What this major is

The slash dispatcher, the help renderer, the schema CLI and the value parser — everything between
"the user typed `/at something`" and "a setting changed", minus the settings themselves.

Four-plus copies of it exist across the collection, in two different shapes, and the divergence is
not cosmetic. One shape parses values by bare coercion, so `set barWidth 99999` stores 99999 and a
`get` on a colour prints a table address. This library takes the type-aware shape — clamping, enum
validation, colour tuples — on the view that a CLI silently accepting a value it cannot honour is
worse than one that refuses.

Like DebugLog, it depends on LibStub and `LibKa0s-Core-1.0` and on no addon framework, and it
returns before `NewLibrary` if Core is missing or below the minor it needs.

## What changed at this version

**Four new lib-level functions — `SplitVerb`, `FindCommand`, `CommandRows`, `ParseBool` — and
nothing else.** No descriptor field, no instance member and no rendered byte moved, so a host
written against minor 5 is correct here unmodified.

They are the vocabulary a **sub-command level** needs, and they are here because two hosts had
already copied byte-identical `lowerFirst` / `findCommand` file-locals out of this dispatcher and
then hand-rolled a *second* command-row format beside this library's own — the same drift, one level
down, that the shared formatter exists to end. See
[The sub-command vocabulary](#the-sub-command-vocabulary).

The **dispatcher** is deliberately not here. Its control flow is genuinely per-host — a bare
`/kcd debug` toggles the console window before printing help, `/cm priority <cat> <verb>` resolves a
category object between the two levels, and both append context lines after the rows — so owning it
would cost four escape hatches to save six lines per host. Owning the *vocabulary* buys the
anti-drift guarantee; owning the flow buys nothing.

Internally, `Sl:HelpRows` and `Sl:LandingRows` are now one-liners over `lib.CommandRows`, and the
private `parseBool` is a wrapper over `lib.ParseBool`. Both render exactly what they rendered at
minor 5; `lib.FormatValue`'s colour arm was restructured into a named channel reader for the same
complexity reason and produces the same string for every input.

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
| `lib.FormatValue(row, v)` | 1 | Render a stored value by the row's declared type — a colour as `{r, g, b, a}` to two places, a number through the row's `fmt`, an empty string as `STRINGS.NONE`, anything else through Core's `SafeToString`. At this minor the descriptor's `format` hook, when present, takes precedence over this entirely. |
| `lib.ParseValue(row, text)` | 1 | The type-aware parser. Returns the value, or `nil` plus a reason. |
| `lib.SplitVerb(rest)` | **6** | → `verb, remainder`. The verb **lowercased**, the remainder's case *and* internal spacing preserved. The asymmetry is the contract, not an oversight — see below. Both default to `""`. |
| `lib.FindCommand(list, name)` | **6** | → the matched `{ name, description, handler }` entry, or `nil`. Linear scan, compared verbatim; callers lowercase through `lib.SplitVerb` first. |
| `lib.CommandRows(prefix, commands, indent)` | **6** | → an array of rendered rows, one per entry: `indent .. lib.FormatRow(prefix .. " " .. entry[1], entry[2])`. `indent` defaults to `""`. |
| `lib.ParseBool(word)` | **6** | → `true`, `false`, or **`nil` meaning "not a boolean word"** — never "false". Case-insensitive over the exact eight-word set `lib.STRINGS.ERR_BOOL` advertises. |
| `lib.STRINGS` | 1 | Every user-visible string, keyed for the descriptor's `L` override. |
| `lib.MODULES` | 1 | `{ Slash = <minor> }` — the live minor of every file in this major. |
| `lib:New(descriptor)` | 1 | Build a dispatcher for one host. |

`ParseValue` is where the type-awareness lives, and its two failure modes are deliberately not the
same. A **number out of range clamps** rather than failing, because a user typing a width larger
than the panel allows means "as wide as it goes". A **string outside its enum fails**, because there
is no such reading of a misspelt texture name. A row's `values` may be a function, evaluated at call
time rather than at load, since a host's media list is populated by another addon and is not
knowable when the schema row is declared. Colours accept `r g b [a]` in either 0–1 or 0–255 and are
rescaled **jointly** — `255 128 0` is one colour expressed in one scale, and dividing only the
channels that happen to exceed 1 would mangle the rest.

Failure is signalled by a `nil` first return plus a message. No row type has a valid value that is
itself `nil`, which is what makes that unambiguous; adding one would be a contract change rather
than a new type.

## The sub-command vocabulary

New at minor 6. Four stateless functions in the shape `FormatRow` / `FormatKV` already set, for the
hosts that run a second command level under a verb (`/kcd debug <verb>`, `/cm priority <cat>
<verb>`).

### `lib.SplitVerb(rest)` → `verb, remainder`

`("^(%S*)%s*(.*)$")`, with the verb **lowercased** and the remainder returned untouched. The
asymmetry is the whole point: a verb is an identifier, while the remainder is **user data** — AceDB
profile names and schema paths are both case-sensitive, so folding them would resolve something the
user did not name. The remainder also keeps its internal spacing, because a color is several tokens.
This is the same rule `Sl:OnSlash` has always applied to the top level; minor 6 just makes it
callable.

### `lib.FindCommand(list, name)` → entry or `nil`

A linear scan of an ordered `{ name, description, handler }` array — **the same row shape the
`commands` descriptor field has always taken**, so a sub level reuses this major's existing
vocabulary rather than inventing one. `entry[1]` is compared verbatim; lowercase through
`lib.SplitVerb` first, exactly as the top level does.

### `lib.CommandRows(prefix, commands, indent)` → array of strings

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
| `set` | function(path, v) | no | 1 | Write one setting by path. |
| `findRow` | function(path) | no | 1 | Resolve a path to a schema row, or nil. |
| `allRows` | function | no | 1 | Every row, in declaration order — which is the order `list` prints. |
| `applyDefault` | function(row) | no | 1 | Restore one row to its default. |
| `parse` | function(row, text) | no | 1 | Defaults to `lib.ParseValue`. |
| `format` | function(row, stored) | no | **5** | Renders a value for display, replacing `lib.FormatValue` outright, at every list/get/set/reset echo. The counterpart of `parse`: for a row type this library does not know — a set, a pattern needing its pipes doubled. Handed the value **as stored**, and taking precedence over `colorDecode`. |
| `groupKey` | function(row) | no | 1 | Row → the heading it lists under. Defaults to `row.page or "settings"` — a row with no page still lists somewhere. |
| `colorDecode` | function(stored) | no | 4 | → `r, g, b, a`. Same field name as the Options descriptor's, so a host passes one pair to both majors. Defaults to reading the named-key form, then the positional one. |
| `colorEncode` | function(r,g,b,a) | no | 4 | → stored. Defaults to `{r=,g=,b=,a=}`. |
| `L` | table | no | 1 | Locale override, keyed identically to `lib.STRINGS`. **Pass a PLAIN table holding only the keys you actually translate — never an addon-wide locale table.** See [The `L` trap](#the-l-trap). |

Only `slash` and `commands` are required, and both raise rather than defaulting: a dispatcher with
no prefix has nothing to compose usage lines from, and one with no verb table answers every input
with "unknown command". Everything schema-shaped is optional, so a host with no settings schema gets
a working dispatcher and help renderer and simply never wires the CLI verbs into `commands`.

## The instance surface

Everything `lib:New(descriptor)` returns on the instance.

| Name | Since | Meaning |
|---|---|---|
| `OnSlash(msg)` | 1 | The entry point. An empty line prints help; otherwise the first token is lowercased, mapped through `aliases`, and dispatched. Only the verb is lowercased — `rest` keeps its case, because schema paths are case-sensitive, and its internal spacing, because a colour is several tokens. An unknown verb says so and then prints help. |
| `PrintHelp()` | 1 | The header, then `HelpRows()`, through the descriptor's `print`. |
| `HelpHeader()` | 1 | `v<version> — slash commands`, plus the alias note when `slashAliases` has one. |
| `HelpRows()` | 1 | The command rows, indented two spaces, because each sits under a header in chat. |
| `LandingRows()` | 1 | The same rows, same colours and spacing, **no** indent — for a settings panel, where each row is its own label and a leading indent reads as a mistake. |
| `BuildListLines()` | 1 | The `list` output as lines, without printing: header, then each `groupKey` heading in declaration order with its rows beneath. Returns the empty-state line when there are no rows. Grouped in declaration order rather than alphabetically, because a schema's order is the order its panel shows and a listing that disagreed with the panel would be its own puzzle. |
| `CliList()` | 1 | `BuildListLines()`, printed. |
| `CliGet(rest)` | 1 | Echo one setting. |
| `CliSet(rest)` | 1 | Parse and store one setting, then echo it by **re-reading** — a clamped number is only visible to the user because the echo reports what was actually stored, not what was typed. |
| `CliReset(rest)` | 1 | Reset one setting by path, and echo it. Never annotated. |
| `CliResetAll()` | 1 | `applyDefault` over every row, then one acknowledgement. |
| `CliVersion()` | 1 | The host's version. |
| `SetRowAnnotator(fn)` | 1 | Install a host suffix appended to a rendered setting — most usefully a note that the stored value is not the one in effect. Applied at exactly three sites: a list row, a get echo and a set echo. Never on reset or resetall, where an explanation of what a value means is noise stapled to an acknowledgement that the value went away. |
| `Text(key)` | 1 | Resolve one user-visible string, the descriptor's `L` first, then `lib.STRINGS`. |

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
