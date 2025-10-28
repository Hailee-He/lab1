extends Area2D

@export var time_value: float = 5.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		var game := get_tree().root.get_node("Game")
		if game and game.has_method("add_time"):
			game.add_time(time_value)
		_spawn_collect_fx()
		queue_free()

func _spawn_collect_fx() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.5, 0.2)
	tw.tween_property(self, "modulate", Color.TRANSPARENT, 0.2)
