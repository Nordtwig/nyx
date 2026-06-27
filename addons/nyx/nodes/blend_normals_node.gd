@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

const _FUNCTION = """vec3 nyx_blend_normals(vec3 a, vec3 b) {
	vec3 n1 = a * 2.0 - 1.0;
	vec3 n2 = b * 2.0 - 1.0;
	return normalize(vec3(n1.xy + n2.xy, n1.z)) * 0.5 + 0.5;
}
"""


func _ready() -> void:
	super._ready()
	title = "Blend Normals"

	var row0 := HBoxContainer.new()
	var a_lbl := Label.new()
	a_lbl.text = "A"
	a_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row0.add_child(a_lbl)
	var out_lbl := Label.new()
	out_lbl.text = "Normal"
	row0.add_child(out_lbl)
	add_child(row0)

	var b_lbl := Label.new()
	b_lbl.text = "B"
	add_child(b_lbl)

	set_slot(0, true, 0, _type_color(0), true, 0, _type_color(0))
	set_slot(1, true, 0, _type_color(0), false, -1, _type_color(0))


func get_shader_snippet(inputs: Array = []) -> String:
	return "nyx_blend_normals(%s, %s)" % [inputs[0], inputs[1]]


func get_shader_functions() -> Dictionary:
	return {"nyx_blend_normals": _FUNCTION}


func get_default_inputs() -> Array:
	return ["vec3(0.5, 0.5, 1.0)", "vec3(0.5, 0.5, 1.0)"]


func get_state() -> Dictionary:
	return {}


func set_state(_state: Dictionary) -> void:
	pass
