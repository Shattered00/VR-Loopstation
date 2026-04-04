extends Node3D

@export var hover_depth: float = 0.08

var _quad_size:     Vector2
var _viewport_size: Vector2

var _nav_stack:    Array         = []
var _active_slot:  int           = -1
var _active_track: Node          = null
var _in_contact:   bool          = false
var _grid:        GridContainer = null
var _title:       Label         = null
var _back_btn:    Button        = null


func _ready() -> void:
	var quad := ($Panel as MeshInstance3D).mesh as QuadMesh
	_quad_size     = quad.size if quad else Vector2(0.7, 0.5)
	_viewport_size = Vector2(($SubViewport as SubViewport).size)
	_get_ui_nodes()
	($Area3D as Area3D).area_entered.connect(_on_area_entered)
	($Area3D as Area3D).area_exited.connect(_on_area_exited)
	visible = false


func _get_ui_nodes() -> void:
	var vbox := $SubViewport/Control/ColorRect/MarginContainer/VBoxContainer as VBoxContainer
	_title    = vbox.get_node("TitleBar/Title") as Label
	_back_btn = vbox.get_node("TitleBar/BackButton") as Button
	_grid     = vbox.get_node("ScrollContainer/ButtonGrid") as GridContainer
	_back_btn.pressed.connect(_on_back_pressed)


# Show the menu at its scene-placed position
func show_menu() -> void:
	_nav_stack.clear()
	_go_to(_main_menu())
	visible = true


# TrackFX shortcut — jumps straight to FX slots, toggles closed if same track
func show_for_track(track: Node) -> void:
	if visible and _active_track == track:
		hide_menu()
		return
	_active_track = track
	_nav_stack.clear()
	_go_to(_main_menu())
	_go_to(_fx_slots_menu())
	visible = true


func hide_menu() -> void:
	visible = false
	_nav_stack.clear()


func toggle() -> void:
	if visible: hide_menu()
	else: show_menu()


# Add items here to grow the root menu
func _main_menu() -> Dictionary:
	return {
		"title": "Menu",
		"items": [
			{"label": "Track FX",        "action": "nav",         "target": "track_fx"},
			{"label": "One Shot Mode",   "action": "placeholder", "target": ""},
			{"label": "Instrument Mode", "action": "placeholder", "target": ""},
			{"label": "",                "action": "placeholder", "target": ""},
			{"label": "",                "action": "placeholder", "target": ""},
			{"label": "",                "action": "placeholder", "target": ""},
		]
	}


func _sorted_tracks() -> Array:
	var tracks := get_tree().get_nodes_in_group("trackholders")
	tracks.sort_custom(func(a: Node, b: Node) -> bool:
		return (a as Node3D).global_position.x < (b as Node3D).global_position.x
	)
	return tracks


func _track_select_menu() -> Dictionary:
	var items: Array = []
	var tracks := _sorted_tracks()
	for i in range(tracks.size()):
		items.append({
			"label":    "Track %d" % (i + 1),
			"action":   "pick_track",
			"target":   "",
			"node_ref": tracks[i],
		})
	return {"title": "Select Track", "items": items}


func _fx_slots_menu() -> Dictionary:
	var s := get_parent()
	var items: Array = []
	for i in range(4):
		items.append({
			"label":  "FX %d\n%s" % [i + 1, s.get_slot_name(i)],
			"action": "pick_slot",
			"target": str(i)
		})
	var track_label := "Track"
	if _active_track != null and is_instance_valid(_active_track):
		var tracks := _sorted_tracks()
		var idx    := tracks.find(_active_track)
		if idx != -1:
			track_label = "Track %d" % (idx + 1)
	return {"id": "fx_slots", "title": "%s FX" % track_label, "items": items}


