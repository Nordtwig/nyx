@tool
extends Control

const OutputNode = preload("res://addons/nyx/nodes/output_node.gd")
const ColorNode = preload("res://addons/nyx/nodes/color_node.gd")
const AddNode = preload("res://addons/nyx/nodes/add_node.gd")
const MultiplyNode = preload("res://addons/nyx/nodes/multiply_node.gd")
const MixNode = preload("res://addons/nyx/nodes/mix_node.gd")
const UVNode = preload("res://addons/nyx/nodes/uv_node.gd")
const FloatNode = preload("res://addons/nyx/nodes/float_node.gd")

const NODE_CLASSES := {
	"OutputNode": OutputNode,
	"ColorNode": ColorNode,
	"AddNode": AddNode,
	"MultiplyNode": MultiplyNode,
	"MixNode": MixNode,
	"UVNode": UVNode,
	"FloatNode": FloatNode,
}

var _graph_container: VBoxContainer
var _graph: GraphEdit
var _preview_panel: Panel
var _preview_dragging: bool = false
var _preview_resizing: bool = false
var _preview_positioned: bool = false
var _viewport: SubViewport
var _sphere: MeshInstance3D
var _shader_material: ShaderMaterial
var _compile_timer: Timer
var _context_menu: PopupMenu
var _export_dialog: EditorFileDialog
var _save_dialog: EditorFileDialog
var _load_dialog: EditorFileDialog
var _spawn_position: Vector2
var _last_shader_code: String
var _undo_stack: Array = []
var _redo_stack: Array = []
var _pre_drag_snapshot = null


func _ready() -> void:
	name = "NyxMain"

	_compile_timer = Timer.new()
	_compile_timer.wait_time = 0.3
	_compile_timer.one_shot = true
	_compile_timer.timeout.connect(_compile_shader)
	add_child(_compile_timer)

	_graph = GraphEdit.new()
	_graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph.right_disconnects = true
	_graph.connection_request.connect(_on_connection_request)
	_graph.disconnection_request.connect(_on_disconnection_request)
	_graph.delete_nodes_request.connect(_on_delete_nodes_request)
	_graph.gui_input.connect(_on_graph_gui_input)

	_graph_container = VBoxContainer.new()
	_graph_container.add_child(_build_graph_toolbar())
	_graph_container.add_child(_graph)
	add_child(_graph_container)

	_context_menu = PopupMenu.new()
	_context_menu.add_item("Color", 0)
	_context_menu.add_item("Float", 5)
	_context_menu.add_separator()
	_context_menu.add_item("Add", 1)
	_context_menu.add_item("Multiply", 2)
	_context_menu.add_item("Mix", 3)
	_context_menu.add_separator()
	_context_menu.add_item("UV", 4)
	_context_menu.id_pressed.connect(_on_context_menu_selected)
	add_child(_context_menu)

	_export_dialog = EditorFileDialog.new()
	_export_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_export_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_export_dialog.add_filter("*.gdshader", "GDShader File")
	_export_dialog.file_selected.connect(_on_export_file_selected)
	add_child(_export_dialog)

	_save_dialog = EditorFileDialog.new()
	_save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_save_dialog.add_filter("*.nyx", "Nyx Graph")
	_save_dialog.file_selected.connect(_on_save_file_selected)
	add_child(_save_dialog)

	_load_dialog = EditorFileDialog.new()
	_load_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_load_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_load_dialog.add_filter("*.nyx", "Nyx Graph")
	_load_dialog.file_selected.connect(_on_load_file_selected)
	add_child(_load_dialog)

	_preview_panel = _build_preview_panel()
	add_child(_preview_panel)

	_add_node(OutputNode.new(), Vector2(400, 200), "OutputNode")
	_add_node(ColorNode.new(), Vector2(150, 200))


func _build_preview_panel() -> Panel:
	var floating := Panel.new()
	floating.size = Vector2(220, 200)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.13, 0.13, 0.16, 0.95)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	floating.add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	floating.add_child(vbox)

	var header := HBoxContainer.new()
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.gui_input.connect(_on_preview_header_input)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "Preview"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var export_btn := Button.new()
	export_btn.text = "Export"
	export_btn.pressed.connect(func(): _export_dialog.popup_centered_ratio(0.5))
	header.add_child(export_btn)

	var toggle := Button.new()
	toggle.text = "×"
	toggle.pressed.connect(_toggle_preview)
	header.add_child(toggle)

	var vpc := SubViewportContainer.new()
	vpc.stretch = true
	vpc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vpc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(vpc)

	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vpc.add_child(_viewport)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 1.2)
	_viewport.add_child(camera)

	_sphere = MeshInstance3D.new()
	_sphere.mesh = SphereMesh.new()
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = Shader.new()
	_shader_material.shader.code = "shader_type spatial;\nvoid fragment() {\n\tALBEDO = vec3(0.5, 0.5, 0.5);\n}\n"
	_sphere.material_override = _shader_material
	_viewport.add_child(_sphere)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	_viewport.add_child(light)

	var grip := Control.new()
	grip.size = Vector2(16, 16)
	grip.anchor_left = 1.0
	grip.anchor_top = 1.0
	grip.anchor_right = 1.0
	grip.anchor_bottom = 1.0
	grip.offset_left = -16
	grip.offset_top = -16
	grip.mouse_default_cursor_shape = 12
	grip.gui_input.connect(_on_preview_resize_input)
	floating.add_child(grip)

	return floating


