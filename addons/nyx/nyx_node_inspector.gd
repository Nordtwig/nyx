@tool
extends Control

## Nyx node-inspector popup — Step 1–3 shell, wired to Curve + Gradient + Color.
##
## Transient overlay, mirroring nyx_search_popup.gd's pattern (built/positioned fresh
## on each open, backdrop dismiss-on-click-away) rather than the persistent floating-
## panel pattern (nyx_preview_panel.gd / nyx_properties_panel.gd / nyx_tool_rail.gd).
## This popup opens/closes constantly and repositions per node, so it has no
## place_default/reanchor/is_placed state to carry across the session.
##
## Content mechanism: embeds a real EditorInspector via .edit(resource), which pulls
## in Godot's specialized editor widgets (CurveEditor, etc.) via the engine's static
## inspector-plugin registry — confirmed working in the 2026-07-02 feasibility spike.
## .edit() populates its tree deferred, so curation (keep the specialized widget,
## hide the generic property dump) waits a couple frames before walking the tree.
##
## Color is a plain Variant, not a Resource — it gets a plain ColorPicker embed
## instead of the EditorInspector mechanism, in the same shell.
##
## The meta section (permanent header of the card) is generic, independent of
## which content mechanism (EditorInspector / ColorPicker) is showing below it.
## Two distinct fields, deliberately not conflated:
##   - Label: a cosmetic, organizational rename of the node's display `title`
##     (Blender-style node renaming — readability in dense graphs, nothing to
##     do with shaders).
##   - Parameter: whether this node's value is exposed as a shader uniform +
##     its export name — the old inline "$" button + name field some node
##     bodies used to carry (Color/Float/Vector3). Duck-typed on the anchor
##     via is_param_mode()/get_param_name()/set_param_mode()/set_param_name(),
##     so it only shows for nodes that actually support it.
##
## See memory/project_properties_panel.md for the full design + staged build plan.
## The universal double-click/cog trigger (reaching node types with no inspector
## content yet) is still Step 5; this popup only opens via the existing Curve/
## Gradient/Color content-click triggers for now. Float/Vector3 still carry their
## OLD inline param controls — they have no trigger to open this popup yet, so
## migrating them off the body happens together with wiring their Step 5 trigger.

var _graph_container: Control
var _card: PanelContainer
var _card_vbox: VBoxContainer
var _header: Label
var _node_settings_label: Label
var _name_edit: LineEdit
var _param_check: CheckBox
var _param_name_field: LineEdit
var _param_range_box: VBoxContainer
var _param_min_spin: SpinBox
var _param_max_spin: SpinBox
var _param_step_spin: SpinBox
var _meta_separator: HSeparator
var _inspector: EditorInspector
var _color_picker: ColorPicker
var _sink_content: VBoxContainer
var _current_anchor: Control
var _updating_name: bool = false
var _updating_param: bool = false


func setup(container: Control) -> void:
	_graph_container = container
	_build()


