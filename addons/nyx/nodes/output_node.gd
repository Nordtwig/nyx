@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

func _ready() -> void:
	super._ready()
	title = "Output"
	set_slot(0, true, 0, Color.WHITE, false, -1, Color.WHITE)
	set_slot(1, true, 1, Color.GRAY, false, -1, Color.WHITE)
	set_slot(2, true, 1, Color.GRAY, false, -1, Color.WHITE)
	set_slot(3, true, 1, Color.GRAY, false, -1, Color.WHITE)
	set_slot(4, true, 0, Color.WHITE, false, -1, Color.WHITE)

	for label_text in ["Albedo", "Alpha", "Roughness", "Metallic", "Emission"]:
		var label := Label.new()
		label.text = label_text
		add_child(label)


func _apply_style() -> void:
	var color := Color(0.18, 0.18, 0.22)

	var body := StyleBoxFlat.new()
	body.bg_color = color
	body.corner_radius_top_left = 0
	body.corner_radius_top_right = 0
	body.corner_radius_bottom_left = 12
	body.corner_radius_bottom_right = 6
	body.expand_margin_top = 2
	body.border_width_left = 1
	body.border_width_right = 1
	body.border_width_bottom = 1
	body.border_color = Color(0.28, 0.28, 0.35)
	add_theme_stylebox_override("panel", body)

	var titlebar := StyleBoxFlat.new()
	titlebar.bg_color = color
	titlebar.corner_radius_top_left = 6
	titlebar.corner_radius_top_right = 12
	titlebar.corner_radius_bottom_left = 0
	titlebar.corner_radius_bottom_right = 0
	titlebar.border_width_left = 1
	titlebar.border_width_right = 1
	titlebar.border_width_top = 1
	titlebar.border_color = Color(0.28, 0.28, 0.35)
	add_theme_stylebox_override("titlebar", titlebar)

	_apply_selection_style(body, titlebar)
	add_theme_icon_override("port", _create_port_texture(10, 1))
	call_deferred("_center_title")
