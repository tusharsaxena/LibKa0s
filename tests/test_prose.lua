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

--- Every `<dir>/<file>` under the shipped directories, as a sorted array of paths.
---
--- DIRECTORIES ARE SKIPPED BY READING, NOT BY OPENING. This used to skip them on the strength of
--- `io.open` refusing a directory, which is true on Windows and false on Linux: there `io.open`
--- hands back a handle and the failure lands on the first read, as `Is a directory` — thrown from
--- inside the scan, where it read as a broken gate rather than as a directory. `LibKa0s/media/` is
--- the first subdirectory this library has ever shipped and the first to find that out.
---
--- The listing does not recurse, so nothing under `media/` is scanned: it holds art, type and their
--- upstream licences, none of it this collection's prose. A `.lua` added under there would go
--- unscanned — put shipped code in the payload root, where the two gates below can see it.
local function shippedFiles()
  local paths = {}
  for _, dir in ipairs(SHIPPED) do
    for _, name in ipairs(listDir(dir)) do
      local path = dir .. "/" .. name
      local f = io.open(path, "r")
      if f then
        -- The probe has to READ A BYTE and get one. A directory opens, and on Linux its first
        -- read answers nil rather than raising -- the raise comes later, from `lines()`, inside the
        -- scan. An empty file is skipped by the same test, which costs nothing: a file with no
        -- bytes has no prose.
        local ok, first = pcall(function() return f:read(1) end)
        f:close()
        if ok and first ~= nil then paths[#paths + 1] = path end
      end
    end
  end
  return paths
end

--- Run `matcher(line, path)` over every line of every shipped file, collecting `file:line —
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
        local what = matcher(line, path)
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

-- ── US English (localization-§5, anti-patterns #46) ─────────────────────────────
--
-- BOTH LISTS BELOW ARE COPIED WHOLE OUT OF `localization-§5`, and the section requires exactly
-- that: a gate MUST carry every published entry and MUST NOT carry one that is not published. This
-- gate used to hold six substrings of its own choosing, two of which were not in the section at
-- all, and it stayed green for months while `CANCELLED` shipped in the chat text Perf.lua writes.
-- A private list is a coverage claim nobody outside this repo can check — which is `testing-§12`'s
-- failure mode sitting inside the gate for `localization-§5`. If a sweep finds a British form
-- neither list knows about, it amends the section first and this copy syncs after; a private
-- addition here MUST NOT outlive the change that found it.
--
-- BRITISH is lowercase substrings, matched case-insensitively, so one entry covers a word's whole
-- family: `colour` catches coloured and colours, `normalis` catches normalise and normalised. That
-- economy is also the trap — *analysis* contains `analys`, *programmer* contains `programme` — so
-- ALLOWED names the correct US words that collide, and they are REMOVED AS WHOLE WORDS before the
-- substring scan runs. Whole words, not substrings: allowing `analyses` as a substring would
-- swallow *analysed* inside it and hide the very defect this gate exists to find.
--
-- Two carve-outs, recorded here so a later sweep does not "fix" them back:
--   * a Blizzard symbol reproduced verbatim (SetColorTexture, SetBackdropBorderColor) stays as
--     Blizzard spells it — none of them is British, which is why no exemption is needed in code;
--   * released CHANGELOG.md entries are history and stay, which is why CHANGELOG.md is not under
--     either shipped directory and is not scanned.
local BRITISH = {
  -- -our → -or
  "colour", "behaviour", "favour", "honour", "neighbour", "armour", "flavour",
  "labour", "rumour", "humour", "endeavour", "rigour", "vigour", "saviour",
  -- -re → -er
  "centre", "centring", "metre", "fibre", "calibre", "theatre", "manoeuvre",
  -- -ce → -se
  "defence", "licence", "offence", "pretence", "practis",
  -- -ise / -isation → -ize / -ization, and the -yse verbs
  "initialis", "normalis", "generalis", "specialis", "optimis", "customis",
  "serialis", "summaris", "utilis", "organis", "authoris", "prioritis",
  "alphabetis", "categoris", "sanitis", "visualis", "minimis", "maximis",
  "itemis", "randomis", "tokenis", "capitalis", "localis", "modularis",
  "standardis", "memois", "recognis", "analys", "paralys", "synthesis",
  "emphasis",
  -- a doubled consonant before a suffix, where US English keeps one
  "cancelled", "cancelling", "cancellable", "labelled", "labelling",
  "travelled", "travelling", "modelled", "modelling", "signalled",
  "signalling", "levelled", "levelling", "fuelled", "fuelling", "totalled",
  "totalling", "fulfil",
  -- -ogue → -og
  "catalogue", "dialogue", "analogue",
  -- no family, just British
  "grey", "artefact", "whilst", "amongst", "learnt", "ageing", "enquir",
  "acknowledgement", "judgement", "sceptic", "mould", "sulphur", "programme",
}

local ALLOWED = {
  "analysis", "analyses", "analyst", "analysts",
  "organism", "organisms", "organist",
  "specialist", "specialists", "generalist", "generalists",
  "optimism", "optimist", "optimists", "optimistic", "optimistically",
  "paralysis", "paralyses", "synthesis", "syntheses", "emphasis", "emphases",
  "fulfill", "fulfills", "fulfilled", "fulfilling", "fulfillment",
  "programmer", "programmers", "programmed",
}

-- The whole-word index ALLOWED is consulted through. `%a+` matches a maximal run of letters, so a
-- lookup against it IS the "delimit on non-letters" the section mandates — there is no way for an
-- allowance to match half of a longer word.
local ALLOWED_WORDS = {}
for _, word in ipairs(ALLOWED) do ALLOWED_WORDS[word] = true end

-- ONE ratified exemption, and the register row is what ratifies it. `localization-§5` names its
-- exclusions file by file rather than by pattern precisely so an exclusion list cannot quietly
-- grow, and this table is keyed the same way: a path, and the exact spelling that path is allowed
-- to carry. Nothing here is a pattern and nothing here is a directory.
--
-- `lib.ICONS`'s `minimise` key is a PATH FRAGMENT, not prose. `lib.Icon` builds
-- `base .. ICON_DIR .. "\\" .. name` from the key, and the file on disk is `minimise.tga`,
-- vendored into every consumer's `libs/LibKa0s/media/icons/`. Renaming the key alone points at a
-- texture that does not exist, and a texture that fails to load draws nothing and raises nothing —
-- the silent failure Media.lua:190-196 records. Changing it needs a second `.tga` or an alias map,
-- so until then the key stays and CLAUDE.md's `## Documented deviations` carries the row.
--
-- An entry that stops matching is itself a failure below. An exemption nobody can see expiring is
-- how a gate goes back to reading as coverage it does not provide.
local RATIFIED = {
  ["LibKa0s/Media.lua"] = { "minimise" },
}
local NO_EXEMPTIONS = {}

--- Replace every plain (non-pattern) occurrence of `needle` in `s` with a space. Returns the new
--- string and how many it replaced. Plain rather than `gsub` so an exemption is read as the literal
--- text it is, with no chance of a magic character in it quietly widening what it covers.
local function stripPlain(s, needle)
  local out, i, n = {}, 1, 0
  while true do
    local a, b = s:find(needle, i, true)
    if not a then break end
    out[#out + 1] = s:sub(i, a - 1)
    out[#out + 1] = " "
    i, n = b + 1, n + 1
  end
  out[#out + 1] = s:sub(i)
  return table.concat(out), n
end

test("prose: no British spelling in the shipped library or the shipped kit", function()
  local used = {}
  local hits = scan(function(line, path)
    -- ALLOWED first, as WHOLE WORDS: `%a+` matches a maximal run of letters, so a token that
    -- survives this lookup is a word and never a fragment of a longer one.
    local lower = line:lower():gsub("%a+", function(word)
      if ALLOWED_WORDS[word] then return " " end
      return word
    end)
    for _, word in ipairs(RATIFIED[path] or NO_EXEMPTIONS) do
      local stripped, n = stripPlain(lower, word)
      if n > 0 then
        lower, used[path .. " " .. word] = stripped, true
      end
    end
    for _, word in ipairs(BRITISH) do
      if lower:find(word, 1, true) then return word end
    end
    return nil
  end)
  for path, words in pairs(RATIFIED) do
    for _, word in ipairs(words) do
      if not used[path .. " " .. word] then
        hits[#hits + 1] = ("%s — ratified exemption `%s` matches nothing; drop it here and in "
          .. "CLAUDE.md's `## Documented deviations`"):format(path, word)
      end
    end
  end
  table.sort(hits)
  assertEqual(table.concat(hits, "\n          "), "",
    "localization-§5 mandates US English and anti-patterns #46 names comments explicitly; these "
    .. "spellings ship to every consumer and no consumer can fix them")
end)

-- ── section references (§N.M is a retired notation) ─────────────────────────────────────────
--
-- The standard is filename-scoped now — `library-stack-§4`, `options-ui-§8` — and a bare dotted
-- global number names a numbering that no longer exists, so a reader cannot resolve it to anything.
-- (This comment deliberately never writes a literal dotted number, the same device
-- documentation-§6 uses on itself: the check below is a plain regex over the shipped payload, and
-- spelling out the form it forbids would redden a file describing the rule.)
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
