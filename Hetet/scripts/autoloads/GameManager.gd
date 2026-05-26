extends Node

# ---------------------------------------------------------------------------
# GameManager — Central game-state controller for Hetet
# Register as autoload singleton "GameManager" in Project Settings.
# ---------------------------------------------------------------------------

enum State {
	MENU,
	PLAYING,
	PAUSED,
	BOSS,
	WIN,
	GAME_OVER,
}

## World IDs: 0 = Normal, 1 = Candy, 2 = Boss
const WORLD_SCENES: Array[String] = [
	"res://scenes/worlds/NormalWorld.tscn",
	"res://scenes/worlds/CandyWorld.tscn",
	"res://scenes/worlds/BossWorld.tscn",
]

const MAIN_MENU_SCENE: String = "res://scenes/common/MainMenu.tscn"

## Emitted whenever the game state changes.
signal state_changed(new_state: State)
## Emitted whenever the player's coin total changes.
signal coins_updated(total: int)

var current_state: State = State.MENU
## 0 = Normal World, 1 = Candy World, 2 = Boss World
var current_world_id: int = 0
## Reference to the active player node. Set by the player itself on _ready.
var active_player: CharacterBody2D = null


func _ready() -> void:
	# Must process even when the tree is paused (e.g. to handle un-pausing).
	process_mode = Node.PROCESS_MODE_ALWAYS


# ---------------------------------------------------------------------------
# State Management
# ---------------------------------------------------------------------------

## Transitions to new_state and adjusts tree.paused accordingly.
func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	match new_state:
		State.PAUSED:
			get_tree().paused = true
		_:
			get_tree().paused = false
	state_changed.emit(new_state)


# ---------------------------------------------------------------------------
# Coin Management
# ---------------------------------------------------------------------------

## Adds amount to the player's coin balance and persists the save.
func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	SaveSystem.save_data["coins"] = SaveSystem.save_data.get("coins", 0) + amount
	SaveSystem.save_game()
	coins_updated.emit(SaveSystem.save_data["coins"])


## Returns the player's current coin balance.
func get_coins() -> int:
	return int(SaveSystem.save_data.get("coins", 0))


## Deducts amount from the player's balance if they have enough.
## Returns true on success, false if the balance is insufficient.
func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	var balance: int = get_coins()
	if balance < amount:
		return false
	SaveSystem.save_data["coins"] = balance - amount
	SaveSystem.save_game()
	coins_updated.emit(SaveSystem.save_data["coins"])
	return true


# ---------------------------------------------------------------------------
# World / Scene Management
# ---------------------------------------------------------------------------

## Loads the scene for world_id and switches state to PLAYING.
func load_world(world_id: int) -> void:
	if world_id < 0 or world_id >= WORLD_SCENES.size():
		push_error("GameManager.load_world: invalid world_id %d" % world_id)
		return
	current_world_id = world_id
	change_state(State.PLAYING)
	get_tree().change_scene_to_file(WORLD_SCENES[world_id])


## Returns to the main menu and clears the active player reference.
func go_to_main_menu() -> void:
	active_player = null
	change_state(State.MENU)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


## Reloads the current world from scratch.
func restart_world() -> void:
	load_world(current_world_id)


## Saves world_unlocked progress if the next world hasn't been recorded yet.
func unlock_next_world() -> void:
	var next_id: int = current_world_id + 1
	if next_id >= WORLD_SCENES.size():
		# All worlds are already available.
		return
	if next_id > SaveSystem.get_world_unlocked():
		SaveSystem.save_data["world_unlocked"] = next_id
		SaveSystem.save_game()
