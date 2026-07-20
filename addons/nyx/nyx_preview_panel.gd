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
##   is_focused_state() → bool       — true while in the FOCUSED panel state
##   exit_focus()                     — leave FOCUSED for AMBIENT (Esc handler)
##   is_freelooking() → bool         — true while RMB freelook is active
##   frame_target()                   — recenter/reframe the camera on the target (F)
##   set_scene_path(path)             — set the pinned scene target (from OutputNode)
##   restore_scene_mode(path,pinned)  — load-time: adopt pin state, open scene mode if pinned
##   on_active_scene_changed(root)    — follow the editor's active scene tab (from plugin.gd)
##   on_scene_saved(filepath)         — refresh the instance when its scene is saved
##   refresh_params()                 — rebuild the live-params drawer (on param/graph change)
## Signals:
##   scene_pin_changed(path, pinned)  — emitted when the user pins/unpins a scene
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
const _LOOK_SPEED := 0.006       # RMB freelook mouse sensitivity
const _PAN_SPEED := 0.0018       # screen-plane pan, scaled by distance
const _FREELOOK_SPEED := 1.4     # WASD units/sec, scaled by distance
const _MIN_CAM_DISTANCE := 0.3
const _MAX_CAM_DISTANCE := 6.0
var _cam_yaw: float = 0.0
var _cam_pitch: float = 0.0
var _cam_distance: float = 1.2
# Orbit pivot / freelook anchor. The camera always sits at
# _cam_focus + dir(yaw,pitch) * distance, looking at _cam_focus. Pan moves the
# focus in the screen plane; freelook moves the focus so the camera translates
# in place — the whole scheme stays expressible in these four values.
var _cam_focus := Vector3.ZERO
var _preview_mesh_scale: float = 1.0
var _default_cam_distance: float = 1.2   # per-mesh default, restored by the reset button
var _orbiting: bool = false
var _panning_cam: bool = false
var _freelook: bool = false

# Scene mode (Olympus Viewport). The active edited scene (or a pinned .tscn) is
# instanced into the same _viewport, replacing the preview mesh. Live shader
# updates ride the shared resource cache for free (see .nyx-notes/olympus-viewport.md).
signal scene_pin_changed(path: String, pinned: bool)
var _scene_active: bool = false
var _scene_path: String = ""           # the currently-instanced scene (follow: active tab; pinned: the pin)
var _pinned: bool = false              # locked to _pinned_scene_path vs. following the active tab
var _pinned_scene_path: String = ""    # persisted pin target (OutputNode)
var _scene_instance: Node              # instanced scene root, freed on exit/reload
var _default_light: DirectionalLight3D
var _scene_btn: Button
var _reload_btn: Button
var _pin_btn: Button
var _scene_msg: Label                  # shown when there's no scene / it failed to load
var _scene_max_distance: float = 6.0   # zoom-out cap while framing a (possibly large) scene
var _saved_mesh_cam: Dictionary = {}   # per-mode camera state, swapped on mesh↔scene

# Inline live-params drawer — a collapsible section along the bottom of the panel
# (wrench toggle in the titlebar). Distinct from the Blackboard: the Blackboard is
# the graph-side authoring view, this is the live tuning surface. Each row writes
# set_shader_parameter instantly to the target material (preview material in mesh
# mode, the scene's shared material in scene mode). See .nyx-notes/olympus-viewport.md.
var _wrench_btn: Button
var _params_drawer: PanelContainer
var _params_scroll: ScrollContainer
var _params_vbox: VBoxContainer
var _params_header: Label
var _params_open: bool = false
var _params_width: float = 200.0        # user-adjustable via the right-edge grip
var _params_grip: Control
var _params_resizing: bool = false
var _param_overrides: Dictionary = {}   # name -> value; reapplied after mesh-mode recompiles
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

# Three-rung panel-state ladder (see .nyx-notes/olympus-viewport.md):
#   MINIMIZED — titlebar only, SubViewport rendering paused.
#   AMBIENT   — the free-floating card; the only freely dragged/resized state.
#   FOCUSED   — fills most of the graph area for close inspection; Esc exits.
# Session state, never persisted to the .nyx (unlike Preview Mesh settings).
enum { STATE_MINIMIZED, STATE_AMBIENT, STATE_FOCUSED }
var _panel_state: int = STATE_AMBIENT
var _restore_size := Vector2(300, 260)   # ambient size, restored after minimize/focus
var _restore_position := Vector2.ZERO    # ambient position, ditto
var _graph_top: float = 0.0              # cached from place_default/reanchor for focused fill
var _header_wrap: PanelContainer
var _min_btn: Button
var _focus_btn: Button
const _FOCUS_MARGIN := 40.0


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
	# Re-assert any live overrides on top of the node defaults just written (mesh
	# mode only — scene materials aren't touched here, so their overrides persist
	# on their own across the code-only live push).
	if not _scene_active:
		for pname in _param_overrides:
			mat.set_shader_parameter(pname, _param_overrides[pname])


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
	# Scene mode only exists in spatial mode — leaving it tears the scene down.
	if type != 0 and _scene_active:
		_teardown_scene()
	_shader_type = type
	if _preview_mesh:
		_preview_mesh.visible = type == 0 and not _scene_active
	if _particles:
		_particles.visible = type == 2
		_particles.emitting = type == 2
	_refresh_body_visibility()
	_update_scene_ui()
	refresh_params()   # target material (and thus the header) changed with the mode


