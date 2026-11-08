class_name statusComp
extends Node
## Хранит статусы врага и реагирует на попадания стихий.
## Добавляется дочерним узлом к врагу. Имя узла: statusComp.

signal status_added(status: Status)
signal status_removed(status: Status)
signal reaction_triggered(reaction_name: String)

enum Status { WET, BURNING, CHILL, FROZEN }

# --- Мокрый ---
const WET_DURATION := 5.0
const WET_TINT := Color(0.6, 0.8, 1.0)

# --- Горение ---
const BURN_DURATION := 3.0
const BURN_TICK_INTERVAL := 1.0   # раз в сколько секунд наносится урон
const BURN_TICK_DAMAGE := 1
const BURN_TINT := Color(1.0, 0.6, 0.5)

# --- Мерзлота ---
const CHILL_DURATION := 4.0
const CHILL_SPEED_MULTIPLIER := 0.5   # 0.5 = враг и его анимации вдвое медленнее
const CHILL_TINT := Color(0.8, 1.0, 1.0)

# --- Заморозка ---
const FROZEN_DURATION := 2.0
const FROZEN_TINT := Color(0.5, 0.95, 1.0)

# --- Реакции ---
const VAPORIZE_MULTIPLIER := 1.5
# Что снимает испарение
const VAPORIZE_CLEARS := [Status.WET, Status.BURNING, Status.CHILL, Status.FROZEN]

# --- Отладочная надпись ---
@export var show_debug_label := true
@export var show_hp := true
@export var label_offset := Vector2(-30, -58)

# Активные статусы: Status -> сколько секунд осталось
var active := {}
var burn_tick_left := 0.0
var debug_label: Label
var reaction_text := ""
var reaction_time_left := 0.0

# Исходные значения врага, к ним возвращаемся после снятия замедления
var base_speed := 0.0
var base_anim_speed := 1.0

@onready var enemy := get_parent() as BaseEnemy
@onready var sprite: CanvasItem = get_parent().get_node_or_null("AnimatedSprite2D")
@onready var anim_sprite := get_parent().get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func _ready() -> void:
	if enemy:
		base_speed = enemy.speedMovement
	if anim_sprite:
		base_anim_speed = anim_sprite.speed_scale
	if show_debug_label:
		create_debug_label()


func _process(delta: float) -> void:
	tick_burning(delta)

	for status in active.keys():
		active[status] -= delta
		if active[status] <= 0.0:
			remove_status(status)

	reaction_time_left = maxf(reaction_time_left - delta, 0.0)
	update_debug_label()


# --- Главная точка входа ---

## Вызывается снарядом перед нанесением урона.
## Возвращает итоговый урон (реакции могут его менять).
func process_hit(element: Element.Type, base_damage: int) -> int:
	var damage := base_damage

	match element:
		Element.Type.WATER:
			if has_status(Status.BURNING):
				damage = vaporize(base_damage)
			elif has_status(Status.CHILL):
				freeze()
			elif has_status(Status.FROZEN):
				pass   # уже заморожен, вода ничего не меняет
			else:
				add_status(Status.WET)

		Element.Type.FIRE:
			if has_status(Status.WET) or has_status(Status.CHILL) or has_status(Status.FROZEN):
				damage = vaporize(base_damage)
			else:
				add_status(Status.BURNING)

		Element.Type.ICE:
			if has_status(Status.BURNING):
				damage = vaporize(base_damage)
			elif has_status(Status.WET):
				freeze()
			elif has_status(Status.FROZEN):
				pass   # уже заморожен
			else:
				add_status(Status.CHILL)

		# Будущие реакции добавляются сюда.

	return damage


# --- Реакции ---

## Испарение: x1.5 урон от удара, все наложенные статусы снимаются.
func vaporize(base_damage: int) -> int:
	for status in VAPORIZE_CLEARS:
		remove_status(status)
	trigger_reaction("ИСПАРЕНИЕ")
	return roundi(base_damage * VAPORIZE_MULTIPLIER)


## Заморозка: враг полностью неподвижен FROZEN_DURATION секунд.
func freeze() -> void:
	remove_status(Status.WET)
	remove_status(Status.CHILL)
	add_status(Status.FROZEN)
	trigger_reaction("ЗАМОРОЗКА")


func trigger_reaction(reaction_name: String) -> void:
	reaction_text = reaction_name
	reaction_time_left = 1.0
	reaction_triggered.emit(reaction_name)


# --- Работа со статусами ---

func add_status(status: Status) -> void:
	var is_new := not active.has(status)
	active[status] = get_duration(status)
	if is_new:
		if status == Status.BURNING:
			burn_tick_left = BURN_TICK_INTERVAL
		status_added.emit(status)
	update_visuals()
	apply_movement_modifiers()


func remove_status(status: Status) -> void:
	if active.erase(status):
		status_removed.emit(status)
		update_visuals()
		apply_movement_modifiers()


func has_status(status: Status) -> bool:
	return active.has(status)


## Может ли враг действовать. Атакам и умениям врагов стоит проверять это.
func can_act() -> bool:
	return not has_status(Status.FROZEN)


func get_duration(status: Status) -> float:
	match status:
		Status.WET:
			return WET_DURATION
		Status.BURNING:
			return BURN_DURATION
		Status.CHILL:
			return CHILL_DURATION
		Status.FROZEN:
			return FROZEN_DURATION
	return 0.0


## Урон от горения раз в BURN_TICK_INTERVAL секунд.
func tick_burning(delta: float) -> void:
	if not has_status(Status.BURNING):
		return
	if enemy == null or enemy.isDead:
		return

	burn_tick_left -= delta
	if burn_tick_left <= 0.0:
		burn_tick_left += BURN_TICK_INTERVAL
		enemy.takeDamage(BURN_TICK_DAMAGE)


## Скорость врага и его анимаций: заморозка = 0, мерзлота = замедление.
func apply_movement_modifiers() -> void:
	var factor := 1.0
	if has_status(Status.FROZEN):
		factor = 0.0
	elif has_status(Status.CHILL):
		factor = CHILL_SPEED_MULTIPLIER

	if enemy:
		enemy.speedMovement = base_speed * factor
	if anim_sprite:
		anim_sprite.speed_scale = base_anim_speed * factor


func update_visuals() -> void:
	if sprite == null:
		return
	# Приоритет цвета: заморозка > горение > мерзлота > мокрый
	if has_status(Status.FROZEN):
		sprite.modulate = FROZEN_TINT
	elif has_status(Status.BURNING):
		sprite.modulate = BURN_TINT
	elif has_status(Status.CHILL):
		sprite.modulate = CHILL_TINT
	elif has_status(Status.WET):
		sprite.modulate = WET_TINT
	else:
		sprite.modulate = Color.WHITE


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
	get_parent().add_child.call_deferred(debug_label)


func update_debug_label() -> void:
	if debug_label == null:
		return

	var lines: Array[String] = []
	if show_hp and enemy:
		lines.append("HP %d/%d" % [maxi(enemy.health, 0), enemy.maxHealth])
	if reaction_time_left > 0.0:
		lines.append("! %s !" % reaction_text)
	for status in active:
		lines.append("%s %.1f" % [Status.keys()[status], active[status]])

	debug_label.visible = not lines.is_empty()
	debug_label.text = "\n".join(lines)
