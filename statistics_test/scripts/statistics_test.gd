extends Control
## Statistics Test - interactive prototype tool.
##
## Phase 1 (setup): enter 30 reference values. The experiment cannot start
## until all 30 are valid numbers.
## Phase 2 (running): the reference sample is frozen; every submitted roll
## slides the 30-value rolling window (drop oldest, append new) and recomputes
## a Welch two-sample t-test of current window vs. reference, redrawing both
## frequency histograms immediately.
##
## Extra reference tables can be added at any time ("[+] New table") and the
## active one chosen from a "Table 1 / Table 2 / ..." dropdown; adding or
## switching tables never touches the rolling window. A "Favor" counter
## (starts at 50) accumulates t values via its own [+] button. Auto-switch
## rules (any number, edited in a popup) make a chosen table the active
## reference automatically whenever Favor crosses that rule's threshold.
##
## Isolation notes: this tool is completely separate from the game. It uses no
## game scripts, no autoloads, no global class_name registrations, and touches
## no project settings. Removing the statistics_test/ folder removes the tool.
##
## Optional command line conveniences (all optional, see README):
##   godot --path . res://statistics_test/scenes/statistics_test.tscn -- --statistics-test-demo
##   godot --path . res://statistics_test/scenes/statistics_test.tscn -- --statistics-test-screenshot=C:/path/shot.png
##   godot --path . res://statistics_test/scenes/statistics_test.tscn -- --statistics-test-screenshot-setup=C:/path/shot.png

const SAMPLE_SIZE := 30
const DEFAULT_AXIS_MIN := -10
const DEFAULT_AXIS_MAX := 10

const StatisticsAnalyzer := preload("res://statistics_test/scripts/statistics_analyzer.gd")
const RollingSample := preload("res://statistics_test/scripts/rolling_sample.gd")
const HistogramView := preload("res://statistics_test/scripts/histogram_view.gd")

const COLOR_T_POSITIVE := Color(1.0, 0.55, 0.3)
const COLOR_T_NEGATIVE := Color(0.45, 0.75, 1.0)
const COLOR_T_NEUTRAL := Color(0.88, 0.89, 0.92)
const COLOR_CELL_INVALID := Color(0.85, 0.25, 0.2)

const DEMO_REFERENCE_VALUES: Array[int] = [
	3, -1, 4, 2, 0, 5, -3, 1, 4, 2,
	-2, 6, 0, 3, 1, -4, 2, 5, -1, 0,
	3, -2, 4, 1, 2, -3, 5, 0, 2, 1,
]
const DEMO_ROLLS: Array[int] = [8, 8, 9, -6, 10, -7, 9, 5]

# State.
var _reference_tables: Array = []          # every stored reference table (each an Array[float])
var _active_table_index := -1              # which stored table is the active reference
var _reference_values: Array[float] = []   # contents of the active reference table
var _rolling: RollingSample = null
var _running := false
var _roll_count := 0
var _last_result := {}
var _favor := 50.0                         # Favor counter, starts at 50
var _dump_reference_text := ""             # first line of the data dump label
var _table_names: Array[String] = []       # display name per session table
var _saved_tables: Array = []              # library loaded from saved_tables.json: {name, values}
var _library_path := "res://statistics_test/saved_tables.json"
var _grid_edit_kind := "none"              # what the apply button writes to: "none" | "session" | "library"
var _grid_edit_index := -1

# Setup-phase UI.
var _setup_panel: PanelContainer
var _value_cells: Array[LineEdit] = []
var _progress_label: Label
var _start_button: Button
var _table_name_edit: LineEdit
var _apply_edit_button: Button

# Run-phase UI.
var _run_panel: VBoxContainer
var _t_value_label: Label
var _t_interpretation_label: Label
var _ref_mean_label: Label
var _cur_mean_label: Label
var _diff_label: Label
var _p_label: Label
var _ref_sd_label: Label
var _cur_sd_label: Label
var _se_label: Label
var _df_label: Label
var _sample_size_label: Label
var _roll_count_label: Label
var _last_action_label: Label
var _dump_label: Label
var _roll_input: LineEdit
var _ref_histogram: HistogramView
var _cur_histogram: HistogramView
var _histogram_row: HBoxContainer
var _cancel_edit_button: Button
var _refs_row: HBoxContainer
var _stats_grid: GridContainer
var _info_row: HBoxContainer
var _table_option: OptionButton
var _new_table_button: Button
var _tables_button: Button
var _reset_window_button: Button
var _favor_value_label: Label
var _add_t_button: Button
var _gen_weighted_check: CheckBox
var _gen_center_spin: SpinBox
var _gen_spread_spin: SpinBox
var _gen_interval_spin: SpinBox
var _auto_button: Button
var _auto_timer: Timer
var _auto_running := false
var _switch_enabled_check: CheckBox
var _switch_summary_label: Label
var _switch_edit_button: Button
var _switch_editor: PopupPanel
var _rules_list: VBoxContainer
var _rule_status_labels: Array[Label] = []
var _switch_rules: Array = []              # each: {enabled, above, threshold, target, fired}
var _switch_rule_just_fired := false
var _tables_popup: PopupPanel
var _tables_list: VBoxContainer
var _library_list: VBoxContainer
var _tables_status_label: Label


func _ready() -> void:
	randomize()
	get_window().title = "Statistics Test"
	_build_ui()
	_refresh_setup_validation()
	_handle_command_line_demo()


# --- UI construction ---------------------------------------------------------


func _build_ui() -> void:
	# The tool's UI lives in a high CanvasLayer so that, when run inside this
	# project, it stays above the game's autoload HUDs (clock HUD uses layer
	# 100, scene transitions 115). Runtime-only; touches nothing of the game's.
	var ui_layer := CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 200
	add_child(ui_layer)

	# Opaque backdrop so game HUD elements below this layer cannot show
	# through the tool's layout. Light tone to match the project theme,
	# which renders labels with dark text.
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.74, 0.68, 0.55)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(backdrop)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	ui_layer.add_child(margin)

	var root := VBoxContainer.new()
	root.name = "Root"
	root.add_theme_constant_override("separation", 3)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(root)

	var title := Label.new()
	title.text = "STATISTICS TEST - fixed 30-value reference vs rolling 30-value window"
	title.add_theme_font_size_override("font_size", _base_font_size() + 2)
	root.add_child(title)

	_setup_panel = _build_setup_panel()
	root.add_child(_setup_panel)

	# Generation settings stay visible in both phases: Fill random (setup)
	# and Random / Auto (run) all use them.
	root.add_child(_build_generation_panel())

	_run_panel = _build_run_panel()
	_run_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_run_panel.visible = false
	root.add_child(_run_panel)

	_auto_timer = Timer.new()
	_auto_timer.one_shot = false
	_auto_timer.timeout.connect(_on_auto_timer_timeout)
	add_child(_auto_timer)

	_build_switch_editor()
	_rebuild_rules_editor()
	_build_tables_editor()
	_load_library_from_file()


