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

	# Spawn marker — portal effect
	var spawn_cell: Vector2i = Config.MAP_PATH[0]
	var sx: float = spawn_cell.x * T + T / 2.0
	var sy: float = spawn_cell.y * T + T / 2.0
	var sp_pulse: float = 0.5 + 0.5 * sin(GM.game_time * 2.5)
	draw_circle(Vector2(sx, sy - T * 0.3), 8, Color(0.1, 0.2, 0.6, 0.3 + sp_pulse * 0.2))
	draw_circle(Vector2(sx, sy - T * 0.3), 5, Config.COLOR_SPAWN)
	draw_arc(Vector2(sx, sy - T * 0.3), 10, 0, TAU, 16, Color(0.3, 0.5, 1.0, 0.3 + sp_pulse * 0.15), 1.5)
	draw_string(font, Vector2(sx - 20, sy - T * 0.55), Locale.t("SPAWN"), HORIZONTAL_ALIGNMENT_CENTER, 40, 10, Color(0.7, 0.8, 1.0))

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

		# Selected highlight
		if GM.selected_tower != null and GM.selected_tower.get("id") == t["id"]:
			draw_arc(Vector2(cx, cy), 20, 0, TAU, 24, Color.WHITE, 2.0)

		# Level indicator
		if t["level"] > 1:
			var tx: float = t["col"] * T
			var ty: float = t["row"] * T
			draw_string(font, Vector2(tx + T - 24, ty + T - 4), "Lv" + str(t["level"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.8, 0.0, a))

		# Attack line to target
		if t["target"] != null and t["target"] is Dictionary and t["target"].get("alive", false) and not t["is_disabled"]:
			draw_line(
				Vector2(t["x"], t["y"]),
				Vector2(t["target"]["x"], t["target"]["y"]),
				Color(1, 0.39, 0.39, 0.15), 1.0
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

# ═══════════════════════════════════════════════════════
# PROJECTILES
# ═══════════════════════════════════════════════════════
func _draw_projectiles() -> void:
	for p in GM.projectiles:
		if not p["alive"]:
			continue
		# Glow
		draw_circle(Vector2(p["x"], p["y"]), 6, Color(1, 0.59, 0.2, 0.3))
		# Core
		draw_circle(Vector2(p["x"], p["y"]), 3, p["color"])

# ═══════════════════════════════════════════════════════
# EFFECTS
# ═══════════════════════════════════════════════════════
func _draw_effects() -> void:
	for e in GM.effects:
		var alpha: float = clampf(e["timer"] / 0.5, 0.0, 1.0)

		match e["type"]:
			"death":
				var expand: float = (1.0 - alpha) * 20.0
				var col: Color = e["color"]
				col.a = alpha
				draw_arc(Vector2(e["x"], e["y"]), e["radius"] + expand, 0, TAU, 24, col, 2.0)
			"aoe":
				var col := Color(1, 0.47, 0.12, alpha * 0.6)
				draw_circle(Vector2(e["x"], e["y"]), e["radius"], col)
			"relic":
				draw_string(font, Vector2(e["x"] - 8, e["y"] - (1.0 - alpha) * 20), "[!]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.8, 0, alpha))
			"corrupt":
				var expand: float = (1.0 - alpha) * 30.0
				draw_circle(Vector2(e["x"], e["y"]), expand, Color(0.71, 0.2, 1.0, alpha * 0.4))
			"core_hit":
				var r: float = 30 + (1.0 - alpha) * 20
				draw_circle(Vector2(e["x"], e["y"]), r, Color(1, 0, 0, alpha * 0.5))
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

# ═══════════════════════════════════════════════════════
# NOTIFICATIONS
# ═══════════════════════════════════════════════════════
func _draw_notifications() -> void:
	var W: float = Config.GAME_WIDTH
	var H: float = Config.GAME_HEIGHT
	for i in range(GM.notifications.size()):
		var n: Dictionary = GM.notifications[i]
		var alpha: float = clampf(n["timer"], 0.0, 1.0)
		var ny: float = H - 20 - i * 20

		# Shadow
		var shadow_col := Color(0, 0, 0, alpha)
		draw_string(font, Vector2(W / 2.0 - 150 + 1, ny + 1), n["text"], HORIZONTAL_ALIGNMENT_CENTER, 300, 13, shadow_col)
		# Text
		var text_col: Color = n["color"]
		text_col.a = alpha
		draw_string(font, Vector2(W / 2.0 - 150, ny), n["text"], HORIZONTAL_ALIGNMENT_CENTER, 300, 13, text_col)

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
	var dice_text: String = str(r["d1"]) + "  +  " + str(r["d2"]) + "  =  " + str(r["total"])
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
	# Drop shadow for depth
	draw_circle(Vector2(cx + 1, cy + 2), 17, Color(0, 0, 0, a * 0.25))
	# Base platform with rim glow
	draw_circle(Vector2(cx, cy), 18, Color(0.35, 0.07, 0.07, a))
	draw_arc(Vector2(cx, cy), 18, 0, TAU, 24, Color(0.8, 0.2, 0.2, a * 0.5), 1.5)
	draw_arc(Vector2(cx, cy), 16, PI * 1.2, PI * 1.8, 8, Color(0.5, 0.1, 0.08, a * 0.3), 1.0)
	# Body with armor plate
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 7, cy - 1), Vector2(cx + 3, cy - 1),
		Vector2(cx + 2, cy + 13), Vector2(cx - 6, cy + 13)
	]), Color(0.55, 0.1, 0.1, a))
	# Armor highlight
	draw_line(Vector2(cx - 2, cy + 1), Vector2(cx - 2, cy + 11), Color(0.7, 0.18, 0.15, a), 1.0)
	# Shoulder guard
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 7, cy - 1), Vector2(cx - 3, cy - 3),
		Vector2(cx + 1, cy - 1), Vector2(cx - 3, cy + 1)
	]), Color(0.65, 0.15, 0.12, a))
	# Head with inner shading
	draw_circle(Vector2(cx - 2, cy - 6), 5.5, Color(0.65, 0.15, 0.15, a))
	draw_circle(Vector2(cx - 2, cy - 6), 4.5, Color(0.78, 0.22, 0.2, a))
	# Horns with taper (two segments each for gradient)
	draw_line(Vector2(cx - 5, cy - 10), Vector2(cx - 7, cy - 14), Color(0.85, 0.25, 0.1, a), 2.5)
	draw_line(Vector2(cx - 7, cy - 14), Vector2(cx - 8, cy - 17), Color(0.95, 0.4, 0.15, a), 1.5)
	draw_line(Vector2(cx + 1, cy - 10), Vector2(cx + 3, cy - 14), Color(0.85, 0.25, 0.1, a), 2.5)
	draw_line(Vector2(cx + 3, cy - 14), Vector2(cx + 5, cy - 17), Color(0.95, 0.4, 0.15, a), 1.5)
	# Glowing eyes (animated pulse)
	var eye_glow: float = 0.8 + 0.2 * sin(GM.game_time * 4.0)
	draw_circle(Vector2(cx - 4, cy - 7), 2.5, Color(1, 0.7, 0, a * 0.15))
	draw_circle(Vector2(cx, cy - 7), 2.5, Color(1, 0.7, 0, a * 0.15))
	draw_circle(Vector2(cx - 4, cy - 7), 1.3, Color(1, 0.85, 0, a * eye_glow))
	draw_circle(Vector2(cx, cy - 7), 1.3, Color(1, 0.85, 0, a * eye_glow))
	# Bow arm
	draw_line(Vector2(cx + 3, cy + 1), Vector2(cx + 11, cy + 1), Color(0.7, 0.2, 0.18, a), 2.0)
	# Bow (reinforced arc)
	draw_arc(Vector2(cx + 11, cy + 1), 11, -1.2, 1.2, 14, Color(0.5, 0.28, 0.1, a), 3.0)
	draw_arc(Vector2(cx + 11, cy + 1), 10, -1.0, 1.0, 10, Color(0.65, 0.38, 0.15, a), 1.5)
	# Bowstring
	var bt := Vector2(cx + 11 + 11 * cos(-1.2), cy + 1 + 11 * sin(-1.2))
	var bb := Vector2(cx + 11 + 11 * cos(1.2), cy + 1 + 11 * sin(1.2))
	draw_line(bt, Vector2(cx + 7, cy + 1), Color(0.85, 0.8, 0.5, a), 1.0)
	draw_line(bb, Vector2(cx + 7, cy + 1), Color(0.85, 0.8, 0.5, a), 1.0)
	# Flaming arrow shaft
	draw_line(Vector2(cx, cy + 1), Vector2(cx + 17, cy + 1), Color(0.9, 0.75, 0.3, a), 1.5)
	# Arrow tip (fiery glow)
	draw_circle(Vector2(cx + 18, cy + 1), 3.5, Color(1, 0.4, 0.1, a * 0.25))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 20, cy + 1), Vector2(cx + 15, cy - 2), Vector2(cx + 15, cy + 4)
	]), Color(1.0, 0.5, 0.15, a))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 19, cy + 1), Vector2(cx + 16, cy - 1), Vector2(cx + 16, cy + 3)
	]), Color(1.0, 0.8, 0.3, a * 0.7))

