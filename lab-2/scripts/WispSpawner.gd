extends Node2D

@export var wisp_scene: PackedScene
@export var initial_wisp_count: int = 20
@export var max_wisp_count: int = 60
@export var spawn_interval: float = 2.0
@export var spawn_margin: float = 50.0

var current_wisp_count: int = 0
var spawn_timer: Timer
var screen_rect: Rect2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_rect = Rect2(-1000, -500, 2000, 1000)
	
	await get_tree().process_frame
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	for i in range(initial_wisp_count):
		spawn_wisp()
		current_wisp_count += 1
	
	spawn_timer.start()

func _on_spawn_timer_timeout():
	if current_wisp_count < max_wisp_count:
		spawn_wisp()
		current_wisp_count += 1
		
func spawn_wisp():
	if not wisp_scene:
		push_error("Wisp scene is not assigned to WispSpawner!")
		return
	
	var wisp = wisp_scene.instantiate()
	
	var edge = randi() % 4
	var spawn_position = Vector2.ZERO
	
	match edge:
		0: # 上边
			spawn_position.x = randf_range(screen_rect.position.x + spawn_margin, 
										 screen_rect.position.x + screen_rect.size.x - spawn_margin)
			spawn_position.y = screen_rect.position.y - spawn_margin
		1: # 右边
			spawn_position.x = screen_rect.position.x + screen_rect.size.x + spawn_margin
			spawn_position.y = randf_range(screen_rect.position.y + spawn_margin, 
										 screen_rect.position.y + screen_rect.size.y - spawn_margin)
		2: # 下边
			spawn_position.x = randf_range(screen_rect.position.x + spawn_margin, 
										 screen_rect.position.x + screen_rect.size.x - spawn_margin)
			spawn_position.y = screen_rect.position.y + screen_rect.size.y + spawn_margin
		3: # 左边
			spawn_position.x = screen_rect.position.x - spawn_margin
			spawn_position.y = randf_range(screen_rect.position.y + spawn_margin, 
										 screen_rect.position.y + screen_rect.size.y - spawn_margin)
	
	wisp.global_position = spawn_position
	
	# 设置初始速度朝向屏幕中心
	var center = screen_rect.position + screen_rect.size / 2
	var direction = (center - spawn_position).normalized()
	wisp.velocity = direction * wisp.speed
	
	get_parent().add_child(wisp)
