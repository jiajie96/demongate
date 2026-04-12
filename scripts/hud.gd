extends CanvasLayer

# ═══════════════════════════════════════════════════════
# UI REFERENCES
# ═══════════════════════════════════════════════════════
# Top bar
var hp_bar: ProgressBar
var hp_label: Label
var wave_label: Label
var wave_desc_label: Label
var enemies_label: Label
var dice_label: Label

# Side panel
var sins_label: Label
var tower_buttons: Dictionary = {}
var tower_info_panel: PanelContainer
var ti_name: Label
var ti_stats: Label
var btn_upgrade: Button
var btn_sell: Button
var btn_next_wave: Button
var hero_pool_label: Label

# Overlays
var menu_overlay: Control
var gameover_overlay: Control
var victory_overlay: Control
var pact_overlay: Control

var go_stats_label: Label
var vic_stats_label: Label
var pact_container: VBoxContainer

var _last_phase: String = ""

# ═══════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════
func _ready() -> void:
	_create_top_bar()
	_create_side_panel()
	_create_overlays()
	_update_overlay_visibility()

# ═══════════════════════════════════════════════════════
# TOP BAR
# ═══════════════════════════════════════════════════════
func _create_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.position = Vector2(0, 0)
	bar.size = Vector2(1100, 50)
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.08, 0.03, 0.08)
	bar.add_theme_stylebox_override("panel", bar_style)
	add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.position = Vector2(10, 5)
	hbox.size = Vector2(1080, 40)
	hbox.add_theme_constant_override("separation", 20)
	bar.add_child(hbox)

	# HP section
	var hp_box := VBoxContainer.new()
	hp_box.custom_minimum_size = Vector2(200, 40)
	hbox.add_child(hp_box)

	hp_label = Label.new()
	hp_label.text = "Hell's Core: 100 / 100"
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	hp_box.add_child(hp_label)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(200, 12)
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.2, 0.2, 0.2)
	hp_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.8, 0.13, 0.13)
	hp_bar.add_theme_stylebox_override("fill", bar_fill)
	hp_box.add_child(hp_bar)

	# Wave
	wave_label = Label.new()
	wave_label.text = "Wave 0 / 20"
	wave_label.add_theme_font_size_override("font_size", 14)
	wave_label.add_theme_color_override("font_color", Color(1, 0.8, 0))
	wave_label.custom_minimum_size = Vector2(120, 40)
	hbox.add_child(wave_label)

	# Wave desc
	wave_desc_label = Label.new()
	wave_desc_label.text = ""
	wave_desc_label.add_theme_font_size_override("font_size", 11)
	wave_desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	wave_desc_label.custom_minimum_size = Vector2(280, 40)
	hbox.add_child(wave_desc_label)

	# Enemies
	enemies_label = Label.new()
	enemies_label.text = "Enemies: 0"
	enemies_label.add_theme_font_size_override("font_size", 12)
	enemies_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	enemies_label.custom_minimum_size = Vector2(100, 40)
	hbox.add_child(enemies_label)

	# Dice
	dice_label = Label.new()
	dice_label.text = "Dice: 2 [D]"
	dice_label.add_theme_font_size_override("font_size", 12)
	dice_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	dice_label.custom_minimum_size = Vector2(100, 40)
	hbox.add_child(dice_label)

