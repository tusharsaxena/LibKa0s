-- tests/test_layout_cap.lua — the 1500-line cap gate (layout-§1).
--
-- WHAT IT PROVES. That no authored `.lua` file this repository tracks sits over layout-§1's
-- 1500-line cap without a disposition, and that no disposition outlives the breach it was written
-- for. It reads the tracked set from git and the census table from CLAUDE.md, and compares the two
-- in BOTH directions.
--
-- WHY IT EXISTS, AND WHY IN THIS REPO. The 2026-09-07 audit graded both of this library's breaches
-- Low and left them, explicitly because nothing upstream said whether the cap reached a library
-- repo at all: `library-stack-§7` promised three applicability lists and shipped two, and layout
-- fell through the gap along with twelve other sections. Four repositories answered that same
-- silence four different ways in one audit cycle. The standard was then revised (M1-STD-08,
-- v2.39.0) to say what the cap binds — every authored file the repo tracks, `tests/` included, a
-- library's own payload folder included, with vendored code the only carve-out that reaches here —
-- and to name the three terminal states a file over the cap may be in: peeled, an open issue naming
-- the seam, or a ratified register row with a re-check trigger. What it does not allow is silence:
-- "the count sitting in a bundle manifest that no document reads". This repo had exactly that —
-- `docs/automated-tests/` manifests carrying an `overCapFiles` count that no document read and the
-- RESULTS.md watch list denied.
--
-- A census written once and never re-checked becomes that manifest in turn. The numbers move on
-- their own: `LibKa0s/OptionsWidgets.lua` was 1838 lines at the review, 1989 on 2026-09-08 and
-- 3645 on 2026-09-14, and the suite beside it went 2287 -> 2398 -> 3828, all while nobody was
-- watching. This is the thing that watches.
--
-- WHAT IT DOES NOT ASSERT: the line figures printed in the census. They are dated measurements, and
-- pinning them would redden the suite on every ordinary edit to a large file — a gate with a
-- standing reason to be switched off stops being run. Membership is the invariant; the numbers are
-- prose.
--
-- IT FAILS RATHER THAN PASSES WHEN IT CANNOT LOOK. No `io.popen`, no git, no CLAUDE.md, no census
-- heading — every one of those is a failure, not a skip, the same bargain tests/test_prose.lua and
-- tests/_kit/test_eol.lua strike. A gate that goes quiet when it is blind reports success, which is
-- worse than not existing.

local T = _G.LK_TEST
local test, fail = T.test, T.fail

local CAP = 1500
local REGISTER = "CLAUDE.md"
local CENSUS_HEADING = "## Files over the 1500-line cap"

