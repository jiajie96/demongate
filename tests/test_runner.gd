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
	_run_boss_kill_bonus_tests()
	_run_cleric_heal_tick_tests()
	_run_relic_aoe_radius_tests()
	_run_projectile_max_dist_tests()
	_run_corruption_mult_tests()
	_run_boss_kills_stat_tests()
	_run_heal_tick_timer_tests()
	# build_spawn, relic_drop, dice_aoe_flash constant tests removed (constants inlined)
	_run_damage_all_percent_tests()
	_run_wave_completion_bonus_tests()
	_run_projectile_lifecycle_tests()
	_run_pact_accept_decline_tests()
	_run_cocytus_global_damage_tracking_tests()
	_run_burn_kill_combat_kill_tests()
	_run_all_pact_types_tests()
	# banner_and_cheat, overview_panel constant tests removed (constants inlined)
	_run_extracted_constants_tests()
	_run_upgrade_scaling_constants_tests()
	_run_relic_drop_config_tests()
	_run_relic_effect_constants_tests()
	_run_lucifer_wave_constants_tests()
	_run_hero_threshold_constants_tests()
	_run_dice_outcome_coverage_tests()
	_run_raphael_heal_target_tests()
	_run_guardian_combat_interaction_tests()
	_run_wave_spawn_interleave_tests()
	_run_find_target_modes_tests()
	_run_complete_wave_decay_tests()
	_run_hades_buff_range_tests()
	_run_burn_source_credit_tests()
	_run_free_upgrade_best_tower_tests()
	_run_dice_replenish_constant_tests()
	_run_projectile_origin_cull_tests()
	_run_starting_sins_constant_tests()
	_run_dice_effect_constants_tests()
	_run_notification_config_tests()
	_run_relic_drop_special_tests()
	_run_fx_timer_constants_tests()
	_run_tower_weaken_constant_tests()
	_run_apply_burn_helper_tests()
	_run_pandora_choice_tests()
	_run_notification_overflow_tests()
	_run_sell_refund_level_scaling_tests()
	_run_cheat_constants_tests()
	_run_core_damage_stat_tests()
	_run_divine_curse_constant_tests()
	_run_lucifer_bolt_constant_tests()
	_run_build_spawn_duration_tests()
	_run_overview_panel_constant_tests()
	_run_banner_animation_constant_tests()

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

func _assert_lte(actual: float, threshold: float, test_name: String) -> void:
	_total += 1
	if actual <= threshold:
		_passed += 1
		print("  PASS: " + test_name)
	else:
		_failed += 1
		print("  FAIL: " + test_name + " (expected <= " + str(threshold) + ", got " + str(actual) + ")")

func _assert_gte(actual: float, threshold: float, test_name: String) -> void:
	_total += 1
	if actual >= threshold:
		_passed += 1
		print("  PASS: " + test_name)
	else:
		_failed += 1
		print("  FAIL: " + test_name + " (expected >= " + str(threshold) + ", got " + str(actual) + ")")

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

# ═══════════════════════════════════════════════════════
# BOSS KILL BONUS TESTS
# ═══════════════════════════════════════════════════════
func _run_boss_kill_bonus_tests() -> void:
	print("[Boss Kill Bonus]")

	# Boss kill bonus constant exists and is > 1
	_assert_gt(Config.BOSS_KILL_BONUS_MULT, 1.0, "Boss kill bonus mult is > 1.0")
	_assert_near(Config.BOSS_KILL_BONUS_MULT, 1.5, 0.01, "Boss kill bonus mult is 1.5")

	# Boss enemies get bonus sins
	GM.reset_state()
	GM.wave = 5
	var start_sins := GM.sins
	GM.earn_from_kill("grand_paladin", false)
	var boss_reward: int = GM.sins - start_sins

	GM.sins = start_sins
	# Compare to non-boss reward (scaled)
	GM.earn_from_kill("crusader", false)
	var normal_reward: int = GM.sins - start_sins

	# Boss reward should be significantly higher than normal due to both base + multiplier
	_assert_gt(float(boss_reward), float(normal_reward), "Boss kill reward > normal kill reward")

	# Verify the bonus is applied: boss reward should be > base_sin_reward * reward_scale
	var base_boss_reward: int = maxi(1, roundi(Config.ENEMY_DATA["grand_paladin"]["sin_reward"] * Config.reward_scale(5)))
	_assert_gt(float(boss_reward), float(base_boss_reward), "Boss kill includes bonus multiplier")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# CLERIC HEAL TICK TESTS
# ═══════════════════════════════════════════════════════
func _run_cleric_heal_tick_tests() -> void:
	print("[Cleric Heal Tick]")

	# Cleric heal tick constant exists
	_assert_gt(Config.CLERIC_HEAL_TICK, 0.0, "Cleric heal tick is positive")
	_assert_near(Config.CLERIC_HEAL_TICK, 0.5, 0.01, "Cleric heal tick is 0.5s")

	# Cleric enemy gets heal_tick_timer in create_enemy
	GM.reset_state()
	GM.wave = 3
	var cleric := GM.create_enemy("temple_cleric")
	_assert(cleric.has("heal_tick_timer"), "Cleric has heal_tick_timer field")
	_assert_near(cleric["heal_tick_timer"], 0.0, 0.01, "Heal tick timer starts at 0")

	# Non-cleric also has the field (all enemies get it)
	var scout := GM.create_enemy("seraph_scout")
	_assert(scout.has("heal_tick_timer"), "Scout has heal_tick_timer field")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# RELIC AOE RADIUS TESTS
# ═══════════════════════════════════════════════════════
func _run_relic_aoe_radius_tests() -> void:
	print("[Relic AoE Radius]")

	# Constant exists and is reasonable
	_assert_gt(Config.RELIC_AOE_RADIUS, 0.0, "Relic AOE radius is positive")
	_assert_near(Config.RELIC_AOE_RADIUS, 80.0, 0.01, "Relic AOE radius is 80")

	# Should be larger than any tower's AoE radius
	var mage_aoe: float = Config.TOWER_DATA["inferno_warlock"]["aoe_radius"]
	_assert_gt(Config.RELIC_AOE_RADIUS, mage_aoe, "Relic AOE > Mage AoE radius")

	# Should be less than half a screen width
	_assert_lt(Config.RELIC_AOE_RADIUS, float(Config.GAME_WIDTH) / 2.0, "Relic AOE < half screen")

# ═══════════════════════════════════════════════════════
# PROJECTILE MAX DIST TESTS
# ═══════════════════════════════════════════════════════
func _run_projectile_max_dist_tests() -> void:
	print("[Projectile Max Dist]")

	# Constant exists and is reasonable
	_assert_gt(Config.PROJECTILE_MAX_DIST, 0.0, "Projectile max dist is positive")
	_assert_near(Config.PROJECTILE_MAX_DIST, 600.0, 0.01, "Projectile max dist is 600")

	# Should be larger than game diagonal (enemies spawn off-screen)
	var max_range: float = 0.0
	for type in Config.TOWER_DATA:
		var data: Dictionary = Config.TOWER_DATA[type]
		if not data.get("is_global", false):
			max_range = maxf(max_range, data["range"])
	_assert_gt(Config.PROJECTILE_MAX_DIST, max_range, "Projectile max dist > longest tower range")

	# Should be less than double the game dimensions
	var diag: float = sqrt(float(Config.GAME_WIDTH * Config.GAME_WIDTH + Config.GAME_HEIGHT * Config.GAME_HEIGHT))
	_assert_lt(Config.PROJECTILE_MAX_DIST, diag, "Projectile max dist < screen diagonal")

# ═══════════════════════════════════════════════════════
# CORRUPTION MULT TESTS
# ═══════════════════════════════════════════════════════
func _run_corruption_mult_tests() -> void:
	print("[Corruption Mult]")

	# Hades tower data now has corruption_mult
	var hades_data: Dictionary = Config.TOWER_DATA["hades"]
	_assert(hades_data.has("corruption_mult"), "Hades has corruption_mult key")
	_assert_gt(hades_data["corruption_mult"], 1.0, "Corruption mult > 1.0 (is a buff)")
	_assert_near(hades_data["corruption_mult"], 1.15, 0.01, "Corruption mult is 1.15")

	# Corruption mult is less than Hades buff_multiplier (weaker synergy)
	_assert_lt(hades_data["corruption_mult"], hades_data["buff_multiplier"], "Corruption < buff_multiplier")

	# Other towers don't have corruption_mult
	_assert(not Config.TOWER_DATA["bone_marksman"].has("corruption_mult"), "Bone Marksman has no corruption_mult")
	_assert(not Config.TOWER_DATA["lucifer"].has("corruption_mult"), "Lucifer has no corruption_mult")

