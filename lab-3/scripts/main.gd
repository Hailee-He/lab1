# ==========================================================
# main.gd — Core game system manager
# Handles: player health, gems, checkpoints, respawn, and audio feedback.
# ==========================================================

extends Node2D

# --- Audio Players (set in scene tree) ---
@onready var bgm            : AudioStreamPlayer = $Music/BGM
@onready var sfx_gameover   : AudioStreamPlayer = $Music/GameOver
@onready var sfx_hit        : AudioStreamPlayer = $SFX/Hit
@onready var sfx_jump       : AudioStreamPlayer = $SFX/Jump
@onready var sfx_success    : AudioStreamPlayer = $SFX/Success
@onready var sfx_run        : AudioStreamPlayer = $SFX/RunLoop
@onready var sfx_levelup    : AudioStreamPlayer = $SFX/LevelUp
@onready var sfx_heal       : AudioStreamPlayer = $SFX/Heal

# --- NEW: Fade overlay for smooth respawn ---
@onready var fade_rect : ColorRect = $Fade    # adjust the path if placed under a CanvasLayer

# --- UI Elements ---
@onready var level_up_label : Label = $LevelUpLabel   # Label for “LEVEL UP!” text

# --- Level Data ---
@export var required_gems: int = 5
var gems_collected: int = 0
var level_complete: bool = false  # prevents multiple levelup triggers

# --- Checkpoint / Respawn Data ---
var checkpoint_pos: Vector2 = Vector2.ZERO
var checkpoint_hp_pips: int = -1

# --- Cached References ---
var player: CharacterBody2D
var hud: Node
var _prev_hearts := -1


# ==========================================================
# READY
# ==========================================================
func _ready() -> void:
	add_to_group("level")   # allow other scripts (gems/checkpoints) to find this node

	# Locate player and HUD dynamically
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	hud = get_tree().get_first_node_in_group("hud")

	if player == null:
		push_error("Player not found. Ensure Player calls add_to_group('player') in _ready().")
	else:
		# Set initial checkpoint and connect signals
		checkpoint_pos = player.global_position
		player.connect("health_changed", Callable(self, "_on_player_health_changed"))
		player.connect("died", Callable(self, "_on_player_died"))

	# Initialize HUD gem display
	if hud and hud.has_method("set_gems"):
		hud.set_gems(gems_collected, required_gems)

	# Ensure background music is playing
	if bgm and not bgm.playing:
		bgm.play()


# ==========================================================
# CHECKPOINT & RESPAWN
# ==========================================================
func set_checkpoint(pos: Vector2) -> void:
	# Called by a checkpoint when activated
	checkpoint_pos = pos
	if player:
		checkpoint_hp_pips = player.hp_pips  # save current health (optional)

func _on_player_died() -> void:
	music_gameover()

	# Wait for death delay then respawn
	await get_tree().create_timer(2.0).timeout

	if player:
		if player.has_method("respawn"):
			player.respawn(checkpoint_pos)

		# Restore health at checkpoint (if you want full heal, remove this block)
		if checkpoint_hp_pips >= 0:
			player.hp_pips = clamp(checkpoint_hp_pips, 0, player.hp_pips_max)
			if hud and hud.has_method("set_health"):
				hud.set_health(player.hp_pips, player.max_hearts)

	music_resume()
	_fade_in_out()   # NEW: smooth black fade after respawn


# ==========================================================
# HEALTH / HUD FEEDBACK
# ==========================================================
func _on_player_health_changed(curr: int, maxv: int) -> void:
	# Trigger flash when health decreases
	if _prev_hearts != -1 and curr < _prev_hearts:
		var flash := hud.get_node_or_null("ColorRect")
		if flash:
			flash.flash()
	_prev_hearts = curr

	# Update HUD health (convert to pips if necessary)
	if hud and hud.has_method("set_health"):
		var pips := curr * 2  # 1 heart = 2 pips
		hud.set_health(pips, maxv)


# ==========================================================
# GEM COLLECTION
# ==========================================================
func add_gem() -> void:
	# Called by gem.gd when collected
	gems_collected += 1

	# Update HUD gem counter
	if hud and hud.has_method("set_gems"):
		hud.set_gems(gems_collected, required_gems)

	# Play single gem pickup sound
	sfx_play_success()

	# (Optional) You can show a hint if all gems are collected
	# if gems_collected >= required_gems:
	#     print("All gems collected! Reach the checkpoint!")


# ==========================================================
# CHECKPOINT REACHED (Level Complete condition)
# ==========================================================
func on_checkpoint_reached() -> void:
	# Only trigger once when all gems are collected
	if gems_collected >= required_gems and not level_complete:
		level_complete = true
		sfx_play_levelup()
		_show_levelup_text()   # simple “LEVEL UP!” display


# ==========================================================
# SIMPLE LEVEL UP TEXT DISPLAY
# ==========================================================
func _show_levelup_text() -> void:
	if not level_up_label:
		return
	level_up_label.visible = true
	level_up_label.text = "LEVEL UP!"
	await get_tree().create_timer(2.0).timeout
	level_up_label.visible = false


# ==========================================================
# AUDIO HELPERS (SFX)
# ==========================================================
func sfx_play_jump() -> void:
	if sfx_jump:
		sfx_jump.play()

func sfx_play_hit() -> void:
	if sfx_hit:
		sfx_hit.play()

func sfx_play_success() -> void:
	if sfx_success:
		sfx_success.play()

func sfx_run_set(active: bool) -> void:
	if not sfx_run:
		return
	if active:
		if not sfx_run.playing:
			sfx_run.play()
	else:
		if sfx_run.playing:
			sfx_run.stop()

func sfx_play_levelup() -> void:
	if sfx_levelup:
		sfx_levelup.play()


# ==========================================================
# AUDIO HELPERS (MUSIC)
# ==========================================================
func music_gameover() -> void:
	if bgm:
		bgm.stop()
	if sfx_gameover:
		sfx_gameover.play()

func music_resume() -> void:
	if sfx_gameover and sfx_gameover.playing:
		await sfx_gameover.finished
	if bgm and not bgm.playing:
		bgm.play()

func sfx_play_heal() -> void:
	if sfx_heal:
		sfx_heal.play()

func _fade_in_out() -> void:
	if not fade_rect: 
		return
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, 0.35)
	t.tween_interval(0.3)
	t.tween_property(fade_rect, "modulate:a", 0.0, 0.35)
	t.tween_callback(Callable(self, "_hide_fade"))

func _hide_fade() -> void:
	if fade_rect:
		fade_rect.visible = false
		
