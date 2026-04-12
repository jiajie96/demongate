extends Node2D

var font: Font
var T: int  # tile size shorthand

func _ready() -> void:
	font = ThemeDB.fallback_font
	T = Config.TILE_SIZE
	Audio.start_music()

func _process(dt: float) -> void:
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

	# Track mouse in local coordinates
	var local_mouse := get_local_mouse_position()
	if local_mouse.x >= 0 and local_mouse.x < Config.GAME_WIDTH and local_mouse.y >= 0 and local_mouse.y < Config.GAME_HEIGHT:
		GM.hovered_grid = Config.pixel_to_grid(local_mouse.x, local_mouse.y)
	else:
		GM.hovered_grid = Vector2i(-1, -1)

	queue_redraw()

func _draw() -> void:
	_draw_map()
	_draw_guardian_zone()
	_draw_range_preview()
	_draw_towers()
	_draw_enemies()
	_draw_projectiles()
	_draw_effects()
	_draw_placement_preview()
	_draw_notifications()
	_draw_dice_result()
	if GM.show_overview:
		_draw_overview()

# ═══════════════════════════════════════════════════════
# MAP
# ═══════════════════════════════════════════════════════
func _draw_map() -> void:
	# Background
	draw_rect(Rect2(0, 0, Config.GAME_WIDTH, Config.GAME_HEIGHT), Config.COLOR_BG)

	# Draw tiles with highground depth effect
	for r in range(Config.GRID_ROWS):
		for c in range(Config.GRID_COLS):
			var rx: float = c * T
			var ry: float = r * T
			if Config.is_path(c, r):
				_draw_path_tile(rx, ry, c, r)
			else:
				_draw_ground_tile(rx, ry, c, r)

	# Spawn marker — portal effect (positioned below top bar)
	var spawn_cell: Vector2i = Config.MAP_PATH[0]
	var sx: float = spawn_cell.x * T + T / 2.0
	var sy: float = spawn_cell.y * T + T / 2.0
	var sp_pulse: float = 0.5 + 0.5 * sin(GM.game_time * 2.5)
	draw_circle(Vector2(sx, sy), 8, Color(0.1, 0.2, 0.6, 0.3 + sp_pulse * 0.2))
	draw_circle(Vector2(sx, sy), 5, Config.COLOR_SPAWN)
	draw_arc(Vector2(sx, sy), 10, 0, TAU, 16, Color(0.3, 0.5, 1.0, 0.3 + sp_pulse * 0.15), 1.5)
	draw_string(font, Vector2(sx - 24, sy + T * 0.7), Locale.t("SPAWN"), HORIZONTAL_ALIGNMENT_CENTER, 48, 10, Color(0.7, 0.8, 1.0))

	# Core marker
	var core_cell: Vector2i = Config.MAP_PATH[Config.MAP_PATH.size() - 1]
	var cx: float = core_cell.x * T + T / 2.0
	var cy: float = core_cell.y * T + T / 2.0

	# Core glow (enhanced)
	var pulse: float = 0.5 + 0.5 * sin(GM.game_time * 3.0)
	for i in range(5):
		var glow_r: float = T * 0.9 * (1.0 - float(i) * 0.17)
		var glow_a: float = (0.25 + 0.2 * pulse) * float(i + 1) * 0.12
		draw_circle(Vector2(cx, cy), glow_r, Color(1, 0.15, 0.1, glow_a))

	draw_circle(Vector2(cx, cy), 12, Color(0.9, 0.1, 0.05))
	draw_circle(Vector2(cx, cy), 8, Config.COLOR_CORE)
	draw_arc(Vector2(cx, cy), 14, 0, TAU, 24, Color(1, 0.3, 0.1, 0.4 + pulse * 0.2), 1.5)
	draw_string(font, Vector2(cx - 40, cy - 18), Locale.t("HELL'S CORE"), HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Color(1, 0.85, 0.8))

	# Core HP bar on map
	var bar_w: float = 40.0
	var bar_h: float = 5.0
	var hp_ratio: float = GM.core_hp / GM.core_max_hp
	draw_rect(Rect2(cx - bar_w / 2, cy + 16, bar_w, bar_h), Config.COLOR_HEALTH_BG)
	var hp_color := Config.COLOR_HEALTH_HP if hp_ratio > 0.3 else Config.COLOR_HEALTH_LOW
	draw_rect(Rect2(cx - bar_w / 2, cy + 16, bar_w * hp_ratio, bar_h), hp_color)

func _tile_hash(c: int, r: int) -> int:
	return absi(c * 7919 + r * 104729 + (c + 1) * (r + 1) * 31) % 10000

func _draw_ground_tile(rx: float, ry: float, c: int, r: int) -> void:
	var h := _tile_hash(c, r)

	# Base color with subtle per-tile variation
	var v := float(h % 30 - 15) * 0.002
	var base := Config.COLOR_GROUND if (c + r) % 2 == 0 else Config.COLOR_GROUND_ALT
	var tile_col := Color(base.r + v, base.g + v * 0.6, base.b + v)
	draw_rect(Rect2(rx, ry, T, T), tile_col)

	# Raised platform — lighter inner face
	draw_rect(Rect2(rx + 2, ry + 2, T - 4, T - 4), tile_col.lightened(0.05))

	# Bevel highlight (top + left — light from upper-left)
	draw_line(Vector2(rx + 1, ry + 1), Vector2(rx + T - 1, ry + 1), Config.COLOR_TILE_HIGHLIGHT, 1.0)
	draw_line(Vector2(rx + 1, ry + 2), Vector2(rx + 1, ry + T - 2), Color(Config.COLOR_TILE_HIGHLIGHT, Config.COLOR_TILE_HIGHLIGHT.a * 0.7), 1.0)

	# Bevel shadow (bottom + right)
	draw_line(Vector2(rx + 2, ry + T - 1), Vector2(rx + T, ry + T - 1), Config.COLOR_TILE_SHADOW, 1.0)
	draw_line(Vector2(rx + T - 1, ry + 2), Vector2(rx + T - 1, ry + T - 2), Color(0, 0, 0, 0.14), 1.0)

	# Cliff faces where elevated ground borders sunken path
	if Config.is_path(c, r + 1):
		draw_rect(Rect2(rx, ry + T - 4, T, 4), Config.COLOR_CLIFF_FACE)
		draw_line(Vector2(rx, ry + T - 4), Vector2(rx + T, ry + T - 4), Color(0.4, 0.25, 0.15, 0.35), 1.0)
	if Config.is_path(c + 1, r):
		draw_rect(Rect2(rx + T - 4, ry, 4, T), Color(Config.COLOR_CLIFF_FACE, Config.COLOR_CLIFF_FACE.a * 0.8))
		draw_line(Vector2(rx + T - 4, ry), Vector2(rx + T - 4, ry + T), Color(0.35, 0.2, 0.12, 0.3), 1.0)
	if Config.is_path(c - 1, r):
		draw_rect(Rect2(rx, ry, 4, T), Color(Config.COLOR_CLIFF_FACE, Config.COLOR_CLIFF_FACE.a * 0.7))
	if Config.is_path(c, r - 1):
		draw_rect(Rect2(rx, ry, T, 4), Color(Config.COLOR_CLIFF_FACE, Config.COLOR_CLIFF_FACE.a * 0.7))

	# Decorative details (sparse, deterministic)
	if h % 8 == 0:
		# Lava crack
		var lx := rx + float(h % 24) + 12
		var ly := ry + float((h / 20) % 24) + 12
		var lx2 := lx + float(h % 14) - 7
		var ly2 := ly + float((h / 14) % 14) - 7
		draw_line(Vector2(lx, ly), Vector2(lx2, ly2), Config.COLOR_LAVA_CRACK, 1.0)
		draw_circle(Vector2(lx, ly), 1.5, Config.COLOR_EMBER)
	elif h % 13 == 0:
		# Small rock pebbles
		var rock_x := rx + float(h % 28) + 10
		var rock_y := ry + float((h / 28) % 28) + 10
		draw_circle(Vector2(rock_x, rock_y), 2.0, tile_col.darkened(0.15))
		draw_circle(Vector2(rock_x + 3, rock_y + 1), 1.5, tile_col.darkened(0.1))
	elif h % 19 == 0:
		# Glowing ember (subtle animation)
		var ex := rx + float(h % 28) + 10
		var ey := ry + float((h / 28) % 28) + 10
		var glow := 0.25 + 0.2 * sin(GM.game_time * 2.0 + float(h) * 0.01)
		draw_circle(Vector2(ex, ey), 2.0, Color(1, 0.4, 0.1, glow))
		draw_circle(Vector2(ex, ey), 4.5, Color(1, 0.3, 0.05, glow * 0.3))

func _draw_path_tile(rx: float, ry: float, c: int, r: int) -> void:
	var h := _tile_hash(c, r)

	# Sunken base
	draw_rect(Rect2(rx, ry, T, T), Config.COLOR_PATH)

	# Worn walking surface (lighter center)
	draw_rect(Rect2(rx + 5, ry + 5, T - 10, T - 10), Config.COLOR_PATH_SURFACE)

	# Shadows cast by elevated ground neighbors
	if not Config.is_path(c, r - 1):
		draw_rect(Rect2(rx, ry, T, 5), Color(0, 0, 0, 0.2))
		draw_rect(Rect2(rx, ry + 5, T, 3), Color(0, 0, 0, 0.07))
	if not Config.is_path(c - 1, r):
		draw_rect(Rect2(rx, ry, 5, T), Color(0, 0, 0, 0.15))
		draw_rect(Rect2(rx + 5, ry, 3, T), Color(0, 0, 0, 0.05))

	# Subtle light on open edges (bottom / right)
	if not Config.is_path(c, r + 1):
		draw_line(Vector2(rx + 2, ry + T - 2), Vector2(rx + T - 2, ry + T - 2), Color(1, 0.8, 0.6, 0.04), 1.0)
	if not Config.is_path(c + 1, r):
		draw_line(Vector2(rx + T - 2, ry + 2), Vector2(rx + T - 2, ry + T - 2), Color(1, 0.8, 0.6, 0.03), 1.0)

	# Path edge definition
	draw_rect(Rect2(rx + 0.5, ry + 0.5, T - 1, T - 1), Config.COLOR_PATH_EDGE, false, 0.5)

	# Subtle wear marks
	if h % 6 == 0:
		var wx := rx + float(h % 20) + 14
		var wy := ry + T / 2.0
		draw_line(Vector2(wx, wy - 5), Vector2(wx + 1, wy + 5), Color(0.1, 0.07, 0.05, 0.2), 1.0)

