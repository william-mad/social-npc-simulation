class_name NPC
extends CharacterBody2D

## Signals
signal hover_changed(is_hovered: bool)
signal died(npc: NPC)

const HUNGRY_THRESHOLD: float = 40.0
<<<<<<< Updated upstream

# ==============================================================================
# HEALTH (0 to 100)
# Starts at 100. If hunger reaches 100, health depletes at hunger increase rate.
# If health reaches 0, the NPC dies and fades away.
=======
const SLEEP_COLLAPSE_THRESHOLD: float = 88.0
const TIRED_COLLAPSE_THRESHOLD: float = 90.0
const SLEEP_URGENT_SEEK_THRESHOLD: float = 70.0
const TIRED_URGENT_SEEK_THRESHOLD: float = 74.0
const SLEEP_SEEK_THRESHOLD: float = 50.0
const TIRED_SEEK_THRESHOLD: float = 55.0
const BOREDOM_REC_SEEK_THRESHOLD: float = 40.0

enum Gender {
	MALE,
	FEMALE
}

enum RomanceInitiator {
	BOTH,
	MALE_ONLY,
	FEMALE_ONLY
}

enum AggressionResponse {
	AUTO,
	ALWAYS_RETALIATE,
	ALWAYS_FLEE,
	STOIC
}

const MALE_INNER_COLOR: Color = Color(0.24, 0.56, 0.94, 1.0)
const FEMALE_INNER_COLOR: Color = Color(0.92, 0.36, 0.66, 1.0)

const DEFAULT_SLEEPING_RATES: Dictionary = {
	"hunger": 0.3,
	"sleep_need": -18.0,
	"talk_need": 0.2,
	"tired": -22.0,
	"boredom": 0.0,
	"lust": 0.2,
	"purpose": 0.2,
	"anger": -2.0
}

const DEFAULT_RECREATION_RATES: Dictionary = {
	"hunger": 0.8,
	"sleep_need": 0.6,
	"talk_need": -4.0,
	"tired": 2.0,
	"boredom": -22.0,
	"lust": 0.4,
	"purpose": -2.0,
	"anger": -3.0
}

# ==============================================================================
# IDENTITY (GENDER & NUMERIC NAME)
# ==============================================================================
@export_group("Identity")
@export var npc_number: int = 0:
	set(v):
		npc_number = maxi(v, 0)
		queue_redraw()

@export var gender: Gender = Gender.MALE:
	set(v):
		gender = v
		_gender_assigned = true
		queue_redraw()

var _gender_assigned: bool = false

# ==============================================================================
# HEALTH & INDIVIDUAL STATS
>>>>>>> Stashed changes
# ==============================================================================
@export_group("Health")
@export_range(20.0, 300.0) var max_health: float = 100.0:
	set(v):
		max_health = maxf(v, 1.0)
		health = clampf(health, 0.0, max_health)
		queue_redraw()

@export_range(0.0, 300.0) var health: float = 100.0:
	set(v):
		health = clampf(v, 0.0, max_health)
		if not is_dead and health <= 0.0:
			die()
		else:
			queue_redraw()

@export var show_health_always: bool = true

@export_group("Individual Combat & Multipliers")
@export_range(0.0, 60.0) var hit_damage: float = 15.0
@export var aggression_response: AggressionResponse = AggressionResponse.AUTO
@export_range(0.0, 100.0) var retaliation_threshold: float = 39.0
@export_range(0.0, 25.0) var sleep_heal_rate: float = 3.5
@export_range(0.0, 15.0) var passive_heal_rate: float = 0.0
@export_range(0.2, 3.0) var speed_multiplier: float = 1.0
@export_range(0.0, 4.0) var individual_growth_multiplier: float = 1.0

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

func get_effective_move_speed() -> float:
	return move_speed * speed_multiplier

func _update_collision_shape() -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = body_radius

<<<<<<< Updated upstream
=======
## Assigns one of the 8 Personality Archetypes with slight individual jitter
func assign_random_personality() -> void:
	var arch: Dictionary = PERSONALITY_ARCHETYPES[randi() % PERSONALITY_ARCHETYPES.size()]
	personality_name = arch["name"]
	personality_tint = arch["tint"]
	body_outline_color = personality_tint
	anger_threshold = clampf(arch["anger_c"] + randf_range(-0.06, 0.06), 0.22, 0.85)
	retaliation_threshold = clampf(anger_threshold * 75.0, 25.0, 55.0)
	lust_threshold = clampf(arch["lust_c"] + randf_range(-0.06, 0.06), 0.22, 0.85)

	var base_w: Dictionary = arch["weights"]
	for k in base_w:
		personality_weights[k] = clampf(base_w[k] + randf_range(-0.12, 0.12), 0.35, 2.0)
	queue_redraw()

## Records a short-term memory in an 8-slot bounded buffer (Dwarf Fortress pattern)
func add_memory(mem_text: String) -> void:
	if recent_memories.size() >= 8:
		recent_memories.pop_front()
	recent_memories.append(mem_text)

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
		var rate: float = get(need["rate_prop"])
		if rate != 0.0:
			var prop: String = need["prop"]
=======
		var prop: String = need["prop"]
		var rate: float
		if sleeping_now:
			rate = sleeping_growth_rates.get(prop, 0.0)
		elif recreating_now:
			rate = recreation_growth_rates.get(prop, 0.0)
		else:
			rate = get(need["rate_prop"])
		# Personality weight, gender multiplier, and individual multiplier scale positive build-up rates
		var p_weight: float = personality_weights.get(prop, 1.0)
		var g_mult: float = gender_scale_multiplier * float(gender_need_multipliers.get(prop, 1.0)) * individual_growth_multiplier
		var effective_rate: float = rate * (p_weight * g_mult if rate > 0.0 else 1.0)

		if effective_rate != 0.0:
>>>>>>> Stashed changes
			var cur_val: float = get(prop)
			var new_val: float = clampf(cur_val + rate * delta, 0.0, 100.0)
			if new_val != cur_val:
				set(prop, new_val)
				if is_mouse_hovered or (prop == "hunger" and new_val >= 40.0):
					needs_redraw = true

