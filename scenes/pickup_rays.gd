extends Node2D

const RAY_COUNT := 5
const RAY_COLOR := Color(1.0, 0.83, 0.49, 0.85)


func _draw() -> void:
	for index in range(RAY_COUNT):
		var direction := Vector2.UP.rotated(TAU * index / RAY_COUNT)
		draw_line(direction * 10.0, direction * 50.0, RAY_COLOR, 6.0, true)
