class_name NPC
extends CharacterBody2D

## Signals
signal hover_changed(is_hovered: bool)
signal died(npc: NPC)
signal foraging_completed(pos: Vector2, amount: float)

const HUNGRY_THRESHOLD: float = 40.0

# ==============================================================================
# HEALTH (0 to 100)
# ==============================================================================
@export_group("Health")
@export_range(0.0, 100.0) var health: float = 100.0:
	set(v):
		health = clampf(v, 0.0, 100.0)
		if not is_dead and health <= 0.0:
			die()
		else:
			queue_redraw()

@export var show_health_always: bool = true

# ==============================================================================
# 8 NEEDS (0 to 100)
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
# PASSIVE GROWTH RATES (pts/sec: -5.0 to +15.0)
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

# ==============================================================================
# PERSONALITY ARCHETYPES & BRANCHING STATE MACHINE
# ==============================================================================
enum NPCState {
	WANDER,
	SEEKING_FOOD,
	SLEEPING,
	SEEKING_SOCIAL,
	IN_CONVERSATION,
	PURSUING_PURPOSE,
	RELIEVING_BOREDOM,
	FLEEING
}

const PERSONALITY_ARCHETYPES: Array[Dictionary] = [
	{
		"name": "Hot-Head",
		"tint": Color(0.95, 0.32, 0.32),
		"weights": {"hunger": 1.0, "sleep_need": 0.85, "talk_need": 0.9, "tired": 0.8, "boredom": 1.3, "lust": 1.0, "purpose": 0.8, "fight": 1.75},
		"fight_c": 0.34, "lust_c": 0.55
	},
	{
		"name": "Romantic",
		"tint": Color(0.95, 0.42, 0.68),
		"weights": {"hunger": 0.9, "sleep_need": 0.9, "talk_need": 1.35, "tired": 1.0, "boredom": 1.2, "lust": 1.75, "purpose": 0.75, "fight": 0.5},
		"fight_c": 0.72, "lust_c": 0.32
	},
	{
		"name": "Chatterbox",
		"tint": Color(0.25, 0.85, 0.92),
		"weights": {"hunger": 0.95, "sleep_need": 0.9, "talk_need": 1.8, "tired": 0.9, "boredom": 1.4, "lust": 1.1, "purpose": 0.85, "fight": 0.65},
		"fight_c": 0.65, "lust_c": 0.48
	},
	{
		"name": "Workaholic",
		"tint": Color(0.28, 0.88, 0.52),
		"weights": {"hunger": 0.85, "sleep_need": 0.75, "talk_need": 0.7, "tired": 0.75, "boredom": 0.6, "lust": 0.6, "purpose": 1.85, "fight": 0.9},
		"fight_c": 0.58, "lust_c": 0.65
	},
	{
		"name": "Glutton",
		"tint": Color(0.98, 0.62, 0.22),
		"weights": {"hunger": 1.8, "sleep_need": 1.2, "talk_need": 0.9, "tired": 1.25, "boredom": 1.1, "lust": 0.85, "purpose": 0.7, "fight": 0.85},
		"fight_c": 0.55, "lust_c": 0.55
	},
	{
		"name": "Sloth",
		"tint": Color(0.58, 0.48, 0.92),
		"weights": {"hunger": 1.0, "sleep_need": 1.75, "talk_need": 0.75, "tired": 1.7, "boredom": 0.7, "lust": 0.7, "purpose": 0.55, "fight": 0.45},
		"fight_c": 0.78, "lust_c": 0.65
	},
	{
		"name": "Hedonist",
		"tint": Color(0.96, 0.78, 0.22),
		"weights": {"hunger": 1.2, "sleep_need": 0.9, "talk_need": 1.3, "tired": 0.95, "boredom": 1.75, "lust": 1.5, "purpose": 0.5, "fight": 1.1},
		"fight_c": 0.48, "lust_c": 0.36
	},
	{
		"name": "Balanced",
		"tint": Color(0.75, 0.82, 0.9),
		"weights": {"hunger": 1.0, "sleep_need": 1.0, "talk_need": 1.0, "tired": 1.0, "boredom": 1.0, "lust": 1.0, "purpose": 1.0, "fight": 1.0},
		"fight_c": 0.52, "lust_c": 0.52
	}
]

