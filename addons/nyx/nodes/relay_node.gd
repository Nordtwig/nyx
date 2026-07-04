@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

signal pair_removed(index: int)

var _pair_count: int = 1
var _color: Color = Color(0.14, 0.14, 0.18, 0.95)

var _pair_rows: Array = []
var _add_btn: Button


func _ready() -> void:
	_node_color = _color
	super._ready()
	title = "Relay"

	_add_pair_row_internal()

	var bottom_row := HBoxContainer.new()
	# IGNORE — no hover behavior lives on this row, so it should be fully
	# transparent to input and let node-drag fall through, same reasoning as
	# the pair rows' spacers below.
	bottom_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add_left_spacer := Control.new()
	add_left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_left_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.add_child(add_left_spacer)
	_add_btn = Button.new()
	_style_icon_button(_add_btn, _get_plus_icon())
	_add_btn.pressed.connect(_on_add_pressed)
	bottom_row.add_child(_add_btn)
	var add_right_spacer := Control.new()
	add_right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_right_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.add_child(add_right_spacer)
	add_child(bottom_row)

	_update_slots()
	_apply_node_color()


func _add_preview_controls() -> void:
	pass


# Tight icon button shared by the +/× controls — StyleBoxEmpty on every state
# (same as the inspector cog in nyx_node.gd) strips the editor theme's default
# button padding, which was the source of the + button's oversized hit area
# and visible top/bottom slack. A fixed small size + SHRINK_CENTER on both
# axes keeps the button from stretching to fill its row (the old EXPAND_FILL
# on a lone child was why "+" used to claim the entire bottom strip).
func _style_icon_button(btn: Button, icon: Texture2D) -> void:
	btn.icon = icon
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(_s(20), _s(20))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_color_override("icon_normal_color", Color(0.85, 0.85, 0.9, 0.7))
	btn.add_theme_color_override("icon_hover_color", Color(0.95, 0.95, 1.0))
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)


static var _plus_icon_cache: ImageTexture
static var _x_icon_cache: ImageTexture


static func _get_plus_icon() -> ImageTexture:
	if _plus_icon_cache:
		return _plus_icon_cache
	_plus_icon_cache = _load_relay_icon("res://addons/nyx/icons/plus.svg", 13)
	return _plus_icon_cache


static func _get_x_icon() -> ImageTexture:
	if _x_icon_cache:
		return _x_icon_cache
	_x_icon_cache = _load_relay_icon("res://addons/nyx/icons/x.svg", 12)
	return _x_icon_cache


# Same rasterize-once-and-recolor-to-white approach as nyx_node.gd's
# _get_cog_icon() — icon_*_color overrides only tint correctly against a
# white+alpha source. 12-13px (vs. the cog's 10px) keeps these thinner
# stroke-width-2 glyphs from washing out at the button's small size.
static func _load_relay_icon(path: String, size: int) -> ImageTexture:
	var tex := load(path) as Texture2D
	if not tex:
		return null
	var img := tex.get_image()
	img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			if px.a > 0.0:
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, px.a))
	return ImageTexture.create_from_image(img)


func _add_pair_row_internal() -> HBoxContainer:
	var row := HBoxContainer.new()
	# PASS, not IGNORE — this row still needs its own mouse_entered/exited for
	# the hover-reveal below, but should also let the press continue to the
	# GraphNode itself for dragging (PASS both receives AND propagates to the
	# parent; IGNORE would receive nothing at all, killing the hover signals).
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# IGNORE — a plain filler Control defaults to MOUSE_FILTER_STOP, which
	# silently ate node-drag presses across almost the whole row (this, not
	# just the button, was why only the node's outer edges were draggable).
	left_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(left_spacer)
	var remove_btn := Button.new()
	_style_icon_button(remove_btn, _get_x_icon())
	remove_btn.add_theme_color_override("icon_pressed_color", Color("#4AAF78"))
	# Hover-only, same opacity+mouse_filter toggle as the inspector cog (see
	# nyx_node.gd) — not .visible, which would reflow the spacers around it.
	remove_btn.modulate.a = 0.0
	remove_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	remove_btn.pressed.connect(func(): _on_remove_pair(_pair_rows.find(row)))
	row.set_meta("remove_btn", remove_btn)
	row.add_child(remove_btn)
	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(right_spacer)
	row.mouse_entered.connect(func(): _set_remove_btn_visible(remove_btn, true))
	# Entering the button itself (a STOP-filter child) fires the row's own
	# mouse_exited in Godot's topmost-control model — a raw exit would hide the
	# button the instant you try to hover it. Same geometric recheck as
	# nyx_node.gd's _on_hover_exit.
	row.mouse_exited.connect(func():
		if row.get_global_rect().has_point(row.get_global_mouse_position()):
			return
		_set_remove_btn_visible(remove_btn, false)
	)
	_pair_rows.append(row)
	add_child(row)
	return row


