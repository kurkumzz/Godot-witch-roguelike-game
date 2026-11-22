extends "res://scenes/effects/reactions/reaction_flash.gd"
## Раскол. Все летящие осколки рисует один узел, коллизии им не нужны.


func _draw() -> void:
	var travel := ease(progress, 0.6)
	for i in 8:
		var ray := Vector2.RIGHT.rotated((i + 0.35) * TAU / 8.0)
		var center := ray * (5.0 + travel * (18.0 + 4.0 * (i % 3)))
		center.y += 14.0 * progress * progress
		var axis := ray.rotated(progress * (1.0 if i % 2 == 0 else -1.0))
		draw_crystal(self, center, axis * (9.0 - 3.0 * progress), 2.5,
				Color("#85ddfc"), Color("#f1ffff"))