func _build() -> void:
	visible = false
	position = Vector2.ZERO
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var backdrop := Control.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			close()
			# Re-inject the same click into the viewport for a fresh dispatch
			# pass now that we're hidden, so it reaches whatever's actually
			# underneath (GraphEdit's own click-to-select/deselect, another
			# node's cog/body) instead of being eaten entirely by this
			# backdrop. MOUSE_FILTER_PASS does NOT do this — it only bubbles
			# to this control's own parent chain (backdrop → this popup →
			# nyx_main), never sideways to GraphEdit, a separate sibling
			# branch of the tree — confirmed by testing, not just docs.
			var vp := get_viewport()
			# A synthetic motion first: Godot's native Button hover visual
			# (icon_hover_color) only ever engages from a real mouse_entered,
			# which needs an actual motion event to have reached that point.
			# Without this, a re-pushed press alone lands on e.g. another
			# node's cog having never been "hovered" in Godot's own tracking,
			# so it jumps straight from resting grey to pressed green instead
			# of passing through the hover state a real approach-then-click
			# would show.
			var motion := InputEventMouseMotion.new()
			motion.position = e.global_position
			motion.global_position = e.global_position
			vp.push_input(motion)
			var repushed := e.duplicate()
			repushed.position = e.global_position
			vp.push_input(repushed))
	add_child(backdrop)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.14, 0.14, 0.18, 0.92)
	card_style.border_color = Color(0.24, 0.24, 0.30)
	card_style.set_border_width_all(1)
	card_style.corner_radius_top_left = 6
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 6
	card_style.set_content_margin_all(8)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(260, 0)
	_card.add_theme_stylebox_override("panel", card_style)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP

	_card_vbox = VBoxContainer.new()
	_card_vbox.add_theme_constant_override("separation", 6)

	_header = Label.new()
	_header.add_theme_color_override("font_color", Color("#6BCF96"))
	_header.add_theme_font_size_override("font_size", 11)
	_card_vbox.add_child(_header)

	_node_settings_label = _build_section_label("Node Settings")
	_card_vbox.add_child(_node_settings_label)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Label"
	_style_line_edit(_name_edit)
	_name_edit.text_changed.connect(_on_name_changed)
	_card_vbox.add_child(_name_edit)

	_param_check = CheckBox.new()
	_param_check.text = "Shader parameter"
	_param_check.add_theme_color_override("font_color", Color(0.85, 0.85, 0.90))
	_param_check.toggled.connect(_on_param_toggled)
	_card_vbox.add_child(_param_check)

	_param_name_field = LineEdit.new()
	_param_name_field.placeholder_text = "param name"
	_style_line_edit(_param_name_field)
	_param_name_field.visible = false
	_param_name_field.text_changed.connect(_on_param_name_changed)
	_card_vbox.add_child(_param_name_field)

	# Range editor for the exported uniform's hint_range (Float only; shown when
	# param mode is on). min/max/step author the slider the material Inspector
	# draws. Plain SpinBoxes so min/max can be any value (unlike an
	# EditorSpinSlider, which is itself a bounded control).
	_param_range_box = VBoxContainer.new()
	_param_range_box.add_theme_constant_override("separation", 2)
	_param_range_box.visible = false
	_param_min_spin = _build_param_range_spin("Slider min", _on_param_range_changed)
	_param_max_spin = _build_param_range_spin("Slider max", _on_param_range_changed)
	_param_step_spin = _build_param_range_spin("Slider step", _on_param_range_changed)
	_card_vbox.add_child(_param_range_box)

	_meta_separator = HSeparator.new()
	var meta_sep_style := StyleBoxLine.new()
	meta_sep_style.color = Color(0.22, 0.22, 0.28)
	meta_sep_style.thickness = 1
	_meta_separator.add_theme_stylebox_override("separator", meta_sep_style)
	# Only shown when something actually follows it — a meta-only popup (no
	# Curve/Gradient/Color/sink content) would otherwise dangle a divider with
	# nothing below it, and open_for_sink hides Label/Parameter above it so a
	# permanently-visible separator would float right under the header with
	# nothing meaningful to divide from.
	_meta_separator.visible = false
	_card_vbox.add_child(_meta_separator)

	_card.add_child(_card_vbox)
	add_child(_card)


func _build_section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
	return lbl


func _style_line_edit(le: LineEdit) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.20, 0.20, 0.26)
	normal.border_color = Color(0.35, 0.35, 0.45)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5

	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = Color("#31614F")

	le.add_theme_stylebox_override("normal", normal)
	le.add_theme_stylebox_override("focus", focus)
	le.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))


func open_for_resource(resource: Resource, title_text: String, anchor: Control) -> void:
	_clear_content()
	_open_meta_for(title_text, anchor)
	_meta_separator.visible = true

	_inspector = EditorInspector.new()
	_inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# EditorInspector is itself a ScrollContainer in the engine, which never
	# propagates its children's minimum size upward (by design — a scroll
	# container's content can always be taller than its own rect). Without an
	# explicit minimum height here, the inspector collapses to ~0px and the
	# curated specialized widget (CurveEditor/GradientEditor) never gets laid
	# out, even though it's visible.
	_inspector.custom_minimum_size = Vector2(0, 260)
	_inspector.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_card_vbox.add_child(_inspector)
	_inspector.edit(resource)

	size = _graph_container.size
	visible = true
	move_to_front()
	_card.reset_size()
	_position_near(anchor)

	# .edit() builds its tree deferred — wait a couple frames before curating.
	await get_tree().process_frame
	await get_tree().process_frame
	_curate_inspector()
	_card.reset_size()
	_position_near(anchor)


