extends Area2D
##
## portal_window.gd — simple one-way teleport window
## - When Player enters this Area2D, teleport them to a target Marker2D
## - Small cooldown so we don't immediately re-trigger
##

@export var target_path: NodePath        # drag WindowTargetRight here in Game scene
@export var cooldown: float = 0.3        # prevent instant re-trigger

var _locked := false

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _locked:
		return
	if not (body.name == "Player" or body.is_in_group("player")):
		return

	var target := get_node_or_null(target_path) as Node2D
	if target == null:
		return

	_locked = true
	body.global_position = target.global_position

	# tiny cooldown to avoid double-teleport in the same frame
	await get_tree().create_timer(cooldown).timeout
	_locked = false
