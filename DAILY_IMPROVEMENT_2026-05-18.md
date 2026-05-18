# Daily Improvement — 2026-05-18

## Summary

10 improvements across code quality, bug fixes, performance, stats tracking, and test coverage.

## Changes

### Code Quality: Extract 9 inline Color literals to game_config constants
- `COLOR_FX_ZEUS_BOLT`, `COLOR_FX_HEAL_BEAM`, `COLOR_FX_HADES_BEAM`, `COLOR_FX_HADES_CURSE`, `COLOR_FX_FROST_SPIKE`, `COLOR_FX_HIT_SPARK`, `COLOR_FX_AOE_SPLASH`, `COLOR_FX_SCREEN_FLASH_STRONG`, `COLOR_FX_SCREEN_FLASH_WEAK`
- game_manager.gd now has zero inline Color() constructors (excluding Color.WHITE/Color.RED)

### Bug Fix: heal_pulse effect used wrong duration
- `add_effect("heal_pulse", ...)` fell through to the default `FX_DEATH_DURATION` (0.5s) instead of using its own duration
- Added `FX_HEAL_PULSE_DURATION` constant (0.3s) and explicit match arm

### Bug Fix: screen_flash effect used wrong duration
- `add_effect("screen_flash", ...)` also fell through to death duration
- Added `FX_SCREEN_FLASH_DURATION` constant (0.3s) and explicit match arm
- Added explicit `core_hit` match arm as well (was also using default)

### Gameplay Stats: Track dice roll count
- New `dice_rolls` stat in game state, incremented on each successful roll
- Enables post-game stats screen to show gambling frequency

### Performance: Avoid sqrt in enemy movement snap check
- Enemy movement now compares `dist_sq <= move_dist * move_dist` before calling `sqrt()`
- Only computes `sqrt()` when the enemy actually needs to move (not snap)
- Saves one sqrt per enemy per frame when enemies are near waypoints

### New Helper: total_tower_kills()
- Parallel to existing `total_tower_damage()` — sums kill_count across all towers
- Useful for stats display and end-game summary

### New Helper: format_kills()
- Parallel to `format_damage()` — formats kill counts with "k" suffix for compact display
- e.g., `format_kills(2500)` returns "2.5k"

### Data Integrity: Wave data validation at load time
- `_validate_wave_data()` runs on `_ready()`, checks all enemy types in WAVE_DATA exist in ENEMY_DATA
- Catches typos immediately on startup rather than mid-game crashes

### Test Coverage: 7 new test suites (45 assertions)
- `_run_fx_color_constants_tests` — validates all 9 new FX color constants
- `_run_dice_rolls_stat_tests` — dice roll stat tracking, including edge case of no uses
- `_run_heal_pulse_duration_tests` — verifies heal_pulse uses correct duration
- `_run_total_tower_kills_tests` — helper function with empty, single, multi, missing-key cases
- `_run_format_kills_tests` — format_kills at 0, sub-1000, 1000+, 2500, 10000
- `_run_screen_flash_duration_tests` — verifies screen_flash uses correct duration
- `_run_wave_data_enemy_types_tests` — validates all wave enemy types, unused enemies, wave count

Total: 862 assertions across 143 test suites (up from 817/136).
