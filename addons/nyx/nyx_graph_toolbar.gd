@tool
extends PanelContainer

## Nyx graph toolbar — owns the top toolbar UI and its widget refs.
##
## Communicates purely via signals (intent out) and public update methods (state in).
## nyx_main connects the signals and calls the update methods; the toolbar never reaches
## back in. Extracted from nyx_main.gd.
##
## Signal flow: user action → toolbar emits signal → nyx_main handler runs → nyx_main
## calls toolbar update method (e.g. update_link_ui) to reflect the new state.
##
## Setup: instantiate, add_child to nyx_main, then call setup(graph) so the floating
## GraphEdit toolbar can be styled (needs the graph in the tree first).

signal file_menu_selected(id: int)
signal recent_file_selected(id: int)
signal recent_menu_opened
signal shader_type_changed(idx: int)
signal render_mode_changed(id: int)
signal export_pressed
signal export_menu_selected(id: int)
signal live_toggled(on: bool)
signal shortcuts_pressed
signal properties_pressed
signal undo_pressed
signal redo_pressed

var _graph: GraphEdit  # for style_graph_toolbar only

var _file_btn: Button
var _file_popup: PopupMenu
var _recent_popup: PopupMenu
var _filename_label: Label
var _type_btn: Button
var _type_popup: PopupMenu
var _render_mode_btn: Button
var _render_mode_popup: PopupMenu
var _export_btn: Button
var _export_menu: MenuButton
var _live_btn: CheckButton


func setup(graph: GraphEdit) -> void:
	_graph = graph
	_build()
	call_deferred("_style_graph_toolbar")


# ── Public update API (nyx_main calls these to reflect state changes) ─────────

func update_link_ui(linked: bool, path: String) -> void:
	if not _export_btn:
		return
	_export_btn.text = "Update" if linked else "Export…"
	_export_btn.tooltip_text = ("Rewrite linked shader: %s" % path) if linked else "Export shader + material, then link"
	_live_btn.disabled = not linked
	if not linked and _live_btn.button_pressed:
		_live_btn.button_pressed = false
	if _file_popup:
		_file_popup.set_item_disabled(_file_popup.get_item_index(8), not linked)  # Unlink


func update_filename(name: String, dirty: bool) -> void:
	if not _filename_label:
		return
	_filename_label.text = (name + " *") if dirty else name
	var col := Color("#D4A017") if dirty else Color("#4AAF78")
	_filename_label.add_theme_color_override("font_color", col)


func update_shader_type_label(idx: int) -> void:
	if _type_btn and _type_popup:
		_type_btn.text = _type_popup.get_item_text(idx) + "  ▾"


# Rebuilds the render mode popup items and syncs the button label.
# current_mode = output_node.get_mode() (or 0 if no output yet).
func update_render_mode(shader_type: int, current_mode: int) -> void:
	if not _render_mode_popup:
		return
	_render_mode_popup.clear()
	if shader_type == 0:
		for label in ["Opaque", "Mix", "Add", "Premult Alpha"]:
			_render_mode_popup.add_item(label)
	elif shader_type == 1:
		for label in ["Default", "Unshaded", "Light Only", "Blend Add", "Blend Premult"]:
			_render_mode_popup.add_item(label)
	if _render_mode_btn:
		var text := _render_mode_popup.get_item_text(current_mode) if _render_mode_popup.item_count > current_mode else "Opaque"
		_render_mode_btn.text = text + "  ▾"
		_render_mode_btn.disabled = shader_type == 2


func refresh_recent_menu(files: Array) -> void:
	_recent_popup.clear()
	if files.is_empty():
		_recent_popup.add_item("(empty)", 0)
		_recent_popup.set_item_disabled(0, true)
	else:
		for i in files.size():
			_recent_popup.add_item((files[i] as String).get_file(), i)
			_recent_popup.set_item_tooltip(i, files[i])


func set_live_on(on: bool) -> void:
	if _live_btn:
		_live_btn.button_pressed = on


# ── Build ─────────────────────────────────────────────────────────────────────

