extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const SPEED := 250.0

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * SPEED

	if input_vector != Vector2.ZERO:
		anim.play("run")
	else:
		anim.play("idle")

	move_and_slide()
