# `LibKa0s-Launcher-1.0` — version 4

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Launcher surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Launcher-1.0` |
| Files and minors | `Launcher.lua` minor **4** |
| Shipped in | v1.58.0 |
| Status | **Current** |
| Supersedes | [version 3](./version-3-docs.md) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`). **LibDataBroker-1.1** and **LibDBIcon-1.0** are OPTIONAL and are resolved with `LibStub(…, true)` at `Register` time, never at load. The client's context-menu API (`MenuUtil`, 11.0 and later) is OPTIONAL too, resolved on every right click. |
| Confirm in-game | `LibStub("LibKa0s-Launcher-1.0").MODULES` → `{ Launcher = 4 }` |

## What changed at this version

The owner's M6 ruling of 2026-09-24, made a MUST by the standard's v2.67.0 (`launcher-§2`, WS-11).

- **Left-click opens the settings panel**, on every addon, in either state. It calls `openSettings`
  and nothing else. The three left-click rungs are retired, and so is version 2's disabled
  left-click refusal: the panel is setup, not a feature, and it is where a disabled addon is
  re-enabled.
- **Right-click opens the options menu**: the client's own context menu,
  `MenuUtil.CreateContextMenu`, titled with the label, with one checkbox per toggle the
  descriptor supplies, in this order and no other:

  ```
  <label>
  [x] Enabled         isEnabled + setEnabled(bool)
  [ ] Locked          isLocked + toggleLock           grayed while disabled
  [ ] Test mode       isTestMode + toggleTestMode     grayed while disabled
  [ ] Show window     isWindowShown + toggleWindow    grayed while disabled
  ```

- **Four new optional descriptor fields**, each the toggle half of a pair: `setEnabled`,
  `toggleLock`, `toggleTestMode`, `toggleWindow`; and one new accessor, `isWindowShown`. The other
  three accessors (`isEnabled`, `isLocked`, `isTestMode`) are the ones the tooltip already reads.
- **Four descriptor fields are retired** and ignored if passed, with no error: `onClick` and
  `leftClickLabel` (the left button has one meaning now), and `disabledLine` and `slash`, which
  served only the retired refusal and its tooltip hint. Version 2's rule that `isEnabled` needs a
  `disabledLine` is gone with them.
- **The tooltip's click hints are fixed**: `Left-click: Open settings` and
  `Right-click: Options menu`, in either state. The rest of version 3's tooltip is unchanged.
- **`lib.STRINGS`** gains `TOOLTIP_OPTIONS_MENU` and seven `MENU_*` keys, and loses
  `TOOLTIP_LEFT_DEFAULT`, `TOOLTIP_DISABLED_HINT` and `TOOLTIP_DISABLED_BARE`. A host `d.L` still
  carrying the three is read by nothing.

## What this major is

**The minimap button and the broker plugin, as one object registered twice** (`launcher-§1`). The
addon creates a single **LibDataBroker-1.1** object of `type = "launcher"` and hands that object to
**LibDBIcon-1.0**; LibDBIcon draws the minimap button from it, and any broker display that is
installed draws its own row from the very same object. One `OnClick`, one icon, one label, one
identity.

It is not two features, and an addon that builds a minimap button with its own click handler and a
broker object with a second one has written the same feature twice and will drift on the next
behavior change — **anti-pattern #81**. Eleven addons were about to write that wiring eleven times.

The **host** supplies what is genuinely its own: its folder name, its logo, how its settings panel
opens, and the accessor-and-toggle pairs for the states it has. This module owns the rest: what each
button does, the tooltip, the menu, and when an entry is grayed.

## What it deliberately does NOT own

**The toggles' effects.** Every menu entry calls the host's own handler, the one its slash verb and
its settings row already use, so the refusals, the combat rules and the chat messages are the
addon's. The menu holds no state and writes nothing itself.

