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
##   set_preview_mesh_settings(h,s,c) — plane orientation/subdivisions + mesh scale (Graph Settings)
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

const _ORBIT_SPEED := 0.01
const _MIN_CAM_DISTANCE := 0.3
const _MAX_CAM_DISTANCE := 6.0
var _cam_yaw: float = 0.0
var _cam_pitch: float = 0.0
var _cam_distance: float = 1.2
var _preview_mesh_scale: float = 1.0
var _default_cam_distance: float = 1.2   # per-mesh default, restored by the reset button
var _orbiting: bool = false
var _reset_cam_btn: Button
var _resize_grip: Control
var _resize_grip_left: Control
var _preview_plane_mesh: PlaneMesh
var _preview_sphere_mesh: SphereMesh
var _preview_cube_mesh: BoxMesh
var _shader_material: ShaderMaterial
var _shader_material_2d: ShaderMaterial
var _shader_material_particle: ShaderMaterial
var _particles: GPUParticles3D
var _mesh_row: Control

var _right_offset: float = 20.0
var _top_offset: float = -1.0          # -1 = not yet placed
var _dragging: bool = false
var _resizing: bool = false
var _resizing_left: bool = false


func setup(graph: GraphEdit, graph_container: Control) -> void:
	_graph = graph
	_graph_container = graph_container
	set_process(true)
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


