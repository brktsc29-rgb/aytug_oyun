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
	"intro": (
		"Ben MALAKOR! Bu diyarın en kötü, en güçlü, en muhteşem kötü adamıyım! "
		"Sen ise sadece küçük bir kahraman olmaya çalışıyorsun... Hah! "
		"Bu macera seni çok zorlayacak, inan bana!"
	),
	"normal_world": (
		"Buraları benim topraklarım! Her çimen, her taş, her bulut... "
		"hepsi MALAKOR'a aittir! Sen burada ne arıyorsun, küçük cesur?"
	),
	"candy_world": (
		"Şeker Dünyam'a hoş geldin! Ama sakın bir tane bile şeker yeme! "
		"Çünkü buradaki her şey BENİMDİR! "
		"MALAKOR'un şekerlerine el uzatanın pişman olacağını bil!"
	),
	"boss_phase_1": (
		"Hmm... Buraya kadar gelebildin ha? Fena değil, ama asıl oyun şimdi başlıyor! "
		"MALAKOR'u yenebileceğini mi sanıyorsun? "
		"O zaman gel de görelim, küçük kahraman!"
	),
	"boss_phase_2": (
		"Yeterince şans kullandın! Artık gerçek gücümü gösterme zamanı geldi! "
		"Dikkatli ol çünkü MALAKOR bu seferinde şakaya gelmiyor! "
		"Titreme sırası sende!"
	),
	"boss_phase_3": (
		"Bu... bu olamaz! Nasıl bu kadar ileri gelebildin?! "
		"Pekâlâ, son kozumu oynuyorum! "
		"MALAKOR hiçbir zaman teslim olmaz... ama bu sefer çok sıkıştım!"
	),
	"player_died": (
		"Ha ha ha! Gördün mü! MALAKOR her zaman kazanır! "
		"Ama... merak etme, tekrar deneyebilirsin. "
		"Belki bu sefer biraz daha dikkatli olursun. Belki!"
	),
	"checkpoint": (
		"Kontrol noktasını buldun, akıllıca! "
		"Bu küçük başarının tadını çıkar, çünkü önünde çok daha büyük tehlikeler var. "
		"MALAKOR seni hazırlıksız yakalamayı çok sever!"
	),
	"boss_defeated": (
		"İ-İnanılmaz... Gerçekten kaybettim mi? Ben... MALAKOR... yenildim mi?! "
		"Bu bitmedi! Çok yakında geri döneceğim! "
		"Bekle beni, küçük kahraman... bekle beni!"
	),
	"world_complete": (
		"Bu dünyayı geçmeyi başardın, tebrikler... Ama sevinme! "
		"Önünde daha nicesi var ve MALAKOR onların hepsinde seni bekliyor. "
		"Hazır mısın? Ben her zaman hazırım!"
	),
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
	# ── Root panel – bottom-wide strip ────────────────────────────────────
	_panel = PanelContainer.new()
	_panel.name = "MalakorPanel"
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -280.0
	_panel.offset_left = 30.0
	_panel.offset_right = -30.0
	_panel.offset_bottom = -30.0
	_panel.visible = false
	add_child(_panel)

	# ── Outer VBoxContainer ───────────────────────────────────────────────
	var outer_vbox: VBoxContainer = VBoxContainer.new()
	outer_vbox.name = "OuterVBox"
	outer_vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(outer_vbox)

	# ── Content row: portrait + text column ──────────────────────────────
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.name = "ContentRow"
	hbox.add_theme_constant_override("separation", 16)
	outer_vbox.add_child(hbox)

	# Portrait – villain's face placeholder
	var portrait: ColorRect = ColorRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(110.0, 110.0)
	portrait.color = Color(0.7, 0.1, 0.1)
	hbox.add_child(portrait)

	# Text column
	var text_vbox: VBoxContainer = VBoxContainer.new()
	text_vbox.name = "TextVBox"
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(text_vbox)

	# Villain name label – large, eye-catching
	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.text = "MALAKOR"
	_name_label.add_theme_font_size_override("font_size", 34)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
	text_vbox.add_child(_name_label)

	# Dialog text – RichTextLabel supports BBCode for future formatting
	_text_label = RichTextLabel.new()
	_text_label.name = "DialogText"
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("normal_font_size", 28)
	text_vbox.add_child(_text_label)

	# ── Continue button ───────────────────────────────────────────────────
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = "Devam Et ▶"
	_continue_button.add_theme_font_size_override("font_size", 28)
	_continue_button.pressed.connect(_on_continue)
	outer_vbox.add_child(_continue_button)


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
		_panel.visible = false
		_is_active = false
		dialog_finished.emit()
		return

	var key: String = _queue.pop_front()
	_full_text = LINES.get(key, "")
	_is_active = true
	_panel.visible = true
	_text_label.text = ""
	_type_text()


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
