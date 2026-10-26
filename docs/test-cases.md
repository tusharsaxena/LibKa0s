# Test Cases

The full inventory of every headless test case in this repo, grouped by the suite file it
lives in. The `## Totals` table below counts the cases that run: its **Total** is the
authoritative pass count, and the README test badge and any count quoted in the docs must equal
it. A declared skip is listed by name in its group and counted on the `Skipped` row, never in
Total.

**Generated — do not hand-edit.** Regenerate with `lua tests/run.lua --list > docs/test-cases.md`.

### the runner (1)

- suite inventory: tests/_kit/test_prose.lua is declined, and the decline is recorded (skipped: CLAUDE.md carries a `## Documented deviations` row keyed `localization-§5`: The kit ships a US-English gate (`tests/_kit/test_prose.lua`) and this repo leaves it unwired, running its own `tests/test_prose.lua` instead. `testing-§9` and `localization-§5` between them permit  ... — tests/test_prose.lua runs in its place)

### test_core.lua (52)

- core: IsConcatSafe is false for a table.concat-hostile value, true for a plain one
- core: SafeToString renders a secret as lib.SECRET and passes nil/booleans through
- core: MakeCloseButton draws the collection's own art when told who is asking
- core: no addon name is the multiplication sign, exactly as before
- core: an addon name the art cannot answer for falls back to the glyph
- core: the art is inset inside the click target, not filling it
- core: the icon reddens under the pointer and goes back
- core: Print joins with a space, prefixes verbatim, and routes through the injected sink
- core: sep separates the prefix from the body and may be empty
- core: a function prefix is re-read on every call
- core: a prefix that has not resolved yet prints the body alone
- core: Format applies the format string with pre-stringified args
- core: Format lands a secret in a numeric specifier as the format and its parts
- core: the default sink is DEFAULT_CHAT_FRAME:AddMessage
- core: :New refuses a descriptor with no prefix
- core: ApplySkin no-ops on a frame without SetBackdrop
- core: ApplySkin applies the skin table and both colors
- core: SKIN is the flat 1px Ka0s edge, not the 12px tooltip border
- core: ApplySkin synthesizes the inner highlight, exactly once
- core: ApplySkin survives a frame whose metatable answers every key
- core: ApplySkin tints a title and a divider when the frame carries them
- core: ApplySkin lays the backdrop down before anything drawn on top of it
- core: ApplySkin tolerates a frame with neither a title nor a divider
- core: ApplySkin honors an explicit skin table
- core: RGBA reads the keyed shape
- core: RGBA reads the positional shape
- core: RGBA lets the keyed shape win every channel, never mixing the two
- core: RGBA falls back per channel, so a three-element color keeps its default alpha
- core: RGBA keeps a stored false rather than swallowing it
- core: RGBA returns the defaults unchanged for a non-table
- core: RGBA does not default the defaults
- core: MakeCloseButton returns a button wired to onClick
- core: MakeCloseButton returns nil when CreateFrame is unavailable
- core: the player's class color is the client's, and nil for a class it cannot name
- core: the player's class color is memoized on SUCCESS only
- core: no unit but the player is ever cached
- core: an unresolvable unit answers nil rather than the player's color
- core: ResolveColor keeps the stored alpha under class color
- core: ResolveColor falls through to the stored rgb when the class does not resolve
- core: ResolveColor with the companion off never reaches the class palette
- core: ResolveColor answers four numbers for a swatch that was never stored
- core: SafeRegisterEvents registers around a retired name, front gate
- core: SafeRegisterEvent refuses a retired name for every AceEvent registrant, front gate
- core: SafeRegisterUnitEvent on a frame isolates a retired name, front gate
- core: SafeRegisterEvents registers around a retired name, probe frame
- core: SafeRegisterEvent refuses a retired name for every AceEvent registrant, probe frame
- core: SafeRegisterUnitEvent on a frame isolates a retired name, probe frame
- core: SafeRegisterEvent's front gate rejects without calling RegisterEvent
- core: SafeRegisterEvent on a raw frame, and with no rejected list at all
- core: SafeRegisterEvent on a Bus-stamped target is replayed after a stand-down
- core: Perf refuses to register when Core is missing or below NEEDS_CORE
- core: Perf's own stringifier renders a secret as <secret>

### test_core_resize.lua (24)

- resize: MakeResizable makes the frame resizable and answers the grip it built
- resize: the bounds are the options' minimum and the screen's size
- resize: explicit maxima win over the screen
- resize: with no minimum the frame's current size is the minimum
- resize: widthOnly pins the height at the minimum
- resize: a client without SetResizeBounds gets SetMinResize and SetMaxResize
- resize: a left mouse-down on the grip starts sizing from the bottom-right
- resize: any other button does not start sizing
- resize: mouse-up stops sizing and hands the new size to onResize
- resize: a resize alone leaves the frame out of the client's layout cache
- resize: a window dragged before the resize stays user-placed, exactly as a drag leaves it
- resize: OnSizeChanged runs the relayout, after any script the frame already had
- resize: no onResize is fine
- resize: without CreateFrame, or on a frame with no sizing API, nothing changes
- resize: canResize answering false refuses the mouse-down, and the mouse-up after it is inert
- resize: canResize is read at every mouse-down, not once at build
- resize: canResize is handed the frame being sized
- resize: a sizing already started finishes even if canResize turns false mid-drag
- resize: canResize never changes the grip's visibility
- resize: a canResize that is not a function is ignored
- resize: onResizeStop runs once per completed sizing, after onResize, and never from OnSizeChanged
- resize: onResizeStop does not run for a right-click or a stray mouse-up
- resize: gripParent builds the grip on another frame while sizing stays on frame
- resize: gripParent that is not a table falls back to the frame

### test_env.lua (9)

- env: GetAddOnMetadata reads the TOC through C_AddOns
- env: GetAddOnMetadata never reads the removed bare global
- env: Version answers the TOC version
- env: Version prefers the TOC over the fallback
- env: Version returns the fallback when the TOC cannot be read
- env: GetPlayerMapID asks C_Map for the player's map
- env: GetPlayerMapID answers nil without C_Map
- env: GetZone answers zone and subzone
- env: GetZone answers empty strings, never nil, when the readers are absent

### test_compat.lua (49)

- compat: registers minor 1 with exactly the nine public members
- compat: the Core floor keeps the major absent from a payload without Core
- compat: the source reads every global bare, never through the global table
- compat: IsSecret is false for every value when the client has no secrets system
- compat: IsSecret asks the client's own test
- compat: IsSecret normalizes a truthy non-boolean answer to true
- compat: CanAccess asks canaccessvalue where it exists
- compat: CanAccess without canaccessvalue is 'accessible unless secret'
- compat: CanAccess with neither global answers true, nil included
- compat: a secret that is accessible is still not a safe key
- compat: IsSafeKey(nil) is false with and without the secrets system
- compat: IsSafeKey is true for plain values, and v ~= nil with no system
- compat: Core's concat probe answers a different question and is not duplicated
- compat: GetSpellInfo flattens C_Spell's table into exactly six values
- compat: GetSpellInfo's modern rung is authoritative when it answers nil
- compat: GetSpellInfo remaps the legacy global's real shape, dropping the rank
- compat: GetSpellInfo answers a single nil when neither rung exists
- compat: GetSpellInfo takes a number or a string and calls no rung for anything else
- compat: GetSpellInfo passes a secret field through untouched
- compat: GetSpellInfo answers a single nil when the legacy global has no name
- compat: GetSpellName answers from C_Spell.GetSpellName first
- compat: GetSpellName falls to C_Spell.GetSpellInfo's name when the top rung is nil
- compat: GetSpellName treats a plain empty string as no answer
- compat: GetSpellName reads C_Spell.GetSpellInfo when C_Spell.GetSpellName is absent
- compat: GetSpellName on the legacy global returns its first value only
- compat: GetSpellName answers nil when no rung exists
- compat: GetSpellName returns a secret untouched and asks IsSecret before anything else
- compat: GetSpellName(nil) answers nil and calls no rung
- compat: GetSpellTexture returns one value, dropping the client's original icon
- compat: GetSpellTexture's modern rung is authoritative when it answers nil
- compat: GetSpellTexture falls back to the legacy global, one value
- compat: GetSpellTexture answers nil with no rung, and for a nil id calls none
- compat: GetSpellCooldown returns the modern table's five values in order
- compat: GetSpellCooldown reads a missing isEnabled as true and only true as active
- compat: GetSpellCooldown answers the inert tuple for a nil info table
- compat: GetSpellCooldown passes secret timings through without touching them
- compat: GetSpellCooldown derives isActive on the legacy global
- compat: GetSpellCooldown reads a zero legacy duration as not active
- compat: GetSpellCooldown reads a legacy isEnabled of 0 or false as disabled
- compat: GetSpellCooldown never orders a secret legacy duration
- compat: GetSpellCooldown is inert with no rung and calls none for a bad id
- compat: GetSpecialization prefers the namespaced reader, even its nil, one value
- compat: GetSpecialization falls back to the global, one value
- compat: GetSpecialization answers nil when neither reader exists
- compat: GetSpecializationInfo passes the namespaced multi-return through exactly
- compat: GetSpecializationInfo uses the global only when the namespaced reader is absent
- compat: GetSpecializationInfo(nil) calls no reader, and nil when none exists
- compat: with every rung removed each member answers the documented absent value
- compat: a host patching the shared table does not change another member's answer

### test_lifecycle.lua (22)

- lifecycle: the major is registered and floors on Core
- lifecycle: the reserved hold keys are exported rather than spelled per host
- lifecycle: New refuses a descriptor missing any required field
- lifecycle: a fresh latch is up, holds nothing, and has fired nothing
- lifecycle: the first hold stands down, and the callbacks take no arguments
- lifecycle: holding a key already held is a no-op and does NOT stand down again
- lifecycle: releasing a key that is not held is a no-op and does NOT stand up
- lifecycle: Hold(a); Hold(b); Release(a) stands down ONCE and never stands up
- lifecycle: Hold; Release; Hold fires down, up, down — in that order, once each
- lifecycle: hold order is irrelevant to the edge count, in both directions
- lifecycle: the perf hold released under a live disabled hold leaves the addon down
- lifecycle: Set(key, truthy) holds and Set(key, falsy) releases
- lifecycle: Set is idempotent in both directions
- lifecycle: Reevaluate fires nothing when the set has not crossed
- lifecycle: Holds answers a FRESH sorted array, not the internal table
- lifecycle: the library prints nothing unless a line is asked for
- lifecycle: PrintHolds with no host printer answers false rather than raising
- lifecycle: a raising standUp still leaves the hold set empty and the latch up
- lifecycle: a raising standDown leaves the hold taken, so the release path still works
- lifecycle: a standDown that releases a hold fires standUp nested, and the latch ends up
- lifecycle: Hold and Release refuse a key that is not a non-empty string
- lifecycle: two latches share nothing

### test_lifecycle_debug.lua (14)

- lc debug: Lifecycle is at minor 3
- lc debug: the first hold writes one stand-down line with the hold and the set, before standDown
- lc debug: the last release writes one stand-up line with the empty set, before standUp
- lc debug: Set routes to the same lines as Hold and Release
- lc debug: a full down-up-down cycle writes one line per edge, in order
- lc debug: a second hold while down fires no edge and writes no line
- lc debug: releasing one of two holds fires no edge and writes no line
- lc debug: no-op calls write nothing (re-hold, release unheld, Reevaluate, PrintHolds)
- lc debug: a raising standDown still leaves its line in the log
- lc debug: a nested edge from inside standDown logs in the order the edges ran
- lc debug: no debug in the descriptor stays silent and the edges still fire
- lc debug: a non-function debug field is ignored, not called
- lc debug: a sink that raises does not strand the latch half down
- lc debug: PrintHolds' chat line is unchanged by the sink

### test_bus.lua (30)

- bus: the major is registered and reports its file minor
- bus: the major is absent without Core, and with a Core below its floor
- bus: New refuses a descriptor without name, and a non-function isDown
- bus: the documented degradation stub matches the live surface
- bus: NewTarget answers a fresh target per call, and two receivers both hear one message
- bus: SendMessage on a tracked target is left raw, and reaches others while its own are down
- bus: the record follows every wrapper, and UnregisterAllEvents leaves messages alone
- bus: StandDown takes events AND messages down and answers the entry count
- bus: StandDown keeps the record and StandUp replays it
- bus: StandUp replays the record as it is NOW, not a snapshot taken at StandDown
- bus: a registration made while down is recorded and NOT live until StandUp
- bus: StandDown and StandUp are idempotent
- bus: re-registering a key replaces the entry in place and never duplicates it
- bus: every handler form survives the round trip with CallbackHandler's arguments
- bus: a raw register that raises while up reaches the caller and is not recorded
- bus: one entry that raises on replay does not stop the others, and StandUp never raises
- bus: a rejected entry is dropped from the record
- bus: StandUp is refused while isDown answers true, and the bus stays down
- bus: composed with Lifecycle, releasing one hold under another leaves the bus down
- bus: a re-embedded target is re-stamped at the next edge, so later registrations stand down
- bus: after a re-stamp, a registration made while down is recorded and not live
- bus: the re-stamp adopts the new raw member and counts a target once
- bus: a target only CallbackHandler holds survives StandDown and a full GC
- bus: a target emptied by its owner leaves the bus, which then holds nothing of it
- bus: two buses share nothing
- bus: the bus prints nothing across a full cycle
- bus: without AceEvent-3.0, NewTarget answers nil and the rest answer zero
- bus: Catalog accepts a conforming table and answers a fresh copy of it
- bus: Catalog refuses each malformed declaration, naming what is wrong
- bus: the catalog is strict on read and on write

### test_schema.lua (32)

- schema: the major is registered and reports its own live version
- schema: the module refuses to register without Core, and registers with it
- schema: the lib-level surface is exactly the six pure members
- schema: the instance surface is exactly the documented member list
- schema: the reference stub carries the whole surface, lib level and instance
- schema: the reference stub reaches neither the library nor the suite
- schema: the stub completes writes, in the live seam's order and to the same store
- schema: the stub's SetMany is all or nothing, and lands what the live batch lands
- schema: the stub writes a writeThrough path through, as the live seam does
- schema: the stub's Reset All sweep resets rows and keeps the sweep veto
- schema: the stub's lib level answers as the library's does on the same inputs
- schema: L overrides a STRINGS key, and a synthesizing L does not mask the rest
- schema: SplitPath memoizes by identity, drops empty segments, tostrings a number
- schema: Read walks a nested path and answers nil at every absence
- schema: Write creates intermediates and repairs a non-table one
- schema: SameValue compares scalars, -0, nested tables, both directions
- schema: a warm Read allocates nothing
- schema: New refuses a descriptor without rows and holds rows by reference
- schema: FindRow is first-wins, skips path-less rows, and refuses a non-string
- schema: AddRows appends, inserts at the head in order, and clamps past the end
- schema: a head insert re-indexes, so a new duplicate becomes the first
- schema: a host's in-place removal is seen after Reindex and not before
- schema: a healthy schema validates to zero errors and resolves every stored row
- schema: each shape error is counted and printed once
- schema: an unresolvable path is missing; sessionOnly, nil roots and bound rows are exempt
- schema: types defaults to the four widget types and a host set replaces it
- schema: Validate with no print still counts, silently
- schema: one row's errors print in field order, and its missing line prints after them
- schema: a non-string or empty path is labeled as given and is never a stored path
- schema: defaultsRoot gets the split parts and the row, and its first may be a string
- schema: a malformed spec falls back field by field
- schema: two instances share nothing

### test_schema_write.lua (41)

- schema: an unknown path is refused and nothing is stored or called
- schema: a write logs, then reacts, then announces, once each, and copies a table
- schema: a validate refusal names the path and carries why, and nothing happens
- schema: a bare-false validate is refused with why = nil
- schema: an instance-rooted write reaches the named instance, not the active one
- schema: an absent instance is refused with the resolver's reason, after validate
- schema: a resolver answering nil with no reason is refused as NO_ROOT
- schema: a row with its own set stores through it and never resolves a root
- schema: a sessionOnly row without set stores nothing and still reacts and announces
- schema: the inverted minimap row stores the inverse and reads back the value
- schema: debugEnabled false means neither debug nor format runs
- schema: the Set line carries format(row, v) when given and the value otherwise
- schema: with no debug, announce or format the seam still stores and reacts
- schema: a raising onChange propagates after the store and the line, before announce
- schema: Set resolves before it validates, and validate and the tail see the resolved id
- schema: a resolver naming no id leaves the caller's, and a false id is still an id
- schema: a closure or sessionOnly row hands validate and the tail the caller's id as given
- schema: Set answers one value on success, two on a refusal, three on an invalid value
- schema: a format answering nil falls back to the value's text on the Set line
- schema: Get answers an interior node for a path with no row, and nil past a leaf
- schema: every instance member works taken as a bare value, without self
- schema: Default is a deep copy and nil for an unknown path
- schema: ApplyDefault writes through Set, and refuses a row with nothing to restore
- schema: ApplyDefault's table default is stored as a copy
- schema: resetExempt vetoes a sweep inside a bracket and not a named reset outside one
- schema: a bracket mutes per-row lines and closes with one line counting changed rows
- schema: nested brackets are one act, one line, the outermost act and scope
- schema: a profile reset at any level silences the bracket
- schema: an error at any level marks the line stopped
- schema: an unpaired BulkEnd is a no-op and never drives the depth negative
- schema: BulkRun re-raises the same error value, closes the bracket, marks the line
- schema: BulkRun hands fn an info table whose profileReset silences the line
- schema: BulkAdd feeds the open bracket's tally and does nothing outside one
- schema: a closure row that stores what it already held counts 0 (read-back tally)
- schema: a raising onChange inside a bracket still counts the write that landed
- schema: the bulk line honors debugEnabled
- schema: CountOffDefault counts stored rows off default and honors pred
- schema: CountOffDefault with no root counts exactly the rows that have a default
- schema: ResetCounted leaves the count pending for exactly one consumer
- schema: ResetCounted re-raises unchanged and clears the pending count
- schema: ConsumeResetCount while a bracket is open closes it with no line

### test_schema_batch.lua (22)

- schema batch: the instance carries SetMany at minor 2
- schema batch: one invalid entry stores nothing, calls nothing, and names its index
- schema batch: an unknown path refuses the whole batch
- schema batch: a normalize refusal inside a batch refuses it whole
- schema batch: a valid batch stores every entry, runs every onChange, announces once
- schema batch: every store lands before the first onChange runs
- schema batch: without announceBatch, announce runs once per write, after the reactions
- schema batch: with an act the batch is one bracket and one line counting the rows it moved
- schema batch: a raising onChange still closes the batch's bracket, and the stores stand
- schema batch: an empty batch stores nothing and answers true
- schema batch: Set stores normalize's value and hands it to onChange and announce
- schema batch: normalize answering nil, why refuses with INVALID and stores nothing
- schema batch: normalize runs only after validate accepts
- schema batch: a normalize refusal comes before a missing root
- schema batch: Get hands the instance id to a row's own get
- schema batch: ApplyDefault(row, id) writes through Set with that id
- schema batch: a writeThrough path with no row is stored raw, logged and announced
- schema batch: a row-less path NOT in writeThrough is still refused and never stored
- schema batch: a writeThrough path that HAS a row takes the row and its validate
- schema batch: a writeThrough store is a copy, and a missing root still refuses
- schema batch: a writeThrough write inside a bracket joins its tally, and SetMany takes it
- schema batch: a malformed writeThrough list keeps only its non-empty strings

### test_pool.lua (23)

- pool: New hands back an empty pool
- pool: New hands back a DISTINCT pool each call
- pool: Acquire builds when the free list is empty, and shows what it hands back
- pool: a released object is REUSED rather than rebuilt
- pool: ReleaseAll hides every active object and returns it to free
- pool: ReleaseAll on an empty pool is a no-op
- pool: the `before` hook runs on each object, before it is hidden
- pool: a nested release through the hook empties both levels
- pool: acquire-release-acquire preserves object identity
- pool: acquire order survives a release — rank n comes back to rank n
- pool: NewKeyed hands back an empty keyed pool
- pool: AcquireKeyed files the object under its key, and shows it
- pool: AcquireKeyed reuses a released object rather than rebuilding
- pool: ReleaseAllKeyed hides every active object and returns it to free
- pool: ReleaseAllKeyed hands the key to the before hook
- pool: ReleaseAllKeyed on an empty pool is a no-op
- pool: AcquireKeyed twice on one key replaces nothing and leaks nothing
- pool: keyed acquire-release-acquire preserves object identity
- pool: ReleaseAll RAISES on a keyed pool rather than silently recycling nothing
- pool: ReleaseAll still accepts an ordinary array pool untouched
- pool: CountsKeyed counts a keyed active map that Counts cannot see
- pool: the ReleaseAll guard cannot catch keys that are themselves 1..n
- pool: a keyed release is unaffected by ordering — the key is the mapping

### test_item.lua (23)

- item: ItemIDFromLink pulls the id out of a full link
- item: ItemIDFromLink accepts a bare itemString
- item: ItemIDFromLink answers nil for anything that is not a link
- item: BonusIDsFromLink reads the declared bonus ids in link order
- item: BonusIDsFromLink accepts a bare itemString
- item: BonusIDsFromLink answers an empty table for an item with no bonuses
- item: BonusIDsFromLink stops at the declared count when modifiers follow
- item: BonusIDsFromLink keeps empty fields so positions hold
- item: BonusIDsFromLink skips a non-numeric field
- item: BonusIDsFromLink answers nil for anything that is not an item
- item: BonusIDsFromLink answers the same for a |cff link and a |cnIQ link
- item: QualityFromLink reads the quality out of a legacy |cff hex prefix
- item: QualityFromLink reads the 11.1.5+ |cnIQ<n> link color
- item: QualityFromLink retries a quality map that was built empty
- item: QualityFromLink answers nil for an uncolored or absent link
- item: QualityFromLink answers nil for a color no quality uses
- item: QualityLabel prefers the client's localized label
- item: QualityLabel falls back to the static English map
- item: QualityLabel defaults to Poor when given nothing
- item: QualityLabel stringifies a quality it does not know
- item: LoadItem asks the client to cache the id
- item: LoadItem fires the callback once the item is loaded
- item: LoadItem is inert without an id or without the API

### test_glow.lua (15)

- glow: the major registers with Core, and reports its file minor
- glow: absent LCG -- Start answers false for every style and Stop is quiet
- glow: LCG registered AFTER the driver loads is reached at call time
- glow: pixel maps every knob to its LCG position, key at 10 and frameLevel at 11
- glow: pixelLength 0, negative, a string or nil goes as nil; a positive number passes
- glow: pixelBorder and procStartAnim are false only when false
- glow: a numeric knob that is not a number goes as nil
- glow: autocast maps 9 positions and button 4, button with no key
- glow: proc gets a fresh options table per call, never the caller's knobs
- glow: nil and non-table knobs read as empty, and the call still happens
- glow: an unknown style or a nil frame answers false and calls nothing
- glow: a missing LCG member answers false or is skipped, and others still work
- glow: Stop shapes -- one style, keyless button, stop-all in order, unknown is a no-op
- glow: stateless -- Start never stops, and repeated Starts all reach LCG
- glow: Glow.lua names LibStub(...) only in the Core probe and the LCG resolver

### test_media.lua (37)

- media: ICON_SETS names the three sets, each with a prefix, a folder and a license
- media: every name in ICONS has a file, and every file has a name, in every set
- media: each icon set's license ships beside its art
- media: the catalog holds every set, not just the first
- media: no Phosphor brand mark ships
- media: the first 113 names are minor 4's, in minor 4's order
- media: every name in TEXTURES, BORDERS and BACKGROUNDS has a file, and every file a name
- media: Texture builds the vendored path, WITHOUT the extension
- media: the texture keys are the labels a player reads
- media: every font in FONTS ships with its license
- media: ICONS holds no duplicate
- media: Icon builds the vendored path, WITHOUT the extension
- media: the file behind an icon path is still <name>.tga on disk
- media: re-attaching the generated catalog never doubles a name, and keeps the table
- media: a prefixed name resolves into its set's folder
- media: an unknown prefix, or a set's name without its prefix, answers nil
- media: IconAuthor names a Game-icons mark's author, and nothing else's
- media: Font builds the vendored path from the catalog's own filename
- media: an unknown name answers nil rather than a plausible path
- media: a missing addon name answers nil rather than a path into nowhere
- media: a consumer that vendors elsewhere passes its own path
- media: RegisterLSM registers every font and every texture, by catalog name
- media: RegisterLSM flags the face western+ruRU, so a ruRU client keeps it
- media: RegisterLSM counts only what LibSharedMedia kept
- media: RegisterLSM counts a face another copy registered first
- media: RegisterLSM never offers a key LibSharedMedia already holds
- media: an LSM without the locale bits gets a plain Register
- media: an LSM without IsValid counts every Register call, as minor 3 did
- media: no LibSharedMedia is 0 registrations, not an error
- media: FONTS carries the five skin faces beside JetBrains Mono
- media: each face names its own locales, and only JetBrains Mono reaches ruRU
- media: every OFL face ships with its license text beside it
- media: RegisterLSM('X') registers 'Ka0s Barlow' under X's own libs folder, western only
- media: a ruRU client keeps JetBrains Mono and is refused the western-only faces
- media: BORDERS and BACKGROUNDS hold the Glass art, and their paths are extensionless
- media: the Glass art is uncompressed 32-bit TGA, power-of-two on both axes
- media: RegisterLSM registers the Glass border and background, and counts them

