@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

const _MODES = ["", "blend_mix", "blend_add", "blend_premul_alpha"]

var _mode: int = 0
var _option_btn: OptionButton


func _ready() -> void:
	super._ready()
	title = "Output"
	var vec3_color := Color.WHITE
	var float_color := Color(0.35, 0.9, 0.85)
	set_slot(0, true, 0, vec3_color, false, -1, vec3_color)
	set_slot(1, true, 1, float_color, false, -1, float_color)
	set_slot(2, true, 1, float_color, false, -1, float_color)
	set_slot(3, true, 1, float_color, false, -1, float_color)
	set_slot(4, true, 0, vec3_color, false, -1, vec3_color)
	set_slot(5, true, 0, vec3_color, false, -1, vec3_color)

	for label_text in ["Albedo", "Alpha", "Roughness", "Metallic", "Emission", "Normal"]:
		var label := Label.new()
		label.text = label_text
		add_child(label)

	_option_btn = OptionButton.new()
	_option_btn.add_item("Opaque")
	_option_btn.add_item("Mix")
	_option_btn.add_item("Add")
	_option_btn.add_item("Premult Alpha")
	_option_btn.selected = _mode
	_option_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_option_btn.item_selected.connect(_on_mode_selected)
	add_child(_option_btn)


func _on_mode_selected(idx: int) -> void:
	emit_signal("edit_started")
	_mode = idx
	emit_signal("value_changed")


func get_render_mode() -> String:
	return _MODES[_mode]


func get_state() -> Dictionary:
	return {"mode": _mode}


func set_state(state: Dictionary) -> void:
	_mode = state.get("mode", 0)
	_option_btn.selected = _mode


func _apply_style() -> void:
	var color := Color(0.18, 0.18, 0.22)

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
	body.border_color = Color(0.28, 0.28, 0.35)
	add_theme_stylebox_override("panel", body)

	var titlebar := StyleBoxFlat.new()
	titlebar.bg_color = color
	titlebar.corner_radius_top_left = 6
	titlebar.corner_radius_top_right = 12
	titlebar.corner_radius_bottom_left = 0
	titlebar.corner_radius_bottom_right = 0
	titlebar.border_width_left = 1
	titlebar.border_width_right = 1
	titlebar.border_width_top = 1
	titlebar.border_color = Color(0.28, 0.28, 0.35)
	add_theme_stylebox_override("titlebar", titlebar)

	_apply_selection_style(body, titlebar)
	add_theme_icon_override("port", _create_port_texture(10, 1))
	call_deferred("_center_title")
