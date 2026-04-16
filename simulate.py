#!/usr/bin/env python3
"""
Hellgate Defenders — Standalone Balance Simulator

Phase 1: Compute per-wave HP budget, required DPS/tile, and theoretical coverage.
Phase 2: Simulate strategies and verify only optimized play achieves zero-leak.

Usage:
    python3 simulate.py              # full analysis + simulation
    python3 simulate.py -q           # summary only
    python3 simulate.py -s optimal   # run one strategy
    python3 simulate.py --plan       # show DPS planning spreadsheet only
"""

import math
import sys
from typing import List, Optional, Tuple

# ════════════════════════════════════════════════════════════
# TUNABLE BALANCE PARAMETERS
#   Adjust these to iterate on balance, then sync to .gd files.
# ════════════════════════════════════════════════════════════
STARTING_SINS       = 120
WAVE_BONUS_BASE     = 30      # wave bonus = round(BASE * reward_scale) + wave * MULT
WAVE_BONUS_MULT     = 2
REWARD_POW_HPG      = 0.85    # powHPG — see game_config.gd

WAVE_HP_COMPOUND    = 1.08    # x1.08 enemy HP per wave (compound growth)
WAVE_SPD_COMPOUND   = 1.015   # x1.015 speed per wave (compound growth)
SCALE_START_WAVE    = 2       # scaling kicks in after this wave
WAVE_HP_STEP_EVERY  = 5       # milestone bump every N waves
WAVE_HP_STEP_MULT   = 1.15    # extra HP multiplier per milestone step

UPGRADE_MULT        = 1.30
MAX_TOWER_LEVEL     = 3
SELL_REFUND         = 0.65
PROJECTILE_SPEED    = 280.0

# ════════════════════════════════════════════════════════════
# CONSTANTS
# ════════════════════════════════════════════════════════════
TILE_SIZE = 48
GRID_COLS = 16
GRID_ROWS = 12
CORE_MAX_HP = 100.0
MAX_WAVES = 20
DT = 0.05  # sim timestep (20 ticks/s)

# ════════════════════════════════════════════════════════════
# MAP PATH
# ════════════════════════════════════════════════════════════
MAP_PATH: List[Tuple[int, int]] = [
    (2,0),(3,0),(4,0),(5,0),(6,0),(7,0),(8,0),(9,0),
    (9,1),(9,2),
    (8,2),(7,2),(6,2),(5,2),(4,2),(3,2),(2,2),(1,2),
    (1,3),(1,4),
    (2,4),(3,4),(4,4),(5,4),(6,4),(7,4),(8,4),(9,4),(10,4),(11,4),
    (11,5),(11,6),
    (10,6),(9,6),(8,6),(7,6),(6,6),(5,6),(4,6),
    (4,7),(4,8),
    (5,8),(6,8),(7,8),(8,8),(9,8),(10,8),(11,8),(12,8),
    (12,9),(12,10),
    (11,10),(10,10),(9,10),(8,10),(7,10),
    (7,11),
]