func _draw_avatar_mage(cx: float, cy: float, a: float) -> void:
	# Drop shadow
	draw_circle(Vector2(cx + 1, cy + 2), 17, Color(0, 0, 0, a * 0.25))
	# Base platform with arcane glow
	draw_circle(Vector2(cx, cy), 18, Color(0.2, 0.05, 0.25, a))
	draw_arc(Vector2(cx, cy), 18, 0, TAU, 24, Color(0.6, 0.2, 0.8, a * 0.5), 1.5)
	# Robe body with fold shading
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 4, cy - 2), Vector2(cx + 4, cy - 2),
		Vector2(cx + 11, cy + 14), Vector2(cx - 11, cy + 14)
	]), Color(0.4, 0.1, 0.55, a))
	# Robe fold highlight
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 1, cy), Vector2(cx + 2, cy),
		Vector2(cx + 4, cy + 13), Vector2(cx - 2, cy + 13)
	]), Color(0.5, 0.15, 0.65, a))
	# Robe rune marks (animated glow)
	var rune_glow: float = 0.3 + 0.3 * sin(GM.game_time * 2.5)
	draw_circle(Vector2(cx, cy + 5), 1.5, Color(1, 0.5, 0.9, a * rune_glow))
	draw_circle(Vector2(cx - 2, cy + 9), 1.0, Color(1, 0.5, 0.9, a * rune_glow * 0.7))
	draw_circle(Vector2(cx + 2, cy + 9), 1.0, Color(1, 0.5, 0.9, a * rune_glow * 0.7))
	# Head
	draw_circle(Vector2(cx, cy - 5), 5.5, Color(0.5, 0.12, 0.65, a))
	draw_circle(Vector2(cx, cy - 5), 4.5, Color(0.58, 0.16, 0.72, a))
	# Pointed hat with star detail
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy - 19), Vector2(cx + 7, cy - 4), Vector2(cx - 7, cy - 4)
	]), Color(0.45, 0.08, 0.6, a))
	# Hat highlight edge
	draw_line(Vector2(cx, cy - 19), Vector2(cx + 7, cy - 4), Color(0.6, 0.18, 0.75, a), 1.0)
	# Hat band
	draw_line(Vector2(cx - 8, cy - 4), Vector2(cx + 8, cy - 4), Color(0.7, 0.25, 0.85, a), 2.5)
	draw_circle(Vector2(cx, cy - 4), 2, Color(1, 0.6, 0.2, a * 0.6))
	# Glowing eyes (animated)
	var eye_pulse: float = 0.7 + 0.3 * sin(GM.game_time * 3.5)
	draw_circle(Vector2(cx - 2, cy - 6), 2.0, Color(0.8, 0.3, 1.0, a * 0.2))
	draw_circle(Vector2(cx + 2, cy - 6), 2.0, Color(0.8, 0.3, 1.0, a * 0.2))
	draw_circle(Vector2(cx - 2, cy - 6), 1.2, Color(0.9, 0.5, 1.0, a * eye_pulse))
	draw_circle(Vector2(cx + 2, cy - 6), 1.2, Color(0.9, 0.5, 1.0, a * eye_pulse))
	# Staff (left side, detailed)
	draw_line(Vector2(cx - 8, cy - 8), Vector2(cx - 8, cy + 12), Color(0.45, 0.25, 0.18, a), 2.5)
	draw_line(Vector2(cx - 7, cy - 8), Vector2(cx - 7, cy + 12), Color(0.55, 0.35, 0.22, a), 1.0)
	# Staff orb (animated pulsing)
	var orb_pulse: float = 0.6 + 0.4 * sin(GM.game_time * 3.0)
	draw_circle(Vector2(cx - 8, cy - 10), 6, Color(1, 0.45, 0.1, a * 0.15 * orb_pulse))
	draw_circle(Vector2(cx - 8, cy - 10), 4, Color(1, 0.5, 0.15, a * 0.35))
	draw_circle(Vector2(cx - 8, cy - 10), 2.5, Color(1, 0.65, 0.25, a * orb_pulse))
	# Animated flames at base
	for i in range(4):
		var fx: float = cx - 8 + i * 5
		var fy: float = cy + 13
		var flame_h: float = 5 + 2 * sin(GM.game_time * 4.0 + float(i) * 1.5)
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx, fy - flame_h), Vector2(fx + 2.5, fy), Vector2(fx - 2.5, fy)
		]), Color(1, 0.45 + float(i) * 0.1, 0.1, a * 0.65))
		# Inner flame
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx, fy - flame_h * 0.6), Vector2(fx + 1.5, fy - 1), Vector2(fx - 1.5, fy - 1)
		]), Color(1, 0.8, 0.3, a * 0.5))

