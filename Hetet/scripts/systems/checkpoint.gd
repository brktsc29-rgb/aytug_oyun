extends Area2D

@export var checkpoint_id := "cp_01"

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.set_checkpoint(global_position)
