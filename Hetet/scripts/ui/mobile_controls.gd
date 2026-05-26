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
	process_mode = Node.PROCESS_MODE_ALWAYS

	_style_buttons()

	left_btn.button_down.connect(_on_left_btn_down)
	left_btn.button_up.connect(_on_left_btn_up)
	right_btn.button_down.connect(_on_right_btn_down)
	right_btn.button_up.connect(_on_right_btn_up)
	jump_btn.button_down.connect(_on_jump_btn_down)
	jump_btn.button_up.connect(_on_jump_btn_up)

# ---------------------------------------------------------------------------
# Visual styling
# ---------------------------------------------------------------------------
func _style_buttons() -> void:
	_apply_move_style(left_btn)
	_apply_move_style(right_btn)
	_apply_jump_style(jump_btn)

func _apply_move_style(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal",  _mk_btn_box(Color(0.08, 0.14, 0.38, 0.75), Color(0.45, 0.70, 1.00, 0.88), 95))
	btn.add_theme_stylebox_override("hover",   _mk_btn_box(Color(0.18, 0.28, 0.55, 0.85), Color(0.65, 0.85, 1.00, 1.00), 95))
	btn.add_theme_stylebox_override("pressed", _mk_btn_box(Color(0.04, 0.08, 0.22, 0.92), Color(0.30, 0.55, 0.85, 0.70), 95))
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 80)

func _apply_jump_style(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal",  _mk_btn_box(Color(0.04, 0.40, 0.12, 0.80), Color(0.28, 0.95, 0.48, 0.90), 100))
	btn.add_theme_stylebox_override("hover",   _mk_btn_box(Color(0.10, 0.58, 0.22, 0.88), Color(0.50, 1.00, 0.68, 1.00), 100))
	btn.add_theme_stylebox_override("pressed", _mk_btn_box(Color(0.02, 0.26, 0.08, 0.92), Color(0.20, 0.75, 0.36, 0.75), 100))
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 88)

func _mk_btn_box(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_bottom = 5
	s.border_width_top    = 5
	s.border_width_left   = 5
	s.border_width_right  = 5
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s

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
