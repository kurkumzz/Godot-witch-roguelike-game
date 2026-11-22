extends "res://scenes/effects/reactions/reaction_flash.gd"
## Заряд. Сквозь два водяных кольца проходит жёлтый разряд.


func _draw() -> void:
	var radius := lerpf(8.0, 22.0, ease(progress, 0.5))
	for i in 2:
		var ring := PackedVector2Array()
		for step in 13:
			var angle := TAU * step / 12.0
			ring.append(Vector2(radius * cos(angle), radius * 0.33 * sin(angle) + i * 8 - 4).round())
		draw_polyline(ring, Color("#6dcfff"), 1.0)
	var bolt := PackedVector2Array([Vector2(6, -21), Vector2(-4, -2),
			Vector2(4, -3), Vector2(-6, 17)])
	draw_polyline(bolt, Color("#eeb444"), 4.0)
	draw_polyline(bolt, Color("#fffbd0"), 1.5)
