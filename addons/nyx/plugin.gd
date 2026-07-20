@tool
extends EditorPlugin

const NyxCharon = preload("res://addons/nyx/core/charon.gd")

var _main_screen: Control
var _editor_main_screen: Control
var _context_menu: EditorContextMenuPlugin
var _tooltip_plugin: EditorResourceTooltipPlugin
var _shader_importer: EditorImportPlugin
# Focus layout: collapse Godot's docks while Nyx is the visible main screen.
var _focus_active: bool = false
var _prior_distraction_free: bool = false


func _get_plugin_name() -> String:
	return "Nyx"


func _get_plugin_icon() -> Texture2D:
	return preload("res://addons/nyx/icons/nyx.svg")


func _has_main_screen() -> bool:
	return true


# CONFIRMED via live testing 2026-07-05 (3 experiments, see backlog.md ->
# "`.nyx` as a directly-usable Shader" for the full log): double-click DOES
# call _handles()/_edit(), but Godot's own native "open the shader/text editor
# for this Shader resource, and focus it" behavior always wins the visible
# foreground regardless - tried a synchronous switch, a deferred switch, and a
# deferred switch + 2-frame wait + an explicit ScriptEditor.close_file() call,
# all with the identical result. get_open_scripts() never even reports the
# native tab as tracked (always empty), across every timing variant tried -
# meaning close_file() cannot ever succeed against it (it's Script-only, not
# Shader-aware, despite the visual similarity). This is a hardcoded editor
# behavior with no discovered plugin-facing override point - not worth chasing
# further. The real, working re-entry path is "Open in Nyx" (right-click,
# core/open_in_nyx_context_menu.gd), confirmed clean with no shader-editor side
# effect. _handles()/_edit() are kept anyway (see below) since they still do
# something real even though they lose the focus race: Nyx's internal state
# gets loaded to the correct graph, so manually switching to the Nyx tab
# afterward already shows the right thing instead of whatever was there before.
#
# Gate: `.nyx`-extension resource_path (only our importer ever produces a
# Shader from a `.nyx`-extension file, so this alone is reliable) plus the
# provenance stamp (belt-and-suspenders, matching how every other re-entry gate
# in this codebase - the context menu, the tooltip plugin - trusts the stamp
# over naming). Deliberately does NOT match a `.gdshader` carrying the same
# stamp: that's the separate "Open in Nyx" context-menu path, and double-
# clicking an exported .gdshader is meant to keep opening the plain GLSL text
# editor (see CLAUDE.md's Save/load section - "a nice edge over VisualShader").
# Old .nyx files saved before compiled_code existed show the importer's
# placeholder code (no stamp) and won't match here either way - resave in Nyx
# once to fix that.
func _handles(object) -> bool:
	if not object is Shader:
		return false
	var shader := object as Shader
	if shader.resource_path.get_extension() != "nyx":
		return false
	return not NyxCharon.read_nyx_source_from_code(shader.code).is_empty()


func _edit(object) -> void:
	if not _handles(object):
		return
	EditorInterface.set_main_screen_editor("Nyx")
	if _main_screen and _main_screen.has_method("load_nyx"):
		_main_screen.load_nyx(object.resource_path)


func _make_visible(visible: bool) -> void:
	if _main_screen:
		_main_screen.visible = visible
	# Collapse the editor docks while Nyx is up; restore on leave. Guarded so the
	# initial _make_visible(false) in _enter_tree can't clobber a user who already
	# has distraction-free on, and so re-entry keeps the original captured value.
	if visible:
		if not _focus_active:
			_prior_distraction_free = NyxCharon.enter_focus_layout()
			_focus_active = true
	elif _focus_active:
		NyxCharon.exit_focus_layout(_prior_distraction_free)
		_focus_active = false


