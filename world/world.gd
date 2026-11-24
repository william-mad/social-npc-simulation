class_name World
extends Node2D

const NPC_SCENE = preload("res://npc/npc.tscn")
const FOOD_SCENE = preload("res://food/food.tscn")
<<<<<<< Updated upstream
=======
const SLEEP_SPOT_SCENE = preload("res://sleep_spot/sleep_spot.tscn")
const RECREATION_SPOT_SCENE = preload("res://recreation_spot/recreation_spot.tscn")
const NPC_INSPECTOR_SCRIPT = preload("res://ui/npc_inspector.gd")

enum ClickTool {
	FOOD,
	SLEEP_SPOT,
	RECREATION_SPOT
}

enum TimeOfDay {
	DAY,
	NIGHT
}
>>>>>>> Stashed changes

enum LeftTab {
	SIM,
	PLACE
}

enum RightTab {
	GROWTH,
	SLEEP,
	RECREATION,
	GENDER
}

@export var arena_size: Vector2 = Vector2(1600, 1000)
@export var initial_npc_count: int = 15

# Nodes
@onready var food_container: Node2D = $FoodContainer
@onready var npc_container: Node2D = $NPCContainer
@onready var camera: Camera2D = $Camera2D
@onready var walls_body: StaticBody2D = $ArenaWalls
@onready var background: Node2D = $ArenaBackground

# Left Unified Panel UI Nodes
@onready var retract_left_panel_btn: Button = %RetractLeftPanelBtn
@onready var left_panel_content: VBoxContainer = %LeftPanelContent
@onready var left_tab_sim_btn: Button = %LeftTabSimBtn
@onready var left_tab_place_btn: Button = %LeftTabPlaceBtn
@onready var left_sim_content: VBoxContainer = %LeftSimContent
@onready var left_place_content: VBoxContainer = %LeftPlaceContent
@onready var npc_inspector: NPC_INSPECTOR_SCRIPT = %NPCInspector

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

<<<<<<< Updated upstream
# Right Growth Panel UI Nodes
=======
# Unified Right Sliders Panel UI Nodes (4 Symbol Tabs: Growth / Sleep / Rec / Gender)
@onready var retract_right_panel_btn: Button = %RetractRightPanelBtn
@onready var right_panel_content: VBoxContainer = %RightPanelContent
@onready var right_tab_growth_btn: Button = %RightTabGrowthBtn
@onready var right_tab_sleep_btn: Button = %RightTabSleepBtn
@onready var right_tab_rec_btn: Button = %RightTabRecBtn
@onready var right_tab_gender_btn: Button = %RightTabGenderBtn

@onready var main_sliders_content: VBoxContainer = %MainSlidersContent
@onready var time_of_day_label: Label = %TimeOfDayLabel
@onready var flip_day_night_btn: Button = %FlipDayNightBtn
@onready var pause_cycle_btn: Button = %PauseCycleBtn
@onready var edit_day_sliders_btn: Button = %EditDaySlidersBtn
@onready var edit_night_sliders_btn: Button = %EditNightSlidersBtn
>>>>>>> Stashed changes
@onready var master_scale_slider: HSlider = %MasterScaleSlider
@onready var master_scale_label: Label = %MasterScaleLabel
@onready var need_sliders_vbox: VBoxContainer = %NeedSlidersVBox
@onready var freeze_growth_btn: Button = %FreezeGrowthBtn
@onready var default_growth_btn: Button = %DefaultGrowthBtn
@onready var fast_growth_btn: Button = %FastGrowthBtn

<<<<<<< Updated upstream
# Camera dragging state
=======
# Sleep Tab UI Nodes
@onready var sleep_sliders_content: VBoxContainer = %SleepSlidersContent
@onready var sleep_need_sliders_vbox: VBoxContainer = %SleepNeedSlidersVBox
@onready var sleep_freeze_btn: Button = %SleepFreezeBtn
@onready var sleep_default_btn: Button = %SleepDefaultBtn
@onready var sleep_fast_rest_btn: Button = %SleepFastRestBtn

# Recreation Tab UI Nodes
@onready var rec_sliders_content: VBoxContainer = %RecSlidersContent
@onready var rec_need_sliders_vbox: VBoxContainer = %RecNeedSlidersVBox
@onready var rec_freeze_btn: Button = %RecFreezeBtn
@onready var rec_default_btn: Button = %RecDefaultBtn
@onready var rec_high_fun_btn: Button = %RecHighFunBtn

# Gender & Romance Tab UI Nodes
@onready var gender_content: VBoxContainer = %GenderContent
@onready var rom_both_btn: Button = %RomBothBtn
@onready var rom_male_btn: Button = %RomMaleBtn
@onready var rom_female_btn: Button = %RomFemaleBtn
@onready var edit_male_mult_btn: Button = %EditMaleMultBtn
@onready var edit_female_mult_btn: Button = %EditFemaleMultBtn
@onready var gender_scale_title: Label = %GenderScaleTitle
@onready var gender_scale_slider: HSlider = %GenderScaleSlider
@onready var gender_scale_label: Label = %GenderScaleLabel
@onready var gender_reset_btn: Button = %GenderResetBtn
@onready var gender_need_sliders_vbox: VBoxContainer = %GenderNeedSlidersVBox

