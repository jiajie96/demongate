# Daily Improvement — May 13, 2026

## Summary

10 improvements across code quality, bug fixes, stats tracking, and test coverage. 7 new test suites adding ~40 assertions (total ~680).

## Changes

### Bug Fix & UX
1. **Sell tower SFX**: `sell_tower()` now plays `ui_click` sound effect for audio feedback — previously the only tower action without sound.

### Code Quality
2. **`format_damage()` helper**: Extracted damage formatting (sub-1k integer, 1k+ with "k" suffix) into `GM.format_damage()` to DRY the overview panel and make it reusable.
3. **Tower hotkey refactor**: Replaced 6 repetitive `KEY_4`–`KEY_9` match arms with a single `_try_select_tower_by_key()` helper using an array lookup. Cuts 18 lines of duplication.

### Stats Tracking
4. **`pacts_offered` stat**: Tracks total Demonic Pacts offered (not just accepted) for richer end-game stats.
5. **`towers_sold` stat**: Tracks tower sell actions, complementing the existing `towers_placed` counter.

### Test Coverage (7 new suites)
6. **Speed buff overwrite**: Verifies applying a second speed buff correctly overwrites the first, and timer expiry resets to 1.0.
7. **Cycle targeting wrap**: Confirms `cycle_targeting()` rotates through all 4 modes (closest → first → strongest → weakest) and wraps back correctly.
8. **Buildable boundaries**: Tests negative coordinates, max grid bounds, far out-of-bounds, occupied tiles, and adjacent-to-occupied tiles.
9. **Wave bonus scaling**: Verifies `wave_completion_bonus()` is monotonically increasing across waves 1→5→10→20 and matches the formula.
10. **Format damage**: Tests `format_damage()` output for zero, sub-1k, exactly 1k, and large values.
11. **Pacts offered stat**: Verifies `pacts_offered` initializes to 0, increments on offer, and is independent of `pacts_accepted`.
12. **Sell tower feedback**: Verifies sell generates notification, removes tower from array, frees tile, and increments `towers_sold`.

## Files Modified
- `scripts/autoload/game_manager.gd` — +13 lines (format_damage, stats, sell SFX)
- `scripts/game_world.gd` — net -15 lines (hotkey refactor)
- `tests/test_runner.gd` — +199 lines (7 new test suites)

## Git Note
The commit was created in a working copy at `/tmp/demongate_work` (SHA `55c7bf3`). The mounted repo has stale `.lock` files from prior sessions that prevent `git commit`/`git am`/`git push` in the sandbox. The code changes are written to disk and will be committable from the host machine after removing the lock files:
```
rm .git/index.lock .git/HEAD.lock .git/packed-refs.lock .git/REBASE_HEAD.lock .git/objects/maintenance.lock
rm -rf .git/refs/refs
git add -A && git commit -m "Daily improvement: ..."
git push
```
