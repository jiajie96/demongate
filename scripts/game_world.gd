extends Node2D

var font: Font
var T: int  # tile size shorthand
var _base_position: Vector2

func _ready() -> void:
	font = ThemeDB.fallback_font
	T = Config.TILE_SIZE
	_base_position = position  # preserve scene-configured offset (10, 55)
	Audio.start_music()

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

	# Spawn marker — heavenly golden portal (brighter)
	var spawn_cell: Vector2i = Config.MAP_PATH[0]
	var sx: float = spawn_cell.x * T + T / 2.0
	var sy: float = spawn_cell.y * T + T / 2.0
	var sp_pulse: float = 0.5 + 0.5 * sin(GM.game_time * 2.5)
	# Outer golden glow — increased alphas
	draw_circle(Vector2(sx, sy), 16, Color(1.0, 0.85, 0.4, 0.12 + sp_pulse * 0.08))
	draw_circle(Vector2(sx, sy), 11, Color(1.0, 0.9, 0.6, 0.18 + sp_pulse * 0.12))
	# Core light
	draw_circle(Vector2(sx, sy), 6, Color(1.0, 0.95, 0.8, 0.75))
	draw_circle(Vector2(sx, sy), 3, Color(1.0, 1.0, 0.95, 0.9))
	# Golden ring
	draw_arc(Vector2(sx, sy), 12, 0, TAU, 20, Color(1.0, 0.85, 0.5, 0.5 + sp_pulse * 0.2), 1.5)
	# Light rays upward
	for ri in range(5):
		var ray_angle: float = -PI / 2.0 + (float(ri) - 2.0) * 0.25
		var ray_len: float = 18.0 + sp_pulse * 8.0
		var ray_end := Vector2(sx + cos(ray_angle) * ray_len, sy + sin(ray_angle) * ray_len)
		draw_line(Vector2(sx, sy), ray_end, Color(1.0, 0.9, 0.6, 0.22 + sp_pulse * 0.14), 1.0)
	draw_string(font, Vector2(sx - 24, sy + T * 0.7), Locale.t("SPAWN"), HORIZONTAL_ALIGNMENT_CENTER, 48, 10, Color(1.0, 0.92, 0.7))

	# Core marker — Hell's Core with vivid fire
	var core_cell: Vector2i = Config.MAP_PATH[Config.MAP_PATH.size() - 1]
	var cx: float = core_cell.x * T + T / 2.0
	var cy: float = core_cell.y * T + T / 2.0

	# Intense fire glow layers — brighter alphas
	var pulse: float = 0.5 + 0.5 * sin(GM.game_time * 3.0)
	for i in range(6):
		var glow_r: float = T * (1.1 - float(i) * 0.15)
		var glow_a: float = (0.3 + 0.2 * pulse) * float(i + 1) * 0.12
		draw_circle(Vector2(cx, cy), glow_r, Color(1, 0.18 + float(i) * 0.04, 0.06, glow_a))
	# Fire tongues around core — more vivid
	for fi in range(8):
		var fa: float = GM.game_time * 2.5 + float(fi) * TAU / 8.0
		var fdist: float = 16.0 + 6.0 * sin(GM.game_time * 4.0 + float(fi) * 1.7)
		var fx: float = cx + cos(fa) * fdist
		var fy: float = cy + sin(fa) * fdist
		var fh: float = 4.0 + 3.0 * sin(GM.game_time * 5.0 + float(fi))
		draw_circle(Vector2(fx, fy), fh, Color(1, 0.45, 0.08, 0.3 * pulse))
		draw_circle(Vector2(fx, fy), fh * 0.5, Color(1, 0.65, 0.2, 0.5 * pulse))

	draw_circle(Vector2(cx, cy), 12, Color(0.95, 0.15, 0.06))
	draw_circle(Vector2(cx, cy), 8, Config.COLOR_CORE)
	draw_arc(Vector2(cx, cy), 14, 0, TAU, 24, Color(1, 0.35, 0.12, 0.55 + pulse * 0.25), 1.5)
	draw_string(font, Vector2(cx - 40, cy - 18), Locale.t("HELL'S CORE"), HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Color(1, 0.88, 0.82))

	# Core HP bar on map
	var bar_w: float = 40.0
	var bar_h: float = 5.0
	var hp_ratio: float = GM.core_hp / GM.core_max_hp
	draw_rect(Rect2(cx - bar_w / 2, cy + 16, bar_w, bar_h), Config.COLOR_HEALTH_BG)
	var hp_color := Config.COLOR_HEALTH_HP if hp_ratio > 0.3 else Config.COLOR_HEALTH_LOW
	draw_rect(Rect2(cx - bar_w / 2, cy + 16, bar_w * hp_ratio, bar_h), hp_color)

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

	# Hell zone (bottom rows 8-11): rising embers and heat glow
	var hell_top: float = float(8 * T)
	# Bottom edge fire glow — brighter
	var fire_glow_a: float = 0.06 + 0.03 * sin(t * 1.5)
	draw_rect(Rect2(0, float(10 * T), Config.GAME_WIDTH, float(2 * T)), Color(1, 0.2, 0.0, fire_glow_a))
	draw_rect(Rect2(0, float(11 * T), Config.GAME_WIDTH, float(T)), Color(1, 0.15, 0.0, fire_glow_a * 1.5))
	# Rising ember particles — more vivid
	for ei in range(16):
		var seed_val: float = float(ei) * 53.91
		var ex: float = fmod(seed_val * 41.3, Config.GAME_WIDTH)
		# Embers rise from bottom, cycling
		var ey_cycle: float = fmod(seed_val * 17.7 + t * (15.0 + fmod(seed_val, 10.0)), float(4 * T))
		var ey: float = float(Config.GAME_HEIGHT) - ey_cycle
		if ey >= hell_top:
			var ember_life: float = ey_cycle / float(4 * T)  # 0=just spawned, 1=faded
			var ember_a: float = (1.0 - ember_life) * 0.7
			var ember_r: float = 1.8 + (1.0 - ember_life) * 1.2
			# Slight horizontal drift
			ex += sin(t * 2.0 + seed_val) * 4.0
			draw_circle(Vector2(ex, ey), ember_r, Color(1, 0.55, 0.15, ember_a))
			draw_circle(Vector2(ex, ey), ember_r * 0.5, Color(1, 0.85, 0.35, ember_a * 0.8))

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

	# Hell zone: floating ash and cinder — more vivid
	var hell_top_y: float = float(8 * T)
	for i in range(10):
		var seed_f: float = float(i) * 61.47
		var fx: float = fmod(seed_f * 29.3, float(Config.GAME_WIDTH))
		fx += sin(t * 0.5 + seed_f) * 12.0  # gentle horizontal sway
		# Slow rise
		var fy_cycle: float = fmod(seed_f * 11.3 + t * 8.0, float(4 * T))
		var fy: float = float(Config.GAME_HEIGHT) - fy_cycle
		if fy >= hell_top_y:
			var ash_life: float = fy_cycle / float(4 * T)
			var ash_a: float = (1.0 - ash_life) * 0.12
			var ash_r: float = 3.0 + (1.0 - ash_life) * 2.0
			# Soft warm glow — more saturated
			draw_circle(Vector2(fx, fy), ash_r, Color(1.0, 0.45, 0.18, ash_a))
			draw_circle(Vector2(fx, fy), ash_r * 0.4, Color(1.0, 0.75, 0.35, ash_a * 1.8))

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
		# Hell side: bright orange geometric dots and ember glows
		var hell_fade: float = (g - 0.5) * 2.0
		if h % 7 == 0:
			var dx := rx + float(h % 28) + 10
			var dy := ry + float((h / 20) % 28) + 10
			draw_circle(Vector2(dx, dy), 2.0, Color(1.0, 0.55, 0.15, 0.5 * hell_fade))
			draw_circle(Vector2(dx, dy), 4.0, Color(1.0, 0.4, 0.1, 0.2 * hell_fade))
		elif h % 11 == 0:
			var ex := rx + float(h % 28) + 10
			var ey := ry + float((h / 28) % 28) + 10
			var glow := 0.35 + 0.25 * sin(GM.game_time * 2.5 + float(h) * 0.01)
			draw_circle(Vector2(ex, ey), 2.5, Color(1.0, 0.5, 0.15, glow * hell_fade))
	else:
		# Heaven side: simple 4-point star sparkles
		if h % 8 == 0:
			var sx := rx + float(h % 30) + 9
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

		_draw_tower_model(t, cx, cy, a)

		# Hades buff aura — pale golden ring rising vertically
		if t.get("hades_buffed", false):
			var buff_t: float = GM.game_time * 1.8
			# Two rings at different phases, rising upward and fading
			for ri in range(2):
				var phase: float = fmod(buff_t + ri * 0.5, 1.0)
				var ring_y: float = cy + 10 - phase * 28  # rise from bottom to top
				var ring_a: float = (1.0 - phase) * 0.45  # fade as it rises
				var ring_w: float = 16.0 - phase * 4.0    # shrink slightly as it rises
				var ring_h: float = 5.0 - phase * 2.0     # flatten at top
				# Draw as an ellipse approximation (horizontal arc squished vertically)
				var pts := PackedVector2Array()
				for si in range(24):
					var angle: float = si * TAU / 24.0
					pts.append(Vector2(cx + cos(angle) * ring_w, ring_y + sin(angle) * ring_h))
				if pts.size() > 1:
					for si in range(pts.size()):
						var next_i: int = (si + 1) % pts.size()
						draw_line(pts[si], pts[next_i], Color(1.0, 0.9, 0.5, ring_a), 1.5)

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
			match t["type"]:
				"bone_marksman":
					# Quick bright spark
					draw_circle(tp, 8 * flash_a, Color(1, 0.6, 0.2, 0.35 * flash_a))
					draw_circle(tp, 3 * flash_a, Color(1, 0.9, 0.5, 0.7 * flash_a))
				"inferno_warlock":
					# Purple flare burst
					draw_circle(tp, 14 * flash_a, Color(0.6, 0.15, 0.8, 0.2 * flash_a))
					draw_circle(tp, 8 * flash_a, Color(1, 0.5, 0.8, 0.4 * flash_a))
					draw_circle(tp, 3 * flash_a, Color(1, 1, 1, 0.5 * flash_a))
				"soul_reaper":
					# Green pulse ring
					draw_arc(tp, 10 * flash_a, 0, TAU, 16, Color(0.2, 0.9, 0.4, 0.4 * flash_a), 2.0)
					draw_circle(tp, 4 * flash_a, Color(0.4, 1, 0.6, 0.5 * flash_a))
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
func _draw_enemies() -> void:
	var gt: float = GM.game_time
	var has_commander: bool = GM._has_alive_type("archangel_marshal")

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
		if e["type"] == "temple_cleric":
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

	# Multi-segment trail — 4 afterimages fading back
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

	# Arrow head — sharp elongated triangle
	var tip := pos + dir * 6
	var left := pos - dir * 5 + perp * 2.8
	var right := pos - dir * 5 - perp * 2.8
	draw_colored_polygon(PackedVector2Array([tip, left, right]), color)

	# Bright tip
	draw_circle(pos + dir * 4, 1.5, Color(1, 0.9, 0.5, 0.9))

