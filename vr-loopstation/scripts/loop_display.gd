extends Node3D

# Should match the visual width of the track holder body
@export var bar_width: float = 1.0

@onready var _marker: MeshInstance3D = $MeshInstance3D
var _record_button: Node
var _showing := false

# Apply red glowing material and hide the marker on start
func _ready() -> void:
	_record_button = get_parent().get_node("Record Button")
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0)
	mat.emission_enabled = true
	mat.emission = Color(1, 0, 0)
	_marker.set_surface_override_material(0, mat)
	_marker.visible = false

# Show and grow the bar once a master loop exists
# Hidden during idle and while recording the very first loop
func _process(_delta) -> void:
	var rb = _record_button
	var is_first_recording = rb.state == rb.RState.RECORDING and rb._master_sample_count == 0
	var should_show = rb.state != rb.RState.IDLE and not is_first_recording

	if should_show != _showing:
		_marker.visible = should_show
		_showing = should_show

	if not should_show:
		return

	if rb._is_paused:
		return

	var t = rb.get_loop_progress()
	_marker.scale.x = max(t, 0.0001)
	_marker.position.x = lerp(-bar_width / 2.0, 0.0, t)
