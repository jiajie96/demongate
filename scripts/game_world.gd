extends Node2D

const TEX_DEMON_MAW := preload("res://assets/art/bestial_fangs.png")
const TEX_HEAVEN_HERALD := preload("res://assets/art/angel_wings.png")

var font: Font
var T: int  # tile size shorthand
var _base_position: Vector2

func _ready() -> void:
	font = ThemeDB.fallback_font
	T = Config.TILE_SIZE
	_base_position = position  # preserve scene-configured offset (10, 55)
	Audio.start_music()
	_spawn_ambient_particles()

func _process(dt: float) -> void:
	# Screen shake — always update position even when paused/menu
	if GM.screen_shake > 0 and GM.phase == "playing" and not GM.paused:
		var shake_t: float = clampf(GM.screen_shake / 0.3, 0.0, 1.0)
		var intensity: float = GM.screen_shake_intensity * shake_t
		position = _base_position + Vector2(
			sin(GM.game_time * 60.0) * intensity,
			cos(GM.game_time * 47.0) * intensity * 0.7
		)
	elif position != _base_position:
		position = _base_position

	if GM.phase != "playing":
		queue_redraw()
		return

	if GM.paused:
		queue_redraw()
		return

	GM.game_time += dt
	GM.clear_alive_type_cache()
	GM.update_waves(dt)
	GM.update_enemies(dt)
	GM.update_towers(dt)
	GM.update_projectiles(dt)
	GM.update_effects(dt)
	_update_facing_angles(dt)

	# Track mouse in local coordinates
	var local_mouse := get_local_mouse_position()
	if local_mouse.x >= 0 and local_mouse.x < Config.GAME_WIDTH and local_mouse.y >= 0 and local_mouse.y < Config.GAME_HEIGHT:
		GM.hovered_grid = Config.pixel_to_grid(local_mouse.x, local_mouse.y)
	else:
		GM.hovered_grid = Vector2i(-1, -1)

	queue_redraw()

func _draw() -> void:
	_draw_map()
	_draw_path_flow()
	_draw_guardian_zone()
	_draw_range_preview()
	_draw_towers()
	_draw_enemies()
	_draw_projectiles()
	_draw_effects()
	_draw_foreground_particles()
	_draw_placement_preview()
	_draw_notifications()
	_draw_wave_banner()
	_draw_dice_result()
	if GM.show_overview:
		_draw_overview()

# ═══════════════════════════════════════════════════════
# MAP
# ═══════════════════════════════════════════════════════
func _row_gradient(r: int) -> float:
	return float(r) / float(Config.GRID_ROWS - 1)  # 0.0 = heaven (top), 1.0 = hell (bottom)

# Directional cast shadow — light source is upper-left, shadow falls to lower-right
func _draw_cast_shadow(cx: float, cy: float, radius: float, height: float = 1.0) -> void:
	var sx: float = cx + 3.0 * height   # offset right
	var sy: float = cy + 4.0 * height   # offset down
	var rx: float = radius * 1.3         # stretch horizontally
	var ry: float = radius * 0.55        # flatten vertically (ellipse on ground plane)
	# Multi-layer soft shadow
	# Outer soft penumbra
	var pts := PackedVector2Array()
	for i in range(24):
		var angle: float = float(i) * TAU / 24.0
		pts.append(Vector2(sx + cos(angle) * rx * 1.2, sy + sin(angle) * ry * 1.2))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.08 * height))
	# Inner shadow core
	pts.clear()
	for i in range(24):
		var angle: float = float(i) * TAU / 24.0
		pts.append(Vector2(sx + cos(angle) * rx * 0.75, sy + sin(angle) * ry * 0.75))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.14 * height))

# Rim lighting — bright arc on the upper-left (light-facing) edge of circular bodies
func _draw_rim_light(cx: float, cy: float, radius: float, alpha: float = 1.0, tint: Color = Color(1, 1, 1)) -> void:
	# Upper-left rim (light source direction: ~225 degrees from center, i.e. upper-left)
	var rim_a: float = 0.22 * alpha
	draw_arc(Vector2(cx, cy), radius, PI * 0.85, PI * 1.45, 12, Color(tint.r, tint.g, tint.b, rim_a), 1.5)
	# Brighter specular highlight on the top-left
	draw_arc(Vector2(cx, cy), radius - 1, PI * 1.0, PI * 1.3, 8, Color(tint.r, tint.g, tint.b, rim_a * 1.5), 1.0)

# Ground-bounce gradient — darker at feet, lighter at head (simulates ambient occlusion)
func _draw_ground_ao(cx: float, cy: float, radius: float, alpha: float = 1.0) -> void:
	# Dark ring at the very bottom of the entity (contact shadow)
	draw_arc(Vector2(cx, cy), radius - 1, -0.3, PI + 0.3, 16, Color(0, 0, 0, 0.12 * alpha), 2.0)

# ═══════════════════════════════════════════════════════
# AMBIENT PARTICLES (persistent GPUParticles2D emitters)
# Spawned at startup; loop continuously; never free.
# ═══════════════════════════════════════════════════════
func _spawn_ambient_particles() -> void:
	var w: float = Config.GAME_WIDTH
	var h: float = Config.GAME_HEIGHT
	var heaven_bot: float = h * 0.25  # top 25% = heaven zone

	# --- Hell zone: rising fire embers across the bottom ---
	_make_ambient_emitter(
		preload("res://assets/vfx/particles/fire_01.png"),
		Vector2(w * 0.5, h + 10),  # emit from just below bottom of screen
		Vector2(w * 1.2, 20),       # wide box emission area
		12,    # amount
		3.0,   # lifetime
		40.0,  # vel min (upward)
		80.0,  # vel max
		15.0,  # spread (degrees)
		Color(1.0, 0.55, 0.1, 0.22),
		Color(1.0, 0.2, 0.0, 0.0),
		0.1, 0.22,
		Vector2(0, -30),  # gravity pushes up (fire rises)
		-90.0             # direction: up
	)

	# --- Heaven zone: drifting light sparkles across the top ---
	_make_ambient_emitter(
		preload("res://assets/vfx/particles/star_04.png"),
		Vector2(w * 0.5, -10),
		Vector2(w * 1.2, heaven_bot + 10),
		20,    # amount — fewer, more spread out
		5.0,   # long life — gentle drift
		10.0,  # slow vel
		25.0,
		360.0, # full spread
		Color(1.0, 0.95, 0.8, 0.5),
		Color(0.9, 0.95, 1.0, 0.0),
		0.1, 0.25,
		Vector2(0, 8),  # gently drift down
		90.0
	)

	# --- Spawn portal — continuous golden flare particles ---
	var spawn_cell: Vector2i = Config.MAP_PATH[0]
	var sx: float = spawn_cell.x * T + T / 2.0
	var sy: float = spawn_cell.y * T + T / 2.0
	_make_ambient_emitter(
		preload("res://assets/vfx/particles/flare_01.png"),
		Vector2(sx, sy),
		Vector2(8, 8),
		12,
		1.2,
		20.0,
		50.0,
		30.0,  # mostly upward
		Color(1.0, 0.9, 0.5, 0.7),
		Color(1.0, 0.75, 0.3, 0.0),
		0.2, 0.5,
		Vector2(0, -60),  # rise
		-90.0
	)

	# --- Hell's Core — sparse embers drifting from the demon maw ---
	var core_cell: Vector2i = Config.MAP_PATH[Config.MAP_PATH.size() - 1]
	var cx: float = core_cell.x * T + T / 2.0
	var cy: float = core_cell.y * T + T / 2.0
	_make_ambient_emitter(
		preload("res://assets/vfx/particles/fire_01.png"),
		Vector2(cx, cy - 5),
		Vector2(10, 3),
		4,
		1.1,
		15.0,
		35.0,
		20.0,
		Color(1.0, 0.55, 0.12, 0.28),
		Color(0.4, 0.05, 0.0, 0.0),
		0.10, 0.20,
		Vector2(0, -20),
		-90.0
	)

func _make_ambient_emitter(tex: Texture2D, pos: Vector2, box: Vector2,
		amount: int, lifetime: float, vel_min: float, vel_max: float,
		spread: float, start_color: Color, end_color: Color,
		scale_min: float, scale_max: float,
		gravity: Vector2, angle_deg: float) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.position = pos
	p.texture = tex
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime  # pre-warm so particles are already on screen at start
	p.emitting = true
	p.show_behind_parent = false

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(box.x * 0.5, box.y * 0.5, 0)
	mat.direction = Vector3(cos(deg_to_rad(angle_deg)), sin(deg_to_rad(angle_deg)), 0)
	mat.spread = spread
	mat.initial_velocity_min = vel_min
	mat.initial_velocity_max = vel_max
	mat.gravity = Vector3(gravity.x, gravity.y, 0)
	mat.scale_min = scale_min
	mat.scale_max = scale_max
	mat.damping_min = 2.0
	mat.damping_max = 8.0

	var gradient := Gradient.new()
	gradient.set_color(0, start_color)
	gradient.set_color(1, end_color)
	var gtx := GradientTexture1D.new()
	gtx.gradient = gradient
	mat.color_ramp = gtx

	p.process_material = mat
	add_child(p)
	return p

func _draw_map() -> void:
	# Background gradient: celestial blue (top) → hellish dark (bottom)
	for gr in range(Config.GRID_ROWS):
		var g := _row_gradient(gr)
		var row_col := Config.COLOR_HEAVEN_BG.lerp(Config.COLOR_BG, g)
		draw_rect(Rect2(0, gr * T, Config.GAME_WIDTH, T + 1), row_col)

	# Draw tiles — two passes: path first (sunken), then ground (raised with walls on top)
	for r in range(Config.GRID_ROWS):
		for c in range(Config.GRID_COLS):
			if Config.is_path(c, r):
				_draw_path_tile(c * T, r * T, c, r)
	for r in range(Config.GRID_ROWS):
		for c in range(Config.GRID_COLS):
			if not Config.is_path(c, r):
				_draw_ground_tile(c * T, r * T, c, r)

	# Ambient atmosphere layer
	_draw_ambient()

	# Spawn marker — heaven herald (angel-wings icon by Lorc, CC BY 3.0)
	var spawn_cell: Vector2i = Config.MAP_PATH[0]
	var sx: float = spawn_cell.x * T + T / 2.0
	var sy: float = spawn_cell.y * T + T / 2.0
	_draw_heaven_herald(sx, sy)

	# Core marker — Hell's Core: demon maw facing the path (north)
	var core_cell: Vector2i = Config.MAP_PATH[Config.MAP_PATH.size() - 1]
	var cx: float = core_cell.x * T + T / 2.0
	var cy: float = core_cell.y * T + T / 2.0
	_draw_hell_maw(cx, cy)

	# Core HP bar on map
	var bar_w: float = 40.0
	var bar_h: float = 3.0
	var hp_ratio: float = GM.core_hp / GM.core_max_hp
	var bar_y: float = cy + 20
	draw_rect(Rect2(cx - bar_w / 2, bar_y, bar_w, bar_h), Config.COLOR_HEALTH_BG)
	var hp_color := Config.COLOR_HEALTH_HP if hp_ratio > 0.3 else Config.COLOR_HEALTH_LOW
	draw_rect(Rect2(cx - bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), hp_color)

func _draw_heaven_herald(sx: float, sy: float) -> void:
	# Sprite-based heaven herald (angel-wings icon by Lorc, CC BY 3.0).
	# Wings extend up off the spawn tile; figure body sits at the path mouth.
	# Counterpoint to the demon maw at the other end of the path.
	var gt := GM.game_time
	var pulse: float = 0.5 + 0.5 * sin(gt * 2.5)

	# Center the sprite slightly south of spawn so wings poke up above the
	# spawn tile and the figure aligns with the path entry point.
	var center := Vector2(sx, sy + 9)
	var size: float = 46.0
	var half: float = size * 0.5

	# Soft golden divine aura behind the herald
	for i in range(4):
		var glow_r: float = 26.0 - float(i) * 4.0
		var glow_a: float = (0.10 + 0.06 * pulse) * (4 - i) * 0.18
		draw_circle(center, glow_r, Color(1.0, 0.88, 0.45, glow_a))

	# Light shafts radiating upward — divine beams pouring from on high
	for ri in range(5):
		var ray_angle: float = -PI * 0.5 + (float(ri) - 2.0) * 0.30
		var ray_len: float = 18.0 + pulse * 7.0
		var ray_end: Vector2 = center + Vector2(cos(ray_angle), sin(ray_angle)) * ray_len
		draw_line(center, ray_end, Color(1.0, 0.93, 0.65, 0.25 + pulse * 0.15), 1.0)

	# Drop shadow (subtle warm)
	draw_texture_rect(TEX_HEAVEN_HERALD, Rect2(center.x - half, center.y - half + 1.5, size, size),
		false, Color(0.45, 0.32, 0.10, 0.30))
	# Main sprite — gold-cream divine tint
	draw_texture_rect(TEX_HEAVEN_HERALD, Rect2(center.x - half, center.y - half, size, size),
		false, Color(1.0, 0.92, 0.62, 1.0))
	# Bright halo rim — slightly larger pass with soft warm-white
	draw_texture_rect(TEX_HEAVEN_HERALD,
		Rect2(center.x - half - 0.8, center.y - half - 0.8, size + 1.6, size + 1.6),
		false, Color(1.0, 0.97, 0.78, 0.28))

	# Bright divine core spark in the herald's chest
	draw_circle(center, 3.5 * pulse, Color(1, 0.97, 0.85, 0.85))
	draw_circle(center, 1.8 * pulse, Color(1, 1, 0.95, 0.95))

	# Label
	draw_string(font, Vector2(sx - 24, sy + T * 0.7), Locale.t("SPAWN"),
		HORIZONTAL_ALIGNMENT_CENTER, 48, 10, Color(1.0, 0.92, 0.7))

func _draw_hell_maw(cx: float, cy: float) -> void:
	# Sprite-based demon maw (bestial-fangs icon by Lorc, CC BY 3.0).
	# The source icon is in profile with the mouth opening toward the right;
	# we rotate -90° so the fangs gape UP toward the incoming path.
	var gt := GM.game_time

	# Sprite — dark purple-black tint; rotated so mouth faces north
	var size: float = 54.0
	var half: float = size * 0.5
	draw_set_transform(Vector2(cx, cy), -PI * 0.5, Vector2.ONE)
	draw_texture_rect(TEX_DEMON_MAW, Rect2(-half, -half + 1.0, size, size),
		false, Color(0, 0, 0, 0.35))
	draw_texture_rect(TEX_DEMON_MAW, Rect2(-half, -half, size, size),
		false, Color(0.10, 0.04, 0.08, 1.0))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# Faint ember glow inside the open mouth — subtle, not a bonfire.
	var mouth_cx: float = cx + 1.5
	var mouth_cy: float = cy - 6.0
	var ip: float = 0.8 + 0.2 * sin(gt * 2.2)
	draw_circle(Vector2(mouth_cx, mouth_cy), 4.0 * ip, Color(0.9, 0.25, 0.08, 0.35))
	draw_circle(Vector2(mouth_cx, mouth_cy), 1.8 * ip, Color(1.0, 0.6, 0.2, 0.5))

	# Label
	draw_string(font, Vector2(cx - 40, cy - 38), Locale.t("HELL'S CORE"),
		HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Color(1, 0.88, 0.82))

func _draw_ambient() -> void:
	var t := GM.game_time
	# Heaven zone (top rows 0-3): bright golden light shafts and sparkles
	for li in range(4):
		var lx: float = 80.0 + float(li) * 180.0 + sin(t * 0.3 + float(li)) * 30.0
		var shaft_a: float = 0.045 + 0.022 * sin(t * 0.8 + float(li) * 1.5)
		# Vertical light shaft from top, fading downward
		for sy in range(0, 4 * T, 4):
			var fade: float = 1.0 - float(sy) / float(4 * T)
			draw_line(Vector2(lx, sy), Vector2(lx, sy + 4), Color(1.0, 0.95, 0.8, shaft_a * fade), 3.0)
	# Sparkle particles in heaven zone
	for si in range(12):
		var seed_val: float = float(si) * 73.37
		var sx: float = fmod(seed_val * 47.1 + t * 8.0, Config.GAME_WIDTH)
		var sy: float = fmod(seed_val * 31.7 + t * 3.0, float(3 * T))
		var sparkle_a: float = 0.4 + 0.4 * sin(t * 4.0 + seed_val)
		if sparkle_a > 0.35:
			draw_circle(Vector2(sx, sy), 1.4, Color(1.0, 0.95, 0.85, sparkle_a * 0.7))

	# Hell zone (bottom rows 8-11): soft heat glow
	var hell_top: float = float(8 * T)
	var fire_glow_a: float = 0.035 + 0.015 * sin(t * 1.5)
	draw_rect(Rect2(0, float(10 * T), Config.GAME_WIDTH, float(2 * T)), Color(1, 0.2, 0.0, fire_glow_a))
	draw_rect(Rect2(0, float(11 * T), Config.GAME_WIDTH, float(T)), Color(1, 0.15, 0.0, fire_glow_a * 1.4))
	# Rising ember particles — sparse, low alpha
	for ei in range(7):
		var seed_val: float = float(ei) * 53.91
		var ex: float = fmod(seed_val * 41.3, Config.GAME_WIDTH)
		var ey_cycle: float = fmod(seed_val * 17.7 + t * (15.0 + fmod(seed_val, 10.0)), float(4 * T))
		var ey: float = float(Config.GAME_HEIGHT) - ey_cycle
		if ey >= hell_top:
			var ember_life: float = ey_cycle / float(4 * T)
			var ember_a: float = (1.0 - ember_life) * 0.35
			var ember_r: float = 1.4 + (1.0 - ember_life) * 0.8
			ex += sin(t * 2.0 + seed_val) * 4.0
			draw_circle(Vector2(ex, ey), ember_r, Color(1, 0.55, 0.15, ember_a))

func _draw_foreground_particles() -> void:
	var t := GM.game_time
	# Foreground depth layer — larger, softer particles that drift in front of entities

	# Heaven zone: drifting light motes — brighter
	for i in range(8):
		var seed_f: float = float(i) * 97.13
		var fx: float = fmod(seed_f * 37.7 + t * 6.0, float(Config.GAME_WIDTH + 40)) - 20.0
		var fy: float = fmod(seed_f * 23.1 + t * 2.5, float(4 * T))
		var mote_a: float = 0.09 + 0.06 * sin(t * 1.5 + seed_f)
		var mote_r: float = 2.5 + 1.5 * sin(t * 0.8 + seed_f * 0.5)
		# Soft glow
		draw_circle(Vector2(fx, fy), mote_r * 2.0, Color(0.9, 0.95, 1.0, mote_a * 0.4))
		draw_circle(Vector2(fx, fy), mote_r, Color(0.95, 0.97, 1.0, mote_a))

	# Hell zone: floating ash and cinder — sparse, muted
	var hell_top_y: float = float(8 * T)
	for i in range(5):
		var seed_f: float = float(i) * 61.47
		var fx: float = fmod(seed_f * 29.3, float(Config.GAME_WIDTH))
		fx += sin(t * 0.5 + seed_f) * 12.0
		var fy_cycle: float = fmod(seed_f * 11.3 + t * 8.0, float(4 * T))
		var fy: float = float(Config.GAME_HEIGHT) - fy_cycle
		if fy >= hell_top_y:
			var ash_life: float = fy_cycle / float(4 * T)
			var ash_a: float = (1.0 - ash_life) * 0.07
			var ash_r: float = 2.5 + (1.0 - ash_life) * 1.5
			draw_circle(Vector2(fx, fy), ash_r, Color(1.0, 0.45, 0.18, ash_a))

	# Mid-zone: universal dust motes — slightly more visible
	for i in range(6):
		var seed_f: float = float(i) * 113.79
		var fx: float = fmod(seed_f * 43.1 + t * 4.0, float(Config.GAME_WIDTH + 20)) - 10.0
		var fy: float = fmod(seed_f * 67.3 + t * 1.2, float(Config.GAME_HEIGHT))
		var dust_a: float = 0.045 + 0.03 * sin(t * 2.0 + seed_f)
		draw_circle(Vector2(fx, fy), 2.0, Color(0.8, 0.8, 0.85, dust_a))

