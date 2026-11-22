extends Node2D

const Witch := preload("res://scenes/player.gd")

# Координаты светлой точки внутри кадров ggSprite (от левого верхнего угла, до отражения).
const TIPS := {
	&"idle": [Vector2(52, 29), Vector2(52, 29), Vector2(52, 31), Vector2(52, 31),
		Vector2(52, 32), Vector2(52, 32), Vector2(52, 30), Vector2(52, 29), Vector2(52, 29)],
	&"left": [Vector2(57, 35), Vector2(57, 36), Vector2(57, 37), Vector2(57, 38),
		Vector2(57, 38), Vector2(57, 37), Vector2(57, 37), Vector2(57, 35), Vector2(57, 35)],
	&"attack": [Vector2(49, 26), Vector2(47, 23), Vector2(55, 32), Vector2(53, 30), Vector2(52, 28)],
	&"jump": [Vector2(53, 33), Vector2(50, 31), Vector2(50, 33), Vector2(52, 28), Vector2(53, 33)],
	&"dash": [Vector2(56, 36), Vector2(58, 35), Vector2(58, 35), Vector2(58, 35), Vector2(58, 35), Vector2(57, 35)],
}

@onready var sprite := get_parent() as AnimatedSprite2D
@onready var witch := sprite.get_parent() as Witch
@onready var halo: Sprite2D = $Halo
@onready var light: PointLight2D = $Light


func _ready() -> void:
	RunState.changed.connect(_sync_element)
	witch.equipment_changed.connect(_sync_element)
	_sync_element()


func _sync_element() -> void:
	visible = witch.has_book_and_wand and witch.current_element != Element.Type.NONE
	set_process(visible)
	if visible:
		var tint: Color = Element.COLORS[witch.current_element]
		halo.self_modulate = Color(tint, 0.62)
		light.color = tint
		self_modulate = tint.lightened(0.36)
		_align_tip()


func _process(_delta: float) -> void:
	_align_tip()


func _align_tip() -> void:
	var frames: Array = TIPS.get(sprite.animation, [])
	var tip := Vector2(52, 30)
	if sprite.frame < frames.size():
		tip = frames[sprite.frame]
	position = tip - Vector2(31.5, 31.5)
	if sprite.flip_h:
		position.x = -position.x


func _draw() -> void:
	draw_rect(Rect2(-1, -2, 2, 4), Color.WHITE)
	draw_rect(Rect2(-2, -1, 4, 2), Color.WHITE)
