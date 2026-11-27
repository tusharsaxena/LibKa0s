-- tests/test_verdict_facts.lua -- LibKa0s-Verdict-1.0's item facts (VerdictFacts.lua): a link turned
-- into the facts the kernel reads, cached per instance; the load of an uncached item with its
-- callback as the retry; the cache cap; the appearance and spell text events; the stand-down; and
-- lib.ItemRead, how complete a link is, with the instance's level and quality reads. Ka0s Drop
-- Watcher's tests/test_item_facts.lua and the ItemRead cases of its tests/test_item_read.lua,
-- ported to the instance.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local FC = dofile("tests/fixture_verdict_client.lua")

local RING  = "|cnIQ4:|Hitem:2001::::::::90:::::|h[Band]|h|r"
local CHEST = "|cnIQ3:|Hitem:2002::::::::90:::::|h[Hauberk]|h|r"
local TOKEN = "|cnIQ4:|Hitem:2003::::::::90:::::|h[Dreadful Helm Module]|h|r"

local function ring(extra)
  local def = { name = "Band", quality = 4, ilvl = 250, effectiveIlvl = 263, equipLoc = "INVTYPE_FINGER",
    classID = 4, subClassID = 0, bindType = 1,
    stats = { ITEM_MOD_CRIT_RATING_SHORT = 100, ITEM_MOD_SOMETHING_NEW = 4 }, specs = { 71, 72 },
    unique = { false, "Cat", 2, 55 }, transmog = true }
  for k, v in pairs(extra or {}) do def[k] = v end
  return def
end

local function chest(extra)
  local def = { name = "Hauberk", quality = 3, ilvl = 240, equipLoc = "INVTYPE_CHEST", classID = 4,
    subClassID = 3, bindType = 1, stats = { ITEM_MOD_AGILITY_SHORT = 50 }, transmog = false }
  for k, v in pairs(extra or {}) do def[k] = v end
  return def
end

local function world(seed, client) return FC.new{ seed = seed, client = client } end

-- ---------------------------------------------------------------------------------------------
-- Reading the facts
-- ---------------------------------------------------------------------------------------------

test("verdict facts: a cached ring reads every field", function()
  local W = world(function(m)
    m.addItem(RING, ring())
    m.upgradeInfo[RING] = { currentLevel = 3, maxLevel = 6, maxItemLevel = 276, trackString = "Hero",
      trackStringID = 999 }
  end)
  local f = W.v:Facts(RING)
  assertEqual(f.link, RING); assertEqual(f.itemID, 2001); assertEqual(f.name, "Band")
  assertEqual(f.ilvl, 263, "the effective level"); assertEqual(f.baseIlvl, 250); assertEqual(f.ilvlSource, "detailed")
  assertEqual(f.equipLoc, "INVTYPE_FINGER"); assertEqual(f.classID, 4); assertEqual(f.subClassID, 0)
  assertEqual(f.quality, 4); assertEqual(f.qualitySource, "item"); assertEqual(f.bindType, 1)
  assertEqual(f.track.name, "Hero"); assertEqual(f.track.rank, 3); assertEqual(f.track.max, 6)
  assertEqual(f.track.tier, 5, "the enUS name, the string id being unknown")
  assertEqual(f.track.stringID, 999); assertEqual(f.track.source, "api")
  assertEqual(f.stats.ITEM_MOD_CRIT_RATING_SHORT, 100)
  assertEqual(f.stats.ITEM_MOD_SOMETHING_NEW, 4, "an unknown stat key is kept")
  assertTrue(f.specs[71]); assertTrue(f.specs[72]); assertNil(f.specs[73])
  assertEqual(f.specsClass, "ROGUE", "the class the client read the specs for")
  assertEqual(f.unique.cat, 55); assertEqual(f.unique.max, 2)
  assertFalse(f.warbound); assertFalse(f.warboundUntilEquip)
  assertNil(f.transmogKnown, "a ring has no appearance")
  assertNil(f.classes); assertFalse(f.isTierToken)
  assertEqual(f.category, "equipment"); assertEqual(f.rawEquipLoc, "INVTYPE_FINGER")
end)

test("verdict facts: a chest reads its appearance on Retail alone, its account binds and no specs", function()
  local W = world(function(m)
    m.addItem(CHEST, chest({ specs = {} }))
    m.accountBoundUE[CHEST] = true
  end)
  local f = W.v:Facts(CHEST)
  assertEqual(f.ilvl, 240, "no effective level: the base one")
  assertFalse(f.transmogKnown)
  assertNil(f.specs, "an empty spec list names no spec")
  assertNil(f.track); assertNil(f.unique)
  assertTrue(f.warbound); assertTrue(f.warboundUntilEquip)
  local F = world(function(m) m.addItem(CHEST, chest()) end, "forever")
  assertNil(F.v:Facts(CHEST).transmogKnown, "WoW Forever has no transmog: no look is read")
end)