PATH_SET = set(MAP_PATH)
PATH_PIXELS = [
    (c * TILE_SIZE + TILE_SIZE // 2, r * TILE_SIZE + TILE_SIZE // 2)
    for c, r in MAP_PATH
]
PATH_LEN_TILES = len(MAP_PATH)                       # 57 tiles
PATH_LEN_PX    = (PATH_LEN_TILES - 1) * TILE_SIZE    # ~2688 px
SPAWN_PX = (MAP_PATH[0][0] * TILE_SIZE + TILE_SIZE // 2, -TILE_SIZE // 2)
HALF_PATH = len(PATH_PIXELS) // 2

# ════════════════════════════════════════════════════════════
# TOWER DATA
# ════════════════════════════════════════════════════════════
TOWER_DATA = {
    "demon_archer": dict(
        name="ARC", damage=2.0, range=120.0, attack_speed=1.8,
        is_aoe=False, aoe_radius=0.0, slow_power=0.0,
        cost=50, upgrade_cost=40,
        is_global=False, is_support=False,
    ),
    "hellfire_mage": dict(
        name="MAG", damage=5.0, range=100.0, attack_speed=0.8,
        is_aoe=True, aoe_radius=60.0, slow_power=0.0,
        cost=90, upgrade_cost=70,
        is_global=False, is_support=False,
    ),
    "necromancer": dict(
        name="NEC", damage=2.0, range=110.0, attack_speed=1.2,
        is_aoe=False, aoe_radius=0.0, slow_power=0.0,
        cost=120, upgrade_cost=85,
        is_global=False, is_support=False,
        # REDESIGN v2: passive aura slow — any enemy in range gets -40% speed
        aura_slow=0.40,
    ),
    "lucifer": dict(
        name="LUC", damage=5.0, range=9999.0, attack_speed=0.3,
        is_aoe=False, aoe_radius=0.0, slow_power=0.0,
        cost=200, upgrade_cost=150,
        is_global=True, is_support=False,
        execute_threshold=0.15,  # REDESIGN: kills enemies <15% HP on pulse
    ),
    "hades": dict(
        name="HAD", damage=2.0, range=130.0, attack_speed=0.0,
        is_aoe=False, aoe_radius=0.0, slow_power=0.0,
        cost=160, upgrade_cost=120,
        is_global=False, is_support=True,
        buff_multiplier=1.5, buff_cooldown=5.0, buff_duration=2.0,
    ),
    "cocytus": dict(
        name="COC", damage=5.0, range=240.0, attack_speed=1.0,
        is_aoe=False, aoe_radius=0.0, slow_power=0.0,
        cost=180, upgrade_cost=130,
        is_global=False, is_support=False,
        # REDESIGN v2: bigger cone, longer reach, higher DPS — always casting
        is_beam_cone=True,
        cone_half_angle=math.radians(35.0),  # 70° total cone
    ),
}

# ════════════════════════════════════════════════════════════
# ENEMY DATA
# ════════════════════════════════════════════════════════════
ENEMY_DATA = {
    "angel_scout":     dict(hp=14.0,  speed=80.0,  core_dmg=3,  is_boss=False, sin_reward=6),
    "holy_knight":     dict(hp=45.0,  speed=55.0,  core_dmg=6,  is_boss=False, sin_reward=8),
    "divine_hunter":   dict(hp=28.0,  speed=130.0, core_dmg=5,  is_boss=False, sin_reward=6),
    "god_of_war":      dict(hp=110.0, speed=38.0,  core_dmg=14, is_boss=False, sin_reward=15),
    "paladin":         dict(hp=280.0, speed=42.0,  core_dmg=30, is_boss=True,  sin_reward=30),
    "monk":            dict(hp=32.0,  speed=60.0,  core_dmg=4,  is_boss=False, sin_reward=8),
    "archangel":       dict(hp=55.0,  speed=42.0,  core_dmg=10, is_boss=False, sin_reward=22),
    "divine_guardian": dict(hp=65.0,  speed=38.0,  core_dmg=8,  is_boss=False, sin_reward=25),
    "michael":         dict(hp=200.0, speed=35.0,  core_dmg=25, is_boss=True,  sin_reward=25),
    "zeus":            dict(hp=80.0,  speed=45.0,  core_dmg=12, is_boss=False, sin_reward=18),
    "raphael":         dict(hp=70.0,  speed=40.0,  core_dmg=8,  is_boss=False, sin_reward=20),
}

# ════════════════════════════════════════════════════════════
# WAVE DATA
# ════════════════════════════════════════════════════════════
WAVE_DATA = [
    # Early game: gentle ramp (base HP: 42->328)
    dict(enemies=[("angel_scout",3)], interval=3.0),
    dict(enemies=[("angel_scout",4),("holy_knight",1)], interval=2.0),
    dict(enemies=[("angel_scout",5),("holy_knight",2)], interval=1.3),
    dict(enemies=[("angel_scout",6),("holy_knight",2),("divine_hunter",2)], interval=1.0),
    dict(enemies=[("holy_knight",4),("divine_hunter",3),("monk",2)], interval=0.9),
    # Mid game: new abilities, steady pressure (base HP: 431->1460)
    dict(enemies=[("angel_scout",8),("holy_knight",4),("divine_hunter",3),("archangel",1)], interval=0.8),
    dict(enemies=[("holy_knight",5),("god_of_war",2),("monk",2),("archangel",1)], interval=0.8),
    dict(enemies=[("divine_hunter",7),("god_of_war",3),("monk",2),("archangel",1)], interval=0.7),
    dict(enemies=[("angel_scout",10),("holy_knight",5),("god_of_war",3),("archangel",2)], interval=0.6),
    dict(enemies=[("holy_knight",4),("god_of_war",3),("monk",2),("paladin",1),("archangel",1),("raphael",1)], interval=0.7),
    dict(enemies=[("divine_hunter",10),("god_of_war",5),("monk",3),("archangel",2),("divine_guardian",1)], interval=0.6),
    dict(enemies=[("angel_scout",14),("holy_knight",6),("divine_hunter",4),("god_of_war",4),("archangel",1),("divine_guardian",1),("zeus",1)], interval=0.5),
    dict(enemies=[("god_of_war",7),("divine_hunter",8),("monk",4),("archangel",2),("divine_guardian",1),("zeus",1)], interval=0.5),
    dict(enemies=[("holy_knight",10),("god_of_war",5),("divine_hunter",5),("archangel",2),("divine_guardian",2),("zeus",1)], interval=0.45),
    # Late game: bosses & full synergy, compound scaling does heavy lifting (base HP: 1772->2588)
    dict(enemies=[("divine_hunter",12),("god_of_war",5),("monk",3),("paladin",1),("archangel",2),("divine_guardian",2),("michael",1),("raphael",1)], interval=0.45),
    dict(enemies=[("angel_scout",18),("holy_knight",10),("divine_hunter",4),("god_of_war",5),("monk",3),("archangel",2),("divine_guardian",2),("zeus",2)], interval=0.5),
    dict(enemies=[("holy_knight",12),("god_of_war",7),("divine_hunter",8),("monk",3),("archangel",2),("divine_guardian",2),("zeus",2)], interval=0.45),
    dict(enemies=[("holy_knight",14),("god_of_war",7),("divine_hunter",8),("monk",4),("archangel",3),("divine_guardian",2),("zeus",2)], interval=0.4),
    dict(enemies=[("angel_scout",22),("holy_knight",10),("god_of_war",8),("monk",4),("archangel",2),("divine_guardian",2),("michael",1),("zeus",2),("raphael",1)], interval=0.45),
    dict(enemies=[("holy_knight",12),("god_of_war",7),("monk",4),("paladin",2),("archangel",2),("divine_guardian",2),("michael",1),("zeus",1),("raphael",1)], interval=0.35),
]


# ════════════════════════════════════════════════════════════
# HELPER: wave-based HP / speed scale factor
# ════════════════════════════════════════════════════════════
def hp_scale(wave: int) -> float:
    compound = WAVE_HP_COMPOUND ** max(0, wave - SCALE_START_WAVE)
    steps = wave // WAVE_HP_STEP_EVERY
    return compound * (WAVE_HP_STEP_MULT ** steps)

def spd_scale(wave: int) -> float:
    return WAVE_SPD_COMPOUND ** max(0, wave - SCALE_START_WAVE)

def reward_scale(wave: int) -> float:
    return hp_scale(wave) ** REWARD_POW_HPG


# ════════════════════════════════════════════════════════════
# PHASE 1 — DPS PLANNING SPREADSHEET
#
#   For each wave, compute:
#     - total HP budget (all enemies × hp_scale)
#     - average enemy speed (weighted by count)
#     - traversal time (path length / avg speed)
#     - required DPS = total_hp / traversal_time
#     - required DPS per path-tile (how much DPS each tile needs)
#     - kill income and cumulative economy
# ════════════════════════════════════════════════════════════

def wave_total_hp(wave: int) -> float:
    """Sum of all enemy HP in a wave (with wave scaling)."""
    hs = hp_scale(wave)
    total = 0.0
    for etype, count in WAVE_DATA[wave - 1]["enemies"]:
        total += ENEMY_DATA[etype]["hp"] * count * hs
    return total

def wave_total_core_dmg(wave: int) -> int:
    """Total core damage if every enemy leaks."""
    total = 0
    for etype, count in WAVE_DATA[wave - 1]["enemies"]:
        total += ENEMY_DATA[etype]["core_dmg"] * count
    return total

def wave_enemy_count(wave: int) -> int:
    return sum(c for _, c in WAVE_DATA[wave - 1]["enemies"])

def wave_avg_speed(wave: int) -> float:
    """Weighted average speed of enemies in a wave."""
    ss = spd_scale(wave)
    total_spd = 0.0
    total_count = 0
    for etype, count in WAVE_DATA[wave - 1]["enemies"]:
        total_spd += ENEMY_DATA[etype]["speed"] * ss * count
        total_count += count
    return total_spd / total_count if total_count else 1.0

def wave_kill_income(wave: int) -> int:
    """Total sin income if all enemies are killed (powHPG-scaled)."""
    total = 0.0
    rs = reward_scale(wave)
    for etype, count in WAVE_DATA[wave - 1]["enemies"]:
        total += max(1.0, round(ENEMY_DATA[etype]["sin_reward"] * rs)) * count
    return int(total)

def tower_dps(ttype: str, level: int = 1) -> float:
    d = TOWER_DATA[ttype]
    if d.get("is_support"):
        return 0.0  # Hades is support, no DPS
    dmg = d["damage"] * (UPGRADE_MULT ** (level - 1))
    aspd = d["attack_speed"] * (1.15 ** (level - 1))
    return dmg * aspd

def tower_total_cost(ttype: str, level: int = 1) -> int:
    d = TOWER_DATA[ttype]
    total = d["cost"]
    for lv in range(1, level):
        total += round(d["upgrade_cost"] * (1.5 ** (lv - 1)))
    return total

def tower_coverage(ttype: str, level: int = 1) -> int:
    """Max path-tiles a single tower can cover (best position)."""
    d = TOWER_DATA[ttype]
    if d.get("is_global"):
        return PATH_LEN_TILES  # Lucifer hits everything
    if d.get("is_support"):
        return 0  # Hades doesn't attack
    if d.get("is_beam_cone"):
        # REDESIGN: best-position × best-facing cone coverage
        cl = d["range"] * (1.1 ** (level - 1))
        ha = d["cone_half_angle"]
        best = 0
        for col in range(GRID_COLS):
            for row in range(GRID_ROWS):
                if (col, row) in PATH_SET: continue
                cx = col * TILE_SIZE + TILE_SIZE // 2
                cy = row * TILE_SIZE + TILE_SIZE // 2
                fa = _best_cone_facing(cx, cy, cl, ha)
                n = cone_path_coverage(cx, cy, cl, ha, fa)
                if n > best: best = n
        return best
    r = d["range"] * (1.1 ** (level - 1))
    best = 0
    for col in range(GRID_COLS):
        for row in range(GRID_ROWS):
            if (col, row) in PATH_SET:
                continue
            cx = col * TILE_SIZE + TILE_SIZE // 2
            cy = row * TILE_SIZE + TILE_SIZE // 2
            r2 = r * r
            n = sum(1 for px, py in PATH_PIXELS if (px-cx)**2+(py-cy)**2 <= r2)
            if n > best:
                best = n
            if n == PATH_LEN_TILES:
                break
    return best


def print_dps_plan():
    """Print the DPS planning spreadsheet."""
    print("=" * 100)
    print("  PHASE 1: DPS PLANNING SPREADSHEET")
    print("=" * 100)

    # Tower reference
    print("\n  Tower reference (DPS / coverage / cost):")
    for ttype in TOWER_DATA:
        d = TOWER_DATA[ttype]
        for lv in [1, 2, 3]:
            dps = tower_dps(ttype, lv)
            cov = tower_coverage(ttype, lv)
            cost = tower_total_cost(ttype, lv)
            # Effective DPS on path = tower_dps × (coverage / path_len)
            # This is how much HP/s the tower removes from the total wave budget
            eff = dps * cov / PATH_LEN_TILES
            print(f"    {d['name']} L{lv}: DPS={dps:5.2f}  cover={cov:2d}/{PATH_LEN_TILES} tiles"
                  f"  effDPS={eff:5.2f}  cost={cost:3d}")
    print()

    # Wave spreadsheet
    hdr = (f"  {'Wave':>4s} {'#Ene':>4s} {'TotalHP':>8s} {'Scale':>5s}"
           f" {'AvgSpd':>6s} {'Travel':>6s} {'ReqDPS':>7s} {'DPS/tile':>8s}"
           f" {'CoreDmg':>7s} {'KillInc':>7s} {'WaveInc':>7s} {'CumSins':>7s}")
    print(hdr)
    print("  " + "-" * (len(hdr) - 2))

    cum_sins = STARTING_SINS
    for w in range(1, MAX_WAVES + 1):
        thp = wave_total_hp(w)
        hs = hp_scale(w)
        ne = wave_enemy_count(w)
        avg_spd = wave_avg_speed(w)
        travel = PATH_LEN_PX / avg_spd                # seconds for avg enemy
        req_dps = thp / travel                         # DPS needed across whole path
        dps_tile = req_dps / PATH_LEN_TILES            # DPS each path-tile must provide
        cdmg = wave_total_core_dmg(w)
        ki = wave_kill_income(w)
        wb = round(WAVE_BONUS_BASE * reward_scale(w)) + w * WAVE_BONUS_MULT
        cum_sins += ki + wb

        print(f"  {w:4d} {ne:4d} {thp:8.0f} {hs:5.2f}"
              f" {avg_spd:6.1f} {travel:6.1f}s {req_dps:7.2f} {dps_tile:8.3f}"
              f" {cdmg:7d} {ki:7d} {wb:7d} {cum_sins:7d}")

    # Aura / special ability notes
    print("\n  NOTE: Archangel aura gives allies +25% speed, -25% incoming damage.")
    print("        Divine Guardian makes first-half-path enemies invulnerable.")
    print("        Michael: every 8s grants all enemies 30% damage reduction for 2s.")
    print("        Zeus: every 6s disables 1-2 nearest towers for 2s.")
    print("        Lucifer: global pulse damages ALL enemies (no range limit).")
    print("        Hades: every 5s buffs nearby towers +50% attack speed for 2s.")
    print("        Cocytus: ice spike, damage ramps 1x→1.5x→2x→3x on same target.")
    print("        Raphael: every 6s heals most damaged ally for 20% max HP.")
    print(f"        Effective DPS multiplier vs archangel waves: ×0.75")
    print(f"        Path length: {PATH_LEN_TILES} tiles = {PATH_LEN_PX} px")


# ════════════════════════════════════════════════════════════
# ENTITIES
# ════════════════════════════════════════════════════════════
_next_id = 0
def _id():
    global _next_id; _next_id += 1; return _next_id


class Tower:
    __slots__ = (
        "id","type","col","row","x","y","level",
        "damage","range","attack_speed","cooldown",
        "is_disabled","disable_timer","damage_mult",
        "slow_power","is_aoe","aoe_radius",
        "is_global","is_support",
        "is_beam_cone","facing_angle",
        "buff_multiplier","buff_cooldown","buff_duration",
        "buff_timer","buff_active_timer",
        "hades_buffed","hades_buff_timer",
    )
    def __init__(self, ttype: str, col: int, row: int):
        d = TOWER_DATA[ttype]
        self.id = _id()
        self.type = ttype
        self.col = col; self.row = row
        self.x = col * TILE_SIZE + TILE_SIZE // 2
        self.y = row * TILE_SIZE + TILE_SIZE // 2
        self.level = 1
        self.damage = d["damage"]
        self.range = d["range"]
        self.attack_speed = d["attack_speed"]
        self.cooldown = 0.0
        self.is_disabled = False
        self.disable_timer = 0.0
        self.damage_mult = 1.0
        self.slow_power = d["slow_power"]
        self.is_aoe = d["is_aoe"]
        self.aoe_radius = d["aoe_radius"]
        self.is_global = d.get("is_global", False)
        self.is_support = d.get("is_support", False)
        self.is_beam_cone = d.get("is_beam_cone", False)
        self.facing_angle = 0.0
        self.buff_multiplier = d.get("buff_multiplier", 1.0)
        self.buff_cooldown = d.get("buff_cooldown", 0.0)
        self.buff_duration = d.get("buff_duration", 0.0)
        self.buff_timer = self.buff_cooldown if self.is_support else 0.0
        self.buff_active_timer = 0.0
        self.hades_buffed = False
        self.hades_buff_timer = 0.0

    def get_upgrade_cost(self) -> int:
        return round(TOWER_DATA[self.type]["upgrade_cost"] * (1.5 ** (self.level - 1)))

    def upgrade(self) -> bool:
        if self.level >= MAX_TOWER_LEVEL:
            return False
        self.level += 1
        self.damage *= UPGRADE_MULT
        self.range *= 1.1
        self.attack_speed *= 1.15
        return True


class Enemy:
    __slots__ = (
        "id","type","hp","max_hp","speed","core_dmg",
        "is_boss","sin_reward","x","y","path_index",
        "alive","reached_core","slow_amount","slow_timer",
        "shield_buff","shield_buff_timer","ability_timer",
        "burn_stacks","burn_timer",  # REDESIGN: MAG burn DoT
    )
    def __init__(self, etype: str, wave_num: int):
        d = ENEMY_DATA[etype]
        hs = hp_scale(wave_num)
        ss = spd_scale(wave_num)
        hp = d["hp"] * hs
        spd = d["speed"] * ss
        self.id = _id()
        self.type = etype
        self.hp = hp; self.max_hp = hp
        self.speed = spd
        self.core_dmg = d["core_dmg"]
        self.is_boss = d["is_boss"]
        self.sin_reward = max(1, round(d["sin_reward"] * reward_scale(wave_num)))
        self.x = float(SPAWN_PX[0]); self.y = float(SPAWN_PX[1])
        self.path_index = 0
        self.alive = True
        self.reached_core = False
        self.slow_amount = 0.0
        self.slow_timer = 0.0
        self.shield_buff = False
        self.shield_buff_timer = 0.0
        self.ability_timer = 0.0
        self.burn_stacks = 0
        self.burn_timer = 0.0


class Projectile:
    __slots__ = ("x","y","tx","ty","damage","speed","alive",
                 "tower","target","is_aoe","aoe_radius")
    def __init__(self, tower: Tower, target: Enemy, double_dmg: bool):
        mult = 2.0 if double_dmg else 1.0
        self.x = float(tower.x); self.y = float(tower.y)
        self.target = target
        self.tx = target.x; self.ty = target.y
        self.damage = tower.damage * tower.damage_mult * mult
        self.speed = PROJECTILE_SPEED
        self.alive = True
        self.tower = tower
        self.is_aoe = tower.is_aoe
        self.aoe_radius = tower.aoe_radius


# ════════════════════════════════════════════════════════════
# GAME STATE
# ════════════════════════════════════════════════════════════
class GameState:
    def __init__(self):
        self.core_hp = CORE_MAX_HP
        self.core_max_hp = CORE_MAX_HP
        self.sins: int = STARTING_SINS
        self.wave: int = 0
        self.towers: List[Tower] = []
        self.enemies: List[Enemy] = []
        self.projectiles: List[Projectile] = []
        self.occupied: set = set()
        self.perm_speed_buff: float = 1.0
        self.double_damage: int = 0
        self.fast_enemy_waves: int = 0
        self.kills: int = 0
        self.total_leaked: int = 0
        self._cmd = False   # archangel alive cache
        self._grd = False   # guardian alive cache
        self._nec_towers: List[Tower] = []  # REDESIGN v2: NEC aura slow sources

    def is_buildable(self, col: int, row: int) -> bool:
        if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
            return False
        return (col, row) not in PATH_SET and (col, row) not in self.occupied

    def place_tower(self, ttype: str, col: int, row: int) -> Optional[Tower]:
        cost = TOWER_DATA[ttype]["cost"]
        if self.sins < cost or not self.is_buildable(col, row):
            return None
        self.sins -= cost
        t = Tower(ttype, col, row)
        if t.is_beam_cone:
            t.facing_angle = _best_cone_facing(t.x, t.y, t.range,
                                               TOWER_DATA[ttype]["cone_half_angle"])
        self.towers.append(t)
        self.occupied.add((col, row))
        return t

    def upgrade_tower(self, tower: Tower) -> bool:
        if tower.level >= MAX_TOWER_LEVEL:
            return False
        cost = tower.get_upgrade_cost()
        if self.sins < cost:
            return False
        self.sins -= cost
        tower.upgrade()
        return True

    def calc_damage(self, base_dmg: float, tower: Optional[Tower], enemy: Enemy) -> float:
        dmg = base_dmg
        if self.double_damage > 0:
            dmg *= 2.0
        if tower is not None:
            dmg *= tower.damage_mult
        if enemy.shield_buff:
            dmg *= 0.7
        if self._cmd and enemy.type != "archangel":
            dmg *= 0.75
        return max(1.0, dmg)

    def _is_guardian_protected(self, enemy: Enemy) -> bool:
        if enemy.type == "divine_guardian":
            return False
        return self._grd and enemy.path_index < HALF_PATH

    def combat_hit(self, enemy: Enemy, base_dmg: float, tower: Optional[Tower]) -> None:
        if not enemy.alive:
            return
        if self._is_guardian_protected(enemy):
            return
        dmg = self.calc_damage(base_dmg, tower, enemy)
        enemy.hp -= dmg
        if tower is not None and tower.slow_power > 0:
            enemy.slow_amount = tower.slow_power
            enemy.slow_timer = 2.0
        # REDESIGN: MAG burn — each AoE hit adds 2 stacks (cap 4), 3s refresh
        if tower is not None and tower.type == "hellfire_mage":
            enemy.burn_stacks = min(enemy.burn_stacks + 2, 4)
            enemy.burn_timer = 3.0
        if enemy.hp <= 0:
            enemy.alive = False
            self.kills += 1
            self.sins += enemy.sin_reward

    def combat_aoe(self, cx: float, cy: float, radius: float,
                   base_dmg: float, tower: Optional[Tower]) -> None:
        r2 = radius * radius
        for e in self.enemies:
            if e.alive and (e.x-cx)**2 + (e.y-cy)**2 <= r2:
                self.combat_hit(e, base_dmg, tower)

    def lucifer_pulse(self, tower: Tower) -> None:
        mult = 2.0 if self.double_damage > 0 else 1.0
        base_dmg = tower.damage * tower.damage_mult * mult
        threshold = TOWER_DATA["lucifer"].get("execute_threshold", 0.0)
        for e in self.enemies:
            if not e.alive:
                continue
            self.combat_hit(e, base_dmg, tower)
            # REDESIGN: execute — any enemy left below threshold HP dies
            if e.alive and threshold > 0 and e.hp <= e.max_hp * threshold:
                e.alive = False
                self.kills += 1
                self.sins += e.sin_reward

    def hades_buff(self, hades: Tower) -> None:
        r2 = hades.range * hades.range
        for t in self.towers:
            if t.id == hades.id or t.is_support:
                continue
            if (t.x - hades.x)**2 + (t.y - hades.y)**2 <= r2:
                t.hades_buffed = True
                t.hades_buff_timer = hades.buff_duration

    def hades_damage(self, hades: Tower) -> None:
        if hades.damage <= 0:
            return
        r2 = hades.range * hades.range
        for e in self.enemies:
            if not e.alive:
                continue
            if (e.x - hades.x)**2 + (e.y - hades.y)**2 <= r2:
                self.combat_hit(e, hades.damage, hades)

    def michael_shield(self, michael: Enemy) -> None:
        michael.ability_timer = 8.0
        for e in self.enemies:
            if e.alive and e.type != "michael":
                e.shield_buff = True
                e.shield_buff_timer = 2.0

    def zeus_lightning(self, zeus: Enemy) -> None:
        zeus.ability_timer = 6.0
        candidates = []
        for t in self.towers:
            if t.is_disabled:
                continue
            d2 = (t.x - zeus.x)**2 + (t.y - zeus.y)**2
            candidates.append((d2, t))
        candidates.sort(key=lambda x: x[0])
        for i in range(min(2, len(candidates))):
            candidates[i][1].is_disabled = True
            candidates[i][1].disable_timer = 2.0

    def raphael_heal(self, raphael: Enemy) -> None:
        raphael.ability_timer = 6.0
        best = None
        best_missing = 0.0
        for e in self.enemies:
            if not e.alive or e.type == "raphael":
                continue
            missing = e.max_hp - e.hp
            if missing > best_missing:
                best_missing = missing
                best = e
        if best is not None and best_missing > 0:
            heal = best.max_hp * 0.15
            best.hp = min(best.hp + heal, best.max_hp)

    def cocytus_beam(self, tower: Tower) -> None:
        # Target highest HP enemy in range
        best = None
        best_hp = -1.0
        r2 = tower.range * tower.range
        for e in self.enemies:
            if not e.alive:
                continue
            if (e.x - tower.x)**2 + (e.y - tower.y)**2 > r2:
                continue
            if e.hp > best_hp:
                best_hp = e.hp
                best = e
        if best is None:
            tower.beam_target_id = -1
            tower.beam_stacks = 0
            return
        # Track stacks
        if best.id != tower.beam_target_id:
            tower.beam_target_id = best.id
            tower.beam_stacks = 0
        tower.beam_stacks = min(tower.beam_stacks + 1, 3)
        stack_mult = [1.0, 1.5, 2.0, 3.0]
        mult = stack_mult[tower.beam_stacks]
        dmg_mult = 2.0 if self.double_damage > 0 else 1.0
        base_dmg = tower.damage * tower.damage_mult * dmg_mult * mult
        self.combat_hit(best, base_dmg, tower)


# ════════════════════════════════════════════════════════════
# POSITION SCORING
# ════════════════════════════════════════════════════════════
_pos_cache: dict = {}

def score_position(col: int, row: int, tower_range: float) -> int:
    key = (col, row, tower_range)
    if key in _pos_cache:
        return _pos_cache[key]
    cx = col * TILE_SIZE + TILE_SIZE // 2
    cy = row * TILE_SIZE + TILE_SIZE // 2
    r2 = tower_range * tower_range
    n = sum(1 for px, py in PATH_PIXELS if (px-cx)**2 + (py-cy)**2 <= r2)
    _pos_cache[key] = n
    return n

def _best_cone_facing(tx: float, ty: float, cone_len: float, half_angle: float) -> float:
    """Pick 8-way angle (0, π/4, ...) covering most path pixels in cone."""
    cl2 = cone_len * cone_len
    cos_half = math.cos(half_angle)
    best_ang = 0.0
    best_hits = -1
    for i in range(8):
        ang = i * math.pi / 4.0
        fx = math.cos(ang); fy = math.sin(ang)
        hits = 0
        for px, py in PATH_PIXELS:
            dx = px - tx; dy = py - ty
            d2 = dx * dx + dy * dy
            if d2 <= 1.0 or d2 > cl2:
                continue
            # cos(angle_to_enemy - facing) >= cos(half_angle)
            dot = dx * fx + dy * fy
            if dot <= 0: continue
            if dot * dot >= cos_half * cos_half * d2:
                hits += 1
        if hits > best_hits:
            best_hits = hits
            best_ang = ang
    return best_ang


def cone_path_coverage(tx: float, ty: float, cone_len: float,
                       half_angle: float, facing: float) -> int:
    cl2 = cone_len * cone_len
    cos_half = math.cos(half_angle)
    fx = math.cos(facing); fy = math.sin(facing)
    hits = 0
    for px, py in PATH_PIXELS:
        dx = px - tx; dy = py - ty
        d2 = dx * dx + dy * dy
        if d2 <= 1.0 or d2 > cl2:
            continue
        dot = dx * fx + dy * fy
        if dot <= 0: continue
        if dot * dot >= cos_half * cos_half * d2:
            hits += 1
    return hits


def ranked_positions(ttype: str, limit: int = 40) -> List[Tuple[int, int, int]]:
    r = TOWER_DATA[ttype]["range"]
    out = []
    for col in range(GRID_COLS):
        for row in range(GRID_ROWS):
            if (col, row) in PATH_SET:
                continue
            s = score_position(col, row, r)
            if s > 0:
                out.append((s, col, row))
    out.sort(key=lambda t: -t[0])
    return out[:limit]


# ════════════════════════════════════════════════════════════
# SIMULATION ENGINE
# ════════════════════════════════════════════════════════════

def simulate_wave(state: GameState, wave_num: int, strategy_fn=None) -> dict:
    state.wave = wave_num
    wdef = WAVE_DATA[wave_num - 1]

    spawn_queue: list = []
    for etype, count in wdef["enemies"]:
        spawn_queue.extend([etype] * count)
    total_enemies = len(spawn_queue)
    interval = wdef["interval"]
    spawn_timer = 0.5

    hp_before = state.core_hp
    kills_before = state.kills
    max_ticks = int(300 / DT)

    for _ in range(max_ticks):
        if strategy_fn:
            strategy_fn(state, "during_wave")

        # spawn
        spawn_timer -= DT
        if spawn_timer <= 0 and spawn_queue:
            state.enemies.append(Enemy(spawn_queue.pop(0), wave_num))
            spawn_timer = interval

        # aura caches
        state._cmd = False; state._grd = False
        for e in state.enemies:
            if not e.alive: continue
            if e.type == "archangel": state._cmd = True
            elif e.type == "divine_guardian": state._grd = True
            if state._cmd and state._grd: break
        # REDESIGN v2: NEC aura slow source cache
        state._nec_towers = [t for t in state.towers if t.type == "necromancer" and not t.is_disabled]

        # Michael / Zeus / Raphael abilities
        for e in state.enemies:
            if not e.alive: continue
            if e.type in ("michael", "zeus", "raphael"):
                e.ability_timer -= DT
                if e.ability_timer <= 0:
                    if e.type == "michael":
                        state.michael_shield(e)
                    elif e.type == "zeus":
                        state.zeus_lightning(e)
                    elif e.type == "raphael":
                        state.raphael_heal(e)

        # move enemies
        for e in state.enemies:
            if not e.alive: continue
            if e.slow_timer > 0:
                e.slow_timer -= DT
                if e.slow_timer <= 0: e.slow_amount = 0.0
            if e.shield_buff_timer > 0:
                e.shield_buff_timer -= DT
                if e.shield_buff_timer <= 0: e.shield_buff = False
            # REDESIGN: MAG burn tick — each stack 1 dmg/s
            if e.burn_stacks > 0:
                e.burn_timer -= DT
                if e.burn_timer <= 0:
                    e.burn_stacks = 0
                else:
                    e.hp -= e.burn_stacks * DT
                    if e.hp <= 0:
                        e.alive = False
                        state.kills += 1
                        state.sins += e.sin_reward
                        continue

            spd = e.speed
            if e.slow_amount > 0: spd *= (1.0 - e.slow_amount)
            # REDESIGN v2: NEC passive aura slow — any enemy in NEC range
            if state._nec_towers:
                aura = TOWER_DATA["necromancer"]["aura_slow"]
                for nt in state._nec_towers:
                    if (e.x - nt.x) ** 2 + (e.y - nt.y) ** 2 <= nt.range * nt.range:
                        spd *= (1.0 - aura)
                        break
            if state.fast_enemy_waves > 0: spd *= 1.3
            if state._cmd and e.type != "archangel": spd *= 1.25

            if e.path_index >= len(PATH_PIXELS):
                e.alive = False; e.reached_core = True
                state.core_hp = max(0.0, state.core_hp - e.core_dmg)
                state.total_leaked += 1
                if state.core_hp <= 0: break
                continue

            tx, ty = PATH_PIXELS[e.path_index]
            dx = tx - e.x; dy = ty - e.y
            dist = math.hypot(dx, dy)
            move = spd * DT
            if dist <= move:
                e.x = float(tx); e.y = float(ty)
                e.path_index += 1
            else:
                e.x += (dx / dist) * move
                e.y += (dy / dist) * move

        if state.core_hp <= 0: break

        # Decay Hades buff timers on all towers
        for t in state.towers:
            if t.hades_buffed:
                t.hades_buff_timer -= DT
                if t.hades_buff_timer <= 0:
                    t.hades_buffed = False

        # towers fire
        for t in state.towers:
            if t.is_disabled:
                t.disable_timer -= DT
                if t.disable_timer <= 0: t.is_disabled = False
                continue

            # Hades support: buff nearby towers + damage enemies every cycle
            if t.is_support:
                t.buff_timer -= DT
                if t.buff_active_timer > 0:
                    t.buff_active_timer -= DT
                if t.buff_timer <= 0:
                    t.buff_timer = t.buff_cooldown
                    t.buff_active_timer = t.buff_duration
                    state.hades_buff(t)
                    state.hades_damage(t)
                continue

            # Lucifer: global pulse
            if t.is_global:
                eff_spd = t.attack_speed * state.perm_speed_buff
                if t.hades_buffed:
                    eff_spd *= t.buff_multiplier
                t.cooldown -= DT
                if t.cooldown > 0: continue
                if not state.enemies: continue
                t.cooldown = 1.0 / eff_spd
                state.lucifer_pulse(t)
                continue

            # REDESIGN: Cocytus continuous cone — no cooldown, always burning
            if t.is_beam_cone:
                if not state.enemies: continue
                cone_dps = t.damage * t.attack_speed * state.perm_speed_buff
                if t.hades_buffed:
                    cone_dps *= t.buff_multiplier
                if state.double_damage > 0: cone_dps *= 2.0
                tick_dmg = cone_dps * DT  # damage this tick per enemy in cone
                cl2 = t.range * t.range
                half_angle = TOWER_DATA[t.type]["cone_half_angle"]
                cos_half = math.cos(half_angle)
                fx = math.cos(t.facing_angle); fy = math.sin(t.facing_angle)
                for e in state.enemies:
                    if not e.alive: continue
                    dx = e.x - t.x; dy = e.y - t.y
                    d2 = dx * dx + dy * dy
                    if d2 <= 1.0 or d2 > cl2: continue
                    dot = dx * fx + dy * fy
                    if dot <= 0: continue
                    if dot * dot < cos_half * cos_half * d2: continue
                    state.combat_hit(e, tick_dmg, t)
                continue

            t.cooldown -= DT
            if t.cooldown > 0: continue

            best = None; best_pi = -1
            r2 = t.range * t.range
            for e in state.enemies:
                if not e.alive: continue
                if (e.x - t.x)**2 + (e.y - t.y)**2 > r2: continue
                if e.path_index > best_pi:
                    best_pi = e.path_index; best = e
            if best is None: continue

            eff_spd = t.attack_speed * state.perm_speed_buff
            if t.hades_buffed:
                eff_spd *= t.buff_multiplier
            t.cooldown = 1.0 / eff_spd
            state.projectiles.append(Projectile(t, best, state.double_damage > 0))

        # move projectiles
        alive_proj = []
        for p in state.projectiles:
            if not p.alive: continue
            if p.target.alive:
                p.tx = p.target.x; p.ty = p.target.y
            dx = p.tx - p.x; dy = p.ty - p.y
            dist = math.hypot(dx, dy)
            move = p.speed * DT
            if dist <= move + 5:
                p.alive = False
                if p.is_aoe:
                    state.combat_aoe(p.tx, p.ty, p.aoe_radius, p.damage, p.tower)
                elif p.target.alive:
                    state.combat_hit(p.target, p.damage, p.tower)
            else:
                p.x += (dx / dist) * move
                p.y += (dy / dist) * move
                if dist > 800: p.alive = False
            if p.alive: alive_proj.append(p)
        state.projectiles = alive_proj

        # cleanup
        state.enemies = [e for e in state.enemies if e.alive]

        if not spawn_queue and not state.enemies: break

    killed = state.kills - kills_before
    leaked = total_enemies - killed
    core_dmg = hp_before - state.core_hp

    state.sins += round(WAVE_BONUS_BASE * reward_scale(wave_num)) + wave_num * WAVE_BONUS_MULT

    if state.double_damage > 0: state.double_damage -= 1
    if state.fast_enemy_waves > 0: state.fast_enemy_waves -= 1

    return dict(cleared=(killed == total_enemies),
                killed=killed, leaked=leaked,
                total=total_enemies, core_dmg=core_dmg)


def simulate_game(strategy_fn, name: str = "?", verbose: bool = True) -> dict:
    global _next_id; _next_id = 0
    state = GameState()

    if verbose:
        print(f"\n{'═'*72}")
        print(f"  Strategy: {name}")
        print(f"{'═'*72}")

    last_cleared = 0; final_wave = 0

    for wn in range(1, MAX_WAVES + 1):
        final_wave = wn
        strategy_fn(state, "between_waves")
        r = simulate_wave(state, wn, strategy_fn)

        if verbose:
            tag = "CLEAR" if r["cleared"] else "LEAK "
            tstr = " ".join(f"{TOWER_DATA[t.type]['name']}L{t.level}" for t in state.towers)
            print(f"  W{wn:2d} {tag} kill {r['killed']:3d}/{r['total']:<3d}"
                  f" leak {r['leaked']:2d} coreDmg {r['core_dmg']:5.1f}"
                  f" HP {state.core_hp:5.1f}/{state.core_max_hp:.0f}"
                  f" sins {state.sins:4d} [{tstr}]")
        if r["cleared"]: last_cleared = wn
        if state.core_hp <= 0:
            if verbose: print(f"  >>> GAME OVER at wave {wn}")
            break
    else:
        if verbose and state.core_hp > 0:
            print(f"  >>> VICTORY!  Core HP {state.core_hp:.1f}/{state.core_max_hp:.0f}")

    return dict(name=name, last_cleared=last_cleared, final_wave=final_wave,
                core_hp=state.core_hp, kills=state.kills,
                leaked=state.total_leaked, towers=len(state.towers), sins=state.sins)


# ════════════════════════════════════════════════════════════
# STRATEGIES
# ════════════════════════════════════════════════════════════
# ── Position helpers ──────────────────────────────────────

_ARC_POS = ranked_positions("demon_archer", 40)
_MAG_POS = ranked_positions("hellfire_mage", 30)
_NEC_POS = ranked_positions("necromancer", 30)

_coverage_cache: dict = {}

def _covered_tiles(col: int, row: int, tower_range: float) -> frozenset:
    """Return the set of path-tile indices a tower at (col,row) can reach."""
    key = (col, row, tower_range)
    if key in _coverage_cache:
        return _coverage_cache[key]
    cx = col * TILE_SIZE + TILE_SIZE // 2
    cy = row * TILE_SIZE + TILE_SIZE // 2
    r2 = tower_range * tower_range
    tiles = frozenset(
        i for i, (px, py) in enumerate(PATH_PIXELS)
        if (px - cx) ** 2 + (py - cy) ** 2 <= r2
    )
    _coverage_cache[key] = tiles
    return tiles


def _greedy_zone_positions(tower_range: float, n: int = 8) -> List[Tuple[int, int]]:
    """Pick up to *n* positions that together maximise unique path coverage.

    Each iteration selects the position that adds the most NEW tiles to the
    already-covered set, breaking ties by total tile count (prefer bends).
    """
    covered: set = set()
    result: List[Tuple[int, int]] = []
    candidates = []
    for col in range(GRID_COLS):
        for row in range(GRID_ROWS):
            if (col, row) in PATH_SET:
                continue
            tiles = _covered_tiles(col, row, tower_range)
            if tiles:
                candidates.append((col, row, tiles))

    for _ in range(n):
        best = None
        best_new = -1
        best_total = -1
        for col, row, tiles in candidates:
            new = len(tiles - covered)
            total = len(tiles)
            if new > best_new or (new == best_new and total > best_total):
                best_new = new
                best_total = total
                best = (col, row, tiles)
        if best is None or best_new == 0:
            break
        col, row, tiles = best
        result.append((col, row))
        covered |= tiles
        candidates = [(c, r, t) for c, r, t in candidates if (c, r) != (col, row)]

    return result


# Pre-compute zone positions for each tower type.
# These are ordered so that each successive position adds the most NEW
# path-tile coverage — spreading towers across different bends.
_ARC_ZONES  = _greedy_zone_positions(TOWER_DATA["demon_archer"]["range"], 8)
_MAG_ZONES  = _greedy_zone_positions(TOWER_DATA["hellfire_mage"]["range"], 6)
_NEC_ZONES  = _greedy_zone_positions(TOWER_DATA["necromancer"]["range"], 6)
_HAD_ZONES  = _greedy_zone_positions(TOWER_DATA["hades"]["range"], 10)
# Lucifer is global — any buildable tile works; pick center of map for aesthetics
_LUC_ZONES  = [(col, row) for col in range(GRID_COLS) for row in range(GRID_ROWS)
               if (col, row) not in PATH_SET][:10]
def _cone_covered_tiles(col: int, row: int) -> frozenset:
    """Tiles that best-facing cone from (col,row) can reach."""
    cx = col * TILE_SIZE + TILE_SIZE // 2
    cy = row * TILE_SIZE + TILE_SIZE // 2
    cl = TOWER_DATA["cocytus"]["range"]
    ha = TOWER_DATA["cocytus"]["cone_half_angle"]
    fa = _best_cone_facing(cx, cy, cl, ha)
    fx = math.cos(fa); fy = math.sin(fa)
    cl2 = cl * cl
    cos_half = math.cos(ha)
    tiles = set()
    for i, (px, py) in enumerate(PATH_PIXELS):
        dx = px - cx; dy = py - cy
        d2 = dx * dx + dy * dy
        if d2 <= 1.0 or d2 > cl2: continue
        dot = dx * fx + dy * fy
        if dot <= 0: continue
        if dot * dot >= cos_half * cos_half * d2:
            tiles.add(i)
    return frozenset(tiles)


def _greedy_cone_zones(n: int = 6) -> List[Tuple[int, int]]:
    covered: set = set()
    result: List[Tuple[int, int]] = []
    cands = []
    for col in range(GRID_COLS):
        for row in range(GRID_ROWS):
            if (col, row) in PATH_SET: continue
            tiles = _cone_covered_tiles(col, row)
            if tiles: cands.append((col, row, tiles))
    for _ in range(n):
        best = None; best_new = -1; best_total = -1
        for col, row, tiles in cands:
            new = len(tiles - covered); tot = len(tiles)
            if new > best_new or (new == best_new and tot > best_total):
                best_new = new; best_total = tot
                best = (col, row, tiles)
        if best is None or best_new == 0: break
        col, row, tiles = best
        result.append((col, row))
        covered |= tiles
        cands = [(c, r, t) for c, r, t in cands if (c, r) != (col, row)]
    return result


_COC_ZONES  = _greedy_cone_zones(6)


# ── Placement / upgrade helpers ───────────────────────────

def _place_best(state, ttype, positions, limit=1):
    """Place up to *limit* towers from a ranked_positions() list."""
    cost = TOWER_DATA[ttype]["cost"]
    placed = 0
    for _, c, r in positions:
        if placed >= limit or state.sins < cost:
            break
        if state.place_tower(ttype, c, r):
            placed += 1
    return placed


def _place_at_zones(state, ttype, zone_list, limit=1):
    """Place up to *limit* towers at the pre-computed zone positions.

    Positions earlier in *zone_list* add more unique coverage, so this
    naturally spreads towers across different path segments.
    """
    cost = TOWER_DATA[ttype]["cost"]
    placed = 0
    for c, r in zone_list:
        if placed >= limit or state.sins < cost:
            break
        if state.place_tower(ttype, c, r):
            placed += 1
    return placed


def _upgrade_best(state, reserve=0):
    """Upgrade towers in order of path coverage (best first)."""
    ups = 0
    cands = [(score_position(t.col, t.row, t.range), t)
             for t in state.towers if t.level < MAX_TOWER_LEVEL]
    cands.sort(key=lambda x: -x[0])
    for _, t in cands:
        if state.sins - t.get_upgrade_cost() < reserve:
            continue
        if state.upgrade_tower(t):
            ups += 1
    return ups


def _upgrade_cheapest(state, reserve=0):
    """Upgrade the cheapest-to-upgrade tower first (best DPS per sin)."""
    ups = 0
    cands = sorted(
        [t for t in state.towers if t.level < MAX_TOWER_LEVEL],
        key=lambda t: t.get_upgrade_cost(),
    )
    for t in cands:
        if state.sins - t.get_upgrade_cost() < reserve:
            continue
        if state.upgrade_tower(t):
            ups += 1
    return ups


# ── Strategy functions ────────────────────────────────────

# 1. Single ARC — wave 1 solo test
def strat_single_arc(s, ph):
    if ph == "between_waves" and not s.towers:
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 1)

# 2. Greedy ARC spam
def strat_greedy_arc(s, ph):
    if ph == "between_waves":
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 99)

