# Daily Improvement — 2026-05-09

## Summary

Extracted 14 inline magic numbers to named constants in `game_config.gd`, fixed `should_drop_relic` to use config-defined drop rates instead of hardcoded values, and added 33 new test assertions across 4 new test suites. Total assertions: 477.

## Improvements

### 1. Fast Enemy Speed Multiplier → `FAST_ENEMY_SPEED_MULT` (1.3)
Pact/dice fast enemy speed buff was hardcoded as `spd *= 1.3` in `update_enemies`. Now centrally tunable.

### 2. Guardian Flash Duration → `GUARDIAN_FLASH_DURATION` (0.05)
Holy Sentinel's damage-blocked flash was `0.05` in two places (combat_hit and cocytus_cone). Extracted to single constant.

### 3. Wave Spawn Delay → `WAVE_SPAWN_DELAY` (0.5)
Initial delay before first enemy spawns at wave start. Was inline in `start_wave`.

### 4–5. Cocytus Visual Timers → `COCYTUS_EMIT_INTERVAL` (0.12), `COCYTUS_FROST_DURATION` (0.3)
Frost spike particle emission interval and enemy frost state duration, both previously hardcoded in `_cocytus_cone`.

### 6–7. Mass Corrupt Relic → `MASS_CORRUPT_SLOW` (0.3), `MASS_CORRUPT_DURATION` (5.0)
Corruption Wave relic slow effect values were inline in `drop_relic`.

### 8–9. Time Warp Relic → `TIME_WARP_SLOW_FACTOR` (0.35), `TIME_WARP_DURATION` (5.0)
Time Warp relic parameters were inline in `drop_relic`.

### 10–12. Tower Upgrade Constants → `UPGRADE_RANGE_MULT` (1.1), `UPGRADE_SPEED_MULT` (1.15), `UPGRADE_COST_SCALING` (1.5)
Per-level upgrade gains and exponential cost growth. Also fixed legendary blueprint upgrade to use same constants as regular upgrades (was duplicating inline values).

### 13. Hades Buff Default → `HADES_BUFF_DEFAULT` (1.5)
Speed buff for non-support towers when Hades-buffed was hardcoded in `update_towers`.

### 14. Heal Beam Duration → `FX_HEAL_BEAM_DURATION` (0.3)
Raphael heal beam visual effect duration was inline in `_raphael_heal`.

### Bug Fix: Relic Drop Rates
`should_drop_relic` was using hardcoded float values (`0.15`, `0.05`, `0.03`) instead of the `RELIC_DROP_*` constants already defined in `game_config.gd`. Now uses `Config.RELIC_DROP_BOSS`, `Config.RELIC_DROP_WAR_TITAN`, `Config.RELIC_DROP_MEDIUM`, `Config.RELIC_DROP_DEFAULT`.

## New Tests (33 assertions)

- **Extracted Constants Tests** (10): Validates all 14 new config constants exist with correct values, plus integration test for fast enemy speed.
- **Upgrade Scaling Constants Tests** (5): Verifies upgrade applies `UPGRADE_RANGE_MULT` and `UPGRADE_SPEED_MULT`, validates cost scaling.
- **Relic Drop Config Tests** (7): Validates all 4 drop rate constants, checks ordering invariant (boss > titan > medium > default), range checks.
- **Relic Effect Constants Tests** (7): Validates mass corrupt and time warp relic parameters, sanity checks (positive, <1.0).

## Note

Commit created locally but push failed (no SSH keys in sandbox). The commit `5fc00ee` needs to be pushed manually.
