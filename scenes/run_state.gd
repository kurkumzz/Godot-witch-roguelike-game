extends Node
## Сид, страницы книги и улучшения живут в пределах одного забега.

signal changed

const COVEN := "res://scenes/coven.tscn"
# Разные постоянные дают независимые последовательности из одного сида.
const BOOK_SEED_SALT := 0x424f4f4b
const MAP_SEED_SALT := 0x4d415000
const ELEMENT_PAGES := {
	&"water": Element.Type.WATER,
	&"fire": Element.Type.FIRE,
	&"ice": Element.Type.ICE,
	&"electric": Element.Type.ELECTRIC,
}
const STAT_TITLES := {
	&"damage": "Урон +1",
	&"range": "Дальность +25%",
	&"health": "Здоровье +2",
	&"speed": "Скорость +10%",
	&"jump": "Двойной прыжок",
}

var run_seed: int
var level: int
var experience: int
var experience_needed: int
var slots: Array[Element.Type] = []
var active_slot: int
var pending_choices: Array[StringName] = []
var damage_bonus: int
var range_steps: int
var health_bonus: int
var speed_steps: int
var double_jump: bool
var _opening_page_read: bool
var _book_rng := RandomNumberGenerator.new()


func _ready() -> void:
	_start_run(randi())


func _start_run(value: int) -> void:
	run_seed = value
	_book_rng.seed = run_seed ^ BOOK_SEED_SALT
	level = 1
	experience = 0
	experience_needed = 1
	slots.clear()
	active_slot = 0
	pending_choices.clear()
	damage_bonus = 0
	range_steps = 0
	health_bonus = 0
	speed_steps = 0
	double_jump = false
	_opening_page_read = false
	changed.emit()


## Каждый вход на карту воспроизводит её независимо от числа открытых страниц.
func map_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed ^ MAP_SEED_SALT
	return rng


func restart_with_seed(value: int) -> void:
	var tree := get_tree()
	var error := tree.change_scene_to_file(COVEN)
	if error != OK:
		push_error("Не удалось открыть шабаш: %s" % error_string(error))
		return
	tree.paused = false
	_start_run(value)


func restart_random() -> void:
	restart_with_seed(randi())


func open_first_page() -> void:
	if _opening_page_read:
		return
	_opening_page_read = true
	_deal(_available_elements(), 2)
	changed.emit()


func switch_element() -> void:
	if slots.size() > 1 and pending_choices.is_empty():
		active_slot = (active_slot + 1) % slots.size()
		changed.emit()


func gain_experience(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	_check_level_up()
	changed.emit()


func _check_level_up() -> void:
	if not pending_choices.is_empty() or experience < experience_needed:
		return
	experience -= experience_needed
	level += 1
	experience_needed = level
	var pool := _available_elements()
	pool.append_array([&"damage", &"range", &"health", &"speed"])
	if not double_jump:
		pool.append(&"jump")
	_deal(pool)


func _available_elements() -> Array[StringName]:
	var pages: Array[StringName] = []
	for page: StringName in ELEMENT_PAGES:
		if not slots.has(ELEMENT_PAGES[page]):
			pages.append(page)
	return pages


func _deal(pool: Array[StringName], count := 3) -> void:
	pending_choices.clear()
	for i in mini(count, pool.size()):
		var index := _book_rng.randi_range(0, pool.size() - 1)
		pending_choices.append(pool.pop_at(index))


func upgrade_title(id: StringName) -> String:
	if not ELEMENT_PAGES.has(id):
		return STAT_TITLES.get(id, str(id))
	var title: String = Element.DISPLAY_NAMES[ELEMENT_PAGES[id]]
	if slots.size() == 2:
		return "%s вместо %s" % [title, Element.DISPLAY_NAMES[slots[active_slot]]]
	return title


func choose_upgrade(id: StringName) -> void:
	if not pending_choices.has(id):
		return
	if ELEMENT_PAGES.has(id):
		if slots.size() < 2:
			slots.append(ELEMENT_PAGES[id])
		else:
			slots[active_slot] = ELEMENT_PAGES[id]
	else:
		match id:
			&"damage": damage_bonus += 1
			&"range": range_steps += 1
			&"health": health_bonus += 2
			&"speed": speed_steps += 1
			&"jump": double_jump = true
	pending_choices.clear()
	_check_level_up()
	changed.emit()
