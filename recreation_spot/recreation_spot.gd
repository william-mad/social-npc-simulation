class_name RecreationSpot
extends Node2D

signal occupancy_changed(spot: RecreationSpot)

@export var max_capacity: int = 5
@export var outer_radius: float = 74.0
@export var slot_ring_radius: float = 46.0

# Each entry holds an NPC (claiming or actively using this slot) or null
var slots: Array = []

func _ready() -> void:
	add_to_group("recreation_spots")
	_ensure_slot_array()

	# Pop-in placement animation (matches Food & SleepSpot)
	scale = Vector2.ZERO
	modulate.a = 0.0
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

func _exit_tree() -> void:
	for i in range(slots.size()):
		var occupant = slots[i]
		if is_instance_valid(occupant) and occupant.has_method("on_recreation_spot_removed"):
			occupant.on_recreation_spot_removed(self)
		slots[i] = null

func _ensure_slot_array() -> void:
	while slots.size() < max_capacity:
		slots.append(null)
	if slots.size() > max_capacity:
		slots.resize(max_capacity)

## Removes any dead, freed, or no-longer-seeking/recreating NPCs from slots
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
			occupant.target_recreation_spot == self
			and (occupant.current_state == NPC.NPCState.SEEKING_RECREATION or occupant.current_state == NPC.NPCState.IN_RECREATION)
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
	if max_capacity <= 1:
		return Vector2.ZERO
	var angle: float = -PI * 0.5 + (TAU * float(slot_idx) / float(max_capacity))
	return Vector2.from_angle(angle) * slot_ring_radius

func get_slot_world_position(npc: NPC) -> Vector2:
	var idx: int = get_slot_index(npc)
	if idx >= 0:
		return global_position + get_slot_offset(idx)
	return global_position

func get_active_count() -> int:
	_prune_slots()
	var count: int = 0
	for occupant in slots:
		if occupant != null and occupant.current_state == NPC.NPCState.IN_RECREATION and occupant.in_recreation_spot:
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
	var active_cnt: int = 0
	var claimed_cnt: int = 0
	for occupant in slots:
		if occupant != null and is_instance_valid(occupant) and not occupant.is_dead:
			claimed_cnt += 1
			if occupant.current_state == NPC.NPCState.IN_RECREATION and occupant.in_recreation_spot:
				active_cnt += 1

	var rec_gold: Color = Color(0.95, 0.76, 0.16)

	# 1. Outer plaza shadow & floor
	draw_circle(Vector2.ZERO, outer_radius + 3.0, Color(0.05, 0.06, 0.09, 0.8))
	draw_circle(Vector2.ZERO, outer_radius, Color(0.16, 0.14, 0.09, 0.94))
	draw_circle(Vector2.ZERO, outer_radius - 6.0, Color(0.22, 0.19, 0.12, 0.92))

	var border_col: Color = rec_gold.lightened(0.18) if active_cnt > 0 else Color(0.76, 0.62, 0.2, 0.88)
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 48, border_col, 2.0, true)

	# 2. Central recreation centerpiece (game table / lounge hub)
	draw_circle(Vector2.ZERO, 17.0, Color(0.12, 0.1, 0.07, 0.95))
	draw_circle(Vector2.ZERO, 13.0, rec_gold * (0.45 if active_cnt > 0 else 0.25))
	draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 28, border_col, 1.5, true)
	draw_circle(Vector2.ZERO, 4.0, rec_gold.lightened(0.25) if active_cnt > 0 else rec_gold * 0.75)

	# 3. Five radial play/lounge slots around the ring
	for i in range(max_capacity):
		var offset: Vector2 = get_slot_offset(i)
		var occupant = slots[i]
		var is_valid_occ: bool = (occupant != null and is_instance_valid(occupant) and not occupant.is_dead)
		var is_active: bool = (is_valid_occ and occupant.current_state == NPC.NPCState.IN_RECREATION and occupant.in_recreation_spot)

		# Subtle spoke line from hub to slot
		var spoke_col: Color = Color(0.95, 0.76, 0.16, 0.55) if is_active else Color(0.55, 0.46, 0.22, 0.35)
		draw_line(offset.normalized() * 17.0, offset.normalized() * (slot_ring_radius - 20.0), spoke_col, 1.5, true)

		var slot_r: float = 20.0
		if is_active:
			draw_circle(offset, slot_r + 2.0, Color(0.95, 0.76, 0.16, 0.22))
			draw_arc(offset, slot_r, 0.0, TAU, 28, rec_gold.lightened(0.2), 2.0, true)
		elif is_valid_occ:
			draw_arc(offset, slot_r, 0.0, TAU, 24, Color(0.98, 0.84, 0.36, 0.55), 1.5, true)
		else:
			draw_arc(offset, slot_r, 0.0, TAU, 24, Color(0.58, 0.48, 0.22, 0.5), 1.2, true)

	# 4. Floating status pill above recreation spot
	var font = ThemeDB.fallback_font
	if font != null:
		var text: String = "Rec: %d/%d" % [active_cnt, max_capacity]
		if claimed_cnt > active_cnt:
			text = "Rec: %d/%d (+%d)" % [active_cnt, max_capacity, claimed_cnt - active_cnt]
		var font_size: int = 10
		var sz: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pill_pos: Vector2 = Vector2(-sz.x * 0.5 - 5.0, -outer_radius - 18.0)
		var pill_rect: Rect2 = Rect2(pill_pos, Vector2(sz.x + 10.0, 14.0))

		draw_rect(pill_rect, Color(0.08, 0.08, 0.06, 0.92), true)
		draw_rect(pill_rect, border_col, false, 1.0)
		draw_string(font, Vector2(pill_pos.x + 5.0, pill_pos.y + 11.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