# Panels & Unified Top Bar Controls
@onready var left_panel: PanelContainer = %LeftPanelContainer
@onready var right_panel: PanelContainer = %RightPanelContainer
@onready var top_controls_panel: PanelContainer = %TopControlsContainer
@onready var toggle_menu_btn: Button = %ToggleMenuBtn
@onready var toggle_sliders_btn: Button = %ToggleSlidersBtn
@onready var toggle_inspector_btn: Button = %ToggleInspectorBtn
@onready var toggle_all_ui_btn: Button = %ToggleAllUIBtn
@onready var close_left_btn: Button = %CloseLeftBtn
@onready var close_right_btn: Button = %CloseRightBtn

var active_left_tab: LeftTab = LeftTab.SIM
var active_right_tab: RightTab = RightTab.GROWTH

# Camera dragging & NPC follow state
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
=======
	set_active_click_tool(ClickTool.FOOD)
	set_romance_initiator_mode(NPC.RomanceInitiator.BOTH)
	set_editing_time_of_day(TimeOfDay.DAY)
	set_editing_gender(NPC.Gender.MALE)
	set_left_tab(LeftTab.SIM)
	set_right_tab(RightTab.GROWTH)
	set_left_panel_expanded(true)
	set_right_panel_expanded(true)
	_update_day_night_ui()
	_update_inspector_top_button()
>>>>>>> Stashed changes

	# Spawn initial batch of NPCs
	spawn_npcs(initial_npc_count)

func _process(delta: float) -> void:
	_update_fps_metrics(delta)
	_handle_camera_keyboard(delta)
<<<<<<< Updated upstream
=======
	_process_camera_follow(delta)

func _process_day_night_cycle(delta: float) -> void:
	if not day_night_cycle_paused:
		time_of_day_elapsed += delta
		var phase_dur: float = day_duration if current_time_of_day == TimeOfDay.DAY else night_duration
		if time_of_day_elapsed >= phase_dur:
			time_of_day_elapsed = 0.0
			var next_phase: TimeOfDay = TimeOfDay.NIGHT if current_time_of_day == TimeOfDay.DAY else TimeOfDay.DAY
			set_time_of_day(next_phase)

	if background and "night_blend" in background:
		var target_blend: float = 1.0 if current_time_of_day == TimeOfDay.NIGHT else 0.0
		background.night_blend = move_toward(background.night_blend, target_blend, delta * 1.4)

	_update_day_night_ui()

func set_time_of_day(phase: TimeOfDay) -> void:
	current_time_of_day = phase
	time_of_day_elapsed = 0.0
	_apply_active_growth_rates_to_all()
	_update_day_night_ui()

func _update_day_night_ui() -> void:
	var is_day: bool = (current_time_of_day == TimeOfDay.DAY)
	var phase_dur: float = day_duration if is_day else night_duration
	var remaining: int = maxi(0, int(ceil(phase_dur - time_of_day_elapsed)))
	var phase_icon: String = "☀" if is_day else "☾"
	var phase_word: String = "DAY" if is_day else "NIGHT"

	if time_of_day_label:
		var suffix: String = "paused" if day_night_cycle_paused else ("%ds" % remaining)
		time_of_day_label.text = "%s %s (%s)" % [phase_icon, phase_word, suffix]
		time_of_day_label.modulate = Color(1.0, 0.9, 0.5) if is_day else Color(0.65, 0.78, 1.0)

	if retract_right_panel_btn:
		var is_exp: bool = right_panel_content and right_panel_content.visible
		var arrow: String = "▾" if is_exp else "▸"
		retract_right_panel_btn.text = "%s ⚙ Sliders (%s %s)" % [arrow, phase_icon, "Day" if is_day else "Night"]

	if right_tab_growth_btn:
		var g_active: bool = (active_right_tab == RightTab.GROWTH)
		right_tab_growth_btn.text = ("● %s" if g_active else "%s") % phase_icon

	if edit_day_sliders_btn:
		var day_sel: bool = (editing_time_of_day == TimeOfDay.DAY)
		var live_tag: String = " ★" if is_day else ""
		edit_day_sliders_btn.text = ("● ☀ Day" if day_sel else "☀ Day") + live_tag
		edit_day_sliders_btn.modulate = Color(1.0, 0.9, 0.55) if day_sel else Color(0.75, 0.78, 0.85)
	if edit_night_sliders_btn:
		var night_sel: bool = (editing_time_of_day == TimeOfDay.NIGHT)
		var live_tag: String = " ★" if not is_day else ""
		edit_night_sliders_btn.text = ("● ☾ Night" if night_sel else "☾ Night") + live_tag
		edit_night_sliders_btn.modulate = Color(0.68, 0.8, 1.0) if night_sel else Color(0.75, 0.78, 0.85)

	_update_right_top_button_text()
>>>>>>> Stashed changes

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
		frame_time_label.text = "%.1fms" % (delta * 1000.0)

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
		food_count_label.text = "Food: %d" % active_items

