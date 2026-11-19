extends CanvasLayer

const RARITY_COLORS := [Color("#c7c7ce"), Color("#9fe2a8"), Color("#d5acff"), Color("#ffe080")]

@onready var player := get_parent()
const ElementParticles := preload("res://scenes/effects/element_particles.gd")
const DOCK_HEIGHT_RATIO := 1.0 / 6.0
const DOCK_ASPECT := 2.4
const SPREAD := Vector2(512, 246)
@onready var grimoire: Control = %Grimoire
var flight: Tween
var reveal: Tween
var choices_ready := false
var effect_rng := RandomNumberGenerator.new()
var opened := 0.0
var base_damage: int
@onready var choice_buttons: VBoxContainer = %Choices
@onready var overlay: ColorRect = %Overlay
@onready var book: VBoxContainer = %Book
@onready var seed_menu: VBoxContainer = %SeedMenu
@onready var seed_input: LineEdit = %SeedInput
var owns_pause := false
var death_dialog := false


func _ready() -> void:
	var shot: projectile = player.PROJECTILE_SCENE.instantiate()
	base_damage = shot.damage
	shot.free()
	%ElementButton.pressed.connect(RunState.switch_element)
	%Icon.gui_input.connect(_on_icon_input)
	get_viewport().size_changed.connect(_layout_book)
	player.health_changed.connect(_update_health)
	player.shield_changed.connect(_update_shield)
	player.died.connect(_on_player_died)
	RunState.changed.connect(refresh)
	%SeedButton.pressed.connect(_open_seed_menu)
	%Restart.pressed.connect(_restart)
	%Cancel.pressed.connect(_cancel_seed_menu)
	seed_input.text_submitted.connect(func(_value: String): _restart())
	seed_input.text_changed.connect(func(_value: String): %SeedError.hide())
	_update_health(player.health, player.max_health)
	_update_shield(player.shield)
	refresh()


func _update_health(current: int, maximum: int) -> void:
	%Health.max_value = maximum
	%Health.value = current
	%HealthText.text = "Здоровье   %d / %d" % [current, maximum]


func _update_shield(current: int) -> void:
	%ShieldText.text = "Щит  %d" % current
	%ShieldText.visible = current > 0


func _on_icon_input(event: InputEvent) -> void:
	if not overlay.visible and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		RunState.switch_element()


func refresh() -> void:
	if not is_inside_tree():
		return
	%SeedButton.text = "Сид  %d" % RunState.run_seed
	%LevelText.text = "Ур. %d    Опыт  %d / %d" % [RunState.level, RunState.experience, RunState.experience_needed]
	%Experience.max_value = RunState.experience_needed
	%Experience.value = RunState.experience
	_update_stats()
	_layout_book()
	if not RunState.pending_choices.is_empty():
		_show_book()
	elif book.is_visible_in_tree():
		_close_dialog()


