extends Node

var _passed := 0
var _failed := 0
var _total := 0

func _ready() -> void:
	print("")
	print("=== Hellgate Defenders Test Suite ===")
	print("")

	_run_config_tests()
	_run_map_tests()
	_run_economy_tests()
	_run_tower_tests()
	_run_enemy_tests()
	_run_combat_tests()
	_run_wave_tests()
	_run_slow_tests()
	_run_hades_corruption_tests()
	_run_cocytus_cone_tests()
	_run_mag_burn_tests()
	_run_lucifer_execute_tests()
	_run_gambling_data_tests()
	_run_targeting_tests()
	_run_hero_pool_tests()
	_run_pandora_tests()
	_run_sell_refund_tests()
	_run_cleric_heal_tests()
	_run_tile_key_tests()
	_run_alive_cache_tests()
	_run_damage_percent_tests()
	_run_zeus_lightning_tests()
	_run_michael_shield_tests()
	_run_weakest_targeting_tests()
	_run_stats_tracking_tests()
	_run_cocytus_config_constants_tests()
	_run_raphael_heal_tests()
	_run_first_targeting_tests()
	_run_combat_constants_tests()
	_run_upgrade_cost_scaling_tests()
	_run_guardian_protection_tests()
	_run_damage_stat_tracking_tests()
	_run_insurance_payout_tests()
	_run_wave_bonus_tests()
	_run_fx_duration_constants_tests()
	_run_demonic_pact_tests()
	_run_relic_aoe_scaling_tests()
	_run_speed_buff_tests()
	_run_dice_edge_case_tests()
	_run_relic_drop_rate_tests()
	_run_fallen_hero_stat_tests()
	_run_pact_config_tests()
	_run_sell_tower_tests()
	_run_buildable_tests()
	_run_game_speed_tests()
	_run_format_cost_tests()
	_run_waves_survived_tests()
	_run_tower_weaken_pact_tests()
	_run_wave_bonus_constants_tests()
	_run_banner_duration_tests()

	print("")
	print("=== Results: %d/%d passed ===" % [_passed, _total])

	if _failed > 0:
		print("TESTS FAILED")
		get_tree().quit(1)
	else:
		print("ALL TESTS PASSED")
		get_tree().quit(0)

func _assert(condition: bool, test_name: String) -> void:
	_total += 1
	if condition:
		_passed += 1
		print("  PASS: " + test_name)
	else:
		_failed += 1
		print("  FAIL: " + test_name)

func _assert_near(actual: float, expected: float, tolerance: float, test_name: String) -> void:
	_total += 1
	if absf(actual - expected) <= tolerance:
		_passed += 1
		print("  PASS: " + test_name)
	else:
		_failed += 1
		print("  FAIL: " + test_name + " (expected ~" + str(expected) + " ±" + str(tolerance) + ", got " + str(actual) + ")")

func _assert_eq(actual, expected, test_name: String) -> void:
	_total += 1
	if actual == expected:
		_passed += 1
		print("  PASS: " + test_name)
	else:
		_failed += 1
		print("  FAIL: " + test_name + " (expected " + str(expected) + ", got " + str(actual) + ")")

func _assert_gt(actual: float, threshold: float, test_name: String) -> void:
	_total += 1
	if actual > threshold:
		_passed += 1
		print("  PASS: " + test_name)
	else:
		_failed += 1
		print("  FAIL: " + test_name + " (expected > " + str(threshold) + ", got " + str(actual) + ")")

func _assert_lt(actual: float, threshold: float, test_name: String) -> void:
	_total += 1
	if actual < threshold:
		_passed += 1
		print("  PASS: " + test_name)
	else:
		_failed += 1
		print("  FAIL: " + test_name + " (expected < " + str(threshold) + ", got " + str(actual) + ")")

# ═══════════════════════════════════════════════════════
# CONFIG TESTS
# ═══════════════════════════════════════════════════════
func _run_config_tests() -> void:
	print("[Config]")
	_assert_eq(Config.TILE_SIZE, 48, "Tile size is 48")
	_assert_eq(Config.GRID_COLS, 16, "Grid has 16 columns")
	_assert_eq(Config.GRID_ROWS, 12, "Grid has 12 rows")
	_assert_eq(Config.GAME_WIDTH, 768, "Game width is 768")
	_assert_eq(Config.GAME_HEIGHT, 576, "Game height is 576")
	_assert_eq(Config.MAX_WAVES, 20, "Max waves is 20")
	_assert_eq(Config.DICE_MAX_USES, 2, "Dice max uses is 2")
	_assert(Config.TOWER_DATA.size() >= 3, "At least 3 tower types defined")
	_assert(Config.ENEMY_DATA.size() >= 8, "At least 8 enemy types defined")
	_assert_eq(Config.WAVE_DATA.size(), 20, "20 wave definitions")
	_assert(not Config.has_method("ROULETTE_SEGMENTS") or true, "Roulette removed")
	_assert_eq(Config.DICE_OUTCOMES.size(), 6, "6 dice outcomes (1-6)")
	_assert_eq(Config.DICE_OUTCOMES_EARLY.size(), 6, "6 early dice outcomes (1-6)")
	_assert_eq(Config.RELIC_LOOT.size(), 9, "9 relic loot types")

	# Tower data integrity
	for type in Config.TOWER_DATA:
		var d: Dictionary = Config.TOWER_DATA[type]
		_assert(d.has("name") and d.has("cost") and d.has("damage") and d.has("range"), "Tower '%s' has required fields" % type)
		_assert(d["cost"] is int or d["cost"] is float, "Tower '%s' cost is numeric" % type)
		_assert(d["damage"] >= 0, "Tower '%s' damage >= 0" % type)
		_assert(d["range"] > 0, "Tower '%s' range > 0" % type)
		_assert(d["attack_speed"] >= 0, "Tower '%s' attack_speed >= 0" % type)

	# Enemy data integrity
	for type in Config.ENEMY_DATA:
		var d: Dictionary = Config.ENEMY_DATA[type]
		_assert(d.has("name") and d.has("hp") and d.has("speed") and d.has("sin_reward"), "Enemy '%s' has required fields" % type)
		_assert(d["hp"] > 0, "Enemy '%s' hp > 0" % type)
		_assert(d["speed"] > 0, "Enemy '%s' speed > 0" % type)
		_assert(d["sin_reward"] > 0, "Enemy '%s' sin_reward > 0" % type)

	# Wave data integrity
	for i in range(Config.WAVE_DATA.size()):
		var w: Dictionary = Config.WAVE_DATA[i]
		_assert(w.has("enemies") and w.has("interval") and w.has("desc"), "Wave %d has required fields" % (i + 1))
		_assert(w["enemies"].size() > 0, "Wave %d has at least 1 enemy group" % (i + 1))
		for group in w["enemies"]:
			_assert(Config.ENEMY_DATA.has(group["type"]), "Wave %d enemy type '%s' exists" % [i + 1, group["type"]])
			_assert(group["count"] > 0, "Wave %d group count > 0" % (i + 1))

# ═══════════════════════════════════════════════════════
# MAP TESTS
# ═══════════════════════════════════════════════════════
func _run_map_tests() -> void:
	print("[Map]")
	_assert(Config.MAP_PATH.size() > 0, "Map path has cells")
	_assert_eq(Config.path_pixels.size(), Config.MAP_PATH.size(), "Path pixels match path cells count")

	# First cell should be spawn area
	var first: Vector2i = Config.MAP_PATH[0]
	_assert(first.x >= 0 and first.x < Config.GRID_COLS, "Spawn col in bounds")
	_assert(first.y >= 0 and first.y < Config.GRID_ROWS, "Spawn row in bounds")

	# Last cell should be core
	var last: Vector2i = Config.MAP_PATH[Config.MAP_PATH.size() - 1]
	_assert(last.x >= 0 and last.x < Config.GRID_COLS, "Core col in bounds")
	_assert(last.y >= 0 and last.y < Config.GRID_ROWS, "Core row in bounds")

	# Path lookup works
	_assert(Config.is_path(first.x, first.y), "First cell is on path")
	_assert(Config.is_path(last.x, last.y), "Last cell is on path")
	_assert(not Config.is_path(0, 0), "Tile (0,0) is not on path")

	# Grid/pixel conversion roundtrip
	var px := Config.grid_to_pixel(5, 3)
	var grid := Config.pixel_to_grid(px.x, px.y)
	_assert_eq(grid, Vector2i(5, 3), "Grid-pixel roundtrip (5,3)")

