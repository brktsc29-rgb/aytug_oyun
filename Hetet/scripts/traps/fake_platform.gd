extends StaticBody2D

## Fake platform — appears solid but dissolves a short time after the player lands.
## The player can step onto it and jump away before it vanishes.
##
## Expected scene layout:
##   FakePlatform (StaticBody2D)     ← this script
##     ├─ CollisionShape2D           ← the solid body; disabled just before queue_free
##     ├─ Visual (ColorRect)         ← platform sprite; fades out during vanish_delay
##     └─ TriggerArea (Area2D)       ← thin strip on top to detect landing

@export var vanish_delay := 0.3  ## Seconds between first contact and removal

var _triggered := false

@onready var _visual: ColorRect         = $Visual
@onready var _trigger_area: Area2D      = $TriggerArea
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_trigger_area.body_entered.connect(_on_trigger_area_body_entered)


func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body is Player and not _triggered:
		_triggered = true
		_begin_vanish()


## Fades the visual over vanish_delay, then disables collision and frees the node.
func _begin_vanish() -> void:
	var tw: Tween = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_visual, "modulate:a", 0.0, vanish_delay)
	tw.tween_callback(_remove)


func _remove() -> void:
	# Defer the disable so physics is not disrupted mid-step
	_collision.set_deferred("disabled", true)
	queue_free()
