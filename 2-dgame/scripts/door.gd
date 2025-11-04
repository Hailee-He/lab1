extends Node2D
##
## door.gd — exit door logic
## - Shows a closed sprite when blocked, and an open sprite when passable
## - Enables / disables the CollisionShape2D that blocks the player
## - Emits signals when opening / closing (HUD or other systems can listen)
## - Optionally plays an SFX when the door opens
##

signal door_opened
signal door_closed

# Sprites for the two visual states
@export var closed_sprite: Texture2D        # e.g. doorClosed_mid.png
@export var opened_sprite: Texture2D        # e.g. doorOpen_mid.png

# Paths to child nodes (adjust if your scene uses different names)
@export var solid_shape_path: NodePath = ^"StaticBody2D/CollisionShape2D"
@export var sprite_path: NodePath      = ^"Sprite2D"

# NEW: optional AudioStreamPlayer(2D) for "door open" SFX
@export var sfx_open_path: NodePath = ^"SFXOpen"

# Internal state flag
var _is_open: bool = false

# Cache child nodes on ready for faster / safer access
@onready var _sprite: Sprite2D = get_node_or_null(sprite_path) as Sprite2D
@onready var _sfx_open: AudioStreamPlayer = get_node_or_null(sfx_open_path) as AudioStreamPlayer


func _ready() -> void:
	# Make sure the initial visuals match the starting state
	_apply_visuals()


func is_open() -> bool:
	## Small helper so Game.gd can query the state.
	return _is_open


func open() -> void:
	## Open the door:
	## - disable collider
	## - swap sprite
	## - play open SFX
	## - emit signal
	if _is_open:
		return

	_is_open = true

	var shape := get_node_or_null(solid_shape_path) as CollisionShape2D
	if shape:
		# Use set_deferred so we don't change physics state in the middle of a signal
		shape.set_deferred("disabled", true)

	_apply_visuals()

	# Play sound if the SFX node exists
	if _sfx_open:
		_sfx_open.play()

	door_opened.emit()


func close() -> void:
	## Close the door:
	## - enable collider
	## - swap sprite back
	## - emit signal
	if not _is_open:
		return

	_is_open = false

	var shape := get_node_or_null(solid_shape_path) as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", false)

	_apply_visuals()
	door_closed.emit()


func toggle() -> void:
	## Convenience: flip between open and closed.
	if _is_open:
		close()
	else:
		open()
		

func _apply_visuals() -> void:
	## Update the Sprite2D texture according to _is_open.
	if not _sprite: 
		return

	if _is_open:
		if opened_sprite:
			_sprite.texture = opened_sprite
	else:
		if closed_sprite:
			_sprite.texture = closed_sprite
