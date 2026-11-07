-- tests/test_mock_client.lua -- the kit's client profiles (testkit/mock_client.lua).
--
-- Two profiles and no more: `retail` (the default, live Retail shape, WOW_PROJECT_CAMELOT nil) and
-- `forever`. Every case applies a profile by name to a FRESH mock set, so none depends on which
-- profile the run was started under (KA0S_KIT_CLIENT).

local T = _G.LK_TEST
local test, assertEqual, assertNil, assertTrue = T.test, T.assertEqual, T.assertNil, T.assertTrue

local MockClient = dofile("tests/_kit/mock_client.lua")
local buildMocks = dofile("tests/wow_mock.lua")

local function fresh(name)
  local m = buildMocks()
  MockClient.apply(m, name)
  return m
end

test("mock client: retail is the live Retail shape, with no Camelot constant", function()
  local m = fresh("retail")
  assertEqual(m.WOW_PROJECT_ID, 1, "WOW_PROJECT_ID")
  assertEqual(m.WOW_PROJECT_MAINLINE, 1, "WOW_PROJECT_MAINLINE")
  assertNil(m.WOW_PROJECT_CAMELOT, "the constant does not exist on Retail")
  local version, build, _, interface = m.GetBuildInfo()
  assertEqual(version, "12.1.5", "version")
  assertEqual(build, "70783", "build")
  assertEqual(interface, 120105, "interface")
  assertNil(m.SetDesaturation, "SetDesaturation is absent under retail too")
  assertEqual(MockClient.current(), "retail", "current")
end)

test("mock client: forever is Camelot, with the spec globals gone", function()
  local m = fresh("forever")
  assertEqual(m.WOW_PROJECT_ID, 18, "WOW_PROJECT_ID")
  assertEqual(m.WOW_PROJECT_CAMELOT, 18, "WOW_PROJECT_CAMELOT")
  assertEqual(m.WOW_PROJECT_MAINLINE, 1, "WOW_PROJECT_MAINLINE")
  local version, build, date, interface = m.GetBuildInfo()
  assertEqual(version, "1.60.1", "version")
  assertEqual(build, "70790", "build")
  assertEqual(date, "Nov  3 2026", "date")
  assertEqual(interface, 16001, "the 4th return is the interface")
  for _, name in ipairs({ "GetSpecialization", "GetSpecializationInfo", "GetActiveSpecGroup",
    "GetTalentInfo", "SetDesaturation" }) do
    assertNil(m[name], name .. " is absent on Forever")
  end
  assertEqual(MockClient.current(), "forever", "current")
end)

test("mock client: an unknown profile name raises", function()
  local err = T.assertError(function() MockClient.apply(buildMocks(), "classic") end,
    "no third profile")
  assertTrue(tostring(err):find('unknown client profile "classic"', 1, true) ~= nil, "names it")
end)

test("mock client: applying retail after forever restores the Camelot-free shape", function()
  local m = fresh("forever")
  MockClient.apply(m, "retail")
  assertNil(m.WOW_PROJECT_CAMELOT, "cleared again")
  assertEqual(m.WOW_PROJECT_ID, 1, "id")
end)