### test_skin.lua (27)

- skin: the major registers both files and the sentinel
- skin: the shell refuses without Core, and SkinDefs then attaches to nothing
- skin: without SkinDefs the engine runs and every token is nil
- skin: the schema names each token once, with a known kind
- skin: every registered skin resolves every schema token to its kind
- skin: Ka0s Default sets every token, faces and sizes included
- skin: Ka0s Default equals the published constants
- skin: Ka0s Default equals the file-local constants it replaces
- skin: Ka0s Default equals LootHistory's constants
- skin: a skin derives from Ka0s Default, and false means none
- skin: RegisterSkin validates, orders and replaces
- skin: an unregistered owner is not an owner and reads Ka0s Default
- skin: RegisterOwner reads the host's choice once, in either shape
- skin: SetChoice is idempotent
- skin: SetChoice resolves before the listeners run
- skin: leaving eui after EllesmereUI painted asks for one reload and repaints nothing
- skin: leaving an eui EllesmereUI never painted is an ordinary change
- skin: one owner switching never repaints another's frames
- skin: a repaint replays each recorded frame once, primitives in first-paint order
- skin: a repaint replays frames in the order they were first painted
- skin: the repaint flag is up only while replaying, and a raising primitive stops nothing
- skin: a frame painted for a second owner moves to it; Untrack forgets it
- skin: the frame registry holds its frames weakly
- skin: the facade is late-bound: swapping lib.prim reaches a cached S
- skin: a newer minor keeps every facade table and re-fills it
- skin: Resolve answers the skin's value for the sentinel or a fromSkin companion
- skin: ResetToSkin puts listed keys back on the skin

### test_skin_defs.lua (24)

- skin defs: the nine skins register in order with their labels
- skin defs: every skin names only schema tokens, each of its kind
- skin defs: every skin defines every schema token or inherits it from Ka0s Default
- skin defs: geometry tokens equal Ka0s Default in all nine skins
- skin defs: every skin's GameTooltip lines read on the client's dark tooltip
- skin defs: every skin's text reads on its own window
- skin defs: every skin's set drawer label differs from its unset one
- skin defs: every skin's bind-state and danger colors read on its own window
- skin defs: the bind-state tokens inherit Ka0s Default unless a skin overrides for legibility
- skin defs: every skin's split text, icon and signed colors read where they draw
- skin defs: the split tokens inherit Ka0s Default unless a skin overrides for legibility
- skin defs: High Contrast draws 1px control edges inside a 2px window and popup edge
- skin defs: Glass rounds its window and popups only, on the Ka0s Glass nine-slice
- skin defs: WoW Default wears the Blizzard art docs/api/Skin names
- skin defs: WoW Midnight is flat with a 2px gold edge and gradients, no Blizzard art
- skin defs: only WoW Default names Blizzard art
- skin defs: WoW Forever is warm charcoal, black centered titles, tan accent, gold headings
- skin defs: every font and border a skin names is shipped or an LSM default
- skin defs: the font assignments follow the spec
- skin defs: every skin sets both sizes, within a point and a half of Ka0s Default's
- skin defs: a hovered row is told apart from a selected one
- skin defs: WoW Default's checkbox art is its only box
- skin defs: in every skin a primary button differs from a normal one
- skin defs: no skin draws a box round a slider's bar

### test_skin_paint.lua (32)

- skin paint: the three files attach to the shell and fill every vocabulary entry
- skin paint: the extras and controls attach to nothing without SkinPaint's helpers
- skin paint: with no skin registered a primitive paints nothing it has no token for
- skin paint: Shell on Ka0s Default draws Core.SKIN's window from its tokens
- skin paint: Shell paints a skin's window from its tokens
- skin paint: a second Shell call makes no new region and paints the same
- skin paint: a skin switch repaints a Shell live, and back to Ka0s Default exactly
- skin paint: WoW Default's window is the dialog edge on the holder over the tiled art
- skin paint: the holder is a child frame one level up, and edges live on it
- skin paint: every skin fades a stock frame's art and draws its own window, Ka0s Default too
- skin paint: two owners on one loaded copy paint and repaint only their own frames
- skin paint: a target painted for a second owner is given back first
- skin paint: a target untracked and painted again reuses its regions and hooks
- skin paint: fills and washes sit under the target's text, edges over it
- skin paint: a bar one level above its window keeps its fill over the window
- skin paint: a fill another fader dimmed comes back at full alpha on the next paint
- skin paint: Panel on Ka0s Default is LootHistory's list panel, call for call
- skin paint: Inset, noBg, noBorder and the nav rail's recolor
- skin paint: FadeRegions fades the stock textures, records their alpha, and spares its own
- skin paint: FadeNineSlice fades the nine pieces under every skin
- skin paint: TitleBar on Ka0s Default fills its bar and centers its gold title
- skin paint: TitleBar fills under its text, centers its title, and gives the alignment back
- skin paint: Divider colors a texture in place, as Core's divider is colored
- skin paint: Card on Ka0s Default is LootHistory's KPI card, call for call
- skin paint: Footer draws its band in every skin, Ka0s Default's foot.bg included
- skin paint: Strip and Cover color their textures as TestStrip and the combat cover do
- skin paint: MenuFrame on Ka0s Default is the shared popup menu, call for call
- skin paint: Tooltip colors a library tooltip in every skin, its art kept
- skin paint: Text colors a role, and a skin's font reaches it through the owner's font object
- skin paint: Font and White put the body font and color on a string
- skin paint: the getters answer the owner's skin
- skin paint: a skin's size scales each string from its own, one font object per size

### test_skin_paint_controls.lua (28)

- skin controls: Button on Ka0s Default is LootHistory's flat button's paint
- skin controls: Button repaints live, primary reads btnPrimary, and the icon is tinted
- skin controls: a stock button is faded and boxed under every skin, Ka0s Default too
- skin controls: Button with keepKeys paints only the label
- skin controls: WhiteButtonLabel and StateButtonLabel
- skin controls: EditBox on Ka0s Default paints the search box's backdrop, call for call
- skin controls: EditBox fades a template's pieces and colors its text and hint in a skin
- skin controls: leaving a skin font puts an EditBox's face back by path, never its anonymous font object
- skin controls: Dropdown on Ka0s Default is Widgets' dropdown, call for call
- skin controls: Checkbox draws a box and a mark that follows the check
- skin controls: WoW Default's checkbox is the client's art; Ka0s Default draws a square box
- skin controls: a disabled Button's label reads text.disabled, and comes back when enabled
- skin controls: ScrollBar's thumb states and the console's own bar match today's tints
- skin controls: a bar's own thumb is tinted and its track drawn under every skin
- skin controls: Slider is painted under every skin, Ka0s Default's thin bar included
- skin controls: Tab paints its state, SetTabSelection moves it, and a repaint keeps it
- skin controls: WoW Default's tabs are the client's tab art; a stock tab is faded under every skin
- skin controls: CloseButton on Ka0s Default is Core's close button, call for call
- skin controls: a stock close button gets a glyph under every skin, Ka0s Default too
- skin controls: PageButton, SquareIcon, IconBorder, SortHeaderBar and ApplyBarFill
- skin controls: NavItem on Ka0s Default is OptionsNav's entry paint
- skin controls: Drawer on Ka0s Default is OptionsDrawer's header paint
- skin controls: ListRow washes live under the row and follow the latest state
- skin controls: every primitive's second call makes no new frame, region or hook
- skin controls: every primitive's repaint reuses its regions and paints the new skin
- skin controls: a dark label is shadowless, a light one keeps its shadow
- skin controls: an EditBox hint and a sort header's texts take the skin's face
- skin controls: a slider's track is a thin bar centered in it

### test_skin_eui.lua (29)

- skin eui: SkinEUI attaches to the shell and makes no frame until an owner registers
- skin eui: without SkinEUI the engine keeps eui a stored choice on the owner's Ka0s skin
- skin eui: GetEUIStatus lists the four conditions and holds only when all do
- skin eui: gate with no EllesmereUI at all
- skin eui: gate with the Blizzard Skin child missing
- skin eui: gate with the master switch off
- skin eui: gate with the owner's entry off
- skin eui: gate with another addon's entry off
- skin eui: gate with the owner's entry nil
- skin eui: an owner registered before the EllesmereUI global exists is retried
- skin eui: PLAYER_LOGIN retries too, then lets go of both events
- skin eui: dispatch at login and registration after login both hand the facade
- skin eui: a newer minor loaded after registration still receives the facade
- skin eui: switching ka0s to eui hides the Ka0s paint and hands the frames to EllesmereUI
- skin eui: a facade arriving after the owner chose eui paints the frames then (late arrival)
- skin eui: the owner falls back to its Ka0s skin while the gate is closed
- skin eui: leaving eui after EllesmereUI painted asks for one reload and repaints nothing
- skin eui: leaving an eui EllesmereUI never painted repaints live, with no reload
- skin eui: a gate that closes after the paint asks for a reload and never falls back live
- skin eui: moving between Ka0s skins while on a painted eui with a closed gate asks for the reload
- skin eui: a facade missing a primitive is refused before any paint, latched and logged once
- skin eui: a misshapen facade closes the gate when it arrives, before the owner picks eui
- skin eui: a facade lacking only the optional SetTabSelection is accepted
- skin eui: a primitive that raises stops EllesmereUI painting the owner, once
- skin eui: Ka0s-only option keys are stripped before EllesmereUI sees a call
- skin eui: an eui-owned AceGUI CheckBox makes zero calls to EllesmereUI
- skin eui: another owner's frames and tokens never see EllesmereUI
- skin eui: EllesmereUI's live looks change repaints the Ka0s extras
- skin eui: EllesmereUIDB is read in LibKa0s/SkinEUI.lua and no other payload file

### test_skin_ace.lua (22)

- skin ace: an owned page's CheckBox is painted from the owner's skin through O.AceGUI
- skin ace: Ka0s Default paints AceGUI rows like every skin
- skin ace: an owner that ignores its settings panel gets stock rows until it stops
- skin ace: an unregistered owner's instance holds AceGUI itself
- skin ace: the proxy is AceGUI for everything but Create
- skin ace: an owner that registers after lib:New is proxied at CreateOptionsPanel
- skin ace: a released CheckBox is stock for the next acquirer outside Ka0s
- skin ace: another owner acquiring the pooled object wears its own skin, not the first's
- skin ace: every painted type is painted while owned and stock on its next acquisition
- skin ace: a SimpleGroup has no painter and is never wrapped
- skin ace: SetDisabled and SetValue keep the skin's colors and mark
- skin ace: the Slider's edit box keeps the skin's edge through AceGUI's hover recolor
- skin ace: a Label keeps the skin's font through its host's SetFontObject, and gives the host's back
- skin ace: a raising restore still returns the widget to the pool, logged once
- skin ace: a host OnRelease and the skin's restore both run, and a re-acquire is stock
- skin ace: a widget whose wrapper a host replaced is put back when it is acquired again
- skin ace: the dropdown's pull-out wears the owner's skin while open and is stock on close
- skin ace: Ka0s Default to Obsidian with a page open repaints its rows after the deferred re-render
- skin ace: an eui owner's rows are painted from EllesmereUI's colors with zero EllesmereUI calls
- skin ace: a widget another skinning addon skinned is left to it
- skin ace: PaintAceTree paints a host container's widgets
- skin ace: Skin:OnRelease chains once and answers its function

### test_widgets.lua (58)

- Widgets.Dropdown draws the host's chevron when it is given one
- Widgets.Dropdown falls to Blizzard's arrow with no host art
- Widgets.Dropdown builds its tick markup from the host's check art
- Two dropdowns can carry different art without either winning
- Browser menu: Populate shows one row per option and sizes the menu to them
- Browser menu: a freak label is capped at 320px
- Browser menu: the menu is never narrower than 90px, nor than its own dropdown
- Browser menu: rows are POOLED — a shorter dropdown hides the spares, never rebuilds
- Browser menu: multi-select ticks 'all' exactly when nothing is selected
- Browser menu: single-select marks the active value and never draws a tick
- Browser menu: selected rows go gold, the rest keep the value's own color
- Browser menu: a glyphed row shows its glyph and indents its text past it
- Browser menu: clicking a multi-select row toggles it and leaves the menu open
- Browser menu: clicking a single-select row sets the value and closes the menu
- A glyphed row is painted in the host's face on every pass
- A host that names no face gets no glyph column
- A row built with no face at all paints without raising
- A glyphless row paints without raising even when the host DID name a face
- A second dropdown repaints the pooled rows in ITS face, not the first one's
- A second dropdown ticks the pooled rows with ITS art, not the first one's
- Widgets.CloseMenu hides an open menu
- Widgets.CloseMenu is a no-op when the menu is already hidden
- Widgets.CloseMenu is a no-op when no dropdown has ever opened the menu
- The menu built on the first dropdown open is FULLSCREEN_DIALOG and clamped to the screen
- Widgets.CloseMenu leaves the unregistering to the menu's own OnHide
- A preset row lights up when its own predicate says so
- A preset row stays dark when its predicate says the selection is something else
- isActive is asked INSTEAD of the selection set, not alongside it
- A preset predicate works on a single-select dropdown too
- Clicking a preset row REPLACES the selection instead of toggling into it
- A dropdown with no presets toggles exactly as it did at minor 3
- A preset may override the 'all' sentinel itself
- The collapsed label takes an active preset's own label
- A selected value with no option row still counts in the summary
- A single selection with no option row reads as its raw value
- An empty selection still reads as the 'all' sentinel's own label
- One selection that IS in the option list reads as that row's label
- A preset row survives a REAL row build
- The menu builds no click-catcher at all
- An open menu listens for a mouse press anywhere
- A RIGHT-click outside closes the menu
- A LEFT-click outside closes the menu
- Any other mouse button closes it too
- A press ON the menu does not close it
- A press on the dropdown that dropped it does not close it
- A press on a DIFFERENT dropdown still closes the menu
- An event that is not GLOBAL_MOUSE_DOWN is ignored
- widgets: CopyWindow answers nil with no client
- widgets: CopyWindow requires an addon name
- widgets: CopyWindow fills in the collection's defaults
- widgets: CopyWindow honors an overridden descriptor
- widgets: the frame is built once and reused
- widgets: Show puts the text in the box and leaves it shown
- widgets: Show sets the text BEFORE it highlights
- widgets: the frame registers for Esc under its global name
- widgets: anchorTo is consulted on EVERY show
- widgets: CopyWindow names the scroll frame when asked (minor 7)
- widgets: CopyWindow leaves the scroll frame anonymous when not asked

### test_widgets_reorderlist.lua (24)

- widgets: ReorderList reports where a drag landed
- widgets: ReorderList says nothing for a drag that lands where it started
- widgets: ReorderList clamps a flat list to its own ends
- widgets: ReorderList keeps a drag inside its group when a boundary is set
- widgets: a boundary of 0 or the row count is one flat list
- widgets: a poll that never reports the button held cannot kill the drag
- widgets: every start path begins one drag and every end path completes it once
- widgets: ReorderList carries a copy of the row under the cursor
- widgets: the insertion line is ANCHORED to the target row
- widgets: a clamped drag still shows the line, stopped at the divide
- widgets: Cancel stops a drag in flight and puts the chrome away
- widgets: Cancel takes every handle OFF the host's frame
- widgets: a released handle is reused rather than a second one built
- widgets: a row may be registered with no handle at all
- widgets: a reused handle drives the LIVE controller, not the one it was built for
- widgets: the handle takes the hover color and drops it again
- widgets: a host may override both handle colors
- widgets: only the handle starts a drag
- widgets: every registered row gets a fill and four edges
- widgets: a dimmed row gets the muted variant, and a pooled box does not carry it over
- widgets: Cancel takes every box OFF the host's frame and back to the pool
- widgets: rowBox = false draws no box at all
- widgets: the handle owns the collection's 30px gutter unless the host says otherwise
- widgets: a box frame that cannot make textures is skipped rather than raising

### test_widgets_draghandle.lua (46)

- draghandle: it builds a named strip of the published height, hidden, with a label and a mark
- draghandle: with no parent, and in a process with no CreateFrame, it answers nil
- draghandle: a frame that cannot make textures is drawn without them rather than raising
- draghandle: the mark's ART is 8px -- the chevron's INK rather than the chevron's BOX
- draghandle: the mark is dimmed to the chevron's own tint, and brightens where a click is wired
- draghandle: a mark with no click behind it does not light up under the cursor
- draghandle: the mark's FRAME is the full strip height, so the art shrank and the target did not
- draghandle: the mark is anchored inside the strip's right end at the published inset
- draghandle: the label is drawn in the same face it is measured in, and one field sets both
- draghandle: the label is bounded by the reserve on both sides, and never wraps
- draghandle: a label far longer than the strip cannot reach the mark
- draghandle: it wears the host's help art, and falls to Blizzard's without any
- draghandle: Measure is the label plus the reserve each side of it keeps clear, twice
- draghandle: the reserve is its own terms, so the clearance beside the label can be changed alone
- draghandle: ApplyWidth floors the natural width at the host's minimum and returns it
- draghandle: SetLabel re-texts and re-measures, and touches no geometry of its own
- draghandle: a measurer the client cannot build is a width of 0, not a raise
- draghandle: the host's numeric guard is what reads every measurement
- draghandle: dragging the strip moves the host's frame and reports both ends
- draghandle: canDrag refuses, and a refused drag stops nothing either
- draghandle: the strip's drag scripts reach the help mark, so the '?' is not a dead zone
- draghandle: a host that passes no right-click leaves both frames unregistered
- draghandle: a host that passes one gets it on the strip and on the mark
- draghandle: no tooltip descriptor means no tooltip at all
- draghandle: the three bands are a gold title, white body lines, then a spacer and gray footer
- draghandle: with no surviving footer line there is no spacer either
- draghandle: the mark shows the same tooltip the strip does
- draghandle: a body line that answers nil is dropped, not drawn empty
- draghandle: a footer line is re-evaluated on EVERY hover, not captured at build time
- draghandle: the owner is the host's call, because for one host it is not a style choice
- draghandle: a second descriptor gives the mark its own tooltip, owner and anchor
- draghandle: a descriptor may own by the cursor while its neighbor owns by the frame
- draghandle: a line may carry its own color, so a gold line in a white band stays gold
- draghandle: the strip is a plain Button with a fill, never a BackdropTemplate
- draghandle: a host with its own edge painter gets its own pixels
- draghandle: DragHandle is at minor 3 or later, the close mark's minor
- draghandle: a spec with no onClose draws exactly the minor-2 strip, number for number
- draghandle: onClose builds an X the same frame and art size as the '?', immediately left of it
- draghandle: with no closeIcon the X falls to Blizzard's stop button
- draghandle: the X widens the reserve on BOTH sides, so the label stays centered
- draghandle: a left click on the X calls onClose once, and a right click does not
- draghandle: an X on a host with no right-click registers the left click alone
- draghandle: the X takes the strip's drag scripts, so a drag that starts on it moves the frame
- draghandle: the X brightens under the cursor and shows closeTooltip, owned by the X
- draghandle: an X with no closeTooltip shows the strip's, and follows a cursor owner
- draghandle: an X on a strip whose '?' could not be built sits where the '?' would

### test_widgets_draghandle_place.lua (10)

- draghandle: without tooltipPlace the call sequence is exactly minor 3's, for both owners
- draghandle: tooltipPlace owns by UIParent at ANCHOR_NONE, draws, shows, then places
- draghandle: tooltipPlace runs after Show, so the tooltip is measured when it is placed
- draghandle: the mark and the X hand tooltipPlace the frame hovered, not the strip
- draghandle: a tooltipPlace that raises falls back to the cursor and redraws the same lines
- draghandle: a tooltipPlace that answers anything but true falls back to the cursor
- draghandle: a descriptor's own place wins over the spec's, as owner and anchor do
- draghandle: a descriptor may place while the spec does not, and its neighbor is untouched
- draghandle: a tooltipPlace that is not a function is ignored, not called
- draghandle: DragHandle is at minor 4 or later, the placement hook's floor

### test_widgets_draghandle_layers.lua (10)

- DragHandle minor 5: MODULES and the file minor say 5
- DragHandle level: no spec.level keeps minor 4 -- handle at parent + 1, marks at handle + 1
- DragHandle level: level = 50 on a parent at 7 -- handle 57, marks 58, written before the marks exist
- DragHandle ApplyLevel: a parent re-leveled to 20 puts the handle at 70 and the marks at 71
- DragHandle ApplyLevel: without spec.level it answers false and writes nothing
- DragHandle level: a secret or non-number parent level reads as 0
- DragHandle level: the host's numeric guard reads the parent's level
- DragHandle ignoreParentAlpha: true sets it, absent leaves it false
- DragHandle ignoreParentAlpha: a frame without SetIgnoreParentAlpha does not error
- DragHandle level: onClose plus level builds both marks at handle + 1

### test_widgets_linechart_math.lua (21)

- chart math: the file attaches to the Widgets shell and records its minor
- chart math: NiceTicks picks a 1-2-2.5-5 step and covers the data
- chart math: NiceTicks widens a flat or empty range instead of dividing by zero
- chart math: NiceTicks with integer=true never steps below 1
- chart math: NiceTicks handles a range that crosses zero
- chart math: Downsample keeps at most one point per 2px and both endpoints
- chart math: Downsample hands a series that already fits back untouched
- chart math: Downsample keeps a one-point spike
- chart math: Budget never answers fewer than three points
- chart math: Budget takes a per-chart spacing and falls to the default for a bad one
- chart math: a larger spacing draws fewer points yet keeps the series' global min and max
- chart math: TimeTicks lands day steps on local midnight
- chart math: TimeTicks uses hour steps inside one day
- chart math: TimeTicks answers nothing for an empty span
- chart math: NearestIndex snaps to the closest x and clamps at the ends
- chart math: Dashes cuts a segment into dash-gap pieces along its length
- chart math: ClipSegment answers a segment inside the rectangle unchanged
- chart math: ClipSegment answers nil for a segment wholly outside
- chart math: ClipSegment cuts a segment at each edge it crosses, keeping its direction
- chart math: ClipSegment handles vertical and horizontal segments on either side
- chart math: ClipSegment keeps a degenerate point inside and drops one outside

### test_widgets_linechart.lua (19)

- line chart: Render draws the axis, one grid rule per y tick and one line per segment
- line chart: a second Render of the same data creates no new Line objects
- line chart: a smaller render hides the leftovers instead of leaving them drawn
- line chart: the plot never gets more than one point per 2px
- line chart: opts.pxPerPoint sets the point budget per chart; the default is unchanged
- line chart: a series maps its first point onto the plot's bottom-left corner
- line chart: a dashed range draws dashes, an undashed series one line per segment
- line chart: a marker inside the domain draws a dashed rule; outside it draws nothing
- line chart: HoverAtPixel snaps to the nearest x and calls onHover once per change
- line chart: OnLeave clears the hover the way ClearHover does
- line chart: Clear hides every line
- line chart: Render before SetData or at zero size draws nothing and does not raise
- line chart: HoverAtPixel with no scale or no hoverXs answers nil and tells the host nothing
- line chart: a one-point series still draws a visible mark
- line chart: a dashed range through a far off-plot point makes a bounded number of Lines
- line chart: a solid series through a far off-plot point is clipped to the plot rectangle
- line chart: a segment wholly outside the plot draws nothing, and so does a one-point series there
- line chart: a render under a resting cursor re-fires onHover and moves the crosshair to the new scale
- line chart: a render that leaves no scale hides the crosshair, and a later clear still tells the host

### test_widgets_autocomplete.lua (37)

- autocomplete: answers nil without a provider or without a box it can hook
- autocomplete: publishes its chrome, with the 0.15 s debounce floor and 8 rows by default
- autocomplete: typing asks the provider only after the debounce, once for a burst
- autocomplete: an opts.debounce under the floor is raised to it
- autocomplete: empty or blank text closes without asking the provider
- autocomplete: opts.minChars holds the list back until the trimmed text is that long
- autocomplete: an empty or nil provider answer hides the list and never raises
- autocomplete: at most maxRows rows, 8 by default
- autocomplete: Refresh asks the provider at once for the box's text
- autocomplete: the list hangs from the box's bottom corners, the box's width, in its own strata
- autocomplete: the list built on first show is at its strata and clamped to the screen
- autocomplete: the list wears the box's own border and background
- autocomplete: a box with no backdrop colors gets the house flat skin
- autocomplete: each row takes its item's color, in either shape, and plain text without one
- autocomplete: rows are pooled, and a shorter list hides the leftovers
- autocomplete: Down and Up move the selection, Up from the first row goes back to the text
- autocomplete: Enter picks the selected row, closes, and hands the host the item as provided
- autocomplete: Enter still picks when the host's own Enter clears focus first
- autocomplete: Enter with nothing selected closes and picks nothing
- autocomplete: Tab picks the selected row, or the first
- autocomplete: Esc closes and keeps the typed text
- autocomplete: a new keystroke drops the selection at once
- autocomplete: a click on a row picks it and closes
- autocomplete: focus lost elsewhere closes on the next frame
- autocomplete: focus lost to a press on the list keeps it, gives the box the keys back, and the row's click picks
- autocomplete: focus regained before the next frame keeps the list
- autocomplete: a debounce still waiting when focus goes shows nothing
- autocomplete: focus gained with text in the box offers the list again
- autocomplete: the host's own SetText closes the list, and the box hiding closes it
- autocomplete: Close hides the list and drops a waiting update
- autocomplete: SetEnabled(false) closes and ignores typing until enabled again
- autocomplete: Release leaves the hooks inert, and a second Autocomplete on the box replaces the first
- autocomplete: calling it again after a host SetScript dropped the hooks brings the list back
- autocomplete: calling it twice without a SetScript dispatches each script once
- autocomplete: a fractional maxRows is floored, and the list is exactly that many rows tall
- autocomplete: a maxRows that floors below 1 falls back to MAX_ROWS
- autocomplete: the backdrop is set once, and its colors follow a restyled box on every show

