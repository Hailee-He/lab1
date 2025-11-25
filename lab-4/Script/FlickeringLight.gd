extends Node3D

enum FlickerLevel {
	LOW = 0,    # 30% probability
	MEDIUM = 1, # 50% probability
	HIGH = 2    # 80% probability
}

@export var flicker_level: FlickerLevel = FlickerLevel.MEDIUM
@export var check_interval: float = 2.0

@onready var spot_light = $SpotLight3D

var timer: float = 0.0
var is_flickering: bool = false
var flicker_step: int = 0
var flicker_timer: float = 0.0

const FLICKER_DURATION = 0.1  # Duration of each on/off cycle

func _ready():
	if not spot_light:
		push_error("SpotLight3D not found as child of FlickeringLight")
		return
	
	# Randomize initial timer to avoid all lights syncing
	timer = randf() * check_interval

func _process(delta):
	if not spot_light:
		return
	
	if is_flickering:
		_process_flicker(delta)
	else:
		_process_timer(delta)

func _process_timer(delta):
	timer += delta
	
	if timer >= check_interval:
		timer = 0.0
		_check_flicker()

func _check_flicker():
	var probability = _get_probability()
	var random_value = randf()
	
	if random_value < probability:
		_start_flicker()

func _get_probability() -> float:
	match flicker_level:
		FlickerLevel.LOW:
			return 0.3
		FlickerLevel.MEDIUM:
			return 0.5
		FlickerLevel.HIGH:
			return 0.8
		_:
			return 0.5

func _start_flicker():
	is_flickering = true
	flicker_step = 0
	flicker_timer = 0.0
	spot_light.visible = false

func _process_flicker(delta):
	flicker_timer += delta
	
	if flicker_timer >= FLICKER_DURATION:
		flicker_timer = 0.0
		flicker_step += 1
		
		# Toggle light state
		if flicker_step % 2 == 0:
			spot_light.visible = false
		else:
			spot_light.visible = true
		
		# Complete after 2 full cycles (4 steps: off, on, off, on)
		if flicker_step >= 4:
			is_flickering = false
			spot_light.visible = true
