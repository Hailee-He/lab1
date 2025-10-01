extends Node2D

@export var slime_scene : PackedScene
@export var spawn_timer : Timer
@export var score : int = 0
@export var score_label : Label
@export var game_over_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Gradually reduce the length of the generation countdown, but do not make it less than 1s.
	spawn_timer.wait_time -= 0.2 * delta
	spawn_timer.wait_time = clamp(spawn_timer.wait_time, 1, 3)
	
	score_label.text = "Score: " + str(score)


func _spawn_slime() -> void:
	# Generate slime and assign it a random location
	var slime_node = slime_scene.instantiate()
	slime_node.position = Vector2(250, randf_range(-100, 100))
	get_tree().current_scene.add_child(slime_node)
	
func show_game_over():
	game_over_label.visible = true
