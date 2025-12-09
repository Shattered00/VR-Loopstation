extends MeshInstance3D

var effect: AudioEffect
var recording: AudioStreamWAV


var stereo: bool = true
var mix_rate := 44100  # This is the default mix rate on recordings.
var format := AudioStreamWAV.FORMAT_16_BITS  # This is the default format on recordings.

func _ready() -> void:
	var idx := AudioServer.get_bus_index(&"RecordBus")
	effect = AudioServer.get_bus_effect(idx, 0) as AudioEffectRecord


func _on_area_3d_area_entered(_area):
	# STOP RECORDING
	if effect.is_recording_active():
		effect.set_recording_active(false)
		print("Recording stopped.")

		recording = effect.get_recording()
	else:
		effect.set_recording_active(true)
		$".".get_active_material(0).albedo_color = Color(1, 0, 0)
		print("Status Recording")
		
		if recording:
			$".".get_active_material(0).albedo_color = Color(0, 1, 0)
			print_rich("\n[b]Playing recording:[/b] %s" % recording)
			print_rich("[b]Format:[/b] %s" % ("8-bit uncompressed" if recording.format == 0 else "16-bit uncompressed" if recording.format == 1 else "IMA ADPCM compressed"))
			print_rich("[b]Stereo:[/b] %s" % ("Yes" if recording.stereo else "No"))
			var data := recording.get_data()
			print_rich("[b]Size:[/b] %s bytes" % data.size())
			print("Playing looped recording.")
			$Area3D/AudioStreamPlayer3D.stream = recording
			$Area3D/AudioStreamPlayer3D.play()
