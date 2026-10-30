-- tests/test_glyph_guard.lua — the kit's display-glyph guard (testkit/glyphs.lua, kit revision 45;
-- LK-12 of Ka0sAddonsCommonTasks docs/2026-10-30-SKIN_FONTS_AND_FEEDBACK, the owner's item 5b and
-- ruling D-19), and LibKa0s's own display strings held to it.
--
-- What it pins: the safe set's face list is the shipped fonts folder, file by file and byte for byte
-- (a face changed without `python3 tools/glyph_safe_set.py` is red here); the set itself (ASCII and
-- the characters every shipped face draws, the U+2248 that LootHistory's footer drew as a box under
-- Obsidian not among them); the lexer's reach (escapes decoded, long strings read, comments, debug
-- calls, `glyph: mono` lines and texture markup left out); the skip contract; and that nothing under
-- LibKa0s/ carries a character some shipped face cannot draw.
--
-- Fixtures spell every non-ASCII character as a decimal escape, so this file reads the same in any
-- editor and the guard's own decoder is what turns them back into characters.

local T = _G.LK_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue
local assertErrorMatches = T.assertErrorMatches

local Kit = dofile("tests/_kit/framework.lua")

local APPROX = "\226\137\136"   -- U+2248, which Expressway and Philosopher lack (image-19)
local ARROW  = "\226\134\146"   -- U+2192, which Prototype, Expressway, Nunito, Atkinson and Philosopher lack
local EMDASH = "\226\128\148"   -- U+2014, which every shipped face draws
local ELLIPSIS = "\226\128\166" -- U+2026
local NBSP   = "\194\160"
local EACUTE = "\195\169"       -- U+00E9
local EURO   = "\226\130\172"   -- U+20AC, which Prototype lacks

