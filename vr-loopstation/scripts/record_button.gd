extends Area3D

var idle_color: Color
var record_color: Color
var play_color: Color

enum RState {IDLE, RECORDING, PLAYING}
var state = RState.IDLE

var recorded_frames: PackedVector2Array = []
var _in_contact := false

var _bake_thread: Thread = null
var _is_paused := false

# All active audio layers on this track
var _layers: Array[AudioStreamPlayer] = []
var _master_sample_count: int = 0
var _master_start_time: float = 0.0

signal recording_started
signal recording_stopped
signal playback_started
signal playback_stopped

# Set up button colours, mic input, and the generator used to drain the mic buffer
func _ready() -> void:
	idle_color = Color(0.2, 0.2, 0.2, 1)
	record_color = Color(1, 0, 0, 1)
	play_color = Color(0, 1, 0, 1)

	var mat = $MeshInstance3D.get_surface_override_material(0)
	mat = mat.duplicate()
	mat.albedo_color = idle_color
	$MeshInstance3D.set_surface_override_material(0, mat)

	var gen = AudioStreamGenerator.new()
	gen.mix_rate = AudioServer.get_input_mix_rate()
	gen.buffer_length = 0.1
	$AudioStreamPlayer.stream = gen
	$AudioStreamPlayer.play()

	AudioServer.set_input_device_active(true)

# Every frame, pull mic frames out of the buffer.
# Only save them when actively recording.
func _process(_delta) -> void:
	var available = AudioServer.get_input_frames_available()
	if available > 0:
		var frames = AudioServer.get_input_frames(available)
		if state == RState.RECORDING:
			recorded_frames.append_array(frames)

# Finger touches the button:
# IDLE -> start recording
# RECORDING -> stop recording and bake to WAV
# PLAYING -> keep layers playing and start recording a new layer on top
func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	if _in_contact:
		return
	_in_contact = true

	if state == RState.IDLE:
		_is_paused = false
		recorded_frames.clear()
		state = RState.RECORDING
		$MeshInstance3D.get_surface_override_material(0).albedo_color = record_color
		recording_started.emit()

	elif state == RState.RECORDING:
		state = RState.PLAYING
		$MeshInstance3D.get_surface_override_material(0).albedo_color = play_color
		recording_stopped.emit()
		_bake_thread = Thread.new()
		_bake_thread.start(_bake_wav)

	elif state == RState.PLAYING:
		recorded_frames.clear()
		state = RState.RECORDING
		$MeshInstance3D.get_surface_override_material(0).albedo_color = record_color
		recording_started.emit()

func _on_area_exited(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	_in_contact = false

# Runs on a background thread.
# Converts recorded mic frames into a looping WAV at the correct sample rate.
# First layer sets the master length. Later layers are trimmed or padded to match.
func _bake_wav() -> void:
	if recorded_frames.is_empty():
		return
	var mix_rate = AudioServer.get_input_mix_rate()
	var is_master = _master_sample_count == 0

	if is_master:
		_master_sample_count = recorded_frames.size()
	else:
		recorded_frames.resize(_master_sample_count)

	var new_wav = AudioStreamWAV.new()
	new_wav.mix_rate = mix_rate
	new_wav.stereo = true
	new_wav.format = AudioStreamWAV.FORMAT_16_BITS
	new_wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	new_wav.loop_begin = 0
	new_wav.loop_end = _master_sample_count
	var byte_array = PackedByteArray()
	byte_array.resize(_master_sample_count * 4)
	for i in _master_sample_count:
		var left  = int(clamp(recorded_frames[i].x, -1.0, 1.0) * 32767)
		var right = int(clamp(recorded_frames[i].y, -1.0, 1.0) * 32767)
		byte_array.encode_s16(i * 4,     left)
		byte_array.encode_s16(i * 4 + 2, right)
	new_wav.data = byte_array
	call_deferred("_start_playback", new_wav, is_master)

# Mute all layers
func pause() -> void:
	_is_paused = true
	for player in _layers:
		player.volume_db = -80.0

# Unmute all layers and restart from the top of the loop
func resume() -> void:
	_is_paused = false
	var slider = get_parent().get_node_or_null("AudioSlider")
	var db = 0.0
	if slider:
		var v = slider.value
		db = -80.0 if v <= 0.001 else linear_to_db(v)
	for player in _layers:
		player.volume_db = db
		player.play()

# Stop all layers, reset everything back to idle, restart the mic drain generator
func stop() -> void:
	_is_paused = false
	if _bake_thread and _bake_thread.is_alive():
		_bake_thread.wait_to_finish()

	for player in _layers:
		player.stop()
		if player != $AudioStreamPlayer:
			player.queue_free()
	_layers.clear()

	_master_sample_count = 0
	_master_start_time = 0.0
	recorded_frames.clear()
	state = RState.IDLE
	$MeshInstance3D.get_surface_override_material(0).albedo_color = idle_color

	$AudioStreamPlayer.volume_db = 0.0
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = AudioServer.get_input_mix_rate()
	gen.buffer_length = 0.1
	$AudioStreamPlayer.stream = gen
	$AudioStreamPlayer.play()

	playback_stopped.emit()

# Set volume on all layers from the slider value
func set_volume(v: float) -> void:
	var db = -80.0 if v <= 0.001 else linear_to_db(v)
	for player in _layers:
		player.volume_db = db

# Called from the main thread once the bake is done.
# Starts playback and syncs new layers to the master loop position.
func _start_playback(new_wav: AudioStreamWAV, is_master: bool) -> void:
	# Bail if stop() was called while the bake was running
	if state == RState.IDLE:
		return

	if _bake_thread and _bake_thread.is_alive():
		_bake_thread.wait_to_finish()

	var player: AudioStreamPlayer
	if is_master:
		player = $AudioStreamPlayer
		_master_start_time = Time.get_ticks_msec() / 1000.0
	else:
		player = AudioStreamPlayer.new()
		add_child(player)

	_layers.append(player)
	player.stream = new_wav

	# Set volume from slider so it doesn't start muted from a previous pause
	var slider = get_parent().get_node_or_null("AudioSlider")
	if slider:
		var v = slider.value
		player.volume_db = -80.0 if v <= 0.001 else linear_to_db(v)
	else:
		player.volume_db = 0.0

	# If the stop button is still held, keep this layer muted
	if _is_paused:
		player.volume_db = -80.0

	if is_master:
		player.play()
	else:
		# Sync new layer to where the master loop currently is
		var master_duration = _master_sample_count / float(AudioServer.get_input_mix_rate())
		var elapsed = fmod(Time.get_ticks_msec() / 1000.0 - _master_start_time, master_duration)
		player.play(elapsed)

	playback_started.emit()
