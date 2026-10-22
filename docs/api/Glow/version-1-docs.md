# `LibKa0s-Glow-1.0` — version 1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Glow surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Glow-1.0` |
| File | `Glow.lua` minor **1** |
| Shipped in | v1.75.0 |
| Status | **Current** |
| Supersedes | — (first version) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` ≥ 1 (no Core member is called) |
| Optional at call time | `LibCustomGlow-1.0`, no floor: resolved with `LibStub("LibCustomGlow-1.0", true)` on every call |
| Confirm in-game | `LibStub("LibKa0s-Glow-1.0").MODULES` → `{ Glow = 1 }` |

## What this major is

**The stateless LibCustomGlow-1.0 driver.** One of four glow styles and its knob values, mapped to
LibCustomGlow-1.0's positional arguments, with its traps handled. Nothing here holds state: no
lifecycle, no repaint gate, no defaults.

Three hosts (DropWatcher, QuickComms, KickCD) mapped the same knobs to the same positional arguments,
and each had to find the same two traps on its own: a `pixelLength` of 0 draws zero-length lines,
and a `nil` border flag draws the border. This file is that mapping, once ([#56](https://github.com/tusharsaxena/LibKa0s/issues/56)).

Depends on LibStub and `LibKa0s-Core-1.0` (minor 1 or newer), and on no addon framework. **No Core
member is called**: the gate is there so that a host holding a partial payload gets every module
absent rather than a working half.

**LibCustomGlow-1.0 is resolved at every call**, never captured at load, and each of its members is
presence-checked (`type(fn) == "function"`) before it is called. The payload cannot carry a
consumer-vendored library (library-stack-§6/§7), so there is nothing to floor on: a host without it,
or with a copy older than ProcGlow, gets `false`, not an error inside the library. Call-time
resolution is also what lets a host's headless suite register its fake LibCustomGlow after load.

## Members

Read straight off the LibStub table. Both functions are dot-called (`Glow.Start(...)`).

| Name | Since | Meaning |
|---|---|---|
| `Start(frame, style, knobs, key, frameLevel)` | 1 | Starts `style`'s glow on `frame`. Returns `true` when it called LibCustomGlow's `_Start` for that style, `false` when the frame is nil, the style is unknown, LibCustomGlow is absent or the style's `_Start` is missing. Never stops anything first. |
| `Stop(frame, style, key)` | 1 | Stops `style`'s glow on `frame`; with `style == nil`, all four in the order button, pixel, autocast, proc. An unknown style string, a nil frame or an absent LibCustomGlow is a no-op; a missing `_Stop` is skipped. Returns nothing. |
| `MAJOR` · `MINOR` | 1 | `"LibKa0s-Glow-1.0"` and the live minor. |
| `MODULES` | 1 | `{ Glow = <minor> }`: the live minor, and the value that picks this document. |

### The arguments

- `frame`: the frame the effect is drawn around. `nil` makes `Start` answer `false` and `Stop` do
  nothing. LibCustomGlow's `_Start` functions return on a nil frame, but not all of its `_Stop`
  functions do, so the driver guards both the same way.
- `style`: one of **`"button"`, `"proc"`, `"pixel"`, `"autocast"`**, exactly these lowercase strings.
  The vocabulary is closed: no aliases, no case folding, and anything else is a quiet `false`
  (`Start`) or no-op (`Stop`). `"button"` is LibCustomGlow's *Action Button Glow*, `"proc"` its
  *Proc Glow*, `"pixel"` its *Pixel Glow*, `"autocast"` its *Autocast Shine*.
- `knobs`: a table, or `nil`, which reads as empty (a shared constant, no allocation); any other type
  also reads as empty. It carries `color` (an `{r, g, b, a}` array) and the thirteen knobs named in
  the mapping below. Fields it does not name are ignored, so a host passes its whole config table.
- `key`: the caller's identity string, passed through unchanged. `nil` is LibCustomGlow's shared
  empty key `""`, so **pass your addon's own key**. The `button` style takes no key.
- `frameLevel`: a number or `nil` (LibCustomGlow uses 8), relative to `frame`. It is a positional
  argument, not a knob, because it says where the host stacks the effect, not what a player chose.

**No defaults.** A `nil` knob reaches LibCustomGlow as `nil`, so LibCustomGlow's own value applies.
A numeric knob that is not a number becomes `nil`. The only coercions are the two traps below.

## The mapping

`num(v)` is `v` when `type(v) == "number"`, otherwise `nil`. `len(v)` is `v` when it is a number
greater than 0, otherwise `nil`.

| Style | LibCustomGlow call | Arguments, in order |
|---|---|---|
| `pixel` | `PixelGlow_Start` | `frame, knobs.color, num(pixelLines), num(pixelFrequency), len(pixelLength), num(pixelThickness), num(xOffset), num(yOffset), pixelBorder ~= false, key, frameLevel` (11) |
| `autocast` | `AutoCastGlow_Start` | `frame, knobs.color, num(autocastParticles), num(autocastFrequency), num(autocastScale), num(xOffset), num(yOffset), key, frameLevel` (9) |
| `button` | `ButtonGlow_Start` | `frame, knobs.color, num(buttonFrequency), frameLevel` (4, no key) |
| `proc` | `ProcGlow_Start` | `frame, { color = knobs.color, startAnim = procStartAnim ~= false, duration = num(procDuration), xOffset = num(xOffset), yOffset = num(yOffset), key = key, frameLevel = frameLevel }`, a **fresh table per call** |

| Style | Stop call |
|---|---|
| `button` | `ButtonGlow_Stop(frame)`, no key |
| `pixel` | `PixelGlow_Stop(frame, key)` |
| `autocast` | `AutoCastGlow_Stop(frame, key)` |
| `proc` | `ProcGlow_Stop(frame, key)` |

The fourteen knob names are `color`, `pixelLines`, `pixelFrequency`, `pixelLength`, `pixelThickness`,
`pixelBorder`, `autocastParticles`, `autocastFrequency`, `autocastScale`, `buttonFrequency`,
`procDuration`, `procStartAnim`, `xOffset` and `yOffset`. A host that stores PascalCase leaves maps
them by lower-casing the first letter (`XOffset` → `xOffset`).

## The traps

1. **`pixelLength` 0 means automatic.** LibCustomGlow computes a length only for `nil`
   (`length = length or floor(...)`); a 0 would draw zero-length lines. The driver passes a number
   greater than 0 through and sends 0, negatives and non-numbers as `nil`.
2. **`pixelBorder` draws for anything but `false`.** LibCustomGlow tests `not (border == false)`, so
   `nil` draws the dark border. The driver passes `pixelBorder ~= false`, a real boolean with
   LibCustomGlow's own nil meaning: a host that wants no border passes `false`. The same rule applies
   to `procStartAnim`, whose LibCustomGlow default is `true`.
3. **The proc options table is fresh.** `ProcGlow_Start` calls `setmetatable` on whatever it is
   handed. The driver never hands over the caller's `knobs` and never reuses a scratch table, so a
   host's config table is not given a metatable and a recorded call in a host's suite is not
   overwritten by the next one.
4. **A color is kept by reference.** The button style stores `color` on its glow frame and, on a
   restart that reuses the frame, divides the old alpha by it. A host **must not mutate** a color
   array after handing it over: hand over a fresh array, or one that never changes.
5. **The `button` style has no key.** Each frame has one button glow. Two keyed callers on one frame
   cannot both use `button`, and `Stop(frame, nil, key)` stops any button glow on the frame, whoever
   started it. **Use stop-all only on a frame you own.**
6. **`ButtonGlow_Stop` on a visible frame animates out** and releases later; a restart inside that
   window reuses the glow. This is LibCustomGlow's behavior, transparent to the driver, and recorded
   so nobody "fixes" it.
7. **Combat.** LibCustomGlow's frames are plain children, so the driver makes no protected call.

## Adopting it

Each adopter gets a seam, `core/GlowSetup.lua`, published as `NS.GlowLib` (`NS.Glow` is already the
host's own glow module in the first adopters):

```lua
local _, NS = ...
-- core/GlowSetup.lua: the LibKa0s-Glow-1.0 seam (library-stack-§7). Absent major: no glow, the
-- same thing an absent LibCustomGlow-1.0 already means here. Never a local copy of the mapping.
local G = LibStub and LibStub("LibKa0s-Glow-1.0", true)
NS.GlowLib = G or {
    Start = function() return false end,
    Stop  = function() end,
}
```

The stub answers with the live surface and nothing more. It must **not** carry a host START/STOP
table: that would be the mapping forked back into the host. Pin it with a parity case in the host's
`tests/test_surface_parity.lua`:

```lua
T.assertSurfaceParity(degraded.GlowLib, "LibKa0s-Glow-1.0")
```

A host's start then reads `NS.GlowLib.Start(frame, cfg.type, cfg, KEY, FRAME_LEVEL)`, and its stop
`NS.GlowLib.Stop(frame, recordedStyle, KEY)`. Pass the style to `Stop` only when it is non-nil:
`nil` means stop-all. Switching styles is the host's job (stop the old, then start the new), as is
every gate deciding whether to start at all.

**Every host keeps vendoring `LibCustomGlow-1.0`** and keeps it in `## OptionalDeps`; the driver only
resolves it. Adoption is required of no addon.

