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
# Number of faces on Devil's Dice. Extracted from the inline `randi() % 6 + 1`
# in roll_dice so the die size lives next to DICE_MAX_USES and the DICE_OUTCOMES
# tables (also keyed 1..6) can't silently disagree with the roll range.
const DICE_SIDES := 6

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
# Raphael's heal is now range-limited rather than global. A global "always heals
# the single most-wounded enemy anywhere on the map" had zero counterplay; gating
# it to a generous radius lets the player deny heals by focusing or out-positioning
# Raphael, while still covering several path tiles (TILE_SIZE=48, so ~4 tiles).
const RAPHAEL_HEAL_RANGE := 200.0        # pixels — only enemies within this heal

# Effect durations — visual feedback timers
const FX_HIT_SPARK_DURATION := 0.2       # single-target hit spark
const FX_SOUL_HIT_DURATION := 0.32       # Soul Reaper spectral hit
const FX_DEATH_DURATION := 0.5           # enemy death burst
const FX_LUCIFER_WAVE_DURATION := 1.2    # Lucifer expanding ring
const FX_LUCIFER_HIT_DURATION := 0.4     # per-enemy Lucifer hit flash (with delay)
const FX_HADES_WAVE_DURATION := 0.6      # Hades corruption wave
const FX_DMG_NUMBER_DURATION := 0.6      # floating damage number
# Floating damage numbers are nudged horizontally by a deterministic pseudo-random
# offset so multiple hits on the same enemy don't stack into an unreadable blob.
# Extracted from the inline `fmod(dmg * 7.3, 16.0) - 8.0` in combat_hit so the
# jitter band is named/tunable and the test suite can pin the offset range.
const DMG_NUM_JITTER_FACTOR := 7.3       # dmg multiplier fed into fmod for the offset
const DMG_NUM_JITTER_SPAN := 16.0        # full pixel width of the horizontal jitter band
# Combat-hit visual placement — extracted from the inline literals in combat_hit so
# the spark size and the damage-number vertical lift are named/tunable in one place
# and the test suite can pin them rather than re-deriving the math from source.
const FX_HIT_SPARK_RADIUS := 6.0         # pixel radius of the per-hit spark burst
const DMG_NUM_Y_OFFSET := 4.0            # extra px the damage number floats above the HP bar
const DMG_NUM_DEFAULT_ENEMY_RADIUS := 8.0  # fallback enemy radius when "radius" is absent
const FX_FLASH_ON_HIT := 0.12            # white flash on enemy hit
const FX_RELIC_DURATION := 0.8           # relic pickup burst
const FX_AOE_DURATION := 0.5             # AoE splash ring

# Demonic Pact system — risky between-wave tradeoffs
const PACT_OFFER_CHANCE := 0.35          # 35% chance a pact is offered between waves
const PACT_OFFER_MIN_WAVE := 3           # pacts start appearing after this wave
# Number of towers the Infernal Forge pact's "disable_random" cost knocks out.
# Extracted from the inline `mini(2, ...)` in accept_pact so the count lives next
# to the pact data and the cost_desc text ("2 random towers disabled for 8s")
# can't silently disagree with how many are actually disabled.
const PACT_DISABLE_COUNT := 2

# Relic AoE scaling — base damage scales with wave so relics stay relevant
const RELIC_AOE_BASE_DAMAGE := 50.0
const RELIC_AOE_SCALE_PER_WAVE := 0.08   # +8% per wave

# Wave completion constants
const WAVE_BONUS_BASE_PER_WAVE := 2      # linear portion: wave * N
const WAVE_BONUS_SCALED_BASE := 30       # powHPG portion: N * reward_scale()

# Wave banner
const WAVE_BANNER_DURATION := 2.6        # seconds for wave title card

# Cleric heal tick interval — clerics heal in discrete ticks not every frame
const CLERIC_HEAL_TICK := 0.5            # seconds between heal ticks