<<<<<<< Updated upstream
	# Health depletion from hunger starvation:
	# "if hunger reaches 100, the health bar starts being depleted at hunger increase rate. if health reaches 0 they die."
	if hunger >= 100.0 and hunger_rate > 0.0:
		var health_loss: float = hunger_rate * delta
		var new_health: float = clampf(health - health_loss, 0.0, 100.0)
=======
	# Max Boredom (100) raises Anger
	if boredom >= 100.0 and max_boredom_anger_rate > 0.0:
		var anger_from_boredom: float = clampf(anger + max_boredom_anger_rate * delta, 0.0, 100.0)
		if anger_from_boredom != anger:
			anger = anger_from_boredom
			if is_mouse_hovered:
				needs_redraw = true

	# Max Purpose (100) raises Anger
	if purpose >= 100.0 and max_purpose_anger_rate > 0.0:
		var anger_from_purpose: float = clampf(anger + max_purpose_anger_rate * delta, 0.0, 100.0)
		if anger_from_purpose != anger:
			anger = anger_from_purpose
			if is_mouse_hovered:
				needs_redraw = true

	# Max Tired (100) raises Anger
	if tired >= 100.0 and max_tired_anger_rate > 0.0:
		var anger_from_tired: float = clampf(anger + max_tired_anger_rate * delta, 0.0, 100.0)
		if anger_from_tired != anger:
			anger = anger_from_tired
			if is_mouse_hovered:
				needs_redraw = true

	# Passive health regeneration when not starving
	if passive_heal_rate > 0.0 and hunger < 85.0 and health < max_health:
		var healed: float = clampf(health + passive_heal_rate * delta, 0.0, max_health)
		if healed != health:
			health = healed
			needs_redraw = true

	# Starvation damage when hunger == 100 (controlled by max_hunger_health_drain_rate)
	if hunger >= 100.0 and max_hunger_health_drain_rate > 0.0:
		var health_loss: float = max_hunger_health_drain_rate * delta
		var new_health: float = clampf(health - health_loss, 0.0, max_health)
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
			if target_food != null:
				_path_towards_food(target_food)
				return

		# Regular wander if not hungry or no food available
=======
			if target_food != null and hunger >= 20.0:
				_path_towards_food(target_food, delta)
			else:
				_evaluate_utility_brain()
				_handle_movement(delta)
		NPCState.SEEKING_SLEEP_SPOT:
			_process_sleep_spot_seeking(delta)
		NPCState.SEEKING_RECREATION:
			_process_recreation_seeking(delta)
		NPCState.SEEKING_SOCIAL:
			_process_social_seeking(delta)
		NPCState.PURSUING_PURPOSE:
			_process_purpose_behavior(delta)
		NPCState.RELIEVING_BOREDOM:
			_process_boredom_behavior(delta)
		_:
			_handle_movement(delta)

## Evaluates all 8 needs using Priority Bucketing + Utility Curves
func _evaluate_utility_brain() -> void:
	var has_food_available: bool = (_find_nearest_food() != null)
	var available_sleep_spot: SleepSpot = _find_nearest_sleep_spot()
	var has_sleep_spot_available: bool = (available_sleep_spot != null)
	var available_rec_spot: RecreationSpot = _find_nearest_recreation_spot()
	var has_rec_spot_available: bool = (available_rec_spot != null)

	# BUCKET 1: Critical Survival Emergency (Starving or Exhaustion Collapse)
	if (hunger >= 75.0 or (is_hungry() and hunger >= 55.0)) and has_food_available:
		_release_sleep_spot()
		_release_recreation_spot()
		current_state = NPCState.SEEKING_FOOD
		state_label_text = "Rushing to Food!" if anger >= 60.0 else "Seeking Food"
		return

	if sleep_need >= SLEEP_COLLAPSE_THRESHOLD or tired >= TIRED_COLLAPSE_THRESHOLD:
		_release_recreation_spot()
		if in_sleep_spot and is_instance_valid(target_sleep_spot):
			current_state = NPCState.SLEEPING
			state_label_text = "Sleeping (Spot)"
		elif is_instance_valid(target_sleep_spot) and target_sleep_spot.reserve_slot(self) != -1 and global_position.distance_to(target_sleep_spot.get_slot_world_position(self)) <= 24.0:
			global_position = target_sleep_spot.get_slot_world_position(self)
			in_sleep_spot = true
			current_state = NPCState.SLEEPING
			state_label_text = "Sleeping (Spot)"
			target_sleep_spot.notify_visual_update()
		else:
			_release_sleep_spot()
			current_state = NPCState.SLEEPING
			state_label_text = "Collapsed (Sleeping)"
		return

	# Proactively seek a Sleep Spot when getting drowsy, before collapsing
	if (sleep_need >= SLEEP_URGENT_SEEK_THRESHOLD or tired >= TIRED_URGENT_SEEK_THRESHOLD) and has_sleep_spot_available:
		_release_recreation_spot()
		current_state = NPCState.SEEKING_SLEEP_SPOT
		state_label_text = "Seeking Sleep Spot!"
		return

	# Score all candidate directives via Utility Curves
	var u_hunger: float = get_drive_utility("hunger") if (is_hungry() and has_food_available) else 0.0
	var u_rest: float = 0.0
	if has_sleep_spot_available and (sleep_need >= SLEEP_SEEK_THRESHOLD or tired >= TIRED_SEEK_THRESHOLD):
		u_rest = maxf(get_drive_utility("sleep_need"), get_drive_utility("tired")) * 1.25
	var can_rom: bool = can_initiate_romance()
	var u_lust_drive: float = get_drive_utility("lust") if can_rom else 0.0
	var u_social: float = maxf(get_drive_utility("talk_need"), u_lust_drive)
	var social_peak: float = maxf(talk_need, lust) if can_rom else talk_need
	if social_cooldown > 0.0 or social_peak < 38.0:
		u_social *= 0.25

	var u_attack: float = 0.0
	var candidate_target: NPC = null
	if anger >= 48.0 and attack_cooldown <= 0.0:
		candidate_target = _find_attack_target()
		if candidate_target != null:
			u_attack = get_drive_utility("anger") * 1.15

	var u_purpose: float = get_drive_utility("purpose") if purpose >= 35.0 else 0.0
	var u_boredom: float = 0.0
	if has_rec_spot_available and boredom >= BOREDOM_REC_SEEK_THRESHOLD:
		u_boredom = get_drive_utility("boredom") * 1.25
	elif boredom >= 45.0:
		u_boredom = get_drive_utility("boredom")

	# Find highest utility winner
	var best_u: float = 0.28 # Minimum threshold to leave idle wander
	var best_state: NPCState = NPCState.WANDER

	if u_hunger > best_u:
		best_u = u_hunger
		best_state = NPCState.SEEKING_FOOD
	if u_rest > best_u:
		best_u = u_rest
		best_state = NPCState.SEEKING_SLEEP_SPOT
	if u_attack > best_u:
		best_u = u_attack
		best_state = NPCState.ATTACKING
	if u_social > best_u:
		best_u = u_social
		best_state = NPCState.SEEKING_SOCIAL
	if u_purpose > best_u:
		best_u = u_purpose
		best_state = NPCState.PURSUING_PURPOSE
	if u_boredom > best_u:
		best_u = u_boredom
		best_state = NPCState.SEEKING_RECREATION if has_rec_spot_available else NPCState.RELIEVING_BOREDOM

	if best_state != NPCState.SEEKING_SLEEP_SPOT and best_state != NPCState.SLEEPING:
		_release_sleep_spot()
	if best_state != NPCState.SEEKING_RECREATION and best_state != NPCState.IN_RECREATION:
		_release_recreation_spot()

	if best_state == NPCState.ATTACKING and candidate_target != null:
		start_attack(candidate_target)
		return

	current_state = best_state

	# Configure sub-branches based on secondary drives!
	match current_state:
		NPCState.SEEKING_FOOD:
			state_label_text = "Aggressive Forage" if anger >= 60.0 else "Seeking Food"
		NPCState.SEEKING_SLEEP_SPOT:
			state_label_text = "Seeking Sleep Spot"
		NPCState.SLEEPING:
			state_label_text = "Sleeping (Spot)" if in_sleep_spot else "Collapsed (Sleeping)"
		NPCState.SEEKING_RECREATION:
			state_label_text = "Seeking Recreation"
		NPCState.IN_RECREATION:
			state_label_text = "Recreation (Spot)"
		NPCState.SEEKING_SOCIAL:
			if can_initiate_romance() and lust >= talk_need and lust >= 50.0:
				state_label_text = "Seeking Romance"
			else:
				state_label_text = "Seeking Chat"
		NPCState.PURSUING_PURPOSE:
			if hunger >= 35.0:
				state_label_text = "Purpose: Foraging"
			elif talk_need >= 55.0:
				state_label_text = "Purpose: Mentoring"
			else:
				state_label_text = "Purpose: Working"
		NPCState.RELIEVING_BOREDOM:
			if anger >= 58.0:
				boredom_branch = "Rowdy"
				state_label_text = "Bored: Rowdy Sprint"
			elif talk_need >= 50.0 or (can_initiate_romance() and lust >= 50.0):
				current_state = NPCState.SEEKING_SOCIAL
				state_label_text = "Bored: Seeking Crowd"
			else:
				boredom_branch = "Spin"
				state_label_text = "Bored: Joyriding"
		NPCState.WANDER:
			state_label_text = "Wandering"

