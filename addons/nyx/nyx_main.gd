@tool
extends Control


const NyxRegistry = preload("res://addons/nyx/nyx_registry.gd")
signal reload_requested

var _outer_vbox: VBoxContainer
var _graph_container: VBoxContainer
var _graph: GraphEdit
var _shader_type: int = 0
# Chrome bar (minimal top bar: filename+dirty dot, Live badge, ◈ palette button),
# tool rail (floating vertical strip: zoom/grid/minimap + Undo/Redo/Props), and
# properties panel (floating Panel).
const NyxChromeBar = preload("res://addons/nyx/nyx_chrome_bar.gd")
const NyxToolRail = preload("res://addons/nyx/nyx_tool_rail.gd")
const NyxPropertiesPanel = preload("res://addons/nyx/nyx_properties_panel.gd")
var _chrome_bar  # NyxChromeBar instance
var _tool_rail  # NyxToolRail instance
var _properties_panel  # NyxPropertiesPanel instance
# Preview panel (floating - owns viewports/materials/mesh-switcher/particles/drag+resize).
# Per-node preview manager (SubViewport-per-node lifecycle). Both extracted from this file.
const NyxPreviewPanel = preload("res://addons/nyx/nyx_preview_panel.gd")
const NyxNodePreviews = preload("res://addons/nyx/nyx_node_previews.gd")
const NyxValueRelayPreviews = preload("res://addons/nyx/nyx_value_relay_previews.gd")
var _preview_panel  # NyxPreviewPanel instance
var _node_previews  # NyxNodePreviews instance
var _value_relay_previews  # NyxValueRelayPreviews instance
var _shortcuts_overlay: Control
var _panning: bool = false
var _pan_moved: bool = false  # did the cursor move during the current empty-canvas drag?
var _clipboard: Dictionary = {}  # {nodes, connections} from the last copy
var _compile_timer: Timer
# Node-search popup. Self-contained Control component (owns its overlay/cards/doc/icons);
# emits node_chosen(id) -> _on_search_node_chosen spawns. See nyx_search_popup.gd.
const NyxSearchPopup = preload("res://addons/nyx/nyx_search_popup.gd")
var _search_popup  # NyxSearchPopup instance

# Quick-add popup: input-side "drag a connection out, drop on empty canvas"
# gesture. See nyx_quick_add_popup.gd + .nyx-notes/olympus-viewport.md's
# "Connection-drop node spawn" design.
const NyxQuickAddPopup = preload("res://addons/nyx/nyx_quick_add_popup.gd")
var _quick_add_popup  # NyxQuickAddPopup instance
var _pending_output_connection: Dictionary = {}  # from_node/from_port, set only while
                                                  # the aMenu is open for an output-side drop
var _pending_input_connection: Dictionary = {}   # to_node/to_port/graph_position, set only
                                                  # while the quick-add popup is open

# Node-inspector popup. Step 1 shell wired to Curve only - see nyx_node_inspector.gd
# header + memory/project_properties_panel.md for the full staged build plan.
const NyxNodeInspector = preload("res://addons/nyx/nyx_node_inspector.gd")
var _node_inspector  # NyxNodeInspector instance

# Ctrl+P command palette - same overlay pattern as the search popup, single card.
# Emits the same signal names the old toolbar used to, so it reuses the same
# handlers unchanged (see nyx_command_palette.gd header). This is now the only
# way to reach File/Export/Live/View actions - the toolbar has been replaced by
# nyx_chrome_bar.gd's minimal filename+dot / Live badge / ◈ bar.
const NyxCommandPalette = preload("res://addons/nyx/nyx_command_palette.gd")
var _command_palette  # NyxCommandPalette instance
var _export_dialog: EditorFileDialog
var _save_dialog: EditorFileDialog
var _load_dialog: EditorFileDialog
var _texture_dialog: EditorFileDialog
var _new_confirm: ConfirmationDialog
var _load_confirm: ConfirmationDialog
var _dirty: bool = false              # unsaved changes to the .nyx working file
var _loading: bool = false            # suppresses dirty-marking during load/new
var _pending_load_action: Callable = Callable()  # action awaiting the discard-changes confirm
var _pending_after_save: Callable = Callable()  # run after a "Save & …" completes
var _texture_target: Node = null
var _spawn_position: Vector2
var _last_spawned_node: Node = null  # set by _add_node; used to auto-connect
                                      # after an aMenu spawn triggered by connection_to_empty
# Shader compiler (graph -> GLSL). Extracted from this file; holds a reference to
# _graph and is constructed once in _ready. See nyx_compiler.gd.
const NyxCompiler = preload("res://addons/nyx/nyx_compiler.gd")
var _compiler  # NyxCompiler instance

# Persistence layer (.nyx disk format + dict↔resource bridge). Stateless/static.
# graph->dict (_serialize_graph) and dict->graph (_deserialize_graph) stay here; this
# only owns disk↔format. See nyx_serializer.gd.
const NyxSerializer = preload("res://addons/nyx/nyx_serializer.gd")

# Live link / exported-shader-file state. `.nyx` is directly usable as a Shader
# the moment it's ever saved (see core/nyx_shader_importer.gd) - there's no
# "linked/unlinked" gate on usability anymore. An exported .gdshader is now an
# independent, optional second target: a graph may have neither, either, or
# both. See backlog.md -> "`.nyx` as a directly-usable Shader".
const NyxCharon = preload("res://addons/nyx/core/charon.gd")
var _export_mode: String = "full"         # "full" | "shader_only" (drives _on_export_file_selected)
var _current_nyx_path: String = ""        # working .nyx file on disk ("" = unsaved)
var _exported_shader_path: String = ""    # optional exported .gdshader ("" = none exported yet)
var _live_link_on: bool = false
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
	_compiler = NyxCompiler.new(_graph)
	_graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph.grid_pattern = GraphEdit.GRID_PATTERN_DOTS
	_graph.snapping_enabled = false
	_graph.minimap_enabled = false
	# The floating toolbar (zoom/grid/minimap) is reparented into NyxToolRail;
	# see its _populate_from_graph_toolbar(), called via setup() deferred.
	var graph_bg := StyleBoxFlat.new()
	graph_bg.bg_color = Color("#0D0D0F")
	_graph.add_theme_stylebox_override("panel", graph_bg)
	_graph.right_disconnects = true
	_graph.connection_request.connect(_on_connection_request)
	_graph.disconnection_request.connect(_on_disconnection_request)
	_graph.connection_from_empty.connect(_on_connection_from_empty)
	_graph.connection_to_empty.connect(_on_connection_to_empty)
	_graph.delete_nodes_request.connect(_on_delete_nodes_request)
	# GraphEdit owns Ctrl+C/V/D when focused (it intercepts them in its own gui_input and
	# emits these signals), so handling them in _shortcut_input never fires. Wire the
	# signals instead - a focused text field consumes the keys first, so node copy/paste
	# only triggers when the graph itself has focus. No manual text-field guard needed.
	_graph.copy_nodes_request.connect(_copy_selected_nodes)
	_graph.paste_nodes_request.connect(_paste_clipboard)
	_graph.duplicate_nodes_request.connect(_duplicate_selected_nodes)
	_graph.gui_input.connect(_on_graph_gui_input)
	# Type IDs: 0 = vec3, 1 = float, 2 = vec2, 3 = vec4.
	# Same-type connections:
	_graph.add_valid_connection_type(0, 0)
	_graph.add_valid_connection_type(1, 1)
	_graph.add_valid_connection_type(2, 2)
	_graph.add_valid_connection_type(3, 3)
	# Implicit promotion (widening only):
	_graph.add_valid_connection_type(1, 2)  # float -> vec2
	_graph.add_valid_connection_type(1, 0)  # float -> vec3
	_graph.add_valid_connection_type(1, 3)  # float -> vec4
	_graph.add_valid_connection_type(2, 0)  # vec2  -> vec3
	_graph.add_valid_connection_type(2, 3)  # vec2  -> vec4
	_graph.add_valid_connection_type(0, 3)  # vec3  -> vec4
	# The one sanctioned narrowing - dropping alpha is unambiguous (.rgb):
	_graph.add_valid_connection_type(3, 0)  # vec4  -> vec3

	_graph_container = VBoxContainer.new()
	_graph_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_container.add_theme_constant_override("separation", 0)
	_graph_container.add_child(_graph)

	_outer_vbox = VBoxContainer.new()
	_outer_vbox.add_theme_constant_override("separation", 0)
	_outer_vbox.add_child(_graph_container)
	add_child(_outer_vbox)

	# Floats over the graph's top-left corner - does NOT sit in _outer_vbox,
	# reserves no layout space (see nyx_chrome_bar.gd header).
	_chrome_bar = NyxChromeBar.new()
	_chrome_bar.palette_pressed.connect(func() -> void:
		# toggle_mode auto-flips the button's own pressed visual on every click,
		# but our external sync (below) only fires when the palette's .visible
		# actually changes - so a second click while it's already open must
		# close it here, not just re-open/refresh it, or the button would show
		# grey while the palette stays open.
		if _command_palette.visible:
			_command_palette.close()
		else:
			_open_command_palette(_chrome_bar.get_palette_anchor_global_pos()))
	add_child(_chrome_bar)
	_chrome_bar.setup(_graph, _graph_container)

	# Floats vertically centered on the graph's left edge - does NOT sit in
	# _outer_vbox, reserves no layout space (see nyx_tool_rail.gd header).
	_tool_rail = NyxToolRail.new()
	_tool_rail.undo_pressed.connect(_undo)
	_tool_rail.redo_pressed.connect(_redo)
	add_child(_tool_rail)
	_tool_rail.setup(_graph, _graph_container)
	_tool_rail.visible = false  # hidden by default; palette's "Toggle Tool Rail" shows it

	_search_popup = NyxSearchPopup.new()
	add_child(_search_popup)
	_search_popup.setup(_graph_container)
	_search_popup.node_chosen.connect(_on_search_node_chosen)

	_quick_add_popup = NyxQuickAddPopup.new()
	add_child(_quick_add_popup)
	_quick_add_popup.setup(_graph_container)
	_quick_add_popup.candidate_chosen.connect(_on_quick_add_chosen)

	_node_inspector = NyxNodeInspector.new()
	add_child(_node_inspector)
	_node_inspector.setup(_graph_container)

	_command_palette = NyxCommandPalette.new()
	add_child(_command_palette)
	_command_palette.setup(_graph_container)
	_command_palette.file_menu_selected.connect(_on_file_menu_id)
	_command_palette.recent_file_selected.connect(_on_recent_selected)
	_command_palette.export_pressed.connect(_on_export_pressed)
	_command_palette.export_menu_selected.connect(_on_export_menu_id)
	_command_palette.live_toggled.connect(_on_live_toggled)
	_command_palette.shortcuts_pressed.connect(_toggle_shortcuts_overlay)
	_command_palette.properties_toggled.connect(_toggle_properties_panel)
	_command_palette.preview_toggled.connect(_toggle_preview_panel)
	_command_palette.tool_rail_toggled.connect(_toggle_tool_rail)
	_command_palette.undo_pressed.connect(_undo)
	_command_palette.redo_pressed.connect(_redo)
	# Keeps the chrome-bar palette icon's toggled-green state in sync with the
	# palette's actual visibility, however it closes (backdrop click, Escape,
	# running a command) - not just the button-click path above.
	_command_palette.visibility_changed.connect(func() -> void:
		_chrome_bar.set_palette_open(_command_palette.visible))

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
	# Cancelling the save drops any pending "Save & New/Load" so a later plain
	# Save can't accidentally trigger the stale follow-up action.
	_save_dialog.canceled.connect(func(): _pending_after_save = Callable())
	add_child(_save_dialog)

	_load_dialog = EditorFileDialog.new()
	_load_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_load_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_load_dialog.add_filter("*.nyx", "Nyx Graph")
	_load_dialog.file_selected.connect(load_nyx)
	add_child(_load_dialog)

	_texture_dialog = EditorFileDialog.new()
	_texture_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_texture_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_texture_dialog.add_filter("*.png,*.jpg,*.jpeg,*.bmp,*.webp,*.tga,*.exr,*.hdr", "Image Files")
	_texture_dialog.file_selected.connect(_on_texture_file_selected)
	add_child(_texture_dialog)

	# OK button = the safe "Save & …" action, so the default/highlighted/Enter
	# choice is never the destructive Discard. Order forced to [Save | Discard | Cancel].
	_new_confirm = ConfirmationDialog.new()
	_new_confirm.title = "New Graph"
	_new_confirm.dialog_text = "You have unsaved changes."
	_new_confirm.ok_button_text = "Save & New"
	var discard_new := _new_confirm.add_button("Discard & New", false, "discard")
	_new_confirm.confirmed.connect(func(): _save_then(_new_graph))
	_new_confirm.custom_action.connect(func(action: StringName):
		if action == &"discard":
			_new_confirm.hide()
			_new_graph()
	)
	_order_dialog_buttons(_new_confirm, discard_new)
	add_child(_new_confirm)

	_load_confirm = ConfirmationDialog.new()
	_load_confirm.title = "Load Graph"
	_load_confirm.dialog_text = "You have unsaved changes."
	_load_confirm.ok_button_text = "Save & Load"
	var discard_load := _load_confirm.add_button("Discard & Load", false, "discard")
	_load_confirm.confirmed.connect(func(): _save_then(func(): _pending_load_action.call()))
	_load_confirm.custom_action.connect(func(action: StringName):
		if action == &"discard":
			_load_confirm.hide()
			_pending_load_action.call()
	)
	_order_dialog_buttons(_load_confirm, discard_load)
	add_child(_load_confirm)

	_preview_panel = NyxPreviewPanel.new()
	add_child(_preview_panel)
	_preview_panel.setup(_graph, _graph_container)
	_preview_panel.scene_pin_changed.connect(_on_scene_pin_changed)
	_node_previews = NyxNodePreviews.new()
	add_child(_node_previews)
	_node_previews.setup(_graph, _compiler)
	_value_relay_previews = NyxValueRelayPreviews.new()
	add_child(_value_relay_previews)
	_value_relay_previews.setup(_graph, _compiler)
	_properties_panel = NyxPropertiesPanel.new()
	add_child(_properties_panel)
	_properties_panel.setup(_graph, _graph_container)
	_update_export_ui()  # nothing exported yet: "Export Shader + Material…", Live has no target

	_shortcuts_overlay = _build_shortcuts_overlay()
	add_child(_shortcuts_overlay)

	_add_node(NyxRegistry.OutputNode.new(), Vector2(300, 160), "OutputNode")
	_add_node(NyxRegistry.VertexOutputNode.new(), Vector2(300, 40), "VertexOutputNode")
	_update_sink_visibility()
	_apply_preview_mesh_settings()
	_frame_default_view()
	_setup_initial_panel_layout()


