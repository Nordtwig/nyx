@tool
extends EditorPlugin

const NyxCharon = preload("res://addons/nyx/core/charon.gd")
const NyxGraphRes = preload("res://addons/nyx/core/nyx_graph.gd")

var _main_screen: Control
var _editor_main_screen: Control
var _context_menu: EditorContextMenuPlugin
var _tooltip_plugin: EditorResourceTooltipPlugin
var _nyx_saver: ResourceFormatSaver
var _nyx_loader: ResourceFormatLoader
# Focus layout: collapse Godot's docks while Nyx is the visible main screen.
var _focus_active: bool = false
var _prior_distraction_free: bool = false


func _get_plugin_name() -> String:
	return "Nyx"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Shader", "EditorIcons")


func _has_main_screen() -> bool:
	return true


# Double-click a `.nyx` in the FileSystem dock → open it in the Nyx tab.
func _handles(object) -> bool:
	return object is NyxGraphRes


func _edit(object) -> void:
	if object is NyxGraphRes and not object.resource_path.is_empty():
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

	# Navigation: artifact → Nyx (gated on the provenance stamp).
	_context_menu = preload("res://addons/nyx/core/open_in_nyx_context_menu.gd").new()
	_context_menu.open_callback = _open_in_nyx
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _context_menu)

	_tooltip_plugin = preload("res://addons/nyx/core/nyx_tooltip_plugin.gd").new()
	EditorInterface.get_file_system_dock().add_resource_tooltip_plugin(_tooltip_plugin)

	# `.nyx` as a native Resource (custom format saver/loader).
	_register_nyx_format()


# Registers fresh instances; also re-run on "Reload Nyx" because re-parsing the
# plugin scripts stales the registered format loader (dev-only: end users never reload).
func _register_nyx_format() -> void:
	_nyx_saver = preload("res://addons/nyx/core/nyx_format_saver.gd").new()
	_nyx_loader = preload("res://addons/nyx/core/nyx_format_loader.gd").new()
	ResourceSaver.add_resource_format_saver(_nyx_saver)
	ResourceLoader.add_resource_format_loader(_nyx_loader)


func _unregister_nyx_format() -> void:
	if _nyx_saver:
		ResourceSaver.remove_resource_format_saver(_nyx_saver)
		_nyx_saver = null
	if _nyx_loader:
		ResourceLoader.remove_resource_format_loader(_nyx_loader)
		_nyx_loader = null


func _open_in_nyx(nyx_path: String) -> void:
	if not FileAccess.file_exists(nyx_path):
		push_warning("Nyx: source graph not found — %s" % nyx_path)
		return
	EditorInterface.set_main_screen_editor("Nyx")
	if _main_screen and _main_screen.has_method("load_nyx"):
		_main_screen.load_nyx(nyx_path)


func _reload() -> void:
	_unregister_nyx_format()  # stale after re-parse; re-registered in _finish_reload
	if _main_screen:
		_main_screen.queue_free()
		_main_screen = null
	call_deferred("_finish_reload")


func _finish_reload() -> void:
	_register_nyx_format()
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
	_unregister_nyx_format()
