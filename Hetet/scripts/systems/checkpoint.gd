extends Area2D

## Checkpoint — saves the player's respawn position when first activated.
## The visual changes from grey to bright green to confirm activation.
##
## Expected scene layout:
##   Checkpoint (Area2D)      ← this script
##     ├─ CollisionShape2D
##     └─ Visual (ColorRect)  ← flag / marker sprite

@export var checkpoint_id := "cp_01"  ## Unique id used by SaveSystem

var _activated := false

@onready var _visual: ColorRect = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_visual.color = Color(0.45, 0.45, 0.45)  # idle grey


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player) or _activated:
		return

	_activated = true

	# Tell the player where to respawn
	body.set_checkpoint(global_position)

	# Persist the checkpoint so it survives scene reloads
	if SaveSystem.has_method("save_checkpoint"):
		SaveSystem.save_checkpoint(checkpoint_id, global_position)

	# Visual feedback: flash white then settle on bright green
	var tw: Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(_visual, "color", Color(1.0, 1.0, 1.0), 0.1)   # flash
	tw.tween_property(_visual, "color", Color(0.15, 1.0, 0.35), 0.3)  # green

	# Optional audio feedback
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("checkpoint_activate")
