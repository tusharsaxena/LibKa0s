-- tests/test_skin_eui.lua — LibKa0s-Skin-1.0's EllesmereUI provider (SkinEUI.lua): registration and
-- its retries, the four-condition gate, entering EllesmereUI live and late, the one-way reload rule,
-- fail-closed painting, option stripping, per-owner isolation, and the objects never handed to
-- EllesmereUI. Every case runs on a fresh environment with a headless EllesmereUI fake
-- (tests/fixture_skin_eui.lua) and the kit's paint recorder.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertFalse, assertNil =
  T.test, T.assertEqual, T.assertTrue, T.assertFalse, T.assertNil
local E = dofile("tests/fixture_skin_eui.lua")
local F = E.F
local Loader = dofile("tests/_kit/loader.lua")

local OWNER = E.OWNER

local function condByKey(status)
  local out = {}
  for _, c in ipairs(status.conditions) do out[c.key] = c end
  return out
end

--- A frame with no BackdropTemplate (the raw SetBackdrop cleared, as tests/test_skin_paint.lua
--- models one), so a box primitive draws its edges on the holder.
local function bareFrame(m)
  local f = m.CreateFrame("Frame", nil, m.UIParent)
  rawset(f, "SetBackdrop", nil)
  return f
end

-- ── attachment ───────────────────────────────────────────────────────────────────────────────

test("skin eui: SkinEUI attaches to the shell and makes no frame until an owner registers", function()
  local _, Skin = E.env()
  assertEqual(Skin.MODULES.SkinEUI, Skin.__euiMinor, "SkinEUI reports its own minor")
  assertEqual(Skin.__euiShellMinor, Skin.MINOR, "attached to the live shell")
  assertEqual(type(Skin.GetEUIStatus), "function", "GetEUIStatus")
  assertEqual(type(Skin.MarkShared), "function", "MarkShared")
  assertNil(Skin.__euiEventFrame, "no frame before RegisterOwner")
  E.owner(Skin, OWNER)
  assertTrue(Skin.__euiEventFrame ~= nil, "the retry frame exists once an owner registers")
end)

test("skin eui: without SkinEUI the engine keeps eui a stored choice on the owner's Ka0s skin", function()
  local m2, Skin2 = F.env({ files = { "Core", "Skin", "SkinDefs", "SkinPaint", "SkinPaintExtras",
                                     "SkinPaintControls" } })
  E.install(m2)
  local S = E.owner(Skin2, OWNER, "eui", "ka0s")
  m2.eui.login()
  local f = E.window(m2)
  S.Shell(f)
  assertEqual(m2.eui.count(), 0, "nothing registers with EllesmereUI without the provider")
  assertNil(Skin2.GetEUIStatus, "no GetEUIStatus")
  assertEqual(f.__shown, true, "the window still painted")
end)

-- ── the gate ─────────────────────────────────────────────────────────────────────────────────

