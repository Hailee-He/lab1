extends RigidBody2D

# --- Tunables ---------------------------------------------------------------
@export var damage: int = 1                     # Damage dealt to the player on hit
@export var gravity_scale_on_fall: float = 1.0  # Gravity used once the rock starts falling
@export var auto_freeze: bool = true            # Start frozen/suspended in the air
@export var remove_after_hit: bool = false      # Free the rock after hurting the player
@export var one_shot_trigger: bool = true       # Disable trigger after first activation
@export var fall_delay: float = 0.0             # NEW: delay (seconds) after trigger before falling

# Child nodes
@onready var trigger: Area2D = $Trigger         # Area2D child used as a fall trigger

# --- Setup ------------------------------------------------------------------
func _ready() -> void:
	# Tag for filtering/group checks if needed.
	add_to_group("hazard")

	# Start suspended: no gravity, no motion.
	gravity_scale = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	if auto_freeze:
		# Use deferred to avoid "flushing queries" on enter-tree.
		set_deferred("freeze", true)

	# Enable contact callbacks so body_entered will be emitted.
	contact_monitor = true
	max_contacts_reported = 4

	# Connect signals safely.
	if trigger != null:
		trigger.body_entered.connect(_on_trigger_body_entered)
	else:
		push_error("Rock: Trigger (Area2D) not found. Child must be named 'Trigger'.")

	# Collisions against other bodies (e.g., the player)
	body_entered.connect(_on_body_entered)

# --- Trigger → (optional delay) → fall --------------------------------------
func _on_trigger_body_entered(other: Node) -> void:
	# Only react when the player enters the trigger.
	if not other.is_in_group("player"):
		return

	# Prevent retrigger spam while falling (optional one-shot).
	if one_shot_trigger and trigger:
		trigger.set_deferred("monitoring", false)

	# NEW: wait some time before starting to fall (per-instance, via Inspector).
	if fall_delay > 0.0:
		await get_tree().create_timer(fall_delay).timeout

	_start_fall()

# --- Start falling -----------------------------------------------------------
func _start_fall() -> void:
	# Switch to falling state. Use deferred updates inside the physics step.
	set_deferred("gravity_scale", gravity_scale_on_fall)
	if auto_freeze:
		set_deferred("freeze", false)  # unfreeze so gravity can act
	# Make sure the rigid body wakes up.
	set_deferred("sleeping", false)

# --- On collision: hurt player ----------------------------------------------
func _on_body_entered(other: Node) -> void:
	# Deal damage to the player on contact.
	if other.is_in_group("player"):
		if other.has_method("take_damage"):
			other.take_damage(damage)
		# Optionally delete after the first hit
		if remove_after_hit:
			queue_free()