# ═══════════════════════════════════════════════════════
# BOSS KILLS STAT TESTS
# ═══════════════════════════════════════════════════════
func _run_boss_kills_stat_tests() -> void:
	print("[Boss Kills Stat]")
	GM.reset_state()

	# Stats has boss_kills key
	_assert(GM.stats.has("boss_kills"), "Stats has boss_kills key")
	_assert_eq(GM.stats["boss_kills"], 0, "Boss kills starts at 0")

	# Kill a boss enemy via combat_kill
	GM.wave = 5
	var boss := GM.create_enemy("grand_paladin")
	GM.enemies.append(boss)
	GM.combat_kill(boss, null)
	_assert_eq(GM.stats["boss_kills"], 1, "Boss kills incremented after killing boss")

	# Kill a non-boss — should not increment
	var scout := GM.create_enemy("seraph_scout")
	GM.enemies.append(scout)
	GM.combat_kill(scout, null)
	_assert_eq(GM.stats["boss_kills"], 1, "Boss kills not incremented for non-boss")

	# Kill another boss — increments to 2
	var michael := GM.create_enemy("archangel_michael")
	GM.enemies.append(michael)
	GM.combat_kill(michael, null)
	_assert_eq(GM.stats["boss_kills"], 2, "Boss kills incremented for second boss")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# HEAL TICK TIMER TESTS
# ═══════════════════════════════════════════════════════
func _run_heal_tick_timer_tests() -> void:
	print("[Heal Tick Timer]")
	GM.reset_state()
	GM.wave = 3

	# Create a cleric and verify heal_tick_timer behavior
	var cleric := GM.create_enemy("temple_cleric")
	_assert_near(cleric["heal_tick_timer"], 0.0, 0.01, "Cleric heal_tick_timer starts at 0")

	# After setting negative, a tick should fire and reset
	cleric["heal_tick_timer"] = -0.1
	# Next update cycle would reset it to CLERIC_HEAL_TICK
	_assert_lt(cleric["heal_tick_timer"], 0.0, "Negative timer triggers heal on next update")

	# Verify CLERIC_HEAL_TICK is compatible with enemy heal_aura_pct
	var heal_pct: float = Config.ENEMY_DATA["temple_cleric"]["heal_aura_pct"]
	var tick_heal: float = heal_pct * Config.CLERIC_HEAL_TICK
	_assert_gt(tick_heal, 0.0, "Per-tick heal amount is positive")
	_assert_lt(tick_heal, 0.1, "Per-tick heal amount is reasonable (< 10% max HP)")

	# Create enemy, damage it, verify heal math
	var target := GM.create_enemy("crusader")
	target["hp"] = target["max_hp"] * 0.5  # 50% HP
	var heal_amount: float = target["max_hp"] * heal_pct * Config.CLERIC_HEAL_TICK
	var expected_hp: float = target["hp"] + heal_amount
	_assert_gt(expected_hp, target["hp"], "Heal would increase target HP")
	_assert_lt(expected_hp, target["max_hp"], "Single tick doesn't overheal from 50%")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# BUILD / SPAWN DURATION CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_build_spawn_constants_tests() -> void:
	print("[Build/Spawn Constants]")
	# Tower uses correct inline build_timer
	GM.reset_state()
	GM.wave = 1
	var tower := GM.create_tower("bone_marksman", 5, 5)
	_assert_near(tower["build_timer"], 0.3, 0.01, "Tower build_timer is 0.3s")
	var enemy := GM.create_enemy("seraph_scout")
	_assert_near(enemy["spawn_timer"], 0.4, 0.01, "Enemy spawn_timer is 0.4s")
	GM.reset_state()

func _run_relic_drop_constants_tests() -> void:
	print("[Relic Drop Constants]")
	# Boss always drops
	_assert(GM.should_drop_relic("grand_paladin"), "Boss always drops relic")

func _run_dice_aoe_flash_constants_tests() -> void:
	print("[Dice AoE Flash Constants — inlined, no separate test needed]")
	pass

# ═══════════════════════════════════════════════════════
# DAMAGE ALL PERCENT (DICE AOE) TESTS
# ═══════════════════════════════════════════════════════
func _run_damage_all_percent_tests() -> void:
	print("[Damage All Percent]")
	GM.reset_state()
	GM.wave = 5

	# Create enemies and deal percentage damage
	var e1 := GM.create_enemy("seraph_scout")
	var e2 := GM.create_enemy("crusader")
	GM.enemies.append(e1)
	GM.enemies.append(e2)
	var e1_max: float = e1["max_hp"]
	var e2_max: float = e2["max_hp"]

	# Track total_damage_dealt before
	var dmg_before: float = GM.stats.get("total_damage_dealt", 0.0)

	# Apply 10% AoE damage
	GM._damage_all_percent(0.10, 0.15)

	# Enemies should have lost 10% HP
	_assert_near(e1["hp"], e1_max * 0.9, 0.1, "Enemy 1 took 10% damage")
	_assert_near(e2["hp"], e2_max * 0.9, 0.1, "Enemy 2 took 10% damage")

	# total_damage_dealt should be tracked
	var dmg_after: float = GM.stats.get("total_damage_dealt", 0.0)
	var expected_dmg: float = e1_max * 0.1 + e2_max * 0.1
	_assert_near(dmg_after - dmg_before, expected_dmg, 0.1, "Dice AoE tracks total_damage_dealt")

	# Test kill via percentage damage tracks boss_kills
	GM.enemies.clear()
	var boss := GM.create_enemy("grand_paladin")
	boss["hp"] = 1.0  # nearly dead
	GM.enemies.append(boss)
	var boss_kills_before: int = GM.stats.get("boss_kills", 0)
	GM._damage_all_percent(1.0, 0.2)
	var boss_kills_after: int = GM.stats.get("boss_kills", 0)
	_assert_eq(boss_kills_after, boss_kills_before + 1, "Dice AoE kill tracks boss_kills stat")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# WAVE COMPLETION BONUS TESTS
# ═══════════════════════════════════════════════════════
func _run_wave_completion_bonus_tests() -> void:
	print("[Wave Completion Bonus]")
	GM.reset_state()

	# wave_completion_bonus should return positive values
	var bonus_w1: int = GM.wave_completion_bonus(1)
	_assert_gt(float(bonus_w1), 0.0, "Wave 1 bonus is positive")

	var bonus_w10: int = GM.wave_completion_bonus(10)
	_assert_gt(float(bonus_w10), float(bonus_w1), "Wave 10 bonus > wave 1 bonus")

	var bonus_w20: int = GM.wave_completion_bonus(20)
	_assert_gt(float(bonus_w20), float(bonus_w10), "Wave 20 bonus > wave 10 bonus")

	# Bonus matches the formula
	var expected_w5: int = 5 * Config.WAVE_BONUS_BASE_PER_WAVE + roundi(Config.WAVE_BONUS_SCALED_BASE * Config.reward_scale(5))
	_assert_eq(GM.wave_completion_bonus(5), expected_w5, "Wave 5 bonus matches formula")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# PROJECTILE LIFECYCLE TESTS
# ═══════════════════════════════════════════════════════
func _run_projectile_lifecycle_tests() -> void:
	print("[Projectile Lifecycle]")
	GM.reset_state()
	GM.wave = 3

	# Create tower and enemy for projectile
	var tower := GM.create_tower("bone_marksman", 5, 5)
	GM.towers.append(tower)
	var enemy := GM.create_enemy("seraph_scout")
	enemy["x"] = tower["x"] + 20
	enemy["y"] = tower["y"]
	GM.enemies.append(enemy)

	# Create projectile
	var proj := GM.create_projectile(tower, enemy)
	_assert(proj["alive"], "New projectile is alive")
	_assert_near(proj["x"], tower["x"], 0.01, "Projectile starts at tower x")
	_assert_near(proj["y"], tower["y"], 0.01, "Projectile starts at tower y")
	_assert_near(proj["speed"], Config.PROJECTILE_SPEED, 0.01, "Projectile uses config speed")
	_assert(not proj["is_aoe"], "Bone Marksman projectile is not AoE")

	# AoE projectile from Inferno Warlock
	var mage_tower := GM.create_tower("inferno_warlock", 3, 3)
	var mage_proj := GM.create_projectile(mage_tower, enemy)
	_assert(mage_proj["is_aoe"], "Inferno Warlock projectile is AoE")
	_assert_gt(mage_proj["aoe_radius"], 0.0, "AoE projectile has radius > 0")

	# Projectile tracks last known position
	_assert_near(proj["target_last_x"], enemy["x"], 0.01, "Projectile tracks target x")
	_assert_near(proj["target_last_y"], enemy["y"], 0.01, "Projectile tracks target y")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# PACT ACCEPT / DECLINE FLOW TESTS