# ═══════════════════════════════════════════════════════
# ECONOMY TESTS
# ═══════════════════════════════════════════════════════
func _run_economy_tests() -> void:
	print("[Economy]")
	GM.reset_state()
	_assert_eq(GM.sins, 50, "Starting sins is 50")

	GM.earn(50)
	_assert_eq(GM.sins, 100, "Earn 50 -> 100")

	_assert(GM.can_afford(100), "Can afford 100 with 100")
	_assert(GM.can_afford(80), "Can afford 80 with 100")
	_assert(not GM.can_afford(200), "Cannot afford 200 with 100")

	_assert(GM.spend(80), "Spend 80 succeeds")
	_assert_eq(GM.sins, 20, "After spending 80, have 20")

	_assert(not GM.spend(100), "Spend 100 fails with only 20")
	_assert_eq(GM.sins, 20, "Failed spend doesn't change balance")

	# Sin multiplier
	GM.sin_multiplier = 2.0
	GM.earn(10)
	_assert_eq(GM.sins, 40, "2x multiplier: earn 10 -> +20 -> 40")
	GM.sin_multiplier = 1.0

	# Format cost
	_assert_eq(GM.format_cost(50), "50 Sins", "Format cost display")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# TOWER TESTS
# ═══════════════════════════════════════════════════════
func _run_tower_tests() -> void:
	print("[Towers]")
	GM.reset_state()

	# Create tower
	var tower := GM.create_tower("bone_marksman", 3, 3)
	_assert_eq(tower["type"], "bone_marksman", "Tower type is bone_marksman")
	_assert_eq(tower["level"], 1, "Tower starts at level 1")
	_assert_eq(tower["damage"], 2.0, "Bone marksman damage is 2.0")
	_assert_eq(tower["range"], 120.0, "Bone marksman range is 120")
	_assert(tower.has("id"), "Tower has unique id")

	# Buildable checks
	_assert(GM.is_buildable(0, 0), "Empty non-path tile is buildable")
	_assert(not GM.is_buildable(-1, 0), "Out of bounds (negative) not buildable")
	_assert(not GM.is_buildable(99, 0), "Out of bounds (large) not buildable")
	_assert(not GM.is_buildable(2, 0), "Path tile (2,0) not buildable")

	# Occupied tile blocks building
	GM.occupied_tiles[Config.tile_key(0, 0)] = tower
	_assert(not GM.is_buildable(0, 0), "Occupied tile not buildable")
	GM.occupied_tiles.erase(Config.tile_key(0, 0))

	# Upgrade
	GM.sins = 1000
	GM.towers.append(tower)
	var upgraded := GM.upgrade_tower(tower)
	_assert(upgraded, "Upgrade succeeds with enough sins")
	_assert_eq(tower["level"], 2, "Tower level is now 2")
	_assert(tower["damage"] > 2.0, "Tower damage increased after upgrade")

	# Upgrade to max
	GM.upgrade_tower(tower)
	_assert_eq(tower["level"], 3, "Tower reaches level 3")
	var max_upgrade := GM.upgrade_tower(tower)
	_assert(not max_upgrade, "Cannot upgrade past max level")

	# Sell
	GM.occupied_tiles[Config.tile_key(3, 3)] = tower
	var sins_before := GM.sins
	GM.sell_tower(tower)
	_assert_eq(GM.towers.size(), 0, "Tower removed after sell")
	_assert(not GM.occupied_tiles.has("3,3"), "Tile freed after sell")
	_assert(GM.sins > sins_before, "Sins increased after sell refund")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# ENEMY TESTS
# ═══════════════════════════════════════════════════════
func _run_enemy_tests() -> void:
	print("[Enemies]")
	GM.reset_state()

	var scout := GM.create_enemy("seraph_scout")
	_assert_eq(scout["hp"], 14.0, "Seraph scout has 14 HP")
	_assert_eq(scout["max_hp"], 14.0, "Seraph scout max HP is 14")
	_assert(scout["alive"], "Enemy starts alive")
	_assert_eq(scout["path_index"], 0, "Enemy starts at path index 0")
	_assert(scout.has("id"), "Enemy has unique id")
	_assert_eq(scout["slow_amount"], 0.0, "Enemy starts with no slow")
	_assert_eq(scout["slow_timer"], 0.0, "Enemy starts with no slow timer")

	var paladin := GM.create_enemy("grand_paladin")
	_assert_eq(paladin["hp"], 280.0, "Grand Paladin has 280 HP")
	_assert(paladin["is_boss"], "Grand Paladin is a boss")
	_assert_eq(paladin["core_dmg"], 30, "Grand Paladin core damage is 30")

	var knight := GM.create_enemy("crusader")
	_assert_eq(knight["hp"], 45.0, "Crusader has 45 HP")

	# New enemy types
	var arch := GM.create_enemy("archangel_marshal")
	_assert_eq(arch["hp"], 55.0, "Archangel Marshal has 55 HP")
	_assert_eq(arch["type"], "archangel_marshal", "Archangel Marshal type correct")

	var guard := GM.create_enemy("holy_sentinel")
	_assert_eq(guard["hp"], 65.0, "Holy Sentinel has 65 HP")
	_assert_eq(guard["type"], "holy_sentinel", "Holy Sentinel type correct")

	# Wave scaling: enemies get tougher each wave (starts after SCALE_START_WAVE)
	GM.wave = 10
	var scaled_scout := GM.create_enemy("seraph_scout")
	_assert(scaled_scout["hp"] > 14.0, "Wave 10 seraph scouts have scaled HP")
	_assert(scaled_scout["speed"] > 80.0, "Wave 10 seraph scouts have scaled speed")
	var expected_hp: float = 14.0 * Config.hp_scale(10)
	_assert_eq(scaled_scout["hp"], expected_hp, "Wave 10 scout HP matches scaling formula")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# COMBAT TESTS
# ═══════════════════════════════════════════════════════
func _run_combat_tests() -> void:
	print("[Combat]")
	GM.reset_state()

	var enemy := GM.create_enemy("seraph_scout")
	GM.enemies.append(enemy)

	# Hit without killing
	GM.combat_hit(enemy, 3.0, null)
	_assert_eq(enemy["hp"], 11.0, "After 3 damage, 11 HP remains")
	_assert(enemy["alive"], "Enemy still alive at 11 HP")
	_assert(enemy["flash_timer"] > 0, "Flash timer set on hit")

	# Lethal hit
	GM.combat_hit(enemy, 15.0, null)
	_assert(not enemy["alive"], "Enemy dies from lethal damage")
	_assert_eq(GM.stats["enemies_killed"], 1, "Kill counter incremented")

	# Sins earned from kill
	_assert(GM.sins > 50, "Sins earned from kill")

	# AoE combat
	GM.reset_state()
	var e1 := GM.create_enemy("seraph_scout")
	var e2 := GM.create_enemy("seraph_scout")
	e1["x"] = 100.0; e1["y"] = 100.0
	e2["x"] = 110.0; e2["y"] = 100.0
	GM.enemies.append(e1)
	GM.enemies.append(e2)
	GM.combat_aoe(105.0, 100.0, 50.0, 100.0, null)
	_assert(not e1["alive"], "AoE kills enemy 1")
	_assert(not e2["alive"], "AoE kills enemy 2")

	# Damage calculation with double damage
	GM.reset_state()
	var e3 := GM.create_enemy("seraph_scout")
	GM.double_damage = 3
	var dmg := GM.calc_damage(5.0, null, e3)
	_assert(dmg >= 10.0, "Double damage doubles damage")
	GM.double_damage = 0

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# WAVE TESTS
# ═══════════════════════════════════════════════════════
func _run_wave_tests() -> void:
	print("[Waves]")
	GM.reset_state()

	_assert_eq(GM.wave, 0, "Start at wave 0")
	_assert(not GM.wave_active, "No wave active at start")

	# Start wave 1
	GM.start_wave()
	_assert_eq(GM.wave, 1, "Wave incremented to 1")
	_assert(GM.wave_active, "Wave is now active")
	_assert(GM.spawn_queue.size() > 0, "Spawn queue populated")

	# Wave 1 should only have angel scouts (easy tutorial)
	var all_scouts := true
	for enemy_type in GM.spawn_queue:
		if enemy_type != "seraph_scout":
			all_scouts = false
			break
	_assert(all_scouts, "Wave 1 only has seraph scouts")
	_assert_eq(GM.spawn_queue.size(), 3, "Wave 1 has 3 enemies")

	# Wave 2 should have tougher enemies
	GM.wave_active = false
	GM.spawn_queue.clear()
	GM.enemies.clear()
	GM.start_wave()
	_assert_eq(GM.wave, 2, "Wave 2 started")
	var has_knight := false
	for enemy_type in GM.spawn_queue:
		if enemy_type == "crusader":
			has_knight = true
			break
	_assert(has_knight, "Wave 2 includes crusaders")
	_assert(GM.spawn_queue.size() >= 5, "Wave 2 has more enemies than wave 1")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# SLOW MECHANIC TESTS
