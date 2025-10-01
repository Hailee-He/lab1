extends Area2D

@export var slime_speed : float = -50

var is_dead : bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# If slime is not dead, slime can move.
	if not is_dead:
		position += Vector2(slime_speed, 0) * delta
	
	# If slime goes to the left of screen, then delete the slime
	if position.x < -250:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# If the player's character enters the slime's area and the slime is still alive, then the player loses the game.
	if body is CharacterBody2D and not is_dead:
		body.game_over()
		


func _on_area_entered(area: Area2D) -> void:
	# Detect whether the object that hit the slime was a bullet
	if area.is_in_group("bullet"):
		# Play the animation of being eliminated and eliminate the bullets
		$AnimatedSprite2D.play("death")
		is_dead = true
		area.queue_free()
		get_tree().current_scene.score += 1
		$DeathSound.play()
		
		# Remove the slime node after a delay of 0.6 seconds.
		await get_tree().create_timer(0.6).timeout
		queue_free()
