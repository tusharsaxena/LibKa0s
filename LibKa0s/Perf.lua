-- LibKa0s-Perf-1.0 — a repeatable A/B performance capture for World of Warcraft addons.
--
-- The value here is not the bucket counter. It is the PROTOCOL: two combat-gated measurement
-- windows over the same fight, differing only in whether the host addon is inert, with load order
-- and shared-frame ownership held fixed. WoW's own Addon Profiler cannot answer "is this cost even
-- ours?", because it bills a shared library's dispatch frame to whichever addon created it — so
-- enabling and disabling addons moves the blame around. Suspending changes only whether the host's
-- code runs.
--
-- Every instance owns its own frames. A lib-level shared frame would reproduce that exact
-- attribution pathology: the measuring instrument corrupting the attribution it exists to fix.
--
-- Depends on LibStub and nothing else, deliberately — no Ace3, so the lib is adoptable by addons
-- that are not on the Ace substrate.

local MAJOR, MINOR = "LibKa0s-Perf-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.MAJOR, lib.MINOR = MAJOR, MINOR

-- Record schema emitted by BuildRecord. See docs/record-schema.md.
lib.SCHEMA = 2

-- Default depth of the SavedVariables capture ring. Small on purpose: these are diagnostic
-- snapshots read by hand, not telemetry.
lib.DEFAULT_RING = 10
