extends Node2D

const GroundDust := preload("res://scenes/effects/player/ground_dust.tscn")
const DashEcho := preload("res://scenes/effects/player/dash_echo.tscn")

@export_range(8.0, 35.0) var echo_spacing := 16.0
@export var foot_height := 24.0
@onready var sprite: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var rest_scale := sprite.scale
@onready var rest_position := sprite.position
var squash: Tween
var last_echo_position := Vector2.INF


func _ready() -> void:
	set_physics_process(false)


func on_jump(from_floor: bool) -> void:
	_stretch(Vector2(0.90, 1.09))
	if from_floor:
		_dust(5)


func on_land(fall_speed: float) -> void:
	if fall_speed < 80.0:
		return
	var weight := clampf(fall_speed / 500.0, 0.3, 1.0)
	_stretch(Vector2(1.0 + 0.14 * weight, 1.0 - 0.15 * weight))
	_dust(roundi(4.0 + 4.0 * weight))


func _dust(count: int) -> void:
	var puff := GroundDust.instantiate() as CPUParticles2D
	puff.amount = count
	add_child(puff)
	puff.global_position = global_position + Vector2.DOWN * foot_height
	puff.reset_physics_interpolation()
	puff.restart()


func _stretch(factor: Vector2) -> void:
	if squash:
		squash.kill()
	# Оставляем ступни у земли, пока меняется только рисунок персонажа.
	sprite.scale = rest_scale * factor
	sprite.position = rest_position + Vector2.DOWN * foot_height * (1.0 - factor.y)
	squash = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	squash.tween_property(sprite, "scale", rest_scale, 0.14)
	squash.tween_property(sprite, "position", rest_position, 0.14)


func on_dash() -> void:
	last_echo_position = Vector2.INF
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if sprite.animation != &"dash":
		set_physics_process(false)
		return
	if sprite.visible and global_position.distance_to(last_echo_position) >= echo_spacing:
		var echo := DashEcho.instantiate()
		add_child(echo)
		echo.capture(sprite)
		last_echo_position = global_position
