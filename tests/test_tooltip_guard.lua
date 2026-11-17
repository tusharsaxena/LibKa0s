-- tests/test_tooltip_guard.lua — no library tooltip anchors itself any more (LibKa0s#92 part B,
-- LK-92B of Ka0sAddonsCommonTasks docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, design section 3.6).
--
-- WowAddonStandards standalone-windows, *Tooltip placement*, and anti-pattern #119: a tooltip of a
-- window the library draws, a library menu, a HUD strip or the minimap button is placed by the
-- placers of LibKa0s-Tooltip-1.0, never by the client's owner anchors. This guard reads every file
-- of the payload for the four anchors those placements used (ANCHOR_CURSOR, ANCHOR_CURSOR_RIGHT,
-- ANCHOR_RIGHT, ANCHOR_TOP) in code, comments stripped.
--
-- OUT OF SCOPE: the Settings-canvas Options files (`Options*.lua`), which the standard does not bind
-- ("Settings-canvas pages, including the library's own Options widgets"; owner, 2026-11-15). The skin
-- picker (`OptionsSkinPicker*.lua`) is a standalone window on UIParent and IS read (R9 C1).
--
-- THE CLOSED ALLOWLIST below names each remaining line and why it is not a placement. A new one is
-- a failure until it is added here with its reason, and an entry that no longer matches fails too.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local BANNED = { "ANCHOR_CURSOR_RIGHT", "ANCHOR_CURSOR", "ANCHOR_RIGHT", "ANCHOR_TOP" }

local ALLOW = {
  { file = "Tooltip.lua", text = 'tip:SetAnchorType(side == "right" and "ANCHOR_RIGHT" or "ANCHOR_LEFT", 0, 0)',
    why = "the comparison side the beside placer hands the client, set before its own absolute point" },
  { file = "Charts.lua", text = 'self.tip(owner, tip, anchor or "ANCHOR_CURSOR_RIGHT", self)',
    why = "the frozen -1.0 host seam's third argument, read by a host's own `tip`; the library's default ignores it" },
  { file = "ChartsRender.lua", text = 'hoverable(ctx, f, "ANCHOR_TOP")',
    why = "the strip bar's legacy host anchor (Loot History branches on it); the library's default ignores it" },
}

--- Every file the payload loads, by name, from LibKa0s.xml (what the client loads).
local function payload()
  local Loader = T.loader or dofile("tests/_kit/loader.lua")
  local out = {}
  for _, path in ipairs(Loader.xmlFiles("LibKa0s/LibKa0s.xml")) do out[#out + 1] = path:match("([^/]+)$") end
  return out
end

local function inScope(file)
  if file:match("^OptionsSkinPicker") then return true end
  return not file:match("^Options")
end

--- `line` with its comment cut off (the library writes no `--` inside a string on these lines).
local function code(line) return (line:gsub("%-%-.*$", "")) end

local function hasBanned(s)
  for _, a in ipairs(BANNED) do
    if s:find("%f[%w_]" .. a .. "%f[^%w_]") then return a end
  end
  return nil
end

local function allowed(file, line)
  local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
  for _, a in ipairs(ALLOW) do
    if a.file == file and trimmed == a.text then return a end
  end
  return nil
end

--- Every banned anchor in code in `files`: offenders as "file:line: anchor", and the allowlist
--- entries that matched.
local function scan(files, read)
  local offenders, used = {}, {}
  for _, file in ipairs(files) do
    local n = 0
    for line in (read(file) .. "\n"):gmatch("([^\n]*)\n") do
      n = n + 1
      line = line:gsub("\r$", "")
      local hit = hasBanned(code(line))
      if hit then
        local a = allowed(file, code(line))
        if a then used[a] = true else offenders[#offenders + 1] = file .. ":" .. n .. ": " .. hit end
      end
    end
  end
  return offenders, used
end

local function readPayload(file)
  local f = assert(io.open("LibKa0s/" .. file, "rb"))
  local s = f:read("*a")
  f:close()
  return s
end

test("tooltip guard: no library file outside the Settings-canvas Options files anchors a tooltip itself", function()
  local files = {}
  for _, file in ipairs(payload()) do
    if inScope(file) then files[#files + 1] = file end
  end
  assertTrue(#files > 40, "the payload was read (" .. #files .. " files)")
  local offenders, used = scan(files, readPayload)
  assertEqual(table.concat(offenders, "\n"), "", "anchors outside the placers")
  for _, a in ipairs(ALLOW) do
    assertTrue(used[a], "an allowlist entry that no longer matches: " .. a.file .. ": " .. a.text)
    assertTrue(type(a.why) == "string" and #a.why > 20, "every entry carries its reason")
  end
end)

test("tooltip guard: the skin picker is read and the Settings-canvas files are not", function()
  assertTrue(inScope("OptionsSkinPicker.lua"), "a standalone window (R9 C1)")
  assertTrue(inScope("OptionsSkinPickerRows.lua"))
  assertTrue(not inScope("OptionsWidgets.lua"), "the Settings canvas is out of scope")
  assertTrue(inScope("WidgetsDragHandleTip.lua"))
end)

test("tooltip guard: the check is falsifiable, a planted anchor is flagged and a comment is not", function()
  local planted = {
    ["Planted.lua"] = 'tip:SetOwner(self, "ANCHOR_TOP")\n-- SetOwner(self, "ANCHOR_RIGHT") in a comment\n'
      .. 'tip:SetOwner(self, "ANCHOR_TOPRIGHT")\nx = "ANCHOR_CURSOR"\n',
  }
  local offenders = scan({ "Planted.lua" }, function(f) return planted[f] end)
  assertEqual(table.concat(offenders, "|"), "Planted.lua:1: ANCHOR_TOP|Planted.lua:4: ANCHOR_CURSOR")
end)
