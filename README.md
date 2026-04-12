# Hellgate Defenders

A tower defense game built with **Godot 4.6** where you play as the Demon Lord, defending Hell's Core against waves of divine warriors. Place demonic towers, earn Sins from fallen enemies, roll the Devil's Dice, and make Demonic Pacts to survive 20 waves of heavenly assault.

## Gameplay

Heaven has declared war on Hell. Waves of angels, holy knights, divine hunters, and gods march toward Hell's Core along a fixed path. Build towers on the roadside to stop them. If enemies break through and the Core reaches 0 HP, Hell falls.

**What makes it different from a typical tower defense:**

- **Reverse morality** — you're the villain, defending against "the good guys"
- **Sins economy** — a single unified currency earned from every kill, spent on towers and upgrades
- **High-stakes gambling** — Devil's Dice, Demonic Pacts, and Pandora's Relics create dramatic risk/reward moments
- **Enemy synergies** — enemies buff each other: Archangel Commander speeds up allies, Michael shields everyone, Zeus disables your towers
- **Single-screen focus** — the entire battlefield is visible at once, no scrolling distractions

### Controls

| Input | Action |
|-------|--------|
| Left Click | Place tower / Select placed tower |
| Right Click | Cancel placement / Deselect |
| D | Roll Devil's Dice (during active waves) |
| Space / Enter | Skip between-wave timer |
| Escape | Cancel current selection |
| 1 / 2 / 3 | Game speed: 0.5x / 1x / 2x |

## Towers

| Tower | Symbol | Cost | Role | Special |
|-------|--------|------|------|---------|
| **Demon Archer** | ARC | 50 | Fast single-target DPS | 1.8 atk/s, 120 range |
| **Hellfire Mage** | MAG | 90 | AoE swarm clearer | 60-radius blast, essential vs large groups |
| **Necromancer** | NEC | 120 | Slow/force multiplier | 40% slow on hit for 2s, amplifies all towers |
| **Lucifer** | LUC | 200 | Global damage pulse | Hits ALL enemies on map, 0.3 atk/s |
| **Hades** | HAD | 160 | Attack speed buffer | Buffs nearby towers 1.5x speed periodically |

Each tower has 3 upgrade levels (+35% damage, +10% range, +15% attack speed per level). Towers can be sold for 65% refund. Each tower supports 4 targeting modes: First (furthest along path), Last (earliest), Closest, and Strongest.

## Enemies

| Enemy | HP | Speed | Core Dmg | Role |
|-------|-----|-------|----------|------|
| Angel Scout | 14 | 80 | 3 | Swarm unit, fast and fragile |
| Holy Knight | 45 | 55 | 6 | Armored frontline |
| Divine Hunter | 28 | 130 | 5 | Speedster, hard to catch |
| Monk | 32 | 60 | 4 | Support unit |
| God of War | 110 | 38 | 14 | Heavy tank |
| Archangel Commander | 55 | 42 | 10 | Aura: +25% speed, -25% dmg taken for allies |
| Divine Guardian | 65 | 38 | 8 | Shield: makes enemies in first half of path invulnerable |
| Zeus | 80 | 45 | 12 | Lightning: disables 1-2 towers every 6s |
| **Paladin** (Boss) | 280 | 42 | 30 | Boss unit, always drops a relic |
| **Archangel Michael** (Boss) | 200 | 35 | 25 | Boss: shields all enemies every 8s (50% dmg reduction) |

Enemy HP and speed scale up after wave 3 (+6% HP, +1.5% speed per wave).

## Risk/Reward Systems

### Devil's Dice (press D during active waves)

Roll 1d6 for a combat gamble. Flat 16.67% chance per outcome. Uses replenish 1 per completed wave (max 2).

- **Waves 1–4**: All outcomes are positive (safe to roll freely)
- **Waves 5+**: 50/50 split — high rolls are powerful, low rolls punish (tower slowdown, disable, sin tax)
- **Rolling 6**: Kills ALL enemies on screen
- **Rolling 1**: Costs 15% of current Sins

### Demonic Pacts (every 5 waves)

Choose 1 of 3 pacts — each has a powerful benefit and a painful cost. You can always decline.

