class_name Player
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal coin_collected(total: int)
signal player_died
signal checkpoint_set(pos: Vector2)

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
@export var speed: float = 350.0
@export var jump_force: float = -720.0
@export var gravity: float = 1800.0
@export var max_jumps: int = 2

# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------
@onready var sprite: Sprite2D = $Sprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer

# AnimationPlayer is optional — some scene setups may omit it.
var anim: AnimationPlayer = null

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var jump_count: int = 0
var is_coyote_active: bool = false
var is_jump_buffered: bool = false
var checkpoint_position: Vector2 = Vector2.ZERO
var is_dead: bool = false
var _was_on_floor: bool = false

const _GRAVITY_CAP: float = 1200.0
const _DEATH_PLANE_Y: float = 2500.0
const _COYOTE_DURATION: float = 0.12
const _JUMP_BUFFER_DURATION: float = 0.15

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	GameManager.active_player = self

	# Restore saved checkpoint
	var saved_cp: Vector2 = SaveSystem.get_checkpoint()
	if saved_cp != Vector2.ZERO:
		checkpoint_position = saved_cp

	# Apply stored skin
	apply_skin(SaveSystem.get_equipped_skin())

	# Optional AnimationPlayer
	if has_node("AnimationPlayer"):
		anim = $AnimationPlayer

	# Timer connections
	coyote_timer.timeout.connect(_on_coyote_timer_timeout)
	jump_buffer_timer.timeout.connect(_on_jump_buffer_timer_timeout)

# ---------------------------------------------------------------------------
# Physics
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# --- Gravity (capped to prevent tunnelling) ---
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, _GRAVITY_CAP)

	# --- Floor state management ---
	var on_floor_now: bool = is_on_floor()

	if on_floor_now:
		jump_count = 0
		is_coyote_active = false
		coyote_timer.stop()

		# Consume buffered jump immediately on landing
		if is_jump_buffered:
			is_jump_buffered = false
			jump_buffer_timer.stop()
			_perform_jump()
	else:
		# Just left the ground → open coyote window
		if _was_on_floor and not is_coyote_active:
			is_coyote_active = true
			coyote_timer.start(_COYOTE_DURATION)

	_was_on_floor = on_floor_now

	# --- Horizontal movement ---
	var dir: float = Input.get_axis("move_left", "move_right")
	velocity.x = dir * speed

	if is_instance_valid(sprite) and dir != 0.0:
		sprite.flip_h = dir < 0.0

	# --- Animations ---
	_update_animation(on_floor_now, dir)

	# --- Jump input ---
	if Input.is_action_just_pressed("jump"):
		var can_jump: bool = on_floor_now or is_coyote_active or jump_count < max_jumps
		if can_jump:
			_perform_jump()
		else:
			is_jump_buffered = true
			jump_buffer_timer.start(_JUMP_BUFFER_DURATION)

	move_and_slide()

	# --- Death plane ---
	if global_position.y > _DEATH_PLANE_Y:
		die()

# ---------------------------------------------------------------------------
# Animation helper
# ---------------------------------------------------------------------------
func _update_animation(on_floor: bool, dir: float) -> void:
	if anim == null:
		return
	if not on_floor:
		if velocity.y < 0.0:
			if anim.has_animation("jump"):
				anim.play("jump")
		else:
			if anim.has_animation("fall"):
				anim.play("fall")
	elif absf(dir) > 0.01:
		if anim.has_animation("run"):
			anim.play("run")
	else:
		if anim.has_animation("idle"):
			anim.play("idle")

# ---------------------------------------------------------------------------
# Jump
# ---------------------------------------------------------------------------
func _perform_jump() -> void:
	var was_double: bool = jump_count >= 1

	velocity.y = jump_force
	jump_count += 1
	is_coyote_active = false
	coyote_timer.stop()
	is_jump_buffered = false
	jump_buffer_timer.stop()

	# SFX — audio nodes not wired yet
	# AudioManager.play_sfx("jump")

	# Double-jump visual: quick squash-and-stretch on the sprite
	if was_double and is_instance_valid(sprite):
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "scale", Vector2(1.4, 0.6), 0.07)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.18)

# ---------------------------------------------------------------------------
# Timer callbacks
# ---------------------------------------------------------------------------
func _on_coyote_timer_timeout() -> void:
	is_coyote_active = false

func _on_jump_buffer_timer_timeout() -> void:
	is_jump_buffered = false

# ---------------------------------------------------------------------------
# Coins
# ---------------------------------------------------------------------------
func collect_coin(amount: int = 1) -> void:
	GameManager.add_coins(amount)
	coin_collected.emit(GameManager.get_coins())
	# AudioManager.play_sfx("coin")

# ---------------------------------------------------------------------------
# Checkpoint
# ---------------------------------------------------------------------------
func set_checkpoint(pos: Vector2) -> void:
	checkpoint_position = pos
	SaveSystem.set_checkpoint(pos)
	checkpoint_set.emit(pos)
	VillainDialog.show_dialog("checkpoint")

# ---------------------------------------------------------------------------
# Death & respawn
# ---------------------------------------------------------------------------
func die() -> void:
	if is_dead:
		return
	is_dead = true

	SaveSystem.record_death()
	player_died.emit()

	if is_instance_valid(sprite):
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "modulate", Color(1.0, 0.0, 0.0, 0.0), 0.5)
		tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.5)
		tween.set_parallel(false)
		tween.tween_callback(_respawn)
	else:
		_respawn()

func _respawn() -> void:
	var respawn_pos: Vector2 = checkpoint_position if checkpoint_position != Vector2.ZERO \
		else Vector2(100.0, -100.0)
	global_position = respawn_pos
	velocity = Vector2.ZERO
	jump_count = 0
	is_coyote_active = false
	is_jump_buffered = false
	is_dead = false

	if is_instance_valid(sprite):
		sprite.scale = Vector2.ONE
		apply_skin(SaveSystem.get_equipped_skin())
		sprite.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.3)

# ---------------------------------------------------------------------------
# Skin
# ---------------------------------------------------------------------------
func apply_skin(skin_id: String) -> void:
	if is_instance_valid(sprite):
		sprite.modulate = ShopSystem.get_skin_color(skin_id)

# ---------------------------------------------------------------------------
# Damage
# ---------------------------------------------------------------------------
func take_damage() -> void:
	die()
