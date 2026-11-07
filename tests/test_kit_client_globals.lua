-- tests/test_kit_client_globals.lua -- the missing-globals scanner (testkit/client_globals.lua) and the
-- kit suite that runs it (testkit/test_client_globals.lua), WFP-LK-06, LibKa0s#77.
--
-- WHAT IT PROVES. That a bare call of a name no client has is flagged on both clients, that each
-- guard shape, each declaration shape and each blanked region (comment, string) is left alone, that a
-- C_ member missing on one client is flagged on that client alone, that the TOC picks the clients, and
-- that the allowlist excuses, demands a reason and goes stale.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local CG = dofile("tests/_kit/client_globals.lua")
local sets = CG.sets("tests/_kit/")

--- "line:name:client" of every finding in one source, comma-joined.
local function flags(src)
  local out = {}
  for _, hit in ipairs(CG.scan({ { "x.lua", src } }, sets)) do
    out[#out + 1] = hit.line .. ":" .. hit.name .. ":" .. hit.client
  end
  return table.concat(out, ",")
end

test("client_globals_flags_setdesaturation: a bare call no client has is flagged for both", function()
  assertEqual(flags("SetDesaturation(x, true)"), "1:SetDesaturation:live,1:SetDesaturation:forever")
end)

test("client_globals_ignores_guarded: a presence test on the same name excuses the call", function()
  assertEqual(flags("if SetDesaturation then SetDesaturation(x) end"), "")
  assertEqual(flags("local ok = SetDesaturation and SetDesaturation(x)"), "")
  assertEqual(flags("local f = SetDesaturation\nif f then f(x) end\nSetDesaturation(x)"), "")
  assertEqual(flags("if type(SetDesaturation) == 'function' then\nSetDesaturation(x)\nend"), "")
end)

test("client globals: a name in a comment or a string is neither a call nor a guard", function()
  assertEqual(flags("-- SetDesaturation(x)\nlocal s = 'SetDesaturation(x)'\n--[[ SetDesaturation(x) ]]"), "")
  assertEqual(flags('-- if SetDesaturation then\nSetDesaturation(x)'), "2:SetDesaturation:live,2:SetDesaturation:forever")
  assertEqual(flags("local s = [==[\nSetDesaturation(x)\n]==]\nSetDesaturation(y)"),
    "4:SetDesaturation:live,4:SetDesaturation:forever")
end)

test("client globals: what the addon declares is its own, whatever the shape", function()
  assertEqual(flags("local function Mine() end\nMine()"), "")
  assertEqual(flags("function Mine2(cb) cb() end\nMine2(1)"), "")
  assertEqual(flags("local a, b = 1, 2\na()\nb()"), "")
  assertEqual(flags("for k, v in pairs(t) do v() end"), "")
  assertEqual(flags("Global = function() end\nGlobal()"), "")
  assertEqual(flags("_G.Other = 1\nOther()"), "")
  assertEqual(flags("local f = function(handler) handler() end"), "")
end)

test("client globals: methods, fields and real client functions are no findings", function()
  assertEqual(flags("tex:SetDesaturation(true)\nobj.SetDesaturation(x)\nCreateFrame('Frame')\nwipe(t)"), "")
  assertEqual(flags("self.textures[i]: SetDesaturation(true)\nobj. SetDesaturation(x)"), "", "a space after the colon or dot")
  assertEqual(flags("function NS:Do() end\nlocal x = function() end"), "")
end)

test("client globals: a C_ member missing on one client is flagged on that client alone", function()
  assertEqual(flags("C_Timer.After(1, f)"), "")
  assertEqual(flags("C_AccountServices.GetPreferredPlaySettings()"), "1:C_AccountServices.GetPreferredPlaySettings:live")
  assertEqual(flags("C_TransmogOutfitInfo.GetWeaponOptionsForSlot(1)"), "1:C_TransmogOutfitInfo.GetWeaponOptionsForSlot:forever")
  assertEqual(flags("if C_AccountServices then C_AccountServices.GetPreferredLocales() end"), "")
  assertEqual(flags("if C_AccountServices.GetPreferredLocales then C_AccountServices.GetPreferredLocales() end"), "")
  assertEqual(flags("C_MyOwnNamespace.Call()"), "", "a C_ root no client knows is the addon's")
end)

test("client globals: the live and forever sets differ where the data says, and carry their SHAs", function()
  assertTrue(sets.live.CreateFrame and sets.forever.CreateFrame)
  assertTrue(sets.live.AbandonSkill and not sets.forever.AbandonSkill, "AbandonSkill is live-only")
  assertTrue(#sets.meta.live.sha == 40 and #sets.meta.forever.sha == 40)
end)

test("client globals: the TOC picks the clients, forever only on a 16xxx Interface", function()
  assertEqual(table.concat(CG.clientsFromToc("## Interface: 120105"), ","), "live")
  assertEqual(table.concat(CG.clientsFromToc("## Interface: 120105, 16001"), ","), "live,forever")
  assertEqual(table.concat(CG.clientsFromToc("## Interface: 16001\n"), ","), "live,forever")
  assertEqual(table.concat(CG.clientsFromToc("## Title: x\n## Version: 1.16000.1"), ","), "live")
  assertEqual(table.concat(CG.clientsFromToc(nil), ","), "live")
end)

test("client globals: the allowlist excuses, needs a reason and goes stale", function()
  local found = CG.scan({ { "x.lua", "Gone(1)\nGone(2)" } }, sets)
  local bad = CG.judge(found, {}, { "live" })
  assertEqual(#bad, 2)
  assertEqual(bad[1], "x.lua:1 Gone live")
  local problems, stale
  bad, problems, stale = CG.judge(found, { { name = "Gone", reason = "client call" } }, { "live" })
  assertEqual(#bad + #problems + #stale, 0)
  local _
  _, problems = CG.judge(found, { { name = "Gone" } }, { "live" })
  assertEqual(#problems, 1)
  _, _, stale = CG.judge(found, { { name = "Never", reason = "r" } }, { "live" })
  assertEqual(stale[1], "Never")
  bad = CG.judge(found, {}, { "forever" })
  assertEqual(#bad, 2, "forever findings count when forever is asked for")
  bad = CG.judge(CG.scan({ { "x.lua", "AbandonSkill()" } }, sets), {}, { "live" })
  assertEqual(#bad, 0, "a name only forever lacks does not fail a retail-only addon")
end)

test("client globals: no git fails rather than passing over nothing", function()
  local real = io.popen
  rawset(io, "popen", nil)
  local ok, err = pcall(CG.collect, ".")
  rawset(io, "popen", real)
  assertTrue(not ok and tostring(err):find("io.popen is unavailable", 1, true) ~= nil, tostring(err))
end)

-- ── the kit suite, driven by a stand-in kit ─────────────────────────────────────────────────

local function suite(facts)
  local cases = {}
  local kit = {
    clientGlobals = facts,
    test = function(name, fn) cases[#cases + 1] = { name = name, fn = fn } end,
    fail = function(msg) error(msg, 0) end,
  }
  assert(loadfile("tests/_kit/test_client_globals.lua"))(kit)
  return cases
end

local function runAll(cases)
  local failed = {}
  for _, c in ipairs(cases) do
    local ok, err = pcall(c.fn)
    if not ok then failed[#failed + 1] = c.name .. ": " .. tostring(err) end
  end
  return table.concat(failed, "\n")
end

local function repoWith(files)
  local dir = os.tmpname(); os.remove(dir); os.execute("mkdir -p '" .. dir .. "/tests' '" .. dir .. "/libs'")
  for path, body in pairs(files) do
    local f = assert(io.open(dir .. "/" .. path, "wb")); f:write(body); f:close()
  end
  os.execute("git -C '" .. dir .. "' init -q && git -C '" .. dir .. "' add -A")
  return dir
end

test("client globals suite: a clean repo passes, a missing global fails with file:line name client", function()
  local clean = repoWith({ ["A.lua"] = "CreateFrame('Frame')", ["A.toc"] = "## Interface: 120105\nA.lua" })
  assertEqual(runAll(suite({ root = clean, allow = clean .. "/none.lua" })), "")
  local dirty = repoWith({ ["A.lua"] = "local x\nSetDesaturation(x)", ["A.toc"] = "## Interface: 120105\nA.lua" })
  local out = runAll(suite({ root = dirty, allow = dirty .. "/none.lua" }))
  assertTrue(out:find("A.lua:2 SetDesaturation live", 1, true) ~= nil, out)
  assertTrue(out:find("forever", 1, true) == nil or out:find("A.lua:2 SetDesaturation forever", 1, true) == nil, out)
end)

test("client globals suite: tests/ is not scanned, libs/ is, and forever counts on a 16xxx TOC", function()
  local root = repoWith({
    ["tests/T.lua"] = "SetDesaturation(1)", ["libs/L.lua"] = "AbandonSkill()",
    ["A.toc"] = "## Interface: 120105, 16001",
  })
  local out = runAll(suite({ root = root, allow = root .. "/none.lua" }))
  assertTrue(out:find("libs/L.lua:1 AbandonSkill forever", 1, true) ~= nil, out)
  assertTrue(out:find("tests/T.lua", 1, true) == nil, out)
end)
