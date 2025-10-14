extends Area2D

@export var damage: int = 1
@export var cooldown: float = 0.30          # time to re-enable monitoring
@export var knockback_x: float = 220.0      # horizontal push
@export var knockback_y: float = 240.0      # vertical pop (applied as -knockback_y)
@export var separate_pixels: float = 8.0    # small nudge to move the player out of the spike

func _ready() -> void:
	add_to_group("hazard")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Only react to the main player character body.
	if not body.is_in_group("player"):
		return

	# 1) Deal damage if present.
	if "take_damage" in body:
		body.take_damage(damage)

	# 2) If this is a CharacterBody2D, apply knockback.
	if body is CharacterBody2D:
		var p := body as CharacterBody2D
		# Push away from the spike center: -1.0 or +1.0
		var dir: float = signf(p.global_position.x - global_position.x)
		if dir == 0.0:
			dir = 1.0  # arbitrary fallback

		# Apply velocity knockback.
		p.velocity.x = clamp(p.velocity.x + dir * knockback_x, -300.0, 300.0)
		p.velocity.y = -knockback_y

		# 3) HARD SEPARATION: small teleport out of the spike to avoid sticking.
		p.global_position += Vector2(dir * separate_pixels, -2.0)

	# 4) Cooldown: stop monitoring a moment so we don't retrigger while still overlapping.
	monitoring = false
	await get_tree().create_timer(cooldown).timeout
	monitoring = true
