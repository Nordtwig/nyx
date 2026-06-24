@tool
extends "res://addons/nyx/nodes/particle_sink_node.gd"

# Particle Process sink — runs every frame per particle.
# Each slot emits its assignment ONLY if connected (empty-default = skip pattern,
# same as OutputNode Normal / Vertex slots). Position auto-integrates from
# VELOCITY when unconnected; connecting Position is an absolute override.
# Fixed node name "ParticleProcessNode" so the compiler can find it.

const _LABELS := ["Velocity", "Color", "Position"]


func _ready() -> void:
	super._ready()
	title = "Particle Process"
	var vec3_color := Color.WHITE
	var vec4_color := Color("#FF8FC0")

	# Type IDs: 0 = vec3, 3 = vec4.
	set_slot(0, true, 0, vec3_color, false, -1, vec3_color)  # Velocity
	set_slot(1, true, 3, vec4_color, false, -1, vec4_color)  # Color
	set_slot(2, true, 0, vec3_color, false, -1, vec3_color)  # Position

	for label_text in _LABELS:
		var label := Label.new()
		label.text = label_text
		add_child(label)
