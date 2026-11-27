-- tests/fixture_feed.lua -- the bench the LibKa0s-Feed-1.0 suites share.
--
-- Every case runs on a fresh environment with the kit's paint recorder (so regions and children
-- are distinct, recording objects), Core and the feed's four files loaded (and Media,
-- Skin and Widgets when the case asks for the skinned path). CreateFrame is wrapped so each frame
-- records what the feed tells it (strata, toplevel, clamp, mouse, points and how many SetPoint calls,
-- alpha, size, scripts) and answers the getters from that record: the kit's universal frame answers
-- those with the frame itself, which would make every placement assertion vacuous.
--
-- Time is the kit's settable clock (`m.__now`). `F.step(feed, dt)` moves it forward and fires the
-- clock's OnUpdate when one is armed; `F.clock(feed)` is that armed, unparented frame or nil;
-- `F.rows(feed)` lists the rows on screen, newest first.

local Loader = (_G.LK_TEST and _G.LK_TEST.loader) or dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")
local installPaint = dofile("tests/_kit/mock_paint.lua")

local F = {}
F.MAJOR = "LibKa0s-Feed-1.0"
F.FILES = { "LibKa0s/Feed.lua", "LibKa0s/FeedModel.lua", "LibKa0s/FeedRow.lua", "LibKa0s/FeedInput.lua" }

-- The environment each feed was made in, so the helpers take a feed alone.
local ENV = setmetatable({}, { __mode = "k" })

--- Record what the feed sets on `f`, and answer the getters from the record.
local BACKDROP_METHODS = { "SetBackdrop", "GetBackdrop", "SetBackdropColor", "GetBackdropColor",
  "SetBackdropBorderColor", "GetBackdropBorderColor" }

local function instrument(f)
  rawset(f, "__setPoints", 0)
  -- A plain frame has no backdrop in the client: only BackdropTemplate brings SetBackdrop, and the
  -- Skin major paints the two differently (P.hasBackdrop). The paint recorder gives every frame one.
  if not tostring(rawget(f, "__template") or ""):find("BackdropTemplate", 1, true) then
    for _, k in ipairs(BACKDROP_METHODS) do rawset(f, k, nil) end
  end
  rawset(f, "SetFrameStrata", function(self, s) rawset(self, "__strata", s) end)
  rawset(f, "GetFrameStrata", function(self) return rawget(self, "__strata") or "MEDIUM" end)
  rawset(f, "SetToplevel", function(self, v) rawset(self, "__toplevel", v) end)
  rawset(f, "SetClampedToScreen", function(self, v) rawset(self, "__clamped", v) end)
  rawset(f, "SetMovable", function(self, v) rawset(self, "__movable", v) end)
  rawset(f, "EnableMouse", function(self, v) rawset(self, "__mouse", v) end)
  rawset(f, "IsMouseEnabled", function(self) return rawget(self, "__mouse") == true end)
  rawset(f, "SetAlpha", function(self, a) rawset(self, "__alpha", a) end)
  rawset(f, "GetAlpha", function(self) return rawget(self, "__alpha") or 1 end)
  rawset(f, "SetScale", function(self, s) rawset(self, "__scale", s) end)
  rawset(f, "GetScale", function(self) return rawget(self, "__scale") or 1 end)
  rawset(f, "SetSize", function(self, w, h) rawset(self, "__w", w); rawset(self, "__h", h) end)
  rawset(f, "SetWidth", function(self, w) rawset(self, "__w", w) end)
  rawset(f, "SetHeight", function(self, h) rawset(self, "__h", h) end)
  rawset(f, "ClearAllPoints", function(self) rawset(self, "__point", nil) end)
  rawset(f, "SetPoint", function(self, ...)
    rawset(self, "__point", { ... })
    rawset(self, "__setPoints", rawget(self, "__setPoints") + 1)
  end)
  rawset(f, "GetPoint", function(self)
    local p = rawget(self, "__point")
    if not p then return nil end
    return p[1], p[2], p[3], p[4], p[5]
  end)
  rawset(f, "SetFrameLevel", function(self, n) rawset(self, "__level", n) end)
  rawset(f, "GetFrameLevel", function(self) return rawget(self, "__level") or 0 end)
  rawset(f, "StartMoving", function(self) rawset(self, "__moving", true) end)
  rawset(f, "StopMovingOrSizing", function(self) rawset(self, "__moving", false) end)
  return f
end

-- The skinned path's files, in LibKa0s.xml order: Media, the whole Skin major and Widgets.
F.SKIN_FILES = { "Media", "MediaIcons", "Skin", "SkinOwnerTokens", "SkinDefs", "SkinDefsOthers", "SkinPaint",
  "SkinPaintExtras", "SkinPaintHud", "SkinAceConfirm", "SkinPaintControls", "SkinPaintNav", "Widgets" }

