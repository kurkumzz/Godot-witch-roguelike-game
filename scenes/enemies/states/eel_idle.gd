extends State

func enter():
	enemy.velocity.x = 0
	enemy.anim.play("idle")

func update(delta):
	
	if(enemy.distanceBetween() < enemy.detectRange && enemy.isPlayerInHeight()):
		return "Attack"
	
	
