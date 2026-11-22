extends Node2D
## Всплеск рисуется одним узлом. Частицы льда здесь только рисунок.

const HIT_TIME := 0.24
const FADE_TIME := 0.16
const RAYS := 6

var element: Element.Type
var on_contact := true
var progress := 0.0


func _ready() -> void:
	z_index = 4
	var tween := create_tween()
	tween.tween_method(_advance, 0.0, 1.0, HIT_TIME if on_contact else FADE_TIME)
	tween.tween_callback(queue_free)


func _advance(value: float) -> void:
	progress = value
	modulate.a = 1.0 - progress * progress
	queue_redraw()


func _draw() -> void:
	var tint: Color = Element.COLORS[element]
	var highlight := tint.lerp(Color.WHITE, 0.78)
	var reach := (17.0 if on_contact else 8.0) * ease(progress, 0.5)
	var fall := Vector2.DOWN.rotated(-global_rotation) * progress * progress
	if on_contact and progress < 0.28:
		draw_rect(Rect2(-2, -2, 4, 4), highlight)
	for i in RAYS:
		var ray := Vector2.RIGHT.rotated((i + 0.35) * TAU / RAYS)
		var tip := ray * (2.0 + reach * (1.0 if i % 2 == 0 else 0.72))
		var side := ray.orthogonal()
		match element:
			Element.Type.FIRE:
				tip -= fall * 5.0
				draw_line((tip - ray * 4.0).round(), tip.round(), tint, 3)
				draw_rect(Rect2(tip.round(), Vector2(2, 2)), highlight)
			Element.Type.ICE:
				tip += fall * 6.0
				var base := tip - ray * 5.0
				draw_colored_polygon(PackedVector2Array([
					tip, base + side * 1.8, base - side * 1.8
				]), tint)
				draw_line(base.round(), tip.round(), highlight, 1)
			Element.Type.ELECTRIC:
				var joint := tip * 0.63 + side * 3.0
				var points := PackedVector2Array([
					(ray * reach * 0.27).round(), joint.round(), tip.round()
				])
				draw_polyline(points, tint, 2)
				draw_line(joint.round(), tip.round(), highlight, 1)
			_:
				tip += fall * 8.0
				draw_circle(tip.round(), 2.0 if i % 2 == 0 else 1.4, tint)
				draw_rect(Rect2(tip.round() - Vector2.ONE, Vector2.ONE), highlight)
