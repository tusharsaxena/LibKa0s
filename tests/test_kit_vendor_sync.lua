-- tests/test_kit_vendor_sync.lua — the vendored-payload gate's icon declaration (kit revision 40),
-- and tools/prune-icons.lua, which cuts a copy down to it.
--
-- WHAT IT PROVES. That `LibKa0s icons:` parses in its three forms and refuses everything else; that
-- the gate holds `libs/LibKa0s/media/icons/` to exactly what the line declares (undeclared icons
-- fail with a count, declared ones missing fail, unknown names fail against the TAG's catalog, each
-- set's attribution files travel with it) while everything else is still compared whole; that no
-- line at all is the old whole-folder gate; and that the tool leaves a copy the gate passes.
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
--- whole copy and a CLAUDE.md whose declaration line is `iconsLine` (nil for none at all).
local function fixture(iconsLine)
  local tmp = tempRoot()
  local lib, addon = tmp .. "/LibKa0s", tmp .. "/Addon"
  for path in pairs(LIB_FILES) do
    sh(('mkdir -p "%s/%s"'):format(lib, path:match("^(.*)/")))
  end
  for path, body in pairs(LIB_FILES) do write(lib .. "/" .. path, body) end
  sh(('git -C "%s" init -q && git -C "%s" add -A && git -C "%s" -c user.name=kit '
    .. '-c user.email=kit@example.invalid -c commit.gpgsign=false commit -q -m fixture '
    .. '&& git -C "%s" tag v9.9.9'):format(lib, lib, lib, lib))
  sh(('mkdir -p "%s/libs/LibKa0s" && cp -r "%s/LibKa0s/." "%s/libs/LibKa0s/"'):format(addon, lib, addon))
  local doc = "# CLAUDE.md\n\n" .. PROVENANCE .. "\n" .. (iconsLine and (iconsLine .. "\n") or "")
  write(addon .. "/CLAUDE.md", doc)
  return tmp, addon
end

local function withFixture(iconsLine, body)
  local tmp, addon = fixture(iconsLine)
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
  withFixture("LibKa0s icons: settings, gi:skull.", function(addon)
    local exact = { "settings.tga", "LICENSE-open-iconic.txt", "game-icons/skull.tga",
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

test("vendor sync: an undeclared icon fails, counted and named", function()
  withFixture("LibKa0s icons: settings.", function(addon)
    prune(addon, { "settings.tga", "LICENSE-open-iconic.txt", "close.tga", "phosphor/sword.tga" })
    local ok, err = gate(addon)
    assertTrue(not ok, "two undeclared icons ship")
    assertTrue(err:find("2 undeclared file(s)", 1, true) ~= nil, err)
    assertTrue(err:find("close.tga, phosphor/sword.tga", 1, true) ~= nil, err)
    assertTrue(err:find("prune-icons.lua", 1, true) ~= nil, "says how to fix it: " .. err)
  end)
end)

test("vendor sync: a name the tag does not carry fails, even if a stray file vouches for it", function()
  withFixture("LibKa0s icons: settings, ph:axe.", function(addon)
    prune(addon, { "settings.tga", "LICENSE-open-iconic.txt" })
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
  withFixture("LibKa0s icons: settings, ph:sword.", function(addon)
    local out = tool(addon)
    assertTrue(out:find("exit=0", 1, true) ~= nil, out)
    assertTrue(out:find("removed libs/LibKa0s/media/icons/game-icons/AUTHORS.txt", 1, true) ~= nil, out)
    assertTrue(out:find("kept 4 file(s), removed 4", 1, true) ~= nil, out)
    assertEqual(present(addon), "LICENSE-open-iconic.txt,phosphor/LICENSE-phosphor.txt,phosphor/sword.tga,settings.tga")
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
