extends Area2D
##
## medkit.gd — full-heal pickup that also drops a rock block
## - When the player touches the medkit:
##     1) Heal to full (via Game.gd HP% system)
##     2) Tween the RockBlock down to close the lower path
##     3) Play a pickup SFX (on the medkit)
##     4) When the rock finishes falling, play a rock impact SFX
##     5) Play a small pickup FX and remove the medkit
##

# How much to heal in percent (100 = full health in your HP% design)
@export var heal_percent: int = 100

# RockBlock to drop after pickup (set this in the Inspector)
# In your scene RockBlock is a sibling of Medkit under Items,
# so "../RockBlock" should work by default.
@export var rock_block_path: NodePath = ^"../RockBlock"

# How far (Y+) and how long the rock falls
@export var rock_drop_distance: float = 96.0
@export var rock_drop_time: float = 0.6

# ---------- SFX paths ----------
# Pickup SFX on the Medkit itself (child AudioStreamPlayer2D)
@export var sfx_pickup_path: NodePath = ^"SFXPickup"
# Rock impact SFX on the RockBlock (child AudioStreamPlayer2D)
@export var sfx_rock_path: NodePath = ^"../RockBlock/SFXRock"

# ---------- Cached references ----------
@onready var _sfx_pickup: AudioStreamPlayer2D = get_node_or_null(sfx_pickup_path)
@onready var _sfx_rock  : AudioStreamPlayer2D = get_node_or_null(sfx_rock_path)

# Guard so the medkit can only be used once
var _consumed: bool = false


func _ready() -> void:
	# Make sure the Area2D actually detects bodies
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _consumed:
		return

	# Only react to the player
	if not (body.name == "Player" or body.is_in_group("player")):
		return

	_consumed = true

	# --- 1) Heal via Game.gd so HUD stays in sync ---
	var game := get_tree().root.get_node_or_null("Game")
	if game:
		if game.has_method("set_health_percent"):
			game.set_health_percent(heal_percent)
		elif game.has_method("heal_to_full"):
			game.heal_to_full()
	else:
		# Fallback: if the player has its own heal() function
		if body.has_method("heal"):
			body.heal(999)

	# --- 2) Drop the rock block to close the lower path ---
	_drop_rock_block()

	# --- 3) Play pickup SFX (medkit heal sound), if present ---
	if _sfx_pickup:
		_sfx_pickup.play()

	# Disable this medkit’s collision so it cannot be collected twice
	_disable_collision()

	# Small pickup tween, then free
	_spawn_collect_fx_and_free()


func _drop_rock_block() -> void:
	# Find the rock block by NodePath
	var rock := get_node_or_null(rock_block_path) as Node2D
	if rock == null:
		return

	# Move it straight down by rock_drop_distance using a tween
	var start_pos := rock.position
	var end_pos := start_pos + Vector2(0, rock_drop_distance)

	var tw := create_tween()
	tw.tween_property(rock, "position", end_pos, rock_drop_time)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	# When the rock finishes falling, play the rock impact SFX (if assigned)
	if _sfx_rock:
		tw.finished.connect(func() -> void:
			_sfx_rock.play()
		)


func _disable_collision() -> void:
	# Use set_deferred to avoid "Function blocked during in/out signal" errors
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", true)


func _spawn_collect_fx_and_free() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.2, 0.12)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.18)
	tw.finished.connect(queue_free)
