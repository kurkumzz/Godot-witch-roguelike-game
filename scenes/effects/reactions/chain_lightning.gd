extends "res://scenes/effects/reactions/reaction_flash.gd"
## Одна молния между точками сигнала. Ломаная сохраняет форму, пока гаснет.

var points := PackedVector2Array()


func set_endpoints(start: Vector2, finish: Vector2) -> void:
	global_position = start
	duration = 0.19
	var offset := to_local(finish)
	var normal := offset.normalized().orthogonal()
	var segments := clampi(ceili(offset.length() / 11.0), 2, 18)
	points = PackedVector2Array([Vector2.ZERO])
	for i in range(1, segments):
		var fraction := float(i) / segments
		var jitter := sin(i * 2.4) * minf(6.0, offset.length() * 0.12)
		points.append((offset * fraction + normal * jitter).round())
	points.append(offset)
	queue_redraw()


func _draw() -> void:
	if points.size() < 2 or points[0].is_equal_approx(points[-1]):
		return
	draw_polyline(points, Color("#ad8cdb"), 3.0)
	draw_polyline(points, Color("#fffac6"), 1.0)
