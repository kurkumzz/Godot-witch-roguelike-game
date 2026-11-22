extends Node
## Короткий удар по темпу и активной камере. Меню книги управляет своей паузой отдельно.

@export_range(0.0, 0.1, 0.001, "suffix:s") var hit_stop_seconds := 0.042
@export_range(0.0, 5.0, 0.5, "suffix:px") var shake_pixels := 2.0

var stop_active := false
var previous_speed := 1.0
var stopped_speed := 1.0
var shake: Tween
var camera: Camera2D
var resting_offset: Vector2


func watch_shot(shot: projectile) -> void:
	shot.enemy_hit.connect(on_hit)


func on_hit(world_position: Vector2) -> void:
	if get_tree().paused:
		return
	if not stop_active and hit_stop_seconds > 0.0:
		stop_active = true
		previous_speed = Engine.time_scale
		stopped_speed = previous_speed * 0.06
		Engine.time_scale = stopped_speed
		# Таймер идёт по реальному времени, даже если удар открыл страницу книги.
		get_tree().create_timer(hit_stop_seconds, true, false, true).timeout.connect(_restore_speed)

	if shake_pixels <= 0.0:
		return
	_finish_shake()
	camera = get_viewport().get_camera_2d()
	if not camera:
		return
	resting_offset = camera.offset
	var witch := get_parent() as Node2D
	var side := 1.0 if world_position.x >= witch.global_position.x else -1.0
	var kick := Vector2(side * shake_pixels, -shake_pixels * 0.5).round()
	camera.offset += kick
	shake = create_tween().set_ignore_time_scale(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	shake.tween_interval(0.026)
	shake.tween_property(camera, "offset", resting_offset - kick * 0.5, 0.035)
	shake.tween_property(camera, "offset", resting_offset, 0.055)


func _restore_speed() -> void:
	if stop_active and is_equal_approx(Engine.time_scale, stopped_speed):
		Engine.time_scale = previous_speed
	stop_active = false


func _finish_shake() -> void:
	if shake and shake.is_running():
		shake.kill()
		if is_instance_valid(camera):
			camera.offset = resting_offset


func _exit_tree() -> void:
	_restore_speed()
	_finish_shake()
