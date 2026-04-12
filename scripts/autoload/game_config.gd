extends Node

# ═══════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════
const TILE_SIZE := 48
const GRID_COLS := 16
const GRID_ROWS := 12
const GAME_WIDTH := TILE_SIZE * GRID_COLS   # 768
const GAME_HEIGHT := TILE_SIZE * GRID_ROWS  # 576

const CORE_MAX_HP := 100.0
const MAX_WAVES := 20
const DICE_MAX_USES := 2

const BETWEEN_WAVE_DELAY := 8.0
const FIRST_WAVE_DELAY := 3.0

const UPGRADE_MULT := 1.35
const MAX_TOWER_LEVEL := 3
const SELL_REFUND := 0.4

const PROJECTILE_SPEED := 280.0

const WAVE_HP_SCALE := 0.06    # +6% enemy HP per wave past SCALE_START
const WAVE_SPD_SCALE := 0.015  # +1.5% speed per wave past SCALE_START
const SCALE_START_WAVE := 3    # scaling kicks in after this wave

const PACT_EVERY := 5

# ═══════════════════════════════════════════════════════
# COLORS
# ═══════════════════════════════════════════════════════
const COLOR_BG := Color(0.055, 0.022, 0.055)
const COLOR_GRID_LINE := Color(0.31, 0.16, 0.31, 0.25)
const COLOR_PATH := Color(0.2, 0.14, 0.1)
const COLOR_PATH_EDGE := Color(0.13, 0.09, 0.065)
const COLOR_GROUND := Color(0.14, 0.085, 0.14)
const COLOR_GROUND_ALT := Color(0.155, 0.09, 0.15)
const COLOR_SPAWN := Color(0.133, 0.267, 0.667)
const COLOR_CORE := Color(0.8, 0.133, 0.133)

# Depth / highground effect colors
const COLOR_TILE_HIGHLIGHT := Color(1.0, 0.8, 0.65, 0.07)
const COLOR_TILE_SHADOW := Color(0.0, 0.0, 0.0, 0.22)
const COLOR_PATH_SURFACE := Color(0.24, 0.17, 0.12)
const COLOR_CLIFF_FACE := Color(0.28, 0.17, 0.1, 0.6)
const COLOR_LAVA_CRACK := Color(1.0, 0.4, 0.1, 0.45)
const COLOR_EMBER := Color(1.0, 0.5, 0.15, 0.35)

const COLOR_HEALTH_BG := Color(0.2, 0.2, 0.2)
const COLOR_HEALTH_HP := Color(0.2, 0.8, 0.2)
const COLOR_HEALTH_LOW := Color(0.8, 0.2, 0.2)

const COLOR_RANGE := Color(1.0, 0.39, 0.39, 0.12)
const COLOR_RANGE_BORDER := Color(1.0, 0.39, 0.39, 0.3)

const COLOR_AOE_FLASH := Color(1.0, 0.47, 0.12, 0.25)

const COLOR_PREVIEW_OK := Color(0.24, 0.86, 0.24, 0.45)
const COLOR_PREVIEW_BAD := Color(0.86, 0.24, 0.24, 0.45)

const COLOR_SINS := Color(0.8, 0.267, 1.0)

# ═══════════════════════════════════════════════════════
# TOWER DATA — each tower fills an irreplaceable role
# ARC: cheap starter DPS. MAG: swarm clearer.
# NEC: slows enemies, force multiplier.
# ═══════════════════════════════════════════════════════
var TOWER_DATA := {
	"demon_archer": {
		"name": "Demon Archer",
		"desc": "Fast attacks, reliable early damage",
		"damage": 2.0,
		"range": 120.0,
		"attack_speed": 1.8,
		"is_aoe": false,
		"aoe_radius": 0.0,
		"slow_power": 0.0,
		"cost": 50,
		"upgrade_cost": 40,
		"color": Color(0.8, 0.2, 0.2),
		"symbol": "ARC",
	},
	"hellfire_mage": {
		"name": "Hellfire Mage",
		"desc": "AoE blasts, essential vs swarms",
		"damage": 3.0,
		"range": 100.0,
		"attack_speed": 0.8,
		"is_aoe": true,
		"aoe_radius": 60.0,
		"slow_power": 0.0,
		"cost": 90,
		"upgrade_cost": 70,
		"color": Color(0.6, 0.2, 0.8),
		"symbol": "MAG",
	},
	"necromancer": {
		"name": "Necromancer",
		"desc": "Slows enemies on hit, force multiplier",
		"damage": 2.0,
		"range": 110.0,
		"attack_speed": 1.2,
		"is_aoe": false,
		"aoe_radius": 0.0,
		"slow_power": 0.4,
		"cost": 120,
		"upgrade_cost": 85,
		"color": Color(0.2, 0.8, 0.4),
		"symbol": "NEC",
	},
}

