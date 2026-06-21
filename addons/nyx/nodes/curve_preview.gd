@tool
extends Control

var curve: Curve = null


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.10, 0.14))
	if curve == null or curve.get_point_count() < 2:
		return
	var steps := int(size.x)
	var pts := PackedVector2Array()
	for i in range(steps):
		var t := float(i) / float(max(steps - 1, 1))
		var v := curve.sample_baked(t)
		pts.append(Vector2(i, size.y - clampf(v, 0.0, 1.0) * size.y))
	draw_polyline(pts, Color(0.15, 0.61, 0.36), 1.5, true)
