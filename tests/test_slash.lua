-- tests/test_slash.lua — the dispatcher, the help renderer, the formatters, and the parser.

local T = _G.LK_TEST
local slash = T.slash
local test, assertEqual = T.test, T.assertEqual

local F = dofile("tests/fixture_slash.lua")
local plain = F.plain

-- ── dispatch ───────────────────────────────────────────────────────────────────────────────

test("sl: an empty message runs the host's config verb (minor 11), printing no help", function()
  -- slash-commands-§4 (standard v2.50.0): bare /<slash> opens the settings panel on its landing
  -- page; `help` prints the list. red under: the old empty-line -> PrintHelp branch.
  local Sl, rec = F.new()
  Sl:OnSlash("")
  assertEqual(#rec.chat, 1, "one line: the config verb's own")
  assertEqual(rec.chat[1], "opened")
end)

test("sl: whitespace-only input is treated as empty", function()
  local Sl, rec = F.new()
  Sl:OnSlash("   ")
  assertEqual(#rec.chat, 1)
  assertEqual(rec.chat[1], "opened")
end)

test("sl: a host with no config verb still gets the help index for an empty message", function()
  local Sl, rec = F.new()
  for i = #rec.commands, 1, -1 do
    if rec.commands[i][1] == "config" then table.remove(rec.commands, i) end
  end
  Sl:OnSlash("")
  assertEqual(#rec.chat, #rec.commands + 1, "a header plus one row per command")
  T.assertTrue(plain(rec.chat[1]):find("slash commands", 1, true) ~= nil, "the header comes first")
end)

test("sl: `help` prints the help index", function()
  local Sl, rec = F.new()
  Sl:OnSlash("help")
  assertEqual(#rec.chat, #rec.commands + 1, "a header plus one row per command")
  T.assertTrue(plain(rec.chat[1]):find("slash commands", 1, true) ~= nil, "the header comes first")
end)

test("sl: an unknown verb names it, then prints the help index", function()
  local Sl, rec = F.new()
  Sl:OnSlash("bogus")
  T.assertTrue(rec.chat[1]:find("unknown command 'bogus'", 1, true) ~= nil, rec.chat[1])
  assertEqual(#rec.chat, #rec.commands + 2, "the error line, the header, and one row per command")
end)

test("sl: the verb is lowercased but the argument keeps its case", function()
  -- Load-bearing: schema paths are case-sensitive, so lowercasing the whole message would break
  -- every dotted path a user types.
  local Sl, rec = F.new()
  Sl:OnSlash("GET units.player.barWidth")
  assertEqual(#rec.chat, 1)
  T.assertTrue(rec.chat[1]:find("units.player.barWidth", 1, true) ~= nil,
    "the path survived intact: " .. plain(rec.chat[1]))
end)

test("sl: an alias is rewritten to its target verb", function()
  local Sl, rec = F.new()
  Sl:OnSlash("options")
  assertEqual(rec.chat[1], "opened", "the alias reached config")
  T.assertTrue(plain(rec.chat[1]):find("unknown", 1, true) == nil)
end)

test("sl: a handler receives the rest of the line, not the verb", function()
  local seen
  local Sl, rec = F.new()
  rec.commands[#rec.commands + 1] = { "echo", "echo", function(rest) seen = rest end }
  Sl:OnSlash("echo  a  b ")
  assertEqual(seen, "a  b", "trimmed at the ends, internal spacing preserved")
end)

test("sl: New requires a slash prefix and a commands table", function()
  T.assertTrue(T.assertError(function() slash:New{ commands = {} } end):find("slash", 1, true) ~= nil)
  T.assertTrue(T.assertError(function() slash:New{ slash = "/x" } end):find("commands", 1, true) ~= nil)
end)

-- ── the row formatter (decision D3) ────────────────────────────────────────────────────────

test("sl: a help row is gold command, single-spaced em dash, white description", function()
  -- The one formatter both the chat help and a host's landing page render through. Uppercase hex,
  -- one space either side of the em dash, and the description colored rather than left bare.
  assertEqual(slash.FormatRow("/th get", "Print a setting"),
    "|cFFFFFF00/th get|r \226\128\148 |cFFFFFFFFPrint a setting|r")
end)

test("sl: HelpRows indents for chat; LandingRows does not", function()
  -- A leading indent exists to sit a chat line under a header. In a settings panel, where each row
  -- is its own label, the same indent reads as a mistake.
  local Sl = F.new()
  local help, landing = Sl:HelpRows(), Sl:LandingRows()
  assertEqual(#help, #landing)
  assertEqual(help[1], "  " .. landing[1], "the indent is the only difference")
  T.assertTrue(landing[1]:sub(1, 1) ~= " ", "a landing row starts at the margin")
end)

test("sl: help rows name each verb with the host's own slash prefix", function()
  local Sl = F.new{ slash = "/kcd" }
  T.assertTrue(plain(Sl:HelpRows()[1]):find("/kcd help", 1, true) ~= nil, plain(Sl:HelpRows()[1]))
end)

test("sl: the help header carries the version and the chat alias", function()
  local Sl, rec = F.new()
  Sl:PrintHelp()
  local header = plain(rec.chat[1])
  T.assertTrue(header:find("v1.2.3", 1, true) ~= nil, header)
  T.assertTrue(header:find("/testhost", 1, true) ~= nil, "the alias is named: " .. header)
  T.assertTrue(header:find("/th", 1, true) ~= nil, header)
end)

test("sl: a host with no chat alias gets a header without the alias clause", function()
  local Sl, rec = F.new{ slashAliases = false }
  Sl:PrintHelp()
  local header = plain(rec.chat[1])
  T.assertTrue(header:find("alias", 1, true) == nil, "no dangling clause: " .. header)
  T.assertTrue(header:find("v1.2.3", 1, true) ~= nil, header)
end)

test("sl: no rendered line ends in a colon", function()
  -- House style, and the reason FormatKV uses " = " rather than ": ".
  local Sl, rec = F.new()
  Sl:OnSlash("")
  Sl:OnSlash("list")
  for _, line in ipairs(rec.chat) do
    T.assertTrue(plain(line):sub(-1) ~= ":", "line ends in a colon: " .. plain(line))
  end
end)

-- ── FormatKV and FormatValue ───────────────────────────────────────────────────────────────

test("sl: FormatKV is a gold key, ' = ', a white value, and no trailing colon", function()
  assertEqual(slash.FormatKV("units.player.barWidth", "200 px"),
    "|cFFFFFF00units.player.barWidth|r = |cFFFFFFFF200 px|r")
end)

test("sl: FormatValue renders every schema type the library knows", function()
  local _, rec = F.new()
  local row = function(path) return rec.byPath[path] end
  assertEqual(slash.FormatValue(row("showOnlyInCombat"), false), "false")
  assertEqual(slash.FormatValue(row("showOnlyInCombat"), true), "true")
  assertEqual(slash.FormatValue(row("units.player.barWidth"), 200), "200 px", "row.fmt is applied")
  assertEqual(slash.FormatValue(row("labelText"), "short"), "short")
  assertEqual(slash.FormatValue(row("emptyLabel"), ""), "(none)", "an empty string reads as (none)")
  assertEqual(slash.FormatValue(row("units.player.barColor"),
    { r = 0.1, g = 0.2, b = 0.3, a = 0.4 }), "{0.10, 0.20, 0.30, 0.40}")
  assertEqual(slash.FormatValue(row("showOnlyInCombat"), nil), "nil")
end)

test("sl: a color channel the stored table omits falls back per channel, alpha to 1 and RGB to 0",
  function()
  -- The per-channel defaults used to be inline `or 0` / `or 1` literals in FormatValue and are a
  -- data table now, one positional triple per channel. Nothing else pins the numbers, and in a
  -- triple a wrong default is one digit among twelve rather than a visible edit to a named line —
  -- so an alpha that regressed to 0 would ship, and every color on the CLI would read as fully
  -- transparent while looking perfectly well-formed.
  --
  -- Alpha is the channel that matters: a three-element color is the shape the Ka0s options widget
  -- writes, so "no fourth element" is the common case, not the corner one. RGB defaulting to 0 is
  -- pinned alongside it because the two defaults sit in the same table and are edited together.
  assertEqual(slash.FormatValue({ type = "color" }, { 0.1, 0.2, 0.3 }),
    "{0.10, 0.20, 0.30, 1.00}", "a three-element positional color is opaque, not transparent")
  assertEqual(slash.FormatValue({ type = "color" }, { r = 0.1, g = 0.2, b = 0.3 }),
    "{0.10, 0.20, 0.30, 1.00}", "and so is a keyed one with no alpha")
  assertEqual(slash.FormatValue({ type = "color" }, { a = 0.4 }),
    "{0.00, 0.00, 0.00, 0.40}", "the RGB channels default to 0, each on its own")
end)

test("sl: a number row with no fmt renders bare", function()
  assertEqual(slash.FormatValue({ type = "number" }, 42), "42")
end)

test("sl: a row whose value does not fit its declared type falls through to the generic renderer",
  function()
  -- FormatValue dispatches on row.type through a table of formatters, and a formatter handed
  -- something it cannot render returns nil to fall THROUGH — which is what the old if-chain did by
  -- simply not matching. That distinction is invisible for a value of the expected shape, and these
  -- cases are what hold it: a formatter answering its own sentinel, or its own tostring, instead of
  -- declining would swallow the fall-through and nothing else here would notice.
  --
  -- Not hypothetical. A row's declared type is what the schema SAYS; the value is whatever the
  -- host's `get` actually returns, and the two disagree while a setting is mid-migration between
  -- shapes — the exact moment someone reads the value off the CLI to find out what is stored.
  assertEqual(slash.FormatValue({ type = "color" }, "not-a-table"), "not-a-table",
    "a color row holding a plain string renders the string")
  assertEqual(slash.FormatValue({ type = "color" }, 7), "7",
    "and one holding a number renders the number")
  assertEqual(slash.FormatValue({ type = "string" }, "text"), "text",
    "a non-empty string is the generic renderer's answer, not the string formatter's")
  assertEqual(slash.FormatValue({ type = "sometype" }, "text"), "text",
    "and a row type the library has never heard of reaches it too")
end)

-- A stand-in for a WoW combat "secret" value, the same shape the Core suite uses: `..` succeeds on
-- it (a real secret propagates silently) while `table.concat` refuses it, which is what the seam
-- probes. A settings value is *supposed* to be an ordinary stored scalar; these cases exist because
-- nothing enforces that, and a host whose getter returns a live or derived value must not raise.
local secretMock = setmetatable({}, {
  __concat = function() return "secret-propagated" end,
})

test("sl: FormatValue renders a secret as the sentinel on every formatting branch", function()
  local _, rec = F.new()
  local row = function(path) return rec.byPath[path] end
  assertEqual(slash.FormatValue(row("units.player.barWidth"), secretMock), T.core.SECRET,
    "the row.fmt branch guards before string.format")
  assertEqual(slash.FormatValue({ type = "number" }, secretMock), T.core.SECRET,
    "the bare-number branch guards before tostring")
  assertEqual(slash.FormatValue(row("units.player.barColor"),
    { r = secretMock, g = 0.2, b = 0.3, a = 0.4 }), T.core.SECRET,
    "the color branch guards each component before the %.2f tuple")
  assertEqual(slash.FormatValue(row("labelText"), secretMock), T.core.SECRET,
    "the string branch guards")
end)

test("sl: FormatValue reads a POSITIONAL color as well as a named-key one", function()
  -- The Ka0s options color widget writes { r, g, b, a } positionally. Rendered through the
  -- named-key reader alone, every such row read as {0.00, 0.00, 0.00, 1.00} — and shipped that
  -- way, because nothing asserts a rendered color's VALUE outside this file.
  local _, rec = F.new()
  local row = rec.byPath["units.player.barColor"]
  assertEqual(slash.FormatValue(row, { 0.1, 0.2, 0.3, 0.4 }), "{0.10, 0.20, 0.30, 0.40}",
    "byte-identical to the named-key rendering of the same color")
end)

test("sl: a positional color with a secret component still renders the sentinel", function()
  -- The guard has to cover the new indexing path too, or a combat-protected component reaches
  -- string.format by the back door.
  local _, rec = F.new()
  local row = rec.byPath["units.player.barColor"]
  assertEqual(slash.FormatValue(row, { secretMock, 0.2, 0.3, 0.4 }), T.core.SECRET)
end)

test("sl: a host color codec round-trips through set and its echo", function()
  -- The end-to-end case, parameterised by shape: parse writes what the host stores, and the echo
  -- reads it back through the same codec. A partial fix that changed only one of them renders a
  -- color the host never stored.
  local POSITIONAL = {
    colorDecode = function(c) c = type(c) == "table" and c or {}
                              return c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1 end,
    colorEncode = function(r, g, b, a) return { r, g, b, a or 1 } end,
  }
  local Sl, rec = F.new(POSITIONAL)
  rec.chat = {}
  Sl:CliSet("units.player.barColor 0.1 0.2 0.3 0.4")
  local stored = rec.store["units.player.barColor"]
  T.assertNear(stored[1], 0.1, 1e-6, "written in the host's positional shape")
  T.assertNil(stored.r, "and not in the library's named-key one")
  local text = table.concat(rec.chat, "\n")
  T.assertTrue(text:find("{0.10, 0.20, 0.30, 0.40}", 1, true) ~= nil,
    "the echo reads it back through the same codec: " .. text)
end)

test("sl: CliReset's echo uses the host color codec too", function()
  -- The second FormatValue site, and the one a partial fix misses.
  local store = {}
  local Sl, rec = F.new({
    colorDecode = function(c) c = type(c) == "table" and c or {}
                              return c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1 end,
    colorEncode = function(r, g, b, a) return { r, g, b, a or 1 } end,
    get = function(path) return store[path] end,
    set = function(path, value) store[path] = value end,
    applyDefault = function(row) store[row.path] = { 0.5, 0.6, 0.7, 0.8 } end,
  })
  rec.chat = {}
  Sl:CliReset("units.player.barColor")
  local text = table.concat(rec.chat, "\n")
  T.assertTrue(text:find("{0.50, 0.60, 0.70, 0.80}", 1, true) ~= nil, text)
end)

test("sl: a guarded FormatValue still survives the FormatKV string.format around it", function()
  local ok, out = pcall(function()
    return slash.FormatKV("units.player.barWidth",
      slash.FormatValue({ type = "number" }, secretMock))
  end)
  T.assertTrue(ok, "rendering a secret must not raise: " .. tostring(out))
  assertEqual(out, "|cFFFFFF00units.player.barWidth|r = |cFFFFFFFF" .. T.core.SECRET .. "|r")
end)

-- ── the command primitives ─────────────────────────────────────────────────────────────────

test("sl: SplitVerb lowercases the verb and preserves the remainder's case", function()
  -- The asymmetry is the contract: a verb is an identifier, the remainder is user data, and both
  -- AceDB profile names and schema paths are case-sensitive.
  local verb, rest = slash.SplitVerb("USE MyProfile")
  assertEqual(verb, "use")
  assertEqual(rest, "MyProfile")
end)

test("sl: SplitVerb keeps the remainder's internal spacing", function()
  -- A color is several tokens, so collapsing runs of spaces would change what the parser sees.
  local verb, rest = slash.SplitVerb("set  1  0.5  0 ")
  assertEqual(verb, "set")
  assertEqual(rest, "1  0.5  0 ")
end)

test("sl: SplitVerb answers two empty strings for empty and nil input", function()
  local verb, rest = slash.SplitVerb("")
  assertEqual(verb, "")
  assertEqual(rest, "")
  verb, rest = slash.SplitVerb(nil)
  assertEqual(verb, "")
  assertEqual(rest, "")
end)

test("sl: SplitVerb answers an empty remainder for a bare verb", function()
  local verb, rest = slash.SplitVerb("List")
  assertEqual(verb, "list")
  assertEqual(rest, "")
end)

test("sl: FindCommand returns the whole triple for a matching name", function()
  local handler = function() end
  local list = { { "list", "List them", function() end }, { "use", "Use one", handler } }
  local entry = slash.FindCommand(list, "use")
  T.assertTrue(entry ~= nil, "the entry was found")
  assertEqual(entry[2], "Use one")
  assertEqual(entry[3], handler)
end)

test("sl: FindCommand compares verbatim and answers nil for a miss", function()
  -- Callers lowercase through SplitVerb first; the lookup itself does not fold, so a table
  -- declaring a mixed-case verb keeps it.
  local list = { { "use", "Use one", function() end } }
  T.assertNil(slash.FindCommand(list, "USE"))
  T.assertNil(slash.FindCommand(list, "nope"))
end)

test("sl: FindCommand answers nil rather than raising on a missing list", function()
  T.assertNil(slash.FindCommand(nil, "use"))
  T.assertNil(slash.FindCommand("not a table", "use"))
end)

test("sl: CommandRows renders one row per entry through the shared formatter", function()
  local list = { { "debug", "Toggle debug" }, { "spells", "Manage spells" } }
  local rows = slash.CommandRows("/kcd", list)
  assertEqual(#rows, 2)
  assertEqual(rows[1], slash.FormatRow("/kcd debug", "Toggle debug"))
  assertEqual(rows[2], slash.FormatRow("/kcd spells", "Manage spells"))
end)

test("sl: CommandRows defaults to no indent and applies the one it is given", function()
  local list = { { "on", "Turn it on" } }
  assertEqual(slash.CommandRows("/cm bar", list)[1]:sub(1, 1), "|", "no leading indent by default")
  assertEqual(slash.CommandRows("/cm bar", list, "  ")[1],
    "  " .. slash.CommandRows("/cm bar", list)[1], "the indent is the only difference")
end)

test("sl: CommandRows answers an empty list rather than raising on a missing table", function()
  assertEqual(#slash.CommandRows("/th", nil), 0)
  assertEqual(#slash.CommandRows("/th", "not a table", "  "), 0)
end)

test("sl: HelpRows and LandingRows render through CommandRows", function()
  -- The sub level and the top level share one formatter by construction, which is the whole point
  -- of the promotion: a second hand-rolled row format is how the two drifted apart before.
  local Sl, rec = F.new()
  assertEqual(table.concat(Sl:HelpRows(), "\n"),
    table.concat(slash.CommandRows("/th", rec.commands, "  "), "\n"))
  assertEqual(table.concat(Sl:LandingRows(), "\n"),
    table.concat(slash.CommandRows("/th", rec.commands, ""), "\n"))
end)

test("sl: ParseBool accepts the same eight words the error string advertises", function()
  for _, word in ipairs({ "true", "1", "on", "yes", "TRUE", "On" }) do
    assertEqual(slash.ParseBool(word), true, word)
  end
  for _, word in ipairs({ "false", "0", "off", "no", "OFF" }) do
    assertEqual(slash.ParseBool(word), false, word)
  end
end)

test("sl: ParseBool answers nil, never false, for a non-boolean word", function()
  -- nil means "not a boolean word", which is what lets a caller implement toggle-on-absent. A
  -- false here would make `/xx bar` and `/xx bar off` indistinguishable.
  T.assertNil(slash.ParseBool("maybe"))
  T.assertNil(slash.ParseBool(""))
  T.assertNil(slash.ParseBool(nil))
  T.assertNil(slash.ParseBool(1))
  T.assertNil(slash.ParseBool({}))
end)

-- ── the parser ─────────────────────────────────────────────────────────────────────────────

test("sl: booleans accept the whole human vocabulary", function()
  local row = { type = "bool" }
  for _, word in ipairs({ "true", "1", "on", "yes", "TRUE", "On" }) do
    assertEqual(slash.ParseValue(row, word), true, word)
  end
  for _, word in ipairs({ "false", "0", "off", "no", "OFF" }) do
    assertEqual(slash.ParseValue(row, word), false, word)
  end
end)

test("sl: a junk boolean is rejected and the accepted words are listed", function()
  local v, err = slash.ParseValue({ type = "bool" }, "maybe")
  T.assertNil(v)
  T.assertTrue(err:find("true/false/on/off/1/0/yes/no", 1, true) ~= nil, err)
end)

test("sl: a number is clamped to the row's range rather than rejected", function()
  local row = { type = "number", min = 50, max = 500 }
  assertEqual(slash.ParseValue(row, "99999"), 500, "clamped to max, not refused")
  assertEqual(slash.ParseValue(row, "1"), 50, "and to min")
  assertEqual(slash.ParseValue(row, "250"), 250)
end)

test("sl: a non-numeric value for a number row is rejected", function()
  local v, err = slash.ParseValue({ type = "number" }, "wide")
  T.assertNil(v)
  T.assertTrue(err:find("expected a number", 1, true) ~= nil, err)
end)

test("sl: a string is validated against its enum, case-sensitively", function()
  local row = { type = "string", values = { none = true, short = true } }
  assertEqual(slash.ParseValue(row, "short"), "short")
  local v, err = slash.ParseValue(row, "Short")
  T.assertNil(v, "the enum match is case-sensitive")
  T.assertTrue(err:find("none, short", 1, true) ~= nil, "the allowed values are listed, sorted: " .. err)
end)

test("sl: an enum declared as an ordered array is offered in declaration order", function()
  -- The Ka0s options schema declares enums as an ordered array of { value =, text = }, because
  -- the declared order IS the dropdown's display order. Declared here so that alphabetical and
  -- declared order DISAGREE — with a list that happens to sort into its own order, the assertion
  -- passes whether or not the implementation honors the position.
  local row = { type = "string", values = {
    { value = "short", text = "Short" },
    { value = "none",  text = "None"  },
  } }
  assertEqual(slash.ParseValue(row, "short"), "short")
  local v, err = slash.ParseValue(row, "Short")
  T.assertNil(v, "the enum match is case-sensitive")
  T.assertTrue(err:find("short, none", 1, true) ~= nil,
    "the allowed values are listed in DECLARED order, not sorted: " .. err)
end)

test("sl: an ordered array supplied as a function is evaluated at parse time", function()
  local row = { type = "string", values = function()
    return { { value = "flat", text = "Flat" } }
  end }
  assertEqual(slash.ParseValue(row, "flat"), "flat")
end)

test("sl: a numeric dropdown rejects an out-of-list value rather than clamping it", function()
  -- Clamping lands BETWEEN two entries, and the renderer then has no label for what is stored:
  -- the row reads blank and the user cannot tell what they set. Constraining says so instead.
  local row = { type = "number", min = 1, max = 4,
    values = { { value = 1 }, { value = 2 }, { value = 4 } } }
  assertEqual(slash.ParseValue(row, "4"), 4)
  local v, err = slash.ParseValue(row, "3")
  T.assertNil(v, "a value inside the range but off the list is refused")
  T.assertTrue(err:find("1, 2, 4", 1, true) ~= nil, err)
  T.assertNil((slash.ParseValue(row, "99")), "and one outside it is refused, not clamped to 4")
end)

test("sl: a number row with no values list still clamps to min/max", function()
  local row = { type = "number", min = 50, max = 500 }
  assertEqual(slash.ParseValue(row, "10"), 50)
  assertEqual(slash.ParseValue(row, "9000"), 500)
end)

test("sl: a string row with no values list accepts free text", function()
  -- The EditBox row. The old reader walked an empty allowed-list and therefore refused every
  -- value, so that widget type shipped un-settable from the CLI.
  assertEqual(slash.ParseValue({ type = "string" }, "anything"), "anything")
end)

-- A STRING ROW TAKES THE WHOLE REMAINDER (minor 10). Through minor 9 it took the first token, so
-- `/am set container.name My Raid Buffs` stored "My", and an enum whose values carry a space -- an
-- LSM font, the "OUTLINE, MONOCHROME" flag -- could not be named. Found by an AuraMaster test agent;
-- PrettyChat had worked around it with a descriptor `parse`.
-- red under: parseString reading args[1], or trimming internal spacing as well as the edges.
test("sl: a free-text string row keeps every word of a multi-word value", function()
  assertEqual(slash.ParseValue({ type = "string" }, "My Raid Buffs"), "My Raid Buffs")
  assertEqual(slash.ParseValue({ type = "string" }, "a  b"), "a  b", "internal spacing is the user's")
end)

test("sl: a string enum accepts an entry that contains spaces, in both enum shapes", function()
  local map = { type = "string", values = { ["Friz Quadrata TT"] = true, Arial = true } }
  assertEqual(slash.ParseValue(map, "Friz Quadrata TT"), "Friz Quadrata TT")
  local arr = { type = "string", values = {
    { value = "OUTLINE, MONOCHROME", text = "Monochrome outline" }, { value = "OUTLINE" } } }
  assertEqual(slash.ParseValue(arr, "OUTLINE, MONOCHROME"), "OUTLINE, MONOCHROME")
  -- Matched on the FULL string: a valid entry followed by more words is refused, not truncated.
  local v, err = slash.ParseValue(map, "Arial Narrow")
  T.assertNil(v, "trailing words after a valid entry are not dropped")
  T.assertTrue(err:find("allowed values", 1, true) ~= nil, err)
end)

test("sl: a string value is trimmed at both ends before it is stored or validated", function()
  assertEqual(slash.ParseValue({ type = "string" }, "   My Raid Buffs  "), "My Raid Buffs")
  local map = { type = "string", values = { ["Friz Quadrata TT"] = true } }
  assertEqual(slash.ParseValue(map, "\tFriz Quadrata TT "), "Friz Quadrata TT")
end)

test("sl: an empty or blank string value is still refused with 'expected a value'", function()
  for _, text in ipairs({ "", "   ", false }) do
    local v, err = slash.ParseValue({ type = "string" }, text or nil)
    T.assertNil(v, "refused: '" .. tostring(text) .. "'")
    assertEqual(err, slash.STRINGS.ERR_STRING)
  end
end)

test("sl: bool, number and color rows still read tokens exactly as before", function()
  -- red under: routing every type through the whole-remainder read.
  assertEqual(slash.ParseValue({ type = "bool" }, "on and more"), true, "a bool reads its first token")
  assertEqual(slash.ParseValue({ type = "number", min = 50, max = 500 }, "250 px"), 250,
    "a number reads its first token")
  local c = slash.ParseValue({ type = "color" }, "  0.1 0.2   0.3 0.4 extra ")
  T.assertNear(c.b, 0.3, 1e-6, "a color reads its four tokens")
  T.assertNear(c.a, 0.4, 1e-6)
  local _, err = slash.ParseValue({ type = "number" }, "")
  assertEqual(err, slash.STRINGS.ERR_NUMBER)
end)

test("sl: set stores a multi-word free-text value whole, through the dispatcher", function()
  local Sl, rec = F.new()
  local row = { path = "container.name", page = "general", type = "string", default = "" }
  rec.rows[#rec.rows + 1] = row
  rec.byPath[row.path] = row
  Sl:OnSlash("set container.name   My Raid Buffs  ")
  assertEqual(rec.store["container.name"], "My Raid Buffs")
  assertEqual(plain(rec.chat[1]), "container.name = My Raid Buffs", "and the echo shows all of it")

  -- A path with no value keeps today's refusal: the row is found, the parse refuses, nothing is
  -- written.
  Sl:CliSet("container.name")
  assertEqual(rec.store["container.name"], "My Raid Buffs", "a blank value does not write")
  T.assertTrue(plain(rec.chat[2]):find("Invalid value for container.name", 1, true) ~= nil,
    plain(rec.chat[2]))
  assertEqual(plain(rec.chat[3]), "  expected a value")
end)

test("sl: a key SET labels its entries with its keys, not with 'true'", function()
  -- { SHORT = true } is a degenerate key map. Rendering the VALUE as the label is how such a row
  -- becomes a list of entries all reading "true"; the key is the only honest label it has.
  local row = { type = "string", values = { none = true, short = true } }
  local _, err = slash.ParseValue(row, "nope")
  T.assertTrue(err:find("none, short", 1, true) ~= nil, err)
end)

test("sl: an enum supplied as a function is evaluated at parse time", function()
  -- A host's media list is populated by another addon and is not knowable at load.
  local row = { type = "string", values = function() return { flat = true } end }
  assertEqual(slash.ParseValue(row, "flat"), "flat")
end)

test("sl: a color parses r g b with an optional alpha", function()
  local c = slash.ParseValue({ type = "color" }, "0.1 0.2 0.3 0.4")
  T.assertNear(c.r, 0.1, 1e-6); T.assertNear(c.a, 0.4, 1e-6)
  local d = slash.ParseValue({ type = "color" }, "0.1 0.2 0.3")
  assertEqual(d.a, 1, "alpha defaults to opaque")
end)

test("sl: a color given in 0-255 is rescaled, and all three channels together", function()
  -- Rescaling per channel would mangle a mixed input worse than rescaling jointly does; this is
  -- the existing behavior and it is preserved deliberately rather than tidied.
  local c = slash.ParseValue({ type = "color" }, "255 128 0")
  T.assertNear(c.r, 1, 1e-6); T.assertNear(c.b, 0, 1e-6)
  T.assertTrue(c.g > 0.5 and c.g < 0.51, "128/255")
end)

test("sl: a color missing a channel is rejected with the expected form", function()
  local v, err = slash.ParseValue({ type = "color" }, "1 0")
  T.assertNil(v)
  T.assertTrue(err:find("r g b", 1, true) ~= nil, err)
end)

test("sl: an unknown row type is rejected by name", function()
  local v, err = slash.ParseValue({ type = "wibble" }, "x")
  T.assertNil(v)
  T.assertTrue(err:find("wibble", 1, true) ~= nil, err)
end)

-- ── the CLI verbs ──────────────────────────────────────────────────────────────────────────

test("sl: list groups rows under the host's own group keys, indented", function()
  local Sl, rec = F.new()
  Sl:CliList()
  local out = {}
  for i, line in ipairs(rec.chat) do out[i] = plain(line) end
  assertEqual(out[1], "Available settings", "the header, with no colon")
  local joined = table.concat(out, "\n")
  T.assertTrue(joined:find("  [general]", 1, true) ~= nil, "a bare page header, indented two")
  T.assertTrue(joined:find("  [bar / player]", 1, true) ~= nil, "and a per-unit one")
  T.assertTrue(joined:find("    units.player.barWidth = 200 px", 1, true) ~= nil,
    "rows indent four, and render through FormatKV: " .. joined)
end)

test("sl: the list keeps its own colors \226\128\148 green header, azure group headings", function()
  -- Decision D3 converges the COMMAND-row formatter, and nothing else. Recasing these to match it
  -- would be a user-visible change outside what was asked for.
  local Sl, rec = F.new()
  Sl:CliList()
  assertEqual(rec.chat[1], "|cff33ff99Available settings|r")
  local sawGroup = false
  for _, line in ipairs(rec.chat) do
    if line:find("|cff3399ff[", 1, true) then sawGroup = true end
  end
  T.assertTrue(sawGroup, "group headings stay azure")
end)

test("sl: list says so when nothing is registered", function()
  local Sl, rec = F.new{ allRows = function() return {} end }
  Sl:CliList()
  assertEqual(#rec.chat, 1)
  assertEqual(plain(rec.chat[1]), "No settings registered yet")
end)

test("sl: get echoes the canonical path and the stored value", function()
  local Sl, rec = F.new()
  Sl:CliGet("units.player.barWidth")
  assertEqual(#rec.chat, 1)
  assertEqual(plain(rec.chat[1]), "units.player.barWidth = 200 px")
end)

test("sl: a stored false renders as false, not as nil", function()
  -- `x and false or nil` collapses a legitimate value. Every unticked checkbox in a host addon is a
  -- stored false, so this is most of what /at list prints.
  local Sl, rec = F.new()
  assertEqual(rec.store["showOnlyInCombat"], false, "the fixture really does store false")
  Sl:CliGet("showOnlyInCombat")
  assertEqual(plain(rec.chat[1]), "showOnlyInCombat = false")
  Sl:CliList()
  local listed = {}
  for i, line in ipairs(rec.chat) do listed[i] = plain(line) end
  T.assertTrue(table.concat(listed, "\n"):find("showOnlyInCombat = false", 1, true) ~= nil,
    "and the same in the listing")
end)

test("sl: get with no path prints usage; an unknown path says so", function()
  local Sl, rec = F.new()
  Sl:CliGet("")
  T.assertTrue(plain(rec.chat[1]):find("Usage: /th get", 1, true) ~= nil, plain(rec.chat[1]))
  Sl:CliGet("nosuchsetting")
  T.assertTrue(plain(rec.chat[2]):find("Setting not found: nosuchsetting", 1, true) ~= nil,
    plain(rec.chat[2]))
end)

test("sl: set writes through the host and echoes what was STORED, not what was typed", function()
  -- The echo re-reads, which is the only reason a clamp is visible to the user.
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barWidth 99999")
  assertEqual(rec.store["units.player.barWidth"], 500)
  assertEqual(plain(rec.chat[1]), "units.player.barWidth = 500 px")
end)

test("sl: set with no path points at the list verb", function()
  local Sl, rec = F.new()
  Sl:CliSet("")
  local line = plain(rec.chat[1])
  T.assertTrue(line:find("Usage: /th set", 1, true) ~= nil, line)
  T.assertTrue(line:find("/th list", 1, true) ~= nil, "and names where to find the paths: " .. line)
end)

test("sl: a rejected value is not written, and the reason is a second, indented line", function()
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barWidth wide")
  assertEqual(rec.store["units.player.barWidth"], 200, "a rejected parse must not write")
  T.assertTrue(plain(rec.chat[1]):find("Invalid value for units.player.barWidth", 1, true) ~= nil,
    plain(rec.chat[1]))
  assertEqual(plain(rec.chat[2]), "  expected a number", "the detail is indented under it")
end)

test("sl: set accepts a value made of several tokens", function()
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barColor 0.1 0.2 0.3 0.4")
  T.assertNear(rec.store["units.player.barColor"].r, 0.1, 1e-6)
  T.assertTrue(plain(rec.chat[1]):find("{0.10, 0.20, 0.30, 0.40}", 1, true) ~= nil,
    plain(rec.chat[1]))
end)

test("sl: reset restores one setting to its default", function()
  -- Decision D1: the library owns `reset <path>`, resetting a single setting. There is no
  -- page-shaped form, here or in any host.
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barWidth 250")
  assertEqual(rec.store["units.player.barWidth"], 250)
  Sl:CliReset("units.player.barWidth")
  assertEqual(rec.store["units.player.barWidth"], 200, "back to the row's default")
  T.assertTrue(plain(rec.chat[#rec.chat]):find("units.player.barWidth", 1, true) ~= nil,
    "and it echoes what it reset")
end)

test("sl: reset leaves every other setting alone", function()
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barWidth 250")
  Sl:CliSet("units.target.barWidth 300")
  Sl:CliReset("units.player.barWidth")
  assertEqual(rec.store["units.target.barWidth"], 300, "one path, not a page")
end)

test("sl: reset with no path prints usage; an unknown path says so", function()
  local Sl, rec = F.new()
  Sl:CliReset("")
  T.assertTrue(plain(rec.chat[1]):find("Usage: /th reset <path>", 1, true) ~= nil, plain(rec.chat[1]))
  Sl:CliReset("bar")
  T.assertTrue(plain(rec.chat[2]):find("Setting not found: bar", 1, true) ~= nil,
    "a page name is just an unknown path now: " .. plain(rec.chat[2]))
end)

test("sl: reset does not lowercase its argument", function()
  -- The inverse of the rule the page-shaped verb had. Pages were a closed lowercase set; a path is
  -- case-sensitive, so folding case here would resolve settings the user did not name.
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barWidth 250")
  Sl:CliReset("UNITS.PLAYER.BARWIDTH")
  assertEqual(rec.store["units.player.barWidth"], 250, "nothing was reset")
  -- Asserted on the ECHOED path, not just on the prefix: a lowercasing CliReset would still print
  -- "Setting not found" for this input, so a prefix match cannot tell the two apart.
  assertEqual(plain(rec.chat[#rec.chat]), "Setting not found: UNITS.PLAYER.BARWIDTH")
end)

test("sl: resetall applies every row's default", function()
  local Sl, rec = F.new()
  Sl:CliSet("units.player.barWidth 250")
  Sl:CliSet("showOnlyInCombat true")
  Sl:CliResetAll()
  assertEqual(rec.store["units.player.barWidth"], 200)
  assertEqual(rec.store["showOnlyInCombat"], false)
end)

-- ── resetall's bulk bracket (Slash minor 8) ────────────────────────────────────────────────
--
-- debug-logging-§10 (standard v2.44.0): a bulk reset through the helper is ONE flow line with a
-- row count. Three consumers route their global reset through CliResetAll, so it brackets its walk
-- with the same two optional descriptor fields the Options major reads.

--- A host whose rows, bracket and printed lines all land in one ordered trace.
local function tracedSlash(extra)
  local trace = {}
  local function push(s) trace[#trace + 1] = s end
  local rec
  local over = {
    print        = function(line) push("chat:" .. plain(line)) end,
    applyDefault = function(row) push("row:" .. row.path); rec.store[row.path] = row.default end,
    bulkBegin    = function(act, scope) push("begin:" .. act .. ":" .. tostring(scope)) end,
    bulkEnd      = function(act, scope, count, err)
      push("end:" .. act .. ":" .. tostring(scope) .. ":" .. count .. ":" .. tostring(err))
    end,
  }
  for k, v in pairs(extra or {}) do over[k] = v end
  local Sl
  Sl, rec = F.new(over)
  return Sl, rec, trace
end

test("sl: resetall brackets its walk, and acknowledges after the bracket closes", function()
  -- red under: CliResetAll not reading bulkBegin/bulkEnd (Slash minor 7).
  local Sl, rec, trace = tracedSlash()
  Sl:CliResetAll()
  local want = { "begin:reset:all" }
  for _, row in ipairs(rec.rows) do want[#want + 1] = "row:" .. row.path end
  want[#want + 1] = "end:reset:all:" .. #rec.rows .. ":nil"
  want[#want + 1] = "chat:" .. plain(Sl:Text("RESET_ALL"))
  assertEqual(table.concat(trace, ","), table.concat(want, ","))
end)

test("sl: a row that raises inside resetall still closes the bracket; the error propagates and "
  .. "nothing is acknowledged", function()
  -- red under: no pcall around the walk, so a host's mute sticks for the session.
  local Sl, rec, trace
  local n = 0
  Sl, rec, trace = tracedSlash{
    applyDefault = function(row)
      n = n + 1
      if n == 2 then error("row down", 0) end
      trace[#trace + 1] = "row:" .. row.path
    end,
  }
  local ok, err = pcall(Sl.CliResetAll, Sl)
  T.assertFalse(ok)
  assertEqual(err, "row down")
  assertEqual(table.concat(trace, ","),
    "begin:reset:all,row:" .. rec.rows[1].path .. ",end:reset:all:1:row down")
end)

test("sl: resetall with no applyDefault still brackets, and counts zero rows written", function()
  local Sl, _, trace = tracedSlash{ applyDefault = false }
  Sl:CliResetAll()
  assertEqual(trace[1], "begin:reset:all")
  assertEqual(trace[2], "end:reset:all:0:nil")
end)

test("sl: resetall hands bulkEnd an info whose profileReset is false, and the host logs "
  .. "[Set] reset all: N rows", function()
  -- The same fifth argument as the Options descriptor's. A Slash walk never resets a profile, so a
  -- host passing one pair to both majors always logs its line here (debug-logging-§10).
  -- red under: bulkEnd called without its info argument.
  local log, depth = {}, 0
  local Sl, rec
  Sl, rec = F.new{
    applyDefault = function(row)
      rec.store[row.path] = row.default
      if depth == 0 then log[#log + 1] = "[Set] " .. row.path end
    end,
    bulkBegin = function() depth = depth + 1 end,
    bulkEnd   = function(act, scope, count, _, info)
      depth = depth - 1
      if info.profileReset then return end
      log[#log + 1] = ("[Set] %s %s: %d rows"):format(act, scope, count)
    end,
  }
  Sl:CliResetAll()
  assertEqual(table.concat(log, " | "), ("[Set] reset all: %d rows"):format(#rec.rows))
  assertEqual(depth, 0)
end)

test("sl: resetall with NO bracket is minor 7's walk — an error escapes with its own stack",
  function()
  -- The compatibility half: no pcall is interposed when the host supplies neither field, so the
  -- traceback at the raise point still holds the row's frame.
  -- red under: routing the unbracketed walk through the pcall too.
  local raiseLine
  local Sl = F.new{
    applyDefault = function()
      raiseLine = debug.getinfo(1, "l").currentline; error("row down")
    end,
  }
  local ok, tb = xpcall(function() Sl:CliResetAll() end, debug.traceback)
  T.assertFalse(ok)
  T.assertTrue(select(2, tb:gsub("test_slash.lua:" .. raiseLine .. ":", "")) >= 2,
    "the stack still holds the row's frame: " .. tb)
end)

test("sl: version prints one line and nothing else", function()
  local Sl, rec = F.new()
  Sl:CliVersion()
  assertEqual(#rec.chat, 1)
  assertEqual(plain(rec.chat[1]), "v1.2.3")
end)

-- ── the row annotator ──────────────────────────────────────────────────────────────────────

test("sl: the annotator fires on list, get and set — and on nothing else", function()
  -- Three sites, and never on reset or resetall: an annotation explaining what a value means is
  -- noise attached to an acknowledgment that a value went away.
  local Sl, rec = F.new()
  Sl:SetRowAnnotator(function(row)
    return row.unit == "target" and "  (annotated)" or ""
  end)
  local function saw(fn)
    local before = #rec.chat
    fn()
    for i = before + 1, #rec.chat do
      if rec.chat[i]:find("(annotated)", 1, true) then return true end
    end
    return false
  end
  T.assertTrue(saw(function() Sl:CliGet("units.target.barWidth") end), "get")
  T.assertTrue(saw(function() Sl:CliSet("units.target.barWidth 250") end), "set")
  T.assertTrue(saw(function() Sl:CliList() end), "list")
  T.assertFalse(saw(function() Sl:CliReset("units.target.barWidth") end), "never on reset")
  T.assertFalse(saw(function() Sl:CliResetAll() end), "nor on resetall")
end)

test("sl: the annotation follows the colored pair rather than interrupting it", function()
  local Sl, rec = F.new()
  Sl:SetRowAnnotator(function() return "  (note)" end)
  Sl:CliGet("units.player.barWidth")
  local line = rec.chat[1]
  T.assertTrue(line:find("|cFFFFFFFF200 px|r  (note)", 1, true) ~= nil,
    "the gold/white pair stays intact: " .. line)
end)

test("sl: with no annotator set, nothing is appended", function()
  local Sl, rec = F.new()
  Sl:CliGet("units.player.barWidth")
  assertEqual(plain(rec.chat[1]), "units.player.barWidth = 200 px")
end)

-- ── the module ─────────────────────────────────────────────────────────────────────────────

test("sl: Slash refuses to register without Core", function()
  local Loader = dofile("tests/_kit/loader.lua")
  local buildMocks = dofile("tests/wow_mock.lua")
  local bare = buildMocks()
  Loader.load("LibKa0s/Slash.lua", nil, bare)
  T.assertNil(bare.LibStub("LibKa0s-Slash-1.0", true), "no Core, no dispatcher")
end)

-- ── the `L` trap ────────────────────────────────────────────────────────────
--
-- See tests/test_debuglog.lua for the full account. In short: a Ka0s host's
-- locale table answers EVERY key with the key itself (the standard mandates the
-- metatable fallback), so resolving an override with a plain index makes this
-- module's own STRINGS unreachable and the host prints raw keys.

local function fallbackLocale()
  return setmetatable({}, { __index = function(_, k) return k end })
end

test("sl: an L whose metatable synthesizes every key does NOT mask the module's strings", function()
  -- red under: reverting Sl:Text to `strings[key]`
  local Sl = F.new({ L = fallbackLocale() })
  assertEqual(Sl:Text("LIST_HEADER"), slash.STRINGS.LIST_HEADER,
    "a synthesized override must fall through to the module's own string")
  assertEqual(Sl:Text("NOT_FOUND"), slash.STRINGS.NOT_FOUND)
end)

test("sl: a REAL entry in an L that also has a fallback still overrides", function()
  local L = fallbackLocale()
  rawset(L, "LIST_HEADER", "Reglages disponibles")
  local Sl = F.new({ L = L })
  assertEqual(Sl:Text("LIST_HEADER"), "Reglages disponibles", "a real entry must still win")
  assertEqual(Sl:Text("NOT_FOUND"), slash.STRINGS.NOT_FOUND,
    "and its neighbors must still fall through")
end)

test("sl: a plain L table overrides exactly as before", function()
  local Sl = F.new({ L = { LIST_HEADER = "Settings!" } })
  assertEqual(Sl:Text("LIST_HEADER"), "Settings!")
  assertEqual(Sl:Text("NOT_FOUND"), slash.STRINGS.NOT_FOUND)
end)

-- ── the format hook ────────────────────────────────────────────────────────────────────────
--
-- Added at Slash minor 5, and it closes an asymmetry rather than adding a feature: `parse` has been
-- a descriptor field since -1.0, so a host has always been able to teach the CLI to READ a value
-- type this library does not know — but there was no way to teach it to WRITE one back.
--
-- Two hosts hit it. BankLedger stores a settings row as a SET of muted stores (`type = "table"`),
-- which lib.FormatValue falls through to Core's SafeToString: a table is not concat-safe, so the
-- user is told a plain settings value is "<secret>" — actively misleading rather than merely ugly.
-- prettychat needs `|` doubled to `||` so a stored pattern renders literally.

test("slash: a host can supply its own value formatter for a type the library does not know",
  function()
    local rows = { { path = "s.stores", type = "table", default = {} } }
    local store = { ["s.stores"] = { BANK = true, GUILD = true } }
    local Sl = slash:New({
      slash = "/th", commands = {},
      print = function() end,
      allRows = function() return rows end,
      findRow = function(p) for _, r in ipairs(rows) do if r.path == p then return r end end end,
      get = function(p) return store[p] end,
      format = function(_, v)
        local keys = {}
        for k, on in pairs(v) do if on then keys[#keys + 1] = k end end
        table.sort(keys)
        return "{" .. table.concat(keys, ", ") .. "}"
      end,
    })
    local lines = Sl:BuildListLines()
    assertEqual(lines[#lines], "    " .. slash.FormatKV("s.stores", "{BANK, GUILD}"),
      "the host's formatter renders the list row")
  end)

test("slash: the format hook reaches the get, set and reset echoes too", function()
  local rows = { { path = "s.x", type = "table", default = {} } }
  local store = { ["s.x"] = { A = true } }
  local out = {}
  local Sl = slash:New({
    slash = "/th", commands = {},
    print = function(line) out[#out + 1] = line end,
    allRows = function() return rows end,
    findRow = function(p) for _, r in ipairs(rows) do if r.path == p then return r end end end,
    get = function(p) return store[p] end,
    set = function(p, v) store[p] = v end,
    applyDefault = function(r) store[r.path] = {} end,
    parse = function() return { B = true } end,
    format = function(_, v)
      local keys = {}
      for k in pairs(v) do keys[#keys + 1] = k end
      table.sort(keys)
      return #keys == 0 and "(none)" or ("{" .. table.concat(keys, ", ") .. "}")
    end,
  })
  Sl:CliGet("s.x")
  assertEqual(out[#out], slash.FormatKV("s.x", "{A}"), "get")
  Sl:CliSet("s.x whatever")
  assertEqual(out[#out], slash.FormatKV("s.x", "{B}"), "set, re-read after storing")
  Sl:CliReset("s.x")
  assertEqual(out[#out], slash.FormatKV("s.x", "(none)"), "reset")
end)

test("slash: a host with no format hook renders exactly as it always did", function()
  -- The existing-consumer path. Every branch of lib.FormatValue must still be the one that answers.
  local rows = { { path = "s.n", type = "number", fmt = "%.2fx", default = 1 } }
  local Sl = slash:New({
    slash = "/th", commands = {},
    print = function() end,
    allRows = function() return rows end,
    findRow = function() return rows[1] end,
    get = function() return 1.5 end,
  })
  local lines = Sl:BuildListLines()
  assertEqual(lines[#lines], "    " .. slash.FormatKV("s.n", "1.50x"))
end)

test("slash: the format hook takes precedence over the color codec, and gets the raw stored value",
  function()
    -- A host that supplies both is telling us it owns rendering outright. Handing it the DECODED
    -- color instead of what it stored would make the two hooks disagree about their own input.
    local rows = { { path = "s.c", type = "color", default = {} } }
    local seen
    local Sl = slash:New({
      slash = "/th", commands = {},
      print = function() end,
      allRows = function() return rows end,
      findRow = function() return rows[1] end,
      get = function() return { 1, 0, 0, 1 } end,
      colorDecode = function(t) return t[1], t[2], t[3], t[4] end,
      format = function(_, v) seen = v; return "red" end,
    })
    local lines = Sl:BuildListLines()
    assertEqual(lines[#lines], "    " .. slash.FormatKV("s.c", "red"))
    assertEqual(seen[1], 1, "the hook is handed the value as STORED")
  end)

test("slash: format beats colorDecode at the get, set and reset echoes, and colorEncode still runs",
  function()
    -- red under: hoisting the colorDecode branch of formatValue above the `d.format` one.
    --
    -- The case above pins the ordering at the list echo only. This pins it at the other three, and
    -- on the write side at the same time, because the documented precedence is over `colorDecode`
    -- ALONE: a host that owns rendering has said nothing about how its color is STORED, so
    -- `colorEncode` must still turn the parser's named-key tuple into the host's shape before the
    -- echo re-reads it. Nothing ships this descriptor — the three `format` hosts and the three
    -- codec hosts are disjoint sets and no ninth consumer is coming — so this suite is the only
    -- place the ordering is executed at all.
    local rows = { { path = "s.c", type = "color", default = {} } }
    local store = { ["s.c"] = { 1, 0, 0, 1 } }
    local out = {}
    local Sl = slash:New({
      slash = "/th", commands = {},
      print = function(line) out[#out + 1] = line end,
      allRows = function() return rows end,
      findRow = function() return rows[1] end,
      get = function(p) return store[p] end,
      set = function(p, v) store[p] = v end,
      applyDefault = function(r) store[r.path] = { 0, 1, 0, 1 } end,
      colorDecode = function(c) return c[1], c[2], c[3], c[4] end,
      colorEncode = function(r, g, b, a) return { r, g, b, a or 1 } end,
      -- Hex, which lib.FormatValue has no branch for: whichever hook answered is legible from the
      -- rendered bytes alone, rather than inferred from a flag the case set for itself.
      format = function(_, v)
        return ("#%02X%02X%02X"):format((v[1] or 0) * 255, (v[2] or 0) * 255, (v[3] or 0) * 255)
      end,
    })
    Sl:CliGet("s.c")
    assertEqual(out[#out], slash.FormatKV("s.c", "#FF0000"),
      "get: the decoded {1.00, 0.00, 0.00, 1.00} tuple must not be what is printed")
    Sl:CliSet("s.c 0 0 1")
    T.assertNear(store["s.c"][3], 1, 1e-6, "colorEncode still wrote the host's positional shape")
    T.assertNil(store["s.c"].b, "and not the parser's named-key one")
    assertEqual(out[#out], slash.FormatKV("s.c", "#0000FF"), "set, re-read after storing")
    Sl:CliReset("s.c")
    assertEqual(out[#out], slash.FormatKV("s.c", "#00FF00"), "reset")
  end)

-- ── the disabled gate (minor 12) ───────────────────────────────────────────────────────────
--
-- Disabled means the addon is NOT RUNNING, and this is the slash half of saying so. What is under
-- test here is almost entirely what does NOT happen: no `unknown command`, no help index, no
-- second line, no host handler reached. A gate asserted only by "the refusal line appeared" would
-- pass just as well over a dispatcher that printed the line AND ran the verb, which is the draw
-- gate wearing a refusal.

--- A host whose enable path starts FALSE, carrying `enable` and `disable` plus one FEATURE verb
--- (`lock`) to prove the gate closes on that and only on that. `rec.enabled.value` is the stored path, and the
--- `enable` / `disable` verbs write it exactly as a schema write would — the test drives the route
--- the checkbox and the verb take rather than calling a teardown directly.
local function disabledHost(overrides)
  local enabled = { value = false }
  local o = {
    isEnabled = function() return enabled.value end,
    brandName = "Ka0s Test Host",
  }
  for k, v in pairs(overrides or {}) do o[k] = v end
  local Sl, rec = F.new(o)
  rec.enabled = enabled
  -- Pushed after New because the dispatcher reads d.commands at dispatch time, and rec.commands IS
  -- d.commands — the same table, not a copy.
  rec.commands[#rec.commands + 1] = { "enable", "Turn the addon on", function()
    enabled.value = true
    rec.chat[#rec.chat + 1] = slash.FormatKV("enabled", "true")
  end }
  rec.commands[#rec.commands + 1] = { "disable", "Turn the addon off", function()
    enabled.value = false
    rec.chat[#rec.chat + 1] = slash.FormatKV("enabled", "false")
  end }
  rec.commands[#rec.commands + 1] = { "lock", "Lock the frames", function()
    rec.chat[#rec.chat + 1] = "locked"
  end }
  return Sl, rec
end

local REFUSAL = slash.DISABLED_LINE_FORMAT:format("Ka0s Test Host", "/th enable")

test("sl: the refusal line's shape is the collection's, down to the color and the dash", function()
  local Sl = disabledHost()
  local line = Sl:DisabledLine()
  assertEqual(line, REFUSAL, "built from the exported format, not re-spelled")
  assertEqual(plain(line), "Ka0s Test Host is disabled \226\128\148 enable it with /th enable",
    "rendered with the color codes stripped")
  -- Each clause of the shape, asserted separately, because a single equality above would go red
  -- for any of them and say only "the string differs".
  assertEqual(line:find("|cFFFFFF00/th enable|r", 1, true) ~= nil, true,
    "gold FFFFFF00 on the command, carrying its leading slash")
  assertEqual(line:find(" \226\128\148 ", 1, true) ~= nil, true,
    "an em dash with a single space either side, matching the row formatter")
  assertEqual(line:sub(-1), "r", "no trailing colon and no trailing period")
  assertEqual(select(2, line:gsub("\n", "")), 0, "exactly one line")
end)

test("sl: an absent isEnabled leaves the dispatcher behaving exactly as it did at minor 11", function()
  -- The whole migration story. An un-adopted host passes no isEnabled, and nothing about its
  -- surface moves — including the two paths the gate would otherwise take over, the bare command
  -- and the unknown verb.
  local Sl, rec = F.new()
  Sl:OnSlash("")
  assertEqual(rec.chat[1], "opened", "bare /<slash> still runs config")
  rec.chat = {}
  Sl:OnSlash("nosuchverb")
  assertEqual(plain(rec.chat[1]), "unknown command 'nosuchverb'")
  assertEqual(#rec.chat > 1, true, "and the index still follows it")
end)

test("sl: isEnabled without brandName is refused at New, not rendered as 'nil is disabled'", function()
  local err = T.assertError(function()
    slash:New{ slash = "/th", commands = {}, isEnabled = function() return false end }
  end, "a gated host with no brand name must be refused")
  assertEqual(tostring(err):find("brandName", 1, true) ~= nil, true, "named in the library's words")
end)

test("sl: a FEATURE verb answers exactly one refusal line and reaches no write seam", function()
  -- red under: drop the `if isDown and not liveVerbs[cmd]` gate from OnSlash
  --
  -- `lock` is the host's own feature verb, and slash-commands-§2's SHOULD is that a disabled addon
  -- refuses one rather than acting on it: the player asked for something the addon is standing down
  -- from doing, and a silent no-op leaves them with no clue why nothing happened. One line is the
  -- whole courtesy — no partial work, no side effect, no second line, and never the help index.
  local Sl, rec = disabledHost()
  Sl:OnSlash("lock")
  assertEqual(#rec.chat, 1, "exactly one line")
  assertEqual(rec.chat[1], REFUSAL, "and THE line")
  assertEqual(rec.refreshed, 0, "and it reached no write seam")
end)

test("sl: the reserved verbs and the whole schema CLI answer NORMALLY while disabled", function()
  -- red under: narrow lib.LIVE_VERBS back to { "enable", "help", "disable" } (minor 12)
  --
  -- Restored at minor 13 under the standard's v2.57.0. None of these is a feature verb, so the
  -- refusal is never turned on them: a player must be able to READ AND REPAIR SETTINGS and to
  -- REACH THE PANEL while the addon is off, which is precisely when they are most likely to need
  -- to — and `enable` above all, or the switch only goes one way.
  local Sl, rec = disabledHost()

  Sl:OnSlash("config")
  assertEqual(rec.chat[1], "opened", "config opens the panel")

  rec.chat = {}
  Sl:OnSlash("version")
  assertEqual(plain(rec.chat[1]), "v1.2.3", "version prints")

  rec.chat = {}
  Sl:OnSlash("list")
  T.assertTrue(#rec.chat > 1, "list prints its header and its rows")

  rec.chat = {}
  Sl:OnSlash("get showOnlyInCombat")
  assertEqual(rec.chat[1], slash.FormatKV("showOnlyInCombat", "false"), "get reads the stored value")

  rec.chat = {}
  Sl:OnSlash("set showOnlyInCombat true")
  assertEqual(rec.store["showOnlyInCombat"], true, "set repairs a setting on an addon that is off")
  assertEqual(rec.chat[1], slash.FormatKV("showOnlyInCombat", "true"), "and echoes what was stored")

  rec.chat = {}
  Sl:OnSlash("reset showOnlyInCombat")
  assertEqual(rec.store["showOnlyInCombat"], false, "reset puts it back")

  for _, line in ipairs(rec.chat) do
    assertEqual(line ~= REFUSAL, true, "and not one of them printed the refusal line")
  end
end)

test("sl: the bare command opens the panel, and a TYPO gets the unknown-command line", function()
  -- red under: refuse the bare-command branch while disabled (what minor 12 did), or put the gate
  -- back BEFORE findCommand, which answered a misspelling with "the addon is disabled".
  --
  -- The panel is the one surface from which a disabled addon gets switched back on by hand, and
  -- the settings registration and the panel body are SETUP rather than features (slash-commands-§7).
  --
  -- THE TYPO IS THE OPPOSITE CASE FROM A REFUSED VERB, and the gate's position is what tells them
  -- apart. A feature verb this addon ships gets the one refusal line, because the addon understood
  -- and is off. A word it does not ship gets slash-commands-§3's `unknown command '<verb>'` and the
  -- index, because the addon did not understand and §3 does not carve the disabled state out of
  -- that MUST. Answering a typo with "the addon is disabled" tells a player who mistyped that their
  -- spelling was fine.
  local Sl, rec = disabledHost()
  Sl:OnSlash("")
  assertEqual(#rec.chat, 1); assertEqual(rec.chat[1], "opened", "the host's config verb ran")
  rec.chat = {}
  Sl:OnSlash("nosuchverb")
  assertEqual(#rec.chat > 1, true, "a typo gets the unknown-command line AND the index, not one line")
  assertEqual(plain(rec.chat[1]):find("unknown command", 1, true) ~= nil, true,
    "the first line names the word that was not understood")
  -- NOT asserted: that the refusal line is absent from the burst. `help` carries it under its
  -- header as a STATUS note -- the addon really is off -- and the index is what a typo prints.
  -- What matters is that the FIRST line named the word, so the player is told they mistyped
  -- rather than told their spelling was fine.
end)

test("sl: an alias onto a gated verb is refused, and an alias onto a live one is honored", function()
  -- Aliases resolve BEFORE the gate. Gating the raw word would refuse `/th hold` and honor
  -- `/th lock`, which is one surface answering two ways.
  local Sl, rec = disabledHost({ aliases = { hold = "lock", on = "enable" } })
  Sl:OnSlash("hold")
  assertEqual(rec.chat[1], REFUSAL, "an alias onto a feature verb is still that feature verb")
  rec.chat = {}
  Sl:OnSlash("on")
  assertEqual(rec.chat[1], slash.FormatKV("enabled", "true"), "an alias onto enable still enables")
end)

test("sl: enable answers normally and is the way back", function()
  local Sl, rec = disabledHost()
  Sl:OnSlash("enable")
  assertEqual(#rec.chat, 1)
  assertEqual(rec.chat[1], slash.FormatKV("enabled", "true"), "the set-shaped echo, not a refusal")
  rec.chat = {}
  -- And the gate is asked at dispatch time, never cached: the very next command works.
  Sl:OnSlash("lock")
  assertEqual(rec.chat[1], "locked")
end)

test("sl: disable ECHOES the write rather than refusing, and is idempotent", function()
  -- Refusing it would answer `/th disable` with a line telling the player to type `/th enable`,
  -- which reads as the addon having misunderstood the request. It is not a feature verb; it is an
  -- alias onto a schema write, so writing false over false is an idempotent no-op write whose
  -- honest answer is the echo every other write gets.
  local Sl, rec = disabledHost()
  Sl:OnSlash("disable")
  assertEqual(#rec.chat, 1)
  assertEqual(rec.chat[1], slash.FormatKV("enabled", "false"))
  assertEqual(rec.enabled.value, false)
end)

test("sl: help prints the full index with the refusal line under its header, unindented", function()
  -- red under: move the refusal emit below the rows in PrintHelp
  --
  -- `help` is not refused: the index prints in full, because the player has to be able to SEE
  -- `enable` in the list. The line under the header is a statement about the whole index — some of
  -- the rows below it are the host's feature verbs, which are the one thing still refused — and
  -- below the rows it would be a footnote to the last one.
  local Sl, rec = disabledHost()
  Sl:OnSlash("help")
  assertEqual(rec.chat[1], Sl:HelpHeader(), "the header first")
  assertEqual(rec.chat[2], REFUSAL, "then the refusal, immediately")
  assertEqual(rec.chat[2]:sub(1, 1) ~= " ", true, "unindented, unlike every row below it")
  assertEqual(#rec.chat, #Sl:HelpRows() + 2, "and every row still printed")
  local sawEnable = false
  for _, line in ipairs(rec.chat) do
    if plain(line):find("/th enable ", 1, true) then sawEnable = true end
  end
  assertEqual(sawEnable, true, "`enable` is visible in the index, which is why help answers at all")
end)

test("sl: help enabled prints no refusal line at all", function()
  local Sl, rec = disabledHost()
  rec.enabled.value = true
  Sl:OnSlash("help")
  assertEqual(rec.chat[1], Sl:HelpHeader())
  assertEqual(rec.chat[2], Sl:HelpRows()[1], "the first row follows the header directly")
end)

test("sl: liveVerbs defaults to the standard's twelve reserved verbs and is overridable as DATA", function()
  assertEqual(table.concat(slash.LIVE_VERBS, ","),
    "help,config,version,enable,disable,debug,perf,get,set,list,reset,resetall",
    "the library ships one default and a host reads THIS rather than copying it")
  -- Narrowed rather than widened, which is the direction a host most often needs: an addon that
  -- registers no `perf` verb names the ones it has.
  local Sl, rec = disabledHost({ liveVerbs = { "enable", "help" } })
  Sl:OnSlash("disable")
  assertEqual(rec.chat[1], REFUSAL, "a verb outside the declared set is gated like any other")
end)

test("sl: a reserved verb the host never shipped is not refused, in either state", function()
  -- A verb is reserved always but REGISTERED WHEN WIRED, so an addon with a no-combat-path
  -- exemption ships no `perf` and `perf` is simply not one of its commands. Minor 13 answered it
  -- with the refusal line while disabled and with `unknown command` while enabled, which made the
  -- disabled state look like it had swallowed a command the addon never had -- five of the eleven
  -- consumers reported exactly that for `/<slash> perf` within a day of adopting it.
  -- Nothing was refused, so nothing says it was.
  --
  -- The LINE COUNT is deliberately not asserted equal: `help` prints its status line under the
  -- index while disabled, so the burst is one longer. What must match is the ANSWER.
  -- Driven with `perf` SPECIFICALLY, and that matters: the bug only reaches a verb that is in
  -- LIVE_VERBS yet absent from COMMANDS. A made-up word misses liveVerbs entirely and would
  -- pass against the broken branch, which is how a first draft of this case proved nothing.
  -- red under: restoring `if isDown and liveVerbs[cmd] then return emit(self:DisabledLine()) end`
  -- ahead of the unknown-command path.
  local SlDown, recDown = F.new({ isEnabled = function() return false end, brandName = "Ka0s Test Host" })
  SlDown:OnSlash("perf")
  assertEqual(plain(recDown.chat[1]):find("unknown command", 1, true) ~= nil, true,
    "disabled: an unshipped verb is not a command here, so it gets the unknown-command line")
  assertEqual(recDown.chat[1] == REFUSAL, false, "nothing was refused, so nothing says it was")

  local SlUp, recUp = F.new()
  SlUp:OnSlash("perf")
  assertEqual(plain(recUp.chat[1]):find("unknown command", 1, true) ~= nil, true,
    "enabled: the same answer, which is the whole point")
end)

test("sl: the gate is asked per dispatch, so a value that changes mid-session is honored", function()
  -- A feature verb, because the reserved ones answer in either state and would pin nothing here.
  local Sl, rec = disabledHost()
  rec.enabled.value = true
  Sl:OnSlash("lock")
  assertEqual(rec.chat[1], "locked", "enabled: the feature verb acts")
  rec.enabled.value = false
  rec.chat = {}
  Sl:OnSlash("lock")
  assertEqual(rec.chat[1], REFUSAL, "disabled: the same verb, the one line")
end)

test("sl: the refusal wording is NOT reachable through the locale override", function()
  -- The wording is the collection's rather than the addon's. A locale table is the obvious place
  -- for eleven addons to each grow their own version of it, so it does not resolve through Text().
  local Sl = disabledHost({ L = { DISABLED_LINE_FORMAT = "%s is off, use %s" } })
  assertEqual(Sl:DisabledLine(), REFUSAL)
end)
