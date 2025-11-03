extends CharacterBody2D
"""
Ghost-like chaser:
- Moves straight toward the player.
- CAN pass through walls/tiles and items (no world collisions).
- Still collides / interacts with the Player and can be hit by Bullets.
- Low damage, short cooldown.
- Supports 'frozen' state so Game.gd can briefly freeze all enemies after respawn.
"""

# ------------ Tunables ------------
@export var speed: float = 90.0
@export var hp: int = 4
@export var attack_damage: int = 1
@export var attack_cooldown: float = 0.8
@export var touch_damage_radius: float = 16.0   # distance check fallback (pixels)

# ------------ Runtime ------------
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var player_ref: Node2D
var hit_cd := 0.0

# Freeze hook (used by respawn protection)
var _frozen := false
func set_frozen(v: bool) -> void:
	_frozen = v

func _ready() -> void:
	# Layers/Masks (using your scheme):
	# 1 = World, 2 = Player, 3 = Enemy, 4 = Bullet, 5 = Items
	# Chaser should be on ENEMY layer (3), and only collide with PLAYER (2) and BULLET (4).
	# => It will NOT collide with World (1) or Items (5) => it can pass through walls/items.
	collision_layer = 1 << 2             # Enemy layer
	collision_mask  = (1 << 1) | (1 << 3) # collide with Player + Bullet only

	add_to_group("enemies")

	_find_player()

	if anim:
		anim.play("idle")

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	if _frozen:
		velocity = Vector2.ZERO
		return

	hit_cd = max(0.0, hit_cd - delta)

	if not player_ref:
		_find_player()
		return

	# Homing movement towards the player
	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()  # no world collisions because mask excludes World

	# Damage trigger — two ways to be robust:
	# 1) If physical slide collision with the Player occurred (depends on Player mask),
	# 2) OR fallback to a simple distance check (works even if slide collisions don't fire).
	var did_hit := false

	# (1) slide collision check
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c and c.get_collider() == player_ref:
			did_hit = true
			break

	# (2) distance fallback (in case player doesn't physically collide with us)
	if not did_hit and player_ref:
		if global_position.distance_to(player_ref.global_position) <= touch_damage_radius:
			did_hit = true

	if did_hit and hit_cd <= 0.0 and player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)
		hit_cd = attack_cooldown

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

	# Notify Game for HUD stats/time bonus
	var game := get_tree().root.get_node("Game")
	if game and game.has_method("on_enemy_killed"):
		game.on_enemy_killed("chaser")

	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished

	queue_free()

func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")