| Pact | Benefit | Cost |
|------|---------|------|
| Blood Rage | 2x tower damage for 3 waves | Core loses 20 HP |
| Infernal Discount | Next 3 towers free | Enemies 30% faster for 2 waves |
| Soul Harvest | 3x sin income for 1 wave | Enemies 20% faster for 2 waves |
| Hellfire Rain | Massive AoE to all enemies | All towers disabled 10s |
| Demonic Fervor | +50% attack speed (permanent) | Core max HP reduced by 25 |
| Sin Amplifier | 2x sin earnings for 5 waves | Current sins halved |

### Pandora's Relics (loot drops)

Defeated enemies occasionally drop relics with random effects — AoE bombs, sin caches, tower blessings, or traps that spawn bonus enemies.

## Game Design Analysis

This section evaluates the game against established game design theory, including the **MDA Framework** (Hunicke et al.), **Flow Theory** (Csikszentmihalyi), **Defender's Quest design principles** (Lars Doucet), and **Game Balance Concepts** (Ian Schreiber).

### Strengths

| Design Choice | Why It Works | Theory Source |
|---------------|-------------|---------------|
| Single-screen map | Preserves player focus — no off-screen anxiety | Defender's Quest: "Scrolling is the enemy of FOCUS" |
| Fixed path + roadside building | Separates tower placement from maze optimization | TD Game Rules (Rule 2.1) |
| 5 distinct tower roles | Each fills a unique niche without redundancy | Defender's Quest: limited, balanced variety |
| Single currency (Sins) | Reduces cognitive overhead, preserves focus for strategy | MDA Framework: streamlined mechanics |
| Enemy synergy mechanics | Creates designed difficulty (new mechanics) not artificial difficulty (stat inflation) | Game Balance Concepts |
| Reverse morality theme | Adds narrative freshness and aesthetic identity | MDA Framework: Discovery aesthetic |
| 2D rendered game state | Clear visual communication, no 3D camera confusion | Defender's Quest: readable game state |

### Areas for Improvement

| Issue | Status | Fix Applied | Theory Source |
|-------|--------|-------------|---------------|
| No speed control | **Fixed** | Added 0.5x/1x/2x speed buttons + keyboard shortcuts (1/2/3) | Defender's Quest: "Total Time Control" |
| Steep early difficulty curve | **Fixed** | Wave 2 reduced from 11 to 7 enemies, smoother ramp | Flow Theory: flow channel |
| 40% sell refund | **Fixed** | Raised to 65% — encourages experimentation | Game Balance: encourage repositioning |
| No targeting options | **Fixed** | 4 modes: First/Last/Closest/Strongest, per-tower cycling | TD genre convention |
| Dice probability skew | **Fixed** | Changed to 1d6 flat distribution; 50/50 positive/negative in late game | Probability design |
| Pact timing | **Fixed** | "Massive AoE" deferred to fire 2s into next wave | Internal logic |
| No stat display | **Fixed** | DPS calculation shown in tower info; HP numbers on enemy health bars | Defender's Quest: Total Information |
| Relics punish good play | **Mitigated** | Reduced curse/trap weights and severity (30s→10s, 2 spawns→1) | Feedback loop theory |
| Late-wave enemy walls | **Fixed** | Raised minimum spawn interval from 0.25s to 0.4s | Designed vs artificial difficulty |
| No catch-up mechanic | **Fixed** | Insurance payout (1.5x core damage as Sins) when enemies leak | Feedback loop: rubber-banding |
| Linear stat upgrades | Planned | Branching upgrades at level 2–3 | Game Balance: skill vs power challenges |

### Key References

