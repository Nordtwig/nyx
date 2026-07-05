@tool
extends Node

## Per-node raw-value readback manager for Value Relay nodes — mirrors
## nyx_node_previews.gd's SubViewport-per-node lifecycle, but renders into a
## dedicated readback target (nyx_compiler.gd's build_node_value_shader)
## instead of a lit swatch, and reads the result back as exact numbers instead
## of assigning a texture. Opt-in like update_contextual_labels() — any node
## exposing set_value_readout_text() gets picked up automatically, no
## per-type wiring needed.
##
## Always uses the canvas_item readback technique, even inside a Spatial
## graph — see nyx_compiler.gd's build_node_value_shader header for why that's
## the accurate path and the 3D/ALBEDO route isn't. depends_on_spatial_only_value()
## is the one real exception (Fresnel/Vertex/Object-World Position/Instance
## Custom Data/Depth Fade don't exist outside a real spatial shader), handled
## as a graceful "unavailable" instead of a silently wrong number.
##
## One-way dep: needs the GraphEdit (to walk children for texture uniforms)
## and the compiler (to build per-node value shaders). Never reaches back
## into nyx_main.

var _graph: GraphEdit
var _compiler  # NyxCompiler — untyped (no class_name), use explicit types on return vals


func setup(graph: GraphEdit, compiler) -> void:
	_graph = graph
	_compiler = compiler


func refresh_all(shader_type: int) -> void:
	for child in _graph.get_children():
		if child.has_method("set_value_readout_text"):
			_refresh(child, shader_type)


func _refresh(node: Node, shader_type: int) -> void:
	# Particle values are per-particle; the readback shader can't evaluate an
	# expression built from particle-only builtins (CUSTOM/INDEX/etc. only
	# exist inside a real particles shader). Same limitation per-node previews
	# already have (see depends_on_instance_custom_data).
	if shader_type == 2:
		close(node)
		node.set_value_readout_text("—", false, "No readout in particle mode — particle values are per-particle, not per-pixel.")
		return

	if _compiler.depends_on_spatial_only_value(node):
		close(node)
		node.set_value_readout_text("N/A", true,
			"Needs a real spatial shader — depends on view angle, vertex-stage, or per-instance data (Fresnel / Vertex / Object or World Position / Instance Custom Data / Depth Fade) that doesn't exist outside one.")
		return

	if not node.has_meta("_value_viewport"):
		_open(node)

	var result: Array = _compiler.build_node_value_shader(node)
	var mat: ShaderMaterial = node.get_meta("_value_material")
	mat.shader.code = result[0]
	for child in _graph.get_children():
		if child.has_method("get_uniform_name") and child.has_method("get_texture"):
			var tex = child.get_texture()
			if tex:
				mat.set_shader_parameter(child.get_uniform_name(), tex)

	var vtype: int = result[1]
	var vp: SubViewport = node.get_meta("_value_viewport")
	# Give the SubViewport a couple of frames to actually render the new
	# shader code before reading it back — get_image() otherwise risks
	# grabbing the previous frame's pixel.
	await _graph.get_tree().process_frame
	await _graph.get_tree().process_frame
	if not is_instance_valid(node) or not node.has_meta("_value_viewport"):
		return
	var img := vp.get_texture().get_image()
	var px := img.get_pixel(0, 0)
	var is_coordinate_dependent: bool = _compiler.depends_on_coordinate_value(node)
	node.set_value_readout_text(_format_value(px, vtype), is_coordinate_dependent,
		"This is a real value, but it's this readback's own reference coordinate — not necessarily the exact point you're inspecting in the main preview."
		if is_coordinate_dependent else "")


func _format_value(px: Color, vtype: int) -> String:
	match vtype:
		1: return "%.3f" % px.r
		2: return "%.3f, %.3f" % [px.r, px.g]
		3: return "%.3f, %.3f, %.3f, %.3f" % [px.r, px.g, px.b, px.a]
		_: return "%.3f, %.3f, %.3f" % [px.r, px.g, px.b]


func _open(node: Node) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1, 1)
	vp.transparent_bg = true
	vp.use_hdr_2d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = "shader_type canvas_item;\nrender_mode unshaded, blend_disabled;\nvoid fragment() { COLOR = vec4(0.0); }"

	var rect := ColorRect.new()
	rect.size = Vector2(1, 1)
	rect.material = mat
	vp.add_child(rect)

	add_child(vp)
	node.set_meta("_value_viewport", vp)
	node.set_meta("_value_material", mat)


func close(node: Node) -> void:
	if node.has_meta("_value_viewport"):
		(node.get_meta("_value_viewport") as Node).queue_free()
		node.remove_meta("_value_viewport")
	if node.has_meta("_value_material"):
		node.remove_meta("_value_material")
