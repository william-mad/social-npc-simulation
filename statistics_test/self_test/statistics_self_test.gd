extends SceneTree
## Headless self-test for the Statistics Test tool.
##
## Run from the project root (no game scene is started, nothing is modified):
##   godot --headless -s res://statistics_test/self_test/statistics_self_test.gd
##
## Exits with code 0 when every check passes, 1 otherwise. The p-value anchors
## and the Welch scenario were generated and cross-checked against
## scipy.stats (Python 3.12, scipy 1.18) to ~1e-9.

const StatisticsAnalyzer := preload("res://statistics_test/scripts/statistics_analyzer.gd")
const RollingSample := preload("res://statistics_test/scripts/rolling_sample.gd")

const DEMO_REFERENCE: Array[int] = [
	3, -1, 4, 2, 0, 5, -3, 1, 4, 2,
	-2, 6, 0, 3, 1, -4, 2, 5, -1, 0,
	3, -2, 4, 1, 2, -3, 5, 0, 2, 1,
]

var _checks := 0
var _failures := 0


func _initialize() -> void:
	print("=== Statistics Test self-test ===")
	_test_basic_statistics()
	_test_p_value_anchors()
	_test_welch_scenario()
	_test_degenerate_cases()
	_test_rolling_sample()
	_test_frequency_counts()
	_test_weighted_random()
	# In -s script mode the scene's _ready() runs on the first frame, so the
	# scene integration checks are deferred until then.
	process_frame.connect(_run_scene_integration, CONNECT_ONE_SHOT)


func _run_scene_integration() -> void:
	_test_scene_integration()
	if _failures == 0:
		print("STATISTICS SELF TEST: ALL %d CHECKS PASSED" % _checks)
		quit(0)
	else:
		print("STATISTICS SELF TEST: %d of %d CHECKS FAILED" % [_failures, _checks])
		quit(1)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failures += 1
		print("  [FAIL] %s" % label)


func _close(a: float, b: float, tolerance := 1e-9) -> bool:
	if is_nan(a) and is_nan(b):
		return true
	return absf(a - b) <= tolerance


func _test_basic_statistics() -> void:
	print("- basic statistics")
	_check(_close(StatisticsAnalyzer.mean([1, 2, 3, 4]), 2.5), "mean([1,2,3,4]) == 2.5")
	_check(_close(StatisticsAnalyzer.sample_variance([1, 2, 3, 4]), 5.0 / 3.0), "sample variance uses n - 1")
	_check(_close(StatisticsAnalyzer.sample_variance([7.0]), 0.0), "variance of a single value == 0")
	_check(_close(StatisticsAnalyzer.sample_std_dev([2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]), sqrt(32.0 / 7.0)), "std dev of known dataset")


func _test_p_value_anchors() -> void:
	print("- t-distribution p-value anchors (scipy-verified)")
	_check(_close(StatisticsAnalyzer.two_tailed_p_value(0.0, 30.0), 1.0), "p(t=0, df=30) == 1")
	_check(_close(StatisticsAnalyzer.two_tailed_p_value(1.0, 29.0), 0.325581988016), "p(t=1, df=29)")
	_check(_close(StatisticsAnalyzer.two_tailed_p_value(2.0, 30.0), 0.054625044963), "p(t=2, df=30)")
	_check(_close(StatisticsAnalyzer.two_tailed_p_value(2.5, 12.4), 0.027356835179), "p(t=2.5, df=12.4)")
	_check(_close(StatisticsAnalyzer.two_tailed_p_value(3.1, 57.9), 0.002986716002), "p(t=3.1, df=57.9)")


func _test_welch_scenario() -> void:
	print("- Welch two-sample t-test vs scipy reference scenario")
	var reference: Array[float] = []
	for v in DEMO_REFERENCE:
		reference.append(float(v))
	var current := reference.duplicate()
	for v in [7, -8, 9, -10, 6, -5, 8, 2]:
		current.pop_front()
		current.append(float(v))
	var result := StatisticsAnalyzer.welch_two_sample_t_test(reference, current)
	_check(result["valid"], "result is valid")
	_check(_close(result["mean_reference"], 1.333333333333), "reference mean == 1.333333...")
	_check(_close(result["mean_current"], 1.266666666667), "current mean == 1.266666...")
	_check(_close(result["t"], -0.071116463969), "t statistic matches scipy (sign: current below reference)")
	_check(_close(result["df"], 47.320555492637), "Welch df matches scipy")
	_check(_close(result["p_two_tailed"], 0.943604781287), "two-tailed p matches scipy")
	var flipped := StatisticsAnalyzer.welch_two_sample_t_test(current, reference)
	_check(_close(flipped["t"], 0.071116463969), "t sign flips with argument order")
	var above := StatisticsAnalyzer.welch_two_sample_t_test([0.0, 1.0, 2.0, 3.0], [10.0, 11.0, 12.0, 13.0])
	_check(above["t"] > 0.0, "positive t when current mean is above reference mean")