# ═══════════════════════════════════════════════════════
# ENEMY DATA
# ═══════════════════════════════════════════════════════
var ENEMY_DATA := {
	"angel_scout": {"name": "Angel Scout", "hp": 14.0, "speed": 80.0, "core_dmg": 3, "is_boss": false, "color": Color(1.0, 0.867, 0.267), "radius": 7.0, "sin_reward": 6},
	"holy_knight": {"name": "Holy Knight", "hp": 45.0, "speed": 55.0, "core_dmg": 6, "is_boss": false, "color": Color(0.91, 0.91, 0.91), "radius": 9.0, "sin_reward": 7},
	"divine_hunter": {"name": "Divine Hunter", "hp": 28.0, "speed": 130.0, "core_dmg": 5, "is_boss": false, "color": Color(0.267, 0.867, 1.0), "radius": 8.0, "sin_reward": 5},
	"god_of_war": {"name": "God of War", "hp": 110.0, "speed": 38.0, "core_dmg": 14, "is_boss": false, "color": Color(1.0, 0.533, 0.267), "radius": 11.0, "sin_reward": 10},
	"paladin": {"name": "Paladin", "hp": 280.0, "speed": 42.0, "core_dmg": 30, "is_boss": true, "color": Color(1.0, 0.8, 0.0), "radius": 13.0, "sin_reward": 20},
	"monk": {"name": "Monk", "hp": 32.0, "speed": 60.0, "core_dmg": 4, "is_boss": false, "color": Color(0.533, 1.0, 0.533), "radius": 8.0, "sin_reward": 5},
	"archangel": {"name": "Archangel Commander", "hp": 55.0, "speed": 42.0, "core_dmg": 10, "is_boss": false, "color": Color(1.0, 0.9, 0.5), "radius": 10.0, "sin_reward": 14},
	"divine_guardian": {"name": "Divine Guardian", "hp": 65.0, "speed": 38.0, "core_dmg": 8, "is_boss": false, "color": Color(0.6, 0.8, 1.0), "radius": 10.0, "sin_reward": 16},
}