# ═══════════════════════════════════════════════════════
# SIDE PANEL
# ═══════════════════════════════════════════════════════
func _create_side_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(788, 55)
	panel.size = Vector2(305, 576)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.04, 0.1)
	panel_style.border_color = Color(0.3, 0.15, 0.3)
	panel_style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(5, 5)
	scroll.size = Vector2(295, 566)
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	# Sins display
	sins_label = Label.new()
	sins_label.text = "SINS: 100"
	sins_label.add_theme_font_size_override("font_size", 18)
	sins_label.add_theme_color_override("font_color", Config.COLOR_SINS)
	sins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sins_label)

	# Separator
	vbox.add_child(_make_separator())

	# Towers title
	var towers_title := Label.new()
	towers_title.text = "TOWERS"
	towers_title.add_theme_font_size_override("font_size", 13)
	towers_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	towers_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(towers_title)

	# Tower buttons
	for type in Config.TOWER_DATA:
		var data: Dictionary = Config.TOWER_DATA[type]
		var btn := Button.new()
		btn.text = data["name"] + " [" + data["symbol"] + "]\n" + data["desc"] + "\n" + GM.format_cost(data["cost"])
		btn.custom_minimum_size = Vector2(280, 60)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.16, 0.08, 0.16)
		btn_style.border_color = data["color"] * 0.5
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(4)
		btn_style.set_content_margin_all(6)
		btn.add_theme_stylebox_override("normal", btn_style)

		var btn_hover := btn_style.duplicate()
		btn_hover.bg_color = Color(0.22, 0.1, 0.22)
		btn_hover.border_color = data["color"]
		btn.add_theme_stylebox_override("hover", btn_hover)

		var btn_pressed := btn_style.duplicate()
		btn_pressed.bg_color = Color(0.3, 0.12, 0.3)
		btn_pressed.border_color = data["color"]
		btn.add_theme_stylebox_override("pressed", btn_pressed)

		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

		var tower_type: String = type
		btn.pressed.connect(_on_tower_button_pressed.bind(tower_type))
		vbox.add_child(btn)
		tower_buttons[type] = btn

	vbox.add_child(_make_separator())

	# Tower info panel
	tower_info_panel = PanelContainer.new()
	tower_info_panel.visible = false
	var ti_style := StyleBoxFlat.new()
	ti_style.bg_color = Color(0.12, 0.06, 0.12)
	ti_style.border_color = Color(0.4, 0.2, 0.4)
	ti_style.set_border_width_all(1)
	ti_style.set_content_margin_all(8)
	tower_info_panel.add_theme_stylebox_override("panel", ti_style)
	vbox.add_child(tower_info_panel)

	var ti_vbox := VBoxContainer.new()
	ti_vbox.add_theme_constant_override("separation", 4)
	tower_info_panel.add_child(ti_vbox)

	ti_name = Label.new()
	ti_name.add_theme_font_size_override("font_size", 13)
	ti_name.add_theme_color_override("font_color", Color(1, 0.8, 0))
	ti_vbox.add_child(ti_name)

	ti_stats = Label.new()
	ti_stats.add_theme_font_size_override("font_size", 11)
	ti_stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	ti_vbox.add_child(ti_stats)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	ti_vbox.add_child(btn_row)

	btn_upgrade = Button.new()
	btn_upgrade.text = "Upgrade"
	btn_upgrade.custom_minimum_size = Vector2(130, 30)
	btn_upgrade.add_theme_font_size_override("font_size", 11)
	btn_upgrade.pressed.connect(_on_upgrade_pressed)
	btn_row.add_child(btn_upgrade)

	btn_sell = Button.new()
	btn_sell.text = "Sell"
	btn_sell.custom_minimum_size = Vector2(130, 30)
	btn_sell.add_theme_font_size_override("font_size", 11)
	btn_sell.pressed.connect(_on_sell_pressed)
	btn_row.add_child(btn_sell)

	# Next wave button
	btn_next_wave = Button.new()
	btn_next_wave.text = "SEND NEXT WAVE"
	btn_next_wave.custom_minimum_size = Vector2(280, 35)
	btn_next_wave.visible = false
	var nw_style := StyleBoxFlat.new()
	nw_style.bg_color = Color(0.15, 0.3, 0.15)
	nw_style.border_color = Color(0.3, 0.6, 0.3)
	nw_style.set_border_width_all(1)
	nw_style.set_corner_radius_all(4)
	nw_style.set_content_margin_all(4)
	btn_next_wave.add_theme_stylebox_override("normal", nw_style)
	btn_next_wave.add_theme_font_size_override("font_size", 12)
	btn_next_wave.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	btn_next_wave.pressed.connect(_on_next_wave_pressed)
	vbox.add_child(btn_next_wave)

	# Hero pool
	hero_pool_label = Label.new()
	hero_pool_label.text = "Fallen Hero Pool: 0 / 200"
	hero_pool_label.add_theme_font_size_override("font_size", 11)
	hero_pool_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(hero_pool_label)

	# Controls help
	var help_label := Label.new()
	help_label.text = "Right-click: Deselect | D: Roll Dice\nSpace: Skip Timer | Esc: Cancel"
	help_label.add_theme_font_size_override("font_size", 10)
	help_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	vbox.add_child(help_label)

