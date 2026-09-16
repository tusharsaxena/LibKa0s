# `LibKa0s-Launcher-1.0` — version 1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Launcher surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Launcher-1.0` |
| Files and minors | `Launcher.lua` minor **1** |
| Shipped in | v1.39.0 |
| Status | **Current** |
| Supersedes | — (first version) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`). **LibDataBroker-1.1** and **LibDBIcon-1.0** are OPTIONAL and are resolved with `LibStub(…, true)` at `Register` time, never at load. |
| Confirm in-game | `LibStub("LibKa0s-Launcher-1.0").MODULES` → `{ Launcher = 1 }` |

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
`descriptor.print` or the chat frame.

## The descriptor

`lib:New(d)` raises on a missing `name`, `icon` or `openSettings`, and on nothing else. None of the
three has a defensible default: the folder name keys LibDBIcon's saved position, the icon is the
addon's face in three places, and right-click **always** opens the panel.

| Field | Since | Required | What it is |
|---|---|---|---|
| `name` | **L1** | yes | The addon's **folder name**, used for **both** registrations (`BankLedger`, `PartyFrameEnhanced`). Not cosmetic: LibDBIcon keys the button's saved position by it, so a second spelling drops the angle the player dragged the button to and labels the broker plugin with the other name. |
| `icon` | **L1** | yes | The addon's own logo — the same file `## IconTexture` names. Never a Blizzard path and never a numeric file id (**anti-pattern #82**). |
| `label` | **L1** | no | What a broker display labels the plugin. Defaults to `name`. |
| `minimap` | **L1** | yes | LibDBIcon's own table, `db.global.minimap`, **or a function answering it**. A function is the usual shape: `db.global.minimap` does not exist when the host builds its descriptor at file load, and a table captured then is one AceDB later replaces. Resolved at `Register` time. |
| `openSettings` | **L1** | yes | Opens the addon's settings panel. **Right-click always** calls it, whatever rung the addon is on; so does left-click on rung (c). |
| `onClick` | **L1** | no | The **left** click's action, and therefore which rung the addon is on. Handed the button name. |
| `onTooltipShow` | **L1** | no | Handed straight to the LDB object. Its contents are the addon's own and nothing here binds them. A non-function is dropped rather than passed on. |
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

## The instance surface

`lib:New(d)` returns an instance. Nothing is registered until `Register` is called.

| Member | Since | What it does |
|---|---|---|
| `Lb:Register()` | **L1** | Builds the one LDB object and registers it with LibDBIcon. **Idempotent** — a host may call it from `OnInitialize` and again from a login handler, and a second `LibDBIcon:Register` on a name it already holds would otherwise build a second button over the first. Returns whether the launcher is **fully** wired. |
| `Lb:IsRegistered()` | **L1** | Whether both halves are wired. `false` while only the broker object exists. |
| `Lb:Object()` | **L1** | The one LDB object, or `nil` before `Register` (or where LibDataBroker is absent). Published so a host with a live value to show can update the object's own fields. It is **not** an invitation to register a second one. |
| `Lb:IsShown()` | **L1** | Whether the button is shown — `not minimap.hide`. Answers from the **store**, so it is still right on a host where LibDBIcon never loaded, and the Master-controls checkbox reflects what the player chose. |
| `Lb:SetShown(shown)` | **L1** | Writes `minimap.hide` and calls LibDBIcon's `Show` / `Hide`, so the button follows the checkbox immediately rather than at the next reload. Returns whether the **button** could be moved; the store is updated either way. |

`lib.STRINGS` carries the four reports (`NO_BROKER`, `NO_ICON`, `NO_MINIMAP`, `CLICK_FAILED`), as a
literal table, exactly as every other major's does: the library carries no locale, and a host that
wants its own words passes `d.L`.

## The one click implementation

Both surfaces dispatch into it, so `launcher-§2` is satisfied on the minimap and in a broker display
**by construction** rather than by two implementations agreeing.

It is `pcall`'d. This runs inside the client's click dispatch, where a raise is a red error box over
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
removed or repurposed. This is minor 1 and there is nothing to be compatible with yet.

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
