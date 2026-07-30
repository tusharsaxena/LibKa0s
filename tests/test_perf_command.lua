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

test("cmd: dump writes one line of JSON to the log sink", function()
  local p, rec = Fixture.new()
  p.OnCommand("start")
  p.OnCommand("finish")
  p.OnCommand("dump")
  local last = rec.log[#rec.log]
  assertEqual(last:sub(1, 1), "{", "one JSON object")
  assertTrue(last:find('"addon":"TestHost"', 1, true) ~= nil, "self-identifying")
  assertEqual(p.Progress().dump, "used", "marked")
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
