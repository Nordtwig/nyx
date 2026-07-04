@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _color := Color.WHITE
var _param_mode: bool = false
var _param_name: String = ""
var _popup: PopupPanel
var _picker: ColorPicker


func _ready() -> void:
	super._ready()
	title = "Color"

	var click_area := Control.new()
	click_area.custom_minimum_size = Vector2(_s(120), _s(48))
	click_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	click_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	click_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click_area.gui_input.connect(_on_clicked)
	add_child(click_area)

	# PopupPanel (not bare Popup): the bare Popup dismissed inconsistently in the
	# embedded editor — it took two clicks to close. PopupPanel matches every other
	# popup in Nyx (search/doc/relay) and closes on the first outside click.
	_popup = PopupPanel.new()
	add_child(_popup)

	_picker = ColorPicker.new()
	_picker.color = _color
	_picker.custom_minimum_size = Vector2(_s(240), 0)
	# Trim the bulky sections — keep the picker square, sliders and hex field.
	_picker.presets_visible = false
	_picker.can_add_swatches = false
	_picker.sampler_visible = false
	_picker.color_modes_visible = false
	_picker.color_changed.connect(_on_color_changed)
	_popup.add_child(_picker)

	set_slot(0, false, -1, _type_color(0), true, 3, _type_color(3))
	_apply_node_color()

	call_deferred("_init_default_param_name")


func _init_default_param_name() -> void:
	if _param_name == "":
		_param_name = "color_" + str(name).to_lower()


func _on_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("edit_started")
		inspector_requested.emit(self)


func _on_color_changed(color: Color) -> void:
	_color = color
	_apply_node_color()
	value_changed.emit()


func get_color() -> Color:
	return _color


# Counterpart to get_color() — the node-inspector popup calls this on every
# ColorPicker drag, since Color is a plain Variant with no shared .changed
# signal (unlike Curve/Gradient) to propagate edits back automatically.
func set_color_from_inspector(c: Color) -> void:
	_picker.color = c  # keep the Blackboard-triggered local picker in sync too
	_on_color_changed(c)


func set_param_mode(v: bool) -> void:
	_param_mode = v
	value_changed.emit()


func set_param_name(n: String) -> void:
	_param_name = n
	value_changed.emit()


func _apply_node_color() -> void:
	_apply_body_color(_color)


func _update_title_color() -> void:
	_apply_luminance_title_color(_color)


func _add_preview_controls() -> void:
	pass


func get_uniform_declaration() -> String:
	if not _param_mode:
		return ""
	return "uniform vec4 %s : source_color;" % _param_name


func get_shader_snippet(inputs: Array = []) -> String:
	if _param_mode:
		return _param_name
	return "vec4(%.4f, %.4f, %.4f, %.4f)" % [_color.r, _color.g, _color.b, _color.a]


func apply_shader_params(material: ShaderMaterial) -> void:
	if _param_mode:
		material.set_shader_parameter(_param_name, _color)


func get_param_export_line() -> String:
	if not _param_mode:
		return ""
	return "shader_parameter/%s = Color(%.4f, %.4f, %.4f, %.4f)" % [
		_param_name, _color.r, _color.g, _color.b, _color.a
	]


func get_state() -> Dictionary:
	return {
		"color": [_color.r, _color.g, _color.b, _color.a],
		"param_mode": _param_mode,
		"param_name": _param_name,
	}


func set_state(state: Dictionary) -> void:
	var c: Array = state["color"]
	_color = Color(c[0], c[1], c[2], c[3])
	_picker.color = _color
	_apply_node_color()
	var pname = state.get("param_name", "")
	if pname != "":
		_param_name = pname
	_param_mode = state.get("param_mode", false)


func is_param_mode() -> bool:
	return _param_mode


func get_param_name() -> String:
	return _param_name


func open_picker() -> void:
	emit_signal("edit_started")
	_popup.reset_size()
	var pos := get_screen_position() + Vector2(0, size.y)
	_popup.popup(Rect2(pos, _popup.size))


func get_blackboard_control() -> Control:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, _s(32))
	var _refresh := func() -> void:
		var s := StyleBoxFlat.new()
		s.bg_color = _color
		s.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", s)
		var sh := StyleBoxFlat.new()
		sh.bg_color = _color.lightened(0.1)
		sh.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("hover", sh)
		btn.add_theme_stylebox_override("pressed", sh)
		btn.add_theme_stylebox_override("focus", s)
	_refresh.call()
	btn.pressed.connect(func() -> void: open_picker())
	value_changed.connect(func() -> void: _refresh.call())
	return btn


func get_vector_semantic() -> String:
	return "color"
