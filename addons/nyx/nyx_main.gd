@tool
extends Control

const OutputNode = preload("res://addons/nyx/nodes/output_node.gd")
const ColorNode = preload("res://addons/nyx/nodes/color_node.gd")
const AddNode = preload("res://addons/nyx/nodes/add_node.gd")
const MultiplyNode = preload("res://addons/nyx/nodes/multiply_node.gd")
const MixNode = preload("res://addons/nyx/nodes/mix_node.gd")
const UVNode = preload("res://addons/nyx/nodes/uv_node.gd")
const FloatNode = preload("res://addons/nyx/nodes/float_node.gd")
const SubtractNode = preload("res://addons/nyx/nodes/subtract_node.gd")
const ClampNode = preload("res://addons/nyx/nodes/clamp_node.gd")
const PowerNode = preload("res://addons/nyx/nodes/power_node.gd")
const SinNode = preload("res://addons/nyx/nodes/sin_node.gd")
const CosNode = preload("res://addons/nyx/nodes/cos_node.gd")
const TimeNode = preload("res://addons/nyx/nodes/time_node.gd")
const SplitNode = preload("res://addons/nyx/nodes/split_node.gd")
const CombineNode = preload("res://addons/nyx/nodes/combine_node.gd")
const TextureSampleNode = preload("res://addons/nyx/nodes/texture_sample_node.gd")
const FresnelNode = preload("res://addons/nyx/nodes/fresnel_node.gd")
const ScaleNode = preload("res://addons/nyx/nodes/scale_node.gd")
const StepNode = preload("res://addons/nyx/nodes/step_node.gd")
const SmoothstepNode = preload("res://addons/nyx/nodes/smoothstep_node.gd")
const NoiseNode = preload("res://addons/nyx/nodes/noise_node.gd")
const VertexNode = preload("res://addons/nyx/nodes/vertex_node.gd")
const NormalMapNode = preload("res://addons/nyx/nodes/normal_map_node.gd")
const AbsNode = preload("res://addons/nyx/nodes/abs_node.gd")
const CeilNode = preload("res://addons/nyx/nodes/ceil_node.gd")
const FloorNode = preload("res://addons/nyx/nodes/floor_node.gd")
const FractNode = preload("res://addons/nyx/nodes/fract_node.gd")
const NegateNode = preload("res://addons/nyx/nodes/negate_node.gd")
const OneMinusNode = preload("res://addons/nyx/nodes/one_minus_node.gd")
const RoundNode = preload("res://addons/nyx/nodes/round_node.gd")
const SqrtNode = preload("res://addons/nyx/nodes/sqrt_node.gd")
const MinMaxNode = preload("res://addons/nyx/nodes/min_max_node.gd")
const DivideNode = preload("res://addons/nyx/nodes/divide_node.gd")
const ModNode = preload("res://addons/nyx/nodes/mod_node.gd")
const NormalizeNode = preload("res://addons/nyx/nodes/normalize_node.gd")
const LengthNode = preload("res://addons/nyx/nodes/length_node.gd")
const DotNode = preload("res://addons/nyx/nodes/dot_node.gd")

const NODE_CLASSES := {
	"OutputNode": OutputNode,
	"ColorNode": ColorNode,
	"AddNode": AddNode,
	"MultiplyNode": MultiplyNode,
	"MixNode": MixNode,
	"UVNode": UVNode,
	"FloatNode": FloatNode,
	"SubtractNode": SubtractNode,
	"ClampNode": ClampNode,
	"PowerNode": PowerNode,
	"SinNode": SinNode,
	"CosNode": CosNode,
	"TimeNode": TimeNode,
	"SplitNode": SplitNode,
	"CombineNode": CombineNode,
	"TextureSampleNode": TextureSampleNode,
	"FresnelNode": FresnelNode,
	"ScaleNode": ScaleNode,
	"StepNode": StepNode,
	"SmoothstepNode": SmoothstepNode,
	"NoiseNode": NoiseNode,
	"VertexNode": VertexNode,
	"NormalMapNode": NormalMapNode,
	"AbsNode": AbsNode,
	"CeilNode": CeilNode,
	"FloorNode": FloorNode,
	"FractNode": FractNode,
	"NegateNode": NegateNode,
	"OneMinusNode": OneMinusNode,
	"RoundNode": RoundNode,
	"SqrtNode": SqrtNode,
	"MinMaxNode": MinMaxNode,
	"DivideNode": DivideNode,
	"ModNode": ModNode,
	"NormalizeNode": NormalizeNode,
	"LengthNode": LengthNode,
	"DotNode": DotNode,
}

