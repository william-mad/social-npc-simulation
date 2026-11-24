extends Node2D

@export var grid_step: float = 64.0
# Inside arena stays constant for high contrast & readability
@export var background_color: Color = Color(0.09, 0.11, 0.14, 1.0)
@export var grid_color: Color = Color(0.14, 0.17, 0.22, 0.8)

# Outside arena clearly signals Day vs Night
@export var day_outside_color: Color = Color(0.52, 0.78, 0.98, 1.0)
@export var night_outside_color: Color = Color(0.02, 0.03, 0.08, 1.0)
@export var day_border_color: Color = Color(0.98, 0.84, 0.36, 0.95)
@export var night_border_color: Color = Color(0.28, 0.45, 0.85, 0.95)
@export var border_width: float = 5.0

var night_blend: float = 0.0:
	set(v):
		var clamped := clampf(v, 0.0, 1.0)
		if not is_equal_approx(night_blend, clamped):
			night_blend = clamped
			_sync_clear_color()
			queue_redraw()

var _stars: Array[Dictionary] = []

func _ready() -> void:
	_generate_exterior_stars()
	_sync_clear_color()

func _sync_clear_color() -> void:
	var outside_col: Color = day_outside_color.lerp(night_outside_color, night_blend)
	RenderingServer.set_default_clear_color(outside_col)

func _generate_exterior_stars() -> void:
	_stars.clear()
	var parent_world = get_parent()
	var arena_size: Vector2 = parent_world.arena_size if parent_world and "arena_size" in parent_world else Vector2(1600, 1000)
	var arena_rect := Rect2(Vector2.ZERO, arena_size).grow(24.0)

	var rng := RandomNumberGenerator.new()
	rng.seed = 20261124
	for _i in range(220):
		var p := Vector2(
			rng.randf_range(-1600.0, arena_size.x + 1600.0),
			rng.randf_range(-1200.0, arena_size.y + 1200.0)
		)
		if arena_rect.has_point(p):
			continue
		_stars.append({
			"pos": p,
			"r": rng.randf_range(1.2, 2.8),
			"alpha": rng.randf_range(0.45, 0.95)
		})

func _draw() -> void:
	var parent_world = get_parent()
	var arena_size: Vector2 = parent_world.arena_size if parent_world and "arena_size" in parent_world else Vector2(1600, 1000)

	var outside_col: Color = day_outside_color.lerp(night_outside_color, night_blend)
	var border_col: Color = day_border_color.lerp(night_border_color, night_blend)

	# 0. Draw exterior Day / Night sky outside the arena
	var sky_rect := Rect2(Vector2(-4000.0, -4000.0), arena_size + Vector2(8000.0, 8000.0))
	draw_rect(sky_rect, outside_col, true)

	# Subtle sunlit outer glow during Day; crisp stars outside the arena during Night
	if night_blend < 0.95:
		var day_alpha: float = 1.0 - night_blend
		var glow_rect := Rect2(Vector2.ZERO, arena_size).grow(22.0)
		draw_rect(glow_rect, Color(1.0, 0.94, 0.72, 0.25 * day_alpha), true)
	if night_blend > 0.05:
		for s in _stars:
			var a: float = float(s["alpha"]) * night_blend
			draw_circle(s["pos"], float(s["r"]), Color(0.88, 0.93, 1.0, a))

	# 1. Fill constant interior arena background
	draw_rect(Rect2(Vector2.ZERO, arena_size), background_color, true)

	# 2. Draw constant interior grid lines
	var x: float = 0.0
	while x <= arena_size.x:
		draw_line(Vector2(x, 0), Vector2(x, arena_size.y), grid_color, 1.0)
		x += grid_step

	var y: float = 0.0
	while y <= arena_size.y:
		draw_line(Vector2(0, y), Vector2(arena_size.x, y), grid_color, 1.0)
		y += grid_step

	# 3. Draw outer border tinted to match Day (warm gold) / Night (cool blue)
	draw_rect(Rect2(Vector2.ZERO, arena_size), border_col, false, border_width)
