@tool
extends Panel

## Nyx Properties panel — floating panel showing exposed shader parameters.
##
## Owns the param list, row styling, copy-snippet interaction, and the detail section
## that appears when a param is clicked. Needs a GraphEdit ref (for walking graph
## children to find param-mode nodes); has no back-reference to nyx_main otherwise.
##
## Public API:
##   setup(graph, graph_container)  — store refs, build UI (call after add_child)
##   rebuild()                      — repopulate param list from current graph state
##   toggle()                       — show/hide + auto-rebuild on show
##   place_default(graph_top)       — initial anchor placement
##   reanchor(graph_top, outer_width) — re-pin on resize (no-op until placed)
##   is_placed()                    — true once placed at least once
##
## Graph Settings (Shader Type / Render Mode) used to live in a "context
## section" here, shown when a sink node was selected — that's fully migrated
## to the node-inspector popup now (nyx_node_inspector.gd's open_for_sink),
## so this panel is purely the params list again.
##
## Extracted from nyx_main.gd.

var _graph: GraphEdit
var _graph_container: Control

var _properties_vbox: VBoxContainer
var _detail_vbox: VBoxContainer
var _detail_sep: HSeparator
var _selected_param_row: Control = null

var _right_offset: float = 20.0
var _top_offset: float = -1.0          # -1 = not yet placed


func setup(graph: GraphEdit, graph_container: Control) -> void:
	_graph = graph
	_graph_container = graph_container
	_build()


func place_default(graph_top: float) -> void:
	_top_offset = graph_top
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


func is_placed() -> bool:
	return _top_offset >= 0.0


func rebuild() -> void:
	if not _properties_vbox:
		return
	_selected_param_row = null
	for child in _properties_vbox.get_children():
		child.queue_free()

	var found := false
	for node in _graph.get_children():
		if not node is GraphNode:
			continue
		if not node.has_method("is_param_mode") or not node.call("is_param_mode"):
			continue
		found = true
		_properties_vbox.add_child(_build_param_row(node))

	if not found:
		var lbl := Label.new()
		lbl.text = "No exposed parameters."
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.45, 0.48, 0.52))
		_properties_vbox.add_child(lbl)


func toggle() -> void:
	visible = not visible
	if visible:
		rebuild()


# ── Build ─────────────────────────────────────────────────────────────────────

func _build() -> void:
	size = Vector2(220, 320)
	visible = true

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.14, 0.14, 0.18, 0.92)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	add_child(vbox)

	# Header with drag handle
	var prop_header_wrap := PanelContainer.new()
	var prop_header_bg := StyleBoxFlat.new()
	var prop_header_base := get_theme_color("base_color", "Editor")
	prop_header_bg.bg_color = Color(prop_header_base.r, prop_header_base.g, prop_header_base.b, 0.95)
	prop_header_bg.corner_radius_top_left = 6
	prop_header_bg.corner_radius_top_right = 6
	prop_header_bg.border_width_bottom = 1
	prop_header_bg.border_color = Color(0.12, 0.12, 0.16)
	prop_header_wrap.add_theme_stylebox_override("panel", prop_header_bg)
	vbox.add_child(prop_header_wrap)

	var header := HBoxContainer.new()
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				set_meta("_drag_offset", get_local_mouse_position())
		elif ev is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if has_meta("_drag_offset"):
				position = position + ev.relative
				_right_offset = _graph_container.size.x - position.x - size.x
				_top_offset = position.y
	)
	prop_header_wrap.add_child(header)

	var pad_l := Control.new()
	pad_l.custom_minimum_size = Vector2(2, 0)
	pad_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(pad_l)

	var header_lbl := Label.new()
	header_lbl.text = "Properties"
	header_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_lbl)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	close_btn.add_theme_color_override("font_hover_color", Color("#4AAF78"))
	var empty := StyleBoxEmpty.new()
	close_btn.add_theme_stylebox_override("normal", empty)
	close_btn.add_theme_stylebox_override("hover", empty)
	close_btn.add_theme_stylebox_override("pressed", empty)
	close_btn.add_theme_stylebox_override("focus", empty)
	close_btn.pressed.connect(func() -> void: visible = false)
	header.add_child(close_btn)

	var pad_r := Control.new()
	pad_r.custom_minimum_size = Vector2(2, 0)
	pad_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(pad_r)

	# Param list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var params_margin := MarginContainer.new()
	params_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	params_margin.add_theme_constant_override("margin_left", 8)
	params_margin.add_theme_constant_override("margin_right", 2)
	params_margin.add_theme_constant_override("margin_top", 4)
	params_margin.add_theme_constant_override("margin_bottom", 4)
	scroll.add_child(params_margin)

	_properties_vbox = VBoxContainer.new()
	_properties_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_properties_vbox.add_theme_constant_override("separation", 2)
	params_margin.add_child(_properties_vbox)

	# Detail area — hidden until a param row is clicked
	_detail_sep = HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.22, 0.22, 0.28)
	sep_style.thickness = 1
	_detail_sep.add_theme_stylebox_override("separator", sep_style)
	_detail_sep.visible = false
	vbox.add_child(_detail_sep)

	_detail_vbox = VBoxContainer.new()
	_detail_vbox.add_theme_constant_override("separation", 6)
	_detail_vbox.visible = false
	vbox.add_child(_detail_vbox)


