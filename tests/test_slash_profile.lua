-- tests/test_slash_profile.lua — the profile verb's shared half (Slash minor 17): `Sl:CliProfile`,
-- `Sl:ProfileSwitch`, `lib.ProfileNames` and the descriptor's `profiles` field.
--
-- A file of its own on the seam it tests, as tests/test_slash_refusal.lua is: the host's profile
-- store answering back. The store here is a duck-typed fake with AceDB-3.0's three methods and
-- nothing else, because the library must not require AceDB (slash-commands.md:34) and a case that
-- passed only against the real AceDB would not show that.
--
-- What the verb promises, and what these cases pin: `profile <name>` switches to a profile that
-- EXISTS (exact case, one pair of surrounding quotes stripped, inner spaces kept); a name that does
-- not exist is refused with the list and never created; bare `profile` lists them, current marked.

local T = _G.LK_TEST
local slash, mocks = T.slash, T.mocks
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local F = dofile("tests/fixture_slash.lua")
local plain = F.plain

--- A profile store with AceDB-3.0's shape: `GetProfiles(tbl) -> tbl, n`, `GetCurrentProfile()`,
--- `SetProfile(name)`. `SetProfile` creates a missing profile exactly as AceDB's does, so a case
--- asserting "never created" is asserting the library never called it.
local function newStore(names, current)
  local s = { profiles = {}, current = current, sets = {} }
  for _, n in ipairs(names) do s.profiles[n] = true end
  function s:GetProfiles(tbl)
    tbl = tbl or {}
    for k in pairs(tbl) do tbl[k] = nil end
    local i = 0
    for n in pairs(self.profiles) do
      i = i + 1
      tbl[i] = n
    end
    return tbl, i
  end
  function s:GetCurrentProfile() return self.current end
  function s:SetProfile(name)
    self.sets[#self.sets + 1] = name
    self.profiles[name] = true
    self.current = name
  end
  return s
end

-- `alpha` is here for the ordering cases: case-insensitively it sorts first, in byte order it sorts
-- after every capitalized name, so a plain `table.sort` would move it and redden the list pins.
local NAMES = { "Default", "raid", "My Main", "Alt", "alpha" }

local function host(store, overrides)
  local o = { profiles = function() return store end }
  for k, v in pairs(overrides or {}) do o[k] = v end
  return F.new(o)
end

local function plainChat(rec)
  local out = {}
  for i, line in ipairs(rec.chat) do out[i] = plain(line) end
  return out
end

-- The list as it prints under Default being current: case-insensitive order, two-space rows.
local LIST = {
  "Profiles",
  "  alpha",
  "  Alt",
  "  Default (current)",
  "  My Main",
  "  raid",
  "/th profile <name> switches profile",
}

local function assertLines(got, want, label)
  assertEqual(#got, #want, (label or "") .. " line count: " .. table.concat(got, " | "))
  for i = 1, #want do assertEqual(got[i], want[i], (label or "") .. " line " .. i) end
end

-- ── the strings ────────────────────────────────────────────────────────────────────────────

test("sl profile: every string is a lib.STRINGS key, worded as the spec gives it", function()
  local S = slash.STRINGS
  assertEqual(S.PROFILE_LIST_HEADER, "Profiles")
  assertEqual(S.PROFILE_CURRENT_MARK, "(current)")
  assertEqual(S.PROFILE_HINT, "%s profile <name> switches profile")
  assertEqual(S.PROFILE_ALREADY, "Already on profile '%s'.")
  assertEqual(S.PROFILE_COMBAT, "Can't switch profiles in combat.")
  assertEqual(S.PROFILE_SWITCHED, "Switched to profile '%s'.")
  assertEqual(S.PROFILE_UNKNOWN, "No profile named '%s'.")
  assertEqual(S.PROFILE_DID_YOU_MEAN, "Did you mean '%s'?")
  assertEqual(type(S.PROFILE_UNAVAILABLE), "string")
end)

test("sl profile: `profile` is neither live while disabled nor added to lib.LIVE_VERBS", function()
  -- A host verb, not a reserved one: each host widens its own liveVerbs (Slash.lua's LIVE_VERBS
  -- comment), which keeps every consumer's hand-copied thirteen-verb pin green.
  assertEqual(#slash.LIVE_VERBS, 13)
  for _, verb in ipairs(slash.LIVE_VERBS) do assertTrue(verb ~= "profile", "profile is not live") end
end)

-- ── the list ───────────────────────────────────────────────────────────────────────────────

test("sl profile: bare `profile` lists every profile sorted case-insensitively, current marked", function()
  local store = newStore(NAMES, "Default")
  local Sl, rec = host(store)
  Sl:CliProfile("")
  assertLines(plainChat(rec), LIST)
  assertEqual(#store.sets, 0, "listing never switches")
end)

test("sl profile: whitespace alone, and an empty pair of quotes, list rather than switch", function()
  for _, rest in ipairs({ "   ", '""', "' '" }) do
    local store = newStore(NAMES, "Default")
    local Sl, rec = host(store)
    Sl:CliProfile(rest)
    assertLines(plainChat(rec), LIST, tostring(rest))
    assertEqual(#store.sets, 0)
  end
end)

test("sl profile: the list header is colored like the settings list's, and carries no colon", function()
  local Sl, rec = host(newStore(NAMES, "Default"))
  Sl:CliProfile("")
  assertEqual(rec.chat[1], "|cff33ff99Profiles|r")
end)

test("sl profile: a store that omits the current profile from GetProfiles still lists it", function()
  -- AceDB's GetProfiles appends the current profile when it has no stored table yet; a store that
  -- does not is still honest about which profile is live.
  local store = newStore({ "Alt" }, "Fresh")
  local Sl, rec = host(store)
  Sl:CliProfile("")
  assertLines(plainChat(rec), { "Profiles", "  Alt", "  Fresh (current)",
    "/th profile <name> switches profile" })
end)

-- ── switching ──────────────────────────────────────────────────────────────────────────────

test("sl profile: an existing name switches, once, and says so", function()
  local store = newStore(NAMES, "Default")
  local Sl, rec = host(store)
  Sl:CliProfile("Alt")
  assertEqual(#store.sets, 1)
  assertEqual(store.sets[1], "Alt")
  assertLines(plainChat(rec), { "Switched to profile 'Alt'." })
end)

test("sl profile: surrounding double quotes are stripped, and the name inside is trimmed", function()
  local store = newStore(NAMES, "Default")
  local Sl, rec = host(store)
  Sl:CliProfile('  " My Main "  ')
  assertEqual(store.sets[1], "My Main")
  assertLines(plainChat(rec), { "Switched to profile 'My Main'." })
end)

test("sl profile: surrounding single quotes are stripped too", function()
  local store = newStore(NAMES, "Default")
  local Sl, rec = host(store)
  Sl:CliProfile("'My Main'")
  assertEqual(store.sets[1], "My Main")
  assertEqual(#rec.chat, 1)
end)

test("sl profile: inner spaces are kept, so an unquoted name with a space still switches", function()
  local store = newStore(NAMES, "Default")
  local Sl = host(store)
  Sl:CliProfile("My Main")
  assertEqual(store.sets[1], "My Main")
end)

test("sl profile: only ONE matching pair is stripped; a lone or mismatched quote is part of the name", function()
  for _, rest in ipairs({ '"Alt', "Alt'", "\"Alt'", "''Alt''" }) do
    local store = newStore(NAMES, "Default")
    local Sl, rec = host(store)
    Sl:CliProfile(rest)
    assertEqual(#store.sets, 0, rest .. " switched")
    assertTrue(plain(rec.chat[1]):find("No profile named", 1, true) == 1, rest .. ": " .. rec.chat[1])
  end
end)

test("sl profile: case is kept — `alt` is not `Alt`, and is refused with a did-you-mean", function()
  local store = newStore(NAMES, "Default")
  local Sl, rec = host(store)
  Sl:CliProfile("alt")
  assertEqual(#store.sets, 0, "a case-folded match must not switch")
  local want = { "No profile named 'alt'.", "Did you mean 'Alt'?" }
  for _, line in ipairs(LIST) do want[#want + 1] = line end
  assertLines(plainChat(rec), want)
end)

test("sl profile: the current profile answers Already, and SetProfile is not called", function()
  local store = newStore(NAMES, "Default")
  local Sl, rec = host(store)
  Sl:CliProfile('"Default"')
  assertEqual(#store.sets, 0)
  assertLines(plainChat(rec), { "Already on profile 'Default'." })
end)

-- ── refusing an unknown name ───────────────────────────────────────────────────────────────

test("sl profile: an unknown name is refused with the list, and nothing is created", function()
  local store = newStore(NAMES, "Default")
  local Sl, rec = host(store)
  Sl:CliProfile("Nope")
  assertEqual(#store.sets, 0, "SetProfile would have created it")
  assertEqual(store.profiles.Nope, nil)
  assertEqual(store.current, "Default")
  local want = { "No profile named 'Nope'." }
  for _, line in ipairs(LIST) do want[#want + 1] = line end
  assertLines(plainChat(rec), want)
end)

test("sl profile: did-you-mean only when exactly one stored name matches case-insensitively", function()
  local store = newStore({ "Main", "MAIN", "Default" }, "Default")
  local Sl, rec = host(store)
  Sl:CliProfile("main")
  assertEqual(#store.sets, 0)
  local p = plainChat(rec)
  assertEqual(p[1], "No profile named 'main'.")
  assertEqual(p[2], "Profiles", "two candidates: no guess, straight to the list")
end)

-- ── combat ─────────────────────────────────────────────────────────────────────────────────

test("sl profile: in combat an existing name is refused and SetProfile is not called", function()
  local saved = mocks.InCombatLockdown
  mocks.InCombatLockdown = function() return true end
  local store = newStore(NAMES, "Default")
  local Sl, rec = host(store)
  local ok, err = pcall(Sl.CliProfile, Sl, "Alt")
  mocks.InCombatLockdown = saved
  assertTrue(ok, tostring(err))
  assertEqual(#store.sets, 0)
  assertLines(plainChat(rec), { "Can't switch profiles in combat." })
end)

test("sl profile: combat does not stop the list, Already, or an unknown-name refusal", function()
  local saved = mocks.InCombatLockdown
  mocks.InCombatLockdown = function() return true end
  local store = newStore(NAMES, "Default")
  local Sl, rec = host(store)
  local ok, err = pcall(function()
    Sl:CliProfile("")
    Sl:CliProfile("Default")
    Sl:CliProfile("Nope")
  end)
  mocks.InCombatLockdown = saved
  assertTrue(ok, tostring(err))
  local p = plainChat(rec)
  assertEqual(p[1], "Profiles")
  assertEqual(p[#LIST + 1], "Already on profile 'Default'.")
  assertEqual(p[#LIST + 2], "No profile named 'Nope'.")
end)

test("sl profile: a client with no InCombatLockdown switches", function()
  local saved = mocks.InCombatLockdown
  mocks.InCombatLockdown = nil
  local store = newStore(NAMES, "Default")
  local Sl = host(store)
  local ok, err = pcall(Sl.CliProfile, Sl, "Alt")
  mocks.InCombatLockdown = saved
  assertTrue(ok, tostring(err))
  assertEqual(store.sets[1], "Alt")
end)

-- ── no store ───────────────────────────────────────────────────────────────────────────────

test("sl profile: a host with no `profiles` field prints the unavailable line and nothing else", function()
  local Sl, rec = F.new()
  Sl:CliProfile("Alt")
  Sl:CliProfile("")
  assertEqual(#rec.chat, 2, table.concat(rec.chat, " | "))
  assertEqual(rec.chat[1], slash.STRINGS.PROFILE_UNAVAILABLE)
  assertEqual(rec.chat[2], slash.STRINGS.PROFILE_UNAVAILABLE)
end)

test("sl profile: a `profiles` function answering nil is the same as no field", function()
  local Sl, rec = F.new({ profiles = function() return nil end })
  Sl:CliProfile("Alt")
  assertEqual(#rec.chat, 1)
  assertEqual(rec.chat[1], slash.STRINGS.PROFILE_UNAVAILABLE)
end)

test("sl profile: a store missing any of the three methods is unavailable, and never half-called", function()
  for _, drop in ipairs({ "GetProfiles", "GetCurrentProfile", "SetProfile" }) do
    local store = newStore(NAMES, "Default")
    store[drop] = nil
    local Sl, rec = host(store)
    local ok, err = pcall(Sl.CliProfile, Sl, "Alt")
    assertTrue(ok, drop .. ": " .. tostring(err))
    assertEqual(#store.sets, 0, drop)
    assertEqual(#rec.chat, 1, drop)
    assertEqual(rec.chat[1], slash.STRINGS.PROFILE_UNAVAILABLE, drop)
  end
end)

test("sl profile: the store is asked for at call time, never cached at New", function()
  -- A host's db is created at ADDON_LOADED, after its slash file has built the dispatcher.
  local store
  local Sl, rec = F.new({ profiles = function() return store end })
  Sl:CliProfile("Alt")
  assertEqual(rec.chat[1], slash.STRINGS.PROFILE_UNAVAILABLE)
  store = newStore(NAMES, "Default")
  Sl:CliProfile("Alt")
  assertEqual(store.sets[1], "Alt")
end)

-- ── the reusable halves ────────────────────────────────────────────────────────────────────

test("sl profile: lib.ProfileNames answers the sorted names and the current one", function()
  local names, current = slash.ProfileNames(newStore(NAMES, "raid"))
  assertEqual(table.concat(names, ","), "alpha,Alt,Default,My Main,raid")
  assertEqual(current, "raid")
end)

test("sl profile: lib.ProfileNames breaks a case-only tie deterministically", function()
  local names = slash.ProfileNames(newStore({ "main", "Main", "MAIN" }, "main"))
  assertEqual(table.concat(names, ","), "MAIN,Main,main")
end)

test("sl profile: lib.ProfileNames on no store, or a store without methods, answers an empty list", function()
  for _, store in ipairs({ false, 42, {} }) do
    local names, current = slash.ProfileNames(store or nil)
    assertEqual(type(names), "table")
    assertEqual(#names, 0)
    assertEqual(current, nil)
  end
end)

test("sl profile: ProfileSwitch takes an already-parsed name, keeping its quotes, and answers true on a switch", function()
  local store = newStore({ "Default", '"Q"' }, "Default")
  local Sl, rec = host(store)
  assertEqual(Sl:ProfileSwitch('"Q"'), true, "a parsed name is used as given")
  assertEqual(store.sets[1], '"Q"')
  assertEqual(Sl:ProfileSwitch('"Q"'), false, "already current")
  assertEqual(Sl:ProfileSwitch("Nope"), false, "unknown")
  assertEqual(#store.sets, 1)
  local p = plainChat(rec)
  assertEqual(p[1], "Switched to profile '\"Q\"'.")
  assertEqual(p[2], "Already on profile '\"Q\"'.")
  assertEqual(p[3], "No profile named 'Nope'.")
end)

test("sl profile: ProfileSwitch with no store prints the unavailable line and answers false", function()
  local Sl, rec = F.new()
  assertEqual(Sl:ProfileSwitch("Alt"), false)
  assertEqual(rec.chat[1], slash.STRINGS.PROFILE_UNAVAILABLE)
end)

-- ── the host's surface ─────────────────────────────────────────────────────────────────────

test("sl profile: through OnSlash the name keeps its case and its quotes are stripped", function()
  local store = newStore(NAMES, "Default")
  local Sl, rec = host(store)
  rec.commands[#rec.commands + 1] = { "profile", "List profiles, or switch to one",
    function(rest) Sl:CliProfile(rest) end }
  Sl:OnSlash('PROFILE "My Main"')
  assertEqual(store.sets[1], "My Main")
end)

test("sl profile: the descriptor's L reaches every profile string", function()
  local store = newStore({ "Default", "Alt" }, "Default")
  local L = {
    PROFILE_LIST_HEADER = "Profile", PROFILE_CURRENT_MARK = "(aktuell)",
    PROFILE_HINT = "%s profile <Name> wechselt", PROFILE_SWITCHED = "Profil '%s' aktiv",
    PROFILE_UNKNOWN = "Kein Profil '%s'", PROFILE_DID_YOU_MEAN = "Meintest du '%s'",
    PROFILE_ALREADY = "Schon '%s'", PROFILE_UNAVAILABLE = "Keine Profile",
  }
  local Sl, rec = host(store, { L = L })
  Sl:CliProfile("alt")
  Sl:CliProfile("Default")
  Sl:CliProfile("Alt")
  local p = plainChat(rec)
  assertLines(p, { "Kein Profil 'alt'", "Meintest du 'Alt'", "Profile", "  Alt",
    "  Default (aktuell)", "/th profile <Name> wechselt", "Schon 'Default'", "Profil 'Alt' aktiv" })
  local Sl2, rec2 = F.new({ L = L })
  Sl2:CliProfile("")
  assertEqual(rec2.chat[1], "Keine Profile")
end)

test("sl profile: no line any path prints ends in a colon", function()
  -- slash-commands-§4 names profile sub-headers in its no-trailing-colon rule.
  local saved = mocks.InCombatLockdown
  local all = {}
  local function collect(rec) for _, line in ipairs(rec.chat) do all[#all + 1] = plain(line) end end
  local store = newStore(NAMES, "Default")
  local Sl, rec = host(store)
  Sl:CliProfile("")
  Sl:CliProfile("alt")
  Sl:CliProfile("Default")
  Sl:CliProfile("Alt")
  mocks.InCombatLockdown = function() return true end
  Sl:CliProfile("raid")
  mocks.InCombatLockdown = saved
  collect(rec)
  local _, rec2 = F.new()
  rec2.instance:CliProfile("x")
  collect(rec2)
  assertTrue(#all >= 12, "every path was reached: " .. #all)
  for _, line in ipairs(all) do
    assertTrue(not line:match(":%s*$"), "trailing colon: " .. line)
  end
end)