# ═══════════════════════════════════════════════════════
# WAVE DATA
# ═══════════════════════════════════════════════════════
var WAVE_DATA := [
	{"enemies": [{"type": "angel_scout", "count": 3}], "interval": 3.0, "desc": "The first scouts arrive"},
	{"enemies": [{"type": "angel_scout", "count": 8}, {"type": "holy_knight", "count": 3}], "interval": 1.0, "desc": "The crusade begins"},
	{"enemies": [{"type": "angel_scout", "count": 6}, {"type": "holy_knight", "count": 5}], "interval": 0.9, "desc": "Knights join the crusade"},
	{"enemies": [{"type": "angel_scout", "count": 10}, {"type": "holy_knight", "count": 4}, {"type": "divine_hunter", "count": 2}], "interval": 0.8, "desc": "Hunters arrive - fast and deadly"},
	{"enemies": [{"type": "holy_knight", "count": 6}, {"type": "divine_hunter", "count": 5}, {"type": "monk", "count": 2}], "interval": 0.8, "desc": "Healers bolster the ranks"},
	{"enemies": [{"type": "angel_scout", "count": 12}, {"type": "holy_knight", "count": 6}, {"type": "divine_hunter", "count": 4}, {"type": "archangel", "count": 1}], "interval": 0.7, "desc": "The Archangel takes command!"},
	{"enemies": [{"type": "holy_knight", "count": 8}, {"type": "god_of_war", "count": 3}, {"type": "monk", "count": 2}, {"type": "archangel", "count": 1}], "interval": 0.8, "desc": "The Gods of War descend"},
	{"enemies": [{"type": "divine_hunter", "count": 10}, {"type": "god_of_war", "count": 4}, {"type": "monk", "count": 3}, {"type": "archangel", "count": 1}], "interval": 0.6, "desc": "Heavy assault under command"},
	{"enemies": [{"type": "angel_scout", "count": 15}, {"type": "holy_knight", "count": 8}, {"type": "god_of_war", "count": 4}, {"type": "archangel", "count": 2}], "interval": 0.5, "desc": "Twin commanders rally the host"},
	{"enemies": [{"type": "holy_knight", "count": 6}, {"type": "god_of_war", "count": 4}, {"type": "monk", "count": 3}, {"type": "paladin", "count": 1}, {"type": "archangel", "count": 2}], "interval": 0.7, "desc": "BOSS: Paladin with Archangel guard"},
	{"enemies": [{"type": "divine_hunter", "count": 12}, {"type": "god_of_war", "count": 6}, {"type": "monk", "count": 3}, {"type": "archangel", "count": 1}, {"type": "divine_guardian", "count": 1}], "interval": 0.5, "desc": "The Guardian's shield descends!"},
	{"enemies": [{"type": "angel_scout", "count": 20}, {"type": "holy_knight", "count": 10}, {"type": "divine_hunter", "count": 4}, {"type": "archangel", "count": 2}, {"type": "divine_guardian", "count": 1}], "interval": 0.4, "desc": "Overwhelming protected numbers"},
	{"enemies": [{"type": "god_of_war", "count": 8}, {"type": "divine_hunter", "count": 10}, {"type": "monk", "count": 4}, {"type": "archangel", "count": 2}, {"type": "divine_guardian", "count": 1}], "interval": 0.5, "desc": "Shielded heavy hitters"},
	{"enemies": [{"type": "holy_knight", "count": 12}, {"type": "god_of_war", "count": 6}, {"type": "divine_hunter", "count": 6}, {"type": "archangel", "count": 2}, {"type": "divine_guardian", "count": 2}], "interval": 0.4, "desc": "Armored column, double guarded"},
	{"enemies": [{"type": "divine_hunter", "count": 15}, {"type": "god_of_war", "count": 6}, {"type": "monk", "count": 4}, {"type": "paladin", "count": 1}, {"type": "archangel", "count": 2}, {"type": "divine_guardian", "count": 2}], "interval": 0.4, "desc": "BOSS: Thunder under divine shield"},
	{"enemies": [{"type": "angel_scout", "count": 25}, {"type": "holy_knight", "count": 12}, {"type": "divine_hunter", "count": 6}, {"type": "archangel", "count": 3}, {"type": "divine_guardian", "count": 2}], "interval": 0.3, "desc": "The flood, commanded and guarded"},
	{"enemies": [{"type": "god_of_war", "count": 10}, {"type": "divine_hunter", "count": 12}, {"type": "monk", "count": 5}, {"type": "archangel", "count": 2}, {"type": "divine_guardian", "count": 2}], "interval": 0.4, "desc": "Elite forces with full support"},
	{"enemies": [{"type": "holy_knight", "count": 15}, {"type": "god_of_war", "count": 8}, {"type": "divine_hunter", "count": 10}, {"type": "monk", "count": 4}, {"type": "archangel", "count": 3}, {"type": "divine_guardian", "count": 2}], "interval": 0.3, "desc": "Full combined arms"},
	{"enemies": [{"type": "angel_scout", "count": 30}, {"type": "god_of_war", "count": 10}, {"type": "monk", "count": 6}, {"type": "archangel", "count": 3}, {"type": "divine_guardian", "count": 3}], "interval": 0.25, "desc": "The final onslaught"},
	{"enemies": [{"type": "holy_knight", "count": 18}, {"type": "god_of_war", "count": 10}, {"type": "monk", "count": 6}, {"type": "paladin", "count": 2}, {"type": "archangel", "count": 3}, {"type": "divine_guardian", "count": 3}], "interval": 0.3, "desc": "BOSS: Heaven's last stand"},
]