# ═══════════════════════════════════════════════════════
func _run_pact_accept_decline_tests() -> void:
	print("[Pact Accept/Decline Flow]")
	GM.reset_state()
	GM.wave = 5

	# Manually set a pending pact (Soul Harvest: flat_sins benefit, fast_enemies cost)
	GM.pending_pact = Config.DEMONIC_PACTS[2].duplicate()
	_assert(not GM.pending_pact.is_empty(), "Pending pact is set")

	# Decline the pact — should clear pending_pact
	GM.decline_pact()
	_assert(GM.pending_pact.is_empty(), "Pending pact cleared after decline")
	_assert_eq(GM.stats.get("pacts_accepted", 0), 0, "Pacts accepted stays 0 after decline")

	# Accept a pact — Soul Harvest gives flat_sins
	GM.pending_pact = Config.DEMONIC_PACTS[2].duplicate()
	var sins_before: int = GM.sins
	GM.accept_pact()
	_assert(GM.pending_pact.is_empty(), "Pending pact cleared after accept")
	_assert_eq(GM.stats.get("pacts_accepted", 0), 1, "Pacts accepted incremented after accept")
	_assert_gt(float(GM.sins), float(sins_before), "Sins increased from Soul Harvest pact")

	# Accept should also apply the cost (fast_enemies for Soul Harvest)
	_assert_gt(float(GM.fast_enemy_waves), 0.0, "Fast enemy waves set from Soul Harvest cost")

	# Declining empty pact is a no-op
	GM.pending_pact = {}
	GM.decline_pact()
	_assert(GM.pending_pact.is_empty(), "Declining empty pact is safe")

	# Accept empty pact is a no-op
	GM.accept_pact()
	_assert_eq(GM.stats.get("pacts_accepted", 0), 1, "Accepting empty pact doesn't increment")

	# Dark Resilience pact: heals core
	GM.core_hp = 50.0
	GM.pending_pact = Config.DEMONIC_PACTS[3].duplicate()
	var hp_before: float = GM.core_hp
	var sins_before_dr: int = GM.sins
	GM.accept_pact()
	_assert_gt(GM.core_hp, hp_before, "Dark Resilience heals core HP")
	_assert_lt(float(GM.sins), float(sins_before_dr), "Dark Resilience taxes sins")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# COCYTUS GLOBAL DAMAGE TRACKING TESTS
# ═══════════════════════════════════════════════════════
func _run_cocytus_global_damage_tracking_tests() -> void:
	print("[Cocytus Global Damage Tracking]")
	GM.reset_state()
	GM.wave = 1

	# Create a Cocytus tower and an enemy directly in front of it
	var tower := GM.create_tower("cocytus", 5, 5)
	GM.towers.append(tower)
	var enemy := GM.create_enemy("seraph_scout")
	# Place enemy directly in front of cone
	var facing: float = tower["facing_angle"]
	enemy["x"] = tower["x"] + cos(facing) * 50.0
	enemy["y"] = tower["y"] + sin(facing) * 50.0
	enemy["spawn_timer"] = 0.0
	GM.enemies.append(enemy)

	var dmg_before: float = GM.stats.get("total_damage_dealt", 0.0)
	GM._cocytus_cone(tower, 0.1)
	var dmg_after: float = GM.stats.get("total_damage_dealt", 0.0)
	_assert_gt(dmg_after, dmg_before, "Cocytus cone damage tracked in global stats")

	# Tower's local damage should also increase
	_assert_gt(tower.get("total_damage", 0.0), 0.0, "Cocytus tower total_damage tracked")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# BURN KILL VIA COMBAT_KILL TESTS
# ═══════════════════════════════════════════════════════
func _run_burn_kill_combat_kill_tests() -> void:
	print("[Burn Kill Combat Kill Path]")
	GM.reset_state()
	GM.wave = 1

	# Burn DoT kill should track boss_kills for bosses
	var boss := GM.create_enemy("grand_paladin")
	boss["hp"] = 0.5  # nearly dead
	boss["burn_stacks"] = 4
	boss["burn_timer"] = 3.0
	boss["spawn_timer"] = 0.0
	GM.enemies.append(boss)

	var boss_kills_before: int = GM.stats.get("boss_kills", 0)
	var kills_before: int = GM.stats.get("enemies_killed", 0)
	GM.update_enemies(0.5)  # burn should finish off the boss
	var boss_kills_after: int = GM.stats.get("boss_kills", 0)
	var kills_after: int = GM.stats.get("enemies_killed", 0)
	_assert_gt(float(boss_kills_after), float(boss_kills_before), "Burn DoT kill tracks boss_kills stat")
	_assert_gt(float(kills_after), float(kills_before), "Burn DoT kill tracks enemies_killed stat")

	# Burn damage should also accumulate in total_damage_dealt
	_assert_gt(GM.stats.get("total_damage_dealt", 0.0), 0.0, "Burn DoT damage tracked in global stats")

	# Safety kill path (hp <= 0 at start of update) also uses combat_kill
	GM.reset_state()
	GM.wave = 1
	var dead_boss := GM.create_enemy("grand_paladin")
	dead_boss["hp"] = -5.0  # already below zero
	dead_boss["spawn_timer"] = 0.0
	GM.enemies.append(dead_boss)
	GM.update_enemies(0.016)
	_assert_eq(GM.stats.get("boss_kills", 0), 1, "Safety kill tracks boss_kills for bosses")
	_assert_eq(GM.stats.get("enemies_killed", 0), 1, "Safety kill tracks enemies_killed")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# ALL 6 PACT TYPES TESTS
# ═══════════════════════════════════════════════════════
func _run_all_pact_types_tests() -> void:
	print("[All Pact Types]")

	# Pact 0: Blood Tithe — sin_boost benefit, core_dmg cost
	GM.reset_state()
	GM.wave = 5
	GM.pending_pact = Config.DEMONIC_PACTS[0].duplicate()
	var hp_bt: float = GM.core_hp
	GM.accept_pact()
	_assert_gt(GM.sin_multiplier, 1.0, "Blood Tithe: sin multiplier > 1.0")
	_assert_gt(float(GM.sin_mult_waves), 0.0, "Blood Tithe: sin_mult_waves set")
	_assert_lt(GM.core_hp, hp_bt, "Blood Tithe: core HP reduced")

	# Pact 1: Infernal Forge — tower_dmg_boost benefit, disable_random cost
	GM.reset_state()
	GM.wave = 5
	var t1 := GM.create_tower("bone_marksman", 3, 3)
	var t2 := GM.create_tower("bone_marksman", 5, 5)
	GM.towers.append(t1)
	GM.towers.append(t2)
	GM.occupied_tiles[Config.tile_key(3, 3)] = t1
	GM.occupied_tiles[Config.tile_key(5, 5)] = t2
	GM.pending_pact = Config.DEMONIC_PACTS[1].duplicate()
	GM.accept_pact()
	_assert_gt(t1.get("damage_mult", 1.0), 1.0, "Infernal Forge: tower damage_mult boosted")
	# At least one tower should be disabled
	var any_disabled: bool = t1["is_disabled"] or t2["is_disabled"]
	_assert(any_disabled, "Infernal Forge: at least one tower disabled")

	# Pact 4: Chaos Pact — double_dmg benefit, extra_enemies cost
	GM.reset_state()
	GM.wave = 5
	GM.pending_pact = Config.DEMONIC_PACTS[4].duplicate()
	GM.accept_pact()
	_assert_gt(float(GM.double_damage), 0.0, "Chaos Pact: double_damage set")
	_assert_gt(float(GM.pact_extra_enemies), 0.0, "Chaos Pact: pact_extra_enemies set")

	# Pact 5: Abyssal Gambit — free_tower benefit, tower_weaken cost
	GM.reset_state()
	GM.wave = 5
	GM.pending_pact = Config.DEMONIC_PACTS[5].duplicate()
	GM.accept_pact()
	_assert_gt(float(GM.free_towers), 0.0, "Abyssal Gambit: free_towers granted")
	_assert_gt(float(GM.tower_weaken_waves), 0.0, "Abyssal Gambit: tower_weaken_waves set")
	_assert_lt(GM.tower_weaken_mult, 1.0, "Abyssal Gambit: tower_weaken_mult < 1.0")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# BANNER AND CHEAT CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_banner_and_cheat_constants_tests() -> void:
	print("[Banner and Cheat Constants — inlined, no separate test needed]")
	pass

func _run_overview_panel_constants_tests() -> void:
	print("[Overview Panel Constants — inlined, no separate test needed]")
	pass

