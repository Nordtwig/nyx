@tool
extends Control

const NyxNodeBase = preload("res://addons/nyx/nodes/nyx_node.gd")
const OutputNode = preload("res://addons/nyx/nodes/output_node.gd")
const ColorNode = preload("res://addons/nyx/nodes/color_node.gd")
const AddNode = preload("res://addons/nyx/nodes/add_node.gd")
const MultiplyNode = preload("res://addons/nyx/nodes/multiply_node.gd")
const MixNode = preload("res://addons/nyx/nodes/mix_node.gd")
const UVNode = preload("res://addons/nyx/nodes/uv_node.gd")
const FloatNode = preload("res://addons/nyx/nodes/float_node.gd")
const SubtractNode = preload("res://addons/nyx/nodes/subtract_node.gd")
const ClampNode = preload("res://addons/nyx/nodes/clamp_node.gd")
const PowerNode = preload("res://addons/nyx/nodes/power_node.gd")
const SinNode = preload("res://addons/nyx/nodes/sin_node.gd")
const CosNode = preload("res://addons/nyx/nodes/cos_node.gd")
const TimeNode = preload("res://addons/nyx/nodes/time_node.gd")
const SplitNode = preload("res://addons/nyx/nodes/split_node.gd")
const CombineNode = preload("res://addons/nyx/nodes/combine_node.gd")
const TextureSampleNode = preload("res://addons/nyx/nodes/texture_sample_node.gd")
const FresnelNode = preload("res://addons/nyx/nodes/fresnel_node.gd")
const ScaleNode = preload("res://addons/nyx/nodes/scale_node.gd")
const StepNode = preload("res://addons/nyx/nodes/step_node.gd")
const SmoothstepNode = preload("res://addons/nyx/nodes/smoothstep_node.gd")
const NoiseNode = preload("res://addons/nyx/nodes/noise_node.gd")
const FBMNode = preload("res://addons/nyx/nodes/fbm_node.gd")
const GradientNode = preload("res://addons/nyx/nodes/gradient_node.gd")
const CurveNode = preload("res://addons/nyx/nodes/curve_node.gd")
const TilingOffsetNode = preload("res://addons/nyx/nodes/tiling_offset_node.gd")
const NormalFromHeightNode = preload("res://addons/nyx/nodes/normal_from_height_node.gd")
const BlendNormalsNode = preload("res://addons/nyx/nodes/blend_normals_node.gd")
const ScreenUVNode = preload("res://addons/nyx/nodes/screen_uv_node.gd")
const ScreenTextureNode = preload("res://addons/nyx/nodes/screen_texture_node.gd")
const DepthFadeNode = preload("res://addons/nyx/nodes/depth_fade_node.gd")
const RotateUVNode = preload("res://addons/nyx/nodes/rotate_uv_node.gd")
const WarpNode = preload("res://addons/nyx/nodes/warp_node.gd")
const VertexNode = preload("res://addons/nyx/nodes/vertex_node.gd")
const NormalMapNode = preload("res://addons/nyx/nodes/normal_map_node.gd")
const AbsNode = preload("res://addons/nyx/nodes/abs_node.gd")
const CeilNode = preload("res://addons/nyx/nodes/ceil_node.gd")
const FloorNode = preload("res://addons/nyx/nodes/floor_node.gd")
const FractNode = preload("res://addons/nyx/nodes/fract_node.gd")
const NegateNode = preload("res://addons/nyx/nodes/negate_node.gd")
const OneMinusNode = preload("res://addons/nyx/nodes/one_minus_node.gd")
const RoundNode = preload("res://addons/nyx/nodes/round_node.gd")
const SqrtNode = preload("res://addons/nyx/nodes/sqrt_node.gd")
const MinMaxNode = preload("res://addons/nyx/nodes/min_max_node.gd")
const DivideNode = preload("res://addons/nyx/nodes/divide_node.gd")
const ModNode = preload("res://addons/nyx/nodes/mod_node.gd")
const NormalizeNode = preload("res://addons/nyx/nodes/normalize_node.gd")
const CustomGLSLNode = preload("res://addons/nyx/nodes/custom_glsl_node.gd")
const Vector3Node = preload("res://addons/nyx/nodes/vector3_node.gd")
const RerouteNode = preload("res://addons/nyx/nodes/reroute_node.gd")
const RelayNode = preload("res://addons/nyx/nodes/relay_node.gd")
const PreviewRelayNode = preload("res://addons/nyx/nodes/preview_relay_node.gd")
const SpriteTextureNode = preload("res://addons/nyx/nodes/sprite_texture_node.gd")
const VertexColorNode = preload("res://addons/nyx/nodes/vertex_color_node.gd")
const TexturePixelSizeNode = preload("res://addons/nyx/nodes/texture_pixel_size_node.gd")
const LengthNode = preload("res://addons/nyx/nodes/length_node.gd")
const DotNode = preload("res://addons/nyx/nodes/dot_node.gd")
const ParticleStartNode = preload("res://addons/nyx/nodes/particle_start_node.gd")
const ParticleProcessNode = preload("res://addons/nyx/nodes/particle_process_node.gd")
const ParticleAgeNode = preload("res://addons/nyx/nodes/particle_age_node.gd")
const ParticleVelocityNode = preload("res://addons/nyx/nodes/particle_velocity_node.gd")
const ParticlePositionNode = preload("res://addons/nyx/nodes/particle_position_node.gd")
const ParticleDeltaNode = preload("res://addons/nyx/nodes/particle_delta_node.gd")
const ParticleRandomNode = preload("res://addons/nyx/nodes/particle_random_node.gd")
const ParticleIndexNode = preload("res://addons/nyx/nodes/particle_index_node.gd")
const VertexOutputNode = preload("res://addons/nyx/nodes/vertex_output_node.gd")

const NyxRegistry = preload("res://addons/nyx/nyx_registry.gd")

# Twilight palette — cooler, muted category accents that sit clearly above the
# dark abyss background without competing with the bright connection lines.
# Tune a whole category by editing one constant here.
const _CAT_INPUTS  := Color(0.14, 0.14, 0.18)
const _CAT_MATH    := Color(0.14, 0.14, 0.18)
const _CAT_VECTOR  := Color(0.14, 0.14, 0.18)
const _CAT_TEXTURE := Color(0.14, 0.14, 0.18)
const _CAT_OUTPUT  := Color(0.14, 0.14, 0.18)

const _TYPE_COLORS := {
	# Inputs
	"FloatNode":    _CAT_INPUTS,
	"Vector3Node":  _CAT_INPUTS,
	"UVNode":       _CAT_INPUTS,
	"VertexNode":   _CAT_INPUTS,
	"TimeNode":     _CAT_INPUTS,
	# Screen
	"ScreenUVNode":      _CAT_INPUTS,
	"ScreenTextureNode": _CAT_INPUTS,
	"DepthFadeNode":     _CAT_INPUTS,
	# Math
	"AddNode":      _CAT_MATH,
	"SubtractNode": _CAT_MATH,
	"MultiplyNode": _CAT_MATH,
	"DivideNode":   _CAT_MATH,
	"MixNode":      _CAT_MATH,
	"ClampNode":    _CAT_MATH,
	"PowerNode":    _CAT_MATH,
	"MinMaxNode":   _CAT_MATH,
	"ModNode":      _CAT_MATH,
	"AbsNode":      _CAT_MATH,
	"CeilNode":     _CAT_MATH,
	"FloorNode":    _CAT_MATH,
	"FractNode":    _CAT_MATH,
	"NegateNode":   _CAT_MATH,
	"OneMinusNode": _CAT_MATH,
	"RoundNode":    _CAT_MATH,
	"SqrtNode":     _CAT_MATH,
	"SinNode":      _CAT_MATH,
	"CosNode":      _CAT_MATH,
	# Shape — mathematical value ops
	"FresnelNode":    _CAT_MATH,
	"StepNode":       _CAT_MATH,
	"SmoothstepNode": _CAT_MATH,
	# Advanced
	"CustomGLSLNode": _CAT_MATH,
	# Vector
	"NormalizeNode":       _CAT_VECTOR,
	"LengthNode":          _CAT_VECTOR,
	"DotNode":             _CAT_VECTOR,
	"SplitNode":           _CAT_VECTOR,
	"CombineNode":         _CAT_VECTOR,
	"NormalFromHeightNode": _CAT_VECTOR,
	"BlendNormalsNode":    _CAT_VECTOR,
	"ScaleNode":           _CAT_VECTOR,
	# Texture
	"TextureSampleNode": _CAT_TEXTURE,
	"NormalMapNode":     _CAT_TEXTURE,
	"GradientNode":      _CAT_TEXTURE,
	"CurveNode":         _CAT_TEXTURE,
	# UV
	"TilingOffsetNode": _CAT_TEXTURE,
	"RotateUVNode":     _CAT_TEXTURE,
	"WarpNode":         _CAT_TEXTURE,
	# Noise/Procedural
	"NoiseNode": _CAT_TEXTURE,
	"FBMNode":   _CAT_TEXTURE,
	# Organisation
	"RerouteNode":      _CAT_OUTPUT,
	"RelayNode":        _CAT_OUTPUT,
	"PreviewRelayNode": _CAT_OUTPUT,
	# Canvas — scene-provided inputs, like UV/Time/ScreenUV
	"SpriteTextureNode":    _CAT_INPUTS,
	"VertexColorNode":      _CAT_INPUTS,
	"TexturePixelSizeNode": _CAT_INPUTS,
	# Particles — per-particle context inputs (sinks keep their own slate style)
	"ParticleAgeNode":      _CAT_INPUTS,
	"ParticleVelocityNode": _CAT_INPUTS,
	"ParticlePositionNode": _CAT_INPUTS,
	"ParticleDeltaNode":    _CAT_INPUTS,
	"ParticleRandomNode":   _CAT_INPUTS,
	"ParticleIndexNode":    _CAT_INPUTS,
}

const NODE_CLASSES := {
	"OutputNode": OutputNode,
	"VertexOutputNode": VertexOutputNode,
	"ColorNode": ColorNode,
	"AddNode": AddNode,
	"MultiplyNode": MultiplyNode,
	"MixNode": MixNode,
	"UVNode": UVNode,
	"FloatNode": FloatNode,
	"SubtractNode": SubtractNode,
	"ClampNode": ClampNode,
	"PowerNode": PowerNode,
	"SinNode": SinNode,
	"CosNode": CosNode,
	"TimeNode": TimeNode,
	"SplitNode": SplitNode,
	"CombineNode": CombineNode,
	"TextureSampleNode": TextureSampleNode,
	"FresnelNode": FresnelNode,
	"ScaleNode": ScaleNode,
	"StepNode": StepNode,
	"SmoothstepNode": SmoothstepNode,
	"NoiseNode": NoiseNode,
	"FBMNode": FBMNode,
	"GradientNode": GradientNode,
	"CurveNode": CurveNode,
	"TilingOffsetNode": TilingOffsetNode,
	"RotateUVNode": RotateUVNode,
	"WarpNode": WarpNode,
	"NormalFromHeightNode": NormalFromHeightNode,
	"BlendNormalsNode": BlendNormalsNode,
	"ScreenUVNode": ScreenUVNode,
	"ScreenTextureNode": ScreenTextureNode,
	"DepthFadeNode": DepthFadeNode,
	"VertexNode": VertexNode,
	"NormalMapNode": NormalMapNode,
	"AbsNode": AbsNode,
	"CeilNode": CeilNode,
	"FloorNode": FloorNode,
	"FractNode": FractNode,
	"NegateNode": NegateNode,
	"OneMinusNode": OneMinusNode,
	"RoundNode": RoundNode,
	"SqrtNode": SqrtNode,
	"MinMaxNode": MinMaxNode,
	"DivideNode": DivideNode,
	"ModNode": ModNode,
	"NormalizeNode": NormalizeNode,
	"LengthNode": LengthNode,
	"DotNode": DotNode,
	"RerouteNode": RerouteNode,
	"RelayNode": RelayNode,
	"PreviewRelayNode": PreviewRelayNode,
	"CustomGLSLNode": CustomGLSLNode,
	"Vector3Node": Vector3Node,
	"SpriteTextureNode": SpriteTextureNode,
	"VertexColorNode": VertexColorNode,
	"TexturePixelSizeNode": TexturePixelSizeNode,
	"ParticleStartNode": ParticleStartNode,
	"ParticleProcessNode": ParticleProcessNode,
	"ParticleAgeNode": ParticleAgeNode,
	"ParticleVelocityNode": ParticleVelocityNode,
	"ParticlePositionNode": ParticlePositionNode,
	"ParticleDeltaNode": ParticleDeltaNode,
	"ParticleRandomNode": ParticleRandomNode,
	"ParticleIndexNode": ParticleIndexNode,
}

