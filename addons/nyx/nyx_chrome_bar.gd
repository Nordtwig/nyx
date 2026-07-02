@tool
extends PanelContainer

## Nyx chrome bar — a small floating pill in the graph's top-left corner (command-palette
## redesign, Stage 2/3). NOT a docked toolbar strip — it reserves no layout space; the
## graph fills the whole area beneath/behind it, same as nyx_preview_panel.gd /
## nyx_properties_panel.gd float over the top-right.
##
## Holds only: an eye-spark icon button that opens the Ctrl+P command palette (left side —
## "click the logo to start acting" is the expected corner convention), filename + dirty
## asterisk, and a bare "●" status dot — always visible, green when linked to a shader,
## red when not (a status indicator, not a control; no label, tooltip covers
## discoverability). Every action that used to live in the old toolbar
## (File/Export/Live/View) now lives in nyx_command_palette.gd; Undo/Redo/Properties
## and GraphEdit's native zoom/grid/minimap toolbar live in nyx_tool_rail.gd. This pill
## is identity + status only, and shrinks to fit its content. Replaces nyx_graph_toolbar.gd
## (deleted once this and nyx_tool_rail.gd covered its job).

const NyxNodeBase = preload("res://addons/nyx/nodes/nyx_node.gd")

signal palette_pressed

const LEFT_MARGIN := 12.0
const TOP_MARGIN := 12.0

var _graph_container: Control   # for placement math
var _top_offset: float = -1.0   # -1 = not yet placed

var _filename_label: Label
var _live_badge: Label


func setup(graph: GraphEdit, graph_container: Control) -> void:
	_graph_container = graph_container
	_build()


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

# Same 3-color language as the Live dot: bright accent green once it's
# actually saved to disk and clean, muted Hunter green for a fresh/never-saved
# graph (nothing wrong, just no file yet — not the same as "safely saved"),
# amber while dirty.
func update_filename(name: String, dirty: bool, ever_saved: bool = true) -> void:
	if not _filename_label:
		return
	_filename_label.text = (name + " *") if dirty else name
	var color := Color("#D4A017")
	if not dirty:
		color = Color("#4AAF78") if ever_saved else Color("#31614F")
	_filename_label.add_theme_color_override("font_color", color)
	reset_size()


# Always visible now — a 2-state dot (bright accent green = linked, muted
# Hunter green = not linked yet) rather than showing/hiding, so the pill always
# communicates link status at a glance instead of only when things are already
# good. Same-hue intensity shift rather than a second signal color, since
# "not linked yet" is a normal starting state, not an error. A 3rd "linked but
# Live paused" state is a separate, not-yet-decided design (feedback.md).
func set_live_badge(linked_path: String) -> void:
	if not _live_badge:
		return
	_live_badge.visible = true
	if linked_path.is_empty():
		_live_badge.add_theme_color_override("font_color", Color("#31614F"))
		_live_badge.tooltip_text = "Not linked to a shader yet"
	else:
		_live_badge.add_theme_color_override("font_color", Color("#4AAF78"))
		_live_badge.tooltip_text = "Live linked to %s" % linked_path.get_file()
	reset_size()


# ── Build ─────────────────────────────────────────────────────────────────────

func _build() -> void:
	# Outer stylebox: no content margin — the two inner segments below carry
	# their own padding, same pattern as the other panels' header-vs-body split
	# (header_wrap sits flush against the outer Panel's edge, body content gets
	# its own MarginContainer). That's what lets the titlebar-gray segment's
	# corners align exactly with the pill's own rounded corners, seamlessly.
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.13, 0.13, 0.16, 0.92)
	card_style.border_color = Color(0.12, 0.12, 0.16)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(NyxNodeBase._s(8))
	add_theme_stylebox_override("panel", card_style)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 0)
	add_child(bar)

	# Left segment — titlebar gray (same as the preview/properties/tool-rail
	# headers), rounded only on the left to match the pill's own left corners,
	# with a thin right-side divider — the same two-tone panel language as
	# those, just rotated 90°: this pill IS one of those panels on its side.
	# "Click the logo to start acting" is the expected corner convention, so
	# the palette entry point comes before identity/status.
	var palette_wrap := PanelContainer.new()
	var palette_bg := StyleBoxFlat.new()
	var palette_base := get_theme_color("base_color", "Editor")
	palette_bg.bg_color = Color(palette_base.r, palette_base.g, palette_base.b, 0.95)
	palette_bg.corner_radius_top_left = NyxNodeBase._s(8)
	palette_bg.corner_radius_bottom_left = NyxNodeBase._s(8)
	palette_bg.border_width_right = 2
	palette_bg.border_color = Color(0.12, 0.12, 0.16)
	palette_bg.content_margin_left = NyxNodeBase._s(5)
	palette_bg.content_margin_right = NyxNodeBase._s(10)
	palette_bg.content_margin_top = NyxNodeBase._s(6)
	palette_bg.content_margin_bottom = NyxNodeBase._s(6)
	palette_wrap.add_theme_stylebox_override("panel", palette_bg)
	bar.add_child(palette_wrap)

	var palette_btn := Button.new()
	palette_btn.icon = _load_icon("res://addons/nyx/icons/eye-spark.svg", 14)
	palette_btn.tooltip_text = "Commands (Ctrl+P)"
	palette_btn.pressed.connect(func() -> void: palette_pressed.emit())
	_style_btn(palette_btn)
	palette_wrap.add_child(palette_btn)

	# Right segment — the rest of the pill (filename, dot), in the darker
	# body gray inherited from the outer stylebox; its own MarginContainer
	# supplies the padding the outer stylebox used to.
	var rest_margin := MarginContainer.new()
	rest_margin.add_theme_constant_override("margin_left", NyxNodeBase._s(10))
	rest_margin.add_theme_constant_override("margin_right", NyxNodeBase._s(5))
	rest_margin.add_theme_constant_override("margin_top", NyxNodeBase._s(6))
	rest_margin.add_theme_constant_override("margin_bottom", NyxNodeBase._s(6))
	bar.add_child(rest_margin)

	var rest_bar := HBoxContainer.new()
	rest_bar.add_theme_constant_override("separation", NyxNodeBase._s(10))
	rest_margin.add_child(rest_bar)

	_filename_label = Label.new()
	_filename_label.add_theme_font_size_override("font_size", 11)
	_filename_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rest_bar.add_child(_filename_label)
	update_filename("untitled.nyx", false, false)  # starts muted green — no file on disk yet

	# Bare status dot, no label — a plain colored dot is a standard "status
	# indicator" idiom (recording lights, connection dots), and now that the
	# dirty flag is a "*" suffix instead of a dot, there's no more ambiguity
	# between two differently-meaning dots. Tooltip still covers discoverability.
	# Wrapped in a MarginContainer so it can be nudged down a couple pixels —
	# a raw position offset on the Label itself would just get overwritten by
	# the HBoxContainer's own layout pass every frame.
	var live_badge_wrap := MarginContainer.new()
	live_badge_wrap.add_theme_constant_override("margin_top", NyxNodeBase._s(2))
	rest_bar.add_child(live_badge_wrap)

	_live_badge = Label.new()
	_live_badge.text = "●"
	_live_badge.add_theme_font_size_override("font_size", 9)
	# STOP, not IGNORE — a tooltip needs mouse-enter events to fire, which an
	# IGNORE control never receives regardless of tooltip_text being set.
	_live_badge.mouse_filter = Control.MOUSE_FILTER_STOP
	live_badge_wrap.add_child(_live_badge)
	set_live_badge("")  # starts red/"not linked" — set_live_badge() drives color+tooltip


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
