extends CharacterBody2D

## MALAKOR — Final boss.
## Three-phase fight: each phase transition increases speed and fire rate.
## HP bar is built programmatically above the boss sprite.
##
## Expected scene layout:
##   FinalBoss (CharacterBody2D)   ← this script
##     ├─ CollisionShape2D
##     └─ Sprite (ColorRect)       ← placeholder boss visual

signal defeated

@export var max_hp := 15
@export var speed := 120.0
@export var jump_force := -600.0
@export var gravity := 1200.0

const PROJECTILE_SCENE := preload("res://scenes/boss/BossProjectile.tscn")

## Phase thresholds (fraction of max_hp)
const PHASE2_THRESHOLD := 0.66
const PHASE3_THRESHOLD := 0.33

## Attack intervals per phase (seconds between shots)
const ATTACK_INTERVALS := [2.0, 1.5, 1.0]

## HP-bar layout constants
const BAR_WIDTH  := 220.0
const BAR_HEIGHT := 18.0
const BAR_OFFSET := Vector2(-110.0, -80.0)  ## Position relative to boss

var hp: int
var phase: int

var _attack_timer := 0.0
var _move_timer   := 0.0
var _direction    := 1  # 1 = right, -1 = left
var _jump_cooldown := 0.0

# HP-bar UI nodes (built in _ready)
var _hp_bar_root: Control
var _hp_label: Label
var _hp_bg: ColorRect
var _hp_fill: ColorRect


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	hp    = max_hp
	phase = 1

	_build_hp_bar()
	_update_hp_bar()

	VillainDialog.show_dialog("boss_phase_1")


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_movement(delta)
	_handle_attacks(delta)
	move_and_slide()

	_hp_bar_root.global_position = global_position + BAR_OFFSET


# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func _handle_movement(delta: float) -> void:
	_move_timer += delta

	# Bounce off walls
	if is_on_wall():
		_direction *= -1

	velocity.x = speed * float(_direction)

	# Occasional jump (every 2-4 seconds)
	_jump_cooldown -= delta
	if is_on_floor() and _jump_cooldown <= 0.0:
		velocity.y = jump_force
		_jump_cooldown = randf_range(2.0, 4.0)


# ---------------------------------------------------------------------------
# Attacks
# ---------------------------------------------------------------------------

func _handle_attacks(delta: float) -> void:
	_attack_timer += delta
	var interval := ATTACK_INTERVALS[phase - 1]
	if _attack_timer >= interval:
		_attack_timer = 0.0
		_fire_projectile()


## Instantiates a projectile aimed at the active player.
func _fire_projectile() -> void:
	var proj: Area2D = PROJECTILE_SCENE.instantiate()

	# Aim towards the player if available, otherwise fire sideways
	var fire_dir := Vector2(float(_direction), 0.0)
	var player: Node2D = GameManager.active_player
	if player != null:
		var diff := player.global_position - global_position
		fire_dir = diff.normalized()

	proj.direction = fire_dir
	proj.global_position = global_position

	# Add to the scene root so it isn't affected by this node's transforms
	get_tree().current_scene.add_child(proj)


# ---------------------------------------------------------------------------
# Damage & phase transitions
# ---------------------------------------------------------------------------

func take_damage(amount: int) -> void:
	if hp <= 0:
		return

	hp = max(hp - amount, 0)
	_update_hp_bar()

	# Flash the boss sprite red to indicate a hit
	var sprite := get_node_or_null("Sprite") as ColorRect
	if sprite != null:
		var tw: Tween = create_tween()
		tw.tween_property(sprite, "color", Color(1.0, 0.2, 0.2), 0.05)
		tw.tween_property(sprite, "color", Color(0.6, 0.1, 0.8), 0.1)

	# Phase 2
	if hp <= int(max_hp * PHASE2_THRESHOLD) and phase == 1:
		phase = 2
		speed += 40.0
		VillainDialog.show_dialog("boss_phase_2")
		_flash_phase_transition()

	# Phase 3
	if hp <= int(max_hp * PHASE3_THRESHOLD) and phase == 2:
		phase = 3
		speed += 40.0
		VillainDialog.show_dialog("boss_phase_3")
		_flash_phase_transition()

	if hp <= 0:
		_die()


func _flash_phase_transition() -> void:
	var tw: Tween = create_tween().set_loops(3)
	tw.tween_property(self, "modulate", Color(2.0, 2.0, 2.0), 0.1)
	tw.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.1)


func _die() -> void:
	set_physics_process(false)

	VillainDialog.show_dialog("boss_defeated")
	defeated.emit()

	var tw: Tween = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.55)
	tw.tween_callback(queue_free)


# ---------------------------------------------------------------------------
# HP bar
# ---------------------------------------------------------------------------

## Builds a floating HP bar above the boss using pure GDScript-created nodes.
func _build_hp_bar() -> void:
	_hp_bar_root = Control.new()
	_hp_bar_root.z_index = 10
	get_tree().current_scene.add_child(_hp_bar_root)

	# Boss name label
	_hp_label = Label.new()
	_hp_label.text = "MALAKOR"
	_hp_label.add_theme_color_override("font_color", Color(1.0, 0.9, 1.0))
	_hp_label.position = Vector2(0.0, -22.0)
	_hp_bar_root.add_child(_hp_label)

	# Background bar (dark)
	_hp_bg = ColorRect.new()
	_hp_bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_hp_bg.position = Vector2(0.0, 0.0)
	_hp_bg.color = Color(0.12, 0.12, 0.12)
	_hp_bar_root.add_child(_hp_bg)

	# Fill bar (red)
	_hp_fill = ColorRect.new()
	_hp_fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_hp_fill.position = Vector2(0.0, 0.0)
	_hp_fill.color = Color(0.85, 0.1, 0.1)
	_hp_bar_root.add_child(_hp_fill)


## Updates the fill bar width to reflect the current hp fraction.
func _update_hp_bar() -> void:
	if _hp_fill == null:
		return
	_hp_fill.size.x = _get_hp_bar_width()


## Returns the pixel width the fill bar should currently have.
func _get_hp_bar_width() -> float:
	return (float(hp) / float(max_hp)) * BAR_WIDTH