# Waits until the Nyx tab is actually visible AND the editor's post-visibility
# layout has settled (the dock-collapse from entering focus layout, kicked off
# in plugin.gd's _make_visible right as visibility flips true, takes a couple
# frames to actually resize the editor). This is the state a freshly created
# main screen is already in when Ctrl+U recreates it - its first layout pass
# never races the dock collapse, which is why that path always lands correctly.
func _await_layout_ready() -> void:
	# Wait for the deferred node resize pass; GraphEdit re-clamps scroll_offset
	# against the node bounding box afterward, which would otherwise snap y back.
	await get_tree().process_frame
	await get_tree().process_frame
	while is_instance_valid(self) and not is_visible_in_tree():
		await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


# Frame the graph view so the default node cluster sits in the top-left with a
# small margin. Deferred + waits for layout to settle so it never frames
# against a (0,0) or pre-dock-collapse GraphEdit size.
func _frame_default_view() -> void:
	call_deferred("_do_frame_default_view")


func _do_frame_default_view() -> void:
	if not _graph:
		return
	await _await_layout_ready()
	if not is_instance_valid(_graph):
		return
	_graph.zoom = 1.0
	# Anchor the sink cluster near the top-right with a consistent margin, so the
	# default framing is viewport-relative (scalable across DPI/resolution)
	# rather than a value eyeballed for one screen. The graph flows left->right
	# into the sink, so this leaves open canvas to its left to build in.
	var gc := _graph_container.size
	if gc.x <= 0.0:
		_graph.scroll_offset = Vector2(-600, -100)  # fallback: layout not ready
		return
	var right_margin := NyxRegistry.NyxNodeBase._s(40.0)
	var top_margin := NyxRegistry.NyxNodeBase._s(60.0)
	# The preview/properties panels float in the top-right corner, so keep the
	# sink cluster's right edge clear to their left. They aren't placed yet when
	# this runs (framing is deferred ahead of panel layout), but their width is
	# already set — reserve panel width + its default right offset (20).
	var panel_clearance: float = (_preview_panel.size.x + 20.0) if _preview_panel else 0.0
	var output := _graph.get_node_or_null("OutputNode")
	# Sink vertical spacing must track node height (which scales with EDSCALE),
	# not the fixed graph-Y offsets — otherwise the taller nodes at higher editor
	# scale crowd/overlap. Drop OutputNode to a scale-aware gap below VertexOutput
	# using its real measured height (known now, post-layout).
	var vout := _graph.get_node_or_null("VertexOutputNode")
	if output and vout:
		output.position_offset.y = vout.position_offset.y + vout.size.y + NyxRegistry.NyxNodeBase._s(40.0)
	var cluster_right: float = 300.0 + (output.size.x if output else NyxRegistry.NyxNodeBase._s(150.0))
	_graph.scroll_offset = Vector2(
		cluster_right - (gc.x - panel_clearance - right_margin),
		40.0 - top_margin,
	)


func _add_node(node: Node, offset: Vector2, node_name: String = "") -> void:
	_last_spawned_node = node
	if node_name != "":
		node.name = node_name
	var type_name := NyxRegistry.get_node_type(node)
	if NyxRegistry.NODE_TYPE_COLORS.has(type_name):
		node._node_color = NyxRegistry.NODE_TYPE_COLORS[type_name]
	node._category = NyxRegistry.NODE_TYPE_CATEGORY.get(type_name, "")
	if NyxRegistry.NODE_WIDTH_TIERS.has(type_name):
		node.custom_minimum_size.x = NyxRegistry.NyxNodeBase._s(NyxRegistry.NODE_WIDTH_TIERS[type_name])
	node.position_offset = offset
	_graph.add_child(node)
	if node.has_signal("value_changed"):
		node.value_changed.connect(_request_compile)
		node.value_changed.connect(_mark_dirty)
		node.value_changed.connect(_refresh_blackboard)
	if node.has_signal("edit_started"):
		node.edit_started.connect(_push_undo_state)
	if node.has_signal("texture_pick_requested"):
		node.texture_pick_requested.connect(_on_texture_pick_requested)
	if node.has_signal("inspector_requested"):
		node.inspector_requested.connect(func(n: Node):
			# Same trigger (cog / double-click) on a node whose popup is already
			# open closes it instead of just re-opening the same content.
			if _node_inspector.is_open_for(n):
				_node_inspector.close()
				return
			if n.has_method("get_curve"):
				_node_inspector.open_for_resource(n.get_curve(), "Curve", n)
			elif n.has_method("get_gradient"):
				_node_inspector.open_for_resource(n.get_gradient(), "Gradient", n)
			elif n.has_method("get_color"):
				_node_inspector.open_for_color(
					Callable(n, "get_color"), Callable(n, "set_color_from_inspector"), n.title, n)
			elif NyxRegistry.is_sink(n):
				var output := _get_output_node()
				_node_inspector.open_for_sink(
					n.title, n, _shader_type, _shader_type != 2, _get_render_mode_index(),
					_render_mode_labels(_shader_type),
					func(idx: int):
						_on_shader_type_changed(idx)
						_node_inspector.close(),
					Callable(self, "_set_render_mode_index"),
					output.get_preview_plane_horizontal() if output else true,
					output.get_preview_subdivisions() if output else 64,
					output.get_preview_scale() if output else 1.0,
					Callable(self, "_set_preview_plane_horizontal"),
					Callable(self, "_set_preview_subdivisions"),
					Callable(self, "_set_preview_scale"))
			else:
				_node_inspector.open_meta_only(n.title, n)
		)
	if node.has_signal("pair_removed"):
		node.pair_removed.connect(func(idx: int): _on_relay_pair_removed(node, idx))
	if node.has_signal("preview_toggled"):
		node.preview_toggled.connect(func():
			if node.has_meta("_preview_material"):
				_node_previews.close(node)
			else:
				_node_previews.open(node, _shader_type)
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
				_mark_dirty()
		)
	# Nodes spawned while in particle mode shouldn't carry a preview chevron.
	if _shader_type == 2 and node.has_method("set_preview_chevron_visible"):
		node.call_deferred("set_preview_chevron_visible", false)


func _request_compile() -> void:
	_compile_timer.stop()
	_compile_timer.start()


func _compile_shader() -> void:
	if _graph.get_node_or_null("OutputNode") or _graph.get_node_or_null("VertexOutputNode") or _shader_type == 2:
		var code: String = _compiler.build_shader_code(_shader_type)
		if _preview_panel.compile(code, _shader_type):
			if _live_link_on:
				_push_live_updates()
		_preview_panel.apply_uniforms()
	if _shader_type != 2:
		_node_previews.refresh_all(_shader_type)
	_value_relay_previews.refresh_all(_shader_type)


# Live pushes to every real target at once: the `.nyx` itself (its cached
# imported Shader, once it's ever been saved - the direct-reference case) and
# a separately exported .gdshader, if one also exists. notify_shader_updated()
# is already fully generic (ResourceLoader.load(path, "Shader") doesn't care
# whether path is a plain .gdshader or an imported `.nyx` - both are cached
# Shader resources by the time they're loaded), so this needed no Charon
# changes, only calling it for both possible targets.
func _push_live_updates() -> void:
	var material: Material = _preview_panel.get_active_material()
	if not _current_nyx_path.is_empty():
		NyxCharon.notify_shader_updated(_current_nyx_path, material)
	if not _exported_shader_path.is_empty():
		NyxCharon.notify_shader_updated(_exported_shader_path, material)


