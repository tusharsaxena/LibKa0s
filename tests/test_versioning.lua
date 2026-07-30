-- tests/test_versioning.lua — the versioning contract, across every major this library ships.
--
-- LibStub picks a winner between vendored copies by comparing MINOR integers, so a released change
-- that does not bump its file's minor is invisible: every host that already carries the old copy
-- keeps running it, and the fix silently does not ship. Nothing in Lua can notice that on its own,
-- which is why the discipline is pinned here — the one part of it a test CAN enforce is that code and
-- changelog agree about what version each file is at.
--
-- Every case iterates LK_TEST.majors (declared in tests/run.lua) rather than naming files inline.
-- Before the multi-module extraction this suite hard-coded Perf's two filenames, which would have
-- meant four more near-identical copies of each case as the library grew.
--
-- See docs/releasing.md for the order of operations these tests exist to protect.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local majors, mocks = T.majors, T.mocks

local function readFile(path)
  local f = io.open(path, "r")
  assertTrue(f ~= nil, "cannot open " .. path .. " (tests run from the repo root)")
  local body = f:read("*a")
  f:close()
  return body
end

--- The registered library table for a major, or nil. Silent, because a major declared in run.lua's
--- MAJORS but never registered is a failure this suite should REPORT, not raise on.
local function libFor(major)
  return mocks.LibStub(major, true)
end

test("versioning: every declared major is actually registered", function()
  local missing = {}
  for _, m in ipairs(majors) do
    if not libFor(m.major) then missing[#missing + 1] = m.major end
  end
  table.sort(missing)
  assertEqual(table.concat(missing, ", "), "",
    "these majors are declared in tests/run.lua but never called NewLibrary")
end)

test("versioning: every file in every major registers its live version", function()
  for _, m in ipairs(majors) do
    local lib = libFor(m.major)
    if lib then
      assertTrue(type(lib.MODULES) == "table", m.major .. ": lib.MODULES exists")
      -- Named explicitly rather than counted: a new file added to a major without a MODULES entry
      -- makes version skew unanswerable from in-game.
      for _, file in ipairs(m.files) do
        assertTrue(lib.MODULES[file] ~= nil, m.major .. ": " .. file .. " registers")
      end
      assertEqual(lib.MODULES[m.primary], lib.MINOR,
        m.major .. ": the primary file's entry is the major's own minor")
    end
  end
end)

test("versioning: no file registers under a major it does not belong to", function()
  -- MODULES is per-major, so a stray entry means one file wrote into another's registry — which
  -- would make "what am I running?" answer with a number from the wrong module.
  for _, m in ipairs(majors) do
    local lib = libFor(m.major)
    if lib and type(lib.MODULES) == "table" then
      local declared = {}
      for _, file in ipairs(m.files) do declared[file] = true end
      for name in pairs(lib.MODULES) do
        assertTrue(declared[name] == true,
          m.major .. ": unexpected MODULES entry '" .. tostring(name) ..
          "' — either that file belongs to another major, or tests/run.lua's MAJORS is stale")
      end
    end
  end
end)

test("versioning: every registered version is a positive integer", function()
  for _, m in ipairs(majors) do
    local lib = libFor(m.major)
    if lib and type(lib.MODULES) == "table" then
      for name, minor in pairs(lib.MODULES) do
        assertTrue(type(minor) == "number", name .. " minor is a number")
        assertEqual(minor, math.floor(minor),
          name .. " minor is an integer — LibStub compares integers")
        assertTrue(minor >= 1, name .. " minor is at least 1")
      end
    end
  end
end)

test("versioning: file basenames are unique across every major", function()
  -- The changelog needle below is `"<FileBasename> minor <N>"`, plain-searched in one shared
  -- CHANGELOG.md, so two majors owning a file of the same name would satisfy each other's
  -- assertion. This is why the Options module ships OptionsWidgets.lua and OptionsScroll.lua rather
  -- than Widgets.lua and ScrollPatch.lua — those bare names are exactly what a future window module
  -- would want, and the collision would be silent.
  local seen = {}
  for _, m in ipairs(majors) do
    for _, file in ipairs(m.files) do
      assertTrue(seen[file] == nil,
        "file basename '" .. file .. "' is claimed by both " .. tostring(seen[file]) ..
        " and " .. m.major .. " — the changelog check cannot tell them apart")
      seen[file] = m.major
    end
  end
end)

test("versioning: the changelog accounts for the version every file is at", function()
  local changelog = readFile("CHANGELOG.md")
  -- Every miss is collected before failing. Asserting inside the loop would abort on the first
  -- missing entry and leave the rest unchecked — which is exactly how this test's own first run
  -- reported one gap while hiding a second.
  local missing = {}
  for _, m in ipairs(majors) do
    local lib = libFor(m.major)
    if lib and type(lib.MODULES) == "table" then
      for name, minor in pairs(lib.MODULES) do
        -- Loose about wording, strict about the pair: any line may carry it, but the file's name and
        -- its current number must both appear. This is what fails when someone bumps a minor and
        -- forgets the entry, or writes an entry for a bump they did not make.
        local needle = ("%s minor %d"):format(name, minor)
        if not changelog:find(needle, 1, true) then missing[#missing + 1] = needle end
      end
    end
  end
  table.sort(missing)
  assertEqual(table.concat(missing, ", "), "",
    "CHANGELOG.md is missing these — a bump and its changelog entry must move together")
end)

test("versioning: every paired secondary file records which primary it attached to", function()
  -- The pairing guard's own state. Asserted because a secondary silently attached to a primary from
  -- a different vendored copy is the failure the single-major layout is supposed to make impossible,
  -- and the two-copy simulations in tests/test_perf_isolation.lua depend on these fields being
  -- maintained.
  for _, m in ipairs(majors) do
    local lib = libFor(m.major)
    if lib then
      for _, p in ipairs(m.paired or {}) do
        assertEqual(lib[p.probeField], lib.MINOR,
          m.major .. ": " .. p.file .. " was built against the live primary")
        assertEqual(lib[p.minorField], lib.MODULES[p.file],
          m.major .. ": " .. p.file .. " reports its own version consistently")
      end
    end
  end
end)
