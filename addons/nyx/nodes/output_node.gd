@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

const _SPATIAL_MODES := ["", "blend_mix", "blend_add", "blend_premul_alpha"]
const _CANVAS_MODES := ["", "unshaded", "light_only", "blend_add", "blend_premul_alpha"]

const _SPATIAL_LABELS := ["Albedo", "Alpha", "Roughness", "Metallic", "Emission", "Normal", "Vertex Offset"]
const _CANVAS_LABELS := ["Color", "Alpha", "Normal Map", "", "", "", ""]

var _mode: int = 0
var _shader_type: int = 0
var _option_btn: OptionButton
var _slot_labels: Array = []


func _add_preview_controls() -> void:
	pass


func _ready() -> void:
	super._ready()
	title = "Output"
	var vec3_color := _type_color(0)
	var float_color := _type_color(1)

	set_slot(0, true, 0, vec3_color, false, -1, vec3_color)
	set_slot(1, true, 1, float_color, false, -1, float_color)
	set_slot(2, true, 1, float_color, false, -1, float_color)
	set_slot(3, true, 1, float_color, false, -1, float_color)
	set_slot(4, true, 0, vec3_color, false, -1, vec3_color)
	set_slot(5, true, 0, vec3_color, false, -1, vec3_color)
	set_slot(6, true, 0, vec3_color, false, -1, vec3_color)

	for label_text in _SPATIAL_LABELS:
		var label := Label.new()
		label.text = label_text
		add_child(label)
		_slot_labels.append(label)

	_option_btn = OptionButton.new()
	_option_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_option_btn.item_selected.connect(_on_mode_selected)
	add_child(_option_btn)

	_rebuild_mode_options()


func _on_mode_selected(idx: int) -> void:
	emit_signal("edit_started")
	_mode = idx
	emit_signal("value_changed")


func set_shader_type(type: int) -> void:
	_shader_type = type
	_mode = 0
	var vec3_color := _type_color(0)
	var float_color := _type_color(1)

	if type == 0:
		# Spatial
		set_slot(0, true, 0, vec3_color, false, -1, vec3_color)
		set_slot(1, true, 1, float_color, false, -1, float_color)
		set_slot(2, true, 1, float_color, false, -1, float_color)
		set_slot(3, true, 1, float_color, false, -1, float_color)
		set_slot(4, true, 0, vec3_color, false, -1, vec3_color)
		set_slot(5, true, 0, vec3_color, false, -1, vec3_color)
		set_slot(6, true, 0, vec3_color, false, -1, vec3_color)
		for i in range(_slot_labels.size()):
			_slot_labels[i].text = _SPATIAL_LABELS[i]
			_slot_labels[i].visible = true
	else:
		# CanvasItem
		set_slot(0, true, 0, vec3_color, false, -1, vec3_color)
		set_slot(1, true, 1, float_color, false, -1, float_color)
		set_slot(2, true, 0, vec3_color, false, -1, vec3_color)
		set_slot(3, false, -1, vec3_color, false, -1, vec3_color)
		set_slot(4, false, -1, vec3_color, false, -1, vec3_color)
		set_slot(5, false, -1, vec3_color, false, -1, vec3_color)
		set_slot(6, false, -1, vec3_color, false, -1, vec3_color)
		for i in range(_slot_labels.size()):
			_slot_labels[i].text = _CANVAS_LABELS[i]
			_slot_labels[i].visible = _CANVAS_LABELS[i] != ""

	_rebuild_mode_options()
	call_deferred("reset_size")
	emit_signal("value_changed")


func _rebuild_mode_options() -> void:
	_option_btn.clear()
	if _shader_type == 0:
		for label in ["Opaque", "Mix", "Add", "Premult Alpha"]:
			_option_btn.add_item(label)
	else:
		for label in ["Default", "Unshaded", "Light Only", "Blend Add", "Blend Premult"]:
			_option_btn.add_item(label)
	_option_btn.selected = _mode


func get_render_mode() -> String:
	var modes := _SPATIAL_MODES if _shader_type == 0 else _CANVAS_MODES
	return modes[_mode] if _mode < modes.size() else ""


func get_state() -> Dictionary:
	return {"mode": _mode, "shader_type": _shader_type}


func set_state(state: Dictionary) -> void:
	# Restore slot config first (set_shader_type rebuilds the mode dropdown and
	# resets _mode), then apply the saved render mode. Particle mode (2) keeps the
	# OutputNode in its prior spatial/canvas config since it isn't the active sink.
	var st: int = state.get("shader_type", 0)
	if st <= 1 and st != _shader_type:
		set_shader_type(st)
	_mode = state.get("mode", 0)
	_option_btn.selected = _mode


func _on_hover_exit() -> void:
	if selected:
		return
	_body_style.border_color = Color("#1A1A26")
	_titlebar_style.border_color = Color("#1A1A26")


func _on_deselected() -> void:
	var hovered := get_global_rect().has_point(get_global_mouse_position())
	var c := Color("#31614F") if hovered else Color("#1A1A26")
	_body_style.border_color = c
	_titlebar_style.border_color = c
	queue_redraw()


func _apply_style() -> void:
	var color := Color(0.14, 0.14, 0.18)
	var border := Color("#1A1A26")

	var body := StyleBoxFlat.new()
	body.bg_color = color
	body.corner_radius_top_left = 0
	body.corner_radius_top_right = 0
	body.corner_radius_bottom_left = 12
	body.corner_radius_bottom_right = 6
	body.expand_margin_top = 2
	body.border_width_left = 1
	body.border_width_right = 1
	body.border_width_bottom = 1
	body.border_color = border
	body.content_margin_left = 2
	body.content_margin_right = 2
	body.content_margin_bottom = 6
	add_theme_stylebox_override("panel", body)
	add_theme_constant_override("separation", 4)

	var titlebar := StyleBoxFlat.new()
	titlebar.bg_color = color
	titlebar.corner_radius_top_left = 6
	titlebar.corner_radius_top_right = 12
	titlebar.corner_radius_bottom_left = 0
	titlebar.corner_radius_bottom_right = 0
	titlebar.border_width_left = 1
	titlebar.border_width_right = 1
	titlebar.border_width_top = 1
	titlebar.border_color = border
	titlebar.content_margin_left = 7
	titlebar.content_margin_top = 3
	titlebar.content_margin_bottom = -1
	add_theme_stylebox_override("titlebar", titlebar)

	_apply_selection_style(body, titlebar)
	add_theme_icon_override("port", _create_port_texture(10, 1))
	if not mouse_entered.is_connected(_on_hover_enter):
		mouse_entered.connect(_on_hover_enter)
		mouse_exited.connect(_on_hover_exit)
	call_deferred("_center_title")