func _show_book() -> void:
	choices_ready = false
	if reveal:
		reveal.kill()
	%PageNote.modulate.a = 0
	book.get_node("Title").modulate.a = 0
	for child in choice_buttons.get_children():
		choice_buttons.remove_child(child)
		child.queue_free()
	for id in RunState.pending_choices:
		var rarity := RunState.upgrade_rarity(id)
		var button := Button.new()
		button.disabled = true
		button.modulate.a = 0
		button.text = RunState.upgrade_title(id)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 40)
		button.add_theme_stylebox_override("disabled", choice_buttons.get_theme_stylebox("normal", "Button"))
		for color_name in [&"font_color", &"font_disabled_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
			button.add_theme_color_override(color_name, RARITY_COLORS[rarity])
		button.pressed.connect(_choose_page.bind(id))
		button.focus_entered.connect(_preview_page.bind(id))
		button.mouse_entered.connect(_preview_page.bind(id))
		choice_buttons.add_child(button)
	_open_dialog(book)
	_layout_book()
	_fly_to(1.0)
	flight.tween_callback(_reveal_pages)
	_preview_page(RunState.pending_choices[0])


func _reveal_pages() -> void:
	var items: Array[Control] = [%PageNote, book.get_node("Title")]
	items.append_array(choice_buttons.get_children())
	var angle := effect_rng.randf_range(0, TAU)
	reveal = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	for i in items.size():
		var item := items[i]
		var destination := item.position
		var offset := Vector2.RIGHT.rotated(angle + TAU * i / items.size()) * effect_rng.randf_range(16, 32)
		var delay := 0.035 * i
		reveal.tween_property(item, "position", destination, 0.22).from(destination + offset.round()).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		reveal.tween_property(item, "modulate:a", 1.0, 0.22).from(0.0).set_delay(delay)
	reveal.chain().tween_callback(_enable_choices)


func _enable_choices() -> void:
	choices_ready = true
	for button: Button in choice_buttons.get_children():
		button.disabled = false
	choice_buttons.get_child(0).grab_focus()


func _choose_page(id: StringName) -> void:
	if choices_ready:
		RunState.choose_upgrade(id)


func _preview_page(id: StringName) -> void:
	%PageNote.text = "Книга улучшений\n\n%s\n\nУдача %.1f" % [
		RunState.upgrade_title(id), player._stat_multiplier(&"luck")]
	if id == &"low_health_shield":
		%PageNote.text += "\n\nРаз за забег · прочность 25% от максимума здоровья"


func _update_stats() -> void:
	var elem: Element.Type = player.current_element
	%Icon.texture = ElementParticles.TEXTURES.get(elem)
	%Icon.modulate = Element.COLORS[elem]
	%ElementButton.text = Element.DISPLAY_NAMES[elem]
	%Stats.text = "Бег  %.1f\nУдача  %.1f\nДальность  %.1f\nТемп огня  %.1f\nУрон  %.1f" % [
		player._stat_multiplier(&"speed"), player._stat_multiplier(&"luck"),
		player._stat_multiplier(&"range"), player._stat_multiplier(&"fire_rate"),
		base_damage * player._stat_multiplier(&"damage")]


func _fly_to(target: float) -> void:
	if flight:
		flight.kill()
	flight = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	flight.tween_method(_set_opened, opened, target, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_opened(value: float) -> void:
	opened = value
	_layout_book()


func _layout_book() -> void:
	if not is_inside_tree():
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var dock_height := maxf(60.0, roundf(viewport_size.y * DOCK_HEIGHT_RATIO))
	var dock := Vector2(roundf(dock_height * DOCK_ASPECT), dock_height)
	grimoire.visible = (player.has_book_and_wand or book.visible) and not seed_menu.is_visible_in_tree()
	grimoire.position = (viewport_size - dock - Vector2(6, 5)).lerp((viewport_size - SPREAD) / 2, opened).round()
	grimoire.size = dock.lerp(SPREAD, opened).round()
	grimoire.turn = opened
	grimoire.queue_redraw()
	var half := grimoire.size.x / 2
	var dock_visible := not book.visible and is_zero_approx(opened)
	%Icon.visible = dock_visible
	var icon_size := roundf(dock_height / 3.0)
	%Icon.size = Vector2.ONE * icon_size
	%Icon.position = Vector2(roundf((half - icon_size) / 2), roundf(dock_height * 0.10))
	%ElementButton.visible = dock_visible
	%ElementButton.disabled = book.visible or RunState.slots.size() < 2
	%ElementButton.position = Vector2(4, %Icon.position.y + icon_size)
	%ElementButton.size = Vector2(half - 8, roundf(dock_height / 3.0))
	%Stats.visible = dock_visible
	%Stats.position = Vector2(half + 7, roundf((dock_height - 8 - %Stats.get_minimum_size().y) / 2))
	%PageNote.visible = book.visible and is_equal_approx(opened, 1.0)
	%PageNote.position = Vector2(24, 32)
	%PageNote.size = Vector2(half - 46, grimoire.size.y - 68)
	book.position = Vector2(half + 16, 30)
	book.size.x = SPREAD.x / 2 - 44


func _open_seed_menu() -> void:
	if book.is_visible_in_tree():
		return
	death_dialog = player.health <= 0
	%SeedTitle.text = "Забег завершён" if death_dialog else "Новый забег"
	%Cancel.visible = not death_dialog
	seed_input.text = str(RunState.run_seed)
	%SeedError.hide()
	_open_dialog(seed_menu)
	seed_input.grab_focus()
	seed_input.select_all()


func _on_player_died() -> void:
	_open_seed_menu()


func _cancel_seed_menu() -> void:
	if not death_dialog:
		_close_dialog()


func _restart() -> void:
	var value := seed_input.text.strip_edges()
	if not value.is_empty() and not _fits_int64(value):
		%SeedError.show()
		seed_input.grab_focus()
		return
	_close_dialog()
	if value.is_empty():
		RunState.restart_random()
	else:
		RunState.restart_with_seed(value.to_int())


func _fits_int64(value: String) -> bool:
	if not value.is_valid_int():
		return false
	var digits := value.trim_prefix("+").trim_prefix("-").lstrip("0")
	var limit := "9223372036854775808" if value.begins_with("-") else "9223372036854775807"
	return digits.length() < limit.length() or (digits.length() == limit.length() and digits <= limit)


func _open_dialog(content: Control) -> void:
	book.visible = content == book
	seed_menu.visible = content == seed_menu
	overlay.show()
	$Root/Overlay/Center.visible = content == seed_menu
	grimoire.visible = content == book
	if not get_tree().paused:
		owns_pause = true
		get_tree().paused = true


func _close_dialog() -> void:
	var was_book := book.visible
	book.hide()
	seed_menu.hide()
	overlay.hide()
	if was_book:
		choices_ready = false
		if reveal:
			reveal.kill()
		_fly_to(0.0)
	_layout_book()
	get_viewport().gui_release_focus()
	# На следующем физическом такте ввод, закрывший окно, уже обработан.
	var next_tick := get_tree().physics_frame
	if not next_tick.is_connected(_resume_after_input):
		next_tick.connect(_resume_after_input, CONNECT_ONE_SHOT | CONNECT_DEFERRED)


func _resume_after_input() -> void:
	if not overlay.visible:
		_release_pause()


func _exit_tree() -> void:
	_release_pause()


func _release_pause() -> void:
	if owns_pause:
		get_tree().paused = false
		owns_pause = false


func _input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if book.is_visible_in_tree():
		var index: int = event.keycode - KEY_1
		if index >= 0 and index < RunState.pending_choices.size():
			get_viewport().set_input_as_handled()
			_choose_page(RunState.pending_choices[index])
	elif event.keycode == KEY_F2 or (event.keycode == KEY_ESCAPE and seed_menu.is_visible_in_tree()):
		get_viewport().set_input_as_handled()
		if overlay.visible:
			_cancel_seed_menu()
		else:
			_open_seed_menu()