test("skin eui: GetEUIStatus lists the four conditions and holds only when all do", function()
  local _, Skin, eui = E.env()
  E.owner(Skin, OWNER)
  local before = Skin:GetEUIStatus(OWNER)
  local c = condByKey(before)
  assertEqual(#before.conditions, 4, "four conditions")
  assertEqual(before.conditions[1].key, "eui", "display order")
  assertEqual(before.conditions[4].key, "facade", "the facade last")
  assertTrue(c.eui.ok and c.master.ok and c.own.ok, "EllesmereUI's three hold")
  assertFalse(c.facade.ok, "no facade before EllesmereUI calls back")
  assertEqual(c.facade.hint, "Reload the UI.", "the facade's hint")
  assertFalse(before.ok, "gate open with no facade: the choice stays disabled")
  assertTrue(c.own.label:find(OWNER, 1, true) ~= nil, "the own condition names the owner")
  eui.login()
  local after = Skin:GetEUIStatus(OWNER)
  assertTrue(after.ok, "all four hold once EllesmereUI handed the facade")
  assertFalse(after.painted, "nothing painted while the owner is on ka0s")
end)

local GATE = {
  { "no EllesmereUI at all", { noEUI = true }, { eui = false, master = false, own = false } },
  { "the Blizzard Skin child missing", { child = false }, { eui = false, master = false, own = false } },
  { "the master switch off", { masterOff = true }, { eui = true, master = false, own = true } },
  { "the owner's entry off", { entries = { [OWNER] = false } }, { eui = true, master = true, own = false } },
  { "another addon's entry off", { entries = { Other = false } }, { eui = true, master = true, own = true } },
  { "the owner's entry nil", { entries = {} }, { eui = true, master = true, own = true } },
}

for _, g in ipairs(GATE) do
  test("skin eui: gate with " .. g[1], function()
    local m, Skin = E.env(g[2])
    E.owner(Skin, OWNER)
    if m.eui then m.eui.login() end
    local c = condByKey(Skin:GetEUIStatus(OWNER))
    for key, want in pairs(g[3]) do assertEqual(c[key].ok, want, key) end
    local open = g[3].eui and g[3].master and g[3].own
    assertEqual(c.facade.ok, open, "EllesmereUI calls back only through an open gate")
    assertEqual(Skin:GetEUIStatus(OWNER).ok, open, "ok")
  end)
end

-- ── registration ─────────────────────────────────────────────────────────────────────────────

test("skin eui: an owner registered before the EllesmereUI global exists is retried", function()
  local m, Skin = E.env({ noEUI = true })
  E.owner(Skin, OWNER)
  assertNil(Skin.euiRegistered[OWNER], "nothing to register with yet")
  local f = Skin.__euiEventFrame
  assertTrue(f:IsEventRegistered("ADDON_LOADED"), "listens for EllesmereUI's load")
  assertTrue(f:IsEventRegistered("PLAYER_LOGIN"), "and for login")
  local eui = E.install(m)
  f:__fire("OnEvent", "ADDON_LOADED", "SomethingElse")
  assertNil(eui.registry[OWNER], "another addon's load retries nothing")
  f:__fire("OnEvent", "ADDON_LOADED", "EllesmereUI")
  assertEqual(type(eui.registry[OWNER]), "function", "registered on EllesmereUI's load")
  assertFalse(f:IsEventRegistered("ADDON_LOADED"), "ADDON_LOADED let go")
  eui.login()
  assertTrue(Skin.euiFacade[OWNER] ~= nil, "the facade arrived")
end)

test("skin eui: PLAYER_LOGIN retries too, then lets go of both events", function()
  local m, Skin = E.env({ noEUI = true })
  E.owner(Skin, OWNER)
  local eui = E.install(m)
  local f = Skin.__euiEventFrame
  f:__fire("OnEvent", "PLAYER_LOGIN")
  assertEqual(type(eui.registry[OWNER]), "function", "registered at login")
  assertFalse(f:IsEventRegistered("PLAYER_LOGIN"), "PLAYER_LOGIN let go")
  assertFalse(f:IsEventRegistered("ADDON_LOADED"), "ADDON_LOADED let go")
end)

test("skin eui: dispatch at login and registration after login both hand the facade", function()
  local _, Skin, eui = E.env()
  E.owner(Skin, "Early")
  assertNil(Skin.euiFacade.Early, "queued until login")
  eui.login()
  assertTrue(Skin.euiFacade.Early ~= nil, "dispatched at login")
  E.owner(Skin, "Late")
  assertTrue(Skin.euiFacade.Late ~= nil, "a registration after login fires at once")
  assertTrue(Skin.euiFacade.Early ~= Skin.euiFacade.Late, "one facade per owner")
  E.owner(Skin, "Early")
  assertEqual(#eui.order, 2, "a second RegisterOwner registers nothing twice")
end)

test("skin eui: a newer minor loaded after registration still receives the facade", function()
  local m, Skin, eui = E.env()
  E.owner(Skin, OWNER, "eui")
  local src = Loader.readFile("LibKa0s/Skin.lua")
  local newer, n = src:gsub('local MAJOR, MINOR = "LibKa0s%-Skin%-1%.0", %d+',
    'local MAJOR, MINOR = "LibKa0s-Skin-1.0", 999', 1)
  assertEqual(n, 1, "the minor line was found")
  Loader.loadSource(newer, "newer/Skin.lua", nil, m)
  local eSrc = Loader.readFile("LibKa0s/SkinEUI.lua")
  local marked, k = eSrc:gsub("function lib:__OnEUIFacade%(owner, S%)",
    "function lib:__OnEUIFacade(owner, S) lib.__newerRan = true;", 1)
  assertEqual(k, 1, "the callback was found")
  Loader.loadSource(marked, "newer/SkinEUI.lua", nil, m)
  assertEqual(Skin.MINOR, 999, "the newer shell won")
  eui.login()
  assertTrue(Skin.__newerRan, "the newer copy's callback ran")
  assertTrue(Skin.euiFacade[OWNER] ~= nil, "the facade is kept")
end)

-- ── entering EllesmereUI ─────────────────────────────────────────────────────────────────────

test("skin eui: switching ka0s to eui hides the Ka0s paint and hands the frames to EllesmereUI", function()
  local m, Skin, eui = E.env()
  local S = E.owner(Skin, OWNER, "ka0s", "obsidian")
  eui.login()
  local panel = bareFrame(m)
  local f = E.window(m)
  local fs = f:CreateFontString(nil, "OVERLAY")
  S.Panel(panel)
  S.Shell(f)
  S.Button(f.btn)
  S.Text(fs, "accent")
  local holder = F.region(Skin, panel, "holder")
  assertTrue(holder ~= nil and holder:IsShown(), "obsidian drew the panel's edges on a holder")
  assertEqual(eui.count(), 0, "nothing reaches EllesmereUI on ka0s")
  local fired = 0
  S.OnLooksChanged(function() fired = fired + 1 end)
  local changed, reload = Skin:SetChoice(OWNER, "eui")
  assertTrue(changed, "changed")
  assertFalse(reload, "entering EllesmereUI needs no reload")
  assertTrue(Skin.euiPainted[OWNER], "the session latch is set")
  assertFalse(holder:IsShown(), "the Ka0s holder is hidden")
  assertEqual(#eui.callsFor("Panel", panel), 1, "EllesmereUI painted the panel")
  assertEqual(#eui.callsFor("Shell", f), 1, "and the window")
  assertEqual(#eui.callsFor("Button", f.btn), 1, "and the button")
  assertEqual(eui.count("Text"), 0, "a Ka0s extra never reaches EllesmereUI")
  local r, g, b = fs:GetTextColor()
  assertEqual(F.rgba({ r, g, b }), F.rgba(eui.accent), "the extra repainted from EllesmereUI's accent")
  assertEqual(F.rgba(S.Token("text.accent")), F.rgba(eui.accent), "S.Token reads EllesmereUI's accent")
  assertEqual(F.rgba(S.Token("win.bg")), F.rgba(eui.panel), "and its panel color")
  assertEqual(S.Token("font.body"), eui.font, "and its font")
  assertEqual(fired, 1, "the owner's listeners fired once")
  S.Shell(f)
  assertEqual(#eui.callsFor("Shell", f), 2, "a later call goes to EllesmereUI too")
  local rc = Skin:GetEUIStatus(OWNER)
  assertTrue(rc.painted, "the status says painted")
end)

test("skin eui: a facade arriving after the owner chose eui paints the frames then (late arrival)", function()
  local m, Skin, eui = E.env()
  local S = E.owner(Skin, OWNER, "eui", "ka0s")
  local f = E.window(m)
  S.Shell(f)
  assertEqual(eui.count(), 0, "before the facade, the owner wears its Ka0s skin")
  assertFalse(Skin.euiPainted[OWNER] == true, "not painted")
  eui.login()
  assertTrue(Skin.euiPainted[OWNER], "the late facade entered EllesmereUI")
  assertEqual(#eui.callsFor("Shell", f), 1, "the recorded window went to EllesmereUI")
end)

test("skin eui: the owner falls back to its Ka0s skin while the gate is closed", function()
  local m, Skin, eui = E.env({ masterOff = true })
  local S = E.owner(Skin, OWNER, "eui", "obsidian")
  eui.login()
  local panel = bareFrame(m)
  S.Panel(panel)
  assertEqual(eui.count(), 0, "nothing reaches EllesmereUI")
  assertNil(Skin.euiFacade[OWNER], "EllesmereUI never called back")
  local holder = F.region(Skin, panel, "holder")
  assertTrue(holder ~= nil and holder:IsShown(), "obsidian painted it")
  assertEqual(F.rgba(S.Token("win.bg")), F.tok(Skin, "obsidian", "win.bg"), "the Ka0s skin's tokens")
  assertFalse(condByKey(Skin:GetEUIStatus(OWNER)).master.ok, "the status names the master switch")
end)

-- ── the one-way rule ─────────────────────────────────────────────────────────────────────────

test("skin eui: leaving eui after EllesmereUI painted asks for one reload and repaints nothing", function()
  local m, Skin, eui = E.env()
  local S = E.owner(Skin, OWNER, "eui", "ka0s")
  eui.login()
  local f = E.window(m)
  S.Shell(f)
  local asked = 0
  Skin:OnReloadRequest(OWNER, function(owner)
    assertEqual(owner, OWNER, "names the owner")
    asked = asked + 1
  end)
  local calls = eui.count()
  local changed, reload = Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertTrue(changed and reload, "changed, and the reload is asked for")
  assertEqual(asked, 1, "OnReloadRequest fired once")
  assertTrue(Skin:PendingReload(OWNER), "pending")
  local _, again = Skin:SetChoice(OWNER, "ka0s", "ember")
  assertFalse(again, "at most once")
  assertEqual(asked, 1, "still once")
  assertEqual(eui.count(), calls, "nothing repainted")
end)

test("skin eui: leaving an eui EllesmereUI never painted repaints live, with no reload", function()
  local m, Skin = E.env({ masterOff = true })
  local S = E.owner(Skin, OWNER, "eui", "ka0s")
  local panel = bareFrame(m)
  S.Panel(panel)
  local changed, reload = Skin:SetChoice(OWNER, "ka0s", "obsidian")
  assertTrue(changed, "changed")
  assertFalse(reload, "no reload")
  assertFalse(Skin:PendingReload(OWNER), "nothing pending")
  local holder = F.region(Skin, panel, "holder")
  assertTrue(holder ~= nil and holder:IsShown(), "repainted in obsidian")
end)

test("skin eui: a gate that closes after the paint asks for a reload and never falls back live", function()
  local m, Skin, eui = E.env()
  local S = E.owner(Skin, OWNER, "eui", "ka0s")
  eui.login()
  local asked = 0
  Skin:OnReloadRequest(OWNER, function() asked = asked + 1 end)
  m.EllesmereUIDB.thirdPartySkinsOff = true
  local status = Skin:GetEUIStatus(OWNER)
  assertFalse(status.ok, "the gate is closed")
  assertTrue(Skin:PendingReload(OWNER), "reading it set the pending reload")
  assertEqual(asked, 1, "the reload was asked for once")
  Skin:GetEUIStatus(OWNER)
  assertEqual(asked, 1, "and only once")
  local f = E.window(m)
  S.Shell(f)
  assertEqual(#eui.callsFor("Shell", f), 1, "no live fallback: EllesmereUI still paints")
end)

test("skin eui: moving between Ka0s skins while on a painted eui with a closed gate asks for the reload", function()
  local m, Skin, eui = E.env()
  E.owner(Skin, OWNER, "eui", "ka0s")
  eui.login()
  m.EllesmereUIDB.thirdPartySkinAddons[OWNER] = false
  local changed, reload = Skin:SetChoice(OWNER, "eui", "obsidian")
  assertTrue(changed and reload, "the reload is asked for")
end)

-- ── fail closed ──────────────────────────────────────────────────────────────────────────────

test("skin eui: a facade missing a primitive is refused before any paint, latched and logged once", function()
  local m, Skin, eui = E.env({ omit = { "Tab" } })
  local log = {}
  local S = E.owner(Skin, OWNER, "ka0s", "obsidian", log)
  eui.login()
  local panel = bareFrame(m)
  S.Panel(panel)
  local _, reload = Skin:SetChoice(OWNER, "eui")
  assertFalse(reload, "no reload")
  assertFalse(Skin.euiPainted[OWNER] == true, "not painted")
  assertEqual(eui.count(), 0, "nothing reached EllesmereUI")
  assertEqual(#log, 1, "one log line")
  assertTrue(log[1]:find("Tab", 1, true) ~= nil, "naming the missing primitive")
  local status = Skin:GetEUIStatus(OWNER)
  assertFalse(status.ok, "the choice is not offered")
  assertTrue(status.refused ~= nil, "the refusal is reported")
  local holder = F.region(Skin, panel, "holder")
  assertTrue(holder ~= nil and holder:IsShown(), "the frame keeps its Ka0s paint")
  Skin:SetChoice(OWNER, "ka0s")
  Skin:SetChoice(OWNER, "eui")
  assertEqual(#log, 1, "latched: still one line")
end)

test("skin eui: a primitive that raises stops EllesmereUI painting the owner, once", function()
  local m, Skin, eui = E.env({ raise = "Button" })
  local log = {}
  local S = E.owner(Skin, OWNER, "eui", "ka0s", log)
  eui.login()
  local f = E.window(m)
  S.Button(f.btn)
  assertEqual(eui.count("Button"), 1, "the raising call was made")
  assertEqual(#log, 1, "logged once")
  assertTrue(Skin.euiRefused[OWNER] ~= nil, "latched")
  local b2 = m.CreateFrame("Button", nil, f, "BackdropTemplate")
  S.Button(b2)
  S.Shell(f)
  assertEqual(eui.count(), 1, "nothing more reaches EllesmereUI")
  assertTrue(Skin.painted[b2] ~= nil, "the library's technique painted it instead")
  assertEqual(#log, 1, "still one line")
end)

-- ── what EllesmereUI is handed ───────────────────────────────────────────────────────────────

test("skin eui: Ka0s-only option keys are stripped before EllesmereUI sees a call", function()
  local m, Skin, eui = E.env()
  local S = E.owner(Skin, OWNER, "eui", "ka0s")
  eui.login()
  local f = E.window(m)
  local eb = m.CreateFrame("EditBox", nil, f)
  S.Shell(f, { noTopBar = true, bottomBar = 20, primary = true, role = "x" })
  S.Button(f.btn, { primary = true })
  local b2 = m.CreateFrame("Button", nil, f)
  S.Button(b2, { "Icon", primary = true })
  S.EditBox(eb, { padInput = true, noBorder = true, role = "search" })
  local shell = eui.callsFor("Shell", f)[1]
  assertEqual(shell.args[1].noTopBar, true, "noTopBar kept")
  assertEqual(shell.args[1].bottomBar, 20, "bottomBar kept")
  assertNil(shell.args[1].primary, "primary stripped")
  assertNil(shell.args[1].role, "role stripped")
  assertNil(eui.callsFor("Button", f.btn)[1].args[1], "a Ka0s options table becomes nothing")
  local keep = eui.callsFor("Button", b2)[1].args[1]
  assertEqual(#keep, 1, "keepKeys kept")
  assertEqual(keep[1], "Icon", "by name")
  assertNil(keep.primary, "without the Ka0s key")
  local edit = eui.callsFor("EditBox", eb)[1].args[1]
  assertTrue(edit.padInput and edit.noBorder, "EditBox's options kept")
  assertNil(edit.role, "role stripped")
  assertEqual(Skin.painted[f].calls.Shell[1].primary, true, "the record keeps the caller's options")
end)

test("skin eui: an eui-owned AceGUI CheckBox makes zero calls to EllesmereUI", function()
  local m, Skin, eui = E.env()
  local S = E.owner(Skin, OWNER, "eui", "ka0s")
  eui.login()
  local w = m.LibStub("AceGUI-3.0"):Create("CheckBox")
  w.frame.obj = w   -- every real AceGUI widget constructor sets it
  S.Checkbox(w.frame)
  S.Font(w.frame)
  assertEqual(eui.count(), 0, "the pooled widget never reaches EllesmereUI")
  assertTrue(Skin.painted[w.frame] ~= nil, "the library's technique painted it")
  local menu = m.CreateFrame("Frame", nil, m.UIParent, "BackdropTemplate")
  Skin:MarkShared(menu)
  S.Panel(menu)
  local icon = w.frame:CreateTexture(nil, "ARTWORK")
  S.SquareIcon(icon)
  assertEqual(eui.count(), 0, "a marked singleton, and a region of a widget's frame, stay the library's")
end)

test("skin eui: another owner's frames and tokens never see EllesmereUI", function()
  local m, Skin, eui = E.env()
  local A = E.owner(Skin, "AddonA", "eui", "ka0s")
  local B = E.owner(Skin, "AddonB", "ka0s", "ka0s")
  eui.login()
  local fa, fb = E.window(m), E.window(m)
  A.Shell(fa)
  B.Shell(fb)
  assertEqual(#eui.callsFor("Shell", fa), 1, "A's window went to EllesmereUI")
  assertEqual(#eui.callsFor("Shell", fb), 0, "B's did not")
  assertEqual(F.rgba(B.Token("text.accent")), F.tok(Skin, "ka0s", "text.accent"), "B keeps Ka0s Default")
  assertTrue(Skin.euiPainted.AddonA and not Skin.euiPainted.AddonB, "the latch is per owner")
  assertTrue(Skin.euiFacade.AddonA ~= Skin.euiFacade.AddonB, "one facade per owner")
end)

test("skin eui: EllesmereUI's live looks change repaints the Ka0s extras", function()
  local m, Skin, eui = E.env()
  local S = E.owner(Skin, OWNER, "eui", "ka0s")
  eui.login()
  local fs = m.CreateFrame("Frame", nil, m.UIParent):CreateFontString(nil, "OVERLAY")
  S.Text(fs, "accent")
  local fired = 0
  S.OnLooksChanged(function() fired = fired + 1 end)
  eui.accent = { 0.9, 0.1, 0.2 }
  for _, fn in ipairs(eui.looks) do fn() end
  local r, g, b = fs:GetTextColor()
  assertEqual(F.rgba({ r, g, b }), F.rgba(eui.accent), "the extra took the new accent")
  assertEqual(fired, 1, "the owner's listeners heard it")
end)

-- ── the standard's confinement ───────────────────────────────────────────────────────────────

test("skin eui: EllesmereUIDB is read in LibKa0s/SkinEUI.lua and no other payload file", function()
  local files = Loader.xmlFiles("LibKa0s/LibKa0s.xml")
  local seen = {}
  for _, path in ipairs(files) do
    if Loader.readFile(path):find("EllesmereUIDB", 1, true) then seen[#seen + 1] = path end
  end
  assertEqual(table.concat(seen, ","), "LibKa0s/SkinEUI.lua",
    "library-stack-§6's skinning exception names one file")
end)
