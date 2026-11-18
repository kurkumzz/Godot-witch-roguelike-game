extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal element_changed(element: Element.Type)

enum State { NORMAL, DASH, DEAD, HURT, ATTACK }

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const HIT_FLASH_SHADER := preload("res://scenes/shaders/hit.gdshader")

const BASE_HEALTH := 10
const SPEED := 200.0
const JUMP_STRENGTH := 400.0
const JUMP_CUT := 0.4
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.12
const GRAVITY := 700.0
const FALL_GRAVITY_MULTIPLIER := 1.6
const FALL_GRAVITY_DELAY := 0.15
const MAX_FALL_SPEED := 500.0
const SPRITE_FACES_LEFT := false

const DASH_SPEED := 350.0
const DASH_DURATION := 0.20
const DASH_COOLDOWN := 0.3
const SHOOT_COOLDOWN := 0.20
const ATTACK_DURATION := 0.20
const MUZZLE_OFFSET := Vector2(14, -8)

const KNOCKBACK_SPEED := Vector2(200.0, 100.0)
const HURT_DURATION := 0.25
const INVULNERABILITY_TIME := 1.5
const BLINK_INTERVAL := 0.1
const HIT_FLASH_TIME := 0.2

@export var has_book_and_wand := true
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_element: Element.Type:
	get:
		return Element.Type.NONE if RunState.slots.is_empty() else RunState.slots[RunState.active_slot]

var max_health := BASE_HEALTH
var health := 0
var state := State.NORMAL
var state_time_left := 0.0
var direction_x := 0.0
var facing := 1.0

var max_jumps := 1
var jumps_left := 0
var is_jumping := false
var fall_time := 0.0
var coyote_time_left := 0.0
var jump_buffer_left := 0.0

var max_dashes := 1
var dashes_left := 0
var dash_allows_jump := false
var dash_cooldown_left := 0.0
var shoot_cooldown_left := 0.0
var invulnerable_left := 0.0
var flash_material: ShaderMaterial
var flash_tween: Tween


func _ready() -> void:
	max_health = BASE_HEALTH + RunState.health_bonus
	health = max_health
	health_changed.emit(health, max_health)
	RunState.changed.connect(_apply_book_upgrades)
	_apply_book_upgrades()
	setup_hit_flash()


func _apply_book_upgrades() -> void:
	max_jumps = 2 if RunState.double_jump else 1
	var new_max := BASE_HEALTH + RunState.health_bonus
	if new_max != max_health:
		health = clampi(health + new_max - max_health, 0, new_max)
		max_health = new_max
		health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	update_timers(delta)
	update_ground_state()
	read_input()

	match state:
		State.NORMAL, State.ATTACK:
			apply_horizontal_movement()
			apply_gravity(delta)
		State.DASH:
			apply_dash()
		State.DEAD, State.HURT:
			apply_gravity(delta)

	move_and_slide()
	update_animation()
# --- Ввод ---

func read_input() -> void:
	direction_x = Input.get_axis("left", "right")
	if direction_x != 0.0:
		facing = signf(direction_x)

	if Input.is_action_just_pressed("dash") and can_dash():
		start_dash()

	if Input.is_action_just_pressed("shoot") and can_shoot():
		shoot()
	if Input.is_action_just_pressed("change") and has_book_and_wand and state != State.DEAD:
		switch_element()

	# Запоминаем нажатие, чтобы прыжок сработал, даже если нажали чуть раньше приземления
	if Input.is_action_just_pressed("jump"):
		jump_buffer_left = JUMP_BUFFER_TIME

	if jump_buffer_left > 0.0 and can_jump():
		jump()
		# Если кнопку уже отпустили, пока прыжок ждал в буфере, делаем короткий прыжок
		if not Input.is_action_pressed("jump"):
			cut_jump()

	if Input.is_action_just_released("jump"):
		cut_jump()


# --- Здоровье ---

func take_damage(amount: int, source_position := Vector2.INF) -> void:
	if state == State.DEAD or invulnerable_left > 0.0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		die()
		return

	invulnerable_left = INVULNERABILITY_TIME
	start_hurt(source_position)
	play_hit_flash()


func heal(amount: int) -> void:
	if state == State.DEAD:
		return
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)


func die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	if health != 0:
		health = 0
		health_changed.emit(health, max_health)
	velocity.x = 0.0
	invulnerable_left = 0.0
	sprite.visible = true   # на случай, если умерли в момент "невидимого" кадра мигания
	died.emit()


# --- Эффекты получения урона ---

func start_hurt(source_position: Vector2) -> void:
	# Откидываем от источника урона. Если позицию не передали, откидываем назад
	var dir := -facing
	if source_position.is_finite():
		var diff := global_position.x - source_position.x
		if diff != 0.0:
			dir = signf(diff)

	state = State.HURT
	state_time_left = HURT_DURATION
	velocity = Vector2(dir * KNOCKBACK_SPEED.x, -KNOCKBACK_SPEED.y)
	is_jumping = false
	fall_time = 0.0


func setup_hit_flash() -> void:
	flash_material = ShaderMaterial.new()
	flash_material.shader = HIT_FLASH_SHADER
	flash_material.set_shader_parameter("flash_amount", 0.0)
	sprite.material = flash_material


