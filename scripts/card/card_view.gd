class_name CardView
extends Control

## Visual representation of a single card.
## Uses marcus_darius card frames as backgrounds, draws card symbol via _draw().

const HOLO_SHADER := preload("res://assets/shaders/holo_foil.gdshader")
const ART_FONT := preload("res://assets/fonts/JetBrainsMono.ttf")

# Card frame textures by type
const FRAME_RED    := preload("res://assets/card_frames/card_frame_blank_red.png")
const FRAME_BLUE   := preload("res://assets/card_frames/card_frame_blank_blue.png")
const FRAME_GREEN  := preload("res://assets/card_frames/card_frame_blank_green.png")
const FRAME_YELLOW := preload("res://assets/card_frames/card_frame_blank_yellow.png")
const FRAME_PURPLE := preload("res://assets/card_frames/card_frame_blank_purple.png")

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
const ART_SYMBOL_SIZE := 26

# Bright title color per card type (contrast on dark frame interior)
const TYPE_TITLE_COLORS := {
	CardData.CardType.VALUE:     Color(0.35, 0.80, 1.00),  # cyan-blue
	CardData.CardType.OPERATION: Color(0.40, 1.00, 0.60),  # bright green
	CardData.CardType.FLOW:      Color(1.00, 0.90, 0.25),  # golden yellow
	CardData.CardType.EFFECT:    Color(1.00, 0.50, 0.30),  # orange-red
}

# Large symbol drawn in the art area — immediately communicates what the card does
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

# Damage-dealing EFFECT cards get the red frame; utility EFFECT cards get purple
const RED_FRAME_CARDS := [&"strike", &"heavy_strike"]


# Private variables
var _card_data: CardData
var _original_position: Vector2
var _original_z_index: int
var _tween: Tween
var _position_ready: bool = false


# @onready variables
@onready var _background: TextureRect = $Background
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
	# Art area: top=40, bottom=140 → center y=90
	var art_center_y := 90.0
	var str_size := ART_FONT.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, ART_SYMBOL_SIZE)
	var draw_x := size.x * 0.5 - str_size.x * 0.5
	var draw_y := art_center_y + float(ART_SYMBOL_SIZE) * 0.36
	draw_string(
		ART_FONT,
		Vector2(draw_x, draw_y),
		symbol,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ART_SYMBOL_SIZE,
		Color(0.20, 1.00, 0.55, 0.92)
	)


# Public methods
func set_card_data(data: CardData) -> void:
	_card_data = data
	_title_label.text = data.title
	_cost_label.text = str(data.cost)
	_description_label.text = data.description

	# Select frame + title color by type / rarity
	var title_color := Color.WHITE
	if data.rarity == CardData.Rarity.RARE:
		_background.texture = FRAME_PURPLE
		var mat := ShaderMaterial.new()
		mat.shader = HOLO_SHADER
		_background.material = mat
		title_color = Color(1.0, 0.85, 0.25)  # gold for rares
	else:
		_background.material = null
		match data.card_type:
			CardData.CardType.VALUE:
				_background.texture = FRAME_BLUE
			CardData.CardType.OPERATION:
				_background.texture = FRAME_GREEN
			CardData.CardType.FLOW:
				_background.texture = FRAME_YELLOW
			CardData.CardType.EFFECT:
				if data.id in RED_FRAME_CARDS:
					_background.texture = FRAME_RED
				else:
					_background.texture = FRAME_PURPLE
		title_color = TYPE_TITLE_COLORS.get(data.card_type, Color.WHITE)

	_title_label.add_theme_color_override("font_color", title_color)
	_cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.20))
	_description_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

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
