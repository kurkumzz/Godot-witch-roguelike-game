extends State

#счетчик
var timer: float
@export var idleTimeCount: float = 3.0

func enter():
	enemy.velocity.x = 0
	timer = 0
	enemy.anim.play("idle")

func update(delta):
	
	if(enemy.distanceBetween() < enemy.detectRange):
		return "Chase"
	
	timer += delta
	if(timer >= idleTimeCount):
		#код для Patrol
		return "Patrol"
		
