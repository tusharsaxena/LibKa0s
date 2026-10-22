-- tests/test_glow.lua — LibKa0s-Glow-1.0, the stateless LibCustomGlow-1.0 driver.
--
-- Every case runs on a fresh environment with Core and Glow loaded and a recording fake of
-- LibCustomGlow-1.0 registered on THAT environment's LibStub, the way DropWatcher's and
-- QuickComms' suites register theirs. Each fake `_Start` / `_Stop` records
-- `{ name, n = select("#", ...), ... }`, so a position, a trailing nil and an argument count are
-- all assertable. The fake ProcGlow_Start calls setmetatable on its options, as the real one does
-- (LCG:920), so a driver that handed over the caller's knobs would be caught by its metatable.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local MAJOR = "LibKa0s-Glow-1.0"
local STYLES = { "button", "proc", "pixel", "autocast" }
local MEMBERS = {
  "ButtonGlow_Start", "ButtonGlow_Stop", "PixelGlow_Start", "PixelGlow_Stop",
  "AutoCastGlow_Start", "AutoCastGlow_Stop", "ProcGlow_Start", "ProcGlow_Stop",
}

--- A fresh environment with Core and Glow loaded and no LibCustomGlow-1.0.
local function env()
  local m = buildMocks()
  Loader.load("LibKa0s/Core.lua", nil, m)
  Loader.load("LibKa0s/Glow.lua", nil, m)
  return m, m.LibStub(MAJOR)
end