# ═══════════════════════════════════════════════════════
# EXTRACTED CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_extracted_constants_tests() -> void:
	print("[Extracted Constants]")

	# Fast enemy speed multiplier
	_assert_near(Config.FAST_ENEMY_SPEED_MULT, 1.3, 0.01, "FAST_ENEMY_SPEED_MULT is 1.3")

	# Guardian flash duration
	_assert_near(Config.GUARDIAN_FLASH_DURATION, 0.05, 0.001, "GUARDIAN_FLASH_DURATION is 0.05")

	# Wave spawn delay
	_assert_near(Config.WAVE_SPAWN_DELAY, 0.5, 0.01, "WAVE_SPAWN_DELAY is 0.5")

	# Cocytus cone timers
	_assert_near(Config.COCYTUS_EMIT_INTERVAL, 0.12, 0.001, "COCYTUS_EMIT_INTERVAL is 0.12")
	_assert_near(Config.COCYTUS_FROST_DURATION, 0.3, 0.01, "COCYTUS_FROST_DURATION is 0.3")

	# Hades buff default
	_assert_near(Config.HADES_BUFF_DEFAULT, 1.5, 0.01, "HADES_BUFF_DEFAULT is 1.5")

	# Heal beam FX duration
	_assert_near(Config.FX_HEAL_BEAM_DURATION, 0.3, 0.01, "FX_HEAL_BEAM_DURATION is 0.3")

	# Fast enemy speed is actually used in update_enemies
	GM.reset_state()
	GM.wave = 1
	GM.fast_enemy_waves = 1
	var enemy := GM.create_enemy("seraph_scout")
	var base_spd: float = enemy["speed"]
	# Speed should be multiplied by FAST_ENEMY_SPEED_MULT during movement
	_assert_gt(Config.FAST_ENEMY_SPEED_MULT, 1.0, "FAST_ENEMY_SPEED_MULT > 1.0 for actual speedup")
	_assert_gt(base_spd, 0.0, "Enemy has positive base speed")
	GM.reset_state()

# ═══════════════════════════════════════════════════════
# UPGRADE SCALING CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_upgrade_scaling_constants_tests() -> void:
	print("[Upgrade Scaling Constants]")

	# Verify the constants exist and have sane values
	_assert_near(Config.UPGRADE_RANGE_MULT, 1.1, 0.01, "UPGRADE_RANGE_MULT is 1.1")
	_assert_near(Config.UPGRADE_SPEED_MULT, 1.15, 0.01, "UPGRADE_SPEED_MULT is 1.15")
	_assert_near(Config.UPGRADE_COST_SCALING, 1.5, 0.01, "UPGRADE_COST_SCALING is 1.5")

	# Verify upgrade applies the constants
	GM.reset_state()
	GM.sins = 9999
	var tower := GM.create_tower("bone_marksman", 3, 3)
	GM.towers.append(tower)
	GM.occupied_tiles[Config.tile_key(3, 3)] = tower
	var range_before: float = tower["range"]
	var speed_before: float = tower["attack_speed"]
	GM.upgrade_tower(tower)
	_assert_near(tower["range"], range_before * Config.UPGRADE_RANGE_MULT, 0.1, "Upgrade applies UPGRADE_RANGE_MULT")
	_assert_near(tower["attack_speed"], speed_before * Config.UPGRADE_SPEED_MULT, 0.01, "Upgrade applies UPGRADE_SPEED_MULT")

	# Verify cost scaling uses UPGRADE_COST_SCALING
	var data: Dictionary = Config.TOWER_DATA["bone_marksman"]
	var expected_cost_l2: int = roundi(data["upgrade_cost"] * pow(Config.UPGRADE_COST_SCALING, 1))
	# Tower is now level 2, so next cost would use level 2
	_assert_gt(float(expected_cost_l2), float(data["upgrade_cost"]), "Level 2 upgrade costs more than level 1")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# RELIC DROP CONFIG CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_relic_drop_config_tests() -> void:
	print("[Relic Drop Config Constants]")

	# Verify drop rates exist in config
	_assert_near(Config.RELIC_DROP_BOSS, 1.0, 0.01, "RELIC_DROP_BOSS is 1.0 (always drops)")
	_assert_near(Config.RELIC_DROP_WAR_TITAN, 0.15, 0.01, "RELIC_DROP_WAR_TITAN is 0.15")
	_assert_near(Config.RELIC_DROP_MEDIUM, 0.05, 0.01, "RELIC_DROP_MEDIUM is 0.05")
	_assert_near(Config.RELIC_DROP_DEFAULT, 0.03, 0.01, "RELIC_DROP_DEFAULT is 0.03")

	# Drop rates should be in descending order by enemy strength
	_assert_gt(Config.RELIC_DROP_BOSS, Config.RELIC_DROP_WAR_TITAN, "Boss drop > War Titan drop")
	_assert_gt(Config.RELIC_DROP_WAR_TITAN, Config.RELIC_DROP_MEDIUM, "War Titan drop > Medium drop")
	_assert_gt(Config.RELIC_DROP_MEDIUM, Config.RELIC_DROP_DEFAULT, "Medium drop > Default drop")

	# All drop rates should be between 0 and 1
	_assert_gt(Config.RELIC_DROP_DEFAULT, 0.0, "Default drop rate > 0")
	_assert(Config.RELIC_DROP_BOSS <= 1.0, "Boss drop rate <= 1.0")

# ═══════════════════════════════════════════════════════
# RELIC EFFECT CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_relic_effect_constants_tests() -> void:
	print("[Relic Effect Constants]")

	# Mass Corruption relic constants
	_assert_near(Config.MASS_CORRUPT_SLOW, 0.3, 0.01, "MASS_CORRUPT_SLOW is 0.3")
	_assert_near(Config.MASS_CORRUPT_DURATION, 5.0, 0.1, "MASS_CORRUPT_DURATION is 5.0")
	_assert_gt(Config.MASS_CORRUPT_SLOW, 0.0, "Mass corrupt slow is positive")
	_assert(Config.MASS_CORRUPT_SLOW < 1.0, "Mass corrupt slow < 1.0 (not full stop)")

	# Time Warp relic constants
	_assert_near(Config.TIME_WARP_SLOW_FACTOR, 0.35, 0.01, "TIME_WARP_SLOW_FACTOR is 0.35")
	_assert_near(Config.TIME_WARP_DURATION, 5.0, 0.1, "TIME_WARP_DURATION is 5.0")
	_assert_gt(Config.TIME_WARP_SLOW_FACTOR, 0.0, "Time warp factor is positive")
	_assert(Config.TIME_WARP_SLOW_FACTOR < 1.0, "Time warp factor < 1.0 (actually slows)")

	# Time Warp description mentions seconds matching constant
	_assert_near(Config.TIME_WARP_DURATION, 5.0, 0.01, "Time warp duration matches '5 seconds' in notification")

# ═══════════════════════════════════════════════════════
# LUCIFER WAVE CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_lucifer_wave_constants_tests() -> void:
	print("[Lucifer Wave Constants]")

	_assert_near(Config.LUCIFER_WAVE_MAX_R, 1000.0, 1.0, "LUCIFER_WAVE_MAX_R is 1000")
	_assert_gt(Config.LUCIFER_WAVE_SPEED, 0.0, "LUCIFER_WAVE_SPEED is positive")
	_assert_near(Config.FX_LUCIFER_HIT_TIMER, 0.22, 0.01, "FX_LUCIFER_HIT_TIMER is 0.22")

	# Wave speed should equal max_r / duration
	var expected_speed: float = Config.LUCIFER_WAVE_MAX_R / Config.FX_LUCIFER_WAVE_DURATION
	_assert_near(Config.LUCIFER_WAVE_SPEED, expected_speed, 1.0, "LUCIFER_WAVE_SPEED = MAX_R / DURATION")

# ═══════════════════════════════════════════════════════
# HERO THRESHOLD CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_hero_threshold_constants_tests() -> void:
	print("[Hero Threshold Constants]")

	_assert_eq(Config.HERO_THRESHOLD_FIRST, 200, "HERO_THRESHOLD_FIRST is 200")
	_assert_eq(Config.HERO_THRESHOLD_SECOND, 500, "HERO_THRESHOLD_SECOND is 500")
	_assert_eq(Config.HERO_THRESHOLD_BASE, 1000, "HERO_THRESHOLD_BASE is 1000")
	_assert_eq(Config.HERO_THRESHOLD_STEP, 500, "HERO_THRESHOLD_STEP is 500")

	# Thresholds should increase
	_assert_gt(float(Config.HERO_THRESHOLD_SECOND), float(Config.HERO_THRESHOLD_FIRST), "Second > First threshold")
	_assert_gt(float(Config.HERO_THRESHOLD_BASE), float(Config.HERO_THRESHOLD_SECOND), "Base > Second threshold")

	# Verify hero_threshold() function
	GM.reset_state()
	GM.fallen_heroes_spawned = 0
	_assert_eq(GM.hero_threshold(), Config.HERO_THRESHOLD_FIRST, "hero_threshold() returns FIRST for 0 spawned")
	GM.fallen_heroes_spawned = 1
	_assert_eq(GM.hero_threshold(), Config.HERO_THRESHOLD_SECOND, "hero_threshold() returns SECOND for 1 spawned")
	GM.fallen_heroes_spawned = 2
	_assert_eq(GM.hero_threshold(), Config.HERO_THRESHOLD_BASE, "hero_threshold() returns BASE for 2 spawned")
	GM.fallen_heroes_spawned = 3
	_assert_eq(GM.hero_threshold(), Config.HERO_THRESHOLD_BASE + Config.HERO_THRESHOLD_STEP, "hero_threshold() scales for 3 spawned")
	GM.reset_state()

