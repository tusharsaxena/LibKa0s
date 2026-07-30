# Changelog

Two version numbers, and they are not the same thing. The repo carries a semver tag for humans.
Each module separately carries a LibStub **MINOR** integer that increments on every released change
to that module — that is what LibStub compares when it picks a winner between vendored copies.

## Unreleased

- `LibKa0s-Perf-1.0` minor 1 — initial extraction from AbsorbTracker (issue
  [#17](https://github.com/tusharsaxena/AbsorbTracker/issues/17)).
- Documentation: the descriptor contract, the `suspend`/`resume` host contract, the public surface,
  and the record schema (v2) are now written up in `README.md` and `docs/record-schema.md` (issue
  [#4](https://github.com/tusharsaxena/LibKa0s/issues/4)).
