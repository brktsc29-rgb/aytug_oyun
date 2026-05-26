extends Node

# ---------------------------------------------------------------------------
# SaveSystem — Persistent JSON save for Hetet
# Register as autoload singleton "SaveSystem" in Project Settings.
# IMPORTANT: Vector2 cannot be serialised in JSON. Positions are stored as
# separate float fields (checkpoint_x / checkpoint_y).
# ---------------------------------------------------------------------------

const SAVE_PATH: String = "user://hetet_save.json"

## Canonical save structure with default values.
## All keys that appear here will be present in save_data at runtime.
var save_data: Dictionary = {
	"coins": 0,
	"checkpoint_x": 0.0,
	"checkpoint_y": 0.0,
	"world_unlocked": 0,
	"owned_skins": ["default"],
	"equipped_skin": "default",
	"deaths": 0,
}

# Snapshot of default values used by reset_progress().
const _DEFAULTS: Dictionary = {
	"coins": 0,
	"checkpoint_x": 0.0,
	"checkpoint_y": 0.0,
	"world_unlocked": 0,
	"owned_skins": ["default"],
	"equipped_skin": "default",
	"deaths": 0,
}


func _ready() -> void:
	load_game()


# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------

## Serialises save_data to disk as pretty-printed JSON.
func save_game() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem.save_game: cannot open '%s' for writing. Error: %d"
			% [SAVE_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()


## Reads the JSON save file and merges it into save_data.
## Missing keys fall back to defaults; unknown keys are ignored.
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		# First launch – write defaults so the file always exists.
		save_game()
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveSystem.load_game: cannot open '%s' for reading. Error: %d"
			% [SAVE_PATH, FileAccess.get_open_error()])
		return

	var raw: String = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(raw)
	if parsed == null or not (parsed is Dictionary):
		push_warning("SaveSystem.load_game: corrupt or empty save – reverting to defaults.")
		save_game()
		return

	# Only copy keys declared in the defaults; ignore anything extra.
	for key: String in save_data.keys():
		if parsed.has(key):
			save_data[key] = parsed[key]


# ---------------------------------------------------------------------------
# Checkpoint
# ---------------------------------------------------------------------------

## Stores a world position as two separate floats and saves immediately.
func set_checkpoint(pos: Vector2) -> void:
	save_data["checkpoint_x"] = pos.x
	save_data["checkpoint_y"] = pos.y
	save_game()


## Reconstructs and returns the saved checkpoint as a Vector2.
func get_checkpoint() -> Vector2:
	return Vector2(
		float(save_data.get("checkpoint_x", 0.0)),
		float(save_data.get("checkpoint_y", 0.0))
	)


## Returns true if a non-origin checkpoint has been recorded.
func has_checkpoint() -> bool:
	return save_data.get("checkpoint_x", 0.0) != 0.0 \
		or save_data.get("checkpoint_y", 0.0) != 0.0


## Clears the checkpoint back to origin and saves.
func clear_checkpoint() -> void:
	save_data["checkpoint_x"] = 0.0
	save_data["checkpoint_y"] = 0.0
	save_game()


# ---------------------------------------------------------------------------
# Deaths
# ---------------------------------------------------------------------------

## Increments the death counter and saves.
func record_death() -> void:
	save_data["deaths"] = int(save_data.get("deaths", 0)) + 1
	save_game()


# ---------------------------------------------------------------------------
# Skins
# ---------------------------------------------------------------------------

## Returns true if the player owns the given skin.
func is_skin_owned(skin_id: String) -> bool:
	var owned: Array = save_data.get("owned_skins", []) as Array
	return owned.has(skin_id)


## Adds skin_id to the owned list and saves. No-op if already owned.
func add_skin(skin_id: String) -> void:
	if is_skin_owned(skin_id):
		return
	var owned: Array = save_data.get("owned_skins", []) as Array
	owned.append(skin_id)
	save_data["owned_skins"] = owned
	save_game()


## Equips skin_id if owned, then saves.
func equip_skin(skin_id: String) -> void:
	if not is_skin_owned(skin_id):
		push_warning("SaveSystem.equip_skin: skin not owned – '%s'" % skin_id)
		return
	save_data["equipped_skin"] = skin_id
	save_game()


## Returns the currently equipped skin id.
func get_equipped_skin() -> String:
	return str(save_data.get("equipped_skin", "default"))


# ---------------------------------------------------------------------------
# World Progress
# ---------------------------------------------------------------------------

## Returns the highest world index the player has unlocked.
func get_world_unlocked() -> int:
	return int(save_data.get("world_unlocked", 0))


# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------

## Wipes all progress back to factory defaults and overwrites the save file.
func reset_progress() -> void:
	# Deep-copy the defaults so arrays are not shared references.
	save_data = {
		"coins": 0,
		"checkpoint_x": 0.0,
		"checkpoint_y": 0.0,
		"world_unlocked": 0,
		"owned_skins": ["default"],
		"equipped_skin": "default",
		"deaths": 0,
	}
	save_game()