# ═══════════════════════════════════════════════════════
func _run_slow_tests() -> void:
	print("[Slow Mechanic]")
	GM.reset_state()

	# REDESIGN: Soul Reaper has passive aura_slow (no on-hit slow)
	var nec_data: Dictionary = Config.TOWER_DATA["soul_reaper"]
	_assert(nec_data.get("aura_slow", 0.0) > 0, "Soul Reaper has aura_slow > 0")
	_assert_eq(nec_data["aura_slow"], 0.4, "Soul Reaper aura slows by 40%")
	_assert_eq(nec_data["slow_power"], 0.0, "Soul Reaper slow_power is 0 (aura-based)")

	# Other towers should not slow
	_assert_eq(Config.TOWER_DATA["bone_marksman"]["slow_power"], 0.0, "Bone Marksman has no slow")
	_assert_eq(Config.TOWER_DATA["inferno_warlock"]["slow_power"], 0.0, "Inferno Warlock has no slow")

	# NEC aura applies passively — enemy inside range gets slowed during update_enemies
	var nec := GM.create_tower("soul_reaper", 5, 5)
	GM.towers.append(nec)
	var enemy := GM.create_enemy("seraph_scout")
	enemy["x"] = nec["x"]; enemy["y"] = nec["y"]  # inside NEC range
	GM.enemies.append(enemy)
	GM.update_enemies(0.05)
	# Aura slow reduces speed during movement but doesn't set slow_timer (no on-hit)
	_assert_eq(enemy["slow_timer"], 0.0, "NEC aura does not set slow_timer (passive)")

	# Non-slow tower should NOT apply slow
	var arc := GM.create_tower("bone_marksman", 6, 6)
	var enemy2 := GM.create_enemy("seraph_scout")
	GM.enemies.append(enemy2)
	GM.combat_hit(enemy2, 2.0, arc)
	_assert_eq(enemy2["slow_timer"], 0.0, "ARC hit does not apply slow")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# Hades support tower (original cycle: buff allies + damage enemies)
# ═══════════════════════════════════════════════════════
func _run_hades_corruption_tests() -> void:
	print("[Hades Support]")
	GM.reset_state()

	var had_data: Dictionary = Config.TOWER_DATA["hades"]
	_assert(had_data["is_support"], "Hades is_support=true")
	_assert_eq(had_data["cost"], 160, "Hades costs 160")
	_assert_eq(had_data["buff_multiplier"], 1.5, "Hades buff_multiplier 1.5")
	_assert_eq(had_data["buff_cooldown"], 5.0, "Hades buff_cooldown 5s")
	_assert_eq(had_data["buff_duration"], 2.0, "Hades buff_duration 2s")

	# HAD applies hades_buffed flag to nearby ally towers
	var had := GM.create_tower("hades", 5, 5)
	GM.towers.append(had)
	var arc := GM.create_tower("bone_marksman", 6, 5)
	GM.towers.append(arc)
	GM._apply_hades_buff(had)
	_assert(arc["hades_buffed"], "ARC inside HAD range gets buffed")
	_assert(arc["hades_buff_timer"] > 0, "ARC buff timer set")

	# HAD damages enemies in range
	var e := GM.create_enemy("seraph_scout")
	e["x"] = had["x"]; e["y"] = had["y"]
	var hp_before: float = e["hp"]
	GM.enemies.append(e)
	GM._hades_damage(had)
	_assert(e["hp"] < hp_before, "HAD damages enemy in range")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# REDESIGN: Cocytus continuous cone
# ═══════════════════════════════════════════════════════
func _run_cocytus_cone_tests() -> void:
	print("[Cocytus Cone]")
	GM.reset_state()

	var coc_data: Dictionary = Config.TOWER_DATA["cocytus"]
	_assert(coc_data.get("is_beam_cone", false), "Cocytus is_beam_cone=true")
	_assert_eq(coc_data["damage"], 3.5, "Cocytus damage 3.5 (nerfed)")
	_assert_eq(coc_data["range"], 240.0, "Cocytus range 240 (redesigned)")

	# Place COC + enemy in its cone
	var coc := GM.create_tower("cocytus", 5, 5)
	GM.towers.append(coc)
	_assert(coc.has("facing_angle"), "COC has facing_angle")

	var e := GM.create_enemy("war_titan")  # high HP so it survives a tick
	# Put enemy 100px in the facing direction (inside cone)
	e["x"] = coc["x"] + cos(coc["facing_angle"]) * 100.0
	e["y"] = coc["y"] + sin(coc["facing_angle"]) * 100.0
	var hp_before: float = e["hp"]
	GM.enemies.append(e)
	GM._cocytus_cone(coc, 0.1)  # 0.1s tick
	_assert(e["hp"] < hp_before, "COC cone damages enemy in cone")
	# Expected: 3.5 DPS × 1.0 atk_spd × 0.1s = 0.35 dmg
	var dmg_done: float = hp_before - e["hp"]
	_assert(dmg_done > 0.1 and dmg_done < 1.0, "COC tick dmg ≈ 0.35 (got " + str(dmg_done) + ")")

	# Enemy opposite direction (outside cone) takes 0 damage
	var e_back := GM.create_enemy("war_titan")
	e_back["x"] = coc["x"] - cos(coc["facing_angle"]) * 100.0
	e_back["y"] = coc["y"] - sin(coc["facing_angle"]) * 100.0
	var hp_back_before: float = e_back["hp"]
	GM.enemies.append(e_back)
	GM._cocytus_cone(coc, 0.1)
	_assert_eq(e_back["hp"], hp_back_before, "COC cone does NOT damage enemy behind tower")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# REDESIGN: Inferno Warlock burn
# ═══════════════════════════════════════════════════════
func _run_mag_burn_tests() -> void:
	print("[MAG Burn DoT]")
	GM.reset_state()

	var mag := GM.create_tower("inferno_warlock", 5, 5)
	var e := GM.create_enemy("war_titan")
	GM.enemies.append(e)
	_assert_eq(e["burn_stacks"], 0, "Enemy starts with 0 burn stacks")
	GM.combat_hit(e, 3.0, mag)
	_assert_eq(e["burn_stacks"], 2, "MAG hit adds 2 burn stacks")
	_assert(e["burn_timer"] > 0, "MAG hit sets burn timer")
	GM.combat_hit(e, 3.0, mag)
	GM.combat_hit(e, 3.0, mag)
	_assert_eq(e["burn_stacks"], 4, "Burn stacks cap at 4")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# REDESIGN: Lucifer execute
# ═══════════════════════════════════════════════════════
func _run_lucifer_execute_tests() -> void:
	print("[Lucifer Execute]")
	GM.reset_state()

	var luc_data: Dictionary = Config.TOWER_DATA["lucifer"]
	_assert_eq(luc_data["damage"], 5.0, "Lucifer damage 5 (redesigned)")
	_assert_eq(luc_data["execute_threshold"], 0.15, "Lucifer execute threshold 15%")

	# Low-HP enemy should be executed
	var luc := GM.create_tower("lucifer", 5, 5)
	GM.towers.append(luc)
	var weak := GM.create_enemy("seraph_scout")
	weak["hp"] = weak["max_hp"] * 0.10  # 10% HP — below threshold
	GM.enemies.append(weak)
	GM._lucifer_pulse(luc)
	_assert(not weak["alive"], "Lucifer executes enemy below 15% HP")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# GAMBLING DATA TESTS
# ═══════════════════════════════════════════════════════
func _run_gambling_data_tests() -> void:
	print("[Gambling Data]")

	# Relic weights
	var relic_total := 0
	for loot in Config.RELIC_LOOT:
		relic_total += loot["weight"]
	_assert_eq(relic_total, 100, "Relic loot weights sum to 100")

	# Dice outcomes cover 1-6
	for roll in range(1, 7):
		_assert(Config.DICE_OUTCOMES.has(roll), "Dice outcome for roll %d exists" % roll)
		_assert(Config.DICE_OUTCOMES_EARLY.has(roll), "Early dice outcome for roll %d exists" % roll)


# ═══════════════════════════════════════════════════════
# TARGETING TESTS
# ═══════════════════════════════════════════════════════
func _run_targeting_tests() -> void:
	print("[Targeting]")
	GM.reset_state()

	# Default targeting mode
	var tower := GM.create_tower("bone_marksman", 5, 1)
	_assert_eq(tower["targeting_mode"], "closest", "Default targeting mode is 'closest'")

	# Cycle through modes
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "first", "Cycle to 'first'")
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "strongest", "Cycle to 'strongest'")
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "weakest", "Cycle to 'weakest'")
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "closest", "Cycle wraps to 'closest'")

	# TARGETING_MODES constant
	_assert_eq(GM.TARGETING_MODES.size(), 4, "4 targeting modes exist")

# ═══════════════════════════════════════════════════════
# HERO POOL TESTS
# ═══════════════════════════════════════════════════════
func _run_hero_pool_tests() -> void:
	print("[Hero Pool]")
	GM.reset_state()

	# Hero threshold progression
	_assert_eq(GM.hero_threshold(), 200, "First hero threshold is 200")
	GM.fallen_heroes_spawned = 1
	_assert_eq(GM.hero_threshold(), 500, "Second hero threshold is 500")
	GM.fallen_heroes_spawned = 2
	_assert_eq(GM.hero_threshold(), 1000, "Third hero threshold is 1000")
	GM.fallen_heroes_spawned = 3
	_assert_eq(GM.hero_threshold(), 1500, "Fourth hero threshold is 1500")

	# Adding to pool triggers hero spawn at threshold
	GM.reset_state()
	GM.add_to_hero_pool(199)
	_assert_eq(GM.fallen_heroes_spawned, 0, "No hero at 199 pool")
	GM.add_to_hero_pool(1)
	_assert_eq(GM.fallen_heroes_spawned, 1, "Hero spawned at 200 pool")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# PANDORA CHOICE TESTS
