# game.gd  — level root
extends Node2D
"""
Responsibilities:
- Spawn/respawn the player (at PlayerSpawn; on death: at the point where the player was ~2s ago).
- Own and emit HUD signals: time / score / HP% / revive halves / kills / shard progress.
- Track Time Shards; open the Door when enough are collected; Exit triggers win.
- Lose when: timer reaches 0 OR HP hits 0 with no revive-halves left.
- Quality-of-life: grant a short invincibility grace period after respawn to prevent spawn-kill.
"""

# -------------------- Signals (HUD subscribes) --------------------
signal time_changed(time_left: float, max_time: float)
signal score_changed(score: int)
signal health_changed(health_percent: int, max_percent: int)      # 0..100
signal lives_changed(current_halves: int, max_halves: int)        # 0..6 halves
signal enemy_killed(enemy_type: String)
signal scrolls_changed(collected: int, required: int)

# -------------------- Exports --------------------
@export var player_scene: PackedScene
@export var lose_scene: PackedScene
@export var win_scene: PackedScene

@export var player_spawn_path: NodePath = ^"PlayerSpawn"   # drag your Marker2D here
@export var fallback_spawn: Vector2 = Vector2(-500, 250)   # used if marker is missing

# Door / Exit
@export var required_scrolls: int = 5
@export var final_door_path: NodePath                      # drag Door node here

# Core tunables
@export var start_time: float = 60.0            # countdown seconds
@export var revive_halves_max: int = 6          # 6 halves = 3 full hearts on HUD
@export var kill_time_bonus: float = 2.0        # time bonus for any enemy kill

# Post-respawn invincibility (minimal-change solution to prevent instant death)
@export var respawn_grace_seconds: float = 3.0

# -------------------- Runtime State --------------------
var time_left: float
var max_time: float
var score: int = 0

# HP is a percentage 0..100
var hp_percent_max := 100
var hp_percent := 100

# Revives counted in halves (0..6)
var revive_halves_left: int
var is_game_over: bool = false

# Optional kill counters
var chaser_kills: int = 0
var shooter_kills: int = 0

# Shards
var scrolls_collected: int = 0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	max_time = start_time
	time_left = start_time
	hp_percent = hp_percent_max
	revive_halves_left = revive_halves_max

	_ensure_containers()

	# Quick fallback if level has no TileMap yet
	if not has_node("Layer1"):
		_create_basic_platforms()

	_spawn_player()

	# Initial HUD push
	_emit_full_state()
	scrolls_changed.emit(scrolls_collected, required_scrolls)

func _process(delta: float) -> void:
	if is_game_over:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_end_game(false)  # time-out lose
	time_changed.emit(time_left, max_time)

# ---------------------------------------------------------------------------
# Containers
# ---------------------------------------------------------------------------
func _ensure_containers() -> void:
	if not has_node("Enemies"):
		var enemies := Node2D.new()
		enemies.name = "Enemies"
		add_child(enemies)
	if not has_node("Items"):
		var items := Node2D.new()
		items.name = "Items"
		add_child(items)

# ---------------------------------------------------------------------------
# Player lifecycle & camera
# ---------------------------------------------------------------------------
func _get_player_spawn_pos() -> Vector2:
	var spawn: Node2D = get_node_or_null(player_spawn_path)
	return spawn.global_position if spawn else fallback_spawn

func _make_player_camera_current(p: Node) -> void:
	var cam := p.get_node_or_null("Camera2D")
	if cam and cam is Camera2D:
		(cam as Camera2D).position_smoothing_enabled = true
		(cam as Camera2D).position_smoothing_speed = 8.0
		(cam as Camera2D).make_current()
	else:
		var fallback_cam: Camera2D = get_node_or_null("Camera2D")
		if fallback_cam == null:
			fallback_cam = Camera2D.new()
			fallback_cam.name = "Camera2D"
			fallback_cam.position_smoothing_enabled = true
			fallback_cam.position_smoothing_speed = 8.0
			add_child(fallback_cam)
		fallback_cam.make_current()

func _spawn_player() -> void:
	var existing := get_tree().get_first_node_in_group("player")
	if existing and existing is Node2D:
		(existing as Node2D).global_position = _get_player_spawn_pos()
		_make_player_camera_current(existing)
		return

	if player_scene == null:
		push_error("Game: player_scene is not assigned in the Inspector.")
		return

	var p := player_scene.instantiate()
	p.name = "Player"
	if not p.is_in_group("player"):
		p.add_to_group("player")
	(p as Node2D).global_position = _get_player_spawn_pos()
	add_child(p)
	_make_player_camera_current(p)

