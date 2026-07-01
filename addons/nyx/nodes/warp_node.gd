@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _strength: float = 0.1
var _strength_slider: EditorSpinSlider


func _ready() -> void:
	super._ready()
	title = "Warp"

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

	var offset_lbl := Label.new()
	offset_lbl.text = "Offset"
	add_child(offset_lbl)

	_strength_slider = EditorSpinSlider.new()
	_strength_slider.label = "Strength"
	_strength_slider.min_value = 0.0
	_strength_slider.max_value = 2.0
	_strength_slider.step = 0.001
	_strength_slider.value = _strength
	_strength_slider.custom_minimum_size = Vector2(_s(80), 0)
	_strength_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_strength_slider.value_changed.connect(func(v: float): _strength = v; emit_signal("value_changed"))
	add_child(_strength_slider)

	set_slot(0, true, 0, _type_color(0), true, 0, _type_color(0))
	set_slot(1, true, 0, _type_color(0), false, -1, _type_color(0))
	set_slot(2, true, 1, float_color, false, -1, _type_color(0))


func get_shader_snippet(inputs: Array = []) -> String:
	return "vec3((%s).xy + (%s).xy * %s, 0.0)" % [inputs[0], inputs[1], inputs[2]]


func get_default_inputs() -> Array:
	return ["vec3(UV, 0.0)", "vec3(0.0)", "%.4f" % _strength]


func get_state() -> Dictionary:
	return {"strength": _strength}


func set_state(state: Dictionary) -> void:
	_strength = state.get("strength", 0.1)
	_strength_slider.value = _strength
