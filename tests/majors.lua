-- tests/majors.lua — every major this library ships and the files that make it up, in
-- LibKa0s.xml order. Returns the table; loaded with `dofile`.
--
-- It lives in its own file because it has two readers that must never disagree: tests/run.lua,
-- which publishes it to the suites as `T.majors`, and tools/gen-api-members.lua, which is not a
-- test and cannot reach a local inside the runner. A second copy in the tool is a second thing to
-- update when a major is added, and the failure it produces — a published member manifest for nine
-- majors out of ten — is silent in exactly the way this repo keeps building gates against.

-- tests/test_versioning.lua iterates this instead of naming Perf's two files inline, so adding a
-- major is one row here rather than an edit scattered through the suite — and a major added to the
-- XML but forgotten here surfaces as a versioning failure instead of as silence.
--
-- `paired` names a secondary file carrying the __<file>Minor / __<file>ProbeMinor guard, so the
-- pairing assertion generalises with the rest.
local MAJORS = {
  {
    major = "LibKa0s-Core-1.0",
    files = { "Core" },
    primary = "Core",
  },
  {
    major = "LibKa0s-Env-1.0",
    files = { "Env" },
    primary = "Env",
  },
  {
    major = "LibKa0s-Lifecycle-1.0",
    files = { "Lifecycle" },
    primary = "Lifecycle",
  },
  {
    major = "LibKa0s-Pool-1.0",
    files = { "Pool" },
    primary = "Pool",
  },
  {
    major = "LibKa0s-Item-1.0",
    files = { "Item" },
    primary = "Item",
  },
  {
    major = "LibKa0s-Media-1.0",
    files = { "Media" },
    primary = "Media",
  },
  {
    major = "LibKa0s-Widgets-1.0",
    files = { "Widgets" },
    primary = "Widgets",
  },
  {
    major = "LibKa0s-DebugLog-1.0",
    files = { "DebugLog" },
    primary = "DebugLog",
  },
  {
    major = "LibKa0s-Slash-1.0",
    files = { "Slash" },
    primary = "Slash",
  },
  {
    major = "LibKa0s-Launcher-1.0",
    files = { "Launcher" },
    primary = "Launcher",
  },
  {
    major = "LibKa0s-Options-1.0",
    files = { "Options", "OptionsWidgets", "OptionsTabs", "OptionsCompose", "OptionsScroll" },
    primary = "Options",
    paired = {
      { file = "OptionsWidgets", minorField = "__widgetsMinor", probeField = "__widgetsShellMinor" },
      { file = "OptionsTabs",    minorField = "__tabsMinor",    probeField = "__tabsShellMinor" },
      { file = "OptionsCompose", minorField = "__composeMinor", probeField = "__composeShellMinor" },
      { file = "OptionsScroll",  minorField = "__scrollMinor",  probeField = "__scrollShellMinor" },
    },
  },
  {
    major = "LibKa0s-Perf-1.0",
    files = { "Perf", "PerfPanel" },
    primary = "Perf",
    paired = { { file = "PerfPanel", minorField = "__panelMinor", probeField = "__panelProbeMinor" } },
  },
}
return MAJORS
