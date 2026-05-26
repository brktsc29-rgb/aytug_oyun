extends CanvasLayer

# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------
@onready var left_btn: Button = $Controls/LeftSide/LeftBtn
@onready var right_btn: Button = $Controls/LeftSide/RightBtn
@onready var jump_btn: Button = $Controls/JumpBtn

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	layer = 20

	# ---- Left button ----
	left_btn.button_down.connect(_on_left_btn_down)
	left_btn.button_up.connect(_on_left_btn_up)

	# ---- Right button ----
	right_btn.button_down.connect(_on_right_btn_down)
	right_btn.button_up.connect(_on_right_btn_up)

	# ---- Jump button ----
	jump_btn.button_down.connect(_on_jump_btn_down)
	jump_btn.button_up.connect(_on_jump_btn_up)

	# Mobile controls must always process so they still function on the pause
	# overlay and during any cutscene state.
	process_mode = Node.PROCESS_MODE_ALWAYS

# ---------------------------------------------------------------------------
# Internal button callbacks → translate to InputMap actions
# ---------------------------------------------------------------------------
func _on_left_btn_down() -> void:
	Input.action_press("move_left")

func _on_left_btn_up() -> void:
	Input.action_release("move_left")

func _on_right_btn_down() -> void:
	Input.action_press("move_right")

func _on_right_btn_up() -> void:
	Input.action_release("move_right")

func _on_jump_btn_down() -> void:
	Input.action_press("jump")

func _on_jump_btn_up() -> void:
	Input.action_release("jump")

# ---------------------------------------------------------------------------
# Public API — for external control (cutscenes, tutorials, etc.)
# ---------------------------------------------------------------------------
func press_left(pressed: bool) -> void:
	if pressed:
		Input.action_press("move_left")
	else:
		Input.action_release("move_left")

func press_right(pressed: bool) -> void:
	if pressed:
		Input.action_press("move_right")
	else:
		Input.action_release("move_right")

func press_jump(pressed: bool) -> void:
	if pressed:
		Input.action_press("jump")
	else:
		Input.action_release("jump")
