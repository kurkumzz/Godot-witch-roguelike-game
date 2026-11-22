class_name statusComp
extends Node
## Хранит статусы врага и реагирует на попадания стихий.
## Добавляется дочерним узлом к врагу. Имя узла: statusComp.

signal status_added(status: Status)
signal status_removed(status: Status)
signal reaction_triggered(reaction_name: String)
signal chain_jumped(from_pos: Vector2, to_pos: Vector2)   # для эффекта молнии между врагами

enum Status { WET, BURNING, CHILL, FROZEN, SHOCKED, CHARGED, FRAGILE }

const ElementParticles := preload("res://scenes/effects/element_particles.gd")
const PARTICLE_ELEMENT := {
	Status.WET: Element.Type.WATER,
	Status.BURNING: Element.Type.FIRE,
	Status.CHILL: Element.Type.ICE,
	Status.FROZEN: Element.Type.ICE,
	Status.SHOCKED: Element.Type.ELECTRIC,
	Status.CHARGED: Element.Type.ELECTRIC,
}
var status_particles: Dictionary[Status, CPUParticles2D] = {}

# --- Мокрый ---
const WET_DURATION := 5.0
const WET_TINT := Color(0.22, 0.44, 1.0, 0.80)

# --- Горение ---
const BURN_DURATION := 3.0
const BURN_TICK_INTERVAL := 1.0   # раз в сколько секунд наносится урон
const BURN_TICK_DAMAGE := 1
const BURN_TINT := Color(1.0, 0.18, 0.12, 0.72)

# --- Мерзлота ---
const CHILL_DURATION := 4.0
const CHILL_SPEED_MULTIPLIER := 0.5   # 0.5 = враг и его анимации вдвое медленнее
const CHILL_TINT := Color(0.42, 0.82, 1.0, 0.75)

# --- Заморозка ---
const FROZEN_DURATION := 2.0
const FROZEN_TINT := Color(0.68, 0.94, 1.0, 0.9)

# --- Наэлектризован (вешает электро, ждёт воду, огонь или лёд) ---
const SHOCKED_DURATION := 4.0

# --- Заряд ---
const CHARGED_DURATION := 3.0
const CHARGED_TICK_INTERVAL := 1.0   # раз в сколько секунд урон + оглушение
const CHARGED_TICK_DAMAGE := 1
const CHARGED_STUN := 0.3            # на сколько секунд враг замирает

# --- Хрупкий (после сверхпроводимости) ---
const FRAGILE_DURATION := 4.0
const FRAGILE_MULTIPLIER := 1.5      # весь входящий урон x1.5 (при уроне 1 округлится до 2)
const FRAGILE_TINT := Color(0.85, 0.7, 1.0, 0.45)

# --- Реакции ---
const VAPORIZE_MULTIPLIER := 1.5
# Что снимает испарение
const VAPORIZE_CLEARS := [Status.WET, Status.BURNING, Status.CHILL, Status.FROZEN]

const CHARGE_MULTIPLIER := 2.0

const OVERLOAD_MULTIPLIER := 2.0
const OVERLOAD_KNOCKBACK := Vector2(350.0, 200.0)   # x: сила толчка, y: подброс
const OVERLOAD_KNOCKBACK_DECAY := 800.0

const SHATTER_MULTIPLIER := 2.0

# --- Цепь по льду ---
const CHAIN_RADIUS := 160.0           # на каком расстоянии разряд ищет соседей
const CHAIN_MAX_TARGETS := 2          # сколько врагов может задеть цепь
const CHAIN_DAMAGE_FACTOR := 0.5      # доля урона удара, которая уходит соседям

# --- Отладочная надпись ---
@export var show_debug_label := true
@export var show_hp := true
@export var label_offset := Vector2(-30, -58)

# Активные статусы: Status -> сколько секунд осталось
var active := {}
var burn_tick_left := 0.0
var charged_tick_left := 0.0
var stun_left := 0.0   # короткое оглушение (не статус, у него своя логика)
var debug_label: Label
var reaction_text := ""
var reaction_time_left := 0.0

# Исходные значения врага, к ним возвращаемся после снятия замедления
var base_speed := 0.0
var base_anim_speed := 1.0

