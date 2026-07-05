@tool
extends EditorContextMenuPlugin

## Adds "Open in Nyx" to the FileSystem right-click menu. Two cases:
## - a `.nyx` file itself: always offered (no gating needed - nothing else
##   produces that extension, and double-clicking it opens Godot's built-in
##   shader editor instead of Nyx, since that editor claims Shader-typed
##   resources before any addon's _handles()/_edit() is consulted; this menu
##   item is therefore the primary re-entry path for `.nyx`, not a fallback).
## - an exported `.gdshader`: gated on the provenance stamp, resolves back to
##   its source `.nyx` path (unchanged from before).
## plugin.gd sets `open_callback` to route the resolved .nyx path into the Nyx
## main screen.

const NyxCharon = preload("res://addons/nyx/core/charon.gd")

var open_callback: Callable


func _popup_menu(paths: PackedStringArray) -> void:
	if paths.size() != 1:
		return
	if _resolve_nyx_path(paths[0]).is_empty():
		return
	var icon := EditorInterface.get_editor_theme().get_icon("Shader", "EditorIcons")
	add_context_menu_item("Open in Nyx", _on_open, icon)


func _on_open(paths) -> void:
	if paths == null or paths.is_empty():
		return
	var nyx_path := _resolve_nyx_path(paths[0])
	if nyx_path.is_empty():
		return
	if open_callback.is_valid():
		open_callback.call(nyx_path)


func _resolve_nyx_path(path: String) -> String:
	if path.ends_with(".nyx"):
		return path
	return NyxCharon.read_nyx_source(path)