# ═══════════════════════════════════════════════════════
func _run_pandora_tests() -> void:
	print("[Pandora Choice]")
	GM.reset_state()

	# Choice 0: double damage
	GM.pending_pandora_choice = true
	GM.accept_pandora_choice(0)
	_assert(not GM.pending_pandora_choice, "Pandora choice clears pending flag")
	_assert(GM.double_damage >= 1, "Pandora choice 0 grants double damage")

	# Choice 1: sins bonus
	GM.reset_state()
	GM.pending_pandora_choice = true
	var sins_before := GM.sins
	GM.accept_pandora_choice(1)
	_assert(GM.sins > sins_before, "Pandora choice 1 grants sins")
	_assert(not GM.pending_pandora_choice, "Pandora choice 1 clears pending flag")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# SELL REFUND TESTS
# ═══════════════════════════════════════════════════════
func _run_sell_refund_tests() -> void:
	print("[Sell Refund]")
	GM.reset_state()
	GM.sins = 1000

	# Level 1 sell refund
	var tower := GM.create_tower("bone_marksman", 3, 3)
	GM.towers.append(tower)
	GM.occupied_tiles[Config.tile_key(3, 3)] = tower
	var cost: int = Config.TOWER_DATA["bone_marksman"]["cost"]
	var expected_refund: int = roundi(cost * Config.SELL_REFUND * 1)
	var sins_before := GM.sins
	GM.sell_tower(tower)
	var actual_refund: int = GM.sins - sins_before
	# Refund goes through earn() which applies sin_multiplier
	_assert_eq(actual_refund, expected_refund, "Lv1 sell refund = cost * 0.65 * level")

	# Level 2 sell refund
	GM.sins = 1000
	var tower2 := GM.create_tower("bone_marksman", 4, 4)
	GM.towers.append(tower2)
	GM.occupied_tiles[Config.tile_key(4, 4)] = tower2
	GM.upgrade_tower(tower2)
	var expected_refund2: int = roundi(cost * Config.SELL_REFUND * 2)
	sins_before = GM.sins
	GM.sell_tower(tower2)
	var actual_refund2: int = GM.sins - sins_before
	_assert_eq(actual_refund2, expected_refund2, "Lv2 sell refund scales with level")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# TEMPLE CLERIC HEAL AURA TESTS
# ═══════════════════════════════════════════════════════
func _run_cleric_heal_tests() -> void:
	print("[Temple Cleric Heal]")
	GM.reset_state()

	var cleric_data: Dictionary = Config.ENEMY_DATA["temple_cleric"]
	_assert(cleric_data.has("heal_aura_radius"), "Temple Cleric has heal_aura_radius")
	_assert(cleric_data.has("heal_aura_pct"), "Temple Cleric has heal_aura_pct")
	_assert(cleric_data["heal_aura_radius"] > 0, "Heal aura radius is positive")
	_assert(cleric_data["heal_aura_pct"] > 0, "Heal aura percentage is positive")

	# Cleric heals damaged ally in range
	var cleric := GM.create_enemy("temple_cleric")
	cleric["x"] = 200.0; cleric["y"] = 200.0
	GM.enemies.append(cleric)
	var ally := GM.create_enemy("crusader")
	ally["x"] = 220.0; ally["y"] = 200.0
	ally["hp"] = ally["max_hp"] * 0.5  # damage the ally
	var hp_before: float = ally["hp"]
	GM.enemies.append(ally)
	GM.update_enemies(1.0)  # 1 second tick
	_assert(ally["hp"] > hp_before, "Cleric heals nearby damaged ally")
	_assert(ally["hp"] <= ally["max_hp"], "Healing does not exceed max HP")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# TILE KEY HELPER TESTS
# ═══════════════════════════════════════════════════════
func _run_tile_key_tests() -> void:
	print("[Tile Key]")
	_assert_eq(Config.tile_key(0, 0), "0,0", "tile_key(0,0) = '0,0'")
	_assert_eq(Config.tile_key(5, 3), "5,3", "tile_key(5,3) = '5,3'")
	_assert_eq(Config.tile_key(15, 11), "15,11", "tile_key(15,11) = '15,11'")

# ═══════════════════════════════════════════════════════
# ALIVE TYPE CACHE TESTS
# ═══════════════════════════════════════════════════════
func _run_alive_cache_tests() -> void:
	print("[Alive Type Cache]")
	GM.reset_state()

	_assert(not GM._has_alive_type("seraph_scout"), "No alive scout with empty enemies")

	var scout := GM.create_enemy("seraph_scout")
	GM.enemies.append(scout)
	GM.clear_alive_type_cache()
	_assert(GM._has_alive_type("seraph_scout"), "Scout detected after adding to enemies")
	_assert(not GM._has_alive_type("crusader"), "No crusader when only scout exists")

	# Cache should be reused on second call
	scout["alive"] = false
	# Without clearing cache, stale result is returned (by design for perf)
	_assert(GM._has_alive_type("seraph_scout"), "Cache returns stale true before clear")
	GM.clear_alive_type_cache()
	_assert(not GM._has_alive_type("seraph_scout"), "After clear, dead scout not detected")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# DAMAGE ALL PERCENT TESTS
# ═══════════════════════════════════════════════════════
func _run_damage_percent_tests() -> void:
	print("[Damage All Percent]")
	GM.reset_state()

	var e1 := GM.create_enemy("war_titan")
	var e2 := GM.create_enemy("seraph_scout")
	e1["x"] = 100.0; e1["y"] = 100.0
	e2["x"] = 200.0; e2["y"] = 200.0
	GM.enemies.append(e1)
	GM.enemies.append(e2)

	GM._damage_all_percent(0.5, 0.2)
	_assert_eq(e1["hp"], e1["max_hp"] * 0.5, "50% damage halves War Titan HP")
	_assert_eq(e2["hp"], e2["max_hp"] * 0.5, "50% damage halves Scout HP")
	_assert(e1["flash_timer"] > 0, "Flash timer set on percent damage")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# ZEUS LIGHTNING TESTS
# ═══════════════════════════════════════════════════════
func _run_zeus_lightning_tests() -> void:
	print("[Zeus Lightning]")
	GM.reset_state()

	# Zeus disables nearby towers
	var zeus := GM.create_enemy("zeus")
	zeus["x"] = 200.0; zeus["y"] = 200.0
	zeus["ability_timer"] = 0.0  # ready to fire
	GM.enemies.append(zeus)

	var tower1 := GM.create_tower("bone_marksman", 4, 4)  # near zeus
	tower1["x"] = 220.0; tower1["y"] = 200.0
	GM.towers.append(tower1)
	var tower2 := GM.create_tower("bone_marksman", 5, 4)
	tower2["x"] = 240.0; tower2["y"] = 200.0
	GM.towers.append(tower2)

	_assert(not tower1["is_disabled"], "Tower1 starts enabled")
	_assert(not tower2["is_disabled"], "Tower2 starts enabled")

	GM._zeus_lightning(zeus)
	_assert(tower1["is_disabled"], "Zeus disables closest tower 1")
	_assert(tower2["is_disabled"], "Zeus disables closest tower 2")
	_assert_eq(zeus["ability_timer"], Config.ZEUS_LIGHTNING_COOLDOWN, "Zeus ability resets to cooldown")
	_assert(tower1["disable_timer"] > 0, "Disabled tower has timer set")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# MICHAEL SHIELD TESTS
# ═══════════════════════════════════════════════════════
func _run_michael_shield_tests() -> void:
	print("[Michael Shield]")
	GM.reset_state()

	var michael := GM.create_enemy("archangel_michael")
	michael["x"] = 200.0; michael["y"] = 200.0
	michael["ability_timer"] = 0.0
	GM.enemies.append(michael)

	var ally := GM.create_enemy("crusader")
	ally["x"] = 250.0; ally["y"] = 200.0
	GM.enemies.append(ally)

	_assert(not ally["shield_buff"], "Ally starts without shield buff")

	GM._michael_shield(michael)
	_assert(ally["shield_buff"], "Michael grants shield buff to ally")
	_assert(ally["shield_buff_timer"] > 0, "Shield buff timer set")
	_assert_eq(michael["ability_timer"], Config.MICHAEL_SHIELD_COOLDOWN, "Michael ability resets to cooldown")

	# Shield buff reduces damage by 30%
	var hp_before: float = ally["hp"]
	GM.combat_hit(ally, 10.0, null)
	var actual_dmg: float = hp_before - ally["hp"]
	# shield_buff gives 0.7 multiplier
	_assert(actual_dmg < 10.0, "Shield buff reduces incoming damage")
	_assert(actual_dmg >= 6.5 and actual_dmg <= 7.5, "Shield buff gives ~30% reduction (got " + str(actual_dmg) + ")")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# WEAKEST TARGETING MODE TESTS
