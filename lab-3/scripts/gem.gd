# gem.gd — collectible gem (Godot 4.x)
extends Area2D

enum GemType { RED, GREEN, PURPLE, YELLOW }

@export var type: GemType = GemType.RED
@export var red_tex: Texture2D
@export var green_tex: Texture2D
@export var purple_tex: Texture2D
@export var yellow_tex: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Group for easy lookup/debug.
	add_to_group("gem")

	# Assign the texture based on the chosen type (skip nulls safely).
	match type:
		GemType.RED:
			if red_tex:    sprite.texture = red_tex
		GemType.GREEN:
			if green_tex:  sprite.texture = green_tex
		GemType.PURPLE:
			if purple_tex: sprite.texture = purple_tex
		GemType.YELLOW:
			if yellow_tex: sprite.texture = yellow_tex

	# Signal for pickup detection.
	body_entered.connect(_on_body_entered)


func _on_body_entered(b: Node) -> void:
	# Only the player can collect.
	if not b.is_in_group("player"):
		return

	# Prevent double-collect if multiple bodies overlap in the same frame.
	set_deferred("monitoring", false)

	# Notify the level to handle gem counting + success SFX centrally.
	var level := get_tree().get_first_node_in_group("level")
	if level:
		level.add_gem()   # success SFX is played inside main.add_gem()

	# Optional: quick visual feedback before removal.
	visible = false
	queue_free()
