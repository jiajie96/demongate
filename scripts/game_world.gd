extends Node2D

var font: Font
var T: int  # tile size shorthand

func _ready() -> void:
	font = ThemeDB.fallback_font
	T = Config.TILE_SIZE

func _process(dt: float) -> void:
	if GM.phase != "playing":
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

	# Ground tiles (checker) + path
	for r in range(Config.GRID_ROWS):
		for c in range(Config.GRID_COLS):
			var rx: float = c * T
			var ry: float = r * T

			if Config.is_path(c, r):
				draw_rect(Rect2(rx, ry, T, T), Config.COLOR_PATH)
				draw_rect(Rect2(rx + 0.5, ry + 0.5, T - 1, T - 1), Config.COLOR_PATH_EDGE, false, 1.0)
			else:
				var col := Config.COLOR_GROUND if (c + r) % 2 == 0 else Config.COLOR_GROUND_ALT
				draw_rect(Rect2(rx, ry, T, T), col)

	# Grid lines
	for c in range(Config.GRID_COLS + 1):
		draw_line(Vector2(c * T, 0), Vector2(c * T, Config.GAME_HEIGHT), Config.COLOR_GRID_LINE, 0.5)
	for r in range(Config.GRID_ROWS + 1):
		draw_line(Vector2(0, r * T), Vector2(Config.GAME_WIDTH, r * T), Config.COLOR_GRID_LINE, 0.5)

	# Spawn marker
	var spawn_cell: Vector2i = Config.MAP_PATH[0]
	var sx: float = spawn_cell.x * T + T / 2.0
	var sy: float = spawn_cell.y * T + T / 2.0
	draw_circle(Vector2(sx, sy - T * 0.3), 6, Config.COLOR_SPAWN)
	draw_string(font, Vector2(sx - 20, sy - T * 0.55), "SPAWN", HORIZONTAL_ALIGNMENT_CENTER, 40, 10, Color.WHITE)

	# Core marker
	var core_cell: Vector2i = Config.MAP_PATH[Config.MAP_PATH.size() - 1]
	var cx: float = core_cell.x * T + T / 2.0
	var cy: float = core_cell.y * T + T / 2.0

	# Core glow
	var pulse: float = 0.5 + 0.5 * sin(GM.game_time * 3.0)
	for i in range(4):
		var glow_r: float = T * 0.8 * (1.0 - float(i) * 0.2)
		var glow_a: float = (0.3 + 0.2 * pulse) * float(i + 1) * 0.15
		draw_circle(Vector2(cx, cy), glow_r, Color(1, 0.2, 0.2, glow_a))

	draw_circle(Vector2(cx, cy), 10, Config.COLOR_CORE)
	draw_string(font, Vector2(cx - 40, cy - 15), "HELL'S CORE", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Color.WHITE)

	# Core HP bar on map
	var bar_w: float = 40.0
	var bar_h: float = 5.0
	var hp_ratio: float = GM.core_hp / GM.core_max_hp
	draw_rect(Rect2(cx - bar_w / 2, cy + 14, bar_w, bar_h), Config.COLOR_HEALTH_BG)
	var hp_color := Config.COLOR_HEALTH_HP if hp_ratio > 0.3 else Config.COLOR_HEALTH_LOW
	draw_rect(Rect2(cx - bar_w / 2, cy + 14, bar_w * hp_ratio, bar_h), hp_color)

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
			"pit_brute": _draw_avatar_brute(cx, cy, a)
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
			"pit_brute": _draw_avatar_brute(center.x, center.y, 0.5)
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
	var alpha: float = clampf(GM.dice_result_timer / 0.5, 0.0, 1.0)
	var W: float = Config.GAME_WIDTH
	var H: float = Config.GAME_HEIGHT

	# Background overlay
	draw_rect(Rect2(W / 2 - 140, H / 2 - 60, 280, 120), Color(0, 0, 0, 0.6 * alpha))

	# Dice values
	var dice_text: String = str(r["d1"]) + "  +  " + str(r["d2"]) + "  =  " + str(r["total"])
	draw_string(font, Vector2(W / 2 - 120, H / 2 - 10), dice_text, HORIZONTAL_ALIGNMENT_CENTER, 240, 30, Color(1, 1, 1, alpha))

	# Outcome name
	var outcome: Dictionary = r["outcome"]
	var out_col := Color(0.267, 1.0, 0.267, alpha) if outcome["positive"] else Color(1.0, 0.267, 0.267, alpha)
	draw_string(font, Vector2(W / 2 - 120, H / 2 + 30), outcome["name"], HORIZONTAL_ALIGNMENT_CENTER, 240, 16, out_col)

# ═══════════════════════════════════════════════════════
# TOWER AVATARS
# ═══════════════════════════════════════════════════════

