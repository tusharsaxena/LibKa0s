# `testkit` — version 60

> **This document is the source of truth for this version of the kit.** Anything else in this repo
> that describes the kit's surface points here rather than restating it. It describes the contract
> *as it is at this version* — not as it is now, unless this version is also the current one.

| | |
|---|---|
| Payload | `testkit/`, the files version 57 lists; no file added |
| Version | **60** (`Kit.VERSION`, top of `framework.lua`) |
| Vendored to | `<Addon>/tests/_kit/` — **never** `libs/`, and never shipped |
| First released in | v1.110.0 |
| Status | Superseded |
| Supersedes | [version 59](version-59-docs.md) — the client profiles carried no container or bank shape, so `Compat.ContainerGroups` answered its fallback and the bank readers nil under both |
| Superseded by | [version 61](version-61-docs.md) — adds `mock_foreverdb.lua`, the opt-in fake of the ForeverDB data addon |
| Sync gate | Byte-identity, enforced by `tests/test_kitsync.lua` |
| Confirm in a consumer | `_G.<X>_TEST.KIT_VERSION` → `60` |

Everything revision 59 describes is unchanged here except what follows. No file is added. Three files
change: `mock_client.lua`, which gains the container and bank shape below, `README.md`, whose row for
it says so, and `framework.lua`, whose `Kit.VERSION` is 60 and which changes in nothing else. No public
member is added, removed or renamed and no kit case is added, removed or renamed. The item is
`K101-LK-02` of Ka0sAddonsCommonTasks `docs/2026-11-22-LIBKA0S_101_CONTAINER_READER/` (LibKa0s#101).

## What changed

### Each client profile carries its client's `Enum.BagIndex`, `Enum.BankType` and `C_Bank.CanViewBank`

`MockClient.apply` (run by `loader.lua` on every mock set it builds an environment over) now also fills
the container and bank shape of the profile's client, as each client's generated API documentation
lists it (`BagIndexConstantsDocumentation.lua`, `ItemConstantsDocumentation.lua`,
`BankDocumentation.lua`):

| | `retail` (12.1.5) | `forever` (1.60.1) |
|---|---|---|
| `Enum.BagIndex` members | 20 | 27 |
| `Accountbanktab`, `Characterbanktab`, `Keyring` | -3, -2, -1 | -3, -2, -1 |
| `Backpack`, `Bag_1`..`Bag_4`, `ReagentBag` | 0, 1..4, 5 | 0, 1..4, 5 |
| `CharacterBankTab_N` | 1..6 = 6..11 | 1..9 = 6..14 |
| `AccountBankTab_N` | 1..5 = 12..16 | 1..9 = 15..23 |
| `Enum.BankType` | Character 0, Guild 1, Account 2 | the same |
| `C_Bank.CanViewBank(Character)` | `true` | `true` |
| `C_Bank.CanViewBank(Account)` | `true` | `false` (no warband bank, ruling R1) |
| `C_Bank.CanViewBank(Guild)` or another number | `false` | `false` |
| `C_Bank.CanViewBank(nil)` or a non-number | raises `Usage: local canViewBank = C_Bank.CanViewBank(bankType)` | the same |

`bankType` is not nilable in either client's documentation, so a non-number raises rather than
answering (fidelity rule 1). The kit models no other `C_Bank` member: a consumer that reads
`FetchNumPurchasedBankTabs` or anything else still builds it.

So on a bare kit harness `Compat.ContainerGroups()` (`LibKa0s-Compat-1.0` minor 6) answers
`{ bags = 0..5, bank = 6..11, accountBank = 12..16 }` under `retail` and
`{ bags = -1, 0..5, bank = 6..14, accountBank = {} }` under `forever`, and
`Compat.CanViewCharacterBank()` answers `true` under both.

### A consumer's own mock wins

The rule is global by global, and the profile only fills a global the consumer left out:

- An `Enum` carrying `BagIndex` and `BankType` only when neither the set nor the real global table has
  an `Enum`, so a consumer that put `Enum` on `_G` is not shadowed. An `Enum` the consumer built is never
  touched, not even to add `BagIndex`: a set whose `Enum.BagIndex` a case cleared before its
  environment was built is testing exactly that absence (LootHistory's `tests/test_compat.lua` has such
  a case).
- A `C_Bank` only when neither the set nor the real global table has one. A `C_Bank` the consumer built
  is never given a `CanViewBank` it left out, because "this build has no `CanViewBank`" is a shape a
  suite may be testing.
- What an apply installed it remembers by identity (weak-keyed), so applying a second profile to the
  same set replaces the kit's own tables and never one a consumer put in their place. Inside the kit's
  own `Enum` it replaces only the members it put there, so a `BindingSet` that `mock_bindings.lua`
  merged in stays. Every apply builds fresh tables, so a case that edits them reaches no other mock set.

A consumer that sets these after its environment is built simply overwrites them, as before.

`tests/test_mock_client.lua` pins both profiles' shapes, the `CanViewBank` answers and raise, the
consumer-wins rules for the set and for `_G`, the re-apply and the fresh tables.
`tests/test_compat_containers.lua`'s profile cases no longer plant an enum: they read the active
profile's.

## What a consumer owes

The whole-folder copy of `tests/_kit/`, as at every revision. A suite that pins `KIT_VERSION` at 59
re-pins it at 60. A consumer whose own mock builds an `Enum` and a `C_Bank` sees no change. One that
builds no `Enum`, or no `C_Bank`, now reads the profile's, so a case that wants either absent must remove
it in the case, as it would have to in a client that has them.