local function cps(list)
  local out = {}
  for _, u in ipairs(list) do out[#out + 1] = u.cp and string.format("%04X", u.cp) or ("b" .. u.byte) end
  return table.concat(out, ",")
end

local function scan(src, opts) return Kit.scanGlyphSource(src, "fixture.lua", opts) end

local function lines(hits)
  local out = {}
  for _, h in ipairs(hits) do out[#out + 1] = h.line .. ":" .. string.format("%04X", h.cp or h.byte) end
  return table.concat(out, " ")
end

test("glyph guard: the helpers are on the kit table and published by Kit.expose", function()
  for _, name in ipairs({ "glyphUnsafe", "assertGlyphSafe", "scanGlyphSource", "scanDisplayGlyphs",
                          "assertDisplayGlyphs" }) do
    assertEqual(type(Kit[name]), "function", "the kit installs " .. name)
    assertEqual(type(T[name]), "function", "and Kit.expose hands " .. name .. " to the suite")
  end
end)

test("glyph guard: the safe set was generated from exactly the shipped faces, byte for byte", function()
  -- red under: a face added to, removed from or replaced in LibKa0s/media/fonts without rerunning
  -- tools/glyph_safe_set.py (then `cp -r testkit/. tests/_kit/`)
  local p = io.popen("git ls-files -- 'LibKa0s/media/fonts/*.ttf' 'LibKa0s/media/fonts/*.otf' 2>/dev/null")
  local onDisk = {}
  for path in p:read("*a"):gmatch("[^\n]+") do
    local f = assert(io.open(path, "rb"))
    onDisk[path:match("[^/]+$")] = f:seek("end")
    f:close()
  end
  p:close()
  local listed = {}
  for _, face in ipairs(Kit.GLYPH_FACES) do
    listed[face.file] = true
    assertEqual(onDisk[face.file], face.bytes, face.file .. " is shipped at the size the set was read from")
  end
  for file in pairs(onDisk) do assertTrue(listed[file], file .. " is shipped and in the safe set's face list") end
  for key, def in pairs(T.media.FONTS) do
    assertTrue(listed[def.file], key .. "'s file is in the safe set's face list")
  end
end)

test("glyph guard: ASCII and the characters every shipped face draws are safe; the rest are named", function()
  assertEqual(cps(Kit.glyphUnsafe("Database ~1.6 MB\tok\n")), "", "ASCII, tab and newline")
  assertEqual(cps(Kit.glyphUnsafe(EMDASH .. ELLIPSIS .. NBSP .. EACUTE)), "", "the em dash, the ellipsis, NBSP, e-acute")
  assertEqual(cps(Kit.glyphUnsafe("Database " .. APPROX .. " 1.6 MB")), "2248", "image-19's U+2248")
  assertEqual(cps(Kit.glyphUnsafe("Poor " .. ARROW .. " Legendary " .. EURO)), "2192,20AC", "in order")
  assertEqual(cps(Kit.glyphUnsafe("bad \255 byte")), "b255", "a byte that is not UTF-8")
  assertEqual(cps(Kit.glyphUnsafe("|TInterface\\Icons\\" .. ARROW .. ":14|t and |Aatlas" .. ARROW .. "|a")), "",
    "texture and atlas markup draws no glyph")
  assertEqual(cps(Kit.glyphUnsafe(nil)), "", "a non-string is nothing")
end)

test("glyph guard: assertGlyphSafe passes a safe string and names an unsafe one", function()
  T.assertGlyphSafe("Copy to every Ka0s addon" .. ELLIPSIS)
  assertErrorMatches(function() T.assertGlyphSafe("Database " .. APPROX, "footer") end,
    "footer: a character some shipped skin face cannot draw: U+2248")
end)

test("glyph guard: the scanner reads every literal, escapes decoded, and long strings too", function()
  local src = table.concat({
    'local a = "Database \\226\\137\\136 %s"',   -- the escape form, which a grep misses
    "local b = 'Poor " .. ARROW .. " Legendary'",
    "local c = [[",
    "  " .. APPROX .. "]]",
    'L["Approx"] = "~ ' .. APPROX .. '"',          -- a locale value
    'local d = "\\x41\\u{2248}"',
    'local e = "fine ' .. EMDASH .. '"',
  }, "\n")
  assertEqual(lines(scan(src)), "1:2248 2:2192 3:2248 5:2248 6:2248", "each line its literal starts on")
end)

test("glyph guard: comments, debug calls, glyph: mono lines and markup are left out", function()
  local src = table.concat({
    "-- a comment: " .. ARROW,
    "--[[ a block " .. APPROX,
    "  still the block " .. ARROW .. " ]]",
    'NS.Debug("copied %s ' .. ARROW .. ' %s", a, b)',
    "self:Debug(",
    '  "multi-line ' .. ARROW .. '",',
    '  fmt("nested (" .. "' .. APPROX .. '")))',
    'debug("arm refused: ' .. APPROX .. '")',
    'D.Debugf(1, "' .. ARROW .. '")',
    'local GLYPH = { up = "' .. ARROW .. '" }   -- glyph: mono',
    "-- glyph: mono begin",
    'local SET = { "' .. APPROX .. '",',
    '  "' .. ARROW .. '" }',
    "-- glyph: mono end",
    'local KEY = "' .. APPROX .. '"   -- glyph: data, a saved name',
    'local CLASS = "[\\128-\\191]"',
    'local tex = "|TInterface\\\\x:0|t ok"',
    'print("after the debug call ' .. ARROW .. '")',
    'local x = debug.traceback("' .. APPROX .. '")',
  }, "\n")
  assertEqual(lines(scan(src)), "18:2192 19:2248",
    "only the plain call after the debug ones, and the debug library's own call, count; a byte class is data")
end)

test("glyph guard: opts.debugNames reads a host's own logger as a debug call", function()
  local src = 'log("' .. ARROW .. '")\ntrace("' .. ARROW .. '")'
  assertEqual(lines(scan(src)), "1:2192 2:2192")
  assertEqual(lines(scan(src, { debugNames = { "log" } })), "2:2192", "a list")
  assertEqual(lines(scan(src, { debugNames = { trace = true } })), "1:2192", "or a set")
end)

test("glyph guard: CRLF sources count lines the same", function()
  assertEqual(lines(scan('local a = 1\r\nlocal b = "' .. ARROW .. '"\r\n')), "2:2192")
end)

test("glyph guard: a skip needs its reason, and libs/, tests/ and tools/ are never read", function()
  assertErrorMatches(function() Kit.scanDisplayGlyphs({ skip = { ["defaults/"] = "" } }) end,
    'opts.skip["defaults/"] gives no reason')
  local _, files = Kit.scanDisplayGlyphs({ include = { "LibKa0s/", "tests/", "tools/" } })
  assertTrue(#files > 0, "LibKa0s/ is read")
  for _, path in ipairs(files) do
    assertTrue(path:sub(1, 8) == "LibKa0s/", path .. " is under LibKa0s/, never tests/ or tools/")
  end
  local _, kept = Kit.scanDisplayGlyphs({ include = { "LibKa0s/" }, skip = { ["LibKa0s/Skin"] = "a fixture" } })
  for _, path in ipairs(kept) do assertTrue(path:find("^LibKa0s/Skin") == nil, path .. " is skipped") end
  local hits, read = Kit.scanDisplayGlyphs({ paths = { "tests/test_glyph_guard.lua" } })
  assertEqual(#read, 1, "opts.paths reads exactly the files named, tests/ or not")
  assertTrue(#hits > 0, "and reads them as source: this file's own escaped constants are hits")
end)

test("glyph guard: every display string LibKa0s ships uses only characters every shipped face draws", function()
  -- red under: a string under LibKa0s/ that a shipped skin face draws as a box
  T.assertDisplayGlyphs({ label = "LibKa0s", include = { "LibKa0s/" } })
end)