# The panel state (is the body shown at all?) and the shader type (which
# viewport/mesh row is relevant) both gate the same set of controls, so both
# funnel through here rather than setting .visible in two places that could
# disagree.
func _refresh_body_visibility() -> void:
	var body := _panel_state != STATE_MINIMIZED
	if _vpc_3d:
		_vpc_3d.visible = body and (_shader_type == 0 or _shader_type == 2)
	if _vpc_2d:
		_vpc_2d.visible = body and _shader_type == 1
	if _mesh_row:
		_mesh_row.visible = body and _shader_type == 0
	if _reset_cam_btn:
		_reset_cam_btn.visible = body and (_shader_type == 0 or _shader_type == 2)
	# Grips only make sense in the freely-sized ambient state.
	var grips := _panel_state == STATE_AMBIENT
	if _resize_grip:
		_resize_grip.visible = grips
	if _resize_grip_left:
		_resize_grip_left.visible = grips
	_update_scene_ui()
	_sync_drawer()   # hide the drawer when minimized, restore when not


func is_focused_state() -> bool:
	return _panel_state == STATE_FOCUSED


func exit_focus() -> void:
	if _panel_state == STATE_FOCUSED:
		_set_panel_state(STATE_AMBIENT)


func place_default(graph_top: float) -> void:
	_graph_top = graph_top
	_top_offset = graph_top + 12.0
	_right_offset = 20.0
	var pos := Vector2(_graph_container.size.x - size.x - _right_offset, _top_offset)
	_restore_position = pos
	_restore_size = size
	if _panel_state == STATE_AMBIENT:
		position = pos


func reanchor(graph_top: float, outer_width: float) -> void:
	_graph_top = graph_top
	if _panel_state == STATE_FOCUSED:
		_apply_focused()
		return
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
	# A new/loaded graph starts with no live overrides.
	_param_overrides.clear()
	refresh_params()


func is_placed() -> bool:
	return _top_offset >= 0.0


# ── UI build ──────────────────────────────────────────────────────────────────

