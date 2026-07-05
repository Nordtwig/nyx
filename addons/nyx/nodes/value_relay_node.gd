@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _color: Color = Color(0.14, 0.14, 0.18, 0.95)
var _readout_label: Label


func _ready() -> void:
	_node_color = _color
	super._ready()
	title = "Value"

	set_slot(0, true, 0, _type_color(0), true, 0, _type_color(0))

	_readout_label = Label.new()
	_readout_label.text = "—"
	_readout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	_readout_label.add_theme_font_size_override("font_size", 10)
	add_child(_readout_label)

	_apply_node_color()


# No swatch/chevron preview — Value Relay shows a raw numeric readout instead
# (see nyx_value_relay_previews.gd), driven by set_value_readout_text() below.
func _add_preview_controls() -> void:
	pass


const _NORMAL_COLOR := Color(0.55, 0.55, 0.6)
const _CAVEAT_COLOR := Color("#D4A017")  # same amber as the chrome bar's dirty-state — "real but worth a second look"


# `caveat` covers two distinct cases the manager can't fully separate at this
# call site: a genuinely unavailable value (spatial-only dependency) and a
# real value that's only accurate at this readback's own reference coordinate
# (UV/Screen UV) rather than necessarily the point being inspected. Both read
# as "don't take this number completely at face value," hence one flag — the
# caller passes the specific explanation as a tooltip rather than in the label
# text itself, which stays short enough to actually fit the node.
func set_value_readout_text(text: String, caveat: bool = false, tooltip: String = "") -> void:
	if not _readout_label:
		return
	_readout_label.text = text
	_readout_label.add_theme_color_override("font_color", _CAVEAT_COLOR if caveat else _NORMAL_COLOR)
	_readout_label.tooltip_text = tooltip


func _on_color_changed(color: Color) -> void:
	_color = color
	_node_color = color
	_apply_node_color()
	emit_signal("value_changed")


func get_color() -> Color:
	return _color


# Counterpart to get_color() — the node-inspector popup calls this on every
# ColorPicker drag (see color_node.gd for why this Callable pair exists).
func set_color_from_inspector(c: Color) -> void:
	_on_color_changed(c)


func _apply_node_color() -> void:
	_apply_body_color(_color)


func _update_title_color() -> void:
	_apply_luminance_title_color(_color)


func is_polymorphic() -> bool:
	return true


func get_output_type(from_port: int, input_types: Array) -> int:
	return input_types[0] if not input_types.is_empty() else 0


func get_default_input_types() -> Array:
	return [0]


func get_output_snippet(port: int, inputs: Array = []) -> String:
	return inputs[0] if not inputs.is_empty() else "vec3(0.0)"


func get_shader_snippet(inputs: Array = []) -> String:
	return inputs[0] if not inputs.is_empty() else "vec3(0.0)"


func get_default_inputs() -> Array:
	return ["vec3(0.0)"]


func get_state() -> Dictionary:
	return {
		"custom_name": title,
		"color": [_color.r, _color.g, _color.b, _color.a],
	}


func set_state(state: Dictionary) -> void:
	title = state.get("custom_name", "Value")
	var c = state.get("color")
	if c is Array and c.size() >= 4:
		_color = Color(c[0], c[1], c[2], c[3])
		_node_color = _color
	_apply_node_color()
