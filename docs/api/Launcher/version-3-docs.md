# `LibKa0s-Launcher-1.0` — version 3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Launcher surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Launcher-1.0` |
| Files and minors | `Launcher.lua` minor **3** |
| Shipped in | v1.57.0 |
| Status | Superseded |
| Supersedes | [version 2](./version-2-docs.md) |
| Superseded by | [version 4](./version-4-docs.md) — left-click opens the settings panel, right-click the options menu; new `setEnabled`, `toggleLock`, `toggleTestMode`, `isWindowShown`, `toggleWindow`; `onClick`, `leftClickLabel`, `disabledLine` and `slash` retired; fixed tooltip hints |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`). **LibDataBroker-1.1** and **LibDBIcon-1.0** are OPTIONAL and are resolved with `LibStub(…, true)` at `Register` time, never at load. |
| Confirm in-game | `LibStub("LibKa0s-Launcher-1.0").MODULES` → `{ Launcher = 3 }` |

## What changed at this version

One change, from the 2026-09-24 smoke pass and the standard's v2.66.0 (`launcher-§1`, WS-10).

- **The library always draws the status tooltip.** The LDB object's `OnTooltipShow` is this
  module's, on every host, whether or not the descriptor passes a hook, and it draws one fixed shape
  in all eleven addons, **including while the addon is disabled**:

  ```
  <label>  v<version>             the label; the version only where `version` answers one
  Enabled: Yes|No                 always; green Yes, red No
  Locked: Yes|No                  only where the descriptor passes `isLocked`
  Test mode: On|Off               only where the descriptor passes `isTestMode`
  <the host's own lines>          `onTooltipShow`, called once per show, appended here
  Left-click: <leftClickLabel>    rungs (a)/(b); while disabled: `disabled — /<slash> enable`
  Left-click: Open settings       rung (c), in either state
  Right-click: Open settings      always
  ```

- **Five new optional descriptor fields**: `version`, `isLocked`, `isTestMode`, `leftClickLabel`
  and `slash`. The disabled hint's command needs no new field on a host that already passes
  `disabledLine`: the library reads `/<slash> enable` out of that line, which is the Slash
  dispatcher's own `DisabledLine()` on every host. `slash` exists for a host whose line is worded
  otherwise.
- **`onTooltipShow` changes meaning.** Through version 2 it was handed to the LDB object as the whole
  tooltip. From version 3 it is called by the library, once per show, between the status block and
  the click hints, and it draws only what is the addon's own. A host whose hook draws a title, a
  version, a status line or a click hint now draws a second copy of one; that is **anti-pattern
  #89**, and the re-vendor deletes those lines.
- **Fourteen new `lib.STRINGS` keys** (`TOOLTIP_*`), reached through `d.L` exactly as the four
  reports are.
- **Every state is read on every show, never cached**, and every accessor is `pcall`'d: a raising
  one costs its own value (a status reads as No, the label falls back to `Toggle`, the host's lines
  are skipped) and is reported to the debug seam, never to chat, since a hover repeats.

## What this major is

**The minimap button and the broker plugin, as one object registered twice** (`launcher-§1`). The
addon creates a single **LibDataBroker-1.1** object of `type = "launcher"` and hands that object to
**LibDBIcon-1.0**; LibDBIcon draws the minimap button from it, and any broker display that is
installed draws its own row from the very same object. One `OnClick`, one icon, one label, one
identity.

It is not two features, and an addon that builds a minimap button with its own click handler and a
broker object with a second one has written the same feature twice and will drift on the next
behavior change — **anti-pattern #81**. Eleven addons were about to write that wiring eleven times.

The **host** supplies what is genuinely its own: its folder name, its logo, what its left button
does, and how its settings panel opens. This module owns the rest.

## What it deliberately does NOT own

**The settings row.** The minimap button's visibility is a Master-controls row (`options-ui-§15`),
emitted by `LibKa0s-Options-1.0`'s `MasterControls` composer from its **`minimapPath`** spec key
(compose minor 7, shipped in this same release). This module registers no row and reads no settings
store.

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

`lib:New(d)` raises on a missing `name`, `icon` or `openSettings`, and — since version 2 — on an
`isEnabled` passed without a `disabledLine`. None of the first three has a defensible default: the folder name keys LibDBIcon's saved position, the icon is the
addon's face in three places, and right-click **always** opens the panel.

| Field | Since | Required | What it is |
|---|---|---|---|
| `name` | **L1** | yes | The addon's **folder name**, used for **both** registrations (`BankLedger`, `PartyFrameEnhanced`). Not cosmetic: LibDBIcon keys the button's saved position by it, so a second spelling drops the angle the player dragged the button to and labels the broker plugin with the other name. |
| `icon` | **L1** | yes | The addon's own logo — the same file `## IconTexture` names. Never a Blizzard path and never a numeric file id (**anti-pattern #82**). |
| `label` | **L1** | no | What a broker display labels the plugin. Defaults to `name`. |
| `minimap` | **L1** | yes | LibDBIcon's own table, `db.global.minimap`, **or a function answering it**. A function is the usual shape: `db.global.minimap` does not exist when the host builds its descriptor at file load, and a table captured then is one AceDB later replaces. Resolved at `Register` time. |
| `openSettings` | **L1** | yes | Opens the addon's settings panel. **Right-click always** calls it, whatever rung the addon is on; so does left-click on rung (c). |
| `onClick` | **L1** | no | The **left** click's action, and therefore which rung the addon is on. Handed the button name. |
| `isEnabled` | **L2** | no | Whether the addon is enabled, asked on every click. Where it answers false (or nil) and `onClick` is present, the **left** click is refused: `disabledLine()` is printed and `onClick` is not called. Right-click and rung (c) are never gated. |
| `disabledLine` | **L2** | with `isEnabled` | Answers the line the refusal prints. Pass the host's Slash dispatcher's own disabled line, so the minimap and `/<slash>` refuse in the same words (`slash-commands-§7`). A non-string answer prints nothing. |
| `onTooltipShow` | **L1**, meaning changed at **L3** | no | Called **once per show**, handed the tooltip, to **append** the addon's own lines between the status block and the click hints. It draws no title, version, status line or click hint (the library draws all four; a second copy is **anti-pattern #89**). A non-function is dropped; a raising one costs its lines and nothing else. Through version 2 it was handed to the LDB object as the whole tooltip. |
| `version` | **L3** | no | A string (or a function answering one) drawn after the label in the tooltip's title, `<label>  v<version>`. A leading `v` is not doubled; `nil` or `""` draws the label alone. |
| `isLocked` | **L3** | no | Where the addon has a lock (the *Lock frame* row): answers whether it is locked, and the tooltip draws `Locked: Yes\|No`. Pass the same accessor the Master-controls row reads. Absent: no line. |
| `isTestMode` | **L3** | no | Where the addon has a test mode: answers whether it is on, and the tooltip draws `Test mode: On\|Off`. Absent: no line. |
| `leftClickLabel` | **L3** | no | What the left click does on rungs (a)/(b) (`Toggle window`, `Toggle test mode`), or a function answering it on every show (a lock toggle's `Unlock frame` / `Lock frame`). Drawn as `Left-click: <label>`. Missing or empty on rung (a)/(b) reads `Toggle`; ignored on rung (c). |
| `slash` | **L3** | no | The slash command the disabled hint names (`/th` or `th`). Rarely needed: without it the command is read out of `disabledLine()` (the first `/<word> enable` in it), which the Slash dispatcher's `DisabledLine()` always contains. Where neither answers, the hint reads `Left-click: disabled`. |
| `print` | **L1** | no | Where this module's own reports go. Defaults to `DEFAULT_CHAT_FRAME`. |
| `debug` | **L1** | no | `debug(tag, message)` — the host's log seam, called with the tag `"Launcher"`. |
| `L` | **L1** | no | Locale override, keyed to `lib.STRINGS`. Read with `rawget`, so a host table that answers an unknown key **with the key** (which every Ka0s locale table does — **anti-pattern #2**) falls through to the library's English rather than printing `NO_BROKER` at the player. |

## Which rung, and what to pass

`launcher-§2`'s three rungs, first match wins. The rung is expressed by the **presence** of
`onClick` rather than by a flag, so a host cannot declare a rung it did not implement.

| Rung | The addon has | Pass | Left-click does |
|---|---|---|---|
| **(a)** | a **primary window** — a browser, a ledger, a meter window, a group popup | `onClick = <toggle that window>` | toggles it |
| **(b)** | a **preview switch** — a test mode, or lock/unlock where unlocking *is* the preview | `onClick = <toggle that switch>` | toggles it |
| **(c)** | neither | **nothing** | opens the settings panel |

- The switch on rung (b) is the addon's **existing** one. The launcher drives the same state the
  *Test mode* or *Lock frame* checkbox drives, through the same seam, and never holds a copy of it.
- **Right-click always opens the settings panel**, which is what lets (a) and (b) spend the left
  button on something better. There is **no setting** that reassigns either button.
- Which rung each rostered addon sits on is recorded in the standard's `ADDONS.md`, one column on
  the roster, so an audit reads it rather than re-deriving it.
- An addon on rung (a) or (b) whose left-click opens the settings panel has not chosen a different
  design — it has skipped the rule, since the panel is already on the right button. That, and a
  right-click doing anything else, is **anti-pattern #81**.

## The status tooltip

Drawn by `drawTooltip`, which is the LDB object's `OnTooltipShow` on every host (version 3). LibDBIcon
calls it on hover with `GameTooltip`, a broker display with its own tooltip; an argument with no
`AddLine` is left alone.

| Line | Drawn when | Reads |
|---|---|---|
| `<label>  v<version>` | always | `label` (else `name`), `version` |
| `Enabled: Yes\|No` | always | `isEnabled()`; a host with no `isEnabled` is always Yes, as its clicks are ungated. Green Yes, red No. |
| `Locked: Yes\|No` | `isLocked` passed | `isLocked()`, green Yes, red No |
| `Test mode: On\|Off` | `isTestMode` passed | `isTestMode()`, green On, red Off |
| the host's lines | `onTooltipShow` passed | whatever it adds, once |
| `Left-click: …` | always | rung (c): `Open settings`. Rungs (a)/(b): `leftClickLabel` while enabled; `disabled — /<slash> enable` while disabled. |
| `Right-click: Open settings` | always | nothing; the right button never changes |

- **Never cached.** Every accessor is asked on every show, so the tooltip reads what the settings
  panel reads the moment it changes. That is also why each is a function rather than a value.
- **The only color is the status value's**, green for Yes/On and red for No/Off, wrapped by the code
  around the localized word; no `lib.STRINGS` value carries an escape, and the title carries none.
- **Nothing a hover does goes to chat.** A raising accessor is reported to `debug` and answers nil.
- **The disabled hint mirrors the click.** While `isEnabled()` answers false, a rung (a)/(b) left
  click prints `disabledLine()` and does nothing (version 2's gate), and the hint says so before the
  click. Rung (c) and the right button are not gated, and their hints do not change.

## The instance surface

`lib:New(d)` returns an instance. Nothing is registered until `Register` is called.

| Member | Since | What it does |
|---|---|---|
| `Lb:Register()` | **L1** | Builds the one LDB object and registers it with LibDBIcon. **Idempotent** — a host may call it from `OnInitialize` and again from a login handler, and a second `LibDBIcon:Register` on a name it already holds would otherwise build a second button over the first. Returns whether the launcher is **fully** wired. |
| `Lb:IsRegistered()` | **L1** | Whether both halves are wired. `false` while only the broker object exists. |
| `Lb:Object()` | **L1** | The one LDB object, or `nil` before `Register` (or where LibDataBroker is absent). Published so a host with a live value to show can update the object's own fields. It is **not** an invitation to register a second one. |
| `Lb:IsShown()` | **L1** | Whether the button is shown — `not minimap.hide`. Answers from the **store**, so it is still right on a host where LibDBIcon never loaded, and the Master-controls checkbox reflects what the player chose. |
| `Lb:SetShown(shown)` | **L1** | Writes `minimap.hide` and calls LibDBIcon's `Show` / `Hide`, so the button follows the checkbox immediately rather than at the next reload. Returns whether the **button** could be moved; the store is updated either way. |

`lib.STRINGS` carries the four reports (`NO_BROKER`, `NO_ICON`, `NO_MINIMAP`, `CLICK_FAILED`) and,
since version 3, the fourteen tooltip strings (`TOOLTIP_TITLE_VERSION`, `TOOLTIP_ENABLED`,
`TOOLTIP_LOCKED`, `TOOLTIP_TEST_MODE`, `TOOLTIP_YES`, `TOOLTIP_NO`, `TOOLTIP_ON`, `TOOLTIP_OFF`,
`TOOLTIP_LEFT`, `TOOLTIP_RIGHT`, `TOOLTIP_OPEN_SETTINGS`, `TOOLTIP_LEFT_DEFAULT`,
`TOOLTIP_DISABLED_HINT`, `TOOLTIP_DISABLED_BARE`), as a literal table, exactly as every other major's does: the library carries no locale, and a host that
wants its own words passes `d.L`. Since version 2 none carries a `[LibKa0s] ` tag; each begins with
the addon's folder name, and the host's printer adds the host's own tag.

## The one click implementation

Both surfaces dispatch into it, so `launcher-§2` is satisfied on the minimap and in a broker display
**by construction** rather than by two implementations agreeing.

**The disabled gate sits inside it** (version 2). A left click on a host that passed `onClick` and
`isEnabled` asks `isEnabled()` first; a false answer prints `disabledLine()` and stops. The right
button and a rung (c) left click go straight to `openSettings`.

It is `pcall`'d, the gate included, so a raising `isEnabled` or `disabledLine` is reported the same
way a raising `onClick` is. This runs inside the client's click dispatch, where a raise is a red error box over
the player's minimap with nothing naming the addon that caused it; one line names the addon, the
button and what raised, and the launcher keeps working.

## Wiring it, end to end

```lua
local addonName, NS = ...

local Launcher = LibStub and LibStub("LibKa0s-Launcher-1.0", true)

-- core/LauncherSetup.lua
if Launcher then
    NS.Launcher = Launcher:New{
        name = addonName,                                   -- the FOLDER name
        icon = "Interface\\AddOns\\" .. addonName .. "\\media\\logos\\" .. lowerName .. ".logo.128.tga",
        minimap = function() return NS.db.global.minimap end,
        openSettings = function() NS.OpenSettings() end,    -- right-click, always
        onClick = function() NS.ToggleBrowser() end,        -- rung (a); omit entirely for rung (c)
        isEnabled = function() return not NS.IsDisabled() end,  -- the left click refuses while disabled
        disabledLine = function() return NS.cli:DisabledLine() end,  -- the dispatcher's own words
        -- the status tooltip (version 3); the library draws it, these only answer its questions
        label = "Ka0s Bank Ledger",
        version = NS.VERSION,
        leftClickLabel = "Toggle window",
        isLocked = function() return NS.db.profile.locked end,       -- only where there is a lock
        onTooltipShow = function(tt) tt:AddLine(NS.EntryCountLine()) end,  -- the addon's own lines
        debug = NS.Debug,
    }
    NS.Launcher:Register()
end

-- settings/Schema.lua — the row is COMPOSED, never hand-written (options-ui-§15/§16)
local rows = H.MasterControls{
    addonName    = "Bank Ledger",
    minimapPath  = "global.minimap.hide",   -- verbatim: the GLOBAL store, outside the profile prefix
    testModePath = "state.testMode",        -- where the addon has one
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
`LibStub` lookup and keeps no launcher at all. There is nothing to stub: unlike the Options surface,
nothing in the addon calls back into this module except its own setup file and its write seam, both
of which already guard on `NS.Launcher`.

## Compatibility

The API is **additive-only**: a member or descriptor field may be added in a later minor, never
removed or repurposed. Version 3 adds five optional descriptor fields and fourteen `lib.STRINGS` keys,
and no member. **It changes what a version 2 host sees without adopting anything**, and that is the
point of the release: every host's button now answers a hover with the status tooltip, including a
host that passed no `onTooltipShow`. A host that did pass one keeps its lines, now drawn inside the
library's block rather than as the whole tooltip, so a hook that drew its own title or click hints
draws them twice until the host deletes them. A consumer test that called the object's
`OnTooltipShow` and expected only its own lines has to expect the library's around them.

## Vendoring

Whole-folder, exactly as every other major in this payload:

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s   # content — MUST be empty
diff -r LibKa0s <Addon>/libs/LibKa0s                       # bytes  — SHOULD be empty
```

`Launcher.lua` is a new entry in `LibKa0s.xml`, so a consumer whose test harness derives its load
list from that XML picks it up with no edit; a consumer that re-types the list adds one row.

**LibDataBroker-1.1 and LibDBIcon-1.0 are the consumer's to vendor**, under its own `libs/` and
listed in the TOC's `# Libraries` section (`toc-file-§4`). They are not part of this payload and
never will be: they are third-party libraries with their own release cadence, and bundling them
inside a folder that is itself copied into eleven addons would give each of them two copies to
reconcile.

## Moving to version 4

Something changes whether or not you adopt: from version 4 the left button opens the settings panel
on every host, in either state, and your `onClick` no longer runs; the right button opens the
client's context menu wherever the descriptor supplies at least one accessor-and-toggle pair, and
otherwise still opens the panel; the tooltip's hints read `Left-click: Open settings` and
`Right-click: Options menu`. The disabled left-click refusal is gone, so `disabledLine` is never
printed.

To adopt (`launcher-§2`, standard v2.67.0): pass `setEnabled` beside `isEnabled` (the path
`/<slash> enable` / `disable` write); `toggleLock` beside `isLocked` where the addon has a lock;
`toggleTestMode` beside `isTestMode` where it has a test mode; and `isWindowShown` with
`toggleWindow` where it has a primary window. Each toggle is the addon's **own** handler, the one its
slash verb and settings row already use, never a copy. Then delete `onClick`, `leftClickLabel`,
`disabledLine` and `slash` from the descriptor: they are ignored, and a host still passing them is
carrying dead configuration. Any test that pinned version 3's click hints, the left click's action
or the disabled refusal re-pins to version 4's behavior.
