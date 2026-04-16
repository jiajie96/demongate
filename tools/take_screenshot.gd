extends Node

# One-shot screenshot capture:
# - Reset game state, hand out sins, place one of each tower, start wave 8
# - Tick simulation with manual dt so combat VFX spawn without waiting real-time
# - Wait a few rendered frames, save PNG, quit

const OUT_PATH := "res://assets/screenshot_gameplay.png"
const SIM_STEPS := 240          # ~8s of pre-simulation so waves + VFX populate
const SIM_DT := 0.033
const POST_FRAMES := 6          # rendered frames to wait after setup

func _ready() -> void:
	# Run after parent Main._ready completes
	call_deferred("_setup_and_capture")

func _setup_and_capture() -> void:
	await get_tree().process_frame

	# CharacterRenderer pre-renders ~720 SubViewports on startup; without waiting
	# for its textures_ready signal towers draw as flat colored dots.
	var cr := get_node_or_null("/root/CharacterRenderer")
	if cr and cr.has_method("is_textures_ready") and not cr.is_textures_ready():
		await cr.textures_ready

	GM.reset_state()
	GM.sins = 999

	# Dense tower layout — one per non-path tile across all 6 spare rows so every
	# tower type shows up multiple times (except Lucifer, which is unique).
	var placements := [
		# Row 1 (spare band between path rows 0 and 2)
		["bone_marksman",   Vector2i(1, 1)],
		["inferno_warlock", Vector2i(3, 1)],
		["soul_reaper",     Vector2i(5, 1)],
		["hades",           Vector2i(7, 1)],
		["cocytus",         Vector2i(11, 1)],
		# Row 3
		["bone_marksman",   Vector2i(3, 3)],
		["inferno_warlock", Vector2i(5, 3)],
		["cocytus",         Vector2i(7, 3)],
		["hades",           Vector2i(9, 3)],
		["bone_marksman",   Vector2i(11, 3)],
		# Row 5
		["bone_marksman",   Vector2i(1, 5)],
		["inferno_warlock", Vector2i(5, 5)],
		["soul_reaper",     Vector2i(7, 5)],
		["hades",           Vector2i(9, 5)],
		# Row 7
		["bone_marksman",   Vector2i(1, 7)],
		["inferno_warlock", Vector2i(5, 7)],
		["cocytus",         Vector2i(9, 7)],
		["hades",           Vector2i(11, 7)],
		# Row 9
		["bone_marksman",   Vector2i(5, 9)],
		["soul_reaper",     Vector2i(7, 9)],
		["lucifer",         Vector2i(9, 9)],
		["inferno_warlock", Vector2i(11, 9)],
		# Row 11
		["hades",           Vector2i(5, 11)],
		["cocytus",         Vector2i(9, 11)],
	]
	for p in placements:
		var type: String = p[0]
		var g: Vector2i = p[1]
		if not GM.is_buildable(g.x, g.y):
			push_warning("Tile not buildable: %s for %s" % [g, type])
			continue
		var tower := GM.create_tower(type, g.x, g.y)
		GM.towers.append(tower)
		GM.occupied_tiles[str(g.x) + "," + str(g.y)] = tower

	# Kick off a mid-late wave for visual variety
	GM.wave = 7
	GM.start_wave()

	# Simulate combat offline so projectiles + VFX exist
	for i in range(SIM_STEPS):
		GM.update_waves(SIM_DT)
		GM.update_towers(SIM_DT)
		if GM.has_method("update_enemies"):
			GM.update_enemies(SIM_DT)
		if GM.has_method("update_projectiles"):
			GM.update_projectiles(SIM_DT)
		if GM.has_method("update_effects"):
			GM.update_effects(SIM_DT)
		GM.game_time += SIM_DT

	# Spread surviving enemies across the middle of the path so the shot doesn't
	# cluster them at the spawn corner. Snap each enemy's x/y to its waypoint.
	var path_px := Config.path_pixels
	var path_len := path_px.size()
	var mid_start := int(path_len * 0.25)
	var mid_end := int(path_len * 0.75)
	var alive_idx := 0
	var alive_count := 0
	for e in GM.enemies:
		if e["alive"]:
			alive_count += 1
	if alive_count > 0:
		for e in GM.enemies:
			if not e["alive"]:
				continue
			var t: float = float(alive_idx) / float(max(alive_count - 1, 1))
			var idx: int = int(lerp(float(mid_start), float(mid_end), t))
			idx = clampi(idx, 0, path_len - 1)
			e["path_index"] = idx
			e["x"] = path_px[idx].x
			e["y"] = path_px[idx].y
			alive_idx += 1
		# Let towers reacquire targets + spawn fresh projectiles/VFX at the new positions
		for i in range(12):
			GM.update_towers(SIM_DT)
			if GM.has_method("update_projectiles"):
				GM.update_projectiles(SIM_DT)
			if GM.has_method("update_effects"):
				GM.update_effects(SIM_DT)
			GM.game_time += SIM_DT

	# Pause so nothing moves while we render
	GM.paused = true

	for i in range(POST_FRAMES):
		await RenderingServer.frame_post_draw

	var img := get_viewport().get_texture().get_image()
	var abs_path := ProjectSettings.globalize_path(OUT_PATH)
	var err := img.save_png(abs_path)
	if err != OK:
		push_error("save_png failed: %s" % err)
	else:
		print("Saved screenshot: %s" % abs_path)

	get_tree().quit()
