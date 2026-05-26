extends Control

const SHOP_SCENE: String = "res://scenes/ui/Shop.tscn"

const _WORLDS: Array = [
	[0, "Normal Dünya",  "🌿", Color(0.15, 0.72, 0.35), Color(0.08, 0.45, 0.20)],
	[1, "Şeker Dünyası", "🍭", Color(0.95, 0.35, 0.70), Color(0.65, 0.10, 0.42)],
	[2, "Boss",          "💀", Color(0.80, 0.10, 0.15), Color(0.50, 0.05, 0.08)],
]

var _coin_label: Label = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	GameManager.coins_updated.connect(_on_coins_updated)
	_on_coins_updated(GameManager.get_coins())

func _build_ui() -> void:
	# ── Deep space background ────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── Stars ────────────────────────────────────────────────────────────────
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 80:
		var star := ColorRect.new()
		var sz: float = rng.randf_range(1.5, 4.0)
		star.size = Vector2(sz, sz)
		star.position = Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 1200))
		star.color = Color(1, 1, 1, rng.randf_range(0.3, 0.9))
		bg.add_child(star)

	# ── Glow strip behind title ──────────────────────────────────────────────
	var glow := ColorRect.new()
	glow.color = Color(0.6, 0.3, 1.0, 0.08)
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.offset_top = 40.0
	glow.offset_bottom = -800.0
	add_child(glow)

	# ── Main layout ──────────────────────────────────────────────────────────
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 160.0
	center.offset_right = -160.0
	center.offset_top = 60.0
	center.offset_bottom = -60.0
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 28)
	add_child(center)

	# ── Title shadow ─────────────────────────────────────────────────────────
	var title_container := Control.new()
	title_container.custom_minimum_size = Vector2(0, 130)
	center.add_child(title_container)

	var title_shadow := Label.new()
	title_shadow.text = "HETET"
	title_shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_shadow.add_theme_font_size_override("font_size", 110)
	title_shadow.add_theme_color_override("font_color", Color(0.4, 0.1, 0.8, 0.6))
	title_shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_shadow.offset_left = 5.0
	title_shadow.offset_top = 6.0
	title_container.add_child(title_shadow)

	var title := Label.new()
	title.text = "HETET"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 110)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.15))
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_container.add_child(title)

	# ── Subtitle ─────────────────────────────────────────────────────────────
	var sub := Label.new()
	sub.text = "✦  Macera Seni Bekliyor  ✦"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 36)
	sub.add_theme_color_override("font_color", Color(0.75, 0.65, 1.0))
	center.add_child(sub)

	# ── Divider ──────────────────────────────────────────────────────────────
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 3)
	div.color = Color(0.5, 0.3, 1.0, 0.4)
	center.add_child(div)

	# ── World buttons ─────────────────────────────────────────────────────────
	var unlocked: int = SaveSystem.get_world_unlocked()
	for entry in _WORLDS:
		var wid: int      = entry[0] as int
		var wname: String  = entry[1] as String
		var wicon: String  = entry[2] as String
		var col1: Color    = entry[3] as Color
		var col2: Color    = entry[4] as Color
		var is_locked: bool = wid > unlocked

		var btn := _make_world_button(wicon + "  " + wname + ("   🔒" if is_locked else ""), col1, col2, is_locked)
		if not is_locked:
			btn.pressed.connect(func() -> void: GameManager.load_world(wid))
		center.add_child(btn)

	# ── Bottom row: shop + coins ──────────────────────────────────────────────
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 20)
	center.add_child(bottom_row)

	var shop_btn := _make_button("🛒  Dükkan", Color(0.85, 0.65, 0.05), Color(0.55, 0.40, 0.02))
	shop_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_btn.pressed.connect(_open_shop)
	bottom_row.add_child(shop_btn)

	var coin_panel := PanelContainer.new()
	coin_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	var coin_style := StyleBoxFlat.new()
	coin_style.bg_color = Color(0.12, 0.10, 0.28)
	coin_style.border_color = Color(1.0, 0.84, 0.0)
	coin_style.border_width_bottom = 3
	coin_style.border_width_top = 3
	coin_style.border_width_left = 3
	coin_style.border_width_right = 3
	_set_all_corners(coin_style, 16)
	coin_style.content_margin_left = 24.0
	coin_style.content_margin_right = 24.0
	coin_style.content_margin_top = 10.0
	coin_style.content_margin_bottom = 10.0
	coin_panel.add_theme_stylebox_override("panel", coin_style)
	bottom_row.add_child(coin_panel)

	_coin_label = Label.new()
	_coin_label.add_theme_font_size_override("font_size", 44)
	_coin_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	coin_panel.add_child(_coin_label)

