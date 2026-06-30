@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

const _LABELS_VECTOR := ["X", "Y", "Z", "W"]
const _LABELS_COLOR := ["R", "G", "B", "A"]

var _labels: Array = []


func _ready() -> void:
	super._ready()
	title = "Split"

	var float_color := _type_color(1)

	for i in range(4):
		var lbl := Label.new()
		add_child(lbl)
		_labels.append(lbl)

	# Input is vec4 so the alpha channel is available; vec3/vec2/float promote up.
	set_slot(0, true, 3, _type_color(3), true, 1, float_color)
	set_slot(1, false, -1, _type_color(0), true, 1, float_color)
	set_slot(2, false, -1, _type_color(0), true, 1, float_color)
	set_slot(3, false, -1, _type_color(0), true, 1, float_color)

	refresh_contextual_labels()


# Swaps R/G/B/A vs X/Y/Z/W based on what feeds the input port — checked via
# get_vector_semantic() on the upstream node. No connection / no opinion ("")
# defaults to the vector labels (most Split uses skew toward positions/vectors).
func refresh_contextual_labels() -> void:
	var labels: Array = _LABELS_COLOR if _resolve_input_semantic() == "color" else _LABELS_VECTOR
	for i in range(_labels.size()):
		_labels[i].text = labels[i]


func _resolve_input_semantic() -> String:
	var graph := get_parent()
	if not graph is GraphEdit:
		return ""
	for conn in graph.get_connection_list():
		if str(conn["to_node"]) == str(name) and conn["to_port"] == 0:
			var from_node = graph.get_node_or_null(str(conn["from_node"]))
			if from_node and from_node.has_method("get_vector_semantic"):
				return from_node.get_vector_semantic()
	return ""


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
