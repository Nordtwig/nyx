@tool
extends GraphNode

signal value_changed
signal edit_started
signal preview_toggled
signal inspector_requested(node)

var _node_color: Color = Color("#2E8266")
var _category: String = ""
var _preview_open: bool = false
var _preview_slot: TextureRect
var _preview_wrapper: Panel
var _preview_spacer: Control
var _preview_chevron: Button
var _preview_unavailable_label: Label
var _inspector_cog: Button
var _cog_hover_shown: bool = false
var _inspector_popup_open: bool = false
var _body_style: StyleBoxFlat
var _titlebar_style: StyleBoxFlat
var _halo_style: StyleBoxFlat


func _ready() -> void:
	_apply_style()
	_build_halo_style()
	call_deferred("_add_preview_controls")
	call_deferred("_add_inspector_trigger")
	call_deferred("_apply_input_styles")
	resized.connect(_update_body_for_preview)
	gui_input.connect(_on_node_gui_input)
	if not is_connected("node_selected", Callable(self, "_on_selected")):
		connect("node_selected", Callable(self, "_on_selected"))
		connect("node_deselected", Callable(self, "_on_deselected"))


# Selection halo — a rounded green outline drawn just OUTSIDE the node rect in
# _draw() (see below), against the dark canvas. Unlike a stylebox border (which
# always sits inside its box and would shift the visible body), this is a pure
# overlay: no layout or body-region change, and it reads on any body color — the
# Color node especially, where a body-edge border can blend into the picked hue.
func _build_halo_style() -> void:
	_halo_style = StyleBoxFlat.new()
	_halo_style.draw_center = false
	_halo_style.bg_color = Color(0, 0, 0, 0)
	_halo_style.border_width_left = 1
	_halo_style.border_width_right = 1
	_halo_style.border_width_top = 1
	_halo_style.border_width_bottom = 1
	_halo_style.border_color = Color("#4AAF78")
	# Wraps the whole node (titlebar + body); radii ~ node corners + the offset.
	_halo_style.corner_radius_top_left = 7
	_halo_style.corner_radius_top_right = 13
	_halo_style.corner_radius_bottom_left = 13
	_halo_style.corner_radius_bottom_right = 7


func _draw() -> void:
	if not (selected and _halo_style):
		return
	var e := 1.0
	draw_style_box(_halo_style, Rect2(Vector2(-e, -e), size + Vector2(e * 2.0, e * 2.0)))
	# The halo draws on top of GraphNode's content, so re-stamp the port dots over
	# it — they overhang the node edge and the ring would otherwise cross them.
	var tex := get_theme_icon("port")
	if tex:
		var half := tex.get_size() * 0.5
		for i in range(get_input_port_count()):
			draw_texture(tex, get_input_port_position(i) - half, get_input_port_color(i))
		for i in range(get_output_port_count()):
			draw_texture(tex, get_output_port_position(i) - half, get_output_port_color(i))


func _add_preview_controls() -> void:
	var chevron := Button.new()
	chevron.text = "▾"
	chevron.flat = true
	chevron.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chevron.pressed.connect(_on_preview_chevron_pressed.bind(chevron))
	add_child(chevron)
	_preview_chevron = chevron

	_preview_spacer = Control.new()
	_preview_spacer.custom_minimum_size = Vector2(0, 8)
	_preview_spacer.visible = false
	add_child(_preview_spacer)

	_preview_wrapper = Panel.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0)
	_preview_wrapper.add_theme_stylebox_override("panel", bg)
	_preview_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_wrapper.custom_minimum_size = Vector2(0, 100)
	_preview_wrapper.visible = false
	add_child(_preview_wrapper)

	_preview_slot = TextureRect.new()
	_preview_slot.stretch_mode = TextureRect.STRETCH_SCALE
	_preview_slot.set_anchor(SIDE_LEFT, 0.5)
	_preview_slot.set_anchor(SIDE_RIGHT, 0.5)
	_preview_slot.set_offset(SIDE_LEFT, -50)
	_preview_slot.set_offset(SIDE_RIGHT, 50)
	_preview_slot.set_offset(SIDE_TOP, 0)
	_preview_slot.set_offset(SIDE_BOTTOM, 100)

	var corner_shader := Shader.new()
	corner_shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec2 size = 1.0 / TEXTURE_PIXEL_SIZE;\n\tvec2 pos = UV * size;\n\tfloat r = 5.0;\n\tvec2 d = max(abs(pos - size * 0.5) - (size * 0.5 - r), vec2(0.0));\n\tCOLOR = texture(TEXTURE, UV);\n\tCOLOR.a *= clamp(-(length(d) - r), 0.0, 1.0);\n}"
	var corner_mat := ShaderMaterial.new()
	corner_mat.shader = corner_shader
	_preview_slot.material = corner_mat

	_preview_wrapper.add_child(_preview_slot)

	_preview_unavailable_label = Label.new()
	_preview_unavailable_label.text = "No preview"
	_preview_unavailable_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_unavailable_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_preview_unavailable_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_preview_unavailable_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	_preview_unavailable_label.add_theme_font_size_override("font_size", 10)
	_preview_unavailable_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_preview_unavailable_label.visible = false
	_preview_wrapper.add_child(_preview_unavailable_label)


