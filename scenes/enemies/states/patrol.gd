extends State

@export var pointA: Marker2D
@export var pointB: Marker2D

var target: Marker2D

func enter():
	if target == null:
		target = pointA
	enemy.anim.play("patrol")

func update(delta):
	if enemy.detects_player():
		return "Chase"
	if pointA == null or pointB == null:
		return "Idle"

	var dir = enemy.currentDir(target.global_position.x)
	var dx = target.global_position.x - enemy.global_position.x
	if abs(dx) < 5:
		if target == pointA:
			target = pointB
		else:
			target = pointA
		enemy.velocity.x = 0
		return "Idle"

	enemy.velocity.x = dir * enemy.speedMovement
	enemy.flipSprite(dir)
	return null
