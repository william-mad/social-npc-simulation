class_name Food
extends Node2D

signal depleted(food: Food)

@export var amount: float = 50.0:
	set(v):
		amount = maxf(v, 0.0)
		queue_redraw()

@export var max_amount: float = 50.0
@export var radius: float = 14.0

var is_depleted: bool = false

func _ready() -> void:
	add_to_group("food")
	if max_amount < amount:
		max_amount = amount

	# Pop-in drop animation
	scale = Vector2.ZERO
	modulate.a = 0.0
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

## Consumes up to `requested_amount` of food. Returns the actual amount consumed.
func consume(requested_amount: float) -> float:
	if is_depleted or amount <= 0.0:
		return 0.0

	var spent: float = minf(requested_amount, amount)
	amount -= spent
	queue_redraw()

	if amount <= 0.001:
		is_depleted = true
		remove_from_group("food")
		depleted.emit(self)
		# Smooth pop-out shrink
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(self, "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(self, "modulate:a", 0.0, 0.22)
		tw.chain().tween_callback(queue_free)

	return spent

func _draw() -> void:
	if is_depleted:
		return

	var ratio = clampf(amount / max_amount, 0.0, 1.0) if max_amount > 0.0 else 0.0

	# 1. Dark shadow / plate rim
	draw_circle(Vector2.ZERO, radius + 3.0, Color(0.08, 0.1, 0.13, 0.8))
	draw_circle(Vector2.ZERO, radius + 1.0, Color(0.24, 0.28, 0.35, 0.9))

	# 2. Food base plate (depleted background)
	draw_circle(Vector2.ZERO, radius, Color(0.18, 0.15, 0.12, 1.0))

	# 3. Remaining food fill (vibrant golden-orange)
	var food_col = Color(0.98, 0.64, 0.14)
	if ratio > 0.01:
		# Dynamic pie wedge or scaled circle
		draw_circle(Vector2.ZERO, radius * sqrt(ratio), food_col)

	# 4. Food inner crumb details / platter rim
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.82, 0.45, 0.95), 1.5, true)
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.95, 0.8, 0.9))

	# 5. Food amount label pill floating above
	var font = ThemeDB.fallback_font
	if font != null:
		var text = "Food: %d" % int(round(amount))
		var font_size = 10
		var sz = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pill_pos = Vector2(-sz.x * 0.5 - 4.0, -radius - 17.0)
		var pill_rect = Rect2(pill_pos, Vector2(sz.x + 8.0, 14.0))

		draw_rect(pill_rect, Color(0.08, 0.1, 0.13, 0.92), true)
		draw_rect(pill_rect, Color(0.98, 0.64, 0.14, 0.8), false, 1.0)

		var text_pos = Vector2(pill_pos.x + 4.0, pill_pos.y + 11.0)
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
