@tool
extends Control

## Nyx quick-add popup — the input-side "drag a connection out and drop it on
## empty canvas" overlay (see .nyx-notes/olympus-viewport.md's "Connection-drop
## node spawn" design, backlog.md, and the Fable 2026-07-06 design session).
##
## Still NOT the full aMenu (nyx_search_popup.gd): a pre-curated, type-filtered
## candidate list, no doc card. But it DOES now carry a search box (added
## 2026-07-07): the output-side drop can offer 30+ compatible nodes, too long to
## eyeball, and grabbing focus into the search field on open is also what makes
## arrow-key nav reliable — without a focused field the editor's own focus
## traversal was stealing Up/Down (both were live-test follow-ups from the
## 2026-07-06 connection-drop session). Typing filters; empty query shows the
## full curated list, so speed-at-drag-release is unchanged for the short
## input-side case.
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
var _search_field: LineEdit
var _scroll: ScrollContainer
var _rows_vbox: VBoxContainer
var _all_candidates: Array = []   # full curated list from the caller
var _candidates: Array = []       # filtered view, parallel to rows: {id, label, is_param, type}
var _row_nodes: Array = []
var _selected_index: int = -1

var _row_highlight_style: StyleBoxFlat
var _row_empty_style: StyleBoxEmpty

const ITEM_ROW_HEIGHT := 20
const ROW_INSET := 8.0
const MAX_LIST_HEIGHT := 280      # cap the scroll; short lists shrink-wrap under it
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

	_search_field = LineEdit.new()
	_search_field.placeholder_text = "Search..."
	_search_field.custom_minimum_size.y = 26
	var input_normal := StyleBoxFlat.new()
	input_normal.bg_color = Color(0.20, 0.20, 0.26)
	input_normal.border_color = Color(0.35, 0.35, 0.45)
	input_normal.set_border_width_all(1)
	input_normal.set_corner_radius_all(4)
	input_normal.content_margin_left = 8
	input_normal.content_margin_right = 8
	input_normal.content_margin_top = 4
	input_normal.content_margin_bottom = 4
	var input_focus := input_normal.duplicate()
	input_focus.border_color = Color("#31614F")
	_search_field.add_theme_stylebox_override("normal", input_normal)
	_search_field.add_theme_stylebox_override("focus", input_focus)
	_search_field.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	_search_field.add_theme_color_override("font_placeholder_color", Color(0.45, 0.45, 0.52))
	_search_field.add_theme_font_size_override("font_size", 10)
	_search_field.text_changed.connect(_on_search_changed)
	_search_field.gui_input.connect(_on_search_field_key)
	vbox.add_child(_search_field)

	_row_highlight_style = StyleBoxFlat.new()
	_row_highlight_style.bg_color = Color("#31614F")
	_row_highlight_style.set_corner_radius_all(3)
	_row_empty_style = StyleBoxEmpty.new()

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rows_vbox = VBoxContainer.new()
	_rows_vbox.add_theme_constant_override("separation", 0)
	_rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_rows_vbox)
	vbox.add_child(_scroll)

	_card.add_child(vbox)
	add_child(_card)


# candidates: Array of {id:int, label:String, is_param:bool, type:int}, already
# filtered + ordered by the caller (param variants first, per the port/param/
# setting rule — see olympus-viewport.md).
func open(candidates: Array, at_position: Vector2) -> void:
	_all_candidates = candidates
	_search_field.text = ""
	_apply_filter("")
	size = _graph_container.size
	visible = true
	move_to_front()
	_card.reset_size()
	var max_pos := _graph_container.size - _card.size
	_card.position = at_position.clamp(Vector2.ZERO, max_pos.max(Vector2.ZERO))
	if _row_nodes.size() > 0:
		_select_index(0)
	# Focus the field so typing filters immediately and, crucially, so the
	# editor's own focus traversal can't steal Up/Down from the list.
	_search_field.call_deferred("grab_focus")


func close() -> void:
	visible = false


# Case-insensitive substring filter over the caller's already-ordered list
# (param variants stay first). Empty query = the full curated list.
func _apply_filter(query: String) -> void:
	query = query.strip_edges().to_lower()
	if query.is_empty():
		_candidates = _all_candidates.duplicate()
	else:
		_candidates = []
		for entry in _all_candidates:
			if String(entry["label"]).to_lower().contains(query):
				_candidates.append(entry)
	_populate_rows()
	# Fixed row height + zero separation → exact natural height without a layout
	# pass. Cap it so a long output-side list scrolls instead of overflowing.
	_scroll.custom_minimum_size.y = min(_candidates.size() * ITEM_ROW_HEIGHT, MAX_LIST_HEIGHT)


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
		_scroll.ensure_control_visible(row)


func _confirm_selection() -> void:
	if _selected_index < 0 or _selected_index >= _candidates.size():
		return
	var entry: Dictionary = _candidates[_selected_index]
	close()
	candidate_chosen.emit(entry["id"], entry.get("is_param", false))


func _on_search_changed(text: String) -> void:
	_apply_filter(text)
	# Free-floating card (not inside a parent Container) won't re-snug on its own
	# as the filtered list shrinks — top-left stays put, height re-fits to content.
	_card.reset_size()
	if _row_nodes.size() > 0:
		_select_index(0)


# Nav keys handled here (the field is focused on open) so the editor's focus
# traversal never sees Up/Down — accept_event() stops them dead. Left/right and
# text go to the LineEdit for editing/filtering as usual.
func _on_search_field_key(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_DOWN:
			_move_selection(1)
			_search_field.accept_event()
		KEY_UP:
			_move_selection(-1)
			_search_field.accept_event()
		KEY_ENTER, KEY_KP_ENTER:
			_confirm_selection()
			_search_field.accept_event()
		KEY_ESCAPE:
			close()
			_search_field.accept_event()


func _move_selection(delta: int) -> void:
	if _candidates.is_empty():
		return
	var idx: int = clamp(_selected_index + delta, 0, _candidates.size() - 1)
	_select_index(idx)


# Fallback for when the search field somehow isn't focused (mouse-only use);
# a focused field accept_event()s these first, so they never reach here then.
func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_DOWN:
			_move_selection(1)
			get_viewport().set_input_as_handled()
		KEY_UP:
			_move_selection(-1)
			get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER:
			_confirm_selection()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
