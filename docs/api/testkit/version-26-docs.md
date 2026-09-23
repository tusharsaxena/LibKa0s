# `testkit` — version 26

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, **`asserts.lua`**, `loader.lua`, `mock_base.lua`, `mock_record.lua`, **`mock_events.lua`**, `mock_ids.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, **`prose_lists.lua`**, `test_layout_cap.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **26** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.56.0 |
| Status | **Current** |
| Supersedes | [version 25](version-25-docs.md) — the pair key, the cap gate and the prose carve-out |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `26` |

## What changed

**Three new files, one new assertion, and three behavioral changes: the AceDB fake, event
registration, and a new frame starting shown.** The first two files are peels, made to take two kit files back under
`layout-§1`'s 1500-line cap and to give the growth still to come somewhere else to land:

| New file | What moved into it | Loaded by |
|---|---|---|
| `asserts.lua` | `Kit.fail`, `Kit.assertEqual`, `Kit.assertTrue`, `Kit.assertFalse`, `Kit.assertNil`, `Kit.assertNear`, `Kit.assertError`; the surface source and the parity gate — `Kit.setSurfaceSource`, `Kit.publicMembers`, `Kit.assertSurfaceParity` and their private helpers | `framework.lua`, once, where the block stood and before `Kit.expose` |
| `prose_lists.lua` | `test_prose.lua`'s published `BRITISH` and `ALLOWED` lists, their two published counts, and the `SKIPPED_DIRS` folder exclusions | `test_prose.lua`, at load |

Each is found from its parent's own chunk name — the folder `debug.getinfo(1, "S").source` names —
with `tests/_kit/` as the fallback for a loader that rewrites chunk names, which is how
`mock_base.lua` has found `mock_record.lua` since revision 22. Neither is loaded on its own, and a
copy of the kit missing either one **raises at load** rather than running without it.

The peel adds, removes, renames or resignatures no member a suite calls, and changes what none of
them does. Every member is on the kit table at the moment it was in revision 25, so `Kit.expose`
copies the same set, plus the one new member below. One visible difference only: a failed assertion's error position names `asserts.lua`
rather than `framework.lua`, because that is where the raising function now lives. `framework.lua`
is 1382 lines (1583 at revision 25; the peel left it at 1381, and `Kit.expose`'s
`assertErrorMatches` line adds one) and `test_prose.lua` 1464 (1499).

### One new member: `Kit.assertErrorMatches`

| Name | Since | Meaning |
|---|---|---|
| `Kit.assertErrorMatches(fn, needle, msg)` | **26** | `fn` must raise, **and** the raised text must contain `needle` — plain text, found with `string.find(err, needle, 1, true)`, never a pattern. Fails when `fn` returns normally, naming the needle it waited for, and fails when `fn` raises something else, naming the needle **and** the text actually raised; `msg`, when given, leads either failure. Returns the error text, as `assertError` does. `Kit.expose` copies it as `assertErrorMatches`. In `asserts.lua`. |

It exists because `Kit.assertError(fn, msg)` proves only that `fn` raised: `msg` is the text of its
own failure, and a caller that uses it as a statement discards the error it returns. `testing-§12`
does not accept "it raised" as proof, since such a case passes on a raise from the wrong line, or
from a typo in the case itself. `assertError` is unchanged and remains the form for a case that
goes on to check several things about the returned text; a statement-position check wants
`assertErrorMatches`. This repository's 23 statement-position `assertError` calls were rewritten to
it in the same release, and `tests/test_kit_asserts.lua` holds the member's own three cases.

### A behavioral change: the AceDB fake's profile verbs raise where AceDB-3.0 raises

**This one is behavioral.** A consumer suite that calls `CopyProfile` or `DeleteProfile` on a bad name
will now see the raise the client would, where through revision 25 it saw a silent return. A suite
that goes red on re-vendoring this revision has found a real defect: the addon code it drives raises a
raw Lua error in the client on the same input.

| Call | Revision 25 | Revision 26, as AceDB-3.0 |
|---|---|---|
| `CopyProfile(active)` | returned | raises `Cannot have the same source and destination profiles ("<name>").` (`AceDB-3.0.lua:582`) |
| `CopyProfile(missing)` | returned | raises `Cannot copy profile "<name>" as it does not exist.` (`:586`) |
| `CopyProfile(missing, true)` | returned | resets the active profile to its defaults and fires `OnProfileCopied` with `name` — AceDB resets before it copies, and there is nothing to copy |
| `CopyProfile(existing)` | wiped the active profile and copied the source over it | the same, then fills the defaults the source lacks, as AceDB's reset-then-copy leaves them |
| `DeleteProfile(active)` | returned | raises `Cannot delete the active profile ("<name>") in an AceDBObject.` (`:532`) |
| `DeleteProfile(missing)` | returned | raises `Cannot delete profile "<name>" as it does not exist.` (`:536`) |
| `DeleteProfile(missing, true)` | returned | returns |
| `SetProfile(other)` | swapped and fired | first strips the **outgoing** profile, in place, of every value equal to its default (`:460-463`), then swaps and fires |

