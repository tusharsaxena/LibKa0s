-- tests/fixture_skin_switch.lua — the consumer facts for the kit's skin-switch suite
-- (testkit/test_skin_switch.lua). A library has no surfaces of its own, so the suite runs over a
-- fixture host on this repo's real Skin major with the kit's paint recorder: a window, a string and
-- a settings row, each painted through the facade the way an addon paints one.
--
-- From kit revision 58 (SD-LK-97.18 of Ka0sAddonsCommonTasks docs/2026-11-20-SKIN_DEFAULTS_AUDIT)
-- it also declares the library's own widgets an addon shows: a Bar, a Charts bar row, a TestStrip, a
-- Footer, a DragHandle and a Dropdown row, built with the fixture owner as a host builds them. And it
-- installs a LibSharedMedia fake that answers every skin's statusbar and font key with a path of its
-- own: with none, P.media found no bar texture under any skin, so BarTexture painted WHITE8X8 under
-- all of them and a bar whose texture stopped following could not be told from one that followed.

local F = dofile("tests/fixture_skin_paint.lua")

local OWNER = "SwitchFixture"

--- Fill `map` with every skin's statusbar and font keys, each its own path. Read off the shipped
--- skins, so a new skin is covered the day it lands; filled after the load, since the fake reads
--- the table it was given on every Fetch (one load of the Skin major, for the run's leak gate).
local function fillLsm(map, Skin)
  for _, def in ipairs(Skin:Skins()) do
    local t = Skin:ResolveSkin(def.key)
    for token, kind in pairs({ ["bar.texture"] = "statusbar", ["font.body"] = "font", ["font.title"] = "font",
                               ["font.mono"] = "font", ["hud.font"] = "font" }) do
      local key = t[token]
      if type(key) == "string" and key ~= "" then
        map[kind .. ":" .. key] = "Interface\\AddOns\\SwitchFixture\\" .. kind .. "\\" .. key
      end
    end
  end
end

local FILES = {}
for _, f in ipairs(F.FILES) do FILES[#FILES + 1] = f end
for _, f in ipairs({ "Pool", "Widgets", "WidgetsDropdown", "WidgetsDragHandle", "WidgetsDragHandleTip",
                     "WidgetsBar", "Charts", "ChartsRender" }) do
  FILES[#FILES + 1] = f
end

local LSM = {}
local m, Skin = F.env({ files = FILES, lsm = LSM })
fillLsm(LSM, Skin)
local S = F.owner(Skin, OWNER)
local W = m.LibStub("LibKa0s-Widgets-1.0")
local Charts = m.LibStub("LibKa0s-Charts-1.0")

local function parent() return m.CreateFrame("Frame", nil, m.UIParent) end

local MENU = { { label = "One", value = 1 }, { label = "Two", value = 2 } }
local menuAnchor

--- The first row of a menu the fixture owner opens: a host's menu opens again on its next click,
--- which is the repaint a pooled row gets.
local function openMenu()
  W.CloseMenu()
  local menu = W.ContextMenu(menuAnchor, MENU, { owner = OWNER })
  return menu.buttons[1]
end

return {
  owner = OWNER,
  skin = Skin,
  mocks = m,   -- not a kit field: tests/test_kit_skin_switch.lua reads the bench through it
  reset = function() W.CloseMenu() end,
  surfaces = {
    { name = "a window's panel", build = function()
      local f = m.CreateFrame("Frame")
      S.Panel(f)
      return f
    end },
    { name = "a string", build = function()
      local fs = m.CreateFrame("Frame"):CreateFontString()
      S.Text(fs, "text.body")
      return fs
    end },
    { name = "a settings row", scope = "panel", build = function()
      local f = m.CreateFrame("Frame")
      S.Card(f)
      return f
    end },
    { name = "a Bar", expect = "texture", build = function()
      local bar = W.Bar(parent(), { owner = OWNER, preset = "row" })
      bar:SetValues({ value = 3, max = 5, text = "3 / 5" })
      return bar
    end },
    { name = "a Charts bar row", expect = "texture", build = function()
      -- The rows redrawn through host.onReskin, as Charts' contract asks of a host: a pooled bar's
      -- own reskin repaints its fill and face, and the host's render its label colors.
      local pool
      local function render(ctx)
        ctx:ReleaseAll()
        ctx:renderBarSection(pool, ctx:sectionHeader(nil, "H"),
          { { label = "A", frac = 0.5, color = { 1, 0, 0 }, value = "1" } }, 0, 500, 8)
      end
      local ctx = Charts:New(parent(), { owner = OWNER, onReskin = render })
      pool = ctx:Pool("b")
      render(ctx)
      return pool.active[1]
    end },
    { name = "a TestStrip", build = function() return W.TestStrip(parent(), { owner = OWNER }) end },
    { name = "a Footer", build = function() return W.Footer(parent(), { owner = OWNER }) end },
    { name = "a DragHandle", build = function()
      return W.DragHandle(parent(), { label = "Move", moveFrame = m.CreateFrame("Frame"), owner = OWNER })
    end },
    { name = "a Dropdown row", build = function()
      menuAnchor = menuAnchor or parent()
      return openMenu()
    end, paint = function() openMenu() end },
  },
}
