@tool
extends EditorImportPlugin

## Imports `.nyx` directly as a Shader - the mechanism behind dragging a graph
## straight onto a material's shader slot, no export/link step required.
## Reads the `compiled_code` field baked into the .nyx at save time (see
## nyx_main.gd's _serialize_graph_for_save()); does NOT run the graph compiler
## itself - that needs live GraphNode instances, which an import pass doesn't
## have. See backlog.md -> "`.nyx` as a directly-usable Shader".
##
## Registered/unregistered in plugin.gd (add_import_plugin/remove_import_plugin).

const NyxSerializer = preload("res://addons/nyx/nyx_serializer.gd")
const NyxCharon = preload("res://addons/nyx/core/charon.gd")

# Graphs saved before this feature existed (or never re-saved since) have no
# compiled_code yet. Rather than fail the import outright, fall back to an
# obvious placeholder + a warning pointing at the fix - this is pre-release
# and cheap now; the real graceful-degrade path is a v1-ship-time concern
# (see backlog.md's migration note), not needed today. Carries NAV_HINT too -
# right-click "Open in Nyx" still works on an un-migrated .nyx (its context-
# menu check doesn't require the stamp), so the pointer is still accurate here.
const _PLACEHOLDER_CODE := NyxCharon.NAV_HINT + "shader_type spatial;\nvoid fragment() {\n\tALBEDO = vec3(1.0, 0.0, 1.0);\n}\n"


func _get_importer_name() -> String:
	return "nyx.shader_importer"


func _get_visible_name() -> String:
	return "Nyx Shader Graph"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["nyx"])


func _get_save_extension() -> String:
	return "res"


func _get_resource_type() -> String:
	return "Shader"


func _get_priority() -> float:
	return 1.0


func _get_import_order() -> int:
	return 0


func _get_preset_count() -> int:
	return 1


func _get_preset_name(_preset_index: int) -> String:
	return "Default"


func _get_import_options(_path: String, _preset_index: int) -> Array[Dictionary]:
	return []


func _get_option_visibility(_path: String, _option_name: StringName, _options: Dictionary) -> bool:
	return true


func _import(source_file: String, save_path: String, _options: Dictionary,
		_platform_variants: Array[String], _gen_files: Array[String]) -> Error:
	var d = NyxSerializer.read(source_file)
	if d == null:
		return ERR_PARSE_ERROR
	var code: String = d.get("compiled_code", "")
	if code.is_empty():
		push_warning("Nyx: %s has no compiled shader yet - open it in Nyx and save once to enable direct use." % source_file)
		code = _PLACEHOLDER_CODE
	var shader := Shader.new()
	shader.code = code
	return ResourceSaver.save(shader, "%s.%s" % [save_path, _get_save_extension()])
