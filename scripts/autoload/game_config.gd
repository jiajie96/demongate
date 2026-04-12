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

const UPGRADE_MULT := 1.4
const MAX_TOWER_LEVEL := 3
const SELL_REFUND := 0.5

const PROJECTILE_SPEED := 280.0

const PACT_EVERY := 5

# ═══════════════════════════════════════════════════════
# COLORS
# ═══════════════════════════════════════════════════════
const COLOR_BG := Color(0.102, 0.039, 0.102)
const COLOR_GRID_LINE := Color(0.31, 0.16, 0.31, 0.25)
const COLOR_PATH := Color(0.239, 0.169, 0.122)
const COLOR_PATH_EDGE := Color(0.165, 0.110, 0.078)
const COLOR_GROUND := Color(0.133, 0.078, 0.133)
const COLOR_GROUND_ALT := Color(0.145, 0.082, 0.145)
const COLOR_SPAWN := Color(0.133, 0.267, 0.667)
const COLOR_CORE := Color(0.8, 0.133, 0.133)

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
# ARC: cheap starter, falls off late. BRT: boss killer.
# MAG: swarm clearer. NEC: slows enemies, force multiplier.
# ═══════════════════════════════════════════════════════
var TOWER_DATA := {
	"demon_archer": {
		"name": "Demon Archer",
		"desc": "Fast attacks, reliable early damage",
		"damage": 2.0,
		"range": 100.0,
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
		"cost": 80,
		"upgrade_cost": 60,
		"color": Color(0.6, 0.2, 0.8),
		"symbol": "MAG",
	},
	"pit_brute": {
		"name": "Pit Brute",
		"desc": "Massive hits, crushes tanks and bosses",
		"damage": 12.0,
		"range": 70.0,
		"attack_speed": 0.25,
		"is_aoe": false,
		"aoe_radius": 0.0,
		"slow_power": 0.0,
		"cost": 120,
		"upgrade_cost": 80,
		"color": Color(0.545, 0.412, 0.078),
		"symbol": "BRT",
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
		"cost": 100,
		"upgrade_cost": 70,
		"color": Color(0.2, 0.8, 0.4),
		"symbol": "NEC",
	},
}

# ═══════════════════════════════════════════════════════
# ENEMY DATA
# ═══════════════════════════════════════════════════════
var ENEMY_DATA := {
	"angel_scout": {"name": "Angel Scout", "hp": 10.0, "speed": 75.0, "core_dmg": 2, "is_boss": false, "color": Color(1.0, 0.867, 0.267), "radius": 7.0, "sin_reward": 5},
	"holy_knight": {"name": "Holy Knight", "hp": 35.0, "speed": 50.0, "core_dmg": 5, "is_boss": false, "color": Color(0.91, 0.91, 0.91), "radius": 9.0, "sin_reward": 8},
	"divine_hunter": {"name": "Divine Hunter", "hp": 20.0, "speed": 120.0, "core_dmg": 4, "is_boss": false, "color": Color(0.267, 0.867, 1.0), "radius": 8.0, "sin_reward": 6},
	"god_of_war": {"name": "God of War", "hp": 80.0, "speed": 35.0, "core_dmg": 12, "is_boss": false, "color": Color(1.0, 0.533, 0.267), "radius": 11.0, "sin_reward": 15},
	"paladin": {"name": "Paladin", "hp": 200.0, "speed": 40.0, "core_dmg": 25, "is_boss": true, "color": Color(1.0, 0.8, 0.0), "radius": 13.0, "sin_reward": 30},
	"monk": {"name": "Monk", "hp": 25.0, "speed": 55.0, "core_dmg": 3, "is_boss": false, "color": Color(0.533, 1.0, 0.533), "radius": 8.0, "sin_reward": 8},
}

