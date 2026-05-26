extends Node2D

## Timed laser — cycles between an active (lethal) and inactive state every frame.
##
## Expected scene layout:
##   TimedLaser (Node2D)              ← this script
##     ├─ LaserArea (Area2D)          ← collision area for the beam
##     │    └─ CollisionShape2D
##     └─ LaserVisual (ColorRect)     ← visual red bar representing the beam

@export var on_time := 2.0    ## Seconds the laser stays active / lethal
@export var off_time := 1.5   ## Seconds the laser stays inactive / safe

const COLOR_ACTIVE   := Color(1.0,  0.10, 0.10, 1.0)  ## Bright red — on
const COLOR_INACTIVE := Color(0.22, 0.22, 0.22, 1.0)  ## Dark grey — off

var _is_on := true
var _timer := 0.0

@onready var _laser_area: Area2D = $LaserArea
@onready var _visual: ColorRect  = $LaserVisual


func _ready() -> void:
	_is_on = true
	_timer = 0.0
	_apply_state()


func _process(delta: float) -> void:
	_timer += delta

	# Toggle state when the current phase duration has elapsed
	var phase_duration := on_time if _is_on else off_time
	if _timer >= phase_duration:
		_timer -= phase_duration
		_is_on = !_is_on
		_apply_state()

	# Kill any player inside the beam while the laser is active
	if _is_on:
		for body in _laser_area.get_overlapping_bodies():
			if body is Player:
				body.die()
				break  # One kill event per frame is enough


## Applies colour and monitoring state to match the current on/off phase.
func _apply_state() -> void:
	_laser_area.monitoring = _is_on
	_visual.color = COLOR_ACTIVE if _is_on else COLOR_INACTIVE