func _build() -> void:
	size = Vector2(300, 260)

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
	_header_wrap = header_wrap

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

	# ⊟ collapse to titlebar / ⛶ fill the graph area / × close (reopen via the
	# command palette's "Toggle Preview Panel"). Minimize + focus each toggle
	# against Ambient; their active state shows as a green glyph via
	# _update_state_buttons (plain buttons, not toggle_mode — sidesteps the
	# toggle_mode auto-flip fighting the state machine, a documented gotcha).
	_min_btn = _make_header_button("⊟", "Minimize")
	_min_btn.pressed.connect(func() -> void:
		_set_panel_state(STATE_AMBIENT if _panel_state == STATE_MINIMIZED else STATE_MINIMIZED))
	header.add_child(_min_btn)

	_focus_btn = _make_header_button("⛶", "Focus (fill graph)")
	_focus_btn.pressed.connect(func() -> void:
		_set_panel_state(STATE_AMBIENT if _panel_state == STATE_FOCUSED else STATE_FOCUSED))
	header.add_child(_focus_btn)

	var toggle := _make_header_button("×", "Close")
	toggle.pressed.connect(func(): visible = false)
	header.add_child(toggle)

	var pad_right := Control.new()
	pad_right.custom_minimum_size = Vector2(2, 0)
	pad_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(pad_right)

	# Floating source-switcher icon stack — anchored to the bottom-right of the panel.
	var mesh_stack := VBoxContainer.new()
	mesh_stack.add_theme_constant_override("separation", 2)
	mesh_stack.set_anchor(SIDE_RIGHT, 1.0)
	mesh_stack.set_anchor(SIDE_BOTTOM, 1.0)
	mesh_stack.set_anchor(SIDE_LEFT, 1.0)
	mesh_stack.set_anchor(SIDE_TOP, 1.0)
	mesh_stack.set_offset(SIDE_RIGHT, -8)
	mesh_stack.set_offset(SIDE_BOTTOM, -4)
	mesh_stack.set_offset(SIDE_LEFT, -32)
	mesh_stack.set_offset(SIDE_TOP, -108)   # 4 switcher buttons (sphere/plane/cube/scene)
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
		var btn := _make_switcher_button(pair[0])
		btn.button_pressed = pair[0] == "sphere"
		btn.pressed.connect(_on_mesh_btn_pressed.bind(btn, pair[1], pair[2], pair[3]))
		mesh_stack.add_child(btn)
		_preview_mesh_buttons.append(btn)

	# 4th switcher option: instance a real scene into the viewport (Olympus
	# Viewport scene mode). Grouped with the mesh buttons so it inherits the
	# stack's spatial-only visibility.
	_scene_btn = _make_switcher_button("scene")
	_scene_btn.tooltip_text = "Preview in scene"
	_scene_btn.pressed.connect(_on_scene_btn_pressed)
	mesh_stack.add_child(_scene_btn)

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

	# Default lighting rig. Hidden in scene mode when the instanced scene brings
	# its own lights/environment (see _instance_scene) — the compatibility
	# renderer shows nothing without a light, so mesh mode always keeps it.
	_default_light = DirectionalLight3D.new()
	_default_light.rotation_degrees = Vector3(-45, 45, 0)
	_viewport.add_child(_default_light)

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

	# Live-params column — a left-edge overlay floating OVER the viewport (not a
	# bottom drawer): anchored down the left side, between the top-left scene
	# controls and the bottom-left wrench. Toggled by the wrench; collapsed by
	# default. On a small panel it covers the left of the scene, which is fine.
	_params_drawer = PanelContainer.new()
	var drawer_bg := StyleBoxFlat.new()
	drawer_bg.bg_color = Color(0.12, 0.12, 0.15, 0.92)
	drawer_bg.set_corner_radius_all(6)
	drawer_bg.border_width_left = 1
	drawer_bg.border_width_right = 1
	drawer_bg.border_width_top = 1
	drawer_bg.border_width_bottom = 1
	drawer_bg.border_color = Color(0.20, 0.20, 0.26)
	drawer_bg.content_margin_left = 6
	drawer_bg.content_margin_right = 6
	drawer_bg.content_margin_top = 4
	drawer_bg.content_margin_bottom = 6
	_params_drawer.add_theme_stylebox_override("panel", drawer_bg)
	_params_drawer.visible = false
	_params_drawer.set_anchor(SIDE_LEFT, 0.0)
	_params_drawer.set_anchor(SIDE_RIGHT, 0.0)
	_params_drawer.set_anchor(SIDE_TOP, 0.0)
	_params_drawer.set_anchor(SIDE_BOTTOM, 1.0)
	_params_drawer.set_offset(SIDE_LEFT, 8)
	_params_drawer.set_offset(SIDE_RIGHT, 8 + _params_width)  # width set via _update_params_width
	_params_drawer.set_offset(SIDE_TOP, 62)          # below the top-left scene controls
	_params_drawer.set_offset(SIDE_BOTTOM, -40)      # above the bottom-left wrench
	add_child(_params_drawer)

	var drawer_vbox := VBoxContainer.new()
	drawer_vbox.add_theme_constant_override("separation", 3)
	_params_drawer.add_child(drawer_vbox)

	_params_header = Label.new()
	_params_header.add_theme_font_size_override("font_size", 9)
	_params_header.add_theme_color_override("font_color", Color(0.55, 0.58, 0.64))
	_params_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	drawer_vbox.add_child(_params_header)

	_params_scroll = ScrollContainer.new()
	_params_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_params_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drawer_vbox.add_child(_params_scroll)

	_params_vbox = VBoxContainer.new()
	_params_vbox.add_theme_constant_override("separation", 4)
	_params_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_params_scroll.add_child(_params_vbox)

	# Wrench toggle — bottom-left overlay (mirrors the switcher stack at bottom-
	# right). Shown only when the graph exposes parameters; green while open.
	_wrench_btn = _make_switcher_button("wrench", false)
	_wrench_btn.tooltip_text = "Tune parameters"
	_wrench_btn.visible = false
	_wrench_btn.set_anchor(SIDE_LEFT, 0.0)
	_wrench_btn.set_anchor(SIDE_RIGHT, 0.0)
	_wrench_btn.set_anchor(SIDE_TOP, 1.0)
	_wrench_btn.set_anchor(SIDE_BOTTOM, 1.0)
	_wrench_btn.set_offset(SIDE_LEFT, 8)
	_wrench_btn.set_offset(SIDE_RIGHT, 32)
	_wrench_btn.set_offset(SIDE_TOP, -32)
	_wrench_btn.set_offset(SIDE_BOTTOM, -8)
	_wrench_btn.pressed.connect(_toggle_params_drawer)
	add_child(_wrench_btn)

	# Right-edge drag grip for the params column — resize its width (compact it or
	# widen it to fit long param names). Tracks the drawer's right edge.
	_params_grip = Control.new()
	_params_grip.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	_params_grip.visible = false
	_params_grip.gui_input.connect(_on_params_grip_input)
	add_child(_params_grip)
	_update_params_width()
	resized.connect(_update_params_width)   # re-clamp/reposition when the panel resizes

	# Reset-camera button — top-right corner of the viewport, on its own (a camera
	# control, kept separate from the scene-source controls in the switcher stack).
	# Snaps orbit back to (yaw=0, pitch=0) and zoom back to the current mesh's
	# default distance (tracked separately from the live _cam_distance so
	# switching meshes doesn't lose the user's own reset point).
	_reset_cam_btn = _make_switcher_button("focus", false)
	_reset_cam_btn.tooltip_text = "Reset camera"
	_reset_cam_btn.set_anchor(SIDE_LEFT, 1.0)
	_reset_cam_btn.set_anchor(SIDE_RIGHT, 1.0)
	_reset_cam_btn.set_anchor(SIDE_TOP, 0.0)
	_reset_cam_btn.set_anchor(SIDE_BOTTOM, 0.0)
	_reset_cam_btn.set_offset(SIDE_LEFT, -28)
	_reset_cam_btn.set_offset(SIDE_RIGHT, -4)
	_reset_cam_btn.set_offset(SIDE_TOP, 33)
	_reset_cam_btn.set_offset(SIDE_BOTTOM, 57)
	_reset_cam_btn.pressed.connect(_on_reset_camera_pressed)
	add_child(_reset_cam_btn)

	# Scene-only controls, top-left corner (opposite the reset-camera button).
	# Pin toggles follow/lock; reload re-instances from disk. Hidden until scene
	# mode via _update_scene_ui. Laid out as a horizontal pair: [pin][reload].
	_pin_btn = _make_switcher_button("pin")
	_pin_btn.visible = false
	_pin_btn.set_anchor(SIDE_LEFT, 0.0)
	_pin_btn.set_anchor(SIDE_RIGHT, 0.0)
	_pin_btn.set_offset(SIDE_LEFT, 8)
	_pin_btn.set_offset(SIDE_RIGHT, 32)
	_pin_btn.set_offset(SIDE_TOP, 33)
	_pin_btn.set_offset(SIDE_BOTTOM, 57)
	_pin_btn.pressed.connect(_on_pin_toggled)
	add_child(_pin_btn)

	_reload_btn = _make_switcher_button("refresh", false)
	_reload_btn.tooltip_text = "Reload scene"
	_reload_btn.visible = false
	_reload_btn.set_anchor(SIDE_LEFT, 0.0)
	_reload_btn.set_anchor(SIDE_RIGHT, 0.0)
	_reload_btn.set_offset(SIDE_LEFT, 34)
	_reload_btn.set_offset(SIDE_RIGHT, 58)
	_reload_btn.set_offset(SIDE_TOP, 33)
	_reload_btn.set_offset(SIDE_BOTTOM, 57)
	_reload_btn.pressed.connect(_on_reload_scene_pressed)
	add_child(_reload_btn)

	# Centered message when scene mode has nothing to show (no active/pinned
	# scene, or a load failure).
	var msg := Label.new()
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.visible = false
	msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	msg.add_theme_color_override("font_color", Color(0.6, 0.6, 0.68))
	msg.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	msg.set_anchor(SIDE_LEFT, 0.0)
	msg.set_anchor(SIDE_RIGHT, 1.0)
	msg.set_offset(SIDE_LEFT, 12)
	msg.set_offset(SIDE_RIGHT, -12)
	add_child(msg)
	_scene_msg = msg

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
func _process(delta: float) -> void:
	if not visible or not is_inside_tree():
		return
	if _freelook:
		# Safety net: if the RMB-release event was ever missed (focus loss etc.),
		# don't let freelook stick and keep swallowing WASD.
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_set_freelook(false)
		else:
			_freelook_move(delta)
	var mouse_pos := get_global_mouse_position()
	if not get_global_rect().has_point(mouse_pos):
		return
	var shape := Input.CURSOR_ARROW
	if _resizing:
		shape = Input.CURSOR_FDIAGSIZE
	elif _resizing_left:
		shape = Input.CURSOR_BDIAGSIZE
	elif _params_resizing:
		shape = Input.CURSOR_HSIZE
	elif _orbiting or _dragging:
		shape = Input.CURSOR_MOVE
	elif _params_grip and _params_grip.visible and _params_grip.get_global_rect().has_point(mouse_pos):
		shape = Input.CURSOR_HSIZE
	elif _resize_grip and _resize_grip.visible and _resize_grip.get_global_rect().has_point(mouse_pos):
		shape = Input.CURSOR_FDIAGSIZE
	elif _resize_grip_left and _resize_grip_left.visible and _resize_grip_left.get_global_rect().has_point(mouse_pos):
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
		# Dragging a rolled-up (minimized) card should carry over to where it
		# un-rolls, rather than snapping back to the pre-minimize spot.
		if _panel_state == STATE_MINIMIZED:
			_restore_position = position
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


