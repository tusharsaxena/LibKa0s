# `LibKa0s-Options-1.0` — version 34.4.38.5.7.11.3.14.9.4.3.6.5.4.1.1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Options surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Options-1.0` |
| Files and minors | `Options.lua` **34** · `OptionsRegistry.lua` **4** · `OptionsWidgets.lua` **38** · `OptionsIds.lua` **5** · `OptionsIdList.lua` **7** · `OptionsTabs.lua` **11** · `OptionsCombat.lua` **3** · `OptionsCompose.lua` **14** · `OptionsScroll.lua` **9** · `OptionsNav.lua` **4** · `OptionsDrawer.lua` **3** · `OptionsKeybinds.lua` **6** · `OptionsAppearance.lua` **5** · `OptionsSkinPicker.lua` **4** · `OptionsSwitch.lua` **1** · `OptionsMedia.lua` **1** (new) |
| Version key | `<Options>.<OptionsRegistry>.<OptionsWidgets>.<OptionsIds>.<OptionsIdList>.<OptionsTabs>.<OptionsCombat>.<OptionsCompose>.<OptionsScroll>.<OptionsNav>.<OptionsDrawer>.<OptionsKeybinds>.<OptionsAppearance>.<OptionsSkinPicker>.<OptionsSwitch>.<OptionsMedia>`, in load order — the same fifteen numbers `lib.MODULES` reports. |
| Shipped in | v1.83.0 |
| Status | **Current** |
| Supersedes | [version 34.4.37.5.7.11.3.14.9.4.3.6.4.3.1](./version-34.4.37.5.7.11.3.14.9.4.3.6.4.3.1-docs.md) (shipped in v1.82.0): its Skin tab's font and texture rows were plain Dropdowns over media keys, and an unregistered `LSM30_*` row fell back to one |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`); `OptionsWidgets.lua` additionally requires `LibKa0s-Pool-1.0` minor ≥ 1 (`NEEDS_POOL = 1`), since 14.14.3.3. `OptionsRegistry.lua`, `OptionsIds.lua`, `OptionsIdList.lua` and `OptionsCombat.lua` declare no floor of their own, and neither do `OptionsDrawer.lua`, `OptionsKeybinds.lua` and `OptionsAppearance.lua` (which reads `LibKa0s-Skin-1.0` at call time, not as a floor). `O.IdList` uses `LibKa0s-Item-1.0`'s `LoadItem` when it is present, looked up at call time; it is not a floor, and without it an uncached item stays unnamed. `O.IdInput`'s pre-warm and name lookup use it too, and fall back to `C_Item.RequestLoadItemDataByID` with `C_Timer.After` without it; `OptionsNav.lua` requires `LibKa0s-Pool-1.0` minor ≥ 1 (`NEEDS_POOL = 1`), since 25.31.5.7.4.1. |
| Confirm in-game | `LibStub("LibKa0s-Options-1.0").MODULES` → `{ Options = 34, OptionsRegistry = 4, OptionsWidgets = 38, OptionsIds = 5, OptionsIdList = 7, OptionsTabs = 11, OptionsCombat = 3, OptionsCompose = 14, OptionsScroll = 9, OptionsNav = 4, OptionsDrawer = 3, OptionsKeybinds = 6, OptionsAppearance = 5, OptionsSkinPicker = 4, OptionsSwitch = 1, OptionsMedia = 1 }` |

`Since` in the tables below names the **file and minor** in which the member first appeared — `O21`
for `Options.lua` minor 21, `O22` for `Options.lua` minor 22, `O23` for `Options.lua` minor 23, `O24` for `Options.lua` minor 24, `O25` for `Options.lua` minor 25, `O27` for `Options.lua` minor 27, `O28` for `Options.lua` minor 28, `O29` for `Options.lua` minor 29, `O30` for `Options.lua` minor 30, `O31` for `Options.lua` minor 31, `O32` for `Options.lua` minor 32, `O33` for `Options.lua` minor 33, `O34` for `Options.lua` minor 34, `W20` for `OptionsWidgets.lua` minor 20, `W21` for `OptionsWidgets.lua`
minor 21, `W22` for `OptionsWidgets.lua` minor 22, `W23` for `OptionsWidgets.lua` minor 23, `W24` for `OptionsWidgets.lua` minor 24, `W25` for `OptionsWidgets.lua` minor 25, `W26` for `OptionsWidgets.lua` minor 26, `W27` for `OptionsWidgets.lua` minor 27, `W28` for `OptionsWidgets.lua` minor 28, `W29` for `OptionsWidgets.lua` minor 29, `W30` for `OptionsWidgets.lua` minor 30, `W31` for `OptionsWidgets.lua` minor 31, `W32` for `OptionsWidgets.lua` minor 32, `W34` for `OptionsWidgets.lua` minor 34, `W35` for `OptionsWidgets.lua` minor 35, `W36` for `OptionsWidgets.lua` minor 36, `T1` for `OptionsTabs.lua` minor 1, `T2` for `OptionsTabs.lua` minor 2, `T3` for `OptionsTabs.lua` minor 3, `T4` for `OptionsTabs.lua` minor 4, `T5` for `OptionsTabs.lua` minor 5, `T8` for `OptionsTabs.lua` minor 8, `T9` for `OptionsTabs.lua` minor 9, `T10` for `OptionsTabs.lua` minor 10, `T11` for `OptionsTabs.lua` minor 11, `C7` for `OptionsCompose.lua` minor 7, `C8` for `OptionsCompose.lua` minor 8, `C9` for `OptionsCompose.lua` minor 9, `C10` for `OptionsCompose.lua` minor 10, `C11` for `OptionsCompose.lua` minor 11, `C12` for `OptionsCompose.lua` minor 12, `C13` for `OptionsCompose.lua` minor 13, `C14` for `OptionsCompose.lua` minor 14, `S1` for
`OptionsScroll.lua` minor 1, `S4` for `OptionsScroll.lua` minor 4, `S5` for `OptionsScroll.lua` minor 5, `S6` for `OptionsScroll.lua` minor 6, `S9` for `OptionsScroll.lua` minor 9, `N1` for `OptionsNav.lua` minor 1, `N3` for `OptionsNav.lua` minor 3, `N4` for `OptionsNav.lua` minor 4, `D1` for `OptionsDrawer.lua` minor 1, `D2` for `OptionsDrawer.lua` minor 2, `D3` for `OptionsDrawer.lua` minor 3, `K1` for `OptionsKeybinds.lua` minor 1, `K2` for `OptionsKeybinds.lua` minor 2, `K3` for `OptionsKeybinds.lua` minor 3, `K4` for `OptionsKeybinds.lua` minor 4, `K5` for `OptionsKeybinds.lua` minor 5, `K6` for `OptionsKeybinds.lua` minor 6, `A1` for `OptionsAppearance.lua` minor 1, `A3` for `OptionsAppearance.lua` minor 3, `A4` for `OptionsAppearance.lua` minor 4, `P1` for `OptionsSkinPicker.lua` minor 1, `P2` for `OptionsSkinPicker.lua` minor 2, `P3` for `OptionsSkinPicker.lua` minor 3, `I1` for
`OptionsIds.lua` minor 1, `I3` for `OptionsIds.lua` minor 3, `I4` for `OptionsIds.lua` minor 4, `I5` for `OptionsIds.lua` minor 5, `OC2` for `OptionsCombat.lua` minor 2, `OC3` for `OptionsCombat.lua` minor 3, `L1` for `OptionsIdList.lua` minor 1, `L3` for `OptionsIdList.lua` minor 3, `L4` for `OptionsIdList.lua` minor 4, `L6` for `OptionsIdList.lua` minor 6, `L7` for `OptionsIdList.lua` minor 7, `SW1` for `OptionsSwitch.lua` minor 1. **A `W`
citation on a chrome member is not stale**: `O.TabStrip`, `O.PageBanner`, `O.PageHeader`,
`O.SubTabStrip` and the four geometry seams were `OptionsWidgets.lua`'s until 21.20.1.7.3 and are
`OptionsTabs.lua`'s from it, with no change to what any of them does; `O.RenderTabbedSchema` (**W9**)
moved the same way at **T4**, and so did the id surface at **I1** and **L1**: `O.ResolveId`,
`O.UnnamedCandidates`, `O.ID_NAME_HINT` and `O.IdInput` are `OptionsIds.lua`'s and `O.IdList` is
`OptionsIdList.lua`'s from 25.32.1.1.5.7.4.1, and every `W` citation on them still names the minor that
introduced them. The combat lock's page chrome (`lib.__combatFrame`, `lib.__OnCombatEvent`, the
page-scoped registration, `lib.__coverLevel`, `lib.__descendsFrom`, `O.__buildCover`,
`O.__releaseOwnedFocus`) is `OptionsCombat.lua`'s from 25.32.1.1.6.1.7.4.1, and its `T2` / `T3`
citations still name the `OptionsTabs.lua` minors that introduced it. The page registry
(`RegisterOptionsPage`, `__pages`, `CreateOptionsPanel`, `OpenOptionsPanel`) and the registration
park's library-level names are `OptionsRegistry.lua`'s from 26.1.32.1.1.6.1.7.4.1, and their `O`
citations still name the `Options.lua` minors that introduced them. The minor that introduced a
member is a fact about when a consumer got it, not about which file holds it today. Minors 1 and 2 of each file were never tagged, so
`O1`/`W1`/`S1` means "present for as long as any consumer could have had this major".

## What changed at this version: the outline default (`LK-F05`)

`LK-F05` of Ka0sAddonsCommonTasks `docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/` (the owner's item 5,
its D-10). `LibKa0s-Skin-1.0`'s `OUTLINE_DEFAULT` is `"hud"`, so the Skin tab's *Font outline* shows
*HUD text only* for an owner that never set one. The dropdown keeps its order, *All text* first.
`OptionsAppearance.lua` (minor 5) changes what a media write sends: `media.outline` is the mode the
owner stored, read from `Skin:__StoredOutline`, and nil while it never moved off the default, so a font
or texture pick no longer stores the default as a choice. A setter reads nil as "left alone", as it
always has. The Skin tab's copy still carries the source's applied mode to its targets. A stored mode
stays.

## What changed at this version: "Skin's default" (`LK-F04`)

