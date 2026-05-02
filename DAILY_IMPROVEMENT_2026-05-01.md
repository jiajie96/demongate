# Daily Improvement Report — 2026-05-01

## Summary

10 improvements implemented across gameplay, code quality, performance, balance, UX, bug fixes, and test coverage.

## Changes

### 1. Gameplay: "Weakest" Targeting Mode
Added a third targeting mode that focuses the lowest-HP enemy in range. Useful for clearing stragglers before they reach the core. Cycles: closest → strongest → weakest → closest.

### 2. Code Quality: Cocytus Constants Extracted
Moved magic numbers for frost slow (0.35), sweep speed (1.5 rad/s), and sweep angle (π/12) into `game_config.gd` as named constants (`COCYTUS_FROST_SLOW`, `COCYTUS_SWEEP_SPEED`, `COCYTUS_SWEEP_ANGLE`). Both `game_manager.gd` and `game_world.gd` now reference these.

### 3. Performance: Merged Hades Buff Decay Loop
Previously `update_towers()` iterated all towers twice — once to decay Hades buff timers, once for the main update. Merged into a single loop, eliminating redundant iteration.

### 4. Audio: Added Missing `wave_complete` SFX Entry
The `SFX_PRIORITY` table referenced "wave_complete" but `SFX_FILES` didn't have it. Added the file path entry so the audio system can load it (falls back to procedural if file missing).

### 5. Balance: Raphael Heal Reduced (15% → 12%)
Archangel Raphael's heal was too strong on boss waves (healing Grand Paladin for 42+ HP every 6s). Reduced from 15% to 12% max HP per heal cycle.

### 6. Stats: Track Total Sins Earned
Added `total_sins_earned` to the stats dictionary. The `earn()` function now accumulates all income. Displayed on game over and victory screens.

### 7. Bug Fix: Trojan Relic Spawns Correct Count
The Trojan Relic had `"value": 2` but only spawned 1 War Titan. Now reads the value field and spawns the configured number of enemies.

### 8. UX: Sins Earned in End-Game Stats
Both game over and victory stat strings now show total Sins earned. Locale templates updated for both English and Chinese.

### 9. Code Quality: Game World Cone Sweep Synced
`game_world.gd` previously used hardcoded `1.5` and `deg_to_rad(15.0)` for the Cocytus cone draw. Now uses `Config.COCYTUS_SWEEP_SPEED` and `Config.COCYTUS_SWEEP_ANGLE` ensuring visual and logic stay in sync.

### 10. Tests: 6 New Test Sections (38+ assertions)
- **Zeus Lightning**: Verifies tower disabling, cooldown reset
- **Michael Shield**: Verifies buff application, 30% damage reduction
- **Weakest Targeting**: Mode cycling, target selection by lowest HP
- **Stats Tracking**: Cumulative earn tracking with multipliers
- **Cocytus Config Constants**: Value range validation
- **Raphael Heal**: Heal amount (12%), cooldown reset, no self-heal

## Files Modified
- `scripts/autoload/game_config.gd` — new constants
- `scripts/autoload/game_manager.gd` — targeting, balance, stats, perf, bug fix
- `scripts/autoload/audio_manager.gd` — wave_complete SFX entry
- `scripts/autoload/locale.gd` — updated stat templates
- `scripts/game_world.gd` — use Config constants for cone draw
- `scripts/hud.gd` — pass sins stat to end screens
- `tests/test_runner.gd` — 6 new test sections, updated targeting assertions
