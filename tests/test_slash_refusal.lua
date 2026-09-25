-- tests/test_slash_refusal.lua — CliSet and CliReset hearing the write seam's refusal (Slash minor 15).
--
-- A file of its own because tests/test_slash.lua sits in the 1000-1500 band (CLAUDE.md, "Files
-- over the 1500-line cap"): these cases peel on the seam they test, the host's `set` and
-- `applyDefault` answering back.
--
-- The seam they pin: LibKa0s-Schema-1.0's S.Set answers `false, err[, why]` with nothing stored
-- when a row's validate rejects a value, and S.ApplyDefault answers false for a row with no default.
-- Up to minor 14 CliSet discarded that answer and echoed the unchanged value, so a player's refused
-- `set` read as a success that did not take (review finding LibKa0s-R-03).

local T = _G.LK_TEST
local test, assertEqual = T.test, T.assertEqual

local F = dofile("tests/fixture_slash.lua")
local plain = F.plain

local PATH = "units.player.barWidth"

test("sl refusal: a set answering false, err, why prints INVALID and the reason, and no echo", function()
  -- red under: the discarded return — minor 14 echoed "units.player.barWidth = 200 px".
  local Sl, rec = F.new({
    set = function() return false, "Invalid value for " .. PATH, "must be 1-10" end,
  })
  Sl:CliSet(PATH .. " 300")
  assertEqual(#rec.chat, 2, "the refusal and its reason, nothing else: " .. table.concat(rec.chat, " | "))
  assertEqual(rec.chat[1], "Invalid value for " .. PATH)
  assertEqual(rec.chat[2], "  must be 1-10")
  assertEqual(rec.store[PATH], 200, "the stored value is untouched")
end)

test("sl refusal: an err that is not the INVALID line itself is printed indented, before why", function()
  -- Schema.Set's NO_ROOT and NOT_FOUND refusals carry their own wording and no `why`.
  local Sl, rec = F.new({
    set = function() return false, "Setting has nowhere to be stored yet: " .. PATH end,
  })
  Sl:CliSet(PATH .. " 300")
  assertEqual(#rec.chat, 2, table.concat(rec.chat, " | "))
  assertEqual(rec.chat[1], "Invalid value for " .. PATH)
  assertEqual(rec.chat[2], "  Setting has nowhere to be stored yet: " .. PATH)
end)

test("sl refusal: a refusal with no err and no why prints the INVALID line alone", function()
  local Sl, rec = F.new({ set = function() return false end })
  Sl:CliSet(PATH .. " 300")
  assertEqual(#rec.chat, 1, table.concat(rec.chat, " | "))
  assertEqual(rec.chat[1], "Invalid value for " .. PATH)
end)

test("sl refusal: a set answering true echoes the stored value", function()
  local store = {}
  local Sl, rec = F.new({
    set = function(path, v) store[path] = v; return true end,
    get = function(path) return store[path] end,
  })
  Sl:CliSet(PATH .. " 300")
  assertEqual(#rec.chat, 1)
  assertEqual(plain(rec.chat[1]), PATH .. " = 300 px")
end)

test("sl refusal: a set answering nothing still echoes, as at minor 14", function()
  local Sl, rec = F.new()   -- the fixture's set returns nothing
  Sl:CliSet(PATH .. " 300")
  assertEqual(#rec.chat, 1)
  assertEqual(plain(rec.chat[1]), PATH .. " = 300 px")
  assertEqual(rec.store[PATH], 300)
end)

test("sl refusal: CliReset prints NO_DEFAULT when applyDefault answers exactly false", function()
  -- red under: the ignored return — minor 14 echoed the unchanged value as though it were reset.
  local Sl, rec = F.new({ applyDefault = function() return false end })
  Sl:CliReset(PATH)
  assertEqual(#rec.chat, 1, table.concat(rec.chat, " | "))
  assertEqual(rec.chat[1], PATH .. " has no default to restore")
  assertEqual(T.slash.STRINGS.NO_DEFAULT, "%s has no default to restore")
end)

test("sl refusal: CliReset echoes when applyDefault answers nil or true", function()
  for _, answer in ipairs({ "nil", "true" }) do
    local store
    local Sl, rec = F.new({ applyDefault = function(row)
      store[row.path] = row.default
      if answer == "true" then return true end
    end })
    store = rec.store
    rec.store[PATH] = 300
    Sl:CliReset(PATH)
    assertEqual(#rec.chat, 1, answer)
    assertEqual(plain(rec.chat[1]), PATH .. " = 200 px", answer)
  end
end)
