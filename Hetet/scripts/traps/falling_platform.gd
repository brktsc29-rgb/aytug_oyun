extends AnimatableBody2D

## Falling platform — shakes briefly after a player lands on it, then drops away.
##
## Expected scene layout:
##   FallingPlatform (AnimatableBody2D)
##     ├─ CollisionShape2D
##     ├─ Visual (ColorRect)
##     └─ StandArea (Area2D) — thin horizontal strip covering the top surface,
##                              used to detect when a player is standing on top.

@export var fall_delay := 0.8     ## Seconds of shaking before the platform falls
@export var shake_amount := 3.0   ## Peak horizontal shake offset in pixels

var _triggered := false
var _falling := false
var _shake_elapsed := 0.0
var _origin: Vector2


func _ready() -> void:
	_origin = global_position
	var area: Area2D = $StandArea
	area.body_entered.connect(_on_stand_area_body_entered)


func _process(delta: float) -> void:
	if not _triggered or _falling:
		return

	# Sinusoidal horizontal shake to give the player a visual warning
	_shake_elapsed += delta
	global_position.x = _origin.x + shake_amount * sin(_shake_elapsed * 20.0)


## Triggered when any body enters the detection area on top of the platform.
func _on_stand_area_body_entered(body: Node2D) -> void:
	if body is Player and not _triggered:
		_triggered = true
		_origin = global_position  # capture current world position as shake origin

		var timer: SceneTreeTimer = get_tree().create_timer(fall_delay)
		timer.timeout.connect(_begin_fall)


## Snaps the shake back to centre then starts the fall tween.
func _begin_fall() -> void:
	_falling = true
	global_position.x = _origin.x  # remove any residual shake offset

	var tw: Tween = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "global_position",
			global_position + Vector2(0.0, 2000.0), 0.9)
	tw.tween_callback(queue_free)