var personality_name: String = "Balanced"
var personality_tint: Color = Color(0.85, 0.88, 0.92)
var personality_weights: Dictionary = {
	"hunger": 1.0, "sleep_need": 1.0, "talk_need": 1.0, "tired": 1.0,
	"boredom": 1.0, "lust": 1.0, "purpose": 1.0, "fight": 1.0
}
var fight_threshold: float = 0.52
var lust_threshold: float = 0.52

# State machine & branching variables
var current_state: NPCState = NPCState.WANDER
var state_label_text: String = "Wandering"
var decision_timer: float = 0.0
var purpose_target: Vector2 = Vector2.ZERO
var purpose_progress: float = 0.0
var boredom_branch: String = "Spin"
var orbit_angle: float = 0.0
var flee_target: NPC = null
var flee_timer: float = 0.0

# Social / Dyadic Conversation state (Talk / Lust / Fight Averaging Engine)
var social_partner: NPC = null
var social_cooldown: float = 0.0
var conversation_timer: float = 0.0
var conversation_topic: String = ""
var conversation_branch: String = "" # "MUTUAL", "REJECTED", "BRAWL"
var conversation_value_rate: float = 0.0 # Mapped to [-5.0, +15.0] pts/s scale
var conversation_color: Color = Color.CYAN
var affinities: Dictionary = {} # instance_id -> float [-100.0, 100.0]
var recent_memories: Array[String] = [] # Bounded 8-slot memory log

var is_mouse_hovered: bool = false
var is_dead: bool = false
var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var arena_bounds: Rect2 = Rect2()

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	add_to_group("npcs")
	input_pickable = true
	collision_layer = 1
	collision_mask = (1 | 2) if collide_with_npcs else 2
	_update_collision_shape()

	if get_parent() == get_tree().root:
		global_position = get_viewport_rect().size * 0.5

	assign_random_personality()
	_pick_new_wander()
	_pick_new_purpose_target()

func _update_collision_shape() -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = body_radius

## Assigns one of the 8 Personality Archetypes with slight individual jitter
func assign_random_personality() -> void:
	var arch: Dictionary = PERSONALITY_ARCHETYPES[randi() % PERSONALITY_ARCHETYPES.size()]
	personality_name = arch["name"]
	personality_tint = arch["tint"]
	body_outline_color = personality_tint
	fight_threshold = clampf(arch["fight_c"] + randf_range(-0.06, 0.06), 0.22, 0.85)
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

## Returns true if hunger >= 40.0
func is_hungry() -> bool:
	return hunger >= HUNGRY_THRESHOLD

# ==============================================================================
# INFINITE AXIS UTILITY SYSTEM (IAUS) RESPONSE CURVES
# Combines 0-100 tank and -5.0..+15.0 pts/s rate into a [0.0, 1.0] Utility Score
# ==============================================================================
func get_drive_utility(prop: String) -> float:
	var val: float = get(prop)
	var rate_prop: String = prop + "_rate"
	var rate: float = get(rate_prop) if (rate_prop in self) else 1.0

	# Normalize tank [0, 100] -> [0, 1] and rate [-5, +15] -> [0, 1]
	var norm_tank: float = clampf(val / 100.0, 0.0, 1.0)
	var norm_rate: float = clampf((rate + 5.0) / 20.0, 0.0, 1.0)

	# Blend accumulated state with immediate rate shock
	var alpha: float = 0.65 if (prop in ["fight", "lust", "tired"]) else 0.85
	var x: float = clampf(alpha * norm_tank + (1.0 - alpha) * norm_rate, 0.0, 1.0)

	var u: float = x
	match prop:
		"hunger":
			# Cubic survival curve (accelerates sharply above 40-70%)
			u = pow(x, 2.2) if val < 40.0 else pow(x, 1.35)
		"sleep_need":
			u = pow(x, 2.6)
		"tired":
			u = pow(x, 2.1)
		"fight":
			# Logistic Sigmoid curve governed by personality fight_threshold
			u = 1.0 / (1.0 + exp(-12.0 * (x - fight_threshold)))
		"lust":
			# Logistic Sigmoid curve governed by personality lust_threshold
			u = 1.0 / (1.0 + exp(-11.0 * (x - lust_threshold)))
		"talk_need":
			u = pow(x, 1.15)
		"purpose":
			u = pow(x, 0.95)
		"boredom":
			u = pow(x, 1.6)

	var w: float = personality_weights.get(prop, 1.0)
	return clampf(u * (0.65 + 0.35 * w), 0.0, 1.25)

