@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _distance: float = 1.0
var _distance_slider: EditorSpinSlider

const _FUNCTION = """float nyx_depth_fade(float fade_dist, vec2 screen_uv, float frag_depth, mat4 inv_proj) {
	float depth = textureLod(DEPTH_TEXTURE, screen_uv, 0.0).r;
	vec4 pixel_view = inv_proj * vec4(screen_uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
	pixel_view.xyz /= pixel_view.w;
	vec4 surface_view = inv_proj * vec4(screen_uv * 2.0 - 1.0, frag_depth * 2.0 - 1.0, 1.0);
	surface_view.xyz /= surface_view.w;
	return clamp((surface_view.z - pixel_view.z) / max(fade_dist, 0.001), 0.0, 1.0);
}
"""


func _ready() -> void:
	super._ready()
	title = "Depth Fade"

	var float_color := Color(0.35, 0.9, 0.85)

	var row0 := HBoxContainer.new()
	var dist_lbl := Label.new()
	dist_lbl.text = "Distance"
	dist_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row0.add_child(dist_lbl)
	var out_lbl := Label.new()
	out_lbl.text = "Out"
	row0.add_child(out_lbl)
	add_child(row0)

	_distance_slider = EditorSpinSlider.new()
	_distance_slider.label = "Distance"
	_distance_slider.min_value = 0.01
	_distance_slider.max_value = 20.0
	_distance_slider.step = 0.01
	_distance_slider.value = _distance
	_distance_slider.custom_minimum_size = Vector2(80, 0)
	_distance_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_distance_slider.value_changed.connect(func(v: float): _distance = v; emit_signal("value_changed"))
	add_child(_distance_slider)

	set_slot(0, true, 1, float_color, true, 1, float_color)
	set_slot(1, false, -1, float_color, false, -1, float_color)


func _add_preview_controls() -> void:
	pass


func get_uniform_declaration() -> String:
	return "uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_nearest;"


func get_shader_snippet(inputs: Array = []) -> String:
	return "nyx_depth_fade(%s, SCREEN_UV, FRAGCOORD.z, INV_PROJECTION_MATRIX)" % inputs[0]


func get_shader_functions() -> Dictionary:
	return {"nyx_depth_fade": _FUNCTION}


func get_default_inputs() -> Array:
	return ["%.4f" % _distance]


func get_state() -> Dictionary:
	return {"distance": _distance}


func set_state(state: Dictionary) -> void:
	var d = state.get("distance")
	if d is float:
		_distance = d
	_distance_slider.value = _distance
