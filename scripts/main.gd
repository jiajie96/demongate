extends Node2D

func _ready() -> void:
	# Draw window background border around game area
	queue_redraw()

func _draw() -> void:
	# Border around the game area
	var game_rect := Rect2(9, 54, Config.GAME_WIDTH + 2, Config.GAME_HEIGHT + 2)
	draw_rect(game_rect, Color(0.3, 0.15, 0.3), false, 1.0)
