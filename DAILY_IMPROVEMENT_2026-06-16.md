# Daily Improvement — 2026-06-16

Ten improvements across gameplay, content, code quality, performance, UX/i18n, and
test coverage. Baseline before work: **2528/2528** assertions passing. After:
**2566/2566** passing (+38 assertions across 5 new suites). GDScript validation clean.

## Gameplay & balance

1. **Raphael heal is now range-limited (counterplay).** Archangel Raphael previously
   healed the single most-wounded enemy *anywhere on the map* — an unavoidable global
   heal with zero counterplay. It now only heals enemies within `RAPHAEL_HEAL_RANGE`
   (200px, ~4 tiles), added as a data-driven `heal_range` field on the enemy. Players
   can now deny heals by focusing or out-positioning Raphael. Existing Raphael tests
   (allies within ~40px) still pass unchanged.

## Content & synergy

2. **New relic: Soul Surge.** A new Pandora's Relic (`type: soul_surge`, weight 6) that
   instantly pours `SOUL_SURGE_POOL` (75) into the Fallen Hero pool via the existing
   `add_to_hero_pool` rollover logic — a well-timed drop can summon a Fallen Hero
   mid-fight. Reinforces the kill-economy loop. Relic weights rebalanced (Hellfire Bomb
   31→28, Sin Cache 27→24) so the table still sums to 100. Localized name + notification
   for en/zh.

## Code quality

3. **Shared `format_large` stat formatter.** The HUD had its own `_format_large_number`
   copy that printed `"2.0k"` for whole thousands. Extracted a single
   `GM.format_large` (with a shared `_strip_dot_zero` helper) so end-screen stats read
   `"2k"` / `"3M"`, matching `format_damage`/`format_kills`. HUD now delegates to it.

4. **`_weighted_pick` empty-table guard.** Returning `table[size()-1]` on an empty array
   is an out-of-bounds crash; the helper now returns an empty dict for empty input.

## Performance

5. **Defer attack-speed math past the cooldown gate in `update_towers`.** Both the
   single-target and Lucifer-pulse branches computed `attack_speed * tower_speed_multiplier`
   on *every* frame, including frames where the tower is idling on cooldown (the common
   case). The computation now runs only on frames a tower actually fires.

## UX / i18n

6. **Localized targeting-mode labels.** The tower Target button showed raw English mode
   names (`Closest`, `Strongest`) even in Chinese. Added `targeting_*` locale templates
   (en/zh) and a `GM.targeting_mode_label` helper with a safe capitalized fallback for
   unknown modes; the HUD now uses it.

## Test coverage (5 new suites, +38 assertions)

7. **`[Format Large]`** — sub-1k passthrough, k/M suffixes, trailing-`.0` strip, and the
   `2000 -> "2k"` regression that motivated the dedup.
8. **`[Targeting Mode Label]`** — every real mode resolves to a non-empty, key-free label;
   zh labels are actually translated; unknown modes fall back gracefully.
9. **`[Raphael Heal Range]`** — ally inside range is healed; the most-wounded ally beyond
   range is *not* (the new counterplay); field/constant wiring is asserted.
10. **`[Soul Surge Relic]` + `[Weighted Pick Empty Guard]`** — loot-table integrity
    (size 10, weights sum 100), Soul Surge feeds the pool and rolls over the hero
    threshold, and `_weighted_pick` handles empty/single-entry tables without crashing.

## Verification

- Ran the full suite headless (Godot 4.6.2): **2566/2566 passed, ALL TESTS PASSED**.
- Ran `--headless --quit` script validation: no SCRIPT ERROR / parse errors.
- Updated the pre-existing `9 relic loot types` assertion to `10` for the new relic.
