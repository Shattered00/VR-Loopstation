extends Node3D

var xr_interface: XRInterface
@onready var environment:Environment = $"WorldEnvironment".environment

func enable_passthrough() -> bool:
	if xr_interface and xr_interface.is_passthrough_supported():		
		return xr_interface.start_passthrough()
	else:
		var modes = xr_interface.get_supported_environment_blend_modes()
		if xr_interface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
			xr_interface.set_environment_blend_mode(xr_interface.XR_ENV_BLEND_MODE_ALPHA_BLEND)
			return true
		else:
			return false
			
func _ready():
	AudioServer.set_input_device_active(true)
	xr_interface = XRServer.primary_interface
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialised successfully")

		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		enable_passthrough()

	else:
		print("XR_Interface ok?: ", xr_interface != null)
		print("XR_Interface is initialised?: ", xr_interface.is_initialized())
		print("XR_Interface capabilities (0 is bad): ", xr_interface.get_capabilities())
		print("OpenXR not initialized, please check if your headset is connected")

# Read mic once per frame and push to every record button
func _process(_delta) -> void:
	var available = AudioServer.get_input_frames_available()
	if available == 0:
		return
	var frames = AudioServer.get_input_frames(available)
	for rb in get_tree().get_nodes_in_group("record_buttons"):
		rb.receive_mic_frames(frames)
