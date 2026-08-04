# Test Cases

The full inventory of every headless test case in this repo, grouped by the suite file it
lives in. The `## Totals` table below is the **authoritative pass count** — the README test
badge and any count quoted in the docs must agree with it.

**Generated — do not hand-edit.** Regenerate with `lua tests/run.lua --list > docs/test-cases.md`.

### test_core.lua (29)

- core: IsConcatSafe is false for a table.concat-hostile value, true for a plain one
- core: SafeToString renders a secret as lib.SECRET and passes nil/booleans through
- core: Print joins with a space, prefixes verbatim, and routes through the injected sink
- core: sep separates the prefix from the body and may be empty
- core: a function prefix is re-read on every call
- core: a prefix that has not resolved yet prints the body alone
- core: Format applies the format string with pre-stringified args
- core: the default sink is DEFAULT_CHAT_FRAME:AddMessage
- core: :New refuses a descriptor with no prefix
- core: ApplySkin no-ops on a frame without SetBackdrop
- core: ApplySkin applies the skin table and both colours
- core: SKIN is the flat 1px Ka0s edge, not the 12px tooltip border
- core: ApplySkin synthesises the inner highlight, exactly once
- core: ApplySkin survives a frame whose metatable answers every key
- core: ApplySkin tints a title and a divider when the frame carries them
- core: ApplySkin lays the backdrop down before anything drawn on top of it
- core: ApplySkin tolerates a frame with neither a title nor a divider
- core: ApplySkin honours an explicit skin table
- core: RGBA reads the keyed shape
- core: RGBA reads the positional shape
- core: RGBA lets the keyed shape win every channel, never mixing the two
- core: RGBA falls back per channel, so a three-element color keeps its default alpha
- core: RGBA keeps a stored false rather than swallowing it
- core: RGBA returns the defaults unchanged for a non-table
- core: RGBA does not default the defaults
- core: MakeCloseButton returns a button wired to onClick
- core: MakeCloseButton returns nil when CreateFrame is unavailable
- core: Perf refuses to register when Core is missing or below NEEDS_CORE
- core: Perf's own stringifier renders a secret as <secret>

### test_debuglog.lua (56)

- dbg: FormatPlain wraps the tag in brackets with single-space separators
- dbg: FormatPlain tolerates a nil tag
- dbg: FormatColored colours the timestamp and tag; pipe and content default
- dbg: both formatters are reachable on an instance as well as on the library
- dbg: the window title is the host's, with the library's suffix appended
- dbg: a host can override the title suffix
- dbg: Add appends the plain form to the buffer and is never gated on the flag
- dbg: the cap is 500 and the message frame is held to the same number
- dbg: the buffer is capped, dropping the oldest line
- dbg: the buffer stays a dense array of plain strings
- dbg: Clear wipes the buffer and works before the window was ever built
- dbg: BufferSize, LastLine and FindLine answer without reaching into .buffer
- dbg: the sink routes the first arg as the [tag] and every vararg through safeToString
- dbg: the sink is a no-op, and does no work at all, when logging is off
- dbg: the sink is dot-callable, because host call sites bind it bare
- dbg: the sink survives a format the stringified args cannot satisfy
- dbg: an ordinary format is NOT routed through the fallback
- dbg: SetEnabled writes the flag through the host, not into the library
- dbg: SetEnabled normalises a truthy value to a boolean
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
- dbg: Add sends the COLOURED form to the console and the plain one to the buffer
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
- an L whose metatable synthesises every key does NOT mask the module's own strings
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
- dbg: a wider host close button pushes Copy and Clear out of its way
- dbg: a close button with no measurable width falls back to the library's own
- dbg: with no close button at all the offsets are still the minor-3 defaults

### test_slash.lua (81)

