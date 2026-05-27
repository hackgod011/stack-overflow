class_name IfPositiveEffect
extends CardEffect
## Skips the next card in the stack if the top of the runtime stack is not > 0.


func apply(context: Dictionary) -> void:
	var top: int = context.runtime_stack.back() if not context.runtime_stack.is_empty() else 0
	if top <= 0:
		context["_skip_next"] = true
