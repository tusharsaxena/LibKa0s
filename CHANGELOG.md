# Changelog

Two version numbers, and they are not the same thing. The repo carries a semver tag for humans. Each
**file** separately carries a LibStub **MINOR** integer that increments on every released change to
that file — that is what LibStub compares when it picks a winner between vendored copies, and a
released change that forgets its bump silently does not reach any host that already has the old copy.

Every release therefore opens with a version block naming each file's live minor. `tests/run.lua`
enforces that the block and `lib.MODULES` agree, so the two cannot drift. Release order is in
[docs/releasing.md](docs/releasing.md).

## Unreleased

Versions in this release: **Perf minor 1**, **PerfPanel minor 1**.

- Initial extraction from AbsorbTracker (issue
  [#17](https://github.com/tusharsaxena/AbsorbTracker/issues/17)) — the probe, the record schema, the
  guided run, and the step panel, as `LibStub("LibKa0s-Perf-1.0")`.
- Still minor 1: the whole-branch review's fixes fold into the initial extraction rather than
  following it, since nothing has been released yet. A panel now re-attaches whenever the probe
  beneath it came from a different vendored copy; `:New()` reads `lib` rather than `self` throughout,
  so a LibStub minor upgrade cannot leave an instance reporting one schema while emitting another;
  `descriptor.buckets` entries are validated; `ring` is clamped to at least one record; panel labels
  re-resolve on every repaint; and a panel click prints exactly what typing the same command prints.
- `lib.MODULES` publishes the live minor of every file in the major, so version skew across vendored
  copies is answerable from in-game rather than by reading source.
- Documentation: the descriptor contract, the `suspend`/`resume` host contract, the public surface,
  and the record schema (v2) are written up in `README.md` and `docs/record-schema.md` (issue
  [#4](https://github.com/tusharsaxena/LibKa0s/issues/4)).
