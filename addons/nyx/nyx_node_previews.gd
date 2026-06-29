@tool
extends Node

## Per-node preview manager — owns the SubViewport-per-node lifecycle.
##
## State lives on each node via meta ("_preview_material", "_preview_viewport") rather
## than in a central dict, so the manager needs no cleanup tracking — closing a node just
## removes its meta and frees its SubViewport. SubViewports are children of this Node
## (which is itself a child of nyx_main), so they're in the scene tree and render.
##
## One-way dep: needs the GraphEdit (to walk children for texture uniforms) and the
## compiler (to build per-node preview shaders). Never reaches back into nyx_main.
## Extracted from nyx_main.gd.

var _graph: GraphEdit
var _compiler  # NyxCompiler — untyped (no class_name), use explicit types on return vals


func setup(graph: GraphEdit, compiler) -> void:
	_graph = graph
	_compiler = compiler


func open(node: Node, shader_type: int) -> void:
	# No per-node previews in particle mode — values are per-particle and a
	# spatial preview shader would reference particle-only builtins (CUSTOM etc).
	if shader_type == 2:
		return
	var tex_rect: TextureRect = node.get_preview_slot()
	if not tex_rect:
		return

	var vp := SubViewport.new()
	vp.size = Vector2i(100, 100)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()

	if shader_type == 1:
		# Canvas Item — use a ColorRect
		mat.shader.code = "shader_type canvas_item;\nrender_mode unshaded;\nvoid fragment() { COLOR = vec4(0.5, 0.5, 0.5, 1.0); }"
		var rect := ColorRect.new()
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.material = mat
		vp.add_child(rect)
	else:
		# Spatial — use a quad mesh with camera + light
		vp.own_world_3d = true
		var cam := Camera3D.new()
		cam.position = Vector3(0, 0, 1.2)
		vp.add_child(cam)
		cam.make_current()
		var mesh_inst := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1.84, 1.84)
		mesh_inst.mesh = qm
		mat.shader.code = "shader_type spatial;\nrender_mode unshaded;\nvoid fragment() { ALBEDO = vec3(0.5); }"
		mesh_inst.material_override = mat
		vp.add_child(mesh_inst)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45, 45, 0)
		vp.add_child(light)

	tex_rect.texture = vp.get_texture()
	node.set_meta("_preview_material", mat)
	node.set_meta("_preview_viewport", vp)
	refresh(node, shader_type)


func close(node: Node) -> void:
	if node.has_meta("_preview_material"):
		node.remove_meta("_preview_material")
	if node.has_meta("_preview_viewport"):
		(node.get_meta("_preview_viewport") as Node).queue_free()
		node.remove_meta("_preview_viewport")
	var tex_rect: TextureRect = node.get_preview_slot()
	if tex_rect:
		tex_rect.texture = null


func refresh(node: Node, shader_type: int) -> void:
	if not node.has_meta("_preview_material"):
		return
	var mat: ShaderMaterial = node.get_meta("_preview_material")
	mat.shader.code = _compiler.build_node_preview_shader(node, shader_type)
	for child in _graph.get_children():
		if child.has_method("get_uniform_name") and child.has_method("get_texture"):
			var tex = child.get_texture()
			if tex:
				mat.set_shader_parameter(child.get_uniform_name(), tex)


func refresh_all(shader_type: int) -> void:
	for child in _graph.get_children():
		if child.has_meta("_preview_material"):
			refresh(child, shader_type)