func _draw_avatar_archer(cx: float, cy: float, a: float) -> void:
	# Base platform
	draw_circle(Vector2(cx, cy), 18, Color(0.35, 0.07, 0.07, a))
	draw_arc(Vector2(cx, cy), 18, 0, TAU, 24, Color(0.8, 0.2, 0.2, a * 0.5), 1.5)
	# Head
	draw_circle(Vector2(cx - 2, cy - 5), 5, Color(0.75, 0.2, 0.2, a))
	# Horns
	draw_line(Vector2(cx - 5, cy - 9), Vector2(cx - 8, cy - 15), Color(0.9, 0.25, 0.1, a), 2.0)
	draw_line(Vector2(cx + 1, cy - 9), Vector2(cx + 4, cy - 15), Color(0.9, 0.25, 0.1, a), 2.0)
	# Eyes
	draw_circle(Vector2(cx - 4, cy - 6), 1.2, Color(1, 0.85, 0, a))
	draw_circle(Vector2(cx, cy - 6), 1.2, Color(1, 0.85, 0, a))
	# Body
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 6, cy), Vector2(cx + 2, cy),
		Vector2(cx + 1, cy + 12), Vector2(cx - 5, cy + 12)
	]), Color(0.6, 0.12, 0.12, a))
	# Bow arm extending right
	draw_line(Vector2(cx + 2, cy + 2), Vector2(cx + 10, cy + 2), Color(0.65, 0.18, 0.18, a), 2.0)
	# Bow (wooden arc)
	draw_arc(Vector2(cx + 10, cy + 2), 10, -1.2, 1.2, 12, Color(0.6, 0.35, 0.12, a), 2.5)
	# Bowstring
	var bt := Vector2(cx + 10 + 10 * cos(-1.2), cy + 2 + 10 * sin(-1.2))
	var bb := Vector2(cx + 10 + 10 * cos(1.2), cy + 2 + 10 * sin(1.2))
	draw_line(bt, Vector2(cx + 6, cy + 2), Color(0.85, 0.8, 0.5, a), 1.0)
	draw_line(bb, Vector2(cx + 6, cy + 2), Color(0.85, 0.8, 0.5, a), 1.0)
	# Arrow
	draw_line(Vector2(cx, cy + 2), Vector2(cx + 16, cy + 2), Color(1, 0.9, 0.3, a), 1.5)
	# Arrowhead
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 18, cy + 2), Vector2(cx + 14, cy - 1), Vector2(cx + 14, cy + 5)
	]), Color(0.85, 0.85, 0.85, a))

func _draw_avatar_mage(cx: float, cy: float, a: float) -> void:
	# Base platform
	draw_circle(Vector2(cx, cy), 18, Color(0.2, 0.05, 0.25, a))
	draw_arc(Vector2(cx, cy), 18, 0, TAU, 24, Color(0.6, 0.2, 0.8, a * 0.5), 1.5)
	# Robe body (wide triangle)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 3, cy - 2), Vector2(cx + 3, cy - 2),
		Vector2(cx + 10, cy + 14), Vector2(cx - 10, cy + 14)
	]), Color(0.45, 0.12, 0.6, a))
	# Head
	draw_circle(Vector2(cx, cy - 5), 5, Color(0.55, 0.15, 0.7, a))
	# Pointed hat
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy - 18), Vector2(cx + 7, cy - 4), Vector2(cx - 7, cy - 4)
	]), Color(0.5, 0.1, 0.65, a))
	# Hat brim
	draw_line(Vector2(cx - 8, cy - 4), Vector2(cx + 8, cy - 4), Color(0.65, 0.2, 0.8, a), 2.0)
	# Eyes (glowing purple)
	draw_circle(Vector2(cx - 2, cy - 6), 1.2, Color(0.9, 0.5, 1.0, a))
	draw_circle(Vector2(cx + 2, cy - 6), 1.2, Color(0.9, 0.5, 1.0, a))
	# Staff (left side)
	draw_line(Vector2(cx - 8, cy - 8), Vector2(cx - 8, cy + 12), Color(0.5, 0.3, 0.2, a), 2.0)
	# Staff orb
	draw_circle(Vector2(cx - 8, cy - 10), 3, Color(1, 0.5, 0.15, a))
	draw_circle(Vector2(cx - 8, cy - 10), 5, Color(1, 0.5, 0.15, a * 0.3))
	# Flames at base (three small flames)
	for i in range(3):
		var fx: float = cx - 6 + i * 6
		var fy: float = cy + 12
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx, fy - 6), Vector2(fx + 3, fy), Vector2(fx - 3, fy)
		]), Color(1, 0.5 + i * 0.15, 0.1, a * 0.7))

