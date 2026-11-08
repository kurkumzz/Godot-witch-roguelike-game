extends State

func enter():
	enemy.anim.play("patrol")
	
func update(delta):
	var target = enemy.player.global_position.x
	
	if(enemy.distanceBetween() > enemy.loseRange):
		return "Idle"
	
	var dx = target - enemy.global_position.x
	var dir = sign(dx)
	enemy.velocity.x = enemy.speedMovement * dir
	enemy.anim.flip_h = dir < 0
	
