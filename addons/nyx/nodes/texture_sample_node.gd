@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

signal texture_pick_requested(node)

var _texture: Texture2D = null
var _uniform_name: String = ""
var _pick_btn: Button
var _tex_label: Label
var _name_edit: LineEdit


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

	_uniform_name = "tex_" + str(name).to_lower()
	var name_row := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = "Name"
	name_row.add_child(name_lbl)
	_name_edit = LineEdit.new()
	_name_edit.text = _uniform_name
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.text_changed.connect(_on_name_changed)
	name_row.add_child(_name_edit)
	add_child(name_row)

	set_slot(0, true, 0, _type_color(0), false, -1, _type_color(0))
	set_slot(1, false, -1, _type_color(0), true, 3, _type_color(3))


func _on_name_changed(new_name: String) -> void:
	_uniform_name = new_name
	value_changed.emit()


func get_uniform_name() -> String:
	return _uniform_name if _uniform_name.strip_edges() != "" else "tex_" + str(name).to_lower()


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
	return "texture(%s, (%s).xy)" % [get_uniform_name(), inputs[0]]


func get_default_inputs() -> Array:
	return ["vec3(UV, 0.0)"]


func get_state() -> Dictionary:
	return {"path": _texture.resource_path if _texture else "", "uniform_name": _uniform_name}


func set_state(state: Dictionary) -> void:
	var path: String = state.get("path", "")
	if path != "":
		var tex = load(path)
		if tex is Texture2D:
			set_texture(tex)
	var uname = state.get("uniform_name", "")
	if uname != "":
		_uniform_name = uname
		_name_edit.text = _uniform_name


func get_vector_semantic() -> String:
	return "color"