# Boss kill bonus multiplier — boss kills grant extra sins on top of scaled reward
const BOSS_KILL_BONUS_MULT := 1.5        # 50% extra sins from bosses

# Fallen Hero pool gain per enemy killed. Extracted from the inline `add_to_hero_pool(1)`
# in combat_kill so the kill→pool rate is named and the hero-pacing math has one knob.
const HERO_POOL_PER_KILL := 1

# Flat bonus Sins for an AoE/splash kill — a small incentive to favor crowd-clear
# towers/effects. Extracted from the inline `earn(1)` literal in earn_from_kill so
# the AoE clear incentive is named and tunable in one place.
const AOE_KILL_BONUS := 1

# Relic explosion radius
const RELIC_AOE_RADIUS := 80.0           # pixel radius for Hellfire Bomb relic

# Projectile max travel distance before auto-cull
const PROJECTILE_MAX_DIST := 600.0       # pixels — tighter than screen diagonal

# Tower build animation duration — visual "rising from ground" effect
const TOWER_BUILD_DURATION := 0.3        # seconds

# Tower fire flash — how long the attack pose holds after shooting
const TOWER_FIRE_FLASH := 0.3            # seconds

# Enemy spawn fade-in duration — visual entrance effect
const ENEMY_SPAWN_DURATION := 0.4        # seconds

# Lucifer pulse hit bolt — visual lightning bolt height above enemy
const LUCIFER_BOLT_HEIGHT := 160.0       # pixels above enemy for bolt origin

# Divine Curse relic — disables the strongest tower for this many seconds
const DIVINE_CURSE_DURATION := 10.0      # seconds

# Starting economy — initial sins when a new game begins
const STARTING_SINS := 50

# Dice replenishment — how many dice are restored per completed wave
const DICE_REPLENISH_PER_WAVE := 1       # gained each wave (capped at DICE_MAX_USES)

# Pact variety — number of distinct pacts offered per random selection
const PACT_POOL_SIZE := 8                # draw from all available pacts

# Burn DoT kill credit — whether burn kills attribute to the tower that applied burn
const BURN_CREDITS_TOWER := true         # track tower kill_count for burn deaths

# Relic drop chances by enemy type — probability of dropping a Pandora's Relic
const RELIC_DROP_BOSS := 1.0             # bosses always drop
const RELIC_DROP_WAR_TITAN := 0.15       # 15% chance
const RELIC_DROP_MEDIUM := 0.05          # crusaders, clerics
const RELIC_DROP_DEFAULT := 0.03         # all other enemies
const RELIC_DROP_SPECIAL := 0.10         # zeus, sentinel, marshal, raphael

# Tower Blessing relic — damage multiplier increment for nearest tower
const TOWER_BLESSING_BUFF := 0.25        # +25% damage mult per blessing

# Wave banner animation phase timings
const WAVE_BANNER_SLIDE_IN := 0.35       # seconds to slide in from left
const WAVE_BANNER_FADE_OUT := 0.7        # seconds to fade out to right

# Overview panel dimensions
const OVERVIEW_PANEL_W := 52.0           # pixel width of tower stats panel
const OVERVIEW_PANEL_H := 30.0           # pixel height of tower stats panel

# Fast enemy speed multiplier (from Demonic Pacts or dice)
const FAST_ENEMY_SPEED_MULT := 1.3       # +30% speed when fast_enemy_waves > 0

# Guardian protection flash — brief flash when damage is blocked
const GUARDIAN_FLASH_DURATION := 0.05    # seconds

# Wave spawn delay — initial delay before first enemy of a wave
const WAVE_SPAWN_DELAY := 0.5            # seconds

# Cocytus cone visual timers
const COCYTUS_EMIT_INTERVAL := 0.12      # seconds between frost spike particles
const COCYTUS_FROST_DURATION := 0.3      # seconds frost state lasts on enemy