# 3. No upgrades — ARC+MAG spam
def strat_no_upgrade(s, ph):
    if ph != "between_waves":
        return
    n = len(s.towers)
    if n % 3 < 2:
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 99)
    else:
        _place_at_zones(s, "hellfire_mage", _MAG_ZONES, 99)
    _place_at_zones(s, "demon_archer", _ARC_ZONES, 99)

# 4. Balanced build — spread across zones, mix types mid-game
def strat_balanced(s, ph):
    if ph != "between_waves":
        return
    w = s.wave
    if w < 3:
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 99)
    elif w < 5:
        _place_at_zones(s, "hellfire_mage", _MAG_ZONES, 1)
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 99)
    else:
        _upgrade_best(s, 50)
        if not any(t.type == "necromancer" for t in s.towers):
            _place_at_zones(s, "necromancer", _NEC_ZONES, 1)
        _place_at_zones(s, "hellfire_mage", _MAG_ZONES, 1)
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 99)

# 5. Optimal — zone-spread towers + during-wave purchasing + smart upgrades
#
#    Build plan (economy-permitting):
#      W0-W2 : ARCs at zone positions 1-3 (cheapest DPS)
#      W3-W4 : NEC for slow (critical vs bosses), upgrade ARCs
#      W5-W7 : 4th-5th ARC, MAG for AoE, Hades near cluster
#      W8+   : Lucifer for global damage, max upgrades, fill
def strat_optimal(s, ph):
    w = s.wave
    arc_n = sum(1 for t in s.towers if t.type == "demon_archer")
    mag_n = sum(1 for t in s.towers if t.type == "hellfire_mage")
    nec_n = sum(1 for t in s.towers if t.type == "necromancer")
    luc_n = sum(1 for t in s.towers if t.type == "lucifer")
    had_n = sum(1 for t in s.towers if t.type == "hades")
    coc_n = sum(1 for t in s.towers if t.type == "cocytus")

    # Phase 1: spread 3 ARCs across bends
    if arc_n < 3:
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 3 - arc_n)
        return

    # Phase 2: NEC early for slow (huge vs bosses), then upgrade ARCs
    if nec_n < 1 and s.sins >= 120:
        _place_at_zones(s, "necromancer", _NEC_ZONES, 1)
    _upgrade_cheapest(s, reserve=50)
    if arc_n < 5:
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 1)
        return

    # Phase 3: MAG for AoE burn, Hades corruption aura, Cocytus cone
    if mag_n < 1 and s.sins >= 90:
        _place_at_zones(s, "hellfire_mage", _MAG_ZONES, 1)
    _upgrade_cheapest(s, reserve=50)
    if had_n < 1 and s.sins >= 160 and w >= 6:
        _place_at_zones(s, "hades", _HAD_ZONES, 1)
    if coc_n < 1 and s.sins >= 180 and w >= 6:
        _place_at_zones(s, "cocytus", _COC_ZONES, 1)

    # Phase 4: Lucifer for global damage, max upgrades, expand
    if w >= 8:
        if luc_n < 1 and s.sins >= 200:
            _place_at_zones(s, "lucifer", _LUC_ZONES, 1)
        _upgrade_cheapest(s, reserve=0)
        if nec_n < 2 and s.sins >= 120:
            _place_at_zones(s, "necromancer", _NEC_ZONES, 1)
        if mag_n < 2 and s.sins >= 90:
            _place_at_zones(s, "hellfire_mage", _MAG_ZONES, 1)
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 99)
        _upgrade_cheapest(s, reserve=0)

