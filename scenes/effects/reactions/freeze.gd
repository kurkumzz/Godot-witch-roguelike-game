extends "res://scenes/effects/reactions/reaction_flash.gd"
## Заморозка. Грани прорастают снизу вверх навстречу ледяной корке статуса.


func _draw() -> void:
	var growth := lerpf(0.2, 1.0, ease(progress, 0.35))
	for i in 5:
		var side := float(i - 2)
		var base := Vector2(side * 5.0, 11.0)
		var axis := Vector2(side * 3.0, -28.0 + absf(side) * 5.0) * growth
		draw_crystal(self, base, axis, 3.8 * growth, Color("#55b9de"), Color("#eaffff"))
