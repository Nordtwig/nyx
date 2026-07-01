@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _tiling_x: float = 1.0
var _tiling_y: float = 1.0
var _offset_x: float = 0.0
var _offset_y: float = 0.0
var _tiling_slider: EditorSpinSlider
var _tiling_x_slider: EditorSpinSlider
var _tiling_y_slider: EditorSpinSlider
var _offset_x_slider: EditorSpinSlider
var _offset_y_slider: EditorSpinSlider
var _syncing := false


func _ready() -> void:
	super._ready()
	title = "Tiling & Offset"

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

	# Master tiling — no port, sets both X and Y
	_tiling_slider = _make_slider("Tiling", 0.01, 20.0, 0.01, 1.0, _on_tiling_changed)

	_tiling_x_slider = _make_slider("Tiling X", 0.01, 20.0, 0.01, _tiling_x, _on_tiling_x_changed)
	_tiling_y_slider = _make_slider("Tiling Y", 0.01, 20.0, 0.01, _tiling_y, _on_tiling_y_changed)
	_offset_x_slider = _make_slider("Offset X", -10.0, 10.0, 0.001, _offset_x, _on_offset_x_changed)
	_offset_y_slider = _make_slider("Offset Y", -10.0, 10.0, 0.001, _offset_y, _on_offset_y_changed)

	set_slot(0, true, 0, _type_color(0), true, 0, _type_color(0))
	# row 1 = master tiling slider, no port
	set_slot(2, true, 1, float_color, false, -1, _type_color(0))
	set_slot(3, true, 1, float_color, false, -1, _type_color(0))
	set_slot(4, true, 1, float_color, false, -1, _type_color(0))
	set_slot(5, true, 1, float_color, false, -1, _type_color(0))


func _make_slider(lbl: String, min_v: float, max_v: float, step: float, default: float, callback: Callable) -> EditorSpinSlider:
	var s := EditorSpinSlider.new()
	s.label = lbl
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = default
	s.custom_minimum_size = Vector2(_s(80), 0)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(callback)
	add_child(s)
	return s


func _on_tiling_changed(v: float) -> void:
	if _syncing:
		return
	_syncing = true
	_tiling_x = v
	_tiling_y = v
	_tiling_x_slider.value = v
	_tiling_y_slider.value = v
	_syncing = false
	emit_signal("value_changed")


func _on_tiling_x_changed(v: float) -> void:
	if _syncing:
		return
	_tiling_x = v
	emit_signal("value_changed")


func _on_tiling_y_changed(v: float) -> void:
	if _syncing:
		return
	_tiling_y = v
	emit_signal("value_changed")


func _on_offset_x_changed(v: float) -> void:
	_offset_x = v
	emit_signal("value_changed")


func _on_offset_y_changed(v: float) -> void:
	_offset_y = v
	emit_signal("value_changed")


func get_shader_snippet(inputs: Array = []) -> String:
	return "vec3((%s).xy * vec2(%s, %s) + vec2(%s, %s), 0.0)" % [
		inputs[0], inputs[1], inputs[2], inputs[3], inputs[4]]


func get_default_inputs() -> Array:
	return ["vec3(UV, 0.0)", "%.4f" % _tiling_x, "%.4f" % _tiling_y,
			"%.4f" % _offset_x, "%.4f" % _offset_y]


func get_state() -> Dictionary:
	return {"tx": _tiling_x, "ty": _tiling_y, "ox": _offset_x, "oy": _offset_y}


func set_state(state: Dictionary) -> void:
	_syncing = true
	_tiling_x = state.get("tx", 1.0)
	_tiling_y = state.get("ty", 1.0)
	_offset_x = state.get("ox", 0.0)
	_offset_y = state.get("oy", 0.0)
	_tiling_slider.value = _tiling_x if _tiling_x == _tiling_y else 1.0
	_tiling_x_slider.value = _tiling_x
	_tiling_y_slider.value = _tiling_y
	_offset_x_slider.value = _offset_x
	_offset_y_slider.value = _offset_y
	_syncing = false