# Color is a plain Variant (not a Resource), so there's no shared object whose
# .changed signal can propagate edits back to the node the way Curve/Gradient do.
# get_color/set_color are Callables into the node instead — set_color is invoked
# live on every ColorPicker drag, mirroring the node's own former inline picker.
func open_for_color(get_color: Callable, set_color: Callable, title_text: String, anchor: Control) -> void:
	_clear_content()
	_open_meta_for(title_text, anchor)
	_meta_separator.visible = true

	_color_picker = ColorPicker.new()
	_color_picker.color = get_color.call()
	_color_picker.custom_minimum_size = Vector2(240, 0)
	_color_picker.presets_visible = false
	_color_picker.can_add_swatches = false
	_color_picker.sampler_visible = false
	_color_picker.color_modes_visible = false
	_color_picker.color_changed.connect(func(c: Color): set_color.call(c))
	_card_vbox.add_child(_color_picker)

	size = _graph_container.size
	visible = true
	move_to_front()
	_card.reset_size()
	_position_near(anchor)


# Fallback for node types with no type-specific content mechanism (no Curve/
# Gradient resource, no Color) — just the meta section (Label + Parameter if
# the anchor supports it). Used by the Step 5 universal trigger so every node
# can at least be renamed / turned into a shader parameter.
func open_meta_only(title_text: String, anchor: Control) -> void:
	_clear_content()
	_open_meta_for(title_text, anchor)
	_meta_separator.visible = false

	size = _graph_container.size
	visible = true
	move_to_front()
	_card.reset_size()
	_position_near(anchor)


# Graph Settings (Shader Type + Render Mode) — true graph-wide state, not
# per-instance meta like Label/Parameter, so this bypasses _open_meta_for
# entirely (a fixed structural sink isn't meaningfully "renamed" or turned
# into a shader parameter). shader_type_setter/render_mode_setter are
# Callables so every sink (Output/Vertex Output/particle sinks) reads and
# writes the SAME shared state regardless of which one's popup is open —
# render_mode in particular is only ever really owned by the one OutputNode,
# not whichever sink the user happened to click.
func open_for_sink(title_text: String, anchor: Control, shader_type: int,
		has_render_mode: bool, render_mode: int, render_mode_labels: Array,
		shader_type_setter: Callable, render_mode_setter: Callable,
		preview_horizontal: bool, preview_subdivisions: int, preview_scale: float,
		preview_horizontal_setter: Callable, preview_subdivisions_setter: Callable,
		preview_scale_setter: Callable) -> void:
	_clear_content()
	_set_current_anchor(anchor)
	_header.text = title_text
	_node_settings_label.visible = false
	_name_edit.visible = false
	_param_check.visible = false
	_param_name_field.visible = false
	_param_range_box.visible = false
	# No Label/Parameter content sits above it here, so the separator would
	# just be an orphaned line between the header and the settings — same
	# reasoning as open_meta_only.
	_meta_separator.visible = false

	_sink_content = VBoxContainer.new()
	_sink_content.add_theme_constant_override("separation", 6)
	_sink_content.add_child(_build_section_label("Graph Settings"))

	_sink_content.add_child(_build_dropdown_row(
		"Shader Type", ["Spatial", "Canvas Item", "Particles"], shader_type, shader_type_setter))
	if has_render_mode:
		_sink_content.add_child(_build_dropdown_row(
			"Render Mode", render_mode_labels, render_mode, render_mode_setter))

	# Preview Mesh: only meaningful in Spatial mode — Canvas Item uses the flat
	# 2D viewport and Particles reuses the 3D viewport without the mesh
	# switcher at all, so there's no mesh here for these settings to affect.
	if shader_type == 0:
		_sink_content.add_child(_build_section_label("Preview Mesh"))
		_sink_content.add_child(_build_dropdown_row(
			"Plane Orientation", ["Horizontal (Floor)", "Vertical (Wall)"],
			0 if preview_horizontal else 1,
			func(idx: int): preview_horizontal_setter.call(idx == 0)))
		_sink_content.add_child(_build_spin_row(
			"Scale", preview_scale, 0.1, 20.0, 0.1, preview_scale_setter))
		_sink_content.add_child(_build_spin_row(
			"Subdivisions", preview_subdivisions, 1, 256, 1,
			func(v: float): preview_subdivisions_setter.call(int(round(v)))))

	_card_vbox.add_child(_sink_content)

	size = _graph_container.size
	visible = true
	move_to_front()
	_card.reset_size()
	_position_near(anchor)


