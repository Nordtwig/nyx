@tool
extends RefCounted

## Nyx shader compiler — walks the graph backwards from the sink nodes and emits
## GLSL snippet strings. Pure logic: its only state is the GraphEdit reference; the
## shader type is passed per-compile (it changes). No back-reference to nyx_main.
##
## Extracted from nyx_main.gd (the God-Object split). Public API:
##   build_shader_code(shader_type)              → full shader source
##   build_node_preview_shader(node, shader_type) → per-node preview shader source
##   update_all_polymorphic_ports()              → resync GraphEdit poly-port colors
##   resolve_output_type(node, from_port)        → resolved output type (connection validation)
##   can_promote(from_type, to_type)             → promotion-matrix check (connection validation)

const NyxNodeBase = preload("res://addons/nyx/nodes/nyx_node.gd")

var graph: GraphEdit


func _init(graph_edit: GraphEdit) -> void:
	graph = graph_edit


func build_node_preview_shader(node: Node, shader_type: int) -> String:
	var c = graph.get_connection_list()

	var uniform_lines := ""
	var seen_decls := {}
	for child in graph.get_children():
		if child.has_method("get_uniform_declaration"):
			var decl: String = child.get_uniform_declaration()
			if decl != "" and not seen_decls.has(decl):
				uniform_lines += decl + "\n"
				seen_decls[decl] = true

	var shader_functions := {}
	for child in graph.get_children():
		if child.has_method("get_shader_functions"):
			shader_functions.merge(child.get_shader_functions())
	var function_block := ""
	for fn in shader_functions:
		function_block += shader_functions[fn]

	var preview_expr: String
	if node.get_output_port_count() == 0:
		preview_expr = _get_snippet_for(node.name, 0, c, "vec3(0.5, 0.5, 0.5)")
	else:
		var node_result := _get_node_snippet(node, 0, c)
		preview_expr = _to_vec3_display(node_result[0], node_result[1])

	if shader_type == 1:
		return "shader_type canvas_item;\nrender_mode unshaded;\n%s\n%svoid fragment() {\n\tCOLOR = vec4(%s, 1.0);\n}\n" % [uniform_lines, function_block, preview_expr]

	return "shader_type spatial;\nrender_mode unshaded;\n%s\n%svoid fragment() {\n\tALBEDO = %s;\n}\n" % [uniform_lines, function_block, preview_expr]


