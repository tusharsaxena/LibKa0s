-- tests/fixture_verdict_client.lua -- a fresh client for a LibKa0s-Verdict-1.0 instance: its own
-- mock set, the majors the instance reads (Core, Compat, Role, Item and Verdict) loaded into it, and
-- a controllable client behind the reads, so the instance's facts, gear, score and collection reads
-- run end to end the way Ka0s Drop Watcher's suites drove its compat family (its tests/wow_mock.lua
-- and tests/wow_mock_collect.lua, whose item cache, tooltips, inventory, bags, talents and
-- collections this ports).
--
--   local W = FC.new{ client = "retail" | "forever", seed = function(m) ... end, host = { ... } }
--
-- W.m is the mock set, W.V the major loaded into it, W.v the instance (New on a host whose config is
-- W.config, whose events are W.events and whose onChange appends to W.changes). W.fire(event, ...)
-- delivers an event the instance registered (after W.v:StandUp()); W.timers() fires every pending
-- timer once and answers how many ran. W.link(id) is an item link, W.wear/W.carry/W.item seed the
-- item cache. A `client = "forever"` world sets WoW Forever's project constants and leaves Retail's
-- spec globals out, so LibKa0s-Role-1.0 reads talent trees; `m.seedTalents(specID, { {name, spent} })`
-- seeds them.
--
-- Mock fields (Drop Watcher's names): items[link] = def (addItem(link, def); def = { name, quality,
-- ilvl, effectiveIlvl, equipLoc, classID, subClassID, bindType, setID, stats, specs, unique,
-- transmog, loadsNeeded }); inventory.player[slot] = link; bags[bag] = { size, [slot] = link };
-- tooltips.inventory["unit:slot"], tooltips.hyperlink[link] = { lines = { { type, leftText } } };
-- upgradeInfo[link]; mounts = { byItem, collected }; pets = { byItem, counts }; toys, toysOwned;
-- cosmetic[link]; professions; itemSpells[link], spellTexts[spellID]; loadRequests (item ids asked).

local T = _G.LK_TEST
local Loader = T.loader
local buildMocks = dofile("tests/wow_mock.lua")
local MAJORS = dofile("tests/majors.lua")

local FC = {}

local WANTED = {
  ["LibKa0s-Core-1.0"] = true, ["LibKa0s-Compat-1.0"] = true, ["LibKa0s-Role-1.0"] = true,
  ["LibKa0s-Item-1.0"] = true, ["LibKa0s-Verdict-1.0"] = true,
}