func _add_node(node: Node, offset: Vector2, node_name: String = "") -> void:
	if node_name != "":
		node.name = node_name
	node.position_offset = offset
	_graph.add_child(node)
	if node.has_signal("value_changed"):
		node.value_changed.connect(_request_compile)
	node.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_pre_drag_snapshot = _serialize_graph()
	)
	if node.has_signal("dragged"):
		node.dragged.connect(func(_f: Vector2, _t: Vector2):
			if _pre_drag_snapshot != null:
				_undo_stack.push_back(_pre_drag_snapshot)
				if _undo_stack.size() > 50:
					_undo_stack.pop_front()
				_redo_stack.clear()
				_pre_drag_snapshot = null
		)


func _toggle_preview() -> void:
	_preview_panel.visible = not _preview_panel.visible


func _request_compile() -> void:
	_compile_timer.stop()
	_compile_timer.start()


func _build_shader_code() -> String:
	var c = _graph.get_connection_list()
	var albedo    = _get_snippet_for("OutputNode", 0, c, "vec3(0.5, 0.5, 0.5)")
	var alpha     = _get_snippet_for("OutputNode", 1, c, "1.0")
	var roughness = _get_snippet_for("OutputNode", 2, c, "1.0")
	var metallic  = _get_snippet_for("OutputNode", 3, c, "0.0")
	var emission  = _get_snippet_for("OutputNode", 4, c, "vec3(0.0, 0.0, 0.0)")
	return "shader_type spatial;\nvoid fragment() {\n\tALBEDO = %s;\n\tALPHA = %s;\n\tROUGHNESS = %s;\n\tMETALLIC = %s;\n\tEMISSION = %s;\n}\n" % [albedo, alpha, roughness, metallic, emission]


func _compile_shader() -> void:
	if not _graph.get_node_or_null("OutputNode"):
		return
	var code := _build_shader_code()
	if code == _last_shader_code:
		return
	_last_shader_code = code
	_shader_material.shader.code = code


func _on_export_file_selected(path: String) -> void:
	if not path.ends_with(".gdshader"):
		path += ".gdshader"

	var shader_code := _build_shader_code()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		push_error("Nyx: could not write shader to %s" % path)
		return
	f.store_string(shader_code)
	f.close()

	var tres_path := path.get_basename() + ".tres"
	var tres_content := "[gd_resource type=\"ShaderMaterial\" load_steps=2 format=3]\n\n[ext_resource type=\"Shader\" path=\"%s\" id=\"1\"]\n\n[resource]\nshader = ExtResource(\"1\")\n" % path
	var tf := FileAccess.open(tres_path, FileAccess.WRITE)
	if not tf:
		push_error("Nyx: could not write material to %s" % tres_path)
		return
	tf.store_string(tres_content)
	tf.close()

	EditorInterface.get_resource_filesystem().scan()
	print("Nyx: exported\n  shader  → %s\n  material → %s" % [path, tres_path])


func _get_snippet_for(to_node: String, to_port: int, connections: Array, default_val: String) -> String:
	for conn in connections:
		if str(conn["to_node"]) == to_node and conn["to_port"] == to_port:
			var from := _graph.get_node_or_null(str(conn["from_node"]))
			if from:
				return _get_node_snippet(from, connections)
	return default_val


func _get_node_snippet(node: Node, connections: Array) -> String:
	var defaults = node.get_default_inputs() if node.has_method("get_default_inputs") else []
	var inputs := []
	for i in range(node.get_input_port_count()):
		var default_val = defaults[i] if i < defaults.size() else "0.0"
		inputs.append(_get_snippet_for(node.name, i, connections, default_val))
	return node.get_shader_snippet(inputs)


func sync_size(new_size: Vector2) -> void:
	if _graph_container:
		_graph_container.size = new_size
	if not _preview_positioned and _preview_panel:
		_preview_positioned = true
		call_deferred("_position_preview_default")


func _position_preview_default() -> void:
	_preview_panel.position = Vector2(_graph_container.size.x - _preview_panel.size.x - 20, 20)


func _on_preview_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_preview_dragging = event.pressed
	elif event is InputEventMouseMotion and _preview_dragging:
		_preview_panel.position += event.relative


func _on_preview_resize_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_preview_resizing = event.pressed
	elif event is InputEventMouseMotion and _preview_resizing:
		var new_size: Vector2 = _preview_panel.size + event.relative
		new_size.x = max(new_size.x, 160.0)
		new_size.y = max(new_size.y, 120.0)
		_preview_panel.size = new_size