# Shared factory for the bottom-right switcher buttons (sphere/plane/cube/scene):
# a 24px toggle button with the icon recolored to the standard grey/green states.
func _make_switcher_button(icon_name: String, toggle: bool = true) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(24, 24)
	btn.toggle_mode = toggle
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var icon_path := "res://addons/nyx/icons/preview/%s.svg" % icon_name
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
	var e := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", e)
	btn.add_theme_stylebox_override("hover", e)
	btn.add_theme_stylebox_override("pressed", e)
	btn.add_theme_stylebox_override("focus", e)
	return btn


func _on_mesh_btn_pressed(btn: Button, mesh: Mesh, rotation: Vector3, cam_z: float) -> void:
	if _scene_active:
		_teardown_scene()
	_preview_mesh.mesh = mesh
	_preview_mesh.rotation_degrees = rotation
	_default_cam_distance = cam_z
	_cam_distance = cam_z * _preview_mesh_scale
	_cam_focus = Vector3.ZERO
	_update_camera_transform()
	for b in _preview_mesh_buttons:
		b.button_pressed = b == btn
	if _scene_btn:
		_scene_btn.button_pressed = false


func _on_reset_camera_pressed() -> void:
	_cam_yaw = 0.0
	_cam_pitch = 0.0
	_cam_focus = Vector3.ZERO
	_cam_distance = _default_cam_distance * _preview_mesh_scale
	_update_camera_transform()


# Camera bindings mirror Godot's own 3D viewport as closely as a preview allows:
#   Orbit     — left-drag (preview convention; left is free here, nothing to
#               select) or middle-drag (Godot's own orbit button)
#   Pan       — Shift + left/middle-drag
#   Zoom      — mouse wheel
#   Freelook  — hold RMB, WASD/QE to fly, mouse to look, Shift to speed up
#               (WASD is only camera input while RMB is held, so it never
#               steals graph shortcuts — Godot's own convention solves that)
#   Frame     — F (handled in nyx_main, routed to frame_target)
func _on_viewport_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var b: int = event.button_index
		if b == MOUSE_BUTTON_LEFT or b == MOUSE_BUTTON_MIDDLE:
			if event.shift_pressed:
				_panning_cam = event.pressed
			else:
				_orbiting = event.pressed
			accept_event()
		elif b == MOUSE_BUTTON_RIGHT:
			_set_freelook(event.pressed)
			accept_event()
		elif event.pressed and b == MOUSE_BUTTON_WHEEL_UP:
			_cam_distance = max(_cam_distance * 0.9, _MIN_CAM_DISTANCE)
			_update_camera_transform()
			accept_event()
		elif event.pressed and b == MOUSE_BUTTON_WHEEL_DOWN:
			# Upper clamp scales with the mesh scale factor too — otherwise a
			# 20x-scaled plane (Ocean Waves' actual motivating case) couldn't
			# be scrolled back out past the original hardcoded 6.0 once
			# re-framed further out than that by a scale change. Scene mode uses
			# its own AABB-derived cap so large scenes stay reachable.
			var cap: float = _scene_max_distance if _scene_active else _MAX_CAM_DISTANCE * max(_preview_mesh_scale, 1.0)
			_cam_distance = min(_cam_distance * 1.1, cap)
			_update_camera_transform()
			accept_event()
	elif event is InputEventMouseMotion:
		if _orbiting:
			_cam_yaw -= event.relative.x * _ORBIT_SPEED
			_cam_pitch = clamp(_cam_pitch - event.relative.y * _ORBIT_SPEED, -1.5, 1.5)
			_update_camera_transform()
			accept_event()
		elif _panning_cam:
			_pan_camera(event.relative)
			accept_event()
		elif _freelook:
			_freelook_look(event.relative)
			accept_event()