# ═══════════════════════════════════════════════════════
# GUARDIAN PROTECTION ZONE
# ═══════════════════════════════════════════════════════
func _draw_guardian_zone() -> void:
	if not GM._has_alive_type("divine_guardian"):
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

		match t["type"]:
			"demon_archer": _draw_avatar_archer(cx, cy, a)
			"hellfire_mage": _draw_avatar_mage(cx, cy, a)
			"necromancer": _draw_avatar_necro(cx, cy, a)
			"lucifer": _draw_avatar_lucifer(cx, cy, a)
			"hades": _draw_avatar_hades(cx, cy, a)

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
				"demon_archer":
					# Quick bright spark
					draw_circle(tp, 8 * flash_a, Color(1, 0.6, 0.2, 0.35 * flash_a))
					draw_circle(tp, 3 * flash_a, Color(1, 0.9, 0.5, 0.7 * flash_a))
				"hellfire_mage":
					# Purple flare burst
					draw_circle(tp, 14 * flash_a, Color(0.6, 0.15, 0.8, 0.2 * flash_a))
					draw_circle(tp, 8 * flash_a, Color(1, 0.5, 0.8, 0.4 * flash_a))
					draw_circle(tp, 3 * flash_a, Color(1, 1, 1, 0.5 * flash_a))
				"necromancer":
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
	for e in GM.enemies:
		if not e["alive"]:
			continue

		var ex: float = e["x"]
		var ey: float = e["y"]
		var er: float = e["radius"]
		var flash: bool = e["flash_timer"] > 0

		# Draw avatar based on type
		match e["type"]:
			"angel_scout": _draw_enemy_scout(ex, ey, er, flash)
			"holy_knight": _draw_enemy_knight(ex, ey, er, flash)
			"divine_hunter": _draw_enemy_hunter(ex, ey, er, flash)
			"god_of_war": _draw_enemy_war(ex, ey, er, flash)
			"paladin": _draw_enemy_paladin(ex, ey, er, flash)
			"monk": _draw_enemy_monk(ex, ey, er, flash)
			"archangel": _draw_enemy_archangel(ex, ey, er, flash)
			"divine_guardian": _draw_enemy_guardian(ex, ey, er, flash)
			"michael": _draw_enemy_michael(ex, ey, er, flash)
			"zeus": _draw_enemy_zeus(ex, ey, er, flash)
			_:
				# Fallback for corrupted / unknown
				var body_color: Color = Color(1, 0.2, 0.2) if flash else e["color"]
				draw_circle(Vector2(ex, ey), er, body_color)

		# Boss border
		if e["is_boss"]:
			draw_arc(Vector2(ex, ey), er + 2, 0, TAU, 24, Color(1.0, 0.8, 0.0), 2.0)

		# Shield buff indicator
		if e["shield_buff"]:
			draw_arc(Vector2(ex, ey), er + 4, 0, TAU, 24, Color(0.39, 0.59, 1.0, 0.6), 2.0)

		# Slow indicator (blue ring)
		if e.get("slow_timer", 0.0) > 0:
			draw_arc(Vector2(ex, ey), er + 3, 0, TAU, 16, Color(0.3, 0.5, 1.0, 0.6), 1.5)

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
			"demon_archer":
				_draw_proj_arrow(px, py, angle, p["color"])
			"hellfire_mage":
				_draw_proj_fireball(px, py, p["color"])
			"necromancer":
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

	# Outer corona — large soft glow
	draw_circle(pos, 12 * pulse, Color(1, 0.3, 0.05, 0.1))
	draw_circle(pos, 9 * pulse, Color(1, 0.2, 0.0, 0.18))

	# Trailing fire fragments
	for ti in range(5):
		var frag_angle := GM.game_time * 8.0 + ti * TAU / 5.0
		var frag_dist := 5.0 + 3.0 * sin(GM.game_time * 12.0 + ti * 1.5)
		var fx := px + cos(frag_angle) * frag_dist
		var fy := py + sin(frag_angle) * frag_dist
		var frag_a := 0.2 + 0.15 * sin(GM.game_time * 15.0 + ti)
		draw_circle(Vector2(fx, fy), 2.0, Color(1, 0.45, 0.1, frag_a))

	# Fire ring
	draw_arc(pos, 6 * pulse, 0, TAU, 16, Color(1, 0.5, 0.15, 0.4), 1.5)

	# Core — purple/orange gradient
	draw_circle(pos, 5.0, Color(0.7, 0.2, 0.9, 0.85))
	draw_circle(pos, 3.0, Color(1, 0.5, 0.8, 0.9))

	# White-hot center
	draw_circle(pos, 1.5, Color(1, 1, 1, 0.85))

func _draw_proj_necro(px: float, py: float, angle: float, color: Color) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	var pos := Vector2(px, py)

	# Ghostly wisp trail — multiple fading segments
	for ti in range(4):
		var trail_pos := pos - dir * (4.0 + ti * 5.0)
		var sway := sin(GM.game_time * 8.0 + ti * 1.5) * 3.0
		trail_pos += Vector2(-dir.y, dir.x) * sway
		var trail_a := 0.25 - ti * 0.05
		draw_circle(trail_pos, 2.5 - ti * 0.4, Color(0.2, 0.8, 0.4, trail_a))

	# Orbiting wisps — larger orbit
	var t: float = GM.game_time * 5.0
	for i in range(3):
		var wa: float = t + i * TAU / 3.0
		var orbit_r := 6.0 + sin(t * 0.5 + i) * 1.5
		var wx: float = px + cos(wa) * orbit_r
		var wy: float = py + sin(wa) * orbit_r
		draw_circle(Vector2(wx, wy), 2.0, Color(0.3, 1, 0.5, 0.3))
		# Tiny wisp trail
		var wx2: float = px + cos(wa - 0.4) * orbit_r
		var wy2: float = py + sin(wa - 0.4) * orbit_r
		draw_circle(Vector2(wx2, wy2), 1.0, Color(0.3, 1, 0.5, 0.15))

	# Core orb — layered
	draw_circle(pos, 5, Color(0.1, 0.4, 0.2, 0.6))
	draw_circle(pos, 3.5, Color(0.15, 0.6, 0.3, 0.85))
	draw_circle(pos, 2.0, color)

	# Bright center
	draw_circle(pos, 1.0, Color(0.6, 1, 0.8, 0.7))

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
				# Outer expanding ring
				draw_arc(pos, e["radius"] + expand, 0, TAU, 28, Color(col.r, col.g, col.b, alpha * 0.8), 2.5)
				# Inner ring (slower)
				draw_arc(pos, e["radius"] + expand * 0.4, 0, TAU, 20, Color(col.r, col.g, col.b, alpha * 0.35), 1.5)
				# Spark lines radiating outward — like an explosion burst
				for i in range(10):
					var pa: float = i * TAU / 10.0 + e["radius"] * 0.1
					var inner_r: float = e["radius"] * 0.5 + expand * 0.3
					var outer_r: float = e["radius"] + expand * (0.7 + 0.3 * sin(pa * 3.0))
					var p1 := Vector2(e["x"] + cos(pa) * inner_r, e["y"] + sin(pa) * inner_r)
					var p2 := Vector2(e["x"] + cos(pa) * outer_r, e["y"] + sin(pa) * outer_r)
					draw_line(p1, p2, Color(col.r, col.g, col.b, alpha * 0.6), 1.5)
					# Bright tip
					draw_circle(p2, 1.5 * alpha, Color(1, 0.9, 0.7, alpha * 0.5))
				# Center flash
				draw_circle(pos, 6 * alpha, Color(1, 0.95, 0.8, alpha * 0.5))
				draw_circle(pos, 3 * alpha, Color(1, 1, 1, alpha * 0.3))
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
			"screen_flash":
				var col: Color = e["color"]
				col.a = alpha * 0.3
				draw_rect(Rect2(0, 0, Config.GAME_WIDTH, Config.GAME_HEIGHT), col)

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

		# Tower avatar preview (semi-transparent)
		match GM.selected_tower_type:
			"demon_archer": _draw_avatar_archer(center.x, center.y, 0.5)
			"hellfire_mage": _draw_avatar_mage(center.x, center.y, 0.5)
			"necromancer": _draw_avatar_necro(center.x, center.y, 0.5)
			"lucifer": _draw_avatar_lucifer(center.x, center.y, 0.5)
			"hades": _draw_avatar_hades(center.x, center.y, 0.5)

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
		draw_string(font, Vector2(px + 2, py + 25), str(kills) + " kills", HORIZONTAL_ALIGNMENT_LEFT, 48, 9, Color(0.7, 0.7, 0.7))

		# Range circle
		draw_arc(Vector2(cx, cy), t["range"], 0, TAU, 32, Color(t["color"].r, t["color"].g, t["color"].b, 0.2), 1.0)

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

	# Background overlay — larger, tinted by outcome
	var bg_col := Color(0.05, 0.12, 0.0, 0.7 * alpha) if is_good else Color(0.15, 0.02, 0.02, 0.7 * alpha)
	draw_rect(Rect2(W / 2 - 180, H / 2 - 80, 360, 170), bg_col)

	# Border glow
	var border_col := Color(0.3, 0.9, 0.3, 0.5 * alpha) if is_good else Color(0.9, 0.2, 0.2, 0.5 * alpha)
	draw_rect(Rect2(W / 2 - 180, H / 2 - 80, 360, 170), border_col, false, 2.0)

	# Dice values — big and centered
	var dice_text: String = str(r["d1"])
	draw_string(font, Vector2(W / 2 - 150, H / 2 - 35), dice_text, HORIZONTAL_ALIGNMENT_CENTER, 300, 32, Color(1, 1, 1, alpha))

	# Outcome name — colored
	var name_col := Color(0.3, 1.0, 0.3, alpha) if is_good else Color(1.0, 0.3, 0.3, alpha)
	draw_string(font, Vector2(W / 2 - 150, H / 2 + 10), Locale.t(outcome["name"]), HORIZONTAL_ALIGNMENT_CENTER, 300, 20, name_col)

	# Effect description — tells the player what actually happened
	var desc_text: String = Locale.t(outcome.get("desc", ""))
	var desc_col := Color(0.85, 0.95, 0.85, alpha * 0.9) if is_good else Color(0.95, 0.75, 0.75, alpha * 0.9)
	draw_string(font, Vector2(W / 2 - 150, H / 2 + 45), desc_text, HORIZONTAL_ALIGNMENT_CENTER, 300, 13, desc_col)

	# Good/bad indicator icon
	var icon_text := "+" if is_good else "!"
	var icon_col := Color(0.3, 1.0, 0.3, alpha) if is_good else Color(1.0, 0.3, 0.15, alpha)
	draw_string(font, Vector2(W / 2 - 150, H / 2 + 72), icon_text + " " + (Locale.t("DEVIL'S DICE") if Locale.current_lang == "zh" else "DEVIL'S DICE"), HORIZONTAL_ALIGNMENT_CENTER, 300, 10, icon_col * 0.6)

