class_name StackZone
extends VBoxContainer

## Visual zone that holds cards queued for execution.
## Cards stack with visual offset; index 0 in _stack = most recently added (executes first).
## No gameplay resolution logic lives here.


# Constants
const CARD_VIEW = preload("res://scenes/card/card_view.tscn")
const CARD_SCALE := Vector2(0.80, 0.80)
const STACK_OFFSET := 14.0


# Signals
signal execute_requested(stack: Array[CardData])
signal clear_requested(cards: Array[CardData])


# Private variables
var _stack: Array[CardData] = []
var _pulse_tween: Tween = null


# @onready variables
@onready var _card_slots: Control = $CardSlots
@onready var _execute_button: Button = $ButtonRow/ExecuteButton
@onready var _clear_button: Button = $ButtonRow/ClearButton


# Built-in virtuals
func _ready() -> void:
	_execute_button.pressed.connect(_on_execute_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)
	_set_glow(0.0)


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
	_set_glow(1.0)


func pop_all() -> Array[CardData]:
	var result: Array[CardData] = _stack.duplicate()
	_stack.clear()
	for child in _card_slots.get_children():
		child.queue_free()
	_set_glow(0.0)
	return result


func clear_stack() -> Array[CardData]:
	var result: Array[CardData] = _stack.duplicate()
	_stack.clear()
	for child in _card_slots.get_children():
		child.queue_free()
	_set_glow(0.0)
	return result


func get_stack() -> Array[CardData]:
	return _stack.duplicate()


func get_views_in_execution_order() -> Array[Control]:
	var children := _card_slots.get_children()
	var result: Array[Control] = []
	for i in range(children.size() - 1, -1, -1):
		result.append(children[i] as Control)
	return result


# Private methods
func _reposition_all() -> void:
	var children := _card_slots.get_children()
	var n := children.size()
	for i in n:
		var child: Control = children[i]
		child.position = Vector2(i * STACK_OFFSET, i * STACK_OFFSET)
		child.z_index = i
		child.scale = CARD_SCALE


func _set_glow(intensity: float) -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	if intensity > 0.5:
		# Modulate-based green pulse — works correctly on Button without a shader
		_pulse_tween = get_tree().create_tween().set_loops()
		_pulse_tween.tween_property(_execute_button, "modulate", Color(1.0, 1.55, 1.0, 1.0), 0.55)
		_pulse_tween.tween_property(_execute_button, "modulate", Color(0.7, 1.05, 0.7, 1.0), 0.55)
	else:
		_execute_button.modulate = Color(1.0, 1.0, 1.0, 0.60)


# Signal handlers
func _on_execute_pressed() -> void:
	if _stack.is_empty():
		return
	var cards: Array[CardData] = _stack.duplicate()
	execute_requested.emit(cards)


func _on_clear_pressed() -> void:
	if _stack.is_empty():
		return
	var cards := clear_stack()
	clear_requested.emit(cards)