Every raise is at level 2, so its position names the caller rather than the kit, and the messages
are copied byte for byte from the `AceDB-3.0.lua` every consumer vendors (`:531-537` and
`:581-587`). The `SetProfile` strip models `removeDefaults`' scalar arm (a value equal to its
default is removed) and its plain-table arm (a default table is recursed into and removed if that
leaves it empty); the `"*"` and `"**"` wildcard arms and the blocker they thread are **not**
modeled, and the fake's `copyDefaults` does not expand wildcards either. A stripped outgoing profile
also shows up in `M.__svWrites()`, because the SavedVariables file changes. `OnProfileChanged` and
`OnProfileCopied` fire exactly as in revision 25; `OnProfileDeleted` is still not fired. The eight
cases are in this repo's `tests/test_mock_record.lua` (review findings `AbsorbTracker-R-06` and
`PartyFrameEnhanced-R-09`).

### A third new file: `mock_events.lua`, and a behavioral change to frame registration

`mock_events.lua` is not a peel. It carries three client surfaces the kit did not model, and
`mock_base.lua` loads it from its own folder the way it loads `mock_record.lua` (the loader now
takes the file name), so a copy of the kit missing it **raises at load**. `mock_base.lua` grows by
two lines, to 1448: the load, the per-frame hook and the install call, less one line the shared
loader saved.

| Name | Since | Meaning |
|---|---|---|
| `M.EventRegistry` | **26** | A recording fake of Blizzard's global CallbackRegistry: `RegisterCallback(event, func, owner)`, `UnregisterCallback(event, owner)` and `TriggerEvent(event, ...)`. One callback per (event, owner), so a second registration **replaces** the first. A function callback is invoked as `func(owner, ...)`, in registration order. An owner left nil is given a generated numeric id, which `RegisterCallback` returns; a numeric owner passed in raises `RegisterCallback 'owner' as number is reserved internally.`, a non-string event and a non-function `func` raise CallbackRegistry's own messages, and `UnregisterCallback` with no owner raises `UnregisterCallback 'owner' is required.`. The closure form (extra arguments after `owner`) is **not modeled** and raises, rather than silently dropping the bound arguments. A callback's error propagates, where the client's securecallfunction would report it. Fresh per build. |
| `M.__registrations()` kind `"callback"` | **26** | Every live `EventRegistry` callback is a row `{ kind = "callback", event = <name>, owner = <owner> }`, after every other kind, ordered by event name and then registration order. The row carries **no `target`**: a suite that renders rows reads `r.target or r.owner`. `UnregisterCallback` removes the row. `M.__fire` does not dispatch to callbacks; `M.EventRegistry:TriggerEvent` does. |
| frame `RegisterEvent` / `RegisterUnitEvent` on a name in `M.__badEvents` | **26** | Raises `Attempt to register unknown event "<NAME>"` — the message the AceEvent path has raised since revision 17 — at level 2, so the position names the caller. Nothing is recorded, because the client registers nothing. `M.__badEvents` is read at call time. Applies to every frame the build tracks, `M.__stubFrame()`'s included. |
| `M.C_EventUtils.IsEventValid(name)` | **26** | `false` for a name in `M.__badEvents`, `true` otherwise, read at call time. A suite models an older client, which has no `C_EventUtils`, with `M.C_EventUtils = nil`; nothing in the kit reads it, so the frame path still raises. |

**Behavioral, in two places.** A consumer suite that surveys `M.__registrations()` now sees a
surviving `EventRegistry` callback — which is the point: through revision 25 a stand-down suite could
not see an `EditMode.Exit` callback left behind on disable (review finding
`PartyFrameEnhanced-R-10`). And a suite that sets `M.__badEvents` now sees a raw frame registration
raise where it used to record the name. A consumer whose own mock defines `EventRegistry` or
`C_EventUtils` overwrites the kit's and is unaffected until it drops its own. The fourteen cases are
in this repo's `tests/test_mock_events.lua`.

### A behavioral flip: a new frame starts shown

| Call | Revision 25 | Revision 26, as the client |
|---|---|---|
| `CreateFrame(...)`, then `IsShown()` / `IsVisible()` | `false` until `Show()` | `true` until `Hide()` |
| `M.__shownFrames()` right after a build | only the frames something called `Show()` on | every frame the build made that nothing hid |
| `M.GameTooltip`, `M.SettingsPanel`, `M.StopwatchFrame` | hidden | hidden: the build hides them, because the client's own windows start closed |

