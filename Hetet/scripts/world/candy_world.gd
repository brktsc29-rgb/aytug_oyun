extends Node2D

# ---------------------------------------------------------------------------
# Candy World — harder level with melting floors, rotating obstacles, lasers.
# Completing this world unlocks the Boss World.
# ---------------------------------------------------------------------------

const PLAYER_SCENE:            PackedScene = preload("res://scenes/player/Player.tscn")
const COIN_SCENE:              PackedScene = preload("res://scenes/objects/Coin.tscn")
const CHECKPOINT_SCENE:        PackedScene = preload("res://scenes/objects/Checkpoint.tscn")
const SPIKE_SCENE:             PackedScene = preload("res://scenes/traps/Spike.tscn")
const MOVING_PLATFORM_SCENE:   PackedScene = preload("res://scenes/traps/MovingPlatform.tscn")
const FALLING_PLATFORM_SCENE:  PackedScene = preload("res://scenes/traps/FallingPlatform.tscn")
const CANDY_PLATFORM_SCENE:    PackedScene = preload("res://scenes/traps/CandyPlatform.tscn")
const ROTATING_OBSTACLE_SCENE: PackedScene = preload("res://scenes/traps/RotatingObstacle.tscn")
const TIMED_LASER_SCENE:       PackedScene = preload("res://scenes/traps/TimedLaser.tscn")

# Candy / pastel colour palette
const _COLOR_GROUND:    Color = Color(1.0,  0.75, 0.87)   # rose pink
const _COLOR_PLATFORM:  Color = Color(1.0,  0.7,  0.85)   # soft candy pink
const _COLOR_PLATFORM2: Color = Color(0.72, 0.88, 1.0)    # baby blue
const _COLOR_PLATFORM3: Color = Color(0.85, 1.0,  0.72)   # mint green

var player: Player = null

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	VillainDialog.show_dialog("candy_world")
	_generate_level()
	_spawn_player()