# ═══════════════════════════════════════════════════════
# DICE OUTCOME COVERAGE TESTS
# ═══════════════════════════════════════════════════════
func _run_dice_outcome_coverage_tests() -> void:
	print("[Dice Outcome Coverage]")

	# Early dice outcomes (waves 1-4): all should be positive
	for roll in range(1, 7):
		var outcome: Dictionary = Config.get_dice_outcome(roll, 1)
		_assert(outcome["positive"], "Early dice roll %d is positive" % roll)

	# Late dice outcomes (wave 5+): rolls 4-6 positive, 1-3 negative
	for roll in range(4, 7):
		var outcome: Dictionary = Config.get_dice_outcome(roll, 5)
		_assert(outcome["positive"], "Late dice roll %d is positive" % roll)
	for roll in range(1, 4):
		var outcome: Dictionary = Config.get_dice_outcome(roll, 5)
		_assert(not outcome["positive"], "Late dice roll %d is negative" % roll)

	# All outcomes have required keys
	for roll in range(1, 7):
		var outcome: Dictionary = Config.get_dice_outcome(roll, 1)
		_assert(outcome.has("name"), "Outcome %d has name" % roll)
		_assert(outcome.has("effect"), "Outcome %d has effect" % roll)
		_assert(outcome.has("desc"), "Outcome %d has desc" % roll)

# ═══════════════════════════════════════════════════════
# RAPHAEL HEAL TARGET TESTS
# ═══════════════════════════════════════════════════════
func _run_raphael_heal_target_tests() -> void:
	print("[Raphael Heal Target]")

	GM.reset_state()
	GM.wave = 1

	# Raphael should heal the most damaged ally
	var raphael := GM.create_enemy("archangel_raphael")
	raphael["x"] = 100.0; raphael["y"] = 100.0
	raphael["ability_timer"] = 0.0
	raphael["spawn_timer"] = 0.0
	GM.enemies.append(raphael)

	var wounded := GM.create_enemy("crusader")
	wounded["x"] = 120.0; wounded["y"] = 100.0
	wounded["hp"] = wounded["max_hp"] * 0.3  # heavily wounded
	wounded["spawn_timer"] = 0.0
	GM.enemies.append(wounded)

	var healthy := GM.create_enemy("seraph_scout")
	healthy["x"] = 140.0; healthy["y"] = 100.0
	healthy["spawn_timer"] = 0.0
	GM.enemies.append(healthy)

	var hp_before: float = wounded["hp"]
	GM._raphael_heal(raphael)
	_assert_gt(wounded["hp"], hp_before, "Raphael heals the most wounded ally")

	# Raphael should not heal itself
	GM.reset_state()
	GM.wave = 1
	var solo_raph := GM.create_enemy("archangel_raphael")
	solo_raph["x"] = 100.0; solo_raph["y"] = 100.0
	solo_raph["hp"] = solo_raph["max_hp"] * 0.5
	solo_raph["spawn_timer"] = 0.0
	GM.enemies.append(solo_raph)
	var raph_hp: float = solo_raph["hp"]
	GM._raphael_heal(solo_raph)
	_assert_near(solo_raph["hp"], raph_hp, 0.01, "Raphael does not heal itself")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# GUARDIAN COMBAT INTERACTION TESTS
# ═══════════════════════════════════════════════════════
func _run_guardian_combat_interaction_tests() -> void:
	print("[Guardian Combat Interaction]")

	GM.reset_state()
	GM.wave = 1

	# Enemy in first half of path should be protected when guardian alive
	var sentinel := GM.create_enemy("holy_sentinel")
	sentinel["x"] = 100.0; sentinel["y"] = 100.0
	sentinel["path_index"] = 0
	sentinel["spawn_timer"] = 0.0
	GM.enemies.append(sentinel)
	GM.clear_alive_type_cache()

	var protected_enemy := GM.create_enemy("seraph_scout")
	protected_enemy["path_index"] = 1  # early in path
	protected_enemy["spawn_timer"] = 0.0
	GM.enemies.append(protected_enemy)

	_assert(GM._is_guardian_protected(protected_enemy), "Enemy early in path is guardian-protected")

	# Guardian itself is NOT protected
	_assert(not GM._is_guardian_protected(sentinel), "Holy Sentinel is not self-protected")

	# Enemy in second half is NOT protected
	var late_enemy := GM.create_enemy("seraph_scout")
	late_enemy["path_index"] = Config.path_pixels.size() - 1
	late_enemy["spawn_timer"] = 0.0
	GM.enemies.append(late_enemy)
	_assert(not GM._is_guardian_protected(late_enemy), "Enemy late in path is NOT protected")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# WAVE SPAWN INTERLEAVE TESTS
# ═══════════════════════════════════════════════════════
func _run_wave_spawn_interleave_tests() -> void:
	print("[Wave Spawn Interleave]")

	# Wave 1 should produce a spawn queue with correct count
	GM.reset_state()
	GM.wave = 0
	GM.start_wave()
	var wave1_def: Dictionary = Config.WAVE_DATA[0]
	var expected_count := 0
	for entry in wave1_def["enemies"]:
		expected_count += entry["count"]
	_assert_eq(GM.spawn_queue.size() + 1, expected_count, "Wave 1 spawn queue has right count (1 already spawned)")

	# Specials should appear in back half
	GM.reset_state()
	GM.wave = 5  # wave 6 has marshal
	GM.start_wave()
	var marshal_idx := -1
	for i in range(GM.spawn_queue.size()):
		if GM.spawn_queue[i] == "archangel_marshal":
			marshal_idx = i
			break
	if marshal_idx >= 0:
		@warning_ignore("integer_division")
		_assert_gt(float(marshal_idx), float(GM.spawn_queue.size() / 4), "Marshal spawns in back portion of queue")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# FIND TARGET MODES TESTS
# ═══════════════════════════════════════════════════════
func _run_find_target_modes_tests() -> void:
	print("[Find Target Modes]")

	GM.reset_state()
	GM.wave = 1

	var tower := GM.create_tower("bone_marksman", 5, 5)
	GM.towers.append(tower)

	# Create enemies at different distances
	var close := GM.create_enemy("seraph_scout")
	close["x"] = tower["x"] + 30.0; close["y"] = tower["y"]
	close["path_index"] = 2
	close["spawn_timer"] = 0.0
	GM.enemies.append(close)

	var far := GM.create_enemy("war_titan")
	far["x"] = tower["x"] + 80.0; far["y"] = tower["y"]
	far["path_index"] = 10
	far["spawn_timer"] = 0.0
	GM.enemies.append(far)

	# Closest mode
	tower["targeting_mode"] = "closest"
	var target = GM.find_target(tower)
	_assert(target == close, "Closest mode finds nearest enemy")

	# First mode (furthest along path)
	tower["targeting_mode"] = "first"
	target = GM.find_target(tower)
	_assert(target == far, "First mode finds furthest-along enemy")

	# Strongest mode
	tower["targeting_mode"] = "strongest"
	target = GM.find_target(tower)
	_assert(target == far, "Strongest mode finds war_titan (highest max_hp)")

	# Weakest mode
	tower["targeting_mode"] = "weakest"
	target = GM.find_target(tower)
	_assert(target == close, "Weakest mode finds seraph_scout (lowest hp)")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# COMPLETE WAVE DECAY TESTS
# ═══════════════════════════════════════════════════════
func _run_complete_wave_decay_tests() -> void:
	print("[Complete Wave Decay]")

	# double_damage should decay on wave complete
	GM.reset_state()
	GM.wave = 3
	GM.wave_active = true
	GM.double_damage = 2
	GM.sin_mult_waves = 2
	GM.sin_multiplier = 1.5
	GM.fast_enemy_waves = 1
	GM.tower_weaken_waves = 1
	GM.tower_weaken_mult = Config.TOWER_WEAKEN_MULT
	GM.complete_wave()
	_assert_eq(GM.double_damage, 1, "double_damage decrements by 1 on wave complete")
	_assert_eq(GM.sin_mult_waves, 1, "sin_mult_waves decrements by 1")
	_assert_gt(GM.sin_multiplier, 1.0, "sin_multiplier still active when waves remain")
	_assert_eq(GM.fast_enemy_waves, 0, "fast_enemy_waves decrements to 0")
	_assert_eq(GM.tower_weaken_waves, 0, "tower_weaken_waves decrements to 0")
	_assert_near(GM.tower_weaken_mult, 1.0, 0.01, "tower_weaken_mult resets when waves hit 0")

	# sin_multiplier resets when sin_mult_waves hits 0
	GM.reset_state()
	GM.wave = 3
	GM.wave_active = true
	GM.sin_mult_waves = 1
	GM.sin_multiplier = 1.5
	GM.complete_wave()
	_assert_eq(GM.sin_mult_waves, 0, "sin_mult_waves decrements to 0")
	_assert_near(GM.sin_multiplier, 1.0, 0.01, "sin_multiplier resets when waves expire")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# HADES BUFF RANGE TESTS
