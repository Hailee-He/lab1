extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_opened: bool = false

func _ready() -> void:
	add_to_group("tombstone")

func open_tomb(next_scene_path: String):
	if is_opened:
		return
	
	is_opened = true
	print("Opening tomb...")
	
	#Play sound effect
	var sound_effect = load("res://assets/sounds/tomb_open.ogg")  
	if sound_effect:
		audio.stream = sound_effect
		audio.play()

	# Play animation
	if anim and anim.has_animation("open_tomb"):
		anim.play("open_tomb")
	
	# Waiting for the animation and sound effects to finish	
	await get_tree().create_timer(1.5).timeout
	
	# Switch to another scene
	get_tree().change_scene_to_file(next_scene_path)