func _process(delta: float) -> void:
	if is_dead:
		return

	if social_cooldown > 0.0:
		social_cooldown = maxf(0.0, social_cooldown - delta)

	if passive_growth_enabled:
		_process_passive_growth(delta)

	_check_mouse_hover()
	z_index = 100 if is_mouse_hovered else 0

func _process_passive_growth(delta: float) -> void:
	if is_dead:
		return

	var needs_redraw: bool = false
	for need in NEED_DEFINITIONS:
		var prop: String = need["prop"]
		var rate: float = get(need["rate_prop"])
		# Personality weight subtly scales positive build-up rates
		var p_weight: float = personality_weights.get(prop, 1.0)
		var effective_rate: float = rate * (p_weight if rate > 0.0 else 1.0)

		if effective_rate != 0.0:
			var cur_val: float = get(prop)
			var new_val: float = clampf(cur_val + effective_rate * delta, 0.0, 100.0)
			if new_val != cur_val:
				set(prop, new_val)
				if is_mouse_hovered or (prop == "hunger" and new_val >= 40.0):
					needs_redraw = true

	# Starvation damage when hunger == 100
	if hunger >= 100.0 and hunger_rate > 0.0:
		var health_loss: float = hunger_rate * delta
		var new_health: float = clampf(health - health_loss, 0.0, 100.0)
		if new_health != health:
			health = new_health
			needs_redraw = true
		if health <= 0.0:
			die()
			return

	if needs_redraw or current_state == NPCState.IN_CONVERSATION:
		queue_redraw()