# Called by the preview manager when it can't build a preview for the node's
# current graph position (e.g. depends on per-instance data). Hides the
# texture slot and shows a short explanation instead.
func show_preview_unavailable(msg: String) -> void:
	if _preview_unavailable_label:
		_preview_unavailable_label.text = msg
		_preview_unavailable_label.visible = true
	if _preview_slot:
		_preview_slot.visible = false


func clear_preview_unavailable() -> void:
	if _preview_unavailable_label:
		_preview_unavailable_label.visible = false
	if _preview_slot:
		_preview_slot.visible = true


func _on_preview_chevron_pressed(chevron: Button) -> void:
	_preview_open = not _preview_open
	chevron.text = "▴" if _preview_open else "▾"
	_preview_spacer.visible = _preview_open
	_preview_wrapper.visible = _preview_open
	if _preview_open:
		_update_body_for_preview()
	else:
		call_deferred("reset_size")
	emit_signal("preview_toggled")


func _update_body_for_preview() -> void:
	var body := get_theme_stylebox("panel") as StyleBoxFlat
	if body:
		body.expand_margin_bottom = -108 if _preview_open else 0
		body.corner_radius_bottom_left = 12
		body.corner_radius_bottom_right = 6


func get_preview_slot() -> TextureRect:
	return _preview_slot


# Universal node-inspector trigger (Step 5): a hover-revealed cog button in the
# titlebar, top-right (same slot the old per-node "$" param buttons used to sit
# in), plus a double-click anywhere on the node (titlebar included — single-click
# dragging is unaffected since Godot distinguishes a double_click press from a
# press-and-hold-drag at the event level). Both just emit inspector_requested(self)
# — nyx_main.gd owns what actually opens (curated EditorInspector / ColorPicker /
# meta-only), this node doesn't need to know.
func _add_inspector_trigger() -> void:
	var hbox := get_titlebar_hbox()
	_inspector_cog = Button.new()
	_inspector_cog.icon = _get_cog_icon()
	_inspector_cog.flat = true
	_inspector_cog.toggle_mode = true
	_inspector_cog.focus_mode = Control.FOCUS_NONE
	_inspector_cog.custom_minimum_size = Vector2(_s(20), 0)
	_inspector_cog.tooltip_text = "Open inspector"
	_inspector_cog.add_theme_color_override("icon_normal_color", Color(0.85, 0.85, 0.9, 0.7))
	_inspector_cog.add_theme_color_override("icon_hover_color", Color(0.95, 0.95, 1.0))
	_inspector_cog.add_theme_color_override("icon_pressed_color", Color("#4AAF78"))
	# Godot uses a SEPARATE icon color for "hovering while toggled on" —
	# without this it falls back to the editor theme's default (a blue
	# accent), so hovering the cog while its popup is open flashed blue.
	_inspector_cog.add_theme_color_override("icon_hover_pressed_color", Color("#4AAF78"))
	var empty := StyleBoxEmpty.new()
	_inspector_cog.add_theme_stylebox_override("normal", empty)
	_inspector_cog.add_theme_stylebox_override("hover", empty)
	_inspector_cog.add_theme_stylebox_override("pressed", empty)
	_inspector_cog.add_theme_stylebox_override("focus", empty)
	_inspector_cog.pressed.connect(func(): emit_signal("inspector_requested", self))
	hbox.add_child(_inspector_cog)
	# Stays visible=true (always laid out — reserves its column width in the
	# titlebar hbox) forever. Hover show/hide is done via opacity + mouse_filter
	# instead of Control.visible, so the titlebar/title-label width never jumps
	# when the cog fades in/out (toggling .visible would remove it from the
	# HBoxContainer's layout pass entirely, reflowing the title label wider).
	# Set directly (not via _set_cog_hover_visible) — a fresh Button defaults to
	# modulate.a = 1.0 and mouse_filter = STOP, and _cog_hover_shown already
	# defaults to false, so the toggle helper's "no change" guard would skip
	# ever actually applying the hidden state on this first call.
	_inspector_cog.modulate.a = 0.0
	_inspector_cog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cog_hover_shown = false


