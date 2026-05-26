extends Node2D

# ---------------------------------------------------------------------------
# Normal World — procedurally assembled level.
# All scenes are instantiated at runtime so no separate tscn layout is needed
# beyond the root node.
# ---------------------------------------------------------------------------

const PLAYER_SCENE:           PackedScene = preload("res://scenes/player/Player.tscn")
const COIN_SCENE:             PackedScene = preload("res://scenes/objects/Coin.tscn")
const CHECKPOINT_SCENE:       PackedScene = preload("res://scenes/objects/Checkpoint.tscn")
const SPIKE_SCENE:            PackedScene = preload("res://scenes/traps/Spike.tscn")
const MOVING_PLATFORM_SCENE:  PackedScene = preload("res://scenes/traps/MovingPlatform.tscn")
const FALLING_PLATFORM_SCENE: PackedScene = preload("res://scenes/traps/FallingPlatform.tscn")
const HUD_SCENE:              PackedScene = preload("res://scenes/ui/HUD.tscn")
const CONTROLS_SCENE:         PackedScene = preload("res://scenes/ui/MobileControls.tscn")
const TREE_TEX:               Texture2D   = preload("res://assets/sprites/tree.svg")
const CLOUD_TEX:              Texture2D   = preload("res://assets/sprites/cloud.svg")

var player: Player = null

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	VillainDialog.show_dialog("normal_world")
	_generate_level()
	_spawn_player()
	_spawn_ui()

# ---------------------------------------------------------------------------
# Level generation
# ---------------------------------------------------------------------------
func _generate_level() -> void:
	_create_background()

	# ── Ground ────────────────────────────────────────────────────────────────
	_create_platform(Vector2(-200.0, 500.0), Vector2(3000.0, 80.0), Color(0.22, 0.62, 0.16))

	# ── Platforms ─────────────────────────────────────────────────────────────
	# Layout: gradually ascending path with deliberate gaps.
	var platforms: Array[Dictionary] = [
		{"pos": Vector2(300.0,  380.0), "size": Vector2(200.0, 24.0)},
		{"pos": Vector2(560.0,  300.0), "size": Vector2(160.0, 24.0)},
		{"pos": Vector2(780.0,  230.0), "size": Vector2(180.0, 24.0)},
		{"pos": Vector2(1020.0, 170.0), "size": Vector2(200.0, 24.0)},
		{"pos": Vector2(1260.0, 260.0), "size": Vector2(140.0, 24.0)},
		{"pos": Vector2(1450.0, 340.0), "size": Vector2(220.0, 24.0)},
		{"pos": Vector2(1680.0, 250.0), "size": Vector2(160.0, 24.0)},
		{"pos": Vector2(1880.0, 180.0), "size": Vector2(180.0, 24.0)},
		{"pos": Vector2(2080.0, 110.0), "size": Vector2(200.0, 24.0)},
		{"pos": Vector2(2300.0, 200.0), "size": Vector2(160.0, 24.0)},
		{"pos": Vector2(2490.0, 310.0), "size": Vector2(200.0, 24.0)},
		{"pos": Vector2(2700.0, 220.0), "size": Vector2(180.0, 24.0)},
		{"pos": Vector2(300.0,  460.0), "size": Vector2(120.0, 20.0)},  # low stepping stone
		{"pos": Vector2(1100.0, 430.0), "size": Vector2(150.0, 20.0)},
		{"pos": Vector2(2000.0, 450.0), "size": Vector2(140.0, 20.0)},
	]
	var pf_color: Color = Color(0.45, 0.62, 0.28)
	for pf in platforms:
		_create_platform(pf["pos"], pf["size"], pf_color)

	# ── Coins ─────────────────────────────────────────────────────────────────
	var coin_positions: Array[Vector2] = [
		Vector2(120.0,  430.0), Vector2(200.0, 430.0), Vector2(280.0, 430.0),
		Vector2(370.0,  340.0), Vector2(450.0, 340.0),
		Vector2(590.0,  260.0), Vector2(660.0, 260.0),
		Vector2(820.0,  190.0), Vector2(890.0, 190.0),
		Vector2(1050.0, 130.0), Vector2(1110.0, 130.0), Vector2(1170.0, 130.0),
		Vector2(1280.0, 220.0),
		Vector2(1480.0, 300.0), Vector2(1550.0, 300.0),
		Vector2(1710.0, 210.0),
		Vector2(1920.0, 140.0), Vector2(1990.0, 140.0),
		Vector2(2110.0,  70.0), Vector2(2170.0,  70.0),
		Vector2(2320.0, 160.0), Vector2(2390.0, 160.0),
		Vector2(2520.0, 270.0),
		Vector2(2720.0, 180.0), Vector2(2800.0, 180.0),
	]
	for cp in coin_positions:
		_spawn_coin(cp)

	# ── Checkpoints ────────────────────────────────────────────────────────────
	_spawn_checkpoint(Vector2(800.0,  160.0), "cp_01")
	_spawn_checkpoint(Vector2(1700.0, 180.0), "cp_02")
	_spawn_checkpoint(Vector2(2500.0, 240.0), "cp_03")

	# ── Spikes ────────────────────────────────────────────────────────────────
	_spawn_spike(Vector2(700.0,  480.0))
	_spawn_spike(Vector2(1350.0, 480.0))
	_spawn_spike(Vector2(1950.0, 480.0))
	_spawn_spike(Vector2(2550.0, 480.0))

	# ── Moving platforms ──────────────────────────────────────────────────────
	_spawn_moving_platform(Vector2(1100.0, 330.0))
	_spawn_moving_platform(Vector2(1850.0, 350.0))
	_spawn_moving_platform(Vector2(2350.0, 300.0))

	# ── Falling platforms ─────────────────────────────────────────────────────
	_spawn_falling_platform(Vector2(470.0,  390.0))
	_spawn_falling_platform(Vector2(1580.0, 330.0))
	_spawn_falling_platform(Vector2(2650.0, 320.0))

	# ── World exit ────────────────────────────────────────────────────────────
	_create_world_exit(Vector2(2900.0, 400.0))