const _TYPE_CATEGORY := {
	"ColorNode": "Inputs",    "FloatNode": "Inputs",     "Vector3Node": "Inputs",
	"UVNode": "Inputs",       "VertexNode": "Inputs",    "TimeNode": "Inputs",
	"FresnelNode": "Inputs",
	"AddNode": "Math",        "SubtractNode": "Math",    "MultiplyNode": "Math",
	"DivideNode": "Math",     "MixNode": "Math",         "ClampNode": "Math",
	"PowerNode": "Math",      "MinMaxNode": "Math",      "ModNode": "Math",
	"AbsNode": "Math",        "CeilNode": "Math",        "FloorNode": "Math",
	"FractNode": "Math",      "NegateNode": "Math",      "OneMinusNode": "Math",
	"RoundNode": "Math",      "SqrtNode": "Math",        "SinNode": "Math",
	"CosNode": "Math",        "StepNode": "Math",        "SmoothstepNode": "Math",
	"NormalizeNode": "Vector", "LengthNode": "Vector",   "DotNode": "Vector",
	"SplitNode": "Vector",    "CombineNode": "Vector",   "ScaleNode": "Vector",
	"NoiseNode": "Noise",     "FBMNode": "Noise",
	"TextureSampleNode": "Texture", "NormalMapNode": "Texture",
	"GradientNode": "Texture", "CurveNode": "Texture",
	"TilingOffsetNode": "UV", "RotateUVNode": "UV",      "WarpNode": "UV",
	"NormalFromHeightNode": "UV", "BlendNormalsNode": "UV",
	"ScreenUVNode": "Screen", "ScreenTextureNode": "Screen", "DepthFadeNode": "Screen",
	"SpriteTextureNode": "Canvas", "VertexColorNode": "Canvas",
	"TexturePixelSizeNode": "Canvas",
	"ParticleStartNode": "Particles",   "ParticleProcessNode": "Particles",
	"ParticleAgeNode": "Particles",     "ParticleVelocityNode": "Particles",
	"ParticlePositionNode": "Particles","ParticleDeltaNode": "Particles",
	"ParticleRandomNode": "Particles",  "ParticleIndexNode": "Particles",
	"RerouteNode": "Organisation",      "RelayNode": "Organisation",
	"PreviewRelayNode": "Organisation",
	"CustomGLSLNode": "Advanced",
}

signal reload_requested

var _outer_vbox: VBoxContainer
var _graph_container: VBoxContainer
var _graph: GraphEdit
var _shader_type: int = 0
var _type_btn: Button
var _type_popup: PopupMenu
var _render_mode_btn: Button
var _render_mode_popup: PopupMenu
var _properties_panel: Panel
var _properties_vbox: VBoxContainer
var _properties_detail_vbox: VBoxContainer
var _selected_param_row: Control = null
# Preview panel (floating — owns viewports/materials/mesh-switcher/particles/drag+resize).
# Per-node preview manager (SubViewport-per-node lifecycle). Both extracted from this file.
const NyxPreviewPanel = preload("res://addons/nyx/nyx_preview_panel.gd")
const NyxNodePreviews = preload("res://addons/nyx/nyx_node_previews.gd")
var _preview_panel  # NyxPreviewPanel instance
var _node_previews  # NyxNodePreviews instance
var _type_legend: PanelContainer
var _legend_toggle: Button
var _minimap_toggle: Button
var _shortcuts_overlay: PanelContainer
var _panning: bool = false
var _pan_moved: bool = false  # did the cursor move during the current empty-canvas drag?
var _clipboard: Dictionary = {}  # {nodes, connections} from the last copy
var _preview_positioned: bool = false
var _properties_positioned: bool = false
var _compile_timer: Timer
# Node-search popup. Self-contained Control component (owns its overlay/cards/doc/icons);
# emits node_chosen(id) → _on_search_node_chosen spawns. See nyx_search_popup.gd.
const NyxSearchPopup = preload("res://addons/nyx/nyx_search_popup.gd")
var _search_popup  # NyxSearchPopup instance
var _export_dialog: EditorFileDialog
var _save_dialog: EditorFileDialog
var _load_dialog: EditorFileDialog
var _texture_dialog: EditorFileDialog
var _new_confirm: ConfirmationDialog
var _load_confirm: ConfirmationDialog
var _file_btn: Button
var _file_popup: PopupMenu
var _recent_popup: PopupMenu
var _filename_label: Label
var _dirty: bool = false              # unsaved changes to the .nyx working file
var _loading: bool = false            # suppresses dirty-marking during load/new
var _pending_load_path: String = ""   # path awaiting the discard-changes confirm
var _pending_after_save: Callable = Callable()  # run after a "Save & …" completes
var _texture_target: Node = null
var _spawn_position: Vector2
# Shader compiler (graph → GLSL). Extracted from this file; holds a reference to
# _graph and is constructed once in _ready. See nyx_compiler.gd.
const NyxCompiler = preload("res://addons/nyx/nyx_compiler.gd")
var _compiler  # NyxCompiler instance

# Persistence layer (.nyx disk format + dict↔resource bridge). Stateless/static.
# graph→dict (_serialize_graph) and dict→graph (_deserialize_graph) stay here; this
# only owns disk↔format. See nyx_serializer.gd.
const NyxSerializer = preload("res://addons/nyx/nyx_serializer.gd")

# Live link / linked artifact state.
const NyxCharon = preload("res://addons/nyx/core/charon.gd")
var _export_mode: String = "full"         # "full" | "shader_only" (drives _on_export_file_selected)
var _current_nyx_path: String = ""        # working .nyx file on disk ("" = unsaved)
var _linked_shader_path: String = ""      # linked exported .gdshader ("" = unlinked)
var _live_link_on: bool = false
var _export_btn: Button                   # contextual Export… / Update
var _export_menu: MenuButton              # caret dropdown (new material / shader only / re-link / unlink)
var _live_btn: CheckButton
var _undo_stack: Array = []
var _redo_stack: Array = []
var _pre_drag_snapshot = null


func _ready() -> void:
	name = "NyxMain"

	_compile_timer = Timer.new()
	_compile_timer.wait_time = 0.3
	_compile_timer.one_shot = true
	_compile_timer.timeout.connect(_compile_shader)
	add_child(_compile_timer)

	_graph = GraphEdit.new()
	_compiler = NyxCompiler.new(_graph)
	_graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph.grid_pattern = GraphEdit.GRID_PATTERN_DOTS
	_graph.snapping_enabled = false
	_graph.minimap_enabled = false
	_graph.show_minimap_button = false
	call_deferred("_style_graph_toolbar")
	var graph_bg := StyleBoxFlat.new()
	graph_bg.bg_color = Color("#0D0D0F")
	_graph.add_theme_stylebox_override("panel", graph_bg)
	_graph.right_disconnects = true
	_graph.connection_request.connect(_on_connection_request)
	_graph.disconnection_request.connect(_on_disconnection_request)
	_graph.delete_nodes_request.connect(_on_delete_nodes_request)
	# GraphEdit owns Ctrl+C/V/D when focused (it intercepts them in its own gui_input and
	# emits these signals), so handling them in _shortcut_input never fires. Wire the
	# signals instead — a focused text field consumes the keys first, so node copy/paste
	# only triggers when the graph itself has focus. No manual text-field guard needed.
	_graph.copy_nodes_request.connect(_copy_selected_nodes)
	_graph.paste_nodes_request.connect(_paste_clipboard)
	_graph.duplicate_nodes_request.connect(_duplicate_selected_nodes)
	_graph.gui_input.connect(_on_graph_gui_input)
	# Type IDs: 0 = vec3, 1 = float, 2 = vec2, 3 = vec4.
	# Same-type connections:
	_graph.add_valid_connection_type(0, 0)
	_graph.add_valid_connection_type(1, 1)
	_graph.add_valid_connection_type(2, 2)
	_graph.add_valid_connection_type(3, 3)
	# Implicit promotion (widening only):
	_graph.add_valid_connection_type(1, 2)  # float → vec2
	_graph.add_valid_connection_type(1, 0)  # float → vec3
	_graph.add_valid_connection_type(1, 3)  # float → vec4
	_graph.add_valid_connection_type(2, 0)  # vec2  → vec3
	_graph.add_valid_connection_type(2, 3)  # vec2  → vec4
	_graph.add_valid_connection_type(0, 3)  # vec3  → vec4
	# The one sanctioned narrowing — dropping alpha is unambiguous (.rgb):
	_graph.add_valid_connection_type(3, 0)  # vec4  → vec3

	_graph_container = VBoxContainer.new()
	_graph_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_container.add_theme_constant_override("separation", 0)
	_graph_container.add_child(_graph)

	_outer_vbox = VBoxContainer.new()
	_outer_vbox.add_theme_constant_override("separation", 0)
	_outer_vbox.add_child(_build_graph_toolbar())
	_outer_vbox.add_child(_graph_container)
	add_child(_outer_vbox)

	_search_popup = NyxSearchPopup.new()
	add_child(_search_popup)
	_search_popup.setup(_graph_container)
	_search_popup.node_chosen.connect(_on_search_node_chosen)

	_export_dialog = EditorFileDialog.new()
	_export_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_export_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_export_dialog.add_filter("*.gdshader", "GDShader File")
	_export_dialog.file_selected.connect(_on_export_file_selected)
	add_child(_export_dialog)

	_save_dialog = EditorFileDialog.new()
	_save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_save_dialog.add_filter("*.nyx", "Nyx Graph")
	_save_dialog.file_selected.connect(_on_save_file_selected)
	# Cancelling the save drops any pending "Save & New/Load" so a later plain
	# Save can't accidentally trigger the stale follow-up action.
	_save_dialog.canceled.connect(func(): _pending_after_save = Callable())
	add_child(_save_dialog)

	_load_dialog = EditorFileDialog.new()
	_load_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_load_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_load_dialog.add_filter("*.nyx", "Nyx Graph")
	_load_dialog.file_selected.connect(load_nyx)
	add_child(_load_dialog)

	_texture_dialog = EditorFileDialog.new()
	_texture_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_texture_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_texture_dialog.add_filter("*.png,*.jpg,*.jpeg,*.bmp,*.webp,*.tga,*.exr,*.hdr", "Image Files")
	_texture_dialog.file_selected.connect(_on_texture_file_selected)
	add_child(_texture_dialog)

	# OK button = the safe "Save & …" action, so the default/highlighted/Enter
	# choice is never the destructive Discard. Order forced to [Save | Discard | Cancel].
	_new_confirm = ConfirmationDialog.new()
	_new_confirm.title = "New Graph"
	_new_confirm.dialog_text = "You have unsaved changes."
	_new_confirm.ok_button_text = "Save & New"
	var discard_new := _new_confirm.add_button("Discard & New", false, "discard")
	_new_confirm.confirmed.connect(func(): _save_then(_new_graph))
	_new_confirm.custom_action.connect(func(action: StringName):
		if action == &"discard":
			_new_confirm.hide()
			_new_graph()
	)
	_order_dialog_buttons(_new_confirm, discard_new)
	add_child(_new_confirm)

	_load_confirm = ConfirmationDialog.new()
	_load_confirm.title = "Load Graph"
	_load_confirm.dialog_text = "You have unsaved changes."
	_load_confirm.ok_button_text = "Save & Load"
	var discard_load := _load_confirm.add_button("Discard & Load", false, "discard")
	_load_confirm.confirmed.connect(func(): _save_then(func(): _do_load(_pending_load_path)))
	_load_confirm.custom_action.connect(func(action: StringName):
		if action == &"discard":
			_load_confirm.hide()
			_do_load(_pending_load_path)
	)
	_order_dialog_buttons(_load_confirm, discard_load)
	add_child(_load_confirm)

	_preview_panel = NyxPreviewPanel.new()
	add_child(_preview_panel)
	_preview_panel.setup(_graph, _graph_container)
	_node_previews = NyxNodePreviews.new()
	add_child(_node_previews)
	_node_previews.setup(_graph, _compiler)
	_properties_panel = _build_properties_panel()
	add_child(_properties_panel)
	_update_link_ui()  # unlinked: "Export…", Live disabled

	_type_legend = _build_type_legend()
	_type_legend.visible = false
	add_child(_type_legend)
	_legend_toggle = _build_legend_toggle()
	add_child(_legend_toggle)
	call_deferred("_reposition_legend")
	_minimap_toggle = _build_minimap_toggle()
	add_child(_minimap_toggle)
	call_deferred("_reposition_minimap_toggle")
	_shortcuts_overlay = _build_shortcuts_overlay()
	add_child(_shortcuts_overlay)

	_add_node(OutputNode.new(), Vector2(300, 160), "OutputNode")
	_add_node(VertexOutputNode.new(), Vector2(300, 40), "VertexOutputNode")
	_update_sink_visibility()
	_frame_default_view()