### test_widgets_searchbox.lua (16)

- SearchBox: wears the dropdown's skin, fill, line and height 20
- SearchBox: the dropdown's look is unchanged after the SKIN hoist
- SearchBox: small highlight face, no auto focus
- SearchBox: a number width is set, a nil width sets none
- SearchBox: the hint shows when empty, hides on text, shows again on clear
- SearchBox: a nil GetText counts as empty
- SearchBox: no hint opt gives an empty hint, still a FontString
- SearchBox: Escape and Enter clear focus
- SearchBox: focus gained paints the gold line, focus lost the gray one
- SearchBox: onChange gets (text, box) exactly once per change
- SearchBox: an icon path draws an 11x11 mark at LEFT+5 and insets the text 21
- SearchBox: no icon keeps box.icon nil and the text inset 6
- SearchBox: a numeric fileID is an icon too
- SearchBox: host hooks on OnTextChanged and OnEditFocusGained survive and run
- SearchBox: W.Autocomplete composes on it, and the hint still toggles
- SearchBox: the host rewrites the hint through box.hint:SetText

### test_widgets_teststrip.lua (17)

- TestStrip: born hidden, unanchored and 18 tall, with its regions
- TestStrip: the fill is the collection's amber at 12%, on all points
- TestStrip: an icon path draws a 12x12 mark at LEFT+6, text on its RIGHT+6
- TestStrip: no icon leaves __icon nil and the text at the strip's LEFT+6
- TestStrip: a numeric fileID is an icon too
- TestStrip: the text is GameFontNormalSmall, RIGHT at -6, LEFT-justified, no wrap
- TestStrip: opts.text is set; nil, non-table opts and non-string text give ''
- TestStrip: the constructor never enables the mouse; a host's tooltip hook runs
- TestStrip: a host's SetHeight and SetWordWrap stick
- TestStrip: a write to TEST_STRIP.HEIGHT does not move the next strip
- TestStrip: TEST_STRIP publishes HEIGHT and no RESERVE
- TestStrip: two strips share no regions
- TestStrip: kind = 'sim' fills the collection's simulation cyan at 12% and reads 'sim'
- TestStrip: the default and every kind that is not 'sim' give the amber and 'test'
- TestStrip: a sim strip has a test strip's height, icon, text, anchors, state and mouse
- TestStrip: a test strip and a sim strip side by side share no regions
- TestStrip: a write to strip.kind after birth does not repaint the fill

### test_widgets_reorder.lua (7)

- reorder: a host OnUpdate on a row frame survives a drag start and end
- reorder: a row frame with no OnUpdate is never given one
- reorder: two lists with different lineColor show their own color on one pooled container
- reorder: the drop line is released after Cancel
- reorder: the drop line goes back at the drop, and the next drag reuses it
- reorder: ReorderList lives in WidgetsReorder.lua at minor 1, paired on the live shell
- reorder: a payload without WidgetsReorder.lua loads whole, with no ReorderList

### test_widgets_skin.lua (24)

- skin owner: Core.ApplySkin and MakeCloseButton without a registered owner are minor 12's
- skin owner: Core.ApplySkin paints a registered owner's window from its skin and repaints it
- skin owner: a host's own skin table wins over the owner, and is never repainted
- skin owner: Core works with no Skin major, and resolves it at call time
- skin owner: MakeCloseButton takes a registered owner's close colors and follows a switch
- skin owner: Dropdown without a registered owner is minor 15's, button and menu
- skin owner: an owned Dropdown wears its owner's skin, and two owners stay apart
- skin owner: the shared menu follows its opener, and an owner-less open puts Ka0s Default back
- skin owner: a LootHistory open under Obsidian, then an owner-less open, shows Ka0s Default
- skin owner: SearchBox and TestStrip without a registered owner are minor 15's
- skin owner: an owned SearchBox paints its box, focus line and icon from the skin
- skin owner: an owned TestStrip takes its wash from the owner's skin
- skin owner: CopyWindow without a registered owner is minor 15's
- skin owner: a registered addon's CopyWindow wears its skin, dense fill and close button
- skin owner: Autocomplete without a registered owner is minor 3's
- skin owner: an owned Autocomplete colors its rows from the skin on every show
- skin owner: DragHandle without a registered owner is minor 5's
- skin owner: an owned DragHandle paints from its owner's skin and follows a switch alone
- skin owner: ReorderList without a registered owner is minor 1's, ghost included
- skin owner: an owned ReorderList draws boxes, handle, line and ghost from the skin
- skin owner: Ka0s Default draws the reorder list exactly as minor 1 did
- skin owner: LineChart without a registered owner reads lib.LINE_CHART as minor 3 did
- skin owner: an owned LineChart takes its chrome and series from ChartStyle and re-renders
- skin owner: Ka0s Default's eight Widgets tokens are the constants they replace

### test_debuglog.lua (75)

- dbg: FormatPlain wraps the tag in brackets with single-space separators
- dbg: FormatPlain tolerates a nil tag
- dbg: FormatColored colors the timestamp and tag; pipe and content default
- dbg: both formatters are reachable on an instance as well as on the library
- dbg: the window title is the host's, with the library's suffix appended
- dbg: a host can override the title suffix
- dbg: Add appends the plain form to the buffer and is never gated on the flag
- dbg: the cap is 3000 and the message frame is held to the same number
- dbg: the buffer is capped, dropping the oldest line
- dbg: the buffer stays a dense array of plain strings
- dbg: Clear wipes the buffer and works before the window was ever built
- dbg: BufferSize, LastLine and FindLine answer without reaching into .buffer
- dbg: at 2999 lines every public reader answers the newest MAX_BUFFER
- dbg: at 3000 lines every public reader answers the newest MAX_BUFFER
- dbg: at 3001 lines every public reader answers the newest MAX_BUFFER
- dbg: at 3100 lines every public reader answers the newest MAX_BUFFER
- dbg: the 3001st line drops the first
- dbg: 3129 adds cost at most one compaction, not one table.remove per line
- dbg: the raw buffer holds at most MAX_BUFFER + BUFFER_SLACK lines, and compacts in order
- dbg: the status line counts what the readers answer, not the raw array
- dbg: the sink routes the first arg as the [tag] and every vararg through safeToString
- dbg: the sink is a no-op, and does no work at all, when logging is off
- dbg: the sink is dot-callable, because host call sites bind it bare
- dbg: the sink survives a format the stringified args cannot satisfy
- dbg: an ordinary format is NOT routed through the fallback
- dbg: SetEnabled writes the flag through the host, not into the library
- dbg: SetEnabled normalizes a truthy value to a boolean
- dbg: enabling acks in green, brackets the session, then adds the [Init] summary
- dbg: disabling acks in red and the bracket line still lands after the flag flips
- dbg: disabling adds no [Init] summary
- dbg: a host with no initSummary gets the bracket line and nothing else
- dbg: the header toggle click flips the flag through SetEnabled
- dbg: Show builds and shows; Hide and IsShown never build
- dbg: Toggle builds the window on its first call
- dbg: showing and hiding the console tells the host
- dbg: two instances own separate buffers and separate frames
- dbg: the copy text is the whole buffer, in order, newline-joined
- dbg: Add sends the COLORED form to the console and the plain one to the buffer
- dbg: the window degrades to nothing when CreateFrame is unavailable
- dbg: ConsoleCheckbox get reflects window visibility, not the logging flag
- dbg: ConsoleCheckbox set shows and hides without touching the logging flag
- dbg: the ConsoleCheckbox tooltip names the host's own slash command
- dbg: a host with no slash command gets a tooltip that does not mention one
- dbg: New requires a name, a title, a font and an isEnabled/setEnabled pair
- dbg: a host that overrides a string gets its own wording
- dbg: DebugLog re-exports Core's close button so a host has one factory, not two
- dbg: a newer Core loading after DebugLog supplies the console's close button
- dbg: an instance built after the upgrade draws the newer Core's button
- dbg: Add renders a secret message as the sentinel
- an L whose metatable synthesizes every key does NOT mask the module's own strings
- a REAL entry in an L that also has a fallback still overrides
- a plain L table overrides exactly as before
- dbg: with no makeCloseButton, BOTH windows close with Core's x
- dbg: the default chrome IS the Ka0s window edge, on both windows
- dbg: a host can supply its own skin function, for both windows
- dbg: the host's skin function runs AFTER the Hide and the Esc wiring
- dbg: a host that supplies no skin function still gets the library's own
- dbg: a host can supply its own close-button factory, for both windows
- dbg: the host's close button actually closes the window
- dbg: a close-button factory returning nil is survivable, as Core's own is
- dbg: the title-bar offsets are derived from the close button's width
- dbg: with addonName the title bar draws icons, and they are narrower than the words
- dbg: an icon control carries NO tooltip
- dbg: the close button is told the addon name too, not just copy and clear
- dbg: the library's own close forwarder passes the name through to Core
- dbg: no addonName is the minor-8 title bar, word for word
- dbg: an addonName the art does not answer for falls back to words
- dbg: a wider host close button pushes Copy and Clear out of its way
- dbg: a close button with no measurable width falls back to the library's own
- dbg: with no close button at all the offsets are still the minor-3 defaults
- dbg: the copy window is built by Widgets.CopyWindow, not by this file
- dbg: the converged copy window keeps its named scroll frame
- dbg: the converged copy window keeps its global frame name
- dbg: the copy window still shows the whole buffer, in order
- dbg: the copy window re-anchors to the console instead of a fixed center

### test_debuglog_copytiming.lua (10)

- dbgtime: TIME_COPY is off at load, and the timing line's text is published in STRINGS
- dbgtime: with TIME_COPY off, ShowCopy reads no clock, queues nothing and prints nothing
- dbgtime: with TIME_COPY on, the next frame prints one exact timing line through emit
- dbgtime: the timing line never lands in the buffer it measures
- dbgtime: the timed open hands the window exactly CopyText, as the untimed one does
- dbgtime: the line counts the kept lines, not the raw array past the cap
- dbgtime: with no debugprofilestop, TIME_COPY opens the window untimed and prints nothing
- dbgtime: with no C_Timer, TIME_COPY opens the window untimed and prints nothing
- dbgtime: BUFFER_SLACK is published, and is 128 at minor 14
- dbgtime: Add reads BUFFER_SLACK at call time, like MAX_BUFFER

### test_debuglog_diagnostics.lua (47)

- diag: the caps are pinned as literals, and the file registers under the major
- diag: both markers carry the brand, and the end marker counts every line
- diag: with no brandName the markers name the title
- diag: the identity header names the host, the client, the flags and the running minors
- diag: the running-minors header covers every major tests/majors.lua ships
- diag: a combat read that raises prints unreadable and costs nothing else
- diag: an initSummary that raises prints unreadable and the header still follows
- diag: BuildDiagnostics writes nothing
- diag: the report appends, and the trace before it survives
- diag: the report never calls Clear
- diag: a run with logging off turns it on first, through the one seam
- diag: opted out, the report is ungated: it lands with logging off and leaves it off
- diag: only false opts out; true turns logging on like the default
- diag: with logging already on, the run writes no second enable line
- diag: a run never turns logging off, opted out or not
- diag: RunDiagnostics prints one chat line with the count and returns it
- diag: the chat line is the host's when L overrides it
- diag: RunDiagnostics shows a hidden console
- diag: the report repaints once, not once per line
- diag: sections are asked for at run time, so one added after New still reports
- diag: spec.sections replaces the host's list
- diag: a raising section costs exactly one line, and the next section still runs
- diag: a raising section list costs one line
- diag: an over-cap report keeps two lines for the truncated line and the end marker
- diag: the cap is clamped a hundred lines below the buffer
- diag: an uncapped report writes no truncated line
- diag: a per-list cap sets the flag the truncated line reports
- diag: a list under its own cap is written whole and sets nothing
- diag: out:add strips color, texture, atlas and hyperlink escapes
- diag: out:escape doubles the pipe, and the doubled pipe survives the strip
- diag: a secret value goes through safeToString and does not raise
- diag: out:readable refuses what the client calls secret
- diag: out:joined wraps at 200 characters and writes `lead -` for nothing
- diag: out:section nests a pcall of its own
- diag: out:nonDefaults prints what differs, skips session-only and hidden rows
- diag: DebugVerb runs the report for `diagnostics`, in any case
- diag: DebugVerb sets the flag for on and off
- diag: DebugVerb answers false for anything else and writes no report
- diag: the three instance members a consumer's DebugLog stub must carry
- diag: without the secondary file an instance has no report methods
- diag link: the console draws it when the instance has RunDiagnostics
- diag link: its label is a module string the host's L overrides
- diag link: not drawn when the diagnostics file did not install the report
- diag link: anchored to the right edge of the Debug On/Off label, with a gap
- diag link: orange at rest, brighter under the pointer, orange again after
- diag link: a click runs the report with logging off, and turns it on first
- diag link: opted out, a click writes the report and leaves logging off

### test_debuglog_gates.lua (20)

- gates: the file registers under the major, paired on the live shell, with its bound pinned
- onClear: absent, Clear empties the buffer and writes nothing (the silent default)
- onClear: a non-function field is ignored, as every optional descriptor field is
- onClear: called once per Clear, after the buffer is empty, and its own line lands
- onClear: a raising hook costs one line, not the Clear
- onClear: not called by turning logging on or off
- DebugOnce: the first call per key writes, formatted as D.Debug formats, and the rest do not
- DebugOnce: logging off writes nothing, remembers nothing and builds nothing
- DebugOnce: Clear re-arms every key
- DebugOnce: turning logging on re-arms every key
- DebugChanged: writes the first line, holds a repeat, and writes a change
- DebugChanged: keys are independent, and a new tag is a change
- DebugChanged: logging off writes nothing, remembers nothing and builds nothing
- DebugChanged: Clear and turning logging on both re-arm it
- DebugForget: re-arms one key in both gates and leaves the others
- gates: a nil key is a key of its own, not a raise
- gates: past GATE_MAX_KEYS keys the memory is wiped rather than grown
- gates: plain functions, bound bare as hosts bind D.Debug
- gates: secret-safe, and an unsatisfiable format still lands as D.Debug's does
- gates: an instance built without DebugLogGates.lua has no gates, and onClear still fires

### test_debuglog_descriptor.lua (7)

- dbg descriptor: a non-table descriptor is refused like an empty one, naming the first field
- dbg descriptor: fontSize defaults to 10 and a non-number reads as absent
- dbg descriptor: an empty slash is no slash, so the tooltip names none
- dbg descriptor: an L that is not a table reads as absent
- dbg descriptor: with no print the acknowledgment reaches DEFAULT_CHAT_FRAME
- dbg descriptor: a safeToString that is not a function falls back to Core's
- dbg descriptor: a skin that is not a table falls back to Core.SKIN, and a table is handed on

### test_resize_windows.lua (23)

- resize console: the default size is still 700 x 344
- resize console: it has a grip and bounds that keep the title bar's controls clear
- resize console: the icon controls are narrower, and so is the minimum
- resize console: the Diagnostics link widens the left group, and the minimum grows
- resize console: a resize resyncs the scrollbar and the line counter, and keeps the buffer
- resize console: the line counter sits clear of the grip
- resize console: the size survives a hide and a show
- resize console: two hosts' consoles resize independently
- resize console: with no MakeResizable in Core it is today's fixed window
- resize copy: a copy window opens at its descriptor's size
- resize copy: it has a grip and a minimum on both axes
- resize copy: the scroll bar's down button sits above the grip
- resize copy: a window declared smaller than the minimum is its own minimum
- resize copy: the edit box width tracks a resize
- resize copy: the size, and the edit box's width, survive a hide and a show
- resize copy: two named copy windows resize independently
- resize copy: the debug console's copy window resizes too
- resize copy: with no MakeResizable in Core it is today's fixed window
- resize panel: the panel opens at today's computed size
- resize panel: width only, with today's width the minimum
- resize panel: a resize stretches every step row
- resize panel: the width survives a hide and a show
- resize panel: with no MakeResizable in Core it is today's fixed panel

### test_tool_windows_layering.lua (8)

- tool windows: the console, the perf panel and the sim panel are DIALOG, toplevel and clamped
- tool windows: the console's copy window is FULLSCREEN and not toplevel
- tool windows: showing each window raises a shown StaticPopup once and a hidden one never
- tool windows: with no StaticPopup globals nothing is raised and nothing errors
- tool windows: an erroring Raise on a popup is swallowed
- core: RaiseStaticPopups answers the count raised and honors STATICPOPUP_NUMDIALOGS
- core: RaiseStaticPopups never shows, hides or re-stratas a popup
- tool windows: with no RaiseStaticPopups in Core the three windows build and show

### test_tool_windows_skin.lua (14)

- tool windows skin: without a registered owner each window is the previous minors' paint
- tool windows skin: an unregistered console logs Ka0s Default's colored line, as before
- tool windows skin: a registered owner's console paints from its skin
- tool windows skin: an owned console logs in its skin's colors and re-colors the log on a switch
- tool windows skin: a skin switch repaints the console, and Ka0s Default is today's paint
- tool windows skin: an owned console's copy window wears the owner's skin
- tool windows skin: a host's own skin or applySkin keeps the console out of the owner's skin
- tool windows skin: two owners' consoles stay isolated
- tool windows skin: a registered owner's perf panel paints its window and step colors
- tool windows skin: an owned perf panel on Ka0s Default draws the constants
- tool windows skin: a registered owner's sim panel paints its window, rows and buttons
- tool windows skin: an owned sim panel on Ka0s Default draws the constants
- tool windows skin: Ka0s Default's tool-window tokens are the constants the windows drew
- tool windows skin: every skin's tool-window text reads on its own window

### test_slash.lua (74)

- sl: an empty message runs the host's config verb (minor 11), printing no help
- sl: whitespace-only input is treated as empty
- sl: a host with no config verb still gets the help index for an empty message
- sl: `help` prints the help index
- sl: an unknown verb names it, then prints the help index
- sl: the verb is lowercased but the argument keeps its case
- sl: an alias is rewritten to its target verb
- sl: a handler receives the rest of the line, not the verb
- sl: New requires a slash prefix and a commands table
- sl: a help row is gold command, single-spaced em dash, white description
- sl: HelpRows indents for chat; LandingRows does not
- sl: help rows name each verb with the host's own slash prefix
- sl: the help header carries the version and the chat alias
- sl: a host with no chat alias gets a header without the alias clause
- sl: no rendered line ends in a colon
- sl: FormatKV is a gold key, ' = ', a white value, and no trailing colon
- sl: FormatValue renders every schema type the library knows
- sl: a color channel the stored table omits falls back per channel, alpha to 1 and RGB to 0
- sl: a number row with no fmt renders bare
- sl: a row whose value does not fit its declared type falls through to the generic renderer
- sl: FormatValue renders a secret as the sentinel on every formatting branch
- sl: FormatValue reads a POSITIONAL color as well as a named-key one
- sl: a positional color with a secret component still renders the sentinel
- sl: a host color codec round-trips through set and its echo
- sl: CliReset's echo uses the host color codec too
- sl: a guarded FormatValue still survives the FormatKV string.format around it
- sl: SplitVerb lowercases the verb and preserves the remainder's case
- sl: SplitVerb keeps the remainder's internal spacing
- sl: SplitVerb answers two empty strings for empty and nil input
- sl: SplitVerb answers an empty remainder for a bare verb
- sl: FindCommand returns the whole triple for a matching name
- sl: FindCommand compares verbatim and answers nil for a miss
- sl: FindCommand answers nil rather than raising on a missing list
- sl: CommandRows renders one row per entry through the shared formatter
- sl: CommandRows defaults to no indent and applies the one it is given
- sl: CommandRows answers an empty list rather than raising on a missing table
- sl: HelpRows and LandingRows render through CommandRows
- sl: list groups rows under the host's own group keys, indented
- sl: the list keeps its own colors — green header, azure group headings
- sl: list says so when nothing is registered
- sl: get echoes the canonical path and the stored value
- sl: a stored false renders as false, not as nil
- sl: get with no path prints usage; an unknown path says so
- sl: set writes through the host and echoes what was STORED, not what was typed
- sl: set with no path points at the list verb
- sl: a rejected value is not written, and the reason is a second, indented line
- sl: set accepts a value made of several tokens
- sl: reset restores one setting to its default
- sl: reset leaves every other setting alone
- sl: reset with no path prints usage; an unknown path says so
- sl: reset does not lowercase its argument
- sl: resetall applies every row's default
- sl: resetall brackets its walk, and acknowledges after the bracket closes
- sl: a row that raises inside resetall still closes the bracket; the error propagates and nothing is acknowledged
- sl: resetall with no applyDefault still brackets, and counts zero rows written
- sl: resetall hands bulkEnd an info whose profileReset is false, and the host logs [Set] reset all: N rows
- sl: resetall with NO bracket is minor 7's walk — an error escapes with its own stack
- sl: version prints one line and nothing else
- sl: the annotator fires on list, get and set — and on nothing else
- sl: the annotation follows the colored pair rather than interrupting it
- sl: with no annotator set, nothing is appended
- sl: Slash refuses to register without Core
- sl: an L whose metatable synthesizes every key does NOT mask the module's strings
- sl: a REAL entry in an L that also has a fallback still overrides
- sl: a plain L table overrides exactly as before
- slash: a host can supply its own value formatter for a type the library does not know
- slash: the format hook reaches the get, set and reset echoes too
- slash: a host with no format hook renders exactly as it always did
- slash: the format hook takes precedence over the color codec, and gets the raw stored value
- slash: format beats colorDecode at the get, set and reset echoes, and colorEncode still runs
- sl: New refuses a non-table descriptor, an empty slash and non-table commands, in its own words
- sl: with no print the dispatcher writes to DEFAULT_CHAT_FRAME
- sl: with no groupKey the list groups rows by page, and a row with none under 'settings'
- sl: an L, aliases or liveVerbs that is not a table, and a parse that is not a function, read as absent

### test_slash_parse.lua (33)

- sl: ParseBool accepts the same eight words the error string advertises
- sl: ParseBool answers nil, never false, for a non-boolean word
- sl: booleans accept the whole human vocabulary
- sl: a junk boolean is rejected and the accepted words are listed
- sl: a number is clamped to the row's range rather than rejected
- sl: a non-numeric value for a number row is rejected
- sl: a number row refuses nan and infinities with the not-a-number reason
- sl: a finite number still parses, on an unbounded and a bounded row
- sl: a string is validated against its enum, case-sensitively
- sl: an enum declared as an ordered array is offered in declaration order
- sl: an ordered array supplied as a function is evaluated at parse time
- sl: a numeric dropdown rejects an out-of-list value rather than clamping it
- sl: a number row with no values list still clamps to min/max
- sl: a string row with no values list accepts free text
- sl: a free-text string row keeps every word of a multi-word value
- sl: a string enum accepts an entry that contains spaces, in both enum shapes
- sl: a string value is trimmed at both ends before it is stored or validated
- sl: an empty or blank string value is still refused with 'expected a value'
- sl: bool, number and color rows still read tokens exactly as before
- sl: set stores a multi-word free-text value whole, through the dispatcher
- sl: a key SET labels its entries with its keys, not with 'true'
- sl: an enum supplied as a function is evaluated at parse time
- sl: a color parses r g b with an optional alpha
- sl: a color given in 0-255 is rescaled, and all three channels together
- sl: a color missing a channel is rejected with the expected form
- sl: an unknown row type is rejected by name
- sl: the host's L reaches every parse refusal through set
- sl: the host's L reaches the empty-string formatter through get
- sl: a key-echoing L still falls through to the library's parse strings
- sl: ParseValue and FormatValue take an optional resolver, and default to the library's strings
- sl: a host's own parse is handed the instance's resolver as a third argument
- sl: the parser lives in SlashParse.lua at minor 2, paired on the live shell
- sl: a payload without SlashParse.lua loads whole, and set refuses naming the file

### test_slash_disabled.lua (16)

- sl: the refusal line's shape is the collection's, down to the color and the dash
- sl: an absent isEnabled leaves the dispatcher behaving exactly as it did at minor 11
- sl: isEnabled without brandName is refused at New, not rendered as 'nil is disabled'
- sl: a FEATURE verb answers exactly one refusal line and reaches no write seam
- sl: the reserved verbs and the whole schema CLI answer NORMALLY while disabled
- sl: the bare command opens the panel, and a TYPO gets the unknown-command line
- sl: an alias onto a gated verb is refused, and an alias onto a live one is honored
- sl: enable answers normally and is the way back
- sl: disable ECHOES the write rather than refusing, and is idempotent
- sl: help prints the full index with the refusal line under its header, unindented
- sl: help enabled prints no refusal line at all
- sl: liveVerbs defaults to the standard's thirteen reserved verbs and is overridable as DATA
- sl: a disabled host that ships diagnostics runs it, by the default live set (minor 16)
- sl: a reserved verb the host never shipped is not refused, in either state
- sl: the gate is asked per dispatch, so a value that changes mid-session is honored
- sl: the refusal wording is NOT reachable through the locale override

