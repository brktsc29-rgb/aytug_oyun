extends CharacterBody2D
class_name Player

signal coin_collected(total: int)
signal player_died

@export var speed := 330.0
@export var jump_force := -680.0
@export var gravity := 1700.0
@export var max_jumps := 2

var jump_count := 0
var coins := 0
var checkpoint_position := Vector2.ZERO

func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = dir * speed
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jump_count = 0
	if Input.is_action_just_pressed("jump") and jump_count < max_jumps:
		velocity.y = jump_force
		jump_count += 1
	move_and_slide()

func collect_coin(amount := 1) -> void:
	coins += amount
	emit_signal("coin_collected", coins)

func set_checkpoint(pos: Vector2) -> void:
	checkpoint_position = pos
	SaveSystem.set_checkpoint(pos)

func die() -> void:
	emit_signal("player_died")
	global_position = checkpoint_position if checkpoint_position != Vector2.ZERO else global_position
	velocity = Vector2.ZERO