func _test_degenerate_cases() -> void:
	print("- degenerate cases")
	var constant_a: Array[float] = [5.0, 5.0, 5.0]
	var equal := StatisticsAnalyzer.welch_two_sample_t_test(constant_a, constant_a.duplicate())
	_check(equal["valid"] and equal["t"] == 0.0 and _close(equal["p_two_tailed"], 1.0), "constant equal samples -> t = 0, p = 1")
	var constant_b: Array[float] = [-2.0, -2.0, -2.0]
	var diff := StatisticsAnalyzer.welch_two_sample_t_test(constant_a, constant_b)
	_check(diff["valid"] and is_inf(diff["t"]) and diff["t"] < 0.0 and diff["p_two_tailed"] == 0.0, "constant different samples -> signed infinity, p = 0")
	var swapped := StatisticsAnalyzer.welch_two_sample_t_test(constant_b, constant_a)
	_check(is_inf(swapped["t"]) and swapped["t"] > 0.0, "sign flips with sample order")
	var too_small: Array[float] = [1.0]
	var bad := StatisticsAnalyzer.welch_two_sample_t_test(too_small, constant_a)
	_check(not bad["valid"], "samples with fewer than 2 values are rejected")


func _test_rolling_sample() -> void:
	print("- rolling window")
	var window := RollingSample.new([1, 2, 3, 4, 5], 5)
	_check(window.size() == 5 and window.is_full(), "init keeps an exact copy, size 5")
	var snap := window.snapshot()
	_check(_close(snap[0], 1.0) and _close(snap[4], 5.0), "copy preserves order (oldest first)")
	snap[0] = 99.0
	_check(_close(window.snapshot()[0], 1.0), "snapshot is a defensive copy")
	var evicted := window.push(6.0)
	_check(_close(evicted, 1.0), "push onto full window evicts the oldest value")
	var after := window.snapshot()
	_check(_close(after[0], 2.0) and _close(after[4], 6.0) and window.size() == 5, "window slides correctly and stays at 5")
	var growing := RollingSample.new([], 3)
	growing.push(1.0)
	_check(_close(growing.push(2.0), 2.0), "push before full returns the pushed value")
	_check(growing.size() == 2 and not growing.is_full(), "window grows until full")


func _test_frequency_counts() -> void:
	print("- frequency counts")
	var counts := StatisticsAnalyzer.frequency_counts([1, 1, 2, -10, 11, 2.6], -10, 10)
	_check(counts.size() == 21, "bin array covers the axis range")
	_check(counts[0] == 1, "-10 binned once")
	_check(counts[11] == 2, "value 1 binned twice")
	_check(counts[12] == 1, "value 2 binned once")
	_check(counts[13] == 1, "2.6 rounds into bin 3")
	_check(counts[20] == 0, "value 11 ignored (outside axis range)")


func _test_weighted_random() -> void:
	print("- weighted random generator")
	seed(12345)
	var center := 3
	var spread := 4.0
	var draws := 4000
	var total := 0.0
	var counts := {}
	var in_range := true
	for i in draws:
		var v := StatisticsAnalyzer.random_weighted_int(-10, 10, center, spread)
		total += v
		if v < -10 or v > 10:
			in_range = false
		counts[v] = int(counts.get(v, 0)) + 1
	var sample_mean := total / draws
	_check(in_range, "weighted values stay in range")
	_check(absf(sample_mean - center) < 0.15, "weighted sample mean lands on the center (%.3f over %d draws)" % [sample_mean, draws])
	_check(int(counts.get(center, 0)) > int(counts.get(center + 1, 0)), "weight decays with distance (center > center+1)")
	_check(int(counts.get(center + 1, 0)) > int(counts.get(center + 2, 0)), "weight decays with distance (center+1 > center+2)")
	_check(StatisticsAnalyzer.random_weighted_int(-10, 10, 7, 0.0) == 7, "spread 0 always returns the center")
	_check(StatisticsAnalyzer.random_weighted_int(0, 5, 9, 2.0) == 5, "center outside the range is clamped into it")


