extends Node

# ═══════════════════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════════════════
signal notification_added(text: String, color: Color)
signal pact_offered(choices: Array)

# ═══════════════════════════════════════════════════════
# GAME STATE
# ═══════════════════════════════════════════════════════
var phase: String = "menu"
var paused: bool = false
var core_hp: float = 100.0
var core_max_hp: float = 100.0
var wave: int = 0

var sins: int = 50

var towers: Array = []
var enemies: Array = []
var projectiles: Array = []
var effects: Array = []

var selected_tower_type: String = ""
var selected_tower = null
# REDESIGN: live-rotatable cone preview for Cocytus placement
var preview_cone_facing: float = 0.0
var preview_cone_manual: bool = false
var preview_cone_last_grid: Vector2i = Vector2i(-99, -99)

var hovered_grid: Vector2i = Vector2i(-1, -1)

var wave_active: bool = false
var spawn_queue: Array = []
var spawn_timer: float = 0.0
var between_wave_timer: float = 0.0
var wave_desc: String = ""

var dice_uses_left: int = 2

var show_pact: bool = false
var pact_choices: Array = []
var show_dice_result: bool = false
var dice_result: Dictionary = {}
var dice_result_timer: float = 0.0

var sin_multiplier: float = 1.0
var sin_mult_waves: int = 0
var free_towers: int = 0
var double_damage: int = 0
var perm_speed_buff: float = 1.0
var temp_speed_buff: float = 1.0
var fast_enemy_waves: int = 0

var fallen_hero_pool: int = 0
var fallen_heroes_spawned: int = 0

var stats: Dictionary = {"enemies_killed": 0, "towers_placed": 0}
var occupied_tiles: Dictionary = {}
var notifications: Array = []
var game_time: float = 0.0
var show_overview: bool = false
var screen_shake: float = 0.0
var screen_shake_intensity: float = 0.0
var speed_buff_timer: float = 0.0
var speed_buff_factor: float = 1.0  # what was multiplied, divide to undo
var game_speed: float = 1.0
var hellfire_strikes_left: int = 0    # Hellfire Rain pact: strikes remaining for next wave
var hellfire_strike_timer: float = 0.0

# Wave announcement banner — cinematic title card shown when a wave starts.
# Counts down from its initial value; game_world reads it each frame to draw
# the sliding "WAVE N" overlay. Zero = no banner visible.
var wave_banner_timer: float = 0.0
const WAVE_BANNER_DURATION: float = 2.6
# Snapshot of the wave number + desc at banner spawn so a new wave can't
# race the banner and rewrite the label partway through its fade.
var wave_banner_num: int = 0
var wave_banner_desc: String = ""
var wave_banner_is_boss: bool = false

var _next_id: int = 0

# ═══════════════════════════════════════════════════════
# RESET
# ═══════════════════════════════════════════════════════
func reset_state() -> void:
	phase = "playing"
	paused = false
	Audio.start_music()
	core_hp = Config.CORE_MAX_HP
	core_max_hp = Config.CORE_MAX_HP
	wave = 0
	sins = 50
	towers.clear()
	enemies.clear()
	projectiles.clear()
	effects.clear()
	selected_tower_type = ""
	selected_tower = null
	preview_cone_facing = 0.0
	preview_cone_manual = false
	preview_cone_last_grid = Vector2i(-99, -99)
	hovered_grid = Vector2i(-1, -1)
	wave_active = false
	spawn_queue.clear()
	spawn_timer = 0.0
	between_wave_timer = Config.FIRST_WAVE_DELAY
	wave_desc = "Prepare your defenses!"  # translated at display point
	dice_uses_left = Config.DICE_MAX_USES
	show_pact = false
	pact_choices.clear()
	show_dice_result = false
	dice_result = {}
	dice_result_timer = 0.0
	sin_multiplier = 1.0
	sin_mult_waves = 0
	free_towers = 0
	double_damage = 0
	perm_speed_buff = 1.0
	temp_speed_buff = 1.0
	fast_enemy_waves = 0
	fallen_hero_pool = 0
	fallen_heroes_spawned = 0
	stats = {"enemies_killed": 0, "towers_placed": 0}
	occupied_tiles.clear()
	notifications.clear()
	game_time = 0.0
	show_overview = false
	screen_shake = 0.0
	screen_shake_intensity = 0.0
	speed_buff_timer = 0.0
	speed_buff_factor = 1.0
	game_speed = 1.0
	Engine.time_scale = 1.0
	hellfire_strikes_left = 0
	hellfire_strike_timer = 0.0
	wave_banner_timer = 0.0
	wave_banner_num = 0
	wave_banner_desc = ""
	wave_banner_is_boss = false
	_next_id = 0

func set_game_speed(speed: float) -> void:
	game_speed = speed
	Engine.time_scale = speed

# ═══════════════════════════════════════════════════════
# ECONOMY
# ═══════════════════════════════════════════════════════
func earn(amount: int) -> void:
	var total := roundi(amount * sin_multiplier)
	sins += total

# powHPG scaling: kill rewards grow with enemy HP scaling (exponent 0.85).
# Keeps economy from dying as enemies get tougher in late waves.
func reward_scale() -> float:
	return Config.reward_scale(wave)

func earn_from_kill(enemy_type: String, was_aoe: bool) -> void:
	var data: Dictionary = Config.ENEMY_DATA.get(enemy_type, {})
	if data.is_empty():
		return
	var scaled_reward: int = maxi(1, roundi(data["sin_reward"] * reward_scale()))
	earn(scaled_reward)
	if was_aoe:
		earn(1)

func can_afford(cost: int) -> bool:
	return sins >= cost

func spend(cost: int) -> bool:
	if sins < cost:
		return false
	sins -= cost
	return true

func total_sins() -> int:
	return sins

func add_to_hero_pool(amount: int) -> void:
	fallen_hero_pool += amount
	var threshold := hero_threshold()
	if fallen_hero_pool >= threshold:
		fallen_hero_pool -= threshold
		fallen_heroes_spawned += 1
		notify(Locale.t("A Fallen Hero has joined your cause!"), Color(1.0, 0.8, 0.0))

func hero_threshold() -> int:
	if fallen_heroes_spawned == 0:
		return 200
	if fallen_heroes_spawned == 1:
		return 500
	return 1000 + (fallen_heroes_spawned - 2) * 500

func format_cost(cost: int) -> String:
	return Locale.tf("cost_format", {"cost": cost})

