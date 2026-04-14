extends Node

# ═══════════════════════════════════════════════════════
# CHARACTER RENDERER
# Pre-renders KayKit 3D models at 16 directional angles.
# Towers have 3 levels (each with different weapons attached to
# handslot.r / handslot.l bones); enemies have 1 level.
# Total: 11 enemies × 1 level × 1 pose × 16 angles
#      + 6 towers × 3 levels × 2 poses (idle + attack) × 16 angles
#      = 176 + 576 = 752 cached ImageTextures.
# Viewports are destroyed after capture — zero runtime GPU cost.
# ═══════════════════════════════════════════════════════

const VIEWPORT_SIZE := 128
const NUM_ANGLES := 16

# Storage: _angle_textures[type_key][level_idx][pose_idx][angle_idx].
# pose_idx: 0 = idle, 1 = attack (only present if attack_anim configured).
# Towers have 3 levels, enemies have 1.
var _angle_textures: Dictionary = {}
const POSE_IDLE := 0
const POSE_ATTACK := 1
# Storage for projectile sprites: _projectile_textures[key] = Array of angles
var _projectile_textures: Dictionary = {}
var _scene_cache: Dictionary = {}
var _is_ready := false

signal textures_ready

# ═══════════════════════════════════════════════════════
# PROJECTILE MODELS
# Standalone weapon models rendered at 16 angles for use as 2D projectile
# sprites. Arrow is rotated -90° on Z to lie horizontal (flight-ready).
# ═══════════════════════════════════════════════════════
const PROJECTILES := {
	"arrow": {
		"path": "res://assets/models/kaykit/skeletons/weapons/Skeleton_Arrow.gltf",
		"z_rot_offset": -90.0,  # lay arrow along +X axis (pointing "east" at angle 0)
	},
}

# ═══════════════════════════════════════════════════════
# CHARACTER MODEL PATHS
# ═══════════════════════════════════════════════════════
const MODELS := {
	"skeleton_warrior":    "res://assets/models/kaykit/skeletons/Skeleton_Warrior.glb",
	"skeleton_mage":       "res://assets/models/kaykit/skeletons/Skeleton_Mage.glb",
	"skeleton_rogue":      "res://assets/models/kaykit/skeletons/Skeleton_Rogue.glb",
	"skeleton_minion":     "res://assets/models/kaykit/skeletons/Skeleton_Minion.glb",
	"skeleton_necromancer":"res://assets/models/kaykit/skeletons/Necromancer.glb",
	"skeleton_golem":      "res://assets/models/kaykit/skeletons/Skeleton_Golem.glb",
	"adv_knight":          "res://assets/models/kaykit/adventurers/Knight.glb",
	"adv_barbarian":       "res://assets/models/kaykit/adventurers/Barbarian.glb",
	"adv_rogue":           "res://assets/models/kaykit/adventurers/Rogue.glb",
	"adv_rogue_hooded":    "res://assets/models/kaykit/adventurers/Rogue_Hooded.glb",
	"adv_mage":            "res://assets/models/kaykit/adventurers/Mage.glb",
}

