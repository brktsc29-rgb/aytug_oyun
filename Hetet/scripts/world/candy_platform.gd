class_name CandyPlatform
extends AnimatableBody2D

# ---------------------------------------------------------------------------
# A platform that slowly melts when a Player stands on it.
# Color shifts from pink → red → transparent, then the node frees itself.
#
# Required scene layout:
#   CandyPlatform (AnimatableBody2D)
#     ├─ Visual (ColorRect)         — visual representation
#     └─ StandArea (Area2D)         — triggers on player contact
#          └─ CollisionShape2D
# ---------------------------------------------------------------------------

@export var melt_time: float = 3.0

const _COLOR_START: Color = Color(1.0, 0.6, 0.8)   # soft pink
const _COLOR_END: Color   = Color(1.0, 0.0, 0.0, 0.0)  # transparent red

@onready var visual: ColorRect = $Visual

var _melt_timer: float = 0.0
var _is_melting: bool  = false
var _original_color: Color = _COLOR_START

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	_original_color = _COLOR_START
	if is_instance_valid(visual):
		visual.color = _original_color

	# Connect stand area
	if has_node("StandArea"):
		($StandArea as Area2D).body_entered.connect(_on_body_entered)

# ---------------------------------------------------------------------------
# _physics_process
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not _is_melting:
		return

	_melt_timer += delta
	var progress: float = clampf(_melt_timer / melt_time, 0.0, 1.0)

	if is_instance_valid(visual):
		visual.color = _original_color.lerp(_COLOR_END, progress)

	if progress >= 1.0:
		queue_free()

# ---------------------------------------------------------------------------
# Signal handler
# ---------------------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	if body is Player and not _is_melting:
		_is_melting = true
		# AudioManager.play_sfx("melt")