# ---------------------------------------------------------------------------
# Level generation — tighter, harder, candy-themed
# ---------------------------------------------------------------------------
func _generate_level() -> void:
	_create_background()

	# ── Ground strip (thinner, trickier) ─────────────────────────────────────
	_create_platform(Vector2(-200.0, 540.0), Vector2(600.0, 60.0), _COLOR_GROUND)
	# Mid-level floor islands
	_create_platform(Vector2(2000.0, 540.0), Vector2(400.0, 60.0), _COLOR_GROUND)
	_create_platform(Vector2(3600.0, 540.0), Vector2(500.0, 60.0), _COLOR_GROUND)

	# ── Normal candy-coloured platforms ──────────────────────────────────────
	# Grouped in colour bands so the world feels like distinct candy zones.
	var normal_platforms: Array[Dictionary] = [
		# Zone 1 — Sugar Rush (tight vertical climbing)
		{"pos": Vector2(340.0,  420.0), "size": Vector2(110.0, 22.0), "col": _COLOR_PLATFORM},
		{"pos": Vector2(520.0,  340.0), "size": Vector2( 90.0, 22.0), "col": _COLOR_PLATFORM2},
		{"pos": Vector2(680.0,  270.0), "size": Vector2(110.0, 22.0), "col": _COLOR_PLATFORM},
		{"pos": Vector2(830.0,  200.0), "size": Vector2( 90.0, 22.0), "col": _COLOR_PLATFORM3},
		{"pos": Vector2(990.0,  140.0), "size": Vector2(100.0, 22.0), "col": _COLOR_PLATFORM2},
		# Zone 2 — Bubblegum Bridge (wider gaps)
		{"pos": Vector2(1180.0, 220.0), "size": Vector2( 80.0, 22.0), "col": _COLOR_PLATFORM},
		{"pos": Vector2(1360.0, 310.0), "size": Vector2( 90.0, 22.0), "col": _COLOR_PLATFORM3},
		{"pos": Vector2(1520.0, 240.0), "size": Vector2( 80.0, 22.0), "col": _COLOR_PLATFORM2},
		{"pos": Vector2(1680.0, 170.0), "size": Vector2(100.0, 22.0), "col": _COLOR_PLATFORM},
		{"pos": Vector2(1830.0, 100.0), "size": Vector2( 80.0, 22.0), "col": _COLOR_PLATFORM3},
		# Zone 3 — Caramel Cliffs
		{"pos": Vector2(2180.0, 430.0), "size": Vector2(120.0, 22.0), "col": _COLOR_PLATFORM},
		{"pos": Vector2(2360.0, 350.0), "size": Vector2( 90.0, 22.0), "col": _COLOR_PLATFORM2},
		{"pos": Vector2(2510.0, 280.0), "size": Vector2( 80.0, 22.0), "col": _COLOR_PLATFORM},
		{"pos": Vector2(2660.0, 200.0), "size": Vector2( 90.0, 22.0), "col": _COLOR_PLATFORM3},
		{"pos": Vector2(2810.0, 130.0), "size": Vector2(100.0, 22.0), "col": _COLOR_PLATFORM2},
		# Zone 4 — Final Sprint
		{"pos": Vector2(3000.0, 200.0), "size": Vector2( 90.0, 22.0), "col": _COLOR_PLATFORM},
		{"pos": Vector2(3160.0, 310.0), "size": Vector2( 80.0, 22.0), "col": _COLOR_PLATFORM3},
		{"pos": Vector2(3320.0, 240.0), "size": Vector2( 90.0, 22.0), "col": _COLOR_PLATFORM2},
		{"pos": Vector2(3480.0, 160.0), "size": Vector2(100.0, 22.0), "col": _COLOR_PLATFORM},
	]
	for pf in normal_platforms:
		_create_platform(pf["pos"], pf["size"], pf["col"])

	# ── Candy platforms (melt on contact) ────────────────────────────────────
	var candy_positions: Array[Vector2] = [
		Vector2(600.0,  480.0),
		Vector2(900.0,  400.0),
		Vector2(1100.0, 350.0),
		Vector2(1440.0, 400.0),
		Vector2(1750.0, 430.0),
		Vector2(2240.0, 490.0),
		Vector2(2600.0, 460.0),
		Vector2(2950.0, 470.0),
		Vector2(3200.0, 490.0),
	]
	for cp in candy_positions:
		_spawn_candy_platform(cp)

	# ── Coins — harder to reach, clustered high ───────────────────────────────
	var coin_positions: Array[Vector2] = [
		# Zone 1
		Vector2(360.0,  380.0), Vector2(430.0,  380.0),
		Vector2(540.0,  300.0),
		Vector2(700.0,  230.0), Vector2(760.0,  230.0),
		Vector2(850.0,  160.0), Vector2(920.0,  160.0),
		Vector2(1010.0, 100.0), Vector2(1070.0, 100.0),
		# Zone 2
		Vector2(1200.0, 180.0),
		Vector2(1380.0, 270.0), Vector2(1440.0, 270.0),
		Vector2(1540.0, 200.0),
		Vector2(1700.0, 130.0), Vector2(1760.0, 130.0),
		Vector2(1850.0,  60.0), Vector2(1910.0,  60.0),
		# Zone 3
		Vector2(2200.0, 390.0),
		Vector2(2380.0, 310.0), Vector2(2440.0, 310.0),
		Vector2(2530.0, 240.0),
		Vector2(2680.0, 160.0), Vector2(2740.0, 160.0),
		Vector2(2830.0,  90.0), Vector2(2890.0,  90.0),
		# Zone 4
		Vector2(3020.0, 160.0),
		Vector2(3180.0, 270.0),
		Vector2(3340.0, 200.0),
		Vector2(3500.0, 120.0), Vector2(3560.0, 120.0),
	]
	for cv in coin_positions:
		_spawn_coin(cv)

	# ── Checkpoints ─────────────────────────────────────────────────────────
	_spawn_checkpoint(Vector2(1000.0, 100.0),  "candy_cp_01")
	_spawn_checkpoint(Vector2(1850.0,  60.0),  "candy_cp_02")
	_spawn_checkpoint(Vector2(2820.0,  90.0),  "candy_cp_03")
	_spawn_checkpoint(Vector2(3480.0, 120.0),  "candy_cp_04")

	# ── Spikes ───────────────────────────────────────────────────────────────
	_spawn_spike(Vector2(460.0,  520.0))
	_spawn_spike(Vector2(750.0,  520.0))
	_spawn_spike(Vector2(1050.0, 520.0))
	_spawn_spike(Vector2(1300.0, 520.0))
	_spawn_spike(Vector2(1620.0, 520.0))
	_spawn_spike(Vector2(1950.0, 520.0))

	# ── Moving platforms ─────────────────────────────────────────────────────
	_spawn_moving_platform(Vector2(1280.0, 260.0), Vector2(0.0,   80.0), 1.4)  # vertical
	_spawn_moving_platform(Vector2(1950.0, 400.0), Vector2(160.0,  0.0), 1.6)  # horizontal
	_spawn_moving_platform(Vector2(2700.0, 300.0), Vector2(0.0,  100.0), 1.2)  # vertical fast
	_spawn_moving_platform(Vector2(3100.0, 350.0), Vector2(140.0,  0.0), 1.0)  # horizontal fast

	# ── Falling platforms ────────────────────────────────────────────────────
	_spawn_falling_platform(Vector2(570.0,  360.0))
	_spawn_falling_platform(Vector2(1160.0, 310.0))
	_spawn_falling_platform(Vector2(1700.0, 360.0))
	_spawn_falling_platform(Vector2(2450.0, 340.0))
	_spawn_falling_platform(Vector2(3000.0, 370.0))

	# ── Rotating obstacles ───────────────────────────────────────────────────
	_spawn_rotating_obstacle(Vector2(780.0,  320.0), 2.5)
	_spawn_rotating_obstacle(Vector2(1480.0, 280.0), 3.0)
	_spawn_rotating_obstacle(Vector2(2200.0, 260.0), 3.5)
	_spawn_rotating_obstacle(Vector2(2900.0, 180.0), 4.0)

	# ── Timed lasers ──────────────────────────────────────────────────────────
	_spawn_timed_laser(Vector2(640.0,  440.0), 1.5, 1.0)
	_spawn_timed_laser(Vector2(1200.0, 360.0), 1.2, 0.8)
	_spawn_timed_laser(Vector2(1900.0, 420.0), 1.0, 1.5)
	_spawn_timed_laser(Vector2(2700.0, 380.0), 0.9, 1.1)
	_spawn_timed_laser(Vector2(3300.0, 400.0), 0.8, 0.8)

	# ── World exit ────────────────────────────────────────────────────────────
	_create_world_exit(Vector2(3750.0, 440.0))