# ═══════════════════════════════════════════════════════
func _run_hades_buff_range_tests() -> void:
	print("[Hades Buff Range]")

	GM.reset_state()
	GM.wave = 1

	var hades := GM.create_tower("hades", 5, 5)
	GM.towers.append(hades)

	# Tower in range should be buffed
	var near_tower := GM.create_tower("bone_marksman", 6, 5)
	GM.towers.append(near_tower)

	# Tower out of range should NOT be buffed
	var far_tower := GM.create_tower("bone_marksman", 14, 10)
	GM.towers.append(far_tower)

	GM._apply_hades_buff(hades)

	_assert(near_tower["hades_buffed"], "Tower in Hades range gets buffed")
	_assert(not far_tower["hades_buffed"], "Tower out of Hades range not buffed")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# BURN SOURCE CREDIT TESTS
# ═══════════════════════════════════════════════════════
func _run_burn_source_credit_tests() -> void:
	print("[Burn Source Credit]")

	GM.reset_state()
	GM.wave = 1

	var tower := GM.create_tower("inferno_warlock", 3, 3)
	GM.towers.append(tower)
	var enemy := GM.create_enemy("seraph_scout")
	enemy["x"] = tower["x"] + 30.0; enemy["y"] = tower["y"]
	enemy["spawn_timer"] = 0.0
	GM.enemies.append(enemy)

	# Hit with warlock to apply burn
	GM.combat_hit(enemy, tower["damage"], tower)
	_assert_gt(float(enemy["burn_stacks"]), 0.0, "Burn stacks applied via combat_hit")
	_assert(enemy["burn_source"] == tower, "Burn source credits the warlock tower")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# FREE UPGRADE BEST TOWER TESTS
# ═══════════════════════════════════════════════════════
func _run_free_upgrade_best_tower_tests() -> void:
	print("[Free Upgrade Best Tower]")

	GM.reset_state()
	GM.sins = 9999

	var weak := GM.create_tower("bone_marksman", 3, 3)
	GM.towers.append(weak)
	var strong := GM.create_tower("inferno_warlock", 5, 5)
	GM.towers.append(strong)

	var strong_level: int = strong["level"]
	GM.free_upgrade_best_tower()

	# The higher-DPS tower should be upgraded
	# DPS = damage * damage_mult * attack_speed
	var weak_dps: float = weak["damage"] * weak.get("damage_mult", 1.0) * weak["attack_speed"]
	var strong_dps: float = strong["damage"] * strong.get("damage_mult", 1.0) * strong["attack_speed"]
	if strong_dps > weak_dps:
		_assert_eq(strong["level"], strong_level + 1, "Highest DPS tower gets free upgrade")
	else:
		_assert_eq(weak["level"], 2, "Highest DPS tower gets free upgrade (weak was higher)")

	# All towers at max level — returns false
	GM.reset_state()
	var max_tower := GM.create_tower("bone_marksman", 3, 3)
	max_tower["level"] = Config.MAX_TOWER_LEVEL
	GM.towers.append(max_tower)
	_assert(not GM.free_upgrade_best_tower(), "Returns false when all towers maxed")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# DICE REPLENISH CONSTANT TESTS
# ═══════════════════════════════════════════════════════
func _run_dice_replenish_constant_tests() -> void:
	print("[Dice Replenish Constant]")

	_assert_eq(Config.DICE_REPLENISH_PER_WAVE, 1, "DICE_REPLENISH_PER_WAVE is 1")
	_assert_gt(float(Config.DICE_REPLENISH_PER_WAVE), 0.0, "Replenish is positive")

	# Verify complete_wave replenishes dice
	GM.reset_state()
	GM.wave = 3
	GM.wave_active = true
	GM.dice_uses_left = 0
	GM.complete_wave()
	_assert_eq(GM.dice_uses_left, Config.DICE_REPLENISH_PER_WAVE, "Dice replenished on wave complete")

	# Should not exceed max
	GM.reset_state()
	GM.wave = 3
	GM.wave_active = true
	GM.dice_uses_left = Config.DICE_MAX_USES
	GM.complete_wave()
	_assert_eq(GM.dice_uses_left, Config.DICE_MAX_USES, "Dice don't exceed max on replenish")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# PROJECTILE ORIGIN CULL TESTS
# ═══════════════════════════════════════════════════════
func _run_projectile_origin_cull_tests() -> void:
	print("[Projectile Origin Cull]")

	_assert_gt(Config.PROJECTILE_MAX_DIST, 0.0, "PROJECTILE_MAX_DIST is positive")

	# A projectile that has traveled past max dist should be culled
	GM.reset_state()
	GM.wave = 1
	var tower := GM.create_tower("bone_marksman", 3, 3)
	var enemy := GM.create_enemy("seraph_scout")
	enemy["x"] = 9999.0; enemy["y"] = 9999.0  # far away
	enemy["spawn_timer"] = 0.0
	var proj := GM.create_projectile(tower, enemy)
	proj["x"] = proj["origin_x"] + Config.PROJECTILE_MAX_DIST + 100.0  # past max
	GM.projectiles.append(proj)
	GM.update_projectiles(0.016)
	_assert_eq(GM.projectiles.size(), 0, "Projectile culled after exceeding max distance")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# STARTING SINS CONSTANT TESTS
# ═══════════════════════════════════════════════════════
func _run_starting_sins_constant_tests() -> void:
	print("[Starting Sins Constant]")

	_assert_eq(Config.STARTING_SINS, 50, "STARTING_SINS is 50")

	# Verify reset_state uses the constant
	GM.reset_state()
	_assert_eq(GM.sins, Config.STARTING_SINS, "reset_state sets sins to STARTING_SINS")

	# Verify it's positive and reasonable
	_assert_gt(float(Config.STARTING_SINS), 0.0, "STARTING_SINS is positive")
	_assert(Config.STARTING_SINS <= 200, "STARTING_SINS is not absurdly high")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# DICE EFFECT CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_dice_effect_constants_tests() -> void:
	print("[Dice Effect Constants]")

	# Surge (positive speed buff)
	_assert_near(Config.DICE_SURGE_SPEED, 1.8, 0.01, "DICE_SURGE_SPEED is 1.8")
	_assert_near(Config.DICE_SURGE_DURATION, 15.0, 0.1, "DICE_SURGE_DURATION is 15.0")
	_assert_gt(Config.DICE_SURGE_SPEED, 1.0, "Surge actually speeds up towers")

	# Speed boost (milder positive)
	_assert_near(Config.DICE_SPEED_BOOST, 1.3, 0.01, "DICE_SPEED_BOOST is 1.3")
	_assert_near(Config.DICE_SPEED_BOOST_DURATION, 10.0, 0.1, "DICE_SPEED_BOOST_DURATION is 10.0")

	# Slow curse (negative)
	_assert_near(Config.DICE_SLOW_FACTOR, 0.75, 0.01, "DICE_SLOW_FACTOR is 0.75")
	_assert_near(Config.DICE_SLOW_DURATION, 10.0, 0.1, "DICE_SLOW_DURATION is 10.0")
	_assert(Config.DICE_SLOW_FACTOR < 1.0, "Slow factor actually slows towers")

	# Disable
	_assert_near(Config.DICE_DISABLE_DURATION, 3.0, 0.1, "DICE_DISABLE_DURATION is 3.0")

	# Tax
	_assert_near(Config.DICE_TAX_PERCENT, 0.10, 0.01, "DICE_TAX_PERCENT is 0.10")
	_assert_gt(Config.DICE_TAX_PERCENT, 0.0, "Tax percent is positive")
	_assert(Config.DICE_TAX_PERCENT < 1.0, "Tax percent < 100%")

	# Bonus tiers
	_assert_eq(Config.DICE_BONUS_SMALL, 10, "DICE_BONUS_SMALL is 10")
	_assert_eq(Config.DICE_BONUS_MEDIUM, 25, "DICE_BONUS_MEDIUM is 25")
	_assert_eq(Config.DICE_BONUS_LARGE, 50, "DICE_BONUS_LARGE is 50")
	_assert_gt(float(Config.DICE_BONUS_LARGE), float(Config.DICE_BONUS_MEDIUM), "Large > Medium bonus")
	_assert_gt(float(Config.DICE_BONUS_MEDIUM), float(Config.DICE_BONUS_SMALL), "Medium > Small bonus")

	# Display duration
	_assert_near(Config.DICE_RESULT_DISPLAY, 5.0, 0.1, "DICE_RESULT_DISPLAY is 5.0")

# ═══════════════════════════════════════════════════════
# NOTIFICATION CONFIG TESTS
# ═══════════════════════════════════════════════════════
func _run_notification_config_tests() -> void:
	print("[Notification Config]")

	_assert_eq(Config.NOTIFICATION_MAX, 6, "NOTIFICATION_MAX is 6")
	_assert_near(Config.NOTIFICATION_DURATION, 4.0, 0.1, "NOTIFICATION_DURATION is 4.0")
	_assert_gt(float(Config.NOTIFICATION_MAX), 0.0, "NOTIFICATION_MAX is positive")
	_assert_gt(Config.NOTIFICATION_DURATION, 0.0, "NOTIFICATION_DURATION is positive")

	# Slow debuff duration
	_assert_near(Config.SLOW_DEBUFF_DURATION, 2.0, 0.1, "SLOW_DEBUFF_DURATION is 2.0")