# Frame the graph view so the default node cluster sits in the top-left with a
# small margin. Deferred: scroll_offset only sticks after GraphEdit lays out.
func _frame_default_view() -> void:
	call_deferred("_do_frame_default_view")


func _do_frame_default_view() -> void:
	if not _graph:
		return
	# Wait for the deferred node resize pass; GraphEdit re-clamps scroll_offset
	# against the node bounding box afterward, which would otherwise snap y back.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(_graph):
		return
	_graph.zoom = 1.0
	_graph.scroll_offset = Vector2(-600, -100)


func _add_node(node: Node, offset: Vector2, node_name: String = "") -> void:
	if node_name != "":
		node.name = node_name
	var type_name := _get_node_type(node)
	if _TYPE_COLORS.has(type_name):
		node._node_color = _TYPE_COLORS[type_name]
	node._category = _TYPE_CATEGORY.get(type_name, "")
	node.position_offset = offset
	_graph.add_child(node)
	if node.has_signal("value_changed"):
		node.value_changed.connect(_request_compile)
		node.value_changed.connect(_mark_dirty)
		node.value_changed.connect(func():
			if _properties_panel and _properties_panel.visible:
				_rebuild_properties_list()
		)
	if node.has_signal("edit_started"):
		node.edit_started.connect(_push_undo_state)
	if node.has_signal("texture_pick_requested"):
		node.texture_pick_requested.connect(_on_texture_pick_requested)
	if node.has_signal("pair_removed"):
		node.pair_removed.connect(func(idx: int): _on_relay_pair_removed(node, idx))
	if node.has_signal("preview_toggled"):
		node.preview_toggled.connect(func():
			if node.has_meta("_preview_material"):
				_node_previews.close(node)
			else:
				_node_previews.open(node, _shader_type)
		)
	node.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_pre_drag_snapshot = _serialize_graph()
	)
	if node.has_signal("dragged"):
		node.dragged.connect(func(_f: Vector2, _t: Vector2):
			if _pre_drag_snapshot != null:
				_undo_stack.push_back(_pre_drag_snapshot)
				if _undo_stack.size() > 50:
					_undo_stack.pop_front()
				_redo_stack.clear()
				_pre_drag_snapshot = null
				_mark_dirty()
		)
	# Nodes spawned while in particle mode shouldn't carry a preview chevron.
	if _shader_type == 2 and node.has_method("set_preview_chevron_visible"):
		node.call_deferred("set_preview_chevron_visible", false)


func _request_compile() -> void:
	_compile_timer.stop()
	_compile_timer.start()


func _compile_shader() -> void:
	if _graph.get_node_or_null("OutputNode") or _graph.get_node_or_null("VertexOutputNode") or _shader_type == 2:
		var code: String = _compiler.build_shader_code(_shader_type)
		if _preview_panel.compile(code, _shader_type):
			if _live_link_on and not _linked_shader_path.is_empty():
				NyxCharon.notify_shader_updated(_linked_shader_path, _preview_panel.get_active_material())
		_preview_panel.apply_uniforms()
	if _shader_type != 2:
		_node_previews.refresh_all(_shader_type)


func _update_sink_visibility() -> void:
	var output_node = _graph.get_node_or_null("OutputNode")
	if output_node:
		output_node.visible = _shader_type != 2
	var vertex_output_node = _graph.get_node_or_null("VertexOutputNode")
	if vertex_output_node:
		vertex_output_node.visible = _shader_type == 0
	var start_node = _graph.get_node_or_null("ParticleStartNode")
	if start_node:
		start_node.visible = _shader_type == 2
	var process_node = _graph.get_node_or_null("ParticleProcessNode")
	if process_node:
		process_node.visible = _shader_type == 2
	if _preview_panel:
		_preview_panel.update_for_shader_type(_shader_type)
	for child in _graph.get_children():
		if child is GraphNode and child.has_method("set_preview_chevron_visible"):
			child.set_preview_chevron_visible(_shader_type != 2)


func _on_relay_pair_removed(relay: Node, removed_idx: int) -> void:
	var relay_name := str(relay.name)
	var c := _graph.get_connection_list()
	var to_reconnect := []
	for conn in c:
		var from := str(conn["from_node"])
		var to := str(conn["to_node"])
		var fp: int = conn["from_port"]
		var tp: int = conn["to_port"]
		if to == relay_name and tp == removed_idx:
			_graph.disconnect_node(from, fp, to, tp)
		elif to == relay_name and tp > removed_idx:
			_graph.disconnect_node(from, fp, to, tp)
			to_reconnect.append({"from": from, "fp": fp, "to": to, "tp": tp - 1})
		elif from == relay_name and fp == removed_idx:
			_graph.disconnect_node(from, fp, to, tp)
		elif from == relay_name and fp > removed_idx:
			_graph.disconnect_node(from, fp, to, tp)
			to_reconnect.append({"from": from, "fp": fp - 1, "to": to, "tp": tp})
	for r in to_reconnect:
		_graph.connect_node(r["from"], r["fp"], r["to"], r["tp"])
	_compiler.update_all_polymorphic_ports()
	_request_compile()


func _sync_shader_type_ui(idx: int) -> void:
	if _type_btn and _type_popup:
		_type_btn.text = _type_popup.get_item_text(idx) + "  ▾"
	_rebuild_render_mode_options()
	_rebuild_properties_list()


func _on_shader_type_changed(idx: int) -> void:
	_shader_type = idx
	_sync_shader_type_ui(idx)
	if idx == 0:
		_ensure_spatial_sinks()
		var output_node = _graph.get_node_or_null("OutputNode")
		if output_node:
			output_node.set_shader_type(0)
	elif idx == 1:
		var output_node = _graph.get_node_or_null("OutputNode")
		if output_node:
			output_node.set_shader_type(1)
	elif idx == 2:
		_ensure_particle_sinks()
	_update_sink_visibility()
	# Rebuild per-node previews for the new mode. Particle mode has no per-node
	# previews (the values are per-particle, not per-pixel), so just tear them down.
	for child in _graph.get_children():
		if child is GraphNode and child.has_meta("_preview_material"):
			_node_previews.close(child)
			if idx != 2:
				_node_previews.open(child, idx)
	_preview_panel.reset_last_code()
	_request_compile()


func _ensure_spatial_sinks() -> void:
	if not _graph.get_node_or_null("OutputNode"):
		_add_node(OutputNode.new(), Vector2(300, 160), "OutputNode")
	if not _graph.get_node_or_null("VertexOutputNode"):
		_add_node(VertexOutputNode.new(), Vector2(300, 40), "VertexOutputNode")


func _ensure_particle_sinks() -> void:
	if not _graph.get_node_or_null("ParticleStartNode"):
		_add_node(ParticleStartNode.new(), Vector2(440, 120), "ParticleStartNode")
	if not _graph.get_node_or_null("ParticleProcessNode"):
		_add_node(ParticleProcessNode.new(), Vector2(440, 360), "ParticleProcessNode")


func _on_texture_pick_requested(node: Node) -> void:
	_texture_target = node
	_texture_dialog.popup_centered_ratio(0.5)


func _on_texture_file_selected(path: String) -> void:
	if not _texture_target:
		return
	var tex = load(path)
	if tex is Texture2D:
		_push_undo_state()
		_texture_target.set_texture(tex)
	_texture_target = null


# --- Linked-artifact export / live link ---

# Contextual primary button: Export… when unlinked, Update when linked.
func _on_export_pressed() -> void:
	if _linked_shader_path.is_empty():
		_export_mode = "full"
		_popup_export_dialog()
	else:
		_do_update()


# Caret dropdown: rarer export ops.
func _on_export_menu_id(id: int) -> void:
	match id:
		0:  # Export new material (resets material parameters)
			if _linked_shader_path.is_empty():
				push_warning("Nyx: link a shader first (Export…) before writing a material.")
				return
			if _write_material_file(_linked_shader_path):
				EditorInterface.get_resource_filesystem().scan()
				print("Nyx: wrote material (parameters reset) → %s" % (_linked_shader_path.get_basename() + ".tres"))
		1:  # Export shader only
			if _linked_shader_path.is_empty():
				_export_mode = "shader_only"
				_popup_export_dialog()
			else:
				_do_update()
		2:  # Export as… (re-link to a new path)
			_export_mode = "full"
			_popup_export_dialog()
		3:  # Unlink
			_set_linked("")
			print("Nyx: unlinked")


func _get_recent_files() -> Array:
	var s := EditorInterface.get_editor_settings()
	if s.has_setting("nyx/recent_files"):
		return Array(s.get_setting("nyx/recent_files"))
	return []


