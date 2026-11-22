extends "res://scenes/effects/reactions/reaction_flash.gd"
## Перегрузка. Горячее ядро сжимается, угловатый фронт взрыва расходится.


func _draw() -> void:
	var travel := ease(progress, 0.45)
	var radius := lerpf(8.0, 36.0, travel)
	var core := lerpf(14.0, 2.0, travel)
	for i in 8:
		var ray := Vector2.RIGHT.rotated(i * TAU / 8.0)
		var next := ray.rotated(TAU / 8.0)
		draw_line((ray * radius).round(), (ray.lerp(next, 0.66) * radius).round(),
				Color("#ff7953"), 2.0)
		draw_crystal(self, ray * (core - 3.0), ray * (8.0 + 5.0 * (i % 2)),
				3.6 * (1.0 - progress), Color("#ff944a"), Color("#fff3a1"))
	draw_circle(Vector2.ZERO, core, Color("#ff693d"))
	draw_circle(Vector2.ZERO, core * 0.66, Color("#fff6ad"))
