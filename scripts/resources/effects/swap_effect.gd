class_name SwapEffect
extends CardEffect
## Swaps the top two values on the runtime stack.


func apply(context: Dictionary) -> void:
	if context.runtime_stack.size() < 2:
		return
	var top: int = context.runtime_stack[-1]
	context.runtime_stack[-1] = context.runtime_stack[-2]
	context.runtime_stack[-2] = top
