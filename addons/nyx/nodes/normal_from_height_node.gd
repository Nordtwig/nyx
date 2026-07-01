@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _strength: float = 8.0
var _strength_slider: EditorSpinSlider

const _FUNCTION = """vec3 nyx_normal_from_height(float h, float strength) {
	vec3 n = normalize(vec3(-dFdx(h) * strength, -dFdy(h) * strength, 1.0));
	return n * 0.5 + 0.5;
}
"""


func _ready() -> void:
	super._ready()
	title = "Normal from Height"

	var float_color := _type_color(1)

	var row0 := HBoxContainer.new()
	var h_lbl := Label.new()
	h_lbl.text = "Height"
	h_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row0.add_child(h_lbl)
	var out_lbl := Label.new()
	out_lbl.text = "Normal"
	row0.add_child(out_lbl)
	add_child(row0)

	_strength_slider = EditorSpinSlider.new()
	_strength_slider.label = "Strength"
	_strength_slider.min_value = 0.1
	_strength_slider.max_value = 100.0
	_strength_slider.step = 0.1
	_strength_slider.value = _strength
	_strength_slider.custom_minimum_size = Vector2(_s(80), 0)
	_strength_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_strength_slider.value_changed.connect(func(v: float): _strength = v; emit_signal("value_changed"))
	add_child(_strength_slider)

	set_slot(0, true, 1, float_color, true, 0, _type_color(0))
	set_slot(1, true, 1, float_color, false, -1, _type_color(0))


func get_shader_snippet(inputs: Array = []) -> String:
	return "nyx_normal_from_height(%s, %s)" % [inputs[0], inputs[1]]


func get_shader_functions() -> Dictionary:
	return {"nyx_normal_from_height": _FUNCTION}


func get_default_inputs() -> Array:
	return ["0.0", "%.4f" % _strength]


func get_state() -> Dictionary:
	return {"strength": _strength}


func set_state(state: Dictionary) -> void:
	_strength = state.get("strength", 8.0)
	_strength_slider.value = _strength
