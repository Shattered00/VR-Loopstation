extends MeshInstance3D
var bus_name := "RecordBus"
var effect_slot := 1  # Slot where your Reverb effect is located

func _on_area_3d_area_entered(area):
	var bus := AudioServer.get_bus_index(bus_name)

	# Retrieve the current enabled state
	var is_enabled := AudioServer.is_bus_effect_enabled(bus, effect_slot)

	# Toggle (if ON → turn OFF, if OFF → turn ON)
	AudioServer.set_bus_effect_enabled(bus, effect_slot, not is_enabled)

	# Print results
	if not is_enabled:
		$".".get_active_material(0).albedo_color = Color(0, 0, 1)
		print(" Reverb ENABLED on %s slot %s" % [bus_name, effect_slot])
	else:
		$".".get_active_material(0).albedo_color = Color(128, 128, 128)
		print(" Reverb DISABLED on %s slot %s" % [bus_name, effect_slot])
	