func _set_cog_hover_visible(v: bool) -> void:
	if not _inspector_cog or _cog_hover_shown == v:
		return
	_cog_hover_shown = v
	_inspector_cog.modulate.a = 1.0 if v else 0.0
	_inspector_cog.mouse_filter = Control.MOUSE_FILTER_STOP if v else Control.MOUSE_FILTER_IGNORE


# Called by nyx_node_inspector.gd when its popup opens/closes on this node —
# pins the cog visible for the duration (a clear "this node's popup is open"
# indicator) regardless of where the cursor wanders in the meantime, AND
# renders it in its toggled/active state (icon_pressed_color, the brand
# green) instead of the passive hover grey — set_pressed_no_signal since this
# is a state sync, not a real click, and must not re-fire "pressed" (which
# would loop back into emitting inspector_requested). Going back to false
# doesn't force a hide; it just hands control back to the normal hover-driven
# show/hide (_process/_on_hover_enter/_on_hover_exit).
func set_inspector_popup_open(v: bool) -> void:
	_inspector_popup_open = v
	if v:
		_set_cog_hover_visible(true)
	if _inspector_cog:
		_inspector_cog.set_pressed_no_signal(v)


static var _cog_icon_cache: ImageTexture


# Cached at the class level (static) — every node instance shares one decoded/
# resized texture instead of re-rasterizing the SVG per node.
static func _get_cog_icon() -> ImageTexture:
	if _cog_icon_cache:
		return _cog_icon_cache
	var tex := load("res://addons/nyx/icons/tool.svg") as Texture2D
	if not tex:
		return null
	var img := tex.get_image()
	# Rasterized smaller than the button's own custom_minimum_size (20) on
	# purpose — the button's layout footprint (titlebar width reservation)
	# is independent of the icon's own pixel size, so this only shrinks the
	# glyph visually, centered in the same clickable area.
	img.resize(10, 10, Image.INTERPOLATE_LANCZOS)
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			if px.a > 0.0:
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, px.a))
	_cog_icon_cache = ImageTexture.create_from_image(img)
	return _cog_icon_cache


func _on_node_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.double_click \
			and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("inspector_requested", self)


# Hide/show the per-node preview chevron. Particle mode disables previews
# (per-particle values have no per-pixel meaning); force any open one closed.
func set_preview_chevron_visible(v: bool) -> void:
	if _preview_chevron == null:
		return
	_preview_chevron.visible = v
	if not v and _preview_open:
		# Reset the open-state visuals; the viewport/material meta teardown is
		# handled by nyx_main when the shader mode changes.
		_preview_open = false
		_preview_chevron.text = "▾"
		if _preview_spacer:
			_preview_spacer.visible = false
		if _preview_wrapper:
			_preview_wrapper.visible = false
		call_deferred("reset_size")


static func _type_color(type: int) -> Color:
	match type:
		1: return Color("#4BB896")  # float — sage-teal
		2: return Color("#5CC96A")  # vec2  — muted green
		3: return Color("#C0E030")  # vec4  — earthy chartreuse
	return Color("#90D640")         # vec3  — earthy lime


# Scales a 1.0-base pixel constant by the editor's interface scale factor.
# Every hardcoded pixel size in Nyx is a *logical* (1.0-scale) value; run it
# through this at apply time so nodes/controls stay proportional to the
# editor's theme-scaled text on any DPI (laptop 75%, desktop 100%, etc.).
# See the "editor scale" gotcha in CLAUDE.md.
static func _s(px: float) -> float:
	return px * EditorInterface.get_editor_scale()