func _draw_path_flow() -> void:
	var path_px: Array[Vector2] = Config.path_pixels
	if path_px.size() < 2:
		return
	var t := GM.game_time
	var path_len: int = path_px.size()

	# Multiple glowing dots flowing along the path from spawn toward core
	var num_dots: int = 6
	for di in range(num_dots):
		# Each dot has a unique phase cycling through the path
		var speed: float = 0.06 + fmod(float(di) * 0.37, 0.03)
		var phase: float = fmod(t * speed + float(di) / float(num_dots), 1.0)
		var path_pos: float = phase * float(path_len - 1)
		var idx: int = int(path_pos)
		var frac: float = path_pos - float(idx)
		if idx >= path_len - 1:
			continue
		var pos: Vector2 = path_px[idx].lerp(path_px[idx + 1], frac)

		# Gradient color: heaven gold at start → hellfire red at end
		var g: float = phase
		var dot_col := Color(1.0, 0.9, 0.5).lerp(Color(1.0, 0.3, 0.1), g)
		var dot_a: float = 0.25 + 0.15 * sin(t * 3.0 + float(di) * 2.0)

		# Outer glow
		draw_circle(pos, 5.0, Color(dot_col.r, dot_col.g, dot_col.b, dot_a * 0.25))
		# Core
		draw_circle(pos, 2.5, Color(dot_col.r, dot_col.g, dot_col.b, dot_a))
		# Bright center
		draw_circle(pos, 1.0, Color(1, 1, 0.9, dot_a * 0.6))

func _tile_hash(c: int, r: int) -> int:
	return absi(c * 7919 + r * 104729 + (c + 1) * (r + 1) * 31) % 10000

func _draw_ground_tile(rx: float, ry: float, c: int, r: int) -> void:
	var h := _tile_hash(c, r)
	var g := _row_gradient(r)  # 0.0 = heaven, 1.0 = hell
	var WALL_H := 10  # visible wall height for isometric depth

	# Base color blended by gradient: cool blue-silver (heaven) → warm crimson (hell)
	var v := float(h % 30 - 15) * 0.002
	var heaven_base := Config.COLOR_HEAVEN_GROUND if (c + r) % 2 == 0 else Config.COLOR_HEAVEN_GROUND_ALT
	var hell_base := Config.COLOR_GROUND if (c + r) % 2 == 0 else Config.COLOR_GROUND_ALT
	var base := heaven_base.lerp(hell_base, g)
	var tile_col := Color(base.r + v, base.g + v * 0.6, base.b + v)

	# --- Isometric wall faces (drawn BEHIND the top face) ---
	var wall_dark := tile_col.darkened(0.35)
	var wall_mid := tile_col.darkened(0.22)

	# South wall — visible when path is below this tile
	if Config.is_path(c, r + 1):
		draw_colored_polygon(PackedVector2Array([
			Vector2(rx, ry + T), Vector2(rx + T, ry + T),
			Vector2(rx + T, ry + T + WALL_H), Vector2(rx, ry + T + WALL_H)
		]), wall_dark)
		draw_rect(Rect2(rx, ry + T, T, 3), wall_mid)
		draw_line(Vector2(rx, ry + T + WALL_H), Vector2(rx + T, ry + T + WALL_H), Color(0, 0, 0, 0.3), 1.5)

	# East wall — visible when path is to the right
	if Config.is_path(c + 1, r):
		var east_col := tile_col.darkened(0.45)
		draw_colored_polygon(PackedVector2Array([
			Vector2(rx + T, ry), Vector2(rx + T, ry + T),
			Vector2(rx + T + 6, ry + T + WALL_H), Vector2(rx + T + 6, ry + WALL_H)
		]), east_col)

	# South-east corner fill
	if Config.is_path(c, r + 1) and Config.is_path(c + 1, r):
		draw_colored_polygon(PackedVector2Array([
			Vector2(rx + T, ry + T), Vector2(rx + T + 6, ry + T + WALL_H),
			Vector2(rx + T, ry + T + WALL_H)
		]), tile_col.darkened(0.5))

	# --- Top face (flat-shaded) ---
	draw_rect(Rect2(rx, ry, T, T), tile_col)

	# Highlight border: top + left edges bright, bottom + right edges dark
	var highlight := Config.COLOR_HEAVEN_HIGHLIGHT.lerp(Config.COLOR_TILE_HIGHLIGHT, g)
	draw_line(Vector2(rx + 1, ry + 1), Vector2(rx + T - 1, ry + 1), Color(highlight.r, highlight.g, highlight.b, highlight.a * 1.6), 1.0)
	draw_line(Vector2(rx + 1, ry + 2), Vector2(rx + 1, ry + T - 2), Color(highlight.r, highlight.g, highlight.b, highlight.a * 1.2), 1.0)
	draw_line(Vector2(rx + 2, ry + T - 1), Vector2(rx + T, ry + T - 1), Color(0, 0, 0, 0.28), 1.0)
	draw_line(Vector2(rx + T - 1, ry + 2), Vector2(rx + T - 1, ry + T - 2), Color(0, 0, 0, 0.2), 1.0)

	# Top edge lip when wall is visible below
	if Config.is_path(c, r + 1):
		draw_line(Vector2(rx, ry + T - 1), Vector2(rx + T, ry + T - 1), tile_col.lightened(0.14), 1.5)

	# Decorative details — different for heaven vs hell
	if g > 0.5:
		# Hell side: muted geometric dots and ember glows
		var hell_fade: float = (g - 0.5) * 2.0
		if h % 11 == 0:
			var dx := rx + float(h % 28) + 10
			@warning_ignore("integer_division")
			var dy := ry + float((h / 20) % 28) + 10
			draw_circle(Vector2(dx, dy), 1.5, Color(1.0, 0.55, 0.15, 0.25 * hell_fade))
		elif h % 17 == 0:
			var ex := rx + float(h % 28) + 10
			@warning_ignore("integer_division")
			var ey := ry + float((h / 28) % 28) + 10
			var glow := 0.2 + 0.15 * sin(GM.game_time * 2.5 + float(h) * 0.01)
			draw_circle(Vector2(ex, ey), 2.0, Color(1.0, 0.5, 0.15, glow * hell_fade))
	else:
		# Heaven side: simple 4-point star sparkles
		if h % 8 == 0:
			var sx := rx + float(h % 30) + 9
			@warning_ignore("integer_division")
			var sy := ry + float((h / 30) % 30) + 9
			var twinkle := 0.35 + 0.35 * sin(GM.game_time * 3.5 + float(h) * 0.02)
			var star_len: float = 3.0
			draw_line(Vector2(sx - star_len, sy), Vector2(sx + star_len, sy), Color(0.9, 0.95, 1.0, twinkle * 0.7), 1.0)
			draw_line(Vector2(sx, sy - star_len), Vector2(sx, sy + star_len), Color(0.9, 0.95, 1.0, twinkle * 0.7), 1.0)
			draw_circle(Vector2(sx, sy), 1.0, Color(0.95, 0.97, 1.0, twinkle))

func _draw_path_tile(rx: float, ry: float, c: int, r: int) -> void:
	var g := _row_gradient(r)  # 0.0 = heaven, 1.0 = hell

	# Dark sunken base
	var path_col := Config.COLOR_HEAVEN_PATH.lerp(Config.COLOR_PATH, g)
	var deep_col := path_col.darkened(0.15)
	draw_rect(Rect2(rx, ry, T, T), deep_col)

	# Brighter center surface
	var surface_col := Config.COLOR_HEAVEN_PATH_SURFACE.lerp(Config.COLOR_PATH_SURFACE, g)
	draw_rect(Rect2(rx + 3, ry + 3, T - 6, T - 6), surface_col)

	# Cast shadows from walls (2 bands)
	# North wall casts shadow downward
	if not Config.is_path(c, r - 1):
		draw_rect(Rect2(rx, ry, T, 6), Color(0, 0, 0, 0.3))
		draw_rect(Rect2(rx, ry + 6, T, 4), Color(0, 0, 0, 0.12))
	# West wall casts shadow rightward
	if not Config.is_path(c - 1, r):
		draw_rect(Rect2(rx, ry, 5, T), Color(0, 0, 0, 0.25))
		draw_rect(Rect2(rx + 5, ry, 3, T), Color(0, 0, 0, 0.1))

	# Subtle light on open edges
	var edge_light := Color(0.8, 0.85, 1.0, 0.08).lerp(Color(1, 0.8, 0.6, 0.07), g)
	if not Config.is_path(c, r + 1):
		draw_line(Vector2(rx + 2, ry + T - 2), Vector2(rx + T - 2, ry + T - 2), edge_light, 1.0)
	if not Config.is_path(c + 1, r):
		draw_line(Vector2(rx + T - 2, ry + 2), Vector2(rx + T - 2, ry + T - 2), Color(edge_light.r, edge_light.g, edge_light.b, edge_light.a * 0.75), 1.0)

	# Inset border
	var edge_col := Config.COLOR_HEAVEN_PATH_EDGE.lerp(Config.COLOR_PATH_EDGE, g)
	draw_rect(Rect2(rx + 0.5, ry + 0.5, T - 1, T - 1), edge_col, false, 0.5)

# ═══════════════════════════════════════════════════════
# GUARDIAN PROTECTION ZONE
# ═══════════════════════════════════════════════════════
func _draw_guardian_zone() -> void:
	if not GM._has_alive_type("holy_sentinel"):
		return
	@warning_ignore("integer_division")
	var half := Config.path_pixels.size() / 2
	var pulse := 0.3 + 0.15 * sin(GM.game_time * 2.0)
	# Highlight protected path tiles with blue overlay
	for i in range(mini(half, Config.MAP_PATH.size())):
		var cell: Vector2i = Config.MAP_PATH[i]
		var rx: float = cell.x * T
		var ry: float = cell.y * T
		draw_rect(Rect2(rx, ry, T, T), Color(0.3, 0.5, 1.0, 0.12 * pulse))
	# Draw midpoint marker
	if half > 0 and half < Config.path_pixels.size():
		var mid_pt: Vector2 = Config.path_pixels[half]
		draw_line(Vector2(mid_pt.x - 20, mid_pt.y), Vector2(mid_pt.x + 20, mid_pt.y), Color(0.4, 0.6, 1.0, 0.5), 2.0)
		draw_string(font, Vector2(mid_pt.x - 30, mid_pt.y - 8), Locale.t("SHIELD END"), HORIZONTAL_ALIGNMENT_CENTER, 60, 8, Color(0.5, 0.7, 1.0, 0.6))

# ═══════════════════════════════════════════════════════
# RANGE PREVIEW
# ═══════════════════════════════════════════════════════
func _draw_range_preview() -> void:
	if GM.selected_tower != null:
		var t: Dictionary = GM.selected_tower
		draw_circle(Vector2(t["x"], t["y"]), t["range"], Config.COLOR_RANGE)
		draw_arc(Vector2(t["x"], t["y"]), t["range"], 0, TAU, 48, Config.COLOR_RANGE_BORDER, 1.0)

