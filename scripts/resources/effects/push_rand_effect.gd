class_name PushRandEffect
extends CardEffect
## Pushes a random integer [1-6] onto the runtime stack.


func apply(context: Dictionary) -> void:
	context.runtime_stack.append(RNG.randi_range(1, 6))
