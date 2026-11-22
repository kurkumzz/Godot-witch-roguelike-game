extends Control

const COVER := preload("res://graphics/ui/grimoire_sketch.png")
@export var folio_texture: Texture2D
var turn := 0.0


func _draw() -> void:
	draw_texture_rect(folio_texture if turn > 0.45 else COVER, Rect2(Vector2.ZERO, size), false)
	if turn <= 0.2 or turn >= 0.8:
		return
	# Сужаем и зеркалим правый лист вокруг корешка во время перелистывания.
	var phase := (turn - 0.2) / 0.6
	var width := roundf((size.x * 0.5 - 12) * cos(PI * phase))
	if absf(width) < 1:
		return
	var lift := roundf(6 * sin(PI * phase))
	draw_set_transform(Vector2(roundf(size.x * 0.5), -lift), 0, Vector2(signf(width), 1))
	draw_texture_rect_region(COVER, Rect2(0, 0, absf(width), size.y * 0.82 + lift), Rect2(72, 1, 65, 46))