# ═══════════════════════════════════════════════════════
# TOWERS
# ═══════════════════════════════════════════════════════
func _draw_towers() -> void:
	for t in GM.towers:
		var cx: float = t["col"] * T + T / 2.0
		var cy: float = t["row"] * T + T / 2.0
		var a: float = 0.5 if t["is_disabled"] else 1.0

		# Build animation — rising from ground
		var build_t: float = t.get("build_timer", 0.0)
		if build_t > 0:
			var build_a: float = build_t / 0.3  # 1.0→0.0
			# Construction glow rising from base
			var glow_r: float = 18.0 * build_a
			draw_circle(Vector2(cx, cy), glow_r, Color(t["color"].r, t["color"].g, t["color"].b, build_a * 0.3))
			draw_arc(Vector2(cx, cy), glow_r, 0, TAU, 16, Color(1, 0.9, 0.6, build_a * 0.4), 1.5)
			# Rising particles
			for bi in range(4):
				var ba: float = float(bi) * TAU / 4.0
				var br: float = 12.0 * build_a
				var bpy: float = cy + 10 * build_a - 20 * (1.0 - build_a)
				draw_circle(Vector2(cx + cos(ba) * br, bpy), 1.5, Color(1, 0.8, 0.4, build_a * 0.5))

		# REDESIGN: Cocytus cone — persistent translucent fan showing kill zone
		if t.get("is_beam_cone", false):
			_draw_cone_overlay(t, cx, cy, a)

		_draw_tower_model(t, cx, cy, a)

		# Hades buff aura — blue-purple arcane rings rising from buffed allies
		if t.get("hades_buffed", false):
			var buff_t: float = GM.game_time * 1.8
			for ri in range(2):
				var phase: float = fmod(buff_t + ri * 0.5, 1.0)
				var ring_y: float = cy + 10 - phase * 28
				var ring_a: float = (1.0 - phase) * 0.55
				var ring_w: float = 16.0 - phase * 4.0
				var ring_h: float = 5.0 - phase * 2.0
				var pts := PackedVector2Array()
				for si in range(24):
					var angle: float = si * TAU / 24.0
					pts.append(Vector2(cx + cos(angle) * ring_w, ring_y + sin(angle) * ring_h))
				for si in range(pts.size()):
					var next_i: int = (si + 1) % pts.size()
					draw_line(pts[si], pts[next_i], Color(0.75, 0.55, 1.0, ring_a), 1.5)

		# Selected highlight
		if GM.selected_tower != null and GM.selected_tower.get("id") == t["id"]:
			draw_arc(Vector2(cx, cy), 20, 0, TAU, 24, Color.WHITE, 2.0)

		# Level indicator
		if t["level"] > 1:
			var tx: float = t["col"] * T
			var ty: float = t["row"] * T
			draw_string(font, Vector2(tx + T - 24, ty + T - 4), "Lv" + str(t["level"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.8, 0.0, a))

		# Muzzle flash when firing — tower-specific
		if t["fire_flash"] > 0:
			var flash_a: float = t["fire_flash"] / 0.15
			var tp := Vector2(t["x"], t["y"])
			var fc: Color = t["color"]
			# Direction toward current target (for directional flash streaks)
			var fire_dir := Vector2.ZERO
			var fire_tgt = t.get("target")
			if fire_tgt != null and fire_tgt is Dictionary and fire_tgt.get("alive", false):
				var fdx: float = fire_tgt["x"] - tp.x
				var fdy: float = fire_tgt["y"] - tp.y
				var fdist: float = sqrt(fdx * fdx + fdy * fdy)
				if fdist > 0.1:
					fire_dir = Vector2(fdx / fdist, fdy / fdist)
			match t["type"]:
				"bone_marksman":
					# Quick bright spark
					draw_circle(tp, 8 * flash_a, Color(1, 0.6, 0.2, 0.35 * flash_a))
					draw_circle(tp, 3 * flash_a, Color(1, 0.9, 0.5, 0.7 * flash_a))
					# Directional streak — a short flame tongue along the firing line
					if fire_dir != Vector2.ZERO:
						var streak_end: Vector2 = tp + fire_dir * (10.0 * flash_a)
						draw_line(tp, streak_end, Color(1, 0.85, 0.4, 0.6 * flash_a), 2.0)
						draw_line(tp, streak_end, Color(1, 1, 0.8, 0.8 * flash_a), 1.0)
				"inferno_warlock":
					# Triangular sigil flare — a momentary 3-pointed burst
					# with radiating violet sparks. Reads more "spell cast"
					# than a generic round flash.
					draw_circle(tp, 16 * flash_a, Color(0.6, 0.15, 0.8, 0.18 * flash_a))
					draw_circle(tp, 9 * flash_a, Color(1, 0.5, 0.9, 0.4 * flash_a))
					# Sigil triangle expanding outward
					var muz_r: float = 12.0 * flash_a
					for ti in range(3):
						var ma: float = -PI / 2.0 + ti * TAU / 3.0
						var mp1 := Vector2(tp.x + cos(ma) * muz_r, tp.y + sin(ma) * muz_r)
						var ma2: float = -PI / 2.0 + ((ti + 1) % 3) * TAU / 3.0
						var mp2 := Vector2(tp.x + cos(ma2) * muz_r, tp.y + sin(ma2) * muz_r)
						draw_line(mp1, mp2, Color(1.0, 0.75, 1.0, 0.85 * flash_a), 1.5)
					# Six radiating sparks
					for si in range(6):
						var sa2: float = float(si) * TAU / 6.0 + 0.3
						var s_inner: float = 4.0 * flash_a
						var s_outer: float = 14.0 * flash_a
						draw_line(
							Vector2(tp.x + cos(sa2) * s_inner, tp.y + sin(sa2) * s_inner),
							Vector2(tp.x + cos(sa2) * s_outer, tp.y + sin(sa2) * s_outer),
							Color(1.0, 0.8, 1.0, 0.6 * flash_a), 1.0)
					# White-hot core
					draw_circle(tp, 3 * flash_a, Color(1, 1, 1, 0.6 * flash_a))
				"soul_reaper":
					# Green pulse ring
					draw_arc(tp, 10 * flash_a, 0, TAU, 16, Color(0.2, 0.9, 0.4, 0.4 * flash_a), 2.0)
					draw_circle(tp, 4 * flash_a, Color(0.4, 1, 0.6, 0.5 * flash_a))
				"cocytus":
					# No muzzle flash — the cone stream is the visual.
					pass
				_:
					draw_circle(tp, 10 * flash_a, Color(fc.r, fc.g, fc.b, 0.3 * flash_a))
					draw_circle(tp, 5 * flash_a, Color(1, 0.9, 0.7, 0.4 * flash_a))

		# Attack line to target — subtle dashed feel via tower color
		if t["target"] != null and t["target"] is Dictionary and t["target"].get("alive", false) and not t["is_disabled"]:
			var line_a: float = 0.06 + 0.04 * sin(GM.game_time * 6.0)
			draw_line(
				Vector2(t["x"], t["y"]),
				Vector2(t["target"]["x"], t["target"]["y"]),
				Color(t["color"].r, t["color"].g, t["color"].b, line_a), 1.0
			)

# ═══════════════════════════════════════════════════════
# ENEMIES
# ═══════════════════════════════════════════════════════
func _draw_cone_overlay(tower: Dictionary, cx: float, cy: float, a: float) -> void:
	# No boundary lines — stream alone communicates the cone.
	var range_px: float = tower["range"]
	var half_angle: float = Config.TOWER_DATA[tower["type"]]["cone_half_angle"]
	# Oscillating sweep: ±15° (30° total arc) around the set facing
	var sweep: float = sin(GM.game_time * Config.COCYTUS_SWEEP_SPEED) * Config.COCYTUS_SWEEP_ANGLE
	var facing: float = tower["facing_angle"] + sweep

	# BLIZZARD STREAM — dense flowing snow along effective facing
	var stream_t: float = fmod(GM.game_time * 1.4, 1.0)
	for si in range(12):
		var phase: float = fmod(stream_t + si * 0.083, 1.0)
		var r_pt: float = range_px * phase
		var lane: float = fmod(float(si) * 0.31, 1.0) * 2.0 - 1.0  # -1..1 across cone
		var drift: float = sin(GM.game_time * 2.5 + si * 0.9) * 0.25
		var ang: float = facing + (lane + drift) * half_angle * 0.75
		var sx: float = cx + cos(ang) * r_pt
		var sy: float = cy + sin(ang) * r_pt
		var life: float = 1.0 - abs(phase - 0.5) * 2.0   # 0→1→0
		var shard_a: float = life * 0.9 * a
		var size: float = 1.5 + life * 2.8
		draw_circle(Vector2(sx, sy), size, Color(0.85, 0.97, 1.0, shard_a))
		draw_circle(Vector2(sx, sy), size + 2.5, Color(0.55, 0.85, 1.0, shard_a * 0.35))

func _draw_enemies() -> void:
	var gt: float = GM.game_time
	var has_commander: bool = GM._has_alive_type("archangel_marshal")
	# Cache NEC towers for slow-zone mote visual
	var nec_towers: Array = []
	for t in GM.towers:
		if t["type"] == "soul_reaper" and not t["is_disabled"]:
			nec_towers.append(t)

	for e in GM.enemies:
		if not e["alive"]:
			continue

		var ex: float = e["x"]
		var ey: float = e["y"]
		var er: float = e["radius"]
		var flash: bool = e["flash_timer"] > 0

		# Subtle floating bob — each enemy has a unique phase based on id
		var bob: float = sin(gt * 2.0 + e["id"] * 1.7) * 1.2
		ey += bob

		# REDESIGN: COC frost mark — snowflake icon floating above enemy
		if e.get("frost_timer", 0.0) > 0:
			var fr_life: float = clampf(e["frost_timer"] / 0.3, 0.0, 1.0)
			var fsx: float = ex
			var fsy: float = ey - er - 6
			var fcol := Color(0.75, 0.95, 1.0, 0.9 * fr_life)
			var fcol2 := Color(0.55, 0.85, 1.0, 0.6 * fr_life)
			# 6-arm snowflake — three crossing lines rotating slowly
			var spin: float = gt * 0.8 + e["id"] * 0.3
			var arm_len: float = 4.5
			for ai in range(3):
				var ang: float = spin + ai * PI / 3.0
				var ax: float = cos(ang) * arm_len
				var ay: float = sin(ang) * arm_len
				draw_line(Vector2(fsx - ax, fsy - ay), Vector2(fsx + ax, fsy + ay), fcol, 1.4)
			# Center glow
			draw_circle(Vector2(fsx, fsy), 1.8, fcol)
			draw_circle(Vector2(fsx, fsy), 3.0, fcol2)
			# Frosted body tint — faint blue overlay on sprite
			draw_circle(Vector2(ex, ey), er + 1, Color(0.55, 0.85, 1.0, 0.18 * fr_life))

		# REDESIGN: NEC slow-zone mark — cold ice-mote ring on slowed enemies
		var is_slowed_by_aura := false
		for n in nec_towers:
			var ndx: float = e["x"] - n["x"]
			var ndy: float = e["y"] - n["y"]
			if ndx * ndx + ndy * ndy <= n["range"] * n["range"]:
				is_slowed_by_aura = true
				break
		if is_slowed_by_aura:
			for mi in range(2):
				var ma: float = -gt * 1.4 + e["id"] * 0.3 + mi * PI
				var mx: float = ex + cos(ma) * (er + 3)
				var my: float = ey + sin(ma) * (er + 3) * 0.5 + 2
				draw_circle(Vector2(mx, my), 1.3, Color(0.5, 1.0, 0.7, 0.7))

		# BURN DoT indicator — rising ember particles and orange body tint when
		# the enemy has active burn stacks from Inferno Warlock hits.
		var burn_stacks: int = e.get("burn_stacks", 0)
		if burn_stacks > 0:
			var burn_life: float = clampf(e.get("burn_timer", 0.0) / 3.0, 0.0, 1.0)
			var burn_intensity: float = float(burn_stacks) / 4.0  # 0.25 to 1.0
			# Orange-red body tint — stronger with more stacks
			draw_circle(Vector2(ex, ey), er + 1, Color(1.0, 0.4, 0.08, 0.15 * burn_intensity * burn_life))
			# Rising flame particles — more particles for more stacks
			var n_flames: int = 1 + burn_stacks
			for fi in range(n_flames):
				var flame_seed: float = float(fi) * 2.3 + float(e["id"]) * 0.7
				var flame_life: float = fmod(gt * 1.2 + flame_seed * 0.4, 1.5) / 1.5
				var flame_x: float = ex + sin(flame_seed * 1.7 + gt * 2.5) * (er * 0.7)
				var flame_y: float = ey + er * 0.3 - flame_life * (er + 10.0)
				var flame_a: float = (1.0 - flame_life) * 0.65 * burn_intensity * burn_life
				var flame_r: float = 1.2 + (1.0 - flame_life) * 1.5
				# Flame core — bright orange-yellow
				draw_circle(Vector2(flame_x, flame_y), flame_r, Color(1.0, 0.65, 0.12, flame_a))
				# Flame outer glow — deeper red
				draw_circle(Vector2(flame_x, flame_y), flame_r + 1.5, Color(1.0, 0.25, 0.05, flame_a * 0.35))
			# Burn stack pips — small orange dots below the enemy showing stack count
			var pip_y: float = ey + er + 4
			var pip_start_x: float = ex - float(burn_stacks - 1) * 2.5
			for pi in range(burn_stacks):
				var pip_x: float = pip_start_x + float(pi) * 5.0
				var pip_pulse: float = 0.7 + 0.3 * sin(gt * 6.0 + float(pi) * 1.5)
				draw_circle(Vector2(pip_x, pip_y), 1.4, Color(1.0, 0.5, 0.1, 0.8 * pip_pulse * burn_life))

		# Spawn fade-in portal effect
		var spawn_t: float = e.get("spawn_timer", 0.0)
		if spawn_t > 0:
			var spawn_a: float = spawn_t / 0.4  # 1.0→0.0 as spawn completes
			# Golden portal ring shrinking around enemy
			var ring_r: float = er + 10.0 * spawn_a
			draw_arc(Vector2(ex, ey), ring_r, 0, TAU, 20, Color(1, 0.85, 0.5, spawn_a * 0.5), 1.5)
			# Vertical light column fading
			draw_line(Vector2(ex, ey - 20 * spawn_a), Vector2(ex, ey + 10), Color(1, 0.9, 0.6, spawn_a * 0.3), 2.0)

		# Archangel speed buff — golden speed streaks behind boosted enemies
		if has_commander and e["type"] != "archangel_marshal":
			for si in range(3):
				var streak_off: float = float(si + 1) * 3.5
				var streak_a: float = 0.12 - float(si) * 0.03
				draw_line(Vector2(ex - er - streak_off, ey - 1), Vector2(ex - er - streak_off + 3, ey - 1), Color(1, 0.85, 0.3, streak_a), 1.0)
				draw_line(Vector2(ex - er - streak_off, ey + 1), Vector2(ex - er - streak_off + 3, ey + 1), Color(1, 0.85, 0.3, streak_a), 1.0)

		# Monk healing sparkles — green particles rising from monks
		# Temple Cleric now has a heal aura: show a subtle green pulse ring
		if e["type"] == "temple_cleric":
			# Heal aura ring — soft green pulse showing the area of effect
			var aura_r: float = Config.ENEMY_DATA["temple_cleric"].get("heal_aura_radius", 80.0)
			var aura_pulse: float = 0.3 + 0.15 * sin(gt * 2.0 + e["id"] * 0.5)
			draw_arc(Vector2(ex, ey), aura_r, 0, TAU, 24, Color(0.4, 0.9, 0.5, 0.06 * aura_pulse), 1.0)
			for pi in range(3):
				var spark_phase: float = fmod(gt * 1.5 + pi * 0.7, 2.0)
				if spark_phase < 1.0:
					var spark_x: float = ex + sin(gt * 3.0 + pi * 2.1) * (er + 2)
					var spark_y: float = ey - spark_phase * 15.0
					var spark_a: float = (1.0 - spark_phase) * 0.6
					draw_circle(Vector2(spark_x, spark_y), 1.5, Color(0.4, 1, 0.5, spark_a))
					# Tiny cross shape
					draw_line(Vector2(spark_x - 1.5, spark_y), Vector2(spark_x + 1.5, spark_y), Color(0.5, 1, 0.6, spark_a * 0.7), 1.0)
					draw_line(Vector2(spark_x, spark_y - 1.5), Vector2(spark_x, spark_y + 1.5), Color(0.5, 1, 0.6, spark_a * 0.7), 1.0)

		# Draw 3D model avatar
		_draw_enemy_model(e, ex, ey, er, flash)

		# Rim lighting — upper-left highlight on all enemies
		if not flash:
			_draw_rim_light(ex, ey, er, 0.8, e["color"].lightened(0.5))

		# Hit white flash — brief bright glow on damage
		if flash:
			var flash_a: float = clampf(e["flash_timer"] / 0.12, 0.0, 1.0)
			draw_circle(Vector2(ex, ey), er + 2, Color(1, 1, 1, flash_a * 0.35))

		# Boss border
		if e["is_boss"]:
			draw_arc(Vector2(ex, ey), er + 2, 0, TAU, 24, Color(1.0, 0.8, 0.0), 2.0)

		# Shield buff indicator — golden shimmer
		if e["shield_buff"]:
			var shield_a: float = 0.4 + 0.2 * sin(gt * 4.0)
			draw_arc(Vector2(ex, ey), er + 4, 0, TAU, 24, Color(1, 0.9, 0.5, shield_a), 2.0)
			draw_arc(Vector2(ex, ey), er + 2, 0, TAU, 16, Color(1, 0.95, 0.7, shield_a * 0.5), 1.0)

		# Slow indicator (blue ring + snowflake hint)
		if e.get("slow_timer", 0.0) > 0:
			draw_arc(Vector2(ex, ey), er + 3, 0, TAU, 16, Color(0.3, 0.5, 1.0, 0.5), 1.5)
			# Tiny ice crystal dots
			for ci in range(4):
				var ca: float = gt * 2.0 + ci * TAU / 4.0
				draw_circle(Vector2(ex + cos(ca) * (er + 3), ey + sin(ca) * (er + 3)), 1.0, Color(0.6, 0.8, 1.0, 0.4))

		# Health bar (only when damaged)
		if e["hp"] < e["max_hp"]:
			var bar_w: float = er * 2 + 4
			var bar_h: float = 3.0
			var bar_x: float = ex - bar_w / 2
			var bar_y: float = ey - er - 8
			var hp_ratio: float = e["hp"] / e["max_hp"]

			draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Config.COLOR_HEALTH_BG)
			var hp_col := Config.COLOR_HEALTH_HP if hp_ratio > 0.3 else Config.COLOR_HEALTH_LOW
			draw_rect(Rect2(bar_x, bar_y, bar_w * hp_ratio, bar_h), hp_col)

			# HP number
			var hp_text := str(roundi(e["hp"]))
			draw_string(font, Vector2(ex - 12, bar_y - 2), hp_text, HORIZONTAL_ALIGNMENT_CENTER, 24, 8, Color(1, 1, 1, 0.7))

# ═══════════════════════════════════════════════════════
# PROJECTILES
# ═══════════════════════════════════════════════════════
func _draw_projectiles() -> void:
	for p in GM.projectiles:
		if not p["alive"]:
			continue
		var px: float = p["x"]
		var py: float = p["y"]
		var dx: float = p["target_last_x"] - px
		var dy: float = p["target_last_y"] - py
		var angle: float = atan2(dy, dx)

		var tower_type: String = ""
		if p["tower"] != null and p["tower"] is Dictionary:
			tower_type = p["tower"].get("type", "")

		match tower_type:
			"bone_marksman":
				_draw_proj_arrow(px, py, angle, p["color"])
			"inferno_warlock":
				_draw_proj_fireball(px, py, p["color"])
			"soul_reaper":
				_draw_proj_necro(px, py, angle, p["color"])
			_:
				# Default — glow + core
				draw_circle(Vector2(px, py), 6, Color(p["color"].r, p["color"].g, p["color"].b, 0.3))
				draw_circle(Vector2(px, py), 3, p["color"])

func _draw_proj_arrow(px: float, py: float, angle: float, color: Color) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	var perp := Vector2(-dir.y, dir.x)
	var pos := Vector2(px, py)

	# Ember trail — 4 afterimages fading back (kept — looks great)
	for ti in range(4):
		var trail_pos := pos - dir * (5.0 + ti * 6.0)
		var trail_a := 0.25 - ti * 0.05
		var trail_r := 1.8 - ti * 0.3
		draw_circle(trail_pos, trail_r, Color(1, 0.5, 0.2, trail_a))

	# Ember particles along trail
	for ti in range(3):
		var offset := fmod(GM.game_time * 200.0 + ti * 37.0, 24.0)
		var ep := pos - dir * offset + perp * sin(GM.game_time * 10.0 + ti * 2.0) * 3.0
		draw_circle(ep, 1.0, Color(1, 0.6, 0.15, 0.3))

	# 3D arrow sprite (pre-rendered) — rotates to match flight direction
	var tex: Texture2D = CharRenderer.get_projectile_texture("arrow", angle)
	if tex != null:
		var arrow_size: float = 28.0
		var half: float = arrow_size * 0.5
		var rect := Rect2(pos.x - half, pos.y - half, arrow_size, arrow_size)
		draw_texture_rect(tex, rect, false, color)
	else:
		# Fallback: procedural triangle (original)
		var tip := pos + dir * 6
		var left := pos - dir * 5 + perp * 2.8
		var right := pos - dir * 5 - perp * 2.8
		draw_colored_polygon(PackedVector2Array([tip, left, right]), color)
		draw_circle(pos + dir * 4, 1.5, Color(1, 0.9, 0.5, 0.9))

func _draw_proj_fireball(px: float, py: float, _color: Color) -> void:
	# Inferno Warlock projectile — arcane orb wrapped in a rotating triangular
	# sigil. The trail behind it is a chain of fading violet runes that mark
	# the path of the bolt, giving the cast a sense of inscribed power rather
	# than a generic fireball.
	var pos := Vector2(px, py)
	var t: float = GM.game_time
	var pulse: float = 0.85 + 0.15 * sin(t * 10.0)

	# Sigil trail — fading rune diamonds behind the orb.  Each "frame" of the
	# trail is positioned via the projectile's stable, per-shot phase so the
	# trail visually flows even though we don't keep history.
	for ti in range(5):
		var trail_phase: float = float(ti) * 0.18
		var trail_off: float = float(ti + 1) * 4.5
		# Sway perpendicular to (rough) flight using time + index, since we
		# don't have direction here — produces a pleasant sine-snake.
		var sway: float = sin(t * 8.0 + float(ti) * 1.2) * 2.5
		var tp := Vector2(pos.x - trail_off, pos.y + sway)
		var ta: float = 0.55 - float(ti) * 0.1
		var ts: float = 1.6 - float(ti) * 0.22
		# Diamond rune
		var dpts := PackedVector2Array([
			Vector2(tp.x, tp.y - ts),
			Vector2(tp.x + ts * 0.7, tp.y),
			Vector2(tp.x, tp.y + ts),
			Vector2(tp.x - ts * 0.7, tp.y),
		])
		draw_colored_polygon(dpts, Color(0.85, 0.45, 1.0, ta * 0.55))
		# Bright center pip
		draw_circle(tp, ts * 0.35, Color(1.0, 0.85, 1.0, ta * 0.8))
		# Soft glow halo
		draw_circle(tp, ts * 1.6, Color(0.7, 0.35, 1.0, (1.0 - trail_phase) * 0.08))

	# Outer purple bloom (slightly larger, breathing)
	draw_circle(pos, 8 * pulse, Color(0.7, 0.3, 1.0, 0.13))
	draw_circle(pos, 5 * pulse, Color(0.85, 0.45, 1.0, 0.18))

	# Rotating triangular sigil cage — three vertices spinning around the orb
	var sig_spin: float = t * 5.5
	var sig_r: float = 5.5
	var cage_pts := PackedVector2Array()
	for i in range(3):
		var a: float = sig_spin + i * TAU / 3.0
		cage_pts.append(Vector2(pos.x + cos(a) * sig_r, pos.y + sin(a) * sig_r))
	for i in range(3):
		draw_line(cage_pts[i], cage_pts[(i + 1) % 3], Color(1.0, 0.75, 1.0, 0.75 * pulse), 1.0)
	# Bright vertex pips
	for i in range(3):
		draw_circle(cage_pts[i], 1.3, Color(1, 1, 1, 0.95))

	# Core — bright magenta
	draw_circle(pos, 3.2, Color(0.85, 0.4, 1.0, 0.85))
	draw_circle(pos, 2.0, Color(1.0, 0.7, 1.0, 0.95))

	# White-hot center
	draw_circle(pos, 1.0, Color(1, 1, 1, 0.95))

func _draw_proj_necro(px: float, py: float, angle: float, color: Color) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	var pos := Vector2(px, py)

	# Ghostly wisp trail
	for ti in range(3):
		var trail_pos := pos - dir * (4.0 + ti * 5.0)
		var sway := sin(GM.game_time * 8.0 + ti * 1.5) * 3.0
		trail_pos += Vector2(-dir.y, dir.x) * sway
		var trail_a := 0.3 - ti * 0.08
		draw_circle(trail_pos, 2.2 - ti * 0.4, Color(0.25, 0.9, 0.45, trail_a))

	# Outer glow
	draw_circle(pos, 5.5, Color(0.15, 0.5, 0.25, 0.2))

	# Core orb — bright green
	draw_circle(pos, 3.5, Color(0.2, 0.7, 0.35, 0.9))
	draw_circle(pos, 2.0, color)

	# Bright center
	draw_circle(pos, 1.0, Color(0.65, 1, 0.8, 0.8))

