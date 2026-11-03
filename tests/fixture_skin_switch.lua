-- tests/fixture_skin_switch.lua — the consumer facts for the kit's skin-switch suite
-- (testkit/test_skin_switch.lua). A library has no surfaces of its own, so the suite runs over a
-- fixture host on this repo's real Skin major with the kit's paint recorder: a window, a string and
-- a settings row, each painted through the facade the way an addon paints one.

local F = dofile("tests/fixture_skin_paint.lua")

local OWNER = "SwitchFixture"
local m, Skin = F.env()
local S = F.owner(Skin, OWNER)

return {
  owner = OWNER,
  skin = Skin,
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
  },
}