# 6. Upgrade-heavy
def strat_upgrade_heavy(s, ph):
    if ph != "between_waves":
        return
    w = s.wave
    _upgrade_best(s, 0)
    if w < 2:
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 1)
    elif w == 2:
        _place_at_zones(s, "hellfire_mage", _MAG_ZONES, 1)
    elif w == 4:
        _place_at_zones(s, "necromancer", _NEC_ZONES, 1)
    elif len(s.towers) < 5:
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 1)
    elif len(s.towers) < 8:
        _place_at_zones(s, "hellfire_mage", _MAG_ZONES, 1)

# 7. Lucifer+Hades focused — test new towers
def strat_lucifer_hades(s, ph):
    w = s.wave
    arc_n = sum(1 for t in s.towers if t.type == "demon_archer")
    nec_n = sum(1 for t in s.towers if t.type == "necromancer")
    luc_n = sum(1 for t in s.towers if t.type == "lucifer")
    had_n = sum(1 for t in s.towers if t.type == "hades")

    # Phase 1: Early ARCs for base DPS
    if arc_n < 3:
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 3 - arc_n)
        return
    # Phase 2: NEC for slow, then upgrade ARCs
    if nec_n < 1 and s.sins >= 120:
        _place_at_zones(s, "necromancer", _NEC_ZONES, 1)
    _upgrade_cheapest(s, reserve=50)
    if arc_n < 5:
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 1)
        return
    # Phase 3: Lucifer + Hades
    if luc_n < 1 and s.sins >= 200:
        _place_at_zones(s, "lucifer", _LUC_ZONES, 1)
    if had_n < 1 and s.sins >= 160:
        _place_at_zones(s, "hades", _HAD_ZONES, 1)
    _upgrade_cheapest(s, reserve=0)
    _place_at_zones(s, "demon_archer", _ARC_ZONES, 99)
    if w >= 8:
        _place_at_zones(s, "hellfire_mage", _MAG_ZONES, 1)
        _upgrade_cheapest(s, reserve=0)


