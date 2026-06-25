@tool
extends EditorResourceTooltipPlugin

## Hover tooltip in the FileSystem dock for Nyx-authored shaders — the closest
## thing to an at-a-glance "this came from Nyx" indicator (a real per-file dock
## icon isn't possible in Godot 4.7; see .nyx-notes/live-link.md). Gated on the
## provenance stamp so hand-written shaders are untouched.

const NyxCharon = preload("res://addons/nyx/core/charon.gd")


func _handles(type: String) -> bool:
	return type == "Shader"


func _make_tooltip_for_path(path: String, metadata: Dictionary, base: Control) -> Control:
	var nyx_path := NyxCharon.read_nyx_source(path)
	if nyx_path.is_empty():
		return base  # not ours — keep Godot's default tooltip
	var note := Label.new()
	note.text = "✦ Authored in Nyx — right-click → Open in Nyx\n    %s" % nyx_path
	note.add_theme_color_override("font_color", Color(0.35, 0.9, 0.85))
	base.add_child(note)
	return base
