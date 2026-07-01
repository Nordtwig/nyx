@tool
extends PanelContainer

## Nyx chrome bar — a small floating pill in the graph's top-left corner (command-palette
## redesign, Stage 2/3). NOT a docked toolbar strip — it reserves no layout space; the
## graph fills the whole area beneath/behind it, same as nyx_preview_panel.gd /
## nyx_properties_panel.gd float over the top-right.
##
## Holds only: filename + dirty asterisk, a "● Live" status badge (visible only while
## live-link is on — a status indicator, not a control), and a ◈ button that opens the
## Ctrl+P command palette. Every action that used to live in the old toolbar
## (File/Export/Live/View) now lives in nyx_command_palette.gd; this pill is identity +
## status only, and shrinks to fit its content (the Live badge only takes up space when
## actually visible). Replaces nyx_graph_toolbar.gd (deleted once this covered its job).
##
## Also inherits _style_graph_toolbar() from the old toolbar — injecting Undo/Redo/Props
## buttons into GraphEdit's own floating toolbar and styling all its buttons. That's a
## graph-canvas concern, not a chrome-bar one, but this is its home until it earns its own file.

const NyxNodeBase = preload("res://addons/nyx/nodes/nyx_node.gd")

signal palette_pressed
signal undo_pressed
signal redo_pressed
signal properties_toggled

const LEFT_MARGIN := 12.0
const TOP_MARGIN := 12.0

var _graph: GraphEdit           # for _style_graph_toolbar only
var _graph_container: Control   # for placement math
var _top_offset: float = -1.0   # -1 = not yet placed

var _filename_label: Label
var _live_badge: Label


func setup(graph: GraphEdit, graph_container: Control) -> void:
	_graph = graph
	_graph_container = graph_container
	_build()
	call_deferred("_style_graph_toolbar")


# Floating-placement API — mirrors nyx_preview_panel.gd's place_default/reanchor/
# is_placed trio, just anchored top-left (fixed) instead of top-right (draggable).
func place_default(graph_top: float) -> void:
	_top_offset = graph_top + TOP_MARGIN
	position = Vector2(LEFT_MARGIN, _top_offset)


func reanchor(graph_top: float) -> void:
	if _top_offset < 0.0:
		return
	_top_offset = graph_top + TOP_MARGIN
	position = Vector2(LEFT_MARGIN, _top_offset)


func is_placed() -> bool:
	return _top_offset >= 0.0


# ── Public update API (nyx_main calls these to reflect state changes) ─────────

func update_filename(name: String, dirty: bool) -> void:
	if not _filename_label:
		return
	_filename_label.text = (name + " *") if dirty else name
	_filename_label.add_theme_color_override("font_color", Color("#D4A017") if dirty else Color("#4AAF78"))
	reset_size()


func set_live_badge(on: bool) -> void:
	if _live_badge:
		_live_badge.visible = on
		reset_size()


# ── Build ─────────────────────────────────────────────────────────────────────

func _build() -> void:
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.13, 0.13, 0.16, 0.95)
	card_style.border_color = Color(0.24, 0.24, 0.30)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(NyxNodeBase._s(8))
	card_style.content_margin_left = NyxNodeBase._s(10)
	card_style.content_margin_right = NyxNodeBase._s(10)
	card_style.content_margin_top = NyxNodeBase._s(6)
	card_style.content_margin_bottom = NyxNodeBase._s(6)
	add_theme_stylebox_override("panel", card_style)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", NyxNodeBase._s(10))
	add_child(bar)

	_filename_label = Label.new()
	_filename_label.text = "untitled.nyx"
	_filename_label.add_theme_font_size_override("font_size", 11)
	_filename_label.add_theme_color_override("font_color", Color("#4AAF78"))
	_filename_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(_filename_label)

	_live_badge = Label.new()
	_live_badge.text = "● Live"
	_live_badge.add_theme_font_size_override("font_size", 11)
	_live_badge.add_theme_color_override("font_color", Color("#4AAF78"))
	_live_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_live_badge.tooltip_text = "Live link active — shader changes push to the linked artifact in real time."
	_live_badge.visible = false
	bar.add_child(_live_badge)

	var palette_btn := Button.new()
	palette_btn.text = "◈"
	palette_btn.tooltip_text = "Commands (Ctrl+P)"
	palette_btn.pressed.connect(func() -> void: palette_pressed.emit())
	_style_btn(palette_btn)
	bar.add_child(palette_btn)


# Injects undo/redo/properties icon buttons into the GraphEdit's built-in floating
# toolbar and applies the Nyx visual style to all its buttons. Called deferred so the
# graph is fully in the tree and get_menu_hbox() returns the real HBox. Moved verbatim
# from nyx_graph_toolbar.gd — this is a graph-canvas concern, unrelated to the chrome
# bar redesign above.
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

	# Properties toggle — no dedicated icon yet (see Iconography backlog item), plain
	# text button styled the same as the rest of this icon strip in the meantime.
	var props_btn := Button.new()
	props_btn.text = "Props"
	props_btn.tooltip_text = "Toggle Properties panel"
	props_btn.pressed.connect(func() -> void: properties_toggled.emit())
	_style_btn(props_btn)
	hbox.add_child(props_btn)
	hbox.move_child(props_btn, 2)

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
