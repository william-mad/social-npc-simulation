class_name NPCInspector
extends PanelContainer

signal close_requested()
signal npc_gender_toggled(npc: NPC)

enum InspectorTab {
	STATS,
	MULTIPLIERS
}

var target_npc: NPC = null
var active_tab: InspectorTab = InspectorTab.STATS
var _is_dragging_hp: bool = false

# UI nodes built cleanly in scene / script
@onready var title_label: Label = %InspectorTitleLabel
@onready var gender_flip_btn: Button = %InspectorGenderBtn
@onready var heal_full_btn: Button = %InspectorHealBtn
@onready var close_btn: Button = %InspectorCloseBtn
@onready var status_label: Label = %InspectorStatusLabel
@onready var tab_stats_btn: Button = %InspectorTabStatsBtn
@onready var tab_mults_btn: Button = %InspectorTabMultsBtn
@onready var stats_vbox: VBoxContainer = %InspectorStatsVBox
@onready var mults_vbox: VBoxContainer = %InspectorMultsVBox

# Combat & Stat slider controls
var hp_slider: HSlider
var hp_val_label: Label
var max_hp_slider: HSlider
var max_hp_val_label: Label
var hit_dmg_slider: HSlider
var hit_dmg_val_label: Label
var retaliate_slider: HSlider
var retaliate_val_label: Label
var sleep_heal_slider: HSlider
var sleep_heal_val_label: Label
var passive_heal_slider: HSlider
var passive_heal_val_label: Label
var speed_mult_slider: HSlider
var speed_mult_val_label: Label

# Aggression response buttons
var resp_buttons: Dictionary = {}

# Multiplier slider controls
var growth_mult_slider: HSlider
var growth_mult_val_label: Label
var need_mult_controls: Dictionary = {}

func _ready() -> void:
	visible = false
	_build_stats_tab()
	_build_multipliers_tab()
	_connect_header_signals()
	set_active_tab(InspectorTab.STATS)