# ═══════════════════════════════════════════════════════
# TOWER
# ═══════════════════════════════════════════════════════
func create_tower(type: String, col: int, row: int) -> Dictionary:
	var data: Dictionary = Config.TOWER_DATA[type]
	var pos := Config.grid_to_pixel(col, row)
	_next_id += 1
	var tower := {
		"id": _next_id,
		"type": type,
		"col": col, "row": row,
		"x": pos.x, "y": pos.y,
		"level": 1,
		"damage": data["damage"],
		"range": data["range"],
		"attack_speed": data["attack_speed"],
		"cooldown": 0.0,
		"target": null,
		"is_disabled": false,
		"disable_timer": 0.0,
		"damage_mult": 1.0,
		"slow_power": data["slow_power"],
		"is_aoe": data["is_aoe"],
		"aoe_radius": data["aoe_radius"],
		"color": data["color"],
		"name": data["name"],
		"is_global": data.get("is_global", false),
		"is_support": data.get("is_support", false),
		"is_beam_cone": data.get("is_beam_cone", false),
		"facing_angle": 0.0,
		"cone_emit_timer": 0.0,
		"buff_cooldown": data.get("buff_cooldown", 0.0),
		"buff_duration": data.get("buff_duration", 0.0),
		"buff_multiplier": data.get("buff_multiplier", 1.0),
		"buff_timer": 0.0,
		"buff_active_timer": 0.0,
		"hades_buffed": false,
		"hades_buff_timer": 0.0,
		"fire_flash": 0.0,
		"total_damage": 0.0,
		"kill_count": 0,
		"targeting_mode": "closest",
		"build_timer": 0.3,
	}
	if tower["is_support"]:
		tower["buff_timer"] = tower["buff_cooldown"]
	if tower["is_beam_cone"]:
		tower["facing_angle"] = _best_cone_facing(tower["x"], tower["y"],
			data["range"], data["cone_half_angle"])
	return tower

func _best_cone_facing(tx: float, ty: float, cone_len: float, half_angle: float) -> float:
	var cl2 := cone_len * cone_len
	var cos_half := cos(half_angle)
	var best_ang := 0.0
	var best_hits := -1
	for i in range(8):
		var ang: float = i * PI / 4.0
		var fx := cos(ang); var fy := sin(ang)
		var hits := 0
		for p in Config.path_pixels:
			var dx: float = p.x - tx; var dy: float = p.y - ty
			var d2: float = dx * dx + dy * dy
			if d2 <= 1.0 or d2 > cl2:
				continue
			var dot: float = dx * fx + dy * fy
			if dot <= 0: continue
			if dot * dot >= cos_half * cos_half * d2:
				hits += 1
		if hits > best_hits:
			best_hits = hits
			best_ang = ang
	return best_ang

func upgrade_tower(tower: Dictionary) -> bool:
	if tower["level"] >= Config.MAX_TOWER_LEVEL:
		return false
	var data: Dictionary = Config.TOWER_DATA[tower["type"]]
	var cost: int = roundi(data["upgrade_cost"] * pow(1.5, tower["level"] - 1))
	if not spend(cost):
		return false
	tower["level"] += 1
	tower["damage"] *= Config.UPGRADE_MULT
	tower["range"] *= 1.1
	tower["attack_speed"] *= 1.15
	notify(Locale.tf("tower_upgraded", {"name": Locale.t(tower["name"]), "level": tower["level"]}), tower["color"])
	return true

func sell_tower(tower: Dictionary) -> void:
	var data: Dictionary = Config.TOWER_DATA[tower["type"]]
	var refund: int = roundi(data["cost"] * Config.SELL_REFUND * tower["level"])
	earn(refund)
	for i in range(towers.size() - 1, -1, -1):
		if towers[i]["id"] == tower["id"]:
			towers.remove_at(i)
			break
	occupied_tiles.erase(str(tower["col"]) + "," + str(tower["row"]))
	if selected_tower != null and selected_tower["id"] == tower["id"]:
		selected_tower = null
	notify(Locale.tf("sold_tower", {"name": Locale.t(tower["name"])}), Color(0.667, 0.667, 0.667))

func has_tower_type(type: String) -> bool:
	for t in towers:
		if t["type"] == type:
			return true
	return false

func is_buildable(col: int, row: int) -> bool:
	if col < 0 or col >= Config.GRID_COLS or row < 0 or row >= Config.GRID_ROWS:
		return false
	if Config.is_path(col, row):
		return false
	if occupied_tiles.has(str(col) + "," + str(row)):
		return false
	return true

# ═══════════════════════════════════════════════════════
# ENEMY
# ═══════════════════════════════════════════════════════
func create_enemy(type: String) -> Dictionary:
	var data: Dictionary = Config.ENEMY_DATA[type]
	var sp := Config.spawn_pixel()
	_next_id += 1
	var scaled_hp: float = data["hp"] * Config.hp_scale(wave)
	var scaled_speed: float = data["speed"] * Config.spd_scale(wave)
	return {
		"id": _next_id,
		"type": type,
		"hp": scaled_hp,
		"max_hp": scaled_hp,
		"speed": scaled_speed,
		"core_dmg": data["core_dmg"],
		"is_boss": data["is_boss"],
		"color": data["color"],
		"radius": data["radius"],
		"name": data["name"],
		"x": sp.x, "y": sp.y,
		"path_index": 0,
		"alive": true,
		"reached_core": false,
		"slow_amount": 0.0,
		"slow_timer": 0.0,
		"shield": 0.0,
		"shield_buff": false,
		"shield_buff_timer": 0.0,
		"flash_timer": 0.0,
		"spawn_timer": 0.4,
		"ability_timer": 0.0,
		"burn_stacks": 0,
		"burn_timer": 0.0,
		"frost_timer": 0.0,
	}

func _has_alive_type(etype: String) -> bool:
	for e in enemies:
		if e["alive"] and e["type"] == etype:
			return true
	return false

func _is_guardian_protected(enemy: Dictionary) -> bool:
	if enemy["type"] == "holy_sentinel":
		return false
	if not _has_alive_type("holy_sentinel"):
		return false
	@warning_ignore("integer_division")
	var half: int = Config.path_pixels.size() / 2
	return enemy.get("path_index", 0) < half

func _michael_shield(michael: Dictionary) -> void:
	# Every 8 seconds, grant all enemies 50% damage reduction for 2 seconds
	michael["ability_timer"] = 8.0
	for e in enemies:
		if e["alive"] and e["type"] != "archangel_michael":
			e["shield_buff"] = true
			e["shield_buff_timer"] = 2.0
	# Golden shield dome from Michael's position
	effects.append({"type": "michael_shield", "x": michael["x"], "y": michael["y"], "radius": 0, "color": Color(1.0, 0.95, 0.6), "timer": 0.8})
	notify(Locale.t("Michael's divine shield protects all!"), Color(1.0, 0.95, 0.8))

