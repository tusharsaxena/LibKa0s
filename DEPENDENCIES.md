# DEPENDENCIES

Everything needed to work on LibKa0s, with install commands for **WSL2 / Ubuntu** — the collection's
development environment. Every entry names what needs it and how that is known, so nothing here is
speculative: a list that asks you to install three things you did not need is a list you stop
trusting before you reach the one that mattered.

`DEPENDENCIES.md` answers *what to install*. [`docs/automated-tests/README.md`](docs/automated-tests/README.md)
answers *how to verify*, and [`docs/releasing.md`](docs/releasing.md) answers *how to release*.

Required by `documentation-§7`, which binds this repo unchanged (`library-stack-§7`).

## Runtime (in-game)

**Nothing.** LibKa0s is a **library, not an addon**: it has no `.toc`, it is never installed by a
player, and it never appears in the addon list. It is vendored whole-folder into each host addon's
`libs/LibKa0s/` and loaded through that addon's TOC — see
[README.md → Installing](README.md#installing). A player who has a Ka0s addon already has every copy
of this library they will ever need.

The only runtime requirement is therefore World of Warcraft (Retail), by way of whichever host addon
vendored the code.

## Development

Three tools. Only the first has a version that matters.

| Tool | Version | Verified with | Why it is needed |
|---|---|---|---|
| `lua5.1` | **5.1 exactly — a hard requirement** | Lua 5.1.5 | The headless harness sets each chunk's environment with **`setfenv`** (`testkit/loader.lua:31` and `:50`), which exists only in Lua 5.1. |
| `luacheck` | any recent | 1.2.0 | The `lint` suite — `luacheck .`, the gating half of the green gate. |
| `lizard` | any recent | 1.23.0 | The `complexity` suite. Recorded on every run; at the tag it gates (`automated-tests-§3`). |

The "verified with" column is the toolchain of the last recorded run,
[`docs/automated-tests/20260805-002859/manifest.json`](docs/automated-tests/20260805-002859/manifest.json)
→ `host` — evidence, not a pin. `luacheck` and `lizard` are pinned nowhere and pinning them would be
false precision; `lua5.1` is not a preference. "5.2 will probably work" is **false**, and it costs an
hour to disprove: 5.2 removed `setfenv`, and the loader is the first thing every suite touches.

Also assumed present, and not installed separately on any normal WSL2 / Ubuntu box:

| Tool | Why it is needed |
|---|---|
| `git` | `tests/test_kitsync.lua` shells out to `git ls-files -s` to assert the runner's `100755` mode in **both** kit copies. The exec bit is not in a file's bytes, so no byte-identity check can ever see it. |
| POSIX `ls` | `Kit.assertSuiteInventory` lists `tests/` with `ls -A` via `io.popen` (`testkit/framework.lua:214`), falling back to `dir /b` under cmd.exe. When neither is available the gate **fails** rather than reporting a pass — an empty listing means "could not look", never "empty directory". |
| `bash` | `testkit/run-automated-tests.sh` is `#!/usr/bin/env bash` and uses `set -uo pipefail` and arrays. |

### Install

```sh
sudo apt update
sudo apt install -y lua5.1 git

# luacheck comes from LuaRocks, built against the 5.1 headers
sudo apt install -y luarocks liblua5.1-0-dev
sudo luarocks install luacheck

# lizard is a Python tool. Ubuntu 24.04 marks its Python EXTERNALLY-MANAGED (PEP 668), so a plain
# `pip install lizard` FAILS with an error that looks like a broken system rather than a policy.
# pipx is the instruction that works.
sudo apt install -y pipx
pipx install lizard
pipx ensurepath        # then reopen the shell, or `source ~/.bashrc`
```

### Verify

```sh
lua5.1 -v            # Lua 5.1.5
luacheck --version    # 1.2.0
lizard --version      # 1.23.0
git --version
```

If `lua` on your `PATH` is not 5.1, either invoke `lua5.1` explicitly — every command in this repo's
docs written as `lua …` means "a 5.1 interpreter" — or point `lua` at it:

```sh
sudo update-alternatives --install /usr/bin/lua lua /usr/bin/lua5.1 100
```

## Release / assets

**Nothing beyond the development set.** There is no packaging step, no CurseForge upload and no
generated image or binary asset in this repo: `packaging` does not bind a library repo
(`library-stack-§7`), and releasing is git plus the commands in
[`docs/releasing.md`](docs/releasing.md). You do not need to install anything extra to cut a release,
and you certainly do not need a graphics stack to fix a typo.

## What this repo is verified with

From the repo root, with the development set installed:

```sh
lua5.1 tests/run.lua                                # the headless suite — 0 failed
luacheck .                                          # 0 warnings / 0 errors, in 12 files
lizard -l lua -x "./libs/*" -x "./tests/_kit/*" .   # recorded; 0 functions above CCN 15
tests/_kit/run-automated-tests.sh                   # all of the above, frozen into a bundle
```

The first two are the **green gate**: no commit without both clean. The `luacheck` count is scoped by
`.luacheckrc`'s `exclude_files` — the eight files in `LibKa0s/` plus the four in `testkit/`; `tests/`
and `docs/` are excluded, so 0/0 only means something if what you changed is inside that set.

There is **no `tests/perf.lua`** here, so the runner's `perf` suite is a standing `skip`. A skip is
never a pass — see [`docs/automated-tests/README.md`](docs/automated-tests/README.md).

## Keeping this file honest

`documentation-§7`: this file is checked at release alongside the rest of the doc set. A new tool a
test shells out to, a new import, or a dropped dependency changes this file **in the same commit**. A
dependency list that is wrong is the one defect that makes a new contributor's first hour their last.
