extends Node

@export var player: CharacterBody3D
@export var fade_overlay: ColorRect
@export var food_object: Node3D
@export var chair_object: Node3D
@export var interaction_label: Label
@export var end_label: Label
@export var ambient_sounds: Array[AudioStreamPlayer3D]
@export var directional_lights: Array[DirectionalLight3D]
@export var scene_lights: Array[Node3D]
@export var emergency_light: SpotLight3D

var breath_sound = preload("res://Assets/Audio/Voice_Male_V1_Breath_Nose_Single_Mono_03.wav")
var food_sounds = [
	preload("res://Assets/Audio/tableware_crash1.mp3"),
	preload("res://Assets/Audio/instant_coffee_O.mp3"),
	preload("res://Assets/Audio/drinking1.mp3")
]
var sit_sound = preload("res://Assets/Audio/sitting_on_a_chair1.mp3")
var dream_sound_1 = preload("res://Assets/Audio/walking_on_night_streets.mp3")
var dream_sound_2 = preload("res://Assets/Audio/electrical_noise1.mp3")
var dream_sound_3 = preload("res://Assets/Audio/Urban nuclear detonation with building collapse and infrastructure destruction.wav")
var wake_up_gasp = preload("res://Assets/Audio/Voice_Male_V1_Breath_Gasp_Mono_02.wav")
var breaker_sound = preload("res://Assets/Audio/cutting_a_breaker.mp3")
var door_sound_1 = preload("res://Assets/Audio/open_the_door1.mp3")
var door_sound_2 = preload("res://Assets/Audio/open_the_door2.mp3")
var door_sound_3 = preload("res://Assets/Audio/open_the_door3.mp3")
var shed_door_sound = preload("res://Assets/Audio/shed_door_O.mp3")
var terror_sound = preload("res://Assets/Audio/coming_of_terror.mp3")
var mad_breath_sound = preload("res://Assets/Audio/mad_breath1.mp3")
var running_hall_sound = preload("res://Assets/Audio/running_in_a_hall.mp3")

var is_interacting = false
var has_eaten = false
var is_tired = false
var has_slept = false
var blink_timer = 0.0
var blink_interval = 5.0

func _ready():
	if interaction_label:
		interaction_label.visible = false
		
	if player:
		player.can_move = false
	
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)
		fade_overlay.visible = true
		
		# Wait a bit before opening eyes
		await get_tree().create_timer(2.0).timeout
		
		var tween = create_tween()
		# Eye opening effect
		# 1. Open slightly
		tween.tween_property(fade_overlay, "color:a", 0.2, 1.5).set_trans(Tween.TRANS_SINE)
		# 2. Close again (blink)
		tween.tween_property(fade_overlay, "color:a", 0.9, 0.3)
		# 3. Open fully
		tween.tween_property(fade_overlay, "color:a", 0.0, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		await tween.finished
		fade_overlay.visible = false
		
		# Play breath sound
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = breath_sound
		audio_player.play()
		
		if player:
			player.can_move = true
			
		await audio_player.finished
		audio_player.queue_free()

func _process(delta):
	if not player or not interaction_label or is_interacting or has_slept:
		return
	
	# Blinking effect when tired
	if is_tired and not is_interacting:
		blink_timer += delta
		if blink_timer >= blink_interval:
			blink_timer = 0.0
			blink_interval = randf_range(3.0, 8.0) # Randomize next blink
			perform_blink()

	# Interaction logic
	var target_object = null
	var interaction_text = ""
	
	if not has_eaten and food_object:
		if player.global_position.distance_to(food_object.global_position) < 3.0:
			target_object = food_object
			interaction_text = "Press E to get food"
			
	elif is_tired and chair_object:
		if player.global_position.distance_to(chair_object.global_position) < 3.0:
			target_object = chair_object
			interaction_text = "Press E to rest"
	
	if target_object:
		interaction_label.text = interaction_text
		interaction_label.visible = true
		# Input check moved to _unhandled_input to avoid "Interact" action error
	else:
		interaction_label.visible = false

func _unhandled_input(event):
	# Fallback if "Interact" action is not defined
	if not player or not interaction_label or is_interacting or has_slept:
		return
		
	if interaction_label.visible and event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if not has_eaten and food_object and player.global_position.distance_to(food_object.global_position) < 3.0:
			start_eating_sequence()
		elif is_tired and chair_object and player.global_position.distance_to(chair_object.global_position) < 3.0:
			start_sleeping_sequence()

func perform_blink():
	if not fade_overlay: return
	
	fade_overlay.visible = true
	var tween = create_tween()
	# Quick blink
	tween.tween_property(fade_overlay, "color:a", 0.8, 0.15)
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.15)
	
	await tween.finished
	fade_overlay.visible = false

