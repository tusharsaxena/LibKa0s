-- tests/test_kit_vendor_sync.lua — the vendored-payload gate's icon declaration (kit revision 40)
-- and sound declaration (kit revision 55), and tools/prune-icons.lua, which cuts a copy down to both.
--
-- WHAT IT PROVES. That `LibKa0s icons:` parses in its three forms and refuses everything else; that
-- the gate holds `libs/LibKa0s/media/icons/` to exactly what the line declares (undeclared icons
-- fail with a count, declared ones missing fail, unknown names fail against the TAG's catalog, each
-- set's attribution files travel with it) while everything else is still compared whole; that no
-- line at all is the old whole-folder gate; and that the tool leaves a copy the gate passes. The
-- same for `LibKa0s sounds:` over `media/sounds/`, where NO line means none: a pack is its folder,
-- credits and license included, a pack the tag lacks fails, and the tool refuses an unknown pack
-- before it removes anything from either folder.
--
-- WHY IT IS PINNED HERE. The gate is a factory a consumer calls, and this repo has no sibling to
-- compare against (the file's header says why), so until revision 40 nothing here ran it at all.
-- A gate with a carve-out is a gate that can pass by not looking, so each shape is driven against a
-- REAL fixture: a library repo with a tag, and a consumer beside it. `git` and `mktemp` are what the
-- gate itself needs; a host without them skips, with the reason.

local T = _G.LK_TEST
local test, assertEqual, assertTrue, assertNil = T.test, T.assertEqual, T.assertTrue, T.assertNil

local VendorSync = dofile("tests/_kit/vendor_sync.lua")

local LIB_CASE = "libs/LibKa0s is the LibKa0s release CLAUDE.md says this addon bundles"
local PROVENANCE = "Bundles [LibKa0s](https://github.com/tusharsaxena/LibKa0s) v9.9.9 (MIT)."

-- ── the parser ──────────────────────────────────────────────────────────────────────────────

test("parseIconLine: the three forms", function()
  local all = VendorSync.parseIconLine(" all (icon picker). ")
  assertEqual(all.mode, "all")
  assertEqual(all.reason, "icon picker")
  assertEqual(VendorSync.parseIconLine("none.").mode, "none")
  local list = VendorSync.parseIconLine("settings, ph:sword,close , gi:skull, close.")
  assertEqual(list.mode, "list")
  assertEqual(table.concat(list.names, ","), "close,gi:skull,ph:sword,settings", "sorted, the duplicate dropped")
end)

test("parseIconLine: `all` without a parenthesized reason is refused", function()
  for _, body in ipairs({ "all.", "all ().", "all (  ).", "all icon picker." }) do
    local decl, err = VendorSync.parseIconLine(body)
    assertNil(decl, body)
    assertTrue(err:find("parenthesized reason", 1, true) ~= nil, body .. ": " .. tostring(err))
  end
end)

test("parseIconLine: malformed lists are refused, naming why", function()
  local cases = {
    { "settings, close", "end with a period" },
    { ".", "names nothing" },
    { "settings,, close.", "empty entry" },
    { "settings, close,.", "empty entry" },
    { "settings.tga.", "not a lib.ICONS name" },
    { "ph:sword gi:skull.", "not a lib.ICONS name" },
  }
  for _, c in ipairs(cases) do
    local decl, err = VendorSync.parseIconLine(c[1])
    assertNil(decl, c[1])
    assertTrue(err:find(c[2], 1, true) ~= nil, c[1] .. ": " .. tostring(err))
  end
end)

test("iconDeclaration: absent, placed, misplaced, doubled", function()
  local decl, err = VendorSync.iconDeclaration("# CLAUDE.md\n\n" .. PROVENANCE .. "\n")
  assertNil(decl, "no line is no declaration")
  assertNil(err, "and no error: the transition state")
  decl = VendorSync.iconDeclaration("# X\r\n" .. PROVENANCE .. "\r\nLibKa0s icons: none.\r\n")
  assertEqual(decl.mode, "none", "directly under, CRLF")
  decl = VendorSync.iconDeclaration(PROVENANCE .. "\n\n\nLibKa0s icons: close.\n")
  assertEqual(decl.names[1], "close", "blank lines between are allowed")
  decl, err = VendorSync.iconDeclaration(PROVENANCE .. "\nSomething else.\nLibKa0s icons: close.\n")
  assertNil(decl)
  assertTrue(err:find("directly under", 1, true) ~= nil, tostring(err))
  decl, err = VendorSync.iconDeclaration("LibKa0s icons: close.\n")
  assertTrue(decl == nil and err:find("directly under", 1, true) ~= nil, "no provenance line to sit under")
  decl, err = VendorSync.iconDeclaration(PROVENANCE .. "\nLibKa0s icons: close.\nLibKa0s icons: none.\n")
  assertTrue(decl == nil and err:find("2 times", 1, true) ~= nil, tostring(err))
end)

test("iconDeclaration: anchored, so prose that mentions the line is not a second one", function()
  local doc = PROVENANCE .. "\nLibKa0s icons: close.\n\nSee the `LibKa0s icons:` line above; "
    .. "prune with tools/prune-icons.lua after a LibKa0s icons: edit.\n"
  local decl, err = VendorSync.iconDeclaration(doc)
  assertNil(err, "a mid-line mention is prose: " .. tostring(err))
  assertEqual(decl.names[1], "close", "the real line still parses")
  decl = VendorSync.iconDeclaration(PROVENANCE .. "\n- LibKa0s icons: none.\n")
  assertEqual(decl.mode, "none", "a `- ` list marker before the line is allowed")
  decl = VendorSync.iconDeclaration(PROVENANCE .. "\n  * LibKa0s icons: settings.\n")
  assertEqual(decl.names[1], "settings", "an indented `* ` list marker is allowed")
  decl, err = VendorSync.iconDeclaration(PROVENANCE .. "\n`LibKa0s icons:` close.\n")
  assertNil(decl, "a code span at line start is not the line")
  assertNil(err, "and is not an error either")
end)

local CATALOG_PATHS = {
  "LICENSE-open-iconic.txt", "close.tga", "settings.tga",
  "phosphor/LICENSE-phosphor.txt", "phosphor/sword.tga",
  "game-icons/AUTHORS.txt", "game-icons/LICENSE-game-icons.txt", "game-icons/skull.tga",
}

test("missingMarks: a list must name what the library draws, and only what the catalog carries", function()
  local cat = VendorSync.iconCatalog(CATALOG_PATHS)
  local missing = VendorSync.missingMarks(VendorSync.parseIconLine("settings."), cat)
  assertEqual(table.concat(missing, ","), "close", "of the marks, this catalog holds only close")
  assertEqual(#VendorSync.missingMarks(VendorSync.parseIconLine("close, settings."), cat), 0)
  assertEqual(#VendorSync.missingMarks(VendorSync.parseIconLine("none."), cat), 0, "none ships nothing")
  assertEqual(#VendorSync.missingMarks(VendorSync.parseIconLine("all (icon picker)."), cat), 0)
end)

test("the library-drawn marks are all real Media icons", function()
  for _, name in ipairs(VendorSync.LIBRARY_MARKS) do
    assertTrue(io.open("LibKa0s/media/icons/" .. name .. ".tga", "rb") ~= nil, name)
  end
end)

test("iconCatalog: names and attribution by set folder", function()
  local cat = VendorSync.iconCatalog(CATALOG_PATHS)
  assertEqual(cat.names.close, "close.tga")
  assertEqual(cat.names["ph:sword"], "phosphor/sword.tga")
  assertEqual(cat.names["gi:skull"], "game-icons/skull.tga")
  assertNil(cat.names.sword, "a Phosphor mark is not reachable unprefixed")
  assertEqual(table.concat(cat.attribution[""], ","), "LICENSE-open-iconic.txt")
  assertEqual(table.concat(cat.attribution["ph:"], ","), "phosphor/LICENSE-phosphor.txt")
  assertEqual(#cat.attribution["gi:"], 2, "the license and AUTHORS.txt")
end)

test("requiredIcons: attribution travels with its set, unknown names come back", function()
  local cat = VendorSync.iconCatalog(CATALOG_PATHS)
  local want, unknown = VendorSync.requiredIcons(VendorSync.parseIconLine("gi:skull, nope, ph:nope."), cat, CATALOG_PATHS)
  assertEqual(table.concat(want, ","), "game-icons/AUTHORS.txt,game-icons/LICENSE-game-icons.txt,game-icons/skull.tga")
  assertEqual(table.concat(unknown, ","), "nope,ph:nope")
  want = VendorSync.requiredIcons(VendorSync.parseIconLine("settings."), cat, CATALOG_PATHS)
  assertEqual(table.concat(want, ","), "LICENSE-open-iconic.txt,settings.tga")
  want = VendorSync.requiredIcons(VendorSync.parseIconLine("none."), cat, CATALOG_PATHS)
  assertEqual(#want, 0, "none ships no icon and no license")
  want = VendorSync.requiredIcons(VendorSync.parseIconLine("all (icon picker)."), cat, CATALOG_PATHS)
  assertEqual(#want, #CATALOG_PATHS, "all ships everything")
end)

test("cappedList: ten names, then a count", function()
  local names = {}
  for i = 1, 13 do names[i] = ("n%02d"):format(i) end
  local text = VendorSync.cappedList(names)
  assertTrue(text:find("n10, ... and 3 more", 1, true) ~= nil, text)
  assertTrue(text:find("n11", 1, true) == nil, text)
end)

-- ── the sound declaration (kit revision 55) ─────────────────────────────────────────────────

local ICONS_NONE = "LibKa0s icons: none."

test("parseSoundLine: the three forms", function()
  assertEqual(VendorSync.parseSoundLine("none.").mode, "none")
  assertEqual(VendorSync.parseSoundLine(" all. ").mode, "all", "bare, no reason")
  local list = VendorSync.parseSoundLine("callout/male-joe, callout/female-kathleen.")
  assertEqual(list.mode, "list")
  assertEqual(table.concat(list.names, ","), "callout/female-kathleen,callout/male-joe", "sorted")
end)

test("parseSoundLine: malformed lines are refused, naming why", function()
  local cases = {
    { "callout/female-kathleen", "end with a period" },
    { ".", "names nothing" },
    { "all (voice picker).", "no parenthesized reason" },
    { "callout/a,, callout/b.", "empty entry" },
    { "callout/a,.", "empty entry" },
    { "callout/a, none.", "stands alone" },
    { "all, callout/a.", "stands alone" },
    { "callout.", "not a voice pack" },
    { "callout/a/go.ogg.", "not a voice pack" },
    { "None.", "not a voice pack" },
    { "callout/a, callout/a.", "declared twice" },
  }
  for _, c in ipairs(cases) do
    local decl, err = VendorSync.parseSoundLine(c[1])
    assertNil(decl, c[1])
    assertTrue(err:find(c[2], 1, true) ~= nil, c[1] .. ": " .. tostring(err))
  end
end)

test("soundDeclaration: no line means none, not a transition", function()
  local decl, err = VendorSync.soundDeclaration(PROVENANCE .. "\n" .. ICONS_NONE .. "\n")
  assertNil(err)
  assertEqual(decl.mode, "none", "no line is none")
  assertTrue(decl.implicit, "and says it was implied")
  decl = VendorSync.soundDeclaration("# CLAUDE.md\n")
  assertEqual(decl.mode, "none", "even with no icons line")
end)

test("soundDeclaration: placed, misplaced, doubled", function()
  local decl = VendorSync.soundDeclaration("# X\r\n" .. PROVENANCE .. "\r\n" .. ICONS_NONE
    .. "\r\nLibKa0s sounds: callout/female-a.\r\n")
  assertEqual(decl.names[1], "callout/female-a", "directly under the icons line, CRLF")
  assertNil(decl.implicit)
  decl = VendorSync.soundDeclaration(PROVENANCE .. "\n" .. ICONS_NONE .. "\n\n\nLibKa0s sounds: all.\n")
  assertEqual(decl.mode, "all", "blank lines between are allowed")
  local err
  decl, err = VendorSync.soundDeclaration(PROVENANCE .. "\n" .. ICONS_NONE .. "\nProse.\nLibKa0s sounds: none.\n")
  assertTrue(decl == nil and err:find("directly under", 1, true) ~= nil, tostring(err))
  decl, err = VendorSync.soundDeclaration(PROVENANCE .. "\nLibKa0s sounds: none.\n")
  assertTrue(decl == nil and err:find("`LibKa0s icons:` line", 1, true) ~= nil, "no icons line to sit under: "
    .. tostring(err))
  decl, err = VendorSync.soundDeclaration(PROVENANCE .. "\n" .. ICONS_NONE
    .. "\nLibKa0s sounds: none.\nLibKa0s sounds: all.\n")
  assertTrue(decl == nil and err:find("2 times", 1, true) ~= nil, tostring(err))
  decl, err = VendorSync.soundDeclaration(PROVENANCE .. "\n" .. ICONS_NONE
    .. "\nLibKa0s sounds: none.\n\nSee the `LibKa0s sounds:` line above.\n")
  assertTrue(err == nil and decl.mode == "none", "a mid-line mention is prose: " .. tostring(err))
end)

local SOUND_PATHS = {
  "README.md",
  "callout/female-a/CREDITS.md", "callout/female-a/LICENSE.txt", "callout/female-a/go.ogg",
  "callout/male-b/CREDITS.md", "callout/male-b/go.ogg",
}

test("soundCatalog and requiredSounds: a pack is its folder, credits and license included", function()
  local cat = VendorSync.soundCatalog(SOUND_PATHS)
  assertEqual(#cat.packs["callout/female-a"], 3)
  assertEqual(#cat.packs["callout/male-b"], 2)
  assertEqual(table.concat(cat.loose, ","), "README.md", "a file in no pack folder")
  assertNil(cat.packs.callout, "a group folder is not a pack")
  local want, unknown = VendorSync.requiredSounds(VendorSync.parseSoundLine("callout/female-a, callout/nope."),
    cat, SOUND_PATHS)
  assertEqual(table.concat(want, ","), "callout/female-a/CREDITS.md,callout/female-a/LICENSE.txt,callout/female-a/go.ogg")
  assertEqual(table.concat(unknown, ","), "callout/nope")
  assertEqual(#VendorSync.requiredSounds(VendorSync.parseSoundLine("none."), cat, SOUND_PATHS), 0,
    "none ships nothing, a loose file included")
  assertEqual(#VendorSync.requiredSounds(VendorSync.parseSoundLine("all."), cat, SOUND_PATHS), #SOUND_PATHS)
end)

-- ── the gate, against a real tag ────────────────────────────────────────────────────────────

local function sh(cmd)
  local p = io.popen(cmd .. " 2>&1")
  local out = p and p:read("*a") or ""
  if p then p:close() end
  return out
end

local function write(path, body)
  local f = assert(io.open(path, "wb"))
  f:write(body)
  f:close()
end

local function tempRoot()
  local made = (sh("mktemp -d"):match("^%s*(.-)%s*$"))
  if made == "" or not made:match("^/") then
    T.skip("no `mktemp -d` on this host, so the vendor-sync fixtures cannot be built")
  end
  if not sh("git --version"):match("^git version") then
    T.skip("no `git` on this host, so the fixture library cannot be tagged")
  end
  return made
end

-- A NUL keeps git from ever reading the art as text, and the CR LF pair inside is the byte pair
-- the gate must never normalize in a binary.
local ART = "TGA\0\r\n"

local LIB_FILES = {
  ["LibKa0s/Core.lua"] = "-- core\n",
  ["LibKa0s/media/fonts/font.ttf"] = "TTF\0\r\n",
  -- Shipped beside a face as its license (Expressway-EULA.pdf, LK-A2 of the 2026-10-30 run): a
  -- binary the gate once normalized, because its extension was missing from BINARY_EXT.
  ["LibKa0s/media/fonts/EULA.pdf"] = "%PDF-1.4\r\n%\0\226\r\nendobj\r\n",
  -- Its text sibling (Expressway-EULA-Guide.html): an LF blob that a CRLF working tree checks
  -- out as CR LF, so the gate must normalize it where it compares the PDF raw.
  ["LibKa0s/media/fonts/Guide.html"] = "<p>terms</p>\n<p>more</p>\n",
  ["LibKa0s/media/icons/close.tga"] = ART .. "close",
  ["LibKa0s/media/icons/settings.tga"] = ART .. "settings",
  ["LibKa0s/media/icons/LICENSE-open-iconic.txt"] = "MIT\n",
  ["LibKa0s/media/icons/phosphor/sword.tga"] = ART .. "sword",
  ["LibKa0s/media/icons/phosphor/LICENSE-phosphor.txt"] = "MIT\n",
  ["LibKa0s/media/icons/game-icons/skull.tga"] = ART .. "skull",
  ["LibKa0s/media/icons/game-icons/LICENSE-game-icons.txt"] = "CC BY 3.0\n",
  ["LibKa0s/media/icons/game-icons/AUTHORS.txt"] = "skull Lorc\n",
  ["testkit/framework.lua"] = "-- kit\n",
}

--- A library repo tagged v9.9.9 at `<tmp>/LibKa0s`, and a consumer at `<tmp>/Addon` carrying the
--- whole copy and a CLAUDE.md whose declaration lines are `iconsLine` (nil for none at all; it may
--- carry a sounds line after a newline). `withSounds` gives the library its voice packs.
--- The voice packs a v1.96.0-shaped fixture library adds: two packs, each with its own credits, and
--- one with a license file too. A tag without them is the shape of every tag before v1.96.0.
local LIB_SOUNDS = {
  ["LibKa0s/media/sounds/callout/female-a/go.ogg"] = "OggS\0\r\nfemale go",
  ["LibKa0s/media/sounds/callout/female-a/stop.ogg"] = "OggS\0\r\nfemale stop",
  ["LibKa0s/media/sounds/callout/female-a/CREDITS.md"] = "# female-a\n",
  ["LibKa0s/media/sounds/callout/female-a/LICENSE.txt"] = "CC BY 4.0\n",
  ["LibKa0s/media/sounds/callout/male-b/go.ogg"] = "OggS\0\r\nmale go",
  ["LibKa0s/media/sounds/callout/male-b/CREDITS.md"] = "# male-b\n",
}

local function fixture(iconsLine, withSounds)
  local tmp = tempRoot()
  local lib, addon = tmp .. "/LibKa0s", tmp .. "/Addon"
  local files = {}
  for path, body in pairs(LIB_FILES) do files[path] = body end
  if withSounds then
    for path, body in pairs(LIB_SOUNDS) do files[path] = body end
  end
  for path in pairs(files) do
    sh(('mkdir -p "%s/%s"'):format(lib, path:match("^(.*)/")))
  end
  for path, body in pairs(files) do write(lib .. "/" .. path, body) end
  sh(('git -C "%s" init -q && git -C "%s" add -A && git -C "%s" -c user.name=kit '
    .. '-c user.email=kit@example.invalid -c commit.gpgsign=false commit -q -m fixture '
    .. '&& git -C "%s" tag v9.9.9'):format(lib, lib, lib, lib))
  sh(('mkdir -p "%s/libs/LibKa0s" && cp -r "%s/LibKa0s/." "%s/libs/LibKa0s/"'):format(addon, lib, addon))
  local doc = "# CLAUDE.md\n\n" .. PROVENANCE .. "\n" .. (iconsLine and (iconsLine .. "\n") or "")
  write(addon .. "/CLAUDE.md", doc)
  return tmp, addon
end

local function withFixture(iconsLine, body, withSounds)
  local tmp, addon = fixture(iconsLine, withSounds)
  local ok, err = pcall(body, addon)
  sh(('rm -rf "%s"'):format(tmp))
  if not ok then error(err, 0) end
end

--- Run the library pair's case against `addon`. Answers true, or false and the failure message.
local function gate(addon)
  local cases = {}
  local fake = {
    test = function(name, fn) cases[name] = fn end,
    skip = function(reason) error("SKIP " .. tostring(reason), 0) end,
    assertTrue = T.assertTrue, assertEqual = T.assertEqual,
  }
  VendorSync.register(fake, { root = addon })
  local ok, err = pcall(cases[LIB_CASE])
  if not ok and tostring(err):find("^SKIP") then T.skip(err) end
  return ok, tostring(err)
end

local function rm(addon, path) os.remove(addon .. "/libs/LibKa0s/media/icons/" .. path) end

--- Leave exactly `keep` (paths relative to media/icons) in the consumer's icon folder.
local function prune(addon, keep)
  local set = {}
  for _, p in ipairs(keep) do set[p] = true end
  for _, p in ipairs(CATALOG_PATHS) do
    if not set[p] then rm(addon, p) end
  end
end

-- ── binaries compare byte for byte (LK-A2) ─────────────────────────────────────────────────

test("vendor sync: a byte-identical PDF holding CR LF pairs passes, and one edited byte fails", function()
  withFixture(nil, function(addon)
    local ok, err = gate(addon)
    assertTrue(ok, "a byte-identical PDF is not line-end normalized: " .. err)
    write(addon .. "/libs/LibKa0s/media/fonts/EULA.pdf", "%PDF-1.4\n%\0\226\nendobj\n")
    ok, err = gate(addon)
    assertTrue(not ok and err:find("EULA.pdf matches", 1, true) ~= nil,
      "a PDF that lost its CRs is a different file: " .. err)
  end)
end)

test("vendor sync: a CR LF copy of an LF text blob passes, and one edited byte under it fails", function()
  withFixture(nil, function(addon)
    local path = addon .. "/libs/LibKa0s/media/fonts/Guide.html"
    write(path, "<p>terms</p>\r\n<p>more</p>\r\n")
    local ok, err = gate(addon)
    assertTrue(ok, "a CR LF checkout of an LF text blob is the same file: " .. err)
    write(path, "<p>terms</p>\r\n<p>mare</p>\r\n")
    ok, err = gate(addon)
    assertTrue(not ok and err:find("Guide.html matches", 1, true) ~= nil,
      "a CR LF copy with one changed content byte is a different file: " .. err)
  end)
end)

test("vendor sync: every extension .gitattributes pins binary is one the gate compares raw", function()
  local f = assert(io.open(".gitattributes", "rb"), "this repo carries a .gitattributes")
  local body = f:read("*a")
  f:close()
  local pinned, missing = 0, {}
  for line in (body:gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do
    local ext, attrs = line:match("^%*%.([%w]+)%s+(.-)%s*$")
    local binary = attrs and (" " .. attrs .. " "):find("%sbinary%s") ~= nil
    if binary then
      pinned = pinned + 1
      if not VendorSync.isBinary("x." .. ext) then missing[#missing + 1] = ext end
    end
  end
  assertTrue(pinned > 0, ".gitattributes pins at least one extension binary")
  assertEqual(table.concat(missing, ", "), "",
    "testkit/vendor_sync.lua's BINARY_EXT covers every `*.<ext> binary` line in .gitattributes")
  assertTrue(VendorSync.isBinary("Media/Expressway-EULA.PDF"), "the match ignores case")
  assertTrue(not VendorSync.isBinary("LibKa0s/Core.lua") and not VendorSync.isBinary("README"),
    "text, and a name with no extension, are normalized")
end)

test("vendor sync: no `LibKa0s icons:` line is the whole-folder gate", function()
  withFixture(nil, function(addon)
    assertTrue(gate(addon), "the whole copy passes")
    rm(addon, "phosphor/sword.tga")
    local ok, err = gate(addon)
    assertTrue(not ok, "a pruned copy with no declaration fails")
    assertTrue(err:find("holds the same files", 1, true) ~= nil, err)
  end)
end)

test("vendor sync: `none.` ships no icon and no icon license", function()
  withFixture("LibKa0s icons: none.", function(addon)
    local ok, err = gate(addon)
    assertTrue(not ok, "the whole copy fails under none")
    assertTrue(err:find("8 undeclared file(s)", 1, true) ~= nil, err)
    prune(addon, {})
    ok, err = gate(addon)
    assertTrue(ok, err)
  end)
end)

test("vendor sync: a list ships exactly its icons and their sets' attribution", function()
  withFixture("LibKa0s icons: close, settings, gi:skull.", function(addon)
    local exact = { "close.tga", "settings.tga", "LICENSE-open-iconic.txt", "game-icons/skull.tga",
      "game-icons/LICENSE-game-icons.txt", "game-icons/AUTHORS.txt" }
    prune(addon, exact)
    local ok, err = gate(addon)
    assertTrue(ok, err)
    rm(addon, "game-icons/AUTHORS.txt")
    ok, err = gate(addon)
    assertTrue(not ok and err:find("1 declared file(s) are missing", 1, true) ~= nil, err)
    assertTrue(err:find("game-icons/AUTHORS.txt", 1, true) ~= nil, "names it: " .. err)
  end)
end)

test("vendor sync: a list that leaves out a library-drawn icon fails, and says which", function()
  withFixture("LibKa0s icons: settings.", function(addon)
    prune(addon, { "settings.tga", "LICENSE-open-iconic.txt" })
    local ok, err = gate(addon)
    assertTrue(not ok, "close draws blank")
    assertTrue(err:find("leaves out 1 icon(s)", 1, true) ~= nil, err)
    assertTrue(err:find(": close.", 1, true) ~= nil, err)
  end)
end)

test("vendor sync: an undeclared icon fails, counted and named", function()
  withFixture("LibKa0s icons: close, settings.", function(addon)
    prune(addon, { "settings.tga", "LICENSE-open-iconic.txt", "close.tga", "game-icons/skull.tga",
      "phosphor/sword.tga" })
    local ok, err = gate(addon)
    assertTrue(not ok, "two undeclared icons ship")
    assertTrue(err:find("2 undeclared file(s)", 1, true) ~= nil, err)
    assertTrue(err:find("game-icons/skull.tga, phosphor/sword.tga", 1, true) ~= nil, err)
    assertTrue(err:find("prune-icons.lua", 1, true) ~= nil, "says how to fix it: " .. err)
  end)
end)

test("vendor sync: a name the tag does not carry fails, even if a stray file vouches for it", function()
  withFixture("LibKa0s icons: close, settings, ph:axe.", function(addon)
    prune(addon, { "close.tga", "settings.tga", "LICENSE-open-iconic.txt" })
    write(addon .. "/libs/LibKa0s/media/icons/phosphor/axe.tga", ART)
    local ok, err = gate(addon)
    assertTrue(not ok and err:find("1 icon name(s)", 1, true) ~= nil, err)
    assertTrue(err:find("ph:axe", 1, true) ~= nil, err)
  end)
end)

test("vendor sync: a declared icon that differs from the tag fails", function()
  withFixture("LibKa0s icons: close.", function(addon)
    prune(addon, { "close.tga", "LICENSE-open-iconic.txt" })
    write(addon .. "/libs/LibKa0s/media/icons/close.tga", ART .. "edited")
    local ok, err = gate(addon)
    assertTrue(not ok and err:find("close.tga matches", 1, true) ~= nil, err)
  end)
end)

test("vendor sync: outside media/icons the copy is still compared whole", function()
  withFixture("LibKa0s icons: none.", function(addon)
    prune(addon, {})
    os.remove(addon .. "/libs/LibKa0s/media/fonts/font.ttf")
    local ok, err = gate(addon)
    assertTrue(not ok and err:find("outside media/icons/", 1, true) ~= nil, err)
  end)
end)

test("vendor sync: `all` needs its reason, and with one is the whole folder", function()
  withFixture("LibKa0s icons: all.", function(addon)
    local ok, err = gate(addon)
    assertTrue(not ok and err:find("parenthesized reason", 1, true) ~= nil, err)
    write(addon .. "/CLAUDE.md", PROVENANCE .. "\nLibKa0s icons: all (icon picker).\n")
    ok, err = gate(addon)
    assertTrue(ok, err)
    rm(addon, "close.tga")
    ok = gate(addon)
    assertTrue(not ok, "all is held to the whole folder")
  end)
end)

-- ── the sound subset, against a real tag (kit revision 55) ──────────────────────────────────

local SOUNDS_DIR = "/libs/LibKa0s/media/sounds"

local function sounds(addon) return table.concat(VendorSync.localNames(addon .. SOUNDS_DIR), ",") end
local function rmSound(addon, path) os.remove(addon .. SOUNDS_DIR .. "/" .. path) end
local function rmSounds(addon) sh(('rm -rf "%s%s"'):format(addon, SOUNDS_DIR)) end
local function rmPack(addon, pack) sh(('rm -rf "%s%s/%s"'):format(addon, SOUNDS_DIR, pack)) end

test("vendor sync: no `LibKa0s sounds:` line is none, so a copied pack fails until pruned", function()
  withFixture(ICONS_NONE, function(addon)
    prune(addon, {})
    local ok, err = gate(addon)
    assertTrue(not ok, "the packs the cp -r brought fail with no line")
    assertTrue(err:find("6 undeclared file(s) ship under", 1, true) ~= nil, err)
    assertTrue(err:find("no line means none", 1, true) ~= nil, "says why: " .. err)
    rmSounds(addon)
    ok, err = gate(addon)
    assertTrue(ok, "an absent folder is the conforming state: " .. err)
  end, true)
end)

test("vendor sync: a tag without media/sounds and no line passes, as every tag before v1.96.0", function()
  withFixture(ICONS_NONE, function(addon)
    prune(addon, {})
    local ok, err = gate(addon)
    assertTrue(ok, err)
  end)
end)

test("vendor sync: `none.` ships no sound, and an empty folder passes", function()
  withFixture(ICONS_NONE .. "\nLibKa0s sounds: none.", function(addon)
    prune(addon, {})
    local ok, err = gate(addon)
    assertTrue(not ok and err:find("6 undeclared file(s)", 1, true) ~= nil, err)
    assertTrue(err:find("no line means none", 1, true) == nil, "the line is there: " .. err)
    rmPack(addon, "callout/female-a")
    rmPack(addon, "callout/male-b")
    ok, err = gate(addon)
    assertTrue(ok, err)
  end, true)
end)

test("vendor sync: a list ships exactly its packs, credits and license included", function()
  withFixture(ICONS_NONE .. "\nLibKa0s sounds: callout/female-a.", function(addon)
    prune(addon, {})
    rmPack(addon, "callout/male-b")
    local ok, err = gate(addon)
    assertTrue(ok, err)
    rmSound(addon, "callout/female-a/CREDITS.md")
    ok, err = gate(addon)
    assertTrue(not ok and err:find("1 declared file(s) are missing", 1, true) ~= nil, err)
    assertTrue(err:find("callout/female-a/CREDITS.md", 1, true) ~= nil, "names it: " .. err)
  end, true)
end)

test("vendor sync: an undeclared pack fails, and a declared one that differs from the tag fails", function()
  withFixture(ICONS_NONE .. "\nLibKa0s sounds: callout/female-a.", function(addon)
    prune(addon, {})
    local ok, err = gate(addon)
    assertTrue(not ok and err:find("2 undeclared file(s)", 1, true) ~= nil, err)
    assertTrue(err:find("callout/male-b/CREDITS.md, callout/male-b/go.ogg", 1, true) ~= nil, err)
    rmPack(addon, "callout/male-b")
    write(addon .. SOUNDS_DIR .. "/callout/female-a/go.ogg", "OggS\0\nfemale go")
    ok, err = gate(addon)
    assertTrue(not ok and err:find("go.ogg matches", 1, true) ~= nil, "a binary is compared raw: " .. err)
  end, true)
end)

test("vendor sync: a pack the tag does not carry fails, even if a stray file vouches for it", function()
  withFixture(ICONS_NONE .. "\nLibKa0s sounds: callout/nope.", function(addon)
    prune(addon, {})
    rmSounds(addon)
    sh(('mkdir -p "%s%s/callout/nope"'):format(addon, SOUNDS_DIR))
    write(addon .. SOUNDS_DIR .. "/callout/nope/go.ogg", "OggS")
    local ok, err = gate(addon)
    assertTrue(not ok and err:find("1 voice pack(s)", 1, true) ~= nil, err)
    assertTrue(err:find("callout/nope", 1, true) ~= nil, err)
  end, true)
end)

test("vendor sync: `all.` compares media/sounds whole; a malformed line fails", function()
  withFixture(ICONS_NONE .. "\nLibKa0s sounds: all.", function(addon)
    prune(addon, {})
    local ok, err = gate(addon)
    assertTrue(ok, err)
    rmSound(addon, "callout/male-b/CREDITS.md")
    ok, err = gate(addon)
    assertTrue(not ok and err:find("outside media/icons/", 1, true) ~= nil, "held whole: " .. err)
    write(addon .. "/CLAUDE.md", PROVENANCE .. "\n" .. ICONS_NONE .. "\nLibKa0s sounds: all (voices).\n")
    ok, err = gate(addon)
    assertTrue(not ok and err:find("no parenthesized reason", 1, true) ~= nil, err)
  end, true)
end)

test("vendor sync: outside both carved folders the copy is still compared whole", function()
  withFixture(ICONS_NONE, function(addon)
    prune(addon, {})
    rmSounds(addon)
    os.remove(addon .. "/libs/LibKa0s/media/fonts/font.ttf")
    local ok, err = gate(addon)
    assertTrue(not ok and err:find("outside media/icons/ and media/sounds/", 1, true) ~= nil, err)
  end, true)
end)

-- ── tools/prune-icons.lua ───────────────────────────────────────────────────────────────────

local function tool(addon)
  if not (arg and arg[-1]) then T.skip("no interpreter path (arg[-1]), so the tool cannot be run") end
  return sh(('{ %s tools/prune-icons.lua "%s"; echo "exit=$?"; }'):format(arg[-1], addon))
end

local function present(addon)
  local names = VendorSync.localNames(addon .. "/libs/LibKa0s/media/icons")
  return table.concat(names, ",")
end

test("prune-icons: a list keeps its icons and attribution, and the gate then passes", function()
  withFixture("LibKa0s icons: close, settings, ph:sword.", function(addon)
    local out = tool(addon)
    assertTrue(out:find("exit=0", 1, true) ~= nil, out)
    assertTrue(out:find("removed libs/LibKa0s/media/icons/game-icons/AUTHORS.txt", 1, true) ~= nil, out)
    assertTrue(out:find("kept 5 file(s), removed 3", 1, true) ~= nil, out)
    assertEqual(present(addon), "LICENSE-open-iconic.txt,close.tga,phosphor/LICENSE-phosphor.txt,phosphor/sword.tga,settings.tga")
    local ok, err = gate(addon)
    assertTrue(ok, err)
  end)
end)

test("prune-icons: none empties the folder; all and no line remove nothing", function()
  withFixture("LibKa0s icons: none.", function(addon)
    local out = tool(addon)
    assertTrue(out:find("removed 8", 1, true) ~= nil, out)
    assertEqual(present(addon), "")
    assertTrue(gate(addon), "the gate passes the emptied copy")
  end)
  withFixture("LibKa0s icons: all (icon picker).", function(addon)
    local out = tool(addon)
    assertTrue(out:find("nothing removed", 1, true) ~= nil and out:find("exit=0", 1, true) ~= nil, out)
    assertEqual(#VendorSync.localNames(addon .. "/libs/LibKa0s/media/icons"), 8)
  end)
  withFixture(nil, function(addon)
    local out = tool(addon)
    assertTrue(out:find("nothing removed", 1, true) ~= nil, out)
    assertEqual(#VendorSync.localNames(addon .. "/libs/LibKa0s/media/icons"), 8)
  end)
end)

test("prune-icons: an unknown name is refused and nothing is removed", function()
  withFixture("LibKa0s icons: settings, ph:nope.", function(addon)
    local out = tool(addon)
    assertTrue(out:find("exit=1", 1, true) ~= nil, out)
    assertTrue(out:find("ph:nope", 1, true) ~= nil and out:find("Nothing was removed", 1, true) ~= nil, out)
    assertEqual(#VendorSync.localNames(addon .. "/libs/LibKa0s/media/icons"), 8)
  end)
  withFixture("LibKa0s icons: all.", function(addon)
    local out = tool(addon)
    assertTrue(out:find("exit=1", 1, true) ~= nil and out:find("parenthesized reason", 1, true) ~= nil, out)
  end)
end)

test("prune-icons: no sounds line removes every pack in the same run, and the gate passes", function()
  withFixture("LibKa0s icons: close, settings.", function(addon)
    local out = tool(addon)
    assertTrue(out:find("exit=0", 1, true) ~= nil, out)
    assertTrue(out:find("removed libs/LibKa0s/media/icons/phosphor/sword.tga", 1, true) ~= nil, out)
    assertTrue(out:find("removed libs/LibKa0s/media/sounds/callout/male-b/go.ogg", 1, true) ~= nil, out)
    assertTrue(out:find("no `LibKa0s sounds:` line); kept 0 file(s), removed 6", 1, true) ~= nil, out)
    assertEqual(sounds(addon), "")
    local ok, err = gate(addon)
    assertTrue(ok, err)
  end, true)
  withFixture(nil, function(addon)
    local out = tool(addon)
    assertTrue(out:find("whole folder ships; nothing removed", 1, true) ~= nil, "icons untouched: " .. out)
    assertEqual(#VendorSync.localNames(addon .. "/libs/LibKa0s/media/icons"), 8)
    assertEqual(sounds(addon), "", "sounds pruned even with no icons line")
    assertTrue(gate(addon), "the gate passes")
  end, true)
end)

test("prune-icons: a sounds list keeps its packs whole; all keeps everything", function()
  withFixture(ICONS_NONE .. "\nLibKa0s sounds: callout/female-a.", function(addon)
    local out = tool(addon)
    assertTrue(out:find("1 voice pack(s) declared; kept 4 file(s), removed 2", 1, true) ~= nil, out)
    assertEqual(sounds(addon), "callout/female-a/CREDITS.md,callout/female-a/LICENSE.txt,"
      .. "callout/female-a/go.ogg,callout/female-a/stop.ogg")
    local ok, err = gate(addon)
    assertTrue(ok, err)
  end, true)
  withFixture(ICONS_NONE .. "\nLibKa0s sounds: all.", function(addon)
    local out = tool(addon)
    assertTrue(out:find("all voice packs; no sound removed", 1, true) ~= nil, out)
    assertEqual(#VendorSync.localNames(addon .. SOUNDS_DIR), 6)
    assertTrue(gate(addon), "the gate passes")
  end, true)
end)

test("prune-icons: an unknown pack is refused and nothing is removed from either folder", function()
  withFixture(ICONS_NONE .. "\nLibKa0s sounds: callout/female-a, callout/nope.", function(addon)
    local out = tool(addon)
    assertTrue(out:find("exit=1", 1, true) ~= nil, out)
    assertTrue(out:find("callout/nope", 1, true) ~= nil and out:find("Nothing was removed", 1, true) ~= nil, out)
    assertTrue(out:find("removed libs/", 1, true) == nil, "no file went: " .. out)
    assertEqual(#VendorSync.localNames(addon .. "/libs/LibKa0s/media/icons"), 8, "icons none waited too")
    assertEqual(#VendorSync.localNames(addon .. SOUNDS_DIR), 6)
  end, true)
  withFixture(ICONS_NONE .. "\nLibKa0s sounds: callout/female-a, callout/female-a.", function(addon)
    local out = tool(addon)
    assertTrue(out:find("exit=1", 1, true) ~= nil and out:find("declared twice", 1, true) ~= nil, out)
    assertEqual(#VendorSync.localNames(addon .. SOUNDS_DIR), 6)
  end, true)
end)