test("verdict facts: the stats carry every primary stat on the tooltip, not the playing spec's alone", function()
  local CLOAK = "|cnIQ4:|Hitem:193763::::::::90:253:::::|h[Fireproof Drape]|h|r"
  local W = world(function(m)
    m.addItem(CLOAK, { name = "Fireproof Drape", quality = 4, ilvl = 311, equipLoc = "INVTYPE_CLOAK",
      classID = 4, subClassID = 1, bindType = 1,
      stats = { ITEM_MOD_AGILITY_SHORT = 86, ITEM_MOD_STAMINA_SHORT = 1689 }, specs = { 253, 254, 255 } })
    m.tooltips.hyperlink[CLOAK] = { lines = { { leftText = "+86 Agility" },
      { leftText = "+1,689 Stamina" }, { leftText = "+86 Intellect" }, { leftText = "+86 Strength" } } }
  end)
  local f = W.v:Facts(CLOAK)
  assertEqual(f.stats.ITEM_MOD_STRENGTH_SHORT, 86); assertEqual(f.stats.ITEM_MOD_INTELLECT_SHORT, 86)
  assertEqual(f.stats.ITEM_MOD_STAMINA_SHORT, 1689)
  -- red under: Agility alone refused a Blood death knight (primaryStat)
  assertEqual(W.V.Equippability(f, { classFile = "DEATHKNIGHT", specID = 250 }, "retail"), "ok")
  assertEqual(W.V.Equippability(f, { classFile = "PALADIN", specID = 70 }, "retail"), "ok")
end)

test("verdict facts: the track tier, by string id first, then by enUS name, else unset; the tooltip line", function()
  local IF = T.mocks.LibStub("LibKa0s-Verdict-1.0").Facts
  assertEqual(IF.TrackTier(nil, "Champion"), 4)
  assertNil(IF.TrackTier(nil, "Champion (localized)")); assertNil(IF.TrackTier(nil, nil))
  local W = world(function(m)
    m.addItem(RING, ring())
    m.tooltips.hyperlink[RING] = { lines = { { type = 32, leftText = "Upgrade Level: Champion 2/8" } } }
  end)
  local t = W.v:Facts(RING).track
  assertEqual(t.name, "Champion"); assertEqual(t.rank, 2); assertEqual(t.max, 8)
  assertEqual(t.tier, 4); assertEqual(t.source, "tooltip"); assertNil(t.stringID)
  W.V.C.TRACK_TIER_BY_STRING_ID[971] = 2   -- this world's own copy of the major
  assertEqual(W.V.Facts.TrackTier(971, "Heros"), 2, "the string id wins over a localized name")
end)

test("verdict facts: an item unique on its own takes its item id as the category", function()
  local W = world(function(m) m.addItem(RING, ring({ unique = { true, nil, nil, 0 } })) end)
  local u = W.v:Facts(RING).unique
  assertEqual(u.cat, "item:2001"); assertEqual(u.max, 1)
end)

test("verdict facts: a token naming classes is a tier token, its slot from its name; class gear is not", function()
  local W = world(function(m)
    m.addItem(TOKEN, { name = "Dreadful Helm Module", quality = 4, ilvl = 263, equipLoc = "",
      classID = 15, subClassID = 0, bindType = 1 })
    m.tooltips.hyperlink[TOKEN] = { lines = { { type = 21, leftText = "Classes: Warrior, Paladin, Death Knight" } } }
    m.addItem(CHEST, chest())
    m.tooltips.hyperlink[CHEST] = { lines = { { type = 21, leftText = "Classes: Hunter" } } }
  end)
  local t = W.v:Facts(TOKEN)
  assertTrue(t.isTierToken)
  assertTrue(t.classes.WARRIOR); assertTrue(t.classes.DEATHKNIGHT); assertNil(t.classes.MAGE)
  assertEqual(t.tokenSlot, "INVTYPE_HEAD"); assertEqual(t.tokenSlotSource, "name")
  assertEqual(t.equipLoc, "INVTYPE_HEAD"); assertEqual(t.rawEquipLoc, ""); assertEqual(t.category, "tierToken")
  local c = W.v:Facts(CHEST)
  assertNil(c.tokenSlot); assertFalse(c.isTierToken); assertTrue(c.classes.HUNTER)
end)

