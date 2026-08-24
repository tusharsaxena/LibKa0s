-- tests/test_env.lua — the client facts every addon in the collection reads the same way.
--
-- THE CASES THAT MATTER ARE THE DEGRADED ONES. Every function here is a two-rung ladder over an
-- API Blizzard has already moved once, and the rung that gets exercised in a live client is the
-- top one — so the bottom rung is the half that ships untested unless a test removes the API. All
-- four therefore have a C_*-absent case, reached by nil-ing the mock rather than by stubbing the
-- function under test (testing-§8).

local T = _G.LK_TEST
local env, mocks = T.env, T.mocks
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

--- Run `fn` with global `name` removed, then restore it. The mock table IS the environment the
--- library chunks were loaded into, so removing a key here is genuinely "this client does not have
--- that API" rather than a stub that pretends.
local function without(name, fn)
  local saved = mocks[name]
  mocks[name] = nil
  local ok, err = pcall(fn)
  mocks[name] = saved
  if not ok then error(err, 0) end
end

-- ── metadata ─────────────────────────────────────────────────────────────────────────────

test("env: GetAddOnMetadata reads the TOC through C_AddOns", function()
  assertEqual(env.GetAddOnMetadata("TestHost", "Version"), "1.2.3")
  assertEqual(env.GetAddOnMetadata("TestHost", "Title"), "Test Host")
end)

test("env: GetAddOnMetadata falls back to the deprecated bare global", function()
  without("C_AddOns", function()
    mocks.GetAddOnMetadata = function(_, field) return field == "Version" and "9.9.9" or nil end
    assertEqual(env.GetAddOnMetadata("TestHost", "Version"), "9.9.9")
    mocks.GetAddOnMetadata = nil
  end)
end)

test("env: GetAddOnMetadata answers nil when neither reader exists", function()
  without("C_AddOns", function()
    without("GetAddOnMetadata", function()
      assertEqual(env.GetAddOnMetadata("TestHost", "Version"), nil)
    end)
  end)
end)

-- ── version ──────────────────────────────────────────────────────────────────────────────

test("env: Version answers the TOC version", function()
  assertEqual(env.Version("TestHost"), "1.2.3")
end)

test("env: Version prefers the TOC over the fallback", function()
  -- The fallback is a hardcoded constant in the host. When the TOC can be read it is the truth,
  -- because it is what the packager stamped and the constant is what someone remembered to edit.
  assertEqual(env.Version("TestHost", "0.0.1"), "1.2.3")
end)

test("env: Version returns the fallback when the TOC cannot be read", function()
  without("C_AddOns", function()
    without("GetAddOnMetadata", function()
      assertEqual(env.Version("TestHost", "0.0.1"), "0.0.1")
      assertEqual(env.Version("TestHost"), nil)
    end)
  end)
end)

-- ── map / zone ───────────────────────────────────────────────────────────────────────────

test("env: GetPlayerMapID asks C_Map for the player's map", function()
  assertEqual(env.GetPlayerMapID(), 2112)
end)

test("env: GetPlayerMapID answers nil without C_Map", function()
  without("C_Map", function()
    assertEqual(env.GetPlayerMapID(), nil)
  end)
end)

test("env: GetZone answers zone and subzone", function()
  local zone, sub = env.GetZone()
  assertEqual(zone, "Silvermoon City")
  assertEqual(sub, "Falconwing Square")
end)

test("env: GetZone answers empty strings, never nil, when the readers are absent", function()
  -- LOAD-BEARING, not cosmetic. LootHistory buckets "" with nil deliberately in storage and in the
  -- Zone filter (core/Database.lua, modules/BrowserTable.lua). A nil here would move stored rows
  -- between buckets on the first re-render.
  without("GetZoneText", function()
    without("GetSubZoneText", function()
      local zone, sub = env.GetZone()
      assertEqual(zone, "")
      assertEqual(sub, "")
      assertTrue(type(zone) == "string" and type(sub) == "string", "both are always strings")
    end)
  end)
end)