# ═══════════════════════════════════════════════════════
# EFFECTS
# ═══════════════════════════════════════════════════════
# Spawn a one-shot GPUParticles2D burst for the given effect type.
# Particles render on top of / alongside the existing procedural draw.
func _spawn_particle_for_effect(e: Dictionary, pos: Vector2) -> void:
	match e["type"]:
		"aoe":
			ParticleSpawner.spawn_aoe_burst(self, pos, e.get("radius", 60.0))
		"death":
			ParticleSpawner.spawn_death_puff(self, pos, e.get("color", Color.WHITE))
		"lucifer_wave":
			# Intentionally no burst at Lucifer's feet — the expanding wave
			# ring + halo-bloom (in _draw_tower_model) sells the cast.
			pass
		"lucifer_hit":
			ParticleSpawner.spawn_lucifer_hit(self, pos)
		"hades_wave":
			ParticleSpawner.spawn_hades_wave(self, pos, e.get("radius", 130.0))
		"ice_burst":
			ParticleSpawner.spawn_ice_burst(self, pos, e.get("radius", 10.0))
		"heal_pulse":
			ParticleSpawner.spawn_heal_pulse(self, pos)
		"michael_shield":
			ParticleSpawner.spawn_michael_shield(self, pos)
		"soul_hit":
			ParticleSpawner.spawn_soul_hit(self, pos)

func _draw_effects() -> void:
	for e in GM.effects:
		# Skip effects still in their pending/delay window — nothing drawn,
		# no particle spawn, until the delay elapses.
		if e.get("delay", 0.0) > 0.0:
			continue
		var alpha: float = clampf(e["timer"] / 0.5, 0.0, 1.0)
		var pos := Vector2(e["x"], e["y"])

		# Spawn particle burst once per effect (on first draw frame)
		if not e.get("particle_spawned", false):
			_spawn_particle_for_effect(e, pos)
			e["particle_spawned"] = true

		match e["type"]:
			"death":
				# GPU puff does the heavy lift — keep procedural to a soft fade.
				draw_circle(pos, 3.5 * alpha, Color(1, 0.95, 0.8, alpha * 0.22))
			"aoe":
				# Arcane detonation — layered shockwave: an outer expanding
				# ring, an inner trailing ring, a brief inscribed pentagram
				# at the blast center, and a quick violet-to-white core flash.
				# Reads as a deliberate ritual blast rather than a circle pop.
				var aoe_radius: float = e["radius"]
				var expand: float = (1.0 - alpha)  # 0 at spawn → 1 at end
				# Outer ring expands slightly past the radius
				var outer_r: float = aoe_radius * (0.95 + expand * 0.18)
				draw_arc(pos, outer_r, 0, TAU, 40, Color(0.95, 0.5, 1.0, alpha * 0.65), 2.2)
				# White-hot inner highlight on the leading edge
				draw_arc(pos, outer_r, 0, TAU, 40, Color(1, 1, 1, alpha * 0.25), 1.0)
				# Trailing ring — slower, deeper violet
				var trail_r: float = aoe_radius * (0.7 + expand * 0.18)
				draw_arc(pos, trail_r, 0, TAU, 32, Color(0.6, 0.25, 0.9, alpha * 0.45), 1.4)
				# Inscribed pentagram — appears strongest at spawn and fades
				var penta_a: float = alpha * 0.55
				if penta_a > 0.05:
					var penta_r: float = aoe_radius * 0.55
					var penta_pts := PackedVector2Array()
					for pi in range(5):
						var pa: float = -PI / 2.0 + pi * TAU / 5.0
						penta_pts.append(Vector2(
							pos.x + cos(pa) * penta_r,
							pos.y + sin(pa) * penta_r))
					var p_order := [0, 2, 4, 1, 3, 0]
					for li in range(p_order.size() - 1):
						draw_line(penta_pts[p_order[li]], penta_pts[p_order[li + 1]],
							Color(1.0, 0.7, 1.0, penta_a), 1.4)
					# Vertex glyph dots
					for pi in range(5):
						draw_circle(penta_pts[pi], 1.8 * alpha, Color(1, 1, 1, penta_a * 1.2))
				# Six radial scorch streaks shooting outward
				for ri in range(6):
					var ra: float = float(ri) * TAU / 6.0 + pos.x * 0.013
					var s_inner: float = aoe_radius * 0.25
					var s_outer: float = aoe_radius * (0.65 + expand * 0.45)
					draw_line(
						Vector2(pos.x + cos(ra) * s_inner, pos.y + sin(ra) * s_inner),
						Vector2(pos.x + cos(ra) * s_outer, pos.y + sin(ra) * s_outer),
						Color(1.0, 0.6, 1.0, alpha * 0.35), 1.0)
				# Center bloom — bright at spawn, fades fast
				var core_a: float = clampf(alpha * 1.4, 0.0, 1.0)
				draw_circle(pos, aoe_radius * 0.3 * (0.4 + expand * 0.4), Color(0.95, 0.55, 1.0, core_a * 0.35))
				draw_circle(pos, aoe_radius * 0.18, Color(1, 0.85, 1, core_a * 0.55))
				draw_circle(pos, aoe_radius * 0.08, Color(1, 1, 1, core_a * 0.7))
			"soul_hit":
				# Necromantic impact — a short-lived spectral burst that
				# matches Soul Reaper's ghostly green fiction instead of the
				# orange fire-spark used by physical/elemental towers. Reads
				# as: scythe bolt tears a wisp loose, bone specks scatter,
				# a cold X-shaped soul mark pops and fades.
				var soul_alpha: float = clampf(e["timer"] / 0.32, 0.0, 1.0)
				var soul_prog: float = 1.0 - soul_alpha  # 0→1 as fades out
				# Outer wisp cloud — drifts upward as it fades
				var cloud_r: float = 4.5 + soul_prog * 8.0
				var cloud_y: float = e["y"] - soul_prog * 6.0
				draw_circle(Vector2(e["x"], cloud_y), cloud_r, Color(0.25, 0.85, 0.4, soul_alpha * 0.22))
				draw_circle(Vector2(e["x"], cloud_y), cloud_r * 0.55, Color(0.5, 1.0, 0.7, soul_alpha * 0.35))
				# X-shaped soul mark — two crossing strokes that expand & fade
				var mark_r: float = 5.0 + soul_prog * 7.0
				var mx_col := Color(0.6, 1.0, 0.75, soul_alpha * 0.8)
				draw_line(
					Vector2(e["x"] - mark_r, cloud_y - mark_r),
					Vector2(e["x"] + mark_r, cloud_y + mark_r),
					mx_col, 1.4)
				draw_line(
					Vector2(e["x"] + mark_r, cloud_y - mark_r),
					Vector2(e["x"] - mark_r, cloud_y + mark_r),
					mx_col, 1.4)
				# Rising wisp tendrils — 4 curling streaks above the impact
				for wi in range(4):
					var ang: float = -PI / 2.0 + (float(wi) - 1.5) * 0.35
					var wr: float = 4.0 + soul_prog * 10.0
					var curl: float = sin(soul_prog * PI + float(wi)) * 2.5
					var wx: float = e["x"] + cos(ang) * wr + curl
					var wy: float = e["y"] + sin(ang) * wr - soul_prog * 6.0
					draw_circle(Vector2(wx, wy), 1.2 * soul_alpha + 0.4,
						Color(0.4, 1.0, 0.6, soul_alpha * 0.55))
				# Bone-chip specks radiating outward — small tan particles
				# fall with slight gravity, giving the burst weight.
				for bi in range(5):
					var ba: float = float(bi) * TAU / 5.0 + e["x"] * 0.11
					var br: float = soul_prog * 14.0
					var bhop: float = sin(soul_prog * PI) * 2.0
					var bx: float = e["x"] + cos(ba) * br
					var by: float = e["y"] + sin(ba) * br - bhop
					draw_rect(Rect2(bx - 0.8, by - 0.4, 1.6, 0.8),
						Color(0.9, 0.85, 0.65, soul_alpha * 0.8))
				# Bright spectral core flash — brief, fades fastest
				var core_a: float = clampf(soul_alpha * 1.3, 0.0, 1.0)
				draw_circle(Vector2(e["x"], e["y"]), 3.0 * core_a, Color(0.8, 1.0, 0.85, core_a * 0.55))
				draw_circle(Vector2(e["x"], e["y"]), 1.3 * core_a, Color(1, 1, 1, core_a * 0.85))
			"hit_spark":
				var spark_alpha: float = clampf(e["timer"] / 0.2, 0.0, 1.0)
				var progress: float = 1.0 - spark_alpha  # 0 at spawn → 1 at end
				# Spark lines radiating from hit — 6 short streaks
				for i in range(6):
					var sa: float = i * TAU / 6.0 + e["x"] * 0.13
					var sr: float = progress * 12.0
					var p1 := Vector2(e["x"] + cos(sa) * sr * 0.3, e["y"] + sin(sa) * sr * 0.3)
					var p2 := Vector2(e["x"] + cos(sa) * sr, e["y"] + sin(sa) * sr)
					draw_line(p1, p2, Color(1, 0.9, 0.5, spark_alpha * 0.7), 1.5)
				# Debris particles — small specks arcing outward-and-up with gravity
				for i in range(4):
					var da: float = float(i) * TAU / 4.0 + e["y"] * 0.11 + 0.4
					var dr: float = progress * 16.0
					# Slight upward hop that falls back (gravity)
					var hop: float = sin(progress * PI) * 3.0
					var dpos := Vector2(
						e["x"] + cos(da) * dr,
						e["y"] + sin(da) * dr - hop
					)
					var dsize: float = 0.9 * spark_alpha + 0.3
					draw_circle(dpos, dsize, Color(1, 0.7, 0.3, spark_alpha * 0.6))
				# Brief white flash at hit point — bloom + bright core
				draw_circle(pos, 6.0 * spark_alpha, Color(1, 0.95, 0.7, spark_alpha * 0.25))
				draw_circle(pos, 3.0 * spark_alpha, Color(1, 1, 1, spark_alpha * 0.6))
			"dmg_number":
				# Floating damage number — rises, fades, briefly pops in scale at spawn.
				# Big hits (≥ 15) get a larger gold "crit" treatment for stronger
				# reinforcement feedback (per Swink's Game Feel, feedback magnitude
				# should scale with action magnitude).
				var dmg_alpha: float = clampf(e["timer"] / 0.6, 0.0, 1.0)
				var rise: float = (1.0 - dmg_alpha) * 18.0
				var dmg_val: float = e.get("value", 0.0)
				var dmg_str: String = str(roundi(dmg_val)) if dmg_val < 10 else str(snappedf(dmg_val, 0.1))
				var life: float = 1.0 - dmg_alpha  # 0 at spawn → 1 at end
				# Brief scale pop in the first ~0.15s — up to ~1.5× at spawn
				var pop: float = 1.0 + maxf(0.0, 0.25 - life) * 2.0
				var is_big: bool = dmg_val >= 15.0
				var base_fs: int = 10 if dmg_val < 5 else (12 if dmg_val < 15 else 14)
				var font_size: int = int(float(base_fs) * pop)
				var ny: float = e["y"] - rise
				# Shadow (slightly deeper for big hits)
				var shadow_a: float = dmg_alpha * (0.7 if is_big else 0.5)
				draw_string(font, Vector2(e["x"] - 10 + 1, ny + 1), dmg_str, HORIZONTAL_ALIGNMENT_LEFT, 24, font_size, Color(0, 0, 0, shadow_a))
				# Colored text — big hits override to warm gold tint
				var nc: Color = e["color"]
				if is_big:
					nc = Color(1.0, 0.85, 0.25)
				draw_string(font, Vector2(e["x"] - 10, ny), dmg_str, HORIZONTAL_ALIGNMENT_LEFT, 24, font_size, Color(nc.r, nc.g, nc.b, dmg_alpha * 0.95))
			"relic":
				draw_string(font, Vector2(e["x"] - 8, e["y"] - (1.0 - alpha) * 20), "[!]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.8, 0, alpha))
			"corrupt":
				var expand: float = (1.0 - alpha) * 30.0
				draw_circle(pos, expand, Color(0.71, 0.2, 1.0, alpha * 0.4))
				draw_arc(pos, expand, 0, TAU, 20, Color(0.8, 0.3, 1.0, alpha * 0.5), 1.5)
			"core_hit":
				var r: float = 30 + (1.0 - alpha) * 20
				draw_circle(pos, r, Color(1, 0, 0, alpha * 0.4))
				draw_arc(pos, r, 0, TAU, 24, Color(1, 0.2, 0.1, alpha * 0.6), 2.0)
				draw_circle(pos, r * 0.4, Color(1, 0.3, 0, alpha * 0.3))
			"lucifer_hit":
				# Lightning blitz — vertical jagged bolt striking down onto the
				# enemy when Lucifer's pulse ring sweeps across them. Short-lived
				# (~0.22s) for a snappy strike, not a lingering burst.
				var hit_a: float = clampf(e["timer"] / 0.22, 0.0, 1.0)
				var er: float = e["radius"]
				var bolt_h: float = 160.0  # how far above the enemy the bolt starts
				var top := Vector2(e["x"], e["y"] - bolt_h)
				# Build a jagged polyline from top straight down to the impact.
				# Seed per-effect so each strike has a unique but stable zigzag.
				var seed_f: float = e["x"] * 0.041 + e["y"] * 0.073
				var n_segs: int = 7
				var pts := PackedVector2Array()
				pts.append(top)
				for si in range(1, n_segs):
					var t_frac: float = float(si) / float(n_segs)
					var jitter: float = sin(seed_f * 13.0 + float(si) * 4.17) * 10.0 * (1.0 - t_frac * 0.6)
					var jx: float = e["x"] + jitter
					var jy: float = e["y"] - bolt_h * (1.0 - t_frac)
					pts.append(Vector2(jx, jy))
				pts.append(pos)
				# Outer glow pass — wide, cyan-white
				for si in range(pts.size() - 1):
					draw_line(pts[si], pts[si + 1],
						Color(0.55, 0.75, 1.0, hit_a * 0.35), 4.0)
				# Mid pass — bright cyan
				for si in range(pts.size() - 1):
					draw_line(pts[si], pts[si + 1],
						Color(0.75, 0.9, 1.0, hit_a * 0.75), 2.0)
				# Hot core — white
				for si in range(pts.size() - 1):
					draw_line(pts[si], pts[si + 1],
						Color(1.0, 1.0, 1.0, hit_a), 1.0)
				# Ground impact flash + small radial sparks
				draw_circle(pos, er * 0.9, Color(0.7, 0.85, 1.0, hit_a * 0.35))
				draw_circle(pos, er * 0.45, Color(1, 1, 1, hit_a * 0.75))
				for si in range(4):
					var sa: float = si * TAU / 4.0 + seed_f
					var sr: float = er + (1.0 - hit_a) * 10.0
					draw_line(pos,
						Vector2(e["x"] + cos(sa) * sr, e["y"] + sin(sa) * sr),
						Color(0.8, 0.9, 1.0, hit_a * 0.45), 1.0)
			"lucifer_wave":
				# Expanding pulse ring from Lucifer's position — cyan/electric to
				# match the lightning-bolt strikes it triggers on crossing enemies.
				# Map diagonal is ~960 px (768×576), so ring must reach 1000 px.
				var wave_alpha: float = clampf(e["timer"] / 1.2, 0.0, 1.0)
				var progress: float = 1.0 - wave_alpha  # 0→1 as wave expands
				var max_r: float = 1000.0
				var wave_r: float = progress * max_r
				# Leading edge ring — bright cyan
				draw_arc(pos, wave_r, 0, TAU, 48, Color(0.6, 0.85, 1.0, wave_alpha * 0.38), 1.6)
				# White-hot inner stroke on the leading edge
				draw_arc(pos, wave_r, 0, TAU, 48, Color(1, 1, 1, wave_alpha * 0.2), 0.8)
				# Trailing ring — deeper blue
				if wave_r > 15:
					draw_arc(pos, wave_r - 10, 0, TAU, 36, Color(0.35, 0.55, 1.0, wave_alpha * 0.15), 1.0)
			"hades_wave":
				# Ritual empowerment — 6-point arcane glyph at Hades's feet (not a shockwave)
				var hw_alpha: float = clampf(e["timer"] / 0.6, 0.0, 1.0)
				var glyph_r: float = 22.0
				# Outer glyph circle — gently pulses, doesn't expand outward
				var glyph_col := Color(0.75, 0.55, 1.0, hw_alpha * 0.55)
				draw_arc(pos, glyph_r, 0, TAU, 32, glyph_col, 1.8)
				draw_arc(pos, glyph_r * 0.65, 0, TAU, 24, Color(0.85, 0.7, 1.0, hw_alpha * 0.35), 1.2)
				# 6 runic points on the glyph — form a hex pattern that rotates slowly
				var spin: float = GM.game_time * 0.8
				for pi in range(6):
					var pa: float = spin + pi * TAU / 6.0
					var px: float = pos.x + cos(pa) * glyph_r
					var py: float = pos.y + sin(pa) * glyph_r
					draw_circle(Vector2(px, py), 2.2, Color(1.0, 0.95, 1.0, hw_alpha * 0.85))
					# connect to next point with a thin line
					var pa_next: float = spin + (pi + 1) * TAU / 6.0
					var nx: float = pos.x + cos(pa_next) * glyph_r
					var ny: float = pos.y + sin(pa_next) * glyph_r
					draw_line(Vector2(px, py), Vector2(nx, ny), Color(0.8, 0.65, 1.0, hw_alpha * 0.35), 1.0)
				# Soft center pulse
				draw_circle(pos, 5 * hw_alpha, Color(0.95, 0.85, 1.0, hw_alpha * 0.5))
			"hades_beam":
				# Thin pulsing arcane tendril from Hades to a buffed tower
				var hb_alpha: float = clampf(e["timer"] / 0.5, 0.0, 1.0)
				var bx2: float = e.get("x2", e["x"])
				var by2: float = e.get("y2", e["y"])
				var beam_pulse: float = 0.7 + 0.3 * sin(GM.game_time * 20.0)
				# Outer glow
				draw_line(Vector2(e["x"], e["y"]), Vector2(bx2, by2),
					Color(0.75, 0.55, 1.0, hb_alpha * 0.2 * beam_pulse), 5)
				# Main beam
				draw_line(Vector2(e["x"], e["y"]), Vector2(bx2, by2),
					Color(0.85, 0.7, 1.0, hb_alpha * 0.75), 2.0)
				# Bright core
				draw_line(Vector2(e["x"], e["y"]), Vector2(bx2, by2),
					Color(1.0, 0.95, 1.0, hb_alpha * 0.9), 1.0)
				# 3 tiny sparks traveling along the beam
				for si in range(3):
					var sp: float = fmod(GM.game_time * 2.5 + float(si) * 0.33, 1.0)
					var sx: float = e["x"] + (bx2 - e["x"]) * sp
					var sy: float = e["y"] + (by2 - e["y"]) * sp
					draw_circle(Vector2(sx, sy), 2.0, Color(1.0, 0.95, 1.0, hb_alpha * 0.9))
			"hades_curse":
				# Jagged crimson curse-bolt from Hades to an enemy.
				var hc_alpha: float = clampf(e["timer"] / 0.5, 0.0, 1.0)
				var x1: float = e["x"]
				var y1: float = e["y"]
				var cx2: float = e.get("x2", x1)
				var cy2: float = e.get("y2", y1)
				var dx_c: float = cx2 - x1
				var dy_c: float = cy2 - y1
				var dist_c: float = sqrt(dx_c * dx_c + dy_c * dy_c)
				if dist_c >= 0.5:
					var perp_x: float = -dy_c / dist_c
					var perp_y: float = dx_c / dist_c
					# Build jagged polyline with 4 segments; zigzag shape is stable
					# per-effect (seeded by endpoint position).
					var zig_seed: float = x1 * 0.013 + cy2 * 0.017
					var n_segs: int = 4
					var pts := PackedVector2Array()
					pts.append(Vector2(x1, y1))
					for i in range(1, n_segs):
						var t: float = float(i) / float(n_segs)
						var main_x: float = x1 + dx_c * t
						var main_y: float = y1 + dy_c * t
						var sign_v: float = 1.0 if ((i + int(zig_seed * 7.0)) % 2) == 0 else -1.0
						var amp: float = 4.5 * sin(t * PI)
						pts.append(Vector2(main_x + perp_x * amp * sign_v,
							main_y + perp_y * amp * sign_v))
					pts.append(Vector2(cx2, cy2))
					var curse_pulse: float = 0.7 + 0.3 * sin(GM.game_time * 26.0)
					for i in range(pts.size() - 1):
						var a: Vector2 = pts[i]
						var b: Vector2 = pts[i + 1]
						# Outer hellfire glow
						draw_line(a, b, Color(1.0, 0.15, 0.2, hc_alpha * 0.25 * curse_pulse), 5.0)
						# Main crimson bolt
						draw_line(a, b, Color(1.0, 0.3, 0.45, hc_alpha * 0.85), 2.0)
						# Bright hot core
						draw_line(a, b, Color(1.0, 0.9, 0.7, hc_alpha * 0.9), 1.0)
					# Impact burst at the enemy end
					draw_circle(Vector2(cx2, cy2), 5.5 * hc_alpha, Color(1.0, 0.25, 0.3, hc_alpha * 0.45))
					draw_circle(Vector2(cx2, cy2), 2.5 * hc_alpha, Color(1.0, 0.9, 0.7, hc_alpha * 0.9))
			"zeus_bolt":
				# Lightning bolt from Zeus to a tower — jagged line
				var bolt_alpha: float = clampf(e["timer"] / 0.4, 0.0, 1.0)
				var x1: float = e["x"]
				var y1: float = e["y"]
				var x2: float = e.get("x2", x1)
				var y2: float = e.get("y2", y1)
				var dx_b: float = x2 - x1
				var dy_b: float = y2 - y1
				# Draw jagged bolt with 5 segments
				var prev := Vector2(x1, y1)
				for si in range(5):
					var frac: float = float(si + 1) / 5.0
					var next := Vector2(x1 + dx_b * frac, y1 + dy_b * frac)
					if si < 4:  # jag the middle segments
						next.x += sin(si * 3.7 + e["timer"] * 20.0) * 8.0
						next.y += cos(si * 2.3 + e["timer"] * 15.0) * 6.0
					# Bright core
					draw_line(prev, next, Color(1, 1, 0.85, bolt_alpha * 0.9), 2.5)
					# Outer glow
					draw_line(prev, next, Color(0.6, 0.7, 1.0, bolt_alpha * 0.3), 5.0)
					prev = next
				# Impact flash at tower
				draw_circle(Vector2(x2, y2), 10 * bolt_alpha, Color(0.7, 0.8, 1.0, bolt_alpha * 0.3))
				draw_circle(Vector2(x2, y2), 5 * bolt_alpha, Color(1, 1, 0.9, bolt_alpha * 0.5))
			"michael_shield":
				# Golden dome expanding from Michael's position
				var ms_alpha: float = clampf(e["timer"] / 0.8, 0.0, 1.0)
				var dome_r: float = (1.0 - ms_alpha) * 300.0
				# Expanding golden ring
				draw_arc(pos, dome_r, 0, TAU, 48, Color(1, 0.9, 0.5, ms_alpha * 0.4), 2.0)
				# Inner shimmer ring
				if dome_r > 20:
					draw_arc(pos, dome_r - 15, 0, TAU, 36, Color(1, 0.95, 0.7, ms_alpha * 0.2), 1.0)
				# Small cross symbols along the ring
				for ci in range(8):
					var ca: float = ci * TAU / 8.0
					var cx_ms: float = pos.x + cos(ca) * dome_r
					var cy_ms: float = pos.y + sin(ca) * dome_r
					draw_line(Vector2(cx_ms - 3, cy_ms), Vector2(cx_ms + 3, cy_ms), Color(1, 0.95, 0.7, ms_alpha * 0.4), 1.0)
					draw_line(Vector2(cx_ms, cy_ms - 3), Vector2(cx_ms, cy_ms + 3), Color(1, 0.95, 0.7, ms_alpha * 0.4), 1.0)
			"screen_flash":
				var col: Color = e["color"]
				col.a = alpha * 0.3
				draw_rect(Rect2(0, 0, Config.GAME_WIDTH, Config.GAME_HEIGHT), col)
			"frost_spike":
				# Ice spike (冰锥) flying from tower to target
				var sx2: float = e.get("x2", e["x"])
				var sy2: float = e.get("y2", e["y"])
				var stacks: float = e["radius"]
				# Spike travels from source to target over effect lifetime
				var progress: float = 1.0 - alpha  # 0→1 as time passes
				var spike_x: float = e["x"] + (sx2 - e["x"]) * progress
				var spike_y: float = e["y"] + (sy2 - e["y"]) * progress
				# Direction angle for spike orientation
				var dx: float = sx2 - e["x"]
				var dy: float = sy2 - e["y"]
				var angle: float = atan2(dy, dx)
				var spike_len: float = 8.0 + stacks * 3.0
				var spike_w: float = 2.5 + stacks * 0.8
				# Icicle shape: pointed triangle
				var tip := Vector2(spike_x + cos(angle) * spike_len, spike_y + sin(angle) * spike_len)
				var left := Vector2(spike_x + cos(angle + PI / 2) * spike_w, spike_y + sin(angle + PI / 2) * spike_w)
				var right := Vector2(spike_x + cos(angle - PI / 2) * spike_w, spike_y + sin(angle - PI / 2) * spike_w)
				var tail := Vector2(spike_x - cos(angle) * spike_len * 0.4, spike_y - sin(angle) * spike_len * 0.4)
				# Outer frost glow
				draw_circle(Vector2(spike_x, spike_y), spike_len * 0.6, Color(0.5, 0.8, 1.0, alpha * 0.12))
				# Main ice spike body
				draw_colored_polygon(PackedVector2Array([tip, left, tail, right]), Color(0.6, 0.85, 1.0, alpha * 0.9))
				# Inner bright core
				var inner_tip := Vector2(spike_x + cos(angle) * spike_len * 0.7, spike_y + sin(angle) * spike_len * 0.7)
				var inner_l := Vector2(spike_x + cos(angle + PI / 2) * spike_w * 0.4, spike_y + sin(angle + PI / 2) * spike_w * 0.4)
				var inner_r := Vector2(spike_x + cos(angle - PI / 2) * spike_w * 0.4, spike_y + sin(angle - PI / 2) * spike_w * 0.4)
				draw_colored_polygon(PackedVector2Array([inner_tip, inner_l, inner_r]), Color(0.85, 0.95, 1.0, alpha * 0.7))
				# Frost trail particles behind
				for ti in range(3):
					var trail_prog: float = maxf(0, progress - float(ti + 1) * 0.1)
					var trail_x: float = e["x"] + (sx2 - e["x"]) * trail_prog
					var trail_y: float = e["y"] + (sy2 - e["y"]) * trail_prog
					var trail_a: float = alpha * (0.3 - float(ti) * 0.08)
					draw_circle(Vector2(trail_x, trail_y), 1.5 - float(ti) * 0.3, Color(0.6, 0.85, 1.0, trail_a))
			"ice_burst":
				# Ice crystal burst at impact (expanding frost ring + shards + shatter lines)
				var burst_r: float = e["radius"] * (1.0 + (1.0 - alpha) * 0.5)
				# Frost ring
				draw_arc(pos, burst_r, 0, TAU, 20, Color(0.6, 0.85, 1.0, alpha * 0.6), 2.0)
				draw_arc(pos, burst_r * 0.6, 0, TAU, 16, Color(0.75, 0.92, 1.0, alpha * 0.3), 1.0)
				# Shatter lines radiating outward — sharp cracks through the ring
				for li in range(8):
					var la: float = float(li) * TAU / 8.0 + e["y"] * 0.09
					var l_inner: float = burst_r * 0.35
					var l_outer: float = burst_r * (1.0 + (1.0 - alpha) * 0.3)
					var lp1 := Vector2(pos.x + cos(la) * l_inner, pos.y + sin(la) * l_inner)
					var lp2 := Vector2(pos.x + cos(la) * l_outer, pos.y + sin(la) * l_outer)
					draw_line(lp1, lp2, Color(0.85, 0.95, 1.0, alpha * 0.5), 1.0)
				# Ice shard particles radiating outward (pointed triangles)
				for si in range(6):
					var sa: float = float(si) * TAU / 6.0 + 0.3
					var sr: float = burst_r * 0.5 + (1.0 - alpha) * 6.0
					var shard_pos := Vector2(pos.x + cos(sa) * sr, pos.y + sin(sa) * sr)
					var shard_dir := Vector2(cos(sa), sin(sa))
					var shard_perp := Vector2(-shard_dir.y, shard_dir.x)
					var shard_pts := PackedVector2Array([
						shard_pos + shard_dir * 2.5,
						shard_pos + shard_perp * 0.9,
						shard_pos - shard_perp * 0.9,
					])
					draw_colored_polygon(shard_pts, Color(0.8, 0.95, 1.0, alpha * 0.6))
				# Center flash
				draw_circle(pos, 3 * alpha, Color(0.9, 0.97, 1.0, alpha * 0.5))
			"heal_beam":
				# Green healing beam
				var hx2: float = e.get("x2", e["x"])
				var hy2: float = e.get("y2", e["y"])
				draw_line(Vector2(e["x"], e["y"]), Vector2(hx2, hy2), Color(0.3, 0.9, 0.4, alpha * 0.15), 5)
				draw_line(Vector2(e["x"], e["y"]), Vector2(hx2, hy2), Color(0.4, 1.0, 0.5, alpha * 0.6), 2)
				draw_line(Vector2(e["x"], e["y"]), Vector2(hx2, hy2), Color(0.7, 1.0, 0.8, alpha * 0.4), 1)
			"heal_pulse":
				# Expanding green healing ring
				var hr: float = e["radius"] + (1.0 - alpha) * 8.0
				draw_arc(pos, hr, 0, TAU, 16, Color(0.4, 1.0, 0.5, alpha * 0.5), 1.5)
				draw_circle(pos, 3 * alpha, Color(0.5, 1.0, 0.6, alpha * 0.4))

# ═══════════════════════════════════════════════════════
# PLACEMENT PREVIEW
# ═══════════════════════════════════════════════════════
func _draw_placement_preview() -> void:
	if GM.selected_tower_type == "" or GM.hovered_grid.x < 0:
		return

	var col: int = GM.hovered_grid.x
	var row: int = GM.hovered_grid.y
	var px: float = col * T
	var py: float = row * T

	var can_place := GM.is_buildable(col, row)

	# Highlight tile
	var tile_col := Config.COLOR_PREVIEW_OK if can_place else Config.COLOR_PREVIEW_BAD
	draw_rect(Rect2(px, py, T, T), tile_col)

	# Range preview + avatar
	if can_place:
		var data: Dictionary = Config.TOWER_DATA[GM.selected_tower_type]
		var center := Vector2(px + T / 2.0, py + T / 2.0)

		# REDESIGN: Cocytus shows a rotatable cone preview (not a circle)
		if data.get("is_beam_cone", false):
			# Auto-pick best facing when hover tile changes (unless player rotated)
			var curr_grid := Vector2i(col, row)
			if not GM.preview_cone_manual and curr_grid != GM.preview_cone_last_grid:
				GM.preview_cone_facing = GM._best_cone_facing(
					center.x, center.y, data["range"], data["cone_half_angle"])
				GM.preview_cone_last_grid = curr_grid
			var preview_tower_coc := {
				"type": GM.selected_tower_type,
				"range": data["range"],
				"facing_angle": GM.preview_cone_facing,
			}
			_draw_cone_overlay(preview_tower_coc, center.x, center.y, 0.7)
			# Rotation hint text below tile
			draw_string(font, Vector2(px - 20, py + T + 14),
				"Q / E to rotate",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.7))
		else:
			draw_circle(center, data["range"], Config.COLOR_RANGE)
			draw_arc(center, data["range"], 0, TAU, 48, Config.COLOR_RANGE_BORDER, 1.0)

		# Tower model preview (semi-transparent)
		var preview_tower := {"type": GM.selected_tower_type, "color": Config.TOWER_DATA[GM.selected_tower_type]["color"]}
		_draw_tower_model(preview_tower, center.x, center.y, 0.4)

