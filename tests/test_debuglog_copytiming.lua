-- tests/test_debuglog_copytiming.lua — LibKa0s-DebugLog-1.0 minor 14: the copy-timing flag and the
-- published buffer slack.
--
-- ── WHY A SUITE OF ITS OWN ────────────────────────────────────────────────────────────────────
--
-- `layout-§1`. tests/test_debuglog.lua was 988 lines when these cases were written, twelve from
-- the 1000-line band `CLAUDE.md` keeps on notice.
--
-- ── WHAT THESE CASES PIN ──────────────────────────────────────────────────────────────────────
--
-- lib.TIME_COPY is a measuring aid for the buffer-size decision: with it on, ShowCopy prints one
-- line naming what the concat, the open and the next frame cost. Every clock here is scripted, so
-- each figure in the printed line is exact rather than "some positive number".
--
-- lib.BUFFER_SLACK is the compaction slack that was a local (64) through minor 13. Published so a
-- suite reads it back rather than hard-coding it, and read by Add at call time.

local T = _G.LK_TEST
local debuglog, mocks = T.debuglog, T.mocks
local test, assertEqual = T.test, T.assertEqual

local function newLog()
  local rec = { chat = {}, enabled = false }
  local D = debuglog:New({
    name       = "TimingHost",
    title      = "Timing Host",
    font       = "Interface\\Fonts\\FRIZQT__.TTF",
    isEnabled  = function() return rec.enabled end,
    setEnabled = function(v) rec.enabled = v end,
    print      = function(line) rec.chat[#rec.chat + 1] = line end,
  })
  return D, rec
end

--- Installs nil for a key in `with`: "this client does not have that API".
local ABSENT = setmetatable({}, { __tostring = function() return "ABSENT" end })

--- Run `fn` with each key of `fixture` installed in the mock environment (ABSENT removes it) and
--- lib.TIME_COPY set as asked, then restore everything and re-raise. A removed key is also cleared
--- from the real global table for the duration, because the loader falls back there.
local function with(timeCopy, fixture, fn)
  local saved, savedG, savedFlag = {}, {}, debuglog.TIME_COPY
  for key, value in pairs(fixture) do
    saved[key], savedG[key] = mocks[key], rawget(_G, key)
    if rawequal(value, ABSENT) then
      mocks[key] = nil
      rawset(_G, key, nil)
    else
      mocks[key] = value
    end
  end
  debuglog.TIME_COPY = timeCopy
  local ok, err = pcall(fn)
  debuglog.TIME_COPY = savedFlag
  for key in pairs(fixture) do
    mocks[key] = saved[key]
    rawset(_G, key, savedG[key])
  end
  if not ok then error(err, 0) end
end

--- A clock that answers the given readings in order and counts how often it was read.
local function scriptedClock(readings)
  local clock = { reads = 0 }
  clock.fn = function()
    clock.reads = clock.reads + 1
    return readings[clock.reads] or readings[#readings]
  end
  return clock
end

--- A C_Timer whose After records the callback instead of scheduling it, so a case decides when
--- "the next frame" happens.
local function recordingTimer()
  local timer = { queued = {} }
  timer.api = { After = function(delay, fn) timer.queued[#timer.queued + 1] = { delay = delay, fn = fn } end }
  return timer
end

local function fill(D, n)
  for i = 1, n do D:Add("N", "L" .. i .. ".") end
end

-- ── lib.TIME_COPY ──────────────────────────────────────────────────────────────────────────

test("dbgtime: TIME_COPY is off at load, and the timing line's text is published in STRINGS", function()
  -- Pinned as literals: every other case sets the flag itself and would pass whatever the default.
  assertEqual(debuglog.TIME_COPY, false, "off unless someone turns it on by hand")
  assertEqual(debuglog.STRINGS.COPY_TIMING,
    "copy timing: %d lines, %d bytes, concat %.1fms, open+highlight %.1fms, next frame %.1fms")
end)

test("dbgtime: with TIME_COPY off, ShowCopy reads no clock, queues nothing and prints nothing", function()
  local clock, timer = scriptedClock({ 0 }), recordingTimer()
  with(false, { debugprofilestop = clock.fn, C_Timer = timer.api }, function()
    local D, rec = newLog()
    fill(D, 3)
    D:ShowCopy()
    assertEqual(clock.reads, 0, "the untimed path costs no clock read")
    assertEqual(#timer.queued, 0, "and schedules nothing")
    assertEqual(#rec.chat, 0, "and says nothing")
    T.assertTrue(D._copyWindowForTest ~= nil, "the window still opened")
  end)
end)

test("dbgtime: with TIME_COPY on, the next frame prints one exact timing line through emit", function()
  -- Readings: before the concat, after it, after the open, then on the next frame.
  local clock, timer = scriptedClock({ 100, 102.5, 110, 125 }), recordingTimer()
  with(true, { debugprofilestop = clock.fn, C_Timer = timer.api }, function()
    local D, rec = newLog()
    fill(D, 3)
    local expectedBytes = #D:CopyText()
    D:ShowCopy()
    assertEqual(#rec.chat, 0, "nothing prints before the next frame")
    assertEqual(#timer.queued, 1, "one callback, for the next frame")
    assertEqual(timer.queued[1].delay, 0, "and it is the next frame, not a later one")
    timer.queued[1].fn()
    assertEqual(#rec.chat, 1, "one line per ShowCopy")
    assertEqual(rec.chat[1], ("copy timing: 3 lines, %d bytes, concat 2.5ms, "
      .. "open+highlight 7.5ms, next frame 15.0ms"):format(expectedBytes))
  end)
end)

test("dbgtime: the timing line never lands in the buffer it measures", function()
  -- Through emit, never Add: a measurement that grew the buffer would change the next reading.
  local clock, timer = scriptedClock({ 0, 1, 2, 3 }), recordingTimer()
  with(true, { debugprofilestop = clock.fn, C_Timer = timer.api }, function()
    local D = newLog()
    fill(D, 3)
    D:ShowCopy()
    timer.queued[1].fn()
    assertEqual(#D.buffer, 3, "the buffer holds the three lines it held before the copy")
    T.assertNil(D:FindLine("copy timing"), "and no timing line")
  end)
end)

test("dbgtime: the timed open hands the window exactly CopyText, as the untimed one does", function()
  local clock, timer = scriptedClock({ 0, 1, 2, 3 }), recordingTimer()
  with(true, { debugprofilestop = clock.fn, C_Timer = timer.api }, function()
    local D = newLog()
    D:Add("A", "first line"); D:Add("B", "second line")
    D:ShowCopy()
    local got
    rawset(D._copyFrameForTest.edit, "SetText", function(_, t) got = t end)
    D:ShowCopy()
    rawset(D._copyFrameForTest.edit, "SetText", nil)
    assertEqual(got, D:CopyText(), "the timed path copies the same text")
  end)
end)

test("dbgtime: the line counts the kept lines, not the raw array past the cap", function()
  local clock, timer = scriptedClock({ 0, 1, 2, 3 }), recordingTimer()
  with(true, { debugprofilestop = clock.fn, C_Timer = timer.api }, function()
    local D, rec = newLog()
    fill(D, debuglog.MAX_BUFFER + 10)
    T.assertTrue(#D.buffer > debuglog.MAX_BUFFER, "precondition: the raw array is in the slack")
    D:ShowCopy()
    timer.queued[1].fn()
    T.assertTrue(rec.chat[1]:find("copy timing: " .. debuglog.MAX_BUFFER .. " lines,", 1, true) ~= nil,
      "the count is the kept lines: " .. tostring(rec.chat[1]))
  end)
end)

for _, missing in ipairs({ "debugprofilestop", "C_Timer" }) do
  test("dbgtime: with no " .. missing .. ", TIME_COPY opens the window untimed and prints nothing", function()
    -- The headless guard. The flag is a measuring aid; a client without the clock keeps its copy
    -- window.
    local clock, timer = scriptedClock({ 0 }), recordingTimer()
    local fixture = { debugprofilestop = clock.fn, C_Timer = timer.api }
    fixture[missing] = ABSENT
    with(true, fixture, function()
      local D, rec = newLog()
      fill(D, 3)
      local ok, err = pcall(function() D:ShowCopy() end)
      T.assertTrue(ok, "ShowCopy must not raise: " .. tostring(err))
      T.assertTrue(D._copyWindowForTest ~= nil, "the window opened")
      assertEqual(#timer.queued, 0, "nothing was scheduled")
      assertEqual(#rec.chat, 0, "and nothing printed")
    end)
  end)
end

-- ── lib.BUFFER_SLACK ───────────────────────────────────────────────────────────────────────

test("dbgtime: BUFFER_SLACK is published, and is 128 at minor 14", function()
  -- Pinned as a literal once, here; the compaction cases read it back. 128 moves with the
  -- 3000-line buffer: about 23 moves per line, as 64 was at 1500.
  assertEqual(debuglog.BUFFER_SLACK, 128)
end)

test("dbgtime: Add reads BUFFER_SLACK at call time, like MAX_BUFFER", function()
  -- Proves the constant is the live one rather than a published copy of a local: shrink it and the
  -- raw array peaks at the new slack.
  local saved = debuglog.BUFFER_SLACK
  debuglog.BUFFER_SLACK = 4
  local ok, err = pcall(function()
    local D = newLog()
    local cap, peak = debuglog.MAX_BUFFER, 0
    for i = 1, cap + 10 do
      D:Add("N", "L" .. i .. ".")
      if #D.buffer > peak then peak = #D.buffer end
    end
    assertEqual(peak, cap + 4, "the raw array stops at the slack Add read")
    assertEqual(D:BufferSize(), cap, "and every reader still answers MAX_BUFFER")
  end)
  debuglog.BUFFER_SLACK = saved
  if not ok then error(err, 0) end
end)
