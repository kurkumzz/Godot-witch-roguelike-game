extends "res://generation/swamp_run.gd"

const SLIME := preload("res://scenes/enemies/swamp/mud_slime.tscn")

var fall_limit := 0.0


func _ready() -> void:
	super()
	$CovenGate.global_position = roomsRoot.global_position
	$LairGate.global_position = roomsRoot.get_child(-1).get_node("LairEntrance").global_position
	if RunState.previous_location == $LairGate.destination:
		player.global_position = $LairGate.global_position + Vector2(-32, -30)
	player.reset_physics_interpolation()
	update_camera_room()
	camera.reset_smoothing()

	for i in roomsRoot.get_child_count():
		var room := roomsRoot.get_child(i)
		var bounds: Rect2 = room.get_node("Bounds").get_global_rect()
		fall_limit = maxf(fall_limit, bounds.end.y + 128)
		# враги создаются по маркерам EnemySpawn: маркер сам знает, кого создать
		for marker in room.get_node("Spawns").get_children():
			if not marker is EnemySpawn or marker.enemy_scene == null:
				continue
			# номер комнаты + имя маркера, чтобы убитые враги не появлялись снова
			var enemy_id := StringName("%d_%s" % [i, marker.name])
			if enemy_id in RunState.defeated_enemies:
				continue
			var enemy: BaseEnemy = marker.enemy_scene.instantiate()
			enemy.name = enemy_id
			$entities.add_child(enemy)
			enemy.global_position = marker.global_position
			var patrol := enemy.get_node_or_null("StateMachine/Patrol")
			if patrol and marker.patrol_a and marker.patrol_b:
				patrol.pointA = marker.patrol_a
				patrol.pointB = marker.patrol_b
			enemy.died.connect(_level_enemy_died.bind(enemy_id))

	var spawn_button: Button = player.get_node("GameUI/%SpawnEnemy")
	spawn_button.show()
	spawn_button.pressed.connect(_spawn_enemy)
	if RunState.slots.is_empty():
		RunState.open_first_page()


func _level_enemy_died(enemy_name: StringName) -> void:
	RunState.defeated_enemies.append(enemy_name)
	RunState.gain_experience(1)


func _spawn_enemy() -> void:
	if get_tree().paused or not currentRoom:
		return
	var terrain: TileMapLayer = currentRoom.get_node("Ground")
	for side: float in [player.facing, -player.facing]:
		var cell := terrain.local_to_map(terrain.to_local(player.global_position + Vector2(side * 128, -32)))
		for row in range(cell.y, terrain.get_used_rect().end.y):
			var ground := Vector2i(cell.x, row)
			var tile := terrain.get_cell_tile_data(ground)
			if not tile or tile.get_collision_polygons_count(0) == 0 or terrain.get_cell_source_id(ground + Vector2i.UP) >= 0:
				continue
			var slime: BaseEnemy = SLIME.instantiate()
			slime.maxHealth = 5
			slime.position = $entities.to_local(terrain.to_global(terrain.map_to_local(ground + Vector2i.UP)))
			$entities.add_child(slime)
			slime.died.connect(RunState.gain_experience.bind(1))
			return


func _physics_process(delta: float) -> void:
	super(delta)
	if player.global_position.y > fall_limit:
		player.die()
	if is_player_in_water():
		player.make_wet()


# стоит ли ведьма в тайле воды (у таких тайлов в тайлсете отмечено water)
func is_player_in_water() -> bool:
	if not currentRoom:
		return false
	var ground: TileMapLayer = currentRoom.get_node("Ground")
	for offset in [Vector2.ZERO, Vector2(0, 20)]:
		var cell := ground.local_to_map(ground.to_local(player.global_position + offset))
		var tile := ground.get_cell_tile_data(cell)
		if tile and tile.get_custom_data("water"):
			return true
	return false
