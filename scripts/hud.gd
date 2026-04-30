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
var menu_btn: Button

# Side panel
var sins_label: Label
var tower_buttons: Dictionary = {}
var tower_style_idle: Dictionary = {}        # type -> StyleBoxFlat (dim/unavailable)
var tower_style_ready: Dictionary = {}       # type -> StyleBoxFlat (affordable highlight)
var tower_info_panel: PanelContainer
var dice_section: PanelContainer
var dice_title_label: Label
var dice_desc_label: Label
var btn_dice_roll: Button
var ti_name: Label
var ti_desc: Label
var ti_role: Label
var ti_stats: Label
var btn_upgrade: Button
var btn_sell: Button
var btn_targeting: Button
var btn_next_wave: Button
var hero_pool_label: Label
var towers_title: Label
var help_label: Label
var speed_buttons: Array = []

# Overlays
var menu_overlay: Control
var gameover_overlay: Control
var victory_overlay: Control
var settings_overlay: Control

var go_stats_label: Label
var vic_stats_label: Label
var pandora_overlay: Control

# Menu overlay refs for locale
var menu_title: Label
var menu_subtitle: Label
var menu_start_btn: Button
var menu_lang_btn: Button

# Game over overlay refs
var go_title: Label
var go_restart_btn: Button

# Victory overlay refs
var vic_title: Label
var vic_play_again_btn: Button

# Settings overlay refs
var settings_title: Label
var btn_pause: Button
var btn_restart: Button
var btn_lang: Button
var btn_close_settings: Button
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var master_label: Label
var music_label: Label
var sfx_label: Label

# ═══════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════
func _ready() -> void:
	_create_top_bar()
	_create_side_panel()
	_create_overlays()
	_create_settings_overlay()
	_update_overlay_visibility()
	_disable_focus(self)

# ═══════════════════════════════════════════════════════
# TOP BAR
# ═══════════════════════════════════════════════════════
func _create_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.position = Vector2(0, 0)
	bar.size = Vector2(Config.GAME_WIDTH + 332, 50)
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.12, 0.05, 0.07)
	bar.add_theme_stylebox_override("panel", bar_style)
	add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.position = Vector2(10, 5)
	hbox.size = Vector2(Config.GAME_WIDTH + 312, 40)
	hbox.add_theme_constant_override("separation", 20)
	bar.add_child(hbox)

	# HP section
	var hp_box := VBoxContainer.new()
	hp_box.custom_minimum_size = Vector2(200, 40)
	hbox.add_child(hp_box)

	hp_label = Label.new()
	hp_label.text = ""
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
	wave_label.text = ""
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
	enemies_label.text = ""
	enemies_label.add_theme_font_size_override("font_size", 12)
	enemies_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	enemies_label.custom_minimum_size = Vector2(120, 40)
	hbox.add_child(enemies_label)

	# Speed buttons
	var speed_container := HBoxContainer.new()
	speed_container.add_theme_constant_override("separation", 2)
	for spd in [0.5, 1.0, 2.0]:
		var sbtn := Button.new()
		sbtn.text = str(spd) + "x"
		sbtn.custom_minimum_size = Vector2(38, 28)
		sbtn.add_theme_font_size_override("font_size", 10)
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.18, 0.1, 0.12)
		s.border_color = Color(0.4, 0.22, 0.25)
		s.set_border_width_all(1)
		s.set_corner_radius_all(3)
		s.set_content_margin_all(2)
		sbtn.add_theme_stylebox_override("normal", s)
		sbtn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		sbtn.pressed.connect(_on_speed_pressed.bind(spd))
		speed_container.add_child(sbtn)
		speed_buttons.append(sbtn)
	hbox.add_child(speed_container)

	# Menu button (☰)
	menu_btn = Button.new()
	menu_btn.text = "☰"
	menu_btn.custom_minimum_size = Vector2(40, 32)
	var mb_style := StyleBoxFlat.new()
	mb_style.bg_color = Color(0.18, 0.1, 0.12)
	mb_style.border_color = Color(0.4, 0.22, 0.25)
	mb_style.set_border_width_all(1)
	mb_style.set_corner_radius_all(4)
	mb_style.set_content_margin_all(2)
	menu_btn.add_theme_stylebox_override("normal", mb_style)
	var mb_hover := mb_style.duplicate()
	mb_hover.bg_color = Color(0.3, 0.16, 0.2)
	mb_hover.border_color = Color(0.55, 0.3, 0.35)
	menu_btn.add_theme_stylebox_override("hover", mb_hover)
	menu_btn.add_theme_font_size_override("font_size", 18)
	menu_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	menu_btn.pressed.connect(_on_menu_btn_pressed)
	hbox.add_child(menu_btn)

