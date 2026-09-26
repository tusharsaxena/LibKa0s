-- tests/test_slash_disabled.lua — LibKa0s-Slash-1.0's disabled gate (minor 12): the refusal line,
-- the live verbs, and what a disabled host's dispatcher does NOT do.
--
-- A file of its own because tests/test_slash.lua was 1339 lines, in `layout-§1`'s 1000-1500 band.
-- The cases moved unchanged, in their original order, with the host they share, in the 2026-09-26
-- automated-tests sweep. The write seam's refusal is tests/test_slash_refusal.lua.

local T = _G.LK_TEST
local slash = T.slash
local test, assertEqual = T.test, T.assertEqual

local F = dofile("tests/fixture_slash.lua")
local plain = F.plain

-- ── the disabled gate (minor 12) ───────────────────────────────────────────────────────────
--
-- Disabled means the addon is NOT RUNNING, and this is the slash half of saying so. What is under
-- test here is almost entirely what does NOT happen: no `unknown command`, no help index, no
-- second line, no host handler reached. A gate asserted only by "the refusal line appeared" would
-- pass just as well over a dispatcher that printed the line AND ran the verb, which is the draw
-- gate wearing a refusal.

--- A host whose enable path starts FALSE, carrying `enable` and `disable` plus one FEATURE verb
--- (`lock`) to prove the gate closes on that and only on that. `rec.enabled.value` is the stored path, and the
--- `enable` / `disable` verbs write it exactly as a schema write would — the test drives the route
--- the checkbox and the verb take rather than calling a teardown directly.
local function disabledHost(overrides)
  local enabled = { value = false }
  local o = {
    isEnabled = function() return enabled.value end,
    brandName = "Ka0s Test Host",
  }
  for k, v in pairs(overrides or {}) do o[k] = v end
  local Sl, rec = F.new(o)
  rec.enabled = enabled
  -- Pushed after New because the dispatcher reads d.commands at dispatch time, and rec.commands IS
  -- d.commands — the same table, not a copy.
  rec.commands[#rec.commands + 1] = { "enable", "Turn the addon on", function()
    enabled.value = true
    rec.chat[#rec.chat + 1] = slash.FormatKV("enabled", "true")
  end }
  rec.commands[#rec.commands + 1] = { "disable", "Turn the addon off", function()
    enabled.value = false
    rec.chat[#rec.chat + 1] = slash.FormatKV("enabled", "false")
  end }
  rec.commands[#rec.commands + 1] = { "lock", "Lock the frames", function()
    rec.chat[#rec.chat + 1] = "locked"
  end }
  return Sl, rec
end

local REFUSAL = slash.DISABLED_LINE_FORMAT:format("Ka0s Test Host", "/th enable")

test("sl: the refusal line's shape is the collection's, down to the color and the dash", function()
  local Sl = disabledHost()
  local line = Sl:DisabledLine()
  assertEqual(line, REFUSAL, "built from the exported format, not re-spelled")
  assertEqual(plain(line), "Ka0s Test Host is disabled \226\128\148 enable it with /th enable",
    "rendered with the color codes stripped")
  -- Each clause of the shape, asserted separately, because a single equality above would go red
  -- for any of them and say only "the string differs".
  assertEqual(line:find("|cFFFFFF00/th enable|r", 1, true) ~= nil, true,
    "gold FFFFFF00 on the command, carrying its leading slash")
  assertEqual(line:find(" \226\128\148 ", 1, true) ~= nil, true,
    "an em dash with a single space either side, matching the row formatter")
  assertEqual(line:sub(-1), "r", "no trailing colon and no trailing period")
  assertEqual(select(2, line:gsub("\n", "")), 0, "exactly one line")
end)

test("sl: an absent isEnabled leaves the dispatcher behaving exactly as it did at minor 11", function()
  -- The whole migration story. An un-adopted host passes no isEnabled, and nothing about its
  -- surface moves — including the two paths the gate would otherwise take over, the bare command
  -- and the unknown verb.
  local Sl, rec = F.new()
  Sl:OnSlash("")
  assertEqual(rec.chat[1], "opened", "bare /<slash> still runs config")
  rec.chat = {}
  Sl:OnSlash("nosuchverb")
  assertEqual(plain(rec.chat[1]), "unknown command 'nosuchverb'")
  assertEqual(#rec.chat > 1, true, "and the index still follows it")
end)

test("sl: isEnabled without brandName is refused at New, not rendered as 'nil is disabled'", function()
  local err = T.assertError(function()
    slash:New{ slash = "/th", commands = {}, isEnabled = function() return false end }
  end, "a gated host with no brand name must be refused")
  assertEqual(tostring(err):find("brandName", 1, true) ~= nil, true, "named in the library's words")
end)

test("sl: a FEATURE verb answers exactly one refusal line and reaches no write seam", function()
  -- red under: drop the `if isDown and not liveVerbs[cmd]` gate from OnSlash
  --
  -- `lock` is the host's own feature verb, and slash-commands-§2's SHOULD is that a disabled addon
  -- refuses one rather than acting on it: the player asked for something the addon is standing down
  -- from doing, and a silent no-op leaves them with no clue why nothing happened. One line is the
  -- whole courtesy — no partial work, no side effect, no second line, and never the help index.
  local Sl, rec = disabledHost()
  Sl:OnSlash("lock")
  assertEqual(#rec.chat, 1, "exactly one line")
  assertEqual(rec.chat[1], REFUSAL, "and THE line")
  assertEqual(rec.refreshed, 0, "and it reached no write seam")
end)

test("sl: the reserved verbs and the whole schema CLI answer NORMALLY while disabled", function()
  -- red under: narrow lib.LIVE_VERBS back to { "enable", "help", "disable" } (minor 12)
  --
  -- Restored at minor 13 under the standard's v2.57.0. None of these is a feature verb, so the
  -- refusal is never turned on them: a player must be able to READ AND REPAIR SETTINGS and to
  -- REACH THE PANEL while the addon is off, which is precisely when they are most likely to need
  -- to — and `enable` above all, or the switch only goes one way.
  local Sl, rec = disabledHost()

  Sl:OnSlash("config")
  assertEqual(rec.chat[1], "opened", "config opens the panel")

  rec.chat = {}
  Sl:OnSlash("version")
  assertEqual(plain(rec.chat[1]), "v1.2.3", "version prints")

  rec.chat = {}
  Sl:OnSlash("list")
  T.assertTrue(#rec.chat > 1, "list prints its header and its rows")

  rec.chat = {}
  Sl:OnSlash("get showOnlyInCombat")
  assertEqual(rec.chat[1], slash.FormatKV("showOnlyInCombat", "false"), "get reads the stored value")

  rec.chat = {}
  Sl:OnSlash("set showOnlyInCombat true")
  assertEqual(rec.store["showOnlyInCombat"], true, "set repairs a setting on an addon that is off")
  assertEqual(rec.chat[1], slash.FormatKV("showOnlyInCombat", "true"), "and echoes what was stored")

  rec.chat = {}
  Sl:OnSlash("reset showOnlyInCombat")
  assertEqual(rec.store["showOnlyInCombat"], false, "reset puts it back")

  for _, line in ipairs(rec.chat) do
    assertEqual(line ~= REFUSAL, true, "and not one of them printed the refusal line")
  end
end)

test("sl: the bare command opens the panel, and a TYPO gets the unknown-command line", function()
  -- red under: refuse the bare-command branch while disabled (what minor 12 did), or put the gate
  -- back BEFORE findCommand, which answered a misspelling with "the addon is disabled".
  --
  -- The panel is the one surface from which a disabled addon gets switched back on by hand, and
  -- the settings registration and the panel body are SETUP rather than features (slash-commands-§7).
  --
  -- THE TYPO IS THE OPPOSITE CASE FROM A REFUSED VERB, and the gate's position is what tells them
  -- apart. A feature verb this addon ships gets the one refusal line, because the addon understood
  -- and is off. A word it does not ship gets slash-commands-§3's `unknown command '<verb>'` and the
  -- index, because the addon did not understand and §3 does not carve the disabled state out of
  -- that MUST. Answering a typo with "the addon is disabled" tells a player who mistyped that their
  -- spelling was fine.
  local Sl, rec = disabledHost()
  Sl:OnSlash("")
  assertEqual(#rec.chat, 1); assertEqual(rec.chat[1], "opened", "the host's config verb ran")
  rec.chat = {}
  Sl:OnSlash("nosuchverb")
  assertEqual(#rec.chat > 1, true, "a typo gets the unknown-command line AND the index, not one line")
  assertEqual(plain(rec.chat[1]):find("unknown command", 1, true) ~= nil, true,
    "the first line names the word that was not understood")
  -- NOT asserted: that the refusal line is absent from the burst. `help` carries it under its
  -- header as a STATUS note -- the addon really is off -- and the index is what a typo prints.
  -- What matters is that the FIRST line named the word, so the player is told they mistyped
  -- rather than told their spelling was fine.
end)

test("sl: an alias onto a gated verb is refused, and an alias onto a live one is honored", function()
  -- Aliases resolve BEFORE the gate. Gating the raw word would refuse `/th hold` and honor
  -- `/th lock`, which is one surface answering two ways.
  local Sl, rec = disabledHost({ aliases = { hold = "lock", on = "enable" } })
  Sl:OnSlash("hold")
  assertEqual(rec.chat[1], REFUSAL, "an alias onto a feature verb is still that feature verb")
  rec.chat = {}
  Sl:OnSlash("on")
  assertEqual(rec.chat[1], slash.FormatKV("enabled", "true"), "an alias onto enable still enables")
end)

test("sl: enable answers normally and is the way back", function()
  local Sl, rec = disabledHost()
  Sl:OnSlash("enable")
  assertEqual(#rec.chat, 1)
  assertEqual(rec.chat[1], slash.FormatKV("enabled", "true"), "the set-shaped echo, not a refusal")
  rec.chat = {}
  -- And the gate is asked at dispatch time, never cached: the very next command works.
  Sl:OnSlash("lock")
  assertEqual(rec.chat[1], "locked")
end)

test("sl: disable ECHOES the write rather than refusing, and is idempotent", function()
  -- Refusing it would answer `/th disable` with a line telling the player to type `/th enable`,
  -- which reads as the addon having misunderstood the request. It is not a feature verb; it is an
  -- alias onto a schema write, so writing false over false is an idempotent no-op write whose
  -- honest answer is the echo every other write gets.
  local Sl, rec = disabledHost()
  Sl:OnSlash("disable")
  assertEqual(#rec.chat, 1)
  assertEqual(rec.chat[1], slash.FormatKV("enabled", "false"))
  assertEqual(rec.enabled.value, false)
end)

test("sl: help prints the full index with the refusal line under its header, unindented", function()
  -- red under: move the refusal emit below the rows in PrintHelp
  --
  -- `help` is not refused: the index prints in full, because the player has to be able to SEE
  -- `enable` in the list. The line under the header is a statement about the whole index — some of
  -- the rows below it are the host's feature verbs, which are the one thing still refused — and
  -- below the rows it would be a footnote to the last one.
  local Sl, rec = disabledHost()
  Sl:OnSlash("help")
  assertEqual(rec.chat[1], Sl:HelpHeader(), "the header first")
  assertEqual(rec.chat[2], REFUSAL, "then the refusal, immediately")
  assertEqual(rec.chat[2]:sub(1, 1) ~= " ", true, "unindented, unlike every row below it")
  assertEqual(#rec.chat, #Sl:HelpRows() + 2, "and every row still printed")
  local sawEnable = false
  for _, line in ipairs(rec.chat) do
    if plain(line):find("/th enable ", 1, true) then sawEnable = true end
  end
  assertEqual(sawEnable, true, "`enable` is visible in the index, which is why help answers at all")
end)

test("sl: help enabled prints no refusal line at all", function()
  local Sl, rec = disabledHost()
  rec.enabled.value = true
  Sl:OnSlash("help")
  assertEqual(rec.chat[1], Sl:HelpHeader())
  assertEqual(rec.chat[2], Sl:HelpRows()[1], "the first row follows the header directly")
end)

test("sl: liveVerbs defaults to the standard's thirteen reserved verbs and is overridable as DATA", function()
  assertEqual(table.concat(slash.LIVE_VERBS, ","),
    "help,config,version,enable,disable,debug,perf,diagnostics,get,set,list,reset,resetall",
    "the library ships one default and a host reads THIS rather than copying it")
  -- Narrowed rather than widened, which is the direction a host most often needs: an addon that
  -- registers no `perf` verb names the ones it has.
  local Sl, rec = disabledHost({ liveVerbs = { "enable", "help" } })
  Sl:OnSlash("disable")
  assertEqual(rec.chat[1], REFUSAL, "a verb outside the declared set is gated like any other")
end)

test("sl: a disabled host that ships diagnostics runs it, by the default live set (minor 16)", function()
  -- debug-logging-§14: the report is most needed from an addon that is off, so the verb is live.
  -- Minor 15 answered it with the refusal line for a host that passed no liveVerbs.
  local Sl, rec = disabledHost()
  rec.commands[#rec.commands + 1] = { "diagnostics", "Write the diagnostics report", function()
    rec.chat[#rec.chat + 1] = "report"
  end }
  Sl:OnSlash("DIAGNOSTICS")
  assertEqual(rec.chat[1], "report", "dispatched, case-insensitively, with no refusal line")
  assertEqual(#rec.chat, 1, "and nothing else printed")
end)

test("sl: a reserved verb the host never shipped is not refused, in either state", function()
  -- A verb is reserved always but REGISTERED WHEN WIRED, so an addon with a no-combat-path
  -- exemption ships no `perf` and `perf` is simply not one of its commands. Minor 13 answered it
  -- with the refusal line while disabled and with `unknown command` while enabled, which made the
  -- disabled state look like it had swallowed a command the addon never had -- five of the eleven
  -- consumers reported exactly that for `/<slash> perf` within a day of adopting it.
  -- Nothing was refused, so nothing says it was.
  --
  -- The LINE COUNT is deliberately not asserted equal: `help` prints its status line under the
  -- index while disabled, so the burst is one longer. What must match is the ANSWER.
  -- Driven with `perf` SPECIFICALLY, and that matters: the bug only reaches a verb that is in
  -- LIVE_VERBS yet absent from COMMANDS. A made-up word misses liveVerbs entirely and would
  -- pass against the broken branch, which is how a first draft of this case proved nothing.
  -- red under: restoring `if isDown and liveVerbs[cmd] then return emit(self:DisabledLine()) end`
  -- ahead of the unknown-command path.
  local SlDown, recDown = F.new({ isEnabled = function() return false end, brandName = "Ka0s Test Host" })
  SlDown:OnSlash("perf")
  assertEqual(plain(recDown.chat[1]):find("unknown command", 1, true) ~= nil, true,
    "disabled: an unshipped verb is not a command here, so it gets the unknown-command line")
  assertEqual(recDown.chat[1] == REFUSAL, false, "nothing was refused, so nothing says it was")

  local SlUp, recUp = F.new()
  SlUp:OnSlash("perf")
  assertEqual(plain(recUp.chat[1]):find("unknown command", 1, true) ~= nil, true,
    "enabled: the same answer, which is the whole point")
end)

test("sl: the gate is asked per dispatch, so a value that changes mid-session is honored", function()
  -- A feature verb, because the reserved ones answer in either state and would pin nothing here.
  local Sl, rec = disabledHost()
  rec.enabled.value = true
  Sl:OnSlash("lock")
  assertEqual(rec.chat[1], "locked", "enabled: the feature verb acts")
  rec.enabled.value = false
  rec.chat = {}
  Sl:OnSlash("lock")
  assertEqual(rec.chat[1], REFUSAL, "disabled: the same verb, the one line")
end)

test("sl: the refusal wording is NOT reachable through the locale override", function()
  -- The wording is the collection's rather than the addon's. A locale table is the obvious place
  -- for eleven addons to each grow their own version of it, so it does not resolve through Text().
  local Sl = disabledHost({ L = { DISABLED_LINE_FORMAT = "%s is off, use %s" } })
  assertEqual(Sl:DisabledLine(), REFUSAL)
end)
