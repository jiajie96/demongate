# Daily Improvement — 2026-05-24

## Headline: Hades support was secretly doing nothing for Lucifer and Cocytus

The standout find today was a real, ship-affecting balance bug: a Hades tower's
attack-speed/DPS buff **never applied to Lucifer or Cocytus**, even though the
HUD claimed it did for Lucifer. Two of the game's most expensive towers were
quietly getting zero value from the support archetype built to amplify them.

**Test results:** `2411 / 2411` assertions passing (was `2378 / 2378`; +33 new).
Main game scene loads with **no `SCRIPT ERROR`** (CI parse gate).

---

## What changed and why

### Bug fixes

1. **Hades buff now applies to every buffable tower (Lucifer + Cocytus).**
   When Hades buffs a neighbour, the buffed tower only stores a boolean
   `hades_buffed`; the buff *strength* is the global `HADES_BUFF_DEFAULT` (1.5×).
   The single-target tower path already used that constant, but the Lucifer
   pulse path and `_calc_cocytus_dps` instead read `tower.get("buff_multiplier",
   1.5)`. That field is the *Hades tower's own* buff strength — it's `1.0` on
   every non-Hades tower, and because the key exists the `1.5` default never
   fired. Net effect: `× 1.0`, i.e. no buff. Both call sites now use
   `Config.HADES_BUFF_DEFAULT`, matching the single-target path **and** the HUD
   (which already displayed 1.5× for Lucifer — so this also fixes a
   HUD-vs-gameplay mismatch).

2. **Special enemies no longer fire their ability on the spawn frame.**
   `create_enemy` initialised `ability_timer` to `0.0`, so Michael / Zeus /
   Raphael triggered their shield / tower-disable / heal the very first frame
   they were processed — an instant, unavoidable effect with zero counterplay
   (a freshly-spawned Zeus could disable towers before the player even saw it).
   The timer is now seeded with each ability's cooldown, so the first cast lands
   one cooldown after the enemy arrives. Ordinary enemies stay at `0.0`.

### Code quality

3. **Extracted `_apply_tower_levelup(tower)`.** The four-line stat-scaling block
   (level++, ×damage, ×range, ×attack_speed) was duplicated in `upgrade_tower`
   and `free_upgrade_best_tower`. They now share one helper, so the paid upgrade
   and the Legendary Blueprint free upgrade can never drift apart.

4. **`format_kills` k-strip consistency.** It now mirrors `format_damage`:
   whole-thousand counts render as `"1k"` / `"10k"` instead of `"1.0k"` /
   `"10.0k"`, while fractional counts keep one decimal (`"2.5k"`).

### UX / UI

5. **Targeting control hidden for towers that ignore targeting.** Global
   (Lucifer), beam-cone (Cocytus) and support (Hades) towers never read
   `targeting_mode`, yet the "Target: …" button was shown for the cone/global
   ones and the `T` hotkey silently cycled an ignored value. A new
   `GM.uses_targeting(tower)` helper drives the button's visibility, and
   `cycle_targeting` early-returns for those towers so the hotkey is a clean
   no-op.

### New test coverage (regression guards)

6. **`[Hades Buff All Towers]`** — builds a *fresh* Cocytus (no manual
   `buff_multiplier` override, unlike the older suite that masked the bug) and
   asserts its DPS rises by exactly `HADES_BUFF_DEFAULT` when Hades-buffed. Also
   pins the `buff_multiplier == 1.0` invariant that caused the bug.
7. **`[Special Enemy Ability Delay]`** — Michael/Zeus/Raphael spawn with their
   cooldown as the initial `ability_timer`; plain enemies stay at `0.0`.
8. **`[Tower Levelup Helper]`** — the helper and the paid `upgrade_tower` path
   produce identical scaled stats.
9. **`[Format Kills K-Strip]`** — locks in `1000 → "1k"`, `1500 → "1.5k"`, etc.
10. **`[Uses Targeting]`** — single-target/AoE/slow towers use targeting;
    support/cone/global do not; `cycle_targeting` is a no-op on the latter.

---

## Verification

- Ran the full suite under Godot 4.6.2 (ARM64, matching CI): **2411/2411 passed.**
- `godot --headless --quit` (loads `main.tscn`) → no `SCRIPT ERROR`, confirming
  `game_world.gd` / `hud.gd` / autoloads still parse and link cleanly.

## Notes for the maintainer

- The older `[Cocytus DPS Calc]` suite still passes because it manually sets
  `buff_multiplier = 1.5` before checking the buff — which is exactly why it
  never caught bug #1. The new `[Hades Buff All Towers]` suite covers the real
  (un-patched) tower, so the regression can't slip back in.
- **Git push from this sandbox:** the environment authenticates to GitHub over
  SSH (`git@github.com:jiajie96/demongate.git`). If no push credential is
  present the commit is made locally and `main` ends up ahead of `origin/main`;
  run `git push origin main` from a credentialed machine if so. (A prior run's
  commit may also still be pending push — check `git log origin/main..HEAD`.)
- The repo lives on a virtiofs mount that disallows file *deletion* and leaves
  stale `.git/index.lock` files behind; this run renames them aside into the
  git-ignored `.lockgrave/` rather than deleting. Safe to remove locally.
