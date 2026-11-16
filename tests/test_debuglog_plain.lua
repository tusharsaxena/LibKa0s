-- tests/test_debuglog_plain.lua — the console's plain-text Copy buffer and its colored view
-- (DebugLog minor 23, DebugLogWindow minor 5; LibKa0s#79, LK-79 of Ka0sAddonsCommonTasks
-- docs/2026-11-16-LIBKA0S_ISSUES_75_PLUS, decisions D3 to D5).
--
-- Through minor 22 the stamp and tag were colored on the view and plain in `buffer`, but the
-- MESSAGE was the same string in both, so a colored report line pasted out of Copy as raw
-- `|cffxxxxxx...|r`. Now `Add` hands the view the message as given and keeps it stripped of color,
-- texture, atlas and hyperlink escapes in `buffer`, so Copy, `LastLine`, `FindLine` and the status
-- count read plain text. `||` (an escaped pipe) survives, `|n` becomes a space and a raw newline is
-- kept (D5). A private `__view` keeps the colored message beside each line that had one, so an
-- owned console rebuilding its log on a skin switch still draws it in color (D3). A host test pins
-- a color through the view, a recorder on the message frame's AddMessage, and needs no new public
-- reader (D4).

local T = _G.LK_TEST
local debuglog = T.debuglog
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil
local F = dofile("tests/fixture_skin_paint.lua")

local function newLog(overrides)
  local rec = { enabled = false }
  local d = {
    name = "PlainTest", title = "Plain Test", font = "Interface\\Fonts\\FRIZQT__.TTF", slash = "/pt",
    isEnabled = function() return rec.enabled end, setEnabled = function(v) rec.enabled = v end,
    print = function() end,
  }
  for k, v in pairs(overrides or {}) do d[k] = v end
  return debuglog:New(d), rec
end

--- The message part of a buffered line.
local function msgOf(line) return (line:match("^.- | %[.-%] (.*)$")) end

