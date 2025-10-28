# res://scripts/hud.gd
extends CanvasLayer

# --- textures for 3 hearts ---
const TEX_HEART_FULL  : Texture2D = preload("res://Asset/sprite/hudHeart_full.png")
const TEX_HEART_HALF  : Texture2D = preload("res://Asset/sprite/hudHeart_half.png")
const TEX_HEART_EMPTY : Texture2D = preload("res://Asset/sprite/hudHeart_empty.png")

# --- cache nodes (match your scene tree exactly) ---
@onready var _row      : HBoxContainer = $"MarginContainer/HBoxContainer"
@onready var _h1       : TextureRect   = $"MarginContainer/HBoxContainer/Hearts/Heart1"
@onready var _h2       : TextureRect   = $"MarginContainer/HBoxContainer/Hearts/Heart2"
@onready var _h3       : TextureRect   = $"MarginContainer/HBoxContainer/Hearts/Heart3"
@onready var _timebar  : ProgressBar   = $"MarginContainer/HBoxContainer/TimeBar"
@onready var _time_lbl : Label         = $"MarginContainer/HBoxContainer/TimeLabel"
@onready var _kill_lbl : Label         = $"MarginContainer/HBoxContainer/KillLabel"

# kill counters
var _chaser_kills : int = 0
var _shooter_kills: int = 0

func _ready() -> void:
	# connect to Game signals (if present)
	var game := get_tree().root.get_node_or_null("Game")
	if game:
		if game.has_signal("time_changed"):
			game.time_changed.connect(_on_time_changed)
		if game.has_signal("score_changed"):
			game.score_changed.connect(_on_score_changed)
		if game.has_signal("health_changed"):
			game.health_changed.connect(_on_health_changed)
		if game.has_signal("enemy_killed"):
			game.enemy_killed.connect(_on_enemy_killed)
	else:
		push_warning("HUD: cannot find /root/Game, signals not connected.")

	# initial UI state
	_timebar.min_value = 0
	_timebar.max_value = 100
	_timebar.value = 100
	_time_lbl.text = "60.0s"
	_kill_lbl.text = "Chaser: 0\nShooter: 0"
	_set_hearts(3)  # show 3 full hearts at start

# -------------------- signal handlers --------------------

func _on_time_changed(time_left: float, max_time: float) -> void:
	var pct: float = 0.0
	if max_time > 0.0:
		pct = clamp(time_left / max_time, 0.0, 1.0)
	_timebar.value = pct * 100.0
	_time_lbl.text = "%.1fs" % time_left

	# simple color feedback (no ternary)
	if pct < 0.2:
		_timebar.modulate = Color(1.0, 0.3, 0.3)
	elif pct < 0.4:
		_timebar.modulate = Color(1.0, 0.8, 0.3)
	else:
		_timebar.modulate = Color(0.3, 1.0, 0.3)

func _on_health_changed(current_health: int, _max_health: int) -> void:
	_set_hearts(current_health)

func _on_score_changed(_score: int) -> void:
	# keep for future FX if needed
	pass

func _on_enemy_killed(enemy_type: String) -> void:
	match enemy_type:
		"chaser":
			_chaser_kills += 1
		"shooter":
			_shooter_kills += 1
	_update_kill_label()

# -------------------- helpers --------------------

func _set_hearts(h: int) -> void:
	# clamp to [0,3]
	h = clamp(h, 0, 3)

	# default empty
	_h1.texture = TEX_HEART_EMPTY
	_h2.texture = TEX_HEART_EMPTY
	_h3.texture = TEX_HEART_EMPTY

	# fill according to health value (no optional chain / ternary)
	if h >= 1:
		_h1.texture = TEX_HEART_FULL if h >= 2 else TEX_HEART_HALF
	if h >= 2:
		_h2.texture = TEX_HEART_FULL if h >= 3 else TEX_HEART_HALF
	if h >= 3:
		_h3.texture = TEX_HEART_FULL

func _update_kill_label() -> void:
	_kill_lbl.text = "Chaser: %d\nShooter: %d" % [_chaser_kills, _shooter_kills]