# ═══════════════════════════════════════════════════════
# WEAPON PATHS (attached to character handslot bones)
# ═══════════════════════════════════════════════════════
const WEAPONS := {
	"axe":             "res://assets/models/kaykit/skeletons/weapons/Skeleton_Axe.gltf",
	"blade":           "res://assets/models/kaykit/skeletons/weapons/Skeleton_Blade.gltf",
	"crossbow":        "res://assets/models/kaykit/skeletons/weapons/Skeleton_Crossbow.gltf",
	"dagger":          "res://assets/models/kaykit/skeletons/weapons/Skeleton_Dagger.gltf",
	"mace":            "res://assets/models/kaykit/skeletons/weapons/Skeleton_Mace.gltf",
	"mace_large":      "res://assets/models/kaykit/skeletons/weapons/Skeleton_Mace_Large.gltf",
	"scythe":          "res://assets/models/kaykit/skeletons/weapons/Skeleton_Scythe.gltf",
	"staff":           "res://assets/models/kaykit/skeletons/weapons/Skeleton_Staff.gltf",
	"quiver":          "res://assets/models/kaykit/skeletons/weapons/Skeleton_Quiver.gltf",
	"shield_small":    "res://assets/models/kaykit/skeletons/weapons/Skeleton_Shield_Small_A.gltf",
	"shield_large":    "res://assets/models/kaykit/skeletons/weapons/Skeleton_Shield_Large_A.gltf",
	"golem_axe":       "res://assets/models/kaykit/skeletons/weapons/Skeleton_Golem_Axe.gltf",
	"golem_axe_large": "res://assets/models/kaykit/skeletons/weapons/Skeleton_Golem_Axe_Large.gltf",
	# Adventurer weapons (holy-side enemies)
	"adv_sword":           "res://assets/models/kaykit/adventurers/weapons/sword_1handed.gltf",
	"adv_sword_2h":        "res://assets/models/kaykit/adventurers/weapons/sword_2handed.gltf",
	"adv_sword_2h_color":  "res://assets/models/kaykit/adventurers/weapons/sword_2handed_color.gltf",
	"adv_axe_2h":          "res://assets/models/kaykit/adventurers/weapons/axe_2handed.gltf",
	"adv_crossbow":        "res://assets/models/kaykit/adventurers/weapons/crossbow_1handed.gltf",
	"adv_dagger":          "res://assets/models/kaykit/adventurers/weapons/dagger.gltf",
	"adv_staff":           "res://assets/models/kaykit/adventurers/weapons/staff.gltf",
	"adv_spellbook":       "res://assets/models/kaykit/adventurers/weapons/spellbook_open.gltf",
	"adv_shield_round":    "res://assets/models/kaykit/adventurers/weapons/shield_round.gltf",
	"adv_shield_round_color": "res://assets/models/kaykit/adventurers/weapons/shield_round_color.gltf",
	"adv_shield_badge":    "res://assets/models/kaykit/adventurers/weapons/shield_badge.gltf",
	"adv_shield_badge_color": "res://assets/models/kaykit/adventurers/weapons/shield_badge_color.gltf",
	"adv_shield_spikes_color": "res://assets/models/kaykit/adventurers/weapons/shield_spikes_color.gltf",
}

