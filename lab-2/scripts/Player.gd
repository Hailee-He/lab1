extends CharacterBody2D

@export var speed := 250.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * speed
	move_and_slide()

	if input_vector != Vector2.ZERO:
		if anim.animation != "run":
			anim.play("run")
		if input_vector.x != 0:
			scale.x = sign(input_vector.x)  # flip left/right
	else:
		if anim.animation != "idle":
			anim.play("idle")
