-- tools/prune-icons.lua — cut a consumer's vendored icon and sound folders down to what it declares.
--
--   lua tools/prune-icons.lua <consumer repo>    # from anywhere; after the `cp -r` re-vendor
--
-- WHY THIS EXISTS. `media/icons/` is the first carve-out from whole-folder vendoring
-- (`library-stack-§7`, standard v2.85.0; kit revision 40). LibKa0s v1.74.0 took it to 5,836 TGAs,
-- about 18 MB (28 MB on disk), and an addon that draws a settings glyph or two should not ship all of them. So a
-- consumer declares which icons it ships, in one line directly under the provenance line of its
-- root CLAUDE.md:
--
--   LibKa0s icons: all (icon picker).            -- the whole catalog; a player-facing chooser only
--   LibKa0s icons: none.                         -- no icon files, no icon license files
--   LibKa0s icons: settings, close, ph:sword.    -- exactly these, by their lib.ICONS names
--
-- `media/sounds/` is the second (`library-stack-§7` *The sound subset*, standard v2.108.0; kit
-- revision 55): from LibKa0s v1.96.0 it holds the Callout's voice packs, one folder each at
-- `media/sounds/callout/<voice>/` with the pack's license and credits inside it. A consumer
-- declares the packs it ships in one line directly under its icons line:
--
--   LibKa0s sounds: none.                        -- no sound file at all
--   LibKa0s sounds: all.                         -- every pack
--   LibKa0s sounds: callout/female-kathleen.     -- exactly these packs, each whole
--
-- and NO SOUNDS LINE MEANS NONE (sounds are opt-in), where no icons line means all (the transition).
--
-- The re-vendor is still `cp -r LibKa0s/. <Addon>/libs/LibKa0s/`, followed by this tool, which in
-- one run deletes every file under `<Addon>/libs/LibKa0s/media/icons/` the icons line does not
-- require (the undeclared icons, and a set's attribution files, the non-TGA files beside its icons,
-- when none of that set's icons is declared), then every file under
-- `<Addon>/libs/LibKa0s/media/sounds/` outside the declared packs. Icons `all`, or no icons line, is
-- a no-op for icons; sounds `all` is a no-op for sounds. The consumer's `tests/test_vendor_sync.lua`
-- then holds the result to the same declarations. The tool keeps its name so every existing
-- re-vendor flow that runs it prunes both folders without a new step.
--
-- ONE PARSER, NOT TWO. Both lines are parsed, and both catalogs derived, by the kit's own
-- `testkit/vendor_sync.lua` — the gate that will judge the result — loaded from beside this file.
-- A tool with its own reading of a line could produce a copy the gate refuses.
--
-- WHICH CATALOG. A name is checked against the icons or packs the consumer's copy holds when the
-- tool runs, which right after the `cp -r` is the whole catalog at the tag being vendored. A name
-- that is not there is REFUSED and NOTHING is deleted, in either folder: both declarations are
-- read and resolved before the first file goes. It is a typo, a name the tag does not carry, or a
-- name an earlier prune already removed (re-copy the folder, then run this again).
--
-- Pure Lua 5.1 and no dependencies. Listing a directory shells out (`find`), as the gate does.

local function here()
  local script = arg and arg[0] or "tools/prune-icons.lua"
  return script:match("^(.*)[/\\][^/\\]*$") or "."
end

local VendorSync = dofile(here() .. "/../testkit/vendor_sync.lua")

local ICONS = "libs/LibKa0s/media/icons"
local SOUNDS = "libs/LibKa0s/media/sounds"
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

--- The icon step's plan: `{ rel, dir, paths, want, subdirs, summary }`, or nil when the icons
--- line asks for nothing to be removed (it says so). Refuses, removing nothing, on a bad line.
local function planIcons()
  local decl, err = VendorSync.iconDeclaration(doc)
  if err then refuse(("%s/%s: %s"):format(root, DOC, err)) end
  if not decl then
    print(("prune-icons: %s declares no `LibKa0s icons:` line, so the whole folder ships; "
      .. "nothing removed"):format(root))
    return nil
  end
  if decl.mode == "all" then
    print(("prune-icons: %s declares all icons (%s); nothing removed"):format(root, decl.reason))
    return nil
  end
  local dir = root .. "/" .. ICONS
  local paths = VendorSync.localNames(dir)
  local want, unknown = VendorSync.requiredIcons(decl, VendorSync.iconCatalog(paths), paths)
  if #unknown > 0 then
    refuse(("%s/%s declares %d name(s) not among the icons in %s: %s. Nothing was removed. A typo, "
      .. "a name the vendored tag does not carry, or one an earlier prune removed: re-copy the "
      .. "folder and run again"):format(root, DOC, #unknown, dir, VendorSync.cappedList(unknown)))
  end
  return { rel = ICONS, dir = dir, paths = paths, want = want, subdirs = { "phosphor", "game-icons" },
    summary = decl.mode == "none" and "none" or (#decl.names .. " icon(s) declared") }
end

--- The sound step's plan, the same shape, or nil for `all`. No line is `none`.
local function planSounds()
  local decl, err = VendorSync.soundDeclaration(doc)
  if err then refuse(("%s/%s: %s"):format(root, DOC, err)) end
  if decl.mode == "all" then
    print(("prune-icons: %s declares all voice packs; no sound removed"):format(root))
    return nil
  end
  local dir = root .. "/" .. SOUNDS
  local paths = VendorSync.localNames(dir)
  local cat = VendorSync.soundCatalog(paths)
  local want, unknown = VendorSync.requiredSounds(decl, cat, paths)
  if #unknown > 0 then
    refuse(("%s/%s declares %d voice pack(s) not among the packs in %s: %s. Nothing was removed. "
      .. "A typo, a pack the vendored tag does not carry, or one an earlier prune removed: re-copy "
      .. "the folder and run again"):format(root, DOC, #unknown, dir, VendorSync.cappedList(unknown)))
  end
  -- Pack folders first, then their group folders (`callout`), so an emptied tree goes whole.
  local subdirs, groups = {}, {}
  for pack in pairs(cat.packs) do
    subdirs[#subdirs + 1] = pack
    groups[pack:match("^([^/]+)/")] = true
  end
  table.sort(subdirs)
  for group in pairs(groups) do subdirs[#subdirs + 1] = group end
  local summary = decl.mode == "list" and (#decl.names .. " voice pack(s) declared")
    or (decl.implicit and "sounds none (no `LibKa0s sounds:` line)" or "sounds none")
  return { rel = SOUNDS, dir = dir, paths = paths, want = want, subdirs = subdirs, summary = summary }
end

--- Delete every file of `plan` its declaration does not require; answers the failures.
local function apply(plan, failed)
  local keep = {}
  for _, p in ipairs(plan.want) do keep[p] = true end
  local removed = 0
  for _, p in ipairs(plan.paths) do
    if not keep[p] then
      local ok, why = os.remove(plan.dir .. "/" .. p)
      if ok then
        removed = removed + 1
        print("removed " .. plan.rel .. "/" .. p)
      else
        failed[#failed + 1] = p .. " (" .. tostring(why) .. ")"
      end
    end
  end
  -- A folder left empty goes too. `os.remove` deletes only an EMPTY directory, so this cannot take
  -- a file with it; where it fails (the folder still holds a kept file, or the platform will not
  -- remove directories this way) the folder simply stays, which the gate does not mind.
  for _, sub in ipairs(plan.subdirs) do os.remove(plan.dir .. "/" .. sub) end
  print(("prune-icons: %s: %s; kept %d file(s), removed %d"):format(root, plan.summary,
    #plan.want, removed))
end

-- Both plans before the first deletion, so a refusal in either leaves both folders untouched.
local icons, sounds = planIcons(), planSounds()
local failed = {}
if icons then apply(icons, failed) end
if sounds then apply(sounds, failed) end
if #failed > 0 then
  refuse(("%d file(s) could not be removed: %s"):format(#failed, VendorSync.cappedList(failed)))
end