func build_shader_code(shader_type: int) -> String:
	var uniform_lines := ""
	var seen_decls := {}
	for child in graph.get_children():
		if child.has_method("get_uniform_declaration"):
			var decl: String = child.get_uniform_declaration()
			if decl != "" and not seen_decls.has(decl):
				uniform_lines += decl + "\n"
				seen_decls[decl] = true

	var shader_functions := {}
	for child in graph.get_children():
		if child.has_method("get_shader_functions"):
			shader_functions.merge(child.get_shader_functions())
	var function_block := ""
	for fn in shader_functions:
		function_block += shader_functions[fn]

	var output_node = graph.get_node_or_null("OutputNode")
	var render_mode: String = output_node.get_render_mode() if output_node else ""
	var render_mode_line: String = ("render_mode %s;\n" % render_mode) if render_mode != "" else ""

	var c = graph.get_connection_list()

	if shader_type == 1:
		# Canvas Item
		var color  = _get_snippet_for("OutputNode", 0, c, "vec3(1.0, 1.0, 1.0)")
		var alpha  = _get_snippet_for("OutputNode", 1, c, "1.0")
		var normal = _get_snippet_for("OutputNode", 2, c, "")
		var normal_line := "\tNORMAL_MAP = %s;\n" % normal if normal != "" else ""
		return "shader_type canvas_item;\n%s%s\n%svoid fragment() {\n\tCOLOR = vec4(%s, %s);\n%s}\n" % [render_mode_line, uniform_lines, function_block, color, alpha, normal_line]

	if shader_type == 2:
		# Particles — process shader. Two entry points: start() (once, on spawn)
		# and process() (per frame). TRANSFORM is recomposed from decomposed
		# Position/Rotation/Scale via nyx_compose_transform. CUSTOM.y is reserved
		# for age tracking (0 at spawn, += DELTA/LIFETIME each frame → Age Ratio).
		var compose_fn := "mat4 nyx_compose_transform(vec3 pos, vec3 euler, vec3 scale) {\n" \
			+ "\tfloat cx = cos(euler.x); float sx = sin(euler.x);\n" \
			+ "\tfloat cy = cos(euler.y); float sy = sin(euler.y);\n" \
			+ "\tfloat cz = cos(euler.z); float sz = sin(euler.z);\n" \
			+ "\tmat3 rx = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cx, sx), vec3(0.0, -sx, cx));\n" \
			+ "\tmat3 ry = mat3(vec3(cy, 0.0, -sy), vec3(0.0, 1.0, 0.0), vec3(sy, 0.0, cy));\n" \
			+ "\tmat3 rz = mat3(vec3(cz, sz, 0.0), vec3(-sz, cz, 0.0), vec3(0.0, 0.0, 1.0));\n" \
			+ "\tmat3 basis = rz * ry * rx;\n" \
			+ "\tbasis[0] *= scale.x; basis[1] *= scale.y; basis[2] *= scale.z;\n" \
			+ "\tmat4 m;\n" \
			+ "\tm[0] = vec4(basis[0], 0.0);\n" \
			+ "\tm[1] = vec4(basis[1], 0.0);\n" \
			+ "\tm[2] = vec4(basis[2], 0.0);\n" \
			+ "\tm[3] = vec4(pos, 1.0);\n" \
			+ "\treturn m;\n}\n\n"

		var s_pos := "vec3(0.0)"
		var s_vel := "vec3(0.0)"
		var s_col := "vec4(1.0)"
		var s_scale := "vec3(1.0)"
		var s_rot := "vec3(0.0)"
		if graph.get_node_or_null("ParticleStartNode"):
			s_pos   = _get_typed_snippet_for("ParticleStartNode", 0, c, "vec3(0.0)", 0)
			s_vel   = _get_typed_snippet_for("ParticleStartNode", 1, c, "vec3(0.0)", 0)
			s_col   = _get_typed_snippet_for("ParticleStartNode", 2, c, "vec4(1.0)", 3)
			s_scale = _get_typed_snippet_for("ParticleStartNode", 3, c, "vec3(1.0)", 0)
			s_rot   = _get_typed_snippet_for("ParticleStartNode", 4, c, "vec3(0.0)", 0)

		var start_body := "\tTRANSFORM = EMISSION_TRANSFORM * nyx_compose_transform(%s, %s, %s);\n" % [s_pos, s_rot, s_scale]
		start_body += "\tVELOCITY = %s;\n" % s_vel
		start_body += "\tCOLOR = %s;\n" % s_col
		start_body += "\tCUSTOM.y = 0.0;\n"

		var process_body := "\tCUSTOM.y += DELTA / max(LIFETIME, 0.0001);\n"
		var p_pos := ""
		if graph.get_node_or_null("ParticleProcessNode"):
			var p_vel := _get_typed_snippet_for("ParticleProcessNode", 0, c, "", 0)
			var p_col := _get_typed_snippet_for("ParticleProcessNode", 1, c, "", 3)
			p_pos = _get_typed_snippet_for("ParticleProcessNode", 2, c, "", 0)
			if p_vel != "":
				process_body += "\tVELOCITY = %s;\n" % p_vel
			if p_col != "":
				process_body += "\tCOLOR = %s;\n" % p_col
		if p_pos != "":
			process_body += "\tTRANSFORM[3].xyz = %s;\n" % p_pos
		else:
			process_body += "\tTRANSFORM[3].xyz += VELOCITY * DELTA;\n"

		return "shader_type particles;\n%s\n%s%svoid start() {\n%s}\n\nvoid process() {\n%s}\n" % [uniform_lines, function_block, compose_fn, start_body, process_body]

	# Spatial — Fragment Output node
	var albedo    = _get_snippet_for("OutputNode", 0, c, "vec3(0.5, 0.5, 0.5)")
	var alpha     = _get_snippet_for("OutputNode", 1, c, "1.0")
	var roughness = _get_snippet_for("OutputNode", 2, c, "1.0")
	var metallic  = _get_snippet_for("OutputNode", 3, c, "0.0")
	var emission  = _get_snippet_for("OutputNode", 4, c, "vec3(0.0, 0.0, 0.0)")
	var normal    = _get_snippet_for("OutputNode", 5, c, "")
	var specular  = _get_snippet_for("OutputNode", 6, c, "")
	var ao        = _get_snippet_for("OutputNode", 7, c, "")
	var normal_line   := "\tNORMAL_MAP = %s;\n" % normal if normal != "" else ""
	var specular_line := "\tSPECULAR = %s;\n" % specular if specular != "" else ""
	var ao_line       := "\tAO = %s;\n" % ao if ao != "" else ""
	# Vertex Output node
	var vertex_offset = _get_snippet_for("VertexOutputNode", 0, c, "")
	var vert_normal   = _get_snippet_for("VertexOutputNode", 1, c, "")
	var vert_tangent  = _get_snippet_for("VertexOutputNode", 2, c, "")
	var vertex_lines := ""
	if vertex_offset != "":
		vertex_lines += "\tVERTEX += %s;\n" % vertex_offset
	if vert_normal != "":
		vertex_lines += "\tNORMAL = %s;\n" % vert_normal
	if vert_tangent != "":
		vertex_lines += "\tTANGENT = %s;\n" % vert_tangent
	var vertex_block := "void vertex() {\n%s}\n\n" % vertex_lines if vertex_lines != "" else ""
	return "shader_type spatial;\n%s%s\n%s%svoid fragment() {\n\tALBEDO = %s;\n\tALPHA = %s;\n\tROUGHNESS = %s;\n\tMETALLIC = %s;\n\tEMISSION = %s;\n%s%s%s}\n" % [render_mode_line, uniform_lines, function_block, vertex_block, albedo, alpha, roughness, metallic, emission, normal_line, specular_line, ao_line]