func _apply_style() -> void:
	var color := _node_color

	_body_style = StyleBoxFlat.new()
	_body_style.bg_color = color
	_body_style.corner_radius_top_left = 0
	_body_style.corner_radius_top_right = 0
	_body_style.corner_radius_bottom_left = 12
	_body_style.corner_radius_bottom_right = 6
	_body_style.expand_margin_top = 2
	_body_style.content_margin_left = 2
	_body_style.content_margin_right = 2
	_body_style.content_margin_bottom = 6
	_body_style.border_width_left = 1
	_body_style.border_width_right = 1
	_body_style.border_width_bottom = 1
	_body_style.border_color = Color("#1A1A26")
	add_theme_stylebox_override("panel", _body_style)
	add_theme_constant_override("separation", 4)

	var titlebar := StyleBoxFlat.new()
	titlebar.bg_color = color
	titlebar.corner_radius_top_left = 6
	titlebar.corner_radius_top_right = 12
	titlebar.corner_radius_bottom_left = 0
	titlebar.corner_radius_bottom_right = 0
	titlebar.content_margin_bottom = -1
	titlebar.content_margin_left = 6
	titlebar.border_width_top = 1
	titlebar.border_width_left = 1
	titlebar.border_width_right = 1
	titlebar.border_color = Color("#1A1A26")
	add_theme_stylebox_override("titlebar", titlebar)
	_titlebar_style = titlebar
	if not mouse_entered.is_connected(_on_hover_enter):
		mouse_entered.connect(_on_hover_enter)
		mouse_exited.connect(_on_hover_exit)

	add_theme_stylebox_override("panel_selected", _body_style)
	add_theme_stylebox_override("titlebar_selected", _titlebar_style)
	add_theme_icon_override("port", _create_port_texture(10, 1))
	call_deferred("_center_title")


func _apply_selection_style(body: StyleBoxFlat, titlebar: StyleBoxFlat) -> void:
	_body_style = body
	_titlebar_style = titlebar
	add_theme_stylebox_override("panel_selected", body)
	add_theme_stylebox_override("titlebar_selected", titlebar)


func _on_selected() -> void:
	# Selection is shown by the halo (see _draw) — keep the body border neutral so
	# we don't stack a second green ring. Reset off the hover-green from the click.
	_body_style.border_color = Color("#1A1A26")
	_titlebar_style.border_color = Color("#1A1A26")
	queue_redraw()


func _on_deselected() -> void:
	var hovered := get_global_rect().has_point(get_global_mouse_position())
	var c := Color("#31614F") if hovered else Color("#1A1A26")
	_body_style.border_color = c
	_titlebar_style.border_color = c
	queue_redraw()


func _on_hover_enter() -> void:
	_set_cog_hover_visible(true)
	if selected:
		return
	_body_style.border_color = Color("#31614F")
	_titlebar_style.border_color = Color("#31614F")


func _on_hover_exit() -> void:
	# mouse_exited fires whenever a child control (spinbox, titlebar label, even
	# the cog button itself) becomes the topmost control under the cursor, not
	# just on a true geometric exit — so a raw mouse_exited alone flickers the
	# cog off while the cursor is still over the node. Only actually treat this
	# as a hover-exit if the cursor is truly outside the node's rect (same
	# defensive check _on_deselected() already uses).
	if get_global_rect().has_point(get_global_mouse_position()):
		return
	# The cog stays pinned visible for as long as this node's inspector popup
	# is open, regardless of cursor position — see set_inspector_popup_open().
	if not _inspector_popup_open:
		_set_cog_hover_visible(false)
	if selected:
		return
	_body_style.border_color = Color("#1A1A26")
	_titlebar_style.border_color = Color("#1A1A26")