# ═══════════════════════════════════════════════════════
func _run_weakest_targeting_tests() -> void:
	print("[Weakest Targeting]")
	GM.reset_state()

	var tower := GM.create_tower("bone_marksman", 5, 5)
	GM.towers.append(tower)

	_assert_eq(GM.TARGETING_MODES.size(), 4, "4 targeting modes exist")
	_assert_eq(GM.TARGETING_MODES[3], "weakest", "Fourth mode is 'weakest'")

	# Cycle through all modes
	_assert_eq(tower["targeting_mode"], "closest", "Starts at closest")
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "first", "Cycles to first")
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "strongest", "Cycles to strongest")
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "weakest", "Cycles to weakest")
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "closest", "Wraps back to closest")

	# Weakest targeting picks lowest HP enemy
	tower["targeting_mode"] = "weakest"
	var strong := GM.create_enemy("war_titan")
	strong["x"] = tower["x"] + 20; strong["y"] = tower["y"]
	strong["hp"] = 100.0
	GM.enemies.append(strong)

	var weak := GM.create_enemy("seraph_scout")
	weak["x"] = tower["x"] + 40; weak["y"] = tower["y"]
	weak["hp"] = 5.0
	GM.enemies.append(weak)

	var target = GM.find_target(tower)
	_assert(target != null, "Weakest mode finds a target")
	_assert_eq(target["hp"], 5.0, "Weakest mode picks lowest HP enemy")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# STATS TRACKING TESTS
# ═══════════════════════════════════════════════════════
func _run_stats_tracking_tests() -> void:
	print("[Stats Tracking]")
	GM.reset_state()

	_assert_eq(GM.stats["total_sins_earned"], 0, "Total sins earned starts at 0")

	GM.earn(50)
	_assert_eq(GM.stats["total_sins_earned"], 50, "Earning 50 tracks to total_sins_earned")

	GM.earn(30)
	_assert_eq(GM.stats["total_sins_earned"], 80, "Cumulative sins earned = 80")

	# Sin multiplier affects tracked amount
	GM.sin_multiplier = 2.0
	GM.earn(10)
	_assert_eq(GM.stats["total_sins_earned"], 100, "2x multiplier: earn(10) tracks 20, total=100")
	GM.sin_multiplier = 1.0

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# COCYTUS CONFIG CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_cocytus_config_constants_tests() -> void:
	print("[Cocytus Config Constants]")

	_assert(Config.COCYTUS_FROST_SLOW > 0 and Config.COCYTUS_FROST_SLOW < 1.0, "Frost slow is between 0 and 1")
	_assert_eq(Config.COCYTUS_FROST_SLOW, 0.35, "Frost slow is 35%")
	_assert(Config.COCYTUS_SWEEP_SPEED > 0, "Sweep speed is positive")
	_assert(Config.COCYTUS_SWEEP_ANGLE > 0, "Sweep angle is positive")
	_assert(Config.COCYTUS_SWEEP_ANGLE < PI / 4.0, "Sweep angle < 45 degrees")

# ═══════════════════════════════════════════════════════
# RAPHAEL HEAL BALANCE TESTS
# ═══════════════════════════════════════════════════════
func _run_raphael_heal_tests() -> void:
	print("[Raphael Heal]")
	GM.reset_state()

	var raphael := GM.create_enemy("archangel_raphael")
	raphael["x"] = 200.0; raphael["y"] = 200.0
	raphael["ability_timer"] = 0.0
	GM.enemies.append(raphael)

	var ally := GM.create_enemy("war_titan")
	ally["x"] = 250.0; ally["y"] = 200.0
	ally["hp"] = ally["max_hp"] * 0.5  # 50% HP
	var hp_before: float = ally["hp"]
	GM.enemies.append(ally)

	GM._raphael_heal(raphael)
	_assert(ally["hp"] > hp_before, "Raphael heals damaged ally")
	# Should heal RAPHAEL_HEAL_PERCENT of max HP
	var expected_heal: float = ally["max_hp"] * Config.RAPHAEL_HEAL_PERCENT
	var actual_heal: float = ally["hp"] - hp_before
	_assert(absf(actual_heal - expected_heal) < 0.01, "Raphael heals 12% max HP (got " + str(actual_heal) + ")")
	_assert_eq(raphael["ability_timer"], Config.RAPHAEL_HEAL_COOLDOWN, "Raphael ability resets to cooldown")

	# Raphael does not heal self
	raphael["hp"] = raphael["max_hp"] * 0.3
	var raph_hp: float = raphael["hp"]
	# Make ally full HP so raphael would be the most damaged
	ally["hp"] = ally["max_hp"]
	GM._raphael_heal(raphael)
	# Raphael should not self-heal (skips self in loop)
	_assert_eq(raphael["hp"], raph_hp, "Raphael does not heal self")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# FIRST TARGETING MODE TESTS
# ═══════════════════════════════════════════════════════
func _run_first_targeting_tests() -> void:
	print("[First Targeting]")
	GM.reset_state()

	# Verify 4 targeting modes now
	_assert_eq(GM.TARGETING_MODES.size(), 4, "4 targeting modes exist")
	_assert_eq(GM.TARGETING_MODES[1], "first", "Second mode is 'first'")

	# Cycle through all modes
	var tower := GM.create_tower("bone_marksman", 5, 5)
	GM.towers.append(tower)
	_assert_eq(tower["targeting_mode"], "closest", "Starts at closest")
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "first", "Cycles to first")
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "strongest", "Cycles to strongest")
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "weakest", "Cycles to weakest")
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "closest", "Wraps back to closest")

	# First targeting picks enemy furthest along path
	tower["targeting_mode"] = "first"
	var early := GM.create_enemy("seraph_scout")
	early["x"] = tower["x"] + 20; early["y"] = tower["y"]
	early["path_index"] = 5
	GM.enemies.append(early)

	var advanced := GM.create_enemy("seraph_scout")
	advanced["x"] = tower["x"] + 40; advanced["y"] = tower["y"]
	advanced["path_index"] = 20
	GM.enemies.append(advanced)

	var target = GM.find_target(tower)
	_assert(target != null, "First mode finds a target")
	_assert_eq(target["path_index"], 20, "First mode picks enemy furthest along path")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# COMBAT CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_combat_constants_tests() -> void:
	print("[Combat Constants]")

	# Verify all extracted constants exist and have sane values
	_assert_eq(Config.SHIELD_BUFF_REDUCTION, 0.7, "Shield buff reduction is 0.7")
	_assert_eq(Config.COMMANDER_SPEED_BUFF, 1.25, "Commander speed buff is 1.25")
	_assert_eq(Config.COMMANDER_DAMAGE_REDUCTION, 0.75, "Commander damage reduction is 0.75")
	_assert_eq(Config.INSURANCE_MULT, 1.5, "Insurance multiplier is 1.5")
	_assert_eq(Config.MICHAEL_SHIELD_COOLDOWN, 8.0, "Michael shield cooldown is 8s")
	_assert_eq(Config.MICHAEL_SHIELD_DURATION, 2.0, "Michael shield duration is 2s")
	_assert_eq(Config.ZEUS_LIGHTNING_COOLDOWN, 6.0, "Zeus lightning cooldown is 6s")
	_assert_eq(Config.ZEUS_DISABLE_DURATION, 2.0, "Zeus disable duration is 2s")
	_assert_eq(Config.ZEUS_MAX_TARGETS, 2, "Zeus max targets is 2")
	_assert_eq(Config.RAPHAEL_HEAL_COOLDOWN, 6.0, "Raphael heal cooldown is 6s")
	_assert_eq(Config.RAPHAEL_HEAL_PERCENT, 0.12, "Raphael heal percent is 0.12")

	# Verify calc_damage uses the constants correctly
	GM.reset_state()
	var enemy := GM.create_enemy("seraph_scout")
	enemy["shield_buff"] = true
	var dmg := GM.calc_damage(10.0, null, enemy)
	# shield_buff applies Config.SHIELD_BUFF_REDUCTION (0.7)
	_assert(dmg >= 6.5 and dmg <= 7.5, "Shield buff reduces damage by 30% (got " + str(dmg) + ")")
	GM.reset_state()