func _get_snippet_typed(to_node: String, to_port: int, connections: Array, default_val: String, default_type: int) -> Array:
	for conn in connections:
		if str(conn["to_node"]) == to_node and conn["to_port"] == to_port:
			var from := graph.get_node_or_null(str(conn["from_node"]))
			if from:
				return _get_node_snippet(from, conn["from_port"], connections)
	return [default_val, default_type]


func _get_snippet_for(to_node: String, to_port: int, connections: Array, default_val: String) -> String:
	# Heuristic default type from the literal — fine for float/vec3 defaults, but
	# can't tell vec3 from vec4. Use _get_typed_snippet_for when the slot is vec4.
	var default_type: int = 1 if not default_val.begins_with("vec") else 0
	return _get_typed_snippet_for(to_node, to_port, connections, default_val, default_type)


func _get_typed_snippet_for(to_node: String, to_port: int, connections: Array, default_val: String, default_type: int) -> String:
	var result := _get_snippet_typed(to_node, to_port, connections, default_val, default_type)
	var snippet: String = result[0]
	if snippet.is_empty():
		return snippet
	var from_type: int = result[1]
	var to_node_ref := graph.get_node_or_null(to_node)
	var to_type: int = to_node_ref.get_input_port_type(to_port) if to_node_ref else 0
	return _promote(snippet, from_type, to_type)