func _update_sink_visibility() -> void:
	var output_node = _graph.get_node_or_null("OutputNode")
	if output_node:
		output_node.visible = _shader_type != 2
	var vertex_output_node = _graph.get_node_or_null("VertexOutputNode")
	if vertex_output_node:
		vertex_output_node.visible = _shader_type == 0
	var start_node = _graph.get_node_or_null("ParticleStartNode")
	if start_node:
		start_node.visible = _shader_type == 2
	var process_node = _graph.get_node_or_null("ParticleProcessNode")
	if process_node:
		process_node.visible = _shader_type == 2
	if _preview_panel:
		_preview_panel.update_for_shader_type(_shader_type)
	for child in _graph.get_children():
		if child is GraphNode and child.has_method("set_preview_chevron_visible"):
			child.set_preview_chevron_visible(_shader_type != 2)


func _on_relay_pair_removed(relay: Node, removed_idx: int) -> void:
	var relay_name := str(relay.name)
	var c := _graph.get_connection_list()
	var to_reconnect := []
	for conn in c:
		var from := str(conn["from_node"])
		var to := str(conn["to_node"])
		var fp: int = conn["from_port"]
		var tp: int = conn["to_port"]
		if to == relay_name and tp == removed_idx:
			_graph.disconnect_node(from, fp, to, tp)
		elif to == relay_name and tp > removed_idx:
			_graph.disconnect_node(from, fp, to, tp)
			to_reconnect.append({"from": from, "fp": fp, "to": to, "tp": tp - 1})
		elif from == relay_name and fp == removed_idx:
			_graph.disconnect_node(from, fp, to, tp)
		elif from == relay_name and fp > removed_idx:
			_graph.disconnect_node(from, fp, to, tp)
			to_reconnect.append({"from": from, "fp": fp - 1, "to": to, "tp": tp})
	for r in to_reconnect:
		_graph.connect_node(r["from"], r["fp"], r["to"], r["tp"])
	_compiler.update_all_polymorphic_ports()
	_compiler.update_contextual_labels()
	_request_compile()


func _sync_shader_type_ui(_idx: int) -> void:
	# Shader-type-change can hide/show nodes (particle mode swaps sinks), which
	# can change which param-mode nodes exist - refresh the params list. Graph
	# Settings itself no longer lives on this panel (migrated to the node-
	# inspector popup's open_for_sink).
	if _properties_panel:
		_properties_panel.rebuild()


func _get_output_node() -> Node:
	return _graph.get_node_or_null("OutputNode")


# Render mode is true graph-wide state (there's only ever one OutputNode, the
# actual owner) - these are the shared read/write path the node-inspector
# popup calls through regardless of which sink (Output/Vertex Output/particle
# sinks) the user actually opened the popup on.
func _get_render_mode_index() -> int:
	var output := _get_output_node()
	return output.get_mode() if output else 0


func _render_mode_labels(shader_type: int) -> Array:
	return ["Opaque", "Mix", "Add", "Premult Alpha"] if shader_type == 0 \
		else ["Default", "Unshaded", "Light Only", "Blend Add", "Blend Premult"]


func _set_render_mode_index(idx: int) -> void:
	var output := _get_output_node()
	if output:
		output.set_mode(idx)
		_request_compile()


# Preview Mesh settings (Graph Settings popup, Spatial mode only). Dirty-
# marking/undo comes for free — output.set_preview_*() emits the same
# edit_started/value_changed pair set_mode() does, and _add_node() already
# wires those generically for every node. The push into the live preview
# panel is the one thing that wiring doesn't cover, so each setter applies
# it explicitly afterward.
func _apply_preview_mesh_settings() -> void:
	var output := _get_output_node()
	if output and _preview_panel:
		_preview_panel.set_preview_mesh_settings(
			output.get_preview_plane_horizontal(),
			output.get_preview_subdivisions(),
			output.get_preview_scale())
		_preview_panel.set_scene_path(output.get_preview_scene_path())


# The preview panel pins/unpins a scene; persist it on OutputNode so it survives
# save/load and mark the graph dirty.
func _on_scene_pin_changed(path: String, pinned: bool) -> void:
	var output := _get_output_node()
	if output and output.has_method("set_preview_scene_path"):
		output.set_preview_scene_path(path)
		output.set_preview_scene_pinned(pinned)
		_mark_dirty()


# Editor scene-tab changed / a scene was saved — forwarded from plugin.gd's
# EditorPlugin signals so the preview panel's follow mode can track it.
func on_active_scene_changed(scene_root: Node) -> void:
	if _preview_panel:
		_preview_panel.on_active_scene_changed(scene_root)


func on_scene_saved(filepath: String) -> void:
	if _preview_panel:
		_preview_panel.on_scene_saved(filepath)


# Load-time only (not undo/redo): a graph pinned to a scene reopens in scene mode
# showing it.
func _restore_preview_scene() -> void:
	var output := _get_output_node()
	if output and _preview_panel and output.has_method("get_preview_scene_pinned"):
		_preview_panel.restore_scene_mode(
			output.get_preview_scene_path(),
			output.get_preview_scene_pinned())


func _set_preview_plane_horizontal(v: bool) -> void:
	var output := _get_output_node()
	if output:
		output.set_preview_plane_horizontal(v)
		_apply_preview_mesh_settings()


func _set_preview_subdivisions(v: int) -> void:
	var output := _get_output_node()
	if output:
		output.set_preview_subdivisions(v)
		_apply_preview_mesh_settings()


func _set_preview_scale(v: float) -> void:
	var output := _get_output_node()
	if output:
		output.set_preview_scale(v)
		_apply_preview_mesh_settings()


func _toggle_properties_panel() -> void:
	if _properties_panel:
		_properties_panel.toggle()


var _blackboard_prev_param_count: int = 0


func _count_exposed_params() -> int:
	var n := 0
	for node in _graph.get_children():
		if node is GraphNode and node.has_method("is_param_mode") and node.call("is_param_mode"):
			n += 1
	return n


# Mid-edit Blackboard upkeep (called on any node value change). Reveals the panel
# on the 0 → ≥1 parameter transition (the first param makes it relevant) but never
# auto-hides — once shown, the user manages it, and adding a 2nd param won't
# fight a manual close. Keeps its rows current while it's open.
func _refresh_blackboard() -> void:
	if not _properties_panel:
		return
	var c := _count_exposed_params()
	if c > 0 and _blackboard_prev_param_count == 0 and not _properties_panel.visible:
		_properties_panel.visible = true
	_blackboard_prev_param_count = c
	if _properties_panel.visible:
		_properties_panel.rebuild()
	if _preview_panel:
		_preview_panel.refresh_params()   # keep the preview's live-params drawer in sync


# Full sync on a graph replacement (load/new): show iff the graph has params, so a
# param-less graph starts with the Blackboard hidden and a param-carrying one
# opens straight into it.
func _sync_blackboard_on_graph_replace() -> void:
	if not _properties_panel:
		return
	var c := _count_exposed_params()
	_blackboard_prev_param_count = c
	_properties_panel.visible = c > 0
	if _properties_panel.visible:
		_properties_panel.rebuild()
	if _preview_panel:
		_preview_panel.refresh_params()   # sync the preview's live-params drawer too


func _toggle_preview_panel() -> void:
	if _preview_panel:
		_preview_panel.visible = not _preview_panel.visible


func _toggle_tool_rail() -> void:
	if _tool_rail:
		# Place it on first reveal if the initial layout hasn't yet (it's created
		# hidden and may be toggled before _do_setup_initial_panel_layout runs).
		if not _tool_rail.is_placed():
			_tool_rail.place_default(_graph_top())
		_tool_rail.visible = not _tool_rail.visible


func _on_shader_type_changed(idx: int) -> void:
	_shader_type = idx
	_sync_shader_type_ui(idx)
	if idx == 0:
		_ensure_spatial_sinks()
		var output_node = _graph.get_node_or_null("OutputNode")
		if output_node:
			output_node.set_shader_type(0)
	elif idx == 1:
		var output_node = _graph.get_node_or_null("OutputNode")
		if output_node:
			output_node.set_shader_type(1)
	elif idx == 2:
		_ensure_particle_sinks()
	_update_sink_visibility()
	# Rebuild per-node previews for the new mode. Particle mode has no per-node
	# previews (the values are per-particle, not per-pixel), so just tear them down.
	for child in _graph.get_children():
		if child is GraphNode and child.has_meta("_preview_material"):
			_node_previews.close(child)
			if idx != 2:
				_node_previews.open(child, idx)
	_preview_panel.reset_last_code()
	_request_compile()


func _ensure_spatial_sinks() -> void:
	if not _graph.get_node_or_null("OutputNode"):
		_add_node(NyxRegistry.OutputNode.new(), Vector2(300, 160), "OutputNode")
	if not _graph.get_node_or_null("VertexOutputNode"):
		_add_node(NyxRegistry.VertexOutputNode.new(), Vector2(300, 40), "VertexOutputNode")


func _ensure_particle_sinks() -> void:
	if not _graph.get_node_or_null("ParticleStartNode"):
		_add_node(NyxRegistry.ParticleStartNode.new(), Vector2(300, 40), "ParticleStartNode")
	if not _graph.get_node_or_null("ParticleProcessNode"):
		_add_node(NyxRegistry.ParticleProcessNode.new(), Vector2(300, 215), "ParticleProcessNode")


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


# --- Exported shader file / live push ---
# The exported .gdshader is now an independent, optional target - a graph is
# always directly usable via its `.nyx` once saved, whether or not this exists.

# Contextual primary button: "Export Shader + Material…" when nothing's been
# exported yet, "Update Shader File" once it has.
func _on_export_pressed() -> void:
	if _exported_shader_path.is_empty():
		_export_mode = "full"
		_popup_export_dialog()
	else:
		_do_update()


# The .nyx itself is a valid Shader-typed reference target once saved (same
# ext_resource type="Shader" line works either way - write_material() doesn't
# need to know or care which kind of path it's given), so "Export Material"
# points at whichever real target exists: the exported .gdshader if there is
# one, otherwise the .nyx directly. Only truly unavailable when neither exists
# (the graph has never been saved at all).
func _material_export_target() -> String:
	return _exported_shader_path if not _exported_shader_path.is_empty() else _current_nyx_path


# Caret dropdown: rarer export ops.
func _on_export_menu_id(id: int) -> void:
	match id:
		0:  # Export material (resets material parameters)
			var target := _material_export_target()
			if target.is_empty():
				push_warning("Nyx: save the graph first before writing a material.")
				return
			if _write_material_file(target):
				EditorInterface.get_resource_filesystem().scan()
				print("Nyx: wrote material (parameters reset) -> %s" % (target.get_basename() + ".tres"))
		1:  # Export shader only
			if _exported_shader_path.is_empty():
				_export_mode = "shader_only"
				_popup_export_dialog()
			else:
				_do_update()
		2:  # Export shader + material as… (re-export to a new path)
			_export_mode = "full"
			_popup_export_dialog()
		3:  # Remove exported shader file (stop syncing it; the .nyx itself is unaffected)
			_set_exported_shader("")
			print("Nyx: removed exported shader file")


func _get_recent_files() -> Array:
	var s := EditorInterface.get_editor_settings()
	if s.has_setting("nyx/recent_files"):
		return Array(s.get_setting("nyx/recent_files"))
	return []


