extends Node

# Global loop grid — established by the first track recorded.
# All subsequent tracks with loop_sync enabled are quantised to a multiple of master_length.

var master_length: int = 0   # samples at input mix rate

var is_set: bool:
	get: return master_length > 0


# Called by the very first synced track that finishes recording
func set_master(length_samples: int) -> void:
	master_length = length_samples


# Round a sample count to the nearest multiple or sub-multiple of master_length.
# Recordings longer than master snap up to ×1, ×2, ×3 … (no silent padding beyond the loop).
# Recordings shorter than master snap down to master÷1, master÷2, master÷4 …
# so a short hit loops tightly without a long tail of silence.
func quantise_to_master(recorded: int) -> int:
	if master_length == 0:
		return recorded
	if recorded >= master_length:
		# Snap up to nearest whole multiple (at least 1×)
		var ratio    := float(recorded) / float(master_length)
		var multiple := int(max(1.0, round(ratio)))
		return multiple * master_length
	else:
		# Snap down to nearest sub-multiple (master ÷ N, N ≥ 1)
		var divisor := int(max(1.0, round(float(master_length) / float(recorded))))
		return master_length / divisor


# Called when any track stops; resets the grid if every button is now idle.
# RState.IDLE == 0 — must stay in sync with the enum in record_button.gd.
func on_track_stopped(tree: SceneTree) -> void:
	for btn in tree.get_nodes_in_group("record_buttons"):
		if btn.get("state") != 0:
			return
	reset()


func reset() -> void:
	master_length = 0
