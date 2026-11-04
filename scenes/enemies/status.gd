class_name statusComp
extends Node
## Хранит статусы врага и реагирует на попадания стихий.
## Добавляется дочерним узлом к врагу. Имя узла: StatusComponent.

signal status_added(status: Status)
signal status_removed(status: Status)

enum Status { WET }

const WET_DURATION := 5.0
const WET_TINT := Color(0.6, 0.8, 1.0)

# --- Отладочная надпись ---
@export var show_debug_label := true                    # выключи, когда отладка не нужна
@export var label_offset := Vector2(-30, -48)           # положение относительно врага

# Активные статусы: Status -> сколько секунд осталось
var active := {}
var debug_label: Label

@onready var sprite: CanvasItem = get_parent().get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	if show_debug_label:
		create_debug_label()


func _process(delta: float) -> void:
	for status in active.keys():
		active[status] -= delta
		if active[status] <= 0.0:
			remove_status(status)
	update_debug_label()


# --- Главная точка входа ---

## Вызывается снарядом перед нанесением урона.
## Возвращает итоговый урон (реакции могут его менять).
func process_hit(element: Element.Type, base_damage: int) -> int:
	var damage := base_damage

	match element:
		Element.Type.WATER:
			add_status(Status.WET)

		# Будущие реакции добавляются сюда.

	return damage


# --- Работа со статусами ---

func add_status(status: Status) -> void:
	var is_new := not active.has(status)
	active[status] = get_duration(status)
	if is_new:
		status_added.emit(status)
	update_visuals()


func remove_status(status: Status) -> void:
	if active.erase(status):
		status_removed.emit(status)
		update_visuals()


func has_status(status: Status) -> bool:
	return active.has(status)


func get_duration(status: Status) -> float:
	match status:
		Status.WET:
			return WET_DURATION
	return 0.0


func update_visuals() -> void:
	if sprite == null:
		return
	sprite.modulate = WET_TINT if has_status(Status.WET) else Color.WHITE


# --- Отладочная надпись ---

func create_debug_label() -> void:
	debug_label = Label.new()
	debug_label.position = label_offset
	debug_label.custom_minimum_size = Vector2(60, 0)
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_label.add_theme_font_size_override("font_size", 8)
	debug_label.add_theme_color_override("font_outline_color", Color.BLACK)
	debug_label.add_theme_constant_override("outline_size", 3)
	debug_label.visible = false
	# Метка должна быть ребёнком врага, чтобы ездить за ним.
	# call_deferred, потому что родитель ещё достраивает свои дочерние узлы.
	get_parent().add_child.call_deferred(debug_label)


func update_debug_label() -> void:
	if debug_label == null:
		return
	if active.is_empty():
		debug_label.visible = false
		return

	var lines: Array[String] = []
	for status in active:
		lines.append("%s %.1f" % [Status.keys()[status], active[status]])
	debug_label.text = "\n".join(lines)
	debug_label.visible = true