func _push_recent(path: String) -> void:
	var s := EditorInterface.get_editor_settings()
	var recent := _get_recent_files()
	recent.erase(path)
	recent.insert(0, path)
	if recent.size() > 10:
		recent.resize(10)
	s.set_setting("nyx/recent_files", PackedStringArray(recent))




func _on_recent_selected(id: int) -> void:
	var recent := _get_recent_files()
	if id < recent.size():
		load_nyx(recent[id])


func _on_file_menu_id(id: int) -> void:
	match id:
		0:  _on_new_pressed()
		1:  _load_dialog.popup_centered_ratio(0.5)
		2:  _on_save_pressed()
		3:  _popup_save_dialog()
		4:  _on_export_pressed()
		5:  _on_export_menu_id(2)  # Export Shader + Material As…
		6:  _on_export_menu_id(0)  # Export Material
		7:  _on_export_menu_id(1)  # Export Shader Only
		8:  _on_export_menu_id(3)  # Remove Exported Shader File


func _on_live_toggled(on: bool) -> void:
	_live_link_on = on
	# Toggling on immediately reflects the current graph state in every real target.
	if on:
		_push_live_updates()


func _popup_export_dialog() -> void:
	# Co-locate: default the artifact to the working file's folder when we have one.
	if not _current_nyx_path.is_empty():
		_export_dialog.current_dir = _current_nyx_path.get_base_dir()
	_export_dialog.popup_centered_ratio(0.5)


# Update the exported shader file in place (no dialog, no material rewrite -
# material values are the user's to keep). Persists the .nyx too, the way
# Ctrl+S does.
func _do_update() -> void:
	if _exported_shader_path.is_empty():
		return
	var code: String = _compiler.build_shader_code(_shader_type)
	if not _write_shader_file(_exported_shader_path, code):
		return
	if not _current_nyx_path.is_empty():
		NyxSerializer.write(_current_nyx_path, _serialize_graph_for_save())
	NyxCharon.notify_shader_updated(_exported_shader_path, _preview_panel.get_active_material())
	EditorInterface.get_resource_filesystem().scan()
	print("Nyx: updated shader -> %s" % _exported_shader_path)


# True whenever Live has a real place to push to: the .nyx itself (once saved)
# and/or a separately exported .gdshader. Replaces the old "is it linked" gate,
# which only ever considered the exported path - now that a saved `.nyx` is
# its own valid target, Live shouldn't be forced off just because no shader
# was ever exported.
func _has_live_target() -> bool:
	return not _current_nyx_path.is_empty() or not _exported_shader_path.is_empty()


func _set_exported_shader(path: String) -> void:
	_exported_shader_path = path
	_update_export_ui()  # also drives the chrome-bar badge off the new state
	# Exporting implies you want to see it live by default - Ctrl+P -> Live is the
	# opt-out for the rarer "edit without disturbing the scene" case.
	if not path.is_empty():
		_on_live_toggled(true)


# Live can't stay on with nowhere to push to - force it off (mirrors the old
# toolbar's Live checkbox auto-uncheck-on-unlink, generalized to the new dual-
# target model). _set_exported_shader/_do_load/_on_save_file_selected
# explicitly turn it on where that's the desired default. Also the single
# place the chrome-bar badge + reference list sync.
func _update_export_ui() -> void:
	if not _has_live_target() and _live_link_on:
		_on_live_toggled(false)
	if _chrome_bar:
		_chrome_bar.set_live_badge(_live_link_on)
		_chrome_bar.set_references(_find_referencing_files() if _has_live_target() else [])


# Finds every .tscn/.tres in the project whose ResourceLoader.get_dependencies()
# lists the `.nyx` and/or its exported .gdshader - i.e. "what's actually using
# this shader." Recomputed at save/export/load time (not on every hover) so the
# chrome bar's reference-list tooltip can be a plain, instant tooltip rather
# than needing to fight Godot's native hover-timing with an async scan.
# ResourceLoader.get_dependencies() is a per-file, forward-dependency query
# (what THIS file depends on) - Godot has no reverse-dependency API, so this
# builds one by walking every project resource and checking each one's forward
# deps for our own path. Confirmed via ClassDB reflection that EditorFileSystem
# itself exposes no "who references this" query.
func _find_referencing_files() -> Array:
	var targets := []
	if not _current_nyx_path.is_empty():
		targets.append(_current_nyx_path)
	if not _exported_shader_path.is_empty():
		targets.append(_exported_shader_path)
	if targets.is_empty():
		return []
	var candidates := []
	_walk_filesystem(EditorInterface.get_resource_filesystem().get_filesystem(), candidates)
	var matches := []
	for path in candidates:
		if path == _current_nyx_path or path == _exported_shader_path:
			continue  # don't list the file against itself
		if path.get_extension() != "tscn" and path.get_extension() != "tres":
			continue
		var deps: PackedStringArray = ResourceLoader.get_dependencies(path)
		for d in deps:
			var is_match := false
			for t in targets:
				if t in d:
					is_match = true
					break
			if is_match:
				matches.append(path)
				break
	return matches


func _walk_filesystem(dir: EditorFileSystemDirectory, out: Array) -> void:
	for i in dir.get_file_count():
		out.append(dir.get_file_path(i))
	for i in dir.get_subdir_count():
		_walk_filesystem(dir.get_subdir(i), out)


# Writes the .gdshader with a provenance stamp (gates artifact -> Nyx navigation).


func _write_shader_file(path: String, code: String) -> bool:
	return NyxSerializer.write_shader(path, code, _current_nyx_path, _serialize_graph())


func _write_material_file(shader_path: String) -> bool:
	return NyxSerializer.write_material(shader_path, _graph.get_children())


# Dialog callback: full export (shader + material) or shader-only.
func _on_export_file_selected(path: String) -> void:
	if not path.ends_with(".gdshader"):
		path += ".gdshader"
	var code: String = _compiler.build_shader_code(_shader_type)
	if not _write_shader_file(path, code):
		return
	if _export_mode != "shader_only":
		_write_material_file(path)
	_set_exported_shader(path)
	# Persist the new exported path to the .nyx too (mirrors _do_update()) -
	# without this, it only exists in memory for the current session; reopening
	# the file later reads exported_shader_path back empty and Live silently
	# never turns on.
	if not _current_nyx_path.is_empty():
		NyxSerializer.write(_current_nyx_path, _serialize_graph_for_save())
	NyxCharon.notify_shader_updated(path, _preview_panel.get_active_material())
	EditorInterface.get_resource_filesystem().scan()
	if _export_mode == "shader_only":
		print("Nyx: exported shader -> %s" % path)
	else:
		print("Nyx: exported\n  shader  -> %s\n  material -> %s" % [path, path.get_basename() + ".tres"])


func sync_size(new_size: Vector2) -> void:
	if _outer_vbox:
		_outer_vbox.size = new_size
	# Initial placement happens once in _do_setup_initial_panel_layout(), which
	# waits for the tab to be visible and settled before placing - so by the
	# time either panel is_placed(), _graph_container.size is already trustworthy
	# and later calls here only need to reanchor against it.
	if _preview_panel and _preview_panel.is_placed():
		# Deferred: _outer_vbox.size = new_size above only queues a container
		# sort (Godot's deferred message queue), so _graph_container.size
		# wouldn't reflect the new width if read synchronously here.
		call_deferred("_reanchor_preview")
	if _properties_panel and _properties_panel.is_placed():
		call_deferred("_reanchor_properties")
	if _chrome_bar and _chrome_bar.is_placed():
		call_deferred("_reanchor_chrome_bar")
	if _tool_rail and _tool_rail.is_placed():
		call_deferred("_reanchor_tool_rail")
	if _search_popup:
		_search_popup.handle_resize()
	if _quick_add_popup:
		_quick_add_popup.handle_resize()
	if _command_palette:
		_command_palette.handle_resize()
	if _node_inspector:
		_node_inspector.handle_resize()


func _graph_top() -> float:
	return _graph_container.position.y if _graph_container else 0.0


func _reanchor_preview() -> void:
	if _preview_panel and _preview_panel.is_placed():
		_preview_panel.reanchor(_graph_top(), _outer_vbox.size.x)


func _reanchor_properties() -> void:
	if _properties_panel and _properties_panel.is_placed():
		_properties_panel.reanchor(_graph_top(), _outer_vbox.size.x)


func _reanchor_chrome_bar() -> void:
	if _chrome_bar and _chrome_bar.is_placed():
		_chrome_bar.reanchor(_graph_top())


func _reanchor_tool_rail() -> void:
	if _tool_rail and _tool_rail.is_placed():
		_tool_rail.reanchor(_graph_top(), _outer_vbox.size.x)


# One-shot initial placement for both floating panels, run once the Nyx tab is
# actually visible and the editor's post-visibility layout (dock-collapse from
# entering focus layout) has settled - see _await_layout_ready(). This mirrors
# why Ctrl+U always positions correctly: a freshly created main screen's first
# layout pass only ever runs while the tab is already visible/settled.
func _setup_initial_panel_layout() -> void:
	call_deferred("_do_setup_initial_panel_layout")


func _do_setup_initial_panel_layout() -> void:
	if not _preview_panel or not _properties_panel:
		return
	await _await_layout_ready()
	if not is_instance_valid(_preview_panel) or not is_instance_valid(_properties_panel):
		return
	if is_instance_valid(_chrome_bar):
		_chrome_bar.place_default(_graph_top())
	if is_instance_valid(_tool_rail):
		_tool_rail.place_default(_graph_top())
	_preview_panel.place_default(_graph_top())
	# Blackboard sits top-left under the command bar (ShaderGraph positioning),
	# below the chrome pill's actual height.
	var bar_h: float = _chrome_bar.size.y if is_instance_valid(_chrome_bar) else 28.0
	var top: float = _graph_top() + NyxChromeBar.TOP_MARGIN + bar_h + 8.0
	_properties_panel.place_default(top)


