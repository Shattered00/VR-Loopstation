extends Area3D

var _trigger_items := {}
var _hold_timer: SceneTreeTimer = null
var _track_paused := false

func _ready() -> void:
	pass
# Finger enters button area
func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return

	var was_empty = _trigger_items.is_empty()
	_trigger_items[area] = area

	if not was_empty:
		return

	var rb = get_parent().get_node("Record Button")
	if _track_paused:
		_track_paused = false
		rb.resume()
	else:
		_track_paused = true
		rb.pause()

	_hold_timer = get_tree().create_timer(2.0)
	_hold_timer.timeout.connect(_on_hold_complete)

# Hold for 2 seconds, clear the track
func _on_hold_complete() -> void:
	if not _trigger_items.is_empty():
		_trigger_items.clear()
		_track_paused = false
		get_parent().get_node("Record Button").stop()

# Finger leaves area, button remains paused
func _on_area_exited(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	_trigger_items.erase(area)
	if _trigger_items.is_empty():
		_hold_timer = null