func _zeus_lightning(zeus: Dictionary) -> void:
	# Every 6 seconds, disable 1-2 closest towers for 2 seconds
	zeus["ability_timer"] = 6.0
	var zx: float = zeus["x"]
	var zy: float = zeus["y"]
	var candidates: Array = []
	for t in towers:
		if t["is_disabled"]:
			continue
		var dx: float = t["x"] - zx
		var dy: float = t["y"] - zy
		candidates.append({"tower": t, "dist": dx * dx + dy * dy})
	candidates.sort_custom(func(a, b): return a["dist"] < b["dist"])
	var count := mini(2, candidates.size())
	for j in range(count):
		var t: Dictionary = candidates[j]["tower"]
		t["is_disabled"] = true
		t["disable_timer"] = 2.0
		# Lightning bolt from Zeus to tower
		effects.append({"type": "zeus_bolt", "x": zx, "y": zy, "x2": t["x"], "y2": t["y"], "radius": 0, "color": Color(0.8, 0.9, 1.0), "timer": 0.4})
	if count > 0:
		Audio.play_sfx("core_hit")

func _raphael_heal(raphael: Dictionary) -> void:
	# Every 6 seconds, heal the most damaged ally for 20% max HP
	raphael["ability_timer"] = 6.0
	var best = null
	var best_missing := 0.0
	for e in enemies:
		if not e["alive"] or e["type"] == "archangel_raphael":
			continue
		var missing: float = e["max_hp"] - e["hp"]
		if missing > best_missing:
			best_missing = missing
			best = e
	if best != null and best_missing > 0:
		var heal: float = best["max_hp"] * 0.15
		best["hp"] = minf(best["hp"] + heal, best["max_hp"])
		effects.append({"type": "heal_beam", "x": raphael["x"], "y": raphael["y"], "x2": best["x"], "y2": best["y"], "radius": 0, "color": Color(0.4, 1.0, 0.5), "timer": 0.3})
		add_effect("heal_pulse", best["x"], best["y"], best.get("radius", 8.0), Color(0.4, 1.0, 0.5))

func update_enemies(dt: float) -> void:
	var path_px: Array[Vector2] = Config.path_pixels
	var has_commander := _has_alive_type("archangel_marshal")
	# REDESIGN: cache NEC aura slow sources for movement step
	var nec_towers: Array = []
	var nec_aura_slow: float = 0.0
	for t in towers:
		if t["type"] == "soul_reaper" and not t["is_disabled"]:
			nec_towers.append(t)
	if nec_towers.size() > 0:
		nec_aura_slow = Config.TOWER_DATA["soul_reaper"].get("aura_slow", 0.0)

	# Process Michael, Zeus, and Raphael abilities
	for e in enemies:
		if not e["alive"]:
			continue
		if e["type"] == "archangel_michael" or e["type"] == "zeus" or e["type"] == "archangel_raphael":
			e["ability_timer"] -= dt
			if e["ability_timer"] <= 0:
				if e["type"] == "archangel_michael":
					_michael_shield(e)
				elif e["type"] == "zeus":
					_zeus_lightning(e)
				elif e["type"] == "archangel_raphael":
					_raphael_heal(e)

	var i := enemies.size() - 1
	while i >= 0:
		var e: Dictionary = enemies[i]
		if not e["alive"]:
			enemies.remove_at(i)
			i -= 1
			continue

		# Safety: kill any enemy that has HP <= 0 but is still alive
		if e["hp"] <= 0:
			e["alive"] = false
			stats["enemies_killed"] += 1
			earn_from_kill(e["type"], false)
			add_effect("death", e["x"], e["y"], e["radius"], e["color"])
			Audio.play_sfx("enemy_death")
			enemies.remove_at(i)
			i -= 1
			continue

		# Spawn fade-in timer
		if e["spawn_timer"] > 0:
			e["spawn_timer"] -= dt

		# Flash timer
		if e["flash_timer"] > 0:
			e["flash_timer"] -= dt

		# Slow timer
		if e["slow_timer"] > 0:
			e["slow_timer"] -= dt
			if e["slow_timer"] <= 0:
				e["slow_amount"] = 0.0

		# Shield buff timer
		if e["shield_buff_timer"] > 0:
			e["shield_buff_timer"] -= dt
			if e["shield_buff_timer"] <= 0:
				e["shield_buff"] = false

		# REDESIGN: COC frost state decay (snowflake marker + slow)
		if e["frost_timer"] > 0:
			e["frost_timer"] -= dt

		# REDESIGN: MAG burn DoT tick
		if e["burn_stacks"] > 0:
			e["burn_timer"] -= dt
			if e["burn_timer"] <= 0:
				e["burn_stacks"] = 0
			else:
				var burn_dps: float = e["burn_stacks"] * Config.TOWER_DATA["inferno_warlock"]["burn_dps_per_stack"]
				e["hp"] -= burn_dps * dt
				if e["hp"] <= 0:
					e["alive"] = false
					stats["enemies_killed"] += 1
					earn_from_kill(e["type"], true)
					add_effect("death", e["x"], e["y"], e["radius"], e["color"])
					Audio.play_sfx("enemy_death")
					enemies.remove_at(i)
					i -= 1
					continue

		# Movement
		var spd: float = e["speed"]
		if e["slow_amount"] > 0:
			spd *= (1.0 - e["slow_amount"])
		# REDESIGN: NEC passive aura slow — any enemy in NEC range
		if nec_aura_slow > 0:
			for nt in nec_towers:
				var ndx: float = e["x"] - nt["x"]
				var ndy: float = e["y"] - nt["y"]
				if ndx * ndx + ndy * ndy <= nt["range"] * nt["range"]:
					spd *= (1.0 - nec_aura_slow)
					break
		# REDESIGN: COC frost slow — while enemy has active frost_timer
		if e["frost_timer"] > 0:
			spd *= 0.65  # 35% slow while being frozen by cone
		if fast_enemy_waves > 0:
			spd *= 1.3
		# Archangel Commander aura: +25% speed to allies
		if has_commander and e["type"] != "archangel_marshal":
			spd *= 1.25

		if e["path_index"] >= path_px.size():
			e["alive"] = false
			e["reached_core"] = true
			core_hp = maxf(0, core_hp - e["core_dmg"])
			# Catch-up: insurance payout when enemies leak
			var insurance := roundi(e["core_dmg"] * 1.5)
			earn(insurance)
			var last_pt: Vector2 = path_px[path_px.size() - 1]
			add_effect("core_hit", last_pt.x, last_pt.y, 10.0, Color.RED)
			Audio.play_sfx("core_hit")
			shake(4.0, 0.2)
			if core_hp <= 0:
				shake(8.0, 0.4)
				phase = "gameover"
				Audio.play_music_stinger("defeat")
			i -= 1
			continue

		var target_pt: Vector2 = path_px[e["path_index"]]
		var dx: float = target_pt.x - e["x"]
		var dy: float = target_pt.y - e["y"]
		var dist: float = sqrt(dx * dx + dy * dy)
		var move_dist: float = spd * dt

		if dist <= move_dist:
			e["x"] = target_pt.x
			e["y"] = target_pt.y
			e["path_index"] += 1
		else:
			e["x"] += (dx / dist) * move_dist
			e["y"] += (dy / dist) * move_dist

		i -= 1

