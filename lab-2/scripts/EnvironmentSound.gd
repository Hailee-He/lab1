extends AudioStreamPlayer

@export var ambient_sound: AudioStream
@export var initial_volume: float = -10.0

func _ready() -> void:
	if ambient_sound:
		stream = ambient_sound
		volume_db = initial_volume
		play()  # loop can be set directly in AudioStream resource
