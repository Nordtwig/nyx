@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

const CurvePreview = preload("res://addons/nyx/nodes/curve_preview.gd")

var _curve: Curve
var _baked_texture: ImageTexture
var _preview: Control


func _ready() -> void:
	super._ready()
	title = "Curve"

	var float_color := _type_color(1)

	_curve = Curve.new()
	_curve.add_point(Vector2(0.0, 0.0))
	_curve.add_point(Vector2(1.0, 1.0))
	_baked_texture = ImageTexture.new()
	_bake()

	_curve.changed.connect(_on_curve_changed)

	var row0 := HBoxContainer.new()
	var t_lbl := Label.new()
	t_lbl.text = "T"
	t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row0.add_child(t_lbl)
	var out_lbl := Label.new()
	out_lbl.text = "Out"
	row0.add_child(out_lbl)
	add_child(row0)

	_preview = CurvePreview.new()
	_preview.curve = _curve
	_preview.custom_minimum_size = Vector2(0, 60)
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview.mouse_filter = Control.MOUSE_FILTER_STOP
	_preview.gui_input.connect(_on_preview_input)
	add_child(_preview)

	set_slot(0, true, 1, float_color, true, 1, float_color)


func _bake() -> void:
	var img := Image.create(256, 1, false, Image.FORMAT_RF)
	for i in range(256):
		var t := float(i) / 255.0
		var v := _curve.sample_baked(t)
		img.set_pixel(i, 0, Color(v, v, v, 1.0))
	_baked_texture.set_image(img)


func _on_preview_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		EditorInterface.inspect_object(_curve)


func _on_curve_changed() -> void:
	_bake()
	_preview.queue_redraw()
	emit_signal("value_changed")


func get_uniform_name() -> String:
	return "curve_" + str(name).to_lower()


func get_uniform_declaration() -> String:
	return "uniform sampler2D %s : hint_default_white;" % get_uniform_name()


func get_texture() -> Texture2D:
	return _baked_texture


func get_shader_snippet(inputs: Array = []) -> String:
	return "texture(%s, vec2(clamp(%s, 0.0, 1.0), 0.5)).r" % [get_uniform_name(), inputs[0]]


func get_default_inputs() -> Array:
	return ["0.5"]


func export_as_sub_resource(start_id: int) -> Dictionary:
	var curve_id := "Curve_%d" % start_id
	var tex_id := "CurveTexture_%d" % (start_id + 1)
	var data := []
	for i in range(_curve.get_point_count()):
		var pos := _curve.get_point_position(i)
		data.append(pos)
		data.append(_curve.get_point_left_tangent(i))
		data.append(_curve.get_point_right_tangent(i))
		data.append(_curve.get_point_left_mode(i))
		data.append(_curve.get_point_right_mode(i))
	var lines := PackedStringArray()
	lines.append('[sub_resource type="Curve" id="%s"]' % curve_id)
	lines.append("_data = %s" % var_to_str(data))
	lines.append("")
	lines.append('[sub_resource type="CurveTexture" id="%s"]' % tex_id)
	lines.append('curve = SubResource("%s")' % curve_id)
	lines.append("width = 256")
	lines.append("texture_mode = 1")
	lines.append("")
	return {
		"lines": lines,
		"param_line": 'shader_parameter/%s = SubResource("%s")' % [get_uniform_name(), tex_id],
		"count": 2
	}


func get_state() -> Dictionary:
	var points := []
	for i in range(_curve.get_point_count()):
		var pos := _curve.get_point_position(i)
		points.append({
			"x": pos.x, "y": pos.y,
			"lt": _curve.get_point_left_tangent(i),
			"rt": _curve.get_point_right_tangent(i),
			"lm": _curve.get_point_left_mode(i),
			"rm": _curve.get_point_right_mode(i),
		})
	return {"points": points}


func set_state(state: Dictionary) -> void:
	var points: Array = state.get("points", [])
	if points.is_empty():
		return
	_curve.clear_points()
	for p in points:
		var idx := _curve.add_point(Vector2(p["x"], p["y"]), p.get("lt", 0.0), p.get("rt", 0.0))
		_curve.set_point_left_mode(idx, p.get("lm", 0))
		_curve.set_point_right_mode(idx, p.get("rm", 0))
	_bake()
	_preview.queue_redraw()
