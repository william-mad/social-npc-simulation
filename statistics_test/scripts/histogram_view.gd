extends Control
## Custom-drawn discrete frequency histogram for the Statistics Test tool.
##
## One bar per integer value across [axis_min, axis_max] (bar for the frequency
## of each integer; non-integer inputs bin at their nearest integer). The tool
## gives both histograms the same axis range and the same shared y scale so
## they stay directly comparable. Data changes call queue_redraw(); all drawing
## happens in _draw() with draw_rect / draw_line / draw_string.

const StatisticsAnalyzer := preload("res://statistics_test/scripts/statistics_analyzer.gd")

const COLOR_BACKGROUND := Color(0.09, 0.1, 0.13)
const COLOR_BORDER := Color(0.28, 0.3, 0.36)
const COLOR_GRID := Color(1, 1, 1, 0.07)
const COLOR_AXIS := Color(0.55, 0.57, 0.62)
const COLOR_TEXT := Color(0.88, 0.89, 0.92)
const COLOR_TEXT_DIM := Color(0.62, 0.64, 0.7)
const COLOR_MEAN_LINE := Color(1.0, 0.83, 0.35, 0.9)

var title := "DISTRIBUTION"
var bar_color := Color(0.4, 0.62, 0.95)
var axis_min := -10
var axis_max := 10
## When > 0, all graphs use this as their y-scale maximum so two histograms
## are directly comparable. When 0, this graph scales to its own maximum.
var shared_max_frequency := 0

var _values: Array = []
var _mean_value := NAN


func _init() -> void:
	clip_contents = true
	custom_minimum_size = Vector2(0, 100)


func set_data(values, mean_value := NAN) -> void:
	_values = values
	_mean_value = mean_value
	queue_redraw()


func set_axis_range(min_value: int, max_value: int) -> void:
	var lo := mini(min_value, max_value)
	var hi := maxi(min_value, max_value)
	if lo == axis_min and hi == axis_max:
		return
	axis_min = lo
	axis_max = hi
	queue_redraw()


func set_shared_max_frequency(max_frequency: int) -> void:
	if max_frequency == shared_max_frequency:
		return
	shared_max_frequency = max_frequency
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var base_size := maxi(10, get_theme_default_font_size())
	var tick_size := maxi(9, base_size - 5)
	var count_size := maxi(9, base_size - 4)

	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, COLOR_BACKGROUND)

	# Plot layout: room for the title on top, y labels left, x labels below.
	var pad_left := 34.0
	var pad_right := 6.0
	var pad_top := base_size + 10.0
	var pad_bottom := tick_size + 8.0
	var plot := Rect2(
			Vector2(pad_left, pad_top),
			Vector2(maxf(10.0, size.x - pad_left - pad_right),
					maxf(10.0, size.y - pad_top - pad_bottom)))
	var plot_bottom := plot.position.y + plot.size.y

	var counts := StatisticsAnalyzer.frequency_counts(_values, axis_min, axis_max)
	var own_max := 1
	for c in counts:
		own_max = maxi(own_max, int(c))
	var max_freq := shared_max_frequency if shared_max_frequency > 0 else own_max
	max_freq = maxi(1, max_freq)

	var bin_count := axis_max - axis_min + 1
	var bin_w := plot.size.x / bin_count

	# Horizontal grid lines and y labels (frequency counts).
	var y_step := 1
	if max_freq > 6:
		y_step = int(ceil(max_freq / 5.0))
	var f := 0
	while f <= max_freq:
		var y := plot_bottom - (float(f) / max_freq) * plot.size.y
		if f > 0:
			draw_line(Vector2(plot.position.x, y), Vector2(plot.position.x + plot.size.x, y), COLOR_GRID, 1.0)
		draw_string(font, Vector2(2.0, y + tick_size * 0.5), str(f),
				HORIZONTAL_ALIGNMENT_LEFT, pad_left - 4.0, tick_size, COLOR_TEXT_DIM)
		f += y_step

	# Bars, one per integer value, with the count on top.
	var bar_w := maxf(1.0, bin_w - 2.0)
	for i in bin_count:
		var freq := int(counts[i])
		if freq <= 0:
			continue
		var x := plot.position.x + i * bin_w + 1.0
		var h := (float(freq) / max_freq) * plot.size.y
		draw_rect(Rect2(Vector2(x, plot_bottom - h), Vector2(bar_w, h)), bar_color)
		if bin_w >= 15.0:
			draw_string(font, Vector2(x, plot_bottom - h - 3.0), str(freq),
					HORIZONTAL_ALIGNMENT_CENTER, bin_w, count_size, COLOR_TEXT)

	# X axis line and value labels.
	draw_line(Vector2(plot.position.x, plot_bottom), Vector2(plot.position.x + plot.size.x, plot_bottom), COLOR_AXIS, 1.0)
	var label_every := 1 if bin_w >= 16.0 else 2
	for i in bin_count:
		var value := axis_min + i
		if value % label_every != 0:
			continue
		var cx := plot.position.x + (i + 0.5) * bin_w
		var col := COLOR_TEXT if value == 0 else COLOR_TEXT_DIM
		draw_string(font, Vector2(cx - bin_w, plot_bottom + tick_size + 2.0), str(value),
				HORIZONTAL_ALIGNMENT_CENTER, bin_w * 2.0, tick_size, col)

	# Dashed vertical marker at the sample mean.
	if not is_nan(_mean_value):
		var mx := clampf(plot.position.x + (_mean_value - axis_min + 0.5) * bin_w,
				plot.position.x, plot.position.x + plot.size.x)
		var ly := plot.position.y
		while ly < plot_bottom:
			var seg := minf(4.0, plot_bottom - ly)
			draw_line(Vector2(mx, ly), Vector2(mx, ly + seg), COLOR_MEAN_LINE, 1.0)
			ly += 7.0

	# Border, title, and summary info.
	draw_rect(rect, COLOR_BORDER, false, 1.0)
	draw_string(font, Vector2(8.0, base_size + 2.0), title,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 16.0, base_size, COLOR_TEXT)
	if not is_nan(_mean_value):
		var info := "n=%d  mean=%+.2f" % [_values.size(), _mean_value]
		draw_string(font, Vector2(8.0, base_size + 2.0), info,
				HORIZONTAL_ALIGNMENT_RIGHT, size.x - 16.0, maxi(9, base_size - 2), COLOR_TEXT_DIM)