func _push_recent(path: String) -> void:
	var s := EditorInterface.get_editor_settings()
	var recent := _get_recent_files()
	recent.erase(path)
	recent.insert(0, path)
	if recent.size() > 10:
		recent.resize(10)
	s.set_setting("nyx/recent_files", PackedStringArray(recent))


func _refresh_recent_menu() -> void:
	_recent_popup.clear()
	var recent := _get_recent_files()
	if recent.is_empty():
		_recent_popup.add_item("(empty)", 0)
		_recent_popup.set_item_disabled(0, true)
	else:
		for i in recent.size():
			_recent_popup.add_item(recent[i].get_file(), i)
			_recent_popup.set_item_tooltip(i, recent[i])


func _on_recent_selected(id: int) -> void:
	var recent := _get_recent_files()
	if id < recent.size():
		load_nyx(recent[id])


func _on_file_menu_id(id: int) -> void:
	match id:
		0:  _on_new_pressed()
		1:  _load_dialog.popup_centered_ratio(0.5)
		2:  _on_save_pressed()
		3:  _popup_save_dialog()
		4:  _on_export_pressed()
		5:  _on_export_menu_id(2)  # Export As… (re-link)
		6:  _on_export_menu_id(0)  # Export new material
		7:  _on_export_menu_id(1)  # Export shader only
		8:  _on_export_menu_id(3)  # Unlink


func _on_live_toggled(on: bool) -> void:
	_live_link_on = on
	# Toggling on immediately reflects the current graph state in the scene.
	if on and not _linked_shader_path.is_empty():
		NyxCharon.notify_shader_updated(_linked_shader_path, _preview_panel.get_active_material())


func _popup_export_dialog() -> void:
	# Co-locate: default the artifact to the working file's folder when we have one.
	if not _current_nyx_path.is_empty():
		_export_dialog.current_dir = _current_nyx_path.get_base_dir()
	_export_dialog.popup_centered_ratio(0.5)


# Update the linked shader in place (no dialog, no material rewrite — material
# values are the user's to keep). Persists the .nyx too, the way Ctrl+S does.
func _do_update() -> void:
	if _linked_shader_path.is_empty():
		return
	var code: String = _compiler.build_shader_code(_shader_type)
	if not _write_shader_file(_linked_shader_path, code):
		return
	if not _current_nyx_path.is_empty():
		NyxSerializer.write(_current_nyx_path, _serialize_graph())
	NyxCharon.notify_shader_updated(_linked_shader_path, _preview_panel.get_active_material())
	EditorInterface.get_resource_filesystem().scan()
	print("Nyx: updated shader → %s" % _linked_shader_path)


func _set_linked(path: String) -> void:
	_linked_shader_path = path
	_update_link_ui()
	# Linking implies you want to see it live — default the toggle on. (The toggle
	# stays for the rarer "edit without disturbing the scene" case.)
	if not path.is_empty():
		_live_btn.button_pressed = true


func _update_link_ui() -> void:
	if not _export_btn:
		return
	var linked := not _linked_shader_path.is_empty()
	_export_btn.text = "Update" if linked else "Export…"
	_export_btn.tooltip_text = ("Rewrite linked shader: %s" % _linked_shader_path) if linked else "Export shader + material, then link"
	_live_btn.disabled = not linked
	if not linked and _live_btn.button_pressed:
		_live_btn.button_pressed = false  # fires toggled → live off
	if _file_popup:
		_file_popup.set_item_disabled(_file_popup.get_item_index(8), not linked)  # Unlink


# Writes the .gdshader with a provenance stamp (gates artifact → Nyx navigation).
func _write_shader_file(path: String, code: String) -> bool:
	var out := code
	if not _current_nyx_path.is_empty():
		# Line 1 is the machine-read provenance stamp (read_nyx_source parses it);
		# line 2 is a human warning. Keep them on separate lines.
		out = "%s%s\n// Generated by Nyx — do not hand-edit; overwritten on Update.\n%s" % [NyxCharon.PROVENANCE_PREFIX, _current_nyx_path, code]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f:
		push_error("Nyx: could not write shader to %s" % path)
		return false
	f.store_string(out)
	f.close()
	return true


# Writes the companion .tres ShaderMaterial next to the shader. Bakes texture/
# sub-resource/float-param values — overwrites any existing material values.
func _write_material_file(shader_path: String) -> bool:
	var path := shader_path
	# Collect nodes by export type
	var file_tex_nodes := []
	var sub_nodes := []
	var value_param_nodes := []
	for child in _graph.get_children():
		if not child.has_method("get_uniform_declaration"):
			continue
		var decl: String = child.get_uniform_declaration()
		if decl == "":
			continue
		if child.has_method("export_as_sub_resource"):
			sub_nodes.append(child)
		elif child.has_method("get_texture"):
			var tex = child.get_texture()
			if tex != null and not tex.resource_path.is_empty():
				file_tex_nodes.append(child)
		elif child.has_method("get_param_export_line"):
			var export_line: String = child.get_param_export_line()
			if export_line != "":
				value_param_nodes.append(child)

	var total_sub_count := sub_nodes.size() * 2
	var load_steps := 1 + file_tex_nodes.size() + total_sub_count + 1
	var lines := PackedStringArray()
	lines.append("[gd_resource type=\"ShaderMaterial\" load_steps=%d format=3]" % load_steps)
	lines.append("")
	lines.append("[ext_resource type=\"Shader\" path=\"%s\" id=\"1\"]" % path)

	var tex_id := 2
	var tex_id_map := {}
	for node in file_tex_nodes:
		var uname: String = node.get_uniform_name()
		lines.append("[ext_resource type=\"Texture2D\" path=\"%s\" id=\"%d\"]" % [node.get_texture().resource_path, tex_id])
		tex_id_map[uname] = tex_id
		tex_id += 1

	lines.append("")

	var sub_id_start := 1
	var sub_param_lines := PackedStringArray()
	for node in sub_nodes:
		var result: Dictionary = node.export_as_sub_resource(sub_id_start)
		for line in (result["lines"] as PackedStringArray):
			lines.append(line)
		sub_param_lines.append(result["param_line"])
		sub_id_start += result["count"] as int

	lines.append("[resource]")
	lines.append("shader = ExtResource(\"1\")")

	for uname in tex_id_map:
		lines.append("shader_parameter/%s = ExtResource(\"%d\")" % [uname, tex_id_map[uname]])

	for line in sub_param_lines:
		lines.append(line)

	for node in value_param_nodes:
		lines.append(node.get_param_export_line())

	lines.append("")

	var tres_path := path.get_basename() + ".tres"
	var tf := FileAccess.open(tres_path, FileAccess.WRITE)
	if not tf:
		push_error("Nyx: could not write material to %s" % tres_path)
		return false
	tf.store_string("\n".join(lines))
	tf.close()
	return true


# Dialog callback: full export (shader + material) or shader-only, then link.
func _on_export_file_selected(path: String) -> void:
	if not path.ends_with(".gdshader"):
		path += ".gdshader"
	var code: String = _compiler.build_shader_code(_shader_type)
	if not _write_shader_file(path, code):
		return
	if _export_mode != "shader_only":
		_write_material_file(path)
	_set_linked(path)
	NyxCharon.notify_shader_updated(path, _preview_panel.get_active_material())
	EditorInterface.get_resource_filesystem().scan()
	if _export_mode == "shader_only":
		print("Nyx: exported shader → %s (linked)" % path)
	else:
		print("Nyx: exported\n  shader  → %s\n  material → %s (linked)" % [path, path.get_basename() + ".tres"])


func sync_size(new_size: Vector2) -> void:
	if _outer_vbox:
		_outer_vbox.size = new_size
	if not _preview_positioned and _preview_panel:
		_preview_positioned = true
		call_deferred("_position_preview_default")
	if not _properties_positioned and _properties_panel:
		_properties_positioned = true
		call_deferred("_position_properties_default")
	elif _preview_panel and _preview_panel.is_placed():
		_preview_panel.reanchor(_graph_top(), _outer_vbox.size.x)
	_reposition_legend()
	_reposition_minimap_toggle()
	if _search_popup:
		_search_popup.handle_resize()


func _graph_top() -> float:
	return _graph_container.position.y if _graph_container else 0.0



func _position_preview_default() -> void:
	_preview_panel.place_default(_graph_top())


func _position_properties_default() -> void:
	var top: float = _graph_top() + 12.0 + _preview_panel.size.y + 8.0
	_properties_panel.position = Vector2(
		_graph_container.size.x - _properties_panel.size.x - 20.0,
		top
	)


# Static key in the bottom-left corner of the graph mapping the four data-type
# dot colors to plain-language names. The dot color is the real type encoding;
# this just reinforces it without any per-port hover machinery.
# Shared brand styling for the floating corner chips (Types / Map / ?). Monochrome
# dark body + grey border at rest; hunter-green border on hover (the same hover
# language as nodes). `hpad` widens narrow chips like the "?" button.
func _make_chip_style(hover: bool, hpad: float = 4.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.20, 0.20, 0.26, 0.97) if hover else Color(0.14, 0.14, 0.18, 0.95)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(4)
	s.content_margin_left = hpad
	s.content_margin_right = hpad
	s.set_border_width_all(1)
	s.border_color = Color("#31614F") if hover else Color(0.24, 0.24, 0.30)
	return s


func _style_chip(btn: Button, hpad: float = 4.0) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))
	btn.add_theme_stylebox_override("normal", _make_chip_style(false, hpad))
	var hover := _make_chip_style(true, hpad)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)


func _build_type_legend() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.14, 0.14, 0.18, 0.96)
	bg.set_corner_radius_all(6)
	bg.set_content_margin_all(6)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.24, 0.24, 0.30)
	panel.add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# [type_id, friendly_name, glsl_name]
	var entries := [
		[1, "Value", "float"],
		[2, "UV", "vec2"],
		[0, "Color", "vec3"],
		[3, "Color + Alpha", "vec4"],
	]
	for e in entries:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)

		var sw := ColorRect.new()
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sw.color = NyxNodeBase._type_color(e[0])
		sw.custom_minimum_size = Vector2(9, 9)
		sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sw)

		var lbl := Label.new()
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.text = "%s  (%s)" % [e[1], e[2]]
		lbl.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))
		lbl.add_theme_font_size_override("font_size", 10)
		row.add_child(lbl)

		vbox.add_child(row)

	return panel


func _build_legend_toggle() -> Button:
	var btn := Button.new()
	btn.text = "Types  ▴"
	_style_chip(btn)
	btn.pressed.connect(_on_legend_toggle)
	return btn


func _on_legend_toggle() -> void:
	_type_legend.visible = not _type_legend.visible
	_legend_toggle.text = "Types  ▾" if _type_legend.visible else "Types  ▴"
	_reposition_legend()


func _reposition_legend() -> void:
	if not _legend_toggle or not _outer_vbox:
		return
	call_deferred("_do_reposition_legend")


func _do_reposition_legend() -> void:
	if not _legend_toggle:
		return
	var bh: float = _legend_toggle.get_combined_minimum_size().y
	_legend_toggle.position = Vector2(20, _outer_vbox.size.y - bh - 20)
	if _type_legend:
		var ph: float = _type_legend.get_combined_minimum_size().y
		_type_legend.position = Vector2(20, _legend_toggle.position.y - ph - 6)


func _build_minimap_toggle() -> Button:
	var btn := Button.new()
	btn.text = "Map  ▴"
	_style_chip(btn)
	btn.pressed.connect(_on_minimap_toggle)
	return btn