# ═══════════════════════════════════════════════════════
# TOWER AVATARS
# ═══════════════════════════════════════════════════════

func _draw_avatar_archer(cx: float, cy: float, a: float) -> void:
	var t := GM.game_time
	# Ember particles floating up from base
	for i in range(5):
		var seed_f: float = float(i) * 1.7 + 0.3
		var life: float = fmod(t * 0.8 + seed_f, 2.0) / 2.0
		var ex: float = cx + sin(seed_f * 3.1 + t * 0.7) * 10.0
		var ey: float = cy + 14 - life * 30.0
		var ea: float = (1.0 - life) * 0.6
		var sz: float = 1.2 + (1.0 - life) * 0.8
		draw_circle(Vector2(ex, ey), sz, Color(1, 0.5 + life * 0.3, 0.1, a * ea * 0.4))
		draw_circle(Vector2(ex, ey), sz * 0.5, Color(1, 0.8, 0.3, a * ea))
	# Drop shadow for depth
	draw_circle(Vector2(cx + 1, cy + 2), 17, Color(0, 0, 0, a * 0.3))
	# Base platform layered (dark core -> mid -> rim glow)
	draw_circle(Vector2(cx, cy), 18, Color(0.25, 0.04, 0.04, a))
	draw_circle(Vector2(cx, cy), 16, Color(0.35, 0.07, 0.07, a))
	draw_circle(Vector2(cx - 1, cy - 1), 13, Color(0.42, 0.1, 0.09, a * 0.5))
	draw_arc(Vector2(cx, cy), 18, 0, TAU, 32, Color(0.85, 0.25, 0.15, a * 0.55), 1.5)
	draw_arc(Vector2(cx, cy), 17, PI * 0.8, PI * 1.4, 10, Color(1.0, 0.4, 0.2, a * 0.2), 1.0)
	# Flowing cape behind body
	var cape_sway: float = sin(t * 2.5) * 2.0
	var cape_sway2: float = sin(t * 2.5 + 0.8) * 1.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 6, cy - 1), Vector2(cx + 2, cy - 1),
		Vector2(cx + 4 + cape_sway2, cy + 16), Vector2(cx - 10 + cape_sway, cy + 16),
		Vector2(cx - 8 + cape_sway * 0.7, cy + 10)
	]), Color(0.4, 0.05, 0.05, a * 0.85))
	# Cape edge highlight
	draw_line(Vector2(cx - 6, cy - 1), Vector2(cx - 10 + cape_sway, cy + 16), Color(0.6, 0.12, 0.1, a * 0.5), 1.0)
	draw_line(Vector2(cx - 10 + cape_sway, cy + 16), Vector2(cx + 4 + cape_sway2, cy + 16), Color(0.5, 0.08, 0.06, a * 0.3), 1.0)
	# Body with layered armor plates
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 7, cy - 1), Vector2(cx + 3, cy - 1),
		Vector2(cx + 2, cy + 13), Vector2(cx - 6, cy + 13)
	]), Color(0.5, 0.08, 0.08, a))
	# Armor mid tone
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 5, cy + 0), Vector2(cx + 1, cy + 0),
		Vector2(cx + 0, cy + 11), Vector2(cx - 4, cy + 11)
	]), Color(0.6, 0.12, 0.1, a))
	# Armor highlight edge
	draw_line(Vector2(cx - 2, cy + 1), Vector2(cx - 2, cy + 10), Color(0.75, 0.2, 0.15, a * 0.7), 1.0)
	draw_line(Vector2(cx - 4, cy + 1), Vector2(cx - 5, cy + 10), Color(0.7, 0.15, 0.12, a * 0.4), 0.8)
	# Shoulder guard with highlight
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 8, cy - 1), Vector2(cx - 3, cy - 4),
		Vector2(cx + 2, cy - 1), Vector2(cx - 3, cy + 1)
	]), Color(0.6, 0.12, 0.1, a))
	draw_line(Vector2(cx - 3, cy - 4), Vector2(cx + 2, cy - 1), Color(0.8, 0.25, 0.18, a * 0.6), 1.0)
	# Quiver on back (visible behind right shoulder)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 1, cy - 3), Vector2(cx + 4, cy - 4),
		Vector2(cx + 5, cy + 8), Vector2(cx + 2, cy + 8)
	]), Color(0.4, 0.2, 0.08, a * 0.8))
	# Arrow shafts in quiver
	for qi in range(3):
		var qx: float = cx + 2.0 + float(qi) * 1.0
		draw_line(Vector2(qx, cy - 4 - float(qi) * 0.5), Vector2(qx, cy + 6), Color(0.8, 0.65, 0.3, a * 0.6), 0.8)
	# Arrow fletching tips
	for qi in range(3):
		var qx: float = cx + 2.0 + float(qi) * 1.0
		var qy: float = cy - 4 - float(qi) * 0.5
		draw_colored_polygon(PackedVector2Array([
			Vector2(qx, qy - 2), Vector2(qx + 1, qy), Vector2(qx - 1, qy)
		]), Color(0.9, 0.3, 0.1, a * 0.7))
	# Head with layered shading
	draw_circle(Vector2(cx - 2, cy - 6), 5.5, Color(0.55, 0.1, 0.1, a))
	draw_circle(Vector2(cx - 2, cy - 6), 4.8, Color(0.65, 0.15, 0.15, a))
	draw_circle(Vector2(cx - 2.5, cy - 6.5), 3.5, Color(0.78, 0.22, 0.2, a * 0.6))
	# Horns with curved gradient (3 segments each for smooth curve)
	draw_line(Vector2(cx - 5, cy - 10), Vector2(cx - 7, cy - 13), Color(0.7, 0.18, 0.08, a), 2.8)
	draw_line(Vector2(cx - 7, cy - 13), Vector2(cx - 9, cy - 16), Color(0.85, 0.28, 0.1, a), 2.2)
	draw_line(Vector2(cx - 9, cy - 16), Vector2(cx - 10, cy - 18), Color(0.95, 0.45, 0.15, a), 1.5)
	# Horn highlight
	draw_line(Vector2(cx - 6, cy - 11), Vector2(cx - 8, cy - 15), Color(1.0, 0.5, 0.25, a * 0.4), 1.0)
	draw_line(Vector2(cx + 1, cy - 10), Vector2(cx + 3, cy - 13), Color(0.7, 0.18, 0.08, a), 2.8)
	draw_line(Vector2(cx + 3, cy - 13), Vector2(cx + 6, cy - 16), Color(0.85, 0.28, 0.1, a), 2.2)
	draw_line(Vector2(cx + 6, cy - 16), Vector2(cx + 7, cy - 18), Color(0.95, 0.45, 0.15, a), 1.5)
	draw_line(Vector2(cx + 2, cy - 11), Vector2(cx + 5, cy - 15), Color(1.0, 0.5, 0.25, a * 0.4), 1.0)
	# Glowing eyes (animated pulse)
	var eye_glow: float = 0.75 + 0.25 * sin(t * 4.5)
	draw_circle(Vector2(cx - 4, cy - 7), 2.8, Color(1, 0.6, 0, a * 0.15))
	draw_circle(Vector2(cx, cy - 7), 2.8, Color(1, 0.6, 0, a * 0.15))
	draw_circle(Vector2(cx - 4, cy - 7), 1.5, Color(1, 0.85, 0, a * eye_glow))
	draw_circle(Vector2(cx, cy - 7), 1.5, Color(1, 0.85, 0, a * eye_glow))
	draw_circle(Vector2(cx - 4, cy - 7), 0.7, Color(1, 1, 0.7, a * eye_glow))
	draw_circle(Vector2(cx, cy - 7), 0.7, Color(1, 1, 0.7, a * eye_glow))
	# Bow arm
	draw_line(Vector2(cx + 3, cy + 1), Vector2(cx + 11, cy + 1), Color(0.7, 0.2, 0.18, a), 2.0)
	# Bow (more curved, dynamic with flex animation)
	var bow_flex: float = 0.1 * sin(t * 3.0)
	draw_arc(Vector2(cx + 11, cy + 1), 11, -1.3 - bow_flex, 1.3 + bow_flex, 18, Color(0.45, 0.22, 0.08, a), 3.5)
	draw_arc(Vector2(cx + 11, cy + 1), 10.5, -1.1 - bow_flex, 1.1 + bow_flex, 14, Color(0.6, 0.35, 0.12, a), 2.0)
	draw_arc(Vector2(cx + 11, cy + 1), 10, -0.8 - bow_flex, 0.8 + bow_flex, 10, Color(0.75, 0.45, 0.18, a * 0.5), 1.0)
	# Bow tips
	var bta: float = -1.3 - bow_flex
	var bba: float = 1.3 + bow_flex
	draw_circle(Vector2(cx + 11 + 11 * cos(bta), cy + 1 + 11 * sin(bta)), 1.5, Color(0.6, 0.35, 0.12, a))
	draw_circle(Vector2(cx + 11 + 11 * cos(bba), cy + 1 + 11 * sin(bba)), 1.5, Color(0.6, 0.35, 0.12, a))
	# Bowstring
	var bt := Vector2(cx + 11 + 11 * cos(bta), cy + 1 + 11 * sin(bta))
	var bb := Vector2(cx + 11 + 11 * cos(bba), cy + 1 + 11 * sin(bba))
	draw_line(bt, Vector2(cx + 7, cy + 1), Color(0.85, 0.8, 0.5, a * 0.9), 1.0)
	draw_line(bb, Vector2(cx + 7, cy + 1), Color(0.85, 0.8, 0.5, a * 0.9), 1.0)
	# Flaming arrow shaft with glow
	draw_circle(Vector2(cx + 10, cy + 1), 2.0, Color(1, 0.5, 0.1, a * 0.1))
	draw_line(Vector2(cx, cy + 1), Vector2(cx + 17, cy + 1), Color(0.85, 0.7, 0.25, a), 1.5)
	draw_line(Vector2(cx + 2, cy + 1), Vector2(cx + 15, cy + 1), Color(0.95, 0.8, 0.4, a * 0.5), 0.8)
	# Arrow tip (fiery glow, layered)
	draw_circle(Vector2(cx + 18, cy + 1), 4.5, Color(1, 0.35, 0.05, a * 0.2))
	draw_circle(Vector2(cx + 18, cy + 1), 3.0, Color(1, 0.5, 0.1, a * 0.3))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 21, cy + 1), Vector2(cx + 15, cy - 2.5), Vector2(cx + 15, cy + 4.5)
	]), Color(0.95, 0.4, 0.1, a))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 20, cy + 1), Vector2(cx + 16, cy - 1.5), Vector2(cx + 16, cy + 3.5)
	]), Color(1.0, 0.65, 0.2, a * 0.8))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 19, cy + 1), Vector2(cx + 17, cy - 0.5), Vector2(cx + 17, cy + 2.5)
	]), Color(1.0, 0.9, 0.5, a * 0.5))

