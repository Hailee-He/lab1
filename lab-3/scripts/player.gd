extends CharacterBody2D

# ── Movement / physics ─────────────────────────────────────────────────────────
@export var move_speed: float = 120.0
@export var jump_force: float = 270.0
@export var gravity: float    = 900.0

# ── Hearts (3 hearts -> 6 half-pips) ───────────────────────────────────────────
@export var max_hearts: int = 3         # 3 hearts in HUD
var hp_pips_max: int                    # = max_hearts * 2
var hp_pips: int                        # current pips (0..hp_pips_max)

# ── Signals ────────────────────────────────────────────────────────────────────
signal health_changed(curr: int, maxv: int)  # let main/hud listen to health updates
signal died                                   # broadcast death event

# ── Child nodes ────────────────────────────────────────────────────────────────
@onready var anim: AnimatedSprite2D = $Anim          # AnimatedSprite2D named "Anim"
@onready var hurtbox: Area2D          = $Hurtbox      # Area2D named "Hurtbox"

# Find HUD once at startup (put your HUD CanvasLayer in group "hud")
@onready var hud: CanvasLayer = get_tree().get_first_node_in_group("hud") as CanvasLayer

# brief invulnerability window after taking damage (in seconds)
var invuln_time := 0.0

func _ready() -> void:
	add_to_group("player")

	# Initialize hearts as full (each heart has 2 "pips" = half-hearts)
	hp_pips_max = max_hearts * 2
	hp_pips     = hp_pips_max

	# Tell listeners (HUD / main.gd) the current health immediately
	emit_signal("health_changed", hp_pips / 2, max_hearts)  # send in hearts for convenience

	# Also push to HUD directly (if you decided not to use signals in your HUD)
	if hud and hud.has_method("set_health"):
		hud.set_health(hp_pips, max_hearts)

	# Start listening for hazards via the Hurtbox
	hurtbox.area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	# Apply gravity while airborne
	if not is_on_floor():
		velocity.y += gravity * delta

	# Horizontal move (←/→)
	var dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = dir * move_speed

	# Jump on ground
	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = -jump_force
		var level = get_tree().get_first_node_in_group("level")
		if level and level.has_method("sfx_play_jump"):
			level.sfx_play_jump()

	move_and_slide()
	
	var running: bool = is_on_floor() and abs(velocity.x) > 10.0


	var level = get_tree().get_first_node_in_group("level")
	if level and level.has_method("sfx_run_set"):
		level.sfx_run_set(running)

	# Simple animation state
	if not is_on_floor():
		anim.play("jump")
	elif absf(velocity.x) > 1.0:
		anim.play("walk")
	else:
		anim.play("idle")

	# Face walking direction
	if velocity.x != 0:
		anim.flip_h = velocity.x < 0

	# Tick down i-frames
	if invuln_time > 0.0:
		invuln_time -= delta

# Called when Hurtbox overlaps a hazard Area2D or an enemy's child Area2D
func _on_area_entered(a: Area2D) -> void:
	if invuln_time > 0.0:
		return

	var is_enemy_child := a.get_parent() != null and a.get_parent().is_in_group("enemy")
	if a.is_in_group("hazard") or is_enemy_child:
		take_damage(1)      # 1 pip = half heart
		invuln_time = 0.8   # short invulnerability

# Decrease health by pips (half-hearts)
func take_damage(by_pips: int = 1) -> void:
	if hp_pips <= 0:
		return
	hp_pips = max(0, hp_pips - by_pips)
	
	var level = get_tree().get_first_node_in_group("level")
	if level and level.has_method("sfx_play_hit"):
		level.sfx_play_hit()

	# Update HUD directly (optional)
	if hud and hud.has_method("set_health"):
		hud.set_health(hp_pips, max_hearts)

	# Notify listeners in hearts (pips / 2)
	emit_signal("health_changed", hp_pips / 2, max_hearts)

	if hp_pips == 0:
		die()

# Increase health by pips (half-hearts)
func heal(by_pips: int = 1) -> void:
	hp_pips = min(hp_pips_max, hp_pips + by_pips)

	if hud and hud.has_method("set_health"):
		hud.set_health(hp_pips, max_hearts)

	emit_signal("health_changed", hp_pips / 2, max_hearts)

# Play death anim, stop physics, then emit "died"
func die() -> void:
	anim.play("dead")
	set_physics_process(false)
	await get_tree().create_timer(0.6).timeout
	emit_signal("died")

# Reset to a checkpoint location and restore health
func respawn(at_pos: Vector2) -> void:
	global_position = at_pos
	velocity        = Vector2.ZERO

	hp_pips = hp_pips_max
	if hud and hud.has_method("set_health"):
		hud.set_health(hp_pips, max_hearts)
	emit_signal("health_changed", hp_pips / 2, max_hearts)

	set_physics_process(true)
	anim.play("idle")
