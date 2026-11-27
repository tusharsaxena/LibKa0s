-- LibKa0s-Verdict-1.0 -- "what is this item to me": the upgrade verdict engine. This file is the
-- shell: the major, its MODULES registry and the instance constructor. The pure kernel is in the
-- secondary files loaded after it, each paired on this file's minor:
--
--   VerdictConstants.lua  the item, slot and quality numbers the kernel reads (lib.C)
--   VerdictClassData.lua  the class lists, one per client (lib.ClassData)
--   VerdictTierTokens.lua tier tokens judged as gear (lib.TierTokens)
--   VerdictEvaluate.lua   the kernel and the off-spec pass (lib.Evaluate, lib.Equippability,
--                         lib.ItemVerdict, lib.TrackDelta, lib.SubClassKey, lib.OffSpec)
--
-- == WHY THIS EXISTS ===========================================================================
--
-- Ka0s Drop Watcher grew a verdict engine for its loot feed: is a drop an upgrade, a sidegrade, a
-- downgrade, or something you cannot use, for you or for another member of your group. Its Item
-- Search then judged every item it showed with the same engine, and Item Search leaves Drop Watcher
-- to become Ka0s Item Search (DropWatcher#19). Both addons need the same answer for the same item,
-- so the engine is promoted here, once, on the owner's ruling (R4 of Drop Watcher's
-- docs/superpowers/specs/2026-11-27-itemsearch-split-design.md), rather than copied into the second
-- addon. The code is Drop Watcher's, moved: modules/Evaluate.lua, modules/OffSpec.lua,
-- modules/TierTokens.lua, core/ClassData.lua, core/ClassDataForever.lua, the tier token parts of
-- core/TextParse.lua and the subset of core/Constants.lua they read, pinned on both sides by the
-- same golden table (tests/fixtures/verdict_golden.lua).
--
-- == THE CLIENT IS THE CALLER'S ================================================================
--
-- Drop Watcher picked its class list, slot plans and off-spec gate once, at file load, from the
-- client it runs on. A library shared through LibStub cannot: the client is named per call.
-- `opts.client` ("retail" | "forever") picks the class list, the ranged slot plans and the off-spec
-- gate of an evaluation; left out, the class list and the slot plans are Retail's and the off-spec
-- pass does not run (no client named, no off-spec). The verdict mode stays the caller's
-- (`opts.verdictMode`). Nothing here reads the client it runs on, so a suite judges both clients'
-- lists on one profile.
--
-- == THE INSTANCE ==============================================================================
--
-- `Verdict:New(host)` answers an instance bound to one host: `host.client` names its client and
-- the rest of the host contract (config, reads, events, onChange) is the instance API's, which the
-- reads, facts, gear, score and collection files add. Until they load an instance carries its
-- client and nothing else.
--
-- == DEPENDENCIES ==============================================================================
--
-- LibStub and LibKa0s-Core-1.0 minor 1 or newer, for the same reason Glow and Charts gate on it: a
-- partial payload gets every module absent rather than a working half. Nothing here is a protected
-- call, so it works in combat.

local core = LibStub and LibStub("LibKa0s-Core-1.0", true)
local NEEDS_CORE = 1
if not core or (core.MINOR or 0) < NEEDS_CORE then return end   -- no NewLibrary; module absent

-- Minor 1 (DropWatcher#19, task B1 of Drop Watcher's
-- docs/superpowers/plans/2026-11-27-itemsearch-split.md): the shell and the pure kernel.
local MAJOR, MINOR = "LibKa0s-Verdict-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.MAJOR, lib.MINOR = MAJOR, MINOR

lib.MODULES = lib.MODULES or {}
lib.MODULES.Verdict = MINOR

--- The clients an instance may name.
lib.CLIENTS = { retail = true, forever = true }

-- The instance methods, shared by every instance. The instance API's files add to this table, so
-- an instance built before they load still answers what they add.
lib.__methods = lib.__methods or {}
local methods = lib.__methods
local instanceMeta = { __index = methods }

--- An instance bound to `host` (see the header). Raises on a host that is not a table or names no
--- known client: a host that cannot say which client it judges for has no verdict to give.
--- @param host table { client = "retail" | "forever", ... }
--- @return table
function lib:New(host)
  if type(host) ~= "table" then error(MAJOR .. ": New(host) needs a host table", 2) end
  if not lib.CLIENTS[host.client] then
    error(MAJOR .. ": host.client must be \"retail\" or \"forever\", got " .. tostring(host.client), 2)
  end
  return setmetatable({ host = host, client = host.client }, instanceMeta)
end

--- The instance's client ("retail" | "forever").
--- @return string
function methods:Client() return self.client end
