extends Control

# ---------------------------------------------------------------------------
# Main Menu — built entirely in GDScript; no scene file required for the UI.
# ---------------------------------------------------------------------------

const SHOP_SCENE: String = "res://scenes/ui/Shop.tscn"

# World metadata: [id, display_name, button_color]
const _WORLDS: Array = [
	[0, "Normal Dünya",   Color(0.2,  0.75, 0.3)],
	[1, "Şeker Dünyası",  Color(0.95, 0.45, 0.75)],
	[2, "Boss",           Color(0.75, 0.1,  0.15)],
]

var _coin_label: Label = null

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

	# Update coin display live
	GameManager.coins_updated.connect(_on_coins_updated)
	_on_coins_updated(GameManager.get_coins())

# ---------------------------------------------------------------------------
# UI Construction
# ---------------------------------------------------------------------------
func _build_ui() -> void:
	# ── Background ──────────────────────────────────────────────────────────
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.1, 0.05, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── Root VBox ───────────────────────────────────────────────────────────
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left   =  60.0
	vbox.offset_right  = -60.0
	vbox.offset_top    =  80.0
	vbox.offset_bottom = -80.0
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)

	# ── Title ────────────────────────────────────────────────────────────────
	var title: Label = Label.new()
	title.text = "HETET"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	vbox.add_child(title)

	# ── Subtitle ─────────────────────────────────────────────────────────────
	var subtitle: Label = Label.new()
	subtitle.text = "Macera Başlıyor!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 40)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))
	vbox.add_child(subtitle)

	# ── Spacer ───────────────────────────────────────────────────────────────
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 30.0)
	vbox.add_child(spacer)

	# ── World buttons ────────────────────────────────────────────────────────
	var unlocked: int = SaveSystem.get_world_unlocked()
	for entry in _WORLDS:
		var world_id: int    = entry[0] as int
		var world_name: String = entry[1] as String
		var btn_color: Color = entry[2] as Color

		var btn: Button = _make_button(world_name, btn_color)
		btn.disabled = world_id > unlocked
		if btn.disabled:
			btn.text = world_name + "  🔒"
		# Capture world_id by value in the lambda
		btn.pressed.connect(func() -> void: GameManager.load_world(world_id))
		vbox.add_child(btn)

	# ── Shop button ──────────────────────────────────────────────────────────
	var shop_btn: Button = _make_button("Dükkan", Color(0.9, 0.7, 0.1))
	shop_btn.pressed.connect(_open_shop)
	vbox.add_child(shop_btn)

	# ── Coin display ─────────────────────────────────────────────────────────
	_coin_label = Label.new()
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coin_label.add_theme_font_size_override("font_size", 44)
	_coin_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	vbox.add_child(_coin_label)

# ---------------------------------------------------------------------------
# Helper — styled button
# ---------------------------------------------------------------------------
func _make_button(label_text: String, bg_color: Color) -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0.0, 90.0)
	btn.add_theme_font_size_override("font_size", 44)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left    = 18
	style.corner_radius_top_right   = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left   = 24.0
	style.content_margin_right  = 24.0
	style.content_margin_top    = 12.0
	style.content_margin_bottom = 12.0

	var style_hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	style_hover.bg_color = bg_color.lightened(0.15)

	var style_pressed: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	style_pressed.bg_color = bg_color.darkened(0.15)

	var style_disabled: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	style_disabled.bg_color = Color(0.35, 0.35, 0.35)

	btn.add_theme_stylebox_override("normal",   style)
	btn.add_theme_stylebox_override("hover",    style_hover)
	btn.add_theme_stylebox_override("pressed",  style_pressed)
	btn.add_theme_stylebox_override("disabled", style_disabled)

	return btn

# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------
func _on_coins_updated(total: int) -> void:
	if is_instance_valid(_coin_label):
		_coin_label.text = "Sikke: %d" % total

func _open_shop() -> void:
	var shop_res: PackedScene = load(SHOP_SCENE)
	if shop_res == null:
		push_error("MainMenu: cannot load Shop scene at %s" % SHOP_SCENE)
		return
	var shop: Control = shop_res.instantiate()
	add_child(shop)
