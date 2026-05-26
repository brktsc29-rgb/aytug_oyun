extends Node2D

## Rotating obstacle with a lethal arm that kills the player on contact.
##
## Expected scene layout:
##   RotatingObstacle (Node2D)             ← this script
##     ├─ PivotVisual (ColorRect)          ← small square at centre (cosmetic)
##     └─ DangerArm (Area2D)              ← the spinning arm
##           ├─ ArmRect (ColorRect)        ← long bar visual (cosmetic)
##           └─ CollisionShape2D          ← hitbox at the end of the arm

@export var rotation_speed := 2.0  ## Radians per second (positive = clockwise)
@export var radius := 80.0         ## Distance from pivot to the arm Area2D centre


func _ready() -> void:
	var arm: Area2D = $DangerArm
	# Position the danger arm at the end of the "radius" so the pivot is at (0,0)
	arm.position = Vector2(radius, 0.0)
	arm.body_entered.connect(_on_arm_body_entered)


func _process(delta: float) -> void:
	# Rotate the entire node (and therefore all children) around the pivot
	rotate(rotation_speed * delta)


func _on_arm_body_entered(body: Node2D) -> void:
	if body is Player:
		body.die()
