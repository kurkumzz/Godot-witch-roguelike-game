extends Node2D
## Общие часы для коротких вспышек. progress меняется от 0 до 1.

@export_range(0.05, 1.0, 0.01) var duration: float = 0.36
var progress: float = 0.0


func _ready() -> void:
	z_index = 4


func _process(delta: float) -> void:
	progress += delta / duration
	if progress >= 1.0:
		queue_free()
		return
	# В конце гаснет вся вспышка, включая светлые грани и контуры.
	self_modulate.a = 1.0 - smoothstep(0.55, 1.0, progress)
	queue_redraw()


## Ромб с подсвеченной гранью, вытянутый вдоль оси кристалла.
static func draw_crystal(canvas: CanvasItem, base: Vector2, axis: Vector2, half_width: float,
		body: Color, facet: Color) -> void:
	var side := axis.normalized().orthogonal() * half_width
	var middle := base + axis * 0.46
	var tip := (base + axis).round()
	var left := (middle - side).round()
	var right := (middle + side).round()
	if left == right or base.round() == tip:
		return
	canvas.draw_colored_polygon(PackedVector2Array([base.round(), left, tip, right]), body)
	canvas.draw_line(left, tip, facet, 1.0)