func _build_dropdown_row(label_text: String, items: Array, current: int, on_select: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 90
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.83, 0.88))
	row.add_child(lbl)

	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.add_theme_font_size_override("font_size", 10)
	for item in items:
		opt.add_item(item)
	opt.selected = current
	opt.item_selected.connect(on_select)
	row.add_child(opt)

	return row


# EditorSpinSlider draws its own internal label (unlike the OptionButton row
# above, which needs an external Label) — no wrapper row needed, matches the
# same slider style used inline on node bodies (e.g. fbm_node.gd).
func _build_spin_row(label_text: String, value: float, min_v: float, max_v: float,
		step: float, on_change: Callable) -> Control:
	var slider := EditorSpinSlider.new()
	slider.label = label_text
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.add_theme_font_size_override("font_size", 10)
	slider.value_changed.connect(on_change)
	return slider


# Shared by the resource/color content mechanisms: sets the category label,
# points the Label field at the anchor node's current display title, shows/
# fills the Parameter section if the anchor supports it, and remembers the
# anchor as the write target. Not used by open_for_sink (see above).
func _open_meta_for(title_text: String, anchor: Control) -> void:
	_set_current_anchor(anchor)
	_header.text = title_text
	_node_settings_label.visible = true
	_name_edit.visible = true
	_updating_name = true
	_name_edit.text = anchor.title
	_updating_name = false

	var supports_param: bool = anchor.has_method("is_param_mode")
	_param_check.visible = supports_param
	var supports_range: bool = supports_param and anchor.has_method("has_param_range") and anchor.has_param_range()
	if supports_param:
		_updating_param = true
		_param_check.button_pressed = anchor.is_param_mode()
		_param_name_field.text = anchor.get_param_name()
		if supports_range:
			_param_min_spin.value = anchor.get_param_min()
			_param_max_spin.value = anchor.get_param_max()
			_param_step_spin.value = anchor.get_param_step()
		_updating_param = false
		_param_name_field.visible = anchor.is_param_mode()
		_param_range_box.visible = supports_range and anchor.is_param_mode()
	else:
		_param_name_field.visible = false
		_param_range_box.visible = false


func _on_name_changed(new_text: String) -> void:
	if _updating_name or not is_instance_valid(_current_anchor):
		return
	_current_anchor.title = new_text
	_current_anchor.emit_signal("value_changed")


func _on_param_toggled(pressed: bool) -> void:
	if _updating_param or not is_instance_valid(_current_anchor):
		return
	_current_anchor.set_param_mode(pressed)
	_param_name_field.visible = pressed
	var supports_range: bool = _current_anchor.has_method("has_param_range") and _current_anchor.has_param_range()
	_param_range_box.visible = pressed and supports_range
	_card.reset_size()
	_position_near(_current_anchor)


func _on_param_name_changed(new_text: String) -> void:
	if _updating_param or not is_instance_valid(_current_anchor):
		return
	_current_anchor.set_param_name(new_text)


# One "label + SpinBox" row for the param range editor, added to _param_range_box.
# Plain SpinBox (not EditorSpinSlider) so min/max/step can be any value.
func _build_param_range_spin(label_text: String, on_change: Callable) -> SpinBox:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 90
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.83, 0.88))
	row.add_child(lbl)

	var spin := SpinBox.new()
	spin.min_value = -1e9
	spin.max_value = 1e9
	spin.step = 0.0001
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(func(_v: float): on_change.call())
	row.add_child(spin)

	_param_range_box.add_child(row)
	return spin


