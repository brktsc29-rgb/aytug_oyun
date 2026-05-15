extends CanvasLayer

func press_left(pressed: bool) -> void:
	Input.action_press("move_left") if pressed else Input.action_release("move_left")

func press_right(pressed: bool) -> void:
	Input.action_press("move_right") if pressed else Input.action_release("move_right")

func press_jump(pressed: bool) -> void:
	Input.action_press("jump") if pressed else Input.action_release("jump")