func _enter_tree() -> void:
	_editor_main_screen = EditorInterface.get_editor_main_screen()
	_main_screen = preload("res://addons/nyx/nyx_main.gd").new()
	_editor_main_screen.add_child(_main_screen)
	_editor_main_screen.resized.connect(_sync_size)
	_sync_size.call_deferred()
	_make_visible(false)
	_main_screen.reload_requested.connect(_reload)

	# Forward the editor's active-scene-tab changes / saves into the main screen
	# so the preview panel's scene-mode follow can track them (Charon-adjacent
	# seam — see .nyx-notes/olympus-viewport.md). Connected to our own
	# EditorPlugin signals; the handlers look up _main_screen fresh so a Reload
	# (which rebuilds it) stays wired.
	scene_changed.connect(_on_editor_scene_changed)
	scene_saved.connect(_on_editor_scene_saved)

	# Navigation: artifact -> Nyx (gated on the provenance stamp).
	_context_menu = preload("res://addons/nyx/core/open_in_nyx_context_menu.gd").new()
	_context_menu.open_callback = _open_in_nyx
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _context_menu)

	_tooltip_plugin = preload("res://addons/nyx/core/nyx_tooltip_plugin.gd").new()
	EditorInterface.get_file_system_dock().add_resource_tooltip_plugin(_tooltip_plugin)

	# `.nyx` imports directly as a Shader (see core/nyx_shader_importer.gd).
	_register_nyx_import()


# Registers a fresh instance; also re-run on "Reload Nyx" - re-parsing the plugin
# scripts likely stales the registered import plugin the same way it staled the
# old format loader (dev-only: end users never reload).
func _register_nyx_import() -> void:
	_shader_importer = preload("res://addons/nyx/core/nyx_shader_importer.gd").new()
	add_import_plugin(_shader_importer)


func _unregister_nyx_import() -> void:
	if _shader_importer:
		remove_import_plugin(_shader_importer)
		_shader_importer = null


func _on_editor_scene_changed(scene_root: Node) -> void:
	if _main_screen and _main_screen.has_method("on_active_scene_changed"):
		_main_screen.on_active_scene_changed(scene_root)


func _on_editor_scene_saved(filepath: String) -> void:
	if _main_screen and _main_screen.has_method("on_scene_saved"):
		_main_screen.on_scene_saved(filepath)


# nyx_path is the resolved (possibly missing) `.nyx` target; source_path is the
# file that was actually right-clicked (itself when it's already `.nyx`, the
# exported `.gdshader` otherwise) - kept around so a missing target has
# something to fall back to.
func _open_in_nyx(nyx_path: String, source_path: String) -> void:
	if FileAccess.file_exists(nyx_path):
		EditorInterface.set_main_screen_editor("Nyx")
		if _main_screen and _main_screen.has_method("load_nyx"):
			_main_screen.load_nyx(nyx_path)
		return
	# The linked `.nyx` is gone - fall back to the graph embedded in the shader
	# itself at export time (see NyxSerializer.write_shader / this file's
	# NyxCharon.read_embedded_graph).
	var graph := NyxCharon.read_embedded_graph(source_path)
	if graph.is_empty():
		push_warning("Nyx: source graph not found - %s" % nyx_path)
		return
	EditorInterface.set_main_screen_editor("Nyx")
	if _main_screen and _main_screen.has_method("load_from_embedded_graph"):
		_main_screen.load_from_embedded_graph(graph, source_path)


func _reload() -> void:
	_unregister_nyx_import()  # stale after re-parse; re-registered in _finish_reload
	if _main_screen:
		_main_screen.queue_free()
		_main_screen = null
	call_deferred("_finish_reload")


func _finish_reload() -> void:
	_register_nyx_import()
	_main_screen = preload("res://addons/nyx/nyx_main.gd").new()
	_editor_main_screen.add_child(_main_screen)
	_main_screen.reload_requested.connect(_reload)
	_sync_size.call_deferred()
	_make_visible(true)


func _sync_size() -> void:
	if _main_screen:
		_main_screen.sync_size(_editor_main_screen.size)


func _exit_tree() -> void:
	if _focus_active:
		NyxCharon.exit_focus_layout(_prior_distraction_free)
		_focus_active = false
	if _editor_main_screen and _editor_main_screen.resized.is_connected(_sync_size):
		_editor_main_screen.resized.disconnect(_sync_size)
	if _main_screen:
		_main_screen.queue_free()
	if _context_menu:
		remove_context_menu_plugin(_context_menu)
	if _tooltip_plugin:
		EditorInterface.get_file_system_dock().remove_resource_tooltip_plugin(_tooltip_plugin)
	_unregister_nyx_import()