# Mass Corruption relic effect
const MASS_CORRUPT_SLOW := 0.3           # 30% slow from Corruption Wave relic
const MASS_CORRUPT_DURATION := 5.0       # seconds slow lasts

# Time Warp relic — slowdown factor for enemies
const TIME_WARP_SLOW_FACTOR := 0.35      # game speed multiplied by this
const TIME_WARP_DURATION := 5.0          # seconds

# Tower upgrade scaling — multipliers applied per level-up
const UPGRADE_RANGE_MULT := 1.1          # +10% range per level
const UPGRADE_SPEED_MULT := 1.15         # +15% attack speed per level
const UPGRADE_COST_SCALING := 1.5        # cost multiplier per existing level

# Hades buff default — fallback buff multiplier for non-Hades tower speed
const HADES_BUFF_DEFAULT := 1.5          # used when buff_multiplier not set

# Raphael heal beam visual duration
const FX_HEAL_BEAM_DURATION := 0.3       # seconds

# Lucifer pulse wave — visual ring expands from tower to max_r over duration
const LUCIFER_WAVE_MAX_R := 1000.0       # pixel radius of expanding ring
const LUCIFER_WAVE_SPEED := LUCIFER_WAVE_MAX_R / FX_LUCIFER_WAVE_DURATION  # ~833 px/s
const FX_LUCIFER_HIT_TIMER := 0.22       # per-enemy hit flash timer (inside wave)

# Fallen Hero pool thresholds — kills fill the pool, threshold triggers a spawn
const HERO_THRESHOLD_FIRST := 200        # kills needed for first Fallen Hero
const HERO_THRESHOLD_SECOND := 500       # kills needed for second
const HERO_THRESHOLD_BASE := 1000        # base for third+
const HERO_THRESHOLD_STEP := 500         # increment per additional hero

# Dice AoE flash durations per tier — how long enemies flash white
const DICE_AOE_FLASH_25 := 0.2           # 25% AoE: stronger flash
const DICE_AOE_FLASH_10 := 0.15          # 10% AoE: lighter flash

# Dice AoE damage fractions — % of each enemy's MAX HP dealt by the dice AoE rolls.
# Extracted from the inline 0.25 / 0.10 literals in roll_dice() for tuning clarity.
const DICE_AOE_DAMAGE_25 := 0.25         # Hellstorm (roll 5): 25% of max HP
const DICE_AOE_DAMAGE_10 := 0.10         # Small Spark (roll 3): 10% of max HP

# Dice effect parameters — extracted from roll_dice() for tuning
const DICE_SURGE_SPEED := 1.8            # Demonic Surge: +80% attack speed
const DICE_SURGE_DURATION := 15.0        # seconds Surge lasts
const DICE_SPEED_BOOST := 1.3            # Quick Hands: +30% attack speed
const DICE_SPEED_BOOST_DURATION := 10.0  # seconds Quick Hands lasts
const DICE_SLOW_FACTOR := 0.75           # Slow Curse: -25% tower speed
const DICE_SLOW_DURATION := 10.0         # seconds Slow Curse lasts
const DICE_DISABLE_DURATION := 3.0       # seconds all towers disabled (Tremor)
const DICE_TAX_PERCENT := 0.10           # Devil's Tax: lose 10% of sins
const DICE_BONUS_SMALL := 10             # Tithe: small bonus sins
const DICE_BONUS_MEDIUM := 25            # Minor Blessing: medium bonus sins
const DICE_BONUS_LARGE := 50             # Late-game Tithe: large bonus sins
const DICE_RESULT_DISPLAY := 5.0         # seconds dice result stays on screen

# Notification system
const NOTIFICATION_MAX := 6              # max simultaneous notifications
const NOTIFICATION_DURATION := 4.0       # seconds each notification lasts
const NOTIFICATION_STACK_SPACING := 20.0 # vertical px between stacked notifications
const NOTIFICATION_Y_OFFSET := 65.0      # starting y (below top bar)