func _process(_delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(target_npc) or target_npc.is_dead:
		set_target_npc(null)
		return
	_refresh_live_values()

func set_target_npc(npc: NPC) -> void:
	_is_dragging_hp = false
	if is_instance_valid(npc) and not npc.is_dead:
		target_npc = npc
		visible = true
		_sync_all_controls_from_npc()
	else:
		target_npc = null
		visible = false

func set_active_tab(tab: InspectorTab) -> void:
	active_tab = tab
	if stats_vbox:
		stats_vbox.visible = (tab == InspectorTab.STATS)
	if mults_vbox:
		mults_vbox.visible = (tab == InspectorTab.MULTIPLIERS)
	if tab_stats_btn:
		tab_stats_btn.text = "● ⚔ Stats" if tab == InspectorTab.STATS else "⚔ Stats"
		tab_stats_btn.modulate = Color(0.6, 0.92, 1.0) if tab == InspectorTab.STATS else Color(0.76, 0.78, 0.84)
	if tab_mults_btn:
		tab_mults_btn.text = "● ⚙ Mults" if tab == InspectorTab.MULTIPLIERS else "⚙ Mults"
		tab_mults_btn.modulate = Color(0.6, 0.92, 1.0) if tab == InspectorTab.MULTIPLIERS else Color(0.76, 0.78, 0.84)

func _connect_header_signals() -> void:
	if close_btn:
		close_btn.pressed.connect(func(): close_requested.emit())
	if gender_flip_btn:
		gender_flip_btn.pressed.connect(_on_gender_flip_pressed)
	if heal_full_btn:
		heal_full_btn.pressed.connect(func():
			if is_instance_valid(target_npc) and not target_npc.is_dead:
				target_npc.health = target_npc.max_health
				_refresh_live_values()
		)
	if tab_stats_btn:
		tab_stats_btn.pressed.connect(func(): set_active_tab(InspectorTab.STATS))
	if tab_mults_btn:
		tab_mults_btn.pressed.connect(func(): set_active_tab(InspectorTab.MULTIPLIERS))

func _on_gender_flip_pressed() -> void:
	if not is_instance_valid(target_npc) or target_npc.is_dead:
		return
	target_npc.gender = NPC.Gender.FEMALE if target_npc.gender == NPC.Gender.MALE else NPC.Gender.MALE
	npc_gender_toggled.emit(target_npc)
	_sync_header()

func _make_slider_row(parent: VBoxContainer, label_text: String, label_color: Color, min_v: float, max_v: float, step_v: float, val_width: float = 52.0) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(84, 0)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", label_color)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size = Vector2(val_width, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 11)
	row.add_child(val_lbl)

	parent.add_child(row)
	return {"row": row, "slider": slider, "label": val_lbl}

func _build_stats_tab() -> void:
	if not stats_vbox:
		return
	for c in stats_vbox.get_children():
		c.queue_free()

	# 1. Hit Points (HP)
	var hp_row := _make_slider_row(stats_vbox, "♥ Hit Points", Color(0.45, 0.95, 0.55), 0.0, 100.0, 1.0)
	hp_slider = hp_row["slider"]
	hp_val_label = hp_row["label"]
	hp_slider.drag_started.connect(func(): _is_dragging_hp = true)
	hp_slider.drag_ended.connect(func(_changed: bool): _is_dragging_hp = false)
	hp_slider.value_changed.connect(func(v: float):
		if is_instance_valid(target_npc) and not target_npc.is_dead:
			var npc_ref: NPC = target_npc
			npc_ref.health = v
			if is_instance_valid(target_npc) and target_npc == npc_ref:
				hp_val_label.text = "%d" % int(round(npc_ref.health))
	)

	# 2. Max Hit Points
	var max_hp_row := _make_slider_row(stats_vbox, "♥ Max HP", Color(0.35, 0.85, 0.45), 20.0, 300.0, 5.0)
	max_hp_slider = max_hp_row["slider"]
	max_hp_val_label = max_hp_row["label"]
	max_hp_slider.value_changed.connect(func(v: float):
		if is_instance_valid(target_npc) and not target_npc.is_dead:
			var npc_ref: NPC = target_npc
			var prev_max: float = npc_ref.max_health
			npc_ref.max_health = v
			if is_instance_valid(target_npc) and target_npc == npc_ref and not npc_ref.is_dead:
				if v > prev_max and npc_ref.health >= prev_max - 0.5:
					npc_ref.health = v
				hp_slider.max_value = v
				hp_slider.set_value_no_signal(npc_ref.health)
				max_hp_val_label.text = "%d" % int(round(v))
				hp_val_label.text = "%d" % int(round(npc_ref.health))
	)

	# 3. Hit Damage
	var dmg_row := _make_slider_row(stats_vbox, "⚔ Hit Dmg", Color(1.0, 0.45, 0.42), 0.0, 60.0, 1.0)
	hit_dmg_slider = dmg_row["slider"]
	hit_dmg_val_label = dmg_row["label"]
	hit_dmg_slider.value_changed.connect(func(v: float):
		if is_instance_valid(target_npc) and not target_npc.is_dead:
			target_npc.hit_damage = v
			hit_dmg_val_label.text = "%d HP" % int(round(v))
	)

	# 4. Response to Aggression (mode selector)
	var resp_row := HBoxContainer.new()
	resp_row.add_theme_constant_override("separation", 4)
	var resp_lbl := Label.new()
	resp_lbl.text = "🛡 On Hit"
	resp_lbl.custom_minimum_size = Vector2(64, 0)
	resp_lbl.add_theme_font_size_override("font_size", 11)
	resp_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
	resp_row.add_child(resp_lbl)

	var modes: Array[Dictionary] = [
		{"mode": NPC.AggressionResponse.AUTO, "text": "Auto"},
		{"mode": NPC.AggressionResponse.ALWAYS_RETALIATE, "text": "Fight"},
		{"mode": NPC.AggressionResponse.ALWAYS_FLEE, "text": "Flee"},
		{"mode": NPC.AggressionResponse.STOIC, "text": "Stoic"}
	]
	for item in modes:
		var mode_val: NPC.AggressionResponse = item["mode"]
		var btn := Button.new()
		btn.text = item["text"]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(func():
			if is_instance_valid(target_npc) and not target_npc.is_dead:
				target_npc.aggression_response = mode_val
				_sync_response_buttons()
		)
		resp_row.add_child(btn)
		resp_buttons[mode_val] = btn
	stats_vbox.add_child(resp_row)

	# 5. Retaliation Threshold (used by Auto mode)
	var ret_row := _make_slider_row(stats_vbox, "💢 Fight Back", Color(0.95, 0.55, 0.35), 0.0, 100.0, 1.0)
	retaliate_slider = ret_row["slider"]
	retaliate_val_label = ret_row["label"]
	retaliate_slider.value_changed.connect(func(v: float):
		if is_instance_valid(target_npc) and not target_npc.is_dead:
			target_npc.retaliation_threshold = v
			retaliate_val_label.text = "≥ %d" % int(round(v))
	)

	# 6. Sleep Healing
	var sheal_row := _make_slider_row(stats_vbox, "🌙 Sleep Heal", Color(0.55, 0.78, 1.0), 0.0, 25.0, 0.5)
	sleep_heal_slider = sheal_row["slider"]
	sleep_heal_val_label = sheal_row["label"]
	sleep_heal_slider.value_changed.connect(func(v: float):
		if is_instance_valid(target_npc) and not target_npc.is_dead:
			target_npc.sleep_heal_rate = v
			sleep_heal_val_label.text = "+%.1f/s" % v
	)

	# 7. Passive Regen Healing
	var pheal_row := _make_slider_row(stats_vbox, "✚ Regen Heal", Color(0.45, 0.92, 0.72), 0.0, 15.0, 0.2)
	passive_heal_slider = pheal_row["slider"]
	passive_heal_val_label = pheal_row["label"]
	passive_heal_slider.value_changed.connect(func(v: float):
		if is_instance_valid(target_npc) and not target_npc.is_dead:
			target_npc.passive_heal_rate = v
			passive_heal_val_label.text = "+%.1f/s" % v
	)

	# 8. Individual Speed Multiplier
	var spd_row := _make_slider_row(stats_vbox, "⚡ Speed", Color(0.95, 0.88, 0.45), 0.2, 3.0, 0.1)
	speed_mult_slider = spd_row["slider"]
	speed_mult_val_label = spd_row["label"]
	speed_mult_slider.value_changed.connect(func(v: float):
		if is_instance_valid(target_npc) and not target_npc.is_dead:
			target_npc.speed_multiplier = v
			speed_mult_val_label.text = "%.1fx" % v
	)

func _build_multipliers_tab() -> void:
	if not mults_vbox:
		return
	for c in mults_vbox.get_children():
		c.queue_free()

	# Overall individual growth multiplier + Reset button
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)

	var g_lbl := Label.new()
	g_lbl.text = "⚙ Growth"
	g_lbl.custom_minimum_size = Vector2(68, 0)
	g_lbl.add_theme_font_size_override("font_size", 11)
	g_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	top_row.add_child(g_lbl)

	growth_mult_slider = HSlider.new()
	growth_mult_slider.min_value = 0.0
	growth_mult_slider.max_value = 4.0
	growth_mult_slider.step = 0.1
	growth_mult_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	growth_mult_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	growth_mult_slider.value_changed.connect(func(v: float):
		if is_instance_valid(target_npc) and not target_npc.is_dead:
			target_npc.individual_growth_multiplier = v
			growth_mult_val_label.text = "%.1fx" % v
	)
	top_row.add_child(growth_mult_slider)

	growth_mult_val_label = Label.new()
	growth_mult_val_label.custom_minimum_size = Vector2(36, 0)
	growth_mult_val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	growth_mult_val_label.add_theme_font_size_override("font_size", 11)
	top_row.add_child(growth_mult_val_label)

	var reset_btn := Button.new()
	reset_btn.text = "1x"
	reset_btn.add_theme_font_size_override("font_size", 10)
	reset_btn.pressed.connect(_reset_individual_multipliers)
	top_row.add_child(reset_btn)
	mults_vbox.add_child(top_row)

	var sep := HSeparator.new()
	mults_vbox.add_child(sep)

	# 8 Individual Per-Need Multipliers (edits npc.personality_weights[prop])
	for need in NPC.NEED_DEFINITIONS:
		var prop: String = need["prop"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var swatch_center := CenterContainer.new()
		swatch_center.custom_minimum_size = Vector2(14, 14)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(9, 9)
		swatch.color = need["color"]
		swatch_center.add_child(swatch)
		row.add_child(swatch_center)

		var name_lbl := Label.new()
		name_lbl.text = need["name"]
		name_lbl.custom_minimum_size = Vector2(60, 0)
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", (need["color"] as Color).lightened(0.25))
		row.add_child(name_lbl)

		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 3.0
		slider.step = 0.1
		slider.value = 1.0
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slider)

		var val_lbl := Label.new()
		val_lbl.custom_minimum_size = Vector2(64, 0)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_font_size_override("font_size", 11)
		row.add_child(val_lbl)

		need_mult_controls[prop] = {"slider": slider, "label": val_lbl}

		slider.value_changed.connect(func(v: float):
			if is_instance_valid(target_npc) and not target_npc.is_dead:
				target_npc.personality_weights[prop] = v
				target_npc.queue_redraw()
				_update_single_need_label(prop)
		)

		mults_vbox.add_child(row)

