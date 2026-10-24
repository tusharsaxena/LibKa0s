-- LibKa0s-Skin-1.0 — the skin engine: which skin each addon wears, what a token resolves to, and
-- the per-owner record of what was painted so a skin switch can repaint it live.
--
-- ── WHY THIS EXISTS ──────────────────────────────────────────────────────────────────────────
--
-- Every Ka0s window, panel, dialog and settings page is drawn from constants written into the
-- library and into each host (`Core.SKIN`, Widgets' file-local `SKIN`, the Options palettes, ~90
-- literals in LootHistory alone). A skin turns those constants into data: a token table, chosen per
-- addon (the owner's ruling R1), that every painter reads. Ka0s Default is today's constants, so a
-- host that never chooses another skin draws exactly what it drew before.
--
-- ── ONE LOADED COPY, MANY OWNERS ─────────────────────────────────────────────────────────────
--
-- LibStub keeps one copy of this major for the whole client, so every piece of state is keyed by
-- OWNER, the consumer's addon folder name, and written `lib.x = lib.x or {}` so a newer minor that
-- loads later keeps it. Two addons can show different skins at the same time, and one switching
-- never repaints the other's frames.
--
--   lib.skins[key]       the registered skin definitions (SkinDefs.lua registers them)
--   lib.owners[owner]    { label, get, set, source, skin, pendingReload, listeners }
--   lib.painted[frame]   weak-keyed: { owner, calls = { [prim] = args }, order = { prim, ... } }
--   lib.byOwner[owner]   weak-keyed set of that owner's painted frames
--   lib.facades[owner]   the owner's facade S, one table kept across minors
--   lib.prim[name]       the painting primitives, fn(owner, ...); SkinPaint.lua fills them
--
-- None of these is contract: they are named so the secondary files and a newer minor can find
-- them, and a host reads the skin only through the members below and the facade.
--
-- ── THE FACADE ───────────────────────────────────────────────────────────────────────────────
--
-- `Skin:For(owner)` answers `lib.facades[owner]`. Every entry is a late-bound trampoline:
-- `S.Button(...)` looks `lib.prim.Button` up AT CALL TIME and calls it as `(owner, ...)`. A host
-- caches S at file load; a newer minor that loads later re-fills `lib.prim` and re-fills every
-- facade's entries in place, so the cached S always runs the winning copy's code. Nothing in a
-- facade closure captures a primitive. A primitive no loaded file provides answers nil.
--
-- ── WHAT IT DELIBERATELY IS NOT ──────────────────────────────────────────────────────────────
--
--   * no painting: the primitives are SkinPaint.lua's; this file only records and replays them;
--   * no SavedVariables: the host stores { source, skin } in its own profile and hands the engine
--     a getter and a setter (`RegisterOwner`); `SetChoice` never writes the profile;
--   * no EllesmereUI calls: the `eui` provider is SkinEUI.lua's. Here `eui` is a stored choice
--     whose tokens fall back to the owner's Ka0s skin, and leaving it asks for a reload;
--   * no OnUpdate, no events: a repaint is one pass over the owner's recorded frames.
--
-- Depends on LibStub and LibKa0s-Core-1.0. No Core member is called; the gate keeps the payload's
-- presence a single question.

local core = LibStub and LibStub("LibKa0s-Core-1.0", true)
local NEEDS_CORE = 1
if not core or (core.MINOR or 0) < NEEDS_CORE then return end   -- no NewLibrary; module absent

local MAJOR, MINOR = "LibKa0s-Skin-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.MAJOR, lib.MINOR = MAJOR, MINOR

lib.MODULES = lib.MODULES or {}
lib.MODULES.Skin = MINOR

--- The stored value that means "take this setting from the skin" (the owner's ruling R3). A
--- profile key holding it resolves through `Resolve` to the owner's skin token.
lib.FROM_SKIN = "@skin"
--- The skin every owner wears until it chooses another, and the one an unknown key falls back to.
lib.DEFAULT = "ka0s"
--- The two skin sources: Ka0s's own skins, or EllesmereUI's (SkinEUI.lua).
lib.SOURCES = { "ka0s", "eui" }

-- The vocabulary the facade carries as trampolines into lib.prim: EllesmereUI's names first (its
-- SKINNING_API facade, API version 3), then the Ka0s extras.
lib.VOCAB = {
  "Shell", "Panel", "Inset", "FadeRegions", "FadeNineSlice", "Button", "WhiteButtonLabel",
  "StateButtonLabel", "EditBox", "Checkbox", "Dropdown", "ScrollBar", "Tab", "SetTabSelection",
  "CloseButton", "PageButton", "SquareIcon", "SortHeaderBar", "Font", "White", "ApplyBarFill",
  "GetAccentColor", "GetPanelColor", "GetFont",
  "TitleBar", "Divider", "Footer", "Card", "Slider", "NavItem", "Drawer", "ListRow", "MenuFrame",
  "Tooltip", "Strip", "Cover", "Text", "ChartStyle", "BarStyle", "IconBorder", "GlowColor",
}

local WEAK_KEYS = { __mode = "k" }

lib.skins    = lib.skins or {}
lib.__order    = lib.__order or {}
lib.owners   = lib.owners or {}
lib.painted  = lib.painted or setmetatable({}, WEAK_KEYS)
lib.byOwner  = lib.byOwner or {}
lib.facades  = lib.facades or {}
lib.prim     = lib.prim or {}
-- The resolved token tables, one per skin key. A cache, rebuilt on demand: emptied here so a newer
-- minor's resolution rules apply, and by RegisterSkin because a skin derives from Ka0s Default.
lib.__resolved = {}

local SOURCE_OK = { ka0s = true, eui = true }

--- Hand `err` to the client's error handler and carry on: one raising listener or primitive must
--- not stop the repaint of every frame after it.
local function report(err)
  local h = type(geterrorhandler) == "function" and geterrorhandler()
  if type(h) == "function" then h(err) end
end

local function requireOwner(owner, what)
  if type(owner) ~= "string" or owner == "" then
    error(MAJOR .. ": " .. what .. " needs an owner (the addon folder name)", 3)
  end
end

-- ── skins ────────────────────────────────────────────────────────────────────────────────────

--- Register a skin: `{ key, label, desc, swatches = { 4 hex }, tokens = {...} }`. A second
--- registration of a key replaces the first (a newer SkinDefs.lua re-registering its skins).
--- Answers the stored definition.
function lib:RegisterSkin(def)
  if type(def) ~= "table" or type(def.key) ~= "string" or def.key == "" then
    error(MAJOR .. ": RegisterSkin needs a table with a string key", 2)
  end
  if type(def.tokens) ~= "table" then
    error(MAJOR .. ": RegisterSkin('" .. def.key .. "') needs a tokens table", 2)
  end
  if not self.skins[def.key] then self.__order[#self.__order + 1] = def.key end
  def.label = type(def.label) == "string" and def.label or def.key
  def.desc = type(def.desc) == "string" and def.desc or ""
  def.swatches = type(def.swatches) == "table" and def.swatches or {}
  self.skins[def.key] = def
  self.__resolved = {}
  return def
end

--- The registered definition for `key`, or nil.
function lib:GetSkin(key)
  return self.skins[key]
end

--- Every registered skin's definition, in registration order (Ka0s Default first). A fresh array
--- of the stored definitions: read `key`, `label`, `desc` and `swatches`, never write them.
function lib:Skins()
  local out = {}
  for _, key in ipairs(self.__order) do
    if self.skins[key] then out[#out + 1] = self.skins[key] end
  end
  return out
end

--- The schema kind of a token name, or nil (lib.SCHEMA, from SkinDefs.lua).
local function kindOf(name)
  local idx = lib.__schemaIndex
  local entry = idx and idx[name]
  return entry and entry.kind
end

local function overlay(out, tokens)
  for name, v in pairs(tokens) do out[name] = v end
end

-- `false` is how a skin says "none" for a token Ka0s Default sets (a skin with no inner rule);
-- it resolves to nil. A bool token keeps its false.
local function dropNone(out)
  for name, v in pairs(out) do
    if v == false and kindOf(name) ~= "bool" then out[name] = nil end
  end
end

--- The skin key a choice actually draws: the key itself when registered, else Ka0s Default.
local function effectiveKey(key)
  if type(key) == "string" and lib.skins[key] then return key end
  return lib.DEFAULT
end

--- The complete token table of a skin: Ka0s Default's tokens with the skin's own over them. An
--- unregistered key resolves as Ka0s Default. Cached; the table is shared, so never write to it.
function lib:ResolveSkin(key)
  key = effectiveKey(key)
  local out = self.__resolved[key]
  if out then return out end
  out = {}
  local base = self.skins[self.DEFAULT]
  if base then overlay(out, base.tokens) end
  if key ~= self.DEFAULT and self.skins[key] then overlay(out, self.skins[key].tokens) end
  dropNone(out)
  self.__resolved[key] = out
  return out
end

-- ── owners and their choice ──────────────────────────────────────────────────────────────────

--- Read a host getter's answer: `{ source, skin }`, or two values.
local function readChoice(get)
  if type(get) ~= "function" then return end
  local ok, a, b = pcall(get)
  if not ok then report(a); return end
  if type(a) == "table" then return a.source or a[1], a.skin or a[2] end
  return a, b
end

local function cleanSource(source)
  if SOURCE_OK[source] then return source end
  return "ka0s"
end

local function cleanSkin(skin)
  if type(skin) == "string" and skin ~= "" then return skin end
  return lib.DEFAULT
end

--- Register `owner` (the addon folder name) at the consumer's file load. `opts.get()` answers the
--- profile's `{ source, skin }`; `opts.set(source, skin)` writes it (copy to every Ka0s addon);
--- `opts.label` names the addon to the player. The choice is read once, here; afterwards it moves
--- only through `SetChoice`. A second call updates the hooks and keeps the applied choice.
--- Answers the owner's facade.
function lib:RegisterOwner(owner, opts)
  requireOwner(owner, "RegisterOwner")
  opts = type(opts) == "table" and opts or {}
  local o = self.owners[owner]
  if not o then
    local source, skin = readChoice(opts.get)
    o = { source = cleanSource(source), skin = cleanSkin(skin), listeners = {} }
    self.owners[owner] = o
  end
  o.get = type(opts.get) == "function" and opts.get or o.get
  o.set = type(opts.set) == "function" and opts.set or o.set
  o.label = type(opts.label) == "string" and opts.label or o.label or owner
  return self:For(owner)
end

--- True only for an owner that called RegisterOwner. Every factory that takes an owner paints
--- today's way, verbatim, for a name that is not one.
function lib:IsOwner(owner)
  return type(owner) == "string" and self.owners[owner] ~= nil
end

--- The registered owners, sorted.
function lib:Owners()
  local out = {}
  for name in pairs(self.owners) do out[#out + 1] = name end
  table.sort(out)
  return out
end

--- The owner's applied choice: source, skin. An unregistered owner answers "ka0s", "ka0s".
function lib:GetChoice(owner)
  local o = self.owners[owner]
  if not o then return "ka0s", self.DEFAULT end
  return o.source, o.skin
end

--- True once an owner left the `eui` source this session: EllesmereUI's paint is one-way, so only a
--- reload removes it.
function lib:PendingReload(owner)
  local o = self.owners[owner]
  return o ~= nil and o.pendingReload == true
end

--- Fire the owner's OnLooksChanged listeners, each under pcall.
local function notify(o)
  for _, fn in ipairs(o.listeners) do
    local ok, err = pcall(fn, o.source, o.skin)
    if not ok then report(err) end
  end
end

--- Move `owner` to (source, skin); nil keeps that half. Idempotent: a choice equal to GetChoice
--- does nothing. Otherwise the new skin is resolved first, every frame recorded for the owner is
--- repainted, and the owner's OnLooksChanged listeners fire. Leaving `eui` cannot repaint
--- (EllesmereUI's paint is one-way): the choice is stored, the owner's pending-reload flag is set,
--- and nothing is repainted. Never writes the host's profile.
--- Answers changed, reload: `reload` is true exactly once per owner, on the switch that first
--- needs a reload, so a caller raises its reload popup at most once.
function lib:SetChoice(owner, source, skin)
  requireOwner(owner, "SetChoice")
  local o = self.owners[owner]
  if not o then return false, false end
  source = source == nil and o.source or cleanSource(source)
  skin = skin == nil and o.skin or cleanSkin(skin)
  if source == o.source and skin == o.skin then return false, false end
  local leavingEUI = o.source == "eui" and source ~= "eui"
  o.source, o.skin = source, skin
  self:ResolveSkin(skin)
  if leavingEUI then
    local first = not o.pendingReload
    o.pendingReload = true
    return true, first
  end
  if o.pendingReload then return true, false end
  self:Repaint(owner)
  notify(o)
  return true, false
end

--- Call `fn(source, skin)` after each change of the owner's skin. Registering the same function
--- twice keeps one entry. Answers fn.
function lib:OnLooksChanged(owner, fn)
  requireOwner(owner, "OnLooksChanged")
  if type(fn) ~= "function" then return end
  local o = self.owners[owner]
  if not o then return end
  for _, have in ipairs(o.listeners) do
    if have == fn then return fn end
  end
  o.listeners[#o.listeners + 1] = fn
  return fn
end

-- ── tokens ───────────────────────────────────────────────────────────────────────────────────

--- The owner's resolved token `name`: a color is `{ r, g, b, a }`, shared, never written to. An
--- unregistered owner reads Ka0s Default. nil for a token the skin leaves alone.
function lib:Token(owner, name)
  local _, skin = self:GetChoice(owner)
  return self:ResolveSkin(skin)[name]
end

--- The owner's color token as r, g, b, a (alpha 1 when the token has three components), or nil.
function lib:Color(owner, name)
  local c = self:Token(owner, name)
  if type(c) ~= "table" then return nil end
  return c[1], c[2], c[3], c[4] or 1
end

--- True when `value` is the FROM_SKIN sentinel.
function lib.IsFromSkin(value)
  return value == lib.FROM_SKIN
end

--- `value`, or the owner's token `kind` when `value` is the FROM_SKIN sentinel or `fromSkin` (a
--- setting's companion "follow the skin" bool) is true.
function lib:Resolve(owner, kind, value, fromSkin)
  if value == self.FROM_SKIN or fromSkin == true then return self:Token(owner, kind) end
  return value
end

--- Walk a dotted path ("font.face") to the table holding its last segment.
local function walk(t, path)
  local segs = {}
  for seg in path:gmatch("[^%.]+") do segs[#segs + 1] = seg end
  if #segs == 0 then return nil end
  local parent = t
  for i = 1, #segs - 1 do
    parent = parent[segs[i]]
    if type(parent) ~= "table" then return nil end
  end
  return parent, segs[#segs]
end

--- Put every listed key of `profile` back on the skin (the owner's ruling R3). A key holding a
--- color (a table) keeps its color and gets its companion `<key>FromSkin = true`; any other key
--- takes the FROM_SKIN sentinel. Keys may be dotted paths into nested tables; a path whose table
--- does not exist is skipped. Answers how many keys it set. Called as `Skin.ResetToSkin(p, keys)`.
function lib.ResetToSkin(profile, keys, extra)
  if profile == lib then profile, keys = keys, extra end
  if type(profile) ~= "table" or type(keys) ~= "table" then return 0 end
  local n = 0
  for _, path in ipairs(keys) do
    local parent, leaf = walk(profile, tostring(path))
    if type(parent) == "table" then
      if type(parent[leaf]) == "table" then
        parent[leaf .. "FromSkin"] = true
      else
        parent[leaf] = lib.FROM_SKIN
      end
      n = n + 1
    end
  end
  return n
end

-- ── the frame registry and the repaint ───────────────────────────────────────────────────────

local function ownerSet(owner)
  local set = lib.byOwner[owner]
  if not set then
    set = setmetatable({}, WEAK_KEYS)
    lib.byOwner[owner] = set
  end
  return set
end

--- Record that primitive `prim` painted `frame` for `owner` with these arguments, so a skin
--- switch can replay it. One record per frame; a frame painted for a second owner moves to it.
--- Repeating a primitive replaces its arguments and keeps its place in the replay order. Called
--- by the primitives; answers the record, whose `regions` table is the primitive's own.
function lib:Track(owner, frame, prim, ...)
  requireOwner(owner, "Track")
  if type(frame) ~= "table" or type(prim) ~= "string" then return nil end
  local rec = self.painted[frame]
  if rec and rec.owner ~= owner then
    local old = self.byOwner[rec.owner]
    if old then old[frame] = nil end
    rec = nil
  end
  if not rec then
    rec = { owner = owner, calls = {}, order = {}, regions = {} }
    self.painted[frame] = rec
  end
  if not rec.calls[prim] then rec.order[#rec.order + 1] = prim end
  rec.calls[prim] = { n = select("#", ...), ... }
  ownerSet(owner)[frame] = true
  return rec
end

--- Forget `frame` (a pooled widget handed back): it is no longer repainted for anyone.
function lib:Untrack(frame)
  local rec = self.painted[frame]
  if not rec then return end
  local set = self.byOwner[rec.owner]
  if set then set[frame] = nil end
  self.painted[frame] = nil
end

--- Replay one frame's primitives, in the order they first painted it.
local function replay(owner, frame, rec)
  local calls = 0
  for _, name in ipairs(rec.order) do
    local fn, args = lib.prim[name], rec.calls[name]
    if type(fn) == "function" and args then
      local ok, err = pcall(fn, owner, frame, unpack(args, 1, args.n))
      if not ok then report(err) end
      calls = calls + 1
    end
  end
  return calls
end

--- Re-run every primitive recorded for `owner`'s frames with the owner's current skin, each frame
--- once. `lib.__repainting` is true while it runs, so a primitive can tell a repaint from a first
--- paint. Answers the number of primitive calls made.
function lib:Repaint(owner)
  local set = self.byOwner[owner]
  if not set then return 0 end
  local frames = {}
  for frame in pairs(set) do frames[#frames + 1] = frame end
  local calls, was = 0, self.__repainting
  self.__repainting = true
  for _, frame in ipairs(frames) do
    local rec = self.painted[frame]
    if rec and rec.owner == owner then calls = calls + replay(owner, frame, rec) end
  end
  self.__repainting = was
  return calls
end

-- ── the facade ───────────────────────────────────────────────────────────────────────────────

local function trampoline(owner, name)
  return function(...)
    local fn = lib.prim[name]
    if fn then return fn(owner, ...) end
  end
end

--- (Re)fill S's entries with this minor's closures, in place: a host's cached S keeps working
--- across a minor upgrade. Every closure reaches `lib` at call time and captures only the owner
--- and a name.
local function fillFacade(S, owner)
  S.owner, S.apiVersion, S.FROM_SKIN = owner, 3, lib.FROM_SKIN
  for _, name in ipairs(lib.VOCAB) do S[name] = trampoline(owner, name) end
  S.Token = function(name) return lib:Token(owner, name) end
  S.Color = function(name) return lib:Color(owner, name) end
  S.Resolve = function(kind, value, fromSkin) return lib:Resolve(owner, kind, value, fromSkin) end
  S.OnLooksChanged = function(fn) return lib:OnLooksChanged(owner, fn) end
  S.IsEnabled = function() return lib:IsOwner(owner) end
  S.GetStyle = function()
    local _, skin = lib:GetChoice(owner)
    return "ka0s:" .. effectiveKey(skin)
  end
  return S
end

--- The owner's facade S: the painting vocabulary bound to `owner`, plus Token, Color, Resolve,
--- OnLooksChanged, IsEnabled, GetStyle, apiVersion and FROM_SKIN. One table per owner, kept for
--- the session. Does not register the owner: an unregistered owner's facade reads Ka0s Default.
function lib:For(owner)
  requireOwner(owner, "For")
  local S = self.facades[owner]
  if not S then
    S = fillFacade({}, owner)
    self.facades[owner] = S
  end
  return S
end

-- A newer minor re-fills every facade an older one built, so the hosts' cached tables run this
-- copy's trampolines.
for owner, S in pairs(lib.facades) do fillFacade(S, owner) end