# ═══════════════════════════════════════════════════════
# SIDE PANEL
# ═══════════════════════════════════════════════════════
func _create_side_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(Config.GAME_WIDTH + 20, 55)
	panel.size = Vector2(305, Config.GAME_HEIGHT)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.06, 0.08)
	panel_style.border_color = Color(0.3, 0.16, 0.2)
	panel_style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(5, 5)
	scroll.size = Vector2(295, Config.GAME_HEIGHT - 10)
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	# Sins display
	sins_label = Label.new()
	sins_label.text = ""
	sins_label.add_theme_font_size_override("font_size", 18)
	sins_label.add_theme_color_override("font_color", Config.COLOR_SINS)
	sins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sins_label)

	# Separator
	vbox.add_child(_make_separator())

	# Towers title
	towers_title = Label.new()
	towers_title.text = Locale.t("TOWERS")
	towers_title.add_theme_font_size_override("font_size", 13)
	towers_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	towers_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(towers_title)

	# Tower buttons
	for type in Config.TOWER_DATA:
		var data: Dictionary = Config.TOWER_DATA[type]

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(280, 0)
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)

		# Avatar — drawn mini tower icon
		var icon: Control = preload("res://scripts/tower_icon.gd").new()
		icon.tower_type = type
		icon.tower_color = data["color"]
		icon.custom_minimum_size = Vector2(44, 44)
		row.add_child(icon)

		# Tower button (compact by default — no desc)
		var btn := Button.new()
		btn.text = _tower_button_text(data, false)
		btn.custom_minimum_size = Vector2(230, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		# Idle style — dim border, faded bg (used for unaffordable / locked)
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.15, 0.08, 0.1)
		btn_style.border_color = data["color"] * 0.5
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(4)
		btn_style.set_content_margin_all(6)
		btn.add_theme_stylebox_override("normal", btn_style)

		# Ready style — full-saturation tower-color border, warmer bg, 2px width.
		# Inset accent line + tinted background communicate "you can buy this now".
		var ready_style: StyleBoxFlat = btn_style.duplicate()
		ready_style.bg_color = Color(0.22, 0.12, 0.14).lerp(data["color"], 0.12)
		ready_style.border_color = data["color"]
		ready_style.set_border_width_all(2)
		ready_style.shadow_color = Color(data["color"].r, data["color"].g, data["color"].b, 0.35)
		ready_style.shadow_size = 3
		ready_style.shadow_offset = Vector2.ZERO

		var btn_hover := ready_style.duplicate()
		btn_hover.bg_color = Color(0.30, 0.16, 0.18).lerp(data["color"], 0.15)
		btn.add_theme_stylebox_override("hover", btn_hover)

		var btn_pressed := ready_style.duplicate()
		btn_pressed.bg_color = Color(0.38, 0.20, 0.22).lerp(data["color"], 0.20)
		btn.add_theme_stylebox_override("pressed", btn_pressed)

		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

		tower_style_idle[type] = btn_style
		tower_style_ready[type] = ready_style

		var tower_type: String = type
		btn.pressed.connect(_on_tower_button_pressed.bind(tower_type))
		row.add_child(btn)
		tower_buttons[type] = btn

	vbox.add_child(_make_separator())

	# Tower info panel
	tower_info_panel = PanelContainer.new()
	tower_info_panel.visible = false
	var ti_style := StyleBoxFlat.new()
	ti_style.bg_color = Color(0.12, 0.07, 0.09)
	ti_style.border_color = Color(0.4, 0.22, 0.25)
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

	ti_desc = Label.new()
	ti_desc.add_theme_font_size_override("font_size", 10)
	ti_desc.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55))
	ti_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	ti_vbox.add_child(ti_desc)

	ti_role = Label.new()
	ti_role.add_theme_font_size_override("font_size", 10)
	ti_role.add_theme_color_override("font_color", Color(0.5, 0.75, 0.9))
	ti_vbox.add_child(ti_role)

	ti_stats = Label.new()
	ti_stats.add_theme_font_size_override("font_size", 11)
	ti_stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	ti_vbox.add_child(ti_stats)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	ti_vbox.add_child(btn_row)

	btn_upgrade = Button.new()
	btn_upgrade.text = Locale.t("Upgrade")
	btn_upgrade.custom_minimum_size = Vector2(130, 30)
	btn_upgrade.add_theme_font_size_override("font_size", 11)
	btn_upgrade.pressed.connect(_on_upgrade_pressed)
	btn_row.add_child(btn_upgrade)

	btn_sell = Button.new()
	btn_sell.text = Locale.t("Sell")
	btn_sell.custom_minimum_size = Vector2(130, 30)
	btn_sell.add_theme_font_size_override("font_size", 11)
	btn_sell.pressed.connect(_on_sell_pressed)
	btn_row.add_child(btn_sell)

	btn_targeting = Button.new()
	btn_targeting.text = "Target: Closest"
	btn_targeting.custom_minimum_size = Vector2(268, 28)
	btn_targeting.add_theme_font_size_override("font_size", 11)
	btn_targeting.pressed.connect(_on_targeting_pressed)
	ti_vbox.add_child(btn_targeting)

	# Next wave button
	btn_next_wave = Button.new()
	btn_next_wave.text = Locale.t("SEND NEXT WAVE")
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

	# Devil's Dice section
	vbox.add_child(_make_separator())

	dice_section = PanelContainer.new()
	var dice_style := StyleBoxFlat.new()
	dice_style.bg_color = Color(0.14, 0.08, 0.06)
	dice_style.border_color = Color(0.6, 0.35, 0.1)
	dice_style.set_border_width_all(1)
	dice_style.set_corner_radius_all(4)
	dice_style.set_content_margin_all(8)
	dice_section.add_theme_stylebox_override("panel", dice_style)
	vbox.add_child(dice_section)

	var dice_vbox := VBoxContainer.new()
	dice_vbox.add_theme_constant_override("separation", 4)
	dice_section.add_child(dice_vbox)

	dice_title_label = Label.new()
	dice_title_label.text = Locale.tf("dice_title", {"count": 2})
	dice_title_label.add_theme_font_size_override("font_size", 13)
	dice_title_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	dice_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice_vbox.add_child(dice_title_label)

	dice_desc_label = Label.new()
	dice_desc_label.text = Locale.t("Roll during battle! High = blessing, low = curse.")
	dice_desc_label.add_theme_font_size_override("font_size", 10)
	dice_desc_label.add_theme_color_override("font_color", Color(0.65, 0.55, 0.4))
	dice_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	dice_vbox.add_child(dice_desc_label)

	btn_dice_roll = Button.new()
	btn_dice_roll.text = Locale.t("ROLL THE DICE")
	btn_dice_roll.custom_minimum_size = Vector2(260, 32)
	var dr_style := StyleBoxFlat.new()
	dr_style.bg_color = Color(0.5, 0.28, 0.08)
	dr_style.border_color = Color(0.8, 0.5, 0.15)
	dr_style.set_border_width_all(1)
	dr_style.set_corner_radius_all(4)
	dr_style.set_content_margin_all(4)
	btn_dice_roll.add_theme_stylebox_override("normal", dr_style)
	var dr_hover := dr_style.duplicate()
	dr_hover.bg_color = Color(0.65, 0.35, 0.1)
	dr_hover.border_color = Color(1.0, 0.6, 0.2)
	btn_dice_roll.add_theme_stylebox_override("hover", dr_hover)
	var dr_disabled := dr_style.duplicate()
	dr_disabled.bg_color = Color(0.2, 0.15, 0.1)
	dr_disabled.border_color = Color(0.3, 0.25, 0.15)
	btn_dice_roll.add_theme_stylebox_override("disabled", dr_disabled)
	btn_dice_roll.add_theme_font_size_override("font_size", 12)
	btn_dice_roll.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	btn_dice_roll.pressed.connect(_on_dice_roll_pressed)
	dice_vbox.add_child(btn_dice_roll)

	# Hero pool
	hero_pool_label = Label.new()
	hero_pool_label.text = ""
	hero_pool_label.add_theme_font_size_override("font_size", 11)
	hero_pool_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(hero_pool_label)

	# Controls help
	help_label = Label.new()
	help_label.text = Locale.t("4-9: Towers | U: Upgrade | X: Sell | T: Target | P: Pause\nSpace: Skip | Tab: Overview | D: Dice | Esc: Cancel")
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

	var menu_panel := _make_centered_panel(400, 340)
	menu_overlay.add_child(menu_panel)

	var menu_vbox := VBoxContainer.new()
	menu_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_vbox.add_theme_constant_override("separation", 15)
	menu_panel.add_child(menu_vbox)

	menu_title = Label.new()
	menu_title.text = Locale.t("HELLGATE DEFENDERS")
	menu_title.add_theme_font_size_override("font_size", 28)
	menu_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_vbox.add_child(menu_title)

	menu_subtitle = Label.new()
	menu_subtitle.text = Locale.t("Defend Hell's Core against\nthe Divine Army!")
	menu_subtitle.add_theme_font_size_override("font_size", 14)
	menu_subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_vbox.add_child(menu_subtitle)

	menu_start_btn = _make_action_button(Locale.t("BEGIN THE DEFENSE"), Color(0.8, 0.15, 0.15))
	menu_start_btn.pressed.connect(_on_start_pressed)
	menu_vbox.add_child(menu_start_btn)

	# Language button on main menu
	menu_lang_btn = _make_action_button(Locale.lang_display(), Color(0.25, 0.2, 0.35))
	menu_lang_btn.pressed.connect(_on_lang_toggle_pressed)
	menu_vbox.add_child(menu_lang_btn)

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

	go_title = Label.new()
	go_title.text = Locale.t("HELL HAS FALLEN")
	go_title.add_theme_font_size_override("font_size", 24)
	go_title.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_vbox.add_child(go_title)

	go_stats_label = Label.new()
	go_stats_label.add_theme_font_size_override("font_size", 12)
	go_stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	go_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_vbox.add_child(go_stats_label)

	go_restart_btn = _make_action_button(Locale.t("TRY AGAIN"), Color(0.8, 0.15, 0.15))
	go_restart_btn.pressed.connect(_on_start_pressed)
	go_vbox.add_child(go_restart_btn)

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

	vic_title = Label.new()
	vic_title.text = Locale.t("HELL ENDURES!")
	vic_title.add_theme_font_size_override("font_size", 24)
	vic_title.add_theme_color_override("font_color", Color(1, 0.8, 0))
	vic_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vic_vbox.add_child(vic_title)

	vic_stats_label = Label.new()
	vic_stats_label.add_theme_font_size_override("font_size", 12)
	vic_stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vic_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vic_vbox.add_child(vic_stats_label)

	vic_play_again_btn = _make_action_button(Locale.t("PLAY AGAIN"), Color(0.15, 0.6, 0.15))
	vic_play_again_btn.pressed.connect(_on_start_pressed)
	vic_vbox.add_child(vic_play_again_btn)

	# --- Pandora's True Gift choice ---
	pandora_overlay = _make_overlay_bg()
	pandora_overlay.visible = false
	add_child(pandora_overlay)

	var pan_panel := _make_centered_panel(420, 220)
	pandora_overlay.add_child(pan_panel)

	var pan_vbox := VBoxContainer.new()
	pan_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pan_vbox.add_theme_constant_override("separation", 12)
	pan_panel.add_child(pan_vbox)

	var pan_title := Label.new()
	pan_title.text = Locale.t("PANDORA'S TRUE GIFT")
	pan_title.add_theme_font_size_override("font_size", 20)
	pan_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	pan_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pan_vbox.add_child(pan_title)

	var pan_desc := Label.new()
	pan_desc.text = Locale.t("Choose your reward wisely.")
	pan_desc.add_theme_font_size_override("font_size", 11)
	pan_desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	pan_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pan_vbox.add_child(pan_desc)

	var pan_btns := HBoxContainer.new()
	pan_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	pan_btns.add_theme_constant_override("separation", 16)
	pan_vbox.add_child(pan_btns)

	var btn_dmg := _make_action_button(Locale.t("2x Damage (1 wave)"), Color(0.8, 0.2, 0.15))
	btn_dmg.custom_minimum_size = Vector2(180, 50)
	btn_dmg.pressed.connect(_on_pandora_choice.bind(0))
	pan_btns.add_child(btn_dmg)

	var btn_sins := _make_action_button(Locale.t("+100 Sins"), Color(0.5, 0.2, 0.7))
	btn_sins.custom_minimum_size = Vector2(180, 50)
	btn_sins.pressed.connect(_on_pandora_choice.bind(1))
	pan_btns.add_child(btn_sins)

