class_name NPC
extends CharacterBody2D

## Signals
signal hover_changed(is_hovered: bool)
signal died(npc: NPC)

const HUNGRY_THRESHOLD: float = 40.0

# ==============================================================================
# HEALTH (0 to 100)
# Starts at 100. If hunger reaches 100, health depletes at hunger increase rate.
# If health reaches 0, the NPC dies and fades away.
# ==============================================================================
@export_group("Health")
@export_range(0.0, 100.0) var health: float = 100.0:
	set(v):
		health = clampf(v, 0.0, 100.0)
		if not is_dead and health <= 0.0:
			die()
		else:
			queue_redraw()

@export var show_health_always: bool = true

# ==============================================================================
# 8 NEEDS (0 to 100)
# User specification:
# 1 = hunger 0-100   -> bar up (Vector2.UP) [Hungry at >= 40, depletes health at 100]
# 2 = sleep need     -> bar northeast (Vector2(1, -1).normalized())
# 3 = talk need      -> bar right (Vector2.RIGHT)
# 4 = tired          -> bar southeast (Vector2(1, 1).normalized())
# 5 = boredom        -> bar down (Vector2.DOWN)
# 6 = lust           -> bar southwest (Vector2(-1, 1).normalized())
# 7 = purpose        -> bar left (Vector2.LEFT)
# 8 = fight          -> bar northwest (Vector2(-1, -1).normalized())
# ==============================================================================
@export_group("Needs (0-100)")
@export_range(0.0, 100.0) var hunger: float = 80.0:
	set(v):
		hunger = clampf(v, 0.0, 100.0)
		if is_mouse_hovered or hunger >= 40.0:
			queue_redraw()

@export_range(0.0, 100.0) var sleep_need: float = 65.0:
	set(v):
		sleep_need = clampf(v, 0.0, 100.0)
		if is_mouse_hovered:
			queue_redraw()

@export_range(0.0, 100.0) var talk_need: float = 50.0:
	set(v):
		talk_need = clampf(v, 0.0, 100.0)
		if is_mouse_hovered:
			queue_redraw()

@export_range(0.0, 100.0) var tired: float = 35.0:
	set(v):
		tired = clampf(v, 0.0, 100.0)
		if is_mouse_hovered:
			queue_redraw()

@export_range(0.0, 100.0) var boredom: float = 90.0:
	set(v):
		boredom = clampf(v, 0.0, 100.0)
		if is_mouse_hovered:
			queue_redraw()

@export_range(0.0, 100.0) var lust: float = 25.0:
	set(v):
		lust = clampf(v, 0.0, 100.0)
		if is_mouse_hovered:
			queue_redraw()

@export_range(0.0, 100.0) var purpose: float = 70.0:
	set(v):
		purpose = clampf(v, 0.0, 100.0)
		if is_mouse_hovered:
			queue_redraw()

@export_range(0.0, 100.0) var fight: float = 15.0:
	set(v):
		fight = clampf(v, 0.0, 100.0)
		if is_mouse_hovered:
			queue_redraw()

# ==============================================================================
# PASSIVE GROWTH RATES (pts/sec)
# Controls how each need increases (or decreases) passively over time.
# ==============================================================================
@export_group("Passive Growth Rates (pts/sec)")
@export var passive_growth_enabled: bool = true
@export var hunger_rate: float = 1.0
@export var sleep_need_rate: float = 1.0
@export var talk_need_rate: float = 1.0
@export var tired_rate: float = 1.0
@export var boredom_rate: float = 1.0
@export var lust_rate: float = 1.0
@export var purpose_rate: float = 1.0
@export var fight_rate: float = 1.0

# ==============================================================================
# VISUAL CONFIGURATION
# ==============================================================================
@export_group("Visuals")
@export var body_radius: float = 20.0:
	set(v):
		body_radius = maxf(v, 5.0)
		_update_collision_shape()
		queue_redraw()

@export var bar_length: float = 38.0:
	set(v):
		bar_length = maxf(v, 10.0)
		queue_redraw()

@export var bar_thickness: float = 5.0:
	set(v):
		bar_thickness = maxf(v, 1.0)
		queue_redraw()

@export var bar_gap: float = 4.0:
	set(v):
		bar_gap = maxf(v, 0.0)
		queue_redraw()

@export var show_labels: bool = true:
	set(v):
		show_labels = v
		queue_redraw()