# ═══════════════════════════════════════════════════════
# WAVE DATA
# ═══════════════════════════════════════════════════════
var WAVE_DATA := [
	{"enemies": [{"type": "angel_scout", "count": 5}], "interval": 1.5, "desc": "The first scouts arrive"},
	{"enemies": [{"type": "angel_scout", "count": 8}, {"type": "holy_knight", "count": 3}], "interval": 1.0, "desc": "The crusade begins"},
	{"enemies": [{"type": "angel_scout", "count": 6}, {"type": "holy_knight", "count": 5}], "interval": 0.9, "desc": "Knights join the crusade"},
	{"enemies": [{"type": "angel_scout", "count": 10}, {"type": "holy_knight", "count": 4}, {"type": "divine_hunter", "count": 2}], "interval": 0.8, "desc": "Hunters arrive - fast and deadly"},
	{"enemies": [{"type": "holy_knight", "count": 6}, {"type": "divine_hunter", "count": 5}, {"type": "monk", "count": 2}], "interval": 0.8, "desc": "Healers bolster the ranks"},
	{"enemies": [{"type": "angel_scout", "count": 12}, {"type": "holy_knight", "count": 6}, {"type": "divine_hunter", "count": 4}], "interval": 0.7, "desc": "A swarm of righteous fury"},
	{"enemies": [{"type": "holy_knight", "count": 8}, {"type": "god_of_war", "count": 3}, {"type": "monk", "count": 2}], "interval": 0.8, "desc": "The Gods of War descend"},
	{"enemies": [{"type": "divine_hunter", "count": 10}, {"type": "god_of_war", "count": 4}, {"type": "monk", "count": 3}], "interval": 0.6, "desc": "Heavy assault"},
	{"enemies": [{"type": "angel_scout", "count": 15}, {"type": "holy_knight", "count": 8}, {"type": "god_of_war", "count": 4}], "interval": 0.5, "desc": "The calm before the storm"},
	{"enemies": [{"type": "holy_knight", "count": 6}, {"type": "god_of_war", "count": 4}, {"type": "monk", "count": 3}, {"type": "paladin", "count": 1}], "interval": 0.7, "desc": "BOSS: The Paladin Champion"},
	{"enemies": [{"type": "divine_hunter", "count": 12}, {"type": "god_of_war", "count": 6}, {"type": "monk", "count": 3}], "interval": 0.5, "desc": "The divine army adapts"},
	{"enemies": [{"type": "angel_scout", "count": 20}, {"type": "holy_knight", "count": 10}, {"type": "divine_hunter", "count": 4}], "interval": 0.4, "desc": "Overwhelming numbers"},
	{"enemies": [{"type": "god_of_war", "count": 8}, {"type": "divine_hunter", "count": 10}, {"type": "monk", "count": 4}], "interval": 0.5, "desc": "Heavy hitters"},
	{"enemies": [{"type": "holy_knight", "count": 12}, {"type": "god_of_war", "count": 6}, {"type": "divine_hunter", "count": 6}], "interval": 0.4, "desc": "Armored column"},
	{"enemies": [{"type": "divine_hunter", "count": 15}, {"type": "god_of_war", "count": 6}, {"type": "monk", "count": 4}, {"type": "paladin", "count": 1}], "interval": 0.4, "desc": "BOSS: Thunder strikes"},
	{"enemies": [{"type": "angel_scout", "count": 25}, {"type": "holy_knight", "count": 12}, {"type": "divine_hunter", "count": 6}], "interval": 0.3, "desc": "The flood"},
	{"enemies": [{"type": "god_of_war", "count": 10}, {"type": "divine_hunter", "count": 12}, {"type": "monk", "count": 5}], "interval": 0.4, "desc": "Elite forces"},
	{"enemies": [{"type": "holy_knight", "count": 15}, {"type": "god_of_war", "count": 8}, {"type": "divine_hunter", "count": 10}, {"type": "monk", "count": 4}], "interval": 0.3, "desc": "Full combined arms"},
	{"enemies": [{"type": "angel_scout", "count": 30}, {"type": "god_of_war", "count": 10}, {"type": "monk", "count": 6}], "interval": 0.25, "desc": "The final onslaught"},
	{"enemies": [{"type": "holy_knight", "count": 18}, {"type": "god_of_war", "count": 10}, {"type": "monk", "count": 6}, {"type": "paladin", "count": 2}], "interval": 0.3, "desc": "BOSS: Heaven's last stand"},
]

# ═══════════════════════════════════════════════════════
# GAMBLING DATA
# ═══════════════════════════════════════════════════════
var DICE_OUTCOMES := {
	12: {"name": "HELLFIRE APOCALYPSE", "positive": true, "effect": "kill_all"},
	11: {"name": "Demonic Surge", "positive": true, "effect": "triple_speed"},
	10: {"name": "Demonic Surge", "positive": true, "effect": "triple_speed"},
	9: {"name": "Hellstorm", "positive": true, "effect": "aoe_30"},
	8: {"name": "Hellstorm", "positive": true, "effect": "aoe_30"},
	7: {"name": "Hellstorm", "positive": true, "effect": "aoe_30"},
	6: {"name": "Backfire", "positive": false, "effect": "disable_8s"},
	5: {"name": "Backfire", "positive": false, "effect": "disable_8s"},
	4: {"name": "Earthquake", "positive": false, "effect": "destroy_2"},
	3: {"name": "Earthquake", "positive": false, "effect": "destroy_2"},
	2: {"name": "DEVIL'S BETRAYAL", "positive": false, "effect": "betray"},
}

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