# ═══════════════════════════════════════════════════════
# OVERLAYS
# ═══════════════════════════════════════════════════════
func _create_overlays() -> void:
	# --- Main Menu ---
	menu_overlay = _make_overlay_bg()
	add_child(menu_overlay)

	var menu_panel := _make_centered_panel(400, 300)
	menu_overlay.add_child(menu_panel)

	var menu_vbox := VBoxContainer.new()
	menu_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_vbox.add_theme_constant_override("separation", 15)
	menu_panel.add_child(menu_vbox)

	var title := Label.new()
	title.text = "HELLGATE DEFENDERS"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Defend Hell's Core against\nthe Divine Army!"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_vbox.add_child(subtitle)

	var start_btn := _make_action_button("BEGIN THE DEFENSE", Color(0.8, 0.15, 0.15))
	start_btn.pressed.connect(_on_start_pressed)
	menu_vbox.add_child(start_btn)

	# --- Game Over ---
	gameover_overlay = _make_overlay_bg()
	gameover_overlay.visible = false
	add_child(gameover_overlay)

	var go_panel := _make_centered_panel(400, 250)
	gameover_overlay.add_child(go_panel)

	var go_vbox := VBoxContainer.new()
	go_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	go_vbox.add_theme_constant_override("separation", 12)
	go_panel.add_child(go_vbox)

	var go_title := Label.new()
	go_title.text = "HELL HAS FALLEN"
	go_title.add_theme_font_size_override("font_size", 24)
	go_title.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_vbox.add_child(go_title)

	go_stats_label = Label.new()
	go_stats_label.add_theme_font_size_override("font_size", 12)
	go_stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	go_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_vbox.add_child(go_stats_label)

	var restart_btn := _make_action_button("TRY AGAIN", Color(0.8, 0.15, 0.15))
	restart_btn.pressed.connect(_on_start_pressed)
	go_vbox.add_child(restart_btn)

	# --- Victory ---
	victory_overlay = _make_overlay_bg()
	victory_overlay.visible = false
	add_child(victory_overlay)

	var vic_panel := _make_centered_panel(400, 250)
	victory_overlay.add_child(vic_panel)

	var vic_vbox := VBoxContainer.new()
	vic_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vic_vbox.add_theme_constant_override("separation", 12)
	vic_panel.add_child(vic_vbox)

	var vic_title := Label.new()
	vic_title.text = "HELL ENDURES!"
	vic_title.add_theme_font_size_override("font_size", 24)
	vic_title.add_theme_color_override("font_color", Color(1, 0.8, 0))
	vic_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vic_vbox.add_child(vic_title)

	vic_stats_label = Label.new()
	vic_stats_label.add_theme_font_size_override("font_size", 12)
	vic_stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vic_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vic_vbox.add_child(vic_stats_label)

	var play_again_btn := _make_action_button("PLAY AGAIN", Color(0.15, 0.6, 0.15))
	play_again_btn.pressed.connect(_on_start_pressed)
	vic_vbox.add_child(play_again_btn)

	# --- Pact ---
	pact_overlay = _make_overlay_bg()
	pact_overlay.visible = false
	add_child(pact_overlay)

	var pact_panel := _make_centered_panel(500, 380)
	pact_overlay.add_child(pact_panel)

	var pact_vbox := VBoxContainer.new()
	pact_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pact_vbox.add_theme_constant_override("separation", 10)
	pact_panel.add_child(pact_vbox)

	var pact_title := Label.new()
	pact_title.text = "DEMONIC PACT"
	pact_title.add_theme_font_size_override("font_size", 20)
	pact_title.add_theme_color_override("font_color", Color(0.8, 0.267, 1))
	pact_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pact_vbox.add_child(pact_title)

	var pact_desc := Label.new()
	pact_desc.text = "Choose a pact — great power at great cost."
	pact_desc.add_theme_font_size_override("font_size", 11)
	pact_desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	pact_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pact_vbox.add_child(pact_desc)

	pact_container = VBoxContainer.new()
	pact_container.add_theme_constant_override("separation", 8)
	pact_vbox.add_child(pact_container)

	var decline_btn := _make_action_button("No Deal", Color(0.4, 0.4, 0.4))
	decline_btn.pressed.connect(_on_decline_pact_pressed)
	pact_vbox.add_child(decline_btn)