func _draw_avatar_mage(cx: float, cy: float, a: float) -> void:
	var t := GM.game_time
	# Animated flames at base (color gradient: red core -> orange -> yellow tip)
	for i in range(6):
		var fx: float = cx - 10 + float(i) * 4.0
		var fy: float = cy + 14
		var flame_h: float = 6 + 3 * sin(t * 4.5 + float(i) * 1.3)
		var flame_sway: float = sin(t * 3.0 + float(i) * 2.0) * 1.5
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx + flame_sway, fy - flame_h), Vector2(fx + 3, fy), Vector2(fx - 3, fy)
		]), Color(0.9, 0.15, 0.05, a * 0.5))
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx + flame_sway * 0.7, fy - flame_h * 0.75), Vector2(fx + 2, fy - 1), Vector2(fx - 2, fy - 1)
		]), Color(1.0, 0.5, 0.1, a * 0.6))
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx + flame_sway * 0.4, fy - flame_h * 0.45), Vector2(fx + 1.2, fy - 2), Vector2(fx - 1.2, fy - 2)
		]), Color(1.0, 0.9, 0.35, a * 0.5))
	# Drop shadow
	draw_circle(Vector2(cx + 1, cy + 2), 17, Color(0, 0, 0, a * 0.3))
	# Base platform layered
	draw_circle(Vector2(cx, cy), 18, Color(0.15, 0.03, 0.2, a))
	draw_circle(Vector2(cx, cy), 16, Color(0.22, 0.06, 0.28, a))
	draw_circle(Vector2(cx - 1, cy - 1), 13, Color(0.28, 0.08, 0.32, a * 0.5))
	draw_arc(Vector2(cx, cy), 18, 0, TAU, 32, Color(0.65, 0.25, 0.85, a * 0.55), 1.5)
	draw_arc(Vector2(cx, cy), 17, PI * 1.0, PI * 1.6, 10, Color(0.8, 0.4, 1.0, a * 0.2), 1.0)
	# Wide flowing robe with multiple fold layers
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 5, cy - 2), Vector2(cx + 5, cy - 2),
		Vector2(cx + 13, cy + 15), Vector2(cx - 13, cy + 15)
	]), Color(0.35, 0.08, 0.48, a))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 3, cy - 1), Vector2(cx + 3, cy - 1),
		Vector2(cx + 9, cy + 14), Vector2(cx - 9, cy + 14)
	]), Color(0.42, 0.1, 0.58, a))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 1, cy), Vector2(cx + 2, cy),
		Vector2(cx + 5, cy + 13), Vector2(cx - 3, cy + 13)
	]), Color(0.52, 0.16, 0.68, a))
	# Robe edge highlights
	draw_line(Vector2(cx - 5, cy - 2), Vector2(cx - 13, cy + 15), Color(0.6, 0.2, 0.78, a * 0.35), 1.0)
	draw_line(Vector2(cx + 5, cy - 2), Vector2(cx + 13, cy + 15), Color(0.6, 0.2, 0.78, a * 0.35), 1.0)
	# Robe rune marks (animated glow)
	var rune_glow: float = 0.3 + 0.4 * sin(t * 2.5)
	draw_circle(Vector2(cx, cy + 4), 1.8, Color(1, 0.5, 0.9, a * rune_glow))
	draw_circle(Vector2(cx, cy + 4), 1.0, Color(1, 0.8, 1.0, a * rune_glow * 0.6))
	draw_circle(Vector2(cx - 3, cy + 8), 1.2, Color(1, 0.5, 0.9, a * rune_glow * 0.7))
	draw_circle(Vector2(cx + 3, cy + 8), 1.2, Color(1, 0.5, 0.9, a * rune_glow * 0.7))
	draw_circle(Vector2(cx - 1, cy + 12), 1.0, Color(1, 0.5, 0.9, a * rune_glow * 0.5))
	draw_circle(Vector2(cx + 1, cy + 12), 1.0, Color(1, 0.5, 0.9, a * rune_glow * 0.5))
	# Head with layered shading
	draw_circle(Vector2(cx, cy - 5), 5.8, Color(0.42, 0.1, 0.58, a))
	draw_circle(Vector2(cx, cy - 5), 5.0, Color(0.5, 0.14, 0.65, a))
	draw_circle(Vector2(cx - 0.5, cy - 5.5), 3.5, Color(0.6, 0.18, 0.75, a * 0.5))
	# Pointed hat with layered shading
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 1, cy - 20), Vector2(cx + 8, cy - 4), Vector2(cx - 7, cy - 4)
	]), Color(0.38, 0.06, 0.52, a))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 1, cy - 19), Vector2(cx + 5, cy - 5), Vector2(cx - 4, cy - 5)
	]), Color(0.45, 0.1, 0.6, a * 0.7))
	# Hat highlight edges
	draw_line(Vector2(cx + 1, cy - 20), Vector2(cx + 8, cy - 4), Color(0.6, 0.2, 0.78, a * 0.6), 1.0)
	draw_line(Vector2(cx + 1, cy - 20), Vector2(cx - 7, cy - 4), Color(0.55, 0.15, 0.7, a * 0.3), 1.0)
	# Hat band with gem
	draw_line(Vector2(cx - 8, cy - 4), Vector2(cx + 9, cy - 4), Color(0.7, 0.28, 0.88, a), 2.8)
	draw_line(Vector2(cx - 8, cy - 4), Vector2(cx + 9, cy - 4), Color(0.85, 0.4, 1.0, a * 0.3), 1.2)
	draw_circle(Vector2(cx, cy - 4), 2.5, Color(1, 0.55, 0.15, a * 0.7))
	draw_circle(Vector2(cx, cy - 4), 1.5, Color(1, 0.8, 0.4, a * 0.9))
	# Floating arcane runes orbiting the hat
	for i in range(4):
		var rune_angle: float = t * 1.8 + float(i) * TAU / 4.0
		var rune_dist: float = 10 + sin(t * 1.2 + float(i) * 1.5) * 2.0
		var rx: float = cx + cos(rune_angle) * rune_dist
		var ry: float = cy - 12 + sin(rune_angle) * rune_dist * 0.4
		var rune_a: float = 0.4 + 0.3 * sin(t * 2.0 + float(i) * 1.8)
		draw_circle(Vector2(rx, ry), 2.5, Color(0.8, 0.4, 1.0, a * rune_a * 0.25))
		draw_circle(Vector2(rx, ry), 1.2, Color(0.9, 0.6, 1.0, a * rune_a))
		draw_line(Vector2(rx - 1.5, ry), Vector2(rx + 1.5, ry), Color(1, 0.7, 1.0, a * rune_a * 0.6), 0.8)
		draw_line(Vector2(rx, ry - 1.5), Vector2(rx, ry + 1.5), Color(1, 0.7, 1.0, a * rune_a * 0.6), 0.8)
	# Glowing eyes (animated)
	var eye_pulse: float = 0.7 + 0.3 * sin(t * 3.5)
	draw_circle(Vector2(cx - 2, cy - 6), 2.2, Color(0.8, 0.3, 1.0, a * 0.2))
	draw_circle(Vector2(cx + 2, cy - 6), 2.2, Color(0.8, 0.3, 1.0, a * 0.2))
	draw_circle(Vector2(cx - 2, cy - 6), 1.3, Color(0.9, 0.5, 1.0, a * eye_pulse))
	draw_circle(Vector2(cx + 2, cy - 6), 1.3, Color(0.9, 0.5, 1.0, a * eye_pulse))
	draw_circle(Vector2(cx - 2, cy - 6), 0.6, Color(1, 0.8, 1.0, a * eye_pulse))
	draw_circle(Vector2(cx + 2, cy - 6), 0.6, Color(1, 0.8, 1.0, a * eye_pulse))
	# Staff (left side, detailed with wrap)
	draw_line(Vector2(cx - 8, cy - 8), Vector2(cx - 8, cy + 12), Color(0.4, 0.22, 0.15, a), 3.0)
	draw_line(Vector2(cx - 7, cy - 8), Vector2(cx - 7, cy + 12), Color(0.55, 0.35, 0.22, a), 1.2)
	for si in range(4):
		var sy: float = cy - 4 + float(si) * 5.0
		draw_line(Vector2(cx - 9.5, sy), Vector2(cx - 6.5, sy + 2), Color(0.5, 0.3, 0.15, a * 0.5), 1.0)
	# Staff orb (animated pulsing with rotating ring)
	var orb_pulse: float = 0.6 + 0.4 * sin(t * 3.0)
	draw_circle(Vector2(cx - 8, cy - 10), 7, Color(1, 0.4, 0.08, a * 0.12 * orb_pulse))
	draw_circle(Vector2(cx - 8, cy - 10), 5, Color(1, 0.48, 0.12, a * 0.3))
	draw_circle(Vector2(cx - 8, cy - 10), 3.5, Color(1, 0.6, 0.2, a * 0.55))
	draw_circle(Vector2(cx - 8, cy - 10), 2.0, Color(1, 0.8, 0.4, a * orb_pulse))
	# Rotating ring around staff orb
	draw_arc(Vector2(cx - 8, cy - 10), 6, t * 2.0, t * 2.0 + PI * 1.2, 12, Color(1, 0.6, 0.25, a * 0.5 * orb_pulse), 1.2)
	draw_arc(Vector2(cx - 8, cy - 10), 6, t * 2.0 + PI, t * 2.0 + PI * 2.2, 12, Color(1, 0.6, 0.25, a * 0.3 * orb_pulse), 0.8)