func _on_minimap_toggle() -> void:
	_graph.minimap_enabled = not _graph.minimap_enabled
	_minimap_toggle.text = "Map  ▾" if _graph.minimap_enabled else "Map  ▴"


# Positions the [Map] chip anchored to the bottom-right corner.
func _reposition_minimap_toggle() -> void:
	if not _minimap_toggle or not _outer_vbox:
		return
	call_deferred("_do_reposition_minimap_toggle")


func _do_reposition_minimap_toggle() -> void:
	if not _minimap_toggle or not _graph_container:
		return
	var mw: float = _minimap_toggle.get_combined_minimum_size().x
	var mh: float = _minimap_toggle.get_combined_minimum_size().y
	_minimap_toggle.position = Vector2(_graph_container.size.x - mw - 20, _outer_vbox.size.y - mh - 20)


func _build_shortcuts_overlay() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.14, 0.14, 0.18, 0.96)
	bg.set_corner_radius_all(8)
	bg.set_content_margin_all(14)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.24, 0.24, 0.30)
	panel.add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "Shortcuts"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("#4AAF78"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.tooltip_text = "Close"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	close_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	close_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	close_btn.add_theme_color_override("font_focus_color", Color(0.55, 0.55, 0.65))
	var _cb_empty := StyleBoxEmpty.new()
	close_btn.add_theme_stylebox_override("normal", _cb_empty)
	close_btn.add_theme_stylebox_override("hover", _cb_empty)
	close_btn.add_theme_stylebox_override("pressed", _cb_empty)
	close_btn.add_theme_stylebox_override("focus", _cb_empty)
	close_btn.pressed.connect(_toggle_shortcuts_overlay)
	title_row.add_child(close_btn)

	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	var sep_line := StyleBoxLine.new()
	sep_line.color = Color(0.24, 0.24, 0.30)
	sep_line.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_line)
	vbox.add_child(sep)

	var entries := [
		["Right-click / A", "Add node"],
		["X", "Delete selected"],
		["R", "Add Reroute"],
		["Ctrl+C", "Copy selected"],
		["Ctrl+V", "Paste"],
		["Ctrl+D", "Duplicate selected"],
		["Left-drag", "Pan canvas"],
		["Shift+Left-drag", "Box select"],
		["Ctrl+N", "New graph"],
		["Ctrl+O", "Open graph"],
		["Ctrl+S", "Save (+ Update if linked)"],
		["Ctrl+Shift+S", "Save As"],
		["Ctrl+E", "Export / Update linked shader"],
		["Ctrl+U", "Reload Nyx"],
		["?", "Toggle this chart"],
	]
	for e in entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var key_lbl := Label.new()
		key_lbl.text = e[0]
		key_lbl.custom_minimum_size.x = 150
		key_lbl.add_theme_font_size_override("font_size", 11)
		key_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.88))
		var desc_lbl := Label.new()
		desc_lbl.text = e[1]
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
		row.add_child(key_lbl)
		row.add_child(desc_lbl)
		vbox.add_child(row)

	return panel



func _push_undo_state() -> void:
	_undo_stack.push_back(_serialize_graph())
	if _undo_stack.size() > 50:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_mark_dirty()
	if _properties_panel and _properties_panel.visible:
		call_deferred("_rebuild_properties_list")


# --- Dirty tracking (unsaved .nyx working-file changes) ---

func _mark_dirty() -> void:
	if _loading or _dirty:
		return
	_dirty = true
	_update_save_button()


func _set_clean() -> void:
	_dirty = false
	_update_save_button()


func _update_save_button() -> void:
	if _filename_label:
		var name := _current_nyx_path.get_file() if not _current_nyx_path.is_empty() else "untitled.nyx"
		_filename_label.text = (name + " *") if _dirty else name
		var col := Color("#D4A017") if _dirty else Color("#4AAF78")
		_filename_label.add_theme_color_override("font_color", col)


func _undo() -> void:
	if _undo_stack.is_empty():
		return
	_redo_stack.push_back(_serialize_graph())
	_deserialize_graph(_undo_stack.pop_back())


func _redo() -> void:
	if _redo_stack.is_empty():
		return
	_undo_stack.push_back(_serialize_graph())
	_deserialize_graph(_redo_stack.pop_back())


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	_push_undo_state()
	for node_name in nodes:
		if str(node_name) == "OutputNode":
			continue
		var to_disconnect := []
		for conn in _graph.get_connection_list():
			if str(conn["from_node"]) == str(node_name) or str(conn["to_node"]) == str(node_name):
				to_disconnect.append(conn)
		for conn in to_disconnect:
			_graph.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
		var node := _graph.get_node_or_null(str(node_name))
		if node:
			node.queue_free()
	_request_compile()


# --- Copy / paste / duplicate ---

# The singleton sink nodes (Output / particle Start+Process) are fixed-name and must
# never be copied or duplicated.
func _is_sink_node(node: Node) -> bool:
	var n := str(node.name)
	return n == "OutputNode" or n == "VertexOutputNode" or n == "ParticleStartNode" or n == "ParticleProcessNode"


# Serialize the currently-selected (non-sink) nodes plus the connections wholly between
# them, into a {nodes, connections} buffer — the shared payload for copy and duplicate.
func _serialize_selected_nodes() -> Dictionary:
	var selected := {}
	var nodes := []
	for child in _graph.get_children():
		if not child is GraphNode or not child.selected or _is_sink_node(child):
			continue
		var type := _get_node_type(child)
		if type == "":
			continue
		selected[str(child.name)] = true
		nodes.append({
			"type": type,
			"name": str(child.name),
			"position": [child.position_offset.x, child.position_offset.y],
			"state": child.get_state(),
		})
	var connections := []
	for conn in _graph.get_connection_list():
		if selected.has(str(conn["from_node"])) and selected.has(str(conn["to_node"])):
			connections.append({
				"from_node": str(conn["from_node"]),
				"from_port": conn["from_port"],
				"to_node": str(conn["to_node"]),
				"to_port": conn["to_port"],
			})
	return {"nodes": nodes, "connections": connections}


# Recreate a {nodes, connections} buffer into the graph, offset from the originals, and
# leave the new nodes selected (so they can be dragged immediately). Used by paste and
# duplicate; new names auto-uniquify on add_child, captured into name_map for the conns.
func _paste_buffer(buf: Dictionary, offset: Vector2 = Vector2(30, 30)) -> void:
	# NOTE: paste does NOT gate on shader mode. The clipboard is per-session and persists
	# across load/new, so you can paste a node that's invalid for the current mode (e.g. a
	# spatial Fresnel into a particle graph). This can't crash — it's a soft failure: an
	# off-mode node only produces bad GLSL if it's actually wired into the output chain
	# (the compiler walks from the sink), and that's recoverable by deleting it. A precise
	# gate would need a parallel type→mode-flags table (the registry is keyed by id, not
	# type), which we deliberately avoid. Same non-enforcement already exists for load.
	var src: Array = buf.get("nodes", [])
	if src.is_empty():
		return
	_push_undo_state()
	_deselect_all_nodes()
	var name_map := {}
	var new_nodes: Array[Node] = []
	for nd in src:
		var type: String = nd["type"]
		if not NODE_CLASSES.has(type):
			continue
		var node = NODE_CLASSES[type].new()
		var pos: Array = nd["position"]
		var base: String = nd["name"]
		if base.begins_with("@"):
			base = type.trim_suffix("Node")
		_add_node(node, Vector2(pos[0], pos[1]) + offset, base)
		name_map[nd["name"]] = str(node.name)
		var state: Dictionary = nd.get("state", {})
		if not state.is_empty():
			node.set_state(state)
		new_nodes.append(node)
	for conn in buf.get("connections", []):
		var from = name_map.get(conn["from_node"])
		var to = name_map.get(conn["to_node"])
		if from != null and to != null:
			_graph.connect_node(from, conn["from_port"], to, conn["to_port"])
	for node in new_nodes:
		node.selected = true
	_compiler.update_all_polymorphic_ports()
	_request_compile()
	_mark_dirty()


func _copy_selected_nodes() -> void:
	var buf := _serialize_selected_nodes()
	if not (buf["nodes"] as Array).is_empty():
		_clipboard = buf


func _paste_clipboard() -> void:
	# Paste anchors the copied group's top-left at the mouse cursor (in graph space), so it
	# lands where you're pointing rather than back at the originals' (maybe scrolled-away)
	# location. Relative layout between the pasted nodes is preserved.
	var src: Array = _clipboard.get("nodes", [])
	if src.is_empty():
		return
	var min_pos := Vector2(INF, INF)
	for nd in src:
		var p: Array = nd["position"]
		min_pos = min_pos.min(Vector2(p[0], p[1]))
	var mouse_graph := _graph.get_local_mouse_position() / _graph.zoom + _graph.scroll_offset
	_paste_buffer(_clipboard, mouse_graph - min_pos)


func _duplicate_selected_nodes() -> void:
	# Duplicate stays a small offset from the originals (the cursor is usually right on the
	# node you just selected, so cursor-anchoring would stack the copy on top). Uses its own
	# buffer so it never clobbers the copy/paste clipboard.
	_paste_buffer(_serialize_selected_nodes())


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from := _graph.get_node_or_null(str(from_node))
	var to := _graph.get_node_or_null(str(to_node))
	if not from or not to:
		return
	var from_type: int = _compiler.resolve_output_type(from, from_port)
	var to_type: int = to.get_input_port_type(to_port)
	if not _compiler.can_promote(from_type, to_type):
		return
	_push_undo_state()
	_graph.connect_node(from_node, from_port, to_node, to_port)
	_compiler.update_all_polymorphic_ports()
	_request_compile()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_push_undo_state()
	_graph.disconnect_node(from_node, from_port, to_node, to_port)
	_compiler.update_all_polymorphic_ports()
	_request_compile()


# True when the mouse is over any node (body or its port dots). GraphEdit's gui_input
# fires for presses over nodes too — it manages node drag/connection centrally — so we
# must NOT pan there or we'd steal the press from node-dragging. The rect is grown to
# cover the port dots that overhang the node edge (the connection grab zone).
func _is_mouse_over_node() -> bool:
	var m := get_global_mouse_position()
	for child in _graph.get_children():
		if child is GraphNode and (child as GraphNode).get_global_rect().grow(12.0).has_point(m):
			return true
	return false


func _deselect_all_nodes() -> void:
	for child in _graph.get_children():
		if child is GraphNode:
			child.selected = false


func _shortcut_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var ctrl: bool = event.ctrl_pressed
	var shift: bool = event.shift_pressed
	if not ctrl:
		return
	# NB: Ctrl+C/V/D are NOT here — GraphEdit consumes them when focused, so they're wired
	# via its copy_nodes_request / paste_nodes_request / duplicate_nodes_request signals.
	match event.keycode:
		KEY_U:
			if not shift:
				emit_signal("reload_requested")
				accept_event()
		KEY_N:
			if not shift:
				_on_new_pressed()
				accept_event()
		KEY_S:
			if shift:
				_popup_save_dialog()
			else:
				_on_save_pressed()
				if not _linked_shader_path.is_empty():
					_do_update()
			accept_event()
		KEY_O:
			if not shift:
				_load_dialog.popup_centered_ratio(0.5)
				accept_event()
		KEY_E:
			if not shift:
				_on_export_pressed()
				accept_event()


