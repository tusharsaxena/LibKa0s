-- tests/test_debuglog_descriptor.lua — what `lib:New` reads off the descriptor when a field is
-- absent or the wrong type.
--
-- CHARACTERIZATION, written before GI-LK-11 moved `lib:New`'s descriptor reads out to file-level
-- helpers (the sighted complexity gate measured the closure at CCN 27). Each case pins one default
-- the inline `type(d.x) == "..." and d.x or default` reads gave, so the move is held to all of them:
-- a field of the wrong type is read as absent, never raised on. `tests/test_debuglog.lua` already
-- pins the required fields, the string overrides, `applySkin` and `makeCloseButton`; this file adds
-- the rest.

local T = _G.LK_TEST
local debuglog = T.debuglog
local test, assertEqual = T.test, T.assertEqual

local function descriptor(overrides)
  local rec = { chat = {}, enabled = false }
  local d = {
    name = "DescHost", title = "Desc Host", font = "Interface\\Fonts\\FRIZQT__.TTF", slash = "/dh",
    isEnabled = function() return rec.enabled end,
    setEnabled = function(v) rec.enabled = v end,
    print = function(line) rec.chat[#rec.chat + 1] = line end,
  }
  for k, v in pairs(overrides or {}) do d[k] = v end
  return d, rec
end

--- The console's minimum height after a Show, which is the one place fontSize is observable.
local function minHeight(overrides)
  local D = debuglog:New((descriptor(overrides)))
  D:Show()
  local _, h = D._frameForTest:GetResizeBounds()
  D:Hide()
  return h
end

test("dbg descriptor: a non-table descriptor is refused like an empty one, naming the first field", function()
  local err = T.assertError(function() debuglog:New("not a table") end, "must be refused")
  T.assertTrue(tostring(err):find("descriptor.name", 1, true) ~= nil, tostring(err))
end)

test("dbg descriptor: fontSize defaults to 10 and a non-number reads as absent", function()
  local default, bigger = minHeight(), minHeight({ fontSize = 14 })
  T.assertTrue(bigger > default, "a larger font asks for a taller console: " .. bigger .. " vs " .. default)
  assertEqual(minHeight({ fontSize = "14" }), default, "a string fontSize is ignored")
  assertEqual(minHeight({ fontSize = 10 }), default, "and the default is 10")
end)

test("dbg descriptor: an empty slash is no slash, so the tooltip names none", function()
  local D = debuglog:New((descriptor({ slash = "" })))
  assertEqual(D:ConsoleCheckbox().tooltip, debuglog.STRINGS.CHECKBOX_TOOLTIP_NO_SLASH)
end)

test("dbg descriptor: an L that is not a table reads as absent", function()
  local D = debuglog:New((descriptor({ L = "x" })))
  assertEqual(D:Text("TITLE_SUFFIX"), debuglog.STRINGS.TITLE_SUFFIX)
end)

test("dbg descriptor: with no print the acknowledgment reaches DEFAULT_CHAT_FRAME", function()
  local saved, seen = T.mocks.DEFAULT_CHAT_FRAME, {}
  T.mocks.DEFAULT_CHAT_FRAME = { AddMessage = function(_, line) seen[#seen + 1] = line end }
  local ok, err = pcall(function()
    debuglog:New((descriptor({ print = "not a function" }))):SetEnabled(true)
  end)
  T.mocks.DEFAULT_CHAT_FRAME = saved
  assertEqual(ok, true, tostring(err))
  assertEqual(#seen, 1, "the one enable acknowledgment went to the chat frame")
end)

test("dbg descriptor: a safeToString that is not a function falls back to Core's", function()
  local d, rec = descriptor({ safeToString = "x" })
  local D = debuglog:New(d)
  rec.enabled = true
  D.Debug("Tag", "value=%s", {})
  T.assertTrue(D:LastLine():find("[Tag] value=", 1, true) ~= nil, "Core's stringifier rendered it: "
    .. tostring(D:LastLine()))
end)

test("dbg descriptor: a skin that is not a table falls back to Core.SKIN, and a table is handed on", function()
  local core, real, seen = T.core, T.core.ApplySkin, {}
  core.ApplySkin = function(f, skin) seen[#seen + 1] = skin; return real(f, skin) end
  local mine = { divider = { 1, 0, 0, 1 } }
  local ok, err = pcall(function()
    debuglog:New((descriptor({ name = "DescSkinA", skin = "x" }))):Show()
    debuglog:New((descriptor({ name = "DescSkinB", skin = mine }))):Show()
  end)
  core.ApplySkin = real
  assertEqual(ok, true, tostring(err))
  assertEqual(seen[1], core.SKIN, "a string skin is ignored")
  assertEqual(seen[2], mine, "the host's table is the one applied")
end)