func _draw_avatar_necro(cx: float, cy: float, a: float) -> void:
	var t := GM.game_time
	# Subtle vortex pattern in green aura
	var aura_pulse: float = 0.12 + 0.07 * sin(t * 2.0)
	draw_circle(Vector2(cx, cy), 23, Color(0.08, 0.5, 0.2, a * aura_pulse * 0.5))
	draw_circle(Vector2(cx, cy), 21, Color(0.1, 0.6, 0.25, a * aura_pulse))
	draw_circle(Vector2(cx, cy), 19, Color(0.08, 0.45, 0.2, a * aura_pulse * 0.7))
	# Vortex swirl arcs
	for vi in range(3):
		var va: float = t * 1.2 + float(vi) * TAU / 3.0
		var vr: float = 18 + sin(t * 0.8 + float(vi)) * 3.0
		draw_arc(Vector2(cx, cy), vr, va, va + 1.2, 8, Color(0.15, 0.7, 0.35, a * aura_pulse * 0.6), 1.0)
	# Floating bone fragments around the character
	for bi in range(4):
		var bone_angle: float = t * 0.9 + float(bi) * TAU / 4.0
		var bone_dist: float = 16 + sin(t * 1.5 + float(bi) * 1.7) * 3.0
		var bfx: float = cx + cos(bone_angle) * bone_dist
		var bfy: float = cy + sin(bone_angle) * bone_dist * 0.65
		var bone_rot: float = bone_angle + t * 1.5
		var bone_a: float = 0.35 + 0.2 * sin(t * 2.0 + float(bi))
		var bl: float = 3.0
		draw_line(
			Vector2(bfx - cos(bone_rot) * bl, bfy - sin(bone_rot) * bl),
			Vector2(bfx + cos(bone_rot) * bl, bfy + sin(bone_rot) * bl),
			Color(0.85, 0.82, 0.7, a * bone_a), 1.5)
		draw_circle(Vector2(bfx - cos(bone_rot) * bl, bfy - sin(bone_rot) * bl), 1.0, Color(0.9, 0.87, 0.75, a * bone_a))
		draw_circle(Vector2(bfx + cos(bone_rot) * bl, bfy + sin(bone_rot) * bl), 1.0, Color(0.9, 0.87, 0.75, a * bone_a))
	# Drop shadow
	draw_circle(Vector2(cx + 1, cy + 2), 17, Color(0, 0, 0, a * 0.3))
	# Base platform layered
	draw_circle(Vector2(cx, cy), 18, Color(0.04, 0.15, 0.08, a))
	draw_circle(Vector2(cx, cy), 16, Color(0.06, 0.2, 0.1, a))
	draw_circle(Vector2(cx - 1, cy - 1), 13, Color(0.08, 0.25, 0.13, a * 0.5))
	draw_arc(Vector2(cx, cy), 18, 0, TAU, 32, Color(0.25, 0.85, 0.45, a * 0.5), 1.5)
	# Tattered robe with wispy dissolving edges
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 6, cy - 6), Vector2(cx + 6, cy - 6),
		Vector2(cx + 11, cy + 14), Vector2(cx - 11, cy + 14)
	]), Color(0.08, 0.25, 0.12, a))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 4, cy - 5), Vector2(cx + 4, cy - 5),
		Vector2(cx + 8, cy + 13), Vector2(cx - 8, cy + 13)
	]), Color(0.12, 0.32, 0.16, a))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 1, cy - 4), Vector2(cx + 2, cy - 4),
		Vector2(cx + 4, cy + 13), Vector2(cx - 3, cy + 13)
	]), Color(0.16, 0.4, 0.22, a))
	# Tattered hem tendrils (wispy, dissolving)
	for ti in range(7):
		var ttx: float = cx - 9 + float(ti) * 3.0
		var tendril_len: float = 4.0 + sin(t * 2.5 + float(ti) * 1.1) * 2.5
		var tendril_sway: float = sin(t * 1.8 + float(ti) * 0.9) * 2.0
		var tendril_a: float = 0.5 - float(ti % 3) * 0.1
		draw_line(Vector2(ttx, cy + 14), Vector2(ttx + tendril_sway, cy + 14 + tendril_len), Color(0.08, 0.28, 0.14, a * tendril_a), 1.2)
		draw_line(Vector2(ttx, cy + 14 + tendril_len * 0.5), Vector2(ttx + tendril_sway * 1.3, cy + 14 + tendril_len + 1.5), Color(0.1, 0.35, 0.18, a * tendril_a * 0.4), 0.8)
	# Hood with depth layers
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy - 16), Vector2(cx + 9, cy - 4), Vector2(cx - 9, cy - 4)
	]), Color(0.06, 0.2, 0.1, a))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy - 15), Vector2(cx + 6, cy - 5), Vector2(cx - 6, cy - 5)
	]), Color(0.1, 0.28, 0.14, a))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy - 14), Vector2(cx + 4, cy - 6), Vector2(cx - 4, cy - 6)
	]), Color(0.14, 0.35, 0.18, a * 0.6))
	draw_line(Vector2(cx, cy - 16), Vector2(cx + 9, cy - 4), Color(0.2, 0.5, 0.25, a * 0.3), 1.0)
	# Skull face with more detail
	draw_circle(Vector2(cx, cy - 5), 5.8, Color(0.78, 0.78, 0.72, a))
	draw_circle(Vector2(cx, cy - 5), 5.2, Color(0.85, 0.85, 0.8, a))
	draw_circle(Vector2(cx - 0.5, cy - 5.5), 4.0, Color(0.92, 0.92, 0.87, a * 0.6))
	# Skull crack details
	draw_line(Vector2(cx - 1.5, cy - 9), Vector2(cx - 0.5, cy - 7), Color(0.55, 0.55, 0.5, a), 0.8)
	draw_line(Vector2(cx - 0.5, cy - 7), Vector2(cx + 0.5, cy - 5.5), Color(0.55, 0.55, 0.5, a), 0.8)
	draw_line(Vector2(cx + 0.5, cy - 5.5), Vector2(cx + 1.5, cy - 4.5), Color(0.6, 0.6, 0.55, a * 0.6), 0.6)
	draw_line(Vector2(cx + 2, cy - 9), Vector2(cx + 2.5, cy - 7.5), Color(0.55, 0.55, 0.5, a * 0.7), 0.7)
	# Glowing eye sockets
	var eye_glow: float = 0.65 + 0.35 * sin(t * 3.2)
	draw_circle(Vector2(cx - 2, cy - 6), 2.5, Color(0.1, 0.7, 0.25, a * 0.2))
	draw_circle(Vector2(cx + 2, cy - 6), 2.5, Color(0.1, 0.7, 0.25, a * 0.2))
	draw_circle(Vector2(cx - 2, cy - 6), 1.5, Color(0.15, 0.9, 0.35, a * eye_glow))
	draw_circle(Vector2(cx + 2, cy - 6), 1.5, Color(0.15, 0.9, 0.35, a * eye_glow))
	draw_circle(Vector2(cx - 2, cy - 6), 0.7, Color(0.4, 1.0, 0.6, a * eye_glow))
	draw_circle(Vector2(cx + 2, cy - 6), 0.7, Color(0.4, 1.0, 0.6, a * eye_glow))
	# Nose cavity
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy - 3.5), Vector2(cx + 1.4, cy - 1.8), Vector2(cx - 1.4, cy - 1.8)
	]), Color(0.04, 0.12, 0.04, a))
	# Jaw with articulation (slight open/close)
	var jaw_open: float = 0.3 + 0.15 * sin(t * 1.8)
	for i in range(5):
		var utx: float = cx - 2.5 + float(i) * 1.2
		draw_line(Vector2(utx, cy - 1.5), Vector2(utx, cy - 0.5 - jaw_open * 0.3), Color(0.82, 0.82, 0.77, a), 0.8)
	draw_arc(Vector2(cx, cy - 2.5 + jaw_open), 3.8, 0.2, PI - 0.2, 8, Color(0.75, 0.75, 0.7, a), 1.2)
	for i in range(4):
		var ltx: float = cx - 2.0 + float(i) * 1.3
		draw_line(Vector2(ltx, cy - 0.5 + jaw_open * 0.5), Vector2(ltx, cy - 1.2), Color(0.82, 0.82, 0.77, a * 0.8), 0.7)
	# Staff (right side, bone-like with segments)
	draw_line(Vector2(cx + 8, cy - 13), Vector2(cx + 8, cy + 11), Color(0.3, 0.18, 0.08, a), 3.0)
	draw_line(Vector2(cx + 9, cy - 12), Vector2(cx + 9, cy + 10), Color(0.45, 0.3, 0.15, a), 1.2)
	# Staff joint knobs
	draw_circle(Vector2(cx + 8.5, cy - 4), 2.0, Color(0.5, 0.35, 0.15, a))
	draw_circle(Vector2(cx + 8.5, cy - 4), 1.2, Color(0.6, 0.45, 0.22, a * 0.6))
	draw_circle(Vector2(cx + 8.5, cy + 4), 2.0, Color(0.5, 0.35, 0.15, a))
	draw_circle(Vector2(cx + 8.5, cy + 4), 1.2, Color(0.6, 0.45, 0.22, a * 0.6))
	# Staff skull orb (pulsing green, layered)
	var orb_pulse: float = 0.6 + 0.4 * sin(t * 2.5)
	draw_circle(Vector2(cx + 8, cy - 14), 8, Color(0.12, 0.7, 0.3, a * 0.1 * orb_pulse))
	draw_circle(Vector2(cx + 8, cy - 14), 6, Color(0.18, 0.8, 0.35, a * 0.2))
	draw_circle(Vector2(cx + 8, cy - 14), 4, Color(0.25, 0.9, 0.4, a * 0.4))
	draw_circle(Vector2(cx + 8, cy - 14), 2.5, Color(0.35, 1.0, 0.55, a * orb_pulse))
	# Soul wisps with fading trails
	for i in range(4):
		var angle: float = t * (1.3 + float(i) * 0.4) + float(i) * TAU / 4.0
		var dist: float = 14 + 4 * sin(t * 1.0 + float(i) * 1.3)
		var wx: float = cx + cos(angle) * dist
		var wy: float = cy + sin(angle) * (dist * 0.65)
		var wisp_a: float = 0.35 + 0.2 * sin(t * 3.0 + float(i) * 2.0)
		# Trail (3 fading positions behind)
		for trail_i in range(3):
			var trail_t: float = t - float(trail_i + 1) * 0.08
			var trail_angle: float = trail_t * (1.3 + float(i) * 0.4) + float(i) * TAU / 4.0
			var trail_dist: float = 14 + 4 * sin(trail_t * 1.0 + float(i) * 1.3)
			var trail_x: float = cx + cos(trail_angle) * trail_dist
			var trail_y: float = cy + sin(trail_angle) * (trail_dist * 0.65)
			var trail_a: float = wisp_a * (0.4 - float(trail_i) * 0.12)
			draw_circle(Vector2(trail_x, trail_y), 1.5, Color(0.2, 0.8, 0.4, a * trail_a * 0.3))
		# Main wisp
		draw_circle(Vector2(wx, wy), 3.5, Color(0.18, 0.85, 0.38, a * wisp_a * 0.3))
		draw_circle(Vector2(wx, wy), 2.0, Color(0.3, 1.0, 0.5, a * wisp_a))
		draw_circle(Vector2(wx, wy), 0.8, Color(0.6, 1.0, 0.7, a * wisp_a * 0.7))

