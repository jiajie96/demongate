extends Node

# ═══════════════════════════════════════════════════════
# AUDIO MANAGER
#
# Hybrid file-based + procedural fallback audio system.
# - Loads OGG files from res://assets/audio/ at startup
# - Falls back to procedural synthesis if a file is missing
# - 16-player SFX pool with priority-based eviction
# - Music + SFX routed through dedicated audio buses
# - Volume settings persist to user://settings.cfg
# ═══════════════════════════════════════════════════════

const SAMPLE_RATE := 22050
const MAX_SFX_PLAYERS := 16

# SFX file paths (nullable — fall back to procedural if missing).
# Multiple paths = random variant.
const SFX_FILES := {
	"shoot_bone_marksman":   "res://assets/audio/sfx/shoot_bone_marksman.ogg",
	"shoot_inferno_warlock": "res://assets/audio/sfx/shoot_inferno_warlock.ogg",
	"shoot_soul_reaper":     "res://assets/audio/sfx/shoot_soul_reaper.ogg",
	"shoot_hades":           "res://assets/audio/sfx/shoot_generic.ogg",
	"shoot_cocytus":         "res://assets/audio/sfx/shoot_generic.ogg",
	"shoot_lucifer":         "res://assets/audio/sfx/shoot_generic.ogg",
	"enemy_death":           ["res://assets/audio/sfx/enemy_death_01.ogg",
							  "res://assets/audio/sfx/enemy_death_02.ogg"],
	"core_hit":              "res://assets/audio/sfx/core_hit.ogg",
	"wave_start":            "res://assets/audio/sfx/wave_start.ogg",
	"ui_click":              "res://assets/audio/sfx/ui_click.ogg",
	"ui_select":             "res://assets/audio/sfx/ui_select.ogg",
	"dice_roll":             "res://assets/audio/sfx/dice_roll.ogg",
	"hades_buff":            "res://assets/audio/sfx/hades_buff.ogg",
	"lucifer_pulse":         "res://assets/audio/sfx/lucifer_pulse.ogg",
	"pact_accept":           "res://assets/audio/sfx/pact_accept.ogg",
	"wave_complete":         "res://assets/audio/sfx/wave_complete.ogg",
}

# Priority table — higher = more important; low-priority sounds get dropped first
# when the pool is saturated. Defaults to 1 if not listed.
const SFX_PRIORITY := {
	"core_hit":      10,  # critical feedback
	"wave_start":     9,
	"wave_complete":  9,
	"lucifer_pulse":  8,
	"dice_roll":      7,
	"pact_accept":    6,
	"hades_buff":     3,
	"enemy_death":    2,
	"ui_click":       2,
	"ui_select":      2,
	# Tower shoots default to 1 (most numerous, cheapest to drop)
}

# Per-SFX volume adjustment (dB) — for fine-tuning file levels
const SFX_VOLUME_OFFSET := {
	"shoot_bone_marksman":   -8.0,
	"shoot_inferno_warlock": -8.0,
	"shoot_soul_reaper":     -6.0,
	"shoot_hades":           -10.0,
	"shoot_cocytus":         -10.0,
	"shoot_lucifer":         -6.0,
	"hades_buff":            -12.0,
	"lucifer_pulse":         -3.0,
	"core_hit":              -4.0,
	"enemy_death":           -8.0,
}

# Music file paths. Gameplay tracks are tiered by wave intensity; stingers play
# on victory/defeat. All gameplay tracks are CC0 (see assets/audio/CREDITS.md).
const MUSIC_FILES := {
	"gameplay_calm": "res://assets/audio/music/cavern_ambient.ogg",       # Paul Wortmann
	"gameplay_mid":  "res://assets/audio/music/determined_pursuit.ogg",   # Emma_MA
	"gameplay_peak": "res://assets/audio/music/epic_boss.ogg",            # Juhani Junkala
	"victory":       "res://assets/audio/music/victory.ogg",
	"defeat":        "res://assets/audio/music/defeat.ogg",
}

# Wave tier thresholds — which gameplay track plays at which wave number.
const MUSIC_TIER_MID := 8
const MUSIC_TIER_PEAK := 15

