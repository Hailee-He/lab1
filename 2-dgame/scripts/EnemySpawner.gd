extends Node2D
##
## EnemySpawner.gd — spawns Chaser & Shooter over time
## - Starts mostly Chasers
## - As difficulty grows, Shooter probability increases
## - Keeps a cap on total enemies
##

# ----------------- Basic spawn settings -----------------
@export var spawn_interval: float = 2.0     # seconds between spawns at start
@export var max_enemies: int = 12          # global cap; lower = easier
@export var spawn_boundary_margin: float = 50.0  # off-screen spawn margin

# ----------------- Difficulty curve -----------------
var difficulty: int = 1                    # starts at 1

@export var difficulty_step_time: float = 25.0   # every 25s -> harder
@export var min_spawn_interval: float = 0.7      # fastest rate
@export var spawn_interval_decay: float = 0.9    # each step * 0.9
@export var max_enemies_step: int = 2           # enemies added per step
@export var max_enemies_cap: int = 30           # upper cap

# Shooter probability parameters
@export var shooter_share_start: float = 0.15    # 15% at difficulty 1
@export var shooter_share_gain: float = 0.15     # +15% each step
@export var shooter_share_max: float = 0.7       # clamp at 70%

# ----------------- Runtime timers -----------------
var _spawn_timer: float = 0.0
var _difficulty_timer: float = 0.0

# Enemy scenes
var chaser_scene: PackedScene = preload("res://scene/chaser.tscn")
var shooter_scene: PackedScene = preload("res://scene/shooter.tscn")

func _ready() -> void:
	# Optional safety: spawner should usually be inside a node named "Enemies"
	if not get_parent() or get_parent().name != "Enemies":
		push_warning("EnemySpawner should be a child of an 'Enemies' node.")

func _process(delta: float) -> void:
	# ---------- Difficulty timer ----------
	_difficulty_timer += delta
	if _difficulty_timer >= difficulty_step_time:
		_difficulty_timer -= difficulty_step_time
		_increase_difficulty()

	# ---------- Spawn timer ----------
	_spawn_timer += delta
	var current_count := _count_current_enemies()
	if _spawn_timer >= spawn_interval and current_count < max_enemies:
		_spawn_timer = 0.0
		_spawn_weighted()

func _count_current_enemies() -> int:
	var n := 0
	var p := get_parent()
	if p:
		for c in p.get_children():
			if c != self and c.is_in_group("enemies"):
				n += 1
	return n

# Spawn one enemy with a probability that depends on difficulty
func _spawn_weighted() -> void:
	# Shooter probability grows with difficulty
	var shooter_share: float = clamp(
		shooter_share_start + shooter_share_gain * float(difficulty - 1),
		shooter_share_start,
		shooter_share_max
	)

	var scene: PackedScene = shooter_scene if randf() < shooter_share else chaser_scene
	var e := scene.instantiate()
	e.global_position = _spawn_pos_at_edge()
	if get_parent():
		get_parent().add_child(e)
	else:
		get_tree().current_scene.add_child(e)

# Spawn slightly outside the visible screen
func _spawn_pos_at_edge() -> Vector2:
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

# Called internally when enough time has passed
func _increase_difficulty() -> void:
	difficulty += 1

	# Make spawns a bit faster
	spawn_interval = max(min_spawn_interval, spawn_interval * spawn_interval_decay)

	# Allow a few more enemies on screen
	max_enemies = min(max_enemies_cap, max_enemies + max_enemies_step)

	# (No need to change shooter_share here;
	#  it is recomputed each time in _spawn_weighted.)