# ═══════════════════════════════════════════════════════
# PROJECTILE
# ═══════════════════════════════════════════════════════
func create_projectile(tower: Dictionary, target: Dictionary) -> Dictionary:
	return {
		"x": tower["x"],
		"y": tower["y"],
		"target": target,
		"target_last_x": target["x"],
		"target_last_y": target["y"],
		"damage": tower["damage"],
		"speed": Config.PROJECTILE_SPEED,
		"tower": tower,
		"alive": true,
		"color": tower["color"],
		"is_aoe": tower["is_aoe"],
		"aoe_radius": tower["aoe_radius"],
	}

func update_projectiles(dt: float) -> void:
	var i := projectiles.size() - 1
	while i >= 0:
		var p: Dictionary = projectiles[i]
		if not p["alive"]:
			projectiles.remove_at(i)
			i -= 1
			continue

		var tgt = p["target"]
		if tgt != null and tgt is Dictionary and tgt.get("alive", false):
			p["target_last_x"] = tgt["x"]
			p["target_last_y"] = tgt["y"]

		var dx: float = p["target_last_x"] - p["x"]
		var dy: float = p["target_last_y"] - p["y"]
		var dist: float = sqrt(dx * dx + dy * dy)
		var move_dist: float = p["speed"] * dt

		if dist <= move_dist + 5:
			p["alive"] = false
			if p["is_aoe"]:
				combat_aoe(p["target_last_x"], p["target_last_y"], p["aoe_radius"], p["damage"], p["tower"])
				add_effect("aoe", p["target_last_x"], p["target_last_y"], p["aoe_radius"], Color(1.0, 0.47, 0.12, 0.25))
			elif tgt != null and tgt is Dictionary and tgt.get("alive", false):
				combat_hit(tgt, p["damage"], p["tower"])
		else:
			p["x"] += (dx / dist) * move_dist
			p["y"] += (dy / dist) * move_dist

		if dist > 800:
			p["alive"] = false

		i -= 1

# ═══════════════════════════════════════════════════════
# TARGETING
# ═══════════════════════════════════════════════════════
const TARGETING_MODES := ["closest", "strongest"]

func cycle_targeting(tower: Dictionary) -> void:
	var idx := TARGETING_MODES.find(tower.get("targeting_mode", "closest"))
	tower["targeting_mode"] = TARGETING_MODES[(idx + 1) % TARGETING_MODES.size()]

func find_target(tower: Dictionary):
	var mode: String = tower.get("targeting_mode", "closest")
	var best = null
	var best_val: float = -1.0 if mode != "closest" else INF
	var r2: float = tower["range"] * tower["range"]
	for e in enemies:
		if not e["alive"]:
			continue
		var dx: float = e["x"] - tower["x"]
		var dy: float = e["y"] - tower["y"]
		var dist_sq: float = dx * dx + dy * dy
		if dist_sq > r2:
			continue
		match mode:
			"closest":
				if dist_sq < best_val:
					best_val = dist_sq
					best = e
			"strongest":
				if e["max_hp"] > best_val:
					best_val = e["max_hp"]
					best = e
	return best

func in_radius(cx: float, cy: float, radius: float) -> Array:
	var r2: float = radius * radius
	var result: Array = []
	for e in enemies:
		if not e["alive"]:
			continue
		var dx: float = e["x"] - cx
		var dy: float = e["y"] - cy
		if dx * dx + dy * dy <= r2:
			result.append(e)
	return result

# ═══════════════════════════════════════════════════════
# COMBAT
# ═══════════════════════════════════════════════════════
func calc_damage(base_dmg: float, tower, enemy: Dictionary) -> float:
	var dmg := base_dmg
	if double_damage > 0:
		dmg *= 2.0
	if tower != null and tower is Dictionary:
		dmg *= tower.get("damage_mult", 1.0)
	if enemy.get("shield", 0.0) > 0:
		dmg *= (1.0 - enemy["shield"])
	if enemy.get("shield_buff", false):
		dmg *= 0.7
	# Archangel Commander aura: 25% damage reduction for allies
	if _has_alive_type("archangel_marshal") and enemy.get("type", "") != "archangel_marshal":
		dmg *= 0.75
	return maxf(1.0, dmg)

func combat_hit(enemy: Dictionary, base_dmg: float, tower) -> void:
	if not enemy.get("alive", false):
		return
	# Holy Sentinel protection: enemies in first half of path are invulnerable
	if _is_guardian_protected(enemy):
		enemy["flash_timer"] = 0.05
		return
	var dmg := calc_damage(base_dmg, tower, enemy)
	enemy["hp"] -= dmg
	enemy["flash_timer"] = 0.12

	# Track damage for overview
	if tower != null and tower is Dictionary:
		tower["total_damage"] = tower.get("total_damage", 0.0) + dmg

	# Hit spark + floating damage number — pick the effect flavor that matches
	# the tower's fiction. Soul Reaper's scythe/spirit-bolt uses a ghostly
	# green burst; every other tower falls back to the warm orange hit_spark.
	var spark_col := Color(1, 0.7, 0.3)
	var hit_fx := "hit_spark"
	if tower != null and tower is Dictionary:
		spark_col = tower.get("color", spark_col)
		if tower.get("type", "") == "soul_reaper":
			hit_fx = "soul_hit"
	add_effect(hit_fx, enemy["x"], enemy["y"], 6.0, spark_col)
	# Offset damage numbers slightly randomly so they don't stack
	var nx: float = enemy["x"] + (fmod(dmg * 7.3, 16.0) - 8.0)
	add_dmg_number(nx, enemy["y"] - enemy.get("radius", 8.0) - 4, dmg, spark_col)

	# Apply slow from towers with slow_power (legacy path; NEC uses aura now)
	if tower != null and tower is Dictionary and tower.get("slow_power", 0.0) > 0:
		enemy["slow_amount"] = tower["slow_power"]
		enemy["slow_timer"] = 2.0

	# REDESIGN: MAG burn stacks on hit
	if tower != null and tower is Dictionary and tower.get("type", "") == "inferno_warlock":
		var mdata: Dictionary = Config.TOWER_DATA["inferno_warlock"]
		enemy["burn_stacks"] = mini(enemy["burn_stacks"] + int(mdata["burn_stacks_per_hit"]), int(mdata["burn_stack_cap"]))
		enemy["burn_timer"] = float(mdata["burn_duration"])

	if enemy["hp"] <= 0:
		combat_kill(enemy, tower)

