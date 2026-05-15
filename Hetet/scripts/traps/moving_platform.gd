extends AnimatableBody2D
@export var move_offset := Vector2(250, 0)
@export var move_time := 1.8
var start_pos := Vector2.ZERO
var tween: Tween

func _ready() -> void:
	start_pos = global_position
	tween = create_tween().set_loops()
	tween.tween_property(self, "global_position", start_pos + move_offset, move_time)
	tween.tween_property(self, "global_position", start_pos, move_time)