# ═══════════════════════════════════════════════════════
# SETTINGS OVERLAY
# ═══════════════════════════════════════════════════════
func _create_settings_overlay() -> void:
	settings_overlay = _make_overlay_bg()
	settings_overlay.visible = false
	add_child(settings_overlay)

	var panel := _make_centered_panel(360, 440)
	settings_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	settings_title = Label.new()
	settings_title.text = Locale.t("SETTINGS")
	settings_title.add_theme_font_size_override("font_size", 22)
	settings_title.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(settings_title)

	# Volume sliders — Master / Music / SFX
	master_label = _make_slider_label("Master")
	vbox.add_child(master_label)
	master_slider = _make_volume_slider(Audio.master_volume)
	master_slider.value_changed.connect(_on_master_volume_changed)
	vbox.add_child(master_slider)

	music_label = _make_slider_label("Music")
	vbox.add_child(music_label)
	music_slider = _make_volume_slider(Audio.music_volume)
	music_slider.value_changed.connect(_on_music_volume_changed)
	vbox.add_child(music_slider)

	sfx_label = _make_slider_label("SFX")
	vbox.add_child(sfx_label)
	sfx_slider = _make_volume_slider(Audio.sfx_volume)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	vbox.add_child(sfx_slider)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 4
	vbox.add_child(spacer)

	btn_pause = _make_action_button(Locale.t("Pause"), Color(0.2, 0.35, 0.5))
	btn_pause.pressed.connect(_on_pause_pressed)
	vbox.add_child(btn_pause)

	btn_restart = _make_action_button(Locale.t("Restart"), Color(0.6, 0.2, 0.2))
	btn_restart.pressed.connect(_on_settings_restart_pressed)
	vbox.add_child(btn_restart)

	btn_lang = _make_action_button(Locale.lang_display(), Color(0.25, 0.2, 0.35))
	btn_lang.pressed.connect(_on_lang_toggle_pressed)
	vbox.add_child(btn_lang)

	btn_close_settings = _make_action_button(Locale.t("Close"), Color(0.35, 0.35, 0.35))
	btn_close_settings.pressed.connect(_on_close_settings_pressed)
	vbox.add_child(btn_close_settings)

