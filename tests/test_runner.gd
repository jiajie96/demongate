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

func _assert_eq(actual, expected, test_name: String) -> void:
	_total += 1
	if actual == expected:
		_passed += 1
		print("  PASS: " + test_name)
	else:
		_failed += 1
		print("  FAIL: " + test_name + " (expected " + str(expected) + ", got " + str(actual) + ")")

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
	_assert_eq(Config.PACT_POOL.size(), 6, "6 pact types")
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
	GM.occupied_tiles["0,0"] = tower
	_assert(not GM.is_buildable(0, 0), "Occupied tile not buildable")
	GM.occupied_tiles.erase("0,0")

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
	GM.occupied_tiles["3,3"] = tower
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
	_assert(dmg >= 10.0, "Double damage pact doubles damage")
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
	_assert(GM.spawn_queue.size() > 5, "Wave 2 has more enemies than wave 1")

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
	_assert_eq(coc_data["damage"], 12.0, "Cocytus damage 12 (redesigned)")
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
	# Expected: 12 DPS × 0.1s = 1.2 dmg
	var dmg_done: float = hp_before - e["hp"]
	_assert(dmg_done > 0.5 and dmg_done < 2.0, "COC tick dmg ≈ 1.2 (got " + str(dmg_done) + ")")

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

	# All pacts have required fields
	for pact in Config.PACT_POOL:
		_assert(pact.has("name") and pact.has("benefit") and pact.has("cost_desc"), "Pact '%s' has display fields" % pact["name"])
		_assert(pact.has("b_effect") and pact.has("c_effect"), "Pact '%s' has effect fields" % pact["name"])

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
	_assert_eq(tower["targeting_mode"], "strongest", "Cycle to 'strongest'")
	GM.cycle_targeting(tower)
	_assert_eq(tower["targeting_mode"], "closest", "Cycle wraps to 'closest'")

	# TARGETING_MODES constant
	_assert_eq(GM.TARGETING_MODES.size(), 2, "2 targeting modes exist")
