extends Area2D

@export var icon: Texture2D         # sprite image for this shard
@onready var spr: Sprite2D = $Sprite2D

func _ready() -> void:
	# set the sprite texture if provided
	if icon and spr:
		spr.texture = icon
	# connect to signal
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	# only react to player
	if body.name != "Player" and not body.is_in_group("player"):
		return

	# get the current scene (your Game node)
	var game := get_tree().current_scene
	if game and game.has_method("add_scroll"):
		game.add_scroll(1)

	# small pickup tween
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.25, 0.12)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.18)

	# IMPORTANT:
	# do NOT call queue_free() directly here while the signal is being flushed.
	# instead, defer it to after the physics step:
	set_deferred("monitoring", false)     # stop detecting new bodies
	set_deferred("monitorable", false)    # optional: other areas won't see it
	call_deferred("_really_free")


func _really_free() -> void:
	queue_free()
