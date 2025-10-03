extends Area2D

@export var required_wisps: int = 3
@export var next_scene: String = "res://scenes/SecretZone.tscn"

var wisp_inside: Array = []
var enough_wisps_collected: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("wisp") and body not in wisp_inside:
		wisp_inside.append(body)
		_check_wisp_count()
		
func _on_body_exited(body):
	if body.is_in_group("wisp") and body in wisp_inside:
		wisp_inside.erase(body)
		_check_wisp_count()

func _check_wisp_count():
	if wisp_inside.size() >= required_wisps and not enough_wisps_collected:
		print("Trigger condition met! Opening tomb...")
		enough_wisps_collected = true
		
		# Search for the tombstone in the scene
		var tombstone = get_tree().get_first_node_in_group("tombstone")
		if tombstone and tombstone.has_method("open_tomb"):
			tombstone.open_tomb(next_scene)			