func _draw_avatar_brute(cx: float, cy: float, a: float) -> void:
	# Base platform (squared off for brute feel)
	draw_rect(Rect2(cx - 18, cy - 18, 36, 36), Color(0.25, 0.18, 0.04, a))
	draw_rect(Rect2(cx - 18, cy - 18, 36, 36), Color(0.55, 0.4, 0.1, a * 0.5), false, 1.5)
	# Massive body
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 10, cy - 4), Vector2(cx + 10, cy - 4),
		Vector2(cx + 12, cy + 14), Vector2(cx - 12, cy + 14)
	]), Color(0.5, 0.35, 0.08, a))
	# Big head
	draw_circle(Vector2(cx, cy - 6), 7, Color(0.55, 0.4, 0.1, a))
	# Prominent horns
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 5, cy - 10), Vector2(cx - 3, cy - 10), Vector2(cx - 10, cy - 18)
	]), Color(0.7, 0.5, 0.1, a))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 5, cy - 10), Vector2(cx + 3, cy - 10), Vector2(cx + 10, cy - 18)
	]), Color(0.7, 0.5, 0.1, a))
	# Angry eyes (red slits)
	draw_line(Vector2(cx - 4, cy - 7), Vector2(cx - 1, cy - 6), Color(1, 0.2, 0.1, a), 2.0)
	draw_line(Vector2(cx + 4, cy - 7), Vector2(cx + 1, cy - 6), Color(1, 0.2, 0.1, a), 2.0)
	# Fists (large circles at sides)
	draw_circle(Vector2(cx - 14, cy + 6), 5, Color(0.6, 0.42, 0.1, a))
	draw_circle(Vector2(cx + 14, cy + 6), 5, Color(0.6, 0.42, 0.1, a))
	# Knuckle lines
	draw_line(Vector2(cx - 16, cy + 5), Vector2(cx - 12, cy + 5), Color(0.4, 0.28, 0.06, a), 1.0)
	draw_line(Vector2(cx + 12, cy + 5), Vector2(cx + 16, cy + 5), Color(0.4, 0.28, 0.06, a), 1.0)
	# Mouth (grim line)
	draw_line(Vector2(cx - 3, cy - 2), Vector2(cx + 3, cy - 2), Color(0.3, 0.2, 0.05, a), 1.5)

func _draw_avatar_necro(cx: float, cy: float, a: float) -> void:
	# Green glow aura
	draw_circle(Vector2(cx, cy), 20, Color(0.1, 0.5, 0.2, a * 0.15))
	# Base platform
	draw_circle(Vector2(cx, cy), 18, Color(0.06, 0.2, 0.1, a))
	draw_arc(Vector2(cx, cy), 18, 0, TAU, 24, Color(0.2, 0.8, 0.4, a * 0.5), 1.5)
	# Hooded robe
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 4, cy - 6), Vector2(cx + 4, cy - 6),
		Vector2(cx + 9, cy + 14), Vector2(cx - 9, cy + 14)
	]), Color(0.12, 0.35, 0.18, a))
	# Hood
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy - 14), Vector2(cx + 7, cy - 4), Vector2(cx - 7, cy - 4)
	]), Color(0.1, 0.3, 0.15, a))
	# Skull face
	draw_circle(Vector2(cx, cy - 5), 5, Color(0.9, 0.9, 0.85, a))
	# Skull eyes (dark hollows)
	draw_circle(Vector2(cx - 2, cy - 6), 1.5, Color(0.05, 0.15, 0.05, a))
	draw_circle(Vector2(cx + 2, cy - 6), 1.5, Color(0.05, 0.15, 0.05, a))
	# Skull nose (small triangle)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy - 4), Vector2(cx + 1, cy - 2.5), Vector2(cx - 1, cy - 2.5)
	]), Color(0.05, 0.15, 0.05, a))
	# Skull teeth line
	draw_line(Vector2(cx - 2.5, cy - 1.5), Vector2(cx + 2.5, cy - 1.5), Color(0.7, 0.7, 0.65, a), 1.0)
	# Staff (right side)
	draw_line(Vector2(cx + 8, cy - 12), Vector2(cx + 8, cy + 10), Color(0.4, 0.25, 0.12, a), 2.0)
	# Staff skull orb (green)
	draw_circle(Vector2(cx + 8, cy - 13), 4, Color(0.2, 0.9, 0.4, a))
	draw_circle(Vector2(cx + 8, cy - 13), 6, Color(0.2, 0.9, 0.4, a * 0.25))
	# Tiny soul wisps
	var t := GM.game_time
	for i in range(2):
		var angle: float = t * 2.0 + i * PI
		var wx: float = cx + cos(angle) * 14
		var wy: float = cy + sin(angle) * 10
		draw_circle(Vector2(wx, wy), 2, Color(0.3, 1, 0.5, a * 0.4))

# ═══════════════════════════════════════════════════════
# ENEMY AVATARS
# ═══════════════════════════════════════════════════════

func _draw_enemy_scout(ex: float, ey: float, er: float, flash: bool) -> void:
	var col: Color = Color(1, 0.2, 0.2) if flash else Color(1.0, 0.87, 0.27)
	# Body
	draw_circle(Vector2(ex, ey), er, col)
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
	# Body (slightly darker for armor feel)
	draw_circle(Vector2(ex, ey), er, col * 0.8)
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
	# Body (larger, armored feel)
	draw_circle(Vector2(ex, ey), er, col * 0.85)
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
	# Outer glow
	draw_circle(Vector2(ex, ey), er + 1, Color(1, 0.9, 0.3, 0.2))
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
	# Body
	draw_circle(Vector2(ex, ey), er, col)
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

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				GM.selected_tower_type = ""
				GM.selected_tower = null
			KEY_D:
				if GM.wave_active:
					GM.roll_dice()
			KEY_SPACE, KEY_ENTER:
				if not GM.wave_active and not GM.show_roulette and not GM.show_pact:
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
