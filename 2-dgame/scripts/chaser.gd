extends CharacterBody2D

@export var speed := 90.0
@export var hp := 4
@export var attack_damage := 1
@export var attack_cooldown := 0.8

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var player_ref: Node2D
var cd := 0.0

func _ready() -> void:
	collision_layer = 1 << 2                     # Enemy layer
	collision_mask  = (1 << 1) | (1 << 3) | (1 << 5) # Player, Bullet, World
	add_to_group("enemies")
	_find_player()
	anim.play("idle")

func _physics_process(delta: float) -> void:
	if hp <= 0: return
	if not player_ref:
		_find_player(); return

	cd = max(cd - delta, 0.0)

	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() == player_ref and cd <= 0.0:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(attack_damage)
			cd = attack_cooldown

func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")

func take_damage(dmg: int) -> void:
	if hp <= 0: return
	hp -= dmg
	if anim.sprite_frames.has_animation("hit"):
		anim.play("hit")
	if hp <= 0: _die()

func _die() -> void:
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	var game := get_tree().root.get_node("Game")
	if game and game.has_method("on_enemy_killed"):
		game.on_enemy_killed("chaser")
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	queue_free()
