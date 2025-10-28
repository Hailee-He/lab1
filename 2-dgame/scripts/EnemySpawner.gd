extends Node2D

# Enemy spawn configuration
@export var spawn_interval: float = 2.0
@export var max_enemies: int = 15
@export var spawn_boundary_margin: float = 50.0  # Margin from screen edges

# Spawn timing and difficulty
var timer: float = 0.0
var difficulty: int = 1

# Enemy scene references
var chaser_scene: PackedScene = preload("res://scene/chaser.tscn")
var shooter_scene: PackedScene = preload("res://scene/shooter.tscn")

func _ready() -> void:
	# Safety check: spawner should be a child of Enemies container
	if not get_parent() or get_parent().name != "Enemies":
		push_warning("EnemySpawner should be a child of an 'Enemies' container")

func _process(delta: float) -> void:
	timer += delta
	var current_enemy_count := _count_current_enemies()
	if timer >= spawn_interval and current_enemy_count < max_enemies:
		timer = 0.0
		_spawn_random_enemy()

func _count_current_enemies() -> int:
	var cnt := 0
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if child != self and (child.is_in_group("enemies") \
			or child.name.begins_with("Chaser") or child.name.begins_with("shooter")):
				cnt += 1
	return cnt

func _spawn_random_enemy() -> void:
	# Godot 4 ternary: value_if_true if condition else value_if_false
	var scene: PackedScene = shooter_scene if (randi() % 3 == 0) else chaser_scene
	var e := scene.instantiate()
	e.global_position = _spawn_pos_at_edge()
	if get_parent():
		get_parent().add_child(e)
	else:
		get_tree().current_scene.add_child(e)

func _spawn_pos_at_edge() -> Vector2:
	# Spawn just outside the visible rect
	var sz := get_viewport().get_visible_rect().size
	var left := -spawn_boundary_margin
	var right := sz.x + spawn_boundary_margin
	var top := -spawn_boundary_margin
	var bottom := sz.y + spawn_boundary_margin
	var edge := randi() % 4
	match edge:
		0: return Vector2(randf_range(left, right), top)      # top
		1: return Vector2(right, randf_range(top, bottom))    # right
		2: return Vector2(randf_range(left, right), bottom)   # bottom
		3: return Vector2(left, randf_range(top, bottom))     # left
		_: return Vector2(randf_range(left, right), top)

func increase_difficulty() -> void:
	difficulty += 1
	spawn_interval = max(0.6, spawn_interval * 0.9)
	max_enemies = min(35, max_enemies + 2)
