-- tests/test_widgets_draghandle_layers.lua — LibKa0s-Widgets-1.0: where `lib.DragHandle` sits
-- (WidgetsDragHandle minor 5): `spec.level`, an offset over the parent's frame level applied at birth
-- BEFORE the help and close marks are built, `handle:ApplyLevel()`, which re-applies it after the
-- host re-levels or re-parents the parent, and `spec.ignoreParentAlpha`, which keeps the strip
-- opaque over a display that fades its content (frame-layering-§2 and §3; XS-05, XS-15, XS-18).
--
-- A suite of its own for `layout-§1`: tests/test_widgets_draghandle.lua sits at 813 lines and these
-- cases would take it toward the 1000–1500 band. The bench is the same one, in
-- tests/fixture_draghandle.lua; every case installs the kit's frame-layer recorder
-- (tests/_kit/mock_layers.lua) over the bench's frame factory, so levels and parent alpha read back,
-- and restores it before the bench restores its own factory.

local T = _G.LK_TEST
local assertEqual = T.assertEqual
local assertTrue  = T.assertTrue
local assertFalse = T.assertFalse
local mocks       = T.mocks

local W = T.widgets

local Bench    = dofile("tests/fixture_draghandle.lua")
local baseSpec = Bench.baseSpec

-- The kit's secret wrapper, installed on a table of this suite's own: the claim below is that a
-- parent level the client answers as a secret is read through the guard and never computed on.
local Secrets = {}
dofile("tests/_kit/secrets.lua")(Secrets)

--- A bench case with the layer recorder installed on the bench's factory, restored after.
local function test(name, fn)
  return Bench.test(name, function()
    local restore = dofile("tests/_kit/mock_layers.lua")(mocks)
    local ok, err = pcall(fn)
    restore()
    if not ok then error(err, 0) end
  end)
end

--- A parent at `level`, built under the recorder.
local function parentAt(level)
  local p = mocks.CreateFrame("Frame", nil, mocks.UIParent)
  if level ~= nil then p:SetFrameLevel(level) end
  return p
end