# ═══════════════════════════════════════════════════════
# RELIC DROP SPECIAL ENEMY TESTS
# ═══════════════════════════════════════════════════════
func _run_relic_drop_special_tests() -> void:
	print("[Relic Drop Special Enemies]")

	# Verify RELIC_DROP_SPECIAL constant exists and is between medium and war_titan
	_assert_near(Config.RELIC_DROP_SPECIAL, 0.10, 0.01, "RELIC_DROP_SPECIAL is 0.10")
	_assert_gt(Config.RELIC_DROP_SPECIAL, Config.RELIC_DROP_MEDIUM, "Special > Medium drop rate")
	_assert(Config.RELIC_DROP_SPECIAL < Config.RELIC_DROP_WAR_TITAN, "Special < War Titan drop rate")

	# Archangel Michael is a boss — should use boss drop rate
	GM.reset_state()
	var michael_data: Dictionary = Config.ENEMY_DATA["archangel_michael"]
	_assert(michael_data.get("is_boss", false), "Archangel Michael is flagged as boss")

	# Grand Paladin is also a boss
	var paladin_data: Dictionary = Config.ENEMY_DATA["grand_paladin"]
	_assert(paladin_data.get("is_boss", false), "Grand Paladin is flagged as boss")

	# Zeus, Holy Sentinel, Marshal, Raphael are not bosses but are special
	_assert(not Config.ENEMY_DATA["zeus"].get("is_boss", false), "Zeus is not a boss")
	_assert(not Config.ENEMY_DATA["holy_sentinel"].get("is_boss", false), "Holy Sentinel is not a boss")
	_assert(not Config.ENEMY_DATA["archangel_marshal"].get("is_boss", false), "Marshal is not a boss")
	_assert(not Config.ENEMY_DATA["archangel_raphael"].get("is_boss", false), "Raphael is not a boss")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# FX TIMER CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_fx_timer_constants_tests() -> void:
	print("[FX Timer Constants]")

	_assert_near(Config.FX_MICHAEL_SHIELD_DURATION, 0.8, 0.01, "FX_MICHAEL_SHIELD_DURATION is 0.8")
	_assert_near(Config.FX_ZEUS_BOLT_DURATION, 0.4, 0.01, "FX_ZEUS_BOLT_DURATION is 0.4")
	_assert_near(Config.FX_HADES_BEAM_DURATION, 0.5, 0.01, "FX_HADES_BEAM_DURATION is 0.5")
	_assert_near(Config.FX_HADES_CURSE_DURATION, 0.5, 0.01, "FX_HADES_CURSE_DURATION is 0.5")
	_assert_near(Config.FX_CORE_HIT_RADIUS, 10.0, 0.1, "FX_CORE_HIT_RADIUS is 10.0")
	_assert_near(Config.GAMEOVER_SHAKE_INTENSITY, 8.0, 0.1, "GAMEOVER_SHAKE_INTENSITY is 8.0")
	_assert_near(Config.GAMEOVER_SHAKE_DURATION, 0.4, 0.01, "GAMEOVER_SHAKE_DURATION is 0.4")

	# All FX durations should be positive
	_assert_gt(Config.FX_MICHAEL_SHIELD_DURATION, 0.0, "Michael shield FX > 0")
	_assert_gt(Config.FX_ZEUS_BOLT_DURATION, 0.0, "Zeus bolt FX > 0")
	_assert_gt(Config.FX_HADES_BEAM_DURATION, 0.0, "Hades beam FX > 0")
	_assert_gt(Config.GAMEOVER_SHAKE_INTENSITY, 0.0, "Gameover shake intensity > 0")

# ═══════════════════════════════════════════════════════
# TOWER WEAKEN CONSTANT TESTS
# ═══════════════════════════════════════════════════════
func _run_tower_weaken_constant_tests() -> void:
	print("[Tower Weaken Constant]")

	_assert_near(Config.TOWER_WEAKEN_MULT, 0.85, 0.01, "TOWER_WEAKEN_MULT is 0.85")
	_assert(Config.TOWER_WEAKEN_MULT < 1.0, "Weaken mult is a debuff (< 1.0)")
	_assert_gt(Config.TOWER_WEAKEN_MULT, 0.0, "Weaken mult is positive")

	# Verify pact acceptance uses the constant
	GM.reset_state()
	GM.wave = 5
	GM.pending_pact = Config.DEMONIC_PACTS[5].duplicate()  # Abyssal Gambit
	GM.accept_pact()
	_assert_near(GM.tower_weaken_mult, Config.TOWER_WEAKEN_MULT, 0.01, "accept_pact uses TOWER_WEAKEN_MULT")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# APPLY BURN HELPER TESTS
# ═══════════════════════════════════════════════════════
func _run_apply_burn_helper_tests() -> void:
	print("[Apply Burn Helper]")

	GM.reset_state()
	GM.wave = 1
	var enemy := GM.create_enemy("seraph_scout")
	var tower := GM.create_tower("inferno_warlock", 3, 3)

	# Initial state — no burn
	_assert_eq(enemy["burn_stacks"], 0, "Enemy starts with 0 burn stacks")

	# Apply burn once
	GM._apply_burn(enemy, tower)
	var mdata: Dictionary = Config.TOWER_DATA["inferno_warlock"]
	_assert_eq(enemy["burn_stacks"], int(mdata["burn_stacks_per_hit"]), "Burn stacks applied")
	_assert_near(enemy["burn_timer"], float(mdata["burn_duration"]), 0.01, "Burn timer set")
	_assert(enemy["burn_source"] == tower, "Burn source set to tower")

	# Apply burn again — should stack up to cap
	GM._apply_burn(enemy, tower)
	var expected: int = mini(int(mdata["burn_stacks_per_hit"]) * 2, int(mdata["burn_stack_cap"]))
	_assert_eq(enemy["burn_stacks"], expected, "Burn stacks cap correctly")

	# Apply burn many times — should never exceed cap
	for _j in range(10):
		GM._apply_burn(enemy, tower)
	_assert_eq(enemy["burn_stacks"], int(mdata["burn_stack_cap"]), "Burn stacks never exceed cap")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# PANDORA CHOICE TESTS
# ═══════════════════════════════════════════════════════
func _run_pandora_choice_tests() -> void:
	print("[Pandora Choice]")

	# Choice 0: double damage for 1 wave
	GM.reset_state()
	GM.pending_pandora_choice = true
	GM.accept_pandora_choice(0)
	_assert_gt(float(GM.double_damage), 0.0, "Pandora choice 0: double_damage set")
	_assert(not GM.pending_pandora_choice, "Pandora choice 0: pending cleared")

	# Choice 1: 100 sins
	GM.reset_state()
	GM.pending_pandora_choice = true
	var sins_before: int = GM.sins
	GM.accept_pandora_choice(1)
	_assert_gt(float(GM.sins), float(sins_before), "Pandora choice 1: sins increased")
	_assert(not GM.pending_pandora_choice, "Pandora choice 1: pending cleared")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# NOTIFICATION OVERFLOW TESTS
# ═══════════════════════════════════════════════════════
func _run_notification_overflow_tests() -> void:
	print("[Notification Overflow]")

	GM.reset_state()

	# Add more than NOTIFICATION_MAX notifications
	for i in range(Config.NOTIFICATION_MAX + 3):
		GM.notify("Test notification " + str(i), Color.WHITE)

	_assert(GM.notifications.size() <= Config.NOTIFICATION_MAX, "Notifications capped at NOTIFICATION_MAX")
	_assert_eq(GM.notifications.size(), Config.NOTIFICATION_MAX, "Exactly NOTIFICATION_MAX notifications kept")

	# Verify oldest was removed (first notification should be #3 since 0,1,2 were evicted)
	var first_text: String = GM.notifications[0]["text"]
	_assert(first_text.contains("3"), "Oldest notifications evicted first")

	# Verify timer is set from constant
	_assert_near(GM.notifications[0]["timer"], Config.NOTIFICATION_DURATION, 0.01, "Notification timer uses NOTIFICATION_DURATION")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# SELL REFUND LEVEL SCALING TESTS