## What is not here

| Not in Glow-1.0 | Stays in | Re-check trigger |
|---|---|---|
| Defaults for any knob | each host's profile (savedvariables-§2) | never: the owner's decision |
| Knob ranges, a knob catalog | each host's schema rows | a fourth host copies the knob table, or one host edits a range and the others do not |
| A `STYLES` list | each host's localized dropdown | a host that needs the list without its labels |
| Lifecycle: the unchanged-repaint gate, Apply/Release/StopFree | the hosts' glow modules | the three hosts' gates converge (they differ today) |
| Proc burst spend (writing `startAnim = false` into LibCustomGlow's proc frame) | DropWatcher and QuickComms | never in the library: it writes LibCustomGlow's internal state |
| Triggers (ready, casting, hover, send, trade and so on) | the hosts | — |
| Class-color resolution | the hosts (options-ui-§17) | — |
| Stop-before-start | the hosts | — |
| An `O.GlowGroup` settings composer | the hosts' settings | rejected in #56 |
| `Available()` | `LibStub("LibCustomGlow-1.0", true)` in a host that needs to know | — |
| Clamping | KickCD's own knob read | — |

## Vendoring

Whole-folder, exactly as every other major in this payload:

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
diff -r --strip-trailing-cr LibKa0s <Addon>/libs/LibKa0s   # content — MUST be empty
diff -r LibKa0s <Addon>/libs/LibKa0s                       # bytes  — SHOULD be empty
```

`Glow.lua` is an entry in `LibKa0s.xml`, after `Item.lua`, so the whole-folder copy brings it in with
no load-list change in the host.