func _build_shortcuts_overlay() -> Control:
	# Outer overlay: IGNORE so clicks pass through to the panel or backdrop.
	# Backdrop: full-rect STOP - dismisses on any outside click.
	# Panel: the actual card, centred over the graph.
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false

	var backdrop := Control.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_toggle_shortcuts_overlay()
	)
	overlay.add_child(backdrop)

	var panel := PanelContainer.new()
	overlay.add_child(panel)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.14, 0.14, 0.18, 0.96)
	bg.set_corner_radius_all(8)
	bg.set_content_margin_all(14)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.24, 0.24, 0.30)
	panel.add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "Shortcuts"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("#4AAF78"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.tooltip_text = "Close"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	close_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	close_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	close_btn.add_theme_color_override("font_focus_color", Color(0.55, 0.55, 0.65))
	var _cb_empty := StyleBoxEmpty.new()
	close_btn.add_theme_stylebox_override("normal", _cb_empty)
	close_btn.add_theme_stylebox_override("hover", _cb_empty)
	close_btn.add_theme_stylebox_override("pressed", _cb_empty)
	close_btn.add_theme_stylebox_override("focus", _cb_empty)
	close_btn.pressed.connect(_toggle_shortcuts_overlay)
	title_row.add_child(close_btn)

	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	var sep_line := StyleBoxLine.new()
	sep_line.color = Color(0.24, 0.24, 0.30)
	sep_line.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_line)
	vbox.add_child(sep)

	var entries := [
		["Right-click / A", "Add node"],
		["X", "Delete selected"],
		["R", "Add Relay"],
		["Ctrl+C", "Copy selected"],
		["Ctrl+V", "Paste"],
		["Ctrl+D", "Duplicate selected"],
		["Left-drag", "Pan canvas"],
		["Shift+Left-drag", "Box select"],
		["Ctrl+N", "New graph"],
		["Ctrl+O", "Open graph"],
		["Ctrl+S", "Save (+ Update Shader File, if exported)"],
		["Ctrl+Shift+S", "Save As"],
		["Ctrl+E", "Export Shader + Material / Update Shader File"],
		["Ctrl+Shift+E", "Export Shader + Material As…"],
		["Ctrl+U", "Reload Nyx"],
		["Ctrl+P", "Command palette"],
		["?", "Toggle this chart"],
	]
	for e in entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var key_lbl := Label.new()
		key_lbl.text = e[0]
		key_lbl.custom_minimum_size.x = 150
		key_lbl.add_theme_font_size_override("font_size", 11)
		key_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.88))
		var desc_lbl := Label.new()
		desc_lbl.text = e[1]
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
		row.add_child(key_lbl)
		row.add_child(desc_lbl)
		vbox.add_child(row)

	var types_sep := HSeparator.new()
	types_sep.add_theme_constant_override("separation", 4)
	var types_sep_line := StyleBoxLine.new()
	types_sep_line.color = Color(0.24, 0.24, 0.30)
	types_sep_line.thickness = 1
	types_sep.add_theme_stylebox_override("separator", types_sep_line)
	vbox.add_child(types_sep)

	var types_title := Label.new()
	types_title.text = "Types"
	types_title.add_theme_font_size_override("font_size", 11)
	types_title.add_theme_color_override("font_color", Color("#4AAF78"))
	vbox.add_child(types_title)

	# [type_id, friendly_name, glsl_name]
	var type_entries := [
		[1, "Value", "float"],
		[2, "UV", "vec2"],
		[0, "Color", "vec3"],
		[3, "Color + Alpha", "vec4"],
	]
	for te in type_entries:
		var trow := HBoxContainer.new()
		trow.add_theme_constant_override("separation", 6)

		var sw := ColorRect.new()
		sw.color = NyxRegistry.NyxNodeBase._type_color(te[0])
		sw.custom_minimum_size = Vector2(9, 9)
		sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		trow.add_child(sw)

		var tlbl := Label.new()
		tlbl.text = "%s  (%s)" % [te[1], te[2]]
		tlbl.add_theme_font_size_override("font_size", 11)
		tlbl.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
		trow.add_child(tlbl)

		vbox.add_child(trow)

	return overlay



func _push_undo_state() -> void:
	_undo_stack.push_back(_serialize_graph())
	if _undo_stack.size() > 50:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_mark_dirty()
	if _properties_panel and _properties_panel.visible:
		call_deferred(_properties_panel.rebuild)


# --- Dirty tracking (unsaved .nyx working-file changes) ---

func _mark_dirty() -> void:
	if _loading or _dirty:
		return
	_dirty = true
	_update_save_button()


func _set_clean() -> void:
	_dirty = false
	_update_save_button()


func _update_save_button() -> void:
	var name := _current_nyx_path.get_file() if not _current_nyx_path.is_empty() else "untitled.nyx"
	if _chrome_bar:
		_chrome_bar.update_filename(name, _dirty, not _current_nyx_path.is_empty())


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



# Recreate a {nodes, connections} buffer into the graph, offset from the originals, and
# leave the new nodes selected (so they can be dragged immediately). Used by paste and
# duplicate; new names auto-uniquify on add_child, captured into name_map for the conns.
func _paste_buffer(buf: Dictionary, offset: Vector2 = Vector2(30, 30)) -> void:
	# NOTE: paste does NOT gate on shader mode. The clipboard is per-session and persists
	# across load/new, so you can paste a node that's invalid for the current mode (e.g. a
	# spatial Fresnel into a particle graph). This can't crash - it's a soft failure: an
	# off-mode node only produces bad GLSL if it's actually wired into the output chain
	# (the compiler walks from the sink), and that's recoverable by deleting it. A precise
	# gate would need a parallel type->mode-flags table (the registry is keyed by id, not
	# type), which we deliberately avoid. Same non-enforcement already exists for load.
	var src: Array = buf.get("nodes", [])
	if src.is_empty():
		return
	_push_undo_state()
	_deselect_all_nodes()
	var name_map := {}
	var new_nodes: Array[Node] = []
	for nd in src:
		var type: String = nd["type"]
		if not NyxRegistry.NODE_CLASSES.has(type):
			continue
		var node = NyxRegistry.NODE_CLASSES[type].new()
		var pos: Array = nd["position"]
		var base: String = nd["name"]
		if base.begins_with("@"):
			base = type.trim_suffix("Node")
		_add_node(node, Vector2(pos[0], pos[1]) + offset, base)
		name_map[nd["name"]] = str(node.name)
		var state: Dictionary = nd.get("state", {})
		if not state.is_empty():
			node.set_state(state)
		new_nodes.append(node)
	for conn in buf.get("connections", []):
		var from = name_map.get(conn["from_node"])
		var to = name_map.get(conn["to_node"])
		if from != null and to != null:
			_graph.connect_node(from, conn["from_port"], to, conn["to_port"])
	for node in new_nodes:
		node.selected = true
	_compiler.update_all_polymorphic_ports()
	_compiler.update_contextual_labels()
	_request_compile()
	_mark_dirty()


func _copy_selected_nodes() -> void:
	var buf := NyxSerializer.serialize_selected(_graph)
	if not (buf["nodes"] as Array).is_empty():
		_clipboard = buf


func _paste_clipboard() -> void:
	# Paste anchors the copied group's top-left at the mouse cursor (in graph space), so it
	# lands where you're pointing rather than back at the originals' (maybe scrolled-away)
	# location. Relative layout between the pasted nodes is preserved.
	var src: Array = _clipboard.get("nodes", [])
	if src.is_empty():
		return
	var min_pos := Vector2(INF, INF)
	for nd in src:
		var p: Array = nd["position"]
		min_pos = min_pos.min(Vector2(p[0], p[1]))
	var mouse_graph := _graph.get_local_mouse_position() / _graph.zoom + _graph.scroll_offset
	_paste_buffer(_clipboard, mouse_graph - min_pos)


func _duplicate_selected_nodes() -> void:
	# Duplicate stays a small offset from the originals (the cursor is usually right on the
	# node you just selected, so cursor-anchoring would stack the copy on top). Uses its own
	# buffer so it never clobbers the copy/paste clipboard.
	_paste_buffer(NyxSerializer.serialize_selected(_graph))


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from := _graph.get_node_or_null(str(from_node))
	var to := _graph.get_node_or_null(str(to_node))
	if not from or not to:
		return
	var from_type: int = _compiler.resolve_output_type(from, from_port)
	var to_type: int = to.get_input_port_type(to_port)
	if not _compiler.can_promote(from_type, to_type):
		return
	_push_undo_state()
	_graph.connect_node(from_node, from_port, to_node, to_port)
	_compiler.update_all_polymorphic_ports()
	_compiler.update_contextual_labels()
	_request_compile()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_push_undo_state()
	_graph.disconnect_node(from_node, from_port, to_node, to_port)
	_compiler.update_all_polymorphic_ports()
	_compiler.update_contextual_labels()
	_request_compile()


# Connection-drop node spawn (see .nyx-notes/olympus-viewport.md's
# "Connection-drop node spawn" design). Dragging a connection out of an INPUT
# port and releasing on empty canvas fires connection_from_empty(to_node,
# to_port, ...) - the port's type is already known, so this is the
# low-ambiguity side: a small curated quick-add list, weighted toward
# param-mode value nodes (the port/param/setting rule - tunability comes by
# wiring a param-mode value node in, never a per-port param checkbox).
func _on_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2) -> void:
	var to_node_ref := _graph.get_node_or_null(str(to_node))
	if not to_node_ref:
		return
	var to_type: int = to_node_ref.get_input_port_type(to_port)
	var candidates := _build_quick_add_candidates(to_type)
	if candidates.is_empty():
		return
	_pending_input_connection = {
		"to_node": to_node,
		"to_port": to_port,
		"graph_position": release_position / _graph.zoom + _graph.scroll_offset,
	}
	_quick_add_popup.open(candidates, release_position)


# Dragging out of an OUTPUT port and releasing on empty used to open the full
# type-agnostic aMenu (2026-07-03 design) on the premise that an output alone
# can't narrow "what comes next" - true for suggesting ONE obvious node, but
# wrong for filtering the candidate SET (Noah, 2026-07-06: "it doesn't make
# sense to allow adding a node that can't connect... let alone one that
# doesn't even have an input"). Reuses the SAME quick-add popup as the input
# side instead of the aMenu - a curated, type-filtered list of every node with
# at least one compatible input port, via NyxRegistry.NODE_INPUT_TYPES.
func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	var from_node_ref := _graph.get_node_or_null(str(from_node))
	if not from_node_ref:
		return
	var from_type: int = _compiler.resolve_output_type(from_node_ref, from_port)
	var candidates := _build_output_drop_candidates(from_type)
	if candidates.is_empty():
		return
	_pending_output_connection = {"from_node": from_node, "from_port": from_port}
	_spawn_position = release_position / _graph.zoom + _graph.scroll_offset
	_quick_add_popup.open(candidates, release_position)


# Candidates are the fixed "Inputs" category value/context nodes - the only
# ones meaningful to auto-spawn+connect from a known input port type. Param-
# capable types (Float/Color/Vector3) get an extra "(Parameter)" entry
# weighted above their plain counterpart; both remain compatible-type-filtered
# via the same promotion matrix _on_connection_request uses.
const _QUICK_ADD_CANDIDATES := [
	{"id": 5, "label": "Float", "type": 1, "paramable": true},
	{"id": 0, "label": "Color", "type": 3, "paramable": true},
	{"id": 48, "label": "Vector3", "type": 0, "paramable": true},
	{"id": 4, "label": "UV", "type": 2, "particle_unsafe": true},
	{"id": 11, "label": "Time", "type": 1},
	{"id": 20, "label": "Vertex", "type": 0, "spatial_only": true},
	{"id": 63, "label": "Object Position", "type": 0, "spatial_only": true},
	{"id": 64, "label": "World Position", "type": 0, "spatial_only": true},
	{"id": 65, "label": "Instance Custom Data", "type": 3, "spatial_only": true},
]


# Full shader-type gating, mirroring nyx_search_popup.gd's _is_node_unavailable
# exactly (particle_only/particle_unsafe/spatial_only/canvas_only) - a strict
# superset of what the small _QUICK_ADD_CANDIDATES table alone ever needed
# (none of those 9 entries carry particle_only/canvas_only), so one shared
# helper covers both the input-side small list and the output-side full-
# registry scan below.
func _is_quick_add_unavailable(entry: Dictionary) -> bool:
	if _shader_type == 2:  # particle
		if entry.get("particle_only", false):
			return false
		return entry.get("particle_unsafe", false) or entry.get("spatial_only", false) \
			or entry.get("canvas_only", false)
	if entry.get("particle_only", false):
		return true
	return (entry.get("spatial_only", false) and _shader_type == 1) or \
		   (entry.get("canvas_only", false) and _shader_type == 0)


