# Changelog

Two version numbers, and they are not the same thing. The repo carries a semver tag for humans.
Each module separately carries a LibStub **MINOR** integer that increments on every released change
to that module — that is what LibStub compares when it picks a winner between vendored copies.

## Unreleased

- `LibKa0s-Perf-1.0` minor 1 — initial extraction from AbsorbTracker (issue
  [#17](https://github.com/tusharsaxena/AbsorbTracker/issues/17)).
- Still minor 1, unreleased: the whole-branch review's fixes fold into the initial extraction rather
  than following it. A panel now re-attaches whenever the probe beneath it came from a different
  vendored copy; `:New()` reads `lib` rather than `self` throughout, so a LibStub minor upgrade
  cannot leave an instance reporting one schema while emitting another; `descriptor.buckets` entries
  are validated; `ring` is clamped to at least one record; panel labels re-resolve on every repaint;
  and a panel click prints exactly what typing the same command prints.
- Documentation: the descriptor contract, the `suspend`/`resume` host contract, the public surface,
  and the record schema (v2) are now written up in `README.md` and `docs/record-schema.md` (issue
  [#4](https://github.com/tusharsaxena/LibKa0s/issues/4)).
