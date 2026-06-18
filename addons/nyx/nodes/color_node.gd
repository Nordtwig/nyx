@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

signal edit_started

var _color := Color.WHITE
var _popup: Popup
var _picker: ColorPicker


func _ready() -> void:
	super._ready()
	title = "Color"

	var click_area := Control.new()
	click_area.custom_minimum_size = Vector2(120, 48)
	click_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	click_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	click_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click_area.gui_input.connect(_on_clicked)
	add_child(click_area)

	_popup = Popup.new()
	_popup.size = Vector2(400, 300)
	add_child(_popup)

	_picker = ColorPicker.new()
	_picker.color = _color
	_picker.color_changed.connect(_on_color_changed)
	_popup.add_child(_picker)

	set_slot(0, false, -1, Color.WHITE, true, 0, Color.WHITE)
	_apply_node_color()


func _on_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		edit_started.emit()
		_popup.popup_centered()


func _on_color_changed(color: Color) -> void:
	_color = color
	_apply_node_color()
	value_changed.emit()


func _apply_node_color() -> void:
	var body := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	body.bg_color = _color
	add_theme_stylebox_override("panel", body)

	var titlebar := get_theme_stylebox("titlebar").duplicate() as StyleBoxFlat
	titlebar.bg_color = _color
	add_theme_stylebox_override("titlebar", titlebar)

	_apply_selection_style(body, titlebar)
	call_deferred("_update_title_color")


func _update_title_color() -> void:
	var luminance := _color.r * 0.299 + _color.g * 0.587 + _color.b * 0.114
	var text_color := Color.BLACK if luminance > 0.5 else Color.WHITE
	var hbox := get_titlebar_hbox()
	for child in hbox.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", text_color)


func get_shader_snippet(inputs: Array = []) -> String:
	return "vec3(%.4f, %.4f, %.4f)" % [_color.r, _color.g, _color.b]


func get_state() -> Dictionary:
	return {"color": [_color.r, _color.g, _color.b, _color.a]}


func set_state(state: Dictionary) -> void:
	var c: Array = state["color"]
	_color = Color(c[0], c[1], c[2], c[3])
	_picker.color = _color
	_apply_node_color()