func _build_setup_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "SetupPanel"

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var header_label := Label.new()
	header_label.text = "STEP 1 - enter the 30 reference values"
	header_label.tooltip_text = "Press Enter in a cell to jump to the next field"
	header.add_child(header_label)
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	_progress_label = Label.new()
	_progress_label.text = "0 / %d values" % SAMPLE_SIZE
	_progress_label.tooltip_text = "How many of the 30 cells hold valid numbers"
	header.add_child(_progress_label)

	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)
	for i in SAMPLE_SIZE:
		var cell := LineEdit.new()
		cell.custom_minimum_size = Vector2(58, 0)
		cell.placeholder_text = "0"
		cell.alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.max_length = 8
		cell.text_changed.connect(_on_reference_cell_changed.bind(i))
		cell.text_submitted.connect(_on_reference_cell_submitted.bind(i))
		grid.add_child(cell)
		_value_cells.append(cell)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	vbox.add_child(buttons)

	var random_button := Button.new()
	random_button.text = "Fill random"
	random_button.tooltip_text = "Fill all 30 cells with random integers in [-10, 10] (weighted per the generation settings)"
	random_button.pressed.connect(_on_fill_random_pressed)
	buttons.add_child(random_button)

	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.pressed.connect(_on_clear_reference_pressed)
	buttons.add_child(clear_button)

	var hint := Label.new()
	hint.text = "Enter = next"
	hint.tooltip_text = "Press Enter in a cell to jump to the next one"
	hint.add_theme_font_size_override("font_size", _base_font_size() - 4)
	buttons.add_child(hint)

	var buttons_spacer := Control.new()
	buttons_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(buttons_spacer)

	var name_label := Label.new()
	name_label.text = "Name:"
	name_label.tooltip_text = "Name for the table created by START EXPERIMENT or [+] ADD AS TABLE"
	buttons.add_child(name_label)
	_table_name_edit = LineEdit.new()
	_table_name_edit.placeholder_text = "Table 1"
	_table_name_edit.max_length = 24
	_table_name_edit.custom_minimum_size = Vector2(110, 0)
	buttons.add_child(_table_name_edit)

	_apply_edit_button = Button.new()
	_apply_edit_button.visible = false
	_apply_edit_button.pressed.connect(_on_apply_edit_pressed)
	buttons.add_child(_apply_edit_button)

	_cancel_edit_button = Button.new()
	_cancel_edit_button.text = "Cancel"
	_cancel_edit_button.visible = false
	_cancel_edit_button.tooltip_text = "Close the entry grid without applying anything"
	_cancel_edit_button.pressed.connect(_on_cancel_edit_pressed)
	buttons.add_child(_cancel_edit_button)

	_start_button = Button.new()
	_start_button.text = "START EXPERIMENT"
	_start_button.disabled = true
	_start_button.pressed.connect(_on_start_pressed)
	buttons.add_child(_start_button)

	return panel


## Shared random generation settings (top row) and the favor-driven
## auto-switch rule (bottom row), used by Fill random (setup phase), the
## Random roll button, the auto timer, and every Favor update.
func _build_generation_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "GenerationPanel"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var small := _base_font_size() - 4

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)

	var caption := Label.new()
	caption.text = "Random gen:"
	caption.tooltip_text = "Used by Fill random, Random and Auto"
	caption.add_theme_font_size_override("font_size", small)
	row.add_child(caption)

	_gen_weighted_check = CheckBox.new()
	_gen_weighted_check.text = "weighted"
	_gen_weighted_check.button_pressed = true
	_gen_weighted_check.tooltip_text = "When on, values cluster around the center (weights fall off linearly over the spread, so the mean lands on the center). When off, values are uniform in [-10, 10]."
	_gen_weighted_check.add_theme_font_size_override("font_size", small)
	row.add_child(_gen_weighted_check)

	var center_label := Label.new()
	center_label.text = "center"
	center_label.add_theme_font_size_override("font_size", small)
	row.add_child(center_label)
	_gen_center_spin = SpinBox.new()
	_gen_center_spin.min_value = -10
	_gen_center_spin.max_value = 10
	_gen_center_spin.step = 1
	_gen_center_spin.value = 0
	_gen_center_spin.custom_minimum_size = Vector2(66, 0)
	_gen_center_spin.add_theme_font_size_override("font_size", small)
	row.add_child(_gen_center_spin)

	var spread_label := Label.new()
	spread_label.text = "spread"
	spread_label.tooltip_text = "Weights fall off linearly over this distance from the center: 0 always returns the center, larger values include more of the range."
	spread_label.add_theme_font_size_override("font_size", small)
	row.add_child(spread_label)
	_gen_spread_spin = SpinBox.new()
	_gen_spread_spin.min_value = 0
	_gen_spread_spin.max_value = 20
	_gen_spread_spin.step = 1
	_gen_spread_spin.value = 5
	_gen_spread_spin.custom_minimum_size = Vector2(56, 0)
	_gen_spread_spin.add_theme_font_size_override("font_size", small)
	row.add_child(_gen_spread_spin)

	var interval_label := Label.new()
	interval_label.text = "every"
	interval_label.tooltip_text = "Interval between automatic values in auto mode"
	interval_label.add_theme_font_size_override("font_size", small)
	row.add_child(interval_label)
	_gen_interval_spin = SpinBox.new()
	_gen_interval_spin.min_value = 0.1
	_gen_interval_spin.max_value = 60.0
	_gen_interval_spin.step = 0.1
	_gen_interval_spin.value = 0.5
	_gen_interval_spin.suffix = " s"
	_gen_interval_spin.custom_minimum_size = Vector2(80, 0)
	_gen_interval_spin.add_theme_font_size_override("font_size", small)
	_gen_interval_spin.value_changed.connect(_on_auto_interval_changed)
	row.add_child(_gen_interval_spin)

	var gen_spacer := Control.new()
	gen_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gen_spacer)

	# Favor-driven auto-switch rules (edited in a popup): each rule makes its
	# chosen table the active reference when Favor crosses its threshold.
	var switch_row := HBoxContainer.new()
	switch_row.add_theme_constant_override("separation", 8)
	box.add_child(switch_row)

	_switch_enabled_check = CheckBox.new()
	_switch_enabled_check.text = "Auto-switch:"
	_switch_enabled_check.tooltip_text = "Master switch: when on, the configured rules make a chosen table the active reference whenever Favor crosses that rule's threshold"
	_switch_enabled_check.add_theme_font_size_override("font_size", small)
	_switch_enabled_check.toggled.connect(_on_switch_enabled_toggled)
	switch_row.add_child(_switch_enabled_check)

	_switch_summary_label = Label.new()
	_switch_summary_label.text = "no rules"
	_switch_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_switch_summary_label.clip_text = true
	_switch_summary_label.tooltip_text = "How many rules are armed / already fired"
	_switch_summary_label.add_theme_font_size_override("font_size", small)
	switch_row.add_child(_switch_summary_label)

	_switch_edit_button = Button.new()
	_switch_edit_button.text = "Edit rules..."
	_switch_edit_button.tooltip_text = "Add, remove and configure auto-switch rules"
	_switch_edit_button.add_theme_font_size_override("font_size", small)
	_switch_edit_button.pressed.connect(_on_rules_edit_pressed)
	switch_row.add_child(_switch_edit_button)

	return panel