test("verdict facts: a tier token's use text names the slot it makes, read once; gear's never", function()
  local USE = "Synthesize a soulbound Voidglass set chest item appropriate for your class."
  local reads = { item = 0, gear = 0 }
  local W = world(function(m)
    m.addItem(TOKEN, { name = "Voidglass Idol", quality = 4, ilvl = 263, equipLoc = "", classID = 15,
      subClassID = 0, bindType = 1 })
    m.tooltips.hyperlink[TOKEN] = { lines = { { type = 21, leftText = "Classes: Warrior" } } }
    m.itemSpells[TOKEN], m.spellTexts[77] = 77, USE
    m.addItem(CHEST, chest())
    m.itemSpells[CHEST], m.spellTexts[78] = 78, (USE:gsub("chest", "hand"))
  end)
  local spellOf = W.m.C_Item.GetItemSpell
  W.m.C_Item.GetItemSpell = function(link)
    if link == TOKEN then reads.item = reads.item + 1 elseif link == CHEST then reads.gear = reads.gear + 1 end
    return spellOf(link)
  end
  local t = W.v:Facts(TOKEN)
  assertEqual(t.tokenSlot, "INVTYPE_CHEST"); assertEqual(t.tokenSlotSource, "use")
  assertEqual(t.useText, USE); assertEqual(t.equipLoc, "INVTYPE_CHEST")
  W.v:Facts(TOKEN)
  assertEqual(reads.item, 1, "read once: the facts are cached")
  local c = W.v:Facts(CHEST)
  assertFalse(c.isTierToken); assertNil(c.useText); assertEqual(reads.gear, 0, "gear's use text is never read")
end)

test("verdict facts: a use spell not loaded yet is waited on, and SPELL_TEXT_UPDATE reads it again", function()
  local USE = "Synthesize a soulbound Voidglass set hand item appropriate for your class."
  local W = world(function(m)
    m.addItem(TOKEN, { name = "Voidglass Idol", quality = 4, ilvl = 263, equipLoc = "", classID = 15,
      subClassID = 0, bindType = 1 })
    m.tooltips.hyperlink[TOKEN] = { lines = { { type = 21, leftText = "Classes: Warrior" } } }
    m.itemSpells[TOKEN], m.spellTexts[77] = 77, ""
  end)
  local f, status = W.v:Request(TOKEN)
  assertNil(f); assertEqual(status, "loading", "the use text is still loading")
  assertEqual(W.m.spellLoadRequests[1], 77)
  W.v:StandUp()
  W.m.spellTexts[77] = USE
  W.fire("SPELL_TEXT_UPDATE", 77)
  local t = W.v:Facts(TOKEN)
  assertEqual(t.tokenSlot, "INVTYPE_HAND", "read again on the event"); assertNil(t.useSpellLoading)
end)

test("verdict facts: a relic is gear on Forever, not gear on Retail", function()
  local RELIC = "|cnIQ3:|Hitem:2004::::::::60:::::|h[Libram of Truth]|h|r"
  local USE = "Increases the damage of your Holy Strike."
  local function seed(m)
    m.addItem(RELIC, { name = "Libram of Truth", quality = 3, ilvl = 60, equipLoc = "INVTYPE_RELIC",
      classID = 4, subClassID = 7, bindType = 1, stats = {} })
    m.itemSpells[RELIC], m.spellTexts[79] = 79, USE
  end
  assertEqual(world(seed).v:Facts(RELIC).useText, USE, "Retail: not gear, its use text is read")
  assertNil(world(seed, "forever").v:Facts(RELIC).useText, "Forever: gear, never read")
end)

test("verdict facts: the quality falls back to the link's color", function()
  local W = world(function(m)
    local d = ring()
    d.quality = nil   -- the client answers no quality for the link
    m.addItem(RING, d)
  end)
  local f = W.v:Facts(RING)
  assertEqual(f.quality, 4); assertEqual(f.qualitySource, "link")
end)

-- ---------------------------------------------------------------------------------------------
-- The cache
-- ---------------------------------------------------------------------------------------------

test("verdict facts: Facts caches by link, per instance", function()
  local W = world(function(m) m.addItem(RING, ring()) end)
  local a = W.v:Facts(RING)
  W.m.items[RING].effectiveIlvl = 289
  assertTrue(W.v:Facts(RING) == a, "the cached table")
  assertEqual((W.v:FactsCounts()), 1)
  local other = W.V:New({ client = "retail" })
  assertEqual(other:Facts(RING).ilvl, 289, "another instance reads its own")
end)