<<<<<<< Updated upstream
=======
	if sleep_spot_count_label and sleep_spot_container:
		var spot_count: int = 0
		var occupied: int = 0
		var capacity: int = 0
		for child in sleep_spot_container.get_children():
			if child is SleepSpot:
				var spot: SleepSpot = child as SleepSpot
				spot_count += 1
				occupied += spot.get_sleeping_count()
				capacity += spot.max_capacity
		sleep_spot_count_label.text = "%d (%d/%d)" % [spot_count, occupied, capacity]

	if rec_spot_count_label and recreation_spot_container:
		var spot_count: int = 0
		var occupied: int = 0
		var capacity: int = 0
		for child in recreation_spot_container.get_children():
			if child is RecreationSpot:
				var spot: RecreationSpot = child as RecreationSpot
				spot_count += 1
				occupied += spot.get_active_count()
				capacity += spot.max_capacity
		rec_spot_count_label.text = "%d (%d/%d)" % [spot_count, occupied, capacity]

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
=======
func _setup_max_effect_sliders_ui() -> void:
	if not max_effects_sliders_vbox:
		return

	for c in max_effects_sliders_vbox.get_children():
		c.queue_free()

	var defs: Array[Dictionary] = [
		{
			"key": "max_hunger_health_drain_rate",
			"label": "Hunger → -HP",
			"color": Color(0.98, 0.42, 0.2),
			"default": max_hunger_health_drain_rate,
			"is_drain": true
		},
		{
			"key": "max_boredom_anger_rate",
			"label": "Bored → +Anger",
			"color": Color(0.95, 0.76, 0.16),
			"default": max_boredom_anger_rate,
			"is_drain": false
		},
		{
			"key": "max_purpose_anger_rate",
			"label": "Purp → +Anger",
			"color": Color(0.22, 0.85, 0.45),
			"default": max_purpose_anger_rate,
			"is_drain": false
		},
		{
			"key": "max_tired_anger_rate",
			"label": "Tired → +Anger",
			"color": Color(0.68, 0.35, 0.85),
			"default": max_tired_anger_rate,
			"is_drain": false
		}
	]

	for item in defs:
		var key: String = item["key"]
		var is_drain: bool = item["is_drain"]
		var default_val: float = item["default"]

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var swatch_center = CenterContainer.new()
		swatch_center.custom_minimum_size = Vector2(16, 16)
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(10, 10)
		swatch.color = item["color"]
		swatch_center.add_child(swatch)
		row.add_child(swatch_center)

		var name_lbl = Label.new()
		name_lbl.text = item["label"]
		name_lbl.custom_minimum_size = Vector2(96, 0)
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", (item["color"] as Color).lightened(0.22))
		row.add_child(name_lbl)

		var slider = HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 20.0
		slider.step = 0.1
		slider.value = default_val
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slider)

		var val_lbl = Label.new()
		val_lbl.custom_minimum_size = Vector2(54, 0)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_size_override("font_size", 11)
		val_lbl.text = _format_rate_text(-default_val if is_drain else default_val)
		row.add_child(val_lbl)

		max_effect_slider_controls[key] = {
			"slider": slider,
			"label": val_lbl
		}

		slider.value_changed.connect(func(new_val: float):
			_on_max_effect_slider_changed(key, new_val, val_lbl, is_drain)
		)

		max_effects_sliders_vbox.add_child(row)

func _on_max_effect_slider_changed(key: String, new_val: float, val_lbl: Label, is_drain: bool) -> void:
	match key:
		"max_hunger_health_drain_rate":
			max_hunger_health_drain_rate = new_val
		"max_boredom_anger_rate":
			max_boredom_anger_rate = new_val
		"max_purpose_anger_rate":
			max_purpose_anger_rate = new_val
		"max_tired_anger_rate":
			max_tired_anger_rate = new_val
	if val_lbl:
		val_lbl.text = _format_rate_text(-new_val if is_drain else new_val)
	_apply_max_effect_rates_to_all()

func _apply_max_effect_rates_to_npc(npc: NPC) -> void:
	npc.max_hunger_health_drain_rate = max_hunger_health_drain_rate * master_growth_multiplier
	npc.max_boredom_anger_rate = max_boredom_anger_rate * master_growth_multiplier
	npc.max_purpose_anger_rate = max_purpose_anger_rate * master_growth_multiplier
	npc.max_tired_anger_rate = max_tired_anger_rate * master_growth_multiplier

func _apply_max_effect_rates_to_all() -> void:
	if not npc_container:
		return
	for child in npc_container.get_children():
		if child is NPC:
			_apply_max_effect_rates_to_npc(child as NPC)

# ==============================================================================
# GENDER MULTIPLIERS & ROMANCE INITIATOR CONTROLS
# ==============================================================================
func _setup_gender_multipliers_ui() -> void:
	if not gender_need_sliders_vbox:
		return

	for c in gender_need_sliders_vbox.get_children():
		c.queue_free()

	for need in NPC.NEED_DEFINITIONS:
		var prop: String = need["prop"]

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var swatch_center = CenterContainer.new()
		swatch_center.custom_minimum_size = Vector2(16, 16)
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(10, 10)
		swatch.color = need["color"]
		swatch_center.add_child(swatch)
		row.add_child(swatch_center)

		var name_lbl = Label.new()
		name_lbl.text = need["name"]
		name_lbl.custom_minimum_size = Vector2(65, 0)
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", (need["color"] as Color).lightened(0.25))
		row.add_child(name_lbl)

		var slider = HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 3.0
		slider.step = 0.1
		slider.value = 1.0
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slider)

		var val_lbl = Label.new()
		val_lbl.custom_minimum_size = Vector2(44, 0)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_size_override("font_size", 11)
		val_lbl.text = "1.0x"
		row.add_child(val_lbl)

		gender_slider_controls[prop] = {
			"slider": slider,
			"label": val_lbl
		}

		slider.value_changed.connect(func(new_val: float):
			_on_gender_need_mult_changed(prop, new_val, val_lbl)
		)

		gender_need_sliders_vbox.add_child(row)