var _graph_container: VBoxContainer
var _graph: GraphEdit
var _preview_panel: Panel
var _preview_dragging: bool = false
var _preview_resizing: bool = false
var _preview_positioned: bool = false
var _viewport: SubViewport
var _preview_mesh: MeshInstance3D
var _preview_camera: Camera3D
var _preview_mesh_buttons: Array[Button] = []
var _shader_material: ShaderMaterial
var _compile_timer: Timer
var _context_menu: PopupMenu
var _export_dialog: EditorFileDialog
var _save_dialog: EditorFileDialog
var _load_dialog: EditorFileDialog
var _texture_dialog: EditorFileDialog
var _texture_target: Node = null
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
	_graph.add_valid_connection_type(0, 0)
	_graph.add_valid_connection_type(1, 1)

	_graph_container = VBoxContainer.new()
	_graph_container.add_child(_build_graph_toolbar())
	_graph_container.add_child(_graph)
	add_child(_graph_container)

	_context_menu = PopupMenu.new()
	_context_menu.add_item("Color", 0)
	_context_menu.add_item("Float", 5)
	_context_menu.add_separator()
	_context_menu.add_item("Add", 1)
	_context_menu.add_item("Subtract", 6)
	_context_menu.add_item("Multiply", 2)
	_context_menu.add_item("Divide", 24)
	_context_menu.add_item("Mix", 3)
	_context_menu.add_item("Clamp", 7)
	_context_menu.add_item("Power", 8)
	_context_menu.add_item("Min / Max", 23)
	_context_menu.add_item("Modulo", 25)
	_context_menu.add_item("Abs", 22)
	_context_menu.add_item("Ceil", 29)
	_context_menu.add_item("Floor", 30)
	_context_menu.add_item("Fract", 31)
	_context_menu.add_item("Negate", 32)
	_context_menu.add_item("One Minus", 33)
	_context_menu.add_item("Round", 34)
	_context_menu.add_item("Sqrt", 35)
	_context_menu.add_item("Sin", 9)
	_context_menu.add_item("Cos", 10)
	_context_menu.add_separator()
	_context_menu.add_item("Normalize", 26)
	_context_menu.add_item("Length", 27)
	_context_menu.add_item("Dot", 28)
	_context_menu.add_separator()
	_context_menu.add_item("Split", 12)
	_context_menu.add_item("Combine", 13)
	_context_menu.add_separator()
	_context_menu.add_item("UV", 4)
	_context_menu.add_item("Vertex", 20)
	_context_menu.add_item("Time", 11)
	_context_menu.add_item("Texture Sample", 14)
	_context_menu.add_item("Normal Map", 21)
	_context_menu.add_item("Fresnel", 15)
	_context_menu.add_item("Scale", 16)
	_context_menu.add_item("Step", 17)
	_context_menu.add_item("Smoothstep", 18)
	_context_menu.add_separator()
	_context_menu.add_item("Noise", 19)
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

	_texture_dialog = EditorFileDialog.new()
	_texture_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_texture_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_texture_dialog.add_filter("*.png,*.jpg,*.jpeg,*.bmp,*.webp,*.tga,*.exr,*.hdr", "Image Files")
	_texture_dialog.file_selected.connect(_on_texture_file_selected)
	add_child(_texture_dialog)

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

	var mesh_row := HBoxContainer.new()
	mesh_row.add_theme_constant_override("separation", 2)
	vbox.add_child(mesh_row)

	for pair in [["Sphere", SphereMesh.new(), Vector3.ZERO, 1.2], ["Plane", QuadMesh.new(), Vector3.ZERO, 1.2], ["Cube", BoxMesh.new(), Vector3(20, 40, 20), 1.8]]:
		var btn := Button.new()
		btn.text = pair[0]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.toggle_mode = true
		btn.button_pressed = pair[0] == "Sphere"
		btn.pressed.connect(_on_mesh_btn_pressed.bind(btn, pair[1], pair[2], pair[3]))
		mesh_row.add_child(btn)
		_preview_mesh_buttons.append(btn)

	var vpc := SubViewportContainer.new()
	vpc.stretch = true
	vpc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vpc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(vpc)

	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vpc.add_child(_viewport)

	_preview_camera = Camera3D.new()
	_preview_camera.position = Vector3(0, 0, 1.2)
	_viewport.add_child(_preview_camera)

	_preview_mesh = MeshInstance3D.new()
	_preview_mesh.mesh = SphereMesh.new()
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = Shader.new()
	_shader_material.shader.code = "shader_type spatial;\nvoid fragment() {\n\tALBEDO = vec3(0.5, 0.5, 0.5);\n}\n"
	_preview_mesh.material_override = _shader_material
	_viewport.add_child(_preview_mesh)

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
	if node.has_signal("edit_started"):
		node.edit_started.connect(_push_undo_state)
	if node.has_signal("texture_pick_requested"):
		node.texture_pick_requested.connect(_on_texture_pick_requested)
	if node.has_signal("preview_toggled"):
		node.preview_toggled.connect(func():
			if node.has_meta("_preview_material"):
				_close_node_preview(node)
			else:
				_open_node_preview(node)
		)
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


