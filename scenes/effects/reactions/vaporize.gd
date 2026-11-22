extends "res://scenes/effects/reactions/reaction_flash.gd"
## Испарение. Три клубка тёплого пара расходятся вверх и меняют размер.


func _init() -> void:
	duration = 0.48


func _draw() -> void:
	for i in 3:
		var side := float(i - 1)
		var center := Vector2(side * (4.0 + 12.0 * progress),
				-2.0 - (21.0 - 5.0 * absf(side)) * progress).round()
		var radius := roundf(4.0 + 5.0 * sin(progress * PI))
		draw_circle(center, radius, Color("#9c948d"))
		draw_circle(center + Vector2(0, -2), radius - 1.0, Color("#eddbc9"))
		draw_rect(Rect2(center + Vector2(-2, -radius), Vector2(4, 2)), Color("#fff3dc"))
