class_name CardView
extends Control

## Visual representation of a single card.
## Handles hover state and click emission. No gameplay rules live here.

const HOLO_SHADER := preload("res://assets/shaders/holo_foil.gdshader")
const ART_FONT := preload("res://assets/fonts/JetBrainsMono.ttf")

# Signals
signal card_clicked(card_data: CardData)


# Enums
enum State { IDLE, HOVERED, DRAGGING, STACKED }


# Public variables
var current_state: State = State.IDLE


# Constants
const HOVER_LIFT := Vector2(0.0, -32.0)
const DEAL_DURATION := 0.25
const DEAL_START_SCALE := Vector2(0.8, 0.8)
const LAND_START_SCALE := Vector2(0.85, 0.85)
const ART_SYMBOL_SIZE := 24

# Unique background color per card — visually distinct across all 22 cards
const CARD_COLORS := {
	&"push_1":        Color(0.05, 0.16, 0.50),
	&"push_3":        Color(0.05, 0.24, 0.55),
	&"push_5":        Color(0.06, 0.32, 0.58),
	&"push_10":       Color(0.04, 0.18, 0.46),
	&"push_rand":     Color(0.04, 0.38, 0.54),
	&"dup":           Color(0.30, 0.08, 0.52),
	&"pop":           Color(0.40, 0.06, 0.44),
	&"swap":          Color(0.20, 0.06, 0.44),
	&"rot":           Color(0.12, 0.05, 0.40),
	&"add":           Color(0.05, 0.40, 0.17),
	&"mul":           Color(0.04, 0.30, 0.10),
	&"neg":           Color(0.30, 0.28, 0.04),
	&"loop_2":        Color(0.42, 0.28, 0.03),
	&"loop_3":        Color(0.46, 0.20, 0.03),
	&"if_positive":   Color(0.44, 0.16, 0.03),
	&"break":         Color(0.50, 0.10, 0.03),
	&"strike":        Color(0.52, 0.05, 0.05),
	&"heavy_strike":  Color(0.40, 0.03, 0.03),
	&"defend":        Color(0.08, 0.15, 0.42),
	&"draw_2":        Color(0.04, 0.30, 0.30),
	&"compile":       Color(0.26, 0.08, 0.32),
	&"debug":         Color(0.12, 0.28, 0.06),
}

# Large readable symbol drawn in the art area for each card
const CARD_SYMBOLS := {
	&"push_1":        "PUSH 1",
	&"push_3":        "PUSH 3",
	&"push_5":        "PUSH 5",
	&"push_10":       "PUSH 10",
	&"push_rand":     "PUSH ?",
	&"dup":           "DUP",
	&"pop":           "POP",
	&"swap":          "SWAP",
	&"rot":           "ROT",
	&"add":           "A + B",
	&"mul":           "A * B",
	&"neg":           "- A",
	&"loop_2":        "LOOP 2",
	&"loop_3":        "LOOP 3",
	&"if_positive":   "IF > 0",
	&"break":         "BREAK",
	&"strike":        "STRIKE",
	&"heavy_strike":  "HEAVY!",
	&"defend":        "DEFEND",
	&"draw_2":        "DRAW 2",
	&"compile":       "COMPILE",
	&"debug":         "DEBUG",
}


# Private variables
var _card_data: CardData
var _original_position: Vector2
var _original_z_index: int
var _tween: Tween
var _position_ready: bool = false


# @onready variables
@onready var _background: ColorRect = $Background
@onready var _title_label: Label = $TitleLabel
@onready var _cost_label: Label = $CostLabel
@onready var _art_rect: TextureRect = $ArtRect
@onready var _description_label: Label = $DescriptionLabel


# Built-in virtuals
func _ready() -> void:
	_original_z_index = z_index
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if current_state == State.IDLE or current_state == State.HOVERED:
				AudioManager.play_card_play()
				card_clicked.emit(_card_data)


func _draw() -> void:
	if _card_data == null or size.x < 10:
		return
	var symbol: String = CARD_SYMBOLS.get(_card_data.id, "")
	if symbol.is_empty():
		return
	# Art area: offset_top=40 offset_bottom=140 → center at y=90, height=100
	var art_center_x := size.x * 0.5
	var art_center_y := 90.0
	var str_size := ART_FONT.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, ART_SYMBOL_SIZE)
	var draw_x := art_center_x - str_size.x * 0.5
	var draw_y := art_center_y + float(ART_SYMBOL_SIZE) * 0.36
	draw_string(
		ART_FONT,
		Vector2(draw_x, draw_y),
		symbol,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ART_SYMBOL_SIZE,
		Color(0.15, 0.95, 0.45, 0.82)
	)


# Public methods
func set_card_data(data: CardData) -> void:
	_card_data = data
	_title_label.text = data.title
	_cost_label.text = str(data.cost)
	_description_label.text = data.description

	_background.color = CARD_COLORS.get(data.id, Color(0.12, 0.15, 0.20))

	if data.rarity == CardData.Rarity.RARE:
		var mat := ShaderMaterial.new()
		mat.shader = HOLO_SHADER
		_background.material = mat
	else:
		_background.material = null

	# Art is drawn via _draw() — hide the TextureRect
	_art_rect.visible = false
	queue_redraw()


func animate_deal() -> void:
	if _tween:
		_tween.kill()
	scale = DEAL_START_SCALE
	_tween = TweenPresets.standard_tween(self)
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), DEAL_DURATION)


func animate_land() -> void:
	if _tween:
		_tween.kill()
	scale = LAND_START_SCALE
	_tween = TweenPresets.standard_tween(self)
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), TweenPresets.STANDARD_DURATION)


func disable() -> void:
	if mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.disconnect(_on_mouse_entered)
	if mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.disconnect(_on_mouse_exited)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


# Private methods
func _animate_hover() -> void:
	if _tween:
		_tween.kill()
	_tween = TweenPresets.standard_tween(self)
	z_index = _original_z_index + 1
	_tween.tween_property(self, "position", _original_position + HOVER_LIFT, TweenPresets.STANDARD_DURATION)
	_tween.parallel().tween_property(self, "scale", Vector2(1.08, 1.08), TweenPresets.STANDARD_DURATION)


func _animate_idle() -> void:
	if _tween:
		_tween.kill()
	_tween = TweenPresets.standard_tween(self)
	z_index = _original_z_index
	_tween.tween_property(self, "position", _original_position, TweenPresets.STANDARD_DURATION)
	_tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), TweenPresets.STANDARD_DURATION)


# Signal handlers
func _on_mouse_entered() -> void:
	if not _position_ready:
		_original_position = position
		_position_ready = true
	current_state = State.HOVERED
	_animate_hover()


func _on_mouse_exited() -> void:
	current_state = State.IDLE
	_animate_idle()