func _on_mesh_btn_pressed(btn: Button, mesh: Mesh, rotation: Vector3, cam_z: float) -> void:
	_preview_mesh.mesh = mesh
	_preview_mesh.rotation_degrees = rotation
	_preview_camera.position.z = cam_z
	for b in _preview_mesh_buttons:
		b.button_pressed = b == btn



func _open_node_preview(node: Node) -> void:
	var tex_rect: TextureRect = node.get_preview_slot()
	if not tex_rect:
		return

	var vp := SubViewport.new()
	vp.size = Vector2i(100, 100)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, 1.2)
	vp.add_child(cam)
	cam.make_current()

	var mesh_inst := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.84, 1.84)
	mesh_inst.mesh = qm
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode unshaded;\nvoid fragment() { ALBEDO = vec3(0.5); }"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mesh_inst.material_override = mat
	vp.add_child(mesh_inst)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	vp.add_child(light)

	tex_rect.texture = vp.get_texture()
	node.set_meta("_preview_material", mat)
	node.set_meta("_preview_viewport", vp)
	_refresh_node_preview(node)


func _close_node_preview(node: Node) -> void:
	if node.has_meta("_preview_material"):
		node.remove_meta("_preview_material")
	if node.has_meta("_preview_viewport"):
		(node.get_meta("_preview_viewport") as Node).queue_free()
		node.remove_meta("_preview_viewport")
	var tex_rect: TextureRect = node.get_preview_slot()
	if tex_rect:
		tex_rect.texture = null


func _refresh_node_preview(node: Node) -> void:
	if not node.has_meta("_preview_material"):
		return
	var mat: ShaderMaterial = node.get_meta("_preview_material")
	mat.shader.code = _build_node_preview_shader(node)
	for child in _graph.get_children():
		if child.has_method("get_uniform_name") and child.has_method("get_texture"):
			var tex = child.get_texture()
			if tex:
				mat.set_shader_parameter(child.get_uniform_name(), tex)


func _refresh_all_node_previews() -> void:
	for child in _graph.get_children():
		if child.has_meta("_preview_material"):
			_refresh_node_preview(child)


func _build_node_preview_shader(node: Node) -> String:
	var c = _graph.get_connection_list()

	var uniform_lines := ""
	for child in _graph.get_children():
		if child.has_method("get_uniform_declaration"):
			var decl: String = child.get_uniform_declaration()
			if decl != "":
				uniform_lines += decl + "\n"

	var shader_functions := {}
	for child in _graph.get_children():
		if child.has_method("get_shader_functions"):
			shader_functions.merge(child.get_shader_functions())
	var function_block := ""
	for fn in shader_functions:
		function_block += shader_functions[fn]

	var result: String
	var albedo_expr: String
	if node.get_output_port_count() == 0:
		# Sink node (e.g. OutputNode) — show what feeds into its first input slot
		result = _get_snippet_for(node.name, 0, c, "vec3(0.5, 0.5, 0.5)")
		albedo_expr = result
	else:
		result = _get_node_snippet(node, 0, c)
		var output_type: int = node.get_output_port_type(0)
		albedo_expr = "vec3(%s)" % result if output_type == 1 else result

	return "shader_type spatial;\nrender_mode unshaded;\n%s\n%svoid fragment() {\n\tALBEDO = %s;\n}\n" % [uniform_lines, function_block, albedo_expr]


