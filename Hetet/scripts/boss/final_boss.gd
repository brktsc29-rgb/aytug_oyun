extends CharacterBody2D

signal defeated
@export var max_hp := 12
var hp := 12
var phase := 1

func _ready() -> void:
	hp = max_hp

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= max_hp * 0.66 and phase == 1:
		phase = 2
		VillainDialog.taunt("Boss Phase 2")
	if hp <= max_hp * 0.33 and phase == 2:
		phase = 3
		VillainDialog.taunt("Boss Phase 3")
	if hp <= 0:
		emit_signal("defeated")
		queue_free()
