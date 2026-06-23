@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Split"

	var float_color := Color(0.35, 0.9, 0.85)

	var label_r := Label.new()
	label_r.text = "R"
	add_child(label_r)

	var label_g := Label.new()
	label_g.text = "G"
	add_child(label_g)

	var label_b := Label.new()
	label_b.text = "B"
	add_child(label_b)

	var label_a := Label.new()
	label_a.text = "A"
	add_child(label_a)

	# Input is vec4 so the alpha channel is available; vec3/vec2/float promote up.
	set_slot(0, true, 3, Color("#FF8FC0"), true, 1, float_color)
	set_slot(1, false, -1, Color.WHITE, true, 1, float_color)
	set_slot(2, false, -1, Color.WHITE, true, 1, float_color)
	set_slot(3, false, -1, Color.WHITE, true, 1, float_color)


func get_output_snippet(port: int, inputs: Array = []) -> String:
	match port:
		1:
			return "(%s).g" % [inputs[0]]
		2:
			return "(%s).b" % [inputs[0]]
		3:
			return "(%s).a" % [inputs[0]]
		_:
			return "(%s).r" % [inputs[0]]


func get_default_inputs() -> Array:
	return ["vec4(0.0)"]
