# Daily Improvement Report — 2026-05-02

## Summary

10 improvements implemented across gameplay, code quality, balance, UX, localization, audio, and test coverage.

## Changes

### 1. Gameplay: "First" Targeting Mode
Added a fourth targeting mode that focuses the enemy furthest along the path (most dangerous — closest to the core). Cycle order: closest → first → strongest → weakest. Essential for prioritizing leakers over fresh spawns.

### 2. Bug Fix: Missing Death SFX in _damage_all_percent
The `_damage_all_percent()` helper (used by dice AoE effects) killed enemies without playing the `enemy_death` SFX, unlike `combat_kill()`. Added the missing `Audio.play_sfx("enemy_death")` call for consistent feedback.

### 3. Code Quality: Combat Constants Extraction
Extracted 11 inline magic numbers from `game_manager.gd` into named constants in `game_config.gd`:
- `SHIELD_BUFF_REDUCTION` (0.7), `COMMANDER_SPEED_BUFF` (1.25), `COMMANDER_DAMAGE_REDUCTION` (0.75)
- `INSURANCE_MULT` (1.5), `MICHAEL_SHIELD_COOLDOWN` (8.0), `MICHAEL_SHIELD_DURATION` (2.0)
- `ZEUS_LIGHTNING_COOLDOWN` (6.0), `ZEUS_DISABLE_DURATION` (2.0), `ZEUS_MAX_TARGETS` (2)
- `RAPHAEL_HEAL_COOLDOWN` (6.0), `RAPHAEL_HEAL_PERCENT` (0.12)

### 4. Code Quality: Reference Constants in Combat Logic
Updated `game_manager.gd` and `game_world.gd` to use the new Config constants instead of inline numbers. Makes future balance tuning trivial — change one value in `game_config.gd` and all systems update.

### 5. Balance: Temple Cleric Heal Aura Buff
Increased Temple Cleric's `heal_aura_radius` from 80 → 90. The old radius was slightly too small — clerics in the back of a group couldn't reach frontline allies. The bump makes their heal aura more reliably cover 2-3 nearby enemies.

### 6. Stats: Total Damage Dealt Tracking
Added `total_damage_dealt` to the stats dictionary, accumulated in `combat_hit()`. Gives players a meaningful performance metric alongside kills and sins earned.

### 7. UX: Damage Stats on End Screens
Game over and victory screens now display total damage dealt (formatted as K/M for readability). Updated both English and Chinese locale templates. Added `_format_large_number()` helper in HUD.

### 8. Localization: Tower Role Tooltips in Chinese
Added Chinese translations for all 6 tower role tooltip strings that appear in the tower info panel when a tower is selected.

### 9. Audio: wave_complete SFX_FILES Entry (from prev session)
The `SFX_FILES` dict was missing the "wave_complete" entry even though the priority table and procedural fallback referenced it. Added the OGG path so the file-based audio path works correctly.

### 10. Tests: 7 New Test Suites (~70 assertions)
- **First Targeting**: Mode cycling (4 modes), target selection by path_index
- **Combat Constants**: All 11 new constants have correct values, calc_damage applies them
- **Upgrade Cost Scaling**: Cost progression, stat multipliers on upgrade
- **Guardian Protection**: Holy Sentinel mechanics (first-half protection, self-exclusion, past-halfway no-protection)
- **Damage Stat Tracking**: Stat key exists, accumulates on combat_hit
- **Insurance Payout**: Leak gives sins back, constant matches expected value
- **Wave Bonus**: Sins earned, wave deactivation, dice replenish, double_damage decrement

## Commit

```
596ff6a Daily improvement: first targeting, combat constants, cleric buff, damage stats, new tests
```

Note: Push to remote failed (no SSH key in sandbox). Commit is on local `main` branch — will push on next session with auth.