# ════════════════════════════════════════════════════════════
# MAIN
# ════════════════════════════════════════════════════════════
# 8. Synergy — force HAD + COC + NEC to verify redesigned abilities pull weight
def strat_synergy(s, ph):
    if ph != "between_waves":
        return
    w = s.wave
    arc_n = sum(1 for t in s.towers if t.type == "demon_archer")
    nec_n = sum(1 for t in s.towers if t.type == "necromancer")
    had_n = sum(1 for t in s.towers if t.type == "hades")
    coc_n = sum(1 for t in s.towers if t.type == "cocytus")
    mag_n = sum(1 for t in s.towers if t.type == "hellfire_mage")
    luc_n = sum(1 for t in s.towers if t.type == "lucifer")
    # Phase 1: 3 ARC anchor
    if arc_n < 3:
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 3 - arc_n)
        return
    # Phase 2: buy NEC / HAD when affordable; fall back to ARC otherwise
    if nec_n < 1 and s.sins >= 120:
        _place_at_zones(s, "necromancer", _NEC_ZONES, 1)
    if had_n < 1 and s.sins >= 160 and w >= 5:
        _place_at_zones(s, "hades", _HAD_ZONES, 1)
    if coc_n < 1 and s.sins >= 180 and w >= 5:
        _place_at_zones(s, "cocytus", _COC_ZONES, 1)
    if mag_n < 1 and s.sins >= 90 and w >= 6:
        _place_at_zones(s, "hellfire_mage", _MAG_ZONES, 1)
    if luc_n < 1 and s.sins >= 200 and w >= 8:
        _place_at_zones(s, "lucifer", _LUC_ZONES, 1)
    _upgrade_cheapest(s, reserve=80 if w < 5 else (50 if w < 8 else 0))
    # Fill with more ARC up to 5, upgrade rest
    if arc_n < 5:
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 1)
    if w >= 9:
        if coc_n < 2 and s.sins >= 180:
            _place_at_zones(s, "cocytus", _COC_ZONES, 1)
        _place_at_zones(s, "demon_archer", _ARC_ZONES, 99)
        _upgrade_cheapest(s, reserve=0)


