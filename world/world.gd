class_name World
extends Node2D

const NPC_SCENE = preload("res://npc/npc.tscn")
const FOOD_SCENE = preload("res://food/food.tscn")

@export var arena_size: Vector2 = Vector2(1600, 1000)
@export var initial_npc_count: int = 15

# Nodes
@onready var food_container: Node2D = $FoodContainer
@onready var npc_container: Node2D = $NPCContainer
@onready var camera: Camera2D = $Camera2D
@onready var walls_body: StaticBody2D = $ArenaWalls
@onready var background: Node2D = $ArenaBackground

# Left HUD UI Nodes
@onready var fps_label: Label = %FPSLabel
@onready var frame_time_label: Label = %FrameTimeLabel
@onready var npc_count_label: Label = %NPCCountLabel
@onready var deaths_label: Label = %DeathsLabel
@onready var food_count_label: Label = %FoodCountLabel
@onready var move_toggle_btn: Button = %MoveToggleBtn
@onready var speed_slider: HSlider = %SpeedSlider
@onready var speed_val_label: Label = %SpeedValLabel
@onready var labels_toggle_btn: Button = %LabelsToggleBtn
@onready var npcs_collide_btn: Button = %NPCsCollideBtn

# Food UI Controls
@onready var food_amount_slider: HSlider = %FoodAmountSlider
@onready var food_amount_val_label: Label = %FoodAmountValLabel
@onready var drop_center_food_btn: Button = %DropCenterFoodBtn
@onready var clear_food_btn: Button = %ClearFoodBtn

# Right Growth Panel UI Nodes
@onready var master_scale_slider: HSlider = %MasterScaleSlider
@onready var master_scale_label: Label = %MasterScaleLabel
@onready var need_sliders_vbox: VBoxContainer = %NeedSlidersVBox
@onready var freeze_growth_btn: Button = %FreezeGrowthBtn
@onready var default_growth_btn: Button = %DefaultGrowthBtn
@onready var fast_growth_btn: Button = %FastGrowthBtn

# Camera dragging state
var is_panning: bool = false
var pan_drag_start: Vector2 = Vector2.ZERO
var camera_pan_start: Vector2 = Vector2.ZERO

# Simulation state
var movement_enabled: bool = true
var current_speed: float = 75.0
var show_labels: bool = true
var collide_between_npcs: bool = false
var food_drop_amount: float = 50.0

# Passive growth settings
var growth_rates: Dictionary = {
	"hunger": 1.0,
	"sleep_need": 1.0,
	"talk_need": 1.0,
	"tired": 1.0,
	"boredom": 1.0,
	"lust": 1.0,
	"purpose": 1.0,
	"fight": 1.0
}
var master_growth_multiplier: float = 1.0
var slider_controls: Dictionary = {}
var total_deaths: int = 0

func _ready() -> void:
	_setup_arena_walls()
	_setup_camera()
	_setup_growth_sliders_ui()
	_connect_ui_signals()

	# Spawn initial batch of NPCs
	spawn_npcs(initial_npc_count)

func _process(delta: float) -> void:
	_update_fps_metrics(delta)
	_handle_camera_keyboard(delta)

func _update_fps_metrics(delta: float) -> void:
	var fps = Engine.get_frames_per_second()
	if fps_label:
		fps_label.text = "FPS: %d" % fps
		if fps >= 55:
			fps_label.modulate = Color(0.3, 0.9, 0.4) # Green
		elif fps >= 30:
			fps_label.modulate = Color(0.95, 0.8, 0.2) # Yellow
		else:
			fps_label.modulate = Color(0.95, 0.3, 0.3) # Red

	if frame_time_label:
		frame_time_label.text = "Frame: %.1f ms" % (delta * 1000.0)

	if npc_count_label:
		var living: int = 0
		for child in npc_container.get_children():
			if child is NPC and not child.is_dead:
				living += 1
		npc_count_label.text = "NPCs: %d" % living

	if deaths_label:
		deaths_label.text = "Starved: %d" % total_deaths

	if food_count_label and food_container:
		var total_food: float = 0.0
		var active_items: int = 0
		for child in food_container.get_children():
			if child is Food and not child.is_depleted:
				total_food += child.amount
				active_items += 1
		food_count_label.text = "Food: %d (%d pts)" % [active_items, int(round(total_food))]

