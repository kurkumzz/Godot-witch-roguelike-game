extends CanvasLayer

@onready var player := get_parent()
@onready var slot_labels: Array[Label] = [%SlotOne, %SlotTwo]
@onready var choice_buttons: VBoxContainer = %Choices
@onready var overlay: ColorRect = %Overlay
@onready var book: VBoxContainer = %Book
@onready var seed_menu: VBoxContainer = %SeedMenu
@onready var seed_input: LineEdit = %SeedInput
var owns_pause := false
var death_dialog := false


func _ready() -> void:
	player.health_changed.connect(_update_health)
	player.died.connect(_on_player_died)
	RunState.changed.connect(refresh)
	%SeedButton.pressed.connect(_open_seed_menu)
	%Restart.pressed.connect(_restart)
	%Cancel.pressed.connect(_cancel_seed_menu)
	seed_input.text_submitted.connect(func(_value: String): _restart())
	seed_input.text_changed.connect(func(_value: String): %SeedError.hide())
	var bindings := InputMap.action_get_events("change")
	if not bindings.is_empty():
		%SwitchHint.text = "%s · сменить" % bindings[0].as_text()
	_update_health(player.health, player.max_health)
	refresh()


func _update_health(current: int, maximum: int) -> void:
	%Health.max_value = maximum
	%Health.value = current
	%HealthText.text = "Здоровье   %d / %d" % [current, maximum]


func refresh() -> void:
	%SeedButton.text = "Сид  %d" % RunState.run_seed
	%LevelText.text = "Ур. %d    Опыт  %d / %d" % [RunState.level, RunState.experience, RunState.experience_needed]
	%Experience.max_value = RunState.experience_needed
	%Experience.value = RunState.experience
	%Slots.visible = player.has_book_and_wand
	%SwitchHint.visible = RunState.slots.size() == 2
	for i in slot_labels.size():
		var element := Element.Type.NONE
		if i < RunState.slots.size():
			element = RunState.slots[i]
		var marker := "▶" if i == RunState.active_slot and element != Element.Type.NONE else "·"
		slot_labels[i].text = "%s %s" % [marker, Element.DISPLAY_NAMES[element]]
		slot_labels[i].modulate = Element.COLORS[element]
	if not RunState.pending_choices.is_empty():
		_show_book()
	elif book.is_visible_in_tree():
		_close_dialog()


func _show_book() -> void:
	for child in choice_buttons.get_children():
		choice_buttons.remove_child(child)
		child.queue_free()
	for i in RunState.pending_choices.size():
		var id := RunState.pending_choices[i]
		var button := Button.new()
		button.text = "%d.  %s" % [i + 1, RunState.upgrade_title(id)]
		button.custom_minimum_size.y = 30
		button.pressed.connect(RunState.choose_upgrade.bind(id))
		choice_buttons.add_child(button)
	_open_dialog(book)
	choice_buttons.get_child(0).grab_focus()


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
	if not get_tree().paused:
		owns_pause = true
		get_tree().paused = true


func _close_dialog() -> void:
	overlay.hide()
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
			RunState.choose_upgrade(RunState.pending_choices[index])
	elif event.keycode == KEY_F2 or (event.keycode == KEY_ESCAPE and seed_menu.is_visible_in_tree()):
		get_viewport().set_input_as_handled()
		if overlay.visible:
			_cancel_seed_menu()
		else:
			_open_seed_menu()
