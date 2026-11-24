class_name SleepSpot
extends Node2D

signal occupancy_changed(spot: SleepSpot)

@export var max_capacity: int = 2
@export var spot_size: Vector2 = Vector2(112.0, 62.0)

const SLOT_OFFSETS: Array[Vector2] = [
	Vector2(-26.0, 0.0),
	Vector2(26.0, 0.0)
]

# Each entry holds an NPC (claiming or sleeping in this slot) or null
var slots: Array = [null, null]

func _ready() -> void:
	add_to_group("sleep_spots")
	_ensure_slot_array()

	# Pop-in placement animation (matches Food)
	scale = Vector2.ZERO
	modulate.a = 0.0
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

func _exit_tree() -> void:
	for i in range(slots.size()):
		var occupant = slots[i]
		if is_instance_valid(occupant) and occupant.has_method("on_sleep_spot_removed"):
			occupant.on_sleep_spot_removed(self)
		slots[i] = null

func _ensure_slot_array() -> void:
	while slots.size() < max_capacity:
		slots.append(null)
	if slots.size() > max_capacity:
		slots.resize(max_capacity)

## Removes any dead, freed, or no-longer-seeking/sleeping NPCs from slots
func _prune_slots() -> void:
	_ensure_slot_array()
	var changed: bool = false
	for i in range(slots.size()):
		var occupant = slots[i]
		if occupant == null:
			continue
		if not is_instance_valid(occupant) or occupant.is_dead:
			slots[i] = null
			changed = true
			continue
		var valid_state: bool = (
			occupant.target_sleep_spot == self
			and (occupant.current_state == NPC.NPCState.SEEKING_SLEEP_SPOT or occupant.current_state == NPC.NPCState.SLEEPING)
		)
		if not valid_state:
			slots[i] = null
			changed = true
	if changed:
		occupancy_changed.emit(self)
		queue_redraw()

## Returns true if the given NPC already holds a slot here or a free slot exists
func can_accept(npc: NPC) -> bool:
	_prune_slots()
	if npc == null or not is_instance_valid(npc) or npc.is_dead:
		return false
	for occupant in slots:
		if occupant == npc:
			return true
	for occupant in slots:
		if occupant == null:
			return true
	return false

## Reserves a slot for `npc` (or returns its existing slot index). Returns -1 if full.
func reserve_slot(npc: NPC) -> int:
	_prune_slots()
	if npc == null or not is_instance_valid(npc) or npc.is_dead:
		return -1
	for i in range(slots.size()):
		if slots[i] == npc:
			return i
	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = npc
			occupancy_changed.emit(self)
			queue_redraw()
			return i
	return -1

## Releases any slot held by `npc`
func release_slot(npc: NPC) -> void:
	var changed: bool = false
	for i in range(slots.size()):
		if slots[i] == npc:
			slots[i] = null
			changed = true
	if changed:
		occupancy_changed.emit(self)
		queue_redraw()

func get_slot_index(npc: NPC) -> int:
	_prune_slots()
	for i in range(slots.size()):
		if slots[i] == npc:
			return i
	return -1

func get_slot_offset(slot_idx: int) -> Vector2:
	if slot_idx >= 0 and slot_idx < SLOT_OFFSETS.size():
		return SLOT_OFFSETS[slot_idx]
	if max_capacity <= 1:
		return Vector2.ZERO
	var span: float = spot_size.x * 0.48
	var t: float = float(slot_idx) / float(max_capacity - 1)
	return Vector2(lerpf(-span * 0.5, span * 0.5, t), 0.0)

func get_slot_world_position(npc: NPC) -> Vector2:
	var idx: int = get_slot_index(npc)
	if idx >= 0:
		return global_position + get_slot_offset(idx)
	return global_position

func get_sleeping_count() -> int:
	_prune_slots()
	var count: int = 0
	for occupant in slots:
		if occupant != null and occupant.current_state == NPC.NPCState.SLEEPING and occupant.in_sleep_spot:
			count += 1
	return count

func get_claimed_count() -> int:
	_prune_slots()
	var count: int = 0
	for occupant in slots:
		if occupant != null:
			count += 1
	return count

func notify_visual_update() -> void:
	queue_redraw()