func _build_quick_add_candidates(to_type: int) -> Array:
	var params := []
	var plains := []
	for c in _QUICK_ADD_CANDIDATES:
		if _is_quick_add_unavailable(c):
			continue
		if not _compiler.can_promote(c["type"], to_type):
			continue
		if c.get("paramable", false):
			params.append({"id": c["id"], "label": c["label"], "is_param": true})
		plains.append({"id": c["id"], "label": c["label"], "is_param": false})
	return params + plains


# Walks the FULL node registry (not the small Inputs-only table above) so the
# output-side drop can offer Math/Vector/Noise/etc. nodes - anything with at
# least one input port compatible with the dragged output's type, via the
# static NyxRegistry.NODE_INPUT_TYPES table (see its own doc comment for why
# this is read from set_slot() declarations rather than a runtime probe).
# Particle Start/Process are additionally excluded once one already exists in
# the graph (both are singletons - _on_context_menu_selected already no-ops a
# duplicate spawn; filtering here avoids ever offering a pick that can't do
# anything, and _handle_quick_add_output_side's _last_spawned_node comparison
# is a defensive backstop in case a no-op spawn slips through some other way).
func _build_output_drop_candidates(from_type: int) -> Array:
	var result := []
	for category in NyxRegistry.NODE_REGISTRY:
		for entry in category["nodes"]:
			var id: int = entry["id"]
			if id == 55 and _graph.get_node_or_null("ParticleStartNode"):
				continue
			if id == 56 and _graph.get_node_or_null("ParticleProcessNode"):
				continue
			if _is_quick_add_unavailable(entry):
				continue
			var input_types: Array = NyxRegistry.NODE_INPUT_TYPES.get(id, [])
			if input_types.is_empty():
				continue
			var compatible := false
			for t in input_types:
				if _compiler.can_promote(from_type, t):
					compatible = true
					break
			if compatible:
				result.append({"id": id, "label": entry["label"], "is_param": false})
	return result


func _spawn_quick_add_node(id: int, pos: Vector2) -> Node:
	match id:
		0: _add_node(NyxRegistry.ColorNode.new(), pos, "Color")
		4: _add_node(NyxRegistry.UVNode.new(), pos, "UV")
		5: _add_node(NyxRegistry.FloatNode.new(), pos, "Float")
		11: _add_node(NyxRegistry.TimeNode.new(), pos, "Time")
		20: _add_node(NyxRegistry.VertexNode.new(), pos, "Vertex")
		48: _add_node(NyxRegistry.Vector3Node.new(), pos, "Vector3")
		63: _add_node(NyxRegistry.ObjectPositionNode.new(), pos, "ObjectPosition")
		64: _add_node(NyxRegistry.WorldPositionNode.new(), pos, "WorldPosition")
		65: _add_node(NyxRegistry.InstanceCustomDataNode.new(), pos, "InstanceCustomData")
		_: return null
	return _last_spawned_node


# Reads the real port label off the node body: every node in this codebase
# adds its port-row control(s) via add_child() in the same order as the ports
# themselves land in set_slot(), so get_child(port_idx) is that row's control
# - a Label (.text), an EditorSpinSlider (.label), or (for a combined in/out
# row like Ocean Waves' "Position | Offset") a Container whose input-side
# Label is always added first (confirmed across every node surveyed - see
# ocean_waves_node.gd/depth_fade_node.gd). Falls back to the node's title if
# a node ever breaks this convention (e.g. a future custom-drawn node).
func _guess_param_default_name(to_node: Node, to_port: int) -> String:
	var port_label := _find_port_label_text(to_node, to_port)
	var node_part := _to_snake_case(String(to_node.title))
	var base: String
	if port_label.is_empty():
		base = "%s_%d" % [node_part, to_port + 1]
	else:
		# Always node-qualified (not just when the node has multiple inputs) -
		# a simpler rule, and it means two different nodes' same-named ports
		# (e.g. two Mix nodes' "A") never collide by construction. Godot/GLSL
		# uniform-naming convention (snake_case) matches every hand-authored
		# param name already in the codebase (rough_base, ripple_strength, etc.
		# - see dev_tools/generate_ocean_showcase.gd).
		base = "%s_%s" % [node_part, _to_snake_case(port_label)]
	return _unique_param_name(base)