# ==============================================================================
# BRANCHING EXECUTION FOR SLEEP, PURPOSE, BOREDOM & FLEEING
# ==============================================================================
func _find_nearest_sleep_spot() -> SleepSpot:
	if not is_inside_tree():
		return null
	if is_instance_valid(target_sleep_spot) and target_sleep_spot.can_accept(self):
		return target_sleep_spot
	var tree = get_tree()
	if tree == null:
		return null
	var spots = tree.get_nodes_in_group("sleep_spots")
	if spots.is_empty():
		return null

	var nearest: SleepSpot = null
	var min_dist_sq: float = INF
	for s in spots:
		if is_instance_valid(s) and s is SleepSpot and (s as SleepSpot).can_accept(self):
			var d_sq: float = global_position.distance_squared_to(s.global_position)
			if d_sq < min_dist_sq:
				min_dist_sq = d_sq
				nearest = s as SleepSpot
	return nearest

func _release_sleep_spot() -> void:
	var prev_spot: SleepSpot = target_sleep_spot
	target_sleep_spot = null
	in_sleep_spot = false
	if is_instance_valid(prev_spot):
		prev_spot.release_slot(self)

func on_sleep_spot_removed(spot: SleepSpot) -> void:
	if target_sleep_spot != spot:
		return
	target_sleep_spot = null
	in_sleep_spot = false
	if current_state == NPCState.SEEKING_SLEEP_SPOT:
		current_state = NPCState.WANDER
		_evaluate_utility_brain()
	elif current_state == NPCState.SLEEPING:
		state_label_text = "Collapsed (Sleeping)"
		queue_redraw()

func _process_sleep_spot_seeking(delta: float) -> void:
	# If exhaustion crosses collapsing threshold en route, collapse immediately
	if sleep_need >= SLEEP_COLLAPSE_THRESHOLD or tired >= TIRED_COLLAPSE_THRESHOLD:
		if is_instance_valid(target_sleep_spot) and target_sleep_spot.reserve_slot(self) != -1 and global_position.distance_to(target_sleep_spot.get_slot_world_position(self)) <= 24.0:
			global_position = target_sleep_spot.get_slot_world_position(self)
			velocity = Vector2.ZERO
			in_sleep_spot = true
			current_state = NPCState.SLEEPING
			state_label_text = "Sleeping (Spot)"
			target_sleep_spot.notify_visual_update()
			queue_redraw()
			return
		_release_sleep_spot()
		velocity = Vector2.ZERO
		current_state = NPCState.SLEEPING
		state_label_text = "Collapsed (Sleeping)"
		queue_redraw()
		return

	if not is_instance_valid(target_sleep_spot) or not target_sleep_spot.can_accept(self):
		_release_sleep_spot()
		target_sleep_spot = _find_nearest_sleep_spot()

	if target_sleep_spot == null:
		current_state = NPCState.WANDER
		_evaluate_utility_brain()
		_handle_movement(delta)
		return

	if target_sleep_spot.reserve_slot(self) == -1:
		target_sleep_spot = null
		_evaluate_utility_brain()
		_handle_movement(delta)
		return

	var slot_pos: Vector2 = target_sleep_spot.get_slot_world_position(self)
	var to_slot: Vector2 = slot_pos - global_position
	if to_slot.length() <= 8.0:
		global_position = slot_pos
		velocity = Vector2.ZERO
		in_sleep_spot = true
		current_state = NPCState.SLEEPING
		state_label_text = "Sleeping (Spot)"
		target_sleep_spot.notify_visual_update()
		queue_redraw()
	else:
		var spd_mult: float = 0.85 if tired >= 75.0 else 1.05
		velocity = to_slot.normalized() * (get_effective_move_speed() * spd_mult)
		move_and_slide()
		_enforce_arena_bounds()

