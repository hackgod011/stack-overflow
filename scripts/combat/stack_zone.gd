class_name StackZone
extends VBoxContainer

## Visual zone that holds cards queued for execution.
## Cards stack with visual offset; index 0 in _stack = most recently added (executes first).
## No gameplay resolution logic lives here.


# Constants
const CARD_VIEW = preload("res://scenes/card/card_view.tscn")
const CARD_SCALE := Vector2(0.62, 0.62)
const STACK_OFFSET := 14.0


# Signals
signal execute_requested(stack: Array[CardData])
signal clear_requested(cards: Array[CardData])


# Private variables
var _stack: Array[CardData] = []


# @onready variables
@onready var _card_slots: Control = $CardSlots
@onready var _execute_button: Button = $ButtonRow/ExecuteButton
@onready var _clear_button: Button = $ButtonRow/ClearButton


# Built-in virtuals
func _ready() -> void:
	_execute_button.pressed.connect(_on_execute_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)


# Public methods
func push_card(data: CardData) -> void:
	_stack.insert(0, data)
	var view: CardView = CARD_VIEW.instantiate()
	_card_slots.add_child(view)
	view.set_card_data(data)
	view.scale = CARD_SCALE
	view.disable()
	_reposition_all()
	view.animate_land()


func pop_all() -> Array[CardData]:
	var result: Array[CardData] = _stack.duplicate()
	_stack.clear()
	for child in _card_slots.get_children():
		child.queue_free()
	return result


func clear_stack() -> Array[CardData]:
	var result: Array[CardData] = _stack.duplicate()
	_stack.clear()
	for child in _card_slots.get_children():
		child.queue_free()
	return result


func get_stack() -> Array[CardData]:
	return _stack.duplicate()


# Private methods
func _reposition_all() -> void:
	var children := _card_slots.get_children()
	var n := children.size()
	for i in n:
		var child: Control = children[i]
		# children[0] = oldest (behind, upper-left)
		# children[n-1] = newest (on top, lower-right) — matches image reference
		child.position = Vector2(i * STACK_OFFSET, i * STACK_OFFSET)
		child.z_index = i
		child.scale = CARD_SCALE


# Signal handlers
func _on_execute_pressed() -> void:
	if _stack.is_empty():
		return
	var result: Array[CardData] = pop_all()
	execute_requested.emit(result)


func _on_clear_pressed() -> void:
	if _stack.is_empty():
		return
	var cards := clear_stack()
	clear_requested.emit(cards)