ALL_STRATEGIES = {
    "single_arc":    (strat_single_arc,    "Single ARC (wave 1 solo)"),
    "greedy_arc":    (strat_greedy_arc,    "Greedy ARC Spam"),
    "no_upgrade":    (strat_no_upgrade,    "No Upgrades (ARC+MAG spam)"),
    "balanced":      (strat_balanced,      "Balanced Build"),
    "optimal":       (strat_optimal,       "Optimal Strategy"),
    "upgrade_heavy": (strat_upgrade_heavy, "Upgrade-Heavy (few towers)"),
    "lucifer_hades": (strat_lucifer_hades, "Lucifer+Hades Focus"),
    "synergy":       (strat_synergy,       "Synergy (NEC+HAD+COC focus)"),
}


def main():
    quiet = "-q" in sys.argv
    plan_only = "--plan" in sys.argv
    only = None
    if "-s" in sys.argv:
        idx = sys.argv.index("-s")
        if idx + 1 < len(sys.argv):
            only = sys.argv[idx + 1]

    print("Hellgate Defenders — Balance Simulator")
    print("=" * 72)

    # Always show the plan
    print_dps_plan()

    if plan_only:
        return

    print()

    if only and only not in ALL_STRATEGIES:
        print(f"Unknown strategy '{only}'. Available: {', '.join(ALL_STRATEGIES)}")
        sys.exit(1)

    to_run = [(only, ALL_STRATEGIES[only])] if only else list(ALL_STRATEGIES.items())
    results = []
    for key, (fn, label) in to_run:
        r = simulate_game(fn, label, verbose=not quiet)
        results.append(r)

    # summary
    print(f"\n{'═'*72}")
    print("  SUMMARY")
    print(f"{'═'*72}")
    hdr = f"  {'Strategy':<30s} {'Result':>7s} {'HP':>7s} {'Towers':>6s} {'Leaked':>6s} {'Kills':>5s}"
    print(hdr)
    print(f"  {'-'*30} {'-'*7} {'-'*7} {'-'*6} {'-'*6} {'-'*5}")
    for r in results:
        hp_s = f"{r['core_hp']:.0f}" if r['core_hp'] > 0 else "DEAD"
        if r['core_hp'] > 0 and r['last_cleared'] == MAX_WAVES:
            res = "WIN"
        elif r['core_hp'] <= 0:
            res = f"W{r['final_wave']}die"
        else:
            res = f"W{r['last_cleared']}+"
        print(f"  {r['name']:<30s} {res:>7s} {hp_s:>7s}"
              f" {r['towers']:>6d} {r['leaked']:>6d} {r['kills']:>5d}")

    # assertions
    print(f"\n{'═'*72}")
    print("  BALANCE ASSERTIONS")
    print(f"{'═'*72}")
    ok = True
    def check(cond, msg):
        nonlocal ok
        print(f"  {'PASS' if cond else 'FAIL'}: {msg}")
        if not cond: ok = False

    by = {r["name"]: r for r in results}

    if "Single ARC (wave 1 solo)" in by:
        r = by["Single ARC (wave 1 solo)"]
        check(r["last_cleared"] >= 1 or (r["core_hp"] > 80),
              f"Single ARC survives wave 1 (HP={r['core_hp']:.0f})")
        check(r["last_cleared"] < 5,
              f"Single ARC can't reach wave 5 (cleared {r['last_cleared']})")

    if "Greedy ARC Spam" in by:
        r = by["Greedy ARC Spam"]
        check(r["last_cleared"] < MAX_WAVES,
              f"ARC-only can't win (cleared {r['last_cleared']})")

    if "No Upgrades (ARC+MAG spam)" in by:
        r = by["No Upgrades (ARC+MAG spam)"]
        check(r["last_cleared"] < MAX_WAVES,
              f"No-upgrade spam can't win (cleared {r['last_cleared']})")

    if "Optimal Strategy" in by:
        r = by["Optimal Strategy"]
        check(r["final_wave"] >= 10,
              f"Optimal survives to wave 10+ (died at wave {r['final_wave']}, cleared {r['last_cleared']})")

    if "Balanced Build" in by and "Greedy ARC Spam" in by:
        check(by["Balanced Build"]["final_wave"] >= by["Greedy ARC Spam"]["final_wave"],
              f"Balanced >= Greedy (wave {by['Balanced Build']['final_wave']} vs {by['Greedy ARC Spam']['final_wave']})")

    if "Lucifer+Hades Focus" in by:
        r = by["Lucifer+Hades Focus"]
        check(r["last_cleared"] >= 8,
              f"Lucifer+Hades reaches wave 8+ (cleared {r['last_cleared']})")

    print()
    if ok:
        print("  All balance assertions passed.")
    else:
        print("  *** SOME ASSERTIONS FAILED ***")
    print()
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
