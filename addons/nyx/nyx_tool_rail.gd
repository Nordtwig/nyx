@tool
extends Panel

## Nyx floating tool rail — a vertical strip holding GraphEdit's native zoom/
## grid/minimap/arrange buttons plus our injected Undo/Redo buttons. No
## Properties toggle here — the Ctrl+P command palette already covers that, so
## a rail button would just be a redundant second path to the same action.
##
## Previously these lived inside GraphEdit's own top-left corner toolbar
## (injected there by nyx_chrome_bar.gd's _style_graph_toolbar), which collided
## with the chrome-bar pill defaulting to the same corner. Rather than
## reimplement zoom/grid/minimap, this reparents GraphEdit's actual native
## Button instances (from get_menu_hbox()) into our own vertical VBoxContainer —
## same wired-up buttons, just relaid-out and given a real floating position of
## their own.
##
## Defaults to the vertical-center of the graph's left edge (a standard
## Photoshop/Blender-style tool rail), draggable via the header handle like the
## preview/properties panels. Public API mirrors those two:
##   setup(graph, graph_container)
##   place_default(graph_top)
##   reanchor(graph_top, outer_width)
##   is_placed()

const NyxNodeBase = preload("res://addons/nyx/nodes/nyx_node.gd")

signal undo_pressed
signal redo_pressed

const LEFT_MARGIN := 12.0
# Fixed rail width, matching the rest of the UI's chrome unit (command-bar
# icon segment, preview panel's shape-switcher icons). Width is no longer
# content-driven like height is — see _fit_to_content(). Deliberately raw/
# unscaled (not wrapped in _s()) — this is an eyeballed-on-screen reference
# value, not a 1.0-scale logical design unit, and multiplying it by EDSCALE
# would shrink it below what was actually being matched (e.g. 40 → 30 at the
# laptop's 0.75 scale, barely bigger than the icon content it should frame).
const RAIL_WIDTH := 40.0
# Icon size for every button in the rail — ours (Undo/Redo) and the
# reparented native ones alike, so nothing in the column reads as a
# mismatched size. Matches the preview panel's shape-switcher icon size.
# Native icons are small rasterized bitmaps to begin with, so upscaling them
# to match isn't lossless — if that reads as too blurry at this width, the
# follow-up plan is to source Tabler equivalents for zoom/grid/minimap too,
# swapped onto the same (still-native-wired) Button instances rather than
# reimplementing their click behavior.
const ICON_SIZE := 16

var _graph: GraphEdit
var _graph_container: Control
var _vbox: VBoxContainer
var _button_col: VBoxContainer
var _dragging: bool = false

var _left_offset: float = LEFT_MARGIN
var _top_offset: float = -1.0   # -1 = not yet placed


func setup(graph: GraphEdit, graph_container: Control) -> void:
	_graph = graph
	_graph_container = graph_container
	_build()
	call_deferred("_populate_from_graph_toolbar")


# Floating-placement API — mirrors nyx_preview_panel.gd's trio, anchored left
# instead of right, defaulting to vertical-center instead of a fixed top offset.
func place_default(graph_top: float) -> void:
	_left_offset = LEFT_MARGIN
	_top_offset = graph_top + (_graph_container.size.y - size.y) / 2.0
	position = Vector2(_left_offset, _top_offset)


func reanchor(graph_top: float, outer_width: float) -> void:
	if _top_offset < 0.0:
		return
	position = Vector2(_left_offset, _top_offset).clamp(
		Vector2(0.0, graph_top),
		Vector2(outer_width, graph_top + _graph_container.size.y) - size
	)


func is_placed() -> bool:
	return _top_offset >= 0.0


# ── Build ─────────────────────────────────────────────────────────────────────

