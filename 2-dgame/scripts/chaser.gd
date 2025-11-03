extends CharacterBody2D
##
## chaser — ghost-like slime that chases the player
## - Does NOT push the player or walls (collision_mask = 0)
## - Touch-damage is done by distance check + cooldown
## - Can still be hit by bullets (bullets are Area2D that look for "enemies" group)
## - Uses your existing animations: idle / jump / hit / death
##

# ------------ Tunable parameters ------------
@export var speed: float = 90.0
@export var hp: int = 4

# Damage is in "percent points" for your Game.gd (HP% system)
@export var touch_damage: int = 10         # how much HP% to remove on touch
@export var touch_radius: float = 20.0     # how close to hurt the player
@export var touch_cooldown: float = 0.6    # seconds between hits

# Names of animations that EXIST in your SpriteFrames
# (You said you have: idle, jump, hit, death — no "walk")
@export var idle_anim_name: String = "idle"
@export var move_anim_name: String = "jump"   # use jump as “moving” animation

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var player_ref: Node2D
var cd: float = 0.0

func _ready() -> void:
	# Layers/Masks: 1=World, 2=Player, 3=Enemy, 4=Bullet, 5=Items
	# Put chaser ON Enemy layer (3) but let it collide with NOTHING,
	# so it will not push the player or get stuck on walls.
	collision_layer = 1 << 2     # Enemy layer (bit 2)
	collision_mask  = 0          # collide with nobody (ghost)

	add_to_group("enemies")
	_find_player()

	# Start with idle anim if it exists
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation(idle_anim_name):
		anim.play(idle_anim_name)

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	if not player_ref:
		_find_player()
		return

	cd = max(0.0, cd - delta)

	# --- Simple chase movement ---
	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()  # no physical push on player because mask = 0

	# --- Touch damage by distance ---
	if cd <= 0.0 and global_position.distance_to(player_ref.global_position) <= touch_radius:
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(touch_damage)
		cd = touch_cooldown

	# --- Animations (use idle/jump instead of hard-coded "walk") ---
	if anim and anim.sprite_frames:
		if velocity.length() > 1.0:
			# moving → play move_anim_name if it exists
			if anim.sprite_frames.has_animation(move_anim_name):
				if anim.animation != move_anim_name:
					anim.play(move_anim_name)
		else:
			# not moving → play idle_anim_name if it exists
			if anim.sprite_frames.has_animation(idle_anim_name):
				if anim.animation != idle_anim_name:
					anim.play(idle_anim_name)

# ------------ Damage from bullets ------------
func take_damage(dmg: int) -> void:
	if hp <= 0:
		return
	hp -= dmg

	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("hit"):
		anim.play("hit")

	if hp <= 0:
		_die()

func _die() -> void:
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", true)

	var game := get_tree().root.get_node_or_null("Game")
	if game and game.has_method("on_enemy_killed"):
		game.on_enemy_killed("chaser")

	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished

	queue_free()

# ------------ Utility ------------
func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")