# ═══════════════════════════════════════════════════════
# GAMBLING DATA
# ═══════════════════════════════════════════════════════
# Early game (waves 1-4): all outcomes are positive
var DICE_OUTCOMES_EARLY := {
	12: {"name": "HELLFIRE APOCALYPSE", "positive": true, "effect": "kill_all", "desc": "All enemies instantly destroyed!"},
	11: {"name": "Demonic Surge", "positive": true, "effect": "triple_speed", "desc": "All towers 3x attack speed for 20s!"},
	10: {"name": "Demonic Surge", "positive": true, "effect": "triple_speed", "desc": "All towers 3x attack speed for 20s!"},
	9: {"name": "Hellstorm", "positive": true, "effect": "aoe_30", "desc": "30% damage to all enemies!"},
	8: {"name": "Hellstorm", "positive": true, "effect": "aoe_30", "desc": "30% damage to all enemies!"},
	7: {"name": "Hellstorm", "positive": true, "effect": "aoe_30", "desc": "30% damage to all enemies!"},
	6: {"name": "Quick Hands", "positive": true, "effect": "speed_boost", "desc": "All towers +50% attack speed for 10s!"},
	5: {"name": "Quick Hands", "positive": true, "effect": "speed_boost", "desc": "All towers +50% attack speed for 10s!"},
	4: {"name": "Small Spark", "positive": true, "effect": "aoe_15", "desc": "15% damage to all enemies!"},
	3: {"name": "Small Spark", "positive": true, "effect": "aoe_15", "desc": "15% damage to all enemies!"},
	2: {"name": "Minor Blessing", "positive": true, "effect": "bonus_sins", "desc": "Gained 30 bonus Sins!"},
}

# Late game (waves 5+): negatives appear but are soft
var DICE_OUTCOMES := {
	12: {"name": "HELLFIRE APOCALYPSE", "positive": true, "effect": "kill_all", "desc": "All enemies instantly destroyed!"},
	11: {"name": "Demonic Surge", "positive": true, "effect": "triple_speed", "desc": "All towers 3x attack speed for 20s!"},
	10: {"name": "Demonic Surge", "positive": true, "effect": "triple_speed", "desc": "All towers 3x attack speed for 20s!"},
	9: {"name": "Hellstorm", "positive": true, "effect": "aoe_30", "desc": "30% damage to all enemies!"},
	8: {"name": "Hellstorm", "positive": true, "effect": "aoe_30", "desc": "30% damage to all enemies!"},
	7: {"name": "Hellstorm", "positive": true, "effect": "aoe_30", "desc": "30% damage to all enemies!"},
	6: {"name": "Slow Curse", "positive": false, "effect": "slow_towers", "desc": "All towers -30% speed for 10s"},
	5: {"name": "Slow Curse", "positive": false, "effect": "slow_towers", "desc": "All towers -30% speed for 10s"},
	4: {"name": "Tremor", "positive": false, "effect": "disable_3s", "desc": "All towers disabled for 3 seconds"},
	3: {"name": "Tremor", "positive": false, "effect": "disable_3s", "desc": "All towers disabled for 3 seconds"},
	2: {"name": "Devil's Tax", "positive": false, "effect": "tax_sins", "desc": "Lost 15% of current Sins"},
}

const DICE_NEGATIVE_WAVE := 5  # negatives start at this wave

func get_dice_outcome(total: int, current_wave: int) -> Dictionary:
	if current_wave < DICE_NEGATIVE_WAVE:
		return DICE_OUTCOMES_EARLY[total]
	return DICE_OUTCOMES[total]

var PACT_POOL := [
	{"name": "Blood Rage", "benefit": "All towers 2x damage for 3 waves", "cost_desc": "Core loses 20 HP", "b_effect": "double_dmg_3", "c_effect": "core_-20"},
	{"name": "Infernal Discount", "benefit": "Next 3 towers are free", "cost_desc": "Enemies 30% faster for 2 waves", "b_effect": "free_towers_3", "c_effect": "fast_enemy_2"},
	{"name": "Soul Harvest", "benefit": "Triple sin income for 1 wave", "cost_desc": "Enemies 20% faster for 2 waves", "b_effect": "triple_sins_1", "c_effect": "fast_enemy_2"},
	{"name": "Hellfire Rain", "benefit": "Instant massive AoE to all enemies", "cost_desc": "All towers disabled 10 seconds", "b_effect": "massive_aoe", "c_effect": "disable_10s"},
	{"name": "Demonic Fervor", "benefit": "All towers +50% attack speed (perm)", "cost_desc": "Core max HP reduced by 25", "b_effect": "speed_50_perm", "c_effect": "core_max_-25"},
	{"name": "Sin Amplifier", "benefit": "All sin earnings doubled for 5 waves", "cost_desc": "All current sins halved", "b_effect": "double_earn_5", "c_effect": "halve_sins"},
]

