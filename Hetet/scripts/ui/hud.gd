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

	GameManager.coins_updated.connect(_on_coins_updated)
	_on_coins_updated(GameManager.get_coins())
	pause_btn.pressed.connect(_on_pause)

	_style_hud()

# ---------------------------------------------------------------------------
# Visual styling
# ---------------------------------------------------------------------------
func _style_hud() -> void:
	# Dark gradient background strip
	var bar_bg := ColorRect.new()
	bar_bg.anchor_right = 1.0
	bar_bg.offset_bottom = 94.0
	bar_bg.color = Color(0.04, 0.02, 0.18, 0.86)
	add_child(bar_bg)
	move_child(bar_bg, 0)

	# Purple accent line at bottom of bar
	var accent := ColorRect.new()
	accent.anchor_right = 1.0
	accent.offset_top    = 90.0
	accent.offset_bottom = 95.0
	accent.color = Color(0.55, 0.28, 1.0, 0.72)
	add_child(accent)

	# Coin label — gold colour
	coin_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.18))

	# World label — soft purple
	world_label.add_theme_color_override("font_color", Color(0.78, 0.68, 1.0))

	# Pause button — purple rounded
	var pn := _hud_btn_style(Color(0.28, 0.12, 0.62, 0.90), Color(0.58, 0.35, 1.0, 0.85))
	var ph := _hud_btn_style(Color(0.40, 0.20, 0.80, 0.94), Color(0.72, 0.50, 1.0, 0.95))
	var pp := _hud_btn_style(Color(0.16, 0.06, 0.38, 0.95), Color(0.42, 0.22, 0.78, 0.75))
	pause_btn.add_theme_stylebox_override("normal",  pn)
	pause_btn.add_theme_stylebox_override("hover",   ph)
	pause_btn.add_theme_stylebox_override("pressed", pp)
	pause_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	pause_btn.text = "⏸"

func _hud_btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_bottom = 3
	s.border_width_top    = 3
	s.border_width_left   = 3
	s.border_width_right  = 3
	s.corner_radius_top_left     = 12
	s.corner_radius_top_right    = 12
	s.corner_radius_bottom_left  = 12
	s.corner_radius_bottom_right = 12
	s.content_margin_left   = 16.0
	s.content_margin_right  = 16.0
	s.content_margin_top    = 8.0
	s.content_margin_bottom = 8.0
	return s

# ---------------------------------------------------------------------------
# Coin display
# ---------------------------------------------------------------------------
func _on_coins_updated(total: int) -> void:
	coin_label.text = "✦ %d" % total
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
