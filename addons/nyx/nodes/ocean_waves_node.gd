@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

# Ocean Waves — a summed Gerstner wave stack as one node. Three outputs share the
# same wave table so displacement, its analytic normal, and a foam-driving crest mask
# stay consistent:
#   Offset (vec3) → Vertex Output · Offset   (the horizontal-pinch displacement)
#   Normal (vec3) → Vertex Output · Normal   (geometric unit normal, NOT NORMAL_MAP-packed)
#   Crest  (float)                            (0 in troughs → 1 at peaks; foam driver)
#
# Why a super node and not composable single-wave nodes: the correct normal is one
# normalize() over the WHOLE sum (per-wave normals can't be added back), and the
# "crests never fold into loops" guarantee is a budget across the whole stack
# (Σ Qᵢ·kᵢ·aᵢ ≤ 1). Both live in the sum, so the stack is the node.
#
# The wave-table params are baked as call-site literals (like FBM's octaves/gain);
# the helpers take position + TIME as arguments so they stay builtin-free per the
# get_shader_functions() convention. Amplitude sets height; Steepness (0–1, budget-
# normalized) sets crest sharpness independently — at 0 the stack is smooth sine
# rollers, near 1 the crests sharpen to their non-self-intersecting limit.

var _waves: int = 5
var _wavelength: float = 24.0
var _amplitude: float = 0.6
var _steepness: float = 0.55
var _speed: float = 1.0
var _direction: float = 25.0
var _spread: float = 60.0
var _seed: float = 0.0

var _waves_slider: EditorSpinSlider
var _wavelength_slider: EditorSpinSlider
var _amplitude_slider: EditorSpinSlider
var _steepness_slider: EditorSpinSlider
var _speed_slider: EditorSpinSlider
var _direction_slider: EditorSpinSlider
var _spread_slider: EditorSpinSlider
var _seed_slider: EditorSpinSlider

const _HASH := """float nyx_ocean_hash(float n) {
	return fract(sin(n) * 43758.5453123);
}
"""

# Per-wave derivation shared by all three functions:
#   λ_i = wavelength · 0.68^i      (each wave shorter)     k_i = 2π / λ_i
#   a_i = amplitude · 0.62^i       (each wave lower)
#   dir_i = direction ± spread·hash(seed,i)                (jittered so fronts don't grid)
#   ω_i = √(g · k_i)               deep-water dispersion (angular frequency, NOT phase
#                                  speed — phase speed would be √(g/k), a different
#                                  quantity; using that in place of ω was a real bug
#                                  found live 2026-07-06, see feedback.md) → long waves
#                                  bob slowly, short waves bob fast, matching real water
#   phase = k_i·dot(dir_i, p.xz) − ω_i·speed·t
# Steepness budget: Qᵢ·kᵢ·aᵢ = steepness/count per wave, so the horizontal pinch is
# steepness/(count·k)·cos(phase) and Σ = steepness ≤ 1 (never self-intersects).
const _OFFSET := """vec3 nyx_ocean_offset(vec3 wp, float t, int count, float wavelength, float amplitude, float steepness, float speed, float direction, float spread, float seed) {
	vec2 p = wp.xz;
	vec3 o = vec3(0.0);
	float base = radians(direction);
	float fcount = float(count);
	for (int i = 0; i < count; i++) {
		float fi = float(i);
		float k = 6.28318530718 / (wavelength * pow(0.68, fi));
		float a = amplitude * pow(0.62, fi);
		float ang = base + radians(spread) * (nyx_ocean_hash(seed + fi * 13.13) * 2.0 - 1.0);
		vec2 d = vec2(cos(ang), sin(ang));
		float ph = k * dot(d, p) - sqrt(9.8 * k) * speed * t;
		float qa = steepness / (fcount * k);
		o.x += d.x * qa * cos(ph);
		o.z += d.y * qa * cos(ph);
		o.y += a * sin(ph);
	}
	return o;
}
"""

const _NORMAL := """vec3 nyx_ocean_normal(vec3 wp, float t, int count, float wavelength, float amplitude, float steepness, float speed, float direction, float spread, float seed) {
	vec2 p = wp.xz;
	float nx = 0.0;
	float nz = 0.0;
	float ny = 0.0;
	float base = radians(direction);
	float fcount = float(count);
	for (int i = 0; i < count; i++) {
		float fi = float(i);
		float k = 6.28318530718 / (wavelength * pow(0.68, fi));
		float a = amplitude * pow(0.62, fi);
		float ang = base + radians(spread) * (nyx_ocean_hash(seed + fi * 13.13) * 2.0 - 1.0);
		vec2 d = vec2(cos(ang), sin(ang));
		float ph = k * dot(d, p) - sqrt(9.8 * k) * speed * t;
		float wa = k * a;
		nx -= d.x * wa * cos(ph);
		nz -= d.y * wa * cos(ph);
		ny += (steepness / fcount) * sin(ph);
	}
	return normalize(vec3(nx, 1.0 - ny, nz));
}
"""