@onready var enemy := get_parent() as BaseEnemy
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
	tick_charged(delta)

	if stun_left > 0.0:
		stun_left -= delta
		if stun_left <= 0.0:
			stun_left = 0.0
			apply_movement_modifiers()
			update_visuals()

	for status in active.keys():
		active[status] -= delta
		if active[status] <= 0.0:
			remove_status(status)

	reaction_time_left = maxf(reaction_time_left - delta, 0.0)
	update_debug_label()


# --- Главная точка входа ---

# Вызывается снарядом перед нанесением урона.
# hit_direction - направление полёта снаряда (нужно для отбрасывания).
# Возвращает итоговый урон (реакции могут его менять).
func process_hit(element: Element.Type, base_damage: int, hit_direction := Vector2.RIGHT) -> int:
	var damage := base_damage
	# Хрупкость считаем по состоянию ДО удара, чтобы удар, который её наложил, не усиливался
	var was_fragile := has_status(Status.FRAGILE)

	match element:
		Element.Type.WATER:
			if has_status(Status.SHOCKED):
				damage = charge(base_damage)
			elif has_status(Status.BURNING):
				damage = vaporize(base_damage)
			elif has_status(Status.CHILL):
				freeze()
			elif has_status(Status.FROZEN):
				pass   # уже заморожен, вода ничего не меняет
			else:
				add_status(Status.WET)

		Element.Type.FIRE:
			if has_status(Status.SHOCKED):
				damage = overload(base_damage, hit_direction)
			elif has_status(Status.WET) or has_status(Status.CHILL) or has_status(Status.FROZEN):
				damage = vaporize(base_damage)
			else:
				add_status(Status.BURNING)

		Element.Type.ICE:
			if has_status(Status.SHOCKED):
				superconduct()
			elif has_status(Status.BURNING):
				damage = vaporize(base_damage)
			elif has_status(Status.WET):
				freeze()
			elif has_status(Status.FROZEN):
				pass   # уже заморожен
			else:
				add_status(Status.CHILL)

		Element.Type.ELECTRIC:
			if has_status(Status.WET):
				damage = charge(base_damage)
			elif has_status(Status.BURNING):
				damage = overload(base_damage, hit_direction)
			elif has_status(Status.FROZEN):
				damage = shatter(base_damage)
				spread_chain(base_damage)
			elif has_status(Status.CHILL):
				superconduct()
				spread_chain(base_damage)
			else:
				add_status(Status.SHOCKED)

		# Будущие реакции добавляются сюда.

	if was_fragile:
		damage = roundi(damage * FRAGILE_MULTIPLIER)
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


## Заряд (электро + вода): x2 урон от удара, затем статус «заряд»:
## небольшой урон и оглушение на CHARGED_STUN секунд (сразу и на каждом тике).
func charge(base_damage: int) -> int:
	remove_status(Status.WET)
	remove_status(Status.SHOCKED)
	add_status(Status.CHARGED)
	stun(CHARGED_STUN)
	trigger_reaction("ЗАРЯД")
	return roundi(base_damage * CHARGE_MULTIPLIER)


## Перегрузка (электро + огонь): враг взрывается, его отбрасывает далеко
## по направлению снаряда, удар наносит x2 урон.
func overload(base_damage: int, hit_direction: Vector2) -> int:
	remove_status(Status.BURNING)
	remove_status(Status.SHOCKED)

	var dir := signf(hit_direction.x)
	if dir == 0.0:
		dir = 1.0
	if enemy:
		enemy.apply_knockback(
			Vector2(dir * OVERLOAD_KNOCKBACK.x, -OVERLOAD_KNOCKBACK.y),
			OVERLOAD_KNOCKBACK_DECAY)

	# Сюда можно подключить сцену взрыва через сигнал reaction_triggered
	trigger_reaction("ПЕРЕГРУЗКА")
	return roundi(base_damage * OVERLOAD_MULTIPLIER)


## Сверхпроводимость (электро + лёд): лёд и электро гасят друг друга,
## враг становится хрупким на FRAGILE_DURATION секунд (весь входящий урон x1.5).
func superconduct() -> void:
	remove_status(Status.CHILL)
	remove_status(Status.SHOCKED)
	add_status(Status.FRAGILE)
	trigger_reaction("СВЕРХПРОВОДИМОСТЬ")