- Doucet, L. — [Optimizing Tower Defense for FOCUS and THINKING](https://www.fortressofdoors.com/optimizing-tower-defense-for-focus-and-thinking-defenders-quest/) (Defender's Quest postmortem)
- Hunicke, R., LeBlanc, M., Zubek, R. — [MDA: A Formal Approach to Game Design](https://users.cs.northwestern.edu/~hunicke/MDA.pdf)
- Schreiber, I. — [Game Balance Concepts: Progression and Pacing](https://gamebalanceconcepts.wordpress.com/2010/08/18/level-7-advancement-progression-and-pacing/)
- Gamedeveloper.com — [Tower Defense Game Rules](https://www.gamedeveloper.com/design/tower-defense-game-rules-part-1-)
- Csikszentmihalyi, M. — Flow Theory applied to [difficulty in game design](https://ricardo-valerio.medium.com/make-it-difficult-not-punishing-7198334573b8)

## Getting Started

### Prerequisites

[Godot 4.6+](https://godotengine.org/download) (standard build, not .NET)

### Run the game

```bash
# Clone and open in Godot
git clone https://github.com/jiajie96/demongate.git
cd demongate

# Option 1: Open in Godot editor, press Cmd+B (macOS) or F5
# Option 2: Command line
godot --path .
```

### Run tests

```bash
# Run the full test suite (426 tests)
cp project.godot project.godot.bak
sed 's|run/main_scene=.*|run/main_scene="res://tests/test_runner.tscn"|' project.godot.bak > project.godot
godot --headless --path . --quit
mv project.godot.bak project.godot
```

## Project Structure

```
project.godot              # Godot project config + autoload registration
scenes/
  main.tscn                # Main scene: GameWorld (Node2D) + HUD (CanvasLayer)
scripts/
  autoload/
    game_config.gd         # All constants, tower/enemy/wave/gambling data, map path
    game_manager.gd        # Game state, economy, combat, waves, gambling systems
    audio_manager.gd       # Procedural sound effects and music (no audio files)
    locale.gd              # Internationalization / translation system
  game_world.gd            # 2D rendering (_draw) and input handling
  hud.gd                   # UI: top bar, side panel, overlays (menu/gameover/pacts)
  main.gd                  # Root scene script
tests/
  test_runner.gd           # 426 automated tests covering config, economy, combat, waves
  test_runner.tscn          # Test scene (swap as main scene to run)
```

### Architecture

Three autoload singletons drive the game:

- **Config** — Pure data. Tower stats, enemy stats, wave definitions, gambling tables, map path. Read-only at runtime.
- **GM** (Game Manager) — All mutable state and logic. Economy, combat resolution, wave spawning, gambling mechanics, effect timers.
- **Audio** — Procedurally generated sound effects and music (no audio files needed).

The rendering layer is intentionally simple:

- **GameWorld** — A single Node2D that calls `_draw()` every frame to render the map, towers, enemies, projectiles, and effects. All game entities are plain Dictionaries managed in Arrays.
- **HUD** — A CanvasLayer that builds all UI programmatically in `_ready()` and updates labels/buttons each frame from GM state.

## Roadmap

Planned features for future releases:

- [x] **Speed control** — 0.5x/1x/2x speed buttons + keyboard shortcuts (1/2/3)
- [x] **Tower targeting modes** — First, Last, Closest, Strongest per tower
- [x] **DPS stat display** — Shows effective DPS in tower info panel
- [x] **Enemy HP numbers** — Numeric HP above health bars
- [x] **Difficulty curve tuning** — Smoother early waves, better late-wave pacing
- [x] **Dice rebalance** — 1d6 flat distribution, 50/50 risk in late game
- [x] **Pact timing fix** — AoE pacts fire into next wave, not between waves
- [x] **Catch-up mechanic** — Insurance payout when enemies leak through
- [ ] **Branching upgrades** — Specialization choices at level 2–3
- [ ] **Sprite assets** — Replace colored shapes with actual demon/angel sprites
- [ ] **Save/load** — Persist mid-run state and high scores
- [ ] **Difficulty modes** — Easy / Normal / Nightmare with tuned enemy stats
- [ ] **Web export** — Publish to itch.io via Godot HTML5 export
- [ ] **Map editor** — Custom path layouts

## Tech Stack

- **Engine**: Godot 4.6 (GDScript)
- **Rendering**: Custom `_draw()` on Node2D — all entities are Dictionaries, not nodes
- **UI**: Programmatic Control nodes via CanvasLayer
- **Audio**: Procedurally generated (no audio files)
- **Tests**: Custom GDScript test runner (426 tests, no external dependencies)

## License

MIT
