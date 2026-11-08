extends State

func enter():
	enemy.anim.play("patrol")
	
func update(delta):
	var target = enemy.player.global_position.x
	
	if(enemy.distanceBetween() > enemy.loseRange):
		return "Idle"
	
	var dx = enemy.currentDir(target)
	enemy.velocity.x = enemy.speedMovement * dx
	enemy.flipSprite(dx)
	
