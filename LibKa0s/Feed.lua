-- LibKa0s-Feed-1.0 -- the toast feed: a stack of short-lived rows, the newest at the anchor.
--
-- == WHY THIS EXISTS ==========================================================================
--
-- Ka0s Loot History's toasts (its issue #38) need a feed rather than an alert: up to ten rows on
-- screen at once, the newest at the anchor and the oldest dropped when the feed is full, each row
-- entering, holding and fading on one clock, a repeat of the same key merged into its row in place,
-- and the whole feed frozen while the pointer is over it. LibKa0s-Toast-1.0 is the other shape (the
-- oldest toast at the saved point, one timer per toast), and a feed mode there would be a behavior
-- flag that turns its members around, so this is a major of its own, promoted with one consumer on
-- the owner's ruling of 2026-11-27 (Loot History plan D24, ruling X1 of the #38 design).
-- docs/api/Feed/version-1.1.1-docs.md is the full contract and carries that record.
--
-- == THE CONTRACT =============================================================================
--
-- `Feed:New(d)` answers one feed instance. `d.content(spec, payload, key)` is the ONE presentation
-- argument: it fills a reused flat row spec (icon, tint, badge, title, count, prefix, up to three
-- secondary lines, sub, highlight) from the host's payload, or answers `false` to skip it.
-- `d.merge(old, new, key)` optionally reduces two payloads under one key. Everything else is a
-- value or a getter carrying a player's setting, in three grouped tables read once into a snapshot:
-- `d.layout` (where and how big), `d.motion` (how rows move) and `d.style` (how they look over the
-- owner's skin). There is no combat flag and no overflow option: a host holds the feed with Hold
-- and Release, and a full feed drops its oldest row.
--
-- == THE FILES ================================================================================
--
-- Three files, one major. This shell owns the constants, `New`, the instance state and the method
-- table, which it publishes as `lib.__methods`. FeedModel.lua is the pure half (no frames: the
-- snapshot, the layout math, the phase machine, merge and drain) behind `lib.__model`, and
-- FeedRow.lua builds and paints rows behind `lib.__row`. Both are paired on this file's minor and
-- read at call time, so a newer secondary reaches a feed on the next call.
--
-- Minor 1 (LootHistory#38, task S1 of the Feed build): the skeleton. Every instance member answers
-- its degraded value (the API document's degradation-stub table) until the engine lands.
--
-- == DEPENDENCIES =============================================================================
--
-- LibStub and LibKa0s-Core-1.0 minor 20 or newer (ClassColor's stand-in, for the class-colored
-- border and text). Pool, Media, Skin, Widgets and LibSharedMedia-3.0 are resolved at call time
-- behind type checks, with no floor. Nothing here is a protected call, so it works in combat.

local core = LibStub and LibStub("LibKa0s-Core-1.0", true)
local NEEDS_CORE = 20   -- ClassColor (Core minor 20)
if not core or (core.MINOR or 0) < NEEDS_CORE then return end   -- no NewLibrary; module absent

local MAJOR, MINOR = "LibKa0s-Feed-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.MAJOR, lib.MINOR = MAJOR, MINOR

lib.MODULES = lib.MODULES or {}
lib.MODULES.Feed = MINOR

-- The defaults a descriptor may leave out. Published so a host cites them rather than restating.
lib.STRATA = "HIGH"   -- frame-layering's T5 interactive toast tier
lib.SLOTS = {         -- the nine anchor slots, in reading order; never mutate it
  "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}
lib.MAX_QUEUE = 10      -- payloads waiting while frozen or held, the oldest dropped past it
lib.SHOWN = 5           -- rows on screen at once
lib.SHOWN_MAX = 10      -- the most rows layout.shown may ask for
lib.WIDTH = 320         -- px, the container's and every row's width
lib.ROW_HEIGHT = 48     -- px, the least a row is high
lib.ICON_SIZE = 36      -- px, clamped to the row's inner height
lib.PADDING = 6         -- px inside a row
lib.GAP = 5             -- px between rows
lib.SLOT_INSET = 20     -- px from the screen edge a slot keeps
lib.NUDGE_MAX = 600     -- UIParent units a nudge may move the feed from its slot, either way
lib.ENTER_TIME = 0.25   -- s, the enter
lib.HOLD = 5            -- s at full alpha
lib.FADE_TIME = 1       -- s, the fade
lib.MERGE_WINDOW = 3    -- s a key stays open to a merge after its last push
lib.PULSE_TIME = 0.6    -- s a merge pulses the border
lib.SLIDE_TIME = 0.15   -- s a row takes to reach a new Y when motion.smooth is on
lib.DROP_FADE = 0.2     -- s a dropped or dismissed row fades out over
lib.MAX_DT = 0.1        -- s, the most one tick advances, so a hitch never skips a row's life

-- == the instance =============================================================================

local STATE = setmetatable({}, { __mode = "k" })

local function state(self)
  local S = STATE[self]
  if not S then error(MAJOR .. ": call this on an instance from Feed:New", 3) end
  return S
end

local METHODS = {}

--- Show `payload` under `key` (nil never merges). Answers "new", "merged", "queued" or false.
function METHODS:Push(key, payload, opts)   -- luacheck: ignore 212
  state(self)
  return false
end

--- The live or waiting payload under `key`, or nil.
function METHODS:Get(key)   -- luacheck: ignore 212
  state(self)
  return nil
end

--- Replace the payload under `key` and repaint it in place. Answers whether a row took it.
function METHODS:Update(key, payload)   -- luacheck: ignore 212
  state(self)
  return false
end

--- Re-run `content` for the row under `key`. Answers whether there was one.
function METHODS:Repaint(key)   -- luacheck: ignore 212
  state(self)
  return false
end

--- Re-run `content` and the style paint for every live row.
function METHODS:RepaintAll()
  state(self)
end

--- Start the drop fade of the row under `key`. Answers whether there was one.
function METHODS:Dismiss(key)   -- luacheck: ignore 212
  state(self)
  return false
end

--- The stand-down: every row released, nothing waits, the clock disarmed, locked again.
function METHODS:Clear()
  state(self)
end

--- New payloads wait (merging there) until Release; live rows keep running.
function METHODS:Hold()
  state(self)
end

--- End a Hold and drain the waiting list.
function METHODS:Release()
  state(self)
end

--- Re-read every getter, re-snapshot layout, motion and style, re-anchor and repaint.
function METHODS:Refresh()
  state(self)
end

--- Push each `{ key, payload }` of `list` sticky, as preview rows. Answers how many showed.
function METHODS:Preview(list)   -- luacheck: ignore 212
  state(self)
  return 0
end

--- Drop only the preview rows.
function METHODS:ClearPreview()
  state(self)
end

--- Lock (true) or unlock (false) the feed for dragging. Answers whether it is now locked.
function METHODS:SetLocked(locked)   -- luacheck: ignore 212
  state(self)
  return true
end

function METHODS:IsLocked()
  state(self)
  return true
end

--- Let the pointer through every row (true), or take it again (false).
function METHODS:SetClickThrough(on)   -- luacheck: ignore 212
  state(self)
end

--- Dock the "test" or "sim" strip with the host's `text`, or hide it with nil.
function METHODS:SetStrip(kind, text)   -- luacheck: ignore 212
  state(self)
end

--- The keys on screen, newest first (`false` for a key-less row). A new table per call.
function METHODS:Visible()
  state(self)
  return {}
end

--- The feed's state, every field always present.
function METHODS:Stats()
  state(self)
  return {
    live = 0, waiting = 0, dropping = 0, frozen = false, held = false, locked = true,
    clickThrough = false, awake = false, shown = 0, built = false,
  }
end

--- The container once built, else nil.
function METHODS:Frame()
  state(self)
  return nil
end

--- Internal test seam, not contract: one tick of `dt` seconds, armed or not.
function METHODS:__Step(dt)   -- luacheck: ignore 212
  state(self)
end

--- A new feed. `d.content` is required; every other field is optional (see the API document).
function lib:New(d)   -- luacheck: ignore 212/self
  if type(d) ~= "table" or type(d.content) ~= "function" then
    error(MAJOR .. ": New(d): d.content(spec, payload, key) is required", 2)
  end
  local inst = {}
  for name, fn in pairs(METHODS) do inst[name] = fn end
  STATE[inst] = {
    d = d, live = {}, leaving = {}, waiting = {}, rows = {}, free = {}, entryFree = {}, byKey = {},
    frozen = false, held = false, locked = true, clickThrough = false, awake = false,
  }
  return inst
end

-- The method table every New copies, for this major's paired files and nobody else. Private: a
-- host calls methods on an instance.
lib.__methods = METHODS
