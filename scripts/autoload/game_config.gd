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
const COCYTUS_FROST_SLOW := 0.35    # 35% slow while frosted by cone
const COCYTUS_SWEEP_SPEED := 1.5    # oscillation frequency (rad/s)
const COCYTUS_SWEEP_ANGLE := PI / 12.0  # ±15° sweep amplitude

const WAVE_HP_COMPOUND := 1.12   # ×1.12 enemy HP per wave (compound growth)
const WAVE_SPD_COMPOUND := 1.015 # ×1.015 speed per wave (compound growth)
const SCALE_START_WAVE := 2      # scaling kicks in after this wave
# Milestone bump: every N waves, HP takes extra ×M jump on top of compound.
# Makes waves 5/10/15/20 feel like real step-ups instead of a flat curve.
const WAVE_HP_STEP_EVERY := 5
const WAVE_HP_STEP_MULT := 1.25
# powHPG: kill rewards & wave bonus scale with pow(hp_scale, REWARD_POW_HPG).
# 0.85 per YYZ-Productions / gamedeveloper.com TD balance research —
# income grows slower than HP, but fast enough to enable a new tower / upgrade every 1-2 waves.
const REWARD_POW_HPG := 0.85

# Combat constants — extracted from inline magic numbers for clarity & tuning
const SHIELD_BUFF_REDUCTION := 0.7       # Michael's shield buff: 30% damage reduction
const COMMANDER_SPEED_BUFF := 1.25       # Archangel Marshal: +25% speed to allies
const COMMANDER_DAMAGE_REDUCTION := 0.75 # Archangel Marshal: 25% damage reduction
const INSURANCE_MULT := 1.5              # Leak insurance: core_dmg × 1.5 sins back
const MICHAEL_SHIELD_COOLDOWN := 8.0     # seconds between shield activations
const MICHAEL_SHIELD_DURATION := 2.0     # seconds shield buff lasts
const ZEUS_LIGHTNING_COOLDOWN := 6.0     # seconds between lightning strikes
const ZEUS_DISABLE_DURATION := 2.0       # seconds towers stay disabled
const ZEUS_MAX_TARGETS := 2              # max towers hit per lightning
const RAPHAEL_HEAL_COOLDOWN := 6.0       # seconds between heals
const RAPHAEL_HEAL_PERCENT := 0.12       # heals 12% of ally's max HP

# Effect durations — visual feedback timers
const FX_HIT_SPARK_DURATION := 0.2       # single-target hit spark
const FX_SOUL_HIT_DURATION := 0.32       # Soul Reaper spectral hit
const FX_DEATH_DURATION := 0.5           # enemy death burst
const FX_LUCIFER_WAVE_DURATION := 1.2    # Lucifer expanding ring
const FX_LUCIFER_HIT_DURATION := 0.4     # per-enemy Lucifer hit flash (with delay)
const FX_HADES_WAVE_DURATION := 0.6      # Hades corruption wave
const FX_DMG_NUMBER_DURATION := 0.6      # floating damage number
const FX_FLASH_ON_HIT := 0.12            # white flash on enemy hit
const FX_RELIC_DURATION := 0.8           # relic pickup burst
const FX_AOE_DURATION := 0.5             # AoE splash ring

# Demonic Pact system — risky between-wave tradeoffs
const PACT_OFFER_CHANCE := 0.35          # 35% chance a pact is offered between waves
const PACT_OFFER_MIN_WAVE := 3           # pacts start appearing after this wave