func set_romance_initiator_mode(mode: NPC.RomanceInitiator) -> void:
	romance_initiator_mode = mode
	if rom_both_btn:
		rom_both_btn.text = "● Both" if mode == NPC.RomanceInitiator.BOTH else "Both"
		rom_both_btn.modulate = Color(1.0, 0.72, 0.88) if mode == NPC.RomanceInitiator.BOTH else Color(0.75, 0.78, 0.82)
	if rom_male_btn:
		rom_male_btn.text = "● ♂ Male" if mode == NPC.RomanceInitiator.MALE_ONLY else "♂ Male"
		rom_male_btn.modulate = Color(0.6, 0.82, 1.0) if mode == NPC.RomanceInitiator.MALE_ONLY else Color(0.75, 0.78, 0.82)
	if rom_female_btn:
		rom_female_btn.text = "● ♀ Female" if mode == NPC.RomanceInitiator.FEMALE_ONLY else "♀ Female"
		rom_female_btn.modulate = Color(1.0, 0.65, 0.84) if mode == NPC.RomanceInitiator.FEMALE_ONLY else Color(0.75, 0.78, 0.82)

	if npc_container:
		for child in npc_container.get_children():
			if child is NPC:
				(child as NPC).romance_initiator_mode = mode

func set_editing_gender(g: NPC.Gender) -> void:
	editing_gender = g
	var is_male: bool = (g == NPC.Gender.MALE)
	if edit_male_mult_btn:
		edit_male_mult_btn.text = "● ♂ Male Mults" if is_male else "♂ Male Mults"
		edit_male_mult_btn.modulate = Color(0.6, 0.82, 1.0) if is_male else Color(0.75, 0.78, 0.82)
	if edit_female_mult_btn:
		edit_female_mult_btn.text = "● ♀ Female Mults" if not is_male else "♀ Female Mults"
		edit_female_mult_btn.modulate = Color(1.0, 0.65, 0.84) if not is_male else Color(0.75, 0.78, 0.82)

	var scale_val: float = male_scale_multiplier if is_male else female_scale_multiplier
	if gender_scale_title:
		gender_scale_title.text = "♂ Overall:" if is_male else "♀ Overall:"
		gender_scale_title.modulate = Color(0.68, 0.86, 1.0) if is_male else Color(1.0, 0.72, 0.86)
	if gender_scale_slider:
		gender_scale_slider.set_value_no_signal(scale_val)
	if gender_scale_label:
		gender_scale_label.text = "%.1fx" % scale_val

	var table: Dictionary = male_need_multipliers if is_male else female_need_multipliers
	for prop in gender_slider_controls:
		var ctrl = gender_slider_controls[prop]
		var val: float = float(table.get(prop, 1.0))
		if ctrl.has("slider"):
			(ctrl["slider"] as HSlider).set_value_no_signal(val)
		if ctrl.has("label"):
			(ctrl["label"] as Label).text = "%.1fx" % val

func _on_gender_scale_changed(val: float) -> void:
	if editing_gender == NPC.Gender.MALE:
		male_scale_multiplier = val
	else:
		female_scale_multiplier = val
	if gender_scale_label:
		gender_scale_label.text = "%.1fx" % val
	_apply_gender_settings_to_all()

func _on_gender_need_mult_changed(prop: String, val: float, val_lbl: Label) -> void:
	var table: Dictionary = male_need_multipliers if editing_gender == NPC.Gender.MALE else female_need_multipliers
	table[prop] = val
	if val_lbl:
		val_lbl.text = "%.1fx" % val
	_apply_gender_settings_to_all()

func reset_editing_gender_multipliers() -> void:
	if editing_gender == NPC.Gender.MALE:
		male_scale_multiplier = 1.0
		for prop in male_need_multipliers:
			male_need_multipliers[prop] = 1.0
	else:
		female_scale_multiplier = 1.0
		for prop in female_need_multipliers:
			female_need_multipliers[prop] = 1.0
	set_editing_gender(editing_gender)
	_apply_gender_settings_to_all()

func _apply_gender_settings_to_npc(npc: NPC) -> void:
	npc.romance_initiator_mode = romance_initiator_mode
	if npc.gender == NPC.Gender.MALE:
		npc.set_gender_multipliers(male_scale_multiplier, male_need_multipliers)
	else:
		npc.set_gender_multipliers(female_scale_multiplier, female_need_multipliers)

func _apply_gender_settings_to_all() -> void:
	if not npc_container:
		return
	for child in npc_container.get_children():
		if child is NPC:
			_apply_gender_settings_to_npc(child as NPC)