func _draw_avatar_lucifer(cx: float, cy: float, a: float) -> void:
	# Drop shadow
	draw_circle(Vector2(cx + 1, cy + 2), 17, Color(0, 0, 0, a * 0.3))
	# Hellfire aura (pulsing orange-red)
	var aura_pulse: float = 0.15 + 0.1 * sin(GM.game_time * 2.5)
	draw_circle(Vector2(cx, cy), 24, Color(1.0, 0.3, 0.0, a * aura_pulse))
	draw_circle(Vector2(cx, cy), 21, Color(1.0, 0.2, 0.0, a * aura_pulse * 0.7))
	# Base platform with infernal glow
	draw_circle(Vector2(cx, cy), 18, Color(0.3, 0.08, 0.02, a))
	draw_arc(Vector2(cx, cy), 18, 0, TAU, 24, Color(1.0, 0.4, 0.0, a * 0.6), 2.0)
	# Body — dark armored torso
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 7, cy - 4), Vector2(cx + 7, cy - 4),
		Vector2(cx + 9, cy + 14), Vector2(cx - 9, cy + 14)
	]), Color(0.2, 0.05, 0.02, a))
	# Armor highlight
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 2, cy - 2), Vector2(cx + 3, cy - 2),
		Vector2(cx + 4, cy + 12), Vector2(cx - 3, cy + 12)
	]), Color(0.35, 0.1, 0.05, a))
	# Head
	draw_circle(Vector2(cx, cy - 8), 6, Color(0.25, 0.06, 0.02, a))
	draw_circle(Vector2(cx, cy - 8), 5, Color(0.35, 0.1, 0.04, a))
	# Massive horns (Lucifer's trademark)
	draw_line(Vector2(cx - 5, cy - 12), Vector2(cx - 10, cy - 20), Color(0.9, 0.3, 0.05, a), 3.0)
	draw_line(Vector2(cx - 10, cy - 20), Vector2(cx - 12, cy - 24), Color(1.0, 0.5, 0.1, a), 2.0)
	draw_line(Vector2(cx + 5, cy - 12), Vector2(cx + 10, cy - 20), Color(0.9, 0.3, 0.05, a), 3.0)
	draw_line(Vector2(cx + 10, cy - 20), Vector2(cx + 12, cy - 24), Color(1.0, 0.5, 0.1, a), 2.0)
	# Burning eyes (intense pulse)
	var eye_glow: float = 0.7 + 0.3 * sin(GM.game_time * 5.0)
	draw_circle(Vector2(cx - 3, cy - 9), 3.0, Color(1, 0.5, 0.0, a * 0.2))
	draw_circle(Vector2(cx + 3, cy - 9), 3.0, Color(1, 0.5, 0.0, a * 0.2))
	draw_circle(Vector2(cx - 3, cy - 9), 1.8, Color(1, 0.7, 0.0, a * eye_glow))
	draw_circle(Vector2(cx + 3, cy - 9), 1.8, Color(1, 0.7, 0.0, a * eye_glow))
	# Dark wings (spread wide)
	var wing_col := Color(0.15, 0.03, 0.0, a * 0.8)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 8, cy - 2), Vector2(cx - 20, cy - 12),
		Vector2(cx - 18, cy - 4), Vector2(cx - 14, cy + 4)
	]), wing_col)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 8, cy - 2), Vector2(cx + 20, cy - 12),
		Vector2(cx + 18, cy - 4), Vector2(cx + 14, cy + 4)
	]), wing_col)
	# Wing edge glow
	draw_line(Vector2(cx - 8, cy - 2), Vector2(cx - 20, cy - 12), Color(1, 0.35, 0.0, a * 0.4), 1.0)
	draw_line(Vector2(cx + 8, cy - 2), Vector2(cx + 20, cy - 12), Color(1, 0.35, 0.0, a * 0.4), 1.0)
	# Animated hellfire ring (global attack indicator)
	var t := GM.game_time
	for i in range(6):
		var angle: float = t * 1.5 + float(i) * TAU / 6.0
		var dist: float = 16 + 2 * sin(t * 2.0 + float(i))
		var fx: float = cx + cos(angle) * dist
		var fy: float = cy + sin(angle) * dist * 0.7
		var fire_a: float = 0.3 + 0.2 * sin(t * 4.0 + float(i) * 1.5)
		draw_circle(Vector2(fx, fy), 2.5, Color(1, 0.4, 0.0, a * fire_a * 0.3))
		draw_circle(Vector2(fx, fy), 1.5, Color(1, 0.7, 0.2, a * fire_a))

func _draw_avatar_hades(cx: float, cy: float, a: float) -> void:
	# Drop shadow
	draw_circle(Vector2(cx + 1, cy + 2), 17, Color(0, 0, 0, a * 0.25))
	# Buff aura (pulsing blue-purple, shows when buff active)
	var is_buffing: bool = false
	for t_check in GM.towers:
		if t_check.get("type") == "hades" and t_check.get("buff_active_timer", 0.0) > 0:
			is_buffing = true
			break
	var aura_intensity: float = 0.2 if is_buffing else 0.08
	var aura_pulse: float = aura_intensity + 0.06 * sin(GM.game_time * 3.0)
	draw_circle(Vector2(cx, cy), 22, Color(0.3, 0.2, 0.9, a * aura_pulse))
	# Base platform with dark royal glow
	draw_circle(Vector2(cx, cy), 18, Color(0.08, 0.05, 0.2, a))
	draw_arc(Vector2(cx, cy), 18, 0, TAU, 24, Color(0.3, 0.2, 0.9, a * 0.5), 1.5)
	# Dark robe body
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 6, cy - 4), Vector2(cx + 6, cy - 4),
		Vector2(cx + 12, cy + 14), Vector2(cx - 12, cy + 14)
	]), Color(0.1, 0.06, 0.25, a))
	# Robe fold highlight
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 1, cy - 2), Vector2(cx + 2, cy - 2),
		Vector2(cx + 4, cy + 13), Vector2(cx - 3, cy + 13)
	]), Color(0.15, 0.08, 0.35, a))
	# Runic symbols on robe (animated glow)
	var rune_glow: float = 0.3 + 0.3 * sin(GM.game_time * 2.0)
	draw_circle(Vector2(cx, cy + 4), 1.5, Color(0.4, 0.3, 1.0, a * rune_glow))
	draw_circle(Vector2(cx - 2, cy + 8), 1.0, Color(0.4, 0.3, 1.0, a * rune_glow * 0.7))
	draw_circle(Vector2(cx + 2, cy + 8), 1.0, Color(0.4, 0.3, 1.0, a * rune_glow * 0.7))
	# Head with crown
	draw_circle(Vector2(cx, cy - 7), 5.5, Color(0.15, 0.08, 0.3, a))
	draw_circle(Vector2(cx, cy - 7), 4.5, Color(0.2, 0.12, 0.4, a))
	# Crown of Hades (bident-style points)
	draw_line(Vector2(cx - 3, cy - 11), Vector2(cx - 4, cy - 18), Color(0.4, 0.3, 0.9, a), 2.0)
	draw_line(Vector2(cx + 3, cy - 11), Vector2(cx + 4, cy - 18), Color(0.4, 0.3, 0.9, a), 2.0)
	draw_line(Vector2(cx - 4, cy - 18), Vector2(cx - 5, cy - 20), Color(0.5, 0.4, 1.0, a), 1.5)
	draw_line(Vector2(cx + 4, cy - 18), Vector2(cx + 5, cy - 20), Color(0.5, 0.4, 1.0, a), 1.5)
	# Glowing eyes (deep purple)
	var eye_pulse: float = 0.7 + 0.3 * sin(GM.game_time * 3.5)
	draw_circle(Vector2(cx - 2, cy - 8), 2.0, Color(0.5, 0.3, 1.0, a * 0.2))
	draw_circle(Vector2(cx + 2, cy - 8), 2.0, Color(0.5, 0.3, 1.0, a * 0.2))
	draw_circle(Vector2(cx - 2, cy - 8), 1.2, Color(0.6, 0.4, 1.0, a * eye_pulse))
	draw_circle(Vector2(cx + 2, cy - 8), 1.2, Color(0.6, 0.4, 1.0, a * eye_pulse))
	# Bident staff (right side)
	draw_line(Vector2(cx + 9, cy - 10), Vector2(cx + 9, cy + 12), Color(0.3, 0.2, 0.5, a), 2.5)
	draw_line(Vector2(cx + 7, cy - 12), Vector2(cx + 7, cy - 16), Color(0.4, 0.3, 0.8, a), 2.0)
	draw_line(Vector2(cx + 11, cy - 12), Vector2(cx + 11, cy - 16), Color(0.4, 0.3, 0.8, a), 2.0)
	# Staff orb (pulsing blue)
	var orb_pulse: float = 0.6 + 0.4 * sin(GM.game_time * 2.5)
	draw_circle(Vector2(cx + 9, cy - 12), 5, Color(0.3, 0.2, 0.9, a * 0.15 * orb_pulse))
	draw_circle(Vector2(cx + 9, cy - 12), 3, Color(0.4, 0.3, 1.0, a * 0.35))
	draw_circle(Vector2(cx + 9, cy - 12), 2, Color(0.5, 0.4, 1.0, a * orb_pulse))
	# Speed buff particles (orbiting)
	if is_buffing:
		var t := GM.game_time
		for i in range(4):
			var angle: float = t * 3.0 + float(i) * TAU / 4.0
			var dist: float = 15
			var bx: float = cx + cos(angle) * dist
			var by: float = cy + sin(angle) * dist * 0.6
			draw_circle(Vector2(bx, by), 2.5, Color(0.4, 0.3, 1.0, a * 0.5))
			draw_circle(Vector2(bx, by), 1.5, Color(0.6, 0.5, 1.0, a * 0.8))

# ═══════════════════════════════════════════════════════
# ENEMY AVATARS
# ═══════════════════════════════════════════════════════

func _draw_enemy_scout(ex: float, ey: float, er: float, flash: bool) -> void:
	var col: Color = Color(1, 0.2, 0.2) if flash else Color(1.0, 0.87, 0.27)
	# Shadow
	draw_circle(Vector2(ex + 1, ey + 1), er, Color(0, 0, 0, 0.2))
	# Body with inner glow
	draw_circle(Vector2(ex, ey), er, col)
	draw_circle(Vector2(ex - 1, ey - 1), er * 0.6, col.lightened(0.15))
	# Wings (two small triangles on sides)
	var wc := col.lightened(0.3)
	# Left wing
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex - er, ey), Vector2(ex - er - 5, ey - 4), Vector2(ex - er - 2, ey + 2)
	]), wc)
	# Right wing
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex + er, ey), Vector2(ex + er + 5, ey - 4), Vector2(ex + er + 2, ey + 2)
	]), wc)
	# Halo
	draw_arc(Vector2(ex, ey - er - 2), 3.5, 0, TAU, 12, Color(1, 1, 0.6), 1.0)

