-- tests/test_verdict_instances.lua -- LibKa0s-Verdict-1.0's instance API (Verdict.lua and the
-- instance members the reads, facts, score, collect and gear files add): the host contract, the
-- read override resolved at call time, the lifecycle, and the review focus of Ka0s Drop Watcher's
-- Item Search split plan, test 4: two addons loaded together, each with its own instance (and, in
-- the client, maybe its own copy of the library: LibStub keeps the higher minor), keep their own
-- host config, so their verdicts and signatures never mix.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil, assertFalse =
  T.test, T.assertEqual, T.assertTrue, T.assertNil, T.assertFalse
local FC = dofile("tests/fixture_verdict_client.lua")

local HEAD = 1
local AGI = "ITEM_MOD_AGILITY_SHORT"

local function leather(ilvl, over) return FC.def("INVTYPE_HEAD", ilvl, 4, 2, over) end

-- A Retail Outlaw rogue wearing a leather helm at 600 (item 3000), the drop (3001) in the cache.
local function rogue(drop)
  return function(m)
    m.addItem(FC.link(3000), leather(600, { stats = { [AGI] = 80 } }))
    m.inventory.player[HEAD] = FC.link(3000)
    m.addItem(FC.link(3001), drop or leather(610, { stats = { [AGI] = 50 } }))
  end
end

test("verdict instances: the major reports its ten files, each secondary paired on the shell", function()
  local V = T.mocks.LibStub("LibKa0s-Verdict-1.0")
  for _, pair in ipairs({ { "VerdictReads", "__readsMinor", "__readsShellMinor" },
      { "VerdictCollect", "__collectMinor", "__collectShellMinor" },
      { "VerdictFacts", "__factsMinor", "__factsShellMinor" },
      { "VerdictScore", "__scoreMinor", "__scoreShellMinor" },
      { "VerdictGear", "__gearMinor", "__gearShellMinor" } }) do
    assertEqual(V.MODULES[pair[1]], V[pair[2]], pair[1])
    assertEqual(V[pair[3]], V.MINOR, pair[1] .. ": paired on the live shell")
  end
  for _, name in ipairs({ "Reads", "Collect", "Facts", "ItemRead", "Score", "Gear" }) do
    assertEqual(type(V[name]), "table", name)
  end
  assertEqual(V.VerdictModeFor("forever"), "scoreFirst")
  assertEqual(V.VerdictModeFor("retail"), "ilvlFirst")
  assertEqual(V.VerdictModeFor(nil), "ilvlFirst")
end)

test("verdict instances: two instances with different configs judge one item each their own way", function()
  local W = FC.new{ seed = rogue() }
  local other = { scorer = "weights", weights = { [260] = { [AGI] = 1 } } }
  local mine = { scorer = "none" }
  W.config = mine
  local second = W.V:New({ client = "retail", L = {}, config = function() return other end })
  local a, pa = W.v:Judge(FC.link(3001))
  local b, pb = second:Judge(FC.link(3001))
  -- red under: one shared config (a lib-level settings table every addon writes)
  assertEqual(a.verdict, "upgrade", "item level alone")
  assertEqual(b.verdict, "sidegrade", "the weights disagree")
  assertEqual(b.scoreDelta, -30)
  assertFalse(pa); assertFalse(pb)
  assertTrue(W.v.__facts ~= second.__facts, "each instance keeps its own facts cache")
end)

test("verdict instances: each instance's signature is its own snapshot's, and a cache is never shared", function()
  local W = FC.new{ seed = rogue() }
  local second = W.V:New({ client = "retail", L = {} })
  assertTrue(type(W.v:Signature()) == "string")
  assertEqual(W.v:Signature(), second:Signature(), "the same client reads the same gear")
  W.v:StandDown()
  assertTrue(type(second:Signature()) == "string", "one stood down leaves the other's snapshot")
  assertNil(W.v.__gear, "the stood down one dropped its own")
  local forever = W.V:New({ client = "forever", L = {} })
  assertTrue(forever:Signature() ~= second:Signature(), "a WoW Forever instance reads slot 18 too")
end)