func _on_graph_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_spawn_position = event.position / _graph.zoom + _graph.scroll_offset
			_search_popup.open(_shader_type)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# Plain left-drag on EMPTY canvas pans. Over a node (body or dots) we do nothing
			# so GraphEdit's own node-drag / connection-drag runs. Shift also defers (native
			# box-select). The whole pan lifecycle lives here: GraphEdit captures mouse focus
			# on the press, so the drag motion and release come back even over nodes.
			if event.pressed:
				if not event.shift_pressed and not _is_mouse_over_node():
					_panning = true
					_pan_moved = false
					accept_event()
			else:
				if _panning:
					_panning = false
					# A clean click on empty canvas (no drag) deselects all nodes — the
					# pan intercept means GraphEdit never gets to do this itself.
					if not _pan_moved:
						_deselect_all_nodes()
					accept_event()
	elif event is InputEventMouseMotion and _panning:
		_pan_moved = true
		_graph.scroll_offset -= event.relative / _graph.zoom
		accept_event()


# Bare graph shortcuts (A / R / X / ?). Handled here rather than in the graph's gui_input
# so they fire without first clicking to focus GraphEdit — _unhandled_key_input runs for
# any key the focused control didn't consume. Gated on the cursor being over the graph
# (so they don't fire while editing elsewhere) and Ctrl/Cmd-free (those belong to
# _shortcut_input). A focused field consumes its own keys, so typing is unaffected.
func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.ctrl_pressed or event.meta_pressed:
		return
	if _search_popup and _search_popup.visible:
		return
	if not _graph.get_global_rect().has_point(get_global_mouse_position()):
		return
	if event.keycode == KEY_SLASH and event.shift_pressed:
		_toggle_shortcuts_overlay()
		accept_event()
		return
	match event.keycode:
		KEY_X:
			var selected: Array[StringName] = []
			for child in _graph.get_children():
				if child is GraphNode and child.selected:
					selected.append(child.name)
			if not selected.is_empty():
				_on_delete_nodes_request(selected)
				accept_event()
		KEY_R:
			_push_undo_state()
			_spawn_position = _graph.get_local_mouse_position() / _graph.zoom + _graph.scroll_offset
			_add_node(RerouteNode.new(), _spawn_position, "Reroute")
			accept_event()
		KEY_A:
			_spawn_position = _graph.get_local_mouse_position() / _graph.zoom + _graph.scroll_offset
			_search_popup.open(_shader_type)
			accept_event()


func _toggle_shortcuts_overlay() -> void:
	_shortcuts_overlay.visible = not _shortcuts_overlay.visible
	if _shortcuts_overlay.visible:
		_shortcuts_overlay.move_to_front()
		_shortcuts_overlay.reset_size()
		var sz := _shortcuts_overlay.get_combined_minimum_size()
		_shortcuts_overlay.position = ((_graph_container.size - sz) * 0.5).max(Vector2.ZERO)


func _on_search_node_chosen(id: int) -> void:
	# The search popup picked a node — spawn it at the captured _spawn_position.
	# _on_context_menu_selected pushes its own undo snapshot, so no extra push here.
	_on_context_menu_selected(id)


func _on_context_menu_selected(id: int) -> void:
	_push_undo_state()
	match id:
		0: _add_node(ColorNode.new(), _spawn_position, "Color")
		1: _add_node(AddNode.new(), _spawn_position, "Add")
		2: _add_node(MultiplyNode.new(), _spawn_position, "Multiply")
		3: _add_node(MixNode.new(), _spawn_position, "Mix")
		4: _add_node(UVNode.new(), _spawn_position, "UV")
		5: _add_node(FloatNode.new(), _spawn_position, "Float")
		6: _add_node(SubtractNode.new(), _spawn_position, "Subtract")
		7: _add_node(ClampNode.new(), _spawn_position, "Clamp")
		8: _add_node(PowerNode.new(), _spawn_position, "Power")
		9: _add_node(SinNode.new(), _spawn_position, "Sin")
		10: _add_node(CosNode.new(), _spawn_position, "Cos")
		11: _add_node(TimeNode.new(), _spawn_position, "Time")
		12: _add_node(SplitNode.new(), _spawn_position, "Split")
		13: _add_node(CombineNode.new(), _spawn_position, "Combine")
		14: _add_node(TextureSampleNode.new(), _spawn_position, "TextureSample")
		15: _add_node(FresnelNode.new(), _spawn_position, "Fresnel")
		16: _add_node(ScaleNode.new(), _spawn_position, "Scale")
		17: _add_node(StepNode.new(), _spawn_position, "Step")
		18: _add_node(SmoothstepNode.new(), _spawn_position, "Smoothstep")
		19: _add_node(NoiseNode.new(), _spawn_position, "Noise")
		36: _add_node(FBMNode.new(), _spawn_position, "FBM")
		37: _add_node(GradientNode.new(), _spawn_position, "Gradient")
		38: _add_node(CurveNode.new(), _spawn_position, "Curve")
		39: _add_node(TilingOffsetNode.new(), _spawn_position, "TilingOffset")
		40: _add_node(RotateUVNode.new(), _spawn_position, "RotateUV")
		41: _add_node(WarpNode.new(), _spawn_position, "Warp")
		42: _add_node(NormalFromHeightNode.new(), _spawn_position, "NormalFromHeight")
		43: _add_node(BlendNormalsNode.new(), _spawn_position, "BlendNormals")
		44: _add_node(ScreenUVNode.new(), _spawn_position, "ScreenUV")
		45: _add_node(ScreenTextureNode.new(), _spawn_position, "ScreenTexture")
		46: _add_node(DepthFadeNode.new(), _spawn_position, "DepthFade")
		20: _add_node(VertexNode.new(), _spawn_position, "Vertex")
		21: _add_node(NormalMapNode.new(), _spawn_position, "NormalMap")
		22: _add_node(AbsNode.new(), _spawn_position, "Abs")
		29: _add_node(CeilNode.new(), _spawn_position, "Ceil")
		30: _add_node(FloorNode.new(), _spawn_position, "Floor")
		31: _add_node(FractNode.new(), _spawn_position, "Fract")
		32: _add_node(NegateNode.new(), _spawn_position, "Negate")
		33: _add_node(OneMinusNode.new(), _spawn_position, "OneMinus")
		34: _add_node(RoundNode.new(), _spawn_position, "Round")
		35: _add_node(SqrtNode.new(), _spawn_position, "Sqrt")
		23: _add_node(MinMaxNode.new(), _spawn_position, "MinMax")
		24: _add_node(DivideNode.new(), _spawn_position, "Divide")
		25: _add_node(ModNode.new(), _spawn_position, "Mod")
		26: _add_node(NormalizeNode.new(), _spawn_position, "Normalize")
		27: _add_node(LengthNode.new(), _spawn_position, "Length")
		28: _add_node(DotNode.new(), _spawn_position, "Dot")
		52: _add_node(RerouteNode.new(), _spawn_position, "Reroute")
		53: _add_node(RelayNode.new(), _spawn_position, "Relay")
		54: _add_node(PreviewRelayNode.new(), _spawn_position, "PreviewRelay")
		47: _add_node(CustomGLSLNode.new(), _spawn_position, "CustomGLSL")
		48: _add_node(Vector3Node.new(), _spawn_position, "Vector3")
		49: _add_node(SpriteTextureNode.new(), _spawn_position, "SpriteTexture")
		50: _add_node(VertexColorNode.new(), _spawn_position, "VertexColor")
		51: _add_node(TexturePixelSizeNode.new(), _spawn_position, "PixelSize")
		55:
			if not _graph.get_node_or_null("ParticleStartNode"):
				_add_node(ParticleStartNode.new(), _spawn_position, "ParticleStartNode")
				_update_sink_visibility()
		56:
			if not _graph.get_node_or_null("ParticleProcessNode"):
				_add_node(ParticleProcessNode.new(), _spawn_position, "ParticleProcessNode")
				_update_sink_visibility()
		57: _add_node(ParticleAgeNode.new(), _spawn_position, "ParticleAge")
		58: _add_node(ParticleVelocityNode.new(), _spawn_position, "ParticleVelocity")
		59: _add_node(ParticlePositionNode.new(), _spawn_position, "ParticlePosition")
		60: _add_node(ParticleDeltaNode.new(), _spawn_position, "ParticleDelta")
		61: _add_node(ParticleRandomNode.new(), _spawn_position, "ParticleRandom")
		62: _add_node(ParticleIndexNode.new(), _spawn_position, "ParticleIndex")


# Brand styling for the top toolbar buttons: flat at rest, hunter-green border on
# hover (the node/chip hover language), subtle green-tinted press.
func _make_toolbar_btn_style(state: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	match state:
		1: s.bg_color = Color(0.20, 0.20, 0.26)   # hover
		2: s.bg_color = Color(0.16, 0.32, 0.26)   # pressed (hunter-tinted)
		_: s.bg_color = Color(0, 0, 0, 0)         # normal (flat)
	s.set_corner_radius_all(4)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	if state == 1:
		s.set_border_width_all(1)
		s.border_color = Color("#31614F")
	return s


func _style_toolbar_button(b: Button) -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 0)
	b.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color(0.85, 0.87, 0.92))
	b.add_theme_stylebox_override("normal", _make_toolbar_btn_style(0))
	b.add_theme_stylebox_override("hover", _make_toolbar_btn_style(1))
	b.add_theme_stylebox_override("pressed", _make_toolbar_btn_style(2))
	b.add_theme_stylebox_override("hover_pressed", _make_toolbar_btn_style(1))
	b.add_theme_stylebox_override("focus", _make_toolbar_btn_style(0))


func _toggle_properties_panel() -> void:
	if _properties_panel:
		_properties_panel.visible = not _properties_panel.visible
		if _properties_panel.visible:
			_rebuild_properties_list()


func _build_properties_panel() -> Panel:
	var panel := Panel.new()
	panel.size = Vector2(220, 320)
	panel.visible = true

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.13, 0.13, 0.16, 0.95)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	var prop_header_wrap := PanelContainer.new()
	var prop_header_bg := StyleBoxFlat.new()
	prop_header_bg.bg_color = get_theme_color("base_color", "Editor")
	prop_header_bg.corner_radius_top_left = 6
	prop_header_bg.corner_radius_top_right = 6
	prop_header_bg.border_width_bottom = 2
	prop_header_bg.border_color = Color(0.12, 0.12, 0.16)
	prop_header_wrap.add_theme_stylebox_override("panel", prop_header_bg)
	vbox.add_child(prop_header_wrap)
	var header := HBoxContainer.new()
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				panel.set_meta("_drag_offset", panel.get_local_mouse_position())
		elif ev is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if panel.has_meta("_drag_offset"):
				panel.position = panel.position + ev.relative
	)
	var _pad_l := Control.new()
	_pad_l.custom_minimum_size = Vector2(2, 0)
	_pad_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_pad_l)
	var header_lbl := Label.new()
	header_lbl.text = "Properties"
	header_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_lbl)
	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	close_btn.add_theme_color_override("font_hover_color", Color("#4AAF78"))
	var _empty := StyleBoxEmpty.new()
	close_btn.add_theme_stylebox_override("normal", _empty)
	close_btn.add_theme_stylebox_override("hover", _empty)
	close_btn.add_theme_stylebox_override("pressed", _empty)
	close_btn.add_theme_stylebox_override("focus", _empty)
	close_btn.pressed.connect(func() -> void: panel.visible = false)
	header.add_child(close_btn)
	var _pad_r := Control.new()
	_pad_r.custom_minimum_size = Vector2(2, 0)
	_pad_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_pad_r)
	prop_header_wrap.add_child(header)

	# Param list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var params_margin := MarginContainer.new()
	params_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	params_margin.add_theme_constant_override("margin_left", 8)
	params_margin.add_theme_constant_override("margin_right", 2)
	params_margin.add_theme_constant_override("margin_top", 4)
	params_margin.add_theme_constant_override("margin_bottom", 4)
	scroll.add_child(params_margin)

	_properties_vbox = VBoxContainer.new()
	_properties_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_properties_vbox.add_theme_constant_override("separation", 2)
	params_margin.add_child(_properties_vbox)

	# Detail area — hidden until a param is clicked
	var detail_sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.22, 0.22, 0.28)
	sep_style.thickness = 1
	detail_sep.add_theme_stylebox_override("separator", sep_style)
	detail_sep.visible = false
	panel.set_meta("detail_sep", detail_sep)
	vbox.add_child(detail_sep)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 6)
	detail_vbox.visible = false
	panel.set_meta("detail_vbox", detail_vbox)
	vbox.add_child(detail_vbox)

	return panel