func _test_scene_integration() -> void:
	print("- scene integration (headless)")
	var packed: PackedScene = load("res://statistics_test/scenes/statistics_test.tscn")
	_check(packed != null, "scene loads")
	if packed == null:
		return
	var tool_ui = packed.instantiate()
	root.add_child(tool_ui)

	_check(tool_ui.set_reference_values(DEMO_REFERENCE), "reference fill reports 30 valid values")
	tool_ui._table_name_edit.text = "Alpha"
	_check(tool_ui.start_experiment(), "experiment starts once 30 values are entered")
	_check(tool_ui.is_running(), "running flag is set")
	_check(tool_ui._table_names[0] == "Alpha", "session table uses the name from the name field")
	_check(tool_ui._table_option.get_item_text(0) == "Alpha", "reference dropdown shows the table name")

	var initial: Dictionary = tool_ui.get_last_result()
	_check(initial["valid"] and initial["t"] == 0.0, "identical initial samples give t == 0")
	_check(_close(initial["p_two_tailed"], 1.0), "initial p-value == 1")

	var rolls := [8.0, 8.0, 9.0, -6.0, 10.0]
	for v in rolls:
		_check(tool_ui.submit_value(v), "roll %s accepted" % v)

	var current: Array[float] = tool_ui.get_current_values()
	_check(current.size() == 30, "window size stays at 30")
	var expected: Array[float] = []
	for i in range(5, 30):
		expected.append(float(DEMO_REFERENCE[i]))
	for v in rolls:
		expected.append(v)
	var order_ok := true
	for i in 30:
		if not _close(current[i], expected[i]):
			order_ok = false
	_check(order_ok, "window == reference[5..29] + new rolls, in order")

	var reference_after: Array[float] = tool_ui.get_reference_values()
	var ref_ok := true
	for i in 30:
		if not _close(reference_after[i], float(DEMO_REFERENCE[i])):
			ref_ok = false
	_check(ref_ok, "reference sample unchanged by rolls")

	var result: Dictionary = tool_ui.get_last_result()
	_check(result["valid"] and result["t"] > 0.0, "t positive after above-reference rolls")

	# Favor counter.
	_check(_close(tool_ui.get_favor(), 50.0), "favor starts at 50")
	_check(tool_ui.submit_value(9.0), "roll accepted before favor test")
	var favor_t: float = tool_ui.get_last_result()["t"]
	var favor_after: float = tool_ui.add_current_t_to_favor()
	_check(_close(favor_after, 50.0 + favor_t), "favor accumulates the current t value")
	_check(_close(tool_ui.get_favor(), 50.0 + favor_t), "favor getter matches after add")
	_check(tool_ui._favor_value_label.text == "%.3f" % favor_after, "favor label shows the formatted value")

	_check(not tool_ui.submit_next_value("abc"), "invalid text rejected")
	_check(tool_ui.get_current_values().size() == 30, "state unchanged after invalid input")

	tool_ui.reset_window()
	var reset_current: Array[float] = tool_ui.get_current_values()
	var reset_ok := true
	for i in 30:
		if not _close(reset_current[i], float(DEMO_REFERENCE[i])):
			reset_ok = false
	_check(reset_ok, "reset window restores the exact reference copy")
	_check(_close(tool_ui.get_last_result()["t"], 0.0), "reset window puts t back to 0")

	# Multiple reference tables.
	_check(tool_ui.get_reference_table_count() == 1, "start creates reference Table 1")
	_check(tool_ui.get_active_reference_table_index() == 0, "Table 1 is active after start")
	var window_before: Array[float] = tool_ui.get_current_values()
	var table_two: Array[float] = []
	for v in DEMO_REFERENCE:
		table_two.append(float(v) + 2.0)
	_check(not tool_ui.add_reference_table([1.0, 2.0]), "adding a table without 30 values is rejected")
	_check(tool_ui.add_reference_table(table_two), "second reference table added")
	_check(tool_ui.get_reference_table_count() == 2, "both tables are stored")
	_check(tool_ui.get_active_reference_table_index() == 1, "new table becomes the active reference")
	var table_two_ok := true
	var active_values: Array[float] = tool_ui.get_reference_values()
	for i in 30:
		if not _close(active_values[i], float(DEMO_REFERENCE[i]) + 2.0):
			table_two_ok = false
	_check(table_two_ok, "active reference values are the new table's values")
	var window_after: Array[float] = tool_ui.get_current_values()
	var window_kept := true
	for i in 30:
		if not _close(window_after[i], window_before[i]):
			window_kept = false
	_check(window_kept, "rolling window preserved when a reference table is added")
	var t_vs_two: float = tool_ui.get_last_result()["t"]
	_check(not is_nan(t_vs_two) and t_vs_two < 0.0, "t recomputed against the new reference (current below it)")
	var check_result: Dictionary = StatisticsAnalyzer.welch_two_sample_t_test(
			tool_ui.get_reference_values(), tool_ui.get_current_values())
	var expected_t_text := "%+.3f" % check_result["t"]
	_check(tool_ui._t_value_label.text == expected_t_text, "t label shows the formatted t for the active reference")
	_check(tool_ui.select_reference_table(0), "switch back to Table 1")
	_check(tool_ui.get_active_reference_table_index() == 0, "Table 1 active again")
	var switched_ok := true
	var ref_after_switch: Array[float] = tool_ui.get_reference_values()
	for i in 30:
		if not _close(ref_after_switch[i], float(DEMO_REFERENCE[i])):
			switched_ok = false
	_check(switched_ok, "reference values follow the selected table")
	var window_after_switch: Array[float] = tool_ui.get_current_values()
	var window_kept_two := true
	for i in 30:
		if not _close(window_after_switch[i], window_before[i]):
			window_kept_two = false
	_check(window_kept_two, "rolling window still preserved after switching tables")
	_check(not tool_ui.select_reference_table(5), "invalid table index rejected")
	_check(_close(tool_ui.get_reference_table(1)[10], float(DEMO_REFERENCE[10]) + 2.0), "stored table keeps its own values")

	# Random generation settings.
	_check(tool_ui._gen_weighted_check.button_pressed, "weighted generation is enabled by default")
	tool_ui._gen_center_spin.value = -6.0
	tool_ui._gen_spread_spin.value = 0.0
	_check(tool_ui.generate_random_value() == -6, "spread 0 generates the center value")
	tool_ui._gen_spread_spin.value = 5.0
	tool_ui._gen_weighted_check.button_pressed = false
	var uniform_value: int = tool_ui.generate_random_value()
	_check(uniform_value >= -10 and uniform_value <= 10, "uniform generation stays in range")
	tool_ui._gen_weighted_check.button_pressed = true

	# Auto generation: each value's t is added to Favor before the next one.
	var _favor_before_auto: float = tool_ui.get_favor()
	var window_pre_auto: Array[float] = tool_ui.get_current_values()
	tool_ui.start_auto()
	_check(tool_ui._auto_running, "auto mode starts")
	_check(tool_ui._auto_button.text == "Auto: stop", "auto button shows stop while running")
	var favor_expected: float = tool_ui.get_favor()
	for i in 3:
		tool_ui._on_auto_timer_timeout()
		var window_after_tick: Array[float] = tool_ui.get_current_values()
		favor_expected += float(StatisticsAnalyzer.welch_two_sample_t_test(
				tool_ui.get_reference_values(), window_after_tick)["t"])
	_check(_close(tool_ui.get_favor(), favor_expected), "each auto value adds its t to favor before the next generation")
	var window_post_auto: Array[float] = tool_ui.get_current_values()
	var advanced := true
	for i in 27:
		if not _close(window_post_auto[i], window_pre_auto[i + 3]):
			advanced = false
	_check(advanced, "three auto ticks slide the window by three")
	tool_ui.stop_auto()
	_check(not tool_ui._auto_running and tool_ui._auto_button.text == "Auto: start", "auto mode stops")

	# Favor-driven auto-switch rules (single rule first).
	tool_ui.set_switch_rules([
		{"above": true, "threshold": tool_ui.get_favor() + 5.0, "target": 1},
	])
	tool_ui.submit_value(9.0)
	tool_ui.add_current_t_to_favor()
	_check(tool_ui.get_active_reference_table_index() == 0, "rule stays armed before the threshold is crossed")
	_check(not tool_ui._switch_rules[0]["fired"], "rule not marked fired while below the threshold")

	var favor_before_rule: float = tool_ui.get_favor()
	tool_ui.set_switch_rules([
		{"above": true, "threshold": favor_before_rule - 1.0, "target": 1},
	])
	_check(tool_ui.get_active_reference_table_index() == 1, "rule fires when favor is at or above the threshold")
	_check(tool_ui._switch_rules[0]["fired"], "rule is marked fired after firing")

	var rearmed := false
	for i in 6:
		tool_ui.submit_value(-10.0)
		tool_ui.add_current_t_to_favor()
		if not tool_ui._switch_rules[0]["fired"]:
			rearmed = true
			break
	_check(rearmed, "rule re-arms after favor falls back below the threshold")

	# A ladder of six rules fires in sequence as favor climbs.
	var favor_base: float = tool_ui.get_favor()
	var ladder_targets := [1, 0, 1, 0, 1, 0]
	var ladder := []
	var offsets := [-2.0, -1.0, 1.0, 2.0, 3.0, 4.0]
	for i in 6:
		ladder.append({"above": true, "threshold": favor_base + offsets[i], "target": ladder_targets[i]})
	tool_ui.set_switch_rules(ladder)
	_check(tool_ui._switch_rules.size() == 6, "six ladder rules stored")
	var fired_count := 0
	for r in tool_ui._switch_rules:
		if r["fired"]:
			fired_count += 1
	_check(fired_count == 2, "ladder rules up to the current favor fire at once")
	_check(tool_ui.get_active_reference_table_index() == ladder_targets[1], "highest crossed rule's target becomes the active reference")

	var all_fired := false
	for i in 15:
		tool_ui.submit_value(10.0)
		tool_ui.add_current_t_to_favor()
		fired_count = 0
		for r in tool_ui._switch_rules:
			if r["fired"]:
				fired_count += 1
		if fired_count == 6:
			all_fired = true
			break
	_check(all_fired, "crossing the top threshold fires the last ladder rule")
	_check(tool_ui.get_active_reference_table_index() == ladder_targets[5], "top ladder rule's target ends active")

	tool_ui.set_switch_rules([])
	_check(tool_ui._switch_summary_label.text == "no rules", "summary shows no rules after clearing")

	# Named, saved and editable tables (library file isolated to a temp path).
	tool_ui._library_path = "res://statistics_test/self_test_tmp_tables.json"
	tool_ui._saved_tables.clear()
	_check(tool_ui._table_names[0] == "Alpha", "session table still named Alpha before library tests")

	var library_entry := {"name": "Saved one", "values": Array([])}
	var saved_values: Array[float] = []
	for v in DEMO_REFERENCE:
		saved_values.append(float(v) - 5.0)
	library_entry["values"] = saved_values
	tool_ui._saved_tables.append(library_entry)
	_check(tool_ui._save_library_to_file(), "library file written")
	_check(FileAccess.file_exists(tool_ui._library_path), "library file exists on disk")
	tool_ui._saved_tables.clear()
	tool_ui._load_library_from_file()
	_check(tool_ui._saved_tables.size() == 1 and tool_ui._saved_tables[0]["name"] == "Saved one", "library round-trips through the file")

	# Edit a saved library table through the grid apply path.
	tool_ui.edit_library_table(0)
	_check(tool_ui._grid_edit_kind == "library", "grid edit targets the library entry")
	var edited: Array[float] = []
	for v in DEMO_REFERENCE:
		edited.append(float(v) + 1.0)
	tool_ui.set_reference_values(edited)
	tool_ui._table_name_edit.text = "Saved one (edited)"
	tool_ui._apply_grid_to_target()
	_check(_close(tool_ui._saved_tables[0]["values"][0], float(DEMO_REFERENCE[0]) + 1.0), "library edit applies the values")
	_check(tool_ui._saved_tables[0]["name"] == "Saved one (edited)", "library edit applies the name")
	tool_ui._saved_tables.clear()
	tool_ui._load_library_from_file()
	_check(tool_ui._saved_tables[0]["name"] == "Saved one (edited)", "library edit persisted to file")

	# Use a saved table mid-run: added to the session as the active reference.
	var session_count: int = tool_ui._reference_tables.size()
	tool_ui.use_saved_table(0)
	_check(tool_ui._reference_tables.size() == session_count + 1, "using a saved table adds it to the session")
	_check(tool_ui._table_names[tool_ui._table_names.size() - 1] == "Saved one (edited)", "used table keeps its saved name")
	_check(tool_ui.get_active_reference_table_index() == tool_ui._reference_tables.size() - 1, "used table becomes the active reference")

	# Edit a session table through the grid apply path.
	tool_ui.edit_session_table(0)
	_check(tool_ui._grid_edit_kind == "session", "grid edit targets the session table")
	_check(tool_ui._histogram_row.visible, "histograms stay visible while the grid is open")
	_check(not tool_ui._dump_label.visible and not tool_ui._refs_row.visible \
			and not tool_ui._stats_grid.visible and not tool_ui._info_row.visible,
			"secondary rows step aside while the grid is open")
	_check(tool_ui._cancel_edit_button.visible, "cancel button available while editing")
	tool_ui.set_reference_values(DEMO_REFERENCE)
	tool_ui._table_name_edit.text = "Alpha"
	tool_ui._apply_grid_to_target()
	_check(tool_ui._histogram_row.visible and tool_ui._dump_label.visible, "histograms and dump return after applying")
	_check(not tool_ui._cancel_edit_button.visible, "cancel button hidden after applying")
	_check(_close(tool_ui._reference_tables[0][0], float(DEMO_REFERENCE[0])), "session edit applies the values")
	_check(tool_ui._table_names[0] == "Alpha", "session edit applies the name")

	# Adding a table through the grid must restore the compacted rows as well.
	tool_ui._grid_edit_kind = "none"
	var add_values: Array[float] = []
	for v in DEMO_REFERENCE:
		add_values.append(float(v) + 3.0)
	tool_ui.set_reference_values(add_values)
	tool_ui._table_name_edit.text = "Gamma"
	var tables_before_add: int = tool_ui._reference_tables.size()
	tool_ui._add_table_from_grid()
	_check(tool_ui._reference_tables.size() == tables_before_add + 1, "grid add creates the table")
	_check(tool_ui._table_names[tool_ui._table_names.size() - 1] == "Gamma", "grid add uses the name field")
	_check(tool_ui._dump_label.visible and tool_ui._refs_row.visible \
			and tool_ui._stats_grid.visible and tool_ui._info_row.visible,
			"adding a table restores the middle rows")

	# Save a session table into the library by name.
	tool_ui._save_session_table_to_library(0)
	var alpha_saved := false
	for entry in tool_ui._saved_tables:
		if entry["name"] == "Alpha":
			alpha_saved = true
	_check(alpha_saved, "session table saved into the library by name")

	# Delete a session table.
	var tables_before_delete: int = tool_ui._reference_tables.size()
	var delete_ok: bool = tool_ui._delete_session_table(1)
	_check(delete_ok and tool_ui._reference_tables.size() == tables_before_delete - 1, "session table deleted")
	_check(tool_ui._table_names[0] == "Alpha", "names shift with deletion")
	_check(not tool_ui._delete_session_table(-1), "invalid session index rejected")

	# Remove the temporary library file.
	DirAccess.remove_absolute("res://statistics_test/self_test_tmp_tables.json")

	# Setup-phase flow on a fresh instance: Use a saved table, then START.
	var second = packed.instantiate()
	root.add_child(second)
	second._library_path = "res://statistics_test/self_test_tmp_tables.json"
	second._saved_tables.clear()
	second._saved_tables.append({"name": "Starter", "values": Array([])})
	var starter_values: Array[float] = []
	for v in DEMO_REFERENCE:
		starter_values.append(float(v) + 2.0)
	second._saved_tables[0]["values"] = starter_values
	second.use_saved_table(0)
	_check(second._grid_edit_kind == "none", "use during setup leaves new-table mode")
	_check(second.start_experiment(), "experiment starts with a saved table's values")
	_check(second.is_running() and _close(second.get_reference_values()[0], float(DEMO_REFERENCE[0]) + 2.0),
			"started with the saved table's values")
	second.queue_free()

	tool_ui.queue_free()
