@tool
extends Control

const OutputNode = preload("res://addons/nyx/nodes/output_node.gd")
const ColorNode = preload("res://addons/nyx/nodes/color_node.gd")
const AddNode = preload("res://addons/nyx/nodes/add_node.gd")
const MultiplyNode = preload("res://addons/nyx/nodes/multiply_node.gd")
const MixNode = preload("res://addons/nyx/nodes/mix_node.gd")
const UVNode = preload("res://addons/nyx/nodes/uv_node.gd")

var _split: HSplitContainer
var _graph: GraphEdit
var _preview_panel: VBoxContainer
var _viewport: SubViewport
var _sphere: MeshInstance3D
var _shader_material: ShaderMaterial
var _compile_timer: Timer
var _context_menu: PopupMenu
var _spawn_position: Vector2


func _ready() -> void:
	name = "NyxMain"

	_compile_timer = Timer.new()
	_compile_timer.wait_time = 0.3
	_compile_timer.one_shot = true
	_compile_timer.timeout.connect(_compile_shader)
	add_child(_compile_timer)

	_split = HSplitContainer.new()
	_split.position = Vector2.ZERO
	add_child(_split)

	_graph = GraphEdit.new()
	_graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph.right_disconnects = true
	_graph.connection_request.connect(_on_connection_request)
	_graph.disconnection_request.connect(_on_disconnection_request)
	_graph.gui_input.connect(_on_graph_gui_input)
	_split.add_child(_graph)

	_context_menu = PopupMenu.new()
	_context_menu.add_item("Color", 0)
	_context_menu.add_separator()
	_context_menu.add_item("Add", 1)
	_context_menu.add_item("Multiply", 2)
	_context_menu.add_item("Mix", 3)
	_context_menu.add_separator()
	_context_menu.add_item("UV", 4)
	_context_menu.id_pressed.connect(_on_context_menu_selected)
	add_child(_context_menu)

	_preview_panel = _build_preview_panel()
	_split.add_child(_preview_panel)

	_add_node(OutputNode.new(), Vector2(400, 200), "OutputNode")
	_add_node(ColorNode.new(), Vector2(150, 200))


func _build_preview_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(280, 0)

	var header := HBoxContainer.new()
	panel.add_child(header)

	var title := Label.new()
	title.text = "Preview"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var toggle := Button.new()
	toggle.text = "×"
	toggle.pressed.connect(_toggle_preview)
	header.add_child(toggle)

	var vpc := SubViewportContainer.new()
	vpc.stretch = true
	vpc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vpc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vpc)

	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vpc.add_child(_viewport)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 2.5)
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

	return panel


func _add_node(node: Node, offset: Vector2, node_name: String = "") -> void:
	if node_name != "":
		node.name = node_name
	node.position_offset = offset
	_graph.add_child(node)
	if node.has_signal("value_changed"):
		node.value_changed.connect(_request_compile)


func _toggle_preview() -> void:
	_preview_panel.visible = not _preview_panel.visible


func _request_compile() -> void:
	_compile_timer.stop()
	_compile_timer.start()


func _compile_shader() -> void:
	var output_node = _graph.get_node_or_null("OutputNode")
	if not output_node:
		return

	var connections = _graph.get_connection_list()
	var albedo = _get_snippet_for("OutputNode", 0, connections, "vec3(0.5, 0.5, 0.5)")
	var alpha = _get_snippet_for("OutputNode", 1, connections, "1.0")

	_shader_material.shader.code = (
		"shader_type spatial;\nvoid fragment() {\n\tALBEDO = %s;\n\tALPHA = %s;\n}\n"
		% [albedo, alpha]
	)


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
	if _split:
		_split.size = new_size


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph.connect_node(from_node, from_port, to_node, to_port)
	_request_compile()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph.disconnect_node(from_node, from_port, to_node, to_port)
	_request_compile()


func _on_graph_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_spawn_position = event.position / _graph.zoom + _graph.scroll_offset
			_context_menu.popup(Rect2(get_global_mouse_position(), Vector2.ZERO))


func _on_context_menu_selected(id: int) -> void:
	match id:
		0: _add_node(ColorNode.new(), _spawn_position)
		1: _add_node(AddNode.new(), _spawn_position)
		2: _add_node(MultiplyNode.new(), _spawn_position)
		3: _add_node(MixNode.new(), _spawn_position)
		4: _add_node(UVNode.new(), _spawn_position)
