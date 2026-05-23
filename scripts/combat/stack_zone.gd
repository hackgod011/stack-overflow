class_name StackZone
extends VBoxContainer

## Visual zone that holds cards queued for execution.
## Cards stack top-down; index 0 = most recently added (executes first).
## No gameplay resolution logic lives here.


# Constants
const CARD_VIEW = preload("res://scenes/card/card_view.tscn")


# Signals
signal execute_requested(stack: Array[CardData])


# Private variables
var _stack: Array[CardData] = []


# @onready variables
@onready var _card_slots: VBoxContainer = $CardSlots
@onready var _execute_button: Button = $ExecuteButton


# Built-in virtuals
func _ready() -> void:
	_execute_button.pressed.connect(_on_execute_pressed)


# Public methods
func push_card(data: CardData) -> void:
	_stack.insert(0, data)
	var view: CardView = CARD_VIEW.instantiate()
	_card_slots.add_child(view)
	view.set_card_data(data)
	_card_slots.move_child(view, 0)


func pop_all() -> Array[CardData]:
	var result: Array[CardData] = _stack.duplicate()
	_stack.clear()
	for child in _card_slots.get_children():
		child.queue_free()
	return result


func get_stack() -> Array[CardData]:
	return _stack.duplicate()


# Signal handlers
func _on_execute_pressed() -> void:
	var result: Array[CardData] = pop_all()
	execute_requested.emit(result)