# ==============================================================================
# PASSIVE GROWTH SLIDERS & CONTROLS
# ==============================================================================
func _setup_growth_sliders_ui() -> void:
	if not need_sliders_vbox:
		return

	# Clear any placeholders
	for c in need_sliders_vbox.get_children():
		c.queue_free()

	# Create a slider row for each of the 8 needs
	for need in NPC.NEED_DEFINITIONS:
		var prop: String = need["prop"]
		var default_rate: float = growth_rates.get(prop, 1.0)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		# 1. Color indicator swatch
		var swatch_center = CenterContainer.new()
		swatch_center.custom_minimum_size = Vector2(16, 16)
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(10, 10)
		swatch.color = need["color"]
		swatch_center.add_child(swatch)
		row.add_child(swatch_center)

		# 2. Need Name Label
		var name_lbl = Label.new()
		name_lbl.text = need["name"]
		name_lbl.custom_minimum_size = Vector2(65, 0)
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", (need["color"] as Color).lightened(0.25))
		row.add_child(name_lbl)

		# 3. Growth Rate Slider
		var slider = HSlider.new()
		slider.min_value = -5.0
		slider.max_value = 15.0
		slider.step = 0.1
		slider.value = default_rate
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slider)

		# 4. Rate Value Readout Label
		var val_lbl = Label.new()
		val_lbl.custom_minimum_size = Vector2(55, 0)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_size_override("font_size", 12)
		val_lbl.text = _format_rate_text(default_rate)
		row.add_child(val_lbl)

		# Store references for presets / sync
		slider_controls[prop] = {
			"slider": slider,
			"label": val_lbl
		}

		# Wire slider change
		slider.value_changed.connect(func(new_val: float):
			_on_need_slider_changed(prop, new_val, val_lbl)
		)

		need_sliders_vbox.add_child(row)

func _format_rate_text(rate: float) -> String:
	if rate > 0.001:
		return "+%.1f/s" % rate
	elif rate < -0.001:
		return "%.1f/s" % rate
	else:
		return "0.0/s"

func _on_need_slider_changed(prop: String, new_rate: float, val_lbl: Label) -> void:
	growth_rates[prop] = new_rate
	if val_lbl:
		val_lbl.text = _format_rate_text(new_rate)

	var effective_rate = new_rate * master_growth_multiplier
	for child in npc_container.get_children():
		if child is NPC:
			child.set_need_rate(prop, effective_rate)

func set_all_growth_rates(rate: float) -> void:
	for prop in slider_controls:
		var ctrl = slider_controls[prop]
		if ctrl.has("slider"):
			ctrl["slider"].value = rate

func _on_master_scale_changed(val: float) -> void:
	master_growth_multiplier = val
	if master_scale_label:
		master_scale_label.text = "%.1fx" % val

	for prop in growth_rates:
		var effective_rate = growth_rates[prop] * master_growth_multiplier
		for child in npc_container.get_children():
			if child is NPC:
				child.set_need_rate(prop, effective_rate)

# ==============================================================================
# FOOD MANAGEMENT
# ==============================================================================
func spawn_food(pos: Vector2, amount: float) -> Food:
	var food: Food = FOOD_SCENE.instantiate()
	food.global_position = pos
	food.amount = amount
	food.max_amount = amount
	food_container.add_child(food)
	return food

func clear_all_food() -> void:
	for child in food_container.get_children():
		child.queue_free()

func _set_food_drop_amount(amount: float) -> void:
	food_drop_amount = amount
	if food_amount_slider:
		food_amount_slider.value = amount
	if food_amount_val_label:
		food_amount_val_label.text = "%d pts" % int(amount)

