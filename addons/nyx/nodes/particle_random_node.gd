@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

# Random — a stable per-particle random value, hashed from the particle's unique
# NUMBER (same particle always returns the same value, so it's safe in both start
# and process). Two modes via dropdown:
#   Vector — three decorrelated channels (random direction / position). Output vec3.
#   Scalar — a single random number (size / colour / lifetime jitter). Output float.
# Min/Max bake the output into a useful range directly, so you don't have to do the
# manual "random - 0.5, then scale" dance. A single uniform Min/Max applies to every
# channel; defaults to a symmetric [-1, 1] so the common case (Vector → Velocity)
# scatters out of the box. For a per-axis bias (e.g. a fountain), multiply the output
# by a direction Vector3 and add a base — graph-idiomatic and keeps this node small.

var _mode: int = 0  # 0 = Vector (vec3), 1 = Scalar (float)
var _min: float = -1.0
var _max: float = 1.0

var _option_btn: OptionButton
var _spin_min: SpinBox
var _spin_max: SpinBox


func _add_preview_controls() -> void:
	pass


func _ready() -> void:
	super._ready()
	title = "Random"

	_option_btn = OptionButton.new()
	_option_btn.add_item("Vector")
	_option_btn.add_item("Scalar")
	_option_btn.selected = _mode
	_option_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_option_btn.item_selected.connect(_on_mode_selected)
	add_child(_option_btn)

	var min_row := HBoxContainer.new()
	var min_lbl := Label.new()
	min_lbl.text = "Min"
	min_lbl.custom_minimum_size = Vector2(30, 0)
	min_row.add_child(min_lbl)
	_spin_min = _make_spin(_min)
	min_row.add_child(_spin_min)
	add_child(min_row)

	var max_row := HBoxContainer.new()
	var max_lbl := Label.new()
	max_lbl.text = "Max"
	max_lbl.custom_minimum_size = Vector2(30, 0)
	max_row.add_child(max_lbl)
	_spin_max = _make_spin(_max)
	max_row.add_child(_spin_max)
	add_child(max_row)

	_spin_min.value_changed.connect(func(_v): _on_value_changed())
	_spin_max.value_changed.connect(func(_v): _on_value_changed())

	# Output port on the dropdown row (child 0); type set per mode in _apply_mode.
	set_slot(0, false, -1, Color.WHITE, true, 0, Color.WHITE)
	_apply_mode()


func _make_spin(initial: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = -1e9
	spin.max_value = 1e9
	spin.step = 0.001
	spin.value = initial
	spin.custom_minimum_size = Vector2(48, 0)
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spin


func _on_mode_selected(idx: int) -> void:
	emit_signal("edit_started")
	_mode = idx
	_apply_mode()
	emit_signal("value_changed")


func _apply_mode() -> void:
	# vec3 (id 0, white) in Vector mode; float (id 1, teal) in Scalar mode.
	var is_vec := _mode == 0
	var t: int = 0 if is_vec else 1
	var col := Color.WHITE if is_vec else Color(0.35, 0.9, 0.85)
	set_slot(0, false, -1, col, true, t, col)
	call_deferred("reset_size")


func _on_value_changed() -> void:
	_min = _spin_min.value
	_max = _spin_max.value
	emit_signal("value_changed")


func get_shader_snippet(inputs: Array = []) -> String:
	if _mode == 1:
		return "mix(%.4f, %.4f, nyx_hash_u(NUMBER))" % [_min, _max]
	return "mix(vec3(%.4f), vec3(%.4f), nyx_hash_u3(NUMBER))" % [_min, _max]


func get_shader_functions() -> Dictionary:
	# lowbias32 integer hash → 0..1. nyx_hash_u must be defined before nyx_hash_u3
	# (GLSL requires declaration before use); dict insertion order is preserved.
	# Bitwise uint ops require GLSL ES 3.0, which particle shaders always run under.
	return {
		"nyx_hash_u": "float nyx_hash_u(uint x) {\n"
			+ "\tx ^= x >> 16u;\n"
			+ "\tx *= 0x7feb352du;\n"
			+ "\tx ^= x >> 15u;\n"
			+ "\tx *= 0x846ca68bu;\n"
			+ "\tx ^= x >> 16u;\n"
			+ "\treturn float(x) / 4294967295.0;\n"
			+ "}\n\n",
		"nyx_hash_u3": "vec3 nyx_hash_u3(uint n) {\n"
			+ "\treturn vec3(nyx_hash_u(n * 3u), nyx_hash_u(n * 3u + 1u), nyx_hash_u(n * 3u + 2u));\n"
			+ "}\n\n",
	}


func get_state() -> Dictionary:
	return {"mode": _mode, "min": _min, "max": _max}


func set_state(state: Dictionary) -> void:
	_mode = state.get("mode", 0)
	var mn = state.get("min")
	if mn is float or mn is int:
		_min = mn
	var mx = state.get("max")
	if mx is float or mx is int:
		_max = mx
	_spin_min.value = _min
	_spin_max.value = _max
	_option_btn.selected = _mode
	_apply_mode()