# ═══════════════════════════════════════════════════════
# CHARACTER CONFIG
# Each entry: one or more "level" variants.
# Level variant = {model, tint, draw_scale, main (weapon), off (offhand weapon)}
# Enemies have a single level; towers have 3.
# ═══════════════════════════════════════════════════════
var CHARACTERS := {
	# ─── TOWERS (demon side — each with 3-level progression) ───
	# Level progression is conveyed entirely via attack VFX (see particle_spawner.gd).
	# Sprite identical across Lv1/Lv2/Lv3 — same model/weapon/color/size.
	# Tints are deliberately subtle (all channels ≥ 0.78) — a hint of signature
	# hue over the natural skeleton texture, never an aggressive color swap.
	# Every tower is a skeleton model (no adventurers — adventurers are reserved
	# for holy-side enemies).
	"bone_marksman": [
		{"model": "skeleton_minion",       "tint": Color(0.90, 1.00, 0.88), "draw_scale": 1.0, "main": "crossbow", "pose_anim": "1H_Ranged_Aiming", "attack_anim": "1H_Ranged_Shoot", "attack_time": 0.15},
		{"model": "skeleton_minion",       "tint": Color(0.90, 1.00, 0.88), "draw_scale": 1.0, "main": "crossbow", "pose_anim": "1H_Ranged_Aiming", "attack_anim": "1H_Ranged_Shoot", "attack_time": 0.15},
		{"model": "skeleton_minion",       "tint": Color(0.90, 1.00, 0.88), "draw_scale": 1.0, "main": "crossbow", "pose_anim": "1H_Ranged_Aiming", "attack_anim": "1H_Ranged_Shoot", "attack_time": 0.15},
	],
	"inferno_warlock": [
		{"model": "skeleton_mage",         "tint": Color(1.00, 0.88, 0.80), "draw_scale": 1.0, "main": "staff", "pose_anim": "Spellcasting", "attack_anim": "Spellcast_Shoot", "attack_time": 0.2},
		{"model": "skeleton_mage",         "tint": Color(1.00, 0.88, 0.80), "draw_scale": 1.0, "main": "staff", "pose_anim": "Spellcasting", "attack_anim": "Spellcast_Shoot", "attack_time": 0.2},
		{"model": "skeleton_mage",         "tint": Color(1.00, 0.88, 0.80), "draw_scale": 1.0, "main": "staff", "pose_anim": "Spellcasting", "attack_anim": "Spellcast_Shoot", "attack_time": 0.2},
	],
	"soul_reaper": [
		{"model": "skeleton_necromancer",  "tint": Color(0.92, 1.00, 0.98), "draw_scale": 1.0, "main": "scythe", "pose_anim": "2H_Melee_Idle", "attack_anim": "2H_Melee_Attack_Slice", "attack_time": 0.25},
		{"model": "skeleton_necromancer",  "tint": Color(0.92, 1.00, 0.98), "draw_scale": 1.0, "main": "scythe", "pose_anim": "2H_Melee_Idle", "attack_anim": "2H_Melee_Attack_Slice", "attack_time": 0.25},
		{"model": "skeleton_necromancer",  "tint": Color(0.92, 1.00, 0.98), "draw_scale": 1.0, "main": "scythe", "pose_anim": "2H_Melee_Idle", "attack_anim": "2H_Melee_Attack_Slice", "attack_time": 0.25},
	],
	"hades": [
		{"model": "skeleton_rogue",        "tint": Color(0.90, 0.85, 1.00), "draw_scale": 1.0, "main": "mace", "off": "shield_small", "pose_anim": "Idle", "attack_anim": "Spellcast_Shoot", "attack_time": 0.3},
		{"model": "skeleton_rogue",        "tint": Color(0.90, 0.85, 1.00), "draw_scale": 1.0, "main": "mace", "off": "shield_small", "pose_anim": "Idle", "attack_anim": "Spellcast_Shoot", "attack_time": 0.3},
		{"model": "skeleton_rogue",        "tint": Color(0.90, 0.85, 1.00), "draw_scale": 1.0, "main": "mace", "off": "shield_small", "pose_anim": "Idle", "attack_anim": "Spellcast_Shoot", "attack_time": 0.3},
	],
	"cocytus": [
		{"model": "skeleton_warrior",      "tint": Color(0.88, 0.96, 1.00), "draw_scale": 1.0, "main": "blade", "pose_anim": "Spellcasting", "attack_anim": "Spellcast_Shoot", "attack_time": 0.2},
		{"model": "skeleton_warrior",      "tint": Color(0.88, 0.96, 1.00), "draw_scale": 1.0, "main": "blade", "pose_anim": "Spellcasting", "attack_anim": "Spellcast_Shoot", "attack_time": 0.2},
		{"model": "skeleton_warrior",      "tint": Color(0.88, 0.96, 1.00), "draw_scale": 1.0, "main": "blade", "pose_anim": "Spellcasting", "attack_anim": "Spellcast_Shoot", "attack_time": 0.2},
	],
	# Golem + golem_axe is much larger than other models. Bumped cam_size to
	# 6.0 (vs default 4.0) so the full silhouette + raised axe fits with
	# margin; cam_y lifted so the camera targets the body center, not the feet.
	"lucifer": [
		# No attack_anim — Rig_Large has no cast clip. Instead the tower spins
		# 360° during fire_flash in _update_facing_angles, which reads as a
		# ritual / charging motion and reuses the pre-rendered Idle_A angles.
		{"model": "skeleton_golem",        "tint": Color(1.00, 0.82, 0.78), "draw_scale": 1.0, "cam_size": 6.0, "cam_y": 3.2, "main": "golem_axe", "pose_anim": "Idle_A"},
		{"model": "skeleton_golem",        "tint": Color(1.00, 0.82, 0.78), "draw_scale": 1.0, "cam_size": 6.0, "cam_y": 3.2, "main": "golem_axe", "pose_anim": "Idle_A"},
		{"model": "skeleton_golem",        "tint": Color(1.00, 0.82, 0.78), "draw_scale": 1.0, "cam_size": 6.0, "cam_y": 3.2, "main": "golem_axe", "pose_anim": "Idle_A"},
	],
	# ─── ENEMIES (single level each, with KayKit weapons equipped) ───
	"seraph_scout":      [{"model": "adv_rogue",         "tint": Color(1.0, 0.93, 0.55),  "draw_scale": 0.85, "main": "adv_dagger",          "pose_anim": "1H_Sword"}],
	"crusader":          [{"model": "adv_knight",        "tint": Color(0.95, 0.95, 0.97), "draw_scale": 1.0,  "main": "adv_sword",           "off": "adv_shield_round",        "pose_anim": "1H_Sword"}],
	"swift_ranger":      [{"model": "adv_rogue_hooded",  "tint": Color(0.6, 0.92, 1.0),   "draw_scale": 0.9,  "main": "adv_crossbow",        "pose_anim": "1H_Ranged_Aiming"}],
	"war_titan":         [{"model": "adv_barbarian",     "tint": Color(1.0, 0.75, 0.5),   "draw_scale": 1.2,  "main": "adv_axe_2h",          "pose_anim": "2H_Sword"}],
	"grand_paladin":     [{"model": "adv_knight",        "tint": Color(1.0, 0.88, 0.35),  "draw_scale": 1.4,  "main": "adv_sword_2h_color",  "off": "adv_shield_round_color",  "pose_anim": "2H_Sword"}],
	"temple_cleric":     [{"model": "adv_mage",          "tint": Color(0.7, 1.0, 0.75),   "draw_scale": 0.9,  "main": "adv_spellbook",       "pose_anim": "Spellcasting"}],
	"archangel_marshal": [{"model": "adv_barbarian",     "tint": Color(1.0, 0.95, 0.7),   "draw_scale": 1.1,  "main": "adv_sword_2h",        "off": "adv_shield_badge_color", "pose_anim": "2H_Sword"}],
	"holy_sentinel":     [{"model": "adv_knight",        "tint": Color(0.72, 0.87, 1.0),  "draw_scale": 1.1,  "main": "adv_sword",           "off": "adv_shield_spikes_color", "pose_anim": "1H_Sword"}],
	"archangel_michael": [{"model": "adv_knight",        "tint": Color(1.0, 0.97, 0.87),  "draw_scale": 1.5,  "main": "adv_sword_2h_color",  "off": "adv_shield_badge_color", "pose_anim": "2H_Sword"}],
	"zeus":              [{"model": "adv_barbarian",     "tint": Color(0.82, 0.87, 1.0),  "draw_scale": 1.1,  "main": "adv_staff",           "pose_anim": "Spellcasting"}],
	"archangel_raphael": [{"model": "adv_mage",          "tint": Color(0.7, 1.0, 0.78),   "draw_scale": 1.0,  "main": "adv_staff",           "pose_anim": "Spellcasting"}],
}