# Relic AoE scaling — base damage scales with wave so relics stay relevant
const RELIC_AOE_BASE_DAMAGE := 50.0
const RELIC_AOE_SCALE_PER_WAVE := 0.08   # +8% per wave


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
		"color": Color(0.95, 0.72, 0.32),
		"symbol": "ARC",
	},
	"inferno_warlock": {
		"name": "Inferno Warlock",
		"desc": "AoE blast ignites burn stacks (1 dps/stack, caps 4, 3s)",
		"damage": 5.0,
		"range": 100.0,
		"attack_speed": 0.8,
		"is_aoe": true,
		"aoe_radius": 60.0,
		"slow_power": 0.0,
		"cost": 90,
		"upgrade_cost": 70,
		"color": Color(0.6, 0.2, 0.8),
		"symbol": "MAG",
		"burn_stacks_per_hit": 2,
		"burn_stack_cap": 4,
		"burn_duration": 3.0,
		"burn_dps_per_stack": 1.0,
	},
	"soul_reaper": {
		"name": "Soul Reaper",
		"desc": "Slow aura: enemies in range move 40% slower",
		"damage": 2.0,
		"range": 110.0,
		"attack_speed": 1.2,
		"is_aoe": false,
		"aoe_radius": 0.0,
		"slow_power": 0.0,
		"cost": 120,
		"upgrade_cost": 85,
		"color": Color(0.2, 0.8, 0.4),
		"symbol": "NEC",
		"aura_slow": 0.40,
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
		"color": Color(0.72, 0.52, 1.0),
		"symbol": "HAD",
		"is_support": true,
		"buff_multiplier": 1.5,
		"buff_cooldown": 5.0,
		"buff_duration": 2.0,
	},
	"cocytus": {
		"name": "Cocytus",
		"desc": "Continuous frost cone — always casting in one direction",
		"damage": 3.5,
		"range": 240.0,
		"attack_speed": 1.0,
		"is_aoe": false,
		"aoe_radius": 0.0,
		"slow_power": 0.0,
		"cost": 180,
		"upgrade_cost": 130,
		"color": Color(0.6, 0.85, 1.0),
		"symbol": "COC",
		"is_beam_cone": true,
		"cone_half_angle": 0.6108652,  # 35° (70° total cone)
	},
	"lucifer": {
		"name": "Lucifer",
		"desc": "Global pulse, executes enemies below 15% HP",
		"damage": 5.0,
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
		"unique": true,
		"execute_threshold": 0.15,
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
	"temple_cleric": {"name": "Temple Cleric", "hp": 32.0, "speed": 60.0, "core_dmg": 4, "is_boss": false, "color": Color(0.533, 1.0, 0.533), "radius": 8.0, "sin_reward": 8, "heal_aura_radius": 90.0, "heal_aura_pct": 0.02},
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
# DEMONIC PACTS — risky between-wave tradeoffs
# ═══════════════════════════════════════════════════════
# Each pact has a benefit and a cost. The player chooses accept or decline.
var DEMONIC_PACTS := [
	{"name": "Blood Tithe", "benefit": "sin_boost", "benefit_desc": "+50% Sin income for 2 waves", "cost": "core_dmg", "cost_desc": "Lose 15 Core HP", "b_val": 1.5, "b_dur": 2, "c_val": 15.0},
	{"name": "Infernal Forge", "benefit": "tower_dmg_boost", "benefit_desc": "All towers +20% damage permanently", "cost": "disable_random", "cost_desc": "2 random towers disabled for 8s", "b_val": 0.2, "b_dur": 0, "c_val": 8.0},
	{"name": "Soul Harvest", "benefit": "flat_sins", "benefit_desc": "Gain 120 Sins instantly", "cost": "fast_enemies", "cost_desc": "Enemies +30% speed for 2 waves", "b_val": 120, "b_dur": 0, "c_val": 2},
	{"name": "Dark Resilience", "benefit": "core_heal", "benefit_desc": "Restore 20 Core HP", "cost": "sin_tax", "cost_desc": "Lose 25% of current Sins", "b_val": 20.0, "b_dur": 0, "c_val": 0.25},
	{"name": "Chaos Pact", "benefit": "double_dmg", "benefit_desc": "Double damage for 1 wave", "cost": "extra_enemies", "cost_desc": "Next wave spawns 3 extra War Titans", "b_val": 1, "b_dur": 0, "c_val": 3},
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
		var key := tile_key(cell.x, cell.y)
		path_set[key] = true
		path_pixels.append(Vector2(
			cell.x * TILE_SIZE + TILE_SIZE / 2.0,
			cell.y * TILE_SIZE + TILE_SIZE / 2.0
		))

func tile_key(col: int, row: int) -> String:
	return str(col) + "," + str(row)

func is_path(col: int, row: int) -> bool:
	return path_set.has(tile_key(col, row))

func spawn_pixel() -> Vector2:
	var first := MAP_PATH[0]
	return Vector2(first.x * TILE_SIZE + TILE_SIZE / 2.0, -TILE_SIZE / 2.0)

func grid_to_pixel(col: int, row: int) -> Vector2:
	return Vector2(col * TILE_SIZE + TILE_SIZE / 2.0, row * TILE_SIZE + TILE_SIZE / 2.0)

func pixel_to_grid(px: float, py: float) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(int(px) / TILE_SIZE, int(py) / TILE_SIZE)

# HP scale = compound growth × milestone-step bump (every WAVE_HP_STEP_EVERY waves).
func hp_scale(current_wave: int) -> float:
	var w: float = maxf(0.0, float(current_wave) - float(SCALE_START_WAVE))
	@warning_ignore("integer_division")
	var steps: int = current_wave / WAVE_HP_STEP_EVERY
	return pow(WAVE_HP_COMPOUND, w) * pow(WAVE_HP_STEP_MULT, steps)

func spd_scale(current_wave: int) -> float:
	var w: float = maxf(0.0, float(current_wave) - float(SCALE_START_WAVE))
	return pow(WAVE_SPD_COMPOUND, w)

# Reward scale follows HP but at REWARD_POW_HPG exponent — kills pay more as HP climbs,
# but slower than HP so economy never outruns difficulty.
func reward_scale(current_wave: int) -> float:
	return pow(hp_scale(current_wave), REWARD_POW_HPG)
