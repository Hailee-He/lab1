extends ColorRect

@export var flash_time := 0.35      
@export var flash_alpha := 0.45     

func flash() -> void:
	visible = true
	modulate.a = flash_alpha
	var tween := create_tween()
	tween.tween_interval(0.05)     
	tween.tween_property(self, "modulate:a", 0.0, flash_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
