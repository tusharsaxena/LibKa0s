-- tests/test_options_reset_tooltip.lua — OptionsCompose minor 11: O.ResetAllTooltip(tail).
--
-- options-ui-§12 (WS-36): where the General page's header Defaults is the global reset, its
-- `defaultsTooltip` MUST be the very text Reset all settings carries, so two controls for one act
-- cannot describe it two ways (U-04, XC-02). An addon with key bindings passes options-ui-§20's
-- tail, O.ResetAllTooltip(O.KEYBINDS_UNCHANGED). The member reads the descriptor at call time
-- exactly as MasterControls' button does. A NO MOCK suite like test_options_compose.lua, apart
-- from the InlineButtonPair recorder.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local Fixture = dofile("tests/fixture_options.lua")

local S = T.options.STRINGS

-- The three hosts the reset can be: settings only, a profile reset, and a profile reset beside a
-- Profiles page.
local HOSTS = {
  { name = "no resetProfile", overrides = {}, want = "RESET_ALL_TIP" },
  { name = "resetProfile", overrides = { resetProfile = function() end }, want = "RESET_ALL_TIP_PROFILE" },
  { name = "resetProfile + profilesPage",
    overrides = { resetProfile = function() end, profilesPage = true },
    want = "RESET_ALL_TIP_PROFILES_PAGE" },
}

--- The Reset all settings spec the MasterControls tail hands O.InlineButtonPair, through a
--- recorder that is put back after the call.
local function resetAllSpec(O, extra)
  local spec = { page = "general", addonName = "X", onResetAll = function() end,
    onResetPosition = function() end }
  for k, v in pairs(extra or {}) do spec[k] = v end
  local _, tail = O.MasterControls(spec)
  local seen, saved = nil, O.InlineButtonPair
  O.InlineButtonPair = function(_, left, right)
    for _, b in ipairs({ left, right }) do
      if b.text == "Reset all settings" then seen = b end
    end
  end
  local ok, err = pcall(tail, {})
  O.InlineButtonPair = saved
  assertTrue(ok, tostring(err))
  assertTrue(seen ~= nil, "the tail drew Reset all settings")
  return seen
end

test("reset tooltip: each host answers its own lib.STRINGS wording", function()
  -- red under: a single literal, or one wording for every host.
  for _, h in ipairs(HOSTS) do
    local O = Fixture.new(h.overrides)
    assertEqual(O.ResetAllTooltip(), S[h.want], h.name)
  end
end)

test("reset tooltip: follows a descriptor changed after New, as the button does", function()
  -- red under: the descriptor read once at attach time rather than at each call.
  local O, rec = Fixture.new()
  assertEqual(O.ResetAllTooltip(), S.RESET_ALL_TIP, "before")
  rec.d.resetProfile = function() end
  assertEqual(O.ResetAllTooltip(), S.RESET_ALL_TIP_PROFILE, "resetProfile set after New")
  assertEqual(O.ResetAllTooltip(), resetAllSpec(O).tooltip, "resetProfile, same as the button")
  rec.d.profilesPage = true
  assertEqual(O.ResetAllTooltip(), S.RESET_ALL_TIP_PROFILES_PAGE, "profilesPage set after New")
  assertEqual(O.ResetAllTooltip(), resetAllSpec(O).tooltip, "profilesPage, same as the button")
end)

test("reset tooltip: equals the tooltip MasterControls gives Reset all settings", function()
  -- red under: a second copy of the wording that drifts from the button's.
  for _, h in ipairs(HOSTS) do
    local O = Fixture.new(h.overrides)
    assertEqual(O.ResetAllTooltip(), resetAllSpec(O).tooltip, h.name)
  end
end)

test("reset tooltip: the key-bindings tail follows after one space", function()
  -- red under: the tail ignored, glued on without a space, or put in front.
  for _, h in ipairs(HOSTS) do
    local O = Fixture.new(h.overrides)
    assertEqual(O.ResetAllTooltip(O.KEYBINDS_UNCHANGED),
      resetAllSpec(O).tooltip .. " Key bindings are not changed.", h.name)
  end
end)

test("reset tooltip: an empty, nil or non-string tail adds nothing", function()
  -- red under: a trailing space, or tostring() of a non-string.
  local O = Fixture.new()
  local plain = O.ResetAllTooltip()
  assertEqual(O.ResetAllTooltip(nil), plain, "nil")
  assertEqual(O.ResetAllTooltip(""), plain, "empty string")
  assertEqual(O.ResetAllTooltip(42), plain, "number")
  assertEqual(O.ResetAllTooltip({}), plain, "table")
  assertEqual(O.ResetAllTooltip(true), plain, "boolean")
end)

test("reset tooltip: notes.resetAll is the button's own and does not reach the member", function()
  -- red under: the member reading a note left behind by a MasterControls call.
  local O = Fixture.new({ resetProfile = function() end })
  local before = O.ResetAllTooltip()
  local noted = resetAllSpec(O, { notes = { resetAll = "All note." } })
  assertEqual(noted.tooltip, before .. " All note.", "the button carries the note")
  assertEqual(O.ResetAllTooltip(), before, "the member does not")
end)

test("reset tooltip: OptionsCompose is at minor 11", function()
  assertEqual(T.options.MODULES.OptionsCompose, 11)
end)
