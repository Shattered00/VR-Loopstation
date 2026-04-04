extends Node3D
class_name Trackholder

@onready var _add_area:     Area3D = $Add/Area3D
@onready var _remove_area:  Area3D = $Remove/Area3D
@onready var _trackfx_area: Area3D = $TrackFX/Area3D

var bus_name: String = ""

var _add_ready:     bool = true
var _trackfx_ready: bool = true

static var _bus_counter: int = 0


func _ready() -> void:
	add_to_group("trackholders")
	_add_area.area_entered.connect(_on_add_entered)
	_add_area.area_exited.connect(_on_add_exited)
	_remove_area.area_entered.connect(_on_remove_entered)
	_trackfx_area.area_entered.connect(_on_trackfx_entered)
	_trackfx_area.area_exited.connect(_on_trackfx_exited)
	_create_bus()
	$"Record Button".set_track_bus(bus_name)


func _create_bus() -> void:
	_bus_counter += 1
	bus_name = "Track_%d" % _bus_counter
	AudioServer.add_bus()
	var idx := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _exit_tree() -> void:
	var tree := get_tree()
	if tree:
		var settings := tree.get_first_node_in_group("settings")
		if settings:
			settings.remove_track(self)
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.remove_bus(idx)


func _on_trackfx_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip") or not _trackfx_ready:
		return
	_trackfx_ready = false
	var settings := get_tree().get_first_node_in_group("settings")
	if settings:
		settings.open_fx_for_track(self)


func _on_trackfx_exited(area: Area3D) -> void:
	if area.is_in_group("finger_tip"):
		_trackfx_ready = true


# Spawn a new Trackholder to the right when finger touches Add
func _on_add_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip") or not _add_ready:
		return
	_add_ready = false
	var new_track = load("res://Objects/Trackholder.tscn").instantiate()
	get_parent().add_child(new_track)
	new_track.global_transform = global_transform
	new_track.global_position += global_transform.basis.x.normalized() * 0.7


# Allow Add to fire again once finger leaves
func _on_add_exited(area: Area3D) -> void:
	if area.is_in_group("finger_tip"):
		_add_ready = true


# Remove this Trackholder, but not if it is the last one
func _on_remove_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	if get_tree().get_nodes_in_group("trackholders").size() <= 1:
		return
	queue_free()