func _draw_avatar_necro(cx: float, cy: float, a: float) -> void:
	# Drop shadow
	draw_circle(Vector2(cx + 1, cy + 2), 17, Color(0, 0, 0, a * 0.25))
	# Pulsing green aura
	var aura_pulse: float = 0.12 + 0.06 * sin(GM.game_time * 2.0)
	draw_circle(Vector2(cx, cy), 22, Color(0.1, 0.6, 0.25, a * aura_pulse))
	draw_circle(Vector2(cx, cy), 20, Color(0.08, 0.45, 0.2, a * aura_pulse * 0.8))
	# Base platform
	draw_circle(Vector2(cx, cy), 18, Color(0.06, 0.2, 0.1, a))
	draw_arc(Vector2(cx, cy), 18, 0, TAU, 24, Color(0.2, 0.8, 0.4, a * 0.5), 1.5)
	# Tattered robe with layered shading
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 5, cy - 6), Vector2(cx + 5, cy - 6),
		Vector2(cx + 10, cy + 14), Vector2(cx - 10, cy + 14)
	]), Color(0.1, 0.3, 0.15, a))
	# Robe fold
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 1, cy - 4), Vector2(cx + 2, cy - 4),
		Vector2(cx + 4, cy + 13), Vector2(cx - 3, cy + 13)
	]), Color(0.14, 0.38, 0.2, a))
	# Tattered hem details
	draw_line(Vector2(cx - 9, cy + 14), Vector2(cx - 11, cy + 16), Color(0.08, 0.25, 0.12, a * 0.6), 1.5)
	draw_line(Vector2(cx + 9, cy + 14), Vector2(cx + 11, cy + 16), Color(0.08, 0.25, 0.12, a * 0.6), 1.5)
	draw_line(Vector2(cx - 4, cy + 14), Vector2(cx - 5, cy + 17), Color(0.08, 0.25, 0.12, a * 0.5), 1.0)
	# Hood with depth
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy - 15), Vector2(cx + 8, cy - 4), Vector2(cx - 8, cy - 4)
	]), Color(0.08, 0.25, 0.12, a))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy - 14), Vector2(cx + 5, cy - 5), Vector2(cx - 5, cy - 5)
	]), Color(0.12, 0.32, 0.16, a))
	# Skull face with cracks
	draw_circle(Vector2(cx, cy - 5), 5.5, Color(0.85, 0.85, 0.8, a))
	draw_circle(Vector2(cx, cy - 5), 4.8, Color(0.92, 0.92, 0.87, a))
	# Skull crack detail
	draw_line(Vector2(cx - 1, cy - 9), Vector2(cx, cy - 7), Color(0.6, 0.6, 0.55, a), 0.8)
	draw_line(Vector2(cx, cy - 7), Vector2(cx + 1, cy - 5), Color(0.6, 0.6, 0.55, a), 0.8)
	# Glowing eye sockets
	var eye_glow: float = 0.7 + 0.3 * sin(GM.game_time * 3.0)
	draw_circle(Vector2(cx - 2, cy - 6), 2.0, Color(0.1, 0.8, 0.3, a * 0.2))
	draw_circle(Vector2(cx + 2, cy - 6), 2.0, Color(0.1, 0.8, 0.3, a * 0.2))
	draw_circle(Vector2(cx - 2, cy - 6), 1.3, Color(0.15, 1.0, 0.4, a * eye_glow))
	draw_circle(Vector2(cx + 2, cy - 6), 1.3, Color(0.15, 1.0, 0.4, a * eye_glow))
	# Nose cavity
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy - 3.5), Vector2(cx + 1.2, cy - 2), Vector2(cx - 1.2, cy - 2)
	]), Color(0.05, 0.15, 0.05, a))
	# Teeth (individual)
	for i in range(5):
		var tx: float = cx - 2.5 + i * 1.2
		draw_line(Vector2(tx, cy - 1.5), Vector2(tx, cy - 0.5), Color(0.8, 0.8, 0.75, a), 0.8)
	# Jaw line
	draw_arc(Vector2(cx, cy - 3), 3.5, 0.3, PI - 0.3, 8, Color(0.7, 0.7, 0.65, a), 1.0)
	# Staff (right side, bone-like)
	draw_line(Vector2(cx + 8, cy - 13), Vector2(cx + 8, cy + 11), Color(0.35, 0.22, 0.1, a), 2.5)
	draw_line(Vector2(cx + 9, cy - 12), Vector2(cx + 9, cy + 10), Color(0.45, 0.3, 0.15, a), 1.0)
	# Staff joint knobs
	draw_circle(Vector2(cx + 8.5, cy - 4), 1.5, Color(0.5, 0.35, 0.15, a))
	draw_circle(Vector2(cx + 8.5, cy + 4), 1.5, Color(0.5, 0.35, 0.15, a))
	# Staff skull orb (pulsing green)
	var orb_pulse: float = 0.6 + 0.4 * sin(GM.game_time * 2.5)
	draw_circle(Vector2(cx + 8, cy - 14), 7, Color(0.15, 0.8, 0.35, a * 0.12 * orb_pulse))
	draw_circle(Vector2(cx + 8, cy - 14), 5, Color(0.2, 0.9, 0.4, a * 0.3))
	draw_circle(Vector2(cx + 8, cy - 14), 3, Color(0.3, 1.0, 0.5, a * orb_pulse))
	# Soul wisps (more, varied paths)
	var t := GM.game_time
	for i in range(3):
		var angle: float = t * (1.5 + float(i) * 0.5) + float(i) * TAU / 3.0
		var dist: float = 13 + 3 * sin(t * 1.2 + float(i))
		var wx: float = cx + cos(angle) * dist
		var wy: float = cy + sin(angle) * (dist * 0.7)
		var wisp_a: float = 0.3 + 0.15 * sin(t * 3.0 + float(i) * 2.0)
		draw_circle(Vector2(wx, wy), 3, Color(0.2, 0.9, 0.4, a * wisp_a * 0.3))
		draw_circle(Vector2(wx, wy), 1.5, Color(0.3, 1, 0.5, a * wisp_a))

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

	if event is InputEventKey and event.pressed:
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

func _handle_left_click(pos: Vector2) -> void:
	var grid := Config.pixel_to_grid(pos.x, pos.y)

	if GM.selected_tower_type != "":
		# Placement mode
		if GM.is_buildable(grid.x, grid.y):
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
