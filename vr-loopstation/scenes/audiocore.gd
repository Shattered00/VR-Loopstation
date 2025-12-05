extends MeshInstance3D

@export var AudioBlock: AudioStreamPlayer3D
@export var Play: AudioStreamPlayer3D

var effect: AudioEffectRecord
var recording: AudioStreamWAV
var idx: int

func _ready():
	idx = AudioServer.get_bus_index(&"RecordBus")
	effect = AudioServer.get_bus_effect(idx, 0) as AudioEffectRecord


func _on_area_3d_area_entered(_area):

	# STOP RECORDING → PLAY
	if effect.is_recording_active():
		effect.set_recording_active(false)
		print("Recording stopped.")

		recording = effect.get_recording()

		if recording:
			# Set loop BEFORE playback
			AudioBlock.stream = recording
			AudioBlock.play()
			print("Playing looped recording.")
		
		return  

	# START RECORDING
	print("Recording...")
	AudioBlock.stop()
	effect.set_recording_active(true)
