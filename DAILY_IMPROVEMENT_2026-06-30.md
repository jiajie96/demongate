# Daily Improvement — 2026-06-30

Ten improvements that harden and extend the **Demonic Pact** system — a bug fix,
a UX gap, two code-quality refactors, new content, localization, and four new
test suites. The full suite passes at **3194/3194 assertions** (+53 new), and all
scripts validate with no parse errors.

## 1. Bug fix — accepted pacts silently skipped the `sins_taxed` stat
The Devil's Tax dice roll records every Sin it drains in `stats["sins_taxed"]`,
but the **Dark Resilience** pact's `sin_tax` cost deducted Sins with a bare
`sins -= lost` and never touched the stat. A run that paid its Core repairs with
pact taxes under-reported lifetime Sins lost. Both paths now share one helper
(see #3), so the stat can never drift again.

## 2. UX — pact tax now tells the player exactly what they paid
Accepting a `sin_tax` pact previously showed only the generic "Accepted!"
notification — the player never learned how many Sins vanished. It now fires the
same `sins_taxed` notification the dice tax uses ("Lost N Sins"), in red, so the
cost of Dark Resilience / Wrathful Bargain is legible at the moment of payment.

## 3. Code quality — shared `apply_sin_tax(percent)` helper
Extracted the duplicated tax math (`roundi(sins * percent)`, deduct, track stat)
out of both `roll_dice()` and `accept_pact()` into a single
`GM.apply_sin_tax(percent)` that returns the exact amount lost. Single source of
truth: the two tax paths can no longer disagree on rounding or stat tracking, and
the helper floors the purse at 0 (`clampi(lost, 0, sins)`) so a degenerate
`>100%` tax can never push Sins negative.

## 4. Content — new Demonic Pact "Wrathful Bargain"
A seventh pact and the highest-tempo gamble in the pool: **double damage for two
full waves**, paid for with a steep **−30% of current Sins**. It reuses the
existing `double_dmg` benefit (`b_val` carries the wave count) and `sin_tax` cost
handlers, so no new `accept_pact` branch was needed. It's deliberately distinct
from Chaos Pact (double damage + extra War Titans): one trades **economy**, the
other trades **extra threat**.

## 5. Localization — en/zh strings for the new pact
Added Chinese translations for the pact name ("暴怒交易"), its benefit
description ("Double damage for 2 waves" → "2波内伤害翻倍"), and its cost
("Lose 30% of current Sins" → "失去当前30%的罪孽"), matching every other pact so
the offer panel reads cleanly in both languages.

## 6. Code quality — extracted `PACT_DISABLE_COUNT` constant
The Infernal Forge pact disabled `mini(2, candidates.size())` towers — an inline
`2` that the cost text ("**2** random towers disabled for 8s") silently depended
on. Promoted to `Config.PACT_DISABLE_COUNT`, so the count lives next to the pact
data and the description can't drift from behavior.

## 7. Test coverage — `apply_sin_tax` helper suite
Pins the new helper: proportional deduction, stat **accumulation** across
multiple taxes (not overwrite), the negative-purse floor under a `>100%` tax, and
harmless no-ops on an empty purse or a 0% rate.

## 8. Test coverage — pact `sin_tax` stat suite
Asserts that accepting a `sin_tax` pact now records the loss in `sins_taxed` and
deducts the right amount — the exact regression that #1 fixed.

## 9. Test coverage — Wrathful Bargain pact suite
Verifies the pact's data shape, that it's appended **last** (so existing
index-based pact tests stay valid), that accepting it sets a 2-wave
double-damage window and taxes 30%, and that its name/benefit/cost strings all
resolve in zh with no English fall-through.

## 10. Test coverage — `PACT_DISABLE_COUNT` + pact-count invariant
New suite confirms `disable_random` disables exactly `PACT_DISABLE_COUNT` towers
when enough exist and clamps gracefully to a lone tower otherwise. Bumped the two
pact-count assertions (`6 → 7`) and the `DEMONIC_PACTS.size() == PACT_POOL_SIZE`
invariant, which is what caught the new pact needing a `PACT_POOL_SIZE` bump.

---

### Verification
- `tests/test_runner.gd`: **3194/3194 passed** (was 3141, +53 new assertions).
- `godot --headless --quit`: no `SCRIPT ERROR` / parse errors across all scripts,
  including `hud.gd` (which the test scene doesn't load).
- Engine: Godot 4.6.2-stable.
