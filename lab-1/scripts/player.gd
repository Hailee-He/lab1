extends CharacterBody2D

# Player movement speed and animation player
@export var move_speed : float = 100
@export var animator : AnimatedSprite2D

# Boolean variable: true or false
@export var is_game_over : bool = false

@export var bullet_scene : PackedScene

func _process(delta: float) -> void:
	if velocity == Vector2.ZERO or is_game_over:
		$RunningSound.stop()
	elif not $RunningSound.playing:
		$RunningSound.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# If the game is not over, then move the character based on the player's input.
	if not is_game_over:
		velocity = Input.get_vector("left","right","up","down") * move_speed
		
		# If the speed is 0, play the idle animation.
		if velocity == Vector2.ZERO:
			animator.play("idle")
		# If the speed is not 0, play the running animation.
		else:
			animator.play("run")	
			
		move_and_slide()

func game_over():
	if not is_game_over:
		# Set the game to end and play the failure animation
		is_game_over = true
		animator.play("game_over")
		
		get_tree().current_scene.show_game_over()
		$GameOverSound.play()
		
		# Wait for 3s before restarting the game.
		$RestartTimer.start()


func _on_fire() -> void:
	# If the player is moving or the game has ended, no bullets will be generated.
	if velocity != Vector2.ZERO or is_game_over:
		return
	
	$firesound.play()
	
	# Create the bullet node, set the correct position of the bullet, and add it to the scene tree.
	var bullet_node = bullet_scene.instantiate()
	bullet_node.position = position + Vector2(6,6)
	get_tree().current_scene.add_child(bullet_node)

func _reload_screne() -> void:
	get_tree().reload_current_scene()
