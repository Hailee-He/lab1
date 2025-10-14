extends Area2D

# How many half-hearts (pips) to restore; 1 pip = half a heart
@export var heal_pips: int = 1

func _ready() -> void:
	# Detect when the player overlaps this pickup
	body_entered.connect(_on_body_entered)

func _on_body_entered(b: Node) -> void:
	if not b.is_in_group("player"):
		return

	# Heal the player if supported (your player.gd already has heal(by_pips))
	if b.has_method("heal"):
		b.heal(heal_pips)

	# Play heal SFX from the level (centralized audio)
	var level := get_tree().get_first_node_in_group("level")
	if level and level.has_method("sfx_play_heal"):
		level.sfx_play_heal()

	# Prevent re-trigger and remove
	set_deferred("monitoring", false)
	visible = false
	queue_free()