func _draw() -> void:
	_ensure_slot_array()
	var half: Vector2 = spot_size * 0.5
	var base_rect: Rect2 = Rect2(-half, spot_size)
	var shadow_rect: Rect2 = Rect2(-half + Vector2(-3.0, -3.0), spot_size + Vector2(6.0, 6.0))

	var sleeping_cnt: int = 0
	var claimed_cnt: int = 0
	for occupant in slots:
		if occupant != null and is_instance_valid(occupant) and not occupant.is_dead:
			claimed_cnt += 1
			if occupant.current_state == NPC.NPCState.SLEEPING and occupant.in_sleep_spot:
				sleeping_cnt += 1

	var sleep_blue: Color = Color(0.25, 0.48, 0.98)

	# 1. Outer shadow & cozy bed frame
	draw_rect(shadow_rect, Color(0.05, 0.07, 0.12, 0.82), true)
	draw_rect(base_rect, Color(0.11, 0.15, 0.25, 0.95), true)

	# Inner blanket mat
	var mat_rect: Rect2 = base_rect.grow(-5.0)
	draw_rect(mat_rect, Color(0.15, 0.21, 0.36, 0.95), true)

	# Border highlights brighter when occupied
	var border_col: Color = sleep_blue.lightened(0.25) if sleeping_cnt > 0 else Color(0.32, 0.46, 0.78, 0.9)
	draw_rect(base_rect, border_col, false, 2.0)

	# Center divider seam between the 2 slots
	draw_line(Vector2(0.0, -half.y + 7.0), Vector2(0.0, half.y - 7.0), Color(0.24, 0.34, 0.56, 0.7), 1.5, true)

	# 2. Draw the 2 individual sleeping berths / pillows
	for i in range(max_capacity):
		var offset: Vector2 = get_slot_offset(i)
		var occupant = slots[i]
		var is_valid_occ: bool = (occupant != null and is_instance_valid(occupant) and not occupant.is_dead)
		var is_sleeping: bool = (is_valid_occ and occupant.current_state == NPC.NPCState.SLEEPING and occupant.in_sleep_spot)

		# Pillow cushion at top of slot
		var pillow_rect: Rect2 = Rect2(offset + Vector2(-15.0, -21.0), Vector2(30.0, 10.0))
		var pillow_col: Color = Color(0.42, 0.58, 0.92, 0.9) if is_sleeping else Color(0.26, 0.34, 0.52, 0.85)
		draw_rect(pillow_rect, pillow_col, true)
		draw_rect(pillow_rect, Color(0.65, 0.78, 1.0, 0.65), false, 1.0)

		# Circular berth outline where NPC rests
		var berth_r: float = 21.0
		if is_sleeping:
			draw_circle(offset, berth_r + 2.0, Color(0.25, 0.48, 0.98, 0.22))
			draw_arc(offset, berth_r, 0.0, TAU, 28, sleep_blue.lightened(0.2), 2.0, true)
		elif is_valid_occ:
			# Reserved by an incoming NPC
			draw_arc(offset, berth_r, 0.0, TAU, 24, Color(0.45, 0.68, 1.0, 0.55), 1.5, true)
		else:
			draw_arc(offset, berth_r, 0.0, TAU, 24, Color(0.28, 0.38, 0.58, 0.5), 1.2, true)

	# 3. Floating status pill above sleep spot
	var font = ThemeDB.fallback_font
	if font != null:
		var text: String = "Sleep: %d/%d" % [sleeping_cnt, max_capacity]
		if claimed_cnt > sleeping_cnt:
			text = "Sleep: %d/%d (+%d)" % [sleeping_cnt, max_capacity, claimed_cnt - sleeping_cnt]
		var font_size: int = 10
		var sz: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pill_pos: Vector2 = Vector2(-sz.x * 0.5 - 5.0, -half.y - 18.0)
		var pill_rect: Rect2 = Rect2(pill_pos, Vector2(sz.x + 10.0, 14.0))

		draw_rect(pill_rect, Color(0.07, 0.09, 0.14, 0.92), true)
		draw_rect(pill_rect, border_col, false, 1.0)
		draw_string(font, Vector2(pill_pos.x + 5.0, pill_pos.y + 11.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
