extends Area2D

@export var heal_amount := 2

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		var game := get_tree().root.get_node("Game")
		if game and game.has_method("heal_to_full"):
			# Full heal via Game (also updates HUD)
			game.heal_to_full()
		elif body.has_method("heal"):
			body.heal(heal_amount)
		_spawn_collect_fx()
		queue_free()

func _spawn_collect_fx() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.2, 0.15)
	tw.tween_property(self, "modulate", Color(1,1,1,0), 0.15)
