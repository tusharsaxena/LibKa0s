# `LibKa0s-Callout-1.0` — version 1.1

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Callout surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Callout-1.0` |
| Files and minors | `Callout.lua` minor **1** · `CalloutSettings.lua` minor **1** (paired on `Callout.lua`'s minor) |
| Shipped in | v1.96.0 |
| Status | **Current** |
| Supersedes | — (the first version of this major) |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`, no member called) |
| Optional at call time | the host's `LibKa0s-Options-1.0` instance, handed to `BuildSettings` (`EnsureScroll`, `TextRow`, `InlineButtonPair`, `RenderRows`, and the `Ka0sMedia_Font` picker through its row), `LibKa0s-Media-1.0` (`Font`, `FONTS`, the bundled faces), `LibKa0s-Skin-1.0` (`IsOwner`, `For(owner).GetFont`, the "Skin font" choice), `LibKa0s-Widgets-1.0` (`DragHandle`, the strip over an unlocked frame), `LibSharedMedia-3.0` (`Fetch`, `List`), `PlaySoundFile`, `C_VoiceChat.GetTtsVoices` and `C_VoiceChat.SpeakText`, each presence-checked |
| Confirm in-game | `LibStub("LibKa0s-Callout-1.0").MODULES` → `{ Callout = 1, CalloutSettings = 1 }` |

## What changed at this version: the settings section (`CalloutSettings.lua` 1, plan row L4)