# ---------------------------------------------------------------------------
# Public helpers (called by player/items/enemies)
# ---------------------------------------------------------------------------
func add_time(sec: float) -> void:
	if is_game_over: return
	time_left += sec
	max_time = max(max_time, time_left)
	time_changed.emit(time_left, max_time)

func add_score(points: int) -> void:
	if is_game_over: return
	score += points
	score_changed.emit(score)

# --- Health as percentage (0..100) ---
func set_health_percent(p: int) -> void:
	hp_percent = clamp(p, 0, hp_percent_max)
	health_changed.emit(hp_percent, hp_percent_max)
	if hp_percent <= 0:
		_on_player_died()

func change_health_percent(delta_percent: int) -> void:
	set_health_percent(hp_percent + delta_percent)

func heal_to_full() -> void:
	set_health_percent(hp_percent_max)

func on_enemy_killed(enemy_type: String) -> void:
	match enemy_type:
		"chaser":
			chaser_kills += 1
		"shooter":
			shooter_kills += 1
	enemy_killed.emit(enemy_type)
	add_score(10)
	add_time(kill_time_bonus)   # same bonus for both

# -------------------- Shard / Door / Exit flow --------------------
func add_scroll(amount: int = 1) -> void:
	if is_game_over: return
	scrolls_collected = clamp(scrolls_collected + amount, 0, 999)
	scrolls_changed.emit(scrolls_collected, required_scrolls)
	if scrolls_collected >= required_scrolls:
		_open_final_door()

func _open_final_door() -> void:
	var door := get_node_or_null(final_door_path)
	if door and door.has_method("open"):
		door.open()

func can_exit() -> bool:
	var door := get_node_or_null(final_door_path)
	return (door and door.has_method("is_open") and door.is_open())

func win_game() -> void:
	_end_game(true)

# -------------------- Death / Revive --------------------
func _on_player_died() -> void:
	if is_game_over:
		return

	if revive_halves_left > 0:
		revive_halves_left -= 1
		lives_changed.emit(revive_halves_left, revive_halves_max)

		# Restore HP to full
		hp_percent = hp_percent_max
		health_changed.emit(hp_percent, hp_percent_max)

		# Ask the existing player to respawn at "point 2s ago" (player script supplies this)
		var p := get_tree().get_first_node_in_group("player")
		if p and p.has_method("respawn_at_point_2s_ago"):
			p.respawn_at_point_2s_ago()
			# short invincibility to prevent instant death after respawn
			if p.has_method("grant_invincibility"):
				p.grant_invincibility(respawn_grace_seconds)
			else:
				# fallback: directly bump its invincible timer if you expose it
				if "invincible" in p:
					p.invincible = max(p.invincible, respawn_grace_seconds)
		else:
			# Fallback: respawn at spawn marker
			_spawn_player()
			var p2 := get_tree().get_first_node_in_group("player")
			if p2 and "invincible" in p2:
				p2.invincible = max(p2.invincible, respawn_grace_seconds)

	else:
		_end_game(false)

# -------------------- End game / scene change --------------------
func _end_game(is_win: bool) -> void:
	if is_game_over:
		return
	is_game_over = true
	_clear_all_enemies()

	var t := Timer.new()
	t.one_shot = true
	t.wait_time = 1.5
	t.timeout.connect(func() -> void:
		_change_to_end_scene(is_win)
	)
	add_child(t)
	t.start()

func _change_to_end_scene(is_win: bool) -> void:
	var target: PackedScene = win_scene if is_win else lose_scene
	if target != null:
		get_tree().change_scene_to_packed(target)
	else:
		push_warning("End scene not assigned; reloading current scene.")
		get_tree().reload_current_scene()

func _clear_all_enemies() -> void:
	if not has_node("Enemies"): return
	for c in $Enemies.get_children():
		if c != null:
			c.queue_free()

# -------------------- Utilities --------------------
func _emit_full_state() -> void:
	time_changed.emit(time_left, max_time)
	score_changed.emit(score)
	health_changed.emit(hp_percent, hp_percent_max)
	lives_changed.emit(revive_halves_left, revive_halves_max)

# -------------------- Fallback ground (no Layer1) --------------------
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
