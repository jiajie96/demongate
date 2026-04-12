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
var fast_enemy_waves: int = 0

var fallen_hero_pool: int = 0
var fallen_heroes_spawned: int = 0

var stats: Dictionary = {"enemies_killed": 0, "towers_placed": 0}
var occupied_tiles: Dictionary = {}
var notifications: Array = []
var game_time: float = 0.0
var show_overview: bool = false
var speed_buff_timer: float = 0.0
var speed_buff_factor: float = 1.0  # what was multiplied, divide to undo
var game_speed: float = 1.0
var pending_aoe_timer: float = 0.0

var _next_id: int = 0

# ═══════════════════════════════════════════════════════
# RESET
# ═══════════════════════════════════════════════════════
func reset_state() -> void:
	phase = "playing"
	paused = false
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
	fast_enemy_waves = 0
	fallen_hero_pool = 0
	fallen_heroes_spawned = 0
	stats = {"enemies_killed": 0, "towers_placed": 0}
	occupied_tiles.clear()
	notifications.clear()
	game_time = 0.0
	speed_buff_timer = 0.0
	speed_buff_factor = 1.0
	game_speed = 1.0
	Engine.time_scale = 1.0
	pending_aoe_timer = 0.0
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

func earn_from_kill(enemy_type: String, was_aoe: bool) -> void:
	var data: Dictionary = Config.ENEMY_DATA.get(enemy_type, {})
	if data.is_empty():
		return
	earn(data["sin_reward"])
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
		"targeting_mode": "first",
	}
	if tower["is_support"]:
		tower["buff_timer"] = tower["buff_cooldown"]
	return tower

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
	var w := maxf(0, wave - Config.SCALE_START_WAVE)
	var scaled_hp: float = data["hp"] * (1.0 + w * Config.WAVE_HP_SCALE)
	var scaled_speed: float = data["speed"] * (1.0 + w * Config.WAVE_SPD_SCALE)
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
		"ability_timer": 0.0,
	}

func _has_alive_type(etype: String) -> bool:
	for e in enemies:
		if e["alive"] and e["type"] == etype:
			return true
	return false

func _is_guardian_protected(enemy: Dictionary) -> bool:
	if enemy["type"] == "divine_guardian":
		return false
	if not _has_alive_type("divine_guardian"):
		return false
	return enemy.get("path_index", 0) < Config.path_pixels.size() / 2

func _michael_shield(michael: Dictionary) -> void:
	# Every 8 seconds, grant all enemies 50% damage reduction for 2 seconds
	michael["ability_timer"] = 8.0
	for e in enemies:
		if e["alive"] and e["type"] != "michael":
			e["shield_buff"] = true
			e["shield_buff_timer"] = 2.0
	add_effect("screen_flash", 0, 0, 0, Color(1.0, 0.95, 0.7, 0.12))
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
	if count > 0:
		add_effect("aoe", zx, zy, 60.0, Color(0.7, 0.8, 1.0, 0.3))
		Audio.play_sfx("core_hit")

