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

const UPGRADE_MULT := 1.30
const MAX_TOWER_LEVEL := 3
const SELL_REFUND := 0.65

const PROJECTILE_SPEED := 280.0

const WAVE_HP_COMPOUND := 1.08   # ×1.08 enemy HP per wave (compound growth)
const WAVE_SPD_COMPOUND := 1.015 # ×1.015 speed per wave (compound growth)
const SCALE_START_WAVE := 2      # scaling kicks in after this wave
# powHPG: kill rewards & wave bonus scale with pow(hp_scale, REWARD_POW_HPG).
# 0.85 per YYZ-Productions / gamedeveloper.com TD balance research —
# income grows slower than HP, but fast enough to enable a new tower / upgrade every 1-2 waves.
const REWARD_POW_HPG := 0.85

const PACT_EVERY := 5

# ═══════════════════════════════════════════════════════
# COLORS
# ═══════════════════════════════════════════════════════
const COLOR_BG := Color(0.12, 0.04, 0.06)
const COLOR_GRID_LINE := Color(0.4, 0.2, 0.2, 0.2)
const COLOR_PATH := Color(0.28, 0.18, 0.12)
const COLOR_PATH_EDGE := Color(0.18, 0.1, 0.07)
const COLOR_GROUND := Color(0.22, 0.1, 0.12)
const COLOR_GROUND_ALT := Color(0.24, 0.11, 0.13)
const COLOR_SPAWN := Color(0.133, 0.267, 0.667)
const COLOR_CORE := Color(0.8, 0.133, 0.133)

# Heaven-side colors (for top of map gradient)
const COLOR_HEAVEN_BG := Color(0.1, 0.12, 0.25)
const COLOR_HEAVEN_GROUND := Color(0.22, 0.25, 0.36)
const COLOR_HEAVEN_GROUND_ALT := Color(0.24, 0.27, 0.38)
const COLOR_HEAVEN_PATH := Color(0.3, 0.28, 0.24)
const COLOR_HEAVEN_PATH_SURFACE := Color(0.38, 0.35, 0.3)
const COLOR_HEAVEN_PATH_EDGE := Color(0.2, 0.18, 0.15)
const COLOR_HEAVEN_HIGHLIGHT := Color(0.8, 0.88, 1.0, 0.14)
const COLOR_HEAVEN_CLIFF := Color(0.22, 0.25, 0.36, 0.5)

# Depth / highground effect colors
const COLOR_TILE_HIGHLIGHT := Color(1.0, 0.85, 0.7, 0.1)
const COLOR_TILE_SHADOW := Color(0.0, 0.0, 0.0, 0.22)
const COLOR_PATH_SURFACE := Color(0.35, 0.24, 0.16)
const COLOR_CLIFF_FACE := Color(0.28, 0.17, 0.1, 0.6)
const COLOR_LAVA_CRACK := Color(1.0, 0.5, 0.15, 0.55)
const COLOR_EMBER := Color(1.0, 0.6, 0.2, 0.45)

const COLOR_HEALTH_BG := Color(0.2, 0.2, 0.2)
const COLOR_HEALTH_HP := Color(0.2, 0.8, 0.2)
const COLOR_HEALTH_LOW := Color(0.8, 0.2, 0.2)

const COLOR_RANGE := Color(1.0, 0.39, 0.39, 0.12)
const COLOR_RANGE_BORDER := Color(1.0, 0.39, 0.39, 0.3)

const COLOR_AOE_FLASH := Color(1.0, 0.47, 0.12, 0.25)

const COLOR_PREVIEW_OK := Color(0.24, 0.86, 0.24, 0.45)
const COLOR_PREVIEW_BAD := Color(0.86, 0.24, 0.24, 0.45)

const COLOR_SINS := Color(0.85, 0.3, 1.0)