# Basis vectors of the current orbit orientation (camera looks from
# focus+dir*distance toward focus). Pitch is clamped well short of ±90°, so the
# UP-cross never degenerates.
func _cam_dir() -> Vector3:
	return Vector3(
		cos(_cam_pitch) * sin(_cam_yaw),
		sin(_cam_pitch),
		cos(_cam_pitch) * cos(_cam_yaw)
	)


func _pan_camera(rel: Vector2) -> void:
	var forward := -_cam_dir()
	var right := forward.cross(Vector3.UP).normalized()
	var up := right.cross(forward).normalized()
	# Scale by distance so pan tracks the cursor at any zoom.
	var s: float = _PAN_SPEED * max(_cam_distance, _MIN_CAM_DISTANCE)
	_cam_focus += (-right * rel.x + up * rel.y) * s
	_update_camera_transform()


func _set_freelook(on: bool) -> void:
	_freelook = on


# RMB mouse-look: rotate the view in place. Recompute the focus so the camera
# position is invariant — that's what turns orbit-around-focus into first-person
# look-around without a separate camera representation.
func _freelook_look(rel: Vector2) -> void:
	var cam_pos := _cam_focus + _cam_dir() * _cam_distance
	_cam_yaw -= rel.x * _LOOK_SPEED
	_cam_pitch = clamp(_cam_pitch - rel.y * _LOOK_SPEED, -1.5, 1.5)
	_cam_focus = cam_pos - _cam_dir() * _cam_distance
	_update_camera_transform()


# WASD/QE flight while RMB is held — polled (not event-driven) so held keys move
# smoothly. Moving the camera == moving the focus by the same vector (distance
# and orientation are unchanged), so it stays inside the four-value model.
func _freelook_move(delta: float) -> void:
	var forward := -_cam_dir()
	var right := forward.cross(Vector3.UP).normalized()
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): move += forward
	if Input.is_key_pressed(KEY_S): move -= forward
	if Input.is_key_pressed(KEY_D): move += right
	if Input.is_key_pressed(KEY_A): move -= right
	if Input.is_key_pressed(KEY_E): move += Vector3.UP
	if Input.is_key_pressed(KEY_Q): move -= Vector3.UP
	if move == Vector3.ZERO:
		return
	var speed: float = _FREELOOK_SPEED * max(_cam_distance, _MIN_CAM_DISTANCE) * delta
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= 3.0
	_cam_focus += move.normalized() * speed
	_update_camera_transform()


# Frame the target: in scene mode recompute the instanced scene's AABB; in mesh
# mode recenter the pivot and pull back to the mesh's default distance (keeping
# the current viewing angle).
func frame_target() -> void:
	if _scene_active and is_instance_valid(_scene_instance):
		_frame_scene(_compute_scene_aabb(_scene_instance))
		return
	_cam_focus = Vector3.ZERO
	_cam_distance = _default_cam_distance * _preview_mesh_scale
	_update_camera_transform()


func is_freelooking() -> bool:
	return _freelook


func _update_camera_transform() -> void:
	_preview_camera.position = _cam_focus + _cam_dir() * _cam_distance
	_preview_camera.look_at(_cam_focus, Vector3.UP)


# ── Scene mode ──────────────────────────────────────────────────────────────────

# Store the persisted pin target (nyx_main pushes it from OutputNode). Doesn't
# touch the currently-followed scene — only used when actually pinned.
func set_scene_path(path: String) -> void:
	_pinned_scene_path = path


# Load/new-time restore: adopt the saved pin flag/path. A graph pinned to a valid
# scene opens straight into scene mode showing it (re-pointing if scene mode is
# already active from a previous graph). An unpinned graph loaded while scene mode
# is active drops back to following the active tab; otherwise it stays in mesh mode.
func restore_scene_mode(path: String, pinned: bool) -> void:
	_pinned_scene_path = path
	_pinned = pinned
	_update_pin_button()
	if pinned and not path.is_empty() and ResourceLoader.exists(path):
		if _scene_active:
			_scene_path = path
			_instance_scene(true)
		else:
			enter_scene_mode()
	elif not pinned and _scene_active:
		_follow_active_scene()


func _on_scene_btn_pressed() -> void:
	# toggle_mode auto-flips button_pressed on every click; if we're already in
	# scene mode, re-assert it (a second click is a no-op, not an un-toggle).
	if _scene_active:
		_scene_btn.button_pressed = true
		return
	enter_scene_mode()


func _on_reload_scene_pressed() -> void:
	if _scene_active:
		_instance_scene(false)  # keep the current view


# Pin/unpin toggle. Pinning locks to the current scene (persisting it as the pin);
# unpinning resumes following the active editor tab.
func _on_pin_toggled() -> void:
	_pinned = _pin_btn.button_pressed
	if _pinned:
		_pinned_scene_path = _scene_path
	_update_pin_button()
	# Persist the change (path + flag) so it survives save/load — deliberate user
	# action, so marking the graph dirty is correct.
	scene_pin_changed.emit(_pinned_scene_path, _pinned)
	# Unpinning snaps to the active scene immediately if it differs.
	if not _pinned:
		_follow_active_scene()


func _update_pin_button() -> void:
	if _pin_btn:
		_pin_btn.button_pressed = _pinned
		_pin_btn.tooltip_text = "Pinned to this scene (click to follow the active scene)" if _pinned \
			else "Following the active scene (click to pin this one)"