--- Register a recording fake of LibCustomGlow-1.0 on `m`'s LibStub. `omit` names members to leave
--- out. Returns the fake and its call log.
local function fakeLCG(m, omit)
  local L = m.LibStub:NewLibrary("LibCustomGlow-1.0", 24)
  local calls = {}
  for _, name in ipairs(MEMBERS) do
    if not (omit and omit[name]) then
      L[name] = function(...)
        local rec = { name = name, n = select("#", ...), ... }
        local _, opts = ...
        if name == "ProcGlow_Start" and type(opts) == "table" then
          setmetatable(opts, { __index = { startAnim = true, duration = 1, xOffset = 0, yOffset = 0 } })
        end
        calls[#calls + 1] = rec
      end
    end
  end
  return L, calls
end

--- A driver with a fake already registered.
local function withLCG(omit)
  local m, G = env()
  local L, calls = fakeLCG(m, omit)
  return G, calls, L
end

local FRAME = { name = "frame" }
local COLOR = { 1, 0.5, 0.25, 0.9 }
local FULL = {
  color = COLOR, pixelLines = 8, pixelFrequency = 0.25, pixelLength = 6, pixelThickness = 2,
  pixelBorder = false, autocastParticles = 4, autocastFrequency = 0.125, autocastScale = 1.5,
  buttonFrequency = 0.2, procDuration = 1.25, procStartAnim = false, xOffset = 3, yOffset = -2,
}

-- ── the major ────────────────────────────────────────────────────────────────────────────

test("glow: the major registers with Core, and reports its file minor", function()
  local _, G = env()
  assertTrue(G ~= nil, MAJOR .. " registered")
  assertEqual(G.MAJOR, MAJOR)
  assertEqual(G.MODULES.Glow, G.MINOR, "the file reports its own live version")
  assertEqual(type(G.Start), "function")
  assertEqual(type(G.Stop), "function")
  assertNil(rawget(G, "STYLES"), "no STYLES member is published")
end)

-- 1 ───────────────────────────────────────────────────────────────────────────────────────

test("glow: absent LCG -- Start answers false for every style and Stop is quiet", function()
  -- red under: a load-time capture of LCG, or an unguarded L.X
  local _, G = env()
  for _, style in ipairs(STYLES) do
    assertFalse(G.Start(FRAME, style, FULL, "K", 2), style .. " starts nothing without LCG")
    G.Stop(FRAME, style, "K")
  end
  G.Stop(FRAME, nil, "K")
end)

-- 2 ───────────────────────────────────────────────────────────────────────────────────────

test("glow: LCG registered AFTER the driver loads is reached at call time", function()
  -- red under: `local L = LibStub(LCG, true)` at file load (KickCD's former shape)
  local m, G = env()
  assertFalse(G.Start(FRAME, "pixel", FULL, "K"), "nothing to call yet")
  local _, calls = fakeLCG(m)
  assertTrue(G.Start(FRAME, "pixel", FULL, "K"), "the late fake is found")
  assertEqual(#calls, 1)
  assertEqual(calls[1].name, "PixelGlow_Start")
end)

-- 3 ───────────────────────────────────────────────────────────────────────────────────────

test("glow: pixel maps every knob to its LCG position, key at 10 and frameLevel at 11", function()
  -- red under: any position swapped in the pixel mapping
  local G, calls = withLCG()
  assertTrue(G.Start(FRAME, "pixel", FULL, "K", 2))
  local c = calls[1]
  assertEqual(c.name, "PixelGlow_Start")
  assertEqual(c.n, 11)
  assertTrue(rawequal(c[1], FRAME))
  assertTrue(rawequal(c[2], COLOR), "color is passed by reference")
  assertEqual(c[3], 8); assertEqual(c[4], 0.25); assertEqual(c[5], 6); assertEqual(c[6], 2)
  assertEqual(c[7], 3); assertEqual(c[8], -2); assertEqual(c[9], false)
  assertEqual(c[10], "K"); assertEqual(c[11], 2)
end)

-- 4 ───────────────────────────────────────────────────────────────────────────────────────

test("glow: pixelLength 0, negative, a string or nil goes as nil; a positive number passes", function()
  -- red under: passing pixelLength raw (0 draws zero-length lines in LCG)
  local G, calls = withLCG()
  for _, v in ipairs({ 0, -3, "6", false }) do
    G.Start(FRAME, "pixel", { pixelLength = v }, "K")
    assertNil(calls[#calls][5], "pixelLength " .. tostring(v) .. " is automatic")
  end
  G.Start(FRAME, "pixel", {}, "K")
  assertNil(calls[#calls][5], "nil stays nil")
  G.Start(FRAME, "pixel", { pixelLength = 6 }, "K")
  assertEqual(calls[#calls][5], 6)
end)

-- 5 ───────────────────────────────────────────────────────────────────────────────────────

test("glow: pixelBorder and procStartAnim are false only when false", function()
  -- red under: `== true` (a nil border would draw none), or passing either raw
  local G, calls = withLCG()
  G.Start(FRAME, "pixel", { pixelBorder = false }, "K")
  assertEqual(calls[#calls][9], false)
  for _, v in ipairs({ true, "x" }) do
    G.Start(FRAME, "pixel", { pixelBorder = v }, "K")
    assertEqual(calls[#calls][9], true, "pixelBorder " .. tostring(v))
    G.Start(FRAME, "proc", { procStartAnim = v }, "K")
    assertEqual(calls[#calls][2].startAnim, true, "procStartAnim " .. tostring(v))
  end
  G.Start(FRAME, "pixel", {}, "K")
  assertEqual(calls[#calls][9], true, "nil draws the border, LCG's own nil meaning")
  G.Start(FRAME, "proc", {}, "K")
  assertEqual(calls[#calls][2].startAnim, true, "nil plays the start animation")
  G.Start(FRAME, "proc", { procStartAnim = false }, "K")
  assertEqual(calls[#calls][2].startAnim, false)
end)

-- 6 ───────────────────────────────────────────────────────────────────────────────────────

test("glow: a numeric knob that is not a number goes as nil", function()
  -- red under: passing a numeric knob through without the type guard
  local G, calls = withLCG()
  G.Start(FRAME, "pixel", { pixelLines = "8", xOffset = "3" }, "K")
  assertNil(calls[#calls][3], "pixelLines '8'")
  assertNil(calls[#calls][7], "xOffset '3'")
  G.Start(FRAME, "proc", { procDuration = {} }, "K")
  assertNil(rawget(calls[#calls][2], "duration"), "procDuration {}")
end)

-- 7 ───────────────────────────────────────────────────────────────────────────────────────

test("glow: autocast maps 9 positions and button 4, button with no key", function()
  -- red under: a key threaded into ButtonGlow_Start, or any autocast position swapped
  local G, calls = withLCG()
  G.Start(FRAME, "autocast", FULL, "K", 2)
  local a = calls[1]
  assertEqual(a.name, "AutoCastGlow_Start")
  assertEqual(a.n, 9)
  assertTrue(rawequal(a[2], COLOR))
  assertEqual(a[3], 4); assertEqual(a[4], 0.125); assertEqual(a[5], 1.5)
  assertEqual(a[6], 3); assertEqual(a[7], -2); assertEqual(a[8], "K"); assertEqual(a[9], 2)

  G.Start(FRAME, "button", FULL, "K", 2)
  local b = calls[2]
  assertEqual(b.name, "ButtonGlow_Start")
  assertEqual(b.n, 4)
  assertTrue(rawequal(b[2], COLOR))
  assertEqual(b[3], 0.2)
  assertEqual(b[4], 2, "position 4 is frameLevel, not the key")
end)

-- 8 ───────────────────────────────────────────────────────────────────────────────────────

test("glow: proc gets a fresh options table per call, never the caller's knobs", function()
  -- red under: handing ProcGlow_Start the knobs table, or reusing one scratch table
  local G, calls = withLCG()
  local knobs = {
    color = COLOR, procDuration = 1.25, procStartAnim = false, xOffset = 3, yOffset = -2,
  }
  G.Start(FRAME, "proc", knobs, "K", 2)
  G.Start(FRAME, "proc", knobs, "K", 2)
  local o1, o2 = calls[1][2], calls[2][2]
  assertEqual(calls[1].name, "ProcGlow_Start")
  assertEqual(calls[1].n, 2)
  assertFalse(rawequal(o1, knobs), "not the caller's knobs")
  assertNil(getmetatable(knobs), "LCG's setmetatable never reached the caller's table")
  assertFalse(rawequal(o1, o2), "a new table per call")
  assertTrue(rawequal(o1.color, COLOR))
  assertEqual(o1.startAnim, false); assertEqual(o1.duration, 1.25)
  assertEqual(o1.xOffset, 3); assertEqual(o1.yOffset, -2)
  assertEqual(o1.key, "K"); assertEqual(o1.frameLevel, 2)

  G.Start(FRAME, "proc", nil, "K")
  local o3 = calls[3][2]
  local fields = {}
  for k in pairs(o3) do fields[#fields + 1] = k end
  assertEqual(#fields, 2, "nil knobs: only startAnim and the key are set")
  assertEqual(o3.startAnim, true)
  assertEqual(o3.key, "K")
end)

-- 9 ───────────────────────────────────────────────────────────────────────────────────────

test("glow: nil and non-table knobs read as empty, and the call still happens", function()
  -- red under: indexing a non-table knobs, or refusing the call without knobs
  local G, calls = withLCG()
  for _, knobs in ipairs({ false, "x", 7 }) do
    assertTrue(G.Start(FRAME, "pixel", knobs, "K"))
  end
  assertTrue(G.Start(FRAME, "pixel", nil, "K"))
  assertEqual(#calls, 4)
  for _, c in ipairs(calls) do
    for i = 2, 8 do assertNil(c[i], "slot " .. i .. " is nil") end
    assertEqual(c[9], true)
    assertEqual(c[10], "K")
  end
end)

-- 10 ──────────────────────────────────────────────────────────────────────────────────────

test("glow: an unknown style or a nil frame answers false and calls nothing", function()
  -- red under: aliases or case-folding of style names, or forwarding a nil frame
  local G, calls = withLCG()
  assertFalse(G.Start(FRAME, "Pixel", FULL, "K"))
  assertFalse(G.Start(FRAME, "action", FULL, "K"))
  assertFalse(G.Start(FRAME, nil, FULL, "K"))
  assertFalse(G.Start(nil, "pixel", FULL, "K"))
  G.Stop(nil, "pixel", "K")
  G.Stop(nil, nil, "K")
  assertEqual(#calls, 0)
end)

-- 11 ──────────────────────────────────────────────────────────────────────────────────────

test("glow: a missing LCG member answers false or is skipped, and others still work", function()
  -- red under: calling L.ProcGlow_Start without the presence check
  local G, calls = withLCG{ ProcGlow_Start = true, ProcGlow_Stop = true }
  assertFalse(G.Start(FRAME, "proc", FULL, "K"))
  G.Stop(FRAME, "proc", "K")
  assertEqual(#calls, 0)
  assertTrue(G.Start(FRAME, "pixel", FULL, "K"))
  G.Stop(FRAME, nil, "K")
  local names = {}
  for _, c in ipairs(calls) do names[#names + 1] = c.name end
  assertEqual(table.concat(names, ","), "PixelGlow_Start,ButtonGlow_Stop,PixelGlow_Stop,AutoCastGlow_Stop")
end)

-- 12 ──────────────────────────────────────────────────────────────────────────────────────

test("glow: Stop shapes -- one style, keyless button, stop-all in order, unknown is a no-op", function()
  -- red under: a key passed to ButtonGlow_Stop, a different stop-all order, or an unknown
  -- style string read as stop-all
  local G, calls = withLCG()
  G.Stop(FRAME, "pixel", "K")
  assertEqual(#calls, 1)
  assertEqual(calls[1].name, "PixelGlow_Stop")
  assertEqual(calls[1].n, 2)
  assertTrue(rawequal(calls[1][1], FRAME)); assertEqual(calls[1][2], "K")

  G.Stop(FRAME, "button", "K")
  assertEqual(calls[2].name, "ButtonGlow_Stop")
  assertEqual(calls[2].n, 1, "the button style takes no key")

  G.Stop(FRAME, "bogus", "K")
  assertEqual(#calls, 2, "an unknown style string stops nothing")

  G.Stop(FRAME, nil, "K")
  local names = {}
  for i = 3, #calls do names[#names + 1] = calls[i].name end
  assertEqual(table.concat(names, ","),
    "ButtonGlow_Stop,PixelGlow_Stop,AutoCastGlow_Stop,ProcGlow_Stop")
  assertEqual(calls[3].n, 1)
  for i = 4, 6 do assertEqual(calls[i][2], "K") end
end)

-- 13 ──────────────────────────────────────────────────────────────────────────────────────

test("glow: stateless -- Start never stops, and repeated Starts all reach LCG", function()
  -- red under: a stop-before-start, or an unchanged-repaint gate inside the driver
  local G, calls = withLCG()
  for _ = 1, 3 do
    for _, style in ipairs(STYLES) do G.Start(FRAME, style, FULL, "K", 2) end
  end
  assertEqual(#calls, 12)
  for _, c in ipairs(calls) do
    assertTrue(c.name:find("_Start$") ~= nil, c.name .. " is a start")
  end
end)

-- 14 ──────────────────────────────────────────────────────────────────────────────────────

test("glow: Glow.lua names LibStub(...) only in the Core probe and the LCG resolver", function()
  -- red under: a second LibStub lookup (a load-time LCG capture) anywhere in the file
  local fh = assert(io.open("LibKa0s/Glow.lua", "r"))
  local src = fh:read("*a")
  fh:close()
  local hits = {}
  for line in src:gmatch("[^\n]+") do
    if not line:match("^%s*%-%-") and line:find("LibStub%s*%(") then hits[#hits + 1] = line end
  end
  assertEqual(#hits, 2, "two LibStub(...) calls in code")
  assertTrue(hits[1]:find('LibStub%("LibKa0s%-Core%-1%.0", true%)') ~= nil, "the Core probe")
  assertTrue(hits[2]:find("local function lcg%(%)") ~= nil, "the call-time resolver")
end)