- sl: an empty message prints the help index
- sl: whitespace-only input is treated as empty
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
- sl: FormatValue reads a POSITIONAL colour as well as a named-key one
- sl: a positional colour with a secret component still renders the sentinel
- sl: a host colour codec round-trips through set and its echo
- sl: CliReset's echo uses the host colour codec too
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
- sl: a key SET labels its entries with its keys, not with 'true'
- sl: an enum supplied as a function is evaluated at parse time
- sl: a colour parses r g b with an optional alpha
- sl: a colour given in 0-255 is rescaled, and all three channels together
- sl: a colour missing a channel is rejected with the expected form
- sl: an unknown row type is rejected by name
- sl: list groups rows under the host's own group keys, indented
- sl: the list keeps its own colours — green header, azure group headings
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
- sl: version prints one line and nothing else
- sl: the annotator fires on list, get and set — and on nothing else
- sl: the annotation follows the coloured pair rather than interrupting it
- sl: with no annotator set, nothing is appended
- sl: Slash refuses to register without Core
- sl: an L whose metatable synthesises every key does NOT mask the module's strings
- sl: a REAL entry in an L that also has a fallback still overrides
- sl: a plain L table overrides exactly as before
- slash: a host can supply its own value formatter for a type the library does not know
- slash: the format hook reaches the get, set and reset echoes too
- slash: a host with no format hook renders exactly as it always did
- slash: the format hook takes precedence over the colour codec, and gets the raw stored value
- slash: format beats colorDecode at the get, set and reset echoes, and colorEncode still runs

### test_options.lua (63)

- options: the major registers all three of its files
- options: an instance carries the shell, the widget makers and the scroll patch
- options: two instances own separate panel registries
- options: CreatePanel returns a ctx wired to a panel, a body and an empty refresher list
- options: CreatePanel names the panel with the plain title for the category tree
- options: CreatePanel starts the panel hidden and registers it
- options: the header title takes the parent breadcrumb, and isMain opts out
- options: __panelFor finds a registered page by key
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
- options: RestoreAllDefaults fires afterRestoreAll BEFORE refreshing the panels
- options: RestoreAllDefaults honours the host's skipRestoreAll veto
- options: RefreshAllPanels runs every registered panel's refreshers, isolating a thrower
- options: registered page builders run in registration order, once, at CreateOptionsPanel
- options: CreateOptionsPanel hands the host the AceGUI it resolved
- options: CreateOptionsPanel says so and returns when AceGUI is missing
- options: the main canvas is registered under the host's brand
- options: the main page's body is deferred to its first OnShow, and built once
- options: a raising page builder costs that page and no other
- options: a page registered after the build is built immediately
- options: SetRenderer draws on first show, and not again
- options: a panel shown during combat closes the window and does not render
- options: a raising renderer is reported, not propagated
- options: RefreshScalars re-syncs a shown page and flags a hidden one dirty
- options: a dirty hidden page re-renders on its next show
- options: the two tiers differ — one re-renders, the other only re-syncs
- options: a ctx that never went through SetRenderer keeps the old ungated behaviour
- options: OpenOptionsPanel REFUSES under combat and does not defer-and-replay
- options: OpenOptionsPanel opens the registered category out of combat
- options: :New refuses a descriptor with no mainPanelName
- options: a host that omits print still sees the combat refusal in the chat frame
- options: CreateOptionsPanel is idempotent in both the category and the refreshers
- options: OpenOptionsPanel is a silent no-op before CreateOptionsPanel has run
- options: LSMValues returns a DEFERRED closure, not a snapshot
- options: LSMValues offers a None placeholder rather than an empty list
- options: EnsureScroll is lazy, created once, and patched
- options: the scrollbar patch is idempotent
- options: FixScroll disables the bar when the content fits, enables it when it does not
- options: OnRelease restores AceGUI's own FixScroll and clears the marker
- options: CreatePanel stamps the three Blizzard canvas callbacks
- options: OnCommit and OnRefresh are inert and safe to call
- options: OnDefault forwards to a defaultsOnClick parked AFTER CreatePanel
- options: OnDefault and the header Defaults button run the SAME action
- options: a page with no defaults action still has a callable, inert OnDefault
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

### test_options_widgets.lua (82)