## Раскол (электро по замороженному): лёд ломается, x2 урон от удара.
func shatter(base_damage: int) -> int:
	remove_status(Status.FROZEN)
	trigger_reaction("РАСКОЛ")
	return roundi(base_damage * SHATTER_MULTIPLIER)


# --- Цепь по льду ---

## Может ли враг проводить разряд цепи (охлаждён или заморожен).
func is_conductive() -> bool:
	return has_status(Status.CHILL) or has_status(Status.FROZEN)


## Разряд перескакивает на ближайших охлаждённых/замороженных врагов.
## Каждый из них получает свою реакцию (раскол или сверхпроводимость).
## Дальше цепь не идёт: соседи сами её не продолжают.
func spread_chain(base_damage: int) -> void:
	if enemy == null:
		return

	var targets: Array[statusComp] = []
	for node in get_tree().get_nodes_in_group(BaseEnemy.ENEMY_GROUP):
		var other := node as BaseEnemy
		if other == null or other == enemy or other.isDead:
			continue
		if enemy.global_position.distance_to(other.global_position) > CHAIN_RADIUS:
			continue
		var other_status := other.get_node_or_null("statusComp") as statusComp
		if other_status and other_status.is_conductive():
			targets.append(other_status)

	targets.sort_custom(func(a: statusComp, b: statusComp) -> bool:
		return a.enemy.global_position.distance_squared_to(enemy.global_position) \
			< b.enemy.global_position.distance_squared_to(enemy.global_position))

	var chain_damage := maxi(roundi(base_damage * CHAIN_DAMAGE_FACTOR), 1)
	for i in mini(targets.size(), CHAIN_MAX_TARGETS):
		chain_jumped.emit(enemy.global_position, targets[i].enemy.global_position)
		targets[i].receive_chain(chain_damage)


## Попадание разряда цепи по этому врагу.
func receive_chain(chain_damage: int) -> void:
	if enemy == null or enemy.isDead:
		return
	var was_fragile := has_status(Status.FRAGILE)
	var damage := chain_damage
	if has_status(Status.FROZEN):
		damage = shatter(chain_damage)
	elif has_status(Status.CHILL):
		superconduct()
	if was_fragile:
		damage = roundi(damage * FRAGILE_MULTIPLIER)
	enemy.takeDamage(damage)


func trigger_reaction(reaction_name: String) -> void:
	reaction_text = reaction_name
	reaction_time_left = 1.0
	reaction_triggered.emit(reaction_name)


# --- Работа со статусами ---

func add_status(status: Status) -> void:
	var is_new := not active.has(status)
	active[status] = get_duration(status)
	if is_new:
		if PARTICLE_ELEMENT.has(status):
			var particles := ElementParticles.new()
			enemy.add_child(particles)
			particles.z_index = 1
			particles.configure(PARTICLE_ELEMENT[status], true)
			status_particles[status] = particles
		if status == Status.BURNING:
			burn_tick_left = BURN_TICK_INTERVAL
		elif status == Status.CHARGED:
			charged_tick_left = CHARGED_TICK_INTERVAL
		status_added.emit(status)
	update_visuals()
	apply_movement_modifiers()


func remove_status(status: Status) -> void:
	if active.erase(status):
		if status_particles.has(status):
			status_particles[status].hide()
			status_particles[status].queue_free()
			status_particles.erase(status)
		status_removed.emit(status)
		update_visuals()
		apply_movement_modifiers()


func has_status(status: Status) -> bool:
	return active.has(status)


## Короткое оглушение: враг неподвижен duration секунд (не складывается, берётся максимум).
func stun(duration: float) -> void:
	stun_left = maxf(stun_left, duration)
	apply_movement_modifiers()
	update_visuals()


## Может ли враг действовать. Атакам и умениям врагов стоит проверять это.
func can_act() -> bool:
	return not has_status(Status.FROZEN) and stun_left <= 0.0


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
		Status.SHOCKED:
			return SHOCKED_DURATION
		Status.CHARGED:
			return CHARGED_DURATION
		Status.FRAGILE:
			return FRAGILE_DURATION
	return 0.0