# ---------------------------------------------------------------------------
# Background
# ---------------------------------------------------------------------------
func _create_background() -> void:
	# Sky gradient strips (4 horizontal bands)
	var bands: Array = [
		[Color(0.10, 0.28, 0.72), -700],
		[Color(0.18, 0.44, 0.86), -350],
		[Color(0.34, 0.62, 0.96),    0],
		[Color(0.58, 0.82, 1.00),  350],
	]
	for b in bands:
		var strip := ColorRect.new()
		strip.size = Vector2(4500, 400)
		strip.position = Vector2(-500, b[1])
		strip.color = b[0]
		strip.z_index = -20
		add_child(strip)

	# Earth fill below ground
	var earth := ColorRect.new()
	earth.size = Vector2(4500, 800)
	earth.position = Vector2(-500, 530)
	earth.color = Color(0.30, 0.18, 0.08)
	earth.z_index = -20
	add_child(earth)

	# Clouds (SVG sprites)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for _i in 10:
		var cloud := Sprite2D.new()
		cloud.texture = CLOUD_TEX
		var sc: float = rng.randf_range(0.7, 1.4)
		cloud.scale = Vector2(sc, sc)
		cloud.modulate = Color(1.0, 1.0, 1.0, rng.randf_range(0.55, 0.88))
		cloud.position = Vector2(rng.randf_range(-50, 2900), rng.randf_range(-560, -80))
		cloud.z_index = -16
		add_child(cloud)

	# Trees along the ground
	rng.seed = 200
	for _i in 14:
		var tree := Sprite2D.new()
		tree.texture = TREE_TEX
		var sc2: float = rng.randf_range(0.6, 1.1)
		tree.scale = Vector2(sc2, sc2)
		tree.position = Vector2(rng.randf_range(-100, 2950), 445.0)
		tree.z_index = -14
		add_child(tree)