func _get_output_node() -> Node:
	return _graph.get_node_or_null("OutputNode")


func _rebuild_render_mode_options() -> void:
	if not _render_mode_popup:
		return
	_render_mode_popup.clear()
	if _shader_type == 0:
		for label in ["Opaque", "Mix", "Add", "Premult Alpha"]:
			_render_mode_popup.add_item(label)
	elif _shader_type == 1:
		for label in ["Default", "Unshaded", "Light Only", "Blend Add", "Blend Premult"]:
			_render_mode_popup.add_item(label)
	var output := _get_output_node()
	var mode: int = 0
	if output:
		mode = output.get_mode()
	if _render_mode_btn:
		_render_mode_btn.text = _render_mode_popup.get_item_text(mode) + "  ▾"
		_render_mode_btn.disabled = _shader_type == 2


func _rebuild_properties_list() -> void:
	if not _properties_vbox:
		return
	_selected_param_row = null
	for child in _properties_vbox.get_children():
		child.queue_free()

	var found := false
	for node in _graph.get_children():
		if not node is GraphNode:
			continue
		if not node.has_method("is_param_mode") or not node.call("is_param_mode"):
			continue
		found = true
		var row := _build_param_row(node)
		_properties_vbox.add_child(row)

	if not found:
		var lbl := Label.new()
		lbl.text = "No exposed parameters."
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.45, 0.48, 0.52))
		_properties_vbox.add_child(lbl)


func _build_param_row(node: Node) -> Control:
	var param_name: String = node.call("get_param_name") if node.has_method("get_param_name") else node.name

	var outer := Control.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.custom_minimum_size = Vector2(0, 24)
	outer.mouse_filter = Control.MOUSE_FILTER_STOP

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = param_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.80, 0.83, 0.88))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_lbl)

	var copy_lbl := Label.new()
	copy_lbl.text = "⧉"
	copy_lbl.add_theme_font_size_override("font_size", 16)
	copy_lbl.add_theme_color_override("font_color", Color(0.40, 0.43, 0.50))
	copy_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	copy_lbl.modulate = Color(1, 1, 1, 0)
	copy_lbl.mouse_entered.connect(func() -> void:
		copy_lbl.add_theme_color_override("font_color", Color("#4AAF78"))
	)
	copy_lbl.mouse_exited.connect(func() -> void:
		copy_lbl.add_theme_color_override("font_color", Color(0.40, 0.43, 0.50))
	)
	var copy_wrap := MarginContainer.new()
	copy_wrap.add_theme_constant_override("margin_left", 4)
	copy_wrap.add_theme_constant_override("margin_right", 4)
	copy_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy_wrap.add_child(copy_lbl)
	hbox.add_child(copy_wrap)

	outer.tooltip_text = 'material.set_shader_parameter("%s", value)' % param_name

	var _apply_style := func(hovered: bool) -> void:
		var selected := outer.get_meta("selected", false)
		var bg := StyleBoxFlat.new()
		if selected:
			bg.bg_color = Color(0.10, 0.22, 0.16)
			bg.border_width_left = 2
			bg.border_color = Color("#4AAF78")
		elif hovered:
			bg.bg_color = Color(0.20, 0.20, 0.26)
		else:
			bg.bg_color = Color(0, 0, 0, 0)
		outer.add_theme_stylebox_override("panel", bg)
		var name_col: Color
		if selected:
			name_col = Color("#4AAF78")
		elif hovered:
			name_col = Color.WHITE
		else:
			name_col = Color(0.80, 0.83, 0.88)
		name_lbl.add_theme_color_override("font_color", name_col)
		copy_lbl.modulate = Color(1, 1, 1, 1) if (hovered or selected) else Color(1, 1, 1, 0)

	outer.mouse_entered.connect(func() -> void: _apply_style.call(true))
	outer.mouse_exited.connect(func() -> void: _apply_style.call(false))

	outer.gui_input.connect(func(ev: InputEvent) -> void:
		if not ev is InputEventMouseButton or not ev.pressed or ev.button_index != MOUSE_BUTTON_LEFT:
			return
		if copy_lbl.get_global_rect().has_point(outer.get_global_mouse_position()):
			DisplayServer.clipboard_set('material.set_shader_parameter("%s", value)' % param_name)
		else:
			if _selected_param_row and is_instance_valid(_selected_param_row):
				_selected_param_row.set_meta("selected", false)
				_selected_param_row.get_meta("apply_style").call(false)
			_selected_param_row = outer
			outer.set_meta("selected", true)
			_apply_style.call(false)
			_show_param_detail(node)
		outer.accept_event()
	)

	outer.set_meta("apply_style", _apply_style)
	return outer


func _show_param_detail(node: Node) -> void:
	if not _properties_panel:
		return
	var detail_vbox := _properties_panel.get_meta("detail_vbox") as VBoxContainer
	var detail_sep := _properties_panel.get_meta("detail_sep") as HSeparator
	if not detail_vbox:
		return
	for child in detail_vbox.get_children():
		child.queue_free()

	var param_name: String = node.call("get_param_name") if node.has_method("get_param_name") else node.name

	var name_lbl := Label.new()
	name_lbl.text = param_name
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color("#4AAF78"))
	name_lbl.add_theme_constant_override("margin_left", 10)
	detail_vbox.add_child(name_lbl)

	if node.has_method("get_blackboard_control"):
		var ctrl := node.call("get_blackboard_control")
		if ctrl:
			var wrap := HBoxContainer.new()
			wrap.add_theme_constant_override("separation", 0)
			ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			wrap.add_child(ctrl)
			detail_vbox.add_child(wrap)

	detail_vbox.visible = true
	detail_sep.visible = true


func _load_toolbar_icon(path: String, size: int = 16) -> ImageTexture:
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


func _style_graph_toolbar() -> void:
	var hbox := _graph.get_menu_hbox()

	var undo_btn := Button.new()
	undo_btn.icon = _load_toolbar_icon("res://addons/nyx/icons/undo.svg", 12)
	undo_btn.tooltip_text = "Undo"
	undo_btn.pressed.connect(_undo)
	_style_toolbar_button(undo_btn)
	hbox.add_child(undo_btn)
	hbox.move_child(undo_btn, 0)

	var redo_btn := Button.new()
	redo_btn.icon = _load_toolbar_icon("res://addons/nyx/icons/redo.svg", 12)
	redo_btn.tooltip_text = "Redo"
	redo_btn.pressed.connect(_redo)
	_style_toolbar_button(redo_btn)
	hbox.add_child(redo_btn)
	hbox.move_child(redo_btn, 1)

	for child in hbox.get_children():
		if child is Button:
			_style_toolbar_button(child)
			if "grid" in child.tooltip_text.to_lower() or "grid" in child.text.to_lower():
				if child.button_pressed:
					child.button_pressed = false
					child.pressed.emit()
			# Tighter margins for icon-only buttons in the floating toolbar.
			var icon_margin := StyleBoxFlat.new()
			icon_margin.bg_color = Color(0, 0, 0, 0)
			icon_margin.set_corner_radius_all(4)
			icon_margin.content_margin_left = 4
			icon_margin.content_margin_right = 4
			icon_margin.content_margin_top = 2
			icon_margin.content_margin_bottom = 2
			child.add_theme_stylebox_override("normal", icon_margin)
			var icon_hover := icon_margin.duplicate()
			icon_hover.bg_color = Color(0.20, 0.20, 0.26)
			icon_hover.set_border_width_all(1)
			icon_hover.border_color = Color("#31614F")
			child.add_theme_stylebox_override("hover", icon_hover)
			var icon_press := icon_margin.duplicate()
			icon_press.bg_color = Color(0.16, 0.32, 0.26)
			child.add_theme_stylebox_override("pressed", icon_press)
			child.add_theme_stylebox_override("hover_pressed", icon_hover)
			child.add_theme_stylebox_override("focus", icon_margin)
			child.add_theme_color_override("icon_pressed_color", Color("#4AAF78"))
			child.add_theme_color_override("font_pressed_color", Color("#4AAF78"))
			child.add_theme_color_override("icon_hover_pressed_color", Color("#4AAF78"))


func _style_toolbar_separator(s: VSeparator) -> void:
	var line := StyleBoxLine.new()
	line.color = Color(0.24, 0.24, 0.30)
	line.thickness = 1
	line.grow_begin = 2
	line.grow_end = 2
	s.add_theme_stylebox_override("separator", line)