func start_eating_sequence():
	is_interacting = true
	has_eaten = true
	interaction_label.visible = false
	
	if player:
		player.can_move = false
		
	for sound in food_sounds:
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = sound
		audio_player.play()
		await audio_player.finished
		audio_player.queue_free()
		
	if player:
		player.can_move = true
	is_interacting = false
	
	# Start timer for tiredness
	await get_tree().create_timer(30.0).timeout
	is_tired = true

func start_sleeping_sequence():
	is_interacting = true
	has_slept = true
	interaction_label.visible = false
	
	if player:
		player.can_move = false
		# Move player to chair position (simple approximation)
		# Adjust y to sit/lie down
		var target_pos = chair_object.global_position
		target_pos.y += 0.5 
		var tween_move = create_tween()
		tween_move.tween_property(player, "global_position", target_pos, 1.0)
		# Look forward/up
		tween_move.parallel().tween_property(player.camera, "rotation:x", deg_to_rad(-20), 1.0)
		
		# Play sit sound
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = sit_sound
		audio_player.play()
		
		await tween_move.finished
		await audio_player.finished
		audio_player.queue_free()
	
	# Closing eyes effect
	if fade_overlay:
		fade_overlay.visible = true
		var tween = create_tween()
		# Slowly close eyes
		tween.tween_property(fade_overlay, "color:a", 1.0, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Fade out audio
		var audio_bus_index = AudioServer.get_bus_index("Master")
		var initial_volume = AudioServer.get_bus_volume_db(audio_bus_index)
		tween.parallel().tween_method(func(val): AudioServer.set_bus_volume_db(audio_bus_index, val), initial_volume, -80.0, 4.0)
		
		await tween.finished
		
	# Dream Sequence
	# Stop ambient sounds
	for sound in ambient_sounds:
		if sound: sound.stop()
	
	# Restore Master volume for dream sounds
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 0.0)

	# Play Sound A (walking_on_night_streets)
	var player_a = AudioStreamPlayer.new()
	add_child(player_a)
	player_a.stream = dream_sound_1
	player_a.volume_db = -80.0
	player_a.play()
	
	var tween_a = create_tween()
	tween_a.tween_property(player_a, "volume_db", 0.0, 5.0)

	# Wait 12s
	await get_tree().create_timer(12.0).timeout
	
	# Play Sound B (electrical_noise1)
	var player_b = AudioStreamPlayer.new()
	add_child(player_b)
	player_b.stream = dream_sound_2
	player_b.volume_db = -80.0
	player_b.play()
	
	var tween_b = create_tween()
	tween_b.tween_property(player_b, "volume_db", 0.0, 5.0)

	# Wait 8s (Total 20s from start of A)
	await get_tree().create_timer(8.0).timeout
	
	# Stop A and B
	player_a.stop()
	player_b.stop()
	player_a.queue_free()
	player_b.queue_free()
	
	# Play Sound C (Explosion)
	var player_c = AudioStreamPlayer.new()
	add_child(player_c)
	player_c.stream = dream_sound_3
	player_c.play()
	
	await player_c.finished
	player_c.queue_free()
	
	# Wake up
	# Play Gasp
	var player_d = AudioStreamPlayer.new()
	add_child(player_d)
	player_d.stream = wake_up_gasp
	player_d.play()
	
	# Restore visuals
	if fade_overlay:
		var tween_wake = create_tween()
		tween_wake.tween_property(fade_overlay, "color:a", 0.0, 0.5)
		await tween_wake.finished
		fade_overlay.visible = false
	
	# Restore ambient sounds
	for sound in ambient_sounds:
		if sound: sound.play()
		
	# Change light energy
	for light in directional_lights:
		if light:
			light.light_energy = 0.7
		
	# Restore control
	if player:
		player.can_move = true
		var tween_reset = create_tween()
		tween_reset.tween_property(player.camera, "rotation:x", 0.0, 0.5)
		
	is_interacting = false
	has_slept = false
	is_tired = false
	
	# Wait 10s then play breaker sound and turn off lights
	await get_tree().create_timer(10.0).timeout
	
	var player_breaker = AudioStreamPlayer.new()
	add_child(player_breaker)
	player_breaker.stream = breaker_sound
	player_breaker.play()
	
	# Stop ambient sounds
	for sound in ambient_sounds:
		if sound: sound.stop()
	
	# Turn off all lights
	# Directional lights
	for light in directional_lights:
		if light:
			light.light_energy = 0.0
			
	# Scene lights (Light nodes)
	for light_node in scene_lights:
		if light_node:
			light_node.set_process(false) # Stop flickering script
			var spot_light = light_node.get_node_or_null("SpotLight3D")
			if spot_light:
				spot_light.visible = false
				spot_light.light_energy = 0.0
	
	await player_breaker.finished
	player_breaker.queue_free()
	
	# Ending Sequence
	# Wait 3s in darkness
	await get_tree().create_timer(3.0).timeout
	
	# Turn on Emergency Light
	if emergency_light:
		emergency_light.light_energy = 20.0 # Higher intensity
		
	# Play Door Sounds Sequence
	var door_sounds = [door_sound_1, door_sound_2, door_sound_3]
	for sound in door_sounds:
		var p = AudioStreamPlayer.new()
		add_child(p)
		p.stream = sound
		p.play()
		await p.finished
		p.queue_free()
		
	# Wait 1s
	await get_tree().create_timer(1.0).timeout
	
	# Play Shed Door Sound
	var p_shed = AudioStreamPlayer.new()
	add_child(p_shed)
	p_shed.stream = shed_door_sound
	p_shed.play()
	await p_shed.finished
	p_shed.queue_free()
	
	# Red Light Flashing & Terror Sounds
	
	# Start Flashing
	var flash_tween = create_tween().set_loops()
	if emergency_light:
		flash_tween.tween_callback(func(): emergency_light.visible = not emergency_light.visible).set_delay(0.1)
		
	# Play Terror Sounds
	var p_terror = AudioStreamPlayer.new()
	add_child(p_terror)
	p_terror.stream = terror_sound
	p_terror.volume_db = -20.0
	p_terror.play()
	
	var p_breath = AudioStreamPlayer.new()
	add_child(p_breath)
	p_breath.stream = mad_breath_sound
	p_breath.volume_db = -20.0
	p_breath.play()
	
	var p_running = AudioStreamPlayer.new()
	add_child(p_running)
	p_running.stream = running_hall_sound
	p_running.volume_db = -15.0
	p_running.play()
	
	# Fade in volume
	var vol_tween = create_tween()
	vol_tween.parallel().tween_property(p_terror, "volume_db", 10.0, 10.0)
	vol_tween.parallel().tween_property(p_breath, "volume_db", 10.0, 10.0)
	vol_tween.parallel().tween_property(p_running, "volume_db", 15.0, 10.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Wait 10s
	await get_tree().create_timer(10.0).timeout
	
	# Stop all sounds immediately
	p_terror.stop()
	p_breath.stop()
	p_running.stop()
	flash_tween.kill()
	
	# Cut to Black
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)
		fade_overlay.visible = true
		
	# Show End Label
	if end_label:
		end_label.visible = true
		
	# Wait a bit then quit
	await get_tree().create_timer(5.0).timeout
	get_tree().quit()

# func turn_off_lights_recursive(node):
# 	if node is Light3D:
# 		node.light_energy = 0.0
# 		
# 	for child in node.get_children():
# 		turn_off_lights_recursive(child)
