extends Node3D
class_name Trackholder

signal interacted(control: Trackholder, hand: Node)

@export var action_id: StringName

@onready var touch_area: Area3D = $Area3D
var _locked := false

func _ready():
	add_to_group(&"trackholder") 
	touch_area.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D):
	if _locked:
		return
	if not area.is_in_group(&"hands"):
		return

	interacted.emit(self, area)

	_locked = true
