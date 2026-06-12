# Daily Improvement — 2026-06-12

## Headline: The Holy Sentinel's shield had two holes in it — both are now sealed

Last run made single-target towers respect the Holy Sentinel's protection.
Today's audit found the two remaining damage paths that still punched straight
through the shield: Lucifer's execute and the Devil's Dice AoE. Both are fixed,
alongside an i18n bug that left Chinese players with untranslated tower
tooltips, a per-frame HUD translation cost, and the game's most-performed
action — placing a tower — finally getting a sound.

**Test results:** `2496 / 2496` assertions passing (was `2442 / 2442`; **+54 new**).
Main game scene loads with **no `SCRIPT ERROR`** (parse gate clean).

---

## What changed and why

### Bug fixes

1. **Lucifer's execute no longer kills through the Holy Sentinel's shield.**
   `combat_hit` correctly no-ops on guardian-protected enemies, but
   `_lucifer_pulse` then checked `hp <= 15% max` and called `combat_kill`
   unconditionally. A protected enemy whittled below the threshold by burn
   DoT (which ticks directly on `hp`) would be executed straight through the
   shield. The execute now skips protected enemies, matching every other
   damage path.

2. **Devil's Dice AoE (Hellstorm / Small Spark) now respects the shield too.**
   `_damage_all_percent` subtracted max-HP fractions from every enemy with no
   guardian check — the last remaining bypass. Protected enemies now get the
   guardian block flash instead of damage. The Sentinel itself is never
   protected, so dice remain a legitimate counter to it.

3. **Chinese tower tooltips were silently English.** The `_zh` table still
   carried the pre-redesign description strings ("AoE blasts, essential vs
   swarms", "Ice spike ramps damage on same target", …) that no longer match
   any `TOWER_DATA` desc — so `Locale.t()` fell through to English for 5 of 6
   towers. The current desc strings are now translated and the dead entries
   removed. A new data-driven test asserts every tower name/desc and enemy
   name has zh coverage, so the table can't drift again.

### Code quality

4. **Extracted `GM.upgrade_cost(tower)` / `GM.sell_refund(tower)`.** The
   upgrade-cost formula lived in `upgrade_tower` AND `hud.gd`'s button label;
   the sell-refund formula in `sell_tower` AND the sell button. Four sites,
   two formulas, free drift potential — the price shown could diverge from the
   price charged. Both now share single helpers, with tests pinning the math
   and the charge/credit amounts.

### Performance

5. **HUD static translations no longer rebuilt every frame.**
   `_update_locale_text()` re-translated ~20 strings (menu, overlays, help
   text, volume labels) in `_process` on every frame, even though they only
   change on language toggle. It's now connected to the existing — previously
   unused — `Locale.language_changed` signal and runs exactly twice per
   session plus once per toggle. The static dice description label moved
   there too.

6. **`Config.path_half` precomputed at load.** `_is_guardian_protected` runs
   per enemy per tower per frame while a Sentinel is alive, and recomputed
   `path_pixels.size() / 2` every call. It's now computed once in
   `_init_path()` and shared with the guardian-zone overlay draw, so the
   shield boundary also can't have two definitions. A boundary test pins
   `path_half - 1` protected / `path_half` unprotected.

### UX / Audio

7. **Tower placement finally makes a sound.** Building a tower — the action
   players perform most — was completely silent. Added a procedural
   `tower_place` generator (low stone thunk + rising power-up shimmer, in the
   style of the existing synth fallbacks) at priority 3 so it survives busy
   combat frames.

8. **Upgrades are audible from the keyboard path.** The HUD button played a
   generic click, but the `U` hotkey gave no feedback at all. Successful
   upgrades now play `ui_select` from inside `upgrade_tower`, so both paths
   confirm.

### Test coverage

9. **Six new test suites (+54 assertions):** Lucifer execute vs guardian
   (including "executes again once the Sentinel dies"), dice AoE vs guardian
   (protected / exposed / the Sentinel itself / no-sentinel regression), cost
   helper math + exact charge/credit, `path_half` boundary behavior,
   `tower_place` generator validity + priority, and zh locale coverage for
   all tower/enemy strings.

10. **Stale `.git/index.lock` removed.** A crashed git process from the
    May 25 run left a lock file that blocked all staging; cleared it before
    committing.

---

## Notes

- **Push status:** the commit is made locally on `main`. This run's sandbox
  has no GitHub credentials (SSH key absent), so `git push` could not
  complete — `git push` from the host machine will publish both commits.
- Balance simulator (`simulate.py`) untouched; no tuning-parameter changes
  this run, so no re-sync needed.
