-- LibKa0s-Feed-1.0 -- FeedRow.lua, the toast feed's rows.
--
-- Builds a row's regions once, places them (icon side, alignment, heights) and paints them in the
-- style the shell snapshotted over the owner's skin, or the degraded look without one. The shell
-- (Feed.lua) reads it through `lib.__row` at call time:
--
--   Build(container)          a new row record over a frame parented to the container
--   Place(R, layout)          the regions laid out for the row's spec
--   Paint(R, spec, cfg, now)  the spec drawn in the style
--   Restyle(R, cfg)           the style re-applied after a skin switch or a Refresh
--
-- Minor 1 (LootHistory#38, task S1 of the Feed build): the shell of this half. Every member is a
-- stub that draws nothing until the rows land.

local lib = LibStub and LibStub("LibKa0s-Feed-1.0", true)
if not lib then return end

local ROW_MINOR = 1
-- Paired on the SHELL's minor as well as this file's own, as FeedModel.lua is.
if lib.__rowMinor and lib.__rowMinor >= ROW_MINOR and lib.__rowShellMinor == lib.MINOR then return end
lib.__rowMinor, lib.__rowShellMinor = ROW_MINOR, lib.MINOR

lib.MODULES = lib.MODULES or {}
lib.MODULES.FeedRow = ROW_MINOR

local R = {}

function R.Build(container)   -- luacheck: ignore 212
  return nil
end

function R.Place(row, layout)   -- luacheck: ignore 212
end

function R.Paint(row, spec, cfg, now)   -- luacheck: ignore 212
end

function R.Restyle(row, cfg)   -- luacheck: ignore 212
end

lib.__row = R