@export var body_color: Color = Color(0.18, 0.22, 0.28, 1.0)
@export var body_outline_color: Color = Color(0.85, 0.88, 0.92, 1.0)
@export var body_outline_width: float = 2.5

# ==============================================================================
# MOVEMENT CONFIGURATION
# ==============================================================================
@export_group("Movement")
@export var can_move: bool = true
@export var move_speed: float = 70.0
@export var wander_interval_min: float = 1.2
@export var wander_interval_max: float = 3.5
@export var pause_on_hover: bool = false
@export var bounce_screen_bounds: bool = true
@export var collide_with_npcs: bool = false:
	set(v):
		collide_with_npcs = v
		collision_mask = (1 | 2) if v else 2

# ==============================================================================
# DEFINITIONS FOR THE 8 RADIAL BARS
# ==============================================================================
const NEED_DEFINITIONS: Array[Dictionary] = [
	{
		"id": 1,
		"name": "Hunger",
		"prop": "hunger",
		"rate_prop": "hunger_rate",
		"dir": Vector2(0, -1), # UP (12 o'clock)
		"color": Color(0.98, 0.52, 0.12) # Warm Orange
	},
	{
		"id": 2,
		"name": "Sleep",
		"prop": "sleep_need",
		"rate_prop": "sleep_need_rate",
		"dir": Vector2(0.70710678, -0.70710678), # NORTHEAST (1:30)
		"color": Color(0.25, 0.48, 0.98) # Night Blue
	},
	{
		"id": 3,
		"name": "Talk",
		"prop": "talk_need",
		"rate_prop": "talk_need_rate",
		"dir": Vector2(1, 0), # RIGHT (3 o'clock)
		"color": Color(0.12, 0.82, 0.88) # Cyan / Speech
	},
	{
		"id": 4,
		"name": "Tired",
		"prop": "tired",
		"rate_prop": "tired_rate",
		"dir": Vector2(0.70710678, 0.70710678), # SOUTHEAST (4:30)
		"color": Color(0.68, 0.35, 0.85) # Purple / Fatigue
	},
	{
		"id": 5,
		"name": "Boredom",
		"prop": "boredom",
		"rate_prop": "boredom_rate",
		"dir": Vector2(0, 1), # DOWN (6 o'clock)
		"color": Color(0.95, 0.76, 0.16) # Amber / Yellow
	},
	{
		"id": 6,
		"name": "Lust",
		"prop": "lust",
		"rate_prop": "lust_rate",
		"dir": Vector2(-0.70710678, 0.70710678), # SOUTHWEST (7:30)
		"color": Color(0.95, 0.25, 0.55) # Rose / Pink
	},
	{
		"id": 7,
		"name": "Purpose",
		"prop": "purpose",
		"rate_prop": "purpose_rate",
		"dir": Vector2(-1, 0), # LEFT (9 o'clock)
		"color": Color(0.22, 0.85, 0.45) # Emerald Green
	},
	{
		"id": 8,
		"name": "Fight",
		"prop": "fight",
		"rate_prop": "fight_rate",
		"dir": Vector2(-0.70710678, -0.70710678), # NORTHWEST (10:30)
		"color": Color(0.92, 0.2, 0.2) # Crimson Red
	}
]

var is_mouse_hovered: bool = false
var is_dead: bool = false
var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var arena_bounds: Rect2 = Rect2()

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	input_pickable = true
	collision_layer = 1
	collision_mask = (1 | 2) if collide_with_npcs else 2
	_update_collision_shape()

	# If isolated scene run directly (as root child), center it in window
	if get_parent() == get_tree().root:
		global_position = get_viewport_rect().size * 0.5

	# Initialize random wander
	_pick_new_wander()

func _update_collision_shape() -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = body_radius

## Returns true if hunger >= 40.0
func is_hungry() -> bool:
	return hunger >= HUNGRY_THRESHOLD

func _process(delta: float) -> void:
	if is_dead:
		return

	if passive_growth_enabled:
		_process_passive_growth(delta)

	_check_mouse_hover()
	# Draw on top of other NPCs when hovered
	z_index = 100 if is_mouse_hovered else 0

