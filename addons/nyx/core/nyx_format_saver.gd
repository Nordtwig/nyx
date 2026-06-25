@tool
extends ResourceFormatSaver

## Saves NyxGraph resources to `.nyx`. Delegates to Godot's native text
## serialization via a temp `.tres`, then writes that text to the `.nyx` path —
## so `.nyx` files are real, readable, diffable resource text (just a branded
## extension). Registered in plugin.gd. (Spike-validated round-trip.)
##
## No recursion: _get_recognized_extensions returns only "nyx", so the inner
## ResourceSaver.save(..., .tres) is handled by the built-in text saver, not us.

const _TMP := "user://__nyx_save_tmp.tres"
const NyxGraphRes = preload("res://addons/nyx/core/nyx_graph.gd")


func _recognize(resource: Resource) -> bool:
	return resource is NyxGraphRes


func _get_recognized_extensions(_resource: Resource) -> PackedStringArray:
	return PackedStringArray(["nyx"])


func _save(resource: Resource, path: String, _flags: int) -> Error:
	var err := ResourceSaver.save(resource, _TMP)
	if err != OK:
		return err
	var text := FileAccess.get_file_as_string(_TMP)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_TMP))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FAILED
	f.store_string(text)
	f.close()
	return OK
