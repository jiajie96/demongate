extends Node

const SAMPLE_RATE := 22050
const MAX_SFX_PLAYERS := 8

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _sounds: Dictionary = {}
var _sfx_index: int = 0

func _ready() -> void:
	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx_players.append(player)

	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -10.0
	add_child(_music_player)

	_generate_sounds()

func play_sfx(sound_name: String, vol_db: float = 0.0) -> void:
	if not _sounds.has(sound_name):
		return
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % MAX_SFX_PLAYERS
	player.stream = _sounds[sound_name]
	player.volume_db = vol_db
	player.play()

func play_shoot(tower_type: String) -> void:
	play_sfx("shoot_" + tower_type, -14.0)

func start_music() -> void:
	if _sounds.has("music") and not _music_player.playing:
		_music_player.stream = _sounds["music"]
		_music_player.play()

func stop_music() -> void:
	_music_player.stop()

# ═══════════════════════════════════════════════════════
# SOUND GENERATION
# ═══════════════════════════════════════════════════════
func _generate_sounds() -> void:
	_sounds["shoot_demon_archer"] = _make_archer_shoot()
	_sounds["shoot_hellfire_mage"] = _make_mage_shoot()
	_sounds["shoot_necromancer"] = _make_necro_shoot()
	_sounds["enemy_death"] = _make_enemy_death()
	_sounds["core_hit"] = _make_core_hit()
	_sounds["wave_start"] = _make_wave_start()
	_sounds["wave_complete"] = _make_wave_complete()
	_sounds["ui_click"] = _make_ui_click()
	_sounds["dice_roll"] = _make_dice_roll()
	_sounds["pact_accept"] = _make_pact_accept()
	_sounds["music"] = _make_music()

# ═══════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════
func _make_wav(data: PackedByteArray, do_loop: bool = false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	if do_loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
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

# Soft saturation — no hard clipping
func _saturate(x: float) -> float:
	return x / (1.0 + absf(x))

# ═══════════════════════════════════════════════════════
# SFX GENERATORS
# ═══════════════════════════════════════════════════════
func _make_archer_shoot() -> AudioStreamWAV:
	# Soft thwip — filtered noise with gentle attack
	var n := _n_samples(0.06)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	var lpf := 0.0
	for i in range(n):
		var env := _env_ad(i, n, 0.08)
		var raw := _noise(i) * 0.25
		lpf += 0.15 * (raw - lpf)  # low-pass filter cuts harshness
		_pack(buf, i, lpf * env)
	return _make_wav(buf)

func _make_mage_shoot() -> AudioStreamWAV:
	# Warm whoosh — lower freq sweep, minimal noise
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
	# Eerie vibrato tone — already soft, just lower volume
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
	# Soft descending tone — mostly sine, tiny noise
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
	# Deep rumble — soft saturation, no hard clipping
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

func _make_wave_start() -> AudioStreamWAV:
	# Rising 3-note with soft attack: D4 -> F4 -> A4
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
	# Resolving chord: A4 -> F4 -> D4 -> D5
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
	# Soft click — sine pulse instead of harsh square wave
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
	# Softer rattle — filtered clicks
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

func _make_pact_accept() -> AudioStreamWAV:
	# Dark chord — soft saturation instead of hard clip
	var n := _n_samples(0.5)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var env := _env_ad(i, n, 0.08)
		var s := sin(t * 73.4 * TAU) * 0.35
		s += sin(t * 103.8 * TAU) * 0.25
		s += sin(t * 146.8 * TAU) * 0.2
		s = _saturate(s * 1.2)
		_pack(buf, i, s * env * 0.3)
	return _make_wav(buf)

# ═══════════════════════════════════════════════════════
# AMBIENT MUSIC (4-second looping drone)
# ═══════════════════════════════════════════════════════
func _make_music() -> AudioStreamWAV:
	var duration := 4.0
	var n := _n_samples(duration)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	for i in range(n):
		var t := float(i) / SAMPLE_RATE
		var lfo := 0.5 + 0.5 * sin(t * 0.15 * TAU)
		var bass := sin(t * 55.0 * TAU) * 0.3
		var mid := sin(t * 73.5 * TAU) * 0.15 * lfo
		var sub := sin(t * 27.5 * TAU) * 0.12
		var hiss := _noise(i) * 0.015
		var s := bass + mid + sub + hiss
		_pack(buf, i, s * 0.4)
	return _make_wav(buf, true)