### test_slash_refusal.lua (7)

- sl refusal: a set answering false, err, why prints INVALID and the reason, and no echo
- sl refusal: an err that is not the INVALID line itself is printed indented, before why
- sl refusal: a refusal with no err and no why prints the INVALID line alone
- sl refusal: a set answering true echoes the stored value
- sl refusal: a set answering nothing still echoes, as at minor 14
- sl refusal: CliReset prints NO_DEFAULT when applyDefault answers exactly false
- sl refusal: CliReset echoes when applyDefault answers nil or true

### test_slash_profile.lua (30)

- sl profile: every string is a lib.STRINGS key, worded as the spec gives it
- sl profile: `profile` is neither live while disabled nor added to lib.LIVE_VERBS
- sl profile: bare `profile` lists every profile sorted case-insensitively, current marked
- sl profile: whitespace alone, and an empty pair of quotes, list rather than switch
- sl profile: the list header is colored like the settings list's, and carries no colon
- sl profile: a store that omits the current profile from GetProfiles still lists it
- sl profile: an existing name switches, once, and says so
- sl profile: surrounding double quotes are stripped, and the name inside is trimmed
- sl profile: surrounding single quotes are stripped too
- sl profile: inner spaces are kept, so an unquoted name with a space still switches
- sl profile: only ONE matching pair is stripped; a lone or mismatched quote is part of the name
- sl profile: case is kept — `alt` is not `Alt`, and is refused with a did-you-mean
- sl profile: the current profile answers Already, and SetProfile is not called
- sl profile: an unknown name is refused with the list, and nothing is created
- sl profile: did-you-mean only when exactly one stored name matches case-insensitively
- sl profile: in combat an existing name is refused and SetProfile is not called
- sl profile: combat does not stop the list, Already, or an unknown-name refusal
- sl profile: a client with no InCombatLockdown switches
- sl profile: a host with no `profiles` field prints the unavailable line and nothing else
- sl profile: a `profiles` function answering nil is the same as no field
- sl profile: a store missing any of the three methods is unavailable, and never half-called
- sl profile: the store is asked for at call time, never cached at New
- sl profile: lib.ProfileNames answers the sorted names and the current one
- sl profile: lib.ProfileNames breaks a case-only tie deterministically
- sl profile: lib.ProfileNames on no store, or a store without methods, answers an empty list
- sl profile: ProfileSwitch takes an already-parsed name, keeping its quotes, and answers true on a switch
- sl profile: ProfileSwitch with no store prints the unavailable line and answers false
- sl profile: through OnSlash the name keeps its case and its quotes are stripped
- sl profile: the descriptor's L reaches every profile string
- sl profile: no line any path prints ends in a colon

### test_slash_debug.lua (14)

- sl debug: Slash is at minor 18 or later
- sl debug: the disabled gate refusing a feature verb writes one Cmd line
- sl debug: an unknown verb writes one Cmd line
- sl debug: an unknown verb while disabled is still an unknown verb, not the gate
- sl debug: get's usage and not-found refusals
- sl debug: set's usage, not-found and parse refusals
- sl debug: a write the host's set refuses names the reason
- sl debug: reset's usage, not-found and no-default refusals
- sl debug: the profile verb's refusals, combat included
- sl debug: a command that is answered writes no line
- sl debug: a live verb while disabled writes no line
- sl debug: with no debug passed, every refusal still answers and nothing raises
- sl debug: a non-function debug field is ignored
- sl debug: the chat is byte for byte the same with and without a debug sink

### test_launcher.lua (45)

- launcher: New refuses a descriptor missing name, icon or openSettings
- launcher: ONE object, of type 'launcher', carrying the host's own icon
- launcher: both registrations use the addon's folder name, and a host may relabel
- launcher: Register is idempotent, so a second call builds no second button
- launcher: IsRegistered is false until BOTH halves are wired
- launcher: the library ALWAYS draws the tooltip, and a host need pass nothing
- launcher: the tooltip title is the label, and the version where one is passed
- launcher: the tooltip's Enabled line is green Yes or red No, read from isEnabled
- launcher: the click hints are fixed, in either state, whatever retired fields are passed
- launcher: every combination of state and status lines draws the fixed shape
- launcher: tooltip Locked and Test mode values are green for Yes/On, red for No/Off
- launcher: the host's tooltip lines are appended ONCE, below the status, above the hints
- launcher: tooltip status is read on EVERY show, never cached
- launcher: a raising tooltip accessor or host hook costs its own line, not the tooltip
- launcher: a tooltip argument with no AddLine is left alone
- launcher: every tooltip string goes through the descriptor's L, rawget-guarded
- launcher: minor 5 is live
- launcher: left-click opens the settings panel, enabled or disabled
- launcher: onClick, leftClickLabel, disabledLine and slash are retired and ignored
- launcher: right-click opens the client's context menu, titled with the label
- launcher: the menu carries one checkbox per supplied toggle, in the one order
- launcher: an accessor without its toggle, or a toggle without its accessor, draws nothing
- launcher: each checkbox shows the state its accessor answers when the menu opens
- launcher: each entry toggles through its host function exactly once
- launcher: while disabled, Enabled stays live and the rest are grayed with the note
- launcher: a grayed entry clicked anyway calls no handler and writes nothing
- launcher: a host with no isEnabled has nothing grayed and no Enabled entry
- launcher: with no MenuUtil, right-click degrades to the settings panel
- launcher: a raising toggle or menu API is reported and never escapes
- launcher: a raising accessor costs its checkmark, not the menu
- launcher: every menu string goes through the descriptor's L, rawget-guarded
- launcher: the host's OWN minimap table is handed to LibDBIcon, never a copy
- launcher: the minimap table is resolved at REGISTER time, not at New
- launcher: IsShown reads LibDBIcon's own `hide` key and inverts it
- launcher: SetShown writes `hide` and drives LibDBIcon's Show / Hide
- launcher: the debug seam reports under the Launcher tag
- launcher: with no LibDataBroker there is no object, and nothing raises
- launcher: with no LibDBIcon the broker plugin still registers; the button does not
- launcher: two Register calls with no LibDBIcon print NO_ICON once
- launcher: STRINGS carry no [LibKa0s] tag, because the host printer adds its own
- launcher: SetShown still records the player's choice where LibDBIcon is absent
- launcher: a descriptor whose minimap answers no table refuses the button and says why
- launcher: a name LibDataBroker already holds takes that object rather than none
- launcher: a host locale overrides a report, and a key-echoing fallback does not
- launcher: with no descriptor print, a report reaches the chat frame

### test_atenable.lua (21)

- atenable: the instance carries DebugAtEnable, with its bound pinned
- atenable: logging on, the line is written at once, formatted as D.Debug formats
- atenable: logging off, nothing is written; turning logging on writes it after the bracket
- atenable: held lines flush in the order they were written
- atenable: the flush is one-shot, a second enable edge does not repeat it
- atenable: an identical line already held is held once
- atenable: past AT_ENABLE_MAX the later lines are dropped, and one line says how many
- atenable: Clear neither drops nor flushes a held line
- atenable: turning logging off does not flush
- atenable: a held line is secret-safe, and an unsatisfiable format still lands
- atenable: plain function, bound bare as hosts bind D.Debug
- atenable: nothing held, turning logging on writes only the bracket (the silent default)
- atenable: an instance built without DebugLogGates.lua has no queue, and enabling still works
- launcher: neither debug nor debugAtEnable passed, Register is silent and does not raise
- launcher: with debugAtEnable, the registration line goes to it, not to debug
- launcher: with debug alone, the registration line goes to debug, as before minor 5
- launcher: a missing minimap table is a state line, held for enable
- launcher: a missing LibDataBroker is a state line, held for enable
- launcher: a missing LibDBIcon is a state line, held for enable
- launcher: event lines (shown / hidden) stay on debug when debugAtEnable is passed
- launcher: end to end, a Register at OnEnable lands the first time logging is turned on

### test_options.lua (61)

- options: the major registers all three of its files
- options: an instance carries the shell, the widget makers and the scroll patch
- options: two instances own separate panel registries
- options: CreatePanel returns a ctx wired to a panel, a body and an empty refresher list
- options: CreatePanel names the panel with the plain title for the category tree
- options: CreatePanel starts the panel hidden and registers it
- options: the header title takes the parent breadcrumb, and isMain opts out
- options: __panelFor finds a registered page by key
- options: SelectTab sets a rendered page's active tab and refreshes
- options: SelectTab refreshes only the target page, not every rendered page
- options: SelectTab reports false for a page that has never been rendered
- options: CreatePanel only DECLARES the Defaults button, never builds it
- options: CreatePanel records no Defaults intent when the page did not ask
- options: EnsureDefaultsButton builds it once, wires the parked handler, then no-ops
- options: EnsureDefaultsButton is a safe no-op without AceGUI and on a nil panel
- options: EnsureDefaultsButton leaves a panel that never wanted one alone
- options: EnsureDefaultsButton survives a vendored copy whose widget makers never attached
- options: RestoreDefaults resets every row on the named page and no other
- options: RestoreDefaults runs the ctx refreshers, and survives one that throws
- options: RestoreDefaults on a page with no rows is a harmless no-op
- options: RestoreDefaults resets a page across EVERY filter value, unlike RenderSchema
- options: RestoreAllDefaults resets every row, then fires the host's afterRestoreAll
- options: with resetProfile supplied, only the sessionOnly rows are walked
- options: resetProfile runs BEFORE afterRestoreAll, which runs before the refresh
- options: the narrowing is applied BEFORE skipRestoreAll is consulted
- options: with NO resetProfile the reset is exactly what it always was
- options: RestoreAllDefaults fires afterRestoreAll BEFORE refreshing the panels
- options: RestoreAllDefaults honors the host's skipRestoreAll veto
- options: LSMValues returns a DEFERRED closure, not a snapshot
- options: LSMValues offers a None placeholder rather than an empty list
- options: __PatchLSM30Border is published on the library, not on an instance
- options: __PatchLSM30Border registers once and the second call is a no-op
- options: the patched constructor hides the preview tile and re-anchors the bar
- options: __PatchLSM30Border stays armed while the widget is absent
- options: EnsureScroll is lazy, created once, and patched
- options: OptionsScroll.lua owns the font preload; without it a show still renders
- options: the scrollbar patch is idempotent
- options: FixScroll disables the bar when the content fits, enables it when it does not
- options: OnRelease restores AceGUI's own FixScroll and clears the marker
- options: CreatePanel stamps the three Blizzard canvas callbacks
- options: OnCommit and OnRefresh are inert and safe to call
- options: OnDefault forwards to a defaultsOnClick parked AFTER CreatePanel
- options: OnDefault and the header Defaults button run the SAME action
- options: a page with no defaults action still has a callable, inert OnDefault
- options: every lib.LAYOUT key is either published on the instance or annotated internal
- options: the published layout scalars are the instance's own, never lib.LAYOUT itself
- options: the landing constants are published on lib.LAYOUT at the promoted values
- options: LANDING_GAP_HEAD and SECTION_BOTTOM_SPACER are the same gap
- options: a host wires the landing body itself, through the buildMain it always had
- options: the shell installs no main renderer of its own, whatever else the descriptor carries
- options: the shell never writes buildMain onto the host's descriptor
- options: a descriptor with no buildMain draws no main body
- options: a disabled bar parks the thumb, dims it, and disables both step buttons
- options: an enabled bar tints the thumb white and enables both step buttons
- options: a state change fires once, not once per FixScroll
- options: a nameless scrollbar resolves no step buttons and still patches
- options: a fresh panel reserves no chrome, so its scroll sits where it always did
- options: reserving chrome pushes the scroll down by exactly that many pixels
- options: reserving chrome AFTER the scroll exists re-anchors the live scroll
- options: ClearScroll leaves the reserved band alone
- options: ClearScroll resets BOTH heading trackers

### test_options_render.lua (25)

- options: RefreshAllPanels runs every registered panel's refreshers, isolating a thrower
- options: registered page builders run in registration order, once, at CreateOptionsPanel
- options: CreateOptionsPanel hands the host the AceGUI it resolved
- options: CreateOptionsPanel says so and returns when AceGUI is missing
- options: the main canvas is registered under the host's brand
- options: the main page's body is deferred to its first OnShow, and built once
- options: a raising page builder costs that page and no other
- options: a page registered after the build is built immediately
- options: SetRenderer draws on first show, and not again
- options: a panel shown during combat is covered, not drawn, and the window is NOT closed
- options: a raising renderer is reported, not propagated
- options: RefreshScalars re-syncs a shown page and flags a hidden one dirty
- options: a dirty hidden page re-renders on its next show
- options: the two tiers differ — one re-renders, the other only re-syncs
- options: RefreshPanel touches ONE page, on both tiers
- options: a structural refresh of a page on screen keeps its scroll offset
- options: RefreshPanel defers a hidden page to its next show
- options: RefreshPanel ignores a non-ctx rather than raising
- options: a ctx that never went through SetRenderer keeps the old ungated behavior
- options: OpenOptionsPanel REFUSES under combat and does not defer-and-replay
- options: OpenOptionsPanel opens the registered category out of combat
- options: :New refuses a descriptor with no mainPanelName
- options: a host that omits print still sees the combat refusal in the chat frame
- options: CreateOptionsPanel is idempotent in both the category and the refreshers
- options: OpenOptionsPanel is a silent no-op before CreateOptionsPanel has run

### test_options_bulk.lua (11)

- options: RestoreDefaults brackets its page walk — begin, every row, end with the count, then the refresh
- options: RestoreAllDefaults brackets the whole act — rows, afterRestoreAll — and refreshes after the end
- options: with resetProfile the bracket spans the session rows, the profile reset and the hook
- options: a row that raises mid-walk still closes the bracket, then the error propagates
- options: the bracket closes when afterRestoreAll or bulkBegin itself raises
- options: either half of the bracket works alone
- options: a host mutes its seam's [Set] inside the bracket and logs ONE line — the documented worked example, a page reset
- options: a profile-reset RestoreAllDefaults is ONE line, the profile handler's — bulkEnd's info says so and the host adds nothing
- options: without resetProfile, RestoreAllDefaults' info.profileReset is false and the host logs [Set] reset all: N rows, N the rows actually written
- options: a resetProfile that raises leaves info.profileReset false and hands bulkEnd the error
- options: with NO bracket the walk is exactly minor 15's — same calls, same order, and an error escapes with its own stack

### test_options_fontpreload.lua (11)

- fontpreload: the first panel OnShow loads each LSM font path exactly once
- fontpreload: the strings live on one shown, full-alpha frame parented to UIParent
- fontpreload: a second show, and a second host's panel, load nothing new
- fontpreload: a font registered after the preload is loaded when it registers
- fontpreload: no registration callback before the first show
- fontpreload: no LibSharedMedia is no error and creates nothing
- fontpreload: no CreateFrame is no error, and the next show can still load
- fontpreload: a SetFont that raises costs that face and nothing else
- fontpreload: a show locked for combat loads nothing; the next show does
- fontpreload: a page with no renderer loads on its show too
- fontpreload: the main page loads on its first show, with a buildMain and without

### test_options_widgets.lua (53)

- widgets: the cross-slice layout constants are published on the instance
- widgets: a bool row renders a CheckBox labeled and seeded from the schema
- widgets: clicking a checkbox writes through the descriptor's set
- widgets: a checkbox registers a refresher that re-reads after an external change
- widgets: every widget gets tooltip callbacks wired from the schema desc
- widgets: relativeWidth is applied when given, full width otherwise
- widgets: SessionCheckbox reads and writes the caller's get/set, never the store
- widgets: a number row renders a Slider carrying the schema's range and step
- widgets: a slider falls back to the row default when the stored value is not a number
- widgets: releasing a slider snaps the value to the row's step
- widgets: slider snapping is relative to the row's min, not to zero
- widgets: a string row with values renders a Dropdown, sorted alphabetically by default
- widgets: a row with explicit `sorting` keeps that order instead of alphabetizing
- widgets: a dropdown falls back to a plain Dropdown when its dialogControl is unregistered
- widgets: a dropdown uses its dialogControl widget when that IS registered
- widgets: a dropdown writes the chosen value, and its refresher re-applies the LIST
- widgets: a dropdown built from an ordered array keeps declaration order
- widgets: a key set labels its entries with its keys, not with 'true'
- widgets: the dropdown's options and the CLI's allowed values agree, in both shapes
- widgets: a color row opts OUT of alpha by declaring it, and cannot before
- widgets: a tooltip body comes from `tooltip`, with `desc` still accepted
- widgets: a slider does not commit on drag by default
- widgets: sliderCommit = 'change' commits on drag, throttled, last value wins
- widgets: commitOn on a row overrides the descriptor default, both ways
- widgets: a string row asking for an EditBox gets one, not a dropdown
- widgets: an edit box commits on OnEnterPressed and re-reads on refresh
- widgets: a color row renders a ColorPicker seeded through the descriptor's codec
- widgets: a color picker substitutes 1s for a missing or corrupt stored color
- widgets: the color codec is the descriptor's, so an array-storing host is not translated
- widgets: disabledIf grays the swatch out while its sibling toggle is on
- widgets: a function disabledIf disables every maker and is re-evaluated on refresh
- widgets: a path disabledIf disables every maker while that setting is on
- widgets: a row with no disabledIf never has its disabled state touched
- widgets: a disabledIf predicate that raises leaves the row drawn and enabled
- widgets: RenderRows opts.disabled disables every widget it draws, after-group ones included
- widgets: a disabled render's flag never leaks into a later render or into its refresh
- widgets: a render nested inside a disabled render inherits the disable
- widgets: an afterGroup hook that raises still propagates, and the flag is cleared
- widgets: OnValueConfirmed commits immediately — cancel must not wait on the throttle
- widgets: OnValueChanged throttles a drag to ONE timer and commits the LAST value
- widgets: a color drag does NOT refresh every panel
- widgets: every other maker's write DOES refresh every panel
- widgets: RenderField dispatches each schema type to its widget
- widgets: RenderField returns nil for an unrecognized type instead of erroring
- widgets: RenderField adds the widget to the parent it was given
- widgets: a number row carrying a values list renders as a Dropdown, not a Slider
- widgets: the numeric dropdown lists its entries with their own labels
- widgets: the numeric dropdown seeds the STORED number, not a stringified copy
- widgets: choosing an entry writes the number through the host's set
- widgets: a number row with NO values list still renders as a Slider
- widgets: a number row whose values function answers empty falls back to a Slider
- widgets: a string row with no values and no dialogControl prints once and still renders
- widgets: a values-backed row that is momentarily empty does NOT warn

### test_options_choicegrid.lua (22)

- widgets: ChoiceGrid draws a heading, a header line and one line per row
- widgets: ChoiceGrid draws skipRender rows, and a custom label header
- widgets: ChoiceGrid lights the cell holding the stored value and only that one
- widgets: a ChoiceGrid click writes the column value and re-syncs the whole line
- widgets: clicking the lit ChoiceGrid cell keeps it lit and writes nothing
- widgets: a ChoiceGrid value outside the columns lights no cell
- widgets: ChoiceGrid radios re-read the store when the refreshers run
- widgets: ChoiceGrid reads and writes a path-less row through its own get/set
- widgets: ChoiceGrid cells are ordinary checkboxes, never radios and never painted
- widgets: a CheckBox recycled after a ChoiceGrid comes back with an untinted check (G-2)
- widgets: ChoiceGrid disables a row's cells by its disabledIf
- widgets: a ChoiceGrid drawn inside a disabled render is disabled with it
- widgets: ChoiceGrid spec.disabled disables every cell for the call only
- widgets: a ChoiceGrid label carries the row's tooltip
- widgets: a ChoiceGrid row that raises costs its own line, not the grid
- widgets: ChoiceGrid with no AceGUI draws nothing
- widgets: an extraColumn draws a header cell and a clickable per-row link, wired to onClick
- widgets: an extraColumn's nil cell draws a blank of the same width, so rows stay aligned
- widgets: an extraColumn cell that raises costs only that cell, not the line or the grid
- widgets: an extraColumn cell with a non-function onClick draws without wiring a handler
- widgets: an extraColumn narrows the label column, and the line still fits one Flow row
- widgets: with no extraColumn, ChoiceGrid's line shape is unchanged

### test_options_flow.lua (48)

- widgets: a raising row costs that row and no other
- widgets: RenderGrid lays arbitrary items out two per row
- widgets: RenderGrid gives a wide item its own full-width row
- widgets: RenderGrid guards each item the way RenderRows guards each row
- widgets: RenderGrid's default gap is one ROW_VSPACER after every flushed and every wide row
- widgets: RenderGrid draws into a host-owned parent and leaves the page scroll alone
- widgets: RenderGrid's opts.gap: false and 0 draw no spacer, a number sets its height
- widgets: a wide RenderGrid item that raised leaves no blank row and no gap
- widgets: a RenderGrid make that answers false drew nothing and takes no row or cell
- widgets: RenderGrid does not lay out; the caller calls DoLayout after its last render
- widgets: RenderSchema pairs widgets two-to-a-row inside full-width Flow groups
- widgets: a `solo` row is rendered alone on its own line
- widgets: a `solo` row flushes the row in progress rather than joining it
- widgets: a `skipRender` row is left to the host and never drawn
- widgets: RenderRows emits one Heading per group, in first-seen order
- widgets: a group's heading lands BELOW the previous group's tail row, not above it
- widgets: an afterGroup callback fires exactly once, after its group's last row
- widgets: an afterGroup callback runs with its group's tail row already on the page
- widgets: an afterGroup hook fires for a group's FIRST run only, when the group recurs
- widgets: a pairWith partner attaches to the named row, is one-shot, and stays 50/50
- widgets: a pairWith partner declines a row it would make three-wide
- widgets: RenderRows leaves the caller's afterGroup / pairWith tables intact
- widgets: RenderRows runs a layout pass at the end
- widgets: Section emits a full-width Heading and tracks the group
- widgets: ClearScroll releases the children AND resets ctx.refreshers
- widgets: ClearScroll reassigns ctx.refreshers rather than wiping it in place
- widgets: InlineButtonPair lays two inset buttons into one Flow row and pcalls the click
- widgets: InlineButtonPair tolerates a missing second spec
- widgets: InlineButtonPair reports a handler-less button once, and draws it anyway
- widgets: a tabbed page draws ONLY the active group's rows
- widgets: a tabbed page draws no section heading -- the tab IS the heading
- widgets: a tabbed page falls back to the untabbed render when OptionsTabs.lua is absent
- widgets: the tab half draws its banner without the widget half's tooltip attacher
- widgets: an UNtabbed page still draws its headings
- widgets: clicking a tab clears the scroll and renders the new group
- widgets: the active tab survives a re-render, and heals when its group disappears
- widgets: a one-group page draws a ONE-TAB strip
- widgets: a page whose rows carry no group renders untabbed AND says so
- widgets: a host that omits print still sees NO_GROUPS in the chat frame
- widgets: with no AceGUI a tabbed page reports no tabs and draws nothing
- widgets: a subgroup draws a heading INSIDE a tab, where the group's own is suppressed
- widgets: a subgroup repeated under a SECOND group draws again
- widgets: the pending line is flushed before a subsection heading
- widgets: an UNTABBED page draws its group heading AND its subgroup headings
- widgets: a `wide` row renders at FULL width, alone, with the lines around it flushed
- widgets: `startsLine` flushes a half-full line so a declared pair cannot be split
- widgets: `startsLine` on a line that is already empty costs nothing
- widgets: InlineButtonPair with no right-hand button draws one, at the pair's width

### test_options_landing.lua (18)

- widgets: TextRow adds a full-width Label carrying the text
- widgets: TextRow left-justifies by default and honors an explicit justify
- widgets: TextRow applies a font object by NAME, and only when the global exists
- widgets: TextRow draws nothing and returns nil when there is no scroll to draw into
- widgets: BuildLandingPage draws the logo block at its declared size, then a spacer
- widgets: BuildLandingPage honors an explicit logoSize
- widgets: a logo whose widget has no backing frame costs the logo, not the page
- widgets: a POOLED frame gains ONE logo texture, and hides it when released
- widgets: a spec with no logo draws no logo block
- widgets: BuildLandingPage calls a notes FUNCTION at render time
- widgets: an empty one-liner skips the notes Label AND its spacer
- widgets: BuildLandingPage renders a heading and one row per section entry
- widgets: a section's rows are re-evaluated on every render
- widgets: a re-render clears the previous body instead of stacking a second copy
- widgets: the second landing heading gets a top spacer and the first does not
- widgets: the gap under a landing heading is emitted once, by Section
- widgets: BuildLandingPage tolerates a nil spec and an empty one
- widgets: the landing page's text rows carry the same justify guard TextRow owns

### test_options_ids.lua (35)