# Drawing / visual layout constants — extracted from game_world.gd inline values
const DRAW_HELL_MAW_SIZE := 54.0         # pixel size of demon maw sprite
const DRAW_HERALD_SIZE := 46.0           # pixel size of heaven herald sprite
const DRAW_WALL_HEIGHT := 10             # isometric wall face height in pixels
const DRAW_PATH_FLOW_DOTS := 6           # number of flowing dots along the path
const DRAW_HEAVEN_SPARKLE_COUNT := 12    # sparkle particles in heaven zone
const DRAW_HELL_EMBER_COUNT := 7         # rising ember particles in hell zone
const DRAW_HEAVEN_MOTE_COUNT := 8        # foreground light motes in heaven
const DRAW_HELL_ASH_COUNT := 5           # foreground ash particles in hell
const DRAW_DUST_MOTE_COUNT := 6          # universal dust motes across map
const DRAW_HEAVEN_SHAFT_COUNT := 4       # vertical light shafts in heaven zone

# HUD font sizes — consistent typography scale across all UI elements
const HUD_FONT_TITLE := 24              # overlay titles (game over, victory, settings)
const HUD_FONT_SUBTITLE := 20           # sub-titles (Pandora, Pact)
const HUD_FONT_LARGE := 18              # sins display, settings title, menu button
const HUD_FONT_WAVE := 14               # wave progress label
const HUD_FONT_SECTION := 13            # section headers (TOWERS)
const HUD_FONT_BODY := 12               # stats, descriptions, labels
const HUD_FONT_SMALL := 11              # HP label, wave desc, tower button text
const HUD_FONT_TINY := 10               # speed buttons, map labels

# HUD overlay panel dimensions — standard sizes for popup/overlay panels
const OVERLAY_MENU_W := 400.0            # main menu panel
const OVERLAY_MENU_H := 340.0
const OVERLAY_RESULT_W := 400.0          # game over / victory panels
const OVERLAY_RESULT_H := 250.0
const OVERLAY_PANDORA_W := 420.0         # Pandora choice panel
const OVERLAY_PANDORA_H := 220.0
const OVERLAY_PACT_W := 440.0            # Demonic Pact panel
const OVERLAY_PACT_H := 220.0
const OVERLAY_SETTINGS_W := 360.0        # settings panel
const OVERLAY_SETTINGS_H := 440.0

# Dice result overlay
const DICE_RESULT_FADE_TIME := 0.8       # seconds over which dice overlay fades

# Lucifer spin animation during pulse cast
const LUCIFER_SPIN_DURATION := 0.3       # full 360° spin during fire_flash

# Tower slow from legacy slow_power towers
const SLOW_DEBUFF_DURATION := 2.0        # seconds slow lasts on enemy

# Tower weaken debuff from Abyssal Gambit pact
const TOWER_WEAKEN_MULT := 0.85          # -15% damage during weaken

# Michael shield dome visual duration
const FX_MICHAEL_SHIELD_DURATION := 0.8  # golden dome expansion time

# Zeus lightning bolt visual duration
const FX_ZEUS_BOLT_DURATION := 0.4       # bolt flash time

# Hades beam/curse visual durations
const FX_HADES_BEAM_DURATION := 0.5      # buff beam visual
const FX_HADES_CURSE_DURATION := 0.5     # damage curse visual

# Core hit visual effect radius
const FX_CORE_HIT_RADIUS := 10.0         # pixel radius of core damage burst

# HP bar drawing — shared by core HP bar and per-enemy HP bar
const HEALTH_BAR_LOW_THRESHOLD := 0.3    # below this ratio, bar turns red
const CORE_HP_BAR_W := 40.0              # pixel width of core HP bar on map
const CORE_HP_BAR_H := 3.0               # pixel height of core HP bar
const CORE_HP_BAR_OFFSET_Y := 20.0       # pixels below core center
const ENEMY_HP_BAR_H := 3.0              # pixel height of enemy HP bar
const ENEMY_HP_BAR_OFFSET_Y := 8.0       # pixels above enemy radius
const ENEMY_HP_BAR_PADDING := 4.0        # extra width beyond enemy diameter
const ENEMY_HP_LABEL_FONT := 8           # font size for HP text above bar