## Урон, который наносят тики статусов, тоже усиливается хрупкостью.
func fragile_damage(damage: int) -> int:
	if has_status(Status.FRAGILE):
		return roundi(damage * FRAGILE_MULTIPLIER)
	return damage


## Урон от горения раз в BURN_TICK_INTERVAL секунд.
func tick_burning(delta: float) -> void:
	if not has_status(Status.BURNING):
		return
	if enemy == null or enemy.isDead:
		return

	burn_tick_left -= delta
	if burn_tick_left <= 0.0:
		burn_tick_left += BURN_TICK_INTERVAL
		enemy.takeDamage(fragile_damage(BURN_TICK_DAMAGE))


## Урон и оглушение от заряда раз в CHARGED_TICK_INTERVAL секунд.
func tick_charged(delta: float) -> void:
	if not has_status(Status.CHARGED):
		return
	if enemy == null or enemy.isDead:
		return

	charged_tick_left -= delta
	if charged_tick_left <= 0.0:
		charged_tick_left += CHARGED_TICK_INTERVAL
		stun(CHARGED_STUN)
		enemy.takeDamage(fragile_damage(CHARGED_TICK_DAMAGE))


## Скорость врага и его анимаций: заморозка и оглушение = 0, мерзлота = замедление.
func apply_movement_modifiers() -> void:
	var factor := 1.0
	if has_status(Status.FROZEN) or stun_left > 0.0:
		factor = 0.0
	elif has_status(Status.CHILL):
		factor = CHILL_SPEED_MULTIPLIER

	if enemy:
		enemy.speedMovement = base_speed * factor
	if anim_sprite:
		anim_sprite.speed_scale = base_anim_speed * factor


func update_visuals() -> void:
	if enemy == null or enemy.flash_material == null:
		return
	# Электричество помечается искрами и сохраняет исходный цвет спрайта.
	var tint := Color.TRANSPARENT
	if has_status(Status.FROZEN):
		tint = FROZEN_TINT
	elif has_status(Status.BURNING):
		tint = BURN_TINT
	elif has_status(Status.FRAGILE):
		tint = FRAGILE_TINT
	elif has_status(Status.CHILL):
		tint = CHILL_TINT
	elif has_status(Status.WET):
		tint = WET_TINT
	enemy.flash_material.set_shader_parameter("status_tint", tint)


# --- Отладочная надпись ---

func create_debug_label() -> void:
	debug_label = enemy.get_node("Label") as Label
	debug_label.position = label_offset
	debug_label.custom_minimum_size = Vector2(60, 0)
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_label.add_theme_font_size_override("font_size", 8)
	debug_label.add_theme_color_override("font_outline_color", Color.BLACK)
	debug_label.add_theme_constant_override("outline_size", 3)
	debug_label.visible = false
	var icons := HBoxContainer.new()
	icons.position = label_offset - Vector2(12, 11)
	icons.size.x = 84
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icons.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icons.add_theme_constant_override("separation", 2)
	enemy.add_child.call_deferred(icons)
	for status in Status.values():
		var element: Element.Type = PARTICLE_ELEMENT.get(status, Element.Type.ICE)
		var icon := TextureRect.new()
		icon.texture = ElementParticles.TEXTURES[element]
		icon.modulate = FRAGILE_TINT.lightened(0.2) if status == Status.FRAGILE else Element.COLORS[element]
		icon.modulate.a = 1
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(10, 10)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icons.add_child(icon)
		icon.visible = has_status(status)
		status_added.connect(func(added: Status): 
			if added == status: icon.show())
		status_removed.connect(func(removed: Status):
			if removed == status: icon.hide())


func update_debug_label() -> void:
	if debug_label == null:
		return

	var lines: Array[String] = []
	if show_hp and enemy:
		lines.append("HP %d/%d" % [maxi(enemy.health, 0), enemy.maxHealth])
	if reaction_time_left > 0.0:
		lines.append("! %s !" % reaction_text)

	debug_label.visible = not lines.is_empty()
	debug_label.text = "\n".join(lines)
