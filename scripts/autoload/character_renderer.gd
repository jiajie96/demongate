extends Node

# ═══════════════════════════════════════════════════════
# CHARACTER RENDERER
# Pre-renders KayKit 3D models at 8 directional angles per type
# (17 types × 8 angles = 136 cached ImageTextures).
# At runtime, get_texture(type_key, angle) picks the
# nearest pre-rendered angle for per-instance facing.
# Viewports are destroyed after capture — zero runtime cost.
# ═══════════════════════════════════════════════════════

const VIEWPORT_SIZE := 128
const NUM_ANGLES := 16  # 22.5° increments for smoother rotation

var _angle_textures: Dictionary = {}  # type_key -> Array[Texture2D] (NUM_ANGLES entries)
var _scene_cache: Dictionary = {}      # model_key -> PackedScene
var _is_ready := false

signal textures_ready

# ═══════════════════════════════════════════════════════
# MODEL PATHS
# ═══════════════════════════════════════════════════════
const MODELS := {
	"skeleton_warrior": "res://assets/models/kaykit/skeletons/Skeleton_Warrior.glb",
	"skeleton_mage": "res://assets/models/kaykit/skeletons/Skeleton_Mage.glb",
	"skeleton_rogue": "res://assets/models/kaykit/skeletons/Skeleton_Rogue.glb",
	"skeleton_minion": "res://assets/models/kaykit/skeletons/Skeleton_Minion.glb",
	"adv_knight": "res://assets/models/kaykit/adventurers/Knight.glb",
	"adv_barbarian": "res://assets/models/kaykit/adventurers/Barbarian.glb",
	"adv_rogue": "res://assets/models/kaykit/adventurers/Rogue.glb",
	"adv_rogue_hooded": "res://assets/models/kaykit/adventurers/Rogue_Hooded.glb",
	"adv_mage": "res://assets/models/kaykit/adventurers/Mage.glb",
}

# ═══════════════════════════════════════════════════════
# CHARACTER CONFIG
# ═══════════════════════════════════════════════════════
var CHARACTERS := {
	# Towers (demon side — skeleton models)
	"bone_marksman":    {"model": "skeleton_rogue",    "tint": Color(1.0, 0.65, 0.6),   "draw_scale": 1.0},
	"inferno_warlock":  {"model": "skeleton_mage",     "tint": Color(0.85, 0.55, 1.0),  "draw_scale": 1.0},
	"soul_reaper":      {"model": "skeleton_minion",   "tint": Color(0.6, 1.0, 0.7),    "draw_scale": 1.0},
	"hades":            {"model": "skeleton_mage",     "tint": Color(0.6, 0.55, 1.0),   "draw_scale": 1.1},
	"cocytus":          {"model": "skeleton_rogue",    "tint": Color(0.75, 0.92, 1.0),  "draw_scale": 1.0},
	"lucifer":          {"model": "skeleton_warrior",  "tint": Color(1.0, 0.72, 0.4),   "draw_scale": 1.3},
	# Enemies (holy side — adventurer models)
	"seraph_scout":     {"model": "adv_rogue",         "tint": Color(1.0, 0.93, 0.55),  "draw_scale": 0.85},
	"crusader":         {"model": "adv_knight",        "tint": Color(0.95, 0.95, 0.97), "draw_scale": 1.0},
	"swift_ranger":     {"model": "adv_rogue_hooded",  "tint": Color(0.6, 0.92, 1.0),   "draw_scale": 0.9},
	"war_titan":        {"model": "adv_barbarian",     "tint": Color(1.0, 0.75, 0.5),   "draw_scale": 1.2},
	"grand_paladin":    {"model": "adv_knight",        "tint": Color(1.0, 0.88, 0.35),  "draw_scale": 1.4},
	"temple_cleric":    {"model": "adv_mage",          "tint": Color(0.7, 1.0, 0.75),   "draw_scale": 0.9},
	"archangel_marshal":{"model": "adv_barbarian",     "tint": Color(1.0, 0.95, 0.7),   "draw_scale": 1.1},
	"holy_sentinel":    {"model": "adv_knight",        "tint": Color(0.72, 0.87, 1.0),  "draw_scale": 1.1},
	"archangel_michael":{"model": "adv_knight",        "tint": Color(1.0, 0.97, 0.87),  "draw_scale": 1.5},
	"zeus":             {"model": "adv_barbarian",     "tint": Color(0.82, 0.87, 1.0),  "draw_scale": 1.1},
	"archangel_raphael":{"model": "adv_mage",          "tint": Color(0.7, 1.0, 0.78),   "draw_scale": 1.0},
}

# ═══════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════
func _ready() -> void:
	call_deferred("_pre_render_all_angles")

