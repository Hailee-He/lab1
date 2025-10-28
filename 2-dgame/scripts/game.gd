extends Node2D

# ---------- Signals for HUD (HUD connects to these) ----------
signal time_changed(time_left: float, max_time: float)
signal score_changed(score: int)
signal health_changed(current_health: int, max_health: int)
signal lives_changed(current_lives: int, max_lives: int)
signal enemy_killed(enemy_type: String)

# ---------- Exported scenes (ASSIGN IN INSPECTOR) ----------
@export var player_scene: PackedScene
@export var lose_scene: PackedScene
@export var win_scene: PackedScene

# ---------- Game parameters ----------
@export var start_time: float = 60.0
@export var start_health: int = 3
@export var start_lives: int = 3

# ---------- Runtime state ----------
var time_left: float
var max_time: float
var score: int = 0
var player_health: int
var max_health: int
var player_lives: int
var max_lives: int
var is_game_over: bool = false

# Optional kill counters
var chaser_kills: int = 0
var shooter_kills: int = 0

func _ready() -> void:
	# Initialize basic state
	max_time = start_time
	time_left = start_time
	max_health = start_health
	player_health = start_health
	max_lives = start_lives
	player_lives = start_lives
	# Ensure containers exist
	_ensure_containers()
	# Ensure camera exists (simple follower; you可改成你自己的）
	_ensure_camera()
	# If TileMapLayer is not present, create quick fallback platforms so你能动起来
	if not has_node("TileMapLayer"):
		_create_basic_platforms()
	# Spawn player safely
	_spawn_player()
	# Initial HUD push
	_emit_full_state()

func _process(delta: float) -> void:
	if is_game_over:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_end_game(false)
	time_changed.emit(time_left, max_time)

# ---------- Safe world setup ----------
func _ensure_containers() -> void:
	if not has_node("Enemies"):
		var enemies := Node2D.new()
		enemies.name = "Enemies"
		add_child(enemies)
	if not has_node("Items"):
		var items := Node2D.new()
		items.name = "Items"
		add_child(items)

func _ensure_camera() -> void:
	if has_node("Camera2D"):
		return
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 5.0
	add_child(cam)
	cam.make_current()

# ---------- Player lifecycle ----------
func _spawn_player() -> void:
	# Guard: player scene must be assigned in Inspector
	if player_scene == null:
		push_error("Game: player_scene is not assigned in Inspector.")
		return
	# Remove old players (if any)
	var olds := get_tree().get_nodes_in_group("player")
	for n in olds:
		n.queue_free()
	# Instantiate
	var p := player_scene.instantiate()
	p.name = "Player"
	# Start bottom-left-ish（之后你会用 TileMap 的出生点）
	p.position = Vector2(120, 520)
	# Ensure it is in the 'player' group (used by enemies & HUD)
	if not p.is_in_group("player"):
		p.add_to_group("player")
	add_child(p)
	# Camera follow
	if has_node("Camera2D"):
		$Camera2D.position_smoothing_enabled = true
		$Camera2D.make_current()

# ---------- Public helpers called by items/enemies/player ----------
func add_time(sec: float) -> void:
	if is_game_over: return
	time_left += sec
	max_time = max(max_time, time_left)
	time_changed.emit(time_left, max_time)

func add_score(points: int) -> void:
	if is_game_over: return
	score += points
	score_changed.emit(score)

func update_health(current: int) -> void:
	player_health = clamp(current, 0, max_health)
	health_changed.emit(player_health, max_health)
	if player_health <= 0:
		_on_player_died()

func heal_to_full() -> void:
	player_health = max_health
	health_changed.emit(player_health, max_health)

func add_life() -> void:
	player_lives = min(player_lives + 1, max_lives)
	lives_changed.emit(player_lives, max_lives)

func on_enemy_killed(enemy_type: String) -> void:
	match enemy_type:
		"chaser":
			chaser_kills += 1
		"shooter":
			shooter_kills += 1
	enemy_killed.emit(enemy_type)
	add_score(10)
	add_time(2.0)

# ---------- Player death / lives ----------
func _on_player_died() -> void:
	if is_game_over:
		return
	player_lives -= 1
	lives_changed.emit(player_lives, max_lives)
	if player_lives > 0:
		# Respawn with full health
		player_health = max_health
		health_changed.emit(player_health, max_health)
		_spawn_player()
	else:
		_end_game(false)

# ---------- Game end / scene change ----------
func _end_game(is_win: bool) -> void:
	if is_game_over:
		return
	is_game_over = true
	_clear_all_enemies()
	# Delay a bit, then change scene
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = 1.5
	t.timeout.connect(func() -> void:
		_change_to_end_scene(is_win)
	)
	add_child(t)
	t.start()

func _change_to_end_scene(is_win: bool) -> void:
	# Godot 4 ternary:  value_if_true if condition else value_if_false
	var target: PackedScene = win_scene if is_win else lose_scene
	if target != null:
		get_tree().change_scene_to_packed(target)
	else:
		push_warning("End scene not assigned; reloading current scene.")
		get_tree().reload_current_scene()

func _clear_all_enemies() -> void:
	if not has_node("Enemies"):
		return
	for c in $Enemies.get_children():
		if c != null:
			c.queue_free()

# ---------- Utility ----------
func _emit_full_state() -> void:
	time_changed.emit(time_left, max_time)
	score_changed.emit(score)
	health_changed.emit(player_health, max_health)
	lives_changed.emit(player_lives, max_lives)

# ---------- Fallback platforms (you会改成 TileMapLayer) ----------
func _create_basic_platforms() -> void:
	var ground := StaticBody2D.new()
	ground.name = "Ground"
	var shape := RectangleShape2D.new()
	shape.extents = Vector2(1000, 40)
	var col := CollisionShape2D.new()
	col.shape = shape
	ground.add_child(col)
	ground.position = Vector2(0, 560)
	add_child(ground)

	var plat := StaticBody2D.new()
	plat.name = "Plat1"
	var s2 := RectangleShape2D.new()
	s2.extents = Vector2(200, 20)
	var c2 := CollisionShape2D.new()
	c2.shape = s2
	plat.add_child(c2)
	plat.position = Vector2(420, 420)
	add_child(plat)
