extends AnimatableBody2D

## Moving platform that oscillates between its origin and origin + move_offset.
## Because this is an AnimatableBody2D, CharacterBody2D players standing on it
## are carried along correctly by the physics engine.

@export var move_offset := Vector2(300.0, 0.0)  ## Displacement from start position
@export var move_time := 2.0                     ## Seconds for one leg of the trip

var start_pos: Vector2


func _ready() -> void:
	start_pos = global_position
	_start_loop()


## Creates a looping tween that perpetually moves the platform back and forth.
func _start_loop() -> void:
	var tw: Tween = create_tween().set_loops()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "global_position", start_pos + move_offset, move_time)
	tw.tween_property(self, "global_position", start_pos, move_time)
