-- tests/fixture_feed.lua -- the bench the LibKa0s-Feed-1.0 suites share.
--
-- Every case runs on a fresh environment with the kit's paint recorder (so regions and children
-- are distinct, recording objects), Core and the feed's three files loaded (and Media,
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
F.FILES = { "LibKa0s/Feed.lua", "LibKa0s/FeedModel.lua", "LibKa0s/FeedRow.lua" }

-- The environment each feed was made in, so the helpers take a feed alone.
local ENV = setmetatable({}, { __mode = "k" })

--- Record what the feed sets on `f`, and answer the getters from the record.
local function instrument(f)
  rawset(f, "__setPoints", 0)
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
  rawset(f, "StartMoving", function(self) rawset(self, "__moving", true) end)
  rawset(f, "StopMovingOrSizing", function(self) rawset(self, "__moving", false) end)
  return f
end

--- A fresh environment. `opts.skinned` also loads Media, Skin and Widgets (the skinned path);
--- `opts.before(m)` runs before any file loads (to install a stand-in or a client API).
function F.env(opts)
  opts = opts or {}
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
  for _, file in ipairs(F.FILES) do Loader.load(file, nil, m) end
  if opts.skinned then
    for _, file in ipairs({ "LibKa0s/Media.lua", "LibKa0s/MediaIcons.lua", "LibKa0s/Skin.lua",
      "LibKa0s/Widgets.lua" }) do
      Loader.load(file, nil, m)
    end
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

return F
