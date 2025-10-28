extends Node

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"): # Enter / Space
		get_tree().change_scene_to_file("res://scene/Game.tscn")
