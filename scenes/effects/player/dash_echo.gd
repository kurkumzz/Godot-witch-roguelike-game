extends Sprite2D
## Снимок кадра остаётся в мире и гаснет за ведьмой.

@export_range(0.05, 0.35) var fade_seconds := 0.15


func capture(source: AnimatedSprite2D) -> void:
	texture = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	flip_h = source.flip_h
	offset = source.offset
	global_transform = source.global_transform
	reset_physics_interpolation()
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, fade_seconds)
	fade.tween_callback(queue_free)
