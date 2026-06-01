class_name TerminalBg
extends Control

## Draws a faint scrolling terminal code rain in the background.
## Purely decorative — no gameplay logic. Runs in _process; kept cheap.

const LINES: Array[String] = [
	"PUSH 5  DUP  ADD  STRIKE",
	"for i in stack: apply(i)",
	"0x7FFF_DEAD  NULL_PTR",
	"if stack.top() > 0: exec",
	"LOOP 3  MUL  COMPILE",
	"seg fault (core dumped)",
	"01001000 01100101 01111000",
	"stack overflow detected",
	"def resolve(ctx): ...",
	"0b1010  0o17  0xFF",
	"while not done: pop()",
	"ERR: runtime stack empty",
	"SWAP  ROT  NEG  BREAK",
]

const LINE_HEIGHT := 22.0
const SCROLL_SPEED := 28.0
const COLUMNS := 3
const ALPHA := 0.06

var _offsets: Array[float] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_offsets.resize(COLUMNS)
	for i in COLUMNS:
		_offsets[i] = i * 240.0


func _process(delta: float) -> void:
	for i in COLUMNS:
		_offsets[i] += SCROLL_SPEED * delta
		if _offsets[i] > size.y + 200.0:
			_offsets[i] = -200.0
	queue_redraw()


func _draw() -> void:
	var col_width: float = size.x / COLUMNS
	for col in COLUMNS:
		var x := col * col_width + 12.0
		var y_start := -_offsets[col]
		var line_index := int(_offsets[col] / LINE_HEIGHT) % LINES.size()
		var y := y_start + (int(_offsets[col] / LINE_HEIGHT) * LINE_HEIGHT)
		while y < size.y + LINE_HEIGHT:
			var line := LINES[line_index % LINES.size()]
			draw_string(
				ThemeDB.fallback_font,
				Vector2(x, y),
				line,
				HORIZONTAL_ALIGNMENT_LEFT,
				int(col_width) - 12,
				11,
				Color(Colors.ACCENT_GREEN.r, Colors.ACCENT_GREEN.g, Colors.ACCENT_GREEN.b, ALPHA)
			)
			y += LINE_HEIGHT
			line_index += 1