func _build_run_panel() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.name = "RunPanel"
	vbox.add_theme_constant_override("separation", 4)

	# Statistics panel.
	var stats_panel := PanelContainer.new()
	vbox.add_child(stats_panel)
	var stats_margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		stats_margin.add_theme_constant_override(side, 6)
	stats_panel.add_child(stats_margin)
	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 4)
	stats_margin.add_child(stats_box)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	stats_box.add_child(top_row)
	var t_box := VBoxContainer.new()
	t_box.add_theme_constant_override("separation", 0)
	top_row.add_child(t_box)
	var t_caption := Label.new()
	t_caption.text = "t statistic (two-sample)"
	t_caption.add_theme_font_size_override("font_size", _base_font_size() - 4)
	t_box.add_child(t_caption)
	_t_value_label = Label.new()
	_t_value_label.text = "N/A"
	_t_value_label.add_theme_font_size_override("font_size", _base_font_size() + 8)
	t_box.add_child(_t_value_label)

	_t_interpretation_label = Label.new()
	_t_interpretation_label.text = ""
	_t_interpretation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_t_interpretation_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_t_interpretation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_t_interpretation_label.custom_minimum_size = Vector2(140, 0)
	top_row.add_child(_t_interpretation_label)

	# Favor counter: starts at 50; [+] adds the current t statistic to it.
	var favor_box := VBoxContainer.new()
	favor_box.add_theme_constant_override("separation", 0)
	top_row.add_child(favor_box)
	var favor_caption := Label.new()
	favor_caption.text = "Favor"
	favor_caption.add_theme_font_size_override("font_size", _base_font_size() - 4)
	favor_box.add_child(favor_caption)
	var favor_row := HBoxContainer.new()
	favor_row.add_theme_constant_override("separation", 4)
	favor_box.add_child(favor_row)
	_favor_value_label = Label.new()
	_favor_value_label.text = "%.3f" % _favor
	_favor_value_label.add_theme_font_size_override("font_size", _base_font_size() + 4)
	favor_row.add_child(_favor_value_label)
	_add_t_button = Button.new()
	_add_t_button.text = "[+]"
	_add_t_button.tooltip_text = "Add the current t statistic to Favor"
	_add_t_button.pressed.connect(_on_add_t_to_favor_pressed)
	favor_row.add_child(_add_t_button)

	# Reference table selection and creation.
	var refs_row := HBoxContainer.new()
	refs_row.add_theme_constant_override("separation", 8)
	stats_box.add_child(refs_row)
	_refs_row = refs_row
	var refs_label := Label.new()
	refs_label.text = "Reference table:"
	refs_row.add_child(refs_label)
	_table_option = OptionButton.new()
	_table_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table_option.item_selected.connect(_on_reference_table_selected)
	refs_row.add_child(_table_option)
	_new_table_button = Button.new()
	_new_table_button.text = "[+] New table"
	_new_table_button.tooltip_text = "Enter 30 values below and add them as an additional reference table (the rolling window is kept)"
	_new_table_button.pressed.connect(_on_new_table_button_pressed)
	refs_row.add_child(_new_table_button)
	_tables_button = Button.new()
	_tables_button.text = "Tables..."
	_tables_button.tooltip_text = "Rename, edit, save and load reference tables"
	_tables_button.pressed.connect(_on_tables_button_pressed)
	refs_row.add_child(_tables_button)

	_reset_window_button = Button.new()
	_reset_window_button.text = "Reset window"
	_reset_window_button.pressed.connect(_on_reset_window_pressed)
	refs_row.add_child(_reset_window_button)

	var stats_grid := GridContainer.new()
	stats_grid.columns = 8
	stats_grid.add_theme_constant_override("h_separation", 12)
	stats_grid.add_theme_constant_override("v_separation", 2)
	stats_box.add_child(stats_grid)
	_stats_grid = stats_grid
	_ref_mean_label = _add_stat(stats_grid, "Ref mean")
	_cur_mean_label = _add_stat(stats_grid, "Cur mean")
	_diff_label = _add_stat(stats_grid, "Diff (cur-ref)")
	_p_label = _add_stat(stats_grid, "p (2-tailed)")
	_ref_sd_label = _add_stat(stats_grid, "Ref std dev")
	_cur_sd_label = _add_stat(stats_grid, "Cur std dev")
	_se_label = _add_stat(stats_grid, "Std error")
	_df_label = _add_stat(stats_grid, "Degrees of freedom")

	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 16)
	stats_box.add_child(info_row)
	_info_row = info_row
	_sample_size_label = Label.new()
	info_row.add_child(_sample_size_label)
	_roll_count_label = Label.new()
	info_row.add_child(_roll_count_label)
	_last_action_label = Label.new()
	_last_action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_last_action_label.clip_text = true
	info_row.add_child(_last_action_label)

	# Data dump for verification (reference + rolling window contents).
	_dump_label = Label.new()
	_dump_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dump_label.add_theme_font_size_override("font_size", _base_font_size() - 6)
	vbox.add_child(_dump_label)

	# Roll input row.
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 6)
	vbox.add_child(input_row)
	var input_label := Label.new()
	input_label.text = "Next value:"
	input_row.add_child(input_label)
	_roll_input = LineEdit.new()
	_roll_input.placeholder_text = "-10 .. 10"
	_roll_input.max_length = 8
	_roll_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roll_input.text_submitted.connect(_on_roll_text_submitted)
	input_row.add_child(_roll_input)
	var submit_button := Button.new()
	submit_button.text = "Submit (Enter)"
	submit_button.pressed.connect(_on_submit_pressed)
	input_row.add_child(submit_button)
	var random_roll_button := Button.new()
	random_roll_button.text = "Random"
	random_roll_button.tooltip_text = "Submit a random value using the generation settings (weighted or uniform)"
	random_roll_button.pressed.connect(_on_random_roll_pressed)
	input_row.add_child(random_roll_button)
	_auto_button = Button.new()
	_auto_button.text = "Auto: start"
	_auto_button.tooltip_text = "Automatically submit a random value (per the generation settings) every interval; each value's t is added to Favor before the next one is generated"
	_auto_button.pressed.connect(_on_auto_pressed)
	input_row.add_child(_auto_button)

	# Histograms (side by side, shared axis and y scale).
	var histogram_row := HBoxContainer.new()
	histogram_row.name = "Histograms"
	histogram_row.add_theme_constant_override("separation", 8)
	histogram_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(histogram_row)
	_histogram_row = histogram_row

	_ref_histogram = HistogramView.new()
	_ref_histogram.title = "REFERENCE DISTRIBUTION"
	_ref_histogram.bar_color = Color(0.42, 0.6, 0.95)
	_ref_histogram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ref_histogram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	histogram_row.add_child(_ref_histogram)

	_cur_histogram = HistogramView.new()
	_cur_histogram.title = "CURRENT DISTRIBUTION"
	_cur_histogram.bar_color = Color(0.3, 0.78, 0.55)
	_cur_histogram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cur_histogram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	histogram_row.add_child(_cur_histogram)

	return vbox


func _add_stat(grid: GridContainer, caption: String) -> Label:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	grid.add_child(box)
	var cap := Label.new()
	cap.text = caption
	cap.add_theme_font_size_override("font_size", _base_font_size() - 4)
	box.add_child(cap)
	var value := Label.new()
	value.text = "-"
	box.add_child(value)
	return value


func _base_font_size() -> int:
	return maxi(10, get_theme_default_font_size())


# --- Signal handlers ---------------------------------------------------------


func _on_reference_cell_changed(_text: String, _index: int) -> void:
	_refresh_setup_validation()


func _on_reference_cell_submitted(_text: String, index: int) -> void:
	var next := index + 1
	if next < SAMPLE_SIZE:
		_value_cells[next].grab_focus()
	elif _setup_is_valid():
		_start_experiment()


func _on_fill_random_pressed() -> void:
	var values: Array[int] = []
	for i in SAMPLE_SIZE:
		values.append(generate_random_value())
	set_reference_values(values)


func _on_clear_reference_pressed() -> void:
	set_reference_values([])


func _on_start_pressed() -> void:
	if _running:
		_add_table_from_grid()
	else:
		_start_experiment()


func _on_reset_window_pressed() -> void:
	reset_window()


func _on_add_t_to_favor_pressed() -> void:
	add_current_t_to_favor()


func _on_new_table_button_pressed() -> void:
	if not _running:
		return
	_grid_edit_kind = "none"
	_grid_edit_index = -1
	_set_setup_panel_visible(not _setup_panel.visible)
	if _setup_panel.visible:
		set_reference_values([])
		_table_name_edit.text = ""
		_value_cells[0].grab_focus()


func _on_cancel_edit_pressed() -> void:
	_grid_edit_kind = "none"
	_grid_edit_index = -1
	_set_setup_panel_visible(false)


func _on_reference_table_selected(index: int) -> void:
	select_reference_table(index)


func _on_submit_pressed() -> void:
	submit_next_value(_roll_input.text)


func _on_random_roll_pressed() -> void:
	if _running:
		submit_value(float(generate_random_value()))


func _on_auto_pressed() -> void:
	if _auto_running:
		stop_auto()
	else:
		start_auto()


func _on_switch_enabled_toggled(pressed: bool) -> void:
	if pressed:
		for r in _switch_rules:
			r["fired"] = false
	_evaluate_switch_rules()


func _on_rules_edit_pressed() -> void:
	_open_centered_popup(_switch_editor, Vector2i(680, 300))


## Shows a popup centered horizontally near the top of the view, with an
## explicit size so it can never extend past the bottom of the 754x496 view.
## (Auto-sized popups can grow to their content minimum, which for some
## labels is far taller than the view.)
func _open_centered_popup(popup: PopupPanel, popup_size: Vector2i) -> void:
	var view := get_viewport_rect().size
	popup.size = popup_size
	popup.position = Vector2i(int((view.x - popup_size.x) / 2.0), 24)
	popup.popup()


func _on_rules_close_pressed() -> void:
	_switch_editor.hide()


func _on_tables_button_pressed() -> void:
	_open_centered_popup(_tables_popup, Vector2i(680, 340))


func _on_tables_close_pressed() -> void:
	_tables_popup.hide()