--- Every frame the next calls create and every SetFrameLevel written, IN ORDER, as one log: the claim
--- about birth is a claim about sequence (the handle's level is written before its marks exist), and
--- the recorder alone derives a child's level dynamically, so it cannot tell the two orders apart.
local function recordBirth()
  local log = {}
  local prev = mocks.CreateFrame
  mocks.CreateFrame = function(...)
    local f = prev(...)
    log[#log + 1] = { "create", f }
    local set = rawget(f, "SetFrameLevel")
    rawset(f, "SetFrameLevel", function(self, n)
      log[#log + 1] = { "level", self, n }
      return set(self, n)
    end)
    return f
  end
  return log, function() mocks.CreateFrame = prev end
end

--- How many SetFrameLevel writes `frames` receive from now on; the spy re-assigns the saved
--- function rather than rawsetting nil, as mock_layers.lua's SPYING note asks.
local function countWrites(frames)
  local n, saved = { count = 0 }, {}
  for i, f in ipairs(frames) do
    saved[i] = rawget(f, "SetFrameLevel")
    rawset(f, "SetFrameLevel", function(self, v) n.count = n.count + 1; return saved[i](self, v) end)
  end
  return n, function() for i, f in ipairs(frames) do rawset(f, "SetFrameLevel", saved[i]) end end
end

local function levelOf(f) return mocks.__layers(f).level end

test("DragHandle minor 5: MODULES and the file minor say 5", function()
  -- At least 5, the minor the level arrived at; a later minor moves both together.
  assertTrue(W.__dragMinor >= 5, "DragHandle is at minor 5 or later")
  assertEqual(W.MODULES.WidgetsDragHandle, W.__dragMinor)
end)

test("DragHandle level: no spec.level keeps minor 4 -- handle at parent + 1, marks at handle + 1", function()
  local p = parentAt(7)
  local h = W.DragHandle(p, baseSpec({ onClose = function() end }))
  assertEqual(levelOf(h), 8)
  assertEqual(levelOf(h.help), 9)
  assertEqual(levelOf(h.close), 9)
  assertEqual(rawget(h, "__level"), nil, "no explicit level is written without spec.level")
end)

test("DragHandle level: level = 50 on a parent at 7 -- handle 57, marks 58, written before the marks exist", function()
  local p = parentAt(7)
  local log, stop = recordBirth()
  local ok, h = pcall(W.DragHandle, p, baseSpec({ level = 50, onClose = function() end }))
  stop()
  assertTrue(ok, tostring(h))
  assertEqual(levelOf(h), 57)
  assertEqual(levelOf(h.help), 58)
  assertEqual(levelOf(h.close), 58)
  local wrote, helpBorn, closeBorn
  for i, e in ipairs(log) do
    if e[1] == "level" and e[2] == h and e[3] == 57 then wrote = wrote or i end
    if e[1] == "create" and e[2] == h.help then helpBorn = i end
    if e[1] == "create" and e[2] == h.close then closeBorn = i end
  end
  assertTrue(wrote and helpBorn and closeBorn, "the handle's write and both marks' births are logged")
  assertTrue(wrote < helpBorn, "the handle's level is written before the help mark is built")
  assertTrue(wrote < closeBorn, "the handle's level is written before the close mark is built")
end)

test("DragHandle ApplyLevel: a parent re-leveled to 20 puts the handle at 70 and the marks at 71", function()
  local p = parentAt(7)
  local h = W.DragHandle(p, baseSpec({ level = 50, onClose = function() end }))
  p:SetFrameLevel(20)
  assertEqual(h:ApplyLevel(), true)
  assertEqual(levelOf(h), 70)
  assertEqual(levelOf(h.help), 71)
  assertEqual(levelOf(h.close), 71)
  assertEqual(rawget(h.help, "__level"), 71, "the help mark's level is written explicitly")
  assertEqual(rawget(h.close, "__level"), 71, "the close mark's level is written explicitly")
end)

test("DragHandle ApplyLevel: a mark the client did not build leaves the other one reached", function()
  local p = parentAt(7)
  local h = W.DragHandle(p, baseSpec({ level = 50, onClose = function() end }))
  h.help = nil
  p:SetFrameLevel(20)
  assertEqual(h:ApplyLevel(), true)
  assertEqual(rawget(h.close, "__level"), 71, "the close mark is reached past the missing help mark")
end)

test("DragHandle ApplyLevel: without spec.level it answers false and writes nothing", function()
  local p = parentAt(7)
  local h = W.DragHandle(p, baseSpec({ onClose = function() end }))
  local n, unspy = countWrites({ h, h.help, h.close })
  local ok, res = pcall(h.ApplyLevel, h)
  unspy()
  assertTrue(ok, tostring(res))
  assertEqual(res, false)
  assertEqual(n.count, 0)
  assertEqual(levelOf(h), 8)
end)

test("DragHandle level: a secret or non-number parent level reads as 0", function()
  for _, answer in ipairs({ "secret", "text" }) do
    local p = parentAt(7)
    local v = answer == "secret" and Secrets.secret(7) or "high"
    rawset(p, "GetFrameLevel", function() return v end)
    local ok, h = pcall(W.DragHandle, p, baseSpec({ level = 5 }))
    assertTrue(ok, answer .. ": " .. tostring(h))
    assertEqual(levelOf(h), 5, answer)
    assertEqual(levelOf(h.help), 6, answer)
    local applied, res = pcall(h.ApplyLevel, h)
    assertTrue(applied, answer .. ": " .. tostring(res))
    assertEqual(res, true, answer)
    assertEqual(levelOf(h), 5, answer)
  end
end)

test("DragHandle level: the host's numeric guard reads the parent's level", function()
  local p = parentAt(7)
  local seen
  local h = W.DragHandle(p, baseSpec({
    level = 3,
    number = function(v, fallback) seen = v; return tonumber(v) or fallback end,
  }))
  assertEqual(seen, 7)
  assertEqual(levelOf(h), 10)
end)

test("DragHandle ignoreParentAlpha: true sets it, absent leaves it false", function()
  local on = W.DragHandle(parentAt(7), baseSpec({ ignoreParentAlpha = true }))
  assertTrue(on:IsIgnoringParentAlpha())
  local off = W.DragHandle(parentAt(7), baseSpec())
  assertFalse(off:IsIgnoringParentAlpha())
end)

test("DragHandle ignoreParentAlpha: a frame without SetIgnoreParentAlpha does not error", function()
  local prev = mocks.CreateFrame
  mocks.CreateFrame = function(...)
    local f = prev(...)
    rawset(f, "SetIgnoreParentAlpha", nil)
    local mt = getmetatable(f)
    local index = mt and mt.__index
    setmetatable(f, { __index = function(t, k)
      if k == "SetIgnoreParentAlpha" then return nil end
      if type(index) == "function" then return index(t, k) end
      return nil
    end })
    return f
  end
  local ok, h = pcall(W.DragHandle, parentAt(7), baseSpec({ ignoreParentAlpha = true }))
  mocks.CreateFrame = prev
  assertTrue(ok, tostring(h))
  assertTrue(h ~= nil)
end)

test("DragHandle level: onClose plus level builds both marks at handle + 1", function()
  local h = W.DragHandle(parentAt(2), baseSpec({ level = 40, onClose = function() end }))
  assertTrue(h.help ~= nil and h.close ~= nil)
  assertEqual(levelOf(h), 42)
  assertEqual(levelOf(h.help), 43)
  assertEqual(levelOf(h.close), 43)
end)