func _reset_individual_multipliers() -> void:
	if not is_instance_valid(target_npc) or target_npc.is_dead:
		return
	target_npc.individual_growth_multiplier = 1.0
	for need in NPC.NEED_DEFINITIONS:
		target_npc.personality_weights[need["prop"]] = 1.0
	target_npc.queue_redraw()
	_sync_all_controls_from_npc()

func _sync_header() -> void:
	if not is_instance_valid(target_npc):
		return
	var g_sym: String = "♂" if target_npc.gender == NPC.Gender.MALE else "♀"
	if title_label:
		title_label.text = "🎯 #%d • %s %s" % [target_npc.npc_number, g_sym, target_npc.personality_name]
		title_label.modulate = Color(0.62, 0.86, 1.0) if target_npc.gender == NPC.Gender.MALE else Color(1.0, 0.68, 0.86)
	if gender_flip_btn:
		gender_flip_btn.text = "♂/♀"

func _sync_response_buttons() -> void:
	if not is_instance_valid(target_npc):
		return
	for mode_val in resp_buttons:
		var btn: Button = resp_buttons[mode_val]
		var active: bool = (target_npc.aggression_response == mode_val)
		btn.modulate = Color(1.0, 0.85, 0.45) if active else Color(0.72, 0.75, 0.82)
	if retaliate_slider:
		retaliate_slider.editable = (target_npc.aggression_response == NPC.AggressionResponse.AUTO)
		retaliate_slider.modulate.a = 1.0 if retaliate_slider.editable else 0.45

