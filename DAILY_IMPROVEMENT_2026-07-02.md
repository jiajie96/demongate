# Daily Improvement — 2026-07-02

Ten improvements to Demongate (reverse-morality tower defense, Godot 4.6 / GDScript).
All **3365 tests pass** (up from 3258 — **+107 new assertions**, 7 new test suites).

## Improvements

### 1. Bug fix (i18n): missing "Vital Surge" relic-name translation
`Locale.t("Vital Surge")` had no entry in the `_zh` name table (only the
`core_healed` message template was translated), so Chinese players saw the raw
English relic name in the drop notification. Added `"Vital Surge": "生命涌动"`.

### 2. Content: new "Frenzy Totem" relic
A short, guaranteed all-tower attack-speed burst (`+40% / 8s`). It gives the relic
pool a positive "go fast" tempo option alongside the existing damage / economy /
defense drops, and is deliberately milder and shorter than the Demonic Surge dice
roll (`+80% / 15s`) so the two don't overlap. Added `FRENZY_TOTEM_SPEED` /
`FRENZY_TOTEM_DURATION` constants, a `RELIC_LOOT` entry (weight 7), a `frenzy`
handler in `drop_relic`, and en/zh name + notify translations.

### 3. Gameplay polish: positive relic never downgrades an active buff
Because Frenzy Totem is a *positive* drop, its handler guards against clobbering a
stronger buff already in flight — it takes the **stronger factor** and the
**longer remaining duration** (`maxf`) rather than overwriting an active Demonic
Surge (1.8×) with the totem's 1.4×. A "good" drop can never feel like a nerf.

### 4. Relic weight rebalance (kept invariant intact)
Adding a 12th relic required keeping the loot-weight total at 100. Trimmed Hellfire
Bomb (24→20) and Sin Cache (22→19) to fund Frenzy Totem's weight 7. The
weights-sum-to-100 invariant test still passes.

### 5. Code quality: `nearest_tower_to(x, y)` helper
Extracted the inline squared-distance "closest tower" loop out of `drop_relic`'s
Tower Blessing branch into a single reusable helper, matching the existing
`strongest_tower_by_dps` pattern. One definition of "nearest tower" for future
proximity picks.

### 6. Code quality: `Config.is_boss_wave(wave_index)` helper + `start_wave` dedup
`start_wave()` scanned a wave's enemies inline to red-tint the boss banner. Moved
that logic into a pure `is_boss_wave` helper in Config and called it from
`start_wave`, so "what counts as a boss wave" lives in one testable place.

### 7. Content/data helper: `Config.wave_special_count(wave_index)`
Pure mirror of the "specials" bucket `start_wave` peels into the back half of a
wave — a handy "how many heavy hitters this wave" figure, verified against a direct
`is_special_enemy` scan and proven to never exceed the wave head-count.

### 8. Content/data helper: `Config.total_scheduled_enemies()`
Grand total of every enemy across all 20 waves — a single honest "campaign scale"
number for menus/stats. Pure sum of `wave_enemy_count` over every wave.

### 9. Test coverage: relic-name i18n regression guard
New suite iterates the entire `RELIC_LOOT` table in zh mode and asserts each name
translates (`Locale.t(name) != name`). This is exactly the regression that let
Vital Surge ship untranslated — now any future relic missing a zh name fails CI.

### 10. Test coverage: `apply_sin_tax` edge cases
Added edge-case assertions for the shared sin-tax helper (used by Devil's Tax and
the Dark Resilience / Wrathful Bargain pacts): a 0% tax is a true no-op, an
over-100% tax clamps to the current balance (purse never goes negative), the
clamped amount is what gets recorded in `sins_taxed`, and taxing an empty purse
loses nothing.

## New test suites
`relic_name_translation`, `frenzy_totem`, `nearest_tower`, `is_boss_wave`,
`wave_special_count`, `total_scheduled_enemies`, `apply_sin_tax_edge`.

## Verification
Ran the full suite headless in Godot 4.6.2 (arm64): **3365/3365 passed.**
`project.godot` restored to the game main scene after the test run.
