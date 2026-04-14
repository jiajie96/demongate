extends Control

var tower_type: String = ""
var tower_color: Color = Color.WHITE

func _draw() -> void:
	var cx: float = size.x / 2.0
	var cy: float = size.y / 2.0
	var s: float = minf(size.x, size.y) / 40.0

	# Draw 3D model texture from CharRenderer — use facing angle 0 (default front)
	var tex: Texture2D = CharRenderer.get_texture(tower_type, 0.0)
	if tex != null:
		var tint: Color = CharRenderer.get_tint(tower_type)
		var icon_size: float = 32.0 * s
		var half: float = icon_size / 2.0

		# Colored aura circle behind the model
		draw_circle(Vector2(cx, cy), 14 * s, Color(tower_color.r * 0.3, tower_color.g * 0.3, tower_color.b * 0.3))
		draw_arc(Vector2(cx, cy), 14 * s, 0, TAU, 16, Color(tower_color.r, tower_color.g, tower_color.b, 0.5), 1.2)

		# The 3D model
		draw_texture_rect(tex, Rect2(cx - half, cy - half - 2, icon_size, icon_size), false, tint)
	else:
		# Fallback circle
		draw_circle(Vector2(cx, cy), 12 * s, tower_color)
