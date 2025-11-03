extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not (body.name == "Player" or body.is_in_group("player")):
		return
	var game := get_node("/root/Game")
	# Only when the door is open will the victory be declared.
	if game and game.has_method("can_exit") and game.can_exit():
		if game.has_method("win_game"):
			game.win_game()
