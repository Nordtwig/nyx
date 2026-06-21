@tool
extends "res://addons/nyx/nodes/nyx_noise_node.gd"

var _octaves: int = 4
var _lacunarity: float = 2.0
var _gain: float = 0.5
var _octaves_slider: EditorSpinSlider
var _lacunarity_slider: EditorSpinSlider
var _gain_slider: EditorSpinSlider

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

const _FBM_FUNCTION = """float nyx_fbm(vec2 p, int octaves, float lacunarity, float gain) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	for (int i = 0; i < octaves; i++) {
		value += amplitude * nyx_gradient_noise(p * frequency);
		frequency *= lacunarity;
		amplitude *= gain;
	}
	return value;
}
"""


func _ready() -> void:
	super._ready()
	title = "FBM"

	var float_color := Color(0.35, 0.9, 0.85)

	_octaves_slider = EditorSpinSlider.new()
	_octaves_slider.label = "Octaves"
	_octaves_slider.min_value = 1
	_octaves_slider.max_value = 8
	_octaves_slider.step = 1
	_octaves_slider.value = _octaves
	_octaves_slider.custom_minimum_size = Vector2(80, 0)
	_octaves_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_octaves_slider.value_changed.connect(_on_octaves_changed)
	add_child(_octaves_slider)

	_lacunarity_slider = EditorSpinSlider.new()
	_lacunarity_slider.label = "Lacunarity"
	_lacunarity_slider.min_value = 1.0
	_lacunarity_slider.max_value = 4.0
	_lacunarity_slider.step = 0.1
	_lacunarity_slider.value = _lacunarity
	_lacunarity_slider.custom_minimum_size = Vector2(80, 0)
	_lacunarity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lacunarity_slider.value_changed.connect(_on_lacunarity_changed)
	add_child(_lacunarity_slider)

	_gain_slider = EditorSpinSlider.new()
	_gain_slider.label = "Gain"
	_gain_slider.min_value = 0.0
	_gain_slider.max_value = 1.0
	_gain_slider.step = 0.01
	_gain_slider.value = _gain
	_gain_slider.custom_minimum_size = Vector2(80, 0)
	_gain_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gain_slider.value_changed.connect(_on_gain_changed)
	add_child(_gain_slider)


func _on_octaves_changed(val: float) -> void:
	_octaves = int(val)
	emit_signal("value_changed")


func _on_lacunarity_changed(val: float) -> void:
	_lacunarity = val
	emit_signal("value_changed")


func _on_gain_changed(val: float) -> void:
	_gain = val
	emit_signal("value_changed")


func get_shader_snippet(inputs: Array = []) -> String:
	return "nyx_fbm((%s).xy * %s, %d, %.2f, %.2f)" % [inputs[0], inputs[1], _octaves, _lacunarity, _gain]


func get_shader_functions() -> Dictionary:
	return {
		"nyx_gradient_noise": _GRADIENT_FUNCTIONS,
		"nyx_fbm": _FBM_FUNCTION,
	}


func get_state() -> Dictionary:
	var state := super.get_state()
	state["octaves"] = _octaves
	state["lacunarity"] = _lacunarity
	state["gain"] = _gain
	return state


func set_state(state: Dictionary) -> void:
	super.set_state(state)
	_octaves = state.get("octaves", 4)
	_lacunarity = state.get("lacunarity", 2.0)
	_gain = state.get("gain", 0.5)
	_octaves_slider.value = _octaves
	_lacunarity_slider.value = _lacunarity
	_gain_slider.value = _gain
