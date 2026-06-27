@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _angle: float = 0.0
var _angle_slider: EditorSpinSlider

const _ROTATE_FUNCTION = """vec3 nyx_rotate_uv(vec3 uv, float angle) {
	vec2 c = uv.xy - vec2(0.5);
	float s = sin(angle);
	float cs = cos(angle);
	return vec3(vec2(c.x * cs - c.y * s, c.x * s + c.y * cs) + vec2(0.5), 0.0);
}
"""


func _ready() -> void:
	super._ready()
	title = "Rotate UV"

	var float_color := _type_color(1)

	var row0 := HBoxContainer.new()
	var uv_lbl := Label.new()
	uv_lbl.text = "UV"
	uv_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row0.add_child(uv_lbl)
	var out_lbl := Label.new()
	out_lbl.text = "Out"
	row0.add_child(out_lbl)
	add_child(row0)

	_angle_slider = EditorSpinSlider.new()
	_angle_slider.label = "Angle"
	_angle_slider.min_value = -3.14159
	_angle_slider.max_value = 3.14159
	_angle_slider.step = 0.01
	_angle_slider.value = _angle
	_angle_slider.custom_minimum_size = Vector2(80, 0)
	_angle_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_angle_slider.value_changed.connect(func(v: float): _angle = v; emit_signal("value_changed"))
	add_child(_angle_slider)

	set_slot(0, true, 0, _type_color(0), true, 0, _type_color(0))
	set_slot(1, true, 1, float_color, false, -1, _type_color(0))


func get_shader_snippet(inputs: Array = []) -> String:
	return "nyx_rotate_uv(%s, %s)" % [inputs[0], inputs[1]]


func get_shader_functions() -> Dictionary:
	return {"nyx_rotate_uv": _ROTATE_FUNCTION}


func get_default_inputs() -> Array:
	return ["vec3(UV, 0.0)", "%.4f" % _angle]


func get_state() -> Dictionary:
	return {"angle": _angle}


func set_state(state: Dictionary) -> void:
	_angle = state.get("angle", 0.0)
	_angle_slider.value = _angle