**The settings row.** The minimap button's visibility is a Master-controls row (`options-ui-§15`),
emitted by `LibKa0s-Options-1.0`'s `MasterControls` composer from its **`minimapPath`** spec key.
This module registers no row and reads no settings store.

**The inversion.** `launcher-§3` stores the visibility as LibDBIcon's **own** `hide` boolean and the
row's label says *shown*, so the row's `get`/`set` invert at the **host's single write seam**
(`options-ui-§1`). This module offers `SetShown` / `IsShown` for that seam to call.

**The scope.** The `minimap` table is `db.global.minimap`, and the standard fixes it there for two
stated reasons: a profile switch must not move a player's buttons, and `options-ui-§12`'s *Reset all
settings* — a profile reset by definition — must not un-hide a button the player deliberately hid.
The host hands the table in; this module does not know what a profile is.

**The icon file.** `launcher-§4` and `layout-§4` own it: `media/logos/<addon>.logo.128.tga`, 128×128,
uncompressed 32-bit, the same file the TOC's `## IconTexture` names. A launcher registered with no
icon file behind it draws **nothing**, which is worse than the state before adoption.

## Neither broker library is a dependency

LibDataBroker-1.1 and LibDBIcon-1.0 are resolved with `LibStub(…, true)` **at `Register` time**, and
a host that has neither gets a launcher that reports itself absent rather than one that raises. That
is the same bargain LibSharedMedia strikes in `Media.lua` and AceGUI-3.0 in `Options.lua`: this
library is vendored into eleven addons whose `libs/` folders are not identical.

Call time rather than load time is deliberate too. `LibKa0s.xml` is one entry in a TOC's
`# Libraries` block and the broker libraries are others; nothing fixes their relative order, and a
lookup taken at load would answer `nil` for a host that happens to list LibKa0s first.

| State | `Register()` | `Object()` | Minimap button | `SetShown` / `IsShown` |
|---|---|---|---|---|
| Both libraries present | `true` | the object | drawn | act on the button and the store |
| LibDBIcon absent | `false` | the object | none; a broker display still shows the plugin | `SetShown` returns `false`, still records `hide`; `IsShown` reads the store |
| LibDataBroker absent | `false` | `nil` | none | `SetShown` returns `false`, still records `hide` |
| `descriptor.minimap` answers no table | `false` | the object | none | `IsShown` answers `true` |

Every one of those reports one line naming the addon and the missing piece, through
`descriptor.print` or the chat frame — **once per instance** since version 2, however many times
`Register` is called.

## The descriptor

`lib:New(d)` raises on a missing `name`, `icon` or `openSettings`, and on nothing else. None of the
three has a defensible default: the folder name keys LibDBIcon's saved position, the icon is the
addon's face in three places, and left-click **always** opens the panel.

