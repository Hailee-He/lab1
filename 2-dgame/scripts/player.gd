extends CharacterBody2D
##
## Player controller
## - Movement & facing
## - Shooting (works even while hurt)
## - Hit / i-frames (does NOT block shooting)
## - Records a short trail of recent positions so we can respawn at
##   “where the player was N seconds ago”
## - Plays SFX: shoot / hurt / death (optional) / running loop
##

# ---------------- Tunables ----------------
@export var move_speed: float = 140.0
@export var fire_cooldown: float = 0.18
@export var invincible_time: float = 0.5
@export var bullet_scene: PackedScene = preload("res://scene/bullet.tscn")

# Spawn offsets for the muzzle relative to the player center
@export var muzzle_offset_px := {
	"up":    Vector2(0, -12),
	"down":  Vector2(0,  12),
	"left":  Vector2(-12, 0),
	"right": Vector2( 12, 0)
}

# ---------------- Runtime state ----------------
@onready var anim: AnimatedSprite2D      = $AnimatedSprite2D
@onready var sfx_shoot: AudioStreamPlayer2D = $SFXShoot
@onready var sfx_hurt: AudioStreamPlayer2D  = $SFXHurt
@onready var sfx_death: AudioStreamPlayer2D = $SFXDeath
@onready var sfx_run: AudioStreamPlayer2D   = $SFXRunLoop

var facing: String = "down"        # "up" | "down" | "left" | "right"
var shoot_cd: float = 0.0          # cooldown timer
var invincible: float = 0.0        # i-frame timer
var is_dead: bool = false          # set & cleared by Game if you need it

# We still play the hurt animation for feedback, but it NEVER blocks shooting.
var is_hurt_playing: bool = false

# -------------- Trail for “2 seconds ago” respawn --------------
const TRAIL_SECONDS := 3.0          # keep last 3s of positions (>= 2s)
const TRAIL_HZ := 20.0              # sample 20 times per second
const TRAIL_DT := 1.0 / TRAIL_HZ
var _trail_time := 0.0
var _trail_sample_acc := 0.0
var _trail : Array = []             # each: { "t": float, "pos": Vector2 }

# ===============================================================
# Lifecycle
# ===============================================================
func _ready() -> void:
	add_to_group("player")
	anim.play("idle-down")

	# Make sure HURT is not looping (so it ends visually)
	if anim.sprite_frames.has_animation("hurt"):
		anim.sprite_frames.set_animation_loop("hurt", false)
	# When any animation finishes, if it was "hurt", clear the flag
	anim.animation_finished.connect(_on_anim_finished)

	# Init trail
	_trail.clear()
	_trail_time = 0.0
	_trail_sample_acc = 0.0
	_push_trail_sample()

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	# --- timers ---
	if shoot_cd > 0.0:
		shoot_cd -= delta
	if invincible > 0.0:
		invincible -= delta
	# Safety: if hurt animation already stopped, clear the cosmetic flag
	if is_hurt_playing and not anim.is_playing():
		is_hurt_playing = false

	# --- record trail (~20Hz, keep 3s) ---
	_record_trail(delta)

	# --- movement input ---
	var input_vec := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")  - Input.get_action_strength("ui_up")
	).normalized()
	velocity = input_vec * move_speed
	move_and_slide()

	# update facing
	if input_vec.length() > 0.1:
		if abs(input_vec.x) > abs(input_vec.y):
			facing = "right" if input_vec.x > 0.0 else "left"
		else:
			facing = "down" if input_vec.y > 0.0 else "up"

	# --- animations (hurt anim is purely visual; does NOT block firing) ---
	if is_hurt_playing:
		if anim.animation != "hurt":
			anim.play("hurt")
	elif velocity.length() > 0.1:
		anim.play("walk-" + facing)
	else:
		anim.play("idle-" + facing)

	# --- running SFX loop ---
	var is_moving := velocity.length() > 0.1
	if sfx_run:
		if is_moving and not sfx_run.playing:
			sfx_run.play()
		elif not is_moving and sfx_run.playing:
			sfx_run.stop()

	# --- shooting ---
	if Input.is_action_pressed("shoot"):
		_try_shoot()

