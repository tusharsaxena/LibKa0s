# Test Cases

_Generated — do not hand-edit. Regenerate with `lua tests/run.lua --list > docs/test-cases.md`._

### test_perf_core.lua (49)

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

### test_perf_panel.lua (39)

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

## Totals

| Suite | Count |
|-------|-------|
| test_perf_core.lua | 49 |
| test_perf_run.lua | 33 |
| test_perf_panel.lua | 39 |
| test_perf_command.lua | 17 |
| test_perf_isolation.lua | 9 |
| **Total** | **147** |
