extends Node2D
## Spawns chasers and shooters over time.
## - Total enemies capped by `max_enemies`
## - Spawn interval shrinks as difficulty increases
## - Shooter share grows with difficulty (weighted spawn)
## - Enemies appear just outside the visible rect and move in

# -------------------- Tuning --------------------
@export var spawn_interval: float = 2.0        # seconds between spawns (initial)
@export var max_enemies: int = 15              # cap of alive enemies
@export var spawn_boundary_margin: float = 48  # how far outside the screen to spawn

# Shooter ratio progression: share = start + gain*(difficulty-1), clamped to [start,max]
@export var shooter_share_start: float = 0.20  # 20% shooters at difficulty 1
@export var shooter_share_gain:  float = 0.06  # +6% per difficulty step
@export var shooter_share_max:   float = 0.80  # cap at 80%

# Difficulty pacing (optional, call increase_difficulty() from Game if needed)
@export var min_spawn_interval: float = 0.6    # never go faster than this
@export var spawn_interval_decay: float = 0.90 # multiply interval by this when difficulty rises
@export var max_enemies_growth:  int   = 2     # +N cap per difficulty
@export var max_enemies_hardcap: int   = 35    # absolute maximum

# -------------------- State --------------------
var _timer: float = 0.0
var _difficulty: int = 1

# -------------------- Enemy scenes --------------------
var chaser_scene:  PackedScene = preload("res://scene/chaser.tscn")
var shooter_scene: PackedScene = preload("res://scene/shooter.tscn")

func _ready() -> void:
	# Spawner should sit under an 'Enemies' container (optional safety)
	if not get_parent() or get_parent().name != "Enemies":
		push_warning("EnemySpawner: place this node under an 'Enemies' container for clean hierarchy.")

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= spawn_interval and _count_current_enemies() < max_enemies:
		_timer = 0.0
		_spawn_weighted()

# -------------------- Difficulty API --------------------
func increase_difficulty() -> void:
	_difficulty += 1
	spawn_interval = max(min_spawn_interval, spawn_interval * spawn_interval_decay)
	max_enemies = min(max_enemies_hardcap, max_enemies + max_enemies_growth)

# -------------------- Internals --------------------
func _count_current_enemies() -> int:
	var n := 0
	var p := get_parent()
	if p:
		for c in p.get_children():
			if c != self and c.is_in_group("enemies"):
				n += 1
	return n

func _spawn_weighted() -> void:
	# Shooter probability grows with difficulty (use clampf for float and explicit typing)
	var shooter_share: float = clampf(
		shooter_share_start + shooter_share_gain * float(_difficulty - 1),
		shooter_share_start, shooter_share_max
	)

	# Pick which enemy to spawn
	var scene: PackedScene = shooter_scene if randf() < shooter_share else chaser_scene
	var e := scene.instantiate()
	e.global_position = _spawn_pos_at_edge()
	e.add_to_group("enemies")

	# Add under the same parent (usually 'Enemies')
	if get_parent():
		get_parent().add_child(e)
	else:
		get_tree().current_scene.add_child(e)

func _spawn_pos_at_edge() -> Vector2:
	# Spawn just outside the current visible rect
	var rect := get_viewport().get_visible_rect()
	var left   := rect.position.x - spawn_boundary_margin
	var right  := rect.position.x + rect.size.x + spawn_boundary_margin
	var top    := rect.position.y - spawn_boundary_margin
	var bottom := rect.position.y + rect.size.y + spawn_boundary_margin

	match randi() % 4:
		0: return Vector2(randf_range(left, right), top)       # top edge
		1: return Vector2(right, randf_range(top, bottom))     # right edge
		2: return Vector2(randf_range(left, right), bottom)    # bottom edge
		_: return Vector2(left, randf_range(top, bottom))      # left edge
