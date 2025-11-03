extends Area2D

@export var sfx_node_path: NodePath = ^"AudioStreamPlayer"

var _consumed: bool = false   # guard against double triggers

func _ready() -> void:
	# Make sure Area2D can detect bodies
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

	# Heal via Game so HUD stays in sync
	var game := get_tree().root.get_node_or_null("Game")
	if game:
		if game.has_method("heal_to_full"):
			game.heal_to_full()
		elif game.has_method("set_health_percent"):
			game.set_health_percent(100)
	else:
		# Fallback if Game is missing
		if body.has_method("heal_points"):
			body.heal_points(999)

	# Optional SFX
	var sfx := get_node_or_null(sfx_node_path)
	if sfx is AudioStreamPlayer:
		(sfx as AudioStreamPlayer).play()

	# Prevent re-trigger: IMPORTANT — use set_deferred in a signal
	_disable_collision()

	# Small pickup FX then free
	_spawn_collect_fx_and_free()

func _disable_collision() -> void:
	# Disconnect signal to be extra safe
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)

	# These property changes are done deferred to avoid the "blocked during in/out signal" error
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Also disable the shape
	var shape := get_node_or_null("CollisionShape2D")
	if shape is CollisionShape2D:
		(shape as CollisionShape2D).set_deferred("disabled", true)

	# (Optional) clear layer/mask so it never collides again
	# set_deferred("collision_layer", 0)
	# set_deferred("collision_mask", 0)

func _spawn_collect_fx_and_free() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.2, 0.12)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.18)
	tw.finished.connect(queue_free)
