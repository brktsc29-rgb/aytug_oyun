extends Node
class_name LevelGenerator

## AI-ready procedural level generator for Hetet.
## Call generate_section(difficulty) to get a layout descriptor dictionary.
## All methods are stateless — safe to call from any context.

# ---------------------------------------------------------------------------
# Content pools
# ---------------------------------------------------------------------------

var trap_pool := [
	"spike",
	"rotating",
	"timed_laser",
	"crusher",
	"fake_platform",
	"falling",
]

var puzzle_pool := [
	"button",
	"memory",
	"path",
	"timed_door",
	"hidden_switch",
]

var platform_styles := [
	"normal",   # index 0
	"candy",    # index 1
	"ice",      # index 2
	"lava",     # index 3
]


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns a layout descriptor for one level section at the given difficulty.
## difficulty 0 = tutorial, 1-3 = normal, 4-6 = hard, 7+ = expert.
func generate_section(difficulty: int) -> Dictionary:
	var style_idx := clamp(difficulty / 3, 0, platform_styles.size() - 1)
	var trap_count := clamp(difficulty + 1, 1, 8)
	var puzzle_count := clamp(difficulty / 3, 0, 4)

	return {
		# Total horizontal length of the section in pixels
		"length":                    1200 + difficulty * 350,
		# Number of platforms to place (both static and moving)
		"platform_count":            5 + difficulty * 2,
		# How many traps to scatter
		"trap_count":                trap_count,
		# How many puzzle elements to include
		"puzzle_count":              puzzle_count,
		# Number of coins to distribute
		"coin_count":                15 + difficulty * 10,
		# Randomly sampled traps from the pool
		"traps":                     _pick_many(trap_pool, trap_count),
		# Randomly sampled puzzles from the pool
		"puzzles":                   _pick_many(puzzle_pool, puzzle_count),
		# Whether to include AnimatableBody2D moving platforms
		"has_moving_platforms":      difficulty >= 2,
		# Whether to include falling (crumbling) platforms
		"has_falling_platforms":     difficulty >= 3,
		# Visual theme for platforms and backgrounds
		"style":                     platform_styles[style_idx],
		# Place a checkpoint every N platforms so the player isn't set back too far
		"checkpoint_every_n_platforms": max(3, 8 - difficulty),
	}


## Returns a theme descriptor for AI-assisted world design.
## prompt can be a free-text description such as "underwater volcano temple".
func suggest_world_theme(prompt: String) -> Dictionary:
	# Base data; an AI service can extend or override these fields
	return {
		"prompt":                 prompt,
		"platform_style":         _pick_one(platform_styles),
		"background_palette":     ["dark", "vibrant", "muted"].pick_random(),
		"recommended_traps":      _pick_many(trap_pool, 3),
		"recommended_puzzles":    _pick_many(puzzle_pool, 2),
		"recommended_mechanics":  ["double_jump", "wall_jump", "dash"].slice(0, 1 + randi() % 3),
		"ambient_sfx":            "ambience_" + _pick_one(platform_styles),
		"ai_expansion_ready":     true,
	}


## Returns a layout descriptor specifically for the final boss arena.
func generate_boss_arena() -> Dictionary:
	return {
		"width":              1600.0,
		"height":             800.0,
		"floor_y":            700.0,
		"ceiling_y":          50.0,
		# Central floor platform the boss paces on
		"main_platform":      {"x": 100.0, "y": 680.0, "width": 1400.0, "height": 40.0},
		# Floating dodge platforms
		"dodge_platforms": [
			{"x": 200.0,  "y": 500.0, "width": 200.0, "height": 24.0},
			{"x": 550.0,  "y": 420.0, "width": 180.0, "height": 24.0},
			{"x": 900.0,  "y": 480.0, "width": 200.0, "height": 24.0},
			{"x": 1200.0, "y": 390.0, "width": 160.0, "height": 24.0},
		],
		"player_spawn":       Vector2(150.0, 620.0),
		"boss_spawn":         Vector2(1300.0, 580.0),
		"wall_thickness":     60.0,
		"style":              "lava",
		"has_moving_platforms": true,
		"coin_count":         0,  # no coins in the boss arena
	}


## Returns the effective difficulty integer for a given world and section index.
## world_id 1 = World 1 (tutorial), world_id 4 = final world.
func calculate_difficulty_for_world(world_id: int, section: int) -> int:
	# Each world contributes a base offset; sections scale within that world
	var base := (world_id - 1) * 3
	# Sections are 0-indexed; every 2 sections bump difficulty by 1
	var section_bonus := section / 2
	return base + section_bonus


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Picks count elements at random from pool (with replacement).
func _pick_many(pool: Array, count: int) -> Array:
	var out: Array = []
	if pool.is_empty() or count <= 0:
		return out
	for _i in range(count):
		out.append(pool[randi() % pool.size()])
	return out


## Picks a single random element from pool.
func _pick_one(pool: Array) -> String:
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]