func _build() -> void:
	var bar_bg := StyleBoxFlat.new()
	var editor_base := get_theme_color("base_color", "Editor")
	bar_bg.bg_color = editor_base
	bar_bg.expand_margin_top = 4
	bar_bg.border_width_bottom = 2
	bar_bg.border_color = Color(0.12, 0.12, 0.16)
	add_theme_stylebox_override("panel", bar_bg)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 4)
	add_child(toolbar)

	# File menu
	_file_popup = PopupMenu.new()
	_recent_popup = PopupMenu.new()
	_recent_popup.id_pressed.connect(func(id: int) -> void: recent_file_selected.emit(id))
	_file_popup.add_item("New", 0)
	_file_popup.add_item("Open…", 1)
	_file_popup.add_submenu_node_item("Open Recent", _recent_popup)
	_file_popup.add_separator()
	_file_popup.add_item("Save", 2)
	_file_popup.add_item("Save As…", 3)
	_file_popup.add_separator()
	_file_popup.add_item("Export…", 4)
	_file_popup.add_item("Export As…", 5)
	_file_popup.add_item("Export new material", 6)
	_file_popup.add_item("Export shader only", 7)
	_file_popup.add_separator()
	_file_popup.add_item("Unlink", 8)
	_file_popup.id_pressed.connect(func(id: int) -> void: file_menu_selected.emit(id))
	_file_popup.about_to_popup.connect(func() -> void: recent_menu_opened.emit())

	_file_btn = Button.new()
	_file_btn.text = "File  ▾"
	_file_btn.add_child(_file_popup)
	_file_btn.pressed.connect(func() -> void:
		var r := _file_btn.get_screen_position()
		_file_popup.reset_size()
		_file_popup.popup(Rect2(Vector2(r.x, r.y + _file_btn.size.y), Vector2.ZERO))
	)
	_style_btn(_file_btn)
	toolbar.add_child(_file_btn)

	toolbar.add_child(_make_sep())

	_filename_label = Label.new()
	_filename_label.text = "untitled.nyx"
	_filename_label.add_theme_font_size_override("font_size", 11)
	_filename_label.add_theme_color_override("font_color", Color("#4AAF78"))
	_filename_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toolbar.add_child(_filename_label)

	toolbar.add_child(_make_sep())

	# Shader type selector
	_type_popup = PopupMenu.new()
	_type_popup.add_item("Spatial", 0)
	_type_popup.add_item("Canvas Item", 1)
	_type_popup.add_item("Particles", 2)
	_type_popup.id_pressed.connect(func(id: int) -> void:
		_type_btn.text = _type_popup.get_item_text(id) + "  ▾"
		shader_type_changed.emit(id)
	)
	_type_btn = Button.new()
	_type_btn.text = "Spatial  ▾"
	_type_btn.add_child(_type_popup)
	_type_btn.pressed.connect(func() -> void:
		var r := _type_btn.get_screen_position()
		_type_popup.reset_size()
		_type_popup.popup(Rect2(Vector2(r.x, r.y + _type_btn.size.y), Vector2(_type_btn.size.x, 0)))
	)
	_style_btn(_type_btn)
	toolbar.add_child(_type_btn)

	# Render mode selector
	_render_mode_popup = PopupMenu.new()
	_render_mode_btn = Button.new()
	_render_mode_btn.text = "Opaque  ▾"
	_render_mode_btn.add_child(_render_mode_popup)
	_render_mode_btn.pressed.connect(func() -> void:
		var r := _render_mode_btn.get_screen_position()
		_render_mode_popup.reset_size()
		_render_mode_popup.popup(Rect2(Vector2(r.x, r.y + _render_mode_btn.size.y), Vector2(_render_mode_btn.size.x, 0)))
	)
	_render_mode_popup.id_pressed.connect(func(id: int) -> void:
		_render_mode_btn.text = _render_mode_popup.get_item_text(id) + "  ▾"
		render_mode_changed.emit(id)
	)
	_style_btn(_render_mode_btn)
	toolbar.add_child(_render_mode_btn)

	toolbar.add_child(_make_sep())

	var params_btn := Button.new()
	params_btn.text = "Properties"
	params_btn.pressed.connect(func() -> void: properties_pressed.emit())
	_style_btn(params_btn)
	toolbar.add_child(params_btn)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)

	toolbar.add_child(_make_sep())

	# Export / Live
	_export_btn = Button.new()
	_export_btn.text = "Export…"
	_export_btn.pressed.connect(func() -> void: export_pressed.emit())
	_style_btn(_export_btn)
	toolbar.add_child(_export_btn)

	_export_menu = MenuButton.new()
	_export_menu.flat = true
	_export_menu.text = "▾"
	_style_btn(_export_menu)
	var pm := _export_menu.get_popup()
	pm.add_item("Export new material", 0)
	pm.add_item("Export shader only", 1)
	pm.add_separator()
	pm.add_item("Export as… (re-link)", 2)
	pm.add_item("Unlink", 3)
	pm.id_pressed.connect(func(id: int) -> void: export_menu_selected.emit(id))
	toolbar.add_child(_export_menu)

	_live_btn = CheckButton.new()
	_live_btn.text = "Live"
	_live_btn.tooltip_text = "Push shader changes into the linked artifact in real time."
	_live_btn.toggled.connect(func(on: bool) -> void: live_toggled.emit(on))
	_style_btn(_live_btn)
	_live_btn.add_theme_color_override("font_pressed_color", Color("#4AAF78"))
	_live_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	toolbar.add_child(_live_btn)

	toolbar.add_child(_make_sep())

	var help_btn := Button.new()
	help_btn.text = "?"
	help_btn.tooltip_text = "Keyboard shortcuts (?)"
	help_btn.focus_mode = Control.FOCUS_NONE
	help_btn.add_theme_font_size_override("font_size", 14)
	help_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	help_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	help_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	help_btn.add_theme_color_override("font_focus_color", Color(0.55, 0.55, 0.65))
	var hb_empty := StyleBoxEmpty.new()
	help_btn.add_theme_stylebox_override("normal", hb_empty)
	help_btn.add_theme_stylebox_override("hover", hb_empty)
	help_btn.add_theme_stylebox_override("pressed", hb_empty)
	help_btn.add_theme_stylebox_override("focus", hb_empty)
	help_btn.pressed.connect(func() -> void: shortcuts_pressed.emit())
	toolbar.add_child(help_btn)

	var edge_pad := Control.new()
	edge_pad.custom_minimum_size = Vector2(4, 0)
	edge_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toolbar.add_child(edge_pad)