# ---------------------------------------------------------------------------
# Background
# ---------------------------------------------------------------------------
func _create_background() -> void:
	# Candy sky — pink-to-light-lavender gradient
	var bands: Array = [
		[Color(0.78, 0.36, 0.85), -700],
		[Color(0.88, 0.54, 0.92), -350],
		[Color(0.95, 0.70, 0.96),    0],
		[Color(1.00, 0.86, 0.98),  350],
	]
	for b in bands:
		var strip := ColorRect.new()
		strip.size = Vector2(5200, 400)
		strip.position = Vector2(-500, b[1])
		strip.color = b[0]
		strip.z_index = -20
		add_child(strip)

	# Sugary ground fill
	var earth := ColorRect.new()
	earth.size = Vector2(5200, 600)
	earth.position = Vector2(-500, 520)
	earth.color = Color(0.68, 0.24, 0.42)
	earth.z_index = -20
	add_child(earth)

	# Candy cane poles in background
	var rng := RandomNumberGenerator.new()
	rng.seed = 321
	for _i in 10:
		var pole := ColorRect.new()
		pole.size = Vector2(14, 160)
		pole.position = Vector2(rng.randf_range(-100, 3800), rng.randf_range(340, 440))
		pole.color = Color(1.0, 0.22, 0.22, 0.72)
		pole.z_index = -15
		add_child(pole)

	# Floating candy dots (small circles)
	for _i in 18:
		var dot := ColorRect.new()
		var ds: float = rng.randf_range(8, 18)
		dot.size = Vector2(ds, ds)
		dot.position = Vector2(rng.randf_range(-100, 3900), rng.randf_range(-550, 300))
		dot.color = Color(
			rng.randf_range(0.8, 1.0),
			rng.randf_range(0.3, 0.8),
			rng.randf_range(0.4, 0.9),
			rng.randf_range(0.4, 0.7)
		)
		dot.z_index = -15
		add_child(dot)

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

	# Candy shine on top
	var hi := ColorRect.new()
	hi.color = Color(minf(color.r + 0.30, 1.0), minf(color.g + 0.30, 1.0), minf(color.b + 0.30, 1.0), 0.90)
	hi.size = Vector2(size.x, 5)
	hi.position = Vector2(-size.x * 0.5, -size.y * 0.5)
	body.add_child(hi)

	# Bottom shadow
	var sh := ColorRect.new()
	sh.color = Color(maxf(color.r - 0.20, 0.0), maxf(color.g - 0.20, 0.0), maxf(color.b - 0.20, 0.0))
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
	if "checkpoint_id" in cp:
		cp.checkpoint_id = id
	add_child(cp)

