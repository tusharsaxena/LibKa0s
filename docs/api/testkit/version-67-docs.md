# `testkit` — version 67

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files [version 61](version-61-docs.md) lists |
| Version | **67** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.120.0 (unreleased) |
| Status | **Current** |
| Supersedes | [version 66](version-66-docs.md) — the vendor-sync gate FAILED a payload case whose provenance tag the present sibling checkout could not resolve, where testing-§11 says skip |
| Superseded by | — |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `67` |

Everything revision 66 describes is unchanged here except what follows. No file is added or removed,
and no kit case is added, removed or renamed. `framework.lua`'s `Kit.VERSION` is 67. The item is
LibKa0s#110 (Drop Watcher review `docs/reviews/2026-11-28/` F-012), fixed in `L3` of Ka0s Drop
Watcher's plan `docs/superpowers/plans/2026-11-28-issue-fixes.md`, on the owner's ruling of
2026-11-28: the kit changes, testing-§11 does not.

## What changed

### `vendor_sync.lua`: an unresolvable provenance tag is a skip carrying its reason

testing-§11 makes a vendor-sync case a skip carrying its reason when its precondition is absent: the
sibling checkout is not there, **or the ref cannot be resolved**. Revision 66 honored only the first
half. With the sibling present it went on to compare, so a provenance line naming a tag the sibling
does not have (a consumer re-vendored from a library branch before its tag is cut, or a sibling that
has not fetched it) failed both payload cases on `ls-tree` and every blob. Drop Watcher and Ka0s Item
Search each wrapped the gate in a pre-tag shim for that.

From revision 67 each payload case asks the sibling `git rev-parse --verify --quiet "<tag>^{commit}"`
after reading the provenance line, and when that answers nothing the case registers `Kit.skip` with
the reason:

```
<sibling> cannot resolve v1.120.0, the tag CLAUDE.md's provenance line names (not cut yet, or not
fetched) — the vendored payload was NOT compared
```

No byte of the payload is read in that case, so a skip says nothing about the copy, either way.

What still **fails**, unchanged:

- a tag that resolves, with a vendored file whose content differs from it;
- a tag that resolves, with a file it carries missing from the copy, or a file the copy carries that
  it does not (the file-set comparison, and under `media/icons/` and `media/sounds/` the declared
  shape);
- a provenance document carrying no `Bundles [LibKa0s](...) vX.Y.Z (MIT).` line at all.

The absent-sibling skip and the runner-mode case are as at revision 66.

## What a consumer owes

The whole-folder copy of `tests/_kit/`, as at every revision. A suite that pins `KIT_VERSION` at 66
re-pins it at 67. A consumer that wrapped `VendorSync.register` in its own pre-tag shim (skipping the
payload cases until its provenance tag exists) can delete the shim and call the gate bare; the kit
now does what the shim did, with the reason in the skip.

## Tests

`tests/test_kit_vendor_sync.lua` gains four cases against a real fixture tag: an unresolvable tag is
a skip naming the tag (and stays a skip with an edited copy); once the tag resolves, a copy whose
content differs fails and a matching one passes; at a resolvable tag a missing file and an extra
file each fail; an absent sibling checkout is still a skip. `tests/test_kit_inventory.lua` pins
revision 67.
