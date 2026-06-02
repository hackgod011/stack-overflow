class_name CombatBg
extends Control

## Animated circuit dot-grid for the combat background.
## Dots drift upward slowly — readable hacker aesthetic without distracting gameplay.

const DOT_SPACING := 32.0
const DOT_RADIUS := 2.2
const DOT_COLOR := Color(0.15, 0.90, 0.45, 0.18)
const SCAN_COLOR := Color(0.08, 0.25, 0.12, 0.06)
const BG_COLOR := Color(0.04, 0.07, 0.10)

var _drift := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_drift = fmod(_drift + delta * 16.0, DOT_SPACING)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), BG_COLOR)

	# Drifting dot grid
	var cols := int(w / DOT_SPACING) + 2
	var rows := int(h / DOT_SPACING) + 2
	for col in cols:
		var x := col * DOT_SPACING
		for row in rows:
			var y := fmod(row * DOT_SPACING - _drift + h + DOT_SPACING, h + DOT_SPACING) - DOT_SPACING
			draw_circle(Vector2(x, y), DOT_RADIUS, DOT_COLOR)

	# Horizontal scanlines
	var y := 0.0
	while y < h:
		draw_rect(Rect2(0, y, w, 2.0), SCAN_COLOR)
		y += 8.0
