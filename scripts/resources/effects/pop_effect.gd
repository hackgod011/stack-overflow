class_name PopEffect
extends CardEffect
## Pops and discards the top value from the runtime stack.


func apply(context: Dictionary) -> void:
	if context.runtime_stack.is_empty():
		return
	context.runtime_stack.pop_back()