const SETTINGS_PATH := "user://settings.cfg"

# ═══════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_active_priority: Array[int] = []  # priority of currently playing SFX per slot
var _music_player: AudioStreamPlayer
var _streams: Dictionary = {}  # sfx_key -> AudioStream OR Array[AudioStream]
var _proc_sounds: Dictionary = {}  # sfx_key -> AudioStreamWAV (fallback)
var _sfx_index: int = 0
var _current_music_key: String = ""

# Volume settings (linear 0-1)
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.9

# ═══════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════
func _ready() -> void:
	_sfx_active_priority.resize(MAX_SFX_PLAYERS)
	_sfx_active_priority.fill(0)

	# 16 pooled SFX players on SFX bus
	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)

	# Single music player on Music bus
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	_load_streams()
	_generate_fallback_sounds()
	load_settings()

# ═══════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════
func play_sfx(sound_name: String, vol_db: float = 0.0) -> void:
	var stream := _get_stream(sound_name)
	if stream == null:
		return

	var priority: int = SFX_PRIORITY.get(sound_name, 1)
	var slot: int = _acquire_slot(priority)
	if slot < 0:
		return  # all slots occupied by higher-priority sounds

	var final_vol: float = vol_db + SFX_VOLUME_OFFSET.get(sound_name, 0.0)
	var player := _sfx_players[slot]
	player.stream = stream
	player.volume_db = final_vol
	player.play()
	_sfx_active_priority[slot] = priority

func play_shoot(tower_type: String) -> void:
	play_sfx("shoot_" + tower_type)

func start_music() -> void:
	# Kick off gameplay music at calm tier (wave 1). Wave transitions call
	# update_music_for_wave() to switch tiers.
	update_music_for_wave(1)

func update_music_for_wave(wave: int) -> void:
	var key: String
	if wave >= MUSIC_TIER_PEAK:
		key = "gameplay_peak"
	elif wave >= MUSIC_TIER_MID:
		key = "gameplay_mid"
	else:
		key = "gameplay_calm"
	_play_music_track(key)

func stop_music() -> void:
	_music_player.stop()
	_current_music_key = ""

func play_music_stinger(stinger_name: String) -> void:
	# For "victory" / "defeat" one-shot stingers. Clears tier state so next
	# start_music() restarts from calm.
	if _streams.has(stinger_name):
		_music_player.stop()
		_music_player.stream = _streams[stinger_name]
		_music_player.play()
		_current_music_key = stinger_name

func _play_music_track(key: String) -> void:
	if _current_music_key == key and _music_player.playing:
		return
	var stream: AudioStream = _streams.get(key, null)
	if stream == null:
		# Fall back to procedural drone if the tier's file isn't loaded
		stream = _proc_sounds.get("music", null)
	if stream == null:
		return
	# Ensure file-based tracks loop seamlessly (Vorbis doesn't set loop by default)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music_player.stream = stream
	_music_player.play()
	_current_music_key = key

# ═══════════════════════════════════════════════════════
# VOLUME CONTROLS
# Linear 0-1 values map to dB via linear_to_db (with floor at -60 for 0).
# ═══════════════════════════════════════════════════════
func set_master_volume(linear: float) -> void:
	master_volume = clampf(linear, 0.0, 1.0)
	_apply_bus_volume("Master", master_volume)

func set_music_volume(linear: float) -> void:
	music_volume = clampf(linear, 0.0, 1.0)
	_apply_bus_volume("Music", music_volume)

func set_sfx_volume(linear: float) -> void:
	sfx_volume = clampf(linear, 0.0, 1.0)
	_apply_bus_volume("SFX", sfx_volume)

func _apply_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var db: float = -60.0 if linear <= 0.001 else linear_to_db(linear)
	AudioServer.set_bus_volume_db(idx, db)

