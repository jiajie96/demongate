# Daily Improvement Summary — 2026-05-07

## Changes Made

### Bug Fixes (4)

1. **Cocytus cone damage not tracked in global stats** — The Cocytus frost cone applies damage directly via `e["hp"] -= tick_dmg` bypassing `combat_hit`, so `stats["total_damage_dealt"]` was never incremented. Now adds `tick_dmg` to global stats each frame alongside the per-tower tracking.

2. **Burn DoT kills skip combat_kill path** — When burn damage killed an enemy in `update_enemies`, the inline kill logic only called `earn_from_kill` and incremented `enemies_killed`. It missed `boss_kills` stat tracking, relic drops (bosses always drop), and the kill_count on the originating tower. Now routes through `combat_kill(e, null)`.

3. **Safety kill path misses boss tracking** — The safety net that catches enemies with HP ≤ 0 at the start of `update_enemies` had the same problem as burn kills — inline logic instead of `combat_kill`. Fixed.

4. **Cheat skip (Ctrl+K) doesn't reset wave banner** — Skipping to wave 15 via the debug shortcut left `wave_banner_timer` running, causing a stale "WAVE N" banner to display over the new wave. Now resets `wave_banner_timer = 0.0`.

### Code Quality (6 constants extracted)

5. **WAVE_BANNER_SLIDE_IN / WAVE_BANNER_FADE_OUT** — Banner animation phase timings (0.35s slide-in, 0.7s fade-out) moved from inline magic numbers in `game_world._draw_wave_banner()` to `game_config`.

6. **OVERVIEW_PANEL_W / OVERVIEW_PANEL_H** — Tower stats panel dimensions (52×30 px) in the Tab overview extracted to config.

7. **CHEAT_SINS_AMOUNT / CHEAT_SKIP_TO_WAVE** — Debug shortcut values (99999 sins, wave 15) extracted to config so they're documented and tunable.

### Test Coverage (26 new assertions)

8. **Cocytus global damage tracking** — Verifies `_cocytus_cone` increments both `tower.total_damage` and `stats.total_damage_dealt`.

9. **Burn kill via combat_kill** — Verifies burn DoT kills track `boss_kills` for boss enemies, increment `enemies_killed`, and accumulate `total_damage_dealt`. Also tests the safety kill path with a pre-dead boss.

10. **All 6 pact types** — Tests Blood Tithe (sin_boost + core_dmg), Infernal Forge (tower_dmg_boost + disable_random), Chaos Pact (double_dmg + extra_enemies), and Abyssal Gambit (free_tower + tower_weaken) accept flows. Prior tests already covered Soul Harvest and Dark Resilience.

11. **Banner and cheat constants** — Validates animation timings sum correctly and cheat values are within game bounds.

12. **Overview panel constants** — Validates panel dimensions are positive and wider than tall.

## Test Count

~469 assertions (up from ~443).

## Commit

`52a3230` on `main`. Push pending (SSH keys not available in sandbox).