test("verdict facts: at its cap the cache drops its least recently used quarter, never the whole", function()
  local links = {}
  for i = 1, 9 do links[i] = ("|cnIQ4:|Hitem:%d::::::::90:::::|h[Band %d]|h|r"):format(5000 + i, i) end
  local W = world(function(m) for _, l in ipairs(links) do m.addItem(l, ring()) end end)
  local IF = W.V.Facts
  IF.CACHE_CAP = 8
  for i = 1, 8 do W.v:Facts(links[i]) end
  W.v:Facts(links[1]); W.v:Facts(links[2])
  W.m.items[links[3]].name = "changed"
  W.v:Facts(links[9])
  assertEqual((W.v:FactsCounts()), 7, "two of eight dropped, then the new link")
  assertEqual(W.v:Facts(links[1]).name, "Band", "a recently used link stays")
  assertEqual(W.v:Facts(links[3]).name, "changed", "the least recently used went, and is read again")
end)

test("verdict facts: garbage links answer nil and never raise", function()
  local W = world()
  local SECRET = RING .. "(secret)"   -- the client says this one value is secret
  W.m.issecretvalue = function(v) return v == SECRET end
  W.m.addItem(SECRET, ring())
  assertNil(W.v:Facts(nil)); assertNil(W.v:Facts(42)); assertNil(W.v:Facts("no item here"))
  assertNil(W.v:Facts(SECRET), "a secret link is never read")
  local f, status = W.v:Request("no item here", function() error("never called") end)
  assertNil(f); assertEqual(status, "invalid")
end)

test("verdict facts: learning an appearance re-reads the flag from the raw slot, then the collections", function()
  local W = world(function(m) m.addItem(CHEST, chest()) end)
  W.v:StandUp()
  W.changes = {}
  local f = W.v:Facts(CHEST)
  assertFalse(f.transmogKnown)
  f.equipLoc = "INVTYPE_NECK"   -- a later step's slot: the raw one decides
  W.m.items[CHEST].transmog = true
  W.fire("TRANSMOG_COLLECTION_UPDATED")
  assertTrue(W.v:Facts(CHEST).transmogKnown)
  W.timers()
  assertEqual(W.count("collection"), 1, "the host hears it once the re-read ran")
end)

-- ---------------------------------------------------------------------------------------------
-- Loading an uncached item
-- ---------------------------------------------------------------------------------------------