# ═══════════════════════════════════════════════════════
# PROCESS — UPDATE UI FROM STATE
# ═══════════════════════════════════════════════════════
func _process(_dt: float) -> void:
	_update_overlay_visibility()

	if GM.phase == "menu":
		return

	# Top bar
	hp_bar.max_value = GM.core_max_hp
	hp_bar.value = GM.core_hp
	hp_label.text = "Hell's Core: " + str(roundi(GM.core_hp)) + " / " + str(roundi(GM.core_max_hp))
	wave_label.text = "Wave " + str(GM.wave) + " / " + str(Config.MAX_WAVES)
	enemies_label.text = "Enemies: " + str(GM.enemies.size())
	dice_label.text = "Dice: " + str(GM.dice_uses_left) + " [D]"

	if GM.wave_active:
		wave_desc_label.text = GM.wave_desc
	elif GM.show_pact:
		wave_desc_label.text = "Demonic Pact offered!"
	else:
		var t := ceili(GM.between_wave_timer)
		wave_desc_label.text = "Next wave in " + str(t) + "s... (Space to skip)" if t > 0 else ""

	# Sins
	sins_label.text = "SINS: " + str(GM.sins)

	# Tower button affordability
	for type in Config.TOWER_DATA:
		if tower_buttons.has(type):
			var data: Dictionary = Config.TOWER_DATA[type]
			var can_buy := GM.can_afford(data["cost"]) or GM.free_towers > 0
			tower_buttons[type].modulate.a = 1.0 if can_buy else 0.5

	# Next wave button
	btn_next_wave.visible = not GM.wave_active and not GM.show_pact and GM.phase == "playing"

	# Tower info
	if GM.selected_tower != null:
		tower_info_panel.visible = true
		var t: Dictionary = GM.selected_tower
		var data: Dictionary = Config.TOWER_DATA[t["type"]]
		ti_name.text = t["name"] + " (Lv." + str(t["level"]) + ")"
		ti_stats.text = "DMG: " + str(snappedf(t["damage"] * t["damage_mult"], 0.1)) + " | RNG: " + str(roundi(t["range"])) + " | SPD: " + str(snappedf(t["attack_speed"], 0.1)) + "/s"

		if t["level"] >= Config.MAX_TOWER_LEVEL:
			btn_upgrade.text = "MAX LEVEL"
			btn_upgrade.disabled = true
		else:
			var cost: int = roundi(data["upgrade_cost"] * pow(1.5, t["level"] - 1))
			btn_upgrade.text = "Upgrade (" + GM.format_cost(cost) + ")"
			btn_upgrade.disabled = not GM.can_afford(cost)

		var refund: int = roundi(data["cost"] * Config.SELL_REFUND * t["level"])
		btn_sell.text = "Sell (+" + GM.format_cost(refund) + ")"
	else:
		tower_info_panel.visible = false

	# Hero pool
	hero_pool_label.text = "Fallen Hero Pool: " + str(GM.fallen_hero_pool) + " / " + str(GM.hero_threshold())

	# End screen stats
	if GM.phase == "gameover":
		go_stats_label.text = "Wave: " + str(GM.wave) + " | Kills: " + str(GM.stats["enemies_killed"]) + " | Towers: " + str(GM.stats["towers_placed"])
	elif GM.phase == "victory":
		vic_stats_label.text = "Kills: " + str(GM.stats["enemies_killed"]) + " | Towers: " + str(GM.stats["towers_placed"])

