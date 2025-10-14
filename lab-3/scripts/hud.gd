extends CanvasLayer

# Heart strip is ordered from EMPTY → ... → FULL (left-to-right).
@export var heart_strip: Texture2D
@export var frames: int = 5  # total frames in the strip

# Three TextureRects inside an HBoxContainer, named Heart1/Heart2/Heart3.
@onready var heart_nodes: Array[TextureRect] = [
	$HBoxContainer/Heart1 as TextureRect,
	$HBoxContainer/Heart2 as TextureRect,
	$HBoxContainer/Heart3 as TextureRect
]

@onready var gem_label: Label = get_node_or_null("GemLabel")


func _ready() -> void:
	add_to_group("hud") # allow main.gd to find HUD by group
	# Example: 3 hearts = 6 half-pips
	set_health(6, 3)

# Show health using half-heart pips.
# hp_pips ∈ [0, max_hearts*2]  (2 pips per heart: 2=full, 1=half, 0=empty)
func set_health(hp_pips: int, max_hearts: int = 3) -> void:
	if heart_strip == null or frames <= 0:
		return

	# 1) Only the first `max_hearts` TextureRects are visible; hide the rest
	for i in range(heart_nodes.size()):
		heart_nodes[i].visible = (i < max_hearts)

	# 2) Clamp pips to the range implied by max_hearts
	var clamped_pips: int = clamp(hp_pips, 0, max_hearts * 2)

	# 3) Choose indices in the atlas: empty / half / full
	var idx_empty: int = 0
	var idx_full:  int = max(frames - 1, 0)
	var idx_half:  int = int(frames / 2)


	# 4) Paint exactly `max_hearts` hearts according to pips
	for i in range(max_hearts):
		var remaining: int = clamp(clamped_pips - 2 * i, 0, 2)
		var frame_idx: int = idx_empty
		if remaining >= 2:
			frame_idx = idx_full
		elif remaining == 1:
			frame_idx = idx_half
		heart_nodes[i].texture = _atlas_frame(heart_strip, frames, frame_idx)

func set_gems(collected: int, required: int) -> void:
	if gem_label:
		gem_label.text = "Gems: %d / %d" % [collected, required]

# Crop a specific frame from a horizontal strip texture.
func _atlas_frame(tex: Texture2D, total_frames: int, index: int) -> AtlasTexture:
	index = clamp(index, 0, total_frames - 1)

	var size: Vector2 = tex.get_size()
	var frame_w: int = int(size.x / max(1, total_frames))
	var frame_h: int = int(size.y)

	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(index * frame_w, 0, frame_w, frame_h)
	return atlas
