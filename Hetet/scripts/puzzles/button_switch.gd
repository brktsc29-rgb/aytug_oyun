extends Area2D
signal activated
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		emit_signal("activated")
