extends Node2D

## Boss World — the final arena where the player fights MALAKOR.
## Generates the arena geometry programmatically, spawns the player and boss,
## and handles the win-screen flow after the boss is defeated.

const PLAYER_SCENE     := preload("res://scenes/player/Player.tscn")
const FINAL_BOSS_SCENE := preload("res://scenes/boss/FinalBoss.tscn")
const COIN_SCENE       := preload("res://scenes/objects/Coin.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/objects/Checkpoint.tscn")

## Arena dimensions (pixels)
const ARENA_WIDTH  := 1600.0
const ARENA_HEIGHT := 800.0
const FLOOR_Y      := 720.0
const WALL_THICK   := 60.0
const PLATFORM_H   := 36.0

## Spawn positions
const PLAYER_SPAWN := Vector2(160.0, FLOOR_Y - 64.0)
const BOSS_SPAWN   := Vector2(1300.0, FLOOR_Y - 80.0)

## Floating platform layout  {x, y, width}
const DODGE_PLATFORMS := [
	{"x": 200.0,  "y": 520.0, "w": 200.0},
	{"x": 560.0,  "y": 430.0, "w": 180.0},
	{"x": 920.0,  "y": 490.0, "w": 200.0},
	{"x": 1240.0, "y": 400.0, "w": 160.0},
]


func _ready() -> void:
	VillainDialog.show_dialog("boss_phase_1")
	_generate_arena()
	_spawn_player()
	_spawn_boss()


# ---------------------------------------------------------------------------
# Arena construction
# ---------------------------------------------------------------------------

## Builds the arena floor, ceiling, side walls, and dodge platforms.
func _generate_arena() -> void:
	# --- Floor ---
	_make_platform(
		Vector2(0.0, FLOOR_Y),
		Vector2(ARENA_WIDTH, PLATFORM_H),
		Color(0.20, 0.08, 0.30)   # dark purple
	)

	# --- Left wall ---
	_make_platform(
		Vector2(-WALL_THICK, 0.0),
		Vector2(WALL_THICK, ARENA_HEIGHT + PLATFORM_H),
		Color(0.15, 0.05, 0.22)
	)

	# --- Right wall ---
	_make_platform(
		Vector2(ARENA_WIDTH, 0.0),
		Vector2(WALL_THICK, ARENA_HEIGHT + PLATFORM_H),
		Color(0.15, 0.05, 0.22)
	)

	# --- Floating dodge platforms ---
	for data in DODGE_PLATFORMS:
		_make_platform(
			Vector2(data["x"], data["y"]),
			Vector2(data["w"], PLATFORM_H),
			Color(0.30, 0.12, 0.45)   # slightly lighter purple
		)


## Creates a StaticBody2D platform at pos with the given size and colour.
func _make_platform(pos: Vector2, size: Vector2, colour: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	add_child(body)

	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	# CollisionShape2D origin is at the shape centre, so offset by half-size
	shape.position = size * 0.5
	body.add_child(shape)

	var visual := ColorRect.new()
	visual.size = size
	visual.color = colour
	body.add_child(visual)


# ---------------------------------------------------------------------------
# Entity spawning
# ---------------------------------------------------------------------------

## Places the player at the left side of the arena.
func _spawn_player() -> void:
	var player: CharacterBody2D = PLAYER_SCENE.instantiate()
	player.global_position = PLAYER_SPAWN
	add_child(player)

	# Register with the GameManager so other systems can find the player
	if GameManager.has_method("register_player"):
		GameManager.register_player(player)


## Instantiates the final boss at the right side and connects its signal.
func _spawn_boss() -> void:
	var boss: CharacterBody2D = FINAL_BOSS_SCENE.instantiate()
	boss.global_position = BOSS_SPAWN
	add_child(boss)

	boss.defeated.connect(_on_boss_defeated)


# ---------------------------------------------------------------------------
# Victory flow
# ---------------------------------------------------------------------------

## Called when the boss emits its "defeated" signal.
func _on_boss_defeated() -> void:
	VillainDialog.show_dialog("boss_defeated")

	# Wait four seconds so the dialog can finish playing
	await get_tree().create_timer(4.0).timeout

	_show_win_screen()
	GameManager.change_state(GameManager.State.WIN)


## Builds a simple win-screen overlay and adds it to the scene.
func _show_win_screen() -> void:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	add_child(overlay)

	# Semi-transparent dark background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay.add_child(bg)

	# "TEBRIKLER!" congratulation label
	var label := Label.new()
	label.text = "TEBRIKLER!"
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.position = Vector2(
		get_viewport_rect().size.x * 0.5 - 160.0,
		get_viewport_rect().size.y * 0.3
	)
	overlay.add_child(label)

	# Sub-label
	var sub_label := Label.new()
	sub_label.text = "Oyunu tamamladın!"
	sub_label.add_theme_font_size_override("font_size", 28)
	sub_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	sub_label.position = Vector2(
		get_viewport_rect().size.x * 0.5 - 120.0,
		get_viewport_rect().size.y * 0.3 + 80.0
	)
	overlay.add_child(sub_label)

	# "Ana Menü" button
	var btn := Button.new()
	btn.text = "Ana Menü"
	btn.add_theme_font_size_override("font_size", 30)
	btn.position = Vector2(
		get_viewport_rect().size.x * 0.5 - 100.0,
		get_viewport_rect().size.y * 0.6
	)
	btn.size = Vector2(200.0, 60.0)
	overlay.add_child(btn)

	btn.pressed.connect(func() -> void:
		GameManager.change_state("MAIN_MENU")
	)

	# Fade the overlay in
	overlay.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(overlay, "modulate:a", 1.0, 0.6)
