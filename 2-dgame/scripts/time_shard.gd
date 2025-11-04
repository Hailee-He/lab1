extends Area2D
##
## time_shard.gd — collectible scroll shard
## - Shows a sprite (icon)
## - When the Player touches it:
##     * tells Game.gd to add one scroll
##     * plays a pickup sound (optional)
##     * plays a small tween effect
##     * frees itself safely using deferred calls
##

# Sprite image for this shard (you can assign different icons for each shard)
@export var icon: Texture2D

# OPTIONAL: path to an AudioStreamPlayer2D child used for pickup SFX
@export var sfx_node_path: NodePath = ^"SFXPickup"

# Cached node references
@onready var spr: Sprite2D = $Sprite2D
@onready var _sfx_pickup: AudioStreamPlayer2D = get_node_or_null(sfx_node_path)

func _ready() -> void:
	# Make sure the Area2D actually detects bodies
	monitoring = true
	monitorable = true

	# Set the sprite texture if provided
	if icon and spr:
		spr.texture = icon

	# Connect body_entered signal to our handler
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	# Only react to the player
	if body.name != "Player" and not body.is_in_group("player"):
		return

	# 1) Inform Game.gd that one scroll was collected
	var game := get_tree().current_scene
	if game and game.has_method("add_scroll"):
		game.add_scroll(1)

	# 2) Play pickup sound, if we have an AudioStreamPlayer2D
	if _sfx_pickup:
		_sfx_pickup.play()

	# 3) Small pickup tween effect (scale + fade out)
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.25, 0.12)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.18)

	# 4) IMPORTANT:
	# Do NOT free immediately while the signal is being processed.
	# Instead, turn off collision now and free later via call_deferred.
	set_deferred("monitoring", false)      # stop detecting new bodies
	set_deferred("monitorable", false)     # other areas can't see us anymore

	call_deferred("_really_free")


func _really_free() -> void:
	queue_free()
