extends Node
##
## main.gd – title + story + controls + press-to-start
## Flow:
##   0) TITLE screen     -> Press ENTER or SPACE
##   1) STORY screen     -> Press ENTER or SPACE
##   2) CONTROLS screen  -> Press ENTER or SPACE to start game
##

# Drag your main Game scene here in the Inspector
@export var game_scene: PackedScene

# UI labels under CanvasLayer
@onready var title_label: Label = $CanvasLayer/GameName
@onready var story_label: Label = $CanvasLayer/StoryLabel
@onready var press_label: Label = $CanvasLayer/PressToStart

# Waiting BGM node on the root
@onready var bgm_waiting: AudioStreamPlayer = $BGMWaiting

# 0 = title, 1 = story, 2 = controls
var _state: int = 0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# TITLE screen first
	_show_title_screen()

	# Play waiting BGM
	if bgm_waiting:
		bgm_waiting.play()


func _unhandled_input(event: InputEvent) -> void:
	# ui_accept: ENTER / Space，ui_select: 也可以设成 Space 或手柄按钮
	if not (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select")):
		return

	match _state:
		0:
			_show_story_screen()
		1:
			_show_controls_screen()
		2:
			_start_game()


# ---------------------------------------------------------
# 0) TITLE
# ---------------------------------------------------------
func _show_title_screen() -> void:
	_state = 0

	if title_label:
		title_label.text = "Time Runner"

	if story_label:
		story_label.text = ""

	if press_label:
		press_label.text = "Press ENTER or SPACE to start"
		press_label.visible = true


# ---------------------------------------------------------
# 1) STORY
# ---------------------------------------------------------
func _show_story_screen() -> void:
	_state = 1

	if title_label:
		title_label.text = "Story"

	if story_label:
		story_label.text = "You were pulled into a strange pixel world.\n" + \
			"Your life has been frozen into 60 seconds.\n\n" + \
			"Collect 5 Time Shards to unlock the EXIT door.\n" + \
			"Reach the EXIT before time runs out to return home."

	if press_label:
		press_label.text = "Press ENTER or SPACE for controls"
		press_label.visible = true


# ---------------------------------------------------------
# 2) CONTROLS + HINTS
# ---------------------------------------------------------
func _show_controls_screen() -> void:
	_state = 2

	if title_label:
		title_label.text = "How to Play"

	if story_label:
		story_label.text = \
			"Move: Arrow Keys or WASD\n" + \
			"Shoot: SPACE or Left Mouse\n\n" + \
			"Ghost slimes can move through walls but deal low damage.\n" + \
			"Armored shooters cannot pass walls but hit harder.\n\n" + \
			"Spike floors slowly drain your HP.\n" + \
			"Medkits heal to 100% but drop a heavy rock.\n" + \
			"Use the blue window to escape if the rock blocks your way.\n\n" + \
			"The top HUD shows: hearts (revives), HP%, time,\n" + \
			"shards collected, and enemies killed."

	if press_label:
		press_label.text = "Press ENTER or SPACE to begin"
		press_label.visible = true


# ---------------------------------------------------------
# 3) START GAME
# ---------------------------------------------------------
func _start_game() -> void:
	if bgm_waiting:
		bgm_waiting.stop()

	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		push_error("main.gd: game_scene is not assigned.")
