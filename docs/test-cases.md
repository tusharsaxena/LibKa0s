# Test Cases

The full inventory of every headless test case in this repo, grouped by the suite file it
lives in. The `## Totals` table below is the **authoritative pass count** — the README test
badge and any count quoted in the docs must agree with it.

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

### test_env.lua (10)

- env: GetAddOnMetadata reads the TOC through C_AddOns
- env: GetAddOnMetadata falls back to the deprecated bare global
- env: GetAddOnMetadata answers nil when neither reader exists
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

### test_schema.lua (73)

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

### test_item.lua (15)

- item: ItemIDFromLink pulls the id out of a full link
- item: ItemIDFromLink accepts a bare itemString
- item: ItemIDFromLink answers nil for anything that is not a link
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

### test_media.lua (20)

- media: every name in ICONS has a file, and every file has a name
- media: the icon license ships beside the art
- media: every name in TEXTURES has a file, and every file has a name
- media: Texture builds the vendored path, WITHOUT the extension
- media: the texture keys are the labels a player reads
- media: every font in FONTS ships with its license
- media: ICONS holds no duplicate
- media: Icon builds the vendored path, WITHOUT the extension
- media: the file behind an icon path is still <name>.tga on disk
- media: Font builds the vendored path from the catalog's own filename
- media: an unknown name answers nil rather than a plausible path
- media: a missing addon name answers nil rather than a path into nowhere
- media: a consumer that vendors elsewhere passes its own path
- media: RegisterLSM registers every font and every texture, by catalog name
- media: RegisterLSM flags the face western+ruRU, so a ruRU client keeps it
- media: RegisterLSM counts only what LibSharedMedia kept
- media: RegisterLSM counts a face another copy registered first
- media: an LSM without the locale bits gets a plain Register
- media: an LSM without IsValid counts every Register call, as minor 3 did
- media: no LibSharedMedia is 0 registrations, not an error

### test_widgets.lua (81)

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
- draghandle: DragHandle is at minor 3, the close mark's minor
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

### test_widgets_reorder.lua (5)

- reorder: a host OnUpdate on a row frame survives a drag start and end
- reorder: a row frame with no OnUpdate is never given one
- reorder: two lists with different lineColor show their own color on one pooled container
- reorder: the drop line is released after Cancel
- reorder: the drop line goes back at the drop, and the next drag reuses it

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

### test_debuglog_diagnostics.lua (35)

- diag: the caps are pinned as literals, and the file registers under the major
- diag: both markers carry the brand, and the end marker counts every line
- diag: with no brandName the markers name the title
- diag: the identity header names the host, the client, the flags and the running minors
- diag: a combat read that raises prints unreadable and costs nothing else
- diag: an initSummary that raises prints unreadable and the header still follows
- diag: BuildDiagnostics writes nothing
- diag: the report appends, and the trace before it survives
- diag: the report never calls Clear
- diag: the report is ungated: it lands with logging off and leaves the flag alone
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

### test_slash.lua (110)

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
- sl: ParseBool accepts the same eight words the error string advertises
- sl: ParseBool answers nil, never false, for a non-boolean word
- sl: booleans accept the whole human vocabulary
- sl: a junk boolean is rejected and the accepted words are listed
- sl: a number is clamped to the row's range rather than rejected
- sl: a non-numeric value for a number row is rejected
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
- launcher: minor 4 is live
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

### test_options.lua (85)

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
- options: RefreshPanel defers a hidden page to its next show
- options: RefreshPanel ignores a non-ctx rather than raising
- options: a ctx that never went through SetRenderer keeps the old ungated behavior
- options: OpenOptionsPanel REFUSES under combat and does not defer-and-replay
- options: OpenOptionsPanel opens the registered category out of combat
- options: :New refuses a descriptor with no mainPanelName
- options: a host that omits print still sees the combat refusal in the chat frame
- options: CreateOptionsPanel is idempotent in both the category and the refreshers
- options: OpenOptionsPanel is a silent no-op before CreateOptionsPanel has run
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