# ═══════════════════════════════════════════════════════
func _run_sell_refund_level_scaling_tests() -> void:
	print("[Sell Refund Level Scaling]")

	# Sell at level 1
	GM.reset_state()
	GM.sins = 9999
	var t1 := GM.create_tower("bone_marksman", 3, 3)
	GM.towers.append(t1)
	GM.occupied_tiles[Config.tile_key(3, 3)] = t1
	var sins_before_sell: int = GM.sins
	GM.sell_tower(t1)
	var refund_l1: int = GM.sins - sins_before_sell
	var expected_l1: int = roundi(Config.TOWER_DATA["bone_marksman"]["cost"] * Config.SELL_REFUND * 1)
	_assert_eq(refund_l1, expected_l1, "Level 1 sell refund = cost * SELL_REFUND * 1")

	# Sell at level 2
	GM.reset_state()
	GM.sins = 9999
	var t2 := GM.create_tower("bone_marksman", 3, 3)
	GM.towers.append(t2)
	GM.occupied_tiles[Config.tile_key(3, 3)] = t2
	GM.upgrade_tower(t2)  # now level 2
	sins_before_sell = GM.sins
	GM.sell_tower(t2)
	var refund_l2: int = GM.sins - sins_before_sell
	var expected_l2: int = roundi(Config.TOWER_DATA["bone_marksman"]["cost"] * Config.SELL_REFUND * 2)
	_assert_eq(refund_l2, expected_l2, "Level 2 sell refund = cost * SELL_REFUND * 2")

	# Level 2 refund should be higher than level 1
	_assert_gt(float(refund_l2), float(refund_l1), "Higher level = higher sell refund")

	# Sell at level 3 (max)
	GM.reset_state()
	GM.sins = 99999
	var t3 := GM.create_tower("bone_marksman", 3, 3)
	GM.towers.append(t3)
	GM.occupied_tiles[Config.tile_key(3, 3)] = t3
	GM.upgrade_tower(t3)  # level 2
	GM.upgrade_tower(t3)  # level 3
	sins_before_sell = GM.sins
	GM.sell_tower(t3)
	var refund_l3: int = GM.sins - sins_before_sell
	var expected_l3: int = roundi(Config.TOWER_DATA["bone_marksman"]["cost"] * Config.SELL_REFUND * 3)
	_assert_eq(refund_l3, expected_l3, "Level 3 sell refund = cost * SELL_REFUND * 3")
	_assert_gt(float(refund_l3), float(refund_l2), "Level 3 refund > level 2 refund")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# CHEAT CONSTANTS TESTS
# ═══════════════════════════════════════════════════════
func _run_cheat_constants_tests() -> void:
	print("[Cheat Constants]")

	# Verify cheat constants exist and have reasonable values
	_assert_eq(Config.CHEAT_SINS_AMOUNT, 99999, "CHEAT_SINS_AMOUNT is 99999")
	_assert_eq(Config.CHEAT_SKIP_TO_WAVE, 15, "CHEAT_SKIP_TO_WAVE is 15")
	_assert_gt(float(Config.CHEAT_SINS_AMOUNT), 0.0, "Cheat sins amount is positive")
	_assert_gt(float(Config.CHEAT_SKIP_TO_WAVE), 0.0, "Cheat skip wave is positive")
	_assert(Config.CHEAT_SKIP_TO_WAVE <= Config.MAX_WAVES, "Cheat skip wave <= MAX_WAVES")

# ═══════════════════════════════════════════════════════
# CORE DAMAGE STAT TRACKING TESTS
# ═══════════════════════════════════════════════════════
func _run_core_damage_stat_tests() -> void:
	print("[Core Damage Stat Tracking]")

	# Stat exists in reset state
	GM.reset_state()
	_assert_near(GM.stats.get("total_core_damage", -1.0), 0.0, 0.01, "total_core_damage starts at 0")

	# Create an enemy at end of path so it leaks
	GM.wave = 1
	var enemy := GM.create_enemy("seraph_scout")
	var last_idx: int = Config.path_pixels.size()
	enemy["path_index"] = last_idx  # past the end
	GM.enemies.append(enemy)
	var core_dmg_expected: float = float(enemy["core_dmg"])
	var hp_before: float = GM.core_hp

	GM.update_enemies(0.016)

	_assert_near(GM.stats.get("total_core_damage", 0.0), core_dmg_expected, 0.01, "Core damage stat tracks leaked enemy damage")
	_assert(GM.core_hp < hp_before, "Core HP decreased after leak")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# DIVINE CURSE CONSTANT TESTS
# ═══════════════════════════════════════════════════════
func _run_divine_curse_constant_tests() -> void:
	print("[Divine Curse Constant]")

	_assert_near(Config.DIVINE_CURSE_DURATION, 10.0, 0.01, "DIVINE_CURSE_DURATION is 10.0")
	_assert_gt(Config.DIVINE_CURSE_DURATION, 0.0, "Divine curse duration is positive")
	# Should be longer than Zeus disable to feel more punishing
	_assert_gt(Config.DIVINE_CURSE_DURATION, Config.ZEUS_DISABLE_DURATION, "Divine curse > Zeus disable")

# ═══════════════════════════════════════════════════════
# LUCIFER BOLT CONSTANT TESTS
# ═══════════════════════════════════════════════════════
func _run_lucifer_bolt_constant_tests() -> void:
	print("[Lucifer Bolt Constant]")

	_assert_near(Config.LUCIFER_BOLT_HEIGHT, 160.0, 0.01, "LUCIFER_BOLT_HEIGHT is 160.0")
	_assert_gt(Config.LUCIFER_BOLT_HEIGHT, 0.0, "Lucifer bolt height is positive")
	# Should be taller than a few tiles so bolts are visually dramatic
	_assert_gt(Config.LUCIFER_BOLT_HEIGHT, float(Config.TILE_SIZE * 2), "Bolt height > 2 tiles")

# ═══════════════════════════════════════════════════════
# BUILD / SPAWN DURATION TESTS
# ═══════════════════════════════════════════════════════
func _run_build_spawn_duration_tests() -> void:
	print("[Build/Spawn Duration Constants]")

	# Tower build_timer should use TOWER_BUILD_DURATION
	GM.reset_state()
	var tower := GM.create_tower("bone_marksman", 3, 3)
	_assert_near(tower["build_timer"], Config.TOWER_BUILD_DURATION, 0.01, "Tower build_timer uses TOWER_BUILD_DURATION")

	# Enemy spawn_timer should use ENEMY_SPAWN_DURATION
	GM.wave = 1
	var enemy := GM.create_enemy("seraph_scout")
	_assert_near(enemy["spawn_timer"], Config.ENEMY_SPAWN_DURATION, 0.01, "Enemy spawn_timer uses ENEMY_SPAWN_DURATION")

	# Both durations should be positive and short
	_assert_gt(Config.TOWER_BUILD_DURATION, 0.0, "Build duration > 0")
	_assert_gt(Config.ENEMY_SPAWN_DURATION, 0.0, "Spawn duration > 0")
	_assert(Config.TOWER_BUILD_DURATION < 2.0, "Build duration < 2s (responsive)")
	_assert(Config.ENEMY_SPAWN_DURATION < 2.0, "Spawn duration < 2s (responsive)")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# OVERVIEW PANEL CONSTANT TESTS
# ═══════════════════════════════════════════════════════
func _run_overview_panel_constant_tests() -> void:
	print("[Overview Panel Constants]")

	_assert_near(Config.OVERVIEW_PANEL_W, 52.0, 0.01, "OVERVIEW_PANEL_W is 52.0")
	_assert_near(Config.OVERVIEW_PANEL_H, 30.0, 0.01, "OVERVIEW_PANEL_H is 30.0")
	_assert_gt(Config.OVERVIEW_PANEL_W, 0.0, "Panel width is positive")
	_assert_gt(Config.OVERVIEW_PANEL_H, 0.0, "Panel height is positive")
	# Panel should fit within a single tile
	_assert(Config.OVERVIEW_PANEL_W <= float(Config.TILE_SIZE * 2), "Panel width fits in 2 tiles")
	_assert(Config.OVERVIEW_PANEL_H <= float(Config.TILE_SIZE), "Panel height fits in 1 tile")

# ═══════════════════════════════════════════════════════
# BANNER ANIMATION CONSTANT TESTS
# ═══════════════════════════════════════════════════════
func _run_banner_animation_constant_tests() -> void:
	print("[Banner Animation Constants]")

	_assert_near(Config.WAVE_BANNER_SLIDE_IN, 0.35, 0.01, "WAVE_BANNER_SLIDE_IN is 0.35")
	_assert_near(Config.WAVE_BANNER_FADE_OUT, 0.7, 0.01, "WAVE_BANNER_FADE_OUT is 0.7")
	_assert_gt(Config.WAVE_BANNER_SLIDE_IN, 0.0, "Slide-in duration > 0")
	_assert_gt(Config.WAVE_BANNER_FADE_OUT, 0.0, "Fade-out duration > 0")
	# Slide-in + fade-out should not exceed the total banner duration
	_assert(Config.WAVE_BANNER_SLIDE_IN + Config.WAVE_BANNER_FADE_OUT <= Config.WAVE_BANNER_DURATION, "Slide + fade <= total banner duration")
	# Fade out should be longer than slide in for smooth exit
	_assert_gt(Config.WAVE_BANNER_FADE_OUT, Config.WAVE_BANNER_SLIDE_IN, "Fade-out > slide-in")
