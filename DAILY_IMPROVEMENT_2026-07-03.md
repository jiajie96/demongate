# Daily Improvement — 2026-07-03

Ten improvements across content, gameplay, code quality, performance, UX, and test
coverage. All tests pass: **3487 / 3487** (up from 3365; +122 assertions), no
`SCRIPT ERROR` / parse errors on headless run of both the test suite and `main.tscn`
under Godot 4.6.2.

## Summary of changes

### 1. Content — new 9th Demonic Pact "Pact of Ruin"
A "blood for power" gamble: **+30% tower damage permanently** for a flat **−20 Core HP**.
It's the only pact pairing the permanent damage benefit with a Core-HP cost — Infernal
Forge also grants a permanent buff but pays by disabling towers, while the other core_dmg
pacts (Blood Tithe, Pact of Avarice) buy a *temporary* Sin-income boost. Ruin buys the
strongest permanent buff in the pool (+30% vs Forge's +20%), rewarding all-in aggression
with a payoff that survives past the wave it's taken. Reuses the existing `tower_dmg_boost`
benefit and `core_dmg` cost handlers — no new `accept_pact` branch. `PACT_POOL_SIZE` bumped
8→9, en/zh locale added.

### 2. Bug fix — Corruption Wave relic could downgrade a stronger slow
`mass_corrupt` unconditionally wrote `slow_amount = 0.3` / `slow_timer = 5.0`, so a second
Corruption Wave (or any future stronger slow source) could **weaken or shorten** an enemy
that was already more slowed. Now takes `maxf` of the existing slow amount and timer — a
positive relic can only ever help. Mirrors the Frenzy Totem no-downgrade guard.

### 3. Code quality — `Config.wave_boss_count()` + `is_boss_wave` dedup
New pure helper counts the true-boss (`is_boss`) head-count in a wave. `is_boss_wave` now
delegates to it (`wave_boss_count(i) > 0`), so "what counts as a boss wave" lives in exactly
one loop instead of two. Complements the existing `wave_special_count` (bosses are a subset
of specials).

### 4. Helper — `Config.campaign_total_threat()`
Grand total worst-case Core threat across the whole campaign (a pure fold over `wave_threat`).
A single honest "how punishing is a full run" figure for menus/stats, mirroring
`total_scheduled_enemies`.

### 5. Helper — `Config.total_scheduled_bosses()`
Grand total of boss enemies scheduled across all waves (pure fold over `wave_boss_count`) —
a "how many bosses does a full run throw at you" stat.

### 6. Code quality — `GM.active_tower_count()` / `disabled_tower_count()`
Testable utilities for the online/offline split of the tower roster. `active + disabled`
always equals `towers.size()`; distinct from `towers.size()`, which counts Zeus-struck,
cursed, Tremor'd and pact-disabled towers as if they were firing.

### 7. Performance — hoist Temple Cleric aura constants out of the per-enemy loop
The cleric heal-aura branch re-read the config Dictionary, re-squared the aura radius and
recomputed the per-tick heal rate **for every cleric, every tick**. These are wave-invariant,
so they're now cached once before the enemy loop (`_cleric_data`, `_cleric_aura_r2`,
`_cleric_tick_heal`). Behavior is unchanged; a covering correctness test was added.

### 8. UX — boss-count wave notification
On boss waves, `start_wave` now posts an extra "☠ N Boss enemy incoming!" notification
(driven by `wave_boss_count`, only when N > 0), so the player can brace and gauge whether to
gamble. Regular waves stay quiet. New `wave_boss_notify` locale template (en/zh).

### 9. Docs — refreshed stale test-count badges in README
The README still advertised "472 passing" / "470+"; updated to the current 3487 / 3400+.

### 10. Test coverage — 8 new suites (+122 assertions)
`_run_pact_of_ruin_tests`, `_run_corruption_wave_no_downgrade_tests`,
`_run_wave_boss_count_tests`, `_run_campaign_total_threat_tests`,
`_run_total_scheduled_bosses_tests`, `_run_tower_count_helper_tests`,
`_run_cleric_heal_perf_tests`, `_run_wave_boss_notify_tests`. These pin the new pact's
benefit/cost/floor behavior, the corruption no-downgrade invariant, boss-count agreement
with a direct scan (bosses ⊆ specials ⊆ head-count), the campaign fold helpers, the
active/disabled roster split invariant, cleric heal correctness after the perf hoist
(in-range heals exactly one tick, out-of-range heals nothing), and the boss-notification
wiring (fires on boss waves, silent otherwise).

## Verification
- `godot --headless res://tests/test_runner.tscn` → **3487/3487 passed, ALL TESTS PASSED**.
- `godot --headless --quit res://scenes/main.tscn` → no `SCRIPT ERROR` / parse errors.
