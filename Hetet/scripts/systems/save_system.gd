extends Node
class_name SaveSystem

const SAVE_PATH := "user://hetest_save.json"
static var save_data := {
	"coins": 0,
	"checkpoint": Vector2.ZERO,
	"world_unlocked": 1,
	"skin": "default"
}

static func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))

static func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var result := JSON.parse_string(file.get_as_text())
	if result is Dictionary:
		save_data = result

static func set_checkpoint(pos: Vector2) -> void:
	save_data["checkpoint"] = {"x": pos.x, "y": pos.y}
	save_game()