--- Run `fn(D, seen)` with the console shown and its message frame recording every AddMessage.
local function withView(D, fn)
  D:Show()
  local log, seen = D._frameForTest.log, {}
  rawset(log, "AddMessage", function(_, line) seen[#seen + 1] = line end)
  local ok, err = pcall(fn, seen)
  rawset(log, "AddMessage", nil)
  if not ok then error(err, 0) end
end

-- ── the buffer is plain, the view keeps the color ──────────────────────────────────────────

test("plain: a colored message reaches the view as given and the buffer stripped", function()
  local D = newLog()
  withView(D, function(seen)
    D:Add("Dump", "|cffff0000red|r x")
    assertTrue(seen[#seen]:find("|cffff0000red|r x", 1, true) ~= nil, "the view: " .. seen[#seen])
  end)
  assertEqual(msgOf(D:LastLine()), "red x", "the buffer")
  assertTrue(D:CopyText():find("|c", 1, true) == nil, "Copy carries no color code")
  assertTrue(D:FindLine("red x") ~= nil, "and FindLine reads the plain text")
end)

test("plain: an escaped pipe survives the strip", function()
  local D = newLog()
  D:Add("T", "a || b |cff00ff00||cff|r")
  assertEqual(msgOf(D:LastLine()), "a || b ||cff")
end)

test("plain: a hyperlink keeps its text, and textures, atlases and keys go", function()
  local D = newLog()
  D:Add("T", "|cff0070dd|Hitem:19019::::|h[Thunderfury]|h|r")
  assertEqual(msgOf(D:LastLine()), "[Thunderfury]")
  D:Add("T", "|TInterface\\Icons\\x:0|t|A:atlas:16:16|a|Kq1|k ok")
  assertEqual(msgOf(D:LastLine()), " ok")
end)

test("plain: |n becomes a space and a raw newline is kept", function()
  local D = newLog()
  D:Add("T", "a|nb\nc")
  assertEqual(msgOf(D:LastLine()), "a b\nc")
end)

test("plain: a line with no pipe is byte for byte what FormatPlain makes", function()
  local D = newLog()
  D:Add("T", "plain text, 100%")
  local ts = D:LastLine():match("^(.-) | ")
  assertEqual(D:LastLine(), debuglog.FormatPlain(ts, "T", "plain text, 100%"))
  assertTrue(not (D.__view and D.__view[#D.buffer]), "no view entry for a line that carried no escape")
end)

test("plain: the gated sink's lines are plain in the buffer too", function()
  local D, rec = newLog()
  rec.enabled = true
  D.Debug("T", "value=%s", "|cff00ff00on|r")
  assertEqual(msgOf(D:LastLine()), "value=on")
end)

test("plain: Clear wipes the view entries with the buffer", function()
  local D = newLog()
  D:Add("T", "|cffff0000red|r")
  D:Clear()
  assertEqual(next(D.__view), nil)
  D:Add("T", "plain")
  assertNil(D.__view[#D.buffer] or nil, "a fresh line has no stale view entry")
end)

test("plain: compaction keeps the view entries beside their lines", function()
  local cap, slack = debuglog.MAX_BUFFER, debuglog.BUFFER_SLACK
  debuglog.MAX_BUFFER, debuglog.BUFFER_SLACK = 4, 1
  local ok, err = pcall(function()
    local D = newLog()
    for i = 1, 11 do
      D:Add("T", (i % 2 == 0) and ("|cffff0000even " .. i .. "|r") or ("odd " .. i))
    end
    assertTrue(#D.buffer <= 5, "compacted")
    for i = 1, #D.buffer do
      local view = D.__view[i]
      local msg = msgOf(D.buffer[i])
      if msg:find("even", 1, true) then
        assertEqual(view, "|cffff0000" .. msg .. "|r", "line " .. i .. " keeps its colored message")
      else
        assertTrue(not view, "line " .. i .. " has none")
      end
    end
    for i = #D.buffer + 1, #D.buffer + 8 do assertNil(D.__view[i], "nothing past the buffer") end
  end)
  debuglog.MAX_BUFFER, debuglog.BUFFER_SLACK = cap, slack
  if not ok then error(err, 0) end
end)

-- ── an owned console's skin switch keeps the colors ────────────────────────────────────────

local OWNER = "LootHistory"
local TOOL_FILES = { "Widgets", "WidgetsDropdown", "WidgetsCopyWindow", "WidgetsHeader", "DebugLog", "DebugLogDiagnostics",
  "DebugLogGates", "DebugLogWindow" }

local function ownedConsole()
  local files = {}
  for _, f in ipairs(F.FILES) do files[#files + 1] = f end
  for _, f in ipairs(TOOL_FILES) do files[#files + 1] = f end
  local m, Skin = F.env({ files = files })
  F.owner(Skin, OWNER, "azeroth")
  local enabled = false
  local D = m.LibStub("LibKa0s-DebugLog-1.0"):New{
    name = "PlainOwned", addonName = OWNER, title = "Host", font = "Interface\\Fonts\\ARIALN.TTF",
    isEnabled = function() return enabled end, setEnabled = function(v) enabled = v end,
    print = function() end,
  }
  D:Show()
  local f = D._frameForTest
  local lines = {}
  rawset(f.log, "AddMessage", function(_, text) lines[#lines + 1] = text end)
  rawset(f.log, "Clear", function() for i = #lines, 1, -1 do lines[i] = nil end end)
  return D, Skin, lines
end

test("plain: a skin switch rebuilds an owned console's log with each message's colors", function()
  local D, Skin, lines = ownedConsole()
  D:Add("Tag", "|cffff0000red|r and plain")
  D:Add("Tag", "only plain")
  assertTrue(D:LastLine():find("|c", 1, true) == nil, "the buffer is plain")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertEqual(#lines, 2, "rebuilt from the buffer")
  assertTrue(lines[1]:find("[Tag]|r |cffff0000red|r and plain", 1, true) ~= nil,
    "the colored message comes back: " .. lines[1])
  assertTrue(lines[2]:find("[Tag]|r only plain", 1, true) ~= nil, "the plain one as it was")
end)

test("plain: a view entry that no longer matches its line is not used", function()
  local D, Skin, lines = ownedConsole()
  D:Add("Tag", "|cffff0000red|r")
  -- A host suite that rewrites a buffered line in place: the stale colored message must not come
  -- back over the text the buffer now holds.
  D.buffer[#D.buffer] = D.buffer[#D.buffer]:gsub("red$", "blue")
  Skin:SetChoice(OWNER, "ka0s", "ka0s")
  assertTrue(lines[#lines]:find("[Tag]|r blue", 1, true) ~= nil, "the buffer's text: " .. lines[#lines])
end)
