@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

signal texture_pick_requested(node)

var _texture: Texture2D = null
var _pick_btn: Button
var _tex_label: Label


func _ready() -> void:
	super._ready()
	title = "Texture Sample"

	var uv_label := Label.new()
	uv_label.text = "UV"
	add_child(uv_label)

	var color_label := Label.new()
	color_label.text = "Color"
	add_child(color_label)

	_pick_btn = Button.new()
	_pick_btn.text = "Pick Texture"
	_pick_btn.pressed.connect(func(): texture_pick_requested.emit(self))
	add_child(_pick_btn)

	_tex_label = Label.new()
	_tex_label.text = "(none)"
	_tex_label.clip_text = true
	_tex_label.custom_minimum_size = Vector2(140, 0)
	add_child(_tex_label)

	set_slot(0, true, 0, Color.WHITE, false, -1, Color.WHITE)
	set_slot(1, false, -1, Color.WHITE, true, 0, Color.WHITE)


func get_uniform_name() -> String:
	return "tex_" + str(name).to_lower()


func get_uniform_declaration() -> String:
	return "uniform sampler2D %s : source_color, hint_default_white;" % get_uniform_name()


func get_texture() -> Texture2D:
	return _texture


func set_texture(texture: Texture2D) -> void:
	_texture = texture
	if texture:
		_tex_label.text = texture.resource_path.get_file()
		_pick_btn.text = "Change"
	else:
		_tex_label.text = "(none)"
		_pick_btn.text = "Pick Texture"
	value_changed.emit()


func get_shader_snippet(inputs: Array = []) -> String:
	return "texture(%s, (%s).xy).rgb" % [get_uniform_name(), inputs[0]]


func get_default_inputs() -> Array:
	return ["vec3(UV, 0.0)"]


func get_state() -> Dictionary:
	return {"path": _texture.resource_path if _texture else ""}


func set_state(state: Dictionary) -> void:
	var path: String = state.get("path", "")
	if path != "":
		var tex = load(path)
		if tex is Texture2D:
			set_texture(tex)