# ═══════════════════════════════════════════════════════
# PRE-RENDER ALL ANGLES
# Creates 17 × 8 = 136 viewports, waits for render,
# captures each as ImageTexture, then destroys viewports.
# ═══════════════════════════════════════════════════════
func _pre_render_all_angles() -> void:
	# Initialize texture arrays
	for type_key in CHARACTERS:
		var arr: Array = []
		arr.resize(NUM_ANGLES)
		_angle_textures[type_key] = arr

	# Create viewports for each (type, angle) combination
	var viewports: Array = []  # Array of dicts: {vp, type_key, angle_idx}
	for type_key in CHARACTERS:
		var cfg: Dictionary = CHARACTERS[type_key]
		for angle_idx in range(NUM_ANGLES):
			var angle: float = float(angle_idx) * TAU / float(NUM_ANGLES)
			var vp := _create_viewport(cfg, angle)
			add_child(vp)
			viewports.append({"vp": vp, "type_key": type_key, "angle_idx": angle_idx})

	# Wait multiple frames to ensure viewports finish rendering
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	# Capture each viewport's texture as an ImageTexture
	for entry in viewports:
		var vp: SubViewport = entry["vp"]
		var image: Image = vp.get_texture().get_image()
		var tex: ImageTexture = ImageTexture.create_from_image(image)
		_angle_textures[entry["type_key"]][entry["angle_idx"]] = tex

	# Destroy all viewports — textures are now cached
	for entry in viewports:
		entry["vp"].queue_free()

	_is_ready = true
	textures_ready.emit()
	print("CharacterRenderer: pre-rendered %d characters × %d angles" % [CHARACTERS.size(), NUM_ANGLES])

# ═══════════════════════════════════════════════════════
# VIEWPORT CONSTRUCTION
# ═══════════════════════════════════════════════════════
func _create_viewport(cfg: Dictionary, model_angle: float) -> SubViewport:
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

	# Camera — orthographic isometric view.
	# Sized to include tall hats/horns: the KayKit Skeleton Mage's pointed hat
	# reaches ~2 units, so vertical world-range must exceed that after projection.
	# At camera tilt ≈ 45°, vertical screen extent ≈ size × 0.827, so size 2.5
	# gives ~2.07 units of headroom. Look-at at character mid-height keeps the
	# character vertically centered in the 128×128 texture.
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.5
	camera.look_at_from_position(Vector3(1.2, 2.15, 1.2), Vector3(0.0, 1.0, 0.0), Vector3.UP)
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

	# Fill light — softer from the back
	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-25, 145, 0)
	fill_light.light_energy = 0.4
	fill_light.light_color = Color(0.85, 0.88, 1.0)
	fill_light.shadow_enabled = false
	vp.add_child(fill_light)

	# Character root with the desired angle baked in
	var root := Node3D.new()
	root.rotation.y = model_angle

	# Load and instance the 3D model
	var scene := _load_model(cfg["model"])
	if scene:
		var instance := scene.instantiate()
		root.add_child(instance)

	vp.add_child(root)
	return vp

func _load_model(model_key: String) -> PackedScene:
	if not _scene_cache.has(model_key):
		var path: String = MODELS.get(model_key, "")
		if path != "" and ResourceLoader.exists(path):
			_scene_cache[model_key] = load(path)
		else:
			push_warning("CharacterRenderer: Model not found: " + model_key + " at " + path)
			return null
	return _scene_cache[model_key]

# ═══════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════
# Returns the pre-rendered texture for a type at the given facing angle.
# Angle is in radians in game-space (atan2(dx, dy) where dx/dy are screen-space deltas).
# If textures aren't ready yet, returns null (caller should fall back).
func get_texture(type_key: String, angle: float = 0.0) -> Texture2D:
	if not _is_ready:
		return null
	var arr: Array = _angle_textures.get(type_key, [])
	if arr.is_empty():
		return null
	var step: float = TAU / float(NUM_ANGLES)
	var idx: int = int(round(angle / step))
	# Wrap to [0, NUM_ANGLES)
	idx = ((idx % NUM_ANGLES) + NUM_ANGLES) % NUM_ANGLES
	return arr[idx]

func get_tint(type_key: String) -> Color:
	if CHARACTERS.has(type_key):
		return CHARACTERS[type_key]["tint"]
	return Color.WHITE

func get_draw_scale(type_key: String) -> float:
	if CHARACTERS.has(type_key):
		return CHARACTERS[type_key]["draw_scale"]
	return 1.0

func has_character(type_key: String) -> bool:
	return CHARACTERS.has(type_key)

func is_textures_ready() -> bool:
	return _is_ready