func _process_passive_growth(delta: float) -> void:
	if is_dead:
		return

	var needs_redraw: bool = false
	for need in NEED_DEFINITIONS:
		var rate: float = get(need["rate_prop"])
		if rate != 0.0:
			var prop: String = need["prop"]
			var cur_val: float = get(prop)
			var new_val: float = clampf(cur_val + rate * delta, 0.0, 100.0)
			if new_val != cur_val:
				set(prop, new_val)
				if is_mouse_hovered or (prop == "hunger" and new_val >= 40.0):
					needs_redraw = true

	# Health depletion from hunger starvation:
	# "if hunger reaches 100, the health bar starts being depleted at hunger increase rate. if health reaches 0 they die."
	if hunger >= 100.0 and hunger_rate > 0.0:
		var health_loss: float = hunger_rate * delta
		var new_health: float = clampf(health - health_loss, 0.0, 100.0)
		if new_health != health:
			health = new_health
			needs_redraw = true
		if health <= 0.0:
			die()
			return

	if needs_redraw:
		queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if can_move and not (pause_on_hover and is_mouse_hovered):
		# "if hunger >= 40 the npc is hungry. add the capacity to path towards food if hungry"
		if is_hungry():
			var target_food = _find_nearest_food()
			if target_food != null:
				_path_towards_food(target_food)
				return

		# Regular wander if not hungry or no food available
		_handle_movement(delta)

## Finds the nearest active food in the world
func _find_nearest_food() -> Food:
	var foods = get_tree().get_nodes_in_group("food")
	if foods.is_empty():
		return null

	var nearest: Food = null
	var min_dist_sq: float = INF

	for f in foods:
		if is_instance_valid(f) and f is Food and not f.is_depleted and f.amount > 0.0:
			var d_sq = global_position.distance_squared_to(f.global_position)
			if d_sq < min_dist_sq:
				min_dist_sq = d_sq
				nearest = f

	return nearest

## Steers towards target food and eats it when within contact range
func _path_towards_food(target_food: Food) -> void:
	var to_food: Vector2 = target_food.global_position - global_position
	var dist: float = to_food.length()
	var eat_range: float = body_radius + target_food.radius + 6.0

	if dist <= eat_range:
		# In eating range: consume food
		_eat_food(target_food)
		velocity = Vector2.ZERO
	else:
		# Seek food directly
		var seek_dir = to_food.normalized()
		velocity = seek_dir * (move_speed * 1.25)
		var collided = move_and_slide()
		if collided and get_slide_collision_count() > 0:
			var col = get_slide_collision(0)
			wander_direction = wander_direction.bounce(col.get_normal()).normalized()

## Consumes food from the target food source
## "the amount of food spent by an npc is equal to the amount of hunger it has."
func _eat_food(target_food: Food) -> void:
	if not is_instance_valid(target_food) or target_food.is_depleted or target_food.amount <= 0.0:
		return

	var needed_food: float = hunger
	if needed_food <= 0.0:
		return

	var spent: float = target_food.consume(needed_food)
	hunger = clampf(hunger - spent, 0.0, 100.0)

	# Quick satisfaction scale pulse
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.15, 0.88), 0.08).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)

	queue_redraw()

func _check_mouse_hover() -> void:
	if is_dead:
		return

	var mouse_pos = get_global_mouse_position()
	var dist_sq = global_position.distance_squared_to(mouse_pos)

	# Hover over body opens bars. While open, cursor staying within bars keeps them visible.
	var max_r: float = body_radius
	if is_mouse_hovered:
		max_r = body_radius + bar_gap + bar_length + (32.0 if show_labels else 6.0)

	var should_hover = dist_sq <= (max_r * max_r)
	if should_hover != is_mouse_hovered:
		is_mouse_hovered = should_hover
		queue_redraw()
		hover_changed.emit(is_mouse_hovered)

