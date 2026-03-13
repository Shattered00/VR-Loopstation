extends Area3D

var _nearby_hands: Array = []
var _held_by = null
var _hold_offset: Transform3D
var _base_scale: Vector3

@onready var _collision: CollisionShape3D = $CollisionShape3D

func _ready():
	_base_scale = _collision.scale
	
# Finger enters grab area, find the owning hand and remember it
func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	var hand = _find_hand(area)
	if hand and hand not in _nearby_hands:
		_nearby_hands.append(hand)

# Finger leaves grab area, forget the hand unless we are holding it
func _on_area_exited(area: Area3D) -> void:
	if not area.is_in_group("finger_tip"):
		return
	var hand = _find_hand(area)
	if hand and hand != _held_by:
		_nearby_hands.erase(hand)

func _process(_delta) -> void:
	if _held_by:
		if _held_by.gesture != "Fist":
			_release()
			return
		get_parent().global_transform = _held_by.global_transform * _hold_offset
		return
	for hand in _nearby_hands:
		if hand.gesture == "Fist":
			_grab(hand)
			return

# Start grab, record offset and expand collision so the hold feels fluid
func _grab(hand) -> void:
	_held_by = hand
	_hold_offset = hand.global_transform.inverse() * get_parent().global_transform
	_collision.scale = _base_scale * 2.0

# Release the trackholder and restore the collision size
func _release() -> void:
	_nearby_hands.erase(_held_by)
	_held_by = null
	_collision.scale = _base_scale

# Walk up the tree from the finger tip area to find the hand node
func _find_hand(area: Area3D) -> Node:
	var node = area.get_parent()
	while node:
		if node.is_in_group("hands"):
			return node
		node = node.get_parent()
	return null
