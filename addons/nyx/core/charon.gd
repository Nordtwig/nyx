@tool
extends RefCounted

# Intentionally NO `class_name`: core Charon is bundled per-plugin (namespaced),
# so each Olympus tool preloads its own copy rather than sharing one global
# symbol. Reference via:  const NyxCharon = preload(".../core/charon.gd")

## Charon — core communication seam between Nyx and Godot.
##
## This is the STATELESS, static "core Charon" only: plugin↔Godot utilities, no
## registry, no event bus, no shared state. Each Olympus plugin bundles its own
## copy (namespaced). The full event-bus Charon is a separate, future standalone
## plugin; when it exists, the seams below hand off to it instead of acting
## directly.
##
## V1 publishes nothing on a bus. The signal name and payload shape below are
## fixed now as CONVENTION ONLY, so Full Charon (with Hephaestus and Iris as
## future subscribers) can route them later. Getting the name/payload right
## matters more than any V1 code here.

## Convention-only event name. Not emitted in V1 — reserved for Full Charon.
const SIGNAL_SHADER_UPDATED := "nyx:shader_updated"

## Provenance stamp written as the first line of an exported .gdshader. Gates the
## artifact → Nyx navigation (we only offer "Open in Nyx" for shaders we authored).
const PROVENANCE_PREFIX := "// nyx_source: "


## Reads the provenance stamp from an exported shader, returning the source .nyx
## path (res://…) or "" if the file isn't a Nyx-authored shader. The stamp is
## always the first line (see nyx_main._write_shader_file).
static func read_nyx_source(shader_path: String) -> String:
	if not shader_path.ends_with(".gdshader"):
		return ""
	if not FileAccess.file_exists(shader_path):
		return ""
	var f := FileAccess.open(shader_path, FileAccess.READ)
	if f == null:
		return ""
	var first := f.get_line()
	f.close()
	if first.begins_with(PROVENANCE_PREFIX):
		return first.substr(PROVENANCE_PREFIX.length()).strip_edges()
	return ""


## Push freshly-compiled shader code into the live, loaded Shader resource at
## `shader_path`. Because Godot caches resources, mutating that loaded instance's
## `.code` propagates in-memory to every material in the scene that references it
## — the live-link update, no disk write.
##
## `material` is the source of truth for the code (the live preview material,
## whose shader carries the latest compile). Returns true on success.
##
## Future: if Full Charon is present, emit nyx:shader_updated on its bus with
## payload { shader_path, material } and let it route, instead of acting here.
static func notify_shader_updated(shader_path: String, material: Material) -> bool:
	if shader_path.is_empty() or material == null:
		return false
	if not material is ShaderMaterial:
		return false
	var src_shader: Shader = (material as ShaderMaterial).shader
	if src_shader == null:
		return false
	if not ResourceLoader.exists(shader_path):
		return false
	var target: Shader = ResourceLoader.load(shader_path, "Shader")
	if target == null:
		return false
	if target.code != src_shader.code:
		target.code = src_shader.code
	return true