# ==============================================================================
# NPC MANAGEMENT
# ==============================================================================
func spawn_single_npc(pos: Vector2 = Vector2.ZERO, randomize_values: bool = true) -> NPC:
	var npc: NPC = NPC_SCENE.instantiate()

	if pos == Vector2.ZERO:
		var margin = 60.0
		pos = Vector2(
			randf_range(margin, arena_size.x - margin),
			randf_range(margin, arena_size.y - margin)
		)

	npc.global_position = pos
	npc.arena_bounds = Rect2(Vector2.ZERO, arena_size)
	npc.can_move = movement_enabled
	npc.move_speed = current_speed
	npc.show_labels = show_labels
	npc.collide_with_npcs = collide_between_npcs

	# Apply current growth rates to new NPC
	for prop in growth_rates:
		npc.set_need_rate(prop, growth_rates[prop] * master_growth_multiplier)

	# Connect death signal
	npc.died.connect(_on_npc_died)

	if randomize_values:
		npc.randomize_needs()

	npc_container.add_child(npc)
	return npc

func _on_npc_died(_npc: NPC) -> void:
	total_deaths += 1
	if deaths_label:
		deaths_label.text = "Starved: %d" % total_deaths

func spawn_npcs(count: int) -> void:
	for i in range(count):
		spawn_single_npc()

func clear_all_npcs() -> void:
	for child in npc_container.get_children():
		child.queue_free()
	total_deaths = 0
	if deaths_label:
		deaths_label.text = "Starved: 0"

func set_movement_active(active: bool) -> void:
	movement_enabled = active
	for child in npc_container.get_children():
		if child is NPC:
			child.can_move = active
	if move_toggle_btn:
		move_toggle_btn.text = "Movement: ON" if active else "Movement: OFF"

func randomize_all_npc_needs() -> void:
	for child in npc_container.get_children():
		if child is NPC:
			child.randomize_needs()

func set_show_labels(enable: bool) -> void:
	show_labels = enable
	for child in npc_container.get_children():
		if child is NPC:
			child.show_labels = enable
	if labels_toggle_btn:
		labels_toggle_btn.text = "Labels: ON" if enable else "Labels: OFF"

func set_npcs_collide(enable: bool) -> void:
	collide_between_npcs = enable
	for child in npc_container.get_children():
		if child is NPC:
			child.collide_with_npcs = enable
	if npcs_collide_btn:
		npcs_collide_btn.text = "NPC Collisions: ON" if enable else "NPC Collisions: OFF"

# ==============================================================================
# ARENA WALLS & SETUP
# ==============================================================================
func _setup_arena_walls() -> void:
	if not walls_body:
		return

	walls_body.collision_layer = 2
	walls_body.collision_mask = 0

	var thickness = 30.0
	var w = arena_size.x
	var h = arena_size.y

	# Top, Bottom, Left, Right
	_create_wall_shape(Vector2(w * 0.5, -thickness * 0.5), Vector2(w + thickness * 2, thickness))
	_create_wall_shape(Vector2(w * 0.5, h + thickness * 0.5), Vector2(w + thickness * 2, thickness))
	_create_wall_shape(Vector2(-thickness * 0.5, h * 0.5), Vector2(thickness, h + thickness * 2))
	_create_wall_shape(Vector2(w + thickness * 0.5, h * 0.5), Vector2(thickness, h + thickness * 2))

func _create_wall_shape(pos: Vector2, size: Vector2) -> void:
	var col = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = size
	col.shape = box
	col.position = pos
	walls_body.add_child(col)

func _setup_camera() -> void:
	if camera:
		camera.position = arena_size * 0.5

