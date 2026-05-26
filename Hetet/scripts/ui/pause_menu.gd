extends Control

# ---------------------------------------------------------------------------
# Pause Menu — built in GDScript. Works while the tree is paused.
# ---------------------------------------------------------------------------

var _music_on: bool = true
var _sfx_on: bool   = true

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Must run even when the scene tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

# ---------------------------------------------------------------------------
# UI Construction
# ---------------------------------------------------------------------------
func _build_ui() -> void:
	# ── Semi-transparent full-screen dimmer ──────────────────────────────────
	var dimmer: ColorRect = ColorRect.new()
	dimmer.color = Color(0.0, 0.0, 0.0, 0.65)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	# ── Centred panel ────────────────────────────────────────────────────────
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.02, 0.16)
	panel_style.border_color = Color(0.52, 0.28, 1.0, 0.90)
	panel_style.border_width_bottom = 4
	panel_style.border_width_top    = 4
	panel_style.border_width_left   = 4
	panel_style.border_width_right  = 4
	panel_style.corner_radius_top_left     = 24
	panel_style.corner_radius_top_right    = 24
	panel_style.corner_radius_bottom_left  = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.content_margin_left   = 50.0
	panel_style.content_margin_right  = 50.0
	panel_style.content_margin_top    = 40.0
	panel_style.content_margin_bottom = 40.0
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	# ── Inner VBox ───────────────────────────────────────────────────────────
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 22)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Title
	var title: Label = Label.new()
	title.text = "DURDURULDU"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	vbox.add_child(title)

	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	# ── Action buttons ───────────────────────────────────────────────────────
	var resume_btn: Button = _make_button("Devam Et",       Color(0.2, 0.75, 0.35))
	var restart_btn: Button = _make_button("Yeniden Başla", Color(0.2, 0.45, 0.85))
	var menu_btn: Button    = _make_button("Ana Menü",      Color(0.65, 0.1, 0.1))

	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	menu_btn.pressed.connect(_on_main_menu)

	vbox.add_child(resume_btn)
	vbox.add_child(restart_btn)
	vbox.add_child(menu_btn)

	# ── Audio toggles ─────────────────────────────────────────────────────
	var audio_hbox: HBoxContainer = HBoxContainer.new()
	audio_hbox.add_theme_constant_override("separation", 30)
	audio_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(audio_hbox)

	var music_check: CheckBox = CheckBox.new()
	music_check.text = "Müzik"
	music_check.button_pressed = _music_on
	music_check.add_theme_font_size_override("font_size", 36)
	music_check.toggled.connect(_on_music_toggled)
	audio_hbox.add_child(music_check)

	var sfx_check: CheckBox = CheckBox.new()
	sfx_check.text = "Efekt"
	sfx_check.button_pressed = _sfx_on
	sfx_check.add_theme_font_size_override("font_size", 36)
	sfx_check.toggled.connect(_on_sfx_toggled)
	audio_hbox.add_child(sfx_check)

# ---------------------------------------------------------------------------
# Helper — styled button
# ---------------------------------------------------------------------------
func _make_button(label_text: String, bg_color: Color) -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(360.0, 80.0)
	btn.add_theme_font_size_override("font_size", 42)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left     = 14
	style.corner_radius_top_right    = 14
	style.corner_radius_bottom_left  = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left   = 20.0
	style.content_margin_right  = 20.0
	style.content_margin_top    = 10.0
	style.content_margin_bottom = 10.0

	var style_hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	style_hover.bg_color = bg_color.lightened(0.15)

	var style_pressed: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	style_pressed.bg_color = bg_color.darkened(0.15)

	btn.add_theme_stylebox_override("normal",  style)
	btn.add_theme_stylebox_override("hover",   style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)

	return btn

# ---------------------------------------------------------------------------
# Unhandled input — Escape key resumes
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_resume()

# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------
func _on_resume() -> void:
	GameManager.change_state(GameManager.State.PLAYING)
	queue_free()

func _on_restart() -> void:
	GameManager.change_state(GameManager.State.PLAYING)
	GameManager.restart_world()
	queue_free()

func _on_main_menu() -> void:
	GameManager.change_state(GameManager.State.PLAYING)
	GameManager.go_to_main_menu()
	queue_free()

func _on_music_toggled(pressed: bool) -> void:
	_music_on = pressed
	# AudioManager.set_music_enabled(pressed)

func _on_sfx_toggled(pressed: bool) -> void:
	_sfx_on = pressed
	# AudioManager.set_sfx_enabled(pressed)