func _process_sleeping(delta: float) -> void:
	velocity = Vector2.ZERO
	if in_sleep_spot:
		if is_instance_valid(target_sleep_spot) and target_sleep_spot.get_slot_index(self) >= 0:
			var slot_pos: Vector2 = target_sleep_spot.get_slot_world_position(self)
			global_position = global_position.lerp(slot_pos, minf(1.0, 12.0 * delta))
		else:
			in_sleep_spot = false
			target_sleep_spot = null
			state_label_text = "Collapsed (Sleeping)"

	# Slight health recovery while resting if not starving (better in a sleep spot)
	if hunger < 85.0 and health < max_health and sleep_heal_rate > 0.0:
		var heal_rate: float = sleep_heal_rate if in_sleep_spot else (sleep_heal_rate * 0.6)
		health = clampf(health + heal_rate * delta, 0.0, max_health)

	if sleep_need <= 12.0 and tired <= 15.0:
		var was_in_spot: bool = in_sleep_spot
		_release_sleep_spot()
		current_state = NPCState.WANDER
		state_label_text = "Refreshed!"
		add_memory("Woke up refreshed in a sleep spot" if was_in_spot else "Woke up feeling refreshed")
	queue_redraw()

func _find_nearest_recreation_spot() -> RecreationSpot:
	if not is_inside_tree():
		return null
	if is_instance_valid(target_recreation_spot) and target_recreation_spot.can_accept(self):
		return target_recreation_spot
	var tree = get_tree()
	if tree == null:
		return null
	var spots = tree.get_nodes_in_group("recreation_spots")
	if spots.is_empty():
		return null

	var nearest: RecreationSpot = null
	var min_dist_sq: float = INF
	for s in spots:
		if is_instance_valid(s) and s is RecreationSpot and (s as RecreationSpot).can_accept(self):
			var d_sq: float = global_position.distance_squared_to(s.global_position)
			if d_sq < min_dist_sq:
				min_dist_sq = d_sq
				nearest = s as RecreationSpot
	return nearest

func _release_recreation_spot() -> void:
	var prev_spot: RecreationSpot = target_recreation_spot
	target_recreation_spot = null
	in_recreation_spot = false
	if is_instance_valid(prev_spot):
		prev_spot.release_slot(self)

func on_recreation_spot_removed(spot: RecreationSpot) -> void:
	if target_recreation_spot != spot:
		return
	target_recreation_spot = null
	in_recreation_spot = false
	if current_state == NPCState.SEEKING_RECREATION or current_state == NPCState.IN_RECREATION:
		current_state = NPCState.WANDER
		_evaluate_utility_brain()
		queue_redraw()

func _process_recreation_seeking(delta: float) -> void:
	if not is_instance_valid(target_recreation_spot) or not target_recreation_spot.can_accept(self):
		_release_recreation_spot()
		target_recreation_spot = _find_nearest_recreation_spot()

	if target_recreation_spot == null:
		current_state = NPCState.WANDER
		_evaluate_utility_brain()
		_handle_movement(delta)
		return

	if target_recreation_spot.reserve_slot(self) == -1:
		target_recreation_spot = null
		_evaluate_utility_brain()
		_handle_movement(delta)
		return

	var slot_pos: Vector2 = target_recreation_spot.get_slot_world_position(self)
	var to_slot: Vector2 = slot_pos - global_position
	if to_slot.length() <= 8.0:
		global_position = slot_pos
		velocity = Vector2.ZERO
		in_recreation_spot = true
		recreation_sway_time = randf() * TAU
		current_state = NPCState.IN_RECREATION
		state_label_text = "Recreation (Spot)"
		target_recreation_spot.notify_visual_update()
		queue_redraw()
	else:
		var spd_mult: float = 0.85 if tired >= 75.0 else 1.15
		velocity = to_slot.normalized() * (get_effective_move_speed() * spd_mult)
		move_and_slide()
		_enforce_arena_bounds()

func _process_in_recreation(delta: float) -> void:
	velocity = Vector2.ZERO
	if not is_instance_valid(target_recreation_spot) or target_recreation_spot.get_slot_index(self) < 0:
		_release_recreation_spot()
		current_state = NPCState.WANDER
		_evaluate_utility_brain()
		return

	recreation_sway_time += delta * 3.0
	var slot_pos: Vector2 = target_recreation_spot.get_slot_world_position(self)
	var sway := Vector2(cos(recreation_sway_time), sin(recreation_sway_time * 1.3)) * 2.5
	global_position = global_position.lerp(slot_pos + sway, minf(1.0, 10.0 * delta))

	if boredom <= 12.0:
		_release_recreation_spot()
		current_state = NPCState.WANDER
		state_label_text = "Entertained!"
		add_memory("Relaxed at a recreation spot")
		_evaluate_utility_brain()
	queue_redraw()

func _process_purpose_behavior(delta: float) -> void:
	var to_target: Vector2 = purpose_target - global_position
	if to_target.length() <= body_radius + 14.0:
		# Arrived at work/purpose waypoint: perform work cycle
		velocity = Vector2.ZERO
		purpose_progress += delta
		purpose = clampf(purpose - 16.0 * delta, 0.0, 100.0)
		tired = clampf(tired + 5.5 * delta, 0.0, 100.0)
		boredom = clampf(boredom - 4.0 * delta, 0.0, 100.0)

		# Branch: Mentoring nearby NPCs if Talk is high
		if talk_need >= 45.0:
			talk_need = clampf(talk_need - 6.0 * delta, 0.0, 100.0)

		if purpose_progress >= 1.8:
			purpose_progress = 0.0
			# Branch: If foraging (Purpose + Hunger), spawn a small food ration!
			if hunger >= 35.0:
				foraging_completed.emit(global_position + Vector2.from_angle(randf() * TAU) * 28.0, 20.0)
				add_memory("Foraged food via Purpose")
			else:
				add_memory("Completed a Purpose task")
			_pick_new_purpose_target()
			if purpose <= 20.0 or tired >= 80.0:
				_evaluate_utility_brain()
	else:
		var spd_mult: float = 0.75 if tired >= 70.0 else 1.05
		velocity = to_target.normalized() * (get_effective_move_speed() * spd_mult)
		move_and_slide()
		_enforce_arena_bounds()