# ==============================================================================
# CORE AI LOOP & PRIORITY BUCKETING
# ==============================================================================
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not can_move or (pause_on_hover and is_mouse_hovered):
		return

	# 1. If locked in an active dyadic conversation/brawl, process it
	if current_state == NPCState.IN_CONVERSATION:
		_process_active_conversation(delta)
		return

	# 2. If actively fleeing a bully/brawler
	if current_state == NPCState.FLEEING:
		_process_fleeing(delta)
		return

	# 3. If sleeping, continue until rested (unless starving emergency)
	if current_state == NPCState.SLEEPING:
		if hunger >= 92.0 and _find_nearest_food() != null:
			current_state = NPCState.SEEKING_FOOD
		else:
			_process_sleeping(delta)
			return

	# 4. Evaluate Utility Brain periodically to pick winning directive
	decision_timer -= delta
	if decision_timer <= 0.0:
		decision_timer = randf_range(0.35, 0.65)
		_evaluate_utility_brain()

	# 5. Execute active state branch
	match current_state:
		NPCState.SEEKING_FOOD:
			var target_food = _find_nearest_food()
			if target_food != null and hunger >= 20.0:
				_path_towards_food(target_food, delta)
			else:
				_evaluate_utility_brain()
				_handle_movement(delta)
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

	# BUCKET 1: Critical Survival Emergency (Starving or Exhaustion Collapse)
	if (hunger >= 75.0 or (is_hungry() and hunger >= 55.0)) and has_food_available:
		current_state = NPCState.SEEKING_FOOD
		state_label_text = "Rushing to Food!" if fight >= 60.0 else "Seeking Food"
		return

	if sleep_need >= 88.0 or tired >= 90.0:
		current_state = NPCState.SLEEPING
		state_label_text = "Exhausted (Sleeping)"
		return

	# Score all candidate directives via Utility Curves
	var u_hunger: float = get_drive_utility("hunger") if (is_hungry() and has_food_available) else 0.0
	var u_rest: float = maxf(get_drive_utility("sleep_need"), get_drive_utility("tired")) if (sleep_need >= 60.0 or tired >= 65.0) else 0.0
	var u_social: float = maxf(get_drive_utility("talk_need"), maxf(get_drive_utility("lust"), get_drive_utility("fight")))
	if social_cooldown > 0.0 or maxf(talk_need, maxf(lust, fight)) < 38.0:
		u_social *= 0.25

	var u_purpose: float = get_drive_utility("purpose") if purpose >= 35.0 else 0.0
	var u_boredom: float = get_drive_utility("boredom") if boredom >= 45.0 else 0.0

	# Find highest utility winner
	var best_u: float = 0.28 # Minimum threshold to leave idle wander
	var best_state: NPCState = NPCState.WANDER

	if u_hunger > best_u:
		best_u = u_hunger
		best_state = NPCState.SEEKING_FOOD
	if u_rest > best_u:
		best_u = u_rest
		best_state = NPCState.SLEEPING
	if u_social > best_u:
		best_u = u_social
		best_state = NPCState.SEEKING_SOCIAL
	if u_purpose > best_u:
		best_u = u_purpose
		best_state = NPCState.PURSUING_PURPOSE
	if u_boredom > best_u:
		best_u = u_boredom
		best_state = NPCState.RELIEVING_BOREDOM

	current_state = best_state

	# Configure sub-branches based on secondary drives!
	match current_state:
		NPCState.SEEKING_FOOD:
			state_label_text = "Aggressive Forage" if fight >= 60.0 else "Seeking Food"
		NPCState.SLEEPING:
			state_label_text = "Sleeping (Zzz)"
		NPCState.SEEKING_SOCIAL:
			if fight >= lust and fight >= talk_need and fight >= 50.0:
				state_label_text = "Looking for a Fight"
			elif lust >= talk_need and lust >= 50.0:
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
			if fight >= 58.0:
				boredom_branch = "Rowdy"
				state_label_text = "Bored: Rowdy Sprint"
			elif talk_need >= 50.0 or lust >= 50.0:
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
func _process_sleeping(delta: float) -> void:
	velocity = Vector2.ZERO
	# Actively relieve Sleep and Tired while resting
	sleep_need = clampf(sleep_need - 18.0 * delta, 0.0, 100.0)
	tired = clampf(tired - 22.0 * delta, 0.0, 100.0)
	# Slight health recovery while resting if not starving
	if hunger < 85.0 and health < 100.0:
		health = clampf(health + 2.5 * delta, 0.0, 100.0)

	if sleep_need <= 12.0 and tired <= 15.0:
		current_state = NPCState.WANDER
		state_label_text = "Refreshed!"
		add_memory("Woke up feeling refreshed")
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
		velocity = to_target.normalized() * (move_speed * spd_mult)
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
	var spd: float = move_speed * (1.35 if boredom_branch == "Rowdy" else 1.1)
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
	velocity = away_dir * (move_speed * 1.45)
	tired = clampf(tired + 6.0 * delta, 0.0, 100.0)
	move_and_slide()
	_enforce_arena_bounds()

# ==============================================================================
# TALK / LUST / FIGHT AVERAGING SOCIAL ENGINE
# ==============================================================================
func _process_social_seeking(delta: float) -> void:
	if not is_instance_valid(social_partner) or social_partner.is_dead or social_partner.current_state == NPCState.IN_CONVERSATION:
		social_partner = _find_best_social_partner()

	if social_partner == null:
		# Nobody available right now; wander and burn a tiny bit of restlessness
		_handle_movement(delta)
		return

	var to_partner: Vector2 = social_partner.global_position - global_position
	var dist: float = to_partner.length()
	var social_range: float = body_radius + social_partner.body_radius + 26.0

	if dist <= social_range:
		_initiate_dyadic_interaction(social_partner)
	else:
		velocity = to_partner.normalized() * (move_speed * 1.15)
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

	for node in npcs:
		if node == self or not is_instance_valid(node) or not (node is NPC):
			continue
		var other: NPC = node as NPC
		if other.is_dead or other.current_state == NPCState.IN_CONVERSATION or other.current_state == NPCState.SLEEPING:
			continue
		if other.social_cooldown > 0.0:
			continue

		var d: float = global_position.distance_to(other.global_position)
		if d > 480.0:
			continue

		# Score partner by proximity + dyadic Talk/Lust/Fight average potential
		var avg_social: float = ((talk_need + other.talk_need) + (lust + other.lust) + (fight + other.fight)) / 6.0
		var prox_score: float = (480.0 - d) * 0.15
		var score: float = avg_social + prox_score
		if score > best_score:
			best_score = score
			best_npc = other

	return best_npc

