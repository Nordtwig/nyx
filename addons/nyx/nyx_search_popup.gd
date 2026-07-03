@tool
extends Control

## Nyx node-search popup — the "Add Node" overlay (search card + hover doc card).
##
## A self-contained Control subtree, NOT a popup window: rendered as plain overlays in
## the main viewport so the live graph shows through the gap between the two cards (an
## embedded popup window has no per-pixel transparency → opaque gap). This node IS the
## full-graph overlay; it owns its backdrop, cards, doc panel, hover timer and category
## icons outright.
##
## One-way dependency on nyx_main: the popup emits `node_chosen(id)` when the user picks
## a node; nyx_main listens and spawns it (push-undo + factory). The popup never reaches
## back into nyx_main — it pulls its catalog from NyxRegistry and reads graph geometry
## from the `_graph_container` reference handed to `setup()`. Extracted from nyx_main.gd.
##
## Rows are hand-built Controls, not an ItemList — matches nyx_command_palette.gd's row
## approach exactly (same style constants) so the two overlays share one visual language.

const NyxRegistry = preload("res://addons/nyx/nyx_registry.gd")

signal node_chosen(id: int)

var _graph_container: Control          # graph area, for sizing + cursor-relative placement
var _shader_type: int = 0              # current mode, set on each open() — drives gating
var _category_icons: Dictionary = {}

var _search_cards: HBoxContainer       # the floating [search | doc] cards, positioned at cursor
var _search_input: LineEdit
var _scroll: ScrollContainer
var _rows_vbox: VBoxContainer
var _search_item_ids: Array = []       # parallel to rows; -1 for category headers
var _row_selectable: Array = []        # parallel to rows; false for headers + disabled entries
var _row_nodes: Array = []             # parallel to rows; the row Control itself
var _selected_index: int = -1

var _row_highlight_style: StyleBoxFlat
var _row_empty_style: StyleBoxEmpty

var _doc_panel: PanelContainer
var _doc_label: RichTextLabel
var _doc_hover_timer: Timer
var _doc_pending_id: int = -1

const HEADER_COLOR := Color("#6BCF96")
const LABEL_COLOR := Color(0.90, 0.90, 0.90)
const LABEL_SELECTED_COLOR := Color.WHITE
const LABEL_DISABLED_COLOR := Color(1, 1, 1, 0.25)

const CARD_TITLE_FONT_SIZE := 11
const CATEGORY_FONT_SIZE := 10
const ITEM_FONT_SIZE := 10

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


# Called once by nyx_main right after instancing + add_child. Stores the graph-container
# reference (geometry source), loads the category icons, and builds the overlay UI.
func setup(container: Control) -> void:
	_graph_container = container
	_load_category_icons()
	_build()


func _load_category_icons() -> void:
	for category in NyxRegistry.NODE_REGISTRY:
		var cat_name: String = category["category"]
		if _category_icons.has(cat_name):
			continue
		var path := "res://addons/nyx/icons/categories/%s.svg" % cat_name.to_lower()
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
		_category_icons[cat_name] = ImageTexture.create_from_image(img)