# Game over shake parameters
const GAMEOVER_SHAKE_INTENSITY := 8.0
const GAMEOVER_SHAKE_DURATION := 0.4

# Cheat mode constants
const CHEAT_SINS_AMOUNT := 99999         # Ctrl+J: sins granted
const CHEAT_SKIP_TO_WAVE := 15           # Ctrl+K: wave to skip to

# Double damage multiplier — applied when Chaos Pact or Pandora 2x is active
const DOUBLE_DAMAGE_MULT := 2.0

# Screen shake ramp — envelope fade time for shake intensity
const SHAKE_RAMP_DURATION := 0.3        # seconds over which shake intensity ramps down

# Screen shake frequency — Hz values for the sinusoidal camera shake pattern
const SHAKE_FREQ_X := 60.0              # horizontal oscillation rate
const SHAKE_FREQ_Y := 47.0              # vertical oscillation rate (offset for organic feel)
const SHAKE_Y_DAMPEN := 0.7             # vertical shake amplitude relative to horizontal

# Screen shake presets — intensity and duration for common game events
const SHAKE_CORE_HIT_INTENSITY := 4.0    # enemy reaches core
const SHAKE_CORE_HIT_DURATION := 0.2
const SHAKE_WAVE_START_INTENSITY := 2.0  # new wave begins
const SHAKE_WAVE_START_DURATION := 0.15
const SHAKE_DICE_ROLL_INTENSITY := 3.0   # dice rolled
const SHAKE_DICE_ROLL_DURATION := 0.15

# Relic pickup visual — radius of the golden burst effect
const RELIC_PICKUP_FX_RADIUS := 15.0     # pixels

# Sin Cache relic — random sins range (uniform between min and max)
const SIN_CACHE_MIN := 50               # minimum sins from Sin Cache relic
const SIN_CACHE_RANGE := 100            # random range added to min (0..99)

# Legendary Blueprint fallback — sins granted when all towers are maxed
const LEGENDARY_FALLBACK_SINS := 80     # consolation prize

# Soul Surge relic — instantly feeds the Fallen Hero pool. Synergizes with the
# kill-economy: a mid-fight drop can tip the pool over its threshold and spawn an
# allied Fallen Hero on the spot, rewarding aggressive clears.
const SOUL_SURGE_POOL := 75             # kills-equivalent added to the hero pool

# Pandora's True Gift — sins option reward
const PANDORA_SINS_REWARD := 100        # "Pandora grants N Sins!"

# Vital Surge relic — repairs Hell's Core. The reverse-morality fiction: the demon
# patches the wound the Divine Army has been carving into the Core. A defensive
# drop that rewards survival in long fights, complementing the all-offense relics.
const VITAL_SURGE_HEAL := 25            # Core HP restored (clamped to core_max_hp)

# Special enemy types — used for spawn ordering and relic drop rates.
# Bosses (is_boss=true, e.g. archangel_michael) are auto-special via
# is_special_enemy() and must NOT be duplicated here.
const SPECIAL_ENEMY_TYPES := ["archangel_marshal", "holy_sentinel", "zeus", "archangel_raphael"]

