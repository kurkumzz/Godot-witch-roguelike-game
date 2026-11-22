extends Node

@export var initialState: State
var currentState: State


func init() -> void:
	var enemy := get_parent() as BaseEnemy
	for child in get_children():
		if child is State:
			child.enemy = enemy
	currentState = initialState
	if currentState == null:
		push_warning("%s: выберите начальное состояние в StateMachine." % get_parent().name)
		return
	currentState.enter()


func update(delta: float) -> void:
	if currentState == null:
		return
	var next_path = currentState.update(delta)
	if not next_path:
		return
	var next_state := get_node_or_null(next_path) as State
	if next_state == null:
		push_error("%s: не найдено состояние %s." % [get_parent().name, next_path])
		return
	currentState.exit()
	currentState = next_state
	currentState.enter()