func combat_aoe(cx: float, cy: float, radius: float, base_dmg: float, tower) -> void:
	var targets := in_radius(cx, cy, radius)
	for e in targets:
		combat_hit(e, base_dmg, tower)

func combat_kill(enemy: Dictionary, tower) -> void:
	enemy["alive"] = false
	stats["enemies_killed"] += 1
	if tower != null and tower is Dictionary:
		tower["kill_count"] = tower.get("kill_count", 0) + 1
	earn_from_kill(enemy["type"], tower != null and tower is Dictionary and tower.get("is_aoe", false))

	if should_drop_relic(enemy["type"]):
		drop_relic(enemy["x"], enemy["y"])

	add_effect("death", enemy["x"], enemy["y"], enemy["radius"], enemy["color"])
	Audio.play_sfx("enemy_death")

# ═══════════════════════════════════════════════════════
# TOWER UPDATE
# ═══════════════════════════════════════════════════════
func update_towers(dt: float) -> void:
	# Decay Hades buff timers on all towers
	for t in towers:
		if t["hades_buffed"]:
			t["hades_buff_timer"] -= dt
			if t["hades_buff_timer"] <= 0:
				t["hades_buffed"] = false

	for t in towers:
		if t["fire_flash"] > 0:
			t["fire_flash"] -= dt
		if t["build_timer"] > 0:
			t["build_timer"] -= dt

		if t["is_disabled"]:
			t["disable_timer"] -= dt
			if t["disable_timer"] <= 0:
				t["is_disabled"] = false
			continue

		# Hades support tower: buff nearby towers + damage enemies every cycle
		if t["is_support"]:
			t["buff_timer"] -= dt
			if t["buff_active_timer"] > 0:
				t["buff_active_timer"] -= dt
			if t["buff_timer"] <= 0:
				t["buff_timer"] = t["buff_cooldown"]
				t["buff_active_timer"] = t["buff_duration"]
				t["fire_flash"] = 0.3
				_apply_hades_buff(t)
				_hades_damage(t)
				Audio.play_sfx("hades_buff", -18.0)
			continue

		# Lucifer global pulse: damage ALL enemies + execute threshold
		if t["is_global"]:
			var pulse_speed: float = t["attack_speed"] * perm_speed_buff * temp_speed_buff
			if t["hades_buffed"]:
				pulse_speed *= t.get("buff_multiplier", 1.5)
			t["cooldown"] -= dt
			if t["cooldown"] > 0:
				continue
			if enemies.size() == 0:
				continue
			t["cooldown"] = 1.0 / pulse_speed
			t["fire_flash"] = 0.3
			_lucifer_pulse(t)
			continue

		# REDESIGN: Cocytus continuous cone — always casting in facing direction
		if t["is_beam_cone"]:
			_cocytus_cone(t, dt)
			continue

		var effective_speed: float = t["attack_speed"] * perm_speed_buff * temp_speed_buff
		if t["hades_buffed"]:
			effective_speed *= 1.5
		t["cooldown"] -= dt
		if t["cooldown"] > 0:
			continue

		var target = find_target(t)
		t["target"] = target
		if target == null:
			continue

		t["cooldown"] = 1.0 / effective_speed
		t["fire_flash"] = 0.3  # how long the attack pose holds after firing
		projectiles.append(create_projectile(t, target))
		Audio.play_shoot(t["type"])

func _lucifer_pulse(tower: Dictionary) -> void:
	var base_dmg: float = tower["damage"]
	var tx: float = tower["x"]
	var ty: float = tower["y"]
	var threshold: float = Config.TOWER_DATA["lucifer"].get("execute_threshold", 0.0)
	# Wave ring: 1000 px radius over 1.2s → ~833 px/s. Must match game_world
	# lucifer_wave draw (max_r + duration) so burst pops exactly when the ring
	# crosses each enemy. Damage is applied instantly; the burst is visual.
	var wave_speed: float = 1000.0 / 1.2
	for e in enemies:
		if e["alive"]:
			combat_hit(e, base_dmg, tower)
			# REDESIGN: execute — kill any enemy surviving pulse below threshold HP
			if e["alive"] and threshold > 0 and e["hp"] <= e["max_hp"] * threshold:
				combat_kill(e, tower)
			var dx: float = e["x"] - tx
			var dy: float = e["y"] - ty
			var delay: float = sqrt(dx * dx + dy * dy) / wave_speed
			effects.append({
				"type": "lucifer_hit",
				"x": e["x"], "y": e["y"],
				"radius": e.get("radius", 8.0),
				"color": tower["color"],
				"timer": 0.22,
				"delay": delay,
			})
	add_effect("lucifer_wave", tower["x"], tower["y"], 0, tower["color"])
	Audio.play_sfx("lucifer_pulse", -6.0)

