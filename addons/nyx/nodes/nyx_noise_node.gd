@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _scale: float = 5.0
var _scale_slider: EditorSpinSlider


func _ready() -> void:
	super._ready()

	var float_color := _type_color(1)

	var row0 := HBoxContainer.new()
	var uv_lbl := Label.new()
	uv_lbl.text = "UV"
	uv_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row0.add_child(uv_lbl)
	var noise_lbl := Label.new()
	noise_lbl.text = "Noise"
	row0.add_child(noise_lbl)
	add_child(row0)

	_scale_slider = EditorSpinSlider.new()
	_scale_slider.label = "Scale"
	_scale_slider.min_value = 0.1
	_scale_slider.max_value = 50.0
	_scale_slider.step = 0.1
	_scale_slider.value = _scale
	_scale_slider.custom_minimum_size = Vector2(_s(80), 0)
	_scale_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scale_slider.value_changed.connect(_on_scale_changed)
	add_child(_scale_slider)

	set_slot(0, true, 0, _type_color(0), true, 1, float_color)
	set_slot(1, true, 1, float_color, false, -1, float_color)


func _on_scale_changed(val: float) -> void:
	_scale = val
	value_changed.emit()


func get_default_inputs() -> Array:
	return ["vec3(UV, 0.0)", "%.2f" % _scale]


func get_param_range_hint(port: int) -> Array:
	if port == 1:
		return [0.1, 50.0, 0.1]
	return []


func get_state() -> Dictionary:
	return {"scale": _scale}


func set_state(state: Dictionary) -> void:
	_scale = state.get("scale", 5.0)
	_scale_slider.value = _scale