# ==============================================================================
# CAMERA PAN & ZOOM & FOOD DROP
# ==============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Zoom with mouse wheel
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(1.15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(0.85)
		# Pan with Right or Middle Mouse Button
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				pan_drag_start = event.position
				camera_pan_start = camera.position
			else:
				is_panning = false
		# Left-Click on open ground drops food with chosen amount!
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_world = get_global_mouse_position()
			if Rect2(Vector2.ZERO, arena_size).has_point(mouse_world):
				spawn_food(mouse_world, food_drop_amount)

	elif event is InputEventMouseMotion and is_panning:
		var delta_pos = (event.position - pan_drag_start) / camera.zoom.x
		camera.position = camera_pan_start - delta_pos

func _zoom_camera(factor: float) -> void:
	var prev_zoom = camera.zoom
	var new_zoom = (prev_zoom * factor).clamp(Vector2(0.25, 0.25), Vector2(3.0, 3.0))
	camera.zoom = new_zoom

func _handle_camera_keyboard(delta: float) -> void:
	var cam_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		cam_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		cam_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		cam_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		cam_dir.x += 1.0

	if cam_dir != Vector2.ZERO:
		var speed = 600.0 / camera.zoom.x
		camera.position += cam_dir.normalized() * speed * delta

# ==============================================================================
# UI EVENT HANDLERS
# ==============================================================================
func _connect_ui_signals() -> void:
	var add_1_btn = get_node_or_null("%Add1Btn")
	if add_1_btn: add_1_btn.pressed.connect(func(): spawn_npcs(1))

	var add_10_btn = get_node_or_null("%Add10Btn")
	if add_10_btn: add_10_btn.pressed.connect(func(): spawn_npcs(10))

	var add_50_btn = get_node_or_null("%Add50Btn")
	if add_50_btn: add_50_btn.pressed.connect(func(): spawn_npcs(50))

	var add_200_btn = get_node_or_null("%Add200Btn")
	if add_200_btn: add_200_btn.pressed.connect(func(): spawn_npcs(200))

	var clear_btn = get_node_or_null("%ClearBtn")
	if clear_btn: clear_btn.pressed.connect(clear_all_npcs)

	if move_toggle_btn:
		move_toggle_btn.pressed.connect(func(): set_movement_active(not movement_enabled))

	var rand_btn = get_node_or_null("%RandNeedsBtn")
	if rand_btn: rand_btn.pressed.connect(randomize_all_npc_needs)

	if labels_toggle_btn:
		labels_toggle_btn.pressed.connect(func(): set_show_labels(not show_labels))

	if npcs_collide_btn:
		npcs_collide_btn.pressed.connect(func(): set_npcs_collide(not collide_between_npcs))

	if speed_slider:
		speed_slider.value = current_speed
		speed_slider.value_changed.connect(_on_speed_slider_changed)
		if speed_val_label:
			speed_val_label.text = "%d px/s" % int(current_speed)

	var reset_cam_btn = get_node_or_null("%ResetCamBtn")
	if reset_cam_btn:
		reset_cam_btn.pressed.connect(_reset_camera)

	# Food controls
	if food_amount_slider:
		food_amount_slider.value = food_drop_amount
		food_amount_slider.value_changed.connect(func(v: float):
			food_drop_amount = v
			if food_amount_val_label:
				food_amount_val_label.text = "%d pts" % int(v)
		)

	if drop_center_food_btn:
		drop_center_food_btn.pressed.connect(func():
			spawn_food(arena_size * 0.5, food_drop_amount)
		)

	if clear_food_btn:
		clear_food_btn.pressed.connect(clear_all_food)

	var f25 = get_node_or_null("%Food25Btn")
	if f25: f25.pressed.connect(func(): _set_food_drop_amount(25.0))
	var f50 = get_node_or_null("%Food50Btn")
	if f50: f50.pressed.connect(func(): _set_food_drop_amount(50.0))
	var f100 = get_node_or_null("%Food100Btn")
	if f100: f100.pressed.connect(func(): _set_food_drop_amount(100.0))
	var f200 = get_node_or_null("%Food200Btn")
	if f200: f200.pressed.connect(func(): _set_food_drop_amount(200.0))

	# Right growth panel controls
	if master_scale_slider:
		master_scale_slider.value_changed.connect(_on_master_scale_changed)

	if freeze_growth_btn:
		freeze_growth_btn.pressed.connect(func(): set_all_growth_rates(0.0))

	if default_growth_btn:
		default_growth_btn.pressed.connect(func(): set_all_growth_rates(1.0))

	if fast_growth_btn:
		fast_growth_btn.pressed.connect(func(): set_all_growth_rates(3.0))

func _on_speed_slider_changed(value: float) -> void:
	current_speed = value
	if speed_val_label:
		speed_val_label.text = "%d px/s" % int(value)
	for child in npc_container.get_children():
		if child is NPC:
			child.move_speed = current_speed

func _reset_camera() -> void:
	camera.position = arena_size * 0.5
	camera.zoom = Vector2.ONE
