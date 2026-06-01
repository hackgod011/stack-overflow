class_name CardView
extends Control

## Visual representation of a single card.
## Handles hover state and click emission. No gameplay rules live here.

const HOLO_SHADER := preload("res://assets/shaders/holo_foil.gdshader")

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

# Per-type card background colors
const BG_COLORS := {
	CardData.CardType.VALUE:     Color(0.10, 0.18, 0.28),
	CardData.CardType.OPERATION: Color(0.18, 0.10, 0.28),
	CardData.CardType.FLOW:      Color(0.10, 0.22, 0.14),
	CardData.CardType.EFFECT:    Color(0.28, 0.10, 0.10),
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


# Public methods
func set_card_data(data: CardData) -> void:
	_card_data = data
	_title_label.text = data.title
	_cost_label.text = str(data.cost)
	_description_label.text = data.description

	# Card type background color
	if data.card_type in BG_COLORS:
		_background.color = BG_COLORS[data.card_type]

	# Holographic foil on RARE cards
	if data.rarity == CardData.Rarity.RARE:
		var mat := ShaderMaterial.new()
		mat.shader = HOLO_SHADER
		_background.material = mat
	else:
		_background.material = null

	# Card art texture
	if data.art != null:
		_art_rect.texture = data.art
		_art_rect.visible = true
	else:
		_art_rect.visible = false


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
