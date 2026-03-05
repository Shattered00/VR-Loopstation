extends Node3D

var hand: Node3D = null
var grab_offset: float = 0.0
var start_local: float = 0.0
var end_local: float = 0.0
var previous_value: float = -1.0

@export var value: float = 0.8
@export var height: float = 0.3
@export var min_value: float = 0.0
@export var max_value: float = 1.0

@onready var collision_shape: CollisionShape3D = $grab/CollisionShape3D
var default_shape_size: Vector3

var _record_button = null

signal value_changed(new_value: float)

func _ready() -> void:
	_record_button = get_parent().get_node_or_null("Record Button")

	start_local = $grab.position.y
	end_local = start_local + height

	var y = remap(value, min_value, max_value, start_local, end_local)
	$grab.position.y = y
	previous_value = value
	default_shape_size = collision_shape.shape.size

	_apply_volume(value)


func _apply_volume(v: float) -> void:
	if _record_button:
		_record_button.set_volume(v)


func _on_grab_area_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	if hand:
		return
	collision_shape.shape.size.y = default_shape_size.y * 5.0
	collision_shape.shape.size.x = default_shape_size.x * 3.0
	collision_shape.shape.size.z = default_shape_size.z * 3.0
	var node = area
	for i in range(5):
		if node.get_parent():
			node = node.get_parent()
		else:
			break
	hand = node
	var hand_local_y = to_local(hand.global_position).y
	grab_offset = $grab.position.y - hand_local_y


func _on_grab_area_exited(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	collision_shape.shape.size = default_shape_size
	hand = null


func _process(_delta: float) -> void:
	if hand:
		var hand_local_y = to_local(hand.global_position).y
		var new_y = hand_local_y + grab_offset
		$grab.position.y = clamp(new_y, start_local, end_local)

	value = remap($grab.position.y, start_local, end_local, min_value, max_value)
	value = clamp(value, min_value, max_value)

	if abs(value - previous_value) > 0.001:
		value_changed.emit(value)
		_apply_volume(value)
		previous_value = value
