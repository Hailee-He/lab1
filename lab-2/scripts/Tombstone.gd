extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D
@export var tomb_open_sound: AudioStream

var is_opened := false

func _ready() -> void:
	add_to_group("tombstone")

func open_tomb(next_scene_path: String):
	if is_opened: return
	is_opened = true

	if tomb_open_sound:
		audio.stream = tomb_open_sound
		audio.play()

	if anim and anim.has_animation("open_tomb"):
		anim.play("open_tomb")

	await get_tree().create_timer(1.5).timeout
	if ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		push_error("Scene not found: " + next_scene_path)
