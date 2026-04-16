extends Node

# Renders each proposed tower level to a PNG in docs/tower_previews/.
# Run: /Applications/Godot.app/Contents/MacOS/Godot --path . tools/render_tower_previews.tscn

const VIEWPORT_SIZE := 256
const OUT_DIR := "res://docs/tower_previews/"

const MODELS := {
	"skeleton_warrior":    "res://assets/models/kaykit/skeletons/Skeleton_Warrior.glb",
	"skeleton_mage":       "res://assets/models/kaykit/skeletons/Skeleton_Mage.glb",
	"skeleton_rogue":      "res://assets/models/kaykit/skeletons/Skeleton_Rogue.glb",
	"skeleton_minion":     "res://assets/models/kaykit/skeletons/Skeleton_Minion.glb",
	"skeleton_necromancer":"res://assets/models/kaykit/skeletons/Necromancer.glb",
	"skeleton_golem":      "res://assets/models/kaykit/skeletons/Skeleton_Golem.glb",
}

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
}

const ADV_MODELS := {
	"adv_knight":       "res://assets/models/kaykit/adventurers/Knight.glb",
	"adv_barbarian":    "res://assets/models/kaykit/adventurers/Barbarian.glb",
	"adv_rogue":        "res://assets/models/kaykit/adventurers/Rogue.glb",
	"adv_rogue_hooded": "res://assets/models/kaykit/adventurers/Rogue_Hooded.glb",
	"adv_mage":         "res://assets/models/kaykit/adventurers/Mage.glb",
}

const ADV_WEAPONS := {
	"adv_crossbow":   "res://assets/models/kaykit/adventurers/weapons/crossbow_1handed.gltf",
	"adv_dagger":     "res://assets/models/kaykit/adventurers/weapons/dagger.gltf",
}

var ALT := {
	# Option A: green mage reaper (collides with inferno mage silhouette)
	"altA_soul_reaper_mage": [
		{"model": "skeleton_mage", "tint": T_REAPER, "draw_scale": 1.0, "main": "scythe"},
		{"model": "skeleton_mage", "tint": T_REAPER, "draw_scale": 1.1, "main": "scythe", "off": "dagger"},
		{"model": "skeleton_mage", "tint": T_REAPER, "draw_scale": 1.2, "main": "mace_large"},
	],
	# Option B: swap — inferno takes necromancer (hooded dark caster), reaper takes mage
	"altB_inferno_necro": [
		{"model": "skeleton_necromancer", "tint": T_INFERNO, "draw_scale": 1.1, "main": "staff"},
		{"model": "skeleton_necromancer", "tint": T_INFERNO, "draw_scale": 1.2, "main": "staff",  "off": "dagger"},
		{"model": "skeleton_necromancer", "tint": T_INFERNO, "draw_scale": 1.3, "main": "scythe"},
	],
	"reaper_necro_tinted": [
		{"model": "skeleton_necromancer", "tint": T_REAPER, "draw_scale": 1.0, "main": "scythe"},
		{"model": "skeleton_necromancer", "tint": T_REAPER, "draw_scale": 1.1, "main": "scythe", "off": "dagger"},
		{"model": "skeleton_necromancer", "tint": T_REAPER, "draw_scale": 1.2, "main": "mace_large"},
	],
	"altB_reaper_mage": [
		{"model": "skeleton_mage", "tint": T_REAPER, "draw_scale": 1.0, "main": "scythe"},
		{"model": "skeleton_mage", "tint": T_REAPER, "draw_scale": 1.1, "main": "scythe", "off": "dagger"},
		{"model": "skeleton_mage", "tint": T_REAPER, "draw_scale": 1.2, "main": "mace_large"},
	],
}

var UNUSED := {
	"adv_knight":       [{"model": "adv_knight",       "tint": Color(1,1,1), "draw_scale": 1.0}],
	"adv_barbarian":    [{"model": "adv_barbarian",    "tint": Color(1,1,1), "draw_scale": 1.0}],
	"adv_rogue":        [{"model": "adv_rogue",        "tint": Color(1,1,1), "draw_scale": 1.0}],
	"adv_rogue_hooded": [{"model": "adv_rogue_hooded", "tint": Color(1,1,1), "draw_scale": 1.0}],
	"adv_mage":         [{"model": "adv_mage",         "tint": Color(1,1,1), "draw_scale": 1.0}],
}

const T_MARKSMAN := Color(1.0, 0.45, 0.35)  # crimson-pink
const T_INFERNO  := Color(1.0, 0.35, 0.15)  # orange-fire
const T_REAPER   := Color(0.4, 1.0, 0.55)   # poison-green
const T_HADES    := Color(0.5, 0.35, 1.0)   # royal purple
const T_COCYTUS  := Color(0.55, 0.88, 1.0)  # ice blue
const T_LUCIFER  := Color(1.0, 0.25, 0.08)  # hellfire crimson

