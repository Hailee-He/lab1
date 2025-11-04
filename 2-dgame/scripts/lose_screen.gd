extends Control
##
## LoseScreen.gd
## - Shown when the player loses (HP=0 & Not revived / Time up)
## - Button sends the player back to the MAIN scene
##   so they can re-read the story & controls, then start again.
##

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main.tscn")
