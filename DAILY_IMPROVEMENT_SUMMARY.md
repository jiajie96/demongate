# Daily Improvement Summary — 2026-05-06

## Changes Made

### 1. Bug Fix: Dice AoE Now Tracks Stats & Uses combat_kill (Bug Fix)
`_damage_all_percent()` (used by Devil's Dice Hellstorm and Small Spark) was bypassing `combat_kill()`, meaning dice AoE kills didn't track `boss_kills` stat, didn't trigger relic drops, and didn't count `total_damage_dealt`. Now routes through `combat_kill()` for consistent behavior and tracks damage in stats.

### 2. Extract Tower Build Duration Constant (Code Quality)
Magic number `0.3` in `create_tower()` → `Config.TOWER_BUILD_DURATION`. Build animation duration is now tunable from one place.

### 3. Extract Tower Fire Flash Constant (Code Quality)
Five occurrences of `fire_flash = 0.3` across tower update functions → `Config.TOWER_FIRE_FLASH`. Attack pose hold time is now a single constant.

### 4. Extract Enemy Spawn Duration Constant (Code Quality)
Magic number `0.4` in `create_enemy()` → `Config.ENEMY_SPAWN_DURATION`. Spawn fade-in timer is now configurable.

### 5. Extract Relic Drop Rate Constants (Code Quality/Balance)
Inline magic numbers in `should_drop_relic()` → four named constants: `RELIC_DROP_BOSS` (1.0), `RELIC_DROP_WAR_TITAN` (0.15), `RELIC_DROP_MEDIUM` (0.05), `RELIC_DROP_DEFAULT` (0.03). Makes drop rates visible, tunable, and testable.

### 6. Extract Dice AoE Flash Duration Constants (Code Quality)
Magic numbers `0.2` and `0.15` for dice AoE flash timers → `Config.DICE_AOE_FLASH_STRONG` and `Config.DICE_AOE_FLASH_WEAK`.

### 7. Add wave_completion_bonus() Helper (Code Quality)
Extracted wave bonus formula into a standalone `GM.wave_completion_bonus(wave_num)` function. Reduces duplication between `complete_wave()` and tests, and makes the bonus calculation independently testable.

### 8. New Tests: Build/Spawn/Fire Flash Constants (Test Coverage — 6 assertions)
Validates `TOWER_BUILD_DURATION`, `ENEMY_SPAWN_DURATION`, and `TOWER_FIRE_FLASH` constants exist with correct values, and verifies `create_tower`/`create_enemy` use them.

### 9. New Tests: Relic Drop, Dice Flash, Damage Percent, Wave Bonus, Projectile, Pact Flow (Test Coverage — 46 assertions)
Seven new test suites covering:
- Relic drop rate constants (ordering, ranges)
- Dice AoE flash constants
- `_damage_all_percent` stat tracking and boss kill detection
- `wave_completion_bonus` formula verification across waves
- Projectile creation lifecycle (position, speed, AoE flags)
- Full pact accept/decline flow (Soul Harvest, Dark Resilience, empty pact safety)

### 10. Total Test Count
**448 assertions** across **64 test suites** (up from 396 assertions / 57 suites).

## Summary
Focused on code quality (extracting 9 magic numbers into named constants), fixing a stat-tracking bug in dice AoE damage, and adding 52 new test assertions covering previously untested systems (projectile lifecycle, pact accept/decline flow, percentage-based AoE damage).