# Effect colors — inline Color literals extracted for consistency & tuning
const COLOR_FX_ZEUS_BOLT := Color(0.8, 0.9, 1.0)        # Zeus lightning bolt visual
const COLOR_FX_HEAL_BEAM := Color(0.4, 1.0, 0.5)        # Raphael heal beam/pulse
const COLOR_FX_HADES_BEAM := Color(0.7, 0.5, 1.0)       # Hades buff beam to towers
const COLOR_FX_HADES_CURSE := Color(1.0, 0.3, 0.45)     # Hades damage curse to enemies
const COLOR_FX_FROST_SPIKE := Color(0.6, 0.85, 1.0)     # Cocytus frost spike particle
const COLOR_FX_HIT_SPARK := Color(1.0, 0.7, 0.3)        # Default hit spark fallback
const COLOR_FX_AOE_SPLASH := Color(1.0, 0.47, 0.12, 0.25)  # AoE impact ring
const COLOR_FX_SCREEN_FLASH_STRONG := Color(1.0, 0.4, 0.0)  # Hellstorm 25% dice flash
const COLOR_FX_SCREEN_FLASH_WEAK := Color(1.0, 0.6, 0.2)    # Small Spark 10% dice flash

# Heal pulse visual — brief green ring on healed enemy
const FX_HEAL_PULSE_DURATION := 0.3    # seconds

# Screen flash — full-screen color overlay from dice AoE effects
const FX_SCREEN_FLASH_DURATION := 0.3  # seconds


