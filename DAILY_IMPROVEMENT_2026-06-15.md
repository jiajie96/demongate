# Daily Improvement — 2026-06-15

Ten improvements across code quality, performance, gameplay, UX, audio, and test
coverage. Test suite expanded from **2496 → 2528** passing assertions (+32). All
tests pass under Godot 4.6.2 headless.

## Summary of changes

### Code quality
1. **Shared `_valid_tower()` guard** (`game_manager.gd`). The combat code repeated
   `tower != null and tower is Dictionary` in six places (`calc_damage`,
   `combat_hit` ×4, `combat_kill` ×2). Replaced all of them with a single
   documented helper, removing duplication and giving one place to harden the
   "is this a real tower?" check that AoE/dice/relic damage relies on (those pass
   `null` as the source tower).

2. **Single definition of "best tower" via `strongest_tower_by_dps()`**
   (`game_manager.gd`). Extracted the highest-DPS selection (damage × mult ×
   attack_speed) into a reusable helper and pointed the Divine Curse relic at it,
   so the curse and the Legendary free-upgrade now agree on what "strongest" means.

### Performance
3. **Skip the per-frame Hades-corruption cache when no Cocytus is on the field**
   (`update_towers`). The cached Hades list is only ever consumed by an active
   Cocytus cone, but it was rebuilt every frame regardless. Guarded the build
   behind a new `has_active_tower_type("cocytus")` check, eliminating a full
   towers scan every frame in the common case where the player hasn't bought one.

### Gameplay
4. **Divine Curse now disables the true highest-DPS tower.** The old check ranked
   towers by `damage × damage_mult` only, ignoring attack speed — so a slow heavy
   hitter could be cursed instead of a faster tower doing more actual damage. Now
   uses full DPS, making the curse consistently bite the player's best tower.

5. **Temple Cleric heal startup delay.** Clerics previously fired a heal aura tick
   on the very first frame after spawning (a free, unavoidable heal). They now
   spawn with the heal tick on cooldown — the same reaction-window reasoning
   already applied to Michael / Zeus / Raphael abilities. Non-ability enemies are
   unaffected.

### UX / localization
6. **Generalized the "unique tower" notification.** The message was hardcoded to
   "Only one Lucifer allowed!" — wrong for any future unique tower. Added a
   `unique_tower_limit` template (en + zh) that substitutes the tower's localized
   name, and wired the placement path (`game_world.gd`) to use it.

### Audio
7. **SFX volume safety ceiling.** `play_sfx` summed a caller dB with a per-sound
   offset and applied it with no upper bound, so an accidental large positive
   value could clip the mix. Added `SFX_MAX_VOLUME_DB` (+6 dB) and a pure,
   testable `clamp_sfx_volume()` helper applied to every play.

### Test coverage (+6 new suites, +32 assertions)
8. **Valid-tower helper + null-source regression** — verifies `_valid_tower`
   rejects null/non-dicts and that `combat_hit` / `calc_damage` still deal damage
   when the source tower is `null` (AoE/dice path).
9. **Active tower type** — `has_active_tower_type` detects active towers, ignores
   disabled ones, and is distinct from existence (`has_tower_type`).
10. **Divine Curse DPS targeting, Cleric heal startup, SFX clamp, and unique-tower
    locale** — dedicated suites pinning each of the behavior changes above,
    including a frame-level check that no cleric heal fires before the first tick
    interval, and placeholder-substitution checks for the new locale string in
    both languages.

## Verification
- `godot --headless --quit` → no parse/script errors.
- Full suite: **2528/2528 assertions passed** (`ALL TESTS PASSED`).
- Two pre-existing tests that pinned the old `heal_tick_timer == 0` behavior were
  updated to assert the new intended startup-delay behavior.