func _handle_movement(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		_pick_new_wander()

	velocity = wander_direction * move_speed
	var collided = move_and_slide()
	if collided and get_slide_collision_count() > 0:
		var col = get_slide_collision(0)
		wander_direction = wander_direction.bounce(col.get_normal()).normalized()

	# Bounce off screen / arena bounds if configured
	if bounce_screen_bounds:
		var bounds = arena_bounds if arena_bounds.size != Vector2.ZERO else get_viewport_rect()
		var margin = body_radius + 4.0
		var bounced = false

		if global_position.x < bounds.position.x + margin:
			global_position.x = bounds.position.x + margin
			wander_direction.x = absf(wander_direction.x)
			bounced = true
		elif global_position.x > bounds.position.x + bounds.size.x - margin:
			global_position.x = bounds.position.x + bounds.size.x - margin
			wander_direction.x = -absf(wander_direction.x)
			bounced = true

		if global_position.y < bounds.position.y + margin:
			global_position.y = bounds.position.y + margin
			wander_direction.y = absf(wander_direction.y)
			bounced = true
		elif global_position.y > bounds.position.y + bounds.size.y - margin:
			global_position.y = bounds.position.y + bounds.size.y - margin
			wander_direction.y = -absf(wander_direction.y)
			bounced = true

		if bounced:
			wander_direction = wander_direction.normalized()

func _pick_new_wander() -> void:
	wander_timer = randf_range(wander_interval_min, wander_interval_max)
	# 80% chance wander, 20% brief idle
	if randf() < 0.8:
		wander_direction = Vector2.from_angle(randf() * TAU)
	else:
		wander_direction = Vector2.ZERO

## Handles death when health reaches 0: stops NPC, fades out, and disappears
func die() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit(self)

	# Disable physics, movement, and interaction immediately
	can_move = false
	velocity = Vector2.ZERO
	input_pickable = false
	is_mouse_hovered = false
	collision_layer = 0
	collision_mask = 0
	queue_redraw()

	# Smooth death animation: fade opacity out and shrink slightly before disappearing
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", scale * 0.7, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:r", 1.5, 0.25)
	# Disappear completely when fade finishes
	tween.chain().tween_callback(queue_free)

## Helper function to assign random needs for stress testing
func randomize_needs() -> void:
	health = 100.0
	# Hunger starts between 15 and 65
	hunger = randf_range(15.0, 65.0)
	sleep_need = randf_range(0.0, 100.0)
	talk_need = randf_range(0.0, 100.0)
	tired = randf_range(0.0, 100.0)
	boredom = randf_range(0.0, 100.0)
	lust = randf_range(0.0, 100.0)
	purpose = randf_range(0.0, 100.0)
	fight = randf_range(0.0, 100.0)

## Helper to set a specific need's passive growth rate
func set_need_rate(prop_name: String, rate: float) -> void:
	for need in NEED_DEFINITIONS:
		if need["prop"] == prop_name or need["rate_prop"] == prop_name:
			set(need["rate_prop"], rate)
			return

## Helper to set all need growth rates simultaneously
func set_all_rates(rate: float) -> void:
	for need in NEED_DEFINITIONS:
		set(need["rate_prop"], rate)

# ==============================================================================
# DRAWING
# ==============================================================================
func _draw() -> void:
	# 1. Circle body (button-like appearance)
	var active_outline: Color = Color.WHITE if is_mouse_hovered else body_outline_color
	var active_width: float = body_outline_width + (1.0 if is_mouse_hovered else 0.0)

	# Hover glow aura
	if is_mouse_hovered and not is_dead:
		draw_circle(Vector2.ZERO, body_radius + 4.0, Color(1, 1, 1, 0.18))

	# Disc body
	draw_circle(Vector2.ZERO, body_radius, body_color)

	# Inner button ridge / tactile bevel
	draw_circle(Vector2.ZERO, body_radius * 0.65, body_color.lightened(0.12))

	# Circle border (glows amber if hungry and unhovered)
	if is_hungry() and not is_mouse_hovered:
		var hungry_glow = Color(0.98, 0.52, 0.12, 0.85)
		draw_arc(Vector2.ZERO, body_radius, 0.0, TAU, 36, hungry_glow, active_width + 0.5, true)
	else:
		draw_arc(Vector2.ZERO, body_radius, 0.0, TAU, 36, active_outline, active_width, true)

	# Center button pip (orange when hungry)
	var pip_color = Color(0.98, 0.52, 0.12) if is_hungry() else active_outline
	draw_circle(Vector2.ZERO, 3.0, pip_color)

	# 2. Draw the 8 radial bars ONLY if mouse is over the NPC and NPC is not dead
	if is_mouse_hovered and not is_dead:
		_draw_bars()

	# 3. Draw health bar
	if not is_dead and (show_health_always or health < 100.0 or is_mouse_hovered):
		_draw_health_bar()