func _draw_enemy_knight(ex: float, ey: float, er: float, flash: bool) -> void:
	var col: Color = Color(1, 0.2, 0.2) if flash else Color(0.91, 0.91, 0.91)
	# Shadow
	draw_circle(Vector2(ex + 1, ey + 1), er, Color(0, 0, 0, 0.2))
	# Body (armored with highlight)
	draw_circle(Vector2(ex, ey), er, col * 0.75)
	draw_arc(Vector2(ex, ey), er * 0.85, PI * 1.2, PI * 1.8, 8, col.lightened(0.1), 1.0)
	# Helmet top (arc ridge)
	draw_arc(Vector2(ex, ey - er * 0.3), er * 0.7, PI + 0.3, TAU - 0.3, 10, col, 2.0)
	# Visor slit
	draw_line(Vector2(ex - er * 0.4, ey - 1), Vector2(ex + er * 0.4, ey - 1), Color(0.2, 0.2, 0.3), 1.5)
	# Cross on chest
	draw_line(Vector2(ex, ey + 1), Vector2(ex, ey + er * 0.7), Color(0.8, 0.75, 0.2), 1.5)
	draw_line(Vector2(ex - er * 0.3, ey + er * 0.3), Vector2(ex + er * 0.3, ey + er * 0.3), Color(0.8, 0.75, 0.2), 1.5)
	# Shield highlight
	draw_arc(Vector2(ex, ey), er, -0.5, 0.5, 6, Color(1, 1, 1, 0.5), 1.5)

func _draw_enemy_hunter(ex: float, ey: float, er: float, flash: bool) -> void:
	var col: Color = Color(1, 0.2, 0.2) if flash else Color(0.27, 0.87, 1.0)
	# Motion blur trail
	draw_circle(Vector2(ex - 3, ey), er * 0.7, Color(col.r, col.g, col.b, 0.15))
	draw_circle(Vector2(ex - 6, ey), er * 0.4, Color(col.r, col.g, col.b, 0.08))
	# Body
	draw_circle(Vector2(ex, ey), er, col)
	# Speed chevrons (behind the body, showing fast movement)
	var chev_col := Color(0.2, 0.7, 0.9, 0.5)
	draw_line(Vector2(ex - er - 4, ey - 3), Vector2(ex - er - 1, ey), chev_col, 1.5)
	draw_line(Vector2(ex - er - 4, ey + 3), Vector2(ex - er - 1, ey), chev_col, 1.5)
	draw_line(Vector2(ex - er - 7, ey - 3), Vector2(ex - er - 4, ey), chev_col, 1.5)
	draw_line(Vector2(ex - er - 7, ey + 3), Vector2(ex - er - 4, ey), chev_col, 1.5)
	# Small wing tips (swept-back)
	draw_line(Vector2(ex - er * 0.5, ey - er * 0.3), Vector2(ex - er - 3, ey - er - 1), col.lightened(0.3), 1.5)
	draw_line(Vector2(ex - er * 0.5, ey + er * 0.3), Vector2(ex - er - 3, ey + er + 1), col.lightened(0.3), 1.5)
	# Eye (focused)
	draw_circle(Vector2(ex + 1, ey - 1), 1.5, Color(1, 1, 1, 0.8))

func _draw_enemy_war(ex: float, ey: float, er: float, flash: bool) -> void:
	var col: Color = Color(1, 0.2, 0.2) if flash else Color(1.0, 0.53, 0.27)
	# Shadow
	draw_circle(Vector2(ex + 1, ey + 1), er, Color(0, 0, 0, 0.25))
	# Body (armored, layered)
	draw_circle(Vector2(ex, ey), er, col * 0.8)
	draw_circle(Vector2(ex, ey), er * 0.85, col * 0.9)
	# Inner armor highlight
	draw_arc(Vector2(ex, ey), er * 0.6, 0, TAU, 12, col.lightened(0.2), 1.5)
	# Helmet crest (spike on top)
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex, ey - er - 5), Vector2(ex + 2, ey - er + 1), Vector2(ex - 2, ey - er + 1)
	]), Color(0.9, 0.4, 0.1))
	# Sword (pointing up-right)
	var sx := ex + er * 0.4
	var sy := ey - er * 0.2
	draw_line(Vector2(sx, sy), Vector2(sx + 5, sy - 7), Color(0.85, 0.85, 0.9), 2.0)
	# Sword crossguard
	draw_line(Vector2(sx + 3, sy - 4), Vector2(sx + 7, sy - 3), Color(0.7, 0.6, 0.2), 1.5)
	draw_line(Vector2(sx + 3, sy - 4), Vector2(sx + 1, sy - 7), Color(0.7, 0.6, 0.2), 1.5)
	# Angry eyes
	draw_line(Vector2(ex - 3, ey - 2), Vector2(ex - 1, ey - 1), Color(1, 0.9, 0.3), 1.5)
	draw_line(Vector2(ex + 3, ey - 2), Vector2(ex + 1, ey - 1), Color(1, 0.9, 0.3), 1.5)

func _draw_enemy_paladin(ex: float, ey: float, er: float, flash: bool) -> void:
	var col: Color = Color(1, 0.2, 0.2) if flash else Color(1.0, 0.8, 0.0)
	# Shadow
	draw_circle(Vector2(ex + 1, ey + 2), er, Color(0, 0, 0, 0.25))
	# Outer divine glow (animated)
	var divine_glow: float = 0.15 + 0.1 * sin(GM.game_time * 2.0)
	draw_circle(Vector2(ex, ey), er + 3, Color(1, 0.9, 0.3, divine_glow))
	draw_circle(Vector2(ex, ey), er + 1, Color(1, 0.85, 0.2, 0.2))
	# Body
	draw_circle(Vector2(ex, ey), er, col)
	# Inner armor
	draw_circle(Vector2(ex, ey), er * 0.65, col.darkened(0.2))
	# Large cross
	draw_line(Vector2(ex, ey - er * 0.6), Vector2(ex, ey + er * 0.6), Color(1, 1, 0.9), 2.5)
	draw_line(Vector2(ex - er * 0.4, ey - er * 0.1), Vector2(ex + er * 0.4, ey - er * 0.1), Color(1, 1, 0.9), 2.5)
	# Wings (larger, more majestic)
	var wing_col := Color(1, 0.95, 0.7, 0.8)
	# Left wing
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex - er, ey - 2), Vector2(ex - er - 7, ey - 6),
		Vector2(ex - er - 5, ey - 1), Vector2(ex - er - 3, ey + 3)
	]), wing_col)
	# Right wing
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex + er, ey - 2), Vector2(ex + er + 7, ey - 6),
		Vector2(ex + er + 5, ey - 1), Vector2(ex + er + 3, ey + 3)
	]), wing_col)
	# Crown
	draw_line(Vector2(ex - 4, ey - er), Vector2(ex - 2, ey - er - 4), Color(1, 0.9, 0.4), 1.5)
	draw_line(Vector2(ex, ey - er), Vector2(ex, ey - er - 5), Color(1, 0.9, 0.4), 1.5)
	draw_line(Vector2(ex + 4, ey - er), Vector2(ex + 2, ey - er - 4), Color(1, 0.9, 0.4), 1.5)

func _draw_enemy_monk(ex: float, ey: float, er: float, flash: bool) -> void:
	var col: Color = Color(1, 0.2, 0.2) if flash else Color(0.53, 1.0, 0.53)
	# Healing glow (subtle)
	draw_circle(Vector2(ex, ey), er + 2, Color(0.4, 1.0, 0.5, 0.1))
	# Body
	draw_circle(Vector2(ex, ey), er, col)
	draw_circle(Vector2(ex - 1, ey - 1), er * 0.6, col.lightened(0.1))
	# Hood (darker arc on top)
	draw_arc(Vector2(ex, ey - er * 0.15), er * 0.85, PI + 0.5, TAU - 0.5, 10, col.darkened(0.3), 3.0)
	# Halo (golden ring above)
	draw_arc(Vector2(ex, ey - er - 2.5), 3.5, 0, TAU, 12, Color(1, 0.95, 0.5, 0.8), 1.0)
	# Peaceful closed eyes
	draw_arc(Vector2(ex - 2, ey - 1), 1.5, 0.2, PI - 0.2, 6, Color(0.2, 0.5, 0.2), 1.0)
	draw_arc(Vector2(ex + 2, ey - 1), 1.5, 0.2, PI - 0.2, 6, Color(0.2, 0.5, 0.2), 1.0)
	# Prayer beads (small dots in an arc below)
	for i in range(3):
		var angle: float = 0.5 + i * 0.5
		var bx: float = ex + cos(angle) * (er + 2)
		var by: float = ey + sin(angle) * (er + 2)
		draw_circle(Vector2(bx, by), 1, Color(0.8, 0.7, 0.3, 0.7))

func _draw_enemy_archangel(ex: float, ey: float, er: float, flash: bool) -> void:
	var col: Color = Color(1, 0.2, 0.2) if flash else Color(1.0, 0.9, 0.5)
	# Command aura (pulsing golden ring)
	var pulse := 0.5 + 0.5 * sin(GM.game_time * 3.0)
	draw_circle(Vector2(ex, ey), er + 6, Color(1, 0.85, 0.3, 0.15 * pulse))
	draw_arc(Vector2(ex, ey), er + 5, 0, TAU, 24, Color(1, 0.85, 0.3, 0.4 * pulse), 1.5)
	# Body (golden armored)
	draw_circle(Vector2(ex, ey), er, col)
	draw_circle(Vector2(ex, ey), er * 0.7, col.darkened(0.15))
	# Large wings (majestic spread)
	var wc := Color(1, 0.95, 0.7, 0.9)
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex - er, ey - 1), Vector2(ex - er - 8, ey - 8),
		Vector2(ex - er - 6, ey - 3), Vector2(ex - er - 4, ey + 2)
	]), wc)
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex + er, ey - 1), Vector2(ex + er + 8, ey - 8),
		Vector2(ex + er + 6, ey - 3), Vector2(ex + er + 4, ey + 2)
	]), wc)
	# Crown (three spikes)
	draw_line(Vector2(ex - 3, ey - er), Vector2(ex - 2, ey - er - 5), Color(1, 0.85, 0.2), 1.5)
	draw_line(Vector2(ex, ey - er), Vector2(ex, ey - er - 7), Color(1, 0.85, 0.2), 2.0)
	draw_line(Vector2(ex + 3, ey - er), Vector2(ex + 2, ey - er - 5), Color(1, 0.85, 0.2), 1.5)
	# Commanding eyes (bright)
	draw_circle(Vector2(ex - 2, ey - 1), 1.5, Color(1, 1, 0.8))
	draw_circle(Vector2(ex + 2, ey - 1), 1.5, Color(1, 1, 0.8))
	# Scepter (right hand)
	draw_line(Vector2(ex + er * 0.5, ey - 2), Vector2(ex + er * 0.5, ey + er * 0.8), Color(0.8, 0.7, 0.3), 2.0)
	draw_circle(Vector2(ex + er * 0.5, ey - 3), 2.5, Color(1, 0.9, 0.3))