func _pick_new_purpose_target() -> void:
	var bounds = arena_bounds if arena_bounds.size != Vector2.ZERO else get_viewport_rect()
	var margin: float = 90.0
	purpose_target = Vector2(
		randf_range(bounds.position.x + margin, bounds.position.x + bounds.size.x - margin),
		randf_range(bounds.position.y + margin, bounds.position.y + bounds.size.y - margin)
	)

func _process_boredom_behavior(delta: float) -> void:
	orbit_angle += (5.5 if boredom_branch == "Spin" else 3.2) * delta
	var spd: float = get_effective_move_speed() * (1.35 if boredom_branch == "Rowdy" else 1.1)
	var dir: Vector2 = Vector2.from_angle(orbit_angle)
	velocity = dir * spd
	move_and_slide()
	_enforce_arena_bounds()

	# Relieves boredom at the cost of slight fatigue
	boredom = clampf(boredom - 16.0 * delta, 0.0, 100.0)
	tired = clampf(tired + 4.0 * delta, 0.0, 100.0)
	if boredom <= 18.0:
		_evaluate_utility_brain()

func _process_fleeing(delta: float) -> void:
	flee_timer -= delta
	if flee_timer <= 0.0 or not is_instance_valid(flee_target) or flee_target.is_dead:
		current_state = NPCState.WANDER
		flee_target = null
		_evaluate_utility_brain()
		return

	var away_dir: Vector2 = (global_position - flee_target.global_position).normalized()
	if away_dir == Vector2.ZERO:
		away_dir = Vector2.from_angle(randf() * TAU)
	velocity = away_dir * (get_effective_move_speed() * 1.45)
	tired = clampf(tired + 6.0 * delta, 0.0, 100.0)
	move_and_slide()
	_enforce_arena_bounds()

# ==============================================================================
# NON-CONTRACTUAL HEADBUTT COMBAT ENGINE
# One NPC attacks unilaterally; victim takes chunk HP damage & retaliates only if anger is high enough
# ==============================================================================
func get_retaliation_threshold() -> float:
	return clampf(retaliation_threshold, 0.0, 100.0)

func _interrupt_for_combat() -> void:
	_release_sleep_spot()
	_release_recreation_spot()
	if current_state == NPCState.IN_CONVERSATION:
		var prev_partner: NPC = social_partner
		social_partner = null
		current_state = NPCState.WANDER
		if is_instance_valid(prev_partner) and not prev_partner.is_dead and prev_partner.current_state == NPCState.IN_CONVERSATION and prev_partner.social_partner == self:
			prev_partner._end_conversation()

func _find_attack_target() -> NPC:
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree == null:
		return null
	var npcs = tree.get_nodes_in_group("npcs")
	var best_npc: NPC = null
	var best_score: float = -INF

	for node in npcs:
		if node == self or not is_instance_valid(node) or not (node is NPC):
			continue
		var other: NPC = node as NPC
		if other.is_dead:
			continue
		var d: float = global_position.distance_to(other.global_position)
		if d > 460.0:
			continue
		# Prefer nearby rivals (negative affinity) and close targets
		var prior_aff: float = affinities.get(other.get_instance_id(), 0.0)
		var score: float = (460.0 - d) * 0.25 - (prior_aff * 0.6)
		if score > best_score:
			best_score = score
			best_npc = other
	return best_npc

func start_attack(target: NPC, is_retaliation: bool = false) -> void:
	if not is_instance_valid(target) or target.is_dead or target == self:
		return
	_interrupt_for_combat()
	attack_target = target
	current_state = NPCState.ATTACKING
	attack_phase = AttackPhase.CHASE
	attack_phase_timer = 0.0
	lunge_hit_landed = false
	if is_retaliation:
		strike_cooldown = maxf(strike_cooldown, 0.22)
		state_label_text = "Fighting Back (#%d)!" % target.npc_number
		add_memory("Retaliated against #%d" % target.npc_number)
	else:
		state_label_text = "Headbutting #%d!" % target.npc_number
	queue_redraw()

func _stop_attacking(cooldown_min: float = 2.5, cooldown_max: float = 4.5) -> void:
	attack_target = null
	attack_phase = AttackPhase.CHASE
	attack_phase_timer = 0.0
	lunge_hit_landed = false
	attack_cooldown = randf_range(cooldown_min, cooldown_max)
	current_state = NPCState.WANDER
	_evaluate_utility_brain()
	queue_redraw()

