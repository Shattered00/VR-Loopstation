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
var _layer_record_start_sample: int = 0

signal recording_started
signal recording_stopped
signal playback_started
signal playback_stopped

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
	add_to_group("record_buttons")

func receive_mic_frames(frames: PackedVector2Array) -> void:
	if state == RState.RECORDING:
		recorded_frames.append_array(frames)
		if _master_sample_count > 0 and recorded_frames.size() >= _master_sample_count:
			_finish_recording()

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
		_finish_recording()

	elif state == RState.PLAYING:
		var mix_rate = float(AudioServer.get_input_mix_rate())
		var master_duration = _master_sample_count / mix_rate
		var elapsed = fmod(Time.get_ticks_msec() / 1000.0 - _master_start_time, master_duration)
		_layer_record_start_sample = int(elapsed * mix_rate)
		recorded_frames.clear()
		state = RState.RECORDING
		$MeshInstance3D.get_surface_override_material(0).albedo_color = record_color
		recording_started.emit()

# Shared logic for ending a recording, whether triggered by tap or auto-end
func _finish_recording() -> void:
	state = RState.PLAYING
	$MeshInstance3D.get_surface_override_material(0).albedo_color = play_color
	recording_stopped.emit()
	_bake_thread = Thread.new()
	_bake_thread.start(_bake_wav)

func _on_area_exited(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	_in_contact = false

# Runs on a background thread
# Converts recorded mic frames into a looping WAV at the correct sample rate
# First layer sets the master length
# Later layers are placed at their exact loop position using silence padding
func _bake_wav() -> void:
	var frames = recorded_frames.duplicate()
	var layer_start = _layer_record_start_sample

	if frames.is_empty():
		return

	var mix_rate = AudioServer.get_input_mix_rate()
	var is_master = _master_sample_count == 0

	if is_master:
		_master_sample_count = frames.size()

	var new_wav = AudioStreamWAV.new()
	new_wav.mix_rate = mix_rate
	new_wav.stereo = true
	new_wav.format = AudioStreamWAV.FORMAT_16_BITS
	new_wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	new_wav.loop_begin = 0
	new_wav.loop_end = _master_sample_count

	var byte_array = PackedByteArray()
	byte_array.resize(_master_sample_count * 4)

	if is_master:
		for i in _master_sample_count:
			var left  = int(clamp(frames[i].x, -1.0, 1.0) * 32767)
			var right = int(clamp(frames[i].y, -1.0, 1.0) * 32767)
			byte_array.encode_s16(i * 4,     left)
			byte_array.encode_s16(i * 4 + 2, right)
	else:
		var write_count = min(frames.size(), _master_sample_count)
		for i in write_count:
			var wav_idx = (layer_start + i) % _master_sample_count
			var left  = int(clamp(frames[i].x, -1.0, 1.0) * 32767)
			var right = int(clamp(frames[i].y, -1.0, 1.0) * 32767)
			byte_array.encode_s16(wav_idx * 4,     left)
			byte_array.encode_s16(wav_idx * 4 + 2, right)

	new_wav.data = byte_array
	call_deferred("_start_playback", new_wav, is_master)

func pause() -> void:
	_is_paused = true
	for player in _layers:
		player.stream_paused = true

# Restart all layers from the top of the loop in sync
func resume() -> void:
	_is_paused = false
	var slider = get_parent().get_node_or_null("AudioSlider")
	var db = 0.0
	if slider:
		var v = slider.value
		db = -80.0 if v <= 0.001 else linear_to_db(v)
	_master_start_time = Time.get_ticks_msec() / 1000.0
	for player in _layers:
		player.volume_db = db
		player.play(0)

# Stop all layers, reset everything back to idle, restart the mic
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

# Returns 0.0 to 1.0 showing how far into the loop
func get_loop_progress() -> float:
	if _master_sample_count == 0 or state == RState.IDLE:
		return 0.0
	var duration = _master_sample_count / float(AudioServer.get_input_mix_rate())
	return fmod(Time.get_ticks_msec() / 1000.0 - _master_start_time, duration) / duration

func set_volume(v: float) -> void:
	var db = -80.0 if v <= 0.001 else linear_to_db(v)
	for player in _layers:
		player.volume_db = db

# Starts playback and syncs new layers to the master loop position
func _start_playback(new_wav: AudioStreamWAV, is_master: bool) -> void:
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

	var slider = get_parent().get_node_or_null("AudioSlider")
	if slider:
		var v = slider.value
		player.volume_db = -80.0 if v <= 0.001 else linear_to_db(v)
	else:
		player.volume_db = 0.0

	if is_master:
		player.play()
	else:
		var master_duration = _master_sample_count / float(AudioServer.get_input_mix_rate())
		var elapsed = fmod(Time.get_ticks_msec() / 1000.0 - _master_start_time, master_duration)
		player.play(elapsed)

	if _is_paused:
		player.stream_paused = true

	playback_started.emit()