var RELIC_LOOT := [
	{"name": "Hellfire Bomb", "weight": 30, "type": "aoe", "value": 50},
	{"name": "Sin Cache", "weight": 25, "type": "random_sins", "value": 100},
	{"name": "Tower Blessing", "weight": 15, "type": "tower_buff", "value": 0.25},
	{"name": "Corruption Wave", "weight": 10, "type": "mass_corrupt", "value": 0.3},
	{"name": "Time Warp", "weight": 7, "type": "rewind", "value": 5},
	{"name": "Legendary Blueprint", "weight": 3, "type": "legendary", "value": 0},
	{"name": "Divine Curse", "weight": 5, "type": "curse", "value": 2},
	{"name": "Trojan Relic", "weight": 3, "type": "trap", "value": 2},
	{"name": "Pandora's True Gift", "weight": 2, "type": "choice", "value": 0},
]

# ═══════════════════════════════════════════════════════
# MAP PATH
# ═══════════════════════════════════════════════════════
var MAP_PATH: Array[Vector2i] = [
	Vector2i(2,0), Vector2i(3,0), Vector2i(4,0), Vector2i(5,0), Vector2i(6,0), Vector2i(7,0), Vector2i(8,0), Vector2i(9,0),
	Vector2i(9,1), Vector2i(9,2),
	Vector2i(8,2), Vector2i(7,2), Vector2i(6,2), Vector2i(5,2), Vector2i(4,2), Vector2i(3,2), Vector2i(2,2), Vector2i(1,2),
	Vector2i(1,3), Vector2i(1,4),
	Vector2i(2,4), Vector2i(3,4), Vector2i(4,4), Vector2i(5,4), Vector2i(6,4), Vector2i(7,4), Vector2i(8,4), Vector2i(9,4), Vector2i(10,4), Vector2i(11,4),
	Vector2i(11,5), Vector2i(11,6),
	Vector2i(10,6), Vector2i(9,6), Vector2i(8,6), Vector2i(7,6), Vector2i(6,6), Vector2i(5,6), Vector2i(4,6),
	Vector2i(4,7), Vector2i(4,8),
	Vector2i(5,8), Vector2i(6,8), Vector2i(7,8), Vector2i(8,8), Vector2i(9,8), Vector2i(10,8), Vector2i(11,8), Vector2i(12,8),
	Vector2i(12,9), Vector2i(12,10),
	Vector2i(11,10), Vector2i(10,10), Vector2i(9,10), Vector2i(8,10), Vector2i(7,10),
	Vector2i(7,11),
]

var path_set: Dictionary = {}
var path_pixels: Array[Vector2] = []

func _ready() -> void:
	_init_path()

func _init_path() -> void:
	path_set.clear()
	path_pixels.clear()
	for cell in MAP_PATH:
		var key := str(cell.x) + "," + str(cell.y)
		path_set[key] = true
		path_pixels.append(Vector2(
			cell.x * TILE_SIZE + TILE_SIZE / 2.0,
			cell.y * TILE_SIZE + TILE_SIZE / 2.0
		))

func is_path(col: int, row: int) -> bool:
	return path_set.has(str(col) + "," + str(row))

func spawn_pixel() -> Vector2:
	var first := MAP_PATH[0]
	return Vector2(first.x * TILE_SIZE + TILE_SIZE / 2.0, -TILE_SIZE / 2.0)

func grid_to_pixel(col: int, row: int) -> Vector2:
	return Vector2(col * TILE_SIZE + TILE_SIZE / 2.0, row * TILE_SIZE + TILE_SIZE / 2.0)

func pixel_to_grid(px: float, py: float) -> Vector2i:
	return Vector2i(int(px) / TILE_SIZE, int(py) / TILE_SIZE)
