extends Node3D

var idle_color: Color
var record_color: Color
var play_color: Color

enum RState {IDLE, RECORDING, PLAYING}
var state = RState.IDLE

var effect: AudioEffectRecord
var recorded_stream: AudioStreamWAV

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
	
	var bus_idx = AudioServer.get_bus_index("Record")
	effect = AudioServer.get_bus_effect(bus_idx, 0)

func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	
	if state == RState.IDLE:
		effect.set_recording_active(true)
		state = RState.RECORDING
		$MeshInstance3D.get_surface_override_material(0).albedo_color = record_color
		recording_started.emit()
		
	elif state == RState.RECORDING:
		effect.set_recording_active(false)
		recorded_stream = effect.get_recording()
		recorded_stream.loop_mode = AudioStreamWAV.LoopMode.LOOP_FORWARD
		$AudioStreamPlayer.stream = recorded_stream
		$AudioStreamPlayer.play()
		state = RState.PLAYING
		$MeshInstance3D.get_surface_override_material(0).albedo_color = play_color
		recording_stopped.emit()
		playback_started.emit()
		
	elif state == RState.PLAYING:
		$AudioStreamPlayer.stop()
		recorded_stream = null
		state = RState.IDLE
		$MeshInstance3D.get_surface_override_material(0).albedo_color = idle_color
		playback_stopped.emit()

func _on_area_exited(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	pass
