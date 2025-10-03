extends AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var ambient_sound = load("res://assets/sounds/ambient_graveyard.wav")
	if ambient_sound:
		stream = ambient_sound
		volume_db = -10.0  # Adjust volume as needed
		play()
		# Set to loop
		finished.connect(_on_finished)

func _on_finished():
	play()  # Loop the sound