func _process_attacking(delta: float) -> void:
	if not is_instance_valid(attack_target) or attack_target.is_dead:
		_stop_attacking(2.5, 4.0)
		return

	# Stop fighting if anger cooled off or exhausted (collapse threshold)
	if anger <= 18.0 or tired >= TIRED_COLLAPSE_THRESHOLD or (hunger >= 92.0 and _find_nearest_food() != null):
		_stop_attacking(2.5, 4.5)
		return

	var to_target: Vector2 = attack_target.global_position - global_position
	var dist: float = to_target.length()
	var dir_to_target: Vector2 = to_target.normalized() if dist > 0.001 else Vector2.RIGHT

	if dist > 540.0 and attack_phase == AttackPhase.CHASE:
		_stop_attacking(2.0, 3.5)
		return

	match attack_phase:
		AttackPhase.CHASE:
			state_label_text = "Charging #%d!" % attack_target.npc_number
			var windup_range: float = body_radius + attack_target.body_radius + 36.0
			if dist <= windup_range and strike_cooldown <= 0.0:
				attack_phase = AttackPhase.WINDUP
				attack_phase_timer = 0.16
				lunge_dir = dir_to_target
				state_label_text = "Windup -> #%d!" % attack_target.npc_number
			else:
				velocity = dir_to_target * (get_effective_move_speed() * 1.42)
				move_and_slide()
				_enforce_arena_bounds()

		AttackPhase.WINDUP:
			attack_phase_timer -= delta
			lunge_dir = dir_to_target
			# Coil backward slightly before ramming forward
			velocity = -lunge_dir * maxf(get_effective_move_speed() * 0.85, 55.0)
			move_and_slide()
			_enforce_arena_bounds()
			if attack_phase_timer <= 0.0:
				attack_phase = AttackPhase.LUNGE
				attack_phase_timer = 0.24
				lunge_hit_landed = false
				state_label_text = "HEADBUTT #%d!" % attack_target.npc_number

		AttackPhase.LUNGE:
			attack_phase_timer -= delta
			var lunge_speed: float = maxf(get_effective_move_speed() * 4.2, 260.0)
			velocity = lunge_dir * lunge_speed
			move_and_slide()
			_enforce_arena_bounds()

			var contact_range: float = body_radius + attack_target.body_radius + 6.0
			if not lunge_hit_landed and global_position.distance_to(attack_target.global_position) <= contact_range:
				_land_headbutt(attack_target)
				return

			if attack_phase_timer <= 0.0:
				attack_phase = AttackPhase.RECOIL
				attack_phase_timer = 0.28
				strike_cooldown = 0.25
				velocity = Vector2.ZERO

		AttackPhase.RECOIL:
			attack_phase_timer -= delta
			velocity = Vector2.ZERO
			if attack_phase_timer <= 0.0:
				if not is_instance_valid(attack_target) or attack_target.is_dead or anger <= 20.0:
					_stop_attacking(2.5, 4.5)
				else:
					attack_phase = AttackPhase.CHASE
					strike_cooldown = maxf(strike_cooldown, 0.2)

	queue_redraw()

func _land_headbutt(target: NPC) -> void:
	lunge_hit_landed = true
	var impact_dir: Vector2 = (target.global_position - global_position).normalized()
	if impact_dir == Vector2.ZERO:
		impact_dir = lunge_dir

	# Discrete chunk damage based on individual hit_damage & anger intensity
	var anger_factor: float = 0.7 + (anger / 100.0) * 0.6
	var dmg: float = roundf(hit_damage * anger_factor) if hit_damage > 0.0 else 0.0
	var midpoint: Vector2 = (global_position + target.global_position) * 0.5

	# Attacker physical recoil, anger vent & stamina cost
	knockback_velocity = -impact_dir * 220.0
	anger = clampf(anger - 18.0, 0.0, 100.0)
	tired = clampf(tired + 7.0, 0.0, 100.0)
	boredom = clampf(boredom - 8.0, 0.0, 100.0)
	_shift_affinity(target, -15.0)

	impact_fx_world_pos = midpoint
	impact_fx_timer = 0.24
	attack_phase = AttackPhase.RECOIL
	attack_phase_timer = 0.42
	strike_cooldown = 0.3

	# Squash & stretch impact animation on attacker
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.22, 0.8), 0.06).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)

	target.receive_headbutt(self, impact_dir, dmg, midpoint)

	if not is_instance_valid(target) or target.is_dead:
		add_memory("Knocked out #%d!" % target.npc_number)
		_stop_attacking(3.0, 5.0)
	else:
		add_memory("Headbutted #%d (-%d HP)" % [target.npc_number, int(dmg)])
	queue_redraw()

func receive_headbutt(attacker: NPC, impact_dir: Vector2, damage: float, impact_pos: Vector2) -> void:
	if is_dead:
		return

	# Apply discrete chunk of health loss
	var actual_dmg: float = clampf(damage, 0.0, max_health)
	knockback_velocity = impact_dir * 270.0
	hit_flash_timer = 0.24
	impact_fx_world_pos = impact_pos
	impact_fx_timer = 0.24
	_spawn_floating_popup("-%d" % int(round(actual_dmg)), Color(1.0, 0.28, 0.24))

	# Squash & stretch recoil
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(0.78, 1.24), 0.06).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

	tired = clampf(tired + 5.0, 0.0, 100.0)
	anger = clampf(anger + 10.0, 0.0, 100.0)
	if is_instance_valid(attacker):
		_shift_affinity(attacker, -22.0)

	health = clampf(health - actual_dmg, 0.0, max_health)
	if is_dead:
		return

	# Already fighting this attacker? Keep fighting after brief recoil!
	if current_state == NPCState.ATTACKING and attack_target == attacker:
		attack_phase = AttackPhase.RECOIL
		attack_phase_timer = 0.26
		strike_cooldown = 0.2
		queue_redraw()
		return

	# Non-contractual reaction governed by individual aggression_response & retaliation_threshold
	if aggression_response == AggressionResponse.STOIC:
		add_memory("Shrugged off headbutt from #%d" % attacker.npc_number)
		queue_redraw()
		return

	_interrupt_for_combat()
	if is_instance_valid(attacker) and not attacker.is_dead:
		var should_retaliate: bool = false
		match aggression_response:
			AggressionResponse.ALWAYS_RETALIATE:
				should_retaliate = true
			AggressionResponse.ALWAYS_FLEE:
				should_retaliate = false
			_:
				should_retaliate = (anger >= get_retaliation_threshold())

		if should_retaliate:
			start_attack(attacker, true)
		else:
			current_state = NPCState.FLEEING
			flee_target = attacker
			flee_timer = 2.4
			state_label_text = "Fleeing from #%d!" % attacker.npc_number
			add_memory("Headbutted by #%d & fled" % attacker.npc_number)
	queue_redraw()

func _spawn_floating_popup(text: String, col: Color) -> void:
	floating_popups.append({
		"text": text,
		"pos": Vector2(randf_range(-8.0, 8.0), -body_radius - 10.0),
		"vel": Vector2(randf_range(-10.0, 10.0), -36.0),
		"life": 0.75,
		"max_life": 0.75,
		"color": col
	})

# ==============================================================================
# TALK / LUST / ANGER AVERAGING SOCIAL ENGINE
# ==============================================================================
func _process_social_seeking(delta: float) -> void:
	if not is_instance_valid(social_partner) or social_partner.is_dead or social_partner.current_state == NPCState.IN_CONVERSATION:
		social_partner = _find_best_social_partner()

	if social_partner == null:
		# Nobody available right now; wander and burn a tiny bit of restlessness
