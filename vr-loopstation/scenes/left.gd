extends XRController3D

func _on_area_3d_area_entered(area):
	$WorldEnvironment/XROrigin3D/AudioBlock/AudioStreamPlayer3D.play()
	
	print("hit")