func enter_scene_mode() -> void:
	# Scene mode is spatial-only (the switcher is hidden in canvas/particle mode,
	# but the load-time restore path can reach here too).
	if _scene_active or _shader_type != 0:
		return
	# Resolve which scene to show: the pin if pinned, else the active editor tab.
	if _pinned and not _pinned_scene_path.is_empty():
		_scene_path = _pinned_scene_path
	else:
		var root := EditorInterface.get_edited_scene_root()
		_scene_path = root.scene_file_path if (root and not root.scene_file_path.is_empty()) else ""
	_saved_mesh_cam = _snapshot_cam()
	_scene_active = true
	_preview_mesh.visible = false
	if _particles:
		_particles.visible = false
		_particles.emitting = false
	for b in _preview_mesh_buttons:
		b.button_pressed = false
	if _scene_btn:
		_scene_btn.button_pressed = true
	_update_pin_button()
	_instance_scene()
	_update_scene_ui()
	refresh_params()   # now tuning the scene material — header + write target change


# ── Follow mode (nyx_main forwards the editor's scene_changed / scene_saved) ─────

func on_active_scene_changed(scene_root: Node) -> void:
	if _scene_active and not _pinned:
		_follow_active_scene(scene_root)


func on_scene_saved(filepath: String) -> void:
	# Refresh the instance when the scene it mirrors is saved from disk — keep the
	# current camera (same scene, just fresher geometry).
	if _scene_active and filepath == _scene_path:
		_instance_scene(false)


# Re-point at the active editor scene (used on tab switch and on unpin). Passing
# the root avoids a redundant EditorInterface lookup when the signal supplies it.
func _follow_active_scene(scene_root: Node = null) -> void:
	var root := scene_root if scene_root else EditorInterface.get_edited_scene_root()
	var path := root.scene_file_path if (root and not root.scene_file_path.is_empty()) else ""
	if path == _scene_path and is_instance_valid(_scene_instance):
		return
	_scene_path = path
	_instance_scene()


# Return to mesh mode: free the instance, show the mesh, restore its camera.
func _teardown_scene() -> void:
	_free_scene_instance()
	_scene_active = false
	_preview_mesh.visible = _shader_type == 0
	if _default_light:
		_default_light.visible = true
	if not _saved_mesh_cam.is_empty():
		_restore_cam(_saved_mesh_cam)
	_update_scene_ui()
	refresh_params()   # back to the sandboxed preview material


func _free_scene_instance() -> void:
	if is_instance_valid(_scene_instance):
		_scene_instance.queue_free()
	_scene_instance = null


# (Re)instance the current scene into the viewport, wire lighting/cameras. Frames
# the camera only for a genuinely new scene (enter/tab-switch) — a save-refresh or
# manual reload of the same scene keeps the user's current view.
func _instance_scene(frame: bool = true) -> void:
	_free_scene_instance()
	if _scene_path.is_empty() or not ResourceLoader.exists(_scene_path):
		_scene_msg.text = "No scene to preview.\nOpen a saved scene, then click this button again."
		_update_scene_ui()
		return
	var packed := load(_scene_path) as PackedScene
	if packed == null:
		_scene_msg.text = "Could not load scene:\n%s" % _scene_path
		_update_scene_ui()
		return
	_scene_instance = packed.instantiate()
	_viewport.add_child(_scene_instance)
	# The instanced scene may carry its own lights/environment and cameras. Use
	# its lighting if present (hide our default rig); always force OUR camera so a
	# scene camera can't steal the render.
	var has_light := _scene_has_lighting(_scene_instance)
	if _default_light:
		_default_light.visible = not has_light
	_disable_scene_cameras(_scene_instance)
	_preview_camera.current = true
	if frame:
		_frame_scene(_compute_scene_aabb(_scene_instance))
	_update_scene_ui()


func _scene_has_lighting(node: Node) -> bool:
	if node is Light3D or node is WorldEnvironment:
		return true
	for c in node.get_children():
		if _scene_has_lighting(c):
			return true
	return false


func _disable_scene_cameras(node: Node) -> void:
	if node is Camera3D:
		node.current = false
	for c in node.get_children():
		_disable_scene_cameras(c)


func _compute_scene_aabb(root: Node) -> AABB:
	var out := AABB()
	var seeded := false
	for vi in _all_visual_instances(root):
		var box: AABB = vi.get_aabb()
		var xf: Transform3D = vi.global_transform
		for i in 8:
			var corner := box.position + Vector3(
				box.size.x if (i & 1) else 0.0,
				box.size.y if (i & 2) else 0.0,
				box.size.z if (i & 4) else 0.0)
			var wp: Vector3 = xf * corner
			if not seeded:
				out = AABB(wp, Vector3.ZERO)
				seeded = true
			else:
				out = out.expand(wp)
	return out


func _all_visual_instances(node: Node, acc: Array = []) -> Array:
	if node is VisualInstance3D:
		acc.append(node)
	for c in node.get_children():
		_all_visual_instances(c, acc)
	return acc


func _frame_scene(aabb: AABB) -> void:
	var radius: float = max(aabb.size.length() * 0.5, 0.5)
	_cam_focus = aabb.get_center()
	_cam_distance = radius * 2.2
	# A pleasant slightly-elevated 3/4 view, and a zoom-out cap that fits the
	# scene rather than the mesh-mode default.
	_cam_yaw = 0.5
	_cam_pitch = 0.35
	_scene_max_distance = radius * 10.0
	_update_camera_transform()


func _snapshot_cam() -> Dictionary:
	return {"yaw": _cam_yaw, "pitch": _cam_pitch, "distance": _cam_distance, "focus": _cam_focus}