func _cocytus_cone(tower: Dictionary, dt: float) -> void:
	# Continuous damage every tick — bypasses calc_damage's 1.0 floor because
	# per-tick damage is fractional (e.g. 0.2 at 60 FPS). Applies multipliers manually.
	# Force casting pose always (fire_flash held high while cone is active).
	tower["fire_flash"] = 0.3
	if enemies.size() == 0:
		return
	var cone_dps: float = tower["damage"] * tower["attack_speed"] * perm_speed_buff * temp_speed_buff
	if tower["hades_buffed"]:
		cone_dps *= tower.get("buff_multiplier", 1.5)
	if double_damage > 0:
		cone_dps *= 2.0
	cone_dps *= tower.get("damage_mult", 1.0)
	var cl2: float = tower["range"] * tower["range"]
	var half_angle: float = Config.TOWER_DATA[tower["type"]]["cone_half_angle"]
	var cos_half: float = cos(half_angle)
	# REDESIGN: oscillating sweep — ±15° around set facing, synced to draw
	var sweep: float = sin(game_time * 1.5) * (PI / 12.0)
	var eff_facing: float = tower["facing_angle"] + sweep
	var fx: float = cos(eff_facing)
	var fy: float = sin(eff_facing)
	var has_cmd := _has_alive_type("archangel_marshal")
	var corruption: float = Config.TOWER_DATA["hades"].get("corruption_mult", 1.0)
	var hit_any := false
	for e in enemies:
		if not e["alive"]:
			continue
		var dx: float = e["x"] - tower["x"]
		var dy: float = e["y"] - tower["y"]
		var d2: float = dx * dx + dy * dy
		if d2 <= 1.0 or d2 > cl2:
			continue
		var dot: float = dx * fx + dy * fy
		if dot <= 0:
			continue
		if dot * dot < cos_half * cos_half * d2:
			continue
		if _is_guardian_protected(e):
			e["flash_timer"] = 0.05
			continue
		# Apply raw damage — NO 1.0 floor (cone is fractional per tick)
		var tick_dmg: float = cone_dps * dt
		if e.get("shield", 0.0) > 0:
			tick_dmg *= (1.0 - e["shield"])
		if e.get("shield_buff", false):
			tick_dmg *= 0.7
		if has_cmd and e.get("type", "") != "archangel_marshal":
			tick_dmg *= 0.75
		if corruption > 1.0:
			for h in towers:
				if h["type"] != "hades" or h["is_disabled"]:
					continue
				var dxh: float = e["x"] - h["x"]
				var dyh: float = e["y"] - h["y"]
				if dxh * dxh + dyh * dyh <= h["range"] * h["range"]:
					tick_dmg *= corruption
					break
		e["hp"] -= tick_dmg
		# REDESIGN: frost state instead of white flash — snowflake icon + slow
		e["frost_timer"] = 0.3
		tower["total_damage"] = tower.get("total_damage", 0.0) + tick_dmg
		hit_any = true
		if e["hp"] <= 0:
			combat_kill(e, tower)
	# Periodic frost spike emit inside cone for visual continuity
	tower["cone_emit_timer"] -= dt
	if tower["cone_emit_timer"] <= 0:
		tower["cone_emit_timer"] = 0.12
		var max_r: float = tower["range"]
		var r_pt: float = max_r * (0.4 + randf() * 0.6)
		var a_off: float = (randf() - 0.5) * 2.0 * half_angle
		var ang: float = eff_facing + a_off
		var ex: float = tower["x"] + cos(ang) * r_pt
		var ey: float = tower["y"] + sin(ang) * r_pt
		effects.append({
			"type": "frost_spike",
			"x": tower["x"], "y": tower["y"],
			"x2": ex, "y2": ey,
			"radius": 1.0,
			"color": Color(0.6, 0.85, 1.0),
			"timer": 0.14,
		})

func _apply_hades_buff(hades_tower: Dictionary) -> void:
	var r2: float = hades_tower["range"] * hades_tower["range"]
	var buff_dur: float = hades_tower["buff_duration"]
	for t in towers:
		if t["id"] == hades_tower["id"]:
			continue
		if t["is_support"]:
			continue
		var dx: float = t["x"] - hades_tower["x"]
		var dy: float = t["y"] - hades_tower["y"]
		if dx * dx + dy * dy <= r2:
			t["hades_buffed"] = true
			t["hades_buff_timer"] = buff_dur
			effects.append({
				"type": "hades_beam",
				"x": hades_tower["x"], "y": hades_tower["y"],
				"x2": t["x"], "y2": t["y"],
				"radius": 0, "color": Color(0.7, 0.5, 1.0),
				"timer": 0.5,
			})

func _hades_damage(hades_tower: Dictionary) -> void:
	var base_dmg: float = hades_tower["damage"]
	if base_dmg <= 0:
		return
	var r2: float = hades_tower["range"] * hades_tower["range"]
	for e in enemies:
		if not e["alive"]:
			continue
		var dx: float = e["x"] - hades_tower["x"]
		var dy: float = e["y"] - hades_tower["y"]
		if dx * dx + dy * dy <= r2:
			combat_hit(e, base_dmg, hades_tower)
			effects.append({
				"type": "hades_curse",
				"x": hades_tower["x"], "y": hades_tower["y"],
				"x2": e["x"], "y2": e["y"],
				"radius": 0, "color": Color(1.0, 0.3, 0.45),
				"timer": 0.5,
			})

# ═══════════════════════════════════════════════════════
# WAVE MANAGER
# ═══════════════════════════════════════════════════════
func start_wave() -> void:
	wave += 1
	if wave > Config.MAX_WAVES:
		phase = "victory"
		Audio.play_music_stinger("victory")
		return
	wave_active = true
	Audio.update_music_for_wave(wave)
	var wave_def: Dictionary = Config.WAVE_DATA[wave - 1]
	wave_desc = wave_def["desc"]

	spawn_queue.clear()
	# Separate regular enemies from special ones (bosses, commanders, guardians)
	var regular: Array = []  # interleaved
	var specials: Array = [] # appended at end in small groups
	for entry in wave_def["enemies"]:
		var etype: String = entry["type"]
		var edata: Dictionary = Config.ENEMY_DATA.get(etype, {})
		var is_special: bool = edata.get("is_boss", false) or etype in ["archangel_marshal", "holy_sentinel", "archangel_michael", "zeus"]
		for j in range(entry["count"]):
			if is_special:
				specials.append(etype)
			else:
				regular.append(etype)
	# Interleave regular enemies by round-robin from each type pool
	var pools: Dictionary = {}
	for etype in regular:
		if not pools.has(etype):
			pools[etype] = 0
		pools[etype] += 1
	var mixed: Array = []
	var remaining := regular.size()
	while remaining > 0:
		for etype in pools:
			if pools[etype] > 0:
				mixed.append(etype)
				pools[etype] -= 1
				remaining -= 1
	spawn_queue = mixed
	# Sprinkle specials in the back half of the wave
	@warning_ignore("integer_division")
	var insert_start: int = maxi(spawn_queue.size() / 2, spawn_queue.size() - specials.size() * 3)
	for i in range(specials.size()):
		var idx: int = mini(insert_start + i * 2, spawn_queue.size())
		spawn_queue.insert(idx, specials[i])
	spawn_timer = 0.5

	notify(Locale.tf("wave_start_notify", {"wave": wave, "desc": Locale.t(wave_desc)}), Color(1.0, 0.8, 0.0))
	# Cinematic wave announcement — snapshot the wave + desc so the banner
	# draws a stable label even if mid-fade state mutates. Boss waves flag
	# themselves for a red-tinted banner; the game_world renders the card.
	wave_banner_timer = WAVE_BANNER_DURATION
	wave_banner_num = wave
	wave_banner_desc = wave_desc
	wave_banner_is_boss = false
	for entry in wave_def["enemies"]:
		var etype: String = entry["type"]
		var edata: Dictionary = Config.ENEMY_DATA.get(etype, {})
		if edata.get("is_boss", false):
			wave_banner_is_boss = true
			break
	Audio.play_sfx("wave_start")
	shake(2.0, 0.15)

