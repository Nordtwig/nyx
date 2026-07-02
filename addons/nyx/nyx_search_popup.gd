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

const NyxRegistry = preload("res://addons/nyx/nyx_registry.gd")

signal node_chosen(id: int)

var _graph_container: Control          # graph area, for sizing + cursor-relative placement
var _shader_type: int = 0              # current mode, set on each open() — drives gating
var _category_icons: Dictionary = {}

var _search_cards: HBoxContainer       # the floating [search | doc] cards, positioned at cursor
var _search_input: LineEdit
var _search_list: ItemList
var _search_item_ids: Array = []
var _doc_panel: PanelContainer
var _doc_label: RichTextLabel
var _doc_hover_timer: Timer
var _doc_pending_id: int = -1


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
		img.resize(14, 14, Image.INTERPOLATE_LANCZOS)
		for y in img.get_height():
			for x in img.get_width():
				var px := img.get_pixel(x, y)
				if px.a > 0.0:
					img.set_pixel(x, y, Color(1.0, 1.0, 1.0, px.a))
		# Add 2 transparent rows at bottom — shifts visual content up when ItemList centers the icon.
		var padded := Image.create(14, 20, false, Image.FORMAT_RGBA8)
		padded.blit_rect(img, Rect2i(0, 0, 14, 14), Vector2i(0, 2))
		_category_icons[cat_name] = ImageTexture.create_from_image(padded)


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
	header.add_theme_font_size_override("font_size", 13)
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
	_search_input.text_changed.connect(_on_search_changed)
	_search_input.gui_input.connect(_on_search_input_key)
	vbox.add_child(_search_input)

	_search_list = ItemList.new()
	_search_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_search_list.add_theme_constant_override("icon_max_width", 12)

	var list_bg := StyleBoxFlat.new()
	list_bg.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	list_bg.set_border_width_all(0)
	_search_list.add_theme_stylebox_override("panel", list_bg)

	# Hovering an item auto-selects it (see _on_search_list_hover), so the visible
	# style for a hovered row is actually "hovered_selected" — all selection/hover
	# states must be overridden to Hunter green or the editor's muddy default bleeds
	# through. One shared green stylebox covers every highlighted state.
	var highlight := StyleBoxFlat.new()
	highlight.bg_color = Color("#31614F")
	highlight.set_corner_radius_all(3)
	highlight.content_margin_left = 4
	highlight.content_margin_right = 4
	for state in ["selected", "selected_focus", "hovered_selected", "hovered_selected_focus"]:
		_search_list.add_theme_stylebox_override(state, highlight)
	# Plain "hovered" (mouse over a row that ISN'T selected) only ever applies to the
	# disabled category headers — real node rows auto-select on hover (→ hovered_selected,
	# above). Keep it empty so categories don't get the green fill.
	_search_list.add_theme_stylebox_override("hovered", StyleBoxEmpty.new())

	_search_list.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90))
	_search_list.add_theme_color_override("font_selected_color", Color.WHITE)
	_search_list.add_theme_color_override("font_hovered_color", Color.WHITE)
	_search_list.add_theme_color_override("font_disabled_color", Color("#6BCF96"))

	_search_list.item_selected.connect(_on_search_item_selected_by_mouse)
	_search_list.gui_input.connect(_on_search_list_hover)
	vbox.add_child(_search_list)

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


func _populate_search_grouped() -> void:
	_search_list.clear()
	_search_item_ids.clear()
	for category in NyxRegistry.NODE_REGISTRY:
		var cat_name: String = category["category"]
		var header_idx: int = _search_list.add_item(category["category"])
		_search_list.set_item_disabled(header_idx, true)
		_search_item_ids.append(-1)
		_search_list.set_item_custom_fg_color(header_idx, Color("#6BCF96"))
		if _category_icons.has(cat_name):
			_search_list.set_item_icon(header_idx, _category_icons[cat_name])
			_search_list.set_item_icon_modulate(header_idx, Color("#6BCF96"))
		for entry in category["nodes"]:
			var item_idx := _search_list.add_item("  " + entry["label"])
			_search_item_ids.append(entry["id"])
			if _is_node_unavailable(entry):
				_search_list.set_item_disabled(item_idx, true)
				_search_list.set_item_custom_fg_color(item_idx, Color(1, 1, 1, 0.25))


func _populate_search_filtered(query: String) -> void:
	_search_list.clear()
	_search_item_ids.clear()
	for category in NyxRegistry.NODE_REGISTRY:
		var category_matches := _fuzzy_match(query, category["category"])
		var cat_name: String = category["category"]
		for entry in category["nodes"]:
			if category_matches or _fuzzy_match(query, entry["label"]):
				var item_idx := _search_list.add_item(entry["label"])
				_search_item_ids.append(entry["id"])
				if _is_node_unavailable(entry):
					_search_list.set_item_disabled(item_idx, true)
					_search_list.set_item_custom_fg_color(item_idx, Color(1, 1, 1, 0.25))
	if _search_list.item_count > 0:
		_search_list.select(0)


func _fuzzy_match(query: String, candidate: String) -> bool:
	query = query.to_lower()
	candidate = candidate.to_lower()
	var qi := 0
	for c in candidate:
		if qi < query.length() and c == query[qi]:
			qi += 1
	return qi == query.length()


func _move_search_selection(delta: int) -> void:
	var count := _search_list.item_count
	if count == 0:
		return
	var sel := _search_list.get_selected_items()
	var idx: int = sel[0] + delta if not sel.is_empty() else (0 if delta > 0 else count - 1)
	while idx >= 0 and idx < count and _search_list.is_item_disabled(idx):
		idx += delta
	if idx < 0 or idx >= count:
		return
	_search_list.select(idx)
	_search_list.ensure_current_is_visible()
	_show_doc_for(_search_item_ids[idx])


func _confirm_search_selection() -> void:
	var sel := _search_list.get_selected_items()
	if sel.is_empty():
		return
	var id: int = _search_item_ids[sel[0]]
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


func _on_search_item_selected_by_mouse(index: int) -> void:
	_show_doc_for(_search_item_ids[index])


func _on_search_list_hover(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var idx := _search_list.get_item_at_position(event.position, true)
		if idx >= 0 and not _search_list.is_item_disabled(idx):
			_search_list.select(idx)
			_show_doc_for(_search_item_ids[idx])
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var idx := _search_list.get_item_at_position(event.position, true)
		if idx >= 0 and not _search_list.is_item_disabled(idx):
			var id: int = _search_item_ids[idx]
			if id >= 0:
				close()
				node_chosen.emit(id)
				get_viewport().set_input_as_handled()


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
