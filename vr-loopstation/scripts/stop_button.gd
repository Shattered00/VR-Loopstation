extends Area3D

## Dictionary of finger tips currently in contact (same pattern as XRToolsInteractableAreaButton)
var _trigger_items := {}
var _hold_timer: SceneTreeTimer = null
var _track_paused := false  # true when WE have paused the track

func _ready() -> void:
	pass

func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return

	# Only act on the transition: no contact → first contact
	var was_empty = _trigger_items.is_empty()
	_trigger_items[area] = area

	if not was_empty:
		return  # Already in contact, don't double-toggle

	var rb = get_parent().get_node("Record Button")
	if _track_paused:
		# Already paused — second touch resumes
		_track_paused = false
		rb.resume()
	else:
		# First touch — pause
		_track_paused = true
		rb.pause()

	# Arm hold timer: 2s hold = clear
	_hold_timer = get_tree().create_timer(2.0)
	_hold_timer.timeout.connect(_on_hold_complete)

func _on_hold_complete() -> void:
	if not _trigger_items.is_empty():
		_trigger_items.clear()  # Reset so next touch is treated as fresh contact
		_track_paused = false
		get_parent().get_node("Record Button").stop()

func _on_area_exited(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	_trigger_items.erase(area)
	if _trigger_items.is_empty():
		_hold_timer = null
	# Do NOT resume here — pause state persists until next touch