# ==============================================================================
# SLEEPING GROWTH SLIDERS & PRESETS
# ==============================================================================
func _setup_sleeping_growth_sliders_ui() -> void:
	if not sleep_need_sliders_vbox:
		return

	for c in sleep_need_sliders_vbox.get_children():
		c.queue_free()

	for need in NPC.NEED_DEFINITIONS:
		var prop: String = need["prop"]
		var default_rate: float = sleeping_growth_rates.get(prop, 0.0)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var swatch_center = CenterContainer.new()
		swatch_center.custom_minimum_size = Vector2(16, 16)
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(10, 10)
		swatch.color = need["color"]
		swatch_center.add_child(swatch)
		row.add_child(swatch_center)

		var name_lbl = Label.new()
		name_lbl.text = need["name"]
		name_lbl.custom_minimum_size = Vector2(65, 0)
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", (need["color"] as Color).lightened(0.25))
		row.add_child(name_lbl)

		var slider = HSlider.new()
		slider.min_value = -30.0
		slider.max_value = 15.0
		slider.step = 0.1
		slider.value = default_rate
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slider)

		var val_lbl = Label.new()
		val_lbl.custom_minimum_size = Vector2(58, 0)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_size_override("font_size", 12)
		val_lbl.text = _format_rate_text(default_rate)
		row.add_child(val_lbl)

		sleep_slider_controls[prop] = {
			"slider": slider,
			"label": val_lbl
		}

		slider.value_changed.connect(func(new_val: float):
			_on_sleeping_need_slider_changed(prop, new_val, val_lbl)
		)

		sleep_need_sliders_vbox.add_child(row)

func _on_sleeping_need_slider_changed(prop: String, new_rate: float, val_lbl: Label) -> void:
	sleeping_growth_rates[prop] = new_rate
	if val_lbl:
		val_lbl.text = _format_rate_text(new_rate)

	var effective_rate = new_rate * master_growth_multiplier
	for child in npc_container.get_children():
		if child is NPC:
			child.set_sleeping_need_rate(prop, effective_rate)

func set_all_sleeping_growth_rates(rate: float) -> void:
	for prop in sleep_slider_controls:
		var ctrl = sleep_slider_controls[prop]
		if ctrl.has("slider"):
			ctrl["slider"].value = rate

func set_sleeping_growth_preset(preset: Dictionary) -> void:
	for prop in sleep_slider_controls:
		var ctrl = sleep_slider_controls[prop]
		if ctrl.has("slider"):
			ctrl["slider"].value = preset.get(prop, 0.0)

# ==============================================================================
# RECREATION GROWTH SLIDERS & PRESETS
# ==============================================================================
func _setup_recreation_growth_sliders_ui() -> void:
	if not rec_need_sliders_vbox:
		return

	for c in rec_need_sliders_vbox.get_children():
		c.queue_free()

	for need in NPC.NEED_DEFINITIONS:
		var prop: String = need["prop"]
		var default_rate: float = recreation_growth_rates.get(prop, 0.0)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var swatch_center = CenterContainer.new()
		swatch_center.custom_minimum_size = Vector2(16, 16)
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(10, 10)
		swatch.color = need["color"]
		swatch_center.add_child(swatch)
		row.add_child(swatch_center)

		var name_lbl = Label.new()
		name_lbl.text = need["name"]
		name_lbl.custom_minimum_size = Vector2(65, 0)
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", (need["color"] as Color).lightened(0.25))
		row.add_child(name_lbl)

		var slider = HSlider.new()
		slider.min_value = -30.0
		slider.max_value = 15.0
		slider.step = 0.1
		slider.value = default_rate
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slider)

		var val_lbl = Label.new()
		val_lbl.custom_minimum_size = Vector2(58, 0)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_size_override("font_size", 12)
		val_lbl.text = _format_rate_text(default_rate)
		row.add_child(val_lbl)

		rec_slider_controls[prop] = {
			"slider": slider,
			"label": val_lbl
		}

		slider.value_changed.connect(func(new_val: float):
			_on_recreation_need_slider_changed(prop, new_val, val_lbl)
		)

		rec_need_sliders_vbox.add_child(row)

func _on_recreation_need_slider_changed(prop: String, new_rate: float, val_lbl: Label) -> void:
	recreation_growth_rates[prop] = new_rate
	if val_lbl:
		val_lbl.text = _format_rate_text(new_rate)

	var effective_rate = new_rate * master_growth_multiplier
	for child in npc_container.get_children():
		if child is NPC:
			child.set_recreation_need_rate(prop, effective_rate)

func set_all_recreation_growth_rates(rate: float) -> void:
	for prop in rec_slider_controls:
		var ctrl = rec_slider_controls[prop]
		if ctrl.has("slider"):
			ctrl["slider"].value = rate

func set_recreation_growth_preset(preset: Dictionary) -> void:
	for prop in rec_slider_controls:
		var ctrl = rec_slider_controls[prop]
		if ctrl.has("slider"):
			ctrl["slider"].value = preset.get(prop, 0.0)

