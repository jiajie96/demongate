# Daily Improvement — 2026-06-20

Tests: **2629/2629 passing** (up from 2591; +38 new assertions across 5 new suites).
Verified against Godot 4.6.2 headless on the same `test_runner.tscn` path CI uses.

## Improvements

### Content / Gameplay
1. **New relic: Vital Surge (`core_heal`)** — a defensive relic that repairs Hell's
   Core (`VITAL_SURGE_HEAL = 25`, clamped to `core_max_hp`). Fits the reverse-morality
   fiction (the demon patches the Core the Divine Army has been carving) and gives the
   loot table its first survival-oriented drop to complement the all-offense relics.
   Weighted at 8; the full table still sums to 100.

2. **Completed the `core_heal` drop handler** — the relic was present in `RELIC_LOOT`
   but `drop_relic()` had no matching `case`, so dropping it would notify the player
   and heal nothing. Added the handler and an overheal-accurate notification: it
   reports the HP *actually* restored, so a heal at near-full HP doesn't falsely
   promise +25 when only a sliver was missing.

### Bug fixes / Correctness
3. **Tremor dice roll could rescue a punished tower** — `disable_3s` previously set
   `disable_timer = 3.0` unconditionally, which would *shorten* a longer disable
   already running (e.g. an 8s Divine Curse). A negative event should never benefit
   the player. Now uses `maxf` so it can only extend, never shorten.

4. **Devil's Tax loss was invisible** — the `tax_sins` dice outcome silently removed
   10% of Sins; the generic outcome notification only showed the roll. Added a
   dedicated `-{amount} Sins` notification and a new `sins_taxed` stat so the player
   sees (and the game records) what was lost.

### Code quality / Refactoring
5. **`enemy_defense_multiplier()` shared helper** — consolidated the shield /
   `shield_buff` / Archangel-Marshal-commander mitigation math that was duplicated
   between `calc_damage()` and the Cocytus cone. The two damage paths can no longer
   drift, and a future defensive modifier only has to be added once.

6. **`_disable_all_towers(duration)` helper** — extracted the mass-disable loop out of
   `roll_dice()`. Carries the `maxf` no-shorten guarantee (#3) and is independently
   unit-testable.

7. **`DICE_SIDES` constant** — replaced the inline `randi() % 6 + 1` in `roll_dice()`
   with `randi() % Config.DICE_SIDES + 1`, so the die size lives next to
   `DICE_MAX_USES` and can't silently disagree with the 1..6-keyed outcome tables.

### Performance
8. **Cocytus cone: precompute `cos_half_sq`** — hoisted `cos_half * cos_half` out of
   the per-enemy loop in `_cocytus_cone()`; the cone now compares against a value
   computed once per call instead of squaring every iteration.

### Test coverage
9. **5 new test suites (+38 assertions)** covering the changes above:
   - `Vital Surge Relic` — loot-table integrity, deterministic `core_heal` drop
     (forces a single-entry table), heal amount, and `core_max_hp` clamp.
   - `Enemy Defense Multiplier` — no-mitigation, shield, `shield_buff`, multiplicative
     stacking, commander aura, and commander-self-exemption.
   - `Dice Sides Constant` — value and full-coverage of both outcome tables 1..N.
   - `Dice Tax Stat` — stat initialization, `DICE_TAX_PERCENT` bounds, locale template.
   - `Dice Disable No-Shorten` — fresh disable, no-shorten guarantee, longer-extends.

### Localization
10. **New bilingual (en/zh) locale templates** — `core_healed` and `sins_taxed`,
    keeping all new player-facing notifications translated.

## Files touched
- `scripts/autoload/game_config.gd` — `DICE_SIDES`, `VITAL_SURGE_HEAL`, Vital Surge loot entry.
- `scripts/autoload/game_manager.gd` — `enemy_defense_multiplier`, `_disable_all_towers`,
  `core_heal` handler, tax stat/notify, `DICE_SIDES` wiring, Cocytus precompute.
- `scripts/autoload/locale.gd` — `core_healed`, `sins_taxed` templates.
- `tests/test_runner.gd` — 5 new suites; updated relic-count assertion to 11.
