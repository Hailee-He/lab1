extends CharacterBody2D
##
## shooter — stronger enemy that respects walls & items
## - Lives on ENEMY layer
## - Collides with WORLD + PLAYER + ITEMS + BULLET
## - Chases player and does melee attack in range
## - Supports frozen flag so Game.gd can briefly freeze enemies
## - Plays walk SFX while walking, death SFX when dying
##

# ------------ Tunables ------------
@export var speed: float = 140.0
@export var hp: int = 4
@export var attack_range: float = 60.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.5

# ------------ Cached nodes ------------
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_walk: AudioStreamPlayer2D = $SFXWalk    # loop walking SFX
@onready var sfx_death: AudioStreamPlayer2D = $SFXDeath  # one-shot death SFX

var player_ref: Node2D
var atk_cd: float = 0.0
var is_facing_right: bool = true

# Freeze hook (used by respawn protection)
var _frozen: bool = false
func set_frozen(v: bool) -> void:
	_frozen = v
	# stop walking SFX while frozen
	if _frozen and sfx_walk and sfx_walk.playing:
		sfx_walk.stop()

# ============================================================
# Lifecycle
# ============================================================
func _ready() -> void:
	# Layers/Masks (0=World,1=Player,2=Enemy,3=Bullet,4=Items — your mapping)
	# Shooter must NOT pass through world/items, so it collides with them.
	collision_layer = 1 << 2
	collision_mask  = (1 << 0) | (1 << 1) | (1 << 3) | (1 << 4)
	#                   World      Player      Bullet      Items

	add_to_group("enemies")
	_find_player()

	if anim and anim.sprite_frames.has_animation("walk"):
		anim.play("walk")

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return

	if _frozen:
		velocity = Vector2.ZERO
		# no movement SFX while frozen
		if sfx_walk and sfx_walk.playing:
			sfx_walk.stop()
		return

	atk_cd = max(0.0, atk_cd - delta)

	if not player_ref:
		_find_player()
		return

	# --- basic chase movement ---
	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()   # collides with world/items

	is_facing_right = player_ref.global_position.x > global_position.x

	var dist := global_position.distance_to(player_ref.global_position)

	# --- attack when close enough ---
	if dist <= attack_range and atk_cd <= 0.0:
		atk_cd = attack_cooldown
		velocity = Vector2.ZERO

		var attack_anim := "attack_right" if is_facing_right else "attack_left"
		if anim and anim.sprite_frames.has_animation(attack_anim):
			anim.play(attack_anim)

		# stop walking SFX during attack
		if sfx_walk and sfx_walk.playing:
			sfx_walk.stop()

		if player_ref and player_ref.has_method("take_damage"):
			player_ref.take_damage(attack_damage)
	else:
		# walking toward player
		if anim and anim.sprite_frames.has_animation("walk") and anim.animation != "walk":
			anim.play("walk")

	# --- walk SFX: only when actually moving & not attacking/frozen ---
	var is_moving := (not _frozen) and velocity.length() > 5.0 and dist > attack_range
	if sfx_walk:
		if is_moving and not sfx_walk.playing:
			sfx_walk.play()
		elif not is_moving and sfx_walk.playing:
			sfx_walk.stop()

# ============================================================
# Damage & death
# ============================================================
func take_damage(dmg: int) -> void:
	if hp <= 0:
		return

	hp -= dmg

	if anim and anim.sprite_frames.has_animation("hit"):
		anim.play("hit")

	if hp <= 0:
		_die()

func _die() -> void:
	# stop walking SFX first
	if sfx_walk and sfx_walk.playing:
		sfx_walk.stop()

	# play death SFX once
	if sfx_death:
		sfx_death.play()

	# disable collision so it no longer blocks player/bullets
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)

	# notify Game for score/time
	var game := get_tree().root.get_node_or_null("Game")
	if game and game.has_method("on_enemy_killed"):
		game.on_enemy_killed("shooter")

	# play death animation then free
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished

	queue_free()

# ============================================================
# Utility
# ============================================================
func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")
