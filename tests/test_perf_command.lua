-- tests/test_perf_command.lua — the command surface the host wires into its own slash table.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse
local Fixture = dofile("tests/fixture.lua")

local function joined(lines) return table.concat(lines or {}, "\n") end

test("cmd: OnCommand always returns a line table, never nil", function()
  local p = Fixture.new()
  assertTrue(type(p.OnCommand("")) == "table", "bare")
  assertTrue(type(p.OnCommand("start")) == "table", "start")
  assertTrue(type(p.OnCommand("nonsense")) == "table", "unknown")
end)

test("cmd: start begins a run and shows the panel", function()
  local p = Fixture.new()
  p.OnCommand("start")
  assertTrue(p.run, "run began")
  assertTrue(p.IsPanelShown(), "the panel is the entry point, so start opens it")
end)

test("cmd: a label is appended to the timestamp, never replaces it", function()
  local p = Fixture.new()
  p.OnCommand("start solo dummy")
  assertTrue(p.label:find("solo dummy", 1, true) ~= nil, "label present")
  assertTrue(#p.label > #"solo dummy", "stamped as well")
end)

test("cmd: measure reports which window armed and whether the host is suspended", function()
  local p = Fixture.new()
  p.OnCommand("start")
  local out = joined(p.OnCommand("measure b"))
  assertTrue(out:find("B", 1, true) ~= nil, "names the window as the user typed it")
  assertTrue(out:upper():find("SUSPENDED", 1, true) ~= nil, "says the host is suspended")
end)

test("cmd: measure outside a run tells you to start one", function()
  local p = Fixture.new()
  assertTrue(joined(p.OnCommand("measure a")):find("start", 1, true) ~= nil, "points at start")
end)

test("cmd: measure rejects an unknown window token", function()
  local p = Fixture.new()
  p.OnCommand("start")
  assertTrue(joined(p.OnCommand("measure z")):find("unknown", 1, true) ~= nil, "rejected")
end)

test("cmd: finish resumes the host before it saves", function()
  local p, rec = Fixture.new()
  p.OnCommand("start")
  p.OnCommand("measure b")
  p.OnCommand("finish")
  assertFalse(p.suspended, "an error in Save must never strand the host inert")
  assertEqual(rec.calls[#rec.calls], "resume", "resume came from the host")
  assertEqual(#_G.TestHostPerfDB.runs, 1, "and the record was saved")
end)

test("cmd: finish prints no report", function()
  local p, rec = Fixture.new()
  p.OnCommand("start")
  p.OnCommand("finish")
  assertTrue(joined(rec.log):find("bucket", 1, true) == nil,
    "finish fires as a fight ends, when a dozen unread lines is the wrong gift")
end)

test("cmd: report writes the summary to the log sink and opens it", function()
  local opened = false
  local p, rec = Fixture.new({ showLog = function() opened = true end })
  p.OnCommand("start")
  p.OnCommand("finish")
  p.OnCommand("report")
  assertTrue(joined(rec.log):find("capture:", 1, true) ~= nil, "the report went to the log")
  assertTrue(opened, "and the host was asked to show it")
  assertEqual(p.Progress().report, "used", "and the step is marked without being disabled")
end)

test("cmd: report writes the summary AND the JSON, in that order", function()
  -- `dump` was its own verb and its own panel step until 2026-09-09. Both artifacts go to the same
  -- place, both describe the same finished run, and the perf-analysis workflow wants BOTH -- so
  -- asking for them separately was a second click and a second thing to remember, and a run
  -- reported without its dump was the easy mistake to make.
  --
  -- Order matters: the summary is what a person reads and the JSON is what they copy, so the human
  -- half goes first and the machine half is the last line, where a copy-paste starts.
  -- red under: a report that prints only the summary.
  local p, rec = Fixture.new()
  p.OnCommand("start")
  p.OnCommand("finish")
  p.OnCommand("report")

  local last = rec.log[#rec.log]
  assertEqual(last:sub(1, 1), "{", "the JSON is not the last line of a report")
  assertTrue(last:find('"addon":"TestHost"', 1, true) ~= nil, "self-identifying")
  assertTrue(#rec.log > 1, "the summary went missing with the fold")
  assertEqual(p.Progress().report, "used", "marked")
end)

test("cmd: dump is no longer a verb of its own", function()
  -- Folded, not aliased: an alias would be the duplication the fold exists to remove, and the
  -- unknown-verb path already prints the usage -- where `report` now says it renders the JSON too.
  -- That is a better answer to someone with the old command in their fingers than a silent synonym.
  -- red under: keeping SUBS.dump, or re-pointing it at report.
  local p = Fixture.new()
  local out = joined(p.OnCommand("dump"))
  assertTrue(out:find("usage:", 1, true) ~= nil,
    "an unknown verb must fall through to the usage block; got: " .. out)
  assertTrue(p.Progress().dump == nil, "Progress still carries a dump step")
end)

test("cmd: cancel refuses when there is nothing to cancel", function()
  local p = Fixture.new()
  assertTrue(joined(p.OnCommand("cancel")):find("no perf run", 1, true) ~= nil, "said so")
end)

test("cmd: show, hide and toggle drive the panel and nothing else", function()
  local p = Fixture.new()
  p.OnCommand("start")
  p.OnCommand("hide")
  assertFalse(p.IsPanelShown(), "hidden")
  assertTrue(p.run, "hiding a panel is not abandoning a capture")
  p.OnCommand("toggle")
  assertTrue(p.IsPanelShown(), "back")
end)

test("cmd: a bare command reports the phase and prints the usage", function()
  local p = Fixture.new()
  local out = joined(p.OnCommand(""))
  assertTrue(out:find("stopped", 1, true) ~= nil, "phase")
  assertTrue(out:find("/th perf", 1, true) ~= nil, "usage carries the host's own slash token")
  assertTrue(p.IsPanelShown(), "bare IS the entry point")
end)

test("cmd: usage never hard-codes a slash prefix", function()
  local p = Fixture.new({ slash = "/kick" })
  assertTrue(joined(p.Usage()):find("/kick perf", 1, true) ~= nil, "host's prefix")
  assertTrue(joined(p.Usage()):find("/th", 1, true) == nil, "and only the host's")
end)

test("cmd: usage never leaves a bare pipe where the client reads an escape", function()
  -- Reported from the game, three addons at once:
  --
  --   usage: /at perf <start|measure|finish|canceleport|dump|showideoggle>
  --
  -- `cancel|report` and `show|hide|toggle` are pipe-separated alternatives, and the client reads
  -- `|r` as a color RESET, `|h` as a hyperlink and `|t` as the end of a texture. It ate all three
  -- and the words fused. The eaten `|r` also swallowed the reset that ends the gold run, which is
  -- why the whole line stayed yellow in the report.
  --
  -- `||` is the escape for a literal pipe. Checked over EVERY line rather than the one that broke:
  -- the failure needs a pipe and one particular next letter, so any future line is one word away
  -- from it and nothing else in the harness would notice.
  -- red under: any bare `|` followed by an escape letter.
  local p = Fixture.new()
  for _, line in ipairs(p.Usage()) do
    -- Strip the legitimate escapes first: a color open, a reset, and a doubled literal pipe.
    local rest = line:gsub("||", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local stray = rest:match("|(.)")
    assertTrue(stray == nil,
      ("a bare pipe before %q survives into chat and the client eats it: %s")
        :format(tostring(stray), line))
  end
end)

test("cmd: usage rows use the library's own row formatter", function()
  -- The perf block hand-aligned its second column with leading spaces and wrapped each description
  -- onto a continuation line. Chat is a PROPORTIONAL font and wraps on its own, so the columns did
  -- not line up and the continuations read as orphaned fragments -- reported beside a screenshot of
  -- the slash-command help, which looks right because it goes through lib.FormatRow.
  --
  -- One formatter, not two conventions for the same thing.
  -- red under: hand-built rows, or a continuation line that starts with spaces.
  local p = Fixture.new()
  local rows = p.Usage()
  for i = 2, #rows do
    local line = rows[i]
    assertTrue(line:find("\226\128\148", 1, true) ~= nil,
      ("row %d carries no em dash, so it is not a FormatRow: %s"):format(i, line))
    assertTrue(line:match("^%s*|cFFFFFF00") ~= nil,
      ("row %d does not open on a gold verb: %s"):format(i, line))
  end
end)

test("cmd: clicking a ready panel row takes the same path as typing it", function()
  local p = Fixture.new()
  p.ShowPanel()
  p.__panel().buttons.start:__fire("OnClick")
  assertTrue(p.run, "the click started the run")
end)

test("cmd: a panel click prints exactly what typing the command prints", function()
  -- The panel and the typed command must be ONE path. OnCommand returns its chat lines rather than
  -- printing them, so the click wiring has to print them itself; discarding them made clicking
  -- through a run produce a fraction of the output typing it did — the "ARMED" acknowledgement
  -- above all, which is the line telling the user the window is live.
  local typedP, typedRec = Fixture.new()
  local clickP, clickRec = Fixture.new()

  -- Typed: the host's slash layer prints whatever OnCommand hands back.
  local function typed(p, rec, cmd)
    for _, line in ipairs(p.OnCommand(cmd)) do rec.chat[#rec.chat + 1] = line end
  end
  typed(typedP, typedRec, "start")
  typed(typedP, typedRec, "measure a")
  typed(typedP, typedRec, "cancel")

  clickP.ShowPanel()
  local f = clickP.__panel()
  f.buttons.start:__fire("OnClick")
  f.buttons.measureA:__fire("OnClick")
  f.buttons.cancel:__fire("OnClick")

  assertEqual(#clickRec.chat, #typedRec.chat,
    "clicking produced " .. #clickRec.chat .. " chat lines, typing produced " .. #typedRec.chat)
  for i, line in ipairs(typedRec.chat) do
    assertEqual(clickRec.chat[i], line, "chat line " .. i)
  end
  assertTrue(table.concat(clickRec.chat, "\n"):find("ARMED", 1, true) ~= nil,
    "including the acknowledgement that the window is armed")
  clickP.HidePanel()
end)

test("cmd: clicking a locked panel row does nothing", function()
  local p = Fixture.new()
  p.ShowPanel()
  p.__panel().buttons.finish:__fire("OnClick")
  assertFalse(p.run, "a step that runs out of order corrupts the run it was meant to protect")
end)