- ResolveId: a number is an id, and a known one carries its name and icon
- ResolveId: every link form resolves, for its own kind only
- ResolveId: a spell name the client knows resolves to its id
- ResolveId: a name the client cannot look up is found among the host's candidates
- ResolveId: two candidates with the name are ambiguous, one listed twice is not
- ResolveId: nothing typed is empty, and an unknown name is not found
- ResolveId: a custom kind's resolver is handed everything typed
- ResolveId: with no client APIs a number still resolves and a name finds nothing
- IdInput: an edit box and an Add button share a line, with a status line under them
- IdInput: the Add button is the height of the box it sits beside, not AceGUI's default
- IdInput: Enter with a valid name adds it once and clears the box
- IdInput: the Add button submits what was typed
- IdInput: a name that resolves to nothing says so inline and adds nothing
- IdInput: an ambiguous name asks for the id, in the kind's own plural
- IdInput: the host can reword the button and the messages
- IdInput: a raising onAdd is reported, and the box keeps its text
- IdInput: the box and status line are cleared before onAdd, so onAdd may redraw the page
- IdInput: drawn inside a disabled render, or with spec.disabled, it is disabled
- IdInput: with no AceGUI it draws nothing
- ResolveId: a client name hit another candidate shares its name with is ambiguous
- UnnamedCandidates: the item candidates the client cannot name yet, each once, capped
- IdInput: a name among uncached candidates is looked up, and added once it lands
- IdInput: a lookup waits for every candidate it asked for, then refuses a shared name
- IdInput: a lookup that never lands gives up after a bounded wait, with the honest reason
- IdInput: a second submit, a changed box or a released box drops a pending lookup
- IdInput and IdList: built with item candidates, they ask for the unnamed ones up front
- IdInput: a name that finds nothing says where names work, per kind; the hint is exported
- IdInput: the looking line can be reworded
- IdInput: a client hit on one rank waits for the uncached ranks, then refuses the name
- IdInput: a name hit waits on unnamed candidates, then adds; a number or a link never waits
- IdInput: a host kind with resolve, loads and info is looked up, and refuses a shared name
- IdInput: a second submit of the same text replaces the pending lookup
- IdInput: ids a lookup could not load are skipped, so later candidates get their turn
- IdInput: a lookup runs at most five windows of 200; the next Enter carries on past them
- IdInput and IdList: pre-warm moves past the ids it has asked for, and reads each id once

### test_options_idlist.lua (24)

- IdList: one line per entry -- icon, name and gray id, then Remove or a checkbox
- IdList: an entry's note is drawn under its name, and only when it has one
- IdList: an empty-string or non-string note draws nothing
- IdList: an entry's suffix is drawn inside the label, after the gray id and in the same gray
- IdList: an entry with no suffix renders exactly as it did at minor 24
- IdList: a suffixed entry still pairs up at two columns -- it is not a full-width row
- IdList: a suffix and a note on one entry -- the note wins its line, the suffix stays inline
- IdList: a suffix is concatenated, so a % or a |c in it reaches the client as written
- IdList: Remove and a toggle call the host back, and Remove asks for a rebuild
- IdList: an add through its input reaches onAdd and rebuilds the list
- IdList: with no ctx.rebuild the library's structural refresh redraws it
- IdList: an empty list shows the host's empty text
- IdList: an uncached item asks to load, and the list redraws once its name lands
- IdList: an item's name is colored by its quality; a spell's and a currency's are not
- IdList: an item with no quality yet, or no palette for it, is drawn uncolored
- IdList: uncached items load as one batch -- one timer and one rebuild, however many
- IdList: an item not cached by the check is asked for again, a bounded number of times
- IdList: an entry's label shows the client's own tooltip for it
- IdList: a host kind with base = "item" wears the item kind's color, tooltip and loads
- IdList: a host kind without base, or with a base no library kind has, is drawn as before
- IdList: a based spell kind draws as a spell and keeps its own tooltip
- IdList: a raising entries() is reported and still draws the input
- IdList: drawn disabled, every Remove and checkbox is disabled
- IdList: with no AceGUI it draws nothing

### test_options_idlist_layout.lua (39)

- IdList: with no columns option each entry has its line to itself, at minor 23's widths
- IdList: columns = 2 packs entries two to a line, row-major, at half the widths
- IdList: columns = 2 in the icon style halves the name and leaves the X alone
- IdList: an odd entry count leaves the last line half filled, not stretched
- IdList: inside a two-column list a noted entry takes a full-width line of its own
- IdList: a columns value that is not a usable count is floored, clamped, or read as 1
- IdList: at two columns a failing entry costs itself, not the entry beside it
- IdList: at two columns the FIRST entry of a row fails without stranding the row
- IdList: columns is capped at two, and the cap's arithmetic is the label's and the X's
- IdList: a content width two columns cannot pay for draws one, not a broken grid
- IdList: a content width that covers the floor keeps the columns the host asked for
- IdList: the default style falls back on the LABEL's floor, which is its only one
- IdList: a width that cannot be measured leaves the column count exactly as it was
- IdList: the X's frame is wider than its art, absolute, at every column count
- IdList: a gutter separates each entry from the next, and only at more than one column
- IdList: at more than one column an entry name is one line tall, never wrapped
- IdList: a list where nothing carries help draws no marks at all
- IdList: every entry gets a mark once ANY entry carries help
- IdList: a mark with nothing to say is dimmed and answers no tooltip
- IdList: a string help reads as one line
- IdList: the help mark's width comes out of the NAME
- IdList: a helped list still gets two columns on a canvas that pays for them
- IdList: the mark is drawn big enough to read, in a frame with the X's 5px ring
- IdList: the mark draws this library's own info art when the host names itself
- IdList: the art ladder falls back, and a host that names its own art keeps it
- IdList: a loaded host's name draws the library art
- IdList: a name the client has not loaded falls back, not to a dead path
- IdList: the removed bare IsAddOnLoaded is never read; no C_AddOns trusts the name
- IdList: a raising IsAddOnLoaded is not fatal and trusts the name
- IdList: a fall-through says why, once per instance
- IdList: no help, no question
- IdList: a help level tints the mark, and an entry that names none keeps its gold
- IdList: an unknown level draws the default, and a hover leaves a mark its own color
- IdList: a one-column list still wraps, and now lights too (minor 28)
- IdList: the no-wrap FontString is put back when AceGUI takes the widget back
- IdList: release clears the markers, so a pooled label cannot answer for the next list
- IdList: a label with no FontString still has its markers cleared
- IdList: at more than one column the hovered entry is lit, so the tooltip has an owner
- IdList: a multi-column tooltip hangs off the row, not over the column beside it

### test_options_tabs.lua (41)

- widgets: tab packing fills a row and wraps to the next
- widgets: a tab wider than the strip gets its own row rather than vanishing
- widgets: an empty tab list lays out as no rows at all
- widgets: __tabPlacement puts the first row below the banner, and wraps below that
- widgets: __tabPlacement accumulates x across a row
- widgets: __tabPlacement places every index exactly once
- widgets: __bannerBand widens a real height by the gap/rule/gap, and a zero one not at all
- widgets: __tabBand reserves the wrapped rows at their pitch, plus one full tab
- widgets: a tab is cut from the client's own tab atlases, active art on the selected one
- widgets: a tabbed page gets the client's content panel, drawn as two mirrored halves
- widgets: the content box is drawn WIDER than the content column it encloses
- widgets: wrapped rows are packed by the ART's height, so they sit flush
- widgets: a strip laid out before the canvas has a width re-wraps when the width arrives
- widgets: TabStrip draws one button per tab, marks the active one, and reserves the band
- widgets: clicking the ACTIVE tab does not re-fire onSelect
- widgets: a second TabStrip call replaces the first rather than stacking on it
- widgets: re-selecting the same tabs builds no second set of frames
- widgets: TabStrip refuses politely with no AceGUI and with no tabs
- widgets: PageBanner draws a seeded picker and reserves the banner band
- widgets: banner then strip reserve ONE band between them, not two
- widgets: banner then strip leave no overlap in the reserved band
- widgets: PageBanner refuses politely with no AceGUI and with no spec
- widgets: repeated strip renders do not grow the page-wide chrome ledger
- widgets: a wrapped strip's geometry is IDENTICAL for every value of the selection
- widgets: every tab's hit rect is inset by the same number the rows are packed by
- widgets: the pitch is measured once, off the INACTIVE family, and cached on success only
- widgets: PageHeader reserves the band, and the strip lands beneath it
- widgets: a page draws at most ONE chrome block -- the second replaces the first
- widgets: PageHeader without a divider draws the block and no rule
- widgets: a raising PageHeader builder costs the block, not the page
- widgets: PageHeader refuses politely with no spec and with no height
- widgets: two full renders of a banner page leave ONE Dropdown out, not two
- widgets: a header page after a banner page gives the banner's Dropdown back
- widgets: PageBanner's re-render from inside its own onSelect never hands itself back
- widgets: PageHeader hands the SAME frame back on every render of one page
- widgets: the divider texture is made once per page and hidden, never unparented
- widgets: SubTabStrip draws inside the host's frame and reports the height it took
- widgets: a second SubTabStrip call releases the first rather than stacking on it
- widgets: ClearScroll drains the sub-tab ledger before AceGUI pools the parent
- widgets: a wrapped SUB strip's geometry is invariant under the selected sub tab
- widgets: SubTabStrip refuses politely with no AceGUI, no parent and no tabs

### test_options_tabbed.lua (20)

- widgets: a host tab sits before the group it names and renders through its callback
- widgets: a host tab keyed by a group takes that group's place and is handed its rows
- widgets: a stale active tab heals to the first tab when only host tabs remain
- widgets: disabledFor draws the notice ABOVE the rows, and the rows disabled
- widgets: disabledFor false draws no notice and live rows; a raising one reads as enabled
- widgets: a host tab renders under the page's disable, and the flag never outlives it
- widgets: chrome is called once per render, after the strip and before the rows
- widgets: without untabbedSkipRender an all-skipRender group is still a tab (default)
- widgets: untabbedSkipRender drops an all-skipRender group's tab and keeps a mixed one
- widgets: untabbedSkipRender keeps an all-skipRender group a hook or host tab claims
- widgets: disabledReplaces draws the notice instead of the rows and host tab
- widgets: without disabledReplaces the notice is small and the rows still draw (default)
- widgets: rerender takes over a tab click: activeTab set, no ClearScroll, refreshers kept
- widgets: a raising rerender is reported and the strip stays usable
- widgets: with OptionsTabs.lua absent RenderTabbedSchema takes opts and renders untabbed
- widgets: the tab half alone does not define RenderTabbedSchema over no flow engine
- widgets: PageBanner's action draws a Button whose click calls onClick
- widgets: PageBanner's action button is Released like its picker, never leaked
- widgets: PageBanner's action re-rendering from its own click never hands itself back
- widgets: PageBanner's action is refused in combat, like its picker

### test_options_nav.lua (14)

- nav: the rail inset is zero with no rail and the rail's width plus its 12px gap with one
- nav: the rail's top is measured off the ACTIVE tab art, under the banner's band
- nav: the probe's cap is the drawn selected tab's own art, so the rail's top is level with the strip beside it (spec §2, §4; A2)
- nav: entries stack 20px apart from 8px below the rail's top
- nav: NavRail draws one entry per spec entry, records railWidth, and disables the selected one
- nav: the rail hangs in the body at the content column's left edge, from the art's top to the panel's foot
- nav: with no rail the strip, the content panel and the scroll are anchored exactly as before
- nav: with a rail the strip, the content panel's left edge and the scroll all move by the one inset
- nav: the first render's zero-width chrome re-places the strip, inset included, when the width arrives
- nav: a re-render reuses the pooled entries and builds no frame; a shorter one hides the surplus
- nav: a click on another entry hands its key to onSelect; the selected entry and a raising handler do nothing
- nav: an empty entry list releases the rail and gives the page its full width back
- nav: a live scroll moves right of the rail at once, and back when the rail is released, with or without a band
- nav: with OptionsNav.lua absent there is no NavRail and nothing is inset

### test_options_drawer.lua (26)

- drawer: OptionsDrawer is at minor 1 or later, attached to an Options shell at 29 or later
- drawer: a closed drawer is one full-width group on the page, a header and no body
- drawer: the header carries the label and the summary; set is gold, unset white and gray
- drawer: summary and set may be functions, read when the drawer is drawn
- drawer: a summary function that raises reads as no summary and is reported
- drawer: the chevron points right while closed and down while open
- drawer: a header click hands the host the other state, then re-renders the page once
- drawer: a header click keeps the page's scroll offset across the re-render
- drawer: a header click is refused in combat, and the host is not told
- drawer: an onToggle that raises is reported and the click goes no further
- drawer: an open drawer asks the host for its body, with a ctx whose scroll is the body
- drawer: the ordinary helpers draw into the box, not onto the page
- drawer: the body ctx reads the page's fields and writes through to the page
- drawer: RefreshPanel on a body ctx refreshes the page it is drawn on
- drawer: a body that raises is reported against the drawer and the page goes on
- drawer: a disabled drawer draws its body under the render-disabled flag, and lifts it after
- drawer: a drawer inside a drawer writes to the page and refreshes the page
- drawer: actions sit right-aligned on the box's last line, in the order given
- drawer: a closed drawer draws no actions; a drawer with none draws no action line
- drawer: an action click runs the host's onClick; refused in combat; a raise is reported
- drawer: a disabled drawer's actions are drawn disabled
- drawer: a drawer drawn while the page is render-disabled draws its actions disabled
- drawer: the box pads its content and grows by the padding when it lays out
- drawer: released, the box's methods and the header's button are handed back clean
- drawer: with OptionsDrawer.lua absent there is no Drawer, and the page is untouched
- drawer: with no AceGUI it draws nothing and answers nil

### test_options_keybinds_model.lua (26)

- keybinds: OptionsKeybinds is at minor 4 or later, paired on an Options shell at 30 or later
- keybinds: the Options version key has a component per file, OptionsKeybinds the twelfth
- keybinds: KEYBIND_STRINGS carries the exact default words, all ASCII
- keybinds: the client's own strings win where they exist, with the library's fallbacks
- keybinds: the API is available only when all five binding functions exist
- keybinds: slot 1 on a keyless command binds the key and saves once
- keybinds: slot 2 on a keyless command becomes slot 1
- keybinds: slot 1 on a one-key command replaces that key, which is left free
- keybinds: slot 2 on a one-key command keeps the old key first
- keybinds: on a two-key command the slot's old key is unbound and the order kept
- keybinds: the same key in the same slot is a no-op that writes and saves nothing
- keybinds: moving a key from slot 2 to slot 1 of the same command swaps the two
- keybinds: taking another action's only key names it, left keyless
- keybinds: taking one of another action's two keys names it, not left keyless
- keybinds: a failed SetBinding restores every old binding, the displaced action's too
- keybinds: a failed SetBinding on a keyless command leaves it keyless and saves nothing
- keybinds: SaveBindings runs exactly once, with GetCurrentBindingSet(), for sets 1 and 2
- keybinds: under the combat lock set and clear refuse 'combat' and call no binding API
- keybinds: under InCombatLockdown alone set and clear refuse 'combat' too
- keybinds: clear slot 1 leaves slot 2, clear slot 2 leaves slot 1, nil clears both
- keybinds: clearing with nothing bound succeeds and saves nothing
- keybinds: the set in force is 'account' for 1 and 'character' for 2
- keybinds: the bundled chord builder orders ALT-CTRL-SHIFT-META and converts mouse names
- keybinds: the bundled chord builder reads the modifier keys when no mods are passed
- keybinds: with the client's chord helpers the client route agrees
- keybinds: the client route refuses the left and right buttons its ignore check lets through

### test_options_keybinds.lua (30)

- keybinds tab: OptionsKeybinds is at minor 4 or later and attaches the three members
- keybinds tab: KeybindingsTab's defaults
- keybinds tab: spec.key, spec.before and spec.strings override
- keybinds tab: RenderTabbedSchema puts it LAST, after every group tab, and its render draws rows
- keybinds tab: rows follow spec.bindings in order, labeled by GetBindingName
- keybinds tab: a binding whose command is not a string is skipped and reported
- keybinds tab: one key button per row, then Clear: no second slot widget (minor 4)
- keybinds tab: the button shows the first key, '<key> +1' with a second, NOT_BOUND with none, and a refresher repaints
- keybinds tab: with a second key the tooltip names every key and where the others were set
- keybinds tab: a key bound through the button goes to slot 1 and keeps the second key
- keybinds tab: the button then SHIFT-K binds SHIFT-K to slot 1 and saves once
- keybinds tab: Escape cancels with no SetBinding
- keybinds tab: a modifier alone keeps listening; PRINTSCREEN screenshots and keeps listening
- keybinds tab: a second left click cancels, and so does a right click on the listener
- keybinds tab: Button4 and the wheel bind
- keybinds tab: a right click clears the key shown and the second moves up; Clear clears both
- keybinds tab: starting row 2 stops row 1; one listening slot
- keybinds tab: a taken key names the action left with no key; otherwise KEY_BOUND
- keybinds tab: the set line follows the set in force
- keybinds tab: a capture started in combat is refused with the gray notice, once
- keybinds tab: PLAYER_REGEN_DISABLED stops a capture in progress, writing nothing
- keybinds tab: a right click and Clear in combat call no binding API
- keybinds tab: released slots leave with nothing of ours, and the listener goes home
- keybinds tab: the page's OnHide stops a capture
- keybinds tab: a page drawn disabled draws disabled slots and Clear
- keybinds tab: without SetBinding one UNAVAILABLE row and nil
- keybinds tab: with no AceGUI scroll it draws nothing and answers nil
- keybinds tab: the fixed intro always draws, and spec.intro adds one line under it
- keybinds tab: T.keybindThroughTab binds through a row and answers the outcome line
- keybinds tab: T.keybindThroughTab slot 2 sets the game page's key through the model

### test_options_keybinds_sync.lua (14)

- keybinds sync: OptionsKeybinds is at minor 3 or later
- keybinds sync: UPDATE_BINDINGS is heard only while a keybind row is on screen
- keybinds sync: a page with no keybind rows registers nothing
- keybinds sync: releasing the rows lets go
- keybinds sync: the registration goes through Core's SafeRegisterEvent
- keybinds sync: without SafeRegisterEvent nothing registers, and OnShow still re-reads
- keybinds sync: a key set in Options -> Keybindings shows on the next frame
- keybinds sync: three UPDATE_BINDINGS in one frame give exactly one repaint
- keybinds sync: LoadBindings to the other set repaints the slots and the set line
- keybinds sync: a key changed while the page was hidden shows on the next OnShow, no event
- keybinds sync: an event delivered with no row on screen draws and prints nothing
- keybinds sync: a capture in progress keeps LISTENING through a repaint
- keybinds sync: a repaint runs in combat, since it only reads
- keybinds sync: without C_Timer the repaint runs at once

### test_options_appearance.lua (26)

- appearance: OptionsAppearance is at minor 1 or later and attaches the two members
- appearance: the Skin major answers an owner's label and writes through its setter
- appearance: AppearanceTab's defaults
- appearance: spec.key, spec.before and spec.strings override
- appearance: RenderTabbedSchema puts it immediately before Keybindings, and its render draws rows
- appearance: the rows draw both sources, one choice per skin with swatches, the copy button and the note
- appearance: a skin pick moves the Skin major, then writes through the seam, and repaints live
- appearance: a pick never reaches another owner, and clicking the checked skin keeps it
- appearance: copy is disabled with its hint while no other owner is loaded
- appearance: copy confirms with the other owners' names and writes each through its own setter
- appearance: in combat a skin or source pick writes nothing
- appearance: a copy clicked in combat asks nothing
- appearance: a copy confirmation accepted after combat starts writes no other owner
- appearance: the EllesmereUI choice is disabled while the gate is closed, each condition listed
- appearance: with no Skin EllesmereUI provider the choice is disabled with one line
- appearance: the open gate lets EllesmereUI in, and leaving it raises one reload popup
- appearance: spec.strings translates every string, the skins' names and descriptions included
- appearance: a page drawn disabled draws every control disabled
- appearance: the refresher re-reads the owner's store
- appearance: an owner that never registered, or no Skin major, draws one line and no controls
- appearance: the Scope section draws its two exceptions between the skins and the copy button
- appearance: Ignore fonts moves the Skin major, writes the seam's third argument, and fonts go back live
- appearance: Ignore settings panel after the panel was painted asks for one reload
- appearance: SetIgnore keeps a nil half, needs no reload on an unpainted panel, and WriteChoice passes it on
- appearance: copy gives every other owner this owner's scope as well as its skin
- appearance: an instance whose owner ignores its panel still hears a skin switch

### test_options_idsuggest.lua (29)

- IdInput suggestions: exact, then prefix, then a word, then anywhere; shorter first
- IdInput suggestions: one name's rows sort by rank, then by id
- IdInput suggestions: at most ten rows, then a line saying how many were left out
- IdInput suggestions: digits match ids by prefix; a name needs two letters
- IdInput suggestions: two letters means two characters, not two bytes
- IdInput suggestions: every rank is its own row, labeled, beside the others
- IdInput suggestions: a spell's rank is the client's subtext
- IdInput suggestions: a click adds that row's id once, through onAdd, and closes
- IdInput suggestions: Up and Down move the highlight, and Enter adds it
- IdInput suggestions: Enter with no row highlighted still refuses a shared name
- IdInput suggestions: a shared name the bags or the spellbook carry is refused, not one rank added
- IdInput suggestions: typing drops the highlight, so Enter never takes a row the text left
- IdInput suggestions: a shared name refused by Add, or before the pause, lists its ranks
- IdInput suggestions: a shared name refused after a lookup lists its ranks
- IdList suggestions: a pick reaches onAdd and rebuilds the list
- IdInput suggestions: Escape, focus loss, a hidden panel and a release close it
- IdInput suggestions: typing is debounced, and a released box's pending update is dropped
- IdInput suggestions: items in the bags and spells in the spellbook need no candidates
- IdInput suggestions: a missing source, a raising candidates() or no info costs nothing
- IdInput suggestions: an uncached candidate joins the list once it is named
- IdInput suggestions: a host kind with base = "item" shows each rank's tier and color
- IdInput suggestions: a based host kind's own false wins over its base
- IdInput suggestions: the id a based kind's resolve answers for a pick is the one added
- IdInput suggestions: a based kind built per render is collected with its view
- IdInput suggestions: a based host kind's resolve still decides what a pick adds
- IdInput suggestions: any library kind can be a base; its ranks and fields come with it
- IdInput suggestions: a based host kind is offered its base's client ids, ranked as the base ranks them
- IdInput suggestions: a host kind with no base is offered nothing of the client's
- IdInput suggestions: the shared-name check reads one source through a based kind and its base

### test_options_idsuggest_frames.lua (15)

- IdInput suggestions: one dropdown per instance, whatever the renders
- IdInput suggestions: a box pooled into a second render is hooked once
- IdInput suggestions: a box pooled into another instance wakes no list of the first's
- IdInput suggestions: a released box lets its render's index go
- IdInput suggestions: Enter in a box that no longer owns the dropdown submits its text
- IdInput suggestions: a box that left before the pause shows nothing
- IdInput suggestions: focus lost to the dropdown itself goes back to the box
- IdInput suggestions: one render names at most 2000 ids
- IdInput suggestions: a raising info costs that id's row, not the list
- IdInput suggestions: the dropdown is as wide as the box looks
- IdInput suggestions: a host kind's suggestTag is appended after the id
- IdInput suggestions: the start of combat closes a list a page opened
- IdInput suggestions: a list another page's box opened is not this release's
- IdInput suggestions: a focused pullout and the list both close at combat start
- IdInput suggestions: leaving combat does not reopen a list combat closed

### test_options_idlist_remove.lua (8)

- IdList removeStyle icon: an X leads every line, then the name; no Remove button and no checkbox
- IdList removeStyle icon: a click on the X calls onRemove and rebuilds the list
- IdList removeStyle icon: the X's tooltip is the remove string, a host's override honored
- IdList without removeStyle draws exactly as before: the name, then Remove or a checkbox
- IdList removeStyle icon: drawn disabled, the X is disabled
- IdList removeStyle icon: the X lights its whole hit area, not just the art inside it
- IdList removeStyle icon: the highlight goes back onto the art when AceGUI takes the X back
- IdList removeStyle icon: an AceGUI whose Icon has no textures still draws the X

### test_options_switched.lua (9)

- switched: only the subsection the selector names is drawn, its heading with it
- switched: equals may list several values; the row shows for any of them
- switched: a group's afterGroup hook fires after its last DRAWN row, once
- switched: changing the selector re-renders the page once, on the next frame
- switched: a write from anywhere (a slash set, a reset) re-renders too, once per change
- switched: a selector that cannot be read shows its rows rather than losing them
- switched: rows without shownWhen render as before, and no selector watcher is added
- switched: a bound (path-less) selector reads and is watched through its record
- switched: two selectors changing in one frame cost one re-render

### test_options_combat.lua (33)