func _on_session_name_changed(text: String, index: int) -> void:
	if index < 0 or index >= _table_names.size():
		return
	_table_names[index] = text
	_refresh_table_options()
	_dump_reference_text = _reference_summary_text()
	_update_dump_label(get_current_values())


func _on_session_edit_pressed(index: int) -> void:
	edit_session_table(index)


func _on_session_save_library_pressed(index: int) -> void:
	_save_session_table_to_library(index)


func _on_session_delete_pressed(index: int) -> void:
	_delete_session_table(index)


func _on_library_name_changed(text: String, index: int) -> void:
	if index < 0 or index >= _saved_tables.size():
		return
	_saved_tables[index]["name"] = text
	_save_library_to_file()
	_refresh_setup_validation()


func _on_library_edit_pressed(index: int) -> void:
	edit_library_table(index)


func _on_library_use_pressed(index: int) -> void:
	use_saved_table(index)


func _on_library_delete_pressed(index: int) -> void:
	_delete_library_table(index)


func _on_apply_edit_pressed() -> void:
	_apply_grid_to_target()


func _on_rule_add_pressed() -> void:
	var threshold := 70.0
	if not _switch_rules.is_empty():
		threshold = float(_switch_rules[_switch_rules.size() - 1]["threshold"]) + 20.0
	add_switch_rule(true, threshold, _default_switch_target())


func _on_rules_clear_fired_pressed() -> void:
	for r in _switch_rules:
		r["fired"] = false
	_evaluate_switch_rules()


func _on_rule_enabled_toggled(pressed: bool, index: int) -> void:
	_switch_rules[index]["enabled"] = pressed
	_evaluate_switch_rules()


func _on_rule_direction_changed(direction: int, index: int) -> void:
	_switch_rules[index]["above"] = direction == 0
	_evaluate_switch_rules()


func _on_rule_threshold_changed(value: float, index: int) -> void:
	_switch_rules[index]["threshold"] = value
	_evaluate_switch_rules()


func _on_rule_target_selected(target: int, index: int) -> void:
	_switch_rules[index]["target"] = target
	_evaluate_switch_rules()


func _on_rule_delete_pressed(index: int) -> void:
	_switch_rules.remove_at(index)
	_rebuild_rules_editor()
	_evaluate_switch_rules()


func _on_auto_interval_changed(value: float) -> void:
	if _auto_running:
		_auto_timer.wait_time = maxf(0.05, value)


## One auto tick: generate a value from the settings, submit it, and add the
## resulting t statistic to Favor - all before the next value is generated.
func _on_auto_timer_timeout() -> void:
	if not _auto_running or not _running:
		if _auto_running:
			stop_auto()
		return
	_switch_rule_just_fired = false
	var value := generate_random_value()
	if not submit_value(float(value)):
		stop_auto()
		return
	var favor_result := add_current_t_to_favor()
	if is_nan(favor_result):
		_last_action_label.text = "Auto: entered %s; Favor unchanged (no valid t)." % _format_number(value)
	elif _switch_rule_just_fired:
		_switch_rule_just_fired = false
		_last_action_label.text = "Auto: entered %s. %s" % [_format_number(value), _last_action_label.text]
	else:
		_last_action_label.text = "Auto: entered %s and added its t to Favor (%s)." % [_format_number(value), _format_stat(favor_result)]


func _on_roll_text_submitted(text: String) -> void:
	submit_next_value(text)


# --- Public API (also used by the self-test) ---------------------------------


## Fills the reference entry cells from `values` (in order; missing entries are
## cleared, extra entries ignored). Returns true when all 30 cells hold valid
## numbers afterwards.
func set_reference_values(values: Array) -> bool:
	for i in SAMPLE_SIZE:
		if i < values.size():
			_value_cells[i].text = _format_number(float(values[i]))
		else:
			_value_cells[i].text = ""
	_refresh_setup_validation()
	return _setup_is_valid()


## Starts the experiment if the reference sample is complete. Returns whether
## the experiment is running afterwards.
func start_experiment() -> bool:
	if not _setup_is_valid():
		return false
	_start_experiment()
	return true


## Parses and submits the next roll from raw text (e.g. the input field).
## Returns false (without changing state) if not running or the text is not a
## valid number.
func submit_next_value(text: String) -> bool:
	if not _running:
		return false
	var trimmed := text.strip_edges()
	if trimmed.is_empty() or not trimmed.is_valid_float():
		if not trimmed.is_empty():
			_last_action_label.text = "Invalid value: \"%s\" - enter a number." % trimmed
		return false
	return submit_value(trimmed.to_float())


## Submits an already parsed roll: slides the window, recomputes statistics,
## updates the graphs.
func submit_value(value: float) -> bool:
	if not _running or _rolling == null:
		return false
	var evicted := _rolling.push(value)
	_roll_count += 1
	_last_action_label.text = "Last roll: entered %s, removed oldest %s." \
			% [_format_number(value), _format_number(evicted)]
	_update_experiment_display()
	_roll_input.clear()
	_roll_input.grab_focus()
	return true


## Restarts the rolling window as an exact copy of the (unchanged) reference.
func reset_window() -> void:
	if _rolling == null:
		return
	_rolling = RollingSample.new(_reference_values, SAMPLE_SIZE)
	_roll_count = 0
	_last_action_label.text = "Window reset: current sample is again an exact copy of the reference."
	_update_experiment_display()


## Adds `values` (exactly 30 numbers) as a NEW named reference table, makes it
## the active reference, and keeps the rolling window untouched. Previous
## tables stay selectable via the "Reference table" dropdown.
func add_reference_table(values: Array, table_name := "") -> bool:
	if not _running or values.size() != SAMPLE_SIZE:
		return false
	var table: Array[float] = []
	for v in values:
		table.append(float(v))
	_reference_tables.append(table)
	var new_name := table_name.strip_edges()
	if new_name.is_empty():
		new_name = "Table %d" % _reference_tables.size()
	_table_names.append(new_name)
	_active_table_index = _reference_tables.size() - 1
	_reference_values = table
	_refresh_table_options()
	set_reference_values([])
	_dump_reference_text = _reference_summary_text()
	_update_dump_label(get_current_values())
	_last_action_label.text = "Added '%s' as the active reference (rolling window kept)." % new_name
	_update_experiment_display()
	return true


## Makes stored table `index` (0-based, as listed in the dropdown) the active
## reference and keeps the rolling window untouched.
func select_reference_table(index: int) -> bool:
	if not _running or index < 0 or index >= _reference_tables.size():
		return false
	_active_table_index = index
	_reference_values = _reference_tables[index]
	_table_option.select(index)
	_dump_reference_text = _reference_summary_text()
	_update_dump_label(get_current_values())
	_last_action_label.text = "Reference switched to '%s' (rolling window kept)." % _table_display_name(index)
	_update_experiment_display()
	return true


func get_reference_table_count() -> int:
	return _reference_tables.size()


func get_reference_table(index: int) -> Array[float]:
	var empty: Array[float] = []
	if index < 0 or index >= _reference_tables.size():
		return empty
	return _reference_tables[index].duplicate()


func get_active_reference_table_index() -> int:
	return _active_table_index


func get_favor() -> float:
	return _favor


## Adds the current t statistic to the Favor counter (which starts at 50).
## Returns the updated Favor, or NAN when no valid finite t exists.
func add_current_t_to_favor() -> float:
	if not _running:
		return NAN
	var t: float = _last_result.get("t", NAN)
	if is_nan(t) or is_inf(t):
		_last_action_label.text = "Cannot add to Favor: no valid t statistic available."
		return NAN
	_favor += t
	_favor_value_label.text = "%.3f" % _favor
	_last_action_label.text = "Favor: added t = %s, Favor is now %s." % [_format_t(t), _format_stat(_favor)]
	_evaluate_switch_rules()
	return _favor


## Generates one random value from the generation settings: weighted around
## the center value, or uniform in [-10, 10] when "weighted" is unticked.
func generate_random_value() -> int:
	if _gen_weighted_check.button_pressed:
		return StatisticsAnalyzer.random_weighted_int(
				DEFAULT_AXIS_MIN, DEFAULT_AXIS_MAX, int(_gen_center_spin.value), _gen_spread_spin.value)
	return randi_range(DEFAULT_AXIS_MIN, DEFAULT_AXIS_MAX)


