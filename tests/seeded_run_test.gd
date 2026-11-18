extends SceneTree
## godot --headless --fixed-fps 60 --script res://tests/seeded_run_test.gd


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var original := await _play(42)
	var other := await _play(-17)
	var replay := await _play(42)
	if original.is_empty() or replay != original or other.is_empty() or other.tiles == original.tiles:
		push_error("Забег не воспроизводится или смена сида не меняет карту.")
		quit(1)
		return
	print("PASS: pickup, book, level, XP and seed replay")
	quit()


func _play(value: int) -> Dictionary:
	var run := root.get_node("RunState")
	run.restart_with_seed(value)
	await scene_changed
	Input.action_press("right")
	for frame in 240:
		await physics_frame
		if paused:
			break
	Input.action_release("right")
	if run.pending_choices.size() != 2 or not run.slots.is_empty():
		return {}
	var opening: Array = run.pending_choices.duplicate()
	var ui := get_first_node_in_group("player").get_node("GameUI")
	ui.get_node("%Choices").get_child(0).pressed.emit()
	if run.slots != [run.ELEMENT_PAGES[opening[0]]]:
		return {}

	Input.action_press("right")
	for frame in 120:
		await physics_frame
		if current_scene and current_scene.scene_file_path == "res://scenes/level.tscn":
			break
	Input.action_release("right")
	if not current_scene or not current_scene.has_node("TileMapLayer2"):
		return {}
	var tiles: PackedByteArray = current_scene.get_node("TileMapLayer2").tile_map_data
	var enemy := get_first_node_in_group("enemies")
	enemy.takeDamage(enemy.health)
	if not paused or run.level != 2 or run.pending_choices.size() != 3 or run.slots.size() != 1:
		return {}
	return {"opening": opening, "tiles": tiles, "level_two": run.pending_choices.duplicate()}
