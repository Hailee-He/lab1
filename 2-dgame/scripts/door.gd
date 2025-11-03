extends Node2D

signal door_opened
signal door_closed

@export var closed_sprite: Texture2D
@export var opened_sprite: Texture2D

# Adjust if your scene uses different node names
@export var solid_shape_path: NodePath = ^"StaticBody2D/CollisionShape2D"
@export var sprite_path: NodePath      = ^"Sprite2D"

var _is_open: bool = false

func _ready() -> void:
	_apply_visuals()

func is_open() -> bool:
	return _is_open

func open() -> void:
	if _is_open:
		return
	_is_open = true
	var shape := get_node_or_null(solid_shape_path) as CollisionShape2D
	if shape:
		# change collider safely during signals/physics
		shape.set_deferred("disabled", true)
	_apply_visuals()
	door_opened.emit()

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	var shape := get_node_or_null(solid_shape_path) as CollisionShape2D
	if shape:
		shape.set_deferred("disabled", false)
	_apply_visuals()
	door_closed.emit()

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func _apply_visuals() -> void:
	var spr := get_node_or_null(sprite_path) as Sprite2D
	if not spr:
		return
	if _is_open:
		if opened_sprite:
			spr.texture = opened_sprite
	else:
		if closed_sprite:
			spr.texture = closed_sprite