test("verdict instances: a newer copy of the shell keeps every instance's host and methods", function()
  local W = FC.new{ seed = rogue() }
  W.config = { scorer = "none" }
  local before = W.v:Judge(FC.link(3001))
  -- A second addon's copy at a higher minor: LibStub hands back the same table and the files re-run.
  local src = T.loader.readFile("LibKa0s/Verdict.lua"):gsub('"LibKa0s%-Verdict%-1%.0", 1\r?\n', '"LibKa0s-Verdict-1.0", 2\n', 1)
  T.loader.loadSource(src, "Verdict.lua@2", nil, W.m)
  assertEqual(W.V.MINOR, 2, "the higher minor won")
  for _, path in ipairs(FC.PATHS) do
    if path:match("Verdict%u") then T.loader.load(path, nil, W.m) end
  end
  assertEqual(W.V.__gearShellMinor, 2, "the secondaries re-ran on the new shell")
  local after = W.v:Judge(FC.link(3001))
  assertEqual(after.verdict, before.verdict, "the old instance judges on, its host kept")
  assertTrue(W.v.host.config() == W.config)
end)

test("verdict instances: a read the host hands over replaces the library's, looked up at each call", function()
  local W = FC.new{ seed = rogue() }
  local calls = 0
  W.host.reads = { InventoryItemLink = function(unit, slot)
    calls = calls + 1
    return W.m.GetInventoryItemLink(unit, slot)
  end }
  -- red under: v.R captured lib.Reads at New, so a reads table set later was never read
  W.v:Snapshot()
  assertTrue(calls > 0, "the host's member is read")
  assertTrue(W.v.R.GetItemInfo == W.V.Reads.GetItemInfo, "a member the host left out is the library's")
  W.host.reads = nil
  assertTrue(W.v.R.InventoryItemLink == W.V.Reads.InventoryItemLink, "and back, at call time")
end)

test("verdict instances: Config fills the client's verdict mode when the host names none", function()
  local W = FC.new{ client = "forever" }
  assertEqual(W.v:Config().verdictMode, "scoreFirst")
  W.config = { verdictMode = "ilvlFirst" }
  assertEqual(W.v:Config().verdictMode, "ilvlFirst", "the host's wins")
  local bare = W.V:New({ client = "retail" })
  assertEqual(bare:Config().verdictMode, "ilvlFirst", "no config: the defaults")
end)

test("verdict instances: StandUp registers the client's events once; StandDown drops them", function()
  local W = FC.new{}
  W.v:StandUp()
  assertTrue(W.events.PLAYER_EQUIPMENT_CHANGED ~= nil)
  assertTrue(W.events.PLAYER_SPECIALIZATION_CHANGED ~= nil, "Retail's spec event")
  assertTrue(W.events.TRANSMOG_COLLECTION_UPDATED ~= nil, "Retail's appearance event")
  assertNil(W.events.TRAIT_CONFIG_UPDATED, "not WoW Forever's talent event")
  assertTrue(W.events.NEW_MOUNT_ADDED ~= nil and W.events.SPELL_TEXT_UPDATE ~= nil)
  assertEqual(W.count("gear"), 1, "the stand-up rebuild announces")
  W.v:StandUp()
  assertEqual(W.count("gear"), 1, "a second stand-up registers nothing twice and reads the same gear")
  W.v:StandDown()
  assertNil(W.events.PLAYER_EQUIPMENT_CHANGED)
  assertTrue(W.v:IsStoodDown())
  local F = FC.new{ client = "forever" }
  F.v:StandUp()
  assertTrue(F.events.TRAIT_CONFIG_UPDATED ~= nil and F.events.PLAYER_LEVEL_UP ~= nil)
  assertNil(F.events.PLAYER_SPECIALIZATION_CHANGED, "Retail's spec event is not Forever's")
  assertNil(F.events.TRANSMOG_COLLECTION_UPDATED, "WoW Forever has no transmog")
end)