func _restore_cam(s: Dictionary) -> void:
	_cam_yaw = s.get("yaw", 0.0)
	_cam_pitch = s.get("pitch", 0.0)
	_cam_distance = s.get("distance", 1.2)
	_cam_focus = s.get("focus", Vector3.ZERO)
	_update_camera_transform()


# Reload/pin buttons visible only in scene mode; message shown only when scene
# mode has nothing valid to display.
func _update_scene_ui() -> void:
	var body := _panel_state != STATE_MINIMIZED and _shader_type == 0
	if _scene_msg:
		_scene_msg.visible = body and _scene_active and not is_instance_valid(_scene_instance)
	if _reload_btn:
		_reload_btn.visible = body and _scene_active
	if _pin_btn:
		_pin_btn.visible = body and _scene_active


# ── Live-params drawer ──────────────────────────────────────────────────────────

func _toggle_params_drawer() -> void:
	_params_open = not _params_open
	refresh_params()


# Apply the current column width to the drawer's right edge and reposition the
# grip to straddle it. Clamped so it can't collapse or overrun the panel.
func _update_params_width() -> void:
	_params_width = clamp(_params_width, 120.0, max(size.x - 24.0, 120.0))
	if _params_drawer:
		_params_drawer.set_offset(SIDE_RIGHT, 8 + _params_width)
	if _params_grip:
		_params_grip.set_anchor(SIDE_LEFT, 0.0)
		_params_grip.set_anchor(SIDE_RIGHT, 0.0)
		_params_grip.set_anchor(SIDE_TOP, 0.0)
		_params_grip.set_anchor(SIDE_BOTTOM, 1.0)
		_params_grip.set_offset(SIDE_LEFT, 8 + _params_width - 3)
		_params_grip.set_offset(SIDE_RIGHT, 8 + _params_width + 3)
		_params_grip.set_offset(SIDE_TOP, 62)
		_params_grip.set_offset(SIDE_BOTTOM, -40)


func _on_params_grip_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_params_resizing = event.pressed
		accept_event()
	elif event is InputEventMouseMotion and _params_resizing:
		_params_width += event.relative.x
		_update_params_width()
		accept_event()


# Which param-mode nodes the graph currently exposes.
func _param_nodes() -> Array:
	var out := []
	if _graph == null:
		return out
	for node in _graph.get_children():
		if node is GraphNode and node.has_method("is_param_mode") and node.is_param_mode():
			out.append(node)
	return out


func _has_params() -> bool:
	return not _param_nodes().is_empty()


# Wrench + drawer visibility only (no row rebuild) — safe to call on layout/state
# changes without disturbing a control mid-edit.
func _sync_drawer() -> void:
	var has := _has_params()
	if not has:
		_params_open = false
	if _wrench_btn:
		_wrench_btn.visible = has
		_wrench_btn.add_theme_color_override(
			"icon_normal_color", Color("#4AAF78") if _params_open else Color(0.55, 0.55, 0.65))
	var show := _params_open and has and _panel_state != STATE_MINIMIZED
	if _params_drawer:
		_params_drawer.visible = show
	if _params_grip:
		_params_grip.visible = show


# Public: rebuild the drawer from the current graph/target (nyx_main calls this on
# param changes and graph loads; internally on open and mode switch).
func refresh_params() -> void:
	_sync_drawer()
	if not (_params_drawer and _params_drawer.visible) or _params_vbox == null:
		return
	_params_header.text = _param_target_label()
	for c in _params_vbox.get_children():
		_params_vbox.remove_child(c)
		c.queue_free()
	for node in _param_nodes():
		_params_vbox.add_child(_build_live_param_row(node))


func _param_target_label() -> String:
	if _scene_active and not _scene_path.is_empty():
		return "Tuning scene material · %s" % _scene_path.get_file()
	return "Tuning preview material (sandboxed)"


func _build_live_param_row(node: Node) -> Control:
	var pname: String = node.get_param_name()
	# Show the live override if one exists, else the node's inline default — so a
	# rebuild never visually discards an override the material still holds.
	var value = _param_overrides.get(pname, node.get_param_value())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.text = pname
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.83, 0.88))
	row.add_child(lbl)

	var control := _make_param_control(node, value, pname)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)

	var reset := Button.new()
	reset.text = "⟲"
	reset.tooltip_text = "Reset to default"
	reset.focus_mode = Control.FOCUS_NONE
	reset.add_theme_font_size_override("font_size", 12)
	reset.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55))
	reset.add_theme_color_override("font_hover_color", Color("#4AAF78"))
	var re := StyleBoxEmpty.new()
	reset.add_theme_stylebox_override("normal", re)
	reset.add_theme_stylebox_override("hover", re)
	reset.add_theme_stylebox_override("pressed", re)
	reset.add_theme_stylebox_override("focus", re)
	reset.pressed.connect(_reset_param.bind(node))
	row.add_child(reset)
	return row