func update_waves(dt: float) -> void:
	if wave_active:
		spawn_timer -= dt
		if spawn_timer <= 0 and spawn_queue.size() > 0:
			var etype: String = spawn_queue.pop_front()
			enemies.append(create_enemy(etype))
			var wave_def: Dictionary = Config.WAVE_DATA[wave - 1]
			spawn_timer = wave_def["interval"]

		# Hellfire Rain pact: multiple strikes spread across the wave (3s, 8s, 13s in)
		if hellfire_strikes_left > 0:
			hellfire_strike_timer -= dt
			if hellfire_strike_timer <= 0:
				for e in enemies:
					if e["alive"]:
						e["hp"] -= e["max_hp"] * 0.30
						e["flash_timer"] = 0.3
						if e["hp"] <= 0:
							e["alive"] = false
							stats["enemies_killed"] += 1
							earn_from_kill(e["type"], true)
				add_effect("screen_flash", 0, 0, 0, Color(1.0, 0.2, 0.0))
				notify(Locale.t("Hellfire Rain strikes!"), Color(1.0, 0.4, 0.0))
				hellfire_strikes_left -= 1
				hellfire_strike_timer = 5.0  # next strike 5s later

		if spawn_queue.size() == 0 and enemies.size() == 0:
			complete_wave()
	else:
		if phase == "playing" and not show_pact:
			between_wave_timer -= dt
			if between_wave_timer <= 0:
				start_wave()

func complete_wave() -> void:
	wave_active = false
	# Wave bonus: base linear + powHPG-scaled portion so it stays meaningful late game.
	var wave_bonus: int = wave * 2 + roundi(30 * reward_scale())
	earn(wave_bonus)
	notify(Locale.tf("wave_complete_notify", {"wave": wave, "bonus": wave_bonus}), Color(0.8, 0.267, 1.0))
	Audio.play_sfx("wave_complete")

	if double_damage > 0:
		double_damage -= 1
	if sin_mult_waves > 0:
		sin_mult_waves -= 1
		if sin_mult_waves <= 0:
			sin_multiplier = 1.0
	if fast_enemy_waves > 0:
		fast_enemy_waves -= 1

	# Replenish 1 die per wave (capped at max)
	if dice_uses_left < Config.DICE_MAX_USES:
		dice_uses_left += 1
		notify(Locale.tf("dice_replenish", {"count": dice_uses_left, "max": Config.DICE_MAX_USES}), Color(1.0, 0.6, 0.2))

	if wave >= Config.MAX_WAVES:
		phase = "victory"
		Audio.play_music_stinger("victory")
		return

	if wave % Config.PACT_EVERY == 0:
		offer_pact()

	between_wave_timer = Config.BETWEEN_WAVE_DELAY

# ═══════════════════════════════════════════════════════
# GAMBLING — DEVIL'S DICE
# ═══════════════════════════════════════════════════════
func roll_dice() -> Dictionary:
	if dice_uses_left <= 0 or not wave_active:
		return {}
	dice_uses_left -= 1

	var d1: int = randi() % 6 + 1
	var total: int = d1
	var outcome: Dictionary = Config.get_dice_outcome(total, wave)

	show_dice_result = true
	dice_result = {"d1": d1, "total": total, "outcome": outcome}
	dice_result_timer = 5.0
	Audio.play_sfx("dice_roll")
	shake(3.0, 0.15)

	var msg_color := Color(0.267, 1.0, 0.267) if outcome["positive"] else Color(1.0, 0.267, 0.267)
	notify(Locale.t(outcome["name"]) + " (" + str(d1) + ")", msg_color)

	match outcome["effect"]:
		"surge":
			_apply_speed_buff(1.8, 15.0)
		"aoe_25":
			for e in enemies:
				if e["alive"]:
					var dmg: float = e["max_hp"] * 0.25
					e["hp"] -= dmg
					e["flash_timer"] = 0.2
					if e["hp"] <= 0:
						e["alive"] = false
						stats["enemies_killed"] += 1
						earn_from_kill(e["type"], true)
			add_effect("screen_flash", 0, 0, 0, Color(1.0, 0.4, 0.0))
		"aoe_10":
			for e in enemies:
				if e["alive"]:
					var dmg: float = e["max_hp"] * 0.10
					e["hp"] -= dmg
					e["flash_timer"] = 0.15
					if e["hp"] <= 0:
						e["alive"] = false
						stats["enemies_killed"] += 1
						earn_from_kill(e["type"], true)
			add_effect("screen_flash", 0, 0, 0, Color(1.0, 0.6, 0.2))
		"speed_boost":
			_apply_speed_buff(1.3, 10.0)
		"bonus_sins":
			earn(25)
		"tithe":
			earn(10)
		"tithe_big":
			earn(50)
		"slow_towers":
			_apply_speed_buff(0.75, 10.0)
		"disable_3s":
			for t in towers:
				t["is_disabled"] = true
				t["disable_timer"] = 3.0
		"tax_sins":
			var lost: int = roundi(sins * 0.10)
			sins -= lost

	return dice_result

# ═══════════════════════════════════════════════════════
# GAMBLING — RELICS
# ═══════════════════════════════════════════════════════
func should_drop_relic(enemy_type: String) -> bool:
	var roll := randf()
	if enemy_type == "grand_paladin":
		return true
	if enemy_type == "war_titan":
		return roll < 0.15
	if enemy_type == "crusader" or enemy_type == "temple_cleric":
		return roll < 0.05
	return roll < 0.03

