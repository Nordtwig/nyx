@tool
extends EditorPlugin

var _main_screen: Control
var _editor_main_screen: Control
var _reload_button: Button
var _context_menu: EditorContextMenuPlugin
var _tooltip_plugin: EditorResourceTooltipPlugin


func _get_plugin_name() -> String:
	return "Nyx"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Shader", "EditorIcons")


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if _main_screen:
		_main_screen.visible = visible


func _enter_tree() -> void:
	_editor_main_screen = EditorInterface.get_editor_main_screen()
	_main_screen = preload("res://addons/nyx/nyx_main.gd").new()
	_editor_main_screen.add_child(_main_screen)
	_editor_main_screen.resized.connect(_sync_size)
	_sync_size.call_deferred()
	_make_visible(false)

	_reload_button = Button.new()
	_reload_button.text = "Reload Nyx"
	_reload_button.pressed.connect(_reload)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _reload_button)

	# Navigation: artifact → Nyx (gated on the provenance stamp).
	_context_menu = preload("res://addons/nyx/core/open_in_nyx_context_menu.gd").new()
	_context_menu.open_callback = _open_in_nyx
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _context_menu)

	_tooltip_plugin = preload("res://addons/nyx/core/nyx_tooltip_plugin.gd").new()
	EditorInterface.get_file_system_dock().add_resource_tooltip_plugin(_tooltip_plugin)


func _open_in_nyx(nyx_path: String) -> void:
	if not FileAccess.file_exists(nyx_path):
		push_warning("Nyx: source graph not found — %s" % nyx_path)
		return
	EditorInterface.set_main_screen_editor("Nyx")
	if _main_screen and _main_screen.has_method("load_nyx"):
		_main_screen.load_nyx(nyx_path)


func _reload() -> void:
	if _main_screen:
		_main_screen.queue_free()
		_main_screen = null
	call_deferred("_finish_reload")


func _finish_reload() -> void:
	_main_screen = preload("res://addons/nyx/nyx_main.gd").new()
	_editor_main_screen.add_child(_main_screen)
	_sync_size.call_deferred()
	_make_visible(true)


func _sync_size() -> void:
	if _main_screen:
		_main_screen.sync_size(_editor_main_screen.size)


func _exit_tree() -> void:
	if _editor_main_screen and _editor_main_screen.resized.is_connected(_sync_size):
		_editor_main_screen.resized.disconnect(_sync_size)
	if _main_screen:
		_main_screen.queue_free()
	if _reload_button:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, _reload_button)
		_reload_button.queue_free()
	if _context_menu:
		remove_context_menu_plugin(_context_menu)
	if _tooltip_plugin:
		EditorInterface.get_file_system_dock().remove_resource_tooltip_plugin(_tooltip_plugin)
