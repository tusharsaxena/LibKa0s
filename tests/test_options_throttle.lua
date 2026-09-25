-- tests/test_options_throttle.lua — OptionsWidgets minor 31: the slider's live commit and the color
-- picker's drag throttle keep their own armed flag rather than reading one off the host's timer.
--
-- THE BUG (KICKCD-R-19). Both throttles did `timer = d.scheduleTimer(...)` and then
-- `if timer then return end` on the next drag frame, so the host's RETURN VALUE was the armed flag.
-- The descriptor never asked for a return value, and three hosts (KickCD, LootHistory, MultiMeters)
-- hand in a `C_Timer.After` wrapper, which answers nil. For them every drag frame armed a fresh
-- timer and a fresh closure: one commit per frame plus the garbage, with the 50 ms throttle
-- defeated in silence.
--
-- WHY A SUITE OF ITS OWN. `tests/test_options_widgets.lua` is a row in CLAUDE.md's census of files
-- over layout-§1's 1500-line cap, and a new case there grows a breach.
--
-- Each host below owns its own timer queue, so what is counted is exactly what the throttle asked
-- the host for, and `set` counts every write that reached the host.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local Fixture = dofile("tests/fixture_options.lua")

--- A host whose scheduleTimer queues `fn` and answers `answer(n)` (n = the queue length), plus a
--- `set` that counts writes. Returns the instance, the fixture record, a ctx, and the probe.
local panelSeq = 0
local function host(answer, extra)
  local probe = { timers = {}, writes = 0, store = {} }
  local overrides = {
    scheduleTimer = function(fn, _delay)
      probe.timers[#probe.timers + 1] = fn
      return answer(#probe.timers)
    end,
    set = function(path, value)
      probe.writes = probe.writes + 1
      probe.store[path] = value
    end,
  }
  for k, v in pairs(extra or {}) do overrides[k] = v end
  local O, rec = Fixture.new(overrides)
  panelSeq = panelSeq + 1
  local ctx = O.CreatePanel("ThrottleBench" .. panelSeq, "Throttle " .. panelSeq, {})
  function probe.fire()
    local queued = probe.timers
    probe.timers = {}
    for _, fn in ipairs(queued) do fn() end
  end
  return O, rec, ctx, probe
end

local function returnsNil() return nil end
local function returnsHandle(n) return { id = n } end

--- Ten drag frames on a live-commit slider inside one throttle window, then the window closes.
local function dragSlider(answer)
  local O, rec, ctx, probe = host(answer, { sliderCommit = "change" })
  local s = O.RenderField(ctx, rec.byPath.barWidth, O.AceGUI:Create("SimpleGroup"), 0.5)
  probe.writes = 0
  for i = 1, 10 do s:__fire("OnValueChanged", 200 + i) end
  local armed = #probe.timers
  local before = probe.writes
  probe.fire()
  return armed, before, probe
end

--- Ten drag frames on a color picker inside one throttle window, then the window closes.
local function dragColor(answer)
  local O, rec, ctx, probe = host(answer)
  local cp = O.RenderField(ctx, rec.byPath.barColor, O.AceGUI:Create("SimpleGroup"), 0.5)
  probe.writes = 0
  for i = 1, 10 do cp:__fire("OnValueChanged", i / 10, 0.5, 0.5, 1) end
  local armed = #probe.timers
  local before = probe.writes
  probe.fire()
  return armed, before, probe
end

test("throttle: a nil-returning scheduleTimer still gets ONE slider timer per window", function()
  local armed, before, probe = dragSlider(returnsNil)
  -- red under: `if dragTimer then return end` with dragTimer = the host's nil (ten timers)
  assertEqual(armed, 1, "ten drag frames arm one timer, whatever the host's timer answers")
  assertEqual(before, 0, "and nothing is written until it fires")
  assertEqual(probe.writes, 1, "the window commits once")
  assertEqual(probe.store.barWidth, 210, "with the last value")
end)

test("throttle: a nil-returning scheduleTimer still gets ONE color timer per window", function()
  local armed, before, probe = dragColor(returnsNil)
  -- red under: `if timer then return end` with timer = the host's nil (ten timers)
  assertEqual(armed, 1, "ten drag frames arm one timer, whatever the host's timer answers")
  assertEqual(before, 0, "and nothing is written until it fires")
  assertEqual(probe.writes, 1, "the window commits once")
  assertTrue(probe.store.barColor ~= nil, "with the last color")
end)

test("throttle: the window re-arms after it fires, for a nil-returning host", function()
  local O, rec, ctx, probe = host(returnsNil, { sliderCommit = "change" })
  local s = O.RenderField(ctx, rec.byPath.barWidth, O.AceGUI:Create("SimpleGroup"), 0.5)
  s:__fire("OnValueChanged", 205)
  probe.fire()
  s:__fire("OnValueChanged", 230)
  s:__fire("OnValueChanged", 231)
  assertEqual(#probe.timers, 1, "the flag was cleared inside the callback, so the next drag re-arms")
  probe.fire()
  assertEqual(probe.store.barWidth, 231, "and the second window commits its own last value")
end)

test("throttle: a host whose timer answers a handle is unchanged", function()
  local armed, before, probe = dragSlider(returnsHandle)
  assertEqual(armed, 1, "slider: one timer per window")
  assertEqual(before, 0, "slider: nothing written until it fires")
  assertEqual(probe.writes, 1, "slider: one commit")
  armed, before, probe = dragColor(returnsHandle)
  assertEqual(armed, 1, "color: one timer per window")
  assertEqual(before, 0, "color: nothing written until it fires")
  assertEqual(probe.writes, 1, "color: one commit")
end)
