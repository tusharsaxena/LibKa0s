-- tests/test_debuglog_footer.lua — the debug console's status line is a Widgets footer
-- (DebugLogWindow minor 5; LibKa0s#90, LK-90 of Ka0sAddonsCommonTasks
-- docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, design §3.5).
--
-- WowAddonStandards v2.110.0 (standalone-windows, *The footer*) says a window the library draws
-- builds its footer with `W.Footer`, in the same release. Through minor 4 the console drew its own
-- 16 px status line: a hand-made rule 8 px in from each side and a counter 3 px off the bottom. What
-- is pinned here is the move and the three decisions the issue asked for:
--
--   * THE FOOTER IS W.Footer's, 24 px, built with NO owner and an empty left line, and the shell's
--     handles stay: `f.lineCount` is its right line and `f.statusDivider` its hairline.
--   * THE COUNTER KEEPS THE DESCRIPTOR'S MONO FACE (debug-logging-§11), owned or not, across a skin
--     switch. That is why the footer has no owner: an owned footer paints its right line in the
--     skin's body face on every switch.
--   * THE COUNTER IS DRAWN IN `text.muted` (the footer rule; anti-pattern #118), where it drew
--     `log.count`. Only Ka0s Default and an unowned console move, 0.60 to 0.70 gray: every other
--     skin aliases `log.count` to `text.muted` already.
--
-- The geometry the resize grip and the minimum height take from it is pinned in
-- tests/test_resize_windows.lua beside the rest of the console's resize.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local OWNER, OTHER = "LootHistory", "BankLedger"
local FONT = "Interface\\Fonts\\ARIALN.TTF"
local TOOL_FILES = { "Widgets", "WidgetsDropdown", "WidgetsCopyWindow", "DebugLog", "DebugLogDiagnostics",
  "DebugLogGates", "DebugLogWindow" }

--- A fresh client on the paint recorder with the console's majors. Every frame records its anchors
--- in `__pts` (the recorder keeps a region's, not a frame's).
local function env()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(TOOL_FILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  local create = m.CreateFrame
  m.CreateFrame = function(...)
    local f = create(...)
    f.__pts = {}
    local setPoint = f.SetPoint
    rawset(f, "SetPoint", function(self, ...)
      self.__pts[#self.__pts + 1] = { ... }
      if type(setPoint) == "function" then return setPoint(self, ...) end
    end)
    return f
  end
  return m, Skin
end

--- Every W.Footer call while the console is built: { parent, opts } each.
local function spyFooter(m)
  local W = m.LibStub("LibKa0s-Widgets-1.0")
  local real, calls = W.Footer, {}
  W.Footer = function(parent, opts)
    calls[#calls + 1] = { parent = parent, opts = opts }
    return real(parent, opts)
  end
  return calls, W
end

local function console(m, owner)
  local D = m.LibStub("LibKa0s-DebugLog-1.0"):New{
    name = "Foot" .. tostring(owner), addonName = owner, title = "Host", font = FONT,
    isEnabled = function() return true end, setEnabled = function() end, print = function() end,
  }
  D:Show()
  return D, D._frameForTest
end

local function rgba(c) return F.rgba(c) end
local function survey(m, obj) return m.__paint(obj) end
local function tok3(Skin, skin, name)
  local c = Skin:ResolveSkin(skin)[name]
  return F.rgba({ c[1], c[2], c[3], 1 })
end

--- The y offset of `frame`'s BOTTOMRIGHT anchor on the console.
local function bottomY(frame)
  for _, pt in ipairs(frame.__pts) do
    if pt[1] == "BOTTOMRIGHT" then return pt[#pt] end
  end
  return nil
end

-- ── the footer ───────────────────────────────────────────────────────────────────────────────

test("debuglog footer: the status line is one W.Footer on the console, with no owner and no left text", function()
  -- red under: minor 4's hand-drawn status line (no W.Footer call), or an owner passed to the footer
  for _, registered in ipairs({ false, true }) do
    local m, Skin = env()
    if registered then F.owner(Skin, OWNER, "obsidian") end
    local calls = spyFooter(m)
    local _, f = console(m, registered and OWNER or OTHER)
    local label = registered and "owned" or "unowned"
    assertEqual(#calls, 1, label .. ": one footer")
    assertTrue(calls[1].parent == f, label .. ": on the console")
    local opts = calls[1].opts or {}
    assertNil(opts.owner, label .. ": the footer has no owner, so it never paints the counter's face")
    assertNil(opts.left, label .. ": no left text")
    assertTrue(f.footer ~= nil, label .. ": recorded as f.footer")
    assertEqual(f.footer.left:GetText(), "", label .. ": the left line is empty")
    assertTrue(f.lineCount == f.footer.right, label .. ": f.lineCount is the footer's right line")
    assertTrue(f.statusDivider == f.footer.line, label .. ": f.statusDivider is its hairline")
  end
end)

test("debuglog footer: the shell's UpdateStatus writes the footer's counter", function()
  local m = env()
  local D, f = console(m, OTHER)
  D:Add("Tag", "one")
  assertEqual(f.lineCount:GetText(), D:Text("LINES"):format(1, m.LibStub("LibKa0s-DebugLog-1.0").MAX_BUFFER),
    "UpdateStatus writes the counter through f.lineCount")
  assertEqual(m.LibStub("LibKa0s-Widgets-1.0").FOOTER.HEIGHT, 24, "a 24 px footer")
end)

test("debuglog footer: the log and its scrollbar end 4 px above the footer", function()
  -- red under: the log and the scrollbar left at minor 4's STATUS_H (16) + 4
  local m = env()
  local _, f = console(m, OTHER)
  local want = m.LibStub("LibKa0s-Widgets-1.0").FOOTER.HEIGHT + 4
  assertEqual(bottomY(f.log), want, "the log")
  assertEqual(bottomY(f.scrollBar), want, "the scrollbar")
end)

-- ── the counter's face and color ─────────────────────────────────────────────────────────────

test("debuglog footer: the counter keeps the descriptor's mono face, owned or not, across a switch", function()
  -- red under: an owner passed to W.Footer (its S.Text paints the skin's body face on the counter)
  local m, Skin = env()
  F.owner(Skin, OWNER, "obsidian")
  local _, owned = console(m, OWNER)
  local _, plain = console(m, OTHER)
  local function face(f) return table.concat(survey(m, f.lineCount).font or {}, ",") end
  local mono = FONT .. ",10,"
  assertEqual(face(owned), mono, "owned")
  assertEqual(face(plain), mono, "unowned")
  Skin:SetChoice(OWNER, "ka0s", "glass")
  assertEqual(face(owned), mono, "after a skin switch")
end)

test("debuglog footer: the counter is drawn in text.muted, where it drew log.count", function()
  -- red under: the palette's count entry left on log.count (Ka0s Default's 0.6 gray)
  local m, Skin = env()
  local _, plain = console(m, OTHER)
  assertEqual(rgba(survey(m, plain.lineCount).textColor), "0.700,0.700,0.720,1", "unowned: Ka0s Default's text.muted")
  F.owner(Skin, OWNER)
  local _, owned = console(m, OWNER)
  assertEqual(rgba(survey(m, owned.lineCount).textColor), tok3(Skin, "ka0s", "text.muted"), "owned, Ka0s Default")
  assertTrue(tok3(Skin, "ka0s", "text.muted") ~= tok3(Skin, "ka0s", "log.count"),
    "the one skin where the two differ, so this case can go red")
  Skin:SetChoice(OWNER, "ka0s", "ember")
  assertEqual(rgba(survey(m, owned.lineCount).textColor), tok3(Skin, "ember", "text.muted"), "after a switch")
end)

test("debuglog footer: an owned console's hairline follows its skin through S.Divider", function()
  local m, Skin = env()
  F.owner(Skin, OWNER, "obsidian")
  local _, f = console(m, OWNER)
  assertEqual(rgba(survey(m, f.footer.line).color), F.tok(Skin, "obsidian", "divider"), "the hairline")
  Skin:SetChoice(OWNER, "ka0s", "azeroth")
  assertEqual(rgba(survey(m, f.footer.line).color), F.tok(Skin, "azeroth", "divider"), "after a switch")
end)

-- ── without the footer ───────────────────────────────────────────────────────────────────────

test("debuglog footer: a Widgets without Footer builds a console with no status line, and it still logs", function()
  -- red under: W.Footer called unguarded
  local m = env()
  local W = m.LibStub("LibKa0s-Widgets-1.0")
  local saved = W.Footer
  W.Footer = nil
  local ok, err = pcall(function()
    local D, f = console(m, OTHER)
    assertTrue(f ~= nil, "the console built")
    assertNil(f.footer, "no footer")
    assertNil(f.lineCount, "no counter, so UpdateStatus does nothing")
    D:Add("Tag", "still logs")
    D:UpdateStatus()
    assertEqual(D:BufferSize(), 1, "the line is buffered")
    assertTrue(f.resizeGrip ~= nil, "the grip goes on the window itself")
  end)
  W.Footer = saved
  if not ok then error(err, 0) end
end)