# ═══════════════════════════════════════════════════════
# OVERLAY VISIBILITY
# ═══════════════════════════════════════════════════════
func _update_overlay_visibility() -> void:
	menu_overlay.visible = GM.phase == "menu"
	gameover_overlay.visible = GM.phase == "gameover"
	victory_overlay.visible = GM.phase == "victory"
	pact_overlay.visible = GM.show_pact

	# Populate pact choices when shown
	if GM.show_pact and pact_container.get_child_count() == 0:
		_populate_pact_choices()

	# Clean up when hidden
	if not GM.show_pact and pact_container.get_child_count() > 0:
		for child in pact_container.get_children():
			child.queue_free()

func _populate_pact_choices() -> void:
	for child in pact_container.get_children():
		child.queue_free()

	for pact in GM.pact_choices:
		var btn := Button.new()
		btn.text = pact["name"] + "\n+ " + pact["benefit"] + "\n- " + pact["cost_desc"]
		btn.custom_minimum_size = Vector2(450, 65)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var pact_style := StyleBoxFlat.new()
		pact_style.bg_color = Color(0.15, 0.06, 0.2)
		pact_style.border_color = Color(0.5, 0.2, 0.6)
		pact_style.set_border_width_all(1)
		pact_style.set_corner_radius_all(4)
		pact_style.set_content_margin_all(8)
		btn.add_theme_stylebox_override("normal", pact_style)

		var pact_hover := pact_style.duplicate()
		pact_hover.bg_color = Color(0.25, 0.1, 0.3)
		btn.add_theme_stylebox_override("hover", pact_hover)

		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

		var p: Dictionary = pact
		btn.pressed.connect(_on_pact_accepted.bind(p))
		pact_container.add_child(btn)

# ═══════════════════════════════════════════════════════
# BUTTON HANDLERS
# ═══════════════════════════════════════════════════════
func _on_start_pressed() -> void:
	GM.reset_state()

func _on_tower_button_pressed(tower_type: String) -> void:
	GM.selected_tower_type = tower_type
	GM.selected_tower = null

func _on_upgrade_pressed() -> void:
	if GM.selected_tower != null:
		GM.upgrade_tower(GM.selected_tower)

func _on_sell_pressed() -> void:
	if GM.selected_tower != null:
		GM.sell_tower(GM.selected_tower)

func _on_next_wave_pressed() -> void:
	if GM.phase == "playing" and not GM.wave_active and not GM.show_pact:
		GM.between_wave_timer = 0

func _on_pact_accepted(pact: Dictionary) -> void:
	GM.accept_pact(pact)

func _on_decline_pact_pressed() -> void:
	GM.decline_pact()

# ═══════════════════════════════════════════════════════
# UI HELPERS
# ═══════════════════════════════════════════════════════
func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	return sep

func _make_overlay_bg() -> ColorRect:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1100, 650)
	bg.color = Color(0, 0, 0, 0.75)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	return bg

func _make_centered_panel(w: float, h: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2((1100 - w) / 2.0, (650 - h) / 2.0)
	panel.size = Vector2(w, h)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.03, 0.08)
	style.border_color = Color(0.4, 0.15, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _make_action_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(250, 40)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = color * 1.3
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color.WHITE)
	return btn