In the client, `CreateFrame` hands back a frame that is shown: a container stays on screen until
the code that built it hides it. Through revision 25 every kit frame started hidden (`__shown =
false` in `mock_base.lua`'s frame stub), which is the convenient default fidelity rule 5 forbids.
It let a frame production built and never hid pass every "nothing is on screen" assertion (review
finding `PartyFrameEnhanced-A-02`). `Show`, `Hide`, `SetShown` and `IsShown` behave as before;
`IsVisible` still answers the frame's own flag and does not walk its parents. The change applies to
every tracked frame, `M.__stubFrame()`'s and the AceGUI fake's widget frames included, since both
are built by the same stub. `UIParent` and `DEFAULT_CHAT_FRAME` are now shown, as they are in the
client. `mock_base.lua` is 1452 lines with the change.

**A consumer note.** A stand-down suite that takes an `F_on` baseline from `M.__shownFrames()`
**now sees the addon's container frames** (holders, fade frames, anchors), which it could not see
before. A suite that goes red on re-vendoring has two honest answers. Either the addon leaves a
frame shown where it should have hidden it, which is a real defect, or the suite's setup owes the
case the `Hide()` the production path performs. Weakening the assertion is not one of them. This
repo had one such case, `tests/test_options_idsuggest.lua`'s "a box that left before the pause
shows nothing", which fired `OnHide` at a frame nothing had hidden; its setup now hides the frame
first, as the client does when the panel goes away. The red-first case is
`tests/test_mock_base.lua`'s "a new frame is shown until hidden, as in the client". A consumer whose
own mock builds its frames without the kit's stub is unaffected until it moves onto the stub.

Everything else below is revision 25's contract, carried forward unchanged.

## The declaration is the pair (basename, directory)

Through revision 24, `Kit.assertSuiteInventory` keyed a declaration by **basename**. A bare
`"test_prose"` in the suites list therefore wired the repo's own `tests/test_prose.lua` **and**
counted as covering `tests/_kit/test_prose.lua`, which was loading nothing. Six of the twelve repos
in the collection were in exactly that state, each running a local copy of a gate the kit also
ships, and the repo's own record — the suite list, `docs/test-cases.md`, the pass count — went on
asserting the rule was covered.

From this revision the key is the pair **(directory, basename)**. `{ name = "test_prose", dir =
"tests/_kit/" }` and `"test_prose"` are two different declarations naming two different files, and
the inventory reports three shapes rather than one:

| Shape | What it is | How it is reported |
|---|---|---|
| **Collision** | the repo declares the basename bare **and** has a file of that name in `tests/`, while the kit ships one too | **Failure**, naming **both** paths and which one is running, with the two ways out spelled in the message |
| **Hole** | a suite in `tests/_kit/` that no declaration references, with no local twin | **Failure**, naming the entry to add |
| **Decline** | either of the above, with a `## Documented deviations` row behind it | **One skip**, carrying the row's own reason, in the run's output and in `docs/test-cases.md` |

The carve-out reaches the collision as well as the general form. `localization-§5` grants a repo
carrying its own prose gate the right to wire one or the other, never both — and every repo that
exercise would apply to is a collision, so a carve-out that reached only the general form would
leave that permission unexercisable by exactly the repos it was written for.

### What a decline row has to say

A decline is read off the repository's register, in `docs/ARCHITECTURE.md` or the root `CLAUDE.md`
(`REGISTER_HOSTS`), and **both** halves are required:

- the **Rule** cell names the rule the gate serves — `KIT_GATE_RULE` maps `test_prose` to
  `localization-5`, `test_eol` to `line-endings-7` and `test_layout_cap` to `layout-1`, and
  `normRule` reduces `localization-§5`, `` `localization-5` `` and `localization-5` to one key, so a
  document's spelling and a Lua table's spelling are the same key;
- the **row** names the kit's own path, `tests/_kit/<suite>`, with or without the extension.

Neither half can be relaxed, and this library is the proof of both. Its register carries two
`localization-§5` rows about third-party API identifiers, so keying on the rule alone would have
switched the prose gate off without ever mentioning it; both of those rows go on to mention
`tests/test_prose.lua` in passing, so matching the bare basename would have done the same. A row
that declines a gate says which copy it is declining. This is narrower than the standard's wording,
deliberately: the alternative hands six repositories a waiver none of them wrote.

Only the rows **directly** under `## Documented deviations` are read, ending at the register's first
subheading of any level. `layout-§1` nests the over-cap census inside that register, and a census row
is not a deviation row.

### Declared skips, and the absent-suite error

The decline registers as `Kit.test(name, nil, reason)` — the same SKIP status `Kit.skip` produces,
never folded into `passed`, never touching the exit code, and visible in `--list`, so the decline
reaches `docs/test-cases.md`, which is where the repo's record was previously claiming coverage it
did not have. It is registered **once** however many times the inventory is asserted.

`loadSuites` is unchanged in contract and slightly more helpful in its message: a listed-but-absent
suite still raises, naming the path and the declaration's position, and now adds *`tests/_kit/<name>.lua`
DOES exist, so this entry wants `{ name = …, dir = "tests/_kit/" }`* when that is what happened. A
`pending` entry with no file still registers a skip carrying its reason; a `pending` entry whose file
**does** exist still raises.

New internals, for suites that drive the inventory directly: `Kit.__loadSuites`, `Kit.__deviationRows`,
`Kit.__declineFor`, `Kit.__kitGateRule`, `Kit.__normDir`.

### One spelling per directory

A pair key is only a key if both halves are spelled the same way, and they are written by
different hands: the declaration's `dir` is typed into a suites list, while the runner's `dir` is
composed. Three runners in the collection resolve their own root out of `arg[0]` and fall back to
`"."`, so the same directory reaches the gate as `./tests/_kit/` from one side and as the literal
`tests/_kit/` — the form `testing-§9` prescribes — from the other. Two of them, KickCD and
MultiMeters, mix both spellings inside a single suites list.

Every directory that becomes a key or a comparand is therefore reduced to one spelling first, at
the one point each side enters the gate: `//` collapses to `/`, a leading `./` is stripped however
many times it appears, an interior `/./` is removed, exactly one trailing `/` is added, and the
working directory comes back as `./` rather than as the empty string (`dir` is both a prefix to
concatenate and an argument to a directory listing, and `""` would serve the first and fail the
second). An empty input stays empty, which is *no directory given* rather than *here*.

Normalization is **lexical, not resolved**, and that is a choice. `..` is left in place, because
collapsing `a/../b` is wrong the moment `a` is a symlink; a backslash is left alone because it is
a legal character in a POSIX filename. Both sides get the same treatment, so identical spellings
still match and two spellings that differ across a `..` are simply not claimed to be recognized.
Resolving file identity would need `realpath` or a subprocess per comparison, is unavailable on
the cmd.exe listing fallback the framework already carries, and would follow symlinks the runner's
own `dir` does not.

### The two sides are read against each other

Normalization folds the spellings **one hand** produces. It does not fold the spellings **two
hands** produce, and revision 25's first fix stopped there. KickCD and MultiMeters each take a
root from `arg[0]` with a `"."` fallback, hand `Kit.run` `root .. "/tests/"`, and then declare
one kit suite as `root .. "/tests/_kit/"` and the next as a bare `"tests/_kit/"`. Both entries
are correct. From the repository root the fallback makes the root `"."` and normalization folds
them together; invoked **by path** from any other working directory the root is absolute, the
relative entry keys against a different string from the very directory it names, and the gate
reports one correctly wired suite as both *declared but not on disk* and *arrived with the kit
but is not declared*, aborting before a case runs.

`resolveDir(entryDir, runnerDir)` therefore normalizes both sides and then reads them against
each other, at the two points a declaration becomes a key or a comparand:

| Entry | Runner | Result |
|---|---|---|
| relative | absolute | the entry takes `rootOf(runnerDir)` — the root it was written against |
| absolute | relative | the entry is cut back at the **last** occurrence of the runner's own directory inside it, so a checkout that itself lives under a `tests/` cuts in the right place |
| absolute | absolute | left as `normDir` produced it |
| relative | relative | left as `normDir` produced it |
| absolute, sharing no anchor with the runner | either | returned untouched — an invented relationship is worse than no relationship |
| absent | either | the runner's own directory |

`Kit.__resolveDir` and `Kit.__adviceDir` are exposed for the kit's own self-tests and are not
part of the consumer surface.

### A remedy is advice about a source line

Every remedy the inventory prints hands over a `{ name = ..., dir = ... }` to paste into a suites
list, and through the first fix each interpolated the directory the gate had **resolved**: under
a runner rooted at `arg[0]`, invoked from elsewhere, that read
`dir = "/home/someone/GIT/KickCD/tests/_kit/"`. An engineer who follows a remedy literally would
then have hard-coded one machine's checkout into a file every other checkout runs.

`adviceDir(kitDir, root)` separates the two. Under a relative runner the resolved spelling already
is the source spelling, and it is returned with an empty note. Under an absolute runner the gate
prints the repo-relative directory plus the instruction to build it from the same root expression
the runner already passes to `Kit.run` — the one thing the kit knows is right, because `Kit.run`
was handed its value. The resolved path is still printed, as a **diagnostic** saying where the
file is, never as advice.

The declined-gate case's **name** had the same defect and it reached further: the name is written
into `docs/test-cases.md`, a generated file that is committed, so it said one thing when the
runner ran from the repository root and another when a wrapper invoked it by path. The name is now
the root-relative `tests/_kit/<suite>.lua`. **The dedupe key stays the resolved path**: the key
has to tell two *repositories* apart inside one process, and `tests/_kit/test_prose` is the same
string in all of them.

### Known, not fixed

`renderInventory`, `countIn` and `currentSuite` key cases on the **bare basename**, so a
repository declaring both `"test_prose"` and `{ name = "test_prose", dir = "tests/_kit/" }` — a
state the inventory permits and only advises against — gets a `--list` where both groups print the
union and the Totals rows double-count. Fixing it changes the `--list` grouping key and therefore
every repository's `docs/test-cases.md`, so it is a revision of its own.

**How all of this was found is worth recording.** Written without normalization, the pair key
reported a **collision** against two repositories that had done exactly what the rule asks, with a
remedy that told them to delete a vendored file. It failed from `Kit.run`, so the whole suite
aborted, no case ran, and `--list` aborted with it — the repository could not even regenerate
`docs/test-cases.md`. The kit's own suite was **green throughout**, because this library spells
its `dir` one way on both sides. The two-sided defect above survived that first fix for exactly
the same reason and was found on the second consumer drive. **A kit's own suite structurally
cannot make this check**: a pass in this repository has to be driven in a consumer tree before it
means anything.

## `test_layout_cap.lua` — the cap gate (`layout-§1`)

`layout-§1` caps every **authored** `.lua` file a repository tracks at 1500 lines, and requires the
disposition of each breach to be recorded under a `Files over the 1500-line cap` heading whose
parent is fixed: **under `## Documented deviations`**, in `docs/ARCHITECTURE.md` or, in a Ka0s-owned
library repo that keeps its engineer context there, the root `CLAUDE.md`. The heading's **level**
follows that register's nesting, so a `##` register takes a `###` census.

The gate is in the kit because the hand-written alternative was already measured: five repos wrote
their own — 232, 221, 209, 380 and 206 lines, **no two byte-identical** — and they had drifted in
the places that matter. One looked for a heading named ``Files by the `layout-§1` band`` where the
other four looked for `Files over the 1500-line cap`, so one rule was keyed to two names; that same
copy gated the 1000–1500 band the release watch list already generates. Seven addons wrote none at
all.

### What it does

It reads the tracked set from one `git ls-files -z`, drops **vendored code** (`libs/` and
`tests/_kit/` — two instances of one carve-out, not two carve-outs), counts lines on the bytes on
disk, parses the census out of the hub, and registers five cases over the repository and eight pure
self-tests over in-memory fixtures. The three assertions, and their converses:

- no authored file over the cap is **missing from the census** — the breach nothing remarks on;
- **no census row outlives its breach** — a row naming a path that no longer exists, or is no longer
  over the cap, is a decision about a file nobody has;
- every over-cap row **carries one of the three terminal states** — the issue naming the seam, the
  ratified deviation row, or the scheduled peel — **except a row marked `exempt`**, which is graded
  against the opts-borne exempt set instead.

A repo that tracks Lua and has nothing over the cap keeps the heading and writes the result under it;
an empty census is a **result**, and the gate tells a census that states *none* apart from one that
states *nothing*. It **fails rather than skips when it cannot look** — no git, no hub document, no
census under the register. A repo that tracks no authored `.lua` at all skips, with the reason said
out loud.

### `Kit.layoutCap` — the two consumer facts

A gate cannot infer that a file is generated rather than authored, loads nowhere and is excluded
from the payload; those are three repository facts no path betrays. So the exempt set arrives
through the gate's opts table, and so does the hub, set on the kit table before `Kit.run`:

```lua
Kit.layoutCap = {
  hub    = "docs/ARCHITECTURE.md",   -- the default; a Ka0s-owned library repo passes "CLAUDE.md"
  exempt = { "GlobalStrings/" },     -- a folder or an exact path; absent means no generated data
}
Kit.run{ dir = "tests/", suites = { ..., { name = "test_layout_cap", dir = "tests/_kit/" } } }
```

It rides on the kit table because a vendored suite is handed the kit and nothing else — the same
reason `test_eol.lua` and `test_prose.lua` take the kit as their chunk argument rather than reading
the exposed table by a global name that belongs to the consumer.

What the gate asserts against that set is only that the two records **agree about which paths were
exempted**: an `exempt` row names a path the set contains, and a path in the set that is over the cap
is either marked `exempt` or absent from the census — never carrying a terminal state, which is for
breaches, and a file the carve-out exempts was never in breach. Whether a given exemption is
*legitimate* is the auditor's judgment against `layout-§1`'s three conditions, and the gate neither
makes it nor pretends to. An exempt entry matching nothing is not a failure: an exemption is not a
disposition, an entry naming a deleted file hides nothing, and an entry naming the wrong file
surfaces immediately as an unremarked breach.

**A repo that wrote its own copy retires it by re-vendoring**, deleting the local file and the bare
string beside it. Keeping both is the collision above.

## `test_prose.lua` — `Kit.prose` and the generated-data carve-out

The prose gate's contract is otherwise unchanged from revision 24. What arrives here is
`localization-§5`'s third exclusion — a generated dump of the client's own strings — as an
**opts-borne exempt set**, in the same shape, with the same semantics and the same bargain as
`Kit.layoutCap.exempt` above. A reader who knows one gate knows both.

```lua
Kit.prose = { exempt = { "GlobalStrings/" } }   -- generated, loaded by nothing, not packaged
Kit.run{ dir = "tests/", suites = { ..., { name = "test_prose", dir = "tests/_kit/" } } }
```

It is an input rather than an inference because the carve-out rests on three facts **about the
repository**, none of which a path betrays: a script writes the file and a person does not edit
it; nothing loads it — no TOC line, no `dofile`, no runtime reader; and `.pkgmeta` keeps it out
of the packaged zip. It sits in `tests/run.lua` on purpose, beside `Kit.layoutCap.exempt` naming
the same folder for the same three reasons, so one fact about the repository is recorded once.

| Question | Answer |
|---|---|
| Absent `Kit.prose` | The normal case. Ten of the eleven consumers have no generated data. |
| Entry form | A tracked path, or a folder. An array, a map of path to `true`, or both. |
| Folder matching | Against `entry .. "/"`, so a sibling whose name merely **starts** with it is not swept in. |
| Globs | Not expanded. An entry that would only match through one matches nothing. |
| When it applies | The path is dropped **before it is opened**, not filtered after — the one carved-out folder in the collection is 3.6 MB across 27 files, one of them 1.6 MB, that the gate would otherwise read to say nothing. |
| A stale entry | Not a failure. The file it named is gone, so there is nothing left for it to hide — the same call `Kit.layoutCap.exempt` makes. |
| A malformed one | A failure naming the shape: `Kit.prose` that is not a table, `exempt` that is not a table, an entry that is not a string. |

**A generated file that ships is not exempt.** Inside the payload a player downloads, the third
condition fails and the spellings reach a screen, which is the one thing `localization-§5`
exists to prevent. And the carve-out is **not** a whole-file waiver by the back door: an
authored file somebody would rather not fix belongs in `tests/prose_waivers.lua`'s `waived`
table, per file **and** per word, with the reason beside it. `skipDirs` and `skipFiles` in that
file extend `localization-§5`'s own **named exclusion** list and nothing wider — and they face
the same two refusals `Kit.prose.exempt` does, so neither is the unpoliced way out. Whether an
exemption is legitimate stays the auditor's call and is never the gate's.

Blindness is now asked of the whole tracked set **before** any filtering, because once the
carve-out can remove files an empty answer has two causes with opposite meanings. `git ls-files`
reporting nothing at all is *git is unavailable or this is not a repository*; an empty set after
filtering is a separate red naming `Kit.prose.exempt` and the waiver file's `skipDirs`.

### Two of the three conditions are gated

A path betrays none of the three, but the repository root the gate already runs in answers two of
them out loud, and reading them is the difference between a carve-out and the whole-file waiver
`localization-§5` forbids. Measured on a repository in this collection: with
`Kit.prose = { exempt = { "core/WhatGroup.lua", "docs/data-flow.md", "tests/" } }` WhatGroup's
prose gate went green while silencing five real hits, two of them inside the packaged payload, and
the run printed not one word about it.

| Condition | Who enforces it | How |
|---|---|---|
| LOADED BY NOTHING | the gate, in part | Every tracked `.toc` is parsed — backslashes read as separators, `##` directives, `#` comments and blank lines dropped, each file line resolved against its own TOC's folder — and a declared narrowing covering any of those paths reddens the run. It follows no `.xml` include and no `dofile`, so the remainder stays with the auditor. |
| EXCLUDED FROM WHAT A PLAYER DOWNLOADS | the gate | The root `.pkgmeta`'s `ignore:` block alone is read: a column-zero sibling key closes it, indented comments and blank lines do not. An ignore entry covers a path exactly, by folder, or by the packager's `*`, matched on the whole path and on the basename. A narrowing no ignore line covers reddens the run. |
| GENERATED RATHER THAN AUTHORED | the auditor | Nothing in the repository root records whether a script or a person wrote the lines. Same division of labor `Kit.layoutCap.exempt` strikes. |

### One enforcement story, over both channels

A repository narrows this gate in **two** places, not one: `Kit.prose.exempt` in the runner, and
`skipDirs` / `skipFiles` in `tests/prose_waivers.lua`. Both are merged into the same exclusion sets
by `exclusionSets`, and both take files out of the same scan. The waiver file's pair is the older
and wider of the two, and it was checked against **nothing** — no TOC, no `.pkgmeta`, named by no
case — while the carve-out's refusal text offered it to a consumer it had just refused.

Every entry in all three lists is therefore a **declared narrowing**, carrying the text the
repository wrote, the list it wrote it in, and that list's own matching predicate. The two refusals
run over the lot and read identically, because the reasoning is identical: two of
`localization-§5`'s three conditions are mechanically readable from the repository root and are
gated; GENERATED RATHER THAN AUTHORED is not, and stays the auditor's.

| List | Where | Matching rule the refusal uses | Refused | Disclosed |
|---|---|---|---|---|
| `Kit.prose.exempt` | `tests/run.lua` | exact path, or folder compared as `entry .. "/"` | yes | yes |
| `skipDirs` | `tests/prose_waivers.lua` | the plain prefix `filterPaths` compares | yes | yes |
| `skipFiles` | `tests/prose_waivers.lua` | one exact key | yes | yes |
| `waived` | `tests/prose_waivers.lua` | per file **and** per word | no — it cannot hide a spelling it did not name; its SHAPE is validated | no |
| `localization-§5`'s published exclusions | this file | — | no — the baseline, identical everywhere, and `libs/` is on every TOC on purpose | no |

**Each list is refused on its own rule, never on a shared approximation.** A refusal matching more
loosely than its channel's scan would reject a narrowing that suppresses nothing; one matching more
tightly would admit a narrowing on the very file it does suppress.

**And both refusals read ONE resolved coverage set.** `coverageOf(narrowings, paths)` resolves every
entry through its own rule against the tracked authored set once — the set `filterPaths` leaves when
the repository has declared nothing — and the refusals, the disclosure and the counts all read that
one resolution. They used to resolve it apiece, and **disagreed about what they were refusing**:
`narrowingsNotIgnored` asked `.pkgmeta` about the entry **as written** while `narrowingsLoadedByToc`
asked about the paths the entry actually suppresses. For `Kit.prose.exempt` and `skipFiles` the two
coincide; for `skipDirs` they do not, because its coverage is an unanchored plain prefix
(`path:sub(1, #dir) == dir`) while `ignoreCovers` anchors on `entry .. "/"`. Measured in a throwaway
Aura Master carrying its real `.pkgmeta`, which ignores `tools`:
`skipDirs = { "docs/spell-research/", "tools" }` hid the shipped root file `tools-notes.md`, and the
run was **15 passed / 0 failed with both refusals green**.

So the packaging refusal now asks **about the entry as written AND about every tracked path it
covers**, and refuses when either is not ignored. Both arms stay: the entry arm is the deliberate
strictness about a stale entry — one covering nothing today still has to be a path the packager
would drop tomorrow — and the coverage arm closes what it left open. The refused line names the
shipped file, not only the entry:

```
tools [skipDirs in tests/prose_waivers.lua] (.pkgmeta ignores the entry, but it suppresses
1 packaged file(s) it does not name: tools-notes.md)
```

**A narrowing that covers no tracked path is refused for its SPELLING**, in a separate message,
and only where the entry arm already refused it. The problem there is the entry, not the packaging
— git writes forward slashes, with no leading `./` and no trailing `/`, and is case-sensitive — and
the same run's disclosure says truthfully that the entry suppressed nothing, so a packaging message
would contradict it. It stays red; a stale entry `.pkgmeta` **does** cover stays what it always was,
stale rather than silent, and not a failure.

**One consequence, stated rather than discovered.** A British locale file cannot be taken out by
`skipFiles`: a locale file is TOC-loaded and shipped, so both refusals reject it. `locales/enGB.lua`
is excluded by name in the kit's copy of the published list, which is where a differently-named one
belongs too — the standard publishes that list, and a repository needing another name on it amends
the standard rather than its own waiver file.

**One silence fixed on the way through.** `skipFiles` written in array form — `{ "docs/notes.md" }`
— used to be copied into the scan's lookup table key and all, leaving a numeric key no path lookup
could hit, so a consumer who wrote it excluded nothing and was told nothing. Both forms go through
the one reader now, and both are disclosed.

**And the same silence removed from `waived`, one key over.** It is the third key in that table and
it had no validation at all: a `waived` that was not a table died inside the scan with a raw Lua
error instead of the gate's own message, and either array form — `waived = { "core/Foo.lua" }`, or a
file's words written as `{ "cancel" .. "led" }` — waived **nothing** and said nothing, because the
scan looks both up by key. `validateWaived` now requires string keys, table values and string-keyed
words, and fails in the gate's voice. `waived` stays **outside** the two refusals, which is not an
oversight: it is per file **and** per word, so it cannot hide a spelling it did not name, which is
why both refusals point at it as the way out. Only its shape is policed.

**Degradation is stated, not silent.** No `.toc` — a library or documentation repository packages
no addon the client loads — and the TOC case **skips** with the reason printed. No `.toc` and no
`.pkgmeta` and the packaging case skips likewise. **A `.toc` with no `.pkgmeta` is refused**,
because the packager then ships the working tree whole.

**The narrowing discloses itself, in one line covering both channels.** A third case passes with
every declared path, the list each one came from, the file count **and the paths themselves,
grouped under the entry that suppressed each**, in its own PASS line:

```
PASS  prose: the exclusions this repository declared suppressed 3 of 148 tracked authored file(s),
      by: docs/spell-research/ [skipDirs in tests/prose_waivers.lua] (3):
      docs/spell-research/2026-09-20/ANALYSIS.md, docs/spell-research/2026-09-20/DIFF.md,
      docs/spell-research/2026-09-20/SOURCES.md
```

The paths are the half that was missing, and their absence is what made a `.pkgmeta`-blessed entry
over a shipped file read as ratified rather than as suspicious: a reader saw an entry and a number,
with nothing tying the number to a file. **The list is bounded, and says it is bounded.** Naming
every path is unaffordable where one entry suppresses hundreds — a fixture below suppresses 225 of
228 — so once the disclosure would name more than twelve paths, every entry falls back to its count
and three examples. Pretty Chat's carve-out, measured in a throwaway:

```
PASS  prose: the exclusions this repository declared suppressed 28 of 96 tracked authored file(s),
      by: GlobalStrings/ [Kit.prose.exempt in tests/run.lua] (28):
      GlobalStrings/GlobalStrings.lua, GlobalStrings/GlobalStrings_001.lua,
      GlobalStrings/GlobalStrings_002.lua, and 25 more (list bounded)
```

So a narrowing can never be invisible in a green run, whichever list supplied it — and two channels
with one disclosure between them is how the second one stops being forgotten. Its body re-measures
the **live** lists and compares them against the reading taken at load, so a suite or a waiver file
that changes between the two is caught rather than obeyed. The count is the gate's own arithmetic:
`filterPaths` run twice, once with everything the repository declared and once with
`localization-§5`'s published exclusions alone.

The three cases above register **wherever a repository declared a narrowing of either kind**, and a
list that cannot be read registers them too rather than retiring them silently. Keyed on
`Kit.prose.exempt` alone, the one consumer that narrows the gate through the waiver file and not the
runner registered none of the three. A repository that declared nothing gains the self-tests alone.

Registration is decided at load, so a narrowing that arrives **after** load - a later suite writing
`Kit.prose.exempt`, a waiver file changed mid-run - would find none of the three armed. The gate
refuses that case itself: when nothing registered at load but the live lists now narrow the scan,
it fails with *a narrowing was declared after this suite loaded, so its refusals and disclosure
never registered*. Measured in a throwaway Aura Master with its waiver file removed and a
`tools-notes.md` carrying British spellings hidden by a later suite: green before, red after.

### The self-tests

Thirteen pure self-tests ship below the gate, driving the same `filterPaths`, `resolveExempt`,
`collect`, `tocLoads`, `pkgmetaIgnores`, `ignoreCovers`, `exclusionSets`, `allNarrowings`,
`coverageOf`, `coverageSummary`, `validateWaived`, `narrowingsLoadedByToc` and
`narrowingsNotIgnored` the gate itself runs, **each over an in-memory fixture the case builds** —
here rather than only upstream, for the reason the cap gate's are: a vendored gate tested only in
the library repo is a gate that can rot in place through a re-vendor.

**Not one of them reads `Kit.prose`.** Revision 25's first draft had a self-test that restored the
live carve-out and then asserted over it, which is permanently green in this repository (it sets
no `Kit.prose`) and permanently red in the one repository the carve-out exists for. Validation is
now split into a pure `validateOptions(o)` that the self-tests drive over fixture tables, and
`options()` is `validateOptions(Kit.prose)`, exercised only by the live gate. **None of these
cases runs in this repository, which declines the suite** — which is how that defect shipped, and
why every one of them was driven in throwaway copies of PrettyChat and WhatGroup instead.

## `test_eol.lua` — a second case, over the `.gitattributes` body

`line-endings-§5` publishes two canonical `.gitattributes` bodies — **84 lines** client-bound,
**85** non-client — and `§7` asks from this revision that a repo be **diffed** against the right one
rather than read against it, as a second case in the suite that already owns the question rather
than a second suite over one rule.

The case checks that `.gitattributes` is present at root **and tracked**; that it carries exactly one
`* text=auto` pin and the one `§2` gives this repo kind; that `§3`'s `*.sh` and `*.py` carve-outs and
`§4`'s binary marks are present; and that the file matches the canonical body line for line through
that body's final line **and its terminator**. Below the body, and only there, a `§5` appendix may
carry the binary marks no extension reaches, graded against `§5`'s own five rules — delimiter exact,
single path, `binary` only, a one-line comment above each entry, nothing after.

The repo kind is decided by `§2`'s mechanical discriminator and never by a roster: a root `.toc`,
then any `.toc`, then a tracked `libs/`, then the payload folder a Ka0s-owned library repo ships
under `library-stack-§7` — a top-level folder carrying the aggregate XML named after itself with Lua
beside it. The directory a checkout sits under is the one fact a gate cannot read, so it is matched
on shape.

Both bodies are copied into the suite **verbatim**, in long-bracket strings, and are verified
programmatically against the fenced blocks in the standard. Byte-identity is terminator-relative and
cannot be otherwise: `§5` prints the bodies LF, a CRLF-pinned repo holds the same body CRLF, and a
literal byte compare would fail twelve correct repositories. The gate compares the text and leaves
the terminator to case one, which asks that question over the whole tracked set with
`.gitattributes` in it.

Blind is red in both cases: no `io.popen`, no git, no tracked set, no readable `.gitattributes`.

## The automated-test runner — every row names its commit

`automated-tests-§4` requires each `RESULTS.md` row to carry the **commit SHA** the run measured and
whether the tree was **clean** at that SHA. Two cells arrive with this revision:

| Cell | Value | When git cannot be asked |
|---|---|---|
| `Commit` | `` `<short sha>` ``, from `git rev-parse --short HEAD` | `unknown` |
| `Tree` | `clean`, or `**dirty**` | `unknown` |

Both are **read from git and nobody types them**; the watch list's `Disposition` remains the one
authored cell in the file. A dirty row is kept and marked rather than dropped — it is an experiment,
honestly labeled — and `--release` still refuses a dirty tree, so no release row can be one.

The header widens **once**. The revision-24 header is recognized and spliced, and every row written
before the runner emitted these cells is carried forward with both cells `unknown`: not `clean`, and
not reconstructed from git archaeology. A header the runner does not recognize is left alone with a
warning, as it always was. The console prints one `widened:` line on the run that does it, and one
`record:` line every run, saying whether the newest bundle was measured at HEAD, how many commits
behind it is, that it is not an ancestor of HEAD, or that it predates this revision and records no
commit at all. That line reports and stops there: it never touches the verdict or the exit code,
because `automated-tests-§3` forbids a perf-or-provenance result failing a run.

The manifest half needed nothing. Revision 24 already emitted `"git": { "sha", "branch", "dirty" }`
beside `gates`, carrying the full sha.

## Adoption

Re-vendoring alone is not enough for two of the three suites, and that is deliberate:

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
```

then, in the consuming `tests/run.lua`:

- add `{ name = "test_layout_cap", dir = "tests/_kit/" }`, and **delete** any local
  `tests/test_layout_cap.lua` and the bare string that wired it;
- set `Kit.layoutCap` before `Kit.run` — the hub if it is not `docs/ARCHITECTURE.md`, the exempt set
  if the repo has generated data;
- for `test_prose`, either change the bare entry to `{ name = "test_prose", dir = "tests/_kit/" }`
  and delete the local file, or write the decline row into the register. The inventory fails the run
  until one of the two happens; if the local copy being retired named a generated folder in its own
  skip list, that folder moves to `Kit.prose = { exempt = { ... } }` — a repository must not lose a
  carve-out it had by adopting the shipped gate;
- nothing for `test_eol`'s second case, and nothing for the runner's two cells.

`docs/automated-tests/RESULTS.md` is rewritten whole on the next run, as it is on every run, and that
run's diff touches every line because the table grew two columns. It is a one-time cost and the
console announces it. **Nothing in that file needs hand-editing, and nothing may be**: a maintainer
who types a sha into an old row has invented the second authored cell `§4` forbids.