func _draw_proj_fireball(px: float, py: float, color: Color) -> void:
	var pos := Vector2(px, py)
	var pulse: float = 0.85 + 0.15 * sin(GM.game_time * 18.0)

	# Outer glow — bold and bright
	draw_circle(pos, 10 * pulse, Color(1, 0.35, 0.08, 0.15))

	# Fire ring
	draw_arc(pos, 7 * pulse, 0, TAU, 16, Color(1, 0.55, 0.2, 0.5), 1.5)

	# Core — purple/orange
	draw_circle(pos, 5.0, Color(0.75, 0.25, 0.95, 0.9))
	draw_circle(pos, 3.0, Color(1, 0.55, 0.85, 0.95))

	# White-hot center
	draw_circle(pos, 1.5, Color(1, 1, 1, 0.9))

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
func _draw_effects() -> void:
	for e in GM.effects:
		var alpha: float = clampf(e["timer"] / 0.5, 0.0, 1.0)
		var pos := Vector2(e["x"], e["y"])

		match e["type"]:
			"death":
				var expand: float = (1.0 - alpha) * 25.0
				var col: Color = e["color"]
				# Bold expanding ring
				draw_arc(pos, e["radius"] + expand, 0, TAU, 24, Color(col.r, col.g, col.b, alpha * 0.9), 2.5)
				# Triangular shards radiating outward
				for i in range(6):
					var pa: float = i * TAU / 6.0 + e["radius"] * 0.1
					var outer_r: float = e["radius"] + expand * 0.8
					var shard := Vector2(e["x"] + cos(pa) * outer_r, e["y"] + sin(pa) * outer_r)
					draw_circle(shard, 2.0 * alpha, Color(1, 0.95, 0.8, alpha * 0.7))
				# Center flash
				draw_circle(pos, 6 * alpha, Color(1, 0.95, 0.8, alpha * 0.6))
				draw_circle(pos, 3 * alpha, Color(1, 1, 1, alpha * 0.4))
			"aoe":
				# Shockwave — expanding ring
				var ring_r: float = e["radius"] * (1.0 - alpha * 0.2)
				draw_arc(pos, ring_r, 0, TAU, 36, Color(1, 0.55, 0.15, alpha * 0.7), 2.5)
				# Inner ring
				draw_arc(pos, ring_r * 0.6, 0, TAU, 24, Color(1, 0.4, 0.1, alpha * 0.35), 1.5)
				# Fill — soft gradient
				draw_circle(pos, e["radius"] * 0.7, Color(1, 0.47, 0.12, alpha * 0.08))
				# Center flash
				draw_circle(pos, 10 * alpha, Color(1, 0.85, 0.4, alpha * 0.5))
				draw_circle(pos, 5 * alpha, Color(1, 1, 0.8, alpha * 0.4))
			"hit_spark":
				var spark_alpha: float = clampf(e["timer"] / 0.2, 0.0, 1.0)
				# Spark lines radiating from hit — 6 short streaks
				for i in range(6):
					var sa: float = i * TAU / 6.0 + e["x"] * 0.13
					var sr: float = (1.0 - spark_alpha) * 12.0
					var p1 := Vector2(e["x"] + cos(sa) * sr * 0.3, e["y"] + sin(sa) * sr * 0.3)
					var p2 := Vector2(e["x"] + cos(sa) * sr, e["y"] + sin(sa) * sr)
					draw_line(p1, p2, Color(1, 0.9, 0.5, spark_alpha * 0.7), 1.5)
				# Brief white flash at hit point
				draw_circle(pos, 4.0 * spark_alpha, Color(1, 1, 1, spark_alpha * 0.5))
			"dmg_number":
				# Floating damage number rising upward
				var dmg_alpha: float = clampf(e["timer"] / 0.6, 0.0, 1.0)
				var rise: float = (1.0 - dmg_alpha) * 18.0
				var dmg_val: float = e.get("value", 0.0)
				var dmg_str: String = str(roundi(dmg_val)) if dmg_val < 10 else str(snappedf(dmg_val, 0.1))
				var ny: float = e["y"] - rise
				var font_size: int = 10 if dmg_val < 5 else 12
				# Shadow
				draw_string(font, Vector2(e["x"] - 10 + 1, ny + 1), dmg_str, HORIZONTAL_ALIGNMENT_LEFT, 20, font_size, Color(0, 0, 0, dmg_alpha * 0.5))
				# Colored text
				var nc: Color = e["color"]
				draw_string(font, Vector2(e["x"] - 10, ny), dmg_str, HORIZONTAL_ALIGNMENT_LEFT, 20, font_size, Color(nc.r, nc.g, nc.b, dmg_alpha * 0.9))
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
				# Fire burst on enemy when Lucifer's pulse hits
				var hit_a: float = clampf(e["timer"] / 0.4, 0.0, 1.0)
				var burst_progress: float = 1.0 - hit_a
				var er: float = e["radius"]
				# Expanding fire ring
				var ring_r: float = er + burst_progress * 14.0
				draw_arc(pos, ring_r, 0, TAU, 20, Color(1, 0.45, 0.08, hit_a * 0.6), 2.0)
				# Inner bright flash
				draw_circle(pos, (er + 4) * hit_a, Color(1, 0.6, 0.15, hit_a * 0.3))
				draw_circle(pos, er * hit_a * 0.6, Color(1, 0.85, 0.4, hit_a * 0.5))
				# Fire spark streaks radiating outward
				for si in range(8):
					var sa: float = si * TAU / 8.0 + e["x"] * 0.17
					var sr_inner: float = er * 0.5 + burst_progress * 4.0
					var sr_outer: float = er + burst_progress * 16.0
					var p1 := Vector2(e["x"] + cos(sa) * sr_inner, e["y"] + sin(sa) * sr_inner)
					var p2 := Vector2(e["x"] + cos(sa) * sr_outer, e["y"] + sin(sa) * sr_outer)
					draw_line(p1, p2, Color(1, 0.5, 0.1, hit_a * 0.5), 1.5)
			"lucifer_wave":
				# Expanding pulse ring from Lucifer's position — no screen tint
				var wave_alpha: float = clampf(e["timer"] / 0.8, 0.0, 1.0)
				var progress: float = 1.0 - wave_alpha  # 0→1 as wave expands
				var max_r: float = 500.0
				var wave_r: float = progress * max_r
				# Leading edge ring
				draw_arc(pos, wave_r, 0, TAU, 48, Color(1, 0.5, 0.1, wave_alpha * 0.5), 2.5)
				# Trailing ring
				if wave_r > 15:
					draw_arc(pos, wave_r - 10, 0, TAU, 36, Color(1, 0.3, 0.0, wave_alpha * 0.2), 1.5)
			"hades_wave":
				# Purple shockwave expanding from Hades when dealing damage
				var hw_alpha: float = clampf(e["timer"] / 0.6, 0.0, 1.0)
				var hw_progress: float = 1.0 - hw_alpha
				var hw_r: float = hw_progress * e["radius"]
				# Outer purple ring
				draw_arc(pos, hw_r, 0, TAU, 36, Color(0.4, 0.25, 1.0, hw_alpha * 0.5), 2.5)
				# Inner ring
				if hw_r > 10:
					draw_arc(pos, hw_r * 0.7, 0, TAU, 28, Color(0.3, 0.2, 0.9, hw_alpha * 0.25), 1.5)
				# Center flash
				var center_r: float = 12.0 * hw_alpha
				draw_circle(pos, center_r, Color(0.5, 0.35, 1.0, hw_alpha * 0.2))
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
				# Ice crystal burst at impact (expanding frost ring + shards)
				var burst_r: float = e["radius"] * (1.0 + (1.0 - alpha) * 0.5)
				# Frost ring
				draw_arc(pos, burst_r, 0, TAU, 20, Color(0.6, 0.85, 1.0, alpha * 0.6), 2.0)
				draw_arc(pos, burst_r * 0.6, 0, TAU, 16, Color(0.75, 0.92, 1.0, alpha * 0.3), 1.0)
				# Ice shard particles radiating outward
				for si in range(6):
					var sa: float = float(si) * TAU / 6.0 + 0.3
					var sr: float = burst_r * 0.5 + (1.0 - alpha) * 6.0
					var shard_pos := Vector2(pos.x + cos(sa) * sr, pos.y + sin(sa) * sr)
					draw_circle(shard_pos, 1.2 * alpha, Color(0.8, 0.95, 1.0, alpha * 0.5))
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

	# Slight tumble based on game time for a landed-dice feel
	var tumble: float = sin(GM.dice_result_timer * 8.0) * 1.5 * clampf(GM.dice_result_timer - 4.0, 0.0, 1.0)

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
func _update_facing_angles(dt: float) -> void:
	var max_turn: float = FACING_TURN_SPEED * dt

	# Towers face their current target
	for t in GM.towers:
		var target = t.get("target")
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
	# Facing angle is smooth-interpolated each frame in _update_facing_angles.
	var angle: float = tower.get("facing_angle", 0.0)
	var tex: Texture2D = CharRenderer.get_texture(type_key, angle)
	if tex == null:
		draw_circle(Vector2(cx, cy), 18, tower["color"])
		return

	var tint: Color = CharRenderer.get_tint(type_key)
	var mod_scale: float = CharRenderer.get_draw_scale(type_key)
	var t: float = GM.game_time

	# Base size for sprite in game pixels
	var draw_size: float = 48.0 * mod_scale
	var half: float = draw_size / 2.0

	# Subtle ground shadow
	_draw_cast_shadow(cx, cy, 16 * mod_scale, a)

	# Tower-specific aura effects (drawn UNDER the model)
	match type_key:
		"bone_marksman":
			# Warm ember glow at base
			draw_circle(Vector2(cx, cy + 2), 14, Color(0.8, 0.2, 0.1, 0.12 * a))
		"inferno_warlock":
			# Purple arcane circle at base
			var pulse: float = 0.7 + 0.3 * sin(t * 3.0)
			draw_circle(Vector2(cx, cy + 2), 16, Color(0.5, 0.15, 0.7, 0.1 * a * pulse))
			draw_arc(Vector2(cx, cy + 2), 16, t * 0.8, t * 0.8 + TAU * 0.7, 12, Color(0.7, 0.3, 1.0, 0.2 * a * pulse), 1.0)
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
			# Hellfire aura — large, intense
			var pulse: float = 0.7 + 0.3 * sin(t * 4.0)
			draw_circle(Vector2(cx, cy), 22, Color(1.0, 0.3, 0.0, 0.12 * a * pulse))
			draw_circle(Vector2(cx, cy), 18, Color(1.0, 0.5, 0.1, 0.08 * a * pulse))
			# Orbiting fire ring
			for fi in range(6):
				var fa: float = t * 2.0 + fi * TAU / 6.0
				var fr: float = 20.0
				var fx: float = cx + cos(fa) * fr
				var fy: float = cy + sin(fa) * fr * 0.45
				draw_circle(Vector2(fx, fy), 2.5, Color(1.0, 0.5 + sin(t * 5 + fi) * 0.3, 0.1, 0.4 * a))
		"hades":
			# Blue-purple support aura
			var is_buffing: bool = tower.get("buff_timer", 0.0) > 0
			var aura_a: float = 0.15 if is_buffing else 0.06
			draw_circle(Vector2(cx, cy + 2), 20, Color(0.3, 0.2, 0.8, aura_a * a))
			# Runic symbols
			for ri in range(3):
				var ra: float = t * 0.6 + ri * TAU / 3.0
				var rr: float = 16.0
				var rx: float = cx + cos(ra) * rr
				var ry: float = cy + sin(ra) * rr * 0.4
				var rp: float = 0.5 + 0.5 * sin(t * 3.0 + ri * 2.0)
				draw_circle(Vector2(rx, ry), 1.5, Color(0.5, 0.35, 1.0, 0.4 * a * rp))
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

	# Draw the 3D model texture
	var rect := Rect2(cx - half, cy - half - 8, draw_size, draw_size)
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
			# Floating arcane runes above head
			for ri in range(3):
				var ra: float = t * 1.2 + ri * TAU / 3.0
				var rr: float = 8.0
				var rx: float = cx + cos(ra) * rr
				var ry: float = cy - 18 + sin(ra) * rr * 0.3
				var rp: float = 0.6 + 0.4 * sin(t * 4.0 + ri * 2.0)
				draw_circle(Vector2(rx, ry), 1.5, Color(1.0, 0.5, 0.9, 0.5 * a * rp))
		"soul_reaper":
			# Floating bone fragments above
			for bi in range(3):
				var ba: float = t * 1.0 + bi * TAU / 3.0
				var br: float = 10.0 + sin(t * 1.5 + bi) * 3.0
				var bx: float = cx + cos(ba) * br
				var by: float = cy - 12 + sin(t * 2.0 + bi * 1.3) * 4.0
				draw_line(Vector2(bx - 2, by), Vector2(bx + 2, by), Color(0.85, 0.8, 0.65, 0.4 * a), 1.5)
		"lucifer":
			# Crown of flame tips
			for ci in range(3):
				var flame_h: float = 6.0 + sin(t * 5.0 + ci * 1.5) * 3.0
				var fx: float = cx - 4 + ci * 4
				draw_line(Vector2(fx, cy - 22), Vector2(fx, cy - 22 - flame_h), Color(1.0, 0.6, 0.1, 0.6 * a), 1.5)
				draw_circle(Vector2(fx, cy - 22 - flame_h), 1.5, Color(1.0, 0.9, 0.3, 0.5 * a))
		"cocytus":
			# Cold mist rising
			for mi in range(4):
				var mp: float = fmod(t * 0.5 + mi * 0.5, 2.0) / 2.0
				var mx: float = cx + sin(t * 0.8 + mi * 2.0) * 8.0
				var my: float = cy + 6 - mp * 20.0
				var ma: float = (1.0 - mp) * 0.25
				draw_circle(Vector2(mx, my), 3.0, Color(0.7, 0.9, 1.0, a * ma))

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

	# Draw size scales with both config scale and enemy radius
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
			# Protective dome
			var pulse: float = 0.6 + 0.4 * sin(t * 2.0)
			draw_arc(Vector2(ex, ey), er + 6, 0, TAU, 20, Color(0.5, 0.7, 1.0, 0.15 * pulse), 1.5)
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

	# Draw the 3D model texture
	var rect := Rect2(ex - half, ey - half - 4, draw_size, draw_size)
	var flash_color := Color(1.3, 0.8, 0.8, 1.0) if flash else Color(tint.r, tint.g, tint.b, 1.0)
	draw_texture_rect(tex, rect, false, flash_color)

	# Type-specific over-effects
	match type_key:
		"seraph_scout":
			# Golden halo
			draw_arc(Vector2(ex, ey - er - 2), 4, 0, TAU, 12, Color(1, 0.9, 0.4, 0.6), 1.0)
		"swift_ranger":
			# Speed afterimage
			for si in range(2):
				var off: float = float(si + 1) * 5.0
				var sa: float = 0.15 - float(si) * 0.06
				draw_texture_rect(tex, Rect2(ex - half - off, ey - half - 4, draw_size, draw_size), false, Color(tint.r, tint.g, tint.b, sa))
		"war_titan":
			# Angry eye glow
			var glow_a: float = 0.5 + 0.3 * sin(t * 5.0)
			draw_circle(Vector2(ex - 2, ey - er * 0.3), 2.0, Color(1.0, 0.3, 0.1, glow_a))
			draw_circle(Vector2(ex + 2, ey - er * 0.3), 2.0, Color(1.0, 0.3, 0.1, glow_a))
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
			# Healing staff glow
			var glow_p: float = 0.5 + 0.5 * sin(t * 3.0)
			draw_circle(Vector2(ex + 5, ey - er * 0.4), 3.0, Color(0.4, 1.0, 0.5, 0.3 * glow_p))