# ═══════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════
func _ready() -> void:
	call_deferred("_pre_render_all_angles")

# ═══════════════════════════════════════════════════════
# PRE-RENDER ALL ANGLES
# ═══════════════════════════════════════════════════════
func _pre_render_all_angles() -> void:
	# Initialize texture arrays:
	#   _angle_textures[type][level_idx][pose_idx][angle_idx]
	# pose_idx 0 = idle always present; pose_idx 1 = attack, only if the cfg
	# defines `attack_anim`.
	for type_key in CHARACTERS:
		var levels: Array = CHARACTERS[type_key]
		var lvl_arr: Array = []
		for level_idx in range(levels.size()):
			var poses: Array = []
			var num_poses: int = 2 if levels[level_idx].has("attack_anim") else 1
			for _p in range(num_poses):
				var angles: Array = []
				angles.resize(NUM_ANGLES)
				poses.append(angles)
			lvl_arr.append(poses)
		_angle_textures[type_key] = lvl_arr

	# Create all character viewports (one per type × level × pose × angle).
	var viewports: Array = []
	for type_key in CHARACTERS:
		var levels: Array = CHARACTERS[type_key]
		for level_idx in range(levels.size()):
			var cfg: Dictionary = levels[level_idx]
			var num_poses: int = 2 if cfg.has("attack_anim") else 1
			for pose_idx in range(num_poses):
				for angle_idx in range(NUM_ANGLES):
					var angle: float = float(angle_idx) * TAU / float(NUM_ANGLES)
					var vp := _create_viewport(cfg, angle, pose_idx)
					add_child(vp)
					viewports.append({"vp": vp, "type_key": type_key, "level_idx": level_idx, "pose_idx": pose_idx, "angle_idx": angle_idx, "kind": "character"})

	# Create projectile viewports (standalone weapon models)
	for proj_key in PROJECTILES:
		var proj_cfg: Dictionary = PROJECTILES[proj_key]
		var angles: Array = []
		angles.resize(NUM_ANGLES)
		_projectile_textures[proj_key] = angles
		for angle_idx in range(NUM_ANGLES):
			var angle: float = float(angle_idx) * TAU / float(NUM_ANGLES)
			var vp := _create_projectile_viewport(proj_cfg, angle)
			add_child(vp)
			viewports.append({"vp": vp, "type_key": proj_key, "angle_idx": angle_idx, "kind": "projectile"})

	# Now that all viewports are in the tree, apply the pose animation
	# on each character instance (AnimationPlayer.seek only takes effect
	# once in the scene tree).
	for entry in viewports:
		if entry["kind"] != "character":
			continue
		var vp: SubViewport = entry["vp"]
		if not vp.has_meta("instance"):
			continue
		_apply_pose(vp.get_meta("instance"), vp.get_meta("pose_anim"), vp.get_meta("pose_time"))

	# Wait for all viewports to render (extra frame so skeleton pose +
	# bone attachment positions settle before capture).
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	# Capture textures
	for entry in viewports:
		var vp: SubViewport = entry["vp"]
		var image: Image = vp.get_texture().get_image()
		var tex: ImageTexture = ImageTexture.create_from_image(image)
		if entry["kind"] == "projectile":
			_projectile_textures[entry["type_key"]][entry["angle_idx"]] = tex
		else:
			_angle_textures[entry["type_key"]][entry["level_idx"]][entry["pose_idx"]][entry["angle_idx"]] = tex

	# Destroy viewports
	for entry in viewports:
		entry["vp"].queue_free()

	_is_ready = true
	textures_ready.emit()
	print("CharacterRenderer: pre-rendered %d viewports" % viewports.size())

