extends Area2D

## Button switch — activates when the player walks into it.
## Optionally calls on_activated() on a target node and supports one-shot mode.
##
## Expected scene layout:
##   ButtonSwitch (Area2D)        ← this script
##     ├─ CollisionShape2D
##     └─ Visual (ColorRect)      ← changes colour on activation

signal activated

@export var target_node_path: NodePath  ## Node to call on_activated() on (optional)
@export var one_shot := true            ## If true the switch fires only once

var _activated := false

@onready var _visual: ColorRect = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_visual.color = Color(0.2, 0.6, 1.0)  # idle blue


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	if one_shot and _activated:
		return

	_activated = true
	activated.emit()

	# Visual feedback — turn yellow when pressed
	var tw: Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(_visual, "color", Color(1.0, 0.85, 0.0), 0.15)

	# Notify the target node if one is configured
	if target_node_path.is_empty():
		return

	var target: Node = get_node_or_null(target_node_path)
	if target == null:
		push_warning("ButtonSwitch: target_node_path '%s' not found." % str(target_node_path))
		return
	if target.has_method("on_activated"):
		target.on_activated()