## Starts automatic rolls: every interval a value is generated from the
## generation settings, submitted, and its t statistic added to Favor before
## the next value is generated.
func start_auto() -> void:
	if not _running or _auto_running:
		return
	_auto_timer.wait_time = maxf(0.05, _gen_interval_spin.value)
	_auto_timer.start()
	_auto_running = true
	_auto_button.text = "Auto: stop"
	_last_action_label.text = "Auto generation started: one value every %s s, each t added to Favor." % _format_number(_gen_interval_spin.value)


func stop_auto() -> void:
	if not _auto_running:
		return
	_auto_timer.stop()
	_auto_running = false
	_auto_button.text = "Auto: start"
	_last_action_label.text = "Auto generation stopped."


## Evaluates every enabled auto-switch rule after any Favor change: a rule
## whose threshold Favor has crossed fires once (making its target table the
## active reference; the last rule to fire wins) and re-arms once Favor moves
## back to the other side of that rule's threshold.
func _evaluate_switch_rules() -> void:
	_switch_rule_just_fired = false
	if not _running or not _switch_enabled_check.button_pressed:
		_refresh_switch_ui()
		return
	for i in _switch_rules.size():
		var rule: Dictionary = _switch_rules[i]
		if not rule["enabled"]:
			continue
		var threshold: float = rule["threshold"]
		var above: bool = rule["above"]
		if rule["fired"]:
			if (above and _favor < threshold) or (not above and _favor > threshold):
				rule["fired"] = false
			continue
		if (above and _favor >= threshold) or (not above and _favor <= threshold):
			rule["fired"] = true
			_switch_rule_just_fired = true
			var target: int = rule["target"]
			if target >= 0 and target < _reference_tables.size():
				select_reference_table(target)
				_last_action_label.text = "Auto-switch rule %d: favor %s %s %s -> reference is now '%s'." \
						% [i + 1, _format_stat(_favor), ">=" if above else "<=", _format_number(threshold), _table_display_name(target)]
			else:
				_last_action_label.text = "Auto-switch rule %d: threshold reached but the target table does not exist." % (i + 1)
	_refresh_switch_ui()


func _refresh_switch_ui() -> void:
	if _switch_summary_label == null:
		return
	if not _running or not _switch_enabled_check.button_pressed:
		_switch_summary_label.text = "off"
	elif _switch_rules.is_empty():
		_switch_summary_label.text = "no rules"
	else:
		var armed := 0
		var fired := 0
		for r in _switch_rules:
			if r["fired"]:
				fired += 1
			else:
				armed += 1
		_switch_summary_label.text = "%d rules: %d armed, %d fired" % [_switch_rules.size(), armed, fired]
	for i in _rule_status_labels.size():
		var rule: Dictionary = _switch_rules[i]
		if not rule["enabled"]:
			_rule_status_labels[i].text = "off"
		elif rule["fired"]:
			_rule_status_labels[i].text = "fired"
		else:
			_rule_status_labels[i].text = "armed"


## Configures the full auto-switch rule list in one call (also used by the
## self-test). Each entry: {above: bool, threshold: float, target: int}.
## All rules start enabled and unarmed; configuring rules also switches the
## master "Auto-switch" checkbox on, then the list is evaluated immediately.
func set_switch_rules(rules: Array) -> void:
	_switch_rules.clear()
	for r in rules:
		_switch_rules.append({
			"enabled": true,
			"above": bool(r.get("above", true)),
			"threshold": float(r.get("threshold", 0.0)),
			"target": int(r.get("target", 0)),
			"fired": false,
		})
	_switch_enabled_check.button_pressed = true
	_rebuild_rules_editor()
	_evaluate_switch_rules()


## Appends one enabled, unarmed rule and re-evaluates.
func add_switch_rule(at_or_above: bool, threshold: float, target_index: int) -> void:
	_switch_rules.append({
		"enabled": true,
		"above": at_or_above,
		"threshold": threshold,
		"target": target_index,
		"fired": false,
	})
	_rebuild_rules_editor()
	_evaluate_switch_rules()


func _default_switch_target() -> int:
	return maxi(0, _reference_tables.size() - 1)


## Rebuilds the rule rows inside the editor popup from _switch_rules.
func _rebuild_rules_editor() -> void:
	if _rules_list == null:
		return
	for c in _rules_list.get_children():
		c.queue_free()
	_rule_status_labels.clear()
	var small := _base_font_size() - 4
	for i in _switch_rules.size():
		var rule: Dictionary = _switch_rules[i]

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_rules_list.add_child(row)

		var enable := CheckBox.new()
		enable.text = "rule %d" % (i + 1)
		enable.button_pressed = rule["enabled"]
		enable.add_theme_font_size_override("font_size", small)
		enable.toggled.connect(_on_rule_enabled_toggled.bind(i))
		row.add_child(enable)

		var dir := OptionButton.new()
		dir.add_item(">=")
		dir.add_item("<=")
		dir.select(0 if rule["above"] else 1)
		dir.custom_minimum_size = Vector2(52, 0)
		dir.add_theme_font_size_override("font_size", small)
		dir.item_selected.connect(_on_rule_direction_changed.bind(i))
		row.add_child(dir)

		var spin := SpinBox.new()
		spin.min_value = -1000
		spin.max_value = 1000
		spin.step = 1
		spin.value = rule["threshold"]
		spin.custom_minimum_size = Vector2(72, 0)
		spin.add_theme_font_size_override("font_size", small)
		spin.value_changed.connect(_on_rule_threshold_changed.bind(i))
		row.add_child(spin)

		var arrow := Label.new()
		arrow.text = "switch to"
		arrow.add_theme_font_size_override("font_size", small)
		row.add_child(arrow)

		var target := OptionButton.new()
		target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for t in _reference_tables.size():
			target.add_item(_table_display_name(t))
		if rule["target"] >= 0 and rule["target"] < _reference_tables.size():
			target.select(rule["target"])
		target.add_theme_font_size_override("font_size", small)
		target.item_selected.connect(_on_rule_target_selected.bind(i))
		row.add_child(target)

		var status := Label.new()
		status.custom_minimum_size = Vector2(56, 0)
		status.add_theme_font_size_override("font_size", small)
		row.add_child(status)
		_rule_status_labels.append(status)

		var del := Button.new()
		del.text = "X"
		del.tooltip_text = "Delete this rule"
		del.custom_minimum_size = Vector2(30, 0)
		del.add_theme_font_size_override("font_size", small)
		del.pressed.connect(_on_rule_delete_pressed.bind(i))
		row.add_child(del)
	_refresh_switch_ui()


## Builds the popup that hosts the auto-switch rule editor.
func _build_switch_editor() -> void:
	_switch_editor = PopupPanel.new()
	_switch_editor.name = "SwitchRulesPopup"
	_switch_editor.min_size = Vector2i(660, 300)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	_switch_editor.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var hint := Label.new()
	hint.text = "Rules fire when Favor crosses the threshold. The last rule to fire wins."
	hint.tooltip_text = "Rules fire when Favor crosses the threshold (once per crossing; each rule re-arms when Favor moves back to its other side). The last rule to fire wins."
	hint.clip_text = true
	hint.custom_minimum_size = Vector2(0, 20)
	hint.add_theme_font_size_override("font_size", _base_font_size() - 4)
	vbox.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 160)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_rules_list = VBoxContainer.new()
	_rules_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rules_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_rules_list)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	vbox.add_child(footer)
	var add_button := Button.new()
	add_button.text = "[+] Add rule"
	add_button.pressed.connect(_on_rule_add_pressed)
	footer.add_child(add_button)
	var rearm_button := Button.new()
	rearm_button.text = "Re-arm all"
	rearm_button.tooltip_text = "Clear the fired flags so every rule can fire again"
	rearm_button.pressed.connect(_on_rules_clear_fired_pressed)
	footer.add_child(rearm_button)
	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_on_rules_close_pressed)
	footer.add_child(close_button)

	add_child(_switch_editor)


# --- Named tables, library file, and grid editing -----------------------------


