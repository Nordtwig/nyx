@tool
extends "res://addons/nyx/nodes/nyx_noise_node.gd"

var _type: int = 0
var _option_btn: OptionButton

const _VALUE_FUNCTIONS = """float nyx_hash_vn(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float nyx_value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(nyx_hash_vn(i), nyx_hash_vn(i + vec2(1.0, 0.0)), u.x),
		mix(nyx_hash_vn(i + vec2(0.0, 1.0)), nyx_hash_vn(i + vec2(1.0, 1.0)), u.x),
		u.y);
}
"""

const _GRADIENT_FUNCTIONS = """float nyx_hash_gn(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
vec2 nyx_grad_gn(vec2 p) {
	float a = nyx_hash_gn(p) * 6.28318;
	return vec2(cos(a), sin(a));
}
float nyx_gradient_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(dot(nyx_grad_gn(i), f),
			dot(nyx_grad_gn(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
		mix(dot(nyx_grad_gn(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
			dot(nyx_grad_gn(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
		u.y) * 0.5 + 0.5;
}
"""

const _VORONOI_FUNCTIONS = """vec2 nyx_hash2_vr(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}
float nyx_voronoi(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 n = vec2(float(x), float(y));
			vec2 diff = n + nyx_hash2_vr(i + n) - f;
			d = min(d, dot(diff, diff));
		}
	}
	return sqrt(d);
}
"""


func _ready() -> void:
	super._ready()
	title = "Noise"

	_option_btn = OptionButton.new()
	_option_btn.add_item("Value")
	_option_btn.add_item("Gradient")
	_option_btn.add_item("Voronoi")
	_option_btn.selected = _type
	_option_btn.item_selected.connect(_on_type_changed)
	add_child(_option_btn)


func _on_type_changed(idx: int) -> void:
	_type = idx
	value_changed.emit()


func get_shader_snippet(inputs: Array = []) -> String:
	match _type:
		1:
			return "nyx_gradient_noise((%s).xy * %s)" % [inputs[0], inputs[1]]
		2:
			return "nyx_voronoi((%s).xy * %s)" % [inputs[0], inputs[1]]
		_:
			return "nyx_value_noise((%s).xy * %s)" % [inputs[0], inputs[1]]


func get_shader_functions() -> Dictionary:
	match _type:
		1:
			return {"nyx_gradient_noise": _GRADIENT_FUNCTIONS}
		2:
			return {"nyx_voronoi": _VORONOI_FUNCTIONS}
		_:
			return {"nyx_value_noise": _VALUE_FUNCTIONS}


func get_state() -> Dictionary:
	var state := super.get_state()
	state["type"] = _type
	return state


func set_state(state: Dictionary) -> void:
	super.set_state(state)
	_type = state.get("type", 0)
	_option_btn.selected = _type