- combat: a page shown in combat is covered and not drawn, and the window is left alone
- combat: the cover is built out of combat, hidden, and takes the mouse and the wheel
- combat: REGEN_DISABLED covers an open tabbed page above its tab strip
- combat: REGEN_DISABLED covers a page's nav rail, and a rail click in combat is refused
- combat: a widget write is refused and the widget put back
- combat: the notice comes back once per combat, not once per session
- combat: the page's Defaults — header button and footer control — are refused
- combat: a library button's click is refused
- combat: a session checkbox is refused and put back
- combat: a color commit is refused and the swatch put back
- combat: a page banner's selection is refused and the dropdown put back
- combat: a tab click is refused and the page stays on its tab
- combat: SelectTab refuses in combat
- combat: a structural refresh in combat waits; the page renders when combat ends
- combat: a page first shown in combat renders when combat ends, and is never re-opened
- combat: a clean open page runs its refreshers when combat ends, not its renderer
- combat: a hidden page is left for its next show
- combat: REGEN_DISABLED closes the library's own dropdown pullout on an open page
- combat: another addon's focused widget is left alone
- combat: out of combat nothing changes
- combat: one event frame for the library, dispatching through lib at call time
- combat: the lock predicate is the flag or the client's lockdown
- combat: with no page shown the library holds no registration and shows no frame
- combat: a page's show registers the events and the last hide unregisters them
- combat: a page hidden in combat drops its cover and lets go of the events
- combat: a page shown mid-combat is locked off InCombatLockdown alone
- combat: a page hidden without OnHide is let go at the next combat edge
- combat: a registration an older copy left is dropped when nothing is shown
- combat: CreateOptionsPanel in combat registers nothing and waits for REGEN_ENABLED
- combat: the end of combat registers the parked panel once and lets go of the event
- combat: a second CreateOptionsPanel while parked is a no-op
- combat: an event other than REGEN_ENABLED leaves the park armed
- combat: OpenOptionsPanel answers false in combat, true when opened, nil with no category

### test_options_combat_debug.lua (16)

- opt combat debug: Options is at 27 or later, with the six files the lines touch at their floor
- opt combat debug: every refused write is one line naming the row; the notice stays once
- opt combat debug: a color commit refused names its row
- opt combat debug: a drag's throttled color and live-slider commits are one line each
- opt combat debug: the page's Defaults, header button, footer control and RestoreDefaults
- opt combat debug: a library button (Reset all settings) names its text
- opt combat debug: a session checkbox names its label
- opt combat debug: a tab click and SelectTab name the tab
- opt combat debug: a nav rail click names the entry
- opt combat debug: a page banner's selection and action name themselves
- opt combat debug: a page shown under the lock writes one line naming it
- opt combat debug: an id list toggle and remove are one line each
- opt combat debug: a parked registration writes the parked line, then the flush line
- opt combat debug: the line is built only under the lock and with a debug to write to
- opt combat debug: no debug on the descriptor is silent, and the chat is unchanged
- opt combat debug: a debug that is not a function is ignored

### test_options_compose.lua (51)

- compose: the instance carries every composer and every published constant
- compose: FontGroup emits the six canonical leaves in the canonical order
- compose: BorderGroup emits the four mandated leaves, and the toggle only when asked
- compose: BarGroup emits texture, opacity, color, companion -- in that layout
- compose: ColorPair emits exactly two rows, and names the companion after the swatch
- compose: FontGroup's font row answers a populated list, not a second closure
- compose: BorderGroup's border-style row answers a populated list
- compose: BarGroup's bar-texture row answers a populated list
- compose: a host whose own LSMValues returns a TABLE lands a frozen list, which is the breach
- compose: every color row is immediately followed by its companion, and starts a line
- compose: no composed row anywhere carries disabledIf
- compose: the class-color SOURCE is stamped on both halves of every pair
- compose: prefix composes the path, and page/group/subgroup reach every row
- compose: order starts where the caller said and steps by ten
- compose: keys, labels and defaults override without changing what the block IS
- compose: omit removes a row and leaves the survivors in the same relative order
- compose: extra rows are appended AFTER the mandated block, never interleaved
- compose: a composer never writes to the spec it was handed
- compose: MasterControls emits the six canonical rows and defaults its own group
- compose: testModePath adds one session-only Test mode row, on its own line after the console
- compose: minimapPath adds a stored Minimap button row, opening the line Test mode pairs on
- compose: Minimap button and Test mode render as ONE line, minimap first
- compose: either row alone still opens its own line
- compose: the debug console's path is verbatim and outside the block's prefix
- compose: frameless drops EXACTLY the four frame-only controls and nothing else
- compose: a frameless addon's lead button shares the pair with Reset all settings
- compose: a FRAMED addon's lead button takes its own row above the full pair
- compose: the tail draws the two resets as the tab's closing button pair
- compose: a path-keyed call emits byte-for-byte what compose minor 3 emitted
- compose: the bind arm emits the same rows as the path arm, with the binding in place of path
- compose: a bound row's get and set reach the bind with the record field and the row
- compose: bind.record is enough to read, and an extra's own path is left alone
- compose: a bind with no setter, or with nothing to read, is refused when the block is composed
- compose: every maker reads a bound row through get and writes it through set, never the store
- compose: a bound row's refresher re-reads the record, so a write elsewhere repaints it
- compose: a row WITH a path is read through the descriptor even when it carries get and set
- compose: PanelMaster's three record-backed groups compose, in the order the editor draws them
- compose: a PanelMaster block writes through the registry and repaints off the live record
- compose: a bound row takes its pairWith partner, keyed by its field
- compose: disabledIf on a bound row reads the record through the bind, not the settings store
- compose: with no resetProfile the Reset all tooltip keeps its minor-4 wording, byte for byte
- compose: with resetProfile the Reset all tooltip says it resets the current profile only
- compose: with resetProfile and profilesPage the tooltip names Profiles -> Reset Profile
- compose: the descriptor moves the Reset all tooltip and nothing else Master controls draws
- compose: a shell that hands __AttachCompose no descriptor keeps the minor-4 tooltip
- compose: StrataTooltip over BACKGROUND..HIGH says the tiers and nothing more
- compose: StrataTooltip adds the dialog sentence when the row offers Dialog or above
- compose: StrataTooltip adds both sentences when the row offers Fullscreen Dialog or Tooltip
- compose: StrataTooltip over a non-table says the tiers alone
- compose: StrataTooltip takes each part from strings, which is how a host localizes it
- compose: StrataTooltip's default text is pure ASCII and names the Settings window

### test_options_compose_master.lua (15)

- compose master: the alpha row is labeled Master opacity, everything else unchanged
- compose master: each row's note appends one sentence to exactly that row
- compose master: notes.resetAll and notes.resetPosition append to the button tooltips
- compose master: an empty, non-string or omitted-leaf note changes nothing
- compose master: a keys rename does not stop the note
- compose master: the spec and its notes are never written, and two calls agree
- compose master: resetPositionTooltip replaces the Reset position tooltip
- compose master: lockIsPreview gives Lock frame the library's preview sentence
- compose master: lockIsPreview with a testModePath is refused
- compose master: frameless with lockIsPreview emits no Lock frame row and does not raise
- compose master: frameless puts Minimap button beside Debug console
- compose master: framed with Lock frame omitted packs minimap and gives Test mode its own line
- compose master: with the console omitted too, frameless Minimap button opens its line
- compose master: the flow engine draws Debug console and Minimap button on one line
- compose master: OptionsCompose is at minor 9 or later

### test_options_compose_tooltips.lua (12)

- compose tooltips: an entry replaces exactly its leaf's tooltip, every other row byte-identical
- compose tooltips: a swatch's override ends with the class-color sentence
- compose tooltips: a companion's override has no class-color sentence appended
- compose tooltips: an empty, non-string or omitted-leaf entry changes nothing
- compose tooltips: a keys rename keeps the override
- compose tooltips: labels and tooltips together both apply
- compose tooltips: a prefixed block keys the override by the leaf, not the path
- compose tooltips: the bind arm applies the override
- compose tooltips: the spec and its tooltips table are never written, and two calls agree
- compose tooltips: MasterControls ignores tooltips (notes is its only route)
- compose tooltips: every golden is unchanged
- compose tooltips: OptionsCompose is at minor 10 or later

### test_options_reset_tooltip.lua (7)

- reset tooltip: each host answers its own lib.STRINGS wording
- reset tooltip: follows a descriptor changed after New, as the button does
- reset tooltip: equals the tooltip MasterControls gives Reset all settings
- reset tooltip: the key-bindings tail follows after one space
- reset tooltip: an empty, nil or non-string tail adds nothing
- reset tooltip: notes.resetAll is the button's own and does not reach the member
- reset tooltip: OptionsCompose is at minor 11 or later

### test_options_skin.lua (15)

- options skin: a page with no registered owner is today's paint, call for call
- options skin: an owner-less page records nothing in the Skin major
- options skin: an owned page paints its header and an opaque backdrop from the skin
- options skin: an owned page's tab strip fades the client's art and wears the tab roles
- options skin: an owned page's rail, drawer and cover paint from the skin
- options skin: a skin switch repaints the owned page with no reload, Ka0s Default included
- options skin: Ka0s Default dresses an owned page like every skin
- options skin: an owner that registers after the page was built gets its skin on the next show
- options skin: two owners' pages stay apart
- options skin: the always-shown thumb takes the owner's tints, and is given back on release
- options skin: a pooled drawer head drawn for no owner leaves the owner's repaint
- options skin: the id list's help mark takes the skin's tints away from Ka0s Default
- options skin: the keybind rows take the skin's text roles away from Ka0s Default
- options skin: Ka0s Default colors the keybind rows in its own text roles
- options skin: the id-suggestion popup takes the skin, Ka0s Default's edge included

### test_options_compose_skin.lua (10)

- compose skin: OptionsCompose is at minor 12 or later, and OptionsWidgets at 35 or later
- compose skin: without fromSkin the three groups emit exactly the rows they did
- compose skin: fromSkin appends one companion per picker, after the canonical rows
- compose skin: the canonical rows are unchanged beside the companion, and so is every list
- compose skin: omit and keys reach the companion like any canonical leaf
- compose skin: the picker shows the skin's value while its companion is set, its own otherwise
- compose skin: a rendered picker is disabled while the companion is set and the companion writes
- compose skin: a record-backed group reads its companion from the record
- compose skin: ResetToSkin sets companions to true and never writes the sentinel into a pick
- compose skin: Skin is at minor 3 or later

### test_options_throttle.lua (4)

- throttle: a nil-returning scheduleTimer still gets ONE slider timer per window
- throttle: a nil-returning scheduleTimer still gets ONE color timer per window
- throttle: the window re-arms after it fires, for a nil-returning host
- throttle: a host whose timer answers a handle is unchanged

### test_perf_core.lua (78)

- lib: registers under its major with a schema and a default ring
- lib: New requires a name, an sv global and a lifecycle latch
- lib: New rejects a bucket entry with no key, in the library's own words
- lib: a ring of zero is clamped to one, not left to empty itself
- lib: a negative ring is clamped too
- lib: two instances share no state
- lib: bucket order and nesting come from the descriptor
- lib: the capture gate starts off
- lib: Note accumulates calls, total and max
- lib: Note tracks unrelated buckets independently
- lib: Note takes the observed parent, and defaults to claiming nothing
- lib: two different observed parents for one bucket are flagged, not overwritten
- lib: Note with no key names the caller instead of raising a table-index error
- lib: Reset clears every bucket and both fps arms
- lib: Open records nothing while the probe is off
- lib: Close with no matching open slot is a silent no-op
- lib: Open with no key names the caller instead of raising a table-index error
- lib: a real bracket records its elapsed ms to the named bucket
- lib: Open/Close feed the same buckets P.Note does
- lib: a bracket opened inside another records the enclosing key as its observed parent
- lib: an exit that forgot its Close is discarded, not credited with a later bracket's time
- lib: a leaked Open in window A does not parent a bracket in window B
- lib: EncodeJSON emits object keys in sorted order
- lib: EncodeJSON renders integral numbers without a decimal point
- lib: EncodeJSON renders fractional numbers to four places
- lib: EncodeJSON escapes quotes, backslashes and control characters
- lib: EncodeJSON emits arrays for sequence tables
- lib: EncodeJSON emits an empty table as an object
- lib: EncodeJSON coerces non-finite numbers rather than emitting invalid JSON
- lib: EncodeJSON encodes a whole record, not just its buckets
- lib: BuildRecord carries schema, source and label
- lib: BuildRecord derives avgFps and msPerFrame from the arms
- lib: BuildRecord reports zero delta when only one arm was sampled
- lib: BuildRecord computes the delta when both arms were sampled
- lib: BuildRecord snapshots buckets rather than aliasing them
- lib: a record names the addon that produced it
- lib: a nested bucket carries its parent into the record
- lib: a declared parent that never fired is emitted with zero counts when its child fired
- lib: every ancestor of a fired leaf is emitted, and an unrelated idle bucket is not
- lib: the zero-count parent travels into the JSON and prints as a zero row
- lib: a record stamps the host's interface version and the capture time
- lib: the record's context names the character's class
- lib: a canceled run takes its context stamp with it
- lib: a record built before Start has no context at all
- lib: a Note key the descriptor never declared still lands in the record
- lib: Save creates the perf global and appends the run
- lib: Save stamps the schema on the store
- lib: Save trims the ring to ringMax, dropping the oldest
- lib: Save traces a retention prune to the host log, and only when it prunes
- lib: a ring written under another schema is discarded, not converted
- lib: FormatReport emits its sections in reading order
- lib: FormatReport marks an unsampled arm rather than printing zeros
- lib: FormatReport prints both arms and the delta when both ran
- lib: FormatReport derives ms/s from the active seconds only
- lib: FormatReport warns that buckets nest
- lib: FormatReport omits buckets that never fired
- lib: FormatReport indents a nested bucket under its parent
- lib: a declared parent nobody supplied is reported as declared, NOT as observed
- lib: a supplied parent is reported as observed
- lib: a parent observed somewhere other than the declared one is reported as the defect it is
- lib: observed containment travels into the record beside the declared value
- lib: a flat bucket set gets no nesting footer
- lib: Context captures character, spec, zone and group
- lib: Context reports solo when ungrouped
- lib: Context takes the namespaced spec reader before the bare global
- lib: Context reports party size and instance type
- lib: Context reports raid size
- lib: ContextLines folds the sub-zone into the location
- lib: ContextLines omits an empty sub-zone cleanly
- lib: ContextLines tolerates a record with no context
- lib: a host passing only the three required fields gets working defaults
- perf: an L whose metatable synthesizes every key does NOT mask the module's strings
- perf: a step label is never its own SCREAMING_SNAKE_CASE key
- perf: a REAL entry in an L that also has a fallback still overrides
- lib: Context captures the class name, not the token
- lib: Context keeps every field's default where its client reader is absent
- lib: Context keeps every field's default where its client reader answers nil
- lib: Context's spec is '?' with no spec index, and with an index reader but no info reader

### test_perf_run.lua (42)

- lib: suspend returns false when already suspended
- lib: resume returns false when not suspended
- lib: the suspended state is session-only, never persisted
- lib: starting an experiment logs it
- lib: stopping an experiment logs both arm durations
- lib: suspend and resume are logged
- lib: a no-op suspend or resume logs nothing
- lib: nothing is logged when no run is happening
- lib: an armed window samples nothing until combat begins
- lib: a window opens on combat and accumulates
- lib: a window closes when combat ends and stops accumulating
- lib: the walk between windows is never measured
- lib: measure b suspends the addon and measure a resumes it
- lib: window B still samples while the addon is suspended
- lib: re-arming a window zeroes it rather than averaging in
- lib: arming a window mid-combat closes the one already open
- lib: Measure is rejected outside an experiment
- lib: Measure rejects an unknown window token
- lib: Measure accepts either case
- lib: Stop closes an open window rather than discarding it
- lib: Stop detaches the sampler so an idle client pays nothing
- lib: the sampler ignores ticks once the experiment is over
- lib: Stop deliberately leaves a suspended host suspended
- lib: two completed windows produce a delta
- lib: recording start and end are announced to chat AND the debug log
- lib: the end announcement carries the duration and frame rate
- lib: the console log is plain text, free of color escapes
- lib: experiments are named A and B, never active/suspended
- lib: the run start is logged with its context
- lib: arming logs which experiment and whether the addon is suspended
- lib: measure b calls the host's suspend, measure a its resume
- lib: canceling a suspended run restores the host
- lib: the stopwatch is driven per window
- latch: Suspend takes the 'perf' hold and Resume gives it back
- latch: p.suspended reads the latch rather than a copy of it
- latch: assigning p.suspended raises rather than shadowing the latch
- latch: releasing the perf hold does NOT resurrect an addon `disabled` still holds down
- latch: the resume log line follows what actually happened
- latch: finish releases the hold before saving, and says which of the two happened
- latch: the perf hold is session-only and reaches no SavedVariables
- sampler: the capture lives in PerfSampler.lua at minor 1, paired on the live probe
- sampler: a probe without PerfSampler.lua builds, records nothing and says why

### test_perf_panel.lua (46)

- lib: before a run Start is the one offered step
- lib: Start reads done while a run is in flight
- lib: Start is offered again once a run has finished
- lib: starting a run makes exactly Measure A ready
- lib: an armed or recording experiment reads busy, not ready
- lib: completing A unlocks B and nothing else
- lib: completing B unlocks Finish
- lib: finishing unlocks Report
- lib: exactly one step is ready at any point in a run
- lib: re-arming a completed experiment sends it back to busy
- lib: re-arming Experiment B relocks Finish
- lib: a step state is always one of the state words, never a value the run holds
- lib: a window that caught no frames still counts as completed
- lib: Reset clears completion, so a fresh run starts from step one
- lib: the panel renders every step and tracks their states
- lib: a locked panel button refuses to act when clicked
- lib: the panel repaints itself on every state transition
- lib: every step row carries a status dot, drawn not glyphed
- lib: labels are plain text with no decoration baked in
- lib: cancel is offered throughout a run and nowhere else
- lib: cancel has its own state, so it never reads as the next step
- lib: canceling discards the run without saving it
- lib: canceling restores a suspended addon
- lib: canceling mid-recording does not announce the experiment as ended
- lib: canceling detaches the sampler
- lib: cancel returns false when there is nothing to cancel
- lib: a canceled run leaves the next one clean
- lib: every row shows its slash command
- lib: a step label is bounded by its command column and never wraps
- lib: cancel stays clickable while a run is mid-experiment
- lib: cancel is not clickable once the run is finished
- lib: hiding the panel never touches the run
- lib: Toggle flips visibility both ways
- lib: decorate is handed the frame and a way to close it
- lib: a host that passes no decorate still gets a working panel
- lib: the fallback close button is told which addon is asking
- lib: an addonName in the descriptor wins over the name
- lib: a host that decorates gets no close button from the library
- lib: report stays clickable after use, but reads as done
- lib: marking a review action twice is a no-op
- lib: MarkReviewed ignores keys that are not review actions
- lib: a fresh run clears the review marks
- lib: the panel titles itself like the debug console
- lib: a locale table filled in after New still reaches the rows
- lib: every step label names what it acts on
- lib: a panel-less instance answers STEPS, PanelStateOf and PanelIsActionable safely

### test_perf_command.lua (22)

- cmd: OnCommand always returns a line table, never nil
- cmd: start begins a run and shows the panel
- cmd: a label is appended to the timestamp, never replaces it
- cmd: measure reports which window armed and whether the host is suspended
- cmd: measure outside a run tells you to start one
- cmd: measure rejects an unknown window token
- cmd: finish resumes the host before it saves
- cmd: finish prints no report
- cmd: report writes the summary to the log sink and opens it
- cmd: report writes the summary AND the JSON, in that order
- cmd: dump is no longer a verb of its own
- cmd: cancel refuses when there is nothing to cancel
- cmd: show, hide and toggle drive the panel and nothing else
- cmd: a bare command reports the phase and prints the usage
- cmd: usage never hard-codes a slash prefix
- cmd: usage never leaves a bare pipe where the client reads an escape
- cmd: usage rows use the library's own row formatter
- cmd: clicking a ready panel row takes the same path as typing it
- cmd: a panel click prints exactly what typing the command prints
- cmd: clicking a locked panel row does nothing
- cmd: the command surface lives in PerfCommands.lua at minor 1, paired on the live probe
- cmd: a probe without PerfCommands.lua answers every command with one line saying so

### test_perf_budget.lua (11)

- budget: a malformed budget is refused in the library's own words
- budget: a well-formed budget is accepted, and a bucket may declare one axis
- budget: the declared budget travels onto its bucket in the record and the JSON
- budget: the record's budget is a copy, not the descriptor's table
- budget: a bucket over its ms/s ceiling and over its max ms reports OVER on both
- budget: a bucket inside both ceilings reports ok, and one axis over reports OVER
- budget: a budgeted bucket that recorded no calls reports not exercised
- budget: a host with no budgets gets a byte-identical report
- budget: a record read back off the ring reports the budget it was built with
- budget: finish says how many buckets went over budget, and nothing gates
- budget: finish with budgets all inside says zero, and with none declared says nothing

### test_perf_toplevel.lua (7)

- perf top: Note takes false as an observation at top level, not as no observation
- perf top: top level and a parent, in either order, are a mix that keeps both observations
- perf top: a bucket observed only at top level is reported as top level, not as unobserved
- perf top: an undeclared bucket seen at top level and inside a parent names both
- perf top: two different parents name both in the mixed sentence
- perf top: an undeclared bucket seen only at top level adds no nesting footer of its own
- perf top: a top-level observation travels into the record and its JSON as false

### test_perf_isolation.lua (12)

- iso: two instances create separate sampler frames
- iso: driving one instance's sampler accumulates into that instance alone
- iso: an instance's sampler is detached without touching the other's
- iso: a dormant Open/Close bracket allocates nothing and records nothing
- iso: an active Open/Close bracket reuses its slots instead of allocating one per open
- iso: armed, recording and label stay raw fields across a window and a cancel
- iso: two instances create separate panel frames
- iso: each panel renders its own host's state and its own slash prefix
- iso: clicking one host's panel drives that host only
- iso: a newer probe loading second brings its own panel with it
- iso: an older copy loading second replaces neither half
- iso: a higher panel minor over the same probe still wins

### test_sim_seam.lua (27)

- sim seam: the major registers with Core, and reports its file minor
- sim seam: the module is absent without Core
- sim seam: the seam carries exactly SetProvider, Live, Keys and Unwrapped
- sim seam: every non-pure function is wrapped, and Keys() is sorted
- sim seam: pure members are the host's own functions, untouched
- sim seam: Keys() answers a fresh copy each call
- sim seam: NewSeam refuses a bad compat, a missing name and bad opts
- sim seam: a guarded key must be a wrapped member, and its answer a function
- sim seam: one compat table is wrapped once
- sim seam: a dropped compat table and its seam are collected
- sim seam: an idle call goes straight to live, arguments and nil holes intact
- sim seam: idle, a guarded member calls live
- sim seam: idle, a registered provider is never consulted
- sim seam: the idle wrapper allocates nothing
- sim seam: SetProvider raises on a pure key and on an unknown key
- sim seam: a second owner raises; nil releases, and then a new owner is taken
- sim seam: SetProvider raises on a provider that is not a function
- sim seam: Live runs fn with its arguments and keeps nil holes in both
- sim seam: Live nests, and the seam works again after a raise
- sim seam: Live re-raises a table error value unchanged
- sim seam: Live re-raises a string error with no second position prefix
- sim seam: Live writes the traceback to opts.debug before re-raising
- sim seam: a raising debug sink never masks the original error
- sim seam: Live with no debug sink still re-raises
- sim seam: Unwrapped() is empty straight after NewSeam
- sim seam: Unwrapped() lists a late-added and a replaced member, sorted
- sim seam: Sim.lua carries no auto-wrap metatable and no guarded-key query

### test_sim_session.lua (55)

- sim session: New is on the library, beside NewSeam
- sim session: every required descriptor field raises by name when missing
- sim session: a seam that NewSeam did not make raises
- sim session: a second New on one seam raises (one seam binds one session)
- sim session: a scenario name with no def, or a def with no timeline, raises
- sim session: d.panel takes presentation fields only (no button, tooltip or store)
- sim session: the instance carries no Live and no public active or delivering field
- sim session: the fallback members answer until their files attach
- sim session: Start prints STARTED and creates the session
- sim session: the seed defaults to an integer, and two starts draw different seeds
- sim session: size reaches prepare only when the def has sizes; 0 is random
- sim session: an unknown scenario is refused first, naming the scenarios
- sim session: Start reads the scenarios live: a def added after New starts (minor 2)
- sim session: a def listed after New is validated on Start, raising as New does
- sim session: prepare receives the caller's extra start options (minor 2)
- sim session: refusal order is unknown, already running, refusal, stood down
- sim session: the stood-down backstop refuses after refusal passes
- sim session: refusal runs inside the seam's Live (it reads the real world)
- sim session: a prepare error becomes Stop('error')
- sim session: ready() is bound to its session; a second call is ignored
- sim session: a stale ready() is ignored after a restart and after stop then start
- sim session: Fire answers 0 when idle
- sim session: Fire delivers any event name with its payload, and counts it
- sim session: an observed stand-down stops the session first and answers 0
- sim session: Fire answers 0 while stopping
- sim session: a deliver error is isolated to a debug line, and Fire answers 0
- sim session: IsDelivering is true only inside Fire, and nesting restores it
- sim session: a Stop inside deliver leaves IsDelivering false afterwards
- sim session: After answers nil when idle
- sim session: After fires within its session, under pcall
- sim session: After never fires into a later session
- sim session: Cancel cancels and forgets; Stop cancels every live handle
- sim session: After refuses while stopping
- sim session: Stop answers false when idle
- sim session: Stop runs guarded, then seam off, then cleanup, then notify, then prints
- sim session: each stop step is pcalled; a raising one does not skip the rest
- sim session: Stop re-entered from deliver, OnStop or a second call is a no-op false (C.1)
- sim session: stop reason lines, host stopText, and the generic reason line
- sim session: stopText overrides a library reason too
- sim session: the panel is hidden on a stood-down stop and repainted otherwise
- sim session: DeliverForCleanup delivers only in the OnStop phase, with the seam off
- sim session: DeliverForCleanup answers 0 while stood down
- sim session: Status answers every field, idle and running
- sim session: host fields go on the session table (the host bag)
- sim session: listeners hear start, ready and stop, with the instance
- sim session: registrations must be functions
- sim session: STRINGS carry every session key
- sim session: d.L overrides a string through rawget; a metatable fallback does not shadow
- sim session: print and debug are read at call time; the defaults need neither
- sim session: active, a provider answers and is handed the live fallback
- sim session: active, a member with no provider answers live
- sim session: a guarded member never reaches live while active, inside Live included
- sim session: active, Live answers live for ordinary members, nested and after a raise
- sim session: once bound, Live's traceback goes to the session's debug sink
- sim session: Sim.lua defines one Live, on the seam, and no test hook on it