test("verdict facts: Request answers a cached item at once and never calls back", function()
  local W = world(function(m) m.addItem(RING, ring()) end)
  local f, status = W.v:Request(RING, function() error("not for a ready item") end)
  assertEqual(f.name, "Band"); assertEqual(status, "ready")
  assertEqual(#W.m.loadRequests, 0); assertEqual(W.timers(), 0)
end)

test("verdict facts: an uncached item loads, and every waiter is called back once", function()
  local W = world(function(m) m.addItem(RING, ring({ loadsNeeded = 1 })) end)
  local got = {}
  local f, status = W.v:Request(RING, function(facts, link) got[#got + 1] = { facts, link } end)
  assertNil(f); assertEqual(status, "loading")
  local _, status2 = W.v:Request(RING, function(facts) got[#got + 1] = { facts } end)
  assertEqual(status2, "loading")
  assertEqual(#W.m.loadRequests, 1, "one load for both")
  assertEqual(select(2, W.v:FactsCounts()), 1)
  W.timers(); W.timers()
  assertEqual(#got, 2)
  assertEqual(got[1][1].name, "Band"); assertEqual(got[1][2], RING)
  assertTrue(got[2][1] == got[1][1], "the same cached facts")
  assertEqual(select(2, W.v:FactsCounts()), 0)
end)

test("verdict facts: an item that never arrives is given up after MAX_LOAD_TRIES, with nil", function()
  local W = world(function(m) m.addItem(RING, ring({ loadsNeeded = 99 })) end)
  local calls, got = 0, "unset"
  W.v:Request(RING, function(facts) calls = calls + 1; got = facts end)
  for _ = 1, 20 do W.timers() end
  assertEqual(calls, 1); assertNil(got)
  assertEqual(#W.m.loadRequests, W.V.Facts.MAX_LOAD_TRIES)
  assertEqual(select(2, W.v:FactsCounts()), 0)
end)

test("verdict facts: a client that cannot load items answers unavailable", function()
  local W = world(function(m) m.addItem(RING, ring({ loadsNeeded = 1 })) end)
  W.m.C_Item.RequestLoadItemDataByID = nil
  local f, status = W.v:Request(RING, function() error("never called") end)
  assertNil(f); assertEqual(status, "unavailable")
end)

test("verdict facts: stood down, the cache and the loads are dropped and a late answer is ignored", function()
  local W = world(function(m)
    m.addItem(CHEST, chest())
    m.addItem(RING, ring({ loadsNeeded = 1 }))
  end)
  W.v:Facts(CHEST)
  local called = false
  W.v:Request(RING, function() called = true end)
  W.v:StandDown()
  assertNil(W.v.__facts, "the cache is dropped")
  W.timers(); W.timers()
  assertFalse(called, "a load from before the stand-down is ignored")
  W.v:StandUp()
  assertEqual((W.v:FactsCounts()), 0)
  assertEqual(W.v:Facts(RING).name, "Band")
end)

-- ---------------------------------------------------------------------------------------------
-- The link (lib.ItemRead) and the level and quality reads
-- ---------------------------------------------------------------------------------------------

local FULL = "|cnIQ4:|Hitem:159617::::::::80:577::35:5:10390:6652:10383:10254:1520:1:28:2462:::::|h[Plumage]|h|r"
local BARE = "|cnIQ3:|Hitem:159617::::::::80:577::35::::::::|h[Plumage]|h|r"
local BAGGED = "|cnIQ4:|Hitem:159617:::::::12345:80:577::35:5:10390:6652:10383:10254:1520:1:28:2462:::::|h[Plumage]|h|r"

test("verdict facts: LinkDetail, BetterLink and IdentityKey read how complete a link is", function()
  local IR = T.mocks.LibStub("LibKa0s-Verdict-1.0").ItemRead
  local d = IR.LinkDetail(FULL)
  assertEqual(d.itemID, 159617); assertEqual(d.context, 35)
  assertEqual(table.concat(d.bonusIDs, ","), "10390,6652,10383,10254,1520")
  assertEqual(d.numModifiers, 1); assertEqual(d.modifiers[28], 2462); assertTrue(d.complete)
  local bare = IR.LinkDetail(BARE)
  assertFalse(bare.complete); assertTrue(d.score > bare.score)
  assertEqual(IR.LinkDetail("item:42").itemID, 42); assertNil(IR.LinkDetail(nil))
  local hole = IR.LinkDetail("item:159617::::::::80:577::35:2:10390::1:28:2462:::::")
  assertEqual(#hole.bonusIDs, 1, "an empty bonus id field keeps the list dense"); assertEqual(hole.modifiers[28], 2462)
  assertEqual(IR.BetterLink(BARE, FULL), FULL); assertEqual(IR.BetterLink(FULL, BAGGED), FULL, "a tie keeps the first")
  assertEqual(IR.BetterLink(BARE, "nonsense"), BARE); assertNil(IR.BetterLink(nil, nil))
  assertEqual(IR.IdentityKey(FULL), "159617|1520,6652,10254,10383,10390")
  assertEqual(IR.IdentityKey(FULL), IR.IdentityKey(BAGGED))
  assertTrue(IR.IdentityKey(FULL) ~= IR.IdentityKey(BARE))
end)

test("verdict facts: the level reads, gear's detailed else base, a bag location exact; the quality", function()
  local W = world(function(m)
    m.addItem(FULL, { name = "Plumage", quality = 4, ilvl = 19, effectiveIlvl = 311, equipLoc = "INVTYPE_TRINKET",
      classID = 4, subClassID = 0, bindType = 1, stats = {} })
    m.addItem(BARE, { name = "Plumage", quality = 3, ilvl = 19, equipLoc = "INVTYPE_TRINKET",
      classID = 4, subClassID = 0, bindType = 1, stats = {} })
    m.bagItemReads["0:3"] = { ilvl = 311, quality = 4 }
  end)
  local v = W.v
  assertEqual(select(2, v:EffectiveItemLevel(FULL)), "detailed")
  assertEqual(v:EffectiveItemLevel(FULL), 311)
  assertEqual(v:EffectiveItemLevel({ bag = 0, slot = 3 }), 311)
  assertEqual(v:ItemLevelAt(0, 3), 311); assertEqual(select(2, v:QualityAt(0, 3)), "location")
  assertNil(v:ItemLevelAt(0, 4))
  W.m.C_Item.GetDetailedItemLevelInfo = function() return nil end
  local level, source = v:EffectiveItemLevel(FULL)
  assertEqual(level, 19); assertEqual(source, "base")
  assertEqual(v:QualityOf(BARE), 3, "a bare link answers the base item")
  W.m.items[FULL].loadsNeeded = 1
  local q, qs = v:QualityOf(FULL)
  assertEqual(q, 4); assertEqual(qs, "link", "uncached: the color")
end)