--- A font-object fake for CreateFont: records its face; a FontString given it answers its face.
local function fontFake(made)
  return function(name)
    local o = { name = name }
    function o:SetFont(path, size, flags) self.font = { path, size, flags } end
    function o:GetFont() return unpack(self.font or {}) end
    function o:SetShadowOffset(x, y) self.shadow = { x, y } end
    function o:SetShadowColor(r, g, b, a) self.shadowColor = { r, g, b, a } end
    made[#made + 1] = o
    return o
  end
end

-- The drag handle's two files, for `opts.widgets` (the unlock path), after the skinned path's.
F.HANDLE_FILES = { "WidgetsDragHandle", "WidgetsDragHandleTip" }

--- A fresh environment. `opts.skinned` also loads Media, the Skin major and Widgets (the skinned
--- path) with a CreateFont fake; `opts.widgets` adds the drag handle (and implies `skinned`);
--- `opts.before(m)` runs before any file loads (to install a stand-in or a client API).
function F.env(opts)
  opts = opts or {}
  if opts.widgets then opts.skinned = true end
  local m = buildMocks()
  installPaint(m)
  local create = m.CreateFrame
  m.__made = {}
  m.CreateFrame = function(...)
    local f = instrument(create(...))
    m.__made[#m.__made + 1] = f
    return f
  end
  m.__errors = {}
  m.geterrorhandler = function() return function(e) m.__errors[#m.__errors + 1] = e end end
  m.__now = m.__now or 0
  if opts.before then opts.before(m) end
  Loader.load("LibKa0s/Core.lua", nil, m)
  if opts.skinned then Loader.load("LibKa0s/CorePixel.lua", nil, m) end
  for _, file in ipairs(F.FILES) do Loader.load(file, nil, m) end
  if opts.skinned then
    m.__fontsMade = {}
    m.CreateFont = fontFake(m.__fontsMade)
    m.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
    for _, file in ipairs(F.SKIN_FILES) do Loader.load("LibKa0s/" .. file .. ".lua", nil, m) end
  end
  if opts.widgets then
    for _, file in ipairs(F.HANDLE_FILES) do Loader.load("LibKa0s/" .. file .. ".lua", nil, m) end
  end
  return m, m.LibStub(F.MAJOR, true)
end

--- A feed on a fresh environment. `content` records each call; `d` overrides the descriptor's
--- fields. Answers the feed, the environment, the content calls and the library.
function F.feed(d, opts)
  local m, Feed = F.env(opts)
  local calls = {}
  local desc = { content = function(spec, payload, key)
    calls[#calls + 1] = { spec = spec, payload = payload, key = key }
    if type(payload) == "table" then spec.title = payload.title end
  end }
  for k, v in pairs(d or {}) do desc[k] = v end
  local feed = Feed:New(desc)
  ENV[feed] = m
  return feed, m, calls, Feed
end

--- The environment `feed` was made in.
function F.mocks(feed) return ENV[feed] end

--- The feed's clock: the armed, unparented frame carrying an OnUpdate, or nil.
function F.clock(feed)
  local m = ENV[feed]
  if not m then return nil end
  for _, f in ipairs(m.__made) do
    if rawget(f, "__parent") == nil and f:GetScript("OnUpdate") then return f end
  end
  return nil
end

--- Move the clock `dt` seconds forward and fire the clock's OnUpdate when one is armed.
function F.step(feed, dt)
  local m = ENV[feed]
  m.__now = (m.__now or 0) + dt
  local f = F.clock(feed)
  if f then f:__fire("OnUpdate", dt) end
end

--- The rows on screen, newest first: the container's shown children, nearest the anchor first.
function F.rows(feed)
  local c = feed:Frame()
  if not c then return {} end
  local rows = {}
  for _, child in ipairs({ c:GetChildren() }) do
    if child:IsShown() and rawget(child, "__point") then rows[#rows + 1] = child end
  end
  table.sort(rows, function(a, b)
    return math.abs(rawget(a, "__point")[5] or 0) < math.abs(rawget(b, "__point")[5] or 0)
  end)
  return rows
end

--- Push `{ title = title or key }` under `key`.
function F.push(feed, key, title, opts) return feed:Push(key, { title = title or key }, opts) end

--- `seconds` of the clock in 0.05 s steps.
function F.settle(feed, seconds)
  local n = math.floor(seconds / 0.05 + 0.5)
  for _ = 1, n do F.step(feed, 0.05) end
end

--- The row frame (live or leaving) whose title string reads `title`, or nil.
function F.row(feed, title)
  local c = feed:Frame()
  if not c then return nil end
  for _, f in ipairs({ c:GetChildren() }) do
    if f:IsShown() and rawget(f, "__point") then
      for _, r in ipairs({ f:GetRegions() }) do
        if r.GetObjectType and r:GetObjectType() == "FontString" and r:GetText() == title then return f end
      end
    end
  end
  return nil
end

return F
