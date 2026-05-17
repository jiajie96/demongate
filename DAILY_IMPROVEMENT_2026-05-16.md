# Daily Improvement Report — 2026-05-16

## Summary

10 improvements across bug fixes, code quality, locale, stats tracking, and test coverage.

## Changes

### Bug Fixes (2)
1. **Pact UI overlay** — Demonic Pacts were offered via notification but had no interactive UI. Added a full HUD overlay with Accept/Decline buttons, pact name, benefit description (green), and cost description (red).
2. **Keyboard bindings for pacts** — Added Y/N key bindings: Y accepts a pending pact (or picks 2x Damage from Pandora), N declines (or picks +100 Sins). Updated the help text to show the new bindings.

### Code Quality (5)
3. **Notification color constants** — Extracted 11 semantic color constants (`COLOR_NOTIFY_GOLD`, `_SINS`, `_POSITIVE`, `_NEGATIVE`, `_PACT`, `_NEUTRAL`, `_SELL`, `_DANGER`, `_LEGENDARY`, `_SLOW`, `_CORRUPT`) to `game_config.gd`. Replaced all 18 inline `Color()` literals in notify calls across `game_manager.gd` and `game_world.gd`.
4. **Data-driven relic drops** — Added `relic_drop` field to all 11 enemy types in `ENEMY_DATA`. Refactored `should_drop_relic()` from a 12-line if-chain with hardcoded enemy type strings to a 3-line data lookup. Adding new enemies no longer requires touching the drop function.
5. **Tower Blessing constant** — Extracted the inline `0.25` damage multiplier increment to `TOWER_BLESSING_BUFF` constant for tuning visibility.
6. **Removed duplicate constants** — Deleted unused `DICE_AOE_FLASH_STRONG`/`DICE_AOE_FLASH_WEAK` (duplicated by `DICE_AOE_FLASH_25`/`DICE_AOE_FLASH_10`).

### Locale (1)
7. **26 Chinese translations** — Added translations for pact names (Blood Tithe, Infernal Forge, etc.), benefit/cost descriptions, Accept/Decline buttons, and notification strings.

### Stats Tracking (1)
8. **Relics collected stat** — Added `relics_collected` to the stats dictionary, incremented on each `drop_relic()` call. Initialized to 0 on game reset.

### Test Coverage (1)
9. **6 new test suites, 40+ assertions** covering:
   - Notification color constants (non-black, distinguishable positive/negative)
   - Data-driven relic drops (all enemies have `relic_drop`, bosses = 100%, war titan > default)
   - Tower Blessing constant (value and bounds)
   - Pact accept/decline logic (accept increments stat, decline clears pact, empty pact no-ops)
   - Relics collected stat (starts at 0, increments on drop)
   - Wave completion bonus math (monotonically increasing, matches formula)

## Metrics

- **Files changed**: 6
- **Lines added**: 284
- **Lines removed**: 56
- **Test suites**: 131 (was 125)
- **Assertions**: ~515 (was ~475)

## Note

Git push failed due to SSH key unavailability in the sandbox. The commit (`3582e8e`) is ready locally — run `git push` from the host machine.