The version is new with its major (v1.96.0 ships 1.1, never 1 alone). `CalloutSettings.lua` adds
the settings section to every instance: `BuildSettings`, `SettingsRows`, `SettingsTabs`, `Preview`
and `TestCountdown`, with the words in `SETTINGS_STRINGS` and the tab keys in `SETTINGS_TABS`.
`Callout.lua` gains, at its minor 1 and before any release, the `muted` setting (a stock key shown
without its voice, the Texts tab's per-key mute) and `Look()`, the look the frame draws, which the
preview reads. See [The settings section](#the-settings-section).

## What changed at version 1: the major is new

The owner's decisions of 2026-11-13 (`docs/superpowers/plans/2026-11-13-callout.md`, adoption issue
[LibKa0s#85](https://github.com/tusharsaxena/LibKa0s/issues/85)): a big center-screen call-out for
countdowns of up to 20 seconds and for stock and custom texts, with a customizable look, AnimationGroup
animations, bundled voice packs or the client's text to speech. Ka0s Combat Trail's race countdown is
its first consumer and is replaced by it whole.

## What this major is

**One frame in the middle of the screen that says one thing loudly.** A countdown's numbers, a "GO!",
a "MOVE", a host's own text. The instance owns the frame, its font, color, glow and animation, its
saved position and its voice; the host owns when it speaks and what a custom text says. Settings
live in the host's own profile table, never in SavedVariables of the library's.

### Timing

`Countdown{ endsAt = <a GetTime() value> }` shows `math.ceil(endsAt - GetTime())`, read in an
OnUpdate while the countdown runs. The number flips on the frame the true remaining time crosses the
integer, so a host that draws its own clock off the same `endsAt` always agrees with it. There is no
timer chain and nothing to drift. The OnUpdate sits on a clock frame with no parent (a hidden UI does
not stop a countdown's `onDone`) and is armed only while a countdown runs or a call-out waits out its
hold; it is cleared the moment neither is true. Animations are AnimationGroups the client runs.

### Sound

The `voice` setting is a key of `PACKS` (a folder of `LINES` under `media/sounds/callout/`), `"tts"`
or `"off"`. A pack line plays with `PlaySoundFile(path, channel)`; a file the consumer pruned away
(`PlaySoundFile` answers false) is silence, reported once per path through `d.debug`. Text to speech
is `C_VoiceChat.SpeakText(voiceID, text, rate, volume, true)` with the player's `ttsVoice` when the
client still lists it in `C_VoiceChat.GetTtsVoices()`, else the client's first voice. Both calls have
the same signature on Retail and WoW Forever (Blizzard's generated API documentation, `live` and
`forever` branches, read 2026-11-13), so no Compat ladder is involved. Numbers above `speakFrom` are
not spoken. `voice = "off"` silences every call-out, a custom sound file included.

## Members

Read straight off the LibStub table.

| Name | Since | Meaning |
|---|---|---|
| `MAJOR`, `MINOR` | 1 | `"LibKa0s-Callout-1.0"`, `1` |
| `MODULES` | 1 | `{ Callout = 1, CalloutSettings = 1 }` (the second from 1.1) |
| `New(d)` | 1 | A new instance (below). Raises without `d.db` |
| `DEFAULTS` | 1 | The settings table a host seeds its profile with (below). Never mutate it |
| `SETTINGS` | 1 | The setting keys `Get`/`Set` take, sorted |
| `PACKS` | 1 | `{ { key, folder, name }, ... }`: the bundled voice packs, in settings order: `female` (folder `female-kathleen`, Piper kathleen) and `male` (folder `male-joe`, Piper joe), each with its `CREDITS.md` and license texts |
| `TTS`, `OFF` | 1 | `"tts"`, `"off"`: the two `voice` values that are not a pack |
| `KINDS` | 1 | `number`, `info`, `go`, `stop`, `warn`, `error` |
| `STOCK` | 1 | key → `{ text, kind, say }` for the 23 stock call-outs |
| `STOCK_ORDER` | 1 | The stock keys in display order |
| `LINES` | 1 | Every file a pack carries, without the extension: each stock key lower-cased, then `1` .. `20` (43) |
| `SOUND_EXT` | 1 | `".ogg"` |
| `MAX_FROM` | 1 | `20`: the longest countdown |
| `FONT_SKIN`, `FONT_GAME`, `FONT_DEFAULT` | 1 | `"Skin font"`, `"Game default"`, `"Ka0s Oxanium Bold"` |
| `OUTLINES` | 1 | `NONE`, `OUTLINE`, `THICKOUTLINE`, `MONOCHROME` |
| `GLOWS` | 1 | `off`, `soft`, `strong` |
| `ANIMS` | 1 | `slam`, `pulse`, `glow`, `blink`, `shake`, `none` |
| `CHANNELS` | 1 | `Master`, `SFX`, `Dialog` |
| `SIZE_MIN`, `SIZE_MAX` | 1 | `32`, `200` |
| `STRATA` | 1 | `"HIGH"` (frame-layering's alert tier) |
| `WIDTH` | 1 | `900`: the frame's width; its height is 1.5 × the size |
| `SETTINGS_STRINGS` | 1.1 | Every word the settings section shows, US English, keyed; a host overrides any through `opts.L` |
| `SETTINGS_TABS` | 1.1 | `look`, `sound`, `texts`: the section's tabs, in order |

The stock keys: `READY`, `GO`, `START`, `STOP`, `WARNING`, `ERROR`, `DONE`, `FINISH`, `NEW_BEST`,
`PAUSE`, `RESUME`, `CANCELED`, `PULL`, `INTERRUPT`, `MOVE`, `DEFENSIVE`, `REBUFF`, `EXPIRING`,
`UPGRADE`, `TIME_UP`, `VICTORY`, `FAILED`, `LAST_TEN`.

## The descriptor

| Field | Required | Meaning |
|---|---|---|
| `db` | yes | The host's settings table for this instance, or a getter answering it (read at every call, so a profile switch is followed; call `Apply` after one) |
| `name` | no | The frame's global name |
| `addon` | no | The consumer's addon folder name: where the voice packs and the bundled fonts are found |
| `vendorPath` | no | Where the payload sits inside the addon; `libs\LibKa0s` by default |
| `soundsBase` | no | The folder holding the packs, overriding the one `addon` implies |
| `skin` | no | A registered skin owner: the "Skin font" face and the drag strip's colors |
| `label` | no | The drag strip's text; `"Call-out"` by default |
| `debug` | no | `debug(tag, msg)`, called under pcall with tag `"CALLOUT"` |

## The settings

`Get(key)` answers the stored value, or the default when none is stored or the stored one is not
valid; an invalid stored value is never rewritten. `Set(key, value)` validates, writes and applies;
nil clears back to the default.

| Key | Default | Valid |
|---|---|---|
| `font` | `"Ka0s Oxanium Bold"` | any non-empty name: a LibSharedMedia face, a LibKa0s-Media-1.0 face, `"Skin font"` or `"Game default"`; a name nothing resolves falls back to the default face, then the game's |
| `size` | `96` | 32 – 200 |
| `outline` | `"THICKOUTLINE"` | `OUTLINES` |
| `shadow`, `shadowX`, `shadowY` | `true`, `2`, `-2` | a boolean; −20 – 20 |
| `colors` | per kind (below) | through `GetColor` / `SetColor` only |
| `glow` | `"soft"` | `GLOWS`: a halo of the text in its kind's color behind it |
| `anim` | `"slam"` | `ANIMS` |
| `hold` | `1.5` | 0.2 – 10 seconds before a call-out fades |
| `point` | `{ "CENTER", "CENTER", 0, 180 }` | `{ point, relativePoint, x, y }` in UIParent's units; written by a drag |
| `voice` | `"female"` | a `PACKS` key, `"tts"` or `"off"` |
| `channel` | `"Master"` | `CHANNELS` |
| `speakFrom` | `5` | an integer 1 – 20: higher numbers are shown, not spoken |
| `ttsVoice` | `false` | false (the client's first voice) or a `voiceID` |
| `ttsRate`, `ttsVolume` | `0`, `100` | −10 – 10; 0 – 100 |
| `texts` | `{}` | stock key → the player's own text for it |
| `muted` | `{}` | stock key → `true`: that key shows without its voice (from 1.1) |

Default colors: `number` white, `info` (0.35, 0.75, 1), `go` (0.3, 1, 0.45), `stop` (1, 0.35, 0.3),
`warn` (1, 0.78, 0.2), `error` (1, 0.2, 0.25).

## The instance

| Method | Meaning |
|---|---|
| `Countdown(spec)` | `spec = { endsAt, from, finish, onTick, onDone }`. `from` is clamped to 1 – 20 (20 when nil); nothing shows while `ceil(endsAt - now)` is above it. At zero `finish` shows (a stock key, a number, a custom spec, or `false` for none; `"GO"` when nil) and `onDone()` is called once. `onTick(n)` is called as each number shows. Both run under pcall. A running countdown is replaced. Answers false while suspended or for a non-number `endsAt` |
| `Cancel()` | Stops the countdown with no finish and no `onDone`, takes the call-out down. Answers whether one ran |
| `Running()` | `running, n`: whether a countdown runs and the number it shows (nil before its first) |
| `Show(what, opts)` | `what` is a stock key, a number 1 – 20 (or its string) or a custom `{ text, kind, sound, voice = false, hold, anim, key }`. `opts` may carry `hold`, `anim`, `voice = false`. It fades after its hold. Answers false for nothing to show, or while suspended |
| `Hide()` | Takes the call-out down now; a running countdown shows its next number |
| `Suspend()` / `Resume()` / `Suspended()` | The stand-down: cancels, hides, locks, and refuses Show and Countdown until Resume |
| `Get(key)` / `Set(key, value)` | The settings, above |
| `GetColor(kind)` / `SetColor(kind, r, g, b)` | A kind's color; `SetColor(kind)` with no color clears it |
| `Apply()` | Re-reads every setting onto the frame |
| `SetLocked(locked)` / `Locked()` | Unlocked, the frame takes the mouse, shows a sample (`READY`, silent) and the drag strip, and a drag writes `point`. Locked (the default, and not saved) it is mouse-transparent |
| `ResetPosition()` | Clears `point` |
| `Voices()` | The `voice` choices: `{ key, name }` for each pack, then `tts`, then `off` |
| `TtsVoices()` | The client's voices, `{ voiceID, name }` each; empty without `C_VoiceChat` |
| `Frame()` | The frame, built on first use |
| `Stats()` | `built`, `shown`, `running`, `number`, `endsAt`, `key`, `text`, `kind`, `awake` (the OnUpdate is armed), `suspended`, `locked`, `logged` |
| `Look()` | From 1.1: `{ font, size, flags, shadow, shadowX, shadowY, glow }`, the look the frame draws, the font resolved to a file path. A fresh table |
| `Preview(what)` | From 1.1: `Show(what, { voice = false })`, `READY` by default: the look on the real call-out, silent |
| `TestCountdown(from)` | From 1.1: `Countdown{ endsAt = GetTime() + from, from = from }`, `from` 5 by default |
| `SettingsRows(opts)` | From 1.1: the section's rows (below); `opts.tab` one tab's, `opts.L` the words, `opts.plain` without the text boxes |
| `SettingsTabs(opts)` | From 1.1: three host tab entries for `RenderTabbedSchema`'s `opts.tabs` (below) |
| `BuildSettings(parent, opts)` | From 1.1: builds the section into `parent` and answers its view (below) |

## The settings section

`CalloutSettings.lua`, from 1.1. A consumer drops it into its own panel; it owns no page and no
SavedVariables, and every write is the instance's `Set` / `SetColor` into the host's `db`.

**With the host's Options instance** (`opts.options`), `parent` is a page ctx (what `CreatePanel`
answers, or the ctx a host tab's `render` is handed). The rows are ordinary **path-less schema rows**
(Options' W15 arm: each is read with `row.get()` and written with `row.set(v)`, which call the
instance), drawn by `O.RenderRows`, so every control is the panel's own dropdown, slider, checkbox,
edit box or color swatch, in the host's skin and under its combat lock. The font row is the one media
picker, `Ka0sMedia_Font` (options-ui-§23), offering "Skin font", "Game default" and then every
LibSharedMedia face (every LibKa0s-Media-1.0 face without it). A color swatch's `get` answers both
color shapes, `{ r, g, b, a, [1], [2], [3], [4] }`, and its `set` reads either, so the host's
`colorDecode` / `colorEncode` pair does not matter.

`opts.tab` (`"look"`, `"sound"` or `"texts"`) draws one tab with no heading of its own; without it
the three draw one under another, each under its heading. Options-ui-§13 puts sections on tabs, so a
host normally passes `SettingsTabs(opts)` to `RenderTabbedSchema` as host tabs: `{ key, label,
tooltip, before, render }` each, keyed `opts.keyPrefix .. tab` (`"callout."` by default), `before`
copied from `opts.before`, `render(ctx)` calling `BuildSettings(ctx, { options, tab, L })`.

**Without one**, `parent` is a frame and the section is built of plain frames, one line each: a
check button for a toggle, a value between - and + buttons for a number, a button stepping through
the choices for a list, a swatch opening the client's `ColorPickerFrame` (when it has
`SetupColorPickerAndShow`) for a color. The per-key text boxes are the Options build's alone.

**Over each tab**, in either build: the **preview**, a sample line (`5  GO!  STOP`, each word in its
kind's color) in the chosen face, outline and shadow at the chosen size up to 64, repainted on every
write (a refresher in the page's `refreshers`); **Test countdown** (`TestCountdown()`, 5 to GO! on the
real call-out); **Play**, which shows the stock text picked in **Text to play** (session state, `GO`
until another is picked, never saved) with its voice; **Unlock to move** (`SetLocked`, never saved);
and **Reset position** (`ResetPosition`).

| Tab | Rows |
|---|---|
| Look | Font, Size, Outline, Glow, Shadow, Shadow X offset, Shadow Y offset (disabled with no shadow), Animation, Hold |
| Sound | Voice, Sound channel, Speak numbers from; with a client that lists a text to speech voice, Text to speech voice, Speech rate, Speech volume (disabled unless the voice is text to speech, and absent with no voice listed) |
| Texts | Colors: one swatch per kind. Stock texts: per key, a text box for the player's own words (empty is the stock text) and **Mute** (the `muted` setting) |

**The view** `BuildSettings` answers: `kind` (`"options"` or `"plain"`), `rows`, `preview` (the
Label or FontString), and for the plain build `controls` (`{ row, control, sync }` each), `refresh`
and `height`. It answers nil with no `parent` to build into (a plain build needs a frame) or for an
unknown `opts.tab`.

**Words.** `SETTINGS_STRINGS`, overridden key by key through `opts.L`, read with rawget (a Ka0s
locale table answers an unknown key with the key). A stock key's own word is its `STOCK` text.

## What is not here

- **No queue.** A Show replaces what is on screen.
- **No per-call channel or volume.** One channel per instance, the player's.
