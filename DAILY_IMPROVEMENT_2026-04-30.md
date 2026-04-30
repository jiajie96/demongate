# Daily Improvement Report — 2026-04-30

**Commit:** `32fb648` — Daily improvement: cleric heal aura, perf cache, tile_key refactor, new tests

## Summary

10 improvements implemented across code quality, gameplay, performance, UX, audio, and test coverage.

## Improvements

### 1. Code Quality: `tile_key()` Helper
Extracted `Config.tile_key(col, row)` to replace the repeated `str(col) + "," + str(row)` pattern used in 7+ locations across game_config, game_manager, game_world, and tests. Single source of truth for tile coordinate keys.

### 2. Performance: `_has_alive_type` Cache
Added per-frame caching dictionary `_alive_type_cache` to `game_manager`. The `_has_alive_type()` function was being called 5-10+ times per frame (in `calc_damage`, `update_enemies`, `_cocytus_cone`, draw functions) for types like "archangel_marshal" and "holy_sentinel". Now only scans enemies once per type per frame.

### 3. Gameplay: Temple Cleric Heal Aura
Temple Clerics now passively heal nearby allies for 2% of their max HP per second within an 80px radius. This gives clerics a real support role — they make enemy groups harder to kill through sustained healing, encouraging players to prioritize clerics or use AoE to overwhelm the healing.

### 4. Visual: Cleric Heal Aura Ring
Added a subtle pulsing green aura ring drawn around Temple Clerics to communicate their heal range to the player, consistent with the visual language of other aura effects (Soul Reaper slow, Hades buff).

### 5. Code Quality: `_damage_all_percent()` Helper
Extracted the duplicated percent-damage-all-enemies logic from `roll_dice()` (used by "aoe_25" and "aoe_10" dice effects) into a reusable helper. Also added death VFX (`add_effect("death", ...)`) to dice kills which were previously missing.

### 6. UX: Targeting Shortcut Key
Added `T` as a keyboard shortcut to cycle targeting mode (closest/strongest) on the currently selected tower, matching the existing button functionality.

### 7. UX: Updated Help Text
Updated the in-game help label and Chinese locale translation to include the new `T: Target` shortcut alongside existing shortcuts.

### 8. Audio: Pandora Pact Sound
Wired up the existing `pact_accept.ogg` asset (which was on disk but unreferenced) to play when the player accepts a Pandora's True Gift choice. Added it to the SFX_FILES mapping and SFX_PRIORITY table.

### 9. Tests: 7 New Test Sections (~35 assertions)
- **Hero Pool**: Threshold progression (200 → 500 → 1000 → 1500+), spawn trigger
- **Pandora Choice**: Both choice paths (double damage, sins bonus), flag clearing
- **Sell Refund**: Level 1 and level 2 refund calculations match formula
- **Cleric Heal**: Data integrity, heal aura heals damaged allies, respects max HP
- **Tile Key**: Helper function output correctness
- **Alive Cache**: Cache hit/miss behavior, stale cache before clear, fresh after clear
- **Damage Percent**: Correct HP reduction, flash timer set, both enemy types affected

### 10. Balance Pass (Prior Session)
Included uncommitted balance changes from a previous session: HP compound growth increased from 1.08→1.12, milestone bump from 1.15→1.25, Cocytus damage nerfed from 5.0→3.5, removed unused PACT_POOL data.

## Files Changed
- `scripts/autoload/game_config.gd` — tile_key, cleric data, balance values
- `scripts/autoload/game_manager.gd` — alive cache, tile_key usage, cleric heal, damage helper, pact audio
- `scripts/autoload/audio_manager.gd` — pact_accept SFX mapping + priority
- `scripts/autoload/locale.gd` — updated help text translation
- `scripts/game_world.gd` — tile_key usage, alive cache clear, T shortcut, cleric aura visual
- `scripts/hud.gd` — help text with T shortcut
- `tests/test_runner.gd` — 7 new test sections
- `GAME_DESIGN_ANALYSIS.md` — prior session updates
