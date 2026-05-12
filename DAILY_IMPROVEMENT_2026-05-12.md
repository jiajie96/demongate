# Daily Improvement — 2026-05-12

## Summary

Fixed 2 cheat-mode bugs (hardcoded values ignoring constants), replaced 8 magic numbers with named constants across game_world and game_manager, added `total_core_damage` stat tracking, extracted 2 new game_config constants, and added 7 new test suites with ~35 new assertions. Total test suites: 105, total assertions: ~633.

## Improvements

### Bug Fixes
1. **Cheat sins used hardcoded 99999** — Now uses `Config.CHEAT_SINS_AMOUNT`, so changing the constant actually takes effect.
2. **Cheat skip-to-wave used hardcoded 14** — Now uses `Config.CHEAT_SKIP_TO_WAVE - 1`, and the notification message is dynamic.

### Code Quality (Magic Number Extraction)
3. **Overview panel dimensions** — Replaced hardcoded `52.0` / `30.0` in `_draw_overview()` with `Config.OVERVIEW_PANEL_W` / `Config.OVERVIEW_PANEL_H`.
4. **Wave banner animation timings** — Replaced hardcoded `0.35` / `0.7` slide-in/fade-out with `Config.WAVE_BANNER_SLIDE_IN` / `Config.WAVE_BANNER_FADE_OUT`.
5. **Enemy spawn_timer** — `create_enemy()` now uses `Config.ENEMY_SPAWN_DURATION` instead of inline `0.4`.
6. **Tower build_timer** — `create_tower()` now uses `Config.TOWER_BUILD_DURATION` instead of inline `0.3`.

### New Constants
7. **LUCIFER_BOLT_HEIGHT (160.0)** — Extracted the lightning bolt visual height above enemies in Lucifer's pulse hit effect.
8. **DIVINE_CURSE_DURATION (10.0)** — Extracted the disable duration for the Divine Curse relic, previously a magic number in `drop_relic()`.

### Gameplay / Stats
9. **Core damage tracking** — Added `total_core_damage` stat to `stats` dictionary, incremented whenever an enemy leaks and damages the core. Enables future end-game summary showing total core damage taken.

### Test Coverage
10. **7 new test suites, ~35 assertions** — Covering cheat constants, core damage stat tracking, divine curse constant, lucifer bolt constant, build/spawn duration constants, overview panel constants, and banner animation constants. Validates both constant values and their correct usage in game logic.

## Stats
- Files changed: 4 (game_config.gd, game_manager.gd, game_world.gd, test_runner.gd)
- Test suites: 98 → 105
- Total assertions: ~601 → ~633
