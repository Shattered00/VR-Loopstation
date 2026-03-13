extends Node3D
class_name Trackholder

@onready var _add_area: Area3D = $Add/Area3D
@onready var _remove_area: Area3D = $Remove/Area3D

var _add_ready := true

func _ready():
	add_to_group("trackholders")
	_add_area.area_entered.connect(_on_add_entered)
	_add_area.area_exited.connect(_on_add_exited)
	_remove_area.area_entered.connect(_on_remove_entered)

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
