extends CanvasLayer
# HUD for: hearts (lives as half-hearts), HEALTH BAR (ProgressBar),
# time text only, shard row, and kill counters.

# ---------- Heart textures ----------
const TEX_HEART_FULL  : Texture2D = preload("res://Asset/sprite/hudHeart_full.png")
const TEX_HEART_HALF  : Texture2D = preload("res://Asset/sprite/hudHeart_half.png")
const TEX_HEART_EMPTY : Texture2D = preload("res://Asset/sprite/hudHeart_empty.png")

# ---------- Shard tint colors (we only have one colored icon) ----------
const COLOR_LIT : Color = Color(1, 1, 1, 1)         # collected
const COLOR_DIM : Color = Color(0.6, 0.6, 0.6, 0.6) # not collected

# ---------- Node references (match your scene tree) ----------
@onready var _h1         : TextureRect   = $"MarginContainer/HBoxContainer/Hearts/Heart1"
@onready var _h2         : TextureRect   = $"MarginContainer/HBoxContainer/Hearts/Heart2"
@onready var _h3         : TextureRect   = $"MarginContainer/HBoxContainer/Hearts/Heart3"

# NOTE: TimeBar was renamed to HealthBar in the scene.
@onready var _healthbar  : ProgressBar   = $"MarginContainer/HBoxContainer/HealthBar"
@onready var _time_lbl   : Label         = $"MarginContainer/HBoxContainer/TimeLabel"
@onready var _kill_lbl   : Label         = $"MarginContainer/HBoxContainer/KillLabel"

@onready var _shards_box : HBoxContainer = $"MarginContainer/HBoxContainer/Shards"
var _shard_slots : Array[TextureRect] = []  # S1..S5 will be collected here

# ---------- Local counters (purely visual) ----------
var _chaser_kills  : int = 0
var _shooter_kills : int = 0
var _hp_percent    : int = 100

func _ready() -> void:
	# Collect S1..S5 and dim them initially
	for c in _shards_box.get_children():
		if c is TextureRect:
			_shard_slots.append(c)
	for s in _shard_slots:
		s.modulate = COLOR_DIM

	# HealthBar initial state (we use it as HP bar now)
	_healthbar.min_value = 0
	_healthbar.max_value = 100
	_healthbar.value     = 100
	_healthbar.modulate  = Color(0.3, 1.0, 0.3)  # green when healthy

	# Time is shown as plain text only
	_time_lbl.text = "60.0s"

	# Hearts start as 3 full (== 6 half-hearts)
	_set_hearts_from_halves(6)

	# Connect to Game signals
	var game := get_tree().root.get_node_or_null("Game")
	if game:
		if game.has_signal("time_changed"):
			# Only updates the time text; HealthBar no longer reflects time.
			game.time_changed.connect(_on_time_changed)
		if game.has_signal("enemy_killed"):
			game.enemy_killed.connect(_on_enemy_killed)
		if game.has_signal("scrolls_changed"):
			game.scrolls_changed.connect(_on_scrolls_changed)
		if game.has_signal("lives_changed"):
			# Expecting (current_halves:int, max_halves:int)
			game.lives_changed.connect(_on_lives_changed)
		if game.has_signal("health_changed"):
			# Expecting (health_percent:int, max_percent:int=100)
			game.health_changed.connect(_on_health_changed)
	else:
		push_warning("HUD: cannot find /root/Game; signals not connected.")

# ---------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------

# Time is text-only now (no more progress bar for time).
func _on_time_changed(time_left: float, _max_time: float) -> void:
	_time_lbl.text = "%.1fs" % time_left

# HealthBar: 0..100; also recolor for quick feedback.
func _on_health_changed(health_percent: int, _max_percent: int) -> void:
	_hp_percent = clamp(health_percent, 0, 100)
	_healthbar.value = _hp_percent

	if _hp_percent < 25:
		_healthbar.modulate = Color(1.0, 0.3, 0.3)   # red - critical
	elif _hp_percent < 60:
		_healthbar.modulate = Color(1.0, 0.85, 0.3)  # yellow - medium
	else:
		_healthbar.modulate = Color(0.3, 1.0, 0.3)   # green - good

# Lives shown as 3 hearts = 6 half-hearts
func _on_lives_changed(current_halves: int, _max_halves: int) -> void:
	_set_hearts_from_halves(current_halves)

func _on_enemy_killed(enemy_type: String) -> void:
	match enemy_type:
		"chaser":  _chaser_kills += 1
		"shooter": _shooter_kills += 1
	_update_kill_label()

func _on_scrolls_changed(collected: int, required: int) -> void:
	_refresh_shard_icons(collected, required)

# ---------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------

# Input: 0..6 half-hearts → draw 3 heart sprites accordingly
func _set_hearts_from_halves(halves: int) -> void:
	halves = clamp(halves, 0, 6)
	var full := halves / 2          # number of full hearts
	var has_half := (halves % 2)==1 # one half-heart to place

	# reset
	_h1.texture = TEX_HEART_EMPTY
	_h2.texture = TEX_HEART_EMPTY
	_h3.texture = TEX_HEART_EMPTY

	# heart 1
	if full >= 1: _h1.texture = TEX_HEART_FULL
	elif has_half and full == 0: _h1.texture = TEX_HEART_HALF
	# heart 2
	if full >= 2: _h2.texture = TEX_HEART_FULL
	elif has_half and full == 1: _h2.texture = TEX_HEART_HALF
	# heart 3
	if full >= 3: _h3.texture = TEX_HEART_FULL
	elif has_half and full == 2: _h3.texture = TEX_HEART_HALF

func _update_kill_label() -> void:
	_kill_lbl.text = "Chaser: %d\nShooter: %d" % [_chaser_kills, _shooter_kills]

# Light up the first `collected` slots and only show the first `required` ones.
func _refresh_shard_icons(collected: int, required: int) -> void:
	for i in range(_shard_slots.size()):
		var slot := _shard_slots[i]
		slot.visible  = i < required
		slot.modulate = COLOR_LIT if i < collected else COLOR_DIM