>>>>>>> Stashed changes
		_handle_movement(delta)

<<<<<<< Updated upstream
## Finds the nearest active food in the world
=======
	var to_partner: Vector2 = social_partner.global_position - global_position
	var dist: float = to_partner.length()
	var social_range: float = body_radius + social_partner.body_radius + 26.0

	if dist <= social_range:
		_initiate_dyadic_interaction(social_partner)
	else:
		velocity = to_partner.normalized() * (get_effective_move_speed() * 1.15)
		move_and_slide()
		_enforce_arena_bounds()

func _find_best_social_partner() -> NPC:
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree == null:
		return null
	var npcs = tree.get_nodes_in_group("npcs")
	var best_npc: NPC = null
	var best_score: float = -INF
	var can_rom: bool = can_initiate_romance()
	var seeking_romance: bool = (can_rom and lust >= talk_need and lust >= 50.0)

	for node in npcs:
		if node == self or not is_instance_valid(node) or not (node is NPC):
			continue
		var other: NPC = node as NPC
		if other.is_dead or other.current_state == NPCState.IN_CONVERSATION or other.current_state == NPCState.SLEEPING or other.current_state == NPCState.IN_RECREATION or other.current_state == NPCState.ATTACKING:
			continue
		if other.social_cooldown > 0.0:
			continue

		var opposite_gender: bool = (other.gender != gender)
		# Lustful / romantic seeking only targets opposite gender (male <-> female)
		if seeking_romance and not opposite_gender:
			continue

		var d: float = global_position.distance_to(other.global_position)
		if d > 480.0:
			continue

		# Score partner by proximity + dyadic Talk/(Lust if allowed)/Anger average potential
		var avg_social: float
		if opposite_gender and can_rom:
			avg_social = ((talk_need + other.talk_need) + (lust + other.lust) + (anger + other.anger)) / 6.0
		else:
			avg_social = ((talk_need + other.talk_need) + (anger + other.anger)) / 4.0
		var prox_score: float = (480.0 - d) * 0.15
		var score: float = avg_social + prox_score
		if score > best_score:
			best_score = score
			best_npc = other

	return best_npc

## Computes the Averages of Talk, Lust, and Anger to decide Conversation Topic, Value & Branch
func _initiate_dyadic_interaction(partner: NPC) -> void:
	if partner.current_state == NPCState.IN_CONVERSATION or partner.is_dead:
		return

	var opposite_gender: bool = (gender != partner.gender)
	var allow_romance: bool = opposite_gender and can_initiate_romance()

	# 1. Compute Pairwise Averages (0 to 100 scale) and Asymmetry Gaps
	var avg_talk: float = (talk_need + partner.talk_need) * 0.5
	var avg_lust: float = (lust + partner.lust) * 0.5 if allow_romance else 0.0
	var avg_anger: float = (anger + partner.anger) * 0.5

	var gap_talk: float = absf(talk_need - partner.talk_need)
	var gap_lust: float = absf(lust - partner.lust)
	var gap_anger: float = absf(anger - partner.anger)

	var prior_affinity: float = affinities.get(partner.get_instance_id(), 0.0)

	# 2. Score Conversation Topics using Single & Compound Averages
	# Lustful interactions require Male-Female AND the initiator's gender must be allowed by romance_initiator_mode
	var topic_scores: Dictionary = {
		"Deep Chat":     avg_talk * (1.0 - (avg_lust + avg_anger) / 220.0),
		"Heated Debate": (avg_talk + avg_anger) * 0.5,
		"Brawl":         avg_anger * (1.0 - avg_talk / 220.0) - (prior_affinity * 0.15)
	}
	if allow_romance:
		topic_scores["Flirty Banter"] = (avg_talk + avg_lust) * 0.5
		topic_scores["Passionate Romance"] = avg_lust * (1.0 - avg_anger / 140.0) + (prior_affinity * 0.15)
		topic_scores["Jealous Drama"] = (avg_lust + avg_anger) * 0.5

	var chosen_topic: String = "Deep Chat"
	var best_topic_val: float = -INF
	for t in topic_scores:
		if topic_scores[t] > best_topic_val:
			best_topic_val = topic_scores[t]
			chosen_topic = t

	# 3. Map the Winning Topic Average [0, 100] onto the [-5.0, +15.0] pts/s Value Scale
	var clamped_topic_avg: float = clampf(best_topic_val, 0.0, 100.0)
	var rate_value: float = -5.0 + (clamped_topic_avg / 100.0) * 20.0

	# 4. Determine Branching Outcome (MUTUAL vs REJECTED vs FLEE/BRAWL)
	var branch: String = "MUTUAL"
	var topic_col: Color = Color(0.12, 0.82, 0.88)

	match chosen_topic:
		"Deep Chat":
			topic_col = Color(0.12, 0.82, 0.88) # Cyan
			branch = "MUTUAL" if gap_talk < 38.0 else "REJECTED"
		"Flirty Banter", "Passionate Romance":
			topic_col = Color(0.95, 0.25, 0.55) # Rose Pink
			branch = "MUTUAL" if (gap_lust < 32.0 and prior_affinity >= -25.0) else "REJECTED"
		"Heated Debate":
			topic_col = Color(0.95, 0.76, 0.16) # Amber
			branch = "MUTUAL" if gap_anger < 35.0 else "REJECTED"
		"Jealous Drama", "Brawl":
			# Non-contractual escalation: the angrier NPC unilaterally attacks instead of locking both into a brawl!
			var aggressor: NPC = self if anger >= partner.anger else partner
			var victim: NPC = partner if aggressor == self else self
			aggressor.start_attack(victim)
			return

	# Lock both NPCs into the synchronized conversation state
	var duration: float = 2.4
	_enter_conversation_lock(partner, chosen_topic, branch, rate_value, topic_col, duration)
	partner._enter_conversation_lock(self, chosen_topic, branch, rate_value, topic_col, duration)

func _enter_conversation_lock(partner: NPC, topic: String, branch: String, val_rate: float, col: Color, duration: float) -> void:
	_release_sleep_spot()
	_release_recreation_spot()
	current_state = NPCState.IN_CONVERSATION
	social_partner = partner
	conversation_topic = topic
	conversation_branch = branch
	conversation_value_rate = val_rate
	conversation_color = col
	conversation_timer = duration
	velocity = Vector2.ZERO
	state_label_text = "%s (%+.1f/s) [%s]" % [topic, val_rate, branch]

	# Quick social pop animation
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12)
	queue_redraw()