| Field | Since | Required | What it is |
|---|---|---|---|
| `name` | **L1** | yes | The addon's **folder name**, used for **both** registrations (`BankLedger`, `PartyFrameEnhanced`). Not cosmetic: LibDBIcon keys the button's saved position by it, so a second spelling drops the angle the player dragged the button to and labels the broker plugin with the other name. |
| `icon` | **L1** | yes | The addon's own logo — the same file `## IconTexture` names. Never a Blizzard path and never a numeric file id (**anti-pattern #82**). |
| `label` | **L1** | no | What a broker display labels the plugin, and the title of the tooltip and of the menu. Defaults to `name`. |
| `minimap` | **L1** | yes | LibDBIcon's own table, `db.global.minimap`, **or a function answering it**. A function is the usual shape: `db.global.minimap` does not exist when the host builds its descriptor at file load, and a table captured then is one AceDB later replaces. Resolved at `Register` time. |
| `openSettings` | **L1**, meaning changed at **L4** | yes | Opens the addon's settings panel. **Left-click always** calls it, in either state (version 4); so does right-click where the client has no context-menu API or the descriptor supplies no toggle. Handed the button name. |
| `isEnabled` | **L2** | no | Whether the addon is enabled, asked on every show and every menu open, never cached. The tooltip's `Enabled` line; with `setEnabled`, the menu's *Enabled* entry; and while it answers false (or nil), the menu's other entries are grayed. A host without it is always enabled. Since version 4 it gates no click. |
| `setEnabled` | **L4** | no | `setEnabled(bool)` — the addon's own enable/disable path, the one `/<slash> enable` / `disable` write (`slash-commands-§2`). Handed the state the addon is moving **to** (`not isEnabled()`, read at the click). With `isEnabled`, draws *Enabled*. |
| `isLocked` | **L3** | no | Where the addon has a lock (the *Lock frame* row): answers whether it is locked. The tooltip's `Locked` line; with `toggleLock`, the menu's *Locked* entry. |
| `toggleLock` | **L4** | no | The addon's own lock/unlock toggle, the one `/<slash> lock` / `unlock` and the *Lock frame* row use. Called with no argument. |
| `isTestMode` | **L3** | no | Where the addon has a test mode: answers whether it is on. The tooltip's `Test mode` line; with `toggleTestMode`, the menu's *Test mode* entry. |
| `toggleTestMode` | **L4** | no | The addon's own test-mode toggle, the one `/<slash> test` and the *Test mode* row use. Called with no argument. |
| `isWindowShown` | **L4** | no | Where the addon has a **primary window** (standalone-windows — the browser, ledger, meter window or group popup the addon exists to show, not a settings or export dialog): answers whether it is shown. With `toggleWindow`, the menu's *Show window* entry. |
| `toggleWindow` | **L4** | no | The primary window's own toggle. Called with no argument. |
| `onTooltipShow` | **L1**, meaning changed at **L3** | no | Called **once per show**, handed the tooltip, to **append** the addon's own lines between the status block and the click hints. It draws no title, version, status line or click hint (**anti-pattern #89**). A non-function is dropped; a raising one costs its lines and nothing else. |
| `version` | **L3** | no | A string (or a function answering one) drawn after the label in the tooltip's title, `<label>  v<version>`. A leading `v` is not doubled; `nil` or `""` draws the label alone. |
| `print` | **L1** | no | Where this module's own reports go. Defaults to `DEFAULT_CHAT_FRAME`. |
| `debug` | **L1** | no | `debug(tag, message)` — the host's log seam, called with the tag `"Launcher"`. |
| `L` | **L1** | no | Locale override, keyed to `lib.STRINGS`. Read with `rawget`, so a host table that answers an unknown key **with the key** (which every Ka0s locale table does — **anti-pattern #2**) falls through to the library's English rather than printing `MENU_LOCKED` at the player. |

### Retired at version 4

Ignored if passed; `New` raises on none of them, so a host that has not yet re-vendored its setup
file keeps working and is carrying dead configuration (`launcher-§5`).

| Field | Was | Why it went |
|---|---|---|
| `onClick` | **L1** — the left click's action, and so the addon's rung | Left-click opens the settings panel on every addon; the rungs are retired (`launcher-§2`, v2.67.0). The action it ran is now a menu entry: pass its toggle as `toggleWindow`, `toggleTestMode` or `toggleLock`. |
| `leftClickLabel` | **L3** — `Left-click: <label>` on rungs (a)/(b) | The hint is fixed, `Left-click: Open settings`. |
| `disabledLine` | **L2** — the line the disabled left-click refusal printed | There is no refusal: the left button opens the panel in either state, and a grayed menu entry calls nothing. |
| `slash` | **L3** — the command the disabled hint named | The disabled hint is gone. |

## The two buttons

| Button | Does | Gated while disabled? |
|---|---|---|
| **Left** | `openSettings(button)` | no — the panel is setup, and where the addon is re-enabled |
| **Right** | opens the options menu (below) | no — *Enabled* is live; the other entries are grayed |

There is **no setting** that reassigns either button, and a host MUST NOT build its own menu or
route clicks itself (`launcher-§2`, anti-pattern #81).

## The options menu

Built by `MenuUtil.CreateContextMenu(owner, generator)`, where `owner` is the frame the client
handed `OnClick` (the minimap button, or the broker display's row), falling back to `UIParent`. The
generator runs when the menu opens:

1. `root:CreateTitle(label)` — the plain-text `label`, else `name`.
2. One `root:CreateCheckbox(text, isSelected, setSelected)` per supplied entry, in the order
   *Enabled*, *Locked*, *Test mode*, *Show window*. An entry is supplied when the descriptor passes
   **both** its accessor and its toggle as functions; half a pair draws nothing, since a checkbox
   that can show a state but not change it, or change one it cannot show, is not an entry.
3. **Each state is read at that moment**, once per open, and never cached: `isSelected` answers the
   value read when the menu opened. A raising accessor reads unchecked and is reported to `debug`.
4. **While `isEnabled()` answers false**, *Locked*, *Test mode* and *Show window* are grayed with
   `SetEnabled(false)` and their text reads `<entry> (enable the addon first)`. The note is in the
   label rather than in an entry tooltip because the client does not run a disabled button's
   motion scripts by default, and a note in a tooltip nobody can raise is no note. *Enabled* stays
   live.

**A click** calls the host's handler **once** — `setEnabled(not isEnabled())` for *Enabled*, the
toggle with no argument for the rest — and answers `MenuResponse.Close`, so the next open reads
every state afresh. A gated entry clicked while the addon is disabled (a client that dispatched a
grayed entry anyway) calls no handler and writes nothing. A raising handler prints one line,
`MENU_FAILED`, naming the addon, the entry and what raised, and never escapes into the client's
menu dispatch.

**Degrading.** The right click resolves `MenuUtil` on every click. Where it is absent, or has no
`CreateContextMenu`, or the descriptor supplies no entry at all, the right click calls
`openSettings("RightButton")` instead — the panel holds every toggle the menu would have — and the
`debug` seam hears which. A raising `CreateContextMenu` is reported with `CLICK_FAILED` like any
other raising click.

## The status tooltip

Drawn by `drawTooltip`, which is the LDB object's `OnTooltipShow` on every host (version 3). LibDBIcon
calls it on hover with `GameTooltip`, a broker display with its own tooltip; an argument with no
`AddLine` is left alone.

| Line | Drawn when | Reads |
|---|---|---|
| `<label>  v<version>` | always | `label` (else `name`), `version` |
| `Enabled: Yes\|No` | always | `isEnabled()`; a host with no `isEnabled` is always Yes. Green Yes, red No. |
| `Locked: Yes\|No` | `isLocked` passed | `isLocked()`, green Yes, red No |
| `Test mode: On\|Off` | `isTestMode` passed | `isTestMode()`, green On, red Off |
| the host's lines | `onTooltipShow` passed | whatever it adds, once |
| `Left-click: Open settings` | always | nothing; fixed since version 4 |
| `Right-click: Options menu` | always | nothing; fixed since version 4 |

- **Never cached.** Every accessor is asked on every show, so the tooltip reads what the settings
  panel reads the moment it changes.
- **The only color is the status value's**, green for Yes/On and red for No/Off, wrapped by the code
  around the localized word; no `lib.STRINGS` value carries an escape, and the title carries none.
- **Nothing a hover does goes to chat.** A raising accessor is reported to `debug` and answers nil.
- The tooltip draws no *Show window* line: its shape is version 3's, unchanged but for the hints.

## The instance surface

`lib:New(d)` returns an instance. Nothing is registered until `Register` is called. Unchanged since
version 1.

| Member | Since | What it does |
|---|---|---|
| `Lb:Register()` | **L1** | Builds the one LDB object and registers it with LibDBIcon. **Idempotent** — a host may call it from `OnInitialize` and again from a login handler, and a second `LibDBIcon:Register` on a name it already holds would otherwise build a second button over the first. Returns whether the launcher is **fully** wired. |
| `Lb:IsRegistered()` | **L1** | Whether both halves are wired. `false` while only the broker object exists. |
| `Lb:Object()` | **L1** | The one LDB object, or `nil` before `Register` (or where LibDataBroker is absent). Published so a host with a live value to show can update the object's own fields, and so a suite can drive the one click both surfaces share. It is **not** an invitation to register a second one, or to replace its `OnClick` or `OnTooltipShow`. |
| `Lb:IsShown()` | **L1** | Whether the button is shown — `not minimap.hide`. Answers from the **store**, so it is still right on a host where LibDBIcon never loaded, and the Master-controls checkbox reflects what the player chose. |
| `Lb:SetShown(shown)` | **L1** | Writes `minimap.hide` and calls LibDBIcon's `Show` / `Hide`, so the button follows the checkbox immediately rather than at the next reload. Returns whether the **button** could be moved; the store is updated either way. |

`lib.STRINGS` carries the four reports (`NO_BROKER`, `NO_ICON`, `NO_MINIMAP`, `CLICK_FAILED`); the
twelve tooltip strings (`TOOLTIP_TITLE_VERSION`, `TOOLTIP_ENABLED`, `TOOLTIP_LOCKED`,
`TOOLTIP_TEST_MODE`, `TOOLTIP_YES`, `TOOLTIP_NO`, `TOOLTIP_ON`, `TOOLTIP_OFF`, `TOOLTIP_LEFT`,
`TOOLTIP_RIGHT`, `TOOLTIP_OPEN_SETTINGS` and, since version 4, `TOOLTIP_OPTIONS_MENU`); and, since
version 4, the seven menu strings (`MENU_ENABLED`, `MENU_LOCKED`, `MENU_TEST_MODE`,
`MENU_SHOW_WINDOW`, `MENU_NEEDS_ENABLE`, `MENU_GRAYED` — the `<entry> (<note>)` shape — and
`MENU_FAILED`), as a literal table, exactly as every other major's does: the library carries no
locale, and a host that wants its own words passes `d.L`. None carries a `[LibKa0s] ` tag; each
report begins with the addon's folder name, and the host's printer adds the host's own tag.

## The one click implementation

Both surfaces dispatch into it, so `launcher-§2` is satisfied on the minimap and in a broker display
**by construction** rather than by two implementations agreeing. A `RightButton` opens the menu;
every other button opens the settings panel.

It is `pcall`'d, so a raising `openSettings` or `CreateContextMenu` is reported with one line naming
the addon, the button and what raised (`CLICK_FAILED`), and the launcher keeps working. This runs
inside the client's click dispatch, where a raise is a red error box over the player's minimap with
nothing naming the addon that caused it.

## Wiring it, end to end

```lua
local addonName, NS = ...

local Launcher = LibStub and LibStub("LibKa0s-Launcher-1.0", true)

-- core/LauncherSetup.lua
if Launcher then
    NS.Launcher = Launcher:New{
        name = addonName,                                   -- the FOLDER name
        icon = "Interface\\AddOns\\" .. addonName .. "\\media\\logos\\" .. lowerName .. ".logo.128.tga",
        label = "Ka0s Bank Ledger",
        version = NS.VERSION,
        minimap = function() return NS.db.global.minimap end,
        openSettings = function() NS.OpenSettings() end,    -- left-click, always
        -- the options menu (version 4): each pair only where the addon has the state, and each
        -- toggle is the SAME handler the slash verb and the settings row use
        isEnabled = function() return not NS.IsDisabled() end,
        setEnabled = function(on) NS.SetEnabled(on) end,    -- what /bl enable|disable call
        isLocked = function() return NS.db.profile.locked end,
        toggleLock = function() NS.ToggleLock() end,        -- what /bl lock|unlock call
        isWindowShown = function() return NS.Browser:IsShown() end,
        toggleWindow = function() NS.ToggleBrowser() end,
        onTooltipShow = function(tt) tt:AddLine(NS.EntryCountLine()) end,  -- the addon's own lines
        debug = NS.Debug,
    }
    NS.Launcher:Register()
end

-- settings/Schema.lua — the row is COMPOSED, never hand-written (options-ui-§15/§16)
local rows = H.MasterControls{
    addonName    = "Bank Ledger",
    minimapPath  = "global.minimap.hide",   -- verbatim: the GLOBAL store, outside the profile prefix
    onResetAll   = NS.ResetAll,
    onResetPosition = NS.ResetPosition,
}

-- settings/OptionsSetup.lua — the single write seam does the inversion, once
function NS.SetValue(path, value)
    if path == "global.minimap.hide" then
        NS.db.global.minimap.hide = not value           -- the row says SHOWN
        if NS.Launcher then NS.Launcher:SetShown(value) end
        return
    end
    -- … every other row
end
```

**A host with no LibKa0s** (the degraded install every Ka0s addon models) gets `nil` from the
`LibStub` lookup and keeps no launcher at all. There is nothing to stub: nothing in the addon calls
back into this module except its own setup file and its write seam, both of which already guard on
`NS.Launcher`.

**Testing a host.** This repository's `MenuUtil` stand-in is `tests/mock_menu.lua`: it records
the title and each checkbox, honors `SetEnabled(false)` by refusing the click, and runs the
generator once per open, as the client does. It is repo-local, **not** in the kit, so a consumer
does not receive it; a host suite that pins its menu entries installs its own fake `MenuUtil` in
its harness, modeled on that file, and drives the menu through
`NS.Launcher:Object().OnClick(frame, "RightButton")`. With no fake installed the right click takes
the degraded path and opens the settings panel, which is itself a checkable fact.

## Compatibility

The API was additive-only through version 3. **Version 4 is the first to retire descriptor fields**
— `onClick`, `leftClickLabel`, `disabledLine` and `slash` — on the owner's ruling and the standard's
v2.67.0, and it does so without breaking a host that still passes them: they are ignored, and `New`
raises on none of them. What **changes without adopting anything**:

- **The left button opens the settings panel** on every host. A rung (a)/(b) host's `onClick` stops
  running, so its window or preview toggle is unreachable from the button until the host passes the
  matching pair for the menu.
- **The right button opens the menu** where the host passes at least one pair — which a version 3
  host with `isEnabled` alone does not, since it has no `setEnabled` yet — and otherwise still opens
  the panel. So a host that re-vendors and adopts nothing sees left and right both open the panel,
  under hints that already say `Options menu`, until it passes its pairs.
- **The disabled refusal is gone.** A consumer test that clicked left while disabled and expected
  `disabledLine` printed and nothing opened now sees the panel open and nothing printed.
- **The hints change** to `Left-click: Open settings` / `Right-click: Options menu`; a consumer test
  that pinned minor 3's hints re-pins them.

No member is added or removed, so no degradation stub moves: the member manifest lists the same
surface as version 3's.

## Vendoring

Whole-folder, exactly as every other major in this payload:

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s   # content — MUST be empty
diff -r LibKa0s <Addon>/libs/LibKa0s                       # bytes  — SHOULD be empty
```

**LibDataBroker-1.1 and LibDBIcon-1.0 are the consumer's to vendor**, under its own `libs/` and
listed in the TOC's `# Libraries` section (`toc-file-§4`). They are not part of this payload and
never will be: they are third-party libraries with their own release cadence, and bundling them
inside a folder that is itself copied into eleven addons would give each of them two copies to
reconcile. `MenuUtil` is the client's own and needs nothing vendored.
