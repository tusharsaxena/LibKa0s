# `LibKa0s-Options-1.0` — version 24.30.3.7.4

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Options surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Options-1.0` |
| Files and minors | `Options.lua` **24** · `OptionsWidgets.lua` **30** · `OptionsTabs.lua` **3** · `OptionsCompose.lua` **7** · `OptionsScroll.lua` **4** |
| Version key | `<Options>.<OptionsWidgets>.<OptionsTabs>.<OptionsCompose>.<OptionsScroll>`, in load order — the same five numbers `lib.MODULES` reports. |
| Shipped in | v1.56.0 |
| Status | **Current** |
| Supersedes | [version 23.30.3.7.3](./version-23.30.3.7.3-docs.md) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`); `OptionsWidgets.lua` additionally requires `LibKa0s-Pool-1.0` minor ≥ 1 (`NEEDS_POOL = 1`), since 14.14.3.3. `O.IdList` uses `LibKa0s-Item-1.0`'s `LoadItem` when it is present, looked up at call time; it is not a floor, and without it an uncached item stays unnamed. `O.IdInput`'s pre-warm and name lookup use it too, and fall back to `C_Item.RequestLoadItemDataByID` with `C_Timer.After` without it. |
| Confirm in-game | `LibStub("LibKa0s-Options-1.0").MODULES` → `{ Options = 24, OptionsWidgets = 30, OptionsTabs = 3, OptionsCompose = 7, OptionsScroll = 4 }` |

`Since` in the tables below names the **file and minor** in which the member first appeared — `O21`
for `Options.lua` minor 21, `O22` for `Options.lua` minor 22, `O23` for `Options.lua` minor 23, `O24` for `Options.lua` minor 24, `W20` for `OptionsWidgets.lua` minor 20, `W21` for `OptionsWidgets.lua`
minor 21, `W22` for `OptionsWidgets.lua` minor 22, `W23` for `OptionsWidgets.lua` minor 23, `W24` for `OptionsWidgets.lua` minor 24, `W25` for `OptionsWidgets.lua` minor 25, `W26` for `OptionsWidgets.lua` minor 26, `W27` for `OptionsWidgets.lua` minor 27, `W28` for `OptionsWidgets.lua` minor 28, `W29` for `OptionsWidgets.lua` minor 29, `W30` for `OptionsWidgets.lua` minor 30, `T1` for `OptionsTabs.lua` minor 1, `T2` for `OptionsTabs.lua` minor 2, `T3` for `OptionsTabs.lua` minor 3, `C7` for `OptionsCompose.lua` minor 7, `S1` for
`OptionsScroll.lua` minor 1, `S4` for `OptionsScroll.lua` minor 4. **A `W`
citation on a chrome member is not stale**: `O.TabStrip`, `O.PageBanner`, `O.PageHeader`,
`O.SubTabStrip` and the four geometry seams were `OptionsWidgets.lua`'s until 21.20.1.7.3 and are
`OptionsTabs.lua`'s from it, with no change to what any of them does. The minor that introduced a
member is a fact about when a consumer got it, not about which file holds it today. Minors 1 and 2 of each file were never tagged, so
`O1`/`W1`/`S1` means "present for as long as any consumer could have had this major".

## What changed at this version

Two changes share this version: `CreateOptionsPanel` parks in combat and `OpenOptionsPanel` answers
a boolean (below), and the font preload moves out of the shell (after them).

