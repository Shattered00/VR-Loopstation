extends Node3D

const EFFECTS: Array = [
	{"name": "None",          "class": "",                            "param": "",              "min":   0.0,  "max":   0.0},
	{"name": "Amplify",       "class": "AudioEffectAmplify",          "param": "volume_db",     "min": -20.0,  "max":  20.0},
	{"name": "BandLimit",     "class": "AudioEffectBandLimitFilter",  "param": "cutoff_hz",     "min": 200.0,  "max": 8000.0},
	{"name": "BandPass",      "class": "AudioEffectBandPassFilter",   "param": "cutoff_hz",     "min": 200.0,  "max": 8000.0},
	{"name": "Chorus",        "class": "AudioEffectChorus",           "param": "wet",           "min":   0.0,  "max":   1.0},
	{"name": "Compressor",    "class": "AudioEffectCompressor",       "param": "ratio",         "min":   1.0,  "max":   8.0},
	{"name": "Delay",         "class": "AudioEffectDelay",            "param": "tap1_level_db", "min": -40.0,  "max":   0.0},
	{"name": "Distortion",    "class": "AudioEffectDistortion",       "param": "drive",         "min":   0.0,  "max":   1.0},
	{"name": "EQ6",           "class": "AudioEffectEQ6",              "param": "",              "min": -15.0,  "max":  15.0},
	{"name": "EQ10",          "class": "AudioEffectEQ10",             "param": "",              "min": -15.0,  "max":  15.0},
	{"name": "EQ21",          "class": "AudioEffectEQ21",             "param": "",              "min": -15.0,  "max":  15.0},
	{"name": "HighPass",      "class": "AudioEffectHighPassFilter",   "param": "cutoff_hz",     "min": 200.0,  "max": 8000.0},
	{"name": "HighShelf",     "class": "AudioEffectHighShelfFilter",  "param": "cutoff_hz",     "min": 200.0,  "max": 8000.0},
	{"name": "Limiter",       "class": "AudioEffectLimiter",          "param": "threshold_db",  "min":   0.0,  "max": -30.0},
	{"name": "LowPass",       "class": "AudioEffectLowPassFilter",    "param": "cutoff_hz",     "min": 200.0,  "max": 8000.0},
	{"name": "LowShelf",      "class": "AudioEffectLowShelfFilter",   "param": "cutoff_hz",     "min": 200.0,  "max": 8000.0},
	{"name": "Notch",         "class": "AudioEffectNotchFilter",      "param": "cutoff_hz",     "min": 200.0,  "max": 8000.0},
	{"name": "Panner",        "class": "AudioEffectPanner",           "param": "pan",           "min":  -1.0,  "max":   1.0},
	{"name": "Phaser",        "class": "AudioEffectPhaser",           "param": "depth",         "min":   0.0,  "max":   1.0},
	{"name": "PitchShift",    "class": "AudioEffectPitchShift",       "param": "pitch_scale",   "min":   0.5,  "max":   2.0},
	{"name": "Reverb",        "class": "AudioEffectReverb",           "param": "wet",           "min":   0.0,  "max":   1.0},
	{"name": "StereoEnhance", "class": "AudioEffectStereoEnhance",    "param": "pan_pullout",   "min":   0.0,  "max":   4.0},
]

const EFFECT_COLORS: Dictionary = {
	"None":          Color(0.20, 0.20, 0.20),
	"Amplify":       Color(1.00, 1.00, 0.75),
	"BandLimit":     Color(0.20, 0.50, 1.00),
	"BandPass":      Color(0.20, 0.65, 1.00),
	"Chorus":        Color(0.10, 0.85, 0.45),
	"Compressor":    Color(1.00, 0.55, 0.10),
	"Delay":         Color(0.60, 0.20, 1.00),
	"Distortion":    Color(1.00, 0.15, 0.15),
	"EQ6":           Color(0.95, 0.85, 0.10),
	"EQ10":          Color(0.90, 0.80, 0.10),
	"EQ21":          Color(0.85, 0.75, 0.10),
	"HighPass":      Color(0.20, 0.70, 1.00),
	"HighShelf":     Color(0.25, 0.65, 1.00),
	"Limiter":       Color(1.00, 0.40, 0.10),
	"LowPass":       Color(0.15, 0.55, 1.00),
	"LowShelf":      Color(0.15, 0.60, 1.00),
	"Notch":         Color(0.30, 0.55, 1.00),
	"Panner":        Color(0.20, 0.90, 0.90),
	"Phaser":        Color(0.25, 0.75, 0.40),
	"PitchShift":    Color(0.70, 0.10, 1.00),
	"Reverb":        Color(0.50, 0.20, 1.00),
	"StereoEnhance": Color(0.15, 0.85, 0.90),
}