func _make_param_control(node: Node, value, pname: String) -> Control:
	if value is Color:
		var cp := ColorPickerButton.new()
		cp.custom_minimum_size = Vector2(0, 18)
		cp.color = value
		cp.edit_alpha = true
		cp.color_changed.connect(func(c: Color) -> void: _set_param(pname, c))
		return cp
	if value is Vector3:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 3)
		var spins: Array[SpinBox] = []
		for i in 3:
			var sp := SpinBox.new()
			sp.step = 0.01
			sp.allow_greater = true
			sp.allow_lesser = true
			sp.value = value[i]
			sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hb.add_child(sp)
			spins.append(sp)
		for sp in spins:
			sp.value_changed.connect(func(_v: float) -> void:
				_set_param(pname, Vector3(spins[0].value, spins[1].value, spins[2].value)))
		return hb
	# float — EditorSpinSlider with the node's range (default 0..1); allow_greater/
	# lesser so out-of-range values still show/edit, matching the material inspector.
	var sp := EditorSpinSlider.new()
	if node.has_method("get_param_min"):
		sp.min_value = node.get_param_min()
		sp.max_value = node.get_param_max()
		var st: float = node.get_param_step()
		sp.step = st if st > 0.0 else 0.001
	else:
		sp.min_value = 0.0
		sp.max_value = 1.0
		sp.step = 0.001
	sp.allow_greater = true
	sp.allow_lesser = true
	sp.value = float(value)
	sp.value_changed.connect(func(v: float) -> void: _set_param(pname, v))
	return sp


# Live uniform write + override tracking. Instant — no recompile, no dirty flag.
func _set_param(pname: String, value) -> void:
	_param_overrides[pname] = value
	_write_param_to_materials(pname, value)


func _reset_param(node: Node) -> void:
	var pname: String = node.get_param_name()
	_param_overrides.erase(pname)
	_write_param_to_materials(pname, node.get_param_value())
	refresh_params()   # rebuild so the control snaps back to the default


func _write_param_to_materials(pname: String, value) -> void:
	if _scene_active:
		# Hit the scene's shared cached materials that actually declare this
		# uniform — updates the preview and the real scene in-memory at once.
		for mat in _collect_scene_shader_materials():
			if _material_has_uniform(mat, pname):
				mat.set_shader_parameter(pname, value)
	else:
		var mat := get_active_material()
		if mat:
			mat.set_shader_parameter(pname, value)


func _collect_scene_shader_materials() -> Array:
	var acc: Array = []
	if is_instance_valid(_scene_instance):
		_walk_shader_materials(_scene_instance, acc)
	return acc


func _walk_shader_materials(node: Node, acc: Array) -> void:
	if node is GeometryInstance3D and node.material_override is ShaderMaterial and not acc.has(node.material_override):
		acc.append(node.material_override)
	if node is MeshInstance3D and node.mesh:
		for i in node.mesh.get_surface_count():
			var m = node.get_active_material(i)
			if m is ShaderMaterial and not acc.has(m):
				acc.append(m)
	for c in node.get_children():
		_walk_shader_materials(c, acc)


func _material_has_uniform(mat: ShaderMaterial, pname: String) -> bool:
	if mat.shader == null:
		return false
	for u in mat.shader.get_shader_uniform_list():
		if u.get("name", "") == pname:
			return true
	return false


# ── Panel-state ladder ──────────────────────────────────────────────────────────

func _make_header_button(glyph: String, tooltip: String) -> Button:
	var b := Button.new()
	b.text = glyph
	b.tooltip_text = tooltip
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	b.add_theme_color_override("font_hover_color", Color("#4AAF78"))
	var e := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", e)
	b.add_theme_stylebox_override("hover", e)
	b.add_theme_stylebox_override("pressed", e)
	b.add_theme_stylebox_override("focus", e)
	return b


func _set_panel_state(s: int) -> void:
	if s == _panel_state:
		return
	# Ambient is the only freely sized/positioned state — snapshot it on the way
	# out so minimize/focus can restore exactly where the card was.
	if _panel_state == STATE_AMBIENT:
		_restore_size = size
		_restore_position = position
	_panel_state = s
	match s:
		STATE_AMBIENT:
			_apply_ambient()
		STATE_MINIMIZED:
			_apply_minimized()
		STATE_FOCUSED:
			_apply_focused()
	_refresh_body_visibility()
	_update_state_buttons()
	_update_render_pause()


func _apply_ambient() -> void:
	size = _restore_size
	position = _restore_position
	# The window may have resized while minimized/focused, so keep the restored
	# card inside the current graph bounds.
	position = position.clamp(
		Vector2(0.0, _graph_top),
		Vector2(_graph_container.size.x, _graph_top + _graph_container.size.y) - size
	)


func _apply_minimized() -> void:
	# Roll up to the titlebar: keep the top-left corner, take the ambient width
	# (so minimizing from the wide focused state doesn't leave a full-width bar),
	# drop to header height (the hidden viewport contributes 0 once
	# _refresh_body_visibility runs).
	position = _restore_position
	size = Vector2(_restore_size.x, _header_wrap.get_combined_minimum_size().y)


func _apply_focused() -> void:
	var m := _FOCUS_MARGIN
	position = Vector2(m, _graph_top + m)
	size = Vector2(
		max(_graph_container.size.x - 2.0 * m, 240.0),
		max(_graph_container.size.y - 2.0 * m, 180.0)
	)


func _update_state_buttons() -> void:
	var active := Color("#4AAF78")
	var idle := Color(0.55, 0.55, 0.65)
	if _min_btn:
		_min_btn.add_theme_color_override("font_color", active if _panel_state == STATE_MINIMIZED else idle)
	if _focus_btn:
		_focus_btn.add_theme_color_override("font_color", active if _panel_state == STATE_FOCUSED else idle)


# Pause the SubViewports whenever nothing is looking (minimized or hidden) — they
# otherwise run UPDATE_ALWAYS forever. Called on every state change and, via
# NOTIFICATION_VISIBILITY_CHANGED, whenever the whole panel is shown/hidden.
func _update_render_pause() -> void:
	var mode := SubViewport.UPDATE_ALWAYS if (visible and _panel_state != STATE_MINIMIZED) else SubViewport.UPDATE_DISABLED
	if _viewport:
		_viewport.render_target_update_mode = mode
	if _viewport_2d:
		_viewport_2d.render_target_update_mode = mode


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_update_render_pause()
