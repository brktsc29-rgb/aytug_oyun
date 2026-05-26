extends Node2D

# ---------------------------------------------------------------------------
# Main scene entry point.
# Defers the menu transition so the scene tree is fully ready before a scene
# change is requested — changing scenes during _ready is unsafe in Godot 4.
# ---------------------------------------------------------------------------

func _ready() -> void:
	call_deferred("_go_to_menu")

func _go_to_menu() -> void:
	GameManager.go_to_main_menu()
