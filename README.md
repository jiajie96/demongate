# Hellgate Defenders

A tower defense game built with **Godot 4.6** where you play as the Demon Lord, defending Hell's Core against waves of divine warriors. Place demonic towers, earn Sins from fallen enemies, gamble at the Soul Roulette, and make dark pacts to survive 20 waves of heavenly assault.

## Gameplay

Heaven has declared war on Hell. Waves of angels, holy knights, divine hunters, and gods march toward Hell's Core. Build towers along the path to stop them. If too many break through, Hell falls.

**What makes it different from a typical tower defense:**

- **Reverse morality** -- you're the villain, defending against "the good guys"
- **Sins economy** -- a single unified currency earned from every kill, spent on towers and upgrades
- **High-stakes gambling** -- Soul Roulette, Demonic Pacts, and Devil's Dice create dramatic risk/reward moments every few waves
- **Sharp difficulty curve** -- wave 1 is a gentle tutorial, wave 2 onward is genuinely hard

### Controls

| Input | Action |
|-------|--------|
| Left Click | Place tower / Select placed tower |
| Right Click | Cancel placement / Deselect |
| D | Roll Devil's Dice (during active waves, 2 per game) |
| Space / Enter | Skip between-wave timer |
| Escape | Cancel current selection |

## Towers

| Tower | Cost | Role | Special |
|-------|------|------|---------|
| **Demon Archer** | 50 | Fast single-target DPS | 2 attacks/sec, longest range |
| **Hellfire Mage** | 75 | AoE crowd control | Hits all enemies in blast radius |
| **Pit Brute** | 100 | Melee tank-killer | Massive single-hit damage, tiny range |
| **Necromancer** | 150 | Corruption specialist | Chance to corrupt dying enemies |

Each tower has 3 upgrade levels. Towers can be sold for 50% refund.

## Enemies

| Enemy | HP | Speed | Threat |
|-------|-----|-------|--------|
| Angel Scout | 8 | Fast | Swarm unit, low damage |
| Holy Knight | 25 | Medium | Armored frontline |
| Divine Hunter | 18 | Very fast | Speedster, hard to catch |
| God of War | 60 | Slow | Heavy tank, 10 core damage |
| Monk | 20 | Medium | Healer support |
| Paladin (Boss) | 150 | Medium | Boss unit, 20 core damage |

## Risk/Reward Systems

### Soul Roulette (every 3 waves)
Bet any amount of Sins. Outcomes range from 10x jackpot to total loss plus a cursed tower. You can always skip.

### Demonic Pacts (every 5 waves)
Choose 1 of 3 pacts -- each has a powerful benefit and a painful cost. Examples:
- *Blood Rage*: 2x tower damage for 3 waves, but Core loses 20 HP
- *Infernal Discount*: Next 3 towers free, but enemies 30% faster
- *Sin Amplifier*: Double sin earnings for 5 waves, but current sins halved

### Devil's Dice (2 per game, press D)
Roll 2d6 during a wave for an emergency gamble. Rolling 12 kills everything on screen. Rolling 2 costs you 25 Core HP and destroys your best tower.

### Pandora's Relics (loot drops)
Defeated enemies occasionally drop relics with random effects -- AoE bombs, sin caches, tower blessings, or traps that spawn bonus enemies.

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
# Validate all scripts
godot --headless --path . --quit

# Run the full test suite (310 tests)
cp project.godot project.godot.bak
sed 's|run/main_scene=.*|run/main_scene="res://tests/test_runner.tscn"|' project.godot.bak > project.godot
godot --headless --path .
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
    game_manager.gd        # Game state, economy, combat, waves, corruption, gambling
  game_world.gd            # 2D rendering (_draw) and input handling
  hud.gd                   # UI: top bar, side panel, overlays (menu/gameover/roulette/pacts)
  main.gd                  # Root scene script
tests/
  test_runner.gd           # 310 automated tests covering config, economy, combat, waves
  test_runner.tscn          # Test scene (swap as main scene to run)
```

### Architecture

Two autoload singletons drive the game:

- **Config** -- Pure data. Tower stats, enemy stats, wave definitions, gambling tables, map path. Read-only at runtime.
- **GM** (Game Manager) -- All mutable state and logic. Economy, combat resolution, wave spawning, gambling mechanics, effect timers.

The rendering layer is intentionally simple:

- **GameWorld** -- A single Node2D that calls `_draw()` every frame to render the map, towers, enemies, projectiles, and effects. This mirrors the HTML5 Canvas approach and keeps rendering in one place.
- **HUD** -- A CanvasLayer that builds all UI programmatically in `_ready()` and updates labels/buttons each frame from GM state.

## Roadmap

Planned features for future releases:

- [ ] **Sprite assets** -- Replace colored shapes with actual demon/angel sprites
- [ ] **Sound & music** -- Dark ambient soundtrack, tower/enemy sound effects
- [ ] **Fallen Heroes system** -- Pool sins to summon permanent allied units
- [ ] **Adaptive AI** -- Enemies counter your tower composition (shields vs physical, spread vs AoE)
- [ ] **More tower types** -- Expand beyond 4 with unlockable demon towers
- [ ] **Web export** -- Publish to itch.io via Godot HTML5 export
- [ ] **Save/load** -- Persist mid-run state and high scores
- [ ] **Difficulty modes** -- Easy / Normal / Nightmare with tuned enemy stats
- [ ] **Map editor** -- Custom path layouts
- [ ] **Localization** -- Multi-language support

## Tech Stack

- **Engine**: Godot 4.6 (GDScript)
- **Rendering**: Custom `_draw()` on Node2D
- **UI**: Programmatic Control nodes via CanvasLayer
- **CI**: GitHub Actions -- script validation + 310 automated tests
- **Tests**: Custom GDScript test runner (no external dependencies)

## License

MIT
