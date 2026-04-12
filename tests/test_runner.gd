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
	_run_gambling_data_tests()

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
	_assert_eq(Config.TOWER_DATA.size(), 4, "4 tower types defined")
	_assert_eq(Config.ENEMY_DATA.size(), 6, "6 enemy types defined")
	_assert_eq(Config.WAVE_DATA.size(), 20, "20 wave definitions")
	_assert_eq(Config.ROULETTE_SEGMENTS.size(), 8, "8 roulette segments")
	_assert_eq(Config.DICE_OUTCOMES.size(), 11, "11 dice outcomes (2-12)")
	_assert_eq(Config.PACT_POOL.size(), 6, "6 pact types")
	_assert_eq(Config.RELIC_LOOT.size(), 9, "9 relic loot types")

	# Tower data integrity
	for type in Config.TOWER_DATA:
		var d: Dictionary = Config.TOWER_DATA[type]
		_assert(d.has("name") and d.has("cost") and d.has("damage") and d.has("range"), "Tower '%s' has required fields" % type)
		_assert(d["cost"] is int or d["cost"] is float, "Tower '%s' cost is numeric" % type)
		_assert(d["damage"] > 0, "Tower '%s' damage > 0" % type)
		_assert(d["range"] > 0, "Tower '%s' range > 0" % type)
		_assert(d["attack_speed"] > 0, "Tower '%s' attack_speed > 0" % type)

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
	_assert_eq(GM.sins, 100, "Starting sins is 100")

	GM.earn(50)
	_assert_eq(GM.sins, 150, "Earn 50 -> 150")

	_assert(GM.can_afford(150), "Can afford 150 with 150")
	_assert(GM.can_afford(100), "Can afford 100 with 150")
	_assert(not GM.can_afford(200), "Cannot afford 200 with 150")

	_assert(GM.spend(100), "Spend 100 succeeds")
	_assert_eq(GM.sins, 50, "After spending 100, have 50")

	_assert(not GM.spend(100), "Spend 100 fails with only 50")
	_assert_eq(GM.sins, 50, "Failed spend doesn't change balance")

	# Sin multiplier
	GM.sin_multiplier = 2.0
	GM.earn(10)
	_assert_eq(GM.sins, 70, "2x multiplier: earn 10 -> +20 -> 70")
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
	var tower := GM.create_tower("demon_archer", 3, 3)
	_assert_eq(tower["type"], "demon_archer", "Tower type is demon_archer")
	_assert_eq(tower["level"], 1, "Tower starts at level 1")
	_assert_eq(tower["damage"], 2.0, "Demon archer damage is 2.0")
	_assert_eq(tower["range"], 120.0, "Demon archer range is 120")
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

	var scout := GM.create_enemy("angel_scout")
	_assert_eq(scout["hp"], 8.0, "Angel scout has 8 HP")
	_assert_eq(scout["max_hp"], 8.0, "Angel scout max HP is 8")
	_assert(scout["alive"], "Enemy starts alive")
	_assert_eq(scout["path_index"], 0, "Enemy starts at path index 0")
	_assert(scout.has("id"), "Enemy has unique id")

	var paladin := GM.create_enemy("paladin")
	_assert_eq(paladin["hp"], 150.0, "Paladin has 150 HP")
	_assert(paladin["is_boss"], "Paladin is a boss")
	_assert_eq(paladin["core_dmg"], 20, "Paladin core damage is 20")

	var knight := GM.create_enemy("holy_knight")
	_assert_eq(knight["hp"], 25.0, "Holy knight has 25 HP")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# COMBAT TESTS
# ═══════════════════════════════════════════════════════
func _run_combat_tests() -> void:
	print("[Combat]")
	GM.reset_state()

	var enemy := GM.create_enemy("angel_scout")
	GM.enemies.append(enemy)

	# Hit without killing
	GM.combat_hit(enemy, 3.0, null)
	_assert_eq(enemy["hp"], 5.0, "After 3 damage, 5 HP remains")
	_assert(enemy["alive"], "Enemy still alive at 5 HP")
	_assert(enemy["flash_timer"] > 0, "Flash timer set on hit")

	# Lethal hit
	GM.combat_hit(enemy, 10.0, null)
	_assert(not enemy["alive"], "Enemy dies from lethal damage")
	_assert_eq(GM.stats["enemies_killed"], 1, "Kill counter incremented")

	# Sins earned from kill
	_assert(GM.sins > 100, "Sins earned from kill")

	# AoE combat
	GM.reset_state()
	var e1 := GM.create_enemy("angel_scout")
	var e2 := GM.create_enemy("angel_scout")
	e1["x"] = 100.0; e1["y"] = 100.0
	e2["x"] = 110.0; e2["y"] = 100.0
	GM.enemies.append(e1)
	GM.enemies.append(e2)
	GM.combat_aoe(105.0, 100.0, 50.0, 100.0, null)
	_assert(not e1["alive"], "AoE kills enemy 1")
	_assert(not e2["alive"], "AoE kills enemy 2")

	# Damage calculation with double damage
	GM.reset_state()
	var e3 := GM.create_enemy("angel_scout")
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
		if enemy_type != "angel_scout":
			all_scouts = false
			break
	_assert(all_scouts, "Wave 1 only has angel scouts")
	_assert_eq(GM.spawn_queue.size(), 5, "Wave 1 has 5 enemies")

	# Wave 2 should have tougher enemies
	GM.wave_active = false
	GM.spawn_queue.clear()
	GM.enemies.clear()
	GM.start_wave()
	_assert_eq(GM.wave, 2, "Wave 2 started")
	var has_knight := false
	for enemy_type in GM.spawn_queue:
		if enemy_type == "holy_knight":
			has_knight = true
			break
	_assert(has_knight, "Wave 2 includes holy knights")
	_assert(GM.spawn_queue.size() > 5, "Wave 2 has more enemies than wave 1")

	GM.reset_state()

# ═══════════════════════════════════════════════════════
# GAMBLING DATA TESTS
# ═══════════════════════════════════════════════════════
func _run_gambling_data_tests() -> void:
	print("[Gambling Data]")

	# Roulette weights should sum to 100
	var roulette_total := 0
	for seg in Config.ROULETTE_SEGMENTS:
		roulette_total += seg["weight"]
	_assert_eq(roulette_total, 100, "Roulette weights sum to 100")

	# Relic weights
	var relic_total := 0
	for loot in Config.RELIC_LOOT:
		relic_total += loot["weight"]
	_assert_eq(relic_total, 100, "Relic loot weights sum to 100")

	# Dice outcomes cover 2-12
	for roll in range(2, 13):
		_assert(Config.DICE_OUTCOMES.has(roll), "Dice outcome for roll %d exists" % roll)

	# All pacts have required fields
	for pact in Config.PACT_POOL:
		_assert(pact.has("name") and pact.has("benefit") and pact.has("cost_desc"), "Pact '%s' has display fields" % pact["name"])
		_assert(pact.has("b_effect") and pact.has("c_effect"), "Pact '%s' has effect fields" % pact["name"])
