extends Area2D

@export var speed := 600.0
@export var lifetime := 1.2
@export var damage := 2
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Enable area monitoring and set collision layers
	monitoring = true
	monitorable = true
	collision_layer = 1 << 3               # Bullet layer
	collision_mask  = (1 << 2) | (1 << 5)  # Hit Enemies + World

	# Connect collision callback
	body_entered.connect(_on_body_entered)

	# Lifetime timer
	var t := Timer.new()
	t.wait_time = lifetime
	t.one_shot = true
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func set_direction(d: Vector2) -> void:
	direction = d.normalized()
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	# Ignore the shooter (player that owns the bullet)
	var shooter := get_tree().get_first_node_in_group("player")
	if body == shooter:
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif body is StaticBody2D:
		queue_free()
