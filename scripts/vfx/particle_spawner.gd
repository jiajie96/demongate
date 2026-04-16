class_name ParticleSpawner
extends RefCounted

# ═══════════════════════════════════════════════════════
# PARTICLE SPAWNER
# Helper for spawning one-shot GPUParticles2D effects using
# Kenney particle textures. Each method attaches a GPUParticles2D
# node to the given parent, emits once, and self-frees on completion.
# ═══════════════════════════════════════════════════════

const TEX_FIRE := preload("res://assets/vfx/particles/fire_01.png")
const TEX_FLAME := preload("res://assets/vfx/particles/flame_01.png")
const TEX_FLAME_BIG := preload("res://assets/vfx/particles/flame_04.png")
const TEX_SMOKE := preload("res://assets/vfx/particles/smoke_01.png")
const TEX_PUFF_WHITE := preload("res://assets/vfx/particles/puff_white.png")
const TEX_PUFF_BLACK := preload("res://assets/vfx/particles/puff_black.png")
const TEX_MAGIC := preload("res://assets/vfx/particles/magic_01.png")
const TEX_MAGIC_ALT := preload("res://assets/vfx/particles/magic_05.png")
const TEX_SPARK := preload("res://assets/vfx/particles/spark_01.png")
const TEX_SPARK_ALT := preload("res://assets/vfx/particles/spark_04.png")
const TEX_LIGHT := preload("res://assets/vfx/particles/light_01.png")
const TEX_FLARE := preload("res://assets/vfx/particles/flare_01.png")
const TEX_STAR := preload("res://assets/vfx/particles/star_04.png")
const TEX_TRACE := preload("res://assets/vfx/particles/trace_01.png")
const TEX_CIRCLE := preload("res://assets/vfx/particles/circle_05.png")
const TEX_SLASH := preload("res://assets/vfx/particles/slash_02.png")
const TEX_MUZZLE := preload("res://assets/vfx/particles/muzzle_01.png")

# ═══════════════════════════════════════════════════════
# INTERNAL BUILDER
# ═══════════════════════════════════════════════════════
static func _spawn(parent: Node2D, pos: Vector2, tex: Texture2D,
		amount: int, lifetime: float, vel_min: float, vel_max: float,
		spread: float, start_color: Color, end_color: Color,
		scale_min: float = 0.2, scale_max: float = 0.6,
		gravity: Vector2 = Vector2.ZERO,
		angle_deg: float = 0.0) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.position = pos
	p.texture = tex
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 0.95
	p.randomness = 0.3

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	mat.direction = Vector3(cos(deg_to_rad(angle_deg)), sin(deg_to_rad(angle_deg)), 0)
	mat.spread = spread
	mat.initial_velocity_min = vel_min
	mat.initial_velocity_max = vel_max
	mat.gravity = Vector3(gravity.x, gravity.y, 0)
	mat.scale_min = scale_min
	mat.scale_max = scale_max
	mat.damping_min = 5.0
	mat.damping_max = 15.0

	# Color gradient from start to end over lifetime
	var gradient := Gradient.new()
	gradient.set_color(0, start_color)
	gradient.set_color(1, end_color)
	var gtx := GradientTexture1D.new()
	gtx.gradient = gradient
	mat.color_ramp = gtx

	p.process_material = mat
	p.emitting = true
	parent.add_child(p)

	# Auto-free when finished (add small buffer)
	var timer := parent.get_tree().create_timer(lifetime + 0.2)
	timer.timeout.connect(p.queue_free)
	return p

# ═══════════════════════════════════════════════════════
# PUBLIC EFFECT SPAWNERS
# Each replaces a specific effect type from _draw_effects().
# ═══════════════════════════════════════════════════════

# Inferno Warlock AoE — single layer of 5-point arcane sparkles.
# Procedural ring carries the shockwave; GPU layer adds texture.
static func spawn_aoe_burst(parent: Node2D, pos: Vector2, radius: float = 60.0) -> void:
	var vel: float = radius * 1.8
	_spawn(parent, pos, TEX_MAGIC,
		3, 0.45, vel * 0.5, vel * 0.9, 180.0,
		Color(1.0, 0.65, 1.0, 0.95), Color(0.6, 0.15, 0.9, 0.0),
		0.25, 0.55)

# Enemy death — single flare blink
static func spawn_death_puff(parent: Node2D, pos: Vector2, tint: Color) -> void:
	var bright := Color(tint.r * 1.2, tint.g * 1.2, tint.b * 1.2, 0.5)
	_spawn(parent, pos, TEX_FLARE,
		1, 0.18, 0.0, 0.0, 0.0,
		bright, Color(tint.r, tint.g, tint.b, 0.0),
		0.18, 0.18)

