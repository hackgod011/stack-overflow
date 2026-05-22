class_name PushValueEffect
extends CardEffect
## Pushes a fixed integer value onto the runtime stack.

@export var value: int = 1


func apply(context: Dictionary) -> void:
	context.runtime_stack.append(value)