`LK-F04` of Ka0sAddonsCommonTasks `docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/` (the owner's item 4).
Wording only. The Skin tab's leading row reads "Skin's default (X)", where it read "Skin's own (X)";
`RESET_FONT_TIP` and `RESET_TEXTURE_TIP` say "the skin's default", and `OptionsSkinPicker.lua` moves to
minor **4** because `APPLY_ALL_TIP` does too. The `SKIN_OWN` key and the `"@skin"` value keep their
names, so a stored override and a host's `spec.strings` are unaffected, except that a translation
of the English text is the host's to reword.

## What changed at this version: the picker's rows (`LK-A3`)

`LK-A3` of Ka0sAddonsCommonTasks `docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/` (the owner's request to
give every addon's skin picker the Skin tab's elements). No member moves; `OptionsSkinPicker.lua`,
`OptionsAppearance.lua` and `OptionsMedia.lua` stay at this release's minors. `lib.__skinMedia`,
`lib.__appliedMedia`, `lib.__nextMedia`, `lib.__readIgnore`, `lib.__copySettings`, `lib.__baseTokens`,
`lib.__mediaList`, `lib.__fillMedia`, `lib.__newMediaRow`, `lib.__outlineItems` and `lib.__resetTip`,
all internal, are the tab's own helpers moved to the library table, and `lib.__createLazyMedia`
(`OptionsMedia.lua`) is `Create` with the faces left for the first open. See
[The skin picker](#the-skin-picker-optionsskinpickerlua-minor-2), *The rows*.

## What changed at this version: a picker row's name never stays blank (`LK-A2`)

`LK-A2` of Ka0sAddonsCommonTasks `docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/` (the owner's blank
Azeroth row). No member moves, and `OptionsSkinPicker.lua` stays at this release's minor **4**.

- **The preload.** Every show hands `lib.__PreloadFonts` every skin's body face and no other: the
  window can come up for a player who never opens settings, so it does not load every LSM face. A
  copy without `OptionsScroll.lua` shows its rows with no preload.
- **A refused face.** A `SetFont` that raises or answers false puts the row back in its template's
  face, `GameFontHighlight`, with its name. So does a nil, unless the face reads back through
  `GetFont`.
- **The redress.** Every open, and a skin switch under an open list, dresses each row at once and
  again next frame, the font and then the text through `""`. A name that still measures nothing
  on that next frame (`GetStringWidth` answers 0) goes to the template's face, and the next open
  tries the skin's face again.

## What changed at this version: the media pickers (`LK-F03`)

`LK-F03` of Ka0sAddonsCommonTasks `docs/2026-10-31-FONT_PICKERS_AND_SKIN_FACES/` (the owner's item 1,
decisions D-08 and D-09). `OptionsMedia.lua` minor **1** joins the major as its sixteenth file;
`OptionsWidgets.lua` moves to **38** and `OptionsAppearance.lua` to **5**.

- **Five AceGUI types**, registered on first ask: `Ka0sMedia_Font`, `Ka0sMedia_Statusbar`,
  `Ka0sMedia_Border`, `Ka0sMedia_Background` and `Ka0sMedia_Sound`, plus the row type
  `Ka0sMedia_Item`. Each is AceGUI's own Dropdown constructor under a type name of ours (the
  AuraMaster precedent), so it has its own pool, the stock row's shape, and the stock pull-out's
  scrolling and strata. The closed row draws the chosen entry in its face (font) or beside a swatch
  (bar, border, background) or a play button (sound), and so does every row once the list opens.
  They do not need AceGUI-3.0-SharedMediaWidgets, and they do not need LibSharedMedia to work: without
  it the rows are plain text.
- **Widget surface, on top of the Dropdown's.** `SetList(list, order)` copies `list`, so a stored
  key added for display never reaches the host's table; `order` puts leading rows first; no `list`
  means every LibSharedMedia key of the kind, sorted. `SetValue(value)` adds a row for a value the
  list lacks, so a stored key always shows. `SetPreviews(map)` (new; `map` is `{ [listValue] = mediaKey }`, or nil)
  says what a leading row previews, so "Skin's default (X)" shows X.
- **`lib.__MediaWidgetType(name)`**, internal. `name` is a LibSharedMedia kind, a `Ka0sMedia_*` type
  or the `LSM30_*` type it stands in for. Answers the registered type, or nil when `name` is none of
  those or AceGUI has no stock Dropdown (the kit's AceGUI fake), and the caller draws a stock
  Dropdown. It registers the types and aliases each to `Dropdown` through `Skin:AliasAceType`.
- **`OptionsWidgets.lua` 38.** A `dialogControl` that is not registered and names one of those
  types draws the picker, then the stock Dropdown as before. A registered `LSM30_*` type is used as
  it always was, and a row may name `Ka0sMedia_*` directly.
- **`OptionsAppearance.lua` 5.** The Skin tab's font and texture rows are pickers, and the leading
  row previews what it stands for.
- **The skin.** D-09: the picker and its pull-out wear the owner's skin through the Dropdown painter.
  The rule that an `LSM30_*` pull-out stays stock stands. The closed row keeps its preview through a
  repaint, at the size and flags the painter chose.
- **Faces load first.** A font picker runs `lib.__PreloadFonts` on acquiring and on opening, and
  dresses its rows again on the next frame when that loaded anything.

The member manifest lists no new member: the types are AceGUI's registry, and `__MediaWidgetType`
is internal. A degradation stub owes nothing.

## What changed at this version: `O.SkinVerb` (`LK-11`)

`LK-11` of Ka0sAddonsCommonTasks `docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/` (the owner's item 12,
decision D-16): `/<slash> skin` in every addon opens the skin picker a new profile shows.
`OptionsSkinPicker.lua` is already at minor **3** this release (`LK-07`), so it does not move again
and the key is unchanged. **One instance member is added**, `O.SkinVerb(spec)` (see
[`O.SkinVerb(spec)`](#oskinverbspec)), and `lib.SKIN_PICKER_STRINGS` gains four keys (`VERB_HELP`,
`VERB_COMBAT`, `VERB_QUEUED`, `VERB_UNAVAILABLE`). The manifest lists the lib-level table only, so it
does not name the member.

**What a consumer owes** (M2, the re-vendor commit): every Options degradation stub gains
`SkinVerb = function() return nil, "absent" end` (`Kit.assertSurfaceParity` turns red until it does);
each addon adds a `skin` row after `config` (help `Choose a skin: open the skin picker`, the
`VERB_HELP` wording) whose handler calls `O.SkinVerb(NS.SkinPickerSpec())` and prints the
library-absent line on `nil, "absent"`; `skin` joins each Slash degraded stub's set of verbs not
offered without the library; help, landing and verb-count pins move by one row.

## What changed at this version: `shownWhen.any` and `OptionsSwitch.lua` (`LK-10`)

`LK-10` of Ka0sAddonsCommonTasks `docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/` (the owner's item 10,
decision D-17): DropWatcher's Upgrade glow tab hides the sections neither style dropdown selects,
and shows both when the two glows pick two styles. `OptionsWidgets.lua` 36 -> **37** and a fifteenth
file, **`OptionsSwitch.lua` 1**, so the key gains a component (fifteen numbers). No public member is
added or removed.

- **`shownWhen = { any = { { path = p1, equals = ... }, { path = p2, equals = ... }, ... } }`**
  (**SW1**). The row is drawn while **any** clause holds; each clause is the single form's
  `{ path, equals = <value> | { <value>, ... } }`, read the same way (a raising read reads as shown).
  Every clause's path is a selector, watched as the single form's is, so a change to any of them
  re-renders the page once, on the next frame, coalesced per page (two changes in one frame cost one
  re-render). A clause that is not a table or names no path holds for nothing and is never watched;
  an `any` with no well-formed clause switches nothing. With `any` present a top-level `path` is
  ignored. The single form is unchanged.
- **The switched sections are `OptionsSwitch.lua`'s** (**SW1**), peeled out of `OptionsWidgets.lua`,
  whose CLAUDE.md band entry named them as its seam and whose 1450-line re-check trigger the OR form
  would have fired. `lib.__AttachWidgets` calls `lib.__AttachSwitch(O, { read, readKey })` where the
  helpers were defined and keeps the three functions it answers (`switchedRows`, `selectorKey`,
  `watchSelector`); the single-path code moved unchanged. Guarded with the multi-file idiom
  (`lib.__switchMinor`, `lib.__switchShellMinor`). A copy without the file draws every row and
  watches nothing.

## What changed at this version (`LK-03`, `LK-04`, `LK-07`, `LK-08`)

Three files move, for `LK-03`, `LK-04` and `LK-07` of Ka0sAddonsCommonTasks
`docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/` (the owner's items 13 and 1 and rulings D-06, D-07 and
D-10, with `LibKa0s-Skin-1.0` minor 9's font outline mode and SkinPaintExtras minor 7's
`S.FontFlags`): `OptionsAppearance.lua` 3 -> **4**, `OptionsCompose.lua` 13 -> **14** and
`OptionsSkinPicker.lua` 2 -> **3**; `LK-08` (item 6, D-11) lays the Skin tab out again in
the same minor. No public member is added or removed; `lib.APPEARANCE_STRINGS` gains ten keys (five
for the outline, five for the layout).

**`O.FontGroup{ flagsFromSkin = true }`: the Font flags row leads with *From skin*** (C14, `LK-04`).
The row's values gain `"@skin"` (the Skin major's `FROM_SKIN`), labeled "From skin", first in its
`sorting`, and it becomes the row's default (a host's `defaults.fontFlags` still wins); its tooltip
says From skin follows the Skin tab's *Font outline* and any other choice is drawn as picked. The
host draws with `S.FontFlags(stored)` (`S.FontFlags(stored, "window")` for window text), which lets a
picked flag win and resolves From skin through the owner's mode. A flags value is a CLI value, not a
media path, so the sentinel is honest here, unlike a media pick (C12's companions). The lists are
private copies: `O.FONT_FLAGS` and `O.FONT_FLAGS_SORT` are unchanged, and a FontGroup without
`flagsFromSkin` emits exactly C13's rows. **`O.FontGroup{ fromSkin = true, flagsFromSkin = true }` is
the minimum font setting** the owner's ruling D-07 asks of every element: face with *Use the skin's
font*, size, color with *Use class color*, flags with *From skin*, and shadow. The composite already
existed (C1's six rows, C12's companion), so it is extended, not duplicated.

**The Skin tab's *Font outline*** (A4). In the *Font and texture* section, under the reset buttons
(under the Scope's two check boxes as `LK-03` drew it; `LK-08` moved it), a dropdown at
`BUTTON_PAIR_REL`, *Font outline*, offers *All text* (`"all"`, the default until `LK-F05`), *HUD text only*
(`"hud"`, the default since) and *Off* (`"off"`), in that order. A pick is refused in combat; it calls
`Skin:SetOutline(owner, mode)` first (the live repaint: every string the owner's primitives paint
loses or regains its outline, and the HUD's `hud.outline` follows), then `spec.set(nil, nil, nil,
{ font, texture, outline })`. It is **grayed while *Ignore fonts* is on**, which wins (`sync` reads
`Skin:GetIgnore` into it), and its tooltip says so. Absent with a Skin copy that has no `SetOutline`.

**Every media write carries all three halves** (A4). `media` gains `outline` (one of the Skin major's
`OUTLINE_MODES`, the applied mode), and a font or texture pick writes it too; an outline pick writes
the applied font and texture overrides with it. A host setter written for A3 stores both overrides of
every `media` it is given, so a partial one would clear them.

**The copy carries it** (A4): *Copy to every Ka0s addon…* gives every other owner this owner's font
outline with its source, skin, scope, font and texture (`Skin:SetOutline`, then the setter), and
says so (`COPY_TIP`, `COPY_CONFIRM`). `lib.__copySkinTo(Skin, name, source, skin, ignore, media)`
takes a `media` with any half left out (nil: the target's own), calls `SetOutline` for
`media.outline`, and writes the target's applied font, texture and outline after the move.

**The skin picker's *Apply to all Ka0s addons* does not carry it**: *Apply to all* still gives the
other owners the source and skin alone. The picker never shows the outline, and an owner that never
set one answers the default, so carrying it could silently undo another addon's *Off* (the LK-03 review;
D-06 gives the outline to the Skin tab's copy alone). `OptionsSkinPicker.lua` stayed at minor 2 for
it; minor 3 is `LK-07`'s, below.

**Choosing another skin resets the font and texture overrides** (A4, still; P3; `LK-07`, the owner's
item 1 and ruling D-10). `lib.__chooseSkin(Skin, name, source, skin)` (internal, library-level, next
to `lib.__copySkinTo`) moves the owner with `Skin:SetChoice` and, when the look it draws changed
(`Skin:DrawsKey` before against after; any change of the choice on a Skin copy without it) and it
wore an override, clears both with `Skin:SetOverride(name, false, false)`; it answers `changed,
reload, cleared` and writes no profile. A Ka0s skin to another resets; a move onto an EllesmereUI
that paints the owner resets (its face replaces the skin's); a fallback skin picked while EllesmereUI
paints keeps them (the look did not change); re-clicking the checked skin keeps them. Every
skin-change path the player drives goes through it:

- **the Skin tab's pick** (a skin or a source): after `spec.set(source, skin)`, a pick that reset an
  override writes `spec.set(nil, nil, nil, { font = false, texture = false, outline })` (every media
  half, the outline as it is), so the profile matches; refused in combat first, so nothing resets in
  combat;
- **`lib.__copySkinTo`** (the tab's copy and the picker's *Apply to all*): a target whose look changes
  starts from the new skin's own font and texture. The tab's copy then lays this owner's overrides
  over it, as before; with no `media` (the picker), a reset is written through `WriteChoice`'s
  fourth argument with the target's own outline;
- **the skin picker** (P3): a pick whose look differs from the one the window opened with previews
  with the overrides cleared (`SetOverride`, no write), a pick back to it restores them; Apply, the
  gear and *Apply to all* then write the cleared overrides after the skin
  (`spec.set(nil, nil, nil, { font = false, texture = false, outline })`); the close control and
  Escape put back the overrides the window opened with, but only while the look drawn is again the
  opened one and the overrides are still the cleared pair the preview left: a Skin-tab write made
  while the picker was up (another skin's reset, or an override) stays live, as the profile holds it.

**The Skin tab's layout** (A4, still; `LK-08`, the owner's item 6 and ruling D-11):

- **Reset font** and **Reset texture**, two AceGUI `Button`s at `BUTTON_PAIR_REL` in a row of their
  own under the two dropdowns (a button on the dropdowns' line would top-align with their labels),
  font under *Font*, texture under *Texture*. A click is the dropdown's *Skin's default* pick for its
  half: refused in combat, `Skin:SetOverride` (that half `false`, the other kept), then
  `spec.set(nil, nil, nil, { font, texture, outline })`. `sync` disables each while its half is
  already the skin's own (and both on a page drawn disabled), and words its tooltip
  (`RESET_FONT_TIP` / `RESET_TEXTURE_TIP`, `%s` the skin's own key worn now). The view gains
  `reset = { font, texture }`.
- **The *Font outline*** sits under them, in the same section, at the same half width.
- **The Scope's two check boxes are half width** (`BUTTON_PAIR_REL`, where they were the skins'
  0.32), so *Ignore fonts* starts in the column *Texture* and *Reset texture* start in.
- **The copy button has its own heading**, *Other Ka0s addons* (`COPY_HEADING`), after the Scope,
  and sits in a row of its own; the `COPY_NONE` hint stays under it, and the tab ends there.
- **The note** (`NOTE`) leads the *Look* section, ahead of the skins (and of `SKIN_EUI_NOTE`), where
  it was the tab's last line. `view.note` is kept.
- The two icons at the right of the owner's image-30 are the page's stock scroll bar: no change.

**Never inside `Skin:SetChoice`**: a host re-applies its stored skin with `SetChoice` at load, after
its stored overrides, and a reset there would wipe them at every login (`tests/test_skin_override.lua`
pins the guard). A profile switch, copy or reset, and `/xx set skin.skin <key>` (a raw row write),
re-apply stored values and reset nothing. Each clearing pick costs two repaints and two
`OnLooksChanged` firings, both synchronous and out of combat.

## What changed at version 34.4.36.5.7.11.3.13.9.4.3.6.3.2

Nine files move, for three items of Ka0sAddonsCommonTasks `docs/2026-10-30-SKIN_LIBRARY_FOLLOWUPS/`:
`OptionsSkinPicker.lua` 1 -> **2** (LK-11, the owner's ruling R-11 and decision D-17);
`OptionsWidgets.lua` 35 -> **36**, `OptionsIdList.lua` 6 -> **7**, `OptionsTabs.lua` 10 -> **11**,
`OptionsScroll.lua` 8 -> **9**, `OptionsNav.lua` 3 -> **4**, `OptionsDrawer.lua` 2 -> **3** and
`OptionsKeybinds.lua` 5 -> **6** (LK-06d, ruling R-5 and decision D-14); and `OptionsIds.lua` 4 ->
**5**, with `OptionsScroll.lua` 9, `OptionsNav.lua` 4, `OptionsDrawer.lua` 3 and `OptionsIdList.lua`
7 again (LK-06c, ruling R-5, decisions D-01, D-07, D-13 and D-14). No public member is added or
removed.

**The tooltip lines the chrome writes take the skin's tooltip colors** (S9, W36, D3, N4, T11, K6,
L7). Each line that named an explicit color was a literal whatever the skin. They now go through one
internal helper on the instance, `O.__tipColor(token, r, g, b)` (S9; a copy without
`OptionsScroll.lua` gets OptionsWidgets' stand-in, which answers the literal): the page owner's
color token while the chrome is skinned (`O.__chromeSkin()` answers a facade), else `r, g, b`. So
an owner-less page and an owner that ignores its settings panel draw exactly what the previous
minors drew. It is read at hover, so a skin switch reaches the next tooltip with no re-render.

| Site | Line | Token | Literal (unskinned) | Ka0s Default |
|---|---|---|---|---|
| `O.AttachTooltip` (W36): every settings row and control | title | `gtip.value` | `1, 1, 1` | white, unchanged |
| Drawer head (D3) | title | `gtip.value` | `1, 1, 1` | white, unchanged |
| Nav entry (N4) | title | `gtip.value` | `1, 1, 1` | white, unchanged |
| Tab (T11) | title | `gtip.value` | `1, 1, 1` | white, unchanged |
| Key button (K6) | title | `gtip.value` | `1, 1, 1` | white, unchanged |
| Id list help mark (L7) | name | `gtip.value` | `1, 1, 1` | white, unchanged |
| Id list help mark (L7) | note lines | `gtip.body` | `0.8, 0.8, 0.8` | **0.9 gray** (D-14's recorded shift, for one tooltip palette across the collection) |

`gtip.value` is white in all nine skins, so the titles move only under a skin that sets it, or
EllesmereUI's derived table. A line that names no color (every tooltip body above) stays the
client's. A pooled nav entry or tab reads the instance that dressed it last (`__ka0sNavO`,
`__ka0sTabO`), never the one that built it. Nothing is owed by a consumer.

**The chrome's last unskinned pieces wear the page owner's skin** (I5, S9, D3, N4, L7; with
`LibKa0s-Skin-1.0` 8.16.12.6.10.2.4's `S.Drawer` and `S.NavItem` and its new `list.hoverArt`).
Everything below is the settings panel (D-01): it is painted through `O.__chromePaint` or read
through `O.__chromeSkin()`, so an owner-less page and an owner that ignores its settings panel draw
the client's look, and *Ignore settings panel* gives a painted piece back live.

| Piece | On an owned page | Ka0s Default | Unskinned |
|---|---|---|---|
| Drawer head's label and summary (D3) | `S.Drawer` labels them (`P.label`): `drawer.text*` / `drawer.summary*` as before, now in the skin's body face, the summary's smaller size scaled, so *Ignore fonts* reaches them | **Oxanium** where the templates drew Friz Quadrata (D-13) | `GameFontNormal`, `GameFontHighlightSmall` |
| Drawer chevron (D3) | `S.Drawer`'s `chevron`: desaturated and colored `icon.arrow`, as every arrow the library draws | gold on the desaturated art | the client's yellow arrow |
| Hover art: drawer head (D3), nav entry (N4) | `S.Drawer`'s and `S.NavItem`'s `hover`: desaturated and colored `list.hoverArt` | the client's art (`list.hoverArt` is `false`) | the client's art |
| Hover art: id list entry (L7), suggestion row (I5) | `O.__hoverArt(tex, back)` (S9, internal): the same, read at each render or open; a released id list entry is handed back untinted | the client's art | the client's art |
| Suggestion rows (I5) | Each label `S.Text(fs, "menu.text")`: the dropdown menu's rows' color, the body face | `menu.text`'s **0.9** where the template drew white (D-14), Oxanium | `GameFontHighlightSmall`, white |
| Suggestion "+N more" line (I5) | `S.Text(fs, "disabled")` | 0.5 gray, the template's, in Oxanium | `GameFontDisableSmall` |
| The id's gray, in the suggestion rows, the id list's labels, suffixes and notes (I5, L7) | the owner's `text.disabled` as a color code, built with the label | `\|cff808080`, exact | `\|cff808080` (`ID_GRAY`) |

Every dress of a pooled drawer head or nav entry puts the faces, the chevron and the hover art back
on the client's before the skin paints, so a head drawn for no owner never keeps another owner's.
`lib.__chromeAway(owner)` and `O.__chromeAway()` keep their names and say what they do (D-07): since
`LibKa0s-Skin-1.0`'s SkinPaint minor 6 no skin is special, so they answer the facade wherever
`__chromeSkin` does, Ka0s Default included; the help mark, the keybind rows, the Skin tab's muted
labels and the page backdrop that ask them draw under Ka0s Default too, as the retired stock look
(R-2) asks. Nothing is owed by a consumer.

**The skin picker's title and the addon's name** (P2): the window's title is `TITLE`, "Choose a
skin", where minor 1's `TITLE_FOR` ("Choose a skin for %s") put the addon's label in a one-line title
224 px wide, and the client cut a long label off (every addon in the owner's screenshots). The
label (`Skin:OwnerLabel(owner)`, else the owner's name) has its own line, `frame.ownerLabel`, above
the dropdown, painted as a heading (`S.Text(fs, "heading")`: the title face, `text.heading`) and
never cut off: the window widens to the label's unbounded width plus its side padding, never
narrower than 280, on every show and every change of the owner's looks (a skin switch or a pick's
preview changes the label's face and size). The dropdown row, the list and the buttons beside the
dropdown move down one line. See [The skin picker](#the-skin-picker-optionsskinpickerlua-minor-2).

**What a consumer owes.** `lib.SKIN_PICKER_STRINGS.TITLE_FOR` is gone and `TITLE` is new: a host
that translated `TITLE_FOR` through `spec.strings` (none in the collection does) translates `TITLE`
instead; a stale `TITLE_FOR` is an unused key, ignored. A test or smoke check that expected the
addon's name in the title reads `frame.ownerLabel` instead.

## What changed at version 34.4.35.4.6.10.3.13.8.3.2.5.3.1

One file moves: `OptionsCompose.lua` 12 -> **13** (LK-04 of Ka0sAddonsCommonTasks
`docs/2026-10-29-SKINNING_ROLLOUT/`, gap DW-G14). No member is added or removed.

**`O.BorderGroup{ fromSkin = "icon" }`** (C13): the same companion bool `fromSkin = true` emits
(`borderStyleFromSkin`, *Use the skin's border*, default `false`, on a line of its own), following the
skin's **icon border family** (`LibKa0s-Skin-1.0`'s `icon.borderStyle` and `icon.borderSize`, SkinDefs
minor 15) instead of the bar's. While it is set the style picker is disabled and shows
`icon.borderStyle`, and the thickness slider (`borderSize`) is disabled too and shows
`icon.borderSize`: an item icon's border follows the skin in style and thickness, the color staying
the swatch's. Its tooltip says so. `fromSkin = true`, and any other value, is C12's bar family,
row for row: only the style picker is governed, from `bar.borderStyle`. See
[Following the skin in the group composers](#following-the-skin-in-the-group-composers-c12-w35).

## What changed at version 34.4.35.4.6.10.3.12.8.3.2.5.3.1

Three files move and a fourteenth arrives: `Options.lua` 33 -> **34**, `OptionsRegistry.lua` 3 ->
**4**, `OptionsAppearance.lua` 2 -> **3**, and `OptionsSkinPicker.lua` at **1** (LibKa0s#63 and
#64; SO-03, PK-01 and PK-02 of Ka0sAddonsCommonTasks `docs/2026-10-28-SKIN_OVERRIDES_AND_PICKER/`).

**`O.OpenOptionsPanel(pageKey)`** (`OptionsRegistry.lua` minor 4): an optional page key, the key
`O.RegisterOptionsPage` was given, opens that page's own subcategory instead of the main category.
See the member table. The skin picker's default gear uses it.

**The skin picker** (O34, P1): `O.SkinPicker(spec)` and `O.HideSkinPicker()`, a small window a host
shows the first time a profile runs so the player picks a skin before opening any settings: a pick
previews, **Apply** saves, the close control puts the preview back, *Apply to all Ka0s addons* gives
every other owner the same skin, and one window is up at a time across every Ka0s addon (a queued
call answers `nil, "queued"`). See
[The skin picker](#the-skin-picker-optionsskinpickerlua-minor-2). `Options.lua` 34 adds one guarded
attach line (`lib.__AttachSkinPicker(O, d)`) and no member of its own.

**The Skin tab** (A3), with `LibKa0s-Skin-1.0` minor 6's `GetOverride`, `SetOverride` and
`WriteChoice`'s `media`, read at call time:

- **The tab is labeled "Skin"** (`TAB_LABEL`); its key stays `"Appearance"`, because hosts name the
  key in `before` and in a stored active tab, and renaming it would move every one of them for no
  visible gain. `TAB_TIP` names the font and bar texture too.
- **A "Font and texture" section** between the skins and the scope: two AceGUI `Dropdown`s side by
  side, *Font* and *Texture*, over LibSharedMedia-3.0's `font` and `statusbar` keys. See
  [The Appearance tab](#the-appearance-tab-optionsappearancelua-minor-1), item 3.
- **The copy carries them**: *Copy to every Ka0s addon…* gives each other owner this owner's font
  and texture as well, and `COPY_TIP` / `COPY_CONFIRM` say so.
- **The skins' heading reads "Look"** (`SKIN_HEADING`), not "Skin": a subsection heading does not
  repeat its tab's name (`options-ui-§7`). The other owners and one owner's skin copy are on the
  library table (`lib.__skinOthers(Skin, owner)`, `lib.__copySkinTo(Skin, name, source, skin,
  ignore, media)`, internal), shared with the skin picker's *Apply to all Ka0s addons*.

The tab adds no instance member and changes no signature; `lib.APPEARANCE_STRINGS` gains
`MEDIA_HEADING`, `FONT`, `FONT_TIP`, `TEXTURE`, `TEXTURE_TIP`, `SKIN_OWN` and `MEDIA_MISSING`.

**What a consumer owes.** Every Options degradation stub gains `SkinPicker` and `HideSkinPicker`
(`Kit.assertSurfaceParity` compares the stub with the live instance), for instance
`SkinPicker = function() return nil end, HideSkinPicker = function() end`. A host that shows the
picker declares the Media icons `eye` and `settings` in its `LibKa0s icons:` line, or the buttons
draw their text glyphs. Its `set` is reached only by Apply, *Apply to all* and the gear, never by a
pick; its `onClose` runs for every close and for a queued picker *Apply to all* dismisses; its
`page` is the key it gave `O.RegisterOptionsPage`. A host that reads `O.SkinPicker`'s answer as
"the picker is up" sees `nil` for a queued call, which shows by itself later.

## What changed at version 33.3.35.4.6.10.3.12.8.3.2.5.2

Every file of the major moves: `Options.lua` 30 -> **33**, `OptionsRegistry.lua` 2 -> **3**,
`OptionsWidgets.lua` 34 -> **35**, `OptionsIds.lua` 3 -> **4**, `OptionsIdList.lua` 5 -> **6**,
`OptionsTabs.lua` 9 -> **10**, `OptionsCombat.lua` 2 -> **3**, `OptionsCompose.lua` 11 -> **12**,
`OptionsScroll.lua` 4 -> **6**, `OptionsNav.lua` 2 -> **3**, `OptionsDrawer.lua` 1 -> **2** and
`OptionsKeybinds.lua` 4 -> **5**, and a thirteenth file arrives, `OptionsAppearance.lua` at **1**. Four things land: **the settings chrome follows the page's skin
owner**, **the group composers can follow the skin** (Ka0sAddonsCommonTasks
`docs/2026-10-25-SKINNING/`, item LK-07; the owner's rulings R2 and R3), and **the AceGUI rows a page
acquires wear the owner's skin** (item LK-08: `Options.lua` 32, `OptionsRegistry.lua` 3,
`OptionsScroll.lua` 6, with `LibKa0s-Skin-1.0`'s `SkinAce.lua`), and **the Appearance tab** (item
LK-10: `Options.lua` 33, `OptionsAppearance.lua` 1, with `LibKa0s-Skin-1.0` minor 4's `OwnerLabel`
and `WriteChoice`). It needs
`LibKa0s-Skin-1.0` and `LibKa0s-Core-1.0` minor 13 at call time, neither as a floor: without them
every page draws what version 30.2.34.3.5.9.2.11.4.2.1.4 drew.

**No member is added to `Options.lua`, `OptionsTabs.lua` or `OptionsWidgets.lua`** (their band
triggers, CLAUDE.md); the helpers are `OptionsScroll.lua`'s, internal and `__`-prefixed. The
Appearance tab's two members are `OptionsAppearance.lua`'s, attached by one guarded line in
`lib:New` (O33), the exception `OptionsKeybinds.lua`'s attach set (K1, O30).

### The Appearance tab (O33, A1)

Two public instance members and one lib-level table, `skinning-§3`: **`O.AppearanceTab(spec)`**,
the host-tab entry a General page draws immediately before Keybindings, **`O.AppearanceRows(ctx,
spec, parent)`**, its body for a host-drawn strip, and **`lib.APPEARANCE_STRINGS`**, its words. See
[The Appearance tab](#the-appearance-tab-optionsappearancelua-minor-1). Without
`LibKa0s-Skin-1.0`, or for an owner that never registered, the rows draw one line and no control.


### The page's skin owner (O31, S5)

The descriptor's **`addonName` is the page's skin owner** — once that addon has called
`LibKa0s-Skin-1.0`'s `RegisterOwner`. Every collection host already passes `addonName`, and the ones
that never adopted skins must keep drawing exactly what they drew, so **an unregistered name, no name
and a client with no Skin major paint today's chrome, call for call** (`tests/test_options_skin.lua`
traces all three). A registered owner's page is painted again through the owner's facade **after**
the chrome's own paint, so a primitive a loaded Skin copy lacks leaves the page as drawn, and on
Ka0s Default each primitive repeats today's colors.

| Surface | What a registered owner's page paints | Ka0s Default |
|---|---|---|
| Header (`CreatePanel`, O31) | The title in the skin's title role (`S.Text(title, "title")`); the divider atlas tinted `title.text` | today's gold, the title font's own color |
| Page backdrop (O31) | Away from Ka0s Default only: an opaque texture under everything the page draws, `win.bg` at **full alpha**, so a light skin (Azeroth) stays legible over the client's Settings window. A texture rather than `S.Panel`, which would also draw on Ka0s Default | none |
| Tab strip (T10) | Each tab through `S.Tab`: the three client atlases are the stock it fades under every skin, Ka0s Default included, the dark backing is its fill (`tab.bg` / `tab.onBg`), the label takes `tab.text` / `tab.onText`, a `tab.onLine` under the selected tab. The secondary strip's tabs too | the client's atlases at full alpha |
| Content box (T10) | `S.FadeRegions` over the inner-frame art, then `S.Panel` (`panel.bg`, `panel.border`) | the inner-frame art |
| Banner / header-block hairline (T10) | `S.Divider(tex, { token = "tab.rule" })` | `{ 1, .82, 0, .16 }`, as before |
| Nav rail (N3) | The pane recolored through `S.Panel(rail, { nav = true })` (`nav.bg`, `nav.border`); each entry through `S.NavItem` (label `nav.text` / `nav.selText`, selection `nav.selBg`, a `nav.selBar`) | `PANE_FILL`, `PANE_BORDER`, gold and white |
| Drawer (D2) | The head through `S.Drawer` (label, summary, its edge set open or closed); the box's edge set in `drawer.boxBg` / `drawer.boxBorder` | the drawer palette |
| Combat cover (OC3) | `S.Cover(dim, { text = line })` on every show, so an owner that registered after the page was built still gets it | `{ 0, 0, 0, .6 }` and the gray line |
| Suggestion list (I4) | `S.MenuFrame(f, { popup = true })` on every open (`popup.bg`, `popup.border`) | `{ 0, 0, 0, .92 }` |
| Id list help mark (L6) | Away from Ka0s Default, read at draw: `text.accent` (info), `sem.bad` (blocked), `text.disabled` (no lines), `icon.hot` (hover) | minor 5's constants |
| Keybind rows (K5) | Away from Ka0s Default: the action's name `text.body`, the set and outcome lines `text.muted`, through the Label's own `SetColor` (AceGUI resets it when it hands the widget out again) | the widgets' defaults |
| Always-shown scrollbar (S5) | `PatchAlwaysShowScrollbar(scroll, owner)`: after the patch's own tint, `S.ScrollBar(bar, { state = "on" \| "off" })` (`scroll.thumbOn` / `scroll.thumbOff`); the bar is given back on release, since the widget is pooled | `THUMB_ON` / `THUMB_OFF` |

**Repainting.** A primitive records what it painted (`Skin:Track`), so `Skin:SetChoice` repaints the
tabs, the rail, the drawers, the cover, the popup and the thumbs on its own. What a page draws per
render from a token read (the help marks, the keybind rows) is redrawn by the instance's **one**
`OnLooksChanged` listener, installed the first time a registered owner's page paints: it repaints
each page's header and backdrop, then runs `O.RefreshAllPanels()` (a shown page re-renders, a hidden
one is marked dirty and re-renders on its next show) **one frame later** (`C_Timer.After(0)`, from
**S6**; at once in a client without `C_Timer`), once however many switches land in that frame: the
re-render is also what repaints the AceGUI rows (*The AceGUI rows*, below). The header and backdrop are also painted on
every show of the page, so an owner that registers after `CreatePanel` gets them.

**Pooled pieces are given back.** A drawer head lives on a pooled AceGUI `SimpleGroup` frame and the
scrollbar on a pooled `ScrollFrame`; drawn for no owner (or released), the frame is untracked in the
Skin major's registry, so its former owner's next switch no longer reaches it. Every chrome dress
repaints each property a primitive touches before the primitive runs, so nothing needs putting back.

The helpers, internal: `lib.__chromeSkin(owner)` (Core's `__SkinFacade`), `lib.__chromeAway(owner)`
(the facade only away from Ka0s Default), `lib.__chromePaint(owner, prim, target, opts)`,
`lib.__chromeGiveBack(target)`, and on the instance `O.__chromeSkin()`, `O.__chromeAway()`,
`O.__chromePaint(prim, target, opts)` and `O.__skinPage(panel)`, closing over the descriptor's
`addonName` (`lib.__AttachScroll(O, d)` now takes the descriptor; `lib:New` always passed it).

### The AceGUI rows (O32, OptionsRegistry 3, S6)

Every widget a page acquires through **`O.AceGUI`** wears the page owner's skin, and goes back to
AceGUI's shared pool stock. The painting is `LibKa0s-Skin-1.0`'s `SkinAce.lua` (its document, *AceGUI
rows*); this major adds only the choke point, so **no widget maker changes** and `OptionsWidgets.lua`
does not grow:

- **`lib.__AttachSkinAce(O, d)`** (internal, `OptionsScroll.lua` **S6**) hands the instance to the
  Skin major's `__AttachSkinAce`, which, once `d.addonName` is a registered skin owner, replaces
  `O.AceGUI` with a proxy whose `Create(type)` is AceGUI's own Create followed by
  `Skin:PaintAce(d.addonName, widget)`. Every other field and method of the proxy is AceGUI's (a method
  called on it runs on AceGUI itself, a write lands on AceGUI), so `O.AceGUI:Release`,
  `O.AceGUI.FocusedWidget`, `RegisterWidgetType` and a host's own `O.AceGUI:Create` behave as before.
- **`lib:New`** calls it once the halves are attached (**O32**, one line in `attachHalves`), and
  **`CreateOptionsPanel`** again after it re-resolves AceGUI (OptionsRegistry minor **3**), so an owner
  that registers between the two is still proxied.
- **Without** the Skin major, `SkinAce.lua`, an AceGUI or a registered owner, `O.AceGUI` is AceGUI
  itself, exactly as at version 30.2.34.3.5.9.2.11.4.2.1.4. **On Ka0s Default** the proxy paints
  nothing and wraps nothing: the rows are stock AceGUI.
- **A skin switch** re-renders the open pages one frame later (*Repainting*, above): the release
  gives every row back stock and the re-acquire paints the new skin. A row is never repainted in
  place.

Cases: `tests/test_skin_ace.lua`.

### Following the skin in the group composers (C12, W35)

`O.FontGroup`, `O.BorderGroup` and `O.BarGroup` take an opt-in **`fromSkin = true`**. It appends
**one companion bool** after the canonical rows, on a line of its own (`startsLine`), named after the
picker's own key plus `FromSkin` (`prefix` and `keys` reach it as they reach the picker):

| Composer | Companion leaf | Label | Skin token |
|---|---|---|---|
| `FontGroup` | `fontFromSkin` | *Use the skin's font* | `hud.font` |
| `BorderGroup` | `borderStyleFromSkin` | *Use the skin's border* | `bar.borderStyle` |
| `BarGroup` | `barTextureFromSkin` | *Use the skin's texture* | `bar.texture` |
| `BorderGroup`, `fromSkin = "icon"` (**C13**) | `borderStyleFromSkin` | *Use the skin's border* | `icon.borderStyle`, and `icon.borderSize` on the thickness slider |

**The icon family** (C13). `BorderGroup{ fromSkin = "icon" }` emits the same rows as `fromSkin = true`,
with the companion following the skin's icon border (`icon.borderStyle`, `icon.borderSize`; Ka0s
Default's is Solid 2px) and governing the **thickness slider** as well as the style picker: both are
disabled while it is set, each showing its token. The companion's tooltip reads *Draw this border in
the skin's icon border style and thickness. The border style and thickness pickers are not read while
this is on.* The host draws with `S.Resolve("icon.borderStyle", style, fromSkin)` and
`S.Resolve("icon.borderSize", size, fromSkin)`, or hands the frame to
`S.IconBorder(frame, { fromSkin = true })` while the companion is set. `"Solid"` is not a
LibSharedMedia default border; a host that fetches it from LibSharedMedia registers it (the
`WHITE8X8` edge), as Drop Watcher does. `fromSkin = true` is unchanged.

Default `false` in leg 1 (addons opt in at leg 2). While it is `true` the picker is **disabled**
(`disabledIf`, the companion's own key, so a record-backed row reads its record) and **shows the
skin's value** — the picker row's new `skinValue()` field, which the flow engine reads before the
stored value (**W35**); the stored pick is untouched for when the player turns the companion off.
The host draws with `S.Resolve(token, pick, fromSkin)`, which answers the skin's value while the
companion is set, and `Skin.ResetToSkin` sets the companion to `true` (Skin minor 3).

**No sentinel ever enters a media list.** An LSM30 picker shows its list's key as the label and uses
the list's value as the media path, and the same list is the CLI's allowed values, so a *From skin*
entry (`Skin.FROM_SKIN`) in it would draw no preview and be a value the CLI accepts and nothing can
render. The picker's `values` are exactly version 30.2.34.3.5.9.2.11.4.2.1.4's. `omit = { fontFromSkin = true }`
leaves the companion out, and the picker is then not governed by it. Without `fromSkin` (or with
`fromSkin = false`) each composer emits exactly what C11 emitted. Cases:
`tests/test_options_compose_skin.lua`.

## Previously, at 30.2.34.3.5.9.2.11.4.2.1.4

Six changes, in `Options.lua` 29 -> **30**, `OptionsIds.lua` 2 -> **3**, `OptionsCombat.lua`
1 -> **2**, `OptionsCompose.lua` 7 -> **11** (its minors 8, 9, 10 and 11 all land in this release) and a
new twelfth file, `OptionsKeybinds.lua`, at minor **4** (its minors 1, 2, 3 and 4 all land in this
release); every other file of the major is unchanged. This version was briefly keyed
29.2.34.3.5.9.2.7.4.2.1, then 29.2.34.3.5.9.2.8.4.2.1, then 30.2.34.3.5.9.2.8.4.2.1.1, then
30.2.34.3.5.9.2.8.4.2.1.2, then 30.2.34.3.5.9.2.8.4.2.1.3, then 30.2.34.3.5.9.2.9.4.2.1.3, then
30.2.34.3.5.9.2.10.4.2.1.3 and then 30.2.34.3.5.9.2.11.4.2.1.3 on the release branch, before the
`OptionsCompose.lua` minor moved, before `OptionsKeybinds.lua` joined, before its second minor,
before its third, before `OptionsCompose.lua`'s ninth, before its tenth, before its eleventh and
before `OptionsKeybinds.lua`'s fourth; no release carried any of those keys (the local v1.77.0 tag
was cut at 30.2.34.3.5.9.2.11.4.2.1.3 and moves before any push).

**One key button and Clear per row (K4).** `OptionsKeybinds.lua` 3 -> **4** is the owner's
follow-up to item 015 (`options-ui-§20` as WS-40 rewrote it): a row of the Keybindings tab is the
binding's label, **one key button** and **Clear**; the client's Options -> Keybindings page is not
touched and keeps its two columns. The button shows the action's first key (`GetBindingKey`'s first
return) or `NOT_BOUND`; a left click listens and the key binds into slot 1 with the client's slot
semantics (`lib.__keybindSet(command, 1, key)`), so a second key set on the client's page is kept.
Nothing is hidden: with a second key the button reads **`<first key> +1`** (`KEY_MORE`), and its
tooltip, read at hover, names every key (`KEYS_ALL`) and says the others were set on the game's Key
Bindings page (`KEYS_OTHER`). A right click on the button clears the key it shows (slot 1; a second
key moves up and shows), and Clear removes every key. Escape, the combat refusals, the set line, the
outcome line and the `UPDATE_BINDINGS` sync are unchanged. The second slot widget is gone, a row
record's `slots` holds the one button, and `lib.KEYBIND_STRINGS` loses `KEY1` / `KEY2` (a host's
`spec.strings` entry for either is ignored) and gains `KEY`, `KEY_MORE`, `KEYS_ALL` and
`KEYS_OTHER`; `CLEAR_TIP` says every key. **No member is added or removed and a stub owes nothing.**
The kit's `Kit.keybindThroughTab` keeps slot 1 and writes slot 2 through the model (kit revision 42,
unreleased). See [The Keybindings tab](#the-keybindings-tab-optionskeybindslua-minor-2). Cases:
`tests/test_options_keybinds.lua`, `tests/test_kit_bindings.lua`.

**The reset's tooltip for the General page's header Defaults: `O.ResetAllTooltip(tail)` (C11).**
`OptionsCompose.lua` 10 -> **11** implements the library half of `options-ui-§12` as WS-36 wrote it:
where the General page's header **Defaults** is the global reset, its `defaultsTooltip` is the very
text *Reset all settings* carries. `O.ResetAllTooltip(tail)` returns that text, read from the
descriptor at call time through the same chooser `O.MasterControls` uses (`resetProfile`,
`profilesPage`), so the two controls for one act can never describe it two ways; `tail` follows
after one space when it is a non-empty string, and an addon with key bindings passes
`O.KEYBINDS_UNCHANGED` (`options-ui-§20`). `O.MasterControls`' `notes.resetAll` is that button's
own and never reaches this member. **One instance member is added, and every Options degradation
stub owes it** (see [What a consumer owes](#what-a-consumer-owes)). See
[`O.ResetAllTooltip(tail)`](#oresetalltooltiptail--string). U-04 and XC-02 of Ka0sAddonsCommonTasks
`docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`. Cases: `tests/test_options_reset_tooltip.lua`.

**Tooltips beside labels on the group composers (C10).** `OptionsCompose.lua` 9 -> **10**
implements the composer half of `options-ui-§16` as standard v2.88.0 wrote it. `O.FontGroup`,
`O.BorderGroup`, `O.BarGroup` and `O.ColorPair` take **`tooltips`** beside `labels`
(`{ <leaf> = "..." }`, keyed by the canonical leaf, never by a `keys` rename): a non-empty string
replaces that row's tooltip, for a host whose wiring the canonical words misdescribe, as
AbsorbTracker's *Bar opacity* applied to the whole frame (ABS-L12). A color swatch keeps
`O.CLASS_COLOR_NOTE` after the host's words (`options-ui-§17`); a companion takes them as given; the
label stays canonical. Bound rows (`spec.bind`) behave the same. **`O.MasterControls` ignores
`tooltips`**: `notes` stays its only route (`options-ui-§15`), and its `labels` behave as before.
An empty or non-string entry, or one for an omitted leaf, does nothing, and a spec with no
`tooltips` emits what it did, every golden unchanged. No member is added and a stub owes nothing.
See [The common spec](#the-common-spec). U-02 and ABS-P15 of Ka0sAddonsCommonTasks
`docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`. Cases: `tests/test_options_compose_tooltips.lua`.

**Master controls: notes, the preview lock, Master opacity and the frameless packing (C9).**
`OptionsCompose.lua` 8 -> **9** implements `options-ui-§15` as standard v2.88.0 wrote it. The
composed rows' words are the composer's, and `O.MasterControls` now takes the only three ways a
host extends them: **`notes`** (`{ <leaf> = "One sentence." }`, appended after that row's or
button's canonical tooltip), **`resetPositionTooltip`** (replaces the *Reset position* tooltip, the
one canonical text that names the addon's own frames) and **`lockIsPreview`** (the library's one
*Lock frame* sentence for an addon whose unlocked view is its test mode; passing `testModePath` as
well raises). Two changes are visible with no new field passed, both owner-ruled: the alpha row is
labeled ***Master opacity*** (owner call CALL-02; the stored leaf is still `alpha`, so nothing
migrates), and with *Lock frame* omitted (a frameless addon, or `omit.locked`) ***Minimap button*
sits beside *Debug console*** and *Test mode* opens its own line (U-09c). No member is added and a
stub owes nothing. See [`O.MasterControls`](#omastercontrolsspec--rows-aftergroup). U-01, U-09,
XC-04 and XC-05 of Ka0sAddonsCommonTasks `docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`. Cases:
`tests/test_options_compose_master.lua`; `tests/fixture_compose_golden.lua`'s framed record moved
for the label only.

**The tab follows Options -> Keybindings (K3).** `OptionsKeybinds.lua` 2 -> **3** keeps the
Keybindings tab in step with the client's page and with the binding set in force: one library
frame, `lib.__keybindEventFrame`, hears `UPDATE_BINDINGS` only while a keybind row is on screen,
registered through Core's `SafeRegisterEvent` and never raw, and repaints every row on screen once
per frame however many events arrive; the page's `OnShow` re-reads every key, so a key changed while
it was hidden shows with no event. No public member is added and a stub owes nothing. See
[Following Options -> Keybindings](#following-options---keybindings-optionskeybindslua-minor-3).
Cases: `tests/test_options_keybinds_sync.lua`.

**The Keybindings tab (K2).** `OptionsKeybinds.lua` 1 -> **2** adds three public instance members:
**`O.KeybindingsTab(spec)`**, the `opts.tabs` entry a General page draws last
(`O.RenderTabbedSchema`, `options-ui-§13`), **`O.KeybindRows(ctx, spec, parent)`**, the rows
themselves for a host-built strip, and **`O.KEYBINDS_UNCHANGED`**, the sentence a General page's
Defaults tooltip ends with. Each binding the host declares (`NS.BINDINGS`) is one row: the client's
`GetBindingName` label, two key slots and **Clear** at K2 (one key button and Clear from **K4**),
with the set line and the outcome line under the rows. The capture behaves as the client's page does
(Escape cancels, a right-click clears a slot, mouse buttons 3 to 31 and the wheel bind) through one library-level
listener, `lib.__keybindListener`; it is refused in combat and stopped at combat start. This is
`options-ui-§20`'s surface (OWNER_SCOPE 015). **Every Options degradation stub owes the three
members.** See [The Keybindings tab](#the-keybindings-tab-optionskeybindslua-minor-2). Cases:
`tests/test_options_keybinds.lua`, and the kit's new driver `Kit.keybindThroughTab`
(`tests/test_kit_bindings.lua`).

**The key binding model (K1 and O30).** `OptionsKeybinds.lua` is new, a twelfth file of the major,
and `Options.lua` 29 -> **30** attaches it at the end of `lib:New`, guarded
(`lib.__AttachKeybinds(O, d)`, an empty body at K1). It is the headless half of the settings-panel
Keybindings tab (`options-ui-§20`): `lib.__keybindSet` / `lib.__keybindClear` write a key with the
client's slot semantics, refuse in combat before calling any binding API, and save once to
`GetCurrentBindingSet()`; `lib.__keyChord` turns a key press into the client's chord string; and
`lib.KEYBIND_STRINGS` holds the tab's words. It writes no `BINDING_*` global and never reads
`Bindings.xml`, so `launcher-§6`'s rejection (LibKa0s#58) stands, and it supersedes QuickComms'
retirement of its in-panel key box (QuickComms `b902e35`). No instance member is added at K1. See
[The key binding model](#the-key-binding-model-optionskeybindslua-minor-1). Cases:
`tests/test_options_keybinds_model.lua`.

**One strata-row tooltip for the collection: `O.StrataTooltip(values, strings)` (C8).** A new
public instance member, a pure function returning the tooltip every player strata row carries
(`frame-layering-§1`, player-chosen strata, a MUST for every such row; `options-ui-§16`). Before it,
each addon that let the player pick a frame's strata wrote its own tier sentences (PanelMaster and
MultiMeters did, and AuraMaster and PartyFrameEnhanced needed one; U-12, XC-21, PAN-L20, MUL-L22,
XS-03 of the 2026-10-24 review). See
[`O.StrataTooltip(values, strings)`](#ostratatooltipvalues-strings--string). No value set is
published with it: each knob keeps the values it stores. Cases: `tests/test_options_compose.lua`.

**The IdList suggestion list closes when combat starts (I3 and OC2).** The dropdown an
`O.IdInput` (and so an `O.IdList`'s add box) puts up as the player types is parented to `UIParent`
(see [The id input and the id list](#the-id-input-and-the-id-list)), so the combat cover over a page
could not reach it: through I2 a list left open at `PLAYER_REGEN_DISABLED` stayed on screen over a
covered page, offering rows the write seam refuses (`O.__combatRefused`). Now the lock's
`O.__releaseOwnedFocus(panels)`, which already closed an AceGUI pullout on one of the instance's
pages, closes that list too, through a new internal instance member,
**`O.__closeOwnedSuggest(panels)`** (**I3**): when the box that owns the list sits under one of
`panels` (`lib.__descendsFrom`), the list is closed exactly as Escape closes it — hidden, its owner
cleared, its highlight and any update still waiting on the debounce dropped. A list a box under none
of those pages opened is left alone. **OC2 no longer returns once a pullout is closed**: the
pullout and the list both close when both are open. Leaving combat reopens nothing; the box's next
keystroke lists again. Nothing usable is lost, because a pick in combat was already refused, and an
AceGUI pullout closes the same way. `__`-prefixed and internal: no degradation stub owes it, and a
copy without it (an `OptionsIds.lua` older than I3) closes the pullout and leaves the list, as
before. Rule: `frame-layering-§4` (XS-10; BAN-S11 of the 2026-10-24 strata review). Cases:
`tests/test_options_idsuggest_frames.lua`.

## Previously, at 29.2.34.2.5.9.1.7.4.2.1

**The `__releaseChrome` test seam is no longer exported (T9), and `OptionsIdList.lua`'s help-mark
comment is corrected (comment-only).** `OptionsTabs.lua` 8 -> **9** and `OptionsIdList.lua` 4 ->
**5**; every other file of the major is unchanged. This version was briefly keyed
29.2.34.2.4.9.1.7.4.2.1 on the release branch, before the `OptionsIdList.lua` minor moved; no release
carried that key.

**`OptionsIdList.lua` minor 5 is comment-only; no member or behavior change** (LibKa0s#57). Its
help-mark comment said `media/icons/info.tga` "ships inside the vendored payload". From v1.75.0 a
consumer's copy is pruned to the icons its `LibKa0s icons:` line declares, so the art ships only
when the host declares `info` (or passes its own `helpIcon`). An undeclared `info` is **not** an
absent one to the help mark: `Media.Icon` answers a path from the catalog and never checks that the
file exists, so the ladder stops at that rung and the mark draws **blank** rather than falling back
to the client's information glyph. The comment's three line citations (Media's `ICONS`,
ConsumableMaster's `KCM.Icon("info")`, `DebugLog.lua`'s `makeIconButton`) and its two
`Core.lua` citations are re-pointed at the current lines. The minor moves so a corrected copy wins
the LibStub race; nothing a host observes changes.

**The `__releaseChrome` seam (T9).** `O.__releaseChrome` put the file-local `releaseChrome` on the
instance for a suite that never called it, and no roster consumer called it either: the only
mentions outside the library were degradation stubs mirroring the name, which the consumers drop
at their v1.75.0 re-vendor. `releaseChrome` itself and its two callers (`O.PageBanner` and
`O.PageHeader`) are unchanged, and the chrome-ledger cases in `tests/test_options_tabs.lua` keep
pinning teardown through `PageBanner`. Removed under the `__` clause of `library-stack-§7` as
narrowed at standard v2.86.0: a `__` member documented as a test seam with zero roster consumers
may be removed with a minor bump (LibKa0s#45). **Nothing public moves**; the row is gone from
[The instance surface](#the-instance-surface).

## Previously, at 29.2.34.2.4.8.1.7.4.2.1

**A drawer (D1 and O29).** `OptionsDrawer.lua` is new, an eleventh file of the major, at minor
**1**, and `Options.lua` 28 -> **29**; every other file of the major is unchanged. `O.Drawer(ctx,
spec)` draws a header bar that opens a bordered box the host fills with ordinary rows, through a
body ctx that draws into the box and reads and writes through to the page; see
[The drawer](#the-drawer). `Options.lua` attaches the file at the end of `lib:New`, guarded, and
`RefreshPanel` takes a body ctx back to its page. **A structural refresh of a page on screen now
keeps its scroll offset** (`RefreshAllPanels`, `RefreshPanel(ctx, true)`): restored after the
re-render and re-fixed, clamped to the new end, where through O28 the render's first `AddChild`
zeroed it; a page drawn on its show and a tab click still start at the top. From Ka0s Quick Comms' When tab, its one consumer
at release (`library-stack-§7`'s deviation row in `CLAUDE.md`). Cases:
`tests/test_options_drawer.lua`.

## Previously, at 28.2.34.2.4.8.1.7.4.2

**The help-art guard never reads the removed bare `IsAddOnLoaded` global (L4).**
`OptionsIdList.lua` 3 -> **4**; every other file of the major is unchanged. At L3 the guard on the
descriptor's `addonName` asked `C_AddOns.IsAddOnLoaded`, else the bare global `IsAddOnLoaded`. That
global is gone on every client this library supports — the standard's compat section deletes such
a dead fallback rung rather than shimming it — so from **L4** rung 2 of the help-art ladder below
reads `C_AddOns.IsAddOnLoaded(name)` only, in a `pcall`. With no `C_AddOns` reader the name is
**trusted**, exactly as it was at L3 when neither API existed; a planted bare global is never
called. On a live client nothing changes. From the 2026-10-07 standards audit (`LK-A-04`).
`.luacheckrc` no longer lists `IsAddOnLoaded` as a read global, so lint proves the payload never
reads it. Cases: `tests/test_options_idlist_layout.lua`.

## Previously, at 28.2.34.2.3.8.1.7.4.2

**The help mark's art checks the name it is given, and says when it cannot use it (L3 and O28,
[LibKa0s#42](https://github.com/tusharsaxena/LibKa0s/issues/42)).** `OptionsIdList.lua` 2 -> **3**
and `Options.lua` 27 -> **28**; every other file of the major is unchanged.

`Media.Icon` checks only that the addon name is a non-empty string, so a wrong descriptor
`addonName` -- the MasterControls compose spec's display label (`"Aura Master"`), or a misspelled
folder -- built a well-formed path to a file that does not exist, and the client drew nothing with
nothing raised. The default art ladder for an `O.IdList` help mark is now, resolved once per
instance at the first helped mark:

1. `spec.helpIcon`, when it is a non-empty string.
2. The descriptor's `addonName`, **only when the client reports that addon loaded**:
   `C_AddOns.IsAddOnLoaded(name)`, in a `pcall` (at L3, else the bare global `IsAddOnLoaded(name)`,
   which **L4** never reads). The name is **trusted** when there is no `C_AddOns` reader (a headless
   harness; at L3, when neither API existed) and when the check raises,
   so the guard catches a wrong name and never vetoes a right one on a client that cannot answer.
3. `Media.Icon(addonName, "info")`, the library's own white `info` art.
4. The client's `Interface\FriendsFrame\InformationIcon`.

When the ladder falls past rung 2 and the descriptor has a `debug`, the instance writes **one**
`Cfg` line, whichever list or render reaches it first:

- `help art: no addonName on the Options descriptor; drawing the client glyph`
- `help art: addonName "<name>" is not a loaded addon; drawing the client glyph`

Players see nothing; a developer with debug on sees why a mark is the blue disc. A list with no
helped entry never reaches the ladder and writes nothing, and neither does a host whose `helpIcon`
answers rung 1.

**O28 is a docblock correction only.** `Options.lua`'s descriptor docblock named `OptionsWidgets.lua`
as the reader of `addonName`; the reader has been `OptionsIdList.lua` since **L1**. The docblock now
says so, calls the field recommended for every host, and says it is the folder name and not the
MasterControls display label.

**What a consumer owes:** pass `addonName = addonName` on the Options descriptor, with
`local addonName, NS = ...` at the top of the file that builds it. Every collection host does from
v1.67.0. Only AuraMaster draws help marks today; BankLedger and LootHistory build id lists with no
`help`, and the other eight have no id list, so for them the field is latent. Cases:
`tests/test_options_idlist_layout.lua`.

## Previously, at 27.2.34.2.2.8.1.7.4.2

**`RenderTabbedSchema` takes three opt-in fields for a host that composed the strip itself to get
them (T8, [AbsorbTracker#32](https://github.com/tusharsaxena/AbsorbTracker/issues/32)).** All are off
by default, so a host that passes none draws and behaves exactly as at 27.2.34.2.2.7.1.7.4.2.

| Field | Since | What it does |
|---|---|---|
| `untabbedSkipRender` | **T8** | `true`: a group whose rows are **all** `skipRender` is no tab, unless a host tab (`tabs`) or an `afterGroup` hook is keyed by it, either of which draws it; a kept group keeps its declaration-order place. The rows stay in their group's bucket, so a mixed group's `skipRender` row is skipped by `RenderRows` as before and its subgroup heading is kept. The first return value still names every group. A page whose groups are all kept off the strip renders untabbed and is not reported as having no groups. |
| `disabledReplaces` | **T8** | `true`: a page `disabledFor` answers true for draws the notice and stops. No row is drawn, and no host tab's `render` runs. |
| `disabledNoticeFont` | **T8** | The notice's font object, by name (`O.TextRow`'s `fontObject`). Default `GameFontHighlightSmall`, as before. |
| `rerender` | **T8** | `function(ctx)`. A tab click sets `ctx.activeTab` to the clicked key and calls it **instead of** `ClearScroll` and a render of its own, so the host's whole redraw runs: its chrome above the strip and the refreshers it registers after the body survive the click. A raise is reported through the descriptor's `print` as `RENDER_FAILED` and the strip stays usable. The combat refusal at the tab button is unchanged. |

Without `rerender`, a tab click re-renders with the same `opts`, as before. Cases:
`tests/test_options_tabbed.lua`.

## Previously, at 27.2.34.2.2.7.1.7.4.2

**`RenderGrid` takes a `parent` and an `opts.gap`, and a failed item leaves no row (W34,
[KickCD#10](https://github.com/tusharsaxena/KickCD/issues/10)).** Additive: a two-argument call
draws exactly what it drew at 27.2.33.2.2.7.1.7.4.2, apart from the failed-item fix below.

- **`parent`**, the third argument: the container the rows go into. Absent, the page scroll
  (`EnsureScroll(ctx)`), as before; given, no page scroll is created behind it.
- **`opts.gap`**, on a fourth argument: the spacer height after each flushed or wide row. Absent,
  `lib.LAYOUT.ROW_VSPACER` (8), as before. `false` or `0` draws no spacer, for a list stacked at a
  fixed stride (a `ReorderList`'s, whose drop math assumes rows touch); any other number is that
  height.
- **A failed item takes no space.** A wide item whose render raised used to leave a blank
  full-width row and a gap behind it; its row is now released and nothing is added. A `make` that
  answers exactly `false` drew nothing and is treated the same way (a half item takes no cell). A
  `make` answering nil or anything else still counts as drawn, which is what every consumer's does.
- **Still no layout pass.** `RenderGrid` does not call `DoLayout()`, by decision rather than
  omission: hosts render several grids into one page and lay out once. Call
  `container:DoLayout()` after the last render, as `RenderRows` does for you.

Cases: `tests/test_options_flow.lua`.

## Previously, at 27.2.33.2.2.7.1.7.4.2

**The combat lock tells the host's debug log what it refused (gap G3 of the 2026-09-30 LibKa0s
debug-gaps run).** No member, row field, string or floor moves, and nothing drawn or printed to
chat changes. What changes is what reaches the descriptor's existing `debug(tag, message)` field;
a host that passes none sees nothing new.

- **One `Cfg` line per refused act (O27)**, `<what> refused (in combat)`, written by
  `O.__combatRefused(kind, subject[, subject2])` when the lock refuses, independent of the one gray
  chat notice per combat. Each text is written once per combat and re-armed at each combat edge, so
  a drag's throttled commits (a color's, or a live slider's under `commitOn = "change"`) are one
  line, not one per throttle tick. The seams pass the parts and `__combatRefused` joins them only
  when the lock is on and `debug` is a function, so a call out of combat, or with no `debug`, builds
  no string. What each file names:
  - `Options.lua` 27: `defaults <page title>` (the header Defaults button and the footer control),
    `defaults <pageKey>` (`O.RestoreDefaults`), `tab <pageKey>/<tabKey>` (`O.SelectTab`), and
    `show <pageKey>` (a page shown under the lock, covered instead of drawn).
  - `OptionsWidgets.lua` 33: `write <path>` (every widget write and a color commit),
    `button <text>` (a library button, *Reset all settings* among them, and a choice grid's extra
    cell), `toggle <label>` (`O.SessionCheckbox`).
  - `OptionsTabs.lua` 7: `tab <key>` (a tab click), `banner select <key>` and
    `banner action <text>` (`O.PageBanner`).
  - `OptionsNav.lua` 2: `rail <key>` (a nav rail click).
  - `OptionsIds.lua` 2: `id list change` (an add, a remove or a rebuild the lock refused).
  - `OptionsIdList.lua` 2: `id list toggle <id>`. The toggle now asks the lock once, before the
    host callback, where it asked twice (inside `callHost` and again after it), which would have
    written the line twice; what it does when refused (put the box back, call nothing) is unchanged.
- **The park's flush line (`OptionsRegistry.lua` 2).** A registration parked in combat already
  wrote `register parked (in combat)`; the end-of-combat replay now writes
  `register flushed (combat ended)` before it runs `CreateOptionsPanel`.
- **Silent default.** Absent `debug`, or a `debug` that is not a function, nothing is written.
  Cases: `tests/test_options_combat_debug.lua`.

## Previously, at 26.1.32.1.1.6.1.7.4.1

**The page registry leaves `Options.lua` for a file of its own (LK-ATS-04).** No member,
descriptor field, row field or drawn pixel changes; a host cannot observe this version except
through `lib.MODULES` and the version key.

- **`OptionsRegistry.lua` minor 1**: `O.RegisterOptionsPage`, `O.__pages`, `O.CreateOptionsPanel`
  and `O.OpenOptionsPanel`, with the state only they read (the page queue, the built list, the main
  category and its ID, the parked flag), attached per instance by `lib.__AttachRegistry(O, d)`; and
  the registration park's library half (`lib.__parkedPanels`, `lib.__OnParkEvent`,
  `lib.__parkRegistration`, the private `lib.__parkFrame`), whose one caller is
  `CreateOptionsPanel`.
- **`Options.lua` minor 26** loses the moved code. `lib:New` calls `lib.__AttachRegistry` where the
  four members used to be defined, so an instance gets its members in the same order as before. The
  sink the registry prints through is the shell's own, `O.__print`.
- **A seam of its own.** Nothing left in the shell read the registry's state, and the registry
  reaches the rest of the instance only through members (`O.CreatePanel`, `O.SetRenderer`,
  `O.AceGUI`, `O.__print`) and the descriptor. The peel takes `Options.lua` from 1462 lines to 1261.
- **Load order and pairing.** `OptionsRegistry.lua` loads right after `Options.lua`, the file it was
  peeled from, so the key gains a component there. It carries its own minor and the shell's,
  `lib.__registryMinor` / `lib.__registryShellMinor`. A copy without it has no
  `O.CreateOptionsPanel`, and a host fails when it calls it: the call-time failure a partly-copied
  Options major has always had.

## Previously, at 25.32.1.1.6.1.7.4.1

**The combat lock's page chrome leaves `OptionsTabs.lua` for a file of its own (LK-ATS-03).** No
member, descriptor field, row field or drawn pixel changes; a host cannot observe this version
except through `lib.MODULES` and the version key.

- **`OptionsCombat.lua` minor 1**: the library half of the combat cover that `OptionsTabs.lua` carried
  from its minors 2 and 3 — the one event frame (`lib.__combatFrame`), the page-scoped registration
  (`lib.__shownPages`, `lib.__syncCombatEvents`, `lib.__pageShown`, `lib.__pageHidden`), the
  dispatcher (`lib.__OnCombatEvent`) and the cover's geometry (`lib.__coverLevel`,
  `lib.__descendsFrom`) — and the instance's two cover members, `O.__buildCover` and
  `O.__releaseOwnedFocus`, attached per instance by `lib.__AttachCombat(O)`.
- **`OptionsTabs.lua` minor 6** loses the moved code. `lib.__AttachTabs` calls `lib.__AttachCombat`
  where the two members used to be defined, so an instance gets its members in the same order as
  before, and `Options.lua` does not move (its calls into the library half were already guarded).
  The refusal every tab control asks stays in `OptionsTabs.lua`.
- **A seam of its own.** Nothing in the moved code read a local of the strip, its art or the tabbed
  page, and nothing left behind reads a local of the moved code: the two meet only through `lib`
  fields. The peel takes `OptionsTabs.lua` from 1493 lines to 1293.
- **Load order and pairing.** `OptionsCombat.lua` loads right after `OptionsTabs.lua`, the
  file it was peeled from, so the key gains a component there. It carries its own minor and the shell's,
  `lib.__combatMinor` / `lib.__combatShellMinor`. A copy without it draws no cover and registers no
  event; the refusal still answers `InCombatLockdown()`.

## Previously, at 25.32.1.1.5.7.4.1

**The id surface leaves `OptionsWidgets.lua` for two files of its own (issue #32).** No member,
descriptor field, row field or drawn pixel changes; a host cannot observe this version except
through `lib.MODULES` and the version key.

- **`OptionsIds.lua` minor 1**: the module-scope id resolution and suggestion blocks, and the
  instance members built on them: `O.ResolveId`, `O.UnnamedCandidates`, `O.ID_NAME_HINT`, `O.IdInput`
  and its suggestion dropdown. Attached per instance by `lib.__AttachIds(O, w)`.
- **`OptionsIdList.lua` minor 1**: `O.IdList` and everything its entry lines are laid out with (the
  delete control, the help mark, `columns` and the floors it is measured against, the
  uncached-item batches). Attached per instance by `lib.__AttachIdList(O, d, ids)`, where `ids` is what
  `lib.__AttachIds` returned.
- **`OptionsWidgets.lua` minor 32** loses the moved code. `lib.__AttachWidgets` calls both attach
  functions where the id members used to be defined, so an instance gets its members in the same
  order as before, and `Options.lua` does not move. It hands them the sink, the combat refusal and its
  two row helpers (`startRow`, `renderRowGuarded`) rather than a restated copy of any of them.
- **Two files rather than one** because the id surface was about 2460 lines, more than one file may
  hold under layout-§1's 1500-line cap. The input and the list were already separate halves: the
  list reaches the input's half only through `drawIdInput`, eight helpers and three layout
  constants, all passed in the table `lib.__AttachIds` returns.
- **Pairing.** Each file carries its own minor and the shell's: `lib.__idsMinor` / `lib.__idsShellMinor`
  and `lib.__idListMinor` / `lib.__idListShellMinor`, the idiom `OptionsTabs.lua` uses. A copy with
  neither file draws no id widget and raises nothing, the same as a copy with no `OptionsWidgets.lua`.

## Previously, at 25.31.5.7.4.1

**OptionsNav minor 1: the nav rail.**

- **`O.NavRail(ctx, spec)`**, `spec = { entries = { { key, label, tooltip } }, value, onSelect, width }`:
  a pinned vertical list at the left of the page's body, the first level of a page that edits one
  instance out of many (options-ui-§13), in AceGUI's TreeGroup tree-pane look (tooltip-border
  backdrop, 0.1/0.1/0.1/0.5 fill, 0.4 border; gold `GameFontNormal` entries; the selected entry
  white on the blue `UI-QuestLogTitleHighlight` bar, and disabled, as the active tab is). `width`
  defaults to 120. Draw it after `O.PageBanner` and before `O.TabStrip`. The selection is the host's
  (`spec.value` / `spec.onSelect`, as `O.SubTabStrip`'s is); `onSelect` is pcall'd, and a click is
  refused in combat by the library as a tab click is. Entries are pooled per page and released on
  every call; an empty list releases the rail and records `ctx.railWidth = 0`.
- **`lib.__railInset(ctx)`**: the rail's width plus a 12px gap, or 0 with no rail. The one number
  the strip's placement, the content panel's left edge and the scroll's left anchor read, so the
  three cannot disagree. Library-level because `drawContentPanel` has no instance in reach.
- **The rail's top** is level with the selected tab's art top: `-(bannerHeight + TAB_H -
  activeArtHeight)`, the active cap atlas measured once on a probe texture and cached on success
  only, falling back to the strip's own pitch. Seams: `O.__railTop`, `O.__railEntryY`,
  `O.__navArtHeight`, `O.__resetNavArtHeight`, `O.__railInset`.

**Options minor 25: the scroll starts right of a nav rail.** `anchorScroll` adds `lib.__railInset(ctx)` to the scroll's left anchor, and `lib:New` attaches
`OptionsNav.lua` after `OptionsScroll.lua`. Both reads are guarded: with no rail, or no
`OptionsNav.lua` in the copy, the scroll is anchored exactly as at minor 24.

**OptionsTabs minor 5: the strip and the content panel start right of a nav rail.** `placeTabs` places every tab `lib.__railInset(ctx)` right of the chrome's left edge and wraps against
the chrome's width less that inset (never less than `TAB_MIN_W`, so the first render's zero-width
chrome cannot go negative; `replaceOnResize` re-places with the inset when the width arrives).
`drawContentPanel` moves the panel's left edge by the same inset. The banner, the header block and
the chrome divider stay full width. With no rail the numbers are minor 4's.

## Previously, at 24.31.4.7.4

Five changes share this version: `CreateOptionsPanel` parks in combat and `OpenOptionsPanel` answers
a boolean (below), the font preload moves out of the shell (after them), the two drag throttles
keep their own armed flag, the page chrome stops leaking a widget per render, and the tabbed page
moves to `OptionsTabs.lua` with host tabs, a disabled notice, a chrome hook and a banner action
(last).

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
only once combat ends; out of combat nothing changes. **The standard permits this park:**
`options-ui-§5` and `options-ui-§9` (standard v2.65.0) say the library **MAY** park a registration
requested under `InCombatLockdown()` and **MUST** replay it exactly once at `PLAYER_REGEN_ENABLED`,
whatever the host's stand-down state, and that a host **MUST NOT** add its own park on top. A
parked registration waits on the client, never on the user, so it is not the deferral
`options-ui-§9` forbids. **No instance member is added** (the original
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
leaves nothing to adopt** -- the member manifest at `members-24.31.4.7.4.json` is identical to
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
A session that loads a 23.30.3.7.3 copy first and a 24.31.4.7.4 copy second runs the older copy's
preload (defined by its shell) until the newer `OptionsScroll.lua` attaches and replaces it; the
state in `lib.__fontPreload` is shared across both, so no face loads twice.

**The drag throttles keep their own armed flag (W31).** `OptionsWidgets.lua` 30 -> **31**. The
slider's live commit (`commitOn` / `sliderCommit = "change"`) and the color picker's drag throttle
both re-arm one timer per 50 ms window through the descriptor's
[`scheduleTimer`](#the-panel-descriptor). Through W30 each one stored what `scheduleTimer` returned
and read it as "a timer is armed" on the next drag frame, so a host whose `scheduleTimer` answers
nil -- a `C_Timer.After` wrapper, which KickCD, LootHistory and MultiMeters all pass -- armed a fresh
timer and a fresh closure on **every** frame and committed about once a frame: the throttle was
defeated in silence (`KICKCD-R-19`). From W31 each throttle keeps a library-local boolean, set before
it calls `scheduleTimer` and cleared inside the callback, and **the return value is unused**. A host
whose timer answers a handle sees no difference. **No member or field is added or removed, and
there is nothing to adopt**: the three nil-returning hosts get the 50 ms throttle by re-vendoring.

**The page chrome stops leaking a widget per render (T4).** `OptionsTabs.lua` 3 -> **4**. Through T3
every full render of a page with a banner or a header block left something behind for good:
`O.PageBanner` created a fresh AceGUI `Dropdown`, `O.PageHeader` a fresh `Frame`, and the divider
under either a fresh texture, and the release hid them and unparented them but never gave any of
them back -- AceGUI recycles a widget only when it is Released, and the client never destroys a
frame or a region (`LibKa0s-R-02`). Every consumer that renders a banner or header page grew by one
widget and one texture per subject switch. From T4 each piece goes back to what owns it:

- **The banner's `Dropdown` is Released to AceGUI** when the band is next drawn, by either
  `PageBanner` or `PageHeader`. It is hidden at once and Released only **after** the replacement
  exists -- after `PageBanner`'s own `Create`, and after a `PageHeader` builder has run -- because
  the replacing render usually runs inside the old dropdown's `OnValueChanged`, and a widget
  Released on the way in would be the one AceGUI's pool hands straight back, re-initialized under its
  own callback. The library holds it under a private ctx key; **`ctx.__bannerWidget` stays the
  host's**, which several hosts write themselves, and the library neither reads nor writes it.
- **`PageHeader` hands back the same `Frame` on every render of one page**, from a pool of one held
  on the ctx, re-anchored and resized each time. **What a builder draws into that frame is still the
  host's to release**, as it always was: AceGUI widgets the host Releases after its render, as the
  collection's two `PageHeader` hosts do, behave exactly as before; a builder that creates raw
  regions into the frame on every call now stacks them on the one frame, where through T3 each set
  was hidden with its own frame.
- **The divider is one texture per page**, created on the first render that draws a rule, hidden on
  release and re-anchored and shown on the next. `SetParent(nil)` is never called on it: that is
  not a call the client promises to honor on a Region.

`ctx.__chromeKids` still lists what the current render drew, in order, and still empties on every
release; it no longer drives the release. **No member or spec field is added or removed, and there
is nothing to adopt**: every consumer gets the fix by re-vendoring. The kit's AceGUI fake now counts
what is still out (`M.__aceguiLive`, kit revision 26), which is what the new cases in
`tests/test_options_tabs.lua` read.

**The tabbed page moves to `OptionsTabs.lua` and takes `opts` (T4).** `O.RenderTabbedSchema` is now
defined in `OptionsTabs.lua`'s attach, which the shell calls as `lib.__AttachTabs(O, d)` so it can read
`d.rowsForPage`; that is the only descriptor field the chrome half reads. `OptionsWidgets.lua` keeps an
untabbed stand-in under the same name, which the chrome half's attach replaces: a partial copy without
`OptionsTabs.lua` still draws every row with its headings and ignores `opts`. A partial copy without
`OptionsWidgets.lua` has no `RenderTabbedSchema` at all, as before. The four-argument call every host
makes is unchanged. AuraMaster (`AuraMaster-R-04`) forked the whole render for the fields below, and
AbsorbTracker, KickCD, ConsumableMaster and MultiMeters hand-build the same strip shape, so none of
them is a per-consumer flag (anti-pattern #55). A fifth argument, every field optional:

| Field | Since | What it does |
|---|---|---|
| `tabs` | **T4** | `{ { key, label, tooltip, before, render = function(ctx, rows) } }`: host tabs drawn by their own callback. One whose `key` equals a schema group takes that group's place in the strip (its `label` and `tooltip` win when given) and `render` is handed that group's rows, which the flow engine then does not draw. Any other is placed ahead of the tab `before` names, or last when that tab is not drawn, and `render` is handed nil. An entry with no `key` or no `render` function is not a tab. A page whose only tabs are host tabs draws its strip and is not reported as having no groups. |
| `cfg` | **T4** | The subject this render edits, handed to `disabledFor` and `disabledNotice`. |
| `disabledFor` | **T4** | `function(cfg)`. Answering true draws `disabledNotice` **above** the rows and renders the rows disabled (`RenderRows`' `opts.disabled`); a host tab's `render` runs with `ctx.__renderDisabled` set, restored on the way out, a raise included. The rows are still drawn: the notice does not replace them. A raising predicate reads as enabled, as a row's `disabledIf` does. |
| `disabledNotice` | **T4** | A string, or `function(cfg)` answering one, drawn with `O.TextRow` in `GameFontHighlightSmall` followed by a row gap. The library adds no color; a host embeds its own escape sequence. |
| `chrome` | **T4** | `function(ctx)`, called once per render, after the strip and before the notice and the rows: a line that belongs above every tab. A tab click is a render, so it is called again. A banner is not chrome here: draw `PageBanner` or `PageHeader` before calling `RenderTabbedSchema`, since both release the strip. |

A tab click re-renders with the same `opts`. `RenderTabbedSchema` also returns a second value from
T4, the key of every tab the strip drew in strip order; the first is still the group names.

**`O.PageBanner` gains `action` (T4).** `spec.action = { text, tooltip, onClick }` draws an AceGUI
`Button` in the band's right half, level with the dropdown's control (14px down under a label, 0
without), and the dropdown takes the left half. This is the picker+create band of `options-ui-§14`,
which AuraMaster built inside `PageHeader`'s frame by hand. `onClick` is pcall'd (a raise prints
`BUTTON_FAILED`) and refused in combat, as the picker's selection is. The Button is held and Released
exactly as the dropdown is (hidden when the band is next drawn, Released once the replacement
exists), so a create act that re-renders the page from inside its own `OnClick` is never handed its
own button back. `PageBanner` returns the Button as a second value. A spec without `action` draws what
T3 drew, apart from the release fix above.

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
box 20px tall with its center at y 43, button 24px with its center at y 42 — **one pixel apart, and
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
what W28 drew. `spec.helpIcon` still wins over everything. (From **L3** the name is also checked
against the client's loaded addons before Media is asked; see
[Previously, at 28.2.34.2.3.8.1.7.4.2](#previously-at-282342381742).)

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
there are **three new optional spec fields** and **one behavior change that needs no adoption**.

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
| A drawer's header click, a drawer's action | D1 | — |
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
`O.RenderTabbedSchema` (in `OptionsWidgets.lua` at this historic version; from T4 its untabbed stand-in there) falls back to the untabbed render when `O.TabStrip`
is absent — every row with its section headings, exactly what its no-groups branch already does —
and `O.PageBanner` (in `OptionsTabs.lua`) skips its tooltip when `O.AttachTooltip` is absent. The
two files are paired on the **shell's** minor rather than on each other's, so a copy carrying one
and not the other is a state LibStub cannot see; a page that still draws is a smaller failure than
a page that raises.

**`OptionsTabs.lua` takes no descriptor** (until T4, which passes it for `rowsForPage`). `lib.__AttachTabs(O)` is called with the instance alone,
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

**Color storage** is a descriptor codec, in **both** majors. AbsorbTracker stores
`{r=,g=,b=,a=}`; KickCD and the Ka0s options color widget store arrays. Baking either in would
force the other to translate at every read site in the addon, so `colorDecode` / `colorEncode` are
descriptor options — under the same names on the Options and Slash descriptors, so a host passes
one pair to both — and the named-key form is only the default. `Slash.FormatValue` additionally
reads the positional shape directly, so the common case needs no descriptor at all.

**The fifth widget type** ships in `-1.0` rather than being added later. KickCD has a free-text
edit box; AbsorbTracker has no equivalent. Adding a *type* later is additive, but retrofitting one
into a dispatch table the major has already frozen is not. It is opted into with
`dialogControl = "EditBox"` rather than inferred from a missing `values` list, because inference
would silently turn a row whose values function happened to return empty into a free-text field.

## What is not here

`library-stack-§7` asks for each rejected promotion to be recorded with its reason where the next
author will look, and for this major that is here. A row is reopened when its trigger fires, not
before.

| Rejected | Consumers counted | Why | Re-check trigger |
|---|---|---|---|
| `O.MixedGrid` — a composer drawing a header line and one line per row, one cell per column, each column naming its maker and each cell an ordinary schema row ([LibKa0s#50](https://github.com/tusharsaxena/LibKa0s/issues/50), rejected 2026-10-22) | **1**: DropWatcher's Situations table. The census of all fourteen roster addons found no second: MultiMeters' visibility contexts are one bool column, AuraMaster's zones one bool per zone (its categories already use `ChoiceGrid`), PremadeGroupsFilterExtension's region colors one color per region, QuickComms' conditions are drawers, KickCD's spell rows a record list, LootHistory's price sources a `ReorderList`. | Bar 1 fails on the count. Bar 2 fails in prospect: the one consumer is already built in the addon as a raw-frame table in a look the owner chose on purpose (fixed pixel columns, striping, gold headers), and adopting a Flow-line grid would need a style flag, a per-row label state driven by another cell, per-column dropdown widths and a column whose path is outside the row's namespace. Bar 3 fails: the shape went through three forms in nine days. `OptionsWidgets.lua` also sits at its band trigger, and the one-consumer exceptions (`LineChart`, `Drawer`) are not to become a third. | A second roster addon ships or specs a fixed set of rows by at least two setting columns of different maker types, every cell a schema row written through the addon's write seam, and both addons accept the same presentation; or DropWatcher's owner asks to replace the raw-frame table with Flow lines. Re-run the census whenever an addon joins `ADDONS.md`. |
| `O.GlowGroup` — a glow settings composer ([LibKa0s#56](https://github.com/tusharsaxena/LibKa0s/issues/56)) | **3** hosts, three layouts | Recorded with the major it serves: see [Glow version 1, *What is not here*](../Glow/version-1-docs.md#what-is-not-here). | options-ui gains a canonical glow block, or two hosts converge on one glow row layout. |

## The panel descriptor

Everything a host supplies to `lib:New(descriptor)`.

| Field | Type | Required | Since | Meaning |
|---|---|---|---|---|
| `parentTitle` | string | yes | O1 | The brand. Shown on the main page and as the breadcrumb prefix on every sub-page. |
| `mainPanelName` | string | yes | O1 | Frame name for the main canvas, so `/framestack` attributes it to the host and two addons cannot collide. |
| `addonName` | string | recommended | **W29** (checked from **L3**) | The host's addon **folder** name, its first vararg (`local addonName, NS = ...`). The route to the shipped `info` art for `O.IdList` help marks, through `LibKa0s-Media-1.0`'s `Icon`. From **L3** it is used only when `C_AddOns.IsAddOnLoaded` reports it loaded, trusted when there is no `C_AddOns` reader (from **L4** the removed bare global `IsAddOnLoaded` is never read); otherwise the mark draws the client glyph and `debug` gets one `Cfg` line. **Not** the MasterControls compose spec's `addonName`, which is a display label. **From O31** it is also the pages' **skin owner**, once that addon called `LibKa0s-Skin-1.0`'s `RegisterOwner` — see [The page's skin owner](#the-pages-skin-owner-o31-s5). |
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
| `scheduleTimer` | function(fn, delay) | no | O1 | Backs the 50 ms color-drag throttle and the slider's live commit. A descriptor field rather than an AceTimer embed, because embedding would be this library's second dependency-budget breach. Without it a drag commits every frame. **Its return value is unused** (W31): the library keeps its own armed flag, so a `C_Timer.After` wrapper that answers nil is throttled like one that answers a handle. Through W30 a nil return defeated the throttle. |
| `getLSM` | function | no | O1 | Returns LibSharedMedia-3.0, for `LSMValues` and, **since O17**, for the font preload a panel's show runs ([`lib.__PreloadFonts`](#lib__preloadfontslsm--number)). Absent, a host gets no preload. |
| `validate` | function | no | O1 | Runs once, before the page builders. A host's schema-shape check. |
| `onAceGUI` | function(AceGUI) | no | O1 | Handed the resolved AceGUI so the host can stash it (library-stack-§4) for its own page files. |
| `buildMain` | function(ctx) | no | O1 | Draws the main page's body, on its first OnShow. |
| `colorDecode` | function(stored) | no | O1 | → `r, g, b, a`. Defaults to the `{r=,g=,b=,a=}` shape. |
| `colorEncode` | function(r,g,b,a) | no | O1 | → stored. Defaults to the same. |
| `sliderCommit` | string | no | O1 | `"change"` makes every slider commit on the drag as well as on release, throttled through `scheduleTimer`. Default is release-only; a single row overrides either way with `commitOn`. |
| `debug` | function(tag, message) | no | O1 | Developer log line, through the host's gated sink. `Cfg` lines: `opened`, `open refused (in combat)` and `register parked (in combat)` (O24); from **O27** the combat lock's `<what> refused (in combat)`, once per text per combat, and the park's `register flushed (combat ended)`; from **L3** one `help art: ...` line per instance when an id list's help art falls past the loaded-addon rung. See [Previously, at 27.2.33.2.2.7.1.7.4.2](#previously-at-272332271742) and [Previously, at 28.2.34.2.3.8.1.7.4.2](#previously-at-282342381742). |

**Consumer census, v1.67.0** ([`CONSUMERS.md`](../CONSUMERS.md)). No host calls or passes these:

- `afterRestoreAll`: no consumer as of v1.67.0, kept because it is the hook for reset state in neither the schema nor the profile; since window positions moved into the profile no host has any.

`addonName` left this list at v1.67.0: all 11 hosts pass it, in each host's `settings/OptionsSetup.lua` (LibKa0s#42). Only AuraMaster draws help marks with it today.

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

**Consumer census, v1.67.0** ([`CONSUMERS.md`](../CONSUMERS.md)). No host calls or passes these:

- `lib.LAYOUT`: no consumer as of v1.67.0, kept because it holds the panel geometry the library draws to; the four published keys are read off the LibStub table by a host that aligns to the panel, and none does today. KickCD deleted its two copies of internal header keys rather than re-reading them (KickCD#36).
- `lib.PatchAlwaysShowScrollbar`: no consumer as of v1.67.0, kept because `EnsureScroll` applies it to every scroll the library builds; a host calls it only for a scroll frame of its own.
- `lib.STRINGS`: no consumer as of v1.67.0, kept because it is the English fallback for the combat lock and the other library strings.

`lib.KEYBIND_STRINGS` (K1) and `lib.APPEARANCE_STRINGS` (A1) are the two tabs' words, after the
census; see their sections.

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
| `lib.__OnCombatEvent(event)` | O22 (in OptionsTabs.lua and page-scoped: **T3**; in OptionsCombat.lua from 25.32.1.1.6.1.7.4.1) | The dispatcher: re-syncs the registration and returns if no page is on screen; else sets or clears the flag, then calls every registered hook with `locked`, each pcall'd. |
| `lib.__combatHooks` | O22 | Weak-keyed set of `hook(locked)`, one per instance, each held by its instance as `O.__combatHook`. |
| `lib.__combatFrame` | T2 (page-scoped: **T3**) | The one frame for both events. Created once, hidden, kept across an upgrade; registered only while a page is on screen (T3). Its `OnEvent` resolves `lib.__OnCombatEvent` at call time and is re-set by each newer copy. |
| `lib.__shownPages` | **T3** | Weak-keyed set of every ctx on screen, across hosts. |
| `lib.__pageShown(ctx)` / `lib.__pageHidden(ctx)` | **T3** | Called from a page's show and hide: add (if the panel is on screen) and register, or remove and re-sync. |
| `lib.__syncCombatEvents()` | **T3** | Prune pages off screen, register or unregister to match, and clear `lib.__combatLocked` when none is left. |
| `lib.__coverLevel(panel, cover)` → number | T2 | The level a cover takes over a page on screen: `max(panel + 100, deepest descendant + 1)`, at most 10000. |
| `lib.__descendsFrom(frame, ancestor)` → boolean | T2 | A bounded `GetParent` walk; picks the AceGUI pullout that is the host's to close. |
| `lib.STRINGS.COMBAT_LOCKED` | O22 | *Settings are locked during combat.* — the cover's line, the standard's words. |
| `lib.STRINGS.COMBAT_LOCKED_NOTICE` | O22 | The gray chat line, at most once per combat per host. |

On the instance, equally internal: `O.__combatRefused(kind, subject[, subject2])` (O22, the refusal every file asks; from **O27** the parts of the refused act the `Cfg` line names, joined only under the lock with a `debug` to write to),
`O.__buildCover(panel)` (T2) and `O.__releaseOwnedFocus(panels)` (T2; from **OC2** it also calls
`O.__closeOwnedSuggest(panels)`, **I3**, which closes an id suggestion list a box on one of those
pages opened), and `ctx.__combatCover` on every ctx `CreatePanel` returns.

### The registration park's library-level names (O24)

**Since O24**, and defined in `OptionsRegistry.lua` from 26.1.32.1.1.6.1.7.4.1. Internal for the same reasons as the lock's names above; a host calls none of them.

| Name | Since | Meaning |
|---|---|---|
| `lib.__parkedPanels` | O24 | The parked replays, in the order they were parked. Kept across an upgrade; replaced with a fresh table when drained. |
| `lib.__parkFrame` | O24 | The park's private frame, separate from `lib.__combatFrame`. Created on the first park, hidden, kept across an upgrade; registered for `PLAYER_REGEN_ENABLED` only while `lib.__parkedPanels` is non-empty. |
| `lib.__parkRegistration(replay)` → boolean | O24 | Append `replay`, (re)set the frame's `OnEvent` and register the event. `false` when no frame can be made, and the caller then registers at once. |
| `lib.__OnParkEvent(event)` | O24 | Ignores every event but `PLAYER_REGEN_ENABLED`; on it, unregisters, takes the parked list and replays each once, each `pcall`'d, then raises the first error (if any) so it is reported rather than swallowed. A replay that finds the client still locked parks again. |

### `lib.__railInset(ctx)` → number (N1)

**Since N1.** `ctx.railWidth + 12`, or `0` for no rail (`railWidth` nil or `<= 0`, or no `ctx`). It is read by `anchorScroll` (O25), `placeTabs` and `drawContentPanel` (T5), and every read is guarded, so a copy without `OptionsNav.lua` lays out as at 24.31.4.7.4. Library-level because `drawContentPanel` is a file-level local with no instance in reach; `O.__railInset` is the same function.

## The instance surface

Everything `lib:New(descriptor)` returns on the instance.

| Name | Since | Meaning |
|---|---|---|
| `CreatePanel(name, title, opts)` | O1 (canvas contract: **O5**; chrome slot: **O10**; combat cover: **O22**) | A canvas Frame with the unified header stamped on top, returning the `ctx` every render call threads through. `opts` = `{ pageKey, isMain, defaultsButton, defaultsTooltip }`. Registers the ctx so the refresh fan-out reaches it. Also stamps the **Blizzard canvas contract** — `OnCommit` and `OnRefresh` inert (writes land immediately through the host's write seam, and `SetRenderer` already owns re-show), and `OnDefault` **forwarding** to the panel's `defaultsOnClick` so the Settings window's footer control and the header Defaults button stay one implementation. A forwarder rather than an assignment because hosts park `defaultsOnClick` *after* this returns. The returned `ctx` now also carries `chrome` (a pinned `Frame` between the header and the scroll) and `chromeHeight` (starting at `0`) — see [What changed at this version](#previously-at-24314774). From **O22** it also builds the page's combat cover (`ctx.__combatCover`), hidden, and the canvas contract's `OnDefault` is refused in combat. |
| `EnsureDefaultsButton(panel)` | O1 | Builds the header's Defaults button on the panel's **first OnShow**, never at build time. Idempotent, and a no-op on a panel that did not ask. |
| `EnsureScroll(ctx)` | O1 | The lazy AceGUI ScrollFrame, patched for an always-visible scrollbar. |
| `ClearScroll(ctx)` | O1 (`lastSubgroup`: **O14**) | Release the children, reset **both** heading trackers (`ctx.lastGroup` and `ctx.lastSubgroup`), and **reassign** `ctx.refreshers`. |
| `Section(ctx, label)` | W1 | A full-width Heading, with the inter-section spacers. |
| `AddSpacer(scroll, height)` | W1 | An invisible full-width row. |
| `TextRow(ctx, text, opts)` | **W6** | A full-width Label, left-justified, added to `EnsureScroll(ctx)` and returned. `opts.fontObject` is a `_G` font-object **name**; `opts.justify` defaults to `"LEFT"`. Returns nil when AceGUI or the scroll is absent. Owns the `w.label` / `SetJustifyH` / `SetFontObject` guard pair **once**. |
| `BuildLandingPage(ctx, spec)` | **W6** | The whole landing body: clear, logo, one-liner, then a heading and its rows per section. See [The landing page](#the-landing-page). |
| `AttachTooltip(widget, label, tooltip)` | W1 | Works on AceGUI widgets and on plain frames. |
| `InlineButtonPair(ctx, left, right)` | W1 | Two action buttons (not settings) in one Flow row, each inset to `BUTTON_PAIR_REL`. A **nil** `right` draws the left button alone, at the pair's width, so it still lines up with every other page's — which is the shape a frameless addon's Master controls tab needs. A throwing `onClick` is reported, never propagated into AceGUI's dispatch. A spec carrying **no** `onClick` is reported once at BUILD time (`lib.STRINGS.DEAD_BUTTON`, naming the button's text) and drawn anyway — the composer emits the master group's two resets unconditionally, so a host that never supplied `onResetAll`/`onResetPosition` is told rather than shipping a live-looking button that swallows the click. **From W16**, drawn inside a disabled render (`RenderRows`' `opts.disabled`, or a disabled `ChoiceGrid` / `IdInput` / `IdList`), both buttons are drawn disabled. |
| `RenderField(ctx, row, parent, relWidth)` | W1 (path-less rows: **W15**; `disabledIf` on every maker: **W16**) | Dispatch by `row.type` to one of the five makers. Returns nil for an unknown type rather than erroring — a misspelled type costs one row, not the page. A row with no `path` is read and written through its own `get` / `set` from W15 — see [Previously, at 15.15.4.3](#previously-at-1515543). From W16 every maker honors `row.disabledIf` — see [What changed at this version](#previously-at-24314774). |
| `SessionCheckbox(ctx, parent, relWidth, spec)` | W1 (disabled render: **W16**) | A checkbox wired to caller-supplied `get`/`set` instead of a settings path, for runtime-only toggles that must never persist. From W16 it is drawn disabled when drawn inside a disabled render. |
| `RenderRows(ctx, rows, afterGroup, pairWith, opts)` | W1 (`opts.noHeadings`: **W9**; `opts.disabled`: **W16**; `shownWhen`: **W22**, its `any` form: **SW1**) | The flow engine, over an **explicit** row list — which is what lets a host render a filtered subset through the same code. `opts = { noHeadings = true }` suppresses the automatic `Section` heading, for a page whose sections are drawn as tabs instead (options-ui-§13); the row-boundary flush and `ctx.lastGroup` advance still happen. Omitted by every untabbed caller. **`opts.disabled = true` (W16)** draws every widget of the call disabled, the widgets an `afterGroup` or `pairWith` hook draws included, through `ctx.__renderDisabled` held for the call alone. A nested call inherits it, and the outer value is restored on a raise, which is re-raised unchanged — see [What changed at this version](#previously-at-24314774). |
| `RenderSchema(ctx, pageKey, afterGroup, pairWith)` | W1 | The per-page wrapper. |
| `RenderTabbedSchema(ctx, pageKey, afterGroup, pairWith, opts)` | **W9** (`opts`: **T4**, **T8**) | Render one page as a tab strip over its own sections. Defined in `OptionsTabs.lua` from **T4**; `OptionsWidgets.lua` keeps an untabbed stand-in that ignores `opts` for a partial copy without it. `opts` = `{ tabs, cfg, disabledFor, disabledNotice, chrome }` (**T4**, see [24.31.4.7.4](#previously-at-24314774)) and `{ untabbedSkipRender, disabledReplaces, disabledNoticeFont, rerender }` (**T8**, see [Previously, at 27.2.34.2.2.8.1.7.4.2](#previously-at-272342281742)), each optional and off by default. The partition is by `row.group`, in declaration order — each group is exactly one tab, and there is no second field naming a group's tab (options-ui-§13); from **T4** `opts.tabs` can add host tabs that own no group, and a host tab keyed by a group name replaces that group's tab. **Every page draws a strip from W13, including a one-group page** — the `#groups < 2` fallback to `RenderSchema` is gone, and the only exemption is a page the host does not route through this function at all (the AceConfig-drawn Profiles page). A page whose rows carry **no** `group` is reported by page key through the descriptor's `print` and rendered untabbed. A stale `ctx.activeTab` heals to the first tab in the strip — the first group unless a host tab is placed before it, and a host tab on a page whose tabs are all host tabs. A tab click re-enters through `ClearScroll` and this function again — the same structural path a subject change already takes, but that path carries no combat refusal to inherit: `SetRenderer`'s guard covers opening or switching a category, not redrawing inside an already-open panel, so a tab click needs no guard and none is added (options-ui-§13). Returns the group names, in tab order, and from **T4** every drawn tab's key in strip order. |
| `TabStrip(ctx, spec)` | **W9** | A pinned tab strip in `ctx.chrome` (options-ui-§13). `spec = { tabs = { { key, label, tooltip } }, value, onSelect }`. One `Button` per tab, the active tab the disabled one. Wraps its buttons across rows via `__layoutTabs`, places them via `__tabPlacement`, and reserves the band via `__tabBand` + `SetChromeHeight` — **after** the wrap is known. Each tab is three slices of the client's `Options_Tab_*` atlases; the selected one is drawn from the Active family and its foot overlaps the `Options_InnerFrame` content panel `TabStrip` also draws (**W11**). Re-places itself once when `ctx.chrome` first learns a real width (**W11**). **Its geometry is invariant under the selection from W13.** **From W14 the buttons and the content panel are acquired from `LibKa0s-Pool-1.0` pools held on the `ctx` rather than created per click** — see [What changed at this version](#previously-at-24314774). Returns the buttons in tab order, or nil having drawn nothing. |
| `SubTabStrip(ctx, parent, spec)` | **W13** | A **secondary** strip drawn inside the scroll as ordinary page content, parented to a frame the host supplies (options-ui-§13). Same `spec` shape as `TabStrip`, same selection-invariant pitch, its own ledger (`ctx.__subTabKids`) released on entry, and **no** content panel and **no** `SetChromeHeight` — the page already has both. **Not pooled at W14**, unlike the primary strip: its parent is a frame AceGUI takes back, so its buttons are unparented on release and cannot be recycled. Returns the buttons in tab order **and** the total height the strip occupies, so the host can size the frame it handed in, or nil having drawn nothing. The selection is the host's state: `spec.value` and `spec.onSelect` are the whole contract, and the convention for the collection is `ctx.activeSubTab` as a table keyed by the primary tab's key, session-only and never persisted. |
| `KeybindingsTab(spec)` | **K2** | The Keybindings tab's `opts.tabs` entry for `RenderTabbedSchema`: `{ key, label, tooltip, before, render }`, key `Keybindings` and last unless `spec` says otherwise. See [The Keybindings tab](#the-keybindings-tab-optionskeybindslua-minor-2). |
| `KeybindRows(ctx, spec, parent)` | **K2** | Draws the Keybindings rows into `parent` (default the page's scroll) and returns the row records, or nil when degraded. For a host-built strip's body. |
| `KEYBINDS_UNCHANGED` | **K2** | `"Key bindings are not changed."`, the sentence a General page's `opts.defaultsTooltip` ends with (`options-ui-§20`). |
| `AppearanceTab(spec)` | **A1** | The Appearance tab's entry, `{ key, label, tooltip, before, render }`: for `RenderTabbedSchema`'s `opts.tabs`, key `Appearance` (labeled "Skin" since **A3**) and `before` the Keybindings tab's key unless `spec` says otherwise, or for a host-drawn strip (`render` is the body). See [The Appearance tab](#the-appearance-tab-optionsappearancelua-minor-1). |
| `AppearanceRows(ctx, spec, parent)` | **A1** | Draws the Appearance rows into `parent` (default the page's scroll) and returns the view, or nil when degraded. For a host-built strip's body. |
| `SkinPicker(spec)` | **P1** | Shows the skin picker (one up at a time across every Ka0s addon, a window per owner) and answers its frame; `nil, "queued"` while another owner's picker is up or the queue waits out combat (it shows when that one closes, or when combat ends); nil when degraded. See [The skin picker](#the-skin-picker-optionsskinpickerlua-minor-2). |
| `HideSkinPicker()` | **P1** | Takes this instance's owners out of the picker queue (no `onClose`) and dismisses its window when it is the one up (`spec.onClose` runs, a pending preview is put back). |
| `SkinVerb(spec)` | **P3** | The `/<slash> skin` verb's act (`LK-11`): `SkinPicker(spec)` on demand, whatever the profile's seen flag says (the host passes its first-run spec), saying why when nothing shows. In combat nothing shows and `VERB_COMBAT` prints on every call (`nil, "combat"`); queued, `VERB_QUEUED` (`nil, "queued"`); no picker to show, `VERB_UNAVAILABLE` (`nil, "unavailable"`). See [`O.SkinVerb(spec)`](#oskinverbspec). |
| `Drawer(ctx, spec)` | **D1** | A header bar (chevron, name gold while set, one-line summary) that opens a bordered box joined under it, filled by `spec.body(ctx, box)` with ordinary rows. See [The drawer](#the-drawer). |
| `NavRail(ctx, spec)` | **N1** | The pinned nav rail, the first level of a page that edits one instance out of many (options-ui-§13): `spec = { entries = { { key, label, tooltip } }, value, onSelect, width }`, `width` 120 by default. Draw after `PageBanner`, before `TabStrip`. Records `ctx.railWidth`, which `lib.__railInset` turns into the inset the strip, the content panel and the scroll start at. Entries pooled per page, released on every call; the selected entry disabled; a click refused in combat by the library; `onSelect` pcall'd. The selection is the host's, as `SubTabStrip`'s is. Returns the entry buttons in rail order, or nil having drawn nothing (an empty list releases the rail, `railWidth` 0). |
| `PageBanner(ctx, spec)` | **W9** | The page's picker, pinned above the strip and the scroll (options-ui-§14) — the only picker a page may have. `spec = { label, list, order, value, onSelect, tooltip, action }`; `action = { text, tooltip, onClick }` (**T4**) draws a `Button` in the band's right half for the picker+create band, pcall'd, refused in combat, and Released like the dropdown. Draws one AceGUI `Dropdown` into `ctx.chrome`, plus the gap / hairline / gap that separate it from the strip (options-ui-§14); records the whole band in `ctx.__bannerHeight` via `__bannerBand` and reserves it with `SetChromeHeight`. Measures the dropdown and **floors** at `L.BANNER_H` rather than forcing that height (**W10**). From **T4** the previous render's dropdown is Released to AceGUI once the new one exists, rather than hidden and kept. **Draw it before `TabStrip`.** Returns the dropdown, or nil having drawn nothing, and the action's `Button` as a second value when there is one. |
| `PageHeader(ctx, spec)` | **W13** | A host-drawn block pinned in the same band, for controls that apply to **every** tab (options-ui-§14). `spec = { height, build = function(ctx, frame) end, divider = <default true> }`. Anchors a `Frame` across `ctx.chrome`, ledgers it, draws the hairline unless told not to, records the widened band in `ctx.__bannerHeight` via `__bannerBand`, reserves it with `SetChromeHeight`, then calls `build` inside a `pcall` — a raising builder is reported and costs the block, not the page. From **T4** the frame comes from a per-page pool of one, so every render of one page is handed **the same frame**; what `build` draws into it is the host's to release. **A page draws at most one chrome block**: this and `PageBanner` both release the chrome band and both write `ctx.__bannerHeight`, so the second call replaces the first. **Draw it before `TabStrip`.** Returns the frame, or nil having drawn nothing. |
| `SetChromeHeight(ctx, height)` | **O10** | Reserve `height` pixels of pinned chrome above the scroll, and re-anchor a live scroll to match. Idempotent. `height <= 0` hides `ctx.chrome`. Call only after the wrap of whatever is being reserved is known. |
| `__scrollTopInset(ctx)` | **O10** | `L.CHROME_GAP + (ctx.chromeHeight or 0)` — the seam `EnsureScroll` and `SetChromeHeight` both read for the scroll's top anchor, so the two cannot disagree. |
| `__layoutTabs(widths, available, gap)` | **W9** | Pure arithmetic: pack tab pixel widths into rows that fit `available`. A tab wider than `available` is placed alone rather than dropped. Returns rows of 1-based indices into `widths`. Test seam for the wrap rule, callable with no widgets. |
| `__tabPlacement(widths, available, gap, top, rowPitch)` | **W10** (signature: **W12**) | Pure arithmetic: the wrap from `__layoutTabs` turned into `{ index, width, x, y }` per tab, plus the row count. `top` is the banner's finished band, which is why row 1 no longer lands on the banner. `rowPitch` is the tab ART's measured height, not the button's. Callable with no widgets. |
| `__tabBand(top, rowCount, tabH, rowPitch)` | **W10** (signature: **W12**) | Pure arithmetic: how many pixels the strip reserves in total, banner included — which is also where the content panel's top edge lands. **(n − 1) pitches plus one whole tab**, because every row but the last is overlapped by the one under it. Took a `rowGap` through 12.11.3 and a `baselineH` through 11.10.3. |
| `__bannerBand(rawHeight, gapTop, ruleH, gapBottom)` | **W10** | Pure arithmetic: the banner's own height widened by the gap, hairline and gap that separate it from the strip (options-ui-§14). What `ctx.__bannerHeight` holds. |
| `__tabArtHeight()` | **W13** | The measured row pitch — the **unselected** tab art's own height, or `TAB_H` where nothing can be measured. Memoized on success only. Published because the invariant a suite has to pin is unassertable without the one number the band and every row offset are both built from. |
| `__resetTabArtHeight()` | **W13** | Forget that measurement. A harness seam; an atlas does not change size mid-session. |
| `RegisterOptionsPage(key, name, builder)` | O1 | Queue a page. Builders run once, in order, at `CreateOptionsPanel`. From `OptionsRegistry.lua` minor 4 a builder that answers its subcategory (`RegisterCanvasLayoutSubcategory`'s first answer) is remembered for `OpenOptionsPanel(key)`; answering nothing is still fine. |
| `CreateOptionsPanel()` | O1 (combat park: **O24**) | Resolve AceGUI, hand it to the host, validate, register the main canvas, run every builder. Idempotent. **From O24**, under `InCombatLockdown()` it registers nothing, parks the call and replays it once at `PLAYER_REGEN_ENABLED`; a second call while parked is a no-op. |
| `OpenOptionsPanel(pageKey)` → `true`, `false` or `nil` | O1 (combat refusal: O3; return value: **O24**; `pageKey`: `OptionsRegistry.lua` minor 4) | Open the category. With `pageKey` (minor 4), the key `RegisterOptionsPage` was given, open that page's own subcategory: the category its builder answered, else the main category's subcategory carrying the page's registered name (`GetSubcategories`, under pcall); a key that names no built page, or a page whose category is not found, opens the main category, as no key does. **Refuses** under combat and never defers-and-replays. The gate for a page **shown** in combat another way is the lock (**O22**). **From O24** answers `true` when opened, `false` when refused in combat, and `nil` when there is no category to open; through O23 it returned nothing. |
| `RestoreDefaults(pageKey, ctx)` | O1 | The per-page Defaults button. Refreshes only the ctx it was given. **From O16** the page walk runs inside the descriptor's optional `bulkBegin` / `bulkEnd` bracket (act `"reset"`, scope `pageKey`); the refresh runs after it closes. **From O22** refused in combat (nothing is reset); `RestoreAllDefaults` is not, because a slash reset verb calls it. |
| `RestoreAllDefaults()` | O1 | Without `resetProfile`: every non-vetoed row, then `afterRestoreAll`, then a full refresh — unchanged. **With `resetProfile` (O9):** only the `sessionOnly` rows, then `resetProfile()`, then `afterRestoreAll`, then a full refresh. **From O16** everything before the refresh — the row walk, `resetProfile` and `afterRestoreAll` — runs inside the descriptor's optional `bulkBegin` / `bulkEnd` bracket (act `"reset"`, scope `"all"`). |
| `SetRenderer(ctx, fn)` | O1 (combat lock: **O22**) | Declare how a page draws itself. The library owns *when*: first show, again after a refresh marked it dirty while hidden, and — from O22 — at `PLAYER_REGEN_ENABLED` for a page on screen that combat left owed a render. Also builds the Defaults button. Under combat it **covers** the page and draws nothing; through O21 it closed the settings window instead (anti-pattern #88). |
| `RefreshAllPanels()` | O1 (two tiers: O3) | **Structural.** Re-run each page's renderer, so rows that appeared or disappeared are drawn. Hidden pages are flagged dirty and re-render on their next show. |
| `RefreshScalars()` | O3 | **In place.** Refreshers only, no rebuild — what every widget maker's own `set()` calls, since writing a value does not change which rows exist. Each is pcall'd, so one dead widget cannot take the UI with it. |
| `RefreshPanel(ctx, structural)` | O8 (a drawer's body ctx: **O29**) | **One page, either tier.** From O29 a drawer's body ctx is refreshed as the page it is drawn on. `structural` true re-runs that ctx's renderer (from O29 keeping the page's scroll offset, re-fixed and clamped to the new end); false runs its refreshers in place. A hidden page is flagged dirty and repaints on its next show, so the caller never has to ask whether it is on screen. For a host whose page repaints off its own message bus rather than off a widget's `set()`. |
| `SelectTab(pageKey, tabKey)` | **O19** | Move an already-rendered page to one tab and refresh **only** that page, through `RefreshPanel(ctx, true)`. Returns `false`, storing no intent, for a page that has not been rendered — the caller opens the page. See [What changed at this version](#previously-at-24314774). **From O22** answers `false` in combat and moves nothing. |
| `__pages()` | O1 | The pages that actually built. A raising builder is reported by key and costs only itself. |
| `RenderGrid(ctx, items, parent, opts)` | **W4** (`parent`, `opts`: **W34**) | Lay arbitrary widgets out two per row, caller-ordered. The sibling of `RenderRows`: that one walks schema rows and emits sections, this one takes whatever the caller hands it — a schema row, or `{ make = fn }` for a bespoke widget, or `wide = true` for its own line. For a list whose length is not in the schema (one checkbox per macro, per unit, per spell). Items are guarded individually; from **W34** an item that raised, or whose `make` answered exactly `false`, takes no cell, and a wide one no row and no gap. `parent` (**W34**) is the container, defaulting to `EnsureScroll(ctx)`; `opts.gap` (**W34**) is the spacer after each row, defaulting to `lib.LAYOUT.ROW_VSPACER`, with `false` or `0` for none. **It does not call `scroll:DoLayout()`**, unlike `RenderRows`, and that is a decision: call `container:DoLayout()` after your last render. |
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
| `ResetAllTooltip(tail)` | **C11** | The tooltip *Reset all settings* carries, for the General page's header Defaults (`options-ui-§12`), read from the descriptor at call time exactly as the button reads it; `tail` follows after one space when it is a non-empty string. Pure; returns a string. See [`O.ResetAllTooltip`](#oresetalltooltiptail--string). |
| `StrataTooltip(values, strings)` | **C8** | The one tooltip every player strata row carries (`frame-layering-§1`), built from the row's own value table: the tiers always, plus the dialog-and-above sentences only when the row offers those values. Pure; returns a string. See [`O.StrataTooltip`](#ostratatooltipvalues-strings--string). |
| `LSMValues(mediaType)` | W1 (never-empty: **W4**) | A **deferred** closure pulling the live media hash at dropdown-render time. Never empty: a media library that has not loaded yet yields a single `None` placeholder, because a dropdown with no options cannot be opened and the CLI would refuse even the stored value. Deferred is load-bearing: LSM-backed rows evaluate this inside a schema-row literal at file load, long before the addons that register media have run. **Since C3 the media composers assign what this returns directly into a row's `values`**, which is why a host that replaces this member must return a function; see [The schema composers](#the-schema-composers). |
| `PatchAlwaysShowScrollbar(scroll, owner)` | S1 (`owner`: **S5**) | The scrollbar override. Idempotent, and reversed on `OnRelease` — AceGUI pools ScrollFrames, so an unreleased patch escapes into whichever addon recycles the widget next. **From S5** an optional `owner` (a skin owner's folder name): for a registered one the thumb's two tints are painted again through its facade, and the bar is given back on release. `EnsureScroll` passes the descriptor's `addonName`. |
| `ROW_VSPACER` / `SECTION_HEADING_H` / `BUTTON_PAIR_REL` | W1 | The cross-slice layout constants, mirrored onto the instance so a host's own page code stays in lockstep with the engine's spacing. |
| `PADDING_X` | **O7** | The horizontal inset the library draws its own header, divider and body to. Read it to align a bespoke widget with any of the three; **do not restate it** (options-ui-§8). |
| `CHROME_GAP` | **O10** | Gap between the bottom of the chrome band and the top of the scroll (`8`, the literal `EnsureScroll` always used). |
| `TAB_H` | **O10** (value: **O12**) | Height of one row of tabs (`37`), taller than the art it carries — the bottom of a tab is the foot that overlaps the content panel. Was `24` through 11.10.3. |
| `BANNER_H` | **O10** (value and meaning: **O11**) | **Floor** for the page banner (`44`), not a fixed height: `PageBanner` measures its dropdown and takes the larger. |
| `chrome` (on `ctx`) | **O10** | The pinned chrome `Frame`, returned on every `ctx` from `CreatePanel`, inset to `PADDING_X` on both edges. What `TabStrip` and `PageBanner` parent their widgets to. |
| `chromeHeight` (on `ctx`) | **O10** | The pixels of chrome the page has reserved, starting at `0`. Set only through `SetChromeHeight` — never write it directly, or the scroll's anchor and the frame's actual height will disagree. |
| `AceGUI` | O1 | The resolved AceGUI-3.0, or nil. Filled in at `:New` and re-resolved at `CreateOptionsPanel`, which is the copy `onAceGUI` hands the host. |
| `__panels()` / `__panelFor(pageKey)` | O1 | Test seams, following Perf's `__buckets()` idiom. The registry is private, so a host suite otherwise has no handle on a live ctx — and a real bug once shipped precisely because one page's ctx was unreachable. |

**Consumer census, v1.67.0** ([`CONSUMERS.md`](../CONSUMERS.md)). No host calls or passes these:

- `CHROME_GAP`: no consumer as of v1.67.0, kept because it is published for a host that draws bespoke chrome of its own and has to know where the band ends.
- `FONT_FLAGS`: no consumer as of v1.67.0, kept because `O.FontGroup` offers it on every composed font row; MultiMeters keeps its own localized list, keyed `NONE` rather than `""`.
- `FONT_FLAGS_SORT`: no consumer as of v1.67.0, kept because the declared order of `FONT_FLAGS`, read by `O.FontGroup`.
- `PatchAlwaysShowScrollbar`: no consumer as of v1.67.0, kept because the instance mirror of the lib-level patch, reached through `EnsureScroll`.
- `RenderSchema`: no consumer as of v1.67.0, kept because every host moved to `RenderTabbedSchema` and `RenderRows`; the untabbed wrapper is permanent under `-1.0`.
- `SetChromeHeight`: no consumer as of v1.67.0, kept because `TabStrip`, `PageBanner` and `PageHeader` reserve their band through it; a host calls it only for chrome of its own.
- `TAB_H`: no consumer as of v1.67.0, kept because it is published for a host that measures its own strip; every host draws the library's.
- `VISIBILITY_SORT`: no consumer as of v1.67.0, kept because `O.MasterControls` offers it on every General page; MultiMeters keeps the library's keys with its own localized labels.
- `VISIBILITY_VALUES`: no consumer as of v1.67.0, kept because `O.MasterControls` offers it on every General page; MultiMeters keeps the library's keys with its own localized labels.

`PADDING_X` left this list at v1.67.0: PanelMaster reads it for its Profiles container, in `settings/Panel.lua` (PanelMaster#56).

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

## The drawer

### `O.Drawer(ctx, spec)` → drawer or `nil`

**D1.** One drawer, added to `O.EnsureScroll(ctx)` — the page, or the box of the drawer whose body
ctx `ctx` is — as one full-width AceGUI `SimpleGroup` (List layout): the header, the box while open,
and a 4px gap. Nil, having drawn nothing, with no AceGUI.

| `spec` field | Since | Meaning |
|---|---|---|
| `label` | D1 | The header's name. |
| `summary` | D1 | String, or a function read at draw. The value at a glance, right-aligned after the name on one line, cut with an ellipsis where it meets the edge. The host words "nothing set" itself (for example `Any`). A function that raises reads as no summary and is reported through the host's printer. |
| `set` | D1 | Boolean, or a function read at draw (a raise reads as false and is reported). While true the name is gold (`1, 0.82, 0`) and the summary pale gold; otherwise the name is white and the summary gray. |
| `tooltip` | D1 | The header's tooltip body, under the name. |
| `open` | D1 | The box is drawn. The chevron points right while closed and down while open. |
| `onToggle(open)` | D1 | A header click calls it with the other state, then `O.RefreshPanel(page, true)` re-renders the page, which keeps the page's scroll offset (O29: restored and re-fixed after it, clamped to the new end), so a drawer opened or closed below the fold stays in view. Refused in combat (`drawer <label>`). A raise is reported and nothing is redrawn. **The open state is the host's**: the library reads neither field back, so any number may be open at once and the host decides how long the state lives (session state, never persisted, as a sub-strip's selection is). |
| `body(ctx, box)` | D1 | Fills the box. `box` is the box's `SimpleGroup` (Flow layout); `ctx` is the **body ctx** below. pcall'd: a raise is reported as `ROW_FAILED` naming `drawer <label>`, and the page goes on. |
| `actions` | D1 | `{ { text, tooltip, onClick, disabled } }`: buttons on the box's last line, right-aligned behind a filler `Label`, each `0.22` of the line, in the order given. `onClick` is pcall'd (`BUTTON_FAILED`) and refused in combat. Drawn only while open, and only when the list is not empty. |
| `disabled` | D1 | The body is drawn under the page's render-disabled flag (`ctx.__renderDisabled`, the flag `RenderRows`' `opts.disabled` sets), put back afterwards, a raise included; every action is drawn disabled. A drawer drawn while the page's flag is already set (a tab rendered disabled, `RenderRows`' `opts.disabled`) draws its actions disabled the same way. The library's own rows honor the flag; a host `make` widget reads it itself. |

**Returns** `{ group, header, head, body, ctx, actions, open }`: the drawer's group, the header's
`SimpleGroup`, the header's button frame, and, while open, the box, the body ctx and the action
line (nil while closed, and `actions` nil when there are none).

**The body ctx.** A view of the page: its `scroll` is the box, so `O.EnsureScroll`, and with it
`O.RenderGrid`, `O.IdList`, `O.IdInput`, `O.TextRow`, `O.InlineButtonPair` and `O.Section`, draw
into the box unchanged. Every other field is the page's, read **and written** through, so a
refresher, a heading tracker or a host's own per-page list started while drawing the box lands on
the ctx the registry holds. `O.RefreshPanel` on a body ctx refreshes its page (O29). A drawer drawn
inside a box writes to, and refreshes, the page. **Never `ClearScroll` a body ctx**: it would release
the box's rows and reassign the page's refreshers.

**What it is built from.** Three AceGUI `SimpleGroup`s and no registered widget type, because
AceGUI's widget registry is process-global. The header's frame carries one button (fill, 1px
edges, the hover glow, the `ChatFrameExpandArrow` chevron, the name and the summary), built once per
pooled frame and re-dressed on every draw. The box's frame carries a fill and three edges (no top
edge: it joins the header), and the box pads its content by `lib.__drawerPad` (`left` 26, under the
header's name; `right` 10; `top` and `bottom` 8) by patching its `OnWidthSet`, `OnHeightSet` and
`LayoutFinished` and its content's two anchors. **Everything is handed back on release**: the header's
button is hidden with its scripts cleared, and the box's three methods and anchors are restored and
its decoration hidden, so the pooled `SimpleGroup` the next addon takes is plain.

**Library-level name.** `lib.__drawerPad` (D1), the box's padding, published for the suite;
`lib.__drawerMinor` / `lib.__drawerShellMinor`, the pairing guard.

## The key binding model (OptionsKeybinds.lua, minor 1)

`OptionsKeybinds.lua` is a twelfth file of the major, at minor **1**, loaded after
`OptionsDrawer.lua` (and so after `OptionsCombat.lua`, whose lock it reads) and attached by
`Options.lua` minor 30 at the end of `lib:New`, guarded (`lib.__AttachKeybinds(O, d)`). It is the
headless half of the settings-panel Keybindings tab (`options-ui-§20`): the editor for the key
bindings a host declares in its own `Bindings.xml` (`launcher-§6`), with the client's two slots per
action (the tab shows them on one key button from K4), saved by the game to the set in force. **Minor 1 attached no
instance member**; the tab's public members arrived with minor 2 in this same release: see
[The Keybindings tab](#the-keybindings-tab-optionskeybindslua-minor-2).

**What it never does.** It writes no `BINDING_*` global, never reads `Bindings.xml` and sets no
default key, so `launcher-§6`'s recorded rejection of a library-owned binding file (LibKa0s#58)
stands. It never touches `SettingsPanel`, `KeybindListener`, `Settings.*BindingSet*`, `HideUIPanel`
or `ToggleGameMenu`, calls no `SetPropagateKeyboardInput`, and reuses neither
`KeyBindingFrameBindingTemplate` nor AceGUI's `Keybinding` widget. It supersedes QuickComms'
2026-10-21 retirement of its in-panel key box (QuickComms `b902e35`), whose write-and-save path
(`db8f7a6`) is the one below.

All of it is library-level and, apart from the words, `__`-prefixed, so it is internal: no
degradation stub owes any of it. `lib.KEYBIND_STRINGS` is the one public lib-level name, and this
version's member manifest lists it beside `LAYOUT`, `New`, `PatchAlwaysShowScrollbar` and `STRINGS`.

### `lib.__keybindSet(command, slot, key)` → `ok, displaced, displacedUnbound, reason`

Binds `key` to `command` in `slot` (1 or 2; anything else reads 1), with the client's own slot
semantics (`RebindKeysInOrder`, `Blizzard_Keybindings.lua`), and saves it once.

1. **Refuses `"combat"`** when `lib.__IsCombatLocked()` (the lock's flag, or `InCombatLockdown()`),
   calling **no** binding API at all: `SetBinding` is `#nocombat`, and `SaveBindings` is blocked
   from tainted code in combat.
2. **Refuses `"unavailable"`** when `lib.__keybindAvailable()` is false.
3. Reads `k1, k2 = GetBindingKey(command)`. `key` already in `slot` answers `true` with no write and
   no save.
4. `displaced` is `GetBindingAction(key)` when that is another command (never `""`, never
   `command` itself: a command's own key moving to its other slot is a swap, not a conflict).
5. Unbinds `k1` and `k2`; then, when there is a `displaced`, unbinds `key`.
6. Rebinds in the new order: the old keys without `key`, with `key` in `slot`. A key the command
   already held moves (the two swap); a new key replaces the slot's old key, which is left free; slot
   2 on a keyless command becomes slot 1.
7. **Any falsy `SetBinding` return** unbinds what this call bound, rebinds `k1` then `k2`, gives `key`
   back to `displaced`, and answers `false, nil, nil, "failed"` **with no save**.
8. Otherwise `displacedUnbound = displaced ~= nil and GetBindingKey(displaced) == nil`, one
   `SaveBindings(GetCurrentBindingSet())`, and `true, displaced, displacedUnbound`.

### `lib.__keybindClear(command, slot)` → `ok, reason`

The same two refusals. `slot` nil clears both keys, 1 or 2 only that slot's. Nothing to clear
answers `true` with no save; otherwise one `SaveBindings(GetCurrentBindingSet())`. A falsy
`SetBinding` puts the command's keys back in order and answers `false, "failed"` with no save.

### `lib.__keybindAvailable()`, `lib.__keybindSetName()`

`__keybindAvailable` is true when `GetBindingKey`, `GetBindingAction`, `SetBinding`, `SaveBindings`
and `GetCurrentBindingSet` are all functions. `__keybindSetName` answers `"character"` when
`GetCurrentBindingSet()` equals `Enum.BindingSet.Character` (else `CHARACTER_BINDINGS`, else 2), and
`"account"` otherwise. The tab never offers its own account/character switch: switching from
character to account destroys the character set behind a Blizzard confirm, which stays Blizzard's.

### `lib.__keyChord(key, mods)` → chord or `nil`

A key press (an `OnKeyDown` key or an `OnMouseDown` button name) as the client's binding string.
`nil` for a press that binds nothing: `LSHIFT` `RSHIFT` `LCTRL` `RCTRL` `LALT` `RALT` `LMETA`
`RMETA`, `UNKNOWN`, `BUTTON1`, `BUTTON2`, and `ESCAPE` (the capture cancels on it before it asks).
Mouse names convert first (`LeftButton` `BUTTON1`, `RightButton` `BUTTON2`, `MiddleButton`
`BUTTON3`, `Button4`..`Button31` `BUTTON4`..`BUTTON31`); `MOUSEWHEELUP` / `MOUSEWHEELDOWN` pass.
Prefixes `ALT-` `CTRL-` `SHIFT-` `META-`, in that order. The client's `GetConvertedKeyOrButton`,
`IsKeyPressIgnoredForBinding` and `CreateKeyChordStringUsingMetaKeyState` are taken first, each on
its own guard (the bundled ignore list applies on both routes, since the client's
`IsKeyPressIgnoredForBinding` does not cover `BUTTON1` / `BUTTON2`); without them a bundled copy of `BindingUtil.lua`'s logic reads `IsAltKeyDown` /
`IsControlKeyDown` / `IsShiftKeyDown` / `IsMetaKeyDown`. `mods` (`{ alt, ctrl, shift, meta }`)
overrides the modifier state and takes the bundled route, for a suite. `PRINTSCREEN` is the
capture's to handle (`Screenshot()` when present).

### `lib.KEYBIND_STRINGS`

The tab's words, a library-level literal table (the library carries no locale; a host with one
overrides any key through the tab's `spec.strings`). ASCII, `->` for an arrow.

| Key | Default |
|---|---|
| `TAB_LABEL` | Keybindings |
| `TAB_TIP` | The same key bindings as Options -> Keybindings. A key set here shows there, and the other way round. |
| `INTRO` | Key bindings are saved by the game, not in your profile. Defaults and Reset all settings leave them alone. |
| `UNCHANGED` | Key bindings are not changed. |
| `KEY` | Key binding (the key button's tooltip title; **K4**, replacing K2's `KEY1` / `KEY2`) |
| `KEY_MORE` | %s +%d (the button with more than one key: the first key's text and how many more; **K4**) |
| `KEYS_ALL` | Keys: %s (the tooltip's list of every key, comma-separated; **K4**) |
| `KEYS_OTHER` | The others were set on the game's Key Bindings page (Options -> Keybindings). (**K4**) |
| `CLEAR` | Clear |
| `CLEAR_TIP` | Remove every key from this action. (K2 read "Remove both keys from this action.") |
| `SLOT_TIP` | Click, then press a key or a mouse button to bind it. Esc cancels. Right-click removes this key. |
| `LISTENING` | Press a key... |
| `SET_ACCOUNT` | Saved for: all characters |
| `SET_CHARACTER` | Saved for: this character only |
| `SET_HOW` | (Options -> Keybindings -> Character Specific Keybindings) |
| `COMBAT` | Key bindings can be changed after combat. |
| `FAILED` | That key could not be bound. |
| `CLEARED` | Key removed. |
| `UNAVAILABLE` | Key bindings cannot be set here on this client. Use Options -> Keybindings. |

The client's own strings win where they exist, read at use through `lib.__keybindClientString`:
`NOT_BOUND` (fallback "Not bound"), `KEY_BOUND` ("Key bound.") and `KEY_UNBOUND_ERROR`
("%s is now unbound.").

Cases: `tests/test_options_keybinds_model.lua`, each installing the kit's
`mock_bindings.lua` (revision 42).

## The Keybindings tab (OptionsKeybinds.lua, minor 2)

`options-ui-§20`'s surface, **Since K2**: an addon whose `Bindings.xml` ships a binding lets the
player set those keys on its own General page, in one tab the library draws, with the client's
Keybindings page's behavior. Both surfaces read and write the client's one store, so a key set in
either shows in the other. Three public instance members; everything else here is library-level and
`__`-prefixed.

### `O.KeybindingsTab(spec)` → tab entry

A host-tab entry for `O.RenderTabbedSchema`'s `opts.tabs` (`options-ui-§13`):

```lua
{ key = spec.key or "Keybindings", label = S.TAB_LABEL, tooltip = S.TAB_TIP, before = spec.before,
  render = function(ctx) O.KeybindRows(ctx, spec) end }
```

where `S` is `lib.KEYBIND_STRINGS` with `spec.strings` over it. The page's tab strip runs `render`
under its pcall with `ctx.__renderDisabled` set for a page drawn disabled. With no `before` the
library puts the tab **after every group tab**, which is where `options-ui-§20` asks for it.

| `spec` field | Meaning |
|---|---|
| `bindings` | `{ { command, tooltip }, ... }`, the host's `NS.BINDINGS` (launcher-§6), in row order: `Bindings.xml` order, Show window first. A binding whose `command` is not a string is skipped and reported through the descriptor's `print` with `lib.STRINGS.ROW_FAILED`. |
| `key` | The tab key, default `Keybindings`. |
| `before` | A tab key to sit before; nil (the rule) is last. |
| `intro` | Optional: **one** host line drawn under the fixed intro. It never replaces it. |
| `strings` | Translations of any `lib.KEYBIND_STRINGS` key, for translation only. The library's table is never written. |

### `O.KeybindRows(ctx, spec, parent)` → rows or `nil`

Draws the tab's body into `parent`, default `O.EnsureScroll(ctx)`. With no AceGUI or no scroll it
draws nothing and answers nil.

- **Degradation.** Without the binding API (`lib.__keybindAvailable()` false) it draws exactly one
  line, `UNAVAILABLE` ("Key bindings cannot be set here on this client. Use Options -> Keybindings."),
  and answers nil.
- **The intro**, always: `INTRO` ("Key bindings are saved by the game, not in your profile. Defaults
  and Reset all settings leave them alone."), then `spec.intro` as a second line when it is a
  non-empty string, then a row gap (`O.ROW_VSPACER`). On the page's scroll each line is an
  `O.TextRow`; in a host-built `parent` it is a full-width Label there.
- **One row per binding**, an AceGUI `SimpleGroup` (Flow, full width) holding: the label,
  `GetBindingName(command)` (else `_G["BINDING_NAME_" .. command]`, else the command), at relative
  width 0.40, an `InteractiveLabel` carrying the binding's `tooltip`; **one key button** (from
  **K4**; K2 drew two, Key 1 and Key 2), an AceGUI Button at 0.22 showing the action's first key as
  `GetBindingText(key)` (else the key), or the client's `NOT_BOUND`, and with more than one key
  `KEY_MORE` over it (`"F5 +1"`); and **Clear**, a Button at 0.12 with `CLEAR_TIP`. The widths sum to
  0.74, inside the clip inset (`options-ui-§8`); the label, the key button and Clear keep K2's
  widths, so they line up as before, minus the second slot.
- **The key button's tooltip** (K4), built at each hover from `GetBindingKey`: the title `KEY`,
  then `SLOT_TIP`; with more than one key, `KEYS_ALL` naming every key in slot order
  (`"Keys: F5, SHIFT-F5"`) and `KEYS_OTHER`, which says the others were set on the client's Key
  Bindings page. A key set there is therefore never hidden, though the tab binds only the first.
- **Under the rows**, two Labels: the **set line**, `SET_ACCOUNT` or `SET_CHARACTER` (from
  `lib.__keybindSetName()`), a space and `SET_HOW`, so "Saved for: all characters (Options ->
  Keybindings -> Character Specific Keybindings)"; then the **outcome line**, empty until an action.
- **Disabled.** Under `ctx.__renderDisabled` the key button and Clear are drawn disabled.
- **Refresh.** Each row pushes a refresher into `ctx.refreshers` that repaints its key button and the
  set line from `GetBindingKey`. No key is cached anywhere.

The answer is the row records, in order, for a suite:
`{ command, label, group, slots = { keyButton }, clear, status, view }` (K2's `slots` held two
Buttons), where `status` is the one outcome Label every row shares.

**The capture.** A left click on the key button starts listening for slot 1 (refused in combat), and
only one button in the session listens at a time: starting one stops any other. The tab never
listens for slot 2 from K4; that key is the client's page's to set, and the model keeps it. The one listener,
**`lib.__keybindListener`**, is a plain Frame made once and kept across a LibStub upgrade (as
`lib.__parkFrame` is), drawing nothing and with no strata or level of its own (frame-layering T0).
To listen it is parented over the slot (`SetParent`, `SetAllPoints`), takes the keyboard, the mouse
and the wheel, and shows; the slot reads `LISTENING`.

| Input while listening | Result |
|---|---|
| `ESCAPE` | Cancels. The keyboard-enabled listener consumes it, so the Settings window stays open; `SetPropagateKeyboardInput` is never called. |
| `PRINTSCREEN` | `Screenshot()` when present; still listening. |
| A key `lib.__keyChord` answers nil for (a modifier alone, `UNKNOWN`) | Still listening. |
| Any other key | Written: `lib.__keybindSet(command, 1, chord)`, slot 1, so a second key is kept. |
| Left or right mouse button | Cancels (click the slot again to cancel, as on the client's page). |
| Any other mouse button | Written, through `lib.__keyChord` (`BUTTON3` to `BUTTON31`). |
| The wheel | `MOUSEWHEELUP` / `MOUSEWHEELDOWN`, with the modifiers held, written. |

After a write the capture stops and the outcome line reads, in the client's own words where it has
them: `KEY_UNBOUND_ERROR` formatted with the `GetBindingName` of the action that lost the key, when
that action is left with no key; else `KEY_BOUND`; `COMBAT` for `"combat"`, `UNAVAILABLE` for
`"unavailable"` and `FAILED` otherwise. Every row of the same render is repainted.

**A right click on the key button** clears the key it shows (`lib.__keybindClear(command, 1)`,
outcome `CLEARED`); a second key then moves up and shows. **Clear** clears every key
(`lib.__keybindClear(command, nil)`). Both are refused in combat.

**Stopping.** A stop turns the listener's keyboard, mouse and wheel off, hides it, clears its points
and parents it back to `UIParent`, and the slot shows its key again. A capture stops on: Escape or a
second click; a write; the slot widget's `OnRelease` (a tab change or a structural refresh releases
it through `ClearScroll`); the page's `OnHide` (hooked once per page, `ctx.__keybindHooked` at K2,
`ctx.__keybindSyncHooked` from K3); and
**combat start**, through `lib.__keybindOnCombat`, a hook in the combat lock's `lib.__combatHooks`
held strongly on `lib` (an older copy's hook is taken out of the set when a newer copy loads). On
`locked == true` it stops the capture and writes `COMBAT` to the outcome line. No event is
registered for it: the lock's one combat frame is the only listener.

**Refusals.** Starting a capture, a right click and Clear each ask `O.__combatRefused("keybind",
command)` first: in combat the gray notice prints once for the combat, the outcome line reads
`COMBAT`, and **no binding API is called**, not even a read.

**Pooled widgets** (`options-ui-§19`). A slot's frame is told `RegisterForClicks("LeftButtonUp",
"RightButtonUp")`, and its one `OnRelease` callback puts it back to `"LeftButtonUp"` and stops a
capture it holds, so a pooled Button leaves with nothing of ours. No script is set on a widget's
frame; the listener is the library's own frame and is re-homed on every stop.

**What it never touches.** `SettingsPanel` (no Commit, no Close), `HideUIPanel`, `ToggleGameMenu`,
`Settings.OpenToCategory`, `Settings.SelectCharacterBindings` / `Settings.SelectAccountBindings`,
`KeybindListener` and the client's binding row template; AceGUI's `Keybinding` widget is not used.
It keeps no key in SavedVariables or a profile and offers no account/character switch of its own.
Repainting on `UPDATE_BINDINGS` and on the page's show is not part of K2; it is K3's (below).

### Following Options -> Keybindings (OptionsKeybinds.lua, minor 3)

**Since K3.** The tab and the client's Keybindings page read and write one store, and from K3 the
tab also *follows* it: a key set on the client's page, a binding set switched (Character Specific
Keybindings, which runs `LoadBindings`), or an override binding shows on the tab without
reopening the settings. `SetBinding`, `SaveBindings` and `LoadBindings` all fire
`UPDATE_BINDINGS` (KEYBINDINGS_RESEARCH §3.1 and §3.4 of Ka0sAddonsCommonTasks
`docs/2026-10-24-KEYBINDS_LAYOUT_STRATA/`).

- **One registration, only while a row is on screen.** `lib.__keybindEventFrame` is one hidden
  Frame for the process, made once and kept across an upgrade; its `OnEvent` resolves
  `lib.__OnKeybindEvent` at call time (the combat lock's idiom). It hears `UPDATE_BINDINGS` while
  at least one live keybind row is on screen and lets go when the last one leaves, so a host with no
  settings page open owns no registration (the lock's discipline, `lib.__syncCombatEvents`).
- **Registered through Core.** The frame registers with `LibStub("LibKa0s-Core-1.0").SafeRegisterEvent(frame,
  "UPDATE_BINDINGS")`, pcall'd, and never with a raw `RegisterEvent`; it unregisters with the
  frame's `UnregisterEvent`. Without Core's helper nothing registers, and the `OnShow` re-read and
  the refreshers still keep the slots true.
- **One repaint per frame.** The dispatcher re-syncs first and, with no row on screen, returns
  having drawn nothing (so a stand-down suite that fires every event at every frame sees nothing).
  Otherwise it queues **one** repaint with `C_Timer.After(0, ...)` unless one is already pending
  (`lib.__keybindRepaintPending`); with no `C_Timer` it repaints at once. The repaint reads every
  live on-screen row's keys from `GetBindingKey` and its view's set line again. A slot that is
  listening keeps `LISTENING` through it.
- **The page's `OnShow` re-reads** that page's rows (and re-syncs), with or without an event; its
  `OnHide` stops a capture on it and re-syncs. Both are hooked once per page and dispatch by name.
- **In combat** a repaint still runs: it only reads.

| Name | Since | Meaning |
|---|---|---|
| `lib.__keybindEventFrame` | K3 | The one `UPDATE_BINDINGS` frame. Hidden, kept across an upgrade. |
| `lib.__keybindLive` | K3 | Weak-keyed set, row record -> its ctx: added when a row is built, removed in the row group's `OnRelease`. A record carries `view` from K3. |
| `lib.__syncKeybindEvents()` → boolean | K3 | Drop dead rows; register when any live row is on screen (its group frame's `IsVisible`, `IsShown` as the fallback, on a page that is shown), unregister when none is. Called on row build, on release, from the page's `OnShow` / `OnHide` and at the start of each dispatch. Answers whether a row is on screen. |
| `lib.__OnKeybindEvent(event)` | K3 | The dispatcher, above. |
| `lib.__keybindRepaintPending` | K3 | True while a queued repaint has not run. |
| `lib.__keybindFlush()` | K3 | The repaint: clears the flag and repaints every live row on screen. |
| `lib.__keybindOnPanelShow(ctx)` / `lib.__keybindOnPanelHide(ctx)` | K3 | The page hooks' bodies. |

Every one is `__`-prefixed: no manifest lists them and no degradation stub owes them. Cases:
`tests/test_options_keybinds_sync.lua`, on `tests/fixture_keybinds.lua`'s bench, which also puts the
sync state back after each case (`Bench.resetSync`).

### `O.KEYBINDS_UNCHANGED`

`lib.KEYBIND_STRINGS.UNCHANGED`, "Key bindings are not changed.": the sentence a host appends to its
General page's `opts.defaultsTooltip` (`CreatePanel`), so the Defaults button says it leaves keys
alone before it is clicked.

### Declaring it

A page drawn by `O.RenderTabbedSchema` (DropWatcher; the same shape in every such host):

```lua
Helpers.RenderTabbedSchema(c, "general", AFTER_GROUP, nil, {
  rerender = renderGeneral,
  tabs = { O.KeybindingsTab({ bindings = NS.BINDINGS }) },
})
```

A hand-drawn General strip (LootHistory's `GENERAL_TABS`) adds its last entry:

```lua
{ key = "Keybindings", build = function(ctx) O.KeybindRows(ctx, KEYBIND_SPEC) end }
```

And the General page's Defaults tooltip is the reset's own (**C11**, `options-ui-§12`), ending with
the sentence:

```lua
defaultsTooltip = O.ResetAllTooltip(O.KEYBINDS_UNCHANGED),
```

### What a consumer owes

**Every Options degradation stub gains `KeybindingsTab`, `KeybindRows` and `KEYBINDS_UNCHANGED`**,
in every addon, windowed or not: `Kit.assertSurfaceParity` compares the stub with the live instance,
so the re-vendor of this version turns red until the stub answers all three. **It gains
`ResetAllTooltip` as well (C11)**, owed by every addon at its re-vendor (RV2) for the same reason;
the suggested stub is

```lua
ResetAllTooltip = function(tail) return type(tail) == "string" and tail or "" end,
```

This version's member manifest lists the lib-level table only, as every Options manifest does, so
it does not name them.
An addon that ships bindings tests its tab through `T.keybindThroughTab(row, slot, key[, mods])`
(the kit's driver, revision 42; slot 1 is the key button, and from K4 slot 2 writes the second key
through the model, as the client's page would) with `tests/_kit/mock_bindings.lua` installed, and leaves the
capture, conflict, combat and settings-window cases to this library's suite (`testing-§8`).

Cases: `tests/test_options_keybinds.lua` (on `tests/fixture_keybinds.lua`'s bench, which fails a
case on any touch of Blizzard's settings window), and `tests/test_kit_bindings.lua` for the driver.

## The skin picker (OptionsSkinPicker.lua, minor 4)

New at `OptionsSkinPicker.lua` minor 1, a fourteenth file paired on the shell's minor
(`lib.__pickerMinor` / `lib.__pickerShellMinor`) and attached by `Options.lua` minor 34
(`lib.__AttachSkinPicker(O, d)`, guarded). LibKa0s#64: a small window a host shows the first time a
profile runs (its `skin.pickerSeen` key is false: a new profile and a reset profile both start from
the defaults, so both show it), so the player picks a skin before opening any settings. It reads
`LibKa0s-Skin-1.0`, `LibKa0s-Core-1.0` and `LibKa0s-Media-1.0` at call time, never as a floor, and
`OptionsAppearance.lua`'s reload popup and its other-owner helpers through the library table.

Minor 1 was amended before release (PK-02 of the same bundle, the owner's in-game pass): the window
sits higher, its title names the addon, a pick previews and **Apply** saves, *Apply to all Ka0s
addons* is new, one window is shared across every Ka0s addon, and the default gear opens the page
itself. PK-03 (the consumer reviews) amended it again: the window is `DIALOG` and raised after the
eye's preview, a dismissal puts back the owner's stored choice as it reads then, and the queue waits
out combat. Minor 2 (LK-11, ruling R-11) gives the title back its plain words and the addon's name a
line of its own that the window widens to fit. Minor 3 (`LK-07`, ruling D-10) resets the font and
texture overrides on a pick to another look: the preview clears them, Apply saves the reset, a
dismissal restores them, and *Apply to all* resets them for every other owner whose look changes
(*What changed at this version*). What follows is minor 2; minor 3 is that section.

### `O.SkinPicker(spec)` → frame, `nil, "queued"`, or `nil`

**One picker is up at a time across every Ka0s addon.** LibStub keeps one copy of this major for the
whole client, so its library table is shared by every addon's Options instance, and the queue lives
there: `lib.__pickerQueue`, `{ current = { owner, inst, frame } | nil, waiting = { { owner, inst,
spec, show }, ... } }`, created when absent and adopted by a newer copy of the file.

- **Nothing up, or this owner up on this instance:** shows the picker and answers its frame. A
  window is built per owner on an instance on that owner's first show and kept (frames are never
  destroyed), so a second call while it is up re-reads `spec` (keeping a pending preview) and
  answers the same frame. Each window refreshes only on its own owner's `OnLooksChanged`. A skin
  registered after a window was built gains its row, at the end, on the next call.
- **Another owner's picker up** (on any instance, this one included), **or the queue waiting out
  combat**: the owner is queued and the call answers **`nil, "queued"`**; nothing is drawn. A
  repeat call while queued refreshes the queued `spec` (one entry per owner). When the picker up
  closes, by any route, the next owner waiting shows, oldest first. A host that ignores the answers
  keeps working: a queued picker shows by itself later.
- **Never shown mid-combat by the queue.** A close under `InCombatLockdown()` shows no next owner:
  the queue parks on `OptionsRegistry.lua`'s end-of-combat park (`lib.__parkRegistration`, its one
  `PLAYER_REGEN_ENABLED` frame, registered only while something is parked; `lib.__pickerQueue.parked`
  is true meanwhile) and advances when combat ends, unless a picker came up meanwhile. A queue
  emptied in the meantime (`O.HideSkinPicker()`, *Apply to all*) shows nothing. The predicate is
  the client's `InCombatLockdown()` alone, as the park's own is. A copy without the park shows the
  next owner at once. A direct call with nothing up and nothing parked still shows at once, in
  combat too: when to call is the host's.
- **This owner already up on another instance:** answers that window, `spec` unread.
- **Degraded:** answers nil, drawing nothing, without `LibKa0s-Skin-1.0`, without a client
  (`CreateFrame`), or for an owner that never called `RegisterOwner`.

`spec`:

| Field | Meaning |
|---|---|
| `owner` | The skin owner; default the descriptor's `addonName` (else the owner shown last on the instance). |
| `get` | The owner's read, as `O.AppearanceTab`'s: `{ source, skin }` or two values, under pcall; without it, or for a value that is not a source or a registered skin, `Skin:GetChoice` stands in. |
| `set` | **MUST be the owner's write seam** (`options-ui-§1`), as `O.AppearanceTab`'s: called as `set(source, skin)` by **Apply**, *Apply to all* and the gear, with the pending pick and the stored source, under pcall. **A pick never calls it.** Not called when nothing was picked. |
| `onPreview` | The eye. A function: the button is shown and a click calls it (the host's test mode, so the player sees the skin on the addon's own frames); the window and a pending preview stay, and the window is `Raise()`d once it returns (even when it raised an error), so a window it showed does not cover the picker (see **Layering**). Absent, the button is hidden. |
| `onSettings` | The gear. A function replaces the default, which is `O.OpenOptionsPanel(spec.page)` (the page's own subcategory, `OptionsRegistry.lua` minor 4) and then `O.SelectTab(spec.page, spec.tab or "Appearance")`. Either way the pending pick is saved first, as Apply saves it, and the window then closes. In combat the gear is refused (`O.__combatRefused("skin picker", owner)`): nothing is saved or called and the window stays up, so a gear that opened nothing never runs `onClose` (where the host marks the picker seen). The default also leaves the window up when `O.OpenOptionsPanel` answers false. |
| `page`, `tab` | The page key (the key `O.RegisterOptionsPage` was given) and the tab key the default gear opens (`tab` defaults to `"Appearance"`, the Skin tab's key). |
| `onClose` | Called once each time the window closes, by any route: Apply, *Apply to all*, the gear, the close control, Escape (the window's name is in `UISpecialFrames`) or `O.HideSkinPicker()`; and once for each queued picker *Apply to all* dismisses, which never shows. A hide of UIParent, which leaves the window shown, is not a close. Where the host sets `skin.pickerSeen`. Under pcall. |
| `strings` | Translations of `lib.SKIN_PICKER_STRINGS` keys, `SKIN_<key>` (a skin's name), and the reload popup's `RELOAD`, `RELOAD_ACCEPT`, `RELOAD_LATER` (default `lib.APPEARANCE_STRINGS`'). |

**The window**, 308 wide or as wide as the addon's label needs, its **center 75% of the way up UIParent** (`SetPoint("CENTER",
UIParent, "BOTTOM", 0, UIParent:GetHeight() * 0.75)`, re-anchored on every show, since UIParent's
height can change; clamped and movable), clear of the middle of the screen where most main windows
open. What keeps it in front of the window the eye opens is its strata (**Layering**, below). Top to
bottom:

1. The title, "Choose a skin" (`TITLE`; `frame.title`, one line), and the close control
   (`Core.MakeCloseButton` for the owner) at its top right.
2. The addon's label (`frame.ownerLabel`, **P2**): `Skin:OwnerLabel(owner)`, else the owner's name,
   left-justified on one line of its own, painted as a heading (`S.Text(fs, "heading")`, so it
   follows the skin). It is never cut off: the window's width is the label's
   `GetUnboundedStringWidth()` (rounded up) plus 12 on each side, never less than 308, set on every
   show and every time the owner's looks change. Every other piece is anchored to the window's sides
   and follows the width.
3. A dropdown button (`frame.dd`): the skin worn now (the pending pick, else the stored choice), as
   the first three of its four swatches and its name, with the eye (`frame.preview`) and the gear
   (`frame.settings`) at its right. A click opens the list under the button, **over the rows**; a
   second click closes it, and so does using a row.
4. The list (`frame.list`): one row per skin, `Skin:Skins()` order, each three swatches and the
   skin's name drawn in **that skin's own body face and size** (`Skin:ResolveSkin(key)["font.body"]`
   fetched through LibSharedMedia-3.0, at `font.bodySize`; a face LSM lacks leaves the row's normal
   font). The skin worn now is selected, the others striped, and the pointer hovers a row.
5. The rows (`frame.rows`, **The rows** below): *Font* and *Texture*, each with its reset icon
   (`frame.reset.font`, `frame.reset.texture`); *Font outline*; *Scope* (`frame.scopeLabel`) with
   *Ignore settings panel* and *Ignore fonts* side by side.
6. At the bottom, *Apply to all Ka0s addons* (`frame.applyAll`, shown only while another skin owner
   is registered, read on every show) and **Apply** (`frame.apply`, a primary button:
   `S.Button(btn, { primary = true })`).

The eye is the Media icon `eye` (tooltip "Preview: open test mode") and the gear `settings`
("Keep these choices and open the Skin settings"). Without LibKa0s-Media-1.0, or for a name the host's
icon declaration pruned, each draws its text glyph (`PREVIEW_GLYPH`, `SETTINGS_GLYPH`).

**A pick previews.** Refused in combat (`O.__combatRefused("skin picker", owner)`); otherwise
`Skin:SetChoice(owner, source, key)` (the stored source kept), so the addon and the window repaint
live, and the reload flag `SetChoice` answers is kept. The owner's write seam is **not** called and
no popup is raised. It closes the list and never the window, and picking does not count as seeing
the picker.

**The rows** (`LK-A3`). The Skin tab's font, texture, outline and scope, from the tab's own helpers
and words, under the picker's contract: a change **previews** through `Skin:SetOverride`,
`SetOutline` or `SetIgnore` and writes nothing, Apply and the gear save what moved, and a dismissal
puts it back. `frame.rows` is `{ font, texture, outline, panel, fonts }`, AceGUI widgets acquired at
the show and released at the close, so a closed picker holds none and leaves none shown; each half
is left out where its seam is missing, and the table is nil with no AceGUI, no `spec.set` (the
picker offers nothing Apply could not keep) or no helpers.

- *Font* is `Ka0sMedia_Font` and *Texture* `Ka0sMedia_Statusbar`, led by "Skin's default (X)", the
  stock Dropdown without them; with no LibSharedMedia they hold that row alone.
- Each reset icon's tooltip says *Reset font* or *Reset texture* and names the skin's own key. It is
  disabled while that half is the skin's own. Its art is the client's `UI-RefreshButton`, grayed,
  not the Media icon `reset`, which a consumer's `LibKa0s icons:` line would have to declare: a
  pruned texture draws nothing and raises nothing.
- *Ignore fonts* disables *Font outline*, as on the tab. Under the `eui` source the rows draw and
  work as on the tab. Combat disables them when they are drawn and refuses them after
  (`O.__combatRefused("skin picker", owner)`), and a refused row reads the truth again.
- **Choosing another skin** clears the font and texture override in the preview, a row's own pick
  among them (D-10), and the rows show it; the look the window opened with gets the overrides it
  opened with back.
- **A dismissal** puts back each half only while it still reads what the preview left, so a write
  from elsewhere stays. An outline that was never set is put back unset.
- **Skin.** The rows take `Skin:__PaintAceWindow`, on acquire and on every change of looks, so they
  wear the skin whatever *Ignore settings panel* says: a window keeps the skin.
- **Faces.** The rows are made with `lib.__createLazyMedia`, so showing the picker loads the skins'
  faces, the owner's own and its override's, and a font row's first open loads every other.

**Apply** saves: refused in combat with the window left up; otherwise `spec.set(source, key)` for
the pending pick, `spec.set(nil, nil, ignore)` for a moved scope and
`spec.set(nil, nil, nil, media)` for moved media (every half, `outline` the mode stored), then, when any pick in this showing asked for a reload, the one reload popup
(`lib.__appearanceReload`, `LIBKA0S_SKIN_RELOAD`, naming the addon), then the window closes.

**The close control and Escape dismiss without saving:** a pending preview is put back
(`Skin:SetChoice(owner, <the owner's stored source and skin as they read at the close>)`: `spec.get`,
else `Skin:GetChoice`; no write), and whatever the rows previewed with it, then the window closes and `onClose` runs, so a dismissal still
counts as seen. Only the unsaved preview is undone: a skin the Skin tab or a profile change stored
while the picker was up is the one put back, not the choice the window opened with. In combat they still close;
putting the preview back writes nothing. `O.HideSkinPicker()` dismisses the same way.

**Apply to all Ka0s addons** (`O.__combatRefused("skin picker", "copy")` in combat, the window left
up): Apply for this owner, then every other registered owner (`lib.__skinOthers`, the Skin tab's
own list) gets the same source, skin, scope, font, texture and font outline through
`lib.__copySkinTo(Skin, name, source, skin, ignore, media)`, reading them with
`lib.__copySettings`: the Skin tab's copy. Its skin major moves first (the live repaint), then
`Skin:WriteChoice`, its own registered setter. One
reload popup names
every addon that needs one, this one first (`"<label>, <label>"`). Then this window closes and every
queued picker is dismissed: each one's `onClose` runs and none shows. Hidden while no other owner is
registered, or on a copy without `OptionsAppearance.lua`'s helpers or `Skin:WriteChoice`.

**Layering** (`frame-layering` §1, §4): a dialog the player answers, tier T6: `DIALOG`,
`SetToplevel(true)`, clamped, moved by dragging its body. Not T4's `HIGH`: the eye's `onPreview`
typically shows the addon's main window, itself `HIGH` and toplevel, which a toplevel window's show
or click brings up over its strata peers, so at `HIGH` it covered the picker. At `DIALOG` no `HIGH`
window can; the `Raise()` after `onPreview` covers a preview that shows a `DIALOG` window of its own.
Every show re-raises a shown StaticPopup (`Core.RaiseStaticPopups`, frame-layering-§4), so the
reload popup one picker's Apply raised stays above the next queued picker. The open list is a
transient popup, tier T8: `FULLSCREEN_DIALOG`, clamped, over the rows and the Apply buttons, and it
may hang past the window's foot. A child of the window, it closes with it. The media pull-outs are
AceGUI's and open at `TOOLTIP`.

**Skin.** Every piece is painted for the owner through the Skin facade: the window by
`Core.ApplySkin(frame, nil, owner)` (so `S.Shell`, the title in the title font), the close control
by `S.CloseButton`, the dropdown button by `S.Dropdown`, the eye, the gear and both text buttons by
`S.Button` (Apply as the primary), the list by `S.MenuFrame` and its rows by `S.ListRow`. A skin
switch, a preview's included, repaints all of it live (`Skin:Repaint`), and the dropdown's swatches
and name and the rows' states follow the owner's `OnLooksChanged`. The rows' names keep their own
skins' faces: no font primitive reaches them.

### `O.HideSkinPicker()`

Takes this instance's pickers down. Its owners waiting in the queue leave it, with **no**
`onClose` (they were never seen); its window, when it is the one up, is dismissed as by the close
control (a pending preview put back, `spec.onClose` run), and the next owner waiting shows (when
combat ends, in combat). Nothing
of this instance's up or queued, it does nothing.

### `O.SkinVerb(spec)`

**Since P3** (`OptionsSkinPicker.lua` minor 3, `LK-11` of Ka0sAddonsCommonTasks
`docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/`, the owner's item 12 and ruling D-16). The act behind every
addon's `/<slash> skin` verb: the row lives in the host's `COMMANDS` table (slash-commands-§3), and its
handler calls this with the spec its first-run start builds (`NS.SkinPickerSpec()`), so the verb shows
**the same picker a new profile shows**, whatever the profile's seen flag says. A close still runs
`spec.onClose`, so the profile is still marked seen. It takes no argument of its own.

| Case | What happens | Answer |
|---|---|---|
| In combat (`InCombatLockdown()`, the queue's own predicate) | Nothing shows. `VERB_COMBAT` prints through the instance's sink **on every call**, never through `O.__combatRefused` (which prints once per combat, so a second `/xx skin` in one fight would answer nothing), and one `Cfg` line, `skin picker <owner> refused (in combat)`, goes to the descriptor's `debug` per call | `nil, "combat"` |
| Another owner's picker is up, or the queue waits out combat | Queued as `SkinPicker` queues it; `VERB_QUEUED` prints once; it shows when the one up closes | `nil, "queued"` |
| No picker to show: no Skin major, no client, an owner that never registered | `VERB_UNAVAILABLE` prints, and one `Cfg` line names the cause: `skin picker <owner> unavailable (no Skin major)`, `(owner not registered)` or `(no client)` | `nil, "unavailable"` |
| Otherwise | The picker shows; a repeat while it is up refreshes the one window, keeping the preview | the frame |

The disabled refusal is the host's: `skin` is a feature verb, not one of `lib.LIVE_VERBS`, so a
disabled addon's dispatch answers it with its one refusal line before this is called.

### `lib.SKIN_PICKER_STRINGS`

The picker's US English words, a literal table like `lib.APPEARANCE_STRINGS`: `TITLE` ("Choose a
skin", shown as it is; **P2**, where minor 1 had `TITLE_FOR`, "Choose a skin for %s"; the addon's label
is never a word of this table, it is the owner's, on its own line),
`CHOOSE_TIP` (the dropdown button's tooltip), `APPLY` ("Apply"), `APPLY_TIP`, `APPLY_ALL` ("Apply to
all Ka0s addons"), `APPLY_ALL_TIP`, `PREVIEW_TIP` ("Preview: open test mode"), `SETTINGS_TIP` ("Keep
this skin and open the Skin settings"), `PREVIEW_GLYPH` and `SETTINGS_GLYPH`; **since P3**, `O.SkinVerb`'s four:
`VERB_HELP` ("Choose a skin: open the skin picker", the `skin` row's help text, one wording for every
host), `VERB_COMBAT` (gray, "cannot open the skin picker during combat"), `VERB_QUEUED` and
`VERB_UNAVAILABLE`. ASCII throughout.
Read, never written through: `spec.strings` builds a fresh table per show.

### Declaring it

```lua
-- after the profile is ready, once per login:
if not NS.db.profile.skin.pickerSeen then
  O.SkinPicker({                     -- answers nil, "queued" while another addon's picker is up
    get = readAppearance, set = writeAppearance, page = "general",
    onPreview = function() NS.TestMode:Toggle() end,
    onClose = function() writeSkin("pickerSeen", true) end,
  })
end
```

Cases: `tests/test_options_skin_picker.lua`.

## The Appearance tab (OptionsAppearance.lua, minor 1)

New at `OptionsAppearance.lua` minor 1, a thirteenth file paired on the shell's minor
(`lib.__appearanceMinor` / `lib.__appearanceShellMinor`) and attached by `Options.lua` minor 33
(`lib.__AttachAppearance(O, d)`, guarded). `skinning-§3`: the tab on an adopted addon's General
page where the player picks the skin the addon wears (Ka0sAddonsCommonTasks
`docs/2026-10-25-SKINNING/`, item LK-10; the owner's ruling R1, per addon). It reads
`LibKa0s-Skin-1.0` at call time, never as a floor.

### `O.AppearanceTab(spec)` → tab entry

`{ key = spec.key or "Appearance", label, tooltip, before, render }`. `before` defaults to
`"Keybindings"`, the key `O.KeybindingsTab` answers, so `RenderTabbedSchema` places the tab
immediately before the Keybindings tab (and last on a page without one); `spec.before = false` asks
for last outright. `render(ctx)` is `O.AppearanceRows(ctx, spec)`, so the same entry serves a
host-drawn strip, as LootHistory's `GENERAL_TABS` takes the Keybindings entry:
`{ key = t.key, label = t.label, tooltip = t.tooltip, build = t.render }`.

### `O.AppearanceRows(ctx, spec, parent)` → view or `nil`

Draws into `parent` (default `O.EnsureScroll(ctx)`), top to bottom:

1. **Skin source**, under a heading (`O.Section` on the page's scroll, an AceGUI `Heading` in a host
   body): two radio choices, *Ka0s skins* and *EllesmereUI*. *EllesmereUI* is disabled unless
   `Skin:GetEUIStatus(owner).ok` (or the stored source is already `eui`), and a line says whether
   EllesmereUI can skin the addon, then one line per gate condition, in the status's order, with the
   client's ready-check mark (`Interface\RaidFrame\ReadyCheck-Ready`) or cross
   (`ReadyCheck-NotReady`) and, for a failing one, its fix. With a Skin copy that has no
   `GetEUIStatus` (no `SkinEUI.lua`) the choice is disabled and one line says so.
2. **Look** (`SKIN_HEADING`; not "Skin", the tab's own name since A3, `options-ui-§7`): the note
   (since A4, `LK-08`): "Skins change every visual element. HUD style options follow the skin unless
   you set them yourself.", muted; then one radio
   choice per registered skin, `Skin:Skins()` order, three to a line
   (relative width 0.32), each labeled with its four swatches (`WHITE8X8` texture markup tinted from
   the skin's `swatches`) and its name, its description on the CheckBox's `SetDescription` and in its
   tooltip. While the stored source is `eui` a line says the skin is used only if EllesmereUI cannot
   skin the addon.
3. **Font and texture** (OptionsAppearance minor 3, `LibKa0s-Skin-1.0` minor 6, LibKa0s#63), under
   its own heading: two AceGUI `Dropdown`s side by side (`BUTTON_PAIR_REL`), *Font* and *Texture*.
   Each lists, first, the value `"@skin"` (`Skin.FROM_SKIN`) as "Skin's default (<key>)", the key being
   the face (`font.body`) or bar texture (`bar.texture`) the owner wears without its overrides
   (`Skin:__BaseTokens`: the skin worn now, or EllesmereUI's table while that paints the owner);
   then LibSharedMedia-3.0's `font` or `statusbar` keys, sorted (`LSM:List`, read at call time);
   then the stored override when LibSharedMedia lacks it, as "<key> (not loaded)" (`MEDIA_MISSING`),
   so the field never shows blank. Without LibSharedMedia each lists the skin's own entry and any
   stored override alone. An override LibSharedMedia cannot resolve leaves the skin's own face or
   texture on screen until a media pack registers it. A pick is refused in combat; it calls `Skin:SetOverride(owner, font, texture)`
   first (the live repaint: a font override replaces `font.body`, `font.title` and `hud.font`, a
   texture override `bar.texture`, so every string and every `S.BarTexture` bar follows), then
   `spec.set(nil, nil, nil, { font = key|false, texture = key|false })` with both halves, `false`
   for the skin's own. *Ignore fonts* wins over a font override (`FONT_TIP` says so). Absent with a
   Skin copy that has no `SetOverride`. Under the dropdowns (A4, `LK-08`), in a row of their own,
   **Reset font** and **Reset texture** at the same width, each disabled while its half is the skin's
   own; and under those the **Font outline** dropdown (below).
4. **Scope** (OptionsAppearance minor 2, `LibKa0s-Skin-1.0` minor 5), under its own heading: two check
   boxes side by side at `BUTTON_PAIR_REL` (since A4; 0.32 before), *Ignore settings panel* (this addon's settings pages stay the client's: the
   Options chrome and the AceGUI rows paint nothing for the owner) and *Ignore fonts* (every string
   keeps its own face, size and shadow; the skin still colors it). A flip is refused in combat; it
   calls `Skin:SetIgnore(owner, panel, fonts)` first (the live repaint: fonts go back or come back,
   open pages re-render), then `spec.set(nil, nil, { panel = bool, fonts = bool })`. Neither needs a
   reload: turning *Ignore settings panel* on hands every chrome target the skin painted back as it
   was (OptionsScroll minor 7's `lib.__chromeRelease`), and turning it off paints the pages again.
   Absent with a Skin copy that has no `SetIgnore`. The **Font outline** dropdown (OptionsAppearance
   minor 4, `LibKa0s-Skin-1.0` minor 9; in the Font and texture section above, under the reset
   buttons) (`BUTTON_PAIR_REL`): *All
   text*, *HUD text only* (the default), *Off* (`"all"`, `"hud"`, `"off"`, the Skin major's `OUTLINE_MODES`), where
   the skin's font flags apply. A pick is refused in combat; it calls `Skin:SetOutline(owner, mode)`
   first (the live repaint), then `spec.set(nil, nil, nil, { font, texture, outline })` with every
   half. Grayed while *Ignore fonts* is on, which wins; its tooltip (`OUTLINE_TIP`) says so, and that
   a font outline the player set on an element still applies. Absent with a Skin copy that has no
   `SetOutline`.
5. **Other Ka0s addons** (`COPY_HEADING`, its own heading since A4): **Copy to every Ka0s addon…**
   (`options-ui-§21`'s ellipsis), a button at `BUTTON_PAIR_REL` in a row of its own. With
   no other registered owner (`Skin:Owners()` less this one) it is disabled and a line under it says
   "No other loaded Ka0s addon uses skins yet." Otherwise a click opens a confirmation
   (`LIBKA0S_SKIN_COPY`) naming the other owners by `Skin:OwnerLabel`, one per line, and saying that
   addons not loaded are unchanged; accepting gives each of them this owner's stored source, skin,
   scope, font, texture and font outline (the outline since OptionsAppearance minor 4, through
   `Skin:SetOutline` and `media.outline`): `Skin:SetChoice(other, source, skin)`, `Skin:SetIgnore(other, panel,
   fonts)` and `Skin:SetOverride(other, font, texture)` (its live repaint), then
   `Skin:WriteChoice(other, source, skin, { panel, fonts }, { font, texture })` (its own registered
   setter; the overrides since OptionsAppearance minor 3). The copying addon's own seam is not written.
   Both the click and the accept are refused in combat (`O.__combatRefused("appearance", "copy")`):
   the confirmation sits at `DIALOG`, above the page's combat cover, so it can be accepted after
   combat starts, and an accept then writes no owner.
6. Nothing after it: the note leads the Look section since A4 (it was the tab's last line).

`spec`:

| Field | Meaning |
|---|---|
| `get` | The owner's read: answers `{ source, skin }` or two values. Under pcall; without it, or for a value that is not a source or a registered skin, the Skin major's `GetChoice` stands in. |
| `set` | **MUST be the owner's write seam** (`options-ui-§1`), called as `set(source, skin)` by a pick, as `set(nil, nil, { panel, fonts })` by the Scope section and as `set(nil, nil, nil, { font, texture, outline })` by the Font and texture section and the Font outline (each override an LSM key or `false`, since A3; `outline` one of `"all"`, `"hud"`, `"off"`, since A4, and every media write carries all three), under pcall; a nil half is not written. |
| `owner` | The skin owner; default the descriptor's `addonName`. |
| `strings` | Translations of `lib.APPEARANCE_STRINGS` keys, plus `SKIN_<key>` / `SKIN_<key>_DESC` (a skin's name and description) and `COND_<key>` / `COND_<key>_HINT` (one EllesmereUI condition, `%s` the addon's label). Every string the tab draws is overridable. |
| `key`, `before` | The tab's (`AppearanceTab`). |

**A pick** (a source or a skin) is refused in combat through `O.__combatRefused("appearance",
owner)`. Otherwise it calls `Skin:SetChoice(owner, source, skin)` **first**, so the repaint is the
library's and an owner's `onChange` that calls `SetChoice` again is a no-op (it is idempotent), then
`spec.set(source, skin)`. When `SetChoice` answers `reload` (leaving an EllesmereUI that painted
this session), the tab raises the reload popup (`LIBKA0S_SKIN_RELOAD`, *Reload now* / *Later*; its
accept calls `C_UI.Reload`, else `ReloadUI`) **once**: `SetChoice` answers it on one switch per
owner. A pick of a skin keeps the stored source; a pick of a source keeps the stored skin. A radio
clicked off snaps back on. Since A4 (`LK-07`, D-10) a pick that changes the look the owner draws resets
its font and texture overrides through `lib.__chooseSkin` and then writes
`spec.set(nil, nil, nil, { font = false, texture = false, outline })` (*What changed at this
version*).

Both popups are Blizzard StaticPopups, defined when shown (`timeout = 0`, `whileDead`,
`hideOnEscape`, `preferredIndex = 3`) so their words are the spec's. A StaticPopup is a shared
Blizzard frame at `DIALOG`, above the settings window, and the tab never re-stratas or restyles it
(`frame-layering`, `skinning-§7`).

The view: `{ owner, label, source = { ka0s, eui }, skins = { [key] = choice }, media = { font,
texture }, reset = { font, texture } (the two reset buttons, A4), ignore = { panel, fonts }, outline (the Font outline dropdown, A4; nil without
`Skin:SetOutline`), order, conditions, copy, note, sync }`; `sync()` also reads `Skin:GetOutline`
into the outline dropdown and grays it while fonts are ignored; `sync()` re-reads
`spec.get` into the choices, `Skin:GetIgnore` into the two check boxes and `Skin:GetOverride` into
the two dropdowns (rebuilding their lists, so the skin's own entry names the skin worn now), and a
refresher calling it is
added to `ctx.refreshers`. Drawn inside a disabled render (`ctx.__renderDisabled`) every control is
disabled. Answers nil, drawing nothing, without AceGUI or a parent; answers nil after one line
("Skins are not available for this addon.") without `LibKa0s-Skin-1.0` or for an owner that never
called `RegisterOwner`. Away from Ka0s Default the tab's secondary lines take the owner's
`text.muted`, as the Keybindings rows do.

### `lib.APPEARANCE_STRINGS`

The tab's US English words, a literal table like `lib.KEYBIND_STRINGS`: `TAB_LABEL` ("Skin" since
A3, "Appearance" before), `TAB_TIP`, `SOURCE_HEADING`, `SOURCE_KA0S`, `SOURCE_KA0S_TIP`,
`SOURCE_EUI`, `SOURCE_EUI_TIP`, `EUI_READY`, `EUI_NOT_READY`, `EUI_MISSING`, `SKIN_HEADING` ("Look"
since A3, "Skin" before),
`SKIN_EUI_NOTE`, `MEDIA_HEADING`, `FONT`, `FONT_TIP`, `TEXTURE`, `TEXTURE_TIP`, `SKIN_OWN` (`%s` the
skin's own key), `MEDIA_MISSING` (`%s` a stored key LibSharedMedia lacks; those seven since A3),
`SCOPE_HEADING`,
`IGNORE_PANEL`, `IGNORE_PANEL_TIP`, `IGNORE_FONTS`, `IGNORE_FONTS_TIP`, `OUTLINE`, `OUTLINE_TIP`,
`OUTLINE_ALL`, `OUTLINE_HUD`, `OUTLINE_OFF` (those five since A4), `RESET_FONT`, `RESET_FONT_TIP`
(`%s` the skin's own font), `RESET_TEXTURE`, `RESET_TEXTURE_TIP` (`%s` the skin's own bar texture),
`COPY_HEADING` (those five since A4, `LK-08`), `COPY`, `COPY_TIP`,
`COPY_NONE`, `COPY_CONFIRM` (`%s` this addon's label, `%s` the list), `COPY_ACCEPT`, `CANCEL`,
`RELOAD` (`%s` the addon or addons), `RELOAD_ACCEPT`, `RELOAD_LATER`, `NOTE` and `UNAVAILABLE`.
ASCII throughout but for `COPY`'s ellipsis (U+2026), which `options-ui-§21` asks of a button that
opens a confirmation; `tests/test_prose.lua` ratifies it for this file alone. Read, never written
through: `spec.strings` builds a fresh table per tab.

### Declaring it

A page drawn by `O.RenderTabbedSchema`:

```lua
tabs = {
  O.AppearanceTab({ get = readAppearance, set = writeAppearance }),
  O.KeybindingsTab({ bindings = NS.BINDINGS }),
},
```

A hand-drawn General strip puts the entry before its Keybindings entry:

```lua
local ap = O.AppearanceTab(APPEARANCE_SPEC)
{ key = ap.key, label = ap.label, tooltip = ap.tooltip, build = ap.render }
```

### What a consumer owes

**Every Options degradation stub gains `AppearanceTab` and `AppearanceRows`**, in every addon,
adopted or not (`skinning-§3`, *Degradation*): `Kit.assertSurfaceParity` compares the stub with the
live instance, so the re-vendor of this version turns red until the stub answers both. The
suggested stub is

```lua
AppearanceTab = function(spec)
  spec = spec or {}
  return { key = spec.key or "Appearance", label = "Appearance", before = "Keybindings",
           render = function() end }
end,
AppearanceRows = function() return nil end,
```

This version's member manifest lists the lib-level tables only, as every Options manifest does, so
it names `APPEARANCE_STRINGS` and not the two instance members.

Cases: `tests/test_options_appearance.lua`.

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
  [What changed at this version](#previously-at-24314774) for the leak it fixed). **From
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

New at `OptionsWidgets.lua` minor 16. Defined in `OptionsIds.lua` (`O.ResolveId`, `O.UnnamedCandidates`,
`O.ID_NAME_HINT`, `O.IdInput`) and `OptionsIdList.lua` (`O.IdList`) from 25.32.1.1.5.7.4.1; in
`OptionsWidgets.lua` before it. **From minor 17**, an entry may carry `note = <string>`. The host owns storage. None of these writes a path: the
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

`UnnamedCandidates`: no consumer as of v1.67.0, kept because `IdInput` calls it to ask the client for names; it is pure and published for tests.

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

`ID_NAME_HINT`: no consumer as of v1.67.0, kept because `IdInput` reads it for its tooltip; it is published for a host's own tooltip.

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
redraw), a submit the list cannot help, text that matches nothing, and the start of combat
(**I3**: the lock closes a list a box on one of the instance's pages opened, and leaving combat
reopens nothing) all close it. The first four
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
| `columns` | **W24**. Optional, default `1`. Entries per line, packed row-major — `1 2` / `3 4` / `5 6`. Every relative width is divided by it and a gutter separates each entry from the next, so the line still sums to `0.98`. Floored and clamped into `1..2` — see [What changed at this version](#previously-at-24314774) for the arithmetic and for what is and is not known about the width it is measured against; a non-number reads as `1`. An entry with a `note` takes a full-width line of its own whatever the count. At more than one column a name **does not wrap**: every entry is one line tall, and a name too long for its column is truncated by the client, which cuts the tail — and the tail is the gray `(id)`, so a truncated entry shows no id. The hovered entry is lit, so the row's tooltip has a visible owner. At one column the name wraps exactly as at W23. A `suffix` is the FIRST thing that truncation takes, before the id — see [What changed at this version](#previously-at-24314774) for the order and for the character budget. |

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
[What changed at this version](#previously-at-24314774), and the full story belongs in the
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
| `shownWhen` | **W22** | `{ path = <selector path>, equals = <value> \| { <value>, … } }`. Draw the row only while the selector (read like a `disabledIf` path) holds `equals`, or any value of an `equals` list; otherwise it is dropped from the render, its heading with it when its whole subsection is dropped. A raising read reads as shown. **Since SW1, `{ any = { <clause>, ... } }`**, each clause that shape: drawn while any clause holds, every clause's path watched (see *What changed at this version: `shownWhen.any`*). A selector drawn in the same `RenderRows` call is watched (by its `path`, or a bound row by its `field`), and a change re-renders the page once on the next frame — see [What changed at this version](#previously-at-24314774). **The page must declare a renderer (`O.SetRenderer`)**: without one the page keeps the section it first drew. **Switch subgroups, not a tabbed page's groups**: `RenderTabbedSchema` builds its tabs from the unfiltered rows, so a group dropped whole still gets a tab. The row stays in the schema. For a subsection a **dropdown** chooses; a single row a checkbox dims keeps `disabledIf`. |
| `min` / `max` / `step` | W1 | Slider range. Snapping is relative to `min`, not to zero. |
| `values` on a `number` row | **W5** | Makes it a **dropdown** rather than a slider, matching what `LibKa0s-Slash-1.0`'s parser has always understood the shape to mean. Inferred, not opted into — a `values` list that resolves empty falls back to the slider. |
| `values` / `sorting` | W1 (ordered-array shape: W3) | Dropdown list, in either shape: an **ordered array** of `{ value =, text = }` (position is the order, and `sorting` is ignored) or a **key map** `{ KEY = "Label" }` (`sorting` keeps a deliberate order instead of alphabetizing). A degenerate key *set* `{ KEY = true }` labels each entry with its key. `values` may be a function, evaluated at render and parse time. |
| `dialogControl` | W1 | An in-tree widget type (`LSM30_*`, `Ka0sMedia_*`, `EditBox`). An unregistered `LSM30_*` type falls back to the matching `Ka0sMedia_*` picker (`OptionsWidgets.lua` 38), so an optional media-widget library staying absent costs nothing; any other unregistered type, and a picker that cannot register, falls back to a plain Dropdown, which costs the preview, not the option. |
| `hasAlpha` | W1 | Color picker: alpha channel — **default true**, declare `false` to suppress it. |
| `disabledIf` | W1 (every maker, and the predicate form: **W16**) | Draw the row disabled while it holds. A **settings path** whose truth disables (a path-less row reads it through `row.get(key)`), or **from W16** a predicate `function(row) -> bool`, `pcall`'d, whose raise reads as enabled. Through W15 the color picker alone read it; from W16 the checkbox, slider, dropdown, edit box and color picker all do, at build and on every refresh. A row without it is never touched. **`disabledIf` must not be used for a class-color companion** (options-ui-§17, anti-patterns #74): the swatch is still read, for its alpha, so graying it says something untrue. No composed row carries it. |
| `classColorSource` / `classColorUnit` | **C1** | `"player"` or `"unit"`, plus the token where it is `"unit"`. Stamped on **both** rows of every composed color pair. The library reads neither — they are the declaration an audit reads, because a path prefix cannot be trusted to say whose class a control means (options-ui-§17). |
| `commitOn` | W1 | `"change"` makes this slider commit on the drag, throttled; `"release"` opts out of a descriptor-wide `sliderCommit`. Default is release-only. |
| `isPercent` | W1 | Slider renders a 0–1 ratio as a percentage. |
| `maxLetters` | W1 | Edit box only. |
| `get` / `set` | **W15** | On a row with **no `path`** only: the row is read with `row.get()` and written with `row.set(value)` instead of through the descriptor's `get` / `set`. `row.get(key)` with an argument reads another key on the row's behalf: the flow engine resolves a path-less row's `disabledIf` that way, and a composed row reads that field of the same record. What a composer's `spec.bind` produces; a hand-written record row may carry them too. A row that has a `path` is always read and written through the descriptor, whatever else it carries. |
| `skinValue` | **W35** | A function `(row) -> value or nil`. When it answers, that is what the row's widget shows, in place of the stored value; writes are untouched. What a composer's `fromSkin` picker carries — see [Following the skin in the group composers](#following-the-skin-in-the-group-composers-c12-w35). |
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
| `labels` | table | `{ <canonicalLeaf> = "My label" }` — host-localized label overrides. |
| `tooltips` | table | **C10.** `{ <canonicalLeaf> = "My words." }` — replaces that row's tooltip where the canonical words misdescribe the host's wiring (`options-ui-§16`); keyed by the canonical leaf, as `labels` is, never by a `keys` rename. A **color swatch keeps the class-color sentence**: its tooltip becomes the host's words, one space, then `O.CLASS_COLOR_NOTE` (`options-ui-§17`); every other row, its companion included, takes the words as given. Only a non-empty string does anything, and an entry for an omitted leaf does nothing. Bound rows (`bind`) behave the same. **`O.MasterControls` does not read it**: `notes` is that tab's only route (`options-ui-§15`). |
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
than a property of how many rows happen to precede the block. **From C12** `fromSkin = true` appends
`fontFromSkin` on a line of its own; see [Following the skin in the group composers](#following-the-skin-in-the-group-composers-c12-w35).

**From C14** `flagsFromSkin = true` leads `fontFlags` with *From skin* (`"@skin"`, the Skin major's
`FROM_SKIN`) and makes it the default; its tooltip says what it follows. The host draws with the Skin
facade's `S.FontFlags(stored)` (`LibKa0s-Skin-1.0` SkinPaintExtras minor 7), which answers a picked
flag as stored and resolves From skin through the owner's *Font outline*. With `fromSkin = true` as
well, the block is the minimum font setting every element carries (ruling D-07 of Ka0sAddonsCommonTasks
`docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK/`). Without `flagsFromSkin` the row is C13's, byte for byte.

### `O.BorderGroup(spec)` → rows

`borderStyle` (`LSM30_Border`), `borderSize` (*Border thickness (px)*), `borderColor`,
`useClassColorBorder`. `spec.show = true` prepends `borderShow` (*Show border*), which is the only
thing that may lead the block. A border offset or anything else the addon legitimately has goes in
`spec.extra`, **after** the mandated rows, never interleaved. **From C12** `fromSkin = true` appends
`borderStyleFromSkin` after them, before any extra. **From C13** `fromSkin = "icon"` appends the same
companion following the skin's icon border family, and it governs `borderSize` too.

### `O.BarGroup(spec)` → rows

`barTexture` (`LSM30_Statusbar`), `barAlpha` (*Bar opacity*, a percentage), `barColor`,
`useClassColorBar`. **From C12** `fromSkin = true` appends `barTextureFromSkin` after them.

A host whose *Bar opacity* is applied to more than the fill (AbsorbTracker's, to the whole frame)
keeps the canonical label and passes `tooltips = { barAlpha = "..." }` (**C10**, `options-ui-§16`);
it never patches the returned row.

**A group over a background is not a bar group.** A container with a backdrop and no fill texture
takes `O.ColorPair` and nothing else; inventing a texture picker for a surface that has no texture is
a control wired to nothing.

### `O.MasterControls(spec)` → rows, afterGroup

The canonical General-page tab (options-ui-§15). Additionally takes `addonName` (for the *Enable*
label), `frameless`, `debugConsolePath` (default `"state.debugConsole"`), `onResetPosition`,
`onResetAll`, — since **C2** — `leadButton`, — since **C6** — `testModePath`, — since **C7**
— `minimapPath` and — since **C9** — `notes`, `resetPositionTooltip` and `lockIsPreview`. Of the
common spec it reads everything but `tooltips` (**C10**), which it ignores: `notes` is its only
route to its words.

| | |
|---|---|
| `enabled` — *Enable `<AddonName>`* | `visibility` — *General visibility* |
| `scale` — *Master scale* | `alpha` — *Master opacity* (labeled *Master alpha* until **C9**) |
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
  pairs in the **second** column beside *Minimap button*, and opens a line of its own where the
  host passed no `minimapPath` (or omitted the `minimap` leaf) and, since **C9**, where *Minimap
  button* has packed beside *Debug console* (below).
- **The frameless packing** (**C9**, `options-ui-§15`, U-09c). With *Lock frame* omitted — the
  frameless set, or a host's `omit.locked` — and the console row emitted, *Minimap button* carries
  no `startsLine` and sits beside *Debug console*, so no line holds a lone control; *Test mode*
  then opens its own line. With *Lock frame* present the shape is C7's. The composer lays out the
  rows the spec asks for and does not police which ones it asks for (the standard's "a frameless
  addon has no Test mode" is the host's to keep).

  ```
  frameless:             [Enable <AddonName>] [General visibility]
                         [Debug console]      [Minimap button]
                         [Reset all settings]

  framed, omit.locked:   [Enable <AddonName>] [General visibility]
                         [Master scale]       [Master opacity]
                         [Debug console]      [Minimap button]
                         [Test mode]
                         [Reset position]     [Reset all settings]
  ```

- **`notes`** (**C9**) is `{ <leaf> = "One sentence." }`. Each note is appended after the
  canonical tooltip of its row or button, with one space: the leaves `enabled`, `visibility`,
  `scale`, `alpha`, `locked`, `debugConsole`, `minimap` and `testMode`, and the buttons
  `resetPosition` and `resetAll`. It is keyed by the **canonical** leaf, so a `keys` rename keeps
  its note. A note for an omitted row, or one that is not a non-empty string, does nothing, and
  `extra` rows are the host's own and take none. **`notes` is the only way a host extends composed
  text** (`options-ui-§15`): writing a composed row's or button's label or tooltip, by patching
  the returned rows, by passing `labels` or by keeping a copy, is **anti-pattern #106**.
- **`resetPositionTooltip`** (**C9**), a non-empty string, replaces the *Reset position* tooltip
  (*"Move the frame back to where it started."*), the one canonical text that has to name the
  addon's own frames; `notes.resetPosition` then follows the replacement. Frameless addons have no
  *Reset position* button, so there it does nothing.
- **`lockIsPreview = true`** (**C9**) is for an addon whose unlocked view is its test mode. *Lock
  frame* then takes the library's one tooltip for it, quoted exactly: *"Stop the frame being
  dragged. While it is unlocked the display shows placeholder content, so it can be seen and
  placed; this is the addon's test mode."*, with `notes.locked` after it (say there what happens at
  combat start, where it is true). Such an addon ships no *Test mode* row, so `lockIsPreview` with
  `testModePath` raises *"LibKa0s-Options: MasterControls lockIsPreview is for an addon whose
  unlocked view is its test mode, so it takes no testModePath (options-ui section 15)"* at the
  host's call (the message spells the section in ASCII, because the shipped library's strings
  are ASCII). A frameless spec emits no *Lock frame* row, so it ignores the field and does not
  raise.
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
  [Previously, at 18.15.5.3](#previously-at-1815553). *Reset position*'s tooltip is the
  host's `resetPositionTooltip` where it passes one (**C9**), and both take their `notes`.

### `O.StrataTooltip(values, strings)` → string

New at `OptionsCompose.lua` minor **8** (**C8**). The tooltip of a dropdown that lets the player pick
a frame's strata. `frame-layering-§1` (player-chosen strata) makes it a **MUST** for every such row:
a host does not write tier sentences of its own, though a row-specific sentence (what the frame is)
may precede this text. Like the composers, a pure function: no widget, no state, and nothing handed
in is written to.

`values` is the row's own value table: an **array** of strata keys
(`{ "BACKGROUND", "LOW", ... }`), or the dropdown's **map** keyed by strata key
(`{ DIALOG = "Dialog", ... }`, whose labels are not read). Anything else offers no strata. The
returned string is built from three parts, in this order:

- **BASE, always:**

  > The layer this frame draws in. Background and Low draw under most of the interface, Medium is the default for displays, and High draws over other windows, in the same layer as the game's Settings window.

- **DIALOG, appended when `values` holds `DIALOG`, `FULLSCREEN`, `FULLSCREEN_DIALOG` or `TOOLTIP`**
  (it begins with a space):

  > Dialog and above also cover confirmation dialogs, this addon's debug console and the Settings window, so a frame placed there can hide them.

- **POPUP, appended when `values` holds `FULLSCREEN_DIALOG` or `TOOLTIP`** (it begins with a space):

  > Fullscreen Dialog and Tooltip can also cover dropdown menus and tooltips.

`strings` (optional) is `{ BASE =, DIALOG =, POPUP = }`, each field replacing that part (an
appended override is still appended only when the row offers its values). **The library carries no
locale**, so a host with one passes its own L's three strings through here; a non-table `strings`
is ignored. The default text is ASCII and US English.

**No value set is published.** A knob keeps the values it already stores (`BACKGROUND` to `HIGH`
is `options-ui-§16`'s set for a new row); changing a stored value set is a migration, not a
tooltip. Wire it as the row's `tooltip`:

```lua
{ type = "dropdown", path = "layout.strata", label = "Frame strata",
  values = STRATA_VALUES, tooltip = H.StrataTooltip(STRATA_VALUES) }
```

### `O.ResetAllTooltip(tail)` → string

New at `OptionsCompose.lua` minor **11** (**C11**). The tooltip *Reset all settings* carries, for
the General page's header **Defaults** where that button is the global reset: `options-ui-§12`
makes its `defaultsTooltip` this text (a **MUST**), and the host writes no wording of its own around
it. A pure function: no widget, no state.

It reads the instance's descriptor **at call time** through the same chooser `O.MasterControls`
gives the button, so the two can never differ: with no `resetProfile`, `lib.STRINGS.RESET_ALL_TIP`;
with `resetProfile`, `lib.STRINGS.RESET_ALL_TIP_PROFILE`; with `profilesPage` as well,
`lib.STRINGS.RESET_ALL_TIP_PROFILES_PAGE`. `tail` (optional) follows after one space when it is a
non-empty string; anything else adds nothing. An addon with key bindings passes options-ui-§20's
tail, `O.KEYBINDS_UNCHANGED`. `O.MasterControls`' `notes.resetAll` is that button's own and never
appears here. Declare it on the General page, built in the page builder after `lib:New`:

```lua
defaultsButton  = true,
defaultsTooltip = H.ResetAllTooltip(H.KEYBINDS_UNCHANGED),
```

## Compatibility

**At 34.4.37.5.7.11.3.14.9.4.3.6.4.3.1 one instance member is added, `O.SkinVerb` (`LK-11`), which every Options degradation stub owes (`SkinVerb = function() return nil, "absent" end`), and no member is removed**: `shownWhen` takes an `any` form (`LK-10`), and a row without one renders as it did; and: `O.FontGroup` takes one more optional spec field, `flagsFromSkin`, and a host that passes none emits what it emitted; the Skin tab draws one more
control and its `media` writes gain `outline`, which a setter written for A3 ignores (it stores the
font and texture it always stored, and every write carries the applied ones). One behavior changes
on purpose (`LK-07`): a skin pick in the tab or the picker, and *Apply to all*, now reset the font and
texture overrides when the look changes, and write the reset through the seam's fourth argument; a
host suite that pinned an override surviving a skin pick (the copy helper keeping a target's font
across a skin change included) moves with it. An Options degradation
stub owes `SkinVerb` and nothing else new. `lib.APPEARANCE_STRINGS` gains ten keys, which a host's `spec.strings` may
translate.

**At 30.2.34.3.5.9.2.11.4.2.1.4 five instance members are added and nothing is removed**: `O.StrataTooltip` (C8), `O.KeybindingsTab`, `O.KeybindRows` and `O.KEYBINDS_UNCHANGED` (K2), and `O.ResetAllTooltip` (C11).
A host that does not call it draws what it drew. **An Options degradation stub owes
`StrataTooltip`, `KeybindingsTab`, `KeybindRows`, `KEYBINDS_UNCHANGED` and `ResetAllTooltip`**: `Kit.assertSurfaceParity` compares a stub against the live instance (the
surface registered with `Kit.setSurfaceSource`), so a stub without it turns the re-vendor red. This
version's manifest lists the lib-level table only and does not name them. The two other moves (I3, OC2) are internal and owe nothing. `OptionsKeybinds.lua` (K1) adds one public lib-level table, `lib.KEYBIND_STRINGS`, which the manifest names, and otherwise only `__` members; `Options.lua` 30's guarded attach changes nothing a host draws, and a copy without `OptionsKeybinds.lua` is otherwise this version. A stub of the instance owes nothing for K1. K2's three members draw nothing until a host calls them, and a copy without `OptionsKeybinds.lua` has none of them. `OptionsKeybinds.lua` 3 (K3) adds only `__` library-level names and one hidden frame that registers `UPDATE_BINDINGS` through Core's `SafeRegisterEvent` while a keybind row is on screen, so a stub owes nothing for it and a host with no settings page open owns no registration. `OptionsCompose.lua` 9 (C9) adds no member, so a stub owes nothing for it; its three `O.MasterControls` fields change nothing for a host that passes none of them, but two owner-ruled changes reach every host that re-vendors: the alpha row reads *Master opacity* (no stored path moves, so a suite pinning *Master alpha* changes at the addon's re-vendor), and a host that omits *Lock frame* (every frameless host) draws *Minimap button* beside *Debug console*. `OptionsCompose.lua` 10 (C10) adds no member, so a stub owes nothing for it; the group composers' `tooltips` field is opt-in, and a host that passes none draws exactly what it drew. `OptionsCompose.lua` 11 (C11) adds `O.ResetAllTooltip`, which draws nothing; a host that does not call it draws what it drew, and its stub owes the member. `OptionsKeybinds.lua` 4 (K4) adds and removes no member, so a stub owes nothing for it; what changes is drawn: a row has one key button and Clear, a suite that read a row's `slots[2]` reads the one button's `"<key> +1"` text instead, and `lib.KEYBIND_STRINGS` drops `KEY1` / `KEY2` (a host's translation of either is ignored) for `KEY`, `KEY_MORE`, `KEYS_ALL` and `KEYS_OTHER`.

**At 29.2.34.2.5.9.1.7.4.2.1 one `__` test seam is removed and nothing public moves**:
`__releaseChrome`, which no suite or roster consumer called. A host draws what it drew. An Options
degradation stub that mirrored `__releaseChrome` should drop it at the re-vendor;
`Kit.assertSurfaceParity` iterates the live surface, so a stub that keeps it turns nothing red.
`OptionsIdList.lua` minor 5 is comment-only. A host that draws help marks declares `info` on its
`LibKa0s icons:` line or passes its own `helpIcon`; an undeclared `info` draws blank.

**At 29.2.34.2.4.8.1.7.4.2.1 one member is added and nothing is removed**: `O.Drawer` (D1). A host
that does not call it draws what it drew; `RefreshPanel` on a page ctx is unchanged. An Options
degradation stub pinned with `Kit.assertSurfaceParity` by name gains a `Drawer` no-op. A copy
without `OptionsDrawer.lua` has no `O.Drawer` and is otherwise this version.

**At 28.2.34.2.4.8.1.7.4.2 no member, field or string is added or removed.** The help-art guard stops reading the
bare `IsAddOnLoaded` global, which no supported client has. On a client with no `C_AddOns` reader
the name is trusted, as it was at 28.2.34.2.3.8.1.7.4.2 when neither API existed; on every live client the guard
answers exactly as before.

**At 28.2.34.2.3.8.1.7.4.2 no member, field or string is added or removed.** The help mark's default art is
taken from `addonName` only when the client reports that addon loaded; a host that passes its real
folder name draws what it drew, and a host that passes a wrong one now draws the client glyph rather
than a path to nothing, with one `Cfg` line through `debug`. `Options.lua`'s change is a comment.

**At 27.2.34.2.2.8.1.7.4.2 four optional `RenderTabbedSchema` fields are added and nothing is removed**:
`untabbedSkipRender`, `disabledReplaces`, `disabledNoticeFont` and `rerender`. A host that passes none
draws what it drew. One report narrows, and only under the new flag: a page whose groups
`untabbedSkipRender` keeps off the strip is not reported as having no groups, since it has some.

**At 27.2.34.2.2.7.1.7.4.2 two optional arguments are added and nothing is removed**: `RenderGrid`'s
`parent` and `opts`. A call that passes neither draws what it drew, with one deliberate exception a
host can see only when an item fails: a wide item that raised no longer leaves a blank row and a gap.
No consumer's `make` answers `false` at this version, so the `false` arm changes nothing already
shipped. A degradation stub that names `RenderGrid` needs no change: a no-op ignores extra arguments.

**At 25.32.1.1.5.7.4.1 no member is added, removed or repurposed**: the id surface moved file, which changes
the version key and `lib.MODULES` and nothing a host calls. A host written against 25.31.5.7.4.1 needs no
change, and a degradation stub pinned by name is unaffected: the two new attach functions are
`__`-prefixed, outside surface parity.

**At 24.31.4.7.4 no member is added or removed**: the font preload moved file; the drag throttles
stop reading `scheduleTimer`'s return value, which a host whose timer answers a handle cannot
observe; the banner's dropdown is Released and the header frame and divider texture reused, which a
host observes only if it held the old dropdown past the next render or built raw regions into the
header frame on every call (none of the five hosts calling `PageBanner` or `PageHeader` at this
version does either); `OpenOptionsPanel`
now returns a value where it returned none, which a host that ignored the result cannot observe; and
`CreateOptionsPanel` called in combat registers when combat ends rather than at once.
`RenderTabbedSchema`'s fifth argument and `PageBanner`'s `action` are optional spec fields: a host
that passes neither draws what it drew, and each gains a second return value a caller that ignored
the first cannot observe. The `CreateOptionsPanel` park
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
[What changed at this version](#previously-at-24314774) apply. Out of combat every page draws
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
