@tool
extends Panel

## Nyx floating preview panel — owns the 3D/2D SubViewports, mesh switcher, particles
## preview, drag/resize, and the shader material state for the main preview.
##
## Public API (called by nyx_main):
##   setup(graph, container)          — wire refs, build UI (call after add_child)
##   compile(code, shader_type) → bool — push compiled GLSL; returns true if code changed
##   apply_uniforms()                 — walk graph children, push texture/param uniforms
##   get_active_material()            — spatial / 2D / particle ShaderMaterial
##   update_for_shader_type(type)     — toggle viewport/mesh/particle visibility
##   place_default(graph_top)         — initial anchoring (called deferred by nyx_main)
##   reanchor(graph_top, outer_width) — re-pin after window resize
##   reset_last_code()                — force next compile() to always push (on new/load)
##   is_placed() → bool              — true once placed at least once
##
## One-way dep: holds _graph (for uniform walk) and _graph_container (for drag clamping).
## Never reaches back into nyx_main. Extracted from nyx_main.gd.

var _graph: GraphEdit
var _graph_container: Control

var _shader_type: int = 0              # mirrored from nyx_main; set by update_for_shader_type
var _last_shader_code: String = ""

var _viewport: SubViewport
var _viewport_2d: SubViewport
var _vpc_3d: SubViewportContainer
var _vpc_2d: SubViewportContainer
var _preview_mesh: MeshInstance3D
var _preview_camera: Camera3D
var _preview_mesh_buttons: Array[Button] = []
var _shader_material: ShaderMaterial
var _shader_material_2d: ShaderMaterial
var _shader_material_particle: ShaderMaterial
var _particles: GPUParticles3D
var _mesh_row: Control

var _right_offset: float = 20.0
var _top_offset: float = -1.0          # -1 = not yet placed
var _dragging: bool = false
var _resizing: bool = false


func setup(graph: GraphEdit, graph_container: Control) -> void:
	_graph = graph
	_graph_container = graph_container
	_build()


# ── Public API ────────────────────────────────────────────────────────────────

func compile(code: String, shader_type: int) -> bool:
	if code == _last_shader_code:
		return false
	_last_shader_code = code
	var mat := get_active_material()
	if mat:
		mat.shader.code = code
		if shader_type == 2 and _particles:
			_particles.restart()
	return true


func apply_uniforms() -> void:
	var mat := get_active_material()
	if mat == null:
		return
	for child in _graph.get_children():
		if child.has_method("get_uniform_name") and child.has_method("get_texture"):
			var tex = child.get_texture()
			if tex:
				mat.set_shader_parameter(child.get_uniform_name(), tex)
		if child.has_method("apply_shader_params"):
			child.apply_shader_params(mat)


func get_active_material() -> ShaderMaterial:
	if _shader_type == 2:
		return _shader_material_particle
	return _shader_material_2d if _shader_type == 1 else _shader_material


func update_for_shader_type(type: int) -> void:
	_shader_type = type
	if _preview_mesh:
		_preview_mesh.visible = type == 0
	if _particles:
		_particles.visible = type == 2
		_particles.emitting = type == 2
	if _mesh_row:
		_mesh_row.visible = type == 0
	if _vpc_3d:
		_vpc_3d.visible = type == 0 or type == 2  # particles reuse the 3D viewport
	if _vpc_2d:
		_vpc_2d.visible = type == 1


func place_default(graph_top: float) -> void:
	_top_offset = graph_top + 12.0
	_right_offset = 20.0
	position = Vector2(_graph_container.size.x - size.x - _right_offset, _top_offset)


func reanchor(graph_top: float, outer_width: float) -> void:
	if _top_offset < 0.0:
		return
	position = Vector2(
		_graph_container.size.x - size.x - _right_offset,
		_top_offset
	).clamp(
		Vector2(0.0, graph_top),
		Vector2(outer_width, graph_top + _graph_container.size.y) - size
	)


func reset_last_code() -> void:
	_last_shader_code = ""


func is_placed() -> bool:
	return _top_offset >= 0.0


# ── UI build ──────────────────────────────────────────────────────────────────