func _spawn_spike(pos: Vector2) -> void:
	var spike: Node2D = SPIKE_SCENE.instantiate()
	spike.position = pos
	add_child(spike)

func _spawn_moving_platform(pos: Vector2, offset: Vector2 = Vector2(200.0, 0.0), duration: float = 2.0) -> void:
	var mp: Node2D = MOVING_PLATFORM_SCENE.instantiate()
	mp.position = pos
	if "move_offset" in mp:
		mp.move_offset = offset
	if "move_time" in mp:
		mp.move_time = duration
	add_child(mp)

func _spawn_falling_platform(pos: Vector2) -> void:
	var fp: Node2D = FALLING_PLATFORM_SCENE.instantiate()
	fp.position = pos
	add_child(fp)

func _spawn_candy_platform(pos: Vector2) -> void:
	var cp: Node2D = CANDY_PLATFORM_SCENE.instantiate()
	cp.position = pos
	add_child(cp)

func _spawn_rotating_obstacle(pos: Vector2, rot_speed: float = 2.0) -> void:
	var ro: Node2D = ROTATING_OBSTACLE_SCENE.instantiate()
	ro.position = pos
	if "rotation_speed" in ro:
		ro.rotation_speed = rot_speed
	add_child(ro)

func _spawn_timed_laser(pos: Vector2, on_t: float = 2.0, off_t: float = 1.5) -> void:
	var laser: Node2D = TIMED_LASER_SCENE.instantiate()
	laser.position = pos
	if "on_time" in laser:
		laser.on_time = on_t
	if "off_time" in laser:
		laser.off_time = off_t
	add_child(laser)

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

	var visual: ColorRect = ColorRect.new()
	visual.color = Color(1.0, 0.9, 0.1)
	visual.size = Vector2(80.0, 120.0)
	visual.position = Vector2(-40.0, -60.0)
	area.add_child(visual)

	var lbl: Label = Label.new()
	lbl.text = "BİTİŞ"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(0.1, 0.05, 0.0))
	lbl.position = Vector2(-40.0, -65.0)
	lbl.size = Vector2(80.0, 30.0)
	area.add_child(lbl)

	area.body_entered.connect(_on_exit_body_entered)

func _on_exit_body_entered(body: Node2D) -> void:
	if body is Player:
		_complete_world()

func _complete_world() -> void:
	VillainDialog.show_dialog("world_complete")
	GameManager.unlock_next_world()
	SaveSystem.set_checkpoint(Vector2.ZERO)  # clear checkpoint for next world
	await get_tree().create_timer(3.0).timeout
	GameManager.load_world(2)

# ---------------------------------------------------------------------------
# Player spawn
# ---------------------------------------------------------------------------
func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.position = Vector2(80.0, 460.0)
	add_child(player)

	# Respawn at checkpoint if one was saved
	var saved_cp: Vector2 = SaveSystem.get_checkpoint()
	if saved_cp != Vector2.ZERO:
		player.global_position = saved_cp

	player.player_died.connect(_on_player_died)

	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("bind_player"):
		hud.bind_player(player)
		hud.set_world_name("Şeker Dünyası")

func _on_player_died() -> void:
	await get_tree().create_timer(2.0).timeout
	GameManager.restart_world()
