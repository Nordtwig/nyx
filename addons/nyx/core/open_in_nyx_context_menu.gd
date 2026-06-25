@tool
extends EditorContextMenuPlugin

## Adds "Open in Nyx" to the FileSystem right-click menu for Nyx-authored
## shaders only (gated on the provenance stamp). plugin.gd sets `open_callback`
## to route the resolved .nyx path into the Nyx main screen.

const NyxCharon = preload("res://addons/nyx/core/charon.gd")

var open_callback: Callable


func _popup_menu(paths: PackedStringArray) -> void:
	if paths.size() != 1:
		return
	if NyxCharon.read_nyx_source(paths[0]).is_empty():
		return
	var icon := EditorInterface.get_editor_theme().get_icon("Shader", "EditorIcons")
	add_context_menu_item("Open in Nyx", _on_open, icon)


func _on_open(paths) -> void:
	if paths == null or paths.is_empty():
		return
	var nyx_path := NyxCharon.read_nyx_source(paths[0])
	if nyx_path.is_empty():
		return
	if open_callback.is_valid():
		open_callback.call(nyx_path)