## Computes the Averages of Talk, Lust, and Fight to decide Conversation Topic, Value & Branch
func _initiate_dyadic_interaction(partner: NPC) -> void:
	if partner.current_state == NPCState.IN_CONVERSATION or partner.is_dead:
		return

	# 1. Compute Pairwise Averages (0 to 100 scale) and Asymmetry Gaps
	var avg_talk: float = (talk_need + partner.talk_need) * 0.5
	var avg_lust: float = (lust + partner.lust) * 0.5
	var avg_fight: float = (fight + partner.fight) * 0.5

	var gap_talk: float = absf(talk_need - partner.talk_need)
	var gap_lust: float = absf(lust - partner.lust)
	var gap_fight: float = absf(fight - partner.fight)

	var prior_affinity: float = affinities.get(partner.get_instance_id(), 0.0)

	# 2. Score Conversation Topics using Single & Compound Averages
	var topic_scores: Dictionary = {
		"Deep Chat":          avg_talk * (1.0 - (avg_lust + avg_fight) / 220.0),
		"Flirty Banter":      (avg_talk + avg_lust) * 0.5,
		"Passionate Romance": avg_lust * (1.0 - avg_fight / 140.0) + (prior_affinity * 0.15),
		"Heated Debate":      (avg_talk + avg_fight) * 0.5,
		"Jealous Drama":      (avg_lust + avg_fight) * 0.5,
		"Brawl":              avg_fight * (1.0 - avg_talk / 220.0) - (prior_affinity * 0.15)
	}

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
			branch = "MUTUAL" if gap_fight < 35.0 else "REJECTED"
		"Jealous Drama", "Brawl":
			topic_col = Color(0.92, 0.2, 0.2) # Crimson
			# If one NPC has very low fight compared to the aggressor, they FLEE!
			if gap_fight >= 38.0 and minf(fight, partner.fight) < 35.0:
				var coward: NPC = self if fight < partner.fight else partner
				var bully: NPC = partner if coward == self else self
				coward.current_state = NPCState.FLEEING
				coward.flee_target = bully
				coward.flee_timer = 2.6
				coward.state_label_text = "Fleeing from %s!" % bully.personality_name
				coward.add_memory("Fled from a brawl!")
				bully.fight = clampf(bully.fight - 15.0, 0.0, 100.0)
				bully.purpose = clampf(bully.purpose - 8.0, 0.0, 100.0)
				bully.state_label_text = "Intimidated rival!"
				bully.social_cooldown = 3.0
				return
			branch = "BRAWL"

	# Lock both NPCs into the synchronized conversation state
	var duration: float = 2.4
	_enter_conversation_lock(partner, chosen_topic, branch, rate_value, topic_col, duration)
	partner._enter_conversation_lock(self, chosen_topic, branch, rate_value, topic_col, duration)

