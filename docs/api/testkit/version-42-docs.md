# `testkit` — version 42

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/` — `framework.lua`, `asserts.lua`, `inventory.lua`, `secrets.lua`, `latch.lua`, `bindings_xml.lua`, `loader.lua`, `mock_base.lua`, `mock_record.lua`, `mock_events.lua`, `mock_resize.lua`, `mock_lines.lua`, `mock_ids.lua`, `mock_bindings.lua`, `mock_layers.lua`, `vendor_sync.lua`, `test_eol.lua`, `test_prose.lua`, `prose_lists.lua`, `prose_coverage.lua`, `prose_selftests.lua`, `test_layout_cap.lua`, `test_diagnostics_contract.lua`, `lizard_sighted.lua`, `test_lizard_sighted.lua`, `run-automated-tests.sh`, `README.md` |
| Version | **42** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.77.0 |
| Status | **Current** |
| Supersedes | [version 41](version-41-docs.md) — the base answered every binding call and every frame-layer getter from its metatable (with the frame, or not at all), and no kit check read an addon's `Bindings.xml` |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `42` |

Everything revision 41 describes is unchanged here except what follows. Three files are added. Revision
42 is one release's kit: LibKa0s v1.77.0 ships it once, and every kit change in that release is listed
below rather than taking a revision of its own. `Kit.expose` also gains one
published member, `keybindThroughTab` (from `bindings_xml.lua`).

## What changed

### `mock_bindings.lua`, an opt-in binding mock

Through revision 41 nothing in the kit answered the client's key-binding API: a bare `GetBindingKey`
was nil, and a frame method of the same shape answered with the frame. QuickComms carried its own
model in `tests/wow_mock.lua`; this file is that model, ported, extended to two binding slots per
command, and shared. It is **opt-in**, in the `mock_ids.lua` pattern: `mock_base.lua` does not load it
(that file is at 1464 lines, under its 1490 re-check trigger, and unchanged by this revision).

```lua
local M = base()
dofile("tests/_kit/mock_bindings.lua")(M)                                 -- the binding API
dofile("tests/_kit/mock_bindings.lua")(M, { clientChordHelpers = true })  -- plus the chord helpers
```

The installer returns `M`. It fills only the names `M` lacks, so a consumer's own fixture keeps
answering; the `__binding*` seams are always installed, because they are the mock's state.

| Member | What it answers |
|---|---|
| `M.__bindingSets` | `{ [1] = { actions = {}, keys = {} }, [2] = { ... } }`, each saved set |
| `M.__bindingLive` | the live tables every call reads and writes; a copy of a set until saved |
| `M.__bindingSet` | the current set, default 1 |
| `GetBindingKey(command)` | every key bound to the command, in bind order (slot 1, slot 2, ...); nil when none |
| `GetBindingAction(key)` | the command, or `""` for a free key |
| `SetBinding(key, command)` | in combat (`M.InCombatLockdown()`): appends `{ key, command }` to `M.__bindingRefusals`, answers false. When `M.__bindingFailNext == key`: clears the seam, answers false. Otherwise a nil command unbinds the key; a command takes the key from the action that had it (left keyless if it was its only key) and appends it to its own array; appends `{ key, command }` to `M.__bindingWrites`; fires `UPDATE_BINDINGS` unless `M.__bindingsFireOnSet == false`; answers true |
| `SaveBindings(set)` | in combat: `{ save = set }` in `M.__bindingRefusals`, nothing else. Otherwise copies the live tables into `M.__bindingSets[set]`, makes `set` current, appends it to `M.__savedBindingSets`, fires `UPDATE_BINDINGS` |
| `LoadBindings(set)` | makes `set` current and live (an unsaved change is discarded), fires `UPDATE_BINDINGS` |
| `GetCurrentBindingSet()` | `M.__bindingSet` |
| `GetBindingText(key)` | the key |
| `GetBindingName(command)` | `M["BINDING_NAME_" .. command]`, else `_G`'s, else the command (`BindingUtil.lua`) |
| `M.__bindingFires` | how many `UPDATE_BINDINGS` the mock fired (set, save and load all count) |
| `NOT_BOUND`, `KEY_BOUND`, `KEY_UNBOUND_ERROR` | the client's strings, where missing |
| `ACCOUNT_BINDINGS`, `CHARACTER_BINDINGS` | 1 and 2, where missing |
| `Enum.BindingSet` | `{ Default = 0, Account = 1, Character = 2 }`, merged into `M.Enum` (created if absent) member by member, never replacing one |
| `IsAltKeyDown`, `IsControlKeyDown`, `IsShiftKeyDown`, `IsMetaKeyDown` | read `M.__modifiers`, all false by default |
| `M.setModifiers{ alt =, ctrl =, shift =, meta = }` | sets all four; a missing field is false |
| `M.bindKey(key, command)` | seeds the live tables and the current set without recording or firing |
| `M.clearBindings()` | empties both sets, the live tables and every log |

`UPDATE_BINDINGS` goes through `M.__fire` (`mock_record.lua`), so it reaches exactly the frames and
AceEvent targets registered for it.

With `clientChordHelpers = true` the installer adds three client helpers, faithful to
`BindingUtil.lua`: `GetConvertedKeyOrButton` (`LeftButton` `BUTTON1`, `RightButton` `BUTTON2`,
`MiddleButton` `BUTTON3`, `ButtonN` `BUTTONN`, else the key), `IsKeyPressIgnoredForBinding` (`LSHIFT`
`RSHIFT` `LCTRL` `RCTRL` `LALT` `RALT` `LMETA` `RMETA` `UNKNOWN`, as `BindingUtil.lua:21-25`; not
`BUTTON1` / `BUTTON2`, which the binding page refuses in its own click handler, `:90-92`) and
`CreateKeyChordStringUsingMetaKeyState(key)` (`ALT-CTRL-SHIFT-META-` order, a modifier key alone
adding no key). They are absent by default, so a suite exercises the library's bundled fallback
unless it asks for the client's.

**Fidelity notes.** `SaveBindings(set)` making `set` current is the client's behavior (the
character-specific toggle saves into the other set and switches to it). `LoadBindings` is not
refused in combat here; nothing in the library calls it. `GetBindingText` does not localize or
abbreviate: a suite asserting row text reads the key it bound.

### `mock_layers.lua`, an opt-in frame-layer recorder

Through revision 41 the base answered every capitalized method it does not define with the frame
(`mock_base.lua`'s metatable): `GetFrameLevel` and `GetParent` handed back the frame itself, and
`SetFrameStrata`, `SetToplevel` and `SetClampedToScreen` stored nothing.

```lua
local restore = dofile("tests/_kit/mock_layers.lua")(M)
-- every frame M.CreateFrame builds from here records its layers
restore()   -- M.CreateFrame (and M.UIParent's fields) are the base's again
```

It wraps `M.CreateFrame`, so every frame created **after** install gets these methods rawset on it,
and installs them on `M.UIParent` when that is a table:

| Method | Answer |
|---|---|
| `SetFrameStrata(s)` / `GetFrameStrata()` | own, else the nearest ancestor's, else `"MEDIUM"`; `s` must be one of `BACKGROUND`, `LOW`, `MEDIUM`, `HIGH`, `DIALOG`, `FULLSCREEN`, `FULLSCREEN_DIALOG`, `TOOLTIP`, and an unknown one raises naming itself |
| `SetFixedFrameStrata(b)` / `HasFixedFrameStrata()` | recorded |
| `SetFrameLevel(n)` / `GetFrameLevel()` | own explicit level, else the parent's level + 1; a frame with no parent is 0 |
| `SetFixedFrameLevel(b)` / `HasFixedFrameLevel()` | recorded |
| `SetToplevel(b)` / `IsToplevel()` | recorded |
| `SetClampedToScreen(b)` / `IsClampedToScreen()` | recorded |
| `Raise()` / `Lower()` | counted in `__raised` / `__lowered`; the level does not move |
| `SetIgnoreParentAlpha(b)` / `IsIgnoringParentAlpha()` | recorded |
| `SetParent(p)` / `GetParent()` | over the `__parent` `M.CreateFrame` recorded; `SetParent` drops an explicit level, which the client re-derives from the new parent (XS-18) |

The survey `M.__layers(frame)` answers `{ strata, level, toplevel, clamped, fixedStrata,
ignoreParentAlpha, raised }`. Inheritance reads the parents' raw fields, so a plain parent built
before the install still answers `MEDIUM` and 0.

**Fidelity notes.** Frames built before the install, and frames the base builds for itself
(`GameTooltip`, the Ace fakes' frames), stay plain. Code that cached `local CreateFrame =
CreateFrame` at load keeps the function it cached, so install before loading the code under test
when it does that. **Spying:** a suite that spies on one of these methods by rawset restores it by
re-assigning the function it saved, not by rawsetting nil: the base's restore idiom
(`mock_base.lua`'s geometry comment) would erase the recorder.

### `Kit.assertBindingsXml`, the shared `Bindings.xml` check, in `bindings_xml.lua`

`launcher-§6`'s re-check paragraph deferred a vendored `Bindings.xml` check until an addon shipped
more than one binding. DpsRace and QuickComms do, so the trigger has fired. `framework.lua` loads
the file beside `latch.lua`, and `Kit.expose` publishes `t.assertBindingsXml`.

```lua
local list = T.assertBindingsXml("Bindings.xml", {
  category = "BINDING_HEADER_MYADDON",   -- required
  commands = NS.BINDINGS,                -- required: command strings or { command = ... } records
  brand    = NS.BRAND,                   -- required
  globals  = mocks,                      -- default _G
  labels   = { MYADDON_TOGGLE = "Toggle the window" },   -- optional
})
-- list = { { name = "MYADDON_TOGGLE", category = "BINDING_HEADER_MYADDON" }, ... }
```

It strips `<!-- ... -->` comments, reads every `<Binding .../>` and `<Binding ...>` element's
attributes (double- or single-quoted), and fails through `Kit.fail` at the caller's line, with a
message naming the file and `launcher-§6`, unless: there is at least one Binding; every `category`
equals `opts.category`; no Binding carries `header=` or `default=`; the names equal the commands in
order (the count first); each `globals["BINDING_NAME_" .. name]` is a non-empty string, equal to
`labels[name]` where given; and `globals[opts.category] == opts.brand`. A missing or unreadable file
fails too. It is a shape check over a small, flat file, not an XML parser.

### `Kit.keybindThroughTab`, the Keybindings tab's driver, in `bindings_xml.lua`

Added with LibKa0s's `OptionsKeybinds.lua` minor 2 (the settings-panel Keybindings tab,
`options-ui-§20`), in this same unreleased revision. `Kit.expose` publishes `t.keybindThroughTab`,
and now records the harness's mock (`t.mocks` or `t.mock`) for it.

```lua
local rows = O.KeybindRows(ctx, { bindings = NS.BINDINGS })   -- or the tab, drawn by its page
local status = T.keybindThroughTab(rows[1], 1, "K", { shift = true })
-- GetBindingKey(NS.BINDINGS[1].command) == "SHIFT-K"; status == KEY_BOUND
```

`Kit.keybindThroughTab(row, slot, key, mods)` does what a player does: it fires the row's slot
widget's `OnClick` callback with `"LeftButton"` (through the AceGUI fake's `__fire`), sets `mods`
(`{ alt, ctrl, shift, meta }`) through the binding mock's `M.setModifiers` for the press when given
and puts the previous state back after it, runs the `OnKeyDown` script of the library's capture
listener (`lib.__keybindListener`, the library resolved through
`LibStub("LibKa0s-Options-1.0")`) with `key`, and answers the row's outcome-line text. `slot`
defaults to 1. The mock is the one handed to `Kit.expose`, else `_G`. It fails through `Kit.fail`,
naming `options-ui-§20`, when `row` is not a row record, the slot widget is missing, there is no
listener with an `OnKeyDown`, or `mods` is given with no `M.setModifiers`.

**Slot 2 on a one-button row** (with LibKa0s's `OptionsKeybinds.lua` minor 4, still this revision:
v1.77.0 had not shipped when it changed). From that minor a row has **one key button** and Clear
(`options-ui-§20`), so slot 1 is that button, driven exactly as above, and a second key is the one a
player sets on the client's Options -> Keybindings page. When `slot` is 2 and the row has no slot-2
widget, the driver writes it through the library's model as that page would: `lib.__keyChord(key)`
with `mods` held (and put back), then `lib.__keybindSet(row.command, 2, chord)`, then the row's
view repainted (`row.view.repaint()`, the `UPDATE_BINDINGS` sync's work, done at once so a suite
needs no timer). It answers the client's `KEY_BOUND` (`lib.__keybindClientString`), or
`KEYBIND_STRINGS.COMBAT` / `UNAVAILABLE` / `FAILED` for a refusal. A press `lib.__keyChord` answers
nil for (`ESCAPE`, a modifier pressed alone, an ignored key) writes nothing, in combat or out, and
the driver answers the row's own outcome-line text, as slot 1 does on Escape. A row drawn by an older minor,
with a second slot widget, is still clicked. It fails naming `options-ui-§20` when the row has no
string `command` or the library has no `__keybindSet`.

```lua
T.keybindThroughTab(rows[1], 1, "K")                   -- the key button: slot 1
T.keybindThroughTab(rows[1], 2, "J", { shift = true }) -- the game page's key: slot 2
-- GetBindingKey(command) == "K", "SHIFT-J"; rows[1].slots[1].text == "K +1"
```

No documented member is renamed or removed and no case name changes. `mock_base.lua` is unchanged.

## What a consumer owes

Re-vendor `tests/_kit/` whole:

```sh
cp -r testkit/. tests/_kit/
git update-index --chmod=+x tests/_kit/run-automated-tests.sh
lua tests/run.lua --list > docs/test-cases.md
```

Nothing else: the two mocks are opt-in and the check is a member a suite calls. A consumer's own
prose that names the revision it holds moves to 42 in the same commit. An addon with key bindings
installs `mock_bindings.lua`, calls `T.assertBindingsXml` from its own suite and binds a key through
its Keybindings tab with `T.keybindThroughTab`; an addon asserting
strata or level installs `mock_layers.lua`.
