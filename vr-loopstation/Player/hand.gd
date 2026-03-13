extends XRNode3D

var gesture: String = ""

func _ready():
	add_to_group("hands")

# Track the current hand pose
func _on_hand_pose_detector_pose_started(p_name: String) -> void:
	gesture = p_name

func _on_hand_pose_detector_pose_ended(p_name: String) -> void:
	if gesture == p_name:
		gesture = ""
