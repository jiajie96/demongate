# Daily Improvement — 2026-06-29

Ten improvements across bug fixes, gameplay/UX, code quality, audio, and test
coverage. The full suite passes at **3141/3141 assertions** (+85 new), and all
scripts validate with no parse errors.

> Note: this commit also finalizes a previous interrupted run whose work was
> staged but never committed (the `enemies_remaining()` / `wave_count()` /
> `wave_enemy_count()` helpers, the damage-number jitter constants, the HUD
> enemy-count fix, and `DAILY_IMPROVEMENT_2026-06-23.md`).

## 1. Bug fix — Fallen Hero pool multi-threshold rollover
`add_to_hero_pool()` drained the pool with a single `if`, so a deposit large
enough to cross **two** thresholds at once (a Soul Surge relic, or any future
bigger reward) spawned only one Fallen Hero and silently discarded the overflow
above the first threshold. Switched to a `while` loop that spawns every hero the
deposit actually earned and keeps the remainder, with a non-positive-threshold
guard so a misconfiguration can't spin forever.

## 2. Content/UX — wave "threat" readout
New pure helper `Config.wave_threat(wave_index)` returns the wave's worst-case
threat: the total Core HP at risk if **every** enemy leaks (sum of
`count × core_dmg`). Surfaced as a wave-start notification so the player can
gauge how punishing a leak would be before committing to a dice roll or pact — a
swarm of cheap scouts and a lone boss can carry very different threat at similar
head-counts. New bilingual `wave_threat_notify` locale template (en/zh).

## 3. UX — honest "remaining / total" enemy count
The HUD showed only a bare remaining count. Added a `wave_enemies_total`
snapshot taken in `start_wave()` once the spawn queue is fully built (regulars +
specials + any Demonic-Pact extras), and updated the `enemies_count` template to
read `Enemies: {count} / {total}`. Remaining can now never exceed the displayed
total.

## 4. Code quality — extracted three combat-hit magic numbers
Replaced inline literals in `combat_hit()` with named, tunable constants:
`FX_HIT_SPARK_RADIUS` (6.0), `DMG_NUM_Y_OFFSET` (4.0), and
`DMG_NUM_DEFAULT_ENEMY_RADIUS` (8.0 fallback). Matches the project's
single-source-of-truth convention for visual placement values.

## 5. Readability — `format_time()` hour rollover
A marathon run used to print an unbounded minutes field ("75:00" meaning 1h15m).
`format_time()` now rolls over to `h:mm:ss` at/after one hour and floors negative
inputs to `0:00`. Updated the existing assertion (`3661 → 1:01:01`) and added
edge cases.

## 6. Test coverage — comprehensive `calc_damage` suite
New suite pinning the full damage pipeline: baseline pass-through, double-damage
scaling, double-damage × weaken stacking, the 1.0 minimum-damage floor under
heavy mitigation, and tower `damage_mult` application.

## 7. Test coverage — new locale templates
New suite verifies both `enemies_count` and `wave_threat_notify` substitute
cleanly in **en and zh** with no leftover `{placeholder}` braces.

## 8. Audio — SFX volume floor
`clamp_sfx_volume()` only clamped the loud ceiling; a pathologically negative
caller value stacked on a per-sound offset could sink toward ~-inf dB. Added an
`SFX_MIN_VOLUME_DB` floor (-40 dB, far below the quietest configured offset of
-12) so normal levels are untouched but degenerate inputs are bounded.

## 9. Code quality — extracted `HERO_POOL_PER_KILL`
The per-kill Fallen Hero pool gain (`add_to_hero_pool(1)` in `combat_kill`) is
now the named constant `Config.HERO_POOL_PER_KILL`, giving the hero-pacing math a
single knob. Covered by a deterministic combat-kill test.

## 10. Test coverage — wave threat pacing guard
New suite asserts the difficulty curve never accidentally flattens: the final
wave's threat dwarfs the opening wave (>5×), and late-game waves carry more total
threat than early-game ones — a guard against future wave-data edits.

---

### Verification
- `tests/test_runner.gd`: **3141/3141 passed** (was 3056).
- `godot --headless --quit`: no `SCRIPT ERROR` / parse errors across all scripts
  (including `hud.gd`, which the test scene doesn't load).