# ═══════════════════════════════════════════════════════
# NOTIFICATION COLORS — semantic colors for game event messages
# ═══════════════════════════════════════════════════════
const COLOR_NOTIFY_GOLD := Color(1.0, 0.8, 0.0)          # wave start, relic drops, fallen hero
const COLOR_NOTIFY_SINS := Color(0.8, 0.267, 1.0)        # sins earned, wave complete
const COLOR_NOTIFY_POSITIVE := Color(0.267, 1.0, 0.267)  # positive dice, tower buffs
const COLOR_NOTIFY_NEGATIVE := Color(1.0, 0.267, 0.267)  # negative dice, trojan relics
const COLOR_NOTIFY_PACT := Color(0.8, 0.2, 0.6)          # pact offers, accepts
const COLOR_NOTIFY_NEUTRAL := Color(0.6, 0.6, 0.6)       # pact declined, time warp faded
const COLOR_NOTIFY_SELL := Color(0.667, 0.667, 0.667)     # sold tower
const COLOR_NOTIFY_DANGER := Color(0.8, 0.2, 0.2)        # tower cursed, trojan relic
const COLOR_NOTIFY_LEGENDARY := Color(1.0, 0.85, 0.0)    # legendary upgrades, pandora
const COLOR_NOTIFY_SLOW := Color(0.3, 0.6, 1.0)          # time warp active
const COLOR_NOTIFY_CORRUPT := Color(0.6, 0.2, 0.8)       # corruption wave

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
		"desc": "Buffs nearby towers, damages enemies, +15% Cocytus corruption",
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
		"corruption_mult": 1.15,  # Cocytus +15% damage to enemies in Hades range
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
	"seraph_scout": {"name": "Seraph Scout", "hp": 14.0, "speed": 80.0, "core_dmg": 3, "is_boss": false, "color": Color(1.0, 0.867, 0.267), "radius": 7.0, "sin_reward": 6, "relic_drop": RELIC_DROP_DEFAULT},
	"crusader": {"name": "Crusader", "hp": 45.0, "speed": 55.0, "core_dmg": 6, "is_boss": false, "color": Color(0.91, 0.91, 0.91), "radius": 9.0, "sin_reward": 8, "relic_drop": RELIC_DROP_MEDIUM},
	"swift_ranger": {"name": "Swift Ranger", "hp": 28.0, "speed": 130.0, "core_dmg": 5, "is_boss": false, "color": Color(0.267, 0.867, 1.0), "radius": 8.0, "sin_reward": 6, "relic_drop": RELIC_DROP_DEFAULT},
	"war_titan": {"name": "War Titan", "hp": 110.0, "speed": 38.0, "core_dmg": 14, "is_boss": false, "color": Color(1.0, 0.533, 0.267), "radius": 11.0, "sin_reward": 15, "relic_drop": RELIC_DROP_WAR_TITAN},
	"grand_paladin": {"name": "Grand Paladin", "hp": 280.0, "speed": 42.0, "core_dmg": 30, "is_boss": true, "color": Color(1.0, 0.8, 0.0), "radius": 13.0, "sin_reward": 30, "relic_drop": RELIC_DROP_BOSS},
	"temple_cleric": {"name": "Temple Cleric", "hp": 32.0, "speed": 60.0, "core_dmg": 4, "is_boss": false, "color": Color(0.533, 1.0, 0.533), "radius": 8.0, "sin_reward": 8, "heal_aura_radius": 90.0, "heal_aura_pct": 0.02, "relic_drop": RELIC_DROP_MEDIUM},
	"archangel_marshal": {"name": "Archangel Marshal", "hp": 55.0, "speed": 42.0, "core_dmg": 10, "is_boss": false, "color": Color(1.0, 0.9, 0.5), "radius": 10.0, "sin_reward": 22, "relic_drop": RELIC_DROP_SPECIAL},
	"holy_sentinel": {"name": "Holy Sentinel", "hp": 65.0, "speed": 38.0, "core_dmg": 8, "is_boss": false, "color": Color(0.6, 0.8, 1.0), "radius": 10.0, "sin_reward": 25, "relic_drop": RELIC_DROP_SPECIAL},
	"archangel_michael": {"name": "Archangel Michael", "hp": 200.0, "speed": 35.0, "core_dmg": 25, "is_boss": true, "color": Color(1.0, 0.95, 0.8), "radius": 12.0, "sin_reward": 25, "relic_drop": RELIC_DROP_BOSS},
	"zeus": {"name": "Zeus", "hp": 80.0, "speed": 45.0, "core_dmg": 12, "is_boss": false, "color": Color(0.7, 0.8, 1.0), "radius": 10.0, "sin_reward": 18, "relic_drop": RELIC_DROP_SPECIAL},
	"archangel_raphael": {"name": "Archangel Raphael", "hp": 70.0, "speed": 40.0, "core_dmg": 8, "is_boss": false, "color": Color(0.5, 0.95, 0.6), "radius": 9.0, "sin_reward": 20, "relic_drop": RELIC_DROP_SPECIAL, "heal_range": RAPHAEL_HEAL_RANGE},
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
	{"name": "Hellfire Bomb", "weight": 24, "type": "aoe", "value": 50},
	{"name": "Sin Cache", "weight": 22, "type": "random_sins", "value": 100},
	{"name": "Tower Blessing", "weight": 13, "type": "tower_buff", "value": 0.25},
	{"name": "Corruption Wave", "weight": 10, "type": "mass_corrupt", "value": 0.3},
	{"name": "Vital Surge", "weight": 8, "type": "core_heal", "value": VITAL_SURGE_HEAL},
	{"name": "Time Warp", "weight": 7, "type": "rewind", "value": 5},
	{"name": "Soul Surge", "weight": 6, "type": "soul_surge", "value": SOUL_SURGE_POOL},
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
	{"name": "Abyssal Gambit", "benefit": "free_tower", "benefit_desc": "Next tower placement is free", "cost": "tower_weaken", "cost_desc": "All towers -15% damage for 3 waves", "b_val": 1, "b_dur": 0, "c_val": 3},
	# Wrathful Bargain — the highest-tempo gamble in the pool: two full waves of
	# doubled tower damage, paid for with a steep one-time Sin tax. Reuses the
	# existing double_dmg benefit (b_val carries the wave count) and sin_tax cost
	# handlers, so no new accept_pact branch is needed. Distinct from Chaos Pact
	# (double_dmg + extra War Titans) by trading economy instead of extra threat.
	{"name": "Wrathful Bargain", "benefit": "double_dmg", "benefit_desc": "Double damage for 2 waves", "cost": "sin_tax", "cost_desc": "Lose 30% of current Sins", "b_val": 2, "b_dur": 0, "c_val": 0.30},
	# Pact of Avarice — the greed gamble. The strongest Sin-economy boost in the pool
	# (double income for a full three waves) paid for in Core HP rather than Sins, so it
	# reads as the mirror image of Blood Tithe: that pact trades a little Core (−15) for a
	# modest income bump (×1.5 / 2 waves); this trades a lot of Core (−25) for a much
	# bigger, longer bump (×2.0 / 3 waves). Reuses the existing sin_boost benefit and
	# core_dmg cost handlers, so no new accept_pact branch is needed.
	{"name": "Pact of Avarice", "benefit": "sin_boost", "benefit_desc": "Double Sin income for 3 waves", "cost": "core_dmg", "cost_desc": "Lose 25 Core HP", "b_val": 2.0, "b_dur": 3, "c_val": 25.0},
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
# Midpoint index of the path — precomputed once at load. The Holy Sentinel's
# protection check runs per enemy per tower per frame, so it shouldn't redo
# this division (and the games rules shouldn't have two definitions of "half").
var path_half: int = 0

