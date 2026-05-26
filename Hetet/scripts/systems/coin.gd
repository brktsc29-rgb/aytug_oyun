extends Area2D

## Collectible coin — grants value coins to the player and removes itself.
##
## Expected scene layout:
##   Coin (Area2D)          ← this script
##     ├─ CollisionShape2D
##     └─ Visual (ColorRect) ← 20×20 yellow square

@export var value := 1

var _collected := false

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Gentle idle bob
	var tw: Tween = create_tween().set_loops()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position:y", position.y - 5.0, 0.6)
	tw.tween_property(self, "position:y", position.y,       0.6)


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player) or _collected:
		return

	_collected = true
	body.collect_coin(value)

	# Play pickup sound via AudioManager if available
	pass  # AudioManager.play_sfx(preload("res://assets/audio/sfx/coin.ogg")) when added

	# Pop animation: scale to zero then free
	var tw: Tween = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.18)
	tw.tween_callback(queue_free)
