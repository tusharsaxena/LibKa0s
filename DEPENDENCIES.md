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
`libs/LibKa0s/` (all but `media/icons/`, which carries only the icons the addon declares) and loaded through that addon's TOC — see
[README.md → Installing](README.md#installing). A player who has a Ka0s addon already has every copy
of this library they will ever need.

The only runtime requirement is therefore World of Warcraft (Retail), by way of whichever host addon
vendored the code.

`LibKa0s-Glow-1.0` drives LibCustomGlow-1.0 but does not carry it: the consumer vendors
LibCustomGlow-1.0 in its own `libs/`, and Glow resolves it with `LibStub` at every call, drawing
nothing when it is absent, so there is nothing to install here (the suite uses a fake,
`tests/test_glow.lua`).

## Development

Three tools. Only the first has a version that matters.

| Tool | Version | Verified with | Why it is needed |
|---|---|---|---|
| `lua5.1` | **5.1 exactly — a hard requirement** | Lua 5.1.5 | The headless harness sets each chunk's environment with **`setfenv`** (`testkit/loader.lua:72` and `:91`), which exists only in Lua 5.1. |
| `luacheck` | any recent | 1.2.0 | The `lint` suite — `luacheck .`, the gating half of the green gate. |
| `lizard` | 1.24.0 | 1.24.0 | The `complexity` suite. Recorded on every run; at the tag it gates (`automated-tests-§3`). The kit's sighted shadow (`testkit/lizard_sighted.lua`, kit revision 35) is written against 1.24.0's Lua reader; another version still runs, and its own blind spots surface as parity failures rather than as a quiet undercount. |

The "verified with" column is the toolchain of the last recorded run,
[`docs/automated-tests/20261022-155222/manifest.json`](docs/automated-tests/20261022-155222/manifest.json)
→ `host` — evidence, not a pin. `luacheck` is pinned nowhere and pinning it would be false precision;
`lizard` is named rather than pinned (see its row); `lua5.1` is not a preference. "5.2 will probably work" is **false**, and it costs an
hour to disprove: 5.2 removed `setfenv`, and the loader is the first thing every suite touches.

Also assumed present, and not installed separately on any normal WSL2 / Ubuntu box:

| Tool | Why it is needed |
|---|---|
| `git` | `tests/test_kitsync.lua` shells out to `git ls-files -s` to assert the runner's `100755` mode in **both** kit copies. The exec bit is not in a file's bytes, so no byte-identity check can ever see it. The kit's line-ending and layout-cap gates list the tracked set with `git ls-files -z` (`testkit/test_eol.lua:130`, `testkit/test_layout_cap.lua:171`), and `tests/test_kit_eol.lua` builds throwaway `git init` repositories as fixtures. |
| POSIX `ls` | `Kit.assertSuiteInventory` lists `tests/` with `ls -A` via `io.popen` (`testkit/inventory.lua:190`, where kit revision 28 moved the suite inventory), falling back to `dir /b` under cmd.exe. When neither is available the gate **fails** rather than reporting a pass — an empty listing means "could not look", never "empty directory". |
| POSIX `mktemp`, `mkdir`, `rm`, `pwd` | The kit's own inventory and line-ending suites build scratch repositories on disk through `io.popen` / `os.execute` (`tests/test_kit_inventory.lua:43`, `:58`, `:70`; `tests/test_kit_eol.lua:22`, `:32`, `:81`). |
| `bash` | `testkit/run-automated-tests.sh` is `#!/usr/bin/env bash` and uses `set -uo pipefail` and arrays. |
| POSIX `find`, `cp` | `testkit/vendor_sync.lua` lists a vendored copy with `find . -type f` (its `localNames`), and so does `tools/prune-icons.lua`, which reuses it; `tests/test_kit_vendor_sync.lua` builds a tagged fixture library and a consumer with `git init`, `cp -r` and `mktemp`. |

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
lizard --version      # 1.24.0
git --version
```

If `lua` on your `PATH` is not 5.1, either invoke `lua5.1` explicitly — every command in this repo's
docs written as `lua …` means "a 5.1 interpreter" — or point `lua` at it:

```sh
sudo update-alternatives --install /usr/bin/lua lua /usr/bin/lua5.1 100
```

## Release / assets

**Nothing extra to cut a release.** There is no packaging step and no CurseForge upload: `packaging`
does not bind a library repo (`library-stack-§7`), and releasing is git plus the commands in
[`docs/releasing.md`](docs/releasing.md).

**Re-vendoring needs nothing extra either.** `tools/prune-icons.lua`, which cuts a consumer's copied
`media/icons/` down to its `LibKa0s icons:` declaration, is pure Lua 5.1 with no dependencies beyond
the `lua5.1` and POSIX `find` above: `lua tools/prune-icons.lua <Addon>`.

**Regenerating the shipped art is the one thing that needs more**, and only when the art itself
changes. `tools/artwork/icon_cleaner.py` rebuilds `LibKa0s/media/icons/` and the generated
`LibKa0s/MediaIcons.lua` from three sets — Open Iconic, Phosphor and Game-icons — and is the
provenance record for that art, not a build step: the TGAs and the catalog it produces are committed.
You need it to add or replace an icon; you do not need it to fix a typo, run the suite, or cut a
release that does not touch the art. Its sibling `tools/artwork/bar_textures.py` synthesizes the
statusbars in `LibKa0s/media/textures/` from named constants — no network and no input files — and
needs Python 3, Pillow and NumPy only; `tools/artwork/glass_textures.py` does the same for the Glass
skin's border and fill. `tools/artwork/fonts.py` is the provenance record for the OFL skin faces in
`LibKa0s/media/fonts/`: `--fetch` downloads them from google/fonts at pinned commits, checking each
SHA-256, into `tools/artwork/.cache/fonts/`, and `--build` copies them in and cuts static weights
from the five variable ones (Inter, Nunito, Vollkorn, Bitter, Oxanium) with fontTools. `tools/skin_gallery.py`
crops in-game skin screenshots and builds the showcases in `media/screenshots/skins/`; it needs
Python 3, Pillow and NumPy only, and labels the showcases in the bundled Inter.

| Tool | Why | Install |
|---|---|---|
| Python 3 | The artwork tools are Python scripts (`tools/artwork/icon_cleaner.py`, `bar_textures.py`, `glass_textures.py`, `fonts.py`, and `tools/skin_gallery.py`) | `sudo apt install python3` |
| Pillow | Reads the source PNGs and writes the TGAs (`from PIL import Image`, in `icon_cleaner.py`, `bar_textures.py` and `glass_textures.py`); `skin_gallery.py` crops the screenshots and draws the showcase with it | `sudo apt install python3-pil` |
| NumPy | The recolor, solidify and normalize stages, the bar gradients and the Glass coverage are array work (`import numpy as np`, in `icon_cleaner.py`, `bar_textures.py` and `glass_textures.py`), as is `skin_gallery.py`'s edge search | `sudo apt install python3-numpy` |
| fontTools | `fonts.py --build` only: cuts the static weights of Inter, Nunito, Vollkorn, Bitter and Oxanium from upstream's variable fonts (`fontTools.varLib.instancer`, inside `instance`) | `sudo apt install python3-fonttools` |
| GitHub CLI | Fetches the upstream PNGs through `gh api`, which the script uses in place of raw.githubusercontent.com because that host times out from here often enough to be useless in a script | `sudo apt install gh && gh auth login` |
| resvg-py | `icon_cleaner.py` only: renders the Phosphor and Game-icons SVGs to 64×64 (`import resvg_py`, inside `render_svg`). No distro package exists, so it lives in a venv with its own Pillow and NumPy (below) | `python3 -m venv tools/artwork/.venv && tools/artwork/.venv/bin/pip install resvg-py pillow numpy` |
| `git` | `icon_cleaner.py --fetch` clones Phosphor and Game-icons shallowly at the commits pinned in the script, into `tools/artwork/.cache/src/` | already present (see above) |

**Ubuntu 24.04 trap:** `pip install pillow` fails on PEP 668's `EXTERNALLY-MANAGED` marker, and
`pipx` is no way round it here: Pillow and NumPy are libraries with no command to expose, so `pipx`
refuses them, and even forced in they land in a venv the system `python3` running these scripts never
sees. Use the distro packages above.

**The icon tool runs from its venv**, `tools/artwork/.venv` (gitignored, like the `.cache` beside
it), because resvg-py is pip-only — the PEP 668 trap above is exactly why it is a venv rather than a
system install. `bar_textures.py`, `glass_textures.py` and `fonts.py` keep using the system `python3`; run `fonts.py`
with `-I` too, since its cache holds downloaded fonts. Run the icon tool with `-I`: the
cache holds other people's repositories, read as data and never executed, and `-I` keeps the
interpreter from importing anything out of the working directory.

Verify:

```sh
python3 -c "import PIL, numpy; print(PIL.__version__, numpy.__version__)"
tools/artwork/.venv/bin/python -c "import resvg_py, PIL, numpy"
gh --version
tools/artwork/.venv/bin/python -I tools/artwork/icon_cleaner.py --fetch   # network: gh + git
tools/artwork/.venv/bin/python -I tools/artwork/icon_cleaner.py --build   # from the cache; no network
python3 tools/artwork/glass_textures.py                                    # no network
python3 -I tools/artwork/fonts.py --fetch --build                          # network: raw.githubusercontent.com
```

A clean rebuild must leave `git status` clean — the committed TGAs are what the tool produces.

## What this repo is verified with

From the repo root, with the development set installed:

```sh
lua5.1 tests/run.lua                                # the headless suite — 0 failed
luacheck .                                          # 0 warnings / 0 errors (file count: RESULTS.md)
tests/_kit/run-automated-tests.sh --no-bundle --suite complexity   # sighted lizard; 0 functions above CCN 15
tests/_kit/run-automated-tests.sh                   # all of the above, frozen into a bundle
```

The first two are the **green gate**: no commit without both clean. The `luacheck` count is scoped by
`.luacheckrc`'s `exclude_files` — everything but `tests/_kit/`, which is a byte copy of `testkit/`
and would report every finding twice (`.luacheckrc:4`). 0/0 only means something if what you changed
is inside that set.

There is **no `tests/perf.lua`** here, so the runner's `perf` suite is a standing `skip`. A skip is
never a pass — see [`docs/automated-tests/README.md`](docs/automated-tests/README.md).

## Keeping this file honest

`documentation-§7`: this file is checked at release alongside the rest of the doc set. A new tool a
test shells out to, a new import, or a dropped dependency changes this file **in the same commit**. A
dependency list that is wrong is the one defect that makes a new contributor's first hour their last.
