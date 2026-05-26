extends CanvasLayer

# ---------------------------------------------------------------------------
# Onready nodes
# ---------------------------------------------------------------------------
@onready var coin_label: Label = $TopBar/CoinContainer/CoinLabel
@onready var world_label: Label = $TopBar/WorldLabel
@onready var pause_btn: Button = $TopBar/PauseButton

# Cached path for the PauseMenu overlay.
const PAUSE_MENU_SCENE: String = "res://scenes/ui/PauseMenu.tscn"

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	layer = 10

	# Connect to GameManager coin signal
	GameManager.coins_updated.connect(_on_coins_updated)

	# Initialise display with current coin count
	_on_coins_updated(GameManager.get_coins())

	# Pause button
	pause_btn.pressed.connect(_on_pause)

# ---------------------------------------------------------------------------
# Coin display
# ---------------------------------------------------------------------------
func _on_coins_updated(total: int) -> void:
	coin_label.text = "Sikke: %d" % total
	_bounce_label(coin_label)

func _bounce_label(label: Label) -> void:
	if not is_instance_valid(label):
		return
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.07)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.12)

# ---------------------------------------------------------------------------
# World name
# ---------------------------------------------------------------------------
func set_world_name(world_name: String) -> void:
	if is_instance_valid(world_label):
		world_label.text = world_name

# ---------------------------------------------------------------------------
# Player binding
# ---------------------------------------------------------------------------
## Call this after spawning the player so the HUD reacts to coin signals.
func bind_player(player: Player) -> void:
	if player == null:
		return
	# coin_collected carries the running total — reuse _on_coins_updated.
	if not player.coin_collected.is_connected(_on_coins_updated):
		player.coin_collected.connect(_on_coins_updated)

# ---------------------------------------------------------------------------
# Pause
# ---------------------------------------------------------------------------
func _on_pause() -> void:
	GameManager.change_state(GameManager.State.PAUSED)

	var pause_scene_res: PackedScene = load(PAUSE_MENU_SCENE)
	if pause_scene_res == null:
		push_error("HUD: cannot load PauseMenu scene at %s" % PAUSE_MENU_SCENE)
		return

	var pause_menu: Control = pause_scene_res.instantiate()
	get_tree().root.add_child(pause_menu)
