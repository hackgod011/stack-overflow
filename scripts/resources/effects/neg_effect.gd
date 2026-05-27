class_name NegEffect
extends CardEffect
## Negates the top value on the runtime stack.


func apply(context: Dictionary) -> void:
	if context.runtime_stack.is_empty():
		return
	context.runtime_stack[-1] = -context.runtime_stack[-1]