func _process_active_conversation(delta: float) -> void:
	velocity = Vector2.ZERO
	conversation_timer -= delta

	if not is_instance_valid(social_partner) or social_partner.is_dead:
		_end_conversation()
		return

	# Intensity multiplier scaled from the averaged topic value
	var intensity: float = clampf((conversation_value_rate + 5.0) / 15.0, 0.35, 1.6)

	match conversation_topic:
		"Deep Chat":
			if conversation_branch == "MUTUAL":
				talk_need = clampf(talk_need - 18.0 * intensity * delta, 0.0, 100.0)
				boredom = clampf(boredom - 12.0 * intensity * delta, 0.0, 100.0)
				purpose = clampf(purpose - 5.0 * delta, 0.0, 100.0)
				_shift_affinity(social_partner, 8.0 * delta)
			else:
				# Awkward / rejected chat -> increases Anger and Boredom!
				talk_need = clampf(talk_need - 6.0 * delta, 0.0, 100.0)
				anger = clampf(anger + 10.0 * intensity * delta, 0.0, 100.0)
				boredom = clampf(boredom + 9.0 * delta, 0.0, 100.0)
				_shift_affinity(social_partner, -4.0 * delta)

		"Flirty Banter", "Passionate Romance":
			if conversation_branch == "MUTUAL":
				lust = clampf(lust - 20.0 * intensity * delta, 0.0, 100.0)
				talk_need = clampf(talk_need - 14.0 * intensity * delta, 0.0, 100.0)
				boredom = clampf(boredom - 15.0 * intensity * delta, 0.0, 100.0)
				anger = clampf(anger - 8.0 * delta, 0.0, 100.0)
				_shift_affinity(social_partner, 15.0 * delta)
			else:
				# REJECTED advance -> spikes Anger and Boredom!
				lust = clampf(lust - 5.0 * delta, 0.0, 100.0)
				anger = clampf(anger + 14.0 * intensity * delta, 0.0, 100.0)
				boredom = clampf(boredom + 8.0 * delta, 0.0, 100.0)
				_shift_affinity(social_partner, -12.0 * delta)

		"Heated Debate":
			talk_need = clampf(talk_need - 14.0 * delta, 0.0, 100.0)
			if conversation_branch == "MUTUAL":
				anger = clampf(anger - 10.0 * delta, 0.0, 100.0)
				purpose = clampf(purpose - 8.0 * delta, 0.0, 100.0)
			else:
				# Escalates hostility!
				anger = clampf(anger + 12.0 * intensity * delta, 0.0, 100.0)
				tired = clampf(tired + 6.0 * delta, 0.0, 100.0)
				_shift_affinity(social_partner, -10.0 * delta)

	queue_redraw()
	if conversation_timer <= 0.0:
		_end_conversation()

func _shift_affinity(partner: NPC, delta_aff: float) -> void:
	if not is_instance_valid(partner):
		return
	var pid: int = partner.get_instance_id()
	var cur: float = affinities.get(pid, 0.0)
	affinities[pid] = clampf(cur + delta_aff, -100.0, 100.0)

func _end_conversation() -> void:
	add_memory("%s [%s]" % [conversation_topic, conversation_branch])
	current_state = NPCState.WANDER
	social_partner = null
	social_cooldown = randf_range(3.0, 5.5)
	_evaluate_utility_brain()
	queue_redraw()

# ==============================================================================
# FOOD SEEKING & CONSUMPTION
# ==============================================================================
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
		velocity = seek_dir * (move_speed * 1.25)
=======
		# Branch: Aggressive NPCs sprint faster toward food; exhausted NPCs trudge
		var speed_mult: float = 1.45 if anger >= 60.0 else (0.85 if tired >= 75.0 else 1.25)
		velocity = seek_dir * (get_effective_move_speed() * speed_mult)
>>>>>>> Stashed changes
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

	velocity = wander_direction * get_effective_move_speed()
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
<<<<<<< Updated upstream
	health = 100.0
	# Hunger starts between 15 and 65
=======
	_release_sleep_spot()
	_release_recreation_spot()
	attack_target = null
	knockback_velocity = Vector2.ZERO
	current_state = NPCState.WANDER
	health = max_health
>>>>>>> Stashed changes
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
	if not is_dead and (show_health_always or health < max_health or is_mouse_hovered or is_selected):
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

<<<<<<< Updated upstream
	# Health Fill
	var hp_ratio: float = clampf(health / 100.0, 0.0, 1.0)
=======
	var hp_ratio: float = clampf(health / max_health, 0.0, 1.0) if max_health > 0.0 else 0.0
>>>>>>> Stashed changes
	if hp_ratio > 0.005:
		var hp_col: Color
		if hp_ratio > 0.5:
			hp_col = Color(0.2, 0.85, 0.35).lerp(Color(0.95, 0.8, 0.15), (1.0 - hp_ratio) * 2.0)
		else:
			hp_col = Color(0.95, 0.8, 0.15).lerp(Color(0.92, 0.2, 0.2), (0.5 - hp_ratio) * 2.0)

		var fill_w: float = (bar_w - 2.0) * hp_ratio
		var fill_rect: Rect2 = Rect2(-bar_w * 0.5 + 1.0, bar_y - bar_h * 0.5 + 1.0, fill_w, bar_h - 2.0)
		draw_rect(fill_rect, hp_col, true)

<<<<<<< Updated upstream
	# Text readout when hovered or actively taking starvation damage
	if font != null and (is_mouse_hovered or hunger >= 100.0 or health < 100.0):
		var hp_text: String = "HP: %d" % int(round(health))
=======
	if font != null and (is_mouse_hovered or is_selected or hunger >= 100.0 or health < max_health):
		var hp_text: String = ("HP: %d/%d" % [int(round(health)), int(round(max_health))]) if not is_equal_approx(max_health, 100.0) else ("HP: %d" % int(round(health)))
>>>>>>> Stashed changes
		if hunger >= 100.0:
			hp_text += " (STARVING)"
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
