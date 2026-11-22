extends State

enum Phase { WINDUP, DASH, COOLDOWN }

var phase: Phase
var timer: float
var dashDir: float

@export var windupTime: float = 0.5
@export var dashTime: float = 0.2
@export var attackCoolDown: float = 1.0

@export var dashDistance: float = 100.0
var currentDashVelocity: float
var dashDeceleration: float


func enter():
	startWindup()

func update(delta):
	timer += delta

	match phase:
		Phase.WINDUP:
			enemy.velocity.x = 0
			if timer > windupTime:
				phase = Phase.DASH
				timer = 0.0
				enemy.anim.play("attack")
				
				var averageSpeed = dashDistance / dashTime
				currentDashVelocity = averageSpeed * 2  
				dashDeceleration = currentDashVelocity / dashTime
		Phase.DASH:
			enemy.velocity.x = currentDashVelocity * dashDir

			currentDashVelocity = move_toward(currentDashVelocity, 0.0, dashDeceleration * delta)
			
			if currentDashVelocity <= 0.0:
				phase = Phase.COOLDOWN
				timer = 0.0
		Phase.COOLDOWN:
			enemy.velocity.x = 0
			enemy.anim.play("confused")
			if timer > attackCoolDown:
				if enemy.distanceBetween() < enemy.attackRange:
					startWindup()
				else:
					return "Chase"
	return null

func startWindup():
	phase = Phase.WINDUP
	timer = 0.0
	enemy.velocity.x = 0
	dashDir = enemy.currentDir(enemy.player.global_position.x)
	enemy.flipSprite(dashDir)
	enemy.anim.play("idle")
