# Daily Improvement — 2026-07-01

Ten improvements centered on the **Demonic Pact** economy, two per-frame
performance caches, a HUD readout fix, a robustness guard, and five new test
suites. The full suite passes at **3258/3258 assertions** (+64 new), and every
script — including `hud.gd`, which the test scene doesn't load — validates with
no parse errors.

## 1. Content — new Demonic Pact "Pact of Avarice"
An eighth pact and the greed gamble of the pool: **double Sin income for three
full waves**, paid for in **Core HP (−25)** rather than Sins. It's deliberately
the mirror image of Blood Tithe — that pact trades a little Core (−15) for a
modest, short income bump (×1.5 / 2 waves); Avarice trades a lot of Core (−25)
for a much bigger, longer bump (×2.0 / 3 waves). It reuses the existing
`sin_boost` benefit and `core_dmg` cost handlers, so no new `accept_pact` branch
was needed, and `PACT_POOL_SIZE` was bumped 7 → 8.

## 2. Localization — en/zh strings for the new pact
Added Chinese translations for the pact name ("贪婪契约"), its benefit ("Double
Sin income for 3 waves" → "罪孽收入翻倍，持续3波") and its cost ("Lose 25 Core HP"
→ "失去25核心生命值"), matching every other pact so zh players never see an
untranslated pact card.

## 3. Code quality — `GM.pact_count()` helper
Mirrors the existing `Config.wave_count()` pattern: a single source of truth for
`DEMONIC_PACTS.size()` so `maybe_offer_pact` no longer reaches into the config
array directly, and the `PACT_POOL_SIZE` invariant has a named accessor to test
against.

## 4. Robustness — empty-pool guard in `maybe_offer_pact`
`Config.DEMONIC_PACTS[randi() % pact_count()]` would divide by zero and crash on
an empty pool. Added a guard that simply offers no pact instead, mirroring the
defensive empty-array guard already in `_weighted_pick`.

## 5. UX — HUD enemy readout previews the next wave
Between waves the "Enemies: N / total" readout used the snapshot from the wave
that just **ended**, so it read a stale "0 / 24" while the player planned. New
`GM.enemies_total_display()` returns the live snapshot during a wave but the
**upcoming** wave's head-count between waves, so the readout now previews how big
the incoming wave is — and cleanly shows 0 once every wave is cleared.

## 6. Performance — precompute the Cocytus cone's cosine term
`_cocytus_cone` runs a per-enemy angular hit test every frame and was recomputing
`cos(half_angle)²` (plus a `TOWER_DATA` dictionary lookup) each call, even though
the cone angle is a fixed tower constant. `create_tower` now caches
`cone_half_angle` and `cone_cos_half_sq` once for beam-cone towers; the cone reads
them, falling back to a live compute for any tower dict built before the field
existed.

## 7. Performance — cache the wave spawn interval
`update_waves` re-indexed `Config.WAVE_DATA[wave - 1]` on **every enemy spawn**
just to read the constant `interval`. `start_wave` now snapshots it once into a
new `spawn_interval` state var (reset in `reset_state`), so the per-spawn path is
one field read instead of an array index + dictionary lookup.

## 8. Test coverage — Pact of Avarice suite
New `[Pact of Avarice]` suite verifies the pact's fields, that it's strictly
greedier than Blood Tithe (bigger multiplier, longer, costlier), that accepting
it sets `sin_multiplier=2.0` for 3 waves and drains 25 Core HP, that the shared
`core_dmg` floor keeps the Core ≥ 1, and that its zh strings resolve.

## 9. Test coverage — pact-count helper & enemies-total-display suites
`[Pact Count Helper]` pins `pact_count()` against both `DEMONIC_PACTS.size()` and
`PACT_POOL_SIZE`, and confirms `maybe_offer_pact` never offers below the min wave
yet eventually offers at a valid one. `[Enemies Total Display]` covers all three
branches of the new HUD helper (pre-wave preview, in-wave snapshot, post-final
zero).

## 10. Test coverage — perf-cache suites
`[Cocytus Cone Precompute]` asserts the cached `cone_half_angle` / `cone_cos_half_sq`
are present and correct on cone towers (and absent on others), and that the cone
still damages an enemy inside it via the cached term. `[Spawn Interval Cache]`
verifies `spawn_interval` is snapshotted from the correct wave's config and that
`spawn_timer` refills from it after a spawn tick.

---

**Existing tests updated:** the pact-count assertion (7 → 8) and the
Wrathful-Bargain test (was "newest pact is last entry" — now looks the pact up by
name so appending Avarice after it stays valid).

**Result:** 3258/3258 assertions passing, no parse errors, no behavioral
regressions.
