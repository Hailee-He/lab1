extends CharacterBody2D
##
## chaser — ghost-like slime that chases the player
## - Does NOT push the player or walls (collision_mask = 0)
## - Deals touch damage by distance check + cooldown (no physical push)
## - Still receives damage from bullets via take_damage()
## - Uses animations: idle / jump / hit / death
## - Plays jump/move SFX while moving, death SFX when dying
##

# ------------ Tunable parameters ------------
@export var speed: float = 90.0
@export var hp: int = 4

# Damage is in "HP percent points" for your Game.gd (HP% system)
@export var touch_damage: int = 10         # how much HP% to remove on touch
@export var touch_radius: float = 20.0     # how close to hurt the player
@export var touch_cooldown: float = 0.6    # seconds between hits

# Names of animations that EXIST in your SpriteFrames
@export var idle_anim_name: String = "idle"
@export var move_anim_name: String = "jump"   # use "jump" as moving animation

# ------------ Cached nodes ------------
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_move: AudioStreamPlayer2D = $SFXMove    # loop jump/move SFX
@onready var sfx_death: AudioStreamPlayer2D = $SFXDeath  # one-shot death SFX

var player_ref: Node2D
var cd: float = 0.0

# ============================================================
# Lifecycle
# ============================================================
func _ready() -> void:
	# Layers/Masks: 0=World, 1=Player, 2=Enemy, 3=Bullet, 4=Items (your mapping)
	# Put chaser on Enemy layer but collide with NOBODY -> ghost
	collision_layer = 1 << 2     # Enemy layer (bit 2)
	collision_mask  = 0          # collide with nobody

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

	# --- Simple chase movement (no physical push) ---
	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	# --- Touch damage by distance ---
	if cd <= 0.0 and global_position.distance_to(player_ref.global_position) <= touch_radius:
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(touch_damage)
		cd = touch_cooldown

	# --- Animation: idle vs move (jump) ---
	if anim and anim.sprite_frames:
		if velocity.length() > 1.0:
			if anim.sprite_frames.has_animation(move_anim_name) and anim.animation != move_anim_name:
				anim.play(move_anim_name)
		else:
			if anim.sprite_frames.has_animation(idle_anim_name) and anim.animation != idle_anim_name:
				anim.play(idle_anim_name)

	# --- Move SFX: loop while moving, stop when idle ---
	var is_moving := velocity.length() > 1.0
	if sfx_move:
		if is_moving and not sfx_move.playing:
			sfx_move.play()
		elif not is_moving and sfx_move.playing:
			sfx_move.stop()

# ============================================================
# Taking damage from bullets
# ============================================================
func take_damage(dmg: int) -> void:
	if hp <= 0:
		return

	hp -= dmg

	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("hit"):
		anim.play("hit")

	if hp <= 0:
		_die()

func _die() -> void:
	# stop move SFX
	if sfx_move and sfx_move.playing:
		sfx_move.stop()

	# play death SFX once
	if sfx_death:
		sfx_death.play()

	# disable collision
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", true)

	# inform Game for score/time
	var game := get_tree().root.get_node_or_null("Game")
	if game and game.has_method("on_enemy_killed"):
		game.on_enemy_killed("chaser")

	# death animation then free
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished

	queue_free()

# ============================================================
# Utility
# ============================================================
func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")