--- Split a NUL-delimited blob into an array.
---
--- `git ls-files -z` because a path may contain anything but NUL, and the line-oriented form quotes
--- such a path instead of printing it — a quoted path would not match a file on disk, and this gate
--- would then report a breach that is really a parse failure.
local function splitNul(blob)
  local out, start = {}, 1
  while true do
    local i = blob:find("\0", start, true)
    if not i then break end
    if i > start then out[#out + 1] = blob:sub(start, i - 1) end
    start = i + 1
  end
  return out
end

--- Every authored `.lua` path git tracks, in git's order.
---
--- The tracked set rather than a directory walk: Lua 5.1 has no directory API, and an untracked
--- scratch file is not something the cap has an opinion about. `libs/` does not exist here and
--- `tests/_kit/` does — it is this repo's own vendored copy of `testkit/`, consumed on the same
--- terms as any addon consumes it — so `tests/_kit/` is dropped and `testkit/` is NOT: the kit is
--- authored here, and a file this repo writes is a file this repo can peel. `libs/` is dropped
--- anyway, so that the exclusion still reads correctly if the library ever vendors something.
--- The second carve-out, generated non-shipping data, has no instance here; if one ever arrives it
--- needs a rule in this function, and a red is the prompt to write it.
local function trackedAuthoredLua()
  if not io.popen then
    fail("layout cap gate: io.popen is unavailable, so the tracked set cannot be read; this gate "
      .. "cannot run and must not be reported as passing", 2)
  end
  local pipe = io.popen("git ls-files -z -- '*.lua'")
  if not pipe then fail("layout cap gate: could not start `git ls-files`", 2) end
  local blob = pipe:read("*a") or ""
  pipe:close()

  local paths = {}
  for _, path in ipairs(splitNul(blob)) do
    if not (path:find("^libs/") or path:find("^tests/_kit/")) then
      paths[#paths + 1] = path
    end
  end
  if #paths == 0 then
    fail("layout cap gate: `git ls-files` reported no tracked .lua files, which cannot be true "
      .. "here", 2)
  end
  return paths
end

--- Lines in `path`, counted as `wc -l` counts them, plus a final unterminated line if there is one.
--- Returns nil when the file cannot be opened, which the callers report rather than skip.
local function countLines(path)
  local fh = io.open(path, "r")
  if not fh then return nil end
  local body = fh:read("*a") or ""
  fh:close()
  if body == "" then return 0 end
  local n = 0
  for _ in body:gmatch("\n") do n = n + 1 end
  if body:sub(-1) ~= "\n" then n = n + 1 end
  return n
end

--- The census table under CENSUS_HEADING in CLAUDE.md, as { path, disposition } rows.
---
--- CLAUDE.md rather than `docs/ARCHITECTURE.md`: `documentation-§3`'s `docs/` trio does not bind a
--- library repo, so there is no ARCHITECTURE.md here, and CLAUDE.md is where this repo already
--- keeps its registers (see its own `## Documented deviations` note).
---
--- A row is a table line whose first cell is a single backticked path; the heading row and the
--- `|---|` separator carry no backticks and fall out on their own. Reading stops at the next
--- heading of any level, so a later section growing a table of its own cannot leak into this one.
local function censusRows()
  local fh = io.open(REGISTER, "r")
  if not fh then fail("layout cap gate: " .. REGISTER .. " could not be opened", 2) end
  local body = fh:read("*a") or ""
  fh:close()

  local text = body:gsub("\r\n", "\n")
  local rows, inside, found = {}, false, false
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    if line == CENSUS_HEADING then
      inside, found = true, true
    elseif inside and line:sub(1, 1) == "#" then
      break
    elseif inside then
      local path, _, disposition = line:match("^|%s*`([^`]+)`%s*|%s*(.-)%s*|%s*(.-)%s*|%s*$")
      if path then
        rows[#rows + 1] = { path = path, disposition = disposition }
      end
    end
  end

  if not found then
    fail("layout cap gate: " .. REGISTER .. " carries no '" .. CENSUS_HEADING .. "' section; the "
      .. "cap census is where every breach is remarked on and it must not be removed", 2)
  end
  return rows
end

-- ── the two directions ─────────────────────────────────────────────────────────────────────────

test("layoutcap: every authored file over 1500 lines is named in the CLAUDE.md census", function()
  local listed = {}
  for _, row in ipairs(censusRows()) do listed[row.path] = true end

  local unremarked = {}
  for _, path in ipairs(trackedAuthoredLua()) do
    local n = countLines(path)
    if n == nil then
      fail("layout cap gate: git tracks " .. path .. " but it cannot be opened", 2)
    elseif n > CAP and not listed[path] then
      unremarked[#unremarked + 1] = path .. " (" .. n .. ")"
    end
  end

  if #unremarked > 0 then
    fail("over layout-§1's " .. CAP .. "-line cap and remarked on nowhere: "
      .. table.concat(unremarked, ", ") .. " — peel it, open an issue naming the seam it would "
      .. "peel on, or ratify a register row with a re-check trigger; then add the row to "
      .. REGISTER .. "'s census", 2)
  end
end)

test("layoutcap: no census row outlives the breach it records", function()
  local spent = {}
  for _, row in ipairs(censusRows()) do
    local n = countLines(row.path)
    if n == nil then
      spent[#spent + 1] = row.path .. " (no such file)"
    elseif n <= CAP then
      spent[#spent + 1] = row.path .. " (" .. n .. ", under the cap)"
    end
  end

  if #spent > 0 then
    fail(REGISTER .. "'s cap census carries rows for files that no longer breach: "
      .. table.concat(spent, ", ") .. " — delete the row, and close the issue or retire the "
      .. "register row that backs it. The census must not become a graveyard", 2)
  end
end)

test("layoutcap: every census row carries a disposition that can be followed", function()
  local rows = censusRows()
  if #rows == 0 then
    fail("the census table under '" .. CENSUS_HEADING .. "' has no rows; if the repository really "
      .. "has no breach left, delete the section rather than leaving an empty table", 2)
  end

  local unfollowable = {}
  for _, row in ipairs(rows) do
    -- layout-§1's second and third terminal states, and nothing else: an issue number to open, or
    -- the register row above to read. A disposition cell that names neither is a note, and a note
    -- is what this whole section exists to stop being enough.
    if not (row.disposition:find("#%d") or row.disposition:find("[Rr]egister row")) then
      unfollowable[#unfollowable + 1] = row.path
    end
  end

  if #unfollowable > 0 then
    fail("cap census rows whose disposition names neither an issue nor the register row: "
      .. table.concat(unfollowable, ", "), 2)
  end
end)
