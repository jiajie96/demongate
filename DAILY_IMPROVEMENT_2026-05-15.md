# Daily Improvement — May 15, 2026

## Summary

10 improvements across code quality (magic number extraction), bug fixes (locale, HUD constants), and test coverage. 5 new test suites adding 34 assertions (total ~757).

## Improvements

### Constants Extracted (game_config.gd)
1. **DOUBLE_DAMAGE_MULT** (2.0) — replaces inline `2.0` in `calc_damage()`, Cocytus cone DPS, and HUD effective damage display. Single tuning point for the double-damage mechanic.
2. **SHAKE_FREQ_X** (60.0) — horizontal screen shake oscillation rate, previously a magic number in game_world.gd.
3. **SHAKE_FREQ_Y** (47.0) — vertical screen shake oscillation rate (intentionally different from X for organic feel).
4. **SHAKE_Y_DAMPEN** (0.7) — vertical shake amplitude ratio relative to horizontal.
5. **SHAKE_RAMP_DURATION** (0.3) — shake envelope fade time for intensity ramp-down.

### Bug Fixes
6. **HUD Hades speed display** — replaced inline `1.5` with `Config.HADES_BUFF_DEFAULT` so HUD and game logic stay in sync if the buff multiplier is retuned.
7. **HUD upgrade cost calculation** — replaced inline `1.5` with `Config.UPGRADE_COST_SCALING` so upgrade costs match the game_manager calculation.
8. **game_world fire flash normalization** — replaced inline `0.15` with `Config.TOWER_FIRE_FLASH` so the muzzle flash alpha decay tracks the actual flash duration constant.
9. **Missing locale template keys** — added `legendary_fallback` and `pandora_sins` templates (EN + ZH) that `game_manager.gd` was already calling via `Locale.tf()` but the locale file was missing, which would cause display issues.

### Test Coverage
10. **5 new test suites** with 34 assertions:
    - **Double Damage Mult**: constant value validation + `calc_damage()` integration test verifying the multiplier is actually applied.
    - **Create Enemy Field Validation**: all 11 enemy types checked for 28 required fields, HP sanity, alive state, and ID uniqueness.
    - **Create Tower Field Validation**: all 6 tower types checked for 37 required fields, position accuracy, initial state, and ID uniqueness.
    - **Wave Data Integrity**: verifies WAVE_DATA has exactly MAX_WAVES entries, all enemy types exist in ENEMY_DATA, intervals are positive, counts are positive, and boss waves (10, 15, 20) actually contain boss enemies.
    - **Shake Frequency Constants**: value range checks and organic-feel constraints (X != Y, dampen < 1.0).

### Test Infrastructure
- Added `_assert_ne` helper for inequality assertions (complements existing `_assert_eq`).

## Files Changed
- `scripts/autoload/game_config.gd` — 6 new constants
- `scripts/autoload/game_manager.gd` — 2 inline values replaced with constants
- `scripts/autoload/locale.gd` — 2 missing template keys added
- `scripts/game_world.gd` — 3 inline values replaced with constants
- `scripts/hud.gd` — 3 inline values replaced with constants
- `tests/test_runner.gd` — 1 new helper, 5 new test suites (34 assertions)

## Notes
- Git push from sandbox failed due to SSH key unavailability; commit exists locally and will be pushed on next session with host-level access.
- Also committed two previously uncommitted daily reports (May 13, May 14) that were in the working tree.
