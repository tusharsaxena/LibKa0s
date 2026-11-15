-- tests/fixture_icon_browser.lua — the bench tests/test_icon_browser.lua and
-- tests/test_icon_browser_search.lua share: a fresh client per case, a browser for a fixture host,
-- and the readers the cases use. One copy rather than two, for the reason tests/fixture_widgets.lua
-- gives.
--
-- Every env() is a fresh client: the mocks with the kit's paint and layer recorders, a stand-in for
-- SettingsFrameTemplate, and the files the browser reads (Core, Compat, Media, the Skin major, the
-- Widgets copy window, the Options major and the three IconBrowser files), with a registered skin
-- owner and an Options instance as its helpers. The game icon list is memoized per session, so a
-- shared environment would hand one case's list to the next.
--
-- Loaded as `dofile("tests/fixture_icon_browser.lua")`; answers the table F.

local T = _G.LK_TEST
local assertTrue = T.assertTrue
local Loader = (_G.LK_TEST and _G.LK_TEST.loader) or dofile("tests/_kit/loader.lua")
local buildMocks = dofile("tests/wow_mock.lua")
local installPaint = dofile("tests/_kit/mock_paint.lua")
local installLayers = dofile("tests/_kit/mock_layers.lua")

local F = {}

local MAJOR = "LibKa0s-IconBrowser-1.0"
local OWNER = "TestHost"
local SKULL = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"
local OPENER = "TestHostOpener"

local SKIN = { "Skin", "SkinOwnerTokens", "SkinDefs", "SkinDefsOthers", "SkinPaint", "SkinPaintExtras", "SkinPaintHud", "SkinAceConfirm", "SkinPaintControls" }
local OPTIONS = { "Options", "OptionsRegistry", "OptionsWidgets", "OptionsFlow", "OptionsIds", "OptionsIdSuggest",
  "OptionsIdList", "OptionsTabs", "OptionsTabbed", "OptionsHeader", "OptionsCombat", "OptionsCompose", "OptionsScroll", "OptionsNav",
  "OptionsDrawer", "OptionsKeybinds", "OptionsAppearance", "OptionsSkinPicker", "OptionsSkinPickerRows",
  "OptionsSwitch", "OptionsMedia" }

