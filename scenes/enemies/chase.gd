extends State

func enter():
	enemy.anim.play("patrol")

func update(delta):
	var distance = enemy.distanceBetween()
	
	if distance > enemy.loseRange:
		return "Idle"

	if not enemy.isPlayerInHeight():
		return "Idle"
	
	if distance < enemy.attackRange:
		return "Attack"

	var xDifference =  abs(enemy.player.global_position.x - enemy.global_position.x)
	var target = enemy.player.global_position.x
	if(xDifference < enemy.deadZone):
		enemy.velocity.x = 0
		enemy.anim.play("idle")
	else:
		enemy.anim.play("patrol")
		var dir = enemy.currentDir(target)
		enemy.velocity.x = enemy.speedMovement * dir
		enemy.flipSprite(dir)
	return null
