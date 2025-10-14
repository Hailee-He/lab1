extends Area2D
@export var damage := 1
func _ready() -> void:
	add_to_group("hazard")
	body_entered.connect(_on_hit)
func _on_hit(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)    
