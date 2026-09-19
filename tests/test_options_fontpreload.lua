-- tests/test_options_fontpreload.lua — Options minor 17: every LibSharedMedia font is loaded the
-- first time any Ka0s settings panel is shown.
--
-- THE BUG. AceGUI-3.0-SharedMediaWidgets' `LSM30_Font` (the dialogControl `O.FontGroup` writes)
-- builds its pull-out list on open: `f.text:SetFont(font, size, outline); f.text:SetText(k)` for
-- every face. The client loads a font file on its first reference, and text set with a face that is
-- not loaded yet draws blank until something sets it again. So the first open of any font dropdown
-- in a session showed a blank row for every face nothing had used yet, and the second open was
-- fine. The widget is upstream and vendored, so the fix is to have the files loaded before the list
-- can be opened: by the time a user can click a dropdown, a panel has been shown.
--
-- WHY A SUITE OF ITS OWN. `tests/test_options.lua` is in the 1000–1500 band CLAUDE.md keeps on
-- notice, and the preload's state is LIBRARY-level — shared by every host — which no other Options
-- suite has to reset between cases. Keeping the reset here keeps it out of every other case.
--
-- The kit's `CreateFontString` answers the frame itself (testkit/mock_base.lua's known divergence),
-- so a SetFont on it cannot be read back. Every case therefore spies `CreateFrame` and gives each
-- frame a font-string factory whose strings record what they were told, which is how the widget
-- suites spy on fonts too.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local mocks = T.mocks
local Fixture = dofile("tests/fixture_options.lua")

local lib = T.options

