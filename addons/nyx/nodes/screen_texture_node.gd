@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Screen Texture"

	var row0 := HBoxContainer.new()
	var uv_lbl := Label.new()
	uv_lbl.text = "UV"
	uv_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row0.add_child(uv_lbl)
	var out_lbl := Label.new()
	out_lbl.text = "Color"
	row0.add_child(out_lbl)
	add_child(row0)

	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)


func _add_preview_controls() -> void:
	pass


func get_uniform_declaration() -> String:
	return "uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;"


func get_shader_snippet(inputs: Array = []) -> String:
	return "texture(SCREEN_TEXTURE, (%s).xy).rgb" % inputs[0]


func get_default_inputs() -> Array:
	return ["vec3(SCREEN_UV, 0.0)"]
