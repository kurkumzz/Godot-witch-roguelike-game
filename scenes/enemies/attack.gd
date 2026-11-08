extends State

enum Phase { WINDUP, DASH, COOLDOWN }

var phase: Phase
var timer: float
var dashDir: float

@export var plusToSpeed: float = 2.0
@export var windupTime: float = 0.5
@export var dashTime: float = 0.25
@export var attackCoolDown: float = 0.5

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
		Phase.DASH:
			enemy.velocity.x = enemy.speedMovement * plusToSpeed * dashDir
			if timer > dashTime:
				phase = Phase.COOLDOWN
				timer = 0.0
		Phase.COOLDOWN:
			enemy.velocity.x = 0
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