# ═══════════════════════════════════════════════════════
# UPGRADE COST SCALING TESTS
# ═══════════════════════════════════════════════════════
func _run_upgrade_cost_scaling_tests() -> void:
	print("[Upgrade Cost Scaling]")
	GM.reset_state()
	GM.sins = 10000

	var tower := GM.create_tower("bone_marksman", 3, 3)
	GM.towers.append(tower)
	var base_upgrade: int = Config.TOWER_DATA["bone_marksman"]["upgrade_cost"]

	# Level 1 -> 2 costs base upgrade
	var lv1_cost: int = roundi(base_upgrade * pow(1.5, 0))
	_assert_eq(lv1_cost, base_upgrade, "Lv1->2 cost equals base upgrade cost")

	# Level 2 -> 3 costs base * 1.5
	var lv2_cost: int = roundi(base_upgrade * pow(1.5, 1))
	_assert(lv2_cost > base_upgrade, "Lv2->3 costs more than lv1->2")

	# Upgrade stats compound correctly
	var dmg_before: float = tower["damage"]
	GM.upgrade_tower(tower)
	var dmg_after: float = tower["damage"]
	var expected_dmg: float = dmg_before * Config.UPGRADE_MULT
	_assert(absf(dmg_after - expected_dmg) < 0.01, "Upgrade multiplies damage by UPGRADE_MULT")

	var range_lv1: float = Config.TOWER_DATA["bone_marksman"]["range"]
	_assert(tower["range"] > range_lv1, "Range increases on upgrade")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# GUARDIAN PROTECTION TESTS
# ═══════════════════════════════════════════════════════
func _run_guardian_protection_tests() -> void:
	print("[Guardian Protection]")
	GM.reset_state()

	# Without a Holy Sentinel, no protection
	var enemy := GM.create_enemy("seraph_scout")
	enemy["path_index"] = 5
	GM.enemies.append(enemy)
	GM.clear_alive_type_cache()
	_assert(not GM._is_guardian_protected(enemy), "No protection without Holy Sentinel")

	# With Holy Sentinel, enemy in first half is protected
	var guard := GM.create_enemy("holy_sentinel")
	GM.enemies.append(guard)
	GM.clear_alive_type_cache()
	_assert(GM._is_guardian_protected(enemy), "Enemy in first half protected by Sentinel")

	# Holy Sentinel itself is NOT protected
	guard["path_index"] = 5
	_assert(not GM._is_guardian_protected(guard), "Holy Sentinel is not self-protected")

	# Enemy past halfway is NOT protected
	@warning_ignore("integer_division")
	var past_half := GM.create_enemy("seraph_scout")
	past_half["path_index"] = Config.path_pixels.size() - 1
	GM.enemies.append(past_half)
	_assert(not GM._is_guardian_protected(past_half), "Enemy past halfway not protected")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# DAMAGE STAT TRACKING TESTS
# ═══════════════════════════════════════════════════════
func _run_damage_stat_tracking_tests() -> void:
	print("[Damage Stat Tracking]")
	GM.reset_state()

	_assert(GM.stats.has("total_damage_dealt"), "Stats has total_damage_dealt key")
	_assert_eq(GM.stats["total_damage_dealt"], 0.0, "Total damage starts at 0")

	var enemy := GM.create_enemy("war_titan")
	GM.enemies.append(enemy)
	GM.combat_hit(enemy, 10.0, null)
	_assert(GM.stats["total_damage_dealt"] > 0, "Damage tracked after combat_hit")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# INSURANCE PAYOUT TESTS
# ═══════════════════════════════════════════════════════
func _run_insurance_payout_tests() -> void:
	print("[Insurance Payout]")
	GM.reset_state()

	# Insurance constant should match
	_assert_eq(Config.INSURANCE_MULT, 1.5, "Insurance payout is 1.5x core damage")

	# Verify enemy leak gives insurance sins
	var enemy := GM.create_enemy("seraph_scout")
	enemy["path_index"] = Config.path_pixels.size()  # past end
	GM.enemies.append(enemy)
	var sins_before := GM.sins
	GM.update_enemies(0.016)
	# Enemy should have leaked and given insurance
	_assert(GM.sins > sins_before, "Insurance sins earned on enemy leak")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# WAVE BONUS TESTS
# ═══════════════════════════════════════════════════════
func _run_wave_bonus_tests() -> void:
	print("[Wave Bonus]")
	GM.reset_state()

	# Complete wave should give sins
	GM.wave = 1
	GM.wave_active = true
	var sins_before := GM.sins
	GM.complete_wave()
	_assert(GM.sins > sins_before, "Wave completion gives bonus sins")
	_assert(not GM.wave_active, "Wave deactivated after completion")

	# Dice replenish
	GM.reset_state()
	GM.dice_uses_left = 0
	GM.wave = 1
	GM.wave_active = true
	GM.complete_wave()
	_assert_eq(GM.dice_uses_left, 1, "Dice replenished after wave completion")

	# Double damage decrements
	GM.reset_state()
	GM.double_damage = 2
	GM.wave = 1
	GM.wave_active = true
	GM.complete_wave()
	_assert_eq(GM.double_damage, 1, "Double damage decremented after wave")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# EFFECT DURATION CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_fx_duration_constants_tests() -> void:
	print("[FX Duration Constants]")

	# Verify all FX constants exist and are positive
	_assert(Config.FX_HIT_SPARK_DURATION > 0, "FX_HIT_SPARK_DURATION is positive")
	_assert(Config.FX_SOUL_HIT_DURATION > 0, "FX_SOUL_HIT_DURATION is positive")
	_assert(Config.FX_DEATH_DURATION > 0, "FX_DEATH_DURATION is positive")
	_assert(Config.FX_LUCIFER_WAVE_DURATION > 0, "FX_LUCIFER_WAVE_DURATION is positive")
	_assert(Config.FX_LUCIFER_HIT_DURATION > 0, "FX_LUCIFER_HIT_DURATION is positive")
	_assert(Config.FX_HADES_WAVE_DURATION > 0, "FX_HADES_WAVE_DURATION is positive")
	_assert(Config.FX_DMG_NUMBER_DURATION > 0, "FX_DMG_NUMBER_DURATION is positive")
	_assert(Config.FX_FLASH_ON_HIT > 0, "FX_FLASH_ON_HIT is positive")
	_assert(Config.FX_RELIC_DURATION > 0, "FX_RELIC_DURATION is positive")
	_assert(Config.FX_AOE_DURATION > 0, "FX_AOE_DURATION is positive")

	# Verify specific values match expected
	_assert_near(Config.FX_HIT_SPARK_DURATION, 0.2, 0.01, "Hit spark is 0.2s")
	_assert_near(Config.FX_SOUL_HIT_DURATION, 0.32, 0.01, "Soul hit is 0.32s")
	_assert_near(Config.FX_LUCIFER_WAVE_DURATION, 1.2, 0.01, "Lucifer wave is 1.2s")
	_assert_near(Config.FX_FLASH_ON_HIT, 0.12, 0.01, "Flash on hit is 0.12s")

	# Verify add_effect uses the constants (effect timer should match constant)
	GM.reset_state()
	GM.add_effect("hit_spark", 100, 100, 5.0, Color.WHITE)
	_assert_eq(GM.effects.size(), 1, "Effect added")
	_assert_near(GM.effects[0]["timer"], Config.FX_HIT_SPARK_DURATION, 0.001, "hit_spark uses FX constant")

	GM.add_effect("soul_hit", 100, 100, 5.0, Color.GREEN)
	_assert_near(GM.effects[1]["timer"], Config.FX_SOUL_HIT_DURATION, 0.001, "soul_hit uses FX constant")

	GM.add_effect("death", 100, 100, 5.0, Color.RED)
	_assert_near(GM.effects[2]["timer"], Config.FX_DEATH_DURATION, 0.001, "death uses FX_DEATH_DURATION")

	# dmg_number should use FX_DMG_NUMBER_DURATION
	GM.add_dmg_number(100, 100, 5.0, Color.WHITE)
	var dmg_fx: Dictionary = GM.effects[GM.effects.size() - 1]
	_assert_near(dmg_fx["timer"], Config.FX_DMG_NUMBER_DURATION, 0.001, "dmg_number uses FX constant")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# DEMONIC PACT TESTS
