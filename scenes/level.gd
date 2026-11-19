extends Node2D

# Нижний ярус в трёх тайлах над полом: на него хватает обычного прыжка,
# а под платформой остаётся место для прохода.
@export var platform_origins: Array[Vector2i] = [
	Vector2i(-36, 15), Vector2i(-20, 15), Vector2i(24, 15),
	Vector2i(40, 15), Vector2i(56, 15), Vector2i(72, 15),
]

const FLOOR_ATLAS := 1
const SLIME := preload("res://scenes/enemies/base_enemy.tscn")
const LEFT_EDGE := Vector2i(6, 5)
const MIDDLE := Vector2i(7, 5)
const RIGHT_EDGE := Vector2i(8, 5)

@onready var terrain: TileMapLayer = $TileMapLayer2


func _ready() -> void:
	var spawn_button: Button = $entities/player/GameUI.get_node("%SpawnEnemy")
	spawn_button.show()
	spawn_button.pressed.connect(_spawn_enemy)
	if RunState.slots.is_empty():
		RunState.open_first_page()
	var rng := RunState.map_rng()
	for origin in platform_origins:
		var lower := origin + Vector2i(rng.randi_range(0, 2), 0)
		var lower_width := rng.randi_range(2, 4)
		var gap := rng.randi_range(1, 2)
		place_platform(lower, lower_width)
		place_platform(lower + Vector2i(lower_width + gap, -1), rng.randi_range(2, 4))

	for entity in $entities.get_children():
		if entity is BaseEnemy:
			entity.died.connect(RunState.gain_experience.bind(1))


func _spawn_enemy() -> void:
	if get_tree().paused:
		return
	var witch := $entities/player
	for side: float in [witch.facing, -witch.facing]:
		var cell := terrain.local_to_map(terrain.to_local(witch.global_position + Vector2(side * 128, -32)))
		for row in range(cell.y, terrain.get_used_rect().end.y):
			var ground := Vector2i(cell.x, row)
			if terrain.get_cell_source_id(ground) < 0 or terrain.get_cell_source_id(ground + Vector2i.UP) >= 0:
				continue
			var slime: BaseEnemy = SLIME.instantiate()
			slime.maxHealth = 5
			slime.position = $entities.to_local(terrain.to_global(terrain.map_to_local(ground + Vector2i.UP)))
			$entities.add_child(slime)
			slime.died.connect(RunState.gain_experience.bind(1))
			return


func place_platform(start: Vector2i, width: int) -> void:
	# Ручная раскладка имеет приоритет, если художник застроил эту зону.
	for offset in width:
		if terrain.get_cell_source_id(start + Vector2i(offset, 0)) != -1:
			return
	terrain.set_cell(start, FLOOR_ATLAS, LEFT_EDGE)
	for offset in range(1, width - 1):
		terrain.set_cell(start + Vector2i(offset, 0), FLOOR_ATLAS, MIDDLE)
	terrain.set_cell(start + Vector2i(width - 1, 0), FLOOR_ATLAS, RIGHT_EDGE)


func _on_fall_zone_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()