func _on_param_range_changed() -> void:
	if _updating_param or not is_instance_valid(_current_anchor):
		return
	if _current_anchor.has_method("set_param_range"):
		_current_anchor.set_param_range(
			_param_min_spin.value, _param_max_spin.value, _param_step_spin.value)


# Centralizes _current_anchor writes so the "this node's popup is open" flag
# (which pins its cog visible — see nyx_node.gd's set_inspector_popup_open)
# always gets cleared on the outgoing anchor and set on the incoming one,
# regardless of which open_* method is switching to it.
func _set_current_anchor(anchor: Control) -> void:
	if is_instance_valid(_current_anchor) and _current_anchor.has_method("set_inspector_popup_open"):
		_current_anchor.set_inspector_popup_open(false)
	_current_anchor = anchor
	if is_instance_valid(_current_anchor) and _current_anchor.has_method("set_inspector_popup_open"):
		_current_anchor.set_inspector_popup_open(true)


# Lets the trigger dispatch (nyx_main.gd) tell an already-open request on the
# same node apart from a fresh one, so pressing the cog / double-clicking a
# node whose popup is already open closes it instead of just re-opening it.
func is_open_for(node: Control) -> bool:
	return visible and _current_anchor == node


# Non-modal naming for a freshly-spawned parameter node (see nyx_main.gd's
# _on_quick_add_chosen / the "Connection-drop node spawn" design): focuses
# and pre-selects the param name field so typing replaces the guessed
# default, while Enter/click-away simply keeps it - never a blocking prompt.
func focus_param_name() -> void:
	if _param_name_field.visible:
		_param_name_field.grab_focus()
		_param_name_field.select_all()


func close() -> void:
	visible = false
	# No explicit hover resync needed here — nyx_node.gd's base _process() is a
	# standing per-frame correctness backstop for exactly this case (popup
	# covered the node, no further mouse motion for signals to recompute on).
	if is_instance_valid(_current_anchor) and _current_anchor.has_method("set_inspector_popup_open"):
		_current_anchor.set_inspector_popup_open(false)
	_current_anchor = null
	_clear_content()


func handle_resize() -> void:
	if visible:
		size = _graph_container.size


func _clear_content() -> void:
	if _inspector:
		_inspector.queue_free()
		_inspector = null
	if _color_picker:
		_color_picker.queue_free()
		_color_picker = null
	if _sink_content:
		_sink_content.queue_free()
		_sink_content = null


func _position_near(anchor: Control) -> void:
	if not is_instance_valid(anchor):
		return
	var anchor_global := anchor.get_global_rect()
	var to_local := _graph_container.get_global_transform().affine_inverse()
	var anchor_pos := to_local * anchor_global.position
	var anchor_size := anchor_global.size  # zoom-scaled already; no further transform needed
	var card_size := _card.size
	var gap := 8.0

	var pos := Vector2(anchor_pos.x + anchor_size.x + gap, anchor_pos.y)
	if pos.x + card_size.x > _graph_container.size.x:
		pos.x = anchor_pos.x - card_size.x - gap
	pos.x = clampf(pos.x, 0.0, maxf(_graph_container.size.x - card_size.x, 0.0))
	pos.y = clampf(pos.y, 0.0, maxf(_graph_container.size.y - card_size.y, 0.0))
	_card.position = pos


# Keeps the specialized widget (e.g. CurveEditor) and hides the generic property
# dump underneath it. The spike found a consistent shape: the built EditorInspector
# contains a VBoxContainer with the specialized widget as its first child and the
# generic category/property rows after it. Walk down to the first VBoxContainer
# with more than one child and apply that rule.
func _curate_inspector() -> void:
	if not _inspector:
		return
	var content := _find_content_container(_inspector)
	if content == null:
		return
	var children := content.get_children()
	for i in range(children.size()):
		if children[i] is Control:
			children[i].visible = (i == 0)


func _find_content_container(node: Node) -> Node:
	for child in node.get_children():
		if child is VBoxContainer and child.get_child_count() > 1:
			return child
		var found := _find_content_container(child)
		if found:
			return found
	return null