# ═══════════════════════════════════════════════════════
# TOWER DATA — each tower fills an irreplaceable role
# ARC: cheap starter DPS. MAG: swarm clearer.
# NEC: slows enemies, force multiplier.
# LUC: global damage pulse. HAD: attack speed buffer + AoE damage.
# ═══════════════════════════════════════════════════════
var TOWER_DATA := {
	"bone_marksman": {
		"name": "Bone Marksman",
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
	"inferno_warlock": {
		"name": "Inferno Warlock",
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
	"soul_reaper": {
		"name": "Soul Reaper",
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
	"hades": {
		"name": "Hades",
		"desc": "Buffs nearby towers & damages enemies in range",
		"damage": 2.0,
		"range": 130.0,
		"attack_speed": 0.0,
		"is_aoe": false,
		"aoe_radius": 0.0,
		"slow_power": 0.0,
		"cost": 160,
		"upgrade_cost": 120,
		"color": Color(0.3, 0.2, 0.9),
		"symbol": "HAD",
		"is_support": true,
		"buff_multiplier": 1.5,
		"buff_cooldown": 5.0,
		"buff_duration": 2.0,
	},
	"cocytus": {
		"name": "Cocytus",
		"desc": "Ice spike ramps damage on same target",
		"damage": 8.0,
		"range": 140.0,
		"attack_speed": 0.4,
		"is_aoe": false,
		"aoe_radius": 0.0,
		"slow_power": 0.0,
		"cost": 180,
		"upgrade_cost": 130,
		"color": Color(0.6, 0.85, 1.0),
		"symbol": "COC",
		"is_beam": true,
	},
	"lucifer": {
		"name": "Lucifer",
		"desc": "Global pulse damages ALL enemies, slow attack",
		"damage": 3.0,
		"range": 9999.0,
		"attack_speed": 0.3,
		"is_aoe": false,
		"aoe_radius": 0.0,
		"slow_power": 0.0,
		"cost": 200,
		"upgrade_cost": 150,
		"color": Color(1.0, 0.4, 0.0),
		"symbol": "LUC",
		"is_global": true,
	},
}

# ═══════════════════════════════════════════════════════
# ENEMY DATA
# ═══════════════════════════════════════════════════════
var ENEMY_DATA := {
	"seraph_scout": {"name": "Seraph Scout", "hp": 14.0, "speed": 80.0, "core_dmg": 3, "is_boss": false, "color": Color(1.0, 0.867, 0.267), "radius": 7.0, "sin_reward": 6},
	"crusader": {"name": "Crusader", "hp": 45.0, "speed": 55.0, "core_dmg": 6, "is_boss": false, "color": Color(0.91, 0.91, 0.91), "radius": 9.0, "sin_reward": 8},
	"swift_ranger": {"name": "Swift Ranger", "hp": 28.0, "speed": 130.0, "core_dmg": 5, "is_boss": false, "color": Color(0.267, 0.867, 1.0), "radius": 8.0, "sin_reward": 6},
	"war_titan": {"name": "War Titan", "hp": 110.0, "speed": 38.0, "core_dmg": 14, "is_boss": false, "color": Color(1.0, 0.533, 0.267), "radius": 11.0, "sin_reward": 15},
	"grand_paladin": {"name": "Grand Paladin", "hp": 280.0, "speed": 42.0, "core_dmg": 30, "is_boss": true, "color": Color(1.0, 0.8, 0.0), "radius": 13.0, "sin_reward": 30},
	"temple_cleric": {"name": "Temple Cleric", "hp": 32.0, "speed": 60.0, "core_dmg": 4, "is_boss": false, "color": Color(0.533, 1.0, 0.533), "radius": 8.0, "sin_reward": 8},
	"archangel_marshal": {"name": "Archangel Marshal", "hp": 55.0, "speed": 42.0, "core_dmg": 10, "is_boss": false, "color": Color(1.0, 0.9, 0.5), "radius": 10.0, "sin_reward": 22},
	"holy_sentinel": {"name": "Holy Sentinel", "hp": 65.0, "speed": 38.0, "core_dmg": 8, "is_boss": false, "color": Color(0.6, 0.8, 1.0), "radius": 10.0, "sin_reward": 25},
	"archangel_michael": {"name": "Archangel Michael", "hp": 200.0, "speed": 35.0, "core_dmg": 25, "is_boss": true, "color": Color(1.0, 0.95, 0.8), "radius": 12.0, "sin_reward": 25},
	"zeus": {"name": "Zeus", "hp": 80.0, "speed": 45.0, "core_dmg": 12, "is_boss": false, "color": Color(0.7, 0.8, 1.0), "radius": 10.0, "sin_reward": 18},
	"archangel_raphael": {"name": "Archangel Raphael", "hp": 70.0, "speed": 40.0, "core_dmg": 8, "is_boss": false, "color": Color(0.5, 0.95, 0.6), "radius": 9.0, "sin_reward": 20},
}

# ═══════════════════════════════════════════════════════
# WAVE DATA
# ═══════════════════════════════════════════════════════
var WAVE_DATA := [
	# --- Early game: gentle ramp, learn mechanics (base HP: 42→328) ---
	{"enemies": [{"type": "seraph_scout", "count": 3}], "interval": 3.0, "desc": "The first scouts arrive"},
	{"enemies": [{"type": "seraph_scout", "count": 4}, {"type": "crusader", "count": 1}], "interval": 2.0, "desc": "The crusade begins"},
	{"enemies": [{"type": "seraph_scout", "count": 5}, {"type": "crusader", "count": 2}], "interval": 1.3, "desc": "Knights join the crusade"},
	{"enemies": [{"type": "seraph_scout", "count": 6}, {"type": "crusader", "count": 2}, {"type": "swift_ranger", "count": 2}], "interval": 1.0, "desc": "Hunters arrive - fast and deadly"},
	{"enemies": [{"type": "crusader", "count": 4}, {"type": "swift_ranger", "count": 3}, {"type": "temple_cleric", "count": 2}], "interval": 0.9, "desc": "Healers bolster the ranks"},
	# --- Mid game: new abilities, steady pressure (base HP: 431→1460) ---
	{"enemies": [{"type": "seraph_scout", "count": 8}, {"type": "crusader", "count": 4}, {"type": "swift_ranger", "count": 3}, {"type": "archangel_marshal", "count": 1}], "interval": 0.8, "desc": "The Archangel takes command!"},
	{"enemies": [{"type": "crusader", "count": 5}, {"type": "war_titan", "count": 2}, {"type": "temple_cleric", "count": 2}, {"type": "archangel_marshal", "count": 1}], "interval": 0.8, "desc": "The Gods of War descend"},
	{"enemies": [{"type": "swift_ranger", "count": 7}, {"type": "war_titan", "count": 3}, {"type": "temple_cleric", "count": 2}, {"type": "archangel_marshal", "count": 1}], "interval": 0.7, "desc": "Heavy assault under command"},
	{"enemies": [{"type": "seraph_scout", "count": 10}, {"type": "crusader", "count": 5}, {"type": "war_titan", "count": 3}, {"type": "archangel_marshal", "count": 2}], "interval": 0.6, "desc": "Twin commanders rally the host"},
	{"enemies": [{"type": "crusader", "count": 4}, {"type": "war_titan", "count": 3}, {"type": "temple_cleric", "count": 2}, {"type": "grand_paladin", "count": 1}, {"type": "archangel_marshal", "count": 1}, {"type": "archangel_raphael", "count": 1}], "interval": 0.7, "desc": "BOSS: Raphael heals the Paladin!"},
	{"enemies": [{"type": "swift_ranger", "count": 10}, {"type": "war_titan", "count": 5}, {"type": "temple_cleric", "count": 3}, {"type": "archangel_marshal", "count": 2}, {"type": "holy_sentinel", "count": 1}], "interval": 0.6, "desc": "The Guardian's shield descends!"},
	{"enemies": [{"type": "seraph_scout", "count": 14}, {"type": "crusader", "count": 6}, {"type": "swift_ranger", "count": 4}, {"type": "war_titan", "count": 4}, {"type": "archangel_marshal", "count": 1}, {"type": "holy_sentinel", "count": 1}, {"type": "zeus", "count": 1}], "interval": 0.5, "desc": "Zeus strikes from the storm!"},
	{"enemies": [{"type": "war_titan", "count": 7}, {"type": "swift_ranger", "count": 8}, {"type": "temple_cleric", "count": 4}, {"type": "archangel_marshal", "count": 2}, {"type": "holy_sentinel", "count": 1}, {"type": "zeus", "count": 1}], "interval": 0.5, "desc": "Shielded heavy hitters with lightning"},
	{"enemies": [{"type": "crusader", "count": 10}, {"type": "war_titan", "count": 5}, {"type": "swift_ranger", "count": 5}, {"type": "archangel_marshal", "count": 2}, {"type": "holy_sentinel", "count": 2}, {"type": "zeus", "count": 1}], "interval": 0.45, "desc": "Armored column, double guarded"},
	# --- Late game: bosses & full synergy, compound scaling does heavy lifting (base HP: 1772→2588) ---
	{"enemies": [{"type": "swift_ranger", "count": 12}, {"type": "war_titan", "count": 5}, {"type": "temple_cleric", "count": 3}, {"type": "grand_paladin", "count": 1}, {"type": "archangel_marshal", "count": 2}, {"type": "holy_sentinel", "count": 2}, {"type": "archangel_michael", "count": 1}, {"type": "archangel_raphael", "count": 1}], "interval": 0.45, "desc": "BOSS: Michael descends with divine shield!"},
	{"enemies": [{"type": "seraph_scout", "count": 18}, {"type": "crusader", "count": 10}, {"type": "swift_ranger", "count": 4}, {"type": "war_titan", "count": 5}, {"type": "temple_cleric", "count": 3}, {"type": "archangel_marshal", "count": 2}, {"type": "holy_sentinel", "count": 2}, {"type": "zeus", "count": 2}], "interval": 0.5, "desc": "The flood, lightning and command"},
	{"enemies": [{"type": "crusader", "count": 12}, {"type": "war_titan", "count": 7}, {"type": "swift_ranger", "count": 8}, {"type": "temple_cleric", "count": 3}, {"type": "archangel_marshal", "count": 2}, {"type": "holy_sentinel", "count": 2}, {"type": "zeus", "count": 2}], "interval": 0.45, "desc": "Elite forces with Zeus support"},
	{"enemies": [{"type": "crusader", "count": 14}, {"type": "war_titan", "count": 7}, {"type": "swift_ranger", "count": 8}, {"type": "temple_cleric", "count": 4}, {"type": "archangel_marshal", "count": 3}, {"type": "holy_sentinel", "count": 2}, {"type": "zeus", "count": 2}], "interval": 0.4, "desc": "Full combined arms"},
	{"enemies": [{"type": "seraph_scout", "count": 22}, {"type": "crusader", "count": 10}, {"type": "war_titan", "count": 8}, {"type": "temple_cleric", "count": 4}, {"type": "archangel_marshal", "count": 2}, {"type": "holy_sentinel", "count": 2}, {"type": "archangel_michael", "count": 1}, {"type": "zeus", "count": 2}, {"type": "archangel_raphael", "count": 1}], "interval": 0.45, "desc": "The final onslaught — Michael leads"},
	{"enemies": [{"type": "crusader", "count": 12}, {"type": "war_titan", "count": 7}, {"type": "temple_cleric", "count": 4}, {"type": "grand_paladin", "count": 2}, {"type": "archangel_marshal", "count": 2}, {"type": "holy_sentinel", "count": 2}, {"type": "archangel_michael", "count": 1}, {"type": "zeus", "count": 1}, {"type": "archangel_raphael", "count": 1}], "interval": 0.35, "desc": "BOSS: Heaven's last stand — all heroes"},
]

# ═══════════════════════════════════════════════════════
# GAMBLING DATA
# ═══════════════════════════════════════════════════════
# Early game (waves 1-4): all outcomes are positive
var DICE_OUTCOMES_EARLY := {
	6: {"name": "Demonic Surge", "positive": true, "effect": "surge", "desc": "All towers +80% attack speed for 15s!"},
	5: {"name": "Hellstorm", "positive": true, "effect": "aoe_25", "desc": "25% damage to all enemies!"},
	4: {"name": "Quick Hands", "positive": true, "effect": "speed_boost", "desc": "All towers +30% attack speed for 10s!"},
	3: {"name": "Small Spark", "positive": true, "effect": "aoe_10", "desc": "10% damage to all enemies!"},
	2: {"name": "Minor Blessing", "positive": true, "effect": "bonus_sins", "desc": "Gained 25 bonus Sins!"},
	1: {"name": "Tithe", "positive": true, "effect": "tithe", "desc": "Gained 10 bonus Sins!"},
}

# Late game (waves 5+): clean 3-negative (rolls 1-3) / 3-positive (rolls 4-6) split
var DICE_OUTCOMES := {
	6: {"name": "Demonic Surge", "positive": true, "effect": "surge", "desc": "All towers +80% attack speed for 15s!"},
	5: {"name": "Hellstorm", "positive": true, "effect": "aoe_25", "desc": "25% damage to all enemies!"},
	4: {"name": "Tithe", "positive": true, "effect": "tithe_big", "desc": "Gained 50 bonus Sins!"},
	3: {"name": "Slow Curse", "positive": false, "effect": "slow_towers", "desc": "All towers -25% speed for 10s"},
	2: {"name": "Tremor", "positive": false, "effect": "disable_3s", "desc": "All towers disabled for 3 seconds"},
	1: {"name": "Devil's Tax", "positive": false, "effect": "tax_sins", "desc": "Lost 10% of current Sins"},
}

const DICE_NEGATIVE_WAVE := 5  # negatives start at this wave

func get_dice_outcome(total: int, current_wave: int) -> Dictionary:
	if current_wave < DICE_NEGATIVE_WAVE:
		return DICE_OUTCOMES_EARLY[total]
	return DICE_OUTCOMES[total]

var PACT_POOL := [
	{"name": "Blood Rage", "benefit": "All towers 2x damage for 3 waves", "cost_desc": "Core loses 20 HP", "b_effect": "double_dmg_3", "c_effect": "core_-20"},
	{"name": "Infernal Discount", "benefit": "Next 2 towers are free", "cost_desc": "Enemies 30% faster for 2 waves", "b_effect": "free_towers_2", "c_effect": "fast_enemy_2"},
	{"name": "Soul Harvest", "benefit": "Double sin income for 1 wave", "cost_desc": "Enemies 20% faster for 2 waves", "b_effect": "double_sins_1", "c_effect": "fast_enemy_2"},
	{"name": "Hellfire Rain", "benefit": "Instant massive AoE to all enemies", "cost_desc": "All towers disabled 10 seconds", "b_effect": "massive_aoe", "c_effect": "disable_10s"},
	{"name": "Demonic Fervor", "benefit": "All towers +30% attack speed (perm)", "cost_desc": "Core max HP reduced by 30", "b_effect": "speed_30_perm", "c_effect": "core_max_-30"},
	{"name": "Sin Amplifier", "benefit": "All sin earnings doubled for 3 waves", "cost_desc": "All current sins halved", "b_effect": "double_earn_3", "c_effect": "halve_sins"},
]

var RELIC_LOOT := [
	{"name": "Hellfire Bomb", "weight": 31, "type": "aoe", "value": 50},
	{"name": "Sin Cache", "weight": 27, "type": "random_sins", "value": 100},
	{"name": "Tower Blessing", "weight": 15, "type": "tower_buff", "value": 0.25},
	{"name": "Corruption Wave", "weight": 10, "type": "mass_corrupt", "value": 0.3},
	{"name": "Time Warp", "weight": 7, "type": "rewind", "value": 5},
	{"name": "Legendary Blueprint", "weight": 3, "type": "legendary", "value": 0},
	{"name": "Divine Curse", "weight": 3, "type": "curse", "value": 2},
	{"name": "Trojan Relic", "weight": 2, "type": "trap", "value": 2},
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