local PATHS = {}
for _, m in ipairs(MAJORS) do
  if WANTED[m.major] then
    for _, file in ipairs(m.files) do PATHS[#PATHS + 1] = "LibKa0s/" .. file .. ".lua" end
  end
end
FC.PATHS = PATHS

--- A link for item `id`.
function FC.link(id) return ("|cnIQ4:|Hitem:%d::::::::90:::::|h[Item %d]|h|r"):format(id, id) end

--- An item definition: `over` adds or replaces fields.
function FC.def(equipLoc, ilvl, classID, subClassID, over)
  local d = { name = "Item", quality = 4, ilvl = ilvl, equipLoc = equipLoc, classID = classID,
    subClassID = subClassID, bindType = 1, stats = {} }
  for k, v in pairs(over or {}) do d[k] = v end
  return d
end

local CLASS_NAMES = {
  WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
  DEATHKNIGHT = "Death Knight", SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock",
  MONK = "Monk", DRUID = "Druid", DEMONHUNTER = "Demon Hunter", EVOKER = "Evoker",
}

local function cached(m, link)
  local d = m.items[link]
  if not d or (d.loadsNeeded or 0) > 0 then return nil end
  return d
end

local function installItems(m)
  m.items, m.loadRequests = {}, {}
  m.upgradeInfo, m.accountBound, m.accountBoundUE, m.cosmetic = {}, {}, {}, {}
  m.bagItemReads, m.itemSpells, m.spellTexts, m.spellLoadRequests = {}, {}, {}, {}
  function m.addItem(link, def)
    def.itemID = tonumber(link:match("item:(%d+)"))
    m.items[link] = def
    return link
  end
  m.C_Item = {
    GetItemInfo = function(link)
      local d = cached(m, link)
      if not d then return nil end
      return d.name, link, d.quality, d.ilvl, 1, "", "", 1, d.equipLoc or "", 0, 0, d.classID,
        d.subClassID, d.bindType or 0, 0, d.setID, false
    end,
    GetItemInfoInstant = function(link)
      local d = m.items[link]
      if not d then return nil end
      return d.itemID, "", "", d.equipLoc or "", 0, d.classID, d.subClassID
    end,
    GetDetailedItemLevelInfo = function(link)
      local d = cached(m, link)
      if d then return d.effectiveIlvl or d.ilvl, false, d.ilvl end
    end,
    GetItemStats = function(link) local d = cached(m, link); return d and d.stats end,
    GetItemSpecInfo = function(link) local d = cached(m, link); return d and d.specs end,
    GetItemUniquenessByID = function(link)
      local d = cached(m, link)
      if d and d.unique then return d.unique[1], d.unique[2], d.unique[3], d.unique[4] end
      return false
    end,
    GetItemUpgradeInfo = function(link) return m.upgradeInfo[link] end,
    IsItemBindToAccount = function(link) return m.accountBound[link] == true end,
    IsItemBindToAccountUntilEquip = function(link) return m.accountBoundUE[link] == true end,
    IsCosmeticItem = function(link) return m.cosmetic[link] == true end,
    DoesItemExist = function(loc) return m.bagItemReads[loc.bag .. ":" .. loc.slot] ~= nil end,
    GetCurrentItemLevel = function(loc) local r = m.bagItemReads[loc.bag .. ":" .. loc.slot]; return r and r.ilvl end,
    GetItemQuality = function(loc) local r = m.bagItemReads[loc.bag .. ":" .. loc.slot]; return r and r.quality end,
    GetItemSpell = function(link)
      local id = m.itemSpells[link]
      if id == nil then return nil end
      return "Spell", id
    end,
    -- The data arrives later, as in the client: on the next timer pass, ahead of LoadItem's callback.
    RequestLoadItemDataByID = function(id)
      m.loadRequests[#m.loadRequests + 1] = id
      m.C_Timer.After(0, function()
        for _, d in pairs(m.items) do
          if d.itemID == id and (d.loadsNeeded or 0) > 0 then d.loadsNeeded = d.loadsNeeded - 1 end
        end
      end)
    end,
  }
  m.ItemLocation = { CreateFromBagAndSlot = function(_, bag, slot) return { bag = bag, slot = slot } end }
  m.C_Spell = { GetSpellDescription = function(spellID) return m.spellTexts[spellID] end,
    RequestLoadSpellData = function(spellID) m.spellLoadRequests[#m.spellLoadRequests + 1] = spellID end }
  m.C_TransmogCollection = { PlayerHasTransmogByItemInfo = function(link)
    local d = cached(m, link)
    if d then return d.transmog == true end
    return false
  end }
  m.LOCALIZED_CLASS_NAMES_MALE, m.LOCALIZED_CLASS_NAMES_FEMALE = {}, {}
  for classFile, name in pairs(CLASS_NAMES) do
    m.LOCALIZED_CLASS_NAMES_MALE[classFile] = name
    m.LOCALIZED_CLASS_NAMES_FEMALE[classFile] = name
  end
end

local function installTooltips(m)
  m.ITEM_LEVEL = "Item Level %d"
  m.ITEM_CLASSES_ALLOWED = "Classes: %s"
  m.LIST_DELIMITER = ", "
  m.ITEM_UPGRADE_TOOLTIP_FORMAT_STRING = "Upgrade Level: %s %d/%d"
  m.ITEM_MOD_STRENGTH, m.ITEM_MOD_AGILITY, m.ITEM_MOD_INTELLECT = "%c%s Strength", "%c%s Agility", "%c%s Intellect"
  m.ITEM_SPELL_KNOWN = "Already known"
  m.ITEM_SPELL_TRIGGER_ONUSE = "Use:"
  m.LOCKED, m.ITEM_OPENABLE = "Locked", "<Right Click to Open>"
  m.INVTYPE_HEAD, m.INVTYPE_SHOULDER, m.INVTYPE_CHEST = "Head", "Shoulder", "Chest"
  m.INVTYPE_HAND, m.INVTYPE_LEGS = "Hands", "Legs"
  m.Enum = m.Enum or {}
  m.Enum.TooltipDataLineType = { ItemBinding = 20, RestrictedRaceClass = 21, ItemUpgradeLevel = 32,
    TradeTimeRemaining = 36, ItemLevel = 41 }
  m.tooltips = { bag = {}, inventory = {}, hyperlink = {} }
  m.C_TooltipInfo = {
    GetBagItem = function(bag, slot) return m.tooltips.bag[bag .. ":" .. slot] end,
    GetInventoryItem = function(unit, slot) return m.tooltips.inventory[unit .. ":" .. slot] end,
    GetHyperlink = function(link) return m.tooltips.hyperlink[link] end,
  }
end

local function installGear(m)
  m.inventory, m.bags = { player = {} }, {}
  m.GetInventoryItemLink = function(unit, slot)
    local worn = m.inventory[unit]
    return worn and worn[slot]
  end
  m.C_Container = {
    GetContainerNumSlots = function(bag) local b = m.bags[bag]; return b and b.size or 0 end,
    GetContainerItemLink = function(bag, slot) local b = m.bags[bag]; return b and b[slot] end,
  }
  m.specID = 250
  m.GetSpecialization = function() return 1 end
  m.GetSpecializationInfo = function() return m.specID, m.__context.spec end
  m.C_SpecializationInfo = {
    GetSpecialization = function() return 1 end,
    GetSpecializationInfo = function(i) if i == 1 then return m.specID, m.__context.class end end,
  }
  m.seedTalents = function(specID, groups)
    m.specID, m.talents = specID, groups or {}
    m.C_SpecializationInfo.GetActiveSpecGroup = function() return 1 end
    m.C_SpecializationInfo.GetCombatConfigIDForSpecGroup = function(group) if group == 1 then return 7001 end end
    m.C_Traits = {
      GetConfigInfo = function(id) if id == 7001 then return { treeIDs = { 801 } } end end,
      GetGroupDisplayInfoByTreeID = function(treeID)
        if treeID ~= 801 then return nil end
        local out = {}
        for i, g in ipairs(m.talents) do out[i] = { groupID = 11000 + i, displayName = g.name, orderIndex = i } end
        return out
      end,
      GetGroupCurrencyInfo = function(configID)
        if configID ~= 7001 then return nil end
        local out = {}
        for i, g in ipairs(m.talents) do out[i] = { traitNodeGroupID = 11000 + i, currencyInfos = { { spent = g.spent } } } end
        return out
      end,
    }
  end
end

local function installCollections(m)
  m.mounts = { byItem = {}, collected = {} }
  m.C_MountJournal = {
    GetMountFromItem = function(itemID) return m.mounts.byItem[itemID] end,
    GetMountInfoByID = function(mountID)
      local known = m.mounts.collected[mountID]
      if known == nil then return nil end
      return "Mount", 1000, 0, false, true, 0, false, false, nil, false, known
    end,
  }
  m.pets = { byItem = {}, counts = {} }
  m.C_PetJournal = {
    GetPetInfoByItemID = function(itemID)
      local species = m.pets.byItem[itemID]
      if not species then return nil end
      return "Pet", 0, 0, 0, "", "", false, false, true, true, true, 0, species
    end,
    GetNumCollectedInfo = function(speciesID)
      local c = m.pets.counts[speciesID]
      if not c then return nil end
      return c[1], c[2]
    end,
  }
  m.toys, m.toysOwned = {}, {}
  m.C_ToyBox = { GetToyInfo = function(itemID)
    if not m.toys[itemID] then return nil end
    return itemID, "Toy " .. itemID, 134400, false, false, 1
  end }
  m.PlayerHasToy = function(itemID) return m.toysOwned[itemID] == true end
  m.professions = {}
  m.GetProfessions = function()
    local p, out = m.professions, {}
    for i = 1, 5 do out[i] = p[i] and i or nil end
    return out[1], out[2], out[3], out[4], out[5]
  end
  m.GetProfessionInfo = function(index)
    local line = m.professions[index]
    if not line then return nil end
    return "Profession " .. line, 134400, 1, 100, 0, 0, line
  end
end

--- A Pawn fake (Drop Watcher's test_scoring shape): ready unless `pawn.ready == false`, an item's
--- data for any link unless `pawn.data[link] == false`, the drop's upgrade list `upgrades[link]`
--- (nil: not read yet) and an item's value `values[scale][link]`.
function FC.installPawn(m, pawn)
  m.PawnIsReady = function() return pawn.ready ~= false end
  m.PawnGetItemData = function(l)
    if pawn.data and pawn.data[l] == false then return nil end
    return { link = l }
  end
  m.PawnIsItemAnUpgrade = function(data) return pawn.upgrades and pawn.upgrades[data.link] end
  m.PawnFindScaleForSpec = function(classID, index) return "S" .. classID .. ":" .. index end
  m.PawnGetSingleValueFromItem = function(data, scale)
    return pawn.values and pawn.values[scale] and pawn.values[scale][data.link]
  end
end

--- A fresh world (see the header).
--- @param opts table { client, seed = fn(m), host = { field = value } }
--- @return table
function FC.new(opts)
  opts = opts or {}
  local client = opts.client or "retail"
  local m = buildMocks()
  installItems(m)
  installTooltips(m)
  installGear(m)
  installCollections(m)
  m.__context.class, m.__context.classToken, m.__context.level = "Rogue", "ROGUE", 80
  m.specID = 260
  -- A GlobalString read through `_G[name]` (Reads.GlobalString) reads this client's strings, not the
  -- harness's own global table.
  m._G = m
  Loader.loadAll(PATHS, nil, m)
  if client == "forever" then
    m.WOW_PROJECT_ID, m.WOW_PROJECT_CAMELOT = 18, 18
    m.GetSpecialization, m.GetSpecializationInfo = nil, nil
  end
  if opts.seed then opts.seed(m) end
  local W = { m = m, V = m.LibStub("LibKa0s-Verdict-1.0"), config = {}, events = {}, changes = {},
    registrations = {}, link = FC.link, def = FC.def }
  local host = {
    client = client, L = nil,   -- no locale: each word reads as its enUS self (TierTokens.WORDS)
    config = function() return W.config end,
    registerEvent = function(event, handler)
      W.events[event] = handler
      W.registrations[event] = (W.registrations[event] or 0) + 1   -- a second registration counts
    end,
    unregisterEvent = function(event) W.events[event] = nil end,
    onChange = function(kind, arg) W.changes[#W.changes + 1] = arg and (kind .. ":" .. tostring(arg)) or kind end,
  }
  for k, v in pairs(opts.host or {}) do host[k] = v end
  W.host = host
  W.v = W.V:New(host)
  function W.fire(event, ...)
    local h = W.events[event]
    if h then h(event, ...) end
  end
  function W.timers() return m.__fireTimers() end
  function W.item(id, d) return m.addItem(FC.link(id), d) end
  function W.wear(slot, id, d)
    m.addItem(FC.link(id), d)
    m.inventory.player[slot] = FC.link(id)
  end
  function W.carry(bag, slot, id, d)
    m.addItem(FC.link(id), d)
    m.bags[bag] = m.bags[bag] or { size = 16 }
    m.bags[bag][slot] = FC.link(id)
  end
  --- How many onChange calls of `kind` arrived (a `kind:arg` entry counts for its kind).
  function W.count(kind)
    local n = 0
    for _, c in ipairs(W.changes) do
      if c == kind or c:sub(1, #kind + 1) == kind .. ":" then n = n + 1 end
    end
    return n
  end
  return W
end

return FC
