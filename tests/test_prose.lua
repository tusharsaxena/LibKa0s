-- tests/test_prose.lua — the prose gates over the two payloads this repo SHIPS: the library folder
-- and the test kit.
--
-- Both gates exist because the sweep alone regresses on the next feature. A one-off pass over 36
-- British spellings fixes today and nothing else; the case is what makes the 37th fail on the
-- commit that writes it.
--
-- And a consumer CANNOT fix either of these for itself. `libs/LibKa0s/` and `tests/_kit/` are
-- re-vendored whole-folder, so a local patch is reverted by the next re-vendor (anti-patterns #48)
-- — which is why WhatGroup's review counts 29 hits under its own `libs/LibKa0s/` as a finding
-- against WhatGroup. Both are fixed here, at the source, or not at all.

local T = _G.LK_TEST
local test, assertEqual, fail = T.test, T.assertEqual, T.fail

-- The directories whose BYTES SHIP. `tests/` is deliberately not here: its prose never leaves this
-- repo, and a gate over it would fire on the fixtures that deliberately spell a host's own field
-- names.
local SHIPPED = { "LibKa0s", "testkit" }

--- List the plain files in a directory, as a sorted array of basenames.
---
--- Lua 5.1 has no directory API and this repo does not depend on LuaFileSystem, so the listing
--- shells out — the same two commands tests/test_kitsync.lua uses, for the same reason. If neither
--- yields anything the gate FAILS rather than passing on an empty set: a gate that goes quiet when
--- it cannot look is worse than no gate, because it reports success.
local function listDir(dir)
  local names = {}
  local function collect(cmd)
    local p = io.popen(cmd)
    if not p then return end
    for line in p:lines() do
      local name = line:gsub("[\r\n]+$", "")
      if name ~= "" and name ~= "." and name ~= ".." then names[#names + 1] = name end
    end
    p:close()
  end
  collect('ls -A "' .. dir .. '" 2>/dev/null')
  if #names == 0 then collect('dir /b "' .. dir:gsub("/", "\\") .. '" 2>NUL') end
  if #names == 0 then
    fail("prose gate: could not list " .. dir .. "/ — no `ls -A` and no `dir /b`; this gate cannot "
      .. "run, and must not be reported as passing", 2)
  end
  table.sort(names)
  return names
end

--- Every `<dir>/<file>` under the shipped directories, as a sorted array of paths. Directories are
--- skipped by the only test Lua 5.1 offers: a directory cannot be opened for reading.
local function shippedFiles()
  local paths = {}
  for _, dir in ipairs(SHIPPED) do
    for _, name in ipairs(listDir(dir)) do
      local path = dir .. "/" .. name
      local f = io.open(path, "r")
      if f then
        f:close()
        paths[#paths + 1] = path
      end
    end
  end
  return paths
end

--- Run `matcher(lowercasedLine)` over every line of every shipped file, collecting `file:line —
--- <what>` for each hit. One walk, two gates: reading the payload twice would double the shell-outs
--- for nothing.
local function scan(matcher)
  local hits = {}
  for _, path in ipairs(shippedFiles()) do
    local f = io.open(path, "r")
    if f then
      local nline = 0
      for line in f:lines() do
        nline = nline + 1
        local what = matcher(line)
        if what then
          hits[#hits + 1] = ("%s:%d — %s"):format(path, nline, what)
        end
      end
      f:close()
    end
  end
  table.sort(hits)
  return hits
end

-- ── US English (localization-§5, anti-patterns #46) ──────────────────────────────────────────
--
-- Matched as SUBSTRINGS so one entry covers a word's whole family: `colour` catches coloured and
-- colours, `normalis` catches normalise and normalised. Case-insensitive, because the sentence-
-- initial spelling is the same defect.
--
-- Two carve-outs, recorded here so a later sweep does not "fix" them back:
--   * a Blizzard symbol reproduced verbatim (SetColorTexture, SetBackdropBorderColor) stays as
--     Blizzard spells it — none of them is British, which is why no exemption is needed in code;
--   * released CHANGELOG.md entries are history and stay, which is why CHANGELOG.md is not under
--     either shipped directory and is not scanned.
local BRITISH = { "colour", "grey", "behaviour", "synthesise", "normalis", "recognis" }

test("prose: no British spelling in the shipped library or the shipped kit", function()
  local hits = scan(function(line)
    local lower = line:lower()
    for _, word in ipairs(BRITISH) do
      if lower:find(word, 1, true) then return word end
    end
    return nil
  end)
  assertEqual(table.concat(hits, "\n          "), "",
    "localization-§5 mandates US English and anti-patterns #46 names comments explicitly; these "
    .. "spellings ship to every consumer and no consumer can fix them")
end)

-- ── section references (§N.M is a retired notation) ─────────────────────────────────────────
--
-- The standard is filename-scoped now — `library-stack-§4`, `options-ui-§8` — and a bare `§3.4`
-- names a numbering that no longer exists, so a reader cannot resolve it to anything.
--
-- Scoped to the shipped payload for a reason: `LibKa0s/Options.lua` is vendored BYTE-FOR-BYTE into
-- eight addons, so a §N.M left here (or reintroduced later) can only be corrected by a re-vendor
-- that reddens every consumer's tests/test_vendor_sync.lua until they take it. The same notation in
-- this repo's own docs/ or tests/ costs nobody anything and is swept separately.
test("prose: no retired §N.M section reference in the shipped library or the shipped kit", function()
  local hits = scan(function(line)
    local ref = line:match("\194\167%d+%.%d")
    if ref then return "retired section notation " .. ref .. "; use `<filename>-§N`" end
    return nil
  end)
  assertEqual(table.concat(hits, "\n          "), "",
    "a §N.M reference resolves to nothing in the current standard, and these bytes are vendored "
    .. "into every consumer")
end)
