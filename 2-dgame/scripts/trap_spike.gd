extends Area2D
##
## Static floor trap that damages the player over time.
## - Player-only Area2D
## - While the player stays inside, deals damage every `tick_sec`
## - Optional warning blink using alpha modulation
## - Plays a hit SFX each time damage is applied
##

# How much HP% to remove per tick (works with your Game HP-percent system)
@export var damage_percent: int = 5        # each tick deals 5% HP
@export var tick_sec: float = 0.5          # damage every 0.5s
@export var warn_blink: bool = true        # blink visually while active

# Optional: which AudioStreamPlayer2D to use for the hit SFX
@export var sfx_node_path: NodePath = ^"SFXHit"

# Cached SFX node (can be null if you don't add it)
@onready var _sfx_hit: AudioStreamPlayer2D = get_node_or_null(sfx_node_path)

var _inside: bool = false  # is the player currently inside?
var _acc: float = 0.0      # time accumulator for damage ticks

# ============================================================
# Lifecycle
# ============================================================
func _ready() -> void:
	# Enable area detection
	monitoring = true
	monitorable = true

	# Layers/Masks (your mapping: 0=World,1=Player,2=Enemy,3=Bullet,4=Items)
	# Trap lives on Items layer and only detects Player
	collision_layer = 1 << 4      # Items layer
	collision_mask  = 1 << 1      # Player only

	# Connect signals so we know when the player enters/leaves
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# ============================================================
# Area signals
# ============================================================
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_inside = true
		_acc = 0.0

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_inside = false
		_acc = 0.0

# ============================================================
# Tick damage + warning blink
# ============================================================
func _process(delta: float) -> void:
	# Optional warning blink (alpha pulsing)
	if warn_blink:
		modulate.a = 0.6 + 0.4 * abs(sin(Time.get_ticks_msec() / 300.0))

	if not _inside:
		return

	_acc += delta
	if _acc >= tick_sec:
		_acc -= tick_sec

		# Deal damage to the player (percent-based)
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("take_damage"):
			# In your design, `take_damage` parameter is "percent points"
			player.take_damage(damage_percent)

			# Play hit SFX once per tick
			if _sfx_hit:
				_sfx_hit.play()
