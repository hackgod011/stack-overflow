class_name CardView
extends Control

## Visual representation of a single card.
## Handles hover state and click emission. No gameplay rules live here.


# Signals
signal card_clicked(card_data: CardData)


# Enums
enum State { IDLE, HOVERED, DRAGGING, STACKED }


# Public variables
var current_state: State = State.IDLE


# Private variables
var _card_data: CardData


# @onready variables
@onready var _background: ColorRect = $Background
@onready var _title_label: Label = $TitleLabel
@onready var _cost_label: Label = $CostLabel
@onready var _description_label: Label = $DescriptionLabel


# Built-in virtuals
func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if current_state == State.IDLE or current_state == State.HOVERED:
				card_clicked.emit(_card_data)


# Public methods
func set_card_data(data: CardData) -> void:
	_card_data = data
	_title_label.text = data.title
	_cost_label.text = str(data.cost)
	_description_label.text = data.description


# Signal handlers
func _on_mouse_entered() -> void:
	current_state = State.HOVERED


func _on_mouse_exited() -> void:
	current_state = State.IDLE
