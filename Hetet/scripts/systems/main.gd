extends Node2D

@onready var world_container: Node = $CurrentWorld

func _ready() -> void:
	SaveSystem.load_game()
	VillainDialog.show_intro("Welcome to the world…")

func load_world(scene_path: String) -> void:
	for child in world_container.get_children():
		child.queue_free()
	var scene := load(scene_path) as PackedScene
	world_container.add_child(scene.instantiate())
