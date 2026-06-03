class_name CombatBg
extends Control

## Animated circuit dot-grid for the combat background.
## Uses get_viewport_rect() instead of size — the instanced Control's rect
## may not be resolved when the scene loads, making size=(0,0).

const DOT_SPACING := 30.0
const DOT_RADIUS := 2.5
const DOT_COLOR := Color(0.15, 0.90, 0.45, 0.30)
const SCAN_COLOR := Color(0.06, 0.22, 0.10, 0.08)
const BG_COLOR := Color(0.04, 0.07, 0.10)

var _drift := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_drift = fmod(_drift + delta * 14.0, DOT_SPACING)
	queue_redraw()


func _draw() -> void:
	var vp := get_viewport_rect()
	var w := vp.size.x
	var h := vp.size.y

	draw_rect(Rect2(0, 0, w, h), BG_COLOR)

	# Drifting dot grid
	var cols := int(w / DOT_SPACING) + 2
	var rows := int(h / DOT_SPACING) + 2
	for col in cols:
		var x := col * DOT_SPACING
		for row in rows:
			var dot_y := fmod(row * DOT_SPACING - _drift + h + DOT_SPACING, h + DOT_SPACING) - DOT_SPACING
			draw_circle(Vector2(x, dot_y), DOT_RADIUS, DOT_COLOR)

	# Subtle horizontal scanlines
	var scan_y := 0.0
	while scan_y < h:
		draw_rect(Rect2(0, scan_y, w, 2.0), SCAN_COLOR)
		scan_y += 8.0