func _effect_picker(slot: int) -> Dictionary:
	var s     := get_parent()
	var items : Array = []
	for fx in s.EFFECTS:
		items.append({
			"label":  fx["name"],
			"action": "assign_fx",
			"target": "%d:%s" % [slot, fx["name"]]
		})
	return {"title": "FX Slot %d" % (slot + 1), "items": items}


func _go_to(menu: Dictionary) -> void:
	_nav_stack.push_back(menu)
	_refresh_menu(menu)


func _go_back() -> void:
	if _nav_stack.size() <= 1:
		hide_menu()
		return
	if (_nav_stack.back() as Dictionary).get("id", "") == "fx_slots":
		_active_track = null
		get_parent().set_selected_track(null)
	_nav_stack.pop_back()
	_refresh_menu(_nav_stack.back())


func _refresh_menu(menu: Dictionary) -> void:
	_title.text       = menu["title"]
	_back_btn.visible = true
	for child in _grid.get_children():
		child.queue_free()
	for item in menu["items"]:
		var btn := Button.new()
		btn.text = item["label"]
		btn.custom_minimum_size = Vector2(0, 80)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.disabled = item["label"] == ""
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_item_pressed.bind(item))
		_grid.add_child(btn)


func _on_item_pressed(item: Dictionary) -> void:
	match item["action"]:
		"nav":
			match item["target"]:
				"track_fx":
					var selected_track: Node = get_parent().get_selected_track() as Node
					if selected_track != null and is_instance_valid(selected_track):
						_active_track = selected_track
						_go_to(_fx_slots_menu())
					else:
						_go_to(_track_select_menu())
		"pick_track":
			var track: Node = item.get("node_ref") as Node
			if is_instance_valid(track):
				_active_track = track
				get_parent().set_selected_track(track)
				_go_to(_fx_slots_menu())
		"pick_slot":
			_active_slot = int(item["target"])
			_go_to(_effect_picker(_active_slot))
		"assign_fx":
			var parts   : PackedStringArray = (item["target"] as String).split(":")
			var slot    : int               = int(parts[0])
			var fx_name : String            = parts[1]
			get_parent().set_slot_by_name(slot, fx_name)
			_go_back()
			_nav_stack[_nav_stack.size() - 1] = _fx_slots_menu()
			_refresh_menu(_nav_stack.back())
		"placeholder":
			pass


func _on_back_pressed() -> void:
	_go_back()


func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("finger_tip") or _in_contact:
		return
	_in_contact = true
	var local_pos := ($Panel as MeshInstance3D).to_local(area.global_position)
	_send_click(_local_to_pixel(local_pos))


func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("finger_tip"):
		_in_contact = false


# Send hover events each frame to drive button highlight states
func _process(_delta: float) -> void:
	if not visible:
		return
	var panel := $Panel as MeshInstance3D
	var tips   = get_tree().get_nodes_in_group("finger_tip")
	var best_px := Vector2(-1000.0, -1000.0)
	var best_d  := hover_depth
	for tip in tips:
		var tip_area := tip as Area3D
		if tip_area == null:
			continue
		var lp := panel.to_local(tip_area.global_position)
		if abs(lp.z) < best_d and abs(lp.x) < _quad_size.x * 0.5 and abs(lp.y) < _quad_size.y * 0.5:
			best_d  = abs(lp.z)
			best_px = _local_to_pixel(lp)
	_send_hover(best_px)


func _local_to_pixel(local_pos: Vector3) -> Vector2:
	return Vector2(
		(local_pos.x / _quad_size.x + 0.5) * _viewport_size.x,
		(-local_pos.y / _quad_size.y + 0.5) * _viewport_size.y
	)


func _send_hover(pixel: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = pixel
	($SubViewport as SubViewport).push_input(ev, true)


func _send_click(pixel: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position     = pixel
	ev.pressed      = true
	($SubViewport as SubViewport).push_input(ev, true)
	ev = ev.duplicate() as InputEventMouseButton
	ev.pressed = false
	($SubViewport as SubViewport).push_input(ev, true)
