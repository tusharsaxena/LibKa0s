-- tests/test_widgets_menu_follow.lua -- LibKa0s#97's batch B, the menu half (WidgetsDropdown minor 3;
-- SD-LK-97B of Ka0sAddonsCommonTasks docs/2026-11-20-LIBKA0S_94_97_99_100, the audit
-- docs/2026-11-20-SKIN_DEFAULTS_AUDIT):
--
--   97.4   a submenu row's arrow takes the opener's `icon.arrow` on every paint, desaturated as a
--          dropdown's arrow is, and the gray back for an owner-less open; the rows are pooled
--   U-21   the menu measures no secret label and reads no width that answers a secret, so Multi
--          Meters' segment picker opens the skinned menu at its `opts.width` under the Combat
--          restriction; a plain label still grows the menu past that floor
--
-- tests/fixture_geom.lua's frames per case, as tests/test_widgets_submenu.lua installs them.

local T = _G.LK_TEST
local assertEqual, assertTrue, assertFalse = T.assertEqual, T.assertTrue, T.assertFalse
local mocks = T.mocks
local W = T.widgets

local Geom = dofile("tests/fixture_geom.lua")
local test = Geom.test

local function anchor() return mocks.CreateFrame("Frame", nil, mocks.UIParent) end
local function rgb(c) return ("%.2f,%.2f,%.2f"):format(c[1], c[2], c[3]) end

local SUB = { { label = "Sub", submenu = { { label = "x" } } } }

--- The arrow with a record of its desaturation: the geometry frame's catch-all swallows the call.
local function arrowOf(row)
  local a = row.__sub
  if not rawget(a, "SetDesaturated") then
    rawset(a, "SetDesaturated", function(self, v) rawset(self, "__desat", not not v) end)
  end
  return a
end

test("menu follow: a skinned menu's submenu arrow wears the opener's icon.arrow, desaturated (97.4)", function()
  -- red under WidgetsDropdown minor 2: the arrow was tinted gray once, when it was built.
  local Skin = T.skin
  local OWNER = "MenuFollowArrow"
  if not Skin:IsOwner(OWNER) then Skin:RegisterOwner(OWNER) end
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  local a = anchor()
  local menu = W.ContextMenu(a, SUB, { owner = OWNER })
  arrowOf(menu.buttons[1])
  W.CloseMenu()
  menu = W.ContextMenu(a, SUB, { owner = OWNER })
  local arrow = menu.buttons[1].__sub
  assertEqual(rgb(arrow.__vertexColor), rgb(Skin:ResolveSkin("contrast")["icon.arrow"]), "High Contrast's arrow")
  assertTrue(arrow.__desat == true, "desaturated, so the token's hue shows")
  W.CloseMenu()
  Skin:SetChoice(OWNER, "ka0s", "obsidian")
  menu = W.ContextMenu(a, SUB, { owner = OWNER })
  assertEqual(rgb(menu.buttons[1].__sub.__vertexColor), rgb(Skin:ResolveSkin("obsidian")["icon.arrow"]),
    "repainted on the next open, in the skin it wears now")
  W.CloseMenu()
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
end)

test("menu follow: an owner-less open gives the pooled arrow its gray back (97.4)", function()
  local Skin = T.skin
  local OWNER = "MenuFollowArrow2"
  if not Skin:IsOwner(OWNER) then Skin:RegisterOwner(OWNER) end
  Skin:SetChoice(OWNER, "ka0s", "contrast")
  local a = anchor()
  local menu = W.ContextMenu(a, SUB, { owner = OWNER })
  arrowOf(menu.buttons[1])
  W.CloseMenu()
  menu = W.ContextMenu(a, SUB)
  local arrow = menu.buttons[1].__sub
  assertEqual(rgb(arrow.__vertexColor), "0.70,0.70,0.72", "the menu's own gray")
  assertFalse(arrow.__desat == true, "on the art's own hue")
  W.CloseMenu()
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
end)

test("menu follow: a secret label is not measured, and the host's width is the floor (U-21)", function()
  -- red under WidgetsDropdown minor 2: every label was measured, a secret one's width raising in the
  -- sum, which is why Multi Meters opened the client's menu while restricted.
  local a = anchor()
  local menu = W.ContextMenu(a, { { label = "warm" } })
  W.CloseMenu()
  local SECRET_LABEL = "a secret session label"
  local saved = rawget(mocks, "issecretvalue")
  local measuredSecret, real = false, rawget(menu.measure, "GetStringWidth")
  rawset(menu.measure, "GetStringWidth", function(self)
    if self.__text == SECRET_LABEL then measuredSecret = true end
    return #(self.__text or "") * 6
  end)
  mocks.issecretvalue = function(v) return v == SECRET_LABEL end
  local ok, err = pcall(W.ContextMenu, a, { { label = SECRET_LABEL }, { label = "Current" } }, { width = 220 })
  mocks.issecretvalue = saved
  rawset(menu.measure, "GetStringWidth", real)   -- the menu is the process's: give its stub back
  assertTrue(ok, tostring(err))
  assertFalse(measuredSecret, "the secret label never reached the measure")
  assertEqual(menu.buttons[1]:GetWidth(), 220, "the host's width")
  assertEqual(menu.buttons[1].fs:GetText(), SECRET_LABEL, "and the row still draws it")
  W.CloseMenu()
end)

test("menu follow: a plain label still grows the menu past the host's width floor (U-21)", function()
  -- Drop Watcher's Filters menu passes its button's width as the floor and needs its labels to fit.
  local menu = W.ContextMenu(anchor(), { { label = string.rep("w", 30) } }, { width = 84 })
  assertEqual(menu.buttons[1]:GetWidth(), 30 * 6 + 24, "measured past the floor")
  W.CloseMenu()
end)

test("menu follow: a measured width that answers a secret is not read (U-21)", function()
  local a = anchor()
  local menu = W.ContextMenu(a, { { label = "warm" } })
  W.CloseMenu()
  local SECRET = setmetatable({}, { __add = function() error("arithmetic on a secret") end })
  local saved = rawget(mocks, "issecretvalue")
  local real = rawget(menu.measure, "GetStringWidth")
  mocks.issecretvalue = function(v) return v == SECRET end
  rawset(menu.measure, "GetStringWidth", function() return SECRET end)
  local ok, err = pcall(W.ContextMenu, a, { { label = "secret" } })
  mocks.issecretvalue = saved
  rawset(menu.measure, "GetStringWidth", real)
  assertTrue(ok, tostring(err))
  assertEqual(menu.buttons[1]:GetWidth(), 90, "the floor, the secret unread")
  W.CloseMenu()
end)
