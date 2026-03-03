extends Node3D

var idle_color: Color
var record_color: Color
var play_color: Color

enum RState {IDLE, RECORDING, PLAYING}
var state = RState.IDLE

var recorded_frames: PackedVector2Array = []
var _playback_position := 0
var _playback: AudioStreamGeneratorPlayback = null
var _in_contact := false

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
	_playback = $AudioStreamPlayer.get_stream_playback()

	AudioServer.set_input_device_active(true)

func _process(_delta) -> void:
	# Always drain mic input buffer
	var available = AudioServer.get_input_frames_available()
	if available > 0:
		var frames = AudioServer.get_input_frames(available)
		if state == RState.RECORDING:
			recorded_frames.append_array(frames)

	# Push recorded frames back through the generator for looped playback
	if state == RState.PLAYING and not recorded_frames.is_empty():
		var to_fill = _playback.get_frames_available()
		if to_fill > 0:
			var chunk := PackedVector2Array()
			chunk.resize(to_fill)
			for i in to_fill:
				chunk[i] = recorded_frames[_playback_position % recorded_frames.size()]
				_playback_position += 1
			_playback.push_buffer(chunk)

func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	if _in_contact:
		return
	_in_contact = true

	if state == RState.IDLE:
		recorded_frames.clear()
		_playback_position = 0
		state = RState.RECORDING
		$MeshInstance3D.get_surface_override_material(0).albedo_color = record_color
		recording_started.emit()

	elif state == RState.RECORDING:
		_playback_position = 0
		state = RState.PLAYING
		$MeshInstance3D.get_surface_override_material(0).albedo_color = play_color
		recording_stopped.emit()
		playback_started.emit()

func _on_area_exited(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	_in_contact = false