func _push_undo_state() -> void:
	_undo_stack.push_back(_serialize_graph())
	if _undo_stack.size() > 50:
		_undo_stack.pop_front()
	_redo_stack.clear()


func _undo() -> void:
	if _undo_stack.is_empty():
		return
	_redo_stack.push_back(_serialize_graph())
	_deserialize_graph(_undo_stack.pop_back())


func _redo() -> void:
	if _redo_stack.is_empty():
		return
	_undo_stack.push_back(_serialize_graph())
	_deserialize_graph(_redo_stack.pop_back())


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	_push_undo_state()
	for node_name in nodes:
		if str(node_name) == "OutputNode":
			continue
		var to_disconnect := []
		for conn in _graph.get_connection_list():
			if str(conn["from_node"]) == str(node_name) or str(conn["to_node"]) == str(node_name):
				to_disconnect.append(conn)
		for conn in to_disconnect:
			_graph.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
		var node := _graph.get_node_or_null(str(node_name))
		if node:
			node.queue_free()
	_request_compile()


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_push_undo_state()
	_graph.connect_node(from_node, from_port, to_node, to_port)
	_request_compile()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_push_undo_state()
	_graph.disconnect_node(from_node, from_port, to_node, to_port)
	_request_compile()


func _on_graph_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_spawn_position = event.position / _graph.zoom + _graph.scroll_offset
			_context_menu.popup(Rect2(get_global_mouse_position(), Vector2.ZERO))


func _on_context_menu_selected(id: int) -> void:
	_push_undo_state()
	match id:
		0: _add_node(ColorNode.new(), _spawn_position)
		1: _add_node(AddNode.new(), _spawn_position)
		2: _add_node(MultiplyNode.new(), _spawn_position)
		3: _add_node(MixNode.new(), _spawn_position)
		4: _add_node(UVNode.new(), _spawn_position)
		5: _add_node(FloatNode.new(), _spawn_position)


func _build_graph_toolbar() -> HBoxContainer:
	var toolbar := HBoxContainer.new()

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(func(): _save_dialog.popup_centered_ratio(0.5))
	toolbar.add_child(save_btn)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.pressed.connect(func(): _load_dialog.popup_centered_ratio(0.5))
	toolbar.add_child(load_btn)

	var sep := VSeparator.new()
	toolbar.add_child(sep)

	var undo_btn := Button.new()
	undo_btn.text = "Undo"
	undo_btn.pressed.connect(_undo)
	toolbar.add_child(undo_btn)

	var redo_btn := Button.new()
	redo_btn.text = "Redo"
	redo_btn.pressed.connect(_redo)
	toolbar.add_child(redo_btn)

	return toolbar


func _get_node_type(node: Node) -> String:
	for type_name in NODE_CLASSES:
		if node.get_script() == NODE_CLASSES[type_name]:
			return type_name
	return ""


func _serialize_graph() -> Dictionary:
	var nodes := []
	for child in _graph.get_children():
		if not child is GraphNode:
			continue
		var type := _get_node_type(child)
		if type == "":
			continue
		nodes.append({
			"type": type,
			"name": str(child.name),
			"position": [child.position_offset.x, child.position_offset.y],
			"state": child.get_state(),
		})

	var connections := []
	for conn in _graph.get_connection_list():
		connections.append({
			"from_node": str(conn["from_node"]),
			"from_port": conn["from_port"],
			"to_node": str(conn["to_node"]),
			"to_port": conn["to_port"],
		})

	return {"nodes": nodes, "connections": connections}


func _deserialize_graph(data: Dictionary) -> void:
	_graph.clear_connections()
	for child in _graph.get_children():
		if child is GraphNode:
			_graph.remove_child(child)
			child.queue_free()

	for node_data in data.get("nodes", []):
		var type: String = node_data["type"]
		if not NODE_CLASSES.has(type):
			push_warning("Nyx: unknown node type '%s', skipping" % type)
			continue
		var node = NODE_CLASSES[type].new()
		var pos: Array = node_data["position"]
		_add_node(node, Vector2(pos[0], pos[1]), node_data["name"])
		var state: Dictionary = node_data.get("state", {})
		if not state.is_empty():
			node.set_state(state)

	for conn in data.get("connections", []):
		_graph.connect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])

	_request_compile()


func _on_save_file_selected(path: String) -> void:
	if not path.ends_with(".nyx"):
		path += ".nyx"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		push_error("Nyx: could not write graph to %s" % path)
		return
	f.store_string(JSON.stringify(_serialize_graph(), "\t"))
	f.close()
	print("Nyx: saved graph → %s" % path)


func _on_load_file_selected(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		push_error("Nyx: could not read graph from %s" % path)
		return
	var result := JSON.parse_string(f.get_as_text())
	f.close()
	if not result is Dictionary:
		push_error("Nyx: invalid graph file %s" % path)
		return
	_deserialize_graph(result)
	print("Nyx: loaded graph ← %s" % path)
