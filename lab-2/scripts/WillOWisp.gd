extends CharacterBody2D

# Emergent behavior parameters
@export var speed: float = 50.0
@export var perception_radius: float = 100.0
@export var separation_distance: float = 30.0
@export var player_avoid_distance: float = 120.0

# Emergent behavior weights (adjustable at runtime)
@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0

var rng = RandomNumberGenerator.new()
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.randomize()
	velocity = Vector2(rng.randf_range(-1,1), rng.randf_range(-1,1)).normalized() * speed
	add_to_group("wisp")
	
	# Play wisp loop sound effect
	var wisp_loop_sound = load("res://assets/sounds/wisp_loop.ogg")
	if wisp_loop_sound:
		audio_player.stream = wisp_loop_sound
		audio_player.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var neighbors = get_neighbors()
	var steering = Vector2.ZERO

	# Flocking rules - emergent behavior
	steering += separation(neighbors) * separation_weight
	steering += alignment(neighbors) * alignment_weight
	steering += cohesion(neighbors) * cohesion_weight

	# Environment interaction - avoid player
	steering += avoid_player()
	
	# Random disturbance
	steering += Vector2(rng.randf_range(-0.3,0.3), rng.randf_range(-0.3,0.3))

	# Update movement
	velocity = (velocity + steering).limit_length(speed)
	move_and_slide()

# -Avoid player behavior
func avoid_player() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist < player_avoid_distance:
			# Change color (indicating fear)
			modulate = Color(1, 0.3, 0.3) 
			return (global_position - player.global_position).normalized() * 2.0
		else:
			# Restore blue color
			modulate = Color(0.3, 0.6, 1.0)
	return Vector2.ZERO

# Get neighbors within perception radius
func get_neighbors() -> Array:
	var result = []
	for body in get_tree().get_nodes_in_group("wisp"):
		if body != self and global_position.distance_to(body.global_position) < perception_radius:
			result.append(body)
	return result

# Separation - avoid crowding neighbors
func separation(neighbors: Array) -> Vector2:
	var force = Vector2.ZERO
	for n in neighbors:
		var dist = global_position.distance_to(n.global_position)
		if dist < separation_distance and dist > 0:
			force += (global_position - n.global_position).normalized() / dist
	return force

# Alignment - steer towards average heading of neighbors
func alignment(neighbors: Array) -> Vector2:
	if neighbors.size() == 0:
		return Vector2.ZERO
	var avg_vel = Vector2.ZERO
	for n in neighbors:
		avg_vel += n.velocity
	avg_vel /= neighbors.size()
	return (avg_vel.normalized() - velocity.normalized())

# Cohesion - steer to move toward average position of neighbors
func cohesion(neighbors: Array) -> Vector2:
	if neighbors.size() == 0:
		return Vector2.ZERO
	var center = Vector2.ZERO
	for n in neighbors:
		center += n.global_position
	center /= neighbors.size()
	return (center - global_position).normalized()
