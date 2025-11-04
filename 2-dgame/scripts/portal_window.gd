extends Area2D
##
## portal_window.gd — simple one-way teleport window
## - When Player enters this Area2D, teleport them to a target Marker2D
## - Small cooldown so we don't immediately re-trigger
## - Optional SFX when teleport occurs
##

# Target marker on the right side (or wherever you want to appear)
@export var target_path: NodePath        # drag WindowTargetRight (Marker2D) here in Game scene

# Cooldown to prevent instant re-triggering
@export var cooldown: float = 0.3        # seconds

# --- NEW: teleport SFX support ---
# Path to an AudioStreamPlayer2D child used to play the teleport sound
@export var sfx_node_path: NodePath = ^"SFXTeleport"

# Cached reference to the SFX player (may be null if you don't add one)
@onready var _sfx_teleport: AudioStreamPlayer2D = get_node_or_null(sfx_node_path)

var _locked: bool = false    # prevents double-teleport during cooldown

# ============================================================
# Lifecycle
# ============================================================
func _ready() -> void:
	# Enable area detection so we can receive body_entered
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)

# ============================================================
# Teleport logic
# ============================================================
func _on_body_entered(body: Node) -> void:
	# Already teleported recently? ignore until cooldown ends
	if _locked:
		return

	# Only react to the player
	if not (body.name == "Player" or body.is_in_group("player")):
		return

	# Find target marker (Node2D) from exported path
	var target := get_node_or_null(target_path) as Node2D
	if target == null:
		return

	_locked = true

	# Move player to target global position
	body.global_position = target.global_position

	# --- NEW: play teleport SFX if available ---
	if _sfx_teleport:
		_sfx_teleport.play()

	# Tiny cooldown to avoid double-teleport in the same frame
	await get_tree().create_timer(cooldown).timeout
	_locked = false