### test_sim_timeline.lua (41)

- sim timeline: the file registers on the shell's minor and in MODULES
- sim timeline: the STRINGS keys the step machine prints are added to Sim.STRINGS
- sim timeline: the members overwrite the shell's fallbacks, and RunTo is not one of them
- sim timeline: Steps is the live list while running and {} idle
- sim timeline: the timeline is handed the def and the session's opts
- sim timeline: Step answers building until ready(), then plays; a second ready is ignored
- sim timeline: Step stamps ranAt, detail and index, prints STEP_LINE and nothing else
- sim timeline: Step labels a step through panel.stepLabel when the host gives one
- sim timeline: Step answers done after the last step, and the last step prints FINISHED
- sim timeline: Step answers notRunning while idle
- sim timeline: a closed gate answers settling, prints its line and does not advance
- sim timeline: a closed gate with no line prints SETTLING
- sim timeline: once the gate opens, Step plays and settling clears
- sim timeline: with no gate the gate is always open
- sim timeline: Run plays the first step at once and the next after the default 2 s
- sim timeline: Run reads a constant stepDelay
- sim timeline: Run reads stepDelay(step) for the step just played, when each timer is set
- sim timeline: Run answers notRunning, building, playing and done
- sim timeline: a Run tick on a closed gate re-polls after 0.25 s without advancing
- sim timeline: the gate is checked before every step of a Run
- sim timeline: Pause cancels the pending tick and leaves no orphan timer
- sim timeline: Pause answers notPlaying when nothing plays
- sim timeline: Resume continues a paused run; it answers notPaused otherwise
- sim timeline: Restart stops with 'restart' and starts the same scenario with a fresh seed
- sim timeline: Restart carries the caller's extra start options, all but seed (minor 2)
- sim timeline: Restart answers notRunning while idle
- sim timeline: a refused Restart prints the refusal and answers false, refused
- sim timeline: a Restart during an async prepare ignores the old ready() (C.1)
- sim timeline: RunTo plays up to and including index back to back, synchronous on an open gate
- sim timeline: RunTo waits on a closed gate by polling, then continues
- sim timeline: RunTo answers notRunning, building and done
- sim timeline: Run during a pending RunTo poll answers playing; a second RunTo retargets (C.2)
- sim timeline: Pause cancels a pending RunTo poll (C.2)
- sim timeline: Stop cancels a pending RunTo poll (C.2)
- sim timeline: a step failure ends a RunTo
- sim timeline: a play error counts the step as run, pauses the run and prints STEP_FAILED
- sim timeline: a Stop inside play leaves no stamp, no STEP_LINE and no next tick (token)
- sim timeline: a Restart inside play leaves the new session untouched (token)
- sim timeline: listeners fire on start, ready, step, run, pause and stop
- sim timeline: Status carries pos, total, playing, paused, settling and ready
- sim timeline: every timer is a session After, so Stop leaves none

### test_sim_verbs.lua (42)

- sim verbs: RunVerb is SimTimeline's, not the shell's NO_TIMELINE fallback
- sim verbs: the status, usage and state keys are added to Sim.STRINGS
- sim verbs: the empty line prints the status line and the usage, and opens the panel
- sim verbs: a nil or blank line is the empty line
- sim verbs: 'help' is not a verb (C.7): it prints the usage, as any unknown word does
- sim verbs: the usage is formatted with d.slash and appends d.usage
- sim verbs: a usage line is overridable through d.L
- sim verbs: status idle prints STATUS_IDLE with the scenario names, and is free
- sim verbs: status running names the scenario, size, seed, position and state
- sim verbs: status reads random for size 0 and no size for an unsized scenario
- sim verbs: the status state reads building, playing, paused, settling and finished
- sim verbs: status appends d.statusLine, as a line or a list, handed the status and session
- sim verbs: a statusLine that raises is a debug line, and the library's line still prints
- sim verbs: panel toggles the panel, idle or running (a free verb)
- sim verbs: start <name> starts it with no size, and prints exactly Start's lines
- sim verbs: start <name> <size> hands the size to Start
- sim verbs: the verb and the scenario name match regardless of case
- sim verbs: start of an unknown scenario prints the UNKNOWN_SCENARIO line, silently refused
- sim verbs: start with no name prints the usage
- sim verbs: start while running prints ALREADY_RUNNING once (refused is silent)
- sim verbs: a host refusal prints its own line once
- sim verbs: step dispatches to Step and prints exactly its line
- sim verbs: run dispatches to Run
- sim verbs: pause dispatches to Pause
- sim verbs: resume dispatches to Resume
- sim verbs: restart dispatches to Restart
- sim verbs: stop dispatches to Stop with the reason stop
- sim verbs: every non-free generic verb prints NOT_RUNNING while idle
- sim verbs: a failure code prints its library WHY line
- sim verbs: step on a closed gate prints the gate's line once, not a second WHY
- sim verbs: a failing step prints STEP_FAILED once, and failed is silent
- sim verbs: a refused restart is silent past the refusal's own line
- sim verbs: a library WHY line is overridable through d.L
- sim verbs: a host verb is parsed from the words and run with the command and the instance
- sim verbs: a host verb needs a session: idle it prints NOT_RUNNING and is not run
- sim verbs: a free host verb runs idle
- sim verbs: a host failure code prints d.why's line; refused stays silent
- sim verbs: a host verb that answers a library code prints the library's line
- sim verbs: a host verb whose parse answers nil prints the usage
- sim verbs: a host verb that raises prints VERB_FAILED and writes a debug line
- sim verbs: the generic verbs win over a host verb of the same name
- sim verbs: a host 'help' verb is the host's own; the library defines none

### test_sim_autoplay.lua (16)

- sim autoplay: a typed start with a synchronous ready plays on the next frame, then at stepDelay
- sim autoplay: the first tick after a typed start reads d.stepDelay for the next one
- sim autoplay: a typed start with ready held is armed and building; ready() schedules the tick
- sim autoplay: the members arm nothing: sim:Start{} and sim:Restart() leave the run waiting
- sim autoplay: a typed restart arms the new session, and no timer of the old one survives
- sim autoplay: a refused typed start arms nothing
- sim autoplay: Pause while armed and building holds it, and a later ready() schedules nothing
- sim autoplay: Stop while armed and building leaves no timer, and a stale ready() schedules nothing
- sim autoplay: a typed step while a run plays holds it, plays the next step, and stays paused
- sim autoplay: a typed step while armed and building answers building and leaves the run armed
- sim autoplay: a click-ahead while a run plays holds it and plays up to the row
- sim autoplay: a click-ahead short of the last step leaves the run paused
- sim autoplay: a second click-ahead retargets a polling one; Run still answers playing (C.2)
- sim autoplay: a manual step from the waiting state leaves paused; finishing clears it
- sim autoplay: a typed run after a manual step resumes and plays the next step at once
- sim autoplay: the start and run usage lines say a simulation plays at once

### test_sim_panel.lua (59)