- widgets: the cross-slice layout constants are published on the instance
- widgets: a bool row renders a CheckBox labelled and seeded from the schema
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
- widgets: a row with explicit `sorting` keeps that order instead of alphabetising
- widgets: a dropdown falls back to a plain Dropdown when its dialogControl is unregistered
- widgets: a dropdown uses its dialogControl widget when that IS registered
- widgets: a dropdown writes the chosen value, and its refresher re-applies the LIST
- widgets: a dropdown built from an ordered array keeps declaration order
- widgets: a key set labels its entries with its keys, not with 'true'
- widgets: the dropdown's options and the CLI's allowed values agree, in both shapes
- widgets: a colour row opts OUT of alpha by declaring it, and cannot before
- widgets: a tooltip body comes from `tooltip`, with `desc` still accepted
- widgets: a slider does not commit on drag by default
- widgets: sliderCommit = 'change' commits on drag, throttled, last value wins
- widgets: commitOn on a row overrides the descriptor default, both ways
- widgets: a raising row costs that row and no other
- widgets: RenderGrid lays arbitrary items out two per row
- widgets: RenderGrid gives a wide item its own full-width row
- widgets: RenderGrid guards each item the way RenderRows guards each row
- widgets: a string row asking for an EditBox gets one, not a dropdown
- widgets: an edit box commits on OnEnterPressed and re-reads on refresh
- widgets: a color row renders a ColorPicker seeded through the descriptor's codec
- widgets: a color picker substitutes 1s for a missing or corrupt stored colour
- widgets: the colour codec is the descriptor's, so an array-storing host is not translated
- widgets: disabledIf greys the swatch out while its sibling toggle is on
- widgets: OnValueConfirmed commits immediately — cancel must not wait on the throttle
- widgets: OnValueChanged throttles a drag to ONE timer and commits the LAST value
- widgets: a colour drag does NOT refresh every panel
- widgets: every other maker's write DOES refresh every panel
- widgets: RenderField dispatches each schema type to its widget
- widgets: RenderField returns nil for an unrecognised type instead of erroring
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
- widgets: a number row carrying a values list renders as a Dropdown, not a Slider
- widgets: the numeric dropdown lists its entries with their own labels
- widgets: the numeric dropdown seeds the STORED number, not a stringified copy
- widgets: choosing an entry writes the number through the host's set
- widgets: a number row with NO values list still renders as a Slider
- widgets: a number row whose values function answers empty falls back to a Slider
- widgets: TextRow adds a full-width Label carrying the text
- widgets: TextRow left-justifies by default and honours an explicit justify
- widgets: TextRow applies a font object by NAME, and only when the global exists
- widgets: TextRow draws nothing and returns nil when there is no scroll to draw into
- widgets: BuildLandingPage draws the logo block at its declared size, then a spacer
- widgets: BuildLandingPage honours an explicit logoSize
- widgets: a logo whose widget has no backing frame costs the logo, not the page
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

### test_perf_core.lua (57)

- lib: registers under its major with a schema and a default ring
- lib: New requires a name, an sv global and a suspend/resume pair
- lib: New rejects a bucket entry with no key, in the library's own words
- lib: a ring of zero is clamped to one, not left to empty itself
- lib: a negative ring is clamped too
- lib: two instances share no state
- lib: bucket order and nesting come from the descriptor
- lib: the capture gate starts off
- lib: Note accumulates calls, total and max
- lib: Note tracks unrelated buckets independently
- lib: Reset clears every bucket and both fps arms
- lib: Open returns nil while the probe is off
- lib: Close on a nil t0 is a silent no-op
- lib: a real bracket records its elapsed ms to the named bucket
- lib: Open/Close feed the same buckets P.Note does
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
- lib: a record built before Start has no context at all
- lib: a Note key the descriptor never declared still lands in the record
- lib: Save creates the perf global and appends the run
- lib: Save stamps the schema on the store
- lib: Save trims the ring to ringMax, dropping the oldest
- lib: a ring written under another schema is discarded, not converted
- lib: FormatReport emits its sections in reading order
- lib: FormatReport marks an unsampled arm rather than printing zeros
- lib: FormatReport prints both arms and the delta when both ran
- lib: FormatReport derives ms/s from the active seconds only
- lib: FormatReport warns that buckets nest
- lib: FormatReport omits buckets that never fired
- lib: FormatReport indents a nested bucket under its parent
- lib: a flat bucket set gets no nesting footer
- lib: Context captures character, spec, zone and group
- lib: Context reports solo when ungrouped
- lib: Context reports party size and instance type
- lib: Context reports raid size
- lib: ContextLines folds the sub-zone into the location
- lib: ContextLines omits an empty sub-zone cleanly
- lib: ContextLines tolerates a record with no context
- lib: a host passing only the four required fields gets working defaults
- perf: an L whose metatable synthesises every key does NOT mask the module's strings
- perf: a step label is never its own SCREAMING_SNAKE_CASE key
- perf: a REAL entry in an L that also has a fallback still overrides

