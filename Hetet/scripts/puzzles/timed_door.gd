extends AnimatableBody2D

## Timed door — opens when on_activated() is called, closes after open_time seconds.
## Designed to be wired to a ButtonSwitch via target_node_path.
##
## Expected scene layout:
##   TimedDoor (AnimatableBody2D)   ← this script
##     ├─ CollisionShape2D          ← disabled while open
##     └─ Visual (ColorRect)        ← tall bar; colour changes to show open/closed state

signal door_opened
signal door_closed

@export var open_time := 4.0  ## Seconds the door stays open before closing

const COLOR_CLOSED := Color(0.35, 0.15, 0.55)  ## Dark purple
const COLOR_OPEN   := Color(0.25, 0.85, 0.45)  ## Bright green

var _is_open := false
var _close_timer: SceneTreeTimer = null

@onready var _visual: ColorRect          = $Visual
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_visual.color      = COLOR_CLOSED
	_collision.disabled = false


## External entry point — called by ButtonSwitch or any other activator.
func on_activated() -> void:
	if _is_open:
		# Refresh the auto-close timer if activated while already open
		if _close_timer != null and _close_timer.timeout.is_connected(_close_door):
			_close_timer.timeout.disconnect(_close_door)
		_schedule_close()
		return

	_open_door()


func _open_door() -> void:
	_is_open = true
	# Defer collision disable so the physics engine finishes the current step
	_collision.set_deferred("disabled", true)

	var tw: Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_visual, "color", COLOR_OPEN, 0.3)

	door_opened.emit()
	_schedule_close()


func _schedule_close() -> void:
	_close_timer = get_tree().create_timer(open_time)
	_close_timer.timeout.connect(_close_door)


func _close_door() -> void:
	_is_open = false
	_collision.set_deferred("disabled", false)

	var tw: Tween = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_visual, "color", COLOR_CLOSED, 0.3)

	door_closed.emit()