func _make_slider_label(title: String) -> Label:
	var lbl := Label.new()
	lbl.text = Locale.t(title) + ": 100%"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	lbl.set_meta("title", title)
	return lbl

func _make_volume_slider(initial_value: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial_value
	slider.custom_minimum_size = Vector2(260, 20)
	return slider

func _on_master_volume_changed(value: float) -> void:
	Audio.set_master_volume(value)
	_update_volume_labels()
	Audio.save_settings()

func _on_music_volume_changed(value: float) -> void:
	Audio.set_music_volume(value)
	_update_volume_labels()
	Audio.save_settings()

func _on_sfx_volume_changed(value: float) -> void:
	Audio.set_sfx_volume(value)
	_update_volume_labels()
	Audio.save_settings()

func _update_volume_labels() -> void:
	if master_label:
		master_label.text = Locale.t(master_label.get_meta("title")) + ": " + str(int(Audio.master_volume * 100)) + "%"
	if music_label:
		music_label.text = Locale.t(music_label.get_meta("title")) + ": " + str(int(Audio.music_volume * 100)) + "%"
	if sfx_label:
		sfx_label.text = Locale.t(sfx_label.get_meta("title")) + ": " + str(int(Audio.sfx_volume * 100)) + "%"

# ═══════════════════════════════════════════════════════
# PROCESS — UPDATE UI FROM STATE
# ═══════════════════════════════════════════════════════
func _process(_dt: float) -> void:
	_update_overlay_visibility()
	_update_locale_text()

	if GM.phase == "menu":
		return

	# Top bar
	hp_bar.max_value = GM.core_max_hp
	hp_bar.value = GM.core_hp
	hp_label.text = Locale.tf("hells_core", {"hp": roundi(GM.core_hp), "max": roundi(GM.core_max_hp)})
	wave_label.text = Locale.tf("wave_progress", {"wave": GM.wave, "max": Config.MAX_WAVES})
	enemies_label.text = Locale.tf("enemies_count", {"count": GM.enemies.size()})

	# Speed button highlight
	var spd_vals := [0.5, 1.0, 2.0]
	for i in range(speed_buttons.size()):
		speed_buttons[i].modulate = Color.WHITE if GM.game_speed == spd_vals[i] else Color(0.5, 0.5, 0.5)

	if GM.wave_active:
		wave_desc_label.text = Locale.t(GM.wave_desc)
	else:
		var t := ceili(GM.between_wave_timer)
		var timer_text: String = Locale.tf("next_wave_timer", {"time": t}) if t > 0 else ""
		var next_idx: int = GM.wave
		if next_idx < Config.WAVE_DATA.size():
			var preview := _build_wave_preview(next_idx)
			wave_desc_label.text = timer_text + "\n" + preview if timer_text != "" else preview
		else:
			wave_desc_label.text = timer_text

	# Sins
	sins_label.text = Locale.tf("sins_display", {"amount": GM.sins})

	# Tower button affordability + uniqueness (show desc only when Tab/overview held)
	var show_details := GM.show_overview
	for type in Config.TOWER_DATA:
		if tower_buttons.has(type):
			var data: Dictionary = Config.TOWER_DATA[type]
			var btn: Button = tower_buttons[type]
			var at_limit: bool = data.get("unique", false) and GM.has_tower_type(type)
			var can_afford: bool = GM.can_afford(data["cost"]) or GM.free_towers > 0
			if at_limit:
				# Locked — already owned and capped (e.g., Lucifer)
				btn.modulate = Color(1.0, 0.45, 0.45, 0.55)
				btn.add_theme_stylebox_override("normal", tower_style_idle[type])
				btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
				btn.text = _tower_button_text(data, show_details) + "  [MAX]"
			elif not can_afford:
				btn.modulate = Color(1, 1, 1, 0.5)
				btn.add_theme_stylebox_override("normal", tower_style_idle[type])
				btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				btn.text = _tower_button_text(data, show_details)
			else:
				# Ready — bright color border, warm bg, glow shadow, white font
				btn.modulate = Color(1, 1, 1, 1)
				btn.add_theme_stylebox_override("normal", tower_style_ready[type])
				btn.add_theme_color_override("font_color", Color(1, 0.97, 0.85))
				btn.text = _tower_button_text(data, show_details)

	# Next wave button
	btn_next_wave.visible = not GM.wave_active and GM.phase == "playing"

	# Tower info
	if GM.selected_tower != null:
		tower_info_panel.visible = true
		var tw: Dictionary = GM.selected_tower
		var data: Dictionary = Config.TOWER_DATA[tw["type"]]
		ti_name.text = Locale.tf("tower_level", {"name": Locale.t(tw["name"]), "level": tw["level"]})
		ti_desc.text = Locale.t(data["desc"])
		# Tower role tag — short label indicating strategic function
		var role_text: String = ""
		if tw.get("is_global", false):
			role_text = Locale.t("Role: Global Pulse — damages all enemies on screen")
		elif tw.get("is_support", false):
			role_text = Locale.t("Role: Support — buffs nearby towers and damages enemies")
		elif tw.get("is_beam_cone", false):
			role_text = Locale.t("Role: Area Denial — continuous frost cone in one direction")
		elif tw.get("is_aoe", false):
			role_text = Locale.t("Role: Swarm Clearer — AoE damage hits groups")
		elif tw["type"] == "soul_reaper":
			role_text = Locale.t("Role: Force Multiplier — slows enemies in aura range")
		else:
			role_text = Locale.t("Role: Single-Target DPS — fast reliable damage")
		ti_role.text = role_text
		var effective_dmg: float = tw["damage"] * tw["damage_mult"]
		if GM.double_damage > 0:
			effective_dmg *= 2.0
		var effective_spd: float = tw["attack_speed"] * GM.perm_speed_buff
		if tw["hades_buffed"]:
			effective_spd *= 1.5
		var dps: float = effective_dmg * effective_spd
		# Support towers deal damage on buff cycle, not via attack_speed
		if tw["is_support"] and tw["damage"] > 0 and tw["buff_cooldown"] > 0:
			dps = effective_dmg / tw["buff_cooldown"]
		ti_stats.text = Locale.tf("tower_stats", {
			"dmg": snappedf(effective_dmg, 0.1),
			"rng": roundi(tw["range"]),
			"spd": snappedf(effective_spd, 0.1),
			"dps": snappedf(dps, 0.1),
		})

		if tw["level"] >= Config.MAX_TOWER_LEVEL:
			btn_upgrade.text = Locale.t("MAX LEVEL")
			btn_upgrade.disabled = true
		else:
			var cost: int = roundi(data["upgrade_cost"] * pow(1.5, tw["level"] - 1))
			btn_upgrade.text = Locale.tf("upgrade_cost", {"cost": GM.format_cost(cost)})
			btn_upgrade.disabled = not GM.can_afford(cost)

		var refund: int = roundi(data["cost"] * Config.SELL_REFUND * tw["level"])
		btn_sell.text = Locale.tf("sell_refund", {"cost": GM.format_cost(refund)})

		var mode: String = tw.get("targeting_mode", "closest")
		btn_targeting.text = Locale.t("Target") + ": " + mode.capitalize()
		btn_targeting.visible = not tw["is_support"]
	else:
		tower_info_panel.visible = false

	# Hero pool
	hero_pool_label.text = Locale.tf("hero_pool", {"pool": GM.fallen_hero_pool, "threshold": GM.hero_threshold()})

	# Dice section
	dice_title_label.text = Locale.tf("dice_title", {"count": GM.dice_uses_left})
	dice_desc_label.text = Locale.t("Roll during battle! High = blessing, low = curse.")
	var can_roll := GM.wave_active and GM.dice_uses_left > 0
	btn_dice_roll.disabled = not can_roll
	if GM.dice_uses_left <= 0:
		btn_dice_roll.text = Locale.t("No dice left")
	elif not GM.wave_active:
		btn_dice_roll.text = Locale.t("Only during waves")
	else:
		btn_dice_roll.text = Locale.t("ROLL THE DICE")

	# End screen stats
	if GM.phase == "gameover":
		go_stats_label.text = Locale.tf("gameover_stats", {"wave": GM.wave, "kills": GM.stats["enemies_killed"], "towers": GM.stats["towers_placed"]})
	elif GM.phase == "victory":
		vic_stats_label.text = Locale.tf("victory_stats", {"kills": GM.stats["enemies_killed"], "towers": GM.stats["towers_placed"]})

	# Settings pause button text
	if settings_overlay.visible:
		btn_pause.text = Locale.t("Resume") if GM.paused else Locale.t("Pause")

# ═══════════════════════════════════════════════════════
# LOCALE TEXT — update text that was set once at creation
# ═══════════════════════════════════════════════════════
func _update_locale_text() -> void:
	towers_title.text = Locale.t("TOWERS")
	btn_next_wave.text = Locale.t("SEND NEXT WAVE")
	help_label.text = Locale.t("4-9: Towers | U: Upgrade | X: Sell | T: Target | P: Pause\nSpace: Skip | Tab: Overview | D: Dice | Esc: Cancel")

	# Menu overlay
	menu_title.text = Locale.t("HELLGATE DEFENDERS")
	menu_subtitle.text = Locale.t("Defend Hell's Core against\nthe Divine Army!")
	menu_start_btn.text = Locale.t("BEGIN THE DEFENSE")
	menu_lang_btn.text = Locale.lang_display()

	# Game over
	go_title.text = Locale.t("HELL HAS FALLEN")
	go_restart_btn.text = Locale.t("TRY AGAIN")

	# Victory
	vic_title.text = Locale.t("HELL ENDURES!")
	vic_play_again_btn.text = Locale.t("PLAY AGAIN")

	# Settings
	settings_title.text = Locale.t("SETTINGS")
	btn_restart.text = Locale.t("Restart")
	btn_lang.text = Locale.lang_display()
	btn_close_settings.text = Locale.t("Close")
	_update_volume_labels()

# ═══════════════════════════════════════════════════════
# OVERLAY VISIBILITY
# ═══════════════════════════════════════════════════════
func _update_overlay_visibility() -> void:
	menu_overlay.visible = GM.phase == "menu"
	gameover_overlay.visible = GM.phase == "gameover"
	victory_overlay.visible = GM.phase == "victory"
	pandora_overlay.visible = GM.pending_pandora_choice

# ═══════════════════════════════════════════════════════
# BUTTON HANDLERS
# ═══════════════════════════════════════════════════════
func _on_start_pressed() -> void:
	Audio.play_sfx("ui_click")
	settings_overlay.visible = false
	GM.reset_state()

func _on_tower_button_pressed(tower_type: String) -> void:
	Audio.play_sfx("ui_click")
	GM.selected_tower_type = tower_type
	GM.selected_tower = null

func _on_upgrade_pressed() -> void:
	Audio.play_sfx("ui_click")
	if GM.selected_tower != null:
		GM.upgrade_tower(GM.selected_tower)

func _on_sell_pressed() -> void:
	Audio.play_sfx("ui_click")
	if GM.selected_tower != null:
		GM.sell_tower(GM.selected_tower)

func _on_targeting_pressed() -> void:
	Audio.play_sfx("ui_click")
	if GM.selected_tower != null:
		GM.cycle_targeting(GM.selected_tower)

func _on_speed_pressed(speed: float) -> void:
	Audio.play_sfx("ui_click")
	GM.set_game_speed(speed)

func _on_next_wave_pressed() -> void:
	Audio.play_sfx("ui_click")
	if GM.phase == "playing" and not GM.wave_active:
		GM.between_wave_timer = 0

func _on_dice_roll_pressed() -> void:
	Audio.play_sfx("ui_click")
	if GM.wave_active and GM.dice_uses_left > 0:
		GM.roll_dice()

func _on_pandora_choice(choice: int) -> void:
	Audio.play_sfx("ui_click")
	GM.accept_pandora_choice(choice)

func _on_menu_btn_pressed() -> void:
	Audio.play_sfx("ui_click")
	if settings_overlay.visible:
		_close_settings()
	else:
		_open_settings()

func _on_pause_pressed() -> void:
	Audio.play_sfx("ui_click")
	if GM.paused:
		_close_settings()
	else:
		GM.paused = true

func _on_settings_restart_pressed() -> void:
	Audio.play_sfx("ui_click")
	settings_overlay.visible = false
	GM.reset_state()

func _on_lang_toggle_pressed() -> void:
	Audio.play_sfx("ui_click")
	Locale.toggle_language()

func _on_close_settings_pressed() -> void:
	Audio.play_sfx("ui_click")
	_close_settings()

func _open_settings() -> void:
	settings_overlay.visible = true
	if GM.phase == "playing":
		GM.paused = true

func _close_settings() -> void:
	settings_overlay.visible = false
	if GM.phase == "playing":
		GM.paused = false

# ═══════════════════════════════════════════════════════
# UI HELPERS
# ═══════════════════════════════════════════════════════
func _tower_button_text(data: Dictionary, show_details: bool = false) -> String:
	if show_details:
		return Locale.tf("tower_button", {
			"name": Locale.t(data["name"]),
			"symbol": data["symbol"],
			"desc": Locale.t(data["desc"]),
			"cost": GM.format_cost(data["cost"]),
		})
	return Locale.tf("tower_button_compact", {
		"name": Locale.t(data["name"]),
		"cost": GM.format_cost(data["cost"]),
	})

func _build_wave_preview(wave_idx: int) -> String:
	var wave_def: Dictionary = Config.WAVE_DATA[wave_idx]
	var parts: PackedStringArray = []
	for group in wave_def["enemies"]:
		var ename: String = Config.ENEMY_DATA[group["type"]]["name"]
		parts.append(str(group["count"]) + "x " + Locale.t(ename))
	return Locale.t("Next:") + " " + ", ".join(parts)

func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	return sep

func _make_overlay_bg() -> ColorRect:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(Config.GAME_WIDTH + 332, Config.GAME_HEIGHT + 74)
	bg.color = Color(0, 0, 0, 0.75)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	return bg

func _make_centered_panel(w: float, h: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(((Config.GAME_WIDTH + 332) - w) / 2.0, ((Config.GAME_HEIGHT + 74) - h) / 2.0)
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
	btn.focus_mode = Control.FOCUS_NONE
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

func _disable_focus(node: Node) -> void:
	if node is Control:
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_disable_focus(child)
