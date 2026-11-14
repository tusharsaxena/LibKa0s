# `LibKa0s-Callout-1.0` — version 2.3

> **This document is the source of truth for this version of this major.** Anything else in this
> repo that describes the Callout surface points here rather than restating it. It describes the
> contract *as it is at this version* — not as it is now, unless this version is also the current
> one.

| | |
|---|---|
| Major | `LibKa0s-Callout-1.0` |
| Files and minors | `Callout.lua` minor **2** · `CalloutSettings.lua` minor **3** (paired on `Callout.lua`'s minor; minor 3 needs the shell at 2) |
| Shipped in | unreleased (v1.98.0) |
| Status | **Current** |
| Supersedes | [version 1.2](./version-1.2-docs.md) (v1.97.0) — the same surface with no host write route, no leaf keys and no `SchemaRows` |
| Superseded by | — |
| Requires | `LibKa0s-Core-1.0` minor ≥ 1 (`NEEDS_CORE = 1`, no member called) |
| Optional at call time | the host's write seam and prefix (`d.set`, `d.path`, from 2), the host's `LibKa0s-Options-1.0` instance, handed to `BuildSettings` (`EnsureScroll`, `TextRow`, `InlineButtonPair`, `RenderRows`, all four checked before anything is drawn, and the `Ka0sMedia_Font` picker through its row), `LibKa0s-Media-1.0` (`Font`, `FONTS`, the bundled faces), `LibKa0s-Skin-1.0` (`IsOwner`, `For(owner).GetFont`, the "Skin font" choice), `LibKa0s-Widgets-1.0` (`DragHandle`, the strip over an unlocked frame), `LibSharedMedia-3.0` (`Fetch`, `List`), `PlaySoundFile`, `C_VoiceChat.GetTtsVoices` and `C_VoiceChat.SpeakText`, each presence-checked |
| Confirm in-game | `LibStub("LibKa0s-Callout-1.0").MODULES` → `{ Callout = 2, CalloutSettings = 3 }` |

## What changed at this version: the settings on a Ka0s host's write route (plan row L11)

Found while adopting the call-out in Ka0s Combat Trail: at 1.2 the settings section drew **path-less**
rows whose `set` called the instance, and the instance wrote the host's `profile.callout` itself. A
Ka0s host's `architecture-§5` wants the opposite: every value a control chooses is a preference with
a **schema row**, every write goes through the host's **one helper** (`NS.SetByPath`), and the host's
`/<slash> get|set|reset` reaches every setting. The owner chose a library fix over a deviation row.
`Callout.lua` moves to **minor 2** and `CalloutSettings.lua` to **minor 3**; every change is
additive, and a host that passes neither new descriptor field sees 1.2's behavior. No lib-level
member moves (`members-2.3.json` differs from `members-1.2.json` in its key and minors alone); the
instance gains `SchemaRows` and the descriptor three fields.

| | | Since |
|---|---|---|
| `d.path`, `d.set` | The host's prefix for the call-out's rows (`"callout."`; a missing trailing dot is added) and its write seam, `set(path, value)`. With both, **every** write the instance makes is `d.set(d.path .. key, value)`: `Set`, `SetColor`, the drag's saved point, `ResetPosition`, the settings section's rows. The instance then only reads `d.db`. `New` raises for a `d.set` with no `d.path` | **2** |
| `d.colorEncode` | `colorEncode(r, g, b, a) -> stored`, the host's Options codec. The shape the instance writes a color in, and a color row's default. Without it the named-key shape (`{ r, g, b, a = 1 }`, the Options default) for a host that gives `d.path`, else the array `{ r, g, b }` | **2** |
| leaf keys | `Get` and `Set` take `texts.<KEY>` (a stock key's own text, `""` for none), `muted.<KEY>` (a boolean) and `colors.<kind>` (a color in either shape; `Get` answers `{ r, g, b, r =, g =, b = }`) beside the keys of `SETTINGS` | **2** |
| a color read in either shape | a stored color with named keys or an array is read; anything else is the kind's default | **2** |
| `SchemaRows(prefix, opts)` | The settings as schema rows (below) for the host to register in its own schema, and, second, the named non-setting state beside them, `{ prefix .. "point" }` | **3** |
| the Options build on the host's route | With `opts.prefix`, or the descriptor's `path`, `BuildSettings` (and through it `SettingsTabs`, which passes `opts.prefix` on) draws rows that carry their paths, read and written through the host's Options instance's own `get` / `set` | **3** |

**Why the route is opt-in, and what the old one now is.** A host that passes neither `d.path` nor
`d.set` keeps 1.2's route: the instance writes `d.db` itself and the section's rows are path-less. That
still works and is not changing, but it is **not conforming for a Ka0s host**: its settings have no
rows (so `/<slash> get|set|reset` cannot reach them and `architecture-§5`'s boot check cannot see
them), and its writes go around the helper. A Ka0s host takes the route below.

## What changed at version 1.2: the call-out's faces lead the font row (`CalloutSettings.lua` 2, plan row L2)

`LibKa0s-Media-1.0` 13.1 ships the two display faces the owner chose for the call-out on 2026-11-13,
`Ka0s Bebas Neue` and `Ka0s Russo One`, beside the default, `Ka0s Oxanium Bold` (Orbitron, also
planned, does not ship). `CalloutSettings.lua` moves to **minor 2**; `Callout.lua` does not move.

| | | Since |
|---|---|---|
| `FONT_FACES` | `{ "Ka0s Oxanium Bold", "Ka0s Bebas Neue", "Ka0s Russo One" }`: the call-out's display faces, in the order the font row offers them, `FONT_DEFAULT` first. Never mutate it | **1.2** |

- **The font row** offers "Skin font", "Game default", then `FONT_FACES`, then every other face,
  sorted. The default is offered always, as before; each other face only when it is listed: by
  LibSharedMedia when it lists any face, else by the winning `LibKa0s-Media-1.0` copy's `FONTS`.
  So a host whose Media copy predates 13 offers neither, and a face Media's `RegisterLSM` refused
  for the client's locale (its `langmask`: Bebas Neue is western only, Russo One western and ruRU)
  is not offered where LibSharedMedia is loaded, though the file ships, because drawn from the raw
  file it renders the player's text as boxes. No face is listed twice.
- **What a consumer owes:** nothing. A face reaches LibSharedMedia's list once the host's
  `Media.RegisterLSM` runs, and a new font file needs a **full client restart** to load.

## What changed at version 1.1: the settings section (`CalloutSettings.lua` 1, plan row L4)

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
| `MAJOR`, `MINOR` | 1 | `"LibKa0s-Callout-1.0"`, `2` (from 2) |
| `MODULES` | 1 | `{ Callout = 2, CalloutSettings = 3 }` (the second from 1.1, at 2 from 1.2, both moving at 2.3) |
| `New(d)` | 1 | A new instance (below). Raises without `d.db` |
| `DEFAULTS` | 1 | The settings' defaults (below), and the table a host **off the write route** seeds its profile with. A host on the route (`d.path`, from 2) seeds from `SchemaRows`' defaults instead: `DEFAULTS.texts` and `muted` are `{}` where the rows are one leaf per stock key, and `DEFAULTS.colors` are arrays where the rows' defaults are the host's shape (see [Adopting it](#adopting-it)). Never mutate it |
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
| `FONT_FACES` | 1.2 | `{ "Ka0s Oxanium Bold", "Ka0s Bebas Neue", "Ka0s Russo One" }`: the faces the font row leads with, after the skin's and the game's |
| `OUTLINES` | 1 | `NONE`, `OUTLINE`, `THICKOUTLINE`, `MONOCHROME` |
| `GLOWS` | 1 | `off`, `soft`, `strong` |
| `ANIMS` | 1 | `slam`, `pulse`, `glow`, `blink`, `shake`, `none` |
| `CHANNELS` | 1 | `Master`, `SFX`, `Dialog` |
| `SIZE_MIN`, `SIZE_MAX` | 1 | `32`, `200` |
| `STRATA` | 1 | `"FULLSCREEN"`: frame-layering-§1's T5 non-interactive screen alert (`SCREEN_ALERT`), mouse-transparent while locked, so it draws over the Blizzard Settings panel (`HIGH`) it is unlocked and tested from |
| `WIDTH` | 1 | `900`: the frame's width; its height is 1.5 × the size |
| `SETTINGS_STRINGS` | 1.1 | Every word the settings section shows, US English, keyed; a host overrides any through `opts.L` |
| `SETTINGS_TABS` | 1.1 | `look`, `sound`, `texts`: the section's tabs, in order |

The stock keys: `READY`, `GO`, `START`, `STOP`, `WARNING`, `ERROR`, `DONE`, `FINISH`, `NEW_BEST`,
`PAUSE`, `RESUME`, `CANCELED`, `PULL`, `INTERRUPT`, `MOVE`, `DEFENSIVE`, `REBUFF`, `EXPIRING`,
`UPGRADE`, `TIME_UP`, `VICTORY`, `FAILED`, `LAST_TEN`.

### The stock texts

Each key's pack line is its lower-case name plus `SOUND_EXT`. `texts[key]` replaces what is shown,
never what is said; `muted[key]` silences it.

| Key | Shown | Kind | Said (text to speech) | Pack line |
|---|---|---|---|---|
| `READY` | READY | info | Ready | `ready.ogg` |
| `GO` | GO! | go | Go | `go.ogg` |
| `START` | START | go | Start | `start.ogg` |
| `STOP` | STOP | stop | Stop | `stop.ogg` |
| `WARNING` | WARNING | warn | Warning | `warning.ogg` |
| `ERROR` | ERROR | error | Error | `error.ogg` |
| `DONE` | DONE | info | Done | `done.ogg` |
| `FINISH` | FINISH | go | Finish | `finish.ogg` |
| `NEW_BEST` | NEW BEST | go | New best | `new_best.ogg` |
| `PAUSE` | PAUSED | warn | Paused | `pause.ogg` |
| `RESUME` | RESUME | info | Resume | `resume.ogg` |
| `CANCELED` | CANCELED | stop | Canceled | `canceled.ogg` |
| `PULL` | PULL | warn | Pull | `pull.ogg` |
| `INTERRUPT` | INTERRUPT | warn | Interrupt | `interrupt.ogg` |
| `MOVE` | MOVE | warn | Move | `move.ogg` |
| `DEFENSIVE` | DEFENSIVE | warn | Defensive | `defensive.ogg` |
| `REBUFF` | REBUFF | info | Rebuff | `rebuff.ogg` |
| `EXPIRING` | EXPIRING | warn | Expiring | `expiring.ogg` |
| `UPGRADE` | UPGRADE | go | Upgrade | `upgrade.ogg` |
| `TIME_UP` | TIME UP | stop | Time up | `time_up.ogg` |
| `VICTORY` | VICTORY | go | Victory | `victory.ogg` |
| `FAILED` | FAILED | error | Failed | `failed.ogg` |
| `LAST_TEN` | LAST TEN | warn | Last ten seconds | `last_ten.ogg` |
| `1` .. `20` | the number | number | the number | `1.ogg` .. `20.ogg` |

### What is spoken

In this order, the first that applies: a `voice = false` (the spec's or `opts`') is silence; a stock
key in `muted` is silence; `voice = "off"` is silence; a custom spec's `sound` is played **exactly as
given** (a path or a FileDataID, on the player's channel, never joined to `soundsBase`); a number
above `speakFrom` is silence; `voice = "tts"` speaks the line's words (a stock key's *Said* column, a
number, a custom text's `text`); a pack plays the line's file. A custom text with no `sound` is
therefore spoken by text to speech and silent on a pack. With no `C_VoiceChat.SpeakText`, or no voice
in `GetTtsVoices()`, text to speech is silence, reported once; nothing stands in for it.

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
| `packs` | no | The pack folders the host ships, as its `LibKa0s sounds:` line names them (`{ "callout/male-joe" }`; the bare folder works too, and `{}` is none). `Voices()` offers only those, `Set("voice", …)` refuses any other pack, and a stored or default pack the host does not ship reads as the first pack it does, else `"off"`. Nil offers every `PACKS` row |
| `debug` | no | `debug(tag, msg)`, called under pcall with tag `"CALLOUT"` |
| `path` | no | From 2: the prefix the host registered `SchemaRows` under (`"callout."`). The default prefix for `SchemaRows` and `BuildSettings`; with `set`, the prefix every write is sent to |
| `set` | no | From 2: the host's write seam, `set(path, value) -> ok`. Needs `path`. A seam answering `false` is a refused write (`Set` and `SetColor` answer false and nothing applies); one that raises raises out of `Set`, and out of a drag only to the error handler |
| `colorEncode` | no | From 2: `colorEncode(r, g, b, a) -> stored`, the shape a color is written in and a color row's default is given in (above) |

## The settings

`Get(key)` answers the stored value, or the default when none is stored or the stored one is not
valid; an invalid stored value is never rewritten. `Set(key, value)` validates, writes and applies;
nil clears back to the default. From 2 both take the leaf keys `texts.<KEY>`, `muted.<KEY>` and
`colors.<kind>`. **Where the write lands** is the descriptor's choice: with `d.path` and `d.set` it is
`d.set(d.path .. key, value)`, a nil sent as the default (`""` for a text, `false` for a mute, the
kind's color in the host's shape, `DEFAULTS`' value otherwise), and the instance never writes
`d.db`; without them it is `d.db` itself, as at 1.2, a nil removing the key. On the route a whole
`texts` or `muted` table (1.2's form) is written as its leaves, since only they have rows: one
`d.set(d.path .. "texts." .. KEY, v)` per stock key, in `STOCK_ORDER`, a key the table leaves out
(or a nil table) sent as its default, so `Set("texts", t)` replaces the whole table exactly as off
the route. Every leaf is sent, and `Set` answers false when the seam refused any of them.

| Key | Default | Valid |
|---|---|---|
| `font` | `"Ka0s Oxanium Bold"` | any non-empty name: a LibSharedMedia face, a LibKa0s-Media-1.0 face, `"Skin font"` or `"Game default"`; a name nothing resolves falls back to the default face, then the game's |
| `size` | `96` | 32 – 200 |
| `outline` | `"THICKOUTLINE"` | `OUTLINES` |
| `shadow`, `shadowX`, `shadowY` | `true`, `2`, `-2` | a boolean; −20 – 20 |
| `colors` | per kind (below) | through `GetColor` / `SetColor`, or the leaf `colors.<kind>` (from 2); a stored color is read with named keys or as an array |
| `glow` | `"soft"` | `GLOWS`: a halo of the text in its kind's color behind it |
| `anim` | `"slam"` | `ANIMS` |
| `hold` | `1.5` | 0.2 – 10 seconds before a call-out fades |
| `point` | `{ "CENTER", "CENTER", 0, 180 }` | `{ point, relativePoint, x, y }` in UIParent's units, both anchors one of the nine region points; written by a drag (through `d.set` on the host's route, from 2) |
| `voice` | `"female"` | a `PACKS` key, `"tts"` or `"off"`; a pack outside `d.packs` reads as the first pack in it, else `"off"` |
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
| `Countdown(spec)` | `spec = { endsAt, from, finish, onTick, onDone }`. `from` is clamped to 1 – 20 (20 when nil); nothing shows while `ceil(endsAt - now)` is above it. At zero `finish` shows (a stock key, a number, a custom spec, or `false` for none; `"GO"` when nil) and `onDone()` is called once. `onTick(n)` is called as each number shows. Both run under pcall. A running countdown is replaced. A call-out already held on screen keeps its hold: it fades on its own schedule through a lead-in (`endsAt` more than `from` away), and the first number replaces it. Answers false while suspended or for a non-number `endsAt` |
| `Cancel()` | Stops the countdown with no finish and no `onDone`, takes the call-out down. Answers whether one ran |
| `Running()` | `running, n`: whether a countdown runs and the number it shows (nil before its first) |
| `Show(what, opts)` | `what` is a stock key, a number 1 – 20 (or its string) or a custom `{ text, kind, sound, voice = false, hold, anim, key }`. `opts` may carry `hold`, `anim`, `voice = false`. It fades after its hold. Over a running countdown it shows until the next number, which replaces it and takes its hold with it: a Show never fades a number. Answers false for nothing to show, or while suspended |
| `Hide()` | Takes the call-out down now; a running countdown shows its next number |
| `Suspend()` / `Resume()` / `Suspended()` | The stand-down: cancels, hides, locks, and refuses Show and Countdown until Resume |
| `Get(key)` / `Set(key, value)` | The settings, above; the leaf keys from 2 |
| `GetColor(kind)` / `SetColor(kind, r, g, b)` | A kind's color; `SetColor(kind)` with no color clears it. From 2 the write is `colors.<kind>`'s, in the host's shape |
| `Apply()` | Re-reads every setting onto the frame |
| `SetLocked(locked)` / `Locked()` | Unlocked, the frame takes the mouse, shows a sample (`READY`, silent) and the drag strip, and a drag writes `point`. Locked (the default, and not saved) it is mouse-transparent; a lock (or a `Suspend`) during a drag ends the move and writes `point`. The animations play on an inner content frame, so the frame and its strip never scale, shake or blink, and the strip ignores the frame's alpha |
| `ResetPosition()` | Clears `point` (on the host's route, writes the default point through `d.set`, from 2) |
| `Voices()` | The `voice` choices: `{ key, name }` for each pack the host ships (`d.packs`), then `tts`, then `off` |
| `TtsVoices()` | The client's voices, `{ voiceID, name }` each; empty without `C_VoiceChat` |
| `Frame()` | The frame, built on first use |
| `Stats()` | `built`, `shown`, `running`, `number`, `endsAt`, `key`, `text`, `kind`, `awake` (the OnUpdate is armed), `suspended`, `locked`, `logged` |
| `Look()` | From 1.1: `{ font, size, flags, shadow, shadowX, shadowY, glow }`, the look the frame draws, the font resolved to a file path. A fresh table |
| `Preview(what)` | From 1.1: `Show(what, { voice = false })`, `READY` by default: the look on the real call-out, silent |
| `TestCountdown(from)` | From 1.1: `Countdown{ endsAt = GetTime() + from, from = from }`, `from` 5 by default |
| `SettingsRows(opts)` | From 1.1: the section's path-less rows (below); `opts.tab` one tab's, `opts.L` the words, `opts.plain` without the text boxes |
| `SchemaRows(prefix, opts)` | From 3: the settings as schema rows under `prefix` (the descriptor's `path` when nil; raises with neither), and the named state's paths. `opts.L` the words, `opts.page` every row's `page`. See [The schema rows](#the-schema-rows) |
| `SettingsTabs(opts)` | From 1.1: three host tab entries for `RenderTabbedSchema`'s `opts.tabs` (below); `opts.prefix` (from 3) handed to each tab's build |
| `BuildSettings(parent, opts)` | From 1.1: builds the section into `parent` and answers its view (below); `opts.prefix` (from 3) |

## The settings section

`CalloutSettings.lua`, from 1.1. A consumer drops it into its own panel; it owns no page and no
SavedVariables. On the host's write route (from 3: `opts.prefix`, or the descriptor's `path`) every
row it draws carries its path and is written through the host's Options instance, so through the
host's seam; off it, every write is the instance's `Set` / `SetColor`, which reach the host's seam
too when the descriptor gives `set`, and the host's `db` otherwise.

### The schema rows

`SchemaRows(prefix, opts)`, from 3, answers the settings as **schema rows** shaped for
`LibKa0s-Schema-1.0` and `LibKa0s-Options-1.0`, for the host to register in its own schema
(`NS.Schema`, its `AddRows`) under the prefix it chooses, so its AceDB defaults, its panel, its
`/<slash> get|set|list|reset` and its boot check all cover them (`architecture-§5`):

| Field | What it holds |
|---|---|
| `path` | `prefix .. key`: `callout.size`, `callout.colors.go`, `callout.texts.READY`, `callout.muted.STOP` |
| `key` | The instance's key (`size`, `colors.go`), which `Get` and `Set` take |
| `type` | `bool`, `number`, `string` or `color`, the four Options widget types `Validate` accepts by default |
| `default` | What the instance reads with nothing stored: `DEFAULTS`' value for every scalar; `""` for a stock key's text and `false` for its mute (what `DEFAULTS`' empty `texts` and `muted` read as); a kind's `DEFAULTS` color in the host's shape (`d.colorEncode`'s, else `{ r, g, b, a = 1 }`); the voice's, the first pack the host ships when `DEFAULTS.voice` is not among them, else `"off"` |
| `validate(v)` | The instance's own rule for the key (the same one `Set` applies), a pack outside `d.packs` refused |
| `normalize(v)` | A stock key's text only: trimmed |
| `onChange()` | The instance's `Apply()`, so a write by path, from the panel, the slash command or a reset, reaches the frame |
| `min`, `max`, `step` / `values` | A number row's bounds, or a list's `{ value, text }` choices. The voice's and the text to speech voice's are functions, read when drawn: the packs the host ships, then `tts` and `off`; the client's voices, led (when it lists any) by `{ value = false, text = "Default (<first voice>)" }` (`SETTINGS_STRINGS.TTS_VOICE_DEFAULT`), so the stored default names the voice it speaks. The font row's is the `Ka0sMedia_Font` picker's list, a function as before |
| `get` | A color row's only (no row has a `set`): the kind's color as the instance reads it, either stored shape, answered in the host's shape (`d.colorEncode`'s, else `{ r, g, b, a = 1 }`). `Schema.Get` answers through it, so a color a 1.2 instance stored as an array still reaches the host's swatch as its own color and a default color reads as the default; a write still stores through the host's seam |
| `label`, `tooltip`, `group`, `subgroup`, `tab`, `startsLine`, `disabledIf`, `dialogControl`, `hasAlpha` | The panel's: `group` is the tab's word (Look, Sound, Texts), `subgroup` the Texts tab's two (Colors, Stock texts), `disabledIf` a predicate |
| `page` | `opts.page`, when given |

Every setting a control chooses has one: the fifteen scalars of `SETTINGS` other than `point`,
`texts` and `muted`, the six kinds' colors and, per stock key, its text and its mute (23 each). The
text to speech rows are among them whatever the client lists. Last come the preview block's two
**session rows**, `prefix .. "play"` (the text Play shows, default `GO`) and `prefix .. "unlocked"`
(Unlock to move, default `false`): `sessionOnly`, each storing through its own `get` / `set` (the
session pick, `SetLocked`), never in the profile, marked `preview = true`.

**The second answer, `{ prefix .. "point" }`,** is the call-out's **named non-setting state**
(`architecture-§5`): the drag's saved position, which only a drag determines and Reset position puts
back (a reset chooses nothing). No control sets it, so it has no row; the instance writes it through
`d.set` like everything else, and the host either lists it in its Schema's `writeThrough` (stored
raw, logged and announced) or stores it in its own seam, and names it in its Settings Schema with
its owner and its two writers, the drag-stop and `ResetPosition`.


**With the host's Options instance** (`opts.options`), `parent` is a page ctx (what `CreatePanel`
answers, or the ctx a host tab's `render` is handed). **On the host's route** (from 3) the rows are
the schema rows above, each carrying its path: the Options instance reads each with its descriptor's
`get(path)` and writes it with `set(path, v)`, so the host's helper validates, stores, runs the row's
`onChange` (the instance's `Apply`) and announces, and the panel refresh that follows repaints the
preview. The rows drawn are the ones `SchemaRows` answers, so the host must have registered them; a
text to speech row is drawn only while the client lists a voice, as before. **Off it** the rows are
ordinary **path-less schema rows** (Options' W15 arm: each is read with `row.get()` and written with
`row.set(v)`, which call the instance). Either way they are drawn by `O.RenderRows`, so every control is the panel's own dropdown, slider, checkbox,
edit box or color swatch, in the host's skin and under its combat lock. The font row is the one media
picker, `Ka0sMedia_Font` (options-ui-§23), offering "Skin font", "Game default", then `FONT_FACES`
(the default always, Bebas Neue and Russo One when LibSharedMedia lists them, or without it when
the Media copy ships them; from 1.2), then every other LibSharedMedia face (every LibKa0s-Media-1.0 face without it),
sorted. **Off the route** a color swatch's `get` answers both
color shapes, `{ r, g, b, a, [1], [2], [3], [4] }`, and its `set` reads either, so the host's
`colorDecode` / `colorEncode` pair does not matter there. **On the route** the swatch is the host's:
it reads through the descriptor's `get(path)` (the color row's `get`, in the host's shape) and decodes
with the host's `colorDecode`, and it writes what the host's `colorEncode` makes through the seam. So
there the codec does matter: `colorDecode` must read the shape `d.colorEncode` writes (the named
shape when it is not given), and the host passes its Options codec's encoder as `d.colorEncode`.

`opts.tab` (`"look"`, `"sound"` or `"texts"`) draws one tab with no heading of its own, in either build; without it
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
Label or FontString), `prefix` (the Options build's, nil off the host's route; from 3), and for the plain build `controls` (`{ row, control, sync }` each), `refresh`
and `height`. It answers nil with no `parent` to build into (a plain build needs a frame), for an
unknown `opts.tab`, or, with `opts.options`, when the instance lacks one of `EnsureScroll`, `TextRow`,
`InlineButtonPair` and `RenderRows` or its `EnsureScroll` answers no scroll for `parent`.

**Words.** `SETTINGS_STRINGS`, overridden key by key through `opts.L`, read with rawget (a Ka0s
locale table answers an unknown key with the key). A stock key's own word is its `STOCK` text.

## The voice packs and the sound declaration

The packs ship in the payload at `media/sounds/callout/<folder>/`, each folder holding exactly
`LINES` as `.ogg` (43 files) beside its own `CREDITS.md` and license texts:

| `voice` key | Folder | Voice | Licenses in the folder |
|---|---|---|---|
| `female` | `female-kathleen` | Piper `en_US-kathleen-medium`, US English | `LICENSE-CC0-1.0.txt`, `LICENSE-CC-BY-4.0.txt` (the base model's Hi-Fi TTS data, credited in `CREDITS.md`) |
| `male` | `male-joe` | Piper `en_US-joe-medium`, US English | `LICENSE-CC0-1.0.txt` |

`media/sounds/` is the second carve-out from whole-folder vendoring (`library-stack-§7`, *The sound
subset*; kit revision 55). A consumer declares the packs it ships in one line of its root
`CLAUDE.md`, **directly under its `LibKa0s icons:` line**, in one of three forms:

```text
LibKa0s sounds: none.
LibKa0s sounds: all.
LibKa0s sounds: callout/female-kathleen, callout/male-joe.
```

**No line means none.** A consumer that keeps only some packs offers only those by passing the same
folders as `d.packs`: `Voices()`, and through it the settings section's Voice row, then lists only
those, and a pack outside them is never played. Without `d.packs` every `PACKS` row is offered, and
a pack the copy does not carry is silence, reported once per file through `d.debug`. `tools/prune-icons.lua` prunes `media/sounds/` to the line after the icons, and
`testkit/vendor_sync.lua` holds the consumer's copy to it, credits and licenses included. A pack
under a license that makes attribution a condition is credited in the consumer's README as its
`CREDITS.md` states.

## Adopting it

A host keeps when to speak, its custom texts and every string; the instance keeps the frame, the
look, the voice and the settings rows. A sketch, Ka0s Combat Trail's race countdown:

```lua
local _, NS = ...
-- modules/RaceCountdown.lua: the race countdown on LibKa0s-Callout-1.0 (library-stack-§7).
local Callout = LibStub and LibStub("LibKa0s-Callout-1.0", true)
-- NS.CalloutStub (the degradation stub below) is defined before this file runs.

NS.Callout = Callout and Callout:New({
    name = "CombatTrailCallout", addon = "CombatTrail", skin = "CombatTrail",
    packs = { "callout/male-joe" },   -- its CLAUDE.md line: LibKa0s sounds: callout/male-joe.
    db = function() return NS.addon.db.profile.callout end,
    -- The write route (from 2): every write, the drag's point included, is NS.SetByPath("callout." .. key, v).
    path = "callout.", set = function(path, value) return NS.SetByPath(path, value) end,
    colorEncode = function(r, g, b, a) return { r = r, g = g, b = b, a = a or 1 } end,   -- the Options codec's
    debug = function(tag, msg) NS.Debug(tag, msg) end,
}) or NS.CalloutStub   -- defined first: nil here would leave NS.Callout nil

-- settings/Schema.lua: the rows join the host's schema, so its panel, its /ct get|set|list|reset
-- and its boot check all cover them. The drag's point joins the Schema descriptor's writeThrough
-- and is named in docs/schema.md as non-setting state. `writeThrough` is read once, at the
-- Schema's :New, so its list names "callout.point" there: the second answer below, which a suite
-- holds the host's list to.
local rows, named = NS.Callout:SchemaRows("callout.", { page = "race" })
NS.RegisterSchemaRows(rows)

-- defaults/Profile.lua: the AceDB defaults for profile.callout come from the ROWS, before
-- AceDB:New, never from Callout.DEFAULTS (the off-route seed): its texts and muted are {} where the
-- rows are one leaf per stock key, and its colors arrays where the rows' are the host's shape.
-- Seeded from DEFAULTS, Validate's defaultsRoot reports the 46 text and mute paths missing and
-- the reset count reads the six colors as changed. The point is seeded from DEFAULTS.point.
for _, r in ipairs(rows) do
    if not r.sessionOnly then LibStub("LibKa0s-Schema-1.0").Write(NS.defaults.profile, r.path, r.default) end
end
LibStub("LibKa0s-Schema-1.0").Write(NS.defaults.profile, named[1], Callout.DEFAULTS.point)

-- The race clock and the call-out read the same endsAt, so they never disagree.
local endsAt = GetTime() + 10
NS.Callout:Countdown{ endsAt = endsAt, from = 10, finish = "GO", onDone = NS.StartRace }
```

The settings page passes `NS.Callout:SettingsTabs({ options = O })` to `RenderTabbedSchema` (or calls
`BuildSettings(ctx, { options = O, tab = "look" })` from a tab's own render); with the descriptor's
`path`, every row it draws is one of the registered rows above, written through `NS.SetByPath`.
A host that adopted 1.2's route (no `path`, no `set`) keeps working unchanged, and is not conforming
until it takes this one: its settings have no rows and its writes go around its helper. The host's stand-down
calls `Suspend()` and its return `Resume()`; its profile change calls `Apply()`. The `addon` field is
what finds the packs and the bundled faces under `Interface\AddOns\<addon>\libs\LibKa0s\`.

### The degradation stub

A host that degrades without the library (anti-pattern #47) stubs the **instance**, in a file that
loads before the one calling `New` (the `or NS.CalloutStub` above reads it there):

```lua
NS.CalloutStub = {
    Countdown = function() return false end, Cancel = function() return false end,
    Running = function() return false, nil end, Show = function() return false end,
    Hide = function() end, Suspend = function() end, Resume = function() end,
    Suspended = function() return false end, Get = function() return nil end,
    Set = function() return false end, GetColor = function() return 1, 1, 1 end,
    SetColor = function() return false end, Apply = function() end, SetLocked = function() end,
    Locked = function() return true end, ResetPosition = function() end,
    Voices = function() return {} end, TtsVoices = function() return {} end,
    Frame = function() return nil end, Look = function() return {} end,
    Preview = function() return false end, TestCountdown = function() return false end,
    SettingsRows = function() return {} end, SchemaRows = function() return {}, {} end,
    SettingsTabs = function() return {} end,
    BuildSettings = function() return nil end,
    Stats = function() return { built = false, shown = false, running = false, awake = false,
        suspended = false, locked = true, logged = 0 } end,
}
```

From 3 the instance has `SchemaRows`, so a stub written against 1.2 gains it. Pin it with
`T.assertSurfaceParity(liveInstance, NS.CalloutStub, "Callout instance")`;
`members-2.3.json` lists the lib-level surface, which a host reads through `Callout:New` and the
constants above.

## What is not here

- **No queue.** A Show replaces what is on screen.
- **No per-call channel or volume.** One channel per instance, the player's.

## Vendoring

Whole-folder, exactly as every other major in this payload, then the declaration-driven prune:

```sh
cp -r LibKa0s/. <Addon>/libs/LibKa0s/
lua tools/prune-icons.lua <Addon>        # media/icons/ and media/sounds/ to the CLAUDE.md lines
```

`Callout.lua` and `CalloutSettings.lua` are entries in `LibKa0s.xml`, after `Toast.lua`, in that
order, so the whole-folder copy brings them in with no load-list change in the host.

**Consumer census.** Not measured: the major is new at v1.96.0, after the v1.83.0 stamp of
[`CONSUMERS.md`](../CONSUMERS.md). Ka0s Combat Trail is its one planned consumer (LibKa0s#85); every
export's verdict is *zero — planned at v1.96.0* until the next re-run.