# ═══════════════════════════════════════════════════════
# NOTIFICATIONS
# ═══════════════════════════════════════════════════════
# ═══════════════════════════════════════════════════════
# OVERVIEW (Tab held)
# ═══════════════════════════════════════════════════════
func _draw_overview() -> void:
	# Dim the game slightly
	draw_rect(Rect2(0, 0, Config.GAME_WIDTH, Config.GAME_HEIGHT), Color(0, 0, 0, 0.3))

	for t in GM.towers:
		var cx: float = t["x"]
		var cy: float = t["y"]
		var total_dmg: float = t.get("total_damage", 0.0)
		var kills: int = t.get("kill_count", 0)

		# Background panel behind text
		var panel_w: float = 52.0
		var panel_h: float = 30.0
		var px: float = cx - panel_w / 2.0
		var py: float = cy - 28
		draw_rect(Rect2(px, py, panel_w, panel_h), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(px, py, panel_w, panel_h), Color(t["color"].r, t["color"].g, t["color"].b, 0.4), false, 1.0)

		# Damage text
		var dmg_str: String
		if total_dmg >= 1000:
			dmg_str = str(snappedf(total_dmg / 1000.0, 0.1)) + "k"
		else:
			dmg_str = str(roundi(total_dmg))
		draw_string(font, Vector2(px + 2, py + 12), dmg_str, HORIZONTAL_ALIGNMENT_LEFT, 48, 11, Color(1, 0.8, 0.3))

		# Kills text
		draw_string(font, Vector2(px + 2, py + 25), Locale.tf("overview_kills", {"count": kills}), HORIZONTAL_ALIGNMENT_LEFT, 48, 9, Color(0.7, 0.7, 0.7))

		# Tower role label (below stats panel)
		if t.get("is_global", false):
			draw_string(font, Vector2(px, py + 38), Locale.t("GLOBAL"), HORIZONTAL_ALIGNMENT_LEFT, 48, 8, Color(t["color"].r, t["color"].g, t["color"].b, 0.5))
		elif t.get("is_support", false):
			draw_string(font, Vector2(px, py + 38), Locale.t("SUPPORT"), HORIZONTAL_ALIGNMENT_LEFT, 48, 8, Color(t["color"].r, t["color"].g, t["color"].b, 0.5))

# ═══════════════════════════════════════════════════════
# WAVE ANNOUNCEMENT BANNER
# Cinematic title card — "WAVE N" + description sweeps in from the left,
# holds briefly, then fades out. Boss waves flip to a crimson palette.
# Entirely diegetic-free (pure HUD), but uses the same horizontal bar
# motif as the wave_complete audio cue so the two events feel linked.
# ═══════════════════════════════════════════════════════
func _draw_wave_banner() -> void:
	if GM.wave_banner_timer <= 0.0 or GM.wave_banner_num <= 0:
		return
	var total: float = GM.WAVE_BANNER_DURATION
	var t_left: float = GM.wave_banner_timer
	var elapsed: float = total - t_left
	# Three-phase envelope: slide-in (0.35s), hold (~1.55s), fade-out (0.7s).
	var slide_in: float = 0.35
	var fade_out: float = 0.7
	var hold_end: float = total - fade_out
	var alpha: float = 1.0
	var slide: float = 0.0  # 0 = fully on-screen, +/- pushes off-screen
	if elapsed < slide_in:
		var p: float = elapsed / slide_in
		# Ease-out cubic for satisfying decel
		var eased: float = 1.0 - pow(1.0 - p, 3.0)
		alpha = eased
		slide = (1.0 - eased) * -140.0   # slide in from the left
	elif elapsed > hold_end:
		var p: float = (elapsed - hold_end) / fade_out
		alpha = clampf(1.0 - p, 0.0, 1.0)
		slide = p * 140.0                # exit toward the right

	var W: float = Config.GAME_WIDTH
	var H: float = Config.GAME_HEIGHT
	var cy: float = H * 0.42
	var bar_w: float = 560.0
	var bar_h: float = 62.0
	var bx: float = (W - bar_w) / 2.0 + slide
	var by: float = cy - bar_h / 2.0
	var is_boss: bool = GM.wave_banner_is_boss
	var accent: Color = Color(1.0, 0.2, 0.18) if is_boss else Color(1.0, 0.75, 0.15)
	var bg_top: Color = Color(0.06, 0.02, 0.02, 0.78 * alpha) if is_boss else Color(0.04, 0.02, 0.06, 0.78 * alpha)

	# Background band with feathered left/right edges using three rectangles
	# (outer tinted accent edges, center solid).
	var feather: float = 44.0
	# Solid middle
	draw_rect(Rect2(bx + feather, by, bar_w - feather * 2.0, bar_h), bg_top)
	# Left feather (linear fade via 4 steps)
	for fi in range(4):
		var fx0: float = bx + feather * (float(fi) / 4.0)
		var fa: float = float(fi + 1) / 5.0
		var fc := Color(bg_top.r, bg_top.g, bg_top.b, bg_top.a * fa)
		draw_rect(Rect2(fx0, by, feather / 4.0, bar_h), fc)
	# Right feather
	for fi in range(4):
		var fx0: float = bx + bar_w - feather + feather * (float(fi) / 4.0)
		var fa: float = 1.0 - float(fi) / 5.0
		var fc := Color(bg_top.r, bg_top.g, bg_top.b, bg_top.a * fa)
		draw_rect(Rect2(fx0, by, feather / 4.0, bar_h), fc)
	# Top + bottom accent bars
	draw_rect(Rect2(bx + feather * 0.5, by, bar_w - feather, 2.0),
		Color(accent.r, accent.g, accent.b, alpha * 0.9))
	draw_rect(Rect2(bx + feather * 0.5, by + bar_h - 2.0, bar_w - feather, 2.0),
		Color(accent.r, accent.g, accent.b, alpha * 0.9))
	# Decorative diamonds on either end
	var dia_pts := PackedVector2Array()
	var dia_cy: float = by + bar_h / 2.0
	var dia_r: float = 6.0
	for side in [-1, 1]:
		var dcx: float = bx + bar_w / 2.0 + float(side) * (bar_w / 2.0 - feather * 0.35)
		dia_pts.clear()
		dia_pts.append(Vector2(dcx, dia_cy - dia_r))
		dia_pts.append(Vector2(dcx + dia_r, dia_cy))
		dia_pts.append(Vector2(dcx, dia_cy + dia_r))
		dia_pts.append(Vector2(dcx - dia_r, dia_cy))
		draw_colored_polygon(dia_pts, Color(accent.r, accent.g, accent.b, alpha * 0.9))

	# WAVE N — large header
	var wave_text: String
	if is_boss:
		wave_text = "BOSS WAVE " + str(GM.wave_banner_num)
	else:
		wave_text = "WAVE " + str(GM.wave_banner_num)
	var text_col: Color = Color(1.0, 0.92, 0.8, alpha) if not is_boss else Color(1.0, 0.85, 0.85, alpha)
	# Drop shadow
	draw_string(font, Vector2(bx + 1, by + 26 + 1), wave_text, HORIZONTAL_ALIGNMENT_CENTER, bar_w, 22, Color(0, 0, 0, alpha * 0.7))
	draw_string(font, Vector2(bx, by + 26), wave_text, HORIZONTAL_ALIGNMENT_CENTER, bar_w, 22, text_col)

	# Description subtitle — translated wave_desc
	var desc_text: String = Locale.t(GM.wave_banner_desc)
	var desc_col: Color = Color(accent.r, accent.g, accent.b, alpha * 0.85)
	draw_string(font, Vector2(bx + 1, by + 50 + 1), desc_text, HORIZONTAL_ALIGNMENT_CENTER, bar_w, 12, Color(0, 0, 0, alpha * 0.6))
	draw_string(font, Vector2(bx, by + 50), desc_text, HORIZONTAL_ALIGNMENT_CENTER, bar_w, 12, desc_col)