## Display name of a session table (falls back to "Table N" when unnamed).
func _table_display_name(index: int) -> String:
	var display := ""
	if index >= 0 and index < _table_names.size():
		display = _table_names[index]
	if display.strip_edges().is_empty():
		display = "Table %d" % (index + 1)
	return display


## Display name of a saved library table.
func _library_display_name(index: int) -> String:
	var display := ""
	if index >= 0 and index < _saved_tables.size():
		display = String(_saved_tables[index]["name"])
	if display.strip_edges().is_empty():
		display = "Table %d" % (index + 1)
	return display


## Name for a table created from the entry grid (name field, or auto-numbered;
## called after the table has been added to the session list).
func _pending_table_name() -> String:
	var entered := _table_name_edit.text.strip_edges()
	if not entered.is_empty():
		return entered
	return "Table %d" % _reference_tables.size()


## Shows/hides the entry grid. While it is open during a run, the reference
## dropdown row, the stats grid, the info row and the data dump step aside so
## the entry grid AND both histograms fit the 754x496 view.
func _set_setup_panel_visible(open: bool) -> void:
	_setup_panel.visible = open
	var editing_during_run := open and _running
	_histogram_row.visible = true
	_dump_label.visible = not editing_during_run
	_refs_row.visible = not editing_during_run
	_stats_grid.visible = not editing_during_run
	_info_row.visible = not editing_during_run
	_cancel_edit_button.visible = editing_during_run


## Shows the entry grid without clearing it (used by the table editors).
func _show_setup_grid() -> void:
	_set_setup_panel_visible(true)
	_refresh_setup_validation()
	_value_cells[0].grab_focus()


## Loads a session table into the entry grid; the apply button then writes the
## edited values (and name) back to that table. Closes the tables popup so the
## grid and START are reachable.
func edit_session_table(index: int) -> void:
	if index < 0 or index >= _reference_tables.size():
		return
	_tables_popup.hide()
	_grid_edit_kind = "session"
	_grid_edit_index = index
	set_reference_values(_reference_tables[index])
	_table_name_edit.text = _table_names[index]
	_show_setup_grid()


## Loads a saved library table into the entry grid; the apply button saves the
## edited values (and name) back to the library file. Closes the tables popup
## so the grid and START are reachable.
func edit_library_table(index: int) -> void:
	if index < 0 or index >= _saved_tables.size():
		return
	_tables_popup.hide()
	_grid_edit_kind = "library"
	_grid_edit_index = index
	set_reference_values(_saved_tables[index]["values"])
	_table_name_edit.text = String(_saved_tables[index]["name"])
	_show_setup_grid()


## Writes the edited grid values (and name) back to the current edit target:
## a session table, or a saved library table (persisted to file).
func _apply_grid_to_target() -> void:
	if _grid_edit_kind == "none" or not _setup_is_valid():
		_last_action_label.text = "Cannot apply: the grid does not hold 30 valid values."
		return
	var values := _read_grid_values()
	var new_name := _table_name_edit.text.strip_edges()
	if _grid_edit_kind == "session":
		var index := _grid_edit_index
		if index < 0 or index >= _reference_tables.size():
			return
		_reference_tables[index] = values
		if not new_name.is_empty():
			_table_names[index] = new_name
		if _running and index == _active_table_index:
			_reference_values = _reference_tables[index]
		_last_action_label.text = "Applied edited values to '%s'." % _table_display_name(index)
	elif _grid_edit_kind == "library":
		var library_index := _grid_edit_index
		if library_index < 0 or library_index >= _saved_tables.size():
			return
		if not new_name.is_empty():
			_saved_tables[library_index]["name"] = new_name
		_saved_tables[library_index]["values"] = values
		_save_library_to_file()
		_last_action_label.text = "Saved edited values to '%s'." % _library_display_name(library_index)
	_grid_edit_kind = "none"
	_grid_edit_index = -1
	_refresh_table_options()
	if _running:
		_set_setup_panel_visible(false)
		_update_experiment_display()
	_update_dump_label(get_current_values())
	_refresh_setup_validation()


## Copies a session table into the saved library (upserted by name) and
## persists the library file.
func _save_session_table_to_library(index: int) -> void:
	if index < 0 or index >= _reference_tables.size():
		return
	var entry := {"name": _table_display_name(index), "values": _reference_tables[index].duplicate()}
	var replaced := false
	for i in _saved_tables.size():
		if String(_saved_tables[i]["name"]) == entry["name"]:
			_saved_tables[i] = entry
			replaced = true
			break
	if not replaced:
		_saved_tables.append(entry)
	_save_library_to_file()
	_rebuild_tables_editor()


## Puts a saved library table into play: during a run it is added to the
## session as the new active reference; during setup it fills the grid for
## START. Closes the tables popup so the grid and START are reachable.
func use_saved_table(index: int) -> void:
	if index < 0 or index >= _saved_tables.size():
		return
	var entry: Dictionary = _saved_tables[index]
	var values: Array[float] = []
	for v in entry["values"]:
		values.append(float(v))
	_tables_popup.hide()
	if _running:
		add_reference_table(values, String(entry["name"]))
		_last_action_label.text = "Loaded '%s' into the session as the active reference (rolling window kept)." \
				% _table_display_name(_active_table_index)
	else:
		_grid_edit_kind = "none"
		_grid_edit_index = -1
		set_reference_values(values)
		_table_name_edit.text = String(entry["name"])
		_show_setup_grid()
		_last_action_label.text = "Loaded '%s' into the grid (%d / %d values) - complete it and press START EXPERIMENT." \
				% [_library_display_name(index), values.size(), SAMPLE_SIZE]


func _delete_session_table(index: int) -> bool:
	if _reference_tables.size() <= 1:
		_tables_status_label.text = "Cannot delete the last session table."
		return false
	if index < 0 or index >= _reference_tables.size():
		return false
	var removed_name := _table_display_name(index)
	_reference_tables.remove_at(index)
	if index < _table_names.size():
		_table_names.remove_at(index)
	if index < _active_table_index:
		_active_table_index -= 1
	else:
		_active_table_index = clampi(_active_table_index, 0, _reference_tables.size() - 1)
	_reference_values = _reference_tables[_active_table_index]
	_refresh_table_options()
	_dump_reference_text = _reference_summary_text()
	_update_dump_label(get_current_values())
	_update_experiment_display()
	_rebuild_tables_editor()
	_last_action_label.text = "Deleted '%s' from the session." % removed_name
	return true


func _delete_library_table(index: int) -> void:
	if index < 0 or index >= _saved_tables.size():
		return
	var removed_name := _library_display_name(index)
	_saved_tables.remove_at(index)
	_save_library_to_file()
	_rebuild_tables_editor()
	_last_action_label.text = "Deleted '%s' from the saved library." % removed_name


## Writes the saved-tables library to statistics_test/saved_tables.json.
func _save_library_to_file() -> bool:
	var tables: Array = []
	for entry in _saved_tables:
		var values: Array = []
		for v in entry["values"]:
			values.append(float(v))
		tables.append({"name": String(entry["name"]), "values": values})
	var file := FileAccess.open(_library_path, FileAccess.WRITE)
	if file == null:
		_tables_status_label.text = "Could not write %s" % _library_path
		return false
	file.store_string(JSON.stringify({"tables": tables}, "\t"))
	file.close()
	_tables_status_label.text = "Saved %d tables to %s" % [tables.size(), _library_path.get_file()]
	return true


## Loads the saved-tables library from disk (called automatically at startup).
func _load_library_from_file() -> void:
	_saved_tables.clear()
	if not FileAccess.file_exists(_library_path):
		_tables_status_label.text = "No saved tables file yet."
		_rebuild_tables_editor()
		return
	var file := FileAccess.open(_library_path, FileAccess.READ)
	if file == null:
		_tables_status_label.text = "Could not read %s" % _library_path
		_rebuild_tables_editor()
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("tables", null)) != TYPE_ARRAY:
		_tables_status_label.text = "Saved tables file is not valid - ignored."
		_rebuild_tables_editor()
		return
	for entry in parsed["tables"]:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var values: Array[float] = []
		var raw_values = entry.get("values", [])
		if typeof(raw_values) == TYPE_ARRAY:
			for v in raw_values:
				values.append(float(v))
		_saved_tables.append({"name": String(entry.get("name", "")), "values": values})
	_tables_status_label.text = "Loaded %d saved tables." % _saved_tables.size()
	_rebuild_tables_editor()


