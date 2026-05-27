class_name AddEffect
extends CardEffect
## Pops the top two values from the runtime stack and pushes their sum.


func apply(context: Dictionary) -> void:
	if context.runtime_stack.size() < 2:
		return
	var a: int = context.runtime_stack.pop_back()
	var b: int = context.runtime_stack.pop_back()
	context.runtime_stack.append(a + b)
