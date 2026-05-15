# Daily Improvement — May 14, 2026

## Summary

10 improvements across code quality (magic number extraction), new helper functions, localization, and test coverage. 10 new test suites adding ~60 assertions.

## Changes

### Code Quality — Magic Number Extraction (6 improvements)
1. **Shake presets**: Extracted `shake(4.0, 0.2)`, `shake(2.0, 0.15)`, `shake(3.0, 0.15)` into named constants `SHAKE_CORE_HIT_*`, `SHAKE_WAVE_START_*`, `SHAKE_DICE_ROLL_*` for clarity and tuning.
2. **Sin Cache relic range**: Replaced `50 + randi() % 100` with `SIN_CACHE_MIN + randi() % SIN_CACHE_RANGE` constants.
3. **Legendary fallback sins**: Replaced `earn(80)` with `Config.LEGENDARY_FALLBACK_SINS`.
4. **Pandora sins reward**: Replaced `earn(100)` with `Config.PANDORA_SINS_REWARD`.
5. **Relic pickup FX radius**: Replaced `15.0` with `Config.RELIC_PICKUP_FX_RADIUS`.
6. **Special enemy types array**: Added `SPECIAL_ENEMY_TYPES` constant to replace inline string arrays in `start_wave()`.

### New Helpers (2 improvements)
7. **`is_special_enemy()`**: Centralized check for boss/elite enemy types, used in `start_wave()` spawn ordering. Replaces inline `edata.get("is_boss") or etype in [...]` pattern.
8. **`total_tower_damage()`**: Sums `total_damage` across a tower array for stats display. Encapsulates the common pattern of iterating towers for damage totals.

### Localization (1 improvement)
9. **New locale keys**: Added `legendary_fallback` and `pandora_sins` template strings (EN + ZH) so formerly hardcoded English messages now go through the translation system.

### Test Coverage (1 improvement — 10 new suites)
10. **10 new test suites** covering all new constants and helpers:
    - `_run_shake_preset_constants_tests` — 7 assertions
    - `_run_relic_pickup_fx_constant_tests` — 2 assertions
    - `_run_sin_cache_constant_tests` — 3 assertions
    - `_run_legendary_fallback_constant_tests` — 2 assertions
    - `_run_pandora_sins_constant_tests` — 4 assertions (incl. integration test)
    - `_run_special_enemy_helper_tests` — 12 assertions (all enemy types)
    - `_run_total_tower_damage_helper_tests` — 4 assertions (empty, single, multi, missing key)
    - `_run_special_enemy_types_constant_tests` — 11 assertions (existence + no-boss check)
    - `_run_shake_usage_tests` — 6 assertions (verify game_manager integration)
    - `_run_is_special_vs_drop_rate_tests` — 7 assertions (cross-check with relic drops)

## Files Modified
- `scripts/autoload/game_config.gd` — +40 lines (12 constants, 1 array, 2 helpers)
- `scripts/autoload/game_manager.gd` — net -8 lines (replaced magic numbers + inline checks)
- `scripts/autoload/locale.gd` — +8 lines (2 new template strings)
- `tests/test_runner.gd` — +170 lines (10 new test suites, ~60 assertions)

## Git Note
Commit `c229d37` created on branch `main`. Push requires SSH keys not available in sandbox — run `git push` from the host machine.