# ═══════════════════════════════════════════════════════
# INPUT
# ═══════════════════════════════════════════════════════
func _unhandled_input(event: InputEvent) -> void:
	if GM.phase != "playing" or GM.paused:
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
			match event.keycode:
				KEY_ESCAPE:
					GM.selected_tower_type = ""
					GM.selected_tower = null
				KEY_D:
					if GM.wave_active:
						GM.roll_dice()
				KEY_SPACE, KEY_ENTER:
					if not GM.wave_active and not GM.show_pact:
						GM.between_wave_timer = 0
				KEY_1:
					GM.set_game_speed(0.5)
				KEY_2:
					GM.set_game_speed(1.0)
				KEY_3:
					GM.set_game_speed(2.0)

func _handle_left_click(pos: Vector2) -> void:
	var grid := Config.pixel_to_grid(pos.x, pos.y)

	if GM.selected_tower_type != "":
		# Placement mode
		if GM.is_buildable(grid.x, grid.y):
			# Lucifer: only 1 allowed on the field
			if GM.selected_tower_type == "lucifer" and GM.has_tower_type("lucifer"):
				GM.notify(Locale.t("Only one Lucifer allowed!"), Color(1, 0.4, 0.0))
				return

			var data: Dictionary = Config.TOWER_DATA[GM.selected_tower_type]
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
			GM.towers.append(tower)
			GM.occupied_tiles[str(grid.x) + "," + str(grid.y)] = tower
			GM.stats["towers_placed"] += 1
	else:
		# Selection mode
		var key := str(grid.x) + "," + str(grid.y)
		if GM.occupied_tiles.has(key):
			GM.selected_tower = GM.occupied_tiles[key]
		else:
			GM.selected_tower = null

func _handle_right_click() -> void:
	GM.selected_tower_type = ""
	GM.selected_tower = null