- sim panel: the file registers on the shell's minor and in MODULES
- sim panel: the STRINGS keys the panel draws are added to Sim.STRINGS
- sim panel: the floor unmet (no Widgets): no attach, and the shell's fallbacks answer
- sim panel: the floor unmet (Core below 9): no attach
- sim panel: idle, the rows preview the picked scenario at pos 0, every step locked
- sim panel: PanelRows is a fresh list each call, and building it plays nothing
- sim panel: building: Start busy, every step locked and not actionable, Stop cancel
- sim panel: mid-run: done, ready, and ahead rows locked AND actionable
- sim panel: playing: the row at pos is busy
- sim panel: settling: the row at pos is busy while the gate holds the next one
- sim panel: done: every step done and none actionable; Stop still cancels
- sim panel: stopping: nothing is actionable, and the Stop row is locked
- sim panel: after a stop the rows are the idle preview again
- sim panel: d.panel.stepLabel names the rows (step, i, steps)
- sim panel: startTip and stopTip may be functions answering a line list
- sim panel: the title defaults to name .. ' - Simulation', and d.panel.title overrides it
- sim panel: headless, ShowPanel answers false and PanelRows still composes
- sim panel: Show, Hide, Toggle, IsPanelShown
- sim panel: the empty verb opens it and `panel` toggles it
- sim panel: ShowPanel answers false and does nothing while stood down
- sim panel: a stand-down stop hides it; any other stop repaints it
- sim panel: every listener notification repaints a shown panel
- sim panel: the check texture is the host's path, shown on a done row
- sim panel: height bounds are re-pinned when the row count changes
- sim panel: the picker previews the chosen scenario and offers sizes only when it has them
- sim panel: the picker's scenario takes the width the bar leaves, on one line
- sim panel: the picker's Start starts the chosen scenario through the typed verb
- sim panel: the picker's Start leaves the session playing, its first tick on the next frame
- sim panel: running, the controls are Pause, Restart and Stop, spanning the bar
- sim panel: a member start offers Resume, which sends run once ready and starts play
- sim panel: Restart's button arms the new session
- sim panel: running, the controls replace the picker, and Pause swaps with Resume
- sim panel: Restart through the controls prints what the typed verb prints
- sim panel: clicking Start, the ready row and Stop prints what typing them prints
- sim panel: clicking an ahead row runs every step up to it, in order (the internal RunTo)
- sim panel: an ahead click while a run is playing holds it and plays up to the row
- sim panel: clicking the ready row while a run plays holds it and plays one step
- sim panel: a stale click re-composes from the live model and refuses
- sim panel: with no anchor and no dragged point it floats at CENTER +420
- sim panel: it docks right of anchorTo() with DOCK_GAP 8
- sim panel: it docks left when there is no room on the right
- sim panel: it floats when neither side has room
- sim panel: a point dragged this session beats the dock, in memory only
- sim panel: ResetPanelPosition forgets the point and redocks
- sim panel: with no dragged point it redocks on every Show
- sim panel: the panel never names SavedVariables or a store
- sim panel: a row's tip goes to GameTooltip as double lines under the row's label
- sim panel: a step label truncated in its row is whole in the tooltip's first line
- sim panel: a disabled row or button still shows its tip, as the client hovers it
- sim panel: HidePanel closes the shared dropdown menu
- sim panel: Escape (the frame's OnHide, not HidePanel) closes the shared dropdown menu
- sim panel: a typed start that swaps the picker out closes the shared dropdown menu
- sim panel: scenarios filled after New: the idle rows read the first one live (minor 2)
- sim panel: scenarios filled after New: the picker's Start starts the first one (minor 2)
- sim panel: scenarios filled after New: clicking the Start row starts the first one (minor 2)
- sim panel: nothing listed yet: the Start row and the picker's Start are inert
- sim panel: a picked scenario the host drops falls back to the first listed one
- sim panel: every documented optional field filled in place after New is read at use
- sim panel: anchorTo, stepDelay and the required callbacks and slash, reassigned after New, are read at use

### test_sim_panel_render.lua (34)

- sim panel render: the renderer is the internal seam lib.__StepPanel, not a Widgets member
- sim panel render: the descriptor's required fields raise when missing
- sim panel render: the handle answers the seven members, and no frame until asked
- sim panel render: headless, Frame() answers nil and nothing raises
- sim panel render: the frame's chrome is Perf's
- sim panel render: the close mark gets the descriptor's addonName
- sim panel render: close=false draws no close mark
- sim panel render: Show, Hide, Toggle and IsShown
- sim panel render: row geometry and the test record
- sim panel render: a long label truncates before the command column, never under it
- sim panel render: a row with no command lets the label run to the row's right inset
- sim panel render: a resize moves the label's bound through its anchors, not a width
- sim panel render: every state paints Perf's palette on the label and the dot
- sim panel render: an unknown state paints as locked
- sim panel render: actionable is explicit row data and nil means false
- sim panel render: command text is repainted on every Refresh
- sim panel render: an actionable row hovers gold and leaves to its palette color
- sim panel render: an actionable cancel row hovers red
- sim panel render: a non-actionable row does not hover
- sim panel render: the tooltip is called on enter only for a row with a tip
- sim panel render: a row with a tip and no tooltip fn shows nothing
- sim panel render: a click re-reads rows() and hands onClick the fresh row and its index
- sim panel render: a row that stopped being actionable after paint is not dispatched
- sim panel render: a click on a row index the list no longer has is not dispatched
- sim panel render: a dispatched click repaints
- sim panel render: height follows the row count, and a shrink hides the extra rows
- sim panel render: a footer adds its height plus PAD, is built once and painted every Refresh
- sim panel render: the title is re-read on every Refresh
- sim panel render: red under: bounds fixed at MakeResizable time are re-pinned when the count moves
- sim panel render: the old SetMinResize / SetMaxResize pair is used where SetResizeBounds is absent
- sim panel render: a width resize stretches every row, and new rows come at the stretched width
- sim panel render: with a check, a done row shows the tinted check over a hidden dot
- sim panel render: with no check, a done row keeps its dot and no check is built
- sim panel render: with no MakeResizable in Core the panel builds fixed

### test_sim_isolation.lua (11)

- sim iso: two hosts' seams are separate objects over separate tables
- sim iso: one host's provider and active flag never reach the other's seam
- sim iso: one host's session, stop and status leave the other's untouched
- sim iso: stopping one host kills its timers only
- sim iso: one host's Run ticks advance that host only
- sim iso: two hosts build separate panel frames, and showing one shows one
- sim iso: each panel composes its own host's rows
- sim iso: a newer shell loading second re-attaches its own timeline and panel
- sim iso: an older copy loading second replaces nothing
- sim iso: a higher SimPanel minor over the same shell still wins
- sim iso: the paired copy actually drives a session (the attach is live, not a stamp)

### test_sim_stub.lua (6)

- sim stub: the session stub answers inert, member by member
- sim stub: the seam stub's Live calls through with every argument and answer
- sim stub: the session stub carries the live instance's whole surface
- sim stub: and carries nothing the live instance does not publish
- sim stub: the seam stub carries the live seam's whole surface, and nothing more
- sim stub: the instance surface is the same with or without the attach files

### test_sim_host.lua (7)

- sim host: after load every non-pure Compat member is wrapped, and Unwrapped() is empty
- sim host: idle, every wrapped member reaches the client
- sim host: the host's refusal stops a start before anything is built
- sim host: start, RunVerb('run') and stop, end to end
- sim host: the host's fields are on its own table, and the instance gained none (C.4)
- sim host: a stand-down mid-run stops first, suppresses cleanup delivery and hides the panel
- sim host: a latch set without a stop is caught by Fire's self-stop backstop

### test_loader.lua (6)

- loader: a cached chunk gives each instance its own global namespace
- loader: a chunk read once is not re-read
- loader: uncache(path) forces the next load to re-read
- loader: uncache() with no argument empties the whole cache
- loader: a missing file raises, and names the path
- loader: a file that fails to compile stays an error until it is fixed

### test_parallel.lua (4)

- parallel: every suite lands in exactly one shard, for every split
- parallel: the shards concatenate back into the original order
- parallel: the split is balanced to within one suite
- parallel: more shards than suites yields empty shards, not overlapping ones

### test_kit_limits.lua (12)

- kit guard: a guarded process sees its depth one deeper and its own arguments unchanged
- kit guard: a runner that starts itself stops at the depth limit instead of forking forever
- kit guard: the guarded child's exit code is the run's exit code
- kit guard: a run past its wall-clock limit is stopped with 124 and says so
- kit guard: KA0S_KIT_GUARD=off runs the process as it was started
- kit guard: exit statuses normalize across Lua 5.1 and 5.2+
- kit limits: a case's CPU ceiling stops a loop, even one that swallows the first error
- kit limits: a bounded call hands back every result, nils included
- kit limits: --jobs is capped by memory, never below one, and unchanged when memory is unknown
- kit limits: a host path in a suite is caught, and a WoW path is not
- kit limits: the heap budget names the case that crossed it
- kit limits: the leak gate counts what is still held, not garbage waiting to be swept

### test_kit_asserts.lua (11)

- kit: assertErrorMatches passes on a raise that carries the needle, and returns the error
- kit: assertErrorMatches fails when fn raises something else, naming both strings
- kit: assertErrorMatches fails when fn does not raise
- kit: assertLibraryConstant passes on the live bytes, and on a dotted member path
- kit: assertLibraryConstant fails on a one-byte difference, naming both strings
- kit: assertLibraryConstant fails clearly on an unknown major or member
- kit: assertLibraryConstant falls back to LibStub when the source maps the name to an instance
- kit: assertSurfaceParity's table form passes on a matching stub and compares private keys
- kit: assertSurfaceParity's table form reports every divergence once, under the default label
- kit: assertSurfaceParity's table form honors ignore as a set or an array
- kit: assertSurfaceParity refuses a live or degraded surface that is not a table

### test_kit_secrets.lua (30)

- kit: Kit.SECRET_ERROR is the fixed marker `secret value`
- kit: Kit.secret raises Kit.SECRET_ERROR on + (secret on the left)
- kit: Kit.secret raises Kit.SECRET_ERROR on + (secret on the right)
- kit: Kit.secret raises Kit.SECRET_ERROR on - (secret on the left)
- kit: Kit.secret raises Kit.SECRET_ERROR on - (secret on the right)
- kit: Kit.secret raises Kit.SECRET_ERROR on * (secret on the left)
- kit: Kit.secret raises Kit.SECRET_ERROR on * (secret on the right)
- kit: Kit.secret raises Kit.SECRET_ERROR on / (secret on the left)
- kit: Kit.secret raises Kit.SECRET_ERROR on / (secret on the right)
- kit: Kit.secret raises Kit.SECRET_ERROR on % (secret on the left)
- kit: Kit.secret raises Kit.SECRET_ERROR on % (secret on the right)
- kit: Kit.secret raises Kit.SECRET_ERROR on ^ (secret on the left)
- kit: Kit.secret raises Kit.SECRET_ERROR on ^ (secret on the right)
- kit: Kit.secret raises Kit.SECRET_ERROR on unary -
- kit: Kit.secret raises Kit.SECRET_ERROR on .. (secret on the left)
- kit: Kit.secret raises Kit.SECRET_ERROR on .. (secret on the right)
- kit: Kit.secret raises Kit.SECRET_ERROR on indexing
- kit: Kit.secret raises Kit.SECRET_ERROR on field assignment
- kit: Kit.secret raises Kit.SECRET_ERROR on call
- kit: Kit.secret raises Kit.SECRET_ERROR on < between two secrets
- kit: Kit.secret raises Kit.SECRET_ERROR on <= between two secrets
- kit: Kit.secret raises Kit.SECRET_ERROR on == between two secrets
- kit: a secret compared against a plain value still raises (the VM's own text)
- kit: what Lua 5.1 cannot trap is documented, not pretended
- kit: Kit.reveal returns the plain value, and is the identity on a non-secret
- kit: Kit.isSecret is true for a wrapper and false for 5, nil and a plain table
- kit: installSecretValue sets issecretvalue, and restore puts back an absent global
- kit: installSecretValue's restore puts back a present global
- kit: a secret minted before a second kit load and mock build is still a secret after
- kit: nothing installs issecretvalue by default

### test_kit_latch.lua (9)

- kit latch: Kit.assertLatchHoldOrder is on the kit table and published by Kit.expose
- kit latch: a conformant host passes both orders and is left up with no hold taken
- kit latch: an enable path that stands up directly fails order B (perf still held)
- kit latch: a disable path that takes no hold fails order A (releasing perf resurrects it)
- kit latch: a rebuild of the same size under different keys fails (compared by key, not count)
- kit latch: an empty R_on fails before anything is held
- kit latch: the label leads every failure message
- kit latch: table registrations are keyed by target, kind, event and unit, or by opts.key
- kit latch: missing or wrong-typed opts raise naming the field

### test_kit_bindings.lua (17)

- kit bindings: Kit.assertBindingsXml is on the kit table and published by Kit.expose
- kit bindings: a conforming file passes with string commands and returns the list
- kit bindings: NS.BINDINGS-style records and matching labels are accepted
- kit bindings: a Binding in the ADDONS category fails
- kit bindings: a header= attribute fails
- kit bindings: a default= attribute fails
- kit bindings: a missing BINDING_NAME_ global fails, and so does a wrong label
- kit bindings: the commands out of order fail
- kit bindings: a category global that is not the brand fails
- kit bindings: a file with no Binding fails
- kit bindings: a missing file fails, naming it
- kit bindings: a failure is reported at the caller's line
- kit bindings: Kit.keybindThroughTab is on the kit table and published by Kit.expose
- kit bindings: keybindThroughTab binds a key through an Options instance's row
- kit bindings: keybindThroughTab slot 2 binds the game page's key through the model
- kit bindings: keybindThroughTab slot 2 with a press that binds nothing answers the row's own line
- kit bindings: keybindThroughTab fails naming options-ui-§20 without a row or a slot

### test_mock_base.lua (33)

- mock: a frame that was never armed answers zero, dressed or not
- mock: __setGeom is the opt-in, and the only thing that arms a frame
- mock: an armed frame takes its height from the published atlas table
- mock: SetAtlas records the name whether or not a size was asked for
- mock: an atlas the table does not publish leaves geometry alone
- mock: the selected and unselected tab atlases are published at different heights
- mock: a new frame is shown until hidden, as in the client
- mock: AceGUI:Release takes a widget back: flagged, frame hidden, recorded in order
- mock: AceGUI:Release fires OnRelease, then drops the children and the callbacks
- mock: a Release reached from the widget's own OnRelease is ignored, as AceGUI's guard ignores it
- mock: AceGUI:Release(nil) raises, as the real one does
- mock: releasing a widget twice raises, as AceGUI's delWidget does
- mock: widget:Release() is AceGUI:Release(widget), as WidgetBase.Release is
- mock: AceGUI:Release wipes userdata in place and the size fields, as the real one does
- mock: an AceEvent embed records game events the way the NewAddon target does
- mock: the embed and the NewAddon target share one event implementation
- mock: UnregisterAllEvents leaves an embed's message registrations alone
- mock: embedding a target a second time keeps what it had registered
- mock: a target reused by a later mock build starts with nothing registered
- mock: a dropped mock build takes every target embedded in it with it
- mock: RegisterEvent refuses what CallbackHandler refuses
- mock: NewAddon clobbers a custom Printf exactly as it clobbers Print
- mock: the console mixins print as AceConsole's do, bare, as methods and to a given frame
- mock: a bare Printf with nothing after the format string raises, as format() does
- mock: the id lookups are absent until a harness installs them
- mock: installing the id lookups fills only what a harness has not defined
- mock: a spell record answers by id and by name, the name in any case
- mock: an uncached item keeps its icon and hides its name until it loads
- mock: an item record answers its quality by id and by link, and none while uncached
- mock: a currency record answers by id, and clearIdRecords empties every kind
- mock: the suggestion sources answer what a suite seeds -- bags, spellbook, tiers, subtext
- mock: installIdSuggestions gives an AceGUI EditBox its editbox frame, and nothing else
- mock: an AceGUI widget answers GetText and records SetType and DisableButton

### test_mock_ace.lua (39)

- ace: NewAddon with a name embeds exactly the libraries it lists
- ace: NewAddon refuses what AceAddon refuses
- ace: NewAddon(name) builds the object itself, named and printable as its name
- ace: a table with no name keeps revision 16's NewAddon, stamps and all
- ace: NewModule makes a named child addon, in creation order
- ace: a module takes its prototype, default libraries and default state
- ace: PLAYER_LOGIN initializes everything queued, then enables the addon before its modules
- ace: ADDON_LOADED initializes; enabling waits for the login
- ace: a module created disabled is skipped by the cascade and enabled on demand
- ace: Disable runs OnDisable, then disables every module, and Enable brings them back
- ace: Enable on an addon still queued for initialization only records the state
- ace: disabling an addon unregisters its events and messages and cancels its timers
- ace: an OnEnable that raises costs only itself, and the cascade reports it afterwards
- ace: RegisterMessage dispatches a string method, a default method and the optional arg
- ace: RegisterMessage refuses what CallbackHandler refuses
- ace: UnregisterAllMessages drops this target's messages and nobody else's
- ace: the library's own SendMessage fans out, and the registry holds a function as given
- ace: a registration made while a message is being sent waits for the send to finish
- ace: __fireEvent dispatches a game event the way CallbackHandler does
- ace: an event the client does not know raises on its first registration
- ace: ScheduleTimer queues a timer __fireTimers runs, with its arguments
- ace: ScheduleTimer refuses what AceTimer refuses
- ace: CancelTimer is honored, answered, and not counted as a run
- ace: a repeating timer fires once per pass until it is canceled, even from inside itself
- ace: CancelAllTimers cancels this object's timers and nobody else's
- ace: TimeLeft reads the clock; a short delay is floored at AceTimer's 0.01
- ace: a C_Timer.NewTimer handle's Cancel is honored too
- ace: RegisterChatCommand records the command and dispatches it as the client would
- ace: where the environment models SlashCmdList, RegisterChatCommand writes the client's globals
- ace: every Embed works when a consumer's wrapper calls it with its own table as self
- ace: a repeating timer keeps its delay and its TimeLeft when the test never moves the clock
- ace: only a lone table argument takes the no-name path; everything else is validated
- ace: the no-name path's CancelTimer is honored by __fireTimers
- ace: a message handler that raises costs only itself, and the send reports it afterwards
- ace: ADDON_LOADED after the login enables a load-on-demand addon, reading IsLoggedIn at call time
- ace: the AceEvent library carries the message registration API, as CallbackHandler publishes it
- ace: AceGUI's layout registry and version table carry their real names
- ace: AceDB's OnProfileCopied carries the SOURCE profile's key, as AceDB-3.0 fires it
- mock_ace: AceDB's ResetProfile fires OnProfileReset with the database alone

### test_mock_record.lua (42)

- record: a fresh build has registered nothing
- record: a raw frame:RegisterEvent is recorded, by frame and by name
- record: entries are REMOVED on unregister and on UnregisterAllEvents
- record: a per-unit registration is one row PER UNIT TOKEN
- record: AceEvent events and messages are recorded under their own kinds
- record: an embedded FRAME loses its raw and per-unit rows to UnregisterAllEvents too
- record: the survey comes back in the same order twice
- record: a bucket registration is a registration, and it is removable
- record: a bucket fires on its interval, through the one timer queue
- record: a bucket unregistered before its tick does NOT call back
- record: __fire reaches the LIVE set only
- record: __fireUnconditional reaches a target whose registration is gone
- record: __fireUnconditional drives an AceEvent handler too
- record: __fireUnconditional reaches a method-name handler after UnregisterAllEvents
- record: __fireUnconditional reaches a function handler after UnregisterEvent
- record: __fireUnconditional reaches the handler of the latest registration
- record: __fireUnconditional answers 0, and does not raise, when nothing was ever registered
- record: a second Embed in the same build keeps what __fireUnconditional can reach
- record: the timer queue is both the pending array and the live set
- record: a canceled ticker leaves the live set
- record: a repeating AceTimer stays live across a tick, and leaves on cancel
- record: a frame carrying an OnUpdate is live until the script is cleared
- record: __shownFrames answers what is on screen, in creation order
- record: a frame an addon's own mock built with __stubFrame is surveyed too
- record: every line that reached the chat frame is recorded, and resettable
- record: __printed hands back a copy, not the live log
- record: a host printer that bypasses the chat frame can still be recorded
- record: a write to the profile is reported by path and value
- record: an addon that writes nothing reports zero writes
- record: clearing a key counts as a write
- record: a global SavedVariables table can be watched explicitly
- record: two databases are told apart in the report
- record: CopyProfile onto the active profile raises AceDB's own message
- record: CopyProfile from a missing profile raises unless silent
- record: CopyProfile(missing, true) is silent, and resets the active profile as AceDB does
- record: DeleteProfile on the active profile raises AceDB's own message
- record: DeleteProfile on a missing profile raises unless silent
- record: DeleteProfile(missing, true) is silent, and a real delete still deletes
- record: SetProfile strips values equal to their defaults from the OUTGOING profile
- record: SetProfile keeps a value that differs from its default
- record: __aceguiLive counts a Create per type and gives it back on Release
- record: __aceguiLive ignores a Release it never saw created, and a registered type counts

### test_mock_events.lua (14)

- events: an EventRegistry callback appears in __registrations as kind 'callback'
- events: UnregisterCallback removes the callback from __registrations
- events: one callback per (event, owner) -- a second registration replaces the first
- events: TriggerEvent reaches a live callback as func(owner, ...) and skips a removed one
- events: RegisterCallback refuses what CallbackRegistry refuses
- events: a callback registered with no owner gets a generated numeric owner
- events: callback rows follow the other kinds, ordered by event then registration
- events: each build has its own EventRegistry
- events: frame:RegisterEvent raises on a name in __badEvents, and records nothing
- events: frame:RegisterUnitEvent raises on a name in __badEvents, and records nothing
- events: the frame path reads __badEvents at call time
- events: the frame raise names the caller, not the kit
- events: C_EventUtils.IsEventValid answers false for a bad name and true otherwise
- events: a suite may remove C_EventUtils to model an older client

### test_mock_resize.lua (6)

- resize mock: a new frame is neither resizable nor user-placed
- resize mock: SetResizable is answered back by IsResizable
- resize mock: GetResizeBounds answers the four numbers SetResizeBounds was given
- resize mock: StartSizing records the point and marks the frame user-placed
- resize mock: StartMoving marks the frame user-placed, and SetUserPlaced clears it
- resize mock: a frame's own stub (M.__stubFrame) carries the surface too

### test_mock_lines.lua (5)

- line mock: CreateLine answers a distinct object per call, recorded on its frame
- line mock: start, end, thickness and color are answered back
- line mock: a new line is shown, and Hide / Show / SetShown are tracked
- line mock: ClearAllPoints forgets both ends
- line mock: an unmodeled method raises instead of silently succeeding

### test_mock_bindings.lua (17)

- binding mock: GetBindingKey answers every key in bind order, and nil for an unbound command
- binding mock: slot order is kept across a rebind of the first slot
- binding mock: GetBindingAction answers the empty string for a free key
- binding mock: a key taken from another action leaves that action keyless
- binding mock: SetBinding and SaveBindings are refused in combat, recorded, and change nothing
- binding mock: __bindingFailNext refuses one SetBinding for that key, then clears
- binding mock: SaveBindings(2) then LoadBindings round-trips both sets
- binding mock: UPDATE_BINDINGS reaches a registered frame and not an unregistered one
- binding mock: __bindingsFireOnSet = false suppresses only SetBinding's fire
- binding mock: GetBindingName reads BINDING_NAME_ on the mock, then _G, then answers the command
- binding mock: a consumer's own GetBindingKey is kept, and the seams are installed regardless
- binding mock: the constants are the client's
- binding mock: the Enum merge keeps existing members
- binding mock: modifiers are false by default and set by M.setModifiers
- binding mock: bindKey seeds silently and clearBindings empties both sets and every log
- binding mock: the client chord helpers are absent by default
- binding mock: clientChordHelpers installs the client's chord helpers, faithfully

### test_mock_layers.lua (7)

- layer mock: strata and level are inherited through the parent chain
- layer mock: an explicit level survives until SetParent, which re-derives it
- layer mock: toplevel, clamp, parent alpha and fixed strata/level round-trip
- layer mock: Raise and Lower are counted
- layer mock: an unknown strata raises, naming itself
- layer mock: UIParent carries the recorder too
- layer mock: restore() puts CreateFrame back, and later frames are plain

### test_mock_paint.lua (13)

- paint mock: CreateTexture and CreateFontString answer distinct regions the frame owns
- paint mock: texture paint calls are recorded and answered back
- paint mock: SetAtlas on a texture records the art and sizes it from the fixture
- paint mock: font string text, color, font, font object and shadow are recorded
- paint mock: regions show, hide and answer IsVisible through their owner
- paint mock: backdrop and its two colors are recorded on the frame
- paint mock: GetChildren answers the frames parented here, in creation order
- paint mock: a NineSlice template carries the standard pieces as regions of a child
- paint mock: HookScript still chains on a recorded frame
- paint mock: a method a region does not have raises, naming itself
- paint mock: UIParent records too, and frames from __paintFrame
- paint mock: off by default, and restore() puts everything back
- paint mock: composes with the layer recorder in either order

### test_surface_parity.lua (7)

- parity: a stub carrying every public member of a live major passes
- parity: a stub missing one member fails and names it
- parity: every divergence lands in one message
- parity: a member that is a function live and something else degraded is reported
- parity: a member left out on purpose is named as data, not omitted in silence
- parity: a major the surface source cannot resolve fails rather than passes
- parity: with no surface source registered the gate fails rather than passes

### test_versioning.lua (10)

- versioning: every declared major is actually registered
- versioning: every file in every major registers its live version
- versioning: no file registers under a major it does not belong to
- versioning: every registered version is a positive integer
- versioning: file basenames are unique across every major
- versioning: the changelog accounts for the version every file is at
- versioning: every paired secondary file records which primary it attached to
- versioning: every major's live version has its API document on disk
- versioning: every major's published member manifest matches its live surface
- versioning: a dated changelog heading moves releasing.md's two version pointers with it

### test_kitsync.lua (12)

- kitsync: Kit.VERSION is a positive integer and reaches the exposed table
- kitsync: the kit revision has an API document
- kitsync: the kit revision is indexed in docs/api/README.md as the one Current revision
- kitsync: the runner is mode 100755 in the git index, in BOTH copies
- kitsync: testkit/ and tests/_kit/ hold the same set of files
- kitsync: testkit/asserts.lua, inventory.lua, secrets.lua, latch.lua, bindings_xml.lua, prose_lists.lua, prose_coverage.lua and prose_selftests.lua exist in both testkit/ and tests/_kit/
- kitsync: every kit file is byte-identical in testkit/ and tests/_kit/, README included
- kitsync: vendor_sync checks the runner's recorded mode, and this repo's copy passes
- kitsync: the runner-mode case fails on a path the index records 100644
- kitsync: the runner-mode case fails on a path the index does not track
- kitsync: the runner-mode case skips, with a reason, where there is no work tree
- kitsync: the runner-mode case skips, with a reason, where io.popen is unavailable

### test_prose.lua (6)

- prose: no British spelling in the shipped library, the shipped kit or the store roots
- prose: the live API document of a major is its highest version key, compared numerically
- prose: no British spelling in the tests, the live docs or the artwork tools
- prose: the ASCII gate scans LibKa0s/ and not testkit/
- prose: no non-ASCII byte reaches a player, the em dash excepted
- prose: no retired §N.M section reference in the shipped library or the shipped kit

### test_register.lua (1)

- every deviation id the register cites is assigned by a bundle in docs/audits/

### test_kit_inventory.lua (42)

- a kit suite declared with its directory is covered
- a bare declaration does not cover the kit's file of the same name
- an unreferenced kit suite with no local twin is the same hole
- a bare entry whose file ships only in the kit is told which directory it wants
- a recorded decline in docs/ARCHITECTURE.md is a skip, not a hole
- a recorded decline in the root CLAUDE.md is read too
- a decline is reported once however often the inventory is asserted
- a row keyed to the rule but silent about the suite grants nothing
- a row that only mentions the repo's own copy grants nothing
- a row naming the suite but keyed to another rule grants nothing
- a row in a subsection of the register is not a deviation row
- `localization-5` and `localization-§5` are the same key
- the rule each kit gate serves is written down
- no kit string literal cites a section without the section sign
- a repository with no register at all is not accidentally declined
- a listed suite that is not on disk raises, naming the path and the position
- a listed suite that is absent here but ships in the kit is told so
- a `pending` entry with no file registers a skip carrying its reason
- a `pending` entry whose file exists raises
- the kit is revision 43
- a `tests/_kit/` declaration covers the kit against a runner dir of `./tests/`
- a real shadow is still reported when the runner dir is spelled `./tests/`
- a `./` segment inside the runner dir does not fork the pair key
- a doubled slash and a missing trailing slash are the same directory
- the directory normalizer folds only the spellings it claims to
- a relative declaration is not a collision under an absolute runner dir
- an absolute declaration is not a collision under a relative runner dir
- a mixed suites list survives being invoked from another working directory
- the remedy names a `dir` a suites list can actually carry
- the two sides are resolved against each other, and only where they differ
- a remedy under a relative runner dir is printed exactly as it resolved
- characterization: a plain kit hole is reported word for word
- characterization: a kit suite with no rule row names the fallback rule
- characterization: a collision is reported word for word
- characterization: of several shadows, the last declared is the one named
- characterization: a decline's name and reason, word for word
- characterization: a decline over a collision names the file that runs instead
- characterization: a decline with an empty rule cell, and a reason clipped at 200 bytes
- --list Totals: Total counts the cases that run; a declared skip has its own row
- --list Totals: a group whose only case is a declared skip has no count row
- --list Totals: with no declared skip there is no Skipped row
- --list preamble: the badge must equal Total, and declared skips are counted apart

### test_kit_eol.lua (26)

- eol repo kind: a root .toc is the evidence even when a nested one sorts first
- eol repo kind: with no root .toc, the first nested one in tracked order
- eol repo kind: a .toc outranks a libs/ tree
- eol repo kind: a libs/ tree with no .toc, first path in tracked order
- eol repo kind: a libs/ tree outranks a library payload folder
- eol repo kind: only a top-level libs/ counts
- eol repo kind: a payload folder: its own aggregate XML with Lua beside it
- eol repo kind: Lua anywhere under the payload folder counts
- eol repo kind: of two payload folders, the first in tracked order
- eol repo kind: an aggregate XML with no Lua in its folder is not a payload
- eol repo kind: an XML not named after its folder is not a payload
- eol repo kind: an aggregate XML below the folder's top is not a payload
- eol lone CR: a line ending \r\r\n fails, naming path:line
- eol lone CR: every lone CR is named, including one at end of file
- eol lone CR: a file with a NUL byte is skipped
- eol lone CR: clean CRLF and clean LF files pass
- eol case two: the canonical body passes
- eol case two: a second pin is refused, counted
- eol case two: the wrong pin is refused, naming both
- eol case two: a missing shebang carve-out is named
- eol case two: a short body is refused, with both lengths
- eol case two: an edited comment is reported as a diff
- eol case two: an unterminated last line is one byte short
- eol case two: a line below the body without the delimiter is refused
- eol case two: an appendix's bad entries are each reported
- eol case two: a conforming appendix passes

### test_kit_prose.lua (15)

- prose scan-back: a store-root perf-analysis README is read though its folder is skipped
- prose scan-back: a store-root automated-tests README is read
- prose scan-back: a store-root automated-tests RESULTS.md is read
- prose scan-back: a dated perf-analysis bundle stays skipped
- prose scan-back: a dated automated-tests bundle stays skipped
- prose scan-back: a store-root name one folder down is a bundle file
- prose scan-back: docs/superpowers/ is a frozen store and skipped
- prose scan-back: docs/investigations/ is a frozen store and skipped
- prose lists: the British synchronize stem is published; a root README carrying it is red
- prose lists: synchronism, synchronisms and synchronistic are allowed
- prose scan-back: restating the kit's own folder in skipDirs does not un-scan the root README
- prose scan-back: a restated kit folder in skipDirs is disclosed as suppressing nothing
- prose scan-back: a restated kit folder in skipDirs, not ignored, is refused as matching nothing
- prose scan-back: a restated kit folder in skipDirs that .pkgmeta ignores passes the refusal
- prose lists: PUBLISHED_BRITISH == #BRITISH == 92 and PUBLISHED_ALLOWED == #ALLOWED == 33

### test_kit_runner.lua (20)

- runner perf: a performance-§12 register row records skip reason (2), in the manifest and RESULTS.md
- runner perf: a library's root CLAUDE.md register is read when there is no docs/ARCHITECTURE.md
- runner perf: with no performance-§12 row the skip stays reason (1)
- runner perf: a row that disclaims the exemption is not the exemption
- runner perf: an unparseable register exits 2 before any bundle is written
- runner perf: KA0S_PERF_EXEMPT=1 counts only where no register exists
- runner complexity: empty watch-list tables print their header rows, then 'None.'
- runner complexity: a table with rows does not also say 'None.'
- runner complexity: the band table leaves out what Kit.layoutCap.exempt names, and says so
- runner complexity: with no exempt set a generated dump is listed like any other file
- runner complexity: functions lizard's reader drops are measured, methods under their own name
- runner complexity: a file lizard stays blind in fails complexity, names the file, never fails the run
- runner complexity: a function longer than lizard's default 1000 lines is not a warning (-L 1500)
- runner complexity: a lizard Traceback is a fail, figures zeroed, manifest numeric
- runner complexity: a warned run exiting 1 with a valid footer is measured, not crashed
- runner complexity: stderr noise with exit 0 does not reach the parse
- runner complexity: exit 124 is the bound note, numeric manifest, no per-file retry
- runner complexity: a file lizard raises on is crashed, named, and never reported blind
- runner complexity: a raise no single file reproduces is a whole-tree crash
- runner complexity: the real 1.24.0 for-header crash is crashed, not blind

### test_kit_vendor_sync.lua (19)

- parseIconLine: the three forms
- parseIconLine: `all` without a parenthesized reason is refused
- parseIconLine: malformed lists are refused, naming why
- iconDeclaration: absent, placed, misplaced, doubled
- iconDeclaration: anchored, so prose that mentions the line is not a second one
- iconCatalog: names and attribution by set folder
- requiredIcons: attribution travels with its set, unknown names come back
- cappedList: ten names, then a count
- vendor sync: no `LibKa0s icons:` line is the whole-folder gate
- vendor sync: `none.` ships no icon and no icon license
- vendor sync: a list ships exactly its icons and their sets' attribution
- vendor sync: an undeclared icon fails, counted and named
- vendor sync: a name the tag does not carry fails, even if a stray file vouches for it
- vendor sync: a declared icon that differs from the tag fails
- vendor sync: outside media/icons the copy is still compared whole
- vendor sync: `all` needs its reason, and with one is the whole folder
- prune-icons: a list keeps its icons and attribution, and the gate then passes
- prune-icons: none empties the folder; all and no line remove nothing
- prune-icons: an unknown name is refused and nothing is removed

### test_eol.lua (2)

- eol: every tracked file carries the terminator .gitattributes declares for it
- eol: .gitattributes is line-endings-§5's canonical body for this repo kind

### test_layout_cap.lua (13)

- layoutcap: every authored file over the 1500-line cap is named in the census
- layoutcap: no census row outlives the breach it records
- layoutcap: every over-cap census row carries one of layout-§1's three terminal states
- layoutcap: the census and the exempt set agree about which paths were exempted
- layoutcap: an empty census is written as a result rather than left standing empty
- layoutcap self-test: the parser reads the census nested under the register, and stops there
- layoutcap self-test: a census outside its register, or at the wrong level, is not read
- layoutcap self-test: an over-cap file missing from the census is reported, and an exempt one is not
- layoutcap self-test: a census row that outlives its breach is reported
- layoutcap self-test: an over-cap row that names no terminal state is reported
- layoutcap self-test: the census and the exempt set are held to naming the same paths
- layoutcap self-test: a census that states nothing is told apart from one that states none
- layoutcap self-test: the exempt set takes folders as well as paths

### test_diagnostics_contract.lua (9)

- diagnostics contract: both forms run the report
- diagnostics contract: the debug word is matched in any case
- diagnostics contract: both markers carry the brand and the end counts the report
- diagnostics contract: the report appends after what the console already holds
- diagnostics contract: the report lands with logging off and turns it on for the session
- diagnostics contract: an addon that opts out lands the report and leaves logging off (skipped: this addon keeps the default (Kit.diagnostics.enablesLogging is not false), so its report turns logging on; the case above holds it)
- diagnostics contract: with logging already on, the report writes no second enable line
- diagnostics contract: both forms run while the addon is disabled
- diagnostics contract: no other name runs the report

### test_lizard_sighted.lua (8)

- lizard sighted: every hazard lizard loses a function over is neutralized
- lizard sighted: fields, strings, comments and look-alike names come through unchanged
- lizard sighted: a method definition is rewritten to its dot form with self
- lizard sighted: no line is added or removed, CRLF included
- lizard sighted: countFunctions counts the keyword, not strings, comments or longer names
- lizard sighted: listedCounts reads the per-file table, once per file
- lizard sighted: parity names every file whose counts differ, and only those
- lizard sighted: lizard lists every function of a hazard fixture once it is sanitized

## Totals

| Suite | Cases |
|-------|------:|
| test_core.lua | 52 |
| test_core_resize.lua | 24 |
| test_env.lua | 9 |
| test_compat.lua | 49 |
| test_lifecycle.lua | 22 |
| test_lifecycle_debug.lua | 14 |
| test_bus.lua | 30 |
| test_schema.lua | 32 |
| test_schema_write.lua | 41 |
| test_schema_batch.lua | 22 |
| test_pool.lua | 23 |
| test_item.lua | 23 |
| test_glow.lua | 15 |
| test_media.lua | 37 |
| test_skin.lua | 27 |
| test_skin_defs.lua | 24 |
| test_skin_paint.lua | 32 |
| test_skin_paint_controls.lua | 28 |
| test_skin_eui.lua | 29 |
| test_skin_ace.lua | 22 |
| test_widgets.lua | 58 |
| test_widgets_reorderlist.lua | 24 |
| test_widgets_draghandle.lua | 46 |
| test_widgets_draghandle_place.lua | 10 |
| test_widgets_draghandle_layers.lua | 10 |
| test_widgets_linechart_math.lua | 21 |
| test_widgets_linechart.lua | 19 |
| test_widgets_autocomplete.lua | 37 |
| test_widgets_searchbox.lua | 16 |
| test_widgets_teststrip.lua | 17 |
| test_widgets_reorder.lua | 7 |
| test_widgets_skin.lua | 24 |
| test_debuglog.lua | 75 |
| test_debuglog_copytiming.lua | 10 |
| test_debuglog_diagnostics.lua | 47 |
| test_debuglog_gates.lua | 20 |
| test_debuglog_descriptor.lua | 7 |
| test_resize_windows.lua | 23 |
| test_tool_windows_layering.lua | 8 |
| test_tool_windows_skin.lua | 14 |
| test_slash.lua | 74 |
| test_slash_parse.lua | 33 |
| test_slash_disabled.lua | 16 |
| test_slash_refusal.lua | 7 |
| test_slash_profile.lua | 30 |
| test_slash_debug.lua | 14 |
| test_launcher.lua | 45 |
| test_atenable.lua | 21 |
| test_options.lua | 61 |
| test_options_render.lua | 25 |
| test_options_bulk.lua | 11 |
| test_options_fontpreload.lua | 11 |
| test_options_widgets.lua | 53 |
| test_options_choicegrid.lua | 22 |
| test_options_flow.lua | 48 |
| test_options_landing.lua | 18 |
| test_options_ids.lua | 35 |
| test_options_idlist.lua | 24 |
| test_options_idlist_layout.lua | 39 |
| test_options_tabs.lua | 41 |
| test_options_tabbed.lua | 20 |
| test_options_nav.lua | 14 |
| test_options_drawer.lua | 26 |
| test_options_keybinds_model.lua | 26 |
| test_options_keybinds.lua | 30 |
| test_options_keybinds_sync.lua | 14 |
| test_options_appearance.lua | 26 |
| test_options_idsuggest.lua | 29 |
| test_options_idsuggest_frames.lua | 15 |
| test_options_idlist_remove.lua | 8 |
| test_options_switched.lua | 9 |
| test_options_combat.lua | 33 |
| test_options_combat_debug.lua | 16 |
| test_options_compose.lua | 51 |
| test_options_compose_master.lua | 15 |
| test_options_compose_tooltips.lua | 12 |
| test_options_reset_tooltip.lua | 7 |
| test_options_skin.lua | 15 |
| test_options_compose_skin.lua | 10 |
| test_options_throttle.lua | 4 |
| test_perf_core.lua | 78 |
| test_perf_run.lua | 42 |
| test_perf_panel.lua | 46 |
| test_perf_command.lua | 22 |
| test_perf_budget.lua | 11 |
| test_perf_toplevel.lua | 7 |
| test_perf_isolation.lua | 12 |
| test_sim_seam.lua | 27 |
| test_sim_session.lua | 55 |
| test_sim_timeline.lua | 41 |
| test_sim_verbs.lua | 42 |
| test_sim_autoplay.lua | 16 |
| test_sim_panel.lua | 59 |
| test_sim_panel_render.lua | 34 |
| test_sim_isolation.lua | 11 |
| test_sim_stub.lua | 6 |
| test_sim_host.lua | 7 |
| test_loader.lua | 6 |
| test_parallel.lua | 4 |
| test_kit_limits.lua | 12 |
| test_kit_asserts.lua | 11 |
| test_kit_secrets.lua | 30 |
| test_kit_latch.lua | 9 |
| test_kit_bindings.lua | 17 |
| test_mock_base.lua | 33 |
| test_mock_ace.lua | 39 |
| test_mock_record.lua | 42 |
| test_mock_events.lua | 14 |
| test_mock_resize.lua | 6 |
| test_mock_lines.lua | 5 |
| test_mock_bindings.lua | 17 |
| test_mock_layers.lua | 7 |
| test_mock_paint.lua | 13 |
| test_surface_parity.lua | 7 |
| test_versioning.lua | 10 |
| test_kitsync.lua | 12 |
| test_prose.lua | 6 |
| test_register.lua | 1 |
| test_kit_inventory.lua | 42 |
| test_kit_eol.lua | 26 |
| test_kit_prose.lua | 15 |
| test_kit_runner.lua | 20 |
| test_kit_vendor_sync.lua | 19 |
| test_eol.lua | 2 |
| test_layout_cap.lua | 13 |
| test_diagnostics_contract.lua | 8 |
| test_lizard_sighted.lua | 8 |
| Skipped | 2 |
| **Total** | **3026** |
