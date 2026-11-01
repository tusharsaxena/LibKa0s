-- tests/test_kit_skin_values.lua — the typed-value scanner (testkit/skin_values.lua) and the kit
-- suite that runs it (testkit/test_skin_values.lua).
--
-- WHAT IT PROVES. That each shape is caught, that each category takes what its ruling leaves alone
-- and no more, that a stale, reasonless or causeless host row fails, and that the gate fails rather
-- than passes when it cannot look. The library is no host, so the suite's own live run is a declared
-- skip here: the suite is driven against a stand-in kit and fixture trees instead.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local V = dofile("tests/_kit/skin_values.lua")

--- The hits of a one-line source.
local function one(line, path)
  local hits = V.scan(line, { path = path })
  assertEqual(#hits, 1, "one hit in: " .. line)
  return hits[1]
end

local function linesOf(hits)
  local out = {}
  for _, h in ipairs(hits) do out[#out + 1] = h.line end
  return table.concat(out, ",")
end

-- ── the shapes ───────────────────────────────────────────────────────────────────────────────

test("skin values: a planted color of each shape is reported, and only those lines", function()
  local planted = table.concat({
    "local x = 1",
    "fs:SetTextColor(0.85, 0.85, 0.85)",
    "tex:SetColorTexture(r, g,",
    "  0.5, 1)",
    'tt:AddLine("n records", 0.7, 0.7, 0.7)',
    'tt:AddDoubleLine("a", "b", r, g, b, 0.4, 0.4, 0.4)',
    'local s = "|cff808080(none)|r"',
    'fs:SetTextColor(NS.SkinColor("text.body"))   -- 0.9, 0.9, 0.9 in a comment',
    "tex:SetColorTexture(r, g, b, 0.95)",
    "-- |cffffffff in a comment",
    'rows[1] = { label, 0.62, 0.62, 0.68 }',
    'rows[2] = { label, Style.Rgb("dr.dim") }',
    "bar:SetStatusBarColor(0.2, 0.2, 0.2)",
    "fs:SetShadowColor(0, 0, 0, 1)",
  }, "\n")
  assertEqual(linesOf(V.scan(planted)), "2,3,5,6,7,11,13,14")
end)

test("skin values: a planted texture of each shape is reported, and only those lines", function()
  local planted = table.concat({
    'bar:SetStatusBarTexture("Interface\\\\TargetingFrame\\\\UI-StatusBar")',
    "icon:SetTexture(134400)",
    'tex:SetAtlas("ui-hud-minimap-mail")',
    'local PATH = "Interface\\\\FrameGeneral\\\\UI-Frame"',
    "local LONG = [[Interface\\QuestFrame\\UI-Quest]]",
    'local FACE = "Fonts/skurri.ttf"',
    "tex:SetTexture(path)",
    'tex:SetTexture("")',
    "tex:SetTexture(0)",
    'tex:SetTexture(t.x["y"])',
    "-- tex:SetTexture(134400)",
    "--[[ local PATH = \"Interface\\\\Block\"",
    "fs:SetTextColor(0.5, 0.5, 0.5) still a comment ]]",
    'local WORD = "Interface options"',
  }, "\n")
  assertEqual(linesOf(V.scan(planted)), "1,2,3,4,5,6")
end)

test("skin values: a setter's path is one hit, not two", function()
  assertEqual(#V.scan('t:SetTexture("Interface\\\\Foo\\\\Bar")'), 1)
end)

test("skin values: a parenthesis in a string does not end a call", function()
  assertEqual(#V.scan('tt:AddLine("a) b", 0.5, 0.5, 0.5)'), 1)
end)

test("skin values: a line's trailing comment is cut, and CRLF keeps the count", function()
  local hits = V.scan("local a\r\nfs:SetTextColor(1, 0, 0) -- red\r\n")
  assertEqual(hits[1].line, 2)
  assertEqual(hits[1].text:match("^(.-)%s*$"), "fs:SetTextColor(1, 0, 0)")
end)

test("skin values: a host's own paint call is read at its named positions", function()
  local src = "NS.Style.DrawEdge(o, 1, 1, 1, 1, 0.35)\nNS.Style.DrawEdge(o, 2, r, g, b, 0.5)\ncd:SetDrawEdge(true)"
  assertEqual(#V.scan(src), 0, "no host call named")
  assertEqual(linesOf(V.scan(src, { calls = { DrawEdge = { 3, 4, 5 } } })), "1")
end)

test("skin values: a row of numbers past a color's range is data", function()
  assertEqual(#V.scan('x = { "questReward", 84000, 2, 9000 }'), 0)
end)

-- ── the categories ───────────────────────────────────────────────────────────────────────────

local TAKEN = {
  { "chat line (L13)", 'print("|cff808080hi|r")' },
  { "chat line (L13)", 'NS.Printf("|cff808080%s|r", L["x"])' },
  { "chat line (L13)", 'printf("|cff808080%s|r", err)' },
  { "chat line (L13)", 'self:Print("|cffffff00x|r")' },
  { "chat line (L13)", 'DEFAULT_CHAT_FRAME:AddMessage("|cffffff00x|r")' },
  { "chat line (L13)", 'pout("|cffff0000schema error|r")' },
  { "chat line (L13)", 'KCM.Say("|cffff0000schema error|r")' },
  { "chat line (L13)", 'NS.PREFIX = "|cff00ffff[AM]|r "' },
  { "chat line (L13)", 'local X = "|cff33ff99"', "settings/Slash.lua" },
  { "chat line (L13)", 'local X = "|cff33ff99"', "settings/SlashVerbs.lua" },
  { "chat line (L13)", 'local X = "|cff40ff40ON"', "core/DebugLogSetup.lua" },
  { "chat line (L13)", 'out("|cff00ff00-- events --|r")', "core/Diagnostics_Feign.lua" },
  { "hyperlink or quality color", 'local s = "|cffffd100|Hitem:1|h[x]|h|r"' },
  { "hyperlink or quality color", 'local s = "|cffffd100|H" .. link' },
  { "hyperlink or quality color", 'local s = "|cff" .. qualityHex(q) .. name' },
  { "hyperlink or quality color", 'local hex = ITEM_QUALITY_COLORS[q].hex or "|cffffffff"' },
  { "escape builder or search pattern", 'local s = ("|cff%02x%02x%02x"):format(r, g, b)' },
  { "escape builder or search pattern", 'local s = "|cff" .. hex(r)' },
  { "escape builder or search pattern", 'text = text:gsub("|cff%x%x%x%x%x%x.-|r", "")' },
  { "escape builder or search pattern", 'local hex = s:match("|cff(%x+)")' },
  { "locale string", 'label:SetText(L["|cffff0000Warning|r"])' },
  { "meaning color table (MC)", 'local s = RAID_CLASS_COLORS[c] and "x" or "|cff808080"' },
  { "meaning color table (MC)", 'local CLASS_HEX = { WARRIOR = "|cffc79c6e" }' },
  { "meaning color table (MC)", 'NS.DISPEL_COLORS = { Magic = "|cff3399ff" }' },
  { "neutral 1,1,1 reset", "strip:SetVertexColor(1, 1, 1, 1)" },
  { "neutral 1,1,1 reset", "icon:SetVertexColor(1, 1, 1)" },
  { "neutral 1,1,1 reset", "bar:SetStatusBarColor(1.0, 1.0, 1.0)" },
  { "white base for tinting", "fill:SetColorTexture(1, 1, 1, 1)" },
  { "StaticPopup text", 'StaticPopupDialogs["X"] = { text = "|cffff0000Sure?|r", button1 = OKAY }' },
  { "StaticPopup text", 'StaticPopup_Show("X", "|cffff0000name|r")' },
  { "spell or item icon", 'local ICON = "Interface\\\\Icons\\\\INV_Misc_QuestionMark"' },
  { "spell or item icon", 'local ICON = [[Interface\\ICONS\\Spell_Nature_Bloodlust]]' },
  { "L10 art", 'local A = "Interface\\\\Buttons\\\\Arrow-Up-Up"' },
  { "L10 art", 'local A = "Interface\\\\RaidFrame\\\\ReadyCheck-Ready"' },
  { "L10 art", 'local A = "Interface\\\\TargetingFrame\\\\UI-Classes-Circles"' },
  { "A6 Blizzard art", 'spark:SetTexture("Interface\\\\CastingBar\\\\UI-CastingBar-Spark")' },
  { "A6 Blizzard art", 'b:SetHighlightTexture("Interface\\\\Buttons\\\\ButtonHilight-Square", "ADD")' },
  { "A6 Blizzard art", 'grip:SetNormalTexture("Interface\\\\ChatFrame\\\\UI-ChatIM-SizeGrabber-Up")' },
  { "white base for tinting", 'local WHITE = "Interface\\\\Buttons\\\\WHITE8X8"' },
  { "white base for tinting", 'local WHITE = "Interface\\\\Buttons\\\\WHITE8x8"' },
  { "degraded or ignored-panel stock path", 'C.FALLBACK_TEXTURE = "Interface\\\\TargetingFrame\\\\UI-StatusBar"' },
  { "degraded or ignored-panel stock path", 'local e = NS.EDGES[name] or "Interface\\\\Tooltips\\\\UI-Tooltip-Border"' },
  { "degraded or ignored-panel stock path", 'return "Fonts\\\\FRIZQT__.TTF"' },
  { "degraded or ignored-panel stock path", 'fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\\\FRIZQT__.TTF", 12)' },
  { "L12 mono", 'local FONT_FALLBACK = [[Fonts\\ARIALN.TTF]]' },
  { "LSM pick or client default", 'local p = LSM:Fetch("statusbar", key) or "Interface\\\\Other\\\\Bar"' },
  { "LSM pick or client default", 'LSM:Register("statusbar", "Flat", "Interface\\\\Other\\\\Flat")' },
  { "Ace profile page", 'local t = AceDBOptions:GetOptionsTable(db) t.icon = "Interface\\\\Foo\\\\Bar"' },
  { "media/ path", 'local P = "Interface\\\\AddOns\\\\PanelMaster\\\\media\\\\artwork\\\\"' },
  { "media/ path", 'local M = "Interface\\\\AddOns\\\\" .. addonName .. "\\\\media\\\\dial\\\\"' },
}

test("skin values: each category takes what its ruling leaves alone", function()
  for _, row in ipairs(TAKEN) do
    local hits = V.scan(row[2], { path = row[3] or "modules/X.lua" })
    assertTrue(#hits >= 1, "no hit in: " .. row[2])
    for _, hit in ipairs(hits) do
      assertEqual(hit.category, row[1], row[2])
    end
  end
end)

-- Each is one rule's near miss: a category that widened to take it would hide a real value.
local KEPT = {
  { "fs:SetTextColor(1, 1, 1)", "a neutral reset is a tint's, and white text is a color" },
  { "f:SetBackdropColor(1, 1, 1, 1)", "a backdrop's white is no tint base" },
  { "tex:SetColorTexture(1, 1, 0.9, 1)", "not white" },
  { "tex:SetVertexColor(1, 1, 0)", "not neutral" },
  { 'local X = "|cff808080"', "no chat call, in a modules file" },
  { 'label:SetText("|cff808080" .. L["x"] .. "|r")', "an escape beside a locale key is typed" },
  { 'local X = { text = "|cff808080" }', "no popup table" },
  { 'local UI_COLORS = { body = "|cff808080" }', "a chrome table, whatever its name says of color" },
  { 'local CLASS_LABELS = { WARRIOR = "|cff808080" }', "a meaning word with no color in the name" },
  { 'bar:SetStatusBarTexture("Interface\\\\TargetingFrame\\\\UI-StatusBar")', "a stock path drawn, not fallen back to" },
  { 'local BAR = "Interface\\\\TargetingFrame\\\\UI-StatusBar"', "a stock path with no fallback's shape" },
  { 'fs:SetFont("Fonts\\\\FRIZQT__.TTF", 12)', "a client face drawn" },
  { 'local P = "Interface\\\\AddOns\\\\MyAddon\\\\art\\\\logo.tga"', "an addon path outside media/" },
  { 'local P = "Interface\\\\Timer\\\\BigTimerNumbers"', "client art no ruling names" },
  { 'tex:SetAtlas("ui-hud-minimap-mail")', "an atlas no ruling names" },
}

test("skin values: a category takes nothing past its ruling", function()
  for _, row in ipairs(KEPT) do
    local hit = one(row[1], "modules/X.lua")
    assertEqual(hit.category, nil, row[1] .. ": " .. row[2])
  end
end)

test("skin values: the seam, defaults/ and the locales are out by file", function()
  assertEqual(V.pathCategory("core/SkinSetup.lua"), "seam")
  assertEqual(V.pathCategory("defaults/Defaults.lua"), "defaults swatch")
  assertEqual(V.pathCategory("locales/enUS.lua"), "locale")
  assertEqual(V.pathCategory("modules/SkinSetup.lua"), nil, "only the seam by its path")
  assertEqual(V.pathCategory("core/Constants.lua"), nil)
end)

test("skin values: chat by file is for escapes, never a numeric color", function()
  assertEqual(one("fs:SetTextColor(0.5, 0.5, 0.5)", "settings/Slash.lua").category, nil)
end)

-- ── the host's rows ──────────────────────────────────────────────────────────────────────────

local function row(file, substring, cause)
  return { file = file, substring = substring, why = "a reason long enough", cause = cause or "L13" }
end

test("skin values: a host row excuses its line and is used", function()
  local bad, stale = V.judge({ { "modules/A.lua", 'local X = "|cff808080"' } },
    { rows = { row("modules/A.lua", "local X") } })
  assertEqual(#bad, 0)
  assertEqual(#stale, 0)
end)

test("skin values: a row reaches only its own file", function()
  local bad, stale = V.judge({ { "modules/A.lua", 'local X = "|cff808080"' } },
    { rows = { row("modules/B.lua", "local X") } })
  assertEqual(#bad, 1)
  assertEqual(bad[1], 'modules/A.lua:1: [color] local X = "|cff808080"')
  assertEqual(#stale, 1)
end)

test("skin values: a stale row fails", function()
  local bad, stale = V.judge({ { "modules/A.lua", "local x = 1" } },
    { rows = { row("modules/A.lua", "gone") } })
  assertEqual(#bad, 0)
  assertEqual(stale[1], 'modules/A.lua "gone" matches nothing')
end)

test("skin values: a row that repeats a category is stale", function()
  local _, stale = V.judge({ { "modules/A.lua", 'print("|cff808080x|r")' } },
    { rows = { row("modules/A.lua", "print") } })
  assertEqual(#stale, 1, "the category took the hit, so the row excuses nothing")
end)

test("skin values: a row needs its file, substring, why and cause id", function()
  assertEqual(#V.rowProblems({ row("a.lua", "x"), row("a.lua", "y", "FS-AM-02") }), 0)
  for _, field in ipairs({ "file", "substring", "why", "cause" }) do
    local r = row("a.lua", "x")
    r[field] = nil
    assertTrue(V.rowProblems({ r })[1]:find(field, 1, true) ~= nil, field)
  end
  assertTrue(V.rowProblems({ row("a.lua", "x", "because") })[1]:find("no cause id", 1, true) ~= nil)
  assertTrue(V.rowProblems({ "a.lua" })[1]:find("not {", 1, true) ~= nil)
end)

-- ── looking ──────────────────────────────────────────────────────────────────────────────────

local function temp()
  local p = io.popen("mktemp -d 2>/dev/null")
  local made = p and p:read("*l")
  if p then p:close() end
  if not made or made == "" then T.skip("no `mktemp -d` on this host") end
  return made
end

local function write(root, path, text)
  os.execute(("mkdir -p '%s/%s'"):format(root, path:match("^(.*)/") or "."))
  local f = assert(io.open(root .. "/" .. path, "wb"))
  f:write(text)
  f:close()
end

local function gitTree(files)
  local root = temp()
  for path, text in pairs(files) do write(root, path, text) end
  os.execute(("git -C '%s' init -q 2>/dev/null && git -C '%s' add -A 2>/dev/null"):format(root, root))
  return root
end

local function raises(fn, what)
  local ok, err = pcall(fn)
  assertTrue(not ok, "it passed: " .. what)
  assertTrue(tostring(err):find(what, 1, true) ~= nil, tostring(err))
end

test("skin values: it reads the tracked scope, without the seam or a file git does not track", function()
  local root = gitTree({
    ["core/A.lua"] = "a", ["core/SkinSetup.lua"] = "s", ["modules/B.lua"] = "b",
    ["settings/C.lua"] = "c", ["locales/enUS.lua"] = "l", ["tools/x.lua"] = "t",
  })
  write(root, "modules/untracked.lua", "u")
  local got = {}
  for _, f in ipairs(V.collect({ root = root })) do got[#got + 1] = f[1] end
  table.sort(got)
  assertEqual(table.concat(got, " "), "core/A.lua modules/B.lua settings/C.lua")
end)

test("skin values: a host's paths replace the scope", function()
  local root = gitTree({ ["core/A.lua"] = "a", ["ui/B.lua"] = "b" })
  local got = V.collect({ root = root, paths = { "ui/*.lua" } })
  assertEqual(#got, 1)
  assertEqual(got[1][1], "ui/B.lua")
end)

test("skin values: no git fails", function()
  local root = temp()
  raises(function() V.collect({ root = root }) end, "git listed no source files")
end)

test("skin values: no io.popen fails", function()
  local real = io.popen
  rawset(io, "popen", nil)
  local ok, err = pcall(V.collect, {})
  rawset(io, "popen", real)
  assertTrue(not ok)
  assertTrue(tostring(err):find("io.popen is unavailable", 1, true) ~= nil, tostring(err))
end)

-- ── the kit suite, driven by a stand-in ──────────────────────────────────────────────────────

--- Run the vendored suite under a stand-in kit with `facts`. Answers the cases it registered,
--- each `{ name, fn, skip }`.
local function suite(facts)
  local cases = {}
  local kit = {
    skinValues = facts,
    test = function(name, fn, skip) cases[#cases + 1] = { name = name, fn = fn, skip = skip } end,
    fail = function(msg) error(msg, 0) end,
  }
  assert(loadfile("tests/_kit/test_skin_values.lua"))(kit)
  return cases
end

local function runAll(cases)
  local failed = {}
  for _, c in ipairs(cases) do
    local ok, err = pcall(c.fn)
    if not ok then failed[#failed + 1] = c.name .. ": " .. tostring(err) end
  end
  return table.concat(failed, "\n")
end

test("skin values suite: unset facts are one declared skip that names the rule", function()
  local cases = suite(nil)
  assertEqual(#cases, 1)
  assertEqual(cases[1].fn, nil)
  assertTrue(cases[1].skip:find("skinning-§1", 1, true) ~= nil, cases[1].skip)
end)

test("skin values suite: facts that are no table fail at load", function()
  raises(function() suite("modules/") end, "Kit.skinValues")
end)

test("skin values suite: a clean tree passes, its planted value proving the check", function()
  local root = gitTree({ ["core/A.lua"] = 'fs:SetTextColor(NS.SkinColor("text.body"))' })
  assertEqual(runAll(suite({ root = root })), "")
end)

test("skin values suite: a typed value fails, naming its line", function()
  local root = gitTree({ ["core/A.lua"] = "local x\nfs:SetTextColor(0.5, 0.5, 0.5)" })
  local out = runAll(suite({ root = root }))
  assertTrue(out:find("core/A.lua:2:", 1, true) ~= nil, out)
end)

test("skin values suite: a stale row fails", function()
  local root = gitTree({ ["core/A.lua"] = "local x" })
  local out = runAll(suite({ root = root, rows = { row("core/A.lua", "gone") } }))
  assertTrue(out:find("stale", 1, true) ~= nil, out)
end)

test("skin values suite: a causeless row fails", function()
  local root = gitTree({ ["core/A.lua"] = 'local X = "|cff808080"' })
  local r = row("core/A.lua", "local X")
  r.cause = nil
  local out = runAll(suite({ root = root, rows = { r } }))
  assertTrue(out:find("has no cause", 1, true) ~= nil, out)
end)

test("skin values suite: no git fails", function()
  local out = runAll(suite({ root = temp() }))
  assertTrue(out:find("git listed no source files", 1, true) ~= nil, out)
end)