# ==============================================================================
# FOOD, SLEEP SPOT & RECREATION SPOT MANAGEMENT
# ==============================================================================
func set_active_click_tool(tool: ClickTool) -> void:
	active_click_tool = tool
	if tool_food_btn:
		tool_food_btn.text = "● Food (1)" if tool == ClickTool.FOOD else "Food (1)"
		tool_food_btn.modulate = Color(1.0, 0.85, 0.55) if tool == ClickTool.FOOD else Color(0.75, 0.78, 0.82)
	if tool_sleep_spot_btn:
		tool_sleep_spot_btn.text = "● 🌙 (2)" if tool == ClickTool.SLEEP_SPOT else "🌙 (2)"
		tool_sleep_spot_btn.modulate = Color(0.6, 0.82, 1.0) if tool == ClickTool.SLEEP_SPOT else Color(0.75, 0.78, 0.82)
	if tool_rec_spot_btn:
		tool_rec_spot_btn.text = "● ★ (3)" if tool == ClickTool.RECREATION_SPOT else "★ (3)"
		tool_rec_spot_btn.modulate = Color(1.0, 0.88, 0.42) if tool == ClickTool.RECREATION_SPOT else Color(0.75, 0.78, 0.82)

func spawn_sleep_spot(pos: Vector2) -> SleepSpot:
	var spot: SleepSpot = SLEEP_SPOT_SCENE.instantiate()
	var margin := Vector2(62.0, 38.0)
	spot.global_position = pos.clamp(margin, arena_size - margin)
	sleep_spot_container.add_child(spot)
	return spot

func clear_all_sleep_spots() -> void:
	if not sleep_spot_container:
		return
	for child in sleep_spot_container.get_children():
		child.queue_free()

func spawn_recreation_spot(pos: Vector2) -> RecreationSpot:
	var spot: RecreationSpot = RECREATION_SPOT_SCENE.instantiate()
	var margin := Vector2(82.0, 82.0)
	spot.global_position = pos.clamp(margin, arena_size - margin)
	recreation_spot_container.add_child(spot)
	return spot

func clear_all_recreation_spots() -> void:
	if not recreation_spot_container:
		return
	for child in recreation_spot_container.get_children():
		child.queue_free()
>>>>>>> Stashed changes
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
		npcs_collide_btn.text = "Collisions: ON" if enable else "Collisions: OFF"

# ==============================================================================
# UNIFIED MENU TABS & VISIBILITY
# ==============================================================================
func set_left_tab(tab: LeftTab) -> void:
	active_left_tab = tab
	if left_sim_content:
		left_sim_content.visible = (tab == LeftTab.SIM)
	if left_place_content:
		left_place_content.visible = (tab == LeftTab.PLACE)
	if left_tab_sim_btn:
		left_tab_sim_btn.text = "● 🌍 Sim" if tab == LeftTab.SIM else "🌍 Sim"
		left_tab_sim_btn.modulate = Color(0.75, 0.92, 1.0) if tab == LeftTab.SIM else Color(0.75, 0.78, 0.84)
	if left_tab_place_btn:
		left_tab_place_btn.text = "● 🛠 Place" if tab == LeftTab.PLACE else "🛠 Place"
		left_tab_place_btn.modulate = Color(1.0, 0.88, 0.55) if tab == LeftTab.PLACE else Color(0.75, 0.78, 0.84)

func set_left_panel_expanded(expanded: bool) -> void:
	if left_panel_content:
		left_panel_content.visible = expanded
	if retract_left_panel_btn:
		retract_left_panel_btn.text = "▾ ☰ World" if expanded else "▸ ☰ World"

<<<<<<< Updated upstream
=======
func set_left_panel_visible(vis: bool) -> void:
	if left_panel:
		left_panel.visible = vis
	if toggle_menu_btn:
		toggle_menu_btn.text = "☰ World ✓" if vis else "☰ World"
	_update_toggle_all_button_text()

func set_right_tab(tab: RightTab) -> void:
	active_right_tab = tab
	if main_sliders_content:
		main_sliders_content.visible = (tab == RightTab.GROWTH)
	if sleep_sliders_content:
		sleep_sliders_content.visible = (tab == RightTab.SLEEP)
	if rec_sliders_content:
		rec_sliders_content.visible = (tab == RightTab.RECREATION)
	if gender_content:
		gender_content.visible = (tab == RightTab.GENDER)

	var phase_icon: String = "☀" if current_time_of_day == TimeOfDay.DAY else "☾"
	if right_tab_growth_btn:
		var act := (tab == RightTab.GROWTH)
		right_tab_growth_btn.text = ("● %s" if act else "%s") % phase_icon
		right_tab_growth_btn.modulate = Color(1.0, 0.9, 0.55) if act else Color(0.75, 0.78, 0.84)
	if right_tab_sleep_btn:
		var act := (tab == RightTab.SLEEP)
		right_tab_sleep_btn.text = "● 🌙" if act else "🌙"
		right_tab_sleep_btn.modulate = Color(0.62, 0.82, 1.0) if act else Color(0.75, 0.78, 0.84)
	if right_tab_rec_btn:
		var act := (tab == RightTab.RECREATION)
		right_tab_rec_btn.text = "● ★" if act else "★"
		right_tab_rec_btn.modulate = Color(1.0, 0.88, 0.42) if act else Color(0.75, 0.78, 0.84)
	if right_tab_gender_btn:
		var act := (tab == RightTab.GENDER)
		right_tab_gender_btn.text = "● ♂♀" if act else "♂♀"
		right_tab_gender_btn.modulate = Color(0.9, 0.74, 1.0) if act else Color(0.75, 0.78, 0.84)

	if right_panel:
		right_panel.reset_size()

func set_right_panel_expanded(expanded: bool) -> void:
	if right_panel_content:
		right_panel_content.visible = expanded
	_update_day_night_ui()
	if right_panel:
		right_panel.reset_size()