func _get_node_snippet(node: Node, from_port: int, connections: Array) -> Array:
	var defaults: Array = node.get_default_inputs() if node.has_method("get_default_inputs") else []
	var default_types: Array = node.get_default_input_types() if node.has_method("get_default_input_types") else []

	var raw_inputs := []
	for i in range(node.get_input_port_count()):
		var default_val: String = defaults[i] if i < defaults.size() else "0.0"
		var default_type: int = default_types[i] if i < default_types.size() else node.get_input_port_type(i)
		raw_inputs.append(_get_snippet_typed(node.name, i, connections, default_val, default_type))

	var input_types := []
	for r in raw_inputs:
		input_types.append(r[1])

	var output_type: int
	if node.has_method("get_output_type"):
		output_type = node.get_output_type(from_port, input_types)
	else:
		output_type = node.get_output_port_type(from_port) if node.get_output_port_count() > from_port else 0

	var is_poly: bool = node.has_method("is_polymorphic") and node.is_polymorphic()

	var inputs := []
	for i in range(raw_inputs.size()):
		var snippet: String = raw_inputs[i][0]
		var in_type: int = raw_inputs[i][1]
		# Polymorphic nodes operate at their resolved output type, so promote
		# every input up to it. Fixed-type nodes promote to the declared port type.
		var target_type: int = output_type if is_poly else (node.get_input_port_type(i) if i < node.get_input_port_count() else 0)
		inputs.append(_promote(snippet, in_type, target_type))

	return [node.get_output_snippet(from_port, inputs), output_type]


func resolve_output_type(node: Node, from_port: int) -> int:
	if not node.has_method("is_polymorphic") or not node.is_polymorphic():
		return node.get_output_port_type(from_port)
	var c := graph.get_connection_list()
	var default_types: Array = node.get_default_input_types() if node.has_method("get_default_input_types") else []
	var input_types := []
	for i in range(node.get_input_port_count()):
		var in_type: int = default_types[i] if i < default_types.size() else node.get_input_port_type(i)
		for conn in c:
			if str(conn["to_node"]) == node.name and conn["to_port"] == i:
				var from_n := graph.get_node_or_null(str(conn["from_node"]))
				if from_n:
					in_type = resolve_output_type(from_n, conn["from_port"])
				break
		input_types.append(in_type)
	return node.get_output_type(from_port, input_types) if node.has_method("get_output_type") else node.get_output_port_type(from_port)


func update_all_polymorphic_ports() -> void:
	for child in graph.get_children():
		if not (child is GraphNode):
			continue
		if not child.has_method("is_polymorphic") or not child.is_polymorphic():
			continue
		for port in range(child.get_output_port_count()):
			var resolved_type := resolve_output_type(child, port)
			if child.get_output_port_type(port) == resolved_type:
				continue
			var port_color := NyxNodeBase._type_color(resolved_type)
			child.set_slot(port,
				child.is_slot_enabled_left(port), child.get_slot_type_left(port), child.get_slot_color_left(port),
				child.is_slot_enabled_right(port), resolved_type, port_color)


func can_promote(from_type: int, to_type: int) -> bool:
	if from_type == to_type:
		return true
	match from_type:
		1: return to_type in [2, 0, 3]  # float → vec2/vec3/vec4
		2: return to_type in [0, 3]     # vec2  → vec3/vec4
		0: return to_type == 3          # vec3  → vec4
		3: return to_type == 0          # vec4  → vec3 (drop alpha, .rgb)
	return false


# Widen a GLSL snippet from one type to another (no-op if already matching).
func _promote(snippet: String, from_type: int, to_type: int) -> String:
	if from_type == to_type:
		return snippet
	match to_type:
		2:
			if from_type == 1: return "vec2(%s)" % snippet
		0:
			if from_type == 1: return "vec3(%s)" % snippet
			if from_type == 2: return "vec3(%s, 0.0)" % snippet
			if from_type == 3: return "(%s).rgb" % snippet
		3:
			if from_type == 1: return "vec4(%s)" % snippet
			if from_type == 2: return "vec4(%s, 0.0, 1.0)" % snippet
			if from_type == 0: return "vec4(%s, 1.0)" % snippet
	return snippet


# Narrow any type down to a vec3 for display in per-node previews.
func _to_vec3_display(snippet: String, type: int) -> String:
	match type:
		1: return "vec3(%s)" % snippet
		2: return "vec3(%s, 0.0)" % snippet
		3: return "(%s).rgb" % snippet
	return snippet