func _draw_notifications() -> void:
	var W: float = Config.GAME_WIDTH
	for i in range(GM.notifications.size()):
		var n: Dictionary = GM.notifications[i]
		var alpha: float = clampf(n["timer"], 0.0, 1.0)
		# Draw at top of game area, below the 50px top bar, stacking downward
		var ny: float = 65 + i * 20

		# Shadow
		var shadow_col := Color(0, 0, 0, alpha)
		draw_string(font, Vector2(W / 2.0 - 200 + 1, ny + 1), n["text"], HORIZONTAL_ALIGNMENT_CENTER, 400, 13, shadow_col)
		# Text
		var text_col: Color = n["color"]
		text_col.a = alpha
		draw_string(font, Vector2(W / 2.0 - 200, ny), n["text"], HORIZONTAL_ALIGNMENT_CENTER, 400, 13, text_col)

# ═══════════════════════════════════════════════════════
# DICE RESULT OVERLAY
# ═══════════════════════════════════════════════════════
func _draw_dice_result() -> void:
	if not GM.show_dice_result or GM.dice_result.is_empty():
		return

	var r: Dictionary = GM.dice_result
	var alpha: float = clampf(GM.dice_result_timer / 0.8, 0.0, 1.0)
	var W: float = Config.GAME_WIDTH
	var H: float = Config.GAME_HEIGHT
	var outcome: Dictionary = r["outcome"]
	var is_good: bool = outcome["positive"]

	# Background overlay
	var bg_col := Color(0.05, 0.12, 0.0, 0.7 * alpha) if is_good else Color(0.15, 0.02, 0.02, 0.7 * alpha)
	draw_rect(Rect2(W / 2 - 180, H / 2 - 90, 360, 190), bg_col)

	# Border glow
	var border_col := Color(0.3, 0.9, 0.3, 0.5 * alpha) if is_good else Color(0.9, 0.2, 0.2, 0.5 * alpha)
	draw_rect(Rect2(W / 2 - 180, H / 2 - 90, 360, 190), border_col, false, 2.0)

	# Draw the die face — centered in top portion of overlay
	var die_cx: float = W / 2.0
	var die_cy: float = H / 2.0 - 40.0
	_draw_die_face(die_cx, die_cy, r["d1"], 50.0, alpha, is_good)

	# Outcome name — colored, below die
	var name_col := Color(0.3, 1.0, 0.3, alpha) if is_good else Color(1.0, 0.3, 0.3, alpha)
	draw_string(font, Vector2(W / 2 - 150, H / 2 + 30), Locale.t(outcome["name"]), HORIZONTAL_ALIGNMENT_CENTER, 300, 20, name_col)

	# Effect description
	var desc_text: String = Locale.t(outcome.get("desc", ""))
	var desc_col := Color(0.85, 0.95, 0.85, alpha * 0.9) if is_good else Color(0.95, 0.75, 0.75, alpha * 0.9)
	draw_string(font, Vector2(W / 2 - 150, H / 2 + 60), desc_text, HORIZONTAL_ALIGNMENT_CENTER, 300, 13, desc_col)

	# Devil's Dice label at bottom
	var icon_text := "+" if is_good else "!"
	var icon_col := Color(0.3, 1.0, 0.3, alpha) if is_good else Color(1.0, 0.3, 0.15, alpha)
	draw_string(font, Vector2(W / 2 - 150, H / 2 + 82), icon_text + " " + (Locale.t("DEVIL'S DICE") if Locale.current_lang == "zh" else "DEVIL'S DICE"), HORIZONTAL_ALIGNMENT_CENTER, 300, 10, icon_col * 0.6)

func _draw_die_face(cx: float, cy: float, value: int, size: float, alpha: float, is_good: bool) -> void:
	var half: float = size / 2.0
	var r: float = size * 0.15  # corner radius

	# Die body shadow
	draw_rect(Rect2(cx - half + 2, cy - half + 2, size, size), Color(0.0, 0.0, 0.0, alpha * 0.4), true, -1.0, r)

	# Die body — dark with colored tint
	var body_col := Color(0.12, 0.06, 0.06, alpha) if not is_good else Color(0.06, 0.1, 0.06, alpha)
	draw_rect(Rect2(cx - half, cy - half, size, size), body_col, true, -1.0, r)

	# Inner face — slightly lighter
	var face_col := Color(0.18, 0.08, 0.08, alpha) if not is_good else Color(0.1, 0.16, 0.1, alpha)
	draw_rect(Rect2(cx - half + 3, cy - half + 3, size - 6, size - 6), face_col, true, -1.0, r * 0.7)

	# Glowing border
	var edge_col := Color(0.9, 0.25, 0.15, alpha * 0.6) if not is_good else Color(0.25, 0.9, 0.25, alpha * 0.6)
	draw_rect(Rect2(cx - half, cy - half, size, size), edge_col, false, 1.5, r)

	# Corner fire wisps
	var wisp_a: float = alpha * 0.3 * (0.5 + 0.5 * sin(GM.game_time * 4.0))
	var wisp_col := Color(1.0, 0.4, 0.1, wisp_a) if not is_good else Color(0.3, 1.0, 0.4, wisp_a)
	draw_circle(Vector2(cx - half, cy - half), 4, wisp_col)
	draw_circle(Vector2(cx + half, cy - half), 4, wisp_col)
	draw_circle(Vector2(cx - half, cy + half), 4, wisp_col)
	draw_circle(Vector2(cx + half, cy + half), 4, wisp_col)

	# Pip positions for standard die faces
	var pip_r: float = size * 0.075
	var pip_glow_r: float = pip_r * 2.0
	var pip_col := Color(1.0, 0.85, 0.65, alpha)
	var pip_glow := Color(1.0, 0.6, 0.2, alpha * 0.3) if not is_good else Color(0.4, 1.0, 0.5, alpha * 0.3)
	var d: float = size * 0.28  # offset from center for pip grid

	var pips: Array[Vector2] = []
	match value:
		1:
			pips = [Vector2(cx, cy)]
		2:
			pips = [Vector2(cx - d, cy - d), Vector2(cx + d, cy + d)]
		3:
			pips = [Vector2(cx - d, cy - d), Vector2(cx, cy), Vector2(cx + d, cy + d)]
		4:
			pips = [Vector2(cx - d, cy - d), Vector2(cx + d, cy - d),
					Vector2(cx - d, cy + d), Vector2(cx + d, cy + d)]
		5:
			pips = [Vector2(cx - d, cy - d), Vector2(cx + d, cy - d),
					Vector2(cx, cy),
					Vector2(cx - d, cy + d), Vector2(cx + d, cy + d)]
		6:
			pips = [Vector2(cx - d, cy - d), Vector2(cx + d, cy - d),
					Vector2(cx - d, cy), Vector2(cx + d, cy),
					Vector2(cx - d, cy + d), Vector2(cx + d, cy + d)]

	# Draw pips with glow
	for p in pips:
		draw_circle(p, pip_glow_r, pip_glow)
		draw_circle(p, pip_r, pip_col)
		draw_circle(p, pip_r * 0.5, Color(1, 1, 1, alpha * 0.6))


# ═══════════════════════════════════════════════════════
# 3D MODEL AVATARS
# ═══════════════════════════════════════════════════════

# Rotation speed for character facing — radians per second.
# ~10 rad/sec ≈ one full revolution in 0.6s, snappy but not instant.
const FACING_TURN_SPEED := 10.0

# Interpolates `current` angle toward `target` by at most `max_delta` radians,
# taking the shortest path around the unit circle.
func _smooth_angle(current: float, target: float, max_delta: float) -> float:
	var delta: float = wrapf(target - current, -PI, PI)
	if absf(delta) <= max_delta:
		return target
	return current + signf(delta) * max_delta

# Called each frame to smoothly rotate tower/enemy facing angles toward their
# current target/movement direction. Runs in _process (not _draw) so we have dt.
func _nearest_enemy_to(tx: float, ty: float):
	var best = null
	var best_d2: float = INF
	for e in GM.enemies:
		if not e["alive"]:
			continue
		var dx: float = e["x"] - tx
		var dy: float = e["y"] - ty
		var d2: float = dx * dx + dy * dy
		if d2 < best_d2:
			best_d2 = d2
			best = e
	return best

func _update_facing_angles(dt: float) -> void:
	var max_turn: float = FACING_TURN_SPEED * dt

	# Towers face their current target. Support (Hades) and global (Lucifer)
	# towers don't track a single target, so for them we face the nearest live
	# enemy — otherwise they'd stare in one fixed direction forever.
	# Lucifer spins 360° while fire_flash is burning down (cast window) —
	# Rig_Large has no cast animation, so this reads the "channeling" beat
	# using the pre-rendered idle angles.
	const LUCIFER_SPIN_DUR := 0.3
	for t in GM.towers:
		if t.get("type", "") == "lucifer" and t.get("fire_flash", 0.0) > 0.0:
			var spin_speed: float = TAU / LUCIFER_SPIN_DUR
			t["facing_angle"] = t.get("facing_angle", 0.0) + spin_speed * dt
			continue
		var target = t.get("target")
		var needs_autoaim: bool = t.get("is_support", false) or t.get("is_global", false)
		if needs_autoaim:
			target = _nearest_enemy_to(t["x"], t["y"])
		if target == null or not (target is Dictionary) or not target.get("alive", false):
			continue
		var dx: float = target["x"] - t["x"]
		var dy: float = target["y"] - t["y"]
		if dx * dx + dy * dy < 0.01:
			continue
		var target_angle: float = _screen_to_model_angle(dx, dy)
		var current: float = t.get("facing_angle", target_angle)
		t["facing_angle"] = _smooth_angle(current, target_angle, max_turn)

	# Enemies face the waypoint they are currently walking toward.
	# path_index is the waypoint the enemy is moving toward — using path_index
	# (not path_index + 1) means they turn only when they reach a corner.
	var path_px: Array[Vector2] = Config.path_pixels
	for e in GM.enemies:
		if not e["alive"]:
			continue
		var path_idx: int = e.get("path_index", 0)
		if path_idx < 0 or path_idx >= path_px.size():
			continue
		var target_pt: Vector2 = path_px[path_idx]
		var dx: float = target_pt.x - e["x"]
		var dy: float = target_pt.y - e["y"]
		if dx * dx + dy * dy < 0.01:
			continue
		var target_angle: float = _screen_to_model_angle(dx, dy)
		# Initialize to target on first frame to avoid spinning from 0
		var current: float = e.get("facing_angle", target_angle)
		e["facing_angle"] = _smooth_angle(current, target_angle, max_turn)

# Converts a 2D screen-space direction (dx, dy) to the Y-axis angle
# that the 3D model should face.
#
# Camera setup: position (1.2, 1.6, 1.2) looking at (0, 0.45, 0).
# Camera's right axis in world = (0.707, 0, -0.707)
# Ground-plane projection (y=0):
#   screen_dx = 0.707 * (dX - dZ)
#   screen_dy = 0.397 * (dX + dZ)   (screen +Y is down in 2D)
#
# KayKit models' default forward is +Z (verified from angle-0 preview).
# At rotation.y = θ, forward = (sin(θ), 0, cos(θ)).
# Solving dx/dy ratio gives:
#   θ = atan2(dx + 1.785*dy, 1.785*dy - dx)
#
# The 1.785 factor (≈ 0.707 / 0.397) accounts for the camera tilt — vertical
# movement on screen is compressed vs horizontal due to the look-down angle.
func _screen_to_model_angle(dx: float, dy: float) -> float:
	return atan2(dx + 1.785 * dy, 1.785 * dy - dx)

