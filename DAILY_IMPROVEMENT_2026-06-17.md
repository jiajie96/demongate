# Daily Improvement — 2026-06-17

Ten improvements across code quality, performance, gameplay/economy, audio, UX and
test coverage. Baseline before work: **2566/2566** assertions passing. After:
**2591/2591** passing (+25 assertions across 6 new suites). GDScript validation clean
(no SCRIPT ERROR / parse errors), verified headless on Godot 4.6.2.

## Code quality

1. **Single `tower_dps()` helper.** The expression `damage × damage_mult ×
   attack_speed` was duplicated verbatim in `strongest_tower_by_dps` (Divine Curse
   target) and `free_upgrade_best_tower` (Legendary Blueprint target). Extracted a
   `GM.tower_dps(tower)` helper that both now call, so the game's notion of
   "strongest tower" can never drift between the two systems. Documented why it
   deliberately excludes transient Hades/global speed buffs (intrinsic strength
   should be stable, not flip every pulse).

2. **Deduplicated the number formatters.** `format_damage` and `format_kills` each
   reimplemented the "compact thousands, strip trailing `.0`" logic that the shared
   `_strip_dot_zero` helper already encapsulates (and which `format_large` uses).
   Both now delegate to it — three suffixers, one rounding/strip path, no drift.

3. **Removed a dead HUD wrapper.** `hud.gd`'s `_format_large_number` had been reduced
   to a one-line passthrough to `GM.format_large` in a prior pass. Deleted it and
   pointed the two end-screen stat call sites straight at `GM.format_large`.

4. **Encapsulated locale template lookups.** `GM.targeting_mode_label` reached into
   `Locale._templates` directly (a private field). Added a public
   `Locale.has_template(key)` method and switched the call to it, so the targeting
   UI no longer depends on Locale's internals.

## Gameplay / economy

5. **Named the AoE-kill bonus.** `earn_from_kill` granted a flat `+1` Sin for
   splash/AoE kills via an inline literal. Extracted it to `Config.AOE_KILL_BONUS`
   so this crowd-clear incentive is documented and tunable in one place alongside
   the other economy constants.

## Performance

6. **Precompute Soul Reaper aura ranges per frame.** In `update_enemies`, the NEC
   passive-slow check recomputed `range × range` for every (enemy × Soul Reaper)
   pair, every frame. The per-frame source list now caches each tower's squared
   range (`{x, y, r2}`) once, so the hot per-enemy loop just compares against a
   stored value. Behavior is identical (verified by a new movement test).

## Audio

7. **Extracted a pure `music_tier_for_wave()` mapping.** The wave→track-tier decision
   was embedded inside `update_music_for_wave`, which also performs playback (a side
   effect), making the thresholds untestable. Split out a pure
   `Audio.music_tier_for_wave(wave) -> String`; `update_music_for_wave` now delegates
   then plays. The MID/PEAK boundaries are now unit-tested.

## UX / correctness

8. **`format_kills` gained an "M" suffix.** It previously only had a "k" suffix, so a
   marathon run could print an unwieldy `1234.5k`. It now mirrors `format_large`
   (and shares `_strip_dot_zero`), reading `1.2M` / `2.5M` for very high counts while
   leaving all sub-million counts unchanged.

## Test coverage (6 new suites, +25 assertions)

9. New suites pinning the refactors above:
   - **`[Tower DPS Helper]`** — `tower_dps` math, and that `strongest_tower_by_dps`
     and `free_upgrade_best_tower` both agree with it on the leader.
   - **`[AoE Kill Bonus]`** — an AoE kill grants exactly `AOE_KILL_BONUS` more Sins
     than a non-AoE kill of the same enemy on the same wave.
   - **`[Format Kills Million]`** — `1M`/`1.2M`/`2.5M` formatting plus a `500k`
     regression guard for the existing k path.

10. More new suites:
   - **`[NEC Aura Slow]`** — an enemy sitting inside a Soul Reaper's aura moves
     strictly slower than its unslowed speed (but still moves) — locks in the
     precompute refactor's behavior.
   - **`[Locale has_template]`** — true/false for known/unknown keys, and that
     `targeting_mode_label` resolves real modes and falls back cleanly on junk.
   - **`[Music Tier For Wave]`** — calm/mid/peak boundaries around `MUSIC_TIER_MID`
     and `MUSIC_TIER_PEAK`.

## Verification

- `godot --headless --quit`: no SCRIPT ERROR / parse errors.
- Full suite headless (Godot 4.6.2): **2591/2591 passed, ALL TESTS PASSED**.
