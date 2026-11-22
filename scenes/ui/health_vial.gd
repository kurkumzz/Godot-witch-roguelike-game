@tool
extends Control

@export var liquid_texture: Texture2D

var fraction: float = 1.0:
	set(value):
		fraction = clampf(value, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	if liquid_texture == null:
		return
	var height := roundi(liquid_texture.get_height() * fraction)
	if height > 0:
		var slice := Rect2(0, liquid_texture.get_height() - height, liquid_texture.get_width(), height)
		draw_texture_rect_region(liquid_texture, slice, slice)
