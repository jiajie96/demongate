extends Control

var tower_type: String = ""
var tower_color: Color = Color.WHITE

func _draw() -> void:
	var cx: float = size.x / 2.0
	var cy: float = size.y / 2.0
	var s: float = minf(size.x, size.y) / 40.0  # scale factor relative to 40px base

	match tower_type:
		"demon_archer":
			# Mini archer — body, head, horns, bow
			draw_circle(Vector2(cx, cy), 14 * s, Color(0.35, 0.07, 0.07))
			draw_arc(Vector2(cx, cy), 14 * s, 0, TAU, 16, Color(0.8, 0.2, 0.2, 0.5), 1.2)
			# Body
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 5*s, cy - 1*s), Vector2(cx + 3*s, cy - 1*s),
				Vector2(cx + 2*s, cy + 10*s), Vector2(cx - 4*s, cy + 10*s)
			]), Color(0.55, 0.1, 0.1))
			# Head
			draw_circle(Vector2(cx - 1*s, cy - 5*s), 4.5*s, Color(0.78, 0.22, 0.2))
			# Horns
			draw_line(Vector2(cx - 4*s, cy - 8*s), Vector2(cx - 6*s, cy - 13*s), Color(0.95, 0.4, 0.15), 2.0)
			draw_line(Vector2(cx + 2*s, cy - 8*s), Vector2(cx + 4*s, cy - 13*s), Color(0.95, 0.4, 0.15), 2.0)
			# Bow string
			draw_arc(Vector2(cx + 6*s, cy), 8*s, -0.8, 0.8, 8, Color(0.8, 0.5, 0.2, 0.7), 1.0)
		"hellfire_mage":
			# Mini mage — base, robe, hat, staff glow
			draw_circle(Vector2(cx, cy), 14 * s, Color(0.2, 0.05, 0.25))
			draw_arc(Vector2(cx, cy), 14 * s, 0, TAU, 16, Color(0.6, 0.2, 0.8, 0.5), 1.2)
			# Robe
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 3*s, cy - 2*s), Vector2(cx + 3*s, cy - 2*s),
				Vector2(cx + 8*s, cy + 11*s), Vector2(cx - 8*s, cy + 11*s)
			]), Color(0.4, 0.1, 0.55))
			# Head
			draw_circle(Vector2(cx, cy - 4*s), 4*s, Color(0.58, 0.16, 0.72))
			# Hat
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx, cy - 16*s), Vector2(cx + 5*s, cy - 4*s), Vector2(cx - 5*s, cy - 4*s)
			]), Color(0.35, 0.08, 0.45))
			# Staff glow
			draw_circle(Vector2(cx + 7*s, cy - 3*s), 3*s, Color(1, 0.5, 0.9, 0.5))
			draw_circle(Vector2(cx + 7*s, cy - 3*s), 1.5*s, Color(1, 0.8, 1, 0.8))
		"necromancer":
			# Mini necro — green aura, hooded figure, skull staff
			var pulse: float = 0.12 + 0.04 * sin(Time.get_ticks_msec() * 0.002)
			draw_circle(Vector2(cx, cy), 16 * s, Color(0.1, 0.6, 0.25, pulse))
			draw_circle(Vector2(cx, cy), 14 * s, Color(0.06, 0.2, 0.1))
			draw_arc(Vector2(cx, cy), 14 * s, 0, TAU, 16, Color(0.2, 0.8, 0.4, 0.5), 1.2)
			# Tattered robe
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 4*s, cy - 5*s), Vector2(cx + 4*s, cy - 5*s),
				Vector2(cx + 8*s, cy + 11*s), Vector2(cx - 8*s, cy + 11*s)
			]), Color(0.1, 0.3, 0.15))
			# Hood
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 5*s, cy - 3*s), Vector2(cx + 5*s, cy - 3*s),
				Vector2(cx, cy - 13*s)
			]), Color(0.08, 0.22, 0.1))
			# Glowing eyes
			draw_circle(Vector2(cx - 2*s, cy - 5*s), 1.5*s, Color(0.2, 1, 0.4, 0.9))
			draw_circle(Vector2(cx + 2*s, cy - 5*s), 1.5*s, Color(0.2, 1, 0.4, 0.9))
		"hades":
			# Mini hades — blue aura, robed figure, glowing orb
			var pulse: float = 0.1 + 0.05 * sin(Time.get_ticks_msec() * 0.003)
			draw_circle(Vector2(cx, cy), 16 * s, Color(0.3, 0.2, 0.9, pulse))
			draw_circle(Vector2(cx, cy), 14 * s, Color(0.08, 0.05, 0.2))
			draw_arc(Vector2(cx, cy), 14 * s, 0, TAU, 16, Color(0.3, 0.2, 0.9, 0.5), 1.2)
			# Dark robe
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 5*s, cy - 4*s), Vector2(cx + 5*s, cy - 4*s),
				Vector2(cx + 7*s, cy + 11*s), Vector2(cx - 7*s, cy + 11*s)
			]), Color(0.1, 0.06, 0.25))
			# Head
			draw_circle(Vector2(cx, cy - 6*s), 4*s, Color(0.15, 0.1, 0.35))
			# Crown
			for i in range(3):
				var xoff: float = float(i - 1) * 3.0 * s
				draw_line(Vector2(cx + xoff, cy - 10*s), Vector2(cx + xoff, cy - 13*s), Color(0.4, 0.3, 0.9), 1.5)
			# Glowing orb in hands
			draw_circle(Vector2(cx, cy + 3*s), 4*s, Color(0.3, 0.2, 0.9, 0.3))
			draw_circle(Vector2(cx, cy + 3*s), 2.5*s, Color(0.5, 0.4, 1.0, 0.7))
			draw_circle(Vector2(cx, cy + 3*s), 1*s, Color(0.8, 0.7, 1, 0.9))
		"lucifer":
			# Mini lucifer — hellfire aura, horned figure, wings, flames
			var pulse: float = 0.12 + 0.06 * sin(Time.get_ticks_msec() * 0.0025)
			draw_circle(Vector2(cx, cy), 16 * s, Color(1.0, 0.3, 0.0, pulse))
			draw_circle(Vector2(cx, cy), 14 * s, Color(0.3, 0.08, 0.02))
			draw_arc(Vector2(cx, cy), 14 * s, 0, TAU, 16, Color(1.0, 0.4, 0.0, 0.6), 1.5)
			# Dark wings
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 6*s, cy - 1*s), Vector2(cx - 14*s, cy - 9*s),
				Vector2(cx - 10*s, cy + 3*s)
			]), Color(0.15, 0.03, 0.0, 0.8))
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx + 6*s, cy - 1*s), Vector2(cx + 14*s, cy - 9*s),
				Vector2(cx + 10*s, cy + 3*s)
			]), Color(0.15, 0.03, 0.0, 0.8))
			# Body
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 5*s, cy - 3*s), Vector2(cx + 5*s, cy - 3*s),
				Vector2(cx + 6*s, cy + 11*s), Vector2(cx - 6*s, cy + 11*s)
			]), Color(0.2, 0.05, 0.02))
			# Head
			draw_circle(Vector2(cx, cy - 6*s), 4.5*s, Color(0.35, 0.1, 0.04))
			# Massive horns
			draw_line(Vector2(cx - 4*s, cy - 9*s), Vector2(cx - 8*s, cy - 16*s), Color(1.0, 0.5, 0.1), 2.5)
			draw_line(Vector2(cx + 4*s, cy - 9*s), Vector2(cx + 8*s, cy - 16*s), Color(1.0, 0.5, 0.1), 2.5)
			# Burning eyes
			draw_circle(Vector2(cx - 2*s, cy - 7*s), 1.5*s, Color(1, 0.7, 0.0, 0.9))
			draw_circle(Vector2(cx + 2*s, cy - 7*s), 1.5*s, Color(1, 0.7, 0.0, 0.9))
		"beelzebub":
			# Mini beelzebub — green plague aura, insectoid figure, beam
			var pulse: float = 0.1 + 0.05 * sin(Time.get_ticks_msec() * 0.003)
			draw_circle(Vector2(cx, cy), 16 * s, Color(0.4, 0.7, 0.1, pulse))
			draw_circle(Vector2(cx, cy), 14 * s, Color(0.12, 0.18, 0.05))
			draw_arc(Vector2(cx, cy), 14 * s, 0, TAU, 16, Color(0.4, 0.7, 0.1, 0.5), 1.2)
			# Body
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 5*s, cy - 3*s), Vector2(cx + 5*s, cy - 3*s),
				Vector2(cx + 6*s, cy + 10*s), Vector2(cx - 6*s, cy + 10*s)
			]), Color(0.2, 0.3, 0.08))
			# Head
			draw_circle(Vector2(cx, cy - 5*s), 4.5*s, Color(0.25, 0.35, 0.1))
			# Compound eyes
			draw_circle(Vector2(cx - 3*s, cy - 6*s), 2*s, Color(0.5, 0.9, 0.2, 0.8))
			draw_circle(Vector2(cx + 3*s, cy - 6*s), 2*s, Color(0.5, 0.9, 0.2, 0.8))
			# Insect wings
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 4*s, cy - 2*s), Vector2(cx - 12*s, cy - 8*s), Vector2(cx - 8*s, cy + 2*s)
			]), Color(0.5, 0.7, 0.3, 0.4))
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx + 4*s, cy - 2*s), Vector2(cx + 12*s, cy - 8*s), Vector2(cx + 8*s, cy + 2*s)
			]), Color(0.5, 0.7, 0.3, 0.4))
			# Beam glow
			draw_line(Vector2(cx, cy + 4*s), Vector2(cx, cy + 14*s), Color(0.5, 0.9, 0.15, 0.6), 2.0)
		"cocytus":
			# Mini cocytus — icy blue aura, crystal spire, frost
			var pulse: float = 0.1 + 0.05 * sin(Time.get_ticks_msec() * 0.003)
			draw_circle(Vector2(cx, cy), 16 * s, Color(0.5, 0.8, 1.0, pulse))
			draw_circle(Vector2(cx, cy), 14 * s, Color(0.08, 0.12, 0.2))
			draw_arc(Vector2(cx, cy), 14 * s, 0, TAU, 16, Color(0.6, 0.85, 1.0, 0.5), 1.2)
			# Ice crystal body (diamond shape)
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx, cy - 12*s), Vector2(cx + 6*s, cy),
				Vector2(cx, cy + 10*s), Vector2(cx - 6*s, cy)
			]), Color(0.35, 0.55, 0.75))
			# Inner facet highlight
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx, cy - 8*s), Vector2(cx + 3*s, cy),
				Vector2(cx, cy + 6*s), Vector2(cx - 1*s, cy - 2*s)
			]), Color(0.5, 0.7, 0.9, 0.6))
			# Frost spikes radiating
			draw_line(Vector2(cx - 8*s, cy - 4*s), Vector2(cx - 12*s, cy - 8*s), Color(0.6, 0.85, 1.0, 0.7), 1.5)
			draw_line(Vector2(cx + 8*s, cy - 4*s), Vector2(cx + 12*s, cy - 8*s), Color(0.6, 0.85, 1.0, 0.7), 1.5)
			draw_line(Vector2(cx - 6*s, cy + 4*s), Vector2(cx - 10*s, cy + 6*s), Color(0.6, 0.85, 1.0, 0.5), 1.0)
			draw_line(Vector2(cx + 6*s, cy + 4*s), Vector2(cx + 10*s, cy + 6*s), Color(0.6, 0.85, 1.0, 0.5), 1.0)
			# Glowing core
			draw_circle(Vector2(cx, cy - 2*s), 3*s, Color(0.6, 0.9, 1.0, 0.5))
			draw_circle(Vector2(cx, cy - 2*s), 1.5*s, Color(0.8, 0.95, 1.0, 0.8))
		_:
			# Fallback circle
			draw_circle(Vector2(cx, cy), 12 * s, tower_color)
