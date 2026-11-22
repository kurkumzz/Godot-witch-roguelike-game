extends State

enum Phase { WINDUP, SHOOT, COOLDOWN }

# сцена снаряда: загружаем один раз, потом создаём копии при каждом выстреле
const BULLET := preload("res://scenes/enemies/enemy_bullet.tscn")

var phase: Phase
var timer: float
var shootDir: float

@export var windupTime: float = 0.4
@export var attackCoolDown: float = 1.5
@export var chargeSound: AudioStream
@export var muzzleOffset := Vector2(16, -4)   # откуда вылетает снаряд относительно угря

func enter():
	startWindup()

func update(delta):
	timer += delta
	enemy.velocity.x = 0   # угорь всегда стоит на месте

	match phase:
		Phase.WINDUP:
			if timer > windupTime:
				phase = Phase.SHOOT
				timer = 0.0
				enemy.anim.play("attack")

		Phase.SHOOT:
			shoot()
			phase = Phase.COOLDOWN
			timer = 0.0

		Phase.COOLDOWN:
			enemy.anim.play("idle")
			if timer > attackCoolDown:
				# ведьма всё ещё рядом и на той же высоте — стреляем снова
				if enemy.distanceBetween() < enemy.detectRange and enemy.isPlayerInHeight():
					startWindup()
				else:
					return "Idle"
	return null

func startWindup():
	phase = Phase.WINDUP
	timer = 0.0
	shootDir = enemy.currentDir(enemy.player.global_position.x)
	enemy.flipSprite(shootDir)
	enemy.anim.play("windup")
	enemy.playSound(chargeSound)

func shoot():
	# 1. создаём новый снаряд из сцены
	var bullet := BULLET.instantiate()
	# 2. говорим, куда лететь
	bullet.direction = shootDir
	# 3. ставим перед угрём (смещение по x зеркалим в сторону выстрела)
	bullet.global_position = enemy.global_position + Vector2(muzzleOffset.x * shootDir, muzzleOffset.y)
	# 4. добавляем в уровень, а НЕ в угря: иначе снаряд будет двигаться вместе с ним
	#    и исчезнет, если угря убьют
	enemy.get_parent().add_child(bullet)
