
extends Node

@export var initialState: State
var currentState: State

func update(delta: float):
	var next = currentState.update(delta)
	
	if next:
		currentState.exit()
		currentState = get_node(next)
		currentState.enter()

func init():
	for child in get_children():
		child.enemy = get_parent()
	currentState = initialState
	currentState.enter()