--- A font string that records SetFont / SetText and no-ops every other capitalized method, the
--- way the kit's frames do. `log.raiseOn[path]` makes SetFont raise for that path, the way the
--- client can for a file it cannot open.
local function recordingFontString(owner, log)
  local fs = { __owner = owner }
  function fs:SetFont(path, size, flags)
    log.fonts[#log.fonts + 1] = { path = path, size = size, flags = flags, fs = self }
    if log.raiseOn[path] then error("cannot load " .. tostring(path)) end
    self.__font = path
    return true
  end
  function fs:SetText(text) self.__text = text end
  return setmetatable(fs, { __index = function(_, k)
    if type(k) == "string" and k:match("^%u") then return function(self) return self end end
  end })
end

--- Spy CreateFrame for one case. Returns the log and the restore; every case restores, pass or
--- fail, through `withSpy`.
local function spy()
  local log = { fonts = {}, frames = {}, raiseOn = {} }
  local saved = mocks.CreateFrame
  mocks.CreateFrame = function(...)
    local f = saved(...)
    log.frames[#log.frames + 1] = f
    rawset(f, "CreateFontString", function(self) return recordingFontString(self, log) end)
    -- Recorded rather than no-opped: an alpha-0 region is one the client may skip, so the preload
    -- has to SAY full alpha, and a test has to be able to see that it did.
    rawset(f, "SetAlpha", function(self, a) self.__alpha = a; return self end)
    return f
  end
  return log, function() mocks.CreateFrame = saved end
end

--- Run `body(log)` with a fresh library-level preload state and the spy installed, restoring both
--- whatever happens. The state is the LIBRARY's, which is the point of it, so every case starts by
--- forgetting what the case before it loaded.
local function withSpy(body)
  local savedState = lib.__fontPreload
  lib.__fontPreload = nil
  local log, restore = spy()
  local ok, err = pcall(body, log)
  restore()
  lib.__fontPreload = savedState
  if not ok then error(err, 0) end
end

--- A LibSharedMedia stand-in: HashTable, Register and CallbackHandler's dot-called
--- RegisterCallback(target, event, fn), firing `LibSharedMedia_Registered` as (event, type, key).
local function fakeLSM(fonts)
  local L = { media = { font = fonts or {}, statusbar = {} }, subscribers = {} }
  function L:HashTable(kind) return self.media[kind] or {} end
  L.RegisterCallback = function(target, event, fn)
    L.subscribers[event] = L.subscribers[event] or {}
    L.subscribers[event][target] = fn
  end
  function L:Register(kind, key, path)
    self.media[kind] = self.media[kind] or {}
    self.media[kind][key] = path
    for _, fn in pairs(self.subscribers.LibSharedMedia_Registered or {}) do
      fn("LibSharedMedia_Registered", kind, key)
    end
    return true
  end
  return L
end

local FONTS = {
  ["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
  ["Expressway"]       = "Interface\\AddOns\\SharedMedia\\fonts\\Expressway.ttf",
  ["Roboto"]           = "Interface\\AddOns\\SharedMedia\\fonts\\Roboto.ttf",
  -- A second key on the same file: the preload is per PATH, so this must not load it twice.
  ["Roboto (alias)"]   = "Interface\\AddOns\\SharedMedia\\fonts\\Roboto.ttf",
}

local function distinctPaths(fonts)
  local seen, n = {}, 0
  for _, p in pairs(fonts) do
    if not seen[p] then seen[p] = true; n = n + 1 end
  end
  return n
end

--- How many times each path reached SetFont.
local function perPath(log)
  local out = {}
  for _, call in ipairs(log.fonts) do out[call.path] = (out[call.path] or 0) + 1 end
  return out
end

--- A host with a rendered page, not yet shown.
local function hostWithPage(lsm, name)
  local O, rec = Fixture.new()
  rec.lsm = lsm
  local ctx = O.CreatePanel(name or "PreloadP", "Preload", { pageKey = "preload" })
  rec.drawn = 0
  O.SetRenderer(ctx, function() rec.drawn = rec.drawn + 1 end)
  return O, rec, ctx
end

local function show(ctx)
  ctx.panel:Show()
  ctx.panel:__fire("OnShow")
end

test("fontpreload: the first panel OnShow loads each LSM font path exactly once", function()
  withSpy(function(log)
    local _, rec, ctx = hostWithPage(fakeLSM(FONTS))
    assertEqual(#log.fonts, 0, "nothing loads at lib:New, CreatePanel or SetRenderer")

    show(ctx)
    local counts = perPath(log)
    local n = 0
    for path, c in pairs(counts) do
      n = n + 1
      assertEqual(c, 1, path .. " was loaded once")
    end
    assertEqual(n, distinctPaths(FONTS), "every distinct path, and an aliased path only once")
    for _, call in ipairs(log.fonts) do
      assertEqual(call.size, 12, "a real size")
      assertEqual(call.flags, "", "no outline")
      assertEqual(call.fs.__text, "Aa", "and the string is given text to lay out")
    end
    assertEqual(rec.drawn, 1, "the page still renders")
  end)
end)

test("fontpreload: the strings live on one shown, full-alpha frame parented to UIParent", function()
  withSpy(function(log)
    local _, _, ctx = hostWithPage(fakeLSM(FONTS))
    show(ctx)
    local f = lib.__fontPreload and lib.__fontPreload.frame
    assertTrue(f ~= nil, "the frame is kept on the library's state")
    assertTrue(#log.fonts > 0)
    for _, call in ipairs(log.fonts) do
      assertTrue(call.fs.__owner == f, "every string belongs to the preload frame")
    end
    assertTrue(f.__parent == mocks.UIParent, "parented to UIParent, so no page's hide can hide it")
    assertTrue(f:IsShown(), "shown: the client may skip work for a hidden region")
    assertEqual(f.__alpha, 1, "at full alpha, set rather than assumed")
  end)
end)

test("fontpreload: a second show, and a second host's panel, load nothing new", function()
  withSpy(function(log)
    local lsm = fakeLSM(FONTS)
    local _, _, ctxA = hostWithPage(lsm, "PreloadA")
    show(ctxA)
    local after = #log.fonts
    local frame = lib.__fontPreload.frame

    ctxA.panel:Hide()
    show(ctxA)
    assertEqual(#log.fonts, after, "a second show of the same page loads nothing")

    -- Another Ka0s addon's instance: a different lib:New, the same library.
    local _, _, ctxB = hostWithPage(lsm, "PreloadB")
    show(ctxB)
    assertEqual(#log.fonts, after, "nor does another host's first show")
    assertTrue(lib.__fontPreload.frame == frame, "and there is still one preload frame")

    local subs = 0
    for _ in pairs(lsm.subscribers.LibSharedMedia_Registered or {}) do subs = subs + 1 end
    assertEqual(subs, 1, "one library-level subscription however many hosts showed a panel")
  end)
end)

test("fontpreload: a font registered after the preload is loaded when it registers", function()
  withSpy(function(log)
    local lsm = fakeLSM(FONTS)
    local _, _, ctx = hostWithPage(lsm)
    show(ctx)
    local before = #log.fonts

    lsm:Register("font", "Late Face", "Interface\\AddOns\\Late\\late.ttf")
    assertEqual(#log.fonts, before + 1, "the late face is loaded on registration")
    assertEqual(log.fonts[#log.fonts].path, "Interface\\AddOns\\Late\\late.ttf")

    lsm:Register("statusbar", "Late Bar", "Interface\\AddOns\\Late\\bar.tga")
    assertEqual(#log.fonts, before + 1, "a statusbar registration loads no font")

    lsm:Register("font", "Late Alias", "Interface\\AddOns\\Late\\late.ttf")
    assertEqual(#log.fonts, before + 1, "a new key on a loaded path loads nothing")
  end)
end)

test("fontpreload: no registration callback before the first show", function()
  -- A player who never opens settings pays for nothing, and that includes a subscription.
  withSpy(function(log)
    local lsm = fakeLSM(FONTS)
    hostWithPage(lsm)
    lsm:Register("font", "Early Face", "Interface\\AddOns\\Early\\early.ttf")
    assertEqual(#log.fonts, 0, "a registration before any panel was shown loads nothing")
    assertNil(lsm.subscribers.LibSharedMedia_Registered, "and nothing had subscribed")
  end)
end)

test("fontpreload: no LibSharedMedia is no error and creates nothing", function()
  withSpy(function(log)
    local _, rec, ctx = hostWithPage(nil)
    local framesBefore = #log.frames
    assertTrue(pcall(show, ctx), "the show survives")
    assertEqual(#log.fonts, 0, "no font is loaded")
    assertEqual(#log.frames, framesBefore, "and no frame is created")
    assertEqual(rec.drawn, 1, "the page renders as it always did")

    -- The same for an LSM with no HashTable, and for a getLSM that raises.
    rec.lsm = {}
    ctx.panel:Hide(); assertTrue(pcall(show, ctx))
    rec.d.getLSM = function() error("no media library") end
    ctx.panel:Hide(); assertTrue(pcall(show, ctx))
    assertEqual(#log.fonts, 0)
    assertEqual(#log.frames, framesBefore)
    assertEqual(#rec.chat, 0, "and nothing is reported: an absent media library is not a fault")
  end)
end)

test("fontpreload: no CreateFrame is no error, and the next show can still load", function()
  withSpy(function(log)
    local _, rec, ctx = hostWithPage(fakeLSM(FONTS))
    local spyFrame = mocks.CreateFrame
    mocks.CreateFrame = nil
    local ok = pcall(show, ctx)
    mocks.CreateFrame = spyFrame
    assertTrue(ok, "the show survives")
    assertEqual(#log.fonts, 0)
    assertEqual(rec.drawn, 1)
    ctx.panel:Hide(); show(ctx)
    assertEqual(#log.fonts, distinctPaths(FONTS), "nothing was marked loaded that was not")
  end)
end)

test("fontpreload: a SetFont that raises costs that face and nothing else", function()
  withSpy(function(log)
    local fonts = {}
    for k, v in pairs(FONTS) do fonts[k] = v end
    fonts["Broken"] = "Interface\\AddOns\\Nowhere\\broken.ttf"
    log.raiseOn["Interface\\AddOns\\Nowhere\\broken.ttf"] = true

    local _, rec, ctx = hostWithPage(fakeLSM(fonts))
    assertTrue(pcall(show, ctx), "the show survives a raising SetFont")
    assertEqual(rec.drawn, 1, "and the page renders")
    assertEqual(#rec.chat, 0, "with nothing reported: a bad face is not the page's failure")
    assertEqual(#log.fonts, distinctPaths(fonts), "every other face was still loaded")

    ctx.panel:Hide(); show(ctx)
    assertEqual(#log.fonts, distinctPaths(fonts), "and the bad one is not retried on every show")
  end)
end)

test("fontpreload: a show locked for combat loads nothing; the next show does", function()
  -- The page is covered (Options minor 22), so no dropdown can open on this show, and loading
  -- every face is a disk hitch the middle of a fight should not pay for.
  withSpy(function(log)
    local _, rec, ctx = hostWithPage(fakeLSM(FONTS))
    mocks.InCombatLockdown = function() return true end
    local ok = pcall(show, ctx)
    mocks.InCombatLockdown = function() return false end
    assertTrue(ok)
    assertEqual(#log.fonts, 0, "nothing loads under lockdown")
    assertEqual(rec.drawn, 0, "and nothing renders, as before")

    ctx.panel:Hide(); show(ctx)
    assertEqual(#log.fonts, distinctPaths(FONTS), "the first show outside combat loads them")
  end)
end)

test("fontpreload: a page with no renderer loads on its show too", function()
  -- A ctx that never went through SetRenderer is still a supported shape — the refresh tiers
  -- keep a migration seam for it — and RenderRows is public, so such a page can hold a font row.
  withSpy(function(log)
    local O, rec = Fixture.new()
    rec.lsm = fakeLSM(FONTS)
    local ctx = O.CreatePanel("BareP", "Bare", { pageKey = "bare" })
    assertEqual(#log.fonts, 0)
    show(ctx)
    assertEqual(#log.fonts, distinctPaths(FONTS))
  end)
end)

test("fontpreload: the main page loads on its first show, with a buildMain and without", function()
  withSpy(function(log)
    local O, rec = Fixture.new{ buildMain = function() end }
    rec.lsm = fakeLSM(FONTS)
    O.CreateOptionsPanel()
    assertEqual(#log.fonts, 0, "nothing at registration")
    mocks.__mainPanel:Show(); mocks.__mainPanel:__fire("OnShow")
    assertEqual(#log.fonts, distinctPaths(FONTS), "a buildMain page loads through SetRenderer")
  end)
  withSpy(function(log)
    local O, rec = Fixture.new()
    rec.lsm = fakeLSM(FONTS)
    O.CreateOptionsPanel()
    mocks.__mainPanel:Show(); mocks.__mainPanel:__fire("OnShow")
    assertEqual(#log.fonts, distinctPaths(FONTS), "and a main page with no renderer loads too")
  end)
end)