var _track_fx:       Dictionary = {}
var _selected_track: Node       = null
var _labels:         Array      = []
var _openui_ready:   bool       = true
var _slot_ready:     Array      = [true, true, true, true]

# Knob1 grab-drag state
var _knob_value:      float  = 0.5
var _knob_hand:       Node3D = null
var _knob_grab_y:     float  = 0.0
var _knob_grab_start: float  = 0.0


func _ready() -> void:
	add_to_group("settings")

	var knob_mat: StandardMaterial3D = ($Knob1 as MeshInstance3D).get_surface_override_material(0)
	if knob_mat:
		($Knob1 as MeshInstance3D).set_surface_override_material(0, knob_mat.duplicate())

	for i in range(4):
		var btn := get_node("TrackFX%d" % (i + 1)) as MeshInstance3D
		var mat: StandardMaterial3D = btn.get_surface_override_material(0)
		if mat:
			btn.set_surface_override_material(0, mat.duplicate())
		var label := Label3D.new()
		label.text = ""
		label.font_size = 96
		label.pixel_size = 0.002
		label.position = Vector3(0, 1.6, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		btn.add_child(label)
		_labels.append(label)
		var area := get_node("TrackFX%d/Area3D" % (i + 1)) as Area3D
		area.area_entered.connect(_on_slot_entered.bind(i))
		area.area_exited.connect(_on_slot_exited.bind(i))

	($OpenUIbutton.get_node("Area3D") as Area3D).area_entered.connect(_on_openui_entered)
	($OpenUIbutton.get_node("Area3D") as Area3D).area_exited.connect(_on_openui_exited)
	($Knob1.get_node("Area3D") as Area3D).area_entered.connect(_on_knob1_entered)
	($Knob1.get_node("Area3D") as Area3D).area_exited.connect(_on_knob1_exited)

	_refresh_all()


func _get_track_data(track: Node) -> Dictionary:
	var id := track.get_instance_id()
	if not _track_fx.has(id):
		_track_fx[id] = {
			"effects":   [0, 0, 0, 0],
			"instances": [null, null, null, null],
		}
	return _track_fx[id]


func get_selected_track() -> Node:
	return _selected_track


func set_selected_track(track: Node) -> void:
	_selected_track = track
	_refresh_all()


func open_fx_for_track(track: Node) -> void:
	_selected_track = track
	_refresh_all()
	$FloatingMenu.show_for_track(track)


func remove_track(track: Node) -> void:
	if _selected_track == track:
		clear_selected_track()
	_track_fx.erase(track.get_instance_id())


func clear_selected_track() -> void:
	_selected_track = null
	$FloatingMenu.hide_menu()
	_refresh_all()


# Toggle the floating menu open or closed
func _on_openui_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip") or not _openui_ready:
		return
	_openui_ready = false
	$FloatingMenu.toggle()

func _on_openui_exited(area: Area3D) -> void:
	if area.is_in_group("finger_tip"):
		_openui_ready = true


func _on_slot_entered(area: Area3D, slot: int) -> void:
	if not area.is_in_group("finger_tip") or not _slot_ready[slot]:
		return
	_slot_ready[slot] = false
	_toggle_slot(slot)

func _on_slot_exited(area: Area3D, slot: int) -> void:
	if area.is_in_group("finger_tip"):
		_slot_ready[slot] = true


func _toggle_slot(slot: int) -> void:
	if not _is_track_valid():
		return
	var data := _get_track_data(_selected_track)
	var instance = data["instances"][slot]
	if instance == null:
		return
	var bus := AudioServer.get_bus_index(_selected_track.bus_name)
	if bus == -1:
		return
	for i in range(AudioServer.get_bus_effect_count(bus)):
		if AudioServer.get_bus_effect(bus, i) == instance:
			AudioServer.set_bus_effect_enabled(bus, i, not AudioServer.is_bus_effect_enabled(bus, i))
			break
	_refresh_slot(slot)


func set_slot_by_name(slot: int, fx_name: String) -> void:
	if not _is_track_valid():
		return
	var data     := _get_track_data(_selected_track)
	var bus_name : String = _selected_track.bus_name
	var idx      := 0
	for i in range(EFFECTS.size()):
		if EFFECTS[i]["name"] == fx_name:
			idx = i
			break
	if data["instances"][slot] != null:
		var bus := AudioServer.get_bus_index(bus_name)
		for i in range(AudioServer.get_bus_effect_count(bus) - 1, -1, -1):
			if AudioServer.get_bus_effect(bus, i) == data["instances"][slot]:
				AudioServer.remove_bus_effect(bus, i)
				break
		data["instances"][slot] = null
	data["effects"][slot] = idx
	var fx: Dictionary = EFFECTS[idx]
	if fx["class"] != "":
		var obj = ClassDB.instantiate(fx["class"])
		if obj is AudioEffect:
			var effect := obj as AudioEffect
			if fx["class"] == "AudioEffectDelay":
				effect.set("tap1_active", true)
				effect.set("tap1_delay_ms", 375.0)
			elif fx["class"] == "AudioEffectDistortion":
				effect.set("mode", AudioEffectDistortion.MODE_OVERDRIVE)
			_set_effect_intensity(effect, fx, _knob_value)
			AudioServer.add_bus_effect(AudioServer.get_bus_index(bus_name), effect)
			data["instances"][slot] = effect
	_refresh_slot(slot)


func get_slot_name(slot: int) -> String:
	if not _is_track_valid():
		return "None"
	var data := _get_track_data(_selected_track)
	return EFFECTS[data["effects"][slot]]["name"]


# Begin tracking the hand position when finger enters Knob1
func _on_knob1_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip") or _knob_hand != null:
		return
	var node: Node = area
	for _i in range(6):
		if node.get_parent():
			node = node.get_parent()
		else:
			break
	_knob_hand = node as Node3D
	_knob_grab_y     = to_local(_knob_hand.global_position).y
	_knob_grab_start = _knob_value

func _on_knob1_exited(area: Area3D) -> void:
	if area.is_in_group("finger_tip"):
		_knob_hand = null

# Track knob hand drag each frame and push intensity to active effects
func _process(_delta: float) -> void:
	if _knob_hand == null:
		return
	var hand_y := to_local(_knob_hand.global_position).y
	_knob_value = clamp(_knob_grab_start + (hand_y - _knob_grab_y) * 2.0, 0.0, 1.0)
	_apply_knob(_knob_value)
	_update_knob_visual()

func _apply_knob(value: float) -> void:
	if not _is_track_valid():
		return
	var data := _get_track_data(_selected_track)
	for slot in range(4):
		if data["instances"][slot] == null:
			continue
		_set_effect_intensity(data["instances"][slot], EFFECTS[data["effects"][slot]], value)

# Drive all bands uniformly for EQ effects, otherwise set the named param
func _set_effect_intensity(effect: AudioEffect, fx: Dictionary, value: float) -> void:
	if fx["param"] == "":
		var eq := effect as AudioEffectEQ
		if eq:
			for i in eq.get_band_count():
				eq.set_band_gain_db(i, lerp(fx["min"], fx["max"], value))
	else:
		effect.set(fx["param"], lerp(fx["min"], fx["max"], value))


func _update_knob_visual() -> void:
	var mat := ($Knob1 as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(
			0.15 + _knob_value * 0.85,
			0.40 + _knob_value * 0.50,
			0.15 + _knob_value * 0.50
		)

func _refresh_all() -> void:
	for i in range(4):
		_refresh_slot(i)

func _refresh_slot(slot: int) -> void:
	var btn := get_node("TrackFX%d" % (slot + 1)) as MeshInstance3D
	var mat := btn.get_surface_override_material(0) as StandardMaterial3D

	if not _is_track_valid():
		if mat:
			mat.albedo_color = Color(0.2, 0.2, 0.2)
		if slot < _labels.size():
			_labels[slot].text = ""
		return

	var data     := _get_track_data(_selected_track)
	var fx_name  : String = EFFECTS[data["effects"][slot]]["name"]
	var instance          = data["instances"][slot]
	var enabled  := true

	if instance != null:
		var bus := AudioServer.get_bus_index(_selected_track.bus_name)
		for i in range(AudioServer.get_bus_effect_count(bus)):
			if AudioServer.get_bus_effect(bus, i) == instance:
				enabled = AudioServer.is_bus_effect_enabled(bus, i)
				break

	if mat:
		var col: Color = EFFECT_COLORS[fx_name]
		mat.albedo_color = col if enabled else col * 0.3
	if slot < _labels.size():
		_labels[slot].text = fx_name


# Guard against freed or null track references
func _is_track_valid() -> bool:
	return _selected_track != null and is_instance_valid(_selected_track)