# ── World button (tall, two-tone) ─────────────────────────────────────────────
func _make_world_button(label_text: String, top_color: Color, bot_color: Color, locked: bool) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0.0, 100.0)
	btn.add_theme_font_size_override("font_size", 48)
	btn.disabled = locked

	var col: Color = Color(0.30, 0.30, 0.30) if locked else top_color
	var col_d: Color = Color(0.18, 0.18, 0.18) if locked else bot_color

	var s := _make_stylebox(col, col_d, 20, 4, Color(1,1,1,0.18))
	var sh := _make_stylebox(col.lightened(0.15), col_d.lightened(0.1), 20, 4, Color(1,1,1,0.3))
	var sp := _make_stylebox(col.darkened(0.2), col_d.darkened(0.15), 20, 4, Color(1,1,1,0.05))
	var sd := _make_stylebox(Color(0.22,0.22,0.22), Color(0.14,0.14,0.14), 20, 2, Color(0.5,0.5,0.5,0.2))

	btn.add_theme_stylebox_override("normal",   s)
	btn.add_theme_stylebox_override("hover",    sh)
	btn.add_theme_stylebox_override("pressed",  sp)
	btn.add_theme_stylebox_override("disabled", sd)
	btn.add_theme_color_override("font_color", Color(1, 1, 1) if not locked else Color(0.55, 0.55, 0.55))
	return btn

func _make_button(label_text: String, color1: Color, color2: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0.0, 80.0)
	btn.add_theme_font_size_override("font_size", 40)
	btn.add_theme_stylebox_override("normal",  _make_stylebox(color1, color2, 16, 3, Color(1,1,1,0.15)))
	btn.add_theme_stylebox_override("hover",   _make_stylebox(color1.lightened(0.15), color2.lightened(0.1), 16, 3, Color(1,1,1,0.25)))
	btn.add_theme_stylebox_override("pressed", _make_stylebox(color1.darkened(0.2), color2.darkened(0.15), 16, 3, Color(1,1,1,0.05)))
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	return btn

func _make_stylebox(bg: Color, border: Color, radius: int, border_w: int, highlight: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_bottom = border_w
	s.border_width_top = border_w
	s.border_width_left = border_w
	s.border_width_right = border_w
	_set_all_corners(s, radius)
	s.content_margin_left = 28.0
	s.content_margin_right = 28.0
	s.content_margin_top = 14.0
	s.content_margin_bottom = 14.0
	# Subtle top highlight
	s.shadow_color = highlight
	s.shadow_size = 2
	return s

func _set_all_corners(s: StyleBoxFlat, r: int) -> void:
	s.corner_radius_top_left = r
	s.corner_radius_top_right = r
	s.corner_radius_bottom_left = r
	s.corner_radius_bottom_right = r

func _on_coins_updated(total: int) -> void:
	if is_instance_valid(_coin_label):
		_coin_label.text = "✦ %d" % total

func _open_shop() -> void:
	var shop_res: PackedScene = load(SHOP_SCENE)
	if shop_res == null:
		return
	add_child(shop_res.instantiate())