# Graph Settings' "Preview Mesh" section — pushed here on graph load and on
# every popup edit. orientation/subdivisions only affect the plane option
# (the sphere/cube buttons don't touch _preview_plane_mesh at all).
#
# Scale resizes each mesh RESOURCE's own local geometry (PlaneMesh.size /
# SphereMesh.radius+height / BoxMesh.size) — NOT a Node3D transform scale.
# That was the first attempt, and it was a real bug (found live 2026-07-06
# testing ocean.nyx at scale 20: the mesh dissolved into swirling spirals
# that got wilder with higher scale). Root cause: World Position's vertex-
# stage snippet is `MODEL_MATRIX * VERTEX`, which DOES include a Node3D
# transform scale — but Ocean Waves' computed Offset gets added to VERTEX
# in LOCAL space, before MODEL_MATRIX. A transform-scale approach leaves the
# mesh's actual LOCAL vertex spacing tiny and fixed (e.g. ~0.01 units for a
# 2-unit plane at 202 subdivisions) while the WORLD position used for wave
# phase diverges far more between physically-adjacent local vertices as
# scale grows — decorrelating neighboring vertices' phases while the fixed-
# magnitude offset (set by the node's own amplitude/steepness, unrelated to
# our scale) stays disproportionately large relative to that tiny local
# extent. Resizing the mesh's own LOCAL geometry instead keeps local vertex
# spacing proportional to scale, so World Position ≈ local position at any
# scale and neighboring vertices stay correlated — exactly what a real,
# large-scale ocean plane needs (a small wave height relative to a big patch).
func set_preview_mesh_settings(horizontal: bool, subdivisions: int, scale: float) -> void:
	if _preview_plane_mesh:
		_preview_plane_mesh.orientation = PlaneMesh.FACE_Y if horizontal else PlaneMesh.FACE_Z
		_preview_plane_mesh.subdivide_width = subdivisions
		_preview_plane_mesh.subdivide_depth = subdivisions
		_preview_plane_mesh.size = Vector2(2.0, 2.0) * scale
	if _preview_sphere_mesh:
		_preview_sphere_mesh.radius = 0.5 * scale
		_preview_sphere_mesh.height = 1.0 * scale
	if _preview_cube_mesh:
		_preview_cube_mesh.size = Vector3(2.0, 2.0, 2.0) * scale
	# A scale change alone leaves the camera at whatever distance was right
	# for the OLD size — e.g. going to 20x with the camera still ~1.2 away
	# puts it deep inside individual wave crests, reading as noise rather
	# than an ocean. Re-frame proactively when scale itself changes (not on
	# orientation/subdivision-only edits, which shouldn't move the camera).
	if not is_equal_approx(scale, _preview_mesh_scale):
		_preview_mesh_scale = scale
		_cam_distance = _default_cam_distance * _preview_mesh_scale
		_update_camera_transform()
	else:
		_preview_mesh_scale = scale


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
	if _reset_cam_btn:
		_reset_cam_btn.visible = type == 0 or type == 2


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
	bg.bg_color = Color(0.14, 0.14, 0.18, 0.92)
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
	var header_base := get_theme_color("base_color", "Editor")
	header_bg.bg_color = Color(header_base.r, header_base.g, header_base.b, 0.95)
	header_bg.corner_radius_top_left = 6
	header_bg.corner_radius_top_right = 6
	header_bg.border_width_bottom = 1
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

	# PlaneMesh, orientation FACE_Y (horizontal "floor") by default — the
	# orientation any world-space horizontal displacement graph (Ocean Waves'
	# wp.xz, wind sway) actually assumes. Godot's QuadMesh turned out to be a
	# PlaneMesh subclass that just defaults orientation to FACE_Z (vertical
	# "card") instead (confirmed via ClassDB — verified 2026-07-06 while
	# fixing an earlier bug where using QuadMesh rendered wave math against
	# the wrong two axes entirely), so "horizontal vs. vertical" is just this
	# one property, not a mesh-type swap — see set_preview_mesh_settings().
	# Subdivided so vertex-displacement graphs actually show something — a bare
	# plane here is 4 verts and displaces to nothing; both subdivision and
	# orientation are user-adjustable via Graph Settings (see the public API).
	_preview_plane_mesh = PlaneMesh.new()
	_preview_plane_mesh.subdivide_width = 64
	_preview_plane_mesh.subdivide_depth = 64
	_preview_sphere_mesh = SphereMesh.new()
	_preview_cube_mesh = BoxMesh.new()
	for pair in [["sphere", _preview_sphere_mesh, Vector3.ZERO, 1.2], ["plane", _preview_plane_mesh, Vector3.ZERO, 1.2], ["cube", _preview_cube_mesh, Vector3(20, 40, 20), 1.8]]:
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
	vpc.mouse_filter = Control.MOUSE_FILTER_STOP
	vpc.mouse_default_cursor_shape = Control.CURSOR_MOVE
	vpc.gui_input.connect(_on_viewport_input)
	vbox.add_child(vpc)
	_vpc_3d = vpc

	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vpc.add_child(_viewport)

	_preview_camera = Camera3D.new()
	_viewport.add_child(_preview_camera)
	_update_camera_transform()

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

	# Reset-camera button — top-right corner of the viewport, clears the header.
	# Snaps orbit back to (yaw=0, pitch=0) and zoom back to the current mesh's
	# default distance (tracked separately from the live _cam_distance so
	# switching meshes doesn't lose the user's own reset point).
	var reset_cam := Button.new()
	reset_cam.text = "⟲"
	reset_cam.tooltip_text = "Reset camera"
	reset_cam.focus_mode = Control.FOCUS_NONE
	reset_cam.add_theme_font_size_override("font_size", 15)
	reset_cam.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	reset_cam.add_theme_color_override("font_hover_color", Color("#4AAF78"))
	var reset_empty := StyleBoxEmpty.new()
	reset_cam.add_theme_stylebox_override("normal", reset_empty)
	reset_cam.add_theme_stylebox_override("hover", reset_empty)
	reset_cam.add_theme_stylebox_override("pressed", reset_empty)
	reset_cam.add_theme_stylebox_override("focus", reset_empty)
	reset_cam.set_anchor(SIDE_LEFT, 1.0)
	reset_cam.set_anchor(SIDE_RIGHT, 1.0)
	reset_cam.set_anchor(SIDE_TOP, 0.0)
	reset_cam.set_anchor(SIDE_BOTTOM, 0.0)
	reset_cam.set_offset(SIDE_LEFT, -24)
	reset_cam.set_offset(SIDE_RIGHT, -4)
	reset_cam.set_offset(SIDE_TOP, 28)
	reset_cam.set_offset(SIDE_BOTTOM, 48)
	reset_cam.pressed.connect(_on_reset_camera_pressed)
	add_child(reset_cam)
	_reset_cam_btn = reset_cam

	# Resize grip (bottom-right corner). All four offsets are set explicitly —
	# changing an anchor value does NOT recompute the opposite offset, it just
	# reinterprets whatever raw offset is already stored under the new anchor
	# basis. Leaving offset_right/offset_bottom at their .size-derived default
	# (16, meant for the anchor=0 basis) silently doubled the hit-box to 32x32
	# once anchor_right/anchor_bottom moved to 1.0 — confirmed via a headless
	# rect dump, not assumed. Same fix applies to the bottom-left grip below.
	var grip := Control.new()
	grip.anchor_left = 1.0
	grip.anchor_top = 1.0
	grip.anchor_right = 1.0
	grip.anchor_bottom = 1.0
	grip.offset_left = -16
	grip.offset_top = -16
	grip.offset_right = 0
	grip.offset_bottom = 0
	grip.mouse_default_cursor_shape = 12  # CURSOR_FDIAGSIZE ("\")
	grip.gui_input.connect(_on_resize_input)
	add_child(grip)
	_resize_grip = grip

	# Resize grip (bottom-left corner) — mirrors the right one; growing from
	# here keeps the top-right corner fixed, so position.x shifts with it.
	var grip_left := Control.new()
	grip_left.anchor_left = 0.0
	grip_left.anchor_top = 1.0
	grip_left.anchor_right = 0.0
	grip_left.anchor_bottom = 1.0
	grip_left.offset_left = 0
	grip_left.offset_top = -16
	grip_left.offset_right = 16
	grip_left.offset_bottom = 0
	grip_left.mouse_default_cursor_shape = 11  # CURSOR_BDIAGSIZE ("/")
	grip_left.gui_input.connect(_on_resize_input_left)
	add_child(grip_left)
	_resize_grip_left = grip_left