### test_options_widgets.lua (227)

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
- widgets: a raising row costs that row and no other
- widgets: RenderGrid lays arbitrary items out two per row
- widgets: RenderGrid gives a wide item its own full-width row
- widgets: RenderGrid guards each item the way RenderRows guards each row
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
- IdList: one line per entry -- icon, name and gray id, then Remove or a checkbox
- IdList: an entry's note is drawn under its name, and only when it has one
- IdList: an empty-string or non-string note draws nothing
- IdList: an entry's suffix is drawn inside the label, after the gray id and in the same gray
- IdList: an entry with no suffix renders exactly as it did at minor 24
- IdList: a suffixed entry still pairs up at two columns -- it is not a full-width row
- IdList: a suffix and a note on one entry -- the note wins its line, the suffix stays inline
- IdList: a suffix is concatenated, so a % or a |c in it reaches the client as written
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
- IdList: a help level tints the mark, and an entry that names none keeps its gold
- IdList: an unknown level draws the default, and a hover leaves a mark its own color
- IdList: a one-column list still wraps, and now lights too (minor 28)
- IdList: the no-wrap FontString is put back when AceGUI takes the widget back
- IdList: release clears the markers, so a pooled label cannot answer for the next list
- IdList: a label with no FontString still has its markers cleared
- IdList: at more than one column the hovered entry is lit, so the tooltip has an owner
- IdList: a multi-column tooltip hangs off the row, not over the column beside it
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
- widgets: a number row carrying a values list renders as a Dropdown, not a Slider
- widgets: the numeric dropdown lists its entries with their own labels
- widgets: the numeric dropdown seeds the STORED number, not a stringified copy
- widgets: choosing an entry writes the number through the host's set
- widgets: a number row with NO values list still renders as a Slider
- widgets: a number row whose values function answers empty falls back to a Slider
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
- widgets: a string row with no values and no dialogControl prints once and still renders
- widgets: a values-backed row that is momentarily empty does NOT warn

### test_options_tabs.lua (54)

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
- widgets: a host tab sits before the group it names and renders through its callback
- widgets: a host tab keyed by a group takes that group's place and is handed its rows
- widgets: a stale active tab heals to the first tab when only host tabs remain
- widgets: disabledFor draws the notice ABOVE the rows, and the rows disabled
- widgets: disabledFor false draws no notice and live rows; a raising one reads as enabled
- widgets: a host tab renders under the page's disable, and the flag never outlives it
- widgets: chrome is called once per render, after the strip and before the rows
- widgets: with OptionsTabs.lua absent RenderTabbedSchema takes opts and renders untabbed
- widgets: the tab half alone does not define RenderTabbedSchema over no flow engine
- widgets: PageBanner's action draws a Button whose click calls onClick
- widgets: PageBanner's action button is Released like its picker, never leaked
- widgets: PageBanner's action re-rendering from its own click never hands itself back
- widgets: PageBanner's action is refused in combat, like its picker

### test_options_idsuggest.lua (40)

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

### test_options_combat.lua (32)

- combat: a page shown in combat is covered and not drawn, and the window is left alone
- combat: the cover is built out of combat, hidden, and takes the mouse and the wheel
- combat: REGEN_DISABLED covers an open tabbed page above its tab strip
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

### test_options_compose.lua (45)

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

### test_options_throttle.lua (4)

- throttle: a nil-returning scheduleTimer still gets ONE slider timer per window
- throttle: a nil-returning scheduleTimer still gets ONE color timer per window
- throttle: the window re-arms after it fires, for a nil-returning host
- throttle: a host whose timer answers a handle is unchanged

### test_perf_core.lua (71)

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

### test_perf_run.lua (40)

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

### test_perf_panel.lua (45)

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

### test_perf_command.lua (20)

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

### test_kit_asserts.lua (7)

- kit: assertErrorMatches passes on a raise that carries the needle, and returns the error
- kit: assertErrorMatches fails when fn raises something else, naming both strings
- kit: assertErrorMatches fails when fn does not raise
- kit: assertLibraryConstant passes on the live bytes, and on a dotted member path
- kit: assertLibraryConstant fails on a one-byte difference, naming both strings
- kit: assertLibraryConstant fails clearly on an unknown major or member
- kit: assertLibraryConstant falls back to LibStub when the source maps the name to an instance

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

### test_mock_record.lua (37)

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

### test_surface_parity.lua (7)

- parity: a stub carrying every public member of a live major passes
- parity: a stub missing one member fails and names it
- parity: every divergence lands in one message
- parity: a member that is a function live and something else degraded is reported
- parity: a member left out on purpose is named as data, not omitted in silence
- parity: a major the surface source cannot resolve fails rather than passes
- parity: with no surface source registered the gate fails rather than passes

### test_versioning.lua (9)