func _build_graph_toolbar() -> PanelContainer:
	var wrap := PanelContainer.new()
	var bar_bg := StyleBoxFlat.new()
	var editor_base := get_theme_color("base_color", "Editor")
	bar_bg.bg_color = editor_base
	bar_bg.expand_margin_top = 4
	bar_bg.border_width_bottom = 2
	bar_bg.border_color = Color(0.12, 0.12, 0.16)
	wrap.add_theme_stylebox_override("panel", bar_bg)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 4)
	wrap.add_child(toolbar)

	_file_popup = PopupMenu.new()
	_recent_popup = PopupMenu.new()
	_recent_popup.id_pressed.connect(_on_recent_selected)
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
	_file_popup.id_pressed.connect(_on_file_menu_id)
	_file_popup.about_to_popup.connect(_refresh_recent_menu)

	_file_btn = Button.new()
	_file_btn.text = "File  ▾"
	_file_btn.add_child(_file_popup)
	_file_btn.pressed.connect(func() -> void:
		var r := _file_btn.get_screen_position()
		var h := _file_btn.size.y
		_file_popup.reset_size()
		_file_popup.popup(Rect2(Vector2(r.x, r.y + h), Vector2(0, 0)))
	)
	_style_toolbar_button(_file_btn)
	toolbar.add_child(_file_btn)

	var sep := VSeparator.new()
	_style_toolbar_separator(sep)
	toolbar.add_child(sep)

	_filename_label = Label.new()
	_filename_label.text = "untitled.nyx"
	_filename_label.add_theme_font_size_override("font_size", 11)
	_filename_label.add_theme_color_override("font_color", Color("#4AAF78"))
	_filename_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toolbar.add_child(_filename_label)

	var sep_type := VSeparator.new()
	_style_toolbar_separator(sep_type)
	toolbar.add_child(sep_type)

	_type_popup = PopupMenu.new()
	_type_popup.add_item("Spatial", 0)
	_type_popup.add_item("Canvas Item", 1)
	_type_popup.add_item("Particles", 2)
	_type_popup.id_pressed.connect(func(id: int) -> void:
		_type_btn.text = _type_popup.get_item_text(id) + "  ▾"
		_on_shader_type_changed(id)
	)
	_type_btn = Button.new()
	_type_btn.text = "Spatial  ▾"
	_type_btn.add_child(_type_popup)
	_type_btn.pressed.connect(func() -> void:
		var r := _type_btn.get_screen_position()
		var h := _type_btn.size.y
		_type_popup.reset_size()
		_type_popup.popup(Rect2(Vector2(r.x, r.y + h), Vector2(_type_btn.size.x, 0)))
	)
	_style_toolbar_button(_type_btn)
	toolbar.add_child(_type_btn)

	_render_mode_popup = PopupMenu.new()
	_render_mode_btn = Button.new()
	_render_mode_btn.text = "Opaque  ▾"
	_render_mode_btn.add_child(_render_mode_popup)
	_render_mode_btn.pressed.connect(func() -> void:
		var r := _render_mode_btn.get_screen_position()
		var h := _render_mode_btn.size.y
		_render_mode_popup.reset_size()
		_render_mode_popup.popup(Rect2(Vector2(r.x, r.y + h), Vector2(_render_mode_btn.size.x, 0)))
	)
	_render_mode_popup.id_pressed.connect(func(id: int) -> void:
		_render_mode_btn.text = _render_mode_popup.get_item_text(id) + "  ▾"
		var output := _get_output_node()
		if output:
			output.set_mode(id)
			_request_compile()
	)
	_style_toolbar_button(_render_mode_btn)
	toolbar.add_child(_render_mode_btn)
	_rebuild_render_mode_options()

	var sep_params := VSeparator.new()
	_style_toolbar_separator(sep_params)
	toolbar.add_child(sep_params)

	var params_btn := Button.new()
	params_btn.text = "Properties"
	params_btn.pressed.connect(_toggle_properties_panel)
	_style_toolbar_button(params_btn)
	toolbar.add_child(params_btn)

	# Spacer pushes export/live + shortcuts to the right edge of the toolbar.
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)

	var sep3 := VSeparator.new()
	_style_toolbar_separator(sep3)
	toolbar.add_child(sep3)

	_export_btn = Button.new()
	_export_btn.text = "Export…"
	_export_btn.pressed.connect(_on_export_pressed)
	_style_toolbar_button(_export_btn)
	toolbar.add_child(_export_btn)

	_export_menu = MenuButton.new()
	_export_menu.flat = true
	_export_menu.text = "▾"
	_style_toolbar_button(_export_menu)
	var pm := _export_menu.get_popup()
	pm.add_item("Export new material", 0)
	pm.add_item("Export shader only", 1)
	pm.add_separator()
	pm.add_item("Export as… (re-link)", 2)
	pm.add_item("Unlink", 3)
	pm.id_pressed.connect(_on_export_menu_id)
	toolbar.add_child(_export_menu)

	_live_btn = CheckButton.new()
	_live_btn.text = "Live"
	_live_btn.tooltip_text = "Push shader changes into the linked artifact in real time."
	_live_btn.toggled.connect(_on_live_toggled)
	_style_toolbar_button(_live_btn)
	_live_btn.add_theme_color_override("font_pressed_color", Color("#4AAF78"))
	_live_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	toolbar.add_child(_live_btn)

	var sep4 := VSeparator.new()
	_style_toolbar_separator(sep4)
	toolbar.add_child(sep4)

	var help_btn := Button.new()
	help_btn.text = "?"
	help_btn.tooltip_text = "Keyboard shortcuts (?)"
	help_btn.focus_mode = Control.FOCUS_NONE
	help_btn.add_theme_font_size_override("font_size", 14)
	help_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	help_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	help_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	help_btn.add_theme_color_override("font_focus_color", Color(0.55, 0.55, 0.65))
	var _hb_empty := StyleBoxEmpty.new()
	help_btn.add_theme_stylebox_override("normal", _hb_empty)
	help_btn.add_theme_stylebox_override("hover", _hb_empty)
	help_btn.add_theme_stylebox_override("pressed", _hb_empty)
	help_btn.add_theme_stylebox_override("focus", _hb_empty)
	help_btn.pressed.connect(_toggle_shortcuts_overlay)
	toolbar.add_child(help_btn)

	var edge_pad := Control.new()
	edge_pad.custom_minimum_size = Vector2(4, 0)
	edge_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toolbar.add_child(edge_pad)

	return wrap


func _get_node_type(node: Node) -> String:
	for type_name in NODE_CLASSES:
		if node.get_script() == NODE_CLASSES[type_name]:
			return type_name
	return ""


func _serialize_graph() -> Dictionary:
	var nodes := []
	for child in _graph.get_children():
		if not child is GraphNode:
			continue
		var type := _get_node_type(child)
		if type == "":
			continue
		nodes.append({
			"type": type,
			"name": str(child.name),
			"position": [child.position_offset.x, child.position_offset.y],
			"state": child.get_state(),
		})

	var connections := []
	for conn in _graph.get_connection_list():
		connections.append({
			"from_node": str(conn["from_node"]),
			"from_port": conn["from_port"],
			"to_node": str(conn["to_node"]),
			"to_port": conn["to_port"],
		})

	return {
		"nodes": nodes,
		"connections": connections,
		"shader_type": _shader_type,
		"linked_shader_path": _linked_shader_path,
	}


func _clear_graph_nodes() -> void:
	_graph.clear_connections()
	var to_remove: Array[Node] = []
	for child in _graph.get_children():
		if child is GraphNode:
			to_remove.append(child)
	for child in to_remove:
		_graph.remove_child(child)
		child.free()


func _deserialize_graph(data: Dictionary) -> void:
	# Reconstruction (and undo/redo) must not mark the graph dirty; the caller
	# decides cleanliness (load/new = clean, undo = leaves dirty unchanged).
	_loading = true
	_clear_graph_nodes()

	var saved_type: int = data.get("shader_type", 0)
	_shader_type = saved_type
	_sync_shader_type_ui(saved_type)
	# Restore the artifact link. Lazy: store the path only; the Shader resource is
	# re-resolved (ResourceLoader.load) on first Update / live-link use, not now.
	_linked_shader_path = data.get("linked_shader_path", "")
	_update_link_ui()
	# OutputNode restores its own slot config via set_state (which calls
	# set_shader_type); sink visibility is updated after recreation below.

	var name_map := {}
	for node_data in data.get("nodes", []):
		var type: String = node_data["type"]
		if not NODE_CLASSES.has(type):
			push_warning("Nyx: unknown node type '%s', skipping" % type)
			continue
		var node = NODE_CLASSES[type].new()
		var pos: Array = node_data["position"]
		var saved_name: String = node_data["name"]
		var target_name := saved_name if not saved_name.begins_with("@") else type.trim_suffix("Node")
		_add_node(node, Vector2(pos[0], pos[1]), target_name)
		name_map[saved_name] = str(node.name)
		var state: Dictionary = node_data.get("state", {})
		if not state.is_empty():
			node.set_state(state)

	for conn in data.get("connections", []):
		var from: String = name_map.get(conn["from_node"], conn["from_node"])
		var to: String = name_map.get(conn["to_node"], conn["to_node"])
		_graph.connect_node(from, conn["from_port"], to, conn["to_port"])

	if _shader_type == 0:
		_ensure_spatial_sinks()
	elif _shader_type == 2:
		_ensure_particle_sinks()
	_update_sink_visibility()
	_request_compile()
	_loading = false


func _on_new_pressed() -> void:
	# Skip the confirm when there's nothing to lose.
	if _dirty:
		_new_confirm.popup_centered()
	else:
		_new_graph()


# Force a 3-button confirm to read [OK | mid_btn | Cancel], right-aligned: move
# each to the end of the button row in turn (any leading spacer stays put, so
# alignment is preserved). OK is the safe "Save & …" action.
func _order_dialog_buttons(dialog: AcceptDialog, mid_btn: Button) -> void:
	var ok: Button = dialog.get_ok_button()
	var cancel: Button = dialog.get_cancel_button()
	var row := ok.get_parent()
	row.move_child(ok, row.get_child_count() - 1)
	row.move_child(mid_btn, row.get_child_count() - 1)
	row.move_child(cancel, row.get_child_count() - 1)


# Reset to a fresh editor state (mirrors the initial _ready setup): empty graph,
# default starting nodes, spatial mode, unlinked, no working-file path.
func _new_graph() -> void:
	_loading = true
	_clear_graph_nodes()
	_shader_type = 0
	_sync_shader_type_ui(0)
	_current_nyx_path = ""
	_set_linked("")
	_preview_panel.reset_last_code()
	_undo_stack.clear()
	_redo_stack.clear()
	_add_node(OutputNode.new(), Vector2(300, 160), "OutputNode")
	_add_node(VertexOutputNode.new(), Vector2(300, 40), "VertexOutputNode")
	_update_sink_visibility()
	_frame_default_view()
	_request_compile()
	_loading = false
	_set_clean()  # fresh editor = nothing unsaved


# Direct save to the current file; only pops the dialog for a never-saved graph.
# (Save As / fork-to-new-file arrives with the File menu.)
func _on_save_pressed() -> void:
	if _current_nyx_path.is_empty():
		_popup_save_dialog()
	elif NyxSerializer.write(_current_nyx_path, _serialize_graph()):
		_set_clean()
		print("Nyx: saved graph → %s" % _current_nyx_path)


func _popup_save_dialog() -> void:
	# Co-locate: default the .nyx next to its linked artifact when there is one.
	if _current_nyx_path.is_empty() and not _linked_shader_path.is_empty():
		_save_dialog.current_dir = _linked_shader_path.get_base_dir()
	_save_dialog.popup_centered_ratio(0.5)


# Save the current graph, then run `after` once the save succeeds. If there's no
# path yet, open the save dialog first and continue once the user picks one.
func _save_then(after: Callable) -> void:
	if _current_nyx_path.is_empty():
		_pending_after_save = after
		_popup_save_dialog()
	elif NyxSerializer.write(_current_nyx_path, _serialize_graph()):
		_set_clean()
		after.call()


func _on_save_file_selected(path: String) -> void:
	if not path.ends_with(".nyx"):
		path += ".nyx"
	_current_nyx_path = path
	_push_recent(path)
	if NyxSerializer.write(path, _serialize_graph()):
		_set_clean()
		print("Nyx: saved graph → %s" % path)
		# Continue a pending "Save & New / Load" once the save succeeded.
		if _pending_after_save.is_valid():
			var after := _pending_after_save
			_pending_after_save = Callable()
			after.call()


# Public, guarded entry point: the Load dialog, "Open in Nyx" navigation, and
# double-click-to-open all route here. Confirms before discarding unsaved work.
func load_nyx(path: String) -> void:
	if _dirty:
		_pending_load_path = path
		_load_confirm.popup_centered()
	else:
		_do_load(path)


func _do_load(path: String) -> void:
	var data = NyxSerializer.read(path)
	if data == null:
		return
	_current_nyx_path = path
	_push_recent(path)
	_deserialize_graph(data)
	_set_clean()  # freshly loaded from disk
	# A loaded linked graph goes live by default (same as just-linked).
	if not _linked_shader_path.is_empty():
		_live_btn.button_pressed = true
	print("Nyx: loaded graph ← %s" % path)