func _request_compile() -> void:
	_compile_timer.stop()
	_compile_timer.start()


func _build_shader_code() -> String:
	var uniform_lines := ""
	for child in _graph.get_children():
		if child.has_method("get_uniform_declaration"):
			var decl: String = child.get_uniform_declaration()
			if decl != "":
				uniform_lines += decl + "\n"

	var shader_functions := {}
	for child in _graph.get_children():
		if child.has_method("get_shader_functions"):
			shader_functions.merge(child.get_shader_functions())
	var function_block := ""
	for fn in shader_functions:
		function_block += shader_functions[fn]

	var output_node = _graph.get_node_or_null("OutputNode")
	var render_mode: String = output_node.get_render_mode() if output_node else ""
	var render_mode_line: String = ("render_mode %s;\n" % render_mode) if render_mode != "" else ""

	var c = _graph.get_connection_list()
	var albedo    = _get_snippet_for("OutputNode", 0, c, "vec3(0.5, 0.5, 0.5)")
	var alpha     = _get_snippet_for("OutputNode", 1, c, "1.0")
	var roughness = _get_snippet_for("OutputNode", 2, c, "1.0")
	var metallic  = _get_snippet_for("OutputNode", 3, c, "0.0")
	var emission  = _get_snippet_for("OutputNode", 4, c, "vec3(0.0, 0.0, 0.0)")
	var normal    = _get_snippet_for("OutputNode", 5, c, "")
	var normal_line := "\tNORMAL_MAP = %s;\n" % normal if normal != "" else ""
	return "shader_type spatial;\n%s%s\n%svoid fragment() {\n\tALBEDO = %s;\n\tALPHA = %s;\n\tROUGHNESS = %s;\n\tMETALLIC = %s;\n\tEMISSION = %s;\n%s}\n" % [render_mode_line, uniform_lines, function_block, albedo, alpha, roughness, metallic, emission, normal_line]


func _apply_texture_uniforms() -> void:
	for child in _graph.get_children():
		if child.has_method("get_uniform_declaration"):
			_shader_material.set_shader_parameter(child.get_uniform_name(), child.get_texture())


func _compile_shader() -> void:
	if _graph.get_node_or_null("OutputNode"):
		var code := _build_shader_code()
		if code != _last_shader_code:
			_last_shader_code = code
			_shader_material.shader.code = code
		_apply_texture_uniforms()
	_refresh_all_node_previews()


func _on_texture_pick_requested(node: Node) -> void:
	_texture_target = node
	_texture_dialog.popup_centered_ratio(0.5)


func _on_texture_file_selected(path: String) -> void:
	if not _texture_target:
		return
	var tex = load(path)
	if tex is Texture2D:
		_push_undo_state()
		_texture_target.set_texture(tex)
	_texture_target = null


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

	# Collect texture nodes (have a texture assigned) and float param nodes
	var tex_nodes := []
	var float_param_nodes := []
	for child in _graph.get_children():
		if not child.has_method("get_uniform_declaration"):
			continue
		var decl: String = child.get_uniform_declaration()
		if decl == "":
			continue
		if child.has_method("get_texture"):
			if child.get_texture() != null:
				tex_nodes.append(child)
		elif "float" in decl:
			float_param_nodes.append(child)

	var load_steps := 1 + tex_nodes.size() + 1
	var lines := PackedStringArray()
	lines.append("[gd_resource type=\"ShaderMaterial\" load_steps=%d format=3]" % load_steps)
	lines.append("")
	lines.append("[ext_resource type=\"Shader\" path=\"%s\" id=\"1\"]" % path)

	var tex_id := 2
	var tex_id_map := {}
	for node in tex_nodes:
		var tex_path: String = node.get_texture().resource_path
		lines.append("[ext_resource type=\"Texture2D\" path=\"%s\" id=\"%d\"]" % [tex_path, tex_id])
		tex_id_map[node.get_uniform_name()] = tex_id
		tex_id += 1

	lines.append("")
	lines.append("[resource]")
	lines.append("shader = ExtResource(\"1\")")

	for uname in tex_id_map:
		lines.append("shader_parameter/%s = ExtResource(\"%d\")" % [uname, tex_id_map[uname]])

	for node in float_param_nodes:
		var decl: String = node.get_uniform_declaration()
		var param_name: String = decl.split(" ")[2]
		var value: float = node.get_state().get("value", 0.0)
		lines.append("shader_parameter/%s = %.4f" % [param_name, value])

	lines.append("")

	var tres_path := path.get_basename() + ".tres"
	var tf := FileAccess.open(tres_path, FileAccess.WRITE)
	if not tf:
		push_error("Nyx: could not write material to %s" % tres_path)
		return
	tf.store_string("\n".join(lines))
	tf.close()

	EditorInterface.get_resource_filesystem().scan()
	print("Nyx: exported\n  shader  → %s\n  material → %s" % [path, tres_path])