var FINAL := {
	"bone_marksman":   {"model": "adv_rogue_hooded",     "tint": Color.WHITE, "draw_scale": 1.0, "main": "adv_crossbow"},
	"inferno_warlock": {"model": "skeleton_mage",        "tint": Color.WHITE, "draw_scale": 1.0, "main": "staff"},
	"soul_reaper":     {"model": "skeleton_necromancer", "tint": Color.WHITE, "draw_scale": 1.0, "main": "scythe"},
	"hades":           {"model": "skeleton_rogue",       "tint": Color.WHITE, "draw_scale": 1.0, "main": "mace", "off": "shield_small"},
	"cocytus":         {"model": "skeleton_warrior",     "tint": Color.WHITE, "draw_scale": 1.0, "main": "blade"},
	"lucifer":         {"model": "skeleton_golem",       "tint": Color.WHITE, "draw_scale": 1.3, "main": "golem_axe"},
}

var PROPOSED := {
	"bone_marksman": [
		{"model": "adv_rogue_hooded", "tint": T_MARKSMAN, "draw_scale": 1.0, "main": "adv_crossbow"},
		{"model": "adv_rogue_hooded", "tint": T_MARKSMAN, "draw_scale": 1.1, "main": "adv_crossbow", "off": "adv_dagger"},
		{"model": "adv_rogue_hooded", "tint": T_MARKSMAN, "draw_scale": 1.2, "main": "adv_crossbow", "off": "quiver"},
	],
	"bone_marksman_orig": [
		{"model": "adv_rogue_hooded", "tint": Color.WHITE, "draw_scale": 1.0, "main": "adv_crossbow"},
		{"model": "adv_rogue_hooded", "tint": Color.WHITE, "draw_scale": 1.1, "main": "adv_crossbow", "off": "adv_dagger"},
		{"model": "adv_rogue_hooded", "tint": Color.WHITE, "draw_scale": 1.2, "main": "adv_crossbow", "off": "quiver"},
	],
	"inferno_warlock": [
		{"model": "skeleton_mage", "tint": T_INFERNO, "draw_scale": 1.0,  "main": "staff"},
		{"model": "skeleton_mage", "tint": T_INFERNO, "draw_scale": 1.1,  "main": "staff",  "off": "dagger"},
		{"model": "skeleton_mage", "tint": T_INFERNO, "draw_scale": 1.2,  "main": "scythe"},
	],
	"soul_reaper": [
		{"model": "skeleton_necromancer", "tint": Color.WHITE, "draw_scale": 1.0, "main": "scythe"},
		{"model": "skeleton_necromancer", "tint": Color.WHITE, "draw_scale": 1.1, "main": "scythe", "off": "dagger"},
		{"model": "skeleton_necromancer", "tint": Color.WHITE, "draw_scale": 1.2, "main": "mace_large"},
	],
	"hades": [
		{"model": "skeleton_rogue", "tint": T_HADES, "draw_scale": 1.0, "main": "mace",       "off": "shield_small"},
		{"model": "skeleton_rogue", "tint": T_HADES, "draw_scale": 1.1, "main": "mace_large", "off": "shield_large"},
		{"model": "skeleton_rogue", "tint": T_HADES, "draw_scale": 1.2, "main": "staff",      "off": "shield_large"},
	],
	"cocytus": [
		{"model": "skeleton_warrior", "tint": T_COCYTUS, "draw_scale": 1.0,  "main": "blade"},
		{"model": "skeleton_warrior", "tint": T_COCYTUS, "draw_scale": 1.1,  "main": "blade", "off": "shield_large"},
		{"model": "skeleton_warrior", "tint": T_COCYTUS, "draw_scale": 1.2,  "main": "axe",   "off": "shield_large"},
	],
	"lucifer": [
		{"model": "skeleton_golem", "tint": T_LUCIFER, "draw_scale": 1.5,  "main": "golem_axe"},
		{"model": "skeleton_golem", "tint": T_LUCIFER, "draw_scale": 1.65, "main": "golem_axe_large"},
		{"model": "skeleton_golem", "tint": T_LUCIFER, "draw_scale": 1.8,  "main": "golem_axe_large", "off": "shield_large"},
	],
}

var _scene_cache: Dictionary = {}

func _ready() -> void:
	call_deferred("_render_all")

