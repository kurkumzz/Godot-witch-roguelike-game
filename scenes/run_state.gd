extends Node
## Сид, страницы книги и улучшения живут в пределах одного забега.

signal changed

const COVEN := "res://scenes/coven.tscn"
# Разные постоянные дают независимые последовательности из одного сида.
const BOOK_SEED_SALT := 0x424f4f4b
const MAP_SEED_SALT := 0x4d415000
const Pages := preload("res://scenes/book_pages.gd")
const ELEMENT_PAGES := Pages.ELEMENTS

var run_seed: int
var level: int
var experience: int
var experience_needed: int
var slots: Array[Element.Type] = []
var active_slot: int
var pending_choices: Array[StringName] = []
var shield_spent := false
var damage_remainder := 0
var _stat_bonuses: Dictionary[StringName, int] = {}
var _passives: Array[StringName] = []
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
	_stat_bonuses.clear()
	_passives.clear()
	shield_spent = false
	damage_remainder = 0
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
	pending_choices = Pages.deal(_book_rng, slots, _passives, true)
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
	pending_choices = Pages.deal(_book_rng, slots, _passives, false, stat_percent(&"luck"))


func upgrade_rarity(id: StringName) -> int:
	return Pages.rarity(id)


func upgrade_title(id: StringName) -> String:
	return Pages.title(id, slots, active_slot)


func stat_percent(id: StringName) -> int:
	return _stat_bonuses.get(id, 0)


func has_passive(id: StringName) -> bool:
	return _passives.has(id)


func choose_upgrade(id: StringName) -> void:
	if not pending_choices.has(id):
		return
	if ELEMENT_PAGES.has(id):
		if slots.size() < 2:
			slots.append(ELEMENT_PAGES[id])
		else:
			slots[active_slot] = ELEMENT_PAGES[id]
	elif Pages.PASSIVES.has(id):
		_passives.append(id)
	else:
		var stat := Pages.stat_id(id)
		_stat_bonuses[stat] = stat_percent(stat) + Pages.percent(id)
	pending_choices.clear()
	_check_level_up()
	changed.emit()
