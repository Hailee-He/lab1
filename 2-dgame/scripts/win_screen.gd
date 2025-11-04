extends Control
##
## WinScreen.gd
## - Shown when the player wins (collected all shards + reached EXIT)
## - Button restarts the level by going directly back to Game.tscn
##

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/Game.tscn")