# ===============================================================
# Shooting
# ===============================================================
func _try_shoot() -> void:
	# IMPORTANT: do NOT block by `is_hurt_playing`
	if shoot_cd > 0.0 or is_dead:
		return
	shoot_cd = fire_cooldown
	_shoot()

func _shoot() -> void:
	if bullet_scene == null:
		push_error("player.gd: bullet_scene is null; assign in Inspector.")
		return

	# tiny shot animation (optional)
	if anim.sprite_frames.has_animation("shot"):
		anim.play("shot")

	var bullet := bullet_scene.instantiate()

	# direction from facing
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

	# spawn position
	var off: Vector2 = muzzle_offset_px.get(facing, Vector2.ZERO)
	bullet.global_position = global_position + off

	# communicate direction to bullet
	if bullet.has_method("set_direction"):
		bullet.set_direction(dir)

	# add to scene tree
	get_parent().add_child(bullet)

	# play shooting SFX
	if sfx_shoot:
		sfx_shoot.play()

# ===============================================================
# Damage / i-frames / hooks called by Game
# ===============================================================
## Called by enemies. If inside i-frames, ignore the hit.
## NOTE: `amount` is interpreted as “HP percent” in your design;
## HP% is actually owned/updated by Game so HUD stays consistent.
func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or invincible > 0.0:
		return

	# Tell Game to change HP% (negative delta)
	var game := get_tree().root.get_node_or_null("Game")
	if game and game.has_method("change_health_percent"):
		game.change_health_percent(-amount)

	# Visual feedback
	is_hurt_playing = true
	if anim.sprite_frames.has_animation("hurt"):
		anim.play("hurt")

	if knockback != Vector2.ZERO:
		velocity = knockback

	# Local i-frames for repeated hits
	invincible = max(invincible, invincible_time)

	# Hurt SFX
	if sfx_hurt:
		sfx_hurt.play()

## Optional helper: call this from Game exactly at the moment
## you consider the player “really dead” (before respawn logic).
func play_death_sfx() -> void:
	if sfx_run and sfx_run.playing:
		sfx_run.stop()
	if sfx_death:
		sfx_death.play()

## Game gives extra invincibility seconds after respawn
func grant_invincibility(sec: float) -> void:
	invincible = max(invincible, sec)

## Game requests: respawn at “2 seconds ago” point
func respawn_at_point_2s_ago() -> void:
	var pos := _get_point_seconds_ago(2.0)
	global_position = pos
	visible = true
	is_dead = false
	is_hurt_playing = false
	anim.play("idle-down")
	# i-frames are granted from Game via grant_invincibility()

# ===============================================================
# Anim callbacks
# ===============================================================
func _on_anim_finished() -> void:
	if anim.animation == "hurt":
		is_hurt_playing = false

# ===============================================================
# Trail recording / query
# ===============================================================
func _record_trail(delta: float) -> void:
	_trail_time += delta
	_trail_sample_acc += delta
	if _trail_sample_acc >= TRAIL_DT:
		_trail_sample_acc -= TRAIL_DT
		_push_trail_sample()
		_trim_trail()

func _push_trail_sample() -> void:
	_trail.append({ "t": _trail_time, "pos": global_position })

func _trim_trail() -> void:
	var cutoff := _trail_time - TRAIL_SECONDS
	while _trail.size() > 0 and _trail[0]["t"] < cutoff:
		_trail.pop_front()

func _get_point_seconds_ago(sec: float) -> Vector2:
	var target_t := _trail_time - sec
	var best_idx := -1
	for i in range(_trail.size()):
		if _trail[i]["t"] <= target_t:
			best_idx = i
	if best_idx >= 0:
		return _trail[best_idx]["pos"]
	elif _trail.size() > 0:
		return _trail[0]["pos"]
	else:
		return global_position