func update_enemies(dt: float) -> void:
	var path_px: Array[Vector2] = Config.path_pixels
	var has_commander := _has_alive_type("archangel")

	# Process Michael and Zeus abilities
	for e in enemies:
		if not e["alive"]:
			continue
		if e["type"] == "michael" or e["type"] == "zeus":
			e["ability_timer"] -= dt
			if e["ability_timer"] <= 0:
				if e["type"] == "michael":
					_michael_shield(e)
				elif e["type"] == "zeus":
					_zeus_lightning(e)

	var i := enemies.size() - 1
	while i >= 0:
		var e: Dictionary = enemies[i]
		if not e["alive"]:
			enemies.remove_at(i)
			i -= 1
			continue

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

		# Movement
		var spd: float = e["speed"]
		if e["slow_amount"] > 0:
			spd *= (1.0 - e["slow_amount"])
		if fast_enemy_waves > 0:
			spd *= 1.3
		# Archangel Commander aura: +25% speed to allies
		if has_commander and e["type"] != "archangel":
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
			if core_hp <= 0:
				phase = "gameover"
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
	var dmg_mult := 1.0
	if double_damage > 0:
		dmg_mult = 2.0
	return {
		"x": tower["x"],
		"y": tower["y"],
		"target": target,
		"target_last_x": target["x"],
		"target_last_y": target["y"],
		"damage": tower["damage"] * tower["damage_mult"] * dmg_mult,
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
const TARGETING_MODES := ["first", "last", "closest", "strongest"]

func cycle_targeting(tower: Dictionary) -> void:
	var idx := TARGETING_MODES.find(tower.get("targeting_mode", "first"))
	tower["targeting_mode"] = TARGETING_MODES[(idx + 1) % TARGETING_MODES.size()]

func find_target(tower: Dictionary):
	var mode: String = tower.get("targeting_mode", "first")
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
			"first":
				if e["path_index"] > best_val:
					best_val = e["path_index"]
					best = e
			"last":
				if best == null or e["path_index"] < best_val:
					best_val = e["path_index"]
					best = e
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
	if _has_alive_type("archangel") and enemy.get("type", "") != "archangel":
		dmg *= 0.75
	# Michael aura: while shield_buff active, 30% damage reduction (already applied via shield_buff flag)
	return maxf(1.0, dmg)

func combat_hit(enemy: Dictionary, base_dmg: float, tower) -> void:
	if not enemy.get("alive", false):
		return
	# Divine Guardian protection: enemies in first half of path are invulnerable
	if _is_guardian_protected(enemy):
		enemy["flash_timer"] = 0.05
		return
	var dmg := calc_damage(base_dmg, tower, enemy)
	enemy["hp"] -= dmg
	enemy["flash_timer"] = 0.12

	# Track damage for overview
	if tower != null and tower is Dictionary:
		tower["total_damage"] = tower.get("total_damage", 0.0) + dmg

	# Hit spark + floating damage number
	var spark_col := Color(1, 0.7, 0.3)
	if tower != null and tower is Dictionary:
		spark_col = tower.get("color", spark_col)
	add_effect("hit_spark", enemy["x"], enemy["y"], 6.0, spark_col)
	# Offset damage numbers slightly randomly so they don't stack
	var nx: float = enemy["x"] + (fmod(dmg * 7.3, 16.0) - 8.0)
	add_dmg_number(nx, enemy["y"] - enemy.get("radius", 8.0) - 4, dmg, spark_col)

	# Apply slow from Necromancer
	if tower != null and tower is Dictionary and tower.get("slow_power", 0.0) > 0:
		enemy["slow_amount"] = tower["slow_power"]
		enemy["slow_timer"] = 2.0

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

		if t["is_disabled"]:
			t["disable_timer"] -= dt
			if t["disable_timer"] <= 0:
				t["is_disabled"] = false
			continue

		# Hades support tower: buff nearby towers periodically
		if t["is_support"]:
			t["buff_timer"] -= dt
			if t["buff_active_timer"] > 0:
				t["buff_active_timer"] -= dt
			if t["buff_timer"] <= 0:
				t["buff_timer"] = t["buff_cooldown"]
				t["buff_active_timer"] = t["buff_duration"]
				_apply_hades_buff(t)
				Audio.play_sfx("hades_buff", -18.0)
			continue

		# Lucifer global pulse: damage ALL enemies
		if t["is_global"]:
			var effective_speed: float = t["attack_speed"] * perm_speed_buff
			if t["hades_buffed"]:
				effective_speed *= t.get("buff_multiplier", 1.5)
			t["cooldown"] -= dt
			if t["cooldown"] > 0:
				continue
			if enemies.size() == 0:
				continue
			t["cooldown"] = 1.0 / effective_speed
			_lucifer_pulse(t)
			continue

		var effective_speed: float = t["attack_speed"] * perm_speed_buff
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
		t["fire_flash"] = 0.15
		projectiles.append(create_projectile(t, target))
		Audio.play_shoot(t["type"])

func _lucifer_pulse(tower: Dictionary) -> void:
	var dmg_mult := 1.0
	if double_damage > 0:
		dmg_mult = 2.0
	var base_dmg: float = tower["damage"] * tower["damage_mult"] * dmg_mult
	for e in enemies:
		if e["alive"]:
			combat_hit(e, base_dmg, tower)
	add_effect("lucifer_wave", tower["x"], tower["y"], 0, tower["color"])
	Audio.play_sfx("lucifer_pulse", -6.0)

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

# ═══════════════════════════════════════════════════════
# WAVE MANAGER
# ═══════════════════════════════════════════════════════
func start_wave() -> void:
	wave += 1
	if wave > Config.MAX_WAVES:
		phase = "victory"
		return
	wave_active = true
	var wave_def: Dictionary = Config.WAVE_DATA[wave - 1]
	wave_desc = wave_def["desc"]

	spawn_queue.clear()
	for entry in wave_def["enemies"]:
		for j in range(entry["count"]):
			spawn_queue.append(entry["type"])
	spawn_timer = 0.5

	notify(Locale.tf("wave_start_notify", {"wave": wave, "desc": Locale.t(wave_desc)}), Color(1.0, 0.8, 0.0))
	Audio.play_sfx("wave_start")

func update_waves(dt: float) -> void:
	if wave_active:
		spawn_timer -= dt
		if spawn_timer <= 0 and spawn_queue.size() > 0:
			var etype: String = spawn_queue.pop_front()
			enemies.append(create_enemy(etype))
			var wave_def: Dictionary = Config.WAVE_DATA[wave - 1]
			spawn_timer = wave_def["interval"]

		# Deferred pact AoE: fires 2s into the wave
		if pending_aoe_timer > 0:
			pending_aoe_timer -= dt
			if pending_aoe_timer <= 0:
				for e in enemies:
					if e["alive"]:
						e["hp"] -= e["max_hp"] * 0.5
						e["flash_timer"] = 0.3
						if e["hp"] <= 0:
							e["alive"] = false
							stats["enemies_killed"] += 1
				add_effect("screen_flash", 0, 0, 0, Color(1.0, 0.2, 0.0))
				notify(Locale.t("Hellfire Rain strikes!"), Color(1.0, 0.4, 0.0))

		if spawn_queue.size() == 0 and enemies.size() == 0:
			complete_wave()
	else:
		if phase == "playing" and not show_pact:
			between_wave_timer -= dt
			if between_wave_timer <= 0:
				start_wave()

func complete_wave() -> void:
	wave_active = false
	var wave_bonus: int = 30 + wave * 2
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

	var msg_color := Color(0.267, 1.0, 0.267) if outcome["positive"] else Color(1.0, 0.267, 0.267)
	notify(Locale.t(outcome["name"]) + " (" + str(d1) + ")", msg_color)

	match outcome["effect"]:
		"kill_all":
			for e in enemies:
				if e["alive"]:
					e["hp"] = 0
					e["alive"] = false
					earn_from_kill(e["type"], true)
					stats["enemies_killed"] += 1
			add_effect("screen_flash", 0, 0, 0, Color(1.0, 0.267, 0.0))
		"triple_speed":
			_apply_speed_buff(3.0, 20.0)
		"aoe_30":
			for e in enemies:
				if e["alive"]:
					var dmg: float = e["max_hp"] * 0.3
					e["hp"] -= dmg
					e["flash_timer"] = 0.2
					if e["hp"] <= 0:
						e["alive"] = false
						stats["enemies_killed"] += 1
						earn_from_kill(e["type"], true)
			add_effect("screen_flash", 0, 0, 0, Color(1.0, 0.4, 0.0))
		"aoe_15":
			for e in enemies:
				if e["alive"]:
					var dmg: float = e["max_hp"] * 0.15
					e["hp"] -= dmg
					e["flash_timer"] = 0.15
					if e["hp"] <= 0:
						e["alive"] = false
						stats["enemies_killed"] += 1
						earn_from_kill(e["type"], true)
			add_effect("screen_flash", 0, 0, 0, Color(1.0, 0.6, 0.2))
		"speed_boost":
			_apply_speed_buff(1.5, 10.0)
		"bonus_sins":
			earn(30)
		"slow_towers":
			_apply_speed_buff(0.7, 10.0)
		"disable_3s":
			for t in towers:
				t["is_disabled"] = true
				t["disable_timer"] = 3.0
		"tax_sins":
			var lost: int = roundi(sins * 0.15)
			sins -= lost

	return dice_result

# ═══════════════════════════════════════════════════════
# GAMBLING — RELICS
# ═══════════════════════════════════════════════════════
func should_drop_relic(enemy_type: String) -> bool:
	var roll := randf()
	if enemy_type == "paladin":
		return true
	if enemy_type == "god_of_war":
		return roll < 0.15
	if enemy_type == "holy_knight" or enemy_type == "monk":
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
			enemies.append(create_enemy("god_of_war"))
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
		"free_towers_3":
			free_towers = 3
		"triple_sins_1":
			sin_multiplier = 3.0
			sin_mult_waves = 1
		"massive_aoe":
			pending_aoe_timer = 2.0
			notify(Locale.t("Hellfire Rain will strike when enemies appear!"), Color(1.0, 0.4, 0.0))
		"speed_50_perm":
			perm_speed_buff += 0.5
		"double_earn_5":
			sin_multiplier = 2.0
			sin_mult_waves = 5

	match pact["c_effect"]:
		"core_-20":
			core_hp = maxf(0, core_hp - 20)
			if core_hp <= 0:
				phase = "gameover"
		"fast_enemy_2":
			fast_enemy_waves = 2
		"disable_10s":
			for t in towers:
				t["is_disabled"] = true
				t["disable_timer"] = 10.0
		"core_max_-25":
			core_max_hp -= 25
			core_hp = minf(core_hp, core_max_hp)
		"halve_sins":
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
	elif type == "lucifer_wave":
		duration = 0.8
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
		effects[i]["timer"] -= dt
		if effects[i]["timer"] <= 0:
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

	if speed_buff_timer > 0:
		speed_buff_timer -= dt
		if speed_buff_timer <= 0:
			perm_speed_buff /= speed_buff_factor
			speed_buff_factor = 1.0

func _apply_speed_buff(factor: float, duration: float) -> void:
	# Undo any existing temp buff first
	if speed_buff_timer > 0:
		perm_speed_buff /= speed_buff_factor
	perm_speed_buff *= factor
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