# ── Param rows ────────────────────────────────────────────────────────────────

func _build_param_row(node: Node) -> Control:
	var param_name: String = node.call("get_param_name") if node.has_method("get_param_name") else node.name

	var outer := Control.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.custom_minimum_size = Vector2(0, 24)
	outer.mouse_filter = Control.MOUSE_FILTER_STOP

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = param_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.80, 0.83, 0.88))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_lbl)

	var copy_lbl := Label.new()
	copy_lbl.text = "⧉"
	copy_lbl.add_theme_font_size_override("font_size", 16)
	copy_lbl.add_theme_color_override("font_color", Color(0.40, 0.43, 0.50))
	copy_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	copy_lbl.modulate = Color(1, 1, 1, 0)
	copy_lbl.mouse_entered.connect(func() -> void:
		copy_lbl.add_theme_color_override("font_color", Color("#4AAF78"))
	)
	copy_lbl.mouse_exited.connect(func() -> void:
		copy_lbl.add_theme_color_override("font_color", Color(0.40, 0.43, 0.50))
	)
	var copy_wrap := MarginContainer.new()
	copy_wrap.add_theme_constant_override("margin_left", 4)
	copy_wrap.add_theme_constant_override("margin_right", 4)
	copy_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy_wrap.add_child(copy_lbl)
	hbox.add_child(copy_wrap)

	outer.tooltip_text = 'material.set_shader_parameter("%s", value)' % param_name

	var _apply_style := func(hovered: bool) -> void:
		var selected := outer.get_meta("selected", false)
		var row_bg := StyleBoxFlat.new()
		if selected:
			row_bg.bg_color = Color(0.10, 0.22, 0.16)
			row_bg.border_width_left = 2
			row_bg.border_color = Color("#4AAF78")
		elif hovered:
			row_bg.bg_color = Color(0.20, 0.20, 0.26)
		else:
			row_bg.bg_color = Color(0, 0, 0, 0)
		outer.add_theme_stylebox_override("panel", row_bg)
		var name_col: Color
		if selected:
			name_col = Color("#4AAF78")
		elif hovered:
			name_col = Color.WHITE
		else:
			name_col = Color(0.80, 0.83, 0.88)
		name_lbl.add_theme_color_override("font_color", name_col)
		copy_lbl.modulate = Color(1, 1, 1, 1) if (hovered or selected) else Color(1, 1, 1, 0)

	outer.mouse_entered.connect(func() -> void: _apply_style.call(true))
	outer.mouse_exited.connect(func() -> void: _apply_style.call(false))

	outer.gui_input.connect(func(ev: InputEvent) -> void:
		if not ev is InputEventMouseButton or not ev.pressed or ev.button_index != MOUSE_BUTTON_LEFT:
			return
		if copy_lbl.get_global_rect().has_point(outer.get_global_mouse_position()):
			DisplayServer.clipboard_set('material.set_shader_parameter("%s", value)' % param_name)
		else:
			if _selected_param_row and is_instance_valid(_selected_param_row):
				_selected_param_row.set_meta("selected", false)
				_selected_param_row.get_meta("apply_style").call(false)
			_selected_param_row = outer
			outer.set_meta("selected", true)
			_apply_style.call(false)
			_show_param_detail(node)
		outer.accept_event()
	)

	outer.set_meta("apply_style", _apply_style)
	return outer


func _show_param_detail(node: Node) -> void:
	if not _detail_vbox:
		return
	for child in _detail_vbox.get_children():
		child.queue_free()

	var param_name: String = node.call("get_param_name") if node.has_method("get_param_name") else node.name

	var name_lbl := Label.new()
	name_lbl.text = param_name
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color("#4AAF78"))
	name_lbl.add_theme_constant_override("margin_left", 10)
	_detail_vbox.add_child(name_lbl)

	if node.has_method("get_blackboard_control"):
		var ctrl := node.call("get_blackboard_control")
		if ctrl:
			var wrap := HBoxContainer.new()
			wrap.add_theme_constant_override("separation", 0)
			ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			wrap.add_child(ctrl)
			_detail_vbox.add_child(wrap)

	_detail_vbox.visible = true
	_detail_sep.visible = true