## Rebuilds the rows of the tables popup from the session tables and library.
func _rebuild_tables_editor() -> void:
	if _tables_list == null or _library_list == null:
		return
	for child in _tables_list.get_children():
		child.queue_free()
	for child in _library_list.get_children():
		child.queue_free()
	var small := _base_font_size() - 4

	for i in _reference_tables.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_tables_list.add_child(row)

		var name_edit := LineEdit.new()
		name_edit.text = _table_names[i] if i < _table_names.size() else ""
		name_edit.placeholder_text = "Table %d" % (i + 1)
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_edit.add_theme_font_size_override("font_size", small)
		name_edit.text_changed.connect(_on_session_name_changed.bind(i))
		row.add_child(name_edit)

		var edit_button := Button.new()
		edit_button.text = "Edit"
		edit_button.tooltip_text = "Load these values into the entry grid to edit them"
		edit_button.add_theme_font_size_override("font_size", small)
		edit_button.pressed.connect(_on_session_edit_pressed.bind(i))
		row.add_child(edit_button)

		var save_button := Button.new()
		save_button.text = "Save to file"
		save_button.tooltip_text = "Copy this table into the saved library (upserted by name) and write the file"
		save_button.add_theme_font_size_override("font_size", small)
		save_button.pressed.connect(_on_session_save_library_pressed.bind(i))
		row.add_child(save_button)

		var delete_button := Button.new()
		delete_button.text = "X"
		delete_button.add_theme_font_size_override("font_size", small)
		delete_button.pressed.connect(_on_session_delete_pressed.bind(i))
		row.add_child(delete_button)

	for i in _saved_tables.size():
		var entry: Dictionary = _saved_tables[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_library_list.add_child(row)

		var name_edit := LineEdit.new()
		name_edit.text = String(entry["name"])
		name_edit.placeholder_text = "Table %d" % (i + 1)
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_edit.add_theme_font_size_override("font_size", small)
		name_edit.text_changed.connect(_on_library_name_changed.bind(i))
		row.add_child(name_edit)

		var edit_button := Button.new()
		edit_button.text = "Edit"
		edit_button.tooltip_text = "Load these values into the entry grid to edit them"
		edit_button.add_theme_font_size_override("font_size", small)
		edit_button.pressed.connect(_on_library_edit_pressed.bind(i))
		row.add_child(edit_button)

		var use_button := Button.new()
		use_button.text = "Use"
		use_button.tooltip_text = "During a run: add this table to the session as the active reference. During setup: fill the entry grid with it."
		use_button.add_theme_font_size_override("font_size", small)
		use_button.pressed.connect(_on_library_use_pressed.bind(i))
		row.add_child(use_button)

		var delete_button := Button.new()
		delete_button.text = "X"
		delete_button.add_theme_font_size_override("font_size", small)
		delete_button.pressed.connect(_on_library_delete_pressed.bind(i))
		row.add_child(delete_button)


## Builds the popup that hosts the tables editor.
func _build_tables_editor() -> void:
	_tables_popup = PopupPanel.new()
	_tables_popup.name = "TablesPopup"
	_tables_popup.min_size = Vector2i(680, 340)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	_tables_popup.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var session_label := Label.new()
	session_label.text = "Session tables (in use):"
	session_label.add_theme_font_size_override("font_size", _base_font_size() - 4)
	vbox.add_child(session_label)

	var session_scroll := ScrollContainer.new()
	session_scroll.custom_minimum_size = Vector2(0, 96)
	session_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(session_scroll)

	_tables_list = VBoxContainer.new()
	_tables_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tables_list.add_theme_constant_override("separation", 4)
	session_scroll.add_child(_tables_list)

	var library_label := Label.new()
	library_label.text = "Saved in saved_tables.json (auto-loaded at startup):"
	library_label.add_theme_font_size_override("font_size", _base_font_size() - 4)
	vbox.add_child(library_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 130)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_library_list = VBoxContainer.new()
	_library_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_library_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_library_list)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	vbox.add_child(footer)
	var save_button := Button.new()
	save_button.text = "Save library to file"
	save_button.pressed.connect(_save_library_to_file)
	footer.add_child(save_button)
	_tables_status_label = Label.new()
	_tables_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tables_status_label.clip_text = true
	_tables_status_label.add_theme_font_size_override("font_size", _base_font_size() - 4)
	footer.add_child(_tables_status_label)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_on_tables_close_pressed)
	footer.add_child(close_button)

	add_child(_tables_popup)


func is_running() -> bool:
	return _running


func get_reference_values() -> Array[float]:
	return _reference_values.duplicate()


func get_current_values() -> Array[float]:
	if _rolling == null:
		var empty: Array[float] = []
		return empty
	return _rolling.snapshot()


func get_last_result() -> Dictionary:
	return _last_result


# --- Core behaviour ----------------------------------------------------------


func _setup_is_valid() -> bool:
	if _value_cells.size() != SAMPLE_SIZE:
		return false
	for cell in _value_cells:
		if not cell.text.strip_edges().is_valid_float():
			return false
	return true


func _refresh_setup_validation() -> void:
	var valid_count := 0
	for cell in _value_cells:
		var s := cell.text.strip_edges()
		if not s.is_empty() and s.is_valid_float():
			valid_count += 1
		if s.is_empty() or s.is_valid_float():
			if cell.has_theme_color_override("font_color"):
				cell.remove_theme_color_override("font_color")
		else:
			cell.add_theme_color_override("font_color", COLOR_CELL_INVALID)
	_progress_label.text = "%d / %d values" % [valid_count, SAMPLE_SIZE]
	_start_button.disabled = valid_count != SAMPLE_SIZE
	if _running:
		_start_button.text = "[+] ADD TABLE %d" % (_reference_tables.size() + 1)
	else:
		_start_button.text = "START EXPERIMENT"
	_apply_edit_button.visible = _grid_edit_kind != "none"
	if _grid_edit_kind == "session":
		_apply_edit_button.text = "APPLY"
		_apply_edit_button.tooltip_text = "Write the edited values back to '%s'" % _table_display_name(_grid_edit_index)
	elif _grid_edit_kind == "library":
		_apply_edit_button.text = "SAVE"
		_apply_edit_button.tooltip_text = "Write the edited values to '%s' in the library file" % _library_display_name(_grid_edit_index)


func _start_experiment() -> void:
	if not _setup_is_valid() or _running:
		return
	var table := _read_grid_values()
	_reference_tables = [table]
	_table_names = [_pending_table_name()]
	_active_table_index = 0
	_reference_values = table
	_rolling = RollingSample.new(_reference_values, SAMPLE_SIZE)
	_running = true
	_roll_count = 0
	_favor = 50.0
	_favor_value_label.text = "%.3f" % _favor
	_grid_edit_kind = "none"
	_grid_edit_index = -1
	_table_name_edit.text = ""
	_set_setup_panel_visible(false)
	_run_panel.visible = true
	for r in _switch_rules:
		r["fired"] = false
	_refresh_table_options()
	_dump_reference_text = _reference_summary_text()
	_update_dump_label(get_current_values())
	_last_action_label.text = "Started: current sample is an exact copy of the reference (t should be ~0)."
	_roll_input.grab_focus()
	_update_experiment_display()


func _read_grid_values() -> Array[float]:
	var values: Array[float] = []
	for cell in _value_cells:
		values.append(cell.text.strip_edges().to_float())
	return values


## Run-phase "[+] ADD AS TABLE N" confirm: stores the grid contents as a new
## reference table and hides the entry grid again.
func _add_table_from_grid() -> void:
	if not _running:
		return
	if not _setup_is_valid():
		_last_action_label.text = "Cannot add table: the grid does not hold 30 valid values."
		return
	var values := _read_grid_values()
	add_reference_table(values, _table_name_edit.text)
	_table_name_edit.text = ""
	_set_setup_panel_visible(false)


func _reference_summary_text() -> String:
	if _active_table_index < 0:
		return "Reference (fixed): "
	return "Reference (fixed) - %s: %s" % [_table_display_name(_active_table_index), _join_numbers(_reference_values)]


