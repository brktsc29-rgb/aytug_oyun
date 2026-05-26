extends Node2D

## Memory puzzle — shows a colour sequence, the player must repeat it by pressing
## matching Area2D buttons. Wrong input resets and the sequence is shown again.
##
## Expected scene layout:
##   MemoryPuzzle (Node2D)          ← this script
##     ├─ Btn0 (Area2D)             ← red button
##     ├─ Btn1 (Area2D)             ← green button
##     ├─ Btn2 (Area2D)             ← blue button
##     └─ Btn3 (Area2D)             ← yellow button
##
## Each button Area2D must have a ColorRect child named "BtnVisual".

signal puzzle_solved

@export var sequence_length := 4  ## Number of steps in the generated sequence

# Palette: one base colour per button index
const BUTTON_COLORS := [
	Color(0.9, 0.15, 0.15),  # 0 — red
	Color(0.15, 0.85, 0.25),  # 1 — green
	Color(0.15, 0.35, 1.0),   # 2 — blue
	Color(1.0, 0.85, 0.10),   # 3 — yellow
]
const FLASH_BRIGHTEN := 0.5   ## Alpha/brightness boost during a sequence flash
const FLASH_DURATION := 0.35  ## Seconds each button stays lit during playback
const FLASH_GAP      := 0.15  ## Seconds of darkness between flashes

var _sequence: Array[int] = []
var _player_input: Array[int] = []
var _showing := false
var _accepting_input := false

# Cached references populated in _ready
var _buttons: Array[Area2D] = []
var _visuals: Array[ColorRect] = []


func _ready() -> void:
	# Collect the four button Area2Ds
	for i in range(4):
		var btn: Area2D = get_node("Btn%d" % i) as Area2D
		if btn == null:
			push_error("MemoryPuzzle: child 'Btn%d' not found." % i)
			continue
		_buttons.append(btn)

		var vis: ColorRect = btn.get_node("BtnVisual") as ColorRect
		if vis == null:
			push_error("MemoryPuzzle: Btn%d has no 'BtnVisual' ColorRect child." % i)
		else:
			vis.color = BUTTON_COLORS[i]
			_visuals.append(vis)

		# Capture index by value so the lambda binds correctly
		var idx := i
		btn.body_entered.connect(func(body: Node2D) -> void:
			_on_button_pressed(body, idx)
		)

	_generate_sequence()
	# Brief delay before showing the sequence so the player can orient
	get_tree().create_timer(0.8).timeout.connect(show_sequence)


## Generates a new random sequence of the configured length.
func _generate_sequence() -> void:
	_sequence.clear()
	for _i in range(sequence_length):
		_sequence.append(randi() % 4)


## Animates the sequence by flashing each button in order.
func show_sequence() -> void:
	if _showing:
		return
	_showing = true
	_accepting_input = false
	_player_input.clear()

	# Chain tweens sequentially, one per sequence step
	var tw: Tween = create_tween()
	for step in _sequence:
		var vis: ColorRect = _visuals[step]
		var base_col: Color = BUTTON_COLORS[step]
		var bright_col := base_col.lightened(FLASH_BRIGHTEN)

		tw.tween_property(vis, "color", bright_col, FLASH_DURATION * 0.5)
		tw.tween_property(vis, "color", base_col,   FLASH_DURATION * 0.5)
		tw.tween_interval(FLASH_GAP)

	tw.tween_callback(func() -> void:
		_showing = false
		_accepting_input = true
	)


## Called when a player body enters one of the button areas.
func _on_button_pressed(body: Node2D, btn_index: int) -> void:
	if not (body is Player) or not _accepting_input or _showing:
		return

	_player_input.append(btn_index)
	_flash_button(btn_index)  # brief acknowledgment flash

	var step := _player_input.size() - 1

	# Check correctness so far
	if _player_input[step] != _sequence[step]:
		# Wrong input — reset and replay
		_accepting_input = false
		_player_input.clear()
		get_tree().create_timer(0.6).timeout.connect(show_sequence)
		return

	# Correct so far — check for completion
	if _player_input.size() == _sequence.size():
		_accepting_input = false
		puzzle_solved.emit()
		_play_victory_flash()


## Brief bright flash on a single button as tap acknowledgment.
func _flash_button(btn_index: int) -> void:
	if btn_index >= _visuals.size():
		return
	var vis: ColorRect = _visuals[btn_index]
	var base_col: Color = BUTTON_COLORS[btn_index]
	var bright_col := base_col.lightened(FLASH_BRIGHTEN)

	var tw: Tween = create_tween()
	tw.tween_property(vis, "color", bright_col, 0.08)
	tw.tween_property(vis, "color", base_col,   0.12)


## Cycles through all buttons with a green flash to celebrate success.
func _play_victory_flash() -> void:
	var tw: Tween = create_tween()
	for _rep in range(3):
		for i in range(4):
			var vis: ColorRect = _visuals[i]
			tw.tween_property(vis, "color", Color(0.5, 1.0, 0.5), 0.08)
			tw.tween_property(vis, "color", BUTTON_COLORS[i],      0.12)