# ═══════════════════════════════════════════════════════
# VIEWPORT CONSTRUCTION
# ═══════════════════════════════════════════════════════
func _create_viewport(cfg: Dictionary, model_angle: float, pose_idx: int = POSE_IDLE) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(VIEWPORT_SIZE, VIEWPORT_SIZE)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = SubViewport.MSAA_2X
	vp.own_world_3d = true

	# World environment — ambient lighting
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.48, 0.55)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	vp.add_child(world_env)

	# Camera — orthographic isometric view. cam_size is per-character so no
	# avatar is ever cropped. Default 4.0 renders the character smaller inside
	# the 128px source so outstretched arms / weapons / tall hats keep padding
	# on every side. Draw sites upscale the texture to their target box.
	var cam_size: float = cfg.get("cam_size", 4.0)
	var cam_y: float = cfg.get("cam_y", 2.4)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = cam_size
	camera.look_at_from_position(Vector3(1.2, cam_y, 1.2), Vector3(0.0, 1.0, 0.0), Vector3.UP)
	camera.near = 0.05
	camera.far = 10.0
	vp.add_child(camera)

	# Key light — upper-left
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-40, -35, 0)
	key_light.light_energy = 1.3
	key_light.light_color = Color(1.0, 0.97, 0.92)
	key_light.shadow_enabled = false
	vp.add_child(key_light)

	# Fill light
	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-25, 145, 0)
	fill_light.light_energy = 0.4
	fill_light.light_color = Color(0.85, 0.88, 1.0)
	fill_light.shadow_enabled = false
	vp.add_child(fill_light)

	# Character root (carries rotation)
	var root := Node3D.new()
	root.rotation.y = model_angle

	# Load and instance the 3D model
	var scene := _load_model(cfg["model"])
	if scene:
		var instance := scene.instantiate()
		root.add_child(instance)

		# Skeleton_Golem ships with no animations — inject Rig_Large anims so
		# at least Idle_A / Idle_B / Walking_A / Death_A become available.
		_inject_rig_large_anims_if_needed(instance, cfg["model"])

		# Attach weapons to handslot bones if configured
		if cfg.has("main") or cfg.has("off"):
			var skel := _find_skeleton(instance)
			if skel != null:
				if cfg.has("main"):
					_attach_weapon(skel, "handslot.r", cfg["main"])
				if cfg.has("off"):
					_attach_weapon(skel, "handslot.l", cfg["off"])

		# Stash pose info + instance ref so we can apply the pose AFTER the
		# viewport enters the tree (AnimationPlayer needs to be in-tree for
		# seek() to take effect). pose_idx selects idle vs attack clip.
		var anim_name: String
		var anim_time: float
		if pose_idx == POSE_ATTACK and cfg.has("attack_anim"):
			anim_name = cfg["attack_anim"]
			anim_time = cfg.get("attack_time", 0.25)
		else:
			anim_name = cfg.get("pose_anim", "Idle")
			anim_time = cfg.get("pose_time", 0.0)
		vp.set_meta("instance", instance)
		vp.set_meta("pose_anim", anim_name)
		vp.set_meta("pose_time", anim_time)

	vp.add_child(root)
	return vp

