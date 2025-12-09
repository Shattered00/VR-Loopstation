extends MeshInstance3D
var bus_name := "RecordBus"
var effect_slot := 1  # Slot where your Reverb effect is located

func _on_area_3d_area_entered(area):
	var bus := AudioServer.get_bus_index(bus_name)

	# CHECK 1: Does the bus exist?
	if bus == -1:
		push_error("Bus '%s' does NOT exist!" % bus_name)
		return

	# CHECK 2: Does an effect exist in this slot?
	if effect_slot >= AudioServer.get_bus_effect_count(bus):
		push_error("No effect found in slot %s on bus '%s'!" % [effect_slot, bus_name])
		return

	# Retrieve the current enabled state
	var is_enabled := AudioServer.is_bus_effect_enabled(bus, effect_slot)

	# Toggle (if ON → turn OFF, if OFF → turn ON)
	AudioServer.set_bus_effect_enabled(bus, effect_slot, not is_enabled)

	# Print results
	if not is_enabled:
		print(" Reverb ENABLED on %s slot %s" % [bus_name, effect_slot])
	else:
		print("✖ Reverb DISABLED on %s slot %s" % [bus_name, effect_slot])
	