func _render_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var viewports: Array = []
	for tower_key in PROPOSED:
		var levels: Array = PROPOSED[tower_key]
		for i in range(levels.size()):
			var cfg: Dictionary = levels[i]
			var vp := _make_viewport(cfg)
			add_child(vp)
			viewports.append({"vp": vp, "tower": tower_key, "level": i + 1})
	for key in UNUSED:
		var cfg2: Dictionary = UNUSED[key][0]
		var vp2 := _make_viewport(cfg2)
		add_child(vp2)
		viewports.append({"vp": vp2, "tower": "unused_" + key, "level": 0})
	for fkey in FINAL:
		var fcfg: Dictionary = FINAL[fkey]
		var fvp := _make_viewport(fcfg)
		add_child(fvp)
		viewports.append({"vp": fvp, "tower": "final_" + fkey, "level": 0})
	for akey in ALT:
		var alvls: Array = ALT[akey]
		for j in range(alvls.size()):
			var acfg: Dictionary = alvls[j]
			var avp := _make_viewport(acfg)
			add_child(avp)
			viewports.append({"vp": avp, "tower": akey, "level": j + 1})

	# let the scene render a few frames
	for _i in range(6):
		await RenderingServer.frame_post_draw

	for entry in viewports:
		var vp: SubViewport = entry["vp"]
		var img: Image = vp.get_texture().get_image()
		var path: String
		if entry["level"] == 0:
			path = "%s%s.png" % [OUT_DIR, entry["tower"]]
		else:
			path = "%s%s_lv%d.png" % [OUT_DIR, entry["tower"], entry["level"]]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved ", path)

	print("done — %d frames rendered" % viewports.size())
	get_tree().quit()

func _make_viewport(cfg: Dictionary) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(VIEWPORT_SIZE, VIEWPORT_SIZE)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = SubViewport.MSAA_4X
	vp.own_world_3d = true

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.background_color = Color(0.08, 0.04, 0.06, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.48, 0.55)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var ds: float = cfg.get("draw_scale", 1.0)
	cam.size = 2.5 * max(1.0, ds / 1.0)  # grow view for bigger models
	var cam_y: float = 2.15 + (ds - 1.0) * 0.8
	cam.look_at_from_position(Vector3(1.2, cam_y, 1.2), Vector3(0.0, 1.0, 0.0), Vector3.UP)
	cam.near = 0.05
	cam.far = 10.0
	vp.add_child(cam)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, -35, 0)
	key.light_energy = 1.3
	key.light_color = Color(1.0, 0.97, 0.92)
	vp.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 145, 0)
	fill.light_energy = 0.4
	fill.light_color = Color(0.85, 0.88, 1.0)
	vp.add_child(fill)

	var root := Node3D.new()
	# face camera (KayKit default +Z, isometric cam at +X+Z)
	root.rotation.y = PI * 0.25
	var table: Dictionary = MODELS if MODELS.has(cfg["model"]) else ADV_MODELS
	var scene := _load(cfg["model"], table)
	if scene:
		var inst: Node3D = scene.instantiate()
		root.add_child(inst)
		var tint: Color = cfg.get("tint", Color.WHITE)
		if tint != Color.WHITE:
			_apply_tint(inst, tint)
		var skel := _find_skel(inst)
		if skel != null:
			if cfg.has("main"):
				_attach(skel, "handslot.r", cfg["main"])
			if cfg.has("off"):
				_attach(skel, "handslot.l", cfg["off"])
	vp.add_child(root)
	return vp

func _load(key: String, table: Dictionary) -> PackedScene:
	var path: String = table.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		push_warning("missing: " + key)
		return null
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path)
	return _scene_cache[path]

func _find_skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var f := _find_skel(c)
		if f != null:
			return f
	return null

func _attach(skel: Skeleton3D, bone: String, weapon_key: String) -> void:
	var idx := skel.find_bone(bone)
	if idx < 0:
		return
	var att := BoneAttachment3D.new()
	att.bone_name = bone
	att.bone_idx = idx
	skel.add_child(att)
	var wtable: Dictionary = WEAPONS if WEAPONS.has(weapon_key) else ADV_WEAPONS
	var ws := _load(weapon_key, wtable)
	if ws:
		att.add_child(ws.instantiate())

func _apply_tint(n: Node, tint: Color) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		var mesh: Mesh = mi.mesh
		if mesh != null:
			for si in range(mesh.get_surface_count()):
				var mat: Material = mi.get_active_material(si)
				if mat is StandardMaterial3D:
					var m: StandardMaterial3D = (mat as StandardMaterial3D).duplicate()
					m.albedo_color = tint
					mi.set_surface_override_material(si, m)
	for c in n.get_children():
		_apply_tint(c, tint)
