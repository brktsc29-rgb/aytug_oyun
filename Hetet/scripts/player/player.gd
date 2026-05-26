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
@export var speed: float       = 350.0
@export var jump_force: float  = -720.0
@export var gravity: float     = 1800.0
@export var max_jumps: int     = 2

# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------
@onready var coyote_timer: Timer      = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer

var anim: AnimationPlayer = null

# ---------------------------------------------------------------------------
# Visual nodes (built in _build_visual)
# ---------------------------------------------------------------------------
var _visual: Node2D      = null
var _body_poly: Polygon2D = null

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var jump_count: int         = 0
var is_coyote_active: bool  = false
var is_jump_buffered: bool  = false
var checkpoint_position: Vector2 = Vector2.ZERO
var is_dead: bool           = false
var _was_on_floor: bool     = false

const _GRAVITY_CAP: float        = 1200.0
const _DEATH_PLANE_Y: float      = 2500.0
const _COYOTE_DURATION: float    = 0.12
const _JUMP_BUFFER_DURATION: float = 0.15

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	GameManager.active_player = self

	_visual = $Visual
	_build_visual()

	var saved_cp: Vector2 = SaveSystem.get_checkpoint()
	if saved_cp != Vector2.ZERO:
		checkpoint_position = saved_cp

	apply_skin(SaveSystem.get_equipped_skin())

	if has_node("AnimationPlayer"):
		anim = $AnimationPlayer

	coyote_timer.timeout.connect(_on_coyote_timer_timeout)
	jump_buffer_timer.timeout.connect(_on_jump_buffer_timer_timeout)

# ---------------------------------------------------------------------------
# Visual construction — builds a blocky adventurer from Polygon2D parts
# Coordinate reference: y=0 is player origin, feet at y=+28, head near y=-28
# ---------------------------------------------------------------------------
func _build_visual() -> void:
	# Hat top
	var hat := Polygon2D.new()
	hat.polygon = PackedVector2Array([
		Vector2(-9, -50), Vector2(9, -50),
		Vector2(11, -38), Vector2(-11, -38)
	])
	hat.color = Color(0.14, 0.07, 0.03)
	_visual.add_child(hat)

	# Hat brim
	var brim := Polygon2D.new()
	brim.polygon = PackedVector2Array([
		Vector2(-16, -41), Vector2(16, -41),
		Vector2(16, -37), Vector2(-16, -37)
	])
	brim.color = Color(0.20, 0.11, 0.04)
	_visual.add_child(brim)

	# Head
	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(-11, -37), Vector2(11, -37),
		Vector2(13, -22), Vector2(-13, -22)
	])
	head.color = Color(0.97, 0.82, 0.62)
	_visual.add_child(head)

	# Left eye
	var eye_l := Polygon2D.new()
	eye_l.polygon = PackedVector2Array([
		Vector2(-9, -33), Vector2(-3, -33),
		Vector2(-3, -27), Vector2(-9, -27)
	])
	eye_l.color = Color(0.10, 0.06, 0.22)
	_visual.add_child(eye_l)

	# Right eye
	var eye_r := Polygon2D.new()
	eye_r.polygon = PackedVector2Array([
		Vector2(3, -33), Vector2(9, -33),
		Vector2(9, -27), Vector2(3, -27)
	])
	eye_r.color = Color(0.10, 0.06, 0.22)
	_visual.add_child(eye_r)

	# Body (coloured by skin)
	_body_poly = Polygon2D.new()
	_body_poly.polygon = PackedVector2Array([
		Vector2(-13, -22), Vector2(13, -22),
		Vector2(14, 13),   Vector2(-14, 13)
	])
	_body_poly.color = Color(0.2, 0.5, 1.0)
	_visual.add_child(_body_poly)

	# Left leg
	var leg_l := Polygon2D.new()
	leg_l.polygon = PackedVector2Array([
		Vector2(-13, 13), Vector2(-3, 13),
		Vector2(-3, 28),  Vector2(-13, 28)
	])
	leg_l.color = Color(0.15, 0.22, 0.48)
	_visual.add_child(leg_l)

	# Right leg
	var leg_r := Polygon2D.new()
	leg_r.polygon = PackedVector2Array([
		Vector2(3, 13),  Vector2(13, 13),
		Vector2(13, 28), Vector2(3, 28)
	])
	leg_r.color = Color(0.15, 0.22, 0.48)
	_visual.add_child(leg_r)

# ---------------------------------------------------------------------------
# Physics
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, _GRAVITY_CAP)

	var on_floor_now: bool = is_on_floor()

	if on_floor_now:
		jump_count = 0
		is_coyote_active = false
		coyote_timer.stop()

		if is_jump_buffered:
			is_jump_buffered = false
			jump_buffer_timer.stop()
			_perform_jump()
	else:
		if _was_on_floor and not is_coyote_active:
			is_coyote_active = true
			coyote_timer.start(_COYOTE_DURATION)

	_was_on_floor = on_floor_now

	var dir: float = Input.get_axis("move_left", "move_right")
	velocity.x = dir * speed

	if is_instance_valid(_visual) and dir != 0.0:
		_visual.scale.x = -1.0 if dir < 0.0 else 1.0

	_update_animation(on_floor_now, dir)

	if Input.is_action_just_pressed("jump"):
		var can_jump: bool = on_floor_now or is_coyote_active or jump_count < max_jumps
		if can_jump:
			_perform_jump()
		else:
			is_jump_buffered = true
			jump_buffer_timer.start(_JUMP_BUFFER_DURATION)

	move_and_slide()

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

	if was_double and is_instance_valid(_visual):
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_visual, "scale", Vector2(1.4, 0.6), 0.07)
		tween.tween_property(_visual, "scale", Vector2(1.0, 1.0), 0.18)

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

	if is_instance_valid(_visual):
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(_visual, "modulate", Color(1.0, 0.0, 0.0, 0.0), 0.5)
		tween.tween_property(_visual, "scale", Vector2(1.5, 1.5), 0.5)
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

	if is_instance_valid(_visual):
		_visual.scale = Vector2.ONE
		apply_skin(SaveSystem.get_equipped_skin())
		_visual.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(_visual, "modulate:a", 1.0, 0.3)

# ---------------------------------------------------------------------------
# Skin
# ---------------------------------------------------------------------------
func apply_skin(skin_id: String) -> void:
	if is_instance_valid(_body_poly):
		_body_poly.color = ShopSystem.get_skin_color(skin_id)

# ---------------------------------------------------------------------------
# Damage
# ---------------------------------------------------------------------------
func take_damage() -> void:
	die()
