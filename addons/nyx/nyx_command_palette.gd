@tool
extends Control

## Nyx command palette — Ctrl+P overlay for File/Edit/View/Live actions.
##
## Same overlay pattern as nyx_search_popup.gd (a plain Control subtree rendered in the
## main viewport, not a Popup window, so the live graph shows through) but a single card
## instead of the paired search+doc cards — commands don't need a hover doc panel.
##
## Emits the same signal names the old top toolbar (nyx_graph_toolbar.gd, deleted once
## this + nyx_chrome_bar.gd covered its job) used to emit, so nyx_main's existing
## handlers (_on_file_menu_id, _on_export_pressed, etc.) connect to this unchanged. The
## palette holds no state of its own: nyx_main passes a small context dict to open()
## (linked/live_on/recent_files) so items like "Export…" vs "Update" or "Enable/Disable
## Live Link" render correctly — this is now the *only* way to reach those actions.
##
## Rows are hand-built Controls, not an ItemList — ItemList only supports a single text
## column, and each row here needs a right-aligned keybind hint alongside its label.

const NyxNodeBase = preload("res://addons/nyx/nodes/nyx_node.gd")

signal file_menu_selected(id: int)
signal recent_file_selected(id: int)
signal export_pressed
signal export_menu_selected(id: int)
signal live_toggled(on: bool)
signal shortcuts_pressed
signal properties_toggled
signal undo_pressed
signal redo_pressed

var _graph_container: Control

var _card: PanelContainer
var _search_input: LineEdit
var _scroll: ScrollContainer
var _rows_vbox: VBoxContainer
var _item_entries: Array = []       # parallel to rows; null for category headers
var _row_nodes: Array = []          # parallel to rows; the row Control itself
var _commands: Array = []           # full command set built fresh on each open()
var _selected_index: int = -1

var _row_highlight_style: StyleBoxFlat
var _row_empty_style: StyleBoxEmpty
var _category_icons: Dictionary = {}   # category name -> Texture2D

const LABEL_COLOR := Color(0.90, 0.90, 0.90)
const LABEL_SELECTED_COLOR := Color.WHITE
const LABEL_DISABLED_COLOR := Color(1, 1, 1, 0.25)
const HEADER_COLOR := Color("#6BCF96")
const SHORTCUT_COLOR := Color(0.55, 0.58, 0.64)

const CARD_TITLE_FONT_SIZE := 11
const CATEGORY_FONT_SIZE := 10
const ITEM_FONT_SIZE := 10
const SHORTCUT_FONT_SIZE := 9

# Fixed row heights, not content-driven — a Label's natural minimum height comes
# from the font's ascent+descent metrics, which reserves far more vertical space
# than the glyphs actually need at these small sizes. Plain Panel (not
# PanelContainer) never auto-sizes to its children's minimum size (see the
# Panel-vs-Container gotcha), so it's used here deliberately to pin each row to
# an exact height regardless of font metrics.
const ITEM_ROW_HEIGHT := 18
const CATEGORY_ROW_HEIGHT := 16
const ROW_INSET := 4.0

const AUTO_SCROLL_ZONE := 20.0    # px band at the top/bottom of the list that triggers scrolling
const AUTO_SCROLL_SPEED := 300.0  # px/sec while hovering in the zone


func setup(container: Control) -> void:
	_graph_container = container
	_load_category_icons()
	_build()


