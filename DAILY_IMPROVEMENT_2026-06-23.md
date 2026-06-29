# Daily Improvement — 2026-06-23

Tests: **3056 passing, 0 failing** (verified with Godot 4.6 headless on this machine).

## Bug fixes

1. **Restored the main scene in `project.godot`.** `run/main_scene` had been left
   pointing at `res://tests/test_runner.tscn` (a leftover from a local test run).
   Shipping/exporting in that state would launch the *test runner* instead of the
   game. Reverted to `res://scenes/main.tscn`.

2. **HUD "enemies remaining" counter was misleading.** The readout used
   `GM.enemies.size()`, which only counts enemies already on the field (and even
   includes not-yet-culled corpses) while ignoring the spawn queue. A wave of 20
   could read "3" while 17 waited to spawn. Added `GM.enemies_remaining()`
   (alive on field + still queued) and wired the HUD to it for an honest count.

3. **Recovered 5 dormant test suites.** `build_spawn_constants`,
   `relic_drop_constants`, `dice_aoe_flash_constants`, `banner_and_cheat_constants`
   and `overview_panel_constants` were all defined but never called from `_ready()`,
   so their assertions were silently sitting out of the suite. Wired all five back
   into the runner.

## Code quality

4. **Extracted damage-number jitter magic numbers.** The inline
   `fmod(dmg * 7.3, 16.0) - 8.0` that nudges floating damage numbers apart is now
   `DMG_NUM_JITTER_FACTOR` (7.3) and `DMG_NUM_JITTER_SPAN` (16.0) in `game_config`,
   with the half-span derived from the span so the band can be tuned in one place.

5. **`Config.wave_count()` helper + invariant.** A single source of truth for the
   number of defined waves, with a test pinning `wave_count() == MAX_WAVES` (a
   mismatch would make the victory check fire on the wrong wave).

6. **`Config.wave_enemy_count(index)` helper.** Pure, range-safe sum of the enemy
   counts scheduled in a wave — available for "X enemies this wave" UI and balance
   tests. Returns 0 for out-of-range indices instead of crashing.

## Test coverage (new suites)

7. **Damage Number Jitter** — constants are positive and the computed horizontal
   offset always lands inside the symmetric `[-span/2, +span/2)` band.

8. **Enemies Remaining** — counts alive + queued, and excludes dead-but-uncull
   corpses.

9. **Wave Count Helper** — `wave_count()` agrees with `WAVE_DATA.size()` and
   `MAX_WAVES`.

10. **Wave Enemy Count** — wave 1 = 3 enemies, out-of-range returns 0, and the
    helper matches a hand sum for every wave (each wave schedules ≥1 enemy).

11. **Enemy Data Integrity** — every enemy has its required keys with positive
    hp/speed/radius/core_dmg/sin_reward, and any `relic_drop` is a valid probability.

12. **Tower Data Integrity** — every tower has its required keys with positive
    damage/range/cost/upgrade_cost, and positive attack speed for all non-support
    towers (Hades is exempt).

13. **Demonic Pact Integrity** — `DEMONIC_PACTS.size()` matches `PACT_POOL_SIZE`,
    every pact has its full field set with unique names and non-empty descriptions.

14. **Relic Loot Integrity** — every loot `type` has a matching handler branch in
    `drop_relic` (an unhandled type would drop and do nothing), weights are positive,
    names are unique, and the table still sums to 100.

## Notes

- All changes are data/logic and test additions; no rendering or audio behavior was
  altered. The full suite was run headless to confirm nothing regressed.