func _build() -> void:
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.13, 0.13, 0.16, 0.92)
	# Top corners match the command bar's corner radius (_s(8)); bottom-left
	# stays at the rail's own original _s(6), bottom-right doubled for accent.
	card_style.corner_radius_top_left = NyxNodeBase._s(8)
	card_style.corner_radius_top_right = NyxNodeBase._s(8)
	card_style.corner_radius_bottom_left = NyxNodeBase._s(6)
	card_style.corner_radius_bottom_right = NyxNodeBase._s(12)
	add_theme_stylebox_override("panel", card_style)

	_vbox = VBoxContainer.new()
	_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vbox.add_theme_constant_override("separation", 0)
	add_child(_vbox)

	# Header / drag handle — same convention as the preview/properties headers.
	var header_wrap := PanelContainer.new()
	var header_bg := StyleBoxFlat.new()
	var header_base := get_theme_color("base_color", "Editor")
	header_bg.bg_color = Color(header_base.r, header_base.g, header_base.b, 0.95)
	header_bg.corner_radius_top_left = NyxNodeBase._s(8)
	header_bg.corner_radius_top_right = NyxNodeBase._s(8)
	header_bg.border_width_bottom = 2
	header_bg.border_color = Color(0.12, 0.12, 0.16)
	header_bg.content_margin_top = NyxNodeBase._s(12)
	header_bg.content_margin_bottom = NyxNodeBase._s(12)
	header_wrap.add_theme_stylebox_override("panel", header_bg)
	_vbox.add_child(header_wrap)

	var header := HBoxContainer.new()
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.gui_input.connect(_on_header_input)
	header_wrap.add_child(header)

	var handle_icon_wrap := MarginContainer.new()
	handle_icon_wrap.add_theme_constant_override("margin_top", NyxNodeBase._s(2))
	handle_icon_wrap.add_theme_constant_override("margin_bottom", NyxNodeBase._s(3))
	handle_icon_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	handle_icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(handle_icon_wrap)

	var handle_icon := TextureRect.new()
	handle_icon.texture = _load_icon("res://addons/nyx/icons/grid-3x3.svg", 14)
	handle_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	handle_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	handle_icon.modulate = get_theme_color("font_color", "Label").darkened(0.15)
	handle_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	handle_icon.tooltip_text = "Tools — drag to move"
	handle_icon_wrap.add_child(handle_icon)

	var col_margin := MarginContainer.new()
	col_margin.add_theme_constant_override("margin_left", 4)
	col_margin.add_theme_constant_override("margin_right", 4)
	col_margin.add_theme_constant_override("margin_top", 6)
	col_margin.add_theme_constant_override("margin_bottom", 6)
	_vbox.add_child(col_margin)

	_button_col = VBoxContainer.new()
	_button_col.add_theme_constant_override("separation", 4)
	col_margin.add_child(_button_col)

	_fit_to_content()


# Plain Panel (unlike PanelContainer) doesn't compute its minimum size from
# children — Panel.get_minimum_size() is always (0,0) regardless of content,
# so reset_size() is a no-op here and leaves self sized for nothing, with the
# actual buttons overflowing past that empty rect and rendering with no
# background behind them. Read the real size off the inner VBoxContainer
# (an actual Container, which does aggregate from children) instead.
# Width is fixed (RAIL_WIDTH, raw/unscaled — not run through _s()) rather
# than content-driven — see its docstring.
func _fit_to_content() -> void:
	size = Vector2(RAIL_WIDTH, _vbox.get_combined_minimum_size().y)


func _on_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		position += event.relative
		_left_offset = position.x
		_top_offset = position.y