func drop_relic(rx: float, ry: float) -> void:
	var loot: Dictionary = _weighted_pick(Config.RELIC_LOOT)
	notify(Locale.tf("relic_drop", {"name": Locale.t(loot["name"])}), Color(1.0, 0.8, 0.0))
	add_effect("relic", rx, ry, 15.0, Color(1.0, 0.8, 0.0))

	match loot["type"]:
		"aoe":
			combat_aoe(rx, ry, 80.0, 50.0, null)
			add_effect("aoe", rx, ry, 80.0, Color(1.0, 0.47, 0.12, 0.25))
		"random_sins":
			var amt: int = 50 + randi() % 100
			earn(amt)
			notify(Locale.tf("sins_gained", {"amount": amt}), Color(0.8, 0.267, 1.0))
		"tower_buff":
			var nearest = null
			var best_dist := INF
			for t in towers:
				var d := sqrt((t["x"] - rx) * (t["x"] - rx) + (t["y"] - ry) * (t["y"] - ry))
				if d < best_dist:
					best_dist = d
					nearest = t
			if nearest != null:
				nearest["damage_mult"] += 0.25
				notify(Locale.tf("tower_buff", {"name": Locale.t(nearest["name"])}), Color(0.267, 1.0, 0.267))
		"curse":
			if towers.size() > 0:
				var strongest: Dictionary = towers[0]
				for t in towers:
					if t["damage"] * t["damage_mult"] > strongest["damage"] * strongest["damage_mult"]:
						strongest = t
				strongest["is_disabled"] = true
				strongest["disable_timer"] = 10.0
				notify(Locale.tf("tower_cursed", {"name": Locale.t(strongest["name"])}), Color(0.8, 0.2, 0.2))
		"trap":
			enemies.append(create_enemy("war_titan"))
			notify(Locale.t("Trojan Relic! Elite enemy spawned!"), Color(0.8, 0.2, 0.2))
		_:
			earn(30)

# ═══════════════════════════════════════════════════════
# GAMBLING — PACTS
# ═══════════════════════════════════════════════════════
func offer_pact() -> void:
	var pool := Config.PACT_POOL.duplicate()
	pool.shuffle()
	pact_choices = pool.slice(0, 3)
	show_pact = true
	pact_offered.emit(pact_choices)

func accept_pact(pact: Dictionary) -> void:
	match pact["b_effect"]:
		"double_dmg_3":
			double_damage = 3
		"free_towers_2":
			free_towers = 2
		"double_sins_1":
			sin_multiplier = 2.0
			sin_mult_waves = 1
		"massive_aoe":
			hellfire_strikes_left = 3
			hellfire_strike_timer = 3.0  # first strike 3s into next wave
			notify(Locale.t("Hellfire Rain will strike 3 times next wave!"), Color(1.0, 0.4, 0.0))
		"speed_30_perm":
			perm_speed_buff += 0.3
		"double_earn_3":
			sin_multiplier = 2.0
			sin_mult_waves = 3

	match pact["c_effect"]:
		"core_-20":
			core_hp = maxf(0, core_hp - 20)
			if core_hp <= 0:
				phase = "gameover"
				Audio.play_music_stinger("defeat")
		"fast_enemy_2":
			fast_enemy_waves = 2
		"disable_10s":
			for t in towers:
				t["is_disabled"] = true
				t["disable_timer"] = 10.0
		"core_max_-30":
			core_max_hp -= 30
			core_hp = minf(core_hp, core_max_hp)
		"halve_sins":
			@warning_ignore("integer_division")
			sins = sins / 2

	notify(Locale.tf("pact_accepted_notify", {"name": Locale.t(pact["name"])}), Color(0.8, 0.267, 1.0))
	Audio.play_sfx("pact_accept")
	show_pact = false
	between_wave_timer = Config.BETWEEN_WAVE_DELAY

func decline_pact() -> void:
	show_pact = false
	between_wave_timer = Config.BETWEEN_WAVE_DELAY
	notify(Locale.t("No deal."), Color(0.533, 0.533, 0.533))

# ═══════════════════════════════════════════════════════
# EFFECTS & NOTIFICATIONS
# ═══════════════════════════════════════════════════════
func add_effect(type: String, ex: float, ey: float, radius: float = 10.0, color: Color = Color.WHITE) -> void:
	var duration := 0.5
	if type == "hit_spark":
		duration = 0.2
	elif type == "soul_hit":
		duration = 0.32
	elif type == "lucifer_wave":
		duration = 1.2
	elif type == "lucifer_hit":
		duration = 0.4
	elif type == "hades_wave":
		duration = 0.6
	effects.append({"type": type, "x": ex, "y": ey, "radius": radius, "color": color, "timer": duration})

func add_dmg_number(ex: float, ey: float, dmg: float, color: Color) -> void:
	effects.append({"type": "dmg_number", "x": ex, "y": ey, "radius": 0, "color": color, "timer": 0.6, "value": dmg})

func notify(text: String, color: Color = Color.WHITE) -> void:
	notifications.append({"text": text, "color": color, "timer": 4.0})
	if notifications.size() > 6:
		notifications.pop_front()
	notification_added.emit(text, color)

func update_effects(dt: float) -> void:
	var i := effects.size() - 1
	while i >= 0:
		var e: Dictionary = effects[i]
		# Effects with a delay wait in a "pending" state — timer/draw/particle
		# spawn all stay frozen until the delay elapses (e.g. Lucifer's wave
		# ring reaching a far enemy).
		if e.get("delay", 0.0) > 0.0:
			e["delay"] -= dt
		else:
			e["timer"] -= dt
			if e["timer"] <= 0:
				effects.remove_at(i)
		i -= 1

	i = notifications.size() - 1
	while i >= 0:
		notifications[i]["timer"] -= dt
		if notifications[i]["timer"] <= 0:
			notifications.remove_at(i)
		i -= 1

	if show_dice_result:
		dice_result_timer -= dt
		if dice_result_timer <= 0:
			show_dice_result = false

	if wave_banner_timer > 0.0:
		wave_banner_timer -= dt
		if wave_banner_timer < 0.0:
			wave_banner_timer = 0.0

	if speed_buff_timer > 0:
		speed_buff_timer -= dt
		if speed_buff_timer <= 0:
			temp_speed_buff = 1.0
			speed_buff_factor = 1.0

	if screen_shake > 0:
		screen_shake -= dt
		if screen_shake <= 0:
			screen_shake_intensity = 0.0

func shake(intensity: float, duration: float) -> void:
	screen_shake = duration
	screen_shake_intensity = intensity

func _apply_speed_buff(factor: float, duration: float) -> void:
	temp_speed_buff = factor
	speed_buff_factor = factor
	speed_buff_timer = duration

# ═══════════════════════════════════════════════════════
# UTILITY
# ═══════════════════════════════════════════════════════
func _weighted_pick(table: Array) -> Dictionary:
	var total_weight := 0.0
	for item in table:
		total_weight += item["weight"]
	var roll := randf() * total_weight
	for item in table:
		roll -= item["weight"]
		if roll <= 0:
			return item
	return table[table.size() - 1]
