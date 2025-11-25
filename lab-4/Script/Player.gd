extends CharacterBody3D

const SPEED = 3.0
const MOUSE_SENSITIVITY = 0.002
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
const FOOTSTEP_INTERVAL = 0.5

var t_bob = 0.0
var footstep_timer = 0.0
var footstep_index = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $Camera3D
@onready var footstep_player = $FootstepPlayer

var footstep_sounds = [
	preload("res://Assets/Audio/Footsteps_DirtyGround_Run_01.wav"),
	preload("res://Assets/Audio/Footsteps_DirtyGround_Run_02.wav")
]

var can_move = true

func _ready():
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if not can_move:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not can_move:
		move_and_slide()
		return

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Move_A", "Move_D", "Move_W", "Move_S")
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# Stair stepping logic
	if is_on_floor() and is_on_wall() and direction.length() > 0:
		var step_height = 0.5
		var original_pos = global_position
		
		# 1. Check if we can move up
		if test_move(global_transform, Vector3(0, step_height, 0)):
			return # Hit ceiling
			
		# 2. Move up virtually
		global_position.y += step_height
		
		# 3. Check if we can move forward at the new height
		var forward_move = direction * SPEED * delta
		if test_move(global_transform, forward_move):
			# Still blocked
			global_position = original_pos
			return
			
		# 4. Apply forward movement
		global_position += forward_move
		
		# 5. Snap down to the step
		var down_move = Vector3(0, -step_height, 0)
		var collision = move_and_collide(down_move)
		
		if not collision:
			# Didn't find a floor to land on, revert
			global_position = original_pos
		else:
			# Successfully stepped up - play footstep sound
			if footstep_player and not footstep_player.playing:
				footstep_player.stream = footstep_sounds[footstep_index]
				footstep_player.play()
				footstep_index = (footstep_index + 1) % footstep_sounds.size()

	# Head bob effect
	if velocity.length() > 0.1 and is_on_floor():
		t_bob += delta * velocity.length() * float(is_on_floor())
		var target_y = 1.5 + sin(t_bob * BOB_FREQ) * BOB_AMP
		camera.transform.origin.y = lerp(camera.transform.origin.y, target_y, 15 * delta)
		
		# Footstep sound - alternate between two sounds
		footstep_timer += delta
		if footstep_timer >= FOOTSTEP_INTERVAL:
			footstep_timer = 0.0
			if footstep_player:
				footstep_player.stream = footstep_sounds[footstep_index]
				footstep_player.play()
				footstep_index = (footstep_index + 1) % footstep_sounds.size()
	else:
		# Reset to default height
		camera.transform.origin.y = lerp(camera.transform.origin.y, 1.5, 10 * delta)
		footstep_timer = 0.0