# Reparents GraphEdit's native zoom/grid/minimap/arrange buttons (from its own
# built-in floating toolbar) into our vertical column, alongside Undo/Redo.
# Deferred so the graph is fully in the tree and get_menu_hbox() returns the
# real HBox with its buttons already built.
func _populate_from_graph_toolbar() -> void:
	var hbox := _graph.get_menu_hbox()

	var undo_btn := Button.new()
	undo_btn.icon = _load_icon("res://addons/nyx/icons/undo.svg", ICON_SIZE)
	undo_btn.tooltip_text = "Undo"
	undo_btn.pressed.connect(func() -> void: undo_pressed.emit())
	_style_btn(undo_btn)
	_button_col.add_child(undo_btn)

	var redo_btn := Button.new()
	redo_btn.icon = _load_icon("res://addons/nyx/icons/redo.svg", ICON_SIZE)
	redo_btn.tooltip_text = "Redo"
	redo_btn.pressed.connect(func() -> void: redo_pressed.emit())
	_style_btn(redo_btn)
	_button_col.add_child(redo_btn)

	_button_col.add_child(_make_separator())

	for child in hbox.get_children().duplicate():
		hbox.remove_child(child)
		if child is VSeparator:
			child.queue_free()
			_button_col.add_child(_make_separator())
			continue
		# The snap-distance SpinBox is a wide numeric field that would force the
		# whole narrow rail wide for a control tied to a feature (node-drag
		# snapping) that's off by default in Nyx. Drop it; its paired toggle
		# button still works, just without an in-rail distance control.
		if child is SpinBox:
			child.queue_free()
			continue
		_button_col.add_child(child)
		if child is Button:
			# Resized to match ICON_SIZE despite the upscale-blur risk —
			# mismatched sizes read worse than the softness. If this still
			# looks bad at RAIL_WIDTH, swap to Tabler-sourced replacement
			# icons next (same Button instances, so click behavior is
			# untouched — just a different .icon texture).
			if child.icon:
				child.icon = _resize_texture(child.icon, ICON_SIZE)
			_style_btn(child)
			# Default grid off, same as before the move.
			if "grid" in child.tooltip_text.to_lower() or "grid" in child.text.to_lower():
				if child.button_pressed:
					child.button_pressed = false
					child.pressed.emit()

	_fit_to_content()


func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.22, 0.22, 0.28)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	return sep


# ── Styling helpers ────────────────────────────────────────────────────────────

# Same convention as the preview panel's mesh-switcher icon stack: no button
# box at all (StyleBoxEmpty on every state), just icon/font color shifts —
# light grey at rest, near-white on hover, brand green when active (pressed,
# or toggled on for the grid/minimap toggle buttons).
func _style_btn(b: Button) -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 0)
	# Shrink-to-content + center: without this, a Button's default SIZE_FILL
	# stretches it to the column's widest sibling, leaving extra whitespace
	# around a same-size icon. Applies to every button here (both our injected
	# ones and reparented native ones, which may carry a different flag from
	# their old horizontal hbox context) so all icons hug their own edges.
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	b.add_theme_color_override("font_hover_color", Color(0.9, 0.9, 0.95))
	b.add_theme_color_override("font_pressed_color", Color("#4AAF78"))
	b.add_theme_color_override("font_focus_color", Color(0.55, 0.55, 0.65))
	b.add_theme_color_override("icon_normal_color", Color(0.55, 0.55, 0.65))
	b.add_theme_color_override("icon_hover_color", Color(0.9, 0.9, 0.95))
	b.add_theme_color_override("icon_pressed_color", Color("#4AAF78"))
	b.add_theme_color_override("icon_hover_pressed_color", Color("#4AAF78"))
	var empty := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", empty)
	b.add_theme_stylebox_override("hover", empty)
	b.add_theme_stylebox_override("pressed", empty)
	b.add_theme_stylebox_override("hover_pressed", empty)
	b.add_theme_stylebox_override("focus", empty)


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


# Resize-only, no recolor — unlike _load_icon(), which force-flattens our own
# monochrome SVGs to white. GraphEdit's native icons already carry their own
# theme-correct colors (and get tinted via icon_*_color overrides same as
# ours), so recoloring here would just be redundant/lossy.
func _resize_texture(tex: Texture2D, size: int) -> ImageTexture:
	var img := tex.get_image()
	img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)