# ═══════════════════════════════════════════════════════
# RIG_LARGE ANIMATION INJECTION
# Skeleton_Golem.glb ships without an AnimationPlayer — KayKit keeps the
# Rig_Large animations in a separate GLB. We load them once and add them
# to any Skeleton_Golem instance as if they'd been bundled.
# ═══════════════════════════════════════════════════════
const RIG_LARGE_ANIM_PATHS := [
	"res://assets/models/kaykit/skeletons/animations/Rig_Large_General.glb",
	"res://assets/models/kaykit/skeletons/animations/Rig_Large_MovementBasic.glb",
]
var _rig_large_anims: Dictionary = {}  # anim_name -> Animation

func _ensure_rig_large_anims_loaded() -> void:
	if not _rig_large_anims.is_empty():
		return
	for path in RIG_LARGE_ANIM_PATHS:
		if not ResourceLoader.exists(path):
			continue
		var scene: PackedScene = load(path)
		if scene == null:
			continue
		var inst := scene.instantiate()
		var ap := _find_animation_player(inst)
		if ap != null:
			for lib_name in ap.get_animation_library_list():
				var lib := ap.get_animation_library(lib_name)
				for anim_name in lib.get_animation_list():
					_rig_large_anims[anim_name] = lib.get_animation(anim_name).duplicate()
		inst.free()

func _inject_rig_large_anims_if_needed(instance: Node, model_key: String) -> void:
	if model_key != "skeleton_golem":
		return
	_ensure_rig_large_anims_loaded()
	if _rig_large_anims.is_empty():
		return
	var ap := _find_animation_player(instance)
	if ap == null:
		ap = AnimationPlayer.new()
		ap.name = "AnimationPlayer"
		instance.add_child(ap)
	# Build library and register on the player.
	var lib := AnimationLibrary.new()
	for anim_name in _rig_large_anims:
		lib.add_animation(anim_name, _rig_large_anims[anim_name])
	# Remove any existing default library to avoid name clashes, then add ours.
	if ap.has_animation_library(""):
		ap.remove_animation_library("")
	ap.add_animation_library("", lib)

# Depth-first search for the AnimationPlayer inside the character GLB.
func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

# Applies an idle pose by playing a named animation and freezing at pose_time.
# Falls back through a list of likely idle names if the requested one is missing
# (KayKit skeletons vs. adventurers ship slightly different animation sets).
func _apply_pose(instance: Node, pose_anim: String, pose_time: float) -> void:
	var ap := _find_animation_player(instance)
	if ap == null:
		return
	var chosen: String = pose_anim
	if not ap.has_animation(chosen):
		for fallback in ["Idle_Combat", "1H_Sword", "2H_Melee_Idle", "Idle", "Idle_A", "Idle_B", "Unarmed_Idle"]:
			if ap.has_animation(fallback):
				chosen = fallback
				break
	if not ap.has_animation(chosen):
		return
	ap.play(chosen)
	ap.seek(pose_time, true)
	ap.pause()

# Depth-first search for the Skeleton3D node inside the character GLB.
func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _attach_weapon(skel: Skeleton3D, bone_name: String, weapon_key: String) -> void:
	var bone_idx: int = skel.find_bone(bone_name)
	if bone_idx < 0:
		return
	var attach := BoneAttachment3D.new()
	attach.bone_name = bone_name
	attach.bone_idx = bone_idx
	skel.add_child(attach)

	var weapon_path: String = WEAPONS.get(weapon_key, "")
	if weapon_path == "" or not ResourceLoader.exists(weapon_path):
		push_warning("CharacterRenderer: weapon not found: " + weapon_key)
		return
	var weapon_scene: PackedScene = _scene_cache.get(weapon_key)
	if weapon_scene == null:
		weapon_scene = load(weapon_path)
		_scene_cache[weapon_key] = weapon_scene
	if weapon_scene != null:
		attach.add_child(weapon_scene.instantiate())

