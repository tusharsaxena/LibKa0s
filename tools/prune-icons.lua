-- tools/prune-icons.lua — cut a consumer's vendored icon folder down to what it declares.
--
--   lua tools/prune-icons.lua <consumer repo>    # from anywhere; after the `cp -r` re-vendor
--
-- WHY THIS EXISTS. `media/icons/` is the one carve-out from whole-folder vendoring
-- (`library-stack-§7`, standard v2.85.0; kit revision 40). LibKa0s v1.74.0 took it to 5,836 TGAs,
-- about 18 MB (28 MB on disk), and an addon that draws a settings glyph or two should not ship all of them. So a
-- consumer declares which icons it ships, in one line directly under the provenance line of its
-- root CLAUDE.md:
--
--   LibKa0s icons: all (icon picker).            -- the whole catalog; a player-facing chooser only
--   LibKa0s icons: none.                         -- no icon files, no icon license files
--   LibKa0s icons: settings, close, ph:sword.    -- exactly these, by their lib.ICONS names
--
-- and the re-vendor is still `cp -r LibKa0s/. <Addon>/libs/LibKa0s/`, followed by this tool, which
-- deletes every file under `<Addon>/libs/LibKa0s/media/icons/` the declaration does not require: the
-- undeclared icons, and a set's attribution files (the non-TGA files beside its icons) when none of
-- that set's icons is declared. `all`, or no line at all, is a no-op. The consumer's
-- `tests/test_vendor_sync.lua` then holds the result to the same declaration.
--
-- ONE PARSER, NOT TWO. The line is parsed, and the catalog derived, by the kit's own
-- `testkit/vendor_sync.lua` — the gate that will judge the result — loaded from beside this file.
-- A tool with its own reading of the line could produce a copy the gate refuses.
--
-- WHICH CATALOG. A name is checked against the icons the consumer's copy holds when the tool runs,
-- which right after the `cp -r` is the whole catalog at the tag being vendored. A name that is not
-- there is REFUSED and nothing is deleted: it is a typo, a name the tag does not carry, or a name
-- an earlier prune already removed (re-copy the folder, then run this again).
--
-- Pure Lua 5.1 and no dependencies. Listing a directory shells out (`find`), as the gate does.

local function here()
  local script = arg and arg[0] or "tools/prune-icons.lua"
  return script:match("^(.*)[/\\][^/\\]*$") or "."
end

local VendorSync = dofile(here() .. "/../testkit/vendor_sync.lua")

local ICONS = "libs/LibKa0s/media/icons"
local DOC = "CLAUDE.md"

local function readAll(path)
  local fh = io.open(path, "rb")
  if not fh then return nil end
  local body = fh:read("*a")
  fh:close()
  return body
end

local function refuse(msg)
  io.stderr:write("prune-icons: ", msg, "\n")
  os.exit(1)
end

local root = arg and arg[1]
if not root or root == "" or root == "-h" or root == "--help" then
  io.stderr:write("usage: lua tools/prune-icons.lua <consumer repo>\n")
  os.exit(root and 0 or 2)
end
root = root:gsub("[/\\]+$", "")

local doc = readAll(root .. "/" .. DOC)
if not doc then refuse(("no %s/%s to read the `LibKa0s icons:` line from"):format(root, DOC)) end

local decl, err = VendorSync.iconDeclaration(doc)
if err then refuse(("%s/%s: %s"):format(root, DOC, err)) end
if not decl then
  print(("prune-icons: %s declares no `LibKa0s icons:` line, so the whole folder ships; "
    .. "nothing removed"):format(root))
  os.exit(0)
end
if decl.mode == "all" then
  print(("prune-icons: %s declares all icons (%s); nothing removed"):format(root, decl.reason))
  os.exit(0)
end

local dir = root .. "/" .. ICONS
local paths = VendorSync.localNames(dir)
local want, unknown = VendorSync.requiredIcons(decl, VendorSync.iconCatalog(paths), paths)
if #unknown > 0 then
  refuse(("%s/%s declares %d name(s) not among the icons in %s: %s. Nothing was removed. A typo, "
    .. "a name the vendored tag does not carry, or one an earlier prune removed: re-copy the "
    .. "folder and run again"):format(root, DOC, #unknown, dir, VendorSync.cappedList(unknown)))
end

local keep = {}
for _, p in ipairs(want) do keep[p] = true end
local removed, failed = 0, {}
for _, p in ipairs(paths) do
  if not keep[p] then
    local ok, why = os.remove(dir .. "/" .. p)
    if ok then
      removed = removed + 1
      print("removed " .. ICONS .. "/" .. p)
    else
      failed[#failed + 1] = p .. " (" .. tostring(why) .. ")"
    end
  end
end
-- A set folder left empty goes too. `os.remove` deletes only an EMPTY directory, so this cannot
-- take a file with it; where it fails (the folder still holds a kept file, or the platform will not
-- remove directories this way) the folder simply stays, which the gate does not mind.
for _, sub in ipairs({ "phosphor", "game-icons" }) do os.remove(dir .. "/" .. sub) end

print(("prune-icons: %s: %s; kept %d file(s), removed %d"):format(root,
  decl.mode == "none" and "none" or (#decl.names .. " icon(s) declared"), #want, removed))
if #failed > 0 then
  refuse(("%d file(s) could not be removed: %s"):format(#failed, VendorSync.cappedList(failed)))
end
