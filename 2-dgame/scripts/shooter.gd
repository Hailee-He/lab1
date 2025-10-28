extends CharacterBody2D

@export var speed: float = 140.0
@export var hp: int = 4
@export var attack_range: float = 60.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.5

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

enum State { IDLE, CHASE, ATTACK, HIT, DEAD }
var current_state: State = State.CHASE
var player_ref: Node2D
var attack_timer: float = 0.0
var search_cooldown: float = 0.0
var is_facing_right: bool = true

func _ready() -> void:
	collision_layer = 1 << 2
	collision_mask  = (1 << 1) | (1 << 3) | (1 << 5)
	_find_player()
	anim.play("walk")

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD: return
	if attack_timer > 0.0: attack_timer -= delta

	if not player_ref:
		search_cooldown -= delta
		if search_cooldown <= 0.0:
			_find_player()
			search_cooldown = 2.0

	match current_state:
		State.IDLE:
			_handle_idle()
		State.CHASE:
			_handle_chase()
		State.ATTACK:
			_handle_attack()
		State.HIT:
			velocity = Vector2.ZERO
		_:
			pass

func _handle_chase() -> void:
	if not player_ref:
		current_state = State.IDLE
		return

	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	var new_face := player_ref.global_position.x > global_position.x
	if new_face != is_facing_right:
		is_facing_right = new_face

	if anim.animation != "walk":
		anim.play("walk")

	var d := global_position.distance_to(player_ref.global_position)
	if d <= attack_range and attack_timer <= 0.0:
		current_state = State.ATTACK
		# Godot 4 ternary uses 'A if cond else B'
		if is_facing_right:
			anim.play("attack_right")
		else:
			anim.play("attack_left")
		velocity = Vector2.ZERO
		if player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(attack_damage)

func _handle_attack() -> void:
	velocity = Vector2.ZERO
	if not anim.is_playing():
		attack_timer = attack_cooldown
		current_state = State.CHASE

func _handle_idle() -> void:
	velocity = Vector2.ZERO
	if anim.animation != "idle":
		anim.play("idle")
	if player_ref and global_position.distance_to(player_ref.global_position) <= attack_range * 2.0:
		current_state = State.CHASE

func take_damage(dmg: int) -> void:
	if current_state == State.DEAD: return
	hp -= dmg
	if anim.sprite_frames.has_animation("hit"):
		current_state = State.HIT
		anim.play("hit")
	else:
		current_state = State.CHASE
	if hp <= 0:
		_die()

func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	var game := get_tree().root.get_node("Game")
	if game and game.has_method("on_enemy_killed"):
		game.on_enemy_killed("shooter")
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	_queue_free_with_rewards()

func _queue_free_with_rewards() -> void:
	var game := get_tree().root.get_node("Game")
	if game and game.has_method("add_score"):
		game.add_score(10)
	if game and game.has_method("add_time"):
		game.add_time(2.0)
	queue_free()

func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")