func set_right_panel_visible(vis: bool) -> void:
	if right_panel:
		right_panel.visible = vis
	_update_right_top_button_text()
	_update_toggle_all_button_text()

func _update_right_top_button_text() -> void:
	if toggle_sliders_btn:
		var is_open: bool = (right_panel and right_panel.visible)
		var icon: String = "☀" if current_time_of_day == TimeOfDay.DAY else "☾"
		toggle_sliders_btn.text = "%s Sliders ✓" % icon if is_open else "%s Sliders" % icon

func _update_inspector_top_button() -> void:
	if not toggle_inspector_btn:
		return
	if is_instance_valid(selected_npc) and not selected_npc.is_dead:
		var shown: bool = npc_inspector and npc_inspector.visible
		toggle_inspector_btn.text = "🎯 #%d%s" % [selected_npc.npc_number, " ✓" if shown else ""]
		toggle_inspector_btn.modulate = Color(0.55, 0.92, 1.0)
	else:
		toggle_inspector_btn.text = "🎯 NPC"
		toggle_inspector_btn.modulate = Color(0.68, 0.72, 0.78)

func _toggle_inspector_from_top() -> void:
	if is_instance_valid(selected_npc) and not selected_npc.is_dead:
		if npc_inspector:
			npc_inspector.visible = not npc_inspector.visible
		_update_inspector_top_button()
	elif npc_container:
		# If nothing selected yet, select the first living NPC for convenience!
		for child in npc_container.get_children():
			if child is NPC and not (child as NPC).is_dead:
				select_npc(child as NPC)
				break

func toggle_all_ui() -> void:
	var any_visible: bool = (
		(left_panel and left_panel.visible)
		or (right_panel and right_panel.visible)
		or (npc_inspector and npc_inspector.visible)
	)
	var new_state: bool = not any_visible
	set_left_panel_visible(new_state)
	set_right_panel_visible(new_state)
	if npc_inspector:
		npc_inspector.visible = new_state and is_instance_valid(selected_npc) and not selected_npc.is_dead
	_update_inspector_top_button()

func _update_toggle_all_button_text() -> void:
	if toggle_all_ui_btn:
		var any_visible: bool = (
			(left_panel and left_panel.visible)
			or (right_panel and right_panel.visible)
			or (npc_inspector and npc_inspector.visible)
		)
		toggle_all_ui_btn.text = "👁 (H)" if any_visible else "👁 +"

>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
=======
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H or event.keycode == KEY_TAB:
			toggle_all_ui()
		elif event.keycode == KEY_ESCAPE:
			select_npc(null)
		elif event.keycode == KEY_1:
			set_active_click_tool(ClickTool.FOOD)
		elif event.keycode == KEY_2:
			set_active_click_tool(ClickTool.SLEEP_SPOT)
		elif event.keycode == KEY_3:
			set_active_click_tool(ClickTool.RECREATION_SPOT)

func _find_npc_at_position(world_pos: Vector2) -> NPC:
	if not npc_container:
		return null
	var best_npc: NPC = null
	var best_dist_sq: float = INF
	for child in npc_container.get_children():
		if child is NPC:
			var npc: NPC = child as NPC
			if npc.is_dead:
				continue
			var hit_r: float = npc.body_radius + 4.0
			var d_sq: float = npc.global_position.distance_squared_to(world_pos)
			if d_sq <= hit_r * hit_r and d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_npc = npc
	return best_npc

func select_npc(npc: NPC) -> void:
	if is_instance_valid(selected_npc):
		selected_npc.is_selected = false
	if is_instance_valid(npc) and not npc.is_dead:
		selected_npc = npc
		selected_npc.is_selected = true
		if camera:
			camera.position = selected_npc.global_position
		if npc_inspector:
			npc_inspector.set_target_npc(selected_npc)
	else:
		selected_npc = null
		if npc_inspector:
			npc_inspector.set_target_npc(null)
	_update_inspector_top_button()
	_update_toggle_all_button_text()

func _process_camera_follow(delta: float) -> void:
	if selected_npc == null:
		return
	if not is_instance_valid(selected_npc) or selected_npc.is_dead:
		select_npc(null)
		return
	if camera and not is_panning:
		camera.position = camera.position.lerp(selected_npc.global_position, minf(1.0, 12.0 * delta))

>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
	# Right growth panel controls
