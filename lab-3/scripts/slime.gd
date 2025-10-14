extends CharacterBody2D

# --- Tunables ---
@export var speed: float = 40.0
@export var patrol_distance: float = 80.0      # patrol half-width
@export var gravity: float = 900.0
@export var damage: int = 1

# --- Cached nodes ---
@onready var anim: AnimatedSprite2D = $Anim
@onready var hitbox: Area2D = $Hitbox

# --- Runtime state ---
var dir := 1                                    # 1 -> right, -1 -> left
var left_x := 0.0                               # left patrol bound
var right_x := 0.0                              # right patrol bound

func _ready() -> void:
	# For filtering / quick lookups
	add_to_group("enemy")

	# Set initial animation and patrol bounds
	anim.play("move")
	left_x  = global_position.x - patrol_distance
	right_x = global_position.x + patrol_distance

	# Detect both bodies (player CharacterBody2D) and areas (player Hurtbox Area2D)
	hitbox.body_entered.connect(_on_body_entered)
	hitbox.area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	# Simple ground stick
	if not is_on_floor():
		velocity.y += gravity * delta

	# Horizontal patrol
	velocity.x = dir * speed
	move_and_slide()

	# Turn around when hitting a wall or reaching patrol bounds
	if is_on_wall() or global_position.x <= left_x or global_position.x >= right_x:
		dir *= -1
		anim.flip_h = dir < 0

# --- Damage helpers (work with either Player body or Player.Hurtbox area) ---
func _deal_damage(target: Node) -> void:
	if target.is_in_group("player"):
		# Prefer take_damage if present; fall back to hurt for older scripts
		if "take_damage" in target:
			target.take_damage(damage)
		elif "hurt" in target:
			target.hurt(damage)

func _on_body_entered(b: Node) -> void:
	_deal_damage(b)

func _on_area_entered(a: Area2D) -> void:
	var p := a.get_parent()
	if p and p.is_in_group("player"):
		_deal_damage(p)
