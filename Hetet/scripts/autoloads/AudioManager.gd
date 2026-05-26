extends Node

# ---------------------------------------------------------------------------
# AudioManager — BGM and SFX controller for Hetet
# Register as autoload singleton "AudioManager" in Project Settings.
# Streams may be null (assets added later); all methods handle null gracefully.
# ---------------------------------------------------------------------------

const SFX_POOL_SIZE: int = 8
const FADE_DURATION: float = 0.5  # seconds for cross-fade

var _bgm: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_idx: int = 0

var music_enabled: bool = true
var sfx_enabled: bool = true

## Tracks the running BGM tween so it can be cancelled before starting a new one.
var _bgm_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# ── BGM player ────────────────────────────────────────────────────────
	_bgm = AudioStreamPlayer.new()
	_bgm.bus = "Master"
	_bgm.name = "BGM"
	add_child(_bgm)

	# ── SFX pool ──────────────────────────────────────────────────────────
	for i: int in SFX_POOL_SIZE:
		var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
		sfx_player.bus = "Master"
		sfx_player.name = "SFX_%d" % i
		add_child(sfx_player)
		_sfx_pool.append(sfx_player)


# ---------------------------------------------------------------------------
# Music
# ---------------------------------------------------------------------------

## Fades out any currently playing track, then fades in stream.
## Does nothing if stream is null or music is disabled.
func play_music(stream: AudioStream) -> void:
	if stream == null:
		push_warning("AudioManager.play_music: stream is null, skipping.")
		return
	if not music_enabled:
		return

	_cancel_bgm_tween()

	if _bgm.playing:
		# Fade out current, swap, fade in new.
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm, "volume_db", -80.0, FADE_DURATION)
		_bgm_tween.tween_callback(func() -> void:
			_bgm.stop()
			_bgm.stream = stream
			_bgm.volume_db = -80.0
			if music_enabled:
				_bgm.play()
				_fade_in_bgm()
		)
	else:
		_bgm.stream = stream
		_bgm.volume_db = -80.0
		_bgm.play()
		_fade_in_bgm()


## Fades out and stops the current background track.
func stop_music() -> void:
	if not _bgm.playing:
		return
	_cancel_bgm_tween()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm, "volume_db", -80.0, FADE_DURATION)
	_bgm_tween.tween_callback(_bgm.stop)


## Enables or disables music. Stops any playing track when set to false.
func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if not enabled:
		stop_music()


func _fade_in_bgm() -> void:
	_cancel_bgm_tween()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm, "volume_db", 0.0, FADE_DURATION)


func _cancel_bgm_tween() -> void:
	if _bgm_tween != null and _bgm_tween.is_valid():
		_bgm_tween.kill()
	_bgm_tween = null


# ---------------------------------------------------------------------------
# SFX
# ---------------------------------------------------------------------------

## Plays stream on the next available SFX pool slot (round-robin).
## Does nothing if stream is null or SFX are disabled.
func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		push_warning("AudioManager.play_sfx: stream is null, skipping.")
		return
	if not sfx_enabled:
		return

	var player: AudioStreamPlayer = _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % SFX_POOL_SIZE

	player.stream = stream
	player.volume_db = 0.0
	player.play()


## Enables or disables SFX. Stops all pool players when set to false.
func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	if not enabled:
		for player: AudioStreamPlayer in _sfx_pool:
			if player.playing:
				player.stop()
