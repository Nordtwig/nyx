@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "World Position"

	var label := Label.new()
	label.text = "Surface"
	add_child(label)

	set_slot(0, false, -1, _type_color(0), true, 0, _type_color(0))


# Stage-aware: Godot's VERTEX builtin is model-space in vertex() but view-space in
# fragment(), so the world-space position needs a different transform per stage.
#   vertex():   MODEL_MATRIX    * vec4(VERTEX, 1.0)  — model → world
#   fragment(): INV_VIEW_MATRIX * vec4(VERTEX, 1.0)  — view  → world (the DISPLACED
#               position, post-vertex-shader — exactly what depth/foam math wants)
# The compiler picks the branch via _current_stage; get_shader_snippet below stays as
# a fragment-correct fallback for any direct (stageless) call.
func get_stage_snippet(_port: int, _inputs: Array, stage: String) -> String:
	if stage == "vertex":
		return "(MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz"
	return "(INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz"


func get_shader_snippet(inputs: Array = []) -> String:
	return "(INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz"


func get_default_inputs() -> Array:
	return []


func get_vector_semantic() -> String:
	return "vector"