# Lucifer strike — cyan-white electric sparks at the impact point.
# The vertical bolt itself is drawn procedurally in game_world (lucifer_hit).
static func spawn_lucifer_hit(parent: Node2D, pos: Vector2) -> void:
	_spawn(parent, pos, TEX_SPARK_ALT,
		6, 0.22, 80.0, 160.0, 180.0,
		Color(0.9, 0.95, 1.0, 0.9), Color(0.55, 0.8, 1.0, 0.0),
		0.1, 0.25)

# Hades buff pulse — supportive rising motes (NOT an outward shockwave)
# Feels ritual/empowering rather than damaging.
static func spawn_hades_wave(parent: Node2D, pos: Vector2, _radius: float = 130.0) -> void:
	# Narrow upward cone of arcane magic motes
	_spawn(parent, pos, TEX_MAGIC,
		20, 0.85, 30.0, 60.0, 40.0,
		Color(0.75, 0.55, 1.0, 0.9), Color(0.4, 0.2, 1.0, 0.0),
		0.25, 0.55,
		Vector2(0, -50),  # buoyant — motes rise
		-90.0)            # direction: up
	# A few bright stars for sparkle
	_spawn(parent, pos, TEX_STAR,
		10, 0.7, 20.0, 45.0, 55.0,
		Color(1.0, 0.95, 1.0, 0.95), Color(0.7, 0.6, 1.0, 0.0),
		0.15, 0.3,
		Vector2(0, -40),
		-90.0)

# Thin arcane tendril from Hades to one buffed tower — shows the buff connection.
# Draws a short-lived beam-style effect; see game_world.gd for rendering.
# (No GPU particles here — the beam itself is procedural in _draw_effects.)

# Ice shatter — Cocytus impact
static func spawn_ice_burst(parent: Node2D, pos: Vector2, _radius: float = 10.0) -> void:
	_spawn(parent, pos, TEX_SPARK_ALT,
		20, 0.6, 60.0, 140.0, 180.0,
		Color(0.85, 0.95, 1.0, 1.0), Color(0.4, 0.7, 1.0, 0.0),
		0.15, 0.4,
		Vector2(0, 80))  # Slight gravity — shards fall down
	_spawn(parent, pos, TEX_STAR,
		8, 0.4, 30.0, 80.0, 180.0,
		Color(1.0, 1.0, 1.0, 1.0), Color(0.7, 0.9, 1.0, 0.0),
		0.25, 0.5)

# Heal pulse — green sparkles ring
static func spawn_heal_pulse(parent: Node2D, pos: Vector2) -> void:
	_spawn(parent, pos, TEX_STAR,
		18, 0.7, 50.0, 100.0, 180.0,
		Color(0.5, 1.0, 0.6, 1.0), Color(0.2, 0.9, 0.3, 0.0),
		0.2, 0.45,
		Vector2(0, -50))  # Float upward

# Michael's shield — golden expanding dome particles
static func spawn_michael_shield(parent: Node2D, pos: Vector2) -> void:
	_spawn(parent, pos, TEX_MAGIC_ALT,
		30, 0.9, 200.0, 350.0, 180.0,
		Color(1.0, 0.9, 0.5, 1.0), Color(1.0, 0.7, 0.3, 0.0),
		0.3, 0.6)

# Muzzle flash — small burst at tower when firing
static func spawn_muzzle_flash(parent: Node2D, pos: Vector2, tint: Color) -> void:
	_spawn(parent, pos, TEX_MUZZLE,
		6, 0.15, 20.0, 60.0, 60.0,
		Color(tint.r * 1.5, tint.g * 1.5, tint.b * 1.5, 1.0),
		Color(tint.r, tint.g, tint.b, 0.0),
		0.3, 0.7)

# Hit spark — generic impact burst for tower hits
static func spawn_hit_spark(parent: Node2D, pos: Vector2, tint: Color) -> void:
	_spawn(parent, pos, TEX_SPARK,
		8, 0.25, 40.0, 120.0, 180.0,
		Color(1.0, 0.95, 0.7, 1.0),
		Color(tint.r * 0.8, tint.g * 0.8, tint.b * 0.8, 0.0),
		0.15, 0.35)

# Soul Reaper impact — ghostly green wisp burst. Complements the procedural
# X-mark + tendrils drawn in _draw_effects. A small updraft (negative Y gravity)
# carries the motes upward so each hit ends with a spirit curling into the sky.
static func spawn_soul_hit(parent: Node2D, pos: Vector2) -> void:
	# Light green motes floating up
	_spawn(parent, pos, TEX_MAGIC,
		6, 0.38, 40.0, 90.0, 120.0,
		Color(0.55, 1.0, 0.7, 0.95),
		Color(0.2, 0.8, 0.4, 0.0),
		0.15, 0.35,
		Vector2(0, -40))
	# A couple of bright pinpoint stars for a "soul plucked" accent
	_spawn(parent, pos, TEX_STAR,
		3, 0.28, 20.0, 55.0, 180.0,
		Color(0.9, 1.0, 0.9, 0.95),
		Color(0.55, 1.0, 0.7, 0.0),
		0.14, 0.28,
		Vector2(0, -30))
