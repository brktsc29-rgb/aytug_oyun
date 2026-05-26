extends CanvasLayer

# ---------------------------------------------------------------------------
# VillainDialog — MALAKOR's typewriter-style dialog system for Hetet
# Register as autoload singleton "VillainDialog" in Project Settings.
# layer = 100 ensures it renders above all game content.
# ---------------------------------------------------------------------------

## Emitted after the last queued dialog line is dismissed.
signal dialog_finished

## Seconds per character for the typewriter effect.
const TYPE_SPEED: float = 0.035

## Child-friendly Turkish villain lines for MALAKOR.
## All text is written to be readable and fun for young players.
const LINES: Dictionary = {
	"intro": "Ben MALAKOR! Bu diyarın en kötü, en güçlü, en muhteşem kötü adamıyım! Bu macera seni çok zorlayacak, inan bana!",
	"normal_world": "Buraları benim topraklarım! Her çimen, her taş, her bulut... hepsi MALAKOR'a aittir! Sen burada ne arıyorsun, küçük cesur?",
	"candy_world": "Şeker Dünyam'a hoş geldin! Ama sakın bir tane bile şeker yeme! MALAKOR'un şekerlerine el uzatanın pişman olacağını bil!",
	"boss_phase_1": "Hmm... Buraya kadar gelebildin ha? Fena değil, ama asıl oyun şimdi başlıyor! O zaman gel de görelim, küçük kahraman!",
	"boss_phase_2": "Yeterince şans kullandın! Artık gerçek gücümü gösterme zamanı geldi! Titreme sırası sende!",
	"boss_phase_3": "Bu... bu olamaz! Nasıl bu kadar ileri gelebildin?! Pekala, son kozumu oynuyorum! MALAKOR hiçbir zaman teslim olmaz!",
	"player_died": "Ha ha ha! Gördün mü! MALAKOR her zaman kazanır! Ama merak etme, tekrar deneyebilirsin. Belki!",
	"checkpoint": "Kontrol noktasını buldun, akıllıca! Bu küçük başarının tadını çıkar, önünde çok daha büyük tehlikeler var!",
	"boss_defeated": "İnanılmaz... Gerçekten kaybettim mi? Ben... MALAKOR... yenildim mi?! Bu bitmedi, geri döneceğim!",
	"world_complete": "Bu dünyayı geçmeyi başardın, tebrikler... Ama sevinme! MALAKOR bir sonrakinde seni bekliyor!",
}

# ---------------------------------------------------------------------------
# UI Node References (populated by _build_ui)
# ---------------------------------------------------------------------------
var _panel: PanelContainer
var _name_label: Label
var _text_label: RichTextLabel
var _continue_button: Button

# ---------------------------------------------------------------------------
# Runtime State
# ---------------------------------------------------------------------------
var _queue: Array[String] = []
var _is_active: bool = false
var _full_text: String = ""
var _type_tween: Tween = null


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	layer = 100
	_build_ui()


