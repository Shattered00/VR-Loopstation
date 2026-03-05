extends Node3D
class_name Trackholder

signal interacted(control: Trackholder, hand: Node)

@export var action_id: StringName

var _locked := false

func _ready():
	add_to_group(&"trackholder")

func _on_area_entered(area: Area3D):
	if _locked:
		return
	if not area.is_in_group(&"hands"):
		return

	interacted.emit(self, area)

	_locked = true


func _on_area_3d_area_entered(area):
	pass # Replace with function body.