func _enter_conversation_lock(partner: NPC, topic: String, branch: String, val_rate: float, col: Color, duration: float) -> void:
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
				# Awkward / one-sided chat
				talk_need = clampf(talk_need - 6.0 * delta, 0.0, 100.0)
				boredom = clampf(boredom + 9.0 * delta, 0.0, 100.0)
				_shift_affinity(social_partner, -4.0 * delta)

		"Flirty Banter", "Passionate Romance":
			if conversation_branch == "MUTUAL":
				lust = clampf(lust - 20.0 * intensity * delta, 0.0, 100.0)
				talk_need = clampf(talk_need - 14.0 * intensity * delta, 0.0, 100.0)
				boredom = clampf(boredom - 15.0 * intensity * delta, 0.0, 100.0)
				fight = clampf(fight - 8.0 * delta, 0.0, 100.0)
				_shift_affinity(social_partner, 15.0 * delta)
			else:
				# REJECTED advance -> spikes Fight and Boredom!
				lust = clampf(lust - 5.0 * delta, 0.0, 100.0)
				fight = clampf(fight + 14.0 * intensity * delta, 0.0, 100.0)
				boredom = clampf(boredom + 8.0 * delta, 0.0, 100.0)
				_shift_affinity(social_partner, -12.0 * delta)

		"Heated Debate":
			talk_need = clampf(talk_need - 14.0 * delta, 0.0, 100.0)
			if conversation_branch == "MUTUAL":
				fight = clampf(fight - 10.0 * delta, 0.0, 100.0)
				purpose = clampf(purpose - 8.0 * delta, 0.0, 100.0)
			else:
				# Escalates hostility!
				fight = clampf(fight + 12.0 * intensity * delta, 0.0, 100.0)
				tired = clampf(tired + 6.0 * delta, 0.0, 100.0)
				_shift_affinity(social_partner, -10.0 * delta)

		"Jealous Drama", "Brawl":
			# Physical brawl vents Fight rapidly, costs Health & Stamina (Tired)
			fight = clampf(fight - 22.0 * delta, 0.0, 100.0)
			tired = clampf(tired + 14.0 * delta, 0.0, 100.0)
			boredom = clampf(boredom - 10.0 * delta, 0.0, 100.0)
			health = clampf(health - (4.5 * intensity * delta), 0.0, 100.0)
			_shift_affinity(social_partner, -20.0 * delta)

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
func _find_nearest_food() -> Food:
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree == null:
		return null
	var foods = tree.get_nodes_in_group("food")
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

func _path_towards_food(target_food: Food, _delta: float) -> void:
	var to_food: Vector2 = target_food.global_position - global_position
	var dist: float = to_food.length()
	var eat_range: float = body_radius + target_food.radius + 6.0

	if dist <= eat_range:
		_eat_food(target_food)
		velocity = Vector2.ZERO
	else:
		var seek_dir = to_food.normalized()
		# Branch: Aggressive NPCs sprint faster toward food; exhausted NPCs trudge
		var speed_mult: float = 1.45 if fight >= 60.0 else (0.85 if tired >= 75.0 else 1.25)
		velocity = seek_dir * (move_speed * speed_mult)
		var collided = move_and_slide()
		if collided and get_slide_collision_count() > 0:
			var col = get_slide_collision(0)
			wander_direction = wander_direction.bounce(col.get_normal()).normalized()

func _eat_food(target_food: Food) -> void:
	if not is_instance_valid(target_food) or target_food.is_depleted or target_food.amount <= 0.0:
		return

	var needed_food: float = hunger
	if needed_food <= 0.0:
		return

	var spent: float = target_food.consume(needed_food)
	hunger = clampf(hunger - spent, 0.0, 100.0)
	add_memory("Ate %d pts of food" % int(round(spent)))

	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.15, 0.88), 0.08).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)

	_evaluate_utility_brain()
	queue_redraw()

# ==============================================================================
# HOVER & BASE MOVEMENT
# ==============================================================================
func _check_mouse_hover() -> void:
	if is_dead:
		return

	var mouse_pos = get_global_mouse_position()
	var dist_sq = global_position.distance_squared_to(mouse_pos)

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

	velocity = wander_direction * move_speed
	var collided = move_and_slide()
	if collided and get_slide_collision_count() > 0:
		var col = get_slide_collision(0)
		wander_direction = wander_direction.bounce(col.get_normal()).normalized()

	_enforce_arena_bounds()

func _enforce_arena_bounds() -> void:
	if not bounce_screen_bounds:
		return
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
	if randf() < 0.8:
		wander_direction = Vector2.from_angle(randf() * TAU)
	else:
		wander_direction = Vector2.ZERO

