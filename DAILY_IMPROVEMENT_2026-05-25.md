# Daily Improvement — 2026-05-25

## Headline: Two HUD-vs-gameplay mismatches and a Holy Sentinel exploit, all fixed

Today's standout finds were two cases where what the game *showed* or *did*
diverged from what it *should*: the tower DPS readout silently ignored the
temporary speed buffs from Devil's Dice, and single-target towers happily
emptied their cooldowns into Holy-Sentinel-shielded enemies for zero damage.
Both are now fixed, alongside a per-kill hot-path optimisation, a missing audio
fallback, and tuning-constant extraction — backed by five new test suites.

**Test results:** `2442 / 2442` assertions passing (was `2411 / 2411`; **+31 new**).
Main game scene loads with **no `SCRIPT ERROR`** (CI parse gate clean).

---

## What changed and why

### Bug fixes

1. **HUD DPS/SPD now reflects the temporary speed buff.**
   The tower info panel computed `effective_spd = attack_speed × perm_speed_buff`
   (+ Hades), but **omitted `temp_speed_buff`** — the multiplier behind Demonic
   Surge (×1.8) and Quick Hands (×1.3). So while those dice buffs were active the
   panel under-reported both attack speed *and* DPS, even though the tower was
   firing faster. The readout now uses the shared `tower_speed_multiplier()`
   helper, which includes perm + temp + Hades, so the numbers match reality.

2. **Single-target towers no longer waste shots on shielded enemies.**
   When a Holy Sentinel is alive it makes every enemy in the path's first half
   invulnerable (`combat_hit` no-ops with just a flash). `find_target` had no
   awareness of this, so a tower would lock onto a protected enemy and burn its
   cooldown + a projectile per shot for **zero damage** — effectively disabling
   the tower while the Sentinel was up. `find_target` now skips guardian-protected
   enemies, so towers retarget to a damageable foe or hold fire (saving the
   cooldown *and* the projectile update/draw cost). The Cocytus cone, Lucifer
   pulse and Hades curse already skipped protected enemies, so this brings
   single-target targeting in line with the rest of the combat code.

### Performance

3. **`reward_scale()` cached per-wave.** `earn_from_kill` runs once per enemy
   death — and an AoE-heavy late wave can kill dozens of enemies in a single
   frame. Each call recomputed `Config.reward_scale(wave)`, which performs three
   `pow()` calls. The result only depends on `wave`, so it's now cached and
   recomputed only when the wave actually changes. Identical output, far fewer
   `pow()` calls on the hottest path in the kill loop.

### Code quality

4. **Extracted `tower_speed_multiplier(tower)`.** The "perm × temp × (Hades ?
   1.5)" speed math was duplicated across **four** sites: the single-target fire
   path, the Lucifer pulse path, `_calc_cocytus_dps`, and the HUD. They now share
   one helper, so the firing rate and the displayed rate can never drift apart
   again (this is also what fixed bug #1).

5. **Extracted dice AoE damage fractions to Config.** The Hellstorm (25%) and
   Small Spark (10%) rolls used inline `0.25` / `0.10` literals in `roll_dice()`.
   They're now `DICE_AOE_DAMAGE_25` / `DICE_AOE_DAMAGE_10`, sitting beside the
   existing `DICE_AOE_FLASH_*` timing constants for easy tuning.

### Audio

6. **Procedural fallback for the pact-accept SFX.** Accepting a Demonic Pact or a
   Pandora choice plays `pact_accept`, but unlike the shoot/death/UI sounds it had
   **no procedural fallback** — if the `.ogg` were ever missing, those confirmations
   went silent. Added `_make_pact_accept()`: an ominous descending two-note motif
   (A3 → E3) with an octave shimmer and a sub layer, registered in
   `_generate_fallback_sounds()`.

### New test coverage (regression guards)

7. **`[Reward Scale Cache]`** — cached `GM.reward_scale()` equals
   `Config.reward_scale(wave)`, invalidates when the wave changes, and the cache
   tracker resets on `reset_state()`.
8. **`[Tower Speed Multiplier]`** — verifies perm/temp/Hades buffs stack
   correctly in the helper and reset cleanly.
9. **`[Guardian Targeting Skip]`** — a protected enemy is skipped (tower holds
   fire), a damageable enemy is chosen over a protected one, and the formerly
   protected enemy becomes targetable once the Sentinel dies.
10. **`[Dice AoE Damage Constants]` + `[Audio Fallback]`** — constant values and
    `_damage_all_percent` behaviour; procedural generators (including the new
    `pact_accept`) produce valid non-empty 16-bit WAV streams at the manager's
    sample rate, and the procedural music loop flag is set.

---

## Verification

- Ran the full suite under Godot 4.6.2 (ARM64, matching CI): **2442/2442 passed.**
- `godot --headless --quit` (loads `main.tscn`) → no `SCRIPT ERROR`, confirming
  `game_world.gd` / `hud.gd` / autoloads still parse and link cleanly. (The HUD
  change is *not* exercised by the test scene, so this parse gate is what
  guards it.)

## Notes for the maintainer

- Bug #1 and the refactor (#4) are the same edit from two angles: the helper is
  the fix. The Cocytus DPS suite already asserts the helper's behaviour
  indirectly (it expects `expected_dps × 1.5` under a Hades buff), so the refactor
  is behaviour-preserving for gameplay and only *changes* the HUD (which now shows
  more, correctly).
- Bug #2 is a slight, intentional nerf to the Holy Sentinel's protection *value*:
  the shield still works (protected enemies take no damage), but towers no longer
  throw shots away at them. If you'd rather keep towers "visually firing" at
  shielded enemies, revert the `find_target` skip — but the current behaviour
  matches the cone/global/curse paths and is strictly better for the player's
  damage uptime.
- Remember to restore `project.godot`'s `run/main_scene` to `res://scenes/main.tscn`
  after any local test run that swaps it to the test scene — this run verified it
  is set back correctly.