const _CREST := """float nyx_ocean_crest(vec3 wp, float t, int count, float wavelength, float amplitude, float steepness, float speed, float direction, float spread, float seed) {
	vec2 p = wp.xz;
	float acc = 0.0;
	float base = radians(direction);
	float fcount = float(count);
	for (int i = 0; i < count; i++) {
		float fi = float(i);
		float k = 6.28318530718 / (wavelength * pow(0.68, fi));
		float ang = base + radians(spread) * (nyx_ocean_hash(seed + fi * 13.13) * 2.0 - 1.0);
		vec2 d = vec2(cos(ang), sin(ang));
		float ph = k * dot(d, p) - sqrt(9.8 * k) * speed * t;
		acc += (steepness / fcount) * sin(ph);
	}
	return clamp(acc / max(steepness, 0.0001), 0.0, 1.0);
}
"""


func _ready() -> void:
	super._ready()
	title = "Ocean Waves"

	var vec3_color := _type_color(0)
	var float_color := _type_color(1)

	# Row 0 — Position (in) | Offset (out)
	var row0 := HBoxContainer.new()
	var pos_lbl := Label.new()
	pos_lbl.text = "Position"
	pos_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row0.add_child(pos_lbl)
	var off_lbl := Label.new()
	off_lbl.text = "Offset"
	row0.add_child(off_lbl)
	add_child(row0)

	# Rows 1, 2 — Normal (out), Crest (out), right-aligned toward their port dots.
	var normal_lbl := Label.new()
	normal_lbl.text = "Normal"
	normal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(normal_lbl)

	var crest_lbl := Label.new()
	crest_lbl.text = "Crest"
	crest_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(crest_lbl)

	set_slot(0, true, 0, vec3_color, true, 0, vec3_color)   # Position in vec3, Offset out vec3
	set_slot(1, false, -1, vec3_color, true, 0, vec3_color)  # Normal out vec3
	set_slot(2, false, -1, vec3_color, true, 1, float_color) # Crest out float

	_waves_slider = _make_slider("Waves", 1, 8, 1, _waves, func(v): _waves = int(v))
	_wavelength_slider = _make_slider("Wavelength", 0.5, 100.0, 0.5, _wavelength, func(v): _wavelength = v)
	_amplitude_slider = _make_slider("Amplitude", 0.0, 5.0, 0.05, _amplitude, func(v): _amplitude = v)
	_steepness_slider = _make_slider("Steepness", 0.0, 1.0, 0.01, _steepness, func(v): _steepness = v)
	_speed_slider = _make_slider("Speed", 0.0, 4.0, 0.05, _speed, func(v): _speed = v)
	_direction_slider = _make_slider("Direction", 0.0, 360.0, 1.0, _direction, func(v): _direction = v)
	_spread_slider = _make_slider("Spread", 0.0, 180.0, 1.0, _spread, func(v): _spread = v)
	_seed_slider = _make_slider("Seed", 0.0, 100.0, 0.1, _seed, func(v): _seed = v)


func _make_slider(label: String, mn: float, mx: float, step: float, value: float, setter: Callable) -> EditorSpinSlider:
	var s := EditorSpinSlider.new()
	s.label = label
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(_s(80), 0)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v: float): setter.call(v); emit_signal("value_changed"))
	add_child(s)
	return s


func _wave_args(inputs: Array) -> String:
	return "%s, TIME, %d, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f" % [
		inputs[0], _waves, _wavelength, _amplitude, _steepness, _speed, _direction, _spread, _seed]


func get_output_snippet(port: int, inputs: Array = []) -> String:
	match port:
		1: return "nyx_ocean_normal(%s)" % _wave_args(inputs)
		2: return "nyx_ocean_crest(%s)" % _wave_args(inputs)
		_: return "nyx_ocean_offset(%s)" % _wave_args(inputs)


func get_shader_snippet(inputs: Array = []) -> String:
	return get_output_snippet(0, inputs)


func get_shader_functions() -> Dictionary:
	# Hash first — GLSL declare-before-use; dict insertion order is preserved by the compiler.
	return {
		"nyx_ocean_hash": _HASH,
		"nyx_ocean_offset": _OFFSET,
		"nyx_ocean_normal": _NORMAL,
		"nyx_ocean_crest": _CREST,
	}


func get_default_inputs() -> Array:
	return ["vec3(0.0)"]


func get_default_input_types() -> Array:
	return [0]


func get_state() -> Dictionary:
	return {
		"waves": _waves, "wavelength": _wavelength, "amplitude": _amplitude,
		"steepness": _steepness, "speed": _speed, "direction": _direction,
		"spread": _spread, "seed": _seed,
	}


func set_state(state: Dictionary) -> void:
	_waves = int(state.get("waves", 5))
	_wavelength = state.get("wavelength", 24.0)
	_amplitude = state.get("amplitude", 0.6)
	_steepness = state.get("steepness", 0.55)
	_speed = state.get("speed", 1.0)
	_direction = state.get("direction", 25.0)
	_spread = state.get("spread", 60.0)
	_seed = state.get("seed", 0.0)
	if _waves_slider: _waves_slider.value = _waves
	if _wavelength_slider: _wavelength_slider.value = _wavelength
	if _amplitude_slider: _amplitude_slider.value = _amplitude
	if _steepness_slider: _steepness_slider.value = _steepness
	if _speed_slider: _speed_slider.value = _speed
	if _direction_slider: _direction_slider.value = _direction
	if _spread_slider: _spread_slider.value = _spread
	if _seed_slider: _seed_slider.value = _seed