## Refreshes the combined data dump: reference line plus rolling window line.
func _update_dump_label(current: Array) -> void:
	_dump_label.text = "%s\nCurrent window (oldest -> newest): %s" % [_dump_reference_text, _join_numbers(current)]


func _refresh_table_options() -> void:
	_table_option.clear()
	for i in _reference_tables.size():
		_table_option.add_item(_table_display_name(i))
	if _active_table_index >= 0 and _active_table_index < _reference_tables.size():
		_table_option.select(_active_table_index)
	_rebuild_rules_editor()
	_rebuild_tables_editor()


func _update_experiment_display() -> void:
	var current := get_current_values()
	_last_result = StatisticsAnalyzer.welch_two_sample_t_test(_reference_values, current)

	var t: float = _last_result["t"]
	_t_value_label.text = _format_t(t)
	_t_interpretation_label.text = _interpret_t(t)
	var t_color := COLOR_T_NEUTRAL
	if not is_nan(t):
		if t > 0.0:
			t_color = COLOR_T_POSITIVE
		elif t < 0.0:
			t_color = COLOR_T_NEGATIVE
	_t_value_label.add_theme_color_override("font_color", t_color)

	_ref_mean_label.text = _format_stat(_last_result["mean_reference"])
	_cur_mean_label.text = _format_stat(_last_result["mean_current"])
	_diff_label.text = _format_signed(_last_result["mean_diff"])
	_p_label.text = _format_p(_last_result["p_two_tailed"])
	_ref_sd_label.text = _format_stat(sqrt(float(_last_result["var_reference"])))
	_cur_sd_label.text = _format_stat(sqrt(float(_last_result["var_current"])))
	_se_label.text = _format_stat(_last_result["se"])
	_df_label.text = _format_df(_last_result["df"])

	_sample_size_label.text = "Sample size: %d / %d" % [_rolling.size(), SAMPLE_SIZE]
	_roll_count_label.text = "Rolls since start: %d" % _roll_count
	_update_dump_label(current)

	# Shared axis so both graphs stay comparable: always cover -10..10 and
	# extend only if data goes beyond it.
	var axis_min := DEFAULT_AXIS_MIN
	var axis_max := DEFAULT_AXIS_MAX
	for v in _reference_values:
		axis_min = mini(axis_min, int(floorf(v)))
		axis_max = maxi(axis_max, int(ceilf(v)))
	for v in current:
		axis_min = mini(axis_min, int(floorf(v)))
		axis_max = maxi(axis_max, int(ceilf(v)))

	var shared_max := 1
	for c in StatisticsAnalyzer.frequency_counts(_reference_values, axis_min, axis_max):
		shared_max = maxi(shared_max, int(c))
	for c in StatisticsAnalyzer.frequency_counts(current, axis_min, axis_max):
		shared_max = maxi(shared_max, int(c))

	_ref_histogram.set_axis_range(axis_min, axis_max)
	_ref_histogram.set_shared_max_frequency(shared_max)
	_ref_histogram.set_data(_reference_values, _last_result["mean_reference"])
	_cur_histogram.set_axis_range(axis_min, axis_max)
	_cur_histogram.set_shared_max_frequency(shared_max)
	_cur_histogram.set_data(current, _last_result["mean_current"])


# --- Formatting helpers ------------------------------------------------------


func _format_number(value: float) -> String:
	if is_nan(value):
		return "N/A"
	if is_inf(value):
		return "+INF" if value > 0.0 else "-INF"
	if is_equal_approx(value, roundf(value)) and absf(value) < 1e9:
		return str(int(roundf(value)))
	return String.num(value, 3)


func _format_stat(value: float) -> String:
	if is_nan(value):
		return "N/A"
	return "%.3f" % value


func _format_signed(value: float) -> String:
	if is_nan(value):
		return "N/A"
	if is_inf(value):
		return _format_t(value)
	return "%+.3f" % value


func _format_t(value: float) -> String:
	if is_nan(value):
		return "N/A"
	if is_inf(value):
		return "+INF" if value > 0.0 else "-INF"
	return "%+.3f" % value


func _format_df(value: float) -> String:
	if is_nan(value):
		return "N/A"
	if is_inf(value):
		return "inf"
	return "%.1f" % value


func _format_p(value: float) -> String:
	if is_nan(value):
		return "N/A"
	if value < 0.00005:
		return "< 0.0001"
	return "%.4f" % value


func _interpret_t(t: float) -> String:
	if is_nan(t):
		return "No valid comparison yet."
	if is_inf(t):
		return "Degenerate: both samples constant with different means."
	if t == 0.0:
		return "t = 0: current mean is at the reference mean."
	if t > 0.0:
		return "Positive t: current mean is ABOVE the reference mean."
	return "Negative t: current mean is BELOW the reference mean."


func _join_numbers(values: Array) -> String:
	var parts := PackedStringArray()
	for v in values:
		parts.append(_format_number(float(v)))
	return ", ".join(parts)


# --- Optional command line demo / screenshot ---------------------------------


## Convenience for quick demo or automated screenshot runs; harmless when the
## flags are absent (which is the normal case).
func _handle_command_line_demo() -> void:
	var args := OS.get_cmdline_user_args()
	var want_demo := args.has("--statistics-test-demo")
	var screenshot_path := ""
	var setup_screenshot_path := ""
	for a in args:
		if a.begins_with("--statistics-test-screenshot="):
			screenshot_path = a.substr(a.find("=") + 1)
		elif a.begins_with("--statistics-test-screenshot-setup="):
			setup_screenshot_path = a.substr(a.find("=") + 1)
	if not want_demo and screenshot_path.is_empty() and setup_screenshot_path.is_empty():
		return
	if not setup_screenshot_path.is_empty():
		# Fill the reference cells but stay in the setup phase.
		set_reference_values(DEMO_REFERENCE_VALUES)
		await _capture_screenshot_and_quit(setup_screenshot_path)
		return
	if not _running:
		set_reference_values(DEMO_REFERENCE_VALUES)
		start_experiment()
	if want_demo:
		for v in DEMO_ROLLS:
			submit_value(float(v))
		add_current_t_to_favor()
		var second_table: Array[float] = []
		for v in DEMO_REFERENCE_VALUES:
			second_table.append(float(v) + 2.0)
		add_reference_table(second_table)
		# Demonstrate weighted auto generation around +8 with a favor-driven
		# rule chain: favor >= 50 -> Table 1, favor >= 52 -> Table 3.
		var third_table: Array[float] = []
		for v in DEMO_REFERENCE_VALUES:
			third_table.append(float(v) + 4.0)
		add_reference_table(third_table)
		_gen_weighted_check.button_pressed = true
		_gen_center_spin.value = 8.0
		_gen_spread_spin.value = 3.0
		set_switch_rules([
			{"above": true, "threshold": 50.0, "target": 0},
			{"above": true, "threshold": 52.0, "target": 2},
		])
		start_auto()
		for i in 10:
			_on_auto_timer_timeout()
		stop_auto()
	if not screenshot_path.is_empty():
		await _capture_screenshot(screenshot_path)
		if _switch_editor != null:
			_open_centered_popup(_switch_editor, Vector2i(680, 300))
			await _capture_screenshot(screenshot_path.get_basename() + "_editor.png")
			_switch_editor.hide()
		if _tables_popup != null:
			_open_centered_popup(_tables_popup, Vector2i(680, 340))
			await _capture_screenshot(screenshot_path.get_basename() + "_tables.png")
			_tables_popup.hide()
		# Show the entry grid open during a run (create/edit state).
		edit_session_table(0)
		await _capture_screenshot(screenshot_path.get_basename() + "_grid.png")
		# Apply the edit back and confirm the middle rows return.
		_table_name_edit.text = "Table 1"
		_apply_grid_to_target()
		await _capture_screenshot(screenshot_path.get_basename() + "_afteradd.png")
		get_tree().quit()


func _capture_screenshot_and_quit(path: String) -> void:
	await _capture_screenshot(path)
	get_tree().quit()


func _capture_screenshot(path: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("Statistics Test screenshot -> %s (error code %d)" % [path, error])