-- The client's SettingsFrameTemplate as the window reads it (wow-ui-source@297d7aa:Interface/AddOns/
-- Blizzard_Settings_Shared/Mainline/Blizzard_SettingsPanelTemplates.xml:4-29): a Bg frame, a
-- NineSlice with its Text, and the ClosePanelButton. And every frame's anchors, recorded.
local function armFrames(m)
  m.__named = {}
  local create = m.CreateFrame
  m.CreateFrame = function(frameType, name, parent, template, ...)
    local f = create(frameType, name, parent, template, ...)
    if name then m.__named[name] = f end
    rawset(f, "SetPoint", function(self, ...)
      local pts = rawget(self, "__pts") or {}
      pts[#pts + 1] = { ... }
      rawset(self, "__pts", pts)
    end)
    rawset(f, "ClearAllPoints", function(self) rawset(self, "__pts", {}) end)
    rawset(f, "GetPoint", function(self, i) return unpack((rawget(self, "__pts") or {})[i or 1] or {}) end)
    if template == "SettingsFrameTemplate" then
      f.Bg = m.CreateFrame("Frame", nil, f)
      f.NineSlice = m.CreateFrame("Frame", nil, f)
      f.NineSlice.Text = f.NineSlice:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      f.ClosePanelButton = m.CreateFrame("Button", nil, f)
    end
    return f
  end
  m.C_XMLUtil = { GetTemplateInfo = function(n) if n == "SettingsFrameTemplate" then return { type = "Frame" } end end }
end

--- A fresh client. `opts.catalog` loads the generated icon sets; `opts.noOwner` registers no skin
--- owner. Answers m, IB, the Options instance (the helpers), the Skin major.
local function env(opts)
  opts = opts or {}
  local m = buildMocks()
  installPaint(m)
  installLayers(m)
  armFrames(m)
  m.prints, m.timers = {}, {}
  local files = { "Core", "Compat", "Media" }
  if opts.catalog then files[#files + 1] = "MediaIcons" end
  for _, f in ipairs(SKIN) do files[#files + 1] = f end
  files[#files + 1] = "Pool"
  files[#files + 1] = "Widgets"
  files[#files + 1] = "WidgetsDropdown"
  files[#files + 1] = "WidgetsCopyWindow"
  for _, f in ipairs(OPTIONS) do files[#files + 1] = f end
  for _, f in ipairs(opts.files or { "IconBrowserSources", "IconBrowserWindow", "IconBrowser" }) do
    files[#files + 1] = f
  end
  for _, f in ipairs(files) do Loader.load("LibKa0s/" .. f .. ".lua", nil, m) end
  Loader.uncache()
  local Skin = m.LibStub("LibKa0s-Skin-1.0")
  -- Ka0s Default by name: the cases pin its token values, and the client's default skin is WoW Forever
  -- under the forever kit profile (Skin minor 18).
  if not opts.noOwner then
    Skin:RegisterOwner(OWNER, { label = "Test Host", get = function() return "ka0s", "ka0s" end })
  end
  local helpers = m.LibStub("LibKa0s-Options-1.0"):New({
    parentTitle = "Test Host", mainPanelName = "TestHostMain", addonName = OWNER,
    print = function() end, get = function() end, set = function() end, applyDefault = function() end,
    rowsForPage = function() return {} end, allRows = function() return {} end,
  })
  return m, m.LibStub(MAJOR, true), helpers, Skin
end

--- A browser for the bench host; `extra` spec fields are laid over the bench's.
local function browserOf(m, IB, helpers, extra)
  local spec = {
    owner = OWNER, title = "Ka0s Test Host", helpers = helpers,
    layers = { strata = "FULLSCREEN", level = 1200, over = 1400 },
    print = function(line) m.prints[#m.prints + 1] = line end,
    inCombat = function() return m.__combat == true end,
    schedule = function(_, fn) m.timers[#m.timers + 1] = fn; return #m.timers end,
  }
  for k, v in pairs(extra or {}) do spec[k] = v end
  return IB:New(spec)
end

--- A fresh client and one browser on it: m, the browser, IB, the helpers.
local function boot(opts, extra)
  local m, IB, helpers = env(opts)
  return m, browserOf(m, IB, helpers, extra), IB, helpers
end

local function flush(m)
  local queued = m.timers
  m.timers = {}
  for _, fn in ipairs(queued) do fn() end
end

-- Open the browser as an opener does: answers the choices it hands back.
local function openOn(B, icon, color, extra)
  local chosen = {}
  local req = { icon = icon, color = color, owner = "test",
    onChoose = function(i, c) chosen[#chosen + 1] = { i, c } end }
  for k, v in pairs(extra or {}) do req[k] = v end
  assertTrue(B:Open(req), "the browser opens")
  return chosen
end

-- The shown cell drawing `icon`, or nil.
local function cellFor(B, icon)
  for _, c in ipairs(B.cells) do
    if c:IsShown() and c.ibIcon == icon then return c end
  end
  return nil
end

local function shownCells(B)
  local n = 0
  for _, c in ipairs(B.cells) do if c:IsShown() then n = n + 1 end end
  return n
end

local function listed(list, value)
  for _, v in ipairs(list) do if v == value then return true end end
  return false
end

local function glyph(m, name) return m.LibStub("LibKa0s-Media-1.0").Icon(OWNER, name) end
local function vertex(region) return table.concat(rawget(region, "__vertex") or { 1, 1, 1 }, ",", 1, 3) end

local function spells(m, list, items)
  m.GetMacroIcons = function(t) for _, v in ipairs(list) do t[#t + 1] = v end end
  m.GetMacroItemIcons = function(t) for _, v in ipairs(items or {}) do t[#t + 1] = v end end
end

local function range(from, n)
  local out = {}
  for i = 1, n do out[i] = from + i end
  return out
end

-- The tab strip's button for `label`, from the Options instance's strip ledger.
local function tabButton(B, label)
  for _, b in ipairs(B.ctx.__tabKids or {}) do
    if b.__ka0sTabTipLabel == label then return b end
  end
  return nil
end

F.MAJOR, F.OWNER, F.SKULL, F.OPENER = MAJOR, OWNER, SKULL, OPENER
F.env, F.browserOf, F.boot, F.flush, F.openOn = env, browserOf, boot, flush, openOn
F.cellFor, F.shownCells, F.listed, F.glyph, F.vertex = cellFor, shownCells, listed, glyph, vertex
F.spells, F.range, F.tabButton = spells, range, tabButton

return F