func _draw_tower_model(tower: Dictionary, cx: float, cy: float, a: float) -> void:
	var type_key: String = tower["type"]
	var level: int = tower.get("level", 1)
	# Facing angle is smooth-interpolated each frame in _update_facing_angles.
	var angle: float = tower.get("facing_angle", 0.0)
	# fire_flash decays from 0.15 → 0 after each shot/pulse; show attack pose
	# while it's burning down so the tower reads as actively firing.
	var attacking: bool = tower.get("fire_flash", 0.0) > 0.0
	var tex: Texture2D = CharRenderer.get_texture(type_key, angle, level, attacking)
	if tex == null:
		draw_circle(Vector2(cx, cy), 18, tower["color"])
		return

	var tint: Color = CharRenderer.get_tint(type_key, level)
	var mod_scale: float = CharRenderer.get_draw_scale(type_key, level)
	var t: float = GM.game_time

	# Base size for sprite in game pixels. With cam_size=4.0 the character
	# occupies ~75% of the source texture, so drawn at 48 it appears a bit
	# smaller than the old cam_size=3.0 version — which was the point of the
	# camera change (no more cropped arms / weapons).
	var draw_size: float = 48.0 * mod_scale
	var _half: float = draw_size / 2.0

	# Firing recoil — the model kicks backward opposite the firing direction
	# during fire_flash, decaying with a quadratic falloff for a snappy feel.
	# Applied only to the sprite itself; aura/particles stay tile-anchored.
	var recoil: Vector2 = Vector2.ZERO
	var fflash: float = tower.get("fire_flash", 0.0)
	if fflash > 0:
		var tgt = tower.get("target")
		if tgt != null and tgt is Dictionary and tgt.get("alive", false):
			var rdx: float = tgt["x"] - cx
			var rdy: float = tgt["y"] - cy
			var rdist: float = sqrt(rdx * rdx + rdy * rdy)
			if rdist > 0.5:
				var kick: float = fflash / 0.15  # 1.0 → 0.0
				var kick_amount: float = kick * kick * 3.0  # max ~3 px
				recoil = Vector2(-rdx / rdist, -rdy / rdist) * kick_amount

	# Subtle ground shadow
	_draw_cast_shadow(cx, cy, 16 * mod_scale, a)

	# Tower-specific aura effects (drawn UNDER the model)
	match type_key:
		"bone_marksman":
			# Warm ember glow at base
			draw_circle(Vector2(cx, cy + 2), 14, Color(0.8, 0.2, 0.1, 0.12 * a))
		"inferno_warlock":
			# Summoning circle — pulsing violet glow with an inscribed rotating
			# pentagram. The star sits flat on the ground (squashed Y) so it reads
			# as floor-painted sigil rather than an emblem floating in front of
			# the warlock. Counter-rotating outer ring of runic dots adds depth.
			var pulse: float = 0.7 + 0.3 * sin(t * 3.0)
			var base := Vector2(cx, cy + 2)
			# Soft violet ground glow
			draw_circle(base, 18, Color(0.5, 0.15, 0.7, 0.1 * a * pulse))
			# Outer ritual ring
			draw_arc(base, 17, 0, TAU, 28, Color(0.65, 0.3, 1.0, 0.28 * a * pulse), 1.2)
			# Inner ring (broken — gives the "ancient sigil" look)
			var inner_spin: float = t * 0.8
			draw_arc(base, 13, inner_spin, inner_spin + TAU * 0.7, 14,
				Color(0.85, 0.55, 1.0, 0.22 * a * pulse), 1.0)
			# Inscribed pentagram — five points connect 0→2→4→1→3→0
			var penta_spin: float = t * 0.5
			var penta_r: float = 14.0
			var penta_pts := PackedVector2Array()
			for pi in range(5):
				var pa: float = penta_spin - PI / 2.0 + pi * TAU / 5.0
				penta_pts.append(Vector2(
					base.x + cos(pa) * penta_r,
					base.y + sin(pa) * penta_r * 0.45  # squash to floor plane
				))
			var penta_col := Color(0.95, 0.65, 1.0, 0.42 * a * pulse)
			var order := [0, 2, 4, 1, 3, 0]
			for li in range(order.size() - 1):
				draw_line(penta_pts[order[li]], penta_pts[order[li + 1]], penta_col, 1.2)
			# Tiny rune dots at each vertex
			for pi in range(5):
				draw_circle(penta_pts[pi], 1.8, Color(1.0, 0.85, 1.0, 0.7 * a * pulse))
			# Counter-rotating outer rune dots — six glyphs orbiting the ring
			for ri in range(6):
				var ra2: float = -t * 0.6 + ri * TAU / 6.0
				var rx2: float = base.x + cos(ra2) * 17.0
				var ry2: float = base.y + sin(ra2) * 17.0 * 0.5
				draw_circle(Vector2(rx2, ry2), 1.2, Color(0.9, 0.6, 1.0, 0.55 * a * pulse))
		"soul_reaper":
			# Green pulsing soul aura
			var pulse: float = 0.6 + 0.4 * sin(t * 2.5)
			draw_circle(Vector2(cx, cy + 2), 18, Color(0.15, 0.6, 0.3, 0.1 * a * pulse))
			# Soul wisps orbiting
			for wi in range(3):
				var wa: float = t * 1.5 + wi * TAU / 3.0
				var wr: float = 16.0 + sin(t * 2.0 + wi) * 3.0
				var wx: float = cx + cos(wa) * wr
				var wy: float = cy + sin(wa) * wr * 0.4
				draw_circle(Vector2(wx, wy), 2.0, Color(0.3, 1.0, 0.5, 0.35 * a))
		"lucifer":
			# Fallen-angel hellfire brand — an infernal inverted-cross sigil
			# scorched flat into the ground, a broken/fractured halo and a
			# breathing lava pool under the model. During fire_flash the whole
			# brand flares white-hot and the sigil widens, selling the
			# global-execute pulse as a ritual burn.
			var pulse: float = 0.65 + 0.35 * sin(t * 3.5)
			var cast_bloom: float = clampf(fflash * 5.0, 0.0, 1.0)
			var base := Vector2(cx, cy + 2)
			# Molten ground pool — breathes subtly
			draw_circle(base, 18 + cast_bloom * 8, Color(1.0, 0.25, 0.04, (0.1 + cast_bloom * 0.2) * a * pulse))
			draw_circle(base, 12 + cast_bloom * 6, Color(1.0, 0.55, 0.1, (0.12 + cast_bloom * 0.18) * a * pulse))
			# Outer hellfire ring scorched around the pool
			draw_arc(base, 17, 0, TAU, 28, Color(1.0, 0.35, 0.08, 0.3 * a * pulse), 1.2)
			# Inner broken ring — three arc segments separated by gaps
			var ring_spin: float = t * 0.4
			var seg_count: int = 3
			for si in range(seg_count):
				var sa: float = ring_spin + si * TAU / seg_count
				draw_arc(base, 12.5, sa, sa + TAU / float(seg_count) * 0.7, 10,
					Color(1.0, 0.7, 0.3, 0.45 * a * pulse), 1.1)
			# Inverted-cross brand painted flat on the pool (long arm points down).
			# Diegetic mark of the fallen — reads as "this tile is cursed ground".
			var brand_spin: float = t * 0.25
			var cs: float = cos(brand_spin)
			var sn: float = sin(brand_spin)
			var arm_y_up: float = -5.0
			var arm_y_dn: float = 10.0
			var arm_x: float = 4.5
			# Project onto flat ground plane (Y squash 0.45) and rotate slowly
			var _flat := func(ox: float, oy: float) -> Vector2:
				var rx: float = cs * ox - sn * oy
				var ry: float = (sn * ox + cs * oy) * 0.45
				return Vector2(base.x + rx, base.y + ry)
			var brand_col := Color(1.0, 0.75, 0.25, (0.55 + cast_bloom * 0.35) * a * pulse)
			# Vertical arm (long, downward)
			draw_line(_flat.call(0, arm_y_up), _flat.call(0, arm_y_dn), brand_col, 1.6)
			# Horizontal crossbar (short, near top of long arm)
			draw_line(_flat.call(-arm_x, arm_y_up + 2), _flat.call(arm_x, arm_y_up + 2), brand_col, 1.4)
			# Tiny molten drip at the brand foot
			draw_circle(_flat.call(0, arm_y_dn), 1.2, Color(1, 1, 0.7, 0.7 * a * pulse))
			# Orbiting embers — 5 larger sparks, pulsing bright on cast
			for fi in range(5):
				var fa: float = t * 1.6 + fi * TAU / 5.0
				var fr: float = 15.0 + sin(t * 3.0 + float(fi) * 1.1) * 1.5
				var fx: float = cx + cos(fa) * fr
				var fy: float = cy + sin(fa) * fr * 0.4 - 2
				var fsize: float = 2.0 + cast_bloom * 1.0
				draw_circle(Vector2(fx, fy), fsize + 1.2, Color(1.0, 0.45, 0.08, 0.25 * a))
				draw_circle(Vector2(fx, fy), fsize, Color(1.0, 0.7, 0.25, (0.55 + cast_bloom * 0.4) * a))
		"hades":
			# Underworld throne aura — dark vortex with spectral pillars and
			# necrotic ground runes. Pulses harder during buff cycle.
			var is_buffing: bool = tower.get("buff_active_timer", 0.0) > 0
			var throne_pulse: float = 0.6 + 0.4 * sin(t * 2.5)
			var buff_boost: float = 1.0 if not is_buffing else 1.6
			var base := Vector2(cx, cy + 2)
			# Dark vortex ground — layered concentric shadows
			draw_circle(base, 22, Color(0.08, 0.02, 0.15, 0.18 * a * buff_boost))
			draw_circle(base, 16, Color(0.12, 0.04, 0.22, 0.14 * a * buff_boost))
			draw_circle(base, 10, Color(0.2, 0.08, 0.35, 0.12 * a * buff_boost))
			# Outer throne ring — purple with slow counter-rotation
			var throne_spin: float = -t * 0.35
			draw_arc(base, 20, throne_spin, throne_spin + TAU, 32, Color(0.5, 0.2, 0.9, 0.3 * a * throne_pulse * buff_boost), 1.4)
			# Inner broken ring — three segments with gaps (ritual circle)
			for si in range(3):
				var seg_a: float = t * 0.5 + si * TAU / 3.0
				draw_arc(base, 14, seg_a, seg_a + TAU / 3.0 * 0.65, 10,
					Color(0.7, 0.4, 1.0, 0.35 * a * throne_pulse * buff_boost), 1.1)
			# Spectral pillars — 4 vertical energy columns rising from the ground
			# around the throne base, giving a sense of an ethereal seat of power.
			for pi in range(4):
				var pa: float = t * 0.3 + pi * TAU / 4.0
				var pillar_x: float = cx + cos(pa) * 18.0
				var pillar_base_y: float = cy + sin(pa) * 18.0 * 0.45 + 2
				var pillar_h: float = 16.0 + sin(t * 1.8 + pi * 1.4) * 3.0
				var pillar_a: float = (0.25 + 0.15 * sin(t * 2.5 + pi * 0.9)) * a * buff_boost
				# Pillar glow (wide, faint)
				draw_line(Vector2(pillar_x, pillar_base_y), Vector2(pillar_x, pillar_base_y - pillar_h),
					Color(0.45, 0.2, 0.85, pillar_a * 0.4), 4.0)
				# Pillar core (thin, bright)
				draw_line(Vector2(pillar_x, pillar_base_y), Vector2(pillar_x, pillar_base_y - pillar_h),
					Color(0.75, 0.55, 1.0, pillar_a), 1.5)
				# Pillar tip spark
				draw_circle(Vector2(pillar_x, pillar_base_y - pillar_h), 1.8, Color(0.9, 0.7, 1.0, pillar_a * 1.2))
			# Necrotic ground runes — 6-point hex inscribed on the floor
			var rune_spin: float = t * 0.25
			for ri in range(6):
				var ra: float = rune_spin + ri * TAU / 6.0
				var rr: float = 17.0
				var rx: float = cx + cos(ra) * rr
				var ry: float = cy + sin(ra) * rr * 0.4
				var rp: float = 0.45 + 0.55 * sin(t * 3.0 + ri * 1.05)
				# Rune node
				draw_circle(Vector2(rx, ry), 1.6, Color(0.6, 0.35, 1.0, 0.55 * a * rp * buff_boost))
				# Connect to next node
				var ra_next: float = rune_spin + (ri + 1) * TAU / 6.0
				var nx: float = cx + cos(ra_next) * rr
				var ny: float = cy + sin(ra_next) * rr * 0.4
				draw_line(Vector2(rx, ry), Vector2(nx, ny),
					Color(0.5, 0.25, 0.85, 0.2 * a * rp * buff_boost), 0.8)
		"cocytus":
			# Cold mist and frost aura
			var pulse: float = 0.7 + 0.3 * sin(t * 2.0)
			draw_circle(Vector2(cx, cy + 2), 16, Color(0.5, 0.8, 1.0, 0.08 * a * pulse))
			# Orbiting ice fragments
			for ii in range(4):
				var ia: float = t * 1.2 + ii * TAU / 4.0
				var ir: float = 14.0
				var ix: float = cx + cos(ia) * ir
				var iy: float = cy + sin(ia) * ir * 0.4 - 4
				draw_rect(Rect2(ix - 1.5, iy - 1.5, 3, 3), Color(0.7, 0.92, 1.0, 0.4 * a))

	# Breathing — subtle vertical bob + scale pulse, desynced per tile so towers
	# don't pulse in lockstep. Suspended during fire_flash so recoil reads cleanly.
	var breath_bob: float = 0.0
	var breath_scale: float = 1.0
	if fflash <= 0.0:
		var tile_seed: float = float(int(tower.get("col", 0)) * 73 + int(tower.get("row", 0)) * 131) * 0.19
		var breath_phase: float = t * 1.6 + tile_seed
		breath_bob = sin(breath_phase) * 0.8
		breath_scale = 1.0 + sin(breath_phase) * 0.012

	# Draw the 3D model texture — apply recoil offset to sprite only.
	# Feet sit around fraction ~0.65 from texture top (cam_size=4.0 isometric
	# projection puts feet well above bottom of padded texture). Offset = 0.62
	# buries feet a few px into the tile so the model reads as grounded.
	var b_size: float = draw_size * breath_scale
	var b_half: float = b_size / 2.0
	var rect := Rect2(cx - b_half + recoil.x, cy - 0.62 * b_size + recoil.y + breath_bob, b_size, b_size)
	var mod_color := Color(tint.r, tint.g, tint.b, a)
	draw_texture_rect(tex, rect, false, mod_color)

	# Tower-specific overlay effects (drawn OVER the model)
	match type_key:
		"bone_marksman":
			# Rising ember particles
			for ei in range(4):
				var seed_f: float = float(ei) * 1.7
				var life: float = fmod(t * 0.8 + seed_f, 2.0) / 2.0
				var ex: float = cx + sin(seed_f * 3.1 + t * 0.7) * 8.0
				var ey: float = cy - life * 25.0
				var ea: float = (1.0 - life) * 0.5
				draw_circle(Vector2(ex, ey), 1.2, Color(1, 0.5, 0.1, a * ea))
		"inferno_warlock":
			# Floating triangular sigil hovering above the warlock's head — a
			# small upward-pointing rune triangle rotates slowly with three
			# corner runes and a central pulsing glyph. Reads as "casting" much
			# more strongly than the previous 3 floating dots.
			var head := Vector2(cx, cy - 22)
			var sig_spin: float = t * 0.9
			var sig_pulse: float = 0.6 + 0.4 * sin(t * 4.0)
			var sig_r: float = 4.5 + sin(t * 2.0) * 0.6
			# Triangle vertices
			var tri_pts := PackedVector2Array()
			for ti in range(3):
				var ta: float = sig_spin - PI / 2.0 + ti * TAU / 3.0
				tri_pts.append(Vector2(head.x + cos(ta) * sig_r,
					head.y + sin(ta) * sig_r))
			# Outer faint glow triangle (slightly larger)
			var glow_pts := PackedVector2Array()
			for ti in range(3):
				var ta: float = sig_spin - PI / 2.0 + ti * TAU / 3.0
				glow_pts.append(Vector2(head.x + cos(ta) * (sig_r + 1.5),
					head.y + sin(ta) * (sig_r + 1.5)))
			for li in range(3):
				draw_line(glow_pts[li], glow_pts[(li + 1) % 3],
					Color(0.6, 0.2, 0.9, 0.18 * a * sig_pulse), 2.0)
			# Main sigil edges
			for li in range(3):
				draw_line(tri_pts[li], tri_pts[(li + 1) % 3],
					Color(1.0, 0.7, 1.0, 0.85 * a * sig_pulse), 1.2)
			# Corner rune dots
			for ti in range(3):
				draw_circle(tri_pts[ti], 1.4, Color(1.0, 0.9, 1.0, 0.95 * a * sig_pulse))
			# Center glyph — small pulsing core
			draw_circle(head, 1.1 + sin(t * 5.0) * 0.5, Color(1.0, 0.6, 1.0, 0.9 * a * sig_pulse))
			# Tether line back to the warlock — soft purple
			draw_line(Vector2(cx, cy - 12), head, Color(0.7, 0.3, 1.0, 0.18 * a * sig_pulse), 1.0)
		"soul_reaper":
			# Floating bone fragments above
			for bi in range(3):
				var ba: float = t * 1.0 + bi * TAU / 3.0
				var br: float = 10.0 + sin(t * 1.5 + bi) * 3.0
				var bx: float = cx + cos(ba) * br
				var by: float = cy - 12 + sin(t * 2.0 + bi * 1.3) * 4.0
				draw_line(Vector2(bx - 2, by), Vector2(bx + 2, by), Color(0.85, 0.8, 0.65, 0.4 * a), 1.5)
		"lucifer":
			# Broken halo — a fractured golden-red ring hovering above the
			# fallen angel's head. Two arcs separated by gaps, gently bobbing
			# and counter-rotating. When Lucifer pulses the global execute
			# (fire_flash > 0) the halo flares white-hot and tilts sharply,
			# reading as a charge surge rather than a static ornament.
			#
			# Pre-pulse charging: as cooldown approaches 0, energy converges
			# inward — arcing tendrils collapse toward center, ground sigil
			# brightens, and a low rumble glow intensifies. This gives the
			# player a visual "tells" before the pulse fires.
			var cooldown: float = tower.get("cooldown", 0.0)
			var max_cd: float = 1.0 / maxf(0.01, tower.get("attack_speed", 0.3) * GM.perm_speed_buff * GM.temp_speed_buff)
			var charge_t: float = clampf(1.0 - cooldown / maxf(0.01, max_cd), 0.0, 1.0)
			# Converging energy tendrils — 6 arcs pulling inward as charge builds
			if charge_t > 0.3:
				var tend_a: float = (charge_t - 0.3) / 0.7  # 0→1 in the last 70% of charge
				var tend_count: int = 6
				for ti in range(tend_count):
					var ta: float = float(ti) * TAU / float(tend_count) + t * 0.8
					var start_r: float = 28.0 * (1.0 - tend_a * 0.6)
					var end_r: float = 6.0
					var sx: float = cx + cos(ta) * start_r
					var sy: float = cy + sin(ta) * start_r * 0.5
					var endx: float = cx + cos(ta) * end_r
					var endy: float = cy + sin(ta) * end_r * 0.5
					var t_col := Color(1.0, 0.5 + tend_a * 0.3, 0.1, tend_a * 0.35 * a)
					draw_line(Vector2(sx, sy), Vector2(endx, endy), t_col, 1.0 + tend_a)
				# Central charge glow intensifying
				draw_circle(Vector2(cx, cy), 8.0 * charge_t, Color(1.0, 0.6, 0.15, charge_t * 0.18 * a))
				draw_circle(Vector2(cx, cy), 4.0 * charge_t, Color(1.0, 0.8, 0.4, charge_t * 0.25 * a))
			var halo_cx: float = cx
			var halo_cy: float = cy - 24 + sin(t * 1.6) * 0.8
			var halo_rx: float = 8.0
			var halo_ry: float = 2.8
			var halo_spin: float = t * 1.1
			var halo_flare: float = clampf(fflash * 6.0, 0.0, 1.0)
			var halo_alpha2: float = (0.7 + halo_flare * 0.3) * a
			var halo_col := Color(1.0, 0.75, 0.2, halo_alpha2)
			var halo_glow := Color(1.0, 0.45, 0.1, halo_alpha2 * 0.25)
			# Two broken arc segments — from halo_spin..halo_spin+120° and +180..+300°
			var arc_seg: float = deg_to_rad(120.0)
			for ai in range(2):
				var a0: float = halo_spin + ai * PI
				# Draw arc as polyline of short segments around the tilted ellipse
				var steps: int = 12
				var prev := Vector2.ZERO
				for si in range(steps + 1):
					var frac: float = float(si) / float(steps)
					var ang: float = a0 + frac * arc_seg
					var hx: float = halo_cx + cos(ang) * halo_rx
					var hy: float = halo_cy + sin(ang) * halo_ry - halo_flare * 0.8
					var cur := Vector2(hx, hy)
					if si > 0:
						# Outer glow
						draw_line(prev, cur, halo_glow, 3.0)
						# Main stroke
						draw_line(prev, cur, halo_col, 1.4)
					prev = cur
			# Tiny molten spark droplets at the fracture points
			for ai in range(2):
				var tip_a: float = halo_spin + ai * PI + arc_seg
				var tpx: float = halo_cx + cos(tip_a) * halo_rx
				var tpy: float = halo_cy + sin(tip_a) * halo_ry
				draw_circle(Vector2(tpx, tpy), 1.2, Color(1, 0.9, 0.6, halo_alpha2))
			# Rising embers — increased to 4 particles with occasional "feather"
			# embers that drift sideways (fallen feathers igniting as they fall).
			for ei in range(4):
				var seed_f: float = float(ei) * 2.7
				var life: float = fmod(t * 0.6 + seed_f, 2.0) / 2.0
				var sway: float = sin(seed_f * 3.1 + t * 0.9) * 10.0
				var ex: float = cx + sway
				var ey: float = cy - life * 30.0
				var ea: float = (1.0 - life) * 0.55
				draw_circle(Vector2(ex, ey), 1.4, Color(1, 0.55, 0.1, a * ea))
				# Every other ember gets a brief crimson glow trail
				if ei % 2 == 0:
					draw_circle(Vector2(ex, ey), 2.8, Color(1, 0.25, 0.05, a * ea * 0.3))
		"cocytus":
			# Cold mist rising
			for mi in range(4):
				var mp: float = fmod(t * 0.5 + mi * 0.5, 2.0) / 2.0
				var mx: float = cx + sin(t * 0.8 + mi * 2.0) * 8.0
				var my: float = cy + 6 - mp * 20.0
				var ma: float = (1.0 - mp) * 0.25
				draw_circle(Vector2(mx, my), 3.0, Color(0.7, 0.9, 1.0, a * ma))
		"hades":
			# Spectral crown — a dark, jagged crown silhouette floats above the
			# lord of the underworld. Three upward spikes with connecting arcs,
			# orbited by soul wisps drawn to the crown's power. During buff
			# cycles (buff_active_timer > 0) the crown flares and tendrils of
			# dark energy reach down from it to the pillar tips.
			var crown_cx: float = cx
			var crown_cy: float = cy - 26 + sin(t * 1.4) * 0.7
			var crown_r: float = 7.0
			var is_casting: bool = tower.get("buff_active_timer", 0.0) > 0
			var crown_boost: float = 1.0 if not is_casting else 1.5
			var crown_pulse: float = 0.65 + 0.35 * sin(t * 3.0)
			var crown_a: float = a * crown_pulse * crown_boost
			# Crown spikes — 5 points alternating tall and short
			var crown_pts := PackedVector2Array()
			for ci in range(10):
				var ca: float = float(ci) * TAU / 10.0 - PI / 2.0
				var spike_r: float = crown_r if ci % 2 == 0 else crown_r * 0.55
				crown_pts.append(Vector2(
					crown_cx + cos(ca) * spike_r,
					crown_cy + sin(ca) * spike_r * 0.55))
			# Draw crown outline
			for ci in range(crown_pts.size()):
				var ni: int = (ci + 1) % crown_pts.size()
				draw_line(crown_pts[ci], crown_pts[ni],
					Color(0.6, 0.3, 1.0, 0.75 * crown_a), 1.3)
			# Crown glow fill — dark purple semi-transparent
			draw_colored_polygon(crown_pts, Color(0.25, 0.08, 0.45, 0.3 * crown_a))
			# Bright gem at crown center
			draw_circle(Vector2(crown_cx, crown_cy), 2.0, Color(0.85, 0.6, 1.0, 0.8 * crown_a))
			draw_circle(Vector2(crown_cx, crown_cy), 1.0, Color(1, 0.9, 1, 0.95 * crown_a))
			# Soul wisps orbiting the crown — 3 small spectral motes
			for wi in range(3):
				var wa: float = t * 1.8 + wi * TAU / 3.0
				var wr: float = crown_r + 5.0 + sin(t * 2.2 + wi * 1.5) * 2.0
				var wx: float = crown_cx + cos(wa) * wr
				var wy: float = crown_cy + sin(wa) * wr * 0.4
				draw_circle(Vector2(wx, wy), 1.5, Color(0.65, 0.4, 1.0, 0.5 * crown_a))
				draw_circle(Vector2(wx, wy), 3.0, Color(0.45, 0.2, 0.8, 0.15 * crown_a))
			# Tether from crown to model head
			draw_line(Vector2(crown_cx, crown_cy + crown_r * 0.5), Vector2(cx, cy - 12),
				Color(0.5, 0.25, 0.9, 0.14 * crown_a), 1.0)
			# During buff: dark tendrils reaching outward from the crown
			if is_casting:
				for ti in range(4):
					var ta: float = t * 1.2 + ti * TAU / 4.0
					var tendril_len: float = 14.0 + sin(t * 3.0 + ti * 2.0) * 4.0
					var tx: float = crown_cx + cos(ta) * tendril_len
					var ty: float = crown_cy + sin(ta) * tendril_len * 0.5
					# Midpoint with curve
					var mid_x: float = crown_cx + cos(ta) * tendril_len * 0.5 + sin(t * 4.0 + ti) * 3.0
					var mid_y: float = crown_cy + sin(ta) * tendril_len * 0.25 - 2.0
					draw_line(Vector2(crown_cx, crown_cy), Vector2(mid_x, mid_y),
						Color(0.5, 0.2, 0.85, 0.3 * a), 2.0)
					draw_line(Vector2(mid_x, mid_y), Vector2(tx, ty),
						Color(0.5, 0.2, 0.85, 0.2 * a), 1.5)
					draw_circle(Vector2(tx, ty), 1.5, Color(0.75, 0.5, 1.0, 0.45 * a))

