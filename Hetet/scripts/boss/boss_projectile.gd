extends Area2D

## Boss projectile — moves in a fixed direction and kills the player on contact.
## Frees itself automatically when it leaves the playable area.
##
## Expected scene layout (or built programmatically by FinalBoss):
##   BossProjectile (Area2D)    ← this script
##     ├─ CollisionShape2D      ← RectangleShape2D 24×24
##     └─ Visual (ColorRect)    ← 24×24 red/orange square

@export var speed := 400.0               ## Pixels per second
@export var direction := Vector2.RIGHT   ## Unit vector; set before adding to tree

## Out-of-bounds limit — free the node when it travels this far from origin
const BOUNDS_LIMIT := 3000.0

@onready var _visual: ColorRect = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# Ensure the visual looks like a fiery projectile
	if _visual != null:
		_visual.color = Color(1.0, 0.35, 0.05)
		_visual.size  = Vector2(24.0, 24.0)
		_visual.position = Vector2(-12.0, -12.0)  # centred


func _physics_process(delta: float) -> void:
	position += direction.normalized() * speed * delta

	# Cull once the projectile is far enough from the scene origin
	if absf(position.x) > BOUNDS_LIMIT or absf(position.y) > BOUNDS_LIMIT:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.die()
		queue_free()
