@tool
extends Control

## Nyx quick-add popup — the input-side "drag a connection out and drop it on
## empty canvas" overlay (see .nyx-notes/olympus-viewport.md's "Connection-drop
## node spawn" design, backlog.md, and the Fable 2026-07-06 design session).
##
## Deliberately NOT the full aMenu (nyx_search_popup.gd): this is a short,
## pre-curated list (a handful of value/input nodes compatible with the port
## the connection was dragged from), not a searchable catalog of all ~70 node
## types. No search box, no doc card — the whole point is speed at the moment
## of a drag-release.
##
## One-way dependency, same shape as nyx_search_popup.gd: nyx_main computes the
## candidate list (already filtered/weighted by type-compatibility via the
## promotion matrix + shader-type gating) and hands it to open(); this popup
## only renders rows and emits which one got picked. It never reaches back
## into nyx_main or the compiler itself.
##
## Row visual language mirrors nyx_search_popup.gd/nyx_command_palette.gd:
## hand-built Panel rows (not ItemList), fixed height, hover highlight.

signal candidate_chosen(id: int, is_param: bool)

var _graph_container: Control

var _card: PanelContainer
var _rows_vbox: VBoxContainer
var _candidates: Array = []       # parallel to rows: {id, label, is_param, type}
var _row_nodes: Array = []
var _selected_index: int = -1

var _row_highlight_style: StyleBoxFlat
var _row_empty_style: StyleBoxEmpty

const ITEM_ROW_HEIGHT := 20
const ROW_INSET := 8.0
const PARAM_BADGE_COLOR := Color("#6BCF96")
const LABEL_COLOR := Color(0.90, 0.90, 0.90)
const LABEL_SELECTED_COLOR := Color.WHITE


func setup(container: Control) -> void:
	_graph_container = container
	_build()


func _build() -> void:
	visible = false
	position = Vector2.ZERO
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var backdrop := Control.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			close())
	add_child(backdrop)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.14, 0.14, 0.18, 0.92)
	card_style.border_color = Color(0.24, 0.24, 0.30)
	card_style.set_border_width_all(1)
	card_style.corner_radius_top_left = 6
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 6
	card_style.set_content_margin_all(6)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(200, 0)
	_card.add_theme_stylebox_override("panel", card_style)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var header := Label.new()
	header.text = "Add Node"
	header.add_theme_color_override("font_color", Color.WHITE)
	header.add_theme_font_size_override("font_size", 11)
	vbox.add_child(header)

	_row_highlight_style = StyleBoxFlat.new()
	_row_highlight_style.bg_color = Color("#31614F")
	_row_highlight_style.set_corner_radius_all(3)
	_row_empty_style = StyleBoxEmpty.new()

	_rows_vbox = VBoxContainer.new()
	_rows_vbox.add_theme_constant_override("separation", 0)
	vbox.add_child(_rows_vbox)

	_card.add_child(vbox)
	add_child(_card)


# candidates: Array of {id:int, label:String, is_param:bool, type:int}, already
# filtered + ordered by the caller (param variants first, per the port/param/
# setting rule — see olympus-viewport.md).
func open(candidates: Array, at_position: Vector2) -> void:
	_candidates = candidates
	_populate_rows()
	size = _graph_container.size
	visible = true
	move_to_front()
	_card.reset_size()
	var max_pos := _graph_container.size - _card.size
	_card.position = at_position.clamp(Vector2.ZERO, max_pos.max(Vector2.ZERO))
	if _row_nodes.size() > 0:
		_select_index(0)


func close() -> void:
	visible = false


func handle_resize() -> void:
	if visible:
		size = _graph_container.size


func _populate_rows() -> void:
	for child in _rows_vbox.get_children():
		_rows_vbox.remove_child(child)
		child.queue_free()
	_row_nodes.clear()
	_selected_index = -1

	for i in range(_candidates.size()):
		_add_item_row(_candidates[i], i)


func _add_item_row(entry: Dictionary, idx: int) -> void:
	var row := Panel.new()
	row.custom_minimum_size = Vector2(0, ITEM_ROW_HEIGHT)
	row.clip_contents = true
	row.add_theme_stylebox_override("panel", _row_empty_style)
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	var label := Label.new()
	var text: String = entry["label"]
	if entry.get("is_param", false):
		text += "  (Parameter)"
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_color_override(
		"font_color", PARAM_BADGE_COLOR if entry.get("is_param", false) else LABEL_COLOR)
	label.add_theme_font_size_override("font_size", 10)

	# Anchored directly on the Label, NOT wrapped in an HBoxContainer - matches
	# nyx_search_popup.gd's _center_row_content exactly. A wrapping HBox was
	# tried first and produced a real bug: clip_text=true makes a Label report
	# a near-zero minimum width (that's the whole point - so it can be
	# squeezed and clip instead of forcing the layout wider), and an
	# HBoxContainer only grows a child past its own minimum on the main axis
	# if that child has SIZE_EXPAND - which a bare Label doesn't. The anchors
	# below force the Label's own rect wide directly, bypassing container
	# main-axis sizing entirely, so clip_text's tiny minimum never matters.
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.offset_left = ROW_INSET
	label.offset_right = -ROW_INSET
	var h: float = label.get_combined_minimum_size().y
	label.anchor_top = 0.5
	label.anchor_bottom = 0.5
	label.offset_top = -h / 2.0
	label.offset_bottom = h / 2.0
	row.add_child(label)
	row.set_meta("main_label", label)

	_rows_vbox.add_child(row)
	_row_nodes.append(row)

	row.mouse_entered.connect(_select_index.bind(idx))
	row.gui_input.connect(_on_row_gui_input.bind(idx))


func _on_row_gui_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_index(idx)
		_confirm_selection()
		get_viewport().set_input_as_handled()


func _select_index(idx: int) -> void:
	if idx == _selected_index:
		return
	if _selected_index >= 0 and _selected_index < _row_nodes.size():
		var prev: Control = _row_nodes[_selected_index]
		prev.add_theme_stylebox_override("panel", _row_empty_style)
		var prev_label: Label = prev.get_meta("main_label", null)
		if prev_label:
			var entry: Dictionary = _candidates[_selected_index]
			prev_label.add_theme_color_override(
				"font_color", PARAM_BADGE_COLOR if entry.get("is_param", false) else LABEL_COLOR)
	_selected_index = idx
	if idx >= 0 and idx < _row_nodes.size():
		var row: Control = _row_nodes[idx]
		row.add_theme_stylebox_override("panel", _row_highlight_style)
		var label: Label = row.get_meta("main_label", null)
		if label:
			label.add_theme_color_override("font_color", LABEL_SELECTED_COLOR)


func _confirm_selection() -> void:
	if _selected_index < 0 or _selected_index >= _candidates.size():
		return
	var entry: Dictionary = _candidates[_selected_index]
	close()
	candidate_chosen.emit(entry["id"], entry.get("is_param", false))


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_DOWN:
			if _selected_index < _candidates.size() - 1:
				_select_index(_selected_index + 1)
			get_viewport().set_input_as_handled()
		KEY_UP:
			if _selected_index > 0:
				_select_index(_selected_index - 1)
			get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER:
			_confirm_selection()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