# Injects undo/redo icon buttons into the GraphEdit's built-in floating toolbar
# and applies the Nyx visual style to all its buttons. Called deferred so the
# graph is fully in the tree and get_menu_hbox() returns the real HBox.
func _style_graph_toolbar() -> void:
	var hbox := _graph.get_menu_hbox()

	var undo_btn := Button.new()
	undo_btn.icon = _load_icon("res://addons/nyx/icons/undo.svg", 12)
	undo_btn.tooltip_text = "Undo"
	undo_btn.pressed.connect(func() -> void: undo_pressed.emit())
	_style_btn(undo_btn)
	hbox.add_child(undo_btn)
	hbox.move_child(undo_btn, 0)

	var redo_btn := Button.new()
	redo_btn.icon = _load_icon("res://addons/nyx/icons/redo.svg", 12)
	redo_btn.tooltip_text = "Redo"
	redo_btn.pressed.connect(func() -> void: redo_pressed.emit())
	_style_btn(redo_btn)
	hbox.add_child(redo_btn)
	hbox.move_child(redo_btn, 1)

	for child in hbox.get_children():
		if not child is Button:
			continue
		_style_btn(child)
		# Default grid off
		if "grid" in child.tooltip_text.to_lower() or "grid" in child.text.to_lower():
			if child.button_pressed:
				child.button_pressed = false
				child.pressed.emit()
		# Icon-only buttons in the floating toolbar get tighter margins
		var icon_normal := StyleBoxFlat.new()
		icon_normal.bg_color = Color(0, 0, 0, 0)
		icon_normal.set_corner_radius_all(4)
		icon_normal.content_margin_left = 4
		icon_normal.content_margin_right = 4
		icon_normal.content_margin_top = 2
		icon_normal.content_margin_bottom = 2
		child.add_theme_stylebox_override("normal", icon_normal)
		var icon_hover := icon_normal.duplicate()
		icon_hover.bg_color = Color(0.20, 0.20, 0.26)
		icon_hover.set_border_width_all(1)
		icon_hover.border_color = Color("#31614F")
		child.add_theme_stylebox_override("hover", icon_hover)
		var icon_press := icon_normal.duplicate()
		icon_press.bg_color = Color(0.16, 0.32, 0.26)
		child.add_theme_stylebox_override("pressed", icon_press)
		child.add_theme_stylebox_override("hover_pressed", icon_hover)
		child.add_theme_stylebox_override("focus", icon_normal)
		child.add_theme_color_override("icon_pressed_color", Color("#4AAF78"))
		child.add_theme_color_override("font_pressed_color", Color("#4AAF78"))
		child.add_theme_color_override("icon_hover_pressed_color", Color("#4AAF78"))


# ── Styling helpers ────────────────────────────────────────────────────────────

func _make_btn_style(state: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	match state:
		1: s.bg_color = Color(0.20, 0.20, 0.26)
		2: s.bg_color = Color(0.16, 0.32, 0.26)
		_: s.bg_color = Color(0, 0, 0, 0)
	s.set_corner_radius_all(4)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	if state == 1:
		s.set_border_width_all(1)
		s.border_color = Color("#31614F")
	return s


func _style_btn(b: Button) -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 0)
	b.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color(0.85, 0.87, 0.92))
	b.add_theme_stylebox_override("normal", _make_btn_style(0))
	b.add_theme_stylebox_override("hover", _make_btn_style(1))
	b.add_theme_stylebox_override("pressed", _make_btn_style(2))
	b.add_theme_stylebox_override("hover_pressed", _make_btn_style(1))
	b.add_theme_stylebox_override("focus", _make_btn_style(0))


func _make_sep() -> VSeparator:
	var s := VSeparator.new()
	var line := StyleBoxLine.new()
	line.color = Color(0.24, 0.24, 0.30)
	line.thickness = 1
	line.grow_begin = 2
	line.grow_end = 2
	s.add_theme_stylebox_override("separator", line)
	return s


func _load_icon(path: String, size: int = 16) -> ImageTexture:
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