# Palette categories are a fixed, small set (unlike the search popup's
# NyxRegistry-driven node categories), so this just checks the ones that have
# icon assets.
func _load_category_icons() -> void:
	for category in ["File", "Export", "Edit", "Recent Files", "Live", "View"]:
		var path := "res://addons/nyx/icons/palette/%s.svg" % category.to_lower().replace(" ", "_")
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if not tex:
			continue
		var img := tex.get_image()
		if not img:
			continue
		img.resize(10, 10, Image.INTERPOLATE_LANCZOS)
		for y in img.get_height():
			for x in img.get_width():
				var px := img.get_pixel(x, y)
				if px.a > 0.0:
					img.set_pixel(x, y, Color(1.0, 1.0, 1.0, px.a))
		_category_icons[category] = ImageTexture.create_from_image(img)


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
	card_style.set_corner_radius_all(NyxNodeBase._s(12))
	card_style.set_content_margin_all(NyxNodeBase._s(8))

	_card = PanelContainer.new()
	# Matches the Add Node search popup's card size exactly (raw, unscaled —
	# the taller/wider unscaled size read better than the EDSCALE-shrunk one).
	_card.custom_minimum_size = Vector2(260, 360)
	_card.add_theme_stylebox_override("panel", card_style)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", NyxNodeBase._s(6))

	var header := Label.new()
	header.text = "Commands"
	header.add_theme_color_override("font_color", Color.WHITE)
	header.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	vbox.add_child(header)

	_search_input = LineEdit.new()
	_search_input.placeholder_text = "Type a command..."
	# Explicit shared height with the Add Node search popup's input — the two
	# styleboxes already use identical content margins, but pinning this
	# directly guarantees parity instead of relying on implicit font metrics.
	_search_input.custom_minimum_size.y = 28

	var input_normal := StyleBoxFlat.new()
	input_normal.bg_color = Color(0.20, 0.20, 0.26)
	input_normal.border_color = Color("#31614F")
	input_normal.set_border_width_all(1)
	input_normal.set_corner_radius_all(4)
	input_normal.content_margin_left = 8
	input_normal.content_margin_right = 8
	input_normal.content_margin_top = 5
	input_normal.content_margin_bottom = 5
	_search_input.add_theme_stylebox_override("normal", input_normal)
	_search_input.add_theme_stylebox_override("focus", input_normal)
	_search_input.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	_search_input.add_theme_color_override("font_placeholder_color", Color(0.45, 0.45, 0.52))
	_search_input.add_theme_font_size_override("font_size", ITEM_FONT_SIZE)
	_search_input.text_changed.connect(_on_search_changed)
	_search_input.gui_input.connect(_on_search_input_key)
	vbox.add_child(_search_input)

	# Shared stylebox resources (same object reused across every row) — rows are
	# Panel (not PanelContainer), so insetting/height comes from the row's own
	# fixed size + the label's anchors, not from content_margin here.
	_row_highlight_style = StyleBoxFlat.new()
	_row_highlight_style.bg_color = Color("#31614F")
	_row_highlight_style.set_corner_radius_all(3)

	_row_empty_style = StyleBoxEmpty.new()

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Backstop so a click on a header/disabled row (mouse_filter IGNORE/STOP
	# with no handler) can never fall through to the backdrop and dismiss the
	# palette — mirrors the old ItemList capturing every click in its rect.
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP

	_rows_vbox = VBoxContainer.new()
	_rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_vbox.add_theme_constant_override("separation", 0)
	_scroll.add_child(_rows_vbox)
	vbox.add_child(_scroll)

	_card.add_child(vbox)
	add_child(_card)


func open(context: Dictionary, anchor_global_pos = null) -> void:
	_commands = _build_commands(context)
	_search_input.text = ""
	_populate_grouped()
	size = _graph_container.size
	visible = true
	move_to_front()
	_card.reset_size()
	# Two entry paths: Ctrl+P anchors at the cursor (same convention as the
	# node-search popup); the chrome-bar palette button instead passes its
	# own global position so the card opens dropdown-style, near/under it.
	var target_pos: Vector2
	if anchor_global_pos != null:
		target_pos = _graph_container.get_global_transform().affine_inverse() * anchor_global_pos
	else:
		target_pos = _graph_container.get_local_mouse_position()
	var max_pos := _graph_container.size - _card.size
	_card.position = target_pos.clamp(Vector2.ZERO, max_pos.max(Vector2.ZERO))
	_search_input.call_deferred("grab_focus")


func close() -> void:
	visible = false


func handle_resize() -> void:
	if visible:
		size = _graph_container.size


# Auto-scrolls the list while the cursor hovers within AUTO_SCROLL_ZONE of the
# ScrollContainer's top/bottom edge — geometric check against the mouse
# position rather than a hover-zone Control overlay, since an overlay would
# need to sit on top of the rows to catch the edge but MOUSE_FILTER_PASS only
# bubbles up a control's own parent chain (see the backdrop-dismiss gotcha),
# not sideways into the row tree below it. scroll_vertical self-clamps, so no
# manual range check is needed.
func _process(delta: float) -> void:
	if not visible:
		return
	if _rows_vbox.get_combined_minimum_size().y <= _scroll.size.y:
		return
	var rect := _scroll.get_global_rect()
	var mouse := get_global_mouse_position()
	if not rect.has_point(mouse):
		return
	var local_y := mouse.y - rect.position.y
	if local_y < AUTO_SCROLL_ZONE:
		_scroll.scroll_vertical -= int(AUTO_SCROLL_SPEED * delta)
	elif local_y > rect.size.y - AUTO_SCROLL_ZONE:
		_scroll.scroll_vertical += int(AUTO_SCROLL_SPEED * delta)


# Builds the full command set for this open() call. Context keys: linked (bool),
# live_on (bool), recent_files (Array[String]). Each entry may carry a "shortcut"
# string, rendered as a muted hint on the row's right edge.
func _build_commands(context: Dictionary) -> Array:
	var linked: bool = context.get("linked", false)
	var live_on: bool = context.get("live_on", false)
	var recent_files: Array = context.get("recent_files", [])

	var cmds := []
	cmds.append({"category": "File", "label": "New", "action": "file_menu_selected", "arg": 0, "shortcut": "Ctrl+N"})
	cmds.append({"category": "File", "label": "Open…", "action": "file_menu_selected", "arg": 1, "shortcut": "Ctrl+O"})
	cmds.append({"category": "File", "label": "Save", "action": "file_menu_selected", "arg": 2, "shortcut": "Ctrl+S"})
	cmds.append({"category": "File", "label": "Save As…", "action": "file_menu_selected", "arg": 3, "shortcut": "Ctrl+Shift+S"})

	cmds.append({"category": "Export", "label": ("Update" if linked else "Export…"), "action": "export_pressed", "shortcut": "Ctrl+E"})
	cmds.append({"category": "Export", "label": "Export As… (re-link)", "action": "export_menu_selected", "arg": 2, "shortcut": "Ctrl+Shift+E"})
	cmds.append({"category": "Export", "label": "Export new material", "action": "export_menu_selected", "arg": 0, "disabled": not linked})
	cmds.append({"category": "Export", "label": "Export shader only", "action": "export_menu_selected", "arg": 1})
	cmds.append({"category": "Export", "label": "Unlink", "action": "export_menu_selected", "arg": 3, "disabled": not linked})

	cmds.append({"category": "Edit", "label": "Undo", "action": "undo_pressed"})
	cmds.append({"category": "Edit", "label": "Redo", "action": "redo_pressed"})

	cmds.append({"category": "View", "label": "Toggle Properties Panel", "action": "properties_toggled"})
	cmds.append({"category": "View", "label": "Keyboard Shortcuts", "action": "shortcuts_pressed", "shortcut": "?"})

	if linked:
		var live_label := "Disable Live Link" if live_on else "Enable Live Link"
		cmds.append({"category": "Live", "label": live_label, "action": "live_toggled", "arg": not live_on})
	else:
		cmds.append({"category": "Live", "label": "Live Link (link a shader first)", "action": "", "disabled": true})

	if recent_files.is_empty():
		cmds.append({"category": "Recent Files", "label": "(empty)", "action": "", "disabled": true})
	else:
		for i in recent_files.size():
			cmds.append({
				"category": "Recent Files",
				"label": (recent_files[i] as String).get_file(),
				"action": "recent_file_selected",
				"arg": i,
			})

	return cmds


# remove_child (synchronous detach) before queue_free (deferred cleanup) —
# queue_free alone leaves the old rows as children for the rest of the frame,
# so a populate-then-repopulate in the same call would briefly double them up.
func _clear_rows() -> void:
	for child in _rows_vbox.get_children():
		_rows_vbox.remove_child(child)
		child.queue_free()
	_item_entries.clear()
	_row_nodes.clear()
	_selected_index = -1


func _populate_grouped() -> void:
	_clear_rows()
	var seen_categories: Array = []
	for cmd in _commands:
		if not seen_categories.has(cmd["category"]):
			seen_categories.append(cmd["category"])
	for category in seen_categories:
		_add_header_row(category)
		for cmd in _commands:
			if cmd["category"] == category:
				_add_item_row(cmd)


func _populate_filtered(query: String) -> void:
	_clear_rows()
	for cmd in _commands:
		if _fuzzy_match(query, cmd["label"]) or _fuzzy_match(query, cmd["category"]):
			_add_item_row(cmd)
	if _item_entries.size() > 0:
		_select_index(0)


# Anchors `control` to span the row horizontally (inset by `inset` on each
# side) but, vertically, only to its own natural content height, centered —
# NOT stretched to fill the row's fixed height. Forcing a Label/HBoxContainer
# to fill a row shorter than the font's natural line height and relying on
# vertical_alignment=CENTER to compensate reads as bottom-heavy in practice;
# anchoring to the real content height sidesteps that entirely. Call this
# after all children are added so get_combined_minimum_size() is final.
func _center_row_content(control: Control, inset: float) -> void:
	control.anchor_left = 0.0
	control.anchor_right = 1.0
	control.offset_left = inset
	control.offset_right = -inset
	var h: float = control.get_combined_minimum_size().y
	control.anchor_top = 0.5
	control.anchor_bottom = 0.5
	control.offset_top = -h / 2.0
	control.offset_bottom = h / 2.0


func _add_header_row(category: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)

	if _category_icons.has(category):
		var icon_rect := TextureRect.new()
		icon_rect.texture = _category_icons[category]
		icon_rect.custom_minimum_size = Vector2(10, 10)
		# Default stretch_mode (STRETCH_SCALE) fills whatever rect the HBoxContainer's
		# cross-axis stretch hands it, distorting the square texture — pin it to keep
		# aspect and never grow past its own minimum size.
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.modulate = HEADER_COLOR
		hbox.add_child(icon_rect)

	var label := Label.new()
	label.text = category
	label.add_theme_color_override("font_color", HEADER_COLOR)
	label.add_theme_font_size_override("font_size", CATEGORY_FONT_SIZE)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(label)
	_center_row_content(hbox, ROW_INSET)

	var row := Panel.new()
	row.custom_minimum_size = Vector2(0, CATEGORY_ROW_HEIGHT)
	row.clip_contents = true
	row.add_theme_stylebox_override("panel", _row_empty_style)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(hbox)
	_rows_vbox.add_child(row)

	_item_entries.append(null)
	_row_nodes.append(row)


func _add_item_row(cmd: Dictionary) -> void:
	var disabled: bool = cmd.get("disabled", false)

	var row := Panel.new()
	row.custom_minimum_size = Vector2(0, ITEM_ROW_HEIGHT)
	row.clip_contents = true
	row.add_theme_stylebox_override("panel", _row_empty_style)
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "  " + cmd["label"]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_color_override("font_color", LABEL_DISABLED_COLOR if disabled else LABEL_COLOR)
	label.add_theme_font_size_override("font_size", ITEM_FONT_SIZE)
	hbox.add_child(label)
	row.set_meta("main_label", label)

	var shortcut: String = cmd.get("shortcut", "")
	if not shortcut.is_empty():
		var hint := Label.new()
		hint.text = shortcut
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", SHORTCUT_FONT_SIZE)
		hint.add_theme_color_override("font_color", SHORTCUT_COLOR)
		hbox.add_child(hint)

	_center_row_content(hbox, ROW_INSET)
	row.add_child(hbox)
	_rows_vbox.add_child(row)

	var idx := _item_entries.size()
	_item_entries.append(cmd)
	_row_nodes.append(row)

	if not disabled:
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
			prev_label.add_theme_color_override("font_color", LABEL_COLOR)
	_selected_index = idx
	if idx >= 0 and idx < _row_nodes.size():
		var row: Control = _row_nodes[idx]
		row.add_theme_stylebox_override("panel", _row_highlight_style)
		var label: Label = row.get_meta("main_label", null)
		if label:
			label.add_theme_color_override("font_color", LABEL_SELECTED_COLOR)
		_scroll.ensure_control_visible(row)


func _fuzzy_match(query: String, candidate: String) -> bool:
	query = query.to_lower()
	candidate = candidate.to_lower()
	var qi := 0
	for c in candidate:
		if qi < query.length() and c == query[qi]:
			qi += 1
	return qi == query.length()


func _is_unselectable(idx: int) -> bool:
	var entry = _item_entries[idx]
	return entry == null or entry.get("disabled", false)


func _move_selection(delta: int) -> void:
	var count := _item_entries.size()
	if count == 0:
		return
	var idx: int = _selected_index + delta if _selected_index >= 0 else (0 if delta > 0 else count - 1)
	while idx >= 0 and idx < count and _is_unselectable(idx):
		idx += delta
	if idx < 0 or idx >= count:
		return
	_select_index(idx)


func _confirm_selection() -> void:
	if _selected_index < 0 or _selected_index >= _item_entries.size():
		return
	var entry = _item_entries[_selected_index]
	if entry == null or entry.get("disabled", false):
		return
	_run(entry)


func _run(entry: Dictionary) -> void:
	close()
	match entry["action"]:
		"file_menu_selected": file_menu_selected.emit(entry["arg"])
		"recent_file_selected": recent_file_selected.emit(entry["arg"])
		"export_pressed": export_pressed.emit()
		"export_menu_selected": export_menu_selected.emit(entry["arg"])
		"live_toggled": live_toggled.emit(entry["arg"])
		"shortcuts_pressed": shortcuts_pressed.emit()
		"properties_toggled": properties_toggled.emit()
		"undo_pressed": undo_pressed.emit()
		"redo_pressed": redo_pressed.emit()


func _on_search_changed(text: String) -> void:
	if text.is_empty():
		_populate_grouped()
	else:
		_populate_filtered(text)


func _on_search_input_key(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_DOWN:
			_move_selection(1)
			_search_input.accept_event()
		KEY_UP:
			_move_selection(-1)
			_search_input.accept_event()
		KEY_ENTER, KEY_KP_ENTER:
			_confirm_selection()
			_search_input.accept_event()
		KEY_ESCAPE:
			close()
			_search_input.accept_event()
