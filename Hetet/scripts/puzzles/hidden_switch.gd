extends Area2D

## Hidden switch — invisible until the player gets close, then fades in.
## Activates when the player physically enters its collision area.
##
## The visual ColorRect is created programmatically so no scene child is required.
## The Area2D collision shape should be configured in the scene as normal.

signal activated

@export var reveal_distance := 150.0  ## Distance (pixels) at which the switch becomes visible

var _revealed := false
var _activated := false
var _visual: ColorRect


func _ready() -> void:
	# Build the visual programmatically so the switch is self-contained
	_visual = ColorRect.new()
	_visual.size = Vector2(32.0, 32.0)
	_visual.position = Vector2(-16.0, -16.0)  # centred on the Area2D origin
	_visual.color = Color(1.0, 0.85, 0.0)     # yellow — the hidden button
	_visual.modulate.a = 0.0                  # start fully invisible
	add_child(_visual)

	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if _activated:
		return

	# Ask GameManager for the current active player position
	var player: Node2D = GameManager.active_player if GameManager.active_player != null else null
	if player == null:
		return

	var dist: float = global_position.distance_to(player.global_position)
	var target_alpha := 1.0 if dist <= reveal_distance else 0.0

	# Smooth fade using lerp so we don't need a Tween per frame
	_visual.modulate.a = lerpf(_visual.modulate.a, target_alpha, 0.08)

	if not _revealed and _visual.modulate.a > 0.95:
		_revealed = true


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player) or _activated:
		return

	_activated = true

	# Snap fully visible and flash white to confirm activation
	_visual.modulate.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_property(_visual, "color", Color(1.0, 1.0, 1.0, 1.0), 0.1)
	tw.tween_property(_visual, "color", Color(0.4, 1.0, 0.4, 1.0), 0.2)

	activated.emit()
