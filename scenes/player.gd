extends CharacterBody2D

enum State { NORMAL, DASH }
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
# --- Константы движения ---
const SPEED := 200.0
const JUMP_STRENGTH := 400.0
const JUMP_CUT := 0.4                # во сколько раз гасится подъём при отпускании кнопки
const GRAVITY := 700.0
const FALL_GRAVITY_MULTIPLIER := 1.6 # усиление гравитации при падении
const FALL_GRAVITY_DELAY := 0.15     # сколько секунд падения до усиления, сек
const MAX_FALL_SPEED := 500.0        # предел скорости падения, пикс/сек
const SPRITE_FACES_LEFT := false      # если игрок повернут направо спрайты зеркалят
var dash_allows_jump := false   # можно ли прервать текущий рывок прыжком

# --- Отзывчивость прыжка ---
const COYOTE_TIME := 0.1             # окно прыжка после схода с края, сек
const JUMP_BUFFER_TIME := 0.12       # запоминание нажатия прыжка до приземления, сек

# --- Константы рывка ---
const DASH_SPEED := 350.0
const DASH_DURATION := 0.20
const DASH_COOLDOWN := 0.3

# --- Лимиты (переменные, чтобы стихии могли их менять) ---
var max_jumps := 1
var max_dashes := 1

# --- Состояние ---
var state := State.NORMAL
var direction_x := 0.0
var facing := 1.0
var is_jumping := false

# --- Счётчики и таймеры ---
var jumps_left := 0
var dashes_left := 0
var dash_time_left := 0.0
var dash_cooldown_left := 0.0
var fall_time := 0.0
var coyote_time_left := 0.0
var jump_buffer_left := 0.0


func _physics_process(delta: float) -> void:
	update_timers(delta)
	update_ground_state()
	read_input()

	match state:
		State.NORMAL:
			apply_horizontal_movement()
			apply_gravity(delta)
		State.DASH:
			apply_dash()

	move_and_slide()
	update_animation()


# --- Ввод ---

func read_input() -> void:
	direction_x = Input.get_axis("left", "right")
	if direction_x != 0.0:
		facing = signf(direction_x)

	if Input.is_action_just_pressed("dash") and can_dash():
		start_dash()

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


# --- Анимации ---

func update_animation() -> void:
	update_sprite_flip()
	play_animation(get_animation_name())


func get_animation_name() -> String:
	if state == State.DASH:
		return "dash"
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
	return state == State.NORMAL or (state == State.DASH and dash_allows_jump)


func can_dash() -> bool:
	return state == State.NORMAL and dashes_left > 0 and dash_cooldown_left <= 0.0


# --- Движение ---

func apply_horizontal_movement() -> void:
	velocity.x = direction_x * SPEED


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
	dash_time_left = DASH_DURATION
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

	if state == State.DASH:
		dash_time_left -= delta
		if dash_time_left <= 0.0:
			end_dash()


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