**`CreateOptionsPanel` parks in combat and replays itself (O24).** Called under
`InCombatLockdown()`, it registers nothing -- no canvas, no category, no page builder runs. It
**parks** the request with the library and returns. When combat ends (`PLAYER_REGEN_ENABLED`) the
library replays the parked call once, which registers the category and builds every queued page
exactly as an out-of-combat call would have. The replay does not go through the host: it runs
whatever the host's stand-down state, so an addon disabled or stood down mid-combat still gets its
category when the fight ends (ConsumableMaster's hand-rolled park lost it there,
`ConsumableMaster-R-03`). A second `CreateOptionsPanel` while the first is parked is a no-op, so the
replay registers one category, not two. `OpenOptionsPanel` while parked answers `nil` -- there is no
category yet. A `/reload` or login taken in combat therefore shows the addon in the AddOns sidebar
only once combat ends; out of combat nothing changes. **No instance member is added** (the original
proposal's `ReplayPending` is not needed: the library drains its own park), so a degradation stub
does not move and the member manifest is unchanged.

**The park's private frame.** One frame for the process, `lib.__parkFrame`, created on the first
park, hidden, and kept across a LibStub upgrade. It is **not** the page lock's `lib.__combatFrame`.
It is registered for `PLAYER_REGEN_ENABLED` **only while something is parked**, and let go of before
the replay runs, so a host with nothing parked owns no registration from it and a stand-down suite
that fires every event at every frame reaches it with nothing to do. Its `OnEvent` looks
`lib.__OnParkEvent` up at call time, so the newest vendored copy drains what an older one parked.
Where no `CreateFrame` exists to listen with, the call registers at once, as before O24. See
[the park's library-level names](#the-registration-parks-library-level-names-o24).

**`OpenOptionsPanel` answers what happened (O24).** `true` when the category was opened; `false`
when it was refused in combat (the gray `COMBAT_REFUSED` line is still printed); `nil` when there is
no category to open -- `CreateOptionsPanel` has not registered one (not yet run, parked, or the
client lacks the canvas API) or the client has no `Settings.OpenToCategory`. Through O23 it returned
nothing in every case, so a host that ignored the result is unaffected. It still never defers and
replays an **open** (options-ui-§2): only the registration is parked.

**The font preload moves out of the shell (O24, S4).** `Options.lua` 23 -> **24** and
`OptionsScroll.lua` 3 -> **4**; `OptionsWidgets.lua`, `OptionsTabs.lua` and `OptionsCompose.lua` do
not move. **The move adds, removes or repurposes no member, moves no descriptor or row field, and
leaves nothing to adopt** -- the member manifest at `members-24.30.3.7.4.json` is identical to
23.30.3.7.3's apart from the version key.

**What moved.** The whole font preload of **O17** -- the library-level state `lib.__fontPreload`,
the preload frame, the per-path load, the one late-registration subscription and
[`lib.__PreloadFonts`](#lib__preloadfontslsm--number) itself -- is now defined at the foot of
`OptionsScroll.lua` instead of in `Options.lua`, byte-for-byte the same code. It moved to keep the
shell under `layout-§1`'s 1500-line cap: `Options.lua` was 1476 lines at O23 and 1376 after the
move, before the park above was added.
`OptionsScroll.lua` was chosen because the preload, like the scrollbar patch already there, is
stateless lib-level code with no instance half. `lib.__PatchLSM30Border` stays in the shell.

**What did not move.** The two triggers are still the shell's, in `lib:New`: `O.SetRenderer`'s
OnShow after its combat refusal, and the OnShow hook `O.CreatePanel` installs. Both, and the
late-registration callback, look `lib.__PreloadFonts` up on `lib` at call time and do nothing when
it is not a function, as they did at O17 -- so a **partial vendored copy missing
`OptionsScroll.lua`** shows every page with no preload (O16's behavior: a font dropdown's first open
may draw blank rows) and never an error. A partial copy missing that file has lost the
always-shown scrollbar as well, which is the larger symptom.

**Across vendored copies.** `OptionsScroll.lua`'s attach guard re-runs whenever the shell underneath
it changed or its own minor rises, so the winning shell always carries the winning copy's preload.
A session that loads a 23.30.3.7.3 copy first and a 24.30.3.7.4 copy second runs the older copy's
preload (defined by its shell) until the newer `OptionsScroll.lua` attaches and replaces it; the
state in `lib.__fontPreload` is shared across both, so no face loads twice.

## Previously, at 23.30.3.7.3

**The Add button stops overhanging the box beside it (W30).** `OptionsWidgets.lua` 29 -> **30**;
every other file of the major is unchanged, and the member manifest is identical to W29's apart
from the minor and the version key. **No new member, no new field, and nothing to adopt** — every
consumer of `O.IdInput` gets it by re-vendoring.

**What was wrong, and what was not.** The owner reported the Add button sitting *"slightly higher"*
than the edit box beside it. It was not higher. The two were already centered on each other and
always had been: AceGUI's labeled `EditBox` publishes `self.alignoffset = 30` (`SetLabel` in
`widgets/AceGUIWidget-EditBox.lua`) and Flow anchors the next widget by
`frameoffset - lastframeoffset`, which puts their middles on one line. Measured off the screenshot:
box 20px tall with its centre at y 43, button 24px with its centre at y 42 — **one pixel apart, and
four pixels different in height**.

**So the fix is the height, not the anchor.** `InputBoxTemplate` draws its border art **20** tall;
AceGUI's `Button` is a flat `SetHeight(24)`. Centered, a 24 against a 20 overhangs 2px at each end —
and the two overhangs do not read alike, because the top one sits against the row's gold caption
and the bottom one against empty dark. That asymmetry is what reads as *higher*. `O.IdInput` now
sets the button to `ID_ADD_H = 20`, Blizzard's own number for that border art. The centering stays
AceGUI's.

**Previously, at 23.29.3.7.3 — the help mark grows up (W29).** `OptionsWidgets.lua` 28 -> **29**; every other file of the major
is unchanged, and the member manifest is identical to W28's apart from the minor and the version
key. One **regression fix**, one **art change**, and one **new optional field**.

**THE REGRESSION, and it was this library's.** W28 reserved `ID_HELP_REL = 0.05` of the row for a
mark whose frame is ABSOLUTE, so `entryMinContent`'s mark floor came out at
`cols * 18 / 0.05` = **720px of content at two columns**. The `ID_COLUMNS_MAX` block calls 584px
"comfortably inside every settings canvas this collection draws a page into" and 876px "past a
settings canvas rather than near it" -- 720 is between them, so `fitIdColumns` correctly dropped
**every** helped list to one column. A host that adopted `help` silently lost its second column.
The suite could not see it: `listBench` draws into 1000px, which pays for 720.

The reserve is now **0.09**, derived rather than picked: it is the smallest hundredth at which the
mark's own floor stops binding before the label floor the row already pays. Adopting `help` still
lifts an icon-style two-column list's floor from **520px to 561px** of content -- that is the label
floor rising as the name gives up its share, it is unavoidable, and it is stated here rather than
buried. 561 is still under the 584 the block calls comfortable. **A helped DEFAULT-style (Remove
button) list at two columns wants ~665px and will fall back to one column on a normal canvas: a
host that wants help and two columns should draw the X.**

**The glyph is the library's own.** W28 fell back to the client's `InformationIcon` at 8px art,
which reads as half-drawn beside the two 16px textures an entry already carries. The default is now
`media/icons/info.tga` -- the icon this library ships and ConsumableMaster already draws -- at
**14px of art in a 24px frame** (art + 10, the same rule `ID_REMOVE_HIT` is built on).

`lib.DRAG_HANDLE.HELP_HIT` stays 18, and the claim that the two marks share their numbers is
retired rather than quietly broken: 18 is the drag strip's **full height**, a ceiling a settings row
does not have.

**Reaching the art across a major boundary.** `Media.Icon` needs the consuming addon's name, and a
vendored copy cannot know its own folder. So the **Options descriptor takes an optional
`addonName`**, resolved once per instance through `LibStub("LibKa0s-Media-1.0", true)` at call time
-- the same shape `Core.MakeCloseButton` and DebugLog already use. Nothing is copied across the
seam, so Options stays vendorable without Media. **Without Media, without `addonName`, or with a
name Media does not know, the mark falls back to the client's information glyph at the new size** --
what W28 drew. `spec.helpIcon` still wins over everything.

**A severity, host-supplied, on the help table itself.** The library reads the lines as opaque
strings and cannot know that one means "this can never match" and another means "also in two other
lists". So the host says, as a `level` field on the table carrying the lines:

    entry.help = { level = "blocked", "Never matches -- this is the cast. Its aura is 119611." }

`"blocked"` tints the mark red, `"info"` leaves it the resting gold, and an entry with nothing to
say keeps the dimmed mark and no tooltip. An unknown level reads as `"info"` rather than as nothing.

**The level rides the LINES rather than a second `entry.helpLevel` beside them**, and that is
deliberate: one field is one host call site, a severity in a second field is a second thing to keep
in step, and there is then no entry whose level says `"blocked"` while its lines were cleared.

**Backward compatible.** An entry passing a plain string or a list of strings, as W28 documented,
draws exactly as it did -- the table carries no `level`, which reads as `"info"`.

## Previously, at 23.28.3.7.3

**A per-entry help mark, and every row lights (W28).** `OptionsWidgets.lua` 27 -> **28**; every
other file of the major is unchanged. No member is added, removed or repurposed -- the manifest at
`members-23.28.3.7.3.json` is identical to W27's apart from the minor and the version key -- but
there are **three new optional spec fields** and **one behaviour change that needs no adoption**.

**`entry.help` -- a "?" between the delete control and the name.** A string, or a list of strings,
shown as a tooltip whose title is the entry's own name. The alternative already here is `note`, a
full-width second line -- and a second line cannot share a Flow row, so a noted entry takes a row of
its own and punches a hole in a multi-column grid. A host with something to say about MANY entries
had to choose between saying it and keeping its columns. The mark says it for a fixed 18px.

- **Asked once per LIST, not per entry.** A list where nothing carries `help` draws no marks, claims
  no width for them, and is byte-identical to what W27 drew. A list that uses it at all gives
  **every** entry a mark, because a column that appears and disappears down the list is not a
  column. An entry with nothing to say wears a **dimmed** mark and registers no hover at all, so it
  cannot answer a hover with a blank tooltip.
- **`spec.helpIcon`** picks the art, falling back to the client's own information glyph -- the same
  last rung `lib.DragHandle`'s mark uses.
- **The numbers are the drag handle's**: 8px of art in an 18px frame, the same gold and the same
  brighten. A player meets both marks in one panel, and two "?" controls of different sizes reads as
  one of them being wrong. They are restated in `OptionsWidgets.lua` rather than read across,
  because `lib.DRAG_HANDLE` belongs to the **Widgets** major and this is the **Options** major's; a
  cross-major read would make one vendorable without the other.
- **The column floor covers the mark's frame.** It is absolute, like the X's, so `cols` of them cost
  a flat `cols * 18px` out of the fraction the names gave up. Without that, `columns`' fit would
  pass a width that pays for the X and not for the mark.

**Every row lights under the cursor now**, not only at more than one column. **Nothing to adopt --
this one is automatic.** The old rule reasoned that a one-column tooltip already hangs off the name
and needs no second owner; but the lit name is also the feedback that says which row the cursor is
on, and one column wants that as much as two. It also left a **noted** entry -- which is drawn at
one column even inside a two-column list -- as the only unlit row on the page. Word wrap is still
turned off only above one column.

**`kind.suggestTag(id)` -- a host's word on a suggestion row**, after the gray id. `rank` beside it
is the library's own answer about an id (a spell's rank, an item's quality) and a host cannot supply
one; this is the other half, something the host knows and the library cannot. The case it was
written for: an id can be a spell's **cast** rather than the aura it applies, which matches nothing,
and the host knew that before the player picked the row and could only say so afterwards. A tag
turns a correction into a choice. It is short, uncolored by the library, and never wrapped,
truncated or measured -- a host that writes a sentence there gets a sentence running off its row.

### Previously, at 23.27.3.7.3

**Four O.IdList follow-ups, none of them a surface change (W27).** `OptionsWidgets.lua` 26 -> **27**;
every other file of the major is unchanged. No member is added, removed or repurposed -- the member
manifest at `members-23.27.3.7.3.json` is byte-identical to W26's apart from the minor and the
version key -- and no host has anything to adopt. These are LibKa0s #34's findings 1, 3, 4 and 5.

**The X lights its whole hit area (finding 1).** In `removeStyle = "icon"` the delete control's
frame is `ID_REMOVE_HIT` (26px) around 16px of art, but AceGUI's Icon anchors its highlight to the
IMAGE while the FRAME is what takes the click -- so the 5px ring this list deliberately buys was
live and unlit, on a control that deletes the row. The highlight is now anchored to the frame, and
put back on the image when AceGUI pools the widget. A client that stops building that texture, or a
harness whose fake has no regions, is unaffected: the walk finds nothing and the X draws as it did.

**The column count is fitted to the canvas (finding 4).** The X's frame is absolute, so the icon
style spends 52px of every row before a relative width is multiplied out, and AceGUI's Flow broke
the trailing gutter onto a row of its own below roughly 520px of content -- icons stacked over
wrapped names, with nothing reporting it. `columns` is now the count the host asks for as a MAXIMUM:
the draw measures the content width and drops a column at a time until the count is payable.
**A width that cannot be measured changes nothing**, so a list on a canvas that answers no geometry
draws exactly the count it was given, as before. The fit is taken once, at draw time; a canvas
dragged narrower afterwards is not re-fitted, because nothing re-runs the page builder on a resize.

**An entry label's markers no longer ride into the pool (finding 3).** `__wordWrap` and
`__highlight` are keys this library invents, and `AceGUI:Release` nils only a fixed list of its own
fields, so both survived into the pool and could be read by the next consumer of that label. They
are cleared on release now, from the single `OnRelease` that also hands the FontString back --
single because `SetCallback` stores one handler per event name, so a second registration would
silently replace the first. Nothing observable to a host changes; the markers exist for test
harnesses.

**Finding 5** removed an unsourced pixel figure from two comments, and **finding 2** (the
multi-column tooltip's anchor) was closed as no-change, with the reasoning recorded at
`entryTooltip`.

### Previously, at 23.26.3.7.3

**A based host kind is offered its base's client ids (W26).** `OptionsWidgets.lua` 25 → **26**;
every other file of the major is unchanged. No member is added, removed or repurposed, and no kind
that does not declare a `base` renders or resolves differently than it did at W25.

A host passes its own kind table when it needs its own entry tooltip, because `O.IdList` builds that
tooltip from the kind and nothing else. Such a host says `base = "spell"` so everything else —
resolution, the drawn name, the words — still comes from the library's spell kind. Through W25 that
cost it the spellbook: the suggestion table was keyed by the library's kind **table**, a host table
is a different table, and the add box therefore suggested nothing as the player typed unless the host
listed every candidate itself. A capability was lost for wanting a tooltip, which is the wrong trade
for a library to impose.

From W26 a based host kind reads its **base's** suggestion row — the same one lookup the rank has
always gone through — so it gets:

- **the base's client source**: every item in the bags for `base = "item"`, every Spell and
  FutureSpell slot of the spellbook for `base = "spell"`, listed after the host's own `candidates()`
  exactly as the base lists them. `base = "currency"` has no client source, so it adds nothing.
- **the same shared-name check**: a name the client answers is refused as `"ambiguous"` when a
  DIFFERENT id in that source carries it too, through a based kind exactly as through the base.
- **the base's rank** on the suggestion rows, which was already so and is now read through the same
  accessor rather than a second lookup of its own.

**A host kind with no `base` still gets none of this**, which is the protection the old keying was
really after: such a kind's ids need not be the client's at all, and a list of, say, currency or
encounter ids must never be offered the spellbook. **Declaring a `base` is how a host opts in;
leaving it out is how it opts out** — there is no third setting. What a based kind still does not
get is the base's `byName`: a typed name reaches the host's `resolve` and its `candidates()`, never
`C_Spell.GetSpellInfo(name)` or `C_Item.GetItemInfoInstant(name)`, so what a host kind **resolves**
is as much its own as it ever was. Only what it is offered, and what a shared name is checked
against, now come with the base.

### Previously, at 23.25.3.7.3

**An entry may carry a `suffix` (W25): a few host-composed words drawn INSIDE its label, after the
gray `(id)` and in the same gray.** `OptionsWidgets.lua` 24 → **25**; every other file of the major
is unchanged. One optional entry field is added and nothing is removed or repurposed. A list whose
entries carry no `suffix` renders byte-for-byte what W24 rendered.

A row reads:

```
(X) [icon] Renewing Mist (119611) (also in 1)
```

- **It is bytes on a string, not a widget.** The name, the gray id and the suffix are one
  `FontString`, so a suffixed entry adds no child to its line and costs a shared row nothing —
  two suffixed entries still pair up under `columns`, at the same `0.37` each. That is the whole
  difference between this and `note`, and it is the reason both exist.
- **`note` is unchanged and is still the right answer for a sentence.** `entry.note` (W17) is a
  SECOND full-width `Label` under the name, and a noted entry still takes a full-width row of its
  own inside a multi-column list. **Reach for `note` when the thing to say is a sentence — why the
  entry is or is not in effect — and for `suffix` when it is a few words that belong to the name:
  a count, a tag, `(also in 1)`.** The two are independent: an entry carrying both keeps its
  full-width row for the note AND draws the suffix inline on the name.
- **The full story belongs in the entry's TOOLTIP**, which the host already owns. A suffix is a
  pointer, not the information; it exists so the row can say *that* there is more without spending
  a line saying what.
- **Drawn in `ID_GRAY`**, the same `|cff808080` the id wears, so the NAME stays the bright thing on
  the row and the two gray runs read as one tail.
- **Concatenated, never formatted.** The suffix is appended with `..`. It is never a `string.format`
  argument and never a `gsub` replacement, which is the same guarantee `note` gives: a `%`, a `%%`
  or a `%(` in a host string is drawn as the bytes the host wrote. A `|c` is likewise not stripped,
  so a host that colors its own suffix gets that color and a host that wants a literal pipe writes
  `||`, exactly as it must anywhere else it hands the client text.
- **Anything that is not a non-empty string draws nothing** — `nil`, `""` and a non-string all read
  as no suffix, as `note` reads. An entry that never heard of the field is untouched.
- **An entry the kind cannot name** has no gray `(id)` for the suffix to sit after; it is appended
  to `Unknown <noun> <id>` instead, in the same gray.

### The truncation order, and the character budget

At **more than one column** word wrap is off (W24) and the client truncates the tail of the string
rather than wrapping it. A suffix makes that string longer, so an entry that already overruns its
column **loses its suffix first, then its id, then the tail of its own name**. That is the right
order — the suffix is the least of the three and the tooltip still carries everything — but it is
stated here rather than left to be discovered, and it is why a host should size its suffix rather
than compose it freely.

The budget, in pixels, is exact. The label is a fraction of the CONTENT width, which is the panel's
width less 60 (see [Previously, at 23.24.3.7.3](#previously-at-2324373) for where the 60 comes from),
and an entry carrying an icon spends `ID_ICON_SIZE = 16` of its label on that icon:

| Style | cols | Label fraction | Text px at content `C` |
|---|---|---|---|
| default | 1 | `0.78` | `0.78 * C - 16` |
| default | 2 | `0.37` | `0.37 * C - 16` |
| icon | 1 | `0.90` | `0.90 * C - 16` |
| icon | 2 | `0.43` | `0.43 * C - 16` |

Turning pixels into characters needs a figure this repository does not measure and will not pretend
to: nothing here reads a font. As a **rule of thumb only**, the default label face averages roughly
`4.5px` a character across mixed-case Latin text, which makes the budget
`(fraction * C - 16) / 4.5` characters. At two columns and the `584px` content the column cap is
chosen against — the narrowest content two columns are drawn at — that is `200px`, or **about 44
characters for the name, the space, the gray `(id)` and the suffix together**. A 24-character name
with a 7-character id spends 35 of them, which leaves about 9 for a suffix, and `(also in 1)` is 11.
So at the floor a long name and a suffix do not both fit, and the suffix is what goes — which is the
order above, working as designed. A wider panel buys the difference back linearly: every extra
`100px` of content is about `8` more characters at two columns, and `17` at one.

At **one column** the name wraps and nothing is truncated at all, so the budget is a line-count
question rather than a character one.

The previous version's "What changed" section follows unchanged under
[Previously, at 23.24.3.7.3](#previously-at-2324373).

## Previously, at 23.24.3.7.3

**`O.IdList` draws in columns (W24), and one at a time is still the default.**
`OptionsWidgets.lua` 23 → **24**; every other file of the major is unchanged. One optional spec
field is added and nothing is removed or repurposed.

- **`columns` (W24)**, a whole number, packs that many entries into each Flow row, **row-major** —
  `1 2` / `3 4` / `5 6`, left to right and then wrap. It is the same full-width Flow row the
  two-column engine packs a pair of widgets into; the entries in it are ordinary entries.
- **Every relative width an entry claims is divided by the column count**, and nothing else about
  the entry changes. At two columns the name is `0.37`, the action `0.20 / 2 = 0.10` and the gutter
  after them `0.02`; in the icon style the name is `0.43`. Each entry is `0.49` of the row, so the
  pair sums to the same `0.98` a single entry held, which is the clip inset `options-ui-§8` asks
  for. The icon, the name and the gray id are laid out by the same code at every column count, so
  they line up across columns for the same reason they line up down one.
- **A gutter separates each entry from the next**, drawn at the END of every entry at more than one
  column and not at all at one. AceGUI's Flow butts its children edge to edge — a child is anchored
  `TOPLEFT` to the previous child's `TOPRIGHT` with no x offset — so without a widget in between,
  the default style reads `[name][Remove][name][Remove]` with the first *Remove* flush against the
  name it does **not** belong to. The gutter comes out of the entry's own share rather than out of
  the line, which is why each entry is still exactly `0.98 / cols`; the trailing entry's gutter is
  dead space inside the clip inset the `0.98` already leaves.
- **The icon style's X is the one width here that is not a fraction, and its frame is wider than
  its art.** The art stays `16px` of `transmog-icon-remove`; the frame is an absolute **`26px`** at
  every column count, W24 included. Absolute, because `SetRelativeWidth` is multiplied by the row
  at layout time and an AceGUI `Icon` anchors its texture TOP-centered rather than clipping it, so
  a fraction that falls under the texture does not shrink the X — it spills it over whatever is
  beside it. Wider than the art, because the entry's own spell icon is also `16px`: a frame the
  size of its art left two adjacent `16x16` textures, one of which deletes the row, and a `16px`
  click target where W23's fraction gave about `41px`. At `26` the `Icon`'s own geometry (art
  centered horizontally, hung `5px` below the frame's top, frame sized to the art plus `10`) puts
  `5px` of padding on all four sides, so **the hit area is `26x26`** and it does not move with
  `cols`. The name gives up `ID_REMOVE_REL`, now `0.08` rather than W23's `0.06`, so that reserve
  still covers the frame at two columns. **A single-column icon-style list therefore draws its X
  in a wider frame and its name at `0.90` rather than `0.92`** — the one place in W24 where a list
  that passes no `columns` is not byte-identical to W23.
- **An entry's tooltip is anchored to the ROW at more than one column.** `GameTooltip:SetOwner` is
  still called with `ANCHOR_RIGHT`; what moves is the owner. At one column the label's right edge
  *is* the list's right edge, so the tooltip lands outside the list; at two, a column-one label's
  right edge is the middle of the list and the same anchor drops the tooltip squarely over column
  two — over the entries the reader is on their way to. The row spans the full width whatever the
  count, so handing it the row is the same rule applied to the widget that still reaches the edge.
  A single-column list is anchored to the label exactly as before.
- **An odd count leaves the last row half filled.** The trailing entry sits in the left column at a
  column's width — it is not widened to fill the row, because no width here fills a row.
- **A noted entry takes a full-width row of its own** whatever the column count, drawn at the
  one-column widths. `entry.note` (W17) is a SECOND line under the name, and a Flow row cannot hold
  a wrapped second line in one column and a neighbor beside it. Anything half-packed is flushed
  ahead of it, so a noted entry never splits a pair. The note's own contract is exactly what W17
  wrote.
- **The guard still costs one ENTRY.** The per-entry `pcall` (`lib.STRINGS.ROW_FAILED`, reported
  against the entry's id) now also rolls the shared row back to the children it held before that
  entry started, so an entry that raises half-drawn takes its own widgets out with it and the entry
  beside it is untouched. With nothing else in the row, the row is dropped — which is what W16 did
  with the one line an entry had to itself — and it is `Release`d rather than simply forgotten,
  because a row the scroll never took is a row no `ReleaseChildren` will ever reach. The entries
  after a failure keep packing, so a free column is taken by the next entry that draws.
- **Out of range reads as usable, not as an error.** The value is floored and clamped into `1..2`;
  anything that is not a number reads as `1`, and a host that passes `40` by mistake gets two
  columns rather than a page of slivers.

  **Two is arithmetic, measured against a width that is a conservative choice.** Two floors bind
  the count, and it is worth being exact about which part is which.

  The **label floor is AceGUI's**. A `Label` that has been given an image moves the image ON TOP of
  the name, centered, with the name wrapped underneath, whenever the frame leaves it under 200px
  beside that image — `if (width - imagewidth) < 200`, AceGUI-3.0's `UpdateImageAnchor` in
  `widgets/AceGUIWidget-Label.lua`, which the `InteractiveLabel` an entry is drawn with hijacks
  whole. An entry's icon is 16px, so its name needs `16 + 200 = 216px` of label.

  The **X floor is this library's**. The delete control's frame is an absolute `26px`, so the names
  have to leave `cols * 26` behind after taking their `0.90` of the row — `content >= 260 * cols`.

  Both are measured against the **content** width, and that number the library does know about
  itself: a page's widgets are laid out inside the AceGUI `ScrollFrame` that `anchorScroll` anchors
  (`LibKa0s/Options.lua:877-883`), which insets it from the panel body by `L.CONTENT_LEFT` and
  `L.CONTENT_RIGHT` — `12` and `28`, declared as `PADDING_X - 4` and `PADDING_X + 12` at
  `LibKa0s/Options.lua:187-188` — and `OptionsScroll.lua`'s always-shown-scrollbar patch then takes
  a further `GUTTER` of `20` off the content width (`LibKa0s/OptionsScroll.lua:34`, forced on every
  one of these scrolls at `LibKa0s/Options.lua:929`). **Content is the panel's width less 60**, and
  the `0.98` these widths sum to is the clip inset on top of that.

  | Columns | Minimum content, default style | Minimum content, icon style | Panel it implies (default) |
  |---|---|---|---|
  | 1 | ~277px | 260px | ~337px |
  | 2 | ~584px | 520px | ~644px |
  | 3 | ~876px | 780px | ~936px |
  | 4 | ~1168px | 1040px | ~1228px |

  What is **not** derived is the panel's own width. It is whatever Blizzard's settings canvas gives
  a registered category at the player's resolution and UI scale; nothing in this library measures
  it at file scope and no figure for it appears anywhere in this repository. So the cap is a
  **conservative choice**, not a measurement: two columns want a ~644px panel, which is comfortably
  inside every canvas this collection draws a page into, and three want ~936px, which is past a
  settings canvas rather than near it. A count the width cannot pay for is not a narrower list — it
  is a column of icons stacked over wrapped names, and that is the one failure mode nothing
  reports. Two is the last count that is safe without knowing the number.

  The cap is flat rather than style-aware because `removeStyle` is the host's choice about a delete
  control, and a cap that moved with it would hand two lists of the same width two different maxima
  over a difference no player can see.
- **At more than one column a name DOES NOT wrap.** Word wrap is turned off on the name's
  `FontString`, so every entry is exactly one line tall and the two columns stay a grid. This is
  not cosmetic: AceGUI's Flow centers a row's widgets on each other by `alignoffset` —
  `frameoffset = child.alignoffset or (frameheight / 2)`, and the next child is anchored
  `frameoffset - lastframeoffset` off its neighbor's `TOPRIGHT` — so **one** name that wrapped to
  two lines in column one would push the name *and* the delete control in column two down with it.
  That is a broken grid, not an uneven row.

  **What a too-long name looks like.** The client truncates it, and truncation cuts the **tail**.
  The tail is the gray `(id)` suffix, so a name too long for its column shows part of the name and
  **no id at all**. The id is not recoverable from the row; hovering still names the spell or item
  through the kind's own tooltip, and the host still has the id in its own store. A host that would
  rather wrap than lose the id asks for one column.

  **A single-column list wraps exactly as W23 wrapped**, byte for byte: the entry has the whole
  row, a wrapped name pushes nothing sideways, and there is nothing to be gained by truncating it.
  The `FontString` is put back on release, because AceGUI pools the widget across every addon in
  the session and `Label`'s `OnAcquire` does not reset word wrap.
- **At more than one column the entry under the cursor is lit.** The tooltip hangs off the whole
  row there (see above), which means it can open a long way from the name the cursor is on with
  nothing saying which of the two entries in the row it describes. `InteractiveLabel` ships a
  `HIGHLIGHT`-layer texture over its own frame and draws nothing in it until a caller names one, so
  naming one — `Interface\QuestFrame\UI-QuestTitleHighlight`, the same art the id suggestion
  lines use — is the whole change. Nothing to restore on release: `InteractiveLabel`'s `OnAcquire`
  clears it. A single-column list lights nothing, as before; its tooltip is already beside the
  name.

**What the returned `lines` table means now.** It still has **one element per entry drawn**, in
entry order, and an entry that failed to draw still has none. At more than one column the same row
object is returned once per entry packed into it, so `lines[i]` is the row carrying the i-th drawn
entry — `#lines` counts entries, not rows, and `lines[1] == lines[2]` at two columns.

**Absent, the render is what 23.23.3.7.3 drew**: one entry per full-width row, the name at `0.78`
and the action at `0.20`, with no gutter, a wrapping name, no highlight, and the tooltip anchored
to the label as before. The one exception is the icon style, where the X's frame is now an absolute
`26px` rather than `0.06` of the row and the name takes `0.90` rather than `0.92` — see the bullet
above. No host sees anything else change until it passes `columns`.

The previous version's "What changed" section follows unchanged under
[Previously, at 23.23.3.7.3](#previously-at-2323373).

## Previously, at 23.23.3.7.3

**A patch to the combat lock (O23, T3): its footprint is zero while none of the library's pages is on
screen.** `Options.lua` 22 → **23**, `OptionsTabs.lua` 2 → **3**; nothing else moves, and no member,
descriptor field or row field is added. 22.23.2.7.3 broke seven consumers' stand-down suites
(`slash-commands-§7`), each of which counts what a stood-down addon still owns.

- **Registered only while a page is on screen.** At 22.23.2.7.3 `lib.__combatFrame` registered
  `PLAYER_REGEN_DISABLED` / `_ENABLED` at load, for good. Now the frame is created hidden and
  unregistered; a page's show registers both events (`lib.__pageShown(ctx)`, asked of the page — a
  show that did not leave the panel on screen registers nothing), and a page's hide lets go of them
  when it was the last page on screen (`lib.__pageHidden(ctx)`, from an `OnHide` hook `CreatePanel`
  now installs; `SetRenderer` replaces `OnShow` only). `lib.__syncCombatEvents()` prunes pages no
  longer on screen (`IsVisible`, else `IsShown`), registers or unregisters to match, and with none
  left clears `lib.__combatLocked`. A newer copy runs it at load, so the permanent registration a
  22.23.2.7.3 copy made is let go of.
- **The dispatcher does nothing with no page on screen.** `lib.__OnCombatEvent` (now OptionsTabs.lua's,
  beside the registration) re-syncs first and returns when no page is left, so an event fired at the
  frame anyway renders, covers and prints nothing.
- **A page shown mid-combat** — nothing was registered when combat started — is locked off
  `InCombatLockdown()`, which the predicate already asked; the registration its show makes is what
  hears `PLAYER_REGEN_ENABLED`.
- **Only a page on screen is covered.** `PLAYER_REGEN_DISABLED` covered every registered page at
  22.23.2.7.3, hidden ones included. Now a hidden page is covered by its own next show, and a page's
  hide takes its cover down.
- **The cover holds its regions** (`cover.__dim`, `cover.__line`), which were locals.

**What a host owes.** Nothing in its own code. A page on screen is watched on purpose — a stood-down
addon's settings window stays usable and locked in combat — so a stand-down suite that runs after
other suites left a settings page shown closes it first (`panel:Hide()`, and in the kit's mock, whose
`Hide` fires no script, `panel:__fire("OnHide")`).

The previous version's "What changed" section follows unchanged under
[Previously, at 22.23.2.7.3](#previously-at-2223273).

## Previously, at 22.23.2.7.3

**The combat lock (O22, W23, T2).** `Options.lua` 21 → **22**, `OptionsWidgets.lua` 22 → **23**,
`OptionsTabs.lua` 1 → **2**; `OptionsCompose.lua` and `OptionsScroll.lua` do not move. It is the Ka0s
WoW Addon Standard v2.60.0's options-ui-§2 and options-ui-§13, and the fix anti-pattern #88 records.
**No member, descriptor field or row field is added**: every new name is `__`-prefixed, so a
degradation stub carries nothing new. It is not opt-in — every host on this copy gets it.

**What 21.22.1.7.3 did, and why it had to go.** `SetRenderer`'s `OnShow`, on a page shown under
`InCombatLockdown()`, called `SettingsPanel:Close()` (else `HideUIPanel(SettingsPanel)`) and printed
`COMBAT_REFUSED`. Blizzard's AddOns sidebar reaches that `OnShow` from inside its own
`DisplayCategory → DisplayLayout → Show`, so the close ran from addon code, and Blizzard's
close-and-commit path ran tainted: `Close → ExitWithCommit → Commit → CommitBindings → SaveBindings()`
is protected (`ADDON_ACTION_BLOCKED`), then `TransitionBackOpeningPanel → ToggleGameMenu` re-entered
the half-shown panel's close until `C stack overflow`. A page already open when combat started was
never refused at all, and its writes applied.

**Nothing of Blizzard's is touched in combat.** No `SettingsPanel` method call or field read or
write, no `HideUIPanel`, `ToggleGameMenu` or `Settings.OpenToCategory`, and no hook on any of them.
`OpenOptionsPanel` keeps its own gate and its gray `COMBAT_REFUSED` line (options-ui-§2), unchanged.

**The cover.** `CreatePanel` builds one per page (`ctx.__combatCover`, T2's `O.__buildCover`), out of
combat, hidden: a plain non-secure `Frame` parented to `ctx.panel` with `SetAllPoints` — so the header
band, the chrome block and the tab strip are under it — `EnableMouse(true)`,
`EnableMouseWheel(true)` with an empty `OnMouseWheel`, a 60 % black dim and one centered gray line,
`lib.STRINGS.COMBAT_LOCKED` = *Settings are locked during combat.* It never calls
`SetPropagateKeyboardInput`. When it goes up over a page on screen its frame level is set by
`lib.__coverLevel(panel, cover)`: one above the deepest frame level under the panel (a walk of
`GetChildren`), never less than the panel's level + 100, capped at 10000. The tab buttons sit two
levels over the chrome frame they hang off, and AceGUI nests a scroll's rows several deep, so no
small fixed offset is safe.

**When it goes up.** On a page's show while locked — `SetRenderer`'s `OnShow`, and `CreatePanel`'s
own show hook for a page with no renderer — the page is covered, **not rendered**, no font is
preloaded, and a page never rendered is marked owed a render (`ctx._dirty`). At
`PLAYER_REGEN_DISABLED`, over every registered page (raised to the level above only where the page is
on screen; a hidden page raises its own when it is shown). At the same edge an AceGUI pullout left
open on one of the host's own pages is closed through `AceGUI:ClearFocus()` — only when AceGUI's
focused widget sits under one of that host's panels. A color picker is Blizzard's frame and is left
alone; its commits are refused.

**What is refused while locked.** The predicate is `lib.__IsCombatLocked()` —
`lib.__combatLocked` (set by `PLAYER_REGEN_DISABLED`, cleared by `PLAYER_REGEN_ENABLED`) or
`InCombatLockdown()`, the second covering a page shown after a `/reload` in combat. The refusal is
`O.__combatRefused()`, which answers true and prints `lib.STRINGS.COMBAT_LOCKED_NOTICE` (gray)
through the host's printer **at most once per combat per host**, the first time a locked page is
shown or refuses something.

| Refused | Where | Put back |
|---|---|---|
| A widget write (every maker, `ChoiceGrid`, a path-less row's `set`) | W23, the maker seam `write` | the `RefreshScalars` its caller already runs |
| A color commit, drag or confirm | W23 | the swatch's own refresher |
| A `SessionCheckbox` toggle | W23 | the box re-reads `spec.get()` |
| A library-drawn button (`InlineButtonPair`, so *Reset all settings*), a choice grid's link cell | W23 | — |
| An id list's add, remove or toggle | W23 (`onAdd` / `onRemove` / `onToggle`) | an add keeps its text; a toggle is reset |
| The page's Defaults — header button, the window's footer control (`panel.OnDefault`), `RestoreDefaults` | O22 | — |
| A structural re-render — `RefreshAllPanels`, `RefreshPanel(ctx, true)`, a switched section, an id list's rebuild | O22 (`renderCtx`) | the page is marked owed a render |
| A tab click, a secondary tab click | T2 (`dressTab`) | — |
| A page banner's selection | T2 | the dropdown is set back to `spec.value` |
| `SelectTab` | O22 | answers `false` |

**Not refused:** `RefreshScalars` and `RefreshPanel(ctx, false)` — refreshers only put widgets back
to stored values, which is what a refused write needs — and `RestoreAllDefaults` itself, because a
host's slash reset verb calls it and the lock covers the settings window only (options-ui-§2). Its
button on the Master controls tab is refused at the button, like every library-drawn button.

**`PLAYER_REGEN_ENABLED`.** Every cover comes down. A page on screen that is owed a render (first
shown in combat, or a structural refresh waited) renders — its Defaults button is ensured and the
font preload runs first, as on a show; a clean one runs its refreshers, so a value a slash verb or a
profile switch changed during the fight shows up. A hidden page renders on its next show. Nothing is
re-opened and nothing is replayed (options-ui-§2).

**One event frame for the process.** `lib.__combatFrame` (T2) is created once and kept across a
LibStub upgrade; it registers `PLAYER_REGEN_DISABLED` and `PLAYER_REGEN_ENABLED`, and its `OnEvent`
looks `lib.__OnCombatEvent` (O22) up on `lib` when the event arrives, so the newest copy's dispatcher
runs. Each instance registers one hook, `hook(locked)`, in the weak-keyed `lib.__combatHooks` and
holds it as `O.__combatHook`; a later minor keeps calling hooks an older one registered, so that
signature does not change.

**A host adds no combat guard of its own** on a settings page or a tab strip beside this one
(options-ui-§2, §13): a second guard is a second place for the lock to disagree with itself. A host
that wraps `SetRenderer` (WhatGroup defers the body a frame) keeps working: the wrapped `OnShow` is
still the library's, and the lock is asked first inside it.

The version before that is under [Previously, at 21.22.1.7.3](#previously-at-21221173).

## Previously, at 21.22.1.7.3

**The flow engine gains one optional row field, `shownWhen` (switched sections), and nothing else
moves.** `OptionsWidgets.lua` 21 → **22**; every other file of the major is unchanged.

- **`shownWhen = { path = <selector path>, equals = <value> | { <value>, … } }` (W22)** on a row
  draws it only while the selector holds `equals` (or any value of an `equals` list). `RenderRows`
  drops every row whose selector says otherwise **before** its group/subgroup pass, so a subsection
  whose rows are all dropped draws no heading and takes no space, and an `afterGroup` hook fires after
  its group's last **drawn** row. The selector is read the way `disabledIf` reads a path (a path-less
  row reads its own record); a read that raises reads as shown. The row stays in the schema — the
  CLI, the resets and Defaults still reach it — only the flow engine skips it.
- **The page re-renders when the selector changes.** For every row of the call whose `path` (for a
  path-less, record-backed row, its `field`) is some row's selector, `RenderRows` adds a refresher that compares the selector's value with the one the
  render drew with and, on a change, asks for **one** structural re-render of the page on the next
  frame (`C_Timer.After(0)`, coalesced per ctx, through `O.RefreshPanel(ctx, true)`, so a hidden page
  is marked dirty instead). The widget's own change, a `/<slash> set` and a Defaults press all run the
  refreshers, so all three re-render. The re-render never runs inside the changing widget's callback.
  Two selectors that change in the same frame still cost one re-render.
- **The page must declare a renderer (`O.SetRenderer`).** The re-render is the page's renderer run
  again; a page without one is refreshed by its refreshers alone, so it keeps the section it first
  drew until something renders it anew.
- **It switches subgroups, not a tabbed page's groups.** `RenderTabbedSchema` builds its tabs from
  the page's unfiltered rows, so a group every row of which is dropped still gets a tab, and that
  tab opens onto an empty page. Put the switched rows in subgroups of one group.
- **Absent, the render is byte-for-byte what 21.21.1.7.3 drew**: the row list is not copied and no
  refresher is added. A selector must be drawn in the same `RenderRows` call to be watched; a host
  that draws it elsewhere re-renders the page itself.

The version before that is under [Previously, at 21.21.1.7.3](#previously-at-21211173).

## Previously, at 21.21.1.7.3

**`O.IdList` gains one optional spec field, `removeStyle`, and nothing else moves.**
`OptionsWidgets.lua` 20 → **21**; every other file of the major is unchanged.

- **`removeStyle = "icon"` (W21)** draws a small **X** at the LEFT of every entry, before the entry's
  icon and name, in place of the right-hand *Remove* button or toggle checkbox. The X is an AceGUI
  `Icon` widget at `0.06` of the line wearing the client atlas `transmog-icon-remove` at 16px;
  the name takes `0.92`. A click calls `spec.onRemove(id)` and redraws the list exactly as *Remove*
  does. Its tooltip is the `remove` string, so a host's `strings.remove` names it. A toggle entry is
  drawn no differently under this style: a host that opts in sends no toggle entries.
- **Absent, the list is byte-for-byte what 21.20.1.7.3 drew**: the name at `0.78`, then *Remove* or
  a checkbox at `0.20`. No host sees a change until it opts in.

The previous version's "What changed" section follows unchanged under
[Previously, at 21.20.1.7.3](#previously-at-21201173).

## Previously, at 21.20.1.7.3

**The major gains a FIFTH file and no member.** `LibKa0s/OptionsTabs.lua` (**T1**) carries the
page's chrome — the tab strip, the page banner, the host's header block, the secondary strip, the
four geometry seams and the client art all four are drawn from. Every one of them was
`OptionsWidgets.lua`'s at 20.19.7.3 and behaves identically here; `Options.lua` 20 → **21** gains
one guarded attach call, `OptionsWidgets.lua` 19 → **20** loses the moved code and one guard.

**Nothing a host calls changes.** The members attach to the same instance `O`, in the same
`lib:New` return, under the same names. A host that never opens this document is unaffected, and
that is the point of doing it as a move rather than as a redesign.

**Why the file exists at all:** `layout-§1` caps an authored `.lua` at 1500 lines, and
`OptionsWidgets.lua` was 3700 (issue **#16**). The cut follows the seam that file was already built
along rather than a new one — the chrome half and the widget half never reached into each other's
module-scope locals, which is what made a 900-line move a move rather than a rewrite. The file is
**still over the cap** after it, at 2812, and its remaining seam (the id-resolution and suggestion
half) is tracked in the repo's census.

**It takes the same paired-minor guard the major's other secondary files take**, on its own
`__tabsMinor` plus the shell's `__tabsShellMinor`, and the same `LibKa0s-Pool-1.0` floor
(`NEEDS_POOL = 1`) `OptionsWidgets.lua` declares — the strip's buttons and the content panel come
from the pool rather than being built on every click, and falling back to allocating per click is
the leak Options minor 14 ended. A payload holding four of the five files is not a supported state
and LibStub cannot detect it, which is why whole-folder vendoring is mandatory.

**Two cross-file calls are now guarded, and both are honest degradations rather than defensiveness.**
`O.RenderTabbedSchema` (in `OptionsWidgets.lua`) falls back to the untabbed render when `O.TabStrip`
is absent — every row with its section headings, exactly what its no-groups branch already does —
and `O.PageBanner` (in `OptionsTabs.lua`) skips its tooltip when `O.AttachTooltip` is absent. The
two files are paired on the **shell's** minor rather than on each other's, so a copy carrying one
and not the other is a state LibStub cannot see; a page that still draws is a smaller failure than
a page that raises.

**`OptionsTabs.lua` takes no descriptor.** `lib.__AttachTabs(O)` is called with the instance alone,
unlike the three attach calls around it. The chrome is geometry and art: it reads no setting, writes
none, and calls no host callback other than the `onSelect` its own spec carries. The signature says
so, so a reader can tell which half of the old file could reach the host's data.

**`OptionsCompose.lua` 6 → 7 lands in the same release, and it adds one spec field.**
`MasterControls` takes `minimapPath` (**C7**): the path of the minimap button's visibility, emitted
as a **Minimap button** checkbox in the **first** column of the line below *Lock frame* / *Debug
console*. It is the Ka0s WoW Addon Standard v2.52.0's `options-ui-§15` row and `launcher-§3`'s one
visibility control, and it is what unblocks the whole collection's launcher adoption: `launcher-§5`
records that no addon could adopt before this seam existed, because §15 forbids hand-writing the row
and the composer had nowhere to emit it from.

**`Test mode` loses its `startsLine` when it pairs.** At **C6** the *Test mode* row opened a line of
its own and left the right half of it empty. It now pairs beside *Minimap button* as
`[Minimap button] [Test mode]`, which is the column order `options-ui-§15` states and states a
reason for: **every** addon has a minimap button and only **some** have a test mode, so the
always-present row takes column 1 and an addon without a test mode draws a tidy single row rather
than a hole in the first column with a lone control to its right.

Both rows stay opt-in, and either alone still opens its own line — `startsLine` is computed from
what was **emitted**, not from what the spec named, so a host that omits the `minimap` leaf through
`omit` is in exactly the same position as one that never passed `minimapPath`. A call that passes
neither renders byte-identically to 20.19.6.3.

**The minimap row is STORED state, and `sessionOnly` is deliberately absent from it.** The console
and the test mode are both things a reload ends. A hidden minimap button is furniture the player
arranged, and `launcher-§3` puts it in the **global** store for two stated reasons: switching
profiles must not move a player's buttons, and `options-ui-§12`'s *Reset all settings* — a profile
reset by definition — must not un-hide a button the player deliberately hid. Its path is therefore
taken **verbatim**, like the console's, because it lives outside the block's profile prefix.

**The row's sense is SHOWN; the inversion is the host's.** `default = true` means the button is
visible. LibDBIcon's own key says *hidden* (`minimap.hide`), so the host's `get`/`set` invert at its
single write seam and call LibDBIcon's `Show` / `Hide` there, exactly as the console row's `set`
opens and closes the console window. The library owns the row; it does not own the inversion, the
table or the registration — those are `LibKa0s-Launcher-1.0`'s (new in this release) and the
host's.

The changes at 20.19.6.3 are in [that version's document](./version-20.19.6.3-docs.md#what-changed-at-this-version).

## Previously, at 13.12.3

**`Options.lua` minor 13 / `OptionsWidgets.lua` minor 12 — the content box stops touching its own
contents, and wrapped rows of tabs sit flush** (options-ui-§13).

Two things a client showed that 12.11.3's arithmetic could not. Neither adds a member; both are
geometry the headless suite had no way to be wrong about, because a headless chrome has no width
and a headless atlas has no height.

**A box has to be outside everything it contains.** 12.11.3 anchored the `Options_InnerFrame`
panel on the content column's own edges — the same `CONTENT_LEFT` / `CONTENT_RIGHT` the page's
widgets use. So the left-hand row labels butted against the left border, and AceGUI's always-shown
scrollbar, which sits *outboard* of `CONTENT_RIGHT` by design, was painted on top of the right one.

The panel now carries its own three internal insets — `PANEL_LEFT`, `PANEL_RIGHT`, `PANEL_BOTTOM`,
each smaller than the content column's — and is anchored horizontally to `ctx.body` rather than to
`ctx.chrome`. The tab strip stays on the content column, which leaves the leftmost tab a few pixels
inside the box's left edge: OPie's arrangement, and the reason its tabs read as sitting *on* the
panel rather than as being its top row.

**A wrapped strip packs by the ART's height, not the button's** (W12). A tab button is `TAB_H`
(37px) carrying an atlas that is shorter, and the difference is the foot that overlaps the panel —
so the empty strip along each button's top stood between two rows as a visible gap. The atlas's
height is only knowable from the client, so `drawTabSlices` measures it (`GetHeight` after
`SetAtlas(name, true)`) and the strip packs rows by that number.

Two consequences worth stating:

- The next row's button overlaps the previous row's art by exactly the empty amount, so each
  button takes a `SetHitRectInsets` removing its own empty top from the mouse. Without it, row 2
  would swallow clicks aimed at the bottom of row 1.
- `__tabBand`'s shape becomes **(n − 1) pitches plus one whole tab**. Every row but the last
  contributes only its pitch, because the next row overlaps it; the last must fit whole, since its
  bottom is the edge the content panel starts at.

**`TAB_ROW_GAP` is retired**, and `__tabPlacement` / `__tabBand` take a `rowPitch` where they took
a `tabH` and a `rowGap`. A measured pitch is not a height plus a gap, and keeping a gap constant
beside it would be two numbers for one decision. Both fall back to `TAB_H` where nothing can be
measured, which is exactly the pre-measurement behavior with no gap.

**Untabbed pages remain untouched.** The panel is drawn by `TabStrip` and nothing else.

### Previously, at 12.11.3

**`Options.lua` minor 12 / `OptionsWidgets.lua` minor 11 — the tab strip stops imitating client
chrome and starts using it, and a first-render wrap bug goes with it** (options-ui-§13).

11.10.3 drew tabs from `Interface/OptionsFrame/`, the client's *old* tab textures. Right idea,
wrong art: those files have sloped transparent shoulders, so a 4px gap between two tabs read as
twelve, and the 1px rule under the strip read as a line the tabs happened to be near rather than
as the edge of anything.

**No member is added or removed at this version.** One published scalar moves — `TAB_H`, 24 → 37 —
and one internal key is retired.

**The reference implementation is OPie's `Libs/TenSettings.lua`**, copied rather than approximated:
the `Options_Tab_*` / `Options_Tab_Active_*` atlases, three slices a tab with the end caps at
natural atlas size and only the middle stretched, the dark gradient backing, the hover glow and
the selected glow, the label anchored to the tab's bottom, `GetStringWidth() + 40`, and a 37px
tab. One deliberate departure: OPie chains its tabs leftward from the frame's right edge and this
strip packs them left to right, because a strip that wraps has to grow downward from a fixed
origin and the left edge is the one the content column already uses.

**The tab/content separator is now a real panel edge, not a rule.** `TabStrip` draws the client's
`Options_InnerFrame` behind the page — two halves meeting at the midpoint, the left one mirrored
by a reversed u range so both corners stay crisp — parented to `ctx.body`, anchored to
`ctx.chrome`'s bottom, and running down to `L.CONTENT_BOTTOM`. It is forced to the body's **own**
frame level, because a child frame otherwise sits one level above its parent and the art would
land in front of the scroll it is meant to sit behind.

A tab is 37px tall against art that is shorter, and the difference is a **foot** that lands on
that panel edge and merges into it. That merge is what a hairline could not do: three attempts at
a 1px rule all read as disconnected, because a line is not the edge of anything.

**`TAB_BASELINE_H` is retired and `__tabBand` no longer takes or reserves it.** Its signature is
now `__tabBand(top, rowCount, tabH, rowGap)` returning one number. A panel drawn *below* the band
must not also be reserved *inside* it, or the page opens a one-pixel gap under its own tabs. The
new internal `CONTENT_BOTTOM` replaces the literal `8` `anchorScroll` used, so the scroll and the
art behind it cannot end in different places.

**Untabbed pages are untouched.** The panel is drawn by `TabStrip` and nothing else, so a consumer
that has never called it renders exactly as it did at 11.10.3 — which is eight of the nine.

**The first page a player opened stacked its tabs vertically** (W11). `ctx.chrome` has zero width
until the settings canvas lays itself out, and the first render happens before that: `placeTabs`
read `0`, fell back to `TAB_MIN_W`, and every tab wrapped onto its own row. It healed the moment
you clicked any tab, because the second render measured a real width — which is exactly why it
survived a suite that only ever rendered twice.

A width cannot be computed from config here; it is the canvas's, and the canvas is Blizzard's. So
the strip re-places itself when the width arrives, through an `OnSizeChanged` script installed once
per panel. Two things keep that from looping: the handler ignores everything but a *change* in
width, and `placeTabs` records the width it used — so the height change `SetChromeHeight` causes,
which fires the same script, is a no-op. The handler reads the current layout out of `ctx` rather
than closing over one strip's buttons, which would pin a released set alive and re-place them
after they were hidden.

`O.EnsureDefaultsButton` has carried a note about `ctx.body` having zero width at enable time since
`O7`. This is the same client behavior reaching a second piece of chrome, and that note is why it
was recognized rather than debugged.

**`TAB_PAD_X` moves 18 → 20** (O12, internal). It has now been too small twice: at 12 the label sat
on the end cap outright, at 18 it cleared the cap but left the tabs cramped against every other tab
strip in the client. 20 a side is OPie's `+ 40`.

**Twelve internal `lib.LAYOUT` keys stay unpublished**, each annotated in `Options.lua` with why:
`TAB_PAD_X`, `TAB_GAP`, `TAB_MIN_W`, `CONTENT_LEFT`, `CONTENT_RIGHT`, `CONTENT_BOTTOM`,
`CHROME_DIVIDER_GAP_TOP`, `CHROME_DIVIDER_H`, `CHROME_DIVIDER_GAP_BOTTOM`, and at 13.12.3
`PANEL_LEFT`, `PANEL_RIGHT`, `PANEL_BOTTOM`. `TAB_ROW_GAP` was retired here; `TAB_BASELINE_H` at
12.11.3.

## What this major is

The settings panel: the canvas shell, the page registry, the lazy Defaults button, the reset and
refresh trio, the five widget makers, and the two-column flow engine that turns a list of schema
rows into a laid-out page.

Three files, one major — `Options.lua` (shell), `OptionsWidgets.lua` (makers and flow),
`OptionsScroll.lua` (the always-shown scrollbar patch). One major because they are one feature: a
host that ended up with a shell from one vendored copy and a flow engine from another would build
panels that lay out wrong, and no version negotiation would catch it. **This is why the version key
above is a triple and why re-vendoring is whole-folder** — the three minors are not independently
adoptable.

Like the others it depends on LibStub and `LibKa0s-Core-1.0` and on no addon framework. AceGUI-3.0
is resolved through LibStub at panel-build time and its absence is survivable — one honest line and
no panel — which is not the same thing as a dependency.

**Previously, in `Options.lua` minor 8 — `O.RefreshPanel(ctx, structural)`, the per-page half of the refresh trio.** One new instance
member, additive. `OptionsWidgets.lua` and `OptionsScroll.lua` do not move. No descriptor field, row
field or drawn pixel changes.

`O.RefreshAllPanels()` and `O.RefreshScalars()` sweep **every** registered ctx, which is right for a
write that could be showing on any page — that is why each widget maker's own `set()` calls one. It
is wrong for a host whose page repaints off its **own** message bus: that host wants one page
repainted and gets three, and the library never hears about the change at all.

What was left for such a host was the private field. `SetRenderer`'s `OnShow` gate reads
`ctx._dirty`, and a host deferring a repaint on a hidden page had to write that flag itself, under a
name nothing published. **PanelMaster guessed `ctx.dirty`** — one underscore out — so its Panels page
marked a flag no code reads. The gate never opened, and the page kept the widget tree it had built
for the previous profile: after a profile switch its panel dropdown still listed the old profile's
panels, while the panels themselves had correctly left the screen. Both suites stayed green, because
the host's own test asserted the same wrong flag name.

- **`Options.lua` minor 8** — `O.RefreshPanel(ctx, structural)` on the instance. It is
  `RefreshAllPanels`/`RefreshScalars` scoped to one ctx and shares their implementation, so the
  shown/hidden decision, the dirty flag and the two tiers stay the library's. A non-table `ctx` is a
  no-op rather than a raise.

**Published on a demonstrated need, which is the bar this library sets** (`library-stack-§7`,
anti-pattern #55). The need here is not repetition: a host bus is a shape the two sweeps genuinely
do not serve, and the only workaround was reaching into a private field by guessing its name — which
is exactly the failure that arrived.

## What stays the host's

The library never learns a settings path, a page name, or a database. It also never learns what a
page *contains*: a host registers builders, and each builder draws its own page through the makers.
What the library owns is everything that is the same in every addon — the canvas registration, the
header and breadcrumb, the button that must not be built too early, the row-pairing arithmetic, and
the refresh fan-out.

## Two divergences absorbed rather than decided

**Colour storage** is a descriptor codec, in **both** majors. AbsorbTracker stores
`{r=,g=,b=,a=}`; KickCD and the Ka0s options colour widget store arrays. Baking either in would
force the other to translate at every read site in the addon, so `colorDecode` / `colorEncode` are
descriptor options — under the same names on the Options and Slash descriptors, so a host passes
one pair to both — and the named-key form is only the default. `Slash.FormatValue` additionally
reads the positional shape directly, so the common case needs no descriptor at all.

**The fifth widget type** ships in `-1.0` rather than being added later. KickCD has a free-text
edit box; AbsorbTracker has no equivalent. Adding a *type* later is additive, but retrofitting one
into a dispatch table the major has already frozen is not. It is opted into with
`dialogControl = "EditBox"` rather than inferred from a missing `values` list, because inference
would silently turn a row whose values function happened to return empty into a free-text field.

## The panel descriptor

Everything a host supplies to `lib:New(descriptor)`.

| Field | Type | Required | Since | Meaning |
|---|---|---|---|---|
| `parentTitle` | string | yes | O1 | The brand. Shown on the main page and as the breadcrumb prefix on every sub-page. |
| `mainPanelName` | string | yes | O1 | Frame name for the main canvas, so `/framestack` attributes it to the host and two addons cannot collide. |
| `print` | function(line) | no | O1 | Where a user-facing line goes. Hosts pass their prefixed printer. |
| `get` | function(path) | yes | O1 | Read one stored value. |
| `set` | function(path, v) | yes | O1 | Write one. Route it through the host's single write seam, so a panel change takes the same path a slash command does — same debug line, same `onChange`, same refresh. |
| `applyDefault` | function(row) | yes | O1 | Reset one row. Same reasoning. |
| `rowsForPage` | function(pageKey, filter) | yes | O1 | The rows of one page, in render order. `filter` is `ctx.unit`, passed through untouched — the library never interprets it. |
| `allRows` | function | yes | O1 | Every row, for `RestoreAllDefaults`. |
| `resetProfile` | function | no | O9 | Supply it and a global reset becomes a **profile reset**: the `sessionOnly` rows are swept row by row, then this is called, then every panel refreshes. Pass `function() NS.db:ResetProfile() end`. With it supplied the library narrows the row walk itself — see `RestoreAllDefaults` below. **Since O18 / C5** it also picks the wording of `MasterControls`' *Reset all settings* tooltip: see [Previously, at 18.15.5.3](#previously-at-1815553). |
| `profilesPage` | boolean | no | **O18** | `true` when the host ships an AceDBOptions Profiles sub-page (`options-ui-§3`). Read by `MasterControls` alone, and only with `resetProfile` supplied: the *Reset all settings* tooltip then names the equivalence `options-ui-§12` asks for, *"the same thing Profiles -> Reset Profile does"* (**O20**: plain ASCII arrow, `localization-§5`). The library cannot see which pages a host registers, so the host declares it. Ignored without `resetProfile`, and changes nothing but that tooltip. |
| `skipRestoreAll` | function(row) | no | O1 | Return true to exclude a row from a global reset. With `resetProfile` supplied the profiles-page veto this was invented for is **implied** (an AceDBOptions row is not `sessionOnly`, so it is already outside the narrowed walk); the field is still honored, and is the whole policy for a host that supplies no `resetProfile`. |
| `afterRestoreAll` | function | no | O1 | Runs after the rows are reset **and after `resetProfile`**, and **before** the panels refresh, for state in neither the schema nor the profile. The order is load-bearing: a refresh first would paint the pre-hook values. A dragged frame's saved position is **not** an example any more — a position lives in the profile and comes back with it. |
| `bulkBegin` | function(act, scope) | no | **O16** | Called once before `RestoreDefaults` (act `"reset"`, scope the `pageKey`) or `RestoreAllDefaults` (act `"reset"`, scope `"all"`) writes its first row. Mute the host seam's per-row `[Set]` line here — `debug-logging-§10`. See [The two fields](#the-two-fields). |
| `bulkEnd` | function(act, scope, count, err, info) | no | **O16** | Called once when the act ends, **always** when the bracket was begun — even if a row, `resetProfile`, `afterRestoreAll` or `bulkBegin` raised. `count` is the rows whose `applyDefault` returned, including rows already at their default, so it is **not** §10's N; `err` is the raised value or `nil` (a raise of `nil`/`false` also arrives as `nil`), and is re-raised unchanged after this returns; `info` is `{ profileReset = <boolean> }`, `true` only when `RestoreAllDefaults` called `resetProfile` and it returned. Unmute here. Then, only when the outermost bracket closes: if any level reported `info.profileReset`, the host **MUST NOT** emit a bulk line (its profile-event handler logs the reset once); otherwise it emits `[Set] reset <scope>: N rows`, with N its own tally of writes that changed a stored value. A host that mutes in `bulkBegin` MUST supply this field. See [What the host logs](#what-the-host-logs--the-contract). A host supplying neither field runs minor 15's walk exactly. |
| `scheduleTimer` | function(fn, delay) | no | O1 | Backs the 50 ms colour-drag throttle. A descriptor field rather than an AceTimer embed, because embedding would be this library's second dependency-budget breach. Without it a drag commits every frame. |
| `getLSM` | function | no | O1 | Returns LibSharedMedia-3.0, for `LSMValues` and, **since O17**, for the font preload a panel's show runs ([`lib.__PreloadFonts`](#lib__preloadfontslsm--number)). Absent, a host gets no preload. |
| `validate` | function | no | O1 | Runs once, before the page builders. A host's schema-shape check. |
| `onAceGUI` | function(AceGUI) | no | O1 | Handed the resolved AceGUI so the host can stash it (library-stack-§4) for its own page files. |
| `buildMain` | function(ctx) | no | O1 | Draws the main page's body, on its first OnShow. |
| `colorDecode` | function(stored) | no | O1 | → `r, g, b, a`. Defaults to the `{r=,g=,b=,a=}` shape. |
| `colorEncode` | function(r,g,b,a) | no | O1 | → stored. Defaults to the same. |
| `sliderCommit` | string | no | O1 | `"change"` makes every slider commit on the drag as well as on release, throttled through `scheduleTimer`. Default is release-only; a single row overrides either way with `commitOn`. |
| `debug` | function(tag, fmt, …) | no | O1 | Developer log line. |

Unlike Core, DebugLog and Slash, this module performs **no descriptor validation at all** — `d` is
indexed directly, so only a nil descriptor raises. The fields marked required above are required in
practice rather than enforced: a missing `parentTitle` silently becomes `""`, and a missing
`get`/`set`/`applyDefault`/`rowsForPage`/`allRows` surfaces at panel-build time, when a widget maker
reaches for it, not at `:New`. Treat the column as a contract you keep rather than one the library
keeps for you.

## The library surface

Almost everything this major publishes hangs off the instance `lib:New(descriptor)` returns. Two
members do not, and cannot. A widget-registry entry is per **process**, and so is a loaded font
file, so the thing that writes either has to be per library rather than per host.

### `lib.__PatchLSM30Border()` → boolean

**Since O15.** Wrap AceGUI-3.0-SharedMediaWidgets' `LSM30_Border` so it lines up on a canvas-layout
settings page, and register the wrapper one version above whatever the registry currently holds.
Returns `true` if this call performed the registration and `false` if there was nothing to do.

| | |
|---|---|
| Where to call it | From the live arm of the host's options setup — the same place it resolves AceGUI. Safe at file load, and safe to call again later. |
| What it does per instance | Hides `frame.displayButton`, re-anchors `frame.label` to the frame's own TOPLEFT and TOPRIGHT, and restores `frame.DLeft` to `GetBaseFrame`'s `BOTTOMLEFT, -17, -21`. |
| What it wraps | Whatever constructor the registry holds when it runs — which may already be a skinning addon's — never a reimplementation of the widget. |
| Idempotence | `lib.__lsmBorderPatched`, on the **library** table. Every vendored copy in the session shares one `lib`, so N copies calling this produce exactly one registration. |
| Returns false when | The library is already patched, AceGUI is absent, or `LSM30_Border` is not in the registry yet. |
| Scope | Border only. `LSM30_Font` and `LSM30_Statusbar` take `AGSMW:GetBaseFrame`, which has no `displayButton`. |

**A `false` return is not an error and does not need handling.** The three reasons for it are all
ordinary: another Ka0s addon got there first, this client has no AceGUI, or AGSMW has not loaded yet.
The last of those is the reason the sentinel is set **only after a registration actually happens** —
a host that calls this early and again after login gets its patch on the second call, where a flag
set on the early return would have disarmed the surface for the whole session in silence.

**`lib.__lsmBorderPatched` is readable but is not a supported write.** Clearing it does not
un-register the wrapper; it only invites a second one to be registered on top of the first, which is
the five-deep stack this member exists to end.

### `lib.__PreloadFonts(LSM)` → number

**Since O17.** Load every LibSharedMedia font face not loaded yet, then subscribe once to faces
registered later. Returns how many faces this call loaded. **Defined in `OptionsScroll.lua` from
O24/S4** (in `Options.lua` from O17 to O23), unchanged; nil in a partial copy missing that file,
which both callers treat as no preload. The header of the preload block in `OptionsScroll.lua`
says why it runs on a panel's show.

| | |
|---|---|
| Who calls it | The library, from every panel show: `O.SetRenderer`'s OnShow after its combat refusal, and the OnShow hook `O.CreatePanel` installs. A host does not call it. |
| `LSM` | What the host's `getLSM()` returns. Anything that is not a table with `HashTable` answers 0 and creates nothing. |
| What it creates | On the first call that loads anything: one frame for the session, parented to `UIParent`, shown, full alpha, 1x1, off the left edge of the screen. Then one FontString per distinct font path, `SetFont(path, 12, "")` and `SetText("Aa")`, `pcall`'d together. |
| Idempotence | `lib.__fontPreload`, on the **library** table: `{ paths = { [path] = true }, frame, subscribed }`. Every host and every vendored copy shares it, so each path is loaded once per session. A path is marked before it is tried, so a face the client refuses is not retried. |
| Late faces | After the first call that finds a `CreateFrame`, one subscription to `LibSharedMedia_Registered`, with the state table as its target. A `font` registration re-runs this, which loads only the new path. |
| Degrades | No `CreateFrame` answers 0 and marks nothing, so the next call tries again. A raising `HashTable` answers 0. The instance trigger `pcall`s the whole call, `getLSM` included, and reports nothing. |
| After an upgrade | Both callers look the member up on `lib` at call time, so the newest copy's code runs against the state the older copy left. |

**`lib.__fontPreload` is readable but is not a supported write.** The suite resets it between cases.
A host that clears it loads every face a second time, into a second frame, for nothing.

### The combat lock's library-level names (O22, T2)

**Since O22 / T2.** Internal — `__`-prefixed, so no manifest lists them and no degradation stub
carries them — but library-level for the reason the two members above are: one event frame and one
lock for the whole process, whichever vendored copy won. A host calls none of them.

| Name | Since | Meaning |
|---|---|---|
| `lib.__IsCombatLocked()` → boolean | O22 | `lib.__combatLocked` or `InCombatLockdown()`. The one predicate every refusal asks. |
| `lib.__combatLocked` | O22 | `true` from `PLAYER_REGEN_DISABLED` to `PLAYER_REGEN_ENABLED`. Kept across an upgrade; from **T3** cleared too when the last page leaves the screen. |
| `lib.__OnCombatEvent(event)` | O22 (in OptionsTabs.lua and page-scoped: **T3**) | The dispatcher: re-syncs the registration and returns if no page is on screen; else sets or clears the flag, then calls every registered hook with `locked`, each pcall'd. |
| `lib.__combatHooks` | O22 | Weak-keyed set of `hook(locked)`, one per instance, each held by its instance as `O.__combatHook`. |
| `lib.__combatFrame` | T2 (page-scoped: **T3**) | The one frame for both events. Created once, hidden, kept across an upgrade; registered only while a page is on screen (T3). Its `OnEvent` resolves `lib.__OnCombatEvent` at call time and is re-set by each newer copy. |
| `lib.__shownPages` | **T3** | Weak-keyed set of every ctx on screen, across hosts. |
| `lib.__pageShown(ctx)` / `lib.__pageHidden(ctx)` | **T3** | Called from a page's show and hide: add (if the panel is on screen) and register, or remove and re-sync. |
| `lib.__syncCombatEvents()` | **T3** | Prune pages off screen, register or unregister to match, and clear `lib.__combatLocked` when none is left. |
| `lib.__coverLevel(panel, cover)` → number | T2 | The level a cover takes over a page on screen: `max(panel + 100, deepest descendant + 1)`, at most 10000. |
| `lib.__descendsFrom(frame, ancestor)` → boolean | T2 | A bounded `GetParent` walk; picks the AceGUI pullout that is the host's to close. |
| `lib.STRINGS.COMBAT_LOCKED` | O22 | *Settings are locked during combat.* — the cover's line, the standard's words. |
| `lib.STRINGS.COMBAT_LOCKED_NOTICE` | O22 | The gray chat line, at most once per combat per host. |

On the instance, equally internal: `O.__combatRefused()` (O22, the refusal every file asks),
`O.__buildCover(panel)` (T2) and `O.__releaseOwnedFocus(panels)` (T2), and `ctx.__combatCover` on
every ctx `CreatePanel` returns.

### The registration park's library-level names (O24)

**Since O24.** Internal for the same reasons as the lock's names above; a host calls none of them.

| Name | Since | Meaning |
|---|---|---|
| `lib.__parkedPanels` | O24 | The parked replays, in the order they were parked. Kept across an upgrade; replaced with a fresh table when drained. |
| `lib.__parkFrame` | O24 | The park's private frame, separate from `lib.__combatFrame`. Created on the first park, hidden, kept across an upgrade; registered for `PLAYER_REGEN_ENABLED` only while `lib.__parkedPanels` is non-empty. |
| `lib.__parkRegistration(replay)` → boolean | O24 | Append `replay`, (re)set the frame's `OnEvent` and register the event. `false` when no frame can be made, and the caller then registers at once. |
| `lib.__OnParkEvent(event)` | O24 | Ignores every event but `PLAYER_REGEN_ENABLED`; on it, unregisters, takes the parked list and replays each once, each `pcall`'d, then raises the first error (if any) so it is reported rather than swallowed. A replay that finds the client still locked parks again. |

## The instance surface

Everything `lib:New(descriptor)` returns on the instance.

| Name | Since | Meaning |
|---|---|---|
| `CreatePanel(name, title, opts)` | O1 (canvas contract: **O5**; chrome slot: **O10**; combat cover: **O22**) | A canvas Frame with the unified header stamped on top, returning the `ctx` every render call threads through. `opts` = `{ pageKey, isMain, defaultsButton, defaultsTooltip }`. Registers the ctx so the refresh fan-out reaches it. Also stamps the **Blizzard canvas contract** — `OnCommit` and `OnRefresh` inert (writes land immediately through the host's write seam, and `SetRenderer` already owns re-show), and `OnDefault` **forwarding** to the panel's `defaultsOnClick` so the Settings window's footer control and the header Defaults button stay one implementation. A forwarder rather than an assignment because hosts park `defaultsOnClick` *after* this returns. The returned `ctx` now also carries `chrome` (a pinned `Frame` between the header and the scroll) and `chromeHeight` (starting at `0`) — see [What changed at this version](#what-changed-at-this-version). From **O22** it also builds the page's combat cover (`ctx.__combatCover`), hidden, and the canvas contract's `OnDefault` is refused in combat. |
| `EnsureDefaultsButton(panel)` | O1 | Builds the header's Defaults button on the panel's **first OnShow**, never at build time. Idempotent, and a no-op on a panel that did not ask. |
| `EnsureScroll(ctx)` | O1 | The lazy AceGUI ScrollFrame, patched for an always-visible scrollbar. |
| `ClearScroll(ctx)` | O1 (`lastSubgroup`: **O14**) | Release the children, reset **both** heading trackers (`ctx.lastGroup` and `ctx.lastSubgroup`), and **reassign** `ctx.refreshers`. |
| `Section(ctx, label)` | W1 | A full-width Heading, with the inter-section spacers. |
| `AddSpacer(scroll, height)` | W1 | An invisible full-width row. |
| `TextRow(ctx, text, opts)` | **W6** | A full-width Label, left-justified, added to `EnsureScroll(ctx)` and returned. `opts.fontObject` is a `_G` font-object **name**; `opts.justify` defaults to `"LEFT"`. Returns nil when AceGUI or the scroll is absent. Owns the `w.label` / `SetJustifyH` / `SetFontObject` guard pair **once**. |
| `BuildLandingPage(ctx, spec)` | **W6** | The whole landing body: clear, logo, one-liner, then a heading and its rows per section. See [The landing page](#the-landing-page). |
| `AttachTooltip(widget, label, tooltip)` | W1 | Works on AceGUI widgets and on plain frames. |
| `InlineButtonPair(ctx, left, right)` | W1 | Two action buttons (not settings) in one Flow row, each inset to `BUTTON_PAIR_REL`. A **nil** `right` draws the left button alone, at the pair's width, so it still lines up with every other page's — which is the shape a frameless addon's Master controls tab needs. A throwing `onClick` is reported, never propagated into AceGUI's dispatch. A spec carrying **no** `onClick` is reported once at BUILD time (`lib.STRINGS.DEAD_BUTTON`, naming the button's text) and drawn anyway — the composer emits the master group's two resets unconditionally, so a host that never supplied `onResetAll`/`onResetPosition` is told rather than shipping a live-looking button that swallows the click. **From W16**, drawn inside a disabled render (`RenderRows`' `opts.disabled`, or a disabled `ChoiceGrid` / `IdInput` / `IdList`), both buttons are drawn disabled. |
| `RenderField(ctx, row, parent, relWidth)` | W1 (path-less rows: **W15**; `disabledIf` on every maker: **W16**) | Dispatch by `row.type` to one of the five makers. Returns nil for an unknown type rather than erroring — a misspelled type costs one row, not the page. A row with no `path` is read and written through its own `get` / `set` from W15 — see [Previously, at 15.15.4.3](#previously-at-1515543). From W16 every maker honors `row.disabledIf` — see [What changed at this version](#what-changed-at-this-version). |
| `SessionCheckbox(ctx, parent, relWidth, spec)` | W1 (disabled render: **W16**) | A checkbox wired to caller-supplied `get`/`set` instead of a settings path, for runtime-only toggles that must never persist. From W16 it is drawn disabled when drawn inside a disabled render. |
| `RenderRows(ctx, rows, afterGroup, pairWith, opts)` | W1 (`opts.noHeadings`: **W9**; `opts.disabled`: **W16**; `shownWhen`: **W22**) | The flow engine, over an **explicit** row list — which is what lets a host render a filtered subset through the same code. `opts = { noHeadings = true }` suppresses the automatic `Section` heading, for a page whose sections are drawn as tabs instead (options-ui-§13); the row-boundary flush and `ctx.lastGroup` advance still happen. Omitted by every untabbed caller. **`opts.disabled = true` (W16)** draws every widget of the call disabled, the widgets an `afterGroup` or `pairWith` hook draws included, through `ctx.__renderDisabled` held for the call alone. A nested call inherits it, and the outer value is restored on a raise, which is re-raised unchanged — see [What changed at this version](#what-changed-at-this-version). |
| `RenderSchema(ctx, pageKey, afterGroup, pairWith)` | W1 | The per-page wrapper. |
| `RenderTabbedSchema(ctx, pageKey, afterGroup, pairWith)` | **W9** | Render one page as a tab strip over its own sections. The partition is by `row.group`, in declaration order — one tab is exactly one group, and there is no second field naming a tab (options-ui-§13). **Every page draws a strip from W13, including a one-group page** — the `#groups < 2` fallback to `RenderSchema` is gone, and the only exemption is a page the host does not route through this function at all (the AceConfig-drawn Profiles page). A page whose rows carry **no** `group` is reported by page key through the descriptor's `print` and rendered untabbed. A stale `ctx.activeTab` heals to the first group. A tab click re-enters through `ClearScroll` and this function again — the same structural path a subject change already takes, but that path carries no combat refusal to inherit: `SetRenderer`'s guard covers opening or switching a category, not redrawing inside an already-open panel, so a tab click needs no guard and none is added (options-ui-§13). Returns the group names, in tab order. |
| `TabStrip(ctx, spec)` | **W9** | A pinned tab strip in `ctx.chrome` (options-ui-§13). `spec = { tabs = { { key, label, tooltip } }, value, onSelect }`. One `Button` per tab, the active tab the disabled one. Wraps its buttons across rows via `__layoutTabs`, places them via `__tabPlacement`, and reserves the band via `__tabBand` + `SetChromeHeight` — **after** the wrap is known. Each tab is three slices of the client's `Options_Tab_*` atlases; the selected one is drawn from the Active family and its foot overlaps the `Options_InnerFrame` content panel `TabStrip` also draws (**W11**). Re-places itself once when `ctx.chrome` first learns a real width (**W11**). **Its geometry is invariant under the selection from W13.** **From W14 the buttons and the content panel are acquired from `LibKa0s-Pool-1.0` pools held on the `ctx` rather than created per click** — see [What changed at this version](#what-changed-at-this-version). Returns the buttons in tab order, or nil having drawn nothing. |
| `SubTabStrip(ctx, parent, spec)` | **W13** | A **secondary** strip drawn inside the scroll as ordinary page content, parented to a frame the host supplies (options-ui-§13). Same `spec` shape as `TabStrip`, same selection-invariant pitch, its own ledger (`ctx.__subTabKids`) released on entry, and **no** content panel and **no** `SetChromeHeight` — the page already has both. **Not pooled at W14**, unlike the primary strip: its parent is a frame AceGUI takes back, so its buttons are unparented on release and cannot be recycled. Returns the buttons in tab order **and** the total height the strip occupies, so the host can size the frame it handed in, or nil having drawn nothing. The selection is the host's state: `spec.value` and `spec.onSelect` are the whole contract, and the convention for the collection is `ctx.activeSubTab` as a table keyed by the primary tab's key, session-only and never persisted. |
| `PageBanner(ctx, spec)` | **W9** | The page's picker, pinned above the strip and the scroll (options-ui-§14) — the only picker a page may have. `spec = { label, list, order, value, onSelect, tooltip }`. Draws one AceGUI `Dropdown` into `ctx.chrome`, plus the gap / hairline / gap that separate it from the strip (options-ui-§14); records the whole band in `ctx.__bannerHeight` via `__bannerBand` and reserves it with `SetChromeHeight`. Measures the dropdown and **floors** at `L.BANNER_H` rather than forcing that height (**W10**). **Draw it before `TabStrip`.** Returns the dropdown, or nil having drawn nothing. |
| `PageHeader(ctx, spec)` | **W13** | A host-drawn block pinned in the same band, for controls that apply to **every** tab (options-ui-§14). `spec = { height, build = function(ctx, frame) end, divider = <default true> }`. Anchors a `Frame` across `ctx.chrome`, ledgers it, draws the hairline unless told not to, records the widened band in `ctx.__bannerHeight` via `__bannerBand`, reserves it with `SetChromeHeight`, then calls `build` inside a `pcall` — a raising builder is reported and costs the block, not the page. **A page draws at most one chrome block**: this and `PageBanner` both release `__chromeKids` and both write `ctx.__bannerHeight`, so the second call replaces the first. **Draw it before `TabStrip`.** Returns the frame, or nil having drawn nothing. |
| `SetChromeHeight(ctx, height)` | **O10** | Reserve `height` pixels of pinned chrome above the scroll, and re-anchor a live scroll to match. Idempotent. `height <= 0` hides `ctx.chrome`. Call only after the wrap of whatever is being reserved is known. |
| `__scrollTopInset(ctx)` | **O10** | `L.CHROME_GAP + (ctx.chromeHeight or 0)` — the seam `EnsureScroll` and `SetChromeHeight` both read for the scroll's top anchor, so the two cannot disagree. |
| `__layoutTabs(widths, available, gap)` | **W9** | Pure arithmetic: pack tab pixel widths into rows that fit `available`. A tab wider than `available` is placed alone rather than dropped. Returns rows of 1-based indices into `widths`. Test seam for the wrap rule, callable with no widgets. |
| `__tabPlacement(widths, available, gap, top, rowPitch)` | **W10** (signature: **W12**) | Pure arithmetic: the wrap from `__layoutTabs` turned into `{ index, width, x, y }` per tab, plus the row count. `top` is the banner's finished band, which is why row 1 no longer lands on the banner. `rowPitch` is the tab ART's measured height, not the button's. Callable with no widgets. |
| `__tabBand(top, rowCount, tabH, rowPitch)` | **W10** (signature: **W12**) | Pure arithmetic: how many pixels the strip reserves in total, banner included — which is also where the content panel's top edge lands. **(n − 1) pitches plus one whole tab**, because every row but the last is overlapped by the one under it. Took a `rowGap` through 12.11.3 and a `baselineH` through 11.10.3. |
| `__bannerBand(rawHeight, gapTop, ruleH, gapBottom)` | **W10** | Pure arithmetic: the banner's own height widened by the gap, hairline and gap that separate it from the strip (options-ui-§14). What `ctx.__bannerHeight` holds. |
| `__releaseChrome(ctx)` | **W9** | Test seam. Releases everything the page parked in its chrome band. The banner's ledger (`ctx.__chromeKids`) is hidden, unparented and forgotten; **from W14 the strip's furniture is returned to `ctx.__tabPool` / `ctx.__panelPool` instead** — hidden, still parented to `ctx.chrome`, and ready to be dressed again — and `ctx.__tabKids` is emptied as the ledger it now purely is. |
| `__tabArtHeight()` | **W13** | The measured row pitch — the **unselected** tab art's own height, or `TAB_H` where nothing can be measured. Memoized on success only. Published because the invariant a suite has to pin is unassertable without the one number the band and every row offset are both built from. |
| `__resetTabArtHeight()` | **W13** | Forget that measurement. A harness seam; an atlas does not change size mid-session. |
| `RegisterOptionsPage(key, name, builder)` | O1 | Queue a page. Builders run once, in order, at `CreateOptionsPanel`. |
| `CreateOptionsPanel()` | O1 (combat park: **O24**) | Resolve AceGUI, hand it to the host, validate, register the main canvas, run every builder. Idempotent. **From O24**, under `InCombatLockdown()` it registers nothing, parks the call and replays it once at `PLAYER_REGEN_ENABLED`; a second call while parked is a no-op. |
| `OpenOptionsPanel()` → `true`, `false` or `nil` | O1 (combat refusal: O3; return value: **O24**) | Open the category. **Refuses** under combat and never defers-and-replays. The gate for a page **shown** in combat another way is the lock (**O22**). **From O24** answers `true` when opened, `false` when refused in combat, and `nil` when there is no category to open; through O23 it returned nothing. |
| `RestoreDefaults(pageKey, ctx)` | O1 | The per-page Defaults button. Refreshes only the ctx it was given. **From O16** the page walk runs inside the descriptor's optional `bulkBegin` / `bulkEnd` bracket (act `"reset"`, scope `pageKey`); the refresh runs after it closes. **From O22** refused in combat (nothing is reset); `RestoreAllDefaults` is not, because a slash reset verb calls it. |
| `RestoreAllDefaults()` | O1 | Without `resetProfile`: every non-vetoed row, then `afterRestoreAll`, then a full refresh — unchanged. **With `resetProfile` (O9):** only the `sessionOnly` rows, then `resetProfile()`, then `afterRestoreAll`, then a full refresh. **From O16** everything before the refresh — the row walk, `resetProfile` and `afterRestoreAll` — runs inside the descriptor's optional `bulkBegin` / `bulkEnd` bracket (act `"reset"`, scope `"all"`). |
| `SetRenderer(ctx, fn)` | O1 (combat lock: **O22**) | Declare how a page draws itself. The library owns *when*: first show, again after a refresh marked it dirty while hidden, and — from O22 — at `PLAYER_REGEN_ENABLED` for a page on screen that combat left owed a render. Also builds the Defaults button. Under combat it **covers** the page and draws nothing; through O21 it closed the settings window instead (anti-pattern #88). |
| `RefreshAllPanels()` | O1 (two tiers: O3) | **Structural.** Re-run each page's renderer, so rows that appeared or disappeared are drawn. Hidden pages are flagged dirty and re-render on their next show. |
| `RefreshScalars()` | O3 | **In place.** Refreshers only, no rebuild — what every widget maker's own `set()` calls, since writing a value does not change which rows exist. Each is pcall'd, so one dead widget cannot take the UI with it. |
| `RefreshPanel(ctx, structural)` | O8 | **One page, either tier.** `structural` true re-runs that ctx's renderer; false runs its refreshers in place. A hidden page is flagged dirty and repaints on its next show, so the caller never has to ask whether it is on screen. For a host whose page repaints off its own message bus rather than off a widget's `set()`. |
| `SelectTab(pageKey, tabKey)` | **O19** | Move an already-rendered page to one tab and refresh **only** that page, through `RefreshPanel(ctx, true)`. Returns `false`, storing no intent, for a page that has not been rendered — the caller opens the page. See [What changed at this version](#what-changed-at-this-version). **From O22** answers `false` in combat and moves nothing. |
| `__pages()` | O1 | The pages that actually built. A raising builder is reported by key and costs only itself. |
| `RenderGrid(ctx, items)` | **W4** | Lay arbitrary widgets out two per row, caller-ordered. The sibling of `RenderRows`: that one walks schema rows and emits sections, this one takes whatever the caller hands it — a schema row, or `{ make = fn }` for a bespoke widget, or `wide = true` for its own line. For a list whose length is not in the schema (one checkbox per macro, per unit, per spell). Items are guarded individually. **Two asymmetries with `RenderRows`, both deliberate today and both tracked:** it does **not** call `scroll:DoLayout()` at the end, so a page rendered through `RenderGrid` alone must call it itself; and it renders into `EnsureScroll(ctx)` with no `parent` override, so it cannot draw into a container the host owns. See [KickCD#10](https://github.com/tusharsaxena/KickCD/issues/10). |
| `ChoiceGrid(ctx, spec)` | W16 (checkbox cells, `extraColumn`: **W17**) | A matrix of one-choice-per-row cells over rows that share one value list: a header line of column labels, then per row one checkbox per column (a yellow fill, not an AceGUI radio, from **W17**) and the row's label with its tooltip. Reads and writes through the maker seam and re-syncs on `RefreshScalars`. **From W17** an optional `spec.extraColumn` draws a per-row link after the label. Returns the row lines. See [The choice grid](#the-choice-grid). |
| `ResolveId(kind, text, candidates)` | **W16** | Pure. Typed text → `id, name, icon`, or `nil, reason` (`"empty"`, `"notFound"`, `"ambiguous"`): a number, a link of the kind's own type, the client's name lookup, then the host's candidates by name. A name two distinct ids carry is ambiguous. See [The id input and the id list](#the-id-input-and-the-id-list). |
| `IdInput(ctx, parent, spec)` | **W16** | One add-by-id line — an edit box, an Add button and a status line — into `parent`, default the page's scroll. Resolves through `ResolveId` and calls `spec.onAdd(id)`; never writes a path and redraws nothing. With item `candidates`, pre-warms the unnamed ones and looks a name up among them before refusing it. While the player types, lists up to ten matching entries under the box, every rank its own row, to pick with a click or the keys. Returns the group, the edit box, the button and the status label. |
| `UnnamedCandidates(kind, candidates)` | **W16** | Pure. The item candidates the client cannot name yet, each once, at most 200 — what `IdInput` asks the client for. See [`O.UnnamedCandidates`](#ounnamedcandidateskind-candidates--ids). |
| `ID_NAME_HINT` | **W16** | A table: the default name hint per named kind (`item`, `spell`, `currency`), a copy per instance, for a host's tooltip. See [`O.ID_NAME_HINT`](#oid_name_hint). |
| `IdList(ctx, spec)` | W16 (entry `note`: **W17**; `columns`: **W24**) | An optional heading, the `IdInput` line, then one line per `spec.entries()` entry, or `columns` entries to a line from **W24** (at most two — AceGUI's label arithmetic, not a taste) — icon, name (an item's in its quality color), gray id, an optional `note` line under the name (**W17**, drawn only for a non-empty string), and Remove or a toggle checkbox. Redraws after an add or a remove through `ctx.rebuild`, else `RefreshAllPanels()`. Returns one line per entry drawn. |
| `ColorPair(spec)` | **C1** (`spec.bind`: **C4**) | A color swatch and its *use class color* companion, as exactly two adjacent rows. See [The schema composers](#the-schema-composers). |
| `FontGroup(spec)` | **C1** (`spec.bind`: **C4**) | The canonical six font rows, in the canonical order. Its `font` row's `values` is `O.LSMValues("font")` itself (**C3**). |
| `BorderGroup(spec)` | **C1** (`spec.bind`: **C4**) | The canonical four border rows, optionally preceded by a *Show border* toggle. Its `borderStyle` row's `values` is `O.LSMValues("border")` itself (**C3**). |
| `BarGroup(spec)` | **C1** (`spec.bind`: **C4**) | The canonical four bar rows, for a surface with a **fill texture**. Its `barTexture` row's `values` is `O.LSMValues("statusbar")` itself (**C3**). |
| `MasterControls(spec)` | **C1** (`spec.bind`: **C4**) | The canonical Master controls rows **and** the `afterGroup` hook that draws the tab's closing button pair. Returns two values. Takes `leadButton` since **C2**, `testModePath` since **C6** and `minimapPath` since **C7**. Its *Reset all settings* tooltip follows the descriptor's `resetProfile` and `profilesPage` since **C5**. |
| `FONT_FLAGS` / `FONT_FLAGS_SORT` | **C1** | The font-flag key map and its declared order. |
| `VISIBILITY_VALUES` / `VISIBILITY_SORT` | **C1** | The four general-visibility values and their declared order. General visibility is a dropdown, not a boolean: a boolean can only ever answer two of the four. |
| `MASTER_GROUP` | **C1** | The literal `"Master controls"` — the group name, the tab label and the `afterGroup` key are one string, because the group name **is** the hook key. |
| `CLASS_COLOR_NOTE` | **C1** | The sentence every composed swatch's tooltip carries, in place of the `disabledIf` it must never have. |
| `LSMValues(mediaType)` | W1 (never-empty: **W4**) | A **deferred** closure pulling the live media hash at dropdown-render time. Never empty: a media library that has not loaded yet yields a single `None` placeholder, because a dropdown with no options cannot be opened and the CLI would refuse even the stored value. Deferred is load-bearing: LSM-backed rows evaluate this inside a schema-row literal at file load, long before the addons that register media have run. **Since C3 the media composers assign what this returns directly into a row's `values`**, which is why a host that replaces this member must return a function; see [The schema composers](#the-schema-composers). |
| `PatchAlwaysShowScrollbar(scroll)` | S1 | The scrollbar override. Idempotent, and reversed on `OnRelease` — AceGUI pools ScrollFrames, so an unreleased patch escapes into whichever addon recycles the widget next. |
| `ROW_VSPACER` / `SECTION_HEADING_H` / `BUTTON_PAIR_REL` | W1 | The cross-slice layout constants, mirrored onto the instance so a host's own page code stays in lockstep with the engine's spacing. |
| `PADDING_X` | **O7** | The horizontal inset the library draws its own header, divider and body to. Read it to align a bespoke widget with any of the three; **do not restate it** (options-ui-§8). |
| `CHROME_GAP` | **O10** | Gap between the bottom of the chrome band and the top of the scroll (`8`, the literal `EnsureScroll` always used). |
| `TAB_H` | **O10** (value: **O12**) | Height of one row of tabs (`37`), taller than the art it carries — the bottom of a tab is the foot that overlaps the content panel. Was `24` through 11.10.3. |
| `BANNER_H` | **O10** (value and meaning: **O11**) | **Floor** for the page banner (`44`), not a fixed height: `PageBanner` measures its dropdown and takes the larger. |
| `chrome` (on `ctx`) | **O10** | The pinned chrome `Frame`, returned on every `ctx` from `CreatePanel`, inset to `PADDING_X` on both edges. What `TabStrip` and `PageBanner` parent their widgets to. |
| `chromeHeight` (on `ctx`) | **O10** | The pixels of chrome the page has reserved, starting at `0`. Set only through `SetChromeHeight` — never write it directly, or the scroll's anchor and the frame's actual height will disagree. |
| `AceGUI` | O1 | The resolved AceGUI-3.0, or nil. Filled in at `:New` and re-resolved at `CreateOptionsPanel`, which is the copy `onAceGUI` hands the host. |
| `__panels()` / `__panelFor(pageKey)` | O1 | Test seams, following Perf's `__buckets()` idiom. The registry is private, so a host suite otherwise has no handle on a live ctx — and a real bug once shipped precisely because one page's ctx was unreachable. |

## The landing page

New at `OptionsWidgets.lua` minor 6 / `Options.lua` minor 6.

### `O.TextRow(ctx, text, opts)` → widget or `nil`

A full-width AceGUI `Label`, left-justified, added to `O.EnsureScroll(ctx)` and returned. A no-op
returning `nil` when AceGUI or the scroll is absent, like every other maker here.

| `opts` field | Type | Meaning |
|---|---|---|
| `fontObject` | string | A `_G` font-object **name** (`"GameFontHighlight"`), applied only when both `widget.label.SetFontObject` and `_G[name]` exist. A name rather than the object itself, so a host declaring a spec at file load does not have to have resolved a global yet. |
| `justify` | string | Defaults to `"LEFT"`. |

It earns its place independently of the landing page: it owns the
`if w.label and w.label.SetJustifyH then` / `SetFontObject` pair **once**. That pair was written out
per text widget per host — 28 times across six repos — and every copy is a place for one of the two
halves to be forgotten, which fails silently and only in game.

### `O.BuildLandingPage(ctx, spec)`

Renders a whole landing body: `ClearScroll`, then the logo, the one-liner, and a heading plus its
rows per section.

| `spec` field | Type | Meaning |
|---|---|---|
| `logo` | string | Texture path. Omitted = no logo block and no gap under it. |
| `logoSize` | number | Defaults to `lib.LAYOUT.LANDING_LOGO`. |
| `notes` | string **or** function() → string | The one-liner. **A function is called at render time**, because a host reading its own TOC `Notes` cannot resolve it at declaration. Empty or nil skips both the notes block and its spacer. |
| `sections` | array of `{ heading = string, rows = function() → array of string }` | `rows` is a **function**, not an array, for the same reason: a re-render then picks up a command registered since the spec was declared. Feed it `Sl:LandingRows`. |

**The renderer owns the clear, not the registry.** A landing page re-renders on every re-show, and
stacking a second copy of the logo under the first is what happens without it.

Headings go through `O.Section`, rows through `O.TextRow`, gaps through `O.AddSpacer` — so the page
is composed of this major's existing vocabulary and inherits every fix to it.

### The four `lib.LAYOUT` constants

Read off the LibStub table (`LibStub("LibKa0s-Options-1.0").LAYOUT`), not the instance.

| Key | Value | Meaning |
|---|---|---|
| `LANDING_LOGO` | 300 | The logo block's height, and the default `spec.logoSize`. |
| `LANDING_GAP_LOGO` | 8 | The gap under the logo. |
| `LANDING_GAP_DESC` | 12 | The gap under the one-liner. |
| `LANDING_GAP_HEAD` | 6 | The gap under a landing heading. |

All four are promoted verbatim from three hosts that had each declared them and agreed on every
value.

`LANDING_GAP_HEAD` **must stay equal to `SECTION_BOTTOM_SPACER`**, which `O.Section` already emits
under every heading — `BuildLandingPage` therefore does not draw a second one, and the day the two
values diverge every landing heading loses its gap. `tests/test_options.lua` pins the equality.

## The choice grid

New at `OptionsWidgets.lua` minor 16. `spec` takes an optional `extraColumn`, since minor 17.
Minors 17–18 painted the lit cell's check region with a solid yellow fill; **from minor 19** that
fill is withdrawn on owner feedback and the cells are ordinary AceGUI checkboxes throughout.

### `O.ChoiceGrid(ctx, spec)` → lines or `nil`

| `spec` field | Type | Meaning |
|---|---|---|
| `rows` | array of schema rows | Each carries `path` (or a path-less `get` / `set`), `label`, the tooltip body (`tooltip` or `desc`), and optionally `disabledIf`. Read and written through the same seam every maker uses. Give them `skipRender = true` so the flow engine leaves them to the grid; the grid draws them regardless, and they stay in the schema for the CLI and the resets. |
| `columns` | ordered array of `{ value =, label = }` | One cell per entry, in this order. A column with no `label` is headed by its `value`. |
| `heading` | string | Optional. Drawn with `O.Section`, and recorded as `ctx.lastGroup`. |
| `labelHeader` | string | Optional heading for the label column. `"Category"` when absent: a literal, as `lib.STRINGS`' own are, since the library carries no locale. |
| `disabled` | boolean | Optional. Draws every cell and label disabled, as `RenderRows`' `opts.disabled` does. A grid drawn inside a disabled render inherits that render's flag either way. |
| `extraColumn` | `{ header =, cell = function(row) -> { text =, onClick =, tooltip = } \| nil }` | Optional, **W17**. A link column drawn after the label column. `cell` is host code, `pcall`'d per row in `choiceExtraCell`; a raise, or a `nil` return, draws a blank `Label` at the same width and costs only that cell. `onClick` is wired only when `type(cell.onClick) == "function"`. The label column gives back this column's width so the line still fits one Flow row; a `spec` with no `extraColumn` is unchanged from W16. |

Each line is a full-width Flow `SimpleGroup`: a `CheckBox` per column at relative width `0.12`,
then an `InteractiveLabel` taking the rest less `0.02` (less `extraColumn`'s width too, when given),
then the extra column's cell when `spec.extraColumn` is set. The label gives back `0.02` for the
reason `BUTTON_PAIR_REL` sits under half: the widget ending at the right edge is clipped by the
ScrollFrame (options-ui-§8).

- **Through W16** each cell carried `SetType("radio")` and drew the client's own radio dot.
  **From W17 through W18** the cell was an ordinary `CheckBox` whose check region was painted with
  a solid yellow (`1, 0.82, 0`) fill instead, with a W18 `OnRelease` restore to keep the paint from
  leaking into the next `CheckBox` AceGUI's pool handed out (see the W18 entry of
  [What changed at this version](#what-changed-at-this-version) for the leak it fixed). **From
  W19**, the fill and its restore are both gone — a lit cell is AceGUI's own default checkmark, no
  different from any other checked `CheckBox` in a host's panel. The cell stays an ordinary
  `CheckBox` rather than reverting to `SetType("radio")`. The one-choice-per-row exclusivity below
  never lived in the widget and has not moved at any point across W16–W19.
- A cell is lit while `read(row) == column.value`, and each cell's refresher re-lights it. A stored
  value no column carries lights **none**.
- A click on an unlit cell writes `column.value` through the row's seam, whose `set` runs
  `RefreshScalars`, so every cell on the line re-syncs to exactly one lit.
- A click on the lit cell writes nothing and re-lights it. AceGUI toggles a checkbox on every click.
- `disabledIf` dims the row's cells **and** its label, and both re-evaluate on refresh. It does not
  reach `extraColumn`'s cell, which is host-drawn.
- Each line is guarded as a flow row is: a row whose `get` raises is reported through
  `lib.STRINGS.ROW_FAILED`, costs that line, and is left out of the return.

It returns the row lines in row order, not the header. With no AceGUI or scroll it returns nil and
draws nothing.

## The id input and the id list

New at `OptionsWidgets.lua` minor 16. **From minor 17**, an entry may carry `note = <string>`. The host owns storage. None of these writes a path: the
widgets call back, and the host keeps whatever stored shape it has.

### `O.ResolveId(kind, text, candidates)` → `id, name, icon` or `nil, reason`

Pure, and needs no ctx. `text` is trimmed first, and a number `text` is taken as its string.

| Step | Resolves | Kinds |
|---|---|---|
| 1 | a number, `^(%d+)$` | all |
| 2 | a link of the kind's own type — `|Hspell:123:…`, `|Hitem:123:…`, `|Hcurrency:123:…` — or the bare `spell:123` / `item:123` / `currency:123`. An item link typed into a spell list is not a spell. | spell, item, currency |
| 3 | the client's name lookup: `C_Spell.GetSpellInfo(name)` → `spellID`; `C_Item.GetItemInfoInstant(name)` → the first return. The item lookup answers only for an item the player carries or carried this session, the spell lookup only for a spell in the player's spellbook. A hit that a **different** id also carries → `"ambiguous"`, whether that id is a candidate or one the client enumerates for the kind (an item in the bags, a spell in the spellbook). | spell, item |
| 4 | a case-insensitive exact name over the ids `candidates()` returns, named through the kind's own id lookup. Two **distinct** ids with the name → `"ambiguous"`; one id listed twice is one. | spell, item, currency |

`reason` is `"empty"`, `"notFound"` or `"ambiguous"`. A number the client cannot name still
resolves, with no name: that is the degraded mode. Every client API is read at call time and
guarded, so with no `C_Spell` or `C_Item` a number or a link resolves, a name finds nothing, and
nothing raises. A raising `candidates()` costs step 4 and is not reported.

**A shared name is ambiguous at step 3 too.** The client answers one id for a name several share,
such as an item's crafted-quality ranks. Its hit alone would add a rank the player did not pick, so
a different id with the same name makes it `"ambiguous"`: a candidate, or an id the client
enumerates for the kind, which is the same source the suggestions list (every item in the bags for
`"item"`, the spellbook for `"spell"`). Two quality tiers of one potion in the bags are refused with
no candidates at all. A candidate the client
cannot name yet (an uncached item) is not a match here, which is what `O.IdInput`'s lookup is for:
it names the unnamed candidates before it takes a name's result, the client's hit included.

`kind`:

| `kind` | Id → name, icon | Tooltip |
|---|---|---|
| `"spell"` | `C_Spell.GetSpellInfo(id)` | `GameTooltip:SetSpellByID` |
| `"item"` | icon from `C_Item.GetItemInfoInstant(id)` (no cache needed), name from `C_Item.GetItemNameByID(id)` (cache needed) | `GameTooltip:SetItemByID` |
| `"currency"` | `C_CurrencyInfo.GetCurrencyInfo(id)`; an empty name is the client's answer for an id it does not have | `GameTooltip:SetCurrencyByID` |
| a host table | `{ resolve = function(text, candidates) -> id, name, icon \| nil, reason; info = function(id) -> name, icon; noun; plural; tooltip = function(tooltip, id) or a GameTooltip method name; loads = bool }`. `resolve` replaces all four steps, is handed the trimmed text and `candidates`, and is `pcall`'d — a raise or an unknown reason reads as `"notFound"`. `loads = true` with an `info` says its ids are items the client loads: `IdInput` then pre-warms and looks up its candidates as it does `"item"`'s. `base = "item"` (or `"spell"`, `"currency"`) says its ids are that kind's — see below. A resolver that hands a name on to `O.ResolveId("item", text, candidates)` gets the shared-name check too. | as given, else the base's |
| anything else | numbers only | none |

#### A host kind based on a library kind: `base`

A host kind keeps its own `resolve` for what the library cannot know: an existence check, a
refusal when there is nowhere to file an id, a stored shape of its own. Its ids may still be one
library kind's. `base` says which: `"item"`, `"spell"` or `"currency"`. Any other value, or none, is
no base, and the kind behaves exactly as a host kind without one.

| A based host kind gets | From the base |
|---|---|
| fields it does not set itself | `info`, `link`, `tooltip`, `loads`, `noun`, `plural`. A field the host sets wins, `false` included, so a host that sets `info = false` to show no list keeps showing none. |
| its name color | an item's quality color, on the suggestion rows and on `IdList`'s entry names. A spell's and a currency's are plain. |
| its rank label | an item's crafted or reagent quality tier icon, a spell's subtext, on the suggestion rows. |
| its client source (**W26**) | the ids the base enumerates — the bags for `"item"`, the spellbook for `"spell"`, none for `"currency"` — listed in the suggestions after the host's own `candidates()`, and read by the shared-name check. |
| its tooltip | `GameTooltip:SetItemByID` / `SetSpellByID` / `SetCurrencyByID` on `IdList`'s entries, unless the host sets `tooltip`. |
| pre-warm and lookup | as `"item"`'s, when the base is `"item"` (its `loads` and `info`) or the host sets `loads = true` and an `info` itself. |

What it does **not** get: the base's client name lookup (`C_Item.GetItemInfoInstant(name)`,
`C_Spell.GetSpellInfo(name)`). What a host kind **resolves** stays its own — a typed name reaches
its `resolve` and its `candidates()`. A resolver that wants the client's lookup hands a name to
`O.ResolveId("item", text, candidates)`, as before. A based kind with no `resolve` resolves a
number, a link of the base's type, and a name over its candidates.

Before **W26** a based kind got no client source either, so a host that passed its own kind for
nothing but the entry tooltip lost the spellbook from its add box. It gets it from W26. A kind with
no `base` still gets none: that is how a host whose ids are not the client's opts out.

**The host still decides what is added.** A pick from a based kind's suggestions is handed to its
`resolve` first, as the id's digits with the same `candidates`. A refusal adds nothing, keeps the
typed text, and writes the reason on the status line as a submit's refusal does (`No item named
'191396'.` with the default words). An id the resolver answers is the one added. A host kind
without a base adds a picked row's id as it stands, as it always has.

`base` is read on every use, so a kind that reads its fields through to whichever type a host
dropdown names (ConsumableMaster's Item / Spell choice) changes base with it.

```lua
local kind = setmetatable({
  resolve = function(text, candidates) return myResolve(text, candidates) end,
}, { __index = function(_, key) return currentType()[key] end })   -- currentType().base = "item"
```

### `O.UnnamedCandidates(kind, candidates)` → ids

Pure, and needs no ctx. It returns the ids `candidates()` returns that the client cannot name
yet: numbers only, each once, in the host's order, at most **200** (`ID_LOOKUP_CAP`). The cap
exists because a host's candidate list can be a whole bag or an expansion's consumables, and asking
for thousands of items at once floods the client's item-data queue for one typed name. `IdInput`
moves past the cap itself: its pre-warm and its lookup work in windows of 200 (below).

It returns an empty table for a kind the client does not load (`"spell"`, `"currency"`, a host
table with neither `loads = true` and an `info` of its own nor `base = "item"`, or anything else),
for a raising or absent
`candidates`, and on a client without
`C_Item.GetItemNameByID` or `C_Item.RequestLoadItemDataByID`. An id whose name lookup raises reads as
named, so it is not asked for.

### `O.ID_NAME_HINT`

A table of the default name hints, one per named kind, for a host to reuse in the input's tooltip:

| Key | Default |
|---|---|
| `item` | `Names work for items you carry (or carried this session) and ones this list knows; otherwise use the id or shift-click a link.` |
| `spell` | `Names work for spells in your spellbook and ones this list knows; otherwise use the id or shift-click a link.` |
| `currency` | `Currency names work only for the currencies this list knows; otherwise use the id or shift-click a link.` |

Each instance gets its own copy, so a host that rewrites an entry changes its own table and no other
host's. The widgets never read it: they read `spec.strings.nameHint`, then these defaults. A host with
a locale passes its translation as `spec.strings.nameHint`, and uses the same string in its tooltip.

### `O.IdInput(ctx, parent, spec)` → group, editBox, button, status

One line, into `parent`, which is the page's scroll when nil: an AceGUI `EditBox` at relative width
`0.78`, with its own Okay button turned off through `DisableButton(true)` where the widget has it,
an Add `Button` at `0.20`, and a full-width status `Label` under both. The two sum to `0.98` for the
clip reason above.

| `spec` field | Meaning |
|---|---|
| `kind` | As `ResolveId`'s. |
| `onAdd` | `function(id)`, called once per successful add. A raise is reported through `lib.STRINGS.BUTTON_FAILED` and counts as a failure: the text stays. |
| `candidates` | Optional `function() -> ids`, searched by name at step 4 and handed to a host kind's `resolve`. For `kind = "item"`, or a host kind with `loads = true` and an `info` (its own, or from `base = "item"`), the unnamed ones are pre-warmed and looked up (below). The suggestions list them first (below). It may be called at every draw, every submit, and a render's first keystroke. |
| `label`, `tooltip` | The edit box's label, and the tooltip on both widgets. |
| `strings` | Optional overrides of the words, by key — see below. |
| `disabled` | Optional; draws both widgets disabled. A disabled render is inherited. |

Enter in the box, or Add, resolves the trimmed text. Success clears the box and the status line,
then calls `onAdd(id)`. The clear comes first so that `onAdd` may redraw the page synchronously: a
redraw releases both widgets into AceGUI's pool, where the new render may take them, and nothing
touches either widget after `onAdd` returns. A raising `onAdd` adds nothing, so the text and the
status line go back as they were. Failure writes the reason on the status line in orange
(`1, 0.5, 0`), keeps the text, and calls nothing. **It redraws nothing after an add**: a host that
draws its own rows redraws them itself. It returns nil, drawing nothing, with no AceGUI.

**Unnamed item candidates.** The client has no item-name search, and a candidate it has not cached
has no name for step 4 to match, and the client's own hit at step 3 cannot be checked against
it. Two things cover that, both only for `kind = "item"` (or a host kind with `loads = true` and
an `info`) with `candidates`, and both inert on a client that cannot load an item:

- **Pre-warm.** Drawing the input asks the client for the unnamed candidates, at most 200 a build.
  Each id is read once a session per instance, however many renders draw it, and the next build
  moves on past the ids the last one read, so a redraw rescans nothing. Nothing waits on it.
- **Lookup.** A typed **name** — one that resolved to an id or to `"notFound"` — while some
  candidates are still unnamed is not settled yet: the client's hit may be the one rank in the bags
  of a name whose other ranks are not cached. The unnamed ids are asked for as one window of at
  most 200, and the status line reads `looking` in a neutral color (`1, 1, 1`). The window is
  checked 0.4 s later. While any id it asked for is still unnamed, and fewer than five asks have
  run, the unnamed ones are asked for again. An id still unnamed then is **dead**: this instance
  skips it from then on, so retired or invalid ids cannot hold the window. The next window takes
  the unnamed candidates after them, up to five windows a lookup; the next Enter carries on past
  those. Then the same text is resolved **once** more: it adds as a normal submit does, or writes
  the normal reason in orange — `"ambiguous"` for a name several ranks share, so one rank is never
  added silently. It waits for every id rather than retrying when the first lands, because a name
  several ranks share would otherwise add whichever rank landed first. A number or a link names one
  id and never waits. The asks go through `LibKa0s-Item-1.0`'s `LoadItem` when it is loaded, else
  `C_Item.RequestLoadItemDataByID` with `C_Timer.After`. `O.ResolveId` itself stays pure and
  synchronous.
- **What drops a lookup.** A second submit replaces it. A box the player has typed over by the check
  drops it and clears the looking line. A released edit box (`OnRelease`) drops it without touching
  either widget, because AceGUI's pool may have handed them to another page.

#### Suggestions while typing

New with issue #31. While the player types, a dropdown under the box lists the entries whose name
or id matches the text: at most **10** rows, each the entry's icon, its name (an item's in its
quality color, as `IdList` draws it), its rank where it has one, and its id in gray. A longer list
ends in a line that is not a choice, `+N more` (the `more` word). The list is worked out 0.1 s after
the last keystroke, for the text then.

| Typed (trimmed) | Matches |
|---|---|
| digits, one or more | the ids that start with them, ascending |
| two characters or more | names, case-insensitive, in four tiers: 1 the whole name; 2 the name starts with the text; 3 a word inside the name starts with it; 4 the text appears anywhere in it |
| one character that is not a digit | nothing |

Within a tier: shorter names first, then by name (case-insensitive), then by rank ascending (an
entry with no rank counts as 0), then by id ascending. **Every rank is its own row.** Ids that share
a name tie on everything before rank, so they sit together, each labeled with its rank:

| Kind | Rank label | Read from |
|---|---|---|
| `"item"` | the client's tier icon, inline: `\|A:Professions-Icon-Quality-Tier<N>-Small:14:14\|a` | `C_TradeSkillUI.GetItemCraftedQualityByItemInfo(id)`, else `C_TradeSkillUI.GetItemReagentQualityByItemInfo(id)` |
| `"spell"` | the client's subtext as the client words it (`Rank 2`, `Racial`), sorted by the number in it | `C_Spell.GetSpellSubtext(id)` |
| a host table with `base` | its base's, above | as its base |
| anything else | none; the gray id tells two rows apart | — |

**Where the rows come from.** The client has no name search, so every row is an id something
already knows:

| Kind | Sources |
|---|---|
| `"item"` | `candidates()`, then every item in the backpack and the equipped bags, through `C_Container.GetContainerNumSlots` / `GetContainerItemID`: bags `0` to `NUM_TOTAL_EQUIPPED_BAG_SLOTS` (the reagent bag included), else to `NUM_BAG_SLOTS`, else to `4` |
| `"spell"` | `candidates()`, then the Spell and FutureSpell slots of the player's spellbook through `C_SpellBook` (`GetNumSpellBookSkillLines`, `GetSpellBookSkillLineInfo`, `GetSpellBookItemInfo`); a flyout or a pet action is never listed |
| a host table with `base = "item"` or `base = "spell"` (**W26**) | `candidates()`, then its base's source above |
| `"currency"`, a host table with `base = "currency"`, or a host table with no base | `candidates()` alone |

A kind with no `info` (a host table without one, or no kind) has nothing to name a row with, and
suggests nothing. Every source is read at call time and guarded: a client without one, a raising
`candidates()` or a raising lookup costs that source and nothing else.

**Cost.** A render's index is built on its first keystroke: the ids, each once, the host's first,
at most **2000**, each named once through the kind's `info`. Every later keystroke scans those
cached names with no client call, and re-reads at most 200 of the ids the client could not name
yet. So an uncached item candidate, which the pre-warm asked for, joins the list once it lands. A
redraw builds a fresh index.

**Choosing.** A click on a row, or Up/Down to highlight one and then Enter, adds that row's id
exactly as a typed add does: the box and the status line are cleared, then `onAdd(id)` runs, then
`IdList`'s rebuild. A pick names one id, so no lookup runs. A host kind with a `base` asks its own
`resolve` about the id first, and a refusal adds nothing (see
[`base`](#a-host-kind-based-on-a-library-kind-base)). Up and Down wrap. From no highlight,
Down takes the first row and Up the last. The `+N more` line is never highlighted. **Enter with no
row highlighted submits the typed text as it always has**, so a name several ranks share is still
refused as `"ambiguous"`: never one rank added for the player, and never all of them, whether the
ranks come from `candidates()`, the bags or the spellbook. Add submits the typed text too. A
keystroke drops the highlight at once, so Enter inside the 0.1 s pause never takes a row of the old
text's list that the new text no longer matches.

**A refused shared name lists its ranks.** When a submit, or a lookup's last try, refuses the text
as `"ambiguous"`, the dropdown opens for that text at once. So the list the refusal points at
(*pick one from the list*) is on screen, even when Enter came inside the 0.1 s pause and the list
had never shown. A refusal from Add hands the box the keys first, so Up, Down and Enter reach the
list. Enter again with nothing highlighted refuses again. A box the player has left by the time a
lookup refuses is not handed the list; it comes back when focus returns to the box while it still
holds the name.

**Closing.** Escape, focus leaving the box, the box hiding with its panel, the box's release (a
redraw), a submit the list cannot help, and text that matches nothing all close it. The first four
also drop an update still waiting on the debounce, whether or not the box shows the dropdown yet,
so a list never goes up under a box the player has left. A hidden box suggests nothing until its
panel shows again. Focus lost while the pointer is on the dropdown keeps it open, because a click
on a row is on its way. The box takes the keys back on the next frame unless a pick has closed the
list, so after a click on the backdrop or the `+N more` line, Escape still reaches it. A release
also lets the render's index and list go, because AceGUI keeps the pooled frame the hooks map to the
box. A released box never suggests again, even when another instance draws its pooled frame and the
first instance's hooks still fire on it.

**The frame.** One dropdown per instance, built the first time it shows and shared by every
`IdInput` the instance draws. Its ten rows and the more line are built with it and reused, so a
redraw builds no frame. It is parented to `UIParent` at `FULLSCREEN_DIALOG` strata, clamped to the
screen and anchored under the box's input, so the panel's scroll frame cannot clip it. Its width is
the box's, converted to the dropdown's own scale. These are plain frames with nothing protected, so
none of it is refused in combat. The keys come from hooks on AceGUI's `EditBox` input frame
(`widget.editbox`: `OnArrowPressed`, `OnEscapePressed`, `OnEditFocusLost`, `OnEditFocusGained`)
and `OnHide` on the widget's frame. Each is hooked once per frame, because AceGUI pools its
widgets, and acts for the box that frame was drawn for last; the arrows act only while that box
owns the dropdown. Whether a hidden box is shown again is read from its frame's `IsVisible()`
rather than hooked, because AceGUI's EditBox sets its own frame's `OnShow` script. A host AceGUI
without the input frame gets no keys, and a click still picks.

**What the host does.** Nothing, to get the dropdown. To list ids the client does not enumerate,
such as every consumable a host knows with all its ranks, pass `candidates`.

**Limits a host should know.**

- **No candidates, no rows beyond what the player carries.** A shared name the player does not
  carry, such as ConsumableMaster's *Potion of the Hushed Zephyr* with no rank in the bags, lists
  nothing until the host passes `candidates` naming its ranks.
- **The suggestions never ask the client to load an id.** They re-read what the input's pre-warm
  asked for, at most 200 candidates a build. A host with more uncached candidates than that may not
  list the later ones on a session's first draw; each redraw asks for the next 200.
- **The index is built once per render.** A bag change, or an id outside the index that the cache
  names later, shows at the next redraw.

**Check in game** (the headless suite cannot observe these): the dropdown draws above the Settings
panel; the tier atlas renders inline; `OnArrowPressed` reaches AceGUI's EditBox for Up and Down; a
click on a row picks after the box has lost focus; the box takes focus back after a click on the
backdrop; `C_SpellBook`'s enumeration lists the spellbook; the width matches the box on a scaled
panel; how long *Looking up items...* reads on a session's first Enter of a name for a host with
thousands of uncached candidates. That wait is bounded at five windows of five 0.4 s asks, about
10 s, and it holds even for a name that already resolved to one id, until the retired ids are
marked dead. Known cosmetic gap: the dropdown is parented to `UIParent` and anchored to the box, so if
the page scrolls while it is open it follows the box past the scroll frame's clip edge.

The words, and their defaults. `{name}` tokens rather than format specifiers, so a translation can
reorder them:

| Key | Default |
|---|---|
| `add` | `Add` |
| `remove` | `Remove` (IdList) |
| `empty` | `Type an id, a link or a name.` |
| `notFound` | item: `No item named '{text}' that the game can find. {hint}`; spell: `No spell named '{text}' in your spellbook. {hint}`; currency: `No currency named '{text}' that this list knows. {hint}`; a host kind (with a `base` or without) or none: `No {noun} named '{text}'.` |
| `ambiguous` | `Several {plural} are named '{text}' — pick one from the list, or use the id.` |
| `looking` | `Looking up {plural}...` (the lookup's status line; **W19**: plain ASCII ellipsis, `localization-§5`) |
| `nameHint` | The kind's entry in [`O.ID_NAME_HINT`](#oid_name_hint); empty for a host kind. Fills `notFound`'s `{hint}`. |
| `unknown` | `Unknown {noun} {id}` (IdList) |
| `more` | `+{count} more` (the suggestions' last line; `{count}` is how many were left out) |

`{noun}` / `{plural}` are `spell`/`spells`, `item`/`items`, `currency`/`currencies`, a host
kind's own `noun` / `plural`, or `entry`/`entries`. `{text}` is the trimmed text. `{hint}` is the
`nameHint` word, so a host that overrides `nameHint` alone changes the hint inside the default
`notFound` as well.

### `O.IdList(ctx, spec)` → lines or `nil`

Everything `IdInput` takes, plus:

| `spec` field | Meaning |
|---|---|
| `entries` | `function() -> ordered { { id =, note = string?, suffix = string?, toggle = bool?, on = bool? }, … }`. `note`: **W17**, `suffix`: **W25** — both below. A raise is reported through `lib.STRINGS.ROW_FAILED` and costs the lines, not the input. |
| `onRemove` | `function(id)`, from an entry's Remove or X. |
| `onToggle` | `function(id, on)`, from a toggle entry's checkbox. |
| `heading` | Optional section heading, drawn with `O.Section` and recorded as `ctx.lastGroup`. |
| `emptyText` | Optional line drawn, through `O.TextRow`, when there are no entries. |
| `toggleLabel` | Optional label beside a toggle entry's checkbox. |
| `removeStyle` | **W21**. Optional. `"icon"` draws a 16px X (`transmog-icon-remove`) at the LEFT of every entry in place of the right-hand Remove button or checkbox; a click calls `onRemove` and rebuilds; its tooltip is the `remove` string. Absent, the list is drawn as before. |
| `columns` | **W24**. Optional, default `1`. Entries per line, packed row-major — `1 2` / `3 4` / `5 6`. Every relative width is divided by it and a gutter separates each entry from the next, so the line still sums to `0.98`. Floored and clamped into `1..2` — see [What changed at this version](#what-changed-at-this-version) for the arithmetic and for what is and is not known about the width it is measured against; a non-number reads as `1`. An entry with a `note` takes a full-width line of its own whatever the count. At more than one column a name **does not wrap**: every entry is one line tall, and a name too long for its column is truncated by the client, which cuts the tail — and the tail is the gray `(id)`, so a truncated entry shows no id. The hovered entry is lit, so the row's tooltip has a visible owner. At one column the name wraps exactly as at W23. A `suffix` is the FIRST thing that truncation takes, before the id — see [What changed at this version](#what-changed-at-this-version) for the order and for the character budget. |

It draws into the page's scroll: the heading, the input line, then one line per entry, guarded per
entry. Each entry line has an `InteractiveLabel` at `0.78` and the action at `0.20`. **From W21**,
`removeStyle = "icon"` draws an `Icon` X first — in an absolute `26px` frame around its `16px` art,
so the frame can never be narrower than the texture it carries and the art is not flush against the
entry's own icon — then the `InteractiveLabel` at `0.90`, and no
action. **From W24**, `columns` puts that many entries in one line and divides each of those
relative widths by it — `0.37`, `0.10` and a `0.02` gutter at two columns, `0.43` for the name in
the icon style —
and the last line of an odd count is left half filled rather than stretched. The label shows
the entry's icon (16px), its name, and its id in gray, or `Unknown <noun> <id>` when the kind cannot
name it. An **item**'s name is drawn in its quality color: `C_Item.GetItemQualityByID(id)` through
the client's `ITEM_QUALITY_COLORS[quality].hex`, both read at draw time. An item whose quality the
client does not answer yet, or whose quality has no palette entry, is drawn plain. An uncached item
has no name to color, and the redraw its load triggers colors it. Spell and currency names, and a
host kind table's, are drawn plain. Hovering it shows the client's own tooltip for that kind.

**From W17**, `entry.note`, when it is a non-empty string, draws a second full-width `Label` under
the name — the same `ID_GRAY` the id already uses, its own line rather than a suffix because a
note is a sentence and a name is a name — for a host that has something to say about why the entry
is, or is not, actually in effect (AuraMaster's filter rules, for example). An entry with no
`note`, or one that is not a string or is empty, draws nothing extra: byte-for-byte what W16 drew.
**From W24** a noted entry takes a full-width line of its own inside a multi-column list, at the
one-column widths, and anything half-packed is flushed ahead of it: a second line under a name
cannot share a Flow row with a neighbor, and the note's own contract is worth more than the pairing.

**From W25**, `entry.suffix`, when it is a non-empty string, is appended to the entry's own label
after the gray `(id)` and in that same gray — `Renewing Mist |cff808080(119611)|r
|cff808080(also in 1)|r`, which reads `Renewing Mist (119611) (also in 1)`. It is the LIGHT option
beside `note`: bytes on a `FontString` rather than a second `Label`, so it adds no line, costs a
shared row nothing, and leaves a suffixed entry free to pair up under `columns`. Use `note` for a
sentence and `suffix` for a few words; an entry may carry both, and then the note still takes its
full-width line and the suffix still rides the name. The suffix is concatenated and never formatted,
so a `%`, a `%%` or a `|c` in it reaches the client exactly as the host wrote it. Anything that is
not a non-empty string draws nothing extra: byte-for-byte what W24 drew. An entry the kind cannot
name gets the suffix after `Unknown <noun> <id>` instead. Because it lengthens the same string the
no-wrap rule truncates at more than one column, it is the first thing to go from an entry that
overruns its column — the order and the character budget are in
[What changed at this version](#what-changed-at-this-version), and the full story belongs in the
entry's tooltip, which the host owns.

The action is Remove, or a `CheckBox` for a `toggle` entry (a starter the host can switch off
without forgetting it), lit by `on`.

- **Redraws.** After an add, or a Remove whose `onRemove` returned, the list redraws through
  `ctx.rebuild` when the host set one, and otherwise through `O.RefreshAllPanels()`, which is
  structural, because the set of lines changed. A toggle redraws nothing.
- **Uncached items.** An item the client cannot name yet is asked for through
  `LibStub("LibKa0s-Item-1.0", true).LoadItem`, looked up at call time. `LoadItem` does not wait
  for the item: it fires its callback 0.4 s after the request whether the item arrived or not. So
  every id one render asks for joins one batch per page, and the batch is checked once, by the
  first id's callback. If any of them is named by then, the list redraws once. Twenty uncached ids
  cost one check and at most one redraw, not twenty. An id still unnamed is asked for again in a
  fresh batch, up to five asks per id per instance (two seconds), and after that it stays
  `Unknown item <id>` until some other redraw finds it named. Without the Item major the entry
  stays unnamed, and nothing raises.

It returns one line per entry **drawn**, in entry order; an entry that failed to draw has none.
**From W24**, where entries share a line the same row object is returned once per entry in it, so
`lines[i]` is still the row carrying the i-th drawn entry. A raise inside one entry is reported
through `lib.STRINGS.ROW_FAILED` against that entry's id and costs that entry alone: the shared row
is rolled back to what it held before, and the entries after it keep packing. It returns nil,
drawing nothing, with no AceGUI.

## Row fields the flow engine reads

Beyond `path`, `type`, `label`, `default` and the tooltip body — `tooltip`, which is what every
Ka0s host's schema declares, or `desc`, this library's own name for it; both are read:

| Field | Since | Meaning |
|---|---|---|
| `group` | W1 | Section heading. A new value emits a `Section` and flushes the row in progress. |
| `solo` | W1 | Render alone in the left half of its own line, for visual pivots. |
| `subgroup` | **W13** | A heading drawn **inside** a group, through `O.Section` (options-ui-§7). Emitted whenever the value changes within a group, and cleared at every group boundary so the same name under two groups draws twice. **Not** suppressed by `opts.noHeadings`, which covers the group heading only: a tab that mixes control types has to name each block, and the tab label is already spent on the section. |
| `wide` | **W13** | Render alone at **full** width, spanning both columns. Not what `solo` does — `solo` renders alone in the left half — and it shares `RenderGrid`'s field name and meaning rather than redefining `solo`. |
| `startsLine` | **W13** | Flush the pending line **before** this row, so a declared two-row pair lands as `[left][right]` and can never be split by an odd number of preceding widgets. |
| `skipRender` | W1 | Keep the row in the schema — so resets and the CLI still see it — but let the host draw it bespoke. |
| `shownWhen` | **W22** | `{ path = <selector path>, equals = <value> \| { <value>, … } }`. Draw the row only while the selector (read like a `disabledIf` path) holds `equals`, or any value of an `equals` list; otherwise it is dropped from the render, its heading with it when its whole subsection is dropped. A raising read reads as shown. A selector drawn in the same `RenderRows` call is watched (by its `path`, or a bound row by its `field`), and a change re-renders the page once on the next frame — see [What changed at this version](#what-changed-at-this-version). **The page must declare a renderer (`O.SetRenderer`)**: without one the page keeps the section it first drew. **Switch subgroups, not a tabbed page's groups**: `RenderTabbedSchema` builds its tabs from the unfiltered rows, so a group dropped whole still gets a tab. The row stays in the schema. For a subsection a **dropdown** chooses; a single row a checkbox dims keeps `disabledIf`. |
| `min` / `max` / `step` | W1 | Slider range. Snapping is relative to `min`, not to zero. |
| `values` on a `number` row | **W5** | Makes it a **dropdown** rather than a slider, matching what `LibKa0s-Slash-1.0`'s parser has always understood the shape to mean. Inferred, not opted into — a `values` list that resolves empty falls back to the slider. |
| `values` / `sorting` | W1 (ordered-array shape: W3) | Dropdown list, in either shape: an **ordered array** of `{ value =, text = }` (position is the order, and `sorting` is ignored) or a **key map** `{ KEY = "Label" }` (`sorting` keeps a deliberate order instead of alphabetising). A degenerate key *set* `{ KEY = true }` labels each entry with its key. `values` may be a function, evaluated at render and parse time. |
| `dialogControl` | W1 | An in-tree widget type (`LSM30_*`, `EditBox`). Unregistered types fall back to a plain Dropdown, so an optional media-widget library staying absent costs a swatch, not the option. |
| `hasAlpha` | W1 | Color picker: alpha channel — **default true**, declare `false` to suppress it. |
| `disabledIf` | W1 (every maker, and the predicate form: **W16**) | Draw the row disabled while it holds. A **settings path** whose truth disables (a path-less row reads it through `row.get(key)`), or **from W16** a predicate `function(row) -> bool`, `pcall`'d, whose raise reads as enabled. Through W15 the color picker alone read it; from W16 the checkbox, slider, dropdown, edit box and color picker all do, at build and on every refresh. A row without it is never touched. **`disabledIf` must not be used for a class-color companion** (options-ui-§17, anti-patterns #74): the swatch is still read, for its alpha, so graying it says something untrue. No composed row carries it. |
| `classColorSource` / `classColorUnit` | **C1** | `"player"` or `"unit"`, plus the token where it is `"unit"`. Stamped on **both** rows of every composed color pair. The library reads neither — they are the declaration an audit reads, because a path prefix cannot be trusted to say whose class a control means (options-ui-§17). |
| `commitOn` | W1 | `"change"` makes this slider commit on the drag, throttled; `"release"` opts out of a descriptor-wide `sliderCommit`. Default is release-only. |
| `isPercent` | W1 | Slider renders a 0–1 ratio as a percentage. |
| `maxLetters` | W1 | Edit box only. |
| `get` / `set` | **W15** | On a row with **no `path`** only: the row is read with `row.get()` and written with `row.set(value)` instead of through the descriptor's `get` / `set`. `row.get(key)` with an argument reads another key on the row's behalf: the flow engine resolves a path-less row's `disabledIf` that way, and a composed row reads that field of the same record. What a composer's `spec.bind` produces; a hand-written record row may carry them too. A row that has a `path` is always read and written through the descriptor, whatever else it carries. |
| `field` | **C4** | On a row a composer bound with `spec.bind`: the record key the row reads and writes, exactly what its path would have been. The flow engine reads it to name the row in the empty-dropdown report, and as the row's `pairWith` key — `RenderRows` looks a partner up by `row.path or row.field` (**W15**). |

## The schema composers

New at `OptionsCompose.lua` minor 1. Five functions, each expanding one declaration into the
canonical block of **ordinary schema rows** — options-ui-§15 for the Master controls tab, §16 for the
font / border / bar groups, §17 for the class-color companion.

**They are pure functions.** No widget, no AceGUI, no state, and nothing the caller handed in is ever
written to — a host may hoist its spec, and its `extra` rows, to a file constant and re-render
freely. What comes out is indistinguishable from hand-written rows, which is what lets every existing
seam keep working unchanged.

**Since C4 a composer can also bind its rows to a registry record** (`spec.bind`, below). A bound
row is still an ordinary table and the composer still reads no state — the row's `get` and `set`
closures read and write the record when the flow engine calls them — but a bound row has no path, so
it is rendered directly and never put in the schema.

### The media rows, and what a host's own `LSMValues` must return

`FontGroup`, `BorderGroup` and `BarGroup` each carry one LSM-backed dropdown — `font`,
`borderStyle`, `barTexture` — and each assigns `O.LSMValues(<mediaType>)` **as** the row's `values`
(**C3**). Not a closure around it: `enumList` unwraps `values` exactly once, so a second wrapper
reaches it as a function and the dropdown comes back empty with no report.

That makes `O.LSMValues` part of the composer's contract rather than an implementation detail of one
row. A host that supplies its own — `__AttachCompose` reads the member off the instance it is handed
— **must return a function**. Return a table and the composer stores that table, frozen at the
moment the schema file loaded, before any addon that registers media has run. Nothing errors and
nothing warns; the dropdown simply never learns about anything registered later.

A host that overrides a composed row's `values` after the composer returns is unaffected, and so is
one that never touches `O.LSMValues` at all — which is every consumer that just calls the composers.

### The common spec

Every composer takes these, and each is optional except `page` and `group` in practice:

| Field | Type | Meaning |
|---|---|---|
| `prefix` | string | Path prefix, e.g. `"units.target."` or `""`. Each canonical row's path is `prefix .. leaf`. |
| `page` | any | Copied onto every row. |
| `group` | string | The tab name, copied onto every row. `MasterControls` defaults it to `"Master controls"`. |
| `subgroup` | string | The intra-tab heading, copied onto every row. |
| `order` | number | Order of the first row; each subsequent row `+10`. Ten, so a host can splice a row of its own between two canonical ones without renumbering either. Defaults to `0`. |
| `keys` | table | `{ <canonicalLeaf> = "myLeaf" }` — path-leaf overrides. **The composer must not change what is stored**, and this is the override that protects a live SavedVariables. |
| `labels` | table | `{ <canonicalLeaf> = "My label" }` — host-localised label overrides. |
| `defaults` | table | `{ <canonicalLeaf> = <value> }` — default overrides. |
| `omit` | table | `{ <canonicalLeaf> = true }` — leave the row out. The survivors stay contiguous, so an omission leaves no hole in the order. |
| `classColor` | table | `{ source = "player" \| "unit", unit = <token>, default = <boolean> }`. Stamped on both rows of every color pair. |
| `extra` | array | Rows appended **after** the canonical block, order continuing, copied rather than stamped in place. An extra declares its own `path` in full — or, under `bind`, its own record `field` (**C4**). |
| `bind` | table | **C4.** `{ set, get \| record }` — bind every row to a registry record instead of a settings path. See [The record-backed arm](#the-record-backed-arm-specbind). |

### The record-backed arm: `spec.bind`

New at `OptionsCompose.lua` minor 4, read by `OptionsWidgets.lua` minor 15.

| Field | Type | Meaning |
|---|---|---|
| `bind.set(field, value, row)` | function | **Required.** Write `value` to the record's `field`. The row is handed through so a bind can convert by `row.type`. |
| `bind.get(field, row)` | function | Read the record's `field`. Read the **live** record here, not one captured when the block was composed. |
| `bind.record()` | function | Instead of `get`: answer the live record, and `get` becomes `record()[field]`. |

What a bound row carries, in place of `path`:

| Field | Value |
|---|---|
| `field` | `(prefix or "") .. (keys[leaf] or leaf)` — or an extra's own `field` |
| `get` | `function() return bind.get(field, row) end` |
| `set` | `function(value) return bind.set(field, value, row) end` |

A missing `set`, or a bind with neither `get` nor `record`, raises when the block is composed.

#### Worked example: PanelMaster's three groups

`settings/PanelEditor.lua` in PanelMaster types out three `options-ui-§16` groups over a panel
record — at `b884ca8`, `:776-790` (the panel's border), `:818-838` (the accent bar) and `:852-866`
(the accent bar's own border); PanelMaster#48 cites the same three blocks at `:738-757`, `:770-800`
and `:814-830`, where they sat when it was filed. All three compose. `tests/test_options_compose.lua`
builds exactly these three blocks against a stand-in registry and asserts the field order, the
binding and a write through it, so this example is checked rather than illustrative.

```lua
-- Inside buildPanelEditor(ctx, parent, rec). `O` is NS.Helpers, the lib:New instance; `group`,
-- `editorRow`, `editorSpacer` and EDITOR_ROW_GAP are the editor's own, unchanged.

-- ONE bind for all three blocks. It reads the LIVE record by id -- a profile switch replaces the
-- panel tables, which is why the hand-written refreshers look the record up again -- and writes
-- through NS.Registry:Set, the registry writer architecture-§5 names. Panel colors are stored as
-- { r, g, b, a } arrays and the descriptor codec reads named keys, so the bind converts the one row
-- type whose shape differs.
local function recordBind(rec)
  local function live() return NS.Registry:Get(rec.id) or rec end
  return {
    get = function(field, row)
      local v = live()[field]
      if row.type ~= "color" then return v end
      local c = NS.Util.Color(v)
      return { r = c[1], g = c[2], b = c[3], a = c[4] }
    end,
    set = function(field, v, row)
      if row.type == "color" then v = { v.r, v.g, v.b, v.a } end
      NS.Registry:Set(rec.id, field, v)
    end,
  }
end

-- The editor draws into its own container, two controls to a line. A composed block's first and
-- third rows carry startsLine, so pairing them in twos IS the canonical layout.
local function renderBlock(rows)
  for i = 1, #rows, 2 do
    local line = editorRow(group)
    O.RenderField(ctx, rows[i], line, 0.5)
    if rows[i + 1] then O.RenderField(ctx, rows[i + 1], line, 0.5) end
    editorSpacer(group, EDITOR_ROW_GAP)
  end
end

-- Composed rows are fresh plain tables, so the page may retune one before drawing it. This
-- addon's border reaches C.MAX_BORDER (32), not the composer's 16, and its media lists come from
-- NS.Compat.MediaList, which carries its own 'Solid' and 'None', rather than from O.LSMValues.
local function mediaValues(kind)
  return function()
    local list = {}
    for _, name in ipairs(NS.Compat.MediaList(kind)) do list[name] = name end
    return list
  end
end

local bind = recordBind(rec)

-- 1. The panel's own border (TAB_SURFACE).
local border = O.BorderGroup{
  bind = bind,
  keys = { borderStyle = "borderTexture", borderSize = "borderSize",
           borderColor = "borderColor", useClassColorBorder = "borderClassColor" },
  extra = { { field = "borderOffset", type = "number", label = "Border offset",
              min = C.MIN_BORDER_OFFSET, max = C.MAX_BORDER_OFFSET, step = 1,
              tooltip = "How far the border sits from the panel's edge." } },
}
border[1].values = mediaValues("border")
border[2].max = C.MAX_BORDER
renderBlock(border)

-- 2. The accent bar (TAB_ACCENT). Its "Enable accent bar" toggle stays the page's own row above the
--    block: only a border's "Show border" may lead a composed block (options-ui-§16).
local bar = O.BarGroup{
  bind = bind,
  keys = { barTexture = "accentTexture", barAlpha = "accentAlpha",
           barColor = "accentColor", useClassColorBar = "accentClassColor" },
  extra = {
    { field = "accentThickness", type = "number", label = "Bar thickness",
      min = C.MIN_ACCENT_THICKNESS, max = C.MAX_ACCENT_THICKNESS, step = 1 },
    { field = "accentOffset", type = "number", label = "Bar offset",
      min = C.MIN_ACCENT_OFFSET, max = C.MAX_ACCENT_OFFSET, step = 1 },
  },
}
bar[1].values = mediaValues("statusbar")
renderBlock(bar)

-- 3. The accent bar's own border (TAB_ACCENT, after the Edges heading).
local barBorder = O.BorderGroup{
  bind = bind,
  keys = { borderStyle = "accentBorderTexture", borderSize = "accentBorderSize",
           borderColor = "accentBorderColor", useClassColorBorder = "accentBorderClassColor" },
  extra = { { field = "accentBorderOffset", type = "number", label = "Border offset",
              min = C.MIN_BORDER_OFFSET, max = C.MAX_BORDER_OFFSET, step = 1 } },
}
barBorder[1].values = mediaValues("border")
barBorder[2].max = C.MAX_BORDER
renderBlock(barBorder)
```

The three blocks come out as:

| Block | Fields, in order |
|---|---|
| Panel border | `borderTexture` · `borderSize` · `borderColor` · `borderClassColor` · `borderOffset` |
| Accent bar | `accentTexture` · `accentAlpha` · `accentColor` · `accentClassColor` · `accentThickness` · `accentOffset` |
| Accent bar border | `accentBorderTexture` · `accentBorderSize` · `accentBorderColor` · `accentBorderClassColor` · `accentBorderOffset` |

— the order the editor draws today, with the mandated four first and the addon's own rows after them.

**What adoption changes on screen, for PanelMaster to decide.** The canonical tooltips replace the
page's longer ones (a host may retune `tooltip` the same way it retunes `max`). *Bar opacity* renders
as a percentage, because the canonical row carries `isPercent`. And the swatch stops relabeling itself
*Border color (opacity)* while its companion is ticked: the composed swatch says the same thing in its
tooltip, in `O.CLASS_COLOR_NOTE`'s words, which is the form `options-ui-§17` fixes. The
`dd:SetValue(value)` push the hand-written media dropdown needs after an AceGUI-3.0-SharedMediaWidgets
change is not needed: the flow engine's `set` runs `RefreshScalars`, and the refresher re-applies
the value.

### `O.ColorPair(spec)` → rows

The primitive the three group composers are built out of, and what a host calls for a standalone
swatch. Additionally takes `key` (the swatch leaf, default `"color"`), `companionKey` (default
`"useClassColor" .. Key`), `label` (default `"Color"`) and `hasAlpha` (default true).

Returns **exactly two** rows: the swatch, carrying `startsLine = true`, and the `Use class color`
checkbox immediately after it — which is what puts the companion in the right-hand column and what
makes that placement impossible to break by inserting a row above the pair.

**Neither row ever carries `disabledIf`,** and that is a recorded reversal of two addons' shipped
behavior: the swatch's **alpha** is live under class color, so a grayed swatch is a lie. The swatch's
tooltip carries `O.CLASS_COLOR_NOTE` instead — *"Not read while Use class color is on, except for its
opacity, which always applies."*

### `O.FontGroup(spec)` → rows

Six leaves, in this order, landing as three lines:

| | |
|---|---|
| `font` (`LSM30_Font`) | `fontSize` |
| `fontColor` | `useClassColorFont` |
| `fontFlags` | `fontShadow` |

An even row count plus `startsLine` on rows 1 and 3 is what makes that layout parity-proof rather
than a property of how many rows happen to precede the block.

### `O.BorderGroup(spec)` → rows

`borderStyle` (`LSM30_Border`), `borderSize` (*Border thickness (px)*), `borderColor`,
`useClassColorBorder`. `spec.show = true` prepends `borderShow` (*Show border*), which is the only
thing that may lead the block. A border offset or anything else the addon legitimately has goes in
`spec.extra`, **after** the mandated rows, never interleaved.

### `O.BarGroup(spec)` → rows

`barTexture` (`LSM30_Statusbar`), `barAlpha` (*Bar opacity*, a percentage), `barColor`,
`useClassColorBar`.

**A group over a background is not a bar group.** A container with a backdrop and no fill texture
takes `O.ColorPair` and nothing else; inventing a texture picker for a surface that has no texture is
a control wired to nothing.

### `O.MasterControls(spec)` → rows, afterGroup

The canonical General-page tab (options-ui-§15). Additionally takes `addonName` (for the *Enable*
label), `frameless`, `debugConsolePath` (default `"state.debugConsole"`), `onResetPosition`,
`onResetAll`, — since **C2** — `leadButton`, — since **C6** — `testModePath` and — since **C7**
— `minimapPath`.

| | |
|---|---|
| `enabled` — *Enable `<AddonName>`* | `visibility` — *General visibility* |
| `scale` — *Master scale* | `alpha` — *Master alpha* |
| `locked` — *Lock frame* | `debugConsole` — *Debug console* |
| `minimap` — *Minimap button* (only with `minimapPath`, **C7**) | `testMode` — *Test mode* (only with `testModePath`, **C6**) |
| *Reset position* (button) | *Reset all settings* (button) |

- **The set is canonical, not a menu.** An addon includes every row that applies to it and must not
  reorder, rename or split them.
- **`frameless = true` omits exactly the frame-only rows** — `scale`, `alpha`, `locked`, and the
  *Reset position* button — and nothing else. General visibility stays: `Never` is a meaningful
  master off-switch distinct from *Enable*. A frameless addon must not invent a movable frame to fill
  the tab out.
- **`visibility` is a dropdown**, over `O.VISIBILITY_VALUES` / `O.VISIBILITY_SORT`. An addon shipping
  a *show only in combat* boolean migrates it (`true` → `"inCombat"`, `false` → `"always"`), because
  a boolean can only ever answer two of the four.
- **`debugConsole` is `sessionOnly`**, and its path is taken **verbatim** rather than prefixed:
  session state lives outside the block's own prefix.
- **`minimapPath`** (**C7**) adds the *Minimap button* row: a plain **stored** bool (no
  `sessionOnly`), `default = true`, `startsLine = true`, its path taken verbatim like the console's
  because `launcher-§3` keeps LibDBIcon's `minimap` table in the **global** store. The row says
  *shown* and LibDBIcon's key says *hidden*, so the host's get/set invert and call `Show` / `Hide`
  at its single write seam. Every Ka0s addon ships a launcher, so pass it — it is opt-in here only
  until the collection has finished adopting (`launcher-§5`).
- **`testModePath`** (**C6**) adds the *Test mode* row: `sessionOnly`, its path taken verbatim like
  the console's. Pass it exactly when the addon has a test mode that stays on until turned off
  (options-ui-§15); a one-shot test action is not one, and may take `leadButton`. Since **C7** it
  pairs in the **second** column beside *Minimap button*, and opens a line of its own only where the
  host passed no `minimapPath` (or omitted the `minimap` leaf).
- **`leadButton` = `{ text, tooltip, onClick }`** (**C2**) is ONE act of the host's own, closing the
  tab beside the resets. On a **frameless** addon it takes the pair's empty right half, so the row
  reads `[<verb>] [Reset all settings]`; on a **framed** addon, whose pair is already full and may
  not be split or reordered, it takes its own row **above** the pair. It exists so an addon never has
  to restate the reset's canonical wording in order to sit a button next to it.
- **The two resets are the tab's closing button pair**, not schema rows — they are acts rather than
  settings, so they would not belong in the CLI or in the reset sweep. The second return value is the
  `afterGroup` hook for the group; wire it as
  `H.RenderTabbedSchema(ctx, page, { ["Master controls"] = tail }, pairWith)`. The **group name is
  the hook key**, so renaming the group detaches the hook.
- **The *Reset all settings* tooltip comes from the descriptor, not the spec** (**C5**). Without
  `resetProfile` it reads *"Restore every setting in this addon to its default."*; with it, that
  the current profile is reset and other profiles are not affected; with `profilesPage` as well,
  that it is the same thing Profiles -> Reset Profile does (**O20**: plain ASCII arrow). See
  [Previously, at 18.15.5.3](#previously-at-1815553). *Reset position*'s tooltip is
  unchanged.

## Compatibility

**At 24.30.3.7.4 no member is added or removed**: the font preload moved file; `OpenOptionsPanel`
now returns a value where it returned none, which a host that ignored the result cannot observe; and
`CreateOptionsPanel` called in combat registers when combat ends rather than at once. That last one
is the only difference a host written against 23.30.3.7.3 can see, and only on a login or `/reload`
taken in combat: its category appears in the AddOns sidebar when the fight ends. A host suite that
pinned "registering during combat still registers" (WhatGroup's, for its WG-A-12 fix) now needs to
fire the end of combat first.

**At 23.24.3.7.3 one optional spec field is added** — `O.IdList`'s `columns` — and nothing is
removed or repurposed. A list that does not pass it draws what 23.23.3.7.3 drew, with one deliberate
exception a host can see: an icon-style list's X now sits in an absolute `26px` frame instead of
`0.06` of the row, and its name takes `0.90` instead of `0.92`, so that the frame can never be
narrower than the texture it carries at any column count and the delete control is not flush against
the entry's own icon. **At 23.25.3.7.3 one entry field is added and nothing else moves**: `entry.suffix` (**W25**), an
optional string drawn inside the entry's own label. A list whose entries do not carry it renders
byte-for-byte what 23.24.3.7.3 rendered, and `entry.note` is untouched. **At 23.24.3.7.3 one spec
field is added**, `columns` (**W24**); a list that passes none draws what 23.23.3.7.3 drew, except
in the icon style, where the X's frame became an absolute `26px` and the name beside it `0.90`.
**At 23.23.3.7.3 nothing is added either** — it narrows when the lock listens, and out of combat and with no page on screen it now does nothing at all. **At 22.23.2.7.3 no member, descriptor field or row field is added**, so a host written against
21.22.1.7.3 needs no change. What changes is behavior in combat, and only there: a page shown in
combat is covered instead of closing the settings window, and the refusals in
[What changed at this version](#what-changed-at-this-version) apply. Out of combat every page draws
and behaves exactly as at 21.22.1.7.3. The paragraphs below are the history as written at 21.20.1.7.3.

The API is **additive-only**: a member, descriptor field or row field may be added in a later minor,
never removed or repurposed, so a host written against `1.1.1` keeps working unmodified here. This
version adds **no member**. It moves the page's chrome into a fifth file, which changes the version
key and nothing a host calls, and it adds one `MasterControls` spec field, `minimapPath` (**C7**).
A host that passes neither `minimapPath` nor `testModePath` renders byte-identically to 20.19.6.3.

The one field that is **not** additive in the strictest reading is `startsLine` on the *Test mode*
row, which C6 always set and C7 sets only when no *Minimap button* row was emitted. It is a layout
hint on a composed row rather than a member, a descriptor field or a stored value, and the only host
that can observe the difference is one passing **both** paths — which no host could do before this
version, because `minimapPath` did not exist. A C6 adopter passing `testModePath` alone gets the row
it got.

The one field that is **not** additive in the strictest reading is `startsLine` on the *Test mode*
row, which C6 always set and C7 sets only when no *Minimap button* row was emitted. It is a layout
hint on a composed row rather than a member, a descriptor field or a stored value, and the only host
that can observe the difference is one passing **both** paths — which no host could do before this
version, because `minimapPath` did not exist. A C6 adopter passing `testModePath` alone gets the row
it got.