# mouse_entered/mouse_exited turned out too unreliable to be the sole source of
# truth for the cog's visibility — two distinct ways to miss an exit found in
# testing: (1) the node-inspector popup covering the node on a click, with no
# further mouse motion for Godot to recompute hover on; (2) leaving the node via
# a port dot, which overhangs the node's actual Control rect by ~12px for
# GraphEdit's own connection grab zone (see nyx_main.gd's _is_mouse_over_node) —
# that zone is hit-tested by GraphEdit itself, not ordinary Control hover
# tracking, so crossing it doesn't reliably produce a clean mouse_exited. Rather
# than patch each case, this is a lightweight per-frame correctness backstop:
# the signal handlers above are still the fast reactive path (no visible lag on
# the common case), this just guarantees the state is never stuck wrong for more
# than a frame regardless of what the signals did.
func _process(_delta: float) -> void:
	if not _inspector_cog or not is_visible_in_tree() or _inspector_popup_open:
		return
	var hovered := get_global_rect().has_point(get_global_mouse_position())
	if hovered and not _cog_hover_shown:
		_on_hover_enter()
	elif not hovered and _cog_hover_shown:
		_on_hover_exit()


func _center_title() -> void:
	var hbox := get_titlebar_hbox()
	for child in hbox.get_children():
		if child is Label:
			child.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			child.add_theme_color_override("font_color", Color.WHITE)
			child.add_theme_constant_override("outline_size", 0)
			child.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
			child.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
			child.add_theme_constant_override("shadow_offset_x", 0)
			child.add_theme_constant_override("shadow_offset_y", 0)
			return


func _create_port_texture(size: int, outline: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var outer_radius := size / 2.0
	var inner_radius := outer_radius - outline
	var aa := 1.2

	for x in range(size):
		for y in range(size):
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var outer_alpha := clamp((outer_radius - dist) / aa, 0.0, 1.0)
			var inner_blend := clamp((dist - inner_radius) / aa, 0.0, 1.0)
			if outer_alpha <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var fill := Color.WHITE
				var ring := Color(0.1, 0.1, 0.1, 1.0)
				var pixel := fill.lerp(ring, inner_blend)
				pixel.a = outer_alpha
				img.set_pixel(x, y, pixel)

	return ImageTexture.create_from_image(img)


func _apply_input_styles() -> void:
	_style_inputs_recursive(self)


func _style_inputs_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Popup:
			continue
		if child is SpinBox:
			_style_spinbox(child)
			continue
		if child is LineEdit:
			_style_lineedit(child)
		elif child is TextEdit:
			_style_textedit(child)
		_style_inputs_recursive(child)


func _make_input_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#3C4655")
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _style_spinbox(sb: SpinBox) -> void:
	var style := _make_input_style()
	var le := sb.get_line_edit()
	le.add_theme_stylebox_override("normal", style)
	le.add_theme_stylebox_override("focus", style)


func _style_lineedit(le: LineEdit) -> void:
	var style := _make_input_style()
	le.add_theme_stylebox_override("normal", style)
	le.add_theme_stylebox_override("focus", style)


func _style_textedit(te: TextEdit) -> void:
	var style := _make_input_style()
	te.add_theme_stylebox_override("normal", style)
	te.add_theme_stylebox_override("focus", style)


func get_shader_snippet(inputs: Array = []) -> String:
	return ""


func get_output_snippet(port: int, inputs: Array = []) -> String:
	return get_shader_snippet(inputs)


func get_shader_functions() -> Dictionary:
	return {}


func get_default_inputs() -> Array:
	return []


func get_default_input_types() -> Array:
	return []


func is_polymorphic() -> bool:
	return false


# Optional semantic hint for nodes whose output is conceptually a "color" or a
# generic "vector". Split reads this off whatever feeds it to decide between
# R/G/B/A and X/Y/Z/W output labels. "" = no opinion.
func get_vector_semantic() -> String:
	return ""


func get_output_type(from_port: int, input_types: Array) -> int:
	if is_polymorphic():
		return _dominant_type(input_types)
	return get_output_port_type(from_port)


# Resolve the widest type among inputs. Rank: float < vec2 < vec3 < vec4.
# Type IDs: 0 = vec3, 1 = float, 2 = vec2, 3 = vec4. Float inputs promote up to
# whatever vec type is present; an all-float set stays float.
func _dominant_type(input_types: Array) -> int:
	var rank := {1: 0, 2: 1, 0: 2, 3: 3}
	var best := 1
	var best_rank := 0
	for t in input_types:
		var r: int = rank.get(t, 0)
		if r > best_rank:
			best_rank = r
			best = t
	return best


func get_state() -> Dictionary:
	return {}


func set_state(_state: Dictionary) -> void:
	pass


func get_param_export_line() -> String:
	return ""


func apply_shader_params(_material: ShaderMaterial) -> void:
	pass