# ── Internal handlers ─────────────────────────────────────────────────────────

# Per-frame cursor correctness backstop — same pattern already proven in
# nyx_node.gd for the inspector cog's hover state (see Known Gotchas:
# "mouse_entered/mouse_exited are unreliable as the sole source of truth").
# Here the resize grips sit geometrically on top of the corners of a
# SubViewportContainer (vpc); moving from a grip into vpc without releasing
# a resize drag first left the cursor pinned at the grip's diagonal-resize
# shape instead of switching to vpc's orbit cursor, even on plain hover with
# no click involved — accept_event() on the drag handlers didn't fix it, so
# rather than keep chasing the exact signal that isn't firing, this
# re-derives the correct shape from raw mouse position every frame and just
# forces it, regardless of what stale internal state the signal-based path
# left behind.
func _process(_delta: float) -> void:
	if not visible or not is_inside_tree():
		return
	var mouse_pos := get_global_mouse_position()
	if not get_global_rect().has_point(mouse_pos):
		return
	var shape := Input.CURSOR_ARROW
	if _resizing:
		shape = Input.CURSOR_FDIAGSIZE
	elif _resizing_left:
		shape = Input.CURSOR_BDIAGSIZE
	elif _orbiting or _dragging:
		shape = Input.CURSOR_MOVE
	elif _resize_grip and _resize_grip.get_global_rect().has_point(mouse_pos):
		shape = Input.CURSOR_FDIAGSIZE
	elif _resize_grip_left and _resize_grip_left.get_global_rect().has_point(mouse_pos):
		shape = Input.CURSOR_BDIAGSIZE
	elif _vpc_3d and _vpc_3d.visible and _vpc_3d.get_global_rect().has_point(mouse_pos):
		shape = Input.CURSOR_MOVE
	Input.set_default_cursor_shape(shape)


func _on_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		position += event.relative
		_right_offset = _graph_container.size.x - position.x - size.x
		_top_offset = position.y
		accept_event()


func _on_resize_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_resizing = event.pressed
		accept_event()
	elif event is InputEventMouseMotion and _resizing:
		var new_size: Vector2 = size + event.relative
		new_size.x = max(new_size.x, 160.0)
		new_size.y = max(new_size.y, 120.0)
		size = new_size
		accept_event()


func _on_resize_input_left(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_resizing_left = event.pressed
		accept_event()
	elif event is InputEventMouseMotion and _resizing_left:
		var new_width: float = max(size.x - event.relative.x, 160.0)
		var new_height: float = max(size.y + event.relative.y, 120.0)
		var width_change := new_width - size.x
		position.x -= width_change
		size = Vector2(new_width, new_height)
		_right_offset = _graph_container.size.x - position.x - size.x
		accept_event()


func _on_mesh_btn_pressed(btn: Button, mesh: Mesh, rotation: Vector3, cam_z: float) -> void:
	_preview_mesh.mesh = mesh
	_preview_mesh.rotation_degrees = rotation
	_default_cam_distance = cam_z
	_cam_distance = cam_z * _preview_mesh_scale
	_update_camera_transform()
	for b in _preview_mesh_buttons:
		b.button_pressed = b == btn


func _on_reset_camera_pressed() -> void:
	_cam_yaw = 0.0
	_cam_pitch = 0.0
	_cam_distance = _default_cam_distance * _preview_mesh_scale
	_update_camera_transform()


func _on_viewport_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_orbiting = event.pressed
			accept_event()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cam_distance = max(_cam_distance * 0.9, _MIN_CAM_DISTANCE)
			_update_camera_transform()
			accept_event()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Upper clamp scales with the mesh scale factor too — otherwise a
			# 20x-scaled plane (Ocean Waves' actual motivating case) couldn't
			# be scrolled back out past the original hardcoded 6.0 once
			# re-framed further out than that by a scale change.
			_cam_distance = min(_cam_distance * 1.1, _MAX_CAM_DISTANCE * max(_preview_mesh_scale, 1.0))
			_update_camera_transform()
			accept_event()
	elif event is InputEventMouseMotion and _orbiting:
		_cam_yaw -= event.relative.x * _ORBIT_SPEED
		_cam_pitch = clamp(_cam_pitch - event.relative.y * _ORBIT_SPEED, -1.5, 1.5)
		_update_camera_transform()
		accept_event()


func _update_camera_transform() -> void:
	var dir := Vector3(
		cos(_cam_pitch) * sin(_cam_yaw),
		sin(_cam_pitch),
		cos(_cam_pitch) * cos(_cam_yaw)
	)
	_preview_camera.position = dir * _cam_distance
	_preview_camera.look_at(Vector3.ZERO, Vector3.UP)
