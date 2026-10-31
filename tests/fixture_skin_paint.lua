-- tests/fixture_skin_paint.lua — the bench tests/test_skin_paint.lua and
-- tests/test_skin_paint_controls.lua share: a fresh environment with the kit's paint recorder
-- installed and the Skin major loaded whole, a font-object fake, an optional LibSharedMedia fake,
-- and a CALL TRACER.
--
-- THE TRACER is what "a primitive's Ka0s Default paint is today's paint, call for call" is asserted
-- with. It wraps the paint methods of the objects it watches (and of every frame, texture and font
-- string created while it watches) and logs each call as one line: the object's watch id, the
-- method and its arguments, numbers to three places, a table by its contents (or by name, for the
-- tables a case names, such as Core's own SKIN), a function as "fn". Two runs that build the same
-- objects in the same order and make the same calls produce the same lines, so a primitive's trace
-- and the trace of the library code it stands for compare as two lists. Getters are not logged:
-- reading a frame is not painting it.

local Loader = dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")
local installPaint = dofile("tests/_kit/mock_paint.lua")

local F = {}

F.MAJOR = "LibKa0s-Skin-1.0"
F.FILES = { "Core", "Skin", "SkinOwnerTokens", "SkinDefs", "SkinDefsOthers", "SkinPaint", "SkinPaintExtras", "SkinPaintControls" }

--- A font-object fake for CreateFont: records its face and shadow; a FontString given it answers
--- its face through GetFont.
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

--- A fresh environment: mocks with the paint recorder, the font fake, and `files` (default: the
--- whole major after Core) loaded. `lsm` (a table "kind:key" -> path) installs a LibSharedMedia
--- fake first. Answers m, Skin.
function F.env(opts)
  opts = opts or {}
  local m = buildMocks()
  installPaint(m)
  m.__fontsMade = {}
  m.CreateFont = fontFake(m.__fontsMade)
  if opts.lsm then
    local LSM = m.LibStub:NewLibrary("LibSharedMedia-3.0", 1)
    LSM.Fetch = function(_, kind, key) return opts.lsm[kind .. ":" .. tostring(key)] end
  end
  for _, f in ipairs(opts.files or F.FILES) do Loader.load("LibKa0s/" .. f .. ".lua", nil, m) end
  return m, m.LibStub(F.MAJOR, true)
end

--- The shell of a newer vendored copy loading over `m`'s: Skin.lua, patched one minor up, then the
--- rest of the major, as a later copy's LibKa0s.xml would. A paired file whose guard ignores the
--- shell's minor stays behind on the old shell. Answers the new minor.
function F.bumpShell(m)
  local live = m.LibStub(F.MAJOR)
  local bumped = live.MINOR + 1
  local src, hits = Loader.readFile("LibKa0s/Skin.lua"):gsub(
    'local MAJOR, MINOR = "LibKa0s%-Skin%-1%.0", %d+',
    ('local MAJOR, MINOR = "%s", %d'):format(F.MAJOR, bumped))
  assert(hits == 1, "Skin.lua's minor line moved")
  Loader.loadSource(src, "Skin.lua+1", nil, m)
  assert(live.MINOR == bumped, "the patched shell upgraded in place")
  for _, f in ipairs(F.FILES) do
    if f ~= "Core" and f ~= "Skin" then Loader.load("LibKa0s/" .. f .. ".lua", nil, m) end
  end
  return bumped
end

--- A registered owner on `skin` (default Ka0s Default). Answers its facade.
function F.owner(Skin, name, skin)
  local S = Skin:RegisterOwner(name)
  if skin and skin ~= "ka0s" then Skin:SetChoice(name, "ka0s", skin) end
  return S
end

-- ── the tracer ───────────────────────────────────────────────────────────────────────────────

local TRACED = {
  "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetPoint", "ClearAllPoints",
  "SetAllPoints", "SetSize", "SetWidth", "SetHeight", "SetFrameLevel", "SetTextColor",
  "SetColorTexture", "SetVertexColor", "SetTexture", "SetGradient", "SetAlpha", "SetFont",
  "SetFontObject", "SetJustifyH", "SetTexCoord", "SetRotation", "SetText", "SetStatusBarColor",
  "SetTextInsets", "SetHorizTile", "SetVertTile", "Show", "Hide", "SetScript", "HookScript",
  "CreateTexture", "CreateFontString",
}

local function fmtNum(n)
  if n == math.floor(n) then return tostring(n) end
  return string.format("%.3f", n)
end

--- A new tracer. `names` maps tables to the name a line prints them by.
function F.tracer(m, names)
  local tr = { lines = {}, ids = {}, n = 0, names = names or {} }

  local function fmt(v, depth)
    local t = type(v)
    if t == "number" then return fmtNum(v) end
    if t == "string" then return string.format("%q", v) end
    if t == "function" then return "fn" end
    if t ~= "table" then return tostring(v) end
    if tr.names[v] then return tr.names[v] end
    if tr.ids[v] then return "#" .. tr.ids[v] end
    if (depth or 0) > 2 then return "{...}" end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = tostring(k) end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do
      local val = v[k]
      if val == nil then val = v[tonumber(k)] end
      parts[#parts + 1] = k .. "=" .. fmt(val, (depth or 0) + 1)
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end

  local function has(obj, method)
    local ok, fn = pcall(function() return obj[method] end)
    return ok and type(fn) == "function" and fn or nil
  end

  function tr.watch(obj)
    if type(obj) ~= "table" or tr.ids[obj] then return obj end
    tr.n = tr.n + 1
    tr.ids[obj] = tr.n
    for _, method in ipairs(TRACED) do
      local orig = has(obj, method)
      if orig then
        rawset(obj, method, function(self, ...)
          local args = {}
          for i = 1, select("#", ...) do args[i] = fmt((select(i, ...))) end
          tr.lines[#tr.lines + 1] = "#" .. (tr.ids[self] or "?") .. ":" .. method .. "(" .. table.concat(args, ",") .. ")"
          local a, b = orig(self, ...)
          if method == "CreateTexture" or method == "CreateFontString" then tr.watch(a) end
          return a, b
        end)
      end
    end
    return obj
  end

  -- Frames created while watching are watched too (the holder, Core's inner border).
  local prevCreate = m.CreateFrame
  m.CreateFrame = function(...)
    local f = prevCreate(...)
    if tr.on then
      tr.watch(f)
      tr.lines[#tr.lines + 1] = "CreateFrame(" .. fmt((select(1, ...))) .. ")->#" .. tr.ids[f]
    end
    return f
  end
  function tr.start() tr.on = true; tr.lines = {} end
  function tr.stop() tr.on = false end
  function tr.restore() m.CreateFrame = prevCreate end
  function tr.text() return table.concat(tr.lines, "\n") end
  return tr
end

--- The lines of `tr` whose method is one of `methods` (a set), in order.
function F.only(tr, methods)
  local out = {}
  for _, line in ipairs(tr.lines) do
    local method = line:match("^#%d+:([%w]+)%(")
    if method and methods[method] then out[#out + 1] = line end
  end
  return table.concat(out, "\n")
end

-- ── frames ───────────────────────────────────────────────────────────────────────────────────

--- A window as the library builds one: a BackdropTemplate frame with a title and a divider.
function F.window(m)
  local f = m.CreateFrame("Frame", nil, m.UIParent, "BackdropTemplate")
  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.divider = f:CreateTexture(nil, "ARTWORK")
  return f
end

--- The record's region `key` for `target`, or nil.
function F.region(Skin, target, key)
  local rec = Skin.painted[target]
  return rec and rec.regions[key]
end

--- A color as "r,g,b,a" at three places.
function F.rgba(c)
  if type(c) ~= "table" then return tostring(c) end
  local out = {}
  for i = 1, 4 do out[i] = fmtNum(c[i] or 1) end
  return table.concat(out, ",")
end

--- A token's color as "r,g,b,a".
function F.tok(Skin, skin, name) return F.rgba(Skin:ResolveSkin(skin)[name]) end

return F
