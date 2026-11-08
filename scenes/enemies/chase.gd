extends State

func enter():
	enemy.anim.play("patrol")

func update(delta):
	var distance = enemy.distanceBetween()

	if distance > enemy.loseRange:
		return "Idle"

	if distance < enemy.attackRange:
		return "Attack"

	var target = enemy.player.global_position.x
	var dir = enemy.currentDir(target)
	enemy.velocity.x = enemy.speedMovement * dir
	enemy.flipSprite(dir)
	return null