func play_hit_flash() -> void:
	if flash_tween:
		flash_tween.kill()
	flash_material.set_shader_parameter("flash_amount", 1.0)
	flash_tween = create_tween()
	flash_tween.tween_property(flash_material, "shader_parameter/flash_amount", 0.0, HIT_FLASH_TIME)


func update_invulnerability(delta: float) -> void:
	if invulnerable_left <= 0.0:
		return
	invulnerable_left -= delta
	if invulnerable_left <= 0.0:
		sprite.visible = true
	else:
		# Чётные интервалы спрайт виден, нечётные скрыт
		sprite.visible = int(invulnerable_left / BLINK_INTERVAL) % 2 == 0


# --- Анимации ---

func update_animation() -> void:
	update_sprite_flip()
	play_animation(get_animation_name())


func get_animation_name() -> String:
	if state == State.HURT:
		return "jump" if not is_on_floor() else "idle"
	if state == State.DASH:
		return "dash"
	if state == State.ATTACK:
		return "attack"
	if not is_on_floor():
		return "jump"
	if direction_x != 0.0:
		return "left"
	return "idle"


func update_sprite_flip() -> void:
	var facing_right := facing > 0.0
	sprite.flip_h = facing_right if SPRITE_FACES_LEFT else not facing_right


func play_animation(anim_name: String) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)

# --- Проверки ---

func can_jump() -> bool:
	if jumps_left <= 0:
		return false
	return state == State.NORMAL or (state == State.DASH and dash_allows_jump) or state == State.ATTACK


func can_dash() -> bool:
	return state == State.NORMAL and dashes_left > 0 and dash_cooldown_left <= 0.0

func can_shoot() -> bool:
	return has_book_and_wand and current_element != Element.Type.NONE and state == State.NORMAL and shoot_cooldown_left <= 0.0


# --- Движение ---

func apply_horizontal_movement() -> void:
	velocity.x = direction_x * SPEED * (1.0 + 0.1 * RunState.speed_steps)


func apply_gravity(delta: float) -> void:
	var gravity := GRAVITY

	if velocity.y > 0.0:
		fall_time += delta
		if fall_time >= FALL_GRAVITY_DELAY:
			gravity *= FALL_GRAVITY_MULTIPLIER
	else:
		fall_time = 0.0

	velocity.y += gravity * delta
	velocity.y = minf(velocity.y, MAX_FALL_SPEED)


# --- Атака ---
func shoot() -> void:
	state = State.ATTACK
	state_time_left = ATTACK_DURATION
	shoot_cooldown_left = SHOOT_COOLDOWN

	var shot := PROJECTILE_SCENE.instantiate() as projectile
	shot.damage += RunState.damage_bonus
	shot.lifetime *= 1.0 + 0.25 * RunState.range_steps
	# Добавляем в сцену, а не к игроку, иначе снаряд будет двигаться вместе с ним
	get_tree().current_scene.add_child(shot)

	var spawn_pos := global_position + Vector2(MUZZLE_OFFSET.x * facing, MUZZLE_OFFSET.y)
	shot.launch(spawn_pos, Vector2(facing, 0.0), self, current_element)


# --- Палочка ---

func switch_element() -> void:
	RunState.switch_element()
	element_changed.emit(current_element)


# --- Прыжок ---

func jump() -> void:
	if state == State.DASH:
		end_dash()
	velocity.y = -JUMP_STRENGTH
	jumps_left -= 1
	is_jumping = true
	jump_buffer_left = 0.0
	coyote_time_left = 0.0


func cut_jump() -> void:
	if is_jumping and velocity.y < 0.0:
		velocity.y *= JUMP_CUT
	is_jumping = false


# --- Рывок ---

func start_dash() -> void:
	state = State.DASH
	dashes_left -= 1
	state_time_left = DASH_DURATION
	dash_cooldown_left = DASH_COOLDOWN
	dash_allows_jump = coyote_time_left > 0.0
	is_jumping = false
	fall_time = 0.0


func apply_dash() -> void:
	velocity.x = facing * DASH_SPEED
	velocity.y = 0.0


func end_dash() -> void:
	state = State.NORMAL


# --- Таймеры и восстановление ---

func update_timers(delta: float) -> void:
	dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)
	coyote_time_left = maxf(coyote_time_left - delta, 0.0)
	jump_buffer_left = maxf(jump_buffer_left - delta, 0.0)
	shoot_cooldown_left = maxf(shoot_cooldown_left - delta, 0.0)

	if state in [State.DASH, State.HURT, State.ATTACK]:
		state_time_left -= delta
		if state_time_left <= 0.0:
			state = State.NORMAL

	update_invulnerability(delta)


func update_ground_state() -> void:
	if is_on_floor():
		jumps_left = max_jumps
		dashes_left = max_dashes
		is_jumping = false
		fall_time = 0.0
		coyote_time_left = COYOTE_TIME
	else:
		# Сошли с края и окно койота закончилось: «наземный» прыжок потерян
		if coyote_time_left <= 0.0 and jumps_left >= max_jumps:
			jumps_left = max_jumps - 1
		if velocity.y >= 0.0:
			is_jumping = false