func _draw_enemy_guardian(ex: float, ey: float, er: float, flash: bool) -> void:
	var col: Color = Color(1, 0.2, 0.2) if flash else Color(0.6, 0.8, 1.0)
	# Shield dome aura
	var pulse := 0.5 + 0.5 * sin(GM.game_time * 2.5)
	draw_circle(Vector2(ex, ey), er + 5, Color(0.3, 0.5, 1.0, 0.1 * pulse))
	draw_arc(Vector2(ex, ey), er + 4, 0, TAU, 24, Color(0.4, 0.6, 1.0, 0.35 * pulse), 2.0)
	# Body (blue-white armored)
	draw_circle(Vector2(ex, ey), er, col)
	draw_circle(Vector2(ex, ey), er * 0.65, col.darkened(0.2))
	# Shield emblem (cross inside circle)
	draw_arc(Vector2(ex, ey), er * 0.45, 0, TAU, 12, Color(0.8, 0.9, 1.0, 0.8), 1.5)
	draw_line(Vector2(ex, ey - er * 0.35), Vector2(ex, ey + er * 0.35), Color(0.9, 0.95, 1.0), 1.5)
	draw_line(Vector2(ex - er * 0.25, ey), Vector2(ex + er * 0.25, ey), Color(0.9, 0.95, 1.0), 1.5)
	# Small wings
	var wc := Color(0.7, 0.85, 1.0, 0.8)
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex - er, ey), Vector2(ex - er - 5, ey - 4), Vector2(ex - er - 3, ey + 2)
	]), wc)
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex + er, ey), Vector2(ex + er + 5, ey - 4), Vector2(ex + er + 3, ey + 2)
	]), wc)
	# Halo (bright blue)
	draw_arc(Vector2(ex, ey - er - 2), 4, 0, TAU, 12, Color(0.5, 0.7, 1.0, 0.9), 1.5)
	# Serene eyes
	draw_arc(Vector2(ex - 2, ey - 1), 1.2, 0.2, PI - 0.2, 6, Color(0.3, 0.5, 0.9), 1.0)
	draw_arc(Vector2(ex + 2, ey - 1), 1.2, 0.2, PI - 0.2, 6, Color(0.3, 0.5, 0.9), 1.0)

func _draw_enemy_michael(ex: float, ey: float, er: float, flash: bool) -> void:
	var col: Color = Color(1, 0.2, 0.2) if flash else Color(1.0, 0.95, 0.8)
	# Shadow
	draw_circle(Vector2(ex + 1, ey + 2), er, Color(0, 0, 0, 0.3))
	# Massive divine aura (animated, larger than paladin)
	var divine_glow: float = 0.2 + 0.15 * sin(GM.game_time * 2.0)
	draw_circle(Vector2(ex, ey), er + 6, Color(1, 0.95, 0.5, divine_glow))
	draw_circle(Vector2(ex, ey), er + 3, Color(1, 0.9, 0.4, 0.25))
	# Shield pulse (when ability active)
	var shield_pulse: float = 0.0 + 0.3 * sin(GM.game_time * 4.0)
	draw_arc(Vector2(ex, ey), er + 8, 0, TAU, 32, Color(1, 0.95, 0.7, maxf(0, shield_pulse * 0.5)), 2.0)
	# Body (radiant white-gold)
	draw_circle(Vector2(ex, ey), er, col)
	draw_circle(Vector2(ex, ey), er * 0.7, col.darkened(0.1))
	# Inner armor (golden cross pattern)
	draw_line(Vector2(ex, ey - er * 0.6), Vector2(ex, ey + er * 0.6), Color(1, 0.9, 0.5), 2.5)
	draw_line(Vector2(ex - er * 0.4, ey), Vector2(ex + er * 0.4, ey), Color(1, 0.9, 0.5), 2.5)
	# Large majestic wings (6 feathered)
	var wc := Color(1, 0.98, 0.85, 0.9)
	# Left wing (three feathers)
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex - er, ey - 2), Vector2(ex - er - 10, ey - 10),
		Vector2(ex - er - 8, ey - 4)
	]), wc)
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex - er, ey), Vector2(ex - er - 12, ey - 6),
		Vector2(ex - er - 9, ey + 1)
	]), wc.darkened(0.05))
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex - er, ey + 2), Vector2(ex - er - 8, ey - 1),
		Vector2(ex - er - 5, ey + 4)
	]), wc.darkened(0.1))
	# Right wing
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex + er, ey - 2), Vector2(ex + er + 10, ey - 10),
		Vector2(ex + er + 8, ey - 4)
	]), wc)
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex + er, ey), Vector2(ex + er + 12, ey - 6),
		Vector2(ex + er + 9, ey + 1)
	]), wc.darkened(0.05))
	draw_colored_polygon(PackedVector2Array([
		Vector2(ex + er, ey + 2), Vector2(ex + er + 8, ey - 1),
		Vector2(ex + er + 5, ey + 4)
	]), wc.darkened(0.1))
	# Flaming sword (right hand)
	var sx := ex + er * 0.3
	var sy := ey - er * 0.4
	draw_line(Vector2(sx, sy), Vector2(sx + 4, sy - 10), Color(1, 0.95, 0.8), 2.5)
	draw_line(Vector2(sx + 4, sy - 10), Vector2(sx + 3, sy - 13), Color(1, 0.7, 0.3), 2.0)
	# Sword flame
	var flame_h: float = 3 + 2 * sin(GM.game_time * 6.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(sx + 3, sy - 13 - flame_h), Vector2(sx + 5, sy - 12), Vector2(sx + 1, sy - 12)
	]), Color(1, 0.5, 0.1, 0.7))
	# Crown with halo
	draw_line(Vector2(ex - 4, ey - er), Vector2(ex - 2, ey - er - 5), Color(1, 0.95, 0.5), 2.0)
	draw_line(Vector2(ex, ey - er), Vector2(ex, ey - er - 7), Color(1, 0.95, 0.5), 2.0)
	draw_line(Vector2(ex + 4, ey - er), Vector2(ex + 2, ey - er - 5), Color(1, 0.95, 0.5), 2.0)
	# Bright halo
	draw_arc(Vector2(ex, ey - er - 3), 5, 0, TAU, 16, Color(1, 0.95, 0.6, 0.8), 1.5)
	# Blazing eyes
	var eye_glow: float = 0.8 + 0.2 * sin(GM.game_time * 4.0)
	draw_circle(Vector2(ex - 2, ey - 1), 2.0, Color(1, 0.9, 0.4, 0.3))
	draw_circle(Vector2(ex + 2, ey - 1), 2.0, Color(1, 0.9, 0.4, 0.3))
	draw_circle(Vector2(ex - 2, ey - 1), 1.2, Color(1, 1, 0.7, eye_glow))
	draw_circle(Vector2(ex + 2, ey - 1), 1.2, Color(1, 1, 0.7, eye_glow))

func _draw_enemy_zeus(ex: float, ey: float, er: float, flash: bool) -> void:
	var col: Color = Color(1, 0.2, 0.2) if flash else Color(0.7, 0.8, 1.0)
	# Shadow
	draw_circle(Vector2(ex + 1, ey + 1), er, Color(0, 0, 0, 0.25))
	# Storm aura (crackling, pulsing)
	var storm_pulse: float = 0.3 + 0.3 * abs(sin(GM.game_time * 5.0))
	draw_circle(Vector2(ex, ey), er + 4, Color(0.5, 0.6, 1.0, 0.1 * storm_pulse))
	draw_arc(Vector2(ex, ey), er + 4, 0, TAU, 20, Color(0.6, 0.7, 1.0, 0.3 * storm_pulse), 1.5)
	# Body (blue-white, electric)
	draw_circle(Vector2(ex, ey), er, col)
	draw_circle(Vector2(ex, ey), er * 0.7, col.lightened(0.1))
	# Lightning bolt symbol on body
	draw_line(Vector2(ex - 1, ey - er * 0.4), Vector2(ex + 2, ey - 1), Color(1, 1, 0.5, 0.9), 2.0)
	draw_line(Vector2(ex + 2, ey - 1), Vector2(ex - 1, ey + 1), Color(1, 1, 0.5, 0.9), 2.0)
	draw_line(Vector2(ex - 1, ey + 1), Vector2(ex + 1, ey + er * 0.4), Color(1, 1, 0.5, 0.9), 2.0)
	# Beard (white flowing)
	draw_arc(Vector2(ex, ey + er * 0.2), er * 0.5, 0.3, PI - 0.3, 8, Color(0.9, 0.9, 1.0, 0.6), 2.0)
	draw_line(Vector2(ex - 2, ey + er * 0.5), Vector2(ex - 3, ey + er + 2), Color(0.9, 0.9, 1.0, 0.5), 1.5)
	draw_line(Vector2(ex + 2, ey + er * 0.5), Vector2(ex + 3, ey + er + 2), Color(0.9, 0.9, 1.0, 0.5), 1.5)
	# Crown / laurel wreath
	draw_arc(Vector2(ex, ey - er * 0.4), er * 0.6, PI + 0.3, TAU - 0.3, 10, Color(1, 0.9, 0.3), 1.5)
	# Electric eyes
	var eye_flash: float = 0.6 + 0.4 * abs(sin(GM.game_time * 6.0))
	draw_circle(Vector2(ex - 2, ey - 2), 1.8, Color(0.7, 0.8, 1.0, 0.3))
	draw_circle(Vector2(ex + 2, ey - 2), 1.8, Color(0.7, 0.8, 1.0, 0.3))
	draw_circle(Vector2(ex - 2, ey - 2), 1.0, Color(0.8, 0.9, 1.0, eye_flash))
	draw_circle(Vector2(ex + 2, ey - 2), 1.0, Color(0.8, 0.9, 1.0, eye_flash))
	# Lightning bolts crackling around (animated)
	var t := GM.game_time
	for i in range(3):
		var angle: float = t * 3.0 + float(i) * TAU / 3.0
		var bx: float = ex + cos(angle) * (er + 3)
		var by: float = ey + sin(angle) * (er + 3)
		var bolt_a: float = 0.3 + 0.4 * abs(sin(t * 8.0 + float(i) * 2.0))
		draw_line(Vector2(bx, by), Vector2(bx + 3 * cos(angle + 0.5), by - 4), Color(0.8, 0.9, 1.0, bolt_a), 1.5)
		draw_line(Vector2(bx + 3 * cos(angle + 0.5), by - 4), Vector2(bx + 1, by - 7), Color(1, 1, 0.7, bolt_a * 0.7), 1.0)

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
				GM.notify("Not enough sins!", Color(1, 0.2, 0.2))
				return
			if not is_free:
				GM.spend(cost)
			else:
				GM.free_towers -= 1
				GM.notify("Free tower! (" + str(GM.free_towers) + " left)", Color(0.267, 1.0, 0.267))

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
