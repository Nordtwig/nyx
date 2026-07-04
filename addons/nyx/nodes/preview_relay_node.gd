@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _color: Color = Color(0.14, 0.14, 0.18, 0.95)


func _ready() -> void:
	_node_color = _color
	super._ready()
	title = "Preview"

	# An empty-text Label, not a bare Control — a Label's minimum height comes
	# from font ascent/descent metrics (one line's worth of vertical space),
	# independent of the actual string content, so this inherits the exact
	# same height every other node's Label-based row gets, on any machine,
	# with no hardcoded/scaled number to keep in sync. (A hardcoded _s(23)
	# was tried first and was wrong: that "23" was measured with no editor
	# scale applied at all, since Label sizing is font-driven and already
	# scales on its own — wrapping it in _s() scaled it a second time,
	# shrinking it below the real row height on an actual running editor.)
	var port_row := Label.new()
	add_child(port_row)

	set_slot(0, true, 0, _type_color(0), true, 0, _type_color(0))

	_apply_node_color()

	# Preview Relay's preview isn't a secondary, occasionally-toggled feature
	# like every other node's — it's the whole point of the node, so it
	# should already be open the moment it's spawned or loaded, not require
	# a manual click. Reuses the real toggle handler (not a state copy) so
	# preview_toggled fires correctly and nyx_main.gd's existing per-node
	# preview wiring opens the SubViewport for it exactly as if clicked.
	call_deferred("_auto_open_preview")


func _auto_open_preview() -> void:
	if _preview_chevron and not _preview_open:
		_on_preview_chevron_pressed(_preview_chevron)


func _on_color_changed(color: Color) -> void:
	_color = color
	_node_color = color
	_apply_node_color()
	emit_signal("value_changed")


func get_color() -> Color:
	return _color


# Counterpart to get_color() — the node-inspector popup calls this on every
# ColorPicker drag (see color_node.gd for why this Callable pair exists).
func set_color_from_inspector(c: Color) -> void:
	_on_color_changed(c)


func _apply_node_color() -> void:
	_apply_body_color(_color)


func _update_title_color() -> void:
	_apply_luminance_title_color(_color)


func is_polymorphic() -> bool:
	return true


func get_output_type(from_port: int, input_types: Array) -> int:
	return input_types[0] if not input_types.is_empty() else 0


func get_default_input_types() -> Array:
	return [0]


func get_output_snippet(port: int, inputs: Array = []) -> String:
	return inputs[0] if not inputs.is_empty() else "vec3(0.0)"


func get_shader_snippet(inputs: Array = []) -> String:
	return inputs[0] if not inputs.is_empty() else "vec3(0.0)"


func get_default_inputs() -> Array:
	return ["vec3(0.0)"]


func get_state() -> Dictionary:
	return {
		"custom_name": title,
		"color": [_color.r, _color.g, _color.b, _color.a],
	}


func set_state(state: Dictionary) -> void:
	title = state.get("custom_name", "Preview")
	var c = state.get("color")
	if c is Array and c.size() >= 4:
		_color = Color(c[0], c[1], c[2], c[3])
		_node_color = _color
	_apply_node_color()
