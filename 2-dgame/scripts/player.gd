extends CharacterBody2D

# -------- Tunable Parameters --------
@export var move_speed: float = 140.0
@export var max_health: int = 3
@export var fire_cooldown: float = 0.18
@export var invincible_time: float = 0.5
@export var respawn_time: float = 1.5
@export var bullet_scene: PackedScene = preload("res://scene/bullet.tscn")

# Bullet spawn offsets relative to player center (adjust for your sprite size)
@export var muzzle_offset_px := {
	"up":    Vector2(0, -12),
	"down":  Vector2(0,  12),
	"left":  Vector2(-12, 0),
	"right": Vector2( 12, 0)
}

# -------- Runtime State --------
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var health: int
var lives: int = 3
var facing: String = "down"     # "up"/"down"/"left"/"right"
var shoot_cd: float = 0.0
var invincible: float = 0.0
var is_dead: bool = false
var is_hurt_playing: bool = false
var respawn_position: Vector2 = Vector2(300, 200)
var death_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	health = max_health
	add_to_group("player")
	respawn_position = global_position
	anim.play("idle-down")

	# Ensure non-looping one-shot animations exist
	if anim.sprite_frames.has_animation("hurt"):
		anim.sprite_frames.set_animation_loop("hurt", false)
	if anim.sprite_frames.has_animation("death"):
		anim.sprite_frames.set_animation_loop("death", false)

	respawn_position = global_position

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		if not anim.is_playing() and anim.animation == "death":
			handle_death_complete()
		return

	# Timers
	if shoot_cd > 0.0: shoot_cd -= delta
	if invincible > 0.0: invincible -= delta
	if is_hurt_playing and not anim.is_playing() and anim.animation == "hurt":
		is_hurt_playing = false

	# Movement input
	var input_vec := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	velocity = input_vec * move_speed
	move_and_slide()

	# Facing
	if input_vec.length() > 0.1:
		if abs(input_vec.x) > abs(input_vec.y):
			facing = "right" if input_vec.x > 0 else "left"
		else:
			facing = "down" if input_vec.y > 0 else "up"

	# Animation
	if is_hurt_playing:
		if anim.animation != "hurt":
			anim.play("hurt")
	elif velocity.length() > 0.1:
		anim.play("walk-" + facing)
	else:
		anim.play("idle-" + facing)

	# Shooting
	if Input.is_action_pressed("shoot"):
		_try_shoot()

# -------- Shooting --------
func _try_shoot() -> void:
	if shoot_cd > 0.0 or is_dead or is_hurt_playing:
		return
	shoot_cd = fire_cooldown
	_shoot()

func _shoot() -> void:
	if bullet_scene == null:
		push_error("Bullet scene is null!")
		return
	if anim.sprite_frames.has_animation("shot"):
		anim.play("shot")

	var bullet := bullet_scene.instantiate()

	# Determine direction using match as a statement
	var dir: Vector2 = Vector2.DOWN
	match facing:
		"up":
			dir = Vector2.UP
		"down":
			dir = Vector2.DOWN
		"left":
			dir = Vector2.LEFT
		"right":
			dir = Vector2.RIGHT
		_:
			dir = Vector2.DOWN

	var off: Vector2 = muzzle_offset_px.get(facing, Vector2.ZERO)
	bullet.global_position = global_position + off

	if bullet.has_method("set_direction"):
		bullet.set_direction(dir)

	get_parent().add_child(bullet)

# -------- Damage / Death --------
func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or invincible > 0.0:
		return

	health -= amount
	invincible = invincible_time
	_update_hud_health()

	if health <= 0:
		die()
	else:
		is_hurt_playing = true
		if anim.sprite_frames.has_animation("hurt"):
			anim.play("hurt")
		if knockback != Vector2.ZERO:
			velocity = knockback

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	death_position = global_position
	lives -= 1
	_update_hud_lives()
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
	else:
		handle_death_complete()

func handle_death_complete() -> void:
	if lives > 0:
		respawn()
	else:
		game_over()

func respawn() -> void:
	health = max_health
	global_position = respawn_position
	is_dead = false
	is_hurt_playing = false
	invincible = invincible_time
	_update_hud_health()
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = false
	visible = true
	anim.play("idle-down")

func game_over() -> void:
	var game := get_tree().root.get_node("Game")
	if game and game.has_method("end_game"):
		game.end_game(false)
	else:
		get_tree().reload_current_scene()

# -------- HUD Bridge --------
func _update_hud_health() -> void:
	var game := get_tree().root.get_node("Game")
	if game and game.has_method("update_health"):
		game.update_health(health)

func _update_hud_lives() -> void:
	var game := get_tree().root.get_node("Game")
	if game and game.has_method("update_lives"):
		game.update_lives(lives)

# -------- Utilities --------
func heal(amount: int) -> void:
	if is_dead: return
	health = min(health + amount, max_health)
	_update_hud_health()

func add_life() -> void:
	lives += 1
	_update_hud_lives()

func set_respawn_position(p: Vector2) -> void:
	respawn_position = p
