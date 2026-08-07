-- tests/test_eol.lua — the working-tree line-ending gate over the automated-test bundles.
--
-- This exists because the defect it catches is invisible to everything else. `run-automated-tests.sh`
-- writes every bundle file with a plain shell redirect, and a redirect is a kernel write into the
-- working tree — it never passes through git's clean/smudge filters. In a repo pinned
-- `* text=auto eol=crlf`, which is this one and every client-bound repo in the collection, the
-- bundle therefore landed LF on disk while `.gitattributes` said CRLF, on every run, for nine
-- revisions of the kit.
--
-- NOTHING REPORTED IT. The blob is LF in the index either way — that is where LF belongs — so
-- `git status` is silent before the commit AND after it, and `git add --renormalize` does not help
-- because it rewrites the index and the index was never wrong. Only a byte-level audit ever saw it.
-- Kit revision 10 fixes the writer; this is the gate that keeps it fixed.
--
-- IT ASSERTS THE INVARIANT, NOT THE IMPLEMENTATION. It never looks at the runner's source. It asks
-- git what each path's terminator is declared to be and then reads the bytes, so it also catches a
-- file the runner does not write at all — most usefully `ANALYSIS.md`, which the
-- `/wow-addon:automated-tests` skill agent drops into the bundle directory after the runner has
-- exited and which is therefore outside the runner's own pass. A red here for that file is the gate
-- working, not the gate being wrong.
--
-- IT FAILS RATHER THAN PASSES WHEN IT CANNOT LOOK. No git, no `ls`, no answer from `check-attr` —
-- all of those are a failure. A gate that goes quiet when it is blind reports success, which is
-- worse than not existing. Same bargain tests/test_kitsync.lua and tests/test_prose.lua strike.

local T = _G.LK_TEST
local test, fail = T.test, T.fail

local BUNDLES = "docs/automated-tests"

--- Every path git tracks under `docs/automated-tests/`, as a sorted array.
---
--- `git ls-files` rather than a directory walk, for two reasons. Lua 5.1 has no directory API and
--- this repo does not depend on LuaFileSystem, so a recursive walk would be several shell-outs deep;
--- and the tracked set is the right set anyway — an untracked scratch file someone left in a bundle
--- folder has no declared terminator to violate.
local function trackedFiles()
  local paths = {}
  local p = io.popen('git ls-files -- "' .. BUNDLES .. '" 2>/dev/null')
  if not p then
    fail("eol gate: io.popen is unavailable, so this gate cannot run and must not be reported as "
      .. "passing", 2)
  end
  for line in p:lines() do
    local path = line:gsub("[\r\n]+$", "")
    if path ~= "" then paths[#paths + 1] = path end
  end
  p:close()
  if #paths == 0 then
    fail("eol gate: `git ls-files -- " .. BUNDLES .. "` returned nothing - either git is not "
      .. "available here or the bundles are untracked; this gate cannot run, and must not be "
      .. "reported as passing", 2)
  end
  table.sort(paths)
  return paths
end

--- The `eol` attribute git declares for `path`: "crlf", "lf", "unspecified", or nil if git cannot
--- answer at all. `git check-attr` prints `<path>: eol: <value>`.
local function declaredEol(path)
  local p = io.popen('git check-attr eol -- "' .. path .. '" 2>/dev/null')
  if not p then return nil end
  local line = p:read("*l")
  p:close()
  if not line then return nil end
  return line:match(":%s*eol:%s*(%S+)%s*$")
end

--- Read a whole file as bytes, or nil if it cannot be opened. Binary mode is load-bearing: text
--- mode on Windows would translate away the exact bytes this gate is here to inspect.
local function readBytes(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local data = f:read("*a")
  f:close()
  return data
end

--- Count the line terminators in `data` and how many of them are CRLF rather than bare LF.
local function terminators(data)
  local total, crlf = 0, 0
  for i = 1, #data do
    if data:byte(i) == 10 then
      total = total + 1
      if i > 1 and data:byte(i - 1) == 13 then crlf = crlf + 1 end
    end
  end
  return total, crlf
end

test("eol: every tracked bundle file carries the terminator .gitattributes declares for it", function()
  local hits = {}
  for _, path in ipairs(trackedFiles()) do
    local want = declaredEol(path)
    if not want then
      fail("eol gate: `git check-attr eol -- " .. path .. "` returned nothing; this gate cannot "
        .. "run, and must not be reported as passing", 2)
    end
    -- `unspecified` is not a violation - it is the repo declaring nothing, and there is then
    -- nothing to hold the bytes to. This repo pins crlf, so it should never be reached here; it is
    -- handled rather than assumed away so the gate stays honest if the pin ever moves.
    if want == "crlf" or want == "lf" then
      local data = readBytes(path)
      if data == nil then
        fail("eol gate: cannot read " .. path .. ", which git tracks", 2)
      end
      if data:find("\000", 1, true) == nil then
        local total, crlf = terminators(data)
        local wrong = (want == "crlf") and (total - crlf) or crlf
        if wrong > 0 then
          hits[#hits + 1] = string.format("%s - declared %s, but %d of %d terminators are %s",
            path, want, wrong, total, (want == "crlf") and "bare LF" or "CRLF")
        end
      end
    end
  end
  if #hits > 0 then
    -- Name every file rather than the first: these arrive a whole bundle at a time, and fixing them
    -- one red run at a time is the slowest possible way to find that out.
    fail("eol: " .. #hits .. " file(s) under " .. BUNDLES .. "/ disagree with `git check-attr eol`."
      .. " A shell redirect bypasses git's filters, so `git status` will never show you this and "
      .. "`git add --renormalize` will not fix it - the index is already right. Repair each with "
      .. "`rm <path> && git checkout -- <path>`, then confirm with `file <path>`:\n          "
      .. table.concat(hits, "\n          "), 2)
  end
end)