# Lowercase + underscores, stripped of anything outside [a-z0-9_] and
# collapsed - titles/labels here are always plain words ("Ocean Waves",
# "Position", "A"), so this is a light sanitize, not a full CamelCase splitter.
func _to_snake_case(text: String) -> String:
	var lower := text.to_lower().replace(" ", "_")
	var result := ""
	for c in lower:
		if c == "_" or (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			result += c
	while result.contains("__"):
		result = result.replace("__", "_")
	return result.trim_prefix("_").trim_suffix("_")


# Increments (_2, _3, ...) until the name doesn't collide with any param
# already in use elsewhere in the graph - checked against the live graph, not
# just other quick-add spawns, so it also catches hand-named params.
func _unique_param_name(base: String) -> String:
	var used := _collect_used_param_names()
	if not used.has(base):
		return base
	var i := 2
	while used.has("%s_%d" % [base, i]):
		i += 1
	return "%s_%d" % [base, i]


func _collect_used_param_names() -> Dictionary:
	var used := {}
	for child in _graph.get_children():
		if child is GraphNode and child.has_method("is_param_mode") and child.is_param_mode():
			used[child.get_param_name()] = true
	return used


func _find_port_label_text(to_node: Node, to_port: int) -> String:
	if to_port < 0 or to_port >= to_node.get_child_count():
		return ""
	return _extract_label_text(to_node.get_child(to_port))


func _extract_label_text(control: Node) -> String:
	if control is Label:
		return (control as Label).text
	if control is EditorSpinSlider:
		return (control as EditorSpinSlider).label
	if control is Container:
		for c in control.get_children():
			var found := _extract_label_text(c)
			if not found.is_empty():
				return found
	return ""


func _on_quick_add_chosen(id: int, is_param: bool) -> void:
	if not _pending_input_connection.is_empty():
		_handle_quick_add_input_side(id, is_param)
	elif not _pending_output_connection.is_empty():
		_handle_quick_add_output_side(id)


func _handle_quick_add_input_side(id: int, is_param: bool) -> void:
	var to_node: StringName = _pending_input_connection["to_node"]
	var to_port: int = _pending_input_connection["to_port"]
	var graph_pos: Vector2 = _pending_input_connection["graph_position"]
	var to_node_ref := _graph.get_node_or_null(str(to_node))
	_pending_input_connection = {}
	if not to_node_ref:
		return

	_push_undo_state()
	var node := _spawn_quick_add_node(id, graph_pos)
	if not node:
		return
	if is_param and node.has_method("set_param_mode"):
		node.set_param_mode(true)
		node.set_param_name(_guess_param_default_name(to_node_ref, to_port))
		# Seed the exported hint_range from the target port's own slider bounds
		# (Ocean Waves' Wavelength up to 100, Direction up to 360, etc.) instead
		# of FloatNode's generic 0..1 default, which squashed every auto-spawned
		# param slider to 0..1 in the material Inspector regardless of the
		# actual value range the port expects — found live 2026-07-07.
		if node.has_method("set_param_range") and to_node_ref.has_method("get_param_range_hint"):
			var range_hint: Array = to_node_ref.get_param_range_hint(to_port)
			if range_hint.size() >= 2:
				var step: float = range_hint[2] if range_hint.size() > 2 else 0.0
				node.set_param_range(range_hint[0], range_hint[1], step)
	_graph.connect_node(node.name, 0, to_node, to_port)
	_compiler.update_all_polymorphic_ports()
	_compiler.update_contextual_labels()
	_request_compile()

	# Non-modal naming (Noah, 2026-07-06): open the inspector with the param
	# name field focused and pre-selected - typing replaces the guessed
	# default, Enter/click-away keeps it. Never blocks on a forced name entry.
	if is_param and node.has_signal("inspector_requested"):
		node.emit_signal("inspector_requested", node)
		if _node_inspector.has_method("focus_param_name"):
			_node_inspector.focus_param_name()


# Reuses the real, proven spawn path (_on_context_menu_selected, which pushes
# its own undo state and places the node at _spawn_position - already set in
# _on_connection_to_empty) rather than a parallel construction switch, then
# wires the dragged output into the new node's first compatible input via the
# existing _auto_connect_pending_output. The prev_spawned comparison guards
# against a no-op spawn (e.g. picking Particle Start/Process when one already
# exists is filtered out at candidate-build time, but this is a cheap,
# generic backstop against any other reason the spawn might silently no-op)
# - without it, _last_spawned_node would still hold a STALE reference from
# some earlier successful spawn, and connecting to that would be a real,
# confusing bug: wiring the drag into the wrong node entirely.
func _handle_quick_add_output_side(id: int) -> void:
	var prev_spawned := _last_spawned_node
	_on_context_menu_selected(id)
	if _last_spawned_node == prev_spawned:
		_pending_output_connection = {}
		return
	_auto_connect_pending_output(_last_spawned_node)


func _auto_connect_pending_output(node: Node) -> void:
	if _pending_output_connection.is_empty() or not is_instance_valid(node):
		return
	var from_node: StringName = _pending_output_connection["from_node"]
	var from_port: int = _pending_output_connection["from_port"]
	_pending_output_connection = {}
	var from_node_ref := _graph.get_node_or_null(str(from_node))
	if not from_node_ref:
		return
	var from_type: int = _compiler.resolve_output_type(from_node_ref, from_port)
	for port in range(node.get_input_port_count()):
		if _compiler.can_promote(from_type, node.get_input_port_type(port)):
			_graph.connect_node(from_node, from_port, node.name, port)
			_compiler.update_all_polymorphic_ports()
			_compiler.update_contextual_labels()
			_request_compile()
			return


# True when the mouse is over any node (body or its port dots). GraphEdit's gui_input
# fires for presses over nodes too - it manages node drag/connection centrally - so we
# must NOT pan there or we'd steal the press from node-dragging. The rect is grown to
# cover the port dots that overhang the node edge (the connection grab zone).
func _is_mouse_over_node() -> bool:
	var m := get_global_mouse_position()
	for child in _graph.get_children():
		if child is GraphNode and (child as GraphNode).get_global_rect().grow(12.0).has_point(m):
			return true
	return false


func _deselect_all_nodes() -> void:
	for child in _graph.get_children():
		if child is GraphNode:
			child.selected = false


func _shortcut_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var ctrl: bool = event.ctrl_pressed
	var shift: bool = event.shift_pressed
	if not ctrl:
		return
	# NB: Ctrl+C/V/D are NOT here - GraphEdit consumes them when focused, so they're wired
	# via its copy_nodes_request / paste_nodes_request / duplicate_nodes_request signals.
	match event.keycode:
		KEY_U:
			if not shift:
				emit_signal("reload_requested")
				accept_event()
		KEY_N:
			if not shift:
				_on_new_pressed()
				accept_event()
		KEY_S:
			if shift:
				_popup_save_dialog()
			else:
				_on_save_pressed()
				if not _exported_shader_path.is_empty():
					_do_update()
			accept_event()
		KEY_O:
			if not shift:
				_load_dialog.popup_centered_ratio(0.5)
				accept_event()
		KEY_E:
			if shift:
				_on_export_menu_id(2)  # Export As… (re-link)
			else:
				_on_export_pressed()
			accept_event()
		KEY_P:
			if not shift:
				_open_command_palette()
				accept_event()


func _on_graph_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_spawn_position = event.position / _graph.zoom + _graph.scroll_offset
			_search_popup.open(_shader_type)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# Shift+drag on EMPTY canvas pans. Plain drag is GraphEdit's native box-select -
			# confirmed (2026-06-30, vanilla-GraphEdit test scene) that Shift+drag does NOT
			# trigger native box-select in this Godot version, only an unmodified drag does,
			# so panning moved to Shift to free up plain drag for selection. Over a node
			# (body or dots) we do nothing so GraphEdit's own node-drag / connection-drag
			# runs. The whole pan lifecycle lives here: GraphEdit captures mouse focus on the
			# press, so the drag motion and release come back even over nodes.
			if event.pressed:
				if event.shift_pressed and not _is_mouse_over_node():
					_panning = true
					_pan_moved = false
					accept_event()
			else:
				if _panning:
					_panning = false
					# A clean shift-click on empty canvas (no drag) deselects all nodes -
					# the pan intercept means GraphEdit never gets to do this itself.
					if not _pan_moved:
						_deselect_all_nodes()
					accept_event()
	elif event is InputEventMouseMotion and _panning:
		_pan_moved = true
		_graph.scroll_offset -= event.relative / _graph.zoom
		accept_event()


# Bare graph shortcuts (A / R / X / ?). Handled here rather than in the graph's gui_input
# so they fire without first clicking to focus GraphEdit - _unhandled_key_input runs for
# any key the focused control didn't consume. Gated on the cursor being over the graph
# (so they don't fire while editing elsewhere) and Ctrl/Cmd-free (those belong to
# _shortcut_input). A focused field consumes its own keys, so typing is unaffected.
func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.ctrl_pressed or event.meta_pressed:
		return
	# Esc exits the preview's focused state first, before anything else Esc might
	# mean, and regardless of where the cursor is (checked before the over-graph
	# gate below).
	if event.keycode == KEY_ESCAPE and _preview_panel and _preview_panel.is_focused_state():
		_preview_panel.exit_focus()
		accept_event()
		return
	# While RMB-freelook is active in the preview, WASD/QE are camera input —
	# swallow bare keys here so they don't fire graph shortcuts (e.g. A → search).
	if _preview_panel and _preview_panel.visible and _preview_panel.is_freelooking():
		return
	# F frames the preview target when the cursor is over the preview panel
	# (GraphEdit doesn't use F, so no conflict).
	if event.keycode == KEY_F and _preview_panel and _preview_panel.visible \
			and _preview_panel.get_global_rect().has_point(get_global_mouse_position()):
		_preview_panel.frame_target()
		accept_event()
		return
	if _search_popup and _search_popup.visible:
		return
	if _command_palette and _command_palette.visible:
		return
	if not _graph.get_global_rect().has_point(get_global_mouse_position()):
		return
	if event.keycode == KEY_SLASH and event.shift_pressed:
		_toggle_shortcuts_overlay()
		accept_event()
		return
	match event.keycode:
		KEY_X:
			var selected: Array[StringName] = []
			for child in _graph.get_children():
				if child is GraphNode and child.selected:
					selected.append(child.name)
			if not selected.is_empty():
				_on_delete_nodes_request(selected)
				accept_event()
		KEY_R:
			# Spawns Relay, not Reroute - Reroute's bare-port GraphNode body
			# fights Godot's titlebar/body layout model (see CLAUDE.md gotcha,
			# 2026-07-01); Relay looks right by default and needs no custom
			# node to fix that properly, which is parked for later.
			_push_undo_state()
			_spawn_position = _graph.get_local_mouse_position() / _graph.zoom + _graph.scroll_offset
			_add_node(NyxRegistry.RelayNode.new(), _spawn_position, "Relay")
			accept_event()
		KEY_A:
			_spawn_position = _graph.get_local_mouse_position() / _graph.zoom + _graph.scroll_offset
			_search_popup.open(_shader_type)
			accept_event()


func _open_command_palette(anchor_global_pos = null) -> void:
	_command_palette.open({
		"exported": not _exported_shader_path.is_empty(),
		"live_on": _live_link_on,
		"has_live_target": _has_live_target(),
		"recent_files": _get_recent_files(),
	}, anchor_global_pos)


func _toggle_shortcuts_overlay() -> void:
	_shortcuts_overlay.visible = not _shortcuts_overlay.visible
	if _shortcuts_overlay.visible:
		_shortcuts_overlay.size = _graph_container.size
		_shortcuts_overlay.position = Vector2.ZERO
		_shortcuts_overlay.move_to_front()
		var panel := _shortcuts_overlay.get_child(1)  # child 0 = backdrop, 1 = panel
		panel.reset_size()
		var sz: Vector2 = panel.get_combined_minimum_size()
		panel.position = ((_graph_container.size - sz) * 0.5).max(Vector2.ZERO)


func _on_search_node_chosen(id: int) -> void:
	# The search popup picked a node - spawn it at the captured _spawn_position.
	# _on_context_menu_selected pushes its own undo snapshot, so no extra push here.
	# (Connection-drop node spawn no longer routes through the aMenu at all -
	# both drag directions use the quick-add popup; see _on_connection_from_empty
	# / _on_connection_to_empty.)
	_on_context_menu_selected(id)


func _on_context_menu_selected(id: int) -> void:
	_push_undo_state()
	match id:
		0: _add_node(NyxRegistry.ColorNode.new(), _spawn_position, "Color")
		1: _add_node(NyxRegistry.AddNode.new(), _spawn_position, "Add")
		2: _add_node(NyxRegistry.MultiplyNode.new(), _spawn_position, "Multiply")
		3: _add_node(NyxRegistry.MixNode.new(), _spawn_position, "Mix")
		4: _add_node(NyxRegistry.UVNode.new(), _spawn_position, "UV")
		5: _add_node(NyxRegistry.FloatNode.new(), _spawn_position, "Float")
		6: _add_node(NyxRegistry.SubtractNode.new(), _spawn_position, "Subtract")
		7: _add_node(NyxRegistry.ClampNode.new(), _spawn_position, "Clamp")
		8: _add_node(NyxRegistry.PowerNode.new(), _spawn_position, "Power")
		9: _add_node(NyxRegistry.SinNode.new(), _spawn_position, "Sin")
		10: _add_node(NyxRegistry.CosNode.new(), _spawn_position, "Cos")
		11: _add_node(NyxRegistry.TimeNode.new(), _spawn_position, "Time")
		12: _add_node(NyxRegistry.SplitNode.new(), _spawn_position, "Split")
		13: _add_node(NyxRegistry.CombineNode.new(), _spawn_position, "Combine")
		14: _add_node(NyxRegistry.TextureSampleNode.new(), _spawn_position, "TextureSample")
		15: _add_node(NyxRegistry.FresnelNode.new(), _spawn_position, "Fresnel")
		16: _add_node(NyxRegistry.ScaleNode.new(), _spawn_position, "Scale")
		17: _add_node(NyxRegistry.StepNode.new(), _spawn_position, "Step")
		18: _add_node(NyxRegistry.SmoothstepNode.new(), _spawn_position, "Smoothstep")
		19: _add_node(NyxRegistry.NoiseNode.new(), _spawn_position, "Noise")
		36: _add_node(NyxRegistry.FBMNode.new(), _spawn_position, "FBM")
		67: _add_node(NyxRegistry.OceanWavesNode.new(), _spawn_position, "OceanWaves")
		37: _add_node(NyxRegistry.GradientNode.new(), _spawn_position, "Gradient")
		38: _add_node(NyxRegistry.CurveNode.new(), _spawn_position, "Curve")
		39: _add_node(NyxRegistry.TilingOffsetNode.new(), _spawn_position, "TilingOffset")
		40: _add_node(NyxRegistry.RotateUVNode.new(), _spawn_position, "RotateUV")
		41: _add_node(NyxRegistry.WarpNode.new(), _spawn_position, "Warp")
		42: _add_node(NyxRegistry.NormalFromHeightNode.new(), _spawn_position, "NormalFromHeight")
		43: _add_node(NyxRegistry.BlendNormalsNode.new(), _spawn_position, "BlendNormals")
		44: _add_node(NyxRegistry.ScreenUVNode.new(), _spawn_position, "ScreenUV")
		45: _add_node(NyxRegistry.ScreenTextureNode.new(), _spawn_position, "ScreenTexture")
		46: _add_node(NyxRegistry.DepthFadeNode.new(), _spawn_position, "DepthFade")
		20: _add_node(NyxRegistry.VertexNode.new(), _spawn_position, "Vertex")
		21: _add_node(NyxRegistry.NormalMapNode.new(), _spawn_position, "NormalMap")
		22: _add_node(NyxRegistry.AbsNode.new(), _spawn_position, "Abs")
		29: _add_node(NyxRegistry.CeilNode.new(), _spawn_position, "Ceil")
		30: _add_node(NyxRegistry.FloorNode.new(), _spawn_position, "Floor")
		31: _add_node(NyxRegistry.FractNode.new(), _spawn_position, "Fract")
		32: _add_node(NyxRegistry.NegateNode.new(), _spawn_position, "Negate")
		33: _add_node(NyxRegistry.OneMinusNode.new(), _spawn_position, "OneMinus")
		34: _add_node(NyxRegistry.RoundNode.new(), _spawn_position, "Round")
		35: _add_node(NyxRegistry.SqrtNode.new(), _spawn_position, "Sqrt")
		23: _add_node(NyxRegistry.MinMaxNode.new(), _spawn_position, "MinMax")
		24: _add_node(NyxRegistry.DivideNode.new(), _spawn_position, "Divide")
		25: _add_node(NyxRegistry.ModNode.new(), _spawn_position, "Mod")
		26: _add_node(NyxRegistry.NormalizeNode.new(), _spawn_position, "Normalize")
		27: _add_node(NyxRegistry.LengthNode.new(), _spawn_position, "Length")
		28: _add_node(NyxRegistry.DotNode.new(), _spawn_position, "Dot")
		52: _add_node(NyxRegistry.RerouteNode.new(), _spawn_position, "Reroute")
		53: _add_node(NyxRegistry.RelayNode.new(), _spawn_position, "Relay")
		54: _add_node(NyxRegistry.PreviewRelayNode.new(), _spawn_position, "PreviewRelay")
		66: _add_node(NyxRegistry.ValueRelayNode.new(), _spawn_position, "ValueRelay")
		47: _add_node(NyxRegistry.CustomGLSLNode.new(), _spawn_position, "CustomGLSL")
		48: _add_node(NyxRegistry.Vector3Node.new(), _spawn_position, "Vector3")
		49: _add_node(NyxRegistry.SpriteTextureNode.new(), _spawn_position, "SpriteTexture")
		50: _add_node(NyxRegistry.VertexColorNode.new(), _spawn_position, "VertexColor")
		51: _add_node(NyxRegistry.TexturePixelSizeNode.new(), _spawn_position, "PixelSize")
		55:
			if not _graph.get_node_or_null("ParticleStartNode"):
				_add_node(NyxRegistry.ParticleStartNode.new(), _spawn_position, "ParticleStartNode")
				_update_sink_visibility()
		56:
			if not _graph.get_node_or_null("ParticleProcessNode"):
				_add_node(NyxRegistry.ParticleProcessNode.new(), _spawn_position, "ParticleProcessNode")
				_update_sink_visibility()
		57: _add_node(NyxRegistry.ParticleAgeNode.new(), _spawn_position, "ParticleAge")
		58: _add_node(NyxRegistry.ParticleVelocityNode.new(), _spawn_position, "ParticleVelocity")
		59: _add_node(NyxRegistry.ParticlePositionNode.new(), _spawn_position, "ParticlePosition")
		60: _add_node(NyxRegistry.ParticleDeltaNode.new(), _spawn_position, "ParticleDelta")
		61: _add_node(NyxRegistry.ParticleRandomNode.new(), _spawn_position, "ParticleRandom")
		62: _add_node(NyxRegistry.ParticleIndexNode.new(), _spawn_position, "ParticleIndex")
		63: _add_node(NyxRegistry.ObjectPositionNode.new(), _spawn_position, "ObjectPosition")
		64: _add_node(NyxRegistry.WorldPositionNode.new(), _spawn_position, "WorldPosition")
		65: _add_node(NyxRegistry.InstanceCustomDataNode.new(), _spawn_position, "InstanceCustomData")



func _serialize_graph() -> Dictionary:
	var nodes := []
	for child in _graph.get_children():
		if not child is GraphNode:
			continue
		var type := NyxRegistry.get_node_type(child)
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

	return {
		"nodes": nodes,
		"connections": connections,
		"shader_type": _shader_type,
		"exported_shader_path": _exported_shader_path,
	}


func _clear_graph_nodes() -> void:
	_graph.clear_connections()
	var to_remove: Array[Node] = []
	for child in _graph.get_children():
		if child is GraphNode:
			to_remove.append(child)
	for child in to_remove:
		_graph.remove_child(child)
		child.free()


func _deserialize_graph(data: Dictionary) -> void:
	# Reconstruction (and undo/redo) must not mark the graph dirty; the caller
	# decides cleanliness (load/new = clean, undo = leaves dirty unchanged).
	_loading = true
	_clear_graph_nodes()

	var saved_type: int = data.get("shader_type", 0)
	_shader_type = saved_type
	_sync_shader_type_ui(saved_type)
	# Restore the exported-shader-file path. Lazy: store the path only; the
	# Shader resource is re-resolved (ResourceLoader.load) on first Update /
	# Live use, not now.
	_exported_shader_path = data.get("exported_shader_path", "")
	_update_export_ui()
	# OutputNode restores its own slot config via set_state (which calls
	# set_shader_type); sink visibility is updated after recreation below.

	var name_map := {}
	for node_data in data.get("nodes", []):
		var type: String = node_data["type"]
		if not NyxRegistry.NODE_CLASSES.has(type):
			push_warning("Nyx: unknown node type '%s', skipping" % type)
			continue
		var node = NyxRegistry.NODE_CLASSES[type].new()
		var pos: Array = node_data["position"]
		var saved_name: String = node_data["name"]
		var target_name := saved_name if not saved_name.begins_with("@") else type.trim_suffix("Node")
		_add_node(node, Vector2(pos[0], pos[1]), target_name)
		name_map[saved_name] = str(node.name)
		var state: Dictionary = node_data.get("state", {})
		if not state.is_empty():
			node.set_state(state)

	for conn in data.get("connections", []):
		var from: String = name_map.get(conn["from_node"], conn["from_node"])
		var to: String = name_map.get(conn["to_node"], conn["to_node"])
		_graph.connect_node(from, conn["from_port"], to, conn["to_port"])

	if _shader_type == 0:
		_ensure_spatial_sinks()
	elif _shader_type == 2:
		_ensure_particle_sinks()
	_update_sink_visibility()
	_apply_preview_mesh_settings()
	_compiler.update_contextual_labels()
	_request_compile()
	_loading = false


func _on_new_pressed() -> void:
	# Skip the confirm when there's nothing to lose.
	if _dirty:
		_new_confirm.popup_centered()
	else:
		_new_graph()


# Force a 3-button confirm to read [OK | mid_btn | Cancel], right-aligned: move
# each to the end of the button row in turn (any leading spacer stays put, so
# alignment is preserved). OK is the safe "Save & …" action.
func _order_dialog_buttons(dialog: AcceptDialog, mid_btn: Button) -> void:
	var ok: Button = dialog.get_ok_button()
	var cancel: Button = dialog.get_cancel_button()
	var row := ok.get_parent()
	row.move_child(ok, row.get_child_count() - 1)
	row.move_child(mid_btn, row.get_child_count() - 1)
	row.move_child(cancel, row.get_child_count() - 1)


# Reset to a fresh editor state (mirrors the initial _ready setup): empty graph,
# default starting nodes, spatial mode, no exported shader file, no working-file path.
func _new_graph() -> void:
	_loading = true
	_clear_graph_nodes()
	_shader_type = 0
	_sync_shader_type_ui(0)
	_current_nyx_path = ""
	_set_exported_shader("")
	_preview_panel.reset_last_code()
	_undo_stack.clear()
	_redo_stack.clear()
	_add_node(NyxRegistry.OutputNode.new(), Vector2(300, 160), "OutputNode")
	_add_node(NyxRegistry.VertexOutputNode.new(), Vector2(300, 40), "VertexOutputNode")
	_update_sink_visibility()
	_apply_preview_mesh_settings()
	_restore_preview_scene()  # fresh graph has no pin: drops scene mode back to follow/mesh
	_sync_blackboard_on_graph_replace()  # fresh graph has no params: Blackboard hidden
	_frame_default_view()
	_request_compile()
	_loading = false
	_set_clean()  # fresh editor = nothing unsaved


# Serialize-dict for an actual disk save: _serialize_graph() plus the baked,
# stamped shader source that core/nyx_shader_importer.gd reads to make this
# `.nyx` directly usable as a Shader. Computed only at save time (not on every
# undo/redo snapshot) - nothing reads it until the next disk read/reimport.
func _serialize_graph_for_save() -> Dictionary:
	var d := _serialize_graph()
	var code: String = _compiler.build_shader_code(_shader_type)
	d["compiled_code"] = "%s%s\n%s%s" % [
		NyxCharon.PROVENANCE_PREFIX, _current_nyx_path, NyxCharon.NAV_HINT, code]
	return d


# Direct save to the current file; only pops the dialog for a never-saved graph.
# (Save As / fork-to-new-file arrives with the File menu.)
func _on_save_pressed() -> void:
	if _current_nyx_path.is_empty():
		_popup_save_dialog()
	elif NyxSerializer.write(_current_nyx_path, _serialize_graph_for_save()):
		_set_clean()
		print("Nyx: saved graph -> %s" % _current_nyx_path)


func _popup_save_dialog() -> void:
	# Co-locate: default the .nyx next to its exported shader file when there is one.
	if _current_nyx_path.is_empty() and not _exported_shader_path.is_empty():
		_save_dialog.current_dir = _exported_shader_path.get_base_dir()
	_save_dialog.popup_centered_ratio(0.5)


# Save the current graph, then run `after` once the save succeeds. If there's no
# path yet, open the save dialog first and continue once the user picks one.
func _save_then(after: Callable) -> void:
	if _current_nyx_path.is_empty():
		_pending_after_save = after
		_popup_save_dialog()
	elif NyxSerializer.write(_current_nyx_path, _serialize_graph_for_save()):
		_set_clean()
		after.call()


func _on_save_file_selected(path: String) -> void:
	if not path.ends_with(".nyx"):
		path += ".nyx"
	_current_nyx_path = path
	_push_recent(path)
	if NyxSerializer.write(path, _serialize_graph_for_save()):
		_set_clean()
		print("Nyx: saved graph -> %s" % path)
		# First save is the moment this graph becomes directly usable (drag onto
		# a material) - same "you probably want to see it live" default as
		# exporting a shader file, Ctrl+P -> Live is the opt-out either way.
		_update_export_ui()
		if not _live_link_on:
			_on_live_toggled(true)
		# Continue a pending "Save & New / Load" once the save succeeded.
		if _pending_after_save.is_valid():
			var after := _pending_after_save
			_pending_after_save = Callable()
			after.call()


# Shared discard-guard for every entry point that's about to replace the graph
# wholesale (load, embedded-graph recovery). Confirms before discarding unsaved
# work; the confirm dialog just re-invokes whichever action was pending.
func _confirm_discard_then(action: Callable) -> void:
	if _dirty:
		_pending_load_action = action
		_load_confirm.popup_centered()
	else:
		action.call()


# Public, guarded entry point: the Load dialog, "Open in Nyx" navigation, and
# double-click-to-open all route here. Confirms before discarding unsaved work.
func load_nyx(path: String) -> void:
	_confirm_discard_then(func(): _do_load(path))


func _do_load(path: String) -> void:
	var data = NyxSerializer.read(path)
	if data == null:
		return
	_current_nyx_path = path
	_push_recent(path)
	_deserialize_graph(data)  # also drives the chrome-bar badge, via _update_export_ui()
	_restore_preview_scene()  # a pinned graph reopens straight into scene mode
	_sync_blackboard_on_graph_replace()  # show the Blackboard iff this graph has params
	_set_clean()  # freshly loaded from disk
	# Any loaded (and therefore directly-usable) graph goes live by default,
	# same as a fresh first save or a fresh export.
	if _has_live_target():
		_on_live_toggled(true)
	print("Nyx: loaded graph ← %s" % path)


# Recovery entry point: "Open in Nyx" on an exported shader whose stamped .nyx
# is missing (deleted/moved/never-shipped) falls back here (see
# plugin.gd._open_in_nyx / NyxCharon.read_embedded_graph). `data` is the JSON
# blob embedded at export time - the same _serialize_graph() shape as a normal
# load, just recovered from a comment instead of a .nyx file. Confirms before
# discarding unsaved work, same as load_nyx.
func load_from_embedded_graph(data: Dictionary, source_shader_path: String) -> void:
	_confirm_discard_then(func(): _do_load_from_embedded_graph(data, source_shader_path))


func _do_load_from_embedded_graph(data: Dictionary, source_shader_path: String) -> void:
	_current_nyx_path = ""  # no .nyx to point at - it's what's missing
	_deserialize_graph(data)
	# The embedded exported_shader_path may be stale (or was never set, if this
	# was the graph's first-ever export) - it should self-reference the file we
	# just recovered from, so Update/Live can push straight back to it.
	_exported_shader_path = source_shader_path
	_update_export_ui()
	# A recovered graph only reflects the last Update - it needs Save to become
	# a real, reopenable .nyx again, so force dirty unconditionally (unlike
	# _mark_dirty(), which no-ops if already dirty - that guard would skip the
	# _update_save_button() call needed here since _current_nyx_path just
	# changed too, same as _do_load's unconditional _set_clean()).
	_dirty = true
	_update_save_button()
	push_warning("Nyx: recovered graph from embedded data in %s - save to create a new .nyx file" % source_shader_path)
	print("Nyx: recovered graph ← %s (embedded)" % source_shader_path)
