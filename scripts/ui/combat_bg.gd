class_name CombatBg
extends Control

## Subtle animated dot-grid for the combat background.
## Dots drift upward slowly — circuit-board / data-stream feel.
## No gameplay logic. Cheap: one draw call per frame.

const DOT_SPACING := 40.0
const DOT_COLOR := Color(0.12, 0.85, 0.40, 0.045)
const SCAN_COLOR := Color(0.06, 0.20, 0.10, 0.022)
const BG_COLOR := Color(0.03, 0.05, 0.08)

var _drift := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_drift = fmod(_drift + delta * 14.0, DOT_SPACING)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), BG_COLOR)

	# Drifting dot grid (dots flow upward)
	var cols := int(w / DOT_SPACING) + 2
	var rows := int(h / DOT_SPACING) + 2
	for col in cols:
		var x := col * DOT_SPACING
		for row in rows:
			var y := fmod(row * DOT_SPACING - _drift + h + DOT_SPACING, h + DOT_SPACING) - DOT_SPACING
			draw_circle(Vector2(x, y), 1.2, DOT_COLOR)

	# Horizontal scanlines (static)
	var y := 0.0
	while y < h:
		draw_rect(Rect2(0, y, w, 2.0), SCAN_COLOR)
		y += 8.0
