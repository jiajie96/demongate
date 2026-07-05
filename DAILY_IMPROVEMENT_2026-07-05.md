# Daily Improvement — 2026-07-05

Ten improvements across bug fixes, gameplay, code quality, performance, content, and
test coverage. All tests pass: **3568 / 3568** (up from 3487; +81 assertions), no
`SCRIPT ERROR` / parse errors on a headless run of both the test suite and `main.tscn`
under Godot 4.6.2.

> Note: this commit also lands the previously-uncommitted **2026-07-03** batch (Pact of
> Ruin, Corruption Wave no-downgrade, `wave_boss_count`, campaign-fold helpers, tower
> online/offline split, cleric-aura perf hoist, boss-count notification) which was sitting
> in the working tree unstaged. Its own summary is in `DAILY_IMPROVEMENT_2026-07-03.md`.

## Summary of today's changes

### 1. Bug fix — legacy tower slow could DOWNGRADE a stronger/longer slow
`combat_hit` unconditionally wrote `slow_amount = tower.slow_power` and
`slow_timer = SLOW_DEBUFF_DURATION`, so a weak legacy-slow tower hitting an enemy already
harder-slowed (a Corruption Wave relic, Cocytus frost) would **weaken** or **shorten** that
slow. Now takes `maxf` of the existing values — a slow can only ever get stronger/longer.
Mirrors the `mass_corrupt` and Frenzy Totem no-downgrade guards.

### 2. Bug fix — tower-weaken pact COST could be quietly refunded
The `tower_weaken` pact cost overwrote `tower_weaken_waves = c_val`, so taking a second
weaken pact (Abyssal Gambit / the new Pact of Thorns) while one was active could **shorten**
the remaining penalty — a cost the player agreed to, silently discounted. Now `maxi`, so a
re-take never reduces an active weaken (and a longer one still extends it).

### 3. Bug fix — sin-income boost pact could downgrade an active stronger boost
The `sin_boost` benefit overwrote both `sin_multiplier` and `sin_mult_waves`, so accepting a
weaker boost (Blood Tithe ×1.5 / 2 waves) while a stronger one ran (Pact of Avarice ×2.0 /
3 waves) **reduced** the multiplier and cut the duration. Now keeps the better multiplier and
the longer window independently (`maxf` / `maxi`); expiry still resets to ×1.0 on runout.

### 4. Content — new 10th Demonic Pact "Pact of Thorns"
The "turtle's bargain": a big one-shot **+35 Core HP** heal (the largest single-pact heal —
Dark Resilience heals 20) paid for with a temporary **−15% tower damage for 3 waves**. It's
the mirror of Abyssal Gambit (free tower for the same weaken cost): Thorns instead buys
survivability for a player who over-extended on Core HP. Reuses the existing `core_heal`
benefit and `tower_weaken` cost handlers — no new `accept_pact` branch. `PACT_POOL_SIZE`
bumped 9→10, en/zh locale added.

### 5. Helper — `Config.relic_total_weight()` + `Config.relic_drop_chance(name)`
Pure helpers exposing the loot distribution: the total selection weight of `RELIC_LOOT` and
the probability (0..1) that a named relic is the one picked from a single weighted draw
(weight / total, 0 for unknown names). Mirrors the runtime `_weighted_pick` math so UI can
honestly advertise loot odds and tests can pin the distribution (all chances sum to 1.0).

### 6. Helper — `Config.peak_threat_wave()` + `Config.average_wave_threat()`
`peak_threat_wave` returns the index of the single most threatening wave (highest
`wave_threat`, earliest on ties); `average_wave_threat` is the campaign mean
(`campaign_total_threat / wave_count`, 0 when empty). "Which wave is scariest / how does this
wave compare to average" figures for menus and difficulty tuning, both pure folds.

### 7. Helper — `GM.tower_count_of_type(type)`
The counting companion to `has_tower_type`: how many towers of a type are BUILT (disabled
included). Backs "Bone Marksman ×3" UI, per-type build caps, and synergy checks that want a
tally rather than a yes/no. Pure scan; per-type counts sum to the roster size.

### 8. Performance — cache Inferno Warlock burn config out of the burn hot path
`_apply_burn` re-read `Config.TOWER_DATA["inferno_warlock"]` and re-parsed three fields on
**every burn hit** (a hot path for any inferno-heavy build). These are compile-time
constants, so they're now lazily cached into scalar members on first burn. Behavior is
identical (covered by a new test asserting the cached scalars match Config and stacks still
add + cap correctly).

### 9. Content/UX — `Config.dice_positive_chance(wave)`
The probability a Devil's Dice roll lands positive at a given wave: 1.0 before
`DICE_NEGATIVE_WAVE` (all faces good), 0.5 after (clean 3-good/3-bad split). Computed from the
actual outcome table's polarity, not a hard-coded fraction, so it stays honest if a face is
ever retuned. Lets a future UI show the player exactly how safe a roll is before committing a
die.

### 10. Docs & test coverage — refreshed badges + 9 new suites (+81 assertions)
README test badges updated 3487→3568. New suites: `_run_legacy_slow_no_downgrade_tests`,
`_run_tower_weaken_no_downgrade_tests`, `_run_sin_boost_no_downgrade_tests`,
`_run_pact_of_thorns_tests`, `_run_relic_drop_chance_tests`, `_run_tower_count_of_type_tests`,
`_run_peak_threat_wave_tests`, `_run_inferno_burn_cache_tests`, `_run_dice_positive_chance_tests`.
These pin the three no-downgrade invariants (slow / weaken cost / sin boost, both directions),
the new pact's benefit/cost/heal-cap/locale wiring and the pool-size bump, the relic
distribution (weight fold + odds sum to 1.0 + unknown → 0), the per-type tower tally, the
peak/average threat folds, the burn-cache correctness, and the dice odds table. The stale
"9 demonic pacts" assertion was updated to 10.

## Verification
- `godot --headless res://tests/test_runner.tscn` → **3568/3568 passed, ALL TESTS PASSED**.
- `godot --headless --quit res://scenes/main.tscn` → 0 `SCRIPT ERROR` lines.