# ---------------------------------------------------------------------------
# Platform factory
# ---------------------------------------------------------------------------
func _create_platform(pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = pos
	add_child(body)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)

	# Main body
	var visual: ColorRect = ColorRect.new()
	visual.color = color
	visual.size = size
	visual.position = -size * 0.5
	body.add_child(visual)

	# Top highlight (grass/shine effect)
	var hi := ColorRect.new()
	hi.color = Color(minf(color.r + 0.28, 1.0), minf(color.g + 0.28, 1.0), minf(color.b + 0.28, 1.0), 0.95)
	hi.size = Vector2(size.x, 5)
	hi.position = Vector2(-size.x * 0.5, -size.y * 0.5)
	body.add_child(hi)

	# Bottom shadow
	var sh := ColorRect.new()
	sh.color = Color(maxf(color.r - 0.18, 0.0), maxf(color.g - 0.18, 0.0), maxf(color.b - 0.18, 0.0))
	sh.size = Vector2(size.x, 5)
	sh.position = Vector2(-size.x * 0.5, size.y * 0.5 - 5)
	body.add_child(sh)

	return body

# ---------------------------------------------------------------------------
# Spawners
# ---------------------------------------------------------------------------
func _spawn_coin(pos: Vector2) -> void:
	var coin: Node2D = COIN_SCENE.instantiate()
	coin.position = pos
	add_child(coin)

func _spawn_checkpoint(pos: Vector2, id: String) -> void:
	var cp: Node2D = CHECKPOINT_SCENE.instantiate()
	cp.position = pos
	if cp.has_method("set") and "checkpoint_id" in cp:
		cp.checkpoint_id = id
	add_child(cp)

func _spawn_spike(pos: Vector2) -> void:
	var spike: Node2D = SPIKE_SCENE.instantiate()
	spike.position = pos
	add_child(spike)

func _spawn_moving_platform(pos: Vector2) -> void:
	var mp: Node2D = MOVING_PLATFORM_SCENE.instantiate()
	mp.position = pos
	add_child(mp)

func _spawn_falling_platform(pos: Vector2) -> void:
	var fp: Node2D = FALLING_PLATFORM_SCENE.instantiate()
	fp.position = pos
	add_child(fp)

# ---------------------------------------------------------------------------
# World exit
# ---------------------------------------------------------------------------
func _create_world_exit(pos: Vector2) -> void:
	var area: Area2D = Area2D.new()
	area.position = pos
	area.collision_mask = 2   # detect Player layer
	area.monitoring = true
	add_child(area)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(80.0, 120.0)
	shape.shape = rect
	area.add_child(shape)

	# Visual
	var visual: ColorRect = ColorRect.new()
	visual.color = Color(1.0, 0.9, 0.1)
	visual.size = Vector2(80.0, 120.0)
	visual.position = Vector2(-40.0, -60.0)
	area.add_child(visual)

	# Label
	var lbl: Label = Label.new()
	lbl.text = "BİTİŞ"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(0.1, 0.05, 0.0))
	lbl.position = Vector2(-40.0, -65.0)
	lbl.size = Vector2(80.0, 30.0)
	area.add_child(lbl)

	# Connection — captures area to avoid duplicate signals
	area.body_entered.connect(_on_exit_body_entered)

func _on_exit_body_entered(body: Node2D) -> void:
	if body is Player:
		_complete_world()

func _complete_world() -> void:
	VillainDialog.show_dialog("world_complete")
	GameManager.unlock_next_world()
	SaveSystem.set_checkpoint(Vector2.ZERO)  # clear checkpoint for next world
	await get_tree().create_timer(3.0).timeout
	GameManager.go_to_main_menu()

# ---------------------------------------------------------------------------
# Player spawn
# ---------------------------------------------------------------------------
func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.position = Vector2(100.0, 400.0)
	add_child(player)

	# Respawn at checkpoint if one was saved
	var saved_cp: Vector2 = SaveSystem.get_checkpoint()
	if saved_cp != Vector2.ZERO:
		player.global_position = saved_cp

	player.player_died.connect(_on_player_died)

	# Bind HUD if present
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("bind_player"):
		hud.bind_player(player)
		hud.set_world_name("Normal Dünya")

func _on_player_died() -> void:
	await get_tree().create_timer(2.0).timeout
	GameManager.restart_world()

func _spawn_ui() -> void:
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	add_child(hud)
	hud.set_world_name("Normal Dünya")
	if player != null:
		hud.bind_player(player)
	add_child(CONTROLS_SCENE.instantiate())