func die() -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group("npcs")
	died.emit(self)

	can_move = false
	velocity = Vector2.ZERO
	input_pickable = false
	is_mouse_hovered = false
	collision_layer = 0
	collision_mask = 0
	queue_redraw()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", scale * 0.7, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:r", 1.5, 0.25)
	tween.chain().tween_callback(queue_free)

func randomize_needs() -> void:
	health = 100.0
	hunger = randf_range(15.0, 65.0)
	sleep_need = randf_range(10.0, 75.0)
	talk_need = randf_range(20.0, 85.0)
	tired = randf_range(10.0, 70.0)
	boredom = randf_range(20.0, 85.0)
	lust = randf_range(15.0, 80.0)
	purpose = randf_range(25.0, 85.0)
	fight = randf_range(10.0, 75.0)
	assign_random_personality()
	_evaluate_utility_brain()

func set_need_rate(prop_name: String, rate: float) -> void:
	for need in NEED_DEFINITIONS:
		if need["prop"] == prop_name or need["rate_prop"] == prop_name:
			set(need["rate_prop"], rate)
			return

func set_all_rates(rate: float) -> void:
	for need in NEED_DEFINITIONS:
		set(need["rate_prop"], rate)

# ==============================================================================
# DRAWING (RADIAL BARS + SOCIAL CONNECTION LINE + STATE/PERSONALITY PILL)
# ==============================================================================
func _draw() -> void:
	# 0. Draw live social connection beam if conversing/brawling with a partner
	if current_state == NPCState.IN_CONVERSATION and is_instance_valid(social_partner) and not social_partner.is_dead:
		var rel_partner: Vector2 = social_partner.global_position - global_position
		draw_line(Vector2.ZERO, rel_partner * 0.5, conversation_color, 3.0, true)
		draw_circle(rel_partner * 0.5, 4.0, conversation_color.lightened(0.3))

	# 1. Circle body
	var active_outline: Color = Color.WHITE if is_mouse_hovered else body_outline_color
	var active_width: float = body_outline_width + (1.0 if is_mouse_hovered else 0.0)

	if is_mouse_hovered and not is_dead:
		draw_circle(Vector2.ZERO, body_radius + 4.0, Color(1, 1, 1, 0.18))

	draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_circle(Vector2.ZERO, body_radius * 0.65, body_color.lightened(0.12))

	if is_hungry() and not is_mouse_hovered:
		var hungry_glow = Color(0.98, 0.52, 0.12, 0.85)
		draw_arc(Vector2.ZERO, body_radius, 0.0, TAU, 36, hungry_glow, active_width + 0.5, true)
	else:
		draw_arc(Vector2.ZERO, body_radius, 0.0, TAU, 36, active_outline, active_width, true)

	var pip_color = Color(0.98, 0.52, 0.12) if is_hungry() else personality_tint
	draw_circle(Vector2.ZERO, 3.5, pip_color)

	# 2. Draw the 8 radial bars ONLY if mouse is over the NPC
	if is_mouse_hovered and not is_dead:
		_draw_bars()

	# 3. Draw health bar
	if not is_dead and (show_health_always or health < 100.0 or is_mouse_hovered):
		_draw_health_bar()

	# 4. Draw Personality & Active Branch / Conversation Topic Pill below NPC
	if not is_dead and (show_labels or is_mouse_hovered or current_state == NPCState.IN_CONVERSATION):
		_draw_state_pill()