# ---------------------------------------------------------------------------
# UI Construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# ── Root panel – dramatic bottom-wide strip ───────────────────────────
	_panel = PanelContainer.new()
	_panel.name = "MalakorPanel"
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top    = -310.0
	_panel.offset_left   = 18.0
	_panel.offset_right  = -18.0
	_panel.offset_bottom = -18.0
	_panel.visible = false

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.02, 0.14, 0.97)
	panel_style.border_color = Color(0.88, 0.12, 0.08)
	panel_style.border_width_bottom = 5
	panel_style.border_width_top    = 5
	panel_style.border_width_left   = 5
	panel_style.border_width_right  = 5
	panel_style.corner_radius_top_left     = 22
	panel_style.corner_radius_top_right    = 22
	panel_style.corner_radius_bottom_left  = 22
	panel_style.corner_radius_bottom_right = 22
	panel_style.content_margin_left   = 20.0
	panel_style.content_margin_right  = 20.0
	panel_style.content_margin_top    = 16.0
	panel_style.content_margin_bottom = 16.0
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	# ── Outer VBox ────────────────────────────────────────────────────────
	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(outer_vbox)

	# ── Content row: portrait + text column ──────────────────────────────
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	outer_vbox.add_child(hbox)

	# Circular villain portrait
	var portrait_wrap := PanelContainer.new()
	portrait_wrap.custom_minimum_size = Vector2(108, 108)
	var face_style := StyleBoxFlat.new()
	face_style.bg_color = Color(0.50, 0.04, 0.07)
	face_style.border_color = Color(1.0, 0.78, 0.0)
	face_style.border_width_bottom = 4
	face_style.border_width_top    = 4
	face_style.border_width_left   = 4
	face_style.border_width_right  = 4
	face_style.corner_radius_top_left     = 54
	face_style.corner_radius_top_right    = 54
	face_style.corner_radius_bottom_left  = 54
	face_style.corner_radius_bottom_right = 54
	portrait_wrap.add_theme_stylebox_override("panel", face_style)
	hbox.add_child(portrait_wrap)

	var portrait_label := Label.new()
	portrait_label.text = "😈"
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	portrait_label.add_theme_font_size_override("font_size", 58)
	portrait_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_wrap.add_child(portrait_label)

	# Text column
	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 8)
	hbox.add_child(text_vbox)

	# Name with drop shadow
	var name_wrap := Control.new()
	name_wrap.custom_minimum_size = Vector2(0, 48)
	text_vbox.add_child(name_wrap)

	var name_shadow := Label.new()
	name_shadow.text = "⚔  MALAKOR  ⚔"
	name_shadow.add_theme_font_size_override("font_size", 36)
	name_shadow.add_theme_color_override("font_color", Color(0.55, 0.0, 0.0, 0.85))
	name_shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_shadow.offset_left = 3.0
	name_shadow.offset_top  = 4.0
	name_wrap.add_child(name_shadow)

	_name_label = Label.new()
	_name_label.text = "⚔  MALAKOR  ⚔"
	_name_label.add_theme_font_size_override("font_size", 36)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.14))
	_name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_wrap.add_child(_name_label)

	# Red divider under name
	var div := ColorRect.new()
	div.color = Color(0.88, 0.12, 0.08, 0.65)
	div.custom_minimum_size = Vector2(0, 2)
	text_vbox.add_child(div)

	# Dialog text
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("normal_font_size", 28)
	_text_label.add_theme_color_override("default_color", Color(0.96, 0.93, 1.0))
	text_vbox.add_child(_text_label)

	# ── Continue button — gold gradient ───────────────────────────────────
	var btn_n := _dialog_btn_style(Color(0.62, 0.42, 0.02), Color(1.0, 0.84, 0.18))
	var btn_h := _dialog_btn_style(Color(0.80, 0.58, 0.05), Color(1.0, 0.94, 0.42))
	var btn_p := _dialog_btn_style(Color(0.42, 0.28, 0.01), Color(0.80, 0.65, 0.10))

	_continue_button = Button.new()
	_continue_button.text = "Devam Et  ▶"
	_continue_button.add_theme_font_size_override("font_size", 30)
	_continue_button.add_theme_color_override("font_color", Color(1, 1, 1))
	_continue_button.add_theme_stylebox_override("normal",  btn_n)
	_continue_button.add_theme_stylebox_override("hover",   btn_h)
	_continue_button.add_theme_stylebox_override("pressed", btn_p)
	_continue_button.pressed.connect(_on_continue)
	outer_vbox.add_child(_continue_button)

func _dialog_btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_bottom = 4
	s.border_width_top    = 4
	s.border_width_left   = 4
	s.border_width_right  = 4
	s.corner_radius_top_left     = 14
	s.corner_radius_top_right    = 14
	s.corner_radius_bottom_left  = 14
	s.corner_radius_bottom_right = 14
	s.content_margin_left   = 24.0
	s.content_margin_right  = 24.0
	s.content_margin_top    = 10.0
	s.content_margin_bottom = 10.0
	return s


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Appends key to the dialog queue. Starts playback immediately if idle.
func show_dialog(key: String) -> void:
	if not LINES.has(key):
		push_warning("VillainDialog.show_dialog: unknown key '%s'" % key)
		return
	_queue.append(key)
	if not _is_active:
		_show_next()


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _show_next() -> void:
	if _queue.is_empty():
		# Slide out before hiding
		var out_tw := create_tween()
		out_tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		out_tw.tween_property(_panel, "offset_bottom", 350.0, 0.28)
		out_tw.tween_property(_panel, "offset_top",    40.0,  0.28).from_current()
		out_tw.tween_callback(func() -> void:
			_panel.visible = false
			_is_active = false
			dialog_finished.emit()
		)
		return

	var key: String = _queue.pop_front()
	_full_text = LINES.get(key, "")
	_is_active = true

	# Slide in from below
	_panel.offset_top    = 80.0
	_panel.offset_bottom = 400.0
	_panel.visible = true
	var in_tw := create_tween()
	in_tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	in_tw.tween_property(_panel, "offset_top",    -310.0, 0.38)
	in_tw.parallel().tween_property(_panel, "offset_bottom", -18.0, 0.38)
	in_tw.tween_callback(func() -> void:
		_text_label.text = ""
		_type_text()
	)


## Animates the dialog text one character at a time using a tween_method.
func _type_text() -> void:
	if _type_tween != null and _type_tween.is_valid():
		_type_tween.kill()

	var total_chars: int = _full_text.length()
	var duration: float = total_chars * TYPE_SPEED

	_type_tween = create_tween()
	# tween_method calls the lambda with interpolated int values from 0 → total_chars.
	_type_tween.tween_method(
		func(char_count: int) -> void:
			_text_label.text = _full_text.left(char_count),
		0,
		total_chars,
		duration
	)


## Pressing "Devam Et" while typing skips to full text.
## Pressing it again advances to the next queued line (or closes the panel).
func _on_continue() -> void:
	if _type_tween != null and _type_tween.is_valid() and _type_tween.is_running():
		# Skip animation – show entire text immediately.
		_type_tween.kill()
		_type_tween = null
		_text_label.text = _full_text
		return

	# Typing finished – proceed to the next line.
	_show_next()
