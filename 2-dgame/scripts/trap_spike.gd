extends Area2D
## Static floor trap that damages the player over time.
@export var damage_percent: int = 5        # each tick deals 5% HP
@export var tick_sec: float = 0.5          # damage every 0.5s
@export var warn_blink: bool = true

var _inside := false
var _acc := 0.0

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 1 << 4      # Items layer (5th bit -> index 4)
	collision_mask  = 1 << 1      # Player only
	body_entered.connect(func(body):
		if body.is_in_group("player"): _inside = true
	)
	body_exited.connect(func(body):
		if body.is_in_group("player"): _inside = false; _acc = 0.0
	)

func _process(delta: float) -> void:
	if warn_blink:
		modulate.a = 0.6 + 0.4 * abs(sin(Time.get_ticks_msec()/300.0))
	if not _inside: return
	_acc += delta
	if _acc >= tick_sec:
		_acc -= tick_sec
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("take_damage"):
			# 按你现在的设计，take_damage 参数就是“百分比”
			player.take_damage(damage_percent)
