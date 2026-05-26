extends Area2D

## Spike trap — instantly kills any Player that enters the collision area.
## The visual (Polygon2D or ColorRect) is built directly in the scene tree as a child.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.die()