func _ready() -> void:
	_init_path()
	_validate_wave_data()

## Assert that every enemy type referenced in WAVE_DATA exists in ENEMY_DATA.
## Catches typos at load time rather than mid-game.
func _validate_wave_data() -> void:
	for i in range(WAVE_DATA.size()):
		var wave_def: Dictionary = WAVE_DATA[i]
		for entry in wave_def["enemies"]:
			var etype: String = entry["type"]
			if not ENEMY_DATA.has(etype):
				push_error("WAVE_DATA[%d] references unknown enemy type: %s" % [i, etype])

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
	@warning_ignore("integer_division")
	path_half = path_pixels.size() / 2

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

## Returns true if this enemy type gets special spawn ordering (back-half of wave)
## and an elevated relic drop rate. Bosses are always special; this covers the
## non-boss elites that still deserve special treatment.
func is_special_enemy(enemy_type: String) -> bool:
	var edata: Dictionary = ENEMY_DATA.get(enemy_type, {})
	if edata.get("is_boss", false):
		return true
	return enemy_type in SPECIAL_ENEMY_TYPES

## Sum total damage dealt across all towers (useful for stats display).
func total_tower_damage(tower_list: Array) -> float:
	var total := 0.0
	for t in tower_list:
		total += t.get("total_damage", 0.0)
	return total

## Sum total kills across all towers (useful for stats display).
func total_tower_kills(tower_list: Array) -> int:
	var total := 0
	for t in tower_list:
		total += t.get("kill_count", 0)
	return total

## Number of defined waves. Single source of truth so callers don't reach into
## WAVE_DATA.size() directly (and so the MAX_WAVES invariant has something to test
## against — the two must agree or the victory check fires on the wrong wave).
func wave_count() -> int:
	return WAVE_DATA.size()

## Total enemies scheduled in a wave (0-based index): sum of every group's count.
## Pure data helper for "X enemies this wave" UI and wave-balance tests. Returns 0
## for an out-of-range index rather than crashing.
func wave_enemy_count(wave_index: int) -> int:
	if wave_index < 0 or wave_index >= WAVE_DATA.size():
		return 0
	var total := 0
	for entry in WAVE_DATA[wave_index]["enemies"]:
		total += int(entry["count"])
	return total

## Total Core HP a wave can inflict if EVERY enemy leaks to the Core — the sum of
## (count × that enemy's core_dmg) across the wave. This is the wave's worst-case
## "threat", a single honest danger number for the HUD/banner so the player can
## gauge how punishing a leak would be (a swarm of cheap scouts and a lone boss can
## carry very different threat even at similar head-counts). Pure data helper;
## returns 0 for an out-of-range index rather than crashing.
func wave_threat(wave_index: int) -> int:
	if wave_index < 0 or wave_index >= WAVE_DATA.size():
		return 0
	var total := 0
	for entry in WAVE_DATA[wave_index]["enemies"]:
		var edata: Dictionary = ENEMY_DATA.get(entry["type"], {})
		total += int(entry["count"]) * int(edata.get("core_dmg", 0))
	return total