func _build() -> void:
	# This node IS the overlay. Structure: [backdrop, cards]. The backdrop is a full-rect
	# STOP control (child 0) whose only job is to dismiss on a press in the empty surround.
	# The cards (child 1) render on top, so a click on the search list reaches the list
	# first and the backdrop only catches clicks that miss the cards.
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

	# HBox: [search card | doc card (hidden until hover)]. No background — the gap and
	# surround show the graph through.
	var hbox := HBoxContainer.new()
	_search_cards = hbox
	hbox.add_theme_constant_override("separation", 10)

	# --- Search card ---
	# Styled to read like a node: monochrome dark body, the node asymmetric corners
	# (TL6/TR12/BL12/BR6), a hunter-green border accent (the card is the active thing
	# while open), and a titlebar-style "Add Node" header with a hunter-green divider.
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.14, 0.14, 0.18, 0.92)
	card_style.border_color = Color(0.24, 0.24, 0.30)
	card_style.set_border_width_all(1)
	# The search card sits on the LEFT — round its outer (left) corners hard, keep the
	# inner (right) corners tight so the pair reads as one unit opening outward.
	card_style.corner_radius_top_left = 18
	card_style.corner_radius_top_right = 3
	card_style.corner_radius_bottom_left = 18
	card_style.corner_radius_bottom_right = 3
	card_style.set_content_margin_all(8)

	var search_card := PanelContainer.new()
	search_card.custom_minimum_size = Vector2(260, 360)
	search_card.add_theme_stylebox_override("panel", card_style)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)

	var header := Label.new()
	header.text = "Add Node"
	header.add_theme_color_override("font_color", Color.WHITE)
	header.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	vbox.add_child(header)

	_search_input = LineEdit.new()
	_search_input.placeholder_text = "Search nodes..."
	# Explicit shared height with the command palette's input — the two
	# styleboxes already use identical content margins, but pinning this
	# directly guarantees parity instead of relying on implicit font metrics.
	_search_input.custom_minimum_size.y = 28

	var input_normal := StyleBoxFlat.new()
	input_normal.bg_color = Color(0.20, 0.20, 0.26)
	input_normal.border_color = Color(0.35, 0.35, 0.45)
	input_normal.set_border_width_all(1)
	input_normal.set_corner_radius_all(4)
	input_normal.content_margin_left = 8
	input_normal.content_margin_right = 8
	input_normal.content_margin_top = 5
	input_normal.content_margin_bottom = 5

	var input_focus := StyleBoxFlat.new()
	input_focus.bg_color = Color(0.20, 0.20, 0.26)
	input_focus.border_color = Color("#31614F")
	input_focus.set_border_width_all(1)
	input_focus.set_corner_radius_all(4)
	input_focus.content_margin_left = 8
	input_focus.content_margin_right = 8
	input_focus.content_margin_top = 5
	input_focus.content_margin_bottom = 5

	_search_input.add_theme_stylebox_override("normal", input_normal)
	_search_input.add_theme_stylebox_override("focus", input_focus)
	_search_input.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	_search_input.add_theme_color_override("font_placeholder_color", Color(0.45, 0.45, 0.52))
	_search_input.add_theme_font_size_override("font_size", ITEM_FONT_SIZE)
	_search_input.text_changed.connect(_on_search_changed)
	_search_input.gui_input.connect(_on_search_input_key)
	vbox.add_child(_search_input)

	# Shared stylebox resources (same object reused across every row) — rows are
	# Panel (not PanelContainer), so insetting/height comes from the row's own
	# fixed size + the label's anchors, not from content_margin here. Same
	# values as nyx_command_palette.gd's rows, so the two overlays read as one
	# shared visual language.
	_row_highlight_style = StyleBoxFlat.new()
	_row_highlight_style.bg_color = Color("#31614F")
	_row_highlight_style.set_corner_radius_all(3)

	_row_empty_style = StyleBoxEmpty.new()

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Backstop so a click on a header/disabled row (mouse_filter IGNORE/STOP with
	# no handler) can never fall through to the backdrop and dismiss the popup.
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP

	_rows_vbox = VBoxContainer.new()
	_rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_vbox.add_theme_constant_override("separation", 0)
	_scroll.add_child(_rows_vbox)
	vbox.add_child(_scroll)

	search_card.add_child(vbox)
	hbox.add_child(search_card)

	# Doc panel — plain PanelContainer, not a Popup. Sits beside the search list in
	# the same window so it never participates in the popup stack and never eats clicks.
	_doc_panel = PanelContainer.new()
	_doc_panel.custom_minimum_size = Vector2(260, 0)
	_doc_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_doc_panel.visible = false
	_doc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var doc_panel_style := StyleBoxFlat.new()
	doc_panel_style.bg_color = Color(0.14, 0.14, 0.18, 0.92)
	doc_panel_style.border_color = Color(0.24, 0.24, 0.30)
	doc_panel_style.set_border_width_all(1)
	# The doc card sits on the RIGHT — mirror of the search card: round its outer
	# (right) corners hard, keep the inner (left) corners tight.
	doc_panel_style.corner_radius_top_left = 3
	doc_panel_style.corner_radius_top_right = 18
	doc_panel_style.corner_radius_bottom_left = 3
	doc_panel_style.corner_radius_bottom_right = 18
	_doc_panel.add_theme_stylebox_override("panel", doc_panel_style)

	var doc_margin := MarginContainer.new()
	doc_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	doc_margin.add_theme_constant_override("margin_left", 12)
	doc_margin.add_theme_constant_override("margin_right", 10)
	doc_margin.add_theme_constant_override("margin_top", 10)
	doc_margin.add_theme_constant_override("margin_bottom", 10)

	_doc_label = RichTextLabel.new()
	_doc_label.bbcode_enabled = true
	_doc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_doc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_doc_label.scroll_active = true
	_doc_label.add_theme_color_override("default_color", Color(0.88, 0.88, 0.92))

	var doc_bg := StyleBoxFlat.new()
	doc_bg.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	doc_bg.set_border_width_all(0)
	_doc_label.add_theme_stylebox_override("normal", doc_bg)

	doc_margin.add_child(_doc_label)
	_doc_panel.add_child(doc_margin)
	hbox.add_child(_doc_panel)

	add_child(hbox)

	_doc_hover_timer = Timer.new()
	_doc_hover_timer.one_shot = true
	_doc_hover_timer.wait_time = 0.4
	_doc_hover_timer.timeout.connect(_on_doc_hover_timeout)
	add_child(_doc_hover_timer)


func open(shader_type: int) -> void:
	_shader_type = shader_type
	_search_input.text = ""
	_populate_search_grouped()
	_doc_label.clear()
	_doc_panel.hide()
	# Cover the whole graph area so the catcher can dismiss on any outside click.
	size = _graph_container.size
	visible = true
	move_to_front()
	_search_cards.reset_size()
	# Anchor the cards at the cursor, clamped so they stay on-screen.
	var local_mouse := _graph_container.get_local_mouse_position()
	var max_pos := _graph_container.size - _search_cards.size
	_search_cards.position = local_mouse.clamp(Vector2.ZERO, max_pos.max(Vector2.ZERO))
	_search_input.call_deferred("grab_focus")


func close() -> void:
	visible = false
	_doc_panel.hide()
	_doc_hover_timer.stop()


# Keeps the overlay sized to the graph area while it's open (nyx_main forwards its resize).
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


func _is_node_unavailable(entry: Dictionary) -> bool:
	if _shader_type == 2:
		# Particle mode: only particle nodes plus nodes that operate on plain
		# values. Anything fragment/UV/screen/canvas-bound is meaningless here.
		if entry.get("particle_only", false):
			return false
		return entry.get("particle_unsafe", false) \
			or entry.get("spatial_only", false) \
			or entry.get("canvas_only", false)
	# Spatial / canvas modes: particle nodes are never available.
	if entry.get("particle_only", false):
		return true
	return (entry.get("spatial_only", false) and _shader_type == 1) or \
		   (entry.get("canvas_only", false) and _shader_type == 0)


# remove_child (synchronous detach) before queue_free (deferred cleanup) — queue_free
# alone leaves the old rows as children for the rest of the frame, so a populate-then-
# repopulate in the same call would briefly double them up.
func _clear_rows() -> void:
	for child in _rows_vbox.get_children():
		_rows_vbox.remove_child(child)
		child.queue_free()
	_search_item_ids.clear()
	_row_selectable.clear()
	_row_nodes.clear()
	_selected_index = -1


func _populate_search_grouped() -> void:
	_clear_rows()
	for category in NyxRegistry.NODE_REGISTRY:
		var cat_name: String = category["category"]
		_add_header_row(cat_name, _category_icons.get(cat_name))
		for entry in category["nodes"]:
			_add_item_row(entry)


func _populate_search_filtered(query: String) -> void:
	_clear_rows()
	for category in NyxRegistry.NODE_REGISTRY:
		var category_matches := _fuzzy_match(query, category["category"])
		for entry in category["nodes"]:
			if category_matches or _fuzzy_match(query, entry["label"]):
				_add_item_row(entry)
	if _search_item_ids.size() > 0:
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


func _add_header_row(category: String, icon) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	if icon:
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon
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

	_search_item_ids.append(-1)
	_row_selectable.append(false)
	_row_nodes.append(row)


func _add_item_row(entry: Dictionary) -> void:
	var disabled := _is_node_unavailable(entry)

	var row := Panel.new()
	row.custom_minimum_size = Vector2(0, ITEM_ROW_HEIGHT)
	row.clip_contents = true
	row.add_theme_stylebox_override("panel", _row_empty_style)
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	var label := Label.new()
	label.text = "  " + entry["label"]
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_color_override("font_color", LABEL_DISABLED_COLOR if disabled else LABEL_COLOR)
	label.add_theme_font_size_override("font_size", ITEM_FONT_SIZE)
	_center_row_content(label, ROW_INSET)
	row.add_child(label)
	row.set_meta("main_label", label)
	_rows_vbox.add_child(row)

	var idx := _search_item_ids.size()
	_search_item_ids.append(entry["id"])
	_row_selectable.append(not disabled)
	_row_nodes.append(row)

	if not disabled:
		row.mouse_entered.connect(_select_index.bind(idx))
		row.gui_input.connect(_on_row_gui_input.bind(idx))


func _on_row_gui_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_index(idx)
		_confirm_search_selection()
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
		_show_doc_for(_search_item_ids[idx])


func _fuzzy_match(query: String, candidate: String) -> bool:
	query = query.to_lower()
	candidate = candidate.to_lower()
	var qi := 0
	for c in candidate:
		if qi < query.length() and c == query[qi]:
			qi += 1
	return qi == query.length()


func _is_unselectable(idx: int) -> bool:
	return not _row_selectable[idx]


func _move_search_selection(delta: int) -> void:
	var count := _search_item_ids.size()
	if count == 0:
		return
	var idx: int = _selected_index + delta if _selected_index >= 0 else (0 if delta > 0 else count - 1)
	while idx >= 0 and idx < count and _is_unselectable(idx):
		idx += delta
	if idx < 0 or idx >= count:
		return
	_select_index(idx)


func _confirm_search_selection() -> void:
	if _selected_index < 0 or _selected_index >= _search_item_ids.size():
		return
	var id: int = _search_item_ids[_selected_index]
	if id < 0:
		return
	close()
	node_chosen.emit(id)


func _on_search_changed(text: String) -> void:
	if text.is_empty():
		_populate_search_grouped()
	else:
		_populate_search_filtered(text)


func _on_search_input_key(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_DOWN:
			_move_search_selection(1)
			_search_input.accept_event()
		KEY_UP:
			_move_search_selection(-1)
			_search_input.accept_event()
		KEY_ENTER, KEY_KP_ENTER, KEY_RIGHT:
			_confirm_search_selection()
			_search_input.accept_event()
		KEY_ESCAPE:
			close()
			_search_input.accept_event()


func _show_doc_for(id: int) -> void:
	if _doc_panel.visible:
		_update_doc_panel(id)
	else:
		_doc_pending_id = id
		_doc_hover_timer.start()


func _on_doc_hover_timeout() -> void:
	_update_doc_panel(_doc_pending_id)


func _estimate_doc_height(entry: Dictionary) -> int:
	var h := 38
	if entry.has("description"):
		h += maxi(44, int((entry["description"] as String).length() / 38.0) * 18)
	if entry.has("ports"):
		h += 20 + (entry["ports"] as Array).size() * 18
	if entry.has("uses"):
		h += 20 + (entry["uses"] as Array).size() * 18
	return clampi(h + 10, 50, 480)


func _get_node_entry(id: int) -> Dictionary:
	for category in NyxRegistry.NODE_REGISTRY:
		for entry in category["nodes"]:
			if entry["id"] == id:
				return entry
	return {}


func _update_doc_panel(id: int) -> void:
	_doc_label.clear()
	if id < 0:
		if _doc_panel.visible:
			_doc_panel.hide()
			_search_cards.reset_size()
		return
	var entry := _get_node_entry(id)
	if entry.is_empty():
		if _doc_panel.visible:
			_doc_panel.hide()
			_search_cards.reset_size()
		return

	_doc_label.append_text("[b]" + entry["label"] + "[/b]\n")
	if entry.has("summary"):
		_doc_label.append_text("\n[color=#4AAF78]" + entry["summary"] + "[/color]\n")
	if entry.has("description"):
		_doc_label.append_text("\n" + entry["description"] + "\n")
	if entry.has("ports") and not (entry["ports"] as Array).is_empty():
		_doc_label.append_text("\n[b]Ports[/b]\n")
		for port in entry["ports"]:
			_doc_label.append_text("  • " + port + "\n")
	if entry.has("uses") and not (entry["uses"] as Array).is_empty():
		_doc_label.append_text("\n[b]Good for[/b]\n")
		for use in entry["uses"]:
			_doc_label.append_text("  • " + use + "\n")

	if not _doc_panel.visible:
		_doc_panel.show()
		_search_cards.reset_size()
		# Keep the widened cards on-screen (doc opens to the right).
		var max_x := _graph_container.size.x - _search_cards.size.x
		_search_cards.position.x = minf(_search_cards.position.x, maxf(max_x, 0.0))
	_search_input.grab_focus()
