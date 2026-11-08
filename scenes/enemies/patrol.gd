extends State

@export var pointA: Marker2D
@export var pointB: Marker2D

var target: Marker2D

func enter():
	if pointA == null or pointB == null:
		push_error(enemy.name + ": в Patrol не назначены pointA/pointB")
		return
	if target == null:
		target = pointA
	enemy.anim.play("patrol")

func update(delta):
	if pointA == null or pointB == null:
		enemy.velocity.x = 0
		return null

	if enemy.distanceBetween() < enemy.detectRange:
		return "Chase"

	var dx = target.global_position.x - enemy.global_position.x
	if abs(dx) < 5:
		if target == pointA:
			target = pointB
		else:
			target = pointA
		enemy.velocity.x = 0
		return "Idle"

	var dir = sign(dx)
	enemy.velocity.x = dir * enemy.speedMovement
	enemy.anim.flip_h = dir < 0
	return null
