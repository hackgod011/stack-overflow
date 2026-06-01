class_name StarfieldBg
extends Control

## Animated star/dot field for the run map background.
## Purely decorative. Stars drift very slowly upward to give depth.

const STAR_COUNT := 80
const BASE_ALPHA := 0.55

var _stars: Array[Vector3] = []  # x, y, speed_factor
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 12345  # fixed seed — same field every run
	for _i in STAR_COUNT:
		_stars.append(Vector3(
			_rng.randf(),   # normalized x
			_rng.randf(),   # normalized y
			_rng.randf_range(0.2, 1.0)  # speed / brightness factor
		))


func _process(delta: float) -> void:
	for i in STAR_COUNT:
		_stars[i].y -= delta * _stars[i].z * 0.012
		if _stars[i].y < 0.0:
			_stars[i].y = 1.0
			_stars[i].x = _rng.randf()
	queue_redraw()


func _draw() -> void:
	for star in _stars:
		var pos := Vector2(star.x * size.x, star.y * size.y)
		var radius: float = star.z * 1.8 + 0.4
		var alpha: float = BASE_ALPHA * star.z
		draw_circle(pos, radius, Color(Colors.ACCENT_GREEN.r, Colors.ACCENT_GREEN.g, Colors.ACCENT_GREEN.b, alpha))
