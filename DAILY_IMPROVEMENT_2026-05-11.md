# Daily Improvement — 2026-05-11

## Summary

Extracted 25 inline magic numbers to named constants, fixed relic drops for special enemies, extracted `_apply_burn` helper, implemented 13 missing test functions (from a previous revert), and added 10 new test suites with ~120 new assertions. Total test suites: 96, total assertions: ~601.

## Improvements

### 1. Starting Sins → `STARTING_SINS` (50)
Initial sins on game start was hardcoded as `sins = 50` in `reset_state`. Now centrally tunable.

### 2. Dice Effect Parameters → 12 new constants
All dice roll effects had inline magic numbers: surge speed (1.8), surge duration (15s), speed boost (1.3/10s), slow factor (0.75/10s), disable duration (3s), tax percent (10%), bonus tiers (10/25/50 sins), display duration (5s). Now configurable via `DICE_SURGE_SPEED`, `DICE_SURGE_DURATION`, `DICE_SPEED_BOOST`, `DICE_SPEED_BOOST_DURATION`, `DICE_SLOW_FACTOR`, `DICE_SLOW_DURATION`, `DICE_DISABLE_DURATION`, `DICE_TAX_PERCENT`, `DICE_BONUS_SMALL/MEDIUM/LARGE`, `DICE_RESULT_DISPLAY`.

### 3. Notification System → `NOTIFICATION_MAX` (6), `NOTIFICATION_DURATION` (4.0)
Max simultaneous notifications and display duration were inline in `notify()`.

### 4. Slow Debuff Duration → `SLOW_DEBUFF_DURATION` (2.0)
Legacy slow_power slow timer was hardcoded as `2.0` in `combat_hit`.

### 5. Tower Weaken Multiplier → `TOWER_WEAKEN_MULT` (0.85)
Abyssal Gambit pact's -15% damage debuff was hardcoded in `accept_pact`.

### 6. FX Timer Constants → 7 new constants
Visual effect durations were hardcoded: Michael shield dome (0.8s), Zeus bolt flash (0.4s), Hades beam (0.5s), Hades curse (0.5s), core hit radius (10px), game over shake intensity (8.0) and duration (0.4s). Now `FX_MICHAEL_SHIELD_DURATION`, `FX_ZEUS_BOLT_DURATION`, `FX_HADES_BEAM_DURATION`, `FX_HADES_CURSE_DURATION`, `FX_CORE_HIT_RADIUS`, `GAMEOVER_SHAKE_INTENSITY`, `GAMEOVER_SHAKE_DURATION`.

### 7. Special Enemy Relic Drops → `RELIC_DROP_SPECIAL` (0.10)
Zeus, Holy Sentinel, Archangel Marshal, and Archangel Raphael had no explicit drop rate — they fell through to the generic 3% default, despite being special enemies. Now they have a 10% rate, and the function uses `is_boss` to catch both boss types (Grand Paladin AND Archangel Michael) instead of only checking for `"grand_paladin"`.

### 8. Code Quality: Extract `_apply_burn` helper
Burn stack application logic (stacking, capping, timer, source tracking) was inline in `combat_hit`. Extracted to `_apply_burn(enemy, tower)` for readability and potential reuse.

### 9. Bug Fix: 13 missing test functions
Previous commits added calls to 13 test functions that were lost in a revert (`_run_lucifer_wave_constants_tests`, `_run_hero_threshold_constants_tests`, `_run_dice_outcome_coverage_tests`, `_run_raphael_heal_target_tests`, `_run_guardian_combat_interaction_tests`, `_run_wave_spawn_interleave_tests`, `_run_find_target_modes_tests`, `_run_complete_wave_decay_tests`, `_run_hades_buff_range_tests`, `_run_burn_source_credit_tests`, `_run_free_upgrade_best_tower_tests`, `_run_dice_replenish_constant_tests`, `_run_projectile_origin_cull_tests`). These would crash the test runner. All 13 now have full implementations.

### 10. New Test Suites (10 suites, ~120 assertions)
- **Starting Sins**: validates constant and `reset_state` integration
- **Dice Effect Constants**: validates all 12 dice parameters, ordering invariants
- **Notification Config**: notification max, duration, slow debuff constants
- **Relic Drop Special**: validates special enemy rates, boss detection
- **FX Timer Constants**: validates all 7 FX timer constants
- **Tower Weaken Constant**: validates pact integration
- **Apply Burn Helper**: validates burn stacking, capping, source credit
- **Pandora Choice**: validates both choice paths (double damage and sins)
- **Notification Overflow**: validates eviction behavior at NOTIFICATION_MAX
- **Sell Refund Level Scaling**: validates refund at levels 1, 2, and 3