### test_perf_run.lua (33)

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
- lib: the console log is plain text, free of colour escapes
- lib: experiments are named A and B, never active/suspended
- lib: the run start is logged with its context
- lib: arming logs which experiment and whether the addon is suspended
- lib: measure b calls the host's suspend, measure a its resume
- lib: cancelling a suspended run restores the host
- lib: the stopwatch is driven per window

### test_perf_panel.lua (42)

- lib: before a run Start is the one offered step
- lib: Start reads done while a run is in flight
- lib: Start is offered again once a run has finished
- lib: starting a run makes exactly Measure A ready
- lib: an armed or recording experiment reads busy, not ready
- lib: completing A unlocks B and nothing else
- lib: completing B unlocks Finish
- lib: finishing unlocks Report and Dump
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
- lib: cancelling discards the run without saving it
- lib: cancelling restores a suspended addon
- lib: cancelling mid-recording does not announce the experiment as ended
- lib: cancelling detaches the sampler
- lib: cancel returns false when there is nothing to cancel
- lib: a cancelled run leaves the next one clean
- lib: every row shows its slash command
- lib: cancel stays clickable while a run is mid-experiment
- lib: cancel is not clickable once the run is finished
- lib: hiding the panel never touches the run
- lib: Toggle flips visibility both ways
- lib: decorate is handed the frame and a way to close it
- lib: a host that passes no decorate still gets a working panel
- lib: report and dump stay clickable after use, but read as done
- lib: marking a review action twice is a no-op
- lib: MarkReviewed ignores keys that are not review actions
- lib: a fresh run clears the review marks
- lib: the panel titles itself like the debug console
- lib: a locale table filled in after New still reaches the rows
- lib: every step label names what it acts on
- lib: a panel-less instance answers STEPS, PanelStateOf and PanelIsActionable safely

### test_perf_command.lua (17)

- cmd: OnCommand always returns a line table, never nil
- cmd: start begins a run and shows the panel
- cmd: a label is appended to the timestamp, never replaces it
- cmd: measure reports which window armed and whether the host is suspended
- cmd: measure outside a run tells you to start one
- cmd: measure rejects an unknown window token
- cmd: finish resumes the host before it saves
- cmd: finish prints no report
- cmd: report writes the summary to the log sink and opens it
- cmd: dump writes one line of JSON to the log sink
- cmd: cancel refuses when there is nothing to cancel
- cmd: show, hide and toggle drive the panel and nothing else
- cmd: a bare command reports the phase and prints the usage
- cmd: usage never hard-codes a slash prefix
- cmd: clicking a ready panel row takes the same path as typing it
- cmd: a panel click prints exactly what typing the command prints
- cmd: clicking a locked panel row does nothing

### test_perf_isolation.lua (9)

- iso: two instances create separate sampler frames
- iso: driving one instance's sampler accumulates into that instance alone
- iso: an instance's sampler is detached without touching the other's
- iso: two instances create separate panel frames
- iso: each panel renders its own host's state and its own slash prefix
- iso: clicking one host's panel drives that host only
- iso: a newer probe loading second brings its own panel with it
- iso: an older copy loading second replaces neither half
- iso: a higher panel minor over the same probe still wins

### test_versioning.lua (7)

- versioning: every declared major is actually registered
- versioning: every file in every major registers its live version
- versioning: no file registers under a major it does not belong to
- versioning: every registered version is a positive integer
- versioning: file basenames are unique across every major
- versioning: the changelog accounts for the version every file is at
- versioning: every paired secondary file records which primary it attached to

### test_kitsync.lua (4)

- kitsync: Kit.VERSION is a positive integer and reaches the exposed table
- kitsync: the kit revision has an API document
- kitsync: testkit/ and tests/_kit/ hold the same set of files
- kitsync: every kit file is byte-identical in testkit/ and tests/_kit/, README included

## Totals

| Suite | Cases |
|-------|------:|
| test_core.lua | 29 |
| test_debuglog.lua | 56 |
| test_slash.lua | 81 |
| test_options.lua | 63 |
| test_options_widgets.lua | 82 |
| test_perf_core.lua | 57 |
| test_perf_run.lua | 33 |
| test_perf_panel.lua | 42 |
| test_perf_command.lua | 17 |
| test_perf_isolation.lua | 9 |
| test_versioning.lua | 7 |
| test_kitsync.lua | 4 |
| **Total** | **480** |