func _sync_all_controls_from_npc() -> void:
	if not is_instance_valid(target_npc):
		return
	_sync_header()
	_sync_response_buttons()

	if max_hp_slider:
		max_hp_slider.set_value_no_signal(target_npc.max_health)
		max_hp_val_label.text = "%d" % int(round(target_npc.max_health))
	if hp_slider:
		hp_slider.max_value = target_npc.max_health
		hp_slider.set_value_no_signal(target_npc.health)
		hp_val_label.text = "%d" % int(round(target_npc.health))
	if hit_dmg_slider:
		hit_dmg_slider.set_value_no_signal(target_npc.hit_damage)
		hit_dmg_val_label.text = "%d HP" % int(round(target_npc.hit_damage))
	if retaliate_slider:
		retaliate_slider.set_value_no_signal(target_npc.retaliation_threshold)
		retaliate_val_label.text = "≥ %d" % int(round(target_npc.retaliation_threshold))
	if sleep_heal_slider:
		sleep_heal_slider.set_value_no_signal(target_npc.sleep_heal_rate)
		sleep_heal_val_label.text = "+%.1f/s" % target_npc.sleep_heal_rate
	if passive_heal_slider:
		passive_heal_slider.set_value_no_signal(target_npc.passive_heal_rate)
		passive_heal_val_label.text = "+%.1f/s" % target_npc.passive_heal_rate
	if speed_mult_slider:
		speed_mult_slider.set_value_no_signal(target_npc.speed_multiplier)
		speed_mult_val_label.text = "%.1fx" % target_npc.speed_multiplier

	if growth_mult_slider:
		growth_mult_slider.set_value_no_signal(target_npc.individual_growth_multiplier)
		growth_mult_val_label.text = "%.1fx" % target_npc.individual_growth_multiplier

	for prop in need_mult_controls:
		var ctrl = need_mult_controls[prop]
		var w: float = float(target_npc.personality_weights.get(prop, 1.0))
		(ctrl["slider"] as HSlider).set_value_no_signal(w)
		_update_single_need_label(prop)

	_refresh_live_values()

func _update_single_need_label(prop: String) -> void:
	if not is_instance_valid(target_npc) or not need_mult_controls.has(prop):
		return
	var val: float = float(target_npc.get(prop))
	var w: float = float(target_npc.personality_weights.get(prop, 1.0))
	(need_mult_controls[prop]["label"] as Label).text = "%d • %.1fx" % [int(round(val)), w]

func _refresh_live_values() -> void:
	if not is_instance_valid(target_npc):
		return
	if status_label:
		status_label.text = "%s  |  HP: %d/%d" % [
			target_npc.state_label_text,
			int(round(target_npc.health)),
			int(round(target_npc.max_health))
		]
	if hp_slider and not _is_dragging_hp:
		hp_slider.max_value = target_npc.max_health
		hp_slider.set_value_no_signal(target_npc.health)
		hp_val_label.text = "%d" % int(round(target_npc.health))
	if active_tab == InspectorTab.MULTIPLIERS:
		for prop in need_mult_controls:
			_update_single_need_label(prop)
