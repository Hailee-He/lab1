extends Area2D

@export var required_wisps: int = 3
@export var next_scene: String = "res://scenes/SecretZone.tscn"

var wisp_inside: Array = []
var triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("agents") and not body in wisp_inside:
		wisp_inside.append(body)
		_check_trigger()

func _on_body_exited(body):
	if body.is_in_group("agents") and body in wisp_inside:
		wisp_inside.erase(body)
		_check_trigger()

func _check_trigger():
	if not triggered and wisp_inside.size() >= required_wisps:
		triggered = true
		var tomb = get_tree().get_first_node_in_group("tombstone")
		if tomb and tomb.has_method("open_tomb"):
			tomb.open_tomb(next_scene)