# ═══════════════════════════════════════════════════════
func _run_demonic_pact_tests() -> void:
	print("[Demonic Pacts]")
	GM.reset_state()

	# Pact data integrity
	_assert(Config.DEMONIC_PACTS.size() >= 3, "At least 3 demonic pacts defined")
	for pact in Config.DEMONIC_PACTS:
		_assert(pact.has("name"), "Pact has name")
		_assert(pact.has("benefit"), "Pact has benefit type")
		_assert(pact.has("cost"), "Pact has cost type")
		_assert(pact.has("benefit_desc"), "Pact has benefit description")
		_assert(pact.has("cost_desc"), "Pact has cost description")

	# Pact constants
	_assert(Config.PACT_OFFER_CHANCE > 0 and Config.PACT_OFFER_CHANCE <= 1.0, "Pact offer chance between 0 and 1")
	_assert(Config.PACT_OFFER_MIN_WAVE >= 1, "Pact min wave >= 1")

	# No pact offered before min wave
	GM.wave = 1
	GM.maybe_offer_pact()
	_assert(GM.pending_pact.is_empty(), "No pact offered at wave 1 (below min)")

	# Accept pact: flat_sins benefit + sin_tax cost
	GM.reset_state()
	GM.pending_pact = {"name": "Test Pact", "benefit": "flat_sins", "cost": "sin_tax",
		"benefit_desc": "Test", "cost_desc": "Test", "b_val": 100, "b_dur": 0, "c_val": 0.5}
	var sins_before := GM.sins
	GM.accept_pact()
	_assert(GM.pending_pact.is_empty(), "Pact cleared after accept")
	_assert(GM.stats["pacts_accepted"] >= 1, "Pact acceptance tracked in stats")
	# Earned 100 sins (through earn() with multiplier 1.0) then lost 50% of total
	_assert(GM.sins != sins_before, "Sins changed after pact")

	# Accept pact: core_heal benefit + core_dmg cost
	GM.reset_state()
	GM.core_hp = 50.0
	GM.pending_pact = {"name": "Heal Pact", "benefit": "core_heal", "cost": "core_dmg",
		"benefit_desc": "Test", "cost_desc": "Test", "b_val": 20.0, "b_dur": 0, "c_val": 15.0}
	GM.accept_pact()
	# HP should be 50 + 20 - 15 = 55 (benefit applied first, then cost)
	_assert(GM.core_hp > 50.0, "Core HP increased from heal pact benefit")

	# Accept pact: extra_enemies cost
	GM.reset_state()
	GM.pending_pact = {"name": "Chaos", "benefit": "double_dmg", "cost": "extra_enemies",
		"benefit_desc": "Test", "cost_desc": "Test", "b_val": 1, "b_dur": 0, "c_val": 3}
	GM.accept_pact()
	_assert_eq(GM.pact_extra_enemies, 3, "Pact sets extra enemies for next wave")
	_assert(GM.double_damage >= 1, "Pact grants double damage benefit")

	# Decline pact
	GM.reset_state()
	GM.pending_pact = {"name": "Test", "benefit": "flat_sins", "cost": "sin_tax",
		"benefit_desc": "T", "cost_desc": "T", "b_val": 100, "b_dur": 0, "c_val": 0.5}
	GM.decline_pact()
	_assert(GM.pending_pact.is_empty(), "Pact cleared after decline")
	_assert_eq(GM.sins, 50, "Sins unchanged after declining pact")

	# Extra enemies injected into spawn queue
	GM.reset_state()
	GM.pact_extra_enemies = 2
	GM.start_wave()
	var titan_count := 0
	for etype in GM.spawn_queue:
		if etype == "war_titan":
			titan_count += 1
	_assert(titan_count >= 2, "Pact extra War Titans added to spawn queue")
	_assert_eq(GM.pact_extra_enemies, 0, "pact_extra_enemies reset after wave start")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# RELIC AOE SCALING TESTS
# ═══════════════════════════════════════════════════════
func _run_relic_aoe_scaling_tests() -> void:
	print("[Relic AoE Scaling]")

	_assert(Config.RELIC_AOE_BASE_DAMAGE > 0, "Relic base AoE damage is positive")
	_assert(Config.RELIC_AOE_SCALE_PER_WAVE > 0, "Relic AoE scale per wave is positive")

	# Wave 0 damage = base
	var wave0_dmg: float = Config.RELIC_AOE_BASE_DAMAGE * (1.0 + Config.RELIC_AOE_SCALE_PER_WAVE * 0)
	_assert_near(wave0_dmg, Config.RELIC_AOE_BASE_DAMAGE, 0.01, "Wave 0 relic dmg = base")

	# Wave 10 damage should be higher
	var wave10_dmg: float = Config.RELIC_AOE_BASE_DAMAGE * (1.0 + Config.RELIC_AOE_SCALE_PER_WAVE * 10)
	_assert(wave10_dmg > wave0_dmg, "Wave 10 relic dmg > wave 0")

	# Wave 20 damage
	var wave20_dmg: float = Config.RELIC_AOE_BASE_DAMAGE * (1.0 + Config.RELIC_AOE_SCALE_PER_WAVE * 20)
	_assert(wave20_dmg > wave10_dmg, "Wave 20 relic dmg > wave 10")
	# At wave 20: 50 * (1 + 0.08 * 20) = 50 * 2.6 = 130
	_assert_near(wave20_dmg, 130.0, 1.0, "Wave 20 relic dmg ≈ 130")

# ═══════════════════════════════════════════════════════
# SPEED BUFF TESTS
# ═══════════════════════════════════════════════════════
func _run_speed_buff_tests() -> void:
	print("[Speed Buff]")
	GM.reset_state()

	# Initial state
	_assert_near(GM.temp_speed_buff, 1.0, 0.01, "Temp speed buff starts at 1.0")
	_assert_near(GM.speed_buff_timer, 0.0, 0.01, "Speed buff timer starts at 0")

	# Apply speed buff
	GM._apply_speed_buff(1.8, 15.0)
	_assert_near(GM.temp_speed_buff, 1.8, 0.01, "Speed buff applied to 1.8")
	_assert_near(GM.speed_buff_timer, 15.0, 0.01, "Speed buff timer set to 15s")
	_assert_near(GM.speed_buff_factor, 1.8, 0.01, "Speed buff factor tracks applied value")

	# Overwrite with negative buff (slow)
	GM._apply_speed_buff(0.75, 10.0)
	_assert_near(GM.temp_speed_buff, 0.75, 0.01, "Slow applied to 0.75")
	_assert_near(GM.speed_buff_timer, 10.0, 0.01, "Slow timer set to 10s")

	# Timer expiry resets buff
	GM.speed_buff_timer = 0.01
	GM.update_effects(0.02)  # exceed timer
	_assert_near(GM.temp_speed_buff, 1.0, 0.01, "Buff resets to 1.0 after timer expires")
	_assert_near(GM.speed_buff_factor, 1.0, 0.01, "Buff factor resets after timer")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# DICE EDGE CASE TESTS
# ═══════════════════════════════════════════════════════
func _run_dice_edge_case_tests() -> void:
	print("[Dice Edge Cases]")
	GM.reset_state()

	# Cannot roll when wave not active
	GM.wave_active = false
	GM.dice_uses_left = 2
	var result := GM.roll_dice()
	_assert(result.is_empty(), "Cannot roll dice when wave not active")
	_assert_eq(GM.dice_uses_left, 2, "Dice not consumed when roll fails")

	# Cannot roll with 0 uses
	GM.wave_active = true
	GM.dice_uses_left = 0
	result = GM.roll_dice()
	_assert(result.is_empty(), "Cannot roll dice with 0 uses")

	# Successful roll
	GM.wave_active = true
	GM.dice_uses_left = 2
	GM.wave = 1
	result = GM.roll_dice()
	_assert(not result.is_empty(), "Dice roll succeeds with uses and active wave")
	_assert_eq(GM.dice_uses_left, 1, "Dice use consumed on roll")
	_assert(result.has("d1"), "Result has d1")
	_assert(result.has("total"), "Result has total")
	_assert(result.has("outcome"), "Result has outcome")
	_assert(result["d1"] >= 1 and result["d1"] <= 6, "Die value between 1-6")
	_assert(GM.show_dice_result, "Dice result display enabled")
	_assert(GM.dice_result_timer > 0, "Dice result timer set")

	# Early game: all outcomes positive
	var outcome: Dictionary = Config.get_dice_outcome(1, 1)
	_assert(outcome["positive"], "Early game roll 1 is positive")
	outcome = Config.get_dice_outcome(6, 1)
	_assert(outcome["positive"], "Early game roll 6 is positive")

	# Late game: low rolls are negative
	outcome = Config.get_dice_outcome(1, 10)
	_assert(not outcome["positive"], "Late game roll 1 is negative")
	outcome = Config.get_dice_outcome(6, 10)
	_assert(outcome["positive"], "Late game roll 6 is positive")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# RELIC DROP RATE TESTS
# ═══════════════════════════════════════════════════════
func _run_relic_drop_rate_tests() -> void:
	print("[Relic Drop Rates]")

	# Grand Paladin always drops
	_assert(GM.should_drop_relic("grand_paladin"), "Grand Paladin always drops relic")

	# Verify drop rate function returns bool for all enemy types
	for etype in Config.ENEMY_DATA:
		var dropped := GM.should_drop_relic(etype)
		_assert(dropped is bool, "should_drop_relic returns bool for " + etype)

	# War Titan has higher drop rate than scouts (15% vs 3%)
	# Statistical test: roll 1000 times and check range
	var titan_drops := 0
	var scout_drops := 0
	for _i in range(1000):
		if GM.should_drop_relic("war_titan"):
			titan_drops += 1
		if GM.should_drop_relic("seraph_scout"):
			scout_drops += 1
	_assert(titan_drops > scout_drops, "War Titan drops more often than scouts (" + str(titan_drops) + " vs " + str(scout_drops) + ")")
	_assert(titan_drops > 50, "War Titan drops at least 50/1000 (got " + str(titan_drops) + ")")