func _get_snippet_for(to_node: String, to_port: int, connections: Array, default_val: String) -> String:
	for conn in connections:
		if str(conn["to_node"]) == to_node and conn["to_port"] == to_port:
			var from := _graph.get_node_or_null(str(conn["from_node"]))
			if from:
				return _get_node_snippet(from, conn["from_port"], connections)
	return default_val


func _get_node_snippet(node: Node, from_port: int, connections: Array) -> String:
	var defaults = node.get_default_inputs() if node.has_method("get_default_inputs") else []
	var inputs := []
	for i in range(node.get_input_port_count()):
		var default_val = defaults[i] if i < defaults.size() else "0.0"
		inputs.append(_get_snippet_for(node.name, i, connections, default_val))
	return node.get_output_snippet(from_port, inputs)


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
	var from := _graph.get_node_or_null(str(from_node))
	var to := _graph.get_node_or_null(str(to_node))
	if not from or not to:
		return
	if from.get_output_port_type(from_port) != to.get_input_port_type(to_port):
		return
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
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_X:
			var selected: Array[StringName] = []
			for child in _graph.get_children():
				if child is GraphNode and child.selected:
					selected.append(child.name)
			if not selected.is_empty():
				_on_delete_nodes_request(selected)
		elif event.keycode == KEY_A:
			_spawn_position = _graph.get_local_mouse_position() / _graph.zoom + _graph.scroll_offset
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
		6: _add_node(SubtractNode.new(), _spawn_position)
		7: _add_node(ClampNode.new(), _spawn_position)
		8: _add_node(PowerNode.new(), _spawn_position)
		9: _add_node(SinNode.new(), _spawn_position)
		10: _add_node(CosNode.new(), _spawn_position)
		11: _add_node(TimeNode.new(), _spawn_position)
		12: _add_node(SplitNode.new(), _spawn_position)
		13: _add_node(CombineNode.new(), _spawn_position)
		14: _add_node(TextureSampleNode.new(), _spawn_position, "TextureSample")
		15: _add_node(FresnelNode.new(), _spawn_position)
		16: _add_node(ScaleNode.new(), _spawn_position)
		17: _add_node(StepNode.new(), _spawn_position)
		18: _add_node(SmoothstepNode.new(), _spawn_position)
		19: _add_node(NoiseNode.new(), _spawn_position)
		20: _add_node(VertexNode.new(), _spawn_position)
		21: _add_node(NormalMapNode.new(), _spawn_position, "NormalMap")
		22: _add_node(AbsNode.new(), _spawn_position)
		29: _add_node(CeilNode.new(), _spawn_position)
		30: _add_node(FloorNode.new(), _spawn_position)
		31: _add_node(FractNode.new(), _spawn_position)
		32: _add_node(NegateNode.new(), _spawn_position)
		33: _add_node(OneMinusNode.new(), _spawn_position)
		34: _add_node(RoundNode.new(), _spawn_position)
		35: _add_node(SqrtNode.new(), _spawn_position)
		23: _add_node(MinMaxNode.new(), _spawn_position)
		24: _add_node(DivideNode.new(), _spawn_position)
		25: _add_node(ModNode.new(), _spawn_position)
		26: _add_node(NormalizeNode.new(), _spawn_position)
		27: _add_node(LengthNode.new(), _spawn_position)
		28: _add_node(DotNode.new(), _spawn_position)


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
