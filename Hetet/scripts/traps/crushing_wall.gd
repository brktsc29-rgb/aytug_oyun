extends AnimatableBody2D

## Crushing wall — waits, slams forward to crush the player, then retracts.
##
## Expected scene layout:
##   CrushingWall (AnimatableBody2D)    ← this script
##     ├─ CollisionShape2D             ← solid wall body
##     └─ CrushArea (Area2D)           ← same-sized area for player detection

@export var crush_distance := 300.0  ## How far the wall moves forward (pixels)
@export var crush_time := 1.5        ## Seconds to complete the forward slam
@export var wait_time := 2.0         ## Seconds of rest between cycles

## Phases: 0 = waiting, 1 = crushing (moving forward), 2 = retracting
var start_pos: Vector2
var _target_pos: Vector2
var _phase := 0
var _timer := 0.0
var _tween: Tween

@onready var _crush_area: Area2D = $CrushArea


func _ready() -> void:
	start_pos = global_position
	_target_pos = start_pos + Vector2(crush_distance, 0.0)
	_phase = 0
	_timer = 0.0


func _process(delta: float) -> void:
	match _phase:
		0:  # Waiting — count down before the next slam
			_timer += delta
			if _timer >= wait_time:
				_timer = 0.0
				_begin_crush()

		1:  # Crushing — the tween handles movement; kill player on contact
			for body in _crush_area.get_overlapping_bodies():
				if body is Player:
					body.die()
					break

		2:  # Retracting — tween handles movement; nothing else to do
			pass


## Launches the forward crush tween and advances the phase.
func _begin_crush() -> void:
	_phase = 1
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(self, "global_position", _target_pos, crush_time)
	_tween.tween_callback(_begin_retract)


## Launches the retraction tween once the wall has fully extended.
func _begin_retract() -> void:
	_phase = 2
	var tw: Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "global_position", start_pos, crush_time * 1.5)
	tw.tween_callback(_return_to_wait)


## Resets to the waiting phase so the cycle repeats.
func _return_to_wait() -> void:
	_phase = 0
	_timer = 0.0