- versioning: every declared major is actually registered
- versioning: every file in every major registers its live version
- versioning: no file registers under a major it does not belong to
- versioning: every registered version is a positive integer
- versioning: file basenames are unique across every major
- versioning: the changelog accounts for the version every file is at
- versioning: every paired secondary file records which primary it attached to
- versioning: every major's live version has its API document on disk
- versioning: every major's published member manifest matches its live surface

### test_kitsync.lua (12)

- kitsync: Kit.VERSION is a positive integer and reaches the exposed table
- kitsync: the kit revision has an API document
- kitsync: the kit revision is indexed in docs/api/README.md as the one Current revision
- kitsync: the runner is mode 100755 in the git index, in BOTH copies
- kitsync: testkit/ and tests/_kit/ hold the same set of files
- kitsync: testkit/asserts.lua and testkit/prose_lists.lua exist in both testkit/ and tests/_kit/
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

### test_kit_inventory.lua (38)

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
- the kit is revision 27
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

### test_kit_eol.lua (16)

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

### test_kit_runner.lua (7)

- runner perf: a performance-§12 register row records skip reason (2), in the manifest and RESULTS.md
- runner perf: a library's root CLAUDE.md register is read when there is no docs/ARCHITECTURE.md
- runner perf: with no performance-§12 row the skip stays reason (1)
- runner perf: a row that disclaims the exemption is not the exemption
- runner perf: an unparseable register exits 2 before any bundle is written
- runner perf: KA0S_PERF_EXEMPT=1 counts only where no register exists
- runner complexity: empty watch-list tables print their header rows, never 'None.'

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

### test_diagnostics_contract.lua (7)

- diagnostics contract: both forms run the report
- diagnostics contract: the debug word is matched in any case
- diagnostics contract: both markers carry the brand and the end counts the report
- diagnostics contract: the report appends after what the console already holds
- diagnostics contract: the report lands with logging off and leaves it off
- diagnostics contract: both forms run while the addon is disabled
- diagnostics contract: no other name runs the report

## Totals

| Suite | Cases |
|-------|------:|
| the runner | 1 |
| test_core.lua | 52 |
| test_env.lua | 10 |
| test_compat.lua | 49 |
| test_lifecycle.lua | 22 |
| test_bus.lua | 30 |
| test_schema.lua | 73 |
| test_schema_batch.lua | 22 |
| test_pool.lua | 23 |
| test_item.lua | 15 |
| test_media.lua | 20 |
| test_widgets.lua | 81 |
| test_widgets_draghandle.lua | 46 |
| test_widgets_reorder.lua | 5 |
| test_debuglog.lua | 75 |
| test_debuglog_copytiming.lua | 10 |
| test_debuglog_diagnostics.lua | 35 |
| test_slash.lua | 110 |
| test_slash_refusal.lua | 7 |
| test_launcher.lua | 45 |
| test_options.lua | 85 |
| test_options_bulk.lua | 11 |
| test_options_fontpreload.lua | 11 |
| test_options_widgets.lua | 227 |
| test_options_tabs.lua | 54 |
| test_options_idsuggest.lua | 40 |
| test_options_idlist_remove.lua | 8 |
| test_options_switched.lua | 9 |
| test_options_combat.lua | 32 |
| test_options_compose.lua | 45 |
| test_options_throttle.lua | 4 |
| test_perf_core.lua | 71 |
| test_perf_run.lua | 40 |
| test_perf_panel.lua | 45 |
| test_perf_command.lua | 20 |
| test_perf_isolation.lua | 12 |
| test_loader.lua | 6 |
| test_parallel.lua | 4 |
| test_kit_limits.lua | 12 |
| test_kit_asserts.lua | 7 |
| test_mock_base.lua | 33 |
| test_mock_ace.lua | 39 |
| test_mock_record.lua | 37 |
| test_mock_events.lua | 14 |
| test_surface_parity.lua | 7 |
| test_versioning.lua | 9 |
| test_kitsync.lua | 12 |
| test_prose.lua | 6 |
| test_register.lua | 1 |
| test_kit_inventory.lua | 38 |
| test_kit_eol.lua | 16 |
| test_kit_prose.lua | 15 |
| test_kit_runner.lua | 7 |
| test_eol.lua | 2 |
| test_layout_cap.lua | 13 |
| test_diagnostics_contract.lua | 7 |
| **Total** | **1730** |