func _draw_enemy_model(enemy: Dictionary, ex: float, ey: float, er: float, flash: bool) -> void:
	var type_key: String = enemy["type"]
	# Facing angle is smooth-interpolated each frame in _update_facing_angles.
	var angle: float = enemy.get("facing_angle", 0.0)
	var tex: Texture2D = CharRenderer.get_texture(type_key, angle)
	if tex == null:
		var body_color: Color = Color(1, 0.2, 0.2) if flash else enemy["color"]
		draw_circle(Vector2(ex, ey), er, body_color)
		return

	var tint: Color = CharRenderer.get_tint(type_key)
	var mod_scale: float = CharRenderer.get_draw_scale(type_key)
	var t: float = GM.game_time

	# Draw size scales with both config scale and enemy radius.
	var draw_size: float = (er * 2 + 20) * mod_scale
	var half: float = draw_size / 2.0

	# Ground shadow
	_draw_cast_shadow(ex, ey, er * mod_scale, 0.8)

	# Type-specific under-effects
	match type_key:
		"grand_paladin", "archangel_michael":
			# Divine radiance for bosses
			var pulse: float = 0.6 + 0.4 * sin(t * 2.5)
			draw_circle(Vector2(ex, ey), er + 6, Color(1.0, 0.9, 0.5, 0.08 * pulse))
			draw_circle(Vector2(ex, ey), er + 3, Color(1.0, 0.95, 0.7, 0.05 * pulse))
		"archangel_marshal":
			# Command aura ring
			var pulse: float = 0.5 + 0.5 * sin(t * 3.0)
			draw_arc(Vector2(ex, ey), er + 8, 0, TAU, 16, Color(1.0, 0.9, 0.4, 0.15 * pulse), 1.0)
		"holy_sentinel":
			# Protective dome — layered shield with hexagonal facets and pulsing
			# barrier lines. Communicates "invulnerability field generator" more
			# clearly than a simple ring.
			var pulse: float = 0.6 + 0.4 * sin(t * 2.0)
			# Outer barrier ring with energy nodes
			draw_arc(Vector2(ex, ey), er + 8, 0, TAU, 24, Color(0.5, 0.7, 1.0, 0.12 * pulse), 1.8)
			draw_arc(Vector2(ex, ey), er + 6, 0, TAU, 20, Color(0.5, 0.7, 1.0, 0.18 * pulse), 1.5)
			# Inner dome glow — highlights on the front-facing half
			draw_arc(Vector2(ex, ey), er + 4, PI * 0.85, PI * 1.45, 10, Color(0.8, 0.9, 1.0, 0.22 * pulse), 1.0)
			# Hex barrier facets — 6 small shield nodes orbiting the dome
			for hi in range(6):
				var ha: float = t * 0.6 + hi * TAU / 6.0
				var hx: float = ex + cos(ha) * (er + 7)
				var hy: float = ey + sin(ha) * (er + 7) * 0.5
				var node_a: float = 0.35 + 0.2 * sin(t * 3.5 + hi * 1.2)
				draw_circle(Vector2(hx, hy), 1.8, Color(0.6, 0.8, 1.0, node_a * pulse))
			# Shield emblem — a small diamond shape at the sentinel's center
			var emblem_r: float = 3.5
			var emblem_pts := PackedVector2Array([
				Vector2(ex, ey - emblem_r),
				Vector2(ex + emblem_r * 0.6, ey),
				Vector2(ex, ey + emblem_r),
				Vector2(ex - emblem_r * 0.6, ey),
			])
			draw_colored_polygon(emblem_pts, Color(0.6, 0.8, 1.0, 0.15 * pulse))
		"zeus":
			# Storm cloud wisps
			for ci in range(3):
				var ca: float = t * 1.5 + ci * TAU / 3.0
				var cr: float = er + 4
				var cx_c: float = ex + cos(ca) * cr
				var cy_c: float = ey + sin(ca) * cr * 0.5
				draw_circle(Vector2(cx_c, cy_c), 3.0, Color(0.6, 0.65, 0.8, 0.15))
		"archangel_raphael", "temple_cleric":
			# Healing glow
			var pulse: float = 0.5 + 0.5 * sin(t * 2.0)
			draw_circle(Vector2(ex, ey), er + 3, Color(0.4, 0.9, 0.5, 0.08 * pulse))

	# Draw the 3D model texture — feet land near (ex, ey) with cam_size=4.0
	# padding in the source texture.
	var rect := Rect2(ex - half, ey - 0.62 * draw_size, draw_size, draw_size)
	var flash_color := Color(1.3, 0.8, 0.8, 1.0) if flash else Color(tint.r, tint.g, tint.b, 1.0)
	draw_texture_rect(tex, rect, false, flash_color)

	# Type-specific over-effects
	match type_key:
		"seraph_scout":
			# Golden halo
			draw_arc(Vector2(ex, ey - er - 2), 4, 0, TAU, 12, Color(1, 0.9, 0.4, 0.6), 1.0)
		"crusader":
			# Armored knight effects — shield glint and tabard cross emblem.
			# Reinforces "disciplined soldier" fiction with subtle military details.
			var cross_y: float = ey - er * 0.1
			var cross_pulse: float = 0.4 + 0.15 * sin(t * 2.5 + float(enemy["id"]) * 0.5)
			var cross_col := Color(0.95, 0.95, 0.95, cross_pulse)
			draw_line(Vector2(ex - 2.5, cross_y), Vector2(ex + 2.5, cross_y), cross_col, 1.3)
			draw_line(Vector2(ex, cross_y - 3.0), Vector2(ex, cross_y + 3.0), cross_col, 1.3)
			# Periodic shield glint — a bright flash that sweeps across
			var glint_phase: float = fmod(t * 0.7 + float(enemy["id"]) * 0.3, 3.0)
			if glint_phase < 0.3:
				var glint_a: float = sin(glint_phase / 0.3 * PI) * 0.55
				var glint_x: float = ex - er + glint_phase / 0.3 * er * 2.0
				draw_line(Vector2(glint_x, ey - er * 0.6), Vector2(glint_x + 2, ey + er * 0.3),
					Color(1.0, 1.0, 0.95, glint_a), 1.5)
		"swift_ranger":
			# Speed afterimage
			for si in range(2):
				var off: float = float(si + 1) * 5.0
				var sa: float = 0.15 - float(si) * 0.06
				draw_texture_rect(tex, Rect2(ex - half - off, ey - half - 4, draw_size, draw_size), false, Color(tint.r, tint.g, tint.b, sa))
		"war_titan":
			# Imposing war presence — angry eye glow, ground tremor dust, and
			# a heavy aura that communicates "this enemy hits hard and takes hits."
			# Angry eye glow (enhanced with pulsing outer bloom)
			var glow_a: float = 0.5 + 0.3 * sin(t * 5.0)
			draw_circle(Vector2(ex - 2, ey - er * 0.3), 3.5, Color(1.0, 0.2, 0.0, glow_a * 0.2))
			draw_circle(Vector2(ex - 2, ey - er * 0.3), 2.0, Color(1.0, 0.3, 0.1, glow_a))
			draw_circle(Vector2(ex + 2, ey - er * 0.3), 3.5, Color(1.0, 0.2, 0.0, glow_a * 0.2))
			draw_circle(Vector2(ex + 2, ey - er * 0.3), 2.0, Color(1.0, 0.3, 0.1, glow_a))
			# Ground tremor dust — small dust puffs kicked up at the titan's feet
			# that cycle with a walking cadence, selling the unit's mass.
			for di in range(3):
				var dust_seed: float = float(di) * 1.9 + float(enemy["id"]) * 0.4
				var dust_life: float = fmod(t * 1.8 + dust_seed, 1.2) / 1.2
				var dust_x: float = ex + sin(dust_seed * 3.7) * (er + 2.0)
				var dust_y: float = ey + er * 0.6 - dust_life * 6.0
				var dust_a: float = (1.0 - dust_life) * 0.35
				var dust_r: float = 1.5 + dust_life * 2.5
				draw_circle(Vector2(dust_x, dust_y), dust_r, Color(0.7, 0.55, 0.35, dust_a))
			# Heavy stance aura — faint orange ring at feet showing mass/threat
			var stance_pulse: float = 0.4 + 0.2 * sin(t * 2.0 + float(enemy["id"]))
			draw_arc(Vector2(ex, ey + er * 0.3), er + 2, 0, TAU, 16,
				Color(1.0, 0.5, 0.2, stance_pulse * 0.18), 1.5)
		"grand_paladin":
			# Golden crown glow
			for ci in range(3):
				var fx: float = ex - 3 + ci * 3
				draw_circle(Vector2(fx, ey - er - 4), 1.5, Color(1.0, 0.85, 0.2, 0.6))
		"archangel_michael":
			# Wing-like light rays
			for wi in range(4):
				var wa: float = PI * 0.7 + wi * 0.15
				var wl: float = er + 8 + sin(t * 2.0 + wi) * 3.0
				draw_line(
					Vector2(ex + cos(wa) * er * 0.5, ey + sin(wa) * er * 0.3),
					Vector2(ex + cos(wa) * wl, ey + sin(wa) * wl * 0.4),
					Color(1.0, 0.95, 0.7, 0.25), 1.5
				)
				draw_line(
					Vector2(ex - cos(wa) * er * 0.5, ey + sin(wa) * er * 0.3),
					Vector2(ex - cos(wa) * wl, ey + sin(wa) * wl * 0.4),
					Color(1.0, 0.95, 0.7, 0.25), 1.5
				)
			# Flaming sword sparkles
			for si in range(3):
				var sp: float = fmod(t * 2.0 + si * 0.6, 1.5) / 1.5
				var sx: float = ex + 6 + sin(t * 4.0 + si) * 3.0
				var sy: float = ey - er * 0.5 - sp * 12.0
				draw_circle(Vector2(sx, sy), 1.0, Color(1.0, 0.7, 0.2, (1.0 - sp) * 0.5))
		"zeus":
			# Crackling electric arcs
			for ai in range(3):
				var aa: float = t * 3.0 + ai * TAU / 3.0
				var ar: float = er + 5
				var ax1: float = ex + cos(aa) * ar
				var ay1: float = ey + sin(aa) * ar * 0.5
				var ax2: float = ax1 + sin(t * 8 + ai) * 4
				var ay2: float = ay1 + cos(t * 6 + ai) * 3
				draw_line(Vector2(ax1, ay1), Vector2(ax2, ay2), Color(0.8, 0.9, 1.0, 0.5), 1.5)
		"archangel_raphael":
			# Caduceus — two counter-rotating ribbons of light winding around the staff,
			# a floating healing cross above, and the core orb glow at the staff head.
			var glow_p: float = 0.5 + 0.5 * sin(t * 3.0)
			# Staff-head orb
			draw_circle(Vector2(ex + 5, ey - er * 0.4), 3.0, Color(0.4, 1.0, 0.5, 0.3 * glow_p))
			draw_circle(Vector2(ex + 5, ey - er * 0.4), 1.4, Color(0.85, 1.0, 0.9, 0.7 * glow_p))
			# Two ribbons spiraling upward around the caduceus
			for ribbon in range(2):
				var ribbon_sign: float = 1.0 if ribbon == 0 else -1.0
				for si in range(5):
					var phase: float = float(si) / 5.0
					var ra: float = t * 2.4 * ribbon_sign + phase * TAU + float(ribbon) * PI
					var ry: float = ey - er - 2 - phase * 10.0
					var rx: float = ex + 5 + sin(ra) * 3.2
					var ribbon_a: float = (1.0 - phase) * 0.55
					draw_circle(Vector2(rx, ry), 1.3 - phase * 0.5, Color(0.55, 1.0, 0.65, ribbon_a))
			# Floating healing cross above the angel
			var cross_y: float = ey - er - 10 + sin(t * 2.0) * 1.5
			var cross_a: float = 0.55 + 0.2 * sin(t * 3.0)
			draw_line(Vector2(ex - 2.5, cross_y), Vector2(ex + 2.5, cross_y), Color(0.7, 1.0, 0.8, cross_a), 1.5)
			draw_line(Vector2(ex, cross_y - 2.5), Vector2(ex, cross_y + 2.5), Color(0.7, 1.0, 0.8, cross_a), 1.5)
			# Soft white bloom behind the cross
			draw_circle(Vector2(ex, cross_y), 3.0, Color(0.9, 1.0, 0.85, cross_a * 0.25))

# ═══════════════════════════════════════════════════════
# INPUT
# ═══════════════════════════════════════════════════════
func _unhandled_input(event: InputEvent) -> void:
	if GM.phase != "playing":
		return

	if event is InputEventMouseButton and event.pressed:
		var pos := get_local_mouse_position()
		if pos.x < 0 or pos.x >= Config.GAME_WIDTH or pos.y < 0 or pos.y >= Config.GAME_HEIGHT:
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click()

	if event is InputEventKey:
		if event.keycode == KEY_TAB:
			GM.show_overview = event.pressed
			get_viewport().set_input_as_handled()
			return
		if event.pressed and event.keycode == KEY_J and event.is_command_or_control_pressed():
			GM.sins += 99999
			GM.notify("Cheat: +99999 Sins", Color(1, 0.2, 0.8))
			get_viewport().set_input_as_handled()
			return
		if event.pressed and event.keycode == KEY_K and event.is_command_or_control_pressed():
			# Skip to wave 15 — clear current wave and jump
			GM.enemies.clear()
			GM.projectiles.clear()
			GM.spawn_queue.clear()
			GM.wave_active = false
			GM.wave = 14
			GM.between_wave_timer = 1.0
			GM.notify("Cheat: Skipping to wave 15", Color(1, 0.2, 0.8))
			get_viewport().set_input_as_handled()
			return

		if event.pressed:
			# REDESIGN: rotate Cocytus cone preview with Q / E during placement
			if GM.selected_tower_type != "" and Config.TOWER_DATA[GM.selected_tower_type].get("is_beam_cone", false):
				if event.keycode == KEY_Q:
					GM.preview_cone_facing -= PI / 4.0
					GM.preview_cone_manual = true
					get_viewport().set_input_as_handled()
					return
				if event.keycode == KEY_E:
					GM.preview_cone_facing += PI / 4.0
					GM.preview_cone_manual = true
					get_viewport().set_input_as_handled()
					return
			var tower_keys := Config.TOWER_DATA.keys()
			match event.keycode:
				KEY_ESCAPE:
					GM.selected_tower_type = ""
					GM.selected_tower = null
					GM.preview_cone_manual = false
					GM.preview_cone_last_grid = Vector2i(-99, -99)
				KEY_D:
					if GM.wave_active and not GM.paused:
						GM.roll_dice()
				KEY_SPACE, KEY_ENTER:
					if not GM.wave_active:
						GM.between_wave_timer = 0
				KEY_P:
					GM.paused = not GM.paused
				KEY_U:
					if GM.selected_tower != null:
						GM.upgrade_tower(GM.selected_tower)
				KEY_T:
					if GM.selected_tower != null:
						GM.cycle_targeting(GM.selected_tower)
				KEY_X:
					if GM.selected_tower != null:
						GM.sell_tower(GM.selected_tower)
				KEY_1:
					GM.set_game_speed(0.5)
				KEY_2:
					GM.set_game_speed(1.0)
				KEY_3:
					GM.set_game_speed(2.0)
				KEY_4:
					if tower_keys.size() > 0:
						GM.selected_tower_type = tower_keys[0]
						GM.selected_tower = null
				KEY_5:
					if tower_keys.size() > 1:
						GM.selected_tower_type = tower_keys[1]
						GM.selected_tower = null
				KEY_6:
					if tower_keys.size() > 2:
						GM.selected_tower_type = tower_keys[2]
						GM.selected_tower = null
				KEY_7:
					if tower_keys.size() > 3:
						GM.selected_tower_type = tower_keys[3]
						GM.selected_tower = null
				KEY_8:
					if tower_keys.size() > 4:
						GM.selected_tower_type = tower_keys[4]
						GM.selected_tower = null
				KEY_9:
					if tower_keys.size() > 5:
						GM.selected_tower_type = tower_keys[5]
						GM.selected_tower = null

func _handle_left_click(pos: Vector2) -> void:
	var grid := Config.pixel_to_grid(pos.x, pos.y)

	if GM.selected_tower_type != "":
		# Placement mode
		if GM.is_buildable(grid.x, grid.y):
			var data: Dictionary = Config.TOWER_DATA[GM.selected_tower_type]
			# Unique towers: only 1 allowed on the field (e.g., Lucifer)
			if data.get("unique", false) and GM.has_tower_type(GM.selected_tower_type):
				GM.notify(Locale.t("Only one Lucifer allowed!"), Color(1, 0.4, 0.0))
				return

			var cost: int = data["cost"]

			var is_free := GM.free_towers > 0
			if not is_free and not GM.can_afford(cost):
				GM.notify(Locale.t("Not enough sins!"), Color(1, 0.2, 0.2))
				return
			if not is_free:
				GM.spend(cost)
			else:
				GM.free_towers -= 1
				GM.notify(Locale.tf("free_tower_notify", {"count": GM.free_towers}), Color(0.267, 1.0, 0.267))

			var tower := GM.create_tower(GM.selected_tower_type, grid.x, grid.y)
			# REDESIGN: override auto-picked facing with player's rotated preview
			if tower.get("is_beam_cone", false):
				tower["facing_angle"] = GM.preview_cone_facing
				GM.preview_cone_manual = false
				GM.preview_cone_last_grid = Vector2i(-99, -99)
			GM.towers.append(tower)
			GM.occupied_tiles[Config.tile_key(grid.x, grid.y)] = tower
			GM.stats["towers_placed"] += 1
	else:
		# Selection mode
		var key := Config.tile_key(grid.x, grid.y)
		if GM.occupied_tiles.has(key):
			GM.selected_tower = GM.occupied_tiles[key]
		else:
			GM.selected_tower = null

func _handle_right_click() -> void:
	GM.selected_tower_type = ""
	GM.selected_tower = null
	GM.preview_cone_manual = false
	GM.preview_cone_last_grid = Vector2i(-99, -99)