test("verdict instances: JudgeFacts takes another player's candidate, without your heirloom rule", function()
  local W = FC.new{ seed = function(m)
    rogue()(m)
    m.items[FC.link(3000)].quality = 7   -- the worn helm is an heirloom
  end }
  W.config = { scorer = "none", heirloomProtect = true }
  local facts = W.v:Facts(FC.link(3001))
  assertEqual(W.v:JudgeFacts(facts).verdict, "sidegrade", "your own heirloom is protected")
  local looter = { classFile = "ROGUE", specID = 260, gear = { [HEAD] = W.v:Snapshot().equipped[HEAD] } }
  assertEqual(W.v:JudgeFacts(facts, { candidate = looter }).verdict, "upgrade", "a looter's is judged plainly")
end)

test("verdict instances: Judge on an uncached item asks for it and tells the host when it arrives", function()
  local W = FC.new{ seed = rogue(leather(610, { loadsNeeded = 1 })) }
  W.config = { scorer = "none" }
  local me, pending = W.v:Judge(FC.link(3001))
  assertNil(me); assertTrue(pending, "loading")
  assertEqual(W.m.loadRequests[1], 3001)
  W.timers(); W.timers()
  assertEqual(W.count("item"), 1, "onChange item once it loads")
  assertEqual(W.changes[#W.changes], "item:" .. FC.link(3001))
  me, pending = W.v:Judge(FC.link(3001))
  assertEqual(me.verdict, "upgrade"); assertFalse(pending)
  me, pending = W.v:Judge("no link")
  assertNil(me); assertFalse(pending, "a link that names no item is not pending")
end)

test("verdict instances: a newer copy that bumps one secondary alone re-runs every file after it", function()
  local W = FC.new{ seed = function(m)
    rogue()(m)
    m.items[FC.link(3000)].quality = 6   -- the worn helm is an artifact: no heirloom, until below
  end }
  W.config = { scorer = "none", heirloomProtect = true }
  local facts = W.v:Facts(FC.link(3001))
  assertEqual(W.v:JudgeFacts(facts).verdict, "upgrade", "quality 6 is no heirloom at minor 1")
  local generation = W.V.__generation
  for _, path in ipairs(FC.PATHS) do
    if path:match("Verdict%u") then T.loader.load(path, nil, W.m) end
  end
  -- red under: a file that re-ran whenever any file had run since it (the same copy twice re-ran)
  assertEqual(W.V.__generation, generation, "a second copy at the same minors runs nothing")
  -- A second addon's copy whose VerdictConstants alone is at minor 2, with the heirloom quality
  -- moved to 6: its other files keep their minors, as a release that bumps one file ships them.
  local src = T.loader.readFile("LibKa0s/VerdictConstants.lua")
    :gsub("local CONSTANTS_MINOR = 1", "local CONSTANTS_MINOR = 2", 1)
    :gsub('HEIRLOOM  = { "Heirloom", 7 }', 'HEIRLOOM  = { "NoSuchQuality", 6 }', 1)
  T.loader.loadSource(src, "VerdictConstants.lua@2", nil, W.m)
  for _, path in ipairs(FC.PATHS) do
    if path:match("Verdict%u") and not path:match("VerdictConstants") then T.loader.load(path, nil, W.m) end
  end
  assertEqual(W.V.C.QUALITY.HEIRLOOM, 6, "the newer constants won")
  -- red under: each file ran only on its own minor, so Evaluate kept the table it captured at load
  assertEqual(W.v:JudgeFacts(facts).verdict, "sidegrade", "the kernel reads the newer constants")
  assertTrue(W.V.__ranAt[40] > W.V.__ranAt[10], "Evaluate re-ran on the newer constants")
  assertEqual(W.V.__ranAt[100], W.V.__generation, "and so did every file after it, Settings last")
end)
