extends ShaderMaterial
## Каждый персонаж держит свой экземпляр: вспышка и оттенок статуса локальны.

var _flash: Tween


func _init() -> void:
	shader = preload("res://scenes/shaders/hit.gdshader")


func flash(sprite: CanvasItem, duration: float) -> void:
	if _flash:
		_flash.kill()
	set_shader_parameter("flash_amount", 1.0)
	_flash = sprite.create_tween()
	_flash.tween_property(self, "shader_parameter/flash_amount", 0.0, duration)
