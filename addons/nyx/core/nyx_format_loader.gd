@tool
extends ResourceFormatLoader

## Loads `.nyx` files back into NyxGraph resources. Mirror of the saver: copies
## the `.nyx` text to a temp `.tres` and lets the built-in text loader parse it.
## Registered in plugin.gd.

const _TMP := "user://__nyx_load_tmp.tres"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["nyx"])


func _handles_type(type: StringName) -> bool:
	return type == &"Resource" or type == &"NyxGraph"


func _get_resource_type(path: String) -> String:
	return "NyxGraph" if path.get_extension() == "nyx" else ""


func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var text := FileAccess.get_file_as_string(path)
	var f := FileAccess.open(_TMP, FileAccess.WRITE)
	if f == null:
		return ERR_CANT_CREATE
	f.store_string(text)
	f.close()
	var res := ResourceLoader.load(_TMP, "", ResourceLoader.CACHE_MODE_IGNORE)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_TMP))
	if res == null:
		return ERR_PARSE_ERROR
	return res
