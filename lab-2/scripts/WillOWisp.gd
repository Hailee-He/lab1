extends CharacterBody2D

# --- Parameters (tweakable in Inspector) ---
@export var max_speed: float = 80.0
@export var max_force: float = 180.0

@export var separation_distance: float = 30.0
@export var player_avoid_distance: float = 120.0
@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var avoid_player_weight: float = 1.2
@export var random_jitter: float = 30.0

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@export var wisp_loop_sound: AudioStream

var rng := RandomNumberGenerator.new()
var neighbors: Array[Node] = []

func _ready() -> void:
	rng.randomize()
	add_to_group("agents")   # group name unified
	
	# Initial random heading
	velocity = Vector2(rng.randf_range(-1,1), rng.randf_range(-1,1)).normalized() * max_speed
	
	# Setup sensing
	$Sensor.body_entered.connect(_on_body_entered)
	$Sensor.body_exited.connect(_on_body_exited)

	# Play looping sound
	if wisp_loop_sound:
		audio_player.stream = wisp_loop_sound
		audio_player.play()

func _physics_process(delta: float) -> void:
	var steering := separation() * separation_weight \
				  + alignment() * alignment_weight \
				  + cohesion() * cohesion_weight \
				  + avoid_player() * avoid_player_weight

	# Random jitter
	steering += Vector2(rng.randf_range(-1,1), rng.randf_range(-1,1)) * random_jitter

	# Limit steering
	if steering.length() > max_force:
		steering = steering.normalized() * max_force
	
	velocity += steering * delta
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	move_and_slide()
	rotation = velocity.angle()

# --- Local sensing ---
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("agents") and body != self:
		neighbors.append(body)

func _on_body_exited(body: Node) -> void:
	neighbors.erase(body)

# --- Rules ---
func separation() -> Vector2:
	var force := Vector2.ZERO
	var count := 0
	for n in neighbors:
		if not is_instance_valid(n): continue
		var d = global_position.distance_to(n.global_position)
		if d > 0 and d < separation_distance:
			force += (global_position - n.global_position).normalized() / d
			count += 1
	if count > 0:
		force = (force / count).normalized() * max_speed - velocity
	return force

func alignment() -> Vector2:
	if neighbors.is_empty(): return Vector2.ZERO
	var avg_vel := Vector2.ZERO
	for n in neighbors:
		if is_instance_valid(n) and "velocity" in n:
			avg_vel += n.velocity
	avg_vel /= neighbors.size()
	return (avg_vel.normalized() * max_speed) - velocity

func cohesion() -> Vector2:
	if neighbors.is_empty(): return Vector2.ZERO
	var center := Vector2.ZERO
	for n in neighbors:
		if is_instance_valid(n):
			center += n.global_position
	center /= neighbors.size()
	return (center - global_position).normalized() * max_speed - velocity

func avoid_player() -> Vector2:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var d = global_position.distance_to(player.global_position)
		if d < player_avoid_distance:
			modulate = Color(1,0.3,0.3)
			return (global_position - player.global_position).normalized() * max_speed - velocity
	modulate = Color(0.3,0.6,1.0)
	return Vector2.ZERO