func _load_model(model_key: String) -> PackedScene:
	if not _scene_cache.has(model_key):
		var path: String = MODELS.get(model_key, "")
		if path != "" and ResourceLoader.exists(path):
			_scene_cache[model_key] = load(path)
		else:
			push_warning("CharacterRenderer: Model not found: " + model_key + " at " + path)
			return null
	return _scene_cache[model_key]

# Builds a SubViewport for a standalone projectile weapon model at a specific
# Y-axis angle. Smaller and without character rig — just the weapon centered
# in view, rotated on Z so the weapon lies flat (pointing horizontally).
func _create_projectile_viewport(proj_cfg: Dictionary, angle: float) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(96, 96)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = SubViewport.MSAA_2X
	vp.own_world_3d = true

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.65, 0.75)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	vp.add_child(world_env)

	# Top-down camera — projectile lies flat and rotates around Y
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.0
	camera.look_at_from_position(Vector3(0, 2.0, 0.001), Vector3.ZERO, Vector3(0, 0, -1))
	camera.near = 0.05
	camera.far = 10.0
	vp.add_child(camera)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-90, 0, 0)
	light.light_energy = 1.2
	light.shadow_enabled = false
	vp.add_child(light)

	# Root applies the flight-direction angle + weapon's lay-flat offset
	var root := Node3D.new()
	root.rotation.y = angle
	root.rotation.z = deg_to_rad(proj_cfg.get("z_rot_offset", 0.0))

	var path: String = proj_cfg["path"]
	if ResourceLoader.exists(path):
		if not _scene_cache.has(path):
			_scene_cache[path] = load(path)
		var scene: PackedScene = _scene_cache[path]
		if scene:
			root.add_child(scene.instantiate())

	vp.add_child(root)
	return vp

# ═══════════════════════════════════════════════════════
# PUBLIC API
# Towers accept level 1-3; enemies always use level 1.
# ═══════════════════════════════════════════════════════
func get_texture(type_key: String, angle: float = 0.0, level: int = 1, attacking: bool = false) -> Texture2D:
	if not _is_ready:
		return null
	var by_level: Array = _angle_textures.get(type_key, [])
	if by_level.is_empty():
		return null
	var level_idx: int = clampi(level - 1, 0, by_level.size() - 1)
	var poses: Array = by_level[level_idx]
	if poses.is_empty():
		return null
	# Pose 1 (attack) is only present when attack_anim was configured for this
	# level variant. Fall back to idle when it wasn't, or when not attacking.
	var pose_idx: int = POSE_ATTACK if attacking and poses.size() > 1 else POSE_IDLE
	var angles: Array = poses[pose_idx]
	if angles.is_empty():
		return null
	var step: float = TAU / float(NUM_ANGLES)
	var idx: int = int(round(angle / step))
	idx = ((idx % NUM_ANGLES) + NUM_ANGLES) % NUM_ANGLES
	return angles[idx]

func get_tint(type_key: String, level: int = 1) -> Color:
	if not CHARACTERS.has(type_key):
		return Color.WHITE
	var levels: Array = CHARACTERS[type_key]
	var level_idx: int = clampi(level - 1, 0, levels.size() - 1)
	return levels[level_idx].get("tint", Color.WHITE)

func get_draw_scale(type_key: String, level: int = 1) -> float:
	if not CHARACTERS.has(type_key):
		return 1.0
	var levels: Array = CHARACTERS[type_key]
	var level_idx: int = clampi(level - 1, 0, levels.size() - 1)
	return levels[level_idx].get("draw_scale", 1.0)

func has_character(type_key: String) -> bool:
	return CHARACTERS.has(type_key)

func is_textures_ready() -> bool:
	return _is_ready

# Projectile sprite lookup. `angle` is the flight direction in the same
# screen-to-model-angle convention used for character facing.
func get_projectile_texture(proj_key: String, angle: float = 0.0) -> Texture2D:
	if not _is_ready:
		return null
	var angles: Array = _projectile_textures.get(proj_key, [])
	if angles.is_empty():
		return null
	var step: float = TAU / float(NUM_ANGLES)
	var idx: int = int(round(angle / step))
	idx = ((idx % NUM_ANGLES) + NUM_ANGLES) % NUM_ANGLES
	return angles[idx]
