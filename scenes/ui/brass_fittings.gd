@tool
extends PanelContainer
## Накладки рисуются поверх рамки в тех же пикселях, что и страницы книги.

func _draw() -> void:
	var bounds := Vector2i(size)
	for x: int in [1, bounds.x - 6]:
		for y: int in [1, bounds.y - 4]:
			draw_rect(Rect2i(x, y, 5, 3), Color("#956a42"))
			draw_rect(Rect2i(x, y, 5, 1), Color("#e4bd79"))
			draw_rect(Rect2i(x + 2, y + 1, 1, 1), Color("#574539"))
