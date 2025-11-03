# shooter.gd
extends CharacterBody2D
"""
Shooter (higher damage, cannot pass through walls):
- Lives on ENEMY layer.
- Collides with WORLD + PLAYER + ITEMS + BULLET (so it respects walls/items).
- Simple chase + melee "attack" when within range (replace with projectile if needed).
- Supports 'frozen' flag so Game.gd can briefly freeze enemies after player respawn.
"""

# ------------ Tunables ------------
@export var speed: float = 140.0
@export var hp: int = 4
@export var attack_range: float = 60.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.5

# ------------ Runtime ------------
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var player_ref: Node2D
var atk_cd := 0.0
var is_facing_right := true

# Freeze hook (used by respawn protection)
var _frozen := false
func set_frozen(v: bool) -> void:
	_frozen = v

func _ready() -> void:
	# Layers/Masks (using mapping: 1=World,2=Player,3=Enemy,4=Bullet,5=Items)
	# Shooter must NOT pass through world/items, so it collides with them.
	collision_layer = 1 << 2                    # Enemy layer
	collision_mask  = (1 << 0) | (1 << 1) | (1 << 3) | (1 << 4)
	#                    World     Player      Bullet      Items

	add_to_group("enemies")
	_find_player()
	if anim:
		anim.play("walk")

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	if _frozen:
		velocity = Vector2.ZERO
		return

	atk_cd = max(0.0, atk_cd - delta)

	if not player_ref:
		_find_player()
		return

	# Basic pathing: straight-line chase.
	# If you want smarter navigation, swap to a NavigationAgent2D.
	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()   # collides with world/items because of mask above

	is_facing_right = player_ref.global_position.x > global_position.x
	if anim.animation != "walk":
		anim.play("walk")

	# Melee-style hit when close enough
	if global_position.distance_to(player_ref.global_position) <= attack_range and atk_cd <= 0.0:
		atk_cd = attack_cooldown
		velocity = Vector2.ZERO
		if anim:
			anim.play("attack_right" if is_facing_right else "attack_left")
		if player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(attack_damage)

func take_damage(dmg: int) -> void:
	if hp <= 0:
		return
	hp -= dmg
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("hit"):
		anim.play("hit")
	if hp <= 0:
		_die()

func _die() -> void:
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	var game := get_tree().root.get_node("Game")
	if game and game.has_method("on_enemy_killed"):
		game.on_enemy_killed("shooter")
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	queue_free()

func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")