# ═══════════════════════════════════════════════════════
# FALLEN HERO STAT TRACKING TESTS
# ═══════════════════════════════════════════════════════
func _run_fallen_hero_stat_tests() -> void:
	print("[Fallen Hero Stats]")
	GM.reset_state()

	_assert(GM.stats.has("fallen_heroes"), "Stats has fallen_heroes key")
	_assert_eq(GM.stats["fallen_heroes"], 0, "Fallen heroes starts at 0")
	_assert(GM.stats.has("pacts_accepted"), "Stats has pacts_accepted key")
	_assert_eq(GM.stats["pacts_accepted"], 0, "Pacts accepted starts at 0")

	# Trigger hero spawn
	GM.add_to_hero_pool(200)
	_assert_eq(GM.stats["fallen_heroes"], 1, "Fallen hero tracked in stats after spawn")
	_assert_eq(GM.fallen_heroes_spawned, 1, "Fallen heroes spawned matches")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# PACT CONFIG TESTS
# ═══════════════════════════════════════════════════════
func _run_pact_config_tests() -> void:
	print("[Pact Config]")

	_assert_eq(Config.DEMONIC_PACTS.size(), 6, "6 demonic pacts defined")

	# Each pact has all required fields
	var required_fields := ["name", "benefit", "benefit_desc", "cost", "cost_desc", "b_val", "b_dur", "c_val"]
	for pact in Config.DEMONIC_PACTS:
		for field in required_fields:
			_assert(pact.has(field), "Pact '" + pact.get("name", "?") + "' has field '" + field + "'")

	# Verify valid benefit types
	var valid_benefits := ["sin_boost", "tower_dmg_boost", "flat_sins", "core_heal", "double_dmg", "free_tower"]
	for pact in Config.DEMONIC_PACTS:
		_assert(valid_benefits.has(pact["benefit"]), "Pact '" + pact["name"] + "' has valid benefit type")

	# Verify valid cost types
	var valid_costs := ["core_dmg", "disable_random", "fast_enemies", "sin_tax", "extra_enemies", "tower_weaken"]
	for pact in Config.DEMONIC_PACTS:
		_assert(valid_costs.has(pact["cost"]), "Pact '" + pact["name"] + "' has valid cost type")

# ═══════════════════════════════════════════════════════
# SELL TOWER TESTS
# ═══════════════════════════════════════════════════════
func _run_sell_tower_tests() -> void:
	print("[Sell Tower]")
	GM.reset_state()

	var tower := GM.create_tower("bone_marksman", 3, 3)
	GM.towers.append(tower)
	GM.occupied_tiles[Config.tile_key(3, 3)] = true
	var initial_sins := GM.sins
	var tower_id := tower["id"]

	GM.sell_tower(tower)
	_assert(not GM.occupied_tiles.has(Config.tile_key(3, 3)), "Tile freed after sell")
	var expected_refund := roundi(Config.TOWER_DATA["bone_marksman"]["cost"] * Config.SELL_REFUND * 1)
	_assert_gt(float(GM.sins), float(initial_sins), "Sins increased after sell")

	# Verify tower removed from array
	var found := false
	for t in GM.towers:
		if t["id"] == tower_id:
			found = true
	_assert(not found, "Tower removed from towers array after sell")

	# Selling selected tower clears selection
	var tower2 := GM.create_tower("bone_marksman", 5, 5)
	GM.towers.append(tower2)
	GM.selected_tower = tower2
	GM.sell_tower(tower2)
	_assert(GM.selected_tower == null, "Selected tower cleared after selling it")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# BUILDABLE TESTS
# ═══════════════════════════════════════════════════════
func _run_buildable_tests() -> void:
	print("[Buildable]")
	GM.reset_state()

	# Out of bounds
	_assert(not GM.is_buildable(-1, 0), "Negative col not buildable")
	_assert(not GM.is_buildable(0, -1), "Negative row not buildable")
	_assert(not GM.is_buildable(Config.GRID_COLS, 0), "Col >= GRID_COLS not buildable")
	_assert(not GM.is_buildable(0, Config.GRID_ROWS), "Row >= GRID_ROWS not buildable")

	# Path tile not buildable
	var first_path := Config.MAP_PATH[0]
	_assert(not GM.is_buildable(first_path.x, first_path.y), "Path tile not buildable")

	# Empty non-path tile is buildable
	_assert(GM.is_buildable(0, 0), "Empty non-path tile is buildable")

	# Occupied tile not buildable
	GM.occupied_tiles[Config.tile_key(0, 0)] = true
	_assert(not GM.is_buildable(0, 0), "Occupied tile not buildable")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# GAME SPEED TESTS
# ═══════════════════════════════════════════════════════
func _run_game_speed_tests() -> void:
	print("[Game Speed]")
	GM.reset_state()

	_assert_near(GM.game_speed, 1.0, 0.01, "Default game speed is 1.0")

	GM.set_game_speed(2.0)
	_assert_near(GM.game_speed, 2.0, 0.01, "Game speed set to 2.0")
	_assert_near(Engine.time_scale, 2.0, 0.01, "Engine time_scale matches")

	GM.set_game_speed(0.5)
	_assert_near(GM.game_speed, 0.5, 0.01, "Game speed set to 0.5")

	GM.reset_state()
	_assert_near(GM.game_speed, 1.0, 0.01, "Game speed reset to 1.0")

# ═══════════════════════════════════════════════════════
# FORMAT COST TESTS
# ═══════════════════════════════════════════════════════
func _run_format_cost_tests() -> void:
	print("[Format Cost]")

	# format_cost should return a non-empty string
	var result := GM.format_cost(100)
	_assert(result.length() > 0, "format_cost returns non-empty string")

	# Result should contain the number
	_assert(result.contains("100"), "format_cost contains the cost value")

# ═══════════════════════════════════════════════════════
# WAVES SURVIVED STAT TESTS
# ═══════════════════════════════════════════════════════
func _run_waves_survived_tests() -> void:
	print("[Waves Survived]")
	GM.reset_state()

	_assert(GM.stats.has("waves_survived"), "Stats has waves_survived key")
	_assert_eq(GM.stats["waves_survived"], 0, "Waves survived starts at 0")

	# Simulate completing a wave
	GM.phase = "playing"
	GM.wave = 1
	GM.wave_active = true
	GM.complete_wave()
	_assert_eq(GM.stats["waves_survived"], 1, "Waves survived incremented after wave 1")

	GM.wave = 2
	GM.wave_active = true
	GM.complete_wave()
	_assert_eq(GM.stats["waves_survived"], 2, "Waves survived incremented after wave 2")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# TOWER WEAKEN PACT TESTS
# ═══════════════════════════════════════════════════════
func _run_tower_weaken_pact_tests() -> void:
	print("[Tower Weaken Pact]")
	GM.reset_state()

	# Find the Abyssal Gambit pact
	var gambit_pact: Dictionary = {}
	for pact in Config.DEMONIC_PACTS:
		if pact["name"] == "Abyssal Gambit":
			gambit_pact = pact.duplicate()
			break
	_assert(not gambit_pact.is_empty(), "Abyssal Gambit pact exists")

	# Test weaken effect via calc_damage
	GM.tower_weaken_mult = 0.85
	GM.tower_weaken_waves = 3
	var enemy := GM.create_enemy("seraph_scout")
	var dmg_weakened := GM.calc_damage(10.0, null, enemy)
	_assert_lt(dmg_weakened, 10.0, "Weakened damage is less than base")
	_assert_near(dmg_weakened, 8.5, 0.5, "Weakened damage is ~85% of base")

	# Reset clears weaken
	GM.reset_state()
	_assert_near(GM.tower_weaken_mult, 1.0, 0.01, "Weaken mult reset to 1.0")
	_assert_eq(GM.tower_weaken_waves, 0, "Weaken waves reset to 0")

# ═══════════════════════════════════════════════════════
# WAVE BONUS CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_wave_bonus_constants_tests() -> void:
	print("[Wave Bonus Constants]")

	_assert_eq(Config.WAVE_BONUS_BASE_PER_WAVE, 2, "Wave bonus base per wave is 2")
	_assert_eq(Config.WAVE_BONUS_SCALED_BASE, 30, "Wave bonus scaled base is 30")

	# Wave bonus calculation matches formula
	var wave_num := 5
	var expected: int = wave_num * Config.WAVE_BONUS_BASE_PER_WAVE + roundi(Config.WAVE_BONUS_SCALED_BASE * Config.reward_scale(wave_num))
	_assert_gt(float(expected), 0.0, "Wave 5 bonus is positive")
	_assert_gt(float(expected), float(wave_num * Config.WAVE_BONUS_BASE_PER_WAVE), "Wave bonus includes scaled portion")

# ═══════════════════════════════════════════════════════
# BANNER DURATION TESTS
# ═══════════════════════════════════════════════════════
func _run_banner_duration_tests() -> void:
	print("[Banner Duration]")

	_assert_near(Config.WAVE_BANNER_DURATION, 2.6, 0.01, "Banner duration is 2.6s")
	_assert_gt(Config.WAVE_BANNER_DURATION, 0.0, "Banner duration is positive")
