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
var _list: ItemList
var _item_entries: Array = []       # parallel to list rows; null for category headers
var _commands: Array = []           # full command set built fresh on each open()


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
	card_style.bg_color = Color(0.14, 0.14, 0.18, 0.95)
	card_style.border_color = Color("#31614F")
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(NyxNodeBase._s(12))
	card_style.set_content_margin_all(NyxNodeBase._s(8))

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(NyxNodeBase._s(420), NyxNodeBase._s(360))
	_card.add_theme_stylebox_override("panel", card_style)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", NyxNodeBase._s(6))

	var header := Label.new()
	header.text = "Commands"
	header.add_theme_color_override("font_color", Color.WHITE)
	header.add_theme_font_size_override("font_size", 13)
	vbox.add_child(header)

	_search_input = LineEdit.new()
	_search_input.placeholder_text = "Type a command..."

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
	_search_input.text_changed.connect(_on_search_changed)
	_search_input.gui_input.connect(_on_search_input_key)
	vbox.add_child(_search_input)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var list_bg := StyleBoxFlat.new()
	list_bg.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	list_bg.set_border_width_all(0)
	_list.add_theme_stylebox_override("panel", list_bg)

	var highlight := StyleBoxFlat.new()
	highlight.bg_color = Color("#31614F")
	highlight.set_corner_radius_all(3)
	highlight.content_margin_left = 4
	highlight.content_margin_right = 4
	for state in ["selected", "selected_focus", "hovered_selected", "hovered_selected_focus"]:
		_list.add_theme_stylebox_override(state, highlight)
	_list.add_theme_stylebox_override("hovered", StyleBoxEmpty.new())

	_list.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90))
	_list.add_theme_color_override("font_selected_color", Color.WHITE)
	_list.add_theme_color_override("font_hovered_color", Color.WHITE)
	_list.add_theme_color_override("font_disabled_color", Color("#6BCF96"))

	_list.item_selected.connect(func(_i: int) -> void: pass)
	_list.gui_input.connect(_on_list_hover)
	vbox.add_child(_list)

	_card.add_child(vbox)
	add_child(_card)


func open(context: Dictionary) -> void:
	_commands = _build_commands(context)
	_search_input.text = ""
	_populate_grouped()
	size = _graph_container.size
	visible = true
	move_to_front()
	_card.reset_size()
	_card.position = ((_graph_container.size - _card.size) * Vector2(0.5, 0.32)).max(Vector2.ZERO)
	_search_input.call_deferred("grab_focus")


func close() -> void:
	visible = false


func handle_resize() -> void:
	if visible:
		size = _graph_container.size


# Builds the full command set for this open() call. Context keys: linked (bool),
# live_on (bool), recent_files (Array[String]).
func _build_commands(context: Dictionary) -> Array:
	var linked: bool = context.get("linked", false)
	var live_on: bool = context.get("live_on", false)
	var recent_files: Array = context.get("recent_files", [])

	var cmds := []
	cmds.append({"category": "File", "label": "New", "action": "file_menu_selected", "arg": 0})
	cmds.append({"category": "File", "label": "Open…", "action": "file_menu_selected", "arg": 1})
	cmds.append({"category": "File", "label": "Save", "action": "file_menu_selected", "arg": 2})
	cmds.append({"category": "File", "label": "Save As…", "action": "file_menu_selected", "arg": 3})

	cmds.append({"category": "Export", "label": ("Update" if linked else "Export…"), "action": "export_pressed"})
	cmds.append({"category": "Export", "label": "Export As… (re-link)", "action": "export_menu_selected", "arg": 2})
	cmds.append({"category": "Export", "label": "Export new material", "action": "export_menu_selected", "arg": 0, "disabled": not linked})
	cmds.append({"category": "Export", "label": "Export shader only", "action": "export_menu_selected", "arg": 1})
	cmds.append({"category": "Export", "label": "Unlink", "action": "export_menu_selected", "arg": 3, "disabled": not linked})

	cmds.append({"category": "Edit", "label": "Undo", "action": "undo_pressed"})
	cmds.append({"category": "Edit", "label": "Redo", "action": "redo_pressed"})

	cmds.append({"category": "View", "label": "Toggle Properties Panel", "action": "properties_toggled"})
	cmds.append({"category": "View", "label": "Keyboard Shortcuts", "action": "shortcuts_pressed"})

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


func _populate_grouped() -> void:
	_list.clear()
	_item_entries.clear()
	var seen_categories: Array = []
	for cmd in _commands:
		if not seen_categories.has(cmd["category"]):
			seen_categories.append(cmd["category"])
	for category in seen_categories:
		var header_idx: int = _list.add_item(category)
		_list.set_item_disabled(header_idx, true)
		_list.set_item_custom_fg_color(header_idx, Color("#6BCF96"))
		_item_entries.append(null)
		for cmd in _commands:
			if cmd["category"] != category:
				continue
			var item_idx := _list.add_item("  " + cmd["label"])
			_item_entries.append(cmd)
			if cmd.get("disabled", false):
				_list.set_item_disabled(item_idx, true)
				_list.set_item_custom_fg_color(item_idx, Color(1, 1, 1, 0.25))


func _populate_filtered(query: String) -> void:
	_list.clear()
	_item_entries.clear()
	for cmd in _commands:
		if _fuzzy_match(query, cmd["label"]) or _fuzzy_match(query, cmd["category"]):
			var item_idx := _list.add_item(cmd["label"])
			_item_entries.append(cmd)
			if cmd.get("disabled", false):
				_list.set_item_disabled(item_idx, true)
				_list.set_item_custom_fg_color(item_idx, Color(1, 1, 1, 0.25))
	if _list.item_count > 0:
		_list.select(0)


func _fuzzy_match(query: String, candidate: String) -> bool:
	query = query.to_lower()
	candidate = candidate.to_lower()
	var qi := 0
	for c in candidate:
		if qi < query.length() and c == query[qi]:
			qi += 1
	return qi == query.length()


func _move_selection(delta: int) -> void:
	var count := _list.item_count
	if count == 0:
		return
	var sel := _list.get_selected_items()
	var idx: int = sel[0] + delta if not sel.is_empty() else (0 if delta > 0 else count - 1)
	while idx >= 0 and idx < count and _list.is_item_disabled(idx):
		idx += delta
	if idx < 0 or idx >= count:
		return
	_list.select(idx)
	_list.ensure_current_is_visible()


func _confirm_selection() -> void:
	var sel := _list.get_selected_items()
	if sel.is_empty():
		return
	var entry = _item_entries[sel[0]]
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


func _on_list_hover(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var idx := _list.get_item_at_position(event.position, true)
		if idx >= 0 and not _list.is_item_disabled(idx):
			_list.select(idx)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var idx := _list.get_item_at_position(event.position, true)
		if idx >= 0 and not _list.is_item_disabled(idx):
			var entry = _item_entries[idx]
			if entry != null:
				_run(entry)
				get_viewport().set_input_as_handled()