# ═══════════════════════════════════════════════════════
# SETTINGS PERSISTENCE
# ═══════════════════════════════════════════════════════
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		# No settings file — apply defaults
		set_master_volume(master_volume)
		set_music_volume(music_volume)
		set_sfx_volume(sfx_volume)
		return
	set_master_volume(cfg.get_value("audio", "master", 1.0))
	set_music_volume(cfg.get_value("audio", "music", 0.8))
	set_sfx_volume(cfg.get_value("audio", "sfx", 0.9))

# ═══════════════════════════════════════════════════════
# INTERNAL — STREAM LOADING / POOLING
# ═══════════════════════════════════════════════════════
func _load_streams() -> void:
	# Load SFX files
	for key in SFX_FILES:
		var val = SFX_FILES[key]
		if val is String:
			var stream = _try_load(val)
			if stream:
				_streams[key] = stream
		elif val is Array:
			var arr: Array[AudioStream] = []
			for path in val:
				var stream = _try_load(path)
				if stream:
					arr.append(stream)
			if arr.size() > 0:
				_streams[key] = arr
	# Load music stingers
	for key in MUSIC_FILES:
		var stream = _try_load(MUSIC_FILES[key])
		if stream:
			_streams[key] = stream

func _try_load(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("Audio file not found: " + path)
		return null
	return load(path) as AudioStream

func _get_stream(sound_name: String) -> AudioStream:
	if _streams.has(sound_name):
		var val = _streams[sound_name]
		if val is Array:
			# Random variant
			return val[randi() % val.size()]
		return val
	# Fall back to procedural
	if _proc_sounds.has(sound_name):
		return _proc_sounds[sound_name]
	return null

# Acquire a free SFX slot, evicting the lowest-priority active slot if needed.
# Returns -1 if this sound's priority is lower than everything active.
func _acquire_slot(new_priority: int) -> int:
	# Prefer a stopped player (round-robin starting from last index)
	for i in range(MAX_SFX_PLAYERS):
		var idx := (_sfx_index + i) % MAX_SFX_PLAYERS
		if not _sfx_players[idx].playing:
			_sfx_index = (idx + 1) % MAX_SFX_PLAYERS
			return idx
	# All playing — find lowest-priority slot
	var lowest_idx := -1
	var lowest_prio: int = new_priority
	for i in range(MAX_SFX_PLAYERS):
		if _sfx_active_priority[i] < lowest_prio:
			lowest_prio = _sfx_active_priority[i]
			lowest_idx = i
	return lowest_idx

# ═══════════════════════════════════════════════════════
# PROCEDURAL FALLBACK
# (kept so the game still plays if asset files are missing)
# ═══════════════════════════════════════════════════════
func _generate_fallback_sounds() -> void:
	# Only generate procedural fallback for keys that DON'T have a file loaded
	if not _streams.has("shoot_bone_marksman"):
		_proc_sounds["shoot_bone_marksman"] = _make_archer_shoot()
	if not _streams.has("shoot_inferno_warlock"):
		_proc_sounds["shoot_inferno_warlock"] = _make_mage_shoot()
	if not _streams.has("shoot_soul_reaper"):
		_proc_sounds["shoot_soul_reaper"] = _make_necro_shoot()
	if not _streams.has("enemy_death"):
		_proc_sounds["enemy_death"] = _make_enemy_death()
	if not _streams.has("core_hit"):
		_proc_sounds["core_hit"] = _make_core_hit()
	if not _streams.has("wave_start"):
		_proc_sounds["wave_start"] = _make_wave_start()
	if not _streams.has("wave_complete"):
		_proc_sounds["wave_complete"] = _make_wave_complete()
	if not _streams.has("ui_click"):
		_proc_sounds["ui_click"] = _make_ui_click()
	if not _streams.has("dice_roll"):
		_proc_sounds["dice_roll"] = _make_dice_roll()
	if not _streams.has("hades_buff"):
		_proc_sounds["hades_buff"] = _make_hades_buff()
	if not _streams.has("lucifer_pulse"):
		_proc_sounds["lucifer_pulse"] = _make_lucifer_pulse()
	# Ambient music — always procedural for now (Kenney has no gameplay-loop music)
	_proc_sounds["music"] = _make_music()

# ═══════════════════════════════════════════════════════
# SYNTHESIS HELPERS
# ═══════════════════════════════════════════════════════
func _make_wav(data: PackedByteArray, do_loop: bool = false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	if do_loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		@warning_ignore("integer_division")
		wav.loop_end = data.size() / 2
	return wav

func _n_samples(duration: float) -> int:
	return int(duration * SAMPLE_RATE)

func _env_ad(i: int, total: int, attack_frac: float) -> float:
	var t := float(i) / total
	if t < attack_frac:
		return t / attack_frac if attack_frac > 0.001 else 1.0
	return (1.0 - t) / (1.0 - attack_frac)

func _noise(i: int) -> float:
	var n := ((i * 1103515245 + 12345) >> 16) & 0x7FFF
	return float(n) / float(0x7FFF) * 2.0 - 1.0

func _pack(buf: PackedByteArray, i: int, sample: float) -> void:
	buf.encode_s16(i * 2, clampi(int(sample * 32767.0), -32768, 32767))

func _saturate(x: float) -> float:
	return x / (1.0 + absf(x))

# ═══════════════════════════════════════════════════════
# PROCEDURAL SFX (fallback generators)
# ═══════════════════════════════════════════════════════
func _make_archer_shoot() -> AudioStreamWAV:
	var n := _n_samples(0.06)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	var lpf := 0.0
	for i in range(n):
		var env := _env_ad(i, n, 0.08)
		var raw := _noise(i) * 0.25
		lpf += 0.15 * (raw - lpf)
		_pack(buf, i, lpf * env)
	return _make_wav(buf)

func _make_mage_shoot() -> AudioStreamWAV:
	var n := _n_samples(0.16)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var env := _env_ad(i, n, 0.12)
		var freq := lerpf(500.0, 140.0, float(i) / n)
		phase += freq / SAMPLE_RATE
		var s := sin(phase * TAU) * 0.35 + sin(phase * TAU * 2.0) * 0.08
		_pack(buf, i, s * env * 0.25)
	return _make_wav(buf)

func _make_necro_shoot() -> AudioStreamWAV:
	var n := _n_samples(0.2)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env_ad(i, n, 0.15)
		var vibrato := sin(t * 6.0 * TAU) * 20.0
		phase += (320.0 + vibrato) / SAMPLE_RATE
		_pack(buf, i, sin(phase * TAU) * env * 0.18)
	return _make_wav(buf)

func _make_enemy_death() -> AudioStreamWAV:
	var n := _n_samples(0.12)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	var phase := 0.0
	var lpf := 0.0
	for i in range(n):
		var env := _env_ad(i, n, 0.05)
		var freq := lerpf(400.0, 80.0, float(i) / n)
		phase += freq / SAMPLE_RATE
		var s := sin(phase * TAU) * 0.4 + _noise(i + 9999) * 0.08
		lpf += 0.2 * (s - lpf)
		_pack(buf, i, lpf * env * 0.25)
	return _make_wav(buf)

func _make_core_hit() -> AudioStreamWAV:
	var n := _n_samples(0.35)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env_ad(i, n, 0.05)
		var s := sin(t * 50.0 * TAU) * 0.5 + sin(t * 75.0 * TAU) * 0.2
		s = _saturate(s * 1.5)
		_pack(buf, i, s * env * 0.35)
	return _make_wav(buf)

func _make_hades_buff() -> AudioStreamWAV:
	var n := _n_samples(0.25)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	var freq := 660.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env_ad(i, n, 0.01)
		env *= env * env
		var s := sin(t * freq * TAU) * 0.06
		s += sin(t * freq * 2.0 * TAU) * 0.02
		_pack(buf, i, s * env)
	return _make_wav(buf)

func _make_lucifer_pulse() -> AudioStreamWAV:
	var n := _n_samples(0.35)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var env := _env_ad(i, n, 0.05)
		var freq := lerpf(120.0, 60.0, float(i) / n)
		phase += freq / SAMPLE_RATE
		var s := sin(phase * TAU) * 0.3
		s += sin(phase * TAU * 2.0) * 0.1
		s += _noise(i) * 0.03 * env
		_pack(buf, i, _saturate(s * env * 0.5))
	return _make_wav(buf)

func _make_wave_start() -> AudioStreamWAV:
	var freqs := [293.66, 349.23, 440.0]
	var note_len := _n_samples(0.12)
	var gap := _n_samples(0.04)
	var total := (note_len + gap) * 3
	var buf := PackedByteArray()
	buf.resize(total * 2)
	for ni in range(3):
		var offset := ni * (note_len + gap)
		for i in range(note_len):
			var t := float(i) / SAMPLE_RATE
			var env := _env_ad(i, note_len, 0.1)
			var s := sin(t * freqs[ni] * TAU) * 0.25 + sin(t * freqs[ni] * 2.0 * TAU) * 0.05
			_pack(buf, offset + i, s * env)
		for i in range(gap):
			_pack(buf, offset + note_len + i, 0.0)
	return _make_wav(buf)

func _make_wave_complete() -> AudioStreamWAV:
	var freqs := [440.0, 349.23, 293.66, 587.33]
	var note_len := _n_samples(0.1)
	var gap := _n_samples(0.03)
	var last_len := _n_samples(0.25)
	var total := (note_len + gap) * 3 + last_len
	var buf := PackedByteArray()
	buf.resize(total * 2)
	for ni in range(3):
		var offset := ni * (note_len + gap)
		for i in range(note_len):
			var t := float(i) / SAMPLE_RATE
			var env := _env_ad(i, note_len, 0.1)
			_pack(buf, offset + i, sin(t * freqs[ni] * TAU) * env * 0.25)
		for i in range(gap):
			_pack(buf, offset + note_len + i, 0.0)
	var last_offset := 3 * (note_len + gap)
	for i in range(last_len):
		var t := float(i) / SAMPLE_RATE
		var env := _env_ad(i, last_len, 0.08)
		_pack(buf, last_offset + i, sin(t * freqs[3] * TAU) * env * 0.28)
	return _make_wav(buf)

func _make_ui_click() -> AudioStreamWAV:
	var n := _n_samples(0.02)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env_ad(i, n, 0.15)
		var s := sin(t * 800.0 * TAU) * 0.2
		_pack(buf, i, s * env)
	return _make_wav(buf)

func _make_dice_roll() -> AudioStreamWAV:
	var n := _n_samples(0.4)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	var lpf := 0.0
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env_ad(i, n, 0.3)
		var rattle := 0.0
		for k in range(12):
			var click_t := float(k) * 0.03 + float(k * k) * 0.001
			if absf(t - click_t) < 0.006:
				rattle = _noise(i + k * 1000) * (1.0 - absf(t - click_t) / 0.006)
		lpf += 0.25 * (rattle - lpf)
		_pack(buf, i, lpf * env * 0.3)
	return _make_wav(buf)

# ═══════════════════════════════════════════════════════
# AMBIENT MUSIC — longer 16-second loop with more variation
# ═══════════════════════════════════════════════════════
func _make_music() -> AudioStreamWAV:
	var duration := 16.0
	var n := _n_samples(duration)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		# Slow breathing LFO
		var lfo := 0.5 + 0.5 * sin(t * 0.08 * TAU)
		# Deep bass drone
		var bass := sin(t * 55.0 * TAU) * 0.28
		# Mid-register shimmering tone with LFO modulation
		var mid := sin(t * 73.5 * TAU) * 0.14 * lfo
		# Subtle third layer that slowly drifts
		var drift := sin(t * 82.4 * TAU + sin(t * 0.3) * 0.5) * 0.09
		# Sub-bass
		var sub := sin(t * 27.5 * TAU) * 0.10
		# Subtle high shimmer that slowly pulses
		var high_lfo := 0.5 + 0.5 * sin(t * 0.15 * TAU + 1.5)
		var high := sin(t * 440.0 * TAU) * 0.02 * high_lfo
		# Breathing noise texture
		var hiss := _noise(i) * 0.012
		var s := bass + mid + drift + sub + high + hiss
		_pack(buf, i, s * 0.4)
	return _make_wav(buf, true)