func _draw_state_pill() -> void:
	var font = ThemeDB.fallback_font
	if font == null:
		return

	var y_offset: float = (body_radius + bar_length + 26.0) if is_mouse_hovered else (body_radius + 15.0)
	var text: String = "[%s] %s" % [personality_name, state_label_text]
	var font_size: int = 9
	var sz: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pill_rect: Rect2 = Rect2(Vector2(-sz.x * 0.5 - 5.0, y_offset - 10.0), Vector2(sz.x + 10.0, 14.0))

	var border_col: Color = conversation_color if current_state == NPCState.IN_CONVERSATION else personality_tint
	draw_rect(pill_rect, Color(0.06, 0.08, 0.11, 0.88), true)
	draw_rect(pill_rect, border_col * 0.85, false, 1.0)
	draw_string(font, Vector2(pill_rect.position.x + 5.0, pill_rect.position.y + 10.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func _draw_health_bar() -> void:
	var font = ThemeDB.fallback_font
	var bar_y: float = -(body_radius + bar_length + 28.0) if is_mouse_hovered else -(body_radius + 9.0)
	var bar_w: float = 32.0
	var bar_h: float = 5.0
	var bar_rect: Rect2 = Rect2(-bar_w * 0.5, bar_y - bar_h * 0.5, bar_w, bar_h)

	draw_rect(bar_rect, Color(0.06, 0.08, 0.1, 0.9), true)

	var border_col: Color = Color(0.3, 0.36, 0.45, 0.9)
	if hunger >= 100.0 or (current_state == NPCState.IN_CONVERSATION and conversation_branch == "BRAWL"):
		var pulse: float = sin(Time.get_ticks_msec() * 0.012) * 0.5 + 0.5
		border_col = Color(1.0, 0.25, 0.25, 1.0).lerp(Color(0.5, 0.1, 0.1, 0.9), pulse)
	draw_rect(bar_rect, border_col, false, 1.0)

	var hp_ratio: float = clampf(health / 100.0, 0.0, 1.0)
	if hp_ratio > 0.005:
		var hp_col: Color
		if hp_ratio > 0.5:
			hp_col = Color(0.2, 0.85, 0.35).lerp(Color(0.95, 0.8, 0.15), (1.0 - hp_ratio) * 2.0)
		else:
			hp_col = Color(0.95, 0.8, 0.15).lerp(Color(0.92, 0.2, 0.2), (0.5 - hp_ratio) * 2.0)

		var fill_w: float = (bar_w - 2.0) * hp_ratio
		var fill_rect: Rect2 = Rect2(-bar_w * 0.5 + 1.0, bar_y - bar_h * 0.5 + 1.0, fill_w, bar_h - 2.0)
		draw_rect(fill_rect, hp_col, true)

	if font != null and (is_mouse_hovered or hunger >= 100.0 or health < 100.0):
		var hp_text: String = "HP: %d" % int(round(health))
		if hunger >= 100.0:
			hp_text = "HP: %d (STARVING)" % int(round(health))
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

		draw_line(start_pt, max_pt, Color(0.08, 0.1, 0.12, 0.8), bar_thickness + 2.0, true)
		draw_line(start_pt, max_pt, Color(0.24, 0.28, 0.34, 0.9), bar_thickness, true)

		if ratio > 0.01:
			draw_line(start_pt, fill_pt, color, bar_thickness, true)
			draw_circle(fill_pt, bar_thickness * 0.5, color.lightened(0.25))

		var perp = dir.orthogonal() * (bar_thickness * 0.8)
		draw_line(max_pt - perp, max_pt + perp, Color(0.75, 0.8, 0.88, 0.85), 1.5, true)

		if show_labels and font != null:
			var label_dist: float = end_dist + 14.0
			var center_pos: Vector2 = dir * label_dist
			var w_mult: float = personality_weights.get(need["prop"], 1.0)
			var text: String = "%s: %d (x%.1f)" % [need["name"], int(round(val)), w_mult]
			if need["prop"] == "hunger" and val >= HUNGRY_THRESHOLD:
				text = "%s: %d (HUNGRY)" % [need["name"], int(round(val))]

			var font_size: int = 10
			var str_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)

			var pill_rect: Rect2 = Rect2(center_pos - (str_size * 0.5) - Vector2(4, 2), str_size + Vector2(8, 4))
			draw_rect(pill_rect, Color(0.08, 0.1, 0.12, 0.92), true)
			draw_rect(pill_rect, color * 0.7, false, 1.0)

			var text_pos: Vector2 = Vector2(
				pill_rect.position.x + 4.0,
				pill_rect.position.y + pill_rect.size.y - 4.0
			)
			draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)