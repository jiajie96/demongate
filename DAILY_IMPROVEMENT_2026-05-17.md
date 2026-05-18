# Daily Improvement — 2026-05-17

## Summary

10 improvements across bug fixes, code quality, performance, gameplay stats, and test coverage.

## Changes

### Bug Fix: Fallen Hero Pool (Critical)
- **`add_to_hero_pool(1)` was never called** — the entire Fallen Hero mechanic was non-functional. The function existed, the HUD displayed the pool, but kills never incremented it. Now wired into `combat_kill()`.

### Gameplay: Lucifer Execute Stat Tracking
- Added `lucifer_executes` stat to track how many enemies Lucifer finishes off via the 15% HP threshold execute. Gives players visibility into Lucifer's unique contribution.

### Code Quality: 4 Magic Numbers Extracted
| Constant | Value | Was |
|----------|-------|-----|
| `NOTIFICATION_STACK_SPACING` | 20.0 | `i * 20` in `_draw_notifications` |
| `NOTIFICATION_Y_OFFSET` | 65.0 | `65` in `_draw_notifications` |
| `DICE_RESULT_FADE_TIME` | 0.8 | `/ 0.8` in `_draw_dice_result` |
| `LUCIFER_SPIN_DURATION` | 0.3 | `const LUCIFER_SPIN_DUR := 0.3` local |

### Performance: Tower Blessing Relic Optimization
- Replaced `sqrt()` in the nearest-tower search (`drop_relic` → `tower_buff`) with squared distance comparison. Avoids an unnecessary square root per tower during relic drops.

### Test Coverage: 5 New Test Suites (~30 assertions)
1. **In Radius Helper** — radius queries, dead enemy exclusion, empty results, edge distances
2. **Hero Pool Combat Kill** — pool increment, threshold spawn trigger, heroes_spawned tracking
3. **Format Damage Edge Cases** — 0, 999, 1000 boundary, k-suffix, fractional display
4. **Lucifer Execute Stat** — threshold kill attribution
5. **New Constants Validation** — sanity checks on extracted layout/timing constants

## Files Modified
- `scripts/autoload/game_config.gd` — 4 new constants
- `scripts/autoload/game_manager.gd` — hero pool call, execute stat, sqrt removal
- `scripts/game_world.gd` — use new constants, remove local magic numbers
- `tests/test_runner.gd` — 5 new test suites registered and implemented

## Note
Git commit was prepared but could not be pushed from the automated environment (no SSH keys). Please run `git add -A && git commit` and `git push` locally.