=======
	# Unified Left & Right panel tabs + retract controls
	if retract_left_panel_btn:
		retract_left_panel_btn.pressed.connect(func():
			var is_exp: bool = left_panel_content and left_panel_content.visible
			set_left_panel_expanded(not is_exp)
		)
	if left_tab_sim_btn:
		left_tab_sim_btn.pressed.connect(func(): set_left_tab(LeftTab.SIM))
	if left_tab_place_btn:
		left_tab_place_btn.pressed.connect(func(): set_left_tab(LeftTab.PLACE))

	if npc_inspector:
		npc_inspector.close_requested.connect(func(): select_npc(null))
		npc_inspector.npc_gender_toggled.connect(func(n: NPC): _apply_gender_settings_to_npc(n))

	if retract_right_panel_btn:
		retract_right_panel_btn.pressed.connect(func():
			var is_exp: bool = right_panel_content and right_panel_content.visible
			set_right_panel_expanded(not is_exp)
		)
	if right_tab_growth_btn:
		right_tab_growth_btn.pressed.connect(func(): set_right_tab(RightTab.GROWTH))
	if right_tab_sleep_btn:
		right_tab_sleep_btn.pressed.connect(func(): set_right_tab(RightTab.SLEEP))
	if right_tab_rec_btn:
		right_tab_rec_btn.pressed.connect(func(): set_right_tab(RightTab.RECREATION))
	if right_tab_gender_btn:
		right_tab_gender_btn.pressed.connect(func(): set_right_tab(RightTab.GENDER))

	# Day / Night dual slider controls
	if flip_day_night_btn:
		flip_day_night_btn.pressed.connect(func():
			var next_phase: TimeOfDay = TimeOfDay.NIGHT if current_time_of_day == TimeOfDay.DAY else TimeOfDay.DAY
			set_time_of_day(next_phase)
		)
	if pause_cycle_btn:
		pause_cycle_btn.pressed.connect(func():
			day_night_cycle_paused = not day_night_cycle_paused
			pause_cycle_btn.text = "▶" if day_night_cycle_paused else "⏸"
			_update_day_night_ui()
		)
	if edit_day_sliders_btn:
		edit_day_sliders_btn.pressed.connect(func(): set_editing_time_of_day(TimeOfDay.DAY))
	if edit_night_sliders_btn:
		edit_night_sliders_btn.pressed.connect(func(): set_editing_time_of_day(TimeOfDay.NIGHT))

>>>>>>> Stashed changes
	if master_scale_slider:
		master_scale_slider.value_changed.connect(_on_master_scale_changed)

	if freeze_growth_btn:
		freeze_growth_btn.pressed.connect(func(): set_all_growth_rates(0.0))

	if default_growth_btn:
		default_growth_btn.pressed.connect(func(): set_all_growth_rates(1.0))

	if fast_growth_btn:
		fast_growth_btn.pressed.connect(func(): set_all_growth_rates(3.0))

<<<<<<< Updated upstream
=======
	# Sleeping tab presets
	if sleep_freeze_btn:
		sleep_freeze_btn.pressed.connect(func(): set_all_sleeping_growth_rates(0.0))
	if sleep_default_btn:
		sleep_default_btn.pressed.connect(func(): set_sleeping_growth_preset(NPC.DEFAULT_SLEEPING_RATES))
	if sleep_fast_rest_btn:
		sleep_fast_rest_btn.pressed.connect(func():
			set_sleeping_growth_preset({
				"hunger": 0.1,
				"sleep_need": -30.0,
				"talk_need": 0.0,
				"tired": -30.0,
				"boredom": 0.0,
				"lust": 0.0,
				"purpose": 0.0,
				"anger": -5.0
			})
		)

	# Recreation tab presets
	if rec_freeze_btn:
		rec_freeze_btn.pressed.connect(func(): set_all_recreation_growth_rates(0.0))
	if rec_default_btn:
		rec_default_btn.pressed.connect(func(): set_recreation_growth_preset(NPC.DEFAULT_RECREATION_RATES))
	if rec_high_fun_btn:
		rec_high_fun_btn.pressed.connect(func():
			set_recreation_growth_preset({
				"hunger": 0.5,
				"sleep_need": 0.4,
				"talk_need": -10.0,
				"tired": 1.0,
				"boredom": -30.0,
				"lust": 0.5,
				"purpose": -5.0,
				"anger": -8.0
			})
		)

	# Gender multipliers & romance tab controls
	if rom_both_btn:
		rom_both_btn.pressed.connect(func(): set_romance_initiator_mode(NPC.RomanceInitiator.BOTH))
	if rom_male_btn:
		rom_male_btn.pressed.connect(func(): set_romance_initiator_mode(NPC.RomanceInitiator.MALE_ONLY))
	if rom_female_btn:
		rom_female_btn.pressed.connect(func(): set_romance_initiator_mode(NPC.RomanceInitiator.FEMALE_ONLY))

	if edit_male_mult_btn:
		edit_male_mult_btn.pressed.connect(func(): set_editing_gender(NPC.Gender.MALE))
	if edit_female_mult_btn:
		edit_female_mult_btn.pressed.connect(func(): set_editing_gender(NPC.Gender.FEMALE))

	if gender_scale_slider:
		gender_scale_slider.value_changed.connect(_on_gender_scale_changed)
	if gender_reset_btn:
		gender_reset_btn.pressed.connect(reset_editing_gender_multipliers)

	# Top Bar & Close Button Visibility toggles
	if toggle_menu_btn:
		toggle_menu_btn.pressed.connect(func(): set_left_panel_visible(not (left_panel and left_panel.visible)))
	if close_left_btn:
		close_left_btn.pressed.connect(func(): set_left_panel_visible(false))

	if toggle_sliders_btn:
		toggle_sliders_btn.pressed.connect(func(): set_right_panel_visible(not (right_panel and right_panel.visible)))
	if close_right_btn:
		close_right_btn.pressed.connect(func(): set_right_panel_visible(false))

	if toggle_inspector_btn:
		toggle_inspector_btn.pressed.connect(_toggle_inspector_from_top)

	if toggle_all_ui_btn:
		toggle_all_ui_btn.pressed.connect(toggle_all_ui)

>>>>>>> Stashed changes
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
