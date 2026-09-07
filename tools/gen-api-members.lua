-- tools/gen-api-members.lua — publish each major's public member list as data.
--
--   lua tools/gen-api-members.lua        # from the repo root; rewrites every manifest
--
-- WHY THIS EXISTS. Nine addons in this collection carry a hand-written degradation stub of a
-- LibKa0s surface — `settings/OptionsSetup.lua` in each, 185 to 384 lines. A stub is a second
-- implementation of somebody else's surface, and the only thing a stub author had to write it
-- from was a reading of the library's source at whatever moment they read it. docs/api/ is the
-- source of truth for every public contract in this library, and it was prose in every one of its
-- documents: accurate, versioned, and not something a test can compare a stub against.
--
-- `docs/api/<Major>/members-<versionKey>.json` is the same contract as data. It is generated from
-- the live surface — the modules loaded through the same mock the suites use — so it cannot be
-- transcribed wrongly, and `tests/test_versioning.lua` regenerates and compares it on every run so
-- it cannot fall behind.
--
-- WHY IT IS KEYED BY VERSION, like every other document in docs/api/. Re-vendoring is whole-folder
-- and per-consumer, so at any moment two addons run different copies of the same major. A single
-- members.json describing only HEAD is a file that answers the wrong question for everyone who has
-- not re-vendored yet — which is the exact failure the folder-per-version convention was built to
-- prevent (docs/api/README.md). The version key is what `lib.MODULES` reports in-game, so the
-- number a player reads out names the file.
--
-- This file is BOTH the generator and the renderer: run as a script it writes, and `dofile`d it
-- returns the renderer and writes nothing, which is how the versioning gate compares without
-- shelling out. `arg[0]` is the script lua was invoked with, and that is this file only in the
-- first case.

local M = {}

-- The member rule is the KIT's, read from the vendored copy rather than restated here. A generator
-- with its own idea of what "public" means publishes a list the gate does not enforce, and the two
-- would drift in the one direction nobody checks.
local Kit = dofile("tests/_kit/framework.lua")

--- JSON string escaping. The values here are LibStub major names, Lua identifiers and type names,
--- so nothing needs escaping today — which is exactly when a generator quietly emits invalid JSON
--- the first time somebody adds a member with a quote in it.
local function q(s)
  return '"' .. tostring(s):gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

--- The `docs/api/` folder for a major: `LibKa0s-Options-1.0` keeps its documents under
--- `docs/api/Options/`. Derived rather than declared, matching tests/test_versioning.lua.
function M.apiFolder(major)
  return (tostring(major):gsub("^LibKa0s%-", ""):gsub("%-%d+%.%d+$", ""))
end

--- The version key of a major: every file's minor joined with `.` in LOAD order, which is
--- `m.files`, which is LibKa0s.xml's order. Never `pairs(lib.MODULES)`: `pairs` has no order, and a
--- generator whose output filename depends on hash iteration produces a different file on someone
--- else's Lua.
function M.versionKey(m, lib)
  local parts = {}
  for _, file in ipairs(m.files) do parts[#parts + 1] = tostring(lib.MODULES[file]) end
  return table.concat(parts, ".")
end

function M.path(m, lib)
  return ("docs/api/%s/members-%s.json"):format(M.apiFolder(m.major), M.versionKey(m, lib))
end

--- The manifest for one major, as JSON text with LF terminators.
---
--- The member list is `Kit.publicMembers`, so what is published is precisely what
--- `Kit.assertSurfaceParity(stub, majorName)` enforces. A manifest listing anything else would be a
--- document telling stub authors to carry members the gate does not ask for.
function M.manifest(m, lib)
  local out = {}
  local function add(line) out[#out + 1] = line end

  add("{")
  add('  "major": ' .. q(m.major) .. ",")
  add('  "versionKey": ' .. q(M.versionKey(m, lib)) .. ",")
  add('  "generator": "tools/gen-api-members.lua",')
  add('  "modules": [')
  for i, file in ipairs(m.files) do
    add(('    { "file": %s, "minor": %d }%s')
      :format(q(file), lib.MODULES[file], i < #m.files and "," or ""))
  end
  add("  ],")
  add('  "members": [')
  local members = Kit.publicMembers(lib)
  for i, member in ipairs(members) do
    add(('    { "name": %s, "kind": %s }%s')
      :format(q(member.name), q(member.kind), i < #members and "," or ""))
  end
  add("  ]")
  add("}")
  return table.concat(out, "\n") .. "\n"
end

--- Load the library through the same mock the suites use, and write every major's manifest.
---
--- The eight lines of boot below are the head of tests/run.lua. They are repeated rather than
--- reached, because reaching them means running the suite, and a generator that runs 788 test cases
--- to write ten files is one nobody runs.
function M.writeAll()
  local Loader = dofile("tests/_kit/loader.lua")
  local mocks  = dofile("tests/wow_mock.lua")()
  Loader.loadAll(Loader.xmlFiles("LibKa0s/LibKa0s.xml"), nil, mocks)

  local written = 0
  for _, m in ipairs(dofile("tests/majors.lua")) do
    local lib = mocks.LibStub(m.major, true)
    if lib and type(lib.MODULES) == "table" then
      local path = M.path(m, lib)
      -- CRLF, written here rather than left to the shell. The repo is pinned `* text=auto
      -- eol=crlf`; a plain redirect writes LF into the working tree, git's filters never see it
      -- (the blob is LF either way), and nothing but a byte-level audit ever notices. That is the
      -- defect tests/test_eol.lua exists for, and this writer is not going to reintroduce it.
      local f = assert(io.open(path, "wb"))
      f:write((M.manifest(m, lib):gsub("\n", "\r\n")))
      f:close()
      written = written + 1
      print("wrote " .. path)
    end
  end
  print(written .. " manifest(s) written")
end

if arg and arg[0] and tostring(arg[0]):match("gen%-api%-members%.lua$") then M.writeAll() end

return M
