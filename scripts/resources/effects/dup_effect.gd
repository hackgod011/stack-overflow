class_name DupEffect
extends CardEffect
## Duplicates the top value on the runtime stack.


func apply(context: Dictionary) -> void:
	if context.runtime_stack.is_empty():
		return
	context.runtime_stack.append(context.runtime_stack.back())