func _draw_health_bar() -> void:
	var font = ThemeDB.fallback_font
	# Position above hunger radial bar if hovered, or directly above circle if unhovered
	var bar_y: float = -(body_radius + bar_length + 28.0) if is_mouse_hovered else -(body_radius + 9.0)
	var bar_w: float = 32.0
	var bar_h: float = 5.0
	var bar_rect: Rect2 = Rect2(-bar_w * 0.5, bar_y - bar_h * 0.5, bar_w, bar_h)

	# Background track
	draw_rect(bar_rect, Color(0.06, 0.08, 0.1, 0.9), true)

	# Border outline (pulses red when taking starvation damage from hunger == 100)
	var border_col: Color = Color(0.3, 0.36, 0.45, 0.9)
	if hunger >= 100.0:
		var pulse: float = sin(Time.get_ticks_msec() * 0.012) * 0.5 + 0.5
		border_col = Color(1.0, 0.25, 0.25, 1.0).lerp(Color(0.5, 0.1, 0.1, 0.9), pulse)
	draw_rect(bar_rect, border_col, false, 1.0)

	# Health Fill
	var hp_ratio: float = clampf(health / 100.0, 0.0, 1.0)
	if hp_ratio > 0.005:
		var hp_col: Color
		if hp_ratio > 0.5:
			hp_col = Color(0.2, 0.85, 0.35).lerp(Color(0.95, 0.8, 0.15), (1.0 - hp_ratio) * 2.0)
		else:
			hp_col = Color(0.95, 0.8, 0.15).lerp(Color(0.92, 0.2, 0.2), (0.5 - hp_ratio) * 2.0)

		var fill_w: float = (bar_w - 2.0) * hp_ratio
		var fill_rect: Rect2 = Rect2(-bar_w * 0.5 + 1.0, bar_y - bar_h * 0.5 + 1.0, fill_w, bar_h - 2.0)
		draw_rect(fill_rect, hp_col, true)

	# Text readout when hovered or actively taking starvation damage
	if font != null and (is_mouse_hovered or hunger >= 100.0 or health < 100.0):
		var hp_text: String = "HP: %d" % int(round(health))
		if hunger >= 100.0:
			hp_text = "HP: %d (STARVING)" % int(round(health))
		var font_size: int = 9
		var sz: Vector2 = font.get_string_size(hp_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos: Vector2 = Vector2(-sz.x * 0.5, bar_rect.position.y - 3.0)
		draw_string(font, text_pos, hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func _draw_bars() -> void:
	var font = ThemeDB.fallback_font
	var start_dist: float = body_radius + bar_gap
	var end_dist: float = start_dist + bar_length

	for need in NEED_DEFINITIONS:
		var dir: Vector2 = need["dir"]
		var val: float = get(need["prop"])
		var ratio: float = clampf(val / 100.0, 0.0, 1.0)
		var color: Color = need["color"]

		var start_pt: Vector2 = dir * start_dist
		var max_pt: Vector2 = dir * end_dist
		var fill_pt: Vector2 = dir * (start_dist + (bar_length * ratio))

		# Background slot track (dark track showing the 0-100 full capacity)
		draw_line(start_pt, max_pt, Color(0.08, 0.1, 0.12, 0.8), bar_thickness + 2.0, true)
		draw_line(start_pt, max_pt, Color(0.24, 0.28, 0.34, 0.9), bar_thickness, true)

		# Filled bar (emanating from circle outward)
		if ratio > 0.01:
			draw_line(start_pt, fill_pt, color, bar_thickness, true)
			# Small rounded pip at end of fill
			draw_circle(fill_pt, bar_thickness * 0.5, color.lightened(0.25))

		# End cap tick mark (100% boundary marker)
		var perp = dir.orthogonal() * (bar_thickness * 0.8)
		draw_line(max_pt - perp, max_pt + perp, Color(0.75, 0.8, 0.88, 0.85), 1.5, true)

		# Optional text label & value pill at outer tip
		if show_labels and font != null:
			var label_dist: float = end_dist + 14.0
			var center_pos: Vector2 = dir * label_dist
			var text: String = "%s: %d" % [need["name"], int(round(val))]
			if need["prop"] == "hunger" and val >= HUNGRY_THRESHOLD:
				text = "%s: %d (HUNGRY)" % [need["name"], int(round(val))]

			var font_size: int = 10
			var str_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)

			# Position pill box
			var pill_rect: Rect2 = Rect2(center_pos - (str_size * 0.5) - Vector2(4, 2), str_size + Vector2(8, 4))
			draw_rect(pill_rect, Color(0.08, 0.1, 0.12, 0.92), true)
			draw_rect(pill_rect, color * 0.7, false, 1.0)

			# Center text baseline inside the pill
			var text_pos: Vector2 = Vector2(
				pill_rect.position.x + 4.0,
				pill_rect.position.y + pill_rect.size.y - 4.0
			)
			draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
