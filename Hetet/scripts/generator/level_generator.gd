extends Node
class_name LevelGenerator

var trap_pool := ["spike", "laser", "crusher", "fake_platform"]
var puzzle_pool := ["button", "memory", "path", "timed_door"]

func generate_section(difficulty: int) -> Dictionary:
	var trap_count := clamp(difficulty + 1, 2, 8)
	var puzzle_count := clamp(difficulty / 2, 1, 4)
	return {
		"length": 1200 + difficulty * 300,
		"traps": _pick_many(trap_pool, trap_count),
		"puzzles": _pick_many(puzzle_pool, puzzle_count),
		"coins": 20 + difficulty * 8
	}

func suggest_world_theme(prompt: String) -> Dictionary:
	return {
		"theme": prompt,
		"platform_style": "cartoon",
		"recommended_mechanics": ["double_jump", "moving_platforms", "hidden_switches"]
	}

func _pick_many(pool: Array, count: int) -> Array:
	var out: Array = []
	for i in range(count):
		out.append(pool[randi() % pool.size()])
	return out