func _build() -> void:
	size = Vector2(220, 200)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.13, 0.13, 0.16, 0.95)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var header_wrap := PanelContainer.new()
	var header_bg := StyleBoxFlat.new()
	header_bg.bg_color = get_theme_color("base_color", "Editor")
	header_bg.corner_radius_top_left = 6
	header_bg.corner_radius_top_right = 6
	header_bg.border_width_bottom = 2
	header_bg.border_color = Color(0.12, 0.12, 0.16)
	header_wrap.add_theme_stylebox_override("panel", header_bg)
	vbox.add_child(header_wrap)

	var header := HBoxContainer.new()
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.gui_input.connect(_on_header_input)
	header_wrap.add_child(header)

	var pad_left := Control.new()
	pad_left.custom_minimum_size = Vector2(2, 0)
	pad_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(pad_left)

	var title := Label.new()
	title.text = "Preview"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var toggle := Button.new()
	toggle.text = "×"
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.add_theme_font_size_override("font_size", 16)
	toggle.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	toggle.add_theme_color_override("font_hover_color", Color("#4AAF78"))
	var empty := StyleBoxEmpty.new()
	toggle.add_theme_stylebox_override("normal", empty)
	toggle.add_theme_stylebox_override("hover", empty)
	toggle.add_theme_stylebox_override("pressed", empty)
	toggle.add_theme_stylebox_override("focus", empty)
	toggle.pressed.connect(func(): visible = false)
	header.add_child(toggle)

	var pad_right := Control.new()
	pad_right.custom_minimum_size = Vector2(2, 0)
	pad_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(pad_right)

	# Floating mesh-switcher icon stack — anchored to bottom-right of the panel.
	var mesh_stack := VBoxContainer.new()
	mesh_stack.add_theme_constant_override("separation", 2)
	mesh_stack.set_anchor(SIDE_RIGHT, 1.0)
	mesh_stack.set_anchor(SIDE_BOTTOM, 1.0)
	mesh_stack.set_anchor(SIDE_LEFT, 1.0)
	mesh_stack.set_anchor(SIDE_TOP, 1.0)
	mesh_stack.set_offset(SIDE_RIGHT, -8)
	mesh_stack.set_offset(SIDE_BOTTOM, -4)
	mesh_stack.set_offset(SIDE_LEFT, -32)
	mesh_stack.set_offset(SIDE_TOP, -82)
	mesh_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mesh_stack)
	_mesh_row = mesh_stack

	for pair in [["sphere", SphereMesh.new(), Vector3.ZERO, 1.2], ["plane", QuadMesh.new(), Vector3.ZERO, 1.2], ["cube", BoxMesh.new(), Vector3(20, 40, 20), 1.8]]:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(24, 24)
		btn.toggle_mode = true
		btn.button_pressed = pair[0] == "sphere"
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		var icon_path := "res://addons/nyx/icons/preview/%s.svg" % pair[0]
		if ResourceLoader.exists(icon_path):
			var tex := load(icon_path) as Texture2D
			if tex:
				var img := tex.get_image()
				img.resize(16, 16, Image.INTERPOLATE_LANCZOS)
				for y in img.get_height():
					for x in img.get_width():
						var px := img.get_pixel(x, y)
						if px.a > 0.0:
							img.set_pixel(x, y, Color(1.0, 1.0, 1.0, px.a))
				btn.icon = ImageTexture.create_from_image(img)
		btn.add_theme_color_override("icon_normal_color", Color(0.55, 0.55, 0.65))
		btn.add_theme_color_override("icon_pressed_color", Color("#4AAF78"))
		btn.add_theme_color_override("icon_hover_color", Color(0.9, 0.9, 0.95))
		btn.add_theme_color_override("icon_hover_pressed_color", Color("#4AAF78"))
		var _s := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", _s)
		btn.add_theme_stylebox_override("hover", _s)
		btn.add_theme_stylebox_override("pressed", _s)
		btn.add_theme_stylebox_override("focus", _s)
		btn.pressed.connect(_on_mesh_btn_pressed.bind(btn, pair[1], pair[2], pair[3]))
		mesh_stack.add_child(btn)
		_preview_mesh_buttons.append(btn)

	# 3D SubViewport
	var vpc := SubViewportContainer.new()
	vpc.stretch = true
	vpc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vpc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(vpc)
	_vpc_3d = vpc

	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
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

	# Particle preview — GPUParticles3D sharing the 3D viewport.
	# Its process material is the compiled particle shader; the draw pass is a
	# small additive billboard quad tinted by COLOR. Preview-only, not exported.
	_shader_material_particle = ShaderMaterial.new()
	_shader_material_particle.shader = Shader.new()
	_shader_material_particle.shader.code = "shader_type particles;\nvoid start() {}\nvoid process() {}\n"

	_particles = GPUParticles3D.new()
	_particles.amount = 48
	_particles.lifetime = 2.0
	_particles.process_material = _shader_material_particle
	var quad := QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.vertex_color_use_as_albedo = true
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	quad.material = draw_mat
	_particles.draw_pass_1 = quad
	_particles.visible = false
	_particles.emitting = false
	_viewport.add_child(_particles)

	# 2D SubViewport (canvas_item shader type)
	_vpc_2d = SubViewportContainer.new()
	_vpc_2d.stretch = true
	_vpc_2d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vpc_2d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vpc_2d.visible = false
	vbox.add_child(_vpc_2d)

	_viewport_2d = SubViewport.new()
	_viewport_2d.transparent_bg = true
	_viewport_2d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vpc_2d.add_child(_viewport_2d)

	var preview_rect := ColorRect.new()
	preview_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shader_material_2d = ShaderMaterial.new()
	_shader_material_2d.shader = Shader.new()
	_shader_material_2d.shader.code = "shader_type canvas_item;\nvoid fragment() { COLOR = vec4(0.5, 0.5, 0.5, 1.0); }\n"
	preview_rect.material = _shader_material_2d
	_viewport_2d.add_child(preview_rect)

	# Resize grip (bottom-right corner)
	var grip := Control.new()
	grip.size = Vector2(16, 16)
	grip.anchor_left = 1.0
	grip.anchor_top = 1.0
	grip.anchor_right = 1.0
	grip.anchor_bottom = 1.0
	grip.offset_left = -16
	grip.offset_top = -16
	grip.mouse_default_cursor_shape = 12
	grip.gui_input.connect(_on_resize_input)
	add_child(grip)


# ── Internal handlers ─────────────────────────────────────────────────────────

func _on_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		position += event.relative
		_right_offset = _graph_container.size.x - position.x - size.x
		_top_offset = position.y


func _on_resize_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_resizing = event.pressed
	elif event is InputEventMouseMotion and _resizing:
		var new_size: Vector2 = size + event.relative
		new_size.x = max(new_size.x, 160.0)
		new_size.y = max(new_size.y, 120.0)
		size = new_size


func _on_mesh_btn_pressed(btn: Button, mesh: Mesh, rotation: Vector3, cam_z: float) -> void:
	_preview_mesh.mesh = mesh
	_preview_mesh.rotation_degrees = rotation
	_preview_camera.position.z = cam_z
	for b in _preview_mesh_buttons:
		b.button_pressed = b == btn
