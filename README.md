# LibKa0s

A Ka0s-owned shared library, vendored into Ka0s WoW addons the way Ace3 is — copied into each
addon's `libs/` folder rather than depended on at runtime. One LibStub major per module. The first
module is `LibKa0s-Perf-1.0`, a repeatable A/B performance capture: two combat-gated measurement
windows over the same fight, differing only in whether the host addon is inert, with load order and
shared-frame ownership held fixed. This is the only trustworthy answer to "is this cost even mine?"
— WoW's own Addon Profiler attributes a shared frame's CPU to whichever addon created it, so
enabling/disabling addons moves the blame around rather than isolating it.

The descriptor contract (what a host addon supplies to adopt `LibKa0s-Perf-1.0`) is written up here
once the contract is real — Task 7.

## Repo layout

```
LibKa0s/            -- the only folder that ships; vendor this into <Addon>/libs/LibKa0s/
  LibKa0s.xml        -- lib load list, referenced from the host addon's TOC lib block
  Perf.lua           -- LibKa0s-Perf-1.0
tests/               -- headless Lua test harness (not shipped)
docs/                -- development docs (not shipped)
LICENSE
README.md
CHANGELOG.md
.luacheckrc
```

## Development

Green gate before every commit, run from the repo root:

```bash
lua tests/run.lua
luacheck .
```

Both must be 0 warnings/errors — `lua tests/run.lua` reports `N passed, 0 failed, N total`,
`luacheck .` reports `0 warnings / 0 errors`.
