extends "res://scenes/effects/reactions/reaction_flash.gd"
## Сверхпроводимость. Встречные лиловые дуги сходятся к излому в центре.


func _draw() -> void:
	var gap := lerpf(24.0, 4.0, ease(progress, 0.55))
	for side: float in [-1.0, 1.0]:
		var tip := Vector2(side * gap, 0).round()
		var path := PackedVector2Array([tip + Vector2(side * 12, -5), tip + Vector2(side * 5, -5),
				tip + Vector2(side * 8, 2), tip])
		draw_polyline(path, Color("#8767ca"), 3.0)
		draw_polyline(path, Color("#efd9ff"), 1.0)
	draw_crystal(self, Vector2(-2, 10), Vector2(4, -22), 4.0,
			Color("#a185df"), Color("#e3faff"))
