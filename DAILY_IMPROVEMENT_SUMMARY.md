# Daily Improvement Summary — 2026-05-04

## Commit: `3191dbd`

**4 files changed, 244 insertions, 20 deletions**

---

## Improvements

### 1. Gameplay: New Demonic Pact — Abyssal Gambit
Added a 6th pact: grants a free tower placement but weakens all tower damage by 15% for 3 waves. Adds a new strategic tradeoff for players who want to expand defenses quickly at the cost of reduced firepower.

### 2. Bug Fix: Lucifer Pulse Hit FX on Dead Enemies
Lucifer's global pulse was spawning `lucifer_hit` visual effects even for enemies killed by the execute threshold check. Now only living enemies after the pulse get the delayed hit flash, preventing orphaned effects.

### 3. Code Quality: WAVE_BANNER_DURATION Moved to Config
The `WAVE_BANNER_DURATION` constant was defined in `game_manager.gd` but belongs with all other timing/balance constants. Moved to `game_config.gd` for consistency. Updated references in both `game_manager.gd` and `game_world.gd`.

### 4. Code Quality: Wave Bonus Magic Numbers Extracted
The wave completion bonus formula had inline magic numbers `2` and `30`. Extracted as `WAVE_BONUS_BASE_PER_WAVE` and `WAVE_BONUS_SCALED_BASE` config constants for clearer tuning.

### 5. Performance: Cached Burn DPS Lookup
The inferno warlock burn DoT tick was looking up `Config.TOWER_DATA["inferno_warlock"]["burn_dps_per_stack"]` inside the per-enemy loop every frame. Hoisted to a single variable at the top of `update_enemies()`.

### 6. Gameplay: Waves Survived Stat
Added `waves_survived` to the stats dictionary, incremented on each `complete_wave()` call. Feeds into game-over and victory screens for clearer performance summary.

### 7. Gameplay: Tower Weaken Debuff System
Implemented `tower_weaken` cost type for the Abyssal Gambit pact. Applies a 0.85x damage multiplier to all tower damage for N waves, then auto-clears on wave completion.

### 8. Consistency Fix: Cocytus Cone Weaken
The Cocytus frost cone applies damage manually (bypassing `calc_damage`). Added `tower_weaken_mult` to this code path so the Abyssal Gambit debuff affects all damage sources consistently.

### 9. Test Helpers: _assert_gt and _assert_lt
Added two new assertion helpers to the test runner for cleaner numeric comparisons. Both print actual vs threshold on failure.

### 10. Tests: 35 New Assertions (8 New Test Groups)
- **Sell Tower** — tile freed, sins refunded, tower removed, selection cleared
- **Buildable** — out-of-bounds, path tiles, occupied tiles
- **Game Speed** — set/reset, Engine.time_scale sync
- **Format Cost** — non-empty output, value inclusion
- **Waves Survived** — stat init, increment tracking
- **Tower Weaken Pact** — damage reduction, config reset
- **Wave Bonus Constants** — value checks, formula validation
- **Banner Duration** — config presence and positivity

---

## Test Count
Previous: 327 assertions → Current: 362 assertions (+35)

## Note
Godot is not available in the sandbox environment, so tests were verified via static analysis (symbol references, parentheses balance, function registration). Committed locally; push to GitHub requires SSH keys from the desktop environment.
