extends Node2D

@export var grid_step: float = 64.0
@export var background_color: Color = Color(0.09, 0.11, 0.14, 1.0)
@export var grid_color: Color = Color(0.14, 0.17, 0.22, 0.8)
@export var border_color: Color = Color(0.28, 0.42, 0.62, 0.9)
@export var border_width: float = 4.0

func _draw() -> void:
	var parent_world = get_parent()
	var arena_size = parent_world.arena_size if parent_world and "arena_size" in parent_world else Vector2(1600, 1000)

	# 1. Fill arena background
	draw_rect(Rect2(Vector2.ZERO, arena_size), background_color, true)

	# 2. Draw grid lines
	var x: float = 0.0
	while x <= arena_size.x:
		draw_line(Vector2(x, 0), Vector2(x, arena_size.y), grid_color, 1.0)
		x += grid_step

	var y: float = 0.0
	while y <= arena_size.y:
		draw_line(Vector2(0, y), Vector2(arena_size.x, y), grid_color, 1.0)
		y += grid_step

	# 3. Draw outer border
	draw_rect(Rect2(Vector2.ZERO, arena_size), border_color, false, border_width)
