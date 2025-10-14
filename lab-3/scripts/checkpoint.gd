extends Area2D
@onready var anim: AnimatedSprite2D = $Anim
var activated := false

func _ready() -> void:
	add_to_group("checkpoint")
	anim.play("idle")
	body_entered.connect(_on_body_entered)

func _on_body_entered(b: Node) -> void:
	if activated or not b.is_in_group("player"): return
	activated = true
	anim.play("active")
	var level := get_tree().get_first_node_in_group("level")
	if level: 
		if level.has_method("set_checkpoint"):
			level.set_checkpoint(global_position)

		if level.has_method("sfx_play_success"):
			level.sfx_play_success()

		if level.has_method("on_checkpoint_reached"):
			level.on_checkpoint_reached()
