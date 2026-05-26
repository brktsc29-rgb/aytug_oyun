extends Control

# ---------------------------------------------------------------------------
# Shop UI — built entirely in GDScript.
# ---------------------------------------------------------------------------

var _coin_label: Label = null
var _grid: GridContainer = null

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

	GameManager.coins_updated.connect(_on_coins_updated)
	_on_coins_updated(GameManager.get_coins())

# ---------------------------------------------------------------------------
# UI Construction
# ---------------------------------------------------------------------------
func _build_ui() -> void:
	# ── Dimmer background ────────────────────────────────────────────────────
	var dimmer: ColorRect = ColorRect.new()
	dimmer.color = Color(0.0, 0.0, 0.0, 0.72)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	# ── Main panel ───────────────────────────────────────────────────────────
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -380.0
	panel.offset_right  =  380.0
	panel.offset_top    = -500.0
	panel.offset_bottom =  500.0

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.04, 0.18)
	panel_style.corner_radius_top_left     = 20
	panel_style.corner_radius_top_right    = 20
	panel_style.corner_radius_bottom_left  = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.content_margin_left   = 30.0
	panel_style.content_margin_right  = 30.0
	panel_style.content_margin_top    = 24.0
	panel_style.content_margin_bottom = 24.0
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	# ── Outer VBox ───────────────────────────────────────────────────────────
	var outer_vbox: VBoxContainer = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 18)
	panel.add_child(outer_vbox)

	# ── Header row (title + close button) ────────────────────────────────────
	var header: HBoxContainer = HBoxContainer.new()
	outer_vbox.add_child(header)

	var title: Label = Label.new()
	title.text = "DÜKKAN"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	header.add_child(title)

	var close_btn: Button = Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 44)
	close_btn.custom_minimum_size = Vector2(64.0, 64.0)
	close_btn.pressed.connect(queue_free)
	header.add_child(close_btn)

	# ── Coin display ─────────────────────────────────────────────────────────
	_coin_label = Label.new()
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_coin_label.add_theme_font_size_override("font_size", 40)
	_coin_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	outer_vbox.add_child(_coin_label)

	var sep: HSeparator = HSeparator.new()
	outer_vbox.add_child(sep)

	# ── Scrollable skin grid ──────────────────────────────────────────────────
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(_grid)

	_refresh_grid()

# ---------------------------------------------------------------------------
# Grid refresh
# ---------------------------------------------------------------------------
func _refresh_grid() -> void:
	# Clear existing children
	for child in _grid.get_children():
		child.queue_free()

	var equipped: String = SaveSystem.get_equipped_skin()

	for skin_id in ShopSystem.get_all_skin_ids():
		_grid.add_child(_build_skin_card(skin_id, equipped))

func _build_skin_card(skin_id: String, equipped_id: String) -> Control:
	var skin_color: Color  = ShopSystem.get_skin_color(skin_id)
	var skin_name: String  = ShopSystem.get_skin_name(skin_id)
	var skin_cost: int     = ShopSystem.get_skin_cost(skin_id)
	var is_owned: bool     = SaveSystem.is_skin_owned(skin_id)
	var is_equipped: bool  = (skin_id == equipped_id)

	# Card panel
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(280.0, 320.0)

	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.14, 0.08, 0.28)
	card_style.corner_radius_top_left     = 14
	card_style.corner_radius_top_right    = 14
	card_style.corner_radius_bottom_left  = 14
	card_style.corner_radius_bottom_right = 14
	card_style.content_margin_left   = 16.0
	card_style.content_margin_right  = 16.0
	card_style.content_margin_top    = 16.0
	card_style.content_margin_bottom = 16.0

	if is_equipped:
		card_style.border_color = Color(1.0, 0.85, 0.0)
		card_style.border_width_left   = 3
		card_style.border_width_right  = 3
		card_style.border_width_top    = 3
		card_style.border_width_bottom = 3

	card.add_theme_stylebox_override("panel", card_style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	# Colour swatch
	var swatch: ColorRect = ColorRect.new()
	swatch.color = skin_color
	swatch.custom_minimum_size = Vector2(80.0, 80.0)
	swatch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(swatch)

	# Name
	var name_lbl: Label = Label.new()
	name_lbl.text = skin_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 32)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_lbl)

	# Status label
	var status_lbl: Label = Label.new()
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 28)
	if is_equipped:
		status_lbl.text = "GİYİLİYOR"
		status_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	elif is_owned:
		status_lbl.text = "SAHİP"
		status_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		status_lbl.text = "%d Sikke" % skin_cost
		status_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	vbox.add_child(status_lbl)

	# Action button
	var action_btn: Button = Button.new()
	action_btn.add_theme_font_size_override("font_size", 32)
	action_btn.custom_minimum_size = Vector2(0.0, 56.0)

	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.corner_radius_top_left     = 10
	btn_style.corner_radius_top_right    = 10
	btn_style.corner_radius_bottom_left  = 10
	btn_style.corner_radius_bottom_right = 10
	btn_style.content_margin_left   = 12.0
	btn_style.content_margin_right  = 12.0
	btn_style.content_margin_top    = 8.0
	btn_style.content_margin_bottom = 8.0

	if is_equipped:
		action_btn.text = "Giyildi"
		action_btn.disabled = true
		btn_style.bg_color = Color(0.3, 0.3, 0.3)
	elif is_owned:
		action_btn.text = "Giy"
		btn_style.bg_color = Color(0.15, 0.55, 0.85)
		action_btn.pressed.connect(func() -> void:
			ShopSystem.equip_skin(skin_id)
			_refresh_grid()
		)
	else:
		action_btn.text = "Satın Al"
		btn_style.bg_color = Color(0.8, 0.5, 0.05)
		action_btn.pressed.connect(func() -> void:
			if ShopSystem.try_buy_skin(skin_id):
				_refresh_grid()
		)

	action_btn.add_theme_stylebox_override("normal", btn_style)

	var btn_hover: StyleBoxFlat = btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = btn_style.bg_color.lightened(0.15)
	action_btn.add_theme_stylebox_override("hover", btn_hover)

	vbox.add_child(action_btn)

	return card

# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------
func _on_coins_updated(total: int) -> void:
	if is_instance_valid(_coin_label):
		_coin_label.text = "Bakiye: %d Sikke" % total