func _set_remove_btn_visible(btn: Button, v: bool) -> void:
	btn.modulate.a = 1.0 if v else 0.0
	btn.mouse_filter = Control.MOUSE_FILTER_STOP if v else Control.MOUSE_FILTER_IGNORE


# Same reliability problem the inspector cog had (see nyx_node.gd's _process
# and its known-gotchas writeup): a port dot overhangs each row's edge for
# GraphEdit's own connection grab zone, and leaving a row through that zone
# doesn't reliably fire mouse_exited, since it's hit-tested by GraphEdit
# itself rather than ordinary Control hover tracking — the reactive
# mouse_entered/exited handlers above are the fast path, this is the
# per-frame backstop that guarantees a row's "×" never gets stuck visible
# regardless of how the cursor actually left.
func _process(delta: float) -> void:
	super._process(delta)
	var mouse_pos := get_global_mouse_position()
	for row in _pair_rows:
		var row_ctrl: Control = row
		var remove_btn: Button = row_ctrl.get_meta("remove_btn")
		var hovered: bool = row_ctrl.get_global_rect().has_point(mouse_pos)
		var shown: bool = remove_btn.modulate.a > 0.5
		if hovered and not shown:
			_set_remove_btn_visible(remove_btn, true)
		elif not hovered and shown:
			_set_remove_btn_visible(remove_btn, false)


func _on_add_pressed() -> void:
	emit_signal("edit_started")
	var bottom_row: Node = _add_btn.get_parent()
	remove_child(bottom_row)
	_add_pair_row_internal()
	add_child(bottom_row)
	_pair_count += 1
	_update_slots()
	emit_signal("value_changed")


func _add_pair_silently() -> void:
	var bottom_row: Node = _add_btn.get_parent()
	remove_child(bottom_row)
	_add_pair_row_internal()
	add_child(bottom_row)
	_pair_count += 1
	_update_slots()


func _on_remove_pair(idx: int) -> void:
	if _pair_count <= 1 or idx < 0:
		return
	emit_signal("edit_started")
	var row: Node = _pair_rows[idx]
	_pair_rows.remove_at(idx)
	remove_child(row)
	row.queue_free()
	_pair_count -= 1
	_update_slots()
	call_deferred("reset_size")
	emit_signal("pair_removed", idx)
	emit_signal("value_changed")


func _update_slots() -> void:
	var vec3_color := _type_color(0)
	for i in range(_pair_rows.size()):
		set_slot(i, true, 0, vec3_color, true, 0, vec3_color)
	var n := _pair_rows.size()
	set_slot(n, false, -1, _type_color(0), false, -1, _type_color(0))


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
	return input_types[from_port] if from_port < input_types.size() else 0


func get_default_input_types() -> Array:
	var types := []
	for i in range(_pair_count):
		types.append(0)
	return types


func get_output_snippet(port: int, inputs: Array = []) -> String:
	return inputs[port] if port < inputs.size() else "vec3(0.0)"


func get_shader_snippet(inputs: Array = []) -> String:
	return inputs[0] if not inputs.is_empty() else "vec3(0.0)"


func get_default_inputs() -> Array:
	var defaults := []
	for i in range(_pair_count):
		defaults.append("vec3(0.0)")
	return defaults


func get_state() -> Dictionary:
	return {
		"pair_count": _pair_count,
		"custom_name": title,
		"color": [_color.r, _color.g, _color.b, _color.a],
	}


func set_state(state: Dictionary) -> void:
	title = state.get("custom_name", "Relay")
	var c = state.get("color")
	if c is Array and c.size() >= 4:
		_color = Color(c[0], c[1], c[2], c[3])
		_node_color = _color
	var target: int = state.get("pair_count", 1)
	while _pair_count < target:
		_add_pair_silently()
	_apply_node_color()
