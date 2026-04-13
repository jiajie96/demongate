# Visual Improvement Plan

## Completed

### 1. Screen Shake - DONE
- Core hit: 4px, 0.2s. Game over: 8px, 0.4s. Dice roll: 3px, 0.15s. Wave start: 2px, 0.15s.
- Applied as Node2D position offset with sin/cos for natural jitter.

### 2. Path Flow Animation - DONE
- 6 glowing dots flow along the path from spawn toward core.
- Color gradient: golden (heaven/spawn) → red (hell/core).
- Each dot has outer glow + core + bright center.

### 3. Enemy Spawn Portal Effect - DONE
- 0.4s fade-in with golden portal ring shrinking around enemy.
- Vertical light column fading as enemy materializes.

### 4. Tower Build Animation - DONE
- 0.3s construction glow rising from ground with colored ring.
- 4 particles rising from base.
