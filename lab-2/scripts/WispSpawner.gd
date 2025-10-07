extends Node2D

@export var wisp_scene: PackedScene
@export var initial_wisp_count: int = 20
@export var max_wisp_count: int = 60
@export var spawn_interval: float = 2.0

var spawn_timer: Timer
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	for i in range(initial_wisp_count):
		spawn_wisp()

	spawn_timer.start()

func _on_spawn_timer_timeout():
	if get_tree().get_nodes_in_group("agents").size() < max_wisp_count:
		spawn_wisp()

func spawn_wisp():
	if not wisp_scene:
		push_error("No Wisp scene assigned!")
		return
	var wisp = wisp_scene.instantiate()
	# Spawn randomly inside viewport
	var rect = get_viewport().get_visible_rect()
	wisp.global_position = Vector2(rng.randf_range(rect.position.x, rect.end.x),
								   rng.randf_range(rect.position.y, rect.end.y))
	add_child(wisp)
